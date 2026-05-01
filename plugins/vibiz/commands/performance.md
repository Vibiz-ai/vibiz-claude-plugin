---
description: Retrieve ad performance data and images for analysis and recommendations
argument-hint: [campaign-id]
---

# /vibiz:performance

Pull campaign, ad set, and creative performance data — surface the top and bottom performers, fetch the actual ad images, and recommend what to create more of.

## Steps

1. **Pick the vibiz** via the [project-match skill](../skills/project-match/SKILL.md). Exactly one match → use it. Multiple → ask. Zero → suggest `/vibiz:onboard`.

2. **Get the Meta Ads account.** Call `vibiz_meta_ads_accounts_list({ target: { vibiz: "<slug>" } })`.
   - If empty + `connectUrl` → surface the link: "Connect your Meta Ads account first →" and stop.
   - If multiple accounts → ask the user which one.

3. **Pull campaign tree.** If `$1` is set, use it as campaign ID and call `vibiz_meta_ads_campaigns_get_tree({ target: { vibiz: "<slug>" }, campaignId: "$1" })`. Otherwise call `vibiz_meta_ads_campaigns_list({ target: { vibiz: "<slug>" } })` and pick the top 5 active campaigns by spend.

4. **Pull creative analytics.** For each campaign from step 3, call `vibiz_meta_ads_creatives_list({ target: { vibiz: "<slug>" }, campaignId: "<id>" })` then `vibiz_meta_ads_creatives_get_analytics({ target: { vibiz: "<slug>" }, creativeId: "<id>" })` for each creative found.

5. **Pull organic post performance.** Call `vibiz_analytics_top_posts({ target: { vibiz: "<slug>" } })` and `vibiz_analytics_daily_metrics({ target: { vibiz: "<slug>" } })` to add organic context.

6. **Fetch ad images.** For each creative from step 4, extract the image URL from the creative data (returned by `vibiz_meta_ads_creatives_get`). Present these as clickable links and read them for visual analysis.

7. **Present the report.** Format as:

   ```
   ## Campaign Performance — <vibiz name>

   ### Paid (Meta Ads)
   | Campaign | Status | Spend | Impressions | Clicks | CTR | CPA |
   |----------|--------|-------|-------------|--------|-----|-----|
   | ...      | ...    | ...   | ...         | ...    | ... | ... |

   #### Top Creatives (by CTR)
   1. **<creative name>** — CTR <x>%, CPA $<y>
      Image: <url>
      Why it works: <1-line analysis based on the image + copy>

   #### Underperformers (bottom 3 by CTR)
   1. **<creative name>** — CTR <x>%, CPA $<y>
      Image: <url>
      Issue: <1-line diagnosis>

   ### Organic (Social)
   | Post | Platform | Likes | Comments | Shares | Engagement Rate |
   |------|----------|-------|----------|--------|-----------------|
   | ...  | ...      | ...   | ...      | ...    | ...             |

   ### Recommendations
   - **Create more like:** <top performer> — <what about its visual/copy works>
   - **Pause or rework:** <underperformer> — <what to change>
   - **Best posting time:** <from vibiz_analytics_best_time>
   ```

8. **Offer follow-ups:**
   - "Want me to generate 3 new ad variants inspired by your top performer? → /vibiz:ad"
   - "Want to pause the underperformers? I can do that now."
   - "Want a deeper breakdown of a specific campaign? Give me the campaign ID."

## Sidecase handling

- **No active campaigns** → fall back to organic-only report from `vibiz_analytics_top_posts`. Tell the user "No active Meta Ads campaigns found — showing organic data only."
- **No organic data either** → "No performance data available yet. Run some ads with `/vibiz:launch` or publish posts with `/vibiz:post` first."
- **API rate limit** → surface the error, do not retry in a loop.
- **Creative has no image** (video-only or carousel) → note the format, still show the analytics, skip image analysis for that creative.

## Hard rules

- This command is **read-only**. Never pause, delete, or modify campaigns from here — only suggest it.
- Always pass `target: { vibiz: "<slug>" }` on every tool call.
- Never fabricate metrics. If a field is missing from the API response, show "—" not a guess.
- Surface `viewUrl` links to the Vibiz dashboard wherever available.
