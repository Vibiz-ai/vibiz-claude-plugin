---
description: Check Vibiz MCP connection, match this project to a vibiz, list available brands
---

# /vibiz:status

Verify the MCP is authenticated and try to **match the current local project** to one of the user's vibizes. This is usually the first command the user runs.

## Steps

1. **Try `list_vibiz`.** If it fails with `Unauthorized` / `not authenticated`:
   - Tell the user to run `/mcp`, pick `vibiz`, choose **Authenticate**, finish the browser login, then re-run `/vibiz:status`.
   - Stop here — do nothing else.
2. **Detect this project's brand URL** using the [project-match skill](../skills/project-match/SKILL.md):
   - Try `package.json` `homepage`, then `pyproject.toml` / `Cargo.toml` `homepage`, then the first non-badge non-github link in the README.
   - Skip private / local URLs.
3. **Match** the detected URL against each vibiz's `websiteUrl` from step 1, after normalizing both sides (lowercase, strip protocol/www/trailing-slash, host + first path segment only).
4. **Report.** Output is one of:

   **A. MCP not authed**
   ```
   ❌ Vibiz MCP — not authenticated. Run /mcp → vibiz → Authenticate.
   ```

   **B. No vibizes at all**
   ```
   ✓ Vibiz MCP — connected
   ⚠ You don't have any vibizes yet. Run /vibiz:onboard to create one from this project, or sign up at https://vibiz.ai.
   ```

   **C. Project URL detected, exact match found**
   ```
   ✓ Vibiz MCP — connected
   ✓ Matched this project (<detected-url>) → vibiz "<name>" (slug: <slug>)
      Subsequent /vibiz commands will scope to this vibiz automatically.
   Other vibizes available: <name1>, <name2>, …
   ```

   **D. Project URL detected, NO match**
   ```
   ✓ Vibiz MCP — connected
   ⚠ This project (<detected-url>) is not yet onboarded as a vibiz.
   Available vibizes: <name1>, <name2>, …
   Run /vibiz:onboard to create a new one for this project, or pick one of the above by name.
   ```

   **E. No detectable URL**
   ```
   ✓ Vibiz MCP — connected
   Available vibizes: <name1>, <name2>, …
   I couldn't auto-detect a brand URL from this repo (no package.json homepage, no obvious link in README). Tell me which vibiz to use, or run /vibiz:onboard with a URL.
   ```
5. **Remember the matched slug for this session** — quote it explicitly in your message ("using vibiz `<slug>` for the rest of this session") so subsequent tool calls inherit the choice.

## Hard rules

- This command is read-only. Never call `vibiz_create_from_url` from `/vibiz:status` — that's `/vibiz:onboard`.
- Never silently fall back to "the only vibiz" when matching produces zero results — surface the mismatch.
- Keep the response under ~12 lines.
