local _,R=...
-- Source restriction is independent of the player's Raid/M+ activity context.
function R.GearSource() return R.db.gearSource or "overall" end
function R.GetGearCandidates(slotID)
 local overall=R.GetCandidates(slotID,nil,"raid") -- authored all-source guide
 if R.GearSource()=="overall" then return overall end
 if R.SourceCatalogPatch and R.SourceCatalogPatch~=(R.GetDataset() or {}).patch then return {} end
 local wanted=R.GearSource()=="raid" and "raid" or "dungeon"
 local result,seen={},{}
 local lists=wanted=="raid" and {overall,R.GetCandidates(slotID,nil,"mythicplus")} or {R.GetCandidates(slotID,nil,"mythicplus"),overall}
 for _,list in ipairs(lists) do for _,item in ipairs(list) do
  local origin=R.SourceCatalog and R.SourceCatalog[item.id]
  if origin and origin.kind==wanted and not item.crafted and not seen[item.id] then
   result[#result+1]=item;seen[item.id]=true
  end
 end end
 -- Shared ring/trinket populations need two distinct recommendations.
 if (slotID==12 or slotID==14) and #result>1 then
  local other=R.GetGearCandidates(slotID==12 and 11 or 13)[1]
  if other and result[1].id==other.id then local first=table.remove(result,1);result[#result+1]=first end
 end
 return result
end
function R.GetGearTarget(slotID) return R.GetGearCandidates(slotID)[1] end
