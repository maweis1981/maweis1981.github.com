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
import sharp from 'sharp';
import { convertMarkdown } from './lib/wechat-md.mjs';
import {
  getAccessToken,
  uploadBodyImage,
  uploadPermanentImage,
  createDraft,
  publishDraft,
} from './lib/wechat-api.mjs';

// WeChat's material APIs only accept jpg/png/gif/bmp — a .webp upload dies
// with errcode 40005 "invalid file type" (which killed the 2026-07-07 pony
// post run). Blog images are increasingly .webp, so transcode those to PNG
// right before upload; everything else passes through untouched.
async function toWxImage(buf, name) {
  const isWebp =
    /\.webp$/i.test(name) ||
    (buf.length > 12 && buf.toString('ascii', 0, 4) === 'RIFF' && buf.toString('ascii', 8, 12) === 'WEBP');
  if (!isWebp) return { buf, name };
  const png = await sharp(buf).png().toBuffer();
  const pngName = name.replace(/\.webp$/i, '') + '.png';
  console.log(`[image] transcoded webp -> png for WeChat: ${name} (${buf.length}B) -> ${pngName} (${png.length}B)`);
  return { buf: png, name: pngName };
}

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

// Jekyll liquid tags never reach the blog reader as-is — Jekyll expands them at
// build time. WeChat gets the RAW markdown though, and `{% post_url ... %}`
// contains spaces, so markdown-it can't even parse the link and the tag leaks
// into the article as literal text. Expand what we can, drop the rest:
//   - {% post_url YYYY-MM-DD-name %} -> https://maweis.com/posts/name/
//     (mirrors the site's /posts/:title/ permalink)
//   - {% raw %} / {% endraw %} and any other {% ... %} -> removed
function resolveLiquidTags(markdownBody) {
  return markdownBody
    .replace(/\{%\s*post_url\s+(\S+)\s*%\}/g, (_m, name) =>
      `https://maweis.com/posts/${name.replace(/^\d{4}-\d{2}-\d{2}-/, '')}/`)
    .replace(/\{%[^%]*%\}/g, '');
}

// Replace every `$$...$$` span in the markdown body with an <img> placeholder
// carrying the LaTeX (base64) and whether it was a standalone (display) block
// or inline. renderMathImages() later turns these into real WeChat images.
function mathToImagePlaceholders(markdownBody) {
  const enc = tex => Buffer.from(tex.trim(), 'utf-8').toString('base64');
  let md = markdownBody;
  // Block: a `$$...$$` that stands alone on its line(s).
  md = md.replace(/(^|\n)[ \t]*\$\$([\s\S]+?)\$\$[ \t]*(?=\n|$)/g,
    (_m, pre, tex) => `${pre}<img alt="formula" data-tex="${enc(tex)}" data-mathdisplay="block">`);
  // Inline: any remaining `$$...$$` within text.
  md = md.replace(/\$\$([\s\S]+?)\$\$/g,
    (_m, tex) => `<img alt="formula" data-tex="${enc(tex)}" data-mathdisplay="inline">`);
  return md;
}

function fetchWithTimeout(url, ms = 20000) {
  const ac = new AbortController();
  const t = setTimeout(() => ac.abort(), ms);
  return fetch(url, { signal: ac.signal }).finally(() => clearTimeout(t));
}

// Turn the `data-tex` placeholders into images: render the LaTeX to PNG via
// CodeCogs, upload to WeChat material, and swap in the WeChat URL. WeChat has
// no MathJax, so this is how math shows up "as a formula". Falls back to a
// Unicode approximation if rendering/upload fails (so a run never dies on it).
async function renderMathImages(token, html) {
  const re = /<img\b[^>]*?\bdata-tex="([^"]+)"[^>]*>/g;
  const found = [...html.matchAll(re)];
  let out = html;
  for (const m of found) {
    const tag = m[0];
    const tex = Buffer.from(m[1], 'base64').toString('utf-8');
    const isBlock = /data-mathdisplay="block"/.test(tag);
    let replacement;
    try {
      const url = `https://latex.codecogs.com/png.image?${encodeURIComponent(`\\dpi{300} ${tex}`)}`;
      const res = await fetchWithTimeout(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const buf = Buffer.from(await res.arrayBuffer());
      const wxUrl = await uploadBodyImage(token, buf, 'formula.png');
      const style = isBlock
        ? 'max-width:80%;height:auto;display:block;margin:1.3em auto'
        : 'height:1.15em;display:inline-block;vertical-align:-0.25em;margin:0 3px';
      replacement = `<img src="${wxUrl}" alt="formula" style="${style}">`;
      console.log(`[math] ${isBlock ? 'block' : 'inline'} ${tex} -> ${wxUrl}`);
    } catch (e) {
      replacement = latexToUnicode(tex);
      console.warn(`[math] render failed (${e.message || e}); Unicode fallback: ${tex} -> ${replacement}`);
    }
    out = out.replace(tag, replacement);
  }
  return out;
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
    const { buf, name } = await toWxImage(fs.readFileSync(t.abs), path.basename(t.abs));
    const url = await uploadBodyImage(token, buf, name);
    out = out.replace(t.match, `<img${t.pre} src="${url}"${t.post}>`);
    console.log(`[image] ${t.src} -> ${url}`);
  }
  return out;
}

// Collect images for a 图片消息 (newspic): explicit front-matter `wechat_images`
// list (in order) if given; otherwise the cover (image.path) plus every local
// image referenced in the body, in document order, deduped.
function resolveNewspicImages(fm, body, repoRoot) {
  let srcs = [];
  if (Array.isArray(fm.wechat_images) && fm.wechat_images.length) {
    srcs = fm.wechat_images.map(String);
  } else {
    if (fm.image?.path) srcs.push(String(fm.image.path));
    const re = /!\[[^\]]*\]\(([^)]+)\)/g;
    let m;
    while ((m = re.exec(body)) !== null) srcs.push(m[1].trim());
  }
  const seen = new Set();
  const out = [];
  for (const src of srcs) {
    if (/^https?:\/\//i.test(src)) continue;
    const abs = src.startsWith('/')
      ? path.join(repoRoot, src.replace(/^\/+/, ''))
      : path.join(repoRoot, src);
    if (seen.has(abs)) continue;
    seen.add(abs);
    if (!fs.existsSync(abs)) { console.warn(`[newspic] image not found, skipped: ${abs}`); continue; }
    out.push({ src, abs, name: path.basename(abs) });
  }
  return out;
}

// Build the 图片消息 caption (newspic `content`). Unlike the digest we keep
// paragraph breaks: collapse only intra-line spaces/tabs, preserve newlines
// (a blank line stays a blank line) so the post reads as written on WeChat.
function buildNewspicCaption(fm, title) {
  return String(fm.wechat_caption || fm.description || title)
    .replace(/\r\n?/g, '\n')
    .split('\n')
    .map((l) => l.replace(/[ \t]+/g, ' ').trim())
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
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

  // Opt-out switch: a post with `wechat: false` in front matter is blog-only.
  // Used for bulk back-fills we don't want flooding 公众号 草稿箱.
  if (fm.wechat === false) {
    console.log(`[skip] ${args.file}: front matter wechat:false — blog only, no draft created.`);
    return;
  }

  const title = fm.title;
  if (!title) { console.error('Front matter has no `title`'); process.exit(1); }
  const author = fm.author || 'Max (Ma Wei)';
  const digest = buildDigest(fm.description, title);

  // 图片消息（newspic / 贴图）mode: image-first WeChat post instead of 图文.
  const isNewspic = ['newspic', 'image', '贴图', '图片', '图片消息']
    .includes(String(fm.wechat_type || '').trim().toLowerCase());

  let bodyForWeChat = resolveLiquidTags(body);
  if (fm.math === true) bodyForWeChat = mathToImagePlaceholders(bodyForWeChat);
  const html = convertMarkdown(bodyForWeChat);
  console.log(`[parse] title: ${title}`);
  console.log(`[parse] digest: ${digest.slice(0, 80)}${digest.length > 80 ? '…' : ''}`);
  console.log(`[render] HTML length: ${html.length}`);

  if (args.dryRun) {
    if (isNewspic) {
      const imgs = resolveNewspicImages(fm, body, repoRoot);
      const caption = buildNewspicCaption(fm, title);
      console.log(`[newspic] mode 图片消息 — images (${imgs.length}): ${imgs.map(i => i.name).join(', ')}`);
      console.log(`[newspic] caption: ${caption.slice(0, 140)}${caption.length > 140 ? '…' : ''}`);
    } else {
      console.log('\n--- HTML preview (first 1500 chars) ---');
      console.log(html.slice(0, 1500));
      console.log('--- (end preview) ---');
    }
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

  // --- 图片消息（newspic）path: upload each image as material, build a
  // newspic article (image_info.image_list) and create a draft. ---
  if (isNewspic) {
    const imgs = resolveNewspicImages(fm, body, repoRoot);
    if (!imgs.length) { console.error('[newspic] no images found for 图片消息'); process.exit(1); }
    const caption = buildNewspicCaption(fm, title);
    const image_list = [];
    for (const im of imgs) {
      const wx = await toWxImage(fs.readFileSync(im.abs), im.name);
      const { media_id } = await uploadPermanentImage(token, wx.buf, wx.name);
      console.log(`[newspic] ${im.src} -> media_id ${media_id}`);
      image_list.push({ image_media_id: media_id });
    }
    const article = {
      article_type: 'newspic',
      title,
      content: caption,
      need_open_comment: 1,
      only_fans_can_comment: 0,
      image_info: { image_list },
    };
    const draftId = await createDraft(token, [article]);
    console.log(`[newspic] 图片消息草稿 media_id: ${draftId} (${image_list.length} 图)`);
    if (args.publish) {
      const publishId = await publishDraft(token, draftId);
      console.log(`[publish] publish_id: ${publishId}`);
    } else {
      console.log('图片消息草稿已建。Review in 公众号 后台 → 草稿筐。');
    }
    return;
  }

  const postDir = path.dirname(filePath);
  let finalHtml = await uploadInlineImages(token, html, postDir, repoRoot);
  if (fm.math === true) finalHtml = await renderMathImages(token, finalHtml);

  const resolvedCover = await resolveCoverBuffer(args.cover, fm, repoRoot);
  const { buf: coverBuf, name: coverName } = await toWxImage(resolvedCover.buf, resolvedCover.name);
  console.log(`[cover] uploading ${resolvedCover.src} to permanent material…`);
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
  // 阅读原文 link: front matter `wechat_source_url` (e.g. the full/interactive
  // web version). Omitted key when unset so the draft has no source link.
  if (fm.wechat_source_url) {
    article.content_source_url = String(fm.wechat_source_url);
    console.log(`[draft] content_source_url (阅读原文): ${article.content_source_url}`);
  }

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
