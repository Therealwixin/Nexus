# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.0 preview 2 uses one restrained Warcraft interface: native fonts and tooltips, a single gear list, and an item detail pane. Player-profile browsing and talent databases have been removed.

- **Equipment:** recommended Raid/Mythic+ gear and ownership on the current character.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings and Mythic raid representation, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. Raid representation is not a direct class-strength ranking. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

The addon is still a preview. Real-client appearance and combat behavior require testing; the Lua simulator does not reproduce WoW's renderer or secure execution.

## Development

Python 3.12 and `lupa==2.8` are used outside the game:

    python tools/refresh_gear.py --validate-only
    python tools/test_lean.py
    python tools/test_maintenance.py
    python tools/package.py --output dist

The live collector has been exercised across all 40 specs, both gear modes and both meta modes on 2026-10-19. Source timestamps remain their published values. Collection writes a candidate; staging, tests and publishing are separate steps.

    python tools/refresh_gear.py
    python tools/data_release.py stage --keep-version

See [SETUP.md](SETUP.md) for GitHub Actions and CurseForge setup. Scheduled collection and publishing are disabled until the corresponding repository variables are enabled. The prepared project description is in [CURSEFORGE.md](CURSEFORGE.md).

No API keys or game libraries are bundled in the addon. Existing owner license terms are retained in `Nexus/LICENSE.txt`.
