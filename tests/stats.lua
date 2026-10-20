local R=TEST.R
R.Initialize();TEST.spec=261;UnitLevel=function()return 90 end
local ratings={[9]=350,[10]=350,[11]=350,[18]=350,[26]=350,[29]=350,[21]=150,[17]=150,[14]=0}
local function converted(index,rating)
 local points=R.Data.statRules.curves[(index==21 or index==17) and "minor" or "secondary"]
 local x=rating*.1
 for i=2,#points do local a,b=points[i-1],points[i];if x<b[1] then return a[2]+(x-a[1])*(b[2]-a[2])/(b[1]-a[1]) end end
 return points[#points][2]
end
GetCombatRating=function(index)return ratings[index]end
GetCombatRatingBonus=function(index)return converted(index,ratings[index])end
GetCombatRatingBonusForCombatRatingValue=function(index,value)return converted(index,value)end
GetCritChance=function()return 39.5 end;GetRangedCritChance=function()return 39.5 end;GetSpellCritChance=function()return 39.5 end
GetHaste=function()return 100 end;GetMasteryEffect=function()return 78,2 end;GetVersatilityBonus=function()return 3 end
GetAvoidance=function()return 14 end;GetLifesteal=function()return 14 end;GetSpeed=function()return 3 end
for _,case in ipairs({{299,0,300},{300,10,400},{350,10,400},{400,20,500},{800,50,2000},{2000,100,nil},{2100,100,nil}}) do
 ratings[18]=case[1];local current=R.StatCurrent("haste");local dr=R.StatDR("haste",current)
 assert(dr and dr.penalty==case[2] and dr.nextRating==case[3],"DR boundaries use rating-derived gains, not total Haste including buffs")
 assert(dr.capRating==2000 and dr.capBonus==126,"Rating-derived hard cap agrees with verified curve")
 if case[1]==2100 then assert(dr.over==100,"Excess rating above hard cap") end
end
ratings[18]=350
local mastery=R.StatDR("mastery",R.StatCurrent("mastery"))
assert(mastery.penalty==10 and mastery.mastery,"78% Mastery effect is not 78 Mastery points for DR")
assert(R.StatDR("avoidance",R.StatCurrent("avoidance")).penalty==40,"Minor stats use their own DR curve")
assert(not R.StatDR("speed",R.StatCurrent("speed")),"Do not invent a Speed cap from an incompatible conversion")
local oldBonus=GetCombatRatingBonus;GetCombatRatingBonus=function()return 999 end
assert(not R.StatDR("haste",R.StatCurrent("haste")),"Changed native API/tuning must disable mismatched DR estimates")
GetCombatRatingBonus=oldBonus
R.SetViewSpec(261);local s=R.StatSummary("haste",261)
assert(s.delta==350-s.reference.rating and s.percentDelta==100-s.reference.percent,"Reference gaps use actual rating and separate percentage points")
assert(not R.StatSummary("mastery",71).current,"Different specs cannot use the current spec's Mastery coefficient")
TEST.version="12.2.0";assert(not R.StatCanCompare(261));TEST.version="12.1.0"
local secret={};issecretvalue=function(value)return value==secret end
local originalRating=GetCombatRating;GetCombatRating=function()return secret end
assert(not R.StatCurrent("crit"),"Restricted values cannot enter arithmetic or formatting")
GetCombatRating=originalRating;issecretvalue=nil
TEST.combat=true;GetCombatRating=function()error("No stat reads during combat")end
assert(not R.StatCurrent("haste"));GetCombatRating=originalRating;TEST.combat=false
R.ScanEquipment();R.UI:Create();R.UI.frame:Show()
for _,size in ipairs({{960,700},{1280,900}}) do
 R.UI.frame:SetSize(unpack(size));R.UI:SetView("stats")
 assert(R.UI.buttons.STATS:GetLeft()>R.UI.buttons.EQUIPMENT:GetRight() and R.UI.buttons.STATS:GetRight()<R.UI.buttons.PREPARATION:GetLeft(),"Stats tab sits between Equipment and Preparation")
 assert(R.UI.statsPane:IsShown() and not R.UI.gearScroll:IsShown() and not R.UI.prepPane:IsShown(),"Stats has an independent pane")
 for spec in pairs(R.Data.specs) do
  R.SetViewSpec(spec);R.UI:Refresh();assert(R.StatProfile(spec),"All 40 specs have source-backed references")
  for _,row in pairs(R.UI.statRows) do
   assert(row:GetLeft()>=R.UI.statsChild:GetLeft() and row:GetRight()<=R.UI.statsChild:GetRight()+.1,"Stat rows fit the scroll child")
   for _,cell in ipairs(row.cells) do assert(cell:GetRight()<=row:GetRight()+.1 and cell:GetBottom()>=row:GetBottom()-.1,"Stat cells fit their rows") end
  end
 end
end
R.SetViewSpec(261);R.UI:Refresh();R.UI.statRows.mastery:Fire("OnEnter")
assert(table.concat(GameTooltip.lines," "):find(R.L("STATS_DR_PENALTY",10),1,true),"Ordinary hover exposes current DR without Shift")
local scans=0;local scan=R.ScanEquipment;R.ScanEquipment=function()scans=scans+1 end;R.equipmentDirty=false
for i=1,50 do R.events:Fire("OnEvent","COMBAT_RATING_UPDATE")end
TEST.Flush();assert(scans==0,"Stat changes refresh without rescanning gear")
TEST.combat=true;R.events:Fire("OnEvent","PLAYER_REGEN_DISABLED");assert(R.UI.statRows.haste.cells[3]:GetText()=="--","Combat hides unavailable current values")
TEST.combat=false;R.events:Fire("OnEvent","PLAYER_REGEN_ENABLED");TEST.Flush();R.ScanEquipment=scan
R.UI:SetView("equipment");assert(not R.UI.statsPane:IsShown(),"Stats does not overlay other tabs")
print("Stats PASS: rating DR/ceilings, Mastery points, buffs, secret/combat guards, 40-spec table layouts, ordinary hover and event-only refresh")
