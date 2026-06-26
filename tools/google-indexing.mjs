#!/usr/bin/env node
// Notify Google's Indexing API that one or more URLs were updated.
//
// Usage:  node tools/google-indexing.mjs <url> [url ...]
//
// Auth: a Google Cloud service account (with the Indexing API enabled, and
// added as an OWNER of the Search Console property) whose JSON key is provided
// in the GOOGLE_INDEXING_SA_KEY env var (a GitHub Actions secret).
//
// No third-party deps: the JWT is signed with Node's built-in crypto.
//
// NOTE: Google officially supports the Indexing API only for JobPosting /
// BroadcastEvent pages. Using it for general blog posts is unofficial.

import crypto from 'node:crypto';

const urls = process.argv.slice(2).filter(Boolean);
if (urls.length === 0) {
  console.log('[indexing] no URLs passed — nothing to do.');
  process.exit(0);
}

const raw = process.env.GOOGLE_INDEXING_SA_KEY;
if (!raw || !raw.trim()) {
  console.warn('[indexing] GOOGLE_INDEXING_SA_KEY is not set — skipping (add the service-account JSON as a repo secret to enable).');
  process.exit(0); // don't fail the build before the secret exists
}

let sa;
try { sa = JSON.parse(raw); }
catch (e) { console.error('[indexing] GOOGLE_INDEXING_SA_KEY is not valid JSON:', e.message); process.exit(1); }

const b64url = (b) => Buffer.from(b).toString('base64').replace(/=+$/g, '').replace(/\+/g, '-').replace(/\//g, '_');

async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/indexing',
    aud: sa.token_uri || 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));
  const input = `${header}.${claim}`;
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(input); signer.end();
  const jwt = `${input}.${b64url(signer.sign(sa.private_key))}`;

  const res = await fetch(sa.token_uri || 'https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`token exchange failed: HTTP ${res.status} ${JSON.stringify(body)}`);
  return body.access_token;
}

const token = await getAccessToken();
let failed = 0;
for (const url of urls) {
  const res = await fetch('https://indexing.googleapis.com/v3/urlNotifications:publish', {
    method: 'POST',
    headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ url, type: 'URL_UPDATED' }),
  });
  if (res.ok) {
    console.log(`[indexing] ✓ URL_UPDATED ${url}`);
  } else {
    failed++;
    const t = await res.text();
    console.error(`[indexing] ✗ ${url} -> HTTP ${res.status} ${t.slice(0, 300)}`);
  }
}
if (failed) { console.error(`[indexing] ${failed}/${urls.length} failed.`); process.exit(1); }
console.log(`[indexing] done — ${urls.length} URL(s) submitted.`);
