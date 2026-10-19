local ADDON, R = ...
R.NAME = "Nexus"
R.ASSET_PATH = "Interface\\AddOns\\"..(ADDON or "Nexus").."\\Media\\"
local function normalized(name)
    return type(name)=="string" and name:lower():gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("^the%s+",""):gsub("[^%w]","") or ""
end
-- Enumerate native encounter names, not NPC IDs (journal creature IDs differ).
-- Selecting an instance once initializes EJ_GetEncounterInfoByIndex on fresh login.
function R.BuildJournalIndex()
    if R.journalIndex or InCombatLockdown() then return R.journalIndex end
    if not (EJ_GetInstanceByIndex and EJ_SelectInstance and EJ_GetEncounterInfoByIndex) then return nil end
    if C_EncounterJournal and C_EncounterJournal.InitalizeSelectedTier then C_EncounterJournal.InitalizeSelectedTier() end
    local index={byName={},byItem={},instances={},sourceNames={},crafted={},encounters={}}
    local interested={}
    for _,modes in pairs(R.Data and R.Data.specs or {}) do
        for _,dataset in pairs(modes) do
            for _,items in pairs(dataset.slots or {}) do
                for _,item in ipairs(items) do
                    interested[item.id]=true
                    if item.crafted then index.crafted[item.id]=true end
                    if item.dropSource and item.dropSource~="" then index.sourceNames[item.id]=item.dropSource end
                end
            end
        end
    end
    index.interested=interested
    local current=EJ_GetCurrentTier and EJ_GetCurrentTier() or 1
    local count=EJ_GetNumTiers and EJ_GetNumTiers() or 1
    if current<1 then current=math.max(1,count) end
    local oldInstance=(EJ_GetCurrentInstance and EJ_GetCurrentInstance()) or (EncounterJournal and EncounterJournal.instanceID)
    local oldEncounter=EncounterJournal and EncounterJournal.encounterID
    local oldDifficulty=EJ_GetDifficulty and EJ_GetDifficulty()
    local oldClass,oldSpec;if EJ_GetLootFilter then oldClass,oldSpec=EJ_GetLootFilter() end
    local oldSlot=C_EncounterJournal and C_EncounterJournal.GetSlotFilter and C_EncounterJournal.GetSlotFilter()
    if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
    if C_EncounterJournal and C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
    local tiers={current};for tier=count,1,-1 do if tier~=current then tiers[#tiers+1]=tier end end
    for _,tier in ipairs(tiers) do
        if EJ_SelectTier then EJ_SelectTier(tier) end
        for _,raid in ipairs({true,false}) do
            for n=1,100 do
                local instanceID,name=EJ_GetInstanceByIndex(n,raid)
                if not instanceID then break end
                EJ_SelectInstance(instanceID)
                index.instances[instanceID]={name=name,isRaid=raid,tier=tier}
                index.encounters[instanceID]={}
                if EJ_SetDifficulty then
                    for _,difficulty in ipairs(raid and {16,14,15,17,1} or {23,2,1}) do
                        if not EJ_IsValidInstanceDifficulty or EJ_IsValidInstanceDifficulty(difficulty) then EJ_SetDifficulty(difficulty);break end
                    end
                end
                for boss=1,40 do
                    local bossName,_,encounterID=EJ_GetEncounterInfoByIndex(boss,instanceID)
                    if not encounterID then break end
                    local route={instanceID=instanceID,encounterID=encounterID,isRaid=raid,instanceName=name,bossName=bossName,tier=tier}
                    index.encounters[instanceID][encounterID]=route
                    local key=normalized(bossName)
                    if not index.byName[key] then index.byName[key]=route end
                    -- Instance loot can return encounterID=0. Query each boss's
                    -- pool explicitly so a raid-wide row cannot mask its source.
                    if EJ_SelectEncounter and EJ_GetNumLoot and C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
                        EJ_SelectEncounter(encounterID)
                        for loot=1,EJ_GetNumLoot() do
                            -- The optional second argument selects a secondary
                            -- source for a shared loot row, NOT a boss index.
                            local info=C_EncounterJournal.GetLootInfoByIndex(loot)
                            if info and info.itemID and interested[info.itemID] then
                                local nativeEncounter=info.encounterID
                                if not nativeEncounter or nativeEncounter<=0 or nativeEncounter==encounterID then
                                    local previous=index.byItem[info.itemID]
                                    if not previous or not previous.encounterID or previous.encounterID<=0 then index.byItem[info.itemID]=route end
                                end
                            end
                        end
                    end
                end
                EJ_SelectInstance(instanceID)
                if EJ_GetNumLoot and C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex then
                    if EJ_SetDifficulty then
                        for _,difficulty in ipairs(raid and {16,14,15,17,1} or {23,2,1}) do
                            if not EJ_IsValidInstanceDifficulty or EJ_IsValidInstanceDifficulty(difficulty) then EJ_SetDifficulty(difficulty);break end
                        end
                    end
                    for loot=1,EJ_GetNumLoot() do
                        local info=C_EncounterJournal.GetLootInfoByIndex(loot)
                        if info and info.itemID and interested[info.itemID] and not index.byItem[info.itemID] then
                            index.byItem[info.itemID]=(index.encounters[instanceID] or {})[info.encounterID] or {instanceID=instanceID,encounterID=info.encounterID,isRaid=raid,instanceName=name,tier=tier}
                        end
                    end
                end
            end
        end
    end
    if EJ_SelectTier then EJ_SelectTier(current) end
    if oldInstance and oldInstance>0 then EJ_SelectInstance(oldInstance) end
    if oldInstance and oldEncounter and EJ_SelectEncounter then EJ_SelectEncounter(oldEncounter) end
    if oldDifficulty and EJ_SetDifficulty then EJ_SetDifficulty(oldDifficulty) end
    if oldClass and EJ_SetLootFilter then EJ_SetLootFilter(oldClass,oldSpec or 0) end
    if oldSlot and C_EncounterJournal and C_EncounterJournal.SetSlotFilter then C_EncounterJournal.SetSlotFilter(oldSlot) end
    if next(index.instances) then R.journalIndex=index end
    return R.journalIndex
end
function R.JournalRoute(item,requireEncounter)
    if not item then return nil end
    local index=R.journalIndex
    local itemRoute=index and index.byItem and index.byItem[item.journalItemID or item.id]
    if itemRoute and (not requireEncounter or (itemRoute.encounterID and itemRoute.encounterID>0)) then return itemRoute end
    if item.journalInstanceID and item.journalEncounterID then
        local meta=index and index.instances[item.journalInstanceID]
        return {instanceID=item.journalInstanceID,encounterID=item.journalEncounterID,isRaid=meta and meta.isRaid,instanceName=meta and meta.name}
    end
    if C_EncounterJournal and C_EncounterJournal.GetLootInfo and EJ_GetEncounterInfo then
        local ok,info=pcall(C_EncounterJournal.GetLootInfo,item.journalItemID or item.id)
        if ok and info and (not info.itemID or info.itemID==(item.journalItemID or item.id)) and info.encounterID and info.encounterID>0 then
            local boss,_,_,_,_,instanceID=EJ_GetEncounterInfo(info.encounterID)
            if instanceID and instanceID>0 then
                local meta=index and index.instances[instanceID]
                local instanceName=meta and meta.name or (EJ_GetInstanceInfo and EJ_GetInstanceInfo(instanceID))
                return {instanceID=instanceID,encounterID=info.encounterID,bossName=boss,instanceName=instanceName,isRaid=meta and meta.isRaid}
            end
        end
    end
    local named=index and index.byName[normalized(item.dropSource or (index.sourceNames and index.sourceNames[item.id]))]
    return named or (not requireEncounter and itemRoute or nil)
end
function R.UpdateJournalLoot()
    if InCombatLockdown() then return end
    local index=R.journalIndex
    local instanceID=(EJ_GetCurrentInstance and EJ_GetCurrentInstance()) or (EncounterJournal and EncounterJournal.instanceID)
    if not index or not instanceID or not EJ_GetNumLoot or not (C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex) then return end
    for n=1,EJ_GetNumLoot() do
        local info=C_EncounterJournal.GetLootInfoByIndex(n)
        local route=info and (index.encounters[instanceID] or {})[info.encounterID]
        if route and index.interested[info.itemID] then index.byItem[info.itemID]=route end
    end
end
function R.ShortSource(item)
    if not item then return "" end
    if item.crafted or (R.journalIndex and R.journalIndex.crafted and R.journalIndex.crafted[item.id]) then return R.L("CRAFT_SOURCE") end
    local route=R.JournalRoute(item)
    if route then
        local raid=route.isRaid
        if raid==nil and EJ_SelectInstance and EJ_InstanceIsRaid and not InCombatLockdown() then
            local previous=(EJ_GetCurrentInstance and EJ_GetCurrentInstance()) or (EncounterJournal and EncounterJournal.instanceID)
            EJ_SelectInstance(route.instanceID);raid=EJ_InstanceIsRaid()
            if previous and previous>0 then EJ_SelectInstance(previous) end
        end
        if raid then return "Raid" end
        if route.instanceName then
            local short,words="",0
            for word in route.instanceName:gmatch("[%w']+") do
                if not ({the=true,of=true,["in"]=true,to=true,at=true})[word:lower()] then short=short..word:sub(1,1):upper();words=words+1 end
            end
            return (words>1 and short or route.instanceName).." Dungeon"
        end
    end
    return item.shortSource or (item.sourceType=="raid" and "Raid") or R.L("SOURCE_UNKNOWN")
end
function R.ItemLevel(item, actual)
    if not item then return nil end
    if not actual and item.targetIlvl then return item.targetIlvl end
    if actual and item.ilvl then return item.ilvl end
    local api = C_Item and C_Item.GetDetailedItemLevelInfo or GetDetailedItemLevelInfo
    if item.link and api then
        local level = api(item.link)
        if R.IsReadable(level) then return level end
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
    if InCombatLockdown() then R.Print(R.L("AFTER_COMBAT")); return end
    R.journalRequestSerial=(R.journalRequestSerial or 0)+1
    local serial=R.journalRequestSerial
    local function status(key)
        R.journalStatus={id=item.id,key=key}
        if R.UI and R.UI.JournalStatusChanged then R.UI:JournalStatusChanged(item.id) end
    end
    if not EncounterJournal_OpenJournal and C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn,"Blizzard_EncounterJournal") end
    if not EncounterJournal_OpenJournal then R.Print(R.L("JOURNAL_UNAVAILABLE")); return end
    if C_EncounterJournal and C_EncounterJournal.InitalizeSelectedTier then C_EncounterJournal.InitalizeSelectedTier() end
    local function open(route,difficulty)
        if not route or not route.instanceID or not route.encounterID or route.encounterID<=0 then return false end
        if route.tier and EJ_SelectTier then EJ_SelectTier(route.tier) end
        EJ_SelectInstance(route.instanceID)
        if not difficulty then difficulty=(route.isRaid or (EJ_InstanceIsRaid and EJ_InstanceIsRaid())) and 16 or 23 end
        if EJ_IsValidInstanceDifficulty and not EJ_IsValidInstanceDifficulty(difficulty) then
            for _,candidate in ipairs({23,16,2,1,15,14,17}) do
                if EJ_IsValidInstanceDifficulty(candidate) then difficulty=candidate;break end
            end
        end
        -- A stale class/slot filter can hide the token or alternative being opened.
        if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
        if C_EncounterJournal and C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
        if EJ_SetSearch then EJ_SetSearch("") end
        local encounter=route.encounterID
        if not encounter or encounter<=0 then encounter=nil end
        EncounterJournal_OpenJournal(difficulty,route.instanceID,encounter,nil,nil,item.journalItemID or item.id)
        -- Synchronize the native selected encounter AND visible Loot tab. Do
        -- not equate opening an instance with opening the boss's loot pool.
        if EJ_SelectEncounter then EJ_SelectEncounter(encounter) end
        if EncounterJournal_DisplayEncounter and EncounterJournal and EncounterJournal.encounterID~=encounter then EncounterJournal_DisplayEncounter(encounter) end
        local tab=EncounterJournal and EncounterJournal.encounter and EncounterJournal.encounter.info and EncounterJournal.encounter.info.lootTab
        if tab and tab.Click then tab:Click() end
        if EncounterJournal_LootUpdate then EncounterJournal_LootUpdate() end
        status(nil);return true
    end
    R.BuildJournalIndex()
    if open(R.JournalRoute(item,true)) then return true end
    status("JOURNAL_LOADING")
    local partial=R.JournalRoute(item)
    if partial and partial.instanceID then EncounterJournal_OpenJournal(nil,partial.instanceID,nil,nil,nil,item.journalItemID or item.id)
    else EncounterJournal_OpenJournal() end
    if not EJ_SetSearch or not EJ_GetNumSearchResults or not EJ_GetSearchResult then status("JOURNAL_NOT_FOUND");return end
    local queries={R.ItemName(item)}
    if item.dropSource and item.dropSource~="" then queries[#queries+1]=item.dropSource end
    local queryIndex,tries=1,0
    EJ_SetSearch(queries[queryIndex])
    local function find()
        if R.journalRequestSerial~=serial then return end
        if InCombatLockdown() then status("AFTER_COMBAT");return end
        R.UpdateJournalLoot()
        if open(R.JournalRoute(item,true)) then return end
        for index=1,EJ_GetNumSearchResults() do
            local id,kind,difficulty,instanceID,encounterID,itemLink=EJ_GetSearchResult(index)
            local exactItem=kind==0 and (id==(item.journalItemID or item.id) or R.ItemID(itemLink)==(item.journalItemID or item.id))
            local exactBoss=queryIndex>1 and kind==1 and EJ_GetEncounterInfo and normalized(EJ_GetEncounterInfo(id))==normalized(item.dropSource)
            if (exactItem or exactBoss) and instanceID then
                if open({instanceID=instanceID,encounterID=encounterID and encounterID>0 and encounterID or (exactBoss and id or nil)},difficulty) then return end
            end
        end
        tries=tries+1
        local finished=EJ_IsSearchFinished and EJ_IsSearchFinished()
        if (finished and tries>=4) or tries>=80 then
            queryIndex=queryIndex+1
            if queries[queryIndex] then tries=0;EJ_SetSearch(queries[queryIndex])
            else status("JOURNAL_NOT_FOUND");return end
        end
        C_Timer.After(.25,find)
    end
    C_Timer.After(.1,find)
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
