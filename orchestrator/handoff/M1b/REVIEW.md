# REVIEW — M1b, Runde 1 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 31.10.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `43608d3…` (`gates.json`, `env.sha`): BUILD-Commit des Builders und QA-Commit;
- die Gate-Fakten `orchestrator/state/M1b/gates.json` mit allen acht `gate-*.log` und `reports/mutation/unmutated.json`;
- `QA.md` mit den Tests `tests/e2e/test-m1b-qa-e2e.R` und `tests/fuzz/test-m1b-qa-fuzz.R`.

## Ergebnis

**Verdict REWORK.** `gates.result` ist `fail` (tests, mutgate); sieben blocking-Befunde (E12 bis E18), fünf nonblocking (E19 bis E23).

- **Abnahme M1b:** Alle acht M1b-Abnahmedateien sind im Gate grün (Gate-Fakten unten). Die Klasse-B-Kurzläufe reproduziert der Abnahmetest byte-identisch.
- **Rot sind:**
  - die sechs reproduzierenden QA-Tests QA-M1b-001 bis -006;
  - K-M2-6 wegen des Abnahmeorakels (E10 der Planrunde, [INFRA]);
  - mutgate, weil sein unmutierter Vorlauf an denselben QA-Tests und an `tests/testthat/test-validation-latent.R` scheitert.
- **Alle sechs QA-Befunde sind echt.** Keine QA-Erwartung widerspricht der Spec. Wo die Spec schweigt, legt ADR-027 die Auslegung fest. Damit sind die QA-Tests erfüllbar (E12 bis E17).
- **In dieser Phase umgesetzt:** ADR-025 Nr. 4 (Rückfallorakel K-M2-6/-7) in `tests/acceptance/setup-m2.R`, dazu ein Selbsttest des Orakels in `tests/acceptance/test-m2-6-evaluate.R`. Mein Lauf: K-M2-6 und K-M2-7 grün, 20 Blöcke, 758 Erwartungen (Prüflauf 1).
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-027-m1b-code-review-auslegungen.md`;
  - ein Projekt-Amendment in `IMPLEMENTATION-RULES.md` (ADR-027 Nr. 7);
  - BL-90 bis BL-93 und ein Stand-Vermerk in BL-86 in `BACKLOG.md`.
- **MUT-EQUIV:** Es gibt weder einen Mutationsbericht noch Anträge. `MUT-EQUIV-APPROVED.json` wird nicht geschrieben.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`. Dazu `orchestrator/prompts/60-rework.md` und `50-code-review.md` sowie `orchestrate.sh` (`path_allowed`).
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `PLAN.md` (Auszüge), `PLAN-UPDATE.md` vollständig, `PLAN-REVIEW.md` und `verdict-plan.json` der Runde 2;
  - `ARBITER-REQUEST.md`, `verdict-arbiter.json`, `orchestrator/ESCALATION-M1b.md`, `QA.md`.
  - Nicht vorhanden: `REVIEW-INPUT.md`, `MUT-EQUIV.json`.
- **Spezifikation:**
  - docs/02, Abschnitt M1b, mit Szenariotabelle und den Kriterien im Wortlaut (das trace-Gate bestätigt die wörtliche Verknüpfung);
  - docs/01 §2 (Prüfstandard);
  - ADR-006 Nr. 4, ADR-023, ADR-025 vollständig, ADR-026 (Builder) vollständig.
- **Diff, ohne Git:**
  - Änderungen über `find -newer orchestrator/state/M1b/3-plan-approved.done`;
  - Inhalt der Änderungen aus den `diff --git`-Blöcken des BUILD-Logs `orchestrator/logs/M1b-40-build-r1-a1-20261031-095737.log` (Z. 69129–71100, letzter kumulativer Stand).
  - Vollständig gelesen:
    - `R/fit.R` und `R/grr.R`;
    - `inst/validation/sim/simulation_helpers.R` und die drei CLI-Skripte;
    - `inst/validation/latent/reference_checks.R` und `SOURCES.json`;
    - `vignettes/validation.Rmd`, `DESCRIPTION`, `NEWS.md` (Kopf);
    - die neuen Unit-Tests `test-fit-latent.R`, `test-fit-latent-diagnostics.R`, `test-grr-latent.R`, `test-acmg-latent-diagnostics.R`, `test-validation-latent.R` und `helper-validation-latent.R`;
    - die Diffs der geänderten Bestandstests `test-fit-grr.R`, `test-fit-rework-inputs.R` und `test-grr-rework.R`;
    - `PROGRESS.md`, Abschnitt M1b.
  - Stichprobe: die Kurzlaufdateien von two_level und die Diagnosen der Sessiondateien.
- **Visuelle Artefakte:** keine; M1b fordert keine (`orchestrator/state/M1b/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 1 (`gates.json`, `env.sha` `43608d3`) |
| --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, rptR 0.9.23, performance 0.19.0) |
| lint | pass (`R CMD check --as-cran --no-manual`: Status OK, beide Vignetten gebaut und neu gebaut) |
| tests | **fail** |
| trace | pass |
| territory | pass (qa/45-qa, Runde 1) |
| mutgate | **fail**: unmutierter Vorlauf rot, kein Mutant gelaufen |
| golden-adr | pass (keine Golden- oder Ankeränderung) |
| mutfull | pass („nicht fällig in M1b“) |
| **result** | **fail** |

- **tests** (`gate-tests.log`):
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3221 ]`; der Skip ist der bekannte ellmer-Negativtest.
  - `tests/acceptance`:
    - M0, M1a und alle M1b-Dateien grün: m1b-1 34, m1b-2 2155, m1b-3 687, m1b-4 37, m1b-5 9, m1b-6 108, m1b-7-vignette-full-results 204, m1b-7-vignette 240 Erwartungen.
    - m1b-4 trägt zwei Warnungen aus dem Abnahmehelfer selbst (`lme4::nobars` und `findbars` nach `reformulas` verschoben, E23).
    - `m2-6-evaluate`: 13 Fehlschläge mit genau dem Muster aus E10 der Planrunde: `isTRUE(mo$fallback)` FALSE statt TRUE, Typ „ordinal“ statt „numeric“, je Modell im Hauptplan und in den konstruierten Läufen sowie im gemeinsamen Fit.
    - Danach endet der Lauf mit „Maximum number of failures exceeded; quitting.“ `m2-7-robustness-pilot` lief im Gate nicht.
  - `tests/e2e`: QA-M1b-001 bis -004 rot, 16 Fehlschläge (`gate-tests.log` Z. 958–1070).
  - `tests/fuzz`: QA-M1b-005 und -006 rot, 12 Fehlschläge (Z. 1090–1183).
  - Kurzbefund: „437 Tests …; 9 fehlgeschlagen, 0 Fehler, 1 übersprungen“.
- **mutgate** (`gate-mutgate.log`, `reports/mutation/unmutated.json`):
  - geplant waren 1214 Mutanten in `R/fit.R` und `R/grr.R`;
  - der unmutierte Testlauf dauerte 118,2 s mit 355 Tests, davon 6 fehlgeschlagen und 1 abgebrochen;
  - abgebrochen ist `tests/testthat/test-validation-latent.R` („latent display retains significant digits and documentation traces every source“), fehlgeschlagen sind die sechs QA-Tests;
  - „Abbruch vor dem ersten Mutanten“: `reports/mutation/mutation.json` existiert nicht. Überlebende Mutanten lassen sich deshalb noch nicht benennen (E18).
- **Status error:** keiner. [INFRA] ist allein die Ursache der K-M2-6-Fehlschläge (E19).

## Eigene Prüfläufe

Alle am 31.10.2026, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26. Probeskripte lagen als `tests/acceptance/.probe-*` im eigenen Territorium und sind per `unlink()` gelöscht (Kontrolle: `list.files(..., pattern = "^[.]probe")` ergibt `character(0)`). Gezeigt ist der echte Output.

1. **K-M2-6 und K-M2-7 nach ADR-025 Nr. 4.** Aufruf `testthat::test_dir("tests/acceptance", filter = "^m2-[67]-", load_package = "source")`, `REPO_ROOT` gesetzt, `set_max_fails(Inf)`. Auszug:

   ```text
   ✔ |        383 | m2-6-evaluate [222.4s]
   ✔ |        375 | m2-7-robustness-pilot [88.3s]
   [ FAIL 0 | WARN 0 | SKIP 0 | PASS 758 ]
   M2-6/7 after ADR-025 Nr. 4: 20 tests; 0 failed blocks; 0 error blocks; 0 skipped; elapsed 312.4 s
   ```

   - Der Block mit erzwungenem Fehler und erzwungener Konvergenzwarnung bleibt grün (24 Erwartungen), der neue Orakel-Selbsttest ebenso (9 Erwartungen).
   - Auch der HTTP-Replay-Test von K-M2-7 ist grün (22 Erwartungen). Der Socket-Fehler aus PROGRESS (M1B-INFRA-SOCKET) betrifft nur die Builder-Sandbox (E22).
2. **QA-M1b-003 im Detail.** Daten wie `tests/e2e/test-m1b-qa-e2e.R:106–135`, Seed 20261031. Echte Ausgabe:

   ```text
   zero-drift blocks: singular = TRUE
       source     variance
   1     item 8.979282e-01
   2   prompt 9.718532e-01
   3    block 7.805441e-14
   4 Residual 1.000000e+00
   message: design is column rank deficient so dropping 1 coef
   confounded model/block: beta names = modelM2
       source     variance
   1     item 8.979282e-01
   2   prompt 9.718532e-01
   3    model 7.805441e-14
   4    block 0.000000e+00
   5 Residual 1.000000e+00
   ```

   Bei konfundierten Faktoren meldet `msa_fit()` still die Varianz 0 für einen nicht identifizierbaren Faktor.
3. **Ankerkopien.** `sha256sum` der Originale unter `reference/anchors/` und der Kopien unter `inst/validation/latent/anchors/`: Für ANK-06, ANK-21, ANK-25, ANK-28 und ANK-TOL sind die Hashes paarweise gleich, ebenso mit `inst/validation/numeric/anchors/ANK-TOL.json` (`dfa241fe…51fd`). `SOURCES.json` nennt dieselben Werte.

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **K-M1b-1:** `latent_reference_checks()` vergleicht wine mit dem direkten `clmm` für beide Links. Die Schranke ist ANK-TOL.engine_ordinal · σ²_TV der direkten Rechnung, der Rest kommt aus ANK-28. Getrennt davon steht die clmm2-Installationsprüfung mit beiden ANK-21-Varianzen (ADR-023 Nr. 9.1, Nr. 11.3).
- **K-M1b-2 und K-M1b-3:**
  - Szenarien, Seed-Regel `20261031 + j + 8(r − 1)`, RNG, Kennzahlen und MCSE folgen ADR-023 Nr. 1 bis 8 und 13, ebenso Abbruch, Session und Laufzeit.
    - MCSE(EmpSE) = EmpSE/√(2(n − 1)), MCSE(MSE) = sd(Fehlerquadrate)/√n, MCSE(RMSE) = MCSE(MSE)/(2 · RMSE), `derived_share` mit √(p(1 − p)/n_sim).
  - Die wahren Werte gleichen der Tabelle, etwa S-two-1 mit %GRR 72,569 und ICC 0,47337. Die Nachrechnung des Abnahmetests ist grün.
  - Kurzlaufzeiten nach PROGRESS: ordinal 105 s, binär 1,5 s, two_level 11 s.
  - Diagnosen der Kurzläufe: S-ord 17/80 Iterationslimit und 1/80 „singular convergence (7)“ (E21).
- **K-M1b-4:**
  - Fester Effekt, β̂²/2 über die Differenz der Designzeilen (ADR-026 Nr. 7), Warnung mit allen Teilen aus ADR-023 Nr. 9.5 und ohne AP1-Auslöser.
  - Eine Druckzeile je Quelle in beiden Methoden; die Hilfe nennt `two_level` und die Vignette.
  - Lücken bei konfundierten Faktoren und bei `singular`: E14.
- **K-M1b-5:**
  - π²/3 ohne Sonderfall (`R/fit.R:665`).
  - Die drei Vergleichsgrößen werden zur Laufzeit gerechnet, mit `ANK-TOL.rptr.live_tol`; die Installationsprüfung mit beiden ANK-25-Werten und `vignette_tol`.
- **K-M1b-6:** alle acht Prüfungen aus ACC-10 erfüllt, auch BL-81. Offen sind Lücken an angrenzenden Eingaben: `...` (E12, E13) und `levels` (E16).
- **K-M1b-7:**
  - Abschnitt, Dateiwahl über `system.file()`, `n_sim` aus der Datei, sechs signifikante Stellen vor `kable` (E11 der Planrunde).
  - Literalregel: Weder `validation.Rmd` noch die nachgeladenen Helfer enthalten ein Dezimalliteral eines Anker- oder Ergebniswerts. Die Simulationsparameter der Szenariotabelle sind Spec; der Logit-Rest steht als `pi^2 / 3`.
- **ADR-025 Nr. 1 bis 3 als Vertrag:**
  - **Nr. 1.4 (Trennung):** erfüllt. Die Zeilen der ICC-Prüfung tragen „ANK-28 / ANK-TOL.rptr.live_tol“, die Installationsprüfung „ANK-25 / ANK-TOL.rptr.vignette_tol“ (`reference_checks.R:171–181`). Der Text sagt „They are installation checks, not reference values for `ICC_items`.“ (`validation.Rmd:176–177`). Keine Zeile stellt ICC_items einem ANK-25-Wert gegenüber.
  - **Nr. 1.5:** `nboot = 0`, `npermut = 0`.
  - **Nr. 2.3:** Literalregel einschließlich Helfer erfüllt (`test-validation-latent.R:123–155` prüft sie, siehe aber E15).
  - **Nr. 3:** `msa_mer_converged()` und `msa_clmm_converged()` folgen der Regel. Fehlende oder unlesbare Codes ergeben FALSE. Der tatsächliche Optimierer folgt aus dem Rechenweg; Unit-Tests belegen ucminf mit einem Term sowie nlminb bei mehreren Termen und bei `useMatrix`. Der numerische Pfad warnt nicht zusätzlich.

### API-Diff

- **Schnittstellen:** keine neuen Exporte, Argumente oder Vorgaben; der API-Snapshot (`test-m0-api-snapshot.R`, 259 Erwartungen) ist grün.
- **Neue Rückgabefelder:** `msa_fit()$converged` und `msa_grr()$derived`; `msa_fit()$derived` gab es schon. Zusätzlich ändert sich die Druckausgabe. Beides ist nach docs/01 §4 ohne ADR zulässig.
- **Abhängigkeiten:** nur neue Suggests (`parallel`, `performance`, `rptR`; ACC-13, E6); Imports unverändert.

### Tests: entkernt, eingefroren, hart

- **Geänderte Bestandstests** (Diff aus dem BUILD-Log):
  - `test-fit-grr.R` und `test-fit-rework-inputs.R` erwarten zusätzlich die neuen Pflichtwarnungen. Keine Erwartung fehlt.
  - In `test-fit-rework-inputs.R` bekommt die `clmm`-Attrappe die Felder, die `msa_clmm_converged()` liest; die Schwellenprüfung (0, 1e-6, 1) bleibt.
  - `test-grr-rework.R` friert die eigene Druckausgabe ein. Zulässig: Die neue Zeile ist der Wortlaut aus K-M1b-4 („range method, see ?msa_fit“), und ADR-026 Nr. 9 kennzeichnet die Momentaufnahme.
- **Neue Tests:** Sie prüfen Verhalten an echten Engines und gegen unabhängige Größen:
  - direkte `clmm`- und `glmer`-Fits auf den bereinigten Zeilen;
  - β̂²/2 aus `model$beta` und als Stichprobenvarianz bei Summenkodierung;
  - %GRR und ICC aus den Komponenten nach Formelsammlung §3;
  - lme4-Meldungen des direkten `lmer` als Orakel.
  - Wörtliche Warnungstexte sind Vertragstexte des Plans, keine Referenzwerte.
- **Harte Erwartungswerte:** keine abgetippten Referenzwerte; Toleranzen kommen aus ANK-TOL.
- **ADR-026 Nr. 8:** Die Invarianztests verwenden ausdrücklich engere Optimierer-Steuerung, die Toleranz bleibt. Bewertung in E20 und ADR-027 Nr. 6.

### Konfiguration, Daten, Golden

- **Konfiguration:** Keine Gate-, Schwellen- oder Lint-Regel ist gelockert.
- **Daten:**
  - Die neun `_check_`-Dateien sind echte Läufe; die Abnahme rechnet sie byte-identisch nach. Ein Vollauf liegt nicht im Repository.
  - Die Ankerkopien sind byte-identisch (Prüflauf 3).
  - `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Öffentliches Repository:** In den neuen Paketdateien steht kein privater Bezug; die Sessiondateien nennen nur `/tmp`-Pfade und die Zeitzone.

## Einwände (Runde 1)

- [E12] (blocking) Gate tests (`tests/e2e/test-m1b-qa-e2e.R`, QA-M1b-001, `gate-tests.log` Z. 958–976); `?msa_boot` (`R/grr.R:141`: „Available for numeric and binary outcomes (lme4 models).“; `:153–154`: „An explicit fitting control passed to [msa_fit()] remains the model's refit control.“); ADR-027 Nr. 1.3 — **Befund:** Der binäre Zweig ruft `lme4::glmer(form, data = dat, family = …, ...)` unausgewertet auf (`R/fit.R:263`). `fit$model@call` speichert deshalb `control = ..1`. `msa_boot()` und `lme4::refit()` scheitern mit „the ... list contains fewer than 1 element“, im selben Rahmen und aus einer Hilfsfunktion. Der ordinale Zweig (`:262`) speichert dieselben Platzhalter. — **Vorschlag:**
  - `...` wie im numerischen Durchreichweg vorab auswerten (`R/fit.R:241–253`) und die ausgewerteten Argumente samt `data` und `family` im gespeicherten Aufruf ablegen, für `glmer` und `clmm`.
  - Unit-Test: `msa_boot()` auf einem binären Fit mit `control =` im selben Rahmen und aus einer Funktion; die gespeicherte Steuerung gleicht der übergebenen.
- [E13] (blocking) Gate tests (QA-M1b-002, `gate-tests.log` Z. 978–1034); `?msa_fit` (`R/fit.R:47–50`: „Expressions in `subset`, `weights` and `offset` can use the internal columns … Row-based arguments refer to the rows remaining after missing or unreadable responses are removed.“; `:104–105`: „All returned data and study counts describe the retained observations.“); K-M1b-6 („… und in `n$observations` gezählt“); docs/01 §2 Nr. 4; ADR-027 Nr. 1.1–1.2 — **Befund:** Nur der numerische Zweig wertet `subset`, `weights` und `offset` in der Datenmaske aus und gleicht `dat` mit dem Modellrahmen ab (`R/fit.R:244–258`).
  - Ordinal und binär endet `subset = item != "I01"` mit „object 'item' not found“.
  - Ein Zeilenvektor schätzt das Modell auf 198 Beobachtungen und 11 Items, `fit$n` und `fit$data` melden aber 216 und 12. Das ist eine still falsche Zählung.
  — **Vorschlag:**
  - Zeilenargumente vor dem Formelaufbau auswerten und anwenden, `weights` und `offset` ausrichten. Dann bestimmen Stufenregel (eine Stufe, zwei Stufen), Formel, `derived`, `data` und `n` dieselben Zeilen wie `nobs(model)`.
  - Unit-Tests für beide Typen mit Ausdruck und Zeilenvektor, Vergleich mit dem direkten Engine-Fit auf den ausgewählten Zeilen (ANK-TOL.engine_ordinal · σ²_TV).
- [E14] (blocking) Gate tests (QA-M1b-003, `gate-tests.log` Z. 1036–1056); docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); K-M1b-4; K-M1b-6 („`singular`/Konvergenz im Objekt vermerkt“); ADR-027 Nr. 2 und 3 — **Befund:**
  1. `singular` zählt im ordinalen Zweig die abgeleiteten Komponenten mit (`R/fit.R:301` nach `:292–296`). Zwei Blöcke ohne Drift ergeben `singular = TRUE` bei inneren Zufallseffekten (Prüflauf 2).
  2. Konfundierte Zwei-Stufen-Faktoren: `clmm` verwirft einen Koeffizienten, und `R/fit.R:288` summiert nur über `names(model$beta)`. Der nicht identifizierbare Faktor erhält still die Varianz 0 (Prüflauf 2).
  3. Ein Zufallsterm mit höchstens zwei beobachteten Stufen erreicht `clmm` (`R/fit.R:221–227` prüft nur die Haupteffekte) und endet mit der rohen Assertion „all(sapply(gfl, nlevels) > 2) is not TRUE“.
  — **Vorschlag:**
  - zu 1: `singular` ordinal nur über die `clmm`-Komponenten bestimmen, die bestehende Schwelle bleibt;
  - zu 2 und 3: vor dem Fit den Rang des festen Designs der Zwei-Stufen-Faktoren und die Stufenzahl jedes Zufallsterms prüfen und benannt abbrechen; nach LESSONS für die ganze Klasse, nicht nur für den gemeldeten Fall.
  - Unit-Tests: Blöcke ohne Drift (Zufallseffekte gegen direktes `clmm`); konfundierte Modelle und Blöcke; Wechselwirkung konfundierter Faktoren.
  - Danach die Kurzläufe neu erzeugen, weil sich die Spalte `singular` ändern kann (ADR-023 Nr. 1.5).
- [E15] (blocking) Gate mutgate (`gate-mutgate.log` Z. 4: „rot: tests/testthat/test-validation-latent.R: latent display retains significant digits and documentation traces every source [abgebrochen]“); Gate tests (QA-M1b-004, `gate-tests.log` Z. 1058–1069); ADR-027 Nr. 7; `IMPLEMENTATION-RULES.md`, Projekt-Amendment [ADR-027] — **Befund:** `tests/testthat/test-validation-latent.R:129–132` sucht `validation.Rmd` nur über `system.file("doc", …)` und `test_path("..", "..")`. In der Paketkopie des Mutationslaufs gibt es kein `vignettes/`, obwohl `REPO_ROOT` gesetzt ist. `expect_true(file.exists(rmd))` schlägt fehl, danach bricht `normalizePath(…, mustWork = TRUE)` im Helfer ab. Der unmutierte Vorlauf ist rot, kein Mutant läuft. — **Vorschlag:**
  - den Pfad wie `test-validation-numeric.R:236–238` auflösen: `validation_find_repo()`, sonst `system.file("doc", "validation.Rmd", mustWork = TRUE)`;
  - Erwartungen, Quellenliste und Literalprüfung unverändert lassen;
  - mit dem QA-Test (Paketkopie mit `REPO_ROOT`) und dem regulären Lauf belegen.
  - Diese Änderung ist nach ADR-027 Nr. 7 Builder-Arbeit im Rework und keine Behebung „an Tests“: Der Test bricht vor seinen Erwartungen ab, nichts wird abgeschwächt.
- [E16] (blocking) Gate tests (QA-M1b-005, `gate-tests.log` Z. 1090–1151); `?msa_fit` (`R/fit.R:37–40`: „For ordinal outcomes: the labels in scale order. For binary outcomes given as labels: two distinct, non-missing labels, whose second element is the event. Labels require this explicit argument …“); PLAN-UPDATE, Schnittstellen („Bei Labels bestimmt allein das validierte Argument `levels` die Kodierung“); docs/01 §2 Nr. 4; ADR-027 Nr. 4 — **Befund:**
  - Ordinales `levels` wird nicht geprüft: NA und `""` laufen durch und stehen in `fit$levels`; Duplikate enden mit dem R-internen Fehler „factor level [3] is duplicated“; ein Label oder keines endet mit Meldungen ohne Bezug auf `levels`.
  - Binär werden leere Labels angenommen.
  - Bei numerischen oder logischen Werten ignoriert der binäre Zweig ein übergebenes `levels` (`R/fit.R:182–183` vor `:184`). `levels = c("no", "yes")` auf 0/1 läuft still ohne Ausschluss, numerische 1/2 mit `levels = c("1", "2")` enden mit „Binary values must be 0 or 1.“, als Zeichen gelingt derselbe Fit.
  — **Vorschlag:**
  - `levels` vor jeder Datenprüfung validieren, ordinal mit einer Meldung, die „levels“ enthält;
  - die bestehende binäre Meldung mit „two distinct, non-missing labels“ beibehalten (`test-fit-latent.R:11–13`) und um leere Labels erweitern;
  - bei gegebenem binären `levels` über `as.character(value)` kodieren, unabhängig vom Speichertyp;
  - ohne `levels` bleibt K-M1b-6 („binäre Werte außerhalb {0, 1} → Fehlermeldung“).
  - Unit-Tests einschließlich der Invarianz gegenüber dem Speichertyp (gleiche `data$y` für numerisch, logisch und Zeichen).
- [E17] (blocking) Gate tests (QA-M1b-006, `gate-tests.log` Z. 1153–1183); ADR-026 Nr. 5 („`sim_merge()` verlangt … gültige Seeds und Kennzahlen“); PLAN-UPDATE, Vignette („Eine vorhandene fehlerhafte Datei führt zum benannten Fehler.“); ADR-023 Nr. 2.3 und Nr. 4.4; ADR-027 Nr. 5 — **Befund:**
  - `sim_merge()` (`simulation_helpers.R:341–350`) prüft weder die Designspalten noch die logischen Flags; `items = 999` wird still zusammengeführt.
  - `latent_read_results()` (`reference_checks.R:197–203`) nimmt `empse` < 0, `derived_share` > 1 und `seed` = −10,5 an.
  - QA schlägt nonblocking vor. Herabgestuft wird nicht: Der Test hält das Gate rot, die Erwartungen decken sich mit dem eigenen Vertrag des Builders (ADR-026 Nr. 5), und die Prüfungen sind klein.
  — **Vorschlag:** Prüfungen nach ADR-027 Nr. 5 ergänzen, je ein synthetischer Negativfall im Unit-Test.
- [E18] (blocking) Gate mutgate (`gate-mutgate.log` Z. 3 und 11–12: „Abbruch vor dem ersten Mutanten: Schon unmutiert scheitern 7 Tests“; `reports/mutation/unmutated.json`) — **Befund:**
  - Kein Mutant ist gelaufen; `reports/mutation/mutation.json` fehlt. Überlebende Mutanten (Survived, NoCoverage) mit Zeile und `mutatorName` lassen sich daher noch nicht benennen.
  - Die sieben roten Tests des Vorlaufs sind die QA-Tests aus E12 bis E14, E16 und E17, der QA-Test zu E15 und `test-validation-latent.R` (E15).
  — **Vorschlag:**
  - E12 bis E17 so beheben, dass der unmutierte Vorlauf über `tests/testthat`, `tests/acceptance` (ohne `MUT_TEST_EXCLUDE`), `tests/e2e` und `tests/fuzz` grün ist.
  - Der neue Code in `R/fit.R` (Konvergenzhelfer, Binärprüfung, Kontrast, Warnungen, Identifizierbarkeit) braucht Tests, die Mutanten erkennen. Über die Schwelle entscheidet der nächste Gate-Lauf.
  - Äquivalenzanträge nur einzeln mit Begründung in `MUT-EQUIV.json` (SCHEMA.md).
- [E19] (minor) [INFRA] Gate tests (`test-m2-6-evaluate.R`, 13 Fehlschläge); ADR-025 Nr. 4; E9 und E10 der Planrunde — **Befund:** Das Abnahmeorakel wertete jede Warnung als Rückfallauslöser. In dieser Phase angepasst:
  - `acc_m2_convergence_warning()` und `acc_m2_with_conditions()` in `tests/acceptance/setup-m2.R`;
  - neuer Selbsttest in `test-m2-6-evaluate.R` mit den Meldungen aus ADR-006 Nr. 4.2, den Pflichtwarnungen von K-M1b-4 und K-M1b-6 und der Optimiererumstellung.
  - Die Regel ist vom Produktcode unabhängig. Sonst ändert sich nichts; der Block mit erzwungenem Fehler und erzwungener Konvergenzwarnung bleibt unverändert.
  - K-M2-6 und K-M2-7 sind in meinem Lauf grün (Prüflauf 1). Das nächste Gate bestätigt es.
  — **Vorschlag:** Keine Builder-Arbeit. `R/acmg.R` bleibt unverändert (ADR-025 Nr. 4.5). BL-90.
- [E20] (minor) ADR-026 Nr. 8; PROGRESS M1b, M1B-NUM-01; docs/01 §2 Nr. 5; ADR-027 Nr. 6 — **Befund:** Mit den Vorgabe-Optimierern weichen latente Fits nach Zeilenumkehr, Umbenennung und Ereignistausch bis 8,1e-6 · σ²_TV ab; die Toleranz ist 1e-6 · σ²_TV. Die Unit-Tests belegen die Invarianz mit engerer Steuerung bei unveränderter Toleranz. Das wird nach ADR-027 Nr. 6 angenommen: Der Vorgabepfad muss gleich den Vorgabeaufrufen der Engines bleiben (K-M1b-1, K-M1b-5). — **Vorschlag:** In `?msa_fit` einen Satz ergänzen, dass ordinale und binäre Schätzer nur bis zur Optimierertoleranz der Engines von Zeilenreihenfolge und Stufennamen unabhängig sind. Kein Eingriff in den Vorgabepfad. BL-91.
- [E21] (minor) K-M1b-2; K-M1d-7; docs/01 §2 Nr. 3 („Berichtet wird, was herauskommt …“); `inst/validation/sim/ordinal_recovery_check_session.txt` — **Befund:** Im Kurzlauf enden 17 von 80 S-ord-Wiederholungen mit „iteration limit reached without convergence (10)“, eine mit „singular convergence (7)“; alle sind `converged = FALSE` mit endlichen Schätzern. Nach ADR-023 Nr. 10.9 und 13.2 ist das spec-gemäß (nlminb-Erfolg nur Code 0, Vorgabesteuerung). — **Vorschlag:** keine Änderung in M1b. Betreiber und M1d berichten im Vollauf den Nichtkonvergenzanteil je Szenario, und K-M1d-7 bewertet die Schätzer mit und ohne diese Wiederholungen. BL-92.
- [E22] (minor) [INFRA] PROGRESS M1b, M1B-INFRA-SOCKET und M1B-INFRA-CLOCK; BL-86 — **Befund:** In der Builder-Sandbox ist `socket()` gesperrt; der HTTP-Replay-Test von K-M2-7 endet dort mit einem Fehler. In meinem Lauf ist er grün (Prüflauf 1); im Gate lief K-M2-7 in Runde 1 nicht (Abbruch nach `m2-6-evaluate`), das nächste tests-Gate entscheidet. Die NOTE „Unable to verify current time“ betrifft nur den lokalen Check, das lint-Gate ist OK. — **Vorschlag:** keine Builder-Arbeit; Stand-Vermerk in BL-86.
- [E23] (minor) `gate-tests.log` Z. 546–571 (zwei Warnungen in `test-m1b-4-two-levels.R:41–42`) — **Befund:** Der Abnahmehelfer ruft `lme4::nobars()` und `lme4::findbars()` auf, die lme4 2.0.6 nach `reformulas` verschoben hat. Kein Fehlschlag, kein Produktbezug. — **Vorschlag:** Der Reviewer stellt den Helfer bei der nächsten Abnahmepflege um, etwa auf `reformulas`, sobald es deklariert ist. BL-93.

## Hinweise für REWORK (Runde 2)

- **Reihenfolge:**
  1. Fit-Eingaben (E12, E13, E16) und Identifizierbarkeit (E14) als eine Klasse im ordinalen und binären Zweig umsetzen, mit gemeinsamem Pfad für `...`, Zeilenauswahl und Stufenregel.
  2. Danach `inst/validation/` (E17) und den Testpfad (E15).
- **Bestehende Meldungen beibehalten, die Tests prüfen:**
  - „Binary values must be 0 or 1.“;
  - „Binary `levels` must contain two distinct, non-missing labels.“ (darf erweitert werden, muss aber „two distinct, non-missing labels“ enthalten);
  - „At least three items are needed for ordinal outcomes.“;
  - die Verwerfungs- und Range-Warnungen. Neue Meldungen dürfen keinen AP1-Rückfallauslöser enthalten, außer bei echter Nichtkonvergenz.
- **Kurzläufe:** Nach der letzten Änderung an `msa_fit()`, `msa_grr()` oder den Studienhelfern alle neun `_check_`-Dateien mit dem endgültigen Paketstand neu erzeugen (ADR-023 Nr. 1.5); die Implementierungs-Hashes der Sessions ändern sich mit.
- **Belege:** echter Output der gezielten Läufe in `REWORK-NOTES.md`, je Befund-ID. Zusätzlich die vollständigen QA-Verzeichnisse und eine Paketkopie wie im QA-Test zu QA-M1b-004.
- **Abnahme- und QA-Tests:** unverändert lassen; die Orakelanpassung zu E19 ist bereits geschehen.

## Backlog

- **Neu:**
  - BL-90: E19, ADR-025 Nr. 4 umgesetzt, Gate-Bestätigung ausstehend;
  - BL-91: E20, Invarianz der Vorgabepfade latenter Fits;
  - BL-92: E21, Nichtkonvergenz im S-ord-Vollauf;
  - BL-93: E23, `nobars`/`findbars` im Abnahmehelfer.
- **Ergänzt:** BL-86 um den Stand-Vermerk zu E22.
- Die blocking-Befunde stehen nicht im Backlog.
