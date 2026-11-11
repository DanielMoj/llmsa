# ADR-058 — Erstes Release als Version 0.2.0

## Status

Angenommen (Betreiber, 11.11.2026). Betreiber-Commit außerhalb des Harness, ohne Mutationslauf. Ändert keine Datei unter `R/`, `inst/`, `man/`, `tests/` oder `vignettes/`.

## Kontext

- `DESCRIPTION` trägt seit dem Ausgangsstand `332a2d5` (20.10.2026) die Version 0.1.0. `docs/00-vision.md` nennt als erstes Release „v0.1.x“. Ein Versions-Tag oder ein Release gibt es bisher nicht; die Tags des Repositorys sind `plan/…` und `done/…`.
- Seit dem Ausgangsstand sind M0 bis M3d abgenommen. `NEWS.md` führt die Änderungen. Die Schnittstellen der 22 exportierten Funktionen sind erhalten (ANK-02, `test-m0-api-snapshot.R`). Hinzugekommen sind Argumente mit Vorgabewert, Rückgabefelder, Spalten und Attribute, und einzelne Vorgabepfade sind geändert (etwa der Optimierungsschritt des numerischen Fits, ADR-018, und die Iterationsgrenzen der ordinalen Fits).
- „v0.1.0“ bezeichnet in `docs/`, `AGENTS.md`, den Ankern und den Abnahmetests durchgehend den Ausgangsstand `332a2d5`.
- Die gespeicherten Simulationsergebnisse unter `inst/validation/` nennen als Paketversion 0.1.0, obwohl sie auf späteren Ständen entstanden sind. Die Versionsangabe unterscheidet diese Stände nicht. Die Zuordnung zum Code leisten der Implementierungs-Hash in den Sitzungsdateien (`inst/validation/sim/*_session.txt`) und die Funktions- und Quell-Hashes in `inst/validation/planning/SOURCES.json`.
- Die Statustabelle des README nennt Übereinstimmung, Westgard/Simulator/Planung und Ausführung/Bericht als nicht validiert, obwohl M3a, M3c und M3d abgenommen sind (BL-148).

## Entscheidung

1. Das erste Release trägt die Version 0.2.0 und den Tag `v0.2.0`. Neue Argumente und Felder und geänderte Vorgabepfade gegenüber dem Ausgangsstand ergeben eine Minor-Version; 0.1.0 bleibt die Bezeichnung des Ausgangsstands.
2. Der Release-Commit ändert die Version in `DESCRIPTION`, die Überschrift in `NEWS.md`, Version und Datum in `CITATION.cff` und das Zitat im README.
3. README, Statustabelle: Die drei Zeilen stehen auf „verified“ und nennen den Prüfweg der abgenommenen Kriterien K-M3a-1 bis -7, K-M3c-1 bis -6 und K-M3d-1 bis -6. Fleiss (1971) und Parvin (1992) kommen mit den Angaben aus ANK-72 und ANK-87 in die Literaturliste. Der Roadmap-Punkt zur ausstehenden Validierung entfällt.
4. README, Absatz zu den Mutationsläufen: bleibt unverändert und nennt weiter nur `R/fit.R`, `R/grr.R` und `R/robustness.R`. Für die Dateien der Ausführung nennt das README keine Zahl: Der Lauf M3d r2 wertet `R/run.R`, `R/parse.R`, `R/backends.R`, `R/report-data.R` und `R/report.R` zusammen mit `R/grr.R` und `R/robustness.R` (80,25 % über alle sieben Dateien; für die fünf Dateien allein 560 von 810, also 69,1 %; `orchestrator/handoff/M3d/REVIEW.md`, BL-142).
5. Bedingungen vor dem Tag: `R CMD check` ist auf dem Release-Commit unter Linux, Windows und macOS grün (`docs/00-vision.md`, Zeile „Paket gesamt“), und der Bestätigungslauf von AP1 auf dem Release-Stand ergibt die Zahlen der Endauswertung vom 11.11.2026 (ADR-057, Konsequenzen).
6. Die gespeicherten Simulationsergebnisse werden für das Release nicht neu erzeugt.
7. Der Zenodo-DOI entsteht mit dem Release. Zenodo liest dafür nur `.zenodo.json`, nicht `CITATION.cff`; die Datei nennt die Lizenz jetzt in der Schreibweise des Zenodo-Beispiels (`mit` statt `MIT`) und bleibt ohne Versionsfeld. Ein Folge-Commit trägt den DOI in README, `CITATION.cff` und `inst/CITATION` ein und ändert sonst nichts.

## Konsequenzen

- `docs/00-vision.md` nennt weiter „v0.1.x“; maßgeblich ist dieses ADR. Den Spec-Text ändert nur der Betreiber.
- Berichte und Sitzungsdateien, die ab dem Release-Commit entstehen, nennen 0.2.0.
- Der Stand mit dem Tag `v0.2.0` enthält im README noch den Satz, dass der DOI mit dem ersten Release folgt; der DOI steht erst im Folge-Commit.
- BL-148 ist erledigt. BL-142 (Testlücken in den Dateien der Ausführung) bleibt offen.

## Nachtrag 11.11.2026: Ausführung

- Release-Commit `97e30f5`. Seine CI blieb unter Linux im Schritt `setup-r` stehen (Störung der Ubuntu-Runner von GitHub, BL-151); Windows und macOS waren grün.
- Commit `75ee3f4` legt den Linux-Runner auf `ubuntu-24.04` fest und ändert nur die beiden Workflow-Dateien und `BACKLOG.md`. R-CMD-check 43072899568 ist für diesen Commit unter Ubuntu 24.04, Windows und macOS grün.
- Bestätigungslauf von AP1: auf `97e30f5` vollständig mit Bootstrap, auf `75ee3f4` ohne Bootstrap. Beide ohne Abweichung von der Endauswertung vom 11.11.2026; die Berichte unterscheiden sich nur in Titel, Datumszeile, Statuszeile, Zeitstempel und Versionsangabe.
- Der Tag `v0.2.0` zeigt auf `75ee3f4`. GitHub-Release veröffentlicht am 11.11.2026.
- Zenodo: Version 0.2.0 unter DOI 10.5281/zenodo.24143759, alle Versionen unter DOI 10.5281/zenodo.24143758. Der Eintrag trägt die Version aus dem Tag (`v0.2.0`) und die Lizenz MIT.
- Der Folge-Commit nach Nr. 7 trägt die DOI in README, `CITATION.cff` und `inst/CITATION` ein und ergänzt diesen Nachtrag. `inst/CITATION` nennt für Version 0.2.0 die DOI der Version und für jede andere Version die DOI für alle Versionen.
