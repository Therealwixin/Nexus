local _,R=...
local evidence
local function sourceEvidence(id)
 if not evidence then
  evidence={}
  for _,row in pairs(R.GuideData and R.GuideData.items or {}) do
   local base=row.acquisitionItemID or row.id;local kind=row.acquisition
   if kind=="raid" or kind=="dungeon" or kind=="crafted" then
    local old=evidence[base]
    if not old then evidence[base]={kind=kind,source=row.dropSource or ""}
    elseif old.kind~=kind then old.ambiguous=true
    elseif old.source=="" or (row.dropSource or ""):lower():find("coiled alt",1,true) or (row.dropSource or ""):lower():gsub("[^%w]",""):find("ulatek",1,true) then old.source=row.dropSource or old.source end
   end
  end
 end
 local found=evidence[id];return found and not found.ambiguous and found or nil
end
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
 if not kind or kind=="unknown" then
  local found=sourceEvidence(base)
  if found then kind=found.kind;if origin=="" then origin=found.source end end
  -- A generic current-season tier recommendation can be previewed on the
  -- ordinary Myth track; a 344 Catalyst preview still needs its original ID.
  if not kind or kind=="unknown" then
   local label=origin:lower()
   if label:find("tier set",1,true) or label=="catalyst" then kind="raid" end
   -- Blizzard's 12.1.5 notes explicitly identify Labyrinth Myth rewards.
   if label:find("labyrinth of kindo",1,true) then kind="delve" end
  end
 end
 local crafted=item.crafted or kind=="crafted"
 if not crafted and kind~="raid" and kind~="dungeon" and kind~="delve" then return end
 local elevated=kind=="raid" and (origin:lower():find("coiled alt",1,true) or origin:lower():gsub("[^%w]",""):find("ulatek",1,true))
 if elevated then return {max=344,kind=kind,track="ELEVATED_ILVL"} end
 local range={min=318,max=crafted and 331 or 334,kind=crafted and "crafted" or kind,track=crafted and "CRAFT_ILVL_RANGE" or "MYTH_ILVL_RANGE"}
 if slot==2 or slot==13 or slot==14 or slot==16 or slot==17 then range.ascended=crafted and 338 or 340 end
 return range
end
function R.GearLevelText(item,slot)
 local range=R.GearLevelRange(item,slot)
 if not range then return R.L("TARGET_ILVL_UNKNOWN") end
 return R.L("MAX_ILVL",range.max)
end
function R.GearLevelLines(item,slot)
 local range=R.GearLevelRange(item,slot)
 if not range then return {R.L("TARGET_ILVL_UNKNOWN")} end
 local lines={R.L(range.track,range.min or range.max,range.max)}
 if range.ascended then
  lines[#lines+1]=R.L("ASCENDED_ILVL",range.ascended)
 end
 return lines
end

-- The bonus list changes the native item, including its stats, quality,
-- required level and upgrade track. Changing a text line cannot do that.
-- Verified against SimulationCraft's 12.1.5.70448 ItemBonus/scaling tables
-- and live Wowhead tooltips (344 raid / 334 Myth 6/6 / 331 crafted).
local statBonuses={}
for _,id in ipairs({6647,6648,6649,6650,6673,6674,6675,8790,8791,8792,8793,8794,8795,8862,8948,8949,8950,8951,8952,8953,8954,8955,8956,8957,11136,11137,11138,11139,11313}) do statBonuses[id]=true end
local function appendStats(bonuses,item)
 for _,id in ipairs(item.previewBonusIDs or {}) do if statBonuses[id] then bonuses[#bonuses+1]=id end end
end
function R.GearPreviewLink(item,slot)
 if not item or item.slotID then return end
 local range=R.GearLevelRange(item,slot)
 if not range then return end
 local id=item.acquisitionItemID or item.id
 local bonuses
 if range.kind=="crafted" then
  bonuses={13836,12497};appendStats(bonuses,item)
  -- Wowhead's main row often omits the crafted stat pair. Use only an
  -- explicitly published pair for the same source item, spec and slot.
  if #bonuses==2 then
   local guide=R.GetGuideDataset()
   for _,key in ipairs(guide and guide.alternatives and guide.alternatives[slot or item.gearSlotID] or {}) do
    local alternative=R.GuideData.items[key]
    if alternative and alternative.id==id then appendStats(bonuses,alternative);if #bonuses>2 then break end end
   end
  end
 else bonuses={range.max==344 and 13848 or 12854};if range.kind=="raid" then bonuses[#bonuses+1]=13335 end end
 -- Source effects are classified during collection from current ItemBonus data.
 -- Match the exact original item; never graft the tier result's proc onto it.
 local present={}
 for _,bonus in ipairs(bonuses) do present[bonus]=true end
 for _,bonus in ipairs(item.previewEffectBonusIDs or {}) do
  if not present[bonus] then bonuses[#bonuses+1]=bonus;present[bonus]=true end
 end
 local context=range.kind=="crafted" and 13 or range.kind=="dungeon" and 35 or 16
 -- Fields after item ID: enchant, four gems, suffix, unique ID, link level,
 -- spec, upgrade type, context, bonus count/list, modifier count/list.
 local fields={"item",id,0,0,0,0,0,0,0,90,R.ViewSpecID() or 0,0,context,#bonuses}
 for _,bonus in ipairs(bonuses) do fields[#fields+1]=bonus end
 fields[#fields+1]=1;fields[#fields+1]=9;fields[#fields+1]=90
 return table.concat(fields,":")..":::::",range
end
function R.EquippedUpgradeMaximum(item)
 if not item or not item.link or not C_Item or not C_Item.GetItemUpgradeInfo then return end
 local ok,info=pcall(C_Item.GetItemUpgradeInfo,item.link)
 if ok and info and R.IsReadable(info.currentLevel) and R.IsReadable(info.maxLevel) and R.IsReadable(info.maxItemLevel)
  and type(info.currentLevel)=="number" and type(info.maxLevel)=="number" and type(info.maxItemLevel)=="number"
  and info.currentLevel<info.maxLevel then return info.maxItemLevel,info.maxLevel end
end
