local R=TEST.R
local function check(value,message)assert(value,message)end
local dungeon={id=159304,acquisition="dungeon",gearSlotID=8,targetIlvl=999,link="item:159304"}
local range=R.GearLevelRange(dungeon)
check(range.min==318 and range.max==334 and not range.ascended,"Dungeon armor targets Myth 1/6 to 6/6, not bare-link or stale ilvl")
check(R.ItemLevel(dungeon,false)==334,"All recommendation ilvl callers use verified target rules")
local weapon={id=237837,crafted=true,gearSlotID=17}
range=R.GearLevelRange(weapon)
check(range.max==331 and range.ascended==338,"Crafted weapon separates maximum quality from Ascendant maximum")
local trinket={id=270164,acquisition="raid",dropSource="Vashnik",gearSlotID=13}
range=R.GearLevelRange(trinket)
check(range.max==334 and range.ascended==340,"Ordinary Myth weapon/neck/trinket supports Ascendant upgrade")
for _,slot in ipairs({1,2,13,16}) do
 range=R.GearLevelRange({id=271875,acquisition="raid",dropSource="Tier Set - Ula'tek",gearSlotID=slot})
 check(range.max==344 and not range.ascended and not range.min,"Elevated raid reward cannot gain another Ascendant upgrade")
end
check(not R.GearLevelRange({id=999999,gearSlotID=8,targetIlvl=999}),"Unverified acquisition must not inherit a made-up target")
check(not R.ItemLevel({id=999999,gearSlotID=8,link="item:999999",targetIlvl=999},false),"Unknown target cannot fall back to base-link ilvl")
local oldVersion=TEST.version;TEST.version="12.2.0"
check(not R.GearLevelRange(dungeon),"Seasonal levels cannot leak into another patch")
TEST.version=oldVersion
local originalShift=IsShiftKeyDown
IsShiftKeyDown=function()return false end
GameTooltip.link=nil
R.UI:ShowItemTooltip(R.UI.frame,dungeon)
check(not GameTooltip.link and table.concat(GameTooltip.lines," "):find("318",1,true) and table.concat(GameTooltip.lines," "):find("334",1,true),"Default BiS tooltip shows target range, never native base stats as max stats")
IsShiftKeyDown=function()return true end
R.UI:ShowItemTooltip(R.UI.frame,dungeon)
check(GameTooltip.link==dungeon.link and table.concat(GameTooltip.lines," "):find(R.L("BASE_STATS_ONLY"),1,true),"Explicit base preview retains native stats and marks their scope")
IsShiftKeyDown=originalShift
local originalInventory=GameTooltip.SetInventoryItem
local usedSlot
GameTooltip.SetInventoryItem=function(_,unit,slot)usedSlot=slot;check(unit=="player","Equipped tooltip unit")end
local current={id=123,slotID=12,link="item:123"}
local row=R.UI:DetailItem(current,"Current copy")
row:Fire("OnEnter")
check(usedSlot==12,"Equipped detail tooltip reads the exact inventory slot, including second ring")
GameTooltip.SetInventoryItem=originalInventory
local known,unknown=0,0
for spec in pairs(R.Data.specs) do
 for _,slot in ipairs(R.SLOTS) do
  local target=R.GetGearTarget(slot.id,spec)
  if target then
   if R.GearLevelRange(target,slot.id) then known=known+1 else unknown=unknown+1 end
   local alternatives=R.GetGearAlternatives(slot.id,spec)
   for _,item in ipairs(alternatives) do
    check(item.gearSlotID==slot.id,"Alternative keeps equipment context for target tooltip")
   end
  end
 end
end
print("Item-level regressions PASS: target ranges, crafted/Ascendant/elevated exceptions, unknown source, patch guard, native equipped tooltip; covered targets "..known..", explicitly unknown "..unknown)
