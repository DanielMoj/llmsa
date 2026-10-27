# ADR-010 — Randfälle AP1: Wiederholungstag, Herkunft, Vollständigkeit, PB-Zeilen und Pilotzeilen ohne API-Beleg

## Status

Angenommen (Reviewer, M2 `50-code-review` Runde 1, 27.10.2026). Bindend ab der nächsten Builder-Phase von M2 (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“). Ergänzt ADR-006; Nr. 6 präzisiert ADR-006 Nr. 7.2 und 7.4. Bezug: QA-M2-001 bis QA-M2-005 in `orchestrator/handoff/M2/QA.md`, Einwände E21 bis E26 in `orchestrator/handoff/M2/REVIEW.md` (Runde 1).

## Kontext

- Die QA-Tests `tests/e2e/test-m2-qa-e2e.R` und `tests/fuzz/test-m2-qa-fuzz.R` scheitern im Test-Gate von M2 Runde 1 (`orchestrator/state/M2/gate-tests.log`). Sie treffen Randfälle, zu denen `docs/03`, ADR-006 und PLAN-UPDATE nur mittelbar etwas sagen:
  - fremde Modelle im Wiederholungstagsbericht eines Modells;
  - eine erfolgreiche OpenRouter-Antwort ohne Feld `provider`;
  - eine Store-Kennung `api` neben fehlerfreien Zeilen ohne `meta`;
  - ein Item ohne Hauptplanzeile des Modells;
  - PB-Zeilen mit unbekannter Klasse oder fremden Designschlüsseln.
- Die Nachrechnung der Pilotregeln im Code-Review zeigt außerdem: Eine fehlerfreie Pilotzeile ohne `id` lässt im Code `provider` und `cost` scheitern. ADR-006 Nr. 7.2 (OpenRouter) und Nr. 7.4 verlangen das dem Wortlaut nach nicht.
- Wortlaute:
  - `docs/01` §2 Nr. 4: „Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“
  - `docs/03` A.6: „Auslöser für einen Wiederholungstag, vorab festgelegt: Anbieterwechsel in der Antwort, wechselnde Modellkennung innerhalb eines Blocks, mehr als 5 % Fehler eines Modells in einem Block.“ A.7: „Zahl der Items ohne Modalantwort“.
  - ADR-006 Nr. 7.2: „Fehlt das Feld in der Antwort, ist die Regel nicht bestanden“. Nr. 7.7: „… aus API-Aufrufen stammt (nicht aus dem Mock) …“. Nr. 7.8: „ein `provider`, der vom angeforderten abweicht oder innerhalb des Blocks wechselt“. Nr. 8.1: „rechnet `acmg_evaluate()` die Kennzahlen und kennzeichnet das Ergebnis als unvollständig, mit den Zählungen“. Nr. 9: „Ergebnisse und Berichte aus Mock-Zeilen kennzeichnet es sichtbar als synthetisch.“ Nr. 11: Itemmerkmale „ausschließlich aus den Spalten von `runs`“.
  - PLAN-UPDATE E3 (akzeptiert): „Widersprüchliche oder bei einem vorhandenen Store nicht belegbare Herkunft führt zum benannten Abbruch; sie wird nicht als API-Herkunft geraten.“ Und: „Solche Daten erteilen keine Pilotfreigabe.“ E7 (akzeptiert): „Fehlende/zusätzliche oder doppelte Zeilen verhindern eine vollständige Bewertung.“
  - PLAN-REVIEW E16: „Zeilen ohne `meta` gelten als Herkunft ‚nicht belegt‘, nie als `api`.“

## Entscheidung

1. **Wiederholungstag im Bericht eines Modells (QA-M2-001).** Der Abschnitt „Repeat-day diagnostics“ im Bericht des Modells m enthält je Block die Zeile von m, berechnet aus den Hauptplanzeilen von m. Zeilen anderer Modelle stehen dort nur, wenn sie aus deren eigenen Hauptplanzeilen berechnet sind. In diesem Abschnitt ist eine Zeile für ein Modell ohne Zeilen im Block, mit `FALSE` oder `NA` als Ersatz, unzulässig.
2. **Fehlender Anbieter (QA-M2-002).** Für ein Modell mit angefordertem OpenRouter-Anbieter (`provider_name` gesetzt) gilt in ADR-006 Nr. 7.8 eine fehlerfreie Zeile als Abweichung vom angeforderten Anbieter, wenn ihr `meta` kein Feld `provider` oder einen leeren Wert trägt. Für Modell und Block ist dann `provider_change = TRUE`. Für Sol (ohne `provider_name`) ist ein fehlendes Feld kein Auslöser. Begründung:
   - Nr. 7.2 wertet dasselbe Fehlen im Pilot als nicht bestanden.
   - Ohne das Feld ist der Auslöser „Anbieterwechsel in der Antwort“ (A.6) nicht auszuschließen.
   - Ein Fehlalarm kostet eine Betreiberentscheidung; ein übersehener Wechsel kostet die Gültigkeit des Blocks.
3. **Herkunft (QA-M2-003).**
   1. Eine fehlerfreie Zeile ist *Mock*, wenn `meta$mock` wahr ist. Sie ist *API-belegt*, wenn ihr `meta` `id` und `model_snapshot` trägt und nicht Mock ist. Sonst ist sie *nicht belegt*. Fehlerzeilen tragen zur Herkunft nicht bei.
   2. `provenance` ist `synthetic`, wenn eine Mock-Zeile vorliegt oder die Store-Kennung `mock` lautet, auch neben nicht belegten Zeilen. Mock- und API-belegte Zeilen zugleich oder eine Kennung, der die Zeilen widersprechen, bleiben ein benannter Abbruch (ADR-006 Nr. 9).
   3. `provenance` ist `api` nur, wenn keine fehlerfreie Zeile nicht belegt ist und dazu API-belegte Zeilen vorliegen oder die Store-Kennung `api` lautet (Store nur mit Fehlerzeilen, E17). In allen übrigen Fällen ist sie `unverified`. Die Store-Kennung macht eine nicht belegte Zeile nie zu `api`.
   4. `acmg_store_read()` vergleicht wie bisher die so bestimmte Herkunft mit `--backend`. Ein Store mit Kennung `api` und nicht belegten fehlerfreien Zeilen endet deshalb mit benanntem Abbruch, ohne Änderung des Stores (PLAN-UPDATE E3). Ein Mock-Store mit nicht belegten Zeilen bleibt nach Nr. 3.2 `synthetic`.
4. **Items ohne Hauptplanzeile (QA-M2-004).**
   - `modal` hat je Modell genau eine Zeile je Item aus `items.csv`. Ein Item ohne Hauptplanzeile des Modells erhält `modal = NA` und `has_modal = FALSE`. Es zählt in `n_no_modal` und in `reference_basis$excluded_no_modal`; A.7 nennt die „Zahl der Items ohne Modalantwort“.
   - Die Itemmerkmale eines solchen Items stammen aus den übrigen Zeilen von `runs` zu diesem Item (Nr. 11). Fehlt es in `runs` ganz, bleiben sie `NA`. Widersprüchliche Itemmerkmale über die Zeilen eines Items bleiben ein benannter Fehler.
   - Die sekundäre Trefferquote eines PB-Laufs nimmt die Referenz aus den Itemspalten der PB-Zeilen selbst (Nr. 11). Die Stabilität vergleicht weiter mit der Modalantwort des Hauptplans (Nr. 8.2).
   - Das Ergebnis bleibt unvollständig; alle Verdikte bleiben „not assessed“ (Nr. 8.1).
5. **PB-Zeilen (QA-M2-005).**
   1. Die Klassenprüfung von `acmg_evaluate()` gilt für alle Zeilen der Hauptplan- und Robustheitsauswertung, auch für `pb01` bis `pb12`: `value` ist eine Klasse nach ANK-69 oder `NA`; ein nicht leeres `reference` ist eine Klasse nach ANK-69. Sonst folgt der benannte Fehler „AP1 runs contain unknown response or reference classes.“ (ADR-005 Nr. 1; `docs/01` §2 Nr. 4).
   2. Robustheit ist für ein Modell nur bewertet, wenn außer der Zählung nach ADR-006 Nr. 8.2 jede seiner PB-Zeilen die Schlüssel des geplanten PB-Designs trägt: `rep` in `seq_len(plan$robustness$replicates)`, `block` gleich 1, kein `run_key` doppelt. Sonst gilt `complete = FALSE` und das Band „not assessed“, mit Begründung (PLAN-UPDATE E7).
6. **Pilotzeilen ohne API-Beleg (präzisiert ADR-006 Nr. 7.2 und 7.4).** Eine fehlerfreie Pilotzeile, die nicht API-belegt ist (Nr. 3.1), lässt die Regel `provider` ihres Modells scheitern, auch bei OpenRouter-Modellen. Die Regel `cost` scheitert dann für alle Modelle. Mock-Zeilen fallen ohnehin darunter (ADR-006 Nr. 7.5). Begründung:
   - Nr. 7.7 verlangt einen Pilot „aus API-Aufrufen“.
   - PLAN-UPDATE E3: „Solche Daten erteilen keine Pilotfreigabe.“
   - Ohne `id` ist die Stichprobe über `GET /api/v1/generation` (K-M2-4) unmöglich.

   Die Ausgabe nennt den Grund. Das entspricht dem Code von M2 Runde 1 (`R/acmg.R:499`, `:502`, `:523`); er bleibt unverändert.

## Konsequenzen

- Die Abnahmetests bleiben unverändert und sind mit Nr. 1 bis 6 verträglich:
  - Die Mock-Daten der Abnahme sind vollständig; ihre fehlerfreien Zeilen tragen `meta$mock`, ihre Stores die Kennung `mock`.
  - Ihre Werte sind Klassen nach ANK-69 oder `NA`.
  - Die PB-Zeilen tragen `rep = 1` und `block = 1`.
  - Konstruierte Läufe ohne `meta` und ohne Kennung bleiben `unverified`.
  - `acc_m2_check_model()` vergleicht `modal` über die Items der Hauptplanzeilen.
- Die QA-Tests prüfen Nr. 1 bis 5 im Test-Gate. Der Builder belegt Nr. 3.2 bis 3.4 und Nr. 6 zusätzlich mit Unit-Tests ohne Netz; die bestehenden Fälle in `tests/testthat/test-acmg-pipeline.R` (Z. 86–113) bleiben dabei gültig.
- Änderungen nur durch ein neues ADR.
