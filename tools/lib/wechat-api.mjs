// WeChat API wrappers.
//
// API_BASE precedence:
//   1. WECHAT_API_PROXY env (e.g. https://your-proxy.vercel.app) — strongly
//      recommended for CI use: the proxy's outbound IP gets added to the
//      公众号 IP whitelist instead of trying to whitelist GitHub Actions IPs.
//   2. https://api.weixin.qq.com (direct — only works from a whitelisted IP).
//
// When WECHAT_API_PROXY is set, every request also sends
//   Authorization: Bearer ${WECHAT_API_PROXY_SECRET}
// so the proxy can authenticate the caller.

const API_BASE = process.env.WECHAT_API_PROXY?.replace(/\/+$/, '') || 'https://api.weixin.qq.com';
const PROXY_SECRET = process.env.WECHAT_API_PROXY_SECRET;

function proxyHeaders(extra = {}) {
  const h = { ...extra };
  if (PROXY_SECRET) h.authorization = `Bearer ${PROXY_SECRET}`;
  return h;
}

async function callJson(url, opts = {}) {
  const res = await fetch(url, { ...opts, headers: proxyHeaders(opts.headers) });
  const text = await res.text();
  console.log(`[client] ${url.split('?')[0]} -> ${res.status} body=${text.slice(0, 300)}`);
  let json;
  try { json = JSON.parse(text); }
  catch { throw new Error(`Non-JSON from ${url} (status ${res.status}): ${text.slice(0, 400)}`); }
  if (json.errcode && json.errcode !== 0) {
    throw new Error(`${url.split('?')[0]} errcode=${json.errcode} errmsg=${json.errmsg}`);
  }
  return json;
}

export async function getAccessToken(appid, secret) {
  return (await callJson(`${API_BASE}/cgi-bin/stable_token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'client_credential',
      appid, secret,
      force_refresh: false,
    }),
  })).access_token;
}

export async function uploadBodyImage(token, buffer, filename) {
  const form = new FormData();
  form.append('media', new Blob([buffer]), filename);
  return (await callJson(
    `${API_BASE}/cgi-bin/media/uploadimg?access_token=${encodeURIComponent(token)}`,
    { method: 'POST', body: form }
  )).url;
}

export async function uploadPermanentImage(token, buffer, filename) {
  const form = new FormData();
  form.append('media', new Blob([buffer]), filename);
  const json = await callJson(
    `${API_BASE}/cgi-bin/material/add_material?access_token=${encodeURIComponent(token)}&type=image`,
    { method: 'POST', body: form }
  );
  return { media_id: json.media_id, url: json.url };
}

export async function createDraft(token, articles) {
  return (await callJson(
    `${API_BASE}/cgi-bin/draft/add?access_token=${encodeURIComponent(token)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ articles }),
    }
  )).media_id;
}

export async function publishDraft(token, draftMediaId) {
  return (await callJson(
    `${API_BASE}/cgi-bin/freepublish/submit?access_token=${encodeURIComponent(token)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ media_id: draftMediaId }),
    }
  )).publish_id;
}
