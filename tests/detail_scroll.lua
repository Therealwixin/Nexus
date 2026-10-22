local R=TEST.R
R.SetViewSpec(71);R.db.needsOnly=false;R.UI.gearView="targets";R.UI.selectedSlot=1
R.UI.frame:Show();R.UI:SetView("equipment");R.UI:RenderDetail(R.GetGearTarget(1),1)
local function position(value)
 local max=math.max(0,R.UI.detailChild:GetHeight()-R.UI.detailScroll:GetHeight())
 assert(max>value,"Regression fixture must contain scrollable detail")
 R.UI.detailScroll:SetVerticalScroll(value)
end
position(120)
for i=1,30 do R.events:Fire("OnEvent","GET_ITEM_INFO_RECEIVED",12345) end
TEST.Flush()
assert(R.UI.detailScroll:GetVerticalScroll()==120,"Item-info refresh must preserve side panel position")
local alt=R.GetGearAlternatives(1)[1];assert(alt,"Regression needs a real alternative")
R.UI:RenderDetail(alt,1)
assert(R.UI.detailScroll:GetVerticalScroll()==0,"Explicit new item starts at top")
position(90)
R.UI:Refresh()
assert(R.UI.detailActiveItem.id==alt.id,"Background refresh must preserve the selected alternative")
assert(R.UI.detailScroll:GetVerticalScroll()==90,"Selected alternative must retain scroll offset")
R.UI:JournalStatusChanged(alt.id)
assert(R.UI.detailScroll:GetVerticalScroll()==90,"Asynchronous journal status must preserve scroll")
R.UI.frame:SetSize(1200,816)
assert(R.UI.detailActiveItem.id==alt.id and R.UI.detailScroll:GetVerticalScroll()==90,"Resize must keep the selected detail and position")
for _,row in ipairs(R.UI.rows) do if row.slotID==1 then row:Fire("OnClick");break end end
assert(R.UI.detailActiveItem.id==R.GetGearTarget(1).id and R.UI.detailScroll:GetVerticalScroll()==0,"Clicking the main slot deliberately returns from its alternative to the primary item")
R.UI.selectedSlot=2;R.UI:Refresh()
assert(R.UI.detailScroll:GetVerticalScroll()==0,"Changing equipment slots starts the new detail at top")
R.SetViewSpec(65);R.UI:Refresh()
assert(R.UI.detailScroll:GetVerticalScroll()==0,"Changing spec cannot retain another spec's detail offset")
assert(not R.UI.buttons.RAID and not R.UI.buttons.MYTHICPLUS,"Single-context UI has no raid selector")
for _,modes in pairs(R.Data.specs) do assert(not modes.raid,"Raid equipment must not be shipped") end
assert(not R.MetaData.modes.raid,"Raid Meta must not be shipped")
R.SetViewSpec(nil);R.UI.selectedSlot=1;R.UI.frame:SetSize(1280,900);R.UI:Refresh()
print("Detail scroll PASS: item events, selected alternatives, journal callbacks and resize preserve position; deliberate item/slot/spec changes reset it; retired raid datasets absent")
