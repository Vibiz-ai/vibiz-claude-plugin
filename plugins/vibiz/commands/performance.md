---
description: Retrieve ad performance data and images for analysis and recommendations
argument-hint: [platform-campaign-id]
---

# /vibiz:performance

Pull campaign, ad set, and creative performance data — surface the top and bottom performers, fetch the actual ad images, and recommend what to create more of.

## Steps

1. **Pick the vibiz** via the [project-match skill](../skills/project-match/SKILL.md). Exactly one match → use it. Multiple → ask. Zero → suggest `/vibiz:onboard`.

2. **Get social accounts.** Call `vibiz_social_list_accounts({ target: { vibiz: "<slug>" } })`.
   - If empty + `connectUrl` → surface the link: "Connect your social accounts first →" and stop.
   - Remember each account's `id` (24-char Zernio ObjectId) for the next step.

3. **Get ad accounts.** For each social account from step 2, call `vibiz_meta_ads_accounts_list({ target: { vibiz: "<slug>" }, socialAccountId: "<id>" })`.
   - If no ad accounts found → surface `vibiz_meta_ads_accounts_get_connect_url` and stop.
   - If multiple ad accounts → ask the user which one.

4. **Pull campaigns.** If `$1` is set, use it as Meta platform campaign ID and call `vibiz_meta_ads_campaigns_get_tree({ target: { vibiz: "<slug>" } })` to get the full hierarchy, then filter to the matching campaign. Otherwise call `vibiz_meta_ads_campaigns_list({ target: { vibiz: "<slug>" }, status: "active" })` and pick the top 5 by spend.

   > **ID note:** campaign IDs here are Meta platform IDs (16-18 digit numeric, e.g. `"23859876543210000"`), returned as `platformCampaignId` from `campaigns_list`. NOT Zernio Mongo ObjectIds.

5. **Pull creative analytics.** For each campaign from step 4, call `vibiz_meta_ads_creatives_list({ target: { vibiz: "<slug>" }, campaignId: "<platformCampaignId>" })`. For the top creatives, call `vibiz_meta_ads_creatives_get_analytics({ target: { vibiz: "<slug>" }, adId: "<id>" })` where `adId` is the 24-char Zernio ObjectId from `creatives_list[].id`.

6. **Pull organic post performance.** Call `vibiz_analytics_top_posts({ target: { vibiz: "<slug>" } })` and `vibiz_analytics_daily_metrics({ target: { vibiz: "<slug>" } })` to add organic context.

7. **Fetch ad images.** For notable creatives from step 5, call `vibiz_meta_ads_creatives_get({ target: { vibiz: "<slug>" }, adId: "<id>" })` to get the full ad shape including image/video URLs, headline, body, and CTA. Present image URLs as clickable links and read them for visual analysis.

8. **Present the report.** Format as:

   ```
   ## Campaign Performance — <vibiz name>

   ### Paid (Meta Ads)
   | Campaign | Status | Spend | Impressions | Clicks | CTR | ROAS |
   |----------|--------|-------|-------------|--------|-----|------|
   | ...      | ...    | ...   | ...         | ...    | ... | ...  |

   #### Top Creatives (by CTR)
   1. **<creative name>** — CTR <x>%, spend $<y>
      Image: <url>
      Why it works: <1-line analysis based on the image + copy>

   #### Underperformers (bottom 3 by CTR)
   1. **<creative name>** — CTR <x>%, spend $<y>
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

9. **Offer follow-ups:**
   - "Want me to generate 3 new ad variants inspired by your top performer? → /vibiz:ad"
   - "Want to pause the underperformers? I can do that now."
   - "Want a deeper breakdown of a specific ad? Give me its ID."

## Sidecase handling

- **No active campaigns** → fall back to organic-only report from `vibiz_analytics_top_posts`. Tell the user "No active Meta Ads campaigns found — showing organic data only."
- **No organic data either** → "No performance data available yet. Run some ads with `/vibiz:launch` or publish posts with `/vibiz:post` first."
- **API rate limit** → surface the error, do not retry in a loop.
- **Creative has no image** (video-only or carousel) → note the format, still show the analytics, skip image analysis for that creative.

## ID glossary

| Name | Shape | Where it comes from |
|------|-------|---------------------|
| Meta platform campaign ID | 16-18 digit numeric | `campaigns_list[].platformCampaignId` |
| Zernio ad ID | 24-char hex ObjectId | `creatives_list[].id` |
| Meta platform ad ID | 16-18 digit numeric | `creatives_list[].platformAdId` |

Use the correct ID type for each tool — see the table above. Passing the wrong ID shape silently fails.

## Hard rules

- This command is **read-only**. Never pause, delete, or modify campaigns from here — only suggest it.
- Always pass `target: { vibiz: "<slug>" }` on every tool call.
- Never fabricate metrics. If a field is missing from the API response, show "—" not a guess.
- Surface `viewUrl` links to the Vibiz dashboard wherever available.
