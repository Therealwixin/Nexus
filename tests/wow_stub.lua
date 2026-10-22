-- Strict, small client API simulator for Lua/runtime regression checks.
-- It cannot reproduce the renderer, combat taint, or the real game client.
local Frame = {}
local serial = 0
ALL_FRAMES = {}
TEST = { combat=false, spec=266, version="12.1.0", equipped={}, bags={}, items={}, sockets={}, gems={}, timer={}, chats={} }
local function coefficient(point, vertical)
    if vertical then return point:find("TOP") and 1 or point:find("BOTTOM") and 0 or .5 end
    return point:find("RIGHT") and 1 or point:find("LEFT") and 0 or .5
end
local function axis(frame, vertical)
    if frame.allPoints then return axis(frame.allPoints,vertical) end
    local size=vertical and frame.height or frame.width
    local first, second
    for _,a in ipairs(frame.points or {}) do
        local base, extent=axis(a.relative,vertical)
        local c=coefficient(a.point,vertical)
        local value=base+coefficient(a.relativePoint,vertical)*extent+(vertical and a.y or a.x)
        if not first then first={c=c,v=value}
        elseif first.c~=c then second={c=c,v=value};break end
    end
    if second then size=(second.v-first.v)/(second.c-first.c) end
    size=size or 1
    return first and first.v-first.c*size or 0,size
end
function Frame:GetWidth() local _,x=axis(self,false);return x end
function Frame:GetHeight() local _,y=axis(self,true);return y end
function Frame:GetLeft() local x=axis(self,false);return x end
function Frame:GetRight() return self:GetLeft()+self:GetWidth() end
function Frame:GetBottom() local y=axis(self,true);return y end
function Frame:GetTop() return self:GetBottom()+self:GetHeight() end
function Frame:GetCenter() return self:GetLeft()+self:GetWidth()/2,self:GetBottom()+self:GetHeight()/2 end
function Frame:SetSize(w,h) self.width,self.height=w,h;if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end end
function Frame:SetParent(parent) self.parent=parent end
function Frame:SetWidth(w) self.width=w end
function Frame:SetHeight(h) self.height=h end
function Frame:ClearAllPoints() self.points={};self.allPoints=nil end
function Frame:SetPoint(point,a,b,c,d)
    local relative,relativePoint,x,y
    if type(a)=="table" then relative,relativePoint,x,y=a,b or point,c or 0,d or 0
    else relative,relativePoint,x,y=self.parent,point,a or 0,b or 0 end
    assert(relative,"SetPoint without a relative frame")
    assert(type(relativePoint)=="string" and type(x)=="number" and type(y)=="number")
    for index=#self.points,1,-1 do if self.points[index].point==point then table.remove(self.points,index) end end
    self.points[#self.points+1]={point=point,relative=relative,relativePoint=relativePoint,x=x,y=y}
end
function Frame:SetAllPoints(relative) self.allPoints=relative or self.parent end
function Frame:SetScript(event,fn) assert(fn==nil or type(fn)=="function");self.scripts[event]=fn end
function Frame:HookScript(event,fn)
    local old=self.scripts[event]
    self:SetScript(event,function(...) if old then old(...) end;fn(...) end)
end
function Frame:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function Frame:Hide() local was=self.shown;self.shown=false;if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function Frame:SetShown(v) if v then self:Show() else self:Hide() end end
function Frame:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function Frame:SetText(s) self.text=tostring(s or "");if self.fontString then self.fontString:SetText(self.text) end end
function Frame:GetText() return self.text or "" end
function Frame:GetStringHeight()
    local width=self:GetWidth();return (self.fontSize or 12)*math.max(1,math.ceil(#self:GetText()*(self.fontSize or 12)*.45/math.max(1,width)))
end
function Frame:SetFont(path,size) assert(path=="Fonts\\FRIZQT__.TTF","Non-native font");self.fontSize=size;return true end
function Frame:SetTextColor(...) self.color={...} end
function Frame:SetFontObject(...) end
function Frame:GetFontString() return self.fontString end
function Frame:SetChecked(v) self.checked=v end
function Frame:GetChecked() return self.checked end
function Frame:SetEnabled(v) self.enabled=v end
function Frame:Enable() self.enabled=true end
function Frame:Disable() self.enabled=false end
function Frame:IsEnabled() return self.enabled~=false end
function Frame:SetFocus() self.focus=true end
function Frame:ClearFocus() self.focus=false end
function Frame:GetVerticalScroll() return self.scroll or 0 end
function Frame:SetVerticalScroll(y) self.scroll=y;if self.scripts.OnVerticalScroll then self.scripts.OnVerticalScroll(self,y) end end
function Frame:IsMouseOver() return self.mouseOver and true or false end
function Frame:SetScrollChild(child) self.scrollChild=child end
function Frame:GetEffectiveScale() return 1 end
function Frame:RegisterEvent(event) self.events[event]=true end
function Frame:GetName() return self.name end
function Frame:Fire(script,...) if self.scripts[script] then return self.scripts[script](self,...) end end
function Frame:Click(...)return self:Fire("OnClick",...) end
function Frame:SetOwner(owner) self.owner=owner end
function Frame:NumLines() return #self.lines end
function Frame:ClearLines() self.lines={} end
function Frame:AddLine(text) self.lines[#self.lines+1]=text end
function Frame:SetHyperlink(link)
    self.lines={"Native item name","Item level","Stats","Effects","Description"}
    self.link=link
    local id=tonumber(link:match("item:(%d+)"))
    self.tooltipData={id=id}
    for _,fn in ipairs(TEST.tooltipHooks or {}) do fn(self,self.tooltipData) end
end
function Frame:SetInventoryItem(_,slot) self:SetHyperlink(TEST.equipped[slot].link) end
function Frame:SetTexture(value) self.texture=value end
function Frame:SetVertexColor(...) self.vertexColor={...} end
function Frame:SetColorTexture(...) self.color={...} end
function Frame:SetBackdrop(value) self.backdrop=value end
function Frame:SetBackdropColor(...) self.backdropColor={...} end
function Frame:SetBackdropBorderColor(...) self.backdropBorderColor={...} end
function Frame:GetNormalTexture()return self.normalTexture end
function Frame:GetPushedTexture()return self.pushedTexture end
function Frame:GetDisabledTexture()return self.disabledTexture end
function Frame:GetAlpha()return self.alpha or 1 end
function Frame:SetAlpha(value)self.alpha=value end
function Frame:IsObjectType(kind)return self.kind==kind end
function Frame:GetRegions()
 local regions={};for _,f in ipairs(ALL_FRAMES) do if f.parent==self and (f.kind=="Texture" or f.kind=="FontString") then regions[#regions+1]=f end end
 return unpack(regions)
end
function Frame:CreateTexture() return CreateFrame("Texture",nil,self) end
function Frame:CreateFontString() return CreateFrame("FontString",nil,self) end
for _,method in ipairs({"SetDrawLayer","SetUnit","SetShadowOffset","SetJustifyH","SetMaxLines","SetTexCoord","SetAutoFocus",
    "HighlightText","SetFrameStrata","SetFrameLevel","SetClampedToScreen","SetMovable","EnableMouse","SetResizable",
    "SetResizeBounds","RegisterForDrag","RegisterForClicks","StartMoving","StopMovingOrSizing","StartSizing","EnableMouseWheel",
    "SetHighlightTexture","SetNormalTexture"}) do Frame[method]=function() end end
function CreateFrame(kind,name,parent,template)
    serial=serial+1
    local frame=setmetatable({kind=kind,name=name or "Anonymous"..serial,parent=parent,template=template,
        scripts={},points={},events={},shown=true,lines={}}, {__index=function(_,key)
        local method=Frame[key]
        if not method and type(key)=="string" and key:match("^[_a-z]") then return nil end
        if not method then error("Unsupported client method/field: "..tostring(key)) end
        return method
    end})
    ALL_FRAMES[#ALL_FRAMES+1]=frame
    if kind=="Button" or kind=="CheckButton" then frame.fontString=CreateFrame("FontString",nil,frame);frame.fontString:SetWidth(180) end
    if template and template:find("UIPanelButtonTemplate",1,true) then
        frame.normalTexture=frame:CreateTexture();frame.pushedTexture=frame:CreateTexture();frame.disabledTexture=frame:CreateTexture()
    end
    if template and template:find("UIPanelScrollFrameTemplate",1,true) then
        frame.ScrollBar=CreateFrame("Slider",nil,frame)
    end
    if template and template:find("ButtonFrameTemplate",1,true) then
        frame.TitleContainer=CreateFrame("Frame",nil,frame)
        frame.TitleContainer.TitleText=CreateFrame("FontString",nil,frame.TitleContainer)
        frame.PortraitContainer=CreateFrame("Frame",nil,frame)
        frame.PortraitContainer.portrait=CreateFrame("Texture",nil,frame.PortraitContainer)
        frame.Inset=CreateFrame("Frame",nil,frame)
        frame.NineSlice=CreateFrame("Frame",nil,frame)
        frame.TitleBg=frame:CreateTexture();frame.TopTileStreaks=frame:CreateTexture()
    end
    return frame
end
UIParent=CreateFrame("Frame","UIParent");UIParent:SetSize(1920,1080)
Minimap=CreateFrame("Frame","Minimap",UIParent);Minimap:SetSize(180,180);Minimap:SetPoint("TOPRIGHT",-15,-15)
GameTooltip=CreateFrame("GameTooltip","GameTooltip",UIParent)
ItemRefTooltip=CreateFrame("GameTooltip","ItemRefTooltip",UIParent)
UISpecialFrames={};SlashCmdList={};tinsert=table.insert;NUM_BAG_SLOTS=4
Enum={BagIndex={ReagentBag=5},TooltipDataType={Item=0}}
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) TEST.chats[#TEST.chats+1]=s end}
C_Timer={After=function(_,fn) TEST.timer[#TEST.timer+1]=fn end}
function TEST.Flush()
    local loops=0
    while #TEST.timer>0 do loops=loops+1;assert(loops<100,"Infinite refresh loop");table.remove(TEST.timer,1)() end
end
function InCombatLockdown() return TEST.combat end
function issecretvalue(x) return type(x)=="table" and x.secret==true end
function GetSpecialization() return 1 end
function GetSpecializationInfo() return TEST.spec, TEST.spec==266 and "Demonology" or "Other spec", "",123,"DAMAGER" end
function GetBuildInfo() return TEST.version,"70000","Oct 5 2026",120100 end
function UnitName() return "AlphaTester" end
function GetInventoryItemLink(_,slot) return TEST.equipped[slot] and TEST.equipped[slot].link end
function GetInventoryItemID(_,slot) return TEST.equipped[slot] and TEST.equipped[slot].id end
function GetInventoryItemTexture(_,slot) return 123 end
function IsShiftKeyDown() return false end
function SetPortraitTexture() end
function GetCursorPosition() return 100,100 end
function ChatEdit_InsertLink() return true end
math.atan2=math.atan2 or function(y,x) return math.atan(y/x) end
C_Container={
    GetContainerNumSlots=function(bag) return #(TEST.bags[bag] or {}) end,
    GetContainerItemInfo=function(bag,slot) return TEST.bags[bag] and TEST.bags[bag][slot] end,
}
C_Item={
    RequestLoadItemDataByID=function(id) TEST.requested=TEST.requested or {};TEST.requested[id]=true end,
    GetItemInfo=function(id)
        if type(id)=="string" then id=tonumber(id:match("item:(%d+)")) end
        local item=TEST.items[id]
        if item then return item.name,"item:"..id,4,315,90,"Armor","Cloth",1,item.equipLoc,123 end
    end,
    GetItemInfoInstant=function(id)
        if type(id)=="string" then id=tonumber(id:match("item:(%d+)")) end
        local item=TEST.items[id]
        if item then return id,"Armor","Cloth",item.equipLoc,123,4,1 end
    end,
    GetDetailedItemLevelInfo=function(link) local id=tonumber(link:match("item:(%d+)"));return TEST.levels and TEST.levels[id] or 315 end,
    GetItemStats=function(link) return TEST.stats and TEST.stats[link] end,
    GetItemNumSockets=function(link) return TEST.sockets[link] or 0 end,
    GetItemGemID=function(link,index) return TEST.gems[link] and TEST.gems[link][index] end,
}
C_TradeSkillUI={
    GetAllRecipeIDs=function() return TEST.recipeIDs or {} end,
    GetRecipeOutputItemData=function(id) return TEST.recipeOutput and TEST.recipeOutput[id] end,
    GetRecipeSchematic=function(id) return TEST.recipeSchematics and TEST.recipeSchematics[id] end,
}
TooltipDataProcessor={AddTooltipPostCall=function(_,fn) TEST.tooltipHooks=TEST.tooltipHooks or {};table.insert(TEST.tooltipHooks,fn) end}

function Frame:SetAtlas(name,useAtlasSize,filterMode,resetTexCoords) self.atlas=name;self.atlasResetTexCoords=resetTexCoords end
function Frame:ClearTextureSlice() self.textureSliceCleared=true end
function Frame:SetTexCoord(...) self.texCoord={...} end

function Frame:CreateMaskTexture() return CreateFrame("MaskTexture",nil,self) end
function Frame:AddMaskTexture(mask) self.mask=mask end
