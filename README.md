# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.1 uses a compact character-panel slot layout without a character model, scrolling Preparation cards and exact socket-row counts. It imports all 40 live Wowhead guides, source-qualified dungeon/raid alternatives and anonymous WCL usage evidence. Item names use quality colors, equipped ilvl uses the native item location, and Catalyst variants keep source-item stats. Player-profile browsing and talent databases remain removed.

- **Equipment:** recommended Raid/Mythic+ gear and ownership on the current character.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings and Mythic raid representation, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. Raid representation is not a direct class-strength ranking. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

Overall uses the authored Wowhead set. Raid/M+ filters use explicitly identified drops, including original Catalyst base items and verified same-spec alternatives. These lists remain incomplete; unknown acquisition sources and crafted items are excluded. An activity-oriented Mythic+ guide can recommend raid gear, so its title alone is not treated as dungeon-drop evidence. See [DATA-SOURCES.md](DATA-SOURCES.md) for all 40 specs, source links and actual slot/sample coverage. Dungeon warnings check the highest recommended missing option available in the visited dungeon for each slot.

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

The manual **Verify Warcraft Logs** workflow uses `WCL_CLIENT_ID` and `WCL_CLIENT_SECRET` repository secrets. Its default is a public OAuth/quota probe. The optional single-encounter query caches anonymous frequencies for six hours. **Collect guides** reads one ranking page for each spec in two verified current-season contexts: The Coiled Altar (Mythic raid) and Murder Row (M+). It stops at 80% of the hourly budget. Healers use HPS; others DPS. Samples below 20 usable gear sets are omitted. Beta 4 includes 40 M+ and 34 raid contexts; details show counts, encounter, metric and retrieval date. These are encounter-specific observations and never reorder the guide or establish acquisition source. No credentials, player names, private logs or event streams are bundled. **Refresh Nexus data** collects this evidence alongside guides, validates and tests before publishing; daily scheduled collection is enabled.

Raider.IO provides EU affix context through its public API. Archon build data is not integrated: the public gear page currently returns human verification. The daily collector reports that status honestly without bypassing the check or treating it as gear data. Publication and last-check dates are shown separately.
