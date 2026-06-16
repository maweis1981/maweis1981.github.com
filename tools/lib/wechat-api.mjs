// WeChat API wrappers — uses node 18+ fetch + FormData (no external HTTP lib).
// All endpoints under `${API_BASE}/cgi-bin/...`.
//
// If WECHAT_API_PROXY is set, requests go through that proxy (the proxy must
// preserve the path + query). This is the supported way to call the API from
// a CI runner whose IP can't be whitelisted directly — point WECHAT_API_PROXY
// at a small relay you control whose outbound IP IS whitelisted in 公众号 后台.

const API_BASE = process.env.WECHAT_API_PROXY?.replace(/\/+$/, '') || 'https://api.weixin.qq.com';

async function callJson(url, opts) {
  const res = await fetch(url, opts);
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); }
  catch { throw new Error(`Non-JSON from ${url} (status ${res.status}): ${text.slice(0, 400)}`); }
  if (json.errcode && json.errcode !== 0) {
    throw new Error(`${url.split('?')[0]} errcode=${json.errcode} errmsg=${json.errmsg}`);
  }
  return json;
}

// stable_token: same endpoint as cgi-bin/token but issues a stable token without
// invalidating previously issued ones. Recommended for multi-process callers.
// Still requires the caller IP to be in the 公众号 IP whitelist.
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

// /cgi-bin/media/uploadimg — for images embedded in article body. Returns a URL
// (NOT a media_id). The URL is what you put in <img src="..."> in the article HTML.
// No quota; image must be ≤ 1 MB. Use this for inline body images.
export async function uploadBodyImage(token, buffer, filename) {
  const form = new FormData();
  form.append('media', new Blob([buffer]), filename);
  return (await callJson(
    `${API_BASE}/cgi-bin/media/uploadimg?access_token=${encodeURIComponent(token)}`,
    { method: 'POST', body: form }
  )).url;
}

// /cgi-bin/material/add_material?type=image — for the cover (thumb_media_id).
// Returns a media_id that you pass as thumb_media_id in the article payload.
// This consumes a slot in your permanent material library (limit 5000 for images),
// so prefer uploading ONE shared cover and reusing its media_id (set
// WECHAT_COVER_MEDIA_ID secret) instead of re-uploading every run.
export async function uploadPermanentImage(token, buffer, filename) {
  const form = new FormData();
  form.append('media', new Blob([buffer]), filename);
  const json = await callJson(
    `${API_BASE}/cgi-bin/material/add_material?access_token=${encodeURIComponent(token)}&type=image`,
    { method: 'POST', body: form }
  );
  return { media_id: json.media_id, url: json.url };
}

// /cgi-bin/draft/add — creates a draft. articles is an array of article objects.
// Returns the draft's media_id (used by freepublish/submit).
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

// /cgi-bin/freepublish/submit — submits a draft for publication.
// Returns publish_id; poll /cgi-bin/freepublish/get with it to track status.
// Subject to per-day publish quota (defaults documented as 1 per day for free
// publish on 个人订阅号; check your 公众号 后台 for your account's actual quota).
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
