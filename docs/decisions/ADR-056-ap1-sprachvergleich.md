# ADR-056 — Sprachvergleich in AP1: deutscher Hauptplan, Faltung über F8, englische Kontrolle

## Status

Angenommen (Betreiber). Festgelegt am 03.11.2026 vor dem ersten Aufruf des Folgeversuchs als `docs/decisions/ADR-AP1-DE-sprachvergleich.md` auf dem Branch `ap1-de` (Commit `56efb0b`, 12:38:20 MEZ; erster Aufruf 12:40:01 MEZ). Am 11.11.2026 als Dokument nach `main` übernommen. Kontext, Entscheidung und Konsequenzen stehen hier im Wortlaut des Branches; neu sind die Nummer, dieser Statusabsatz und die beiden Nachträge am Ende.

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

## Nachtrag 11.11.2026: Ausführung

Erhoben im Klon auf `56efb0b`, ohne Änderung an Code oder Plan. Zeiten in MEZ nach den Zeitstempeln der Stores (Beginn des ersten und des letzten Aufrufs). Backendfehler sind Zeilen mit gesetztem `error`; unlesbar sind Antworten ohne Backendfehler, in denen der Parser keine Klasse erkennt.

| Teil | Zeitraum | Store | Backendfehler | Unlesbar |
| --- | --- | --- | --- | --- |
| Pilot 1 | 03.11., 12:40 bis 13:23 | `ap1_de.sqlite` | Qwen 1 (HTTP 429) | Qwen 1 |
| Pilot 2 | 03.11., 13:37 bis 14:16 | `ap1_de_2.sqlite` | Qwen 1 (HTTP 429) | keine |
| Pilot 3 | 04.11., 00:58 bis 01:32 | `ap1_de_3.sqlite` | keine | keine |
| Block 1 | 04.11., 01:33 bis 21:51 | `ap1_de_3.sqlite` | Qwen 1 (Verbindung nach dem Senden getrennt) | Qwen 33, Llama 9 |
| Kontrolle | 04.11., 22:19 bis 05.11., 00:54 | `ap1_de_kontrolle.sqlite` | Qwen 17 (HTTP 429) | Qwen 2 |
| Block 2 | 05.11., 10:30 bis 06.11., 06:05 | `ap1_de_3.sqlite` | keine | Qwen 23, Llama 9 |
| Faltung | 06.11., 09:19 bis 07.11., 05:48 | `ap1_de_3.sqlite` | Qwen 5 (HTTP 429) | Qwen 19, Llama 3 |

SHA-256 der Stores nach dem jeweiligen Teil:

- Pilot 1: `eebad3c7ab5f126e837877cb6aea93b84d8f13e925ed9f4a735c7753e8015d95`
- Pilot 2: `ef0c96b4c814e9c99398208e3e44f9a912e0522578a86e32bd9485d1a3b422f5`
- Pilot 3: `05965488d6c0615d0d0f0b5fdc53982db2856206c3df89176dee0c97c75c9b6c`
- Block 1: `b8a601dabda62ba8bba6c52de17fa5c568161f50af7f29b8a130baec2cd873ee`
- Kontrolle: `e5e4460adc7bca833c48a4fab2475cfcb949818ad242443923c9a096c0f55c85`
- Block 2: `8cf63ef14bcd3231a9167797054de603c0cb30df453ef83164170044c0ef86ef`
- Faltung: `d4874511583a9f2ed70210ebb7c160a506214fa161bfb3f748360ada0003b759`

1. **Piloten.** Pilot 1 und Pilot 2 scheiterten je an einem HTTP 429 bei Qwen (Pilotregel: kein HTTP 4xx). Jeder weitere Pilot lief in einem neuen Store; die Stores der gescheiterten Piloten bleiben als Beleg und werden nicht ausgewertet. Pilot 3 bestand.
2. **Reihenfolge** wie in Nr. 2 der Entscheidung. Block 2 begann am 05.11., einen Tag nach Block 1.
3. **Lücken in Blöcken und Faltung** nach Nr. 5 der Entscheidung. Blöcke: kein Nachholen (Qwen 1 von 900 Aufrufen in Block 1, keiner in Block 2). Faltung: Qwen lag in keinem PB-Lauf über 5 % (`pb03` 1, `pb06` 1, `pb10` 2, `pb12` 1 von je 100 Aufrufen); kein Nachholen.
4. **Lücken in der Kontrolle.** Nr. 5 der Entscheidung nennt die Kontrolle nicht. Bei Qwen endeten 17 von 100 Aufrufen mit HTTP 429, alle am 04.11. zwischen 22:29 und 23:14 (17 der 42 Qwen-Aufrufe zwischen dem ersten und dem letzten Fehler; 14 ERepo- und 3 INSAID-Items bei 75 zu 25 im Satz). Sol und Llama hatten keine Backendfehler. Entscheidung des Betreibers vom 11.11.2026, in Kenntnis der Kontrolldaten und ihrer ersten Auszählung: kein Nachholen. Berichtet wird Qwen auf den 81 lesbaren Antworten und zusätzlich auf allen 100 Aufrufen, fehlende Antworten als Nichtübereinstimmung. Gründe: Die Kontrolle misst das englische concise zwischen den beiden Blöcken, nachgeholte Aufrufe lägen danach. Die Reihenfolge der Aufrufe war zufällig und die Fehler fielen in ein Zeitfenster; sie hängen an der Uhrzeit, nicht am Item.
5. **Auswertung** (zu Nr. 6 der Entscheidung). Zwischen `done/M1d` und dem Stand nach M3c sind `R/fit.R` und `R/acmg.R` auf `main` unverändert. Ausgewertet wird mit dem Paketstand nach M3c und den Änderungen aus `56efb0b` auf einem eigenen Branch, nicht mit dem Stand `done/M1d`.

## Nachtrag 11.11.2026: Übernahme nach `main`

Nach `main` kommt nur dieses Dokument. Die `plan.yaml` des Branches ersetzt die englischen Vorlagen des Hauptplans durch die deutschen; `main` behält den freigegebenen englischen Plan (ADR-004), an dem das Verdikt von AP1 hängt. `acmg_pb()` mit `pb_design.fold_over`, `inst/validation/ap1/run_control.R` und der README-Abschnitt des Folgeversuchs bleiben deshalb auf dem Branch `ap1-de`. Eine spätere Übernahme des Codes braucht eine eigene Plandatei für den Folgeversuch und eine eigene ADR (BL-150).
