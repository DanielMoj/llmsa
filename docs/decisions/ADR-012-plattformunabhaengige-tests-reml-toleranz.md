# ADR-012 — Plattformunabhängige Tests: Pfadvergleich und REML-Toleranz

## Status

Angenommen (Betreiber, 27.10.2026; Betreiberänderung nach BL-01).

## Kontext

- GitHub Actions, Workflow `R-CMD-check`, Lauf 40480274195 zum Commit `7affa46` (27.10.2026): ubuntu-latest grün, macos-latest und windows-latest rot im Schritt `check-r-package` (`R CMD check`, „checking tests“: 1 ERROR). Es war der erste CI-Lauf mit den M2-Commits; der letzte grüne Lauf war bei `62af932`, vor M2. Die beiden roten Tests stammen aus `4187c51` (M2, Builder `40-build` Runde 1) und tragen kein `skip_on_cran()`; mit `NOT_CRAN=true` (ADR-011) hängt der Befund nicht zusammen. Windows-CI ist Release-Bedingung (AGENTS.md, Projektblock).
- `tests/testthat/test-acmg-pipeline.R:190` (macOS, Windows): Der Test erwartet für einen Geschwisterpfad des Wurzelordners den unnormalisierten Pfad `file.path(sibling, "ap1.sqlite")`. `acmg_external_path()` liefert richtig den normalisierten Pfad, weil `acmg_resolve_path()` den vorhandenen Präfix mit `normalizePath(winslash = "/")` auflöst: unter macOS `/private/var/…` statt `/var/…`, unter Windows `C:/Users/runneradmin/…` statt `C:\Users\RUNNER~1\…`. Unter Windows warnt außerdem `unlink()` beim Entfernen des Verzeichnis-Symlinks (Zeile 194: „cannot delete reparse point …“).
- `tests/testthat/test-acmg-evaluate.R:68` (macOS): Der numerische Rückfall-Fit, REML über `lme4::lmer()` mit Standard-`lmerControl`, weicht nach umgekehrter Zeilenreihenfolge um 2,7e-6 · σ²_TV ab; geprüft wurde gegen `validation_tolerances$invariance` (1e-6). `msa_fit()` reicht `...` an `lme4::lmer()` durch und setzt keine eigene `lmerControl`; `acmg_fit()` übergibt keine Steuerung. REML trifft das Optimum nur auf Optimierergenauigkeit. Für REML mit Standard-`lmerControl` ist nach `ANK-TOL` die Klasse `reml_anova` zuständig (1e-4 · σ²_TV je Komponente, abgeleitete Kennzahlen 1e-4 relativ; BL-49).

## Entscheidung

1. Vergleiche zweier REML-Fits mit Standard-`lmerControl`, auch nach Permutation der Zeilen, prüfen gegen `reml_anova` (`ANK-TOL.reml_anova`). `invariance` gilt für Größen ohne iterative Optimierung (etwa Kappa, Verdikt, ndc) und für Fits mit enger Optimierersteuerung.
2. Tests vergleichen Pfade nur normalisiert. Die Erwartung entsteht unabhängig von der geprüften Funktion: der vorhandene Elternordner mit `normalizePath(winslash = "/", mustWork = TRUE)` normalisiert, der Rest angehängt.
3. Gilt ab sofort, auch für die Abnahmetests ab M1a.

## Konsequenzen

- `inst/validation/ap1/plan.yaml`, `validation_tolerances`: neu `reml_anova: 1.0e-04`; die Zeile `anchor` nennt `reml_anova`.
- `tests/testthat/test-acmg-evaluate.R`, Test „numeric fallback equals a direct fit with default interactions and retains warnings“: Die Prüfung gegen umgekehrte Zeilenreihenfolge nutzt `reml_anova`. Die Zeilen 61–62 lasen den nicht vorhandenen Schlüssel `engine_ordinal`, testthat 3 verglich deshalb exakt; sie lesen jetzt `engine`. Die Kappa-Invarianz im Test „evaluation preserves input order and item metadata and labels unverified runs“ bleibt bei `invariance`.
- `tests/testthat/test-acmg-pipeline.R`, Test „external paths reject descendants and symlinks while permitting sibling stores“: Die Erwartung für den Geschwisterpfad ist normalisiert berechnet. Unter Windows verknüpft der Test den Ordner mit einer Junction (`Sys.junction()`), die `unlink()` ohne Warnung entfernt und die kein besonderes Recht braucht; auf den anderen Systemen bleibt der Symlink. Wo sich eine Verknüpfung anlegen lässt, bleibt die Prüfung aktiv.
- BL-72 hält den Befund und den Hinweis für M1a fest.
- Kein Einfluss auf AP1-Ergebnisse: Produktcode, Items, Prompts und Auswertungsregeln bleiben unverändert; `validation_tolerances` liest nur die Testsuite.
