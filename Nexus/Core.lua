local ADDON, R = ...
local events = CreateFrame("Frame")
local statEvents={COMBAT_RATING_UPDATE=true,UNIT_STATS=true,UNIT_AURA=true,UNIT_SPELL_HASTE=true,MASTERY_UPDATE=true,SPEED_UPDATE=true,LIFESTEAL_UPDATE=true,AVOIDANCE_UPDATE=true,PLAYER_LEVEL_UP=true}

function R.Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. R.NAME .. "|r " .. tostring(message)) end
end

function R.QueueRefresh(equipmentChanged)
    if equipmentChanged~=false then R.equipmentDirty=true end
    if InCombatLockdown() or R.refreshPending or not (R.UI.frame and R.UI.frame:IsShown()) then return end
    R.refreshPending=true
    C_Timer.After(.2,function()
        R.refreshPending=false
        if not R.db or InCombatLockdown() or not (R.UI.frame and R.UI.frame:IsShown()) then return end
        R.RunBackground("refresh",function()
            if R.equipmentDirty or R.scanAfterCombat then R.ScanEquipment();R.equipmentDirty=false end
            R.UI:Refresh()
        end)
    end)
end

function R.Initialize()
    -- Legacy globals can be loaded from a copied SavedVariables file. Do not
    -- alias them: an enabled old alpha must never share mutable beta settings.
    local function copy(value)
        if type(value)~="table" then return value end
        local out={};for key,v in pairs(value) do out[key]=copy(v) end;return out
    end
    NexusDB = type(NexusDB)=="table" and NexusDB or copy(type(RelicDB)=="table" and RelicDB or {})
    NexusCharacterDB = type(NexusCharacterDB)=="table" and NexusCharacterDB or copy(type(RelicCharacterDB)=="table" and RelicCharacterDB or {})
    R.db, R.character = NexusDB, NexusCharacterDB
    if not R.Locales[R.db.language] then R.db.language = "EN" end
    R.db.mode = "mythicplus"
    R.character.targets = type(R.character.targets) == "table" and R.character.targets or {}
    R.character.shopping = type(R.character.shopping) == "table" and R.character.shopping or {}
    if R.character.viewSpecID and not R.SpecInfo(R.character.viewSpecID) then R.character.viewSpecID=nil end
    R.character.lastSpecByClass=type(R.character.lastSpecByClass)=="table" and R.character.lastSpecByClass or {}
    if not R.THEMES[R.db.theme] then R.db.theme="warcraft" end
    -- Enlarge the old default once; later user resizing remains persistent.
    if R.db.windowLayout~=2 then
        if (not R.db.width or R.db.width==1000) and (not R.db.height or R.db.height==680) then
            R.db.width,R.db.height=R.DEFAULT_WIDTH,R.DEFAULT_HEIGHT
        end
        R.db.windowLayout=2
    end
    R.db.schema = 4
    R.scan = {equipped={},bags={}}
    R.InstallTooltips()
end

function R.DebugText()
    local version, build, _, interface = GetBuildInfo()
    local dataset, why = R.GetDataset()
    local equipped, bags = 0,0
    for _ in pairs(R.scan and R.scan.equipped or {}) do equipped=equipped+1 end
    for _ in pairs(R.scan and R.scan.bags or {}) do bags=bags+1 end
    local errors={}
    for _,entry in ipairs(R.db.runtimeErrors or {}) do errors[#errors+1]=entry.context.." ("..entry.count..") "..entry.message end
    return R.NAME .. " " .. R.VERSION .. " | WoW " .. tostring(version) .. " (" .. tostring(build) .. ")"
        .. " | Interface " .. tostring(interface) .. " | Spec " .. tostring(R.SpecID())
        .. " | Viewed spec " .. tostring(R.ViewSpecID())
        .. " | Mode " .. R.GetMode() .. " | Language " .. R.db.language
        .. " | Dataset " .. (dataset and tostring(dataset.updatedAt) or tostring(why or "none"))
        .. " | Equipped " .. equipped .. " | Bag IDs " .. bags .. " | Font " .. R.FONT
        .. " | Data " .. R.DataStatus(dataset) .. " | Errors " .. table.concat(errors," / ")
end

SLASH_NEXUS1 = "/nexus"
SLASH_NEXUS2 = "/metaslave"
SLASH_NEXUS3 = "/relic"
SLASH_NEXUS4 = "/lootmark"
SlashCmdList.NEXUS = function(message)
    if not R.db then return end
    local command, argument = (message or ""):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "lang" then
        local language = argument:upper()
        if R.Locales[language] then R.db.language = language; R.UI:Refresh()
        else R.Print(R.L("HELP")) end
    elseif command == "theme" then R.SetTheme(argument:lower())
    elseif command == "scan" then R.ScanEquipment(); R.ScanRecipes(); R.UI:Refresh()
    elseif command == "sources" then R.UI:ShowSources()
    elseif command == "debug" then R.UI:ShowCopy(R.DebugText(), R.NAME.." diagnostics · Ctrl+C")
    elseif command == "resetui" then
        R.db.x,R.db.y,R.db.width,R.db.height,R.db.minimapAngle = 0,0,R.DEFAULT_WIDTH,R.DEFAULT_HEIGHT,225
        if R.UI.frame then
            R.UI.frame:ClearAllPoints(); R.UI.frame:SetPoint("CENTER",UIParent,"CENTER",0,0); R.UI.frame:SetSize(R.DEFAULT_WIDTH,R.DEFAULT_HEIGHT)
        end
        if R.UI.minimap then R.UI.minimap:ClearAllPoints(); R.UI.minimap:SetPoint("CENTER",Minimap,"CENTER",-55,-55) end
    elseif command == "help" then R.Print(R.L("HELP"))
    else R.UI:Toggle() end
end

events:SetScript("OnEvent", function(_, event, argument)
    if event == "ADDON_LOADED" and argument == ADDON then R.Initialize()
    elseif event == "PLAYER_LOGIN" then
        if not R.db then R.Initialize() end
        R.ScanEquipment(); R.UI:CreateMinimap()
        if C_MythicPlus and C_MythicPlus.RequestMapInfo then C_MythicPlus.RequestMapInfo() end
        if not R.db.welcomed then R.Print(R.L("FIRST_LOGIN")); R.db.welcomed = true end
    elseif not R.db then return
    elseif event=="PLAYER_REGEN_DISABLED" then
        if R.UI.frame and R.UI.frame:IsShown() and R.UI.view=="stats" then GameTooltip:Hide();R.UI:RenderStats() end
    elseif statEvents[event] then
        if (event:sub(1,5)~="UNIT_" or argument=="player") and R.UI.view=="stats" then R.QueueRefresh(false) end
    elseif event=="EJ_LOOT_DATA_RECIEVED" then
        if not InCombatLockdown() then R.RunBackground("journal",R.UpdateJournalLoot) end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if argument == "player" then if not R.character.viewSpecID then R.UI:ResetSpecViewState() end; R.QueueRefresh() end
    elseif event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_SHOW" then
        if not InCombatLockdown() and R.UI.frame and R.UI.frame:IsShown() then R.RunBackground("recipes",R.ScanRecipes) end; R.QueueRefresh(false)
    elseif event=="GET_ITEM_INFO_RECEIVED" then R.QueueRefresh(false)
    elseif event=="PLAYER_REGEN_ENABLED" then R.QueueRefresh(false)
    else R.QueueRefresh() end
    if R.db and ({PLAYER_ENTERING_WORLD=true,ZONE_CHANGED_NEW_AREA=true,CHALLENGE_MODE_MAPS_UPDATE=true,
        CHALLENGE_MODE_START=true,PLAYER_REGEN_ENABLED=true,EJ_LOOT_DATA_RECIEVED=true,
        PLAYER_SPECIALIZATION_CHANGED=true,GET_ITEM_INFO_RECEIVED=true})[event] then R.RunBackground("dungeon event",function()R.DungeonAlerts:OnEvent(event,argument)end) end
end)
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_EQUIPMENT_CHANGED","BAG_UPDATE_DELAYED",
    "PLAYER_SPECIALIZATION_CHANGED","GET_ITEM_INFO_RECEIVED","PLAYER_REGEN_ENABLED","PLAYER_ENTERING_WORLD",
    "TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_SHOW","EJ_LOOT_DATA_RECIEVED","ZONE_CHANGED_NEW_AREA",
    "CHALLENGE_MODE_MAPS_UPDATE","CHALLENGE_MODE_START","COMBAT_RATING_UPDATE","UNIT_STATS","UNIT_AURA","UNIT_SPELL_HASTE","MASTERY_UPDATE","SPEED_UPDATE","LIFESTEAL_UPDATE","AVOIDANCE_UPDATE","PLAYER_LEVEL_UP","PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
R.events = events
