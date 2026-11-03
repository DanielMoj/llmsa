# ADR-046 — Windows kennt keine leeren Umgebungsvariablen: Test von `boot_workers()`

## Status

Angenommen (Betreiber, 03.11.2026; Betreiberänderung nach BL-01 und ADR-012). Betreiber-Commit vor dem Start von M1d.

## Kontext

- GitHub Actions, Workflow `R-CMD-check`, Lauf 41649109574 zum Commit `2498dcd` (03.11.2026), der erste Lauf mit M1c: ubuntu-latest und macos-latest grün, windows-latest rot, nur in `checking tests`. `test-validation-bootstrap.R:238`, `FAIL 1 | SKIP 6 | PASS 5573`; ubuntu-latest `FAIL 0 | SKIP 6 | PASS 5574`. Der Test stammt aus `565841b` (M1c, Builder `40-build` Runde 1); die Gates laufen nur unter Linux, Windows sieht ihn erst die CI.
- Der Test verlangt für sechs Werte von `LLMSA_SIM_WORKERS` den Abbruch, darunter `""`. `?Sys.setenv`: „Most platforms allow setting an environment variable to `""`, but Windows does not and there `Sys.setenv(FOO = "")` unsets FOO.“ Unter Windows gilt dann die Vorgabe aus `Sys.getenv()`, also `ANK-TOL.sim_runtime.cores`, und `boot_workers()` wählt richtig den sequentiellen Weg. Die übrigen fünf Werte bleiben auch unter Windows gesetzt und brechen ab.
- Nachstellung unter Linux (R 4.3.3) mit genau den zwei Windows-Eigenschaften (`.Platform$OS.type`; `Sys.setenv()` mit leerem Wert entfernt die Variable): Von 23 Prüfungen des Blocks ist genau eine rot, wie im CI-Lauf.
- Der Fehler liegt im Test, nicht in `boot_workers()`. Keine Spezifikation verlangt den Abbruch bei leerem Wert (ADR-026 Nr. 6; M1c PLAN: `LLMSA_SIM_WORKERS` kann die Zahl reduzieren, unter Windows arbeitet die Studie sequentiell).

## Entscheidung

1. Die fünf Werte, die es auf allen Systemen gibt, verlangen weiter den Abbruch.
2. Leerer Wert außerhalb von Windows: Abbruch wie bisher.
3. Leerer Wert unter Windows: Der Test verlangt, dass die Variable danach ungesetzt ist und `boot_workers()` genau `1L` liefert. Der Fall wird nicht übersprungen; ändert R das Verhalten, wird der Test rot.
4. `boot_workers()` und `sim_main()` bleiben unverändert.

## Konsequenzen

- Kein Einfluss auf Ergebnisse: `R/` und `inst/` bleiben unverändert, damit auch `sim_implementation()` und `boot_implementation()`. Die Vollläufe von M1c bleiben gültig, der Mutationsumfang (`R/fit.R`, `R/grr.R`) ist nicht berührt.
- Unter Linux und macOS bleibt die Zahl der Prüfungen gleich. Unter Windows kommt eine hinzu, und der Rückgabewert von `boot_workers()` wird dort erstmals geprüft.
- Geprüft unter Linux (R 4.3.3, testthat 3.2.1): die Testdatei nativ und der Block in der Nachstellung. Zwei Gegenproben: Akzeptiert `boot_workers()` den leeren Wert, ist der Test unter Linux rot; fehlt `workers <- 1L`, ist er in der Nachstellung rot. Windows selbst belegt erst der nächste CI-Lauf.
- BL-116 hält den Befund fest.
