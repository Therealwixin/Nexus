local _,R=...
-- Midnight S2 bonus 34 groups 617 (Hero) and 618 (Myth), verified against
-- SimulationCraft item_bonus.inc, build 12.1.5.70448, and native Wowhead
-- tooltips. These are explicit variant bonuses, never inferred from ilvl.
-- https://raw.githubusercontent.com/simulationcraft/simc/midnight/engine/dbc/generated/item_bonus.inc
R.UpgradeBonusTracks={patch="12.1",build="12.1.5.70448",bonuses={}}
for rank=1,6 do
 R.UpgradeBonusTracks.bonuses[12840+rank]={maximum=321,name="Hero",rank=rank}
 R.UpgradeBonusTracks.bonuses[12848+rank]={maximum=334,name="Myth",rank=rank}
end
-- Ascendant ranks retain their base track. Treat them as at least its
-- ordinary ceiling when comparing alternatives; they never imply a new track.
for bonus=12847,12848 do R.UpgradeBonusTracks.bonuses[bonus]={maximum=328,name="Hero",rank=bonus-12840} end
for bonus=12855,12856 do R.UpgradeBonusTracks.bonuses[bonus]={maximum=340,name="Myth",rank=bonus-12848} end

function R.UpgradeTrackFromBonuses(item)
 local catalog=R.UpgradeBonusTracks
 local rules=R.Data and R.Data.upgradeRules
 local version=GetBuildInfo()
 if not catalog or not rules or rules.patch~=catalog.patch or
  tostring(version):match("^(%d+%.%d+)")~=catalog.patch then return end
 local parsed=item and R.ParseLink(item.link)
 local found
 for _,bonus in ipairs(parsed and parsed.bonusIDs or {}) do
  local track=catalog.bonuses[bonus]
  if track then
   if found and (found.maximum~=track.maximum or found.name~=track.name or found.rank~=track.rank) then return end
   found=track
  end
 end
 if found then return {maximum=found.maximum,name=found.name,rank=found.rank,origin="bonus"} end
end
