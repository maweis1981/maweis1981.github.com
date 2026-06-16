# Fly.io Deploy — Agent Runbook

> For a terminal coding agent (Claude Code) with `fly` available and the user
> logged in. Goal: deploy the WeChat proxy in this directory to Fly.io with a
> **stable dedicated egress IPv4**, then report the values the user must paste
> into GitHub secrets + the 公众号 IP whitelist.

You are in `tools/wechat-fly-proxy/` of the repo. Work through these steps,
showing output as you go. Stop and tell the user if a step fails in a way you
can't resolve.

## Step 1 — Verify Fly auth

```bash
fly auth whoami
```
- If it errors with `EOF` / timeout: it's a transient network issue to
  `api.fly.io` — retry up to 3×. If it still fails, tell the user their network
  can't reach Fly's API (try toggling VPN / different network) and stop.
- If it says "not logged in": run `fly auth login` (this opens a browser; the
  user completes it).

## Step 2 — Create the app (idempotent)

Check whether the app already exists (a previous partial `fly launch` may have
created it):

```bash
fly apps list | grep wechat-feeds-proxy || echo "NOT_CREATED"
```

- If it shows `wechat-feeds-proxy` already: skip to Step 3.
- If `NOT_CREATED`: create it non-interactively:

```bash
fly launch --no-deploy --copy-config --name wechat-feeds-proxy --region sin --org personal --yes
```

If the name is globally taken (`wechat-feeds-proxy` already used by someone
else), retry with a unique suffix and **remember the chosen name** — it
determines the URL `https://<name>.fly.dev`:

```bash
fly launch --no-deploy --copy-config --name wechat-feeds-proxy-mw --region sin --org personal --yes
```

## Step 3 — Generate the shared secret

```bash
WX_SECRET=$(openssl rand -hex 32)
echo "WX_SECRET=$WX_SECRET"
```
Keep this value — the user pastes the SAME value into GitHub later.

## Step 4 — Set the secret on Fly

```bash
fly secrets set WECHAT_PROXY_SECRET="$WX_SECRET" --app <APP_NAME>
```

## Step 5 — Allocate a dedicated IPv4 (this is the ~$2/mo line item)

```bash
fly ips allocate-v4 --app <APP_NAME> --yes
```
- A shared IPv4 is free but rotates — do NOT use `--shared`. We need a
  dedicated address so the egress IP is stable.
- If the command prompts for billing confirmation and `--yes` didn't suppress
  it, answer yes.

## Step 6 — Deploy

```bash
fly deploy --app <APP_NAME>
```
Wait for `successfully deployed`.

## Step 7 — Read the egress IP

```bash
curl -s https://<APP_NAME>.fly.dev/api/outbound-ip
```
Expect `{"ok":true,"outbound_ip":"X.X.X.X", ...}`.

## Step 8 — Report to the user (do NOT try to do these yourself)

Print a final summary with exactly these three things for the user to action:

1. **Whitelist this IP** in 公众号 后台 → 设置 → 公众号设置 → IP白名单:
   `<outbound_ip from step 7>`

2. **Set GitHub repo secrets** at
   `https://github.com/maweis1981/maweis1981.github.com/settings/secrets/actions`:
   - `WECHAT_API_PROXY` = `https://<APP_NAME>.fly.dev`
   - `WECHAT_API_PROXY_SECRET` = `<WX_SECRET from step 3>`

3. After both done: re-run the **WeChat Publish** GitHub Action
   (post `_posts/2026-06-14-ai-daily-2026-06-14.md`,
    cover `assets/img/posts/harness-is-the-product/cover.png`,
    publish `false`) and confirm the draft appears in 草稿箱 with no `40164`.

## Notes

- All proxy logic is in `server.mjs`; you don't need to modify it.
- If `fly deploy` build fails transiently, just re-run it (Docker layers cache).
- Health check after deploy: `curl -s https://<APP_NAME>.fly.dev/` → `{"ok":true,...}`.
