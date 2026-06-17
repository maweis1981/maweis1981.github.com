#!/usr/bin/env node
// Convert a single Jekyll post into a WeChat 公众号 draft (and optionally publish).
//
// Calls WeChat APIs through the proxy at WECHAT_API_PROXY (a tiny Fly.io
// app in tools/wechat-fly-proxy/, whose outbound IP is added to the
// 公众号 IP whitelist). The proxy is a passthrough; auth between Action and
// proxy uses a shared bearer secret.
//
// Usage:
//   node tools/wechat-publish.mjs --file _posts/<post>.md --cover assets/img/<cover>.png
//   node tools/wechat-publish.mjs --file _posts/<post>.md --cover https://example.com/cover.png
//   node tools/wechat-publish.mjs --file <post>            # cover from image.path front matter
//   node tools/wechat-publish.mjs --file <post> --cover <img> --publish
//   node tools/wechat-publish.mjs --file <post> --dry-run        # render only
//
// Cover resolution order:
//   1. --cover CLI arg (local path or https:// URL)
//   2. image.path in post front matter (local path or https:// URL)
//   3. DEFAULT_COVER env var (local path)
//
// Env (required unless --dry-run):
//   WECHAT_APP_ID
//   WECHAT_APP_SECRET
//   WECHAT_API_PROXY            recommended: https://your-proxy.fly.dev
//   WECHAT_API_PROXY_SECRET     bearer secret matching the proxy's env

import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { convertMarkdown } from './lib/wechat-md.mjs';
import {
  getAccessToken,
  uploadBodyImage,
  uploadPermanentImage,
  createDraft,
  publishDraft,
} from './lib/wechat-api.mjs';

function parseArgs(argv) {
  const out = { file: null, cover: null, publish: false, dryRun: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--file') out.file = argv[++i];
    else if (a === '--cover') out.cover = argv[++i];
    else if (a === '--publish') out.publish = true;
    else if (a === '--dry-run') out.dryRun = true;
  }
  return out;
}

function parseFrontMatter(content) {
  const m = content.match(/^---\s*\n([\s\S]+?)\n---\s*\n?([\s\S]*)$/);
  if (!m) throw new Error('No YAML front matter found');
  return { fm: yaml.load(m[1]) || {}, body: m[2] };
}

function buildDigest(description, fallback) {
  const raw = (description || fallback || '').replace(/\s+/g, ' ').trim();
  return raw.length > 120 ? raw.slice(0, 117) + '…' : raw;
}

// --- Math fallback for WeChat (no MathJax there) -------------------------
// The blog renders `$$...$$` via Chirpy/MathJax. WeChat can't, so for posts
// with `math: true` we degrade the LaTeX inside `$$...$$` to a readable
// Unicode approximation (e.g. \dbinom{n}{4} -> C(n, 4), 2^{n-1} -> 2ⁿ⁻¹).
// Gated on `math: true` so the `$` currency signs in other posts are untouched.
const SUP = { '0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹',
  '+':'⁺','-':'⁻','−':'⁻','=':'⁼','(':'⁽',')':'⁾','n':'ⁿ','i':'ⁱ' };
const SUB = { '0':'₀','1':'₁','2':'₂','3':'₃','4':'₄','5':'₅','6':'₆','7':'₇','8':'₈','9':'₉',
  '+':'₊','-':'₋','−':'₋','=':'₌','(':'₍',')':'₎','n':'ₙ','i':'ᵢ','k':'ₖ' };
const mapChars = (str, table) => [...str].map(c => table[c] ?? c).join('');

function latexToUnicode(tex) {
  let s = tex;
  s = s.replace(/\\(?:d|t)?binom\s*\{([^{}]*)\}\s*\{([^{}]*)\}/g,
    (_m, a, b) => `C(${a.trim()}, ${b.trim()})`);
  s = s.replace(/\^\{([^{}]*)\}/g, (_m, g) => mapChars(g, SUP));
  s = s.replace(/\^(\S)/g, (_m, g) => mapChars(g, SUP));
  s = s.replace(/_\{([^{}]*)\}/g, (_m, g) => mapChars(g, SUB));
  s = s.replace(/_(\S)/g, (_m, g) => mapChars(g, SUB));
  s = s.replace(/\\cdot/g, '·').replace(/\\times/g, '×')
       .replace(/\\neq/g, '≠').replace(/\\leq?/g, '≤').replace(/\\geq?/g, '≥')
       .replace(/\\left|\\right/g, '').replace(/\\[,;!:]| \\ /g, ' ');
  s = s.replace(/[{}]/g, '').replace(/\s+/g, ' ').trim();
  return s;
}

// Replace every `$$...$$` span in the markdown body with its Unicode form.
function degradeMathToUnicode(markdownBody) {
  return markdownBody.replace(/\$\$([\s\S]+?)\$\$/g, (_m, inner) => latexToUnicode(inner));
}


/**
 * Resolve the cover image buffer from CLI arg, post front matter, or DEFAULT_COVER env.
 * Accepts local file paths and https:// URLs.
 */
async function resolveCoverBuffer(coverArg, fm, repoRoot) {
  // Priority: --cover CLI arg > post front matter image.path > DEFAULT_COVER env
  const src = coverArg || fm?.image?.path || process.env.DEFAULT_COVER;
  if (!src) throw new Error('No cover: pass --cover, set image.path in front matter, or set DEFAULT_COVER env');
  if (/^https?:\/\//i.test(src)) {
    console.log(`[cover] fetching from URL: ${src}`);
    const res = await fetch(src);
    if (!res.ok) throw new Error(`Cover URL fetch failed: HTTP ${res.status} ${src}`);
    return { buf: Buffer.from(await res.arrayBuffer()), name: path.basename(src) || 'cover.png', src };
  }
  // Repo-root-absolute paths (e.g. front matter `image.path: /assets/...`) are
  // resolved against the repo root — mirroring inline-image handling — rather
  // than the filesystem root. Other relative paths resolve from cwd (repo root).
  const abs = src.startsWith('/')
    ? path.join(repoRoot, src.replace(/^\/+/, ''))
    : path.resolve(src);
  if (!fs.existsSync(abs)) throw new Error(`Cover not found: ${abs}`);
  return { buf: fs.readFileSync(abs), name: path.basename(abs), src: abs };
}

async function uploadInlineImages(token, html, postDir, repoRoot) {
  const re = /<img([^>]*?)\ssrc="([^"]+)"([^>]*)>/g;
  const tasks = [];
  let m;
  while ((m = re.exec(html)) !== null) {
    const [match, pre, src, post] = m;
    if (/^https?:\/\//i.test(src)) continue;
    const abs = src.startsWith('/')
      ? path.join(repoRoot, src.replace(/^\/+/, ''))
      : path.join(postDir, src);
    if (!fs.existsSync(abs)) {
      console.warn(`[warn] inline image not found, leaving src untouched: ${abs}`);
      continue;
    }
    tasks.push({ match, pre, src, post, abs });
  }
  let out = html;
  for (const t of tasks) {
    const buf = fs.readFileSync(t.abs);
    const url = await uploadBodyImage(token, buf, path.basename(t.abs));
    out = out.replace(t.match, `<img${t.pre} src="${url}"${t.post}>`);
    console.log(`[image] ${t.src} -> ${url}`);
  }
  return out;
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.file) {
    console.error('Missing --file');
    process.exit(1);
  }

  const repoRoot = process.cwd();
  const filePath = path.resolve(args.file);
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(filePath, 'utf-8');
  const { fm, body } = parseFrontMatter(raw);
  const title = fm.title;
  if (!title) { console.error('Front matter has no `title`'); process.exit(1); }
  const author = fm.author || 'Max (Ma Wei)';
  const digest = buildDigest(fm.description, title);

  const bodyForWeChat = fm.math === true ? degradeMathToUnicode(body) : body;
  const html = convertMarkdown(bodyForWeChat);
  console.log(`[parse] title: ${title}`);
  console.log(`[parse] digest: ${digest.slice(0, 80)}${digest.length > 80 ? '…' : ''}`);
  console.log(`[render] HTML length: ${html.length}`);

  if (args.dryRun) {
    console.log('\n--- HTML preview (first 1500 chars) ---');
    console.log(html.slice(0, 1500));
    console.log('--- (end preview) ---');
    return;
  }

  const appid = process.env.WECHAT_APP_ID;
  const secret = process.env.WECHAT_APP_SECRET;
  if (!appid || !secret) {
    console.error('WECHAT_APP_ID / WECHAT_APP_SECRET env vars are required');
    process.exit(1);
  }
  if (!process.env.WECHAT_API_PROXY) {
    console.warn('[warn] WECHAT_API_PROXY not set — calling api.weixin.qq.com directly. This works only from a whitelisted IP.');
  }

  console.log('[auth] requesting stable_token…');
  const token = await getAccessToken(appid, secret);
  console.log('[auth] ok');

  const postDir = path.dirname(filePath);
  const finalHtml = await uploadInlineImages(token, html, postDir, repoRoot);

  const { buf: coverBuf, name: coverName, src: coverSrc } = await resolveCoverBuffer(args.cover, fm, repoRoot);
  console.log(`[cover] uploading ${coverSrc} to permanent material…`);
  const cover = await uploadPermanentImage(token, coverBuf, coverName);
  console.log(`[cover] media_id: ${cover.media_id}`);

  const article = {
    title,
    author,
    digest,
    content: finalHtml,
    thumb_media_id: cover.media_id,
    need_open_comment: 0,
    only_fans_can_comment: 0,
  };

  console.log('[draft] creating…');
  const draftMediaId = await createDraft(token, [article]);
  console.log(`[draft] media_id: ${draftMediaId}`);

  if (args.publish) {
    console.log('[publish] submitting freepublish…');
    const publishId = await publishDraft(token, draftMediaId);
    console.log(`[publish] publish_id: ${publishId}`);
  } else {
    console.log('Draft created. Review in 公众号 后台 → 草稿筐, or re-run with --publish.');
  }
}

main().catch(err => {
  console.error('[fatal]', err.message || err);
  process.exit(1);
});
