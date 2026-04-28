---
description: Draft a social media post about your most recent commit (or a specific commit)
argument-hint: [commit-sha]
---

# /vibiz:post

Turn a code change into a marketing-ready social post. Reads the latest commit (or a specific SHA passed as `$1`), writes draft post text in the brand voice, generates a matching image, and offers to schedule/publish it.

## Steps

1. **Pick the commit.**
   - If `$1` is set, use it: `git show --stat $1` and `git log -1 --format='%H %s%n%b' $1`.
   - Else: `git log -1 --format='%H %s%n%b'` and `git diff HEAD~1 HEAD --stat`.
2. **Filter out commits that are bad post material.** Skip + tell the user, do NOT proceed silently:
   - Merge commits (`git rev-list --merges -n 1 <sha>` returns the sha)
   - Diff stat is fewer than 5 lines changed
   - Commit subject matches `/^(chore|build|ci|style|docs)(\(|:)/i` (boring infra)
   - Commit subject contains: `password`, `secret`, `token`, `cve`, `vuln`, `xss`, `sqli`, `auth bypass` (security/sensitive)
   - Commit body has `[skip-vibiz]` or `[no-post]`
3. **Pick the vibiz.**
   - Call `mcp__vibiz__list_vibiz`. If exactly one, use it. If multiple, ask the user which one. If zero, suggest `/vibiz:onboard`.
4. **Draft the post.** Compose 2-3 short copy variants (Twitter/X-friendly: under 280 chars each) that:
   - Lead with the user-visible benefit ("now you can …", "we just shipped …", "fixed the X annoyance"), NOT internal jargon
   - Avoid file paths, function names, library versions
   - Include a relevant emoji at the start (1 max)
   - End with a soft CTA ("try it →" or "ship it now →") only if the brand has a website to link to
5. **Generate a matching image.** Call `mcp__vibiz__vibiz_generate_image({ target: { vibiz: "<slug>" }, prompt: "<short visual prompt derived from the commit>", platform: "instagram_portrait", style: "branded-ad", useBrand: true })`.
6. **Show the user.** Output:
   - The draft variants (numbered)
   - The image `viewUrl` from step 5
   - Three options: `1) post it now`, `2) schedule it`, `3) just give me the draft`
7. **If user picks 1 or 2:**
   - Call `mcp__vibiz__vibiz_social_list_accounts({ target: { vibiz: "<slug>" } })`. If empty + `connectUrl` returned, surface the connect link and stop.
   - Otherwise ask which platform(s), pick the matching `accountId`s, and call `mcp__vibiz__vibiz_social_publish` with the chosen variant + image URL + (for option 2) a `scheduledFor` ISO datetime the user provides.

## Sidecase handling

- Working tree must have at least one commit. If `git rev-parse HEAD` fails, tell the user there's nothing to post about yet.
- If MCP is not authenticated → run `/mcp` first, do not silently fall through.
- NEVER auto-publish without the user explicitly choosing option 1 or 2 in step 6. Drafts are zero-cost; publishing isn't.
- If `vibiz_generate_image` fails or times out, still surface the draft text so the work isn't wasted.
