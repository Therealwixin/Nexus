local R=TEST.R
local originalTextureAPI=C_Texture
local nativeWidth,nativeHeight=1614,776
C_Texture={GetAtlasInfo=function(name)
 assert(name:match("^talents%-background%-"),"Current native talent atlas only")
 return {width=nativeWidth,height=nativeHeight,leftTexCoord=.1,rightTexCoord=.9,topTexCoord=.2,bottomTexCoord=.8}
end}
R.UI.frame:Show();R.UI.gearView="targets"
for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
 R.UI.frame:SetSize(unpack(size))
 for _,spec in ipairs(R.Data.catalog) do
  R.SetViewSpec(spec.id);R.UI:SetView("equipment")
  local ui=R.UI;local art=ui.gearBackground
  local expected="talents-background-"..spec.classSlug:gsub("-","").."-"..spec.slug:gsub("-","")
  assert(art:IsShown() and art.atlas==expected,"All 40 specs use their own current talent art")
  assert(art:GetWidth()>=ui.gearChild:GetWidth()-.01 and art:GetHeight()>=ui.gearChild:GetHeight()-.01,"Native image covers real viewport")
  assert(art:GetAlpha()==1 and not art.mask,"Native image stays opaque beneath the separate readability overlay")
  assert(ui.gearBackgroundDim:IsShown() and ui.gearBackgroundDim:GetWidth()==ui.gearChild:GetWidth() and ui.gearBackgroundDim:GetHeight()==ui.gearChild:GetHeight(),"Readability overlay follows the viewport on spec changes and resizing")
  assert(not ui.gearCrest and not ui.gearIdentity and not ui.gearClass,"No enlarged icons or central labels")
  assert(art.atlasResetTexCoords==true and art.textureSliceCleared,"Native atlas UV reset and flat artwork rendering")
  assert(not art.texCoord,"Never reapply sprite-sheet coordinates to a selected atlas")
  local maxRight=0
  for _,row in ipairs(ui.rows) do maxRight=math.max(maxRight,row:GetRight()) end
  assert(math.abs(maxRight-ui.gearChild:GetRight())<.1,"Right equipment column restored to original outer edge")
 end
end
for _,native in ipairs({{1614,776},{2048,1024},{1024,2048},{320,180}}) do
 nativeWidth,nativeHeight=unpack(native)
 for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
  R.UI.frame:SetSize(unpack(size));R.UI:Refresh()
  local art=R.UI.gearBackground;local viewport=R.UI.gearChild
  assert(math.abs(art:GetWidth()/art:GetHeight()-nativeWidth/nativeHeight)<1e-8,"Native artwork aspect survives resize")
  assert(art:GetWidth()>=viewport:GetWidth()-.01 and art:GetHeight()>=viewport:GetHeight()-.01,"No empty strips at viewport edges")
  assert(math.abs(art:GetWidth()-viewport:GetWidth())<.01 or math.abs(art:GetHeight()-viewport:GetHeight())<.01,"Minimum cover scale, no extra zoom")
  assert(math.abs(art:GetRight()-viewport:GetRight())<.01,"Right edge retained by native geometry")
  local _,artY=art:GetCenter();local _,viewY=viewport:GetCenter()
  assert(math.abs(artY-viewY)<.01,"Vertical center follows actual pane")
  assert(not art.texCoord,"No manual UV transform at any window/atlas size")
  assert(R.UI.gearScroll.scrollChild==viewport,"Existing game ScrollFrame clips scaled background at viewport bounds")
 end
end
R.UI.gearView="mine";R.UI:Refresh();assert(R.UI.gearBackground:IsShown(),"Both equipment views share talent art")
ClassTalentUtil={GetVisualsForSpecID=function()return {background="talents-background-client-override"}end}
R.UI:Refresh();assert(R.UI.gearBackground.atlas=="talents-background-client-override","Prefer loaded native client mapping")
ClassTalentUtil=nil
C_Texture.GetAtlasInfo=function()return nil end
R.UI:Refresh();assert(not R.UI.gearBackground:IsShown(),"Missing atlas stays plain without an unrelated/icon fallback")
C_Texture=originalTextureAPI;R.SetViewSpec(nil);R.UI.gearView="targets";R.UI.frame:SetSize(1280,900);R.UI:Refresh()
print("Talent backgrounds PASS: 40 specs, real viewport coverage, native atlas UV reset, no manual UV overrides, original columns, preserved aspect/right edge, both views and safe missing atlas")

local group={updatedAt="2026-10-16T10:00:00Z",updatedEpoch=1,retrievedAt="2026-10-21T17:00:00Z",retrievedEpoch=100000}
local dataset={roles={dps=group}}
assert(R.MetaDate(dataset,"dps")=="2026-10-16" and R.MetaDate(dataset,"dps","retrievedAt")=="2026-10-21","Source publication and successful download stay distinct")
local serverTime=GetServerTime;GetServerTime=function()return 100001 end
assert(R.MetaAge(group)==0,"Freshness uses successful collection, not old publication")
GetServerTime=serverTime
print("Meta UI provenance PASS: collection/publication labels and freshness")
