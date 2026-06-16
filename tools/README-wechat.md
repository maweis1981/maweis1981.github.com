# WeChat 公众号 Auto-Publish

End-to-end auto-publish from `_posts/*.md` to 公众号 (草稿 + optional
`freepublish`), all the way from a static GitHub Pages blog.

The architecture:

```
┌──────────────────────────────────────────────────────┐
│  GitHub Action (this repo)                            │
│  tools/wechat-publish.mjs                            │
│  - Read post, parse front matter                     │
│  - Convert Markdown → WeChat HTML (inline styles)    │
│  - Call stable_token / addMaterial / draft.add /     │
│    freepublish.submit  THROUGH the proxy             │
└──────────────────────────────────────────────────────┘
                            ↓ HTTPS + Bearer proxy secret
┌──────────────────────────────────────────────────────┐
│  Vercel function (~50 lines, see tools/wechat-       │
│  vercel-proxy/)                                       │
│  - Verify bearer                                     │
│  - Strip Authorization                               │
│  - Forward to api.weixin.qq.com                      │
└──────────────────────────────────────────────────────┘
                            ↓ HTTPS (Vercel outbound IP, whitelisted)
                       api.weixin.qq.com/cgi-bin/*
```

The Vercel function's outbound IP is what WeChat sees; you add **that** one
IP to 公众号 → IP 白名单 instead of trying to whitelist GitHub Actions' Azure
ranges.

## Components

| Path | Purpose |
|---|---|
| `tools/wechat-publish.mjs` | Entry point — front matter parse, render, orchestrate WeChat calls |
| `tools/lib/wechat-md.mjs` | Markdown → WeChat HTML (inline styles only; handles Chirpy `{: .prompt-info \| tip \| warning \| danger }` markers) |
| `tools/lib/wechat-api.mjs` | `stable_token` + `material/add_material` + `draft/add` + `freepublish/submit` + `media/uploadimg` |
| `tools/wechat-vercel-proxy/` | The 50-line Vercel function — **deployed separately**; see its own README for the runbook |
| `.github/workflows/wechat-publish.yml` | `workflow_dispatch` (`post`, `cover`, `publish`, `dry_run`) |

## Setup (one-time)

1. **Deploy the Vercel proxy.** Detailed runbook: [`tools/wechat-vercel-proxy/README.md`](wechat-vercel-proxy/README.md).
2. **Whitelist the proxy's outbound IP** in 公众号 后台 → 设置 → 公众号设置 → IP白名单. The proxy exposes `/api/outbound-ip` for this.
3. **Add four repo secrets** under Settings → Secrets and variables → Actions:

   | Secret | Value |
   |---|---|
   | `WECHAT_APP_ID` | from 公众号 后台 |
   | `WECHAT_APP_SECRET` | from 公众号 后台 |
   | `WECHAT_API_PROXY` | `https://your-proxy.vercel.app` |
   | `WECHAT_API_PROXY_SECRET` | the bearer secret you set on the Vercel function |

## Running it

### Manually via GitHub Actions UI

`Actions → WeChat Publish → Run workflow`

Inputs:

- **post** — `_posts/2026-06-14-ai-daily-2026-06-14.md`
- **cover** — `assets/img/posts/harness-is-the-product/cover.png` (any committed JPG/PNG; aspect ratio 2.35:1 recommended for the cover that shows in the article header)
- **publish** — leave **false** the first few times; review in 公众号 后台 → 草稿箱. Flip to **true** once the format is right.
- **dry_run** — set **true** to just render HTML and exit, useful when tuning the Markdown → HTML converter without touching the API.

## What this does *not* do (yet)

- **Auto-trigger on push to master.** Still `workflow_dispatch` only — once a few drafts are validated, switching to `on: push` with a paths filter is a one-line follow-up.
- **Per-post cover from front matter.** The cover is a workflow input. If you add `image: { path: … }` to front matter (Chirpy convention), this script could be extended.
- **`freepublish` status polling.** `--publish` returns the `publish_id` and exits; poll `/cgi-bin/freepublish/get` separately if you want strict success confirmation.

## Failure modes

See `tools/wechat-vercel-proxy/README.md` for the full table. The two you'll
hit most often:

- `errcode=40164 invalid ip` — Vercel outbound IP changed (no Static IPs
  add-on). Re-curl `/api/outbound-ip` and update the whitelist.
- `status 401: unauthorized` — `WECHAT_API_PROXY_SECRET` (GitHub) ≠
  `WECHAT_PROXY_SECRET` (Vercel). Match them.
