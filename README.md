# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.0 beta 3 restores a character-panel equipment layout, compact scrolling preparation cards and multi-item socket comparisons. Native fonts, icons and tooltips are retained. Player-profile browsing and talent databases have been removed.

- **Equipment:** recommended Raid/Mythic+ gear and ownership on the current character.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings and Mythic raid representation, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. Raid representation is not a direct class-strength ranking. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

Source-restricted Raid/M+ alternatives are experimental and incomplete. The source catalogue currently covers 128 items: 95 raid and 33 dungeon items. Depending on specialization, static dungeon alternatives cover 3–10 equipment slots. Unknown sources and ambiguous catalysts are excluded, rather than relabelled as dungeon drops. The existing dungeon warning also contributes verified loot sources from the visited dungeon. Overall uses the authored all-source guide; source-filtered alternatives are observed candidates, not a simulated optimal set.

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

## Warcraft Logs and Archon

The manual **Verify Warcraft Logs** workflow uses `WCL_CLIENT_ID` and `WCL_CLIENT_SECRET` repository secrets. Its default is a public OAuth/quota probe. An optional encounter query reduces one ranking page to anonymous item frequencies, caches the result for six hours and stops at 80% of the hourly point budget. Samples below 20 usable gear sets are rejected. No credentials, player names, private logs or event streams are bundled in Nexus. WCL candidates do not replace validated addon data automatically. Gear popularity is not drop-source evidence or a personalized BiS simulation.

Archon build data is not integrated. Its published API documentation covers log data; a supported aggregate-build feed and permission to redistribute it still need verification.
