// Passthrough proxy: forwards /cgi-bin/* -> https://api.weixin.qq.com/cgi-bin/*
//
// Catchall route: any request to /cgi-bin/<anything> hits this file via the
// vercel.json rewrite. The path segments after /cgi-bin/ arrive in
// req.query.path as an array.
//
// Auth: requires Authorization: Bearer ${WECHAT_PROXY_SECRET}. The header is
// stripped before forwarding; WeChat's own auth (access_token query param) is
// preserved.
//
// Body: read raw (bodyParser disabled) so multipart/form-data image uploads
// pass through with their boundary intact.

export const config = {
  api: { bodyParser: false },
};

const PROXY_SECRET = process.env.WECHAT_PROXY_SECRET;

export default async function handler(req, res) {
  const got = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!PROXY_SECRET) {
    return res.status(500).json({ ok: false, error: 'WECHAT_PROXY_SECRET not configured on the proxy' });
  }
  if (got !== PROXY_SECRET) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }

  const segments = Array.isArray(req.query.path) ? req.query.path : [req.query.path].filter(Boolean);
  if (segments.length === 0) {
    return res.status(400).json({ ok: false, error: 'no path' });
  }
  const wechatPath = '/cgi-bin/' + segments.join('/');

  const passthrough = new URLSearchParams();
  for (const [k, v] of Object.entries(req.query)) {
    if (k === 'path') continue;
    if (Array.isArray(v)) v.forEach(vi => passthrough.append(k, vi));
    else if (v != null) passthrough.set(k, String(v));
  }
  const qs = passthrough.toString();
  const upstreamUrl = `https://api.weixin.qq.com${wechatPath}${qs ? '?' + qs : ''}`;

  let body;
  if (!['GET', 'HEAD'].includes((req.method || 'POST').toUpperCase())) {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    body = Buffer.concat(chunks);
  }

  let upstream;
  try {
    upstream = await fetch(upstreamUrl, {
      method: req.method,
      headers: {
        'content-type': req.headers['content-type'] || 'application/json',
      },
      body,
    });
  } catch (e) {
    return res.status(502).json({ ok: false, error: 'upstream fetch failed: ' + e.message });
  }

  const respBuf = Buffer.from(await upstream.arrayBuffer());
  res.status(upstream.status);
  const ct = upstream.headers.get('content-type');
  if (ct) res.setHeader('content-type', ct);
  res.send(respBuf);
}
