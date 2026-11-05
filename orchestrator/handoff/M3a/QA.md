# QA — M3a (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M3a` · Stand: 05.11.2026 · Fester, geloggter Seed aller neuen QA-Tests: `20261105` (`set.seed(20261105L)`).

## 1. Geprüfter Kontext und Artefakte

- **Kontextmanifest & Verträge:** `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/M3a/CRITERIA.json`, `docs/04-weitere-bausteine.md` (`K-M3a-1` bis `K-M3a-7`), `docs/01-fachspezifikation.md` (§2–§8), `docs/decisions/ADR-052-m3a-reviewer-auslegungen.md` (Nr. 1–19), `orchestrator/handoff/M3a/PLAN.md`, `orchestrator/handoff/M3a/PLAN-UPDATE.md`, `orchestrator/handoff/M3a/PLAN-REVIEW.md`, `PROGRESS.md`, `BACKLOG.md`.
- **Gate-Stand vor QA (`orchestrator/state/M3a/gates.json`, Runde 1, Basis `438ffb91b1cb79de8771235966640b299d852cdb`):**
  - `deps`: pass (`28 Anforderungen erfüllt (R 4.6.1)`)
  - `territory`: pass (`letzter Diff sauber (builder/40-build, Runde 1)`)
  - `trace`: pass (`7/7 Kriterien gemappt`)
  - `lint`: pass (`R CMD check` Status: OK)
  - `tests`: pass (`tests/testthat`, `tests/acceptance`, `tests/simulation`, `tests/e2e`, `tests/fuzz`)
  - `mutgate`: pass (`score=88.85 required=80 baseline=88.85 floor=80`; 774/871 nicht freigestellte Mutanten in `R/agreement.R` getötet)
  - `golden-adr`: pass (`keine Golden-/Ankeränderung`)
- **Visuelle Artefakte (`orchestrator/state/M3a/shots/`):** Verzeichnis leer (in M3a keine neue Plotfunktion im Lieferumfang).

## 2. Neue ausführbare QA-Testsuiten (`Seed = 20261105`) und Erledigung von `BL-131`

### 2.1 `tests/e2e/test-m3a-qa-e2e.R` (3 Blöcke, 149 Erwartungen, `0` Fehler)
- **`QA-M3a-E2E-1` (`K-M3a-1` bis `K-M3a-4`):**
  - Reproduziert Cohen (1968) Tab. 1 (`ANK-70`, $N = 200$) unter Zeilenpermutation mit festem Seed `20261105` gegen den gedruckten Wert $\kappa = 0{,}492$ sowie ungewichtet, linear und quadratisch gewichtet gegen `irr::kappa2` und `DescTools::CohenKappa` innerhalb `ANK-TOL.package_compare`.
  - Prüft Fleiss (1971) Tab. 1 / `irr::diagnoses` (`ANK-72`) für `fleiss = FALSE` (`$fleiss` ist `NULL`) und `fleiss = TRUE` (`$fleiss` ist `list(kappa = <unbenannter Skalar>)` ohne SE-Feld, Übereinstimmung mit `ANK-72` und `irr::kappam.fleiss`, Druckausgabe `Fleiss' kappa: 0.430` ohne SE-Erwähnung).
  - Prüft Krippendorff (2011) (`ANK-73`, 4 Beobachter × 12 Einheiten mit 7 fehlenden Werten und Einzelwert-Einheit 12) über `weights = "unweighted"` (nominal), `"linear"` (ordinal) und `"quadratic"` (Intervall) gegen `ANK-73` und `irr::kripp.alpha`, einschließlich `n_units_excluded == 1` und `fleiss$kappa = NA_real_` (mit Hinweis auf `Krippendorff`).
  - Prüft Attributkennzahlen (`K-M3a-4`), Modalwert-Tie-Break („niedrigste Kategorie in Skalenreihenfolge“ vs. `NA_character_` ohne gültige Antworten) und Ausschluss von Items ohne gültiges Antwort-Referenz-Paar in `pct_items_all_correct`.
- **`QA-M3a-E2E-2` (`K-M3a-5`, `K-M3a-6`):**
  - Prüft `msa_bias()` auf einem unbalancierten Mehr-Item-/Mehr-Bedingungs-Design (6 Items, davon zwei mit gleichem Referenzwert $4$ und eines mit nur einem Replikat; eine Bedingung `P2 x M2` vollständig unparsbar/`NA`; Faktoren als Eingabe; `level` in `{0.90, 0.95, 0.99}`) gegen `stats::t.test` und `stats::lm`.
  - Prüft die Zählgleichung `n + n_excluded == nrow` gesamt und je Bedingung, den Erhalt der leeren Bedingung `P2 x M2` mit `n = 0` und `NA_real_`-Schätzern sowie das Auseinanderfallen von Handbuch-Steigung ($gm - 2$ FG) und Item-Mittelwert-Steigung ($g - 2$ FG) bei unbalancierten Replikatzahlen.
- **`QA-M3a-E2E-3` (`K-M3a-2` bis `K-M3a-7`):**
  - Prüft den vollständigen End-to-End-Berichtsfluss (`acmg_demo`, `ic50_demo` → `msa_agreement(fleiss = TRUE)`, `msa_bias()`, `msa_fit()`, `msa_grr()` → `msa_report()`) auf Fleiss-Kappa, Modalwert-Abgrenzung zu `acmg_modal()`, `n_units_excluded`, beide Linearitätsregressionen mit ihren Freiheitsgraden und das Handbuch-Verdikt.
  - Prüft die gerenderten Hilfeseiten `man/msa_agreement.Rd` und `man/msa_bias.Rd` sowie `inst/validation/agreement/bias_coverage.R` (`agreement_bias_coverage`, `agreement_coverage_table`, Wiederherstellung von `.Random.seed` nach Lauf mit `ANK-TOL.n_check`).

### 2.2 `tests/fuzz/test-m3a-qa-fuzz.R` (2 Blöcke, 892 Erwartungen, `0` Fehler)
- **`QA-M3a-FUZZ-1` (`msa_agreement` Metamorphe Invarianzen & Grenzbereiche):**
  - 15 randomisierte Fuzz-Durchläufe über $K \in \{2,\dots,6\}$ Kategorien, fehlende Werte und alle drei Gewichte: Invarianz unter Zeilenpermutation, Skaleninversion (`levels -> rev(levels)`) und Trennzeichen-IDs (`|`, `.`, `:`).
  - Trennzeichen-Kollisionstest (`item_id = c("a|b", "a")`, `prompt_id = c("c", "b|c")`), mehrfache Werte außerhalb `levels` (`"Z_high", "Z_low"`), Referenzkonflikte mit leerer Zeichenkette `""`, sowie die drei undefinierten Fleiss-Kappa-Pfade (ungleiche Anzahl gültiger Urteile, $< 2$ gültige Urteile je Item, nur eine genutzte Kategorie).
- **`QA-M3a-FUZZ-2` (`msa_bias` Metamorphe Invarianzen, Präzisions- und Bandgrenzen):**
  - 15 randomisierte Fuzz-Durchläufe: Zeilenpermutation, gemeinsame Verschiebung von Antwort und Referenz um $c$ sowie positive Skalierung um $s > 0$.
  - Numerischer Referenzkonflikt in der 17. signifikanten Stelle (`0.1 + 0.2` vs. `0.3`), bedingungsspezifische Konstanzmeldung (`Bias (prompt "p_const", model "m_const") ...`), Leerzeichen-Verkettung in `linearity_note`, exakte Konstanzschwelle `se_mean < 10 * eps * |mean|` bei $n = 3$ (`15 * eps` vs. `19 * eps`), asymmetrisches 10-Punkte-Design um die kritische Bandbreite `width = 0.84 < 1 = |slope|` (`0.85` akzeptabel vs. `0.83` inakzeptabel) sowie innerer Scheitelpunkt des konkaven Vertrauensbands (`reference = c(-1, 1)` im Band, Scheitelpunkt bei `0` außerhalb).

### 2.3 Bereinigung von `BL-131` in `tests/e2e/test-m3b-qa-e2e.R` und `tests/fuzz/test-m3b-qa-fuzz.R`
- Alle fünf Punkte aus `BL-131` (M3b REVIEW r1 E9) wurden in den M3b-QA-Dateien umgesetzt und in den neuen M3a-QA-Dateien von Beginn an eingehalten:
  1. Alle Toleranzen werden aus `reference/anchors/ANK-TOL.json` geladen (keine nackten Toleranzliterale).
  2. Alle PB-Generatorzeilen und Plangrößen werden aus `reference/anchors/ANK-80.json` gelesen.
  3. `options(testthat.progress.max_fails = Inf)` wird ausschließlich lokal innerhalb von `test_that()` mit `on.exit(options(old_opt), add = TRUE)` gesetzt.
  4. Optionale Orakelpakete werden mit `skip_if_not_installed()` statt stillschweigender `if (requireNamespace(...))`-Blöcke geprüft.
  5. `pb_design(24L)` prüft nur den sauberen Abbruch ohne Festschreibung des Meldungswortlauts aus `BL-127 (3)`.

## 3. Befunde

Für den durch `K-M3a-1` bis `K-M3a-7` und `ADR-052` Nr. 1–19 festgelegten Lieferumfang wurden **keine blockierenden Abweichungen** gefunden. Zwei defensive Randfälle außerhalb der in `ADR-052` Nr. 17 spezifizierten Eingabeverträge sind als `nonblocking`-Vorschlag (`QA-M3a-001` / `BL-132`) dokumentiert:

### `QA-M3a-001` — Defensive Härtung bei extremer Subnormal-/Unterlauf-Skalenspreizung in `msa_bias_regression()` sowie bei Duplikaten/`NA` in `levels` bei `msa_agreement()`

- **ID:** `QA-M3a-001` (`BL-132`)
- **Testpfad:** `tests/fuzz/test-m3a-qa-fuzz.R` (reguläre Pfade geprüft in `QA-M3a-FUZZ-1` und `QA-M3a-FUZZ-2`; Reproduktionscode für die beiden entarteten Randfälle unten)
- **Betroffene Stellen:** `R/agreement.R:504–507, 529` (`msa_bias_regression()`) und `R/agreement.R:76` (`msa_agreement()`)
- **Beobachtet:**
  1. **Unterlauf von `slope` bei der Achsenabschnittsberechnung (`R/agreement.R:504–507, 529`):** `msa_bias_regression()` berechnet `slope <- b * (yc$scale / xc$scale)` (mit Fallback `(b * yc$scale) / xc$scale`) und daraus `intercept <- yc$mean - slope * xc$mean`, greift aber nur bei `!is.finite(intercept)` auf die skalierte Formel `yc$scale * (yc$mean / yc$scale - b * (xc$mean / xc$scale))` zurück. Wenn `yc$scale / xc$scale` zu `0` unterläuft oder im Subnormalbereich Präzision verliert (z. B. Item 1 bei `reference = 0` mit `value = 1e-200`, Items 2–4 bei `reference = c(1e200, 2e200, 3e200)` mit `value == reference`), wird `slope == 0` und `slope * xc$mean == 0` endlich, sodass der Fallback in Z. 507 nicht ausgelöst wird. Während `linearity_band$fit` bei `reference == 0` über die skalierte Formel in Z. 540 (`yc$mean + yc$scale * (b * z)`) den exakten Achsenabschnitt `7e-201` liefert, gibt `linearity[["intercept"]]` (und `linearity_item_means[["intercept"]]`) `yc$mean = 2.5e-201` und `t_intercept = 0.7715167` statt `2.160247` zurück.
  2. **Ungeprüfte Duplikate oder `NA` im vom Aufrufer übergebenen `levels`-Vektor (`R/agreement.R:76`):** Übergibt ein Aufrufer `levels` mit Duplikaten (`c("A", "B", "A", "C")`) oder `NA` (`c("A", "B", NA, "C")`), verschiebt `match(values, levels)` in `krippendorff_alpha()` bei `weights = "quadratic"` (`metric = "interval"`) und `reference = NULL, fleiss = FALSE` still die Skalenposition von `"C"` von `3` auf `4` (`alpha = -0.1363636` statt `-0.1904762`). Mit `reference` bricht `levels` mit `NA` in `cohen_kappa()` mit `Error in w * tab: non-conformable arrays` und mit Duplikaten in `factor()` mit `Error in levels<-(*tmp*, ...): factor level [3] is duplicated` (mit `conditionCall() != NULL`) ab.
- **Erwartet:**
  1. In `msa_bias_regression()` wird `intercept` (oder zumindest der Fall `slope == 0` / Subnormalbereich) wie `band$fit` über `yc$mean - yc$scale * (b * (xc$mean / xc$scale))` und der Zähler von `t_intercept` über `yc$mean / yc$scale - b * (xc$mean / xc$scale)` berechnet, sodass `linearity[["intercept"]]` und `linearity_band$fit[reference == 0]` auch bei extremer Skalenspreizung zwischen `x` und `y` übereinstimmen.
  2. `msa_agreement()` weist ein vom Aufrufer übergebenes `levels` mit `NA` oder Duplikaten vorab mit einer sauberen englischen Fehlermeldung (`call. = FALSE`) ab.
- **Reproduktion:**
  ```r
  # (1) Subnormal-/Unterlauf-Skalenspreizung zwischen Referenz und Abweichung
  d_sub <- data.frame(
    item_id = paste0("i", 1:4), prompt_id = "p1", model_id = "m1",
    value = c(1e-200, 1e200, 2e200, 3e200),
    reference = c(0, 1e200, 2e200, 3e200)
  )
  b_sub <- msa_bias(d_sub, "reference")
  b_sub$linearity[["intercept"]]       # 2.5e-201 (yc$mean, da slope zu 0 unterlief)
  b_sub$linearity_band$fit[1]          # 7.0e-201 (exakter Achsenabschnitt bei reference = 0)
  b_sub$linearity[["t_intercept"]]     # 0.7715167 statt 2.160247

  # (2) Duplikate / NA in levels bei msa_agreement()
  d_ag <- data.frame(
    item_id = rep(c("i1", "i2", "i3"), each = 2L),
    prompt_id = "p1", model_id = "m1", rep = rep(1:2, 3L),
    value = c("A", "B", "A", "C", "A", "A")
  )
  msa_agreement(d_ag, levels = c("A", "B", "C"), weights = "quadratic")$alpha$alpha[1]      # -0.1904762
  msa_agreement(d_ag, levels = c("A", "B", "A", "C"), weights = "quadratic")$alpha$alpha[1] # -0.1363636
  ```
- **Vorgeschlagene Schwere:** `nonblocking` (`ADR-052` Nr. 17 definiert die geforderten Eingabe- und Überlaufpfade; beide Fälle betreffen entartete Aufrufe außerhalb dieser Spezifikation und sind als `BL-132` für die Pflege nach dem 26.11.2026 erfasst; Entscheidung beim Reviewer).
