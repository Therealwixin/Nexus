# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.7 uses a compact character-panel slot layout without a character model, scrolling Preparation cards and exact socket-row counts. Equipment uses the selected specialization's current native talent background across the complete pane, including DH and Evoker. Native atlas rendering scales to the actual equipment viewport; the game ScrollFrame clips overflow. Both equipment columns use their original outer edges, with no reserved portrait strip. A uniform black overlay improves readability beneath item text/icons. Both equipment columns meet without a center gutter. There are no central spec icons or legacy portraits. Both weapons sit below Wrists on the left. It imports all 40 live Wowhead guides, source-qualified dungeon/raid alternatives. Item names use quality colors, equipped ilvl uses the native item location, and Catalyst variants keep source-item stats. Player-profile browsing and talent databases remain removed.

- **Equipment:** Mythic+ (Murlok top-profile usage), up to four verified alternatives per slot, and current-character ownership. Acquisition includes raid, dungeon and crafted items; raid mode is temporarily removed.
- **Stats:** Murlok M+ references for all 40 specs, native active-character values, rating gaps and verified rating-derived DR details on hover.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

Equipment follows observed current-season Murlok Mythic+ usage. Wowhead and Icy Veins supply verified alternatives and acquisition evidence across all sources, including raid drops. Up to four distinct alternatives are shown, reserving a dungeon option where known. Raid equipment mode and raid Meta are temporarily removed. See [DATA-SOURCES.md](DATA-SOURCES.md) for actual coverage.

The addon is still a preview. Real-client appearance and combat behavior require testing; the Lua simulator does not reproduce WoW's renderer or secure execution.

## Development

Python 3.12 and `lupa==2.8` are used outside the game:

    python tools/refresh_gear.py --validate-only
    python tools/test_lean.py
    python tools/test_maintenance.py
    python tools/test_guides.py
    python tools/package.py --output dist

The live Wowhead collector was exercised across all 40 specs on 2026-10-20; published source timestamps and live patch are preserved. Preparation, aggregate gear and meta inputs retain their own published timestamps. Collection writes a candidate; staging, tests and publishing are separate steps. An incompatible guide patch or missing complete authored set prevents replacing the last verified snapshot.

    python -m pip install playwright==1.56.0
    python -m playwright install chromium
    python tools/refresh_gear.py
    python tools/data_release.py stage --keep-version

Daily data collection, validation and configured publishing are enabled. See [AKTUALIZACIE_SK.md](AKTUALIZACIE_SK.md) for the detailed Slovak installation/update guide and [SETUP.md](SETUP.md) for setup details. The prepared project description is in [CURSEFORGE.md](CURSEFORGE.md).

No API keys or game libraries are bundled in the addon. Existing owner license terms are retained in `Nexus/LICENSE.txt`.

## Active sources

Daily collection uses Wowhead, Icy Veins and Murlok. U.GG raid Meta collection and data are removed. Direct WCL collection, Archon status checks and Raider.IO affix checks remain removed. Daily publication and addon updates continue.

Murlok Meta, gear, Stats, gems and enchants use rendered aggregate pages after hydration. One browser reads gear pages at most two at a time; all 40 specs are required. No player-profile pages are requested. Stale, future-dated and incomplete inputs are rejected. If a current edge response is older than our existing complete snapshot, the newer verified aggregate and its original dates are retained with an unsuccessful refresh flag and retry. Other sources can still update.

Daily data packages inherit the beta/stable channel. The external collector runs on GitHub, never in WoW. Source publication and successful collection dates remain separate. Detail panel refreshes preserve scroll and the selected alternative; explicit item/slot/spec changes start the new detail at the top.
