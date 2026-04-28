---
description: Onboard the current repo as a Vibiz brand (auto-detects name + URL)
---

# /vibiz:onboard

Create a new vibiz (brand workspace) from the current repository so the user can generate ads, funnels, and posts about it.

## Steps

1. **Detect the project URL.** In order, check:
   - `package.json` → `homepage` field
   - `README.md` first 50 lines for any URL matching `https?://[a-z0-9.-]+\.[a-z]{2,}` that is NOT GitHub, npm, or docs links
   - The git remote URL (`git remote get-url origin`) — if it's a GitHub repo, ask the user "Is there a public website for this project? Paste the URL or press Enter to skip."
2. **Confirm with the user** before doing anything: "I'll create a new Vibiz brand from `<url>`. Sound good?" — wait for yes.
3. Call `mcp__vibiz__vibiz_create_from_url({ websiteUrl: "<url>" })`. This kicks off a Trigger.dev task that scrapes the brand kit, generates offers, and provisions the vibiz.
4. The tool returns `{ orgSlug, viewUrl }`. Show both to the user.
5. Ask: "Want me to also list ICPs and offers once they're done? (yes/no)"
   - If yes, after ~30 seconds call `mcp__vibiz__vibiz_list_icps({ target: { vibiz: "<slug>" } })` and `mcp__vibiz__vibiz_list_offers(...)` and surface the results.

## Sidecase handling

- If MCP is not authenticated → tell the user to run `/mcp` and authenticate first. Do NOT prompt for the URL yet.
- If no URL can be detected and the user skips, tell them they can run `/vibiz:onboard` again later or onboard manually at https://vibiz.ai.
- If the URL is a private/local URL (`localhost`, `127.0.0.1`, `*.internal`) — refuse and explain the brand kit needs a public website.
- If the project already exists as a vibiz (the `list_vibiz` output before this call already had a slug matching the inferred name), confirm with the user first: "Looks like you already have a vibiz called `<slug>`. Create a new one anyway, or skip?"
