local _, R = ...
R.recipes = {}

function R.ScanRecipes()
    if InCombatLockdown and InCombatLockdown() then return end
    local api = C_TradeSkillUI
    if not api or not api.GetAllRecipeIDs or not api.GetRecipeOutputItemData then return end
    local recipeIDs = api.GetAllRecipeIDs()
    if type(recipeIDs) ~= "table" then return end
    for _, recipeID in ipairs(recipeIDs) do
        local output = api.GetRecipeOutputItemData(recipeID)
        if output and output.itemID then R.recipes[output.itemID] = recipeID end
    end
end

function R.GetCraftMaterials(itemID)
    local recipeID = R.recipes[itemID]
    if not recipeID or not C_TradeSkillUI or not C_TradeSkillUI.GetRecipeSchematic then return nil end
    local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
    if not schematic or not schematic.reagentSlotSchematics then return nil end
    local out = {}
    for _, slot in ipairs(schematic.reagentSlotSchematics) do
        if slot.required and slot.reagents then
            local choices = {}
            for _, reagent in ipairs(slot.reagents) do
                if reagent.itemID then
                    choices[#choices + 1] = { id = reagent.itemID }
                    R.RequestItem(reagent.itemID)
                end
            end
            if #choices > 0 then out[#out + 1] = { choices = choices, count = slot.quantityRequired or 1 } end
        end
    end
    return out, recipeID
end
