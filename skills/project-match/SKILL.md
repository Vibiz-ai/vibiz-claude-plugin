---
name: project-match
description: Detect the local project's brand URL and match it to an existing vibiz, or create one if none matches.
---

# Project ⇄ Vibiz matching

Whenever the user asks for a Vibiz tool that needs a `target.vibiz`, you should match the **current local project** against their existing vibizes — and only ask them which one to use if matching is ambiguous. This skill describes how.

## Step 1 — Detect the project's brand URL

Try in order, stop at the first one that yields a public, parseable URL:

1. **`package.json`** — read the `homepage` field. (Skip `repository` — that's a git URL, not a brand URL.)
2. **`pyproject.toml`** — `[project].urls.Homepage` or `[tool.poetry].homepage`.
3. **`Cargo.toml`** — `[package].homepage`.
4. **`README.md` / `README.mdx`** — first 100 lines, find the first link of the form `https?://<host>` that is NOT:
   - github.com / gitlab.com / bitbucket.org
   - npmjs.com / pypi.org / crates.io / rubygems.org
   - badge providers (`shields.io`, `img.shields.io`, `badge.fury.io`, `flat.badgen.net`)
   - docs hosts (`readthedocs.io`, `gitbook.com`, `docs.rs`)
   - any line starting with `[![` (markdown badge image)
5. **git remote** — `git remote get-url origin`. If it's a GitHub repo, do NOT use it as the brand URL; instead ask the user "what's the public website for this project?" (Enter to skip.)
6. If everything fails — ask the user.

Refuse private/local URLs: `localhost`, `127.0.0.1`, `*.local`, `*.internal`, `*.test`. Tell the user the brand kit needs a public website.

## Step 2 — Normalize for matching

Both sides (the detected URL + each vibiz's `websiteUrl`) get the same treatment:

```
1. lowercase
2. strip leading 'http://' or 'https://'
3. strip leading 'www.'
4. strip trailing '/'
5. take the host + first path segment only (drop query strings, hashes, deep paths)
```

Examples:
- `https://www.Stripe.com/` → `stripe.com`
- `https://stripe.com/payments` → `stripe.com`  (we keep just the host for top-level brand sites)
- `https://shop.example.com` → `shop.example.com`  (subdomains DO matter — different brand)

## Step 3 — Match against `list_vibiz`

Call `list_vibiz` (returns `[{ name, slug, websiteUrl, logoUrl }]`). Apply the same normalization to each vibiz's `websiteUrl`. Compare strings.

**Outcomes:**
- **Exactly one match** → tell the user "Matched this project to vibiz **<name>**" and use `target: { vibiz: "<slug>" }` from then on. Do NOT ask them to pick.
- **Multiple matches** (rare — same URL across vibizes) → list them and ask which one.
- **Zero matches** → the project hasn't been onboarded. Offer:
  > I don't see a vibiz for `<url>` yet. Want me to create one? (yes / no / use a different vibiz)

  If yes → call `vibiz_create_from_url({ websiteUrl })` (see `/vibiz:onboard` for the full flow).

## Step 4 — Cache the match for the session

Once you've matched, remember the slug for the rest of the session — don't re-detect on every command. (You can't write to a file from a slash command, but you can keep it in conversation context: state "using vibiz `<slug>` for this session" once, and reference it on later calls.)

## Anti-patterns

- **Don't silently fall back** to a different vibiz when matching fails. Always tell the user.
- **Don't match on `name`** (free-form) — match on `websiteUrl` (canonical). Names collide; URLs don't.
- **Don't trust git remote** as a brand URL — it's almost always a code-hosting URL, not the product site.
- **Don't auto-create** without explicit user confirmation. Onboarding is cheap but visible (it kicks off a Trigger.dev brand-scrape job).
