local R=TEST.R
local savedBags=TEST.bags
local first="item:98001:0:0:0:0:0:1"
local second="item:98001:0:0:0:0:0:2"
TEST.items[98001]={name="Two copies of one ring",equipLoc="INVTYPE_FINGER"}
TEST.items[98002]={name="No sockets",equipLoc="INVTYPE_FINGER"}
TEST.items[98003]={name="Material",equipLoc=""}
TEST.items[98004]={name="Test gem",equipLoc=""}
TEST.sockets[first]=1;TEST.sockets[second]=2;TEST.gems[first]={98004}
TEST.bags={[0]={{itemID=98001,stackCount=1,hyperlink=first},{itemID=98001,stackCount=1,hyperlink=second},{itemID=98003,stackCount=12,hyperlink="item:98003"}},[1]={{itemID=98002,stackCount=1,hyperlink="item:98002"}}}
R.ScanEquipment()
assert(R.scan.bags[98001]==2 and R.scan.bags[98003]==12,"Keep ownership and material stack counts")
assert(#R.scan.bagItems==3,"Retain gear copies, exclude known non-gear")
local equipped=R.GetSocketOverview();local bags=R.GetSocketOverview("bags")
assert(#bags.items==2 and bags.total==3 and bags.filled==1 and bags.empty==2,"Only actual bag sockets")
assert(bags.items[1].item.link==second and bags.items[2].item.link==first,"Copies retain their own variant and gems; empty first")
for _,entry in ipairs(bags.items) do
 assert(entry.slotID==nil and entry.item.bagID~=nil,"Bag location never masquerades as equipped slot")
 for _,rec in ipairs(entry.recommendations) do assert(not R.IsDiamond(rec.item),"No unique diamond plan across mutually exclusive bag gear") end
end
assert(R.GetSocketOverview().total==equipped.total,"Bag gear cannot affect equipped diamond/socket plan")
R.UI.prepCategory="gems";R.UI:SetView("preparation")
R.UI.socketScopeButtons.bags.scripts.OnClick()
assert(#R.UI.socketEntries==2 and R.UI.socketOverview.total==3,"In bags filter uses bag copies")
R.UI.socketCards[1].scripts.OnEnter(R.UI.socketCards[1])
assert(GameTooltip.link==second,"Bag tooltip uses complete variant link")
R.db.needsOnly=true;R.UI:Refresh();assert(#R.UI.socketEntries==1,"Missing only applies inside bag scope")
for _,size in ipairs({{960,700},{1280,900}}) do
 R.UI.frame:SetSize(unpack(size));R.UI:Refresh()
 assert(R.UI.socketScroll:GetTop()<R.UI.prepSummary:GetBottom(),"Socket summary clears scroll content")
 assert(R.UI.prepSummary:GetTop()<R.UI.socketScopeButtons.bags:GetBottom(),"Scope filters clear summary")
end
-- Existing bag event rescans once through the coalesced refresh queue.
TEST.bags={};R.events.scripts.OnEvent(R.events,"BAG_UPDATE_DELAYED");TEST.Flush()
assert(#R.UI.socketEntries==0,"Removing bag gear updates visible filter")
assert(R.UI.prepEmpty:IsShown() and R.UI.prepEmpty:GetText()==R.L("NO_EMPTY_BAG_SOCKETS"),"Bag-specific empty state")
R.db.needsOnly=false;R.UI.socketScopeButtons.equipped.scripts.OnClick()
assert(R.UI.socketOverview.total==equipped.total,"Equipped filter restores original items")
R.UI.prepCategory="enchants";R.UI:Refresh()
assert(not R.UI.socketPane:IsShown(),"Scope controls hidden outside sockets")
TEST.bags=savedBags;R.ScanEquipment();R.UI.frame:SetSize(1280,900)
print("Bag sockets PASS: duplicate variants, real socket counts, native links, scoped filters, bag events, Diamond isolation and layout")

