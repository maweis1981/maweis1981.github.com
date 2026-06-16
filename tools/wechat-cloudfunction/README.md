# 公众号 云开发 Cloud Function — Deployment Guide

This is the **only** component that needs to be deployed once. It sits inside
your 公众号's own 云开发 (CloudBase) environment, runs in Tencent's network,
and calls the 公众号 official APIs (`draft.add`, `freepublish.submit`, etc.)
from there. **Because the call originates inside Tencent's 公众号 infrastructure,
there is no IP whitelist requirement** — that's the whole point.

The GitHub Action stays a pure client: it renders the post to HTML and POSTs
to this function's HTTP trigger URL with a shared-secret bearer header.

## What this function does

For every incoming POST it:

1. Verifies the `Authorization: Bearer <secret>` header
2. Fetches `cover_url` (the post's cover, served from `raw.githubusercontent.com`)
3. Uploads the image as **permanent material** via `cloud.openapi.material.addMaterial` → gets `thumb_media_id`
4. Creates a draft via `cloud.openapi.draft.add` → gets draft `media_id`
5. If `publish=true`, calls `cloud.openapi.freepublish.submit(media_id)` → gets `publish_id`
6. Returns `{ cover_media_id, draft_media_id, publish_id }`

## One-time setup

### 1. 开通公众号云开发

公众号 后台 → **开发 → 云开发** → 开通

Pick the free 套餐 — daily blog usage stays well within free quotas (calls/day,
storage, materials). If the menu item doesn't exist for your account type,
verify that 云开发 is available for your 订阅号 / 服务号 category.

Note the **环境 ID** (looks like `cloud1-1g…xxx`) — you'll need it on every
function operation.

### 2. Package the function

From the repo root:

```bash
cd tools/wechat-cloudfunction
npm install --no-audit --no-fund
zip -r ../wechat-cloudfunction.zip . -x node_modules/.bin/\*
```

(Or zip from your file manager — must include `index.js`, `package.json`, and
the installed `node_modules/`.)

### 3. Upload as a cloud function

公众号 后台 → 云开发 → **云函数** → 新建函数:

- **函数名**: `wechat-publish` (any name works, just remember it)
- **运行环境**: **Node.js 18** (or 16 — both supported)
- **上传方式**: zip 上传 → pick `wechat-cloudfunction.zip`
- **入口**: `index.main`
- **执行超时**: 30s (default 3s is too short for image upload + draft.add)
- **内存**: 256 MB

### 4. Environment variable

云函数详情页 → **配置 → 环境变量** → 新增：

| Key | Value |
|---|---|
| `WECHAT_PROXY_SECRET` | a long random string (e.g. `openssl rand -hex 32`) — **save this for step 6** |

### 5. Enable the HTTP trigger

云函数详情页 → **触发管理 → 新建触发器** → **HTTP 触发器**:

- **触发路径**: `/wechat-publish` (or whatever)
- **认证方式**: 不鉴权 (we do auth in the function via the bearer header)

After saving, you'll see a **触发 URL** like:

```
https://cloud1-1g….service.tcloudbase.com/wechat-publish
```

That's the URL to give the GitHub Action.

### 6. Add the secrets to the blog repo

`maweis1981/maweis1981.github.com` → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `WECHAT_PROXY_URL` | the HTTP trigger URL from step 5 |
| `WECHAT_PROXY_SECRET` | the same random string from step 4 |

(The older `WECHAT_APP_ID` / `WECHAT_APP_SECRET` are no longer needed — the
cloud function uses its built-in 公众号 binding instead.)

### 7. Test it

`Actions → WeChat Publish → Run workflow`:

- **post**: `_posts/2026-06-14-ai-daily-2026-06-14.md`
- **cover**: `assets/img/posts/harness-is-the-product/cover.png` (any committed PNG/JPG works for testing)
- **publish**: **false** (review the draft first)
- **dry_run**: **false**

If it works, the workflow logs `[ok] { draft_media_id: '…', … }` and 公众号 后台 →
草稿箱 shows the new draft.

Once you're happy with the formatting, re-run with **publish: true** to push
straight to the public URL via `freepublish.submit`.

## Updating the function later

If you tweak `index.js`:

```bash
cd tools/wechat-cloudfunction
zip -r ../wechat-cloudfunction.zip . -x node_modules/.bin/\*
```

Then in 云函数 → **函数代码 → 上传 zip** → pick the new zip → 部署. Environment
variables persist across re-uploads; HTTP trigger URL stays the same.

## Failure modes

| In the GitHub Action log | What it means | Fix |
|---|---|---|
| `WECHAT_PROXY_URL and WECHAT_PROXY_SECRET env vars are required` | secrets missing | add the two repo secrets (step 6) |
| `[error] status 401: {"ok":false,"error":"unauthorized"}` | bearer mismatch | secret in repo ≠ secret on cloud function |
| `[error] status 500: …WECHAT_PROXY_SECRET env var not configured…` | env var not set on the function | step 4 |
| `[error] status 500: …addMaterial: 53400…` | cover format not jpg/png | convert cover to jpg/png |
| `[error] status 500: …draft.add: 40001…` | function bound to wrong 公众号 / token issue | check the 公众号 bound to this 云开发 env |
| `[error] status 500: …45009 reach max api daily quota…` | exceeded `freepublish` daily cap | wait until tomorrow, or skip `publish` and publish manually |

## Why this design

- **No IP whitelist gymnastics** — the cloud function runs inside Tencent's
  network with implicit 公众号 authorization
- **No `access_token` management** — `cloud.openapi.*` handles it
- **No new infra outside the 公众号 ecosystem** — the function lives in 公众号
  后台 → 云开发, not on Vercel / Fly / VPS
- **One-shot deploy** — re-deploy only if you change `index.js`
- **Bearer-based auth** — single shared secret in both places, easy to rotate
- **Cover by URL** — GitHub Action passes the raw GitHub URL of a cover image
  already in the repo; the cloud function fetches it on Tencent's side. No
  base64 in the JSON payload.
