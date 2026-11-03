# ADR-AP1-DE — Sprachvergleich in AP1: deutscher Hauptplan, Faltung über F8, englische Kontrolle

## Status

Vorgeschlagen, vom Betreiber zu bestätigen. Festgelegt vor dem ersten Aufruf dieses Folgeversuchs. Die Nummer vergibt der Betreiber bei der Übernahme nach `main`.

## Kontext

- Der Hauptplan von AP1 ist englisch. Deutsch kommt nur als Faktor F8 (Anweisungssprache) in den Robustheitsläufen vor, je sechs von zwölf Läufen.
- GRR, Kappa, Trefferquote und gefährliche Fehler sind damit nur für englische Prompts gemessen. Aus den sechs Läufen je Sprache lassen sich die übrigen sieben Faktoren nicht je Sprache schätzen.
- Plackett-Burman mit zwölf Läufen vermischt Haupteffekte teilweise mit Zwei-Faktor-Wechselwirkungen.
- Dieser Folgeversuch ist nach Kenntnis der vorläufigen Auswertung vom 03.11.2026 (Paketstand M1b) geplant, die eine Wirkung der Anweisungssprache erkennen ließ. Das wird im Bericht und im Paper offen genannt. Die neuen Daten sind von diesen Ergebnissen unabhängig.

## Entscheidung

1. **Erhebung.** Eigener Klon, Branch `ap1-de`, eigene Stores. Der englische Store und `inst/validation/ap1/plan.yaml` auf `main` bleiben unverändert.

| Teil | Umfang | Aufrufe |
| --- | --- | --- |
| Pilot, deutsch | 10 Pilotitems × 3 Prompts × 1 Replikat × 3 Modelle, Regeln nach A.6 | 90 |
| Hauptplan, deutsch | 100 Items × 3 Prompts × 3 Replikate × 2 Blöcke × 3 Modelle | 5400 |
| Kontrolle, englisch | 100 Items × englisches concise × 1 Durchgang × 3 Modelle, eigener Store | 300 |
| Faltung über F8 | dieselben 12 PB-Läufe mit umgekehrtem F8 × 100 Items × 3 Modelle | 3600 |

2. **Reihenfolge.** Pilot, Block 1, Kontrolle, Block 2 an einem anderen Tag als Block 1, Faltung.
3. **Prompttexte.** Das deutsche concise ist der vorhandene Text aus `robustness.blocks` (alle Faktoren minus, F8 plus). role und json sind neu übersetzt. Klassennamen, Kürzel und der JSON-Schlüssel `classification` bleiben englisch, der Systemprompt von F6 ebenso. Gemessen wird also die Sprache der Anweisung, nicht ein vollständig deutsches Gespräch. Der Text der Kontrolle ist wortgleich mit dem englischen concise (Hash je Item gegen den englischen Store geprüft).
4. **Unverändert.** Items, Modelle, Anbieter, Quantisierung, Seeds, Parameter, Parser, Aliasse, Klassen, Akzeptanzgrenzen und der Code auf `f948105`, außer: `acmg_pb()` kehrt die in `pb_design.fold_over` genannte Spalte um (ohne dieses Feld wie bisher), und `inst/validation/ap1/run_control.R` erhebt die Kontrolle. Die Prompt-IDs `pb01` bis `pb12` behalten ihre Zeile; F8 plus heißt weiter Deutsch.
5. **Lücken.** Blöcke: Regel nach A.8; kein Nachholen einzelner Zeilen, weil der Block den Tag misst. Faltung: Über 5 % Backendfehler eines Modells in einem Lauf werden nur die Backendfehler-Zeilen auf einer Storekopie einmal nachgeholt und offen ausgewiesen, wie am 03.11.2026. Unlesbare Antworten werden nie nachgeholt; sie zählen nach Plan als nicht stabil.
6. **Auswertung.** Nach M1d mit dem Code von M1d und diesem Commit, Fits nach ADR-006 und ADR-041. Alle Vergleiche sind beschreibend, mit Intervallen; es gibt keinen Test als Urteil und kein neues Gesamturteil über die Sprache. Das Verdikt von AP1 bleibt am englischen Hauptplan; der deutsche Hauptplan bekommt seine Bänder nach ANK-58 als Zusatzergebnis. Je Modell:
   1. Primär: Kappa, %GRR, gefährliche Fehler und der Paarvergleich aus Nr. 6.4, Deutsch gegen Englisch.
   2. Kappa-Differenz Deutsch minus Englisch mit gepaartem Item-Bootstrap: dieselben gezogenen Items in beiden Sprachen, Wiederholungen, Saat, Niveau und Quantiltyp nach `evaluation.kappa_bootstrap`.
   3. Trefferquote, Anteil fehlender Antworten, Items ohne Modalwert, Anteil der Items mit anderem Modalwert, gefährliche Fehler, die nur in einer Sprache auftreten. Liegen beide Sprachen nicht auf derselben Skala (ordinal oder numerischer Rückfall), wird %GRR auf beiden Skalen verglichen.
   4. Paarvergleich F8: Zwölf Paare, die sich nur in der Sprache unterscheiden. Antwort `y` nach Plan. Primär beide Hälften gegen den englischen Modalwert, sekundär gegen den deutschen: mittlere Differenz Deutsch minus Englisch, t-Intervall 95 % über die Paare, `delta_p` am mittleren Logit.
   5. Innerhalb jeder Sprache: zwölf Läufe, sieben Faktoren, Antwort gegen den Modalwert derselben Sprache, Lenth mit m = 7, ME und SME wie im Plan.
   6. Wechselwirkungen F8 × Fj: Effekt auf Deutsch minus Effekt auf Englisch, nur beschreibend.
   7. Kontrolle: Anteil gleich dem Modalwert der sechs englischen concise-Aufrufe, neben der Übereinstimmung einzelner concise-Aufrufe mit den übrigen fünf und neben `pb03`. Weicht ein Modell ab, dessen Wiederholungen identisch waren, oder ändern sich Anbieter oder `model_snapshot`, gilt der Hauptplanvergleich dieses Modells nur mit diesem Vorbehalt.
7. **Gegenrechnung.** Jede Kennzahl wird unabhängig vom Paketcode nachgerechnet (Prüfstandard), die Hashes aller Prompts gegen die Plantexte.
8. **Veröffentlichung.** Dieser Branch geht vor dem ersten Aufruf auf GitHub. Ergebnisse erst nach M1d.

## Konsequenzen

- Rund 9400 Aufrufe, rund 67 h Laufzeit und rund 22 $, unter `budget_eur`. Der Betreiber startet jeden Teil selbst.
- Bericht und Paper nennen, dass der deutsche Hauptplan später erhoben wurde als der englische. In der Faltung läuft bei sechs Paaren Deutsch später und bei sechs Englisch, ein Zeiteffekt gleicht sich dort weitgehend aus.
- Eine Aussage über eine rein deutsche Pipeline mit deutschen Klassennamen bleibt offen.
