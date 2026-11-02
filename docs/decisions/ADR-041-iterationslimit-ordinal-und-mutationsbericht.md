# ADR-041 — Iterationslimit des ordinalen Vorgabepfads (K-M1c-8); Mutationsbericht innerhalb einer Gate-Runde

## Status

Angenommen (Betreiber, 02.11.2026). Betreiber-Commit vor der Wiederholung der Acceptance von M1c. Ändert ADR-027 Nr. 6 für den ordinalen Vorgabepfad.

## Kontext

- Vollauf `ordinal_recovery` (02.11.2026, n_sim = 1000, Stand M1b, R 4.6.1, Matrix 1.7-4, Referenz-BLAS 3.12.1): nicht konvergiert S-ord-1 8,1 %, S-ord-2 20,5 %, S-ord-3 7,8 %, S-ord-4 46,3 %. In S-ord-4 enden 451 der 463 am Iterationslimit von `nlminb` („iteration limit reached without convergence (10)“, Vorgabe 150), die übrigen 12 mit „singular convergence (7)“. S-ord-4 hat die Größe von AP1 (100 Items).
- Diese Wiederholungen sind verzerrt. S-ord-4, Mittel über die Wiederholungen:

| Schätzziel | wahr | konvergiert (n = 537) | nicht konvergiert (n = 463) |
| --- | ---: | ---: | ---: |
| prompt | 0,0625 | 0,051 | 0,268 |
| model | 0,090 | 0,066 | 0,291 |
| %GRR | 74,57 | 74,18 | 78,41 |

- Probe mit `control = ordinal::clmm.control(iter.max = 2000, eval.max = 4000)` in derselben Umgebung, auf den jeweils ersten nicht konvergierten Wiederholungen:

| Szenario | jetzt konvergiert | prompt, Mittel | model, Mittel | %GRR, Mittel |
| --- | ---: | --- | --- | --- |
| S-ord-4 | 25 von 28 (25 von 26 mit Code 10; die zwei mit Code 7 bleiben) | 0,257 → 0,054 | 0,268 → 0,079 | 77,98 → 74,35 |
| S-ord-2 | 14 von 14 | 0,061 → 0,061 | 0,081 → 0,057 | 74,62 → 74,35 |

- Die beiden geprüften konvergierten Wiederholungen ändern sich nicht (größte Abweichung 1,4e-14 in %GRR, Rundung der CSV-Spalte). Ein Fit, der innerhalb des alten Limits endet, folgt demselben Pfad.
- Die Rate hängt an der Umgebung: Unter R 4.6.2, Matrix 1.7-6 und OpenBLAS 0.3.26 konvergieren viele dieser Wiederholungen schon mit dem alten Limit. Mit dem neuen Limit stimmen beide Umgebungen überein, etwa Wiederholung 15 von S-ord-4: prompt 0,0029, model 0,177, %GRR 76,7. Das alte Limit macht das Ergebnis also auch plattformabhängig.
- AP1, Probeauswertung (vorläufig): Von den vier ordinalen Fits enden zwei vor 150 Iterationen und ändern sich nicht. Der Fit des dritten Modells und der gemeinsame Forschungsfit über alle Modelle (ohne Verdikt) enden am Limit und fallen nach ADR-006 Nr. 4 auf die numerische Skala zurück. Mit dem neuen Limit konvergieren beide auf der latenten Skala, nach 315 und 229 Iterationen. Das Verdikt ändert sich bei keinem Modell. Ihr größter Gradient bleibt mit 0,0098 und 0,015 über den 0,00016 der beiden anderen; beim Modellfit ändern engere Toleranzen die Lösung nicht. Anlass der Änderung ist die Simulation, nicht dieses Ergebnis.
- `R/fit.R` ändert sich damit in M1c. `86-mutgate` mutiert dann `R/fit.R` und `R/grr.R`, `88-mutfull` dieselben Dateien mit demselben Adapter noch einmal, rund 7 h 45 min doppelt in jeder Runde.

## Entscheidung

1. K-M1c-8: `msa_fit(type = "ordinal")` ohne `control` ruft `ordinal::clmm` mit `iter.max = 2000` und `eval.max = 4000`. Eine eigene `control`-Angabe gilt unverändert.
2. ADR-027 Nr. 6: Der ordinale Vorgabepfad gleicht dem Vorgabeaufruf der Engine bis auf diese zwei Limits. K-M1b-1 bleibt unverändert gültig, weil ein Fit innerhalb des alten Limits denselben Pfad nimmt.
3. AP1: ADR-006 Nr. 4 und `acmg_fit()` bleiben unverändert und gelten mit dem neuen Limit. Das ist eine ausgewiesene Abweichung vom ursprünglichen Rechenweg. Bericht und Paper nennen sie und zeigen als Sensitivität, für den Modellfit und den gemeinsamen Fit, die alten Limits samt numerischem Rückfall.
4. Nach M1c werden alle drei Vollläufe neu gerechnet, weil der Implementierungshash `msa_fit` einschließt (`sim_implementation()`). Die Prüfung der Vollläufe vom 02.11. wird daran wiederholt. K-M1d-7 berichtet weiter mit und ohne nicht konvergierte Wiederholungen.
5. `88-mutfull` übernimmt den Bericht von `86-mutgate`, wenn Commit, Hash von `orchestrator/config.env` und die Dateimenge gleich sind (`gate_mut_report_key()`, `reports/mutation/report.key`). Sonst rechnet es selbst; ein Flake-Rerun rechnet immer. K-M1c-6 bleibt erfüllt: Der Bericht stammt aus einem Lauf über beide Dateien, und ändert sich nur eine, rechnet `88-mutfull` selbst.
6. Die Acceptance von M1c wird wiederholt (`orchestrator/state/M1c/1-acceptance.done` entfernt, wie ADR-016), damit K-M1c-8 Abnahmetests erhält.

## Konsequenzen

- Der Builder erzeugt die Kurzläufe neu; bis dahin ist der Reproduktionstest aus K-M1b-2 rot (`docs/01` §8).
- Fits am alten Limit dauern länger: in der Probe mit 14 Prozessen in S-ord-4 im Median 63 s, höchstens 143 s je Fit. Der Vollauf `ordinal_recovery` wird dadurch länger als die bisherigen 91 Minuten; `binary_recovery` und `two_level` brauchen zusammen unter zehn Minuten.
- Geprüft: die Wiederverwendung mit einer Attrappe als `MUT_CMD` (übernommen; neu gerechnet bei anderer Konfiguration, anderem Commit, anderer Dateimenge und beim Flake-Rerun). Das Limit: siehe Kontext. Das Template folgt.
