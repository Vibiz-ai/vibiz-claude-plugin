---
description: Generate an ad creative (image or video) about what your repo does
argument-hint: [image|video] [prompt-override]
---

# /vibiz:ad

Generate a polished ad creative for the project in this repo. Pulls context from the README + recent commits to write the prompt automatically — or you can override it.

## Steps

1. **Pick the format.**
   - If `$1` is `video` → use `vibiz_generate_ad_video`.
   - If `$1` is `image` (or omitted) → use `vibiz_generate_image`.
   - If `$1` is something else, treat it as the prompt override and default to image.
2. **Pick the vibiz** via the [project-match skill](../skills/project-match/SKILL.md): detect this project's brand URL and match against `list_vibiz` by `websiteUrl`. Exactly one match → use it. Multiple → ask. Zero → suggest `/vibiz:onboard` (do NOT silently fall back).
3. **Build the prompt.** Unless the user passed an override (`$2` or `$1` when not image/video), generate one from:
   - First paragraph of `README.md` (skip badges + headers)
   - The last 3 commit subjects (`git log -3 --format='%s'`)
   - Project name from `package.json` `name` or the directory name
   Write a 1-2 sentence visual prompt focused on the user benefit ("a busy founder shipping …" beats "a screenshot of feature X").
4. **Confirm with the user** before generating: show the prompt + format + vibiz, ask "looks good?" — wait for yes.
5. **Call the tool.** With `target: { vibiz: "<slug>" }`, `useBrand: true`, default platform `instagram_portrait` for image / `9:16` for video.
6. **Surface the result.**
   - For image: poll `statusUrl` (returned in the response) every ~3s until `status: 'completed'`, then show `viewUrl` + the rendered image URL.
   - For video: same — but warn the user upfront video can take 60-180s.
7. **Offer follow-ups:**
   - "Want me to draft a social post to go with this? → /vibiz:post"
   - "Want to launch this as a paid Meta ad? → /vibiz:campaign" (TODO command)

## Sidecase handling

- Empty README + no commits → ask the user to type a one-line prompt themselves.
- Tool returns `connectUrl` (no Late profile) for downstream social/ad steps → surface the link and stop.
- Don't auto-launch paid spend. Generation is free; launching costs money.
