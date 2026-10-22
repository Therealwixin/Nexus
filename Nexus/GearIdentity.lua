local _,R=...
local function positive(value)return R.IsReadable(value) and type(value)=="number" and value>0 end

-- Native upgrade data describes the track even at 1/6. Never infer a track
-- from the current item level or from localized tooltip text.
function R.UpgradeTrackInfo(item)
 if not item or not item.link or not R.IsReadable(item.link) then return end
 if C_Item and C_Item.GetItemUpgradeInfo then
  local ok,info=pcall(C_Item.GetItemUpgradeInfo,item.link)
  if ok and info and R.IsReadable(info) and positive(info.maxItemLevel) then
   return {maximum=info.maxItemLevel,id=positive(info.trackStringID) and info.trackStringID or nil,
    name=R.IsReadable(info.trackString) and type(info.trackString)=="string" and info.trackString or nil,origin="native"}
  end
 end
 return R.UpgradeTrackFromBonuses(item)
end
local function sameTrack(a,b)
 if not a or not b or a.maximum~=b.maximum then return false end
 if a.id and b.id then return a.id==b.id end
 -- A verified seasonal ceiling is independent of the localized rank label.
 return true
end
local function profile(link)
 local api=C_Item and C_Item.GetItemStats or GetItemStats
 if not link or not api then return end
 local ok,stats=pcall(api,link);if not ok or not stats or not R.IsReadable(stats) then return end
 local out,total={},0
 for _,key in ipairs({"ITEM_MOD_CRIT_RATING_SHORT","ITEM_MOD_HASTE_RATING_SHORT","ITEM_MOD_MASTERY_RATING_SHORT","ITEM_MOD_VERSATILITY"}) do
  local value=stats[key];if positive(value) then out[key]=value;total=total+value end
 end
 if total==0 then return end
 for key,value in pairs(out) do out[key]=value/total end
 return out
end
local function sameProfile(a,b)
 if not a or not b then return end
 for key,value in pairs(a) do if not b[key] or math.abs(value-b[key])>.025 then return false end end
 for key in pairs(b) do if not a[key] then return false end end
 return true
end
local function expectedLink(item,slot)
 return R.GearPreviewLink(item,slot)
end
local function expectedTrack(item,slot)
 local range=R.GearLevelRange(item,slot)
 local link=expectedLink(item,slot)
 if range and range.track=="ELEVATED_ILVL" then
  local ordinary={};for key,value in pairs(item) do ordinary[key]=value end
  ordinary.acquisition="dungeon";ordinary.sourceType="dungeon"
  link=expectedLink(ordinary,slot);range=R.GearLevelRange(ordinary,slot)
 end
 local native=link and R.UpgradeTrackInfo({link=link})
 if native then return native end
 -- Maximum-rank generated previews may not expose native upgrade metadata.
 -- Use only the already verified seasonal target ceiling, never current ilvl.
 if range and range.track=="MYTH_ILVL_RANGE" then return {maximum=range.max} end
end
R.RecommendationUpgradeTrack=expectedTrack
local function offpieceKnown(item,current,slot,specID)
 local catalog=R.CatalystOffpieces
 local rules=R.Data and R.Data.upgradeRules
 local result=catalog and catalog.items[current.id]
 local spec=R.SpecInfo(specID or R.ViewSpecID())
 local range=R.GearLevelRange(item,slot)
 if not result or not rules or catalog.patch~=rules.patch or not range or
  (range.kind~="raid" and range.kind~="dungeon") or not spec or
  result.classID~=spec.classID or result.slot~=slot then return false end
 local api=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
 if not api then return false end
 local ok,_,_,_,location,_,classID,armor=pcall(api,item.acquisitionItemID or item.id)
 local locations={[6]="INVTYPE_WAIST",[8]="INVTYPE_FEET",[9]="INVTYPE_WRIST",[15]="INVTYPE_CLOAK"}
 return ok and R.IsReadable(location) and R.IsReadable(classID) and R.IsReadable(armor) and
  location==locations[slot] and classID==4 and armor==result.armor
end
local function conversionKnown(item,current,slot,specID)
 local source=item.acquisitionItemID or item.id
 if item.acquisitionItemID and current.id==item.id then return true end
 if item.catalystTargetID and current.id==item.catalystTargetID then return true end
 if offpieceKnown(item,current,slot,specID) then return true end
 local guide=R.GetGuideDataset(specID);if not guide then return false end
 local function check(keys)
  for _,key in ipairs(keys or {}) do
   local raw=R.GuideData.items[key]
   if raw and ((raw.acquisitionItemID==source and raw.id==current.id) or
    (raw.id==source and raw.catalystTargetID==current.id)) then return true end
  end
 end
 for _,set in ipairs(guide.sets or {}) do if check(set.slots and set.slots[slot]) then return true end end
 for _,slots in pairs(guide.sourceLists or {}) do if check(slots[slot]) then return true end end
 return check(guide.alternatives and guide.alternatives[slot]) or false
end
function R.CatalystEquivalent(item,current,slot,specID)
 if not item or not current or not current.link or not conversionKnown(item,current,slot,specID) then return false end
 local link=expectedLink(item,slot);if not link then return false end
 -- Elevated raid rewards (344) are a separate best-obtainable preview, not
 -- the ordinary Myth upgrade ceiling. Compare converted copies with the
 -- same source on the ordinary Myth track, independent of current rank.
 if not sameTrack(R.UpgradeTrackInfo(current),expectedTrack(item,slot)) then return false end
 -- Equal secondary stats must not erase a distinct source item's passive.
 if item.previewEffectBonusIDs and #item.previewEffectBonusIDs>0 then
  local body=current.link:match("(item:[^|]+)");local fields={}
  if body then for field in (body..":"):gmatch("(.-):") do fields[#fields+1]=field end end
  local count=tonumber(fields[14]);if not count or count<0 or count>100 then return false end
  local bonuses={};for i=15,14+count do bonuses[tonumber(fields[i]) or 0]=true end
  for _,id in ipairs(item.previewEffectBonusIDs) do if not bonuses[id] then return false end end
 end
 return sameProfile(profile(current.link),profile(link))==true
end

function R.FindCatalystRecommendation(current,specID)
 for _,slot in ipairs(R.SLOTS) do
  local item=R.GetGearTarget(slot.id,specID,"mplus_usage")
  if item and R.CatalystEquivalent(item,current,slot.id,specID) then return item,slot.id end
 end
end

-- Aggregate Murlok rows retain the tier ID but not the guide's Catalyst flag.
-- Such IDs can still have several different secondary-stat allocations.
local function statSensitive(item)
 if item.catalyst or item.catalystOption then return true end
 for _,raw in pairs(R.GuideData and R.GuideData.items or {}) do
  if raw.id==item.id and raw.catalyst and raw.acquisitionItemID then return true end
 end
 return false
end

function R.GearVariantStatus(item,current,slot)
 if not statSensitive(item) then return nil end
 local link=expectedLink(item,slot)
 local expected=profile(link) or profile(item.acquisitionItemID)
 local match=sameProfile(current and profile(current.link),expected)
 if match==nil then return "TIER_STATS_UNVERIFIED" end
 if not match then return "TIER_STATS_DIFFERENT" end
 local actualTrack=R.UpgradeTrackInfo(current)
 local targetTrack=expectedTrack(item,slot)
 if actualTrack and targetTrack and not sameTrack(actualTrack,targetTrack) then return "TIER_TRACK_DIFFERENT" end
 return "MATCHED"
end

function R.GearIdentityDebugText()
 local function describe(value)
  if value==nil then return "unavailable" end
  local fields={}
  for key,v in pairs(value) do if R.IsReadable(v) then fields[#fields+1]=tostring(key).."="..tostring(v) end end
  table.sort(fields);return table.concat(fields,", ")
 end
 local out={"Gear identity diagnostics (viewed spec "..tostring(R.ViewSpecID())..")"}
 for _,slot in ipairs(R.SLOTS) do
  local target=R.GetGearTarget(slot.id)
  local current=R.scan and R.scan.equipped[slot.id]
  if target and current then
   local preview=expectedLink(target,slot.id)
   out[#out+1]=slot.key..": target="..target.id..", equipped="..current.id..", state="..R.GearOwnership(target,slot.id)
   out[#out+1]=" actual track: "..describe(R.UpgradeTrackInfo(current))
   out[#out+1]=" target track: "..describe(expectedTrack(target,slot.id))
   out[#out+1]=" actual stats: "..describe(profile(current.link))
   out[#out+1]=" target stats: "..describe(profile(preview))
   out[#out+1]=" conversion known: "..tostring(conversionKnown(target,current,slot.id,R.ViewSpecID()))
   out[#out+1]=" actual link: "..tostring(current.link):gsub("|","||")
   out[#out+1]=" target link: "..tostring(preview)
  end
 end
 return table.concat(out,"\n")
end

-- An item's name/ID changes at the Catalyst; native source stats and track
-- identify its converted copy. Re-read the current guide mapping after updates.
function R.GearOwnership(item,slotID,specID)
 if not item then return "NO_DATA" end
 local state=R.Ownership(item.id,slotID)
 if state=="MISSING" then
  for _,slot in ipairs(R.PAIRS[slotID] or {slotID}) do
   local current=R.scan and R.scan.equipped[slot]
   if R.CatalystEquivalent(item,current,slotID,specID) then return "EQUIPPED" end
  end
  for _,current in ipairs(R.scan and R.scan.bagItems or {}) do
   if R.CatalystEquivalent(item,current,slotID,specID) then return "IN_BAGS" end
  end
  return state
 end
 if not statSensitive(item) then return state end
 local copies={}
 for _,current in pairs(R.scan and R.scan.equipped or {}) do
  if current.id==item.id then copies[#copies+1]={item=current,state=current.slotID==slotID and "EQUIPPED" or "OWNED"} end
 end
 for _,current in ipairs(R.scan and R.scan.bagItems or {}) do
  if current.id==item.id then copies[#copies+1]={item=current,state="IN_BAGS"} end
 end
 local status="TIER_STATS_UNVERIFIED"
 for _,copy in ipairs(copies) do
  local variant=R.GearVariantStatus(item,copy.item,slotID)
  if variant=="MATCHED" then return copy.state end
  if variant and variant~="TIER_STATS_UNVERIFIED" then status=variant end
 end
 return status
end

function R.PrimaryCopySatisfied(item,current,slot,specID)
 if not item or not current then return false end
 if current.id~=item.id then return R.CatalystEquivalent(item,current,slot,specID) end
 local actual=R.UpgradeTrackInfo(current)
 local target=expectedTrack(item,slot)
 if actual and target then return actual.maximum>=target.maximum end
 local range=R.GearLevelRange(item,slot)
 local level=R.ItemLevel(current,true)
 return range and level and level>=range.max or false
end
