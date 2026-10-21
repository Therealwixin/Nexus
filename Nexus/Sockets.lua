local _,R=...

local function gemCatalog()
 if R.gemCatalog then return R.gemCatalog end
 local out={}
 for _,modes in pairs(R.Data and R.Data.specs or {}) do
  for _,data in pairs(modes) do for _,gem in ipairs(data.gems or {}) do out[gem.id]=gem end end
 end
 R.gemCatalog=out;return out
end
local function category(id)
 if C_Item and C_Item.GetItemUniquenessByID then
  local _,_,_,value=C_Item.GetItemUniquenessByID(id)
  if R.IsReadable(value) and type(value)=="number" and value>0 then return value end
 end
end
function R.IsDiamond(gem)
 local known=gemCatalog()[gem.id]
 if (known and known.uniqueGem=="diamond") or gem.uniqueGem=="diamond" then return true end
 local name=(known and known.name) or gem.name
 if type(name)=="string" and name:lower():find("diamond",1,true) then return true end
 local idCategory=category(gem.id)
 if idCategory then
  for id,entry in pairs(gemCatalog()) do
   if (entry.uniqueGem=="diamond" or (entry.name or ""):lower():find("diamond",1,true)) and category(id)==idCategory then return true end
  end
 end
 return false
end
function R.SocketInfo(link)
 if not R.IsReadable(link) or type(link)~="string" then return nil end
 local parsed=R.ParseLink(link);if not parsed then return nil end
 local total
 if C_Item and C_Item.GetItemNumSockets then total=C_Item.GetItemNumSockets(link) end
 if total~=nil and not R.IsReadable(total) then return nil end
 if type(total)~="number" then
  local api=C_Item and C_Item.GetItemStats or GetItemStats
  local stats=api and api(link);if type(stats)~="table" then return nil end
  total=0
  for stat,value in pairs(stats) do
   if type(stat)=="string" and stat:match("^EMPTY_SOCKET_") and R.IsReadable(value) then total=total+(tonumber(value) or 0) end
  end
 end
 local out={total=total,filled=0,empty=0,gems={},pending=false}
 for index=1,total do
  local id,name,gemLink
  if C_Item and C_Item.GetItemGemID then id=C_Item.GetItemGemID(link,index)
  elseif parsed.gems[index] then id=parsed.gems[index] end
  if not R.IsReadable(id) then return nil end
  local api=C_Item and C_Item.GetItemGem or GetItemGem
  if api then name,gemLink=api(link,index);if not R.IsReadable(name) or not R.IsReadable(gemLink) then return nil end end
  id=R.ItemID(id) or R.ItemID(gemLink) or R.ItemID(parsed.gems[index])
  if id then
   R.RequestItem(id);local known=gemCatalog()[id]
   local item={id=id,link=gemLink,name=name or (known and known.name),icon=known and known.icon}
   local info=C_Item and C_Item.GetItemInfo or GetItemInfo
   if not item.name and info then local n=info(id);if R.IsReadable(n) then item.name=n end end
   if not item.name then out.pending=true end
   out.gems[#out.gems+1]={index=index,item=item};out.filled=out.filled+1
  else out.gems[#out.gems+1]={index=index};out.empty=out.empty+1 end
 end
 return out
end
function R.GetSocketOverview(scope)
 local inBags=scope=="bags"
 local data=R.GetDataset();local regular,diamonds={},{};local allowed={};local seen={}
 for _,gem in ipairs(data and data.gems or {}) do
  if not seen[gem.id] then
   seen[gem.id]=true;allowed[gem.id]=true
   local list=R.IsDiamond(gem) and diamonds or regular;list[#list+1]=gem
  end
 end
 local function popularity(a,b)return (a.count or 0)>(b.count or 0) end
 table.sort(regular,popularity);table.sort(diamonds,popularity)
 local out={items={},total=0,filled=0,empty=0,recommended=0,diamondCount=0,pending=false,regular=regular,diamonds=diamonds,unknown=0}
 local items={}
 if inBags then items=R.scan and R.scan.bagItems or {}
 else for _,slot in ipairs(R.SLOTS) do local item=R.scan and R.scan.equipped[slot.id];if item then items[#items+1]=item end end end
 for _,item in ipairs(items) do
  if item and item.link then
   local sockets=R.SocketInfo(item.link)
   if not sockets then out.unknown=out.unknown+1
   elseif sockets.total>0 then
    local entry={item=item,slotID=item.slotID,sockets=sockets,recommendations={}}
    out.items[#out.items+1]=entry;out.total=out.total+sockets.total;out.filled=out.filled+sockets.filled;out.empty=out.empty+sockets.empty
    out.pending=out.pending or sockets.pending
    for _,gem in ipairs(sockets.gems) do
     if gem.item then
      if R.IsDiamond(gem.item) then out.diamondCount=out.diamondCount+1 end
      if allowed[gem.item.id] then out.recommended=out.recommended+1 end
     end
    end
   end
  end
 end
 -- Bag copies are alternatives, not a simultaneous loadout: defer unique diamonds until equipped.
 -- Reserve ONE diamond for the whole character, including all unshown slots.
 -- Incomplete gem data blocks the diamond suggestion until native data loads.
 table.sort(out.items,function(a,b)
  if (a.sockets.empty>0)~=(b.sockets.empty>0) then return a.sockets.empty>0 end
  if inBags then
   if a.item.bagID~=b.item.bagID then return a.item.bagID<b.item.bagID end
   return a.item.bagSlot<b.item.bagSlot
  end
  return a.slotID<b.slotID
 end)
 local diamondAvailable=not inBags and out.diamondCount==0 and not out.pending and out.unknown==0 and diamonds[1]
 for _,entry in ipairs(out.items) do
  local empty=entry.sockets.empty
  if empty>0 and diamondAvailable then
   entry.recommendations[#entry.recommendations+1]={item=diamonds[1],count=1,diamond=true};out.diamondPlanSlot=entry.slotID;diamondAvailable=false;empty=empty-1
  end
  if empty>0 and regular[1] then entry.recommendations[#entry.recommendations+1]={item=regular[1],count=empty} end
 end
 -- Empty sockets come first; the gear remains browseable when fully socketed.
 return out
end
