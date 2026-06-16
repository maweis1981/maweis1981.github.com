# WeChat 公众号 Auto-Publish (via 云开发 cloud function)

End-to-end auto-publish from `_posts/*.md` to 公众号 (草稿 + optional
`freepublish`), running entirely from this static repo + GitHub Actions.

The reason it works without local infra: there's a tiny **HTTP-triggered cloud
function** deployed inside the 公众号's own **云开发** environment. The function
calls 公众号 APIs from inside Tencent's network, so the WeChat IP whitelist
constraint is sidestepped. See `tools/wechat-cloudfunction/README.md` for that
deployment.

The two pieces:

```
┌──────────────────────────────────────────────────────┐
│  GitHub Action  (this repo's _posts/* → rendered HTML)│
│  tools/wechat-publish.mjs                            │
│  - Read post, parse front matter                     │
│  - Convert Markdown → WeChat HTML (inline styles)    │
│  - POST { title, content_html, cover_url, … } to →   │
└──────────────────────────────────────────────────────┘
                            ↓ (HTTPS + Bearer secret)
┌──────────────────────────────────────────────────────┐
│  公众号 云开发 cloud function                          │
│  tools/wechat-cloudfunction/index.js                 │
│  - Verify bearer                                     │
│  - Fetch cover_url → upload as permanent material    │
│  - cloud.openapi.draft.add(...)                      │
│  - cloud.openapi.freepublish.submit(...) [optional]  │
│  - Return { cover_media_id, draft_media_id, … }      │
└──────────────────────────────────────────────────────┘
```

## What this does

Given a post under `_posts/`:

1. Parses YAML front matter (`title`, `author`, `description`, …).
2. Renders the body to WeChat-compatible HTML with inline styles only — no
   classes, no `<style>` blocks (WeChat strips them).
3. Detects Chirpy's `{: .prompt-info | tip | warning | danger }` markers and
   rewrites the preceding `<blockquote>` as a colored box.
4. Constructs the **raw GitHub URL** of the cover image (the image must
   already be committed to a branch — typically `master`).
5. POSTs the payload to the cloud function.
6. The cloud function does cover upload + draft.add (+ optional publish) and
   returns the resulting media IDs.

## One-time setup

The detailed runbook is **`tools/wechat-cloudfunction/README.md`**. Short version:

1. 公众号 后台 → 开发 → **云开发** → 开通 (free tier)
2. `cd tools/wechat-cloudfunction && npm install && zip -r ../wechat-cloudfunction.zip .`
3. 云开发 → 云函数 → 新建函数 → 上传 zip → entry `index.main` → Node 18 → timeout 30 s
4. Function env var: `WECHAT_PROXY_SECRET=<random string>`
5. Function 触发器 → HTTP 触发器, get the trigger URL
6. Repo secrets (Settings → Secrets and variables → Actions):
   - `WECHAT_PROXY_URL` = the trigger URL from step 5
   - `WECHAT_PROXY_SECRET` = the same secret from step 4

## Running it

### Manually via GitHub Actions UI

`Actions → WeChat Publish → Run workflow`

Inputs:

- **post** — `_posts/2026-06-14-ai-daily-2026-06-14.md`
- **cover** — `assets/img/posts/harness-is-the-product/cover.png` (or any
  committed JPG/PNG; aspect ratio 2.35:1 recommended)
- **publish** — leave **false** the first few times so you can review in
  公众号 后台 → 草稿箱. Flip to **true** once the format is right.
- **dry_run** — set **true** to just render HTML and exit. Useful when
  tuning the Markdown → HTML converter without touching the function.

### Locally (for converter tweaks only)

Local runs hit the cloud function the same way — set the same env vars:

```bash
cd /path/to/maweis1981.github.com
export WECHAT_PROXY_URL=https://cloud1-….service.tcloudbase.com/wechat-publish
export WECHAT_PROXY_SECRET=…
export GITHUB_REPOSITORY=maweis1981/maweis1981.github.com
export GITHUB_REF_NAME=master

# Dry run — render only
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md --dry-run

# Real run — creates a draft
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md \
  --cover assets/img/posts/harness-is-the-product/cover.png

# With auto-publish after draft
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md \
  --cover assets/img/posts/harness-is-the-product/cover.png \
  --publish
```

## What this does *not* do (yet)

- **Auto-trigger on push to master.** Still `workflow_dispatch` only — once
  you've validated a few drafts, switching to `on: push` with a paths filter
  is a one-line follow-up.
- **Per-post cover from front matter.** The cover is a workflow input
  (or `--cover` flag). If you add `image: { path: … }` to front matter for
  Chirpy, this script could be extended to read it.
- **freepublish status polling.** `--publish` returns the `publish_id` and
  exits; poll `/cgi-bin/freepublish/get` separately if you want strict
  success confirmation.

## Why this design

- **No IP whitelist gymnastics** — cloud function runs inside Tencent's
  network with implicit 公众号 authorization
- **No `access_token` management** — `cloud.openapi.*` handles it
- **No new infra outside the 公众号 ecosystem** — the function lives in 公众号
  后台 → 云开发, not on Vercel / Fly / VPS
- **Single shared bearer secret** between Action and function — easy to rotate
- **Cover by URL** — Action passes `raw.githubusercontent.com/…` URL; function
  fetches on Tencent's side. No base64 in the JSON payload.
