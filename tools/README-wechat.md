# WeChat 公众号 Auto-Publish

Markdown → WeChat 草稿 → optional freepublish, in one Node script. Wired into a
`workflow_dispatch` GitHub Action so you can publish any post on demand from the
Actions tab; later switch to `on: push` once you trust it.

## What this does

Given a markdown post under `_posts/`:

1. Parses YAML front matter (`title`, `author`, `description`, …).
2. Renders the body to **WeChat-compatible HTML** with inline styles only — no
   classes, no `<style>` blocks (WeChat strips them).
3. Detects Chirpy's `{: .prompt-info|tip|warning|danger }` markers and rewrites
   the preceding `<blockquote>` as a colored box.
4. Uploads any inline images (`<img src="/assets/...">` or relative paths) to
   WeChat via `/cgi-bin/media/uploadimg` and rewrites the `src`.
5. Uses a **shared cover image** (single permanent material reused across posts)
   so you don't fill up your 5000-slot permanent material library.
6. Creates a draft via `/cgi-bin/draft/add`.
7. Optionally submits the draft via `/cgi-bin/freepublish/submit`.

## One-time setup

### 1. Get AppID + AppSecret from 公众号 后台

公众号 后台 → **设置 → 公众号设置 → 开发者ID(AppID)** and **开发者密码(AppSecret)**.
The AppSecret only shows once when reset — copy it immediately.

> **Note**: If you're on a personal 订阅号 registered after 2018, AppSecret access
> may be restricted. Verify it's available before continuing.

### 2. Solve the IP-whitelist problem

`/cgi-bin/stable_token` (and `/cgi-bin/token`) refuse calls from any IP not in
your account's IP whitelist. GitHub Actions runners use thousands of dynamic
IPs across many CIDRs, so you can't just add them all.

Pick one:

#### Option A (simplest) — run locally first

For your first run, clone the repo, set env vars, and run from your home machine.
Add your home IP to the whitelist:

  公众号 后台 → 设置 → 公众号设置 → **IP白名单** → 添加 (your public IP).

This proves the script works. Useful for testing the conversion + draft creation.

#### Option B (recommended for automation) — a tiny proxy on a fixed IP

The script honours a `WECHAT_API_PROXY` env var: if set, all requests go to
`${WECHAT_API_PROXY}/cgi-bin/...` instead of `https://api.weixin.qq.com/cgi-bin/...`.

Stand up a tiny passthrough on something whose outbound IP you control —
e.g. a Vercel function in your existing Vercel project, a Cloudflare Worker
(with a Workers Paid plan + dedicated IP), a Fly.io machine, or a $4/mo VPS.
Add **that** IP to the WeChat whitelist. Then:

```
WECHAT_API_PROXY=https://your-proxy.example.com
```

Minimal proxy (Node/Express, ~25 lines):

```js
import express from 'express';
const app = express();
app.use(express.raw({ type: '*/*', limit: '10mb' }));
app.all('/cgi-bin/*', async (req, res) => {
  const url = 'https://api.weixin.qq.com' + req.url;
  const r = await fetch(url, {
    method: req.method,
    headers: { 'content-type': req.headers['content-type'] || 'application/json' },
    body: ['GET','HEAD'].includes(req.method) ? undefined : req.body,
  });
  res.status(r.status);
  r.headers.forEach((v, k) => res.setHeader(k, v));
  res.send(Buffer.from(await r.arrayBuffer()));
});
app.listen(process.env.PORT || 3000);
```

(Auth that proxy with a shared secret in real production — left out for brevity.)

#### Option C — self-hosted GitHub Actions runner

Run the workflow on a runner with a fixed IP. Most engineering for the
cleanest result. Documented at
<https://docs.github.com/actions/hosting-your-own-runners>.

### 3. Upload a cover image once, save its media_id

Every WeChat article requires `thumb_media_id`. Run locally once with `--cover`
to upload the image you want to reuse and grab the media_id:

```bash
cd /path/to/maweis1981.github.com
export WECHAT_APP_ID=...
export WECHAT_APP_SECRET=...
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md \
  --cover path/to/cover.jpg
# log will print:  [cover] new media_id: <SOMETHING_LONG>
```

Then store `<SOMETHING_LONG>` as the **`WECHAT_COVER_MEDIA_ID`** secret. After
that, future runs reuse it without re-uploading.

WeChat cover requirements:

- Format: JPG / JPEG / PNG (not WebP)
- Recommended ratio: 2.35:1 (e.g. 900 × 383) — what shows in the article header

### 4. Add GitHub repo secrets

`Settings → Secrets and variables → Actions → New repository secret`:

| Secret | Required? | Value |
|---|---|---|
| `WECHAT_APP_ID` | yes | from 公众号 后台 |
| `WECHAT_APP_SECRET` | yes | from 公众号 后台 |
| `WECHAT_API_PROXY` | only if you went with Option B | e.g. `https://your-proxy.example.com` |

(Cover image is **per-run** via the workflow `cover` input or `--cover` CLI flag — not a secret.)

## Running it

### Manually via GitHub Actions UI

`Actions → WeChat Publish → Run workflow`

Inputs:

- **post** — `_posts/2026-06-14-ai-daily-2026-06-14.md`
- **publish** — leave **false** the first few times; review in 公众号 后台 →
  草稿箱 first. Flip to **true** once the format looks right.
- **dry_run** — set **true** to just render HTML and exit, useful when tuning
  the converter.

### From the command line

```bash
cd /path/to/maweis1981.github.com
export WECHAT_APP_ID=...  WECHAT_APP_SECRET=...  WECHAT_COVER_MEDIA_ID=...
# (optional) export WECHAT_API_PROXY=https://your-proxy.example.com

# Dry run — just see the HTML
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md --dry-run

# Real run — creates a draft
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md

# Real run — creates a draft AND submits it for publication
node tools/wechat-publish.mjs \
  --file _posts/2026-06-14-ai-daily-2026-06-14.md --publish
```

## What this does *not* do (yet)

- **Auto-trigger on push to master.** This is `workflow_dispatch` only for now.
  Once you've published a few drafts manually and trust the format, switch to
  `on: push` with a paths filter + diff detection.
- **Per-post cover images.** Uses a single shared cover (`WECHAT_COVER_MEDIA_ID`).
  Per-post would mean reading `image.path` from front matter and uploading the
  file every run, which burns permanent material slots.
- **Code highlighting.** WeChat strips Prism / Rouge / etc. CSS. Code blocks
  render with a uniform dark background, no syntax colors. AI Daily posts have
  no code blocks so this is mostly academic.
- **KaTeX / math.** Not handled. Add a markdown-it plugin if needed.
- **Polling freepublish status.** `--publish` returns the `publish_id` and
  exits; you can poll `/cgi-bin/freepublish/get` from your own script if you
  want strict success confirmation.

## Failure modes

- `errcode=40164 invalid ip 1.2.3.4 not in whitelist` — IP whitelist isn't set
  for the caller (you, or your proxy, or the runner). See **Setup step 2**.
- `errcode=89503` / `89506` / `89507` — API call from web UI is being throttled
  by 公众号's auto risk-control. Wait 30 minutes and retry; if it persists,
  check 公众号 后台 → **接口分析** for the alert.
- `errcode=53400 image format not support` on cover upload — convert to JPG/PNG.
- `errcode=45009 reach max api daily quota limit` — exceeded freepublish per-day
  cap. 个人订阅号 caps `freepublish` at 1/day historically; verify your account's
  current quota in 公众号 后台 → 数据分析 → 接口分析.
