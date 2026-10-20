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
