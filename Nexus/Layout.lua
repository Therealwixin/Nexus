local _,R=...
local UI=R.UI
local GOLD={.86,.73,.45}
local WHITE={.88,.87,.82}
local MUTED={.57,.58,.56}
local AMBER={.89,.65,.31}
local GREEN={.49,.72,.48}
local function label(parent,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
 f:SetFont(R.FONT,size,"");f:SetShadowOffset(1,-1);f:SetTextColor(unpack(color or WHITE));f:SetJustifyH("LEFT");f:SetMaxLines(1)
 return f
end
local function place(frame,point,parent,relative,x,y)
 frame:ClearAllPoints();frame:SetPoint(point,parent,relative,x,y)
end

function UI:Layout()
 local f=self.frame;if not f or not self.detailPane then return end
 if not self.sectionTitle then
  self.sectionTitle=label(f,16,GOLD);self.sectionTitle:SetHeight(20)
  self.gearHeaders={slot=label(self.gearChild,10,MUTED),item=label(self.gearChild,10,MUTED),state=label(self.gearChild,10,MUTED)}
 end
 if f.PortraitContainer then f.PortraitContainer:Hide() end
 place(f.Inset,"TOPLEFT",f,"TOPLEFT",8,-151);f.Inset:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-8,47)
 place(self.buttons.EQUIPMENT,"TOPLEFT",f,"TOPLEFT",22,-39);self.buttons.EQUIPMENT:SetSize(130,28)
 place(self.buttons.PREPARATION,"LEFT",self.buttons.EQUIPMENT,"RIGHT",4,0);self.buttons.PREPARATION:SetSize(140,28)
 place(self.buttons.META,"LEFT",self.buttons.PREPARATION,"RIGHT",4,0);self.buttons.META:SetSize(90,28)
 place(self.buttons.SOURCES,"TOPRIGHT",f,"TOPRIGHT",-22,-39);self.buttons.SOURCES:SetSize(180,28)
 place(self.classPicker,"TOPLEFT",f,"TOPLEFT",22,-83);self.classPicker:SetSize(140,25)
 place(self.specPicker,"LEFT",self.classPicker,"RIGHT",6,0);self.specPicker:SetSize(170,25)
 place(self.mySpec,"LEFT",self.specPicker,"RIGHT",6,0);self.mySpec:SetSize(90,25)
 place(self.buttons.MYTHICPLUS,"TOPRIGHT",f,"TOPRIGHT",-130,-83);self.buttons.MYTHICPLUS:SetSize(110,25)
 place(self.buttons.RAID,"LEFT",self.buttons.MYTHICPLUS,"RIGHT",6,0);self.buttons.RAID:SetSize(102,25)
 place(self.sectionTitle,"TOPLEFT",f,"TOPLEFT",22,-122);self.sectionTitle:SetWidth(150)
 place(self.buttons.MY_GEAR,"TOPLEFT",f,"TOPLEFT",181,-119);self.buttons.MY_GEAR:SetSize(100,24)
 place(self.buttons.TARGETS,"LEFT",self.buttons.MY_GEAR,"RIGHT",5,0);self.buttons.TARGETS:SetSize(130,24)
 place(self.needs,"LEFT",self.buttons.TARGETS,"RIGHT",10,0);self.needsLabel:SetWidth(170)
 place(self.gearPane,"TOPLEFT",f,"TOPLEFT",18,-158);self.gearPane:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-344,53)
 place(self.detailPane,"TOPLEFT",f,"TOPRIGHT",-328,-158);self.detailPane:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-18,53)
 place(self.buttons.REFRESH,"BOTTOMRIGHT",f,"BOTTOMRIGHT",-24,15);self.buttons.REFRESH:SetSize(140,24)
 place(self.footer,"BOTTOMLEFT",f,"BOTTOMLEFT",22,18);self.footer:SetWidth(f:GetWidth()-200);self.footer:SetHeight(14)
 self.characterName:Hide();self.themeButton:Hide()
 for index,b in ipairs(self.languageButtons) do place(b,"TOPLEFT",f,"TOPLEFT",181+(index-1)*38,-119) end
end

function UI:RenderRows()
 self.gearScroll:ClearAllPoints();self.gearScroll:SetPoint("TOPLEFT",self.gearPane,"TOPLEFT",0,0);self.gearScroll:SetPoint("BOTTOMRIGHT",self.gearPane,"BOTTOMRIGHT",-24,0)
 local width=self.gearScroll:GetWidth();local visible={};local owned,total=0,0
 for index,slot in ipairs(R.SLOTS) do
  local item=self:GetShownItem(slot.id);local state=item and R.Ownership(item.id,slot.id) or "EMPTY"
  if item then total=total+1;if state~="MISSING" then owned=owned+1 end end
  if not R.db.needsOnly or self.gearView=="mine" or state=="MISSING" then visible[#visible+1]={index=index,slot=slot,item=item,state=state} end
  self.rows[index]:Hide()
 end
 local selectedVisible=false
 for _,entry in ipairs(visible) do if entry.slot.id==self.selectedSlot then selectedVisible=true end end
 if not selectedVisible and visible[1] then self.selectedSlot=visible[1].slot.id end
 local headers=self.gearHeaders
 place(headers.slot,"TOPLEFT",self.gearChild,"TOPLEFT",12,-10);headers.slot:SetWidth(108);headers.slot:SetHeight(14);headers.slot:SetText(R.L("GEAR_SLOT"))
 place(headers.item,"TOPLEFT",self.gearChild,"TOPLEFT",164,-10);headers.item:SetWidth(width-330);headers.item:SetHeight(14);headers.item:SetText(R.L("GEAR_ITEM"))
 place(headers.state,"TOPRIGHT",self.gearChild,"TOPRIGHT",-12,-10);headers.state:SetWidth(132);headers.state:SetHeight(14);headers.state:SetJustifyH("RIGHT");headers.state:SetText(R.L("GEAR_STATE"))
 for position,entry in ipairs(visible) do
  local b=self.rows[entry.index];local item,slot=entry.item,entry.slot;local selected=self.selectedSlot==slot.id
  b.gridTop=32+(position-1)*52;place(b,"TOPLEFT",self.gearChild,"TOPLEFT",2,-b.gridTop);b:SetSize(width-4,50)
  self:BindItem(b,item,slot.id,self.gearView=="mine",true)
  place(b.icon,"LEFT",b,"LEFT",124,0);b.icon:SetSize(32,32)
  place(b.text,"LEFT",b,"LEFT",12,0);b.text:SetSize(104,16);b.text:SetFont(R.FONT,11,"");b.text:SetTextColor(unpack(MUTED));b.text:SetText(R.L(slot.key))
  place(b.note,"LEFT",b,"LEFT",164,0);b.note:SetSize(math.max(110,width-324),18);b.note:SetFont(R.FONT,13,"");b.note:SetTextColor(unpack(item and WHITE or MUTED));b.note:SetText(item and R.ItemName(item) or R.L("EMPTY"))
  place(b.ownership,"RIGHT",b,"RIGHT",-12,0);b.ownership:SetSize(132,16);b.ownership:SetJustifyH("RIGHT");b.ownership:SetFont(R.FONT,11,"");b.ownership:SetText(item and R.L(entry.state) or "")
  b.ownership:SetTextColor(unpack(entry.state=="MISSING" and AMBER or GREEN))
  b.red:Hide();b.icon:SetVertexColor(1,1,1);b.selected:Hide();b.check:Hide()
  local here=R.ViewSpecID()==R.SpecID() and item and R.DungeonAlerts:IsHighlighted(item.id)
  b._stripe=position%2==0;R.SkinPanel(b,here and "dungeon" or "row",selected)
  b:SetScript("OnClick",function(owner)self.selectedSlot=owner.slotID;self:RenderRows();self:RenderDetail()end)
  b:Show();if item then R.RequestItem(item.id) end
 end
 self.gearChild:SetWidth(width);self.gearChild:SetHeight(math.max(32,32+#visible*52))
 self.gearRange=math.max(0,self.gearChild:GetHeight()-self.gearScroll:GetHeight())
 if self.gearScroll.ScrollBar then self.gearScroll.ScrollBar:SetShown(self.gearRange>1) end
 self:ScrollGear(self.gearOffset)
 local dataset,why=R.GetDataset()
 local unavailable=self.gearView=="targets" and not dataset
 self.noData:SetShown(#visible==0 or unavailable);self.noData:SetWidth(width-16);self.noData:SetText(R.L(unavailable and (why or "NO_SNAPSHOT") or "GEAR_NOTHING_MISSING"))
end

local previousPreparation=UI.RenderPreparation
function UI:RenderPreparation()
 previousPreparation(self)
 local width=self.prepPane:GetWidth();local height=math.max(60,(self.prepPane:GetHeight()-118)/6)
 for index,row in ipairs(self.prepRows) do if row:IsShown() then
  place(row,"TOPLEFT",self.prepPane,"TOPLEFT",8,-70-(index-1)*height);row:SetSize(width-16,height-3)
  place(row.icon,"LEFT",row,"LEFT",10,0);row.icon:SetSize(32,32);row.icon:SetVertexColor(1,1,1);row.red:Hide();row.check:Hide()
  place(row.text,"TOPLEFT",row,"TOPLEFT",54,-9);row.text:SetSize(width-236,14);row.text:SetFont(R.FONT,11,"");row.text:SetTextColor(unpack(MUTED))
  place(row.note,"TOPLEFT",row,"TOPLEFT",54,-28);row.note:SetSize(width-236,18);row.note:SetFont(R.FONT,13,"");row.note:SetTextColor(unpack(WHITE));row.note:SetMaxLines(1)
  place(row.status,"RIGHT",row,"RIGHT",-12,0);row.status:SetSize(136,30);row.status:SetJustifyH("RIGHT");row.status:SetMaxLines(2)
  row._stripe=index%2==0;R.SkinPanel(row,"row")
 end end
end

local previousRefresh=UI.Refresh
function UI:Refresh()
 if not self.frame or not self.frame:IsShown() then return end
 self:Layout();previousRefresh(self)
 self.title:SetText(R.NAME);self.themeButton:Hide();self.characterName:Hide()
 self.sectionTitle:SetText(R.L(self.view=="equipment" and "EQUIPMENT" or self.view=="preparation" and "PREPARATION" or self.view=="meta" and "META" or "DATA_SETTINGS"))
 self.buttons.SOURCES:SetText(R.L("DATA_UPDATES"))
 for key,view in pairs({EQUIPMENT="equipment",PREPARATION="preparation",META="meta",SOURCES="sources"}) do R.StyleNavigation(self.buttons[key],self.view==view) end
 self.footer:SetText(R.VERSION.." · "..R.DataStatus(R.GetDataset()))
end
