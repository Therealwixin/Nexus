local R=TEST.R
local old={scan=R.scan,upgrade=C_Item.GetItemUpgradeInfo,stats=C_Item.GetItemStats,level=R.ItemLevel,
 target=R.GetGearTarget,alternatives=R.GetGearAlternatives,range=R.GearLevelRange}
local source={id=239037,acquisition="dungeon",gearSlotID=3}
local preview=R.GearPreviewLink(source,3)
local current={id=271454,slotID=3,link="item:271454:converted"}
local haste="ITEM_MOD_HASTE_RATING_SHORT";local crit="ITEM_MOD_CRIT_RATING_SHORT"
local tracks={
 [preview]={currentLevel=6,maxLevel=6,maxItemLevel=334,trackStringID=42,trackString="Localized Myth"},
 [current.link]={currentLevel=4,maxLevel=6,maxItemLevel=334,trackStringID=42,trackString="Localized Myth"}}
local stats={[preview]={[haste]=100,[crit]=200},[current.link]={[haste]=90,[crit]=180}}
C_Item.GetItemUpgradeInfo=function(link)return tracks[link] end
C_Item.GetItemStats=function(link)return stats[link] end
R.scan={equipped={[3]=current},bags={},bagItems={}}
assert(R.CatalystEquivalent(source,current,3,71),"Known current-spec converted ID with same stats/track/cap must match the original")
assert(R.GearOwnership(source,3,71)=="EQUIPPED","Equipment must recognize the converted BiS source")
tracks[current.link].currentLevel=1
assert(R.CatalystEquivalent(source,current,3,71),"Upgrade progress must not change Catalyst identity")
tracks[current.link].maxItemLevel=327
assert(not R.CatalystEquivalent(source,current,3,71),"Hero and Myth copies must not be equivalent")
tracks[current.link].maxItemLevel=334;tracks[current.link].trackStringID=43
assert(not R.CatalystEquivalent(source,current,3,71),"Different native track IDs must not match even with equal caps")
tracks[current.link].trackStringID=42
stats[current.link]={[haste]=200,[crit]=100}
assert(not R.CatalystEquivalent(source,current,3,71),"Different stat proportions must not match")
stats[current.link]={[haste]=90,[crit]=180}
assert(not R.CatalystEquivalent({id=999,acquisition="dungeon",gearSlotID=3},current,3,71),"Equal stats alone cannot make an unrelated item BiS")
local native=tracks[current.link];tracks[current.link]=nil
assert(not R.CatalystEquivalent(source,current,3,71),"Unknown track is not proof of identity")
tracks[current.link]=native
R.scan.equipped={};R.scan.bagItems={current}
assert(R.GearOwnership(source,3,71)=="IN_BAGS","Converted copies in bags are recognized too")
R.scan.equipped={[3]=current};R.scan.bagItems={}
source.previewEffectBonusIDs={14049}
assert(not R.CatalystEquivalent(source,current,3,71),"Matching stats cannot substitute for missing source passive evidence")
source.previewEffectBonusIDs=nil

-- The reported DH case: the primary Myth weapon is 328 / 4 of 6, whereas
-- the offered alternative preview is 334 / 6 of 6 on that same track.
local main={id=501,acquisition="dungeon",gearSlotID=16}
local alt={id=502,acquisition="dungeon",gearSlotID=16}
local weapon={id=501,slotID=16,link="item:501:current"}
local mainLink=R.GearPreviewLink(main,16);local altLink=R.GearPreviewLink(alt,16)
tracks[mainLink]={currentLevel=6,maxLevel=6,maxItemLevel=334,trackStringID=42}
tracks[altLink]={currentLevel=6,maxLevel=6,maxItemLevel=334,trackStringID=42}
tracks[weapon.link]={currentLevel=4,maxLevel=6,maxItemLevel=334,trackStringID=42}
R.ItemLevel=function(item)return item==weapon and 328 or old.level(item,true) end
R.GetGearTarget=function(slot)return slot==16 and main end
R.GetGearAlternatives=function(slot)return slot==16 and {alt} or {} end
R.scan={equipped={[16]=weapon},bags={},bagItems={}}
assert(R.PrimaryCopySatisfied(main,weapon,16,1480),"Myth 4/6 primary already satisfies the desired track")
assert(#R.DungeonAlerts:CollectEntries({[502]=true},1480)==0,"No alternative popup for unfinished Myth primary")
tracks[weapon.link].maxItemLevel=327;tracks[weapon.link].trackStringID=41
assert(#R.DungeonAlerts:CollectEntries({[502]=true},1480)==1,"A lower-track weapon must not suppress a Myth alternative")
tracks[weapon.link].maxItemLevel=334;tracks[weapon.link].trackStringID=42
main={id=503,crafted=true,gearSlotID=17};weapon={id=503,slotID=17,link="item:503:crafted"}
R.ItemLevel=function(item)return item==weapon and 331 or old.level(item,true) end
R.GetGearTarget=function(slot)return slot==17 and main end
R.GetGearAlternatives=function(slot)return slot==17 and {{id=502,acquisition="dungeon",gearSlotID=17}} or {} end
R.scan.equipped={[17]=weapon}
assert(#R.DungeonAlerts:CollectEntries({[502]=true},1480)==0,"An equipped maximum-quality crafted primary suppresses off-hand alternatives")

-- Primary popup ownership uses the same Catalyst identity as Equipment.
R.GetGearTarget=function(slot)return slot==3 and source end
R.GetGearAlternatives=function()return {} end
R.scan={equipped={[3]=current},bags={},bagItems={}}
assert(#R.DungeonAlerts:CollectEntries({[239037]=true},71)==0,"Converted BiS must not be requested again in an instance")
local tooltipItem,oldByID,oldIsTarget,oldTooltipSpec=GameTooltip.GetItem,R.ItemByID,R.IsTarget,R.tooltipSpecID
GameTooltip.GetItem=function()return "Converted tier",current.link end
R.ItemByID=function()end;R.IsTarget=function()return false end;R.tooltipSpecID=71
local wasPreview=GameTooltip.nexusItemPreview;GameTooltip.nexusItemPreview=nil
GameTooltip:ClearLines();R.DecorateTooltip(GameTooltip,{id=current.id})
assert(table.concat(GameTooltip.lines," "):find(R.L("DUNGEON_BIS_CATALYST"),1,true),"Native converted-item tooltip retains the primary recommendation label")
GameTooltip.nexusItemPreview=wasPreview
GameTooltip.GetItem,R.ItemByID,R.IsTarget,R.tooltipSpecID=tooltipItem,oldByID,oldIsTarget,oldTooltipSpec
local matched,slot=R.FindCatalystRecommendation(current,71)
assert(matched==source and slot==3,"Native tooltip lookup resolves the converted original recommendation")

-- Reported non-tier Catalyst belt: source 344, converted Myth 2/6 at 321.
-- The guide has no explicit source -> off-piece mapping for this slot.
local belt={id=268256,acquisition="raid",dropSource="The Coiled Altar",gearSlotID=6}
local cinch={id=271534,slotID=6,link="item:271534:myth2"}
local elevatedLink=R.GearPreviewLink(belt,6)
local ordinaryLink=R.GearPreviewLink({id=belt.id,acquisition="dungeon",gearSlotID=6},6)
assert(elevatedLink~=ordinaryLink,"Regression must exercise 344 raid versus ordinary Myth previews")
local instant=C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant=function(id)
 if id==268256 then return id,"Armor","Leather","INVTYPE_WAIST",123,4,2 end
 return instant(id)
end
local mastery="ITEM_MOD_MASTERY_RATING_SHORT"
stats[elevatedLink]={[haste]=49,[mastery]=108}
stats[cinch.link]={[haste]=45,[mastery]=98}
tracks[elevatedLink]=nil -- Elevated rewards need not expose an upgrade track.
tracks[ordinaryLink]={currentLevel=6,maxLevel=6,maxItemLevel=334,trackStringID=42}
tracks[cinch.link]={currentLevel=2,maxLevel=6,maxItemLevel=334,trackStringID=42}
R.scan={equipped={[6]=cinch},bags={},bagItems={}}
R.GetGearTarget=function(slot)return slot==6 and belt end
assert(R.GearOwnership(belt,6,1480)=="EQUIPPED","Reported Myth 2/6 Catalyst belt is owned despite elevated 344 recommendation")
tracks[ordinaryLink]=nil
assert(R.GearOwnership(belt,6,1480)=="EQUIPPED","A max-rank generated preview without native upgrade metadata must not hide a real Myth copy")
assert(R.PrimaryCopySatisfied(belt,cinch,6,1480),"Unfinished converted Myth belt satisfies the primary track")
assert(#R.DungeonAlerts:CollectEntries({[268256]=true},1480)==0,"Converted belt is not requested again by instance alerts")
local found,foundSlot=R.FindCatalystRecommendation(cinch,1480)
assert(found==belt and foundSlot==6,"Native tooltip resolves the non-tier converted belt")
assert(not R.CatalystEquivalent(belt,cinch,6,71),"A different class's Catalyst appearance is not equivalent")
assert(not R.CatalystEquivalent(belt,cinch,9,1480),"A different armor slot is not equivalent")
tracks[cinch.link].maxItemLevel=327;tracks[cinch.link].trackStringID=41
assert(not R.CatalystEquivalent(belt,cinch,6,1480),"Hero off-piece cannot satisfy the Myth recommendation")
tracks[cinch.link].maxItemLevel=334;tracks[cinch.link].trackStringID=42
stats[cinch.link]={[haste]=98,[mastery]=45}
assert(not R.CatalystEquivalent(belt,cinch,6,1480),"Same class/slot with different stat allocation is not equivalent")
stats[cinch.link]={[haste]=45,[mastery]=98}
R.scan.equipped={};R.scan.bagItems={cinch}
assert(R.GearOwnership(belt,6,1480)=="IN_BAGS","Non-tier converted bag copies are recognized")
C_Item.GetItemInfoInstant=function(id)
 if id==268256 then return id,"Armor","Plate","INVTYPE_WAIST",123,4,4 end
 return instant(id)
end
assert(not R.CatalystEquivalent(belt,cinch,6,1480),"Matching stats on a different armor type cannot match")
local classes,count={},0
for id,row in pairs(R.CatalystOffpieces.items) do
 count=count+1;classes[row.classID]=true
 assert(id>0 and ({[6]=true,[8]=true,[9]=true,[15]=true})[row.slot],"Off-piece catalog contains only the four non-tier slots")
end
local classCount=0;for _ in pairs(classes) do classCount=classCount+1 end
assert(count==52 and classCount==13,"All 13 classes have four verified off-pieces")
C_Item.GetItemInfoInstant=instant

-- Actual Murlok recommendations have no Catalyst flag. ID equality must not
-- bypass the secondary-stat check for known tier items.
local chest=old.target(5,1480,"mplus_usage")
assert(chest.id==271540 and not chest.catalyst and not chest.catalystOption,"Regression uses the unannotated aggregate tier recommendation")
local chestLink=R.GearPreviewLink(chest,5)
local worn={id=chest.id,slotID=5,link="item:271540:hero-converted"}
stats[chestLink]={[haste]=138,ITEM_MOD_VERSATILITY=63}
stats[worn.link]={[crit]=112,ITEM_MOD_VERSATILITY=79}
R.scan={equipped={[5]=worn},bags={},bagItems={}}
assert(R.GearOwnership(chest,5,1480)=="TIER_STATS_DIFFERENT","Same tier ID with wrong stats must not show Equipped")
local nativeGetItem,tooltipSpec,previewFlag=GameTooltip.GetItem,R.tooltipSpecID,GameTooltip.nexusItemPreview
GameTooltip.GetItem=function()return chest.name,worn.link end
R.tooltipSpecID=1480;GameTooltip.nexusItemPreview=nil
GameTooltip:ClearLines();R.DecorateTooltip(GameTooltip,{id=chest.id})
assert(table.concat(GameTooltip.lines," "):find(R.L("TIER_STATS_DIFFERENT"),1,true),"Native same-ID tooltip must warn about the actual wrong-stat copy")
GameTooltip.GetItem,R.tooltipSpecID,GameTooltip.nexusItemPreview=nativeGetItem,tooltipSpec,previewFlag
R.GetGearTarget=function(slot)return slot==5 and chest end
assert(#R.DungeonAlerts:CollectEntries({[chest.id]=true},1480)==1,"A wrong-stat tier copy must not suppress its recommended drop")
stats[worn.link]={[haste]=nil,ITEM_MOD_VERSATILITY=79}
assert(R.GearOwnership(chest,5,1480)=="TIER_STATS_DIFFERENT","An incomplete stat pair must not match")
stats[worn.link]=nil
assert(R.GearOwnership(chest,5,1480)=="TIER_STATS_UNVERIFIED","Unloaded tier stats must not confirm an ID-only match")
stats[worn.link]={[haste]=124,ITEM_MOD_VERSATILITY=57}
tracks[worn.link]={currentLevel=2,maxLevel=6,maxItemLevel=334,trackStringID=42}
tracks[chestLink]=nil
assert(R.GearOwnership(chest,5,1480)=="EQUIPPED","Correct tier stat allocation matches without synthetic preview upgrade metadata")
tracks[worn.link].maxItemLevel=321
assert(R.GearOwnership(chest,5,1480)=="TIER_TRACK_DIFFERENT","Hero copy with correct stats remains a different target track")
R.scan.equipped={};R.scan.bags={[chest.id]=1};R.scan.bagItems={worn}
stats[worn.link]={[crit]=112,ITEM_MOD_VERSATILITY=79}
assert(R.GearOwnership(chest,5,1480)=="TIER_STATS_DIFFERENT","A wrong-stat copy in bags cannot confirm the recommendation either")
tracks[worn.link].maxItemLevel=334;stats[worn.link]={[haste]=124,ITEM_MOD_VERSATILITY=57}
assert(R.GearOwnership(chest,5,1480)=="IN_BAGS","A verified correct bag variant is recognized")
assert(R.GearIdentityDebugText():find("Gear identity diagnostics",1,true),"Existing debug command includes native comparison diagnostics")

-- Exact links exported by the live client, which returned no upgrade info
-- for ANY equipped item. Do not fabricate a successful native API here.
local fixture=TEST.liveCatalyst
local previousVersion=TEST.version
TEST.version="12.1.5";C_Item.GetItemUpgradeInfo=nil
local liveBelt=fixture.waist
local parsed=R.ParseLink(liveBelt.link)
assert(parsed.bonusIDs[1]==12850 and parsed.modifiers[64]==268256,"Real live link parses bonuses and original source modifier without field offsets")
local liveTrack=R.UpgradeTrackInfo(liveBelt)
assert(liveTrack and liveTrack.maximum==334 and liveTrack.rank==2 and liveTrack.name=="Myth" and liveTrack.origin=="bonus","Live Myth 2/6 is recognized even with no native upgrade API")
local heroTrack=R.UpgradeTrackInfo(fixture.chest)
assert(heroTrack and heroTrack.maximum==321 and heroTrack.name=="Hero","Live Hero 6/6 must remain distinct from Myth 2/6 at the same ilvl")
C_Item.GetItemInfoInstant=function(id)
 if id==268256 then return id,"Armor","Leather","INVTYPE_WAIST",123,4,2 end
 return instant(id)
end
stats[liveBelt.link]=liveBelt.stats;stats[elevatedLink]=liveBelt.targetStats
R.scan={equipped={[6]={id=liveBelt.id,slotID=6,link=liveBelt.link}},bags={},bagItems={}}
R.GetGearTarget=function(slot)return slot==6 and belt end
assert(R.GearOwnership(belt,6,1480)=="EQUIPPED","Exact reported belt is equipped with all native upgrade responses unavailable")
assert(#R.DungeonAlerts:CollectEntries({[268256]=true},1480)==0,"Exact live Catalyst belt does not generate an instance alert")
R.scan={equipped={[5]={id=fixture.chest.id,slotID=5,link=fixture.chest.link}},bags={},bagItems={}}
stats[fixture.chest.link]=fixture.chest.stats;stats[chestLink]=fixture.chest.targetStats
R.GetGearTarget=function(slot)return slot==5 and chest end
assert(R.GearOwnership(chest,5,1480)=="TIER_STATS_DIFFERENT","Exact live wrong-stat chest remains rejected with no native upgrade info")
local ascended=R.UpgradeTrackInfo(fixture.weapon)
assert(ascended and ascended.name=="Myth" and ascended.maximum==340,"Live ascended Myth weapon is not confused with an unknown track")
local liveMain=old.target(16,1480,"mplus_usage")
local liveWeapon={id=fixture.weapon.id,slotID=16,link=fixture.weapon.link}
assert(R.PrimaryCopySatisfied(liveMain,liveWeapon,16,1480),"Exact live Myth weapon satisfies the desired track with no native API")
R.scan={equipped={[16]=liveWeapon},bags={},bagItems={}}
R.GetGearTarget=function(slot)return slot==16 and liveMain end
R.GetGearAlternatives=function(slot)return slot==16 and {{id=273778,acquisition="dungeon",gearSlotID=16}} or {} end
assert(#R.DungeonAlerts:CollectEntries({[273778]=true},1480)==0,"Unavailable native API cannot cause the reported DH weapon alternative popup to return")
local nativeAPI=C_Item.GetItemUpgradeInfo
C_Item.GetItemUpgradeInfo=function()return {maxItemLevel=999,trackStringID=1} end
assert(R.UpgradeTrackInfo(liveBelt).maximum==999,"Available native upgrade data takes precedence over fallback")
C_Item.GetItemUpgradeInfo=nativeAPI
local damaged={link=liveBelt.link:gsub("12850","999999")}
assert(not R.UpgradeTrackInfo(damaged),"Unknown bonus must not inherit a track from the current item level")
damaged.link=liveBelt.link:gsub("12850","12846"):gsub("13334","12850")
assert(not R.UpgradeTrackInfo(damaged),"Contradictory known tracks must not produce an invented match")
damaged.link=liveBelt.link:gsub(":5:12850",":500:12850")
assert(not R.UpgradeTrackInfo(damaged),"Malformed bonus count cannot certify a track")
TEST.version="12.2.0"
assert(not R.UpgradeTrackInfo(liveBelt),"Verified seasonal bonus fallback cannot leak into another season patch")
TEST.version=previousVersion;C_Item.GetItemInfoInstant=instant
R.scan=old.scan;C_Item.GetItemUpgradeInfo=old.upgrade;C_Item.GetItemStats=old.stats;R.ItemLevel=old.level
R.GetGearTarget,R.GetGearAlternatives,R.GearLevelRange=old.target,old.alternatives,old.range
print("Gear identity PASS: Catalyst mapping, 13-class off-pieces, reported Myth 2/6 belt vs 344 preview, stats/track guards, bag copies, native tooltip and instance alerts")
