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
  console.log(`[proxy] entry url=${req.url} query=${JSON.stringify(req.query)}`);

  const got = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!PROXY_SECRET) {
    return res.status(500).json({ ok: false, error: 'WECHAT_PROXY_SECRET not configured on the proxy' });
  }
  if (got !== PROXY_SECRET) {
    return res.status(401).json({ ok: false, error: 'unauthorized' });
  }

  // Parse the path directly from req.url instead of relying on req.query.path.
  // Vercel's dynamic-route catchall [...path] doesn't reliably populate
  // req.query.path for non-Next.js serverless functions — it sometimes
  // arrives as undefined regardless of how many URL segments matched.
  // req.url is always present and stable: it's the path after the host,
  // including query string. We strip the /api/wx/ prefix to get the
  // WeChat path segments.
  const fullUrl = req.url || '';
  const pathOnly = fullUrl.split('?')[0];
  const afterPrefix = pathOnly.replace(/^\/api\/wx\/?/, '');
  const segments = afterPrefix.split('/').filter(Boolean);
  if (segments.length === 0) {
    return res.status(400).json({ ok: false, error: `no path; req.url=${fullUrl}` });
  }
  const wechatPath = '/cgi-bin/' + segments.join('/');

  // Pass through any non-path query params (e.g. access_token, type) to upstream.
  // Use the raw query string from req.url so we don't depend on req.query at all.
  const rawQs = (fullUrl.split('?')[1] || '');
  const passthrough = new URLSearchParams(rawQs);
  passthrough.delete('path'); // safety: in case Vercel still added it
  const qs = passthrough.toString();
  const upstreamUrl = `https://api.weixin.qq.com${wechatPath}${qs ? '?' + qs : ''}`;

  // Body: try raw stream first; fall back to re-stringified req.body if Vercel
  // auto-parsed (which it does for application/json by default in pure
  // Serverless Functions, ignoring the `config.api.bodyParser` next.js hint).
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
      headers: {
        'content-type': req.headers['content-type'] || 'application/json',
      },
      body,
    });
  } catch (e) {
    console.error(`[proxy] upstream fetch error: ${e.message}`);
    return res.status(502).json({ ok: false, error: 'upstream fetch failed: ' + e.message });
  }

  const respBuf = Buffer.from(await upstream.arrayBuffer());
  console.log(`[proxy] upstream ${upstream.status} body_preview=${respBuf.toString('utf-8').slice(0, 300)}`);
  res.status(upstream.status);
  const ct = upstream.headers.get('content-type');
  if (ct) res.setHeader('content-type', ct);
  res.send(respBuf);
}
