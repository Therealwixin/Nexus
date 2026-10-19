local _,R=...
R.THEME_ORDER={"warcraft"}
R.THEMES={warcraft={name="Warcraft",bg={.07,.065,.055,1},card={.10,.095,.08,1},detail={.08,.075,.065,1},accent={.64,.53,.32,1},selected={.17,.145,.095,1}}}
local white="Interface\\Buttons\\WHITE8X8"
R.themePanels={};R.themeButtons={}
function R.Theme()return R.THEMES.warcraft end
function R.SkinPanel(frame,kind,selected)
 if not frame._nexusPanel then frame._nexusPanel={};R.themePanels[#R.themePanels+1]=frame end
 frame._nexusPanel.kind=kind or "card";frame._nexusPanel.selected=selected and true or false
 local theme=R.Theme();local marked=selected or kind=="dungeon"
 local bg=marked and theme.selected or frame._stripe and {.115,.11,.095,1} or theme[kind or "card"] or theme.card
 local border=kind~="row" and kind~="detail" and kind~="nav" and kind~="card"
 frame:SetBackdrop({bgFile=white,edgeFile=(marked or border) and white or nil,edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
 frame:SetBackdropColor(unpack(bg));frame:SetBackdropBorderColor(unpack(theme.accent))
end
function R.SkinButton(button)
 if button._nexusButton then return end
 button._nexusButton={textures={}}
 for _,region in ipairs({button:GetRegions()}) do
  if region:IsObjectType("Texture") then button._nexusButton.textures[#button._nexusButton.textures+1]={region=region,alpha=region:GetAlpha()} end
 end
 R.themeButtons[#R.themeButtons+1]=button
end
function R.StyleNavigation(button,active)
 R.SkinButton(button)
 for _,texture in ipairs(button._nexusButton.textures) do texture.region:SetAlpha(0) end
 button:SetEnabled(true)
 button:SetBackdrop(nil)
 if not button._nexusUnderline then
  button._nexusUnderline=button:CreateTexture(nil,"ARTWORK");button._nexusUnderline:SetHeight(2)
  button._nexusUnderline:SetPoint("BOTTOMLEFT",9,0);button._nexusUnderline:SetPoint("BOTTOMRIGHT",-9,0)
  button._nexusUnderline:SetColorTexture(.73,.59,.33,1)
 end
 button._nexusUnderline:SetShown(active)
 local f=button:GetFontString();f:SetFont(R.FONT,13,"");f:SetTextColor(active and .91 or .63,active and .79 or .63,active and .52 or .60)
end
function R.ApplyTheme()
 for _,frame in ipairs(R.themePanels) do local state=frame._nexusPanel;R.SkinPanel(frame,state.kind,state.selected) end
 local ui=R.UI
 if ui and ui.frame then
  for _,region in ipairs(ui.nativeChrome or {}) do region:Show() end
  ui.frame:SetBackdrop(nil)
 end
end
function R.SetTheme(key)
 if key~="warcraft" then return false end
 R.db.theme="warcraft";R.ApplyTheme();if R.UI then R.UI:Refresh() end;return true
end
