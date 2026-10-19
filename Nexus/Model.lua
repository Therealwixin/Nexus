local ADDON, R = ...

R.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "0.6.0-preview.1"
R.FONT = "Fonts\\FRIZQT__.TTF"
R.DEFAULT_WIDTH, R.DEFAULT_HEIGHT = 1200, 816
R.SLOTS = {
    { id = 1, key = "HEAD", icon = "Head" },
    { id = 2, key = "NECK", icon = "Neck" },
    { id = 3, key = "SHOULDERS", icon = "Shoulder" },
    { id = 15, key = "BACK", icon = "Chest" },
    { id = 5, key = "CHEST", icon = "Chest" },
    { id = 9, key = "WRIST", icon = "Wrists" },
    { id = 10, key = "HANDS", icon = "Hands" },
    { id = 6, key = "WAIST", icon = "Waist" },
    { id = 7, key = "LEGS", icon = "Legs" },
    { id = 8, key = "FEET", icon = "Feet" },
    { id = 11, key = "RING1", icon = "Finger" },
    { id = 12, key = "RING2", icon = "Finger" },
    { id = 13, key = "TRINKET1", icon = "Trinket" },
    { id = 14, key = "TRINKET2", icon = "Trinket" },
    { id = 16, key = "MAINHAND", icon = "MainHand" },
    { id = 17, key = "OFFHAND", icon = "SecondaryHand" },
}
R.SLOT_BY_ID = {}
for _, slot in ipairs(R.SLOTS) do R.SLOT_BY_ID[slot.id] = slot end
R.PAIRS = { [11] = {11, 12}, [12] = {11, 12}, [13] = {13, 14}, [14] = {13, 14} }

function R.IsReadable(value)
    return not issecretvalue or not issecretvalue(value)
end

function R.ItemID(value)
    if not R.IsReadable(value) then return nil end
    if type(value) == "number" then return value > 0 and math.floor(value) or nil end
    if type(value) ~= "string" then return nil end
    local id = tonumber(value:match("item:(%d+)") or value:match("^%s*(%d+)%s*$"))
    return id and id > 0 and id or nil
end

function R.ParseLink(link)
    if type(link) ~= "string" or not R.IsReadable(link) then return nil end
    local payload = link:match("item:([^|]+)")
    if not payload then return nil end
    local fields = {}
    for field in (payload .. ":"):gmatch("(.-):") do fields[#fields + 1] = field end
    local id = tonumber(fields[1])
    if not id or id <= 0 then return nil end
    local out = { id = id, enchantID = tonumber(fields[2]) or 0, gems = {} }
    for index = 3, 6 do out.gems[#out.gems + 1] = tonumber(fields[index]) or 0 end
    return out
end

function R.SpecID()
    local index = GetSpecialization and GetSpecialization()
    if not index then return nil end
    return GetSpecializationInfo(index)
end

function R.GetMode()
    return R.db and R.db.mode or "mythicplus"
end

function R.ViewSpecID()
    local selected=R.character and R.character.viewSpecID
    if selected and R.Data and R.Data.specs and R.Data.specs[selected] then return selected end
    return R.SpecID()
end

function R.GetDataset(mode, specID)
    local spec = specID or R.ViewSpecID()
    if not spec or not R.Data or not R.Data.specs then return nil end
    local data = R.Data.specs[spec] and R.Data.specs[spec][mode or R.GetMode()]
    if not data then return nil end
    if GetBuildInfo and data.patch then
        local version = GetBuildInfo()
        local clientPatch = type(version) == "string" and version:match("^(%d+%.%d+)")
        if clientPatch and clientPatch ~= data.patch then return nil, "PATCH_MISMATCH" end
    end
    return data
end

function R.TargetStore()
    local spec = R.SpecID() or 0
    R.character.targets = R.character.targets or {}
    R.character.targets[spec] = type(R.character.targets[spec]) == "table" and R.character.targets[spec] or {}
    local bySpec = R.character.targets[spec]
    bySpec[R.GetMode()] = type(bySpec[R.GetMode()]) == "table" and bySpec[R.GetMode()] or {}
    return bySpec[R.GetMode()]
end

function R.GetCandidates(slotID, specID, mode)
    local data = R.GetDataset(mode,specID)
    return data and data.slots and data.slots[slotID] or {}
end

function R.GetTarget(slotID, specID, mode)
    if not R.character then return nil end
    local candidates = R.GetCandidates(slotID,specID,mode)
    return candidates[1]
end

function R.ItemName(item)
    if not item then return R.L("EMPTY") end
    local id = R.ItemID(item.id or item.link)
    local api = C_Item and C_Item.GetItemInfo or GetItemInfo
    local name = id and api and api(item.link or id)
    if name and R.IsReadable(name) then return name end
    return item.name or (id and "Item #" .. id) or R.L("LOADING")
end

function R.ItemIcon(item, fallback)
    local id = item and R.ItemID(item.id or item.link)
    local api = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if id and api then
        local _, _, _, _, icon = api(item.link or id)
        if icon and R.IsReadable(icon) then return icon end
    end
    return item and item.icon or fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function R.RequestItem(id)
    id = R.ItemID(id)
    if not id then return end
    R.requested = R.requested or {}
    if R.requested[id] then return end
    R.requested[id] = true
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
end

function R.Ownership(id, slotID)
    id = R.ItemID(id)
    if not id then return "NO_DATA", 0 end
    local equipped = R.scan and R.scan.equipped or {}
    for _, candidateSlot in ipairs(R.PAIRS[slotID] or {slotID}) do
        if equipped[candidateSlot] and equipped[candidateSlot].id == id then return "EQUIPPED", 1 end
    end
    local count = R.scan and R.scan.bags and R.scan.bags[id] or 0
    if count > 0 then return "IN_BAGS", count end
    -- An item equipped in a different slot is still owned.
    for _, item in pairs(equipped) do if item.id == id then return "OWNED", 1 end end
    return "MISSING", 0
end

function R.ItemByID(id, specID, mode)
    local data = R.GetDataset(mode,specID)
    if not data then return nil end
    for _, list in pairs(data.slots or {}) do
        for _, item in ipairs(list) do if item.id == id then return item end end
    end
    for _, list in ipairs({data.consumables or {}, data.gems or {}}) do
        for _, item in ipairs(list) do if item.id == id then return item end end
    end
end

function R.IsTarget(id, specID, mode)
    for _, slot in ipairs(R.SLOTS) do
        local target = R.GetTarget(slot.id,specID,mode)
        if target and target.id == id then return true, slot.id, target.personal end
    end
    return false
end

function R.SetTarget(slotID, itemID)
    local id = R.ItemID(itemID)
    if not R.SLOT_BY_ID[slotID] or not id then return false, "INVALID_ITEM" end
    local instant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if instant then
        local foundID, _, _, equipLoc = instant(id)
        if not foundID then R.RequestItem(id); return false, "UNKNOWN_ITEM" end
        if not equipLoc or equipLoc == "" then return false, "WRONG_SLOT" end
        if equipLoc and equipLoc ~= "" then
            local allowed = {
                INVTYPE_HEAD = {1}, INVTYPE_NECK = {2}, INVTYPE_SHOULDER = {3},
                INVTYPE_CLOAK = {15}, INVTYPE_CHEST = {5}, INVTYPE_ROBE = {5},
                INVTYPE_WRIST = {9}, INVTYPE_HAND = {10}, INVTYPE_WAIST = {6},
                INVTYPE_LEGS = {7}, INVTYPE_FEET = {8}, INVTYPE_FINGER = {11,12},
                INVTYPE_TRINKET = {13,14}, INVTYPE_2HWEAPON = {16}, INVTYPE_WEAPON = {16,17},
                INVTYPE_WEAPONMAINHAND = {16}, INVTYPE_WEAPONOFFHAND = {17},
                INVTYPE_HOLDABLE = {17}, INVTYPE_SHIELD = {17}, INVTYPE_RANGED = {16},
                INVTYPE_RANGEDRIGHT = {16},
            }
            local matches = false
            for _, candidate in ipairs(allowed[equipLoc] or {}) do if candidate == slotID then matches = true end end
            if not matches then return false, "WRONG_SLOT" end
        end
    end
    R.TargetStore()[slotID] = id
    R.RequestItem(id)
    return true
end

function R.ClearTarget(slotID)
    R.TargetStore()[slotID] = nil
end

function R.EmptySockets(link)
    local parsed = R.ParseLink(link)
    if not parsed then return nil end
    if C_Item and C_Item.GetItemNumSockets and C_Item.GetItemGemID then
        local total = C_Item.GetItemNumSockets(link)
        if not R.IsReadable(total) or type(total) ~= "number" then return nil end
        local empty = 0
        for index = 1, total do
            local gemID = C_Item.GetItemGemID(link, index)
            if not R.IsReadable(gemID) then return nil end
            if not gemID or gemID == 0 then empty = empty + 1 end
        end
        return empty
    end
    local api = C_Item and C_Item.GetItemStats or GetItemStats
    local stats = api and api(link)
    if type(stats) ~= "table" then return nil end
    local total, filled = 0, 0
    for stat, value in pairs(stats) do
        if type(stat) == "string" and stat:match("^EMPTY_SOCKET_") and R.IsReadable(value) then
            total = total + (tonumber(value) or 0)
        end
    end
    for _, gem in ipairs(parsed.gems) do if gem > 0 then filled = filled + 1 end end
    return math.max(0, total - filled)
end

function R.GetPreparation()
    local out = {}
    local data = R.GetDataset()
    local enchantSlots = data and data.enchants or { [5]={}, [8]={}, [11]={}, [12]={}, [16]={} }
    for _, slot in ipairs(R.SLOTS) do
        local item = R.scan and R.scan.equipped[slot.id]
        local rule = enchantSlots[slot.id]
        if item and item.link then
            local parsed = R.ParseLink(item.link)
            if rule and parsed then
                local key = parsed.enchantID == 0 and "ENCHANT_MISSING" or "ENCHANT_PRESENT"
                if rule.allowedEnchantIDs and #rule.allowedEnchantIDs > 0 and parsed.enchantID ~= 0 then
                    local matches = false
                    for _, id in ipairs(rule.allowedEnchantIDs) do if id == parsed.enchantID then matches = true end end
                    key = matches and "ENCHANT_MATCH" or "ENCHANT_DIFFERENT"
                end
                out[#out + 1] = { slotID = slot.id, item = item, key = key,
                    needed = key == "ENCHANT_MISSING" or key == "ENCHANT_DIFFERENT", recommendation = rule.name, enchant = rule }
            end
            local empty = R.EmptySockets(item.link)
            if empty and empty > 0 then
                out[#out + 1] = { slotID = slot.id, item = item, key = "EMPTY_SOCKETS", count = empty, needed = true }
            end
        end
    end
    for _, item in ipairs(data and data.consumables or {}) do
        local count = R.scan and R.scan.bags[item.id] or 0
        out[#out + 1] = { item = item, key = count > 0 and "IN_BAGS" or "MISSING", count = count,
            needed = count == 0, consumable = true }
    end
    return out
end
