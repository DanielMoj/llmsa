# QA — M1d (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M1d` · Stand: 04.11.2026 · Fester, geloggter Seed aller neuen QA-Tests: `20261104` (`set.seed(20261104L)`).

## Geprüfter Kontext

- **Rahmen und Verträge:** `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`.
- **Meilenstein-Spezifikation und Entscheidungen:** `orchestrator/handoff/M1d/CRITERIA.json` (`K-M1d-1` bis `K-M1d-8`, `ACC-1` bis `ACC-20`), `docs/02-statistikkern.md` (Abschnitt M1d), `docs/01-fachspezifikation.md`, `docs/decisions/ADR-035-abschlussregel-bis-2026-11-26.md`, `docs/decisions/ADR-045-robustheitsergebnis-wortlaut.md`, `docs/decisions/ADR-047-m1d-kein-mutationslauf-fuer-kommentare.md`, `docs/decisions/ADR-048-m1d-reviewer-auslegungen.md`, `docs/decisions/ADR-049-m1d-daten-und-validierungsressourcen.md`, `orchestrator/handoff/M1d/PLAN.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `REVIEW-INPUT.md`, `PROGRESS.md`, `BACKLOG.md`.
- **Gate-Stand und Logs:** `orchestrator/state/M1d/gates.json`, `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log`. Visuelle Artefakte: `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.
- **Geänderte und neue Produkt-, Daten-, Dokumentations- und Testdateien seit `plan/M1d`:** `R/robustness.R`, `R/fit.R` (nur roxygen), `R/grr.R` (nur roxygen), `man/msa_fit.Rd`, `man/msa_boot.Rd`, `inst/templates/validation_report.Rmd`, `data-raw/make_llm_stability.R`, `data-raw/make_clinvar_subsets.R`, `data-raw/make_validation_m1d.R`, `inst/validation/m1d/prepare.R`, `inst/validation/m1d/findings.R`, `inst/validation/m1d/README.md`, `inst/validation/m1d/SOURCES.json`, `inst/validation/m1d/anchors/`, `inst/extdata/llm-stability_2026-10-22/`, `inst/extdata/clinvar_2026-10-19/`, `vignettes/llm-stability.Rmd`, `vignettes/clinvar-raters.Rmd`, `vignettes/validation.Rmd`, `tests/testthat/test-m1d-data.R`, `tests/testthat/test-m1d-findings.R`, `tests/testthat/test-robustness.R`, `NEWS.md`, `PROGRESS.md`, `docs/decisions/ADR-049-m1d-daten-und-validierungsressourcen.md`.

---

## Erledigung `M1D-QA-01` (`tests/e2e/test-m1c-qa-e2e.R`)

- **Hintergrund (`REVIEW-INPUT.md` `M1D-QA-01`, `gate-tests.log` Z. 1888–1924):** In `tests/e2e/test-m1c-qa-e2e.R` (`QA-M1c-E2E-4`, Zeilen 166–168) rief der Test aus M1c `boot_read_results()` auf dem Standardverzeichnis `inst/validation/sim/` auf und erwartete `mode == "check"` sowie `c("S-boot-1", "S-boot-7")`. Seit der Bereitstellung der Vollläufe (`boot_coverage_results.csv`) vor M1d gibt `boot_read_results()` auf dem Standardverzeichnis vertragsgemäß (`K-M1c-5`, `K-M1d-6`, `K-M1d-7`) dem Volllauf Vorrang (`mode == "full"`, Szenarien `S-boot-1` bis `S-boot-7`).
- **Umsetzung in `45-qa`:** `QA-M1c-E2E-4` prüft nun sowohl den Vorrang des Volllaufs auf dem Standardverzeichnis (`default_res$mode == "full"`, alle sieben Szenarien `S-boot-1` bis `S-boot-7`) als auch den Kurzlauf-Rückfall (`checked$mode == "check"`, Szenarien `c("S-boot-1", "S-boot-7")`) auf einem isolierten temporären Verzeichnis, das ausschließlich die unveränderte `boot_coverage_check_results.csv` enthält.
- **Hinweis zu `_pkgdown.yml` (`E1` / `M1D-INFRA-01`, `ADR-048` Nr. 15):** Die drei im `gate-tests.log` (Z. 1197–1211) fehlgeschlagenen Erwartungen in `test-m1d-5-size-licence-network.R` betreffen ausschließlich `_pkgdown.yml` im Betreiber-Territorium (kein Builder- und kein QA-Befund).

---

## Neue E2E- und Fuzz-Tests für M1d (`Seed = 20261104`)

1. **`tests/e2e/test-m1d-qa-e2e.R` (`Seed = 20261104`):**
   - `QA-M1d-E2E-1`: Prüft das eingefrorene `llm-stability`-Dataset (`inst/extdata/llm-stability_2026-10-22/`), die `SHA256SUMS`-Prüfsummen, die `QUELLE.txt`-Angaben gegen `ANK-40` (einschließlich `Non-label answer keys:`) und den vollständigen Nutzerfluss `as_msa_runs() -> msa_counts() -> msa_fit(type = "binary", interactions = FALSE, link = "probit") -> msa_grr()` sowie die beobachtete Antwort-Wiederholbarkeit, Trefferquote und Fehlquote über alle 21 Aufgaben und 5 Modelle (82.850 Zeilen). Verifiziert insbesondere, dass `msa_counts()` fehlende Antworten einschließt, während `msa_fit()` fehlende Antworten mit Warnung verwirft und nicht als `0`/`FALSE` umkodiert.
   - `QA-M1d-E2E-2`: Prüft die eingefrorenen ClinVar-Teilmengen (`hrf_submissions.csv.gz` und `sample_submissions.csv.gz` unter `inst/extdata/clinvar_2026-10-19/`), die `SHA256SUMS`, die Fünf-Klassen-Beschränkung (`ANK-47`), die HRF-Gene (`MEFV`, `MVK`, `NLRP3`, `TNFRSF1A`), die Mindestzahl verschiedener Submitter je Variante ($\ge 2$ bzw. $\ge 4$), die Beibehaltung mehrerer SCVs desselben Submitters, den Nutzerfluss `as_msa_runs() -> msa_agreement(weights = "unweighted" / "linear") -> msa_fit(type = "ordinal", link = "probit") -> msa_grr()`, die Anteile vollständiger Übereinstimmung und Konflikt (`full_agreement + conflict < 1`) sowie die Sensitivitätsfilterung `startsWith(review_status, "criteria provided")` (Ausschluss von `"no assertion criteria provided"` und `"reviewed by expert panel"`).
   - `QA-M1d-E2E-3`: Prüft die Offline-Ressourcen `m1d_resources()`, die vier Klasse-B-Vollläufe (`ordinal_recovery`, `binary_recovery`, `two_level`, `boot_coverage`), die dynamische Befundauswahl `m1d_findings()` sowie die ordinale Konvergenz-Sensitivität `m1d_convergence_sensitivity()` (`BL-92`) auf `ordinal_recovery_replicates.csv` (eigene `n`-Zählung für alle endlichen vs. konvergierten endlichen Schätzungen, ADEMP-Kennzahlen und äußere Wiederholungsdiagnosen).
   - `QA-M1d-E2E-4`: Prüft den `K-M1d-8`-Wortlaut (`ADR-045`, `BL-112`) Ende-zu-Ende über `msa_robustness() -> print() -> msa_report()` für (a) keinen Faktor über ME (`ME = %.4f`, neuer Satz, kein alter Satz `"robust to all screened perturbations"`, keine Suffixe), (b) gemischte aktive Faktoren (`(also above SME)` und `(above ME only)`, keine Suffixe an inaktiven Faktoren).

2. **`tests/fuzz/test-m1d-qa-fuzz.R` (`Seed = 20261104`):**
   - `QA-M1d-FUZZ-1`: Fuzz- und Grenzfalltests für `inst/validation/m1d/prepare.R`: `m1d_parse_answers()` (Groß-/Kleinschreibung, wiederholtes gleiches Label `(b) ... (B)`, konkurrierende Labels einschließlich Zitaten `'(A)' or (B)`, Leerzeichen `( A )`, bloße Buchstaben, `navigate`-Wortgrenzen wie `"yesterday"`/`"notable"`/`"yes_no"`, `NA` und Whitespace), `m1d_draw_variants()` (vollständige Wiederherstellung von `.Random.seed` und `RNGkind()` in `.GlobalEnv`, Permutationsinvarianz der Eingabezeilen, Randfall `length(eligible) == 1L` bei `sample.int`), sowie deterministische UTF-8-CSV/gzip-Serialisierung `m1d_write_csv()` mit Anführungszeichen, Kommas, Multibyte-UTF-8 und `NA`.
   - `QA-M1d-FUZZ-2`: Fuzz- und Grenzfalltests für `inst/validation/m1d/findings.R`: `m1d_findings()` exakt auf und knapp über den `ANK-TOL`-Schwellen (`bias_report$rel_bias`, `bias_report$mcse_multiple`, `mc_factor$report`), `mcse == 0` bei exakter vs. abweichender Überdeckung in `boot_coverage`, Ausschluss abgeleiteter Verhältnisse (`icc_items`, `grr_pct_study_var`) in den Recovery-Studien, Fehlerpfade bei ungültigen Eingaben, `m1d_performance()` mit $n \in \{0, 1\}$, `m1d_convergence_sensitivity()` bei fehlender Datei und widersprüchlichen Replikat-Diagnosen sowie Manipulationsprüfung in `m1d_resources()`.

**Gemeinsamer Prüflauf (`tests/e2e` und `tests/fuzz`):**
- `tests/e2e`: 5 Dateien, 19 Blöcke, 319 bestandene Erwartungen, 0 Fehlschläge, 0 Fehler, 0 Skips.
- `tests/fuzz`: 5 Dateien, 9 Blöcke, 94 bestandene Erwartungen, 0 Fehlschläge, 0 Fehler, 0 Skips.

---

## Befunde

Es liegt **kein blockierender Befund** gegen `K-M1d-1` bis `K-M1d-8` vor. Der nachfolgende Punkt betrifft ausschließlich die Eingabevalidierung bei synthetisch/manuell veränderten CSV-Dateien außerhalb des regulären Studienschreibers und ist nach `ADR-035` Nr. 1–3 als `nonblocking` eingestuft.

### QA-M1d-001 — `m1d_convergence_sensitivity()` und `m1d_findings()` (`inst/validation/m1d/findings.R`) prüfen bei manuell veränderten CSV-Dateien einzelne Spaltentypen und Pflichtmaße unvollständig

- **ID:** `QA-M1d-001`
- **Testabdeckung der aktiven Regeln:** `tests/fuzz/test-m1d-qa-fuzz.R` (`QA-M1d-FUZZ-2`, Zeilen 96–191)
- **Seed:** `20261104`
- **Spezifikations-/ADR-Bezug:** `docs/01-fachspezifikation.md` §2 Nr. 4; `docs/02-statistikkern.md` K-M1d-7; `docs/decisions/ADR-048-m1d-reviewer-auslegungen.md` Nr. 14.4; `docs/decisions/ADR-035-abschlussregel-bis-2026-11-26.md` Nr. 1–3 (analog zu `QA-M1c-001` / `BL-110`).
- **Beobachtetes Verhalten:**
  1. **`m1d_convergence_sensitivity()` (`inst/validation/m1d/findings.R` Zeilen 115–120):** Liest die Replikat-CSV mit `utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)` ohne `colClasses` und weist die Datei ab, wenn `!is.numeric(d$estimate)` gilt. Enthält eine synthetische Replikat-CSV ausschließlich `NA` in `estimate` (alle Wiederholungen fehlgeschlagen), typisiert `utils::read.csv()` die Spalte `estimate` in R standardmäßig als `logical`, sodass `m1d_convergence_sensitivity()` mit `"Invalid ordinal convergence-sensitivity replicates."` abbricht, statt den in `m1d_performance()` vorgesehenen Status `"fewer than two finite estimates"` zu liefern. Umgekehrt wird `d$rep` nicht auf positive Ganzzahlen (`rep >= 1`, `rep == floor(rep)`) oder auf ein vollständiges `(scenario, rep, estimand)`-Gitter je Szenario geprüft.
  2. **`m1d_findings()` (`inst/validation/m1d/findings.R` Zeilen 65–95):** Während für `study == "two_level"` explizit geprüft wird, dass für jedes Szenario eine Zeile `measure == "bias" & estimand == "model"` existiert (`if (!setequal(rows$scenario, unique(results$scenario))) stop("Missing two-level model bias.")`), fehlt für `ordinal_recovery`, `binary_recovery` (`measure == "rel_bias"`) und `boot_coverage` (`measure == "coverage"`) sowie bei leerem `results` (`nrow(results) == 0`) eine entsprechende Prüfung; ein auf andere `measure`-Zeilen gefilterter Dataframe liefert dort stillschweigend eine leere Befundtabelle (`0 rows`).
- **Erwartetes Verhalten (Härtungsvorschlag nach dem 26.11.2026, `BL-117`):**
  1. In `m1d_convergence_sensitivity()` eine reine `NA`-Spalte `estimate` nach `as.numeric()` wandeln, `d$rep` auf endliche positive Ganzzahlen prüfen und je Szenario ein vollständiges `rep x estimand`-Gitter verlangen.
  2. In `m1d_findings()` `nrow(results) > 0` sowie für jedes Szenario das Vorhandensein der benötigten `measure`-Zeilen (`"rel_bias"` bzw. `"coverage"`) prüfen.
- **Vorgeschlagene Schwere:** `nonblocking` (`ADR-035` Nr. 1–3; Vorschlag, Entscheidung beim Reviewer)
