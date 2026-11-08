# PROGRESS — Langzeitgedächtnis des Builders

## M3c — BUILD, Runde 1 (08.11.2026)

Der freigegebene PLAN ist nach ADR-054 umgesetzt. Die vollständige lokale
M3c-Abnahme, Unit-Suite, QA-Fuzz-Suite und Klasse-A-Simulationssuite bestehen.
Der bekannte lokale Socketbefund M3d-BUILD-INFRA-01 begrenzt weiterhin einen
QA-E2E- und einen M3d-Metadaten-Abnahmeblock. Dieser Eintrag dokumentiert
ausgeführte Builder-Prüfungen; die Gate- und Abnahmeentscheidung steht aus.

### Grundlage und Änderungen

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, PROGRESS,
LESSONS, PLAN und PLAN-REVIEW (Runde 1, Reviewer-PASS), CRITERIA einschließlich
ACC-1 bis ACC-12, ADR-054, die M3c-Abnahmetests und Klasse-A-Studien samt
Helfern, docs/01, docs/04 M3c, docs/02 S-boot-1 und Formelsammlung §§2, 8, 9.
PLAN-UPDATE und ARBITER liegen für M3c nicht vor. Die LESSONS-Vorgabe zur
allgemeinen Ursachenbehebung ist berücksichtigt; kein Befund erforderte einen
Umbau des Fit-Kerns.

- `R/spc.R`: letztes Argument `r4s = c("range", "westgard")`, vektorisierte
  alternative Paarbedingung, einzelnes Lesartattribut und ausdrückliche
  Lesart in `print()`. Alte Karten ohne Attribut verwenden `range`;
  ungültige vorhandene Attribute lösen denselben benannten Fehler in Druck
  und Bericht aus. Die Hilfe erklärt strikte Grenzen, vollständige Fenster,
  Stichproben-SD und Westgards Anwendung innerhalb eines Kontrolllaufs.
- `R/plan.R`: vollständige Einzelreplikate aus genau den bestehenden Fits,
  neue Bias-/EmpSE-/MCSE-Spalten und Zusammenfassungen ausschließlich aus
  diesen Replikaten. Ein Prompt erhält `NA_real_`, mehrere Prompts erfordern
  eine gültige REML-Komponente. Alle singulären Fits und exakten Nullen
  bleiben enthalten. Ungültige `nsim`, fehlende Komponenten und nichtendliche
  Schätzer brechen benannt ab; Fit-Fehler propagieren. `nsim = 1` bleibt mit
  ausdrücklich typisierten NA-Streuungskennzahlen ausführbar. Die Hilfe und
  NEWS beschreiben diesen Vertrag; alte Planobjekte bleiben druckbar.
- `R/report.R` und Vorlage: eigener interner Parameter
  `control_chart_reading`; öffentliche Signatur und attributfreie
  Verletzungstabelle bleiben erhalten. Der bisherige Range-Satz bleibt
  wörtlich; der Westgard-Satz nennt aufeinanderfolgende standardisierte Werte
  und beide strikten Grenzen.
- `inst/validation/planning/`: echte Klasse-A-Dokumentationsdaten,
  vollständige Replikate, Quellen-/Ergebnismanifest, Sitzungsprotokoll und
  reiner Leser mit Hash-, Schema-, Schlüssel- und Arithmetikprüfung. Der
  getrennte Erzeuger unter `inst/validation/sim/planning_rule.R` verwendet
  genau einen gesetzten Seed und einen `msa_plan()`-Aufruf je Kandidat;
  standardmäßig sequentiell, optional unter Unix je ganzem Kandidaten parallel.
  Die Vignette lädt keine Simulation beim Knitten. Der öffentliche Leser
  vergleicht keine aktuellen Produktquellhashes als Ersatz für Fachprüfungen.
- `data-raw/make_validation_planning.R`: nur ANK-89 wird vollständig und
  bytegleich neu kopiert; ANK-06, ANK-16 und ANK-TOL werden über bestehende
  geprüfte Kopien wiederverwendet. Die Vignette erhält den Methodentext zu
  K-M3c-1 bis K-M3c-5 sowie die neunspaltige Planungstabelle und die getrennte
  ergänzende CV-MCSE-Tabelle. Keine Änderung vorhandener Klasse-B-Ergebnisse.
- Vier neue Unit-Dateien prüfen Regeln, Invarianzen, tatsächliche Druck- und
  Plot-Ausgaben, unabhängige Replikatnachrechnung, RNG und Fehlerpfade,
  Rendervertrag/HTML und Ressourcenbeschädigung. Die CV-MCSE-Nachrechnung
  verwendet unabhängig die Parametrisierung mit zentriertem zweitem Moment.
  `qcc` steht zusätzlich in Suggests; keine Imports oder Exporte hinzugefügt.
  Nur die drei betroffenen Hilfen wurden mit roxygen2 neu erzeugt.

Der angeforderte Builder-ADR ist
`docs/decisions/ADR-055-m3c-planungsressourcen.md`. Er dokumentiert die
Ressourcenablage, Delta-Methode und die ergänzende Druckkorrektur:
`rules = "R_4s"` ließ zuvor vorhandene Ablehnungen aus der gedruckten Tabelle
verschwinden, weil die nicht ausgewählte Warnungsspalte einen leeren Index
erzeugte. Das ist mit der Baseline reproduziert und allgemein korrigiert;
Regeln und Kennzahlen ändern sich dadurch nicht. Die Abweichungen gegenüber
dem ursprünglichen PLAN (NA statt Null bei einem Prompt, nur benutzte
Ankerkopien) folgen ausdrücklich ADR-054. Keine ungeklärte Vertragsfrage
wurde durch eine neue fachliche Annahme ersetzt.

### Antworten auf PLAN-REVIEW

| ID | Umsetzung und Beleg |
| --- | --- |
| E1 | `prompt = NA_real_` bei einer Prompt-Variante, REML-Schätzer sonst zwingend; Hilfe, reale Ein-Prompt-Fits und Fehlermocks in `test-plan.R`. |
| E2 | Gemeinsame Lesartprüfung für Druck und Bericht; alte Karten und ungültige Attributformen in Druck-, Renderparameter- und echten HTML-Tests. |
| E3 | Westgard-Bedingung mit vektorisiertem `&`/`\|`; bestehende Behandlung fehlender Nachbarn und `%in% TRUE` im Ablehnungsindikator; Unit-Fälle mit fehlenden Werten. |
| E4 | Ausschließlich ANK-89 neu kopiert; vollständige bestehende Kopien von ANK-06/16/TOL wiederverwendet und gehasht. Keine unbenutzte Kopie von ANK-86/87. |
| E5 | Methodentext zu Regeln, Fehlalarmen, Parvin, qcc-Linien und Simulator mit Anker-IDs und Testpfaden. Bestehende Numerik-/Latent-/Vignetten-Literalwachen bestehen. Historische Git-verwendende Prüfwege bleiben beim Orchestrator. |
| E6 | Ganze Ausgaben beider Druckmethoden, echte Plot-Displayliste, Replikatreplay mit identischem Ziehungsablauf, unabhängige Simulatorgleichung, alle vorgesehenen Eingabeteilbedingungen und exakte Fehler einschließlich `conditionCall()` geprüft. Neue Tests laufen in Sekunden. Kein eigener Mutationsscore, keine Exklusion oder Äquivalenzfreigabe. |
| E7 | Zahlen als `sprintf("%.17g")`, feste Lesetypen; Zusammenfassung aus gespeicherten Replikaten. Synthetischer Serialisierungstest bewahrt auch kleinste positive Doubles und trennt sie von null; echte Reproduktion unten. |
| E8 | Westgard-Berichtssatz gemäß ADR-054 Nr. 17; Hilfetext zu innerhalb desselben Laufs verglichenen Nachbarn. Range-Satz und Verletzungstabelle bleiben erhalten. |
| E9 | Positive ganze `nsim` früh geprüft und in NEWS benannt; Einzelsimulation weiterhin ausführbar. Ungültige Eingaben mit exakten Fehlermeldungen geprüft. |

### Umgebung und Testtreiber

Alle ausführenden Prüfungen liefen in Positivlisten-Kopien unter
`/tmp/llmsa-m3c-build-qg68yr8l/`: `baseline/`, `work/`, `docs-src/` und die
getrennten Paketcheck-Verzeichnisse `public/` und `full/`. Keine Git- oder
Schlüsseldateien wurden kopiert. Originalanker, geschützte Datenblätter und
Betreiberaufzeichnungen wurden ausschließlich gelesen. Die Ausgangsinventur
umfasst 461 Dateien.

Für die nachstehenden Befehle gilt die Pfadabkürzung:

```bash
M3C_BUILD_DIR=/tmp/llmsa-m3c-build-qg68yr8l
```

`run-suite.R` nimmt Paketverzeichnis, Testverzeichnis, Filter, Label und
Ergebnispräfix entgegen. Er setzt `REPO_ROOT` auf das Originalrepo,
`NOT_CRAN=true`, `TZ=Europe/Berlin` und die vorhandene Testoption
`llmsa.test.ap1_recordings` auf die Originalaufzeichnungen, öffnet `pdf(NULL)`
und setzt `testthat::set_max_fails(Inf)`. Ausgeführt wird unverändert
`testthat::test_dir(testdir, filter = filter, load_package = "source",
reporter = "summary", stop_on_failure = FALSE)`. Alle Ergebnisse werden
als RDS gespeichert; Fehler/negative Erwartungen bestimmen Exit 1. Kein
Abnahmehelfer und keine Erwartung wird dabei ersetzt.

Rein lesender Abhängigkeitscheck aus `work/` (Exit 0):

```bash
Rscript --vanilla /mnt/c/Users/Danie/dev/Llmsa/llmsa/orchestrator/lib/r-deps.R --check-only
```

```text
r-deps: pass — 32 Anforderungen erfüllt (R 4.6.1)
```

Verwendet wurden die installierten eingefrorenen Abhängigkeiten, darunter
lme4 2.0.6, Matrix 1.7.4, ordinal 2026.7.26, qcc 2.7, testthat 3.3.2,
jsonlite 2.0.0, digest 0.6.39, rmarkdown 2.32, knitr 1.52 und roxygen2 8.1.1.
Keine Abhängigkeit wurde installiert oder aktualisiert. Alle Studien
verwenden Mersenne-Twister/Inversion/Rejection und die vorgeschriebenen Seeds.

### Frühe Diagnosen und direkte Prüfungen

```bash
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/baseline" tests/acceptance '^m3c-' 'M3c baseline acceptance' "$M3C_BUILD_DIR/acceptance-before"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/acceptance '^m3c-(1|2|4|5|6-plan)' 'M3c deterministic acceptance' "$M3C_BUILD_DIR/acceptance-core"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/testthat '^(control-chart|plan|report-control-chart)$' 'M3c new core unit initial' "$M3C_BUILD_DIR/unit-core-initial"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/testthat '^(control-chart|plan|report-control-chart)$' 'M3c new core unit corrected' "$M3C_BUILD_DIR/unit-core-corrected"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/testthat '^validation-planning$' 'M3c planning-resource unit' "$M3C_BUILD_DIR/unit-planning"
```

Echte Schlusszeilen aus den gleichnamigen Logs; Exit-Codes 1, 0, 1, 0, 0:

```text
M3c baseline acceptance: 25 blocks; 19 failed expectations; 0 error blocks; 0 warnings; 0 skips; 323 passed expectations; elapsed 30.133 s
M3c deterministic acceptance: 22 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 477 passed expectations; elapsed 8.611 s
M3c new core unit initial: 22 blocks; 6 failed expectations; 0 error blocks; 0 warnings; 0 skips; 443 passed expectations; elapsed 4.878 s
M3c new core unit corrected: 22 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 451 passed expectations; elapsed 5.450 s
M3c planning-resource unit: 8 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 126 passed expectations; elapsed 1.991 s
```

Der erwartete Baseline-Fehlschlag belegt die zuvor fehlenden M3c-Verträge.
Der erste neue Core-Unit-Lauf scheiterte ausschließlich an sechs eigenen
HTML-Prüfungen, die `<th>` ohne die tatsächlich vorhandenen Ausrichtungsattribute
erwarteten. Die Spaltenprüfung akzeptiert jetzt diese gültigen Attribute und
prüft weiterhin die tatsächlichen Überschriften und den vollständigen Satz.
Keine bestehende Erwartung wurde geändert.

Roxygen lief in `docs-src/` mit folgendem Befehl (Exit 0):

```bash
Rscript --vanilla -e 'roxygen2::roxygenise("/tmp/llmsa-m3c-build-qg68yr8l/docs-src", roclets = "rd")'
```

Übernommen wurden nur
`msa_control_chart.Rd`, `msa_plan.Rd`, `msa_report.Rd`; die zusätzliche
Roxygen-Formatänderung der Paketübersichtsseite wurde nicht übernommen.
Syntaxprüfung (Exit 0): `10 changed or added R files parsed successfully.`

Der direkte ANK-02-Vergleich (`Rscript --vanilla
"$M3C_BUILD_DIR/check-api.R"`, Exit 0) und der Ausdrucksvergleich der
unveränderten Funktionen liefern:

```text
ANK-02: 22 exports and 108 original ordered arguments/defaults preserved; no new exports.
msa_control_chart: final argument r4s = c("range", "westgard"); msa_report signature preserved.
msa_simulate: identical parsed function before and after BUILD.
plot.msa_control_chart: identical parsed function before and after BUILD.
msa_report_control_chart: identical parsed function before and after BUILD.
```

### Echte Planungsdaten und Reproduktion

Offline-Vorbereitung aus dem Repository:

```bash
Rscript --vanilla data-raw/make_validation_planning.R
```

```text
Planning inputs: 1 byte-identical anchor; 3 existing anchor copies reused; SHA-256 provenance recorded.
```

Der erste Erzeugungslauf führte alle Fits aus, brach anschließend aber beim
Lesen der Zusammenfassung ab: Der CSV-Schreiber hatte numerische Zellen
ebenfalls zitiert. Relevanter Originaloutput (`planning-generation.log`,
Exit 1): `scan() expected 'a real', got '"46.442036401282401"'`.
Es wurden keine Ergebnisse dieses abgebrochenen Laufs publiziert. Die
Korrektur zitiert nur Textspalten und verwendet explizite Lesetypen.
Ein kleiner ausdrücklich synthetischer CSV-Test lieferte nach Korrektur:

```text
Synthetic CSV check: all summary columns and replicate values round-trip exactly with explicit reader types.
```

Danach wurden die echten Fits erneut gerechnet; kein Ergebnis wurde aus
Fixtures oder einem fehlgeschlagenen Lauf ergänzt. Erzeugung und unabhängige
sequentielle Wiederholung in getrennte Ausgabeziele:

```bash
env REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa TZ=Europe/Berlin Rscript --vanilla "$M3C_BUILD_DIR/work/inst/validation/sim/planning_rule.R" --out /mnt/c/Users/Danie/dev/Llmsa/llmsa/inst/validation/planning --workers 4 --package "$M3C_BUILD_DIR/work"
env REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa TZ=Europe/Berlin Rscript --vanilla "$M3C_BUILD_DIR/work/inst/validation/sim/planning_rule.R" --out "$M3C_BUILD_DIR/reproduction" --workers 1 --package "$M3C_BUILD_DIR/work"
```

Echter Output des korrigierten ersten Laufs (`planning-generation-corrected.log`):

```text
Planning S-plan-1: starting 1000 repetitions with seed 20261109.
Planning S-plan-2: starting 1000 repetitions with seed 20261110.
Planning S-plan-3: starting 1000 repetitions with seed 20261111.
Planning S-plan-4: starting 1000 repetitions with seed 20261112.
Planning S-plan-1: completed 1000 repetitions in 73.502 s.
Planning S-plan-2: completed 1000 repetitions in 89.685 s.
Planning S-plan-3: completed 1000 repetitions in 128.363 s.
Planning S-plan-4: completed 1000 repetitions in 180.467 s.
     plan items prompts nu cv_rule cv_empirical boundary_share mcse_boundary
 S-plan-1    20       3  2  1.0000       1.0722         0.0460        0.0066
 S-plan-2    20       5  4  0.7071       0.7436         0.0070        0.0026
 S-plan-3    40       3  2  1.0000       1.0334         0.0340        0.0057
 S-plan-4    40       5  4  0.7071       0.7513         0.0080        0.0028
 n_sim
  1000
  1000
  1000
  1000
     plan cv_empirical mcse_cv                                mcse_cv_method
 S-plan-1       1.0722  0.0435 Delta method: first two empirical raw moments
 S-plan-2       0.7436  0.0192 Delta method: first two empirical raw moments
 S-plan-3       1.0334  0.0279 Delta method: first two empirical raw moments
 S-plan-4       0.7513  0.0186 Delta method: first two empirical raw moments
                                                 mcse_cv_note
 approximate; all prompt estimates, including zeros, retained
 approximate; all prompt estimates, including zeros, retained
 approximate; all prompt estimates, including zeros, retained
 approximate; all prompt estimates, including zeros, retained
Planning generation: 4 plans; 4000 replicates; n_sim 1000 per plan; 180.477 s; RNG Mersenne-Twister/Inversion/Rejection.
```

Die sequentielle Wiederholung verwendet die abschließende Version des
Erzeugers einschließlich fester Replikat-Lesetypen. Ihre Sitzungs- und
Manifestdateien werden gemeinsam mit ihren wirklich neu erzeugten Ergebnissen
übernommen. Quellen-/Funktionshashes beschreiben diesen Lauf; es wird kein
Hash auf alte Daten umetikettiert. Die numerischen Dateien beider Läufe sind
bytegleich; Laufzeit und Sitzungsangaben werden ausdrücklich nicht gleichgesetzt.

```text
Planning S-plan-1: starting 1000 repetitions with seed 20261109.
Planning S-plan-1: completed 1000 repetitions in 85.805 s.
Planning S-plan-2: starting 1000 repetitions with seed 20261110.
Planning S-plan-2: completed 1000 repetitions in 103.720 s.
Planning S-plan-3: starting 1000 repetitions with seed 20261111.
Planning S-plan-3: completed 1000 repetitions in 149.128 s.
Planning S-plan-4: starting 1000 repetitions with seed 20261112.
Planning S-plan-4: completed 1000 repetitions in 176.430 s.
Planning generation: 4 plans; 4000 replicates; n_sim 1000 per plan; 515.084 s; RNG Mersenne-Twister/Inversion/Rejection.
summary.csv: byte-identical across 4-worker and 1-worker runs; SHA-256 ac4913aaf78336975931de642f155963efd8ebc2a921fd732528e0686e175af9; 2172 bytes.
replicates.csv.gz: byte-identical across 4-worker and 1-worker runs; SHA-256 398ac8d834efcb040cda0d8b396f0a912e668514ed2958ef611fe6fdf21306eb; 89871 bytes.
Final run provenance: all 17 recorded source hashes match the actual final source files.
Session records differ as expected: each run retains its actual worker count and elapsed times.
Published all files from the actual sequential regeneration; no historical hashes were relabelled.
```

Nach Übernahme dieses Laufprotokolls wurden die Ressourcenprüfungen erneut
ausgeführt (Exit 0):

```bash
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/testthat '^validation-planning$' 'Final planning-resource provenance' "$M3C_BUILD_DIR/unit-planning-final"
```

```text
Final planning-resource provenance: 8 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 126 passed expectations; elapsed 1.927 s
```

Die Vignette berichtet die Abweichung der vier empirischen CV von der Regel
beschreibend. Exakte Nullen und singuläre Fits bleiben erhalten. ACC-9 bleibt
beim Betreiber offen; die separat ausgewiesene Delta-MCSE-Näherung folgt
PLAN und ADR-054 Nr. 9 und erzeugt keine Bestehensschwelle.

### Vollständige lokale Tests und Klasse A

```bash
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/acceptance '^m3c-' 'M3c full acceptance' "$M3C_BUILD_DIR/acceptance-m3c"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/testthat . 'Full unit suite' "$M3C_BUILD_DIR/unit-full"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/e2e . 'Full QA E2E suite' "$M3C_BUILD_DIR/qa-e2e"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/fuzz . 'Full QA fuzz suite' "$M3C_BUILD_DIR/qa-fuzz"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/acceptance '^(m1a-|m1b-7-vignette|m1c-5-vignette|m3d-(4|5|6))' 'Numerical, vignette and report regression' "$M3C_BUILD_DIR/acceptance-regression"
Rscript --vanilla "$M3C_BUILD_DIR/run-suite.R" "$M3C_BUILD_DIR/work" tests/simulation . 'Full class A simulation suite' "$M3C_BUILD_DIR/simulations"
```

Echte Schlusszeilen; Exit-Codes 0, 0, 1, 0, 1, 0:

```text
M3c full acceptance: 25 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 528 passed expectations; elapsed 32.477 s
Full unit suite: 410 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 1 skips; 8065 passed expectations; elapsed 148.773 s
Full QA E2E suite: 28 blocks; 0 failed expectations; 1 error blocks; 0 warnings; 0 skips; 773 passed expectations; elapsed 45.748 s
Full QA fuzz suite: 15 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 1580 passed expectations; elapsed 10.553 s
Numerical, vignette and report regression: 92 blocks; 0 failed expectations; 1 error blocks; 0 warnings; 0 skips; 1905 passed expectations; elapsed 154.512 s
Full class A simulation suite: 6 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 257 passed expectations; elapsed 302.668 s
```

Der einzige Unit-Skip stammt unverändert aus `test-backends.R:32`: der
Negativfall „backend_ellmer needs ellmer“ wird bei installiertem ellmer
übersprungen. Kein M3c-Test wird übersprungen. Die M3d-HTML-/Markdown-Prüfung
QA-M3d-E2E-3 besteht einschließlich des unveränderten Range-Satzes.

Die Zeitmessung von 302,668 s umfasst die gesamte unveränderte
`tests/simulation/`-Suite, einschließlich Bias-Coverage und Lenth-H0.
Sie liegt unter ANK-TOL.sim_runtime (20 Minuten, 14 Kerne). Es liefen
gleichzeitig weitere lokale Prüfungen; keine Stichprobengröße, Workerzahl oder
Toleranz wurde dafür reduziert. Die Planungskandidaten wurden durch die
Reviewer-Studie mit frischen Fits geprüft; die gerenderte Tabelle stimmt.
Vollständiger fachlicher Output der M3c-Studien aus `simulations.log`:

```text
K-M3c-6 (tests/simulation/test-plan-satterthwaite.R, msa_plan, 217.3 s):
S-plan-1 (items 20, prompts 3, models 3, replicates 2, blocks 2): nu 2, rule 1.0000, empirical CV 1.0722, boundary share 0.0460 (MCSE 0.0066); n_sim 1000, seed 20261109, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
S-plan-2 (items 20, prompts 5, models 3, replicates 2, blocks 2): nu 4, rule 0.7071, empirical CV 0.7436, boundary share 0.0070 (MCSE 0.0026); n_sim 1000, seed 20261110, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
S-plan-3 (items 40, prompts 3, models 3, replicates 2, blocks 2): nu 2, rule 1.0000, empirical CV 1.0334, boundary share 0.0340 (MCSE 0.0057); n_sim 1000, seed 20261111, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
S-plan-4 (items 40, prompts 5, models 3, replicates 2, blocks 2): nu 4, rule 0.7071, empirical CV 0.7513, boundary share 0.0080 (MCSE 0.0028); n_sim 1000, seed 20261112, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
K-M3c-5 (tests/simulation/test-simulator-recovery.R, 17.1 s):
S-sim-1 (items 40, prompts 3, models 3, replicates 2, blocks 2), n_sim 1000, seeds 20261108 + s, seed 20261108, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
item          mean 1.002651 given 1      bias +0.002651 MCSE 0.007477 (+0.35 MCSE); estimates at 0: 0
prompt        mean 0.048579 given 0.05   bias -0.001421 MCSE 0.001608 (-0.88 MCSE); estimates at 0: 41
model         mean 0.050043 given 0.05   bias +0.000043 MCSE 0.001744 (+0.02 MCSE); estimates at 0: 49
block         mean 0.009371 given 0.01   bias -0.000629 MCSE 0.000428 (-1.47 MCSE); estimates at 0: 93
item:prompt   mean 0.010178 given 0.01   bias +0.000178 MCSE 0.000097 (+1.84 MCSE); estimates at 0: 0
item:model    mean 0.049645 given 0.05   bias -0.000355 MCSE 0.000297 (-1.20 MCSE); estimates at 0: 0
prompt:model  mean 0.005187 given 0.005  bias +0.000187 MCSE 0.000132 (+1.42 MCSE); estimates at 0: 24
Residual      mean 0.100067 given 0.1    bias +0.000067 MCSE 0.000128 (+0.52 MCSE); estimates at 0: 0
item variance of latent: mean 1.001603 expected 1 MCSE 0.007267 (+0.22 MCSE)
mean of latent: mean 0.005786 expected 0 MCSE 0.005101 (+1.13 MCSE)
mean of value - latent: mean 0.000172 expected 0 MCSE 0.006404 (+0.03 MCSE)
covariance of latent with the item means of value - latent: mean 0.000421 expected 0 MCSE 0.000777 (+0.54 MCSE)

K-M3c-3 (tests/simulation/test-westgard-false-alarm.R, firing per rule and position, 11.5 s):
range    1_2s  analytic 0.045500; share per position 0.045100 to 0.046300 (MCSE 0.000659)
range    1_3s  analytic 0.002700; share per position 0.002280 to 0.003050 (MCSE 0.000164)
range    2_2s  analytic 0.001035; share per position 0.000950 to 0.001250 (MCSE 0.000102)
range    R_4s  analytic 0.004678; share per position 0.004440 to 0.005280 (MCSE 0.000216)
range    4_1s  analytic 0.001267; share per position 0.001210 to 0.001400 (MCSE 0.000112)
range    10_x  analytic 0.001953; share per position 0.001860 to 0.001930 (MCSE 0.000140)
range    largest deviation R_4s at position 12: +2.79 MCSE; n_sim 100000 series of 12 values, seed 20261208, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
westgard 1_2s  analytic 0.045500; share per position 0.043940 to 0.046660 (MCSE 0.000659)
westgard 1_3s  analytic 0.002700; share per position 0.002240 to 0.002940 (MCSE 0.000164)
westgard 2_2s  analytic 0.001035; share per position 0.000800 to 0.001270 (MCSE 0.000102)
westgard R_4s  analytic 0.001035; share per position 0.000880 to 0.001290 (MCSE 0.000102)
westgard 4_1s  analytic 0.001267; share per position 0.000980 to 0.001360 (MCSE 0.000112)
westgard 10_x  analytic 0.001953; share per position 0.001940 to 0.002070 (MCSE 0.000140)
westgard largest deviation 1_3s at position 11: -2.80 MCSE; n_sim 100000 series of 12 values, seed 20261308, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
K-M3c-3 (tests/simulation/test-westgard-false-alarm.R, Parvin 1992, 21.2 s):
SE 0: ARL 179.685 (MCSE 1.277), 1/ARL 0.00557 (MCSE 0.00004), Parvin 0.005, difference +0.00057 (tolerance 0.016); 20000 trials, seed 20262108, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
SE 1: ARL 12.555 (MCSE 0.071), 1/ARL 0.07965 (MCSE 0.00045), Parvin 0.082, difference -0.00235 (tolerance 0.016); 20000 trials, seed 20262118, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
SE 2: ARL 3.332 (MCSE 0.015), 1/ARL 0.30010 (MCSE 0.00131), Parvin 0.301, difference -0.00090 (tolerance 0.016); 20000 trials, seed 20262128, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
```

**M3d-BUILD-INFRA-01 — erneut in M3c, OUT-OF-TERRITORY [INFRA].**
Ref: QA-M3d-E2E-2 (`tests/e2e/test-m3d-qa-e2e.R:180`),
K-M3d-6 Metadaten (`tests/acceptance/test-m3d-6-report-conventions.R:119`,
`setup-m3d.R:545`) und der unveränderte HTTP-Replay in `setup-m2.R`.
Der QA-Replay verwendet `httr2::req_dry_run()` und damit einen lokalen
Echo-Server; der Sandbox fehlen Socketrechte. Echter Abbruch:

```text
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE)
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Der Metadaten-Abnahmehelfer erreicht nach denselben gespeicherten
Backendfehlern `jsonlite::fromJSON(runs$meta[i])` mit fehlenden Metadaten und
bricht dort mit `missing value where TRUE/FALSE needed` ab, bevor die
Berichtstabelle geprüft wird. Derselbe Zusammenhang ist bereits im M3d-BUILD
dokumentiert. Kein neuer Produktfix, kein Retry mit geänderten Rechten und
kein Eingriff in QA/Abnahme. Vorschlag an Reviewer/Betreiber für die
Backlog-Nachführung: unveränderte Prüfwege im regulären Gate-Kontext mit
lokalen Sockets ausführen. Die beiden betreffenden Gesamtläufe sind lokal
ausdrücklich nicht vollständig grün.

### Paketbau und Paketchecks

`public/src` und `full/src` enthalten nur Paketdateien, Builder-Unit-Tests
und die unveränderte `tests/testthat.R`; keine Originalanker, lokalen
Datenblätter, API-Aufzeichnungen, Harness- oder Git-Dateien. Jeder Kontext
führt aus seinem eigenen Verzeichnis aus:

```bash
R CMD build --no-manual src
R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Der öffentliche Prozess hat kein `REPO_ROOT`, der vollständige Prozess
verweist auf das Originalrepo. `TZ=Europe/Berlin`; wie in
`orchestrator/lib/r-check.sh` ist lediglich
`_R_CHECK_CRAN_INCOMING_REMOTE_=false` gesetzt. Der Systemzeitcheck bleibt
aktiv. Startbefehle: `python3 "$M3C_BUILD_DIR/run-check.py" public` und
entsprechend `full`. Echter Schluss beider Prozesse:

```text
public R CMD build: exit 0
public R CMD check: exit 0
Status: 1 NOTE
full R CMD build: exit 0
full R CMD check: exit 0
Status: 1 NOTE
```

Im gebauten öffentlichen Paket meldet `testthat.R` unverändert kontextbedingte
Skips (sechs nicht ausgelieferte API-Aufzeichnungen, zwei Originalanker-Vergleiche,
ein CRAN-Skip und der ellmer-Negativfall); mit REPO_ROOT entfallen die beiden
Originalanker-Skips. Die direkte vollständige Unit-Suite oben hat dagegen die
Betreiberaufzeichnungen und `NOT_CRAN=true`. Echte Paket-Testausgaben:

```text
public: [ FAIL 0 | WARN 0 | SKIP 10 | PASS 7774 ]
full:   [ FAIL 0 | WARN 0 | SKIP 8 | PASS 7776 ]
```

Die NOTE lautet `Unable to verify current time.`; der externe CRAN-Index
ist ebenfalls nicht erreichbar, die installierten Abhängigkeiten bestehen
aber den Check. Keine ERROR/WARNING im abschließenden Checkstatus und keine
Abschwächung einer Prüfregel. Vier Vignetten werden je Kontext gebaut und
beim Check erneut gebaut. Die tatsächlichen HTML-Tabellen in den Tarballs
wurden gelesen und gegen die enthaltenen Ergebnisspalten verglichen:

```text
public: all 4 HTML vignettes built; planning table has exactly 4 plans and 9 columns, matching stored results; context public; no private or harness files shipped.
full: all 4 HTML vignettes built; planning table has exactly 4 plans and 9 columns, matching stored results; context full; no private or harness files shipped.
Public and full planning HTML tables are identical.
```

Der erste eigene Tarball-Inspektor verwendete versehentlich den installierten
Pfad statt `inst/validation/` im Quellarchiv (KeyError); nach Korrektur des
Inspektors bestehen unverändert gebaute Archive die Prüfung. Kein
Paketinhalt musste dafür geändert werden. Nach den Paketchecks wurden nur
die echten neuen Sitzungs-/Provenienzdateien der sequentiellen Wiederholung
übernommen; Code, Tests, Dokumentation und numerische Dateien bleiben
bytegleich. Die abschließende Ressourcenprüfung oben umfasst diese neuen
Dateien. Der direkte Dateivergleich ergibt:

```text
public check input vs final package: only SOURCES.json and session.txt changed for the new real run; product code, unit tests, documentation and numerical data remain byte-identical.
full check input vs final package: only SOURCES.json and session.txt changed for the new real run; product code, unit tests, documentation and numerical data remain byte-identical.
```

Windows/macOS wurden lokal nicht ausgeführt und bleiben Release-/CI-Prüfungen
des Betreibers.

### Backlog, Integrität und Übergabe

Die vollständige Zuordnung aller 144 Backlog-Einträge aus PLAN bleibt
maßgeblich; es wird kein Eintrag eigenmächtig geschlossen. Aktualisierungen
gegenüber PLAN für Reviewer/Betreiber:

- BL-50: Vergleich samt Grenzanteilen und MCSE ist aus echten Replikaten
  berichtet und unabhängig reproduziert; keine Übereinstimmungsschwelle.
- BL-13/BL-46: gemeinsame Klasse-A-Laufzeit und beide vollständigen
  Paketprüfungen sind oben belegt; die Gesamtdauer regulärer Gates und
  Mutationsläufe bleibt Betreiberbeobachtung.
- BL-57: direkt geladener ANK-02 bestätigt das alte API-Präfix; das neue
  Argument hat eine Vorgabe und steht am Ende. Die Prüferpflicht bleibt.
- BL-76: dokumentierter Fit-Abbruch bleibt erhalten und ist gezielt geprüft.
- BL-142: die von E6 verlangten `validate_assessment()`-Teilbedingungen und
  Berichtsfehler sind ergänzt. Weitere Parser-/Backend-/Hash-Pflege und die
  Zusammenführung alter Konstanten bleiben nach PLAN/ADR-054 vertagt.
- ACC-9: verbindliche Aufnahme einer CV-MCSE-Formel bleibt Betreiberfrage;
  der erlaubte benannte Zusatz wird dokumentiert, keine Entscheidung vorweggenommen.

Die übrigen Gründe/Zuständigkeiten der PLAN-Vertagungen gelten unverändert,
insbesondere AP1/Betreiber-Volläufe, historische Reviewer-/QA-Restaufgaben
und die nach dem 26.11.2026 vorgesehene Pflege. Der Socketbefund ist oben
mit stabiler ID, Fundstellen und ausgeführtem Beleg übergeben.

Abschließende SHA-256-Inventur ohne Git:

```text
Inventory: 461 baseline files; 11 changed; 450 byte-identical; 0 deleted.
New files in inventoried trees: 14; all belong to the approved Builder file list.
Existing tests: 179/179 byte-identical.
Original anchor files: 59/59 byte-identical.
M3c handoffs and LESSONS: 5/5 byte-identical.
Historical PROGRESS body: byte-identical suffix.
R/fit.R, R/grr.R, R/report-data.R, NAMESPACE: byte-identical.
All remaining inventoried specs, contracts, rules, toolchain and BACKLOG files: byte-identical.
No changed or new inventoried file outside the approved Builder file list.
```

Die ältere PROGRESS-Historie bleibt bytegleich als Suffix erhalten.
`R/fit.R`, `R/grr.R`, `R/report-data.R`, NAMESPACE, alle vorhandenen Tests,
Originalanker, Spezifikationen, Verträge, BACKLOG, Toolchain und erfasste
M3c-Handoffs sind unverändert. Keine Gate-Fakten oder Orchestrator-Dateien
geschrieben. Keine Git-Kommandos, Live-API-Aufrufe, Installation oder
Äquivalenzfreigabe. Der reguläre kumulative Gate-Lauf einschließlich
historischer Git-verwendender Tests, Mutation mit unveränderter
Schwelle/Floor/Ratchet und 14 Workern, Territoriumsprüfung, Reviewer-Verdict
und Phasen-Commit bleiben beim Orchestrator. Ein Mutationsscore für diesen
BUILD wird ohne ausgeführten Lauf nicht behauptet.

## M3d — REWORK, Runde 2 (07.11.2026)

Der Code-Review der Runde 1 enthält **keine blocking-Befunde** und
verlangt keine Produktänderung. E11 ist **OUT-OF-TERRITORY [INFRA]**:
Das tests-Gate scheitert ausschließlich an den drei historischen
M1d-Abnahmestellen, die das in M3d erlaubte Seed-Attribut noch nicht
berücksichtigt hatten (ADR-053 Nr. 14.5). Der Reviewer hat sie inzwischen
korrigiert und seine positiven und negativen Prüfläufe in REVIEW
dokumentiert. Die Bestätigung durch die Gates der Runde 2 steht aus.

Maßgebliche Gate-Fakten bleiben `orchestrator/state/M3d/gates.json`,
Runde 1: `result: fail`, nur `tests: fail`, alle anderen Gates `pass`,
kein Status `error`. Das Log nennt 866 Testblöcke, davon drei fehlgeschlagen
mit zehn negativen Erwartungen, null Fehler und einen Skip
(`gate-tests.log:1784–1866`, `:2618`). `mutgate` ist mit 80,25 bei
geforderten 80 grün (`gate-mutgate.log:2255`); `mutfull` ist nicht fällig.

Die Antworten auf **E11 bis E17**, die Referenzen und vollständigen
Prüfbefehle stehen in
[REWORK-NOTES.md](orchestrator/handoff/M3d/REWORK-NOTES.md).
E12 (CSV-Text NA, BL-139), E13 (Metadatendarstellung, BL-140), E14
(Bootstrap-Hinweis, BL-141), E15 (Testlücken und Pflege, BL-142), E16
(Parser-Vektoren, QA-M3d-001/BL-143) und E17 (Kennzeichnung des
Plot-Snapshots, BL-128) bleiben gemäß Review nonblocking und vertagt.
Keiner dieser Punkte wird als behoben erklärt. Kein MUT-EQUIV-Antrag
und keine Freigabe; bestehende Tests bleiben unverändert.

Der frühere PLAN-Befund E9/ACC-17 (4) ist von QA umgesetzt; der
unveränderte M3b-E2E-Test bestätigt die getrennte Seed-Prüfung unten.
E10/ACC-17 (1–3) ist die unter E11 eingeordnete Reviewer-Korrektur.
Kein offener QA-PENDING-Befund im aktuellen Review. Der historische
Socketbefund M3d-BUILD-INFRA-01 bleibt eine lokale
OUT-OF-TERRITORY-Prüfgrenze; die betreffenden M3d-Abnahmetests sind im
regulären Gate der Runde 1 grün. Kein erneuter Socket-Replay und kein
Scheinfix. Eine ARBITER.md liegt für M3d nicht vor; LESSONS ist gelesen.

Gezielte Läufe in der bytegleichen Paketkopie
`/tmp/llmsa-m3d-r2-l52al90t/package`, mit Originalankern und
Betreiberaufzeichnungen über die vorhandenen Testhelfer. Die sieben
M3d-Unit-Dateien, M3b-QA-E2E und M3d-QA-Fuzz wurden unverändert
ausgeführt. Alle drei Prozesse Exit 0; echter Output:

```text
M3d-R2-unit: 45 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 932 passed expectations; elapsed 12.383 s
M3d-R2-QA-seeds: 3 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 259 passed expectations; elapsed 1.717 s
M3d-R2-QA-fuzz: 2 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 195 passed expectations; elapsed 1.148 s
```

50 Blöcke und 1.386 erfolgreiche Erwartungen, keine Warnungen oder Skips.
Dies ist ein gezielter Builder-Nachweis, keine vollständige Gate-Abnahme.
Die historischen M1d-Vergleiche verwenden `acc_git()` und bleiben wegen
des Git-Verbots dem Orchestrator vorbehalten. Kein erneuter Mutationslauf
und kein Paketbau bei unverändertem Produktcode.

Geändert sind nur dieser Nachtrag und der zugewiesene Handoff.
Die SHA-256-Inventur (Exit 0) bestätigt eine geänderte Ausgangsdatei,
eine neue Datei und keine Löschung; die übrigen 473 von 474 erfassten
Ausgangsdateien sind bytegleich, darunter alle 15 R-Dateien, 169 Tests
und 22 Zustandsdateien von M3d. Vollständiger Output: REWORK-NOTES, P3.
Produktcode, Hilfeseiten, Vorlagen, Tests, Anker, BACKLOG und Gate-Zustand
bleiben erhalten. Keine Git-Kommandos, Abhängigkeitsinstallationen,
Live-API-Aufrufe, Schwellenänderungen oder eigener Verdict. Der
Orchestrator prüft das Territorium, erzeugt den Phasen-Commit und führt
die Gates der Runde 2 aus.

## M3d — BUILD, Runde 1 (06.11.2026)

Der freigegebene PLAN ist gemäß ADR-053 im Builder-Territorium umgesetzt.
Die lokalen Unit-, Numerik-, Berichts- und Klasse-B-Reproduktionen bestehen.
Die unveränderte M3d-Abnahme bleibt wegen des lokalen Socketverbots rot;
die unveränderte QA-Suite zeigt die zwei von ADR-053 angekündigten
Seed-Attribut-Konflikte. Dies ist ein BUILD-Nachweis, keine Gate-Abnahme.

### Grundlage und Umsetzung

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema,
PROGRESS, LESSONS, PLAN, PLAN-REVIEW/verdict-plan (Runde 1, PASS),
CRITERIA ACC-1 bis ACC-17, die vollständigen M3d-Abnahmetests samt
Helfern, docs/01, die Stellen zu K-M3d-1 bis K-M3d-6 in docs/04,
die betroffenen M1c-/M1d-/M2-Verträge und Formelsammlung §§2–4, 8,
11–12. PLAN-UPDATE und ARBITER liegen für M3d nicht vor. Die einzige
LESSONS-Lehre verlangt allgemeine Ursachenbehebung statt Einzelfallpatches.
ADR-053 entscheidet die im PLAN vorgelegten Vertragsfragen. Es gibt
keine Planabweichung und keinen neuen Builder-ADR.

- `R/run.R`: CSV liest ausschließlich block/position/rep als Integer und
  latency_s als Double, sämtliche übrigen und unbekannten Spalten als Text.
  Fehler sowie NULL, Länge null, NA und leerer Antworttext erhalten eine
  benannte Fehlerzeile ohne Parseraufruf; vorhandene Metadaten bleiben.
  Whitespace geht an den Parser. Nicht-Fehlerbedingungen propagieren
  unverändert; Schreibfehler brechen ab. Resume überspringt auch gespeicherte
  Fehler und nicht parsbare Antworten, ohne sie umzuschreiben.
- `R/backends.R`: Der Mock verwendet den dokumentierten, stellenabhängigen
  Strom aus Seed und längenmarkierten UTF-8-Teilen des vollständigen
  Aufrufschlüssels. Neue Backendinstanzen und andere Reihenfolgen liefern
  dieselbe zeilenbezogene Antwort. Prompt-/Modelleffekte bleiben unverändert,
  ebenso die Rückgabe eines vorhandenen oder fehlenden Aufrufer-RNG-Zustands.
  ellmer nutzt weiterhin eine frische Chat-Kopie und übernimmt Modell,
  Anbieter und verschachtelte usage aus der tatsächlichen letzten Antwort.
- `R/parse.R`: Unicode-Minus wird für Zahlen normalisiert. Der JSON-Parser
  validiert das erste vollständig abgegrenzte Objekt mit
  `jsonlite::parse_json(simplifyVector = FALSE)`, berücksichtigt Strings und
  Escapes und liest nur das exakte Feld der obersten Ebene. Syntaxfehler,
  Warnungen und nicht skalare/nicht unterstützte Werte ergeben NA; ein
  Dateiname wird nicht als Eingabequelle interpretiert. Die Fabrik nennt
  jsonlite als Voraussetzung. Choice-Verhalten bleibt unverändert.
- `R/report.R`, `R/report-data.R` und die Vorlage: letztes Defaultargument
  `control_chart = NULL`, frühe Klassenprüfung, Westgard-Zahlen und echte
  Indexpositionen, Konventionen und Modellgrenzen, alle beobachteten
  Metadatenwerte sowie ausdrücklich benannte Lücken. Hash, Seed-Texte,
  Modell- und Westgard-Tabellen entstehen in R und gehen als deklarierte
  Parameter an die Vorlage. Der SHA-256 deckt sämtliche Zellen der nach
  ADR-053 kanonisierten Lauftabelle ab. NA-ndc bleibt NA. Zahlen verwenden
  Dezimalpunkte; das ursprüngliche OutDec wird nach dem Rendern restauriert.
- `R/grr.R` und `R/robustness.R`: genau die drei Seed-Zuweisungen aus
  ADR-053 Nr. 14.2 neben ergänzender roxygen-Dokumentation. Keine Änderung
  einer Formel, eines Fits, einer Quantilrechnung oder eines AP1-Bands.
  Sieben Hilfeseiten wurden in einer temporären Kopie erzeugt; nur diese
  sieben wurden übernommen. NEWS beschreibt das endgültige Verhalten.
- Fünf neue Unit-/Property-Dateien prüfen Resume/Typen/Abbruch/RNG,
  JSON- und Zahlenparser, beide echten Adapter mit Aufzeichnungen und
  synthetischen Fehlerantworten, unabhängige kanonische CSV-Bytes,
  Metadaten/Markdown/HTML und Seed-Provenienz. Darstellungstests sind als
  solche markiert. BL-128 ergänzt die Kommentare der bestehenden
  Robustheitstests und prüft den abschließenden Zeilenumbruch mit einem
  nachfolgenden Ausgabemarker. BL-130 bleibt wie geplant vertagt.

### Antworten auf PLAN-REVIEW

| ID | Umsetzung und Übergabe |
| --- | --- |
| E1 | Abschnitte 1–6 behalten Nummer und Titel; keine zusätzlichen Überschriften in 3/5/6. Die latente Erklärung steht unmittelbar nach der einzigen Listenzeile mit beiden Präzisionsbegriffen. Bestehende Robustheits-, Bias-, AP1- und Bootstraptexte bleiben. Berichtsregression und QA bestätigen die alten Leser. |
| E2 | Nur `error` wird gespeichert. Eigene CSV-/SQLite-Tests prüfen unveränderte `interrupt`- und `acmg_network_abort`-Bedingungen ohne zusätzliche Zeile; vorhandene AP1-Netzwachentests bestehen. |
| E3 | Alle vier Leerarten, Parserunterdrückung und Metadatenerhalt geprüft. AP1-Folge unten ausdrücklich beschrieben; keine Änderung von AP1-Regeln. |
| E4 | Vollständige colClasses-Zuordnung; eigene Tests für führende Nullen, Textantworten, NA-Spalten und unbekannte Textspalten sowie fertigen Resume ohne Neuaufruf. |
| E5 | Längenmarkierte UTF-8-Teile und Positionsmischung dokumentiert. Tests für gleiche Zeichensummen, verschiedene Teilgrenzen, Unicode, Block/Replikat und Aufrufreihenfolge. Mock-Werte ändern sich gegenüber dem alten Aufrufzähler; keine empirischen Konstanten oder eingefrorenen Resultate angepasst. |
| E6 | Seeds ohne Exponent/Tausendertrenner und unmittelbar nach der Bezeichnung; Konventionen 1.41, 1 und 9 aus ANK-16. Tatsächliche Verdiktbasis/-schwellen kommen aus grr. |
| E7 | parse_json statt fromJSON; Syntax- und Dateinamensnegativfälle, exakte Feldnamen und dokumentierter Fehler bei fehlendem jsonlite geprüft. |
| E8 | Alte runs ohne meta/design, unlesbares meta, ausgelassene Objekte und fehlende Seeds rendern. Die Vorlage formatiert die in R vorbereiteten Herkunftsdaten. |
| E9 | [QA-PENDING], nonblocking gemäß ADR-053 Nr. 14.6/ACC-17: genau zwei rote Erwartungen in QA-M3b-E2E-3, siehe echter Output unten. Änderung ausschließlich durch QA. |
| E10 | Reviewer-Auftrag gemäß ADR-053 Nr. 14.5: die drei historischen M1d-Vergleiche bleiben bis zum Code-Review erwartet rot. Ihre Git-verwendenden Pfade wurden lokal nicht ausgeführt; keine Änderung/Ersetzung der Tests durch den Builder. |

### Ausführungsumgebung und Testtreiber

Alle ausführenden Prüfungen liefen in Positivlisten-Kopien unter
`/tmp/llmsa-m3d-build-64t4zgy9/`. `baseline/` enthält den gesicherten
Ausgangsstand, `work/` den geprüften Produktstand, `docs-src/` die
roxygen-Kopie und `public/src/` die öffentliche Paketkopie. Die Inventur
vor der Änderung umfasst 438 Dateien. Keine Git-/Schlüsseldateien wurden
kopiert. Quellen, Aufzeichnungen und Anker werden ausschließlich gelesen.

Für die nachstehenden vollständigen Befehle ist die Pfadabkürzung:

```bash
M3D_BUILD_DIR=/tmp/llmsa-m3d-build-64t4zgy9
```

`run-suite.R` setzt das übergebene Paketverzeichnis als Arbeitsverzeichnis,
`REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa`, `NOT_CRAN=true`,
`TZ=Europe/Berlin` sowie die vorhandene Unit-Option
`llmsa.test.ap1_recordings` auf die Originalaufzeichnungen. Es öffnet
`pdf(NULL)`, setzt `testthat::set_max_fails(Inf)` und ruft
`testthat::test_dir(testdir, filter = filter, load_package = "source",
reporter = "summary", stop_on_failure = FALSE)` auf. Alle Blöcke laufen;
der Prozess endet anhand der tatsächlichen Fehl-/Fehlerblöcke mit 0/1.
Ergebnisobjekte und vollständige Outputs stehen im genannten Verzeichnis.
Abnahmehelfer, erwartete Werte und Fehlerbedingungen werden nicht ersetzt.

Rein lesende Abhängigkeitsdiagnose aus `work/` (Exit 0):

```bash
Rscript --vanilla /mnt/c/Users/Danie/dev/Llmsa/llmsa/orchestrator/lib/r-deps.R --check-only
```

Echter Schluss aus `dependencies.log`:

```text
r-deps: pass — 31 Anforderungen erfüllt (R 4.6.1)
```

Unter anderem unverändert installiert: lme4 2.0.6, Matrix 1.7.4,
ordinal 2026.7.26, ellmer 0.5.0, httr2 1.3.0, jsonlite 2.0.0,
testthat 3.3.2, digest 0.6.39, rmarkdown 2.32 und knitr 1.52.
Keine Installation/Aktualisierung von Abhängigkeiten und kein Live-API-Aufruf.

### Frühe Diagnosen

```bash
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/baseline" tests/acceptance '^m3d-' 'M3d baseline acceptance'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/acceptance '^m3d-' 'M3d implementation acceptance'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/testthat '^(run-resume|parser-properties|backend-metadata|report-provenance|seed-provenance)$' 'M3d unit initial'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/testthat '^(run-resume|parser-properties|backend-metadata|report-provenance|seed-provenance|robustness-transform|robustness-properties)$' 'M3d unit corrected'
```

Echte Outputs in `acceptance-before.log`, `acceptance-initial.log`,
`unit-initial.log`, `unit-corrected.log`; Exit-Codes 1, 1, 1, 0:

```text
M3d baseline acceptance: 31 blocks; 211 failed expectations; 1 error blocks; 0 warnings; 0 skips; 1199 passed expectations; elapsed 38.911 s
M3d implementation acceptance: 31 blocks; 32 failed expectations; 1 error blocks; 0 warnings; 0 skips; 1453 passed expectations; elapsed 34.236 s
M3d unit initial: 26 blocks; 10 failed expectations; 1 error blocks; 0 warnings; 0 skips; 410 passed expectations; elapsed 11.791 s
M3d unit corrected: 45 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 932 passed expectations; elapsed 12.591 s
```

Im ersten Implementierungslauf fehlte noch die neu erzeugte ellmer-Hilfe.
Die übrigen negativen Erwartungen sind der unten beschriebene Replayweg.
Der erste neue Unit-Lauf fand Fehler in den eigenen Testhilfen: Der
synthetische Response-Bauer rundete JSON-Zahlen schon vor dem Adapter;
ellmers strukturierter Message-Inhalt wurde für die Fehlerfallauswahl
falsch gelesen; requireNamespace wurde an einer nicht vorhandenen
Namespace-Bindung gemockt; HTML-Zeilenumbruch störte einen Textvergleich.
Korrigiert wurden Serialisierungspräzision, Auswertung der tatsächlichen
Message-Struktur, die lokale Abhängigkeitsumgebung der unveränderten
Parserfabrik und Whitespace-Normalisierung des gelesenen HTML. Keine
fachliche Erwartung wurde entfernt oder abgeschwächt.

### Endgültige Unit-, QA- und Abnahmeregressionen

```bash
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/testthat '.' 'M3d full unit'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/e2e '.' 'M3d unchanged QA e2e'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/fuzz '.' 'M3d unchanged QA fuzz'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/acceptance '^m3d-' 'M3d final acceptance'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/acceptance '^(m3b-|m3a-6-|m1c-[12]-|m1c-7-latent-note)' 'M3d core report regression'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/acceptance '^m2-[3467]-' 'M3d M2 regression'
```

Vollständige Logs: `unit-full.log`, `qa-e2e.log`, `qa-fuzz.log`,
`acceptance-final.log`, `core-report.log`, `m2-regression.log`.
Exit-Codes in dieser Reihenfolge: 0, 1, 0, 1, 0, 1.

```text
M3d full unit: 380 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 1 skips; 7486 passed expectations; elapsed 154.548 s
M3d unchanged QA e2e: 25 blocks; 2 failed expectations; 0 error blocks; 0 warnings; 0 skips; 722 passed expectations; elapsed 39.154 s
M3d unchanged QA fuzz: 13 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 1385 passed expectations; elapsed 10.501 s
M3d final acceptance: 31 blocks; 31 failed expectations; 1 error blocks; 0 warnings; 0 skips; 1454 passed expectations; elapsed 63.773 s
M3d core report regression: 53 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 850 passed expectations; elapsed 35.969 s
M3d M2 regression: 35 blocks; 2 failed expectations; 5 error blocks; 0 warnings; 0 skips; 1587 passed expectations; elapsed 747.030 s
```

Der einzige Quell-Unit-Skip ist der bestehende Negativfall
`backend_ellmer needs ellmer`, weil ellmer installiert ist. Der gesonderte
M3d-Abnahmetest für fehlendes ellmer im isolierten Teilprozess besteht.
Die Aufzeichnungen wurden in den neuen Quell-Unit-Tests tatsächlich gegen
beide Adapter wiedergegeben, einschließlich unveränderter verschachtelter
usage und frischer Chat-Verläufe. Beide Adapter bestehen zusätzlich die
SQLite-Folge Erfolg/HTTP 500/HTTP 401/Timeout/leerer Body/NULL/leerer
Content/Erfolg. Das ist ergänzende Evidenz, kein Ersatz der roten Abnahme.

Die zwei erwarteten QA-Fehler stehen unverändert in
`tests/e2e/test-m3b-qa-e2e.R:214` und `:231`:

```text
Expected `sort(names(attributes(rob_default)))` to be identical to `sort(...)`.
Differences:
`actual[7:11]`:   "response_mean" "response_sd" "row.names" "seed" "sme"
`expected[7:10]`: "response_mean" "response_sd" "row.names"        "sme"
Expected `rob_sub_pb` to be identical to `rob_sub_df`.
Differences:
`attr(actual, 'seed')` is an integer vector (20261105)
`attr(expected, 'seed')` is absent
```

M3d-Ergebnisse nach Datei (aus dem gespeicherten testthat-Ergebnis):

| Kriterium | Erfolgreiche Erwartungen | Fehlgeschlagene Erwartungen | Fehlerblöcke |
| --- | ---: | ---: | ---: |
| K-M3d-1 Resume | 706 | 0 | 0 |
| K-M3d-2 Parser | 13 | 0 | 0 |
| K-M3d-3 Backends | 100 | 31 | 0 |
| K-M3d-4 Berichtszahlen | 513 | 0 | 0 |
| K-M3d-5 Datenhash | 89 | 0 | 0 |
| K-M3d-6 Konventionen | 33 | 0 | 1 |

**M3d-BUILD-INFRA-01 — [INFRA], nonblocking für den Builder.**
Ref: K-M3d-3, K-M3d-6 Metadaten, K-M2-4/7, PLAN P-M3d-04;
`tests/acceptance/setup-m2.R:771` (von M3d mitbenutzt). Der unveränderte
Abnahme-Replay verwendet req_dry_run und damit einen lokalen Socket:

```text
System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE)
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Dadurch werden auch die vorgesehenen Erfolgsantworten zu Fehlerzeilen.
Alle 31 M3d-Fehlerwartungen stammen aus diesem Replay und seinen
Folgen. K-M3d-6 scheitert im Abnahmehelfer beim JSON-Lesen der dadurch
fehlenden meta mit `missing value where TRUE/FALSE needed`, bevor die
Metadatentabelle geprüft wird. Kein Test, Helfer, Gate, Recht oder
Schwellenwert wurde verändert. Handoff: Betreiber/Reviewer führen den
unveränderten Prüfweg im regulären Gate-Umfeld mit lokalen Sockets aus.
Die M2-Regression hat dieselbe Ursache: K-M2-4 meldet zwei negative
Erwartungen und vier Fehlerblöcke, K-M2-7 einen Fehlerblock beim
Systemspalten-Replay. K-M2-3 besteht mit 837 Erwartungen, K-M2-6 mit
383; die übrigen 353 Erwartungen aus K-M2-7 bestehen einschließlich
Mock-CLI, Teile-/Resume-Schlüsseln, Pilot, Robustheit und Assessment.
Die Aufschlüsselung mit jedem Fehlertext liegt in `m2-files.log`.

### Numerik, Simulationen und Seeds

```bash
Rscript --vanilla "$M3D_BUILD_DIR/compare-seeds.R"
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/acceptance '^m(1c-4-|1d-6-)' 'M3d class B reproduction'
Rscript --vanilla "$M3D_BUILD_DIR/run-suite.R" "$M3D_BUILD_DIR/work" tests/simulation '^lenth-h0$' 'M3d Lenth class A'
```

Alle drei Prozesse Exit 0. Echter Output aus `compare-seeds.log`,
`class-b.log`, `lenth-class-a.log`:

```text
Before/after: 12 PB designs; 24 robustness results; 9 bootstraps; 5 AP1 assessments
All existing result fields, attributes, warnings, messages and RNG states identical after removing only the approved seed attributes.
Seed provenance checked separately for NULL, integer and double seeds; all three AP1 bands retained.
M3d class B reproduction: 25 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 4881 passed expectations; elapsed 344.360 s
M3d Lenth class A: 1 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 6 passed expectations; elapsed 2.056 s
```

Der Vorher-/Nachher-Vergleich lädt gesicherte Ausgangsquellen in einen
eigenen Funktionskontext im selben R-Prozess. Er entfernt ausschließlich
die erlaubten neuen Seed-Attribute vor identical; alle übrigen Attribute,
Replikate, Intervalle, Warnungen, Meldungen und RNG-Zustände werden exakt
verglichen. Die AP1-Fälle enthalten acceptable, marginal und unacceptable.
Der unabhängige Bootstrapvergleich gegen bootMer und die alten Berichtsleser
sind zusätzlich Bestandteil der grünen Kernregression oben.

K-M1c-4 reproduziert den Kurzlauf und das S-boot-7-Präfix. K-M1d-6 prüft
Vollständigkeit der vorhandenen vier Studien, ihre Kennzahlen aus den
Einzelschätzern und reproduziert mit ANK-TOL.n_check die vorgeschriebenen
Präfixe; für boot_coverage sind dies S-boot-1 und S-boot-7. Alle Ergebnisse
entstehen unter temporären Ausgabepfaden. Historische Kurz-/Vollresultate
und Session-Dateien sind bytegleich; kein zusätzlicher Volllauf wurde
gerechnet oder behauptet. Der neue Körper von msa_boot ändert künftig
boot_implementation; alte Session-Hashes werden nach ADR-053 Nr. 16
nicht umetikettiert, alte und neue Chunks nicht zusammengeführt.

Lenth-Klasse-A meldete n_sim = 1000 je Szenario, Seeds 20261112/20261115,
RNG Mersenne-Twister/Inversion/Rejection. Für acht Faktoren: ME-Rate
0.02325 (MCSE 0.00222), SME-Rate 0.01500 (0.00384); für elf Faktoren:
0.02891 (0.00231) und 0.02500 (0.00494). Jede Entscheidung stimmt mit
der unabhängigen Mini-Referenz überein; die unveränderten Kriterien bestehen.

### Dokumentation, API und öffentlicher Paketcheck

```bash
Rscript --vanilla -e 'roxygen2::roxygenise("/tmp/llmsa-m3d-build-64t4zgy9/docs-src", roclets="rd")'
Rscript --vanilla "$M3D_BUILD_DIR/check-api.R"
```

Beide Exit 0. roxygen2 8.1.1 erzeugte die sieben geplanten Hilfen;
die zusätzliche Autorenformatierung von llmsa-package.Rd wurde nicht
übernommen. DESCRIPTION und NAMESPACE bleiben bytegleich. `api.log`:

```text
ANK-02: 22 exports and 108 original ordered arguments/defaults preserved; every appended argument has a default.
msa_report: final argument control_chart = NULL; no new exports.
```

Öffentliche Positivlisten-Kopie nur mit Paketdateien, ausgelieferten
Ressourcen, Unit-Tests und Vignetten; keine Originalanker, geschützten
Daten, API-Aufzeichnungen, Harness- oder Git-Dateien. Aus `public/`
tatsächlich ausgeführt, beide Exit 0:

```bash
env -u REPO_ROOT TZ=Europe/Berlin R CMD build --no-manual src
env -u REPO_ROOT TZ=Europe/Berlin _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht dem unveränderten Betreiberprüfweg
`orchestrator/lib/r-check.sh`; die Uhrzeitprüfung blieb aktiv. Aus
`public/build.log`, `public/check.log` und dem installierten Testoutput:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
* checking R code for possible problems ... OK
* checking examples with --run-donttest ... [39s/39s] OK
* checking tests ...
  Running ‘testthat.R’ [99s/99s]
 [100s/99s] OK
[ FAIL 0 | WARN 0 | SKIP 10 | PASS 7195 ]
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [54s/54s] OK
* DONE
Status: 1 NOTE
```

Kein ERROR, keine WARNING. Die einzige NOTE lautet
`Unable to verify current time` bei `checking for future file timestamps`.
Die zehn installierten Skips betreffen sechs Replayblöcke mit bewusst
nicht ausgelieferten Betreiberaufzeichnungen, zwei Originalanker-Vergleiche
im öffentlichen Tarball, den bestehenden Report-On-CRAN-Skip und den
ellmer-Abwesenheitsfall bei installiertem ellmer. Die entsprechenden
Quellprüfungen liefen oben mit Originalressourcen. Windows/macOS/R 4.1
werden durch diesen Linux-Lauf mit R 4.6.1 nicht als geprüft erklärt.

### Integrität und Übergabe

Abschließend ausgeführt (Exit 0):

```bash
python3 "$M3D_BUILD_DIR/check-integrity.py"
```

Echter Output (`integrity-final.log`):

```text
Inventory: 438 baseline files; 18 authorized changes; 6 authorized additions; no removals.
Protected inventoried paths: 325/325 byte-identical, including all acceptance, QA, anchor and simulation result files.
R/grr.R and R/robustness.R: only three approved seed assignments beyond roxygen changes; other statistical cores byte-identical.
Checked package copy: 23 changed/new package paths byte-identical; seven generated help files match roxygen output.
R sources ASCII; existing PROGRESS content retained; no generated artifacts in Builder paths.
```

Die Datei `integrity.json` enthält die vollständige Pfadliste. Kein
fremdes Territorium wurde geändert; das bestehende QA-Artefakt aus BL-135
bleibt bei QA. Die Inventur ersetzt nicht die Territoriumsprüfung.

**AP1-Folge (E3, ADR-053 Nr. 19.2):** Neu erfasste leere Antworten zählen
jetzt als backend_errors und damit für Pilot-/Wiederholungstagsregeln.
Die vorhandene AP1-Auswertung nimmt nur fehlerfreie Zeilen für
Provider-/Token-/Kostennachweise, obwohl die leere Fehlerzeile ihre meta
weiterhin speichert. Vorhandene Stores werden nicht nachklassifiziert
und beim Resume nicht neu gerechnet. Über Fortsetzung vorhandener oder
gemischter Erhebungen beziehungsweise einen neuen Store entscheidet der
Betreiber. Der Builder hat keine Betreiberstores verwendet oder geändert.

Die im PLAN dokumentierten Backlog-Zuordnungen und Vertagungen bleiben
bestehen. Reviewer/QA übernehmen E10/E9 und den belegten Infrastrukturpunkt
in ihrem Territorium. Der Orchestrator führt die unveränderten kumulativen
Gates einschließlich Mutation aus, prüft das Territorium und erzeugt den
Phasen-Commit. Es gibt keine eigenen Git-Kommandos, Gate-Fakten,
Äquivalenzfreigaben oder Abschwächungen von Tests und Schwellen.


## M3a — BUILD, Runde 1 (05.11.2026)

Der freigegebene PLAN samt PLAN-UPDATE ist umgesetzt; maßgeblich sind
PLAN-REVIEW Runde 2, `verdict-plan.json: PASS` und ADR-052 einschließlich
Nr. 17 und 19. Keine ARBITER-Datei vorhanden. Keine Planabweichung und
kein neuer Builder-ADR. Die Backlog-Zuordnungen und Vertagungen des
PLAN-UPDATE bleiben bestehen. Dieser Eintrag enthält die Build-Antworten
und ausgeführten Nachweise; eine gesonderte REVIEW-INPUT-Datei wurde in
diesem Auftrag nicht zugewiesen.

### Umsetzung und Antworten auf die Einwände

`R/agreement.R` ergänzt Fleiss-Kappa, Alpha-Ausschlusszahlen und beide
Bias-/Linearitätsrechnungen. Gemeinsame Referenzauflösung und gültige
Paarnenner gelten für die drei bisherigen Referenzformen. Die OLS-Rechnung
zentriert und skaliert vor Quadraten; das Handbuchband wird über den ganzen
geschlossenen Referenzbereich einschließlich innerer Extrema beurteilt.
Die zusätzlichen Ausgabefelder, Randfälle und Methoden stehen in den zwei
aus roxygen erzeugten Hilfeseiten und in Berichtsteil 4/5. Der bestehende
AP1-, Fit-, Bootstrap- und Robustheitsproduktcode wurde nicht geändert.

Der neue installierbare Helfer unter `inst/validation/agreement/` rechnet
die Bias-Überdeckung sequenziell mit dem geladenen `llmsa`-Namespace.
Seine ADEMP-Beschreibung steht in README.md. Der neue Abschnitt der
Validierungsvignette folgt vollständig hinter dem Bootstrap-Abschnitt.
Er nutzt die bereits hashgeprüften latenten ANK-06-/ANK-TOL-Objekte; keine
neue Ankerkopie und keine eingefrorene Ergebnisdatei. `irr`, `psych` und
`DescTools` sind Suggests; Imports, Exporte und NAMESPACE sind unverändert.
NEWS beschreibt die Erweiterungen auf Englisch.

| ID | Umsetzung und Nachweis |
| --- | --- |
| E1 | Referenzen werden vor der Kategorienfilterung eindeutig je Item aufgelöst; Konflikte und Referenzen außerhalb der ausdrücklichen/abgeleiteten Skala scheitern benannt. Cohen verwendet gültige Paare und die vollständige Skala. Unit-Tests prüfen alle Referenzformen, Gewichte und Reihenfolgen; K-M3a-1/-5 sowie AP1-/ClinVar-Integration wurden ausgeführt. |
| E2 | `n_excluded` steht hinter den bestehenden Feldern; jede beobachtete Prompt×Modell-Bedingung bleibt auch mit `n = 0` erhalten. Gesamt-/Gruppenzählungen, Singleton, fehlende Referenzen und unparsebare Antworten sind geprüft. Druck und Bericht zeigen Ausschlüsse, bei alten Objekten „not recorded“. |
| E3 | Eigene geschlossene t-/OLS-Rechnungen ohne `t.test`, `lm` oder `summary.lm` im Produktpfad. Relative Konstanz-/Restregeln aus ADR-052, Punktintervalle bzw. zusammenfallende Bänder und eindeutige Hinweise. Das numerische Raster umfasst 240 synthetische Fälle; zusätzlich extreme Skalen, Achsenverschiebungen, ungleiche Replikation, zwei Beobachtungen und innere Bandextrema. |
| E4 | `fleiss` enthält genau den unbenannten numerischen Punktschätzer `kappa`; kein SE. Beide Urteilsfelder sind unbenannte Skalare der vereinbarten Typen, auch bei undefinierter Linearität. Exakte Struktur- und Drucktests bestehen. |
| E5 | Eigener Bias-Abschnitt auf Ebene zwei ohne abgetippte Ergebniszahlen. Tabelle mit MCSE-Abstand und Befundtext; voller Umfang aus ANK-06, RNG-Wiederherstellung auch bei Fehlern. Ganze Knits vor/nach Änderung wurden mit demselben Skript gemessen; beide ohne Fehler und neue Repository-Dateien. |
| E6 | Vier neue Unit-Dateien prüfen u. a. beide vollständigen Druckausgaben, verschiedene Reproduzierbarkeitsraten, letzten Zeilenumbruch, unsichtbare Rückgabe, englische Fehlertexte und `conditionCall() == NULL`. Formattests sind als solche gekennzeichnet. Lokale Mutation über die ganze `R/agreement.R`; keine Mutationsausnahme und kein Äquivalenzclaim. |
| E7 | Optionale Live-Orakel in neuen Unit-Tests stehen hinter `skip_if_not_installed()`; unabhängige Formel-/Paarzähltests in eigenen Blöcken benötigen diese Pakete nicht. Abnahme und Schwellen bleiben unverändert. |
| E8 | Numerisch konstante Zielwerte ergeben in beiden Regressionen `r_squared = NA_real_` mit Hinweis. Das Raster prüft auch Rundungsreste nach `value - reference`. |
| E9 | Numerische Eingaben behalten ihre Double-Werte ohne Zeichenketten-Rundlauf. Konflikte zeigen 17 signifikante Stellen; Faktorlabels und gleiche numerische Schreibweisen sind geprüft. Unendlichkeiten und Differenzüberlauf führen zu benannten Fehlern. |
| E10 | Eindeutige Spalten `scenario`, `coverage`, `MCSE`, `n_sim`; Zusatzspalte `distance to level (MCSE)`. `n_sim` ohne Exponent. Unit- und Vignetten-Abnahme lesen die tatsächlich berechnete Tabelle erfolgreich. |
| E11 | Fleiss verweist nur bei ungleichen gültigen Anzahlen auf Alpha; andere Entartungen nennen ihren eigenen Grund. Kategorien und Konfliktwerte erscheinen in Anführungszeichen, auch leere Zeichenketten. Vollständige Meldungstests bestehen. |

Die vier neuen Tests liegen unter `tests/testthat/`: `test-agreement-m3a.R`,
`test-bias-linearity.R`, `test-agreement-report.R` und
`test-validation-bias.R`. Fachliche Vergleiche verwenden die Toleranzen aus
ANK-TOL; synthetische Designwerte sind keine empirischen Referenzkonstanten.
Die Formelprüfung und Live-Orakel laufen getrennt. Bei Alpha wurde ein
Fehler im ersten neuen Orakeltest korrigiert; der ausführbare Befund zu
`irr` steht unten. Weitere erste Fehler betrafen Argumentfehler mit Call
sowie typografische Anführungszeichen in R/Pandoc. Der Produktfehlerpfad
unterdrückt jetzt den Call; die neuen Formatprüfungen berücksichtigen die
tatsächliche R-/Pandoc-Darstellung. `unit-initial.log` und
`unit-expanded.log` bewahren diese frühen fehlgeschlagenen Läufe.

### Ausgeführte Befehle und echte Outputs

Arbeitsverzeichnis aller Repository-Befehle war die Repo-Wurzel.
Rohlogs und reproduzierbare Hilfsskripte liegen unter
`/tmp/llmsa-m3a-build-b4z_2rv_/`. R 4.6.1 (2026-06-24),
testthat 3.3.2, pkgload 1.5.3, roxygen2 8.1.1, irr 0.85,
psych 2.6.9, DescTools 0.99.60, knitr 1.52, rmarkdown 2.32,
jsonlite 2.0.0, digest 0.6.39 und muttest 0.3.0.
Keine Installation oder Aktualisierung von Abhängigkeiten; Paketbau und
Prüfinstallation verwenden ausschließlich temporäre Paketkopien.

`Rscript --vanilla orchestrator/lib/r-deps.R --check-only`, Exit 0
(`dependencies.log`):

```text
r-deps: pass — 31 Anforderungen erfüllt (R 4.6.1)
```

Rd-Erzeugung mit `roxygen2::roxygenise(..., roclets = "rd")` in
`/tmp/llmsa-m3a-build-b4z_2rv_/docs-src`, Exit 0. Übernommen wurden nur
`man/msa_agreement.Rd` und `man/msa_bias.Rd`. Erneute Erzeugung aus dem
Produkt-Endstand bestätigt (`roxygen-final.log`):

```text
ℹ Loading llmsa
msa_agreement.Rd: generated output identical = True
msa_bias.Rd: generated output identical = True
```

`run-suite.R` setzt `REPO_ROOT`, `NOT_CRAN=true`, ein Null-PDF-Gerät und
führt `testthat::test_dir(load_package = "source", reporter = "summary",
stop_on_failure = FALSE)` aus. Die Zusammenfassung stammt aus dem echten
Ergebnisrahmen; Fehler oder fehlgeschlagene Erwartungen ergeben Exit 1.
Die folgenden Läufe endeten mit Exit 0:

```sh
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/run-suite.R tests/testthat '^(agreement|agreement-m3a|bias-linearity|agreement-report|validation-bias|report|validation-latent|validation-latent-rework)$' 'M3a final unit and source contracts'
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/run-suite.R tests/acceptance '^m3a-' 'M3a acceptance initial'
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/run-suite.R tests/simulation '^bias-coverage$' 'M3a class A'
```

Unveränderte Outputzeilen aus `unit-complete.log`,
`acceptance-initial.log` und `simulation.log`:

```text
Synthetic bias grid: 240 cases, seeds 1201/1202; largest normalized oracle difference 2.36e-13
M3a final unit and source contracts: 51 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 819 passed expectations; elapsed 25.289 s
M3a acceptance initial: 35 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 872 passed expectations; elapsed 38.581 s
M3a class A: 1 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 4 passed expectations; elapsed 8.442 s
```

Die unveränderte unabhängige Klasse-A-Studie meldet:

```text
K-M3a-7 (tests/simulation/test-bias-coverage.R, 6.9 s):
S-bias-1: coverage 0.9590 (MCSE 0.0063), distance to 0.95 +0.0090 (+1.4 MCSE); n_sim 1000, seed 20261106, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
S-bias-2: coverage 0.9520 (MCSE 0.0068), distance to 0.95 +0.0020 (+0.3 MCSE); n_sim 1000, seed 20261107, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
```

Der erweiterte Lauf mit dem Filter
`'^(m3a-|m1a-7|m1b-7|m1c-5|m1d-4|m2-7)'` und dem Label
`'M3a and integration acceptance'` endete mit Exit 1
(`acceptance-integration.log`). Alle M3a-Blöcke, die vorhandenen
Vignetten-/ClinVar-Prüfungen und der fachliche AP1-Auswertungsvergleich
liefen durch. Ein bestehender M2-HTTP-Mock scheiterte am lokalen
Socketverbot; M3a-B2 unten enthält den vollständigen relevanten Befund.

```text
M3a and integration acceptance: 78 blocks; 0 failed expectations; 1 error blocks; 0 warnings; 0 skips; 2027 passed expectations; elapsed 496.247 s
```

Die vollständigen vorhandenen Unit-/E2E-/Fuzz-Suiten wurden über den
lesenden Testläufer ausgeführt, Exit 0 (`unit-qa-all.log`):

```sh
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' --args tests/testthat tests/e2e tests/fuzz
```

```text
Duration: 169.6 s
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 6866 ]
Duration: 58.3 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 575 ]
Duration: 10.5 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 494 ]
r-tests: pass — 384 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

Der vorhandene Skip in `test-backends.R:32` prüft den Fehlerfall ohne
ellmer und greift, weil ellmer 0.5.0 installiert ist. Nach diesem
Gesamtlauf wurden ausschließlich drei neue Unit-Dateien um die oben
genannten Numerik-/Ausgabefälle ergänzt bzw. die optionale Orakelprüfung
vom Formeltest getrennt; deren Endstand ist im abschließenden gezielten
Lauf und im installierten Kontext geprüft.

### Vignette, installierter Kontext und API

Vor und nach der Produktänderung wurde jeweils in einem frischen Prozess
derselbe ganze Repository-Knit ohne wiederverwendeten Knit-Cache gemessen:

```sh
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/knit.R /mnt/c/Users/Danie/dev/Llmsa/llmsa before /tmp/llmsa-m3a-build-b4z_2rv_
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/knit.R /mnt/c/Users/Danie/dev/Llmsa/llmsa after /tmp/llmsa-m3a-build-b4z_2rv_
```

Beide Exit 0; gleiche R-/Paket-/Kontextkonfiguration und bei der
Nachhermessung keine parallel laufende lokale Test-/Mutationsprüfung.
`knit-before.log` und `knit-after.log`:

```text
before: error=none; new_files=0; lines=1515; elapsed=17.075 s; R=4.6.1; knitr=1.52; llmsa=0.1.0
after: error=none; new_files=0; lines=1559; elapsed=24.085 s; R=4.6.1; knitr=1.52; llmsa=0.1.0
```

Differenz: 7,010 s. Die neu berechnete Tabelle in `after-validation.md`
enthält folgende echte Zeilen; die Helferrechnung meldet 6,8 s:

```text
|scenario |coverage |MCSE     |n_sim |distance to level (MCSE) |finding                 |
|S-bias-1 |0.959000 |0.006270 |1000  |1.435295                 |within report threshold |
|S-bias-2 |0.952000 |0.006760 |1000  |0.295863                 |within report threshold |
```

`python3 /tmp/llmsa-m3a-build-b4z_2rv_/public-check.py` baut eine
öffentliche Paketkopie ohne Harness/geschützte Quellen und ohne
`REPO_ROOT`. Mit der bestehenden Offline-Einstellung
`_R_CHECK_CRAN_INCOMING_REMOTE_=false` und `TZ=Europe/Berlin` führt sie in
`/tmp/llmsa-m3a-build-b4z_2rv_/public/` aus:

```sh
R CMD build --no-manual src
R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Beide Exit 0 (`public/build.log`, `public/check.log`, `public/commands.json`):
Build 107,652 s, Check 354,557 s; beide einschließlich vollständiger
Vignetten. Kein ERROR und kein WARNING, eine NOTE:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
* checking re-building of vignette outputs ... [103s/103s] OK
Status: 1 NOTE
```

Die Uhrzeitprüfung wurde nicht abgeschaltet. Die installierten Tests
melden `[ FAIL 0 | WARN 0 | SKIP 9 | PASS 6790 ]`. Alle neun Skips sind
vorhandene Kontextregeln: fünf externe AP1-Aufzeichnungsfälle, zwei
Originalanker-Vergleiche, der CRAN-Berichtstest und der ellmer-Fehlerfall.

138 Produkt-/Ressourcendateien der geprüften Kopie stimmen bytegleich mit
dem Produkt-Endstand überein (siehe Integritätsprüfung). Die nach dem
Anlegen dieser Paketkopie ergänzten drei neuen Unit-Dateien wurden mit
`public-final-tests.R` nochmals gegen genau dieses installierte Paket
geprüft; `REPO_ROOT` war entfernt, `load_package = "installed"`:

```text
Final public-context additions: 29 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 592 passed expectations; elapsed 3.589 s
Loaded package: /tmp/llmsa-m3a-build-b4z_2rv_/public/llmsa.Rcheck/llmsa; REPO_ROOT: <unset>
```

Der erste temporäre Stagingversuch dieses Zusatzlaufs stoppte vor jedem
Test, weil `file.copy()` das Snapshot-Unterverzeichnis nicht rekursiv
kopierte. `public-final-tests-stage-initial.log` bewahrt den Fehler; nur
das temporäre Kopierskript wurde auf rekursives Kopieren korrigiert.

`TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/api-check.R`,
Exit 0, nutzt beide unveränderten API-Vergleichshelfer aus `setup-m0.R`
ohne dessen Git-bezogene Tests auszuführen (`api-check.log`):

```text
ANK-02 API: 22 snapshot exports preserved; 0 signature violations; independent prefix check TRUE; fleiss fifth with FALSE default.
```

### Lokale Mutationsdiagnose und Integrität

Die Diagnose erzeugt mit den neun Mutatorfamilien des vorhandenen
R-Mutationswerkzeugs 875 Mutanten der gesamten `R/agreement.R`.
Ausführung: `Rscript --vanilla .../mutation-plan.R`, anschließend
`python3 .../run-mutation-probe.py` unter dem oben genannten Temp-Pfad.
14 lokale R-Prozesse führen die schnellen Agreement-/Bias-Unit-Tests
und, sofern diese noch keinen Fehler finden, die unveränderten
M3a-Abnahmetests 1–6 aus. Vignetten- und Klasse-A-Simulation sind nicht
Teil dieser lokalen Diagnose; das ist kein regulärer mutgate-Lauf.
Jeder Mutant, seine Quelle und sein eigener Ergebnis-/Logpfad stehen
unter `mutation/`. Der erste Lauf dauerte 547,31 s:

```text
Final diagnostic counts: {'Survived': 111, 'Killed': 762, 'CompileError': 2}
Detected 762/873 parseable mutants (87.29%); no gate verdict
```

Die Diagnose zeigte fehlende Testunterscheidungen für ein geneigtes
inneres Bandextremum, endliche Regressionsresultate trotz überlaufender
Zwischenterme und vertauschte Reproduzierbarkeits-Druckfelder. Ergänzt
wurden analytische Zeugen bzw. unabhängige begrenzte OLS-Gegenrechnungen
und eine handzählbare Druckfixture mit verschiedenen Raten. Produktcode
und Schwellen wurden dabei nicht geändert. Danach rechnet
`python3 /tmp/llmsa-m3a-build-b4z_2rv_/rerun-mutation.py` die unmutierte
Kontrolle und alle 111 überlebenden Mutanten mit den finalen Unit-Tests
erneut; die 762 bereits erkannten und zwei nicht parsbaren bleiben im
Ergebnis erhalten. Exit 0, 150,88 s (`mutation-final.log`):

```text
Final tests, unmutated diagnostic: {"status": "Survived", "failed": 0, "errors": 0, "warnings": 0, "skipped": 0, "passed": 1459, "elapsed": 15.097, "wall_seconds": 15.303903992986307}
111/111: {'Killed': 23, 'Survived': 88}
Final diagnostic counts: {'Survived': 88, 'Killed': 785, 'CompileError': 2}
Detected 785/873 parseable mutants (89.92%); no gate verdict
```

Alle überlebenden Mutanten bleiben im Nenner; es gibt keine Ausnahmen,
keine behauptete Äquivalenz und keinen Timeout-/Harnessfehler.
`mutation-final/diagnostic-results.json` und `test-hashes.json` halten
den zusammengeführten Befund und die finalen Unit-Dateihashes fest.
Produkt-SHA-256 dieser Läufe:
`0d60fd2085f5c055165530c0738d850c738a4c4fb9309fd463a1b3f24f2d8794`.
Regulärer Mutationsscope, Ratchet und Gate-Verdict bleiben beim Betreiber.

Der lesende SHA-256-Vergleich `python3 .../integrity.py`, Exit 0, prüft
die 211 vor BUILD erfassten geschützten Dateien, neue Dateien in den
erfassten geschützten Verzeichnissen, den Produktstand des Paketchecks
und die wiederverwendeten Ankerkopien (`integrity.log`):

```json
{
  "protected_files": 211,
  "changed_or_missing": [],
  "additional_protected_files": [],
  "public_check_current_product_files": 138,
  "public_check_product_differences": [],
  "reused_anchor_copies_identical": {
    "ANK-06.json": true,
    "ANK-TOL.json": true
  },
  "agreement_sha256": "0d60fd2085f5c055165530c0738d850c738a4c4fb9309fd463a1b3f24f2d8794"
}
```

### Handoff-Befunde und Grenzen

- **M3a-B1 (nonblocking, Orakelhinweis).** `ref`: K-M3a-3,
  Formelsammlung §5 (Normierung mit `m_u - 1`). Die installierte
  `irr::kripp.alpha()` 0.85 setzt bei vollständig beobachteten Matrizen
  `mc <- rep(1, dimx[2])`, auch bei mehr als zwei Beurteilern. Eine
  zusätzliche vollständig fehlende Beurteilerzeile verändert keinen
  gültigen Wert oder Vergleich, aktiviert aber den richtigen
  `apply(x, 2, vn) - 1`-Zweig. Der neue Unit-Orakeladapter verwendet diese
  Darstellung; eine eigene vollständige Paarzählung steht ohne
  Orakelabhängigkeit daneben. Die Produktformel wurde nicht an den
  fehlerhaften Orakelzweig angepasst. Vorschlag an den Reviewer:
  Einschränkung bei künftigen vollständigen Mehrbeurteiler-Orakelfällen
  berücksichtigen. Reproduktion:
  `Rscript --vanilla /tmp/llmsa-m3a-build-b4z_2rv_/oracle-alpha.R`, Exit 0.
  Synthetische Itemzeilen: `(1,1,2)`, `(2,3,2)`, `(3,1,3)`, `(1,2,2)`,
  `(3,3,3)`; 15 gültige Bewertungen vor und nach dem Anhängen. Output:

  ```text
     metric          llmsa pair_enumeration   irr_complete irr_missing_coder
    nominal 0.243243243243   0.243243243243 0.216216216216    0.243243243243
    ordinal 0.356094276094   0.356094276094 0.333097643098    0.356094276094
   interval 0.328767123288   0.328767123288 0.304794520548    0.328767123288
  ```

- **M3a-B2 [INFRA] (für den Builder nonblocking).** `ref`:
  `tests/acceptance/test-m2-7-robustness-pilot.R:175`,
  `tests/acceptance/setup-m2.R:787`, K-M2-7. Der vorhandene HTTP-Mock
  verwendet `httr2::req_dry_run()` und damit einen lokalen Echo-Server.
  Der Socket ist in dieser Sandbox verboten. Der erweiterte Testlauf
  ist deshalb ausdrücklich nicht vollständig grün. Vorschlag für
  Betreiber/Reviewer bzw. BACKLOG: unveränderten Test im vorgesehenen
  Gate-Kontext mit lokaler Socketunterstützung ausführen. Kein Scheinfix
  im Produkt und kein Eingriff in den Test. Relevanter Originaloutput:

  ```text
  Error ('test-m2-7-robustness-pilot.R:175:5')
  Error: System failure for: socket() (Operation not permitted)
  1. acc_m2_backend(s, system = cs$arg)(...)
  2. httr2::req_perform(req) at llmsa/R/backends.R:177:5
  4. httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:787:5
  5. curl::curl_echo(handle, progress = FALSE)
  6. httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
  ```

Alle hier genannten Ergebnisse sind lokale ausgeführte Befunde, keine
Builder-Abnahme. Die vollständige Git-basierte historische Abnahme,
reguläre Gates einschließlich Territory/Trace/Mutation, unabhängige QA,
Windows-CI sowie Commit bleiben beim Orchestrator/Reviewer/Betreiber.
Keine Git-Kommandos, keine Änderungen an Abnahmetests, Quellen, Ankern,
Gates oder Betreiberzustand. Die Systemzeit-NOTE und der M2-Socketfehler
bleiben sichtbar; keine dieser Prüfungen wurde für ein grünes Ergebnis
abgeschwächt.

## M3b — BUILD, Runde 1 (04.11.2026)

Der freigegebene PLAN ist umgesetzt; Grundlage sind PLAN-REVIEW mit
`verdict-plan.json: PASS`, ADR-050 und ADR-051. Keine PLAN-UPDATE- oder
ARBITER-Datei vorhanden. Keine Planabweichung, kein neuer Builder-ADR,
keine neue Vertragslücke. Die Antworten auf E1–E3 und ACC-1–ACC-15 stehen
im zugewiesenen [REVIEW-INPUT.md](orchestrator/handoff/M3b/REVIEW-INPUT.md).
Die Vertagungen des PLAN, insbesondere BL-125/BL-126, bleiben bestehen.

**Nachtrag zu M1d:** Die inzwischen vorliegenden Betreiberfakten
`orchestrator/state/M1d/gates.json` nennen Runde 5, `result: pass` und
acht bestandene Gates (deps, lint, tests, trace, territory, mutgate,
golden-adr, mutfull). `orchestrator/handoff/M1d/verdict-code.json` enthält
Runde 5, `verdict: PASS`, `blocking: []`. Das aktualisiert den damaligen
Kenntnisstand des unverändert erhaltenen Eintrags unten; es ist kein
erneuter Gate-Lauf dieser BUILD-Phase. E16/BL-119, E18/BL-117 und
E19/BL-121 bleiben nach diesem Verdict nonblocking.

### Umsetzung und Prüfgrenzen

`msa_robustness()` erhält als fünftes Argument `transform = "none"`.
Nur die einzelnen Zeichenwerte `"none"` und `"logit"` sind zulässig.
Der neue Logit-Pfad verlangt reelle, endliche numerische Vektoren strikt
zwischen 0 und 1; Matrizen, Arrays, komplexe Werte, Grenzen und sonstige
ungültige Werte scheitern benannt vor der Transformation. Bestehende
Längen- und NA-Fehler bleiben erhalten. Danach wird genau einmal
`stats::qlogis()` angewandt, ohne Randkorrektur. Der Standardpfad und
das vollständige Ergebnisschema bleiben erhalten, ebenso PB-Konstruktion,
Lenth-Rechenfolge und Druckmethoden. Der bestehende AP1-Aufruf verwendet
weiterhin den Standardpfad für seine bereits transformierten Antworten.

Die Half-Normal-Achse nennt Daniel (1959). Roxygen und erzeugte Hilfe
erklären das konservative ME-/SME-Verfahren, nominales `alpha`, den
zulässigen Logit-Bereich und die Skala einschließlich Antwortmittelwert
und -standardabweichung. FrF2, DoE.base und unrepx stehen jetzt in
Suggests; keine Imports, Exporte oder eingefrorenen Abhängigkeiten geändert.
NEWS und ein kurzer englischer Methodenabschnitt in `validation.Rmd`
dokumentieren M3b. Die Vignette erhält weder abgetippte Ergebnisse oder
Toleranzen noch neue ausführbare Chunks oder `source()`-Aufrufe.

Zwei neue Unit-Dateien ergänzen 19 Blöcke mit 489 Erwartungen:
unabhängige Logit-/Regressionsgegenrechnung, ganze Standardobjekte,
Fehlerklassen, RNG-Erhaltung, Faktor-Metadaten, Invarianzen,
verschwindende/kleine PSE, komplette Druckausgaben und die tatsächlich
aufgezeichnete Grafik. Der erste Lauf hatte eine falsche Erwartung im
neuen Test: automatische data.frame-Zeilennamen wurden mit den fehlenden
Matrix-Zeilennamen verglichen. Nur dieser neue Test normalisiert jetzt
die Zeilennamen vor dem weiterhin vollständigen Matrixvergleich.
`unit-initial.log` enthält den ursprünglichen Fehler; vorhandene Tests
und Abnahmetests wurden nicht geändert.

Alle folgenden Prüfungen sind lokale ausgeführte Befunde. Vollständige
Git-basierte Prüfungen K-M1d-8/K-M0-7, reguläre Gates, QA, Commit und
Abnahme bleiben beim Orchestrator beziehungsweise Reviewer. Kein eigener
Gate-Status und kein Builder-Verdict. Keine Git-Kommandos ausgeführt.

### Umgebung, Befehle und echte Outputs

Rohlogs und Hilfsskripte: `/tmp/llmsa-m3b-build-22ktixdh/`.
R 4.6.1 (2026-06-24), testthat 3.3.2, pkgload 1.5.3,
roxygen2 8.1.1, FrF2 2.3.5, DoE.base 1.2.5, unrepx 1.0.2,
muttest 0.3.0. Keine Installation oder Aktualisierung.
`Rscript --vanilla orchestrator/lib/r-deps.R --check-only`, Exit 0:

```text
r-deps: pass — 28 Anforderungen erfüllt (R 4.6.1)
```

Die drei geschützten Lenth-Tabellen stimmen mit den SHA-256 aus ANK-81
überein; `QUELLE.txt` ist vorhanden. Die installierbare numerische
ANK-TOL-Kopie ist bytegleich mit dem Original. Die Mutations-Baseline
`orchestrator/state/mut-baseline` fehlt wie im PLAN vorgesehen.

Rd-Erzeugung in der temporären Paketkopie, Exit 0 (`roxygen.log`):

```sh
Rscript --vanilla -e 'roxygen2::roxygenise("/tmp/llmsa-m3b-build-22ktixdh/docs-src", roclets = "rd")'
```

```text
ℹ Setting Config/roxygen2/version to "8.1.1"
ℹ Loading llmsa
Writing 'msa_robustness.Rd'
Writing 'llmsa-package.Rd'
```

Übernommen wurde ausschließlich `man/msa_robustness.Rd`, bytegleich mit
diesem Output. Andere Rd-Dateien und NAMESPACE bleiben unverändert.

Der temporäre `run-suite.R` setzt `REPO_ROOT` und `NOT_CRAN=true`, öffnet
ein Null-PDF-Gerät und ruft `testthat::test_dir(load_package = "source",
reporter = "summary", stop_on_failure = FALSE)` mit dem angegebenen Filter
auf. Seine Zusammenfassung zählt den echten testthat-Ergebnisrahmen;
Fehler oder fehlgeschlagene Erwartungen führen zu Exit 1. Ausgeführt im
Repository mit `TZ=Europe/Berlin`, jeweils Exit 0:

```sh
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3b-build-22ktixdh/run-suite.R tests/testthat '^robustness-' 'M3b unit'
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3b-build-22ktixdh/run-suite.R tests/acceptance '^m3b-' 'M3b acceptance'
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3b-build-22ktixdh/run-suite.R tests/simulation '^lenth-h0$' 'Lenth H0'
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3b-build-22ktixdh/run-suite.R tests/acceptance '^m1[abc]-[57]-vignette' 'Vignette regressions'
```

Maßgebliche unveränderte Outputzeilen aus `unit-final.log`,
`acceptance.log` und `vignette-regression.log`:

```text
M3b unit: 25 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 538 passed expectations; elapsed 6.34 s
test-robustness-plan-spc.R: 6 blocks; failed 0; errors 0; warnings 0; skips 0; passed 49
test-robustness-properties.R: 12 blocks; failed 0; errors 0; warnings 0; skips 0; passed 188
test-robustness-transform.R: 7 blocks; failed 0; errors 0; warnings 0; skips 0; passed 301
M3b acceptance: 27 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 437 passed expectations; elapsed 9.43 s
test-m3b-1-pb-matrices.R: 4 blocks; failed 0; errors 0; warnings 0; skips 0; passed 101
test-m3b-2-frf2.R: 2 blocks; failed 0; errors 0; warnings 0; skips 0; passed 11
test-m3b-3-lenth.R: 7 blocks; failed 0; errors 0; warnings 0; skips 0; passed 183
test-m3b-4-half-normal.R: 3 blocks; failed 0; errors 0; warnings 0; skips 0; passed 15
test-m3b-5-help-page.R: 3 blocks; failed 0; errors 0; warnings 0; skips 0; passed 3
test-m3b-6-design-transform.R: 8 blocks; failed 0; errors 0; warnings 0; skips 0; passed 124
Vignette regressions: 26 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 696 passed expectations; elapsed 137.64 s
```

Vollständige Studienausgabe aus `lenth-h0.log` (die erste Zeile folgt dort
unmittelbar auf die sechs Fortschrittspunkte des Reporters):

```text
K-M3b-5 (tests/simulation/test-lenth-h0.R, 1.8 s):
N = 12,  8 factors: per effect (ME) 0.02325 (MCSE 0.00222), distance to alpha 0.05: -0.02675 (-12.0 MCSE); per plan (SME) 0.01500 (MCSE 0.00384), distance to alpha 0.05: -0.03500 (-9.1 MCSE); n_sim 1000, seed 20261112, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
N = 12, 11 factors: per effect (ME) 0.02891 (MCSE 0.00231), distance to alpha 0.05: -0.02109 (-9.1 MCSE); per plan (SME) 0.02500 (MCSE 0.00494), distance to alpha 0.05: -0.02500 (-5.1 MCSE); n_sim 1000, seed 20261115, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
Lenth H0: 1 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 6 passed expectations; elapsed 4.53 s
```

Alle einzelnen ME-/SME-Entscheidungen stimmen mit der unabhängigen
Mini-Referenz. Die konservativen Raten werden offen berichtet; keine
Nachkalibrierung, keine Änderung an Seeds, ANK-06 oder ANK-TOL.

Vollständige Unit-/E2E-/Fuzz-Regression, Exit 0 (`regression.log`):

```sh
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' --args tests/testthat tests/e2e tests/fuzz
```

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 6230 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 319 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 94 ]
r-tests: pass — 345 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

Der einzige Test-Skip ist der bestehende ellmer-Negativtest, weil ellmer
installiert ist. Das zusätzlich übergebene `--args` wurde vom Runner als
leerer Verzeichnisname gemeldet (`r-tests: --args: keine Testdateien,
übersprungen`); alle drei tatsächlichen Testverzeichnisse wurden vollständig
ausgeführt (52/5/5 Testdateien).

Git-freie Zusatzprüfung gegen den vor BUILD gesicherten Funktionsstand
und die vorhandenen Reviewer-Helfer, Exit 0 (`compatibility.log`):

```sh
TZ=Europe/Berlin Rscript --vanilla /tmp/llmsa-m3b-build-22ktixdh/check-compatibility.R
```

```text
Compatibility: 7 full msa_robustness objects identical to the pre-BUILD functions, with default and explicit none
Logit: 5 full objects identical to the pre-BUILD function on separately transformed responses
AP1 compatibility: 5 full acmg_robustness objects identical; acceptable, marginal and unacceptable all exercised
PB construction and both print methods: formals and function bodies unchanged
API: all 22 exported signatures retain the ANK-02 prefix, checked by both reviewer helpers without Git
Validation vignette: no typed numeric results from any of the four full studies
```

### Lokale Mutationsdiagnose

Die neun Mutatorfamilien des vorhandenen `r-mutation.R` wurden mit
`muttest::muttest_plan()` auf die vollständige endgültige `R/robustness.R`
angewandt. Ausführung über
`python3 /tmp/llmsa-m3b-build-22ktixdh/run-mutation-probe.py`, Exit 0,
mit zwölf unabhängigen R-Prozessen und isolierten Paketkopien außerhalb
des Arbeitsbaums. Jeder Mutant läuft gegen alle `^robustness-`-Unit- und
`^m3b-`-Abnahmedateien. Der unmutierte Vorlauf besteht 975 Erwartungen
ohne Fehler/Warnungen/Skips (12,471 s).

```text
Final diagnostic counts: {'Killed': 299, 'Survived': 9, 'CompileError': 9}
Detected 299/308 parseable mutants (97.08%); no gate verdict
Elapsed 459.11 s
```

Keine Timeouts oder Infrastrukturabbrüche. Die neun Syntaxfehler sind
getrennt ausgewiesen; alle neun Überlebenden bleiben im Nenner. Acht
entsprechen Kandidatentypen aus PLAN-REVIEW E1 Nr. 7. Die neunte Variante
entfernt den letzten Druck-Zeilenumbruch, den `capture.output()` nicht
unterscheidet. Keine MUT-EQUIV-Claims oder eigene Freigaben. Einzelbefunde
und Funktionszuordnung stehen im Handoff und in `mutation-probe.log`,
`mutation/diagnostic-results.json`, `mutation/by-function.log`.
Nachträglich ergänzte Mutatorbezeichnungen ändern keine Quellvariante;
alle 317 SHA-256 blieben gleich (`mutation/metadata.log`).
Dies ersetzt weder den regulären Mutationslauf noch dessen Schwellen-,
Floor- oder Ratchet-Entscheidung.

### Öffentlicher Paketbau und Check

Ausgeführt in `/tmp/llmsa-m3b-build-22ktixdh/public` auf einer Kopie der
öffentlichen Paketdateien, ohne geschützte Originale, API-Aufzeichnungen
oder Harness-Dateien; beide Kommandos Exit 0:

```sh
env -u REPO_ROOT TZ=Europe/Berlin R CMD build --no-manual src
env -u REPO_ROOT TZ=Europe/Berlin _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

`_R_CHECK_CRAN_INCOMING_REMOTE_=false` entspricht der bestehenden
Offline-Einstellung des Paket-Gates; die Systemzeitprüfung blieb aktiv.
Auszüge aus `public/build.log` und `public/check.log`:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
* checking examples ... [11s/11s] OK
* checking examples with --run-donttest ... [105s/105s] OK
* checking tests ...
  Running ‘testthat.R’ [223s/223s]
 [223s/223s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [101s/101s] OK
* DONE
Status: 1 NOTE
```

Keine ERROR-/WARNING-Befunde des Checks; die eine NOTE betrifft die
offline nicht überprüfbare Uhrzeit. Die Logzeile zur nicht erreichbaren
CRAN-Paketliste endet mit bestandenem Abhängigkeiten-Check. Die bekannte
Paketgröße erscheint als INFO (22,3 Mb, davon 20,6 Mb validation; BL-114).
Alle vier gebauten Vignetten und alle vier Vollstudien-Ergebnisdateien
sind im Tarball, ebenso beide neuen Tests und die erzeugte Hilfeseite.
Installierter Testlauf (`public/llmsa.Rcheck/tests/testthat.Rout`):

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 6154 ]
```

Die neun bestehenden Skips betreffen fünf nicht mitgelieferte
API-Aufzeichnungen, einen CRAN-ausgenommenen Berichtstest, zwei Vergleiche
mit den nur im Repository vorhandenen Originalankern sowie den
ellmer-Negativtest. Im Repo-Lauf wurden alle davon bis auf den
ellmer-Negativtest ausgeführt. Keine Skip-Regel geändert.

### Abschlussintegrität

`python3 /tmp/llmsa-m3b-build-22ktixdh/integrity.py`, Exit 0:

```text
Inventory: 445 baseline files; 6 changed; 3 new; 0 removed
Changed: DESCRIPTION
Changed: NEWS.md
Changed: PROGRESS.md
Changed: R/robustness.R
Changed: man/msa_robustness.Rd
Changed: vignettes/validation.Rmd
New: orchestrator/handoff/M3b/REVIEW-INPUT.md
New: tests/testthat/test-robustness-properties.R
New: tests/testthat/test-robustness-transform.R
All 136 pre-existing test files are byte-identical
reference/anchors/: 49 original files byte-identical
reference/quellen/data/: 6 original files byte-identical
inst/extdata/: 24 original files byte-identical
inst/validation/sim/: 32 original files byte-identical
msa_robustness.Rd equals the staged roxygen output byte for byte
Earlier PROGRESS entries preserved byte for byte
All three protected Lenth tables still match ANK-81
Integrity check completed; no territory-gate verdict
```

Alle übrigen 439 inventarisierten Dateien sind bytegleich. Keine
Änderung außerhalb der neun im PLAN genannten Dateien, keine gelöschte
Datei, keine Änderung an Gate-Fakten oder Regeln. Alle Test-, Build- und
Mutationsartefakte liegen außerhalb des Arbeitsbaums. Die Inventur
ersetzt das Territoriums-Gate nicht.

## M1d — REWORK, Runde 5 (04.11.2026)

**K-M1d-5 besteht im gezielten Lauf mit 45 Erwartungen**, ohne Fehler,
Warnungen oder Skips (Exit 0). Die Betreiberergänzung war bereits beim
Beginn dieser Phase in `_pkgdown.yml:36–43` vorhanden: `validation`,
`llm-stability` und `clinvar-raters` stehen unter `articles`.
Die Datei hat 703 Byte und SHA-256
`7e465e038e78aa7b5cd90c2caebd909c74ab588298a1a765a594c00c12c3b671`,
wie vom Reviewer in Runde 4 angegeben. Der Builder hat sie nicht geändert.

**E1 / M1D-INFRA-01 / BL-118: OUT-OF-TERRITORY [INFRA],
Betreiberergänzung vorhanden und lokal erfolgreich geprüft.** Das alte
Gate-Log der Runde 4 belegt noch die drei Listungsfehler
(`gate-tests.log:1189–1207`, `:1831–1849`). Der aktuelle Lauf der
vollständigen unveränderten Abnahmedatei endet dagegen mit:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]
K-M1d-5 acceptance: 5.77 seconds; exit 0
```

Prüfbefehl, Dateizuordnungen und Antworten auf sämtliche aktuellen
Befund-IDs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1d/REWORK-NOTES.md).
Lokales Log: `/tmp/llmsa-m1d-r5-3pltfgx8/pkgdown-acceptance.log`.
Die Gate-Fakten bleiben unverändert **Runde 4, `result: fail`**:
sieben Gates grün, nur `tests` rot, kein Status `error`. Ein Gate-Ergebnis
der Runde 5 oder eine Abnahme wird nicht vorweggenommen.

REVIEW und Verdict Runde 4 enthalten `blocking: []` und verlangen keine
Produktänderung. E16 / BL-119 bleibt bis zur Betreiberentscheidung vor
der Paper-Verwendung zurückgestellt; E18 / QA-M1d-001 / BL-117 und
E19 / BL-121 bleiben bis nach dem 26.11.2026 vertagt. E17, E2–E15 und
M1D-QA-01 sind laut REVIEW erledigt; kein offener QA-PENDING-Auftrag.
BL-93 bleibt mit den beiden Warnungen aus `gate-tests.log:778–803`
OUT-OF-TERRITORY (Reviewer). Eine ARBITER.md zu M1d liegt nicht vor.

Geändert werden nur dieser Nachtrag und der zugewiesene Handoff.
Keine Produkt-, Test-, Daten-, Gate- oder Schwellenänderung, kein neuer
ADR. mutgate/mutfull sind laut Gate-Fakten Runde 4 grün (ADR-047);
kein eigener Mutationslauf, keine MUT-EQUIV-Claims oder Approvals.
Keine Git-Kommandos. Vollständige Gates, Territoriumsprüfung,
Phasen-Commit und Abnahme bleiben bei Orchestrator und Reviewer.

Die SHA-256-Inventur (`python3 /tmp/llmsa-m1d-r5-3pltfgx8/integrity.py`,
Exit 0) bestätigt: `462 baseline files; 2 changed; 0 new; 0 removed`.
Alle übrigen 460 inventarisierten Dateien sind bytegleich, darunter alle
127 Testdateien, `_pkgdown.yml` und die Gate-Fakten. Die früheren
PROGRESS-Einträge sind bytegleich erhalten. Vollständiger Output im
Handoff; die Inventur ersetzt kein Territoriums-Gate.

## M1d — REWORK, Runde 4 (04.11.2026)

REVIEW und Verdict der Runde 3 enthalten `blocking: []`. Für Runde 4
verlangt der Reviewer ausdrücklich ausschließlich die Antworten im Handoff;
Produkt, DESCRIPTION, Vignetten, Daten und Tests werden nicht geändert.
Die gelesenen Gate-Fakten bleiben Runde 3, `result: fail`: sieben Gates
sind `pass`, ausschließlich `tests` ist rot, kein Status `error`.

**E1 / M1D-INFRA-01 / BL-118 bleibt OUT-OF-TERRITORY [INFRA]**
nach ADR-048 Nr. 15. `_pkgdown.yml` enthält weiterhin keinen Abschnitt
`articles`. Das Gate-Log der Runde 3 belegt die drei Listungsfehler
(`gate-tests.log:1192–1210`, `:1830–1851`). Die unveränderte vollständige
Abnahmedatei K-M1d-5 wurde gezielt erneut ausgeführt. Echter Output:

```text
Expected _pkgdown.yml has an articles section to be TRUE.
Expected llm-stability is listed under articles to be TRUE.
Expected clinvar-raters is listed under articles to be TRUE.
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]
K-M1d-5 acceptance: 5.76 seconds; exit 1
```

Prüfbefehl, Zuordnung zu den Dateien und konkrete Betreiberergänzung mit
`validation`, `llm-stability` und `clinvar-raters` stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1d/REWORK-NOTES.md).
Lokales Log: `/tmp/llmsa-m1d-r4-f1rjqj2b/pkgdown-acceptance.log`.
Der Betreiber muss die Ergänzung außerhalb einer laufenden Modellphase
als Basis einer folgenden Modellphase umsetzen (BL-106).

E16 / BL-119 bleibt bis zur Betreiberentscheidung vor der Paper-Verwendung
zurückgestellt. E18 / QA-M1d-001 / BL-117 bleibt nach ADR-035 auf nach dem
26.11.2026 vertagt. **E19 / BL-121** bleibt ebenfalls ausdrücklich bis zur
Release-Arbeit nach dem 26.11.2026 zurückgestellt: Die Seiten-URL fehlt
im URL-Feld von DESCRIPTION; der Beleg stammt aus REVIEW Runde 3,
Prüflauf 2. Kein eigener neuer pkgdown-Prüflauf. E17 ist laut Review
erledigt; E2–E15 und M1D-QA-01 ebenfalls. Kein offener QA-PENDING-Auftrag.
BL-93 bleibt mit den beiden Warnungen in `gate-tests.log:779–804`
OUT-OF-TERRITORY (Reviewer). ARBITER.md zu M1d liegt nicht vor.

Diese Runde aktualisiert nur PROGRESS und den zugewiesenen Handoff.
Kein neuer ADR, Test, Mutationslauf oder vollständiger Gate-Lauf;
mutgate und mutfull sind laut Gate-Fakten der Runde 3 grün (ADR-047),
kein eigener Mutationsscore. Keine MUT-EQUIV-Claims, keine Approvals
und keine Git-Kommandos. E1 ist reproduziert und weiter offen;
eine Abnahme wird nicht behauptet.

Die SHA-256-Inventur (`python3 /tmp/llmsa-m1d-r4-f1rjqj2b/integrity.py`,
Exit 0) bestätigt den Umfang. Echter Output (Auszug):

```text
Inventory: 445 baseline files; 2 changed; 0 new; 0 removed
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1d/REWORK-NOTES.md
All 443 other inventoried files are byte-identical
Preserved tests/: 127/127 byte-identical
Gate facts unchanged: round 3; result fail; error statuses 0
Current review IDs addressed: E1, E16, E18, E19
Earlier PROGRESS entries preserved byte for byte
```

Der vollständige Output steht im Handoff; die Inventur ersetzt kein
Territoriums-Gate.

## M1d — REWORK, Runde 3 (04.11.2026)

REVIEW und Verdict der Runde 2 enthalten `blocking: []` und nennen
keinen Pflichtpunkt für den Builder. Die gelesenen Gate-Fakten bleiben
Runde 2, `result: fail`: ausschließlich `tests` ist rot, wegen der
fehlenden Artikelliste in der Betreiberdatei `_pkgdown.yml` (E1);
sieben Gates sind `pass`, kein Status `error`.

**E1 / M1D-INFRA-01 / BL-118 bleibt OUT-OF-TERRITORY [INFRA]**
nach ADR-048 Nr. 15. Der unveränderte Abnahmetest K-M1d-5 wurde gezielt
erneut ausgeführt und reproduziert genau die drei Listungsfehler.
Befehl und vollständige Zuordnung stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1d/REWORK-NOTES.md);
lokales Log: `/tmp/llmsa-m1d-r3-56fg7bcz/pkgdown-acceptance.log`.
Echter Output:

```text
Expected _pkgdown.yml has an articles section to be TRUE.
Expected llm-stability is listed under articles to be TRUE.
Expected clinvar-raters is listed under articles to be TRUE.
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]
K-M1d-5 acceptance: 5.77 seconds; exit 1
```

E16 / BL-119 bleibt wie verlangt bis zur Betreiberentscheidung vor der
Paper-Verwendung zurückgestellt. E17 / BL-120 ist laut REVIEW Runde 2
erledigt. E18 / QA-M1d-001 / BL-117 bleibt nach ADR-035 auf nach dem
26.11.2026 vertagt. E2–E15 und M1D-QA-01 sind laut REVIEW erledigt;
kein offener QA-PENDING-Auftrag. BL-93 bleibt mit den beiden Warnungen
in `gate-tests.log:780–805` OUT-OF-TERRITORY (Reviewer).
ARBITER.md zu M1d ist nicht vorhanden.

Diese Runde ändert ausschließlich PROGRESS und den zugewiesenen Handoff.
Kein neuer ADR, Test, Mutationslauf oder vollständiger Gate-Lauf;
mutgate/mutfull sind laut Gate-Fakten der Runde 2 grün (ADR-047).
Keine MUT-EQUIV-Claims und keine Git-Kommandos. Die konkrete
Betreiberergänzung für `articles` mit `validation`, `llm-stability`
und `clinvar-raters` sowie der Verweis auf den zulässigen Zeitpunkt
stehen im Handoff. Eine Abnahme wird nicht behauptet.

Die SHA-256-Inventur dieser Runde (`integrity.py`, Exit 0) bestätigt
440 Ausgangsdateien: ausschließlich PROGRESS und REWORK-NOTES geändert,
keine neuen oder entfernten Dateien, alle übrigen 438 bytegleich,
darunter alle 127 Testdateien. Die bisherigen PROGRESS-Einträge sind
bytegleich erhalten. Echter Output und Prüfbefehl stehen im Handoff;
die Inventur ersetzt kein Territoriums-Gate.

## M1d — REWORK, Runde 2 (04.11.2026)

REVIEW Runde 1 enthält keine blocking-Befunde. Die gelesenen Gate-Fakten
bleiben Runde 1, `result: fail`; ausschließlich `tests` ist rot, wegen
E1 in der Betreiberdatei `_pkgdown.yml`. Kein Status `error`.
Der optionale Darstellungspunkt **E17 / BL-120** ist umgesetzt:

- `vignettes/validation.Rmd` gibt die Szenarien der
  Konvergenz-Sensitivität sortiert aus (S-ord-1 bis S-ord-4).
- `vignettes/clinvar-raters.Rmd` nennt die Häufigkeitsspalte der
  Statustabelle `submissions` statt `Freq`.

Antworten auf alle aktuellen Befund-IDs, Referenzen, vollständige
Prüfkommandos und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1d/REWORK-NOTES.md).
**E1 / M1D-INFRA-01 / BL-118 bleibt OUT-OF-TERRITORY [INFRA]**;
der Betreiber muss die Artikelliste ergänzen. E16 / BL-119 bleibt wie
verlangt außerhalb dieser M1d-Änderung; E18 / QA-M1d-001 / BL-117 bleibt
nach ADR-035 bis nach dem 26.11.2026 zurückgestellt. E2–E15 sind laut
REVIEW erledigt. Der historische M1D-QA-01 ist durch `45-qa` erledigt;
kein offener QA-PENDING-Auftrag. Eine ARBITER.md zu M1d liegt nicht vor.

Gezielte Prüfungen auf den endgültigen Vignetten (Logs unter
`/tmp/llmsa-m1d-r2-cdsfmtsl/`):

```text
Vignette acceptance: 87.28 seconds; exit 0
SummaryReporter: 6 files; 802 passes; 0 failures; 0 warnings; 0 skips
K-M1d-5 acceptance: 5.10 seconds; exit 1
SummaryReporter: 1 files; 42 passes; 3 failures; 0 warnings; 0 skips
HTML render: validation completed in public context
HTML render: clinvar-raters completed in public context
Review-status columns: subset, review_status, submissions, retained
Public rendering: 28.64 seconds; exit 0
```

Die SummaryReporter-Zahlen stammen aus der ausgeführten Logauswertung
`summarize.py`. Der Vignettenfilter lautet
`^m1[abc]-[57]-vignette|^m1d-4-`; die drei Fehler von K-M1d-5 sind
erneut genau die fehlende Artikelsektion und ihre beiden Vignetteneinträge
(`gate-tests.log` Runde 1, Zeilen 1193–1213; aktuelles lokales Log
`pkgdown-acceptance.log`). Das öffentliche HTML-Rendering und die Kontrolle
des erzeugten Markdown belegen die Reihenfolge und Spaltenbeschriftung.

Keine fachliche Rechenänderung, keine neuen Tests, kein neuer ADR und kein
Mutationslauf; mutgate/mutfull sind laut bestehenden Gate-Logs grün
(ADR-047). Keine MUT-EQUIV-Claims. Die vollständigen Gates und
Git-verwendenden Abnahmepfade führt der Orchestrator aus; hier keine
Abnahme oder neuer Gate-Score behauptet. Keine Git-Kommandos.

Die abschließende SHA-256-Inventur (`integrity.py`, Exit 0) erfasst 430
Ausgangsdateien: drei geändert (beide Vignetten und PROGRESS), ein neuer
zugewiesener Handoff, keine entfernte Datei. Alle 127 Testdateien,
R-Code, Rd-Hilfen, Datenskripte, Golden-Daten, Anker, Studiendateien,
Gates und die geprüften Gate-Fakten sind bytegleich. Details und echter
Output stehen in REWORK-NOTES; die Inventur ersetzt kein Gate.

## M1d — BUILD (04.11.2026)

Der freigegebene PLAN mit den Präzisierungen E2–E15 aus PLAN-REVIEW ist
umgesetzt. [ADR-049](docs/decisions/ADR-049-m1d-daten-und-validierungsressourcen.md)
dokumentiert die Golden-Daten, die abschließende Parserregel, das
Locale-unabhängige Dateiformat und die installierten Validierungsressourcen;
keine fachliche Planabweichung. Zugewiesener Handoff mit Antworten auf alle
Einwand-IDs und konkreten Vorschlägen für fremde Territorien:
[REVIEW-INPUT.md](orchestrator/handoff/M1d/REVIEW-INPUT.md).

Aktualisierung des zuvor letzten Eintrags: M1c ist abgenommen. Die gelesenen
Gate-Fakten vom 03.11.2026, 13:25:55+01:00, enthalten acht `pass`;
`verdict-code.json` meldet Runde 1, `PASS`, `blocking: []`. Der dort gemessene
Mutationsscore beträgt 92,8 %, erforderlich waren 92,09 %. ADR-047 übernimmt
diesen Beleg für M1d; hier wurde kein neuer Mutationsscore gemessen. Die
historischen Einträge darunter bleiben unverändert.

### Umsetzung

- `data-raw/make_llm_stability.R` prüft die ANK-40-Quellen und das vollständige
  Gitter. Der Parser hat keinen Lösungsschlüssel als Argument; fehlende und
  mehrdeutige Antworten bleiben NA. QUELLE zählt die drei Fehlgründe und
  erklärt die zwei Text-Schlüssel in `ruin_names` samt Auswirkung auf die
  Trefferquote. Die Vignette berechnet Wiederholbarkeit, Trefferquote,
  Fehlanteil und alle acht binären Probit-Fits einschließlich Diagnosen.
- `make_clinvar_subsets.R` filtert vor Einreicherzählung und Stichprobe,
  erhält alle SCVs, prüft Genzuordnungen und zählt ausgeschlossene Begriffe
  vor den Schwellen. Die Vignette zeigt Alpha, exakte Übereinstimmung,
  Konflikte, beide ordinalen Fits und die Status-Sensitivität mit ihren
  tatsächlichen Nennern. Literaturzahlen kommen vollständig aus den
  installierten, hashgeprüften ANK-42–ANK-46-Kopien.
- `validation.Rmd` berichtet alle vier Betreiber-Vollläufe, 428 verlangte
  Wert/MCSE-Paare und 19 dynamisch abgeleitete Befunde. BL-92 ergänzt eine
  unabhängige Auswertung der ordinalen Replikate mit getrennten Nennern für
  alle endlichen und konvergierte endliche Schätzungen: 50 Tabellenzeilen,
  Bias/relativer Bias/EmpSE mit MCSE. Singuläre endliche Fits bleiben erhalten.
- `R/fit.R` und `R/grr.R` ändern ausschließlich roxygen; die erzeugten Rd
  nennen alle betreffenden Szenarien und die Vignette. Print und Report
  verwenden den K-M1d-8-Wortlaut samt faktorbezogenen ME/SME-Zusätzen.
  Robustheitsobjekte und AP1-Bänder bleiben unverändert.
- Zwei neue Unit-Dateien prüfen allgemeine Parser-/Auswahlfälle,
  Gitterfehler, RNG-/Reihenfolgeinvarianz, UTF-8/Quoting/Locale, Publikation,
  Ankerintegrität, Befundgrenzen, MCSE und die Sensitivitätsnenner. Bestehende
  Tests, Anker, Abhängigkeiten und sämtliche Betreiber-Studiendateien wurden
  nicht geändert. NEWS und Ressourcen-README sind ergänzt.

### Ausgeführte Daten- und Ressourcenaufbereitung

Arbeits-/Rohlogverzeichnis: `/tmp/llmsa-m1d-build-w4061qzp/` (nachfolgend
`$work`). R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4,
roxygen2 8.1.1; ausschließlich vorhandene eingefrorene Abhängigkeiten.
Paketinstallation erfolgte nur für das eigene Paket in der öffentlichen
temporären Baukopie. Keine Git-Kommandos und keine Modellaufrufe.

```sh
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
Rscript --vanilla data-raw/make_llm_stability.R
Rscript --vanilla data-raw/make_clinvar_subsets.R
Rscript --vanilla data-raw/make_validation_m1d.R
Rscript --vanilla data-raw/make_validation_m1d.R --out "$work/resources-reproduction"
```

Echte Outputs; die ersten beiden Datenskripte wurden zusätzlich mit
`/usr/bin/time` gemessen (`llm-data.log`, `clinvar-data.log`):

```text
r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)
llm-stability: 82850 rows; 11070 missing answers; 2 non-label keys; 258865 bytes published
ambiguous     empty  no_label    parsed
     8974       155      1941     71780
llm-stability preparation: 13.65 seconds; peak RSS 187196 KB; exit 0
ClinVar: 450290 eligible variants; HRF 6647 rows / 1383 variants; sample 5010 rows / 1000 variants
Excluded before thresholds: HRF 501; all 43886; 117822 bytes published
ClinVar preparation: 277.61 seconds; peak RSS 1449860 KB; exit 0
M1d validation inputs: 11 byte-identical anchors; SHA-256 provenance recorded
M1d resources: 11 whole anchors and SOURCES.json reproduced byte for byte
```

Die Archivextraktion meldet ignorierte macOS-Extended-Header (`LIBARCHIVE.xattr`),
endet aber mit Exit 0. Weder Zeilen noch Aufgaben werden deswegen ausgelassen.

Unabhängige Reproduktion in `$work/locale-package/llmsa`, mit Kopien der
Generatoren/Anker/Ressourcen und einem lesenden Link auf die Originalquellen:

```sh
LC_ALL=C Rscript --vanilla data-raw/make_llm_stability.R
LC_ALL=C Rscript --vanilla data-raw/make_clinvar_subsets.R
```

Echter Output des vollständigen zweiten ClinVar-Laufs und des anschließenden
SHA-256-Vergleichs (`locale-clinvar.log`, `locale-reproduction.log`):

```text
ClinVar: 450290 eligible variants; HRF 6647 rows / 1383 variants; sample 5010 rows / 1000 variants
Excluded before thresholds: HRF 501; all 43886; 117822 bytes published
C-locale ClinVar preparation: 408.75 seconds; peak RSS 1435424 KB; exit 0
C-locale regeneration: all 7 frozen files (including QUELLE and SHA256SUMS) match
```

Die endgültige UTF-8-Korrektur ist zusätzlich durch einen synthetischen
Regressionstest unter `LC_CTYPE=C` belegt. Textverbindungen mit expliziter
Transkodierung verloren dort Zeichen; `write.table()` schrieb teils
`<U+...>`. Der Generator liest TSV binär und serialisiert die drei
verwendeten CSV-Typen mit `writeLines(useBytes=TRUE)`. Die CSV-Leser behalten
Textverbindungen für `read.csv()` und markieren die Bytes über dessen
`encoding`-Argument. Das eingefrorene Dateiformat änderte sich nicht.
Gesamtgröße von `inst/extdata`: tatsächlich 627.618 Byte.

### Unit-, Regressions- und Abnahmeprüfungen

```sh
TZ=Europe/Berlin Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
Rscript --vanilla -e 'testthat::test_dir("tests/testthat", filter="^m1d-", load_package="source", reporter="summary")'
TZ=Europe/Berlin Rscript --vanilla "$work/run-vignette-contracts.R"
LC_COLLATE=C TZ=Europe/Berlin Rscript --vanilla "$work/run-acceptance.R"
TZ=Europe/Berlin Rscript --vanilla "$work/check-findings-and-baseline.R"
```

Die lokalen Abnahmeskripte setzen `REPO_ROOT` auf die Repository-Wurzel,
`NOT_CRAN=true` und `testthat.progress.max_fails=Inf`. Der letzte vollständige
M1d-Lauf wählt ausschließlich die unveränderten Dateien `^m1d-[1-6]-`,
deren Ausführung kein Git benötigt. Der Vignetten-Regressionsfilter lautet
`^m1[abc]-[57]-vignette|^m1d-[24]-`. K-M1d-7/-8 werden lokal unabhängig mit
den unveränderten Reviewer-Helfern und den gesicherten Vorher-Dateien
geprüft; die vollständigen Git-basierten Abnahmetests bleiben beim Orchestrator.

Echte Outputs (`regression.log`, `m1d-unit-final.log`,
`vignette-contracts.log`, `vignette-final.log`, `acceptance-1-6.log`):

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 5737 ]
[ FAIL 2 | WARN 0 | SKIP 0 | PASS 90 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 43 ]
r-tests: fail — 319 Tests in tests/testthat, tests/e2e, tests/fuzz; 1 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1d unit tests: 15 test blocks; 0 failed expectations; 0 errors; 0 skips; 95 passed expectations
Vignette contracts: 40 test blocks; 0 failed expectations; 0 errors; 0 skips; 915 passed expectations; 112.15 seconds
Final M1d vignette contracts: 14 blocks; 0 failed expectations; 0 errors; 219 passed expectations
M1d acceptance 1-6: 59 test blocks; 3 failed expectations; 0 errors; 0 skips; 4530 passed expectations; 902.26 seconds
```

Der gemeinsame Regressionstest lief vor der letzten UTF-8-Erweiterung.
Danach wurden die endgültigen neuen Unit-Tests, beide neuen Vignetten und
der vollständige öffentliche Paketcheck nochmals ausgeführt. Der eine
Unit-Skip ist der bestehende **Negativtest für fehlendes ellmer**:
`requireNamespace("ellmer")` ist hier TRUE. Die zwei E2E-Fehler betreffen
die veraltete Kurzlaufannahme in einem unveränderten QA-Test (unten).
Die ursprünglichen lokalen Abnahmefehler ohne exportiertes `REPO_ROOT`
sind in `acceptance-initial-without-root.log` erhalten und durch den
abschließenden vollständigen Lauf ersetzt. Ein vorübergehender CSV-Knit-
Fehler bei binärer statt textueller CSV-Verbindung wurde im Produkt behoben;
`vignette-before-reader-fix.log` bewahrt den tatsächlichen Vorläuferoutput.

Git-freie numerische/inhaltliche Nachweise (`findings-baseline.log`):

```text
Baseline: four snapshots match ANK-34; fit.R and grr.R equal after removing only roxygen lines
Findings: all 19 rows match the independent reviewer calculation, including MCSE and direction
Validation: 428 required value/MCSE pairs displayed; 19 findings and all Rd references present; zero typed results or source-tree artifacts
Ordinal convergence sensitivity: 50 summary rows with separate finite-estimate denominators
Robustness: both print/report branches and invisible return checked; five msa_robustness and five acmg_robustness objects identical to ANK-34 snapshots; all three AP1 bands exercised
Git-free findings and baseline verification: completed
```

Die Sensitivität liest je Szenario 1.000 tatsächlich vorhandene Wiederholungen:
nicht konvergiert 9/18/20/16, singulär 812/797/812/789 für S-ord-1/-2/-3/-4;
unbekannte Flags jeweils null. Ihre Anteile und MCSE werden aus diesen Zeilen
gerechnet, nicht als Konstanten in Code oder Vignetten geschrieben.

`implementation-hashes.log` enthält die echte Prüfung aller vier Sessiondateien:
ordinal/binary/two_level `203bc36478f5400b1db3ca42182e290451947f49a9e528d230c3ae0f574da3b8`,
Bootstrap `2dcf076e648ab6d0a957db008a7853a952b33d4dc2bc037d7c0a290cc8bf9d79`.
Alle stimmen unter C.UTF-8 mit dem geladenen Code überein. Der C-Locale-
Sonderlauf oben betrifft ausschließlich die Datenaufbereitung, nicht die
Studienhashes (BL-115).

### Öffentlicher Paketbau

Eine explizite öffentliche Paketkopie unter `$work/package-final/src`
enthält Paketquellen, `inst`, Daten, Vignetten, Handbuch und Unit-Tests.
Geschützte Originalquellen, API-Fixtures und Harness-Dateien werden nicht
kopiert. Befehle im Arbeitsverzeichnis `$work/package-final`:

```sh
env -u REPO_ROOT TZ=Europe/Berlin R CMD build --no-manual src
env -u REPO_ROOT TZ=Europe/Berlin _R_CHECK_CRAN_INCOMING_REMOTE_=false \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Echte Auszüge aus `package-final/build.log` und `package-final/check.log`:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
* checking installed package size ... INFO
  installed size is 22.3Mb
  sub-directories of 1Mb or more:
    validation  20.6Mb
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
* checking tests ...
  Running ‘testthat.R’ [90s/90s]
 [90s/90s] OK
* checking re-building of vignette outputs ... [47s/47s] OK
* DONE
Status: 1 NOTE
```

Build und Check endeten mit Exit 0, ohne ERROR oder WARNING im Checkstatus.
Die Unit-Ausgabe des gebauten Pakets lautet tatsächlich
`[ FAIL 0 | WARN 0 | SKIP 9 | PASS 5665 ]`: fünf bestehende Skips für nicht
mitgelieferte API-Aufzeichnungen, zwei für Originalanker außerhalb des
Tarballs, einmal `skip_on_cran()` im Berichtstest und der ellmer-Negativtest.
Die Repository-Prüfung oben führt die Quell-/Aufzeichnungstests sowie den
Berichtstest aus; für Robustheit wurden beide Berichtsvarianten zusätzlich
tatsächlich gerendert.
Der Clock-Check wurde nicht abgeschaltet. Die lokale Offline-Einstellung
für CRAN-Incoming entspricht `orchestrator/lib/r-check.sh`; dessen
Git-Export wurde nicht aufgerufen. Der Check meldet zusätzlich den offline
nicht erreichbaren CRAN-Paketindex und setzt die Abhängigkeitsprüfung auf OK.
Die Paketgrößenmeldung ist in dieser R-Version INFO; BL-114 bleibt vor CRAN
zu lösen. Der Tarball enthält nach tatsächlicher Inhaltsprüfung alle vier
gerenderten Vignetten und sämtliche zwölf Volllaufdateien.

### Offene Befunde und Integrität

- **E1 / M1D-INFRA-01 [INFRA]**, ref K-M1d-5/ACC-8(5)/PLAN-REVIEW E1:
  fehlendes `articles` in `_pkgdown.yml`, drei rote Erwartungen. Betreiber
  ergänzt `validation`, `llm-stability`, `clinvar-raters`; konkretes YAML im
  Handoff. Kein Builder-Schreibrecht auf diese Datei.
- **M1D-QA-01 [QA-PENDING]**, ref `QA-M1c-E2E-4`,
  `tests/e2e/test-m1c-qa-e2e.R:166–168`, ADR-043 und K-M1d-6:
  Standardleser liefert seit den vorhandenen Vollläufen richtigerweise
  `full`/1.000/sieben Szenarien; der QA-Test erwartet `check` und nur
  S-boot-1/S-boot-7. Zwei Erwartungen in einem Testblock scheitern. Ein
  gesondertes temporäres Kurzlaufverzeichnis liefert nach ausgeführtem
  Kontextcheck unverändert `check`/20/S-boot-1,S-boot-7. Leser, Test und
  Vollläufe sind seit vor BUILD bytegleich. QA soll den Kurzlauf explizit
  isolieren und den Standardordner separat als Volllauf prüfen; kein
  Produkt-Scheinfix, keine Entfernung der Pflichtdaten. BACKLOG liegt bei
  QA/Reviewer; der Handoff enthält den Aufnahmevorschlag.
- Alle ursprünglichen geschützten Dateien und alle zwölf Volllaufdateien
  wurden abschließend gegen die vor BUILD erfassten SHA-256 geprüft.
  Bestehende Tests wurden weder entfernt noch geändert. `R/fit.R` und
  `R/grr.R` sind ohne roxygen-Zeilen identisch zur ANK-34-Basis.
  Die Inventur umfasst 354 ursprüngliche Dateien, darunter 123 bestehende Testdateien; alle Änderungen liegen im zugewiesenen Builder-Umfang.
- Offizielle Gates und Code-Review M1d stehen aus; diese lokalen Belege
  behaupten keine Abnahme. ADR-047-Kontrolllauf nach done/M1d,
  Scope-Rückstellung vor M3a und die übrigen im PLAN begründeten Vertagungen
  bleiben Aufgaben der jeweils zuständigen Rolle.


## M1c — BUILD (02.11.2026)

Der freigegebene PLAN und die Ergänzungen E1–E6 aus PLAN-REVIEW sind
umgesetzt. Einzige zusätzliche Planabweichung: der eigenständige,
generatorfreie Ergebnisleser nach
[ADR-043](docs/decisions/ADR-043-m1c-ergebnisleser-ohne-simulator.md).
K-M1c-6 und die endgültige Abnahme bleiben bei Betreiber und Reviewer.
Zugewiesener BUILD-Handoff:
[REVIEW-INPUT.md](orchestrator/handoff/M1c/REVIEW-INPUT.md).

Aktualisierung des zuvor letzten Eintrags: M1b ist inzwischen abgenommen.
Die gelesenen Gate-Fakten vom 02.11.2026, 09:43:15+01:00, melden acht
`pass`; `verdict-code.json` M1b, Runde 8, enthält `PASS`, `blocking: []`.
Der Mutationsbeleg dazu bleibt der Lauf r7 gemäß ADR-038; in r8 wurde kein
neuer Score gemessen. Die folgenden historischen Einträge bleiben erhalten.

### Umsetzung

- `msa_boot()` ergänzt `n_singular` für endliche singuläre Replikate und
  zählt Zeilen mit nicht endlichen Kennzahlen separat als `n_failed`.
  Die sechs bisherigen Bootstrap-Spalten und die spaltenweise gebildeten
  Typ-7-Quantile bleiben erhalten. Beide Zahlen werden immer gedruckt;
  ältere Objekte melden die nicht erfasste Singularitätszahl ausdrücklich.
- Die latente GRR-Druckausgabe, das Report-Template und `?msa_grr` enthalten
  den verlangten Hinweis. Numerische Ergebnisse ändern sich dadurch nicht.
- Ordinale Fits erhalten ohne benanntes `control` die Grenzen 2000/4000.
  Eigene Steuerungen werden unverändert weitergereicht; direkte Optionen
  in `...` haben die Vorrangregel von `ordinal::clmm()`. Rd und NEWS nennen
  die Grenzen und die beobachtbaren Änderungen.
- Die Klasse-B-Studie implementiert alle sieben spezifizierten Szenarien,
  getrennte Daten-/Bootstrap-Seeds, tatsächliche Fit-/Bootstrap-Zähler,
  Diagnosen, MCSE und einen geprüften Zusammenführer vollständiger
  Szenarioläufe. Ergebniszeilen nennen `n_finite`, `n_failed` und den ersten
  Daten-Seed. Die Vignette liest Ergebnisse ohne Fits oder Simulationen;
  eine vorhandene ungültige Volllaufdatei führt zum Fehler.
- Vier neue Unit-/Property-Testdateien prüfen Randfälle und Invarianzen;
  der bestehende Drucktest wurde an die angeforderten zwei Zeilen
  angepasst. Abnahmetests und QA-Tests wurden nicht verändert.

### Ausgeführte Nachweise

Arbeits- und Rohlogverzeichnis: `/tmp/llmsa-m1c-build-_nxa5o1i/` (nachfolgend
`$work`). Befehle liefen aus dem Repository, soweit kein anderes
Arbeitsverzeichnis genannt ist. R 4.6.1, lme4 2.0.6, ordinal 2026.7.26,
Matrix 1.7.4; ausschließlich vorhandene Abhängigkeiten. Das eigene Paket
wurde aus einer öffentlichen Paketkopie nach `$work/library` installiert.

```sh
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa \
  Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' \
  tests/testthat tests/e2e tests/fuzz
TZ=Europe/Berlin Rscript --vanilla "$work/acceptance.R"
TZ=Europe/Berlin Rscript --vanilla "$work/acceptance-final.R"
```

Echter Output, aus `deps.log`, `unit-qa-final.log`, `acceptance.log` und
`acceptance-final.log` (Fortschrittsanimationen ausgelassen):

```text
r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 5644 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 299 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
[ FAIL 0 | WARN 2 | SKIP 0 | PASS 8124 ]
M1a/M1b/M1c acceptance without Git: 190 test blocks; 0 failed expectations; 0 error blocks; 0 skipped; elapsed 761.822 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3525 ]
Final M1c 3/4/5 acceptance: 20 test blocks; 0 failed expectations; 0 error blocks; 0 skipped; elapsed 258.471 s
```

Der Integrationsfilter umfasst alle M1a-/M1b-Tests sowie alle M1c-Dateien
außer dem Git aufrufenden Bytevergleich. Die zwei Warnungen stammen aus
den bestehenden M1b-Abnahmehelfern (`nobars`/`findbars`, BL-93).
Während dieses Integrationslaufs wurde der Leser nach ADR-043 getrennt;
deshalb wurden **K-M1c-3/-4/-5 nach der endgültigen Neuberechnung nochmals
vollständig** ausgeführt (`^m1c-[345]-`). Alle übrigen geprüften
Produktfunktionen blieben seit Beginn des Integrationslaufs bytegleich.
Der eine Unit-Skip ist die bestehende optionale `ellmer`-Prüfung
(`test-backends.R:32:3`); das Paket ist in der eingefrorenen Umgebung
nicht vorhanden.

Weitere echte lokale Outputs (`core-unit-final.log`, `core-acceptance.log`,
`reader-final.log`, `api-check-final.log`, `byte-equality.log`):

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 180 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 309 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 371 ]
API: 22 exports and 108 original arguments retain names, positions and defaults.
Byte equality verified for 9 GRR cases and 3 bootstrap cases; no Git access.
```

Der Bytevergleich nutzt die vor dem ersten Edit gesicherten Quelldateien,
deren SHA-256 gegen ANK-33 geprüft wurde. Er ersetzt nicht den offiziellen
Git-basierten Abnahmetest. Keine Abnahmedatei wurde kopiert und umgeschrieben.

### Echte Kurzläufe und Paketcheck

Jeweils `R_LIBS=$work/library TZ=Europe/Berlin Rscript --vanilla
inst/validation/sim/<study>.R --n-sim 20 --out <frisches Verzeichnis>`;
für Bootstrap zusätzlich `--scenarios S-boot-1,S-boot-7`. Die 20 stammen
aus ANK-TOL.n_check. Alle vier Aufrufe endeten mit Exit 0:

```text
boot_coverage: 2 scenarios x 20 repetitions; 96 result rows; elapsed 176.562 s; workers 14
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 167.588 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.937 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 9.007 s; workers 14
Serial reverse-order run: all 38 rows and 24 replicate columns equal the 14-worker, 20-repetition prefix at 15 digits.
```

Alle zwölf Kurzlauf-Dateien stammen aus diesen Läufen. Die Bootstrap-CSV
sind auch vor/nach ADR-043 bytegleich. Binary- und Two-Level-CSV stimmen
mit M1b überein, ihre Sessiondateien stammen dennoch aus echten Neuläufen.
Die vier aktuellen Implementierungshashes wurden gegen die Sessiondateien
geprüft (`study-hashes.log`, Exit 0). Die Bootstrap-Studie hat 40 endliche,
konvergierte Ausgangsfits, jeweils 200 Refits, keinen nicht endlichen
Refit; endliche singuläre Refits bleiben enthalten. Ordinal verbleiben
2/80 nicht konvergierte Fits (`singular convergence (7)`, beide S-ord-4),
keiner am Iterationslimit. Alle Warnungen/Diagnosen bleiben gespeichert.

Paketkopie mit den 158 öffentlichen Quelldateien unter
`$work/package-check-final/src`, einschließlich der Unit-Tests und aller
Vignetten; Abhängigkeiten nicht installiert oder aktualisiert:

```sh
env -u REPO_ROOT TZ=Europe/Berlin R CMD build --no-manual src
env -u REPO_ROOT TZ=Europe/Berlin _R_CHECK_CRAN_INCOMING_REMOTE_=false \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Beide Befehle endeten mit Exit 0. Echter Output aus dem finalen Check:

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 5568 ]
* checking re-building of vignette outputs ... [30s/30s] OK
* DONE
Status: 1 NOTE
```

Die NOTE lautet `Unable to verify current time`; kein ERROR oder WARNING.
Die Systemzeitprüfung blieb aktiv. Die Archiv-Skips betreffen vorhandene
Prüfungen mit nicht ausgelieferten Fixtures/Originalankern, den bestehenden
CRAN-Report-Skip und das optionale `ellmer`.

Der erste Unit-/QA-/Paketcheck fand einen echten Literalherkunftsfehler
durch den von der Vignette transitiv geladenen M1b-Generator. ADR-043
dokumentiert die behobene Ursache und die zusätzliche Leserdatei. Weder
Szenarioparameter noch Herkunftstest wurden verändert. Die obigen finalen
Läufe enthalten die Korrektur; die ersten roten Logs bleiben unter `$work`.

### Mutationsbelege und Übergabe

Der native Teil-Mutationslauf mit dem unveränderten `HarnessTestStrategy`
des Adapters bestand seinen unmutierten Vorlauf (24 Testblöcke, 13,238 s),
brach aber beim Dispatcher ab. `Rscript --vanilla "$work/mutation-native.R"`
lieferte Exit 1 und `16 | Permission denied` aus `.dispatcher_start`.
Keine Berechtigung wurde umgangen. Die zusätzliche Diagnose mit normalen
frischen R-Prozessen (`python3 "$work/mutation-processes.py"`) lieferte:

```text
Focused mutation diagnosis: 123 mutants; {'Killed': 93, 'RuntimeError': 24, 'Survived': 6}; elapsed 270.141 s
```

Das ist kein Gate-Score; RuntimeError zählt nicht als erkannt. Zwei
überlebende Singularitätsmutanten deckten eine symmetrische Testbelegung
auf. Nach ihrer Verstärkung scheitern beide tatsächlichen Mutanten mit
`[ FAIL 1 | WARN 0 | SKIP 0 | PASS 30 ]`; der unveränderte Produktcode
besteht die 180 Kern-Erwartungen. Drei weitere Überlebende ändern
API-Vorgaben und werden vom Snapshotvergleich erkannt. Der verbleibende
Teillauf-Überlebende ändert eine ältere Druckeinrückung.

`Rscript --vanilla "$work/equivalence-bind.R"` und
`R_LIBS=$work/library Rscript --vanilla "$work/equivalence-proofs.R"`
endeten mit Exit 0:

```text
19 equivalence proposals checked against actual final-source mutants; reviewer approval remains open.
```

Die 19 konkreten Anträge auf 17 Gate-Schlüsseln stehen in
`orchestrator/handoff/M1c/MUT-EQUIV.json`, gebunden an aktuelle Quellhashes,
Zeilen, Spalten und Ersetzungen. Keine alte Approval wurde übernommen.
Die beiden ADR-039-Fälle weisen Rundungsunterschiede bis
1,819e-12 bzw. 6,822e-13 auf; dafür wird keine Bitgleichheit behauptet.

Noch auszuführen sind `86-mutgate` und `88-mutfull` durch den Betreiber
(Ratchet derzeit 92,09 bzw. K-M1c-6 mindestens ANK-32), der offizielle
Bytevergleich und die Rollenabnahme. Der zusätzliche M2-Rückfalllauf
bestand K-M2-6 (383 Erwartungen); ein M2-7-Test endet in der bestehenden
Socket-Sperre, Gesamtoutput `[ FAIL 1 | WARN 0 | SKIP 0 | PASS 736 ]`.
Der Handoff enthält stabile `[INFRA]`-IDs, die BL-87-Diagnose und die
gemessenen Laufzeiten für die Betreiber-Vollläufe vor M1d. Keine
Abnahmebehauptung für nicht ausgeführte Gates, keine Git-Kommandos.

Abschließende Inventur ohne Git (`python3 "$work/integrity-final.py"`, Exit 0):

```text
Inventory: 16 changed, 13 added, 0 removed files
Unchanged baseline files: 323/339
Inventoried protected files unchanged: 214/214
Final checked public package sources unchanged: 158/158
Repository short-run files match genuine generated files: 12/12
Equivalence claims bound to current source: 19 mutants, 17 gate keys
Prior PROGRESS history: byte-identical
No unexpected files in inventoried path groups; no package-check artifacts in repository root
```

Die 29 geänderten/neuen Dateien liegen ausschließlich im zugewiesenen
Builder-Territorium. Freigegebene Pläne, Verträge, Spezifikationen,
Abnahmetests, QA-Tests, `tests/simulation/`, Fixtures, Anker und Golden-Daten
aus der Startinventur sind unverändert. Gate-Fakten, Orchestrator-Zustand
und Approval-Dateien wurden nicht geschrieben. Commit und formale
Territoriumsprüfung erfolgen durch den Orchestrator.


## M1b — REWORK Runde 8 (02.11.2026)

REVIEW/verdict-code Runde 7 nach dem Entparken enthält `blocking: []`.
Die aktuellen Gate-Fakten (`2026-11-02T08:47:04+01:00`,
`env.sha = 8d1763ef6329a7408975b6004000f9e9e7efd94e`) sind weiterhin
Runde 7: sieben Gates `pass`, allein territory `fail`, `result: fail`.
Kein Status `error`, kein aktueller `[QA-PENDING]`-Befund. Die vorherigen
AIAG-Fehler sind durch den Gate-Neulauf überholt. M1b bleibt bis zu neuen
grünen Gates und Reviewer-Verdict nicht abgenommen.

- **E37:** AIAG-Datenblatt vom Betreiber wiederhergestellt; sein SHA-256
  stimmt mit ANK-10 überein, QUELLE.txt ist vorhanden. lint, tests und
  mutgate sind grün. Harness-Nacharbeit BL-103 Nr. 3 bleibt
  OUT-OF-TERRITORY [INFRA].
- **E38 — OUT-OF-TERRITORY [INFRA]:** Die Abbruchgrenze des
  Testtreibers bleibt Betreiberarbeit BL-104. Im aktuellen Gate wurden
  alle 28 Abnahmedateien abgeschlossen, ohne Fehlschlag.
- **E39:** Mutgate der Runde 7 besteht mit 94,09 bei verlangten 90,83.
  Nachrechnung des Berichts: 1306 erkannt, 82 nicht erkannt,
  17 Überlebende durch 15 bestehende Freigaben gedeckt. Weitere Arbeit
  an BL-102 nach dem 26.11.2026; keine neuen Tests, Claims oder Approvals.
- **E40 — OUT-OF-TERRITORY [INFRA]:** Der Start-Log bestätigt
  `REWORK<=6` und `ARBITER+2`; Runde 8 ist die letzte. Rückstellung der
  Konfiguration vor M1c nach ADR-038 Nr. 3 bleibt Betreiberarbeit.
- **E41 — OUT-OF-TERRITORY [INFRA]:** Einziges rotes Gate ist territory.
  `gate-territory.log:2` nennt die unpassenden Audit-Basen `6fdc42c…`
  und `c80fb40…`; Zeile 5: `exit=1 status=fail`. Ursache laut REVIEW und
  ADR-038: Park-/Entpark-Commits zwischen Modellphase und Gates.
  Neuer Audit und Commit erfolgen durch den Orchestrator; BL-106 bleibt
  Betreiberarbeit. Kein Gate-Erfolg für Runde 8 wird vorweggenommen.
- **E42:** Nur PROGRESS.md und REWORK-NOTES.md ergänzt. Beide Hashes
  aus ADR-038 stimmen; alle 198 erfassten Paketdateien einschließlich
  aller 96 Tests/Fixtures sind bytegleich zur Inventur vor Rework r7.
  Mutationsbeleg bleibt der bestandene Lauf der Runde 7, gemäß ADR-038.

Gezielte lesende Prüfungen dieser Runde, jeweils zuletzt Exit 0;
vollständige Kommandos, Befundantworten und echte Outputs in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md), R8-P1/R8-P2.
Rohlogs und Diagnoseskripte: `/tmp/llmsa-m1b-r8-tbm5gjjf/`.

```text
acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180  R/fit.R
004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e  R/grr.R
Acceptance contexts completed in r7 log: 28/28
Package files vs r7 pre-check inventory: 198/198 byte-identical; 0 added, 0 removed
Tests and fixtures vs r7 pre-check inventory: 96/96 byte-identical
Recomputed r7 score: 94.09; detected 1306; denominator 1388; no mutation run or approval written
```

Gelesene Gate-Belege aus Runde 7: Paketcheck `Status: OK`;
testthat `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 5254 ]`,
Abnahme `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 6559 ]`, e2e 49 und fuzz 25
bestandene Erwartungen. Die Warnungen bleiben E23/BL-93.
Keine erneuten Test-, Simulations-, Paketcheck- oder Mutationsläufe
und keine Git-Kommandos. Arbiter-Direktive und die bisherigen
Produkt-/Kurzlaufbelege gelten fort. Neue Gates, Territoriumsprüfung
und Commit bleiben beim Orchestrator, Abnahme beim Reviewer.

Abschließender Inventurvergleich R8-P3, Exit 0, echter Output:

```text
Inventory: 2 changed, 0 added, 0 removed files
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1b/REWORK-NOTES.md
Unchanged inventory files: 1059/1059
Tests and fixtures unchanged: 96/96
Prior REWORK-NOTES and PROGRESS history: byte-identical
Claims, approvals, gate facts and inventoried state: unchanged
Gate facts unchanged: round 7, result fail
```

## M1b — REWORK Runde 7 (01.11.2026)

REVIEW/verdict-code Runde 6 enthalten `blocking: []`; REVIEW und ADR-037
Nr. 2 verlangen keine Produktänderung. Die vorhandenen Gate-Fakten sind
Runde 6: lint, tests und mutgate `fail`, die übrigen fünf Gates `pass`,
`result: fail`. Kein Status `error`, kein aktueller `[QA-PENDING]`-Befund.
M1b bleibt nicht abgenommen.

- **E37 — OUT-OF-TERRITORY [INFRA]:** Das geschützte AIAG-Datenblatt
  `reference/quellen/data/aiag/anova_example.csv` fehlt weiterhin; auch
  die übrigen Dateien unter `reference/quellen/` und `reference/privat/`
  fehlen. Gate-Logs und die beiden eigenen Abnahmeläufe unten belegen
  dieselbe Ursache. Wiederherstellung und Restore-Korrektur: Betreiber,
  BL-103.
- **E38 — OUT-OF-TERRITORY [INFRA]:** `gate-tests.log:685` meldet
  `Maximum number of failures exceeded; quitting.` Zehn von 28 Dateien
  liefen, 18 wurden nicht erreicht. Korrektur des Testtreibers: Betreiber,
  BL-104. Der vollständige Zusatzlauf in REVIEW Runde 6 ist ein
  Reviewer-Beleg, kein eigener Lauf dieser Runde.
- **E39 — nonblocking:** Kein `mutation.json`; unmutierter Vorlauf mit
  zwölf fehlgeschlagenen und vier abgebrochenen Testblöcken, kein Mutant
  gelaufen. Die drei früheren nicht freigegebenen Überlebenden bleiben
  bis zum nächsten Bericht offen (BL-102). Alle 16 Claims und 15
  Freigaben treffen weiter ihre Quellzeilen; keine Änderung daran.
- **E40 — OUT-OF-TERRITORY [INFRA]:** Rundenlimit 5 + 2 = 7 und
  vorhandener `arbiter-granted` bestätigt. Laut Steuerlogik droht bei
  weiterhin roten Gates das Parken nach Runde 7. BL-103 muss vor dem
  Gate-Lauf erledigt werden; Wiederanlauf und Infrastrukturklassifikation
  bleiben Betreiberarbeit (BL-105). Keine Zustandsänderung durch den Builder.

E33/E34/E36 bleiben erledigt, E32/E35 nach ADR-035 zurückgestellt.
Arbiter-Direktive und bisherige Produkt- und Kurzlaufbelege gelten fort.

Gezielte unveränderte Abnahmetests mit R 4.6.1, echter Output:

```text
K-M1a-2, Exit 1: [ FAIL 3 | WARN 0 | SKIP 0 | PASS 0 ]
Error: acceptance: local AIAG data sheet missing (K-M1a-2, ANK-10, docs/01 §6): /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv
K-M1b-7, Exit 1: [ FAIL 7 | WARN 0 | SKIP 0 | PASS 11 ]
`actual` is a character vector ('Validation input is missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv')
```

Vollständige Kommandos, Antworten auf E37–E40 und Gate-Fundstellen:
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md), Runde 7,
R7-P1/R7-P2. Nur dieser Fortschrittsnachtrag und der zugewiesene Handoff
werden ergänzt. Keine Produktänderung, Ersatzdaten, neuen Tests oder
Äquivalenzanträge; keine Änderung von Gates, Schwellen oder Reviewer-
Approvals. Kein neuer Gate-, Simulations-, Paketcheck- oder Mutationslauf;
keine Git-Kommandos. Neue Gate-Fakten und Commit folgen durch den
Orchestrator, die Abnahme durch den Reviewer.

Die ausgeführte SHA-256-Inventur (REWORK-NOTES R7-P3, Exit 0) bestätigt:

```text
Inventory: 2 changed, 0 added, 0 removed files
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1b/REWORK-NOTES.md
Unchanged inventory files: 408/408
Tests and fixtures unchanged: 96/96
Prior REWORK-NOTES and PROGRESS history: byte-identical
Gate facts unchanged: round 6, result fail
AIAG data sheet and mutation.json: still missing
```

## M1b — REWORK Runde 6 (01.11.2026)

REVIEW/verdict-code Runde 5 enthalten `blocking: []`; ADR-037 Nr. 2
verlangt keine Produktänderung. Die vorhandenen Gate-Fakten sind weiterhin
Runde 5: lint, tests und mutgate `fail`, die übrigen fünf Gates `pass`,
`result: fail`. Kein Gate hat Status `error`; kein offenes `[QA-PENDING]`
im aktuellen Verdict. M1b bleibt nicht abgenommen.

- **E37 — OUT-OF-TERRITORY [INFRA]:** Das geschützte AIAG-Datenblatt
  `reference/quellen/data/aiag/anova_example.csv` fehlt weiterhin;
  `reference/quellen/` und `reference/privat/` enthalten je null Dateien.
  Die vorhandenen Logs belegen denselben Grund für den roten Paketbau,
  die Abnahmefehler und den Abbruch vor dem ersten Mutanten. Betreiber
  stellt die Originaldateien gemäß BL-103 wieder her und prüft den
  Rollback. Keine Ersatzdaten oder Produkt-Scheinreparatur.
- **E38 — OUT-OF-TERRITORY [INFRA]:** `gate-tests.log:685` meldet
  `Maximum number of failures exceeded; quitting.` Der Abbruch nach
  m1a-4 und die Korrektur am Testtreiber bleiben Betreiber-Auftrag BL-104.
- **E39 — nonblocking:** Kein `mutation.json`, damit kein neuer
  vollständiger Score. Der vorhandene unmutierte Bericht enthält
  12 fehlgeschlagene und vier abgebrochene Testblöcke. Die drei im
  früheren Teillauf überlebenden, nicht freigegebenen Mutanten bleiben
  offen bis zum nächsten Bericht (ADR-037 Nr. 3, BL-102). Bestehende
  16 Claims und Reviewer-Approvals bleiben unverändert.

E33/E34 sind nach REVIEW Runde 5 und ADR-037 Nr. 1 erledigt, E35 ist
dokumentiert, E36 ist behoben. Keine zusätzliche Arbeit an den durch
ADR-035 zurückgestellten Befunden BL-100/101. Die Arbiter-Direktive zu
K-M1b-5 bleibt maßgeblich.

Gezielte unveränderte Abnahmetests dieser Runde (R 4.6.1), echter Output:

```text
K-M1a-2, Exit 1: [ FAIL 3 | WARN 0 | SKIP 0 | PASS 0 ]
Error: acceptance: local AIAG data sheet missing (K-M1a-2, ANK-10, docs/01 §6): /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv
K-M1b-7, Exit 1: [ FAIL 7 | WARN 0 | SKIP 0 | PASS 11 ]
`actual` is a character vector ('Validation input is missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv')
K-M1b-1 und K-M1b-5, Exit 0: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 43 ]
```

Vollständige Befehle, Befundantworten und Log-Fundstellen stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md), R6-P1 bis
R6-P5. Die Nachweise der Runde 5 sind dort als historischer Handoff
erhalten. Die SHA-256-Inventur bestätigt (Exit 0):

```text
Inventory: 2 changed, 0 added, 0 removed files
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1b/REWORK-NOTES.md
Unchanged inventory files: 374/374
Tests and fixtures unchanged: 96/96
Prior REWORK-NOTES and PROGRESS history: byte-identical
Gate facts unchanged: round 5, result fail
AIAG data sheet and mutation.json: still missing
```

Nur PROGRESS.md und der zugewiesene Handoff wurden geändert;
kein neuer Gate-Lauf, kein Paketcheck, keine Simulation und kein
Mutationslauf. Keine Git-Kommandos. Wiederherstellung, neue Gate-Fakten,
Territoriumsprüfung und Commit bleiben beim Orchestrator/Betreiber,
Abnahme und Äquivalenzfreigaben beim Reviewer.

## M1b — REWORK Runde 5 (01.11.2026)

Grundlage: REVIEW/verdict-code Runde 4 (E33–E36), gates.json samt Logs,
CRITERIA, ARBITER, LESSONS und ADR-034/035. Die vorhandenen acht Gates
sind Runde 4, alle `pass`; kein `error`. Mutgate: 93,02 bei verlangten
90,83. Dieser Eintrag berichtet lokale Builder-Prüfungen; neues Gate,
Verdict und Commit bleiben beim Orchestrator beziehungsweise Reviewer.
Vollständige Antworten, Befehle, Rohlogpfade und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E33 umgesetzt:** `R/fit.R` berechnet die latente Gram-Matrix über
  dünn besetzte Kreuztabellen und Produkte im festen Effektraum gemäß
  ADR-034. Dichte Stufen-mal-Stufen-Projektionsblöcke entfallen.
  Restterm, Rangnachweis, Eigenwertregel und Namensdiagnose bleiben
  unverändert; keine neue Toleranz. Neue Tests decken die verlangten
  Größen bis 2000 Items/Zellen und geschlossene Formeln bis 5000 Items
  ab. Das Raster mit drei Seeds/sieben Größen ergibt 588 übereinstimmende
  Entscheidungen (252 identifizierbar, 336 abgewiesen).
- **E34 umgesetzt:** Nach Zeilenauswahl zählen ganzzahlige Gewichte als
  Häufigkeiten; sobald ein verbleibendes Gewicht nicht ganzzahlig ist,
  zählt jede positive Zeile genau einmal, auch im festen Rang und dessen
  Rangnachweis. Engine-Gewichte und Engine-Daten bleiben unverändert.
  Direkte clmm/glmer-Orakel und ein unabhängiges Beobachtungspaar-/SVD-
  Raster bestätigen das Verhalten: 768 Entscheidungen, keine Abweichung
  (340 identifizierbar, 60 Eingabe-/Stufenprüfung, 368 konfundiert).
- **E35 dokumentiert:** „Known limitations“ in `?msa_fit` nennt die
  Stufenzählung bei Nullgewichten und verweist auf `subset`, außerdem
  den numerischen Durchreichweg aus E32/BL-100. Keine weitere Änderung
  dieser Wege; ADR-035 bleibt maßgeblich.
- **E36 bearbeitet:** Überflüssiges `stringsAsFactors = FALSE` entfernt,
  widerlegten Äquivalenzclaim zurückgenommen. Gegenprobe mit msa_runs,
  Datenrahmen, Liste und Zeichenmatrix ist identisch zum bisherigen
  Verhalten. Die 16 verbleibenden Anträge sind an endgültige Zeilen,
  Spalten und Quelltexte gebunden; APPROVED bleibt unverändert.
- **Mutation:** Gezielte Diagnose über 179 Mutanten plus zusätzlicher
  algebraischer Test für den Rangnachweis: 168 Killed, 9 Survived,
  2 syntaktische RuntimeErrors. Alle 32 Mutanten der neuen Gewichts-
  normalisierung und Sparse-Arithmetik werden getötet. Sechs Überlebende
  sind beantragt; `>`→`>=` an `R/fit.R:338:74` und die beiden `symmetric`
  TRUE→FALSE-Mutanten an `:331:42`/`:337:55` bleiben ungeclaimt.
  Kein vollständiger Gate-Score; keine eigenen Freigaben.

Neu: `tests/testthat/test-fit-latent-precision.R` mit sieben Blöcken und
545 Erwartungen sowie Builder-ADR-036. Bestehende Tests sind unverändert.
Die Gegenprobe mit dem alten Produktcode ergibt erwartete 73
fehlgeschlagene Erwartungen, 470 bestandene und keinen Testfehler.
Hilfe und NEWS sind ergänzt; die Hilfe entspricht der Roxygen-Erzeugung.

Alle neun Kurzlaufdateien wurden mit dem aktuellen installierten Paket,
unveränderten Seeds, n_sim = ANK-TOL.n_check (20) und 14 Workern neu
erzeugt. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 107.327 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.964 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 9.623 s; workers 14
Nine genuine short-run files copied; six CSVs byte-identical to the pre-rework files.
No full-run files written in the repository.
```

Alle drei Prozesse Exit 0. Sessionhash separat bestätigt:
`477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e`.
Die unveränderten Abnahmetests reproduzieren die sechs CSVs bytegleich.

Ausgeführte Schlussprüfungen, Rohlogs unter `/tmp/llmsa-m1b-r5-VqXqW8/`:

```text
Gezielte latente Tests: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1957 ]
tests/testthat: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 5254 ]
tests/e2e:      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
tests/fuzz:     [ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 282 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1a/M1b-Abnahme: [ FAIL 59 | WARN 2 | SKIP 0 | PASS 3765 ]
Blocks: 128; failed expectations: 55; error blocks: 4; skipped: 0; elapsed: 216.189 s
R CMD check: Status: 1 NOTE
Installierte Tests: [ FAIL 0 | WARN 0 | SKIP 9 | PASS 5178 ]
```

**OUT-OF-TERRITORY:** Die lokale Abnahme ist durch die fehlende geschützte
Datei `reference/quellen/data/aiag/anova_example.csv` rot. Die vier
direkten Fehler und 55 Folgefehlschläge der Repo-Vignette sind im Log
belegt; keine Ersatzdaten und kein Skip. K-M1b-1 bis K-M1b-6 bestehen
mit 3030 Erwartungen, die Volllauf-Fixture mit weiteren 204. E23 bleibt
wegen zweier Reviewer-Abnahmehelfer-Deprecations nonblocking (BL-93).
Der Paketcheck hat keine ERRORs/WARNINGs; seine einzige NOTE lautet
`Unable to verify current time.` Die Zeitprüfung bleibt aktiv.
Der native Mutationstreiber scheitert mit `.dispatcher_start: 16 |
Permission denied`; die zusätzliche Diagnose läuft mit gewöhnlichen
R-Unterprozessen innerhalb derselben Sandbox. Zwei erzeugte Mutanten
sind syntaktisch ungültig (`unexpected '!'`); sie zählen nicht als
Killed. Bei der Sessionerfassung scheitert `timedatectl` mit Status 1,
die Simulationen selbst enden mit Exit 0. Belege und Zuständigkeiten
stehen in REWORK-NOTES P3–P6. Kein offenes [QA-PENDING].

Integrität: 405/405 geschützte Bestandsdateien und 95/95 bestehende
Test-/Fixture-Dateien bytegleich; numerische Helfer, Eigenwertregel und
Namensdiagnose unverändert. Alle 22 Snapshot-Schnittstellen behalten
Positionen und Vorgabewerte. Keine Änderung von Ankern, Schwellen,
Gates, APPROVED oder Orchestrator-Zustand; keine Git-Kommandos.


## M1b — REWORK Runde 4 (01.11.2026)

Grundlage: REVIEW/verdict-code Runde 3 (E29–E32), gates.json und Gate-Logs,
CRITERIA, ARBITER, LESSONS sowie ADR-032. Die vorhandenen acht Gates sind
Runde 3, alle `pass`; kein `error`. Dieser Eintrag berichtet lokale
Builder-Prüfungen und ersetzt weder Gate-Fakten noch Reviewer-Verdict.
Vollständige Antworten, Befehle, Rohlogpfade und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E29 umgesetzt:** `R/fit.R` prüft die latente Identifizierbarkeit mit
  fester Restvarianz und Häufigkeitsgewichten. Nullgewichte liefern keine
  Ranginformation, Antwortkategorien oder beobachteten Zufallsstufen.
  Das Gram-Kriterium enthält die Rest-Kreuzprodukte Σw − ‖Qᵀ√W Z_j‖²_F
  und die Restdiagonale Σw − p. Gewichteter fester Rang und vollständig
  aufgespannte Terme werden auf derselben Darstellung geprüft. Die
  Eigenwertregel bleibt unverändert, k zählt den Restterm mit. Fehler
  erfolgen vor beiden Engines; bei Restkonfundierung wird der Grund
  benannt. Keine neue empirische Toleranz oder Engine-Vorgabe.
- **E30 umgesetzt:** Die Fehlermeldung nennt über die Vereinigung aller
  erkannten Nullraumrichtungen ausschließlich beteiligte Terme, auch
  bei mehreren unabhängigen Relationen. Neue Tests prüfen die genaue
  Namensliste, vollständige Meldung und `call. = FALSE`.
- **E31 bearbeitet:** Alle vier konkret benannten nicht äquivalenten
  Überlebenden aus REVIEW werden getötet. Der gezielte Lauf über 163 von
  muttest erzeugte Mutanten ergibt nach Ergänzungen 154 Killed,
  7 Survived, 2 RuntimeError. Sechs Überlebende sind begründet äquivalent;
  `R/fit.R:323:74`, `>` → `>=` an der Namensdiagnoseschwelle, bleibt mangels
  allgemeinem Beweis ungeclaimt. Die zwei RuntimeErrors sind syntaktisch
  ungültige Mutanten und zählen nicht als Killed. `MUT-EQUIV.json` enthält
  17 einzeln begründete Anträge mit endgültigen Zeilen, einschließlich
  M1a-Neubindungen. Freigaben bleiben beim Reviewer; APPROVED unverändert.
- **E32 OUT-OF-TERRITORY für M1b:** ADR-032 Nr. 3 verlangt ausdrücklich
  keinen Builder-Fix; Betreiberentscheidung in M1c, BL-100. Numerischer
  Rechenkern, numerische Engine-/Refit-Aufrufe und `R/grr.R` sind bytegleich.
- **Ältere IDs:** E25 und E26 sind laut REVIEW/Gate erledigt und lokal
  erneut bestätigt (Volllauf-Fixture 204 Erwartungen; gemeinsamer QA-Lauf
  nach M1b einschließlich M2 grün). Kein offenes [QA-PENDING]. E23 bleibt
  wegen zweier Reviewer-Abnahmehelfer-Warnungen OUT-OF-TERRITORY (BL-93).

Zwei neue Unit-Dateien enthalten zwölf Blöcke mit 1088 Erwartungen:
unabhängige expandierte Beobachtungspaarrechnung samt Restterm, exakte
algebraische Rangfälle, Nullgewichte, Frequenzvielfachheiten, beide Links
und Zielgrößen mit gesperrten Engines sowie gültige gewichtete Fits gegen
direkte Engines. Das Raster über 96 Pläne/384 Aufrufe stimmt vollständig
mit der unabhängigen SVD-Referenz überein (168 identifizierbar, 198
konfundiert, 18 durch Eingabe-/Stufenprüfung abgewiesen). Die Gegenprobe
mit ursprünglicher `R/fit.R` in einer isolierten Kopie ergibt erwartete
188 fehlgeschlagene Erwartungen und drei Fehler wegen neuer interner
Argumente. Bestehende Unit-, Abnahme- und QA-Dateien wurden nicht geändert.

`man/msa_fit.Rd`, `NEWS.md` und Builder-ADR-033 dokumentieren den Rework.
Die Hilfe stimmt exakt mit der Roxygen-Erzeugung überein. Alle neun
Kurzlaufdateien wurden mit dem installierten aktuellen Paket, unveränderten
Seeds, `n_sim = ANK-TOL.n_check` (20) und 14 Workern neu erzeugt. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 110.598 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.909 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 12.002 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle Erzeugungsprozesse Exit 0; sechs CSVs bytegleich zum Rundenbeginn.
Die drei Sessiondateien tragen den separat abgeglichenen Hash
`815a3da5b543b3301f28c72da167f1ec1621410dac74e1298e00d822889a15ba`.
Keine Volllaufdateien oder Betreiberartefakte geschrieben.

Ausgeführte Schlussprüfungen, vollständige Befehle in REWORK-NOTES P1–P8:

```text
tests/testthat: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 4709 ]
tests/e2e:      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
tests/fuzz:     [ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 275 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1b: [ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
Blocks: 74; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 236.385 s
M1a: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
Blocks: 54; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 74.888 s
K-M2-6: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 383 ]
Blocks: 11; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 313.587 s
K-M2-7: [ FAIL 1 | WARN 0 | SKIP 0 | PASS 353 ]
Blocks: 9; failed expectations: 0; error blocks: 1; skipped: 0; elapsed: 250.668 s
```

Der vorhandene Unit-Skip ist der ellmer-Negativtest. Die M1b-Warnungen
sind die unveränderten `nobars`-/`findbars`-Deprecations im Abnahmehelfer.
K-M2-7 hat genau einen Infrastrukturfehler im HTTP-Replay; alle acht
anderen Blöcke, einschließlich der Robustheitsauswertung mit 165
Erwartungen, bestehen. Die Socket-Erzeugung scheitert in
`setup-m2.R:787` über `httr2::req_dry_run()`/`httpuv::startServer()` mit
`System failure for: socket() (Operation not permitted)`.

Paketbau und direkter `R CMD check --as-cran --no-manual` sind mit Exit 0
abgeschlossen: keine ERRORs/WARNINGs, eine NOTE `Unable to verify current
time.` Installierte Tests: `[ FAIL 0 | WARN 0 | SKIP 9 | PASS 4633 ]`;
die neun bestehenden Skips betreffen nicht mitgelieferte API-Fixtures/
Repository-Anker, den CRAN-Reporttest und ellmer. Beispiele einschließlich
`--run-donttest`, Vignetten und Vignettenneubau sind OK.

**OUT-OF-TERRITORY [INFRA], ohne Scheinfix:** nativer muttest-Dispatcher
(`16 | Permission denied`), zwei syntaktisch ungültige Mutanten, lokale
HTTP-Replay-Sockets, `timedatectl` ohne Systembus und externe Zeitprüfung.
Log-Belege und stabile IDs stehen in REWORK-NOTES P2/P4/P5/P6/P8. Kein
Eingriff in Berechtigungen, Tests, Gates, Schwellen oder Orchestrator-Zustand;
keine Git-Kommandos. Der vollständige Mutationslauf und neue Gate-Fakten
bleiben beim Orchestrator, Äquivalenzfreigaben beim Reviewer.

## M1b — REWORK Runde 3 (31.10.2026)

Grundlage: REVIEW/verdict-code Runde 2 (E24–E28), gates.json samt roten
Logs, CRITERIA, ARBITER, LESSONS und ADR-029. Dieser Eintrag berichtet
Builder-Prüfungen; Gate-Fakten bleiben unverändert Runde 2, `result: fail`
wegen der beiden in REVIEW beschriebenen Fremdterritoriums-Ursachen.
Die vollständigen Antworten, Befehle und echten Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E24 umgesetzt:** `R/fit.R` prüft nach Zeilenauswahl alle ordinalen
  und binären Zufallsterme einschließlich Wechselwirkungen auf getrennte
  Identifizierbarkeit nach Abzug des festen Designs. Das Gram-Kriterium
  verwendet die Eigenwertregel aus ADR-029. Vollständig aufgespannte Terme
  werden mittels Rangnachweis exakt als null behandelt, auch wenn alle
  Zufallsterme betroffen sind. Keine neue empirische Toleranz, keine
  Änderung der Engine-Vorgaben. Hilfe und Builder-ADR-030 dokumentieren
  die Umsetzung. Gültige Pläne stimmen weiter mit direkten Engines überein.
- **E27 umgesetzt:** Zwei neue Testdateien liefern zehn Blöcke mit 221
  Erwartungen: unabhängige Kovarianzrechnung, Konfundierung als Klasse,
  gültige Pläne gegen direkte Engines, explizite Labelreihenfolge, zwei
  ordinale Kategorien und erneut ausgewerteter binärer Aufruf. Alle vier
  von E27 benannten Mutanten werden getötet. Eine Gegenprobe mit der
  ursprünglichen `msa_fit()`-Definition ergibt 93 fehlgeschlagene
  Erwartungen in sieben Blöcken, keine Testfehler.
- **E28 umgesetzt:** NEWS nennt die Änderungen der Runden 2 und 3 an
  latenten Fits, einschließlich Zeilenauswahl, Gewichten, Labelprüfung,
  gespeicherten Engine-Aufrufen und `data$.msa_offset`.
- **E25 OUT-OF-TERRITORY [INFRA]:** Die bereits vor dieser Runde vom
  Reviewer korrigierte Volllauf-Fixture besteht jetzt mit 204 Erwartungen;
  Produktvalidator und Abnahmetest blieben unverändert. Reguläre
  Gate-Bestätigung bleibt bei Orchestrator/Reviewer (BL-94).
- **E26 OUT-OF-TERRITORY [QA-PENDING]:** Alle sechs M1b-QA-Befunde bestehen,
  danach scheitern die vier M2-E2E-Blöcke weiterhin am gelöschten Namespace
  von QA-M1b-004. Der frische M2-Prozess besteht mit neun Erwartungen.
  Kein Produkt-Scheinfix und kein Eingriff in QA oder Betreiberzustand;
  erforderlicher QA-Nachlauf nach ADR-029 Nr. 3 bleibt offen (BL-95).

Alle neun Kurzlaufdateien wurden nach der Produktänderung mit dem
installierten aktuellen Paket, `n_sim = ANK-TOL.n_check` (20), den
bisherigen Seeds und 14 Workern erzeugt. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 108.138 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.905 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.037 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle drei Prozesse endeten mit Exit 0. Die sechs CSVs sind bytegleich zum
Rundenbeginn, die drei Sessiondateien tragen den separat abgeglichenen
Implementierungsnachweis
`c2045c7c594adda23b5ecd516fcedf0ed28a52df00180c79f9cbea9ea0238c9d`.
Der neue Rechenhelfer gehört ausdrücklich zum Hash. Keine Betreiber-
Volllaufdatei wurde geschrieben; E21/BL-92 bleibt inhaltlich unverändert.

Abschließende tatsächlich ausgeführte Prüfungen; Rohlogs unter
`/tmp/llmsa-m1b-r3-2ug3odnl/`:

| Prüfung | Echter Output / Ergebnis |
| --- | --- |
| Vollständige Unit-Suite | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3621 ]`, 247 Blöcke, Exit 0 |
| Vollständige M1b-Abnahme | `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 3474 ]`, 74 Blöcke, Exit 0 |
| M1a-Abnahme | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 722 ]`, 54 Blöcke, Exit 0 |
| Vollständige QA-Verzeichnisse | `16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen`, Exit 1 wegen E26 |
| M2-E2E allein, frischer Prozess | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 9 ]`, Exit 0 |
| K-M2-6 | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 383 ]`, 11 Blöcke, Exit 0; wiederholt nach der im Handoff belegten Dateiinventur-Kollision |
| Öffentlicher Paketbau und installierter `R CMD check --as-cran --no-manual` | Je Exit 0, `Status: 1 NOTE`; installierte Tests `[ FAIL 0 \| WARN 0 \| SKIP 9 \| PASS 3545 ]` |
| 80 gezielte Mutationsproben | `{"Killed": 65, "RuntimeError": 4, "Survived": 11}`; Diagnose, kein vollständiger Gate-Score |

Die Unit-/Paket-Skips sind unverändert: ellmer-Negativtest sowie im
öffentlichen Paket fehlende lokale API-Aufzeichnungen/Originalanker und
der bestehende Report-CRAN-Skip. Die beiden M1b-Abnahmewarnungen kommen
weiter aus `lme4::nobars`/`findbars` im Reviewer-Helfer (E23/BL-93).
M0-Prüfwege mit Git wurden nicht ausgeführt.

**Zusätzliche OUT-OF-TERRITORY-Infrastruktur, keine Scheinreparaturen:**
Der native parallele `muttest`-Start scheitert nach grünem Vorlauf mit
`16 | Permission denied` in `.dispatcher_start` (M1B-R3-INFRA-MUTTEST).
Die 80 generierten Mutanten wurden deshalb als lokale Diagnose jeweils
in einer eigenen Paketkopie mit frischem R-Prozess ausgeführt; vier
RuntimeErrors werden nicht als getötet gezählt. Die einzige Paketcheck-
NOTE lautet `Unable to verify current time` (M1B-R3-INFRA-CLOCK);
die Zeitprüfung bleibt aktiv. Befehle und Logstellen stehen im Handoff.

Drei einzeln bewiesene Äquivalenzanträge stehen in `MUT-EQUIV.json`:
literaler Doppelpunkt bei `strsplit`, vollständig überschriebene
Gram-Anfangswerte 1 und −1. Keine Builder-Freigabe. Der letzte reguläre
mutgate-Wert bleibt Runde 2 mit 91,91 bei 91,83; ein neuer vollständiger
Lauf folgt durch den Orchestrator.

Die abschließende SHA-256-Inventur bestätigt neun geänderte und vier neue
Dateien ausschließlich im zugewiesenen Builder-Territorium. Alle 291
geschützten Bestandsdateien und alle 91 bestehenden Test-/Fixture-Dateien
sind bytegleich. Produktcode, Hilfe, `inst/`, Unit-Tests und Paketmetadaten
stimmen mit dem tatsächlich gebauten und geprüften Paketstand überein.
Keine Git-Kommandos; keine Änderung an Gates, Schwellen, Ankern, Specs,
BACKLOG oder Betreiberzustand. Drei Äquivalenzanträge bleiben ohne
Builder-Freigabe. E26 und der reguläre Gate-/Reviewer-Nachlauf bleiben offen;
dieser Eintrag erklärt kein Meilenstein-PASS.

## M1b — REWORK Runde 2 (31.10.2026)

Grundlage: REVIEW/verdict-code Runde 1 (E12–E23), gates.json samt roten
Logs, CRITERIA, ARBITER, LESSONS und ADR-027. Rollen-/Buildregeln,
Protokoll, Handoff-Schema, Spezifikationen und bestehende Prüfungen wurden
gelesen. Dieser Eintrag berichtet Builder-Prüfungen, kein Abnahme-Verdict.
Die Antworten auf jede Befund-ID, Befehle und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E12/E13:** `R/fit.R` wertet Argumente aus und speichert erneut
  ausführbare Engine-Aufrufe. Zeilenauswahl, Gewichte und Offsets gelten
  vor dem Formelaufbau; Daten, Stufen, abgeleitete Komponenten und
  Zählungen beziehen sich auf dieselben Beobachtungen. Ordinale Offsets
  sind Formelterme. Bei ordinalen Häufigkeitsgewichten ist `nobs(clmm)`
  die Gewichtssumme, während `n` Zeilen zählt; direkte Engine-Vergleiche
  belegen das. Hilfe und ADR-028 dokumentieren die Einzelheiten.
- **E14/E16:** Singularität zählt nur Zufallskomponenten. Alle ordinalen
  Zufallsterme und festen Zwei-Stufen-Designs werden vorab auf Schätzbarkeit
  geprüft. Explizite Labels werden unabhängig vom Speichertyp validiert
  und verwendet; bisherige Warnungen und Fehlermeldungen bleiben erhalten.
- **E15:** Neuer Unit-Helfer ergänzt ausschließlich die fehlende
  Dokumentationsfixture in Paketkopien über `REPO_ROOT`. Er lädt keinen
  Produktcode aus dem Original nach. Der bestehende Test bleibt
  byte-identisch; die vollständige Suite besteht auch ohne ursprünglich
  vorhandenes `vignettes/` in der Kopie.
- **E17:** Studien-Merge prüft alle Designzählungen und Diagnoseflags;
  Ergebnisleser weist ungültige EmpSE/RMSE, Anteile und Seeds zurück.
- **E18/E20:** Acht neue Testblöcke mit 179 Erwartungen verwenden
  direkte Engines, Formeln und synthetische Korruptionen. Alle acht
  erkennen den ursprünglichen Produktcode; am finalen Stand bestehen
  sie. Die Hilfe nennt die Optimierertoleranz latenter Invarianz.
  Kein Mutationsscore und kein MUT-EQUIV-Antrag ohne Mutationsbericht.

Die neun Kurzlaufdateien wurden nach der letzten Implementierungsänderung
mit dem installierten Paket, `n_sim = ANK-TOL.n_check` (20), den bestehenden
Seeds und 14 Workern neu erzeugt. Echter Generator-Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 104.210 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.879 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.795 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle drei Prozesse endeten mit Exit 0. Die sechs CSVs bleiben bytegleich
zum Rundenbeginn; die drei Sessiondateien tragen den neuen Hash
`cc34f15d2cd96684043f688b41b85ab70ffefb2ba41044e161a7bf9c88c5c4a7`,
der separat mit den finalen Quellen abgeglichen wurde. E21 bleibt
unverändert berichtet: 18/80 ordinale Wiederholungen nicht konvergiert,
alle mit endlichen Schätzern (17 Iterationslimits, einmal singular
convergence). Je Szenario 1/20, 5/20, 2/20 und 10/20; S-bin und S-two
jeweils 0/40. Die Vollauswertung bleibt bei Betreiber/M1d (BL-92).

Abschließende ausgeführte Prüfungen; Details und Rohlogs unter
`/tmp/llmsa-m1b-r2/` sowie im Handoff:

| Prüfung | Echter Output / Ergebnis |
| --- | --- |
| Vollständige Unit-Suite, Arbeitsbaum | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3400 ]`, 237 Blöcke, Exit 0 |
| Vollständige Unit-Suite, Paketkopie ohne Vignetten | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3400 ]`, 237 Blöcke, Exit 0 |
| M1a-Abnahme | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 722 ]`, 54 Blöcke, Exit 0 |
| Alle acht M1b-Abnahmedateien | `[ FAIL 5 \| WARN 2 \| SKIP 0 \| PASS 3270 ]`, 74 Blöcke, Exit 1; ausschließlich die ungültige Volllauf-Fixture rot |
| Vollständige QA-Verzeichnisse | `16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen`; alle sechs M1b-QA-Befunde grün, die vier M2-E2E-Blöcke scheitern am Namespace-Lebenszyklus |
| M2-E2E allein, frischer Prozess | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 9 ]`, Exit 0 |
| K-M2-6 und K-M2-7 | `[ FAIL 1 \| WARN 0 \| SKIP 0 \| PASS 736 ]`, 20 Blöcke, Exit 1; K-M2-6 grün mit 383 Erwartungen, ein Socket-Fehler in K-M2-7 |
| Paketbau und `R CMD check --as-cran --no-manual` | Exit 0, `Status: 1 NOTE` (Zeitprüfung); keine ERROR/WARNING; installierte Tests `[ FAIL 0 \| WARN 0 \| SKIP 9 \| PASS 3324 ]` |

Der Unit-Skip ist der unveränderte ellmer-Negativtest. Die neun Skips im
öffentlichen Paketcheck sind unveränderte Prüfungen, die lokale
API-Aufzeichnungen bzw. Originalanker verlangen, der Report-CRAN-Skip
und derselbe ellmer-Negativtest. Der vollständige Quellpaketlauf führt
die Repository-Prüfungen aus. K-M1b-2/-3 reproduzieren die Kurzläufe
byte-identisch. Es wurden keine Tests abgeschwächt oder neue Skips ergänzt.

**OUT-OF-TERRITORY, mit Log-Belegen im Handoff:**

- **M1B-R2-INFRA-FULL-FIXTURE:** Der geschützte Abnahmetest addiert 0.5
  auf jeden Ergebniswert und erzeugt dadurch `derived_share = 1.5`.
  ADR-027 Nr. 5 verlangt dessen Zurückweisung. Der Reviewer muss die
  Fixture fachlich gültig machen; der Produktvalidator bleibt streng.
- **M1B-R2-INFRA-QA-NAMESPACE:** QA-M1b-004 löscht seine temporäre
  Paketkopie, während deren Namespace noch aktiv ist. Die nachfolgenden
  M2-Tests finden kein Paket mehr. Auch mit dem alten Produktcode und
  ohne den neuen Vignettenhelfer reproduziert; Zuständigkeit QA/Betreiber.
- **E19 [INFRA]/BL-90:** Das vom Reviewer korrigierte M2-Orakel besteht
  mit 383 Erwartungen; `R/acmg.R` bleibt byte-identisch.
- **E22 [INFRA]/BL-86:** Der HTTP-Replay-Test endet mit „System failure for: socket() (Operation not permitted)“. Die lokale NOTE lautet
  „Unable to verify current time“. Keine Umgehung der Sandbox oder
  Abschaltung der Prüfungen.
- **E23/BL-93:** Zwei Deprecation-Warnungen aus dem geschützten
  Abnahmehelfer (`lme4::nobars`/`findbars`); kein Produktfehler.

Bestehende Tests, QA, Abnahme, Fixtures, Specs, Anker, Gate-Fakten und
Schwellen bleiben unverändert. Der abschließende SHA-256-Abgleich prüft
die Änderungen gegen 303 zu Rundenbeginn gesicherte Dateien sowie die
final getesteten Quellen und Paketbaueingaben. Keine Git-Kommandos,
keine Änderungen an BACKLOG oder Betreiberzustand, keine Betreiber-
Volllaufdateien. E18 und die Gate-Bestätigung bleiben offen bis zum
nächsten regulären Lauf; dieser Builder erklärt den Meilenstein nicht
für abgenommen.

## M1b — BUILD (31.10.2026)

Grundlage: freigegebener PLAN und PLAN-UPDATE, PLAN-REVIEW Runde 2 mit
PASS, ARBITER zu E1, CRITERIA samt ACC-18 sowie ADR-023/024/025.
AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, Spezifikationen,
Abnahmetests, bisheriger PROGRESS und LESSONS wurden gelesen.
Dieser Eintrag enthält Builder-Prüfbelege, kein Abnahme-Verdict.

Nachgetragener M1a-Abschluss gemäß PLAN-UPDATE, Reihenfolge Nr. 2:
`orchestrator/handoff/M1a/verdict-code.json` dokumentiert für Runde 5
`"verdict": "PASS"`, `"blocking": []`; die bestehenden Gate-Fakten unter
`orchestrator/state/M1a/gates.json` nennen achtmal `pass` und
`"result": "pass"`. Die dort gelesene Mutationszusammenfassung lautet:

```text
mutgate: pass (score=93.83 required=91.79 baseline=93.83 floor=80)
```

Das sind übernommene Orchestrator-/Reviewer-Fakten, kein neuer Gate-Lauf.
Die nichtblockierenden E57/BL-84, E58/BL-89 und E59/BL-87 bleiben nach
dem freigegebenen M1b-Plan vertagt; der aktuelle Builder-Lauf ändert ihre
Freigabe oder Bewertung nicht.

### Umsetzung und Einwände

- **E1 / K-M1b-5 / ACC-18:** latente Logit-ICC gegen live
  `rptBinary(expect = "liability")`, `performance::icc()` auf direktem und
  zurückgegebenem Modell und die Rechnung mit ANK-28. ANK-25 steht separat
  neben beiden rptR-Vorgabewerten als Installationsprüfung. Die wine-Prüfung
  rechnet beide Links direkt nach; ANK-21 prüft clmm2 getrennt.
- **E2:** `converged` kommt aus der finalen Engine-Diagnose. Echte
  ucminf-Eintermfits, nlminb-Matrix-/Mehrtermfits trotz ucminf-Anforderung,
  singulärer glmer-Erfolg und Limitabbrüche sind geprüft. Numerischer
  Direktweg, geschlossener und analytischer Abschluss verwenden den
  finalen lme4-Code samt Meldungen; Startdiagnosen entscheiden nicht,
  numerische Warnungswege werden nicht ergänzt oder umgeschrieben.
- **E3 / BL-81:** Binärwerte werden vor Ganzzahlkonversion exakt geprüft;
  Labelkodierung verlangt zwei eindeutige nichtfehlende Labels. Fehlende
  Gruppierungen, konstante/fehlende Kategorien enden benannt. Entfernte
  Antworten werden gewarnt; Modell, bereinigte Daten und Zählungen stimmen
  überein. Gegenrechnungen und Metamorphieprüfungen siehe ADR-026 Nr. 8.
- **E4 / K-M1b-4:** jeder ordinale Zwei-Stufen-Fit warnt mit Formel,
  positiver Verzerrung und Dokumentationsverweis. Fit und GRR nennen jede
  abgeleitete Quelle einzeln; GRR übernimmt `attr(vc, "derived")`.
  Kontrastdifferenzen liefern die gleiche Formel auch bei Sum-Codierung.
  Hilfe, NEWS und Vignette erklären die fehlende AIAG-Korrektur und
  verweisen auf `two_level`. Echte AP1-Tests behalten Range-/Ausschluss-
  warnungen ohne Rückfall und führen bei clmm-Limitabbruch den numerischen
  Rückfall mit erhaltenen Diagnosen aus.
- **E5 / K-M1b-2/-3:** drei installierbare CLI-Skripte, alle acht
  ADEMP-Szenarien, feste Seeds je Szenario/Wiederholung, alle geforderten
  Schätzziele und Kennzahlen samt MCSE. Finite nichtkonvergierte/singuläre
  Fits bleiben enthalten. Fehler bleiben als NA-Zeilen erhalten; weniger
  als zwei finite Schätzer sichert Replikate/Session vor benanntem Abbruch
  ohne Ergebnisdatei. CLI-, RNG-, Null-RMSE- und Zusammenführungsprüfungen
  verwenden kleine ausdrücklich synthetische Fixtures. Die ausführbare
  Betreiberanleitung deckt Vollläufe und geprüfte disjunkte Teilläufe ab.
- **E6:** nur Suggests ergänzt (`rptR`, `performance`, `parallel`), keine
  neue Import-Abhängigkeit und kein Export. Optionale Unit-Abhängigkeiten
  werden vor Nutzung geprüft. Vollständige Ankerkopien, Hashmanifest,
  doppelte ANK-TOL-Kopie, fehlende/veränderte Originale und öffentliche
  Paketverwendung sind geprüft; Referenzwerte werden nicht abgetippt.
- **E7/E8:** Betreiberentscheidungen ADR-024 übernommen; keine Änderung
  an Mutationsauswahl, Rollback, Gates oder deren Fakten.
- **E9/E10:** Warnungsorakel-Konflikt gemäß ADR-025 Nr. 4 separat unten
  als OUT-OF-TERRITORY [INFRA] belegt; `R/acmg.R` bleibt bytegleich.
- **E11 / K-M1b-7:** sechs signifikante Stellen vor `kable`, ganzzahliges
  `n_sim` aus der gewählten Datei. Vorhandene Vollläufe haben Vorrang;
  ungültige Volllaufdateien brechen ab. Die Vignette führt keine Simulation
  aus. Literalprüfung verfolgt Inline-R und nachgeladene Helfer.

ADR-026 dokumentiert Ressourcen/Provenienz sowie zwei Planpräzisierungen:
die ausdrücklich gewählten Optimierer in den neuen Metamorphieprüfungen
und die zusätzlich nötige Aktualisierung des eigenen Drucktext-Snapshots
in `test-grr-rework.R`. Dort bleiben alle Zahlen-, Format-, Rückgabe- und
Singularitätsprüfungen erhalten; nur die vom neuen Vertrag ersetzte
Range-Erklärung wird exakt auf die Zeilen je Quelle umgestellt. Die beiden
bereits geplanten Bestands-Testdateien erwarten die neuen Warnungen
gezielt. Abnahmetests, QA, Fixtures, Anker und Schwellen wurden nicht geändert.

### Nachweis der Entwicklung und der Kurzläufe

Der ausgeführte Ausgangslauf mit `test_dir("tests/acceptance",
filter = "^m1b-", load_package = "source")` endete mit Exit 1:

```text
M1b baseline: 74 tests; 26 failed blocks; 27 error blocks; 0 skipped
M1b baseline elapsed seconds: 32.64; exit: 1
```

Der erste vollständige Lauf nach Implementierung fand einen tatsächlichen
CSV-Fehler: `FAIL 1 | WARN 2 | SKIP 0 | PASS 3473`; beim binären Präfix
mit zwei Wiederholungen unterschieden sich zehn Meldungszellen (`NA` versus
leere Zeichenkette). Der neue Unit-Test mit normalen `read.csv()`-Vorgaben
war vor der Korrektur rot, danach grün. Fehlende Diagnosen stehen nun als
`NA` im CSV, vorhandene Meldungen bleiben erhalten. Der erste Gesamt-Unit-
und Paketcheck fand außerdem zwei alte Drucktext-Erwartungen desselben
Blocks; ADR-026 Nr. 9 und der exakte neue Snapshot beheben das.

```text
`actual$messages`:   NA NA NA NA NA NA NA NA NA NA
`expected$messages`: "" "" "" "" "" "" "" "" "" ""
After: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 253 ]
```

Die 253 Erwartungen stammen aus dem ausgeführten Nachlauf
`test_dir("tests/testthat", filter = "^validation-simulation$|^grr-rework$",
load_package = "source")`. Die unveränderte neue Präfixprüfung ist darunter.
Die übrigen gezielten Kernprüfungen bestanden zuvor mit 533 Erwartungen;
die Ressourcen- und Literalprüfungen mit 172, jeweils ohne Fehler/Warnung/Skip.

Das finale Paket wurde nur in `/tmp/llmsa-m1b-build/library` installiert;
vorhandene Abhängigkeitsversionen blieben erhalten. Erzeugung mit dem
installierten Paket aus einem fremden Arbeitsverzeichnis, `n_sim` aus
ANK-TOL.n_check; die Dateien wurden erst nach drei erfolgreichen Prozessen
byte-identisch als `_check_` übernommen:

```bash
R CMD INSTALL --library=/tmp/llmsa-m1b-build/library .
M1B_SHORT_RUN=checks-final-v2 python3 /tmp/llmsa-m1b-build/generate_checks.py
```

Der Treiber führt je Studie tatsächlich aus:

```text
Rscript --vanilla /tmp/llmsa-m1b-build/library/llmsa/validation/sim/<study>.R --n-sim 20 --out /tmp/llmsa-m1b-build/checks-final-v2/<study>
```

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 104.660 s; workers 14
ordinal_recovery: exit=0; wall_seconds=105.346
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.878 s; workers 14
binary_recovery: exit=0; wall_seconds=1.533
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.696 s; workers 14
two_level: exit=0; wall_seconds=11.352
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle 160 Wiederholungen liefern finite Schätzer. Gespeicherte Diagnosen:
ordinal 18/80 nichtkonvergiert und 63/80 singulär; binär 0/40 und 7/40;
two_level 0/40 und 1/40. Das sind Kurzlauf-Diagnosen, keine Befunde zur
statistischen Güte der Vollstudien. Nur neun Kurzlaufdateien liegen im
Repo, keine Betreiber-Volllaufdateien.

Weitere ausgeführte Reproduktionsprüfungen:

```bash
Rscript --vanilla data-raw/make_validation_latent.R --out /tmp/llmsa-m1b-build/resource-reproduction
M1B_WORKER_RUN=workers-final python3 /tmp/llmsa-m1b-build/check_workers.py
```

```text
Latent validation inputs: 5 byte-identical anchors; SHA-256 provenance recorded
Resource reproduction: all five whole anchor copies and SOURCES.json are byte-identical.
Worker/order reproduction: result and replicate CSVs byte-identical; 78 installed files unchanged in read-only library.
```

Die Workerprüfung rechnet S-bin-1/S-bin-2 mit `--n-sim 2` einmal mit einem
und einmal mit zwei Workern sowie umgekehrter Szenarioreihenfolge. Sie lädt
eine schreibgeschützte Installation aus einem fremden Arbeitsverzeichnis
und prüft anschließend deren vollständige Dateihashes.

### Abschließende Abnahme- und Regressionsdiagnosen

Alle folgenden Läufe verwenden R 4.6.1, lme4 2.0.6, ordinal 2026.7.26,
Matrix 1.7.4, rptR 0.9.23 und performance 0.19.0. `TZ=Europe/Berlin`
vermeidet die hier gesperrte Systembus-Abfrage von `sessionInfo()`;
Zufallsströme und Engine-Einstellungen werden dadurch nicht verändert.
Nach Abschluss der Dateierzeugung blieb der gesamte Testinput unverändert.

**Unveränderte M1b-Abnahme (Exit 0).** Ausgeführt als eigener
`TZ=Europe/Berlin /usr/bin/time -f 'M1b acceptance elapsed seconds: %e; exit: %x'
Rscript --vanilla -e '<R-Code>'` mit diesem R-Code:

```r
Sys.setenv(REPO_ROOT = normalizePath("."))
grDevices::pdf(NULL)
testthat::set_max_fails(Inf)
r <- testthat::test_dir("tests/acceptance", filter = "^m1b-",
  load_package = "source",
  reporter = testthat::ProgressReporter$new(show_praise = FALSE),
  stop_on_failure = FALSE)
d <- as.data.frame(r)
write.csv(d[, c("file", "test", "failed", "error", "skipped", "passed")],
  "/tmp/llmsa-m1b-build/m1b-tests-final.csv", row.names = FALSE)
cat(sprintf("M1b acceptance: %d tests; %d failed blocks; %d error blocks; %d skipped\n",
  nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped)))
quit(status = as.integer(any(d$failed > 0 | d$error)))
```

```text
[ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
M1b acceptance: 74 tests; 0 failed blocks; 0 error blocks; 0 skipped
M1b acceptance elapsed seconds: 225.55; exit: 0
```

Der ausgeführte Abnahmelauf für alle sieben Kriterien besteht,
einschließlich kompletter Reproduktionen aller Kurzläufe, Präfixen,
MCSE-Nachrechnungen, Laufzeitgrenzen, echtem Knit und Auswahl vorhandener
Volllaufdateien in der öffentlichen temporären Paketkopie. Die beiden
Warnungen stammen unverändert aus `test-m1b-4-two-levels.R:41–42`:
`nobars` und `findbars` sind laut installiertem lme4 nach `reformulas`
verschoben. Keine Fehl-Erwartung, kein Skip und kein Produkt-Scheinfix.

**M1a-Regression (Exit 0).** Separater Rscript-Aufruf mit demselben
`test_dir`-Laufkern, Filter `^m1a-`, gesetztem `REPO_ROOT`, PDF-Gerät nach
`NULL`, vollständiger Ergebnisauswertung und Exit ungleich 0 bei Fehlern:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a regression: 54 tests; 0 failed blocks; 0 error blocks; 0 skipped
M1a regression elapsed seconds: 47.05; exit: 0
```

**Unit-, E2E- und Fuzz-Regression (Exit 0).** Tatsächlicher Aufruf:

```bash
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa \
  /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' \
  tests/testthat tests/e2e tests/fuzz
```

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3221 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 239 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 133.90; exit: 0
```

Der eine Skip ist der unveränderte ellmer-Fehlerpfad bei installiertem
ellmer. Beide QA-Verzeichnisse laufen vollständig und bytegleich zum
Ausgangsstand. Der bestehende Report-Test läuft hier durch `NOT_CRAN=true`
im unveränderten Testtreiber.

**Öffentlicher Paketbau und installierter Check (je Exit 0).** Eine
Positivliste kopiert 138 Paket-/Testdateien ohne Git und ohne Betreiber-
Fixtures, Schlüssel oder Harness-Zustand nach
`/tmp/llmsa-m1b-build/package-check-final/src`. Der ausgeführte Treiber ist
`M1B_CHECK_WORK=/tmp/llmsa-m1b-build/package-check-final python3
/tmp/llmsa-m1b-build/check_package.py`; er entfernt `REPO_ROOT` aus der
Prozessumgebung und führt dort mit `TZ=Europe/Berlin` aus:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
build.log: exit=0; wall_seconds=59.157
check.log: exit=0; wall_seconds=172.713
Status: 1 NOTE
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 3145 ]
```

Beide Vignetten wurden gebaut und beim Check erneut gebaut. Die neun
installierten Skips sind fünf ausgeschlossene Betreiber-Aufzeichnungen,
der CRAN-Report-Test, die beiden Originalanker-Vergleiche ohne Repository
und der bestehende ellmer-Fehlerpfad. Alle anderen neuen Tests laufen auch
installiert. Remote-Incoming entspricht dem Betreiber-Prüfskript; keine
weitere Check-Regel wurde abgeschaltet.

Vollständige Logs und Auswertungs-CSV liegen unter
`/tmp/llmsa-m1b-build/`: `m1b-acceptance-final.log`, `m1a-regression.log`,
`unit-qa-final.log`, `m2-regression-final.log`, `package-check-final/`.


### Einschränkungen und Handoff-Vorschläge

**E9/E10 — OUT-OF-TERRITORY [INFRA].** Ref: ADR-025 Nr. 4 und
Konsequenzen; K-M2-6/-7; `tests/acceptance/setup-m2.R:714,869–883`.
Der Builder unterdrückt keine Range-/Ausschlusswarnung und erweitert
keinen AP1-Rückfallauslöser. Der Reviewer muss die bereits beschlossene
unabhängige Orakelregel umsetzen und den BACKLOG-Eintrag führen.

Unveränderte K-M2-6/-7, separat ausgeführt mit demselben Rscript-
Laufkern wie oben, Filter `^m2-[67]-`, CSV `m2-tests-final.csv`, Auswertung
aller 19 Testblöcke und Exit 1 bei roten Tests. Echte Endausgabe:

```text
[ FAIL 20 | WARN 0 | SKIP 0 | PASS 689 ]
M2 regression: 19 tests; 4 failed blocks; 1 error blocks; 0 skipped
M2 regression elapsed seconds: 398.75; exit: 1
```

Genau 19 Erwartungen in vier Blöcken betreffen die bereits beschlossene
Orakelkorrektur: je Modell zweimal (`fallback` und Typ) im Hauptplan, in
den konstruierten Läufen und mit Robustheitsauswertung, dazu der Typ des
gemeinsamen Fits. Tatsächliche Ausgabe jeweils `FALSE` statt erwartetem
`TRUE` bzw. `"ordinal"` statt `"numeric"`. Der fünfte rote Block ist der
gesperrte Socket (unten). Erzwungene Fehler/Konvergenzwarnungen lösen den
geforderten Rückfall aus; die übrigen Erwartungen bleiben grün.

Ein vorheriger Lauf meldete zusätzlich zwei Datei-Inventurfehler, weil
der parallel abgeschlossene Kurzlauf seine neun neuen Dateien während
der AP1-Inventur kopierte. Das war eine Störung durch die Reihenfolge
der Builder-Diagnosen. Die vollständige Wiederholung erfolgte erst nach
Abschluss aller Dateischreibvorgänge; beide Inventurprüfungen bestehen
jetzt. Diese beiden alten Fehlschläge werden nicht als [INFRA] abgegeben.


**M1B-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Ref:
K-M2-7, `tests/acceptance/setup-m2.R:771`, `req_dry_run()` und der
HTTP-Replay-Test. Der echte Fehler lautet
`System failure for: socket() (Operation not permitted)`.
Kein Bypass und keine Abschwächung dieses Tests.

**M1B-NUM-01 — offener fachlicher Befund / Handoff-Vorschlag.** Ref: docs/01 §2
(Metamorphie), PLAN-UPDATE „Testplan“ E3/E4, ADR-026 Nr. 8.
Für den neuen synthetischen Fixture-Seed liefern Standardoptimierer trotz
gleichem mathematischem Modell kleine Parameterisierungsunterschiede
oberhalb ANK-TOL.invariance. Tatsächlich gemessen (Komponentendifferenz/TV):

```text
binary, default bobyqa/Nelder_Mead, event reversal: 1.60286127649222e-06
binary, bobyqa/bobyqa with rhoend from ANK-TOL.engine_boot: 1.03795717323999e-07
ordinal, default nlminb, sum contrasts: 1.12331735442896e-06
ordinal, default nlminb, renamed/reversed levels and rows: 8.13388012911663e-06
ordinal, default ucminf, sum contrasts: 3.25822451182535e-08
ordinal, default ucminf, renamed/reversed levels and rows: 1.16080065153201e-08
```

Reproduktion: `pkgload::load_all(".")`, beide Testhelfer
`helper-validation-numeric.R` und `helper-validation-latent.R` sourcen;
binär `latent_test_runs("binary", prompts=1L, models=1L)` in die Labels
`no`/`yes` umwandeln und `levels` vertauschen; ordinal
`latent_test_runs(prompts=2L, models=2L, blocks=2L)` mit Treatment-/Sum-
Kontrasten bzw. umgekehrten Zeilen und Zuordnung erste Stufe→`z`, zweite→`a`
fitten. Verglichen wird `max(abs(vc_new - vc_reference))/sum(vc_reference)`
nach Quellennamen. Die neuen Property-Tests verwenden die expliziten
Steuerungen aus ADR-026 bei unveränderter Toleranz und prüfen echten
Optimierererfolg. Kleinere clmm-Toleranzen allein halfen nicht zuverlässig
(ucminf-Code 4); deshalb keine pauschale Änderung der Produktvorgaben.
Die allgemeine Invarianzforderung ist für diese Vorgabepfade mit diesem
Beleg nicht erfüllt; die erfolgreichen Prüfungen mit expliziten
Optimierern ersetzen den offenen Nachweis nicht. Vorschlag an den
Reviewer: ADR-026 Nr. 8 bewerten und erforderliche Nacharbeit am
Vorgabepfad festlegen. Die Einstufung verbleibt beim Reviewer.
Logs: `invariance-diagnosis.log`, `contrast-diagnosis.log`
unter `/tmp/llmsa-m1b-build/`.

**M1B-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Ref: lint,
Paketcheck `00check.log`, „checking for future file timestamps“.
Die einzige NOTE lautet `Unable to verify current time.` Die Prüfung
blieb aktiv; der Check hat keine ERRORs oder WARNINGs. Windows wurde in
dieser Linux-Sitzung nicht ausgeführt; die Windows-CI bleibt Release-Bedingung.

### Integrität

`python3 /tmp/llmsa-m1b-build/integrity.py` endet mit Exit 0:

```text
Baseline inventory: 269 files; 11 changed in assigned Builder paths; 258 byte-identical; no removed files.
New files: 31, all in assigned Builder paths.
Changed: DESCRIPTION, NEWS.md, PROGRESS.md, R/fit.R, R/grr.R, man/msa_fit.Rd, man/msa_grr.Rd, tests/testthat/test-fit-grr.R, tests/testthat/test-fit-rework-inputs.R, tests/testthat/test-grr-rework.R, vignettes/validation.Rmd
Protected baseline tests/acceptance/: 33/33 files byte-identical.
Protected baseline tests/e2e/: 2/2 files byte-identical.
Protected baseline tests/fuzz/: 2/2 files byte-identical.
Protected baseline tests/fixtures/: 6/6 files byte-identical.
Protected baseline tests/simulation/: 1/1 files byte-identical.
Protected baseline reference/anchors/: 36/36 files byte-identical.
Protected baseline inst/extdata/: 17/17 files byte-identical.
Protected baseline orchestrator/handoff/M1b/: 8/8 files byte-identical.
Protected baseline orchestrator/state/: 3/3 files byte-identical.
final-test-inputs.json: 170 files byte-identical to the final tested inputs.
package-check-final/source-sha256.json: 138 files byte-identical to the final tested inputs.
All nine check files match the final generated files; no full-run files in the repository.
No package-check, plot, archive or SQLite artifacts at the repository root.
This inventory is a Builder integrity check, not an orchestrator gate verdict.
```

Keine Git-Kommandos, fremden Schreibterritorien, Abhängigkeitsdownloads,
realen API-Aufrufe, Test-/Gate-Umgehungen oder Builder-Verdicts. Formale
Territoriumsprüfung, Gates einschließlich Mutation und Phasen-Commit
verbleiben beim Orchestrator; kein neuer Mutationsscore wird behauptet.


## M1a — REWORK, Runde 5 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 4 verlangt REWORK wegen E54.
Die unveränderten Orchestrator-Fakten nennen acht grüne Gates, `result:
pass`, mutgate 93,74 bei required 91,79; kein Status error und kein
aktueller QA-PENDING-Befund. ARBITER fehlt, LESSONS enthält keine Lehren.
Die neue Gate-Abnahme verbleibt beim Orchestrator und Reviewer.

**E54 ist im Produktcode behoben.** `R/fit.R:514–547` schützt den
Aufbau des numerischen Originalskalenmodells: `lFormula`, `mkLmerDevfun`,
`devfun(theta)`, `mkMerMod` und das Auslesen von `VarCorr`. Fehler und
Warnungen an diesen Enginegrenzen beenden den Fit mit
`Numeric model variance is not representable on the original scale at working precision.`
Die Klasse ist `simpleError`, der Aufruf `NULL`. `checkConv` steht
separat und gibt Konvergenzwarnungen weiter. Gesammelte Startwarnungen
werden beim späteren Abbruch weiterhin in ihrer Reihenfolge ausgegeben.
Der explizite Durchreichweg behält die originalen Enginebedingungen.
Schätzer, Nullgrenze, Präzisionsgrenze und Abschlusskriterium bleiben
unverändert; ein Teilmodell wird nicht als Ergebnis verwendet.

Neu sind 18 Testblöcke in `tests/testthat/test-fit-model-construction.R`.
Die drei E54-Reproduktionen und der positive Gegenfall werden mit
`stats::aov` und den expliziten EMS-Formeln aus der Formelsammlung §2
geprüft. Fehler und Warnungen an allen fünf Enginegrenzen, aktive
Konvergenzprüfung, Startwarnungen und Durchreichweg werden zusätzlich
synthetisch geprüft. Numerische Toleranzen kommen aus ANK-TOL; nur der
Diagnosetext ist eigene Ausgabe. Vor der Korrektur scheitern 15 Blöcke
mit 47 falschen Erwartungen, danach bestehen alle 129 Erwartungen.
Die neue Datei blieb zwischen beiden Läufen gleich.

E55/BL-89 bleibt **OUT-OF-TERRITORY für diesen Auftrag, nonblocking**:
Der Auftrag untersagt die Änderung bestehender Tests. Deshalb bleibt
`test-fit-initialization.R:22–49` byte-identisch. Die neuen E54-Tests
erlauben auf einer anderen Plattform einen erfolgreichen Fit nur mit
den unabhängig berechneten ANOVA-Komponenten; sie erzwingen keinen
Engineabbruch. Synthetische Bedingungen sichern den genauen Fehlervertrag.
Windows/macOS wurden hier nicht geprüft.

E56: `?msa_fit` nennt jetzt auch den Modellbau nach geschlossener Lösung
als mögliche Fehlerstelle bei hoher Wiederholpräzision und ordnet die
mögliche Hessian-Warnung auf der Theta-Skala ein. ADR-020, Nachtrag
Runde 5, enthält die zusätzliche balancierte Gegenrechnung. Die allgemeine
Verbesserung des Abschlusses und dessen weitergehender Robustheitsnachweis
aus E51/BL-87 bleiben vor M1d offen. NEWS und die erzeugte Rd-Hilfe
dokumentieren den Produktfix.

E50 und E52 sind laut REVIEW Runde 4 erledigt. E53/BL-84 bleibt mit
seinen nicht verlangten Darstellbarkeits- und Redundanzfällen offen.
Die zehn bestehenden Äquivalenzanträge wurden gegen identische
Quellzeilen und die zwölf zugehörigen Überlebenden des Berichts Runde 4
neu gebunden: neun Einträge in R/fit.R um fünf Zeilen verschoben,
R/grr.R bytegleich. Keine neue Äquivalenz und keine eigene Approval.
E48/BL-85, E49/BL-86 und E41/BL-79 sind OUT-OF-TERRITORY [INFRA].
E39/BL-77 und E42/BL-80 bleiben beim Betreiber/Reviewer,
E43/BL-81 gemäß ADR-022 in M1b. BACKLOG bleibt unverändert.

Vollständige Antworten, Kommandos und Log-Bezüge stehen in
`orchestrator/handoff/M1a/REWORK-NOTES.md`; Diagnoseartefakte unter
`/tmp/llmsa-m1a-r5/`. Echte Ausgaben dieser Runde:

```text
Model construction regression: 18 tests; 15 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 129 ]
Model construction regression: 18 tests; 0 failed blocks; 0 errors; 0 skipped
120 cases; 8 raw errors before, 0 after; 6 arithmetic warnings before, 0 after
45 unchanged successful fits; maximum component/TV error against aov EMS 3.76805041e-09 (ANK-TOL.oracle 0.0001)
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2809 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 215 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 80.00; exit: 0
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 37.05; exit: 0
```

Die drei E54-Einzelfälle liefern jetzt den Darstellbarkeitstext,
`simpleError`, `call = NULL` und null Warnungen. Die Sensitivitätsrechnung
verwendet 120 feste synthetische Prüfeingaben: 6×4×1×2, 8×3×1×3 und
10×3×2×2 (Items×Prompts×Modelle×Replikate), Effekte mit Seed 11,
Rauschen `10^(-3:-10)` mit Seeds 1001–1005. Alle haben nichtnegative
EMS-Schätzer und positive Reststreuung über der unveränderten Nullgrenze.
45 Fits bleiben erfolgreich und exakt gleich zum Ausgangscode;
34 Fälle enden benannt wegen Darstellbarkeit, 41 wegen nicht auflösbarer
Restskala. Kein zusätzlicher Konvergenzerfolg, keine ADEMP-/Coverage-Aussage.
Bei Rauschen `1e-4` und `1e-5` bleibt im E54-Plan die vom Reviewer
beschriebene Hessian-Warnung sichtbar; bei `1e-3` ist der Fit warnungsfrei.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual`: jeweils
Exit 0, keine ERRORs/WARNINGs, Vignetten neu gebaut. Echter Check-Output:

```text
Status: 1 NOTE
Package check elapsed seconds: 123.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2734 ]
```

Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
den CRAN-Report-Test, Originalanker ohne Repository und ellmer. Alle neuen
Tests laufen installiert. Der NOTE lautet `Unable to verify current time.`;
die Zeitprüfung blieb aktiv. Die mirai-Probe endet mit `16 | Permission
denied` (Exit 1). `sessionInfo()` meldet zusätzlich den gesperrten lokalen
Systembus/`timedatectl`; der numerische Diagnosetreiber endet mit Exit 0.
Diese Infrastrukturgrenzen sind mit tatsächlichen Logs OUT-OF-TERRITORY
dokumentiert. Kein neuer Mutationsscore wurde erzeugt.

`python3 /tmp/llmsa-m1a-r5/integrity.py` bestätigt mit Exit 0:
315 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
308 bytegleich, keine gelöscht; eine neue Testdatei. Alle 69 bestehenden
Test-/Fixture-Dateien bleiben bytegleich, ebenso Anker, Golden-Daten,
Specs, Gates, Mutationsbericht, Reviewer-Approvals und BACKLOG. Alle
110 öffentlichen Quelldateien stimmen mit der geprüften Paketkopie
überein. R/fit.R SHA-256:
`fff305a2c353c1f6bce60e549712913525e9c731087b0e6eac33fa1f6933be1c`.
Die Inventur ersetzt keine Territoriumsprüfung. Keine Git-Kommandos,
Abhängigkeitsinstallation oder eigenen API-Aufrufe. Territoriumsprüfung,
Phasen-Commit, Gates und Review verbleiben bei den zuständigen Rollen;
dieser Eintrag ist ein Builder-Prüfbeleg, kein Verdict.


## M1a — REWORK, Runde 4 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 3 verlangt REWORK wegen E50.
Die unveränderten Orchestrator-Fakten nennen acht grüne Gates, `result:
pass`, mutgate 93,72 bei required 91,79; kein Status error und kein
QA-PENDING. ARBITER fehlt, LESSONS enthält keine Lehren. Die aktuelle
Gate-Abnahme verbleibt beim Orchestrator und Reviewer.

**E50 ist im Produktcode behoben.** `R/fit.R:471` fängt Fehler des
lme4-Startfits im numerischen Vorgabepfad ab und meldet
`Numeric model initialization failed: ` mit der ursprünglichen
Engine-Meldung als Ursache. Die äußere Klasse ist `simpleError` ohne
internen Aufruf; die Warnungen des fehlgeschlagenen Starts werden weiterhin
in ihrer Reihenfolge weitergegeben. Positive Reststreuung wird nicht als
null umgedeutet. Daten, Nullgrenze, Präzisionsprüfung und Abschlusskriterium
bleiben gleich. Der explizite lme4-Durchreichweg behält seine Fehlerklassen,
Meldungen und Warnungen. ADR-020, Nachtrag Runde 4, NEWS.md und die
erzeugte Hilfe `man/msa_fit.Rd` dokumentieren die Änderung.

Die neue Datei `tests/testthat/test-fit-initialization.R` prüft die drei
realen E50-Reproduktionen mit positiver Restquadratsumme aus `stats::aov`,
die Engine-Ursache gegen einen direkten lme4-Aufruf, die Weitergabe zweier
synthetischer Startwarnungen, den expliziten Durchreichweg und positive
Gegenfälle gegen lme4 bei zwei absoluten Skalen. Vor der Codeänderung
scheitern vier der sechs Blöcke; danach bestehen alle 79 Erwartungen.
Die Testdatei wurde zwischen diesen beiden Läufen nicht verändert.

E51: `?msa_fit` nennt jetzt die Einschränkung bei hoher Wiederholpräzision;
die numerische Verbesserung und der zusätzliche Robustheitsnachweis
bleiben BL-87/nonblocking vor M1d. E52: ADR-020 dokumentiert den
Speicher-/Rechenaufwand der dichten Projektion und die größeren Messfälle
aus REVIEW Runde 3 mit ausdrücklicher Quellenangabe; keine Behauptung
einer Performanceverbesserung. E53: zwei Index-Äquivalenzen sind mit
ausgeführtem Beleg beantragt, weitere Darstellbarkeits- und Redundanzpunkte
bleiben BL-84/nonblocking. Sieben ältere R/fit.R-Claims wurden auf
identische Quellzeilen versetzt; R/grr.R bleibt unverändert. MUT-EQUIV.json
enthält zehn Anträge, keine Genehmigung. MUT-EQUIV-APPROVED.json bleibt
bytegleich. E48/BL-85 und E49/BL-86 sind OUT-OF-TERRITORY [INFRA].

Echter Output unter `/tmp/llmsa-m1a-r4/`; Befehle, einzelne Antworten und
vollständige Log-Bezüge in `orchestrator/handoff/M1a/REWORK-NOTES.md`:

```text
[ FAIL 9 | WARN 0 | SKIP 0 | PASS 70 ]
Initialization regression: 6 tests; 4 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 79 ]
Initialization regression: 6 tests; 0 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2680 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 197 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 85.75; exit: 0
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.65; exit: 0
Count-vector enumeration: 9837 vectors, lengths 2..8, entries 1..3; both predicates identical
Balanced helper: 4 valid designs x 2 index mutations; outputs and warnings exactly identical
Equivalence evidence only; no mutation score or approval.
```

Die M1a-Abnahme enthält Originalanker, geschützte AIAG-Daten, NIST,
Paketorakel und geknittete Vignette. Der einzige Quellbaum-Skip ist der
bestehende ellmer-Negativtest. Keine neuen Skips oder geänderten Tests.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual` jeweils
Exit 0; keine ERRORs/WARNINGs, Vignetten neu gebaut. Echter Check-Output:

```text
Status: 1 NOTE
Package check elapsed seconds: 129.93; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2605 ]
```

Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
den CRAN-Report-Test, Originalanker ohne Repository und ellmer. Alle neuen
Tests werden ausgeführt. Der NOTE lautet `Unable to verify current time`;
die Zeitprüfung bleibt aktiv. Die lokale mirai-Probe endet mit
`16 | Permission denied` (Exit 1). Beides ist mit aktuellem Log-Beleg als
OUT-OF-TERRITORY [INFRA] dokumentiert. Kein vollständiger Mutationslauf
oder neuer Gate-Score wurde erzeugt.

`python3 /tmp/llmsa-m1a-r4/integrity.py` bestätigt mit Exit 0:
295 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
288 bytegleich, keine gelöscht; eine neue Testdatei. Alle 68 bestehenden
Test-/Fixture-Dateien sind bytegleich. Alle 109 öffentlichen Quelldateien
stimmen mit der geprüften Paketkopie überein. Gate-Fakten, Mutationsbericht
und Reviewer-Approvals sind unverändert. R/fit.R SHA-256:
`73caf9801081da31ef01ab26c3e026c44c34f4060804329b7f63e84e902ebd94`.
Die Inventur ersetzt keine Territoriumsprüfung.

Keine Git-Kommandos, Abhängigkeitsinstallation oder eigenen API-Aufrufe.
Orchestratorzustand, BACKLOG, Abnahmetests, QA-Tests, Fixtures, Anker,
Golden-Daten, Specs, Gates und Schwellen bleiben unverändert.
Territoriumsprüfung, Phasen-Commit, Gates und Review erfolgen durch die
zuständigen Rollen. Das ist ein Builder-Prüfbeleg, kein Verdict.


## M1a — REWORK, Runde 3 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 2 verlangt REWORK wegen E44.
`orchestrator/state/M1a/gates.json` nennt Runde 2 mit acht grünen Gates,
`result: pass`, mutgate 93,79; kein Status error, kein QA-PENDING.
ARBITER fehlt, LESSONS enthält keine Lehren. Diese historischen
Gate-Fakten bleiben unverändert; die aktuelle Abnahme folgt durch den
Orchestrator und Reviewer.

**E44 ist im Produktcode behoben.** Der allgemeine numerische Pfad
prüft vor dem lme4-Startfit die Restnorm der konditionierten Antwort
auf dem Spaltenraum des tatsächlichen Zufalls-Intercept-Designs.
Rangaufdeckende QR erlaubt unbalancierte Pläne, abhängige Spalten und
fehlende Zellen. Die vorhandene relative Restvarianzgrenze bleibt gleich.
Die Diagnose verlangt positive Restfreiheitsgrade der Projektion:
Ein gesättigter Spaltenraum lässt keinen Schluss auf die REML-Restvarianz
zu; der neue Gegenfall wird gegen lme4 und die geschlossene Randlösung geprüft.
Identische Replikate mit ausgelassener Wechselwirkung dürfen weiterhin
positive Modellrestvarianz haben. Der explizite lme4-Durchreichweg bleibt
unverändert. Umsetzung: R/fit.R; Begründung: ADR-020, Nachtrag Runde 3;
neue Regressionen: tests/testthat/test-fit-residual-design.R.

E45 und E46 sind über die vom Reviewer vorgeschlagene Dokumentationsoption
in R/fit.R und man/msa_fit.Rd behandelt: große gespeicherte lme4-Aufrufe
sowie die unmittelbare Aufruferumgebung datenbezogener Ausdrücke.
NEWS nennt die Diagnose vor dem Startfit. E47 ist teilweise behandelt:
dünn besetzte Pläne gegen lme4 und kleines positives Q gegen eine
unabhängige Rang-eins-Formel; vier benannte Überlebende werden lokal
erkannt. Die getrennten Darstellbarkeitsfälle bleiben BL-84/nonblocking.

E48/BL-85 und E49/BL-86 sind **OUT-OF-TERRITORY [INFRA]**, mit aktuellen
Log-Belegen und vollständiger Antwort auf alle IDs in
`orchestrator/handoff/M1a/REWORK-NOTES.md`. Die sieben verschobenen
Äquivalenz-Claims in R/fit.R wurden bei unverändertem Quelltext auf neue
Zeilen gesetzt und erneut beantragt; der achte in R/grr.R:94 bleibt gleich.
Die Reviewer-Approval-Datei wurde nicht geändert. E39/E41/E42 bleiben
beim Betreiber/Reviewer, E43 gemäß ADR-022 in M1b.

Echte Ausgaben aus `/tmp/llmsa-m1a-r3/`; vollständige Kommandos im Handoff:

```text
Baseline regression: 8 tests; 3 failed blocks; 0 errors; 0 skipped
Neue Tests: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 124 ]
Unit: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 2601 ]
E2E: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
Fuzz: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 191 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 78.44; exit: 0
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.72; exit: 0
```

Die M1a-Abnahme besteht mit 722 Erwartungen einschließlich Originaldaten,
Orakeln und geknitteter Vignette. Bestehende Tests sind unverändert.
Der einzige Quellbaum-Skip ist der bekannte ellmer-Negativtest.
Die endgültigen neuen Tests wurden gegen die alte R/fit.R ausschließlich
in einer temporären Paketkopie geprüft; der Arbeitsbaum wurde nicht
zurückgesetzt. Die vier gezielten Mutationsversuche sind kein Gate-Lauf
und ergeben keinen neuen Mutationsscore.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual`: jeweils
Exit 0, keine ERRORs/WARNINGs, Vignetten gebaut, `Status: 1 NOTE`,
121,91 s; installierte Tests `FAIL 0 | WARN 0 | SKIP 8 | PASS 2526`.
Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
On CRAN, Originalanker ohne Repository und ellmer. Die neuen Tests
werden ausgeführt. Der einzige NOTE ist die weiterhin aktive
Zeitprüfung (`Unable to verify current time`). Der mirai-Probeaufruf
endet erneut mit `16 | Permission denied` (Exit 1). Keine Scheinreparatur
dieser Infrastruktur; Incoming-Remote entspricht dem Betreiber-Prüfskript.

Sechs positive Pläne haben exakt gleiche Varianzkomponenten und
Numerikdiagnosen wie der gesicherte Ausgangscode. Lokale Messung auf
ic50_demo, fünf alternierende Läufe nach Aufwärmen: Median vorher
0,489 s, nachher 0,564 s (Faktor 1,153); das zusätzliche Design mit
2152 × 297 Einträgen benötigt 4,88 MiB. Die geschlossene Lösung
benötigt diese zusätzliche Projektion nicht.

`python3 /tmp/llmsa-m1a-r3/integrity.py` bestätigt mit Exit 0:
289 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
282 bytegleich, keine gelöscht; eine neue Unit-Datei. Alle 67 vorhandenen
Test-/Fixture-Dateien bleiben bytegleich. R/fit.R, die Rd-Datei und die
neue Testdatei gleichen der geprüften Paketkopie. Gate-Fakten und
Reviewer-Approvals bleiben bytegleich; keine eigene Approval, kein Verdict
und keine Git-Kommandos. Die Inventur ersetzt nicht die Territoriumsprüfung.

## M1a — REWORK, Runde 2 (29.–30.10.2026)

Grundlage: REVIEW/verdict-code und rote Gate-Logs aus Runde 1,
CRITERIA K-M1a-1 bis K-M1a-7 sowie ADR-022. ARBITER liegt nicht vor;
LESSONS enthält keine Lehren. Die vollständige Antwort auf **E18–E43**
mit Dateien, Kommandos und echtem Output steht in
`orchestrator/handoff/M1a/REWORK-NOTES.md`.

Produktkorrekturen: selbsttragende lme4-Aufrufe auch bei lokalem explizitem
`control`; Datenmaske für `subset`/`weights`/`offset` und tatsächliche
Modellzeilen in `data`, `n` und `input_rows`; relative Restvarianzdiagnose;
benannte Ablehnung von Originalskalen mit unzureichender Genauigkeit;
einheitliches numerisches NaN-/Gruppierungsverhalten; validierte
GRR-Schwellen und vollständige Ressourcenprovenienz. ADR-020 begründet
die Numerikergänzung. NEWS und die Hilfen dokumentieren die Fehler und den
Abbruch der Planung bei einem gescheiterten Fit.

Neue Unit-Tests unter `tests/testthat/` prüfen die Mutationsbefunde gegen
ANOVA/EMS, dichte REML-Formeln, lme4/ordinal, Differenzenquotienten,
ANK-16 und Quantile. Ausgabe-Charakterisierungen sind ausdrücklich markiert.
Die einzige rein mutationsbezogene Produktvereinfachung entfernt eine
wirkungslose Restvarianzrechnung nach Festlegung des Quotienten auf null
und das redundante `na.rm` nach Filterung auf endliche Bootstrapwerte.
Keine bestehenden Tests, Abnahmetests, QA-Tests, Gates, Schwellen, Anker
oder Specs wurden geändert. Keine eigenen Git-Kommandos.

Ausgeführte Belege unter `/tmp/llmsa-m1a-r2/`:

```text
QA vor Korrektur: r-tests: fail — 10 Tests; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
QA nach Korrektur: r-tests: pass — 10 Tests; 0 fehlgeschlagen, 0 Fehler, 0 übersprungen
Unit-/QA-Abschlusslauf: r-tests: pass — 183 Tests; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped; 65.65 s
M2 evaluation: 10 tests; 0 failed blocks; 0 errors; 0 skipped; 424.42 s
Final rework regression: 33 tests; 0 failed blocks; 0 errors; 0 skipped; 14.12 s
```

M1a-Abnahme: `PASS 722`, M2-Auswertung: `PASS 374`, jeweils `FAIL 0`,
`WARN 0`, `SKIP 0`. Der Unit-Skip ist der bestehende ellmer-Negativtest.
Beide Paketchecks (öffentlich/mit Originalankern) liefen mit Exit 0,
ohne ERROR/WARNING und mit dem Infrastruktur-NOTE „Unable to verify
current time“. Die Prüfung wurde nicht deaktiviert. Die letzten zwei
Testergänzungen sind im separaten Abschlusslauf der 33 neuen Tests mit
`PASS 479`, `FAIL 0`, `WARN 0`, `SKIP 0` belegt.

Zusätzliche lokale Mutationsdiagnose (ausdrücklich kein Gate-Ersatz):
vollständige `muttest`-Generation über `R/fit.R`, `R/grr.R`, 14 unabhängige
R-Prozesse, zunächst eine benannte Teilmenge mit 41 Unit-Tests. Output:

```text
Finished diagnostic mutation run in 1245.6s; {'Killed': 823, 'Survived': 145, 'RuntimeError': 111, 'Timeout': 26}
```

Das sind 85,41 % nach der Statusformel ohne Äquivalenzabzug; allein Killed
bei im Nenner belassenen Timeouts ergibt 82,80 %. Dieser eingefrorene Stand
enthält noch die später entfernte überflüssige Restvarianzrechnung. Der
frische Plan zum Abschlusscode enthält 1097 Mutanten, deren Quellen mit
den alten Mutanten nach Entfernung genau dieser Zeile abgeglichen wurden.
Fünf Überlebende entfielen mit dieser Rechnung; die übrigen 140 wurden
gegen den finalen Stand mit 45 Tests/575 Erwartungen erneut ausgeführt:

```text
Finished diagnostic mutation run in 120.7s; {'Survived': 70, 'Killed': 61, 'RuntimeError': 9}
```

Keine Zusammenrechnung zu einem angeblichen Gate-Lauf. Acht einzeln
begründete Claims in `orchestrator/handoff/M1a/MUT-EQUIV.json` betreffen
zehn dieser verbleibenden Mutanten. Exakte Vergleichsrechnungen wurden
ausgeführt und in REWORK-NOTES protokolliert. Es gibt keine Approval-Datei.

Abschließende Integritätsprüfung: 255 Bestandsdateien verglichen, zehn
geplante Builder-Dateien geändert, 245 bytegleich, keine Bestandsdatei
gelöscht und kein vorhandener Test geändert. Neu: fünf Testdateien
einschließlich Helper und die beiden zugewiesenen Handoffs. NAMESPACE ist
bytegleich; alle 26 REVIEW-IDs sind beantwortet (`integrity-final.log`).

**Offene Betreiber-/Reviewer-Schritte:** Nur der Orchestrator schreibt die
Gate-Fakten. `gates.json` ist weiterhin der unveränderte rote Stand aus
Runde 1. Der lokale `mirai::daemons(1L)`-Probeaufruf endet mit
`16 | Permission denied` (`mirai-probe.log`); deshalb ersetzt die zusätzliche
Prozessdiagnose keinen regulären mutgate-Lauf. Die Infrastrukturpunkte
E40/E41 sowie lokale Dispatcher-/Zeitprüfungsprobleme sind in den
REWORK-NOTES ausdrücklich OUT-OF-TERRITORY. E39/E42 bleiben beim
Betreiber, E43 gemäß ADR-022 in M1b. Keine selbst genehmigte Äquivalenz.

## M2 — Abschlussnachtrag im M1a-BUILD (29.10.2026)

`orchestrator/state/M2/gates.json` nennt Runde 3, `result: pass` und
acht Gates mit `pass`; `orchestrator/handoff/M2/verdict-code.json`
bestätigt `PASS` ohne blocking-Einwand. Das sind gelesene Fakten des
Orchestrators/Reviewers, kein neuer Builder-Gate-Lauf.

## M1a — BUILD, Runde 1 (29.10.2026)

Grundlage: freigegebener PLAN samt PLAN-UPDATE und PLAN-REVIEW Runde 2,
CRITERIA K-M1a-1 bis K-M1a-7, unveränderte Abnahmetests einschließlich
Setup-Dateien, Rollen-/Implementierungsregeln, PROTOCOLS, Fachspezifikation
§2–§8, Statistikkern M1a und die numerischen S-boot-Szenarien,
Formelsammlung §1–§3 sowie ADR-016 bis ADR-019. ARBITER liegt nicht vor;
LESSONS enthält keine Lehren. ADR-019 bestätigt ADR-018 und regelt die
Mutationsinfrastruktur ausschließlich beim Betreiber.

### Numerischer Vorversuch vor der Ressourcenarbeit

Der Ausgangskern wurde ohne Git nach `/tmp/llmsa-m1a-build/baseline/`
kopiert. Die Inventur erfasst 198 Produkt-, Test-, Anker-, Vertrags-,
Dokumentations- und Handoff-Dateien. Schlüssel und Git-Metadaten wurden
nicht gelesen. Gesicherte SHA-256:

```text
R/fit.R 761faa4c4519cea2770f4c746fe002f72b91979bb625cb3a598f2af7655c93e1
R/grr.R 6c0d8b57e54f4a72a5667ad89f3b0119acd9ca020bb669a060e3ec2ed9224fed
```

Der unveränderte Ausgangslauf wurde mit `testthat::test_dir()` aus den
Quellen ausgeführt (`filter = "^m1a-"`, `set_max_fails(Inf)`,
`stop_on_failure = FALSE`, PDF-Gerät `pdf(NULL)`). Echter Output,
Exit 1, `/tmp/llmsa-m1a-build/baseline-acceptance.log`:

```text
[ FAIL 88 | WARN 5 | SKIP 0 | PASS 486 ]
M1a baseline: 54 tests; 21 failed blocks; 6 error blocks; 0 skipped; elapsed 22.56 s
```

Nach dem ersten Numerikentwurf lief derselbe Prüfweg mit
`filter = "^m1a-[12346]-"`. Echter Output, Exit 1:

```text
Duration: 18.5 s
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 465 ]
Numeric first: 40 tests; 0 failed blocks; 1 error blocks; 0 skipped
Error: acceptance: vignette missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/vignettes/validation.Rmd
```

Alle numerischen Abnahmefälle dieses Laufs bestehen. Der eine Fehler
ist die zu diesem Zeitpunkt bewusst noch nicht erzeugte Vignette in
`test-m1a-4-nist.R:94`; der Test wurde weder geändert noch übersprungen.

Anschließend ausgeführt (je Exit 0):

```bash
Rscript --vanilla /tmp/llmsa-m1a-build/go-no-go.R
Rscript --vanilla /tmp/llmsa-m1a-build/robustness.R
Rscript --vanilla /tmp/llmsa-m1a-build/derivatives.R
Rscript --vanilla /tmp/llmsa-m1a-build/timing.R
```

Tatsächlicher Output:

```text
Invariance: 250 transformed fits; max component/TV 1.91366e-09; max relative metric 2.63966e-09; distant discrete cases 250; failures 0
Methods: analytic_reml 30; closed_form 220
Model consistency: VarCorr, sigma, response, fitted, residuals and predictions passed for all original and transformed fits
Robustness: 200/200 fits completed; no errors
Dense reference: criterion error 1.06581e-14; score error 5.32907e-15; Hessian relative error 1.18928e-10
Serialization, refit control and same-seed bootMer: passed
ic50_demo: before median 0.389 [0.389, 0.389] s; after median 0.461 [0.460, 0.478] s; ratio 1.185
SmLs03: before median 0.043 [0.043, 0.050] s; after median 0.045 [0.045, 0.045] s; ratio 1.047
msa_plan: before median 0.216 [0.215, 0.230] s; after median 0.544 [0.543, 0.660] s; ratio 2.519
msa_boot: before median 0.103 [0.102, 0.108] s; after median 0.115 [0.113, 0.118] s; ratio 1.117
```

Aufbau, Seeds, Transformationen, Tabellen je Robustheitsszenario und
Laufzeitgrößen stehen vollständig in ADR-020. Die CSVs unter demselben
temporären Verzeichnis enthalten alle Einzelmessungen. Vier balancierte
Designs × Seeds 1–6 und ic50_demo tragen je zehn Transformationen.
Die S-boot-Szenarien 1–6 und die vier `msa_plan`-Beispielpläne tragen
je Seeds 1–20. Keine ADEMP-/Coverage-Behauptung. Der Bootstrap-Vergleich
verwendet acht Wiederholungen und Seed 37.

Zwei frühe Fehler betrafen ausschließlich das temporäre Diagnoseskript:
`refit()` ergänzt in lme4 das normale `print_level = 0` (daher Vergleich
mit direktem lme4 statt Annahme einer leeren Ergebnisliste); eine lokal
`eval` genannte Prüffunktion verdeckte `base::eval`. Beide Ursachen
wurden im Skript korrigiert. Die Modellsteuerung selbst ist leer und
der gespeicherte `lmerControl`-Ausdruck bleibt auswertbar. Der endgültige
Nachweis oben lief danach vollständig.

Der Vorversuch trägt die nächste Planstufe. ADR-020 begründet Numerik
und Matrix-Import; ADR-021 begründet die neuen Validierungsressourcen
einschließlich Golden-Pfad. Die endgültigen Prüfungen und die
Territoriumsübergabe werden unten ergänzt; Gates sind noch nicht
abgenommen.

### Umsetzung und Antworten auf die Planhinweise

`R/fit.R` enthält den gesamten neuen numerischen Pfad im bestehenden
Mutations-Scope: unveränderte Doubles, stabile Konditionierung, EMS-Lösung,
analytischer restringierter REML-Abschluss und endgültiger lme4-Modellbau
auf Originaldaten. `vc` wird ausschließlich aus `VarCorr(model)` gewonnen.
`numerics` ergänzt Methode, aktive Grenzen, Normen, Startdiagnostik und
Zuordnung der beim Parsen behaltenen Eingabezeilen. Fehler werden benannt;
ein gescheiterter Abschluss gibt keinen ungenauen Startfit zurück.

`R/grr.R` setzt die ndc-Untergrenze und den spezielleren Nullfall aus
ADR-017 um. Bei Gesamtvarianz null bleiben Varianzen/SD null, während
Prozentwerte, ICC und ndc `NA_real_` sind; das Verdikt ist `undetermined`.
Die Druckmethoden unterscheiden `NA` und `Inf`. Alle bisherigen
öffentlichen Argumentpositionen und Vorgaben bleiben erhalten.

| Planhinweis | Antwort und Beleg |
| --- | --- |
| E1, E3, E5–E7 | ADR-020; numerischer Vorversuch oben; unabhängige dichte Score-/Hessian-Rechnung, VarCorr-/sigma-/Antwort-/Vorhersageprüfungen, Serialisierung und Invarianz. Kleine positive Streuung und degenerierte Fälle werden getrennt behandelt. |
| E2 | Wurzel-README unverändert. Anleitung unter `inst/validation/numeric/README.md`. |
| E4 | Jeder Eintrag in `...` wählt den direkten lme4-Pfad. Unit-Vergleiche für Steuerung einschließlich `NULL`, Gewichte, Offset, Subset und Startwerte; unveränderter Nichtkonvergenz-Abnahmetest. |
| E8, E13 | Gewöhnliche nloptwrap-Refits; derselbe Seed gegen direktes `bootMer`; getrennte Zeitmessungen und 200 erfolgreiche S-boot-/Planungsfits vor Ressourcenarbeit. Degenerierte Planung und AP1-Fehlerpräfix zusätzlich geprüft. |
| E9 | Kleine Unit- und metamorphe Prüfungen; kein vollständiges Knitten und kein großes VCA-Orakel im Unit-Pfad. Der vollständige Testlauf steht unten. |
| E10 | ADR-021; ganze Ankerkopien, Quellenmanifest, zwei strikte Kontexte, Original-/Kopien-Driftwache, rekursive Prüfung der `source`-/`sys.source`-Abhängigkeiten einschließlich Inline-R, Daten-/Hash-/Schema-Negativfälle. |
| E11 | Nullfälle einschließlich Druckmethoden und `grr_stats()`-Verwendung durch den Bootstrap geprüft. Keine Abnahme vorweggenommen für die spätere Coverage-Studie. |
| E12 [INFRA], E16 | Numerik bleibt in `R/fit.R`/`R/grr.R`. Testauswahl, Mutation-Scope und Schwellen bleiben unverändert. Der Builder schreibt keine Mutationsfakten und führt keine Git-verwendenden Gates aus; Beurteilung/Score liegen beim Betreiber und Reviewer (ADR-019). |
| E14 | Positive Skala aus tatsächlichen Differenzen, keine MAD-Nullfalle. Zwei Gleichstandsmuster sowie sehr kleine/große Skalen geprüft; K-M2-6 erhält einen eigenen Regressionslauf. |
| E15 | Direkter Import `Matrix (>= 1.6-0)`, im numerischen ADR begründet; R >= 4.1 bleibt. Lokale Matrix-NEWS belegen die Einführung von `determinant(..., sqrt=)` in 1.6-0. Der zunächst angesetzte Mindeststand 1.3-0 wurde vor dem abschließenden Paketcheck korrigiert. Keine Paketinstallation oder Aktualisierung. |
| E17 | Startwarnungen mit Herkunft in `numerics$start`, bei Fehlschlag erneut als Warnung; finale Konvergenzprüfung aktiv. Roxygen-Dokumentation und gezielter Unit-Test belegen beide Fälle. |

Technische Festlegungen sind in ADR-020 und ADR-021 dokumentiert.
Es wurde keine neue Vertragslücke festgestellt. Spezifikationen,
Abnahmetests, ursprüngliche Anker und bestehende Testtoleranzen bleiben
unverändert. Die Hilfsrechnung der Vignette lädt den aktuellen Namespace
und nie eine unmutierte Paketkopie.

### Ressourcen, Herkunft und Dokumentation

Ausgeführt (Exit 0):

```bash
Rscript --vanilla data-raw/make_validation_numeric.R
Rscript --vanilla data-raw/make_validation_numeric.R --out /tmp/llmsa-m1a-build/reproduction-a
Rscript --vanilla data-raw/make_validation_numeric.R --out /tmp/llmsa-m1a-build/reproduction-b
Rscript --vanilla /tmp/llmsa-m1a-build/resource-negative-current.R
```

Der Erzeuger meldete jeweils:

```text
Numeric validation inputs: 11 NIST tables; 5 byte-identical anchors; 224678 stored data bytes
```

Eine anschließende unabhängige Python-Prüfung verglich alle Bytes mit
beiden Ausgaben und dem Checkout sowie die Zahlentokens/Zeilen mit den
gehashten Originalen. Echter Output (`reproduction-current.log`, Exit 0):

```text
Reproduction: 19 generated files byte-identical in both independent outputs and the repository
NIST tokens and row order: 11/11 original datasets reproduced exactly; 3 deterministic gzip headers
```

Die sechs Negativfälle verändern ausschließlich temporäre Kopien. Auch
der Fall einer bereits gestagten, aber zu großen Ausgabe veröffentlicht
nichts. Output aus `resource-negative-current.log`:

```text
Generator negative missing-anchor: rejected before publication; existing output unchanged
Generator negative missing-source: rejected before publication; existing output unchanged
Generator negative source-hash: rejected before publication; existing output unchanged
Generator negative malformed-source: rejected before publication; existing output unchanged
Generator negative missing-size-key: rejected before publication; existing output unchanged
Generator negative size-limit: rejected before publication; existing output unchanged
Generator negative cases: 6/6 passed; original inputs never edited
API snapshot ANK-02: 22 exports and 108 ordered arguments retained
```

`vignettes/validation.Rmd` rechnet K-M1a-1 bis K-M1a-5 mit
`inst/validation/numeric/reference_checks.R`. Die AIAG-Darstellung nimmt
nur aggregierte GRR-Tabellen an. Die gepoolte Interaktion wird ausdrücklich
als nicht separat geschätzt berichtet, nicht mit einem erfundenen Fitwert.
Im öffentlichen Kontext sind sämtliche AIAG-Beobachtungsfelder
`not rerun: protected data required`. Keine geschützten Rohdaten werden
in irgendeinem Kontext ausgegeben.

Die Roxygen-Erzeugung lief ausschließlich in
`/tmp/llmsa-m1a-build/roxygen-current-h_c1v8g9/` mit
`roxygen2::roxygenise(..., roclets = c("rd", "namespace"))` (Exit 0).
Nur `msa_fit.Rd`, `msa_grr.Rd` und `msa_boot.Rd` wurden übernommen.
`NAMESPACE` blieb byte-identisch. Die zusätzliche automatisch erzeugte
Autorenformatierung in `llmsa-package.Rd` wurde nicht übernommen.
`NEWS.md` beschreibt Numerik, Nullfälle und Validierung.

### Ausgeführte Regressionen

Eingefrorene Umgebung, rein prüfender Aufruf:

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
```

Output des endgültigen Laufs (`deps-complete-current.log`, Exit 0):

```text
r-deps: R              4.6.1        (verlangt: >= 4.1)
r-deps: lme4           2.0.6        (verlangt: beliebig)
r-deps: Matrix         1.7.4        (verlangt: >= 1.6-0)
r-deps: ordinal        2026.7.26    (verlangt: beliebig)
r-deps: SixSigma       0.11.1       (verlangt: beliebig)
r-deps: VCA            1.5.2        (verlangt: beliebig)
r-deps: pass — 22 Anforderungen erfüllt (R 4.6.1)
```

Der vollständige M1a-Abnahmelauf wurde aus den Quellen mit
`Sys.setenv(REPO_ROOT = normalizePath("."))`, `pdf(NULL)`,
`pkgload::load_all(".", quiet = TRUE)`, `testthat::set_max_fails(Inf)`
und `testthat::test_dir("tests/acceptance", filter = "^m1a-",
reporter = "progress", stop_on_failure = FALSE,
stop_on_warning = FALSE)` ausgeführt. Der Prozess beendete sich anhand
der tatsächlich fehlgeschlagenen/fehlerhaften Testblöcke; Abnahmeinhalte
wurden nicht verändert. Echter Output des endgültigen Laufs
(`acceptance-complete-current.log`, Exit 0):

```text
Duration: 38.7 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a final: 54 tests; 0 failed blocks; 0 error blocks; 0 skipped; elapsed 38.88 s
```

Vorherige Diagnoseausgänge bleiben sichtbar: Der erste Vignettenlauf
ohne gesetztes `REPO_ROOT` endete mit sechs Setup-Fehlern (573 erfolgreiche
Prüfungen), weil der Abnahmehelfer nach dem Wechsel ins temporäre
Verzeichnis die Repo-Wurzel nicht mehr fand. Der Aufruf wurde dem
Harness-Kontext angepasst; die Abnahmedatei blieb unverändert. Ein erster
neuer Darstellungstest meldete vier fehlende INT-Zeilen. Daraufhin wurde
die Darstellung um die explizit gepoolte Interaktion ergänzt; keine
Erwartung wurde entfernt. Danach bestand die Teilmenge
`fit-numeric|grr-numeric|validation-numeric|acmg-evaluate` mit
`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 382 ]` (29 Blöcke, 8,3 s).
Eine zusätzliche Inline-Quellverfolgungsprüfung ist im folgenden
Gesamtlauf enthalten.

Gesamtregression mit dem unveränderten Betreiber-Testtreiber und offenem
Null-PDF-Gerät (Dateiausgaben außerhalb des Checkouts):

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath(".")); grDevices::pdf(NULL); started <- proc.time()[["elapsed"]]; source("orchestrator/lib/r-tests.R"); cat(sprintf("Unit and QA elapsed: %.2f s\n", proc.time()[["elapsed"]] - started))' tests/testthat tests/e2e tests/fuzz
```

Echter Output (`unit-qa-current.log`, Exit 0):

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1998 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 145 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed: 70.60 s
```

Der eine bestehende Skip betrifft `test-backends.R:32`:
`requireNamespace("ellmer", quietly = TRUE) is TRUE` (Negativfall für
eine fehlende optionale Abhängigkeit). Die neuen Drift-/Numerikprüfungen
wurden im Repository nicht übersprungen. Bestehende QA-Dateien blieben
unverändert. Die System-Bus-Diagnose aus `acmg-policies` ist stderr des
vorhandenen Prüfwegs; testthat meldet null Warnungen und keinen Fehler.

Die schwierigen NIST-Fälle bleiben ausdrücklich Berichte, wie ADR-017
und K-M1a-4 verlangen. Gemessene LRE aus dem unveränderten Abnahmetest:

```text
K-M1a-4 report SmLs07: LRE msa_fit residual 3.81, item 3.71; LRE aov residual 4.16, item 4.02
K-M1a-4 report SmLs08: LRE msa_fit residual -0.60, item -0.60; LRE aov residual 2.67, item 3.92
K-M1a-4 report SmLs09: LRE msa_fit residual -4.19, item -4.19; LRE aov residual -0.28, item 3.94
```

Die Originalskala des lme4-Modells begrenzt hier die Genauigkeit trotz
präziser Varianzverhältnisse. Es gibt keine nachträgliche Korrektur nur
der `vc`-Tabelle und keine Datenreparatur. Alle vorgeschriebenen niedrigen
und mittleren Schwierigkeitsfälle bestehen.

K-M2-6 wurde mit demselben direkten Abnahmeaufruf und
`filter = "^m2-6-"` ausgeführt (`acceptance-m2-current.log`, Exit 0):

```text
Duration: 234.7 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 374 ]
M2 evaluation regression: 10 tests; 0 failed blocks; 0 error blocks; 0 skipped; elapsed 234.76 s
```

### Paketbau und Check in beiden Kontexten

Zwei Positivlisten-Kopien enthalten nur `DESCRIPTION`, `NAMESPACE`,
Lizenzen, `NEWS.md`, `README.md`, `.Rbuildignore`, `R/`, `man/`, `data/`,
`inst/`, `vignettes/`, `tests/testthat.R` und `tests/testthat/`.
Originalanker, geschützte Daten, API-Aufzeichnungen, Harness,
Git-Metadaten und Geheimnisse wurden nicht kopiert.

Öffentliches Arbeitsverzeichnis:
`/tmp/llmsa-m1a-build/public-check-current-1_8k9lha/`.
Vollmodus-Arbeitsverzeichnis:
`/tmp/llmsa-m1a-build/full-check-current-lsm9_tb3/`.
Jeweils ausgeführt, alle vier Prozesse Exit 0:

```bash
env -u REPO_ROOT R CMD build --no-manual src
env -u REPO_ROOT _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz

REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa R CMD build --no-manual src
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die finalen Builds mit dem korrigierten Matrix-Minimum stehen jeweils in
`build-complete.log`, die Checks in `check.log` und `llmsa.Rcheck/`.
Echter gemeinsamer Build-Output:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
```

Check-Auszüge, zuerst öffentlich:

```text
* checking examples with --run-donttest ... [31s/31s] OK
* checking tests ...
  Running ‘testthat.R’ [49s/49s]
 [49s/49s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [27s/27s] OK
* DONE
Status: 1 NOTE
```

Vollmodus:

```text
* checking examples with --run-donttest ... [31s/31s] OK
* checking tests ...
  Running ‘testthat.R’ [48s/48s]
 [48s/48s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [28s/29s] OK
* DONE
Status: 1 NOTE
```

Beide Checks haben **keinen ERROR und keine WARNING**. Die einzige NOTE
lautet `Unable to verify current time` bei `checking for future file
timestamps`. Die Uhrzeitprüfung wurde nicht deaktiviert. Nur die bereits
im Betreiberprüfweg vorgesehene CRAN-Incoming-Netzeinstellung ist gesetzt.

Die installierten Tests melden öffentlich
`[ FAIL 0 | WARN 0 | SKIP 8 | PASS 1923 ]`, im Vollmodus
`[ FAIL 0 | WARN 0 | SKIP 7 | PASS 1924 ]`.
Fünf bestehende Skips betreffen nicht ausgelieferte API-Aufzeichnungen,
einer den bisherigen CRAN-Report-Test, einer die installierte optionale
ellmer-Abhängigkeit. Nur öffentlich kommt der nach ADR-017 erlaubte
Originalanker-Vergleich hinzu. Kopien, Schema, Hashes, numerische
Unit-Tests und Literalherkunft laufen in beiden Paketen; im Vollmodus
läuft auch die Original-Driftwache.

Die tatsächlich erzeugten HTML-Dateien wurden ohne erneute Rechnung aus
den Tarballs gelesen und ihre Tabellen geprüft. Output
(`rendered-vignettes-current.log`, Exit 0):

```text
public: 9 computed reference tables; results {'PASS': 94, 'NOT RERUN': 23, 'REPORT': 8, 'REPORT (higher difficulty)': 6}; 23 AIAG rows; no raw-data columns or protected input files
full: 13 computed reference tables; results {'PASS': 123, 'REPORT (pooled interaction)': 4, 'REPORT': 12, 'REPORT (higher difficulty)': 6}; 23 AIAG rows; no raw-data columns or protected input files
```

Alle erwarteten, beobachteten und Toleranzwerte wurden beim Knitten
berechnet beziehungsweise aus den autorisierten Eingaben gelesen.
Die HTML-Prüfung fand weder FAIL- noch WARNING-Ergebniszeilen. Die
Tarballs enthalten kein geschütztes Eingabeblatt; die HTML-Tabellen
enthalten keine Rohdaten-Spalten.

### Übergabe und verbleibende Grenzen

Die Builder-Umsetzung und die oben genannten Prüfungen sind abgeschlossen.
Abnahme, kumulative Gates, Mutation-Score einschließlich E16,
Territoriumsprüfung und Phasen-Commit bleiben beim Orchestrator/Reviewer.
E12 bleibt ein nonblocking Infrastrukturhinweis in dessen Zuständigkeit;
der Builder hat weder BACKLOG noch Gate-/Zustandsdateien geändert.
Ein Windows-, macOS- oder R-4.1-Lauf wird nicht behauptet. Gemessen wurde
die eingefrorene Linux-Umgebung mit R 4.6.1 und Matrix 1.7.4.

Keine Git-Kommandos, keine Änderung der Abnahme- oder Gate-Regeln,
keine Installation/Aktualisierung von Abhängigkeiten. Temporäre
Paketinstallationen durch R CMD build/check liegen unter `/tmp/`.
Sämtliche Bauartefakte und Diagnoseprotokolle liegen außerhalb des
Arbeitsbaums. Abschließend ausgeführte Python-/SHA-256-Inventur
(`integrity-current.log`, Exit 0):

```text
Integrity: 198 inventoried files; 9 authorized existing-file changes; 29 authorized new files; 0 removed files
Protected inventoried files: 95/95 byte-identical
Existing AP1 evaluation tests: retained byte-for-byte with one added test block
public checked package source: 103 files byte-identical to the final corresponding repository files
full checked package source: 103 files byte-identical to the final corresponding repository files
Workspace artifacts: none; vignettes contains only the two Rmd sources
```

Die vollständige Pfadliste liegt in
`/tmp/llmsa-m1a-build/integrity-current.json`. Die neun Änderungen
bestehender Dateien betreffen `R/fit.R`, `R/grr.R`, die drei genannten
Rd-Dateien, den zusätzlichen AP1-Unit-Test, `DESCRIPTION`, `NEWS.md` und
dieses Fortschrittsdokument. Die neuen Dateien liegen ausschließlich in
den im Plan genannten Builder-Pfaden. Diese Inventur ersetzt nicht die
Territoriumsprüfung des Orchestrators.

## M0 — BUILD, Runde 1 (25.10.2026)

Der freigegebene Plan ist im Builder-Territorium umgesetzt: Diese Phase
aktualisiert ausschließlich `PROGRESS.md` und dokumentiert die unten
ausgeführten, rein lesenden Diagnosen. **Die Gate-Abnahme steht aus.**
Beim Diagnosezeitpunkt existiert
`orchestrator/state/M0/gates.json` noch nicht.

### Umfang und verbindlicher Kontext

Grundlage sind `orchestrator/handoff/M0/PLAN.md`,
`PLAN-REVIEW.md` und `verdict-plan.json` (Runde 1, `PASS`, keine
blocking-Einwände). PLAN-UPDATE und ARBITER liegen für M0 nicht vor.
Gelesen wurden außerdem `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`,
`CRITERIA.json`, sämtliche M0-Abnahmetests einschließlich Setup-Dateien,
`docs/01-fachspezifikation.md` mit K-M0-1 bis K-M0-7,
die Reviewer-ADRs ADR-001 bis ADR-003, der bisher leere `PROGRESS.md`,
`BACKLOG.md` und `orchestrator/LESSONS.md` (noch keine Lehren).

Die Begrenzung folgt der Fachspezifikation §10: „M0 ändert `R/` nicht.
Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“
Daher bleiben Produktcode, Schnittstellen, Abhängigkeiten und sämtliche
Tests unverändert; zusätzliche Unit-/Property-Tests sind in diesem
freigegebenen M0-Plan ausdrücklich nicht vorgesehen. Es gibt keine
Planabweichung und keinen neuen Builder-ADR.

Für die Diagnosen wurde die vorhandene Umgebung nach `toolchain.json`
und dem unveränderten Manifest `DESCRIPTION` verwendet. Es erfolgten keine
Installation, kein Update und kein Netzzugriff. Abnahmetests, Verifier und
Gates wurden nicht gestartet; auch indirekte Git-Aufrufe durch diese
Prüfwege wurden vermieden. Keine Git-Kommandos, keine Builds oder
Testläufe im Checkout, keine Bauartefakte und keine Schreibzugriffe auf
fremde Territorien.

### Behandlung der Reviewer-Hinweise

| ID | Antwort und Stand |
| --- | --- |
| E1 | Akzeptiert: `PROGRESS.md` wird in BUILD fortgeschrieben, einschließlich aktueller ANK-01-Diagnose mit echtem Output. Die noch fehlenden Gate-Fakten werden ausdrücklich als offen geführt. |
| E2 | Akzeptiert: ausschließlich lesende Diagnosen; kein Build, Check oder Testlauf im Checkout. Damit entstehen dort keine Tarballs, `*.Rcheck`, `_snaps` oder `Rplots.pdf` durch diese Phase. |
| E3 / PLAN-M0-INFRA-01 | Übernommen als nonblocking `[INFRA]`; ref: Fachspezifikation §9, BL-48. `gates-auswahl.md` fehlt weiterhin an der Repo-Wurzel. Die Zuordnung ist in PLAN-REVIEW bestätigt. Betreiber: Datei bereitstellen oder Verweis berichtigen; Reviewer: BL-48 in CODE-REVIEW nachtragen. Kein Builder-Eingriff in BACKLOG oder Gate-Auswahl. |
| E4 | Berücksichtigt; ref: Fachspezifikation §4, K-M0-7. M0 ergänzt keine Argumente. Ab M2 prüft der Reviewer zusätzlich, ob angehängte Argumente ohne ADR einen Vorgabewert haben. |

ACC-1 bis ACC-3 sind durch die angenommenen Reviewer-ADRs entschieden:
ADR-001 legt den Prüfgegenstand von K-M0-4 nach M0 fest,
ADR-002 die wirksame Ignore-Prüfung samt Exit-Codes,
ADR-003 die Zählung der testthat-Blöcke einschließlich bestehender Skips.
Die noch als „ADR ausstehend“ formulierten Einträge in CRITERIA.json
werden hier nicht geändert; maßgeblich sind die Planfreigabe und die
vorliegenden ADRs. Es wurde keine neue Vertragslücke festgestellt.

### Ausgeführte Diagnosen

Alle folgenden Befehle liefen in dieser BUILD-Phase aus der Repo-Wurzel.
Die Ausgaben sind die tatsächlichen Outputs dieses Laufs, keine
Übernahme historischer PLAN- oder Reviewer-Ergebnisse.

**1. Dateiintegrität, statische Exportliste und Layout (Exit 0).**

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import json
import os
import re

root = Path.cwd()
expected = json.loads((root / 'reference/anchors/ANK-01.json').read_text())['value']
actual = {p.relative_to(root).as_posix(): p for p in (root / 'R').rglob('*') if p.is_file()}
assert set(actual) == set(expected), 'R/ file set differs from ANK-01'
for name, path in sorted(actual.items()):
    data = path.read_bytes()
    assert len(data) == expected[name]['bytes'], name
    assert hashlib.sha256(data).hexdigest() == expected[name]['sha256'], name
print(f'ANK-01: {len(actual)}/{len(expected)} files match path, bytes and SHA-256')
snapshot = json.loads((root / 'reference/anchors/ANK-02.json').read_text())['value']
exports = re.findall(r'^export\(([^)]+)\)$', (root / 'NAMESPACE').read_text(), re.M)
assert set(exports) == set(snapshot['exports']), 'NAMESPACE exports differ from ANK-02'
print(f'ANK-02: {len(exports)} NAMESPACE exports match; formals not evaluated')
required = ['^pkgdown-site$', '^docs$', '^reference$', '^orchestrator$', '^tests/acceptance$', '^tests/simulation$', '^tests/fixtures$']
assert set(required) <= set((root / '.Rbuildignore').read_text().splitlines())
assert re.search(r'^destination: pkgdown-site\s*$', (root / '_pkgdown.yml').read_text(), re.M)
print('Layout: 7/7 required .Rbuildignore lines and pkgdown destination present; Git ignore semantics not executed')
gates = sorted(p.name for p in (root / 'orchestrator/gates.d').glob('[0-9][0-9]-*.sh') if os.access(p, os.X_OK))
print('Executable gate files: ' + ', '.join(gates))
print('M0 gates.json exists: ' + str((root / 'orchestrator/state/M0/gates.json').exists()))
print('gates-auswahl.md exists at repository root: ' + str((root / 'gates-auswahl.md').exists()))
PY
```

Output:

```text
ANK-01: 13/13 files match path, bytes and SHA-256
ANK-02: 22 NAMESPACE exports match; formals not evaluated
Layout: 7/7 required .Rbuildignore lines and pkgdown destination present; Git ignore semantics not executed
Executable gate files: 10-deps.sh, 20-lint.sh, 30-tests.sh, 70-trace.sh, 82-territory.sh, 86-mutgate.sh, 87-golden-adr.sh, 88-mutfull.sh
M0 gates.json exists: False
gates-auswahl.md exists at repository root: False
```

Damit sind die Pfadmenge, Bytezahlen und SHA-256-Werte aller R-Dateien
aktuell gegen ANK-01 geprüft. Der NAMESPACE-Vergleich ist eine
Bestandsdiagnose der Exportliste; er prüft weder `formals()` noch die
Negativfälle des API-Abnahmetests. Die Layoutdiagnose prüft die
geforderten Dateiinhalte, nicht die wirksamen Git-Ignore-Regeln.
Ausführbare Gate-Dateien belegen keinen Gate-Erfolg.

**2. Vorhandene Abhängigkeiten, ohne Installation (Exit 0).**

```bash
Rscript orchestrator/lib/r-deps.R --check-only
```

Output:

```text
r-deps: R              4.6.1        (verlangt: >= 4.1)
r-deps: graphics       4.6.1        (verlangt: beliebig)
r-deps: lme4           2.0.6        (verlangt: beliebig)
r-deps: ordinal        2026.7.26    (verlangt: beliebig)
r-deps: stats          4.6.1        (verlangt: beliebig)
r-deps: tools          4.6.1        (verlangt: beliebig)
r-deps: utils          4.6.1        (verlangt: beliebig)
r-deps: DBI            1.3.0        (verlangt: beliebig)
r-deps: ellmer         0.5.0        (verlangt: beliebig)
r-deps: httr2          1.3.0        (verlangt: beliebig)
r-deps: jsonlite       2.0.0        (verlangt: beliebig)
r-deps: knitr          1.52         (verlangt: beliebig)
r-deps: rmarkdown      2.32         (verlangt: beliebig)
r-deps: RSQLite        3.53.3       (verlangt: beliebig)
r-deps: testthat       3.3.2        (verlangt: >= 3.0.0)
r-deps: pass — 15 Anforderungen erfüllt (R 4.6.1)
```

Alle Anforderungen aus DESCRIPTION sind in der Builder-Umgebung
erfüllt. Dies ist der ausdrücklich lesende `--check-only`-Lauf,
kein deps-Gate-Beleg; das Gate muss seine eigene Umgebung und
Versionen in `gate-deps.log` dokumentieren.

**3. R-Laufzeit (Exit 0).**

```bash
Rscript --version
```

Output:

```text
Rscript (R) version 4.6.1 (2026-06-24)
```

### Offene Abnahme und Übergabe

| Kriterium | Aktueller Builder-Beleg | Noch erforderlicher Nachweis |
| --- | --- | --- |
| K-M0-1 | Lesende Abhängigkeitsdiagnose: 15 Anforderungen erfüllt; Versionen oben. | deps-Gate `pass` und Versionen in `gate-deps.log`. |
| K-M0-2 | ANK-03 und ADR-003 gelesen; kein aktueller Testlauf durch den Builder. | tests-Gate ohne Fehlschlag/Fehler; mindestens `ANK-03.value` testthat-Blöcke (derzeit 27); Testzahl und Skips aus dem echten Lauf berichten. |
| K-M0-3 | Kein Build-/Check-Lauf in dieser BUILD-Phase. | lint-Gate: Paketbau und `R CMD check --as-cran --no-manual` außerhalb des Repos ohne ERROR/WARNING. |
| K-M0-4 | 13/13 R-Dateien stimmen in Pfad, Bytezahl und SHA-256 mit ANK-01 überein. | Unveränderter Abnahmetest im tests-Gate. |
| K-M0-5 | Sieben geforderte `.Rbuildignore`-Zeilen und pkgdown-Ziel vorhanden. | Vollständiger Layout-Abnahmetest einschließlich tatsächlicher Git-Ignore-Semantik nach ADR-002. |
| K-M0-6 | Acht ausführbare Gate-Dateien vorhanden; `gates.json` fehlt noch. | Aktuelles Aggregat mit `pass` für deps, lint, tests, trace, territory, mutgate, golden-adr; mutgate-Kurzbefund `mutgate: pass (kein geänderter Mutations-Scope)`. `88-mutfull` ist in M0 nicht fällig. |
| K-M0-7 | Die 22 NAMESPACE-Exporte gleichen der Liste aus ANK-02; keine Snapshot-Änderung. | Geladenes Paket als API-Obermenge einschließlich Positionen/Vorgabewerten, positive und negative Prüffälle sowie golden-adr-Prüfung im Harness. |

Der Orchestrator prüft das Territorium, erzeugt den Phasen-Commit und
führt danach die konfigurierten Gates aus. Der Reviewer beurteilt den
Diff seit `plan/M0` und die aktuellen Gate-Fakten. Für Runde 1 verlangt
PLAN-REVIEW ein `gates.json` mit passendem `round`, `base`, `env.sha`
und `result: pass`; solche Fakten liegen dieser BUILD-Phase noch nicht
vor. Es wird kein Kriterium allein aufgrund der Vorprüfung als
abgenommen und kein Gate als bestanden erklärt.

Die Backlog-Zuordnung aus dem freigegebenen PLAN bleibt bestehen.
E3/BL-48 bleibt bei Betreiber und Reviewer; ein neuer blocking-Befund
wurde nicht festgestellt. Nach M0 wertet der Betreiber Modellumleitung,
Kosten und Gate-Laufzeiten aus (BL-06, BL-11, BL-13, BL-37). Der nächste
Meilenstein ist M2; AP1-Zahlen vor der erneuten Auswertung nach
M1-Abnahme bleiben vorläufig (BL-52).

## M0 — Abschlussnachtrag im M2-BUILD (27.10.2026, BL-54)

Der oben dokumentierte M0-BUILD-Stand ist historisch. Die anschließend
erzeugten Fakten liegen inzwischen vor und wurden in dieser Phase
gelesen: `orchestrator/state/M0/gates.json` nennt Runde 1,
`baseRef: plan/M0`, Basis `6783f2874340f62c4de53d30b5415708e1a45073`,
Umgebungs-SHA `9866ba2f5fcef6538338a1612f4e849cb77355e9` und
`result: pass`. deps, lint, tests, trace, territory, mutgate und
golden-adr stehen auf `pass`; mutfull ist „nicht fällig in M0“.
`orchestrator/handoff/M0/REVIEW.md` und `verdict-code.json` bestätigen
`PASS` ohne blocking-Einwand. Dies ist der verlangte Abschlussvermerk,
kein neuer M0-Gate-Lauf. Der Git-verwendende `done/M0`-Zweig bleibt dem
Test-Gate des Orchestrators vorbehalten (BL-53).

## M2 — BUILD, Runde 1 (27.10.2026)

Der freigegebene PLAN einschließlich PLAN-UPDATE ist implementiert;
ADR-009 dokumentiert die zusätzlich erforderliche Korrektur der
numerischen JSON-Metadaten, deren Prüfung durch den Reviewer aussteht.
Maßgeblich sind die Planfreigabe Runde 2 (`PASS`, keine blocking-Einwände),
CRITERIA ACC-1 bis ACC-25, K-M2-1 bis K-M2-7 sowie ADR-004 mit beiden
Nachträgen und ADR-005 bis ADR-007. Eine ARBITER-Datei liegt nicht vor.
Rollenregeln, Protokolle, Spezifikationen, Abnahmetests und Handoffs
wurden gelesen; `orchestrator/LESSONS.md` enthält keine zusätzliche Lehre.
Die noch als ausstehend beschriebenen Auslegungen in CRITERIA werden
durch die angenommenen ADRs konkretisiert, ohne CRITERIA zu verändern.

### Umsetzung und Umfang

- `R/acmg.R` enthält die vier internen Einstiegspunkte sowie die
  AP1-Helfer für Konfiguration, Import, Design, API-/Mock-Betrieb,
  Pilot, Store-Herkunft, Auswertung und Berichte. `run.R` unter
  `inst/validation/ap1/` lädt den richtigen Quellbaum und delegiert
  an denselben in den Unit-Tests geprüften Treiber.
- `data-raw/make_items_ap1.R` erzeugt den eingefrorenen Satz aus den
  vorhandenen Quellen nach ADR-005. Alle Quellhashes, Schemata,
  Poolzahlen und Größenlimits werden vor dem Schreiben geprüft.
  Hauptsatz, Pilot, Herkunft und Hashliste liegen unter
  `inst/extdata/items_ap1_2026-10-24/`. ADR-008 begründet diese erste
  Golden-Erzeugung; Auswahl und Referenzregeln weichen nicht vom PLAN ab.
- `plan.yaml` enthält die Zahlen aus den geernteten Ankern, die
  unveränderten Vorlagen und F8-Bausteine, Pilotregeln, Schwellen,
  Metadaten, Policy-Belege und Grenzen der Interpretation. Die drei
  Prüf-Toleranzen für paketinterne Unit-Tests stammen ebenfalls aus
  ANK-TOL und sind mit Herkunft im ausgelieferten Plan hinterlegt.
- `parse_choice()` ergänzt `whole_word = FALSE`, `msa_run()` ergänzt
  `parse_by_prompt = NULL`, `msa_report()` ergänzt `assessment = NULL`,
  jeweils am Ende. Die bisherigen Vorgaben bleiben erhalten. Das
  HTTP-Backend lässt Temperatur bei NULL weg, berücksichtigt `row$system`
  und hält Anfrage- und Antwortmetadaten auseinander. Es speichert
  weder Schlüssel noch Header. Die zusätzlichen Request-Metadaten
  Seed, Temperatur und Reasoning-Effort dienen der Nachvollziehbarkeit.
  ADR-009 korrigiert die bisherige Rundung kleiner und gebrochener
  Metadatenwerte bei der JSON-Speicherung; auch verschachtelte `usage`
  bleibt im SQLite-Rundlauf numerisch identisch.
- Auswertung und Berichte erhalten NA-Modalwerte, Gleichstände,
  Referenzbasis, Vollständigkeit, Rückfallgründe und alle Fit-Warnungen.
  Der numerische Rückfall nutzt die Paketvorgaben mit Interaktionen.
  Der gemeinsame Fit erhält kein Verdikt. Ein fehlendes Kriterium oder
  unvollständiger Hauptplan verhindert ein Gesamtband. Die Kennzeichnung
  `synthetic`/`unverified` bleibt zusätzlich zu den Kriterienbändern.
- README, NEWS und fünf von roxygen2 erzeugte Rd-Dateien beschreiben
  die Schnittstellen und den Betreiberablauf. Neue Suggests sind
  ausschließlich `digest`, `pkgload` und `yaml`. Imports und die
  22 Exporte bleiben unverändert; es gibt keine Installation und
  keine Änderung der eingefrorenen Abhängigkeiten.

### Antworten auf die Planhinweise

| ID | Antwort und Umsetzung |
| --- | --- |
| E1 | Akzeptiert: Ein API-Konstruktor für CLI und Tests; exakter HTTPS-Host bestimmt den Schlüssel, Routing bleibt Array, kein `max_tokens` aus Kostenannahmen und kein Qwen-Reasoning-Override. Fehler vor Requests. |
| E2 | Akzeptiert: alle vier Pilotregeln einschließlich globaler strikter Kostensumme, vollständiger Schlüssel, technischer Parserquote und Wiederholungstagsdiagnostik. API-main und API-robustness sind bis zum bestandenen API-Pilot gesperrt. |
| E3 | Akzeptiert: expliziter Modus, persistente `ap1_metadata`, Prüfung vor Resume/Schreiben, keine Mischung; auch reine Fehlerstores und reine Auswertung sind geprüft. |
| E4 | Akzeptiert: Fehler und vereinbarte Konvergenzwarnungen lösen den Rückfall aus; Standardinteraktionen bleiben erhalten, Fehler des numerischen Fits enden benannt. |
| E5 | Akzeptiert: an Fits gehen die übergebenen Zeilen in unveränderter Reihenfolge und mit ihren Typen. Direkter Vergleich und separate Permutation sind geprüft. |
| E6 | Akzeptiert: Referenzen und Prior-Felder stammen ausschließlich aus `runs`; der CLI-Join erhält die Reihenfolge. Eingeladene INSAID-Referenzen werden nicht überschrieben. |
| E7 | Akzeptiert: vollständige Haupt-/PB-Zählungen einschließlich Fehlern; fehlende, zusätzliche oder doppelte Designzellen verhindern vollständige Bewertung. Nicht definiertes Kappa/%GRR bleibt `not assessed`. |
| E8 | Akzeptiert: API-Robustheit verlangt den verifizierten INSAID-Eingang vor Aufrufen. Produktivhash aus QUELLE; synthetische TSVs nur als explizite Unit-Eingaben unter temporären Pfaden. |
| E9 | Akzeptiert: ASCII in R/, Paketressourcen statt Repo-Quellen in Unit-Tests, Suggests werden geprüft. Deutsche F8-Stufe ausschließlich in YAML. |
| E10 | Akzeptiert: ADR-008 für den ersten Golden-Satz; byte-identische Reproduktion aller vier Dateien unter beiden verfügbaren Kollationen. |
| E11 | Akzeptiert: Policy-Texte mit Fundstelle aus den lokalen Schnappschüssen. Der fehlende konkrete Anbieterbeleg wird offengelegt, siehe M2-BUILD-INFRA-02. |
| E12 | Akzeptiert: Stores, Berichte, Pakettarball, Check-Verzeichnis und Diagnose-Logs außerhalb des Arbeitsbaums. Dateiinventur und geschützte Hashes ohne Git. |
| E13 | Akzeptiert: ADR-007 umgesetzt; neue Defaults, Parserdispatch, Assessment-Prüfung und tatsächliches Rendering mit/ohne Assessment sind geprüft. |
| E14 | Akzeptiert als nonblocking `[INFRA]`: direkter Unit-Lauf mit `NOT_CRAN=true`; keine Änderung der Gate-Konfiguration. Entscheidung zu BL-56 bleibt beim Betreiber. |
| E15 | Akzeptiert als nonblocking `[INFRA]`: Ergänzung von K-M2-7 in `docs/gates-auswahl.md` bleibt Betreiberarbeit. |
| E16 | Akzeptiert: synthetische Herkunft überschreibt keine berechneten Bänder; Eingaben ohne belegende Metadaten heißen `unverified`. Gemischte Eingabe scheitert vor Fit und Rendering. |
| E17 | Akzeptiert: ausschließlich SQLite-Endungen für den AP1-Store, unabhängig vom generischen CSV-Pfad von msa_run. |
| E18 | Akzeptiert: README beschreibt neuen Store nach gescheitertem Pilot, Archivierung mit SHA-256 und Wiederholung aus der Kopie vor dem Block. Fehlender Provider führt zum Generation-Endpunkt-/ADR-Hinweis, ohne Override. |
| E19 | Akzeptiert: Ergebnis und Bericht nennen Kappa-Basis, ausgeschlossene Items und geladene INSAID-Referenzen. API-Auswertung ohne TSV gibt einen Hinweis und bleibt ausführbar. |
| E20 | Akzeptiert: Erkennung folgt ADR-006, nicht dem weiteren Warnungsbegriff der Mini-Referenz. Keine Anpassung der Mock-Parameter an Fit-Warnungen. Der direkte Mock-Hauptlauf und sein gemeinsamer Fit ergaben keine Fit-Warnungen. |

### Tatsächlich ausgeführte Prüfungen

Alle folgenden Prüfungen liefen in dieser BUILD-Phase. Sie sind
Builder-Diagnosen und ersetzen keine Gate-Abnahme. Die ausgeführten
Skripte und vollständigen Logs liegen unter `/tmp/llmsa-m2-*`; im
Arbeitsbaum wurden keine Laufdaten oder Reports abgelegt.

**Abhängigkeiten (Exit 0):**

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
```

Tatsächlicher Schluss:

```text
r-deps: pass — 18 Anforderungen erfüllt (R 4.6.1)
```

Vorhanden waren unter anderem `yaml 2.3.12`, `digest 0.6.39`,
`pkgload 1.5.3`, `httr2 1.3.0`, `jsonlite 2.0.0`, `DBI 1.3.0`,
`RSQLite 3.53.3`, `testthat 3.3.2`, `lme4 2.0.6`,
`ordinal 2026.7.26`, `rmarkdown 2.32` und `knitr 1.52`.
Es wurden keine Pakete installiert, aktualisiert oder heruntergeladen.

**Golden-Erzeugung (Exit 0):**

```bash
Rscript --vanilla data-raw/make_items_ap1.R
```

Output:

```text
AP1 freeze: pool 1180 classifications / 71 genes / 35 panels; main 100; pilot 10
Expert-panel conservative exclusions (item/cutoff pairs): 120
2b9f56914b40221512ac20bb217d874bf97c60fbddf6b73977f976fca5c8aa5b  items.csv
6690501d9a6725a08cbdd1f3f3d573bbaa8750153bdcdbf30a308b8038750b63  pilot.csv
85616580d6b7d8163e79d899f22a5a25c1bf4138df3f3f4f8b7b2a079616624d  QUELLE.txt
```

**Reproduktion und negativer Poolfall (Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-reproduce.R
```

Das Diagnoseskript kopiert Produktcode, Daten und Anker in eine
temporäre Paketkopie und verknüpft nur dort die vorhandenen lokalen
Quellen. Es führt denselben Erzeuger unter `C` und `C.UTF-8` aus und
vergleicht SHA-256 aller vier Dateien mit dem erzeugten Satz. Danach
erhöht es ausschließlich in der temporären Ankerkopie die erwartete
Poolzahl um eins und verlangt Abbruch ohne veränderte Ausgabedatei.
Tatsächlicher Output:

```text
AP1 byte reproduction: C 4/4 files identical
AP1 byte reproduction: C.UTF-8 4/4 files identical
AP1 pool mismatch: ERepo pool differs from ANK-51 (counts by classification, gene, panel or class). ; 4/4 existing files unchanged
AP1 reproduction elapsed seconds: 191.414
2b9f56914b40221512ac20bb217d874bf97c60fbddf6b73977f976fca5c8aa5b  items.csv
6690501d9a6725a08cbdd1f3f3d573bbaa8750153bdcdbf30a308b8038750b63  pilot.csv
85616580d6b7d8163e79d899f22a5a25c1bf4138df3f3f4f8b7b2a079616624d  QUELLE.txt
76005dc691e837eb9c6cdcda8273ea5b12baff2e7d7c0d6aaa6434cd9f7930f6  SHA256SUMS
```

Die Dateigrößen sind 21.291, 2.816, 1.917 und 229 Bytes. Die
Größenprüfung im Erzeuger nutzt ANK-TOL; es gibt keinen Rohdatenimport
in den Arbeitsbaum. Eine weitere Kollation ist nicht installiert
(`locale -a`: C, C.utf8, POSIX).

**Dokumentation, API und Zeichensatz (jeweils Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-docs.R
Rscript --vanilla /tmp/llmsa-m2-api.R
```

Roxygen wurde in einer temporären Paketkopie ausgeführt; nur die fünf
betroffenen Rd-Dateien wurden übernommen. Der API-Vergleich lädt das
Paket, liest ANK-02 und vergleicht sämtliche vorhandenen Positionen
und Vorgabewerte; zusätzlich verlangt er Defaults für Anhänge. Output:

```text
Documentation: generated 5 Rd files with roxygen2 8.1.1 ; NAMESPACE byte-identical
Appended default: msa_report assessment = NULL
Appended default: msa_run parse_by_prompt = NULL
Appended default: parse_choice whole_word = FALSE
ANK-02: 22 exports; all original argument positions/defaults preserved; no acmg export
R ASCII: pass
```

**Unit-, Integrations- und Berichtstests:**

Die neuen Unit-Tests verwenden nur installierbare Paketressourcen und
kleine ausdrücklich synthetische Eingaben. Sie decken T1 bis T5 und T7
ab: serialisierte HTTP-Anfragen, Dummy-Schlüsselzuordnung, API-Pilot
durch den CLI-Treiber, HTTP-Fehler mit Weiterlauf, Pilotgrenzen,
Herkunftskonflikte und unveränderte Stores, INSAID-Vorprüfung, Evaluation
ohne API-Konstruktion, Modal-/NA-Regeln, unabhängige Kappa-Gegenrechnung,
Bootstrap mit verworfenen Wiederholungen und RNG-Rückgabe, Fit-Rückfall,
unveränderte Reihenfolge, Referenzbasis, Unvollständigkeit, PB-Denominatoren,
Effekte, Bänder und tatsächliches Rendering. Die schnelle Unit-Prüfung
ersetzt keine wissenschaftliche Kernvalidierung aus M1.

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat
```

Abschließender tatsächlicher Output (Exit 0):

```text
Duration: 19.7 s
── Skipped tests (1) ──
• requireNamespace("ellmer", quietly = TRUE) is TRUE (1):
  'test-backends.R:32:3'
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 680 ]
r-tests: pass — 59 Tests in tests/testthat; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit elapsed seconds: 21.44; exit: 0
```

Der vorhandene ellmer-Skip wurde nicht geändert. Der Berichtstest mit
`skip_on_cran()` lief in diesem direkten Aufruf durch `NOT_CRAN=true`
tatsächlich mit. Der neue HTTP-400-Fall prüft den gespeicherten Fehler,
den erfolgreichen Folgeaufruf und JSON-null in den persistierten
Metadaten. Frühe Tests fanden Fehler in den neuen Testhilfen
(leerer R-Listenname, Argumentposition und NULL-Serialisierung des
synthetischen httr2-Response-Bauers); diese wurden berichtigt, ohne
die geforderten Prüfungen abzuschwächen. Der abschließende Lauf enthält
auch die Qualifizierung von `utils::head`/`utils::tail`, eine echte
numerische Fit-Permutation mit Abweichungen relativ zur Gesamtvarianz
und eine unabhängige Gegenrechnung des interpolierten Pilot-Quantils.
Der zusätzliche Präzisionsfall führte zunächst zu einem echten
Fehlschlag für `1 / 3`; die JSON-Serialisierung wurde korrigiert,
der identische Vergleich beibehalten. Der obige abschließende Lauf
enthält diese Korrektur aus ADR-009.

**Unveränderte API-Aufzeichnungen, ergänzender Builder-Prüfweg (Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-recordings.R
```

Das separate Diagnoseskript lädt keine Abnahme-Helfer. Es prüft die
drei Betreiber-Aufzeichnungen gegen ANK-94, übergibt ihre unveränderten
JSON-Bytes mit `httr2::local_mocked_responses()` an die tatsächlichen
AP1-Backends und führt `msa_run()` mit SQLite aus. Der Request-Abgleich
nutzt URL, Modell und den tatsächlichen httr2-Body-Serializer ohne
Socket. Schlüssel sind ausdrücklich synthetisch. Antworttext, IDs,
Modell, Fingerprint einschließlich NULL, Routing und verschachtelte
`usage` werden identisch mit den Originalen verglichen. Die erste
Ausführung fand den in ADR-009 dokumentierten Rundungsfehler; nach
der Produktkorrektur lautet der tatsächliche Output:

```text
Raw recording replay: sol response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Raw recording replay: llama response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Raw recording replay: qwen response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Recording checksums: 3/3 match ANK-94 and remain unchanged; live API calls: 0
Ran 1/1 deferred expressions
```

Dieser zusätzliche Nachweis ersetzt den unveränderten roten
Abnahmelauf nicht und verändert weder dessen Helfer noch die Fixtures.

**Paketbau und installierter Paketcheck (Exit 0):**

Eine explizite Positivliste kopiert nur Paketdateien in
`/tmp/llmsa-m2-check/src`: DESCRIPTION, NAMESPACE, LICENSE, NEWS,
README, .Rbuildignore, R, man, data, inst, vignettes sowie
tests/testthat.R und tests/testthat. Kein Git-Export, keine
Schlüsseldatei, keine geschützte Quelle und kein Harness-Pfad wird
kopiert. Dort wurden ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht exakt dem gelesenen Betreiber-
Prüfskript `orchestrator/lib/r-check.sh`; dieses selbst wurde wegen
seiner Git-Kommandos nicht gestartet. Keine andere Prüfregel wurde
gelockert. Der erste Check ergab zwei NOTEs; der Produktcode-Hinweis
auf unqualifizierte `head`/`tail` wurde im Produktcode behoben. Der
erneute Check nach der Korrektur ergab nur noch die Uhrzeit-NOTE.
Nach Ergänzung der letzten Unit-Fälle und der Präzisionskorrektur
aus ADR-009 wurde die Paketkopie nochmals mit dem aktuellen
Produkt- und Teststand gebaut und geprüft. Der abschließende
vollständige Check endet mit:

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 57.15; exit: 0
```

Die verbleibende NOTE ist wörtlich:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Uhrzeitprüfung wurde nicht deaktiviert. Installierte Tests:
`[ FAIL 0 | WARN 0 | SKIP 2 | PASS 676 ]`. Die beiden vorhandenen
Skips sind der Berichtstest mit `skip_on_cran()` und der ellmer-
Fehlerpfad, weil ellmer installiert ist. Der neue AP1-Berichtstest
läuft auch im Paketcheck. Der HTTP-400-Fall, die echte numerische
Permutation, die Pilot-Quantilprüfung und der numerische Metadaten-
Rundlauf sind im abschließenden direkten Unit-Lauf und im
abschließenden Paketcheck enthalten.

**Direkter Mock-Lauf und Bericht:**

```bash
Rscript --vanilla inst/validation/ap1/run.R --part pilot --backend mock --store /tmp/llmsa-m2-pilot.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part main --backend mock --store /tmp/llmsa-m2-main.sqlite
Rscript --vanilla inst/validation/ap1/run.R --evaluate-only --backend mock --store /tmp/llmsa-m2-main.sqlite --report-dir /tmp/llmsa-m2-smoke-reports
```

Alle drei Aufrufe endeten mit Exit 0. Relevanter tatsächlicher Output:

```text
AP1 pilot backend=mock; stored calls=90; store=/tmp/llmsa-m2-pilot.sqlite
sol parser passed: 29 recognized of 30 planned; complete=TRUE
llama parser passed: 29 recognized of 30 planned; complete=TRUE
qwen parser passed: 30 recognized of 30 planned; complete=TRUE
AP1 main backend=mock; stored calls=5400; store=/tmp/llmsa-m2-main.sqlite
```

Alle drei Modelle meldeten `4xx passed`, `provider failed` und
`cost failed`; der Mock liefert keine Provider- oder Tokenmessungen.
Beide Hauptplanblöcke hatten im Wiederholungstagsbericht Fehleranteil
0 und keine beobachteten Anbieter-/Modellwechsel. Die drei HTML-Dateien
`ap1-sol.html`, `ap1-llama.html`, `ap1-qwen.html` wurden gerendert.
Sie berichten für diese Mock-Daten jeweils `No fit warnings.`; der
gemeinsame Fit hat ebenfalls keine Warnung. Die Formate tragen die
vorläufige und synthetische Kennzeichnung. Zusätzlich erscheint vom
R-/Pandoc-Umfeld die Meldung `Failed to connect to system scope bus via
local transport: Operation not permitted`; das Rendering endet dennoch
erfolgreich und die Dateien wurden in den Tests inhaltlich geprüft.

**Vollständiger unveränderter M2-Abnahmelauf vor ADR-009 (Exit 1):**

```bash
/usr/bin/time -f 'M2 acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Alle sieben M2-Dateien mit ihren 62 Testblöcken liefen, ohne Skip.
Es wurde keine Acceptance-Funktion ersetzt und keine Replay-Hilfe
angepasst. Die längste Teilprüfung enthält die unabhängige
Parser-Gegenrechnung sowie sämtliche Mock-CLI-Läufe und Resume.
Tatsächlicher Reporter-Output nach Datei:

```text
✔ |        149 | m2-1-items [132.3s]
✔ |         34 | m2-2-memorisation [83.7s]
✔ |        837 | m2-3-prompts-parser [488.2s]
✖ | 6       14 | m2-4-backends [1.6s]
✔ |        106 | m2-5-plan [1.7s]
✔ |        374 | m2-6-evaluate [96.5s]
✖ | 1      353 | m2-7-robustness-pilot [93.1s]
Duration: 897.2 s
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 1867 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
M2 acceptance elapsed seconds: 899.16; exit: 1
```

Die sieben negativen Erwartungen verteilen sich auf sechs Testblöcke:
fünf in K-M2-4 und den Systemspalten-Test von K-M2-7. Ursprung ist
jeweils der unveränderte HTTP-Replay-Pfad:

```text
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Die nachgelagerte JSON-Prüfung sieht deshalb fehlende `meta` statt einer
Aufzeichnung. Im 4xx-Fall ist auch der zweite Aufruf ein Socket-Fehler
statt der aufgezeichneten erfolgreichen Antwort; daraus entstehen zwei
fehlgeschlagene Erwartungen. Der Systemspalten-Test stoppt bereits beim
ersten Replay. Alle übrigen M2-Testblöcke bestehen. Die beiden Stores
des Mock-Prüfwegs enthalten 9.090 Zeilen (Hauptplan, PB, Pilot; erneuter
Pilot unverändert) und 5.400 Zeilen (Hauptplan am Stück); Reihenfolge,
Prompthashes und Ausschluss neuer Dateien bestehen in der Abnahme.
Die K-M2-6-Nachrechnungen bestehen auch bei erzwungenem Rückfall und
nach lokalem INSAID-Join. Für die reale API-Wiedergabe bleibt
M2-BUILD-INFRA-01 offen, für die Anbieter-Policy A.7 zusätzlich
M2-BUILD-INFRA-02. Das Gesamtergebnis dieses Abnahmelaufs ist rot.

Nach der alleinigen Änderung der numerischen Metadaten-Serialisierung
durch ADR-009 wurden alle Unit-Tests, der installierte Paketcheck,
der separate Aufzeichnungsprüfweg und die betroffene unveränderte
API-Abnahmedatei erneut ausgeführt. Die vollständige M2-Suite wurde
nicht nochmals ausgeführt. Befehl des gezielten Abnahmelaufs:

```bash
/usr/bin/time -f 'M2 API acceptance after ADR-009 elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'testthat::test_dir("tests/acceptance",filter="m2-4-",load_package="source",reporter=testthat::ProgressReporter$new(show_praise=FALSE),stop_on_failure=TRUE)'
```

Tatsächlicher Schluss nach ADR-009, weiterhin dieselben Socket- und
Folgefehler in den fünf betroffenen Testblöcken:

```text
[ FAIL 6 | WARN 0 | SKIP 0 | PASS 14 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
M2 API acceptance after ADR-009 elapsed seconds: 3.08; exit: 1
```

**Abschließende Dateiintegrität (Exit 0):**

Ein lesender Python-Vergleich gegen das vor BUILD angelegte Inventar
unter `/tmp/llmsa-m2-before.json` prüft neue und geänderte Pfade sowie
SHA-256 der erfassten geschützten Dateien. Git-Metadaten und
Geheimnisdateien sind vom Inhaltsvergleich ausgeschlossen; es werden
keine Geheimnisinhalte gelesen. Ausgeführt wurde
`python3 /tmp/llmsa-m2-integrity.py`. Tatsächlicher Output:

```text
Inventory: 18 new files; 13 changed baseline files; all in Builder paths; no missing baseline files
Protected baseline: 78 files byte-identical
Workspace artifacts: no Rplots.pdf, tarball or Rcheck directory
R ASCII: pass
```

Die 78 Dateien umfassen alle erfassten Abnahmetests, API-Fixtures,
Anker, Spezifikationen, Verträge, Handoffs sowie AGENTS,
IMPLEMENTATION-RULES, toolchain.json, NAMESPACE, .Rbuildignore,
tests/testthat.R und beide Mutations-Scope-Dateien. Die
Inventur ersetzt nicht die Territoriumsprüfung des Orchestrators.

### Offene Punkte und Übergabe

- **M2-BUILD-INFRA-01 — `[INFRA]`, nonblocking für den Builder.**
  Ref: K-M2-4, K-M2-7 Systemspalte, ACC-10 und
  `tests/acceptance/setup-m2.R:771`. Der unveränderte Replay-Helfer
  verwendet `httr2::req_dry_run()`, das in httr2 1.3.0 über curl/httpuv
  einen lokalen Socket öffnet. Die Builder-Sandbox verweigert ihn mit
  `System failure for: socket() (Operation not permitted)`. Dadurch
  können diese Abnahmefälle hier keine erfolgreiche HTTP-Wiedergabe
  belegen; Folgefehler betreffen fehlende Metadaten und die zweite
  Antwort nach einem HTTP-Fehler. Kein Test und keine Berechtigung
  wurde geändert. Die eigenen Unit-Tests prüfen die Bytes mit dem
  tatsächlichen httr2-Serializer ohne Socket und durchlaufen den
  Produkt-HTTP-Pfad mit synthetischen Antworten. Der zusätzliche
  separate Prüfweg reproduziert außerdem alle drei unveränderten
  Betreiber-Aufzeichnungen einschließlich persistierter Metadaten.
  Das ist ergänzende Evidenz, kein Ersatz für die Aufzeichnungsabnahme. Vorschlag an
  Betreiber/Reviewer: unveränderte Abnahme im regulären Gate-Umfeld
  mit funktionsfähigen lokalen Sockets ausführen.
- **M2-BUILD-INFRA-02 — `[INFRA]`, Quellenlücke.**
  Ref: `docs/03-anwendungspipeline.md` A.7 und PLAN-UPDATE E11.
  Die bezeichnete eingefrorene `Provider_Logging.html` liefert
  allgemeine OpenRouter-Regeln, aber keine spezifischen Belege für
  CoreWeave oder DeepInfra. Sowohl Textspiegel als auch HTML wurden
  geprüft. Tatsächlicher Output der HTML-Suche:
  `Provider_Logging snapshot: CoreWeave lines = 0 ; DeepInfra lines = 0`.
  YAML und Berichte nennen den belegten allgemeinen Stand und diese
  Lücke; sie erfinden keine Aufbewahrungsdauer. Handoff-Vorschlag:
  Betreiber liefert datierte Anbieterbelege, Reviewer bestätigt die
  Ergänzung mit dem nötigen ADR-/Ankerweg. A.7 gilt in diesem Punkt
  nicht als vollständig belegt.
- **E14 / BL-56 und E15 / BL-48 — `[INFRA]`.** Gate-Umgebung für
  `NOT_CRAN` und die dokumentierte Zuordnung von K-M2-7 bleiben beim
  Betreiber. BACKLOG wurde nicht angefasst; der Reviewer übernimmt
  offene Punkte im Code-Review.
- **PLAN-M2-QA-1 — `[QA-PENDING]`.** Eigenständige E2E-/Fuzz-Prüfung
  bleibt bei QA. Der Builder ersetzt weder diese Rolle noch die
  Reviewer-Abnahme durch eigene Tests.

Die einzige Planergänzung ist die in ADR-009 dokumentierte Korrektur
der numerischen JSON-Präzision. Es gab keinen API-Netzzugriff, keine
Verwendung realer API-Schlüssel, keine Git-Kommandos und keinen Bypass. Statistikkern
`R/fit.R`/`R/grr.R`, Abnahmetests, Anker, Verträge und Orchestrator
bleiben unverändert. Der Orchestrator führt Territoriumsprüfung,
Phasen-Commit und die vollständigen M0/M2-/QA-Gates aus. Insbesondere
werden hier weder `gates.json` geschrieben noch K-M2 pauschal als
abgenommen erklärt.

## M2 — REWORK, Runde 2 (27.10.2026)

Die fünf blocking-Befunde E21 bis E25 aus REVIEW Runde 1 sind im
Produktcode `R/acmg.R` nach ADR-010 behoben; E27 ist zusätzlich
umgesetzt. Der aktuelle Builder-Lauf belegt die unveränderten fünf
QA-Tests grün. Die vollständige Gate-Abnahme steht weiterhin aus.
Maßgeblich bleiben die gelesenen Gate-Fakten von Runde 1:
`tests: fail`, `result: fail`, alle anderen Gates `pass`, kein
Status `error`. Deren Ursache waren ausschließlich QA-M2-001 bis
QA-M2-005; die Abnahme war dort mit 2.340 Erwartungen grün.

Die vollständigen Antworten mit Referenzen, Dateistellen, Kommandos
und tatsächlichem Output stehen in
`orchestrator/handoff/M2/REWORK-NOTES.md`. ARBITER liegt nicht vor;
LESSONS enthält keine zusätzliche Lehre. Kein neuer Builder-ADR ist
nötig, da die Änderungen die angenommene ADR-010 umsetzen.

| Befund | Antwort und Stand |
| --- | --- |
| E21 / QA-M2-001 | Behoben: Wiederholungstagsdiagnosen enthalten nur beobachtete Modell-/Blockkombinationen. Jeder Einzelmodellbericht enthält seine eigenen korrekten Diagnosen. |
| E22 / QA-M2-002 | Behoben: Fehlende oder leere Anbieterwerte fehlerfreier OpenRouter-Antworten lösen den Wiederholungstagshinweis aus; Sol und fehlende Angaben bei Backendfehlern erzeugen diesen zusätzlichen Auslöser nicht. |
| E23 / QA-M2-003 | Behoben: Ein API-Marker ersetzt keine fehlenden Zeilenbelege. Mock-Herkunft bleibt synthetisch. API-Stores mit unbelegten fehlerfreien Zeilen werden schreibgeschützt abgewiesen; reine Fehlerstores mit Marker und bisherige Konfliktprüfungen bleiben unterstützt. |
| E24 / QA-M2-004 | Behoben: Modal- und Ausschlusszählungen umfassen jedes Planitem, auch ohne Hauptplanzeile. Merkmale stammen nur aus runs; vollständig fehlende Merkmale bleiben NA. PB-Referenzquoten verwenden die PB-Referenzspalte. Unvollständige Hauptpläne bleiben not assessed. |
| E25 / QA-M2-005 | Behoben: Klassenprüfung auch über PB-Zeilen vor dem Fit. Ungültige Replikat-/Blockwerte oder doppelte Schlüssel verhindern eine vollständige Robustheitsbewertung. |
| E26 | ADR-010 Nr. 6 bestätigt die strengere Pilotsperre ohne API-ID. Keine Produktänderung; für alle drei Modelle unit-getestet. Die Entkopplung des Pilot-Quantiltyps bleibt BL-64. |
| E27 | Behoben: Bericht nennt fehlende provider- und system_fingerprint-Felder unter fehlerfreien Antworten mit Nenner; echtes HTML-Rendering geprüft. BL-65 zur Schließung an den Reviewer. |
| E28 / BL-63 | OUT-OF-TERRITORY [INFRA]: Provider_Logging-Snapshot erneut geprüft, jeweils 0 Treffer für CoreWeave/DeepInfra. Datierte spezifische Belege fehlen; Betreiber/Reviewer müssen sie liefern und verankern. |
| E29 / BL-56 | OUT-OF-TERRITORY [INFRA]: gate-tests.log:92 enthält weiter den On-CRAN-Skip von test-report.R:5. Der direkte Builder-Lauf führt ihn mit NOT_CRAN=true aus; Gate-Konfiguration bleibt Betreiberarbeit. |
| E30 / BL-48 | OUT-OF-TERRITORY [INFRA]: docs/gates-auswahl.md:87 nennt weiterhin K-M2-1 bis K-M2-6. Ergänzung von K-M2-7 bleibt Betreiberarbeit. |

### Echte Prüfbelege dieser Runde

**Unveränderte QA vor der Änderung (Exit 1):**

```bash
Rscript --vanilla orchestrator/lib/r-tests.R tests/e2e tests/fuzz
```

```text
[ FAIL 8 | WARN 0 | SKIP 0 | PASS 2 ]
[ FAIL 5 | WARN 0 | SKIP 0 | PASS 0 ]
r-tests: fail — 5 Tests in tests/e2e, tests/fuzz; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
```

**Unit- und unveränderte QA-Tests nach der Korrektur (Exit 0):**

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

```text
✔ |        194 | acmg-rework [7.5s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 874 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 73 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 33.90; exit: 0
```

Neun neue Unit-Blöcke unter `tests/testthat/test-acmg-rework.R`
decken E21 bis E27 ab. Alle bestehenden Tests bleiben byte-identisch.
Der einzige direkte Skip ist der vorhandene ellmer-Fehlerpfad, weil
ellmer installiert ist. Der generische Berichtstest wird tatsächlich
ausgeführt. Die neue HTML-Prüfung normalisiert nur Render-Leerraum;
erwarteter Text und Zahlen bleiben exakt.

In einer temporären Paketkopie mit denselben neuen Tests, aber der
gesicherten alten `acmg.R`, scheitern acht der neun neuen Blöcke;
E26 besteht auch vorher. Echter Schluss des in REWORK-NOTES vollständig
angegebenen Kommandos (erwartet Exit 1):

```text
Baseline regression blocks: 9; failed: 7; errors: 4; skipped: 0
```

Fehler und Fehlschläge überlappen in den Blockzählungen. Der aktuelle
Quellbaum wurde für diese Gegenprobe nicht zurückgesetzt.

**Betroffene unveränderte Abnahme (Exit 1, lokale Infrastruktur):**

```bash
/usr/bin/time -f 'M2 targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[67]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✔ |        374 | m2-6-evaluate [216.3s]
✖ | 1      353 | m2-7-robustness-pilot [94.1s]
Duration: 310.4 s
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 727 ]
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
M2 targeted acceptance elapsed seconds: 312.17; exit: 1
```

**M2-R2-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Der einzige
negative Test ist die Systemspalten-Wiedergabe in K-M2-7: Der
unveränderte Reviewer-Helfer öffnet über curl/httpuv einen lokalen
Socket, den die Builder-Sandbox verweigert. Vollständiger Stacktrace
in REWORK-NOTES und `/tmp/llmsa-m2-r2/acceptance.log`. Kein Testhelfer,
keine Berechtigung und kein Produktcode wurden zur Umgehung geändert.
K-M2-6 und die fachliche Robustheitsauswertung bestehen. Im regulären
Gate der Runde 1 bestand auch dieser Socket-Pfad; der historische
M2-BUILD-INFRA-01 ist dort laut REVIEW erledigt. Der Orchestrator
führt den aktuellen vollständigen M0/M2-Lauf im Gate-Umfeld aus.
Die übrigen M2-Abnahmedateien wurden hier nicht erneut gestartet;
M0-Prüfwege mit Git-Kommandos wurden nicht ausgeführt.

**Paketbau und installierter Check (je Exit 0):**

Mit einer Positivliste der Paketdateien wurde eine Kopie ohne
Schlüssel, geschützte Quellen und Harness-Dateien unter
`/tmp/llmsa-m2-r2/package-check/src` angelegt. Darin ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 66.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 870 ]
```

Incoming-Remote entspricht dem Betreiber-Prüfskript; keine andere
Prüfregel wurde abgeschaltet. **M2-R2-INFRA-CLOCK — OUT-OF-TERRITORY
[INFRA]:** Die einzige NOTE lautet `Unable to verify current time.`
Die Uhrzeitprüfung bleibt aktiv. Die beiden installierten Skips sind
unverändert On-CRAN im generischen Bericht und ellmer. Neue AP1-
Berichts- und Regressionsprüfungen laufen auch im installierten Paket.

### Integrität und Übergabe

`python3 /tmp/llmsa-m2-r2/integrity.py` endete mit Exit 0:

```text
Inventory: 2 changed baseline files, 2 new files; all assigned Builder paths; no removed files
Preserved baseline: 154/154 files byte-identical
Existing tests and fixtures: 38/38 byte-identical
R source and new test comments: ASCII
Workspace artifacts: no Rplots.pdf, package archive, Rcheck directory or SQLite store
Gate facts: still round 1, result fail; no Builder verdict or state write
```

Geändert sind `R/acmg.R` und dieser Nachtrag; neu sind die Unit-Datei
und die zugewiesene `orchestrator/handoff/M2/REWORK-NOTES.md`.
Die SHA-256-Inventur ersetzt nicht das Territoriums-Gate.
R/fit.R und R/grr.R bleiben unverändert; keine MUT-EQUIV-Claims und
keine Approvals. Es gibt keinen offenen QA-PENDING-Befund aus dem
aktuellen Review. Keine Git-Kommandos, keine Abhängigkeitsinstallation,
keine realen API-Schlüssel oder API-Aufrufe, keine Golden- oder
Schwellenänderung, kein eigener Gate- oder Verdict-Schreibzugriff.
Territoriumsprüfung, Phasen-Commit und Abnahme folgen durch den
Orchestrator und Reviewer.

## M2 — REWORK, Runde 3 (27.10.2026)

Der Abschluss der vorigen Runde ist inzwischen belegt:
`orchestrator/state/M2/gates.json` nennt Runde 2 und `result: pass`;
alle acht Gates sind grün, kein Status `error`. REVIEW Runde 2 nimmt
E21 bis E25 und E27 an und bestätigt E26. Es verlangt trotzdem
REWORK wegen E31: R-Partial-Matching verwechselt im Pilot einen
fehlenden Antwortanbieter mit dem Anfragerouting `provider_order`.
Die lokalen Socket-/Uhrzeitbefunde der Runde 2 traten im damaligen
regulären Gate nicht auf.

E31 ist jetzt im Produktcode behoben; E32 und E33 sind zusätzlich
umgesetzt. Die Belege und vollständigen Kommandos stehen in
`orchestrator/handoff/M2/REWORK-NOTES.md` der Runde 3. ARBITER liegt
weiterhin nicht vor, LESSONS enthält keine Lehre. Diese Builder-
Prüfungen erteilen keine Gate-Abnahme.

Geändert ist ausschließlich Produktcode in `R/acmg.R`, dazu dieser
Nachtrag und der zugewiesene Handoff. Neu sind sieben Unit-Blöcke in
`tests/testthat/test-acmg-pilot-metadata.R`. Bestehende Tests, Fixtures,
Anker, Plan, Schwellen, Schnittstellen und Mutations-Scope bleiben
unverändert; kein neuer ADR ist erforderlich.

| Befund | Antwort und Stand |
| --- | --- |
| E31 | Behoben: exakte Metadatenfelder für Anbieter, API-/Mock-Belege und Tokens. Fehlender/null/leerer/Leerraum-Anbieter liefert zwölf Pilotregeln und den Generation-Hinweis mit Antwort-ID. Pilot und Resume berichten; main und robustness bleiben vor weiteren Aufrufen benannt gesperrt. Direkte Auswertung und evaluate-only übergeben alle Pilotregeln an die Berichte. |
| E32 / BL-66 | Behoben: Eine gescheiterte Anbieterregel nennt fehlende API-Belege (`meta$id`, `meta$model_snapshot`), auch bei richtigem Anbieter. Die strengere Sperre bleibt erhalten. |
| E33 / BL-67 | Behoben: Unbelegte Store-Herkunft erhält eine eigene Meldung mit Zahl der betroffenen fehlerfreien Antworten, Belegfeldern und Hinweis auf einen neuen Store. Schreibgeschützter Abbruch und unveränderter Store bleiben erhalten. |
| E26 / BL-64 | Sperre bestätigt und weiter belegt. Quantil-Entkopplung vertagt: Der unveränderte freigegebene Plan trägt Typ 7; diese Korrektur ändert keine statistische Rechenregel. |
| E28 / BL-63 | OUT-OF-TERRITORY [INFRA]: Provider-Logging-Textspiegel enthält weiter je 0 Treffer für CoreWeave und DeepInfra. Betreiber liefert datierte spezifische Belege; Reviewer verankert sie. |
| E29 / BL-56 | OUT-OF-TERRITORY [INFRA]: Gate-Log Runde 2, Zeile 107, enthält den On-CRAN-Skip; r-tests.R enthält 0 NOT_CRAN-Verweise. Der direkte Unit-Lauf führt den Bestandsbericht aus. Dauerhafte Gate-Konfiguration bleibt beim Betreiber. |
| E30 / BL-48 | OUT-OF-TERRITORY [INFRA]: docs/gates-auswahl.md:87 nennt weiter K-M2-1 bis K-M2-6. Betreiber ergänzt K-M2-7. |
| E21–E25 / QA-M2-001–005 | Laut REVIEW Runde 2 erledigt; alle unveränderten QA- und bisherigen Regressionsprüfungen bleiben grün. |
| E27 | Erledigt; der unveränderte Bestandsregressionstest rendert und prüft die Fehlstellenzählungen im HTML-Bericht. |

### Ausgeführte Prüfungen

**Regressionserkennung (erwartet Exit 1).** Die endgültigen sieben
neuen Blöcke laufen in einer temporären Paketkopie mit der vor dieser
Phase gesicherten `R/acmg.R`. Alle sieben sind rot; zwei enthalten
sowohl fehlgeschlagene Erwartungen als auch einen Fehler. Tatsächlicher
Output aus `/tmp/llmsa-m2-r3/regression-final-before.log`:

```text
Regression blocks: 7; failed blocks: 4; error blocks: 5; skips: 0
Error: Error in `vapply(responses, function(x) x$provider %||% "", "")`: values must be type 'character',
 but FUN(X[[1]]) result is type 'list'
```

Der Arbeitsbaum wurde dafür nicht zurückgesetzt. Dies ist kein
Mutationsscore und kein Äquivalenz-Claim.

**Neue Tests einschließlich Betreiber-Aufzeichnungen (Exit 0).**

```bash
Rscript --vanilla -e 'options(llmsa.test.ap1_recordings = normalizePath("tests/fixtures/api")); testthat::test_dir("tests/testthat", filter = "acmg-pilot-metadata", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✔ |        370 | acmg-pilot-metadata [14.2s]
Duration: 14.2 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 370 ]
```

Alle Blöcke laufen im installierten Paket mit ausdrücklich synthetischen
Antworten. Die explizite Testoption fügt die vorhandenen Aufzeichnungen
hinzu und verlangt dann deren Dateien. Änderungen an den Antworten
finden nur im Speicher statt; alle drei Dateien entsprechen weiterhin
ANK-94. URL-/Modell-Matching und synthetische Schlüssel verhindern
reale Aufrufe. Die Auswertungs-Unit-Prüfung nutzt Fit-/Renderer-Stubs
und prüft die an den Renderer übergebenen Pilot-Tabellen; echte Fits
und Berichte sind durch die unveränderte Abnahme unten belegt.

**Unit- und unveränderte QA-Tests (Exit 0).**

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

```text
✔ |        222 | acmg-pilot-metadata [6.8s]
✔ |        194 | acmg-rework [7.8s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1096 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 80 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 41.65; exit: 0
```

Der unveränderte ellmer-Fehlerpfad ist der einzige Skip. Der generische
Bestandsbericht wird durch `NOT_CRAN=true` tatsächlich ausgeführt.

**Paketbau und installierter Paketcheck (je Exit 0).** Eine Positivliste
kopiert Paketdateien nach `/tmp/llmsa-m2-r3/package-check/src`, ohne
Schlüssel, Betreiber-Fixtures oder Harness-Dateien. Im übergeordneten
Verzeichnis ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 71.84; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 1092 ]
```

**M2-R3-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Die einzige NOTE
laut `package-check/check.log:29–31` lautet `Unable to verify current
time.` Die Uhrzeitprüfung bleibt aktiv. Incoming-Remote entspricht
dem Betreiber-Prüfskript; keine weitere Prüfregel wurde abgeschaltet.
Die beiden installierten Skips sind wie bisher der generische Bericht
(On CRAN) und ellmer. Keine ERRORs/WARNINGs.

**Betroffene unveränderte Abnahme (Exit 1, Infrastruktur).**

```bash
/usr/bin/time -f 'Targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[467]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✖ | 6       14 | m2-4-backends [1.1s]
✔ |        374 | m2-6-evaluate [219.5s]
✖ | 1      353 | m2-7-robustness-pilot [93.7s]
Duration: 314.6 s
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 741 ]
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
Targeted acceptance elapsed seconds: 316.37; exit: 1
```

**M2-R3-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Der unveränderte
HTTP-Replay-Helfer von K-M2-4/K-M2-7 öffnet über curl/httpuv einen
lokalen Socket; die Sandbox verweigert ihn. Folgefehler betreffen
fehlende gespeicherte Metadaten und die zweite Antwort nach HTTP 4xx.
Es sind dieselben sechs Testblöcke wie im ursprünglichen BUILD.
`acceptance.log` enthält die vollständigen Stacktraces; REWORK-NOTES
ordnet die sieben negativen Erwartungen zu. Keine Umgehung, kein
Test- oder Produkt-Scheinfix.

K-M2-6 besteht vollständig mit echten Fits, Rückfall und HTML-Berichten;
die fachliche PB-Auswertung in K-M2-7 ebenfalls. Die übrigen
M2-Abnahmedateien wurden hier nicht wiederholt. Die vollständigen
Gates, einschließlich der Git-verwendenden M0-Prüfwege, führt der
Orchestrator nach der Territoriumsprüfung aus.

### Integrität und Übergabe

`python3 /tmp/llmsa-m2-r3/integrity.py` endete mit Exit 0:

```text
Inventory: 3 changed baseline files, 1 new file; all assigned Builder paths; no removed files
Changed: PROGRESS.md, R/acmg.R, orchestrator/handoff/M2/REWORK-NOTES.md
New: tests/testthat/test-acmg-pilot-metadata.R
Protected baseline: 201/201 files byte-identical
Existing tests and fixtures: 39/39 files byte-identical
R source and new test: ASCII
Checked package copy: final R/acmg.R and new test byte-identical
Workspace artifacts: no Rplots.pdf, package archive, Rcheck directory or SQLite store at the root
Gate facts: still round 2, result pass; no Builder verdict or state write
```

Die Inventur ersetzt nicht das Territoriums-Gate. Kein Zugriff auf
Git-Metadaten oder Schlüsseldateien, keine Git-Kommandos, keine
Installation und keine realen API-Aufrufe. R/fit.R und R/grr.R sind
unverändert; keine MUT-EQUIV-Claims und keine Approvals. Es gibt
keinen offenen QA-PENDING-Befund im aktuellen Review. E31 bis E33
werden zur Prüfung übergeben; E26/BL-64 bleibt vertagt, Infrastruktur
mit Log-Belegen OUT-OF-TERRITORY. BACKLOG-Pflege und vollständige
Gate-Abnahme bleiben bei Reviewer und Orchestrator.
