# ADR-040 — Wiederholbarkeit auf der latenten Skala: Kennzeichnung statt neuer Rechnung (K-M1c-7)

## Status

Angenommen (Betreiber, 02.11.2026). Gilt ab M1c.

## Kontext

- Bei latenten Fits ist die Restvarianz durch den Link fixiert (Probit 1, Logit π²/3; `latent_residual()`, `R/fit.R`), `grr_stats()` führt sie als „Repeatability“. Sie ist also kein Messwert aus Wiederholungen. Der ordinale Standardfit hat zudem keinen Item×Prompt-Term (`interactions`, `R/fit.R`), die anderen Komponenten sind relativ zu dieser festen Einheit geschätzt.
- `?msa_grr` definiert Repeatability als „variation between replicate calls“ und ergänzt nur, dass latente Fits die feste Restvarianz nutzen.
- In der vorläufigen AP1-Auswertung zeigt der Bericht für ein Modell in Abschnitt 4 identische Wiederholungen in allen Zellen und in Abschnitt 3 eine Repeatability im zweistelligen Prozentbereich der Studienvariation. Beides stimmt nach der jeweiligen Definition, liest sich aber als Widerspruch.
- Die Rechnung folgt der Konvention der Link-Skala (K-M1b-5, rptR). %GRR und Verdikt ändern sich dadurch nicht. Der Wortlaut führt aber Leser von Bericht und Paper in die Irre.

## Entscheidung

1. Keine neue Rechnung: `table`, `summary`, `verdict` und die Ergebnisse von `msa_boot()` bleiben bytegleich.
2. Neues Kriterium K-M1c-7 (`docs/02-statistikkern.md`, `orchestrator/milestones.json`): `print.msa_grr`, `inst/templates/validation_report.Rmd` und `?msa_grr` kennzeichnen die Zeile bei latenten Fits.
3. Wiederholbarkeit latenter Fits wird in Veröffentlichungen über den Anteil der Zellen mit identischen Wiederholungen aus `msa_agreement()` berichtet, %GRR als Gesamtgröße.
4. Die AP1-Endauswertung ergänzt einen ausgewiesenen Sensitivitätslauf mit `interactions = TRUE`. `acmg_fit()` und `inst/validation/ap1/plan.yaml` bleiben unverändert.

## Konsequenzen

- M1c ändert `R/grr.R` ohnehin; das Kriterium kostet keine zusätzliche Mutationszeit in `R/fit.R`.
- Numerische Fits bleiben ohne Hinweis: Dort misst die Restvarianz die Streuung zwischen Wiederholungen.
