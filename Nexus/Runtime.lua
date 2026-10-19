local _,R=...

-- Bounded diagnostics. Never send an exception back into the event dispatcher.
function R.RecordRuntimeError(context,message)
    if not R.db then return end
    local errors=R.db.runtimeErrors or {};R.db.runtimeErrors=errors
    local text=tostring(message):sub(1,1500)
    local previous=errors[#errors]
    if previous and previous.context==context and previous.message==text then
        previous.count=math.min(9999,(previous.count or 1)+1)
    else
        if #errors>=8 then table.remove(errors,1) end
        errors[#errors+1]={context=context,message=text,count=1}
    end
end
function R.RunBackground(context,callback)
    local ok,message=pcall(callback)
    if not ok then R.RecordRuntimeError(context,message) end
    return ok
end

local function day(text)
    if type(text)~="string" then return nil end
    local y,m,d=text:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    y,m,d=tonumber(y),tonumber(m),tonumber(d)
    if not y or m<1 or m>12 or d<1 or d>31 then return nil end
    if m<=2 then y=y-1;m=m+12 end
    return 365*y+math.floor(y/4)-math.floor(y/100)+math.floor(y/400)+math.floor((153*(m-3)+2)/5)+d
end
function R.DataAge(dataset)
    if not dataset or not GetServerTime or not date then return nil end
    local updated=day(dataset.updatedAt)
    local today=day(date("!%Y-%m-%d",GetServerTime()))
    if not updated or not today or today<updated then return nil end
    return today-updated
end
function R.DataStatus(dataset)
    if not dataset then return R.L("NO_DATA") end
    local age=R.DataAge(dataset)
    local text=(dataset.primarySource or "").." · "..tostring(dataset.updatedAt or "?"):sub(1,10)
    if age then text=text.." · "..R.L("DATA_AGE",age) end
    if age and age>7 then text="|cffffb347"..R.L("DATA_OLD").." · "..text.."|r" end
    return text
end

local extra={
 EN={RESCAN_GEAR="Scan gear",DATA_SETTINGS="Data / settings",DATA_AGE="%d days old",DATA_OLD="Older snapshot",UPDATE_NOTE="Recommendations are bundled snapshots, not live data. Scan gear checks your equipment and bags only. Install a new Nexus package to update recommendations. Source dates are preserved; snapshots older than 7 days are flagged.",SOURCE_OPEN="Source page",SIMPLIFIED_NOTE="Compact Nexus: gear, preparation and meta. Player profiles and talents are not loaded."},
 SK={RESCAN_GEAR="Overiť výbavu",DATA_SETTINGS="Dáta / nastavenia",DATA_AGE="vek: %d dní",DATA_OLD="Starší dátový balík",UPDATE_NOTE="Odporúčania sú pribalené dáta, nie živé údaje. Overiť výbavu kontroluje iba tvoje vybavenie a tašky. Odporúčania aktualizuje nový balík Nexusu. Dátumy zdrojov nemeníme; dáta staršie než 7 dní sú označené.",SOURCE_OPEN="Stránka zdroja",SIMPLIFIED_NOTE="Odľahčený Nexus: výbava, príprava a meta. Profily hráčov ani talenty sa nenačítavajú."},
 CZ={RESCAN_GEAR="Ověřit výbavu",DATA_SETTINGS="Data / nastavení",DATA_AGE="stáří: %d dní",DATA_OLD="Starší datový balík",UPDATE_NOTE="Doporučení jsou přibalená data, nikoli živé údaje. Ověřit výbavu kontroluje pouze vybavení a tašky. Doporučení aktualizuje nový balík Nexusu. Data starší než 7 dní jsou označena.",SOURCE_OPEN="Stránka zdroje",SIMPLIFIED_NOTE="Odlehčený Nexus: výbava, příprava a meta. Profily hráčů ani talenty se nenačítají."},
}
for language,values in pairs(extra) do for key,value in pairs(values) do R.Locales[language][key]=value end end

local layoutStrings={
 EN={GEAR_SLOT="SLOT",GEAR_ITEM="ITEM",GEAR_STATE="STATUS",GEAR_NOTHING_MISSING="All recommended items are owned.",DATA_UPDATES="Data & updates"},
 SK={GEAR_SLOT="SLOT",GEAR_ITEM="PREDMET",GEAR_STATE="STAV",GEAR_NOTHING_MISSING="Všetky odporúčané predmety už vlastníš.",DATA_UPDATES="Dáta a aktualizácie"},
 CZ={GEAR_SLOT="SLOT",GEAR_ITEM="PŘEDMĚT",GEAR_STATE="STAV",GEAR_NOTHING_MISSING="Všechny doporučené předměty již vlastníš.",DATA_UPDATES="Data a aktualizace"},
}
for language,values in pairs(layoutStrings) do for key,value in pairs(values) do R.Locales[language][key]=value end end
