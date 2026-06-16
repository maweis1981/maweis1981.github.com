// WeChat API wrappers.
//
// Two modes:
//   1. WECHAT_API_PROXY env set (e.g. https://your-proxy.vercel.app)
//      Calls go to ${PROXY}/api/wx/<rest> and the proxy adds /cgi-bin/
//      server-side before forwarding to api.weixin.qq.com. The /api/wx/
//      prefix (instead of the literal /cgi-bin/) is intentional — Vercel
//      Firewall blocks paths containing "cgi-bin" as a CGI-attack pattern.
//   2. WECHAT_API_PROXY not set
//      Calls go directly to https://api.weixin.qq.com/cgi-bin/... — only
//      works from a whitelisted IP.
//
// When using the proxy, every request also sends
//   Authorization: Bearer ${WECHAT_API_PROXY_SECRET}
// so the proxy can authenticate the caller.

const PROXY = process.env.WECHAT_API_PROXY?.replace(/\/+$/, '');
const PROXY_SECRET = process.env.WECHAT_API_PROXY_SECRET;
const DIRECT_BASE = 'https://api.weixin.qq.com';

function wechatUrl(pathWithCgiBin) {
  // pathWithCgiBin is "/cgi-bin/<rest>[?query]"
  if (!PROXY) {
    return `${DIRECT_BASE}${pathWithCgiBin}`;
  }
  // Strip the leading "/cgi-bin" since the proxy adds it back; this keeps
  // the substring out of the client URL so the Vercel Firewall rule that
  // blocks any path containing "cgi-bin" doesn't fire.
  const withoutPrefix = pathWithCgiBin.replace(/^\/cgi-bin/, '');
  return `${PROXY}/api/wx${withoutPrefix}`;
}

function proxyHeaders(extra = {}) {
  const h = { ...extra };
  if (PROXY_SECRET) h.authorization = `Bearer ${PROXY_SECRET}`;
  return h;
}

async function callJson(url, opts = {}) {
  const res = await fetch(url, { ...opts, headers: proxyHeaders(opts.headers) });
  const text = await res.text();
  console.log(`[client] ${url.split('?')[0]} -> ${res.status} body=${text.slice(0, 300)}`);
  if (!res.ok) {
    throw new Error(`${url.split('?')[0]} returned HTTP ${res.status}: ${text.slice(0, 400)}`);
  }
  let json;
  try { json = JSON.parse(text); }
  catch { throw new Error(`Non-JSON from ${url} (status ${res.status}): ${text.slice(0, 400)}`); }
  if (json.errcode && json.errcode !== 0) {
    throw new Error(`${url.split('?')[0]} errcode=${json.errcode} errmsg=${json.errmsg}`);
  }
  return json;
}

export async function getAccessToken(appid, secret) {
  return (await callJson(wechatUrl('/cgi-bin/stable_token'), {
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
    wechatUrl(`/cgi-bin/media/uploadimg?access_token=${encodeURIComponent(token)}`),
    { method: 'POST', body: form }
  )).url;
}

export async function uploadPermanentImage(token, buffer, filename) {
  const form = new FormData();
  form.append('media', new Blob([buffer]), filename);
  const json = await callJson(
    wechatUrl(`/cgi-bin/material/add_material?access_token=${encodeURIComponent(token)}&type=image`),
    { method: 'POST', body: form }
  );
  return { media_id: json.media_id, url: json.url };
}

export async function createDraft(token, articles) {
  return (await callJson(
    wechatUrl(`/cgi-bin/draft/add?access_token=${encodeURIComponent(token)}`),
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ articles }),
    }
  )).media_id;
}

export async function publishDraft(token, draftMediaId) {
  return (await callJson(
    wechatUrl(`/cgi-bin/freepublish/submit?access_token=${encodeURIComponent(token)}`),
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify({ media_id: draftMediaId }),
    }
  )).publish_id;
}
