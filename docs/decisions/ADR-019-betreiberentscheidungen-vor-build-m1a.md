# ADR-019 — Betreiberentscheidungen vor BUILD M1a

## Status

Angenommen (Betreiber, 29.10.2026). Betreiber-Commit vor dem Neustart von `40-build` in M1a. Die Nummer ist frei: Das ADR-019 des abgebrochenen ersten BUILD-Versuchs hat der Rollback entfernt.

## Kontext

- Der Orchestrator steht seit 28.10.2026, 19:03:36 (FATAL „STOP-Datei gefunden“). Der Betreiber hatte den ersten Versuch von `40-build` M1a abgebrochen; `orchestrate.log` verbucht das um 19:01:36 als Transportfehler (rc=137) mit Retry nach 120 s. Der Rollback setzte den Arbeitsbaum auf `485c960` (Tag `plan/M1a`, Plan freigegeben). Der Betreiber hat am 29.10. geprüft: keine codex- oder Rscript-Prozesse, seit dem Halt keine Datei im Repo geändert.
- E12 (PLAN-REVIEW M1a, Runde 2, `orchestrator/handoff/M1a/verdict-plan.json`, nonblocking, [INFRA], an den Betreiber): Je Mutant laufen alle Abnahmetests, die M2-Abnahmetests allein rund 930–946 s; Hochrechnung rund 9 h je Gate-Lauf bei 14 Workern. Weder `86-mutgate.sh` noch `orchestrator/lib/r-mutation.R` setzen ein Zeitlimit (zur Vorgabe von muttest selbst Befund 1). In M0 und M2 lief kein Mutant („kein geänderter Mutations-Scope“); der Lauf in M1a wäre der erste.
- Messung am 29.10.2026, unmutiert, so aufgerufen wie in `HarnessTestStrategy`: Paketkopie wie in `r-mutation.R`, je Ordner aus `MUT_TEST_DIRS` `testthat::test_dir(load_package = "source")` nacheinander in einem R-Prozess, `setup-*.R` eingeschlossen. Umgebung: R 4.6.1, testthat 3.3.2, muttest 0.3.0, callr 3.8.0, 32 Kerne, Referenz-BLAS. Zeit je Datei über die Aufrufe von `testthat::source_file`:
  - Voller Satz 1036,6 s: `tests/testthat` 45,5 s, `tests/acceptance` 987,7 s, `tests/e2e` 2,5 s, `tests/fuzz` 0,7 s.
  - Die sieben M2-Abnahmetests zusammen 918,7 s: test-m2-3-prompts-parser 497,7 s, test-m2-1-items 134,6 s, test-m2-6-evaluate 97,6 s, test-m2-7-robustness-pilot 94,0 s, test-m2-2-memorisation 91,6 s, test-m2-5-plan 1,6 s, test-m2-4-backends 1,6 s.
  - Ohne sie (`MUT_TEST_EXCLUDE='^m2-[0-9]'`) 116,9 s: `tests/testthat` 45,0 s, `tests/acceptance` 68,5 s (davon test-m0-testthat-count 46,4 s, test-m1a-3-oracles 13,1 s), `tests/e2e` 2,4 s, `tests/fuzz` 0,9 s. Höchster Speicherbedarf 0,9 GB (voller Satz 1,5 GB).
  - `setup-*.R` je rund 0,01 s, auch `setup-m2.R`; die M2-QA-Tests zusammen rund 3 s (test-m2-qa-e2e 2,3 s, test-m2-qa-fuzz 0,8 s).
  - test-m0-testthat-count lässt `tests/testthat` im geladenen Paket ein zweites Mal laufen und zählt nur die Tests; das kostet je Mutant rund 46 s.
- Befunde bei der Umsetzung:
  1. muttest 0.3.0 hat eine eigene Grenze, `muttest(timeout = 600 * 1000)` in Millisekunden, und reicht sie als `.timeout` an mirai weiter. Diese Grenze zählt ab dem Einreihen in die Warteschlange, nicht ab dem Start eines Mutanten. Probe mit mirai 2.7.3: 6 Aufgaben zu je 3 s, 2 Worker, Grenze 5 s; die Aufgaben 3 bis 6 enden mit errorValue 5. muttest führt einen solchen Mutanten als `RuntimeError` („Timed out“), und den zählen 86-mutgate und 88-mutfull weder als entdeckt noch als unentdeckt. Künstlicher Fall mit dem Strategie-Aufruf von `485c960` und der muttest-Grenze 5 s: alle 8 Mutanten `RuntimeError`, Score nach der Formel von 86-mutgate 100. Mit der Vorgabe 600 s und rund 1040 s Testzeit je Mutant hätte der Lauf in M1a nach rund zehn Minuten fast jeden Mutanten so geführt; der Score hätte nur die wenigen vorher beendeten Mutanten gezählt.
  2. Die Paketkopie enthielt `tests/fixtures/` nicht. Darin brechen fünf Tests in `tests/testthat` (test-acmg-pilot-costs, test-backend-finish-reason, test-backend-reasoning) mit „AP1 test recording missing: ../fixtures/api/sol.json“ ab. muttest führt einen Mutanten, bei dem kein Test scheitert, aber einer abbricht, als `RuntimeError` statt `Survived`; der Score hätte nur getötete Mutanten gezählt.
  3. Auf `485c960` scheitern die Abnahmetests von M1a unmutiert, weil M1a noch nicht gebaut ist (test-m1a-4 bis test-m1a-7: 21 Tests fehlgeschlagen, 6 abgebrochen). Bis BUILD M1a gilt deshalb jeder Mutant als getötet; der Score des Probelaufs ist kein Maßstab.
  4. STOP: Der Rollback nach einem abgebrochenen Versuch löscht `orchestrator/STOP` (`git clean` in `rollback_attempt()`). Entsteht die Datei während einer Modellphase, gilt sie als Territoriumsverletzung, und der Versuch wird verworfen. Nimmt man sie aus der Territoriumsprüfung aus, erreicht die Phase `commit_phase()`, dessen `git add -A` die Datei mitcommitten würde; ebenso `park()`.
- ADR-018 (Reviewer, `30-plan-review` M1a Runde 2) legt den Vorgabepfad von `msa_fit(type = "numeric")` fest; der Betreiber entscheidet, ob er ihn ohne Änderung trägt.

## Entscheidung

### (a) E12 und STOP

1. **Testauswahl.** `r-mutation.R` liest `MUT_TEST_EXCLUDE`, einen regulären Ausdruck auf den Testnamen, also den Dateinamen ohne `test-` und `.R` wie bei `testthat::test_dir(filter)`. Passende Testdateien laufen im Mutationslauf nicht; leer heißt keine Ausnahme. In `config.env` steht `MUT_TEST_EXCLUDE='^m2-[0-9]'`.
   - Der Ausdruck trifft genau `tests/acceptance/test-m2-1` bis `test-m2-7`, nicht `tests/e2e/test-m2-qa-e2e.R` und `tests/fuzz/test-m2-qa-fuzz.R` (geprüft mit `testthat::find_test_scripts` über alle Ordner aus `MUT_TEST_DIRS`).
   - Umsetzung mit `test_dir(filter = MUT_TEST_EXCLUDE, invert = TRUE)`. In testthat 3.3.2 reicht `test_dir` `invert` über `...` an `find_test_scripts` weiter (geprüft an Probedateien); `setup-*.R` laufen unabhängig vom Filter. Ein Ordner ohne verbleibende Testdatei wird übersprungen, sonst bräche `test_dir` mit „No test files found.“ ab. Die Prüfung dafür ruft `find_test_scripts(full.names = FALSE)` auf wie `test_dir`; mit vollen Pfaden passt `^m2-` nie.
   - Begründung: Weniger Tests senken den Score höchstens; ein Bestehen gilt damit auch für den vollen Testsatz.
   - Gemeldet, nicht geändert: `setup-m2.R` kostet rund 0,01 s, die M2-QA-Tests zusammen rund 3 s.
2. **Zeitlimit je Mutant.** `MUT_TEST_TIMEOUT` in Sekunden, Wert max(60, 3 × 116,9 s) aufgerundet, also `MUT_TEST_TIMEOUT=351`.
   - muttests eigene Grenze ist ungeeignet (Befund 1) und bleibt aus (`timeout = Inf`). Die Grenze sitzt in `HarnessTestStrategy$execute`: Die Tests eines Mutanten laufen in einem eigenen R-Prozess (`callr::r(timeout = …, cleanup_tree = TRUE)`). Nach der Grenze wird der Prozess samt Kindprozessen beendet.
   - Ein Mutant über der Grenze steht im Bericht als `Timeout` (Grund `harness-timeout: …`) und zählt in 86-mutgate und 88-mutfull als entdeckt; der Lauf geht mit dem nächsten Mutanten weiter. muttest selbst kennt den Status nicht und führt den Abbruch als `RuntimeError`; `r-mutation.R` benennt ihn nach dem Lauf um, sonst bleibt der Bericht unverändert.
3. **Bei der Umsetzung ergänzt** (über den Auftrag hinaus, Befunde 2 und 4):
   - `tests/fixtures/` gehört zur Paketkopie.
   - Unmutierter Vorlauf: Vor dem ersten Mutanten läuft der gefilterte Testsatz einmal unmutiert in einer eigenen Kopie. Das Log nennt Laufzeit, fehlgeschlagene und abgebrochene Tests und warnt, wenn schon unmutiert Tests scheitern. Die Grenze des Laufs ist max(`MUT_TEST_TIMEOUT`, ⌈3 × Laufzeit des Vorlaufs⌉); das Log nennt beide Werte. Grund: Der Testsatz wächst mit BUILD M1a und in M1b bis M1d; eine feste Grenze träfe dann auch Mutanten, die die Tests nicht verlangsamen, und jeder Timeout zählt als entdeckt.
   - `commit_phase()` und `park()` nehmen `orchestrator/STOP` beim `git add` aus.
4. **STOP.** `changed_paths()` überspringt `orchestrator/STOP`, `rollback_attempt()` nimmt die Datei beim `git clean` aus (`-e orchestrator/STOP`), dazu Nr. 3. Eine STOP-Datei aus einer laufenden Modellphase ist keine Territoriumsverletzung, übersteht den Rollback und wird nie committet; der Orchestrator hält vor dem nächsten Versuch oder nach dem Commit der Phase. `RUNBOOK.md`, Abschnitt STOP, beschreibt das.
5. **Doku.** `docs/gates-auswahl.md` (Zeile mutgate, Konfigurationsblock) und der Kommentar in `orchestrator/config.env` nennen Entscheidung, Begründung, Messwerte und die Wirkung auf mutfull in M1c.

### (b) ADR-018 bestätigt

ADR-018 (Vorgabepfad von `msa_fit`, `type = "numeric"`) wird ohne Änderung bestätigt.

Begründung:

- Der Schätzer bleibt derselbe: Kriterium und `merMod` stammen aus lme4, das Kriterium stimmt laut Reviewer bis auf eine Konstante mit dem von lme4 überein; ersetzt wird nur der Weg zum Optimum.
- Die ableitungsfreien Optimierer bleiben je nach Lage und Skalierung der Daten an verschiedenen Punkten stehen (auf `ic50_demo` bis 8,7e-6 · σ²_TV); EMS-Lösung und Newton-Abschluss treffen das Optimum bis auf Rundung, die Invarianz folgt aus der Rechnung.
- Die eigene Numerik wird gegen ANOVA-Lösung, Orakel (`VCA::remlVCA`) und NIST StRD nachgerechnet (K-M1a-1, -3, -4).

Verworfener Gegenweg: `ANK-TOL.invariance` auf 1e-4 · σ²_TV lockern und bei `lmer` mit bobyqa bleiben. Das hätte einen neuen Planzyklus gekostet und den Invarianztest für Fehler unter 1e-4 blind gemacht.

Folgen:

- E13 (scheitert der Newton-Abschluss, endet `msa_fit` mit Fehler) wird im Code-Review M1a geprüft und im Plan von M1c behandelt, und zwar das Verhalten eines Simulationslaufs (`boot_coverage`, `msa_plan`), wenn ein einzelnes Replikat scheitert.
- Die Formelsammlung §2 erhält nach `done/M1a` einen Satz zum Rechenweg (Betreiber, nicht in diesem Commit).

## Konsequenzen

- Betreiber-Commit außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`, `orchestrator/STOP` bleibt liegen; Umsetzung mit Claude Code). Geändert: `orchestrator/lib/r-mutation.R`, `orchestrator/orchestrate.sh`, `RUNBOOK.md`, `docs/gates-auswahl.md`, dieses ADR. `orchestrator/config.env` ist git-ignoriert; `MUT_TEST_EXCLUDE`, `MUT_TEST_TIMEOUT` und ihr Kommentar stehen dort lokal, der Konfigurationsblock in `docs/gates-auswahl.md` §2 gibt sie wieder.
- Unverändert: `R/`, `man/`, `tests/`, `inst/`, `vignettes/`, `DESCRIPTION`, `NAMESPACE`, `reference/anchors/`, `orchestrator/state/`, `orchestrator/handoff/`; Kriterien, Abnahmetests, Anker und Toleranzen; `86-mutgate.sh` und `88-mutfull.sh` mit ihrer Zählung (Killed und Timeout entdeckt, Survived und NoCoverage unentdeckt, RuntimeError nicht gezählt).
- Nachweis (29.10.2026):
  - Künstlicher Fall: ein Wegwerf-Paket mit drei Funktionen und einem Test, dessen Schleife bei zwei der acht Mutanten nie endet; `MUT_TEST_TIMEOUT=10`. Direkt mit 2 Workern: Die beiden Endlos-Mutanten stehen nach 10 s als `Timeout` im Bericht, 5 sind `Killed`, 1 `Survived`; der Lauf endet nach 13 s. Über `86-mutgate.sh` und `88-mutfull.sh` mit 1 Worker: `mutgate: pass (score=87.5 required=80 …)` und `mutfull: pass (score=87.5 required=80 …)`, je 24 s. Sechs Mutanten warteten länger als die Grenze in der Warteschlange und liefen regulär zu Ende; kein Prozess blieb übrig. Ein ganz ausgeschlossener Ordner wird übersprungen (8 × `NoCoverage`).
  - Probelauf über `R/grr.R` (`MUT_FILES=R/grr.R`, `config.env` wie im Gate, `MUT_WORKERS=14`, Bericht außerhalb des Repos): 211 Mutanten. Vorlauf unmutiert 121,8 s, Grenze des Laufs 366 s. Laufzeit je Mutant: Median 224 s, Quartile 216 und 233 s, Maximum 260 s, Mittel 216,7 s; kein Timeout. Gesamtdauer 3479 s (58 min, davon muttest 3355 s). 206 `Killed`, 5 `RuntimeError` (String-Mutanten in Z. 71, 72 und 75, die schon beim Parsen scheitern); Score nach 86-mutgate 100, wegen Befund 3 kein Maßstab.
  - Hochrechnung für `R/fit.R` und `R/grr.R` (451 Mutanten vor M1a): 451 × 216,7 s / 14 ≈ 7000 s, rund 2 h je Mutationslauf; mit dem Flake-Rerun von 86-mutgate höchstens das Doppelte. Nach BUILD M1a laufen die M1a-Abnahmetests vollständig, und die geänderten Dateien tragen mehr Mutanten; beides verlängert den Lauf.
  - Unmutiert gegen Grenze: 116,9 s gegen 351 s (Messung) und 121,8 s gegen 366 s (Vorlauf), je rund ein Drittel. Bei 14 parallelen Läufen brauchte ein Mutant im Median das 1,8-Fache des allein laufenden Satzes; das Maximum von 260 s lag bei 71 % der Grenze.
- mutfull in M1c: `88-mutfull.sh` ruft denselben Adapter mit derselben `config.env` auf; Testauswahl, Zeitlimit und Vorlauf gelten dort ebenso. Der Score über `R/fit.R` und `R/grr.R` ist damit höchstens niedriger als mit allen Testdateien; ein Bestehen von K-M1c-6 gilt auch für den vollen Testsatz.
- Code-Review M1a: E13 nach (b); den BACKLOG-Eintrag zu E12 schreibt der Reviewer (verdict-plan.json, E12).
- Rücknahme: `MUT_TEST_EXCLUDE=` (leer) lässt alle Testdateien laufen, `MUT_TEST_TIMEOUT=` (leer) hebt Zeitlimit und Vorlauf auf. Die Änderungen an STOP gelten ohne Schalter.
