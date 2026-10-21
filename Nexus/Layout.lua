local _,R=...
local UI=R.UI
local GOLD={.86,.73,.45}
local WHITE={.88,.87,.82}
local MUTED={.57,.58,.56}
local RED={1,.1,.1}
local GREEN={.1,1,.1}
local function label(parent,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 f:SetFont(R.FONT,size,"");f:SetShadowOffset(1,-1);f:SetTextColor(unpack(color or WHITE));f:SetJustifyH("LEFT");f:SetMaxLines(1)
 return f
end
local function scrollFrame(parent)
 local frame=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate");local child=CreateFrame("Frame",nil,frame);child:SetSize(300,1);frame:SetScrollChild(child);return frame,child
end
local function place(frame,point,parent,relative,x,y)
 frame:ClearAllPoints();frame:SetPoint(point,parent,relative,x,y)
end
function UI:Layout()
 local f=self.frame;if not f or not self.detailPane then return end
 if not self.sectionTitle then
  self.sectionTitle=label(f,16,GOLD);self.sectionTitle:SetHeight(20)
  self.gearHeaders={slot=label(self.gearChild,10,MUTED),item=label(self.gearChild,10,MUTED),state=label(self.gearChild,10,MUTED)}
  self.sourceButtons={}
 end
 if ButtonFrameTemplate_HidePortrait then ButtonFrameTemplate_HidePortrait(f) elseif f.PortraitContainer then f.PortraitContainer:Hide() end
 place(f.Inset,"TOPLEFT",f,"TOPLEFT",8,-151);f.Inset:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-8,47)
 place(self.buttons.EQUIPMENT,"TOPLEFT",f,"TOPLEFT",22,-39);self.buttons.EQUIPMENT:SetSize(130,28)
 place(self.buttons.STATS,"LEFT",self.buttons.EQUIPMENT,"RIGHT",4,0);self.buttons.STATS:SetSize(84,28)
 place(self.buttons.PREPARATION,"LEFT",self.buttons.STATS,"RIGHT",4,0);self.buttons.PREPARATION:SetSize(140,28)
 place(self.buttons.META,"LEFT",self.buttons.PREPARATION,"RIGHT",4,0);self.buttons.META:SetSize(90,28)
 place(self.buttons.SOURCES,"TOPRIGHT",f,"TOPRIGHT",-22,-39);self.buttons.SOURCES:SetSize(180,28)
 place(self.classPicker,"TOPLEFT",f,"TOPLEFT",22,-83);self.classPicker:SetSize(140,25)
 place(self.specPicker,"LEFT",self.classPicker,"RIGHT",6,0);self.specPicker:SetSize(170,25)
 place(self.mySpec,"LEFT",self.specPicker,"RIGHT",6,0);self.mySpec:SetSize(90,25)
 place(self.buttons.MYTHICPLUS,"TOPRIGHT",f,"TOPRIGHT",self.view=="equipment" and -176 or -174,-83);self.buttons.MYTHICPLUS:SetSize(self.view=="equipment" and 148 or 110,25)
 place(self.buttons.RAID,"LEFT",self.buttons.MYTHICPLUS,"RIGHT",6,0);self.buttons.RAID:SetSize(self.view=="equipment" and 148 or 140,25)
 place(self.sectionTitle,"TOPLEFT",f,"TOPLEFT",22,-122);self.sectionTitle:SetWidth(150)
 place(self.buttons.MY_GEAR,"TOPLEFT",f,"TOPLEFT",181,-119);self.buttons.MY_GEAR:SetSize(100,24)
 place(self.buttons.TARGETS,"LEFT",self.buttons.MY_GEAR,"RIGHT",5,0);self.buttons.TARGETS:SetSize(130,24)
 place(self.needs,"LEFT",self.buttons.TARGETS,"RIGHT",10,0);self.needsLabel:SetWidth(170)
 place(self.gearPane,"TOPLEFT",f,"TOPLEFT",18,-158);self.gearPane:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-344,53)
 place(self.detailPane,"TOPLEFT",f,"TOPRIGHT",-328,-158);self.detailPane:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-18,53)
 place(self.buttons.REFRESH,"BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,15);self.buttons.REFRESH:SetSize(140,24)
 place(self.footer,"BOTTOMLEFT",f,"BOTTOMLEFT",22,18);self.footer:SetWidth(f:GetWidth()-200);self.footer:SetHeight(14)
 self.characterName:Hide();self.themeButton:Hide()
 local equipment=self.view=="equipment"
 for _,b in pairs(self.sourceButtons) do b:Hide() end
 self.buttons.MYTHICPLUS:SetShown(self.view=="meta" or self.view=="equipment");self.buttons.RAID:SetShown(self.view=="meta" or self.view=="equipment")
 for index,b in ipairs(self.languageButtons) do place(b,"TOPLEFT",f,"TOPLEFT",181+(index-1)*38,-119) end
end
-- Use the same background atlas as Blizzard's current talent window for every
-- spec, including DH and Evoker. These compositions deliberately put their
-- character on the right: height-cover and right alignment retain that artwork.
function UI:UpdateGearBackground()
 if not self.gearBackground then
  self.gearBackground=self.gearChild:CreateTexture(nil,"BACKGROUND",nil,-8)
  self.gearBackground:SetAlpha(1)
  self.gearBackgroundDim=self.gearChild:CreateTexture(nil,"BACKGROUND",nil,-7)
  self.gearBackgroundDim:SetAllPoints(self.gearChild)
  self.gearBackgroundDim:SetColorTexture(0,0,0,.55)
 end
 local specID=R.ViewSpecID();local atlas
 if ClassTalentUtil and ClassTalentUtil.GetVisualsForSpecID then
  local visuals=ClassTalentUtil.GetVisualsForSpecID(specID);atlas=visuals and visuals.background
 end
 if not atlas then
  for _,spec in ipairs(R.Data and R.Data.catalog or {}) do if spec.id==specID then
   atlas="talents-background-"..spec.classSlug:gsub("-","").."-"..spec.slug:gsub("-","");break
  end end
 end
 local info=atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
 local width,height=self.gearChild:GetWidth(),self.gearChild:GetHeight()
 if not info or not info.width or not info.height or info.width<=0 or info.height<=0 or width<=0 or height<=0 then
  self.gearBackground:Hide();self.gearBackgroundDim:Hide();self.gearBackgroundAtlas=nil;return
 end
 -- Let the client apply the atlas rectangle. Sheet coordinates must not be
 -- reapplied to an already selected atlas. Explicitly reset UVs on spec changes.
 if self.gearBackgroundAtlas~=atlas then
  self.gearBackground:SetAtlas(atlas,false,nil,true)
  if self.gearBackground.ClearTextureSlice then self.gearBackground:ClearTextureSlice() end
  self.gearBackgroundAtlas=atlas
 end
 -- Scale the native image, not its UV rectangle. The existing gearScroll
 -- viewport clips the oversized texture at the actual equipment-pane edges.
 local scale=math.max(width/info.width,height/info.height)
 self.gearBackground:ClearAllPoints()
 self.gearBackground:SetPoint("RIGHT",self.gearChild,"RIGHT",0,0)
 self.gearBackground:SetSize(info.width*scale,info.height*scale)
 self.gearBackground:Show();self.gearBackgroundDim:Show()
end
-- Eight slots per side; both weapons follow wrists on the left.

function UI:RenderRows()
 self.gearScroll:ClearAllPoints();self.gearScroll:SetPoint("TOPLEFT",self.gearPane,"TOPLEFT",0,0);self.gearScroll:SetPoint("BOTTOMRIGHT",self.gearPane,"BOTTOMRIGHT",-2,0)
 if self.gearScroll.ScrollBar then self.gearScroll.ScrollBar:Hide() end
 local width,height=self.gearScroll:GetWidth(),self.gearScroll:GetHeight()
 self.gearChild:SetSize(width,height);self:UpdateGearBackground();self.gearRange=0;self:ScrollGear(0)
 for _,header in pairs(self.gearHeaders) do header:Hide() end
 local side=math.floor(width/2);local stride=(height-12)/8
 local left={[1]=0,[2]=1,[3]=2,[15]=3,[5]=4,[9]=5,[16]=6,[17]=7}
 local right={[10]=0,[6]=1,[7]=2,[8]=3,[11]=4,[12]=5,[13]=6,[14]=7}
 if self.paperDoll then self.paperDoll:Hide() end
 for index,slot in ipairs(R.SLOTS) do
  local row=self.rows[index];local item=self:GetShownItem(slot.id);local onRight=right[slot.id]~=nil
  local top=(left[slot.id] or right[slot.id] or 0)*stride+4
  local x=onRight and side or 0
  local rowWidth=onRight and width-side or side
  place(row,"TOPLEFT",self.gearChild,"TOPLEFT",x,-top);row:SetSize(rowWidth,stride-2);row.gridTop=top
  local state=self:BindItem(row,item,slot.id,self.gearView=="mine",true)
  local icon=math.floor(math.min(36,(stride-4)/1.55));place(row.icon,onRight and "RIGHT" or "LEFT",row,onRight and "RIGHT" or "LEFT",onRight and -16 or 16,0);row.icon:SetSize(icon,icon)
  for _,f in ipairs({row.text,row.note,row.ownership}) do f:ClearAllPoints();f:SetWidth(rowWidth-icon-32);f:SetJustifyH(onRight and "RIGHT" or "LEFT") end
  local anchor=onRight and "TOPRIGHT" or "TOPLEFT";local offset=onRight and -icon-24 or icon+24
  local contentTop=math.max(2,(stride-64)/2)
  row.text:SetPoint(anchor,row,anchor,offset,-contentTop);row.text:SetHeight(11);row.text:SetFont(R.FONT,10,"");row.text:SetTextColor(unpack(MUTED));row.text:SetText(R.L(slot.key))
  row.note:SetPoint(anchor,row,anchor,offset,-contentTop-13);row.note:SetHeight(stride>=70 and 30 or 26);row.note:SetFont(R.FONT,12,"OUTLINE");row.note:SetMaxLines(2);row.note:SetTextColor(R.ItemColor(item));row.note:SetText(item and R.ItemName(item) or R.L("NO_SOURCE_OPTION"))
  if item and self.gearView=="mine" then local level=R.ItemLevel(item,true);if level then row.text:SetText(R.L(slot.key).." · "..level) end end
  if item and self.gearView~="mine" then state=R.GearOwnership(item,slot.id) end
  row.ownership:SetPoint(anchor,row,anchor,offset,-contentTop-(stride>=70 and 47 or 41));row.ownership:SetHeight(11);row.ownership:SetFont(R.FONT,10,"OUTLINE");row.ownership:SetText(item and R.L(state) or "");row.ownership:SetTextColor(unpack(state=="MISSING" and RED or state:find("TIER_STATS",1,true) and GOLD or GREEN))
  row.red:Hide();row.check:Hide();row.icon:SetVertexColor(1,1,1)
  row.border:SetColorTexture(R.ItemColor(item))
  if not row.slotBevel then
   row.slotBevel=row:CreateTexture(nil,"OVERLAY");row.slotBevel:SetTexture("Interface\\Buttons\\UI-Quickslot2");row.slotBevel:SetPoint("CENTER",row.icon,"CENTER",0,0)
  end
  row.slotBevel:SetSize(icon*1.55,icon*1.55)
  row.selected:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");row.selected:SetVertexColor(1,.82,.35);row.selected:SetAlpha(.24);row.selected:SetShown(self.selectedSlot==slot.id)
  local here=item and R.DungeonAlerts:IsHighlighted(item.id)
  R.SkinPanel(row,"equipment");row.selected:SetShown(self.selectedSlot==slot.id or here)
  row:SetShown(not R.db.needsOnly or self.gearView=="mine" or state=="MISSING" or state:find("TIER_STATS",1,true))
  row:SetScript("OnClick",function(owner)self.selectedSlot=owner.slotID;self:RenderRows();self:RenderDetail()end)
  if item then R.RequestItem(item.id) end
 end
 local data,why=R.GetDataset();self.noData:SetShown(not data);self.noData:SetWidth(width-16);self.noData:SetText(R.L(why or "NO_DATA"))
end
-- All socketed items share one scroll view; no full-page hero or per-item paging.
function UI:CreateSocketPane()
 self.socketPane=CreateFrame("Frame",nil,self.prepPane);self.socketPane:SetAllPoints();self.socketPane:Hide()
 self.socketScroll,self.socketChild=scrollFrame(self.socketPane)
 self.socketScroll:ClearAllPoints();self.socketScroll:SetPoint("TOPLEFT",8,-101);self.socketScroll:SetPoint("BOTTOMRIGHT",-27,8)
 self.socketCards={};self.socketScopeButtons={}
 for index,scope in ipairs({"equipped","bags"}) do
  local b=CreateFrame("Button",nil,self.socketPane,"UIPanelButtonTemplate,BackdropTemplate");b:SetSize(110,25);b:SetPoint("TOPLEFT",12+(index-1)*118,-41);R.SkinButton(b)
  b:SetScript("OnClick",function()self.socketScope=scope;self.socketScroll:SetVerticalScroll(0);self:Refresh()end)
  self.socketScopeButtons[scope]=b
 end
end
function UI:RenderSockets()
 local inBags=self.socketScope=="bags"
 for scope,b in pairs(self.socketScopeButtons) do b:SetText(R.L(scope=="bags" and "SOCKET_IN_BAGS" or "SOCKET_EQUIPPED"));b:SetEnabled((self.socketScope or "equipped")~=scope) end
 self.prepSummary:ClearAllPoints();self.prepSummary:SetPoint("TOPLEFT",12,-77)
 local overview=R.GetSocketOverview(self.socketScope);self.socketOverview=overview;self.socketEntries={}
 for _,entry in ipairs(overview.items) do if not R.db.needsOnly or entry.sockets.empty>0 then self.socketEntries[#self.socketEntries+1]=entry end end
 self.prepScroll:Hide();self.prepPrev:Hide();self.prepNext:Hide();self.prepPosition:Hide();self.socketPane:Show()
 self.prepSummary:SetText(R.L("SOCKET_OVERVIEW",overview.filled,overview.total,overview.recommended,overview.empty))
 local width=self.socketScroll:GetWidth();local column=width/2;local h=210
 self.socketChild:SetWidth(width);self.socketChild:SetHeight(math.max(1,math.ceil(#self.socketEntries/2)*h))
 for _,card in ipairs(self.socketCards) do card:Hide() end
 for index,entry in ipairs(self.socketEntries) do
  local card=self.socketCards[index]
  if not card then
   card=CreateFrame("Button",nil,self.socketChild,"BackdropTemplate");self.socketCards[index]=card
   card.icon=card:CreateTexture(nil,"ARTWORK");card.icon:SetSize(32,32);card.icon:SetPoint("TOPLEFT",9,-9);card.icon:SetTexCoord(.07,.93,.07,.93)
   card.border=card:CreateTexture(nil,"BACKGROUND");card.border:SetColorTexture(.55,.47,.32,1);card.border:SetPoint("TOPLEFT",card.icon,"TOPLEFT",-1,1);card.border:SetPoint("BOTTOMRIGHT",card.icon,"BOTTOMRIGHT",1,-1)
   card.title=label(card,11,GOLD);card.title:SetPoint("TOPLEFT",49,-9);card.title:SetHeight(28);card.title:SetMaxLines(2)
   card.state=label(card,10);card.state:SetPoint("TOPLEFT",49,-39);card.state:SetHeight(12)
   card.current=label(card,10);card.current:SetPoint("TOPLEFT",10,-63);card.current:SetHeight(12);card.current:SetMaxLines(1)
   card.plan=label(card,10);card.plan:SetPoint("TOPLEFT",column/2+3,-63);card.plan:SetHeight(12);card.plan:SetMaxLines(1)
   card.gemRows={}
   for i=1,8 do
    local b=CreateFrame("Button",nil,card);b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(22,22);b.icon:SetPoint("LEFT",0,0);b.icon:SetTexCoord(.07,.93,.07,.93);b.name=label(b,9);b.name:SetPoint("TOPLEFT",26,-1);b.name:SetHeight(26);b.name:SetMaxLines(2);card.gemRows[i]=b
   end
  end
  place(card,"TOPLEFT",self.socketChild,"TOPLEFT",((index-1)%2)*column+2,-math.floor((index-1)/2)*h);card:SetSize(column-6,h-5);R.SkinPanel(card,"card")
  card.title:SetWidth(column-64);card.state:SetWidth(column-64);card.current:SetWidth(column-26);card.plan:SetWidth(column-26)
  card.icon:SetTexture(R.ItemIcon(entry.item));card.title:SetText(R.ItemName(entry.item));card.state:SetText(R.L("ITEM_SOCKET_COUNT",entry.sockets.filled,entry.sockets.total));card.state:SetTextColor(unpack(entry.sockets.empty>0 and RED or GREEN))
  place(card.plan,"TOPLEFT",card,"TOPLEFT",column/2+3,-63)
  card.current:SetWidth(column/2-15);card.plan:SetWidth(column/2-15);card.current:SetText(R.L(inBags and "SOCKET_INSERTED_GEMS" or "CURRENT_GEMS"));card.plan:SetText(R.L("RECOMMENDED_GEMS"))
  for i,button in ipairs(card.gemRows) do
   local current=i<=4;local index=current and i or i-4
   local socket=current and entry.sockets.gems[index];local rec=not current and entry.recommendations[index]
   local item=socket and socket.item or rec and rec.item
   button:SetShown(not not (socket or rec))
   if button:IsShown() then
    place(button,"TOPLEFT",card,"TOPLEFT",current and 10 or column/2+3,-82-(index-1)*29);button:SetSize(column/2-18,28);button.name:SetWidth(column/2-46)
    button.icon:SetTexture(item and R.ItemIcon(item) or "Interface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic")
    button.name:SetText(item and (rec and rec.count.." × " or "")..R.ItemName(item) or R.L("EMPTY_SOCKET"));button.name:SetTextColor(unpack(item and WHITE or RED))
    button:SetScript("OnEnter",function(owner)if item then self:ShowItemTooltip(owner,item) end end);button:SetScript("OnLeave",function()GameTooltip:Hide()end)
   end
  end
  card:SetScript("OnEnter",function(owner)self:ShowItemTooltip(owner,entry.item,entry.slotID,not inBags)end);card:SetScript("OnLeave",function()GameTooltip:Hide()end)
  card:SetScript("OnClick",function()
   self:DetailClear();self:DetailSection(R.L("SOCKET_PLAN"),GOLD);self:DetailItem(entry.item,R.L("ITEM_SOCKET_COUNT",entry.sockets.filled,entry.sockets.total),nil,true)
   for _,rec in ipairs(entry.recommendations) do self:DetailItem(rec.item,rec.count.." × · "..R.L("GEM_BAG_COUNT",R.scan.bags[rec.item.id] or 0)) end
   if inBags then self:DetailText(R.L("SOCKET_BAG_HELP"),MUTED,11) end
   self:DetailText(R.L("GEM_EVIDENCE"),MUTED,11);self:DetailFinish()
  end);card:Show()
 end
 self.prepEmpty:SetShown(#self.socketEntries==0);self.prepEmpty:SetText(R.L(inBags and (R.db.needsOnly and "NO_EMPTY_BAG_SOCKETS" or "NO_BAG_SOCKETS") or (R.db.needsOnly and "NO_EMPTY_SOCKETS" or "NO_SOCKETS")))
 self:DetailClear();self:DetailSection(R.L("SOCKETS_GEMS"),GOLD);self:DetailText(R.L(inBags and "SOCKET_BAG_HELP" or "SOCKET_HELP"));self:DetailFinish()
end
local previousRefresh=UI.Refresh
function UI:Refresh()
 if not self.frame or not self.frame:IsShown() then return end
 self:Layout();previousRefresh(self)
 self.title:SetText(R.NAME);self.themeButton:Hide();self.characterName:Hide()
 self.sectionTitle:SetText(self.view=="equipment" and R.L(R.GetMode()=="mythicplus" and "MPLUS_GEAR_TITLE" or "RAID_GEAR_TITLE") or R.L(self.view=="preparation" and "PREPARATION" or self.view=="stats" and "STATS" or self.view=="meta" and "META" or "DATA_SETTINGS"))
 self.buttons.SOURCES:SetText(R.L("DATA_UPDATES"))
 for key,view in pairs({EQUIPMENT="equipment",STATS="stats",PREPARATION="preparation",META="meta",SOURCES="sources"}) do R.StyleNavigation(self.buttons[key],self.view==view) end
 self.buttons.MYTHICPLUS:SetText(self.view=="meta" and R.L("META_MPLUS") or "Mythic+ · Murlok");self.buttons.RAID:SetText(self.view=="meta" and R.L("META_RAID") or "Raid · Wowhead")
 if self.view~="meta" then self.footer:SetText(R.VERSION.." · "..(self.view=="equipment" and R.GetGearSummary() or R.DataStatus(R.GetDataset()))) end
 if self.view=="stats" then local profile=R.StatProfile();self.footer:SetText(R.VERSION.." · Murlok.io · M+ · "..(profile and profile.updatedAt:sub(1,10) or R.L("NO_DATA"))) end
end
