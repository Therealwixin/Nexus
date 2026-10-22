# Nexus

Addon pre World of Warcraft Retail: odporúčaná výbava, Stats, príprava postavy a Meta.
Podporuje všetkých 40 specov a rozhranie EN/SK/CZ. Výbava používa natívne pozadia talentov.

## Inštalácia

Rozbaľ inštalačný ZIP a nahraď priečinok Nexus. Výsledok musí byť
`_retail_/Interface/AddOns/Nexus/Nexus.toc`. SavedVariables ponechaj. Otvor `/nexus`.

## Dáta a aktualizácie

Mythic+ výbava a Stats používajú
agregované dáta Murloku, alternatívy zahŕňajú aj Icy Veins. Odporúčania nie sú osobná simulácia.
M+ Meta zachováva poradie Murloku v rámci roly. Raid režim a raid Meta sú dočasne odstránené.
Raidové predmety odporúčané pre M+ zostávajú dostupné vrátane ich zdroja a loot navigácie.

Denný zber beží na GitHube o 04:17 UTC, s opakovaním neúspešných kontrol o 10:17 a 16:17 UTC.
Po úspešných kontrolách workflow vytvorí a publikuje dátový balík podľa konfigurácie projektu.
Dátumy publikácie zdrojov a úspešného načítania zostávajú oddelené. Pri výpadku sa zachovávajú
pôvodné označené dáta; nepredstiera sa úspešná aktualizácia. CurseForge môže nový súbor ešte schvaľovať.

Scan gear kontroluje iba nasadenú výbavu a tašky vrátane enchantov a socketov.
Výbava sa obnovuje aj automaticky po zmenách inventára. Webové odporúčania aktualizuje
inštalácia novšieho balíka addonu. Addon vo WoW neposiela webové požiadavky.

## Overenie v hre

Pred prvým stable releasom over zmenu specu/režimu, tooltipy, enchanty/sockety v bagu,
resize okna, Scan gear počas/po boji a dungeon upozornenie. Lokálne testy nenahrádzajú
vykreslenie ani secure execution v skutočnom klientovi. Diagnostika: `/nexus debug`.
