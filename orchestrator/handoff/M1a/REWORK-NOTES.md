# M1a — REWORK, Runde 3

Rolle: Builder · Phase: `60-rework` · Stand: 30.10.2026.

## Grundlage

Maßgeblich sind REVIEW und verdict-code aus Runde 2, CRITERIA K-M1a-1
bis K-M1a-7, ADR-018/020/022, PLAN-UPDATE, AGENTS.md,
IMPLEMENTATION-RULES.md und contracts/PROTOCOLS.md. ARBITER.md liegt
nicht vor; LESSONS.md enthält keine Lehren. Die bisherigen M1a-Belege
bleiben in PROGRESS.md dokumentiert.

Die gelesenen Gate-Fakten nennen **Runde 2, result pass**, alle acht
Gates `pass`, keinen Status `error`. Es gibt kein fachlich rotes Gate
und keinen offenen `[QA-PENDING]`-Auftrag. REVIEW verlangt REWORK wegen
**E44**. Die Gate-Logs bestätigen unter anderem:

```text
gate-lint.log:88: r-check: pass — Status: OK
gate-mutgate.log:1306: mutgate: pass (score=93.79 required=80 baseline=93.79 floor=80)
gate-mutfull.log:2: mutfull: pass (nicht fällig in M1a)
```

Das sind historische Orchestrator-Fakten, keine Abnahme dieser Änderung.
Der Builder schreibt weder gates.json noch Verdict oder Approval.

## Antworten auf alle aktuellen Befund-IDs

- **E44 — behoben; Ref: ADR-022 Nr. 7, ADR-018 Nr. 3,
  PLAN-UPDATE „Randfälle“, E20 / QA-M1a-003.**
  `R/fit.R:460` prüft vor dem allgemeinen lme4-Startfit den
  Kleinste-Quadrate-Rest der konditionierten Antwort auf dem Spaltenraum
  des tatsächlich enthaltenen Zufalls-Intercept-Designs. Dieser Raum
  enthält den Intercept. Rangaufdeckende QR über `stats::lm.fit()`
  erlaubt abhängige Indikatorspalten und fehlende Zellen. Die vorhandene
  Prüfung `msa_numeric_check_residual()` und ihre Grenze
  `(64 * .Machine$double.eps)^2 * SST` bleiben unverändert.
  Es gibt keine künstliche Reststreuung und keine neue absolute Grenze.
  Die Vorprüfung diagnostiziert nur bei positiven Restfreiheitsgraden
  der Projektion: Ein gesättigter Spaltenraum bildet jeden Antwortvektor
  ab und erlaubt deshalb keinen Schluss auf die REML-Restvarianz.
  Solche Pläne behalten den allgemeinen REML-Pfad.
  Der unbalancierte Mehrfaktorfall endet damit vor lme4 benannt, ohne
  C++-/Matrix-Fehler oder Startwarnungen.

  Acht neue Unit-Blöcke in `tests/testthat/test-fit-residual-design.R`
  prüfen fehlende/entfernte Replikate, den 5×3-Plan mit Seed 7,
  Skalierungen, unvollständige Mehrfaktorpläne mit Modell und Block,
  Umbenennung/Umordnung sowie die positiven Gegenfälle ohne
  Wechselwirkung und bei gesättigter Projektion. `stats::aov` liefert unabhängig den Modellrest,
  direktes `lme4::lmer` die positiven Varianzkomponenten; Toleranzen
  stammen aus ANK-TOL. Der explizite Durchreichweg bleibt lme4 und wird
  auf demselben degenerierten Datensatz direkt mit der Engine verglichen.
  Nur der Diagnosewortlaut verwendet den bereits ausdrücklich als
  eigene Ausgabe gekennzeichneten Helper `rework_error()`.
  ADR-020, Nachtrag Runde 3, begründet Verfahren und Speicherbedarf;
  NEWS.md nennt die erweiterte Diagnose.

- **E45 — vorgeschlagene Dokumentationsoption umgesetzt;
  Ref: ADR-022 Nr. 1.3, REVIEW E45 / BL-82.**
  `R/fit.R:73` und die daraus erzeugte `man/msa_fit.Rd` erklären die
  eingebetteten Daten/Argumente, den großen gedruckten lme4-Aufruf und
  die kompakte Ausgabe des `msa_fit`-Objekts. Der gespeicherte Aufruf
  bleibt selbsttragend. Die Umstellung auf eine zusätzliche gespeicherte
  Datenumgebung ist nicht Bestandteil dieses Reworks. Die bestehenden
  Tests für Serialisierung, update, refit und Bootstrap laufen unverändert.

- **E46 — vorgeschlagene Dokumentationsoption umgesetzt;
  Ref: ADR-022 Nr. 1.1, REVIEW E46 / BL-83.**
  `R/fit.R:43` und `man/msa_fit.Rd` unterscheiden jetzt ausdrücklich
  die unmittelbare Aufruferumgebung für weitere Symbole in
  subset/weights/offset-Ausdrücken von den ursprünglichen
  Argumentumgebungen anderer weitergereichter Argumente. Wrapper müssen
  die benötigten Symbole in ihrem eigenen Frame bereitstellen. Keine
  Änderung der lme4-Datenmasken-Semantik.

- **E47 — teilweise zusätzliche Abdeckung; Ref: mutgate, REVIEW E47 / BL-84.**
  Die neue Unit-Datei prüft einen dünn besetzten Plan mit weniger
  Beobachtungen als möglichen Zellen gegen lme4 sowie positives,
  verschwindend kleines profiliertes Q gegen die unabhängige Formel
  `Q = 4 / (1 + 4 * lambda)` für ein Rang-eins-Kovarianzmodell.
  Vier konkret benannte Überlebende des unveränderten Berichts der
  Runde 2 werden dadurch in einer lokalen Diagnose erkannt (unten).
  Dafür wurde kein Produktcode geändert. Die übrigen in E47 genannten
  Lücken zur getrennten Darstellbarkeit einzelner Komponenten und zu
  den beiden Rückskalierungsprüfungen bleiben nonblocking offen: Sie
  benötigen eigene konstruierte Komponentenfälle und betreffen nicht
  die Modellraumprüfung aus E44. Die bisherigen Präzisionstests bleiben
  aktiv und unverändert. BL-84 ist daher nicht als vollständig erledigt
  gemeldet; BACKLOG-Pflege bleibt beim Reviewer.

- **E48 — OUT-OF-TERRITORY [INFRA]; Ref: REVIEW E48 / BL-85,
  `orchestrator/gates.d/86-mutgate.sh:38–41`.**
  Die Approval-Zuordnung prüft weiterhin Dateiende, Mutator und Zeile,
  keinen Quelltext oder Hash. `gate-mutgate.log:1306–1309` nennt den
  Score der Runde 2 und ihren Bericht `reports/mutation/mutation.json`.
  Dessen Quellzeilen gleichen dem gesicherten Ausgangscode dieser
  Runde (nur der abschließende Zeilenumbruch fehlt im Bericht).
  Sieben Claims für unveränderte R/fit.R-Zeilen wurden in der zugewiesenen
  `MUT-EQUIV.json` auf die neuen Zeilen versetzt und erneut beantragt;
  der achte Claim für R/grr.R:94 bleibt gleich. Die alte
  `MUT-EQUIV-APPROVED.json` bleibt unangetastet. Neue Zuordnung und
  Entfernung veralteter Approvals bleiben Reviewer-/Betreiberarbeit.

- **E49 — OUT-OF-TERRITORY [INFRA]; Ref: REVIEW E49 / BL-86.**
  Der aktuelle mirai-Probeaufruf endet erneut mit `16 | Permission denied`.
  Der öffentliche Paketcheck meldet erneut `Unable to verify current time`.
  Die vollständigen aktuellen Logs und Befehle stehen unten. Der
  historische Gate-Lauf hatte dagegen `gate-lint.log:37` Zeitprüfung OK
  und `gate-lint.log:86` Status OK. Keine Sandbox-, Zeitprüfungs-,
  Dispatcher- oder Gateänderung und kein Produkt-Scheinfix.

Fortgeschriebene ältere Befunde: E18/E19/E21–E38/E40 gelten nach REVIEW
Runde 2 als erledigt; E20 wird durch E44 vervollständigt. E39/BL-77
(QA-Zitate), E41/BL-79 (Berichtsarchivierung) und E42/BL-80 (Spec-Tippfehler)
bleiben OUT-OF-TERRITORY bei Betreiber/Reviewer. Anders als in Runde 1
liegt der Mutationsbericht jetzt vor. E43/BL-81 bleibt gemäß ADR-022
dem Meilenstein M1b zugeordnet.

## Ausgeführte Prüfungen

Alle aktuellen Diagnoseartefakte liegen unter `/tmp/llmsa-m1a-r3/`.
Keine folgenden Befehle schreiben Gatezustand oder führen Git aus.

### Regression: alter und korrigierter Produktcode

Der gesicherte Ausgangscode `baseline/R/fit.R` hat SHA-256
`a8252955a2e97ab4c48d9a60952dc136a036aac6600387080bc1a9515580484c`.
Der neue Code hat SHA-256
`6ab0a2a57cbc269c15f17fc0a9f6e397845082d92d28930189f017cfb386cf49`.

Der erste Vorversuch, `Rscript --vanilla /tmp/llmsa-m1a-r3/probe-residual.R`,
reproduziert E44 mit dem alten Code; echter Output in `probe-residual.log`:

```text
qa_missing interactions=TRUE; projection RSS/SST=7.0960501e-33; aov RSS/SST=4.8489676e-32; Rcpp::exception: Downdated VtV is not positive definite
qa_missing interactions=FALSE; projection RSS/SST=0.7984535; aov RSS/SST=0.7984535; method=analytic_reml; residual=2.591429
```

Für die endgültige Gegenprobe enthält
`/tmp/llmsa-m1a-r3/regression-baseline/src` eine Paketkopie mit der alten
R/fit.R und exakt den endgültigen neuen Tests. Darin ausgeführt:

```bash
Rscript --vanilla -e 'x <- testthat::test_dir("tests/testthat", filter = "fit-residual-design", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); print(d[, c("test", "failed", "error", "warning", "passed")], row.names = FALSE); cat(sprintf("Baseline regression: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`regression-baseline-final.log`, erwartet Exit 1:

```text
Baseline regression: 8 tests; 3 failed blocks; 0 errors; 0 skipped
```

Der aktuelle Quellbaum wurde für diese Gegenprobe nicht zurückgesetzt.
Auf dem korrigierten Code, aus der Repo-Wurzel:

```bash
Rscript --vanilla -e 'testthat::test_dir("tests/testthat", filter = "fit-residual-design", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

`regression-final-rank.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 124 ]
```

Die gesonderte Gegenprüfung `rank-counterexample-before.log` machte die
zunächst unbedingte neue Projektion auf einem gesättigten Design rot:
`[ FAIL 1 | WARN 0 | SKIP 0 | PASS 119 ]`, Exit 1. Der endgültige achte
Test verlangt deshalb neben der aov-Rangprüfung die positive REML-
Restvarianz gegen direktes lme4 und unabhängig `SST / (N - 1)` an der
Randlösung beider Zufallskomponenten null. Die Einschränkung auf positive
Projektions-Restfreiheitsgrade behebt diesen Gegenbefund; keine Toleranz
oder vorhandene Erwartung wurde gelockert.

### Unit- und unveränderte QA-Tests

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

`unit-qa.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2601 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 191 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 78.44; exit: 0
```

Der einzige Skip ist der unveränderte ellmer-Negativtest, weil ellmer
installiert ist (`test-backends.R:32`). Es wurde kein Skip hinzugefügt.

### Unveränderte M1a-Abnahme

```bash
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa \
  /usr/bin/time -f 'M1a acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(NULL); x <- testthat::test_dir("tests/acceptance", filter = "m1a-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); cat(sprintf("M1a acceptance: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`acceptance.log`, Exit 0, einschließlich Originalanker, geschützter
AIAG-Daten, NIST, Orakel und geknitteter Vignette:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.72; exit: 0
```

Die vollständige M0/M2-Abnahme und reguläre Gates verbleiben beim
Orchestrator. Git-verwendende M0-Prüfwege wurden nicht ausgeführt.

### Öffentlicher Paketbau und installierter Paketcheck

Eine Positivliste kopiert R/, man/, inst/, data/, vignettes/, tests/testthat/,
tests/testthat.R, DESCRIPTION, NAMESPACE, LICENSE und NEWS.md nach
`/tmp/llmsa-m1a-r3/package-check/src`. Keine Schlüssel, Betreiber-Fixtures
oder Harness-Dateien werden kopiert. Roxygen lief nur in dieser Kopie;
nur die erzeugte `man/msa_fit.Rd` wurde übernommen, fremde generierte
Änderungen in der Kopie auf die Originaldateien zurückgesetzt.

In `/tmp/llmsa-m1a-r3/package-check` ausgeführt:

```bash
Rscript --vanilla -e 'roxygen2::roxygenise("src", roclets = "rd")'
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Build und Check jeweils Exit 0; `build.log`, `check.log` und
`llmsa.Rcheck/tests/testthat.Rout`:

```text
* creating vignettes ... OK
* checking R code for possible problems ... OK
* checking re-building of vignette outputs ... [26s/26s] OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 121.91; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2526 ]
```

Acht bestehende Standalone-Skips: fünf Betreiber-Aufzeichnungen fehlen
im öffentlichen Tarball, einmal On CRAN im generischen Bericht,
einmal der Vergleich mit Originalankern ohne Repository und einmal
ellmer. Der Quellbaum-Lauf führt diese Prüfungen bis auf den
ellmer-Negativtest tatsächlich aus; alle neuen Tests laufen in beiden
Kontexten. Keine ERRORs oder WARNINGs.

**M1a-R3-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA], E49.**
Der einzige NOTE, `package-check/check.log:29–31`, lautet:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Zeitprüfung bleibt aktiv. Die Incoming-Remote-Einstellung entspricht
`orchestrator/lib/r-check.sh`; keine weitere Prüfregel wurde abgeschaltet.

### Lokale Mutationsdiagnose zu E47, kein Gate-Ersatz

```bash
python3 /tmp/llmsa-m1a-r3/check-selected-mutations.py
```

`selected-mutations.log`, Exit 0 des Treibers; jeder absichtlich
mutierte Testlauf endet erwartet mit Exit 1:

```text
336:40:^ → * -> current line 343: 8 tests; 1 failed blocks; 0 errors; 0 skipped; exit 1
336:41:<n> - 1 → <n> - 1 -> current line 343: 8 tests; 1 failed blocks; 0 errors; 0 skipped; exit 1
336:41:<n> + 1 → <n> + 1 -> current line 343: 8 tests; 1 failed blocks; 0 errors; 0 skipped; exit 1
254:39:NULL → NA -> current line 261: 8 tests; 0 failed blocks; 2 errors; 0 skipped; exit 1
Four selected survivors detected by the new tests; diagnostic only, no gate score or approval.
```

Der Treiber liest die vier konkreten Ersetzungen samt Spaltenposition
aus dem vorhandenen Gate-Bericht, prüft die ursprünglichen Quellzeilen,
ordnet sie den identischen aktuellen Zeilen zu und verändert ausschließlich
eine temporäre Paketkopie. Geprüft wird nur die neue Testdatei. Kein
vollständiger Mutationsscore, keine Änderung des Berichts und keine Approval.

Die erneut beantragten acht Äquivalenzen betreffen unveränderten Code:

| Datei | alte Zeile → neue Zeile | Mutator |
| --- | --- | --- |
| R/fit.R | 222 → 229 | + → - |
| R/fit.R | 102 → 109 | FALSE → TRUE |
| R/fit.R | 341 → 348 | numerischer Initialwert +1 |
| R/fit.R | 341 → 348 | numerischer Initialwert −1 |
| R/fit.R | 442 → 449 | TRUE → FALSE |
| R/fit.R | 444 → 451 | TRUE → FALSE |
| R/fit.R | 450 → 457 | TRUE → FALSE |
| R/grr.R | 94 → 94 | > → >= |

**M1a-R3-INFRA-MUT-DISPATCH — OUT-OF-TERRITORY [INFRA], E49.**

```bash
timeout 20 Rscript --vanilla -e 'mirai::daemons(1L)'
```

`mirai-probe.log`, Exit 1, kein Timeout:

```text
Error in .dispatcher_start(url, urld, tls_cfg, serial, envir[["stream"]],  :
  16 | Permission denied
Calls: <Anonymous> -> launch_dispatcher -> .dispatcher_start
Execution halted
```

Der reguläre Mutationslauf bleibt beim Orchestrator; die gezielte
Diagnose beansprucht keine Gate-Wirkung.

### Wirkung auf positive Fits und Laufzeit

```bash
Rscript --vanilla /tmp/llmsa-m1a-r3/compare-positive-fits.R
```

`positive-fits.log`, Exit 0:

```text
Positive designs: 6; components and numerical diagnostics byte-identical as R objects; max difference 0
ic50_demo, five alternating timings after warmup: before median 0.4890 s [0.4870, 0.5180]; after median 0.5640 s [0.5420, 0.6760]; ratio 1.153
ic50_demo projection design: 2152 observations by 297 columns; dense payload 4.88 MiB
```

Verglichen wurden ic50_demo, vier unbalancierte synthetische
Mehrfaktorpläne mit Seeds 1–4 und der gesättigte Sechszeilenplan mit Seed 1
gegen den gesicherten Ausgangscode.
Die Laufzeit ist eine lokale Messung, kein neues Gatebudget. Zusätzlicher
Speicherbedarf ist N × q für das Design; keine N × N-Kovarianzmatrix.

## Integrität und Übergabe

```bash
python3 /tmp/llmsa-m1a-r3/integrity.py
```

`integrity.log`, Exit 0:

```text
Inventory: 289 baseline files; 7 allowed changed files; 282 byte-identical; no removed files; 1 allowed new file
Changed: NEWS.md, PROGRESS.md, R/fit.R, docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md, man/msa_fit.Rd, orchestrator/handoff/M1a/MUT-EQUIV.json, orchestrator/handoff/M1a/REWORK-NOTES.md
New: tests/testthat/test-fit-residual-design.R
All 67 existing test and fixture files remain byte-identical
Checked package copy: final source, Rd and new tests match the workspace
No root-level Rplots.pdf, package archive or Rcheck directory
Gate facts remain round 2, result pass; reviewer approvals remain byte-identical
Eight equivalence claims refer to unchanged source lines; no approval written
Modified R source and new test are ASCII
```

Die Inventur umfasst die vorab gesicherten Produkt-, Test-, Vertrags-,
Spec-, Anker- und M1a-Handoff-/Gate-Dateien. Sie ersetzt nicht das
Territoriums-Gate. R/grr.R, NAMESPACE, DESCRIPTION, bestehende Tests,
Abnahmetests, QA-Tests, Fixtures, Anker, Golden-Daten, Specs, Gates,
Schwellen und Reviewer-Approvals sind unverändert.

Keine Git-Kommandos, keine Abhängigkeitsinstallation und keine eigenen
API-Aufrufe. Keine Änderung an Orchestratorzustand oder BACKLOG.
Territoriumsprüfung, Phasen-Commit, vollständige Gates und Review
verbleiben bei den zuständigen Rollen. E48/E49 und der Rest von E47
werden mit ihren oben dokumentierten Zuständigkeiten übergeben.
