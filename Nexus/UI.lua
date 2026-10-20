local _,R=...
local UI={view="equipment",selectedSlot=1,gearView="targets",prepCategory="enchants",prepPage=1};R.UI=UI
local GOLD,WHITE,GREEN,RED,GREY={.86,.73,.45},{.88,.87,.82},{.1,1,.1},{1,.1,.1},{.60,.60,.56}
local function Font(parent,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");f:SetFont(R.FONT,size or 12,"");f:SetShadowOffset(1,-1);f:SetJustifyH("LEFT");f:SetTextColor(unpack(color or WHITE));return f
end
local function Button(parent,width,text,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate,BackdropTemplate");b:SetSize(width,25);b:SetText(text or "");local f=b:GetFontString();if f then f:SetFont(R.FONT,12,"") end;b:SetScript("OnClick",callback);R.SkinButton(b);return b
end
local function HidePool(pool)
 for _,entry in ipairs(pool) do
  if entry.Hide then entry:Hide() else for _,widget in pairs(entry) do if type(widget)=="table" or type(widget)=="userdata" then if widget.Hide then widget:Hide() end end end end
 end
end
local function Scroll(parent)
 local f=CreateFrame("ScrollFrame",nil,parent,"UIPanelScrollFrameTemplate");f:SetPoint("TOPLEFT",7,-7);f:SetPoint("BOTTOMRIGHT",-27,7)
 local child=CreateFrame("Frame",nil,f);child:SetSize(300,1);f:SetScrollChild(child);return f,child
end
function UI:ShowItemTooltip(owner,item,slot,inventory,specID,mode)
 if not item then return end
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
 local previous,previousMode=R.tooltipSpecID,R.tooltipMode;R.tooltipSpecID=specID or (inventory and R.SpecID() or R.ViewSpecID());R.tooltipMode=mode or R.GetMode()
 if inventory and slot then GameTooltip:SetInventoryItem("player",slot)
 elseif item.id and item.id>0 then GameTooltip:SetHyperlink(item.link or "item:"..item.id)
 elseif C_Spell and C_Spell.GetSpellInfo and GameTooltip.SetSpellByID then
  local info=C_Spell.GetSpellInfo(item.name)
  if info and info.spellID then GameTooltip:SetSpellByID(info.spellID) else GameTooltip:SetText(item.name or R.L("LOADING")) end
 else GameTooltip:SetText(item.name or R.L("LOADING"));if item.source then GameTooltip:AddLine(item.source,1,.82,0) end end
 R.tooltipSpecID,R.tooltipMode=previous,previousMode
 if item.targetIlvl then GameTooltip:AddLine(R.L("TARGET_ILVL",item.targetIlvl),1,.82,0);if not item.link then GameTooltip:AddLine(R.L("BASE_TOOLTIP"),.65,.65,.65,true) end end
 GameTooltip:Show()
end
function UI:ShowCopy(text,title)
 if not self.copyFrame then
  local f=CreateFrame("Frame","NexusCopyFrame",UIParent,"BackdropTemplate");f:SetSize(560,140);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");f:SetFrameLevel(900);f:SetClampedToScreen(true)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
  f.title=Font(f,14,GOLD);f.title:SetPoint("TOPLEFT",18,-17)
  f.edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.edit:SetSize(510,28);f.edit:SetPoint("TOPLEFT",24,-50);f.edit:SetFont(R.FONT,12,"");f.edit:SetAutoFocus(false)
  f.edit:SetScript("OnEscapePressed",function()f:Hide()end);f.edit:SetScript("OnEnterPressed",function()f:Hide()end)
  f.close=Button(f,90,R.L("CLOSE"),function()f:Hide()end);f.close:SetPoint("BOTTOMRIGHT",-18,17);tinsert(UISpecialFrames,"NexusCopyFrame");self.copyFrame=f
 end
 local f=self.copyFrame;f.title:SetText(title or R.NAME.." · Ctrl+C");f.close:SetText(R.L("CLOSE"));f.edit:SetText(text or "");f:Show();f.edit:SetFocus();f.edit:HighlightText()
end
function UI:DetailClear()
 HidePool(self.detailPool);self.detailIndex=0;self.detailY=8;self.detailSection=nil;self.detailChild:SetWidth(math.max(260,self.detailScroll:GetWidth()));self.detailScroll:SetVerticalScroll(0)
end
function UI:DetailEndSection()
 if self.detailSection then
  self.detailSection.panel:SetHeight(self.detailY-self.detailSection.y+10)
  self.detailY=self.detailY+26;self.detailSection=nil
 end
end
function UI:DetailSection(title,color)
 self:DetailEndSection();self.detailIndex=self.detailIndex+1
 local e=self.detailPool[self.detailIndex] or {};self.detailPool[self.detailIndex]=e
 if not e.panel then e.panel=CreateFrame("Frame",nil,self.detailChild,"BackdropTemplate");e.bg=e.panel end
 e.y=self.detailY;e.panel:ClearAllPoints();e.panel:SetPoint("TOPLEFT",1,-e.y);e.panel:SetWidth(self.detailChild:GetWidth()-3);R.SkinPanel(e.panel,"detail");e.panel:Show()
 self.detailSection=e;self.detailY=self.detailY+14;self:DetailText(title,color or GOLD,13)
end
function UI:DetailPoint(widget,x)
 local section=self.detailSection;local parent=section and section.panel or self.detailChild
 widget:SetParent(parent);widget:ClearAllPoints();widget:SetPoint("TOPLEFT",parent,"TOPLEFT",x or 12,-(self.detailY-(section and section.y or 0)))
end
function UI:DetailText(text,color,size)
 self.detailIndex=self.detailIndex+1;local e=self.detailPool[self.detailIndex] or {};self.detailPool[self.detailIndex]=e
 if not e.text then e.text=Font(self.detailChild,size,color) end
 local f=e.text;self:DetailPoint(f);f:SetWidth(self.detailChild:GetWidth()-28);f:SetFont(R.FONT,size or 12,"");f:SetTextColor(unpack(color or WHITE));f:SetText(text or "");f:Show();self.detailY=self.detailY+math.max(size or 12,f:GetStringHeight())+10;return f
end
function UI:DetailButton(text,callback)
 self.detailIndex=self.detailIndex+1;local e=self.detailPool[self.detailIndex] or {};self.detailPool[self.detailIndex]=e
 if not e.button then e.button=Button(self.detailChild,200) end
 local b=e.button;self:DetailPoint(b);b:SetWidth(self.detailChild:GetWidth()-28);b:SetText(text);b:SetScript("OnClick",callback);b:Show();self.detailY=self.detailY+32;return b
end
local function ItemRow(parent)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(38,38);b.icon:SetPoint("LEFT",8,0);b.icon:SetTexCoord(.07,.93,.07,.93)
 b.border=b:CreateTexture(nil,"OVERLAY");b.border:SetColorTexture(.55,.47,.32,1);b.border:SetDrawLayer("BACKGROUND");b.border:SetPoint("TOPLEFT",b.icon,"TOPLEFT",-1,1);b.border:SetPoint("BOTTOMRIGHT",b.icon,"BOTTOMRIGHT",1,-1)
 b.text=Font(b,12);b.text:SetPoint("TOPLEFT",48,-5);b.text:SetMaxLines(2)
 b.note=Font(b,11,GREY);b.note:SetPoint("BOTTOMLEFT",48,5);b.note:SetMaxLines(1)
 b.red=b:CreateTexture(nil,"OVERLAY");b.red:SetAllPoints(b.icon);b.red:SetColorTexture(.85,.02,.02,.34)
 b.check=b:CreateTexture(nil,"OVERLAY");b.check:SetSize(23,23);b.check:SetPoint("BOTTOMRIGHT",b.icon,"BOTTOMRIGHT",6,-4);b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");b.check:SetVertexColor(.15,1,.15)
 b.selected=b:CreateTexture(nil,"BACKGROUND");b.selected:SetAllPoints();b.selected:SetColorTexture(1,.82,0,.10)
 b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");return b
end
function UI:BindItem(row,item,slot,inventory,showOwnership)
 row.item=item;row.slotID=slot;local descriptor=R.SLOT_BY_ID[slot];local fallback=descriptor and "Interface\\PaperDoll\\UI-PaperDoll-Slot-"..descriptor.icon
 row.icon:SetTexture(R.ItemIcon(item,fallback));row.icon:SetVertexColor(1,1,1)
 local state=item and R.Ownership(item.id,slot or 0) or "EMPTY"
 local missing=showOwnership and state=="MISSING";row.red:SetShown(missing);row.check:SetShown(showOwnership and state=="EQUIPPED")
 if missing then row.icon:SetVertexColor(1,.28,.28) end
 row:SetScript("OnEnter",function(owner)self:ShowItemTooltip(owner,item,slot,inventory)end);row:SetScript("OnLeave",function()GameTooltip:Hide()end)
 return state
end
function UI:DetailItem(item,note,callback,large)
 self.detailIndex=self.detailIndex+1;local e=self.detailPool[self.detailIndex] or {};self.detailPool[self.detailIndex]=e
 if not e.item then e.item=ItemRow(self.detailChild) end
 local b=e.item;self:DetailPoint(b,10);b:SetSize(self.detailChild:GetWidth()-24,large and 88 or 64)
 b.icon:SetSize(large and 60 or 38,large and 60 or 38);local x=large and 80 or 54
 b.text:ClearAllPoints();b.text:SetPoint("TOPLEFT",x,-8);b.text:SetWidth(b:GetWidth()-x-5);b.text:SetText(R.ItemName(item));b.text:SetTextColor(unpack(GOLD))
 b.note:ClearAllPoints();b.note:SetPoint("BOTTOMLEFT",x,8);b.note:SetWidth(b:GetWidth()-x-5);b.note:SetText(note or "")
 b.selected:Hide();self:BindItem(b,item,nil,false,false);b:SetScript("OnClick",callback);b:Show();self.detailY=self.detailY+b:GetHeight()+8;return b
end
function UI:DetailFinish()self:DetailEndSection();self.detailChild:SetHeight(self.detailY+8)end
function UI:JournalStatusChanged(id)
 local active=self.detailActiveItem
 if self.frame and self.frame:IsShown() and self.view=="equipment" and active and active.id==id then self:RenderDetail(active,self.detailActiveSlot) end
end
function UI:GetShownItem(slot)
 if self.gearView=="mine" then return R.scan and R.scan.equipped[slot] end
 return R.GetGearTarget(slot)
end
function UI:RenderDetail(override,slotOverride)
 self:DetailClear();local slotID=slotOverride or self.selectedSlot;if slotOverride==false then slotID=nil end;local slot=R.SLOT_BY_ID[slotID]
 local item=override or self:GetShownItem(slotID)
 self.detailActiveItem,self.detailActiveSlot=item,slotID
 if slot then self:DetailText(R.L(slot.key),GOLD,14) end
 if not item then self:DetailText(R.L("NO_DATA"),GREY);self:DetailFinish();return end
 self:DetailSection(R.L("SELECTED_ITEM"),GOLD)
 self:DetailItem(item,item.source or (self.gearView=="mine" and R.L("CURRENT_ITEM")),nil,true)
 local state=R.Ownership(item.id,slotID or 0);self:DetailText(R.L(state)..(state=="MISSING" and " · "..R.ShortSource(item) or ""),state=="MISSING" and RED or GREEN)
 local level=R.ItemLevel(item,self.gearView=="mine")
 if level then self:DetailText(R.L("ILVL")..": "..level..(item.ilvlBasis and " · "..item.ilvlBasis or ""),GOLD) end
 if item.count then local d=R.GetDataset();self:DetailText(R.L("SAMPLE")..": "..item.count.." / "..(item.sampleSize or (d and d.sampleSize) or "?")) end
 if item.updatedAt then self:DetailText(R.L("SNAPSHOT")..": "..item.updatedAt:sub(1,10),GREY) end
 if slot and self.view=="equipment" then
  self:DetailSection(R.L("ACQUISITION"),GOLD)
  self:DetailText(R.L("DROP_FROM"),GOLD);self:DetailText(R.LootInfo(item),WHITE)
  if item.catalyst then self:DetailText(R.L("CATALYST_NOTE"),GREY) end
  if not item.crafted then
   self:DetailButton(R.L("OPEN_JOURNAL"),function()R.OpenLoot(item)end)
   if R.journalStatus and R.journalStatus.id==item.id and R.journalStatus.key then self:DetailText(R.L(R.journalStatus.key),GREY,11) end
  end
  if item.targetIlvl then self:DetailText(R.L("UPGRADE"),GOLD);self:DetailText(R.UpgradeText(item,slotID));self:DetailText(R.L("DISCOUNT_NOTE"),GREY) end
  local current=R.scan and R.scan.equipped[slotID]
  if current then self:DetailSection(R.L("CURRENT_ITEM"),GREEN);self:DetailItem(current,R.L("ILVL")..": "..(R.ItemLevel(current,true) or "?")) end
  if item.crafted then
   self:DetailSection(R.L("CRAFT_MATERIALS"),GOLD);local materials=R.GetCraftMaterials(item.id)
   if not materials or #materials==0 then self:DetailText(R.L("CRAFT_PENDING"),GREY)
   else for _,group in ipairs(materials) do for _,reagent in ipairs(group.choices) do self:DetailItem(reagent,group.count.." × "..R.L("REAGENT_CHOICE")) end end end
  end
  local candidates=R.GetGearCandidates(slotID)
  if #candidates>1 then
   self:DetailSection(R.L("ALTERNATIVES"),GREY)
   for _,alternative in ipairs(candidates) do
    if alternative.id~=item.id then
     local alt=alternative;self:DetailItem(alt,(alt.source or "").." · "..(R.ItemLevel(alt,false) or "?").." ilvl",function()self:RenderDetail(alt,slotID)end)
    end
   end
  end
 end
 self:DetailEndSection();self:DetailText(R.L(self.view=="equipment" and "SOURCE_SCOPE_NOTE" or "POPULARITY_NOTE"),GREY,11)
 self:DetailButton("Wowhead · "..R.L("COPY_URL"),function()self:ShowCopy("https://www.wowhead.com/item="..item.id)end)
 self:DetailFinish()
end
function UI:ScrollGear(offset)
 self.gearOffset=math.max(0,math.min(self.gearRange or 0,offset or 0));self.gearScroll:SetVerticalScroll(self.gearOffset)
end
function UI:RevealGearSlot(slotID)
 for _,b in ipairs(self.rows) do if b.slotID==slotID then
  local top=b.gridTop;local bottom=top+b:GetHeight();local offset=self.gearOffset or 0
  if top<offset then self:ScrollGear(top) elseif bottom>offset+self.gearScroll:GetHeight() then self:ScrollGear(bottom-self.gearScroll:GetHeight()) end
  return
 end end
end
function UI:RenderRows()
 local d=R.GetDataset();local top=4
 self.gearScroll:ClearAllPoints();self.gearScroll:SetPoint("TOPLEFT",self.gearPane,"TOPLEFT",0,-top);self.gearScroll:SetPoint("BOTTOMRIGHT",self.gearPane,"BOTTOMRIGHT",-26,4)
 local height=math.max(64,(self.gearScroll:GetHeight()+4)/8);local width=self.gearScroll:GetWidth()/2
 self.gearChild:SetWidth(self.gearScroll:GetWidth());self.gearChild:SetHeight(height*8-4)
 self.gearRange=math.max(0,self.gearChild:GetHeight()-self.gearScroll:GetHeight())
 if self.gearScroll.ScrollBar then self.gearScroll.ScrollBar:SetShown(self.gearRange>1) end
 self:ScrollGear(self.gearOffset)
 for index,slot in ipairs(R.SLOTS) do
  local b=self.rows[index];local col=index>8 and 1 or 0;local position=(index-1)%8
  b.gridTop=position*height;b:ClearAllPoints();b:SetPoint("TOPLEFT",self.gearChild,"TOPLEFT",col*width+2,-b.gridTop);b:SetSize(width-6,height-4)
  b.icon:SetSize(38,38);b.text:SetWidth(b:GetWidth()-65);b.note:SetWidth(b:GetWidth()-65)
  local item=self:GetShownItem(slot.id);local state=self:BindItem(b,item,slot.id,self.view=="equipment" and self.gearView=="mine",true)
  b.text:SetText(R.L(slot.key)..(item and R.ItemLevel(item,self.gearView=="mine") and " · "..R.ItemLevel(item,self.gearView=="mine") or ""));b.text:SetTextColor(unpack(GOLD))
  b.note:SetText(item and R.ItemName(item) or R.L("EMPTY"));b.note:SetTextColor(unpack(item and WHITE or GREY))
  b.ownership:SetText(item and (R.L(state)..(state=="MISSING" and " · "..R.ShortSource(item) or "")) or "");b.ownership:SetTextColor(unpack(state=="MISSING" and RED or GREEN));b.ownership:SetWidth(b:GetWidth()-65)
  local here=self.view=="equipment" and self.gearView=="targets" and R.ViewSpecID()==R.SpecID() and item and R.DungeonAlerts:IsHighlighted(item.id)
  R.SkinPanel(b,here and "dungeon" or "card",self.selectedSlot==slot.id)
  b.selected:SetShown(self.selectedSlot==slot.id);b:SetShown(not R.db.needsOnly or self.gearView=="mine" or state=="MISSING")
  b:SetScript("OnClick",function(owner)self.selectedSlot=owner.slotID;self:RenderRows();self:RenderDetail()end)
  if item then R.RequestItem(item.id) end
 end
 self.noData:SetShown(not d);self.noData:SetWidth(self.gearPane:GetWidth()-12)
 if not d then local _,why=R.GetDataset();self.noData:SetText(R.L(why or "NO_SNAPSHOT")) end
end
function UI:ListClear()HidePool(self.listPool);self.listIndex=0;self.listY=4;self.listChild:SetWidth(self.listScroll:GetWidth());self.listScroll:SetVerticalScroll(0)end
function UI:ListLine(text,item,note,callback,color)
 self.listIndex=self.listIndex+1;local b=self.listPool[self.listIndex]
 if not b then b=ItemRow(self.listChild);self.listPool[self.listIndex]=b end
 b:ClearAllPoints();b:SetPoint("TOPLEFT",0,-self.listY);b:SetSize(self.listChild:GetWidth(),item and 60 or 54);b.text:SetWidth(b:GetWidth()-60);b.note:SetWidth(b:GetWidth()-60)
 b.text:SetText(text);b.text:SetTextColor(unpack(color or WHITE));b.note:SetText(note or "");b.icon:SetShown(item~=nil);b.border:SetShown(item~=nil);b.red:Hide();b.check:Hide();b.selected:Hide()
 if item then self:BindItem(b,item,nil,false,false) else b:SetScript("OnEnter",nil);b:SetScript("OnLeave",nil) end
 b:SetScript("OnClick",callback);b:Show();self.listY=self.listY+b:GetHeight()+4;return b
end
function UI:RenderPreparation()
 local d=R.GetDataset();local entries={};local needs,ready,empty=0,0,0;local browsing=R.IsViewingOtherClass()
 for category,b in pairs(self.prepTabs) do b:SetText(R.L(category=="enchants" and "ENCHANTS" or category=="gems" and "SOCKETS_GEMS" or "CONSUMABLES"));b:SetEnabled(category~=self.prepCategory) end
 self.socketPane:Hide();self.prepScroll:Show();self.prepPrev:Hide();self.prepNext:Hide();self.prepPosition:Hide()
 if self.prepCategory=="gems" and not browsing then for _,row in ipairs(self.prepRows) do row:Hide() end;self:RenderSockets();return end
 self.prepPrev:SetScript("OnClick",function()self.prepPage=math.max(1,self.prepPage-1);self:Refresh()end)
 self.prepNext:SetScript("OnClick",function()self.prepPage=math.min(self.prepPages or 1,self.prepPage+1);self:Refresh()end)
 local function add(entry)
  if entry.needed then needs=needs+1 else ready=ready+1 end
  if browsing or not R.db.needsOnly or entry.needed then entries[#entries+1]=entry end
 end
 if browsing and self.prepCategory=="enchants" then
  for _,slot in ipairs(R.SLOTS) do
   local e=d and d.enchants and d.enchants[slot.id]
   if e and e.name then add({title=R.L(slot.key),item={id=e.id,name=e.name,icon=e.icon,source=e.source or "Murlok.io"},note=e.name,status=R.L("RECOMMENDED"),preview=true,slotID=slot.id}) end
  end
 elseif browsing and self.prepCategory=="gems" then
  for _,gem in ipairs(d and d.gems or {}) do add({title=R.L("GEM_OPTION"),item=gem,note=R.ItemName(gem),status=gem.source or "Murlok.io",preview=true}) end
 else
 for _,check in ipairs(R.GetPreparation()) do
  local slot=R.SLOT_BY_ID[check.slotID]
  if self.prepCategory=="enchants" and check.enchant then
   local e=check.enchant
   add({title=slot and R.L(slot.key),item={id=e.id,name=e.name,icon=e.icon,source=e.source or "Murlok.io"},note=e.name,status=R.L(check.key),needed=check.needed,matched=check.key=="ENCHANT_MATCH",current=check.item,slotID=check.slotID})
  elseif self.prepCategory=="consumables" and check.consumable then
   add({title=check.item.category or R.L("CONSUMABLES"),item=check.item,note=R.ItemName(check.item),status=R.L(check.key).." ("..check.count..")",needed=check.needed,matched=not check.needed})
  end
 end
 end
 local viewed=R.SpecInfo(R.ViewSpecID())
 self.prepSummary:SetText(browsing and viewed and R.L("PREVIEW_RECOMMENDATIONS",viewed.class.name,viewed.name) or R.L("PREP_SUMMARY",needs,ready))
 local pageSize=#self.prepRows;self.prepPages=1;self.prepPage=1
 self.prepPosition:SetText(self.prepPage.." / "..self.prepPages);self.prepPrev:SetEnabled(self.prepPage>1);self.prepNext:SetEnabled(self.prepPage<self.prepPages)
 local contentWidth=self.prepScroll:GetWidth();self.prepChild:SetWidth(contentWidth);local width=contentWidth/2;local height=74
 self.prepChild:SetHeight(math.max(1,math.ceil(#entries/2)*height));self.prepPrev:Hide();self.prepNext:Hide();self.prepPosition:Hide();self.prepScroll:Show()
 for index,row in ipairs(self.prepRows) do
  local entry=entries[index];row:SetShown(entry~=nil)
  if entry then
   row:ClearAllPoints();row:SetPoint("TOPLEFT",self.prepChild,"TOPLEFT",((index-1)%2)*width+2,-math.floor((index-1)/2)*height);row:SetSize(width-6,height-4);R.SkinPanel(row,"card")
   row.icon:ClearAllPoints();row.icon:SetPoint("LEFT",8,0);row.icon:SetSize(32,32)
   row.text:ClearAllPoints();row.text:SetPoint("TOPLEFT",50,-7);row.text:SetSize(width-62,12);row.text:SetFont(R.FONT,10,"")
   row.note:ClearAllPoints();row.note:SetPoint("TOPLEFT",50,-22);row.note:SetSize(width-62,27);row.note:SetMaxLines(2);row.note:SetFont(R.FONT,11,"")
   row.status:ClearAllPoints();row.status:SetPoint("BOTTOMLEFT",50,5);row.status:SetSize(width-62,12);row.status:SetFont(R.FONT,10,"")
   row.text:SetText(entry.title);row.text:SetTextColor(unpack(GOLD));row.note:SetText(entry.note);row.status:SetText(entry.status);row.status:SetTextColor(unpack(entry.preview and GREY or entry.needed and RED or GREEN))
   self:BindItem(row,entry.item,entry.slotID,false,false);row.red:Hide();row.check:Hide();row.selected:Hide()
   row:SetScript("OnClick",function()
    self:DetailClear();self.detailActiveItem=nil;self:DetailSection(entry.title,GOLD);self:DetailItem(entry.item,entry.status,nil,true);self:DetailText(entry.note,GREY)
    if entry.current then self:DetailSection(R.L("CURRENT_ITEM"),GREEN);self:DetailItem(entry.current,R.L("ILVL")..": "..(R.ItemLevel(entry.current,true) or "?")) end
    self:DetailEndSection()
    if entry.item.id and entry.item.id>0 then self:DetailButton("Wowhead · "..R.L("COPY_URL"),function()self:ShowCopy("https://www.wowhead.com/item="..entry.item.id)end) end
    self:DetailFinish()
   end)
  end
 end
 self.prepEmpty:SetShown(#entries==0);self.prepEmpty:SetText(R.L(not browsing and R.db.needsOnly and "PREP_READY" or "NO_DATA"))
 self:DetailClear();self.detailActiveItem=nil;self:DetailSection(R.L("PREPARATION"),GOLD);self:DetailText(R.L("PREP_NAV_HELP"));self:DetailText(R.L("ENCHANT_HELP"),GREY);self:DetailFinish()
 if browsing then self:DetailText(R.L("PREVIEW_PREPARATION_HINT"),GREY);self:DetailFinish() end
end
function UI:RenderSources()
 self:ListClear();self:DetailClear()
 self:DetailText(R.L("DATA_SETTINGS"),GOLD,14)
 self:DetailText(R.L("SIMPLIFIED_NOTE"),WHITE)
 self:DetailSection(R.L("SNAPSHOT"),GOLD)
 self:DetailText(R.DataStatus(R.GetDataset()),GOLD)
 self:DetailText(R.L("UPDATE_NOTE"),GREY,12)
 for _,mode in ipairs({"mythicplus","raid"}) do
  local dataset=R.GetDataset(mode)
  if dataset then
   local url=dataset.sourceURL
   self:ListLine(R.L(mode=="raid" and "RAID" or "MYTHICPLUS"),nil,R.DataStatus(dataset),function()
    if url then self:ShowCopy(url,R.L("SOURCE_OPEN").." · Ctrl+C") end
   end,GOLD)
  end
 end
 self:DetailFinish();self.listChild:SetHeight(self.listY)
end
function UI:Refresh()
 if not self.frame or not self.frame:IsShown() then return end
 self.title:SetText(R.NAME.." · "..R.VERSION);self.themeButton:SetText(R.L("APPEARANCE")..": "..R.Theme().name);local d=R.GetDataset()
 self:RefreshSpecControls()
 for key,b in pairs(self.buttons) do b:SetText(R.L(key)) end
 if self.view=="meta" then self.buttons.MYTHICPLUS:SetText(R.L("META_MPLUS"));self.buttons.RAID:SetText(R.L("META_RAID")) end
 self.buttons.MYTHICPLUS:SetEnabled(R.GetMode()~="mythicplus");self.buttons.RAID:SetEnabled(R.GetMode()~="raid")
 self.buttons.META:SetEnabled(self.view~="meta")
 self.buttons.MY_GEAR:SetEnabled(self.gearView~="mine");self.buttons.TARGETS:SetEnabled(self.gearView~="targets")
 self.needsLabel:SetText(R.L("NEEDS_ONLY"));self.needs:SetChecked(R.db.needsOnly)
 self.themeButton:SetShown(self.view=="sources");for _,b in ipairs(self.languageButtons) do b:SetShown(self.view=="sources") end
 self.buttons.REFRESH:SetText(R.L("RESCAN_GEAR"));self.buttons.SOURCES:SetText(R.L("DATA_SETTINGS"))
 self.footer:SetWidth(self.frame:GetWidth()-70);self.footer:SetText(R.DataStatus(d).." · "..R.L("OWNERSHIP_HINT"))
 for _,b in ipairs(self.rows) do b:Hide() end;self.noData:Hide()
 self.listPane:SetShown(self.view=="sources");self.prepPane:SetShown(self.view=="preparation")
 self.metaPane:SetShown(self.view=="meta")
 self.detailPane:Show()
 self.gearScroll:SetShown(self.view=="equipment")
 self.buttons.MY_GEAR:SetShown(self.view=="equipment");self.buttons.TARGETS:SetShown(self.view=="equipment")
 local filterVisible=self.view=="equipment" or self.view=="preparation" and not R.IsViewingOtherClass()
 self.needs:SetShown(filterVisible);self.needsLabel:SetShown(filterVisible)
 if self.view=="meta" then self:RenderMeta() elseif self.view=="preparation" then self:RenderPreparation() elseif self.view=="sources" then self:RenderSources() else self:RenderRows();self:RenderDetail() end
end
function UI:SetView(view)
 if self.view~=view then self.gearOffset=0 end
 if view=="meta" and self.metaFollowSpec==nil then self.metaFollowSpec=R.ViewSpecID();self.metaLastMode=R.GetMode() end
 if view~="equipment" and view~="preparation" and view~="meta" and view~="sources" then view="equipment" end
 self.view=view;self:Refresh()
end
function UI:Create()
 if self.frame then return end
 local f=CreateFrame("Frame","NexusMainFrame",UIParent,"ButtonFrameTemplate,BackdropTemplate");self.frame=f
 local width=math.min(1280,math.max(960,R.db.width or R.DEFAULT_WIDTH));local height=math.min(900,math.max(700,R.db.height or R.DEFAULT_HEIGHT))
 f:SetSize(width,height);f:SetPoint("CENTER",UIParent,"CENTER",R.db.x or 0,R.db.y or 0);f:SetFrameStrata("DIALOG");f:SetClampedToScreen(true);f:SetMovable(true);f:EnableMouse(true);f:SetResizable(true);f:SetResizeBounds(960,700,1280,900);f:RegisterForDrag("LeftButton")
 f:SetScript("OnDragStart",function(o)if not InCombatLockdown() then o:StartMoving() end end)
 f:SetScript("OnDragStop",function(o)o:StopMovingOrSizing();local x,y=o:GetCenter();local cx,cy=UIParent:GetCenter();R.db.x,R.db.y=x-cx,y-cy end)
 f:SetScript("OnSizeChanged",function(_,w,h)R.db.width,R.db.height=w,h;if self.detailScroll then self:Refresh() end end);f:SetScript("OnHide",function()GameTooltip:Hide();self:CloseSpecMenus()end);f:Hide();tinsert(UISpecialFrames,"NexusMainFrame")
 self.title=f.TitleContainer.TitleText;self.title:SetFont(R.FONT,14,"");SetPortraitTexture(f.PortraitContainer.portrait,"player")
 f.PortraitContainer.portrait:SetTexture(R.ASSET_PATH.."nexus-icon.tga")
 f.Inset:ClearAllPoints();f.Inset:SetPoint("TOPLEFT",5,-91);f.Inset:SetPoint("BOTTOMRIGHT",-6,70)
 self.nativeChrome={};for _,key in ipairs({"NineSlice","TitleBg","TopTileStreaks","Inset"}) do local part=f[key];if part then self.nativeChrome[#self.nativeChrome+1]=part end end
 self.characterName=Font(f,10,GREY);self.characterName:SetPoint("BOTTOMLEFT",18,57);self.characterName:SetHeight(11);self.characterName:SetWidth(width-70);self.characterName:SetMaxLines(1)
 self:CreateSpecControls(f)
 self.buttons={};self.buttons.MYTHICPLUS=Button(f,190,"",function()R.db.mode="mythicplus";self.prepPage=1;self:Refresh()end);self.buttons.MYTHICPLUS:SetPoint("TOPRIGHT",-191,-34)
 self.buttons.RAID=Button(f,170,"",function()R.db.mode="raid";self.prepPage=1;self:Refresh()end);self.buttons.RAID:SetPoint("LEFT",self.buttons.MYTHICPLUS,"RIGHT",5,0)
 self.buttons.MY_GEAR=Button(f,105,"",function()self.gearView="mine";self:Refresh()end);self.buttons.MY_GEAR:SetPoint("TOPLEFT",17,-66)
 self.buttons.TARGETS=Button(f,125,"",function()self.gearView="targets";self:Refresh()end);self.buttons.TARGETS:SetPoint("LEFT",self.buttons.MY_GEAR,"RIGHT",5,0)
 self.needs=CreateFrame("CheckButton",nil,f,"UICheckButtonTemplate");self.needs:SetSize(26,26);self.needs:SetPoint("LEFT",self.buttons.TARGETS,"RIGHT",10,0);self.needs:SetScript("OnClick",function(o)R.db.needsOnly=o:GetChecked() and true or false;self:Refresh()end)
 self.needsLabel=Font(f,12);self.needsLabel:SetPoint("LEFT",self.needs,"RIGHT",1,0)
 self.languageButtons={}
 for index,language in ipairs({"EN","SK","CZ"}) do local lang=language;local b=Button(f,32,lang,function()R.db.language=lang;self:Refresh()end);b:SetPoint("TOPRIGHT",-15-(3-index)*35,-66);self.languageButtons[#self.languageButtons+1]=b end
 self.themeButton=Button(f,155,"",function()
  for i,key in ipairs(R.THEME_ORDER) do if key==R.db.theme then R.SetTheme(R.THEME_ORDER[i%#R.THEME_ORDER+1]);break end end
 end);self.themeButton:SetPoint("TOPRIGHT",-128,-66)
 self.themeButton:SetScript("OnEnter",function(owner)GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(R.L("APPEARANCE"));GameTooltip:AddLine(R.L("THEME_HINT"),1,1,1,true);GameTooltip:AddLine("Classic / Slate / Frost / Ember",1,.82,0);GameTooltip:Show()end)
 self.themeButton:SetScript("OnLeave",function()GameTooltip:Hide()end)
 self.gearPane=CreateFrame("Frame",nil,f);self.gearPane:SetPoint("TOPLEFT",12,-103);self.gearPane:SetPoint("BOTTOMRIGHT",-371,70)
 self:CreateMetaPane()
 self.gearScroll=CreateFrame("ScrollFrame",nil,self.gearPane,"UIPanelScrollFrameTemplate");self.gearChild=CreateFrame("Frame",nil,self.gearScroll);self.gearChild:SetSize(300,1);self.gearScroll:SetScrollChild(self.gearChild)
 self.gearScroll:EnableMouseWheel(true);self.gearScroll:SetScript("OnMouseWheel",function(_,delta)self:ScrollGear((self.gearOffset or 0)-delta*64)end)
 self.gearScroll:HookScript("OnVerticalScroll",function(_,offset)self.gearOffset=offset end)
 self.rows={}
 for index,slot in ipairs(R.SLOTS) do
  local b=ItemRow(self.gearChild);b.icon:ClearAllPoints();b.icon:SetPoint("LEFT",10,0)
  b.text:ClearAllPoints();b.text:SetPoint("TOPLEFT",56,-7);b.text:SetHeight(14);b.text:SetMaxLines(1)
  b.note:ClearAllPoints();b.note:SetPoint("TOPLEFT",56,-25);b.note:SetHeight(13)
  b.ownership=Font(b,10);b.ownership:SetPoint("BOTTOMLEFT",56,7);b.ownership:SetHeight(12);b.ownership:SetMaxLines(1);self.rows[index]=b
 end
 self.noData=Font(self.gearPane,12,GREY);self.noData:SetPoint("BOTTOMLEFT",6,6)
 self.prepPane=CreateFrame("Frame",nil,f,"InsetFrameTemplate");self.prepPane:SetAllPoints(self.gearPane);self.prepTabs={};self.prepRows={}
 local previous
 for _,category in ipairs({"enchants","gems","consumables"}) do
  local key=category;local b=Button(self.prepPane,category=="gems" and 145 or 125,"",function()self.prepCategory=key;self.prepPage=1;self:Refresh()end)
  if previous then b:SetPoint("LEFT",previous,"RIGHT",5,0) else b:SetPoint("TOPLEFT",10,-10) end
  previous=b;self.prepTabs[category]=b
 end
 self.prepSummary=Font(self.prepPane,12,GOLD);self.prepSummary:SetPoint("TOPLEFT",12,-45);self.prepSummary:SetWidth(500)
 self.prepScroll,self.prepChild=Scroll(self.prepPane);self.prepScroll:ClearAllPoints();self.prepScroll:SetPoint("TOPLEFT",8,-69);self.prepScroll:SetPoint("BOTTOMRIGHT",-27,8)
 for index=1,20 do
  local row=ItemRow(self.prepChild);row.text:SetMaxLines(1);row.text:ClearAllPoints();row.text:SetPoint("TOPLEFT",58,-10);row.note:ClearAllPoints();row.note:SetPoint("TOPLEFT",58,-28);row.note:SetMaxLines(2)
  row.status=Font(row,10);row.status:SetPoint("BOTTOMLEFT",58,10);R.SkinPanel(row,"card");self.prepRows[index]=row
 end
 self.prepPrev=Button(self.prepPane,80,"<",function()self.prepPage=math.max(1,self.prepPage-1);self:Refresh()end);self.prepPrev:SetPoint("BOTTOMLEFT",10,10)
 self.prepNext=Button(self.prepPane,80,">",function()self.prepPage=math.min(self.prepPages or 1,self.prepPage+1);self:Refresh()end);self.prepNext:SetPoint("BOTTOMRIGHT",-10,10)
 self.prepPosition=Font(self.prepPane,12,GOLD);self.prepPosition:SetPoint("BOTTOM",0,16);self.prepPosition:SetWidth(100);self.prepPosition:SetJustifyH("CENTER")
 self.prepEmpty=Font(self.prepPane,13,GREEN);self.prepEmpty:SetPoint("TOPLEFT",12,-80);self.prepEmpty:SetWidth(500)
 self:CreateSocketPane()
 self.listPane=CreateFrame("Frame",nil,f,"InsetFrameTemplate");self.listPane:SetAllPoints(self.gearPane);self.listScroll,self.listChild=Scroll(self.listPane);self.listPool={}
 self.detailPane=CreateFrame("Frame",nil,f,"InsetFrameTemplate");self.detailPane:SetPoint("TOPLEFT",f,"TOPRIGHT",-359,-101);self.detailPane:SetPoint("BOTTOMRIGHT",-14,68);self.detailScroll,self.detailChild=Scroll(self.detailPane);self.detailPool={}
 self.buttons.EQUIPMENT=Button(f,110,"",function()self:SetView("equipment")end);self.buttons.EQUIPMENT:SetPoint("BOTTOMLEFT",17,15)
 self.buttons.PREPARATION=Button(f,110,"",function()self:SetView("preparation")end);self.buttons.PREPARATION:SetPoint("LEFT",self.buttons.EQUIPMENT,"RIGHT",5,0)
 self.buttons.META=Button(f,80,"",function()self:SetView("meta")end);self.buttons.META:SetPoint("LEFT",self.buttons.PREPARATION,"RIGHT",5,0)
 self.buttons.SOURCES=Button(f,155,"",function()self:SetView("sources")end);self.buttons.SOURCES:SetPoint("BOTTOMRIGHT",-43,15)
 self.buttons.REFRESH=Button(f,125,"",function()R.ScanEquipment();if not InCombatLockdown() then R.ScanRecipes() end;self:Refresh()end);self.buttons.REFRESH:SetPoint("RIGHT",self.buttons.SOURCES,"LEFT",-5,0)
 self.footer=Font(f,11,GREY);self.footer:SetPoint("BOTTOMLEFT",18,43);self.footer:SetHeight(12);self.footer:SetWidth(width-70);self.footer:SetMaxLines(1)
 local resize=CreateFrame("Button",nil,f);resize:SetSize(22,22);resize:SetPoint("BOTTOMRIGHT",-3,3);resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up");resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight");resize:SetScript("OnMouseDown",function()if not InCombatLockdown() then f:StartSizing("BOTTOMRIGHT") end end);resize:SetScript("OnMouseUp",function()f:StopMovingOrSizing()end)
 R.ApplyTheme()
end
function UI:Toggle()
 self:Create();if self.frame:IsShown() then self.frame:Hide() else self.view="equipment";R.ScanEquipment();self.frame:Show();self:Refresh() end
end
function UI:OpenRecommendedItem(item,slotID)
 self:Create();R.SetViewSpec(nil);self:CloseSpecMenus();R.db.mode="mythicplus";R.db.gearSource="mythicplus";R.db.needsOnly=false;self.view="equipment";self.gearView="targets";self.selectedSlot=slotID
 R.ScanEquipment();self.frame:Show();self:Refresh();self:RevealGearSlot(slotID);self:RenderDetail(item,slotID)
end
function UI:ShowSources()self:Create();self.frame:Show();self:SetView("sources")end
function UI:CreateMinimap()
 if self.minimap or not Minimap then return end
 local b=CreateFrame("Button","NexusMinimapButton",Minimap);self.minimap=b;b:SetSize(32,32);b:SetFrameStrata("MEDIUM");b:SetFrameLevel(8);b:RegisterForClicks("LeftButtonUp","RightButtonUp");b:RegisterForDrag("LeftButton")
 local icon=b:CreateTexture(nil,"ARTWORK");icon:SetSize(23,23);icon:SetPoint("CENTER",0,1);icon:SetTexture(R.ASSET_PATH.."nexus-icon.tga")
 local border=b:CreateTexture(nil,"OVERLAY");border:SetSize(54,54);border:SetPoint("TOPLEFT",0,0);border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
 local function position()local a=math.rad(R.db.minimapAngle or 225);local radius=Minimap:GetWidth()/2+8;b:ClearAllPoints();b:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*radius,math.sin(a)*radius)end
 b:SetScript("OnClick",function()self:Toggle()end);b:SetScript("OnEnter",function(o)GameTooltip:SetOwner(o,"ANCHOR_LEFT");GameTooltip:SetText(R.NAME,1,.82,0);GameTooltip:AddLine(R.L("MINIMAP_HINT"),1,1,1,true);GameTooltip:Show()end);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
 b:SetScript("OnDragStart",function(o)GameTooltip:Hide();o:SetScript("OnUpdate",function()local x,y=GetCursorPosition();local cx,cy=Minimap:GetCenter();local scale=Minimap:GetEffectiveScale();R.db.minimapAngle=math.deg(math.atan2(y/scale-cy,x/scale-cx));position()end)end)
 b:SetScript("OnDragStop",function(o)o:SetScript("OnUpdate",nil)end);position()
end
