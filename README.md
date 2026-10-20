# Nexus

A focused World of Warcraft Retail addon for gear goals, equipment ownership and character preparation.

## Current preview

Nexus 0.6.5 uses a compact character-panel slot layout without a character model, scrolling Preparation cards and exact socket-row counts. It imports all 40 live Wowhead guides, source-qualified dungeon/raid alternatives and anonymous WCL usage evidence. Item names use quality colors, equipped ilvl uses the native item location, and Catalyst variants keep source-item stats. Player-profile browsing and talent databases remain removed.

- **Equipment:** BiS gear, up to four verified alternatives per slot, and ownership on the current character.
- **Stats:** Murlok M+ references for all 40 specs, native active-character values, rating gaps and verified rating-derived DR details on hover.
- **Preparation:** enchantments, equipped sockets, gem suggestions and consumables.
- **Meta:** published M+ role rankings and Mythic raid representation, with source dates and methodology.
- Browse supported classes/specs without changing the character's specialization.
- EN/SK/CZ interface text, native item icons and `/nexus debug` diagnostics.

Recommendations are source snapshots, not a personalized simulation. Raid representation is not a direct class-strength ranking. The addon does not make network requests inside WoW.

## Install

Download an installable Nexus ZIP, close WoW and replace the `Nexus` addon folder. The result must be `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Preserve SavedVariables. Open `/nexus`.

Equipment now has only BiS, with up to four distinct verified alternatives per slot. A dungeon option is reserved whenever one is known. Wowhead, Icy Veins and same-spec observed alternatives are labelled by source. Lists are not padded when source data is incomplete. Catalyst alternatives retain the original source item. See [DATA-SOURCES.md](DATA-SOURCES.md) for actual coverage.

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
