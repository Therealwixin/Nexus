local R=TEST.R
R.UI.frame:Show();R.UI.gearView="targets"
for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
 R.UI.frame:SetSize(unpack(size))
 for _,spec in ipairs(R.Data.catalog) do
  R.SetViewSpec(spec.id);R.UI:SetView("equipment")
  local ui=R.UI;local art=ui.gearBackground
  assert(ui.gearIdentity:GetText()==spec.name and ui.gearClass:GetText()==spec.className,"Composition follows selected specialization")
  assert(ui.gearCrest:IsShown() and ui.gearCrest:GetWidth()>=60,"Recognizable crest for every spec")
  if spec.classID==12 or spec.classID==13 then
   assert(not art:IsShown(),"New specs use own crest, never borrowed/abstract art")
  else
   assert(art:IsShown() and art.texture:find("Interface\\TalentFrame\\bg-",1,true),"Native character painting")
   assert(art:GetWidth()==art:GetHeight() and art:GetWidth()>=160,"Recognizable full square painting, no talent-atlas crop")
   assert(art:GetLeft()>=ui.gearChild:GetLeft()+ui.rows[1]:GetWidth() and art:GetRight()<=ui.gearChild:GetRight()-ui.rows[1]:GetWidth(),"Painting stays in its own center column, never underneath item labels")
   local coords=art.texCoord;assert(coords[1]==0 and coords[2]==1 and coords[3]==0 and coords[4]==1,"Full painting stays intact")
  end
  for _,row in ipairs(ui.rows) do
   assert(row:GetRight()<=ui.gearIdentity:GetLeft()+.1 or row:GetLeft()>=ui.gearIdentity:GetRight()-.1,"Labels stay outside central identity")
  end
 end
end
-- Removed/missing client artwork switches to the selected spec's crest.
local texture=R.UI.gearBackground.SetTexture
R.UI.gearBackground.SetTexture=function()return false end
R.SetViewSpec(70);R.UI:Refresh()
assert(not R.UI.gearBackground:IsShown() and R.UI.gearCrest:IsShown(),"Missing native painting has explicit crest fallback")
R.UI.gearBackground.SetTexture=texture
R.SetViewSpec(nil);R.UI.gearView="targets";R.UI:Refresh()
print("Equipment composition PASS: all 40 specs, responsive columns, full paintings, native crest fallback and missing client assets")

local group={updatedAt="2026-10-16T10:00:00Z",updatedEpoch=1,retrievedAt="2026-10-21T17:00:00Z",retrievedEpoch=100000}
local dataset={roles={dps=group}}
assert(R.MetaDate(dataset,"dps")=="2026-10-16" and R.MetaDate(dataset,"dps","retrievedAt")=="2026-10-21","Source publication and successful download stay distinct")
local serverTime=GetServerTime;GetServerTime=function()return 100001 end
assert(R.MetaAge(group)==0,"Freshness uses successful collection, not old publication")
GetServerTime=serverTime
print("Meta UI provenance PASS: collection/publication labels and freshness")
