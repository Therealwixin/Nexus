local _,R=...

function R.SpecCatalog()
 if R.specCatalog then return R.specCatalog end
 local catalog={classes={},byClass={},byID={}}
 for _,entry in ipairs(R.Data and R.Data.catalog or {}) do
  if R.Data.specs[entry.id] then
   local class=catalog.byClass[entry.classID]
   if not class then
    class={id=entry.classID,name=entry.className,file=entry.classSlug:gsub("-",""):upper(),specs={}}
    catalog.classes[#catalog.classes+1]=class;catalog.byClass[class.id]=class
   end
   local spec={id=entry.id,name=entry.name,classID=class.id,class=class}
   class.specs[#class.specs+1]=spec;catalog.byID[spec.id]=spec
  end
 end
 table.sort(catalog.classes,function(a,b)return a.id<b.id end)
 R.specCatalog=catalog;return catalog
end
function R.SpecInfo(specID)return R.SpecCatalog().byID[specID] end
function R.CurrentClassID()
 local spec=R.SpecInfo(R.SpecID());if spec then return spec.classID end
 if UnitClass then local _,_,id=UnitClass("player");if R.IsReadable(id) then return id end end
end
function R.IsViewingOtherClass()
 local viewed=R.SpecInfo(R.ViewSpecID());return viewed and viewed.classID~=R.CurrentClassID() or false
end
function R.SetViewSpec(specID)
 if not R.character then return false end
 if specID~=nil and not R.SpecInfo(specID) then return false end
 R.character.viewSpecID=specID
 if specID then
  R.character.lastSpecByClass=R.character.lastSpecByClass or {}
  R.character.lastSpecByClass[R.SpecInfo(specID).classID]=specID
 end
 return true
end
function R.ClassDefaultSpec(classID)
 local class=R.SpecCatalog().byClass[classID];if not class then return nil end
 local saved=R.character and R.character.lastSpecByClass and R.character.lastSpecByClass[classID]
 local metadata=saved and R.SpecInfo(saved)
 if metadata and metadata.classID==classID then return saved end
 local active=R.SpecInfo(R.SpecID())
 if active and active.classID==classID then return active.id end
 return class.specs[1] and class.specs[1].id
end
function R.SetClassIcon(texture,class)
 local coords=class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class.file]
 if coords then
  texture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes");texture:SetTexCoord(unpack(coords))
 else texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");texture:SetTexCoord(0,1,0,1) end
end
function R.SetSpecIcon(texture,spec)
 local api=GetSpecializationInfoByID;local icon
 if spec and api then
  local ok,id,_,_,value=pcall(api,spec.id)
  if ok and R.IsReadable(id) and id==spec.id and R.IsReadable(value) then icon=value end
 end
 if icon then texture:SetTexture(icon);texture:SetTexCoord(.07,.93,.07,.93)
 else R.SetClassIcon(texture,spec and spec.class) end
end
