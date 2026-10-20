## 0.6.3-beta.1

- Move Acquisition & upgrades above Alternatives. Put source attribution in its own section, with author/profile distinction, denominators, publication dates, check dates and source links.
- Prioritize authored Wowhead/Icy Veins alternatives before observed Murlok profiles; keep the reserved verified dungeon option.
- Withdraw legacy single-dungeon/single-boss WCL evidence from Overall, alternatives and item tooltips. WCL popularity never selects Overall BiS; blocked Archon access is not presented as a working data feed.
- Collect two ranking pages per spec across all 8 seasonal dungeons and 10 Mythic raid encounters. Filter to a 14-day window, M+ keys >=10 and complete loadouts. Deduplicate by character, retaining the latest loadout per spec/mode.
- Gate statistical eligibility on all planned encounters having >=20 unique characters and >=200 unique characters overall. Display missing coverage explicitly. Keep detailed maps in the audit JSON and compact summaries in WoW.
- Seed real broad Arms/Subtlety snapshots; daily automation expands to all 40 specs, respects quota resets, retries transient errors and retains previous dated broad data on failure. Incomplete checkpoints are not published.
- Add source-attribution, section-order, pagination, temporal filtering, duplicate-character, coverage, quota and runtime-payload regressions.

## 0.6.2-beta.3

- Restore native item tooltips on ordinary hover. Build complete level-90 item strings with validated seasonal bonus IDs: Myth 6/6 (334), elevated raid (344), maximum-quality Myth crafted (331).
- Scale the native item and its stats instead of appending a target number to a base-level tooltip. Remove the Shift/base-preview branch.
- Keep source-item stats for Catalyst previews; preserve published crafted stat-pair bonuses through daily guide collection.
- Read unfinished equipped items' upgrade caps through C_Item.GetItemUpgradeInfo. Leave the actual equipped tooltip and rank intact.
- Remove Max-ilvl row clutter and repeated WCL/popularity/source diagnostics from Nexus-owned hover tooltips. Keep evidence in the details panel.
- Exclude unverified/off-season observed alternatives instead of inventing upgraded variants. Keep a dungeon alternative reserved whenever verified; use epic colors for the epic seasonal previews.
- Verify the three reported screenshot items against live Wowhead tooltips and SimulationCraft DBC data. Check all occupied Overall slots and native link fields, not just mocked item-level labels.

## 0.6.2-beta.2

- Show the best obtainable item-level target in Overall BiS and its alternatives, with the Myth 1/6–6/6 or crafted-quality range in details and tooltips.
- Distinguish ordinary Myth armor (334), elevated raid rewards (344), and maximum-quality Myth crafts (331). Show separate Ascendant targets for eligible slots (340, or 338 crafted), including the regional unlock dates.
- Stop treating stale target metadata and ID-only base tooltips as upgraded BiS previews. When no exact variant is available, show a target summary; Shift-hover opens an explicitly marked base tooltip with its original stats.
- Use native inventory tooltips for equipped comparison cards, including the exact second ring/trinket slot. Keep equipped ilvl separate from recommendation targets.
- Keep unverified source/season targets explicit instead of assigning a guessed level. Add all-spec coverage and target/native-tooltip regressions.

## 0.6.2-beta.1

- Keep only Overall BiS in Equipment; remove Raid/Mythic+ source selectors and ignore obsolete saved source selections.
- Show at most four distinct alternatives per slot, reserving a place for a verified dungeon option whenever available.
- Add authored Icy Veins gear options for all 40 specs to the existing Wowhead/Murlok pools. Label dungeon options explicitly; retain original source-item identity for Catalyst alternatives.
- Keep missing options explicit rather than padding lists. Include these sources in daily collection, preserving previous dated alternatives if temporarily unavailable.
- Test the four-option cap, dungeon reservation, item identity and all-spec selection. Data releases keep the current code version prefix.

## 0.6.1-beta.1 and daily data builds

- Remove the character model and artificial gaps; use compact aligned paper-doll columns and item-quality name colors.
- Fix false/nil socket visibility: only actual sockets and actual recommendations are shown.
- Read equipped ilvl from the native equipment ItemLocation, with full-link fallback. Do not use generic cached ilvl.
- Put Alternatives before acquisition/WCL details and include clearly labelled same-spec observed alternatives in Overall.
- Respect Catalyst stat retention: preview the original source item, compare available secondary-stat profiles and keep unverified variants labelled.
- Resolve unopened Adventure Guide routes asynchronously, limited to current-expansion raids and seasonal dungeons, with at most 24 loot reads per callback and saved native filters/state. Reuse verified boss encounter IDs for tier sources. No repeated chat errors.
- Enable daily data collection/testing/publishing. Show publication and last-check dates separately. Add Raider.IO EU affix context and honest Archon availability status; blocked Archon pages are not imported as gear data.
- Add screenshot-specific regression checks and a detailed Slovak update/install guide.

## 0.6.0-beta.4

- Import all 40 live Wowhead guides, preserving named sets, alternatives, publication dates and live patch checks.
- Separate authored activity sets from acquisition restrictions. Raid/M+ filters exclude crafted and unknown-source items; preserve original Catalyst drops for dungeon warnings and journal links.
- Use source-qualified guide priorities and verified same-spec observed alternatives rather than the old 128-item seed as the only source filter.
- Add anonymous WCL item usage in details/tooltips: 40 M+ contexts and 34 raid contexts, one ranking page each, with encounter, metric, sample size and retrieval date. Exclude samples below 20; no player profiles or credentials bundled.
- Refresh and validate guide/WCL snapshots as part of the data-release pipeline. Keep incompatible or failed candidates unpublished.
- Retain beta 3 paper-doll layout, compact Preparation and bounded Adventure Guide operations. Real-client testing remains necessary.

## 0.6.0-beta.3

- Restore paper-doll equipment layout, with armor on both sides and weapons below.
- Replace Preparation paging with compact scrolling cards. Show multiple socketed items together, with current/recommended gem icons and tooltips.
- Match icon borders to texture bounds; use native bright green/red ownership labels.
- Remove the all-expansion Adventure Guide scan and repeated manual UI updates. Open only a resolved boss/item through Blizzard's native function; unresolved sources leave the journal untouched.
- Add Overall, Raid and Mythic+ gear-source choices. Source-restricted alternatives remain experimental/incomplete; unknown sources are excluded and absence is labelled.
- Retain dungeon-entry warnings and reuse the visited dungeon's existing loot lookup for source evidence.
- Prepare a separate, manual, public Warcraft Logs API reader. It does not change addon recommendations until source validation is complete.

# 0.6.0 preview 2 — 2026-10-19

- One restrained Warcraft appearance replaces the previous skin variants.
- Gear becomes a single slot/item/status list with compact filtering and a separate detail pane.
- Primary navigation moves to the top; preparation uses six readable rows per page.
- Player profiles and talent modules remain removed.
- Live aggregate collection now covers 40 specs in both modes, plus M+ rankings and Mythic raid representation.
- Source publication dates are preserved separately from retrieval time.
- Prepared validation, 72-hour refresh and gated CurseForge release workflows.
- Still a preview: real-client rendering, combat taint and the first hosted release need verification.
