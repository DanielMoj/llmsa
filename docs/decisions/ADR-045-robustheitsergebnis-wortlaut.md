# ADR-045 — Satz zum Robustheitsergebnis: kein aktiver Faktor heißt nicht robust (K-M1d-8)

## Status

Angenommen (Betreiber, 03.11.2026). Gilt ab M1d.

## Kontext

- Liegt kein Faktor über ME, schreiben `print.msa_robustness` (`R/robustness.R:168`) und `inst/templates/validation_report.Rmd:161`, die Pipeline sei „robust to all screened perturbations at this level“.
- Das zeigt ein Screening nicht. Kein Faktor über ME heißt nur, dass kein Effekt die Rauschschranke dieses Plans überschreitet. Bei zwölf Läufen und großem Lenth-PSE kann ME deutlich über der Akzeptanzgrenze des Plans liegen; ein Effekt an dieser Grenze ist dann von Rauschen nicht zu trennen.
- In der vorläufigen AP1-Auswertung steht der Satz bei zwei Modellen neben dem Band „marginal“ und niedriger Stabilität. Die Zahlen folgen mit der Endauswertung.
- Bei aktiven Faktoren sagt der Satz nicht, ob sie nur ME oder auch SME überschreiten. `active_simultaneous` steht nur in der Tabelle.
- Tests auf den alten Wortlaut gibt es nicht.

## Entscheidung

1. Neues Kriterium K-M1d-8 (`docs/02-statistikkern.md`, `orchestrator/milestones.json`): neuer Satz ohne aktiven Faktor, Zusatz je aktivem Faktor.
2. Keine neue Rechnung: `msa_robustness()`, PSE, ME, SME, `active`, `active_simultaneous` und die Bänder bleiben unverändert.
3. Das Kriterium steht in M1d und nicht in M3b, weil die AP1-Endauswertung mit dem Code von M1d rechnet und M3b je nach Zeit erst danach läuft.
4. Bericht und Paper sagen bei Modellen ohne aktiven Faktor: nicht entscheidbar, nicht „robust“.

## Konsequenzen

- M1d ändert `R/robustness.R` und die Vorlage. `R/robustness.R` liegt außerhalb von `MUT_SCOPE_REGEX` und außerhalb der Implementierungshashes der Simulationsstudien; die Vollläufe bleiben gültig.
- K-M3b prüft weiter die Rechnung. Den Wortlaut deckt K-M1d-8 ab.
