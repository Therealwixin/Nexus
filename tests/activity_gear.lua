local R=TEST.R
local mode=R.db.mode
assert(not R.IsGearItem({id=240908}),"Known gem must never be equipment")
TEST.items[98098]={name="Test non-gear",equipLoc=""}
assert(not R.IsGearItem({id=98098}),"Native non-gear type must override an imported raid label")
R.SetViewSpec(1480);R.db.mode="mythicplus"
local mpFixture=R.GetDataset("mythicplus",1480);local liveOffhand=mpFixture.slots[17]
mpFixture.slots[17]={{id=237840,name="Crafted regression weapon",crafted=true,source="Murlok.io",count=27},{id=268211,source="Murlok.io",count=2},{id=268211,source="Wowhead",bisGuide=true}}

local target=R.GetGearTarget(17)
assert(target and target.id==237840 and target.crafted and target.source=="Murlok.io" and target.count==27,"Devourer M+ offhand must follow its observed crafted weapon")
local original=R.GetDataset("mythicplus").slots[17][1]
assert(original.bisGuide~=target.bisGuide or not original.bisGuide,"Do not mutate observed source into authored BiS")
assert(R.GearLevelRange(target,17).max==331 and R.GearPreviewLink(target,17),"Crafted target keeps maximum-quality native tooltip")
R.UI.frame:Show();R.UI.gearView="targets";R.UI:SetView("equipment")
assert(not R.UI.buttons.RAID and not R.UI.buttons.MYTHICPLUS,"No obsolete activity selectors")
assert(R.UI.sectionTitle:GetText()==R.L("MPLUS_GEAR_TITLE") and R.GetGearSummary():find("Murlok.io",1,true),"M+ names its actual dataset")
R.db.mode="raid"
assert(R.GetMode()=="mythicplus" and R.GetGearTarget(17).id==237840,"Saved raid setting cannot change M+ recommendations")
assert(not R.GetDataset("raid") and not R.GetMetaDataset("raid"),"Raid datasets removed")
for _,button in pairs({R.UI.buttons.EQUIPMENT,R.UI.buttons.STATS,R.UI.buttons.PREPARATION,R.UI.buttons.META}) do assert(not button.backdrop,"No square gold navigation border") end
mpFixture.slots[17]=liveOffhand
local shown=0
for sid in pairs(R.Data.specs) do
 R.SetViewSpec(sid)
 for _,slot in ipairs(R.SLOTS) do
  local candidates=R.GetMPlusGearCandidates(slot.id)
  local primary=candidates[1]
  if primary then
   shown=shown+1;assert(primary.count>0 and primary.source=="Murlok.io" and not primary.bisGuide,"Only actually observed M+ candidates qualify")
   for _,row in ipairs(candidates) do assert(row.count<=primary.count and R.GearPreviewLink(row,slot.id),"Popularity order and seasonal tooltips") end
   if slot.id==12 or slot.id==14 then assert(primary.id~=R.GetGearTarget(slot.id==12 and 11 or 13).id,"Paired slots remain distinct") end
   local seen={}
   local alternatives=R.GetGearAlternatives(slot.id)
   assert(#alternatives<=4,"Alternative bound survives activity mode")
   for _,alt in ipairs(alternatives) do assert(alt.id~=primary.id and not seen[alt.id],"No repeated M+ target or duplicate alternatives");seen[alt.id]=true end
  end
 end
end
assert(shown>580,"Broad M+ coverage, without falling back to the other source")
-- No observations must never silently borrow a Wowhead primary.
local data=R.GetDataset("mythicplus",1480);local old=data.slots[17];data.slots[17]={{id=268211,source="Wowhead",bisGuide=true,count=999}}
assert(not R.GetGearTarget(17,1480),"Missing observations cannot masquerade as a Murlok recommendation")
data.slots[17]=old
R.db.mode=mode;R.SetViewSpec(nil);R.UI.frame:SetSize(1280,900)
print("Activity gear PASS: Devourer source conflict, crafted tooltip, retired-mode migration, all-spec popularity, paired slots, bounded alternatives, unavailable-source isolation and minimum layout")
