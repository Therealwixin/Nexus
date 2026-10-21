local _,R=...
local UI=R.UI
local GOLD,WHITE,GREY,GREEN,RED={1,.82,0},{1,1,1},{.65,.65,.65},{.25,1,.25},{1,.28,.22}
local roleKeys={all="META_ALL",dps="META_DPS",healer="META_HEALER",tank="META_TANK"}
local function Font(parent,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");f:SetFont(R.FONT,size,"");f:SetShadowOffset(1,-1);f:SetJustifyH("LEFT");f:SetTextColor(unpack(color or WHITE));return f
end
local function Button(parent,width,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate,BackdropTemplate");b:SetSize(width,25);b:GetFontString():SetFont(R.FONT,12,"");b:SetScript("OnClick",callback);R.SkinButton(b);return b
end
local function Identity(id)
 local spec=R.SpecInfo(id);return spec and spec.name.." "..spec.class.name or "?"
end
local function Metric(record)
 local e=record.entry
 if record.dataset.method=="raid_representation" then return string.format("%.1f%%",e.share),R.L("META_PARSES",e.count) end
 return tostring(e.score),R.L("META_MURLOK_SCORE")
end
function UI:ScrollMeta(offset)
 self.metaOffset=math.max(0,math.min(self.metaRange or 0,offset or 0));self.metaScroll:SetVerticalScroll(self.metaOffset)
end
function UI:CreateMetaPane()
 local pane=CreateFrame("Frame",nil,self.frame,"InsetFrameTemplate");self.metaPane=pane;pane:SetAllPoints(self.gearPane)
 self.metaRole=R.SpecRole(R.ViewSpecID());self.metaRows={};self.metaRoleButtons={}
 local previous
 for _,role in ipairs({"all","dps","healer","tank"}) do
  local key=role;local button=Button(pane,role=="all" and 125 or 95,function()
   self.metaRole=key;self.metaOffset=0;self.metaFollowSpec=R.ViewSpecID();self:Refresh()
  end)
  if previous then button:SetPoint("LEFT",previous,"RIGHT",5,0) else button:SetPoint("TOPLEFT",10,-10) end
  previous=button;self.metaRoleButtons[role]=button
 end
 self.metaSummary=Font(pane,12,GOLD);self.metaSummary:SetPoint("TOPLEFT",12,-45);self.metaSummary:SetHeight(15);self.metaSummary:SetMaxLines(1)
 self.metaHint=Font(pane,10,GREY);self.metaHint:SetPoint("TOPLEFT",12,-65);self.metaHint:SetHeight(12);self.metaHint:SetMaxLines(1)
 self.metaScroll=CreateFrame("ScrollFrame",nil,pane,"UIPanelScrollFrameTemplate");self.metaScroll:SetPoint("TOPLEFT",7,-87);self.metaScroll:SetPoint("BOTTOMRIGHT",-27,9)
 self.metaChild=CreateFrame("Frame",nil,self.metaScroll);self.metaChild:SetSize(300,1);self.metaScroll:SetScrollChild(self.metaChild)
 local function onMouseWheel(_,delta)self:ScrollMeta((self.metaOffset or 0)-delta*62)end
 self.metaScroll:EnableMouseWheel(true);self.metaScroll:SetScript("OnMouseWheel",onMouseWheel)
 self.metaChild:EnableMouseWheel(true);self.metaChild:SetScript("OnMouseWheel",onMouseWheel)
 self.metaScroll:HookScript("OnVerticalScroll",function(_,offset)self.metaOffset=offset end)
 self.metaEmpty=Font(pane,13,GREY);self.metaEmpty:SetPoint("TOPLEFT",14,-100)
 for i=1,40 do
  local row=CreateFrame("Button",nil,self.metaChild,"BackdropTemplate");self.metaRows[i]=row
  row:EnableMouseWheel(true);row:SetScript("OnMouseWheel",onMouseWheel)
  row.rank=Font(row,16,GOLD);row.rank:SetPoint("LEFT",10,0);row.rank:SetWidth(36);row.rank:SetJustifyH("CENTER")
  row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(36,36);row.icon:SetPoint("LEFT",49,0)
  row.name=Font(row,13,WHITE);row.name:SetPoint("TOPLEFT",96,-12);row.name:SetHeight(15);row.name:SetMaxLines(1)
  row.note=Font(row,10,GREY);row.note:SetPoint("TOPLEFT",96,-33);row.note:SetHeight(12);row.note:SetMaxLines(1)
  row.metric=Font(row,15,GOLD);row.metric:SetPoint("TOPRIGHT",-12,-10);row.metric:SetWidth(118);row.metric:SetHeight(18);row.metric:SetJustifyH("RIGHT")
  row.metricLabel=Font(row,10,GREY);row.metricLabel:SetPoint("TOPRIGHT",-12,-33);row.metricLabel:SetWidth(118);row.metricLabel:SetHeight(12);row.metricLabel:SetJustifyH("RIGHT")
  row.check=row:CreateTexture(nil,"OVERLAY");row.check:SetSize(22,22);row.check:SetPoint("BOTTOMRIGHT",row.icon,"BOTTOMRIGHT",6,-4);row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check");row.check:SetVertexColor(.2,1,.2)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  row:SetScript("OnClick",function(owner)if owner.record then self:SelectViewedSpec(owner.record.entry.specID) end end)
  row:SetScript("OnEnter",function(owner)
   local record=owner.record;if not record then return end
   GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(Identity(record.entry.specID))
   GameTooltip:AddLine(R.L("META_ROLE_RANK",record.entry.rank,R.L(roleKeys[record.role])),1,.82,0)
   local metric,label=Metric(record);GameTooltip:AddLine(label..": "..metric,1,1,1)
   GameTooltip:AddLine(record.dataset.source.." · "..R.L("META_COLLECTED")..": "..(record.group.retrievedAt or "?"):sub(1,10),.65,.65,.65)
   GameTooltip:AddLine(R.L("META_SOURCE_DATE")..": "..record.group.updatedAt:sub(1,10),.65,.65,.65)
   GameTooltip:AddLine(R.L("META_SELECT_HINT"),1,1,1,true);GameTooltip:Show()
  end)
  row:SetScript("OnLeave",function()GameTooltip:Hide()end);row:Hide()
 end
 pane:Hide()
end
function UI:RenderMetaDetail(record,why)
 self:DetailClear();self.detailActiveItem,self.detailActiveSlot=nil,nil
 if not record then self:DetailSection(R.L("META"));self:DetailText(R.L(why or "META_UNAVAILABLE"),GREY);self:DetailFinish();return end
 local spec=R.SpecInfo(record.entry.specID)
 self:DetailSection(R.L("META_SELECTED_SPEC"),GOLD)
 self.detailIndex=self.detailIndex+1;local e=self.detailPool[self.detailIndex] or {};self.detailPool[self.detailIndex]=e
 if not e.metaIcon then e.metaIcon=self.detailChild:CreateTexture(nil,"ARTWORK") end
 self:DetailPoint(e.metaIcon);e.metaIcon:SetSize(56,56);R.SetSpecIcon(e.metaIcon,spec);e.metaIcon:Show();self.detailY=self.detailY+66
 self:DetailText(Identity(spec.id),GOLD,15)
 self:DetailText(R.L("META_ROLE_RANK",record.entry.rank,R.L(roleKeys[record.role])),WHITE,13)
 local metric,label=Metric(record);self:DetailText(label..": "..metric,GREEN,14)
 if record.group.sampleSize then self:DetailText(R.L("META_ROLE_SAMPLE",record.group.sampleSize),GREY,11) end
 self:DetailButton(R.L("META_VIEW_GEAR"),function()
  self:SelectViewedSpec(spec.id);self.gearView="targets";self:SetView("equipment")
 end)
 self:DetailSection(R.L("META_METHOD"),GOLD)
 self:DetailText(R.L(record.dataset.method=="raid_representation" and "META_RAID_METHOD" or "META_MPLUS_METHOD"),WHITE,12)
 self:DetailText(R.L("META_ROLES_NOTE"),GREY,11)
 self:DetailSection(R.L("SOURCE"),GOLD)
 self:DetailText(record.dataset.source..(record.dataset.upstream and " · "..record.dataset.upstream or ""),WHITE)
 self:DetailText(record.dataset.scope..(record.dataset.difficulty and " · "..record.dataset.difficulty or ""),GREY,11)
 self:DetailText(R.L("META_COLLECTED")..": "..(record.group.retrievedAt or "?"):sub(1,16):gsub("T"," ").." UTC",WHITE,12)
 self:DetailText("Patch "..R.MetaData.patch.." · "..R.L("META_SOURCE_DATE")..": "..record.group.updatedAt:sub(1,16):gsub("T"," ").." UTC",GREY,11)
  if record.group.refreshStatus=="unavailable" then self:DetailText(R.L("META_REFRESH_FAILED"),RED,11) end
 self:DetailText(R.L("META_DATE_NOTE"),GREY,11)
 local age=R.MetaAge(record.group)
 if age and age>1 then self:DetailText(R.L("STALE"),RED,12) end
 self:DetailButton(record.dataset.source.." · "..R.L("COPY_URL"),function()self:ShowCopy(record.group.sourceURL)end)
 self:DetailFinish()
end
function UI:RenderMeta()
 local data,why=R.GetMetaDataset();local records=R.MetaEntries(nil,self.metaRole)
 self.metaSummary:SetWidth(self.metaPane:GetWidth()-26);self.metaHint:SetWidth(self.metaPane:GetWidth()-26);self.metaEmpty:SetWidth(self.metaPane:GetWidth()-30)
 for role,button in pairs(self.metaRoleButtons) do button:SetText(R.L(roleKeys[role]));button:SetEnabled(role~=self.metaRole) end
 self.metaSummary:SetText((data and data.source.." · "..data.scope..(data.difficulty and " · "..data.difficulty or "") or R.L("META")).." · "..R.L("META_SPEC_COUNT",#records))
 self.metaHint:SetText(R.L(data and data.method=="raid_representation" and "META_RAID_HINT" or "META_MPLUS_HINT"))
  for _,group in pairs(data and data.roles or {}) do if group.refreshStatus=="unavailable" then self.metaHint:SetText(R.L("META_REFRESH_FAILED"));break end end
 self.metaEmpty:SetShown(#records==0);self.metaEmpty:SetText(R.L(why or "META_UNAVAILABLE"))
 local width=self.metaScroll:GetWidth();local height=62
 self.metaChild:SetWidth(width);self.metaChild:SetHeight(math.max(1,#records*height))
 self.metaRange=math.max(0,self.metaChild:GetHeight()-self.metaScroll:GetHeight())
 if self.metaScroll.ScrollBar then self.metaScroll.ScrollBar:SetShown(self.metaRange>1) end
 local selected=R.ViewSpecID();local selectedIndex
 for i,row in ipairs(self.metaRows) do
  local record=records[i];row.record=record;row:SetShown(record~=nil)
  if record then
   local spec=R.SpecInfo(record.entry.specID);local active=record.entry.specID==selected
   row:ClearAllPoints();row:SetPoint("TOPLEFT",self.metaChild,"TOPLEFT",1,-(i-1)*height);row:SetSize(width-3,height-4)
   R.SkinPanel(row,"card",active);R.SetSpecIcon(row.icon,spec);row.check:SetShown(active)
   row.rank:SetText("#"..record.entry.rank);row.name:SetText(Identity(spec.id));row.name:SetWidth(math.max(100,width-240));row.note:SetWidth(math.max(100,width-240))
   local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[spec.class.file] or {};row.name:SetTextColor(color.r or 1,color.g or 1,color.b or 1)
   row.note:SetText(R.L(roleKeys[record.role])..(active and " · "..R.L("META_SELECTED") or ""))
   local metric,label=Metric(record);row.metric:SetText(metric);row.metricLabel:SetText(label)
   if active then selectedIndex=i end
  end
 end
 -- A deliberate Class/Spec choice reveals that spec; filters keep browsing
 -- useful even when the selected spec belongs to a different role.
 if self.metaLastMode~=R.GetMode() then self.metaOffset=0;self.metaLastMode=R.GetMode() end
 if self.metaFollowSpec~=selected then
  self.metaFollowSpec=selected
  if selectedIndex then
   local top=(selectedIndex-1)*height;local bottom=top+height;local offset=self.metaOffset or 0
   if top<offset then self.metaOffset=top elseif bottom>offset+self.metaScroll:GetHeight() then self.metaOffset=bottom-self.metaScroll:GetHeight() end
  end
 end
 self:ScrollMeta(self.metaOffset)
 self:RenderMetaDetail(R.MetaRecord(selected),why)
 self.footer:SetText(data and data.source.." · "..R.L("META_COLLECTED")..": "..R.MetaDate(data,self.metaRole,"retrievedAt").." · "..R.L("META_SOURCE_DATE")..": "..R.MetaDate(data,self.metaRole) or R.L(why or "META_UNAVAILABLE"))
end
