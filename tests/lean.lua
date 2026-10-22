local R=TEST.R
local count=0
local function check(value,message)count=count+1;assert(value,message)end
GetServerTime=function()return 1792436400 end
date=function()return "2026-10-19" end
R.events:Fire("OnEvent","ADDON_LOADED","Nexus")
R.events:Fire("OnEvent","PLAYER_LOGIN")
TEST.Flush()
check(not R.UI.frame,"Login does not build main UI")
check(not R.TalentData and not R.Talents,"Talent module not loaded")
check(not R.Data.playerItems and not R.Data.variants,"Profile item caches removed")
local specCount=0
for id,modes in pairs(R.Data.specs) do
 specCount=specCount+1
 for _,mode in ipairs({"mythicplus"}) do
  local d=modes[mode];check(d and d.slots,"Spec/mode coverage "..id..mode)
  check(not d.players,"No retained profiles "..id..mode)
  for slot,items in pairs(d.slots) do
   for _,item in ipairs(items) do TEST.items[item.id]={name=item.name or "Item",equipLoc="INVTYPE_HEAD"} end
  end
 end
end
check(specCount==40,"All 40 source specs retained")
local data=R.GetDataset();local head=data.slots[1][1];local neck=data.slots[2][1]
TEST.equipped[1]={id=head.id,link="item:"..head.id..":0:0:0:0:0"}
TEST.bags[0]={{itemID=neck.id,stackCount=1}}
R.ScanEquipment()
check(R.Ownership(head.id,1)=="EQUIPPED","Equipment ownership")
check(R.Ownership(neck.id,2)=="IN_BAGS","Bag ownership")
R.UI:Toggle()
check(R.UI.frame:IsShown(),"Gear opens")
check(not R.UI.buttons.PLAYERS and not R.UI.buttons.TALENTS,"Removed navigation")
check(not R.UI.playerCards and not R.UI.talentsPane,"Removed widgets not created")
check(not R.UI.themeButton:IsShown(),"Secondary controls hidden on gear")
for _,lang in ipairs({"EN","SK","CZ"}) do
 R.db.language=lang
 for _,mode in ipairs({"mythicplus"}) do
  R.db.mode=mode
  for id in pairs(R.Data.specs) do
   R.SetViewSpec(id)
   for _,view in ipairs({"equipment","preparation","meta","sources"}) do
    R.UI:SetView(view)
    check(R.UI.view==view,"View opens "..id..mode..lang..view)
   end
  end
 end
end
R.SetViewSpec(nil);R.db.mode="mythicplus";R.db.language="EN"
R.UI:SetView("sources");check(R.UI.languageButtons[1]:IsShown() and not R.UI.themeButton:IsShown(),"Settings accessible; one consistent theme")
check(not R.WCLData and not R.SourceStatus and not R.GetWCLEvidence,"Retired source data and hooks are not loaded")
for _,pool in ipairs({R.UI.listPool,R.UI.detailPool}) do for _,entry in ipairs(pool) do
 for _,field in ipairs({"text","note"}) do local part=entry[field];if part and part:IsShown() then
  for _,label in ipairs({"Collected","Archon","Raider.IO","WCL"}) do check(not part:GetText():find(label,1,true),"Retired sources hidden in Data & updates") end
 end end
end end
R.UI:SetView("players");check(R.UI.view=="equipment","Removed view cannot be selected")
for _,theme in ipairs(R.THEME_ORDER) do check(R.SetTheme(theme),"Theme "..theme) end
for _,category in ipairs({"enchants","gems","consumables"}) do
 R.UI.prepCategory=category;R.UI:SetView("preparation");check(R.UI.prepCategory==category,"Preparation "..category)
end
check(R.DataAge({updatedAt="2026-10-06T12:00:00Z"})==13,"Real source date age")
check(R.DataAge({updatedAt="garbage"})==nil,"Unknown source date")
check(not R.DataStatus({updatedAt="2026-10-06",retrievedAt="2026-10-19",primarySource="Source"}):find(R.L("DATA_OLD"),1,true),"Old publication checked today is not an old source check")
check(R.DataAge({updatedAt="2026-10-20"})==nil,"Future date not falsely fresh")
check(R.DataStatus({updatedAt="2026-10-06",primarySource="Source"}):find(R.L("DATA_OLD"),1,true),"Stale data is labelled")
check(R.DataStatus({updatedAt="2026-10-19",retrievedAt="2026-10-19",primarySource="Source",refreshStatus="unavailable"}):find(R.L("SOURCE_UNAVAILABLE"),1,true),"Retained source refresh failure stays visible even when its dates are current")
local originalScan=R.ScanEquipment;local scans=0
R.ScanEquipment=function()scans=scans+1;return originalScan()end
R.UI.frame:Hide()
for i=1,100 do R.events:Fire("OnEvent","GET_ITEM_INFO_RECEIVED",head.id) end
TEST.Flush();check(scans==0,"Hidden item events do not rescan bags")
R.UI:Toggle();scans=0
for i=1,100 do R.events:Fire("OnEvent","GET_ITEM_INFO_RECEIVED",head.id) end
TEST.Flush();check(scans==0,"Visible item events only redraw")
TEST.combat=true
R.events:Fire("OnEvent","PLAYER_EQUIPMENT_CHANGED",1);TEST.Flush()
check(scans==0,"Combat defers equipment scan")
TEST.combat=false
R.events:Fire("OnEvent","PLAYER_REGEN_ENABLED");TEST.Flush()
check(scans==1,"One deferred equipment scan after combat")
scans=0;R.equipmentDirty=false;TEST.combat=true
R.ScanEquipment();scans=0
check(R.scanAfterCombat,"Manual combat scan is queued")
TEST.combat=false;R.events:Fire("OnEvent","PLAYER_REGEN_ENABLED");TEST.Flush()
check(scans==1 and not R.scanAfterCombat,"Manual scan resumes after combat without an inventory event")
R.ScanEquipment=originalScan
local A=R.DungeonAlerts
local alertContext,alertLoot=A.Context,A.ReadLoot
A.visit={gameMapID=123,attempts=12,notified={}};A.pending=nil
A.Context=function()return {gameMapID=123}end
local reads=0;A.ReadLoot=function()reads=reads+1;return nil,true end
A.visit.revision=tostring(R.VERSION)..":"..tostring(R.GetDataset("mythicplus",R.SpecID()).retrievedAt)..":"..tostring(R.GuideData.generatedAt)
for i=1,100 do A:Check() end
check(reads==0,"Event flood respects dungeon retry cap")
A.visit.attempts=0
A.ReadLoot=function()error("simulated dungeon failure")end
A:Check();check(not A.checking,"Dungeon failure unlocks reentrancy guard")
check(A.visit.attempts==12,"Failed dungeon visit stops retry loop")
A.Context,A.ReadLoot=alertContext,alertLoot;A.visit=nil;A.pending=nil
for i=1,100 do R.RecordRuntimeError("same","same error") end
check(#R.db.runtimeErrors<=8,"Diagnostics bounded")
check(R.db.runtimeErrors[#R.db.runtimeErrors].count==100,"Repeated diagnostics coalesced")
TEST.leanChecks=count
