# ADR-039 — Plattformunabhängige Tests nach dem ersten CI-Lauf von M1a und M1b; Rollback des Harness

## Status

Angenommen (Betreiber, 02.11.2026; Betreiberänderung nach BL-01 und ADR-012). Betreiber-Commit vor dem Start von M1c.

## Kontext

- GitHub Actions, Workflow `R-CMD-check`, Lauf 41426634298 zum Commit `2db6f55` (02.11.2026): der erste Lauf mit M1a und M1b, denn bis dahin galt `PUSH_REMOTE=0`. Alle drei Plattformen sind rot, jeweils nur in `checking tests`; Installation, Beispiele und Vignetten sind grün. Die CI löst Pakete frei auf (R 4.6.2, lme4 2.1.0, Matrix 1.7.6), die Gates laufen in der eingefrorenen Umgebung (R 4.6.1, lme4 2.0.6, Matrix 1.7.4).

| Plattform | Stelle | Befund | Ursache |
| --- | --- | --- | --- |
| windows-latest | `test-validation-latent.R:133`, `test-validation-numeric.R:240` | `system.file(...) %in% sources` ist FALSE | `sources` ist normalisiert, der Vergleichswert nicht (ADR-012 Nr. 2) |
| ubuntu-latest | `test-fit-latent.R:83, 85, 86` | ucminf endet mit Code 4 („Stopped by zero step from line search“), größter Gradient 2,3e-5 | letzte Liniensuche hängt an der Rundung; nachgestellt mit R 4.6.2 und OpenBLAS 0.3.26 unter Ubuntu 24.04 |
| macos-latest | `test-fit-initialization.R:39` (zwei Eingaben) | der direkte `lmer`-Start gelingt | von BL-89 vorhergesagt |
| macos-latest | `test-fit-model-construction.R:70` | „… residual variance cannot be resolved …“ statt „… not representable …“ | von BL-89 vorhergesagt; nachgestellt mit R 4.6.2 ohne `long double` (`--disable-long-double`) |
| macos-latest | `test-fit-model-construction.R:194` | zusätzliche Konvergenzwarnungen von lme4 („degenerate Hessian“) vor der synthetischen Warnung | die Eingabe (`noise = 1e-3`) liegt nahe an der Singularität |
| macos-latest | `test-fit-rework-numerics.R:114` | „Analytic REML did not converge (iterations 100, scaled score 1.15409e-07, scaled step 4.92412e-07)“ | die Eingabe liegt an der Präzisionsgrenze, die `?msa_fit` dokumentiert (BL-108) |

- Messung zur letzten Zeile (x86-64 Linux, R 4.6.2): Mit dem Zusatz `rep(c(-1, 1, 0), 3) * d` fittet `msa_fit()` bei d = 0,1 und d = 0,01 auf allen vier geprüften Skalen; bei d = 0,001 endet es auf drei der vier Skalen mit derselben benannten Meldung. Der Test stand also um eine Zehnerpotenz neben der Grenze.
- BL-103: `trap release_lock EXIT INT TERM` löscht bei Strg+C die Sicherung der Modellphase und beendet den Lauf nicht. Danach meldet der Manifestvergleich eine Territoriumsverletzung, und `restore_worktree()` löscht jeden gesicherten Pfad ohne Kopie. So gingen am 01.11. die git-ignorierten Dateien unter `reference/` verloren. BL-104: `r-tests.R` bricht einen Testordner nach zehn Fehlschlägen ab.

## Entscheidung

1. Pfade werden auch in den Dokumentationstests normalisiert verglichen (ADR-012 Nr. 2).
2. `test-fit-latent.R`, ucminf: Endet ein Fit mit Code 4, verlangt der Test `converged = FALSE` und genau die Nichtkonvergenzwarnung neben der Warnung zum Ersatzverfahren; sonst `converged = TRUE` und nur diese eine Warnung. Der Vergleich der Komponenten bleibt unverändert.
3. BL-89 wird wie dort beschrieben umgesetzt. `test-fit-initialization.R` verzweigt nach dem Ausgang des direkten Starts: Scheitert er, gilt die bisherige Prüfung; gelingt er, muss `msa_fit()` fitten oder benannt enden, nie als `Rcpp::exception`. Die E54-Reproduktionen in `test-fit-model-construction.R` lassen beide dokumentierten Präzisionsmeldungen zu; die synthetischen Blöcke verlangen weiter genau ihre Meldung, durchgesickerte Matrix- und CHOLMOD-Warnungen bleiben verboten.
4. `test-fit-model-construction.R`, „explicit fitting control …“: Die Eingabe wird gut konditioniert (`noise = 1`). Die Erwartung bleibt exakt: nur die synthetische Warnung, derselbe Fehler.
5. `test-fit-rework-numerics.R`: Der Zusatz wird `/ 10` statt `/ 100`. Der Test prüft die Invarianz gegenüber der Skala, nicht die Präzisionsgrenze; deren Abbruchregel führt BL-108.
6. Harness, `orchestrator/orchestrate.sh` (BL-103 Nr. 3): Ein Signal beendet den Lauf mit 130 oder 143 ohne Rollback und meldet das im Log. Es wirkt, sobald der laufende Modellaufruf endet, denn `timeout` läuft in einer eigenen Prozessgruppe. Vor jedem Manifestvergleich und jedem Rollback prüft `require_snapshot()` die Sicherung; ist sie unvollständig, endet der Lauf mit FATAL, nichts wird zurückgesetzt oder gelöscht.
7. Abweichung von BL-103 Nr. 3: Ignorierte Pfade bleiben in Sicherung und Prüfung, also kein `--exclude-standard`. Das Preset verlangt, dass die Territoriumsprüfung auch ignorierte Dateien erfasst; sonst könnte ein Modell unter `reference/quellen/` unbemerkt schreiben. Nr. 6 beseitigt die Löschung, ohne diese Prüfung abzuschwächen.
8. `orchestrator/lib/r-tests.R` setzt `testthat.progress.max_fails = Inf` (BL-104).
9. Die überholten Meldungen `orchestrator/ESCALATION.md` und `orchestrator/ESCALATION-M1b.md` werden entfernt (M1b REVIEW r8, „An den Betreiber“ Nr. 4). Der Orchestrator legt sie beim nächsten Parken neu an.

## Konsequenzen

- Kein Einfluss auf Ergebnisse: `R/`, `inst/validation/` und `inst/validation/ap1/plan.yaml` bleiben unverändert. Die Hashes von `R/fit.R` und `R/grr.R` aus ADR-038 gelten weiter.
- Mutationslauf: Die zwei rechnerisch gleichwertigen Mutanten aus BL-89 (`sparse = FALSE`, `perm = FALSE` in `R/fit.R`) überleben künftig. Sie sind äquivalent; der Reviewer kann sie in M1c einzeln freigeben.
- Geprüft: die sechs Testdateien und `tests/testthat` insgesamt unter x86-64 Linux mit R 4.6.2, mit und ohne `long double`; die Abnahme des Templates T-1 bis T-10 mit zwei neuen Fällen in T-7 (Signal, verlorene Sicherung), die am alten Orchestrator scheitern. macOS und Windows belegt erst der nächste CI-Lauf.
- Das Template erhält dieselben Änderungen an `orchestrate.sh` und `r-tests.R`, sobald M1c läuft.
