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
local function fields(link)
 local out={};for value in (link..":"):gmatch("(.-):") do out[#out+1]=value end;return out
end
local function bonuses(link)
 local f=fields(link);local out={};for i=1,tonumber(f[14]) do out[tonumber(f[14+i])]=true end;return out,f
end
local cases={
 {id=268253,acquisition="raid",dropSource="The Coiled Altar",gearSlotID=15,bonus=13848,level=344},
 {id=239037,acquisition="dungeon",gearSlotID=3,bonus=12854,level=334},
 {id=237828,crafted=true,gearSlotID=8,bonus=13836,level=331},
}
local originalShift=IsShiftKeyDown
for _,item in ipairs(cases) do
 IsShiftKeyDown=function()return false end
 R.UI:ShowItemTooltip(R.UI.frame,item)
 local link=GameTooltip.link;local ids,f=bonuses(link)
 check(ids[item.bonus] and f[10]=="90" and f[2]==tostring(item.id),"Screenshot item uses a max-level variant hyperlink, never an ID-only tooltip")
 if item.crafted then check(ids[12497],"Crafted tooltip includes maximum crafting quality") end
 local fixture
 for _,entry in ipairs(TEST.variantEvidence.cases) do if entry.id==item.id then fixture=entry end end
 check(fixture and fixture.level==item.level and ids[fixture.bonusIDs[1]],"Native preview agrees with recorded live Wowhead tooltip, not a mocked base-level API")
 if item.id==239037 then check(fixture.rank=="6/6" and fixture.nativeTooltip:find("334",1,true),"Exact screenshot shoulder has live verified Myth 6/6 stats") end
 check(R.ItemLevel(item,false)==item.level,"Preview ilvl matches externally verified variant data")
 check(not table.concat(GameTooltip.lines," "):find(R.L("POPULARITY_NOTE"),1,true),"Own tooltips do not repeat WCL/source diagnostics")
 IsShiftKeyDown=function()return true end
 R.UI:ShowItemTooltip(R.UI.frame,item)
 check(GameTooltip.link==link,"Shift never changes the recommendation into a base item")
end
IsShiftKeyDown=originalShift
local converted={id=271511,acquisitionItemID=159337,acquisition="dungeon",gearSlotID=10}
local projected=R.GearPreviewLink(converted)
check(fields(projected)[2]=="159337","Catalyst preview retains the original item stats")
local pair={id=237828,crafted=true,gearSlotID=8,previewBonusIDs={8790,12849,13848}}
local ids=bonuses(R.GearPreviewLink(pair))
check(ids[8790] and not ids[12849] and not ids[13848],"Retain only published stat pairs, never conflicting source level bonuses")
GameTooltip:Hide()
check(not GameTooltip.nexusItemPreview,"Closing Nexus tooltip restores normal external decoration")
local originalInventory=GameTooltip.SetInventoryItem
local usedSlot
GameTooltip.SetInventoryItem=function(_,unit,slot)usedSlot=slot;check(unit=="player","Equipped tooltip unit")end
local current={id=123,slotID=12,link="item:123"}
local row=R.UI:DetailItem(current,"Current copy")
row:Fire("OnEnter")
check(usedSlot==12,"Equipped detail tooltip reads the exact inventory slot, including second ring")
GameTooltip.SetInventoryItem=originalInventory
local oldUpgrade=C_Item.GetItemUpgradeInfo
C_Item.GetItemUpgradeInfo=function()return {currentLevel=1,maxLevel=6,maxItemLevel=334}end
check(R.EquippedUpgradeMaximum(current)==334,"Unfinished equipped item exposes native upgrade cap")
C_Item.GetItemUpgradeInfo=function()return {currentLevel=6,maxLevel=6,maxItemLevel=334}end
check(not R.EquippedUpgradeMaximum(current),"Fully upgraded items do not repeat a redundant maximum line")
C_Item.GetItemUpgradeInfo=oldUpgrade
local known,unknown=0,0
for spec in pairs(R.Data.specs) do
 for _,slot in ipairs(R.SLOTS) do
  local target=R.GetGearTarget(slot.id,spec)
  if target then
   if R.GearLevelRange(target,slot.id) then known=known+1 else unknown=unknown+1 end
   local alternatives=R.GetGearAlternatives(slot.id,spec)
   for _,item in ipairs(alternatives) do
    check(item.gearSlotID==slot.id,"Alternative keeps equipment context for target tooltip")
    check(R.GearPreviewLink(item,slot.id),"Every displayed alternative must have a verified seasonal native preview")
    check(item.id~=158075,"Off-season Heart of Azeroth cannot be presented as a current BiS alternative")
   end
  end
 end
end
print("Item-level regressions PASS: native variant hyperlinks for screenshot items, no Shift/base fallback, crafted quality/stat pairs, Catalyst originals, equipped upgrade caps; covered targets "..known..", explicitly unknown "..unknown)
check(known>600 and unknown==0,"All occupied Overall slots have a seasonal preview")

R.SetViewSpec(261)
for _,slot in ipairs({1,5}) do
 local item=R.GetGearTarget(slot,261,"overall")
 local link=R.GearPreviewLink(item,slot);local ids,f=bonuses(link)
 local fixture
 for _,entry in ipairs(TEST.variantEvidence.cases) do if tostring(entry.id)==f[2] then fixture=entry end end
 check(fixture and fixture.effect and fixture.nativeTooltip:find("Equip:",1,true),"Screenshot source has externally verified passive effect")
 for _,bonus in ipairs(fixture.bonusIDs) do check(ids[bonus],"Source effect bonus must survive maximum-ilvl tooltip construction") end
 R.UI:ShowItemTooltip(R.UI.frame,item,slot)
 check(table.concat(GameTooltip.lines," "):find("Catalyst: ",1,true),"Catalyst conversion uses a supported colon, not an unsupported arrow glyph")
end
R.UI:SetView("equipment")
local savedAlternatives=R.GetGearAlternatives
local savedDetailText=R.UI.DetailText
local emptyMessage,dungeonMessage=0,0
R.UI.DetailText=function(self,text,...)
 if text==R.L("NO_ALTERNATIVES") then emptyMessage=emptyMessage+1 end
 if text==R.L("NO_DUNGEON_ALTERNATIVE") then dungeonMessage=dungeonMessage+1 end
 return savedDetailText(self,text,...)
end
R.GetGearAlternatives=function()return {}end
R.UI:RenderDetail(R.GetGearTarget(1,261),1)
check(emptyMessage==1 and dungeonMessage==0,"No alternatives must be explicit without a duplicate no-dungeon message")
R.UI.DetailText=savedDetailText
R.GetGearAlternatives=savedAlternatives
print("Catalyst source passives, supported conversion label and explicit missing alternatives PASS")
