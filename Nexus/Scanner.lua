local _, R = ...

function R.ScanEquipment()
    if InCombatLockdown and InCombatLockdown() then R.scanAfterCombat = true; return end
    local scan = { equipped = {}, bags = {} }
    for _, slot in ipairs(R.SLOTS) do
        local link = GetInventoryItemLink("player", slot.id)
        local id = GetInventoryItemID("player", slot.id)
        if R.IsReadable(link) and R.IsReadable(id) and id then
            scan.equipped[slot.id] = { id = id, link = link, slotID=slot.id, icon = GetInventoryItemTexture("player", slot.id) }
            R.RequestItem(id)
        end
    end
    if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
        local maxBag = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag or (NUM_BAG_SLOTS or 4) + 1
        for bag = 0, maxBag do
            local count = C_Container.GetContainerNumSlots(bag) or 0
            if R.IsReadable(count) then
                for index = 1, count do
                    local item = C_Container.GetContainerItemInfo(bag, index)
                    if item and R.IsReadable(item.itemID) and R.IsReadable(item.stackCount) and item.itemID then
                        scan.bags[item.itemID] = (scan.bags[item.itemID] or 0) + (item.stackCount or 1)
                    end
                end
            end
        end
    end
    R.scan = scan
    R.scanAfterCombat = nil
end
