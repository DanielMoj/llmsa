# STATUS — llmsa

Stand: 2026-10-25T07:43:18+01:00 · Fortschritt: **0/10 fertig**

`▒░░░░░░░░░`  (▓ fertig · ▒ in Arbeit · ░ offen · ✖ geparkt)

| Paket | Inhalt | Status | Detail |
|---|---|---|---|
| M0 | Gerüst steht: Toolchain, Preset r-paket und alle gewählten Gates laufen grün auf v0.1.0, ohne Änderung an R/ | 🔨 | Phase 30-plan-approved · Runde 1 |
| M2 | Pipeline für das Anwendungsbeispiel ACMG/AMP: Itemsatz mit SHA-256, Prompt-Vorlagen, Backends mit festem Routing, Auswertung, Validierungsplan; läuft vor dem Statistikkern, damit die AP1-Erhebung parallel zu M1 beginnt | ⬜ | offen |
| M1a | Statistikkern numerisch nach Prüfstandard: Varianzkomponenten gleich ANOVA, AIAG-Beispiel, Gegenrechnung, NIST StRD, Kennzahlen und Verdikt, Invarianzen | ⬜ | offen |
| M1b | Statistikkern ordinal und binär: Engine-Gleichheit, Recovery- und β²/2-Studien als Skripte mit reproduziertem Kurzlauf, rptR, Randfälle | ⬜ | offen |
| M1c | Bootstrap wie lme4::bootMer, Überdeckungsstudie als Skript mit reproduziertem Kurzlauf, Mutationslauf über R/fit.R und R/grr.R | ⬜ | offen |
| M1d | Vignetten auf echten Daten ohne Modellaufruf (llm-stability, ClinVar-Einreichungen) und Abnahme der Klasse-B-Simulationsergebnisse aus M1b und M1c | ⬜ | offen |
| M3a | Übereinstimmung (Cohen, Fleiss, Krippendorff, Attributkennzahlen), Bias und Linearität nach Prüfstandard | ⬜ | offen |
| M3b | Robustheit: Plackett-Burman-Pläne, Lenth, Half-Normal-Plot, Fehlalarmrate | ⬜ | offen |
| M3c | Systemeignung: Westgard-Regelkarte, Simulator und Fallzahlplanung | ⬜ | offen |
| M3d | Ausführung mit Fortsetzen, Parser, Backends gegen Aufzeichnungen, zahlentreuer Bericht mit SHA-256 | ⬜ | offen |

_Automatisch aus `orchestrator/state/` erzeugt; Maschinenvertrag: `orchestrator/state/summary.json`._
