---
description: Retrieve ad performance data and images for analysis and recommendations
argument-hint: [platform-campaign-id]
---

# /vibiz:performance

Pull campaign, ad set, and creative performance data — surface the top and bottom performers, fetch the actual ad images, and recommend what to create more of.

## Steps

1. **Pick the vibiz** via the [project-match skill](../skills/project-match/SKILL.md). Exactly one match → use it. Multiple → ask. Zero → suggest `/vibiz:onboard`.

2. **Get social accounts.** Call `mcp__vibiz__vibiz_social_list_accounts({ target: { vibiz: "<slug>" } })`.
   - If empty + `connectUrl` → surface the link: "Connect your social accounts first →" and stop.
   - Remember each account's `id` (24-char Zernio ObjectId) for step 3.

3. **Get ad accounts.** For each social account from step 2, call `mcp__vibiz__vibiz_meta_ads_accounts_list({ target: { vibiz: "<slug>" }, socialAccountId: "<socialAccountId>" })`.
   - If no ad accounts found → surface `mcp__vibiz__vibiz_meta_ads_accounts_get_connect_url` and stop.
   - If multiple ad accounts → ask the user which one.
   - Remember the chosen ad account's `id` as `<adAccountId>` — it scopes all subsequent campaign/creative calls.

4. **Pull campaigns.** If `$1` is set, use it as Meta platform campaign ID and call `mcp__vibiz__vibiz_meta_ads_campaigns_get_tree({ target: { vibiz: "<slug>" }, adAccountId: "<adAccountId>" })` to get the full hierarchy, then filter to the matching campaign (show it regardless of status — the user asked for it specifically). Otherwise call `mcp__vibiz__vibiz_meta_ads_campaigns_list({ target: { vibiz: "<slug>" }, adAccountId: "<adAccountId>", status: "active" })` and pick the top 5 by spend.

   > **ID note:** campaign IDs here are Meta platform IDs (16-18 digit numeric, e.g. `"23859876543210000"`), returned as `platformCampaignId` from `campaigns_list`. NOT Zernio Mongo ObjectIds.

5. **Pull creative analytics.** For each campaign from step 4, call `mcp__vibiz__vibiz_meta_ads_creatives_list({ target: { vibiz: "<slug>" }, adAccountId: "<adAccountId>", campaignId: "<campaignId>" })` where `campaignId` is the Zernio ObjectId from `campaigns_list[].id` (NOT the `platformCampaignId`). For the top 5 creatives by spend, call `mcp__vibiz__vibiz_meta_ads_creatives_get_analytics({ target: { vibiz: "<slug>" }, adId: "<adId>" })` where `adId` is the Zernio ObjectId from `creatives_list[].id`.

6. **Pull organic post performance.** Call `mcp__vibiz__vibiz_analytics_top_posts({ target: { vibiz: "<slug>" } })`, `mcp__vibiz__vibiz_analytics_daily_metrics({ target: { vibiz: "<slug>" } })`, and `mcp__vibiz__vibiz_analytics_best_time({ target: { vibiz: "<slug>" } })`.

7. **Fetch ad images.** For the top 3 and bottom 3 creatives by CTR from step 5, call `mcp__vibiz__vibiz_meta_ads_creatives_get({ target: { vibiz: "<slug>" }, adId: "<adId>" })` where `adId` is the Zernio ObjectId from `creatives_list[].id`. This returns the full ad shape including image/video URLs, headline, body, and CTA. Present image URLs as clickable links and read them for visual analysis.

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

| Name | Shape | Where it comes from | Used by |
|------|-------|---------------------|---------|
| Social account ID | 24-char hex ObjectId | `social_list_accounts[].id` | `accounts_list(socialAccountId)` |
| Ad account ID | 24-char hex ObjectId | `accounts_list[].id` | `campaigns_list(adAccountId)`, `campaigns_get_tree(adAccountId)`, `creatives_list(adAccountId)` |
| Zernio campaign ID | 24-char hex ObjectId | `campaigns_list[].id` | `creatives_list(campaignId)` |
| Meta platform campaign ID | 16-18 digit numeric | `campaigns_list[].platformCampaignId` | display only, `$1` argument matching |
| Zernio ad/creative ID | 24-char hex ObjectId | `creatives_list[].id` | `creatives_get(adId)`, `creatives_get_analytics(adId)` |
| Meta platform ad ID | 16-18 digit numeric | `creatives_list[].platformAdId` | display only |

Use the correct ID type for each tool — see the "Used by" column. Passing the wrong ID shape silently fails.

## Hard rules

- This command is **read-only**. Never pause, delete, or modify campaigns from here — only suggest it.
- Always pass `target: { vibiz: "<slug>" }` on every tool call.
- Never fabricate metrics. If a field is missing from the API response, show "—" not a guess.
- Surface `viewUrl` links to the Vibiz dashboard wherever available.
