local R=TEST.R
local A=R.DungeonAlerts
local saved={target=R.GetGearTarget,alternatives=R.GetGearAlternatives,scan=R.scan,level=R.ItemLevel,range=R.GearLevelRange,
 context=A.Context,loot=A.ReadLoot,scanEquipment=R.ScanEquipment,spec=R.SpecID,dataset=R.GetDataset}
-- Actual published Elemental alternatives from the reported dungeon.
R.scan={equipped={},bags={}}
local altar={};for _,slot in ipairs(R.SLOTS) do for _,item in ipairs(R.GetGearAlternatives(slot.id,262)) do
 if (item.dropSource or ""):find("Altar of Fangs",1,true) then altar[item.acquisitionItemID or item.journalItemID or item.id]=true end
end end
assert(altar[273778],"Elemental's Polished Lightwood Channeler must stay covered by this regression")
local actual=A:CollectEntries(altar,262);local found=false
for _,entry in ipairs(actual) do if entry.item.id==273778 then found=entry.alternative end end
assert(found,"Actual Elemental Altar of Fangs alternative must trigger without a primary drop")

-- Every validated daily snapshot must keep all UI candidates eligible for entry alerts.
local specs=0
for sid in pairs(R.Data.specs) do
 local pool,expected={},{}
 for _,slot in ipairs(R.SLOTS) do
  local function add(item)
   if item and not item.crafted then local id=item.acquisitionItemID or item.journalItemID or item.id;pool[id]=true;expected[id]=true end
  end
  add(R.GetGearTarget(slot.id,sid,"mplus_usage"))
  for _,item in ipairs(R.GetGearAlternatives(slot.id,sid)) do add(item) end
 end
 local got={};for _,entry in ipairs(A:CollectEntries(pool,sid)) do assert(not got[entry.dropID],"Duplicate instance drop");got[entry.dropID]=true end
 for id in pairs(expected) do assert(got[id],"Current snapshot candidate missing from popup: "..sid.."/"..id) end
 specs=specs+1
end
assert(specs==40,"Instance candidate coverage must include all 40 specs")

local targets={
 [10]={id=271511,acquisitionItemID=159337,catalyst=true,name="Tier gloves",gearSlotID=10},
 [12]={id=162544,name="Target ring",gearSlotID=12},
 [8]={id=159327,crafted=true,name="Craft fixture",gearSlotID=8}}
local alts={
 [10]={{id=159317,name="Alternative gloves",gearSlotID=10}},
 [12]={{id=159329,name="Alternative ring",gearSlotID=12}},
 [8]={{id=158366,name="Alternative boots",gearSlotID=8}}}
R.GetGearTarget=function(slot,spec,scope)assert(spec==261 and scope=="mplus_usage");return targets[slot]end
R.GetGearAlternatives=function(slot,spec)assert(spec==261);return alts[slot] or {} end
R.GearLevelRange=function()return {max=334}end
R.ItemLevel=function(item)return item.level end
local loot={[159337]=true,[162544]=true,[159317]=true,[159329]=true,[159327]=true,[158366]=true}
local entries=A:CollectEntries(loot,261)
assert(#entries==5,"Two primary drops and three real alternatives qualify; crafted item never drops")
assert(not entries[1].alternative and not entries[2].alternative and entries[3].alternative,"Primary picks are listed first")
assert(#A:CollectEntries({[159317]=true,[159329]=true,[158366]=true},261)==3,"Alternative-only pools must trigger with truthful alternative labels")
assert(#A:CollectEntries({[271511]=true},261)==0,"Tier result ID does not prove original source drop")
R.scan.bags[159337]=1;assert(#A:CollectEntries(loot,261)==4,"Owned Catalyst source is excluded")
R.scan.bags={};R.scan.equipped[11]={id=162544,level=320}
assert(#A:CollectEntries(loot,261)==4,"Owned ring suppresses the primary, but its alternative may replace the other weaker ring slot")
R.scan.equipped={};targets[11]=targets[12]
assert(#A:CollectEntries(loot,261)==5,"Duplicate paired-slot primary must be deduplicated")
targets[11]=nil
R.scan.equipped[10]={id=999,level=340}
assert(#A:CollectEntries(loot,261)==4,"Higher equipped level suppresses an alternative, not a missing primary recommendation")
R.scan.equipped[10].level=334;assert(#A:CollectEntries(loot,261)==5,"Equal level can still be a relevant sidegrade")
local catalystTarget=targets[10];targets[10]={id=271511,name="Direct primary",gearSlotID=10}
R.scan.equipped[10]={id=271511,level=320};assert(#A:CollectEntries(loot,261)==4,"A low-level equipped primary must not suppress a potentially stronger alternative")
R.scan.equipped[10].level=334;assert(#A:CollectEntries(loot,261)==3,"An equipped primary at the alternative ceiling suppresses that alternative")
targets[10]=catalystTarget
R.scan.equipped={[11]={id=998,level=340},[12]={id=999,level=320}}
assert(#A:CollectEntries(loot,261)==5,"A ring can replace the weaker paired slot")
R.scan.equipped[12].level=340;assert(#A:CollectEntries(loot,261)==4,"Both stronger paired items suppress the alternative")
R.scan.equipped={};R.scan.bags[159317]=1;assert(#A:CollectEntries(loot,261)==4,"Owned alternatives are excluded")
R.scan.bags={}
A.visit={name="Altar of Fangs",kind="party"};A:Show(entries)
assert(A.rows[1].source:GetText():find(R.L("DUNGEON_BIS_CATALYST"),1,true),"Catalyst source label")
assert(A.pages==2,"All qualifying picks and alternatives are paginated")
A.page=2;A:RenderBanner();assert(A.rows[1].source:GetText():find(R.L("INSTANCE_ALTERNATIVE"),1,true),"Alternatives must never be labelled BiS")
A.visit.kind="raid";A:RenderBanner();assert(A.frame.title:GetText()==R.L("RAID_DROP_WARNING"),"Raid acquisition title")

-- Visit lifecycle: no season-list gate, active spec, current data, no repeat spam.
local nativeInfo=GetInstanceInfo
GetInstanceInfo=function()return "Altar of Fangs","party",23,"Mythic",5,0,false,123 end
assert(saved.context(A).kind=="party","Any native dungeon with relevant loot can qualify")
GetInstanceInfo=function()return "Raid fixture","raid",15,"Heroic",20,0,false,124 end
assert(saved.context(A).kind=="raid" and saved.context(A).difficultyID==15,"Raid context is supported")
GetInstanceInfo=function()return "World","none",0,"",0,0,false,1 end
assert(saved.context(A)==nil,"Open world does not create an instance warning")
GetInstanceInfo=nativeInfo
A:ClearVisit();local context={name="Altar of Fangs",kind="party",gameMapID=123,difficultyID=23}
A.Context=function()return context end
local reads=0;A.ReadLoot=function()reads=reads+1;return loot,false end
R.ScanEquipment=function()end;R.SpecID=function()return 261 end
local data={retrievedAt="2026-10-22T10:00:00Z"};R.GetDataset=function()return data end
A:Check();assert(#A.entries==5 and A.frame:IsShown() and reads==1,"Entering shows all current matching drops")
A.remaining=9;A:Check();assert(reads==1 and A.remaining==9,"Repeated events do not restart the popup")
A.frame:Hide();A:OnEvent("BAG_UPDATE_DELAYED");assert(not A.frame:IsShown(),"Unchanged inventory does not reopen dismissed popup")
R.scan.bags[159317]=1;A:OnEvent("BAG_UPDATE_DELAYED");assert(#A.entries==4 and reads==1,"Ownership updates reuse the native loot pool")
R.scan.bags={};alts[3]={{id=777,name="Fresh alternative",gearSlotID=3}};loot[777]=true
data.retrievedAt="2026-10-23T10:00:00Z";A:Check()
assert(#A.entries==6,"A data refresh immediately uses newly recommended alternatives")
context={name="Raid fixture",kind="raid",gameMapID=124,difficultyID=15};A:Check()
assert(reads==2 and A.frame.title:GetText()==R.L("RAID_DROP_WARNING"),"Raid entry reads its own loot and displays the correct title")
TEST.combat=true;context={name="Combat entry",kind="party",gameMapID=125,difficultyID=23};A:Check();assert(reads==2,"Combat entry is deferred")
TEST.combat=false;A:OnEvent("PLAYER_REGEN_ENABLED");assert(reads==3,"Combat exit resumes the pending instance check")
-- Native Adventure Guide scan uses raid difficulty and restores player filters.
local names={"EJ_SelectInstance","EJ_GetNumLoot","EJ_GetCurrentInstance","EJ_GetDifficulty","EJ_SetDifficulty","EJ_IsValidInstanceDifficulty","EJ_GetLootFilter","EJ_SetLootFilter","EJ_SelectEncounter","EJ_GetEncounterInfo","EJ_IsLootListOutOfDate"}
local natives={};for _,key in ipairs(names) do natives[key]=_G[key] or false end
local nativeJournal,nativeUI,sourceCatalog,journalIndex=C_EncounterJournal,EncounterJournal,R.SourceCatalog,R.journalIndex
local state={instance=901,difficulty=23,class=7,spec=262,slot=4,encounter=888}
local lootDifficulty
EJ_SelectInstance=function(id)state.instance=id end
EJ_GetCurrentInstance=function()return state.instance end
EJ_GetDifficulty=function()return state.difficulty end
EJ_SetDifficulty=function(id)state.difficulty=id end
EJ_IsValidInstanceDifficulty=function(id)return id==15 or id==23 end
EJ_GetLootFilter=function()return state.class,state.spec end
EJ_SetLootFilter=function(c,sp)state.class=c;state.spec=sp end
EJ_SelectEncounter=function(id)state.encounter=id end
EJ_GetEncounterInfo=function(id)return "Raid fixture boss",nil,id,nil,nil,902 end
EJ_IsLootListOutOfDate=function()return false end
EJ_GetNumLoot=function()return 1 end
EncounterJournal={encounterID=888}
C_EncounterJournal={
 GetInstanceForGameMap=function(id)assert(id==124);return 902 end,
 GetSlotFilter=function()return state.slot end,
 ResetSlotFilter=function()state.slot=0 end,
 SetSlotFilter=function(id)state.slot=id end,
 GetLootInfoByIndex=function()lootDifficulty=state.difficulty;return {itemID=777,encounterID=999,link="item:777"} end}
local nativeLoot,pending=saved.loot(A,{name="Raid fixture",kind="raid",gameMapID=124,difficultyID=15})
assert(nativeLoot[777].link=="item:777" and not pending and lootDifficulty==15,"Raid lookup reads the active difficulty and native item link")
assert(R.journalIndex.byItem[777].isRaid and R.SourceCatalog[777].kind=="raid","Raid route/source remains a raid")
assert(state.instance==901 and state.difficulty==23 and state.class==7 and state.spec==262 and state.slot==4 and state.encounter==888,"Native instance, difficulty, loot/slot filters and selected encounter are restored")

-- Reproduce Temple -> Kith'ix -> Venomous with the old native Temple pool
-- still present immediately after selecting each new raid instance.
local originalTarget,originalAlternatives=R.GetGearTarget,R.GetGearAlternatives
local realTarget,realAlternatives=saved.target,saved.alternatives
local lifecycleDataset=R.GetDataset;R.GetDataset=saved.dataset
R.GetGearTarget=function()return nil end
R.GetGearAlternatives=function(slot)return realAlternatives(slot,262) end
local templeContext={name="Temple of Sethraliss",kind="party",gameMapID=300,difficultyID=23}
local kithContext={name="Kith'ix raid",kind="raid",gameMapID=301,difficultyID=15}
local venomContext={name="The Venomous Abyss",kind="raid",gameMapID=302,difficultyID=15}
local byMap={[300]=1000,[301]=1001,[302]=1002}
C_EncounterJournal.GetInstanceForGameMap=function(map)return byMap[map] end
local activeRows={{itemID=159375,encounterID=2000,link="item:159375"}}
local owners={[2000]=1000,[2001]=1001,[2002]=1002}
EJ_GetEncounterInfo=function(id)return "Verified boss",nil,id,nil,nil,owners[id] end
C_EncounterJournal.GetLootInfoByIndex=function(index)return activeRows[index] end
EJ_GetNumLoot=function()return #activeRows end
local templeLoot,templePending=saved.loot(A,templeContext)
assert(not templePending and templeLoot[159375],"Actual reported legguards are present in their verified Temple pool")
local templeEntries=A:CollectEntries(templeLoot,262,templeContext)
assert(#templeEntries==1 and templeEntries[1].dropID==159375,"Reported Elemental Catalyst alternative appears in Temple")
assert(templeLoot[159375].instanceID==1000 and templeLoot[159375].encounterID==2000,"Verified loot retains the actual instance and encounter for diagnostics")
local route=R.journalIndex.byItem[159375]
assert(route.instanceID==1000 and not route.isRaid,"Legguards route points to the real dungeon")
for _,raidContext in ipairs({kithContext,venomContext}) do
 local stale,pending=saved.loot(A,raidContext)
 assert(pending and not stale[159375],"Old Temple loot must be rejected after switching into either raid")
 assert(R.journalIndex.byItem[159375]==route and R.SourceCatalog[159375].kind=="dungeon","Rejected stale pool cannot relabel the dungeon item as a raid drop")
 assert(#A:CollectEntries({[159375]=true},262,raidContext)==0,"Explicit dungeon source is excluded from raid popups even if passed a contaminated pool")
end
-- A mixed read is transactional: even its legitimate rows cannot poison the
-- source catalog until the entire native response has been verified.
activeRows={{itemID=159375,encounterID=2000},{itemID=990001,encounterID=2001}}
local mixed,mixedPending=saved.loot(A,kithContext)
assert(mixedPending and mixed[990001] and not R.SourceCatalog[990001],"A partial/mixed pool does not commit source metadata")
activeRows={{itemID=990001,encounterID=2001}}
local fresh,freshPending=saved.loot(A,kithContext)
assert(not freshPending and fresh[990001] and not fresh[159375],"Fresh raid pool replaces old dungeon rows")
assert(#A:CollectEntries(fresh,262,kithContext)==0,"Dungeon legguards disappear once the valid raid pool arrives")
EJ_IsLootListOutOfDate=function()return true end
local obsolete,obsoletePending=saved.loot(A,kithContext)
assert(not obsolete and obsoletePending,"Native out-of-date loot cannot be marked complete")
EJ_IsLootListOutOfDate=function()return false end
R.GetGearTarget,R.GetGearAlternatives=originalTarget,originalAlternatives
R.GetDataset=lifecycleDataset
C_EncounterJournal.GetInstanceForGameMap=function()return 902 end
C_EncounterJournal.GetLootInfoByIndex=function()return nil end
local _,waiting=saved.loot(A,{name="Raid fixture",kind="raid",gameMapID=124,difficultyID=15});assert(waiting,"Unloaded native loot is retried, never marked complete")
for _,key in ipairs(names) do _G[key]=natives[key] or nil end
C_EncounterJournal,EncounterJournal,R.SourceCatalog,R.journalIndex=nativeJournal,nativeUI,sourceCatalog,journalIndex
A:ClearVisit()
R.GetGearTarget,R.GetGearAlternatives,R.scan,R.ItemLevel,R.GearLevelRange=saved.target,saved.alternatives,saved.scan,saved.level,saved.range
A.Context,A.ReadLoot=saved.context,saved.loot
R.ScanEquipment,R.SpecID,R.GetDataset=saved.scanEquipment,saved.spec,saved.dataset
print("Instance alerts PASS: actual Elemental alternatives, Temple -> two raids with stale native loot, transactional source updates, instance ownership, labels, gear variants, data refresh, paging and combat deferral")
