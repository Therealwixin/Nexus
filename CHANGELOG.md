## 0.6.6-beta.4

- Fit the complete specialization artwork inside the equipment pane instead of cropping it to fill the pane. Preserve the original aspect ratio and full atlas UV range, center the illustration and never enlarge it beyond native dimensions.
- Cover wide, tall, square and small textures at supported window sizes, in addition to the existing specialization/atlas fallback checks.

## 0.6.6-beta.3

- Add the selected specialization's native Blizzard talent artwork behind equipment. Use the client's mapping when already loaded, otherwise resolve the known talent atlas naming scheme, and check atlas availability before use.
- Keep illustration proportions with atlas-aware cropping, subdued opacity and a readability overlay. Reuse one static texture; no image downloads, animations or talent-addon loading.
- Place Main hand and Off hand directly below Wrists in the left column. Both columns now contain eight slots, removing the disconnected bottom weapon row.
- Verify selected-spec changes across all 40 catalog entries, Devourer art selection, both gear views, native mapping overrides, missing-atlas fallback and responsive slot bounds.

## 0.6.6-beta.2

- Refine both equipment views with native WoW Quickslot bevels, quality borders, quieter backgrounds, vertically grouped slot/name/status labels and the native quest highlight for selection. Keep paper-doll placement and native hover tooltips.
- Fix Icy Veins primary-item parsing: handle the published wowxptr namespace and select only the direct gear tooltip, never nested gems or enchants. Reparse all 40 cached source guides without changing source publication/check dates.
- Reject known gems and native non-equippable items from runtime gear candidates and alternatives, even if imported source metadata labels them as raid drops.
- Add nested-gem/PTR regression fixtures, all-spec stored gem exclusion checks, runtime non-gear guards and native slot bounds across supported window sizes.

## 0.6.6-beta.1

- Separate Equipment by activity: Raid uses the existing authored Wowhead guide; Mythic+ uses observed Murlok M+ item usage. Both include all acquisition sources, including crafted and raid gear.
- Fix Devourer offhand selection: M+ selects the observed crafted Spellbreaker's Warglaive instead of overriding it with the authored Baleful Hexblade target. Keep counts and source dates visible; do not present independent per-slot popularity as a simulated optimal set.
- Preserve up to four distinct alternatives and a verified dungeon option where available. Keep M+ ring/trinket slots distinct, exclude unobserved guide rows and off-season items, and never silently substitute the Raid primary when observations are missing.
- Match dungeon-entry notifications to the active spec's primary M+ recommendations, retaining strict ownership and source-ID checks.
- Remove the square gold outline around active navigation buttons; retain native red textures and white/gold label states.
- Cover the Devourer source conflict, activity switching, all-spec popularity/variant validity, paired slots, alternative limits, source isolation and minimum-width layout.

## 0.6.5-beta.3

- Restore native WoW red button textures, bevels and hover states for the main navigation. Use larger Friz Quadrata labels, classic gold text and a white/gold active selection instead of flat grey underlined links.
- Document the verified distinction between WCL API access and Archon build aggregates, with a concrete aggregate-feed access request. No unverified feed or credentials are introduced.

## 0.6.5-beta.2

- Add Equipped / In bags filters to Preparation → Sockets & Gems, with Missing only applied to the selected location.
- Preserve separate bag copies and complete variant links, gems and actual socket counts. Refresh through existing bag events; keep stack counts for ownership and consumables.
- Show regular gem plans for bag gear; defer unique Diamond planning until equipped to avoid treating spare pieces as one loadout.
- Cover duplicate variants, native tooltips, bag removal, scoped empty states, Diamond isolation and compact filter layout in the Lua simulation.

## 0.6.5-beta.1

- Add a restrained Stats tab between Equipment and Preparation, using the shared 40-spec selector. Show Murlok M+ secondary/minor reference bars as a compact rating/percentage table with current-character values and signed rating differences.
- Ordinary hover and the detail panel explain below/above-reference gaps, percentage-point differences, marginal DR, next rating boundary and rating-derived cap. Distinguish Mastery points from effect percentages and buffs/base stats from rating.
- Read live values from native APIs only for the active level-90 spec. Guard combat/secret values and incompatible patches; refresh via player stat events without equipment rescans or polling.
- Extract current DR curves during daily collection and validate modeled gains against native rating bonuses. Hide unsupported/mismatched calculations; no invented Speed cap.
- Preserve published stat priorities, sample sizes, source/check dates and previous dated references on source failure. No individual player requests or profiles are introduced.
- Test all 40 profiles, parser failures, zeros, DR boundaries/caps, Mastery/buffs, secret values, live hover, event coalescing and minimum/maximum table layouts.

## 0.6.4-beta.2

- Restrict dungeon-entry alerts to the active specialization's primary authored BiS targets. Source-restricted alternatives and observed M+ items no longer inflate the popup.
- Match Catalyst recommendations against the original dungeon drop ID and label the conversion explicitly.
- Keep ownership checks, paired-slot/source deduplication and the existing per-visit notification limits.
- Add a six-loot/two-BiS regression, alternative-only pool, exact Catalyst source, ownership and banner-label checks.

## 0.6.4-beta.1

- Integrate the latest authored/Murlok refresh with the Catalyst passive-effect fixes.
- Run daily guide, item-bonus and meta publication independently of WCL. Keep the last validated WCL snapshot.
- Add a separate weekly WCL workflow with a cheap daily due check and automatic retry after failed collections. Only its short publication phase shares the daily write lock.
- Persist anonymous completed spec/mode summaries even after failures; resume compatible checkpoints within 48 hours without changing the original sampling window. Reject incomplete publications.
- Pace API queries and honor numeric Retry-After on transient rate limits. Expand interruption/resumption, cadence, stale-window and publication-isolation regressions.

## 0.6.3-beta.2

- Preserve published source-item passive effects in maximum-ilvl and Catalyst previews. Verify Gaze at 344 and Chestwrap at Myth 6/6, 334 against live tooltip data.
- Classify effect-only bonus lists from current SimulationCraft ItemBonus data during daily collection. Reject conflicting level modifiers, ambiguous inherited variants and cross-item/crafted-effect guesses; retain original source dates.
- Rename the displayed set to BiS. Explicitly state when no verified alternatives are available, without a redundant second empty-dungeon message.
- Replace unsupported conversion/range arrow glyphs with a colon/plain separator.
- Add source-effect, build mismatch, maximum-ilvl conflict, exact-item inheritance and empty-alternative regressions.

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
