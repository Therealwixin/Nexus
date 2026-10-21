local R=TEST.R
local textureAPI=C_Texture
local atlasCalls=0
C_Texture={GetAtlasInfo=function(name)
 atlasCalls=atlasCalls+1
 assert(name:match("^talents%-background%-"),"Only native talent background atlases")
 return {width=1024,height=1024,leftTexCoord=.1,rightTexCoord=.9,topTexCoord=.2,bottomTexCoord=.8}
end}
R.UI.frame:Show();R.UI.gearView="targets"
for _,spec in ipairs(R.Data.catalog) do
 R.SetViewSpec(spec.id);R.UI:SetView("equipment")
 local expected="talents-background-"..spec.classSlug:gsub("-","").."-"..spec.slug:gsub("-","")
 assert(R.UI.gearBackground.atlas==expected and R.UI.gearBackground:IsShown(),"Background follows selected preview spec")
 local coords=R.UI.gearBackground.texCoord
 assert(coords[1]>=.1 and coords[2]<=.9 and coords[3]>=.2 and coords[4]<=.8,"Crop stays inside atlas region")
 assert(R.UI.gearBackground:GetAlpha()==.72,"Artwork remains visible beneath readable rows")
end
R.SetViewSpec(1480);R.UI:Refresh();assert(R.UI.gearBackground.atlas=="talents-background-demonhunter-devourer","Devourer has its own art")
R.UI.gearView="mine";R.UI:Refresh();assert(R.UI.gearBackground:IsShown(),"My gear shares selected-spec art")
ClassTalentUtil={GetVisualsForSpecID=function()return {background="talents-background-client-updated"}end}
R.UI:Refresh();assert(R.UI.gearBackground.atlas=="talents-background-client-updated","Prefer native mapping when already available")
ClassTalentUtil=nil
C_Texture.GetAtlasInfo=function()return nil end
R.UI:Refresh();assert(not R.UI.gearBackground:IsShown() and not R.UI.gearBackgroundDim:IsShown(),"Missing atlas safely keeps plain fallback")
C_Texture=textureAPI;R.SetViewSpec(nil);R.UI.gearView="targets";R.UI:Refresh()
print("Gear background PASS: 40 selected specs, Devourer, both views, atlas crop, native override and missing-texture fallback")
