# ADR-050 — M3b: drei Widersprüche der Spec nach der Acceptance

## Status

Angenommen (Betreiber, 04.11.2026; Betreiber-Commit vor der Wiederholung der Acceptance). Bindend ab der Wiederholung von `10-acceptance` in M3b. Ändert K-M3b-2, K-M3b-3 und K-M3b-5 in `docs/04-weitere-bausteine.md`.

## Kontext

Die Acceptance von M3b lief am 04.11.2026 (Reviewer `10-acceptance`, Runde 1, Commit `31ed494`). `orchestrator/handoff/M3b/CRITERIA.json` führt ACC-5, ACC-7 und ACC-10 als blockierend: Keine Implementierung kann alle Kriterien zugleich erfüllen. Die Befunde unten sind vom Betreiber außerhalb des Repos nachgerechnet, zusätzlich zur Probe des Reviewers unter R 4.6.1 (R 4.3.3, FrF2 2.3.5, DoE.base 1.2.5, unrepx 1.0.2, igraph; Python ohne Paketcode).

- **ACC-5, K-M3b-1 gegen K-M3b-2 bei N = 16.** `FrF2::pb()` hat die Vorgabe `boxtyssedal = TRUE` und liefert bei N = 16 mit 15 Faktoren einen nicht regulären Plan. |J3| je Spaltentripel bleibt unter Zeilen-, Spaltenpermutation und Spaltenvorzeichen gleich: zyklischer Plan aus der Generatorzeile 0:420, 16:35; `FrF2::pb(nruns = 16)` 0:336, 8:112, 16:7; `FrF2::pb(nruns = 16, boxtyssedal = FALSE)` 0:420, 16:35. Zweites Verfahren: kanonische Form eines gefärbten Graphen (Zeilen als Knoten, je Spalte zwei Knoten für die Vorzeichen; igraph, BLISS). Mit `boxtyssedal = FALSE` sind alle fünf Größen äquivalent, in der Vorgabe alle außer N = 16. Gegenproben: versteckte Permutation mit Vorzeichen erkannt, gestörter Plan abgelehnt.
- **ACC-7, innerhalb von K-M3b-3.** `unrepx::ME()` rechnet `pse * quantile(rd$abst, 1 - alpha)` aus einer simulierten Referenzverteilung, nicht `qt(1 - alpha/2, m/3) * pse`. Beispiel II: Lenth 0,5784, unrepx 0,4838 und 0,4833 (Seeds 1 und 2); Beispiel IV: 0,2940, unrepx 0,2460 und 0,2457. Eine Übereinstimmung auf 1e-8 schließt die Reproduktion der Beispiele aus. `unrepx::PSE(method = "Lenth")` stimmt.
- **ACC-10, K-M3b-5 gegen K-M3b-3 und die Quelle.** Mit Lenths Konstanten liegt die Fehlalarmrate unter H0 deutlich unter α = 0,05. Lenth nennt das Verfahren selbst konservativ (1989, S. 472–473; Zitate in `ANK-81`). Gerechnet:

| Rechnung | m = 8, je Effekt | m = 8, je Plan | m = 11, je Effekt | m = 11, je Plan |
| --- | --- | --- | --- | --- |
| Reviewer, Test auf Plänen N = 12, n = 1 000 | 0,02325 | 0,0150 | 0,02891 | 0,0250 |
| Reviewer, Mini-Referenz, unabhängige Kontraste, n = 200 000 | 0,02135 | 0,01295 | 0,02675 | 0,01848 |
| Betreiber, Python, Pläne N = 12, n = 200 000 | 0,02158 | 0,01320 | 0,02632 | 0,01786 |
| Betreiber, Python, unabhängige Kontraste, n = 4 000 000 (MCSE ≤ 0,00007) | 0,02135 | 0,01299 | 0,02650 | 0,01822 |

Kalibrierte Schranken für α = 0,05 (ME/PSE und SME/PSE), zum Vergleich mit Lenths 3,42 und 7,89 bei m = 8:

| m | Tabellen `crit.ME`, `crit.SME` in DoE.base | Betreiber, Python, n = 3 000 000 | Ye & Hamada (2000), ME, zitiert nach Xampeny et al. (2018), Tab. 1 |
| --- | --- | --- | --- |
| 7 | 2,298; 4,873 | 2,297; 4,872 | 2,297 |
| 8 | 2,202; 4,863 | 2,204; 4,866 | |
| 11 | 2,210; 4,439 | 2,209; 4,451 | |
| 15 | 2,157; 4,231 | 2,154; 4,232 | 2,156 |

## Entscheidung

1. **K-M3b-2 (ACC-5):** Das Orakel ist `FrF2::pb(nruns = N, boxtyssedal = FALSE)`. K-M3b-1 bleibt unverändert, die Matrizen folgen Plackett & Burman (1946). N = 16 bleibt im Vergleich, damit alle fünf Größen ein Orakel haben.
2. **K-M3b-3 (ACC-7):** `unrepx::ME` entfällt als Orakel. Die PSE bleibt gegen `unrepx::PSE` geprüft; PSE, ME und SME werden gegen `DoE.base::ME.Lenth(effects, simulated = FALSE, alpha = alpha)` geprüft. Die Funktion rechnet Lenths Gl. (1)–(5) mit d = m/3 und strikter Trimmung; gegen die eigene Nachrechnung ist die Abweichung 0 auf beiden Beispielen, in 1 400 Zufallsfällen (m = 7 bis 63) und im Grenzfall |c| = 2,5 · s0. DoE.base ist über `Depends` von FrF2 ohnehin installiert, es entsteht keine neue Abhängigkeit im Baum. Die Toleranz bleibt `ANK-TOL.frf2_unrepx.pse_me_tol` und gilt auch für SME; Name und Wert des Ankers ändern sich nicht.
3. **K-M3b-5 (ACC-10):** Das Kriterium verlangt die Einhaltung des Niveaus: je Kennzahl ≤ α + `ANK-TOL.mc_factor.pass` · MCSE. Jede Entscheidung gleicht zusätzlich der Mini-Referenz nach Lenth (1989), Gl. (1)–(5), denn die Einhaltung allein bestünde auch ein Code, der nie etwas meldet. Der Test gibt beide Raten mit MCSE und dem Abstand zu α aus. Die Hilfeseite von `msa_robustness()` nennt das Verfahren konservativ und α einen Nominalwert; der Satz „at the 5 % level per effect“ entfällt.
4. **Vorgabe bleibt Lenth 1989.** `msa_robustness()` rechnet weiter mit t-Quantilen. Kalibrierte Schranken werden nicht Vorgabe: Die Beispiele aus K-M3b-3 gälten dann nicht mehr, der Plan von AP1 ist auf Lenth 1989 festgelegt (`ANK-58`), eine Änderung nach Kenntnis der Daten wäre nicht vertretbar, und die Simulation setzt voraus, dass alle Effekte null sind (Fontdecaba et al. 2015). Die Schlussauswertung von AP1 weist die kalibrierten Schranken aus `DoE.base` als Sensitivität aus. Ein Argument dafür im Paket hält BL-126 fest.
5. **Verworfen:** Ein Vergleich mit einer selbst simulierten Sollrate als neuem Anker (ACC-10 b), weil der Test dieselbe Formel schon über die Mini-Referenz Entscheidung für Entscheidung prüft; ein Bericht ohne Bestehenskriterium (ACC-10 c), weil das Niveau eine Eigenschaft ist, die der Code halten muss; das Weglassen von N = 16 (ACC-5 b); `unrepx::ME` als Vergleich ohne Kriterium (ACC-7 b), weil DoE.base denselben Zweck mit Bestehenskriterium erfüllt; `BsMD::LenthPlot` als Orakel, das ebenso genau rechnet, aber ein neues Paket wäre.
6. **Wiederholung der Acceptance (wie ADR-016 Nr. 7, ADR-041 Nr. 6):** `orchestrator/state/M3b/1-acceptance.done` wird mit `git rm` entfernt. Der Reviewer passt `CRITERIA.json`, die Abnahmetests zu K-M3b-2, K-M3b-3 und K-M3b-5 und den Hinweis zu den Suggests nur dort an, wo dieses ADR es verlangt, und vermerkt ACC-5, ACC-7 und ACC-10 in `open` als entschieden. Mit `AUTONOMY_LEVEL=0` hält der Orchestrator danach wieder; der Betreiber prüft wie nach Runde 1.
7. **Formelsammlung (private Kopie):** „Fehler je Effekt α“ und „Familienfehler α“ werden zu Nominalwerten. Der Satz, ohne aktiven Faktor gelte die Pipeline als robust, entfällt; er widersprach dem Bericht. Die Formeln bleiben.

## Konsequenzen

- Die Bestehensgrenze von K-M3b-5 ist weit; Implementierungsfehler fängt die Gleichheit mit der Mini-Referenz und K-M3b-3, nicht der Abstand zu α.
- AP1: SME entscheidet nur zwischen „marginal“ und „inakzeptabel“ (`plan.yaml`, `sme_alpha = 0,05`, 8 Faktoren in 12 Läufen; tatsächliche Rate je Plan rund 0,013). „Akzeptabel“ hängt allein an |Δp| ≤ 5 %. Das konservative Verfahren kann ein Band also nur zu mild ausfallen lassen, nie fälschlich akzeptabel. Ein einzelner Effekt von 8 Standardfehlern überschreitet SME dort in rund 50 % der Pläne (eigene Simulation, n = 400 000). Der Bericht sagt schon, dass „kein aktiver Faktor“ keine Robustheit belegt.
- `msa_robustness()` rechnet ohne `transform` unverändert, Effekte, ME und SME von AP1 bleiben gleich.
- Der Builder ergänzt `FrF2`, `DoE.base` und `unrepx` in den Suggests; `R/robustness.R` ändert nur den Hilfetext aus Nr. 3 zusätzlich zu dem, was K-M3b-4 und K-M3b-6 verlangen.
- BL-125 hält fest, dass `msa_robustness()` die PSE nur aus den Faktorspalten rechnet; BL-126 die kalibrierten Schranken.

## Quellen

- Lenth, R. V. (1989). Quick and easy analysis of unreplicated factorials. Technometrics 31(4), 469–473.
- Ye, K. Q., Hamada, M. (2000). Critical values of the Lenth method for unreplicated factorial designs. Journal of Quality Technology, doi:10.1080/00224065.2000.11979971. Nicht am Original gelesen, Werte über Xampeny et al. (2018).
- Xampeny, R., Grima, P., Tort-Martorell, X. (2018). Selecting significant effects in factorial designs: Lenth's method versus the Box-Meyer approach. Journal of Applied Statistics.
- Fontdecaba, S., Grima, P., Tort-Martorell, X. (2015). Proposal of a single critical value for the Lenth method. Quality Technology & Quantitative Management 12(1), 41–51.
