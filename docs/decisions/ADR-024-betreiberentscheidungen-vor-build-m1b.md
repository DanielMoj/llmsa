# ADR-024 — Betreiberentscheidungen vor BUILD M1b

## Status

Angenommen (Betreiber, 31.10.2026). Betreiber-Commit vor dem Neustart von M1b nach dem Parken am 31.10.2026, 04:28 („Plan nicht auflösbar; Arbiter benötigt HUMAN“). Beantwortet die beiden Betreiberfragen aus `orchestrator/handoff/M1b/ARBITER.md` (Verdict HUMAN zu E1, Plan-Review M1b Runde 1) und erledigt die Betreiberpunkte E7 und E8 aus `verdict-plan.json` Runde 1 (CRITERIA.json ACC-12 und ACC-15).

## Kontext

- K-M1b-5 (docs/02 Z. 43, Fassung bis 31.10.2026) verlangte für ICC_items auf `rptR::BeetlesMale` zugleich Gleichheit mit (a) dem Vorgabeaufruf `rptR::rptBinary(…, link = "logit")`: 0,187930859738746, (b) dem Vignettenwert ANK-25: 0,188, und (c) `performance::icc()`: 0,223294850303548. (a) und (b) rechnen mit der Beobachtungsvarianz 1/(p(1 − p)) (rptR-Vorgabe `expect = "meanobs"`, p = 205/480), (c) mit π²/3. Keine Implementierung erfüllt (b) und (c) zugleich; der Abstand 0,0354 ist das 71-Fache der Toleranz `ANK-TOL.rptr.vignette_tol`. Die Zahlen liegen dreimal unabhängig vor (ANK-25 `verification`, PLAN.md Runde 1 Z. 605–655, PLAN-REVIEW.md Runde 1 Prüflauf 1 und 2) und stimmen auf 15 Stellen überein; der Betreiber hat sie am 31.10.2026 arithmetisch nachvollzogen (σ²/(σ² + π²/3) und 1/(p(1 − p)) mit p = 205/480).
- docs/01 §5 (Z. 58) und Formelsammlung §4 (Z. 175–181) legen für Logit σ²_ε = π²/3 fest (ANK-28). Der Code rechnet so (CRITERIA.json ACC-1: ICC_items 0,223294779042746).
- Ursprung des Widerspruchs: Formelsammlung §4 Z. 190 und die Prüfprotokolle vom 24.10.2026 (Erstprüfung A2, Zweitprüfung) führten den Vignettenwert 0,188 als Prüfwert für R_latent, obwohl die rptR-Vignette die Link-Skala seit der Umstellung auf `expect = "meanobs"` mit 1/(p(1 − p)) rechnet (ANK-25 `further_quotes`). Der Abnahme-Reviewer hat das am 31.10.2026 beim Nachrechnen gefunden (ACC-1).
- Der Arbiter hat HUMAN entschieden: Bindende Spec-Stellen widersprechen einander wörtlich, und nur der Betreiber ändert den Spec-Text (docs/01 Z. 8).

## Entscheidung

1. **Frage 1: Variante A.** Die latente Restvarianz für Logit bleibt π²/3; ICC_items wird gegen Orakel und Nachrechnung mit π²/3 geprüft, der Vignettenwert prüft nur die rptR-Installation.
   - docs/02 Z. 43 erhält den neuen Wortlaut von K-M1b-5: ICC_items gleicht `rptR::rptBinary(…, expect = "liability")` auf der Link-Skala, `performance::icc()` auf demselben `glmer`-Modell und der Nachrechnung σ²_Population/(σ²_Population + π²/3) (ANK-28), Toleranz `ANK-TOL.rptr.live_tol`; die installierte rptR-Version reproduziert mit dem Vorgabeaufruf die publizierten Punktschätzer (ANK-25, Toleranz `ANK-TOL.rptr.vignette_tol`), die kein Referenzwert für ICC_items sind. Gegenüber dem Vorschlag in ARBITER.md nennt der Wortlaut je Vergleich den Eintrag des Toleranzankers.
   - docs/01 §3 Nr. 12: Zusatz „(`expect = "liability"`, Restvarianz π²/3 nach `ANK-28`; ADR-024)“.
   - Formelsammlung §4 Z. 190 (`reference/privat/`, nicht versioniert) und ihre Kopie im Claude-Projekt: Abnahmesatz wie in ARBITER.md vorgeschlagen, Stand-Zeile mit Nachtrag 31.10.2026.
   - Unverändert bleiben docs/01 §5, Formelsammlung §4 Z. 175–181, ANK-25, ANK-28, ANK-TOL und der Code. Das golden-adr-Gate wird nicht berührt.
2. **Frage 2: `10-acceptance` für M1b wird wiederholt; der Plan läuft als Runde 2 weiter.** Dieser Commit entfernt unter `orchestrator/state/M1b/` die Marker `parked`, `reason` und `1-acceptance.done`. Der Reviewer übernimmt in der wiederholten Abnahmephase den neuen Wortlaut wörtlich nach CRITERIA.json, schließt ACC-1 und passt `tests/acceptance/test-m1b-5-binary-rptr.R` an (Block 1: `expect = "liability"`; Block 2, Vergleich der ICC_items mit 0,188, entfällt, Block 5 enthält die Installationsprüfung bereits). Danach führt das liegengebliebene Plan-Verdict (Runde 1, ESCALATE) regulär zum Arbiter; er entscheidet E1 gegen die berichtigte Spec. Plan Runde 2 beantwortet E1 bis E8 in PLAN-UPDATE.md.
3. **E7 / ACC-12, `orchestrator/config.env`:** `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full)'`. Der Ausdruck trifft genau `test-m1b-2-recovery-scripts`, `test-m1b-3-two-level-script` und `test-m1b-7-vignette-full-results` (Paketinstallation, Kurzläufe bis 2 × 20 Minuten, zweites Knit), nicht `test-m1b-7-vignette`; geprüft gegen die Dateinamen unter `tests/acceptance/`. Die schnellen Abnahmetests K-M1b-1, -4, -5, -6 und -7 bleiben im Mutationslauf.
4. **E8 / ACC-15, `orchestrator/orchestrate.sh` (ownership_check):** Ein Pfad kommt nur dann nach `OWNERSHIP_REMOVE`, wenn `git ls-files --error-unmatch` ihn nicht kennt. Versionierte Dateien stellt `git reset --hard` im Rollback wieder her; das anschließende `rm -f` hatte sie gelöscht (BACKLOG.md in `10-acceptance` M1b, Versuch 1). Die Änderung gehört auch in das harness-template.

## Begründung

- A ändert nur die Stellen, die 0,188 als π²/3-Wert behandeln, und ist mit allen übrigen bindenden Stellen vereinbar. B hätte Konvention (docs/01 §5, Formelsammlung §4, AGENTS.md), Code und die Schätzziele von S-bin-1 und S-bin-2 geändert, und K-M1b-5 wäre trotzdem rot geblieben: `performance::icc(approximation = "observation_level")` liegt 4,0e-4 neben der rptR-Vorgabe (PLAN-REVIEW Runde 1, Prüflauf 2).
- Methodik: Auf der latenten Skala mit π²/3 hängt ICC_items nicht vom Anteil p ab; Pipelines auf Datensätzen mit verschiedener Prävalenz bleiben vergleichbar, ordinal (clmm, π²/3) und binär rechnen gleich, und die Schätzziele der Simulationsszenarien haben feste wahre Werte. Nakagawa, Johnson & Schielzeth 2017 (Druckseite 7) unterscheiden die theoretische Varianz π²/3 ausdrücklich von 1/(np(1 − p)); rptRs „more accurate approximation“ betrifft die Beobachtungsebene.
- Prüfstandard (docs/01 §2 Nr. 2): ICC_items hat drei Belege aus zwei Arten (zwei Pakete als Gegenrechnung, eigene Nachrechnung), die auf 1e-15 übereinstimmen; der Literaturwert bleibt als Installationsprüfung erhalten, nach dem Vorbild von ANK-21 in K-M1b-1. Installationsprüfung: 0,187930859738746 gegen 0,188, Abstand 6,9e-5 innerhalb 5e-4.
- Verfahren: CRITERIA.json und `tests/acceptance/` gehören dem Reviewer; `30-plan-review` und `70-arbiter` dürfen sie nicht schreiben. Die Wiederholung der Abnahmephase vermeidet eine Rework-Runde gegen einen Test, der für spec-treuen Code rot ist. Der Weg über das liegengebliebene Verdict entspricht dem RUNBOOK („Arbiter meldet HUMAN“) und schließt den Streit formal; ein Neustart der Planung ab Runde 1 ließe ein Verdict mit derselben Rundennummer und eine als bindend geltende ARBITER.md zurück.

## Folgen

- Die Direktive aus ARBITER.md (Runde 1) ist mit dieser Entscheidung erledigt; ihre Nr. 2 (Logit rechnet mit π²/3) gilt als Teil von Variante A fort. Der Arbiter wird in M1b durch die Auflösung von E1 verbraucht; die Code-Phase hat dann `MAX_ROUNDS_REWORK + ARBITER_EXTRA_ROUNDS` Runden und parkt danach.
- E2 bis E6 aus `verdict-plan.json` Runde 1 sind nicht Gegenstand dieser Entscheidung; sie beantwortet der Builder in PLAN-UPDATE.md.
- Lehre für die Formelsammlung: Zahlenbeispiele aus Quellen gelten erst als Prüfwert, wenn die Rechenvorschrift der Quelle mit der eigenen übereinstimmt; bei rptR entscheidet `expect`.
