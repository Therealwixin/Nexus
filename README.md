# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.6 uses a compact character-panel slot layout without a character model, scrolling Preparation cards and exact socket-row counts. Equipment uses the selected spec's native talent background with a dim overlay and eight slots per column; both weapons sit below Wrists on the left. It imports all 40 live Wowhead guides, source-qualified dungeon/raid alternatives and anonymous WCL usage evidence. Item names use quality colors, equipped ilvl uses the native item location, and Catalyst variants keep source-item stats. Player-profile browsing and talent databases remain removed.

- **Equipment:** Raid (authored Wowhead guide) or Mythic+ (Murlok top-profile usage), up to four verified alternatives per slot, and current-character ownership. Activity is separate from acquisition: both modes include raid, dungeon and crafted items.
- **Stats:** Murlok M+ references for all 40 specs, native active-character values, rating gaps and verified rating-derived DR details on hover.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings and Mythic raid representation, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. Raid representation is not a direct class-strength ranking. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

Equipment has two activity contexts: Raid uses the existing authored Wowhead all-source guide; Mythic+ selects the most-used verified current-season item per slot from Murlok M+ profiles. This is an observed reference, not a simulated optimal combined set. The Raid label does not assert the imported all-source guide is an independently authored raid-only performance list. Both modes retain up to four distinct verified alternatives per slot. A dungeon option is reserved whenever one is known. Wowhead, Icy Veins and same-spec observed alternatives are labelled by source. Lists are not padded when source data is incomplete. Catalyst alternatives retain the original source item. See [DATA-SOURCES.md](DATA-SOURCES.md) for actual coverage.

The addon is still a preview. Real-client appearance and combat behavior require testing; the Lua simulator does not reproduce WoW's renderer or secure execution.

## Development

Python 3.12 and `lupa==2.8` are used outside the game:

    python tools/refresh_gear.py --validate-only
    python tools/test_lean.py
    python tools/test_maintenance.py
    python tools/test_guides.py
    python tools/test_wcl.py
    python tools/package.py --output dist

The live Wowhead collector was exercised across all 40 specs on 2026-10-20; published source timestamps and live patch are preserved. Preparation, aggregate gear and meta inputs retain their own published timestamps. Collection writes a candidate; staging, tests and publishing are separate steps. An incompatible guide patch or missing complete authored set prevents replacing the last verified snapshot.

    python tools/refresh_gear.py
    python tools/data_release.py stage --keep-version

Daily data collection, validation and configured publishing are enabled. See [AKTUALIZACIE_SK.md](AKTUALIZACIE_SK.md) for the detailed Slovak installation/update guide and [SETUP.md](SETUP.md) for setup details. The prepared project description is in [CURSEFORGE.md](CURSEFORGE.md).

No API keys or game libraries are bundled in the addon. Existing owner license terms are retained in `Nexus/LICENSE.txt`.

## Warcraft Logs and Archon

**Refresh Nexus data** updates authored Wowhead/Icy Veins guides, Murlok aggregates, item-effect bonuses and meta daily at 04:17 UTC. It never waits for WCL and retains the last verified WCL snapshot.

**Refresh weekly WCL evidence** performs a cheap daily due check at 04:47 UTC, without calling WCL when not due. Broad collection runs approximately weekly; failures retry on the next daily check. It reads two ranking pages per spec across all 8 seasonal dungeons and 10 raid encounters, filters the last 14 days (M+ keys >=10), and deduplicates characters. Eligibility requires at least 20 usable characters per encounter and 200 per spec/mode. These ranked samples never select or reorder BiS.

Completed anonymous spec/mode summaries are cached even on collection failure. Compatible checkpoints resume for up to 48 hours while retaining their original window/date; incompatible or expired checkpoints restart. Only complete 40-spec collections are committed, and the next daily addon package includes them. The hours-long API collection has a separate concurrency group; only its short publication phase shares the daily write lock. Requests are paced and transient rate limits retried. No credentials, player identities, private reports or event streams are bundled.

**Verify Warcraft Logs** remains a manual OAuth/quota diagnostic using repository secrets `WCL_CLIENT_ID` and `WCL_CLIENT_SECRET`. Optional single-encounter diagnostic outputs never replace broad addon evidence.

Raider.IO provides EU affix context through its public API. Archon build data is not integrated: the public gear page currently returns human verification. The daily collector reports that status honestly without bypassing the check or treating it as gear data. Publication and last-check dates are shown separately.

### Archon aggregate access investigation (2026-10-21)

No documented public endpoint for the precomputed WoW build/gear aggregates was found. The API documentation linked by Archon's help collection documents Warcraft Logs OAuth/GraphQL, which does not establish access to Archon's separate build aggregates. Our existing WCL credentials must not be labeled as an Archon integration or counted as an independent evidence source.

Archon's September 29 API update announces an API refresh and temporarily reduced quotas for newly created keys; it does not announce a public gear aggregate endpoint. The next concrete step is to ask `support@archon.gg` for an approved aggregate feed/partner API and permission to distribute derived snapshots in the Nexus addon. Ask for coverage across all 40 specs (M+/raid), sample denominators, patch/season, source/update timestamps, permitted snapshot retention/distribution, attribution, quotas and refresh frequency. A weekly aggregate export would avoid per-player calls. Keep collection outside the game and bundle only validated anonymous aggregates after access is confirmed.

Sources:
- https://www.archon.gg/wow/articles/help/help-and-faq-collection
- https://www.archon.gg/classic-vanilla/articles/help/api-documentation
- https://www.archon.gg/eso/articles/news/api-updates-are-on-the-way
- https://www.archon.gg/classic-sod/articles/help/rpg-logs-api-terms-of-service

Suggested access request (not sent):

> Subject: Nexus WoW addon — access to aggregated gear/build data
>
> Hello Archon team, I develop Nexus, a WoW gear and preparation addon (https://github.com/Therealwixin/Nexus). Do you offer an approved API, scheduled aggregate export, or partner feed for your WoW gear/build statistics across all 40 specializations in Mythic+ and raids? We want anonymous aggregate item usage, sample sizes, patch/season and update timestamps, collected centrally about once per week, with attribution and no per-player data requests from the addon. Please confirm permitted distribution of derived snapshots inside addon releases, cache/retention limits, rate limits, required credentials and any licensing or fees. We already have WCL API credentials but understand these may not grant access to Archon's build aggregates. Thank you.
