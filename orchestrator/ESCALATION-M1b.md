# ESCALATION M1b

Plan nicht auflösbar; Arbiter benötigt HUMAN.

Handoff: `orchestrator/handoff/M1b/`

Fortsetzen: Ursache beheben, dann `git rm orchestrator/state/M1b/parked`, committen und neu starten (der Marker ist versioniert; ein bloßes rm lässt den Arbeitsbaum für den PREFLIGHT unsauber).

## Entscheid (Betreiber, 31.10.2026)

Frage 1: Variante A (π²/3 bleibt; K-M1b-5 in docs/02 neu gefasst). Frage 2: `10-acceptance` für M1b wird wiederholt, danach läuft der Plan über das liegengebliebene Verdict zum Arbiter und in Runde 2. Dazu E7 (`MUT_TEST_EXCLUDE`) und E8 (`ownership_check`) erledigt. Begründung und alle geänderten Stellen: `docs/decisions/ADR-024-betreiberentscheidungen-vor-build-m1b.md`.
