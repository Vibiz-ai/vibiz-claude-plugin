---
name: vibiz-mcp
description: How to use the Vibiz MCP server from Claude Code — the 40 tools, the target.vibiz arg, and the OAuth auth flow.
---

# Using the Vibiz MCP

The Vibiz MCP server is auto-configured by this plugin at `https://www.vibiz.ai/api/mcp`. After `/plugin install`, the user authenticates once via `/mcp` → `vibiz` → **Authenticate**, and from then on every Vibiz tool call is scoped to their workspace group via OAuth.

## The `target` argument is the key

Most Vibiz tools accept a `target` arg:

```ts
target: { vibiz: "<slug>" }
```

The slug comes from `list_vibiz`. **Always call `list_vibiz` first** when you don't know it — never guess. Pass `target` on every generation, list, post, ad, and analytics call. The auth-bound vibiz (legacy API-key tokens) implicitly has it; OAuth tokens require it.

## Tool surface — what's available

### Discovery
- `list_vibiz` — list brands the user can act on
- `vibiz_get_branding` — brand kit (colors, fonts, voice, logo)

### Workspace lifecycle
- `vibiz_create_from_url` — scrape a URL, create a vibiz with brand kit + ICPs + offers
- `vibiz_send_agent_email` — transactional email from the vibiz inbox

### Generation (creative production)
- `vibiz_generate_image` / `vibiz_generate_carousel` — static ad creatives
- `vibiz_generate_ad_video` — text-to-video ad
- `vibiz_animate_image` — image-to-video
- `vibiz_generate_ugc` — UGC-style spokesperson video
- `vibiz_generate_funnel` — landing-page funnel
- `vibiz_generate_qualification_funnel` — lead-qual funnel
- `vibiz_generate_icps` / `vibiz_list_icps` — create / read ideal customer profiles
- `vibiz_generate_offers` / `vibiz_list_offers` — create / read sales offers

### Social (Late API)
- `vibiz_social_list_accounts`, `vibiz_social_list_posts`, `vibiz_social_publish`
- All return `connectUrl` if no Late profile is connected.

### Inbox (DMs + comments)
- `vibiz_inbox_conversations`, `vibiz_inbox_comments`, `vibiz_inbox_reply_comment`, `vibiz_inbox_send_dm`

### Analytics
- `vibiz_analytics_top_posts`, `vibiz_analytics_daily_metrics`, `vibiz_analytics_best_time`

### Meta Ads (Zernio)
- `vibiz_meta_ads_accounts_list`, `vibiz_meta_ads_accounts_get_connect_url`
- `vibiz_meta_ads_campaigns_*` — list, get_tree, set_status, bulk_set_status, duplicate, delete
- `vibiz_meta_ads_creatives_*` — list, get, get_analytics, set_status, delete
- `vibiz_meta_ads_launch_boost_post`, `vibiz_meta_ads_launch_create`

## Behavioural rules — read before writing tool calls

1. **Always pass `target`** — never omit. If unknown, call `list_vibiz` first.
2. **Never silently swap brands.** If the user asks for brand X and `list_vibiz` doesn't have it, say so — do not generate against a different brand.
3. **Surface `viewUrl`** (deep link to the dashboard) on every result so the user can click to see it.
4. **Surface `connectUrl`** on every "no profile / no accounts" response. Don't paper over it.
5. **Confirm before paid actions.** Generation is free. `vibiz_social_publish` and any `vibiz_meta_ads_launch_*` cost money / reach. Show drafts first; let the user say go.
6. **Refuse security-sensitive commits as marketing material.** Subjects matching `password`, `secret`, `token`, `cve`, `vuln`, `xss`, `sqli`, `auth bypass` — don't post about them.

## Auth troubleshooting

If a tool returns `Unauthorized` or `not authenticated`:
1. Run `/mcp`.
2. Pick `vibiz`.
3. Choose **Authenticate**.
4. Complete the browser login (Clerk → WorkOS handoff).
5. Retry the tool.

If it returns `Protected resource ... does not match expected` — the canonical URL got out of sync. This shouldn't happen for plugin users (we pin to `https://www.vibiz.ai/api/mcp`) but if it does, file an issue.
