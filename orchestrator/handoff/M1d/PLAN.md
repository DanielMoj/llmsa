# PLAN — M1d, Runde 1

Rolle: Builder · Phase: PLAN · Stand: 04.11.2026.

## Ziel

M1d liefert zwei reproduzierbar eingefrorene öffentliche Datensätze, die Vignetten `llm-stability` und `clinvar-raters`, den Bericht über die vier Klasse-B-Vollläufe und den Robustheitswortlaut aus ADR-045. Maßgeblich sind K-M1d-1 bis K-M1d-8 in `docs/02-statistikkern.md`, die Querschnittsregeln in `docs/01-fachspezifikation.md` und die konkreten Verträge ACC-1 bis ACC-20 in `CRITERIA.json`.

Die Rechenverfahren von `msa_fit()`, `msa_grr()` und `msa_boot()` bleiben auf dem abgenommenen Stand von M1c. Insbesondere gilt wörtlich: „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ (`docs/02-statistikkern.md`, M1d, vor den Kriterien). Die neue Laufzeitänderung im Produkt betrifft ausschließlich die Ausgabe des Robustheitsergebnisses; dessen Objekt, ME-/SME-Berechnung und AP1-Bänder bleiben gleich.

Diese PLAN-Session schreibt ausschließlich diese Datei. Sie führt weder Git-Kommandos noch Produkt-, Abnahme- oder Gate-Läufe aus. Implementierung, Datenerzeugung und die unten geplanten Prüfungen gehören in BUILD beziehungsweise in die anschließenden Orchestrator-Gates. Ein grünes Kriterium wird hier nicht behauptet.

### Gelesene Grundlagen und Ausgangslage

Gelesen wurden `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `PROGRESS.md`, das gesamte `BACKLOG.md` einschließlich BL-116, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/handoff/M1d/CRITERIA.json`, `docs/01-fachspezifikation.md` und `docs/02-statistikkern.md`. Hinzu kommen sämtliche acht `tests/acceptance/test-m1d-*.R`, `setup-m1d.R`, die gemeinsamen Abnahmehelfer, die Ergebnisleser und bisherigen Vignettenverträge aus M1b/M1c sowie die einschlägigen ADRs, insbesondere ADR-035, ADR-040 bis ADR-043, ADR-045 bis ADR-047. Es gibt für M1d noch kein `PLAN-REVIEW.md` und kein `ARBITER.md`.

Die Pflichtlektüre und die Bestandsaufnahme erfolgten lesend. Die Roharchive von llm-stability und ClinVar sind aus dieser Sandbox erreichbar. Die zwei neuen Datenordner, ihre Erzeugungsskripte und die beiden neuen Vignetten fehlen noch. `_pkgdown.yml` hat noch keinen `articles`-Abschnitt.

ACC-14 beschreibt einen inzwischen überholten Fehlstand: Alle zwölf Volllaufdateien sind vorhanden. BL-12 dokumentiert den Betreiber-Abschluss vom 04.11.2026. Die lesende Bestandsaufnahme mit Python (`csv.DictReader`, `Path.stat()`, keine Simulation) lieferte tatsächlich:

```text
ordinal_recovery: files=3/3; result_rows=100; n_sim=['1000']; scenarios=4; bytes=4024154
binary_recovery: files=3/3; result_rows=40; n_sim=['1000']; scenarios=2; bytes=1244208
two_level: files=3/3; result_rows=42; n_sim=['1000']; scenarios=2; bytes=2891284
boot_coverage: files=3/3; result_rows=386; n_sim=['1000']; scenarios=7; bytes=12807696
pkgdown_articles_present=False
backlog_entries=116; first=BL-01; last=BL-116
M1c_gates_result=pass
```

Zusätzlich wurden die gespeicherten Kurzlaufreplikate mit den gespeicherten ersten Wiederholungen der Vollläufe verglichen: Sie stimmen in allen vier Studien überein. Das ist eine Prüfung zweier vorhandener Dateien, **kein** Neulauf und noch kein Nachweis von K-M1d-6. Die Roharchive wurden auf Lesbarkeit geprüft; ihre vollständige SHA-256-Prüfung gegen ANK-40/ANK-41 gehört noch zur Datenerzeugung. Die vier aktuellen Quelldateien aus ANK-34 stimmen per SHA-256 mit dem dort dokumentierten M1c-Ausgangsstand überein.

`orchestrator/state/M1c/gates.json` meldet `pass`; `orchestrator/handoff/M1c/verdict-code.json` enthält PASS ohne blocking-Befund. Der M1c-Review berichtet den Mutationslauf mit 1478 Mutanten und Score 92,80 bei verlangten 92,09. Das sind gelesene Fremdbelege. Gemäß ADR-047 ist dieser Lauf der Mutationsbeleg für M1d, sofern ACC-12 erfüllt bleibt und kein Test entfällt oder abgeschwächt wird; M1d erhält dadurch keinen eigenen gemessenen Mutationsscore.

## Dateien

Die folgende Liste beschreibt die spätere BUILD-Arbeit. In dieser Runde wird davon nur `orchestrator/handoff/M1d/PLAN.md` geschrieben.

| Pfad | Geplante Änderung und Zweck |
| --- | --- |
| `data-raw/make_llm_stability.R` | Neues ausführbares Offline-Skript für Auswahl, Antwortparsing, Validierung und deterministische Ausgabe der Itemdaten; K-M1d-1. |
| `data-raw/make_clinvar_subsets.R` | Neues Offline-Skript für gefilterte ClinVar-Einreichungen, Genabbildung und die verankerte Stichprobe; K-M1d-3. |
| `data-raw/make_validation_m1d.R` | Übernimmt die benötigten ganzen Ankerdateien bytegleich nach `inst/validation/m1d/anchors/` und erzeugt deren Herkunftsmanifest; keine selbst gepflegten Zahlenkopien. |
| `inst/validation/m1d/prepare.R` | Kleine, reine Hilfsfunktionen für Antwortetiketten, Auswahl-/Datumskonventionen und deterministisches Schreiben, von den Datenskripten genutzt und unabhängig mit kleinen Fixtures prüfbar; keine öffentliche API. |
| `inst/validation/m1d/findings.R` | Ergebnisdarstellung, Schwellenentscheidung und getrennte Konvergenz-Sensitivität aus vorhandenen CSV-Dateien; keine Simulationsgeneratoren und kein Fit-Code. |
| `inst/validation/m1d/anchors/`, `SOURCES.json`, `README.md` | Ganze benötigte Anker ANK-06, ANK-40 bis ANK-47, ANK-63 und ANK-TOL, Herkunft/SHA-256, Dokumentation der Offline-Leser; kein Original-PDF und keine lokalen geschützten Datentabellen. |
| `inst/extdata/llm-stability_2026-10-22/items.csv.gz`, `SHA256SUMS`, `QUELLE.txt` | Eingefrorene Itemdaten, vollständiges Dateimanifest und englische Provenienz. |
| `inst/extdata/clinvar_2026-10-19/hrf_submissions.csv.gz`, `sample_submissions.csv.gz`, `SHA256SUMS`, `QUELLE.txt` | Zwei eingefrorene Einreichungs-Teilmengen, Manifest und englische Provenienz. |
| `vignettes/llm-stability.Rmd`, `vignettes/clinvar-raters.Rmd` | Neue installierbare Vignetten mit tatsächlichen Berechnungen aus den eingefrorenen Daten. |
| `vignettes/validation.Rmd` | Alle vier Volllauf-Auswertungen mit MCSE, automatisch benannten Befunden und klar getrennter Konvergenz-Sensitivität; bisherige Referenzrechnungen erhalten. |
| `R/fit.R`, `R/grr.R` | Ausschließlich roxygen-Zeilen für qualitative Studienbefunde und Vignettenverweise; sonst zeilengleich zu ANK-34/done/M1c. |
| `man/msa_fit.Rd`, `man/msa_boot.Rd` | Aus den roxygen-Änderungen erzeugte Hilfe. Keine handgeschriebenen Ergebniszahlen. |
| `R/robustness.R` | Nur `print.msa_robustness` und nötigenfalls ein interner Textformatierer: verbindlicher Satz beziehungsweise Faktor-Zusätze. |
| `inst/templates/validation_report.Rmd` | Gleicher Robustheitswortlaut in Abschnitt 6; bestehende Tabellen, Kennzahlen, latenter Hinweis und AP1-Bänder bleiben erhalten. |
| `tests/testthat/test-m1d-data.R`, `test-m1d-findings.R` | Gezielte Tests der neuen nichttrivialen Parser-, Auswahl- und Befundlogik; keine Kopie der Abnahmetests und keine großen Rohdaten als Unit-Fixtures. |
| `NEWS.md`, `PROGRESS.md` | Englische nutzersichtbare Änderungen; deutscher Umsetzungsstand mit tatsächlich ausgeführten Befehlen, Output und Grenzen. M1c-Abschluss als Nachtrag mit Verweis auf seine Gates, keine Umschreibung historischer BUILD-Belege. |
| `docs/decisions/ADR-<freie Nummer>-m1d-daten-und-validierungsressourcen.md` | Builder-ADR im selben Meilenstein für neue Golden-Daten, Auswahl, Herkunft, Kopiermanifest und Determinismus. Nummer erst bei BUILD nach dem Reviewer-ADR vergeben. |
| `orchestrator/handoff/M1d/REVIEW-INPUT.md` | Nach BUILD Zuordnung Kriterien → Änderungen → echte Prüfausgaben und verbleibende Befunde. |

Neue Imports, Exporte und API-Snapshot-Änderungen sind nicht nötig. Vorhandene `jsonlite`-/`digest`-Suggests reichen für die Entwicklungs-/Validierungsskripte; Paketfunktionen erhalten keine neuen Abhängigkeiten. Vorhandene Simulationsskripte, `simulation_helpers.R`, `boot_coverage_helpers.R` und die bestehenden Ergebnisleser bleiben unverändert. Insbesondere werden weder vollständige Studienergebnisse noch ihre Sessions/Hashes neu geschrieben.

### Konkrete Betreiber-Zuarbeit zu K-M1d-5

**M1D-INFRA-01 — nonblocking für den Builder, ref K-M1d-5 / ACC-8 (5).** Die aktive `BUILDER_EXTRA_PATHS_REGEX` in `orchestrator/config.env:200` enthält `_pkgdown.yml` nicht; auch `path_allowed()` in `orchestrator/orchestrate.sh` gibt diese Datei nicht frei. Der Builder darf den nötigen Eintrag deshalb nicht selbst schreiben. Vorschlag für den Betreiber: vor BUILD, außerhalb einer laufenden Modellphase, folgenden Abschnitt ergänzen und committen; das bestehende `destination: pkgdown-site` bleibt erhalten:

```yaml
articles:
- title: Applications
  contents:
  - llm-stability
  - clinvar-raters
```

Das ist keine Bitte um Lockerung der Territorien. Die Zuarbeit ist konkret benannt; fehlt sie bei den Gates, bleibt K-M1d-5 zu Recht rot. Der Reviewer kann den Infrastrukturpunkt in `BACKLOG.md` übernehmen. Kein Betreiber-Eingriff zwischen BUILD und GATES.

## Schnittstellen

Die 22 bestehenden Exporte behalten Namen, Argumentpositionen und Vorgabewerte gemäß ANK-02; Rückgabeobjekte werden nicht umdefiniert. `acmg_*` bleibt intern. Die neuen Hilfsfunktionen unter `inst/validation/m1d/` gehören ausschließlich zur Datenvorbereitung und Berichterstellung. Code, Kommentare, Paketdokumentation, Testnamen und Fehlermeldungen werden Englisch geschrieben; ADR, PROGRESS und Handoffs Deutsch. Es entsteht keine neue Parallelisierung in `R/`.

### K-M1d-1 und K-M1d-2: llm-stability

Das Erzeugungsskript läuft als `Rscript data-raw/make_llm_stability.R` aus der Paketwurzel und liest ausschließlich `../quellen/daten/llm-stability_2026-10-22/`. Es prüft Archiv und Auswahltabelle gegen ANK-40. Auswahl sind genau die dort genannten 40 Zero-shot-Ordner aus `experiments/v3/runs.tgz`, bestimmt durch `experiments/v3/stability_eval.csv`, `shots = 0` und `top_p_k = 1.0`. Die v2-Läufe mit nur fünf Wiederholungen sowie andere Temperaturen, Few-shot-Ordner und frühere Konfigurationen werden nicht vermischt.

Die gespeicherte CSV hat genau die Spalten `task,model,run,item_id,answer,correct` in dieser Reihenfolge. `item_id` kommt aus `rubric_id`, `run` bleibt 0–9. Vor Ausgabe werden Eindeutigkeit und Vollständigkeit aller Aufgabe×Modell×Lauf×Item-Schlüssel, fünf Modelle, acht Aufgaben und die aufgabenspezifischen Itemzahlen aus ANK-40 geprüft. Die daraus folgende Zeilenzahl wird berechnet, nicht zur Rekonstruktion fehlender Datensätze verwendet.

Der Parser extrahiert ausschließlich ein eindeutiges Antwortetikett aus den tatsächlich vorhandenen Antworttexten und den Optionen des Items, bei `navigate` Yes/No. Leere, nicht parsbare und mehrdeutige Antworten bleiben fehlend. Der Lösungsschlüssel dient ausschließlich dem nachfolgenden Gleichheitsvergleich, niemals zur Auswahl zwischen mehreren Antworten. Abweichende Schlüssel-/Optionsformate werden nachvollziehbar gezählt; es gibt keine Reparatur anhand erwarteter Trefferquoten. `correct` ist TRUE bei Gleichheit mit `gt`, FALSE bei vorhandener abweichender Antwort, NA bei fehlender Antwort. Rohtexte oder zusätzliche Originalfelder gelangen nicht in die eingefrorene Datei.

`QUELLE.txt` nennt Quelle, URL, Commit aus ANK-40, Apache 2.0, Archiv, `stability_eval.csv`, `top_p_k`, „zero-shot“, Auswahl, Skript und die berechneten Fehlend-/Parsingzählungen. `SHA256SUMS` umfasst jede gespeicherte Datei außer sich selbst, einschließlich `QUELLE.txt`.

Die Vignette liest ausschließlich über `system.file("extdata", "llm-stability_2026-10-22", "items.csv.gz", package = "llmsa")`. Je Aufgabe bildet `as_msa_runs()` Item = Frage, Prompt = eine konstante Stufe, Modell = Quellmodell, Replikat = Lauf, Block = 1 ab. `msa_counts()` zeigt alle Aufrufe je Modell einschließlich fehlender Antworten.

Die Wiederholbarkeit je Aufgabe und Modell ist der Anteil aller Items, deren zehn Antworten sämtlich vorhanden und identisch sind. Die Trefferquote zählt `correct == TRUE` im Zähler und alle Aufrufe im Nenner. Fehlende Antworten werden im Fit-Datensatz deshalb nicht zu falschen Antworten umcodiert. Je Aufgabe werden `msa_fit(type = "binary", interactions = FALSE)` mit dem Vorgabelink Probit und `msa_grr()` berechnet. Tabellen zeigen Wiederholbarkeit, Trefferquote, Item-/Modellkomponenten und %GRR nach Studienvariation mit mindestens zwei signifikanten Stellen; bevorzugt sechs zur nachvollziehbaren Gegenrechnung. Kein Ergebnis steht als numerisches Literal im Rmd.

Die Vignette erläutert den Unterschied zwischen empirischer Antwortgleichheit und der linkbedingt fixierten latenten Restvarianz gemäß ADR-040. Warnungen, fehlende Antworten und Fitdiagnosen werden erfasst und inhaltlich eingeordnet. Ein fehlgeschlagener Pflichtfit wird nicht durch eine andere Aufgabe, eine Scheintabelle oder ein vorab gespeichertes Ergebnis ersetzt.

### K-M1d-3 und K-M1d-4: ClinVar

`Rscript data-raw/make_clinvar_subsets.R` liest den Rohstand unter `../quellen/daten/clinvar_2026-10-22/`; der öffentliche Zielordner heißt entsprechend dem Datenstand **`clinvar_2026-10-19`**. SHA-256 und Spaltenherkunft folgen ANK-41/ANK-63. Die großen komprimierten Dateien werden blockweise beziehungsweise in begrenzten Durchgängen verarbeitet; keine vollständige Kopie aller Rohspalten im Arbeitsspeicher.

Verbindliche Reihenfolge ist: exakter Filter auf `Benign`, `Likely benign`, `Uncertain significance`, `Likely pathogenic`, `Pathogenic`; danach verschiedene verbliebene Submitter pro VariationID zählen; erst danach HRF-Auswahl beziehungsweise Stichprobenziehung. `submitter_id` ist der unveränderte Submitter-Text. Mehrere SCVs desselben Einreichers bleiben mehrere Zeilen und erhöhen nicht dessen Einreicherzahl. `gene` stammt aus `variant_summary`/GeneSymbol, verknüpft über VariationID; mehrteilige Werte mit `;` bleiben erhalten, fehlende Zuordnung bleibt NA. Widersprüchliche Assemblierungszuordnungen brechen benannt ab.

HRF umfasst alle Fünf-Klassen-Einreichungen zu Varianten mit mindestens zwei verschiedenen Einreichern, deren Genliste MEFV, MVK, NLRP3 oder TNFRSF1A enthält. Für die Stichprobe werden Varianten mit mindestens drei verschiedenen verbliebenen Einreichern numerisch nach VariationID sortiert. Umfang und Seed werden aus ANK-47 gelesen; RNG wird explizit auf Mersenne-Twister/Inversion/Rejection festgelegt. Alle passenden Einreichungen der gezogenen Varianten werden übernommen.

Spaltenreihenfolge beider Dateien: `variation_id,gene,submitter_id,classification,date_last_evaluated,review_status`. Datumsnormalisierung verwendet die englische Monats-Locale explizit; `-` bleibt fehlend, Ausgabe ist ISO. `review_status` wird unverändert übernommen. Die Zählungen ausgeschlossener Nicht-Fünf-Klassen-Einreichungen werden vor den Einreicherschwellen sowohl für alle vier HRF-Gene als auch für die gesamte Quelldatei ermittelt und in `QUELLE.txt` geschrieben. Die in ACC-6 berichteten Bestandszählungen sind Prüfbelege, keine Generator-Konstanten.

Die Vignette liest beide Teilmengen über `system.file("extdata", ...)`. Abbildung: Item = VariationID, Prompt = Einreicher, Modell = eine konstante Stufe, Replikat und Block = 1, Zielgröße in der oben genannten geordneten Fünf-Klassen-Skala. Sie berechnet je Teilmenge:

- `msa_agreement(..., weights = "unweighted")` für nominales Alpha und `weights = "linear"` für ordinales Alpha, jeweils die Zeile `all conditions`; keine vorherige Reduktion auf Modalwerte.
- Anteil der Varianten mit vollständig gleicher Fünf-Klassen-Einreichung und Anteil mit Konflikt zwischen mindestens zwei Gruppen B/LB, VUS, P/LP, jeweils unter Varianten mit mindestens zwei Einreichungen. Der Konfliktanteil ist nicht das Komplement der vollständigen Übereinstimmung.
- `msa_fit(type = "ordinal", levels = ..., interactions = FALSE)` mit Probit und `msa_grr()`: Item-/Promptkomponenten und %GRR nach Studienvariation.
- Sensitivität mit `startsWith(review_status, "criteria provided")`, ausdrücklich ohne Treffer auf `no assertion criteria provided`. Die ursprünglichen Einreicherschwellen werden nach diesem Filter nicht erneut angewandt; mindestens beide Alpha-Werte und die tatsächlich verbleibenden Nenner werden gezeigt.

Die Literaturtabelle liest alle numerischen Blätter von `value` in den unverändert kopierten ANK-42 bis ANK-46, nennt IDs, Quellen, Einheiten, Zählungen und jeweilige Bezugsgruppen. Der Text enthält wörtlich **„not an acceptance criterion“**. Kein Literatur- oder Ergebniswert wird im Rmd abgetippt. Unterschiede werden benannt: Yang verwendet verschiedene Zusammenfassungen der Klassen, nicht durchgehend exakte Fünf-Klassen-Konkordanz (ACC-18); Amendola vergleicht Laborbewertungen vor/nach Abstimmung; Harrison unterscheidet exakte Klassen und klinisch zusammengefasste Gruppen; Lazareva untersucht kumulative Konflikte über mehrere Jahre, keine Querschnittsquote dieser Stichprobe. Bei Van Gijn werden Abstract-Wert und die abweichende Results-Zählung anhand ANK-45 eingeordnet (ACC-19), ohne eine INSAID-Referenzklasse je Variante zu veröffentlichen.

Kappa wird in diesen beiden Vignetten nicht zusätzlich eingeführt: K-M1d-4 verlangt Alpha, und BL-113 betrifft eine andere, noch offene Modalwertdefinition. Diese Beschränkung verhindert keine geforderte Auswertung.

### K-M1d-5: gemeinsame Daten- und Bauverträge

Beide Generatoren validieren alle nötigen Eingaben, bevor sie Zieldateien ersetzen. Ohne `../quellen` kommt ein benannter Fehler mit „quellen“ und die eingefrorenen Dateien bleiben unverändert. Ausgabe zunächst in einem temporären Verzeichnis, Veröffentlichung erst nach erfolgreicher Validierung. CSV-Typen, NA-Schreibweise, Zeilenreihenfolge, Zeilenenden und gzip ohne Zeitstempel werden festgelegt; Sortierung ist unabhängig von der aufrufenden Locale. Die Erzeugung muss auch unter `LC_COLLATE=C` bytegleich sein.

Grenzen werden aus ANK-TOL.data_size gelesen: komprimieren oberhalb `gzip_above_bytes`, prüfen gegen `file_max_bytes`, `folder_max_bytes` und `extdata_total_max_bytes` in dezimalen Bytes. Die Gesamtprüfung umfasst auch die bestehenden AP1-/NIST-Daten. Keine Roharchive, Rohantworten, PDFs, INSAID-Klassifikationen oder unlizenzierte Daten werden mitgeliefert. Literaturanker behalten ihre kurzen Belegzitate; Quellenkopien unter `inst/` bleiben bytegleich.

Vignetten und Paketbau benötigen keinen Netzzugriff. Rmd-Code enthält keine `httr2`-, `curl`- oder `download.file`-Aufrufe. Es gibt kein Laden externer Daten bei Knit und keinen Simulationslauf beim Paketbau. Die pkgdown-Einträge werden über M1D-INFRA-01 geliefert.

### K-M1d-6 und K-M1d-7: Vollläufe und Befunde

Die vorhandenen Betreiberdateien sind unveränderliche Eingaben für M1d. Die offizielle Abnahme prüft alle Szenarien, Schätzziele, Kennzahlen und MCSE, mindestens ANK-06 Wiederholungen, Ableitung der Zusammenfassungen aus den Replikaten auf ANK-TOL.arithmetic sowie Seed/RNG/R-/Paketversionen und Laufzeitangaben. Sie rechnet tatsächlich die ersten ANK-TOL.n_check Wiederholungen neu: alle ordinalen, binären und Zwei-Stufen-Szenarien, bei Bootstrap S-boot-1 und S-boot-7. Vergleich in allen Spalten nach `format(x, digits = 15)`. Fehlende Dateien sind Fehler, keine Skips.

`validation.Rmd` verwendet die bestehenden Ergebnisleser und liest bei vorhandenen Vollläufen diese statt der Kurzläufe. Die Verträge der bereits abgenommenen M1b-/M1c-Tests bleiben erhalten: ein vorhandener fehlerhafter Volllauf wird nicht still durch einen Kurzlauf ersetzt; der historische Kurzlaufmodus bleibt als solcher gekennzeichnet. Er kann M1d nicht erfüllen, weil K-M1d-6 unabhängig die vollständigen Vollläufe verlangt. Das Lesen von Ergebnistabellen wird nicht nachträglich an einen Simulator, eine erneute Simulation oder die vollständige Sessionprüfung gekoppelt (ADR-043).

Die neue Befunddarstellung liegt außerhalb des Simulations-Hashbereichs. Je Studie/Szenario/Schätzziel zeigt sie Bias, relative Verzerrung und EmpSE samt jeweiliger MCSE in derselben Zeile; vorhandenes RMSE bleibt verfügbar. Bootstrap zeigt für `grr_pct_study_var`, `grr_pct_contribution`, `ndc` und `icc_items` zusätzlich Überdeckung und mittlere Intervallbreite mit MCSE. Diagnoseanteile werden gesondert von Schätzzielen dargestellt. `n_sim` wird aus jeder Ergebnisdatei gelesen. Prozentumrechnung betrifft Wert und MCSE gleichermaßen.

Die Benennung der Befunde wird aus den aktuellen Zeilen und den verankerten Berichtsschwellen erzeugt:

- Ordinal/binär: wahre Komponenten, ohne Residual, `grr_pct_study_var` und `icc_items`; Befund bei `abs(rel_bias) > max(ANK-TOL.bias_report.rel_bias, ANK-TOL.bias_report.mcse_multiple * mcse)`. Richtung und genaue `estimand`-/Szenario-ID stehen als `underestimation` oder `overestimation` in der Ausgabe.
- Zwei Stufen: Bias der Komponente `model` für jedes Szenario stets berichten, samt MCSE. Richtungsbefund erst oberhalb der Berichtsschwelle; andernfalls keine nachgewiesene Richtung in dieser Simulation, keine Behauptung allgemeiner Unverzerrtheit.
- Bootstrap: jedes Intervallschätzziel mit Abweichung vom nominalen Niveau um mehr als ANK-TOL.mc_factor, Berichtsschwelle, mal MCSE als `undercoverage` oder `overcoverage` benennen. Ein MCSE von null bei einer von nominal abweichenden Überdeckung darf den Befund nicht verschlucken. Das Niveau stammt aus dem Studienvertrag, nicht aus geschätzten Ergebnissen.

Die lesende Anwendung dieser Regeln auf den vorhandenen Dateien ergab folgende **zu dokumentierende Befundmenge**, keine neu erzeugten Simulationsergebnisse:

| Studie | Szenarien und Schätzziele | Aussage |
| --- | --- | --- |
| ordinal_recovery | S-ord-1: model, prompt; S-ord-2: model; S-ord-3: model, prompt; S-ord-4: model, prompt | Unterschätzung oberhalb der Berichtsschwelle. |
| binary_recovery | S-bin-1: model, prompt; S-bin-2: model | Unterschätzung oberhalb der Berichtsschwelle. |
| two_level | S-two-1 und S-two-2: model | Bias und MCSE in beiden Szenarien berichten; derzeit keine Richtung oberhalb der Berichtsschwelle. |
| boot_coverage | S-boot-1 bis S-boot-7: ndc | Überdeckung oberhalb der Berichtsschwelle. Für die übrigen Intervallschätzziele ergab die Bestandsauswertung keinen solchen Befund. |

Diese Tabelle wird nicht als fest codierte Ausgabe implementiert. Sie bestimmt den gegenwärtig nötigen qualitativen Hilfetext: `?msa_fit` nennt die betreffenden ordinalen/binären Szenarien und ordnet beide Zwei-Stufen-Szenarien ein; `?msa_boot` nennt die ndc-Überdeckung in allen sieben Bootstrap-Szenarien. Beide verweisen auf `vignette("validation")`. Vollständigkeit und Richtungen werden gegen die dynamisch bestimmten Befunde geprüft. Ein wissenschaftlich ungünstiger Befund macht keinen Test rot; fehlende oder falsche Dokumentation dagegen schon.

**BL-92 wird umgesetzt.** Eine getrennte Zusatzdiagnostik liest `ordinal_recovery_replicates.csv` und vergleicht je Szenario und Schätzziel alle endlichen Schätzungen mit der Teilmenge `converged == TRUE`. Die Hauptauswertung behält alle vertragsgemäß enthaltenen Fits. Beide Gruppen bekommen tatsächlich beobachtetes n, Bias, relativen Bias, EmpSE und MCSE nach den bestehenden ADEMP-Definitionen; nicht konvergierte und singuläre Anteile werden getrennt ausgewiesen. Kein Weglassen allein wegen Singularität. Der Ausgangsbestand enthält 9, 18, 20 und 16 nicht konvergierte Fits je 1000 in S-ord-1 bis S-ord-4; das wird zur Laufzeit aus den Replikaten ermittelt.

Diese Zusatzdiagnostik verändert die bestehenden Ergebnisleser nicht. Ihre Gruppengrößen stammen aus ihren Replikatzeilen und werden nicht aus dem `n_sim` einer möglicherweise separat geprüften Ergebnistabelle übernommen. Damit bleiben die M1b-/M1c-Leserprüfungen mit unabhängig veränderten Ergebnistabellen möglich. Im vollständigen M1d-Bestand wird die Sensitivität in der Vignette gezeigt; bei einer isolierten Leserprüfung ohne Replikate ist sie ausdrücklich nicht verfügbar. Das ersetzt weder die Volllaufprüfung noch deren Fehler bei fehlenden Dateien. Der Befund ist deskriptiv; das Entfernen nicht konvergierter Fits kann selbst eine Auswahlverzerrung erzeugen und ist kein neuer Schätzer.

### K-M1d-8: Robustheitswortlaut

Wenn kein Faktor über ME liegt, schreiben `print.msa_robustness` und Abschnitt 6 der Berichtsvorlage genau:

> No factor exceeded the margin of error (ME = x). Smaller effects cannot be told apart from noise with this design, so this result does not show that the pipeline is robust.

`x` wird aus dem aktuellen ME mit `formatC(..., format = "f", digits = 4)` erzeugt, identisch zur Darstellung in der PSE-/ME-/SME-Zeile. Bei aktiven Faktoren nennt jede Ausgabe jeden Faktor vor seinem Zusatz: `above ME only` bei `active == TRUE` und `active_simultaneous == FALSE`, sonst `also above SME`. Inaktive Faktoren erhalten keinen Zusatz; der Satz für keinen aktiven Faktor erscheint im aktiven Fall nicht. Die alte Phrase entfällt vollständig aus `R/` und `inst/templates/`.

Die Ausgabe kann einen kleinen internen Formatierer teilen; keine neue exportierte Funktion. `print` gibt das unveränderte Objekt unsichtbar zurück. `msa_robustness()` sowie `acmg_robustness()` und deren numerische Resultate werden nicht geändert. ACC-11 vergleicht sie auf den fünf allgemeinen Fällen und den AP1-Fällen für alle drei Bänder mit ANK-34/done/M1c.

### Übernahme der offenen Auslegungen

| Einträge aus CRITERIA.json | Behandlung in diesem PLAN |
| --- | --- |
| ACC-1, ACC-2, ACC-3 | Übernommen: verankerte Zero-shot-Auswahl, vollständiges Itemgitter, echte Antwortetiketten/NA, genaue Importabbildung. |
| ACC-4, ACC-8 | Übernommen: Manifest einschließlich QUELLE, bytegleiche Offline-Neuerzeugung, unveränderte Dateien bei fehlender Quelle, Größen-/Lizenz-/Netzprüfung; pkgdown konkret als M1D-INFRA-01 zugeordnet. |
| ACC-5 | Übernommen: Nenner einschließlich fehlender Aufrufe, binäre Pflichtfits je Aufgabe, vollständige berechnete Tabellen. |
| ACC-6, ACC-7 | Übernommen: ClinVar-Filterreihenfolge, eindeutige Einreicherzählung, alle SCVs, Genquelle, Seed/RNG, genaue Alpha-/Konflikt-/Sensitivitätsdefinition und sämtliche Literaturwerte. |
| ACC-9, ACC-10 | Übernommen: Vollständigkeit plus echter Präfix-Neulauf, Ergebnis/MCSE gemeinsam, dynamische Befundschwellen, qualitative Hilfe. |
| ACC-11, ACC-12 | Übernommen: exakter Wortlaut, unveränderte Robustheitsobjekte/Bänder und Nicht-roxygen-Zeilen der Kerndateien. |
| ACC-13 | Betreiberangelegenheit; inzwischen ADR-047 maßgeblich. Der Builder ändert weder Scope noch Testauswahl; M1c-Beleg und spätere Betreiber-Kontrolle werden offen benannt. |
| ACC-14 | Fehlstand durch die tatsächlich vorhandenen zwölf Dateien und BL-12 überholt; K-M1d-6 noch auszuführen, kein zusätzlicher Volllauf eingeplant. |
| ACC-15 | Reviewer-Anker werden unverändert genutzt/kopiert. Reviewer dokumentiert seine Auslegungen/Ankernachträge im angekündigten M1d-ADR; zusätzlich Builder-ADR für neue Golden-Daten. |
| ACC-16 | Historischer Reviewer-Teststand, kein eigener Lauf und kein aktueller Gesamtstatus. Neulauf nach Implementierung in den Gates. |
| ACC-17 | BL-92 wird mit separater Sensitivität umgesetzt; BL-113 wird begründet vertagt, da die neuen Vignetten kein Kappa verwenden. |
| ACC-18, ACC-19 | Literaturbegriffe und Abstract-/Results-Abweichung im Vergleich erklären, ohne private Quellenverzeichnisse oder Anker zu ändern. |
| ACC-20 | Rohdaten sind hier lesbar; Builder erzeugt die Teilmengen in BUILD. Ein erst nach BUILD zwischen Modellphase und Gates vorgenommener Betreiber-Eingriff ist nicht eingeplant. |

## Reihenfolge

1. **PLAN-REVIEW und Voraussetzungen:** Bindende Rückmeldung/ADR aufnehmen; M1D-INFRA-01 außerhalb der Modellphasen durch den Betreiber erledigen lassen. BUILD beginnt mit lesender Prüfung von Ankern, Roharchiven, den zwölf vorhandenen Volllaufdateien und der UTF-8-Locale. Neue reale Fehler benennen; keine Daten erfinden.
2. **Provenienz und kleine Hilfsfunktionen:** Builder-ADR anlegen, Ankerkopien samt Manifest erzeugen, deterministische Parser-/Auswahl-/CSV-Funktionen mit kleinen allgemeinen Fällen prüfen. Noch vor großen Läufen Fehlerverhalten und Ausgabeatomizität prüfen.
3. **Daten einfrieren:** Beide Generatoren ausführen, Laufzeit/Speicherbedarf und Ausschlusszählungen protokollieren, anschließend unabhängig in temporärer Paketkopie wiederholen. SHA-256, Bytereproduktion, Schema, Schlüssel, Auswahl und Größe prüfen. Erzeugte Dateien erst danach als Grundlage der Vignetten verwenden.
4. **Pflichtfits früh erproben:** Alle acht binären Aufgabenfits und beide ordinalen ClinVar-Fits mit den verlangten Vorgaben durchführen. Damit werden reale Modell-/Laufzeitprobleme vor dem Ausformulieren der Vignetten sichtbar. Bei einem echten Kernproblem kein verbotener Eingriff in `R/fit.R`/`R/grr.R`; Befund mit Kriteriumsbezug an den Reviewer.
5. **Neue Vignetten:** Tabellen, Missingness-/Diagnosehinweise, Alpha-/Konflikt-Sensitivität und verankerte Literaturvergleiche erstellen und im installierten temporären Paket offline stricken. Kein Ergebnis aus dem Entwicklungs-Workspace als versteckte Knit-Eingabe.
6. **Volllaufbericht:** Vorhandene Tabellen einlesen, MCSE-Darstellung und dynamische Befundbenennung ergänzen, BL-92-Auswertung danebenstellen. Erst nach der Bestimmung der Befundmenge die entsprechenden roxygen-/Rd-Texte ergänzen; Simulationscode und Betreiberdateien erhalten.
7. **Robustheitsausgabe:** Text/Formatierung in Print und Bericht anpassen und beide Fallgruppen prüfen; allgemeiner Bericht und AP1-Bericht sollen dieselben Zusätze verwenden.
8. **Regression und Handoff:** Gezielte neue Unit-Prüfungen, bisherige Leser-/Berichtsverträge und installierte Vignetten prüfen; NEWS, PROGRESS und REVIEW-INPUT mit echten Ausgaben vervollständigen. Orchestrator prüft Territorium, erstellt den Phasen-Commit und führt die Gates einschließlich aller Abnahmetests aus. QA erhält anschließend ihre eigene Phase; kein eigener Builder-Verdict.

## Risiken

| Risiko / Bezug | Vorgehen und Grenze |
| --- | --- |
| Große Rohdaten und wiederholte Fits; BL-13, BL-36, BL-46 | Früh messen, ClinVar blockweise verarbeiten, nur nötige Felder halten, je Vignette Ergebnisse innerhalb des Knit-Laufs wiederverwenden. Keine verkleinerte Pflichtstichprobe, `eval=FALSE` oder Timeout-/Gate-Lockerung. `ANK-TOL.sim_runtime` betrifft Klasse A; Rohdatenaufbereitung/Knit-Zeit gesondert berichten. |
| Mehrdeutige LLM-Ausgaben | Konservative, allgemeine Etikettenregel, NA und Zählung statt Lösungsschlüssel-gestützter Auswahl. Manuelle Annotationen der Quelle erklären Unterschiede zur publizierten Auswahltabelle; diese ist kein Antwort-Orakel. |
| ClinVar-Filter, gleiche Submitter, Genlisten, Locale | Filter vor Einreicherzählung, SCVs nicht deduplizieren, echte Join-Prüfung, numerische Sortierung der IDs, expliziter RNG und englische Datums-Locale; Prüfung über Multimenge und Bytegleichheit. |
| Nichtkonvergenz / Singularität der Pflichtfits | Diagnosen sichtbar halten; weder einen Fehler als Ergebnis ausgeben noch Aufgaben auslassen. Reproduzierbarer Fehler auf dem regulären M1d-Plan bleibt ein Kriteriumsproblem. Änderungen der Kernrechnung erforderten einen neuen freigegebenen Auftrag samt erneuerter Studienbasis, nicht einen stillen M1d-Fix. |
| Befundbericht verändert Studienhashes; ADR-043 | Neue reine Leser außerhalb der Generator-/Hashdateien. Bestehende `boot_`-/`sim_`-Hilfsfunktionen und Voll-/Kurzlaufdateien unangetastet lassen. |
| Locale-abhängiger Bootstrap-Hash; BL-115 | Studien-/Gate-Läufe in C.UTF-8 wie beim Betreiber; für Daten-Bytereproduktion nur LC_COLLATE=C setzen, nicht LC_ALL=C auf den Studienlauf übertragen. Hash-Neuentwurf nach dem 26.11. |
| Ergebnisleser-Regressionsvertrag, BL-94/BL-110 | Bisherige geänderte-Volllauf-Fixtures bleiben zulässig. Haupttabellen lesen die vorhandenen Ergebnisdateien; neue Sensitivität nennt ihr eigenes Replikat-n. Keine zusätzliche pauschale Integritätsprüfung in den bisherigen Lesern, die deren bestehenden Vertrag verschärft. K-M1d-6 bleibt die unabhängige Vollständigkeitsprüfung. |
| Fehlender pkgdown-Eintrag außerhalb des Builder-Territoriums | Konkreter Betreiber-Zusatz M1D-INFRA-01 vor BUILD. Der Builder schreibt weder `_pkgdown.yml` noch seine eigene Pfadfreigabe. |
| Große installierte Studienbasis; BL-114 | Dateien jetzt erhalten, weil K-M1d-6 sie verlangt. Bestehende Größen-NOTE dokumentieren; CRAN-Verpackung vor Release getrennt lösen, keine vorzeitige Entfernung. |
| Scheinbare neue Mutationsabnahme; ADR-047 | Ausschließlich den gelesenen M1c-Lauf als Beleg nennen; keine Tests abschwächen. Kontrolllauf nach done/M1d und Rückstellung vor M3a sind Betreiberaufgaben. |
| Sandbox-, Socket-, Zeit- oder Quellenfehler; BL-86/BL-103/BL-105 | Echte Ausgabe im Handoff, [INFRA] mit Ursache, keine Permissions-Umgehung und kein Produkt-Scheinfix. Keine Änderung von Gate-Regeln. |

### Behandlung sämtlicher BACKLOG-Einträge

„Umsetzen“ meint die folgende BUILD-Phase, „erhalten/prüfen“ die Regression eines vorhandenen Vertrags. Eine Vertagung benennt Grund, Zuständigkeit und nächsten Anlass. Geschlossene Einträge bleiben geschlossen; offene Restaufgaben werden nicht dadurch geschlossen, dass ihr ursprünglicher Teil behoben ist. Der Builder ändert `BACKLOG.md` in dieser Phase nicht.

| ID | Behandlung in M1d oder begründete Vertagung |
| --- | --- |
| BL-01 | M1d auf die acht Kriterien begrenzen. Betreiber entscheidet nach M1d über M3a–M3d anhand Frist 26.11. und AP1-Fortschritt; keine M3-Vorarbeit in diesen BUILD ziehen. |
| BL-02 | Neuheitsabgrenzung an AP1-/Paper-Arbeit nach M1d vertagen; M1d liefert Validierung, keine unbelegte Prioritätsbehauptung. Zuständig Betreiber/Autoren. |
| BL-03 | K-M1d-7 umsetzen: Bias und MCSE von β̂²/2 in beiden Vollauf-Szenarien berichten und qualitativ einordnen; keine neue Zwei-Stufen-Methode ohne Studienbeleg. |
| BL-04 | K-M1d-7 umsetzen: tatsächliche Überdeckungen sämtlicher Schätzziele berichten, insbesondere ndc-Befunde; vermutete Unterdeckung nicht als feststehendes Ergebnis übernehmen. Keine Anpassung für „grüne“ Forschungsergebnisse. |
| BL-05 | Präzision und Richtigkeit in den Vignetten auseinanderhalten. AP1-Vorbehalt und Auswertung nach `prior_differs` bei der finalen Betreiber-Auswertung nach M1d erhalten; keine Änderung des AP1-Datensatzes. |
| BL-06 | Modellumleitungsprüfung bleibt Betreiber-/Harness-Arbeit an den tatsächlichen Logs, außerhalb dieses offline arbeitenden M1d. Keine Modellzugangs- oder Sandbox-Änderung. |
| BL-07 | Bestehende M2-Routingverträge per Regression erhalten. Anbieter-/Quantisierungsbeobachtung bei AP1 bleibt Betreiberaufgabe; keine neuen API-Läufe oder Fallbacks in M1d. |
| BL-08 | Auf AP7 vertagen: Partnerdaten fehlen im M1d-Scope; Betreiber klärt Vereinbarungen vor deren Erhebung. |
| BL-09 | Jetzt berücksichtigen: nur erlaubte öffentliche Teilmengen und kurze verankerte Literaturbelege, keine Bücher/PDFs/INSAID-TSVs. Reviewer prüft seine Anker. |
| BL-10 | Betreiber/Autoren behalten Go/No-Go am 15.11. und Einreichungsziel 19.11.; M1d liefert vorher die Abnahmegrundlage, entscheidet aber nicht über Publikation oder DOI. |
| BL-11 | Kostenmessung/-projektion bleibt Betreiberaufgabe anhand Dashboard/Logs vor M3-Entscheidung. M1d führt dafür keine API- oder Geheimniszugriffe ein. |
| BL-12 | Laut Betreiber am 04.11. erledigt; Dateien vorhanden. M1d prüft K-M1d-6 an diesen Dateien und rechnet keinen zusätzlichen vollständigen Lauf. |
| BL-13 | Laufzeiten von Datenerzeugung, Vignetten und Kurzlaufprüfungen erfassen. Bei Infrastrukturgrenze benannten Befund liefern; Timeout und Klasse-A-Grenze nicht ändern. |
| BL-14 | Vorhandene unabhängige M1a–M1c-Kernbelege und Regression erhalten; M1d ergänzt reale Daten und Vollaufbefunde. Mutationsbeleg ausschließlich nach ADR-047. |
| BL-15 | Fleiss-Dokumentation/Implementierung auf M3a, K-M3a-2, vertagen; kein Fleiss-Versprechen in den M1d-Vignetten. |
| BL-16 | Erledigt; M2-Backend-/Provenienzvertrag unverändert erhalten. |
| BL-17 | Auf M3d/AP2 vertagen: ellmer-Aufzeichnungen und Live-Validierung gehören nicht zur Offline-Datenvalidierung. Betreiber liefert Aufzeichnungen. |
| BL-18 | SHA-256-Umstellung der allgemeinen Datenhash-API bleibt K-M3d-5; Bootstrap-Diagnosewortlaut aus M1c erhalten. Neue M1d-Manifeste verwenden bereits SHA-256 gemäß K-M1d-1/-3. |
| BL-19 | Erledigt; bestehendes pkgdown-Ziel erhalten. Neue Artikelregistrierung separat über M1D-INFRA-01. |
| BL-20 | Bestehende Trennung von wine-Installationsprüfung und Engine-Gleichheit in `validation.Rmd` erhalten; keine feste-Kovariaten-API hinzufügen. |
| BL-21 | NIST-Schachtelungsfall bleibt Reviewer-Ankerkandidat ohne M1d-Kriterium; fachliche Zuordnung später im passenden Statistikauftrag. |
| BL-22 | Vorhandene AIAG-Vergleichsrechnung ohne Wechselwirkung und deren Erläuterung erhalten; M1d ändert keine Komponentenrechnung. |
| BL-23 | Bestehende NIST-LRE-/Präzisionsbefunde erhalten; höhere Schwierigkeit weiter diagnostisch, nicht neues M1d-Akzeptanzkriterium. |
| BL-24 | Betreiber setzt vor M3a Scope/Baseline gemäß dann geltendem Auftrag zurück; zusätzlich ADR-047 Nr. 4 beachten. Builder ändert keine Zustandsdatei. |
| BL-25 | Jetzt berücksichtigen: Builder-ADR für neue Golden-Daten; Reviewer-ADR für seine M1d-Auslegungen/Anker. Keine eigenmächtige Ankeränderung. |
| BL-26 | Erledigt; vorhandene API-Fixtures erhalten, keine neuen Aufzeichnungen in M1d. |
| BL-27 | Erledigt; freigegebenen AP1-Plan und dessen Bänder bei K-M1d-8 unverändert lassen. |
| BL-28 | Konten, Limits und Schlüssel bleiben Betreiberangelegenheit der AP1-Erhebung; keine Schlüsselzugriffe in M1d. |
| BL-29 | Betreiber verfolgt Infevers-Anfrage separat; bis zur Klärung keine INSAID-Klasse je Variante veröffentlichen. M1d nutzt ClinVar-Einreichungen und aggregierte Literaturwerte. |
| BL-30 | Pages-/Zenodo-/Release-Einrichtung an Betreiber/AP2 vertagen; M1d liefert Paketartikel, führt aber weder Veröffentlichung noch Git-Aktion aus. |
| BL-31 | Betreiber-Gitidentität bleibt außerhalb des Builder-Auftrags. Keine eigene Prüfung oder Änderung per Git. |
| BL-32 | Erledigt; Harness-Dateimodi, `tests/testthat.R` und Harness-Buildignore unverändert. |
| BL-33 | Vertrauens-/Sandbox-Konfiguration bleibt Betreiber-Preflight; M1d benötigt keinen neuen Modellzugang und keine Freigabeumgehung. |
| BL-34 | Erreichbarkeit bleibt Betreiberaufgabe vor einer echten Eskalation. Einziger Human-Touchpoint bleibt der orchestrierte Eskalationspfad; kein eigener Kontaktkanal. |
| BL-35 | Benachrichtigungskorrektur an Betreiber/Template-Wartung vertagen; hat keinen Bezug zu K-M1d-1 bis -8. |
| BL-36 | M1d reduziert I/O durch begrenzte ClinVar-Durchgänge und temporäre Arbeitsdaten außerhalb des Repos; eine Workspace-Verlagerung bleibt Betreiberentscheidung bei gemessener Notwendigkeit. |
| BL-37 | Kostenspur im Harness an Betreiber/Template vertagen; keine Instrumentierung im Produkt. Verbindung zu BL-11 bei M3-Budgetentscheidung erhalten. |
| BL-38 | Bereits im Template behoben; Hinweis für historische Logs erhalten, keine M1d-Änderung. |
| BL-39 | Beschaffung geschützter Normen bleibt Betreiber/AP7; sie werden für die vorliegenden acht M1d-Kriterien nicht benötigt. |
| BL-40 | Jetzt ANK-42 bis ANK-46 verwenden und Unterschiede der Studien erklären. Weitere Literaturkandidaten ohne M1d-Kriterium bleiben bei Reviewer/Autoren; keine Werte aus Modellgedächtnis ergänzen. |
| BL-41 | Landis-/Koch-Bandnamen in den neuen Vignetten nicht verwenden. Quellenbeschaffung erst bei einer späteren fachlich verlangten Kappa-Einordnung, durch Reviewer/Betreiber. |
| BL-42 | Vorhandene geschützte Datenblätter für die Regression lesend voraussetzen; fehlende Datei als [INFRA] melden. Beschaffung/Abgleich und künftige M3-Daten bleiben Betreiber/Reviewer. |
| BL-43 | Live-Modellkennungen, Anbieter-Slugs und Preise bleiben AP1-Betreiberprüfung zum Erhebungszeitpunkt; offline eingefrorene M1d-Modelle sind davon unabhängig. |
| BL-44 | Fleiss-Varianzprüfung auf K-M3a-2 vertagen; keine Fleiss-Implementierung in M1d. |
| BL-45 | Synchronisierung externer Claude-/Harness-Projektdokumente durch Betreiber nach M1d; keine Änderungen außerhalb der Repo-Rollenterritorien. |
| BL-46 | Jetzt alle vier Vignetten im Paketbau messen und prüfen; Berechnungen ohne Netzwerk, keine Auslagerung von Pflichtrechnungen in abgetippte Tabellen. |
| BL-47 | VariantBench bleibt außerhalb des Projekts; neue Vignetten führen diese Quelle nicht beiläufig als genutzten Datensatz an. Autoren-/Zitatkorrektur nur bei späterer tatsächlicher Verwendung. |
| BL-48 | Dieser PLAN und REVIEW-INPUT ordnen alle acht Kriterien zu. Maschinelle Gate-Zuordnung bleibt Betreiber/Template; die dokumentarische M1c-Korrektur ist bereits erfolgt. |
| BL-49 | Bestehende verankerte REML-Toleranzen und Komponentenbezüge erhalten; keine neue Toleranz oder Optimierereinstellung zum Erreichen des M1d-Status. |
| BL-50 | CV-Näherungsprüfung auf M3c, K-M3c-6, vertagen; nicht Teil der M1d-Daten-/Befunddarstellung. |
| BL-51 | `acmg_*` bleibt intern. Exportentscheidung nach AP1 mit ADR; keine öffentliche Schnittstellenänderung in M1d. |
| BL-52 | Betreiber wiederholt die finale AP1-Auswertung nach M1d-Abnahme mit dem abgenommenen Kern; frühere Zahlen bleiben vorläufig. M1d selbst erhebt keine neuen API-Daten. |
| BL-53 | Erledigt; bestehende Abnahme des M0-Tag-Vertrags bleibt unangetastet und läuft im Orchestrator. |
| BL-54 | Erledigt; dieselbe Dokumentationsdisziplin anwenden: M1c-Abnahme nachtragen und M1d-BUILD nicht als M1d-Abnahme ausgeben. |
| BL-55 | Territorien auch für ignorierte Dateien beachten. Betreiberdateien vor Beginn BUILD bereitstellen; kein Erzeugen/Ändern fremder Dateien und kein Eingriff zwischen BUILD und GATES. |
| BL-56 | Erledigt; Gate führt bestehende NOT_CRAN-Tests aus. Neue gezielte Prüfläufe protokollieren ihre Umgebung. |
| BL-57 | API-Snapshot-Testhärtung bleibt Reviewer-Aufgabe beim nächsten API-Auftrag; M1d fügt keine Argumente/Exporte hinzu und umgeht den bestehenden Test nicht. |
| BL-58 | Erledigt; M1d verwendet die vorhandenen Quellen-/Ankerbelege, keine unbelegte Aktualisierung. |
| BL-59 | Erledigt; modellbezogene Memorisierungsvorbehalte bei der späteren AP1-Auswertung erhalten. |
| BL-60 | ellmer-/httr2-Mocking auf K-M3d-3 vertagen; Betreiber-Fixtures und Reviewer-Vertrag erforderlich, kein M1d-Netzzugriff. |
| BL-61 | Erledigt; bestehende Backend-Finish-/Reasoning-Regression erhalten. |
| BL-62 | Erledigt; M1d macht keine zusätzlichen Aussagen über Live-Modellidentität. |
| BL-63 | Erledigt; Logging-/Provider-Verträge der AP1-Erhebung bleiben unverändert. |
| BL-64 | Pilotregel-/Quantil-Kopplung auf den nächsten AP1-/M3d-Auftrag vertagen: bestehend nonblocking und ohne Bezug zu den eingefrorenen M1d-Studien. |
| BL-65 | Erledigt; bestehende Routing-Provenienzausgabe in der Berichtsregression erhalten. |
| BL-66 | Erledigt; bestehende Pilot-Fehlerdiagnose erhalten. |
| BL-67 | Erledigt; bestehende Herkunftsprüfung des API-Stores erhalten. |
| BL-68 | Meldung `store unchanged` vor weiterer AP1-CLI-Überarbeitung durch Builder im dafür freigegebenen Auftrag korrigieren; keine `R/acmg.R`-Änderung für die M1d-Ausgabeaufgabe. |
| BL-69 | Erledigt; bestehende Reasoning-Fixture-Auswertung erhalten. |
| BL-70 | Status-/Timeout-/Templatedefekte an Betreiber/Template-Wartung vertagen; nicht durch Produktcode kompensieren. |
| BL-71 | Versions-/Memorisierungszuordnung vor finaler AP1-Interpretation durch Betreiber/Autoren klären. Die M1d-ClinVar-Vignette beschreibt ihren Querschnitt und leitet daraus keine historische Modellkenntnis ab. |
| BL-72 | Bereits behobene Plattformregeln erhalten; neue Tests verwenden plattformunabhängige Pfade, Datums-/Locale-Regeln und dokumentierte numerische Toleranzen. CI bleibt Release-Bedingung. |
| BL-73 | Kosten-/Reasoning-Spaltenerläuterung und Sol-Nachrechnung in der finalen AP1-Berichterstattung vor Publikation bearbeiten; keine API-Kostenanalyse im M1d-Scope. |
| BL-74 | AP1-Latenz-/Zeitbudget bleibt Betreiberplanung der Erhebung; M1d misst davon getrennt lokale Daten-/Knit-Laufzeiten. |
| BL-75 | Netzpausenbereinigte API-Latenz auf finalen AP1-Bericht vertagen; kein Änderungsauslöser für die Offline-M1d-Pipeline. |
| BL-76 | Erledigt; vorhandene Fehler-/NEWS-Dokumentation erhalten und neue M1d-Änderungen ergänzen. |
| BL-77 | Historische QA-Zitatkorrektur bleibt QA/Betreiber. Dieser PLAN trennt wörtliche Spec-Zitate, Interpretation und tatsächlich ausgeführte Belege. |
| BL-78 | Erledigt; keine erneute Mutation-Infrastrukturinitialisierung in M1d. |
| BL-79 | Archivierung von Mutationsberichten bleibt Betreiber/Template; M1c-Beleg referenzieren, nach ADR-047 keinen neuen Bericht vortäuschen. |
| BL-80 | Zahlenfehler in der NIST-Spec durch Betreiber im passenden Spec-Auftrag korrigieren; M1d erhält die ankerbasierte bestehende Rechnung und ändert die Spec nicht. |
| BL-81 | Vorhandene Eingabe-/Gruppenprüfungen aus M1b in der Regression erhalten; fehlende Datenzählung in neuen Vignetten sichtbar machen. Keine neue Kernänderung ohne reproduzierbaren M1d-Kriteriumsfehler. |
| BL-82 | Erledigt; Reihenfolge/Subset-Vertrag und vorhandene Regression erhalten. |
| BL-83 | Erledigt; Gewichts-/Offset-Durchreichvertrag erhalten. |
| BL-84 | Optionale Mutanten-Testhärtung auf nächsten Kernauftrag nach 26.11. gemäß ADR-035 vertagen; keine entsprechende Rechenänderung in M1d, bestehende Tests bleiben vollständig. |
| BL-85 | Bindung der Mutantenfreigaben an tatsächliche Quellen/Positionen bleibt Reviewer-/Betreiberaufgabe. Keine M1c-Freigabe als neue M1d-Freigabe abschreiben; ADR-047 beschreibt die Belegübernahme explizit. |
| BL-86 | Sandbox-/Socket-/Clock-Befunde als [INFRA] mit tatsächlichem Output melden. Offizielle Tests laufen im Orchestrator; keine Umgehungsflags oder stillen Skips. |
| BL-87 | Algorithmisches Abbruchkriterium und zusätzliche numerische Robustheitsszenarien auf nächsten Kernauftrag nach 26.11. vertagen. Begründung: explizites roxygen-only-Gebot in docs/02 M1d; K-M1d-2 verlangt binäre, keine numerischen Fits. Bereits dokumentierte Grenzen erhalten. Ein Fehler eines geforderten realen binären Fits bleibt trotzdem blocking mit K-M1d-2 als ref. |
| BL-88 | Erledigt; dokumentierte Präzisions-/Fehlergrenzen erhalten. |
| BL-89 | Laut ADR-039 am 02.11. erledigt; bestehende plattformtolerante Reproduktionstests unverändert behalten. |
| BL-90 | Erledigt; Abnahme-Rückfallvertrag von M2 erhalten, keine Wiederholung seiner früheren Warnungsfehlklassifikation in den Vignetten. |
| BL-91 | Engere Aussage zu latenter Permutationsinvarianz/Toleranz bleibt Reviewer-Ankerentscheidung mit ADR. M1d verwendet Vorgabe-Engines und vorhandene Anker, passt weder Optimierer noch Toleranz an. Neue Reproduktionsabweichungen konkret melden. |
| BL-92 | Jetzt umsetzen: Vollauf-Replikate mit und ohne nicht konvergierte Fits gegenüberstellen, eigenes n und MCSE ausweisen, Hauptauswertung unverändert. Keine Simulation neu rechnen oder Konvergenz umetikettieren. |
| BL-93 | Deprecation-Warnungen der Reviewer-Abnahmehelfer bleiben Reviewer-Aufgabe; Builder ändert weder deren Aufrufe noch Imports zur Unterdrückung. |
| BL-94 | Erledigt; den gültigen geänderte-Volllauf-Testvertrag erhalten, nicht durch neue Kopplung an Session-/Replikatmetadaten erneut brechen. |
| BL-95 | Erledigt; Tests laden keine löschbare Paketkopie dauerhaft in denselben Namespace. Installierte Vignetten-/Berichtsprüfungen in getrennten Prozessen. |
| BL-96 | Erledigt; entsprechende latente Regressionstests erhalten. |
| BL-97 | Erledigt; NEWS-Konvention fortführen. |
| BL-98 | Erledigt; informative Identifizierbarkeitsmeldungen erhalten. |
| BL-99 | Erledigt; bestehende latente Prüfcode-Tests erhalten, keine neue Äquivalenzannahme. |
| BL-100 | Numerische Identifizierbarkeit im Durchreichweg auf Kernauftrag nach 26.11. gemäß ADR-035 vertagen; kein M1d-Argument für Eingriff in `R/fit.R`. Bekannte Grenze nicht als umfassend gelöst darstellen. |
| BL-101 | Termauswahl bei Nullgewichten auf Kernauftrag nach 26.11. gemäß ADR-035 vertagen; M1d-Pflichtfits verwenden keine künstlichen Nullgewichte. |
| BL-102 | Weitere latente Mutantenhärtung auf Auftrag nach 26.11. gemäß ADR-035 vertagen; keine Tests abschwächen und keinen M1d-Mutationsscore aus unpassenden alten Freigaben berechnen. |
| BL-103 | Projektkorrektur nach ADR-039 respektieren; verbleibende Rollback-/Template-Auditaufgabe beim Betreiber. Vorhandene geschützte Dateien nur lesen und niemals neu anlegen, löschen oder in eigene Manifeste außerhalb des Territoriums aufnehmen. |
| BL-104 | Im Projekt seit 02.11. erledigt (`max_fails = Inf`); Template-Übernahme bleibt Betreiber. Geplante direkte Tests protokollieren vollständige Fehler, keine Abbruchgrenze zum Verbergen späterer Befunde. |
| BL-105 | Fehlende Quellen/Infra-Ursachen konkret benennen; Retry-/Rundenlogik bleibt Betreiber/Template. Keine nutzlosen Produktänderungen zur Behandlung fremder Gate-Fehler. |
| BL-106 | Keine Zwischen-Commits/-Eingriffe durch den Builder. Betreiber-Zuarbeit vor BUILD, Phasen-Commit und Audit-Basis allein durch Orchestrator; allgemeine Auditverbesserung im Template vertagen. |
| BL-107 | Historische M1b-Ausnahme nicht fortschreiben. Für M1d gilt ausdrücklich ADR-047; Kontrolllauf nach done/M1d und Scope-Rückstellung vor M3a beim Betreiber. Allgemeine Cache-/Scope-Diagnostik bleibt Template-Arbeit. |
| BL-108 | Optimierer-Abbruch bei hoher numerischer Wiederholbarkeit nach 26.11. im Kernauftrag behandeln; roxygen-only-Gebot und vorhandene Präzisionsdokumentation bleiben maßgeblich. |
| BL-109 | Erledigten latenten Restvarianz-Hinweis in Print/Bericht erhalten und in neuen Vignetten erklären. Offene AP1-Sensitivität mit `interactions = TRUE` bei finaler Betreiber-Auswertung nach M1d, keine Umdefinition der hier geforderten Vorgabefits. |
| BL-110 | Zusätzliche Härtung manipulierten Bootstrap-CSV-Inhalts nach 26.11. gemäß ADR-035/ADR-042/ADR-043; bestehende Leser unverändert, dadurch keine Invalidierung der Studienhashes oder alten Abnahmeverträge. |
| BL-111 | Erledigt; aktuelle Spec nennt `R/grr.R`. Genau diese Datei unterliegt ACC-12, keine neue `R/boot.R`. |
| BL-112 | Jetzt vollständig über K-M1d-8/ADR-045 umsetzen und für Print sowie Bericht prüfen. |
| BL-113 | Auf M3a beziehungsweise nach 26.11. vertagen; M1d zeigt Alpha ohne Modalwertreduktion und kein Kappa. Unterschiedliche AP1-Kappa-Nenner bleiben bei finaler AP1-Interpretation ausdrücklich zu beachten. |
| BL-114 | CRAN-Verpackung vor Release durch Betreiber lösen: volle Replikate/Sessions gegebenenfalls im Quellrepo/Archiv behalten und nur aus CRAN-Tarball ausschließen. In M1d bleiben sämtliche zwölf Pflichtdateien erhalten. |
| BL-115 | Jetzt C.UTF-8 für Studien-/Gate-Reproduktion sichern; robusterer Hash ohne Locale-abhängige Texte erst nach 26.11., da Änderung neue Studienprovenienz auslösen würde. |
| BL-116 | Laut Betreiber am 04.11. auf allen drei CI-Systemen erledigt; keine leere Umgebungsvariable als plattformübergreifend vorhandenen Testwert einführen. Neue Tests müssen Windows-Verhalten berücksichtigen. |

## Testplan

Alle folgenden Produkt-/Abnahmeprüfungen sind **geplant, in dieser PLAN-Session nicht ausgeführt**. Der Builder dokumentiert in BUILD nur tatsächlich ausgeführte Befehle mit Output, Laufzeit und Grenzen. Für Git verwendende Abnahme-/Gate-Pfade ist der Orchestrator zuständig; insbesondere lesen K-M1d-7/ACC-12 und K-M1d-8 den Ausgangsstand über Git, und `r-check.sh` exportiert versionierte Dateien mit Git. Der Builder startet diese Pfade nicht selbst und ersetzt ihre Helfer nicht durch Testattrappen.

### Gezielte BUILD-Prüfungen ohne Git

1. Neue reine Helfer mit kleinen ausdrücklich synthetischen Fixtures prüfen: eindeutige/mehrdeutige/leere Antwortetiketten, keine Antwortwahl über `gt`, NA versus FALSE; Filter-vor-Einreicherzahl, doppelte SCVs, Genlisten und fehlender Join, numerische ID-Sortierung, Datums-Locale; konsistente Auswahl unter permutierten Eingaben. Erwartete Werte folgen direkt aus den kleinen Fällen, nicht aus gespeicherten Paketausgaben.
2. Beide `Rscript data-raw/...`-Befehle wirklich ausführen; in temporärer Kopie mit denselben Rohdaten und LC_COLLATE=C wiederholen. Die komprimierten CSVs und Manifeste vergleichen. Fehlerfall ohne `quellen`: benannter Abbruch und vor/nach identische Zieldateien. Keine Schreiboperation auf geschützte Rohdaten.
3. Ankerkopien byteweise und Manifest-SHA-256 prüfen. CSV-Schema/Schlüssel, tatsächliche Auswahl und Zählungen aus Rohdaten unabhängig gegenprüfen. Größen aus ANK-TOL, Lizenz-/Quellenfelder und keine INSAID-Klassifikationen überprüfen.
4. Neue Befundhelfer mit kleinen berechenbaren Tabellen prüfen: positive/negative Verzerrung, exakte Schwelle, relative versus MCSE-Schwelle, MCSE null, alle Schätzziele und getrennte Konvergenzgruppen. Für Bias/EmpSE/MCSE eine unabhängige kleine Handrechnung als zweiter Beleg; keine nachgebaute Implementierungsfunktion als Orakel.
5. Zwei neue Vignetten und `validation.Rmd` aus einem temporär installierten Paket offline rendern, Tabellen und Diagnosehinweise prüfen. Ankerwerte werden zur Laufzeit gelesen, kein Ergebnisliteral und kein versteckter Zugriff auf `../quellen` beim Knit. Bestehende M1b-/M1c-Ergebnisleserprüfungen gegen vollständige, kurze und geänderte Ergebnisdateien erhalten.
6. Robustheits-Print und Bericht auf Fällen ohne aktive Faktoren sowie mit ME-only/SME-Faktoren prüfen: Wortlaut, vier Nachkommastellen, Faktor-Zuordnung, unveränderte Rückgabe. Vorhandene Berichts-/AP1-Unit-Verträge ausführen, soweit der ausgewählte Testpfad keine Git-Kommandos ausführt. Keine neue Testschicht allein zum Spiegeln der einfachen Textformatierung.

Beispiel für die gezielten neuen Unit-Dateien nach ihrer Implementierung, aus der Paketwurzel:

```sh
Rscript -e 'Sys.setenv(NOT_CRAN="true"); options(testthat.progress.max_fails=Inf); testthat::test_dir("tests/testthat", filter="m1d-(data|findings)", load_package="source", stop_on_failure=TRUE)'
```

### Unveränderte deterministische Abnahme und Gates des Orchestrators

| Kriterium | Abnahmedatei / unabhängiger Nachweis | Erwartete Entscheidung |
| --- | --- | --- |
| K-M1d-1 | `test-m1d-1-llm-stability-data.R`: ANK-40, Rohdaten-/Schlüssel-/Etikettenprüfung, Skriptneulauf, Manifest und Import/Counts. | Struktur und bytegleiche Reproduktion stimmen; fehlende Quelle schlägt benannt fehl. |
| K-M1d-2 | `test-m1d-2-llm-stability-vignette.R`: eigene Kennzahlen/Fits gegen gestrickte Tabellen; lint baut Vignette. | Jede Aufgabe/jedes Modell erscheint mit berechneten Kennzahlen; keine abgetippten Ergebnisse, kein ERROR/WARNING beim Bau. |
| K-M1d-3 | `test-m1d-3-clinvar-data.R`: unabhängige Rohdaten-Mini-Referenz, Multimengenvergleich, verankerter Seed und Skriptneulauf. | Beide Teilmengen entsprechen der Filter-/Ziehregel, inklusive Mehrfach-SCVs und Ausschlusszählungen. |
| K-M1d-4 | `test-m1d-4-clinvar-vignette.R`: unabhängige Alpha-Nachrechnung, eigene Fits, Kriterienfilter und vollständiger Ankervergleich. | Beide Subsets und Sensitivitäten vollständig, Nenner korrekt, Literaturvergleich als solcher bezeichnet. |
| K-M1d-5 | `test-m1d-5-size-licence-network.R`, lint; Betreiber liefert Articles vor BUILD. | Grenzen, Herkunft, Lizenzen, INSAID-/Netzfreiheit, Navigation und Bau erfüllt. |
| K-M1d-6 | `test-m1d-6-full-runs.R`: Vollständigkeit, Kennzahlen aus Replikaten, echter Kurz-Neulauf und Sessionprüfung. | Alle vier Tripel und alle geforderten Szenarien vorhanden; Präfixvergleich tatsächlich grün, kein Skip. |
| K-M1d-7 | `test-m1d-7-findings.R`: Wert/MCSE-Tabellen, dynamisch bestimmte Befundmenge, Rd-Text, Literalprüfung und ACC-12 gegen done/M1c. | Jede erforderliche Richtung/Szenario-ID dokumentiert; Kernzeilen unverändert. |
| K-M1d-8 | `test-m1d-8-robustness-wording.R`: Print/gerenderter Bericht, Altphrase-Suche, identische Baseline-Objekte und alle AP1-Bänder. | Neuer exakter Wortlaut bei gleicher Rechnung und gleichen Bändern. |

Der reguläre Tests-Befehl des Orchestrators bleibt:

```sh
Rscript orchestrator/lib/r-tests.R tests/testthat tests/acceptance tests/simulation tests/e2e tests/fuzz
```

Er umfasst die vorherigen Meilensteine, API-Snapshot, Klasse-A-Simulationen und die getrennt von QA gelieferten E2E-/Fuzz-Tests. Keine neuen QA-Dateien durch den Builder. Abhängigkeiten installiert das deps-Gate; keine Downloads aus der Builder-Sandbox. lint führt unverändert `R CMD build` und `R CMD check --as-cran --no-manual` mit den bestehenden Offline-Einstellungen aus; alle vier Vignetten müssen gebaut werden. ERROR/WARNING bleiben Fehler; die bekannte installierte Größe aus BL-114 darf nicht als neue grüne Vollprüfung umgedeutet werden.

Zusätzlich entscheiden trace, territory und golden-adr unverändert. mutgate folgt dem bereits beschlossenen ADR-047: kein eigener M1d-Lauf, M1c-Beleg nur unter dessen Bedingungen. Der Betreiber führt nach done/M1d den dort verlangten Kontrolllauf in separater Kopie aus und klärt einen Score unter 92,09 vor Release; vor M3a stellt er den Scope zurück. Der Builder verändert keine Gate-Auswahl, keine Baseline und keine Äquivalenzfreigabe.

Die PLAN-Datei selbst wurde mit `python3` (`pathlib`, `re`, `json`) gegen die sechs Schemaabschnitte sowie die IDs aus `CRITERIA.json` und `BACKLOG.md` geprüft. Tatsächlicher Output der Dokumentprüfung:

```text
PLAN schema: 6/6 required sections
Criterion coverage: 8/8
ACC coverage: 20/20
BACKLOG coverage: 116/116, one explicit row per ID
Markdown fences: balanced
```

Diese Prüfung belegt die formale Abdeckung des Plans, keine Produktabnahme. Produkt-, Abnahme- und Gate-Tests wurden in PLAN nicht ausgeführt.
