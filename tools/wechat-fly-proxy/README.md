# WeChat Fly.io Proxy — Deploy Guide

A ~70-line standalone HTTP server that forwards WeChat API calls from the
GitHub Action to `api.weixin.qq.com`. Unlike the Vercel function, this runs on
**one long-lived Fly machine**, so every request egresses from a **stable IP** —
which is exactly what WeChat's IP whitelist requires.

## Why Fly.io instead of Vercel

Vercel Serverless Functions egress from a wide AWS Lambda IP pool that changes
per invocation — you can't whitelist it. Stable egress IPs on Vercel are an
Enterprise-only feature. Fly gives you a dedicated IPv4 for ~$2/mo and the
machine's egress IP is stable, so you whitelist it **once**.

## One-time setup (~10 min)

### 1. Install flyctl + sign in

```bash
curl -L https://fly.io/install.sh | sh   # or: brew install flyctl
fly auth login
```

### 2. Launch the app (from this directory)

```bash
cd tools/wechat-fly-proxy
fly launch --no-deploy
```

- When prompted for an app name, pick one (e.g. `wechat-feeds-proxy`) — or keep
  the one in `fly.toml`. If you change it, note the resulting `*.fly.dev` URL.
- Region: **hkg** (Hong Kong — closest to WeChat servers). Already set in fly.toml.
- It detects the `Dockerfile`; no Postgres/Redis needed — decline those.

### 3. Allocate a dedicated IPv4 (this is the ~$2/mo line item)

```bash
fly ips allocate-v4
```

A shared IPv4 is free but rotates; a **dedicated** one is stable. The command
above allocates a dedicated address (confirm the small monthly charge prompt).

### 4. Set the shared secret

```bash
fly secrets set WECHAT_PROXY_SECRET=<the same value as the GitHub repo secret WECHAT_API_PROXY_SECRET>
```

### 5. Deploy

```bash
fly deploy
```

### 6. Find the egress IP and whitelist it

```bash
curl https://<your-app>.fly.dev/api/outbound-ip
# { "ok": true, "outbound_ip": "X.X.X.X", ... }
```

Add `outbound_ip` to 公众号 后台 → 设置 → 公众号设置 → **IP白名单**.

> The value reported by `/api/outbound-ip` is the actual source IP WeChat will
> see. With a dedicated IPv4 allocated, this stays constant across machine
> restarts and scale-to-zero wakeups. Whitelist it once.

### 7. Repoint the GitHub Action at Fly

In `maweis1981/maweis1981.github.com` → Settings → Secrets and variables → Actions, update:

| Secret | New value |
|---|---|
| `WECHAT_API_PROXY` | `https://<your-app>.fly.dev` |
| `WECHAT_API_PROXY_SECRET` | unchanged (must match Fly's `WECHAT_PROXY_SECRET`) |

`WECHAT_APP_ID` / `WECHAT_APP_SECRET` unchanged.

### 8. Test

Re-run the **WeChat Publish** workflow. All calls now egress from the Fly IP;
no more `40164` once it's whitelisted. The old Vercel project can be deleted.

## How requests flow

```
GitHub Action
  POST https://<app>.fly.dev/api/wx?__p=draft/add&access_token=…
  Authorization: Bearer <secret>
        │
        ▼
Fly machine (stable egress IP, whitelisted)
  - verify bearer
  - __p=draft/add  ->  /cgi-bin/draft/add
  - forward body + content-type
        │
        ▼
  https://api.weixin.qq.com/cgi-bin/draft/add?access_token=…
  (source IP = Fly machine's egress, on the whitelist)
```

## Updating the proxy later

```bash
cd tools/wechat-fly-proxy
fly deploy
```

The dedicated IPv4 and the secret persist across deploys.

## Failure modes

| GitHub Action log | Cause | Fix |
|---|---|---|
| `errcode=40164 invalid ip …` | Fly egress IP not whitelisted (or changed — shouldn't with dedicated v4) | `curl …/api/outbound-ip` and update the whitelist |
| `status 401 unauthorized` | secret mismatch | Fly `WECHAT_PROXY_SECRET` ≠ GitHub `WECHAT_API_PROXY_SECRET` |
| `502 upstream fetch failed` | Fly machine couldn't reach WeChat (rare) | usually transient; re-run |
