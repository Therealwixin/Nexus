local _,R=...
local A={generation=0,highlights={},page=1};R.DungeonAlerts=A
local function number(value)return R.IsReadable(value) and type(value)=="number" and value>0 end

function A:IsHighlighted(itemID)return self.highlights[itemID] and true or false end
function A:ClearVisit()
 self.generation=self.generation+1;self.visit=nil;self.entries=nil;self.highlights={};self.pending=nil
 if self.frame then self.frame:Hide() end
 if R.UI then R.UI:Refresh() end
end
function A:Context()
 if not GetInstanceInfo then return nil end
 local ok,name,kind,difficultyID,_,_,_,_,gameMapID=pcall(GetInstanceInfo)
 if not ok or not R.IsReadable(kind) or (kind~="party" and kind~="raid") or not number(gameMapID) then return nil end
 return {name=R.IsReadable(name) and name or "",gameMapID=gameMapID,kind=kind,difficultyID=number(difficultyID) and difficultyID or nil}
end
function A:ReadLoot(context)
 if InCombatLockdown() then return nil end
 if not EJ_SelectInstance and C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn,"Blizzard_EncounterJournal") end
 if not (C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap and C_EncounterJournal.GetLootInfoByIndex and EJ_SelectInstance and EJ_GetNumLoot) then return nil end
 local ok,journalID=pcall(C_EncounterJournal.GetInstanceForGameMap,context.gameMapID)
 if not ok or not number(journalID) then return nil end
 -- Read only this instance's pool. Do not open the Adventure Guide or rebuild
 -- every expansion on zoning. Preserve the player's existing native filters.
 local oldInstance=EJ_GetCurrentInstance and EJ_GetCurrentInstance()
 local oldEncounter=EncounterJournal and EncounterJournal.encounterID
 local oldDifficulty=EJ_GetDifficulty and EJ_GetDifficulty()
 local oldClass,oldSpec;if EJ_GetLootFilter then oldClass,oldSpec=EJ_GetLootFilter() end
 local oldSlot=C_EncounterJournal.GetSlotFilter and C_EncounterJournal.GetSlotFilter()
 local good,loot,pending=pcall(function()
  EJ_SelectInstance(journalID)
  if EJ_SetDifficulty then for _,difficulty in ipairs(context.kind=="raid" and {context.difficultyID or 16,16,15,14,17} or {context.difficultyID or 23,23,2,1}) do
   if not EJ_IsValidInstanceDifficulty or EJ_IsValidInstanceDifficulty(difficulty) then EJ_SetDifficulty(difficulty);break end
  end end
  if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
  if C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
  local count=EJ_GetNumLoot();if not number(count) then return nil,true end
  local ids={};local waiting=false
  for index=1,count do
   local info=C_EncounterJournal.GetLootInfoByIndex(index)
   if info and R.IsReadable(info) and number(info.itemID) then
    ids[info.itemID]={link=R.IsReadable(info.link) and info.link or nil}
    -- Reuse the one instance pool already read for the warning. No extra EJ scan.
    R.SourceCatalog=R.SourceCatalog or {};R.SourceCatalog[info.itemID]={kind=context.kind=="raid" and "raid" or "dungeon",source=context.name}
    if number(info.encounterID) then
     R.journalIndex=R.journalIndex or {byItem={}};R.journalIndex.byItem[info.itemID]={instanceID=journalID,encounterID=info.encounterID,isRaid=context.kind=="raid",instanceName=context.name}
    end
   else waiting=true end
  end
  return ids,waiting
 end)
 if number(oldInstance) then EJ_SelectInstance(oldInstance) end
 if number(oldInstance) and number(oldEncounter) and EJ_SelectEncounter then EJ_SelectEncounter(oldEncounter) end
 if R.IsReadable(oldDifficulty) and oldDifficulty and EJ_SetDifficulty then EJ_SetDifficulty(oldDifficulty) end
 if R.IsReadable(oldClass) and oldClass and EJ_SetLootFilter then EJ_SetLootFilter(oldClass,oldSpec or 0) end
 if R.IsReadable(oldSlot) and oldSlot and C_EncounterJournal.SetSlotFilter then C_EncounterJournal.SetSlotFilter(oldSlot) end
 if not good then return nil end
 return loot,pending
end

local function font(parent,size,color)
 local text=parent:CreateFontString(nil,"OVERLAY","GameFontNormal");text:SetFont(R.FONT,size,"");text:SetShadowOffset(1,-1);text:SetTextColor(unpack(color));return text
end
function A:Create()
 if self.frame then return end
 local f=CreateFrame("Frame","NexusDungeonWarning",UIParent,"BackdropTemplate");self.frame=f
 f:SetWidth(490);f:SetPoint("TOP",UIParent,"TOP",0,-115);f:SetFrameStrata("DIALOG");f:SetFrameLevel(800);f:SetClampedToScreen(true)
 f.title=font(f,16,{1,.77,.25});f.title:SetPoint("TOPLEFT",17,-14);f.title:SetWidth(415);f.title:SetHeight(20);f.title:SetJustifyH("LEFT")
 f.hint=font(f,11,{.9,.86,.75});f.hint:SetPoint("TOPLEFT",17,-38);f.hint:SetWidth(450);f.hint:SetHeight(14);f.hint:SetJustifyH("LEFT")
 f.close=CreateFrame("Button",nil,f,"UIPanelButtonTemplate,BackdropTemplate");f.close:SetSize(22,22);f.close:SetPoint("TOPRIGHT",-10,-10);f.close:SetText("X");f.close:GetFontString():SetFont(R.FONT,14,"");R.SkinButton(f.close)
 f.close:SetScript("OnClick",function()GameTooltip:Hide();f:Hide()end)
 f.close:SetScript("OnEnter",function(owner)GameTooltip:SetOwner(owner,"ANCHOR_RIGHT");GameTooltip:SetText(R.L("CLOSE"));GameTooltip:Show()end)
 f.close:SetScript("OnLeave",function()GameTooltip:Hide()end)
 self.rows={}
 for index=1,3 do
  local b=CreateFrame("Button",nil,f,"BackdropTemplate");self.rows[index]=b;b:SetSize(458,48);b:SetPoint("TOPLEFT",16,-60-(index-1)*54)
  b.icon=b:CreateTexture(nil,"ARTWORK");b.icon:SetSize(32,32);b.icon:SetPoint("LEFT",9,0);b.icon:SetTexCoord(.07,.93,.07,.93)
  b.name=font(b,12,{1,1,1});b.name:SetPoint("TOPLEFT",50,-8);b.name:SetSize(397,15);b.name:SetMaxLines(1);b.name:SetJustifyH("LEFT")
  b.source=font(b,10,{.85,.77,.6});b.source:SetPoint("BOTTOMLEFT",50,7);b.source:SetSize(397,12);b.source:SetMaxLines(1);b.source:SetJustifyH("LEFT")
  b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  b:SetScript("OnEnter",function(owner)if owner.entry then R.UI:ShowItemTooltip(owner,owner.entry.item,owner.entry.slotID,false,owner.entry.specID,"mythicplus") end end)
  b:SetScript("OnLeave",function()GameTooltip:Hide()end)
  b:SetScript("OnClick",function(owner)if owner.entry then self:OpenItem(owner.entry) end end)
 end
 f.prev=CreateFrame("Button",nil,f,"UIPanelButtonTemplate,BackdropTemplate");f.prev:SetSize(28,22);f.prev:SetText("<");f.prev:GetFontString():SetFont(R.FONT,12,"");f.prev:SetPoint("BOTTOMLEFT",17,10);R.SkinButton(f.prev)
 f.next=CreateFrame("Button",nil,f,"UIPanelButtonTemplate,BackdropTemplate");f.next:SetSize(28,22);f.next:SetText(">");f.next:GetFontString():SetFont(R.FONT,12,"");f.next:SetPoint("BOTTOMRIGHT",-17,10);R.SkinButton(f.next)
 f.position=font(f,11,{1,.82,0});f.position:SetPoint("BOTTOM",0,15);f.position:SetSize(150,12);f.position:SetJustifyH("CENTER")
 f.prev:SetScript("OnClick",function()self.page=math.max(1,self.page-1);self:RenderBanner()end)
 f.next:SetScript("OnClick",function()self.page=math.min(self.pages,self.page+1);self:RenderBanner()end)
 -- A timer on the visible banner avoids queued hide callbacks accidentally
 -- closing a newer dungeon visit. Hovering pauses the timeout.
 f:SetScript("OnUpdate",function(_,elapsed)
  if not f:IsMouseOver() then self.remaining=(self.remaining or 25)-elapsed end
  if self.remaining<=0 then f:Hide() end
 end)
 f:Hide()
end
function A:RenderBanner()
 local f=self.frame;local count=#(self.entries or {});self.pages=math.max(1,math.ceil(count/3));self.page=math.min(self.page,self.pages)
 f.title:SetText(R.L(self.visit and self.visit.kind=="raid" and "RAID_DROP_WARNING" or "DUNGEON_WARNING"));f.hint:SetText(R.L("DUNGEON_WARNING_HINT"))
 local shown=0
 for index,b in ipairs(self.rows) do
  local entry=self.entries[(self.page-1)*3+index];b.entry=entry;b:SetShown(entry~=nil)
  if entry then
   local kind=entry.alternative and "INSTANCE_ALTERNATIVE" or entry.item.acquisitionItemID and "DUNGEON_BIS_CATALYST" or "DUNGEON_BIS_ITEM"
   shown=shown+1;b.icon:SetTexture(R.ItemIcon(entry.item));b.name:SetText(R.ItemName(entry.item));b.source:SetText(R.L(kind).." · "..R.L(R.SLOT_BY_ID[entry.slotID].key).." · "..(self.visit.name or ""));R.SkinPanel(b,"card")
  end
 end
 local paged=self.pages>1;f:SetHeight(60+shown*54+(paged and 38 or 12));R.SkinPanel(f,"detail")
 f.prev:SetShown(paged);f.next:SetShown(paged);f.position:SetShown(paged);f.prev:SetEnabled(self.page>1);f.next:SetEnabled(self.page<self.pages);f.position:SetText(self.page.." / "..self.pages)
end
function A:Show(entries)
 self.entries=entries;self.page=1;self:Create();self:RenderBanner();self.remaining=25;self.frame:Show()
end
function A:OpenItem(entry)
 if not self.visit or not entry then return end
 local context=self:Context()
 if not context or context.gameMapID~=self.visit.gameMapID then self:ClearVisit();return end
 if entry.specID~=R.SpecID() then self:Check();return end
 self.highlights[entry.item.id]=true;GameTooltip:Hide();self.frame:Hide();R.UI:OpenRecommendedItem(entry.item,entry.slotID)
end
function A:Retry()
 if self.pending or not self.visit or self.visit.attempts>=12 then return end
 self.pending=true;local generation=self.generation
 C_Timer.After(1,function()
  if generation~=self.generation then return end
  self.pending=nil;self:Check()
 end)
end
-- Always resolve the current bundled primary and the same alternatives shown in
-- Equipment. No separate per-instance recommendation lists can become stale.
function A:CollectEntries(loot,specID)
 local entries,seen={},{}
 local function owned(item,slot)
  local state=R.GearOwnership(item,slot,specID);return state=="EQUIPPED" or state=="IN_BAGS" or state=="OWNED"
 end
 local function higherEquipped(item,slotID,drop)
  local targetTrack=R.RecommendationUpgradeTrack(item,slotID)
  local range=R.GearLevelRange(item,slotID)
  local ceiling=range and (range.ascended or range.max)
  if type(drop)=="table" and drop.link then
   local native=R.ItemLevel({link=drop.link},true)
   if native then ceiling=math.max(ceiling or 0,native) end
  end
  if not ceiling then return false end -- Do not invent a comparison.
  local slots=R.PAIRS[slotID] or {slotID}
  for _,slot in ipairs(slots) do
   local current=R.scan and R.scan.equipped[slot]
   local level=current and R.ItemLevel(current,true)
   -- For paired slots the candidate can replace the weaker item.
   local primary=R.GetGearTarget(slot,specID,"mplus_usage")
   local track=R.UpgradeTrackInfo(current)
   local trackSatisfied=track and targetTrack and track.maximum>=targetTrack.maximum
   local primaryAtLevel=R.PrimaryCopySatisfied(primary,current,slot,specID)
   if not (trackSatisfied or primaryAtLevel or level and level>ceiling) then return false end
  end
  return true
 end
 for pass=1,2 do for _,slot in ipairs(R.SLOTS) do
  local main=R.GetGearTarget(slot.id,specID,"mplus_usage")
  local function add(item,alternative)
   if not item then return end
   local dropID=item.acquisitionItemID or item.journalItemID or item.id
   if item.crafted or not loot[dropID] or seen[dropID] or owned(item,slot.id) or
    (dropID~=item.id and R.Ownership(dropID,slot.id)~="MISSING") then return end
   if alternative then
    if higherEquipped(item,slot.id,loot[dropID]) then return end
   end
   entries[#entries+1]={item=item,slotID=slot.id,specID=specID,alternative=alternative or nil,dropID=dropID}
   seen[dropID]=true;R.RequestItem(item.id)
  end
  if pass==1 then add(main,false)
  else for _,item in ipairs(R.GetGearAlternatives(slot.id,specID)) do add(item,true) end end
 end end
 -- A duplicate paired-slot alternative must never hide a primary label.
 table.sort(entries,function(a,b)if a.alternative~=b.alternative then return not a.alternative end;if a.slotID~=b.slotID then return a.slotID<b.slotID end;return a.dropID<b.dropID end)
 return entries
end
function A:CheckVisit()
 if not R.db then return end
 local context=self:Context()
 if not context then if self.visit then self:ClearVisit() end;return end
 if not self.visit or self.visit.gameMapID~=context.gameMapID or self.visit.difficultyID~=context.difficultyID or self.visit.kind~=context.kind then
  if self.visit then self:ClearVisit() end
  self.generation=self.generation+1;context.attempts=0;context.notified={};self.visit=context;self.highlights={}
 end
 local visit=self.visit;local specID=R.SpecID()
 local data=specID and R.GetDataset("mythicplus",specID)
 local revision=tostring(R.VERSION)..":"..tostring(data and data.retrievedAt)..":"..tostring(R.GuideData and R.GuideData.generatedAt)
 if visit.revision~=revision then visit.revision=revision;visit.notified={};visit.attempts=0 end
 if visit.notified[specID or 0] or visit.attempts>=12 or self.pending or InCombatLockdown() then return end
 visit.attempts=visit.attempts+1
 if InCombatLockdown() then return end -- PLAYER_REGEN_ENABLED resumes safely.
 if not data or not specID then self:Retry();return end
 R.ScanEquipment()
 local loot,pending=visit.loot,false
 if not loot then loot,pending=self:ReadLoot(context) end
 if not loot or pending then self:Retry();return end
 visit.loot=loot
 local entries=self:CollectEntries(loot,specID)
 visit.notified[specID or 0]=true
 local keys={}
 for _,entry in ipairs(entries) do keys[#keys+1]=entry.dropID..":"..tostring(entry.alternative)..":"..entry.slotID end
 local signature=tostring(specID)..":"..table.concat(keys,"|")
 if visit.signature~=signature then
  visit.signature=signature
  if #entries>0 then self:Show(entries) elseif self.frame then self.frame:Hide();self.entries={} end
 end
end
function A:Check()
 if self.checking then return end
 self.checking=true
 local ok=R.RunBackground("dungeon check",function()self:CheckVisit()end)
 self.checking=false
 if not ok and self.visit then self.visit.attempts=12 end
end
function A:OnEvent(event,argument)
 if self.visit and (event=="PLAYER_EQUIPMENT_CHANGED" or event=="BAG_UPDATE_DELAYED") then self.visit.notified={};self.visit.attempts=0 end
 if event=="PLAYER_SPECIALIZATION_CHANGED" and argument=="player" then
  self.highlights={};self.entries=nil;if self.frame then self.frame:Hide() end
  if self.visit then self.visit.attempts=0;self.visit.notified={};self.visit.signature=nil end
 end
 if event=="GET_ITEM_INFO_RECEIVED" then
  if self.frame and self.frame:IsShown() then self:RenderBanner() end
 else self:Check() end
end
