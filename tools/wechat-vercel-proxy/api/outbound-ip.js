// Returns the proxy's current outbound IP — the address you need to add to
// 公众号 后台 → 设置 → 公众号设置 → IP白名单.
//
// Curl this once after deploying to find out what to whitelist:
//   curl https://your-proxy.vercel.app/api/outbound-ip
//
// If you're on the Static Outbound IPs add-on, this stays stable forever.
// Without the add-on it can change occasionally; re-curl when it does.
//
// Unauthenticated by design — only exposes a public IP that's already
// observable on every outbound request, no secrets involved.

export default async function handler(req, res) {
  try {
    const r = await fetch('https://api.ipify.org?format=json');
    const data = await r.json();
    res.json({
      ok: true,
      outbound_ip: data.ip,
      note: 'Add this IP to 公众号 后台 → 设置 → 公众号设置 → IP白名单.',
      region: process.env.VERCEL_REGION || 'unknown',
    });
  } catch (e) {
    res.status(500).json({ ok: false, error: e.message });
  }
}
