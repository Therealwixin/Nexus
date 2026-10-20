# Nexus: repository and update setup

Repository selected by the owner: https://github.com/Therealwixin/Nexus

CurseForge project: **Nexus: Gear & Preparation**, ID **1754795**.
Author dashboard: https://authors.curseforge.com/#/projects/1754795/files
The project is created with All Rights Reserved licensing and its GitHub source link.
The upload token, project ID and tagged publishing are configured. The first beta uploaded successfully to CurseForge and GitHub on 2026-10-19. The project and earlier betas are approved; a new file can still be under review. Daily data refresh is enabled; see AKTUALIZACIE_SK.md.

## Prepared behavior

- Every push/pull request runs Lua 5.1 simulation, snapshot validation and packaging.
- Tagged releases run the same checks and build an installable ZIP.
- Data refresh runs daily at 04:17 UTC and checks whether 23 hours have elapsed since the last successful collection. Manual runs force collection.
- The daily collector downloads aggregate Murlok gear, Wowhead/Icy Veins guides, verified item-effect bonuses, Murlok role rankings and U.GG Mythic raid representation. It makes no individual player-profile requests.
- Weekly WCL collection has its own workflow. A daily 04:47 UTC due check starts it only when the weekly snapshot is due or incomplete. Failures retry automatically, resuming compatible anonymous checkpoints for up to 48 hours. Only complete 40-spec collections are saved; the next daily addon build ships them. WCL API waits never block daily guide updates.
- All 40 specs, both gear modes and all six meta groups must pass validation before any candidate is staged.
- Source publication dates are retained. Collection time is recorded separately.
- A failed collection/test exits before committing/publishing. The last published package remains available.
- Defaults build artifacts only. Nothing is uploaded to CurseForge until its project ID, upload token and publishing switch are configured.

## Repository settings

Actions variables:

- `AUTO_DATA_REFRESH` is no longer required; the daily schedule is enabled in the workflow.
- `CURSEFORGE_PROJECT_ID`: numeric ID on the CurseForge project.
- `CURSEFORGE_PUBLISH_ENABLED=true`: enable upload after tests. Leave unset until the beta is reviewed.

Actions secret:

- `CF_API_TOKEN`: the author's upload token. Enter it directly in GitHub's secret form. Never put it in source code, a workflow, a commit, or chat.

The workflow uses the repository-provided `GITHUB_TOKEN`; a personal GitHub token is not required.

## First trial

1. Run **Validate Nexus** and download the tested artifact.
2. Test it in WoW, including rendering, scrolling, combat and dungeon warnings.
3. Run **Refresh Nexus data** manually with publishing disabled; confirm the complete artifact and data revision.
4. Create the CurseForge project and configure its ID and token.
5. Enable beta publishing and verify one end-to-end beta upload.
6. Daily refresh is already enabled. Monitor its first successful runs.

CurseForge requires a Release file before normal app syncing; beta files use the user's beta preference. Do not mark a preview stable merely to bypass that distinction.

References: [BigWigs packager](https://github.com/BigWigsMods/packager), [supported token names](https://github.com/BigWigsMods/packager/blob/master/release.sh), [CurseForge submission](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project).

## Public Warcraft Logs trial

Create your own Warcraft Logs API application and enter its Client ID and Client Secret as GitHub repository secrets `WCL_CLIENT_ID` and `WCL_CLIENT_SECRET`. Never paste them in chat. Run **Verify Warcraft Logs** with encounter ID 0 to verify OAuth and the point budget. Optional encounter samples are anonymous gear frequencies, kept separate from addon snapshots; they do not establish where items drop or a simulated best-in-slot set. Archon aggregate-build integration remains unverified.
