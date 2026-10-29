# QA — M1a (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M1a` · Stand: 29.10.2026 · Fester, geloggter Seed aller QA-Tests: `20261029` (`set.seed(20261029L)`).

## Geprüfter Kontext

- Rahmen und Verträge: `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`.
- Meilenstein-Spezifikation und Entscheidungen: `orchestrator/handoff/M1a/CRITERIA.json` (`K-M1a-1` bis `K-M1a-7`, `ACC-1` bis `ACC-18`), `docs/02-statistikkern.md`, `docs/01-fachspezifikation.md`, `docs/decisions/ADR-012-plattformunabhaengige-tests-reml-toleranz.md`, `docs/decisions/ADR-016-betreiberentscheidungen-acceptance-m1a.md` bis `docs/decisions/ADR-021-m1a-validierungsressourcen.md`, `orchestrator/handoff/M1a/PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `PROGRESS.md`, `BACKLOG.md`.
- Gate-Stand und Logs: `orchestrator/state/M1a/gates.json`, `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log`. Visuelle Artefakte unter `orchestrator/state/M1a/shots/` (leer; in M1a nicht gefordert).
- Geänderte Produkt-, Dokumentations- und Testdateien seit `plan/M1a`: `R/fit.R`, `R/grr.R`, `DESCRIPTION`, `man/msa_fit.Rd`, `man/msa_grr.Rd`, `man/msa_boot.Rd`, `NEWS.md`, `data-raw/make_validation_numeric.R`, `inst/extdata/nist-strd-anova_2026-10-22/`, `inst/validation/numeric/`, `vignettes/validation.Rmd`, `tests/testthat/test-fit-numeric.R`, `tests/testthat/test-grr-numeric.R`, `tests/testthat/test-validation-numeric.R`, `tests/testthat/helper-validation-numeric.R`, `tests/testthat/test-acmg-evaluate.R`.

---

## Befunde

### QA-M1a-001 — `msa_boot()` bricht bei jedem über den expliziten `...`-Durchreichweg (`msa_fit(..., control = ...)`) erzeugten Fit mit `"the ... list contains fewer than 1 element"` ab

- **ID:** `QA-M1a-001`
- **Reproduzierender Test:** `tests/e2e/test-m1a-qa-e2e.R` (`test_that("QA-M1a-001: msa_boot succeeds on fits created with explicit control or lme4 arguments passed via ... (seed = 20261029)", ...)`, Zeilen 4–34)
- **Seed:** `20261029`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1a-1, K-M1a-6; `docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md` Nr. 2.2 und Nr. 2.5 („Der Unterschied zwischen Vorgabepfad und explizitem `...`-Pfad wird in `?msa_fit` dokumentiert und direkt gegen `lme4::lmer` geprüft.“); `docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md` („Explizite `...`-Aufrufe gehen unverändert an `lme4::lmer()` und behalten ihre Steuerung.“); `man/msa_boot.Rd` („An explicit fitting control passed to `msa_fit()` remains the model's refit control.“); `orchestrator/handoff/M1a/PLAN-UPDATE.md` [E4], [E8].
- **Beobachtetes Verhalten:**
  In `R/fit.R` (Zeile 172) ruft der explizite Pfad direkt `lme4::lmer(form, data = dat, REML = TRUE, ...)` (bzw. `lme4::glmer(form, data = dat, family = ..., ...)` für `type = "binary"`) auf. Da `...` innerhalb von `msa_fit()` an `lmer()` weitergereicht wird, zeichnet `match.call()` in `lme4::lmer()` im gespeicherten Modellaufruf `fit$model@call` für jedes über `...` übergebene Argument das Promise-Symbol `..1` (bzw. `..2` usw.) auf:
  ```r
  lme4::lmer(formula = y ~ 1 + (1 | item) + (1 | prompt), data = dat, REML = TRUE, control = ..1)
  ```
  Wird das erzeugte `msa_fit`-Objekt anschließend im End-to-End-Fluss an `msa_boot(fit, nsim = 3, seed = 20261029L)` übergeben, wertet `lme4::bootMer()` intern `eval.parent(x@call$control)` außerhalb eines `...`-Kontexts aus und bricht sofort mit dem Laufzeitfehler `Error: the ... list contains fewer than 1 element` ab — obwohl `?msa_boot` (`man/msa_boot.Rd`) und `R/grr.R` ausdrücklich zusichern: „An explicit fitting control passed to `msa_fit()` remains the model's refit control.“
- **Erwartetes Verhalten:**
  `msa_fit()` muss beim direkten Aufruf von `lme4::lmer()` / `lme4::glmer()` über `...` (oder durch `do.call` bzw. Ersetzen der `..n`-Symbole/Speichern eines selbsttragenden `model@call` analog zu Zeile 424 in `msa_numeric_fit()`) sicherstellen, dass `fit$model@call` keine unaufgelösten `..1`-Promises oder verschwundenen lokalen Variablenreferenzen enthält, sodass `msa_boot(fit)` auf explizit gesteuerten Fits fehlerfrei durchläuft.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1a-002 — `msa_fit()` mit `subset` oder `NA`-enthaltenden `weights`/`offset` in `...` schlägt bei unquotierten Spaltenausdrücken fehl und liefert bei Zeilenfilterung durch `lme4::lmer()` inkonsistente `fit$data`, `fit$n` und `fit$numerics$input_rows`

- **ID:** `QA-M1a-002`
- **Reproduzierender Test:** `tests/e2e/test-m1a-qa-e2e.R` (`test_that("QA-M1a-002: msa_fit with subset or NA-dropping lme4 arguments keeps fit$data, fit$n and input_rows consistent with fit$model (seed = 20261029)", ...)`, Zeilen 36–69)
- **Seed:** `20261029`
- **Spezifikations-/ADR-Bezug:** `docs/01-fachspezifikation.md` §2 Nr. 4 („nie stillschweigend eine falsche Zahl“); `docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md` Nr. 2.2 und Nr. 2.4; `orchestrator/handoff/M1a/PLAN-UPDATE.md` [E4], [E5] (`weights`, `offset`, `subset`, `start` behalten den Durchreichweg; `fit$data`, `n` und `numerics$input_rows` beschreiben die analysierten Zeilen konsistent zum Modell).
- **Beobachtetes Verhalten:**
  1. Wird `subset` als unquotierter Ausdruck wie `msa_fit(runs, type = "numeric", interactions = FALSE, subset = item != "I001")` übergeben, wertet `lme4::lmer(form, data = dat, REML = TRUE, ...)` sein `subset`-Argument via Non-Standard Evaluation gegen die Umgebung von `msa_fit()` aus, findet dort `..1` und versucht `item != "I001"` im Aufrufer-Frame statt in `dat` auszuwerten (`Error: object 'item' not found`). (Im Unit-Test `test-fit-numeric.R` Zeile 165 wurde dies nur deshalb verdeckt, weil `subset = seq_len(nrow(r)) > 2` keine Spalte von `dat` referenziert.)
  2. Filtert `lme4::lmer()` über `subset` (z. B. `subset = which(runs$item_id != "I001")`) oder über `na.omit` bei `NA` in `weights`/`offset` Zeilen oder ganze Faktorstufen heraus, berechnet `msa_fit()` in `R/fit.R` (Zeile 176 und 189–196) `fit$data`, `fit$n` (`items`, `prompts`, `models`, `blocks`, `observations`, `reps_per_cell`) und `fit$numerics$input_rows` weiterhin ungefiltert aus `dat` vor dem `lmer`-Aufruf. Im Testfall (6 Items à 4 Beobachtungen = 24 Zeilen, Item `I001` per `subset` bzw. `weights = NA` ausgeschlossen) hat `fit$model` 20 Beobachtungen und 5 Items (`nobs(fit$model) == 20`, `ngrps(fit$model)[["item"]] == 5`), während `fit$n$observations` `24`, `nrow(fit$data)` `24`, `length(fit$numerics$input_rows)` `24` und `fit$n$items` `6` meldet.
- **Erwartetes Verhalten:**
  `subset` in `...` wird sauber an `lmer` übergeben, und `fit$data`, `fit$n` sowie `fit$numerics$input_rows` spiegeln exakt die tatsächlich vom Modell analysierten Beobachtungen und Faktorstufen wider.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1a-003 — `msa_fit(type = "numeric")` stürzt bei identischen Replikaten (Restvarianz null) in mehrfaktoriellen balancierten sowie in unbalancierten Designs mit `Matrix::Cholesky`-Fehler (`leading principal minor ... is not positive`) und CHOLMOD-Warnungen statt mit der benannten Restvarianz-Diagnose ab

- **ID:** `QA-M1a-003`
- **Reproduzierender Test:** `tests/e2e/test-m1a-qa-e2e.R` (`test_that("QA-M1a-003: multi-factor and unbalanced designs with zero residual variance fail with named residual-variance diagnostic without CHOLMOD warnings (seed = 20261029)", ...)`, Zeilen 71–122)
- **Seed:** `20261029`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1a-6; `docs/01-fachspezifikation.md` §2 Nr. 4; `docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md` („Verschwindet im Modell die Restvarianz, bricht der Fit wegen nicht darstellbarer `theta = sigma_j / sigma_e` benannt ab.“); `man/msa_fit.Rd` („Constant numeric responses, non-finite values, non-identifiable components and a degenerate residual variance produce named errors.“); `orchestrator/handoff/M1a/PLAN-UPDATE.md` [E7] und Tabelle „Randfälle“ („Ist das restringierte Optimum ohne positive Restvarianz und damit ohne endliches darstellbares Theta, benannter Fehler über die degenerierte Restvarianz“).
- **Beobachtetes Verhalten:**
  1. **Mehrfaktoriell balanciert mit identischen Replikaten:** In `msa_numeric_balanced()` (`R/fit.R` Zeile 217–223) wird `residual <- dat$y - grand - Reduce(`+`, effects)` über Fließkomma-Randmittel berechnet und anschließend exakt auf `if (residual_v == 0)` geprüft (während der Einweg-Fall in Zeile 219 gesondert `dat$y - stats::ave(...)` nutzt). Bei einem 2-Wege-Plan (`4 items x 2 prompts x 2 reps`, `interactions = TRUE`) mit identischen Replikaten je Zelle und gewöhnlichen Dezimalwerten (`1.1, 2.3, ...`) hinterlässt die Subtraktion der orthogonalen Effekte `residual_v = 7.17e-33` statt `0`. Dadurch greift `if (residual_v == 0)` nicht; außerdem entsteht durch Rundung eine minimal negative Haupteffekt-Varianz, sodass `msa_numeric_balanced()` `NULL` zurückgibt und an `analytic_reml` übergibt.
  2. **Unbalanciert (oder `analytic_reml`-Pfad) mit identischen Replikaten:** Im allgemeinen Pfad (`msa_numeric_optimize()`) divergiert `lambda = variance / residual_v` gegen $+\infty$ (`~1e30`), bis `B = I + D * cross * D` in `msa_numeric_reml()` (`R/fit.R` Zeile 281) numerisch singulär wird und `Matrix::Cholesky(B)` mit `CHOLMOD warning 'not positive definite'` sowie dem ungefangenen internen Matrix-Fehler `Error in .local(A, ...) : leading principal minor of order ... is not positive` abstürzt — statt die vorgesehene benannte Fehlermeldung (`"Degenerate numeric model: residual variance is zero."` bzw. `"Degenerate numeric model: no positive residual variance."`) auszugeben.
- **Erwartetes Verhalten:**
  Sowohl im balancierten Mehrfaktorfall als auch im unbalancierten `analytic_reml`-Pfad muss eine verschwindende Restvarianz (exakte Anpassung durch die Zufallseffekte ohne positive Reststreuung) zuverlässig erkannt und ohne CHOLMOD-Warnungen mit dem benannten Fehler über die degenerierte Restvarianz abgebrochen werden.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1a-004 — `msa_fit(type = "numeric")` verletzt bei subnormalen Varianzskalen (`1e-161`) `ANK-TOL.invariance` um > 9 %, warnt bei `"NaN"`-Strings inkonsistent zu numerischem `NaN` und akzeptiert `NA` in Gruppierungsspalten auf dem expliziten `...`-Pfad

- **ID:** `QA-M1a-004`
- **Reproduzierender Test:** `tests/fuzz/test-m1a-qa-fuzz.R` (`test_that("QA-M1a-004: msa_fit handles subnormal variance scales cleanly and rejects malformed numeric/grouping inputs consistently (seed = 20261029)", ...)`, Zeilen 4–56)
- **Seed:** `20261029`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1a-6 (`ANK-TOL.invariance`); `docs/01-fachspezifikation.md` §2 Nr. 4; `docs/decisions/ADR-020-m1a-numerischer-reml-abschluss.md` („Eingaben mit Unter- oder Überlauf der Modellvarianz auf Originalskala werden benannt abgelehnt.“); `orchestrator/handoff/M1a/PLAN-UPDATE.md` [E6], [E7].
- **Beobachtetes Verhalten:**
  1. **Denormale Varianzskala auf Originalskala (`1e-161`):** Werden die Messwerte eines Studienplans mit `1e-161` skaliert, liegen die Varianzkomponenten auf Originalskala bei $\approx 10^{-322}$ im subnormalen Bereich nahe `.Machine$double.xmin * .Machine$double.eps` ($4.94 	imes 10^{-324}$), in dem IEEE-754-Doubles nur noch wenige signifikante Bits besitzen. `R/fit.R` (Zeile 436) prüft lediglich `stats::sigma(model) <= 0` statt auf subnormalen Präzisionsverlust (`< .Machine$double.xmin`), gibt scheinbar erfolgreich ein `msa_fit`-Objekt zurück und verletzt dabei die Skalierungsinvarianz um `9.05 %` von $\sigma^2_{	ext{TV}}$ (Erwartung: entweder benannter Fehler wegen nicht darstellbarer Varianz auf Originalskala wie bei `1e-162` oder Einhaltung von `ANK-TOL.invariance = 1e-6`).
  2. **Inkonsistenz zwischen numerischem `NaN` und `"NaN"` als Zeichenkette:** In `R/fit.R` (Zeile 98) entfernt `input_rows <- which(!is.na(d$value))` ein numerisches `NaN` stillschweigend als fehlenden Wert ohne Warnung (`is.na(NaN)` ist `TRUE`), während bei Zeichenketteneingabe (`d$value = "NaN"`, wie sie `msa_run()` in `value = as.character(val)` speichert) `is.na("NaN")` `FALSE` ist, `as.numeric("NaN")` `NaN` liefert und Zeile 107 fälschlich warnt: `1 value(s) could not be interpreted as numbers and were dropped.`
  3. **Fehlende Werte (`NA`) in Gruppierungsfaktoren auf dem `...`-Pfad:** Während `msa_numeric_fit()` in Zeile 382 `if (anyNA(dat)) stop("Numeric grouping factors must not contain missing values.")` prüft, fehlt diese Prüfung vor dem `switch(type, ...)` in `msa_fit()` (Zeile 166). Enthält `item_id`, `prompt_id`, `model_id` oder `block` ein `NA` und wird `control = lme4::lmerControl()` übergeben (oder `type = "ordinal"` / `"binary"` gewählt), läuft der Fit ohne Fehler durch, verwirft die Zeilen stillschweigend in `lme4` und erzeugt ein inkonsistentes `msa_fit`-Objekt (`n$observations = 20`, `nobs(model) = 18`).
- **Erwartetes Verhalten:**
  1. Varianzen im subnormalen Unterlaufbereich auf Originalskala werden wie `sigma <= 0` mit `"Numeric model variance is not representable on the original scale."` abgelehnt (sofern sie `ANK-TOL.invariance` nicht halten können).
  2. Numerisches `NaN` und Zeichenketten-`"NaN"` werden konsistent behandelt.
  3. Fehlende Werte (`NA`) in den Gruppierungsspalten (`item`, `prompt`, `model`, `block`) werden in `msa_fit()` vor der Verzweigung in die Schätzpfade einheitlich mit benanntem Fehler abgewiesen.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1a-005 — `msa_grr()` validiert `threshold` nicht und `validation_verify_resources()` prüft in `SOURCES.json` weder die `datasets`-Sektion noch ungelistete Dateien in `anchors/`

- **ID:** `QA-M1a-005`
- **Reproduzierender Test:** `tests/fuzz/test-m1a-qa-fuzz.R` (`test_that("QA-M1a-005: msa_grr validates threshold argument and validation_verify_resources checks NIST dataset manifest and unlisted anchor files (seed = 20261029)", ...)`, Zeilen 58–94)
- **Seed:** `20261029`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1a-5, K-M1a-7; `docs/01-fachspezifikation.md` §2 Nr. 4; `docs/decisions/ADR-017-m1a-reviewer-auslegungen.md` Nr. 7.2 und Nr. 7.3; `docs/decisions/ADR-021-m1a-validierungsressourcen.md`.
- **Beobachtetes Verhalten:**
  1. `msa_grr()` (`R/grr.R` Zeile 47–65) prüft das Argument `threshold` nicht:
     - Bei vertauschten Schwellen `threshold = c(30, 10)` (`threshold[1] > threshold[2]`) oder negativen Schwellen `c(-5, 30)` liefert `msa_grr()` ohne Fehlermeldung ein falsches `verdict`.
     - Bei `threshold = "invalid"` wird durch R-Typkoerzion `crit < "invalid"` lexikographisch ausgewertet und `"acceptable"` zurückgegeben.
     - Bei `threshold = c(10)` (Länge 1) oder `threshold = c(NA_real_, 30)` stürzt `if (crit <= threshold[2])` mit `Error: missing value where TRUE/FALSE needed` ab.
  2. `validation_verify_resources()` in `inst/validation/numeric/reference_checks.R` (Zeile 46–64) prüft nur, ob `names(manifest$anchors)` mit `validation_anchor_ids` übereinstimmt:
     - Wird `manifest$datasets` aus `SOURCES.json` gelöscht oder korrumpiert, läuft `validation_verify_resources()` ohne Fehler durch.
     - Liegt im Verzeichnis `inst/validation/numeric/anchors/` eine zusätzliche, nicht im Manifest verzeichnete Datei (z. B. `ANK-99.json`), wird diese von `validation_verify_resources()` ignoriert.
- **Erwartetes Verhalten:**
  1. `msa_grr()` prüft, dass `threshold` (falls nicht `NULL`) ein endlicher numerischer Vektor der Länge 2 mit `0 <= threshold[1] <= threshold[2]` ist, und bricht andernfalls mit benanntem Fehler ab.
  2. `validation_verify_resources()` prüft sowohl die exakte Dateimenge im `anchors/`-Verzeichnis als auch die Vollständigkeit und Hash-/Provenienz-Konsistenz der `datasets`-Einträge in `SOURCES.json` gegen `ANK-14`.
- **Vorgeschlagene Schwere:** `nonblocking` (Vorschlag, Entscheidung beim Reviewer)
