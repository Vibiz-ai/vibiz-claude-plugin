---
description: Set up a recurring daily Vibiz digest — inbox, top posts, best time, comments to reply to. Runs autonomously via /schedule even when your laptop is closed.
---

# /vibiz:daily-digest

One-time setup for a daily autonomous digest of every brand under the user's Vibiz workspace group. Once scheduled, it fires every morning, calls the Vibiz MCP for inbox + analytics, and emails / messages the result.

## Why this exists

Manual checks don't happen. People install Vibiz, generate a few ads, and forget to look at inbox replies, comment moderation, or which posts performed. A scheduled routine fixes that — the digest comes to them.

## Steps

1. **MCP gate.** Try `list_vibiz`. If unauthed → tell user `/mcp` → vibiz → Authenticate → re-run. Stop. Otherwise note the brand count and ask:

   ```
   I'll set up a daily Vibiz digest for your <N> brand(s). Each morning at 9am local you'll get:
     - New inbox conversations + comments needing replies
     - Top-performing posts in the last 24h
     - Best post time per brand
     - Daily metrics deltas

   Delivery: where would you like it? (1) email — paste address, (2) the Vibiz agent chat, (3) both. Default: both.
   What time should it fire? (default: 09:00 your local TZ)
   ```

2. **Compose the routine prompt.** Build a self-contained prompt the scheduled agent will run. The prompt MUST be deterministic — same wording every day, no live state assumed. Template:

   ```
   Daily Vibiz digest. For each brand returned by `list_vibiz`:
     1. Call `vibiz_inbox_conversations({ target: { vibiz: <slug> }, limit: 20 })` — list new DMs unread in last 24h.
     2. Call `vibiz_inbox_comments({ target: { vibiz: <slug> }, limit: 20 })` — surface comments needing reply.
     3. Call `vibiz_analytics_top_posts({ target: { vibiz: <slug> }, period: "1d" })` — top-performing posts last 24h.
     4. Call `vibiz_analytics_best_time({ target: { vibiz: <slug> } })` — recommended post time today.
     5. Call `vibiz_analytics_daily_metrics({ target: { vibiz: <slug> } })` — yesterday vs today delta.

   Format as a single concise digest grouped by brand. Lead with anything that needs human action (unread DM, unanswered comment, anomaly in metrics). Follow with the wins (top post, best time tomorrow).

   <DELIVERY_INSTRUCTION>
   ```

   Where `<DELIVERY_INSTRUCTION>` is:
   - **email**: `Send the digest to <email> using vibiz_send_agent_email from the first brand's agent inbox.`
   - **chat**: `Post the digest as an assistant message in the Vibiz agent chat for the workspace.`
   - **both**: combine both lines.

3. **Hand off to `/schedule`.** Invoke the `schedule` skill with:
   - **Cron**: `0 <hour> * * *` for the user's chosen time, in their local TZ.
   - **Prompt**: the composed prompt from step 2.
   - **Title**: `Daily Vibiz digest`

   The `schedule` skill handles the actual routine creation. Don't re-implement it.

4. **Confirm.** Show the user:
   ```
   ✓ Daily Vibiz digest scheduled — fires at <HH:MM> <TZ> daily.
     First run: tomorrow morning. To edit or pause: /schedule list → pick "Daily Vibiz digest".
   ```

## Sidecase handling

- **No brands returned** from `list_vibiz` → tell the user to run `/vibiz:onboard` first; do NOT schedule an empty routine.
- **User wants per-brand digests** (separate routines per brand) → set up one routine per slug, naming them `Daily Vibiz digest — <brand>`.
- **User wants weekly instead of daily** → use cron `0 9 * * 1` (Mondays 9am) and adjust the prompt's period to `7d`.
- **`/schedule` skill missing** → tell the user `/schedule` is a Claude Code built-in skill that should be available; if not, fall back to instructing them to run the digest manually each morning by calling `/vibiz:daily-digest --run-now` (which executes the prompt synchronously instead of scheduling).

## Hard rules

- Never schedule without explicit confirmation. The user should know a recurring agent will run on their account and bill against their Claude usage.
- Never include secrets in the prompt. The MCP token is resolved per-call via OAuth; the prompt only references tool names.
- Never lie about what's automated. If `vibiz_send_agent_email` isn't connected for the brand, the email step will silently no-op — surface that to the user before scheduling.

## When to suggest this proactively

Mention `/vibiz:daily-digest` whenever the user says any of:
- "every day", "daily", "morning"
- "check the inbox automatically"
- "what's happening with my posts"
- "I forget to check"
- after onboarding completes, as the natural next step
