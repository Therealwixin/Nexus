local _,R=...
-- Acquisition scope and activity are separate: an M+ playstyle set may contain raid gear.
function R.GearSource() return R.GetMode()=="mythicplus" and "mplus_usage" or "overall" end
-- Native instant metadata excludes gems/consumables even if an external feed mislabels them.
function R.IsGearItem(item)
 local api=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
 if api then
  local _,_,_,location=api(item.acquisitionItemID or item.id)
  if not R.IsReadable(location) then return false end
  if location=="" then return false end
 end
 if not R.nonGearGemIDs then
  R.nonGearGemIDs={}
  for _,modes in pairs(R.Data and R.Data.specs or {}) do
   for _,data in pairs(modes) do for _,gem in ipairs(data.gems or {}) do R.nonGearGemIDs[gem.id]=true end end
  end
 end
 return not R.nonGearGemIDs[item.id]
end
-- Activity recommendations include all acquisition sources, including crafts and raids.
function R.GetMPlusGearCandidates(slotID,specID)
 local data=R.GetDataset("mythicplus",specID);local result,seen={},{}
 for _,raw in ipairs(data and data.slots[slotID] or {}) do
  if raw.source=="Murlok.io" and type(raw.count)=="number" and raw.count>0 and not seen[raw.id] then
   local item={};for k,v in pairs(raw) do item[k]=v end
   item.gearSlotID=slotID;item.bisGuide=nil;item.observedAlternative=true
   item.updatedAt=data.updatedAt;item.sourceURL=data.sourceURL
   if R.IsGearItem(item) and R.GearLevelRange(item,slotID) then result[#result+1]=item;seen[item.id]=true end
  end
 end
 table.sort(result,function(a,b)if a.count~=b.count then return a.count>b.count end;return a.id<b.id end)
 if slotID==12 or slotID==14 then
  local first=R.GetMPlusGearCandidates(slotID==12 and 11 or 13,specID)[1]
  if first then for i=#result,1,-1 do if result[i].id==first.id then table.remove(result,i) end end end
 end
 return result
end
function R.GetGuideDataset(specID)
 local data=R.GuideData;local spec=specID or R.ViewSpecID()
 if not data or not spec or not data.specs[spec] then return nil end
 local base=R.GetDataset(nil,spec)
 if not base or base.patch~=data.patch then return nil end
 return data.specs[spec]
end
function R.GetGuideSet(specID)
 local guide=R.GetGuideDataset(specID);if not guide then return end
 for _,set in ipairs(guide.sets) do if set.scope=="overall" then return set end end
 return guide.sets[1]
end
function R.GuideItem(key,specID)
 local spec=specID or R.ViewSpecID();local guide=R.GetGuideDataset(spec);if not guide then return end
 R.guideItems=R.guideItems or {};R.guideItems[spec]=R.guideItems[spec] or {}
 if not R.guideItems[spec][key] then
  local raw=R.GuideData.items[key];if not raw or not R.IsGearItem(raw) then return end
  local item={};for k,v in pairs(raw) do item[k]=v end
  if item.source=="Wowhead" then item.updatedAt=guide.updatedAt;item.guideURL=guide.sourceURL end
  item.journalItemID=item.acquisitionItemID or item.id
  if item.acquisitionItemID then R.RequestItem(item.acquisitionItemID) end
  item.sourceType=item.acquisition;item.shortSource=item.dropSource
  R.guideItems[spec][key]=item
 end
 return R.guideItems[spec][key]
end
function R.GetGearCandidates(slotID,specID,scope)
 scope=scope or R.GearSource();if scope=="mplus_usage" then return R.GetMPlusGearCandidates(slotID,specID) end
 local guide=R.GetGuideDataset(specID);if not guide then return {} end
 local set=scope=="overall" and R.GetGuideSet(specID)
 local slots=set and set.slots or guide.sourceLists[scope];local result={};local seen={}
 for _,key in ipairs(slots and slots[slotID] or {}) do
  local item=R.GuideItem(key,specID)
  if item and R.IsGearItem(item) and not seen[item.id] then item.gearSlotID=slotID;result[#result+1]=item;seen[item.id]=true end
 end
 if scope=="overall" and #result>0 then
  local observed=R.GetDataset("mythicplus",specID)
  for _,raw in ipairs(observed and observed.slots[slotID] or {}) do
   if raw.source=="Murlok.io" and not seen[raw.id] then
    local item={};for k,v in pairs(raw) do item[k]=v end
    item.observedAlternative=true;item.bisGuide=nil;item.gearSlotID=slotID
    item.targetIlvl=nil;item.dropIlvl=nil;item.ilvlBasis=nil
    result[#result+1]=item;seen[item.id]=true
   end
  end
 end
 if scope~="overall" and (slotID==12 or slotID==14) then
  local other=R.GetGearCandidates(slotID==12 and 11 or 13,specID,scope)[1]
  if other then for i=#result,1,-1 do if result[i].id==other.id then table.remove(result,i) end end end
 end
 return result
end
function R.GetGearTarget(slotID,specID,scope) return R.GetGearCandidates(slotID,specID,scope)[1] end
function R.GetGearAlternatives(slotID,specID)
 local guide=R.GetGuideDataset(specID);if not guide then return {} end
 local main=R.GetGearTarget(slotID,specID);local pool,seen={},{}
 local function add(raw)
  if not raw or not R.IsGearItem(raw) then return end
  if main and raw.id==main.id and raw.acquisitionItemID==main.acquisitionItemID then return end
  local item=raw
  if raw.acquisitionItemID and raw.acquisitionItemID~=raw.id then
   item={};for k,v in pairs(raw) do item[k]=v end
   item.id=raw.acquisitionItemID;item.catalystTargetID=raw.id;item.acquisitionItemID=nil;item.catalyst=nil;item.catalystOption=nil
   item.name="Item #"..item.id;item.icon=nil;item.link=nil;item.journalItemID=item.id
  end
  if main and (item.id==main.id or item.id==main.acquisitionItemID) then return end
  if seen[item.id] then
   if item.acquisition=="dungeon" then
    local old=seen[item.id];old.acquisition="dungeon";old.sourceType="dungeon";old.dropSource=item.dropSource;old.catalystTargetID=item.catalystTargetID or old.catalystTargetID
   end
   return
  end
  local copy={};for k,v in pairs(item) do copy[k]=v end
  copy.gearSlotID=slotID
  -- An observed ID can be old/off-season (even Heart of Azeroth appears in
  -- aggregates). Only offer gear with a verified current-season preview.
  if not R.GearLevelRange(copy,slotID) then return end
  seen[copy.id]=copy;pool[#pool+1]=copy
 end
 if R.GearSource()=="mplus_usage" then for _,item in ipairs(R.GetMPlusGearCandidates(slotID,specID)) do add(item) end end
 for _,item in ipairs(R.GetGearCandidates(slotID,specID,"overall")) do if item.source=="Wowhead" then add(item) end end
 for _,key in ipairs(guide.alternatives and guide.alternatives[slotID] or {}) do add(R.GuideItem(key,specID)) end
 for _,scope in ipairs({"mythicplus","raid"}) do for _,key in ipairs(guide.sourceLists[scope][slotID] or {}) do local item=R.GuideItem(key,specID);if item.source=="Wowhead" then add(item) end end end
 for _,item in ipairs(R.GetGearCandidates(slotID,specID,"overall")) do if item.source~="Wowhead" then add(item) end end
 for _,scope in ipairs({"mythicplus","raid"}) do for _,key in ipairs(guide.sourceLists[scope][slotID] or {}) do add(R.GuideItem(key,specID)) end end
 local result,hasDungeon={},false
 for i=1,math.min(4,#pool) do result[i]=pool[i];if pool[i].acquisition=="dungeon" then hasDungeon=true end end
 if not hasDungeon then for _,item in ipairs(pool) do if item.acquisition=="dungeon" then result[math.min(4,#result+1)]=item;break end end end
 for _,item in ipairs(result) do R.RequestItem(item.id) end
 return result
end
function R.GetGearSummary()
 local guide=R.GetGuideDataset();if not guide then return R.L("NO_DATA") end
 local count=0
 local mp=R.GearSource()=="mplus_usage" and R.GetDataset("mythicplus")
 local source=mp or guide
 for _,slot in ipairs(R.SLOTS) do if R.GetGearTarget(slot.id) then count=count+1 end end
 local title=mp and R.L("MPLUS_GEAR_TITLE") or R.L("RAID_GEAR_TITLE")
 return title.." · "..count.." / 16 · "..(mp and "Murlok.io " or "Wowhead ")..source.updatedAt:sub(1,10).." · "..R.L("CHECKED").." "..(source.retrievedAt or source.updatedAt):sub(1,10)
end
function R.GetGearEvidence(item,slotID,specID)
 local guide=R.GetGuideDataset(specID);if not guide or not item then return {} end
 local result={};local base=item.acquisitionItemID or item.id
 local function same(raw)return raw and (raw.acquisitionItemID or raw.id)==base end
 local wowhead=false
 for _,set in ipairs(guide.sets) do for _,key in ipairs(set.slots[slotID] or {}) do if same(R.GuideData.items[key]) then wowhead=true end end end
 for _,scope in ipairs({"raid","mythicplus"}) do for _,key in ipairs(guide.sourceLists[scope][slotID] or {}) do local raw=R.GuideData.items[key];if raw.source=="Wowhead" and same(raw) then wowhead=true end end end
 if wowhead then result[#result+1]={source="Wowhead",kind="guide",url=guide.sourceURL,updatedAt=guide.updatedAt,retrievedAt=guide.retrievedAt} end
 local icy=false
 for _,key in ipairs(guide.alternatives and guide.alternatives[slotID] or {}) do if same(R.GuideData.items[key]) then icy=true end end
 if icy then result[#result+1]={source="Icy Veins",kind="guide",url=guide.alternativeGuideURL,updatedAt=guide.alternativeGuideUpdatedAt,retrievedAt=guide.alternativeGuideCheckedAt or guide.retrievedAt} end
 local mp=R.GetDataset("mythicplus",specID);local count,samples
 for _,raw in ipairs(mp and mp.slots[slotID] or {}) do if same(raw) and raw.source=="Murlok.io" and raw.count and (not count or raw.count>count) then count=raw.count;samples=raw.sampleSize or mp.sampleSize end end
 if count and samples then result[#result+1]={source="Murlok.io",kind="observation",url=mp.sourceURL,updatedAt=mp.updatedAt,retrievedAt=mp.retrievedAt or mp.updatedAt,count=count,sampleSize=samples} end
 return result
end
