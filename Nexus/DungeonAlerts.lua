local _,R=...
local A={generation=0,highlights={},page=1};R.DungeonAlerts=A
local function number(value)return R.IsReadable(value) and type(value)=="number" and value>0 end
local function plain(value)return R.IsReadable(value) and type(value)=="string" and value:lower():gsub("[^%w]","") or "" end

function A:IsHighlighted(itemID)return self.highlights[itemID] and true or false end
function A:ClearVisit()
 self.generation=self.generation+1;self.visit=nil;self.entries=nil;self.highlights={};self.pending=nil
 if self.frame then self.frame:Hide() end
 if R.UI then R.UI:Refresh() end
end
function A:Context()
 if not GetInstanceInfo then return nil end
 local ok,name,kind,_,_,_,_,_,gameMapID=pcall(GetInstanceInfo)
 if not ok or not R.IsReadable(kind) or kind~="party" or not number(gameMapID) then return nil end
 return {name=R.IsReadable(name) and name or "",gameMapID=gameMapID}
end
function A:SeasonalMap(context)
 if not (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo) then return nil,false end
 local ok,ids=pcall(C_ChallengeMode.GetMapTable)
 if not ok or not R.IsReadable(ids) or type(ids)~="table" or #ids==0 then return nil,false end
 local pending=false
 for _,challengeMapID in ipairs(ids) do if number(challengeMapID) then
  -- The second return is the challenge ID, not the world instance. Retail's
  -- sixth return is the game map ID, matching GetInstanceInfo's eighth return.
  local good,name,_,_,_,_,gameMapID=pcall(C_ChallengeMode.GetMapUIInfo,challengeMapID)
  if good and number(gameMapID) then
   if gameMapID==context.gameMapID then return challengeMapID,true end
  elseif good and R.IsReadable(name) and type(name)=="string" and name~="" then
   -- Compatibility with clients without the sixth return. Both native names
   -- are localized by the same client; never compare English snapshot names.
   if plain(name)==plain(context.name) and plain(name)~="" then return challengeMapID,true end
   pending=true
  else pending=true end
 end end
 return nil,not pending
end

function A:ReadLoot(context)
 if InCombatLockdown() then return nil end
 if not EJ_SelectInstance and C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn,"Blizzard_EncounterJournal") end
 if not (C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap and C_EncounterJournal.GetLootInfoByIndex and EJ_SelectInstance and EJ_GetNumLoot) then return nil end
 local ok,journalID=pcall(C_EncounterJournal.GetInstanceForGameMap,context.gameMapID)
 if not ok or not number(journalID) then return nil end
 -- Read only this dungeon's pool. Do not open the Adventure Guide or rebuild
 -- every expansion on zoning. Preserve the player's existing native filters.
 local oldInstance=EJ_GetCurrentInstance and EJ_GetCurrentInstance()
 local oldEncounter=EncounterJournal and EncounterJournal.encounterID
 local oldDifficulty=EJ_GetDifficulty and EJ_GetDifficulty()
 local oldClass,oldSpec;if EJ_GetLootFilter then oldClass,oldSpec=EJ_GetLootFilter() end
 local oldSlot=C_EncounterJournal.GetSlotFilter and C_EncounterJournal.GetSlotFilter()
 local good,loot,pending=pcall(function()
  EJ_SelectInstance(journalID)
  if EJ_SetDifficulty then for _,difficulty in ipairs({23,2,1}) do
   if not EJ_IsValidInstanceDifficulty or EJ_IsValidInstanceDifficulty(difficulty) then EJ_SetDifficulty(difficulty);break end
  end end
  if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
  if C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
  local count=EJ_GetNumLoot();if not number(count) then return nil,true end
  local ids={};local waiting=false
  for index=1,count do
   local info=C_EncounterJournal.GetLootInfoByIndex(index)
   if info and R.IsReadable(info) and number(info.itemID) then
    ids[info.itemID]=true
    -- Reuse the one dungeon pool already read for the warning. No extra EJ scan.
    R.SourceCatalog=R.SourceCatalog or {};R.SourceCatalog[info.itemID]={kind="dungeon",source=context.name}
    if number(info.encounterID) then
     R.journalIndex=R.journalIndex or {byItem={}};R.journalIndex.byItem[info.itemID]={instanceID=journalID,encounterID=info.encounterID,isRaid=false,instanceName=context.name}
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
 f.title:SetText(R.L("DUNGEON_WARNING"));f.hint:SetText(R.L("DUNGEON_WARNING_HINT"))
 local shown=0
 for index,b in ipairs(self.rows) do
  local entry=self.entries[(self.page-1)*3+index];b.entry=entry;b:SetShown(entry~=nil)
  if entry then
   shown=shown+1;b.icon:SetTexture(R.ItemIcon(entry.item));b.name:SetText(R.ItemName(entry.item));b.source:SetText(R.L(R.SLOT_BY_ID[entry.slotID].key).." · "..(self.visit.name or ""));R.SkinPanel(b,"card")
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
function A:CheckVisit()
 if not R.db then return end
 local context=self:Context()
 if not context then if self.visit then self:ClearVisit() end;return end
 if not self.visit or self.visit.gameMapID~=context.gameMapID then
  if self.visit then self:ClearVisit() end
  self.generation=self.generation+1;context.attempts=0;context.notified={};self.visit=context;self.highlights={}
 end
 local visit=self.visit;local specID=R.SpecID()
 if visit.notified[specID or 0] or visit.attempts>=12 or self.pending or InCombatLockdown() then return end
 visit.attempts=visit.attempts+1
 local seasonal,ready=self:SeasonalMap(context)
 if not seasonal then if not ready then self:Retry() end;return end
 visit.challengeMapID=seasonal
 if InCombatLockdown() then return end -- PLAYER_REGEN_ENABLED resumes safely.
 local dataset=specID and R.GetDataset("mythicplus",specID);if not dataset then return end
 R.ScanEquipment()
 local loot,pending=self:ReadLoot(context)
 if not loot or pending then self:Retry();return end
 local entries,seen={},{}
 for _,slot in ipairs(R.SLOTS) do
  local item=dataset.slots and dataset.slots[slot.id] and dataset.slots[slot.id][1]
  if item and not item.crafted and loot[item.journalItemID or item.id] and not seen[item.id] and R.Ownership(item.id,slot.id)=="MISSING" then
   entries[#entries+1]={item=item,slotID=slot.id,specID=specID};seen[item.id]=true;R.RequestItem(item.id)
  end
 end
 visit.notified[specID or 0]=true
 if #entries>0 then self:Show(entries) end
end
function A:Check()
 if self.checking then return end
 self.checking=true
 local ok=R.RunBackground("dungeon check",function()self:CheckVisit()end)
 self.checking=false
 if not ok and self.visit then self.visit.attempts=12 end
end
function A:OnEvent(event,argument)
 if event=="PLAYER_SPECIALIZATION_CHANGED" and argument=="player" then
  self.highlights={};self.entries=nil;if self.frame then self.frame:Hide() end
  if self.visit then self.visit.attempts=0 end
 end
 if event=="GET_ITEM_INFO_RECEIVED" then
  if self.frame and self.frame:IsShown() then self:RenderBanner() end
 else self:Check() end
end
