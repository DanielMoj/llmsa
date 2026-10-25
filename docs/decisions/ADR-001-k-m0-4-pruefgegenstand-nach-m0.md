# ADR-001 — K-M0-4 prüft nach Abschluss von M0 den eingefrorenen Stand `done/M0`

## Status

Angenommen (Reviewer, M0 `30-plan-review` Runde 1; bindend ab Planfreigabe von M0). Offener Punkt ACC-1 in `orchestrator/handoff/M0/CRITERIA.json`.

## Kontext

- `docs/01-fachspezifikation.md` §10, K-M0-4: „Die 13 Dateien unter `R/` sind byte-identisch mit Commit `332a2d5`: die SHA-256-Summen gleichen `ankerRef: ANK-01`. (Prüfweg: Test)“; ebenda: „M0 ändert `R/` nicht.“
- Die Spec schweigt dazu, was K-M0-4 nach M0 bedeutet. Ab M2 ändert sich `R/` planmäßig (`docs/03-anwendungspipeline.md`, `acmg_*`), während die Abnahmetests unter `tests/acceptance/` in jedem späteren Test-Gate (`TEST_CMD`) und Mutationslauf (`MUT_TEST_DIRS`) weiterlaufen.
- Ein dauerhaft gegen den Arbeitsbaum prüfender Test würde ab M2 jedes Test-Gate rot färben und im Mutationslauf jeden Mutanten von `R/fit.R` und `R/grr.R` „töten“, ohne dass ein fachlicher Test ihn erkannt hätte (Scheintötungen, gegen `docs/01-fachspezifikation.md` §2 Nr. 7).
- Ein Überspringen nach M0 verbietet AGENTS.md, Integrität der Abnahme Nr. 1 („Tests … dürfen nie abgeschwächt, übersprungen … werden, um grün zu erreichen.“).

## Entscheidung

1. K-M0-4 ist eine Eigenschaft des Ergebnisses von M0.
2. Solange `orchestrator/state/M0/8-done.done` fehlt, prüft der Abnahmetest den Arbeitsbaum: Die Dateimenge unter `R/` ist genau die der 13 Pfade aus ANK-01, und je Datei stimmen Bytezahl und SHA-256 mit ANK-01 überein.
3. Sobald der Marker existiert, prüft der Test denselben Vergleich am Baum des unveränderlichen Tags `done/M0`, gelesen mit `git ls-tree -r --name-only --full-name done/M0 R` und `git cat-file blob done/M0:<pfad>` in eine temporäre Datei, nie am Arbeitsbaum. Marker, Commit und Tag erzeugt ausschließlich der Orchestrator (DONE-Schritt: Marker anlegen, committen, dann `done/M0` taggen); keine Modellrolle schreibt sie.
4. Kein `skip`: Fehlen Tag oder Blob oder scheitert Git, schlägt der Test benannt fehl.

## Konsequenzen

- Tests: `tests/acceptance/test-m0-r-unchanged.R` mit `acc_milestone_done()` und `acc_r_files_at()` aus den Setup-Dateien setzt diese Entscheidung bereits um; keine Änderung nötig. ANK-01 bleibt unverändert; das Gate golden-adr ist nicht berührt.
- Spätere Meilensteine: Änderungen unter `R/` werden nach ihren eigenen Kriterien und nach der Schnittstellenregel (§4, ANK-02, K-M0-7 prüft weiterhin das geladene Paket) beurteilt, nicht nach K-M0-4. K-M0-4 tötet nach M0 keine Mutanten.
- Während M0 gibt es keinen Mutationslauf: Bleibt `R/` unverändert, meldet mutgate „kein geänderter Mutations-Scope“ (K-M0-6).
- Restrisiko: Der Tag-Zweig lief in der ACCEPTANCE-Phase nur gegen eine Git-Attrappe. Sein erster echter Lauf ist das erste Test-Gate nach dem DONE von M0 (M2). Der Reviewer prüft dort `gate-tests.log` auf diesen Test; ein Fehler im Test ist Reviewer-Sache, kein Builder-Befund.
- Rücknahme oder Änderung nur durch ein neues ADR.
