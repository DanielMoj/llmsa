# ADR-003 — K-M0-2: Zählweise der „ausgeführten Tests unter `tests/testthat/`“

## Status

Angenommen (Reviewer, M0 `30-plan-review` Runde 1; bindend ab Planfreigabe von M0). Offener Punkt ACC-3 in `orchestrator/handoff/M0/CRITERIA.json`.

## Kontext

- `docs/01-fachspezifikation.md` §10, K-M0-2: „… und die Zahl der ausgeführten Tests unter `tests/testthat/` ist mindestens `ankerRef: ANK-03`. (Prüfweg: Gate tests)“
- Die Spec legt die Zähleinheit nicht fest: Möglich wären `test_that()`-Blöcke, Erwartungen oder Dateien. Ebenso offen ist, ob übersprungene Blöcke zählen.
- ANK-03 = 27 stammt aus `docs/00-vision.md` („27 Tests“). Ein testthat-Lauf auf `332a2d5` ergab 27 Blöcke (25 bestanden, 2 übersprungen, 138 Erwartungen); `parse()` der sechs Testdateien zählt ebenfalls 27 `test_that()`-Aufrufe.
- Die beiden Skips hängen von der Umgebung ab. Der eine ist `skip_if(requireNamespace("ellmer", quietly = TRUE))` in `test-backends.R`; er greift immer, weil das deps-Gate das Suggests-Paket `ellmer` installiert. Der andere ist `skip_on_cran()` in `test-report.R`; er greift, solange `NOT_CRAN` nicht gesetzt ist. Ohne Skips wäre die Zahl in der Gate-Umgebung je nach `NOT_CRAN` 25 oder 26. K-M0-2 wäre dann auf dem unveränderten v0.1.0 nicht erfüllbar, obwohl der Builder in M0 keine Tests ergänzen darf (§10: „Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“).
- Das Test-Gate `orchestrator/lib/r-tests.R` zählt `nrow(as.data.frame(test_dir(...)))`, Skips eingeschlossen. Eine Untergrenze prüft es nicht.

## Entscheidung

1. Ein „ausgeführter Test“ ist ein `test_that()`-Block, den `testthat::test_dir()` über `tests/testthat/` ausführt, also eine Zeile von `as.data.frame()` des Ergebnisses. Übersprungene Blöcke zählen mit. Das ist dieselbe Zählung wie im Test-Gate und in ANK-03.
2. Die Bedingung lautet: Zahl der Zeilen ≥ `ANK-03.value`. Der Wert wird zur Laufzeit aus dem Anker gelesen, nie als Literal.
3. Gezählt wird im Abnahmetest `tests/acceptance/test-m0-testthat-count.R` mit einem eigenen `test_dir()`-Lauf über `tests/testthat/` des geladenen Pakets. Ob der Gesamtlauf ohne Fehlschlag und Fehler endet, entscheidet das Test-Gate. Weil der Abnahmetest im Test-Gate läuft, schließt „das tests-Gate meldet `pass`“ die Untergrenze ein.
4. Skips zählen nur so, wie sie im Bestand vorkommen. Einen bestehenden Test in einen Skip zu verwandeln oder reine Skip-Blöcke zum Erreichen der Untergrenze hinzuzufügen, ist eine Abschwächung nach AGENTS.md, Integrität der Abnahme Nr. 1, und ein blocking-Befund im Code-Review. Der Reviewer liest die Zahl der Skips aus `gate-tests.log` („… übersprungen“).

## Konsequenzen

- Tests und Anker bleiben unverändert. Der zusätzliche `test_dir()`-Lauf kostet rund 10 s je Test-Gate und im Mutationslauf je Mutant.
- In späteren Meilensteinen darf die Zahl nur durch echte Tests wachsen. Das Löschen von Tests bleibt nach Integritätsregel Nr. 1 verboten.
- Rücknahme oder Änderung nur durch ein neues ADR.
