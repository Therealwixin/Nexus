local ADDON, R = ...
R.NAME = "Nexus"
R.ASSET_PATH = "Interface\\AddOns\\"..(ADDON or "Nexus").."\\Media\\"
local function normalized(name)
    return type(name)=="string" and name:lower():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("^the%s+",""):gsub("[^%w]","") or ""
end
-- Rendering must never enumerate or mutate the Adventure Guide.
function R.BuildJournalIndex() return R.journalIndex end
function R.UpdateJournalLoot() end
function R.JournalRoute(item,requireEncounter)
 if not item then return end
 if item.journalInstanceID and (not requireEncounter or item.journalEncounterID) then
  return {instanceID=item.journalInstanceID,encounterID=item.journalEncounterID,isRaid=item.sourceType=="raid",instanceName=item.instanceName,bossName=item.dropSource}
 end
 local cached=R.journalIndex and R.journalIndex.byItem and R.journalIndex.byItem[item.journalItemID or item.id]
 if cached and (not requireEncounter or cached.encounterID) then return cached end
end
function R.ShortSource(item)
 if not item then return "" end
 if item.crafted then return R.L("CRAFT_SOURCE") end
 return item.instanceName or (R.SourceCatalog and R.SourceCatalog[item.id] and R.SourceCatalog[item.id].source) or item.shortSource or (item.sourceType=="raid" and "Raid") or (item.sourceType=="dungeon" and "Mythic+") or R.L("SOURCE_UNKNOWN")
end
function R.ItemLevel(item, actual)
    if not item then return nil end
    if not actual then
        local range=R.GearLevelRange and R.GearLevelRange(item)
        return range and range.max or nil
    end
    if actual and item.slotID and C_Item and C_Item.GetCurrentItemLevel and ItemLocation and ItemLocation.CreateFromEquipmentSlot then
        local ok,level=pcall(C_Item.GetCurrentItemLevel,ItemLocation:CreateFromEquipmentSlot(item.slotID))
        if ok and R.IsReadable(level) and type(level)=="number" and level>0 then return level end
    end
    local api = C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
    if item.link and api then
        local ok,level = pcall(api,item.link)
        if ok and R.IsReadable(level) and type(level)=="number" and level>0 then return level end
    end
end
function R.LootInfo(item)
    if not item then return nil end
    if item.crafted then return R.L("CRAFT") end
    local route=R.JournalRoute(item,true)
    if route and route.bossName then return route.bossName..(route.instanceName and " · "..route.instanceName or "") end
    return item.dropSource and item.dropSource ~= "" and item.dropSource or R.L("JOURNAL_LOOKUP")
end
function R.OpenLoot(item)
 if not item or item.crafted then return end
 if InCombatLockdown() then R.Print(R.L("AFTER_COMBAT"));return end
 if not EncounterJournal_OpenJournal and C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn,"Blizzard_EncounterJournal") end
 if not EncounterJournal_OpenJournal then R.Print(R.L("JOURNAL_UNAVAILABLE"));return end
 local route=R.JournalRoute(item,true)
 -- One native item lookup, never all expansions/instances/bosses/loot pools.
 if not route and C_EncounterJournal and C_EncounterJournal.GetLootInfo and EJ_GetEncounterInfo then
  local ok,info=pcall(C_EncounterJournal.GetLootInfo,item.journalItemID or item.id)
  if ok and info and (not info.itemID or info.itemID==(item.journalItemID or item.id)) and info.encounterID and info.encounterID>0 then
   local boss,_,_,_,_,instanceID=EJ_GetEncounterInfo(info.encounterID)
   if instanceID and instanceID>0 then route={instanceID=instanceID,encounterID=info.encounterID,bossName=boss,isRaid=item.sourceType=="raid"} end
  end
 end
 if not route and R.ResolveJournalRoute then
  local pending=R.ResolveJournalRoute(item,function(found)
   if found then R.ShowJournalRoute(item,found) else
    R.journalStatus={id=item.id,key=InCombatLockdown() and "AFTER_COMBAT" or "JOURNAL_NOT_FOUND"}
    if R.UI then R.UI:JournalStatusChanged(item.id) end
   end
  end)
  if pending then if R.UI then R.UI:JournalStatusChanged(item.id) end;return true end
 end
 if not route then
  R.journalStatus={id=item.id,key="JOURNAL_NOT_FOUND"}
  if R.UI then R.UI:JournalStatusChanged(item.id) end
  return false
 end
 return R.ShowJournalRoute(item,route)
end
function R.ShowJournalRoute(item,route)
 if InCombatLockdown() then return false end
 if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
 if C_EncounterJournal and C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
 if EJ_SetSearch then EJ_SetSearch("") end
 -- Nexus uses DIALOG strata. Hide it so it cannot cover the native journal.
 if R.UI and R.UI.frame then R.UI.frame:Hide() end
 local ok=pcall(EncounterJournal_OpenJournal,route.isRaid and 16 or 23,route.instanceID,route.encounterID,nil,nil,item.journalItemID or item.id)
 if not ok then R.Print(R.L("JOURNAL_UNAVAILABLE"));return false end
 R.journalIndex=R.journalIndex or {byItem={}};R.journalIndex.byItem[item.journalItemID or item.id]=route
 R.journalStatus=nil;return true
end
function R.UpgradeText(item, slotID)
    local rules = R.Data and R.Data.upgradeRules
    if not item or not rules then return R.L("NO_UPGRADE_DATA") end
    local current = R.scan and R.scan.equipped[slotID]
    if C_ItemUpgrade and C_ItemUpgrade.GetItemHyperlink and C_ItemUpgrade.GetItemUpgradeItemInfo and current then
        local link = C_ItemUpgrade.GetItemHyperlink()
        if link and R.ItemID(link) == item.id then
            local info = C_ItemUpgrade.GetItemUpgradeItemInfo()
            if info and info.upgradeLevelInfos then
                if info.maxItemLevel and item.targetIlvl and info.maxItemLevel<item.targetIlvl then return R.L("NEED_MYTH_COPY") end
                local sum = 0
                for _, step in ipairs(info.upgradeLevelInfos) do
                    if step.upgradeLevel > info.currUpgrade then
                        for _, cost in ipairs(step.currencyCostsToUpgrade or {}) do
                            if cost.currencyID == rules.crestID then sum = sum + cost.cost end
                        end
                    end
                end
                return R.L("EXACT_CRESTS",sum,rules.crestName)
            end
        end
    end
    if item.crafted then return R.L("CRAFT_CRESTS",rules.craftCrests,rules.crestName) end
    if item.targetIlvl and item.targetIlvl > rules.levels[#rules.levels] then return R.L("SPECIAL_REWARD") end
    local start = current and current.id == item.id and R.ItemLevel(current,true) or item.dropIlvl or rules.levels[1]
    if start and start < rules.levels[1] then return R.L("NEED_MYTH_COPY") end
    if current and current.id==item.id and C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local tooltip=C_TooltipInfo.GetHyperlink(current.link)
        for _,line in ipairs(tooltip and tooltip.lines or {}) do
            if R.IsReadable(line.leftText) and type(line.leftText)=="string" then
                for _,track in ipairs({"Hero","Champion","Veteran","Adventurer"}) do
                    if line.leftText:match(track.."%s*%(?%d+/%d+") then return R.L("NEED_MYTH_COPY") end
                end
            end
        end
    end
    local watermark
    if C_ItemUpgrade and C_ItemUpgrade.GetHighWatermarkForItem then watermark = C_ItemUpgrade.GetHighWatermarkForItem(item.link or item.id) end
    local steps = 0
    for _, level in ipairs(rules.levels) do
        if level > (start or 0) and (not R.IsReadable(watermark) or not watermark or level > watermark) then steps = steps+1 end
    end
    return R.L("BASE_CRESTS",steps*rules.costPerStep,rules.crestName)
end
