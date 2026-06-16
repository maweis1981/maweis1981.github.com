#!/usr/bin/env node
// Markdown post -> rendered WeChat HTML -> POST to 公众号 云开发 HTTP trigger.
//
// All WeChat-side work (cover upload, draft.add, freepublish.submit) is done
// inside the 公众号 云开发 cloud function (see tools/wechat-cloudfunction/),
// which runs inside Tencent's network and doesn't need IP whitelisting.
//
// Usage:
//   node tools/wechat-publish.mjs --file _posts/<post>.md --cover assets/img/<cover>.png
//   node tools/wechat-publish.mjs --file <post> --cover <img> --publish
//   node tools/wechat-publish.mjs --file <post> --dry-run         # render only, no POST
//
// Env (required unless --dry-run):
//   WECHAT_PROXY_URL      HTTP trigger URL of the deployed cloud function
//   WECHAT_PROXY_SECRET   Shared secret (must match cloud function's env)
//   GITHUB_REPOSITORY     owner/repo (auto-set by GitHub Actions)
//   GITHUB_REF_NAME       branch (auto-set by GitHub Actions)

import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';
import { convertMarkdown } from './lib/wechat-md.mjs';

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

function buildRawUrl(coverPath) {
  const repo = process.env.GITHUB_REPOSITORY;
  const ref = process.env.GITHUB_REF_NAME || process.env.GITHUB_HEAD_REF || 'master';
  if (!repo) {
    throw new Error('GITHUB_REPOSITORY env var not set — this script is intended to run inside GitHub Actions so the cloud function can fetch the cover via raw.githubusercontent.com');
  }
  return `https://raw.githubusercontent.com/${repo}/${ref}/${coverPath.replace(/^\/+/, '')}`;
}

async function main() {
  const args = parseArgs(process.argv);
  if (!args.file) { console.error('Missing --file'); process.exit(1); }
  if (!args.cover && !args.dryRun) {
    console.error('Missing --cover (required unless --dry-run)');
    process.exit(1);
  }

  const filePath = path.resolve(args.file);
  if (!fs.existsSync(filePath)) { console.error(`File not found: ${filePath}`); process.exit(1); }

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

  const proxyUrl = process.env.WECHAT_PROXY_URL;
  const proxySecret = process.env.WECHAT_PROXY_SECRET;
  if (!proxyUrl || !proxySecret) {
    console.error('WECHAT_PROXY_URL and WECHAT_PROXY_SECRET env vars are required');
    process.exit(1);
  }

  const coverUrl = buildRawUrl(args.cover);
  console.log(`[cover] raw URL: ${coverUrl}`);

  const payload = {
    action: 'createDraft',
    title,
    author,
    digest,
    content_html: html,
    cover_url: coverUrl,
    publish: args.publish,
  };

  console.log(`[post] -> ${proxyUrl}`);
  const res = await fetch(proxyUrl, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${proxySecret}`,
      'content-type': 'application/json; charset=utf-8',
    },
    body: JSON.stringify(payload),
  });

  const resText = await res.text();
  let resJson = null;
  try { resJson = JSON.parse(resText); } catch { /* keep null */ }

  if (!res.ok || (resJson && resJson.ok === false)) {
    console.error(`[error] status ${res.status}: ${resText.slice(0, 800)}`);
    process.exit(1);
  }

  console.log('[ok]', JSON.stringify(resJson || resText, null, 2));
}

main().catch(err => {
  console.error('[fatal]', err.message || err);
  process.exit(1);
});
