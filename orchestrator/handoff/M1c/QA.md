# QA — M1c (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M1c` · Stand: 03.11.2026 · Fester, geloggter Seed aller QA-Tests: `20261103` (`set.seed(20261103L)`).

## Geprüfter Kontext

- **Rahmen, Regeln und Verträge:** `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `docs/decisions/ADR-035-abschlussregel-bis-2026-11-26.md`.
- **Meilenstein-Spezifikation und Entscheidungen:** `orchestrator/handoff/M1c/CRITERIA.json` (`K-M1c-1` bis `K-M1c-8`, `ACC-1` bis `ACC-20`), `docs/02-statistikkern.md` (Abschnitt M1c), `docs/01-fachspezifikation.md` (§2, §3 Nr. 5, §4, §5, §8), `docs/decisions/ADR-040-wiederholbarkeit-latente-skala.md`, `docs/decisions/ADR-041-iterationslimit-ordinal-und-mutationsbericht.md`, `docs/decisions/ADR-042-m1c-reviewer-auslegungen.md`, `docs/decisions/ADR-043-m1c-ergebnisleser-ohne-simulator.md`, `orchestrator/handoff/M1c/PLAN.md`, `orchestrator/handoff/M1c/PLAN-REVIEW.md`, `orchestrator/handoff/M1c/verdict-plan.json`, `orchestrator/handoff/M1c/REVIEW-INPUT.md`, `orchestrator/handoff/M1c/MUT-EQUIV.json`, `PROGRESS.md`, `BACKLOG.md`.
- **Gate-Stand und Logs (Runde 1):** `orchestrator/state/M1c/gates.json` (`result: "pass"`, alle 8 Gates grün: `deps`, `lint`, `tests`, `trace`, `territory`, `mutgate`, `golden-adr`, `mutfull`), `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log` (`score = 92.8`, `required = 80`, `files = R/fit.R,R/grr.R`). Visuelle Artefakte unter `orchestrator/state/M1c/shots/` (leer; in M1c nicht gefordert).
- **Geänderte und neue Dateien seit `plan/M1c`:** `R/fit.R`, `R/grr.R`, `inst/templates/validation_report.Rmd`, `man/msa_fit.Rd`, `man/msa_grr.Rd`, `man/msa_boot.Rd`, `vignettes/validation.Rmd`, `NEWS.md`, `PROGRESS.md`, `inst/validation/sim/boot_coverage.R`, `inst/validation/sim/boot_coverage_helpers.R`, `inst/validation/sim/boot_coverage_results.R`, `inst/validation/sim/boot_coverage_check_results.csv`, `inst/validation/sim/boot_coverage_check_replicates.csv`, `inst/validation/sim/boot_coverage_check_session.txt`, `inst/validation/sim/ordinal_recovery_check_results.csv`, `inst/validation/sim/ordinal_recovery_check_replicates.csv`, `inst/validation/sim/ordinal_recovery_check_session.txt`, `inst/validation/sim/binary_recovery_check_results.csv`, `inst/validation/sim/binary_recovery_check_replicates.csv`, `inst/validation/sim/binary_recovery_check_session.txt`, `inst/validation/sim/two_level_check_results.csv`, `inst/validation/sim/two_level_check_replicates.csv`, `inst/validation/sim/two_level_check_session.txt`, `inst/validation/sim/README.md`, `tests/testthat/test-boot.R`, `tests/testthat/test-fit-ordinal-control.R`, `tests/testthat/test-grr-latent-note.R`, `tests/testthat/test-validation-bootstrap.R`.

---

## Ergebnis der Red-Team-Prüfung

- **Keine blockierenden Gegenbeispiele (`ADR-035` Nr. 1):** An Nutzerflüssen, Protokollgrenzen, Extremwerten, Seeds, Nebenläufigkeit (`parallel = "snow"` mit PSOCK-Cluster in `msa_boot()` sowie `LLMSA_SIM_WORKERS` / `mclapply` in `boot_coverage.R`) und Kombinationen wurden keine Verstöße gegen `K-M1c-1` bis `K-M1c-8`, keine roten Gates, keine Rückschritte gegenüber `M0`/`M1a`/`M1b`/`M2` und keine still falschen Ergebnisse auf regulären Plänen gefunden.
- **Ausführbare QA-Testsuiten (`Seed = 20261103`):**
  - `tests/e2e/test-m1c-qa-e2e.R` (`QA-M1c-E2E-1` bis `QA-M1c-E2E-4`): Prüft `msa_boot()` über Konfidenzniveaus (`0.90`, `0.95`), Seed-Reproduzierbarkeit, Trennung von `n_failed` und `n_singular` ohne Zusatzspalte in `attr(, "boot")`, `print.msa_boot`, den Hinweis zur latenten Wiederholbarkeit in `print.msa_grr` und `msa_report()` (`K-M1c-7`), das ordinale Iterationslimit samt `control`-Ersetzung und `...`-Vorrang (`K-M1c-8`) sowie die Generator-Isolierung des Ergebnislesers `boot_coverage_results.R` (`ADR-043`) und die Reihenfolgeinvarianz der Zufallsströme von `boot_generate()`.
  - `tests/fuzz/test-m1c-qa-fuzz.R` (`QA-M1c-FUZZ-1` bis `QA-M1c-FUZZ-2`): Prüft Extremkombinationen nicht endlicher (`NA`, `NaN`, `Inf`, `-Inf`) und singulärer Bootstrap-Wiederholungen einschließlich Totalausfall (`n_failed == nsim`, `n_singular == 0`), Rückwärtskompatibilität von `print.msa_boot` für Altdaten ohne `n_singular`-Attribut, die exakte obere Integer-Seed-Grenze in `boot_seeds()` für `S-boot-7` (`max_r = 151944467`) sowie Fehlereingaben in `boot_summarize()`.
  - Gemeinsamer Lauf über `tests/e2e` (`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 92 ]`) und `tests/fuzz` (`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 43 ]`) endet fehlerfrei.

---

## Zurückgestellte Beobachtungen nach `ADR-035` Nr. 2 und Nr. 3 (`nonblocking`, in `BACKLOG.md` als `BL-110` erfasst)

### QA-M1c-001 (Backlog `BL-110`) — Defensive Schema- und Wertebereichsprüfung bei manuell manipulierten CSV-Dateien in `boot_read_results()`, `boot_summarize()` und `boot_merge()`

- **ID:** `QA-M1c-001` (`BL-110`)
- **Testpfad:** `tests/fuzz/test-m1c-qa-fuzz.R` (`QA-M1c-FUZZ-2`, prüft die aktiven Ablehnungsregeln mit `Seed = 20261103`; die weitergehende Härtung gegen manuell veränderte CSV-Dateien ist gemäß `ADR-035` Nr. 2–3 für nach dem `26.11.2026` in `BACKLOG.md` unter `BL-110` dokumentiert, um keinen nicht-blockierenden Rework-Zyklus auszulösen)
- **Seed:** `20261103`
- **Spezifikations-/ADR-Bezug:** `docs/decisions/ADR-042-m1c-reviewer-auslegungen.md` Nr. 4.2, Nr. 5, Nr. 6.5–6.6; `docs/decisions/ADR-043-m1c-ergebnisleser-ohne-simulator.md`; `docs/decisions/ADR-035-abschlussregel-bis-2026-11-26.md` Nr. 1–3.
- **Beobachtetes Verhalten:**
  1. `boot_read_results()` (`inst/validation/sim/boot_coverage_results.R`, Zeilen 24–46) prüft `d$mcse >= 0` und Anteile (`coverage`, `singular_share`, `failed_share`) auf $[0, 1]$, weist aber in manuell editierten Ergebnis-CSVs negative Werte für `empse`, `rmse` oder `width` sowie zusätzliche unerwartete `estimand`-Zeilen (etwa `Residual` in `S-boot-7`) nicht zurück (anders als `latent_read_results()` nach `QA-M1b-006`).
  2. `boot_summarize()` (`inst/validation/sim/boot_coverage_helpers.R`, Zeilen 201–210) prüft `n_singular / boot_nsim` und `n_failed / boot_nsim` einzeln auf $[0, 1]$, nicht jedoch `n_singular + n_failed <= boot_nsim` (während `boot_replicate()` dies zur Laufzeit in Zeile 127 erzwingt); `boot_merge()` (Zeilen 358–367) prüft bei `is.na(d$estimate)` nicht, ob alle fünf Design-Zählspalten `NA` sind, und prüft `converged`/`singular` nicht auf `is.logical()` (anders als `sim_merge()`). Regulär durch `boot_replicate()` erzeugte Studienläufe sind davon nicht betroffen.
- **Erwartetes Verhalten (nach 26.11.2026, `BL-110`):**
  Angleichung der CSV-Validatoren in `boot_read_results()`, `boot_summarize()` und `boot_merge()` an `latent_read_results()` bzw. `sim_merge()` unter Beibehaltung der Kompatibilität mit den synthetischen Testfixtures in `test-validation-bootstrap.R` und `test-m1c-5-vignette-full-results.R`.
- **Vorgeschlagene Schwere:** `nonblocking` (`ADR-035` Nr. 1–3; Vorschlag, Entscheidung beim Reviewer)
