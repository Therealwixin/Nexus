local R=TEST.R
local textureAPI=C_Texture
local atlasCalls=0
local nativeWidth,nativeHeight=2048,1024
C_Texture={GetAtlasInfo=function(name)
 atlasCalls=atlasCalls+1
 assert(name:match("^talents%-background%-"),"Only native talent background atlases")
 return {width=nativeWidth,height=nativeHeight,leftTexCoord=.1,rightTexCoord=.9,topTexCoord=.2,bottomTexCoord=.8}
end}
R.UI.frame:Show();R.UI.gearView="targets"
for _,spec in ipairs(R.Data.catalog) do
 R.SetViewSpec(spec.id);R.UI:SetView("equipment")
 local expected="talents-background-"..spec.classSlug:gsub("-","").."-"..spec.slug:gsub("-","")
 assert(R.UI.gearBackground.atlas==expected and R.UI.gearBackground:IsShown(),"Background follows selected preview spec")
 local coords=R.UI.gearBackground.texCoord
 assert(coords[1]==.1 and coords[2]==.9 and coords[3]==.2 and coords[4]==.8,"Entire artwork stays visible without atlas cropping")
 assert(R.UI.gearBackground:GetAlpha()==.85,"Artwork remains visible beneath readable rows")
end
R.SetViewSpec(1480);R.UI:Refresh();assert(R.UI.gearBackground.atlas=="talents-background-demonhunter-devourer","Devourer has its own art")
R.UI.gearView="mine";R.UI:Refresh();assert(R.UI.gearBackground:IsShown(),"My gear shares selected-spec art")
for _,native in ipairs({{2048,1024},{1024,2048},{1024,1024},{320,180}}) do
 nativeWidth,nativeHeight=unpack(native)
 for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
  R.UI.frame:SetSize(unpack(size));R.UI:Refresh()
  local art,container=R.UI.gearBackground,R.UI.gearChild
  assert(math.abs(art:GetWidth()/art:GetHeight()-nativeWidth/nativeHeight)<.0001,"Artwork aspect stays intact")
  assert(art:GetWidth()<=container:GetWidth()*.68+.01 and art:GetHeight()<=container:GetHeight()*.68+.01,"Small centered motif leaves room around equipment")
  assert(art:GetWidth()<=nativeWidth and art:GetHeight()<=nativeHeight,"No native-size enlargement")
  local fitsWidth=math.abs(art:GetWidth()-container:GetWidth()*.68)<.01
  local fitsHeight=math.abs(art:GetHeight()-container:GetHeight()*.68)<.01
  assert(fitsWidth or fitsHeight or art:GetWidth()==nativeWidth,"Fit uses available space without arbitrary zoom")
 end
end
R.UI.frame:SetSize(1280,900)
assert(R.UI.gearBackground.mask==R.UI.gearBackgroundMask and R.UI.gearBackgroundMask.texture==R.ASSET_PATH.."equipment-art-mask.tga","Artwork has feathered edges without masking labels")

ClassTalentUtil={GetVisualsForSpecID=function()return {background="talents-background-client-updated"}end}
R.UI:Refresh();assert(R.UI.gearBackground.atlas=="talents-background-client-updated","Prefer native mapping when already available")
ClassTalentUtil=nil
C_Texture.GetAtlasInfo=function()return nil end
R.UI:Refresh();assert(not R.UI.gearBackground:IsShown() and not R.UI.gearBackgroundDim:IsShown(),"Missing atlas safely keeps plain fallback")
C_Texture=textureAPI;R.SetViewSpec(nil);R.UI.gearView="targets";R.UI:Refresh()
print("Gear background PASS: 40 selected specs, Devourer, both views, full-artwork fit, resize/aspect/native-size bounds, native override and missing-texture fallback")
