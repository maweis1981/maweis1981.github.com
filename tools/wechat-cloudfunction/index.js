// 公众号 云开发 HTTP-triggered cloud function.
//
// Deploy to:  公众号 后台 → 开发 → 云开发 → 云函数 → 新建/上传函数
//
// The function uses wx-server-sdk's `cloud.openapi` to call 公众号 official
// APIs from inside Tencent's network — no IP whitelist needed, no manual
// access_token management.
//
// Env vars to set in the 云开发 console (云函数 → 配置 → 环境变量):
//   WECHAT_PROXY_SECRET   shared secret matching the GitHub Action's
//
// HTTP trigger payload (POST, application/json):
//   {
//     "action": "createDraft",
//     "title": "…",
//     "author": "…",
//     "digest": "…",
//     "content_html": "<p>…</p>",
//     "cover_url": "https://raw.githubusercontent.com/owner/repo/branch/path/to/cover.png",
//     "publish": false
//   }
//
// Authorization: Bearer <WECHAT_PROXY_SECRET>
//
// Response:
//   200 { ok: true, cover_media_id, draft_media_id, publish_id }
//   401 { ok: false, error: "unauthorized" }
//   400 { ok: false, error: "<reason>" }
//   500 { ok: false, error: "<message>" }

const cloud = require('wx-server-sdk');
cloud.init({ env: cloud.DYNAMIC_CURRENT_ENV });

const _fetch = global.fetch || require('node-fetch');

function verifyAuth(headers) {
  const expected = process.env.WECHAT_PROXY_SECRET;
  if (!expected) throw new Error('WECHAT_PROXY_SECRET env var not configured on this cloud function');
  const got = (headers && (headers.authorization || headers.Authorization)) || '';
  return got === `Bearer ${expected}`;
}

async function fetchImage(url) {
  const res = await _fetch(url);
  if (!res.ok) throw new Error(`fetch ${url} -> HTTP ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  let contentType = res.headers.get('content-type') || '';
  // WeChat material API needs a concrete image type. Sniff if header is generic.
  if (!/^image\//i.test(contentType)) {
    if (url.endsWith('.png') || (buf[0] === 0x89 && buf[1] === 0x50)) contentType = 'image/png';
    else if (url.endsWith('.jpg') || url.endsWith('.jpeg') || (buf[0] === 0xff && buf[1] === 0xd8)) contentType = 'image/jpeg';
    else contentType = 'image/png';
  }
  return { buf, contentType };
}

function ok(body) {
  return {
    statusCode: 200,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  };
}
function err(status, message) {
  return {
    statusCode: status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
    body: JSON.stringify({ ok: false, error: message }),
  };
}

exports.main = async (event /*, context */) => {
  if ((event.httpMethod || 'POST').toUpperCase() !== 'POST') {
    return err(405, 'method not allowed');
  }

  let authOk;
  try { authOk = verifyAuth(event.headers || {}); }
  catch (e) { return err(500, e.message); }
  if (!authOk) return err(401, 'unauthorized');

  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return err(400, 'invalid JSON body'); }

  const {
    action,
    title,
    author = 'Max (Ma Wei)',
    digest,
    content_html,
    cover_url,
    publish = false,
  } = body;

  if (action !== 'createDraft') return err(400, `unknown action: ${action}`);
  if (!title || !content_html || !cover_url) return err(400, 'missing title/content_html/cover_url');

  try {
    console.log(`[cover] fetching ${cover_url}`);
    const { buf, contentType } = await fetchImage(cover_url);
    console.log(`[cover] fetched ${buf.length} bytes (${contentType})`);

    const materialRes = await cloud.openapi.material.addMaterial({
      mediaType: 'image',
      media: { contentType, value: buf },
    });
    const coverMediaId = materialRes.mediaId || materialRes.media_id;
    console.log(`[cover] media_id: ${coverMediaId}`);

    const draftRes = await cloud.openapi.draft.add({
      articles: [{
        title,
        author,
        digest: digest || title,
        content: content_html,
        thumbMediaId: coverMediaId,
        needOpenComment: 0,
        onlyFansCanComment: 0,
      }],
    });
    const draftMediaId = draftRes.mediaId || draftRes.media_id;
    console.log(`[draft] media_id: ${draftMediaId}`);

    let publishId = null;
    if (publish) {
      const publishRes = await cloud.openapi.freepublish.submit({ mediaId: draftMediaId });
      publishId = publishRes.publishId || publishRes.publish_id;
      console.log(`[publish] publish_id: ${publishId}`);
    }

    return ok({
      ok: true,
      cover_media_id: coverMediaId,
      draft_media_id: draftMediaId,
      publish_id: publishId,
    });
  } catch (e) {
    console.error('[error]', e);
    return err(500, e.message || String(e));
  }
};
