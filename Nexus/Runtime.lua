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
    if dataset.retrievedAt then text=text.." · "..R.L("CHECKED").." "..dataset.retrievedAt:sub(1,10) elseif age then text=text.." · "..R.L("DATA_AGE",age) end
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

local repairStrings={
 EN={NO_SOURCE_OPTION="No verified source option",JOURNAL_NOT_FOUND="The exact boss could not be resolved safely. Use the Wowhead link below.",SOURCE_SCOPE_NOTE="Overall: authored all-source guide. Raid/M+: source-restricted alternatives from available candidates, not a simulated best set. Unknown sources are excluded; some slots may be empty."},
 SK={NO_SOURCE_OPTION="Bez overenej alternatívy",JOURNAL_NOT_FOUND="Presného bossa sa nepodarilo bezpečne určiť. Použi odkaz na Wowhead nižšie.",SOURCE_SCOPE_NOTE="Overall: guide zo všetkých zdrojov. Raid/M+: alternatívy z dostupného vzorku, nie simulovaný BIS set. Neznáme zdroje sú vynechané; niektoré sloty môžu byť prázdne."},
 CZ={NO_SOURCE_OPTION="Bez ověřené alternativy",JOURNAL_NOT_FOUND="Přesného bosse se nepodařilo bezpečně určit. Použij odkaz na Wowhead níže.",SOURCE_SCOPE_NOTE="Overall: guide ze všech zdrojů. Raid/M+: alternativy z dostupného vzorku, nikoli simulovaný BIS set. Neznámé zdroje jsou vynechány; některé sloty mohou být prázdné."},
}
for lang,values in pairs(repairStrings) do for key,value in pairs(values) do R.Locales[lang][key]=value end end
R.Locales.EN.WCL_EVIDENCE_NOTE="One ranking page for this encounter. Observed usage, not a personal simulation."
R.Locales.SK.WCL_EVIDENCE_NOTE="Jedna stránka rebríčka pre tento encounter. Používanie predmetov, nie osobná simulácia."
R.Locales.CZ.WCL_EVIDENCE_NOTE="Jedna stránka žebříčku pro tento encounter. Používání předmětů, nikoli osobní simulace."
local fixes={
 EN={TIER_STATS_UNVERIFIED="Tier equipped · verify stats",TIER_STATS_DIFFERENT="Tier equipped · different stats",CATALYST_NOTE="Catalyst keeps the original item's secondary stats, sockets and special effects. The default tier tooltip does not prove the converted variant's stats.",JOURNAL_RESOLVING="Finding loot in current raids and seasonal dungeons…",NO_ALTERNATIVES="No verified alternatives available for this item.",OBSERVED_ALTERNATIVE="Observed alternative",CHECKED="Checked"},
 SK={TIER_STATS_UNVERIFIED="Tier nasadený · over staty",TIER_STATS_DIFFERENT="Tier nasadený · iné staty",CATALYST_NOTE="Catalyst zachová sekundárne staty, sockety a špeciálne efekty pôvodného predmetu. Bežný tier tooltip nepotvrdzuje staty konvertovanej verzie.",JOURNAL_RESOLVING="Hľadám loot v aktuálnych raidoch a sezónnych dungeonoch…",NO_ALTERNATIVES="Pre tento predmet nemáme overené alternatívy.",OBSERVED_ALTERNATIVE="Používaná alternatíva",CHECKED="Overené"},
 CZ={TIER_STATS_UNVERIFIED="Tier nasazený · ověř staty",TIER_STATS_DIFFERENT="Tier nasazený · jiné staty",CATALYST_NOTE="Catalyst zachová sekundární staty, sockety a speciální efekty původního předmětu. Běžný tier tooltip nepotvrzuje staty konvertované verze.",JOURNAL_RESOLVING="Hledám loot v aktuálních raidech a sezonních dungeonech…",NO_ALTERNATIVES="Pro tento předmět nemáme ověřené alternativy.",OBSERVED_ALTERNATIVE="Používaná alternativa",CHECKED="Ověřeno"},
}
for lang,values in pairs(fixes) do for key,value in pairs(values) do R.Locales[lang][key]=value end end
for _,lang in ipairs({"EN","SK","CZ"}) do
 local l=R.Locales[lang]
 l.SOURCE_AVAILABLE=lang=="EN" and "available · context only" or lang=="SK" and "dostupný · kontext" or "dostupný · kontext"
 l.SOURCE_BLOCKED=lang=="EN" and "blocked · no gear data" or lang=="SK" and "blokovaný · bez gear dát" or "blokovaný · bez gear dat"
 l.SOURCE_UNAVAILABLE=lang=="EN" and "unavailable" or lang=="SK" and "nedostupný" or "nedostupný"
 l.SOURCE_NOT_INTEGRATED=lang=="EN" and "not integrated" or lang=="SK" and "nezapojený" or "nezapojený"
end
R.Locales.EN.META_REFRESH_FAILED="Source unavailable at last check; showing the previous dated snapshot."
R.Locales.SK.META_REFRESH_FAILED="Zdroj pri poslednej kontrole nebol dostupný; zobrazené sú pôvodné datované údaje."
R.Locales.CZ.META_REFRESH_FAILED="Zdroj při poslední kontrole nebyl dostupný; zobrazené jsou původní datované údaje."
R.Locales.EN.NO_DUNGEON_ALTERNATIVE="No additional verified dungeon option for this slot."
R.Locales.SK.NO_DUNGEON_ALTERNATIVE="Pre tento slot nemáme ďalšiu overenú dungeonovú možnosť."
R.Locales.CZ.NO_DUNGEON_ALTERNATIVE="Pro tento slot nemáme další ověřenou dungeonovou možnost."
R.Locales.EN.SOURCE_SCOPE_NOTE="BiS plus up to four distinct alternatives. A verified dungeon option is kept when available. Observed usage is not a personal simulation."
R.Locales.SK.SOURCE_SCOPE_NOTE="BiS a najviac štyri odlišné alternatívy. Ak je dostupná overená dungeonová možnosť, zostáva medzi nimi. Používanie predmetov nie je osobná simulácia."
R.Locales.CZ.SOURCE_SCOPE_NOTE="BiS a nejvýše čtyři odlišné alternativy. Pokud je dostupná ověřená dungeonová možnost, zůstává mezi nimi. Používání předmětů není osobní simulace."
