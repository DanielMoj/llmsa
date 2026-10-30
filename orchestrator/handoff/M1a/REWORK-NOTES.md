# M1a — REWORK, Runde 4

Rolle: Builder · Phase: `60-rework` · Stand: 30.10.2026.

## Grundlage

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
Handoff-Schema, REVIEW/verdict-code Runde 3, CRITERIA K-M1a-1 bis K-M1a-7,
die zugehörigen Specs und Abnahmetests, PROGRESS sowie ADR-018/020/022.
ARBITER.md liegt nicht vor; LESSONS.md enthält keine Lehren.

Die vorliegenden Orchestrator-Fakten stammen aus **Runde 3**:
alle acht Gates `pass`, `result: pass`, kein `error`, kein fachlich rotes
Gate und kein `[QA-PENDING]`. Die Log-Belege lauten:

```text
orchestrator/state/M1a/gate-lint.log:86:Status: OK
orchestrator/state/M1a/gate-tests.log:553:r-tests: pass — 322 Tests in tests/testthat, tests/acceptance, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
orchestrator/state/M1a/gate-mutgate.log:1321:mutgate: pass (score=93.72 required=91.79 baseline=93.79 floor=80)
orchestrator/state/M1a/gate-mutfull.log:2:mutfull: pass (nicht fällig in M1a)
```

REVIEW verlangt REWORK wegen E50. Die historischen Gate-Fakten sind keine
Abnahme dieser Änderung und wurden nicht verändert.

## Antworten auf alle aktuellen Befund-IDs

- **E50 — behoben; Ref: ADR-018 Nr. 3, docs/01 §2 Nr. 4,
  PLAN-UPDATE „Randfälle“, REVIEW Runde 3 E50.**
  `R/fit.R:471` behandelt Fehler genau am lme4-Startaufruf auf der
  konditionierten Antwort. Der Fehler beginnt mit
  `Numeric model initialization failed: ` und erhält die ursprüngliche
  Engine-Meldung als Ursache. Die äußere Klasse ist `simpleError`, ohne
  internen Aufruf. Damit bleibt auch eine andere Startursache erkennbar;
  positive Reststreuung wird nicht pauschal als null bezeichnet.
  Der bestehende `on.exit`-Handler gibt bereits gesammelte Startwarnungen
  weiterhin vollständig und in ihrer Reihenfolge aus.

  Die neue Datei `tests/testthat/test-fit-initialization.R` enthält sechs
  Testblöcke: die drei realen Reproduktionen aus E50, einen synthetischen
  Startfehler mit zwei Warnungen, den Vergleich des expliziten
  Durchreichwegs mit lme4 sowie positive Gegenfälle gegen lme4 bei
  ursprünglicher und mit `1e-100` skalierter Antwort. `stats::aov` belegt
  die positive Restquadratsumme unabhängig. Numerische Toleranzen kommen
  aus ANK-TOL; nur der Diagnosepräfix ist als eigene Ausgabe markiert.
  Vor der Korrektur erkennen die Tests neun falsche Erwartungen in vier
  Blöcken; danach bestehen alle 79 Erwartungen. Kein Rückfall auf einen
  Startwert, keine künstliche Streuung und keine geänderte Numerikgrenze.
  Die expliziten lme4-Argumente behalten die originalen Bedingungen.
  ADR-020, Nachtrag Runde 4, `?msa_fit` und NEWS.md dokumentieren das Verhalten.

- **E51 — Dokumentationsoption umgesetzt; numerische Verbesserung bleibt
  nonblocking offen (BL-87); Ref: REVIEW E51, ADR-018 Nr. 3/5.**
  `R/fit.R:82` und die erzeugte `man/msa_fit.Rd` sagen ausdrücklich,
  dass positive, darstellbare Restvarianz bei hoher Wiederholpräzision
  keinen erfolgreichen Start oder analytischen Abschluss garantiert.
  ADR-020 nennt den weiter offenen Robustheitsnachweis für Restanteile
  `1e-4` und `1e-6` vor M1d. Es wird keine Verbesserung der Konvergenz
  behauptet; das Abbruchkriterium wurde nicht geändert. Die neue
  Fehlerbehandlung sichert den benannten Abbruch aus E50 ab.

- **E52 — vorgeschlagene Dokumentationsoption umgesetzt;
  Ref: REVIEW E52 / BL-88, IMPLEMENTATION-RULES „Hot Paths“.**
  ADR-020, Nachtrag Runde 4, nennt O(Nq) Speicher, O(Nq²) Arbeit und
  die wiederholten Kosten in `msa_plan()`. Die dort zitierten größeren
  Messfälle sind ausdrücklich die Messungen des Reviewers aus REVIEW
  Runde 3, Nachprüfung 7. Die Projektion bleibt unverändert; die sparsame
  Umsetzung oder spätere Ausführung bleibt eine getrennte Optimierung.
  Es wird kein neuer Laufzeit- oder Budgetnachweis behauptet.

- **E53 — zwei Äquivalenzen beantragt; übrige Punkte nonblocking offen
  (BL-84); Ref: REVIEW E53, mutgate Runde 3.**
  Die beiden Überlebenden `counts[1]` → `counts[2]` beziehungsweise
  `counts[1 + 1L]` sind in MUT-EQUIV.json auf der aktuellen Zeile 267
  beantragt. Im gültigen Produktpfad hat `item` mindestens zwei beobachtete
  Stufen, also hat der Zählvektor mindestens zwei positive endliche Einträge.
  Gleichheit aller Einträge mit einem ausgewählten Eintrag ist unabhängig
  von dessen Index. Der ausgeführte Beleg prüft beide Prädikate für alle
  9837 Vektoren der Längen 2–8 mit Einträgen 1–3 und beide mutierten
  Funktionen auf vier gültigen Plänen exakt.

  Die übrigen Darstellbarkeitsfälle und die als redundant beschriebenen
  frühen Restprüfungen bleiben offen. E53 bezeichnet sie ausdrücklich als
  nicht verlangt; das mutgate ist grün. Diese Runde konzentriert den
  Produktfix auf den belegten Startabbruch und verändert keine dieser
  früheren Prüfungen. Es wird weder vollständige Mutationsabdeckung noch
  ein neuer Score behauptet.

- **E48 — OUT-OF-TERRITORY [INFRA]; Ref: REVIEW Runde 3,
  „Stand der Einwände“ / BL-85; `orchestrator/gates.d/86-mutgate.sh`.**
  Die bestehende Approval-Zuordnung bleibt Betreiber-Territorium.
  Sieben R/fit.R-Claims wurden anhand identischer Quellzeilen auf die
  neuen Positionen versetzt und erneut beantragt; R/grr.R bleibt gleich.
  Beleg: unveränderter Bericht `reports/mutation/mutation.json`,
  `gate-mutgate.log:1321` oben, Quellabgleich und Integritätsprüfung unten.
  MUT-EQUIV.json enthält jetzt zehn Claims; die acht Reviewer-Approvals
  der Runde 3 wurden nicht geändert. Die neue Bindung entscheidet der Reviewer.

- **E49 — OUT-OF-TERRITORY [INFRA]; Ref: REVIEW Runde 3,
  „Stand der Einwände“ / BL-86.**
  Die lokale mirai-Probe endet erneut mit `16 | Permission denied`.
  Der öffentliche Paketcheck meldet die nicht überprüfbare Uhrzeit.
  Die tatsächlichen Logs und Befehle stehen unten. Keine Änderung an
  Dispatcher, Sandbox, Zeitprüfung, Gates oder Schwellen.

Fortgeschriebene Zuständigkeiten: E44–E46 sind laut REVIEW Runde 3 erledigt;
E47 geht in E53/BL-84 auf. E39/BL-77 (QA-Zitate), E41/BL-79
(Berichtsarchivierung) und E42/BL-80 (Spec-Tippfehler) bleiben nach dem
Stand im REVIEW OUT-OF-TERRITORY beim Betreiber/Reviewer; E43/BL-81 ist
gemäß ADR-022 nach M1b vertagt. BACKLOG wurde nicht geändert.

## Ausgeführte Prüfungen

Diagnoseartefakte: `/tmp/llmsa-m1a-r4/`. Alle folgenden Befehle wurden
ausgeführt; kein Prüfweg schreibt Gatezustand oder führt Git aus.

### E50 vor und nach der Produktkorrektur

Der gesicherte Ausgangscode `baseline/R/fit.R` hat SHA-256
`6ab0a2a57cbc269c15f17fc0a9f6e397845082d92d28930189f017cfb386cf49`.
Der endgültige Code hat SHA-256
`73caf9801081da31ef01ab26c3e026c44c34f4060804329b7f63e84e902ebd94`.

```bash
Rscript --vanilla /tmp/llmsa-m1a-r4/probe-start.R
```

Vorher und nachher jeweils Exit 0 des Diagnosetreibers. `probe-before.log`:

```text
removed: n=44; seed=1001; noise=1e-08; aov RSS/SST=6.43274619e-17; class=Rcpp::exception/C++Error/error/condition; warnings=0; Downdated VtV is not positive definite
missing: n=15; seed=1003; noise=1e-08; aov RSS/SST=1.04153353e-17; class=Rcpp::exception/C++Error/error/condition; warnings=0; Downdated VtV is not positive definite
balanced: n=16; seed=1001; noise=1e-09; aov RSS/SST=3.84207579e-19; class=Rcpp::exception/C++Error/error/condition; warnings=0; Downdated VtV is not positive definite
Unchanged ADR-020 relative zero bound: 2.01948392e-28
```

`probe-after.log`:

```text
removed: n=44; seed=1001; noise=1e-08; aov RSS/SST=6.43274619e-17; class=simpleError/error/condition; warnings=0; Numeric model initialization failed: Downdated VtV is not positive definite
missing: n=15; seed=1003; noise=1e-08; aov RSS/SST=1.04153353e-17; class=simpleError/error/condition; warnings=0; Numeric model initialization failed: Downdated VtV is not positive definite
balanced: n=16; seed=1001; noise=1e-09; aov RSS/SST=3.84207579e-19; class=simpleError/error/condition; warnings=0; Numeric model initialization failed: Downdated VtV is not positive definite
Unchanged ADR-020 relative zero bound: 2.01948392e-28
```

Die neue Testdatei wurde vor und nach der Korrektur unverändert ausgeführt:

```bash
Rscript --vanilla -e 'x <- testthat::test_dir("tests/testthat", filter = "^fit-initialization$", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); cat(sprintf("Initialization regression: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`regression-before.log`, erwarteter Exit 1; danach `regression-after.log`, Exit 0:

```text
[ FAIL 9 | WARN 0 | SKIP 0 | PASS 70 ]
Initialization regression: 6 tests; 4 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 79 ]
Initialization regression: 6 tests; 0 failed blocks; 0 errors; 0 skipped
```

### Unit-, QA- und M1a-Abnahme

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' tests/testthat tests/e2e tests/fuzz
```

`unit-qa.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2680 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 197 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 85.75; exit: 0
```

Der einzige Skip ist der unveränderte ellmer-Negativtest
(`test-backends.R:32`, ellmer ist installiert). Alle bestehenden Tests,
einschließlich der positiven Gegenfälle und Warnungsprüfungen früherer
Runden, sind unverändert enthalten.

```bash
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa /usr/bin/time -f 'M1a acceptance elapsed seconds: %e; exit: %x' Rscript --vanilla -e 'grDevices::pdf(NULL); x <- testthat::test_dir("tests/acceptance", filter = "^m1a-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); cat(sprintf("M1a acceptance: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`acceptance.log`, Exit 0, einschließlich der Originalanker, geschützten
AIAG-Daten, NIST, Paketorakel und geknitteten Vignette:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.65; exit: 0
```

Die vollständigen M0/M2-Abnahmen und regulären Gates bleiben beim
Orchestrator. Git-verwendende Prüfwege wurden nicht ausgeführt.

### Öffentlicher Paketbau und installierter Check

Eine Positivliste kopiert R/, man/, inst/, data/, vignettes/, tests/testthat/,
tests/testthat.R, DESCRIPTION, NAMESPACE, LICENSE, NEWS.md, README.md und
.Rbuildignore nach `/tmp/llmsa-m1a-r4/package-check/src`.
Geschützte Referenzen, API-Fixtures, Harness und Schlüssel sind nicht enthalten.
Roxygen lief ausschließlich dort; nur `man/msa_fit.Rd` wurde übernommen,
weitere generierte Änderungen in der Kopie auf den Originalstand zurückgesetzt.

In `/tmp/llmsa-m1a-r4/package-check` ausgeführt:

```bash
Rscript --vanilla -e 'roxygen2::roxygenise("src", roclets = "rd")'
env -u REPO_ROOT R CMD build --no-manual src
env -u REPO_ROOT _R_CHECK_CRAN_INCOMING_REMOTE_=false /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Roxygen, Build und Check jeweils Exit 0. Echter Output aus
`package-check/build.log`, `package-check/check.log` und
`package-check/llmsa.Rcheck/tests/testthat.Rout`:

```text
* creating vignettes ... OK
* checking R code for possible problems ... OK
* checking re-building of vignette outputs ... [28s/28s] OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 129.93; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2605 ]
```

Keine ERRORs oder WARNINGs. Die acht bestehenden Standalone-Skips sind
fünf fehlende Betreiber-Aufzeichnungen im öffentlichen Tarball, der
CRAN-Report-Test, der Originalanker-Vergleich ohne Repository und der
ellmer-Negativtest. Alle neuen Tests werden auch installiert ausgeführt.

**M1a-R4-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA], E49.**
`package-check/check.log:29–31`:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Zeitprüfung bleibt aktiv. Die Incoming-Remote-Einstellung entspricht
dem unveränderten Betreiber-Prüfweg `orchestrator/lib/r-check.sh`.

### Mutationsclaims und lokale Infrastruktur

```bash
Rscript --vanilla /tmp/llmsa-m1a-r4/counts-equivalence.R
```

`counts-equivalence.log`, Exit 0:

```text
Count-vector enumeration: 9837 vectors, lengths 2..8, entries 1..3; both predicates identical
Balanced helper: 4 valid designs x 2 index mutations; outputs and warnings exactly identical
Equivalence evidence only; no mutation score or approval.
```

Erneute Anträge für unveränderte Quellzeilen:

| Datei | Zeile Runde 3 → Runde 4 | Mutator |
| --- | --- | --- |
| R/fit.R | 229 → 233 | + → - |
| R/fit.R | 109 → 113 | FALSE → TRUE |
| R/fit.R | 348 → 352 | numerischer Initialwert +1 |
| R/fit.R | 348 → 352 | numerischer Initialwert −1 |
| R/fit.R | 449 → 453 | TRUE → FALSE |
| R/fit.R | 451 → 455 | TRUE → FALSE |
| R/fit.R | 457 → 461 | TRUE → FALSE |
| R/grr.R | 94 → 94 | > → >= |

Hinzu kommen die zwei separat begründeten E53-Anträge für R/fit.R:267
(bisher 263). Alle zehn Claims sind Anträge, keine Genehmigungen.
Es wurde kein neuer Mutationslauf oder Score erzeugt; der vorliegende
Gate-Bericht und MUT-EQUIV-APPROVED.json bleiben bytegleich.

**M1a-R4-INFRA-MUT-DISPATCH — OUT-OF-TERRITORY [INFRA], E49.**

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

### Integrität und Übergabe

```bash
python3 /tmp/llmsa-m1a-r4/integrity.py
```

`integrity.log`, Exit 0:

```text
Inventory: 295 baseline files; 7 allowed changed files; 288 byte-identical; no removed files; 1 allowed new file
Changed: NEWS.md, PROGRESS.md, R/fit.R, docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md, man/msa_fit.Rd, orchestrator/handoff/M1a/MUT-EQUIV.json, orchestrator/handoff/M1a/REWORK-NOTES.md
New: tests/testthat/test-fit-initialization.R
All 68 existing test and fixture files remain byte-identical
Checked package copy: all 109 public source files match the workspace
No root-level Rplots.pdf, package archive or Rcheck directory
Gate facts remain round 3, result pass; reviewer approvals remain byte-identical
Eight existing equivalence claims mapped to unchanged source; two new index claims; no approval written
R/fit.R SHA-256: 73caf9801081da31ef01ab26c3e026c44c34f4060804329b7f63e84e902ebd94
Modified R source and new test are ASCII
```

Keine bestehenden Tests, Abnahmetests, QA-Tests, Fixtures, Anker,
Golden-Daten, Specs, Gates, Schwellen oder Reviewer-Approvals geändert.
Keine Git-Kommandos, Abhängigkeitsinstallation oder eigenen API-Aufrufe.
Orchestratorzustand und BACKLOG bleiben unverändert. Die Inventur ersetzt
nicht das Territoriums-Gate. Territoriumsprüfung, Phasen-Commit,
vollständige Gates und Code-Review verbleiben bei den zuständigen Rollen.
