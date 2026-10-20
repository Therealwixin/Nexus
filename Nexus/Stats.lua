local _,R=...
R.STAT_KEYS={"crit","haste","mastery","versatility","avoidance","leech","speed"}
local indices={crit=9,haste=18,mastery=26,versatility=29,avoidance=21,leech=17,speed=14}
local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok and R.IsReadable(value) and type(value)=="number" and value==value and value>=0 and value<1e9 then return value end
end
function R.StatProfile(specID)
 local dataset=R.GetDataset("mythicplus",specID or R.ViewSpecID())
 local profile=dataset and dataset.statProfile
 if profile and profile.patch==dataset.patch then return profile end
end
function R.StatCurrent(key)
 if InCombatLockdown() then return end
 local index=indices[key];local rating=read(GetCombatRating,index)
 if rating==nil then return end
 local bonus=read(GetCombatRatingBonus,index);local percent
 if key=="crit" then
  local melee=read(GetCritChance);local ranged=read(GetRangedCritChance);local spell=read(GetSpellCritChance,2)
  for school=3,7 do local p=read(GetSpellCritChance,school);if p and (not spell or p<spell) then spell=p end end
  if melee or ranged or spell then
   percent=math.max(melee or 0,ranged or 0,spell or 0)
   index=spell and spell==percent and 11 or ranged and ranged==percent and 10 or 9
   rating=read(GetCombatRating,index);bonus=read(GetCombatRatingBonus,index)
   if not rating then return end
  end
 elseif key=="haste" then percent=read(GetHaste)
 elseif key=="mastery" then percent=read(GetMasteryEffect)
 elseif key=="versatility" then local flat=read(GetVersatilityBonus,index);if bonus and flat then percent=bonus+flat end
 elseif key=="avoidance" then percent=read(GetAvoidance)
 elseif key=="leech" then percent=read(GetLifesteal)
 elseif key=="speed" then percent=read(GetSpeed) end
 return {rating=rating,percent=percent,bonus=bonus,index=index}
end
function R.StatCanCompare(specID)
 return specID==R.SpecID() and read(UnitLevel,"player")==90 and tostring(GetBuildInfo()):match("^(%d+%.%d+)")==R.Data.upgradeRules.patch
end
local function curveValue(points,x)
 for i=2,#points do local a,b=points[i-1],points[i];if x<b[1] then return a[2]+(x-a[1])*(b[2]-a[2])/(b[1]-a[1]) end end
 return points[#points][2]
end
function R.StatDR(key,current)
 local rules=R.Data.statRules
 if not current or key=="speed" or not rules or read(UnitLevel,"player")~=90 or tostring(GetBuildInfo()):match("^(%d+%.%d+)")~=rules.patch then return end
 local points
 if key=="avoidance" or key=="leech" then points=rules.curves.minor else points=rules.curves.secondary end
 local base=read(GetCombatRatingBonusForCombatRatingValue,current.index,1)
 if not base or base<=0 or not points or not current.bonus then return end
 local x=current.rating*base;local effective=curveValue(points,x)
 -- API semantics or game tuning can change. Never show guessed DR numbers.
 if math.abs(effective-current.bonus)>.05 then return end
 local last=points[#points];local slope=0;local nextX
 for i=2,#points do local a,b=points[i-1],points[i]
  if x<b[1] then
   slope=(b[2]-a[2])/(b[1]-a[1]);nextX=b[1]
   for j=i+1,#points do local c,d=points[j-1],points[j];local following=(d[2]-c[2])/(d[1]-c[1]);if math.abs(following-slope)>.001 then break end;nextX=d[1] end
   break
  end
 end
 return {penalty=math.floor((1-slope)*100+.5),nextRating=nextX and math.ceil(nextX/base),capRating=math.ceil(last[1]/base),capBonus=last[2],over=math.max(0,math.floor(current.rating-last[1]/base)),mastery=key=="mastery"}
end
function R.StatSummary(key,specID)
 local profile=R.StatProfile(specID);local group=key=="avoidance" or key=="leech" or key=="speed"
 local ref=profile and profile[group and "minor" or "secondary"].values[key]
 local current=R.StatCanCompare(specID) and R.StatCurrent(key) or nil
 return {reference=ref,current=current,delta=current and ref and current.rating-ref.rating,percentDelta=current and current.percent and ref and current.percent-ref.percent,dr=current and R.StatDR(key,current)}
end
function R.StatLines(key,specID)
 local summary=R.StatSummary(key,specID);local ref,current,dr=summary.reference,summary.current,summary.dr
 local lines={R.L("STATS_REFERENCE_NOTE")}
 if ref then lines[#lines+1]=R.L("STATS_REF_VALUE",ref.percent,ref.rating) end
 if current then
  lines[#lines+1]=R.L("STATS_YOUR_RATING",current.rating)
  if current.percent then lines[#lines+1]=R.L("STATS_YOUR_PERCENT",current.percent) end
  if summary.delta then
   lines[#lines+1]=R.L(summary.delta<0 and "STATS_BELOW" or summary.delta>0 and "STATS_ABOVE" or "STATS_EQUAL",math.abs(summary.delta))
   if summary.percentDelta then lines[#lines+1]=R.L("STATS_PERCENT_GAP",summary.percentDelta) end
  end
 else lines[#lines+1]=R.L(R.StatCanCompare(specID) and "STATS_RESTRICTED" or "STATS_PREVIEW") end
 if dr then
  lines[#lines+1]=R.L("STATS_DR_PENALTY",dr.penalty)
  if dr.nextRating then lines[#lines+1]=R.L("STATS_DR_NEXT",dr.nextRating,math.max(0,dr.nextRating-current.rating)) end
  lines[#lines+1]=R.L(dr.mastery and "STATS_MASTERY_CAP" or "STATS_RATING_CAP",dr.capBonus,dr.capRating)
  if dr.over>0 then lines[#lines+1]=R.L("STATS_OVER_CAP",dr.over) end
 else lines[#lines+1]=R.L("STATS_DR_UNKNOWN") end
 lines[#lines+1]=R.L("STATS_DR_NOTE")
 return lines
end
