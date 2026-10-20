# Nexus: inštalácia a automatické aktualizácie

## Čo je nastavené za teba

GitHub je miesto, kde je uložený zdrojový kód Nexusu. GitHub Actions je služba, ktorá na serveri spustí zber dát, testy a vytvorí nový ZIP. Nemusíš mať počas toho zapnutý počítač ani WoW.

Workflow **Refresh Nexus data** je zapnutý denne približne o 04:17 UTC. V Bratislave je to v lete 06:17, v zime 05:17. GitHub môže štart odložiť. Ak od posledného úspešného zberu ešte neuplynulo 23 hodín, plánovaný beh nový balík nevytvorí. Ručný beh kontrolu času preskočí.

Úspešný beh:

1. Stiahne aktuálne stránky Murlok a Wowhead pre všetkých 40 špecializácií a meta dáta.
2. Skontroluje dostupnosť Raider.IO a Archon.
3. Cez Warcraft Logs API načíta anonymné gear štatistiky pre 40 špecializácií. Používa všetkých 8 sezónnych M+ dungeonov a 10 raid encounterov; úplnosť a veľkosť vzorky ukazuje pri konkrétnej špecializácii.
4. Overí patch, úplnosť, zdroje a počty vzoriek. Spustí regresné testy addonu.
5. Uloží novú verziu a vytvorí ZIP na GitHube aj na CurseForge.

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
| Murlok.io | Agregovaná výbava, enchanty, gemy a M+ meta. Profily jednotlivých hráčov sa nezobrazujú. |
| Warcraft Logs | Samostatná sezónna štatistika: 8 dungeonov a 10 raid encounterov, po dve stránky pre každý spec, posledných 14 dní. Vyžaduje aspoň 20 unikátnych postáv v každom encounteri a 200 v danom spec/režime. Neurčuje BiS. |
| Raider.IO | Verejné EU affixy/sezónny kontext. Nie ďalší BiS gear feed. |
| Archon | Kontrola dostupnosti a odkaz. Momentálne vracia overenie človeka; jeho gear štatistiky nie sú zapojené. WCL prístup automaticky neznamená prístup k Archon build feedu. |

## Catalyst a kontrola novej verzie v hre

Catalyst zachová sekundárne staty, sockety a špeciálne efekty pôvodného predmetu. Rovnaké tier item ID preto nestačí na potvrdenie odporúčanej verzie. Nexus pri známom pôvodnom kuse porovnáva dostupný profil sekundárnych statov; pri chýbajúcich dátach ukáže **over staty**. Pri odporúčanej konverzii natívny tooltip ukazuje pôvodný kus v sezónnej vylepšenej verzii a krátke označenie konverzie. Skutočne nasadený predmet používa natívny tooltip tvojej konkrétnej verzie.

Po nainštalovaní skontroluj Equipment bez modelu postavy, reálny ilvl pri **My gear**, sekciu Alternatives a Sockets & Gems. Jeden predmet s jedným socketom má jeden riadok socketu. Adventure Guide pri prvom hľadaní môže krátko zobrazovať priebeh; vyhľadávanie je rozdelené na malé dávky a počas boja sa neotvára.

Testy mimo hry pomáhajú zachytiť regresie, ale nenahrádzajú vykreslenie a bezpečné správanie v skutočnom klientovi WoW.

## BiS a alternatívy

Equipment má iba BiS. Pri slote sú najviac štyri odlišné overené alternatívy. Ak je známa dungeonová možnosť, má rezervované miesto a označenie Dungeon. Keď zdroje poskytujú menej možností, zoznam sa nedopĺňa vymyslenými predmetmi. Wowhead/Murlok dopĺňajú autorské možnosti Icy Veins, ktoré sa zbierajú v dennej aktualizácii.

## Ilvl a tooltipy (od 0.6.2-beta.3)

Bežný hover nad BiS alebo alternatívou otvára natívny herný tooltip skutočného sezónneho variantu. Predmet má správne škálované staty, kvalitu a upgrade rank; Shift sa nevyžaduje a nezapína základnú verziu. Bežný Myth preview je na 6/6 (334), zvýšené raid odmeny na 344, Myth craft na maximálnej kvalite (331). Dodatočné Ascendant maximum je krátka samostatná poznámka pri oprávnených slotoch.

Tooltipy v Nexuse neobsahujú opakované WCL počty, vysvetlenia popularity a dátové diagnostiky; tie zostávajú v detaile predmetu. Pri odporúčanom Catalyst kuse sa používa pôvodný predmet so zachovanými statmi a krátkym označením konverzie. Zdrojové craft stat bonusy sa zachovávajú, ak ich guide uvádza; chýbajúci výber statov sa nevymýšľa.

My gear a Currently equipped používajú presný nasadený slot a jeho skutočný tooltip. Ak ešte nie je plne vylepšený, Nexus načíta jeho upgrade maximum priamo z herného API a doplní jeden riadok. Nepriraďuje mu automaticky BiS maximum.

Odkazy na varianty sú overené proti dátam SimulationCraft pre build 12.1.5.70448 a živým Wowhead tooltipom troch hlásených príkladov: Silken Voodoo Drape (344), C’thraxxi Binders Pauldrons (334, Myth 6/6), Spellbreaker’s March (331). Vykreslenie a spoluprácu s ostatnými addonmi ešte treba potvrdiť v skutočnom klientovi WoW.

Neoverené pozorované alternatívy, ktorým nemožno priradiť aktuálny sezónny variant, sa nezobrazujú. Týka sa to aj starých predmetov z minulých expanzií. Niektoré sloty preto majú menej než štyri možnosti; overené dungeonové možnosti majú naďalej rezervované miesto.

## Poradie detailu a pravidlá dát (od 0.6.3-beta.1)

Detail má poradie **Selected item → Acquisition & upgrades → Alternatives → Currently equipped / craft materiály → Zdroje a podklady**. Warcraft Logs počty už nie sú vložené pod alternatívu ani pri Overall predmete. Pri každom skutočne doloženom zdroji je odkaz, dátum obsahu a dátum posledného načítania.

Overall používa pomenovaný autorský set Wowhead. Autorské možnosti Wowhead a Icy Veins majú v alternatívach prednosť pred pozorovanou výbavou Murloku. Zhoda mena tier predmetu sama nepotvrdzuje zhodu pôvodného Catalyst predmetu a jeho statov. Dva guide weby ani Archon/WCL sa nepočítajú ako nezávislé hlasy v hlasovaní o BiS.

Murlok ukazuje snímku top hodnotených M+ profilov, spravidla 50. Číslo pri predmete znamená **koľko z týchto profilov ho používa**. Neznamená to percento všetkých hráčov, počet všetkých logov ani optimálnu voľbu pre konkrétnu postavu.

WCL má oddelený širší zber pre aktuálnu sezónu: všetkých 8 dungeonov na kľúčoch aspoň +10 a 10 Mythic raid encounterov. Pre každý spec a encounter sa načítajú najviac dve stránky po 100 rebríčkových výsledkoch. Zostávajú iba záznamy z pevného 14-dňového obdobia s kompletnou výbavou. Identita postavy podľa mena a servera slúži iba v pamäti zberača na odstránenie duplicít; v JSON/Lua nie sú uložené hráčske mená, servery ani report kódy. V rámci spec/režimu sa použije najnovší kompletný loadout každej postavy. Počty z viacerých bossov sa nesčítajú ako nezávislí hráči.

Vzorka sa označí ako vhodná až pri minimálne 20 unikátnych postavách v **každom** plánovanom encounteri a aspoň 200 unikátnych postavách celkovo v danom spec/režime. Chýbajúci dungeon sa nezamení za kompletné sezónne pokrytie. V prehľade dát je počet zozbieraných specov, presné pokrytie, veľkosť vzorky a obdobie. Aj tak ide o top rebríčkovú vzorku, nie náhodný výber či všetky logy. Tanky a DPS používajú DPS rebríček, healeri HPS; samotné poradie nepoukazuje na najlepšiu obrannú alebo liečiteľskú výbavu.

Prvý nový živý dataset obsahuje Arms a Subtlety, oba s 8/8 dungeonmi a 10/10 raid encountermi. Kompletný zber všetkých 40 specov je súčasťou denného workflow. Starý dataset z jedného dungeonu/jedného bossa bol odstránený. Archon zostáva označený ako nezapojený, pretože verejný prístup vracia HTTP 403; WCL kľúč sám tento prístup nezabezpečuje.

### Ako prebehne automatická aktualizácia

1. GitHub denne spustí **Refresh Nexus data**. Ručne ho nájdeš cez repozitár → Actions → Refresh Nexus data → Run workflow → vetva main → Run workflow.
2. Najprv sa načítajú guidey a Murlok. Širší WCL zber môže pri hodinovej kvóte čakať na jej obnovenie; celé spracovanie môže trvať niekoľko hodín. Kým beží, nespúšťaj ďalšiu rovnakú úlohu. Žltý bežiaci stav počas čakania nie je chyba.
3. Ak WCL dočasne zlyhá, ponechá sa predošlý dátovaný široký snapshot. Nedokončený checkpoint sa nepublikuje; aktualizácia guideov/Murloku môže pokračovať. Zlyhanie je označené varovaním v Actions.
4. Až po testoch workflow uloží dáta a vydá nový beta balík na CurseForge/GitHub. V CurseForge aplikácii potom treba vykonať aktualizáciu addonu; samotný WoW nemá prístup na internet a nový snapshot si počas hrania nestiahne.

Detailné WCL mapy jednotlivých encounterov zostávajú v auditnom JSON súbore repozitára. Do WoW sa načítajú zmenšené súhrny, aby sa zbytočne nezvyšovala RAM. Šírka vzorky, presné filtre a verejné odkazy robia dáta overiteľnými; tvrdenie o absolútne nespochybniteľnom osobnom BiS by bolo zavádzajúce.

## Efekty predmetov a údržba (od 0.6.3-beta.2)

Názov kategórie je **BiS**. Ak nemáme overené alternatívy, detail to výslovne uvedie. Nie je to tvrdenie, že žiadny iný predmet v hre neexistuje.

Pri Catalyst náhľade je **Catalyst: názov tieru** označenie výslednej konverzie. Predchádzajúca šípka sa v hernom fonte zobrazovala ako chybný znak; dvojbodka je zámerná.

Denný zber zachová bonusy publikované v guideoch a načíta aktuálnu ItemBonus tabuľku SimulationCraft. Efektové bonusy oddelí od ilvl a upgrade bonusov. Pre pôvodný Catalyst kus môže použiť iba efekt doložený pre toto isté pôvodné item ID. Pri rozporných variantoch efekt neodhadne. Voliteľné craft efekty neprenáša medzi odporúčaniami; zachová iba výslovne publikovanú voľbu konkrétneho riadku. Pôvodné dátumy guideov sa pri tomto obohatení nemenia.

Nie je potrebné ručne dopisovať pasíva jednotlivých helm/chest predmetov. Neúplná bonusová tabuľka alebo iný patch zastavia vydanie kandidáta a ponechajú poslednú vydanú verziu. Pri novej sezóne treba overiť ilvl pravidlá a API; nepredstierame, že tieto zmeny možno vždy bezpečne odhadnúť automaticky. WoW naďalej dostáva hotový snapshot cez aktualizáciu balíka.
