local _,R=...
local UI=R.UI
local function button(parent,width,text,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate,BackdropTemplate");b:SetSize(width,25);b:SetText(text or "");b:GetFontString():SetFont(R.FONT,12,"");b:SetScript("OnClick",callback);R.SkinButton(b);return b
end
local function font(parent,size)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");f:SetFont(R.FONT,size,"");f:SetShadowOffset(1,-1);f:SetTextColor(1,.82,0);f:SetJustifyH("LEFT");return f
end
local function hint(owner,title,message)
 GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(title);GameTooltip:AddLine(message,1,1,1,true);GameTooltip:Show()
end
function UI:CloseSpecMenus()
 for _,menu in pairs(self.specMenus or {}) do menu:Hide() end
end
function UI:ResetSpecViewState()
 self.selectedSlot=1;self.prepPage=1;self.socketSlotID=nil;self.gearOffset=0
end
function UI:SelectViewedSpec(specID)
 if not R.SetViewSpec(specID) then return false end
 self:CloseSpecMenus();self:ResetSpecViewState();self.gearView="targets";R.db.needsOnly=false
 if self.view=="sources" then self.view="equipment" end
 if self.view=="meta" and self.metaRole~="all" and self.metaRole~=R.SpecRole(R.ViewSpecID()) then self.metaRole=R.SpecRole(R.ViewSpecID());self.metaOffset=0 end
 GameTooltip:Hide();self:Refresh();return true
end
function UI:CreateSpecControls(parent)
 local class=button(parent,150,"",function()self:ToggleSpecMenu("class")end);class:SetPoint("TOPLEFT",65,-34);self.classPicker=class
 local spec=button(parent,185,"",function()self:ToggleSpecMenu("spec")end);spec:SetPoint("LEFT",class,"RIGHT",5,0);self.specPicker=spec
 self.mySpec=button(parent,82,"",function()self:SelectViewedSpec(nil)end);self.mySpec:SetPoint("LEFT",spec,"RIGHT",5,0)
 for index,b in ipairs({class,spec}) do
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(19,19);b.icon:SetPoint("LEFT",5,0)
  b.arrow=b:CreateTexture(nil,"ARTWORK");b.arrow:SetSize(12,12);b.arrow:SetPoint("RIGHT",-5,0);b.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
  local text=b:GetFontString();text:ClearAllPoints();text:SetPoint("LEFT",28,0);text:SetWidth(b:GetWidth()-47);text:SetHeight(15);text:SetJustifyH("LEFT");text:SetMaxLines(1)
  b.label=font(parent,9);b.label:SetPoint("BOTTOMLEFT",b,"TOPLEFT",2,0);b.label:SetWidth(b:GetWidth());b.label:SetHeight(10)
  local key=index==1 and "SELECT_CLASS" or "SELECT_SPEC"
  b:SetScript("OnEnter",function(owner)hint(owner,R.L(key),R.L("SPEC_PICKER_HINT"))end);b:SetScript("OnLeave",function()GameTooltip:Hide()end)
 end
 self.mySpec:SetScript("OnEnter",function(owner)hint(owner,R.L("MY_SPEC"),R.L("MY_SPEC_HINT"))end);self.mySpec:SetScript("OnLeave",function()GameTooltip:Hide()end)
 self.specMenus={}
 for _,kind in ipairs({"class","spec"}) do
  local anchor=kind=="class" and class or spec
  local menu=CreateFrame("Frame",kind=="class" and "NexusClassPickerMenu" or "NexusSpecPickerMenu",parent,"BackdropTemplate");self.specMenus[kind]=menu
  menu:SetWidth(kind=="class" and 210 or 245);menu:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-3);menu:SetFrameStrata("DIALOG");menu:SetFrameLevel(500);menu:SetClampedToScreen(true);menu.rows={}
  menu:SetScript("OnUpdate",function(owner)
   if IsMouseButtonDown and IsMouseButtonDown("LeftButton") and not owner:IsMouseOver() and not anchor:IsMouseOver() then owner:Hide() end
  end)
  local rowCount=#R.SpecCatalog().classes
  if kind=="spec" then rowCount=0;for _,entry in ipairs(R.SpecCatalog().classes) do rowCount=math.max(rowCount,#entry.specs) end end
  for index=1,rowCount do
   local b=CreateFrame("Button",nil,menu);b:SetSize(menu:GetWidth()-14,29);b:SetPoint("TOPLEFT",7,-7-(index-1)*31)
   b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(21,21);b.icon:SetPoint("LEFT",4,0)
   b.text=font(b,12);b.text:SetPoint("LEFT",33,0);b.text:SetSize(b:GetWidth()-60,15);b.text:SetMaxLines(1)
   b.selected=b:CreateTexture(nil,"BACKGROUND");b.selected:SetAllPoints();b.selected:SetColorTexture(.3,.6,.2,.20)
   b.check=b:CreateTexture(nil,"OVERLAY");b.check:SetSize(20,20);b.check:SetPoint("RIGHT",-3,0);b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");b.check:SetVertexColor(.2,1,.2)
   b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");menu.rows[index]=b
  end
  menu:Hide()
 end
end
function UI:RefreshSpecControls()
 local viewed=R.SpecInfo(R.ViewSpecID());local class=viewed and viewed.class or R.SpecCatalog().byClass[R.CurrentClassID()]
 self.classPicker:SetText(class and class.name or R.L("SELECT_CLASS"));self.specPicker:SetText(viewed and viewed.name or R.L("SELECT_SPEC"));self.specPicker:SetEnabled(viewed~=nil)
 R.SetClassIcon(self.classPicker.icon,class);R.SetSpecIcon(self.specPicker.icon,viewed)
 self.classPicker.label:SetText(R.L("SELECT_CLASS"));self.specPicker.label:SetText(R.L("SELECT_SPEC"));self.mySpec:SetText(R.L("MY_SPEC"));self.mySpec:SetEnabled(R.character.viewSpecID~=nil)
 local active=R.SpecInfo(R.SpecID());self.characterName:SetWidth(self.frame:GetWidth()-70)
 self.characterName:SetText(R.L("CURRENT_CHARACTER",UnitName("player") or "")..(active and " · "..active.class.name.." · "..active.name or ""))
 for kind,menu in pairs(self.specMenus) do if menu:IsShown() then self:RenderSpecMenu(kind) end end
end
function UI:RenderSpecMenu(kind)
 local menu=self.specMenus[kind];local viewed=R.SpecInfo(R.ViewSpecID());local class=viewed and viewed.class or R.SpecCatalog().byClass[R.CurrentClassID()]
 local entries=kind=="class" and R.SpecCatalog().classes or class and class.specs or {};local count=#entries
 menu:SetHeight(12+count*31);R.SkinPanel(menu,"detail")
 for index,b in ipairs(menu.rows) do
  local entry=entries[index];b:SetShown(entry~=nil)
  if entry then
   b.entry=entry;b.text:SetText(entry.name)
   local selected=kind=="class" and class and class.id==entry.id or kind=="spec" and viewed and viewed.id==entry.id
   b.selected:SetShown(selected);b.check:SetShown(selected)
   if kind=="class" then
    R.SetClassIcon(b.icon,entry);local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.file]
    if color then b.text:SetTextColor(color.r,color.g,color.b) else b.text:SetTextColor(1,.82,0) end
   else R.SetSpecIcon(b.icon,entry);b.text:SetTextColor(1,1,1) end
   local id=entry.id;b:SetScript("OnClick",function()self:SelectViewedSpec(kind=="class" and R.ClassDefaultSpec(id) or id)end)
  end
 end
end
function UI:ToggleSpecMenu(kind)
 local menu=self.specMenus[kind];local was=menu:IsShown();self:CloseSpecMenus();GameTooltip:Hide()
 if not was then self:RenderSpecMenu(kind);menu:Show() end
end
