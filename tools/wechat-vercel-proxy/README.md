# WeChat Vercel Proxy — Deploy Guide

A 50-line Vercel function that's the **only** piece of infra outside this
GitHub Pages repo. Its sole job: forward `/cgi-bin/*` requests from the
GitHub Action to `api.weixin.qq.com/cgi-bin/*` so WeChat sees the request
coming from Vercel's outbound IP (which **you** add to the 公众号 IP
whitelist) instead of GitHub Actions' rotating Azure IPs.

## What you'll do (~10 min one-time setup)

### 1. Deploy this directory as a Vercel project

Drop the **`tools/wechat-vercel-proxy/`** directory anywhere — easiest is its
own dedicated Vercel project (don't co-locate with kolens-web; you want this
proxy's secret / outbound IP separate from your product code).

Option A — Vercel dashboard:

1. Push `tools/wechat-vercel-proxy/` to a separate small Git repo (e.g.
   `maweis1981/wechat-proxy`).
2. Vercel dashboard → **Add New… → Project** → import that repo.
3. **Root Directory**: `/` (the root of the repo you pushed).
4. **Framework Preset**: Other.
5. **Build Command**: leave empty (no build step).
6. **Install Command**: leave empty (no deps).
7. **Region**: pick one and remember it (`hkg1` Hong Kong is closest to WeChat).
8. Deploy.

Option B — Vercel CLI:

```bash
cd tools/wechat-vercel-proxy
npx vercel --prod
# follow prompts; pick a region (hkg1 / sin1 are closest to WeChat servers)
```

### 2. Set the proxy's own auth secret

In Vercel dashboard → your proxy project → **Settings → Environment Variables**:

| Key | Value | Scope |
|---|---|---|
| `WECHAT_PROXY_SECRET` | a random string, e.g. `openssl rand -hex 32` | Production |

Redeploy after adding (Vercel does this automatically when you save, or
re-trigger from the **Deployments** tab).

### 3. Find the proxy's outbound IP

After deploy, curl the debug endpoint:

```bash
curl https://your-proxy.vercel.app/api/outbound-ip
# { "ok": true, "outbound_ip": "76.76.21.x", "region": "hkg1" }
```

> **Stable IP guarantee**: Vercel Serverless Functions on Hobby / Pro by
> default use AWS Lambda IPs from a wide pool — **not** statically stable.
> If you need a single permanent IP, enable Vercel's **Static IPs** add-on
> (Pro plan + ~\$20/mo) and the function will egress from one or two fixed
> IPs you choose. Without that add-on the outbound IP can shift every few
> deploys / cold starts, and you'll need to re-curl `/api/outbound-ip` and
> update the whitelist when WeChat starts rejecting calls.

### 4. Add the IP to 公众号 IP 白名单

公众号 后台 → **设置 → 公众号设置 → 开发者ID(AppID)** → **IP白名单** → 编辑 → 添加 → save.

(Microsoft Authenticator-style 二次确认 will pop on the admin's phone via 公众平台安全助手 — approve.)

### 5. Add three GitHub repo secrets

`maweis1981/maweis1981.github.com` → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `WECHAT_APP_ID` | from 公众号 后台 |
| `WECHAT_APP_SECRET` | from 公众号 后台 (only shown at reset) |
| `WECHAT_API_PROXY` | `https://your-proxy.vercel.app` |
| `WECHAT_API_PROXY_SECRET` | same value as the Vercel env var from step 2 |

### 6. Run the workflow

Actions → **WeChat Publish** → Run workflow:

- post: `_posts/2026-06-14-ai-daily-2026-06-14.md`
- cover: `assets/img/posts/harness-is-the-product/cover.png`
- publish: false (review first)
- dry_run: false

Successful run logs:

```
[parse] title: 2026年6月14日 · 双 IPO 同期冲刺,Anthropic 反超 OpenAI
[render] HTML length: 18511
[auth] requesting stable_token…
[auth] ok
[cover] uploading … to permanent material…
[cover] media_id: <id>
[draft] creating…
[draft] media_id: <id>
Draft created. Review in 公众号 后台 → 草稿箱, or re-run with --publish.
```

Draft appears in 公众号 后台 → 草稿箱.

## How requests flow

```
GitHub Action                           Vercel                    WeChat
─────────────                           ──────                    ──────
fetch                                                              
  https://proxy.vercel.app/cgi-bin/draft/add?access_token=…
  Authorization: Bearer <PROXY_SECRET>
  Content-Type: application/json
  body: { articles: [ ... ] }
                          ──HTTPS──>
                                          api/proxy/[...path].js
                                          ── verify Bearer
                                          ── strip Authorization
                                          ── construct upstream URL
                                          ── forward body + content-type
                                                              ──HTTPS──>
                                                                  cgi-bin/draft/add
                                                                  (caller IP = Vercel
                                                                   outbound IP, on
                                                                   the WeChat whitelist)
                                                              <──response──
                                          <── stream upstream response back
                          <──response──
```

## Failure modes

| In GitHub Action log | Cause | Fix |
|---|---|---|
| `errcode=40164 invalid ip x.x.x.x not in whitelist` | Vercel's outbound IP isn't whitelisted, OR it changed | curl `/api/outbound-ip` → add to 公众号 IP 白名单 |
| `status 401: {"ok":false,"error":"unauthorized"}` | `WECHAT_API_PROXY_SECRET` (Action) ≠ `WECHAT_PROXY_SECRET` (Vercel) | match them |
| `status 500: …WECHAT_PROXY_SECRET not configured…` | Vercel env var missing | set it in Vercel dashboard, redeploy |
| `errcode=40001 invalid credential` | `WECHAT_APP_SECRET` wrong / rotated | re-copy from 公众号 后台 |
| `errcode=53400 image format not support` | cover isn't jpg/png | use a jpg or png cover |
| `status 502: upstream fetch failed` | Vercel function couldn't reach `api.weixin.qq.com` | usually transient; re-run |

## Why this design

- **Static-blog-only constraint preserved**: the only thing outside this repo
  is one Vercel function. The blog itself stays static GitHub Pages.
- **One IP to whitelist** (with Static IPs add-on) or a small number that
  occasionally needs refresh (without).
- **Proxy is dumb** — it doesn't know anything about WeChat's API semantics.
  No `wx-server-sdk` dependency, no `access_token` management. If WeChat
  adds new endpoints they just work; if WeChat changes endpoints the proxy
  doesn't care.
- **Bearer secret** between Action and proxy is independent from
  `WECHAT_APP_SECRET`, so you can rotate them separately.
