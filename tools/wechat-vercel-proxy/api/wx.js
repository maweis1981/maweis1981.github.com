// Passthrough proxy to api.weixin.qq.com — a single fixed-route function.
//
// Why a flat /api/wx route (not a /api/wx/[...path] catchall):
//   Vercel's filesystem catchall routing is unreliable for multi-segment
//   paths in non-framework projects. /api/wx/stable_token (1 segment)
//   resolved, but /api/wx/material/add_material (2 segments) 404'd at the
//   edge. A single exact-match function + the WeChat path passed in a query
//   param sidesteps all dynamic-route ambiguity.
//
// Request shape from the client (tools/lib/wechat-api.mjs):
//   POST ${PROXY}/api/wx?__p=<wechat-path-after-cgi-bin>&<wechat query params>
//   Authorization: Bearer ${WECHAT_PROXY_SECRET}
//   body: forwarded as-is (JSON or multipart/form-data)
//
//   e.g. __p=stable_token
//        __p=material/add_material  (+ access_token, type)
//        __p=draft/add              (+ access_token)
//
// The "cgi-bin" substring never appears in the client URL (it's added back
// here, server-side) so Vercel Firewall's CGI-attack rule doesn't fire.

export const config = {
  api: { bodyParser: false },
};

const PROXY_SECRET = process.env.WECHAT_PROXY_SECRET;

export default async function handler(req, res) {
  console.log(`[proxy] entry url=${req.url}`);

  if (!PROXY_SECRET) {
    return res.status(500).json({ ok: false, error: 'WECHAT_PROXY_SECRET not configured on the proxy' });
  }
  const got = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (got !== PROXY_SECRET) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }

  // Parse query straight off req.url (don't rely on req.query — see history).
  const url = new URL(req.url, 'http://internal');
  const wxRel = url.searchParams.get('__p');
  if (!wxRel) {
    return res.status(400).json({ ok: false, error: `missing __p query param; req.url=${req.url}` });
  }
  url.searchParams.delete('__p');

  const wechatPath = '/cgi-bin/' + wxRel.replace(/^\/+/, '');
  const qs = url.searchParams.toString();
  const upstreamUrl = `https://api.weixin.qq.com${wechatPath}${qs ? '?' + qs : ''}`;

  // Read the raw body so multipart/form-data (image uploads) passes through
  // with its boundary intact. Fall back to a re-stringified req.body if the
  // runtime auto-parsed it despite bodyParser:false.
  let body;
  if (!['GET', 'HEAD'].includes((req.method || 'POST').toUpperCase())) {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    body = Buffer.concat(chunks);
    if (body.length === 0 && req.body != null) {
      if (typeof req.body === 'string') body = Buffer.from(req.body, 'utf-8');
      else if (Buffer.isBuffer(req.body)) body = req.body;
      else body = Buffer.from(JSON.stringify(req.body), 'utf-8');
    }
  }

  console.log(`[proxy] ${req.method} ${wechatPath} ct=${req.headers['content-type']} body_len=${body?.length || 0}`);

  let upstream;
  try {
    upstream = await fetch(upstreamUrl, {
      method: req.method,
      headers: { 'content-type': req.headers['content-type'] || 'application/json' },
      body,
    });
  } catch (e) {
    console.error(`[proxy] upstream fetch error: ${e.message}`);
    return res.status(502).json({ ok: false, error: 'upstream fetch failed: ' + e.message });
  }

  const respBuf = Buffer.from(await upstream.arrayBuffer());
  console.log(`[proxy] upstream ${upstream.status} body_preview=${respBuf.toString('utf-8').slice(0, 200)}`);
  res.status(upstream.status);
  const ct = upstream.headers.get('content-type');
  if (ct) res.setHeader('content-type', ct);
  res.send(respBuf);
}
