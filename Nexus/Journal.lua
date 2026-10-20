local _,R=...
-- Verified WCL worldData dungeonEncounter IDs, not journal encounter IDs.
local bosses={ [3470]="Nek'zali the Soulcoiler",[3445]="Entombed Sentinels",[3455]="Vashnik the Malignant",[3497]="The Lost Explorers",[3420]="Sszorak",[3421]="The Twin Fangs",[3429]="The Coiled Altar",[3492]="Ula'tek",[3379]="Nymrissa Wavecaller",[3513]="Kith'ix" }
local function norm(s)return type(s)=="string" and s:lower():gsub("^the%s+",""):gsub("[^%w]","") or "" end
local function save()
 local s={instance=EJ_GetCurrentInstance and EJ_GetCurrentInstance(),tier=EJ_GetCurrentTier and EJ_GetCurrentTier(),difficulty=EJ_GetDifficulty and EJ_GetDifficulty(),encounter=EncounterJournal and EncounterJournal.encounterID}
 if EJ_GetLootFilter then s.class,s.spec=EJ_GetLootFilter() end
 if C_EncounterJournal.GetSlotFilter then s.slot=C_EncounterJournal.GetSlotFilter() end
 return s
end
local function restore(s)
 if s.tier and EJ_SelectTier then EJ_SelectTier(s.tier) end
 if s.instance and s.instance>0 then EJ_SelectInstance(s.instance);if s.encounter and s.encounter>0 and EJ_SelectEncounter then EJ_SelectEncounter(s.encounter) end end
 if s.difficulty and EJ_SetDifficulty then EJ_SetDifficulty(s.difficulty) end
 if s.class and EJ_SetLootFilter then EJ_SetLootFilter(s.class,s.spec or 0) end
 if s.slot and C_EncounterJournal.SetSlotFilter then C_EncounterJournal.SetSlotFilter(s.slot) end
end
local function instances(item)
 local out,seen={},{}
 local function add(id,raid)if type(id)=="number" and id>0 and not seen[id] then seen[id]=true;out[#out+1]={id=id,raid=raid} end end
 if item.sourceType~="dungeon" and EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex then
  local s=save();local ok=pcall(function()
   EJ_SelectTier(EJ_GetNumTiers()) -- Only the current expansion, never every tier.
   for i=1,12 do local id=EJ_GetInstanceByIndex(i,true);if not id then break end;add(id,true) end
  end);restore(s);if not ok then return {} end
 end
 if item.sourceType~="raid" and C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo and C_EncounterJournal.GetInstanceForGameMap then
  for index,map in ipairs(C_ChallengeMode.GetMapTable() or {}) do if index>12 then break end
   local _,_,_,_,_,gameMapID=C_ChallengeMode.GetMapUIInfo(map)
   if gameMapID then add(C_EncounterJournal.GetInstanceForGameMap(gameMapID),false) end
  end
 end
 return out
end
function R.ResolveJournalRoute(item,complete)
 if not (EJ_SelectInstance and EJ_GetNumLoot and C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex and C_Timer and C_Timer.After) then return false end
 if R.journalLookup and R.journalLookup.id==item.id then return true end
 local ok,list=pcall(instances,item);if not ok or #list==0 then return false end
 local job={id=item.id,instance=1,index=1,reads=0,list=list};R.journalLookup=job
 local wanted;local source=norm(item.dropSource)
 if R.GuideData and R.GuideData.patch=="12.1" then
  for id,name in pairs(bosses) do if source~="" and source:find(norm(name),1,true) then wanted=id;break end end
 end
 local function finish(route)
  if R.journalLookup~=job then return end
  R.journalLookup=nil;complete(route)
 end
 local step
 step=function()
  if R.journalLookup~=job then return end
  if InCombatLockdown() then finish(nil);return end
  local instance=job.list[job.instance];if not instance or job.reads>=2000 then finish(nil);return end
  local old=save();local route
  local success=pcall(function()
   EJ_SelectInstance(instance.id)
   if EJ_SetDifficulty then
    for _,difficulty in ipairs(instance.raid and {16,15,14} or {23,2,1}) do
     if not EJ_IsValidInstanceDifficulty or EJ_IsValidInstanceDifficulty(difficulty) then EJ_SetDifficulty(difficulty);break end
    end
   end
   if EJ_SetLootFilter then EJ_SetLootFilter(0,0) end
   if C_EncounterJournal.ResetSlotFilter then C_EncounterJournal.ResetSlotFilter() end
   if wanted and job.index==1 and EJ_GetEncounterInfoByIndex and EJ_GetEncounterInfo then
    for i=1,32 do
     local _,_,encounter=EJ_GetEncounterInfoByIndex(i);if not encounter then break end
     local name,_,_,_,_,_,dungeonID=EJ_GetEncounterInfo(encounter)
     if dungeonID==wanted then route={instanceID=instance.id,encounterID=encounter,isRaid=instance.raid,bossName=name};return end
    end
   end
   local count=EJ_GetNumLoot() or 0
   if count==0 and not job.retried then job.retried=true;return end
   local last=math.min(count,job.index+23,600)
   for i=job.index,last do
    job.reads=job.reads+1;local info=C_EncounterJournal.GetLootInfoByIndex(i)
    if info and info.itemID==(item.acquisitionItemID or item.journalItemID or item.id) and info.encounterID and info.encounterID>0 then
     route={instanceID=instance.id,encounterID=info.encounterID,isRaid=instance.raid};return
    end
   end
   job.index=last+1
   if job.index>count or job.index>600 then job.instance=job.instance+1;job.index=1;job.retried=nil end
  end)
  local restored=pcall(restore,old)
  if not success or not restored then finish(nil) elseif route then finish(route) else C_Timer.After(.03,step) end
 end
 R.journalStatus={id=item.id,key="JOURNAL_RESOLVING"}
 C_Timer.After(0,step)
 return true
end
