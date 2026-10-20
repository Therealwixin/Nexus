local R=TEST.R
local function check(value,message)assert(value,message)end
local info=C_Item.GetItemInfo
C_Item.GetItemInfo=function(value)check(value~=nil,"Native item API cannot receive nil for spell-only enchant rows");return info(value)end
check(R.ItemColor({name="Spell-only enchant"})~=nil,"Spell-only enchant color must be safe")
R.db.gearSource="overall";R.SetViewSpec(261);R.UI.gearView="targets";R.UI:SetView("equipment")
check(not R.UI.paperDoll or not R.UI.paperDoll:IsShown(),"Character model must be removed")
check(next(R.UI.sourceButtons)==nil and R.UI.sectionTitle:GetText()=="Overall BiS","No Raid/Mythic gear-source selectors remain")
local wrist=R.UI.rows[6];local chest=R.UI.rows[5]
check(math.abs(chest:GetBottom()-wrist:GetTop())<4,"No artificial gap before wrists")
local a,b=R.GetGearCandidates(1,261,"overall")[1],R.GetGearCandidates(1,261,"overall")[2]
check(a and b and a.id~=b.id and b.observedAlternative,"Overall alternatives must include labelled observed options")
local header
for _,e in ipairs(R.UI.detailPool) do if e.text and e.text:GetText()==R.L("ALTERNATIVES") and e.text:IsShown() then header=e.text end end
check(header and header:GetTop()>R.UI.detailScroll:GetBottom(),"Alternatives heading is visible before acquisition details")
ItemLocation={CreateFromEquipmentSlot=function(_,slot)return {slot=slot}end}
C_Item.GetCurrentItemLevel=function(location)return location.slot==1 and 345 or 340 end
check(R.ItemLevel({id=123,slotID=1,link="item:123",ilvl=1},true)==345,"Equipped ilvl must use native item location before generic/cached values")
R.scan.equipped[1]={id=123,link="item:123",slotID=1}
TEST.stats={ [456]={ITEM_MOD_HASTE_RATING_SHORT=100,ITEM_MOD_MASTERY_RATING_SHORT=100},["item:123"]={ITEM_MOD_HASTE_RATING_SHORT=150,ITEM_MOD_CRIT_RATING_SHORT=150} }
check(R.GearOwnership({id=123,catalyst=true,acquisitionItemID=456},1)=="TIER_STATS_DIFFERENT","Tier item ID must not confirm different Catalyst stats")
TEST.stats["item:123"]={ITEM_MOD_HASTE_RATING_SHORT=150,ITEM_MOD_MASTERY_RATING_SHORT=150}
check(R.GearOwnership({id=123,catalyst=true,acquisitionItemID=456},1)=="EQUIPPED","Matching secondary types are recognized independently of ilvl")
TEST.stats["item:123"]={ITEM_MOD_HASTE_RATING_SHORT=200,ITEM_MOD_MASTERY_RATING_SHORT=100}
check(R.GearOwnership({id=123,catalyst=true,acquisitionItemID=456},1)=="TIER_STATS_DIFFERENT","Different secondary proportions must not confirm a Catalyst variant")
check(R.GearOwnership({id=123,catalystOption=true},1)=="TIER_STATS_UNVERIFIED","Unknown Catalyst base must remain unverified")
-- Resolve a previously unopened journal through one current-expansion boss mapping.
local tier,instance,difficulty=3,99,15;local reads=0;local opens=0
EJ_GetNumTiers=function()return 12 end;EJ_GetCurrentTier=function()return tier end;EJ_SelectTier=function(x)tier=x end
EJ_GetCurrentInstance=function()return instance end;EJ_SelectInstance=function(x)instance=x end
EJ_GetDifficulty=function()return difficulty end;EJ_SetDifficulty=function(x)difficulty=x end
EJ_GetInstanceByIndex=function(i,raid)check(tier==12 and raid,"Only current expansion raid enumeration allowed");return i==1 and 500 or nil end
EJ_GetEncounterInfoByIndex=function(i)return "Localized boss",nil,i==1 and 700 or nil end
EJ_GetEncounterInfo=function(id)return "Localized Ulatek",nil,id,nil,nil,500,3492 end
EJ_GetNumLoot=function()return 100 end
C_EncounterJournal={GetLootInfoByIndex=function(i)reads=reads+1;return {itemID=i,encounterID=701}end}
EncounterJournal_OpenJournal=function(diff,inst,boss)opens=opens+1;check(inst==500 and boss==700,"Resolved native boss route incorrect")end
R.journalLookup=nil;R.journalIndex=nil
check(R.OpenLoot({id=271510,sourceType="raid",dropSource="Tier Set - Ula'tek"}),"Unopened journal starts asynchronous resolution")
check(opens==0,"Lookup must not block click synchronously")
TEST.Flush();check(opens==1 and reads==0,"Verified boss mapping opens once without scanning loot")
check(tier==3 and instance==99 and difficulty==15,"Native journal state must be restored before opening")
-- Loot lookup is chunked and keeps the player's filters/selection intact.
local completed;local maxBatch=0;reads=0
check(R.ResolveJournalRoute({id=60,sourceType="raid"},function(route)completed=route end),"Lookup starts")
while #TEST.timer>0 do local before=reads;table.remove(TEST.timer,1)();maxBatch=math.max(maxBatch,reads-before) end
check(completed and completed.encounterID==701 and maxBatch<=24,"Loot discovery must find item using <=24 reads per callback")
check(tier==3 and instance==99 and difficulty==15,"Chunked lookup restores native state")
print("Screenshot regressions: socket row counts, compact paper doll, visible alternatives, native ilvl, Catalyst stats and asynchronous journal PASS")
