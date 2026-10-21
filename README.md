# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.6 uses a compact character-panel slot layout without a character model, scrolling Preparation cards and exact socket-row counts. Equipment uses the selected spec's native talent spec scene, centered at a smaller size with feathered edges and a dim overlay and eight slots per column; both weapons sit below Wrists on the left. It imports all 40 live Wowhead guides, source-qualified dungeon/raid alternatives. Item names use quality colors, equipped ilvl uses the native item location, and Catalyst variants keep source-item stats. Player-profile browsing and talent databases remain removed.

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
    python tools/package.py --output dist

The live Wowhead collector was exercised across all 40 specs on 2026-10-20; published source timestamps and live patch are preserved. Preparation, aggregate gear and meta inputs retain their own published timestamps. Collection writes a candidate; staging, tests and publishing are separate steps. An incompatible guide patch or missing complete authored set prevents replacing the last verified snapshot.

    python tools/refresh_gear.py
    python tools/data_release.py stage --keep-version

Daily data collection, validation and configured publishing are enabled. See [AKTUALIZACIE_SK.md](AKTUALIZACIE_SK.md) for the detailed Slovak installation/update guide and [SETUP.md](SETUP.md) for setup details. The prepared project description is in [CURSEFORGE.md](CURSEFORGE.md).

No API keys or game libraries are bundled in the addon. Existing owner license terms are retained in `Nexus/LICENSE.txt`.

## Active sources

Daily collection uses Wowhead, Icy Veins, Murlok and U.GG (raid Meta). Direct WCL collection, its snapshots/workflows, Archon status checks and Raider.IO affix checks have been removed. U.GG's methodology still credits its underlying log source; Nexus makes no direct WCL API requests. Daily publication and addon updates continue as before.
