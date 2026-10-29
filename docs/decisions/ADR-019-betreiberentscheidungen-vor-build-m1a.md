# ADR-019 — Betreiberentscheidungen vor BUILD M1a

## Status

Angenommen (Betreiber, 29.10.2026). Betreiber-Commit vor dem Neustart von `40-build` in M1a. Die Nummer ist frei: Das ADR-019 des abgebrochenen ersten BUILD-Versuchs hat der Rollback entfernt. Der erste Nachtrag vom 29.10.2026 ändert (a) Nr. 1 bis 3 und die Rücknahme; (a) bleibt als Verlauf stehen. Der zweite Nachtrag vom selben Tag, während der Gates von M1a Runde 1, ändert die Rollen-Prompts `60-rework.md` und `50-code-review.md`. Der dritte, nach diesen Gates, begrenzt die Flake-Wiederholung in `86-mutgate.sh` und `88-mutfull.sh` (`MUT_FLAKE_MARGIN`); wo er abweicht, gilt er.

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
3. **Bei der Umsetzung ergänzt** (über den Auftrag hinaus, Befunde 2 und 4; vom Betreiber nach dem Bericht vom 29.10.2026 angenommen, siehe Nachtrag):
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
- Rücknahme (angepasst mit dem Nachtrag vom 29.10.2026): `MUT_TEST_EXCLUDE=` (leer) lässt alle Testdateien laufen. `MUT_TEST_TIMEOUT=` (leer) hebt nur das Zeitlimit auf; der unmutierte Vorlauf bleibt. `MUT_TEST_TIMEOUT_FACTOR=3` stellt den Faktor aus (a) Nr. 3 wieder her. Die Änderungen an STOP und der Abbruch bei rotem Vorlauf gelten ohne Schalter.

## Nachtrag 29.10.2026 — vor dem Neustart von M1a

- Betreiber-Nachtrag zu `e739f7b`, ebenfalls außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`, `orchestrator/STOP` bleibt liegen; Umsetzung mit Claude Code). BUILD M1a hat noch nicht begonnen.
- Die Ergänzungen unter (a) Nr. 3 hat der Betreiber nach dem Bericht vom 29.10.2026 angenommen.
- Der Nachtrag ändert (a) Nr. 1 bis 3; wo er abweicht, gilt er.

### Entscheidungen

1. **Roter Vorlauf ist fail.** Scheitern schon im unmutierten Vorlauf Tests (fehlgeschlagen oder abgebrochen), bricht `r-mutation.R` vor dem ersten Mutanten ab: Exit 3, kein Bericht. Die roten Tests stehen im Log und in `unmutated.json` neben `MUT_REPORT` (Datei, Testname, fehlgeschlagen oder abgebrochen). `86-mutgate.sh` und `88-mutfull.sh` melden dann `fail`, nicht `pass` und nicht `error`, ohne Flake-Rerun und mit Anzahl und Namen der Tests im Kurzbefund: `mutgate: fail (unmutierter Vorlauf rot, kein Mutant gelaufen; 3 Tests: <Datei>: <Test> [fehlgeschlagen] | …)`. Der Vorlauf läuft immer, auch bei leerem `MUT_TEST_TIMEOUT`; leer hebt nur das Zeitlimit auf.
   - Begründung: Über einem roten Vorlauf zählt jeder Mutant als entdeckt; der Lauf wäre wertlos und kostet Stunden. Bisher warnte nur das Log ((a) Nr. 3).
   - Wie bisher `error`: Bricht der Vorlauf als Ganzes ab, etwa weil das Paket in der Kopie nicht lädt oder eine Testdatei nicht parst, gibt es keine Testergebnisse; das bleibt Infrastruktur (Exit 2). Exit 3 ohne lesbare `unmutated.json` ist ebenfalls `error`. Ohne Mutanten läuft kein Vorlauf; der leere Bericht ergibt `pass` wie bisher.
2. **Faktor 5.** Neue Variable `MUT_TEST_TIMEOUT_FACTOR`, Vorgabe 5 in `r-mutation.R`, Wert 5 in `config.env`; leer heißt Vorgabe, ein Wert unter 1 ist ein Konfigurationsfehler (Exit 2). Die Grenze eines Laufs ist max(`MUT_TEST_TIMEOUT`, ⌈Faktor × Laufzeit des Vorlaufs⌉). Der Faktor 5 gilt für die feste Grenze (Nr. 3) wie für den Vorlauf.
   - Begründung: Ein Timeout zählt als entdeckt. Unter Last braucht ein Mutant das 1,8-Fache des Einzellaufs (Probelauf `R/grr.R` unter Konsequenzen oben); bei Faktor 3 bliebe nur das 1,7-Fache als Reserve.
3. **test-m0-testthat-count ausgenommen.** In `config.env` steht `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$)'`. Mit `testthat::find_test_scripts` über alle Ordner aus `MUT_TEST_DIRS` geprüft (Werte aus `config.env`): Der Ausdruck trifft genau acht Dateien, `tests/acceptance/test-m2-1` bis `test-m2-7` und `tests/acceptance/test-m0-testthat-count.R`, nicht `tests/e2e/test-m2-qa-e2e.R` und `tests/fuzz/test-m2-qa-fuzz.R`.
   - Begründung: test-m0-testthat-count lässt `tests/testthat` ein zweites Mal laufen und zählt nur. Wie in (a) Nr. 1 senken weniger Tests den Score höchstens.
   - Zeitlimit laut Messung im Kontext: gefilterter Satz 116,9 s − 46,4 s = 70,5 s, also `MUT_TEST_TIMEOUT=353` (5 × 70,5 s, aufgerundet). Keine neue Vollmessung; der Vorlauf misst vor jedem Lauf nach (Nr. 2).
4. **Vorlage.** `config.env.example` führt `MUT_TEST_EXCLUDE`, `MUT_TEST_TIMEOUT` und `MUT_TEST_TIMEOUT_FACTOR` mit Kommentar im Block „Mutgate v2“, Vorgaben leer, leer, 5.
   - Begründung: `orchestrator/config.env` ist git-ignoriert, und `bootstrap.sh` legt eine neue `config.env` aus der Vorlage an. Die Vorgaben entsprechen dem Verhalten ohne Eintrag: alle Testdateien, kein Zeitlimit, Faktor 5.

### Bewusst unverändert

- `NOT_CRAN` bleibt im Mutationslauf ungesetzt, anders als in `r-tests.R` (BL-56, ADR-011). Betroffen ist nur der erste Test in `tests/testthat/test-report.R`, der einzige mit `skip_on_cran()` unter `tests/`. test-report.R prüft den Bericht, nicht den Kern, und ein übersprungener Test verfälscht den Score nicht.
- golden-adr bleibt in M1a, wie es ist, obwohl ADR-019 seine Bedingung für den ganzen Meilenstein erfüllt: `87-golden-adr.sh` verlangt nur irgendein geändertes `docs/decisions/ADR-*` seit `plan/<MS>`. Die Bedingung erfüllt jedes ADR im Meilenstein, auch eines des Builders.

### Für das Template vorgemerkt

- alle Änderungen aus `e739f7b` und diesem Nachtrag, auch in `orchestrator/gates.d/86-mutgate.sh.example` und im Preset `r-paket` (`projektierung/presets/r-paket/PRESET.md`), die hier unverändert bleiben;
- golden-adr soll verlangen, dass das ADR den geänderten Pfad nennt;
- wird `r-mutation.R` von außen beendet, soll es den laufenden Kindprozess mit beenden;
- die Ausnahme für rotes mutgate oder mutfull in `60-rework.md` und die Befunde zu überlebenden Mutanten in `50-code-review.md` (zweiter Nachtrag), im Template mit dem Berichtspfad aus `MUT_REPORT`;
- die Flake-Wiederholung in `86-mutgate.sh` und `88-mutfull.sh` nur dann, wenn der erste Score höchstens 5 Punkte unter der Schwelle liegt (`REQUIRED` beziehungsweise `MUT_SCORE_MIN`) — **umgesetzt** im dritten Nachtrag mit `MUT_FLAKE_MARGIN`; `86-mutgate.sh.example` und das Preset bleiben wie oben unverändert.

### Konsequenzen

- Geändert: `orchestrator/lib/r-mutation.R`, `orchestrator/gates.d/86-mutgate.sh`, `orchestrator/gates.d/88-mutfull.sh`, `config.env.example`, `docs/gates-auswahl.md` (Zeile mutgate, Konfigurationsblock §2, Wortlaut von `88-mutfull.sh` in §4), dieses ADR (Status, (a) Nr. 3, Rücknahme, Nachtrag). Lokal und git-ignoriert: `orchestrator/config.env` mit Werten und Kommentar wie im Konfigurationsblock.
- Unverändert: `R/`, `man/`, `tests/`, `inst/`, `vignettes/`, `DESCRIPTION`, `NAMESPACE`, `reference/anchors/`, `orchestrator/state/`, `orchestrator/handoff/`; die Zählung in 86-mutgate und 88-mutfull (Killed und Timeout entdeckt, Survived und NoCoverage unentdeckt, RuntimeError nicht gezählt).
- Für M1a: Auf `485c960` ist der Vorlauf rot (Befund 3). Bleiben nach BUILD Abnahmetests rot, endet mutgate nach dem Vorlauf mit `fail` und nennt sie, statt Stunden über einem wertlosen Score zu rechnen.
- Nachweis (29.10.2026): Wegwerf-Paket mit 13 Mutanten in zwei Dateien, darunter zwei Endlosschleifen; die echten `86-mutgate.sh` und `88-mutfull.sh` dieses Commits über ein Schein-`ORCH` mit eigener `config.env` (`MUT_TEST_EXCLUDE` wie oben, 2 Worker). Kein Mutationslauf über das Paket.
  - Vorlauf rot (ein fehlgeschlagener Test, ein Fehler außerhalb von `test_that()`, ein abgebrochener Test; dazu rote Tests in den ausgeschlossenen Dateien `test-m2-1-excluded.R` und `test-m0-testthat-count.R`): Beide Gates enden nach rund 1 s mit Exit 1 und `fail (unmutierter Vorlauf rot, kein Mutant gelaufen; 3 Tests: …)`; ein Vorlauf, kein Flake-Rerun, kein Mutant, kein Bericht, die ausgeschlossenen Dateien liefen nicht. Mit leerem `MUT_TEST_TIMEOUT` ebenso.
  - Vorlauf grün: `mutgate: pass (score=84.62 …)` und `mutfull: pass (score=84.62 …)` mit 9 Killed, 2 Timeout und 2 Survived. Grenze bei `MUT_TEST_TIMEOUT=1`: 3 s, also ⌈5 × 0,5 s⌉ aus dem Vorlauf; bei `MUT_TEST_TIMEOUT=10` und leerem Faktor: 10 s. Leeres `MUT_TEST_TIMEOUT`: Vorlauf, „Zeitlimit je Mutant: keins“, `pass (score=100 …)`. Grüner Vorlauf mit niedrigem Score: genau ein Flake-Rerun wie bisher, dann `fail (score=20.00 …)`.
  - `error` (Exit 2): Faktor 0,5; Vorlauf als Ganzes abgebrochen (Testdatei parst nicht); Exit 3 ohne `unmutated.json`.
  - Aus den Läufen blieb kein Prozess übrig.

## Zweiter Nachtrag 29.10.2026 — während der Gates von M1a Runde 1

- Betreiber-Nachtrag auf `118618f` (`orch(M1a): builder 40-build r1`), umgesetzt mit Claude Code. Anders als bei `e739f7b` und `6bd85b4` läuft der Orchestrator: Gates Runde 1, `86-mutgate.sh` rechnet. `orchestrator/STOP` ist gesetzt, damit bis zu diesem Commit keine Modellphase beginnt; der Orchestrator wurde weder gestartet noch angehalten.
- Lage um 14:07 Uhr laut Fortschrittsanzeige von muttest: 358 von 1003 Mutanten in `R/fit.R` und `R/grr.R` gelaufen, 179 Killed, 130 Survived, 49 Fehler. muttest zeigt auch die Harness-Timeouts als Fehler, bis `r-mutation.R` sie nach dem Lauf umbenennt; nach der Zählung von 86-mutgate läge der Score damit zwischen 57,9 und 63,7, verlangt sind 80 (keine Baseline). Zwischenstand, kein Gate-Ergebnis. Rund 12,7 s je Mutant, Hochrechnung rund 3,5 h je Durchgang; bleibt der Score unter 80, folgt genau ein Flake-Rerun über alle 1003 Mutanten.
- Anlass: `60-rework.md` verlangte, jedes fachlich rote Gate „am Produktcode, niemals an Tests, Gates oder Schwellen“ zu beheben. Für das tests-Gate ist das richtig. Für mutgate und mutfull verbietet es den üblichen Weg: Überlebende Mutanten zeigen Lücken in den Tests, nicht Fehler im Code.

### Entscheidungen

1. **Rework darf Tests gegen überlebende Mutanten schreiben** (`orchestrator/prompts/60-rework.md`). Bei rotem mutgate oder mutfull darf der Builder neue Tests unter `tests/testthat/` schreiben, die überlebende Mutanten töten. Bestehende Tests, Abnahmetests (`tests/acceptance/`), QA-Tests (`tests/e2e/`, `tests/fuzz/`), Gates und Schwellen ändert er nicht; Produktcode ändert er dafür nur dort, wo ein Mutant toten oder überflüssigen Code zeigt. Echte Äquivalente beantragt er wie bisher in `MUT-EQUIV.json`. Neue Tests prüfen Verhalten gegen unabhängige Werte (Anker, Orakel, Formel), wo es sie gibt; eine Momentaufnahme der eigenen Ausgabe nur dort, wo es keine unabhängige Referenz gibt, und dann als solche gekennzeichnet.
2. **Code-Review nennt die überlebenden Mutanten** (`orchestrator/prompts/50-code-review.md`). Bei rotem mutgate oder mutfull nennt der Reviewer die überlebenden Mutanten aus `reports/mutation/mutation.json` (`MUT_REPORT`; Survived oder NoCoverage ohne Approval, wie die Gates zählen) nach Datei und Stelle gruppiert als blocking-Befunde mit dem Gate als `ref`, je Mutant mit Zeile und `mutatorName` wörtlich aus dem Bericht, und mit der erwarteten Abhilfe (Test, Code entfernen, Äquivalenzantrag). Neue Tests prüft er darauf, dass sie Verhalten belegen und nicht nur die eigene Ausgabe einfrieren; eine gekennzeichnete Momentaufnahme gilt nur dort, wo es keine unabhängige Referenz gibt.
   - Zeile und `mutatorName` wörtlich, weil die Gates eine Approval über Datei, `mutatorName` und Anfangszeile zuordnen; ein ungenauer Antrag ließe den Score unverändert.

Begründung: Mutation misst die Tests. Das Verbot, Tests zu schreiben, hätte Rework-Runden ohne Fortschritt erzeugt: Änderungen am Produktcode töten keinen Mutanten, den kein Test prüft, und Äquivalenzanträge decken nur echte Äquivalente.

### Konsequenzen

- Geändert: `orchestrator/prompts/60-rework.md`, `orchestrator/prompts/50-code-review.md`, dieses ADR (Status, Für das Template vorgemerkt, dieser Nachtrag).
- Unverändert: `orchestrator/gates.d/`, `orchestrator/state/`, `orchestrator/handoff/`, `STATUS.md`, `R/`, `tests/`; Territorien, Gates, Schwellen und die Zählung in 86-mutgate und 88-mutfull. `tests/testthat/` gehört über `BUILDER_EXTRA_PATHS_REGEX` schon zum Builder-Territorium, auch in `60-rework`; zwischen neuen und bestehenden Tests unterscheidet der Orchestrator dort nicht, die Grenze steht nur im Prompt.
- Wirkung: `render_prompt()` liest den Prompt beim Start einer Phase; die Änderung gilt ab dem nächsten Code-Review und Rework von M1a. Den laufenden Mutationslauf berührt sie nicht: Seine Paketkopie enthält nur `DESCRIPTION`, `NAMESPACE`, `R`, `inst`, `data`, `src`, `tests/fixtures` und die Ordner aus `MUT_TEST_DIRS`.
- `gates.json` dieser Gate-Runde nennt in `env.sha` diesen Commit statt `118618f`, weil `verifier.sh` HEAD erst nach dem letzten Gate liest. Produktcode und Tests sind die von `118618f`; dieser Commit ändert nur die beiden Prompts und dieses ADR. Der Gate-Commit des Orchestrators folgt auf ihn.

## Dritter Nachtrag 29.10.2026 — nach den Gates von M1a Runde 1

- Betreiber-Nachtrag auf `a92396f` (`orch(M1a): gates r1 (rc=1)`), umgesetzt mit Claude Code. Der Orchestrator steht: `orchestrator/logs/orchestrate.log` endet um 19:26:48 mit „FATAL: STOP-Datei gefunden — vor der nächsten Phase angehalten.“; kein `orchestrator/.lock`, kein Orchestrator-, Gate- oder Modellprozess. `orchestrator/STOP` bleibt liegen; der Orchestrator wurde nicht gestartet.
- mutgate in Runde 1 laut `orchestrator/state/M1a/gate-mutgate.log`: 1003 Mutanten (`R/fit.R` 783, `R/grr.R` 220), zwei Durchgänge mit gleichem Ergebnis, je 517 Killed, 29 Timeout, 360 Survived und 97 RuntimeError; Score 60,26 bei Schwelle 80 (keine Baseline), also 19,74 Punkte darunter. Im Log: `mutgate: 60.26 < 80; genau ein Flake-Rerun`, am Ende `mutgate: fail (score=60.26 required=80 baseline=n/a floor=80)`.
  - Dauer laut Gate-Log: unmutierter Vorlauf 85 s und 88,1 s, muttest („Duration“) 11895,14 s und 11701,83 s. Die Wiederholung kostete damit rund 3 h 16 min und änderte nichts.
  - Das ganze Gate lief von 12:50:28 bis 19:26:46, rund 6 h 36 min (Beginn aus dem Prozessalter um 14:07:52, zweiter Nachtrag; Ende `env.ts` in `gates.json`).

### Entscheidung

1. **Flake-Rerun nur nahe der Schwelle.** Liegt der erste Score unter der verlangten Schwelle, wiederholen `86-mutgate.sh` und `88-mutfull.sh` den Lauf genau einmal, aber nur, wenn er höchstens `MUT_FLAKE_MARGIN` Punkte darunter liegt. Liegt er weiter darunter, melden beide Gates sofort `fail` mit Score, Schwelle und dem Hinweis, dass keine Wiederholung lief; in Runde 1 hätte das gelautet: `mutgate: fail (score=60.26 required=80 baseline=n/a floor=80; 19.74 Punkte unter der Schwelle, mehr als MUT_FLAKE_MARGIN=5, ohne Flake-Rerun)`.
   - `MUT_FLAKE_MARGIN`: Vorgabe 5 in beiden Gate-Skripten und in `config.env.example`, Wert 5 in `config.env`; leer heißt Vorgabe, 0 schaltet die Wiederholung ab. Ein Wert, der keine Zahl ab 0 ist, ist ein Konfigurationsfehler (Exit 2, `error`) und fällt vor dem ersten Durchgang auf.
   - Verlangte Schwelle: in 86-mutgate `REQUIRED` (ohne Baseline `MUT_SCORE_MIN`, sonst Baseline minus `MUT_RATCHET_TOL`, mindestens `MUT_SCORE_FLOOR`), in 88-mutfull `MUT_SCORE_MIN`. Der Abstand wird wie Score und Schwelle auf zwei Stellen gerundet; genau 5,00 Punkte lösen die Wiederholung noch aus.
   - Unverändert: Zählung, Score, Ratchet und Baseline; der rote Vorlauf (`fail` ohne Rerun); über der Schwelle `pass` wie bisher; innerhalb des Abstands genau ein Rerun, das bessere Ergebnis zählt. Die Zeile vor dem Rerun nennt jetzt den Abstand.

Begründung: Die Wiederholung fängt Schwankungen von ein bis zwei Punkten ab. Bei 20 Punkten Abstand kostet sie einen vollen Durchgang, in M1a Runde 1 rund 3 h 16 min, und kann das Ergebnis nicht drehen.

### Nachweis (29.10.2026)

Wegwerf-Paket mit einer Datei `R/a.R` (zwei Funktionen) und einer Testdatei: 8 Mutanten, 5 Killed, 3 Survived, Score 62,5. Die echten `86-mutgate.sh` und `88-mutfull.sh` dieses Commits liefen aus dem Repo über ein Schein-`ORCH` mit dem echten `_lib.sh`, je Fall frischer `config.env` und dem echten Adapter `r-mutation.R` (2 Worker), ohne Baseline, wo nicht anders genannt; ein Durchgang dauerte rund 3,5 s. Kein Mutationslauf über das Paket llmsa.

| Fall | `MUT_SCORE_MIN` | `MUT_FLAKE_MARGIN` | Abstand | Durchgänge | Ergebnis, in beiden Gates gleich |
| --- | --- | --- | --- | --- | --- |
| über der Schwelle | 60 | 5 | – | 1 | `pass (score=62.5 required=60 …)` |
| knapp darunter | 65 | 5 | 2,50 | 2 | `62.5 < 65 (2.50 Punkte darunter, höchstens MUT_FLAKE_MARGIN=5); genau ein Flake-Rerun`, dann `fail (score=62.50 required=65 …)` |
| an der Grenze | 67.5 | 5 | 5,00 | 2 | Rerun, dann `fail (score=62.50 required=67.5 …)` |
| knapp über der Grenze | 67.51 | 5 | 5,01 | 1 | `fail (score=62.5 required=67.51 …; 5.01 Punkte unter der Schwelle, mehr als MUT_FLAKE_MARGIN=5, ohne Flake-Rerun)` |
| weit darunter | 82.5 | 5 | 20,00 | 1 | `fail (score=62.5 required=82.5 …; 20.00 Punkte unter der Schwelle, mehr als MUT_FLAKE_MARGIN=5, ohne Flake-Rerun)` |
| Vorgabe | 65 | leer; ohne Eintrag | 2,50 | 2 | Rerun mit `höchstens MUT_FLAKE_MARGIN=5`, dann `fail` |
| abgeschaltet | 65 | 0 | 2,50 | 1 | `fail (…; 2.50 Punkte unter der Schwelle, mehr als MUT_FLAKE_MARGIN=0, ohne Flake-Rerun)` |
| altes Verhalten | 82.5 | 100 | 20,00 | 2 | Rerun, dann `fail (score=62.50 required=82.5 …)` |
| ungültig | 65 | abc | – | 0 | Exit 2 vor dem ersten Durchgang, stderr `MUT_FLAKE_MARGIN muss eine Zahl ab 0 sein: abc` |

- Ratchet in 86-mutgate (`MUT_SCORE_FLOOR=50`, `MUT_RATCHET_TOL=2`): Baseline 69 ergibt `required=67.00`, 4,50 Punkte Abstand, Rerun, dann `fail`; Baseline 70 ergibt `required=68.00`, 5,50 Punkte, `fail` ohne Rerun.
- Gegenprobe mit den Skripten von `a92396f` in denselben Fällen: über der Schwelle und knapp darunter derselbe Kurzbefund wie mit den neuen; weit darunter liefen dort zwei Durchgänge bis `fail (score=62.50 required=82.5 …)`.
- Aus den Läufen blieb kein Prozess übrig.

### Konsequenzen

- Geändert: `orchestrator/gates.d/86-mutgate.sh`, `orchestrator/gates.d/88-mutfull.sh`, `config.env.example` (Block „Mutgate v2“), `docs/gates-auswahl.md` (Zeile mutgate, Konfigurationsblock §2, Wortlaut von `88-mutfull.sh` in §4), dieses ADR (Status, Für das Template vorgemerkt, dieser Nachtrag). Lokal und git-ignoriert: `orchestrator/config.env` mit `MUT_FLAKE_MARGIN=5` und Kommentar wie im Konfigurationsblock.
- Unverändert: `R/`, `man/`, `tests/`, `inst/`, `vignettes/`, `DESCRIPTION`, `NAMESPACE`, `reference/anchors/`, `orchestrator/state/`, `orchestrator/handoff/`, `orchestrator/prompts/`, `orchestrator/lib/r-mutation.R`, `orchestrator/gates.d/86-mutgate.sh.example`; das Ergebnis von Runde 1 (`gates.json`, `gate-mutgate.log`) bleibt, wie es ist.
- Für M1a: Die nächste Gate-Runde (nach QA in Runde 1) läuft mit der neuen Regel. Liegt der Score wieder rund 20 Punkte unter 80, endet mutgate nach einem Durchgang, nach den Zahlen von Runde 1 in rund 3,3 h statt 6,6 h.
- Rücknahme: `MUT_FLAKE_MARGIN=100` stellt das alte Verhalten her; jeder Score unter der Schwelle liegt höchstens 100 Punkte darunter.
