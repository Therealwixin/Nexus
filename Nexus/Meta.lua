local _,R=...
-- Rankings stay role-local. A tank's representation is never compared to a
-- healer's output or to a DPS score. Published Murlok positions are preserved.
R.META_ROLES={"dps","healer","tank"}
local tanks={[73]=true,[66]=true,[250]=true,[268]=true,[104]=true,[581]=true}
local healers={[65]=true,[256]=true,[257]=true,[264]=true,[270]=true,[105]=true,[1468]=true}
function R.SpecRole(id)return tanks[id] and "tank" or healers[id] and "healer" or "dps" end
function R.GetMetaDataset(mode)
 local data=R.MetaData
 if not data or data.schema~=1 or not data.modes then return nil,"META_UNAVAILABLE" end
 if GetBuildInfo then
  local version=GetBuildInfo();local patch=type(version)=="string" and version:match("^(%d+%.%d+)")
  if patch and patch~=data.patch then return nil,"PATCH_MISMATCH" end
 end
 return data.modes[mode or R.GetMode()]
end
function R.MetaEntries(mode,role)
 local data,why=R.GetMetaDataset(mode);local result={}
 if not data then return result,why or "META_UNAVAILABLE" end
 for _,key in ipairs(R.META_ROLES) do
  if not role or role=="all" or role==key then
   local group=data.roles and data.roles[key]
   for _,entry in ipairs(group and group.entries or {}) do
    if R.SpecInfo(entry.specID) then result[#result+1]={entry=entry,role=key,group=group,dataset=data} end
   end
  end
 end
 return result
end
function R.MetaRecord(id,mode)
 for _,record in ipairs(R.MetaEntries(mode,R.SpecRole(id))) do if record.entry.specID==id then return record end end
end
function R.MetaDate(data,role)
 local oldest
 for key,group in pairs(data and data.roles or {}) do
  if role==nil or role=="all" or key==role then
   if not oldest or group.updatedAt<oldest then oldest=group.updatedAt end
  end
 end
 return oldest and oldest:sub(1,10) or "?"
end
function R.MetaAge(group)
 local now=GetServerTime and GetServerTime() or time and time()
 return now and group and group.updatedEpoch and math.max(0,math.floor((now-group.updatedEpoch)/86400))
end
