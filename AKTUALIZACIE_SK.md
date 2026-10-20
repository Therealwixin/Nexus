# Nexus: inštalácia a automatické aktualizácie

## Čo je nastavené za teba

GitHub je miesto, kde je uložený zdrojový kód Nexusu. GitHub Actions je služba, ktorá na serveri spustí zber dát, testy a vytvorí nový ZIP. Nemusíš mať počas toho zapnutý počítač ani WoW.

Workflow **Refresh Nexus data** je zapnutý denne približne o 04:17 UTC. V Bratislave je to v lete 06:17, v zime 05:17. GitHub môže štart odložiť. Ak od posledného úspešného zberu ešte neuplynulo 23 hodín, plánovaný beh nový balík nevytvorí. Ručný beh kontrolu času preskočí.

Úspešný beh:

1. Stiahne aktuálne stránky Murlok a Wowhead pre všetkých 40 špecializácií a meta dáta.
2. Skontroluje dostupnosť Raider.IO a Archon.
3. Cez Warcraft Logs API načíta anonymné gear štatistiky pre 40 špecializácií. Používa jeden aktuálny raidový encounter a jeden M+ dungeon; nie sú to výsledky zo všetkých bossov a dungeonov.
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

Projekt [Nexus: Gear & Preparation](https://www.curseforge.com/wow/addons/nexus-gear-preparation) je už schválený. Každý nový súbor však ešte môže samostatne čakať na kontrolu: najnovší balík 0.6.1 je práve **Under Review**. Kým sa schváli, aplikácia môže ponúkať staršiu beta 4. Ak potrebuješ opravy hneď, použi priložený ZIP z GitHubu. Schvaľovanie GitHub ani addon nevie urýchliť.

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
| Warcraft Logs | Anonymné počty používania predmetov v uvedenom encounteri. Minimálne 20 použiteľných záznamov; používanie nie je dôkaz najlepšieho gearu pre tvoju postavu. |
| Raider.IO | Verejné EU affixy/sezónny kontext. Nie ďalší BiS gear feed. |
| Archon | Kontrola dostupnosti a odkaz. Momentálne vracia overenie človeka; jeho gear štatistiky nie sú zapojené. WCL prístup automaticky neznamená prístup k Archon build feedu. |

## Catalyst a kontrola novej verzie v hre

Catalyst zachová sekundárne staty, sockety a špeciálne efekty pôvodného predmetu. Rovnaké tier item ID preto nestačí na potvrdenie odporúčanej verzie. Nexus pri známom pôvodnom kuse porovnáva dostupný profil sekundárnych statov; pri chýbajúcich dátach ukáže **over staty**. Pri odporúčanej konverzii zhrnutie uvádza cieľový ilvl; Shift + nájazd myšou otvorí pôvodný kus so zreteľným označením základných statov. Skutočne nasadený predmet používa natívny tooltip tvojej konkrétnej verzie.

Po nainštalovaní skontroluj Equipment bez modelu postavy, reálny ilvl pri **My gear**, sekciu Alternatives a Sockets & Gems. Jeden predmet s jedným socketom má jeden riadok socketu. Adventure Guide pri prvom hľadaní môže krátko zobrazovať priebeh; vyhľadávanie je rozdelené na malé dávky a počas boja sa neotvára.

Testy mimo hry pomáhajú zachytiť regresie, ale nenahrádzajú vykreslenie a bezpečné správanie v skutočnom klientovi WoW.

## Overall BiS a alternatívy

Equipment má iba Overall BiS. Pri slote sú najviac štyri odlišné overené alternatívy. Ak je známa dungeonová možnosť, má rezervované miesto a označenie Dungeon. Keď zdroje poskytujú menej možností, zoznam sa nedopĺňa vymyslenými predmetmi. Wowhead/Murlok dopĺňajú autorské možnosti Icy Veins, ktoré sa zbierajú v dennej aktualizácii.

## Ilvl odporúčanej a nasadenej výbavy (od 0.6.2-beta.2)

**Overall BiS a alternatívy** ukazujú cieľ najlepšej získateľnej verzie. Detail uvádza Myth 1/6 až 6/6, prípadne kvalitu Myth craftu. Bežný Myth gear ide z 318 na 334; Myth craft z 318 na 331. Špeciálne Mythic odmeny z The Coiled Altar/Ula’tek majú 344. Pri oprávnených zbraniach, trinketoch a neckoch je samostatne uvedené Ascendant maximum 340 (craft 338); už zvýšené 344 odmeny sa ďalej nezvyšujú. Odomknutie Ascendant systému je 20. 10. v NA a 21. 10. v EU.

Základný predmet podľa samotného ID nemá bonusy konkrétnej sezónnej verzie. Preto jeho nízky natívny ilvl a staty nevydávame za maximálny BiS. Bežný nájazd myšou ukáže cieľový rozsah a zdroj. **Podrž Shift a potom prejdi myšou na predmet**, ak chceš natívny tooltip základného kusu; bude označený ako základný náhľad. Nexus zatiaľ neprepočítava jeho staty na maximum. Pri nedostatočne overenom pôvode ukáže, že maximum nie je overené.

**My gear a Currently equipped** používajú aktuálny ilvl a natívny tooltip tvojej konkrétnej nasadenej verzie. BiS maximum sa na tieto predmety nevzťahuje automaticky.

Pravidlá: https://www.wowhead.com/guide/midnight/item-level-gear-upgrades-dawncrests a https://www.wowhead.com/guide/midnight/bonus-rolls-item-upgrades . Číselné ciele sú obmedzené na sezónu 12.1; pri inej sezóne sa nepreberajú automaticky.
