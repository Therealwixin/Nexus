local R=TEST.R
local function base(item)return item.acquisitionItemID or item.id end
for spec in pairs(R.Data.specs) do
 for _,slot in ipairs(R.SLOTS) do
  local item=R.GetGearTarget(slot.id,spec)
  if item then
   local sources=R.GetGearEvidence(item,slot.id,spec)
   assert(sources[1] and sources[1].source=="Wowhead" and sources[1].kind=="guide","Overall attribution must name its actual author")
   for _,source in ipairs(sources) do
    assert(source.url and source.updatedAt and source.retrievedAt,"Every claim needs source and dates")
    assert(source.source~="Warcraft Logs" and source.source~="Archon","Log counts/blocked feeds must not imply authored consensus")
    if source.kind=="observation" then assert(source.count<=source.sampleSize and source.source=="Murlok.io","Profile denominator must stay explicit") end
   end
   for _,alt in ipairs(R.GetGearAlternatives(slot.id,spec)) do
    if alt.source=="Icy Veins" then
     local found=false
     for _,source in ipairs(R.GetGearEvidence(alt,slot.id,spec)) do if source.source=="Icy Veins" then found=true end end
     assert(found,"Icy Veins options require direct source-item evidence")
    end
   end
  end
 end
end
R.SetViewSpec(261);R.UI.gearView="targets";R.UI:SetView("equipment")
for _,entry in ipairs(R.UI.detailPool) do
 if entry.text and entry.text:IsShown() then assert(not entry.text:GetText():find("Warcraft Logs",1,true),"WCL sample must not be attached to an Overall item or alternative") end
end
print("Evidence regressions PASS: authored provenance, profile denominators, no implied WCL/Archon consensus, original-item identity")
