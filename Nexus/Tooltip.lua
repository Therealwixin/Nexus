local _, R = ...
local processed = setmetatable({}, {__mode="k"})

function R.DecorateTooltip(tooltip, data)
    if tooltip.nexusItemPreview then return end
    if not R.db or not R.character or not data or not R.IsReadable(data.id) then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local id = R.ItemID(data.id)
    if not id then return end
    local specID=R.tooltipSpecID or R.SpecID();if not specID then return end
    local mode=R.tooltipMode or R.GetMode()
    local previous = processed[tooltip]
    local lines = tooltip:NumLines()
    if previous and previous.data == data and previous.specID==specID and previous.mode==mode and lines >= previous.lines then return end
    local isTarget, _, personal = R.IsTarget(id,specID,mode)
    local item = R.ItemByID(id,specID,mode)
    if R.tooltipItem and R.tooltipItem.id==id then item=R.tooltipItem end
    if not isTarget and not item then return end
    tooltip:AddLine(" ")
    if item and item.source == "Wowhead" then tooltip:AddLine(R.NAME .. " · " .. R.L("GUIDE_RECOMMENDATION"), .8,.5,1)
    elseif item and item.source == "Archon.gg" then tooltip:AddLine(R.NAME .. " · " .. R.L("POPULAR_ITEM"), .8,.5,1)
    else tooltip:AddLine(R.NAME .. " · " .. R.L("TOP_ITEM"), .8,.5,1) end
    if item and item.bisGuide then tooltip:AddLine(R.L("BIS_LIST"),1,.82,0) end
    if item and item.count then
        local dataset = R.GetDataset(mode,specID)
        local countText = item.group == "gems" and tostring(item.count)
            or item.count .. "/" .. (item.sampleSize or (dataset and dataset.sampleSize) or "?")
        tooltip:AddLine((item.source or "Murlok.io") .. ": " .. countText, 1,1,1)
    end
    local dataset = R.GetDataset(mode,specID)
    local updatedAt = (item and item.updatedAt) or (dataset and dataset.updatedAt)
    if updatedAt then tooltip:AddLine(R.L("SNAPSHOT") .. ": " .. updatedAt:sub(1,10), .65,.65,.65) end
    tooltip:AddLine(R.L("POPULARITY_NOTE"), .65,.65,.65, true)
    processed[tooltip] = {data=data,lines=tooltip:NumLines(),specID=specID,mode=mode}
end

function R.InstallTooltips()
    if R.tooltipInstalled then return end
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, R.DecorateTooltip)
        R.tooltipInstalled = true
    end
end
