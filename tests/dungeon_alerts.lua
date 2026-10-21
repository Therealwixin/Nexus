local R=TEST.R
local A=R.DungeonAlerts
local originalTarget,originalCandidates,originalScan=R.GetGearTarget,R.GetGearCandidates,R.scan
local targets={
 [10]={id=271511,acquisitionItemID=159337,catalyst=true,name="Chosen Bloodslayer's Fanged Grips",gearSlotID=10},
 [12]={id=162544,name="Jade Ophidian Band",gearSlotID=12},
 [8]={id=159327,crafted=true,name="Craft fixture",gearSlotID=8},
}
R.GetGearTarget=function(slot,spec,scope)
 assert(spec==261 and scope=="mplus_usage","Dungeon alerts must use active-spec M+ primary recommendation, independently of preview/activity settings")
 return targets[slot]
end
R.GetGearCandidates=function()error("Dungeon alternatives must not become BiS alerts")end
R.scan={equipped={},bags={}}
-- Six source-pool items do not imply six authored BiS targets.
local loot={[159337]=true,[162544]=true,[159317]=true,[159329]=true,[159327]=true,[158366]=true}
local entries=A:CollectEntries(loot,261)
assert(#entries==2 and entries[1].item.id==271511 and entries[2].item.id==162544,"Only the ring and original source of the tier gloves qualify")
assert(#A:CollectEntries({[159317]=true,[159329]=true,[158366]=true},261)==0,"Alternative-only loot pools must produce no BiS popup")
assert(#A:CollectEntries({[271511]=true},261)==0,"A tier result ID is not proof the dungeon drops the original piece")
R.scan.bags[159337]=1
assert(#A:CollectEntries(loot,261)==1,"An owned Catalyst source must not be requested again")
R.scan.bags={};R.scan.equipped[11]={id=162544}
assert(#A:CollectEntries(loot,261)==1,"A BiS ring equipped in the other ring slot is already owned")
R.scan.equipped={};targets[11]=targets[12]
assert(#A:CollectEntries(loot,261)==2,"The same item in paired target slots must not count twice")
targets[11]=nil
A.visit={name="Temple of Sethraliss"};A:Show(entries)
assert(A.rows[1].source:GetText():find(R.L("DUNGEON_BIS_CATALYST"),1,true),"A Catalyst source must be visibly labelled as a conversion")
assert(A.rows[2].source:GetText():find(R.L("DUNGEON_BIS_ITEM"),1,true),"A direct M+ target drop must be visibly distinguished")
assert(#A.entries==2 and A.pages==1,"Two real targets must not leave two pages of alternatives")
A.frame:Hide();A.visit=nil;A.entries=nil
R.GetGearTarget,R.GetGearCandidates,R.scan=originalTarget,originalCandidates,originalScan
print("Dungeon alerts PASS: primary M+ active-spec selection, six-to-two regression, Catalyst source IDs/labels, owned and paired-slot deduplication")
