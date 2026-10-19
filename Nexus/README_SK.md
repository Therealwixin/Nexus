# Nexus 0.6.0 preview 2

Nový smer: jeden striedmy Warcraft vzhľad, prehľadný zoznam výbavy a detail predmetu vpravo.
Players a Talents sú odstránené z kódu aj dát. Preparation má šesť čitateľných riadkov na stránku.

## Inštalácia

Vypni WoW, zálohuj starý priečinok Nexus a nahraď ho celým novým priečinkom z addon ZIPu.
Výsledok: `_retail_/Interface/AddOns/Nexus/Nexus.toc`. SavedVariables ponechaj. Otvor `/nexus`.

## Dáta a aktualizácie

Zber bol 19. 10. 2026 overený pre všetkých 40 specov v Raid aj Mythic+ režime a pre obe mety.
V addone zostávajú skutočné dátumy zdrojov, napríklad 16. 10. pri Murloku alebo 13. 10. pri niektorých Wowhead návodoch.
Odporúčania nie sú osobná simulácia výbavy. Raid meta vyjadruje zastúpenie vo vzorke Mythic parsov, nie čistú silu specu.

Overiť výbavu kontroluje iba vybavenie a tašky. Webové odporúčania prináša nový balík addonu.
Pripravené GitHub workflowy kontrolujú kód a dáta, balia addon a umožňujú trojdňový refresh po zapojení repozitára a CurseForge projektu.
Plánovanie a publikovanie sú predvolene vypnuté. Addon sám vo WoW nekomunikuje s webom ani neprepisuje súbory.

## Overenie v hre

Skontroluj výbavu, filter chýbajúcich predmetov, enchanty/sockety, zmenu veľkosti okna, oba režimy a dungeon upozornenie.
Vykreslenie, combat taint a reálnu RAM musí potvrdiť hra. Pri chybe použi `/nexus debug`.
Lokálne Lua testy a živý zber prešli; neznamená to overené vydávanie na CurseForge.
