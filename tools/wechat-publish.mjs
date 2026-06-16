#!/usr/bin/env node
// Convert a single Jekyll post into a WeChat 公众号 draft (and optionally publish it).
//
// Usage:
//   node tools/wechat-publish.mjs --file _posts/2026-06-14-ai-daily-2026-06-14.md
//   node tools/wechat-publish.mjs --file <path> --cover assets/img/avatar.webp
//   node tools/wechat-publish.mjs --file <path> --publish
//   node tools/wechat-publish.mjs --file <path> --dry-run    # print HTML, no API calls
//
// Env (required unless --dry-run):
//   WECHAT_APP_ID
//   WECHAT_APP_SECRET
//   WECHAT_COVER_MEDIA_ID    # OR pass --cover <local path>
//   WECHAT_API_PROXY         # optional, see tools/lib/wechat-api.mjs
//
// Outputs the resulting draft media_id (and publish_id if --publish).

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
    else if (a === '--help' || a === '-h') {
      console.log(fs.readFileSync(new URL(import.meta.url).pathname, 'utf-8').split('\n').slice(0, 18).join('\n'));
      process.exit(0);
    }
  }
  return out;
}

function parseFrontMatter(content) {
  const m = content.match(/^---\s*\n([\s\S]+?)\n---\s*\n?([\s\S]*)$/);
  if (!m) throw new Error('No YAML front matter found');
  const fm = yaml.load(m[1]) || {};
  return { fm, body: m[2] };
}

function buildDigest(description, fallback) {
  // WeChat caps digest at 120 characters.
  const raw = (description || fallback || '').replace(/\s+/g, ' ').trim();
  return raw.length > 120 ? raw.slice(0, 117) + '…' : raw;
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
    console.error('Missing --file. See top of script for usage.');
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

  const html = convertMarkdown(body);
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

  console.log('[auth] requesting stable_token…');
  const token = await getAccessToken(appid, secret);
  console.log('[auth] ok');

  const postDir = path.dirname(filePath);
  const finalHtml = await uploadInlineImages(token, html, postDir, repoRoot);

  let thumbMediaId;
  if (args.cover) {
    const abs = path.resolve(args.cover);
    if (!fs.existsSync(abs)) {
      console.error(`Cover not found: ${abs}`);
      process.exit(1);
    }
    console.log(`[cover] uploading ${abs} to permanent material…`);
    const r = await uploadPermanentImage(token, fs.readFileSync(abs), path.basename(abs));
    thumbMediaId = r.media_id;
    console.log(`[cover] new media_id: ${thumbMediaId} (url: ${r.url})`);
    console.log('[cover] NOTE: store this media_id as WECHAT_COVER_MEDIA_ID secret to avoid re-uploading');
  } else if (process.env.WECHAT_COVER_MEDIA_ID) {
    thumbMediaId = process.env.WECHAT_COVER_MEDIA_ID;
    console.log(`[cover] reusing WECHAT_COVER_MEDIA_ID: ${thumbMediaId}`);
  } else {
    console.error('No cover. Pass --cover <path> or set WECHAT_COVER_MEDIA_ID env var.');
    process.exit(1);
  }

  const article = {
    title,
    author,
    digest,
    content: finalHtml,
    thumb_media_id: thumbMediaId,
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
    console.log('[publish] poll /cgi-bin/freepublish/get with this id to track status');
  } else {
    console.log('Draft created. Go to 公众号 后台 → 草稿箱 to review and publish, or re-run with --publish.');
  }
}

main().catch(err => {
  console.error('[fatal]', err.message || err);
  process.exit(1);
});
