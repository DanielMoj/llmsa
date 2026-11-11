# ADR-057 — AP1-Berichte nach der Abnahme von M1 nicht mehr als „provisional“ kennzeichnen

## Status

Angenommen (Betreiber, 11.11.2026). Betreiber-Commit außerhalb des Harness, ohne Mutationslauf. Ändert ein Textfeld des freigegebenen Plans (ADR-004); Design, Modelle, Akzeptanzgrenzen und Auswertung bleiben unverändert.

## Kontext

- M2 lief vor dem Statistikkern. Deshalb tragen die AP1-Berichte seit M2 den Titel `AP1 <Modell> - <Herkunft> - provisional` (fest in `acmg_evaluate()`) und unter „Provenance and status“ den Satz aus `reporting.provisional` in `inst/validation/ap1/plan.yaml`: „Statistics are provisional until M1 is accepted. Re-evaluate the same store after M1 (BL-52).“
- M1 ist seit dem 04.11.2026 abgenommen (`done/M1d`). Die Endauswertung vom 11.11.2026 auf `daa4f0c` liefert für den englischen Hauptplan in allen sechs Berichten (Stores vor und nach dem Nachholen, ADR-044) dieselben Zahlen wie die Auswertung mit `done/M1d`; Sensitivitäten, Robustheit mit allen Kontrasten und der parametrische Bootstrap sind Feld für Feld gleich.
- Die Berichte sind der Beleg der Validierung. Ein Bericht, der nach der Abnahme weiter „provisional“ heißt, sagt über seinen Stand das Falsche.

## Entscheidung

1. `acmg_evaluate()` setzt den Titel `AP1 <Modell> - <Herkunft>` ohne Zusatz.
2. `reporting.provisional` in `plan.yaml` lautet: „Statistics use the statistical core accepted in milestone M1 (2026-11-04). Evaluations made before that date were provisional and are superseded (BL-52, ADR-057).“ Der Feldname bleibt, damit Pläne älterer Stände und der Branch `ap1-de` (ADR-056) lesbar bleiben.
3. `inst/validation/ap1/README.md` nennt die Abnahme statt des Vorbehalts.
4. `tests/testthat/test-report.R` verlangt den neuen Satz und den Titel ohne Zusatz und prüft, dass „provisional“ in Titel und Statuszeile nicht mehr vorkommt.
5. Sonst ändert sich nichts: keine Rechnung, keine Schwelle, kein anderes Planfeld.

## Konsequenzen

- Berichte aus Auswertungen vor diesem Commit tragen den alten Titel; ihre Zahlen gelten weiter.
- Der Bestätigungslauf auf dem Release-Stand vergleicht die Berichte zeilenweise mit denen vom 11.11.2026. Erwartet sind Unterschiede nur in Titel, Statuszeile, Versionsangabe und Datum.
- Die Berichte des Sprachvergleichs (ADR-056) entstehen auf dem Branch `ap1-de` mit dessen Plan; sie tragen den alten Titel, bis der Branch auf diesen Stand gehoben ist.
- BL-52 ist erledigt.
