# M1b — REWORK, Runde 2

Rolle: Builder · Phase: `60-rework` · Stand: 31.10.2026.

## Grundlage und Grenze der Aussage

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
Handoff-Schema, REVIEW und verdict-code.json Runde 1, CRITERIA.json,
ARBITER.md, LESSONS.md, PROGRESS.md, freigegebener Plan, die zugehörigen
Specs, ADR-023 bis ADR-027, Abnahme-/QA-Tests sowie gates.json und die
zugehörigen Gate-Logs. Die Arbiter-Direktive zu K-M1b-5 bleibt unverändert:
Logit-Restvarianz pi^2/3, Live-Vergleiche auf der latenten Skala, ANK-25
nur als gesonderte Installationsprüfung.

Die gelesenen Orchestrator-Fakten stammen aus Runde 1: `tests: fail`,
`mutgate: fail`, die übrigen sechs Gates `pass`; `mutfull` war nicht
fällig. Kein Gate hatte Status `error`; kein aktueller Befund trägt
`[QA-PENDING]`. E19 und E22 sind bereits als `[INFRA]` eingeordnet.
Der Mutationslauf brach vor dem ersten Mutanten ab:

```text
orchestrator/state/M1b/gate-mutgate.log:
r-mutation: unmutierter Testlauf: 118.2 s; 355 Tests, davon 6 fehlgeschlagen, 1 abgebrochen
r-mutation: Abbruch vor dem ersten Mutanten: Schon unmutiert scheitern 7 Tests
```

Die folgenden Ergebnisse sind ausgeführte Builder-Prüfungen, kein neues
Gate- oder Abnahme-Verdict. Insbesondere bleiben die nachgewiesenen
OUT-OF-TERRITORY-Ursachen unten offen. Gate-Fakten, Verdicts und BACKLOG
wurden nicht geschrieben. Es wurden keine Git-Kommandos ausgeführt.

## Antworten auf jede Befund-ID

- **E12 / QA-M1b-001 — akzeptiert, im Produktcode behoben.**
  Ref: ADR-027 Nr. 1.3, REVIEW E12, Gate tests.
  `R/fit.R` wertet `...` vor dem Engine-Aufruf aus und verwendet für
  `glmer` und `clmm` `do.call()` mit eingebetteten Daten, Familien- und
  Steuerungsargumenten. Die gespeicherten Aufrufe haben qualifizierte
  Funktionsnamen und keine `..1`-Platzhalter. Der neue
  `tests/testthat/test-fit-latent-rework.R` prüft Aufrufe aus lokalen
  Funktionen, spätere Re-Evaluation, `refit()` und `msa_boot()` gegen
  `bootMer()` mit einer unabhängig formulierten latenten ICC.
  Belege: P1/P2 und QA-M1b-001 in P4 unten.

- **E13 / QA-M1b-002 — akzeptiert, im Produktcode behoben.**
  Ref: ADR-027 Nr. 1.1–1.2, K-M1b-6, REVIEW E13.
  Der gemeinsame Eingabepfad in `R/fit.R` wertet `subset`, `weights` und
  `offset` in der bereinigten Datenmaske und im unmittelbaren Aufrufer
  aus. Im latenten Pfad wählt `model.frame()` die Zeilen vor dem
  Formelaufbau; Gewichte und Offsets werden gemeinsam ausgerichtet.
  Formel, Faktorstufen, `derived`, `data` und `n` beziehen sich damit auf
  dieselbe Auswahl, auch bei wiederholten Indizes und `na.action`.
  Ordinale Offsets stehen als `offset(.msa_offset)` vor den Zufallstermen
  in der Formel; ADR-028 erläutert die Rahmenindizierung von `clmm`.
  Neue Tests vergleichen beide Typen mit direkten Engine-Fits auf
  unabhängig ausgewählten Daten, Gewichten und Offsets. Bei ordinalen
  Häufigkeitsgewichten meldet `nobs(clmm)` die Gewichtssumme; `n` zählt
  weiterhin Zeilen. Genau das bestätigt auch der direkte Engine-Fit.
  Diese Unterscheidung steht in `man/msa_fit.Rd` und ADR-028; kein
  Engine-Feld wird künstlich umgeschrieben. Belege: P1/P2 und QA-M1b-002.

- **E14 / QA-M1b-003 — akzeptiert, im Produktcode behoben.**
  Ref: ADR-027 Nr. 2–3, K-M1b-4/-6, REVIEW E14 und LESSONS.
  `R/fit.R` bestimmt ordinale Singularität aus den Zufallskomponenten,
  bevor die abgeleiteten Komponenten ergänzt werden. Die bisherige
  Schwelle bleibt. Vor `clmm()` werden sämtliche Zufallsterme auf mehr
  als zwei beobachtete Stufen und die festen Zwei-Stufen-Faktoren auf
  vollen Spaltenrang geprüft; Fehlermeldungen nennen den Term bzw. die
  Faktoren. Neue Tests decken alle Paare der optionalen Zwei-Stufen-
  Faktoren, konfundierte Interaktionen, degenerierte Kontraste und einen
  Nullkontrast bei inneren Zufallskomponenten ab. Die numerischen Orakel
  sind direkte `clmm`-Fits und die Varianz der beiden festen Effekte.
  Alle neun Kurzlaufdateien wurden nach der letzten Codeänderung erneut
  erzeugt (P7). Belege: P1/P2, QA-M1b-003 und P3.

- **E15 / QA-M1b-004 — akzeptiert, Testumgebung ergänzt.**
  Ref: ADR-027 Nr. 7, IMPLEMENTATION-RULES Projekt-Amendment, REVIEW E15.
  Der aktuelle Auftrag verbietet Änderungen an bestehenden Tests.
  Deshalb bleibt `test-validation-latent.R` byte-identisch. Der neue
  `tests/testthat/helper-validation-vignette.R` kopiert ausschließlich
  die Original-Rmd aus `REPO_ROOT` in eine Quellpaketkopie, falls dort
  sowohl die installierte als auch die lokale Vignette fehlt. Fehlt
  das Original, bleibt das ein Fehler. Erwartungen, Literalprüfung,
  Quellenliste und Toleranzen bleiben unangetastet. Es wird kein
  Produktcode aus `REPO_ROOT` geladen; mutierte Paketfunktionen würden
  deshalb weiterhin getestet. ADR-028 dokumentiert diese Umsetzung.
  Die vollständige Unit-Suite wurde zusätzlich in einer neu angelegten
  Paketkopie ohne `vignettes/` ausgeführt (P2). QA-M1b-004 besteht in P4;
  dessen unabhängiger Namespace-Seiteneffekt ist separat unten belegt.

- **E16 / QA-M1b-005 — akzeptiert, im Produktcode behoben.**
  Ref: ADR-027 Nr. 4, K-M1b-6, REVIEW E16.
  `R/fit.R` validiert explizite bzw. aus geordneten Faktoren abgeleitete
  Labels vor der Datenprüfung: ordinal mindestens zwei, binär genau zwei,
  jeweils verschieden, nicht fehlend und nicht leer. Die binäre Meldung
  behält „two distinct, non-missing labels“. Explizite binäre Labels
  bestimmen die Kodierung über `as.character()` bei allen Speichertypen;
  ohne Labels bleibt die exakte Prüfung auf 0/1. Die bestehende Warnung
  über entfernte Antworten bleibt auch vor dem Fehler bei fehlendem
  ordinalem `levels` erhalten. Ein vollständiger Zwischenlauf hatte
  diese Warnungsregression aufgedeckt; behoben wurde der Produktcode,
  nicht `test-fit-grr.R`. Neue Tests prüfen ungültige Labels sogar auf
  einem leeren Datenrahmen sowie numerische, logische, Zeichen- und
  Faktorwerte mit beiden Ereignisrichtungen. Belege: P0/P1/P2 und
  QA-M1b-005 in P4.

- **E17 / QA-M1b-006 — akzeptiert, im Produktcode behoben.**
  Ref: ADR-027 Nr. 5, ADR-026 Nr. 5, REVIEW E17.
  `inst/validation/sim/simulation_helpers.R` prüft in `sim_merge()` alle
  fünf Designzählungen gegen das Szenario, ihre gemeinsame Verfügbarkeit,
  logische Diagnoseflags und widerspruchsfreie Zustände ohne Fit.
  `inst/validation/latent/reference_checks.R` weist negative EmpSE/RMSE,
  Anteile außerhalb [0, 1] und Seeds außerhalb des positiven ganzzahligen
  R-Bereichs benannt ab. Der neue
  `tests/testthat/test-validation-latent-rework.R` prüft synthetische
  Verfälschungen jeder Designspalte und der Flags, die zulässigen
  Fehlerzustände sowie Grenzen von Kennzahlen und Seeds. Belege: P1/P2,
  QA-M1b-006 und die Kurzlauf-Reproduktion in P3. Die unveränderte
  Abnahmefixture mit `derived_share = 1.5` wird folgerichtig abgewiesen;
  dieser Konflikt ist OUT-OF-TERRITORY, kein Anlass zur Lockerung.

- **E18 — akzeptiert; ursprüngliche Vorlaufursachen behoben,
  vollständiges Gate weiterhin offen.**
  Ref: `gate-mutgate.log`, `reports/mutation/unmutated.json`, REVIEW E18.
  Die sechs ursprünglichen QA-Tests bestehen (P4), ebenso alle Unit-Tests
  in der Paketkopie (P2). Die acht neuen Testblöcke erkennen den alten
  Produktcode (P8). Ein vollständig grüner Vorlauf wird wegen der unten
  belegten geschützten Test-/Umgebungsfehler nicht behauptet. Es gibt
  weiterhin keinen Mutationsbericht und keine benennbaren überlebenden
  Mutanten; deshalb kein MUT-EQUIV-Antrag und keine Selbstfreigabe.
  Kein neuer Mutationsscore wird behauptet. Auswahl, Ausschlüsse,
  Schwellen und Ratchet bleiben Betreiber-Sache; der nächste reguläre
  Gate-Lauf entscheidet. Die Git-aufrufenden Gate-/Abnahmepfade wurden
  unter dem ausdrücklichen Git-Verbot nicht ausgeführt.

- **E19 — OUT-OF-TERRITORY [INFRA], Reviewer-Korrektur übernommen.**
  Ref: ADR-025 Nr. 4, REVIEW E19, BL-90.
  Der Reviewer hat das M2-Warnungsorakel und dessen Selbsttest bereits
  korrigiert. `R/acmg.R` bleibt byte-identisch. P5 führt K-M2-6 und
  K-M2-7 mit diesem unveränderten Orakel aus; der bekannte Socket-Fehler
  wird E22 zugeordnet. Kein Produkt-Scheinfix für das frühere Orakel.

- **E20 — akzeptiert, Dokumentation ergänzt.**
  Ref: ADR-027 Nr. 6, REVIEW E20, BL-91.
  `R/fit.R` und die daraus erzeugte `man/msa_fit.Rd` nennen ausdrücklich
  die Optimierertoleranz als Grenze der Invarianz gegenüber Zeilenfolge
  und Stufennamen. Vorgabe-Optimierer und Toleranzen bleiben unverändert.
  Die bestehenden Invarianztests mit expliziter Steuerung bestehen in
  P1/P2; direkte Engine-Gleichheit bleibt Gegenstand von P3.

- **E21 — akzeptiert, unverändert berichtet; Vollauswertung beim
  Betreiber/M1d.** Ref: K-M1b-2, K-M1d-7, REVIEW E21, BL-92.
  Auch der neu erzeugte ordinale Kurzlauf hat 18/80 nichtkonvergierte
  Wiederholungen mit endlichen Schätzern: 17 Iterationslimits und eine
  „singular convergence (7)“. Je Szenario: S-ord-1 1/20, S-ord-2 5/20,
  S-ord-3 2/20, S-ord-4 10/20. Schätzer und Diagnosen bleiben enthalten;
  kein Seed, Optimierer oder Konvergenzkriterium wurde passend gemacht.
  S-bin und S-two haben jeweils 0/40 nichtkonvergierte Wiederholungen.
  P7 und die drei `*_check_session.txt` belegen den aktuellen Stand.
  Vollläufe und deren Ergebnisdateien gehören zum Betreiber-Territorium.

- **E22 — OUT-OF-TERRITORY [INFRA], keine Produktänderung.**
  Ref: REVIEW E22, BL-86, PROGRESS M1B-INFRA-SOCKET/-CLOCK.
  P5/P6 halten das tatsächliche Verhalten der Builder-Sandbox fest.
  Weder HTTP-Replay noch Zeitprüfung werden abgeschaltet oder gelockert.
  Der Reviewer-Lauf und das lint-Gate aus Runde 1 bleiben die getrennt
  dokumentierten historischen Belege ihrer Umgebung.

- **E23 — OUT-OF-TERRITORY, nonblocking offen.**
  Ref: REVIEW E23, BL-93,
  `tests/acceptance/test-m1b-4-two-levels.R:41–42`.
  P3 zeigt erneut die beiden Deprecation-Warnungen des Abnahmehelfers
  zu `lme4::nobars()` und `lme4::findbars()`. Zuständig bleibt der
  Reviewer; weder Abnahmehelfer noch Paketabhängigkeiten wurden geändert.

## Zusätzlich belegte OUT-OF-TERRITORY-Ursachen

### M1B-R2-INFRA-FULL-FIXTURE — Reviewer-Territorium

Ref: ADR-027 Nr. 5.2 und
`tests/acceptance/test-m1b-7-vignette-full-results.R:18–23`.
Die Fixture addiert pauschal 0.5 auf jede Kennzahl. Beide gültigen
`derived_share`-Werte der Zwei-Stufen-Studie sind 1; daraus wird 1.5.
Die nach E17 vorgeschriebene Bereichsprüfung muss diese Datei abweisen.
P3 führt die Abnahmedatei unverändert mit aus; vier Blöcke enthalten
insgesamt fünf fehlgeschlagene Erwartungen. Die konkrete Ursache lautet:

```text
Invalid latent study result measure range: .../two_level_results.csv
```

Der separate reproduzierende Lauf steht in
`/tmp/llmsa-m1b-r2/full-fixture-probe.log`; das Einlesen der beiden
Originalzeilen und die unveränderte Fixture-Operation ergeben jeweils
`1 -> 1.5`. Zuständig ist der Reviewer für eine fachlich gültige
Fixture zur Prüfung des Dateivorrangs. Produktcode und Validator
erkennen keine Fixture und enthalten keinen Sonderfall.

### M1B-R2-INFRA-QA-NAMESPACE — QA-/Betreiber-Territorium

Ref: `tests/e2e/test-m1b-qa-e2e.R:152–187` und P4.
QA-M1b-004 lädt durch `testthat::test_file(load_package = "source")`
eine temporäre Paketkopie im laufenden R-Prozess. Danach löscht sein
`on.exit()` die Kopie, stellt aber den zuvor geladenen Namespace nicht
wieder her. Die vier nachfolgenden M2-E2E-Blöcke finden deshalb ein
Paketverzeichnis, das nicht mehr existiert. Der vollständige QA-Lauf
bleibt mit vier Fehlern rot, obwohl alle sechs M1b-QA-Befunde bestehen.
Die M2-E2E-Datei besteht separat in einem frischen R-Prozess (P4b).

Das Problem wurde zusätzlich mit dem unveränderten ursprünglichen
Produktcode und ohne den neuen Vignettenhelfer in einer temporären
Kopie reproduziert; es ist kein Seiteneffekt einer Reparatur am Produkt:

```text
Original staged test: failed expectations=1; error blocks=1
Namespace still points to staged package: TRUE
After unchanged QA cleanup: there is no package called ‘llmsa’
```

Befehl: `TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa
Rscript --vanilla /tmp/llmsa-m1b-r2/probe-qa-namespace.R`;
Output: `/tmp/llmsa-m1b-r2/qa-namespace-proof.log` (Exit 0, Defekt
reproduziert). Die QA muss den verschachtelten Pakettest isolieren oder
den tatsächlich zuvor geprüften Namespace wiederherstellen. Einfach
Produktcode aus `REPO_ROOT` nachzuladen wäre im Mutationslauf falsch.
Diese Zuständigkeit wird übergeben, nicht durch einen Builder-Hook
umgangen. BACKLOG und QA-Tests bleiben unverändert.

## Ausgeführte Prüfungen und echter Output

Arbeitsverzeichnis ist die Repo-Wurzel, soweit nicht anders genannt.
Belege, temporäre Paketkopien und Treiber liegen unter
`/tmp/llmsa-m1b-r2/`. Die folgenden Auszüge wurden aus diesen
Rohlogs gelesen. Die Suite-Aufrufe verwenden:

```text
TZ=Europe/Berlin NOT_CRAN=true REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa
Rscript --vanilla /tmp/llmsa-m1b-r2/run-suite.R <Verzeichnis> <Filter> <Label> <CSV>
```

Die beiden Zeilen sind ein Aufruf mit vorangestellten Umgebungsvariablen.
`run-suite.R` öffnet `pdf(NULL)`, setzt `testthat::set_max_fails(Inf)` und
ruft `testthat::test_dir(..., load_package = "source",
stop_on_failure = FALSE)` auf. Er schreibt die blockweisen Ergebnisse
als CSV und liefert Exit 1, sobald eine Erwartung fehlschlägt oder ein
Test abbricht. Es werden keine Erwartungen umgeschrieben; `max_fails`
verhindert lediglich den vorzeitigen Abbruch des Berichts.

### P0 — Warnungs- und Labelregression nach der letzten Codeänderung

Argumente: `tests/testthat '^fit-grr$|^fit-latent-rework$'
'Level-validation regressions' /tmp/llmsa-m1b-r2/levels-verified.csv`.
Output: `levels-verified.log`, Exit 0.

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 153 ]
Level-validation regressions: 12 tests; 0 failed blocks; 0 error blocks; 0 skipped; 11.58 seconds
```

### P1 — Vollständige Unit-Suite

Argumente: `tests/testthat '' 'Unit suite'
/tmp/llmsa-m1b-r2/unit-verified.csv`.
Output: `unit-verified.log`, Exit 0.

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3400 ]
Unit suite: 237 tests; 0 failed blocks; 0 error blocks; 1 skipped; 142.16 seconds
```

Der unveränderte Skip ist der ellmer-Negativtest bei installiertem ellmer.
Die beiden neuen Testdateien enthalten zusammen acht Blöcke und 179
Erwartungen: `test-fit-latent-rework.R` 120,
`test-validation-latent-rework.R` 59; jeweils null Fehlschläge/Fehler.
Der unveränderte `test-validation-latent.R` besteht mit sieben Blöcken
und 55 Erwartungen. Die numerischen Gegenrechnungen verwenden direkte
Engines, Formeln oder unabhängig ausgewählte Eingaben; es wurden keine
Schätzer-Ausgaben des Pakets als neue Referenz eingefroren.

### P2 — Vollständige Unit-Suite in einer Paketkopie ohne Vignetten

Neu angelegt wurde `/tmp/llmsa-m1b-r2/staged-package-verified` aus
DESCRIPTION, NAMESPACE, R, inst, data, tests/testthat und tests/fixtures;
vor dem Lauf existierte dort kein Verzeichnis `vignettes/`.
Arbeitsverzeichnis: diese Kopie. Argumente:
`tests/testthat '' 'Staged unmutated unit suite'
/tmp/llmsa-m1b-r2/staged-unit-verified.csv`.
`REPO_ROOT` zeigt weiterhin auf das Original; Output:
`staged-unit-verified.log`, Exit 0.

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3400 ]
Staged unmutated unit suite: 237 tests; 0 failed blocks; 0 error blocks; 1 skipped; 120.17 seconds
```

Der abschließende Hashvergleich bestätigt unveränderte Produkt- und
Testdateien der Kopie sowie die byte-identische Dokumentationsfixture.
Das ist ein Test der Paketkopie, kein ausgeführtes Mutationsgate.

### P3 — Vollständige M1b-Abnahme und M1a-Regression

Argumente: `tests/acceptance '^m1b-' 'M1b acceptance'
/tmp/llmsa-m1b-r2/m1b-verified.csv`.
Output: `m1b-verified.log`, Exit 1.

```text
[ FAIL 5 | WARN 2 | SKIP 0 | PASS 3270 ]
M1b acceptance: 74 tests; 4 failed blocks; 0 error blocks; 0 skipped; 229.75 seconds
```

Alle acht M1b-Dateien wurden ausgeführt, einschließlich der roten
Volllauf-Fixture. Rot sind ausschließlich ihre vier Blöcke (fünf
Erwartungen), wie unter M1B-R2-INFRA-FULL-FIXTURE beschrieben. Die zwei
Warnungen stammen ausschließlich aus dem geschützten Abnahmehelfer
(E23). Die übrigen sieben Dateien bestehen: K-M1b-1 34,
K-M1b-2 2155, K-M1b-3 687, K-M1b-4 37, K-M1b-5 9,
K-M1b-6 108 und die Kurzlauf-Vignette 240 Erwartungen.
K-M1b-2/-3 reproduzieren die erzeugten Kurzläufe byte-identisch.

Argumente: `tests/acceptance '^m1a-' 'M1a regression'
/tmp/llmsa-m1b-r2/m1a-verified.csv`.
Output: `m1a-verified.log`, Exit 0.

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a regression: 54 tests; 0 failed blocks; 0 error blocks; 0 skipped; 71.09 seconds
```

### P4 — Beide vollständigen QA-Verzeichnisse

```sh
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' tests/e2e tests/fuzz
```

Output: `qa-verified.log`, Exit 1.

```text
✔ |         14 | m1a-qa-e2e
✔ |         26 | m1b-qa-e2e [6.7s]
✖ | 4 4      0 | m2-qa-e2e
Error in `find.package(package)`: there is no package called 'llmsa'
[ FAIL 4 | WARN 4 | SKIP 0 | PASS 40 ]
✔ |          7 | m1a-qa-fuzz
✔ |         13 | m1b-qa-fuzz
✔ |          5 | m2-qa-fuzz
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: fail — 16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen
```

Die Fehlermeldungen nennen die bereits gelöschte
`qa-m1b-stage-.../DESCRIPTION`; siehe M1B-R2-INFRA-QA-NAMESPACE.

**P4b, frischer Prozess:** Argumente
`tests/e2e '^m2-qa-e2e$' 'Isolated M2 QA'
/tmp/llmsa-m1b-r2/m2-qa-isolated.csv`.
Output: `m2-qa-isolated.log`, Exit 0.

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
Isolated M2 QA: 4 tests; 0 failed blocks; 0 error blocks; 0 skipped; 5.74 seconds
```

### P5 — M2-Rückfallorakel und Robustheit

Argumente: `tests/acceptance '^m2-[67]-' 'M2 regression'
/tmp/llmsa-m1b-r2/m2-verified.csv`.
Output: `m2-verified.log`, Exit 1. Der Arbeitsbaum wurde während dieses
Laufs nicht verändert; insbesondere wurden die Handoffs erst danach
aktualisiert.

```text
✔ |        383 | m2-6-evaluate [313.0s]
✖ | 1      353 | m2-7-robustness-pilot [93.1s]
Error ('test-m2-7-robustness-pilot.R:175:5'):
Error: System failure for: socket() (Operation not permitted)
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 736 ]
M2 regression: 20 tests; 0 failed blocks; 1 error blocks; 0 skipped; 407.96 seconds
```

Der einzige Fehler entsteht über `setup-m2.R:787`,
`httr2::req_dry_run()` und `curl::curl_echo()` beim lokalen HTTP-Server.
Das ist der bereits dokumentierte Sandbox-Befund E22. Das korrigierte
Rückfallorakel von K-M2-6 samt Selbsttest besteht vollständig (E19);
kein Produktfehler wurde durch Änderung des Orakels oder Auslassen des
HTTP-Tests verdeckt.

### P6 — Paketbau und installierter Paketcheck

Ausgeführt mit `M1B_CHECK_WORK=/tmp/llmsa-m1b-r2/package-check-verified
python3 /tmp/llmsa-m1b-r2/check_package.py`. Der Treiber erzeugt eine
frische positive Paketkopie und ein SHA-256-Eingangsmanifest; er nimmt
keine Harness-Dateien oder API-Aufzeichnungen in das Paket auf.
`REPO_ROOT` und `NOT_CRAN` sind für den öffentlichen Paketkontext
entfernt. `_R_CHECK_CRAN_INCOMING_REMOTE_=false` entspricht dem
bestehenden Betreiber-Check. Die Systemzeitprüfung wurde nicht deaktiviert.

Ausgeführte R-Kommandos im temporären Paketverzeichnis:

```sh
R CMD build --no-manual src
R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Output: `package-check-verified-driver.log`, `package-check-verified/build.log`,
`package-check-verified/check.log` und `llmsa.Rcheck/00check.log`.
Beide R-Kommandos und der Treiber endeten mit Exit 0. Echter Output:

```text
build.log: exit=0; wall_seconds=62.043
check.log: exit=0; wall_seconds=185.002
* checking tests ...
  Running ‘testthat.R’ [74s/74s]
 [74s/74s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [34s/34s] OK
Status: 1 NOTE
Public package build and installed check completed.
```

Die einzige NOTE lautet `Unable to verify current time` (E22), keine
ERROR und keine WARNING. Der installierte Testlauf meldet:

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 3324 ]
```

Die neun unveränderten Skips betreffen fünf Tests mit nicht im Paket
enthaltenen API-Aufzeichnungen, zwei Originalanker-Vergleiche, den
Report-CRAN-Skip und den ellmer-Negativtest. Im vollständigen Quelllauf
P1/P2 bleibt nur der ellmer-Skip. Es wurden keine Skips ergänzt.

### P7 — Installation, echte Kurzläufe und Implementierungsnachweis

```sh
TZ=Europe/Berlin R CMD INSTALL --library=/tmp/llmsa-m1b-r2/library /tmp/llmsa-m1b-r2/install-source
M1B_SHORT_RUN=checks-verified python3 /tmp/llmsa-m1b-r2/generate_checks.py
```

Installation: `install-verified.log`, Exit 0, `* DONE (llmsa)`.
Der Generator verwendet das installierte Paket aus `library`, liest
`n_sim = 20` aus ANK-TOL.n_check und ruft aus einem fremden
Arbeitsverzeichnis jeweils das installierte Skript auf:

```text
Rscript --vanilla /tmp/llmsa-m1b-r2/library/llmsa/validation/sim/ordinal_recovery.R --n-sim 20 --out /tmp/llmsa-m1b-r2/checks-verified/ordinal_recovery
Rscript --vanilla /tmp/llmsa-m1b-r2/library/llmsa/validation/sim/binary_recovery.R --n-sim 20 --out /tmp/llmsa-m1b-r2/checks-verified/binary_recovery
Rscript --vanilla /tmp/llmsa-m1b-r2/library/llmsa/validation/sim/two_level.R --n-sim 20 --out /tmp/llmsa-m1b-r2/checks-verified/two_level
```

Output aus `generate-checks-verified.log`, alle drei Exit 0:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 104.210 s; workers 14
ordinal_recovery: exit=0; wall_seconds=104.966
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.879 s; workers 14
binary_recovery: exit=0; wall_seconds=1.523
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.795 s; workers 14
two_level: exit=0; wall_seconds=11.460
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle neun erzeugten Dateien wurden erst nach Erfolg aller Studien nach
`inst/validation/sim/*_check_*` kopiert. Die sechs Ergebnis-/Replikat-
CSVs sind zusätzlich byte-identisch zum Beginn der Runde; die drei
Sessiondateien enthalten den neuen Implementierungsnachweis und die
echten Laufdiagnosen. Es wurden keine Ergebniszahlen nachgetragen.

Ein separater R-Aufruf lädt die finalen Quellen mit
`pkgload::load_all(helpers = FALSE)`, sourced den Studienhelfer und
vergleicht dessen `sim_implementation()` mit allen drei Sessionköpfen.
Output `session-hashes-verified.log`, Exit 0:

```text
Current implementation: cc34f15d2cd96684043f688b41b85ab70ffefb2ba41044e161a7bf9c88c5c4a7
All three short-run sessions match current code.
```

### P8 — Neue Tests erkennen den ursprünglichen Produktcode

In `/tmp/llmsa-m1b-r2/baseline-package` wurden die beiden neuen
Testdateien unverändert gegen die zu Rundenbeginn gesicherten
`R/fit.R`, `R/grr.R` und die beiden ursprünglichen Studien-/Anzeigehelfer
mit `testthat::test_dir(load_package = "source")` ausgeführt.
Output aus `regression-before.log`, Exit 1:

```text
Original product: 8 new test blocks; 6 failed blocks; 6 error blocks; 0 skipped
```

Die Mengen der fehlgeschlagenen und abgebrochenen Blöcke überlappen;
ihre Vereinigung umfasst alle acht neuen Blöcke (`regression-before.csv`).
Mit dem finalen Produktcode bestehen genau diese acht Blöcke (P1/P2).
Das belegt die Regressionserkennung, nicht eine gemessene Mutationsquote.

## Abschließende Integritätsprüfung

Befehl: `python3 /tmp/llmsa-m1b-r2/verify_integrity.py`.
Output: `integrity-verified.log`, Exit 0:

```text
Baseline integrity: 303 files checked; 8 authorized changes; 0 unexpected changes.
Existing tests unchanged: 88 files, byte-identical.
Final tested inputs unchanged: 175 files.
Package build inputs match final tree: 141 files.
Staged product/tests match final tree; staged vignette matches original byte-for-byte.
All nine short-run files match generated outputs; six CSVs also match the round-start values.
No operator full-run results, replicates or sessions created.
New files in checked areas: 5, all assigned Builder artifacts.
```

Die acht geänderten Bestandsdateien sind `R/fit.R`, `man/msa_fit.Rd`,
die beiden Studien-/Anzeigehelfer, die drei Kurzlauf-Sessiondateien und
`PROGRESS.md`. Neu sind ausschließlich die beiden Regressionstestdateien,
der Vignetten-Fixture-Helfer, ADR-028 und dieses zugewiesene Handoff.
`R/grr.R`, `R/acmg.R`, DESCRIPTION, NAMESPACE, alle 88 bestehenden
Testdateien einschließlich Fixtures, Spezifikationen, Anker und die
gesicherten Gate-/Reviewer-Dateien bleiben byte-identisch. Der bisherige
Inhalt von PROGRESS wurde unverändert hinter den neuen Eintrag gestellt.
Die hier ergänzte Integritätsausgabe ändert keine getestete Eingabe.

Für die weitere Abnahme sind die geschützte Volllauf-Fixture und der
QA-Namespace-Lebenszyklus an die zuständigen Rollen übergeben; der
Socket-Test benötigt die Betreiberumgebung. E18 und die Bestätigung
aller Gate-Fakten bleiben beim nächsten regulären Gate-Lauf.
