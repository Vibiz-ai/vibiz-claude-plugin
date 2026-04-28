# Vibiz for Claude Code

Generate ads, funnels, ICPs, social posts, and full Meta campaigns from inside Claude Code. Drafts a marketing post about every commit you make.

```
/plugin install Vibiz-ai/vibiz
```

Then authenticate once:

```
/mcp
```

Pick `vibiz` → **Authenticate** → done. No URL, no API key, no token paste.

## What you get

**5 slash commands**

| Command | What it does |
|---|---|
| `/vibiz:status` | Show MCP connection + list your brands |
| `/vibiz:onboard` | Auto-create a Vibiz brand from this repo (URL + brand kit + offers + ICPs) |
| `/vibiz:post [sha]` | Draft a social post about your latest commit (or a specific one). Optionally publish it. |
| `/vibiz:ad [image\|video]` | Generate an ad creative based on what your repo does |
| `/vibiz:launch` | Full kit: onboard, list offers/ICPs, generate 3 ad variants — end to end |

**A subagent**

`vibiz-marketer` — call it when you want code or commits turned into marketing copy. Knows the full Vibiz tool surface and the brand-voice rules.

**A "post about your commit?" hook**

After every successful `git commit`, the plugin checks if the change is post-worthy and gently offers `/vibiz:post`. Skips merge commits, security fixes, boring chores (`chore:` / `build:` / `ci:` / `style:` / `docs:` / `test:`), tiny diffs (<5 lines), and anything tagged `[skip-vibiz]` or `[no-post]` in the commit body.

## What Vibiz is

[Vibiz](https://vibiz.ai) is an AI marketing platform — ad creatives, landing pages, social publishing, and Meta Ads campaigns, all driven from a brand kit it scrapes from any URL.

This plugin exposes 40 Vibiz MCP tools to Claude Code:

- **Generation** — images, carousels, videos, UGC, funnels, ICPs, offers
- **Social** — list accounts, list posts, publish/schedule across IG / FB / TikTok / X / LinkedIn / Threads
- **Inbox** — list DMs, list commented posts, reply to comments, send DMs
- **Analytics** — top posts, daily metrics, best posting times
- **Meta Ads (Zernio)** — list / get / pause / resume / duplicate / delete campaigns + creatives, boost a post, launch a standalone ad

## Install (manual / dev)

If you want to develop on this plugin locally:

```bash
git clone https://github.com/Vibiz-ai/vibiz ~/.claude/plugins/vibiz
```

…and Claude Code will pick it up on next start.

## Skip the post nudge for a commit

```
git commit -m "fix: something" -m "[skip-vibiz]"
```

## License

MIT — see [LICENSE](./LICENSE).
