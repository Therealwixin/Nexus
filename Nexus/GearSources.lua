local _,R=...
-- Acquisition scope and activity are separate: an M+ playstyle set may contain raid gear.
function R.GearSource() return R.db.gearSource or "overall" end
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
 local scope=R.GetMode()=="raid" and "raid_activity" or "mythicplus_activity"
 for _,set in ipairs(guide.sets) do if set.scope==scope then return set end end
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
  if item and not seen[item.id] then result[#result+1]=item;seen[item.id]=true end
 end
 if scope~="overall" and (slotID==12 or slotID==14) then
  local other=R.GetGearCandidates(slotID==12 and 11 or 13,specID,scope)[1]
  if other then for i=#result,1,-1 do if result[i].id==other.id then table.remove(result,i) end end end
 end
 return result
end
function R.GetGearTarget(slotID,specID,scope) return R.GetGearCandidates(slotID,specID,scope)[1] end
function R.GetGearSummary()
 local guide=R.GetGuideDataset();if not guide then return R.L("NO_DATA") end
 local scope=R.GearSource();local set=scope=="overall" and R.GetGuideSet();local count=0
 for _,slot in ipairs(R.SLOTS) do if R.GetGearTarget(slot.id) then count=count+1 end end
 local title=set and set.name or scope=="raid" and "Raid drops" or "Mythic+ drops"
 return title.." · "..count.." / 16 · Wowhead "..guide.updatedAt:sub(1,10)
end
