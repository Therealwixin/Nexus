local R=TEST.R
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
local function inside(child,parent,message)
 check(child:GetLeft()>=parent:GetLeft()-.1 and child:GetRight()<=parent:GetRight()+.1 and child:GetTop()<=parent:GetTop()+.1 and child:GetBottom()>=parent:GetBottom()-.1,message.." "..tostring(child:GetName()))
end
R.db.language="EN";R.db.needsOnly=false;R.UI.gearView="targets"
for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
 R.UI.frame:SetSize(unpack(size));R.UI:SetView("equipment")
 for _,row in ipairs(R.UI.rows) do
  inside(row,R.UI.gearChild,"Equipment fits paper doll")
  for _,part in ipairs({row.icon,row.text,row.note,row.ownership}) do inside(part,row,"Gear labels/icons stay inside slot") end
  check(row.border:GetWidth()==row.icon:GetWidth()+2,"Icon border hugs texture")
  check(not row.backdrop and row.slotBevel.texture=="Interface\\Buttons\\UI-Quickslot2","Gear uses native slot bevel without flat card border")
  inside(row.slotBevel,row,"Native slot bevel contained in row")
 end
 check(R.UI.rows[1]:GetLeft()<R.UI.rows[7]:GetLeft(),"Head left / gloves right")
 check(R.UI.rows[15]:GetTop()<R.UI.rows[6]:GetBottom(),"Main hand below wrists")
 check(R.UI.rows[16]:GetTop()<R.UI.rows[15]:GetBottom() and R.UI.rows[16]:GetLeft()==R.UI.rows[6]:GetLeft(),"Offhand below main hand in left column")
 for _,category in ipairs({"enchants","consumables"}) do
  R.UI.prepCategory=category;R.UI:SetView("preparation")
  check(not R.UI.prepPrev:IsShown() and not R.UI.prepNext:IsShown(),"No Preparation paging")
  local lastTop={}
  for index,row in ipairs(R.UI.prepRows) do if row:IsShown() then
   inside(row,R.UI.prepChild,"Preparation rows contained in scroll child")
   for _,part in ipairs({row.icon,row.text,row.note,row.status}) do inside(part,row,"Preparation labels fit row") end
   local col=(index-1)%2;check(not lastTop[col] or row:GetTop()<lastTop[col],"Preparation rows do not overlap");lastTop[col]=row:GetBottom()
  end end
 end
end
-- Several socketed items are visible together, preserving per-gem tooltips.
for _,slot in ipairs({2,11,12,9}) do
 local item={id=90000+slot,link="item:"..(90000+slot)..":0:0:0:0:0",name="Socket test item"}
 TEST.items[item.id]={name=item.name,equipLoc="INVTYPE_FINGER"};TEST.equipped[slot]=item;TEST.sockets[item.link]=2
end
R.ScanEquipment();R.UI.prepCategory="gems";R.UI:SetView("preparation")
check(#R.UI.socketEntries>=4,"Multiple socketed items share one view")
check(not R.UI.prepPrev:IsShown() and not R.UI.prepNext:IsShown(),"No per-item socket paging")
for _,card in ipairs(R.UI.socketCards) do if card:IsShown() then
 inside(card,R.UI.socketChild,"Socket cards fit scroll child")
 inside(card.icon,card,"Socket item icon fits card")
 check(card.border:GetWidth()==card.icon:GetWidth()+2,"Socket border matches icon")
 for _,row in ipairs(card.gemRows) do if row:IsShown() then inside(row,card,"Gem rows contained in card") end end
end end
for index,entry in ipairs(R.UI.socketEntries) do
 local visible=0;for _,row in ipairs(R.UI.socketCards[index].gemRows) do if row:IsShown() then visible=visible+1 end end
 check(visible==#entry.sockets.gems+#entry.recommendations,"Only real socket and recommendation rows are visible")
end
for _,scope in ipairs({"raid","mythicplus"}) do
 R.db.gearSource=scope
 for id in pairs(R.Data.specs) do R.SetViewSpec(id)
  for _,slot in ipairs(R.SLOTS) do for _,item in ipairs(R.GetGearCandidates(slot.id,nil,scope)) do
   check(item.acquisition==(scope=="raid" and "raid" or "dungeon") and not item.crafted,"Source restrictions are real")
  end end
 end
end
R.SetViewSpec(nil);R.db.gearSource="overall"
local enumerations=0
EJ_GetInstanceByIndex=function()enumerations=enumerations+1;error("Global EJ scan forbidden")end
EJ_GetNumTiers=function()enumerations=enumerations+1;error("Global EJ scan forbidden")end
local opened=0;EncounterJournal_OpenJournal=function(...)opened=opened+1;check(select(6,...)==99999,"Native opener receives item")end
R.UI:SetView("equipment");R.UI.frame:Show()
check(R.OpenLoot({id=99999,journalInstanceID=101,journalEncounterID=202,sourceType="raid"}),"Exact route opens")
check(opened==1 and not R.UI.frame:IsShown() and enumerations==0,"One native open, no overlay or global scan")
R.UI.frame:Show();check(R.OpenLoot({id=99998})==false and opened==1,"Unknown source does not open empty journal")
TEST.combat=true;R.OpenLoot({id=99999,journalInstanceID=101,journalEncounterID=202});TEST.combat=false
check(opened==1,"Combat prevents journal action")
TEST.version="99.0.0";R.UI:SetView("equipment");check(R.UI.noData:IsShown(),"Patch mismatch visible");TEST.version="12.1.0"
TEST.lookChecks=checks
