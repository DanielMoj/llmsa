# M1b — REWORK, Runde 3

Rolle: Builder · Stand: 31.10.2026 · Keine Git-Kommandos.

## Grundlage und Grenze der Aussage

Gelesen wurden AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
PROGRESS.md, Handoff-Schema, REVIEW/verdict-code Runde 2, CRITERIA.json,
gates.json samt Fehlerstellen der Gate-Logs, ARBITER.md, LESSONS.md,
die M1b-Spezifikation, ihre Auslegungen und die betroffenen Abnahmetests.
Insbesondere bindet ADR-029 Nr. 2 für E24. Der Arbiterentscheid zu K-M1b-5
bleibt unverändert: Logit-Restvarianz pi²/3, ANK-25 nur Installationsprüfung.

Die vorhandenen Gate-Fakten sind weiterhin **Runde 2**: `tests: fail`,
sieben weitere Gates `pass`, kein Status `error`; mutgate 91,91 bei
verlangten 91,83. Diese Datei schreibt kein neues Gate-Ergebnis und kein
Abnahme-Verdict. E24 ist umgesetzt; E27 und E28 sind zusätzlich bearbeitet.
E25 ist durch die vorhandene Reviewer-Korrektur lokal bestätigt. E26 bleibt
OUT-OF-TERRITORY [QA-PENDING].

Rohlogs und temporäre Paketkopien dieser Runde liegen unter
`/tmp/llmsa-m1b-r3-2ug3odnl/`. Die nachstehenden Auszüge sind echter Output;
die vollständige Werkzeugspur bleibt im Modellphasen-Log des Orchestrators.

## Antworten auf die Befund-IDs

### E24 — umgesetzt, gezielt geprüft

Ref: docs/01 §2 Nr. 4; ADR-029 Nr. 2; LESSONS „Numerische Randfälle als
Klasse beheben.“

- `R/fit.R:302` prüft vor beiden latenten Engine-Aufrufen das gemeinsame
  Varianzdesign aller Zufallsterme, einschließlich Wechselwirkungen.
  Zeilenauswahl und Bereinigung sind dann bereits abgeschlossen. Der feste
  Teil enthält den Achsenabschnitt und die ordinalen Zwei-Stufen-Faktoren
  mit den tatsächlich übergebenen Kontrasten.
- `msa_latent_information()` (`R/fit.R:396`) berechnet das Gram-Kriterium
  G_ij = ||Z_iᵀ P Z_j||²_F in Faktorstufenräumen; n × n-Matrizen werden
  nicht angelegt. Es gilt die Eigenwertregel aus ADR-029, mit k und
  `.Machine$double.eps`, ohne neue empirische Konstante. Vollständig vom
  festen Design aufgespannte Terme werden mittels Rangnachweis als exakte
  Nullzeile/-spalte behandelt. Das deckt auch den Fall ab, dass **alle**
  Zufallsterme aufgespannt sind und Rundungsreste sonst eine positive
  1 × 1-Matrix vortäuschen könnten. ADR-030 begründet die Umsetzung.
- Die Fehlermeldung nennt die gemeinsam geprüften Zufallsterme und den
  Bezug auf den festen Teil. Bestehende Fehler für feste Rangdefizienz,
  zu wenige beobachtete ordinale Zufallsstufen und ungültige Labels bleiben.
- `tests/testthat/test-fit-latent-identifiability.R` enthält sieben neue
  Blöcke: unabhängige Rechnung mit Beobachtungspaaren; alle sechs Paare
  der vier Gruppierungsfaktoren, beide Zielgrößen und Links; verschachtelte
  Items mit Wechselwirkungen, auch erst nach `subset`; konfundierte
  zweistufige binäre Modell-/Blockfaktoren; vom festen Design aufgespannte
  Komponenten mit q = p und q < p; eine exakte Kovarianzabhängigkeit ohne
  identische Partitionen; gültige verschachtelte und gekreuzte Pläne gegen
  direkte `clmm`-/`glmer`-Fits. Engine-Sperren prüfen ausdrücklich, dass
  die unzulässigen Pläne vor dem Aufruf abbrechen.
- `man/msa_fit.Rd` wurde aus Roxygen in einer temporären Paketkopie erzeugt;
  ausschließlich diese generierte Hilfeseite wurde übernommen.
- `inst/validation/sim/simulation_helpers.R:214` nimmt den neuen Helfer in
  den Implementierungshash auf. Alle neun Kurzlaufdateien sind mit dem
  aktuellen installierten Paket neu erzeugt (P4). Alle sechs CSVs sind
  bytegleich zum Rundenbeginn; die drei Sessiondateien sind aktualisiert.

Belege: P1 (vollständige Units), P2 (unveränderte M1b- und M1a-Abnahme),
P4 (Kurzläufe), P5 (Mutation), P6 (Paketcheck). Die Gegenprobe P3 setzt nur
`msa_fit()` in einer temporären Kopie auf den Rundenbeginn zurück: sieben
Testblöcke, 93 fehlgeschlagene Erwartungen, keine Testfehler. Die neuen
Prüfungen erkennen somit das bisherige Verhalten; die Gram-Nachrechnung
wird dabei nicht durch einen fehlenden neuen Helfer künstlich rot.

### E25 — OUT-OF-TERRITORY [INFRA], Reviewer-Korrektur lokal bestätigt

Ref: `orchestrator/state/M1b/gate-tests.log:662–696`,
`tests/acceptance/test-m1b-7-vignette-full-results.R`, ADR-029 Nr. 1.
Der alte Gate-Output lautet unter anderem:

```text
Expected `k$error` to be NULL.
Invalid latent study result measure range: .../two_level_results.csv
[ FAIL 5 | WARN 2 | SKIP 0 | PASS 6355 ]
```

Die Fixture des Reviewers hatte `derived_share = 1.5` erzeugt. Ihre bereits
vor dieser Runde vorhandene Korrektur bleibt bytegleich; der Produktvalidator
bleibt unverändert streng. P2 bestätigt jetzt:

```text
✔ |        204 | m1b-7-vignette-full-results [36.9s]
✔ |        240 | m1b-7-vignette [34.2s]
```

Keine Builder-Reparatur an Fixture oder Prüfschwelle. BL-94 und die
Bestätigung im regulären Gate bleiben beim Reviewer/Orchestrator.

### E26 — OUT-OF-TERRITORY [QA-PENDING], weiterhin reproduzierbar

Ref: `orchestrator/state/M1b/gate-tests.log:951–1084`,
`tests/e2e/test-m1b-qa-e2e.R:151–184`, ADR-029 Nr. 3, BL-95.
QA-M1b-004 lädt seine Paketkopie in denselben Prozess und löscht sie,
ohne den vorherigen Namespace-Pfad wiederherzustellen. Der aktuelle
unveränderte QA-Lauf P7 reproduziert die vier nachfolgenden M2-Fehler:

```text
✔ |         26 | m1b-qa-e2e [9.8s]
Error in `find.package(package)`: there is no package called 'llmsa'
[ FAIL 4 | WARN 4 | SKIP 0 | PASS 40 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: fail — 16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen
```

Die Fehler stehen in `qa.log:47–172`; der Backtrace verweist auf die
`qa-m1b-stage-*`-Kopie. Alle sechs M1b-QA-Befunde bestehen. Die vier
M2-E2E-Blöcke bestehen in einem frischen Prozess mit neun Erwartungen
(P7). Das ist ein Gegenbeleg zur Ursache, kein Ersatz für den roten
zusammenhängenden QA-Lauf.

Kein Produkt-Scheinfix, kein Nachladen des Originals aus `REPO_ROOT`,
keine Änderung an QA oder Betreiberzustand. QA muss nach ADR-029 den
verschachtelten Lauf isolieren oder den ursprünglichen Namespace exakt
wiederherstellen; der Betreiber fordert den QA-Nachlauf an. Ein neues
Gesamt-PASS kann der Builder nicht erklären.

### E27 — die benannten Testlücken geschlossen; drei Äquivalenzanträge

Ref: REVIEW Runde 2, E27; Mutationsbericht der Runde 2; BL-96.
Neue Datei `tests/testthat/test-fit-latent-calls-labels.R`, drei Blöcke:
explizite umgekehrte Labels eines geordneten Faktors gegen unabhängig
kodiertes `clmm`; genau zwei ordinale Kategorien gegen `clmm`; erneute
Auswertung des gespeicherten binären Aufrufs nach Verlassen seiner
Aufrufumgebung, mit Steuerung, Offset und Gewichten, gegen direktes
`glmer`. Keine eingefrorene eigene Ausgabe.

P5 tötet alle vier in E27 ausdrücklich benannten Überlebenden. Die Zeilen
haben sich durch Dokumentation und die neue Prüfung verschoben:

| Runde-2-Stelle | Aktuelle Stelle / lokale Mutanten-ID | Ergebnis |
| --- | --- | --- |
| 160, zweites `&& → \|\|` | 163, ID 17 | Killed |
| 166, `< → <=` | 169, ID 13 | Killed |
| 331, binäres Call-Index `+ 1L` | 343, ID 56 | Killed |
| 331, binäres Call-Index `- 1L` | 343, ID 69 | Killed |

Die gezielten Proben des neuen Kriteriums führten zu zusätzlichen
Erwartungen für die vollständige Nullzeile/-spalte und getrennt lesbare
Termnamen. Der abschließende Lauf über alle 80 ausgewählten Mutanten
liefert 65 Killed, vier RuntimeError und elf Survived. RuntimeError wird
nicht als getötet gezählt. Das ist **kein vollständiger Gate-Score**;
getestet wurden nur die latenten Unit-Dateien. Unter den Überlebenden
liegt beispielsweise auch die Öffnung der Prüfung für numerische Fits,
die dieser begrenzte Testsatz nicht ausführt.

`MUT-EQUIV.json` enthält genau drei einzeln begründete Builder-Anträge aus
diesem ausgeführten Lauf: `fixed = FALSE` beim Literal-Doppelpunkt in
`strsplit` (Zeile 398) sowie beide Änderungen des vollständig vor jedem
Lesen überschriebenen Initialwerts der Gram-Matrix (Zeile 405). Die
Anträge nennen den allgemeinen Äquivalenzbeweis. Keine Eigenwert- oder
Grenzfallbehauptung wird pauschal als Äquivalenz beansprucht. Es gibt keine
Builder-Freigabe und keine `MUT-EQUIV-APPROVED.json`.

### E28 — umgesetzt

Ref: NEWS.md, BL-97. Der Kopf von `NEWS.md` nennt jetzt Identifizierbarkeit,
Zeilenargumente und Gewichte, Labelvorrang und Labelprüfung, erneut
auswertbare Engine-Aufrufe, `data$.msa_offset` sowie die Bedeutung der
ordinalen Singularität. Die öffentliche Hilfe enthält die neue
Identifizierbarkeitsprüfung. Paketbau und installierter Check: P6.

### Fortführung der älteren IDs aus REVIEW

| ID | Stand dieser Runde |
| --- | --- |
| E12 | Laut REVIEW erledigt; bestehende Refit-/Bootstrap-Tests und QA-M1b-001 bestehen, gespeicherter binärer Aufruf zusätzlich durch E27 geprüft. |
| E13 | Laut REVIEW erledigt; Zeilenauswahl-/Gewichts-/Offset-Tests und QA-M1b-002 bestehen. |
| E14 | Die bisherigen Prüfungen bleiben; die darüber hinausgehende Klasse behandelt E24. QA-M1b-003 besteht. |
| E15 | Bestehender Dokumentationshelfer unverändert; QA-M1b-004 selbst besteht. Sein Namespace-Seiteneffekt ist E26. |
| E16 | Bestehende Labelprüfungen und QA-M1b-005 bestehen; E27 ergänzt zwei weitere zulässige Eingaben. |
| E17 | Bestehende Datei-/Bereichsprüfungen und QA-M1b-006 bestehen; keine Lockerung für E25. |
| E18 | Gate Runde 2 bereits pass. Neuer vollständiger Score bleibt beim Orchestrator; P5 und MUT-EQUIV sind Vorschläge/Diagnosen. |
| E19 | Im Review und Gate Runde 2 erledigt; R/acmg.R und das Reviewer-Orakel bleiben unverändert. Aktueller M2-Lauf: P8. |
| E20 | Dokumentierter Invarianzvorbehalt und Vorgabe-Optimierer bleiben unverändert (BL-91). |
| E21 | Kurzlaufbefund bleibt durch bytegleiche CSVs unverändert; quantitative Volllaufbewertung bleibt Betreiber/M1d (BL-92). |
| E22 | Gate Runde 2 bestätigt HTTP-Replay und Zeitprüfung. Kein neuer HTTP-Replay-Lauf in dieser Runde; lokale Zeit-NOTE siehe P6. |
| E23 | OUT-OF-TERRITORY, nonblocking: unveränderte `nobars`-/`findbars`-Deprecation-Warnungen im Abnahmehelfer, P2, BL-93. |

## Ausgeführte Prüfungen und echter Output

Die Befehle sind nachstehend mit diesen identischen Pfaden verkürzt:

```sh
R3_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa
R3_WORK=/tmp/llmsa-m1b-r3-2ug3odnl
export REPO_ROOT="$R3_ROOT" NOT_CRAN=true TZ=Europe/Berlin
```

Für P1, P2, P3, den frischen Prozess in P7 und P8 wurde der folgende
Runner unter `$R3_WORK/run-tests.R` tatsächlich ausgeführt. Fehler werden
vollständig gesammelt und liefern anschließend Exit 1:

```r
args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(args[1L], mustWork = TRUE)
pkgload::load_all(root, quiet = TRUE, helpers = FALSE)
grDevices::pdf(tempfile(fileext = ".pdf"))
elapsed <- system.time(result <- testthat::test_dir(file.path(root, args[2L]),
  filter = args[3L], load_package = "none", stop_on_failure = FALSE,
  reporter = testthat::ProgressReporter$new(show_praise = FALSE)))
d <- as.data.frame(result)
cat(sprintf("Blocks: %d; failed expectations: %d; error blocks: %d; skipped: %d; elapsed: %.3f s\n",
  nrow(d), sum(d$failed), sum(d$error), sum(d$skipped), elapsed[["elapsed"]]))
quit(status = as.integer(any(d$failed > 0L | d$error)))
```

### P1 — abschließende vollständige Unit-Suite, Exit 0

```sh
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_ROOT" tests/testthat ''
```

`unit-final.log`:

```text
✔ |         17 | fit-latent-calls-labels
✔ |        204 | fit-latent-identifiability [6.9s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3621 ]
Blocks: 247; failed expectations: 0; error blocks: 0; skipped: 1; elapsed: 128.133 s
```

Die zehn neuen Blöcke liefern 221 Erwartungen. Der einzige Skip ist der
unveränderte ellmer-Negativtest. Ein früherer vollständiger Lauf bestand
bereits mit 3601 Erwartungen; die zusätzlichen Erwartungen danach sind
im hier genannten abschließenden Lauf enthalten.

### P2 — unveränderte M1b-Abnahme und M1a-Regression, jeweils Exit 0

```sh
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_ROOT" tests/acceptance '^m1b-'
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_ROOT" tests/acceptance '^m1a-'
```

`acceptance-m1b.log`, Auszug:

```text
✔ |         34 | m1b-1-engine-ordinal [2.8s]
✔ |        2155 | m1b-2-recovery-scripts [143.7s]
✔ |        687 | m1b-3-two-level-script [16.1s]
✔ |   2     37 | m1b-4-two-levels [3.1s]
✔ |          9 | m1b-5-binary-rptr
✔ |        108 | m1b-6-edge-cases [11.4s]
✔ |        204 | m1b-7-vignette-full-results [36.9s]
✔ |        240 | m1b-7-vignette [34.2s]
[ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
Blocks: 74; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 248.955 s
```

Die beiden Warnungen stehen in `acceptance-m1b.log:89–114`: Der
unveränderte Abnahmetest ruft `lme4::nobars()` und `lme4::findbars()` auf.
Sie gehören zum bekannten E23/BL-93, nicht zum Produktfix.
K-M1b-2/-3 reproduzieren die Kurzläufe und ihre Präfixe und bestehen die
unveränderten Schema-, Formel- und Laufzeitprüfungen.

`acceptance-m1a.log`:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
Blocks: 54; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 38.258 s
```

M0-Prüfwege, die Git aufrufen, wurden nicht gestartet.

### P3 — negative Gegenprobe mit dem bisherigen Fit, erwartet Exit 1

In `$R3_WORK/before-source` wurde allein die Definition von `msa_fit()`
aus der vor dieser Runde gesicherten `fit-before.R` übernommen. Die
übrigen Funktionen und der neue Helfer für die unabhängige Gram-Prüfung
blieben erhalten. Der Arbeitsbaum wurde nicht zurückgesetzt.

```sh
Rscript --vanilla "$R3_WORK/restore-before-fit.R"
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_WORK/before-source" tests/testthat 'fit-latent-identifiability$'
```

Die endgültige neue Testdatei wurde auch in diese Kopie übernommen.
`before-final.log`, unveränderte Standardgrenze der Testausgabe:

```text
Maximum number of failures exceeded; quitting.
Blocks: 7; failed expectations: 93; error blocks: 0; skipped: 0; elapsed: 8.258 s
```

Es wurde keine Fehlergrenze verändert. Das ist eine Gegenprobe zur
Regressionserkennung, kein Gate-Score und kein Produktfehler am Endstand.

### P4 — installierter aktueller Stand und echte Kurzläufe, jeweils Exit 0

Die Paketkopie `install-source` enthält ausschließlich DESCRIPTION,
NAMESPACE, LICENSE, R, man, data und inst. Keine Abhängigkeit wurde
installiert; die Installation des Pakets selbst liegt in einer temporären
Bibliothek für den vorgeschriebenen Skriptlauf.

```sh
TZ=Europe/Berlin R CMD INSTALL --no-docs --library="$R3_WORK/library" "$R3_WORK/install-source"
python3 "$R3_WORK/generate-checks.py"
```

Installation: `install.log`, `* DONE (llmsa)`. Der Generator liest
`ANK-TOL.n_check$n_sim` und `ANK-TOL.sim_runtime$cores`, setzt `R_LIBS`
auf die temporäre Bibliothek und startet aus einem fremden Arbeitsordner:

```sh
Rscript --vanilla "$R3_WORK/library/llmsa/validation/sim/ordinal_recovery.R" --n-sim 20 --out "$R3_WORK/checks/ordinal_recovery"
Rscript --vanilla "$R3_WORK/library/llmsa/validation/sim/binary_recovery.R" --n-sim 20 --out "$R3_WORK/checks/binary_recovery"
Rscript --vanilla "$R3_WORK/library/llmsa/validation/sim/two_level.R" --n-sim 20 --out "$R3_WORK/checks/two_level"
```

`generate-checks.log`:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 108.138 s; workers 14
ordinal_recovery: exit=0; wall_seconds=108.985
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.905 s; workers 14
binary_recovery: exit=0; wall_seconds=1.560
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.037 s; workers 14
two_level: exit=0; wall_seconds=10.713
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Erst nach Erfolg aller drei Studien wurden deren neun Dateien bytegleich
auf die `_check_`-Namen kopiert. Der Generator bestätigt für alle sechs
CSVs `same_bytes_as_before=True`; für die drei Sessiondateien FALSE.
Es wurde kein Ergebniswert manuell eingetragen.

Der zusätzliche Abgleich lädt die aktuellen Quellen mit
`pkgload::load_all(helpers = FALSE)`, sourced den installierbaren
Studienhelfer und vergleicht `sim_implementation()` mit den drei
Sessionköpfen. `session-hashes.log`, Exit 0:

```text
Current implementation: c2045c7c594adda23b5ecd516fcedf0ed28a52df00180c79f9cbea9ea0238c9d
ordinal_recovery session matches current code
binary_recovery session matches current code
two_level session matches current code
```

### P5 — echte gezielte Mutationsproben; kein vollständiges Mutationsgate

```sh
Rscript --vanilla "$R3_WORK/prepare-mutations.R"
Rscript --vanilla "$R3_WORK/run-mutations.R"
python3 "$R3_WORK/run-mutations-final.py"
```

Der Plan verwendet dieselben neun `muttest`-Mutatorfamilien wie der
Betreiberadapter und selektiert die neue Prüfung, ihren Helfer und die
E27-Stellen. Er enthält 80 Mutanten. Die temporäre Paketkopie enthält
sämtliche latenten Unit-Dateien und die benötigten unveränderten Helfer.
Der unmutierte Vorlauf war grün:

```text
Unmutated targeted suite: 24 blocks; failed expectations 0; errors 0; skips 0
```

**M1B-R3-INFRA-MUTTEST — OUT-OF-TERRITORY [INFRA].** Der native parallele
Start scheiterte danach vor dem ersten Mutanten (`mutations.log`, Exit 1):

```text
Error in .dispatcher_start(url, urld, tls_cfg, serial, envir[["stream"]],  :
  16 | Permission denied
Calls: <Anonymous> ... <Anonymous> -> launch_dispatcher -> .dispatcher_start
```

Keine Sandbox-/Berechtigungsänderung, kein Gate-Eingriff. Als lokale
Diagnose wurden dieselben von `muttest` erzeugten mutierten Quellen in
je einer neuen Paketkopie mit einem frischen R-Prozess geprüft (14
gleichzeitige Prozesse). Der Runner lädt ausschließlich die jeweilige
Kopie. Er erfasst echte `testthat`-Ergebnisse und verwendet dieselbe
Klassifikation wie `muttest:::.record_result`: fehlgeschlagene Erwartung
→ Killed, ausschließlich Testfehler → RuntimeError, sonst Survived.
Der vollständige Mutationsbericht ist
`targeted-subprocess-mutation-final.json`; je Mutant liegen Ergebnis und
R-Output unter `mutation-runs-final/`.

Abschließender Output, Exit 0 des Diagnoserunners:

```text
Counts: {"Killed": 65, "RuntimeError": 4, "Survived": 11}
Elapsed seconds: 87.444
```

Exit 0 bedeutet hier, dass alle 80 Proben ausgeführt wurden; er erklärt
keine Mutationsschwelle für bestanden. Der reguläre vollständige Lauf
und die Entscheidung über die drei Claims bleiben ausstehend.

### P6 — öffentlicher Paketbau und installierter Check, jeweils Exit 0

Eine Positivliste kopierte Paketdateien, Unit-Tests und Vignetten nach
`$R3_WORK/package-source`, ohne Harness, Schlüssel, Betreiber-Fixtures
oder geschützte Originalquellen. Aus `$R3_WORK` ausgeführt:

```sh
TZ=Europe/Berlin R CMD build --no-manual package-source
TZ=Europe/Berlin _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

`build.log` und `check.log`:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
* checking R code for possible problems ... OK
* checking tests ...
  Running ‘testthat.R’ [90s/90s]
 [90s/90s] OK
* checking package vignettes ... OK
* DONE
Status: 1 NOTE
```

Installierter Testlauf (`llmsa.Rcheck/tests/testthat.Rout`):

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 3545 ]
```

Die neun bestehenden Skips: fünf Tests benötigen die nicht ausgelieferten
API-Aufzeichnungen, zwei die lokalen Originalanker, ein Berichtstest ist
On-CRAN markiert, einer ist der ellmer-Negativtest. Die neuen Tests laufen
auch im installierten Paket; es wurde kein Skip ergänzt.

**M1B-R3-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Einzige NOTE in
`check.log:29–30`:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.
```

Die Zeitprüfung blieb aktiv. `_R_CHECK_CRAN_INCOMING_REMOTE_=false`
entspricht unverändert `orchestrator/lib/r-check.sh:41`; keine weitere
Prüfregel wurde abgeschaltet. Keine ERRORs oder WARNINGs.

### P7 — vollständige QA-Verzeichnisse und frischer M2-Prozess

```sh
Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); source("orchestrator/lib/r-tests.R")' tests/e2e tests/fuzz
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_ROOT" tests/e2e '^m2-'
```

Zusammenhängender QA-Lauf: Exit 1, tatsächlicher Output bei E26.
Frischer M2-Prozess (`qa-m2-fresh.log`), Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
Blocks: 4; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 5.169 s
```

### P8 — M2-Auswertung auf dem unveränderten Anwendungsprodukt

```sh
Rscript --vanilla "$R3_WORK/run-tests.R" "$R3_ROOT" tests/acceptance '^m2-6-'
```

Der erste Lauf endete mit einer durch den parallelen Arbeitsablauf
verursachten Fehlmessung, nicht mit einem Produktfehler
(`acceptance-m2-6.log`, Exit 1):

```text
Expected `m$new_files` to be identical to `character()`.
`actual`:   "docs/decisions/ADR-030-m1b-latente-identifizierbarkeit.md"
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 382 ]
Blocks: 11; failed expectations: 1; error blocks: 0; skipped: 0; elapsed: 276.136 s
```

Die Datei wurde vom Builder während der Dateiinventur des Tests angelegt.
Nach Anlage aller neuen Dateien wurde derselbe unveränderte Test komplett
wiederholt. Am Test und am Produktcode wurde dafür nichts geändert.

Der zweite Lauf (`acceptance-m2-6-final.log`) endete mit Exit 0:

```text
✔ |        383 | m2-6-evaluate [269.7s]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 383 ]
Blocks: 11; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 269.902 s
```

## Integrität und Übergabe

Die SHA-256-Inventur vergleicht die 306 zu Rundenbeginn erfassten Dateien
und sucht neue Dateien in den betroffenen Verzeichnissen. Sie gleicht
außerdem den abschließenden Paketstand mit der tatsächlich gebauten und
geprüften Paketkopie sowie die Äquivalenzanträge mit den ausgeführten
Mutationsproben ab. Befehl, Exit 0:

```sh
python3 "$R3_WORK/integrity.py"
```

Echter Output (`integrity-final.log`):

```text
Inventory: 9 changed baseline files, 4 new files; assigned Builder paths only; no removed files
Changed: NEWS.md, PROGRESS.md, R/fit.R, inst/validation/sim/binary_recovery_check_session.txt, inst/validation/sim/ordinal_recovery_check_session.txt, inst/validation/sim/simulation_helpers.R, inst/validation/sim/two_level_check_session.txt, man/msa_fit.Rd, orchestrator/handoff/M1b/REWORK-NOTES.md
New: docs/decisions/ADR-030-m1b-latente-identifizierbarkeit.md, orchestrator/handoff/M1b/MUT-EQUIV.json, tests/testthat/test-fit-latent-calls-labels.R, tests/testthat/test-fit-latent-identifiability.R
Protected baseline: 291/291 files byte-identical
Existing tests and fixtures: 91/91 files byte-identical
Final package source: R, man, inst, all unit tests, DESCRIPTION, NAMESPACE and NEWS byte-identical
Source and new tests: ASCII; no package archive, Rcheck directory, root SQLite store or Rplots.pdf in workspace
Equivalence claims: 3 distinct observed survivors; no approval file
Gate facts unchanged: round 2, result fail
```

Die Inventur ersetzt nicht das Territoriums-Gate. Keine Git-Kommandos,
keine Abhängigkeitsinstallation, keine API-Aufrufe mit realen Schlüsseln,
keine Änderung von Spezifikationen, bestehenden Tests, Abnahme, QA,
Ankern, Golden-Daten, Gate-Fakten, Gates oder Schwellen. R/grr.R und
R/acmg.R bleiben bytegleich. BACKLOG und Betreiberzustand bleiben
unverändert. Territoriumsprüfung, Phasen-Commit, vollständiger Gate-Lauf,
QA-Nachlauf und Reviewer-Entscheidung stehen dem Orchestrator und den
zuständigen Rollen zu.
