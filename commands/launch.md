---
description: Full marketing kit — onboard the repo, generate offers, ICPs, and 3 ads
---

# /vibiz:launch

Run a full Vibiz onboarding flow: detect the project URL → create a vibiz → list the offers + ICPs Vibiz auto-discovered → generate 3 ad creative variants. End-to-end in one command.

## Steps

1. **Check status.** Run the equivalent of `/vibiz:status` silently. If MCP is not authed, halt and tell the user to run `/mcp`.
2. **Onboard.** If `list_vibiz` is empty for this repo's URL, run the `/vibiz:onboard` flow. If the URL already maps to an existing vibiz, skip to step 3.
3. **Show what was discovered.**
   - `mcp__vibiz__vibiz_list_icps({ target: { vibiz: "<slug>" } })` → format as `Name | Title | Pain points (truncated)`.
   - `mcp__vibiz__vibiz_list_offers(...)` → format as `Title | Price | Type`.
4. **Confirm with the user** before spending any generation budget: "I'll generate 3 ad image variants based on the top offer. ~30 seconds. Continue?"
5. **Generate 3 ads.** Pick the first offer's title as the seed. Call `vibiz_generate_image` 3 times with `imageCount: 1` and slightly varied prompts (one each: hero/lifestyle, product-shot, social-proof). Use the same `target: { vibiz }`.
6. **Summary.** Show:
   - Vibiz `viewUrl`
   - ICPs page deep link
   - Offers page deep link
   - The 3 ad `viewUrl`s
   - Suggested next: `/vibiz:post` for organic, or "say 'launch a Meta campaign' to spend on it".

## Sidecase handling

- If the project has no public website, fall back to "I can still create a vibiz from text — describe what your project does in one sentence." Then call the appropriate creation flow (or punt to the dashboard if MCP doesn't expose a text-only creator).
- If the MCP rate-limits image generation, surface the actual error and stop — do NOT auto-retry forever.
- Cap total spend per `/vibiz:launch` at 3 image generations. The user can run again if they want more.
