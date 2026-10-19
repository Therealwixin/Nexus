local R=TEST.R
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
R.db.language="SK";R.UI:SetView("equipment");R.UI.gearView="targets"
for _,size in ipairs({{960,700},{1200,816},{1280,900}}) do
 R.UI.frame:SetSize(size[1],size[2]);R.UI:Refresh()
 local width=R.UI.gearScroll:GetWidth();check(width>500,"Readable list width")
 check(R.UI.rows[1].note:GetWidth()>180,"Item name has useful space")
 for _,row in ipairs(R.UI.rows) do if row:IsShown() then
  check(row:GetHeight()==50,"Consistent gear row height")
  check(row.note:GetWidth()+164<=row:GetWidth()-144,"Item name and status do not overlap")
 end end
 R.db.needsOnly=true;R.UI:Refresh()
 local shown={};for _,row in ipairs(R.UI.rows) do if row:IsShown() then shown[#shown+1]=row end end
 table.sort(shown,function(a,b)return a.gridTop<b.gridTop end)
 for index,row in ipairs(shown) do check(row.gridTop==32+(index-1)*52,"Missing filter leaves no holes") end
 R.db.needsOnly=false
 R.UI.prepCategory="enchants";R.UI:SetView("preparation")
 local visible=0;for _,row in ipairs(R.UI.prepRows) do if row:IsShown() then visible=visible+1;check(row:GetHeight()>=57,"Preparation row remains readable") end end
 check(visible<=6,"Six preparation rows per page")
 R.UI:SetView("equipment")
end
TEST.version="99.0.0";R.UI:Refresh()
check(R.UI.noData:IsShown(),"Patch mismatch visibly reports unavailable recommendations")
TEST.version="12.1.0";R.UI:Refresh()
TEST.lookChecks=checks
