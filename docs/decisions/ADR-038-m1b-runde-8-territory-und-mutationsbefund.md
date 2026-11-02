# ADR-038 — M1b Runde 8: territory nach dem Entparken, Mutationsbefund der Runde 7 gilt für Runde 8

## Status

Angenommen (Betreiber, 02.11.2026). Nur für die Gates von M1b Runde 8.

## Kontext

- Nach dem Datenverlust vom 01.11.2026 (BL-103) wurde M1b am 02.11. mit dem Betreiber-Commit `8d1763e` entparkt (REVIEW r7, E40).
- Gates Runde 7 ab 00:35: deps, lint, tests (488 Tests, 0 Fehler) und trace bestanden. territory ist rot, weil der Betreiber-Commit zwischen der letzten Modellphase und den Gates liegt (`82-territory.sh` verlangt `audit_base = HEAD^`). Runde 8 ist deshalb nötig.
- Der Mutationslauf der Runde 7 misst `R/fit.R` (SHA-256 `acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180`) und `R/grr.R` (SHA-256 `004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e`), rund acht Stunden.

## Entscheidung

1. Für die Gates der Runde 8 trifft `MUT_SCOPE_REGEX` keine Datei; mutgate meldet „kein geänderter Mutations-Scope“. Mutationsbeleg für Runde 8 ist der Lauf der Runde 7.
2. Bedingungen: mutgate der Runde 7 bestanden; `R/fit.R` und `R/grr.R` in Runde 8 bytegleich mit den Hashes oben; unter `tests/` entfällt kein Test und wird keine Erwartung abgeschwächt. Eine Verletzung ist ein blocking-Befund in Review r8 mit `ref` auf dieses ADR.
3. Vor dem Start von M1c setzt der Betreiber in `orchestrator/config.env` zurück: die zwei ADR-038-Zeilen entfernen, `MUT_RATCHET_TOL=2` (ADR-031), `MAX_ROUNDS_REWORK=5`.

## Begründung

Der Mutationsscore hängt nur vom mutierten Quelltext und den Tests ab. Sind beide unverändert, misst ein zweiter Lauf dasselbe und kostet acht Stunden. territory ist rot aus einem formalen Grund, nicht wegen eines Eingriffs einer Modellrolle.

## Konsequenzen

mutgate der Runde 8 ist kein eigener Beleg. Harness-Liste: Entparken ohne Betreiber-Commit vor den Gates ermöglichen; Mutationsbericht bei unveränderten Hashes wiederverwenden.
