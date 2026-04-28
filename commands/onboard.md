---
description: Onboard the current repo as a Vibiz brand (matches against existing vibizes first; only creates if none match)
---

# /vibiz:onboard

End-to-end flow: detect this project's URL → check for an existing vibiz → only create a new one if no match.

## Steps

1. **MCP gate.** Try `list_vibiz`. If unauthed → tell user `/mcp` → vibiz → Authenticate → re-run. Stop.
2. **Detect this project's brand URL** using the [project-match skill](../skills/project-match/SKILL.md). Same fallback chain: `package.json` `homepage` → `pyproject.toml` / `Cargo.toml` → first non-badge non-github link in README → ask user.
3. **Match against existing vibizes** (using normalized `websiteUrl` comparison from the project-match skill).
4. **Branch on the match outcome:**

   **Existing match found** → tell the user, do NOT create another.
   ```
   ✓ Found an existing vibiz for <url>: "<name>" (slug: <slug>)
      Reusing it. To force-create a new one, say: /vibiz:onboard --force <url>
   ```
   Then list ICPs + offers from that vibiz so the user knows what's already in there.

   **No match** → confirm with the user before creating:
   ```
   I'll scrape <url> and create a new vibiz from it. This:
     - generates a brand kit (colors, fonts, logo, voice)
     - auto-discovers ICPs and offers
     - takes ~30 seconds
   Sound good? (yes / no / use a different URL)
   ```
   On yes → call `vibiz_create_from_url({ websiteUrl: "<url>" })`. Show the returned `viewUrl`. Tell the user the slug for use on later commands.

   **No URL detected** → ask: "Paste the public URL for this project, or skip."
5. **Optional follow-up.** Once a vibiz is matched OR created, ask:
   > Want me to (1) generate 3 ad variants now, or (2) draft a launch post about your latest commit?
   Map answers to `/vibiz:launch` and `/vibiz:post` respectively.

## Sidecase handling

- **Local / private URLs** (`localhost`, `127.0.0.1`, `*.internal`, `*.local`, `*.test`) → refuse, explain the brand kit needs a public URL.
- **`--force <url>`** flag in `$1` → skip the matching step, go straight to `vibiz_create_from_url`. Useful when the detected URL was wrong.
- **GitHub repo with no clear product site** → ask the user explicitly. Don't silently use the GitHub URL as the brand URL — that's almost never what they want.
- **Existing match but it's clearly the wrong vibiz** (user says "no, that's a different brand") → suggest `/vibiz:onboard --force <correct-url>`.
- **Trigger.dev task fails** → surface the error verbatim, do not retry, do not pretend it succeeded.

## Hard rules

- Never auto-create a vibiz without explicit "yes" from the user when the URL was auto-detected. Onboarding is visible work.
- Never silently swap to a different vibiz than the one the user requested.
- Never log or echo the underlying Clerk org id (`org_*`).
