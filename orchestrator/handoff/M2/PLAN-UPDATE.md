# PLAN-UPDATE — M2, Runde 2

Rolle: Builder · Phase: `20-plan` · Runde: 2 · Stand: 27.10.2026.
Gegenstand: `PLAN-REVIEW.md` und `verdict-plan.json` aus Runde 1.
Status: Antworten und aktualisierter Bauplan zur Prüfung; BUILD und Abnahme
stehen aus. Diese Phase schreibt ausschließlich `PLAN-UPDATE.md`.

## Ziel

Der Umfang bleibt K-M2-1 bis K-M2-7 aus
`docs/03-anwendungspipeline.md`: AP1-Itemsatz, Memorisierungskennzeichen,
Vorlagen und Parser, feste API-Konfiguration, Plan, Pilot, Hauptplan,
Robustheit und Auswertung. Dieses Update schließt die Planlücken E1–E3
und übernimmt die Präzisierungen E4–E15. Alle Einwände werden akzeptiert.

Die folgenden Festlegungen ersetzen die entsprechenden Aussagen von
`PLAN.md` aus Runde 1, insbesondere die Vorgabe `--backend mock`, die
wahlfreie INSAID-Datei im API-Robustheitslauf und die noch ausstehenden
Reviewer-Verträge. Der übrige Plan einschließlich seiner sieben
Abnahmewege gilt weiter. Zahlen vor der Abnahme von M1 bleiben vorläufig
(BL-52); M2 nimmt den Statistikkern nicht vorweg.

Gelesen wurden `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, M2 `CRITERIA.json` einschließlich
ACC-1–ACC-25, `PLAN.md`, `PLAN-REVIEW.md`, das Runde-1-Verdict,
sämtliche Abnahmetests samt Setup-Dateien, `docs/00-vision.md`,
`docs/01-fachspezifikation.md`, `docs/03-anwendungspipeline.md` vollständig
und ADR-004 einschließlich beider Nachträge sowie ADR-005 bis ADR-007.
Zusätzlich gelesen: die Anker zu den hier präzisierten Regeln,
`R/run.R`, `R/backends.R`, `DESCRIPTION`, `.Rbuildignore`,
`tests/fixtures/api/README.md`, `orchestrator/lib/r-tests.R` und die
Zuordnung in `docs/gates-auswahl.md`.

`ARBITER.md` ist nicht vorhanden. `orchestrator/LESSONS.md` enthält noch
keine Lehren. Die Präzedenz Spec > Reviewer > Builder wird angewendet:
Die Auslegungen aus ADR-005/-006/-007 werden übernommen; es gibt keinen
mit Spec-Zitat zurückgewiesenen Punkt. Die erforderliche ADR-Dokumentation
der Reviewer-Auslegungen liegt damit bereits vor.

## Dateien

Die Dateiliste aus `PLAN.md` gilt für den späteren BUILD. Sie erhält
folgende Ergänzungen und Konkretisierungen; diese Phase verändert keine
der dort genannten Produkt-, Test-, Daten- oder ADR-Dateien.

| Pfad im BUILD | Ergänzung gegenüber Runde 1 |
| --- | --- |
| `R/acmg.R` | Interner Konstruktor `acmg_api_backends(plan)`, testbarer CLI-Treiber `acmg_run_cli(args)`, Pilotregeln und Prüfung der Store-Herkunft; Auswertung mit Warnungsdiagnostik, Vollständigkeit und Herkunftskennzeichnung. |
| `inst/validation/ap1/run.R` | Lädt seinen eigenen Quellbaum und ruft den internen CLI-Treiber auf. `--backend` ist ausdrücklich erforderlich; Pilotprüfung vor API-Hauptplan und API-Robustheit, INSAID-Prüfung vor API-Robustheit. |
| `inst/validation/ap1/plan.yaml` | Zusätzlich `provider_name` mit Ankerverweis je OpenRouter-Modell sowie ausgelieferte Zusammenfassungen der Logging-/Datenregeln mit Kurzzitat, Stand und Fundstelle. |
| `tests/testthat/test-acmg-api.R` | Neuer Test des tatsächlich vom CLI verwendeten API-Konstruktors mit Dummy-Schlüsseln, synthetischen HTTP-Antworten und Prüfung des serialisierten Requests. |
| `tests/testthat/test-acmg-pipeline.R`, `test-acmg-evaluate.R`, `test-acmg-data.R` | Ergänzende Fälle T2–T6 unten zu Pilot, Store-Trennung, Rückfall, Itemmerkmalen, unvollständigen Daten und INSAID-Prüfung. |
| `R/parse.R`, `R/run.R`, `R/backends.R`, `R/report.R`, zugehörige Rd-Dateien und `inst/templates/validation_report.Rmd` | Umsetzung genau nach ADR-007; Code unter `R/` in ASCII, F8-Texte aus UTF-8-YAML. Keine neue Exportfunktion. |
| `data-raw/make_items_ap1.R`, vier Dateien unter `inst/extdata/items_ap1_2026-10-24/` | Poolprüfung gegen ANK-51 vor der Auswahl; auch `QUELLE.txt` und `SHA256SUMS` byte-identisch reproduzieren. |
| Neues Golden-ADR unter `docs/decisions/` | Im BUILD, derzeit nächste freie Nummer ADR-008; Nummer vor Anlage erneut prüfen. Begründet das Einfrieren und verweist auf ADR-005. Es muss im Diff seit `plan/M2` liegen. |
| `inst/validation/ap1/README.md`, `man/acmg.Rd`, `NEWS.md`, `PROGRESS.md` | CLI-Pflichten und Pilotformeln dokumentieren; additive Argumente und Temperaturkorrektur nennen; M0-Abschluss nach BL-54 und echte BUILD-Belege ergänzen. |

Die vorgesehenen Suggests `yaml`, `digest`, `pkgload` bleiben wie in
Runde 1 geplant. Installation erfolgt durch das deps-Gate. Die vier
internen Einstiegspunkte behalten ihre in `docs/03` festgelegten
Signaturen; die zusätzlichen Hilfsfunktionen sind ebenfalls intern.

## Schnittstellen

### E1 — API-Backends aus dem ausgelieferten Plan

akzeptiert: `run.R` verwendet über `acmg_run_cli(args)` ausschließlich
`acmg_api_backends(plan)` zum Aufbau der API-Backends. Bezug:
`docs/03` Einleitung, A.4, K-M2-4 und ACC-13. Der Konstruktor liefert
eine nach `key` (`sol`, `llama`, `qwen`) benannte Liste. Der Dispatcher
wählt anhand von `row$model_id` und übergibt die Modellkennung `id` des
zugehörigen Planeintrags an `backend_openai_compatible()`.

| Planeintrag / Herkunft | Abbildung |
| --- | --- |
| `endpoint` | Basis-URL übernehmen; bei einer Chat-Completions-URL den abschließenden Teil `/chat/completions` genau einmal entfernen. Der Backend-Aufruf hängt ihn einmal an. Beide Formen von ACC-13 sind unterstützt. |
| `id`, `seed` | Modellkennung und API-Seed aus dem jeweiligen Modellelement; der Design-Seed ist davon getrennt. |
| `reasoning` | Nur ein gesetzter Wert wird als `reasoning_effort` durchgereicht. Es wird kein Body-Feld `reasoning` erzeugt. |
| `temperature` | Den Wert ausdrücklich an das Backend übergeben, bei YAML-`null` ausdrücklich `temperature = NULL`. Dadurch greift nicht dessen Vorgabe 0; im HTTP-Body fehlt dann das Feld ganz. |
| `provider_order`, `quantizations` | Bei Routing beide Listen verlangen und als `provider = list(order = as.list(...), allow_fallbacks = FALSE, quantizations = as.list(...))` übergeben. Damit bleiben auch Einzelelemente JSON-Arrays. Ohne Routing kein `provider`-Objekt. |
| Tokenannahmen | Nur Kostenrechnung, kein daraus abgeleitetes `max_tokens`. Auch `/no_think` wird nicht eingefügt. |
| Host `api.openai.com` | Ausschließlich den zur Laufzeit gesetzten Wert von `OPENAI_API_KEY` ausdrücklich als `api_key` übergeben. |
| Host `openrouter.ai` | Ausschließlich `OPENROUTER_API_KEY` ausdrücklich übergeben; niemals auf die Backend-Vorgabe für OpenAI zurückfallen. |

Die Hostprüfung erfolgt auf dem geparsten HTTPS-Host, nicht durch eine
Teilzeichenkettensuche. Unbekannte Endpunkte, inkonsistente Routinglisten
und fehlende oder leere erforderliche Schlüssel führen vor dem ersten
Request zu einem benannten Fehler. Die Fehlermeldung nennt nur das
fehlende Feld beziehungsweise den Variablennamen. Schlüssel und Header
gelangen nicht in Ausgabe, Logs, Store, Bericht oder `meta`.
Mock- und reine Auswertungspfade lesen keine API-Schlüssel.

T1 prüft URL, Authorization und den tatsächlich serialisierten JSON-Body
je Modell gegen die ausgelieferte YAML und die Feldstruktur der
Produktions-Bodies aus `tests/fixtures/api/README.md`. Die API-Backends
werden im Test nicht nochmals unabhängig vom Produktkonstruktor gebaut.

### E2 — Rechenregeln und Wirkung des Pilots

akzeptiert: ADR-006 Nr. 7.1–7.8 und Nr. 1 werden vollständig übernommen
(K-M2-7, A.6, ANK-67). Ausgewertet werden alle gespeicherten Pilotzeilen
des Modells, einschließlich Fehlern und früherer fortgesetzter Läufe.
Die geplanten Schlüssel sind die zehn Pilotitems mit den drei Vorlagen
und einem Replikat; Duplikate ersetzen keinen fehlenden Aufruf.

| Regelstichwort | Entscheidung |
| --- | --- |
| `4xx` | Bestanden, wenn keine gespeicherte Backend-Fehlermeldung einen HTTP-Status 400–499 meldet. Die Erkennung ist dokumentiert und unterscheidet HTTP-Status von beliebigen Zahlen im Text. |
| `provider` | OpenRouter: Jede Zeile ohne Backendfehler muss `meta$provider` passend zu `plan$models[[...]]$provider_name` tragen. `CoreWeave` und `DeepInfra` stammen aus ANK-54/55, nicht aus einem Vergleich mit dem Endpunkt-Tag. Fehlender/abweichender Anbieter bedeutet `failed`; bei fehlendem Anbieter folgt der Hinweis auf die Betreiber-Stichprobe nach K-M2-4. Sol: direkter OpenAI-Endpunkt, jede erfolgreiche Zeile aus einem API-Aufruf mit `id` und `model_snapshot`; Begründung `direct endpoint`. |
| `parser` | Alle 30 geplanten Zeilen müssen vorliegen, mindestens 27 mit erkannter Klasse. Fehlerzeilen sind Nichttreffer. Die Referenzklasse spielt für diese Regel keine Rolle. |
| `cost` | Für jedes Modell muss mindestens eine Zeile ohne Fehler vorliegen, und jede solche Zeile muss `usage.completion_tokens` tragen. Je Modell wird die Projektion berechnet; entscheidend ist ihre Summe über alle drei Modelle. |

Die Kostenformel nach ADR-006 Nr. 7.4 lautet bei Preisen in USD je
Million Tokens:

```text
q90_m = quantile(completion_tokens of successful pilot rows, 0.9, type = 7)
p_m   = 3000 * (1000 * price_in_m + q90_m * price_out_m) / 10^6
S     = sum(p_m for sol, llama, qwen)
cost passed for each model iff usage is complete as above and S < 150
```

Aufruf- und Tokenzahlen kommen aus ANK-56, Quantil und Pilotumfang aus
ANK-67, Budget und Währungsregel aus ANK-57. Reasoning-Tokens werden
nicht nochmals addiert. Es wird kein Wechselkurs verwendet.

Mock-Zeilen bestehen weder `provider` noch `cost`; fehlende Messungen
werden nicht erfunden. `4xx` besteht beim fehlerfreien Mock.
`--part pilot` berichtet je Modell alle vier Regeln mit
`passed`/`failed` und Begründung, p_m und S, Latenzmedian sowie Median
und 90-%-Quantil der Reasoning-Tokens. Die Pilotauswertung endet auch
bei gescheiterten Regeln mit Exit 0. Ungültige Aufrufe oder
Infrastrukturfehler bleiben benannte Fehler.

Für `--backend api` sperrt ein fehlender, unvollständiger, synthetischer
oder nicht in allen Regeln bestandener Pilot sowohl `main` als auch
`robustness`: Exit ungleich 0, gescheiterte Regeln benannt, kein
API-Aufruf. Nach Resume gilt dieselbe Prüfung auf dem gesamten Store.
Mock-Teile bleiben für die Abnahme unabhängig ausführbar.

Nach jedem Hauptplanblock werden die drei Wiederholungstagsauslöser
gemäß Nr. 7.8 berichtet: abweichender/wechselnder Anbieter, wechselnde
Modellkennung und Backendfehleranteil strikt über ANK-67.error_share_trigger.
Unlesbare Antworten sind für diesen Fehleranteil keine Backendfehler.
Ein Wiederholungstag wird nicht automatisch gestartet. Testfälle: T2.

### E3 — Expliziter Modus und getrennte Stores

akzeptiert: ADR-006 Nr. 9. `--backend mock|api` hat keine Vorgabe und ist
auch bei `--evaluate-only` ausdrücklich anzugeben. Fehlt es, folgt ein
benannter Fehler vor Store-Schreiben oder Backend-Aufruf. Die Vorgabe
des Store-Pfads bleibt `../llmsa-runs/ap1_runs.sqlite` außerhalb des
Arbeitsbaums (K-M2-6).

Der AP1-Treiber hält die Art `mock`/`api` dauerhaft in einer eigenen
Metadatentabelle `ap1_metadata` des SQLite-Stores fest und prüft sie vor jeder
Ausführung gegen den verlangten Modus und gegen die vorhandenen
Antwortmetadaten. Die Tabelle `runs`, ihre Spalten und `run_key` bleiben
unverändert (ADR-007 Nr. 2). Bei einem neuen Store werden die Moduskennung
und eine leere `runs`-Tabelle mit dem bestehenden Schema zusammen
initialisiert, damit `msa_run(resume = TRUE)` bereits beim ersten Lauf
einen lesbaren Store vorfindet. So ist auch ein Store mit ausschließlich
Fehlerzeilen ohne Antwort-`meta` einem Modus zugeordnet. Widersprüchliche
oder bei einem vorhandenen Store nicht belegbare Herkunft führt zum
benannten Abbruch; sie wird nicht als API-Herkunft geraten.

Es werden weder Mock-Zeilen in einen API-Store noch API-Zeilen in einen
Mock-Store geschrieben. Die Prüfung erfolgt auch vor Resume, selbst
wenn kein neuer Schlüssel mehr auszuführen wäre. Eine gescheiterte
Prüfung ändert keine vorhandenen Zeilen oder Moduskennzeichnungen.

`acmg_evaluate()` prüft die Herkunft vor dem Fit und Rendern. Gemischte
Mock-/API-Eingaben werden benannt abgewiesen. Reine Mock-Ergebnisse und
ihre Berichte tragen sichtbar die Kennzeichnung `synthetic`. Der
CLI-Treiber gibt die Store-Herkunft beim Einlesen im Speicher weiter;
`meta$mock` bleibt erhalten. Die konstruierten `msa_runs` ohne `meta`
aus K-M2-6 bleiben auswertbar; ihre Herkunft ist nicht belegt und wird
nicht als API-Erhebung bezeichnet. Solche Daten erteilen keine
Pilotfreigabe. Testfälle: T3.

### E4 — Auslöser und Art des numerischen Rückfalls

akzeptiert: ADR-006 Nr. 4. Der Aufruf erfolgt über `msa_fit()` mit
`type = "ordinal"`, Klassen in Skalenordnung und `link = "probit"`.
Fehler oder Konvergenzwarnung lösen den numerischen Rückfall aus.
Die Erkennung prüft Meldungen ohne Beachtung der Groß-/Kleinschreibung
auf `converge`, `Hessian`, `max|grad`, `gradient`, `unidentifiable`,
nicht auf den speziellen Text des erzwungenen Abnahmetestfehlers.
Die bloße Umstellung von ucminf auf nlminb und eine Nullkomponente
allein lösen keinen Rückfall aus.

Der Rückfall bildet ausschließlich `value` auf die Scores 1–5 nach
ANK-68 ab, erhält NA und verwendet
`msa_fit(..., type = "numeric")` mit sämtlichen Paketvorgaben,
einschließlich `interactions = TRUE`, danach `msa_grr()`.
Alle Warnungen beider Fits, Rückfallgrund und verfügbare clmm-Diagnostik
(Iterationen, max|grad|, Hesse-Konditionszahl) bleiben im Ergebnis und
Bericht. Diagnostikwerte sind kein zusätzlicher Auslöser. Ein Fehler
des numerischen Fits wird benannt weitergegeben. Der gemeinsame Fit
folgt derselben Regel, bleibt aber `msa_fit` ohne GRR und Verdikt. T4.

### E5 — Zeilenfolge für die Engine-Gegenrechnung

akzeptiert: ADR-006 Nr. 4.1. Nach der Auswahl der Hauptplanzeilen je
Modell werden sie in übergebener Reihenfolge und mit unveränderten
Spaltentypen an den ordinalen Fit weitergereicht; keine Sortierung oder
Deduplikation. Auch der gemeinsame Fit erhält diese Reihenfolge.
Der Item-Join im CLI erhält die Reihenfolge der Store-Zeilen.
Die direkte Gegenrechnung verwendet ANK-TOL.engine_ordinal.
Die separate Permutationsprüfung bleibt bei ANK-TOL.invariance und
berechtigt nicht zur Änderung der Engine-Toleranz. T4.

### E6 — Herkunft der Itemmerkmale

akzeptiert: ADR-006 Nr. 11 und ADR-005 Nr. 3. `acmg_evaluate()` liest
`reference`, `source`, `prior_differs_*` und weitere Itemmerkmale
ausschließlich aus `runs`. Fehlende erforderliche Spalten sind ein
benannter Fehler. IDs aus `acmg_items()` dienen dort nur zur Trennung
von Hauptplan, Pilot und Robustheit. Vorhandene Itemspalten werden
nicht aus der eingefrorenen CSV überschrieben; die TSV wird hier
nicht selbst gelesen.

Der Satz zur erneuten Store-Lektüre in Runde 1 gilt für `run.R`:
Der CLI-Treiber liest alle gespeicherten Zeilen und ergänzt im Speicher
passende Merkmale aus `acmg_items(insaid_path = ...)`, auch bei
`--evaluate-only`. Leeres `prior_differs_*` wird NA, niemals FALSE.
Die Auswertungsgruppen heißen `"TRUE"` und `"FALSE"`; unbekannte Werte
gehören zu keiner davon. Ohne optionale TSV bleiben INSAID-Referenzen
NA und verursachen keinen Auswertungsfehler. T4/T5.

### E7 — Vollständigkeit und nicht definierte Kennzahlen

akzeptiert: ADR-006 Nr. 8 und Nr. 10. Je Modell muss jedes Hauptitem
genau 18 Hauptplanzeilen haben, einschließlich Fehlerzeilen. Bei
Abweichung werden vorhandene Kennzahlen, soweit definiert, und
Vollständigkeitszählungen berichtet; sämtliche Kriterienverdikte und
das Gesamtverdikt lauten `not assessed`. Es wird weder dedupliziert
noch aufgefüllt. Für Fehler der Fits gilt weiterhin E4.

Robustheit ist nur mit allen zwölf PB-Prompt-IDs und genau einer Zeile
je Hauptitem und Modell in jedem Lauf bewertet. Der Nenner n enthält
NA- und Fehlerzeilen. In x zählen nur fehlerfreie, nicht fehlende
Antworten, die einer vorhandenen, nicht fehlenden Hauptplan-Modalantwort
gleichen. Fehlende/zusätzliche oder doppelte Zeilen verhindern eine
vollständige Bewertung. Nicht definiertes Kappa oder %GRR ergibt
`not assessed` für das Kriterium und für das Gesamtverdikt, niemals
ein positives Band. T4.

### E8 — INSAID-Datei vor API-Robustheit

akzeptiert: ADR-006 Nr. 12. `--part robustness --backend api` verlangt
`--insaid-path` und prüft die lokale Datei vor dem ersten Request
gegen die ausgelieferte SHA-256 aus `QUELLE.txt` (Herkunft ANK-52).
Fehlen oder abweichender Hash führen zum benannten Fehler.
Bei Hauptplan und reiner Auswertung bleibt die Ergänzung optional;
die Mock-Abnahme kann ohne TSV laufen.

INSAID-Referenz und -p.-Angabe bleiben im Speicher; F2 + verwendet die
p.-Angabe im Request. Sie werden nicht in Store, Log, Prompt-Dump oder
Berichtstabelle je Variante geschrieben. Berichtet werden ausschließlich
die zulässigen Aggregate. T5 prüft Vorbedingungen und Ausgabepfade.

### E9 — Paketbau und verfügbare Testressourcen

akzeptiert: Die Vorgaben von `20-lint` und `docs/01` §5 werden umgesetzt.
`R/` enthält ASCII-Code und -Kommentare; die vorgegebenen deutschen
F8-Bausteine werden aus UTF-8-YAML gelesen, notwendige Zeichenliterale
mit Unicode-Escapes geschrieben. Unit-Tests verwenden ausgelieferte
Paketressourcen und kleine ausdrücklich synthetische Daten, ohne
`../quellen/`, `reference/`, `tests/fixtures/` oder den nicht
ausgelieferten Ordner `data-raw/` vorauszusetzen.

Für benötigte Suggests verwenden Unit-Tests `skip_if_not_installed()`
nach der Spec; die Abnahme bleibt ohne solche Ausweichpfade. Nach
roxygen2 werden die 22 Exporte und bisherigen Signaturen gegen ANK-02
geprüft. `acmg_*` und die Hilfsfunktionen bleiben intern. T1/T6/T7.

### E10 — Poolprüfung und deterministische Golden-Dateien

akzeptiert: ADR-005 Nr. 7 und Nr. 8. Vor der Auswahl wird der Pool gegen
ANK-51 geprüft: 1.180 Einstufungen, 71 Gene, 35 Panels und die
Ankerzahlen je Klasse. Abweichungen beenden den Lauf vor einer
Ausgabeänderung. Es gelten ausdrücklich
`RNGkind("Mersenne-Twister", "Inversion", "Rejection")`, Seed ANK-59,
gebietsschemaunabhängige Sortierung/Datumsverarbeitung und UTF-8/LF.

Alle vier Dateien (`items.csv`, `pilot.csv`, `QUELLE.txt`,
`SHA256SUMS`) sind bei Wiederholung byte-identisch. Die Begleitdateien
enthalten keine Laufzeitstempel oder Sitzungsdaten; `SHA256SUMS` deckt
die drei anderen Dateien ab. ADR-008 beziehungsweise die dann nächste
freie Nummer entsteht zusammen mit den Golden-Dateien im BUILD;
ADR-005/-006/-007 vor `plan/M2` ersetzen diesen Nachweis nicht. T6.

### E11 — Ausgelieferte Logging- und Datenregeln

akzeptiert: Für A.7 erhält `plan.yaml` einen Abschnitt
`reporting.policies` mit getreuen kurzen englischen Zusammenfassungen,
Kurzzitat, `snapshot_date: "2026-10-22"`, URL und Fundstelle der
Schnappschüsse `Provider_Logging.html` und `Your_data.html`.
Die Inhalte werden im BUILD aus den benannten lokalen Quellen
übernommen. `acmg_evaluate()` liefert sie aus dem Plan an
`msa_report()`; beide benötigen zur Laufzeit keine Dateien unter
`../quellen/` oder im Harness. T7 prüft den gerenderten Inhalt in einer
Umgebung, die nur Paketressourcen hat.

### E12 — Testausführung und Artefakte

akzeptiert: Tests im Checkout verwenden die Source-Ladung des
Test-Gates. Alle Stores, Berichte, Grafiken, Paketkopien und temporären
Ausgaben werden ausdrücklich unter `tempdir()` beziehungsweise einem
externen Ziel angelegt. Vor Testbeginn und vor Phasenende werden
Dateilisten ohne Git verglichen; Diagnose und Herkunft neuer Dateien
werden festgehalten. Ein gezieltes Grafikgerät verhindert
`Rplots.pdf` im Arbeitsbaum. M0-Tests mit Git-Unterprozessen und die
vollständigen Gates führt ausschließlich der Orchestrator aus.
Die aktualisierten Prüfwege stehen unter Testplan; Bezug BL-55.

### E13 — Freigegebene additive Verträge

akzeptiert: ADR-007 ist der zentrale Reviewer-Vertrag. Umgesetzt werden
`parse_choice(..., whole_word = FALSE)`,
`msa_run(..., parse_by_prompt = NULL)`,
`msa_report(..., assessment = NULL)` und die dort beschriebene
Backend-Verarbeitung. Insbesondere sind zusätzliche, im aktuellen
Design unbenutzte Namen in `parse_by_prompt` zulässig; leere/doppelte
Namen oder Nichtfunktionen werden vor dem ersten Aufruf abgewiesen.
`NULL` bewahrt das bisherige Lauf-/Berichtsverhalten.
Rd-Seiten und NEWS folgen diesem Vertrag; NEWS nennt auch die
Temperaturkorrektur. ANK-02 wird nicht geändert. T7.

### E14 — Berichtstest im vollständigen Gate

akzeptiert: `[INFRA]`, nonblocking für den Builder; Bezug BL-56.
Der Betreiber entscheidet vor BUILD von M2 über `NOT_CRAN=true` im
Test-Gate. Der Reviewer führt BL-56 im Code-Review fort. Der Builder
ändert weder Gate-Konfiguration noch bestehende Skips. Die direkte
Renderingprüfung T7 und die M2-Abnahme bleiben eingeplant.

### E15 — Zuordnung der Gate-Kriterien

akzeptiert: `[INFRA]`, nonblocking für den Builder; Bezug BL-48,
`docs/gates-auswahl.md` §3. Die Datei liegt unter `docs/`; die
Ablageaussage aus Runde 1 ist damit ersetzt. Der Betreiber ergänzt
K-M2-7 in der tests-Zeile. trace prüft gegen das Manifest und ist
hiervon nicht betroffen. Die sieben M2-Abnahmedateien bleiben im
geplanten Lauf enthalten.

Die bisherigen ACC-Verträge gelten mit den nun vorliegenden ADRs:
ADR-005 Nr. 1–8 legt ACC-1–6, ACC-16/-17 fest; ADR-006 legt
ACC-7/-9/-19–22 und die oben genannten Laufregeln fest; ADR-007
bestätigt ACC-10/-18 und die öffentlichen Ergänzungen. ACC-8/-11–13
gelten mit den Präzisierungen dieses Updates. ACC-14/-15/-23–25
bleiben wie in Runde 1 zugeordnet. ADR-006 Nr. 13 gilt auch für die
Sprache der YAML: Prosa getreu englisch, Zahlen, Bezeichner und
freigegebene Vorlagen/Bausteine zeichengleich, F8-Deutsch erhalten.

## Reihenfolge

1. Nach Planfreigabe die akzeptierten ADRs als BUILD-Grundlage verwenden,
   Suggests deklarieren und den M0-Abschluss nach Lektüre seiner echten
   Gate-/Review-Fakten in PROGRESS ergänzen (BL-54).
2. YAML samt Quellenverweisen, `provider_name` und Berichtstexten sowie
   Parser und die additiven Verträge umsetzen. Den zentralen
   API-Konstruktor direkt mit T1 prüfen.
3. Lokale Daten prüfen, Pool und Auswahl nach ADR-005 erzeugen, alle vier
   Ausgabedateien in temporärer Kopie reproduzieren und das Golden-ADR
   im BUILD anlegen.
4. Store-Modus, Pilotberechnung und Sperren implementieren und mit
   T2/T3/T5 prüfen, bevor der API-Pfad des CLI vollständig verbunden
   wird. Dann Vorlagen, blockweise Reihenfolge und Resume integrieren.
5. Auswertung mit erhaltener Zeilenfolge, Warnungserfassung, Rückfall,
   unveränderten Itemmerkmalen und Vollständigkeitsregeln umsetzen;
   T4 und die unabhängigen M2-Gegenrechnungen ausführen.
6. Berichte, externe Ausgaben, README, Rd und NEWS fertigstellen;
   Rendering und Kompatibilität nach T7 prüfen.
7. Unit- und gezielte M2-Abnahmeläufe abschließen, reale Outputs,
   Laufzeiten und Befunde in PROGRESS/Handoff berichten und die
   Dateiinventur durchführen. Der Orchestrator übernimmt danach
   Territoriumsprüfung, Commit, QA und vollständige Gates.

## Risiken

| ID / Bezug | Behandlung |
| --- | --- |
| PLAN-M2-R1; K-M2-1/2 | Auswahl- und Memorisierungslesarten sind durch ADR-005 festgelegt. Unit-Fälle binden genau diese Lesarten; keine Auswahl anhand späterer Modellergebnisse. |
| PLAN-M2-R2; ACC-17/24 | ClinVar-Laufzeit und Locale: blockweise Verarbeitung, Prüfungen vor Schreiben und deterministische Ausgabe; volle Reproduktion im Quellbaum-Prüfweg, nicht im CRAN-Unit-Test. |
| PLAN-M2-R3; E4–E7, BL-03/52 | Warnungen, Reihenfolge und unvollständige Daten können Bewertungen verfälschen. Expliziter Rückfall, Diagnostik und `not assessed`; M1-Validierung bleibt ausstehend. |
| PLAN-M2-R4; BL-07/43/62 | Antwortmetadaten und Anbieter können sich ändern. Pilot nutzt gespeicherte Messwerte; Live-Prüfung und etwaige Planänderung per ADR bleiben beim Betreiber. |
| PLAN-M2-R5; E3/E12, BL-55 | Modusverwechslung und Artefakte: beidseitige Store-Sperre einschließlich Fehlerzeilen, externe Ausgaben und Dateiinventur. |
| PLAN-M2-R6; E1 | Falscher Schlüssel oder JSON-Skalar statt Routingarray: zentraler Konstruktor, Hostzuordnung und Prüfung des serialisierten Requests im Unit-Test. |
| PLAN-M2-R7; E2 | Falsch verstandene Pilotregeln könnten die Erhebung sperren oder freigeben: Parser-Erkennung unabhängig von Richtigkeit, feste Nenner, Summenkostenregel und Null-Request-Nachweis bei Sperre. |
| PLAN-M2-INFRA-1; E14/BL-56 | Entscheidung zu NOT_CRAN vor BUILD durch Betreiber; für Builder nonblocking. |
| PLAN-M2-INFRA-2; E15/BL-48 | K-M2-7 in der Gate-Zuordnung durch Betreiber nachtragen; für Builder nonblocking. |
| PLAN-M2-QA-1; AGENTS, docs/01 §9 | QA ab M2 Pflicht. E2E/Fuzz und QA-Handoff gehören der QA-Phase; bis dahin `[QA-PENDING]`, für Builder nonblocking. |

### Jeder offene Backlog-Eintrag

Die 54 offenen Einträge werden wie folgt übernommen beziehungsweise
begründet vertagt. Das Update ändert `BACKLOG.md` nicht und erklärt
keinen Eintrag aufgrund einer bloßen Planentscheidung für erledigt.

| ID | Behandlung oder begründete Vertagung |
| --- | --- |
| BL-01 | M2 priorisiert die AP1-Erhebungspipeline. Über M3a–M3d entscheidet der Betreiber nach M1d anhand von Zeit und Budget. |
| BL-02 | Vertagt auf Publikationsarbeit nach AP1/M1: Neuheitsabgrenzung ist kein M2-Kriterium. |
| BL-03 | Numerischer Rückfall in M2 nach E4; Zwei-Stufen-Validierung bleibt M1b/M1d. |
| BL-04 | Überdeckung der Varianzkomponenten bleibt M1c/M1d/AP5; M2 liefert den spezifizierten Kappa-Item-Bootstrap. |
| BL-05 | M2 liefert drei Stichtage und Memorisierungsstrata mit Vorbehalt; leere Kennzeichen bleiben unbekannt (E6). |
| BL-06 | Betreiber prüft Modellzugang und M0-Umleitung; keine Rollen- oder Schlüsselkonfiguration durch den Builder. |
| BL-07 | Festes Routing, getrennte Anfrage-/Antwortmetadaten und Anbieterregel nach E1/E2. |
| BL-08 | Vertagt auf AP7: keine Partnerdaten in AP1; Vereinbarung vor späterer Nutzung beim Betreiber. |
| BL-09 | M2 hält INSAID-Referenzen/Protein lokal und Berichte aggregiert; Zitatprüfung bleibt Reviewer-Aufgabe. |
| BL-10 | Preprint hängt weiter an M1-Abnahme und erneuter AP1-Auswertung; M2 kennzeichnet Zahlen vorläufig. |
| BL-11 | Kostenabgleich mit Dashboard beim Betreiber; protokollierte Tokens werden nicht in erfundene Eurokosten umgerechnet. |
| BL-12 | Vollläufe nach M1b/M1c, vor M1d beim Betreiber; M2 hat keine Klasse-B-Studie. |
| BL-13 | M2-Laufzeiten tatsächlich messen und dokumentieren; Simulationsbudgets in M1a erneut prüfen, Timeoutänderung beim Betreiber. |
| BL-14 | Unabhängige Kernvalidierung und mutfull bleiben M1a–M1c; keine vorgezogene Abnahme in M2. |
| BL-15 | Fleiss-Kappa und Projektdokumentkorrektur bleiben M3a beziehungsweise Betreiberpflege, außerhalb AP1. |
| BL-16 | Temperaturfeld bei NULL auslassen, Routingmetadaten und NEWS in M2; E1/E13. |
| BL-17 | ellmer-Aufzeichnungen bleiben K-M3d-3, Liveprüfung AP2; AP1 nutzt den kompatiblen HTTP-Backendpfad. |
| BL-18 | Laufdatenhash-Umstellung bleibt M3d, Bootstrap-Meldung M1c; neue M2-Golden-Dateien erhalten SHA-256. |
| BL-20 | wine-Kovariatenvergleich bleibt K-M1b-1; kein Bestandteil des AP1-Designs. |
| BL-21 | Reviewer-Zuordnung der geschachtelten NIST-Studie bei M1a/Ankerarbeit; kein M2-Kriterium. |
| BL-22 | AIAG-Pooling bleibt K-M1a-2. M2-Rückfall nutzt Paketvorgaben einschließlich Wechselwirkungen (E4). |
| BL-23 | Zentrierung/NIST-Genauigkeit bleibt K-M1a-4/-6; keine Fit-Kernänderung für M2 geplant. |
| BL-24 | Betreiber setzt vor M3a die Mutationsbaseline beim Scope-Wechsel zurück; kein Builder-Eingriff. |
| BL-25 | Golden-ADR im BUILD zusammen mit dem Itemsatz (E10); Ankernachträge mit ADR bleiben Reviewer-Aufgabe. |
| BL-28 | Schlüssel, Guthaben und Limits vor Live-Pilot durch Betreiber; Builder-Tests ausschließlich mit Dummy-Werten (E1). |
| BL-29 | Infevers-Anfrage durch Betreiber; bis zur Klärung lokale Ergänzung und aggregierte Ausgabe nach E8. |
| BL-30 | GitHub/Pages/Zenodo/Release bleiben AP2-Veröffentlichungsarbeit, für M2 nicht erforderlich. |
| BL-31 | Git-Identität ist Betreiberkonfiguration; keine Git-Kommandos des Builders. |
| BL-33 | QA-PREFLIGHT und CLI-/Sandboxkonfiguration prüft der Betreiber vor QA, außerhalb Produktcode. |
| BL-34 | Erreichbarkeit im RUNBOOK durch Betreiber; Eskalationen nur über den vorgesehenen Orchestrator-Touchpoint. |
| BL-35 | Benachrichtigungsfehler bleibt Template-Backlog; projektspezifische Einstellung ist Betreiberzuständigkeit. |
| BL-36 | Rohdaten bleiben außerhalb und werden blockweise gelesen; etwaiger WSL-Umzug ist Betreiberarbeit. |
| BL-37 | Harness-Kostenspur und Dashboard-Abgleich beim Betreiber, zusammen mit BL-11. |
| BL-39 | Beschaffung bleibt bei späteren Modulen/AP7 und Betreiber; M2 ergänzt keine unbelegten Normwerte. |
| BL-40 | Konkordanzquellen bleiben M1d/Publikationsvergleich; AP1-Schwellen aus ANK-58 bleiben fest. |
| BL-41 | Bänder als Betreiberentscheidung darstellen; Literaturzuschreibung nur mit beschafftem Beleg. |
| BL-42 | Geschützte AIAG-/Lenth-Blätter zwischen Phasen durch Betreiber; Originalabgleich beim zuständigen Reviewer, nicht für M2 erforderlich. |
| BL-43 | M2 übernimmt geerntete Konfiguration. Betreiber prüft Preise/Katalog unmittelbar vor AP1 live; Änderung nur per ADR. |
| BL-44 | Fleiss-Varianzquelle bleibt K-M3a-2, außerhalb des AP1-Kappa. |
| BL-45 | Externe Projektfassungen nach Meilenstein durch Betreiber pflegen; außerhalb Builder-Territorium. |
| BL-46 | Zusätzliche Vignetten bleiben M1d; M2-Berichte außerhalb des Repos, kein Live-Lauf beim Paketbau. |
| BL-47 | Autorenhinweis bei späteren Veröffentlichungen durch Betreiber; VariantBench ist keine M2-Datenquelle. |
| BL-48 | Aktueller Pfad `docs/gates-auswahl.md`; Betreiber ergänzt K-M2-7, Reviewer prüft Zuordnung (E15). Maschinelle Prüfung bleibt Betreiberarbeit. |
| BL-49 | REML/ANOVA-Toleranz bleibt K-M1a-1. M2 nutzt engine_ordinal für direkte Fits und invariance separat (E5). |
| BL-50 | Planungsnäherung/CV bleibt K-M3c-6; AP1-Anzahlen sind bereits festgelegt. |
| BL-51 | Alle acmg-Funktionen intern; Exportentscheidung erst nach AP1 per ADR. |
| BL-52 | Externer Store, vorläufige Kennzeichnung und erneute Auswertung nach M1 ohne neue Aufrufe. |
| BL-53 | Reviewer prüft im ersten M2-Code-Review den done/M0-Testzweig im Gate-Log; Builder startet diesen Git-Prüfweg nicht. |
| BL-54 | Im M2-BUILD M0-Abschluss in PROGRESS mit tatsächlichen Gate-/Review-Verweisen ergänzen. |
| BL-55 | Externe Artefakte und Dateiinventur (E12); Betreiberdateien nur zwischen Modellphasen, Templateänderungen beim Betreiber. |
| BL-56 | NOT_CRAN-Entscheidung vor M2-BUILD durch Betreiber; nonblocking. Builder belegt gezieltes Rendering (E14/T7). |
| BL-57 | Neue Argumente haben Vorgaben am Ende nach ADR-007; zusätzliche Signaturprüfung im BUILD und Code-Review. |
| BL-60 | ellmer-Streaming/Mock-Erreichbarkeit bleibt vor K-M3d-3 zu prüfen; nicht der M2-Backendpfad. |
| BL-62 | Reasoning-Tokens und fehlende Fingerprints berichten; Wirkung durchgehend null Tokens klärt Betreiber im Pilot, keine eigenmächtige Änderung der Reasoning-Stufe. |

Erledigt und nicht wieder geöffnet: BL-19, BL-26, BL-27, BL-32, BL-38,
BL-58, BL-59, BL-61. Die Nachträge zu ADR-004 gelten weiterhin.

## Testplan

### Ergänzungen für BUILD und Gates

Die sieben Abnahmedateien `test-m2-1-items.R` bis
`test-m2-7-robustness-pilot.R` mit insgesamt 62 Testblöcken bleiben
unverändert. Der Testplan aus Runde 1 wird um folgende Nachweise
erweitert. Unit-Fälle verwenden kleine synthetische Daten und prüfen
beobachtbares Verhalten; echte Aufzeichnungen und Rohdaten bleiben im
unveränderten Acceptance-Prüfweg.

| ID / Einwände | Konkreter Nachweis |
| --- | --- |
| T1 / E1, E9 | `test-acmg-api.R`: Ausgelieferte YAML lesen, beide Schlüsselvariablen lokal mit verschiedenen Dummy-Werten setzen, echten Produktkonstruktor verwenden. Je Modell URL, Authorization und JSON nach Serialisierung mit `simplifyVector = FALSE` prüfen: Arrays auch bei Länge 1, `allow_fallbacks` false, korrektes Modell/Seed, Sol ohne Temperatur/Provider, OpenRouter mit Temperatur 0, kein `reasoning`/`max_tokens`, kein fremder Schlüssel. Beide endpoint-Formen und fehlende Schlüssel testen; bei Fehler null Requests. Unerwartete Requests beenden den Mock mit Fehler, niemals mit NULL. Ein kurzer API-Pilot mit synthetischen httr2-Antworten durch denselben CLI-Treiber belegt die Verdrahtung. Keine Laufzeitabhängigkeit des Tests von der Fixture-README. |
| T2 / E2 | Pilot mit 26/27/30 erkannten Klassen, auch bei absichtlich falscher Referenz; unvollständige/duplizierte Schlüssel, Fehlerzeilen und Resume. HTTP 400/499 gegenüber 500 und bloßen Zahlen ohne HTTP-Status; passender, fehlender, abweichender Provider; Sol mit/ohne API-Metadaten. Fehlende usage, fehlendes completion_tokens, kein Erfolg eines Modells, Summe oberhalb/genau/unter Budget, obwohl Einzelbeträge darunter liegen; Reasoning wird nicht doppelt gezählt. Mock besteht weder Provider noch Kosten. Pilot-Exit 0 bei Regelversagen; API-main und API-robustness mit gescheitertem Pilot: Exit ungleich 0, null Requests, unveränderter Store. Wiederholungstag genau bei mehr als 5 %, Anbieter-/Modellwechsel und Backendfehlern gemäß ANK-67. |
| T3 / E3 | Fehlendes --backend: benannter Fehler ohne Schreiben. API in Mock-Store und Mock in API-Store: Abbruch vor Aufruf und unveränderte Zeilen/Moduskennung, auch nach Resume und mit ausschließlich Fehlerzeilen. Widerspruch zwischen Kennzeichnung und meta wird erkannt. Gemischte Auswertung scheitert vor Fit/Rendering; reine Mock-Ergebnisse und tatsächlicher Bericht sind als synthetic markiert. Konstruktion ohne meta bleibt auswertbar, aber ohne behauptete API-Herkunft. --evaluate-only führt keine Requests aus und liest keine Schlüssel. |
| T4 / E4–E7 | Fehler und jede Warnungsfamilie lösen den Rückfall aus; ucminf-Umstellung, Nullkomponente und bloße Diagnostikwerte nicht. Alle Warnungen erscheinen im Objekt und Bericht. Numerischer Fit mit Paketvorgaben gegen direkten msa_fit()/msa_grr()-Aufruf; gemeinsamer Fit ohne Verdikt. Prüfung der unveränderten übergebenen Zeilenfolge und separate Permutationsprüfung. Ergänzte INSAID-Referenzen werden nicht überschrieben; fehlende Itemspalte scheitert; NA-prior in keiner TRUE/FALSE-Gruppe. Fehlende, zusätzliche und doppelte Haupt-/PB-Zeilen verhindern volle Bewertung; NA-/Fehlerzeilen bleiben im Nenner. Nicht definiertes Kappa/%GRR ergibt not assessed, ebenso das Gesamtverdikt. |
| T5 / E6, E8 | API-Robustheit ohne TSV oder mit falscher SHA-256 scheitert vor dem ersten Request. Hash-/Importhelfer mit kleiner als synthetisch markierter TSV und explizitem erwarteten Testhash prüfen; Produktionshash weiterhin aus ausgelieferter Provenienz nach ANK-52. F2 +/− verändert den Request korrekt. Keine Referenz-/Proteinspalten oder entsprechenden Texte in persistenten Ausgaben; Aggregatbericht zulässig. Ohne TSV bleibt die reine Auswertung mit NA-Referenzen möglich. |
| T6 / E9, E10 | Poolabweichung beendet den Datenerzeuger vor jeder Änderung. Volle Neuerzeugung in temporärer Quellbaumkopie unter C- und verfügbarer abweichender Kollation: alle vier Dateien byte-identisch, SHA256SUMS vollständig. Dieser Testweg gehört zur BUILD-Diagnose/Abnahme mit echten Quellen; schnelle Unit-Tests im Paket benötigen diese Quellen nicht. ASCII-Prüfung für R/, Datenlimits aus ANK-TOL und roxygen2-Exportkontrolle. |
| T7 / E9, E11–E14 | Tests der neuen Argumente nach ADR-007: NULL-Regressionspfade, Parserdispatch einschließlich unbenutzter Namen und ungültiger Listen, assessment-Validierung vor Rendering. Tatsächliche Berichte mit/ohne assessment außerhalb des Baums; Fazit, synthetische/vorläufige Kennzeichnung, Warnungen und ausgelieferte Policy-Texte prüfen. Paketressourcen allein genügen. NEWS und Rd beschreiben die Verträge; API-Signaturen samt Vorgaben werden lesend gegen ANK-02 geprüft. Dateiinventur vor/nach dem Lauf. |

Die Request-Erwartungen in T1 werden eigenständig aus YAML und dem hier
festgelegten Vertrag formuliert; der Test ruft nicht eine zweite
Produktfunktion auf, um den erwarteten Request zu erzeugen. Die
unabhängigen Mini-Rechnungen der Abnahme werden nicht in Produktcode
importiert. Keine neuen Referenzkonstanten aus Modellgedächtnis.

Punktwerte: ANK-TOL.arithmetic. Direkte Fits:
ANK-TOL.engine_ordinal. Separate Invarianzen: ANK-TOL.invariance.
Bootstrap-Grenzen: `ANK-TOL.mc_factor.pass * sqrt(2) * MCSE +
ANK-TOL.arithmetic` nach ADR-006 Nr. 3, mit gezählten verworfenen
nicht endlichen Wiederholungen und wiederhergestelltem Zufallszustand.
Die bekannte abweichende NA-Banddarstellung der Acceptance-Mini-Referenz
wird nicht nachgebaut: ADR-006 Nr. 10 verlangt `not assessed` und der
entsprechende Unit-Fall belegt das; Abnahmetests bleiben Reviewer-Besitz.

Die direkten BUILD-Aufrufe ersetzen die weniger konkreten Angaben aus
Runde 1. Nach Prüfung der externen Artefaktziele und Grafikgeräte:

```bash
NOT_CRAN=true Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat
Rscript --vanilla -e 'testthat::test_dir("tests/acceptance", filter = "m2-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Das einmalige NOT_CRAN im direkten Builder-Lauf ändert keine
Gate-Einstellung; E14 bleibt Betreiberarbeit. Der zweite Aufruf wählt
nur die sieben M2-Testdateien. Die Setup-Dateien definieren ihre
Hilfsfunktionen, starten aber keinen Git-Prozess. Die komplette
M0/M2-/QA-Suite sowie deps, lint, trace, territory, mutgate und
golden-adr führt danach der Orchestrator aus. `88-mutfull` ist in M2
nicht fällig. Ein unerwarteter Eingriff in den Mutations-Scope würde
weiterhin die reguläre Mutationspflicht auslösen.

### Tatsächliche Prüfung dieser PLAN-Runde

In Runde 2 wurden Kontextdateien gelesen und statische Dokumentprüfungen
ausgeführt. Produkt-/Abnahmetests, Paketbau, Gates, Installationen und
API-Aufrufe wurden nicht ausgeführt. Die Diagnoseergebnisse aus Runde 1
werden nicht als neue Prüfläufe ausgegeben.

Die erste lesende Python-Prüfung verglich die Kriterienzitate mit der
Spec, erfasste die Review-IDs und Backlog-Status und zählte die M2-Tests.
Tatsächlicher Output, Exit 0:

```text
Review objections: E1, E2, E3, E4, E5, E6, E7, E8, E9, E10, E11, E12, E13, E14, E15
Criteria: 7/7 quotes match docs/03; acceptance notes: 25
Backlog: 62 entries; 54 open; 8 closed
Closed backlog IDs: BL-19, BL-26, BL-27, BL-32, BL-38, BL-58, BL-59, BL-61
M2 acceptance tests: 62 test_that blocks read, not executed
ARBITER.md: not present
```

Vor dem Schreiben wurde ein SHA-256-Inventar von 130 Dateien in den
Produkt-, Test-, Dokumentations-, Anker-, Vertrags- und M2-Handoffpfaden
sowie den gelesenen Stammdateien aufgenommen. Die abschließende lesende
Dokumentprüfung mit `python3 -` lieferte folgenden Output (Exit 0):

```text
PLAN-UPDATE schema: 6/6 sections in required order
Review: 15/15 objections answered with akzeptiert
Backlog: 54/54 open entries addressed exactly once; 8 closed entries listed separately
Criteria: 7/7 quotes match docs/03
Markdown: paired fences, no trailing whitespace, UTF-8/LF
Product tests and gates: not executed in this PLAN phase
```

Der SHA-256-Vergleich des erfassten Bestands meldete
`unchangedFiles: 130`, `changed: []` und als einzigen neuen Pfad
`orchestrator/handoff/M2/PLAN-UPDATE.md`. Dies ist eine Prüfung der
erfassten Dateien, keine vollständige Territoriumsprüfung des
Orchestrators oder Kriterienabnahme. Ein Verdict oder Gate-Ergebnis
wird hier nicht gesetzt.
