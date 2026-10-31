# QA — M1b (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M1b` · Stand: 31.10.2026 · Fester, geloggter Seed aller QA-Tests: `20261031` (`set.seed(20261031L)`).

## Geprüfter Kontext

- Rahmen und Verträge: `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`.
- Meilenstein-Spezifikation und Entscheidungen: `orchestrator/handoff/M1b/CRITERIA.json` (`K-M1b-1` bis `K-M1b-7`, `ACC-1` bis `ACC-18`), `docs/02-statistikkern.md`, `docs/01-fachspezifikation.md`, `docs/decisions/ADR-023-m1b-reviewer-auslegungen.md`, `docs/decisions/ADR-024-betreiberentscheidungen-vor-build-m1b.md`, `docs/decisions/ADR-025-m1b-reviewer-auslegungen-runde-2.md`, `docs/decisions/ADR-026-m1b-validierungsressourcen.md`, `orchestrator/handoff/M1b/PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `PROGRESS.md`, `BACKLOG.md`.
- Gate-Stand und Logs: `orchestrator/state/M1b/gates.json`, `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log`. Visuelle Artefakte: in M1b nicht gefordert (`orchestrator/state/M1b/shots/` nicht vorhanden).
- Geänderte und neue Produkt-, Dokumentations- und Testdateien seit `plan/M1b`: `R/fit.R`, `R/grr.R`, `DESCRIPTION`, `NEWS.md`, `PROGRESS.md`, `man/msa_fit.Rd`, `man/msa_grr.Rd`, `vignettes/validation.Rmd`, `data-raw/make_validation_latent.R`, `inst/validation/latent/`, `inst/validation/sim/`, `tests/testthat/helper-validation-latent.R`, `tests/testthat/test-fit-latent.R`, `tests/testthat/test-fit-latent-diagnostics.R`, `tests/testthat/test-grr-latent.R`, `tests/testthat/test-validation-simulation.R`, `tests/testthat/test-validation-latent.R`, `tests/testthat/test-acmg-latent-diagnostics.R`, `tests/testthat/test-fit-grr.R`, `tests/testthat/test-fit-rework-inputs.R`, `tests/testthat/test-grr-rework.R`.

---

## Befunde

### QA-M1b-001 — `msa_boot()` bricht bei jedem über `...` gesteuerten binären Fit (`msa_fit(type = "binary", control = ...)`) mit `"the ... list contains fewer than 1 element"` ab

- **ID:** `QA-M1b-001`
- **Reproduzierender Test:** `tests/e2e/test-m1b-qa-e2e.R` (`test_that("QA-M1b-001: msa_boot succeeds on binary fits created with explicit control or lme4 arguments passed via ... (seed = 20261031)", ...)`, Zeilen 39–70)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1b-5, K-M1b-6; `man/msa_boot.Rd` / `R/grr.R` Zeilen 135–145 („Available for numeric and binary outcomes (lme4 models).“, „`@param fit` An `msa_fit` of type numeric or binary.“, „An explicit fitting control passed to `msa_fit()` remains the model's refit control.“); `man/msa_fit.Rd` / `R/fit.R` Zeilen 48–55 (`@param ... Passed on to the model-fitting function.`).
- **Beobachtetes Verhalten:**
  Während `msa_fit()` für `type == "numeric"` in `R/fit.R` (Zeilen 242–255) die Argumente aus `...` vorab auswertet und per `do.call(lme4::lmer, ...)` konkrete Werte im Modellaufruf `model@call` hinterlegt, ruft der `else`-Zweig für `type == "binary"` in Zeile 263 direkt `lme4::glmer(form, data = dat, family = stats::binomial(link = link), ...)` auf. Dadurch zeichnet `lme4::glmer()` in `fit$model@call` für jedes über `...` übergebene Argument (wie `control = lme4::glmerControl(optimizer = "bobyqa")` oder `nAGQ = 1L`) das unaufgelöste Promise-Symbol `..1` auf:
  ```r
  lme4::glmer(formula = y ~ 1 + (1 | item) + (1 | prompt) + (1 | model),
              data = dat, family = stats::binomial(link = link), control = ..1)
  ```
  Wird das erzeugte binäre `msa_fit`-Objekt anschließend im dokumentierten End-to-End-Fluss (`msa_fit(type = "binary", control = ...) -> msa_grr() -> msa_boot()`) an `msa_boot(fit, nsim = 2, seed = 20261031L)` übergeben, wertet `lme4::bootMer()` / `lme4::refit()` das gespeicherte `control = ..1` außerhalb eines `...`-Kontexts aus und bricht sofort mit `Error: the ... list contains fewer than 1 element` ab (sowohl im selben Scope als auch beim Aufruf aus einer Hilfsfunktion).
- **Erwartetes Verhalten:**
  `msa_fit(type = "binary", ...)` muss analog zum numerischen `lmer`-Pfad die über `...` übergebenen Argumente sowie `data` und `family` ausgewertet in `fit$model@call` ablegen, sodass `msa_boot(fit)` auf explizit gesteuerten binären Fits fehlerfrei durchläuft und die übergebene Steuerung für die Refits beibehält.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1b-002 — `msa_fit()` für `type = "ordinal"` und `type = "binary"` bricht bei `subset`/`weights`/`offset`-Ausdrücken mit internen Spaltennamen ab und liefert bei Zeilenfilterung über `...` inkonsistente `fit$data` und `fit$n`

- **ID:** `QA-M1b-002`
- **Reproduzierender Test:** `tests/e2e/test-m1b-qa-e2e.R` (`test_that("QA-M1b-002: msa_fit for ordinal and binary outcomes supports subset/weights expressions and keeps fit$data and fit$n consistent with fit$model (seed = 20261031)", ...)`, Zeilen 72–105)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `docs/01-fachspezifikation.md` §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); `docs/02-statistikkern.md` K-M1b-6; `man/msa_fit.Rd` / `R/fit.R` Zeilen 48–55 („Expressions in `subset`, `weights` and `offset` can use the internal columns `item`, `prompt`, `model`, `block` and `y`. Row-based arguments refer to the rows remaining after missing or unreadable responses are removed.“) und Zeilen 104–106 („All returned data and study counts describe the retained observations.“).
- **Beobachtetes Verhalten:**
  1. Die in `?msa_fit` dokumentierte Auswertung von `subset`, `weights` und `offset` in der Datenmaske `dat` mit Rückgriff auf `parent.frame()` (`R/fit.R` Zeilen 245–251) sowie die anschließende Synchronisierung von `dat` mit `stats::model.frame(model)` (Zeilen 256–258) sind ausschließlich im Zweig `else if (type == "numeric")` implementiert.
  2. Ein Aufruf wie `msa_fit(runs, type = "binary", subset = item != "I01")` oder `msa_fit(runs, type = "ordinal", levels = ..., subset = item != "I01")` bricht deshalb mit `Error: object 'item' not found` ab.
  3. Wird `subset` als numerischer oder logischer Vektor übergeben (z. B. `subset = which(runs$item_id != "I01")` bei 12 Items à 18 Beobachtungen = 216 Zeilen), schätzen `lme4::glmer()` bzw. `ordinal::clmm()` das Modell auf den 198 verbleibenden Beobachtungen und 11 Items (`nobs(fit$model) == 198`, `ngrps(fit$model)[["item"]] == 11`), während `fit$n$observations` `216`, `nrow(fit$data)` `216` und `fit$n$items` `12` meldet.
- **Erwartetes Verhalten:**
  `subset`, `weights` und `offset` über `...` müssen auch für `type = "ordinal"` und `type = "binary"` gemäß `?msa_fit` ausgewertet werden, und `fit$data` sowie alle Zählungen in `fit$n` müssen exakt die vom Modell analysierten Beobachtungen und Faktorstufen beschreiben.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1b-003 — `msa_fit(type = "ordinal")` markiert nicht-singuläre Fits fälschlich als `singular = TRUE`, wenn ein Zwei-Stufen-Festfaktor (`derived`) nahe null liegt, und liefert bei kollinearen Zwei-Stufen-Faktoren stillschweigend `variance = 0`

- **ID:** `QA-M1b-003`
- **Reproduzierender Test:** `tests/e2e/test-m1b-qa-e2e.R` (`test_that("QA-M1b-003: ordinal msa_fit does not falsely mark interior random-effect fits as singular when a two-level fixed factor has zero contrast, and rejects collinear two-level factors or <=2-level interactions cleanly (seed = 20261031)", ...)`, Zeilen 107–149)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1b-4, K-M1b-6; `orchestrator/handoff/M1b/CRITERIA.json` ACC-9 und ACC-10 (6); `docs/decisions/ADR-023-m1b-reviewer-auslegungen.md` Nr. 9 und Nr. 10.6; `docs/01-fachspezifikation.md` §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); `man/msa_fit.Rd` („`singular` flag (a variance estimated at zero, common with few prompt or model levels...)“).
- **Beobachtetes Verhalten:**
  1. **Falsche `singular = TRUE`-Markierung durch feste Zwei-Stufen-Effekte:** In `R/fit.R` Zeile 294 wird `singular <- if (inherits(model, "merMod")) lme4::isSingular(model) else any(vc$variance[vc$source != "Residual"] < 1e-6)` erst **nach** dem Anhängen der über die Spannweitenmethode ($\hat{\beta}^2 / 2$) abgeleiteten festen Zwei-Stufen-Faktoren (`fixed_two`) an `vc` ausgewertet. Hat in einer ordinalen Studie mit zwei Blöcken oder zwei Modellen der feste Effekt keinen oder einen sehr kleinen Drift ($\hat{\beta}^2 / 2 < 10^{-6}$), während alle Zufallseffekt-Varianzen in `ordinal::VarCorr(fit$model)` (`item`, `prompt`) weit im Inneren liegen ($> 1{,}1$), setzt `msa_fit()` dennoch `fit$singular = TRUE` — obwohl ein fester Kontrast $\hat{\beta} \in \mathbb{R}$ keinen Rand bei $0$ besitzt und kein Zufallseffekt singulär ist.
  2. **Stillschweigende `variance = 0` bei kollinearen Zwei-Stufen-Faktoren:** Sind zwei Zwei-Stufen-Faktoren in `fixed_two` kollinear/konfundiert (z. B. `model_id == "M1"` nur in `block == 1` und `"M2"` nur in `block == 2`), verwirft `ordinal::clmm()` den rangdefizienten Koeffizienten (`design is column rank deficient so dropping 1 coef`) aus `model$beta`. Da `R/fit.R` Zeile 283 mit `design[2L, names(model$beta)] - design[1L, names(model$beta)]` nur über die in `names(model$beta)` verbliebenen Spalten summiert, wird für den nicht identifizierbaren zweiten Faktor stillschweigend `beta = 0` und damit `variance = 0` zurückgegeben statt eines benannten Identifizierbarkeits-/Rangdefekt-Fehlers.
  3. **Roher interner `stopifnot`-Absturz bei Wechselwirkungen mit $\le 2$ beobachteten Stufen:** Prüft `R/fit.R` Zeilen 216–220 für `interactions = TRUE` lediglich `nlev(dat[[p[1]]]) > 1 && nlev(dat[[p[2]]]) > 1`, ohne die Stufenzahl der beobachteten Kombinationen `interaction(dat[[p[1]]], dat[[p[2]]], drop = TRUE)` zu prüfen, übergibt `msa_fit(type = "ordinal", interactions = TRUE)` bei nur 2 beobachteten Zellen einen Zufallsterm mit 2 Stufen an `ordinal::clmm()`, das mit dem internen Assertionsfehler `all(sapply(gfl, nlevels) > 2) is not TRUE` abstürzt.
- **Erwartetes Verhalten:**
  1. `fit$singular` darf bei `type = "ordinal"` nur die Zufallseffekt-Varianzkomponenten (`!(vc$source %in% c("Residual", fixed_two))`) auf `< 1e-6` prüfen.
  2. Kollineare / rangdefiziente Zwei-Stufen-Faktoren (wenn `design[, names(model$beta)]` nicht alle erwarteten festen Kontraste enthält bzw. Spalten gedroppt wurden) sowie ordinale Wechselwirkungen mit $\le 2$ beobachteten Stufen müssen mit einer klaren, benannten Fehlermeldung abgewiesen werden.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1b-004 — `tests/testthat/test-validation-latent.R` bricht in ausgelagerten Paketkopien (`86-mutgate.sh` / `r-mutation.R`) unmutiert ab, weil `REPO_ROOT` beim Auflösen von `vignettes/validation.Rmd` ignoriert wird

- **ID:** `QA-M1b-004`
- **Reproduzierender Test:** `tests/e2e/test-m1b-qa-e2e.R` (`test_that("QA-M1b-004: test-validation-latent.R succeeds in a staged package copy with REPO_ROOT set (as in 86-mutgate.sh / r-mutation.R) (seed = 20261031)", ...)`, Zeilen 151–182)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `orchestrator/state/M1b/gate-mutgate.log` (`mutgate: fail (unmutierter Vorlauf rot, kein Mutant gelaufen; 1 Tests: tests/testthat/test-validation-latent.R: latent display retains significant digits and documentation traces every source [abgebrochen])`); `orchestrator/gates.d/86-mutgate.sh`; `orchestrator/lib/r-mutation.R`; `docs/decisions/ADR-026-m1b-validierungsressourcen.md`.
- **Beobachtetes Verhalten:**
  In `orchestrator/lib/r-mutation.R` (Zeilen 69–75) wird für den Mutationslauf eine schlanke Paketkopie außerhalb des Repos angelegt, die `DESCRIPTION`, `NAMESPACE`, `R`, `inst`, `data`, `src`, `tests/fixtures` und die Testverzeichnisse kopiert (jedoch kein `vignettes/`-Verzeichnis), während `REPO_ROOT` in der Prozessumgebung auf das Repository zeigt. Während `tests/testthat/test-validation-numeric.R` (Zeilen 207–209) über `validation_find_repo()` `REPO_ROOT` auswertet und `file.path(root, "vignettes", "validation.Rmd")` findet, sucht `tests/testthat/test-validation-latent.R` (Zeilen 97–100) nur unter `system.file("doc", "validation.Rmd", package = "llmsa")` (bei `load_package = "source"` leer) und `file.path(test_path("..", ".."), "vignettes", "validation.Rmd")` (im Staging-Verzeichnis nicht vorhanden). Dadurch schlägt `expect_true(file.exists(rmd))` fehl und `latent_test_documentation_sources(rmd)` bricht in `normalizePath(pending[1L], mustWork = TRUE)` mit einem unbehandelten Fehler ab, was das Gate `mutgate` vor dem ersten Mutanten scheitern lässt.
- **Erwartetes Verhalten:**
  `test-validation-latent.R` (bzw. ein Repo-Suchhelfer in `inst/validation/latent/reference_checks.R` analog zu `validation_find_repo()`) muss `REPO_ROOT` berücksichtigen, damit der Test auch in der ausgelagerten Paketkopie von `r-mutation.R` (`86-mutgate.sh`) grün durchläuft.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1b-005 — `msa_fit()` validiert `levels` bei `type = "ordinal"` nicht gegen `NA`/Duplikate/leere Labels und ignoriert bei `type = "binary"` ein explizit übergebenes `levels`-Argument für numerische oder logische `value`-Spalten

- **ID:** `QA-M1b-005`
- **Reproduzierender Test:** `tests/fuzz/test-m1b-qa-fuzz.R` (`test_that("QA-M1b-005: msa_fit validates ordinal/binary levels and respects explicit binary levels regardless of value storage mode (seed = 20261031)", ...)`, Zeilen 19–74)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `docs/02-statistikkern.md` K-M1b-6; `orchestrator/handoff/M1b/CRITERIA.json` ACC-10 (3)–(4); `docs/01-fachspezifikation.md` §2 Nr. 4; `man/msa_fit.Rd` / `R/fit.R` Zeilen 37–41 („`@param levels` For ordinal outcomes: the labels in scale order. For binary outcomes given as labels: two distinct, non-missing labels, whose second element is the event.“) und Zeilen 104–109 („Ordinal and binary fits discard missing responses, and labels outside `levels`, with a warning giving the count.“).
- **Beobachtetes Verhalten:**
  1. **Fehlende `levels`-Validierung für `type = "ordinal"` (`R/fit.R` Zeilen 171–177):** Im Gegensatz zu `type == "binary"` (Zeile 179) prüft `type == "ordinal"` das übergebene `levels`-Argument weder auf `NA` noch auf Duplikate, Mindestlänge ($\ge 2$) oder leere Zeichenketten `""`. Bei `levels = c("c1", NA, "c2", "c3")` oder `levels = c("", "c2", "c3")` läuft `msa_fit()` ohne Fehler durch und speichert `NA` bzw. `""` in `fit$levels`; bei Duplikaten `levels = c("c1", "c2", "c2", "c3")` bricht R mit dem internen `factor()`-Fehler `factor level [3] is duplicated` ab. Auch bei `type = "binary"` wird `levels = c("", "yes")` ohne Fehler akzeptiert.
  2. **Stillschweigendes Ignorieren von `levels` bei numerischen/logischen Binärwerten (`R/fit.R` Zeilen 182–188):** In `R/fit.R` stehen `if (is.logical(v)) y <- as.integer(v)` und `else if (is.numeric(v)) y <- v` **vor** `else if (!is.null(levels))`. Wird `levels` explizit übergeben, während `runs$value` numerisch oder logisch gespeichert ist:
     - ignoriert `msa_fit(runs_01, type = "binary", levels = c("no", "yes"))` das `levels`-Argument vollständig und schätzt auf allen 0/1-Zeilen ohne Warnung oder Ausschluss;
     - schlägt `msa_fit(runs_12_num, type = "binary", levels = c("1", "2"))` (numerische Codes `1`/`2` mit expliziten `levels = c("1", "2")`) mit `"Binary values must be 0 or 1."` fehl, obwohl `as.character(runs_12_num$value)` mit denselben `levels = c("1", "2")` erfolgreich geschätzt wird.
- **Erwartetes Verhalten:**
  1. `msa_fit()` prüft `levels` bei `type = "ordinal"` (mindestens 2 eindeutige, nicht-fehlende, nicht-leere Stufenbezeichnungen) und weist leere Strings `""` in `levels` sowohl bei `ordinal` als auch bei `binary` mit einer klaren `levels`-Fehlermeldung ab.
  2. Ist `levels` bei `type = "binary"` explizit angegeben (`!is.null(levels)`), wird `d$value` konsistent als Label gegen `levels` ausgewertet (sodass Werte außerhalb von `levels` mit Warnung verworfen werden und `levels[2]` das Ereignis definiert).
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M1b-006 — `sim_merge()` und `latent_read_results()` akzeptieren korrumpierte Replikat-Designzählungen sowie unmögliche Kennzahlen (`empse < 0`, `derived_share > 1`) und ungültige `seed`-Werte

- **ID:** `QA-M1b-006`
- **Reproduzierender Test:** `tests/fuzz/test-m1b-qa-fuzz.R` (`test_that("QA-M1b-006: sim_merge and latent_read_results reject corrupted replicate design counts, contradictory failure states, and out-of-range result metrics (seed = 20261031)", ...)`, Zeilen 76–157)
- **Seed:** `20261031`
- **Spezifikations-/ADR-Bezug:** `docs/01-fachspezifikation.md` §2 Nr. 4 und §8; `docs/02-statistikkern.md` K-M1b-2, K-M1b-3, K-M1b-7; `docs/decisions/ADR-023-m1b-reviewer-auslegungen.md` Nr. 2 bis 5 (`ACC-3`, `ACC-4`, `ACC-5`); `docs/decisions/ADR-026-m1b-validierungsressourcen.md`.
- **Beobachtetes Verhalten:**
  1. **`sim_merge()` (`inst/validation/sim/simulation_helpers.R` Zeilen 340–358):** Beim Zusammenführen disjunkter Szenarioläufe prüft `sim_merge()` in `<studie>_replicates.csv` zwar `rep`, `rep_seed`, `estimand`, `true` und `derived`, validiert jedoch weder die Designspalten (`items`, `prompts`, `models`, `blocks`, `observations`) gegen die Szenariovorgaben (bzw. `NA` bei fehlgeschlagenem Fit gemäß ADR-023 Nr. 4.4) noch die logischen Diagnoseflags (`converged`, `singular`). Eine manipulierte Replikatdatei mit `items = 999L` (statt `60L`) wird von `sim_merge()` ohne Fehlermeldung zusammengeführt.
  2. **`latent_read_results()` (`inst/validation/latent/reference_checks.R` Zeilen 171–192):** Beim Einlesen von `<studie>_results.csv` bzw. `<studie>_check_results.csv` für die Validierungsvignette prüft `latent_read_results()` lediglich `any(d$mcse < 0)`, akzeptiert aber negative Werte für `empse` (z. B. `-0.25`) oder `rmse`, Anteile `derived_share` außerhalb von $[0, 1]$ (z. B. `1.5`) sowie negative oder nicht-ganzzahlige `seed`-Einträge (z. B. `-10.5`).
- **Erwartetes Verhalten:**
  1. `sim_merge()` prüft in `<studie>_replicates.csv` auch die Designzählungen (`items`, `prompts`, `models`, `blocks`, `observations` gleich den Szenariowerten bei erfolgreichem Fit bzw. `NA` bei fehlgeschlagenem Fit) und die Konsistenz von `converged`/`singular`.
  2. `latent_read_results()` weist Ergebnisdateien mit `empse < 0`, `rmse < 0`, `derived_share` außerhalb von $[0, 1]$ oder ungültigen `seed`-Werten (`seed < 1`, `seed != floor(seed)`, `seed > .Machine$integer.max`) benannt zurück.
- **Vorgeschlagene Schwere:** `nonblocking` (Vorschlag, Entscheidung beim Reviewer)
