# QA — M3c (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M3c` · Stand: 08.11.2026 · Fester, geloggter Seed aller neuen QA-Tests: `20261108` (`set.seed(20261108L)`).

---

## 1. Geprüfter Kontext und Manifest

- **Rahmen, Regeln und Verträge:** `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`.
- **Meilenstein-Spezifikation und Entscheidungen:** `orchestrator/handoff/M3c/CRITERIA.json` (`K-M3c-1` bis `K-M3c-6`, `ACC-1` bis `ACC-12`), `docs/04-weitere-bausteine.md` (Abschnitt M3c), `docs/01-fachspezifikation.md` (§2, §4, §5, §6, §8), `docs/02-statistikkern.md` (`S-boot-1`), `docs/decisions/ADR-054-m3c-reviewer-auslegungen.md` (Nr. 1 bis 18), `docs/decisions/ADR-055-m3c-planungsressourcen.md`, `orchestrator/handoff/M3c/PLAN.md`, `orchestrator/handoff/M3c/PLAN-REVIEW.md` (Befunde `E1` bis `E9`), `PROGRESS.md`, `BACKLOG.md`.
- **Anker:** `reference/anchors/ANK-86.json` (Westgard et al. 1981: Regeln, strikte Schwellen, vollständige Fenster, analytische Fehlalarmraten), `reference/anchors/ANK-87.json` (Parvin 1992, Tab. 1: $\bar{p}_{cr} = 1/	ext{ARL}$), `reference/anchors/ANK-89.json` (Planungsregel $	ext{CV}(\hat{\sigma}_Y^2) \approx \sqrt{2/
u_Y}$, $
u_Y = a - 1$), `reference/anchors/ANK-02.json` (API-Snapshot), `reference/anchors/ANK-06.json`, `reference/anchors/ANK-16.json`, `reference/anchors/ANK-TOL.json`.
- **Gate-Stand und Logs (Runde 1):** `orchestrator/state/M3c/gates.json` (`result: "pass"`, alle 8 Gates grün: `deps`, `lint`, `tests` mit `925 Tests, 0 fehlgeschlagen, 0 Fehler`, `trace`, `territory`, `mutgate` mit `score = 93.6` bei `required = 80`, `golden-adr`, `mutfull`), `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log`. Visuelle Artefakte unter `orchestrator/state/M3c/` nicht vorhanden (keine Web-UI).
- **Geänderte und neue Dateien seit `plan/M3c`:** `R/spc.R`, `R/plan.R`, `R/report.R`, `inst/templates/validation_report.Rmd`, `inst/validation/planning/reference_checks.R`, `inst/validation/planning/SOURCES.json`, `inst/validation/planning/summary.csv`, `inst/validation/planning/replicates.csv.gz`, `inst/validation/planning/session.txt`, `inst/validation/planning/README.md`, `inst/validation/planning/anchors/ANK-89.json`, `inst/validation/sim/planning_rule.R`, `data-raw/make_validation_planning.R`, `vignettes/validation.Rmd`, `man/msa_control_chart.Rd`, `man/msa_plan.Rd`, `man/msa_report.Rd`, `DESCRIPTION`, `NEWS.md`, `PROGRESS.md`, `docs/decisions/ADR-055-m3c-planungsressourcen.md`, `tests/testthat/test-control-chart.R`, `tests/testthat/test-plan.R`, `tests/testthat/test-report-control-chart.R`, `tests/testthat/test-validation-planning.R`.

---

## 2. Ergebnis der Red-Team-Prüfung

- **Keine blockierenden Gegenbeispiele (`0 blocking`):** An Nutzerflüssen, Protokollgrenzen, Extremwerten, Seeds, RNG-Zustandsisolierung, Serialisierungsgrenzen und Kombinationen wurden keine Verstöße gegen `K-M3c-1` bis `K-M3c-6`, `ADR-054` oder `ADR-055`, keine roten Gates und keine Rückschritte gegenüber `M0` bis `M3d` gefunden:
  - **Westgard-Regeln & Fenstergrenzen (`K-M3c-1`, `ANK-86`):** Jede der sechs Regeln (`1_2s`, `1_3s`, `2_2s`, `R_4s`, `4_1s`, `10_x`) löst exakt oberhalb ihrer strikten Schwelle (`>`, `<`) und niemals auf oder knapp unterhalb der Grenze (`\pm 2^{-30}`) oder vor vollständigem Fenster ($t < m$) aus. `1_2s` ist reine Warnregel (`reject` bleibt `FALSE`). Bei `rules = "R_4s"` ohne `1_2s` gibt `print.msa_control_chart()` ausgelöste Zeilen vollständig aus (`ADR-055`).
  - **Beide `R_4s`-Lesarten & Rückwärtskompatibilität (`K-M3c-2`, `ADR-054` Nr. 1–2, 16–18):** `msa_control_chart(..., r4s = c("range", "westgard"))` hat Default `"range"` ($|z_t - z_{t-1}| > 4$) und prüft unter `"westgard"` $(z_t > 2 \land z_{t-1} < -2) \lor (z_t < -2 \land z_{t-1} > 2)$ mit vektorisiertem `&`/`|` ohne Skalar-Kurzschluss. `attr(cc, "r4s")` speichert die gewählte Lesart; ältere Karten ohne `r4s`-Attribut fallen in `print()` und `msa_report()` auf `"range"` zurück, während manipulierte/ungültige `r4s`-Attribute mit benanntem Fehler (`The control chart `r4s` attribute must be 'range' or 'westgard'.`, `call. = FALSE`) abgewiesen werden. `msa_report()` gibt den zur Lesart passenden Konventionssatz und die aktualisierten `R_4s`- und `reject`-Positionen im Markdown- und HTML-Bericht aus.
  - **Fehlalarmraten & Parvin (1992) (`K-M3c-3`, `ANK-86`, `ANK-87`, `ADR-054` Nr. 3–4):** Die Klasse-A-Studie `tests/simulation/test-westgard-false-alarm.R` bestätigt für beide `R_4s`-Lesarten über $100\,000$ Serien der Länge 12 alle Einzelregel- und Positions-Auslöseraten innerhalb von `ANK-TOL.mc_factor` ($4\,	ext{MCSE}$; maximale Abweichung $+2{,}79\,	ext{MCSE}$ bzw. $-2{,}80\,	ext{MCSE}$) sowie für die laufende Prozedur `1_3s/2_2s/4_1s/10_x` ohne `R_4s` ($	ext{SE} \in \{0, 1, 2\}$) $\bar{p}_{cr} = 1/	ext{ARL}$ innerhalb von `0.016` um Parvin (1992), Tab. 1 (maximale Differenz $0{,}00235$).
  - **Shewhart-Grenzen gegen `qcc::qcc(type = "xbar.one")` (`K-M3c-4`, `ADR-054` Nr. 5):** Die von `plot.msa_control_chart()` gezeichneten horizontalen Linien (`center` sowie `center +- 1, 2, 3 sd`) stimmen innerhalb von `ANK-TOL.oracle$closed_form_rel_tol` mit `qcc::qcc(..., type = "xbar.one", center = ..., std.dev = ..., nsigmas = k)` überein.
  - **Simulator-Itemwahrheit (`latent`) & Wiedergewinnung (`K-M3c-5`, `ADR-054` Nr. 6):** `msa_simulate()` führt in `latent` exakt $\mu + a_i$ (innerhalb jedes Items konstant über Prompts, Modelle, Blöcke und Replikate, exakt verschiebungsäquivariant unter `mean`), stellt `.Random.seed` bei gesetztem `seed` wieder her und gewinnt in `tests/simulation/test-simulator-recovery.R` (`S-sim-1`, $n_{	ext{sim}} = 1000$, Seed `20261108`) alle 8 Varianzkomponenten innerhalb von $1{,}84\,	ext{MCSE}$ ($\le 4\,	ext{MCSE}$) zurück.
  - **Studiengrößenplanung (`msa_plan`), Einzelreplikate & Validierungsvignette (`K-M3c-6`, `ANK-89`, `ADR-054` Nr. 7–15, `ADR-055`):** `msa_plan()` liefert `bias`, `empse`, `mcse_bias`, `mcse_empse` und `attr(plan, "replicates")` (`scenario, sim, estimate, singular, prompt`) exakt aus denselben ungefilterten Replikaten (einschließlich singulärer Fits und exakter Nullen; `prompt = NA_real_` bei `n_prompts == 1`; `empse = mcse_bias = mcse_empse = NA_real_` bei `nsim == 1`). Die Offline-Leseroutine `inst/validation/planning/reference_checks.R` prüft SHA-256-Provenienz, Schema, Schlüssel und Arithmetik ohne Neusimulation beim Knitten von `vignettes/validation.Rmd`.

---

## 3. Neue QA-Testsuiten (`tests/e2e/` und `tests/fuzz/`)

1. **`tests/e2e/test-m3c-qa-e2e.R` (3 `test_that`-Blöcke, 219 `expect_*`-Prüfungen, Seed `20261108`):**
   - `QA-M3c-E2E-1`: End-to-End-Fluss für `msa_control_chart()` über konstruierte Serien mit beiden `R_4s`-Lesarten (`"range"` vs. `"westgard"`), Vergleich der Shewhart-Grenzen (`center +- 1, 2, 3 sd`) und der `plot()`-Display-Liste mit `qcc::qcc(type = "xbar.one")` (sowohl für vorgegebene Parameter als auch für `n_baseline = 10`), Prüfung von `print.msa_control_chart()` (inkl. `rules = "R_4s"` ohne `1_2s`) sowie vollständiges Rendern von `msa_report()` in GFM-Markdown und HTML für `"range"`, `"westgard"` und Alt-Karten ohne `r4s`-Attribut.
   - `QA-M3c-E2E-2`: End-to-End-Fluss für `msa_simulate()` und `msa_plan()` über mehrere Kandidatenpläne (1 und 2 Blöcke sowie `n_prompts = 1` vs. `n_prompts > 1`), `.Random.seed`-Wiederherstellung, exaktes Replay jedes einzelnen Replikats gegen manuelle Aufrufe von `msa_simulate()` + `msa_fit()` sowie unabhängige Handnachrechnung aller 12 Zusammenfassungskennzahlen aus `attr(plan, "replicates")` nach Formelsammlung §9 und `ANK-16`.
   - `QA-M3c-E2E-3`: End-to-End-Prüfung des Offline-Planungslesers (`planning_read_results()` im `public`- und `full`-Modus ohne Modell-Fits), verlustfreie CSV-Serialisierungs- und Zusammenfassungs-Rundreise über `planning_rule_csv()` und `planning_summarize()` sowie vollständiges Knitten von `vignettes/validation.Rmd` mit Prüfung der M3c-Abschnitte, Anker-Referenzen (`ANK-86`, `ANK-87`, `ANK-89`) und Planungstabellen (`S-plan-1` bis `S-plan-4`, Delta-Methode).
2. **`tests/fuzz/test-m3c-qa-fuzz.R` (2 `test_that`-Blöcke, 4175 `expect_*`-Prüfungen, Seed `20261108`):**
   - `QA-M3c-FUZZ-1`: Property- und Grenz-Fuzzing für `msa_control_chart()` über 250 zufällige Serien an den exakten Schwellen ($\{0, \pm 1, \pm 1{,}5, \pm 2, \pm 2{,}5, \pm 3, \pm 4\} \pm 2^{-30}$), eingestreute `NA`-Werte, zufällige Regelteilmengen (von `character(0)` bis alle 6 Regeln) und beide `R_4s`-Lesarten gegen ein unabhängiges Orakel; außerdem 40 exakt dyadisch skalierte und vorzeicheninvertierte Serien sowie Fehlerpfade für ungültige `sd`, unbekannte `r4s`-Argumente und manipulierte `r4s`-Attribute in `print()` und `msa_report()`.
   - `QA-M3c-FUZZ-2`: Grenz- und Fehler-Fuzzing für `msa_plan()` (18 ungültige `nsim`-Typen/Werte vor jeder Simulation, fehlende Pflichtspalten in `scenarios`, Randfall `nsim = 1` mit `n_prompts = 1` und `n_prompts = 2`, `.Random.seed`-Wiederherstellung auch wenn `.Random.seed` vorab nicht existierte) sowie Skaleninvarianz- und Degenerations-Fuzzing (`all(y == 0)` vs. positives konstantes `y`) für `planning_prompt_summary()` und den Delta-Methoden-MCSE.

---

## 4. Nicht-blockierende Beobachtung im unveränderten Bestandscode (`nonblocking`)

Es liegen **keine `blocking`-Befunde** vor. Als nicht-blockierende Randbeobachtung im vor M3c bestehenden Code von `msa_control_chart()` und `msa_simulate()` wird für die Pflege nach dem `26.11.2026` (`ADR-035`) dokumentiert:

### `QA-M3c-001` — Unbekannte Regelnamen in `rules` und unplausible `n_baseline`-Werte in `msa_control_chart()`

- **ID:** `QA-M3c-001`
- **Testpfad (Dokumentation / Nachweis):** `R/spc.R` Z. 46–79 (`msa_control_chart()`); vgl. `tests/fuzz/test-m3c-qa-fuzz.R` (`QA-M3c-FUZZ-1` prüft gültige Regelteilmengen einschließlich `character(0)` mit `Seed = 20261108`).
- **Reproduktion (Seed `20261108`):**
  ```r
  set.seed(20261108L)
  cc_typo <- msa_control_chart(c(0, 3.5, -3.5), center = 0, sd = 1, rules = "1_3S")
  names(cc_typo)
  ```
- **Beobachtet:** Im unveränderten Bestandscode von `msa_control_chart()` (`R/spc.R:65-75`) prüft jede Regel einzeln `if ("..." %in% rules)`. Wird ein unbekannter Regelname (z. B. Tippfehler `"1_3S"` oder `"2_3s"`) übergeben, wird dieser stillschweigend ignoriert, in `attr(cc, "rules")` übernommen und führt ohne gültige Ablehnungsregel zu `reject = FALSE` für alle Punkte. Ebenso führt `n_baseline < 2` oder `n_baseline = NA` bei fehlendem `sd` über `stats::sd(base)` erst indirekt zur Fehlermeldung `` `sd` must be a positive number. `` statt zu einer direkten Meldung über `n_baseline`.
- **Erwartet (Empfehlung für die Pflege nach dem 26.11.2026):** Vorabprüfung `unknown <- setdiff(rules, c("1_2s", "1_3s", "2_2s", "R_4s", "4_1s", "10_x"))` mit benanntem `stop(..., call. = FALSE)` sowie explizite Vorprüfung von `n_baseline` (wenn `center` oder `sd` `NULL` ist), sobald die Änderungsbeschränkung aus `ADR-035` und `ADR-054` (nur `r4s` als neues Formulargument für `K-M3c-2`) entfällt.
- **Vorgeschlagene Schwere:** `nonblocking` (`ADR-035`; `ADR-054` Nr. 1–2 beschränkt die Schnittstellenänderung an `msa_control_chart()` auf `r4s = c("range", "westgard")`; Vorschlag, Entscheidung beim Reviewer).

---

## 5. Lokaler Ausführungsnachweis

```text
tests/e2e/test-m3c-qa-e2e.R:   3 Blöcke,  219 PASS, 0 FAIL, 0 ERROR, 0 SKIP, 0 WARN
tests/fuzz/test-m3c-qa-fuzz.R: 2 Blöcke, 4175 PASS, 0 FAIL, 0 ERROR, 0 SKIP, 0 WARN
Gesamtsuite tests/e2e:        31 Blöcke, 1037 PASS, 0 FAIL, 0 ERROR, 0 SKIP, 0 WARN
Gesamtsuite tests/fuzz:       17 Blöcke, 5755 PASS, 0 FAIL, 0 ERROR, 0 SKIP, 0 WARN
```
