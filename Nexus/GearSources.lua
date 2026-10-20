local _,R=...
-- Acquisition scope and activity are separate: an M+ playstyle set may contain raid gear.
function R.GearSource() return "overall" end
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
  local raw=R.GuideData.items[key];if not raw then return end
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
 local guide=R.GetGuideDataset(specID);if not guide then return {} end
 scope=scope or R.GearSource();local set=scope=="overall" and R.GetGuideSet(specID)
 local slots=set and set.slots or guide.sourceLists[scope];local result={};local seen={}
 for _,key in ipairs(slots and slots[slotID] or {}) do
  local item=R.GuideItem(key,specID)
  if item and not seen[item.id] then item.gearSlotID=slotID;result[#result+1]=item;seen[item.id]=true end
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
 local main=R.GetGearTarget(slotID,specID,"overall");local pool,seen={},{}
 local function add(raw)
  if not raw then return end
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
 local scope=R.GearSource();local set=scope=="overall" and R.GetGuideSet();local count=0
 for _,slot in ipairs(R.SLOTS) do if R.GetGearTarget(slot.id) then count=count+1 end end
 local title="Overall BiS"
 return title.." · "..count.." / 16 · Wowhead "..guide.updatedAt:sub(1,10).." · "..R.L("CHECKED").." "..guide.retrievedAt:sub(1,10)
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
function R.GetWCLEvidence(itemID,specID,mode)
 local data=R.WCLData
 if not data or data.schema~=2 or not R.GuideData or data.patch~=R.GuideData.patch then return end
 local spec=data.specs[specID or R.ViewSpecID()]
 local scope=R.GearSource();mode=mode or (scope=="overall" and R.GetMode() or scope)
 local context=spec and spec[mode]
 if not context or not context.eligible or context.coveredEncounterCount~=context.expectedEncounterCount then return end
 local count=context and context.items[tostring(itemID)]
 if count then return context,count end
end
