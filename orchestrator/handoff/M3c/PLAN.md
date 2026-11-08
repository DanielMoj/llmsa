# PLAN — M3c, Runde 1

Stand: 08.11.2026. Rolle: Builder, Phase PLAN. Dieser Entwurf beschreibt die
spätere Umsetzung; er erteilt keine Abnahme. In dieser Phase entsteht ausschließlich
`orchestrator/handoff/M3c/PLAN.md`.

## Ziel

M3c ergänzt die Systemeignung um die wählbare R_4s-Lesart und nachvollziehbare
Kennzahlen der Fallzahlplanung. Maßgeblich sind K-M3c-1 bis K-M3c-6 in
`docs/04-weitere-bausteine.md`, der Prüfstandard und die Schnittstellenregel in
`docs/01-fachspezifikation.md`, Formelsammlung §§2, 8 und 9 sowie
`orchestrator/handoff/M3c/CRITERIA.json` einschließlich ACC-1 bis ACC-12.

Gelesen wurden AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, PROGRESS, BACKLOG,
Handoff-SCHEMA, LESSONS, die M3c-Abnahmetests samt Setup und die drei zugehörigen
Klasse-A-Studien. Für die Integration wurden außerdem die bestehenden Funktionen,
Berichtsvorlage, Validierungsressourcen und berührten M3d-/Unit-/QA-Verträge
gelesen. LESSONS wird bei einem tatsächlichen numerischen Befund als Auftrag zur
Prüfung der gesamten Fehlerklasse berücksichtigt; daraus folgt kein vorsorglicher
Umbau des Statistikkerns.

Die gelesenen Gate-Fakten nennen für M1a Runde 5 und M3d Runde 2 jeweils
`result: pass`. Das sind vorhandene Orchestrator-Fakten, keine Prüfung dieser
PLAN-Phase. Die Ausgangsbefunde und Attrappenmessungen in ACC-10/ACC-11 sind
Reviewer-Evidenz und werden nicht als Builder-Ergebnis übernommen.

| Kriterium | Geplantes Ergebnis und unabhängige Belege |
| --- | --- |
| K-M3c-1 | Strikte Grenzen, richtige Fenster und Standardisierung aller sechs Regeln; 1_2s bleibt reine Warnung. Belege: ANK-86/Formelsammlung §8 und konstruierte Fälle sowie unabhängige Mini-Referenz der unveränderten Abnahme. |
| K-M3c-2 | Letztes Argument `r4s = c("range", "westgard")`; Lesart im Objekt, in `print()` und im tatsächlichen HTML-Bericht. Belege: ANK-86 und unterscheidende Reihen einschließlich beider Orientierungen und exakter Grenzen. |
| K-M3c-3 | Klasse-A-Nachweis der Auslösewahrscheinlichkeiten je Regel/Position und des fortlaufenden Parvin-Verfahrens. Belege: analytische Wahrscheinlichkeiten aus ANK-86 und publizierte Werte/Verfahrensbeschreibung aus ANK-87, jeweils gegen echte Simulation. |
| K-M3c-4 | Gezeichnete Mittellinie und Grenzen bei gegebenem Zentrum und SD bleiben korrekt. Belege: geschlossene Rechnung und zur Laufzeit aufgerufenes `qcc::qcc(type = "xbar.one")`; geprüft werden die tatsächlich gezeichneten Linien. |
| K-M3c-5 | Bestehender Simulator liefert Itemwahrheit und reproduziert im Mittel die acht S-sim-1-Komponenten. Belege: deterministische Zerlegungs-/Verschiebungsfälle und Mittelwerte echter `msa_fit()`-Schätzungen samt MCSE. |
| K-M3c-6 | Zusätzliche Bias-/EmpSE-/MCSE-Spalten und vollständige Einzelreplikate; alle bisherigen Zusammenfassungen daraus nachrechenbar. Die Vignette berichtet die vier Kandidatenpläne, empirischen Prompt-CV und Grenzanteile. Belege: Formelsammlung §9 plus unabhängige Nachrechnung; ANK-89 plus frische Klasse-A-Reproduktion der berichteten Zahlen. Die Übereinstimmung mit der Planungsregel erhält keine Bestehensschwelle. |

Die vorhandene Standardisierung, die übrigen Regeldefinitionen, die gezeichneten
Grenzen und die Simulationsgleichung erscheinen nach der Quelllektüre bereits
passend; der Ausführungsnachweis für M3c steht aus. Geplant sind dort gezielte
Regressionen; eine Änderung erfolgt nur bei einem
reproduzierten Kriterienfehler. Die beabsichtigten fachlichen Erweiterungen liegen
in der R_4s-Auswahl und in der Sammlung/Auswertung der Planungsreplikate.

## Dateien

Die folgende Liste gilt für BUILD nach der Planfreigabe. Originalanker,
Abnahmetests, Klasse-A-Tests, QA-Dateien und Betreiberzustand werden dabei nur
gelesen. Die aktuelle PLAN-Phase schreibt ausschließlich diese Datei.

| Pfad | Geplante Änderung in BUILD |
| --- | --- |
| `R/spc.R` | Argument, Validierung und Attribut `r4s`; alternative R_4s-Bedingung; Lesart in der Druckausgabe; Roxygen-Hilfe zur Fenster- und Laufsemantik. |
| `R/plan.R` | Einzelreplikate aus den bereits ausgeführten Fits sammeln; neue Kennzahlen daraus berechnen; Ergebnis-/Fehlervertrag und Druckausgabe dokumentieren. Die Zufallsziehung von `msa_simulate()` bleibt erhalten, sofern K-M3c-5 keinen Fehler belegt. |
| `R/report.R` | Lesart der übergebenen Karte als gesonderten internen Renderparameter `control_chart_reading` übergeben; Hilfe aktualisieren. |
| `inst/templates/validation_report.Rmd` | Parameterdeklaration und Text im vorhandenen Westgard-Abschnitt von der Lesart abhängig machen; Verletzungstabelle und übrige Berichtsabschnitte erhalten. |
| `man/msa_control_chart.Rd`, `man/msa_plan.Rd`, `man/msa_report.Rd` | Nur die betroffenen Hilfen aus Roxygen erzeugen; Formeln, neue Felder und Lesart erklären. `man/msa_simulate.Rd` nur bei einer tatsächlich nötigen Präzisierung der Itemwahrheit. |
| `DESCRIPTION` | `qcc` zu Suggests ergänzen (ACC-5/ACC-10). Bestehende Imports einschließlich des bereits begründeten Matrix-Imports bleiben erhalten. |
| `tests/testthat/test-control-chart.R` | Kleine unabhängige Grenz-, Fenster-, Invarianz-, Auswahl- und Drucktests für beide Lesarten. |
| `tests/testthat/test-plan.R` | Nachrechnung aus Einzelreplikaten, Zuordnung zu mehreren Plänen, RNG-Erhaltung, Sonderfall einer Wiederholung und benannter Abbruch bei einem gescheiterten Fit. |
| `tests/testthat/test-report-control-chart.R` | Weitergabe der Lesart sowie echte HTML-Ausgabe beider Varianten und älterer Karten ohne Lesartattribut; bestehende Berichtstests bleiben wirksam. |
| `tests/testthat/test-validation-planning.R` | Ressourcen-, Herkunfts-, Schema-, Nachrechnungs- und Fehlerprüfungen mit kleinen synthetischen Eingaben; keine lange Simulation pro Unit-Lauf. |
| `data-raw/make_validation_planning.R` | Offline-Erzeugung vollständiger bytegleicher Kopien von ANK-86, ANK-87 und ANK-89 mit Quellenmanifest; getrennt von der Simulationsrechnung. |
| `inst/validation/planning/anchors/ANK-86.json`, `ANK-87.json`, `ANK-89.json` | Ganze installierbare Kopien der Reviewer-Anker. ANK-06, ANK-16 und ANK-TOL werden über bereits vorhandene hashgeprüfte Ressourcen wiederverwendet. |
| `inst/validation/sim/planning_rule.R` | Ausführbarer Erzeuger mit exakt einem `msa_plan()`-Aufruf je Kandidatenplan, vorgegebenem RNG/Seed und vollständiger Provenienz. Sequentielle Vorgabe; optionale Parallelisierung nur je ganzem Plan und nur im dafür zulässigen Pfad. |
| `inst/validation/planning/summary.csv`, `replicates.csv.gz`, `session.txt`, `SOURCES.json` | Tatsächlich berechnete Klasse-A-Dokumentationsdaten, Einzelreplikate, Sitzungs-/Methodenangaben und Hashes. Keine Änderung an vorhandenen Klasse-B-Volllaufdateien unter `inst/validation/sim/`. |
| `inst/validation/planning/reference_checks.R`, `README.md` | Reiner Ergebnisleser mit Validierung und Darstellung sowie ADEMP, Formeln, Aufrufe und Interpretation. Der Leser lädt keinen Simulationsgenerator. |
| `vignettes/validation.Rmd` | Abschnitt mit „planning rule“ im Titel; berechnete Tabelle aus den geprüften Dateien, separate Angabe des ergänzenden CV-MCSE und Interpretation der Abweichungen/Grenzschätzungen. |
| `NEWS.md`, `PROGRESS.md` | Englische Änderungsnotiz; deutscher tatsächlicher Umsetzungs-/Prüfstand mit Kommandos, Output, Einschränkungen und Backlog-Zuordnung. |
| `docs/decisions/ADR-<freie Nummer>-m3c-planungsressourcen.md` | Builder-ADR zur reproduzierbaren Ressourcenablage und zur ergänzenden, ausdrücklich benannten CV-MCSE-Methode; Nummer nach den Reviewer-ADRs vergeben. |
| `orchestrator/handoff/M3c/REVIEW-INPUT.md` | Späterer zugewiesener BUILD-Handoff mit Kriterienbelegen und offenen Punkten; bei REWORK nur die dann zugewiesenen Handoffs. |

`R/report-data.R` muss für die geplante Weitergabe nicht geändert werden:
`msa_report_control_chart()` liefert weiterhin denselben attributfreien
`data.frame`. Dadurch bleibt der bestehende `identical()`-Vertrag aus
`tests/testthat/test-report-provenance.R:103–119` direkt prüfbar. `NAMESPACE`
benötigt keine Änderung; es wird kein neuer Export eingeführt.

Die Ressourcenänderung erhält ihren Builder-ADR. Die M3c-Auslegungen und der in
ACC-1 angekündigte Anker-ADR bleiben Reviewer-Aufgaben der Planprüfung. Es wird
weder ein Originalanker nachgetragen noch ein vorhandener Golden-Hash ersetzt.

## Schnittstellen

### Regelkarte und Bericht

Die bisherigen Argumente von `msa_control_chart(x, center, sd, n_baseline,
rules)` behalten Position und Vorgabe. Dahinter steht exakt
`r4s = c("range", "westgard")`; die Auswahl wird einmal mit `match.arg()`
aufgelöst und als einzelner String im Attribut `r4s` gespeichert.

- `range`: am Zeitpunkt t ab dem zweiten Wert gilt
  `abs(z[t] - z[t - 1]) > 4`.
- `westgard`: am Zeitpunkt t gilt
  `(z[t] > 2 && z[t - 1] < -2) || (z[t] < -2 && z[t - 1] > 2)`.
  Geprüft wird jedes benachbarte Paar, nicht eine Aufteilung in disjunkte
  Zweiergruppen. Die erste Position bleibt falsch.
- Exakte Grenzwerte lösen nicht aus. Diese Präzisierung folgt den expliziten
  Ungleichungen in K-M3c-1/K-M3c-2, Formelsammlung §8 und ACC-2/ACC-3.
  Fenster vor Erreichen ihrer vollständigen Länge lösen ebenfalls nicht aus.
- `center`/`sd`, Basisstichprobe mit Stichproben-SD, Regelspalten, `index`,
  Klassen und vorhandene Attribute bleiben erhalten. `reject` ist die
  Vereinigung der ausgewählten Ablehnungsregeln; `1_2s` bleibt ausgeschlossen.
  Default und explizites `r4s = "range"` ergeben identische Objekte.

Die Hilfe erklärt Westgards Interpretation für Kontrollen innerhalb desselben
Laufs und die ursprüngliche Anwendung mit zwei bis vier Kontrollen (ANK-86).
Die Schnittstelle besitzt keine Laufkennungen und erkennt keine Laufgrenzen;
Anwender müssen für die Westgard-Lesart sicherstellen, dass die verglichenen
Nachbarwerte demselben Kontrolllauf angehören. Eine zusätzliche Gruppierungs-API
ist nicht Teil von M3c.

`print.msa_control_chart()` nennt R_4s und die gewählte Lesart auch ohne
Verletzung. `msa_report()` behält seine vollständige öffentliche Signatur,
insbesondere `control_chart = NULL` als letztes Argument. Der zusätzliche
Parameter betrifft nur den internen Rendervertrag. Die Tabelle Rule/Violations/
Positions und die tatsächlich gespeicherten Indexpositionen bleiben erhalten.
Für `range` bleibt der durch QA-M3d-E2E-3 geforderte Satz wörtlich:

> R_4s uses the range of two consecutive standardized values.

Für `westgard` nennt derselbe Abschnitt ausdrücklich die Lesart und die beiden
strikten Schwellen. Bei einer älteren serialisierten Karte ohne `r4s`-Attribut
wird die bisher einzig verfügbare Lesart `range` berichtet. Ein vorhandenes,
ungültiges Attribut wird nicht still als `range` umgedeutet. Ohne Karte bleibt
das bisherige Verhalten des Berichts erhalten.

### Simulator und Fallzahlplanung

`msa_simulate()` und `msa_plan(scenarios, vc, nsim = 100, seed = NULL,
verbose = TRUE)` behalten ihre öffentlichen Argumente und Vorgaben. Der Simulator
führt weiterhin `latent = mean + Itemeffekt` mit, konstant innerhalb eines Items;
die Messung ergänzt die übrigen Zufallseffekte und den Rest. Fehlende
Varianzkomponenten bedeuten null.

`msa_plan()` behält die Entwurfsfelder und bisherigen Spalten `grr_true`, `mean`,
`q2.5`, `median`, `q97.5`, `rmse`, `pct_singular`, `pct_misclassified` sowie Klasse
und Attribute `nsim`/`vc`. Hinzu kommen `bias`, `empse`, `mcse_bias`,
`mcse_empse` und das Attribut `replicates` als `data.frame`:

| Spalte | Vertrag |
| --- | --- |
| `scenario` | Zeilennummer des Kandidatenplans in der übergebenen Tabelle; keine Ableitung aus frei wählbaren Zeilennamen. |
| `sim` | Wiederholung 1 bis `nsim` innerhalb dieses Plans. |
| `estimate` | Geschätzter %GRR auf der Skala Prozent Studienvariation aus genau diesem Fit. |
| `singular` | Logischer Singularitätsstatus dieses Fits, ohne NA. |
| `prompt` | Nichtnegative REML-Schätzung der Prompt-Varianz aus demselben `msa_fit()`-Ergebnis; eine strukturell nicht geschätzte Prompt-Komponente ist null, ein unerwartet fehlender/ungültiger Schätzer ist ein benannter Fehler. |

Die Ausgabe enthält genau `nrow(scenarios) * nsim` Zeilen, sortiert nach
`scenario`, dann `sim`, mit eindeutigen Schlüsseln. Es werden weder Fits nochmals
ausgeführt noch zusätzliche Zufallszahlen für die Erfassung gezogen. Der
bisherige sequentielle Ziehungsablauf über Pläne/Wiederholungen und die
Wiederherstellung des RNG-Zustands bei gesetztem Seed bleiben erhalten.
Singuläre Fits einschließlich Prompt-Schätzung null bleiben in allen Nennern.
Ein gescheiterter Fit stoppt weiterhin mit seiner Diagnose (BL-76); nichtendliche
Kennzahlen werden nicht durch `na.rm` aus dem Plan entfernt oder ersetzt.

Mit n Wiederholungen, Schätzern x_s, Mittel m und Q = Summe((x_s − m)^2) gilt:

| Feld | Berechnung gemäß Formelsammlung §9/ACC-7 |
| --- | --- |
| `grr_true` | 100 · sqrt(G / (G + Item)), G = Summe aller sieben Nicht-Item-Komponenten einschließlich Block und Interaktionen; fehlende Komponenten null. |
| `mean`, `bias` | m; m − `grr_true`. |
| `empse` | sqrt(Q / (n − 1)). |
| `mcse_bias` | sqrt(Q / (n · (n − 1))). |
| `mcse_empse` | `empse` / sqrt(2 · (n − 1)); als Näherung dokumentiert. |
| `q2.5`, `median`, `q97.5` | Quantile nach Definition 7; keine Rundung der Schätzer vor der Rechnung. |
| `rmse` | sqrt(Mittel((x_s − `grr_true`)^2)). |
| `pct_singular` | 100 · Mittel(`singular`). |
| `pct_misclassified` | 100 · Anteil unterschiedlicher Verdikte von x_s und Wahrheit: < 10 akzeptabel, 10 bis einschließlich 30 bedingt, > 30 nicht akzeptabel (ANK-16). |

Alle Zusammenfassungen werden aus genau den gespeicherten Einzelreplikaten
berechnet. `nsim` muss eine positive ganze Anzahl sein. Der bisher mögliche
Einzelfall `nsim = 1` bleibt ausführbar: Bias und bisherige Kennzahlen bleiben
definiert, EmpSE und die beiden darauf beruhenden MCSE sind ausdrücklich NA.
Dieser Fall ist kein Simulationsnachweis mit ausreichender Wiederholungszahl.
Die Druckmethode zeigt die neuen Spalten und gibt das unveränderte Objekt
unsichtbar zurück. Gerundet wird ausschließlich für die Darstellung.

### Reproduzierbare Planungstabelle

Die Kandidatenpläne folgen ACC-8: S-plan-1 bis S-plan-4 haben jeweils
20/20/40/40 Items, 3/5/3/5 Prompts, drei Modelle, zwei Replikate und zwei Blöcke.
Die Varianzen sind die spezifizierten S-boot-1-Einstellungen aus
`docs/02-statistikkern.md`: Item 1, Prompt 0,05, Modell 0,05, Block 0,01,
Item×Prompt 0,01, Item×Modell 0,05, Prompt×Modell 0,005, Rest 0,1.
Dies sind Simulationsvorgaben mit Spec-Fundstelle, keine empirischen Referenzwerte.

Der Erzeuger verwendet pro Plan i genau einen Aufruf
`msa_plan(plan_i, vc, nsim = n_min, seed = 20261108 + i, verbose = FALSE)`;
`n_min` kommt aus ANK-06. Er setzt den vorgeschriebenen RNG
Mersenne-Twister/Inversion/Rejection. Eine optionale Verteilung auf Prozesse
verändert weder diesen Aufruf noch die Seed-Zuordnung. Die sequentielle Variante
bleibt auf Windows ausführbar. In `R/` wird keine Fork-Parallelisierung eingeführt.

Aus allen Prompt-Schätzungen eines Plans, einschließlich der Nullen, entstehen
CV = Stichproben-SD/Mittelwert, Grenzanteil p = Anteil exakt null und
MCSE(p) = sqrt(p · (1 − p) / n). Die Planungsregel liest Zähler und Freiheitsgrad-
Versatz aus ANK-89: nu = Prompts − 1, CV_rule = sqrt(2 / nu).

Die erste Planungstabelle enthält genau die neun von ACC-8 verlangten Spalten
`plan`, `items`, `prompts`, `nu`, `cv_rule`, `cv_empirical`, `boundary_share`,
`mcse_boundary`, `n_sim`. Vorgesehen sind vier Nachkommastellen für beide CV und
die beiden Anteilsgrößen. Alle Tabellenwerte einschließlich Entwurfsgrößen und
Wiederholungszahl werden eingelesen/berechnet, nicht im Rmd abgetippt.

**ACC-9:** Die Spec enthält keine MCSE-Formel für den empirischen CV. Der Plan
nutzt die dort ausdrücklich erlaubte benannte Ergänzung: Delta-Methode über die
ersten beiden empirischen Rohmomente und ihre geschätzte Kovarianz. Für
g(m1, m2) = sqrt(n/(n−1)) · sqrt(m2−m1²)/m1 wird der MCSE als
sqrt(Gradient(g)' · cov((y, y²))/n · Gradient(g)) berechnet. Die Annahmen
(positiver Mittelwert, positive Streuung, endliche benötigte Momente) und der
Näherungscharakter werden dokumentiert. Ein undefinierter Zusatzwert wird als
solcher benannt, nicht durch null ersetzt. Der CV-MCSE erscheint in einer
separaten ergänzenden Tabelle, damit der Neun-Spalten-Vertrag bestehen bleibt.
Dies fügt keine Bestehensschwelle hinzu. Ob diese Methode in die verbindliche
Formelsammlung übernommen wird, bleibt die nonblocking Betreiberentscheidung
aus ACC-9. Den MCSE für 1/ARL berichtet bereits die unveränderte Klasse-A-Studie
mit ihrer Delta-Methode.

Der Ergebnisleser prüft Dateien, Hashes, Schema, eindeutige Plan-/Replikatschlüssel,
vollständige n-Werte, endliche Größen und gültige Anker. Bei gesetztem `REPO_ROOT`
werden Original-/Kopien-Hashes verglichen; ohne Repo funktioniert das installierte
Paket mit vollständigen Ankerkopien. Fehlende oder beschädigte Eingaben führen zu
benanntem Abbruch. Es gibt keine automatische Neusimulation beim Knitten.

SOURCES/session halten Eingaben, Seeds, RNG, Methoden, Paketversionen,
Quellhashes und Laufzeit fest. Quellhashes dienen der Provenienz; der Knit darf
nicht jeden geänderten Produktfunktionskörper allein wegen eines Hashunterschieds
als Fehler zählen. Die fachliche Aktualität der Tabelle prüft die frische
Klasse-A-Simulation gegen den jeweils geladenen Namespace. Ändern sich
ergebniswirksame Teile von `msa_plan()`, `msa_simulate()` oder `msa_fit()`, werden
die Zahlen wirklich neu erzeugt. Es werden keine alten Ergebnisdateien lediglich
mit einem neuen Implementierungshash versehen.

## Reihenfolge

1. **Planprüfung und Ausgangspunkt:** Reviewer-Auslegungen/ADR aus der Planprüfung
   lesen, insbesondere ACC-2/3/7/8/9/12; API-Präfix gegen ANK-02 und vorhandene
   M3d-Verträge festhalten. Die Referenzanker liegen bereits vor. Keine Arbeit an
   Gates, Baseline oder Quellenbeschaffung durch den Builder.
2. **Regelkarte:** Kleine unabhängige Grenz-/Invarianztests ergänzen, `r4s`
   implementieren und Druckausgabe prüfen. K-M3c-1/2/4 direkt ausführen. Bei einem
   bereits passenden Standardpfad nur die Erweiterung vornehmen.
3. **Berichtsintegration:** Lesart über den separaten Renderparameter führen;
   beide HTML-Varianten und alte Karten prüfen. Default-Satz, unveränderte
   Verletzungstabelle sowie M3d-Abnahme-/QA-Regression prüfen.
4. **Planungsdaten:** Replikate aus jedem vorhandenen Fit aufnehmen, Kennzahlen
   daraus ableiten und Einheit/Zuordnung/RNG/Fehlerverhalten prüfen. K-M3c-5
   deterministisch und K-M3c-6 arithmetisch ausführen. Kein Umbau des Fit-Kerns
   ohne reproduzierten Kriterienfehler.
5. **Ressourcen und echter Studienlauf:** Kopien/Manifest erzeugen; Generator und
   reinen Leser gemäß ADR-043 trennen. Die vier S-plan-Läufe mit vorgeschriebenem
   n/Seed wirklich rechnen, vollständige Replikate und Provenienz speichern,
   Zusammenfassungen unabhängig nachrechnen. Der ergänzende CV-MCSE wird separat
   geprüft und gekennzeichnet.
6. **Vignette und Hilfe:** Planungsteil aus den Dateien rendern, bestehende
   Quellen-/Literalwachen ausführen; Hilfen in einer temporären Paketkopie
   erzeugen und ausschließlich die betroffenen Rd-Dateien übernehmen. NEWS und
   tatsächliche Fortschrittsbelege ergänzen.
7. **Abschließende Prüfung und Übergabe:** Die unveränderten M3c-Tests einschließlich
   aller drei Klasse-A-Studien, relevante Regressionen, vollständige Unit-/QA-
   Prüfungen und Paketbau/-check ausführen. Laufzeit der gesamten Klasse-A-Suite
   messen. Orchestrator erhält Handoff und tatsächliche Logs für kumulative
   Gates, Mutation, Territorium und Phasen-Commit; kein eigenes Verdict.

Die lange Planungssimulation wird erst nach Stabilisierung des betreffenden Codes
gerechnet. Weitere Wiederholungen erfolgen bei einer ergebniswirksamen Änderung,
einem Fehlschlag oder einem konkreten Reproduktionsbedarf. Arbeitskopien,
Renderausgaben und Diagnoselogs der BUILD-Prüfungen liegen außerhalb des
Arbeitsbaums; Quellen/Fixtures werden dort nur unverändert eingelesen.

## Risiken

| Risiko / Ref | Behandlung |
| --- | --- |
| Strikte Grenzen und Bedeutung von „Lauf“; K-M3c-1/2, ACC-2/3 | Explizite Ungleichungen, beide Orientierungen, unvollständige Fenster und jedes benachbarte Paar prüfen; die fehlende Laufkennung in der Hilfe offenlegen. Kein stiller Wechsel des Default-Verhaltens. |
| Regression des M3d-Berichts; ACC-12 | Exakten Default-Satz beibehalten, Lesart separat weitergeben, bestehende Tabellen-/Signaturtests unverändert ausführen. QA-Dateien werden nicht an die Implementierung angepasst. |
| Veränderte Zufallsfolge oder selektierte Fits; K-M3c-5/6 | Replikate im bestehenden Fit-Durchlauf sammeln; Seeds/RNG wiederherstellen; singuläre Fits mitführen, gescheiterte Fits benannt abbrechen. Ausgabezahlen nicht an Erwartungen anpassen. |
| Laufzeit und veraltete Vignettenergebnisse; ACC-8/10, BL-13/46 | Generator getrennt vom Knit; Ergebnisse aus echten Aufrufen; frischer Klasse-A-Abgleich. Die gesamte Suite muss innerhalb ANK-TOL.sim_runtime bleiben. Keine Reduktion von n oder Ausblendung von Tests. |
| Herkunftswachen und Mutationsverfälschung; ADR-021/026/043 | Ganze Ankerkopien; statisch auflösbare `system.file()`-Quellen; reiner Leser ohne Generator. Kein Laden unmutierten Produktcodes aus REPO_ROOT und kein pauschaler Produktcode-Hashvergleich als Testorakel. |
| Grenzen der CV-Näherung; BL-50, ACC-9 | Nullen in CV/Anteil belassen; Abweichungen berichten; ergänzenden Delta-MCSE als Näherung mit Methode kennzeichnen. Keine Kalibrierung auf die Planungsregel. |
| Neue Numerikfehler in regulären S-sim-/S-plan-Fällen; LESSONS | Vollständiger Fehlerbeleg mit Plan/Seed; ganze betroffene Engine-Fehlerklasse prüfen. Reparatur nur im Builder-Territorium, ohne Toleranzänderung; keine Umdeutung in erfolgreich berechnete Replikate. |
| Lokale Socket-/Dispatcher-/Uhrzeitprobleme; BL-86 | Falls sie auftreten, echten Fehler und Prüfgrenze als [INFRA] übergeben; die reguläre Gate-Ausführung bleibt beim Betreiber. Keine Berechtigungsumgehung und keine Lockerung der Tests. |
| Plattform- und Release-Nachweis; BL-137/138 | Portable Pfade, sequentieller Produktcode und eigenständiger installierter Build; Linux-Belege werden nicht als Windows-/macOS-Abnahme ausgegeben. CI-Prüfung bleibt beim Betreiber. |

### Offener Backlog: Entscheidung zu jedem Eintrag

Die Zuordnung bezieht sich auf den gelesenen Stand mit BL-01 bis BL-144. Sie
ändert keine Backlog-Statusdatei. „Vertagt“ bezeichnet eine bewusste Begrenzung des
M3c-Auftrags, mit Zuständigkeit und Anlass für die Wiederaufnahme. Bestehende
Vertagungen nach dem 26.11. werden beibehalten; ADR-035 wird nicht als neue
allgemeine Ausnahme für M3c ausgeweitet.

| ID | Behandlung in diesem Plan bzw. begründete Vertagung |
| --- | --- |
| BL-01 | Termin-/AP1-Priorität berücksichtigen: M3c auf seine sechs Kriterien begrenzen; Veröffentlichung und AP1 organisiert weiter der Betreiber. |
| BL-02 | Vertagt an Betreiber/Publikationsarbeit: Aktualität der Neuheit erfordert Literaturarbeit für das Paper, keinen M3c-Produktumbau. |
| BL-03 | M1d-Befund zu wenigen Stufen als bekannte Grenze erhalten; weitere latente Methoden/AP5 vertagt, weil M3c numerische Regelkarten-/Planungsfälle prüft. |
| BL-04 | Vorhandene Coverage-Befunde erhalten; zusätzliche AP5-Untersuchungen vertagt. M3c ändert weder Bootstrap noch seine abgenommenen Studien. |
| BL-05 | Memorisation und `prior_differs` gehören zur AP1-Auswertung beim Betreiber; für synthetische M3c-Studien ohne Modellantworten nicht einschlägig. |
| BL-06 | Modellzugang/Umleitung bleiben Betreiberkontrolle der Rollenlogs; kein Eingriff in Rollenmodell oder Dispatcher. |
| BL-07 | Live-Routing und Wiederholungstagskontrolle an AP1-Betreiber vertagt; die vorhandenen M2-Prüfungen bleiben erhalten. |
| BL-08 | Datenschutz/AP7 an Betreiber vor der betreffenden Datenerhebung vertagt; M3c verwendet synthetische Studien. |
| BL-09 | Fortlaufend berücksichtigen: nur Anker mit Kurzzitat/Quelle kopieren, keine geschützten Volltexte oder Rohdaten neu ausliefern. |
| BL-10 | Go/No-Go und Einreichungsentscheidungen bleiben Betreiber-/Publikationsarbeit; M3c liefert Prüfbelege und keine Terminfreigabe. |
| BL-11 | Die aktuelle ausdrückliche M3c-PLAN-Beauftragung ausführen. Die frühere Termin-/Kostenpriorisierung wird dadurch nicht im Backlog umgeschrieben; Dashboard und Freigabe weiterer Arbeit bleiben beim Betreiber. |
| BL-13 | In M3c berücksichtigen: gesamte Klasse-A-Laufzeit gegen ANK-TOL messen; keine Planungssimulation beim Knit. Gate-Zeitlimits/Hardware ändert nur der Betreiber. |
| BL-14 | Für berührte Funktionen unabhängige Grenz-/Formel-/Orakelbelege ergänzen; allgemeine Erweiterungen außerhalb M3c vertagen, vorhandene unabhängige M1-Tests erhalten. |
| BL-15 | Fleiss-Umsetzung ist laut Backlog bereits erfolgt; verbleibende Synchronisation der Projektunterlagen beim Betreiber nachführen lassen, keine Agreement-Änderung in M3c. |
| BL-17 | Wiedergabetests erhalten; verbleibende Live-Prüfung vor AP2/Release an Betreiber vertagt. Keine Live-API-Aufrufe im Builder. |
| BL-20 | Bestehenden `wine`-/CLMM-Vertrag erhalten; ein weitergehender Vergleich bleibt bei Statistikkern/Reviewer, da kein M3c-Kriterium die Modellform erweitert. |
| BL-21 | Zusätzliches geschachteltes NIST-Beispiel an spätere Reviewer-Validierung vertagt; S-sim-1 ist ein gekreuzter Plan. |
| BL-22 | Gepoolte AIAG-Nachrechnung als M1a-Vertrag erhalten; M3c benötigt keine Änderung der Interaktionsbehandlung. |
| BL-23 | Dokumentierte NIST-Präzisionsgrenzen erhalten; keine zielwertabhängige Korrektur oder neue Optimiererarbeit im Planungsteil. |
| BL-25 | Ankerdisziplin anwenden: nur vorhandene ANK-86/87/89 verwenden; angekündigter Reviewer-ADR in Planprüfung, spätere Änderungen nur über den vorgesehenen ADR-Weg. |
| BL-28 | API-Schlüssel/Accounts bleiben beim Betreiber vor AP1; weder Schlüsselzugriff noch Netz für M3c erforderlich. |
| BL-29 | Infevers-Freigabe bleibt Betreiberaufgabe vor Nutzung/Publikation; keine INSAID-Referenzklassen in neue M3c-Dateien. |
| BL-30 | Pages, Release und Zenodo an AP2-/Publikationsablauf vertagt; diese PLAN-Phase veröffentlicht nichts. |
| BL-31 | Git-Identität bleibt Betreiberaufgabe; der Builder führt keine Git-Kommandos aus. |
| BL-33 | CLI-Vertrauen/Sandbox bleiben Betreiberkonfiguration; M3c nutzt die vorhandenen Berechtigungen ohne Bypass. |
| BL-34 | Verfügbarkeit für Eskalationen bleibt Betreiberaufgabe; ein tatsächlicher Spec-Widerspruch geht über den vorgesehenen ESCALATION-Handoff. |
| BL-35 | Benachrichtigungsfehler an Harness-Template-Wartung vertagt; keine Änderung in orchestrator außerhalb des zugewiesenen Handoffs. |
| BL-36 | Textspiegel-/Checkout-Optimierung an Betreiber vertagt; vorhandene lokale Quellen genügen, kein Quellenumzug für M3c. |
| BL-37 | Kosten-Trace/Dashboard an Betreiber vertagt; echte Laufzeiten im BUILD-Handoff liefern, keine Betreiberabrechnung im Produkt ergänzen. |
| BL-39 | Noch fehlende Literaturbeschaffung bleibt Betreiberaufgabe. M3c nutzt die geernteten Westgard-1981-/Parvin-Anker; keine unbelegten Ersatzkonstanten. |
| BL-40 | Weitere Konkordanzquellen an Betreiber/Reviewer bei späterer Agreement-Validierung vertagt; kein M3c-Kriterium benötigt sie. |
| BL-41 | Landis/Koch-Quellenpflege an Betreiber/Reviewer vertagt; keine neue Interpretation dieser Bänder im M3c-Bericht. |
| BL-42 | Geschützte Datenblätter bleiben Betreiber-/Reviewer-Territorium; vorhandene Regressionen lesen sie unverändert, M3c verlangt keine neue geschützte Tabelle. |
| BL-43 | Live-Modellkennungen/Preise prüft der Betreiber vor AP1; keine Recherche oder Preisannahme für die synthetische Planung. |
| BL-45 | Synchronisation der übergeordneten Projektanweisung an Betreiber nach dem Meilenstein vertagt; keine zusätzliche Projektdatei in PLAN ändern. |
| BL-46 | In M3c berücksichtigen: Zusatzteil liest Ergebnisse statt tausender Fits beim Vignettenbau; gesamten Knit/Bau messen und vorhandene vier Vignetten erhalten. |
| BL-47 | VariantBench-Zitation ist Publikationsarbeit beim Betreiber; keine Änderung an Daten-/Literaturgrundlage der M3c-Kriterien. |
| BL-48 | Gate-/Kriterien-Mapping bleibt Betreiber-/Reviewer-Aufgabe; Handoff referenziert K-M3c-1 bis K-M3c-6 eindeutig, keine Gate-Auswahl ändern. |
| BL-49 | Bestehende REML-Toleranzen erhalten; Recovery verwendet Komponenten-MCSE und ANK-TOL, keine Anpassung von Schwellen oder Engine an erwünschte Zahlen. |
| BL-50 | In M3c umsetzen: empirischen Prompt-CV aller Replikate samt Grenzanteil/MCSE pro Kandidatenplan gegen ANK-89 berichten; keine Gleichheitsforderung. |
| BL-51 | Exportentscheidung für interne `acmg_*` an Betreiber/ADR nach AP1 vertagt; M3c fügt keinen Export hinzu. |
| BL-52 | Wiederholte AP1-Auswertung nach M1 beim Betreiber; M3c nutzt keine vorläufigen AP1-Zahlen als Referenz. |
| BL-55 | Rollback-/Ignored-Path-Problem an Template-Wartung vertagt; lokale Prüfartefakte außerhalb des Baums halten und eigene Dateiintegrität prüfen. |
| BL-57 | Für die neue Schnittstelle unmittelbar berücksichtigen: `r4s` am Ende mit Default, alter ANK-02-Präfix unverändert. Generische Verschärfung des Abnahmetests bleibt Reviewer-Aufgabe. |
| BL-64 | Entkopplung des AP1-Pilotquantils vertagt auf AP1-Wartung; die Planung benutzt den ausdrücklich vereinbarten Quantiltyp 7 und ändert `R/acmg.R` nicht. |
| BL-68 | Wortlaut zur unveränderten Store-Datei an nächste AP1-Fehlermeldungswartung vertagt; Store-Pfad wird in M3c nicht verändert. |
| BL-70 | Transportstatus, Timeouts und Harness-Statusdarstellung an Betreiber/Template vertagt; keine Zustandsdateien oder Ausführungsflags ändern. |
| BL-71 | Memorisation-Näherung/ADR vor endgültiger AP1-Interpretation beim Betreiber; keine Golden-Datenänderung durch M3c. |
| BL-72 | Lehre anwenden: neue Tests mit portablen Pfaden und exakt adressierten Ankertoleranzen; keine pauschale Toleranzlockerung. |
| BL-73 | Pilotkosten-Erklärung/Sol-Abgleich an AP1-Berichtspflege mit Betreiber vertagt; Kontrollkartenbericht benötigt diese Änderung nicht. |
| BL-74 | API-Latenz und Zeitplanung an AP1-Betreiber vertagt; M3c enthält keine Requests. |
| BL-75 | Netzwarte-/Latenzaufbereitung an spätere AP1-Berichtspflege vertagt; Laufzeiten der neuen Simulation werden eigenständig protokolliert. |
| BL-77 | Falsche QA-Referenzen sind Rollen-/Template-Thema; neue Handoffs erhalten exakte Kriterienrefs, vorhandene QA-Handoffs bleiben unangetastet. |
| BL-79 | Archivierung vollständiger Mutationsberichte bleibt beim Betreiber; lokale Diagnosen werden nicht als Gate-Score ausgegeben. |
| BL-80 | NIST-Exponent in Spec/Anker bleibt Betreiber-/Reviewer-Korrektur; neue M3c-Zahlen stammen aus den dafür vorgesehenen Ankern. |
| BL-81 | Laut PROGRESS in M1b bereits adressierte Behandlung fehlender Gruppen als Regression erhalten; formale Statuspflege dem Reviewer überlassen. Kein neuer Eingriff in den latenten Fit. |
| BL-84 | Optionale Fit-Mutationslücken an spätere Numerikwartung nach dem 26.11. vertagt; M3c stärkt die tatsächlich geänderten Funktionen. |
| BL-85 | Mutanten-Identität/Approval-Härtung bleibt Betreiber-/Reviewer-Aufgabe; keine eigene Genehmigung oder Übernahme veralteter Approval-Dateien. |
| BL-86 | Bestehende Infrastrukturgrenzen berücksichtigen; bei tatsächlichem Auftreten Log/Prüfgrenze übergeben. Dispatcher, Sockets und Uhrzeitprüfung werden nicht umgangen. |
| BL-87 | Bekannte schwierige Hochwiederholbarkeitsfälle an geplante Numerikwartung vertagt. Falls ein reguläres M3c-Szenario scheitert, als eigenen Kriterienfehler beheben statt Fits auszusortieren. |
| BL-91 | Offene Reviewer-Frage zur latenten Permutations-/Engine-Auslegung bleibt dort; vorhandene Dokumentation und Tests erhalten, keine M3c-Änderung an ordinalem Verhalten. |
| BL-93 | Reviewer-Helferwarnungen bleiben nonblocking und außerhalb des Builder-Territoriums; bei Regressionen vollständig berichten, keine Acceptance-Helfer ändern. |
| BL-100 | Bestehende Vertagung der numerischen `...`-/Identifizierbarkeits-Randfälle nach dem 26.11. beibehalten; S-plan nutzt reguläre Standardfits ohne diese Eingaben. |
| BL-101 | Gewicht-null-/Termauswahl-Randfälle bleiben im bereits vorgesehenen Arbeitspaket nach dem 26.11.; kein gewichteter latenter Fit in M3c. |
| BL-102 | Verbleibende optionale Fit-Mutationslücken nach dem 26.11. behandeln; aktuelle Gates mit unverändertem Scope/Schwellen ausführen lassen. |
| BL-103 | Projektkorrektur des Rollbacks erhalten; verbleibende Übernahme ins Harness-Template beim Betreiber, keine Produktmaßnahme in M3c. |
| BL-104 | Erledigter Projektfehler bleibt erledigt; verbliebene Template-Nachpflege dem Betreiber zuordnen. Keine Testlaufumgebung im Repo umschreiben. |
| BL-105 | Umgang mit durch Infrastruktur verbrauchten Runden an Betreiber/Template vertagt; Builder verändert keine Rundenzähler oder Statusdateien. |
| BL-106 | Territoriums-Basis und Zwischenphasenänderungen bleiben Orchestrator-Thema; nur zugewiesene Dateien schreiben und Befund mit Phase/Beleg übergeben. |
| BL-107 | Mutations-Scope-/Cache-Härtung an Betreiber vertagt; M3c erzeugt keine eigene Baseline und verändert keine Auswahl oder Wiederverwendungsregeln. |
| BL-108 | Iterationslimit für schwierige ordinale Hoch-ICC-Fälle bleibt spätere Numerikarbeit; die Planung verwendet numerische Fits. |
| BL-109 | Latente Skalenhinweise erhalten; noch offene AP1-Sensitivität mit Interaktionen ist Betreiber-Auswertungsarbeit außerhalb M3c. |
| BL-110 | Zusätzliche Klasse-B-CSV-Härtung bleibt nach dem 26.11. vertagt; der neue Planungsleser erhält eigenen Schema-/Vollständigkeitsvertrag, ohne alte B-Dateien oder Leser umzubauen. |
| BL-113 | Umgesetzte Modalregel erhalten; verbleibenden Hinweis in der AP1-Endauswertung beim Betreiber belassen. Keine zusätzliche Änderung am Agreement-Bericht. |
| BL-114 | CRAN-Umgang mit großen Klasse-B-Dateien an AP2/Betreiber vertagt; neue Planungsreplikate kompakt gzip-komprimieren und Größen dokumentieren. Keine Ignore-Regel ändern. |
| BL-115 | Alte Implementierungshash-/Locale-Härtung vertagt wie vorgesehen; neue Erzeugung mit festem RNG, kontrollierter Locale und ehrlicher Provenienz, ohne alte B-Sessions umzuschreiben. |
| BL-117 | Weitere M1d-Ergebnisleser-Härtung nach dem 26.11. beibehalten; M3c benutzt einen getrennten, geprüften Planungsleser. |
| BL-119 | Sensitivitäts-/Etikettenkorrektur der LLM-Vignette an Betreiber vor Publikation vertagt; M3c verändert weder diese Daten noch ihre Interpretation. |
| BL-121 | Statische Lektüre: DESCRIPTION enthält die pkgdown-URL bereits. Keine weitere URL-Änderung geplant; `check_pkgdown()`-/Statusbestätigung bleibt beim zuständigen Prüflauf, hier kein Erfolgsbeleg behauptet. |
| BL-123 | Laut Backlog vor M3c entfernte Baseline respektieren; in der gelesenen Inventur liegt keine entsprechende Baseline-Datei vor. Neumessung und spätere Scope-spezifische Baselines bleiben Betreiberaufgabe. |
| BL-124 | Laplace-/Engine-Grenzen ordinaler Hoch-ICC-Fälle an eigenständige Methoden-/ADR-Arbeit vertagt; keine alternative Engine für numerische M3c-Planung. |
| BL-125 | Erweiterte Lenth-Kontraste nach erster Veröffentlichung/AP1-Sensitivität behandeln; kein Robustheitseffekt im M3c-Kriterienumfang. |
| BL-126 | Lenth-Kalibrierungsstudie auf das vorgesehene spätere Methodenpaket vertagen; keine Kalibrierung von Planungs-CV oder Westgard-Schwellen. |
| BL-127 | Robustheits-Eingabehärtung nach dem 26.11. gemäß bestehender Zuordnung; M3c verändert diese Funktionen nicht. |
| BL-128 | Erledigte Druck-/Snapshot-Teile erhalten; übriger Plot-Snapshot-Kommentar und optionale Äquivalenzprüfung beim nächsten tatsächlichen Eingriff in Robustheitstests, frühestens nach dem 26.11. |
| BL-129 | Half-normal-Grafikdarstellung an späteres Robustheits-/Grafikpaket vertagt; die M3c-Shewhart-Grafik ist eine andere Schnittstelle. |
| BL-130 | Fehlender Logit-Skalenhinweis bleibt als eigener Berichtspunkt nach dem 26.11. vertagt. Trotz Änderung derselben Vorlage beschränkt M3c die fachliche Änderung auf R_4s; bestehende Robustheitszahlen/-tests bleiben erhalten. |
| BL-132 | Agreement-Unterlauf-/Level-Randfälle an vorgesehenes Paket nach dem 26.11. vertagt; keine Agreement-Funktion für M3c ändern. |
| BL-133 | Reihenfolge von Bedingungen und R²-Fehlermeldung nach dem 26.11. behandeln; keine Abhängigkeit zur Systemeignung. |
| BL-134 | Agreement-Snapshot-Kommentare und optionale Testlücken beim nächsten dortigen Eingriff, frühestens nach dem 26.11.; neue M3c-Tests nutzen fachliche Orakel. |
| BL-136 | Bekannten irr-Orakelfehler bei späteren Agreement-Tests durch Reviewer/QA berücksichtigen; M3c benötigt qcc und eigene Formeln, keinen neuen irr-Vergleich. |
| BL-137 | Bereits geprüften Betreiberfix erhalten; noch ausstehende CI-Prüfung nach Push beim Betreiber. Lokaler M3c-Erfolg ist kein Ersatz für Plattformbelege. |
| BL-138 | Betreiber prüft CI vor Fortsetzung/Release; Template-Erweiterung um Plattformstatus/noLD bleibt außerhalb M3c. Neue Tests werden portabel angelegt. |
| BL-139 | CSV-Literal „NA“ in Stores an das vorgesehene Wartungspaket nach dem 26.11. vertagt; keine Store-Lese-/Schreibänderung in M3c. |
| BL-140 | Metadaten-/Backend-NULL-Wortlaut an separate Berichtspflege nach dem 26.11. vertagt; neuer Lesartparameter ändert keine Metadatenaufbereitung. |
| BL-141 | Bootstrap-Abwesenheitsdarstellung nach dem 26.11. behandeln; M3c erhält den vorhandenen Bootstrap-Abschnitt unverändert. |
| BL-142 | Optionale Berichtsdaten-Testlücken, tote Helfer und Konstantenbereinigung nach dem 26.11. behandeln; `R/report-data.R` bleibt für die geplante Lesartweitergabe unverändert. Neue M3c-Berichtstests prüfen den fachlichen Zusatz. |
| BL-143 | Parserverhalten bei Länge zwei an separates Parser-Wartungspaket nach dem 26.11. vertagt; keine Änderung von `parse_*`. |

Bereits als erledigt dokumentierte Einträge werden erhalten und nicht neu
aufgerollt: BL-12, BL-16, BL-18, BL-19, BL-24, BL-26, BL-27, BL-32, BL-38,
BL-44, BL-53, BL-54, BL-56, BL-58, BL-59, BL-60, BL-61, BL-62, BL-63,
BL-65, BL-66, BL-67, BL-69, BL-76, BL-78, BL-82, BL-83, BL-88, BL-89,
BL-90, BL-92, BL-94, BL-95, BL-96, BL-97, BL-98, BL-99, BL-111, BL-112,
BL-116, BL-118, BL-120, BL-122, BL-131, BL-135 und BL-144. Soweit diese
Einträge fortlaufende Betreiberpflichten nennen, bleiben sie bestehen; die
zugehörigen offenen Aufgaben sind oben separat zugeordnet, insbesondere
BL-17/28, BL-104/113, BL-123 und BL-137/138.

## Testplan

Alle folgenden fachlichen Läufe sind für BUILD geplant, in dieser PLAN-Phase
nicht ausgeführt. Prüfungen verwenden die unveränderten Reviewer-/QA-Dateien
und den tatsächlich geladenen Paketstand. Keine Referenzzahl stammt aus der
Implementierung als Orakel; Toleranzen werden über exakte Schlüssel aus
ANK-TOL bezogen.

### Deterministische Kriterien und Integration

| Prüfweg | Inhalt und maßgebliche Grenze |
| --- | --- |
| `tests/acceptance/test-m3c-1-westgard-rules.R` | Exakte/knapp benachbarte Grenzen, vollständige Fenster, Warnung/Ablehnung, Baseline und gegebene Standardisierung; 1.500 Reihen nach Reviewer-Seed 31081 gegen Mini-Referenz. |
| `tests/acceptance/test-m3c-2-r4s-reading.R` | API-Präfix/Default, beide R_4s-Lesarten und Orientierungen, unbekannte Auswahl, Druck und echte HTML-Ausgabe; 1.500 Reihen nach Seed 31082. |
| `tests/acceptance/test-m3c-4-qcc-limits.R` | Drei Zentrum-/SD-Konfigurationen; tatsächlich aufgezeichnete Plotlinien gegen geschlossene Formel und Live-qcc-Orakel; ANK-TOL.oracle.closed_form_rel_tol. |
| `tests/acceptance/test-m3c-5-simulator-latent.R` | Itemkonstanz, reine Itemvarianz, Itemvarianz null und Verschiebung des Gesamtmittels bei gleichem Seed; keine Entfernung der Spalte `latent`. |
| `tests/acceptance/test-m3c-6-plan-replicates.R` | Zwei Pläne mit 25 Wiederholungen, vollständige Schlüssel/Typen, wahre Komponenten einschließlich Interaktionen; alle Kennzahlen und Typ-7-Quantile unabhängig nachgerechnet, Toleranz ANK-TOL.arithmetic; Seed-Reproduktion. |
| `tests/acceptance/test-m3c-6-vignette.R` | Vollständige vier Planzeilen, genau neun verlangte Spalten, Rundungspräzision und aus Dateien/Ankern gelesene Zahlen. |
| Bestehende M3d-Berichtsabnahme, `tests/testthat/test-report-provenance.R`, `tests/e2e/test-m3d-qa-e2e.R` | Default-Satz, Signatur, attributfreie Hilfstabelle, sortierte tatsächliche Indexpositionen und bereits abgenommene Berichtsinhalte. |
| Neue Builder-Unit-Tests | Kleine fachliche Fälle ergänzend zur Abnahme: positive affine Transformation und Vorzeichenumkehr der z-Reihe, Regelauswahl, fehlendes Lesartattribut; Planzuordnung/RNG/Abbruch; Ressourcenfehler nur in temporären Kopien. |

Die neuen Plan-Tests prüfen Summen-/Quadratsummen- und Quantilrechnung unabhängig
von einem etwaigen Produkt-Aggregationshelfer. Der ergänzende CV-MCSE wird gegen
die Delta-Rechnung in der Parametrisierung (Mittelwert, zentriertes zweites
Moment) und analytische Ableitungen geprüft; ein kleiner direkter Fall erlaubt
die Nachrechnung ohne Modellfit. Ressourcen-Negativfälle umfassen fehlende Datei,
Hashfehler, doppelte/fehlende Plan- oder Replikatschlüssel und nichtendliche
Kennzahlen. Bestehende Quellen-/Literalwachen laufen über alle vom Rmd geladenen
Helfer; sie werden nicht umgangen oder abgeschwächt.

### Klasse A und Reproduktion

| Unveränderter Test | Ausführung und Entscheidung |
| --- | --- |
| `tests/simulation/test-westgard-false-alarm.R`, Einzelregeln | Je Lesart 100 · ANK-06 unabhängige Reihen mit zwölf Positionen; beide Lesarten vollständig gegen Mini-Referenz. Analytische p aus ANK-86; MCSE sqrt(p(1−p)/n); Abstand höchstens ANK-TOL.mc_factor.pass (derzeit vier) MCSE. Vor vollständigem Fenster exakt null. Seeds/Worker-Verteilung aus dem vorhandenen Test erhalten. |
| Dieselbe Datei, Parvin | 20 · ANK-06 Läufe je Verschiebung 0, 1 und 2 SD; zehn Vorlaufwerte und Initialisierungs-/Ablehnungsregel des fortlaufenden Verfahrens aus ANK-87. Kombination 1_3s/2_2s/4_1s/10_x ohne R_4s, N = 1. 1/ARL gegen die drei publizierten Werte innerhalb der ankereigenen absoluten Toleranz 0,016; keine zusätzlich aufgeschlagene MCSE-Toleranz. Delta-MCSE berichten. |
| `tests/simulation/test-simulator-recovery.R` | ANK-06 Wiederholungen von S-sim-1, Seeds 20261108+s; alle acht Komponenten einzeln sowie Itemwahrheit/Mittel-/Unabhängigkeitsgrößen gegen Vorgaben mit dem bestehenden vier-MCSE-Kriterium prüfen. |
| `tests/simulation/test-plan-satterthwaite.R` | Je S-plan-Kandidat ANK-06 Wiederholungen und Seed 20261108+i. Frische Prompt-Schätzungen einschließlich Nullen gegen die wirklich gerenderte Vignettentabelle; Vollständigkeit und Darstellung innerhalb halber letzter gezeigter Stelle plus ANK-TOL.arithmetic. Keine Grenze für CV_empirical − CV_rule. |

Die Builder-Erzeugung und die Reviewer-Studie sind getrennte Aufrufe derselben
öffentlichen Funktionen; der Builder-Erzeuger lädt keine Acceptance-Helfer und
übernimmt keine Attrappenzahlen. Eine Wiederholung in einem separaten Ausgabeziel
prüft die Ergebnisreproduktion. Replikat-/Ergebnisschema und Hashes werden
abgeglichen; tatsächliche Laufzeiten/Sitzungsangaben werden für jeden Lauf neu
protokolliert, nicht auf Bytegleichheit fingiert.

Die vollständige Klasse-A-Suite unter `tests/simulation/` erhält eine gemeinsame
Zeitmessung gegen ANK-TOL.sim_runtime (derzeit 20 Minuten auf 14 Kernen).
Einzeldatei-Messungen allein belegen dieses Budget nicht. Die Vorgaben werden bei
Überschreitung nicht reduziert; Ursache und tatsächliche Laufzeit gehen in den
Handoff. Die in ACC-10 genannten Probezeiten sind ausschließlich Orientierung.

### Regression, Paket und Gates

Gezielte direkte testthat-Aufrufe nutzen in einer temporären Paketkopie
`load_package = "source"`, den unveränderten Filter `^m3c-` für M3c-Abnahme und
die drei oben genannten Dateien für M3c-Simulation. `REPO_ROOT` zeigt auf die
Originalanker/geschützten Quellen; Produktfunktionen kommen stets aus dem
geladenen Namespace der geprüften Kopie. Alle Fehlschläge/Fehler werden gesammelt
und bestimmen den Exitstatus; keine Umdeutung von Skips in bestandene Kriterien.
Grafikdateien, testthat-Zwischenstände und Renderprodukte bleiben außerhalb des
Arbeitsbaums. `NOT_CRAN=true` aktiviert die bereits vorhandenen Berichtstests.

Nach den gezielten Prüfungen folgen Unit- und unveränderte E2E-/Fuzz-Tests,
M1a-Numerikregression und die berührte M3d-Berichtsabnahme. Der Orchestrator führt
die vollständigen kumulativen Kriterien aus; insbesondere historische
Git-verwendende Prüfwege werden nicht eigenständig vom Builder gestartet.
Der API-Vergleich lädt ANK-02 direkt und prüft 22 Exportverträge mit unveränderten
Argumentpositionen/-vorgaben sowie den neuen Default am Ende.

Paketbau und `R CMD check --as-cran --no-manual` laufen außerhalb des Repos mit
einer Positivliste der Paketdateien in beiden Dokumentationskontexten: öffentlich
ohne REPO_ROOT und vollständig mit Originalankern/lokalen geschützten Quellen.
Alle Vignetten bauen ohne Netz. Die erzeugten HTML-Tabellen werden inhaltlich
gelesen; fehlende lokale Pflichtquellen führen im Vollkontext zum Fehler. Es
werden keine Abhängigkeiten durch den Builder installiert; Suggests/qcc stellt
das deps-Gate bereit. Paketcheck-Regeln bleiben unverändert.

Der reguläre Mutationslauf umfasst seit M3a alle `R/*.R`, mit unveränderter
Schwelle/Floor/Ratchet aus ANK-32 und 14 Workern. M3c-Abnahmetests bleiben im
vorgesehenen Mutations-Prüfweg, `tests/simulation/` bleibt außerhalb der Tests je
Mutant. Keine zusätzliche Exklusion, keine eigene Baseline, keine eigene
Äquivalenzgenehmigung. Falls ein späterer Claim nötig wird, wird er einzeln mit
ausführbarem Beleg an den Reviewer gegeben.

BUILD dokumentiert nur wirklich ausgeführte Befehle und deren vollständigen
relevanten Output, einschließlich n, Seeds, RNG, Versionen, MCSE, Laufzeit und
Prüfgrenzen. Die Abnahmeentscheidung, Gate-Fakten, Territoriumsprüfung und der
Phasen-Commit bleiben beim Orchestrator/Reviewer.
