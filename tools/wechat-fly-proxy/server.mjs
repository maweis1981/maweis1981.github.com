// WeChat API passthrough proxy — standalone Node HTTP server for Fly.io.
//
// Same logic as the Vercel function (tools/wechat-vercel-proxy/api/wx.js) but
// as a long-running server, so all requests egress from ONE stable Fly machine
// IP — which is the whole point: WeChat's IP whitelist needs a fixed source IP,
// and Fly gives you one (allocate a dedicated IPv4; verify via /api/outbound-ip).
//
// Routes:
//   GET  /                  health check
//   GET  /api/outbound-ip   returns this machine's egress IP (the value to
//                           put in 公众号 IP 白名单). No auth.
//   *    /api/wx?__p=<path> authenticated passthrough to
//                           api.weixin.qq.com/cgi-bin/<__p>
//
// Env:
//   PORT                 (Fly sets this; defaults 8080)
//   WECHAT_PROXY_SECRET  shared bearer secret matching the GitHub Action

import http from 'node:http';

const PORT = process.env.PORT || 8080;
const SECRET = process.env.WECHAT_PROXY_SECRET;

function json(res, status, obj) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(obj));
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://internal');

  if (url.pathname === '/' || url.pathname === '/health') {
    return json(res, 200, { ok: true, service: 'wechat-fly-proxy' });
  }

  if (url.pathname === '/api/outbound-ip') {
    try {
      const r = await fetch('https://api.ipify.org?format=json');
      const data = await r.json();
      return json(res, 200, {
        ok: true,
        outbound_ip: data.ip,
        note: 'Add this IP to 公众号 后台 → 设置 → 公众号设置 → IP白名单.',
      });
    } catch (e) {
      return json(res, 500, { ok: false, error: e.message });
    }
  }

  if (url.pathname === '/api/wx') {
    if (!SECRET) return json(res, 500, { ok: false, error: 'WECHAT_PROXY_SECRET not configured' });
    const got = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
    if (got !== SECRET) return json(res, 401, { ok: false, error: 'unauthorized' });

    const wxRel = url.searchParams.get('__p');
    if (!wxRel) return json(res, 400, { ok: false, error: 'missing __p query param' });
    url.searchParams.delete('__p');

    const wechatPath = '/cgi-bin/' + wxRel.replace(/^\/+/, '');
    const qs = url.searchParams.toString();
    const upstreamUrl = `https://api.weixin.qq.com${wechatPath}${qs ? '?' + qs : ''}`;

    let body;
    if (!['GET', 'HEAD'].includes((req.method || 'POST').toUpperCase())) {
      const chunks = [];
      for await (const chunk of req) chunks.push(chunk);
      body = Buffer.concat(chunks);
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
      console.error(`[proxy] upstream error: ${e.message}`);
      return json(res, 502, { ok: false, error: 'upstream fetch failed: ' + e.message });
    }

    const buf = Buffer.from(await upstream.arrayBuffer());
    console.log(`[proxy] upstream ${upstream.status} ${buf.toString('utf-8').slice(0, 160)}`);
    res.writeHead(upstream.status, {
      'content-type': upstream.headers.get('content-type') || 'application/json',
    });
    return res.end(buf);
  }

  return json(res, 404, { ok: false, error: 'not found' });
});

server.listen(PORT, () => console.log(`wechat-fly-proxy listening on :${PORT}`));
