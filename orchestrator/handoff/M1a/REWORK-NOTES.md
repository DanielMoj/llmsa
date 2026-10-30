# M1a — REWORK, Runde 5

Rolle: Builder · Phase: `60-rework` · Stand: 30.10.2026.

## Grundlage

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
Handoff-Schema, REVIEW/verdict-code Runde 4, CRITERIA K-M1a-1 bis K-M1a-7
einschließlich ACC-Hinweisen, zugehörige Specs, Formelsammlung §2,
Abnahmetests und deren Helfer, PROGRESS sowie ADR-018/020/022.
ARBITER.md fehlt; LESSONS.md enthält keine Lehren.

Die vorliegenden Orchestrator-Fakten stammen aus **Runde 4**:
acht Gates `pass`, `result: pass`, kein Status `error`, kein fachlich
rotes Gate und kein aktueller `[QA-PENDING]`-Befund. Log-Belege:

```text
orchestrator/state/M1a/gate-lint.log:86:Status: OK
orchestrator/state/M1a/gate-tests.log:574:r-tests: pass — 328 Tests in tests/testthat, tests/acceptance, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
orchestrator/state/M1a/gate-mutgate.log:1323:mutgate: pass (score=93.74 required=91.79 baseline=93.79 floor=80)
orchestrator/state/M1a/gate-mutfull.log:2:mutfull: pass (nicht fällig in M1a)
```

Das REWORK-Verdict trägt den blocking-Befund E54. Die folgenden
Builder-Prüfbelege ändern weder diese historischen Gate-Fakten noch
das Reviewer-Verdict.

## Antworten auf die aktuellen Befund-IDs

- **E54 — im Produktcode behoben; Ref: ADR-022 Nr. 6.1/6.2,
  docs/01 §2 Nr. 4, ADR-018 Nr. 3, REVIEW Runde 4 E54.**
  `R/fit.R:514` definiert die gemeinsame benannte Diagnose. Die beiden
  geschützten Abschnitte ab `R/fit.R:526` und `:541` umfassen
  `lFormula`, `mkLmerDevfun`, `devfun(theta)`, `mkMerMod` und das
  Auslesen von `VarCorr`. Fehler und Warnungen in diesen Engineaufrufen
  beenden den Fit sofort mit
  `Numeric model variance is not representable on the original scale at working precision.`
  Die äußere Klasse ist `simpleError`, der Aufruf `NULL`. Eine Warnung
  wird in diesen engen Abschnitten in einen Fehler übersetzt; ein
  Teilmodell wird nicht zurückgegeben. `checkConv` bleibt separat in
  Zeile 537, seine Warnungen und Modell-Diagnostik bleiben aktiv.
  Gesammelte Startwarnungen werden bei späterem Abbruch weiterhin in
  ihrer Reihenfolge ausgegeben. Der explizite Durchreichweg bleibt die
  Engine-Rechnung. Nullgrenze, Präzisionsgrenze, Schätzer und
  Abschlusskriterium wurden nicht verändert.

  Neu: `tests/testthat/test-fit-model-construction.R`, 18 Testblöcke.
  Die drei realen Reproduktionen und der positive Gegenfall verwenden
  `stats::aov` und die expliziten Zweifaktor-EMS-Formeln aus §2 der
  Formelsammlung. Positive Restfreiheitsgrade, RSS/SST oberhalb der
  unveränderten Nullgrenze und nichtnegative endliche EMS-Schätzer
  werden unabhängig geprüft. Numerische Toleranzen stammen aus ANK-TOL.
  Fehler und Warnungen an allen fünf Enginegrenzen werden zusätzlich
  synthetisch injiziert. Eigene Tests prüfen die aktive Konvergenzprüfung,
  Startwarnungen nach späterem Abbruch und den Durchreichweg. Nur der
  Diagnosetext ist als eigene Ausgabe charakterisiert. Vor der Korrektur
  sind 15 Blöcke mit 47 falschen Erwartungen rot; danach bestehen alle
  129 Erwartungen. Die neue Datei blieb zwischen beiden Läufen gleich.

  ADR-020, Nachtrag Runde 5, `?msa_fit` und NEWS.md dokumentieren die
  Fehlerbehandlung. `man/msa_fit.Rd` wurde mit roxygen erzeugt.

- **E55 — bestehender Test OUT-OF-TERRITORY für diesen Auftrag;
  nonblocking offen, BL-89. Ref: REVIEW E55, AGENTS.md
  Windows-CI-Bedingung und ausdrückliche Rework-Auftragsgrenze.**
  Der Auftrag untersagt: „Bestehende Tests, Abnahmetests
  (tests/acceptance/), QA-Tests (tests/e2e/, tests/fuzz/), Gates und
  Schwellen änderst du nicht.“ Deshalb bleibt der vom Reviewer
  vorgeschlagene Umbau von `test-fit-initialization.R:22–49` aus.
  Die Datei ist byte-identisch; ihre Tests bestehen in dieser
  Linux-Umgebung. Eine Windows-/macOS-Abnahme wird nicht behauptet.
  Das ist eine Auftragsgrenze, kein neu diagnostizierter Produktfehler.

  Die **neuen** E54-Reproduktionstests erzwingen keinen plattformabhängigen
  Engineabbruch: Ein erfolgreicher Fit muss die unabhängig berechneten
  ANOVA-Komponenten liefern; ein gescheiterter Modellbau muss benannt
  enden. Die synthetischen Fehler-/Warnungstests prüfen den genauen
  Diagnosevertrag unabhängig von der Plattform. BL-89 bleibt zur
  weiteren Behandlung und zum ersten plattformübergreifenden CI-Lauf
  beim Reviewer/Betreiber; BACKLOG wurde nicht geändert.

- **E56 — Dokumentation und balancierte Gegenrechnung ergänzt;
  Ref: REVIEW E56, ADR-018 Nr. 5, BL-87.**
  `R/fit.R:86` / `man/msa_fit.Rd:117` nennen jetzt auch den Aufbau
  des Originalskalenmodells nach der geschlossenen Lösung als mögliche
  Fehlerstelle. Die Hilfe erklärt, dass `checkConv` auf der Theta-Skala
  eine numerisch singuläre Hesse-Matrix melden kann, obwohl das
  balancierte Modell identifizierbar ist. Die Warnung bleibt sichtbar.

  ADR-020 dokumentiert die zusätzliche Gegenrechnung auf 120 festen
  balancierten Prüfeingaben, einschließlich eines Modells mit drei
  Faktoren und allen Zweifach-Wechselwirkungen. 45 erfolgreiche Fits
  behalten Komponenten, Theta, Numerikdiagnosen und Warnungen exakt bei;
  ihre Komponenten werden gegen ANOVA geprüft. Die anderen Fälle enden
  benannt. Das ist keine Verbesserung des Konvergenzbereichs und keine
  ADEMP-/Coverage-Aussage. Die weitergehende Verbesserung des allgemeinen
  Abschlusses und dessen Robustheitsnachweis aus E51/BL-87 bleiben vor
  M1d offen. Die neuen Messungen ersetzen diese offene Aufgabe nicht.

## Fortgeschriebene Befunde und Zuständigkeiten

| ID | Antwort in Runde 5 |
| --- | --- |
| E50 | Laut REVIEW Runde 4 erledigt. Die bestehenden sechs Initialisierungstests bleiben unverändert und bestehen. Die neue Fehlerbehandlung schützt die nachfolgende Stufe. |
| E51 / BL-87 | Dokumentationsweg bereits angenommen, jetzt nach E56 ergänzt. Verbesserung des allgemeinen Abschlusskriteriums bleibt nonblocking vor M1d offen. |
| E52 | Laut REVIEW Runde 4 erledigt; die Kosten der dichten Projektion stehen weiterhin in ADR-020. Keine neue Performancebehauptung. |
| E53 / BL-84 | Die zwei Index-Äquivalenzen wurden in Runde 4 vom Reviewer freigegeben. Erneuter Antrag wegen der Zeilenverschiebung, keine neue Äquivalenz. Die ausdrücklich nicht verlangten Darstellbarkeitsfälle und redundanten frühen Prüfungen bleiben offen; das vorliegende mutgate ist grün. |
| E48 / BL-85 | OUT-OF-TERRITORY [INFRA]. Die Approval-Zuordnung in `86-mutgate.sh:38–41` prüft weiterhin nur Datei, Mutator und Anfangszeile. Quellbindung/Gate-Schema sind Betreiberarbeit. Der Log-Beleg ist `gate-mutgate.log:1323` oben, die aktuelle Quellzuordnung steht in `claim-mapping.log` unten. Nur Anträge in MUT-EQUIV.json wurden neu gebunden; die zehn Reviewer-Approvals bleiben bytegleich. |
| E49 / BL-86 | OUT-OF-TERRITORY [INFRA]. Die mirai-Dispatcherprobe endet erneut mit `16 \| Permission denied`; die aktive Zeitprüfung des Paketchecks mit `Unable to verify current time.` Beide aktuellen Befehle und Logs stehen unten. Kein Eingriff in Sandbox, Dispatcher oder Prüfregeln. |
| E39 / BL-77 | OUT-OF-TERRITORY beim Betreiber/Reviewer: QA-Zitate. Ref: REVIEW Runde 4 „Stand der Einwände“, BACKLOG BL-77; kein neuer Builder-Fix. |
| E41 / BL-79 | OUT-OF-TERRITORY [INFRA]: Archivierung der Mutationsberichte. Ref: REVIEW Runde 4, `86-mutgate.sh:60–61` (`run_mutation`, Berichtslöschung). Der aktuelle vollständige Bericht ist vorhanden und unverändert; das Betreiber-Gate wird nicht bearbeitet. |
| E42 / BL-80 | OUT-OF-TERRITORY beim Betreiber: Größenordnungsangabe in K-M1a-4. Ref: REVIEW Runde 4, BACKLOG BL-80; Spec und Anker bleiben unverändert. |
| E43 / BL-81 | Gemäß ADR-022 Nr. 2 nach M1b vertagt: Gruppierungsfehlstellen bei ordinalen/binären Zielgrößen. Keine Änderung dieser Pfade in M1a. |

E44–E46 sind bereits in REVIEW Runde 3 erledigt; E47 geht in E53/BL-84
auf. Es gibt keinen aktuellen QA-PENDING-Befund. Die Pflege von BACKLOG
und der Approval-Datei bleibt bei den zuständigen Rollen.

## Ausgeführte Prüfungen

Alle Diagnoseartefakte liegen unter `/tmp/llmsa-m1a-r5/`. Die Befehle
wurden ausgeführt, ohne Git oder einen Gatezustand schreibenden Runner.
Ausgangs-SHA-256 von R/fit.R:
`73caf9801081da31ef01ab26c3e026c44c34f4060804329b7f63e84e902ebd94`.
Aktueller SHA-256:
`fff305a2c353c1f6bce60e549712913525e9c731087b0e6eac33fa1f6933be1c`.

### Neue Tests vor und nach der Produktkorrektur

```bash
Rscript --vanilla -e 'x <- testthat::test_dir("tests/testthat", filter = "^fit-model-construction$", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); cat(sprintf("Model construction regression: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`regression-before.log`, erwarteter Exit 1:

```text
✖ | 47       67 | fit-model-construction [1.1s]
Model construction regression: 18 tests; 15 failed blocks; 0 errors; 0 skipped
```

`regression-after.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 129 ]
Model construction regression: 18 tests; 0 failed blocks; 0 errors; 0 skipped
```

Der positive Gegenfall, die aktive Konvergenzprüfung und der Durchreichweg
bestehen schon vorher. Die 15 roten Blöcke betreffen die drei realen
Abbrüche und die zwölf synthetischen Fehler-/Warnungsfälle.

### Reproduktionen und balancierte Gegenrechnung

```bash
Rscript --vanilla /tmp/llmsa-m1a-r5/probe-construction.R
```

Exit 0. Der gesicherte Ausgangscode wurde in einer eigenen R-Umgebung
geladen; der Arbeitsbaum wurde nicht zurückgesetzt. Auszug des echten
Outputs aus `probe-construction.log`:

```text
noise=1e-07; seed=1002; df=24; aov RSS/SST=2.82229069e-15; EMS residual=7.81360473e-15
  before: class=Rcpp::exception/C++Error/error/condition; warnings=0; Downdated VtV is not positive definite
  after: class=simpleError/error/condition; warnings=0; call=NULL: TRUE; Numeric model variance is not representable on the original scale at working precision.
noise=1e-08; seed=1001; df=24; aov RSS/SST=6.19894245e-17; EMS residual=1.71619766e-16
  before: class=Rcpp::exception/C++Error/error/condition; warnings=2; Downdated VtV is not positive definite
  after: class=simpleError/error/condition; warnings=0; call=NULL: TRUE; Numeric model variance is not representable on the original scale at working precision.
noise=1e-08; seed=1005; df=24; aov RSS/SST=3.62881558e-17; EMS residual=1.00464956e-16
  before: class=Rcpp::exception/C++Error/error/condition; warnings=0; Downdated VtV is not positive definite
  after: class=simpleError/error/condition; warnings=0; call=NULL: TRUE; Numeric model variance is not representable on the original scale at working precision.
120 cases; 8 raw errors before, 0 after; 6 arithmetic warnings before, 0 after
45 unchanged successful fits; maximum component/TV error against aov EMS 3.76805041e-09 (ANK-TOL.oracle 0.0001)
E56 6x4x1x2; noise=0.001; seed=11/1001; RSS/SST=6.19968805e-07; closed_form; warnings=0
E56 6x4x1x2; noise=0.0001; seed=11/1001; RSS/SST=6.19901748e-09; closed_form; warnings=1
   Hessian is numerically singular: parameters are not uniquely determined
E56 6x4x1x2; noise=1e-05; seed=11/1001; RSS/SST=6.19894989e-11; closed_form; warnings=1
   Hessian is numerically singular: parameters are not uniquely determined
```

Die Sensitivitätsrechnung verwendet die drei Pläne 6×4×1×2, 8×3×1×3,
10×3×2×2 (Items×Prompts×Modelle×Replikate), Effekte mit Seed 11,
Rauschen `10^(-3:-10)` mit Seeds 1001–1005. Alle EMS-Schätzer sind
nichtnegativ. Von den 120 aktuellen Ausgängen sind 45 `closed_form`,
34 benannte Darstellbarkeitsfehler und 41 benannte Fehler der Restskala.
Die 45 erfolgreichen Fits sind exakt zum Ausgangscode gleich und
gegen `stats::aov` geprüft. Keine zusätzlichen erfolgreichen Fits werden
behauptet. Einzelergebnisse: `balanced-sensitivity.csv`; RNG, R 4.6.1,
lme4 2.0.6, Matrix 1.7.4 und BLAS/LAPACK stehen im Log.

### Unit-, QA- und unveränderte M1a-Abnahme

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' tests/testthat tests/e2e tests/fuzz
```

`unit-qa.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2809 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 215 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 80.00; exit: 0
```

Der einzige Skip ist der unveränderte ellmer-Negativtest
(`test-backends.R:32`, ellmer ist installiert).

```bash
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa /usr/bin/time -f 'M1a acceptance elapsed seconds: %e; exit: %x' Rscript --vanilla -e 'grDevices::pdf(NULL); x <- testthat::test_dir("tests/acceptance", filter = "^m1a-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = FALSE); d <- as.data.frame(x); cat(sprintf("M1a acceptance: %d tests; %d failed blocks; %d errors; %d skipped\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(save = "no", status = as.integer(any(d$failed > 0 | d$error)))'
```

`acceptance.log`, Exit 0, einschließlich Originalanker, geschützter
AIAG-Daten, NIST, Paketorakel und geknitteter Vignette:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 37.05; exit: 0
```

Vollständige M0/M2-Abnahme und die regulären Gates verbleiben beim
Orchestrator. Git-verwendende Prüfwege wurden nicht ausgeführt.

### Öffentlicher Paketbau und installierter Check

`python3 /tmp/llmsa-m1a-r5/prepare-package.py` kopierte 110 öffentliche
Paketdateien per Positivliste nach `package-check/src`: R/, man/, inst/,
data/, vignettes/, tests/testthat/, tests/testthat.R, DESCRIPTION,
NAMESPACE, LICENSE, NEWS.md, README.md und .Rbuildignore. Keine Schlüssel,
Betreiber-Fixtures, geschützten Referenzen oder Harness-Dateien.
Roxygen lief nur in der Kopie. Übernommen wurde ausschließlich
`man/msa_fit.Rd`; beiläufig erzeugte Änderungen an DESCRIPTION und
man/llmsa-package.Rd wurden nur in der temporären Kopie zurückgesetzt.

In `/tmp/llmsa-m1a-r5/package-check` ausgeführt, jeweils Exit 0:

```bash
Rscript --vanilla -e 'roxygen2::roxygenise("src", roclets = "rd")'
env -u REPO_ROOT R CMD build --no-manual src
env -u REPO_ROOT _R_CHECK_CRAN_INCOMING_REMOTE_=false /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Echter Output aus `build.log`, `check.log` und
`llmsa.Rcheck/tests/testthat.Rout`:

```text
* creating vignettes ... OK
* checking R code for possible problems ... OK
* checking re-building of vignette outputs ... [26s/26s] OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 123.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2734 ]
```

Keine ERRORs/WARNINGs. Die acht bestehenden Standalone-Skips sind fünf
fehlende Betreiber-Aufzeichnungen, der CRAN-Berichtstest, der
Originalanker-Vergleich ohne Repository und der ellmer-Negativtest.
Alle neuen Tests laufen auch im installierten Paket.

### Infrastruktur: OUT-OF-TERRITORY, mit Log-Belegen

**M1a-R5-INFRA-CLOCK — E49/BL-86.** `package-check/check.log:29–31`:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Zeitprüfung blieb aktiv. Die Incoming-Remote-Einstellung entspricht
dem unveränderten Betreiber-Prüfweg `orchestrator/lib/r-check.sh`.
Dies ist der einzige NOTE des Checks; das reguläre lint-Gate Runde 4
meldet weiterhin `Status: OK`.

**M1a-R5-INFRA-MUT-DISPATCH — E49/BL-86.** Ausgeführt:

```bash
timeout 20 Rscript --vanilla -e 'mirai::daemons(1L); mirai::daemons(0L)'
```

`mirai-probe.log`, Exit 1, kein Timeout:

```text
Error in .dispatcher_start(url, urld, tls_cfg, serial, envir[["stream"]],  :
  16 | Permission denied
Calls: <Anonymous> -> launch_dispatcher -> .dispatcher_start
Execution halted
```

Kein vollständiger Mutationslauf und kein neuer Score wurden erzeugt.
Es gibt keinen Scheinfix der Dispatcher-/Sandbox-Grenze.

**M1a-R5-INFRA-SESSIONINFO.** Die obige erfolgreiche Sensitivitätsrechnung
endet mit `sessionInfo()`. Dessen lokale Umgebungsabfrage meldet
in `probe-construction.log:55,92–93`:

```text
Failed to connect to system scope bus via local transport: Operation not permitted (consider using --machine=<user>@.host --user to connect to bus of other user)
In system("timedatectl", intern = TRUE) :
  running command 'timedatectl' had status 1
```

Exit des Diagnosetreibers bleibt 0; R-, Paket-, RNG- und BLAS-Angaben
stehen im Log. Die Meldung stammt aus der Systemabfrage nach den Fits,
nicht aus einem numerischen Prüffall. Systembus/Sandbox bleiben unverändert.

### Äquivalenzanträge

```bash
python3 /tmp/llmsa-m1a-r5/rebind-claims.py
```

`claim-mapping.log`, Exit 0:

```text
R/fit.R:233 -> 238; + → -; identical source; 3 round-4 survivors
R/fit.R:113 -> 118; FALSE → TRUE; identical source; 1 round-4 survivors
R/fit.R:352 -> 357; <n> + 1 → <n> + 1; identical source; 1 round-4 survivors
R/fit.R:352 -> 357; <n> - 1 → <n> - 1; identical source; 1 round-4 survivors
R/fit.R:453 -> 458; TRUE → FALSE; identical source; 1 round-4 survivors
R/fit.R:455 -> 460; TRUE → FALSE; identical source; 1 round-4 survivors
R/fit.R:461 -> 466; TRUE → FALSE; identical source; 1 round-4 survivors
R/grr.R:94 -> 94; > → >=; identical source; 1 round-4 survivors
R/fit.R:267 -> 272; <n> + 1 → <n> + 1; identical source; 1 round-4 survivors
R/fit.R:267 -> 272; x[<i>] → x[<i> + 1L]; identical source; 1 round-4 survivors
10 claim mappings checked against 12 round-4 survivors; no approval written
```

Die neun R/fit.R-Einträge wurden wegen fünf zusätzlicher roxygen-Zeilen
auf identische Quellzeilen versetzt; R/grr.R ist bytegleich. Der
Quelltext im alten Bericht stimmt bis auf dessen fehlenden letzten
Zeilenumbruch exakt mit dem gesicherten Ausgangscode überein. Die
Modellbau-Handler stehen hinter allen betroffenen R/fit.R-Zeilen und
registrieren keinen weiteren `on.exit`-Handler. Dies sind erneuerte
Anträge zu den zehn einzeln geprüften Äquivalenzen aus REVIEW Runde 4,
keine neuen Äquivalenzen oder eigenen Genehmigungen. Die erneute Bindung
der Reviewer-Approvals an den nächsten Gate-Bericht entscheidet der Reviewer.

### Integrität und Übergabe

```bash
python3 /tmp/llmsa-m1a-r5/integrity.py
```

`integrity.log`, Exit 0:

```text
Inventory: 315 baseline files; 7 allowed changed files; 308 byte-identical; no removed files; 1 allowed new file
Changed: NEWS.md, PROGRESS.md, R/fit.R, docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md, man/msa_fit.Rd, orchestrator/handoff/M1a/MUT-EQUIV.json, orchestrator/handoff/M1a/REWORK-NOTES.md
New: tests/testthat/test-fit-model-construction.R
All 69 existing test and fixture files remain byte-identical
Checked package copy: all 110 public source files match the workspace
No root-level Rplots.pdf, package archive or Rcheck directory
Gate facts remain round 4, result pass; mutation report, reviewer approvals and BACKLOG remain byte-identical
Ten existing equivalence claims map to identical source; no new equivalence or approval
R/fit.R SHA-256: fff305a2c353c1f6bce60e549712913525e9c731087b0e6eac33fa1f6933be1c
Modified R source and new test are ASCII
```

Alle bestehenden Tests, Abnahmetests, QA-Tests, Fixtures, Anker,
Golden-Daten, Specs, Gates, Schwellen und Reviewer-Approvals bleiben
unverändert. Die Inventur ersetzt nicht das Territoriums-Gate.
Keine Git-Kommandos, Abhängigkeitsinstallation oder eigenen API-Aufrufe.
PROGRESS ist aktualisiert; E54 wird mit den ausgeführten Belegen zur
Prüfung übergeben. Territoriumsprüfung, Phasen-Commit, vollständige Gates
und Code-Review erfolgen durch die zuständigen Rollen.
