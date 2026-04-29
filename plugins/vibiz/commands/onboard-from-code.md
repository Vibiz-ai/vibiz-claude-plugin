---
description: Onboard the current repo as a Vibiz brand without scraping a website — synthesize the brand kit from local code (README, package.json, Tailwind config, etc.)
---

# /vibiz:onboard-from-code

For projects with no public marketing site (devtools, libraries, internal tools), or when the codebase is a more canonical brand source than a marketing site. Reads the local repo, synthesizes a brand kit, and creates a vibiz directly — no Firecrawl scrape, no ~30-60s wait.

## Steps

1. **MCP gate.** Try `list_vibiz`. If unauthed → tell user `/mcp` → vibiz → Authenticate → re-run. Stop.

2. **Match against existing vibizes** by company name (read `package.json` `name` and the README intro paragraph). If you find a clear match (same project, same brand), tell the user and stop:
   ```
   ✓ Found an existing vibiz that looks like this project: "<name>" (slug: <slug>)
      Reusing it. To force-create a new one, say: /vibiz:onboard-from-code --force
   ```

3. **Read the repo to synthesize the brand payload.** Read in this order, stop pulling once you have enough signal:

   - `package.json` — `name`, `description`, `homepage`, `dependencies` (for framework / component-lib detection).
   - `pyproject.toml` / `Cargo.toml` / `go.mod` — name + description fallback when no `package.json`.
   - `README.md` or `README.mdx` — first ~200 lines. Use the intro paragraph as `headline`, the "Features" / "Why X" sections for `description` and `keyFeatures`, the writing style for `tone`.
   - `tailwind.config.{js,ts}` — extract `theme.extend.colors` into `brand.colors` (`primary`, `secondary`, `accent`).
   - `app/globals.css` / `src/index.css` / similar — `:root { --primary: ... }` CSS variables fall back here.
   - `next.config.{js,ts}` — confirm framework. Check `dependencies` for `react`/`next`/`vite`/`fastapi`/`axum`/etc.
   - Component imports (grep for `@radix-ui`, `shadcn`, `@chakra-ui`, `@mui`) → `componentLibrary`.

4. **Refuse to invent values.** If you can't detect a color, leave it out — don't guess. The MCP tool accepts partial payloads. Same for `logoUrl` — only set it if there's a CDN-hosted logo URL in the README (e.g. a public S3 / Vercel asset). Don't pass local paths like `./public/logo.svg`.

5. **Confirm with the user before creating.** Show what you'll send:
   ```
   I'll create a vibiz from this code:
     - Name: <companyName>
     - Headline: <headline>
     - Tone: <tone>
     - Stack: <framework> + <componentLibrary>
     - Colors: <primary> / <secondary> / <accent>
     - Audience guess: <targetAudience>

   No website scrape — branding goes straight to the kit.
   Sound good? (yes / no / edit field <name>)
   ```

6. **On yes** → call `vibiz_create_from_code({ brand: <payload> })`. Show the returned `vibiz.slug`. Tell the user ICP + offer discovery is running in the background (~1-2 minutes, paid plans only) and give them the slug for `/vibiz:ad`, `/vibiz:post`, etc.

7. **Optional follow-up.** Once the vibiz exists, ask:
   > Want me to (1) generate 3 ad variants now, or (2) draft a launch post about your latest commit?

## Sidecase handling

- **Public website detected in `package.json` `homepage` AND it's reachable** → suggest `/vibiz:onboard <url>` instead — Firecrawl picks up things the README misses (real product screenshots, about page, OG images). Tell the user so they can choose.
- **`--force` flag** → skip the existing-vibiz match step, create a new one from code anyway.
- **No README and no package.json description** → ask the user for a one-line pitch before proceeding. Don't ship an empty brand kit.
- **Tailwind / CSS variables use semantic names** (e.g. `--brand`, `--accent-foreground`) → take the literal hex values, not the variable names.

## Hard rules

- Never auto-create a vibiz without explicit "yes" from the user. Onboarding is visible work.
- Never invent color values, logo URLs, or fonts. Empty fields are fine.
- Never echo the underlying Clerk org id (`org_*`) — only show the slug + name.
- Never call `vibiz_create_from_code` with `companyName` empty or whitespace — the server rejects it.
