local _,R=...
local UI=R.UI
local GOLD,WHITE,GREY={.86,.73,.45},{.88,.87,.82},{.60,.60,.56}
local function text(parent,size,color)
 local f=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");f:SetFont(R.FONT,size,"");f:SetTextColor(unpack(color or WHITE));f:SetJustifyH("LEFT");f:SetMaxLines(2);return f
end
function UI:CreateStatsPane()
 if self.statsPane then return end
 self.statsPane=CreateFrame("Frame",nil,self.frame);self.statsPane:SetAllPoints(self.gearPane)
 self.statsScroll=CreateFrame("ScrollFrame",nil,self.statsPane,"UIPanelScrollFrameTemplate");self.statsScroll:SetPoint("TOPLEFT",8,-8);self.statsScroll:SetPoint("BOTTOMRIGHT",-27,8)
 self.statsChild=CreateFrame("Frame",nil,self.statsScroll);self.statsScroll:SetScrollChild(self.statsChild)
 self.statRows={};self.statHeaders={}
 for _,key in ipairs({"STAT_NAME","STATS_REFERENCE","STATS_CURRENT","STATS_GAP"}) do self.statHeaders[#self.statHeaders+1]=text(self.statsChild,10,GOLD);self.statHeaders[#self.statHeaders]:SetText(R.L(key)) end
 self.statsSecondary=text(self.statsChild,12,GOLD);self.statsMinor=text(self.statsChild,12,GOLD)
 self.statsPriority=text(self.statsChild,10,GREY)
 for _,key in ipairs(R.STAT_KEYS) do
  local row=CreateFrame("Button",nil,self.statsChild,"BackdropTemplate");self.statRows[key]=row;row.cells={}
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  for i=1,4 do row.cells[i]=text(row,i==1 and 12 or 11) end
  row:SetScript("OnEnter",function(owner)
   GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(R.L("STAT_"..key:upper()))
   for _,line in ipairs(R.StatLines(key,R.ViewSpecID())) do GameTooltip:AddLine(line,.88,.87,.82,true) end
   GameTooltip:Show()
  end)
  row:SetScript("OnLeave",function()GameTooltip:Hide()end)
  row:SetScript("OnClick",function()self.selectedStat=key;self:RenderStats()end)
 end
end
function UI:RenderStatsDetail()
 local spec=R.ViewSpecID();local profile=R.StatProfile(spec);local key=self.selectedStat or "crit"
 self:DetailClear();self.detailActiveItem=nil;self:DetailSection(R.L("STATS"),GOLD)
 self:DetailText(R.L("STATS_REFERENCE_NOTE"),GREY,11)
 if profile then
  self:DetailText(R.L("STATS_SAMPLE",profile.sampleSize),GOLD,11)
  self:DetailText(R.L("STATS_DATED",profile.updatedAt:sub(1,10),profile.retrievedAt:sub(1,10)),GREY,10)
  if profile.refreshStatus=="unavailable" then self:DetailText(R.L("STATS_OLD_PROFILE"),GOLD,11) end
  self:DetailButton("Murlok.io · "..R.L("COPY_URL"),function()self:ShowCopy(profile.sourceURL)end)
 else self:DetailText(R.L("NO_DATA"),GREY) end
 self:DetailSection(R.L("STAT_"..key:upper()),GOLD)
 for _,line in ipairs(R.StatLines(key,spec)) do self:DetailText(line,WHITE,11) end
 if R.Data.statRules then
  self:DetailText("DR · "..R.Data.statRules.build,GREY,10)
  if R.Data.statRules.refreshStatus=="unavailable" then self:DetailText(R.L("STATS_OLD_RULES"),GOLD,11) end
 end
 self:DetailFinish()
end
function UI:RenderStats()
 self:CreateStatsPane();local width=math.max(300,self.statsScroll:GetWidth());self.statsChild:SetWidth(width)
 local columns={0,.27,.53,.79,1};local spec=R.ViewSpecID();local profile=R.StatProfile(spec)
 self.selectedStat=self.selectedStat or profile and profile.secondary.priority[1] or "crit"
 for i,header in ipairs(self.statHeaders) do
  header:ClearAllPoints();header:SetPoint("TOPLEFT",self.statsChild,"TOPLEFT",columns[i]*width+6,-5);header:SetSize((columns[i+1]-columns[i])*width-9,28)
  header:SetText(R.L(({"STAT_NAME","STATS_REFERENCE","STATS_CURRENT","STATS_GAP"})[i]))
 end
 self.statsSecondary:ClearAllPoints();self.statsSecondary:SetPoint("TOPLEFT",6,-38);self.statsSecondary:SetSize(width-12,20);self.statsSecondary:SetText(R.L("STATS_SECONDARY"))
 local priority={}
 for _,key in ipairs(profile and profile.secondary.priority or {}) do priority[#priority+1]=R.L("STAT_"..key:upper()) end
 self.statsPriority:ClearAllPoints();self.statsPriority:SetPoint("TOPLEFT",6,-60);self.statsPriority:SetSize(width-12,28);self.statsPriority:SetText(table.concat(priority," > "))
 self.statsMinor:ClearAllPoints();self.statsMinor:SetPoint("TOPLEFT",6,-303);self.statsMinor:SetSize(width-12,20);self.statsMinor:SetText(R.L("STATS_MINOR"))
 for index,key in ipairs(R.STAT_KEYS) do
  local row=self.statRows[key];local y=index<=4 and 94+(index-1)*50 or 332+(index-5)*50
  row:ClearAllPoints();row:SetPoint("TOPLEFT",self.statsChild,"TOPLEFT",2,-y);row:SetSize(width-4,46);R.SkinPanel(row,"card",self.selectedStat==key)
  for i,cell in ipairs(row.cells) do cell:ClearAllPoints();cell:SetPoint("TOPLEFT",row,"TOPLEFT",columns[i]*width+5,-7);cell:SetSize((columns[i+1]-columns[i])*width-12,34) end
  local s=R.StatSummary(key,spec);local ref,current=s.reference,s.current
  row.cells[1]:SetText(R.L("STAT_"..key:upper()));row.cells[1]:SetTextColor(unpack(WHITE))
  row.cells[2]:SetText(ref and string.format("%.1f%%\n%d %s",ref.percent,ref.rating,R.L("STATS_RATING")) or "--")
  row.cells[3]:SetText(current and (current.percent and string.format("%.1f%%\n",current.percent) or "")..string.format("%.0f %s",current.rating,R.L("STATS_RATING")) or "--")
  row.cells[4]:SetText(s.delta and string.format("%+.0f\n%s",s.delta,R.L("STATS_RATING")) or "--");row.cells[4]:SetTextColor(unpack(s.delta and s.delta~=0 and GOLD or GREY))
 end
 self.statsChild:SetHeight(486);self:RenderStatsDetail()
end
