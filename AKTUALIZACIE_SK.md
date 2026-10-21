# Nexus: inštalácia a automatické aktualizácie

## Čo je nastavené za teba

GitHub je miesto, kde je uložený zdrojový kód Nexusu. GitHub Actions je služba, ktorá na serveri spustí zber dát, testy a vytvorí nový ZIP. Nemusíš mať počas toho zapnutý počítač ani WoW.

Workflow **Refresh Nexus data** kontroluje každý nový UTC kalendárny deň o 04:17 UTC. Ďalšie pokusy pri chybe alebo neúplnej aktualizácii zdroja sú o 10:17 a 16:17 UTC. Po úspešnej kompletnej kontrole dnešného dňa sa ďalší plánovaný beh preskočí. Včerajší večerný ručný zber nepreskočí dnešnú kontrolu. Ručný beh zber vynúti vždy. GitHub môže štart odložiť.

Úspešný beh:

1. Stiahne aktuálne stránky Murlok, Wowhead a Icy Veins pre všetkých 40 špecializácií, meta dáta a údaje o efektových bonusoch predmetov.
2. Overí patch, úplnosť, zdroje a počty vzoriek. Spustí regresné testy addonu.
3. Uloží novú verziu a vytvorí ZIP na GitHube aj na CurseForge.

Ak povinný zber alebo test zlyhá, nový balík sa nevydá. Posledná úspešná verzia zostáva dostupná. Pri nedostupnom voliteľnom zdroji sa zobrazí jeho stav; nevymyslia sa náhradné údaje.

## Dva kroky aktualizácie

**Aktualizácia dát na serveri** prebieha cez GitHub Actions. **Inštalácia nového balíka do tvojho počítača** prebieha cez CurseForge aplikáciu alebo ručným stiahnutím ZIPu. WoW addon sám nemôže sťahovať súbory z internetu.

Tlačidlo **Scan gear / Overiť výbavu** iba znovu prečíta tvoje nasadené predmety a tašky. Nesťahuje nové odporúčania.

## Ako nainštalovať aktuálnu verziu ručne

1. Ukonči WoW.
2. Otvor [GitHub Releases](https://github.com/Therealwixin/Nexus/releases). Vyber najnovšie vydanie. V časti **Assets** stiahni ZIP s názvom `Nexus-...zip`. Nevyberaj automatické archívy **Source code**.
3. Rozbaľ ZIP. Vnútri musí byť priečinok **Nexus** so súborom **Nexus.toc**.
4. V inštalácii hry otvor `_retail_/Interface/AddOns/` a nahraď existujúci priečinok **Nexus** tým novým.
5. Správna výsledná cesta je `_retail_/Interface/AddOns/Nexus/Nexus.toc`. Nemá tam byť ďalší vnorený priečinok `Nexus/Nexus/`.
6. Nemaž priečinok `WTF` ani `SavedVariables`; tam sú tvoje nastavenia.
7. Spusti WoW. V zozname addonov zapni Nexus, otvor `/nexus` a skontroluj verziu v spodnej časti okna.

Na aktualizáciu serverových dát nemusíš nič programovať, sťahovať Python ani inštalovať Git.

## Automatická inštalácia cez CurseForge

Projekt [Nexus: Gear & Preparation](https://www.curseforge.com/wow/addons/nexus-gear-preparation) je už schválený. Každý nový súbor však ešte môže samostatne čakať na kontrolu: súbor môže byť označený **Under Review**. Kým sa schváli, aplikácia môže ponúkať staršiu verziu. Ak potrebuješ opravy hneď, použi priložený ZIP z GitHubu. Schvaľovanie GitHub ani addon nevie urýchliť.

Nastavenie aplikácie:

1. V CurseForge aplikácii vyber **World of Warcraft** a správny **Retail** profil/inštaláciu.
2. Vyhľadaj a nainštaluj **Nexus: Gear & Preparation**.
3. Pri Nexuse povoľ prijímanie **Beta** verzií. Aktuálne testovacie vydania nie sú označené ako stabilný Release.
4. Ak aplikácia v tvojej verzii ponúka automatické aktualizácie, zapni ich pre Nexus. Inak použi jej tlačidlo **Update** pred spustením hry.
5. Po aktualizácii reštartuj WoW. Ak sa aktualizoval už známy addon za behu hry, môže stačiť `/reload`; pri problémoch hru úplne ukonči a spusti znova.

## Ako overiť, či sa zber vydaril

1. Otvor [Refresh Nexus data](https://github.com/Therealwixin/Nexus/actions/workflows/data-refresh.yml).
2. Klikni na najnovší beh. Zelená fajka znamená úspech, červený krížik chybu.
3. V úspešnom behu uvidíš zber, testy a publikovanie. Nový balík nájdeš aj v [Releases](https://github.com/Therealwixin/Nexus/releases).
4. Číslo dátového vydania obsahuje čas, napríklad `0.6.1-beta.data.202610200945`. To identifikuje balík; neznamená to, že každá zdrojová stránka bola v tej minúte zmenená.

**Ručné vynútenie zberu:** na rovnakej stránke klikni **Run workflow**, nechaj vetvu **main** a potvrď zelené **Run workflow**. Nepotrebuješ nikam vkladať API kľúče. Počkaj na zelený výsledok.

**Pri červenom výsledku:** otvor neúspešný krok a pošli sem odkaz na beh. API kľúče, heslá ani obsah GitHub Secrets neposielaj do chatu. Ak sa zmenil patch alebo formát zdroja, treba upraviť zberač; opakované klikanie Run workflow to neopraví.

## Prečo môže byť na položke starší dátum

Nexus rozlišuje dátum publikácie zdroja a dátum, kedy ho znovu skontroloval. Napríklad `Murlok.io · 2026-10-16 · Overené 2026-10-20` znamená, že stránka bola načítaná 20. 10., ale sama uvádzala 16. 10. Starý dátum neprepisujeme dnešným. Samotný starší dátum preto neznamená, že workflow nebežal.

## Ktoré zdroje sú naozaj zapojené

| Zdroj | Použitie |
|---|---|
| Wowhead | Autorské gear odporúčania, príprava a explicitné zdroje predmetov. |
| Icy Veins | Autorské alternatívy gearu. |
| U.GG | Zastúpenie specov v Mythic raide pre Meta tabuľku. |
| Murlok.io | Agregovaná výbava, enchanty, gemy a M+ meta. Profily jednotlivých hráčov sa nezobrazujú. |

## Catalyst a kontrola novej verzie v hre

Catalyst zachová sekundárne staty, sockety a špeciálne efekty pôvodného predmetu. Rovnaké tier item ID preto nestačí na potvrdenie odporúčanej verzie. Nexus pri známom pôvodnom kuse porovnáva dostupný profil sekundárnych statov; pri chýbajúcich dátach ukáže **over staty**. Pri odporúčanej konverzii natívny tooltip ukazuje pôvodný kus v sezónnej vylepšenej verzii a krátke označenie konverzie. Skutočne nasadený predmet používa natívny tooltip tvojej konkrétnej verzie.

Po nainštalovaní skontroluj Equipment bez modelu postavy, reálny ilvl pri **My gear**, sekciu Alternatives a Sockets & Gems. Jeden predmet s jedným socketom má jeden riadok socketu. Adventure Guide pri prvom hľadaní môže krátko zobrazovať priebeh; vyhľadávanie je rozdelené na malé dávky a počas boja sa neotvára.

Testy mimo hry pomáhajú zachytiť regresie, ale nenahrádzajú vykreslenie a bezpečné správanie v skutočnom klientovi WoW.

## BiS a alternatívy

Equipment má Raid (Wowhead guide) a Mythic+ (Murlok používanie gearu), oba vrátane raidových, dungeonových a crafted predmetov. Pri slote sú najviac štyri odlišné overené alternatívy. Ak je známa dungeonová možnosť, má rezervované miesto a označenie Dungeon. Keď zdroje poskytujú menej možností, zoznam sa nedopĺňa vymyslenými predmetmi. Wowhead/Murlok dopĺňajú autorské možnosti Icy Veins, ktoré sa zbierajú v dennej aktualizácii.

## Ilvl a tooltipy (od 0.6.2-beta.3)

Bežný hover nad BiS alebo alternatívou otvára natívny herný tooltip skutočného sezónneho variantu. Predmet má správne škálované staty, kvalitu a upgrade rank; Shift sa nevyžaduje a nezapína základnú verziu. Bežný Myth preview je na 6/6 (334), zvýšené raid odmeny na 344, Myth craft na maximálnej kvalite (331). Dodatočné Ascendant maximum je krátka samostatná poznámka pri oprávnených slotoch.

Tooltipy v Nexuse neobsahujú opakované vysvetlenia popularity a dátové diagnostiky; tie zostávajú v detaile predmetu. Pri odporúčanom Catalyst kuse sa používa pôvodný predmet so zachovanými statmi a krátkym označením konverzie. Zdrojové craft stat bonusy sa zachovávajú, ak ich guide uvádza; chýbajúci výber statov sa nevymýšľa.

My gear a Currently equipped používajú presný nasadený slot a jeho skutočný tooltip. Ak ešte nie je plne vylepšený, Nexus načíta jeho upgrade maximum priamo z herného API a doplní jeden riadok. Nepriraďuje mu automaticky BiS maximum.

Odkazy na varianty sú overené proti dátam SimulationCraft pre build 12.1.5.70448 a živým Wowhead tooltipom troch hlásených príkladov: Silken Voodoo Drape (344), C’thraxxi Binders Pauldrons (334, Myth 6/6), Spellbreaker’s March (331). Vykreslenie a spoluprácu s ostatnými addonmi ešte treba potvrdiť v skutočnom klientovi WoW.

Neoverené pozorované alternatívy, ktorým nemožno priradiť aktuálny sezónny variant, sa nezobrazujú. Týka sa to aj starých predmetov z minulých expanzií. Niektoré sloty preto majú menej než štyri možnosti; overené dungeonové možnosti majú naďalej rezervované miesto.

## Poradie detailu a pravidlá dát

Detail má poradie **Selected item → Acquisition & upgrades → Alternatives → Currently equipped / craft materiály → Zdroje a podklady**. Pri zdroji je odkaz, dátum obsahu a dátum načítania. Murlok je vzorka top M+ hráčov, nie simulovaný optimálny spoločný set. Zhoda názvu tieru nepotvrdzuje zhodu statov pôvodného Catalyst predmetu.

Priamy WCL zber, jeho dáta a workflow, Archon a Raider.IO affixy boli odstránené. U.GG Meta zostáva samostatne zbieraným zdrojom; jej metodika môže odkazovať na logy.

## Efekty predmetov a údržba (od 0.6.3-beta.2)

Názov kategórie je **BiS**. Ak nemáme overené alternatívy, detail to výslovne uvedie. Nie je to tvrdenie, že žiadny iný predmet v hre neexistuje.

Pri Catalyst náhľade je **Catalyst: názov tieru** označenie výslednej konverzie. Predchádzajúca šípka sa v hernom fonte zobrazovala ako chybný znak; dvojbodka je zámerná.

Denný zber zachová bonusy publikované v guideoch a načíta aktuálnu ItemBonus tabuľku SimulationCraft. Efektové bonusy oddelí od ilvl a upgrade bonusov. Pre pôvodný Catalyst kus môže použiť iba efekt doložený pre toto isté pôvodné item ID. Pri rozporných variantoch efekt neodhadne. Voliteľné craft efekty neprenáša medzi odporúčaniami; zachová iba výslovne publikovanú voľbu konkrétneho riadku. Pôvodné dátumy guideov sa pri tomto obohatení nemenia.

Nie je potrebné ručne dopisovať pasíva jednotlivých helm/chest predmetov. Neúplná bonusová tabuľka alebo iný patch zastavia vydanie kandidáta a ponechajú poslednú vydanú verziu. Pri novej sezóne treba overiť ilvl pravidlá a API; nepredstierame, že tieto zmeny možno vždy bezpečne odhadnúť automaticky. WoW naďalej dostáva hotový snapshot cez aktualizáciu balíka.

## Dungeonové upozornenie (od 0.6.4-beta.2)

Pri vstupe do sezónneho dungeonu sa porovná jeho skutočný loot pool iba s hlavným BiS zoznamom tvojho aktívneho specu. Alternatívy a pozorované M+ predmety sa do vstupného BiS hlásenia nezapočítavajú. Naďalej ich nájdeš v detaile slotu. Hlásenie sa riadi aktuálnymi dátami, nie ručne napísaným zoznamom dungeonov.

Pri odporúčanom Catalyst kuse sa hľadá pôvodné drop ID a riadok je označený **BiS cez Catalyst**. Tier výsledok sa neprezentuje ako priamy drop. Predmety, ktoré už máš nasadené alebo v taške, a duplicitné ring/trinket možnosti sa nepočítajú opakovane.

## Stats (od 0.6.5-beta.1)

Medzi Equipment a Preparation je samostatný tab **Stats**. Používa existujúci výber všetkých 40 class/spec kombinácií. Tabuľka ukazuje sekundárne staty aj Avoidance, Leech a Speed: **Murlok M+ referencia / tvoja postava / rozdiel ratingu**. Poradie priorít, rating a percentá sú prevzaté z publikovaných agregovaných barov Murloku, nie dopočítané z individuálnych profilov.

Hover otvorí tooltip s vlastnou hodnotou, ratingovým rozdielom nad/pod referenciou a rozdielom v percentuálnych bodoch. Kliknutie ukáže rovnaké podrobnosti v pravom paneli. Murlok referencia nie je osobný optimálny cieľ ani cap. Aktuálne percentá postavy môžu obsahovať buffy; do porovnania medzi rôznymi specmi sa nepúšťame, pretože napríklad Mastery má iný prevod na efekt.

Živé porovnanie je dostupné pre tvoj aktívny spec na leveli 90 pri zhodnom patchi. Ostatné specy slúžia na prezeranie referencií. Počas boja sa nepoužívajú chránené ani nečitateľné hodnoty a nič sa z nich neodhaduje. Zmeny statov obnovujú panel cez herné udalosti, bez priebežného pollingu či nového skenovania tašiek.

DR počítame z ratingu a aktuálnej krivky. Hover obsahuje zníženie zisku z ďalšieho ratingu, ďalšiu hranicu, koľko ratingu k nej chýba, a ratingový strop. Mastery používa **Mastery body**, nie celkové percentá efektu. Buffy a základné staty sa nepovažujú za rating pre DR. DR znamená nižší prírastok, nie automatický pokyn prestať daný stat zbierať.

Výpočet sa kontroluje proti natívnemu bonusu herného API; pri nezhode alebo nedostupnom API sa neoverené DR čísla skryjú. Pre Speed sa zatiaľ DR cap neuvádza, pretože má osobitný prevod; referenčný aj skutočný Speed rating/percentá zostávajú dostupné.

Denný workflow automaticky zbiera aj stat referencie zo všetkých 40 Murlok guideov a malé krivky DR z aktuálnych primárnych DBC dát SimulationCraft. Pri nedostupnom zdroji zachová poslednú overenú verziu aj jej pôvodné dátumy a označí neúspešnú aktualizáciu. V addone nie je internetový prístup ani databáza jednotlivých hráčov.
