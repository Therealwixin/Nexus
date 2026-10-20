local _,R=...
-- Midnight S2 targets, checked 2026-10-20. These describe the best obtainable
-- version, never the level or stats of a bare item ID or of the player's copy.
-- https://www.wowhead.com/guide/midnight/item-level-gear-upgrades-dawncrests
-- https://www.wowhead.com/guide/midnight/bonus-rolls-item-upgrades
-- https://www.method.gg/guides/how-to-unlock-ascendant-venomstones-in-wow-midnight-season-2-neck-weapon-trinket-upgrades
function R.GearLevelRange(item,slot)
 if not item or item.slotID then return end
 slot=slot or item.gearSlotID
 if not R.SLOT_BY_ID[slot] then return end
 local rules=R.Data and R.Data.upgradeRules
 local version=GetBuildInfo()
 if not rules or rules.patch~="12.1" or tostring(version):match("^(%d+%.%d+)")~="12.1" then return end
 local base=item.acquisitionItemID or item.id
 local catalog=R.SourceCatalog and R.SourceCatalog[base]
 local kind=item.acquisition or item.sourceType
 if not kind or kind=="unknown" then kind=catalog and catalog.kind end
 local origin=item.dropSource or item.shortSource or catalog and catalog.source or ""
 local crafted=item.crafted or kind=="crafted"
 if not crafted and kind~="raid" and kind~="dungeon" then return end
 local elevated=kind=="raid" and (origin:lower():find("coiled alt",1,true) or origin:lower():gsub("[^%w]",""):find("ulatek",1,true))
 if elevated then return {max=344,track="ELEVATED_ILVL"} end
 local range={min=318,max=crafted and 331 or 334,track=crafted and "CRAFT_ILVL_RANGE" or "MYTH_ILVL_RANGE"}
 if slot==2 or slot==13 or slot==14 or slot==16 or slot==17 then range.ascended=crafted and 338 or 340 end
 return range
end
function R.GearLevelText(item,slot)
 local range=R.GearLevelRange(item,slot)
 if not range then return R.L("TARGET_ILVL_UNKNOWN") end
 return R.L("MAX_ILVL",range.ascended or range.max)
end
function R.GearLevelLines(item,slot)
 local range=R.GearLevelRange(item,slot)
 if not range then return {R.L("TARGET_ILVL_UNKNOWN")} end
 local lines={R.L(range.track,range.min or range.max,range.max)}
 if range.ascended then
  lines[#lines+1]=R.L("ASCENDED_ILVL",range.ascended)
  lines[#lines+1]=R.L("ASCENDED_UNLOCK")
 end
 return lines
end
