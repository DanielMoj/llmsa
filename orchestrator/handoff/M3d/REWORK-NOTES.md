# REWORK-NOTES — M3d, Runde 2

Rolle: Builder · Phase: REWORK · Stand: 07.11.2026.

Keine Produktänderung erforderlich. `REVIEW.md` und `verdict-code.json`
der Runde 1 enthalten keine blocking-Befunde. Das einzige rote Gate ist
`tests`; seine Ursache liegt nach E11 und ADR-053 Nr. 14.5 im
Reviewer-Territorium. Der Reviewer hat die drei betroffenen Stellen bereits
korrigiert. Die Bestätigung durch die Gates der Runde 2 steht aus.
E12 bis E17 bleiben gemäß REVIEW („Für REWORK Runde 2“) vertagt.

Geändert sind ausschließlich dieser zugewiesene Handoff und
`PROGRESS.md`. Keine Änderung an Produktcode, Hilfeseiten, Vorlagen,
bestehenden Tests, Abnahmetests, QA-Tests, Ankern, Gates oder Schwellen;
keine neuen Tests und keine Mutationsanträge oder Freigaben.

Gelesen sind das Kontextmanifest (AGENTS, IMPLEMENTATION-RULES,
PROTOCOLS, Handoff-Schema, REVIEW, verdict-code, gates samt rotem Log,
CRITERIA und LESSONS), der M3d-Abschnitt von PROGRESS, docs/01,
die M3d-Kriterien in docs/04, ADR-053 zu Seed-Provenienz und Übergabe,
die betroffenen aktuellen Abnahmestellen, QA.md sowie die unten genannten
Backlog-Einträge. Eine `ARBITER.md` liegt für M3d nicht vor. Die
LESSONS-Lehre zur allgemeinen Absicherung von Engine-Aufrufen begründet
hier keine Änderung: Es liegt kein entsprechender Produktbefund vor.

## Antworten auf jede Befund-ID

| ID | Antwort, Referenz und betroffene Dateien |
| --- | --- |
| **E11 / BL-144** | **OUT-OF-TERRITORY [INFRA].** Ref: Gate `tests`, `orchestrator/state/M3d/gate-tests.log:1784–1866`, Schluss in Zeile 2618; ADR-053 Nr. 14.5.4: „Bis dahin sind genau diese drei Tests rot. Das ist kein Befund gegen den Builder.“ Die zehn negativen Erwartungen betreffen nur `tests/acceptance/test-m1d-7-findings.R:145` und `test-m1d-8-robustness-wording.R:96`, `:117` im damaligen Gate-Stand. Der Reviewer hat den ersten Vergleich auf done/M1d gegen done/M1c zurückgeführt und prüft in den beiden anderen Blöcken das zusätzliche `seed` separat, den Rest weiterhin mit `identical()`. Die aktuellen Dateien wurden gelesen, aber vom Builder weder geändert noch als eigener vollständiger Abnahmelauf ausgeführt. Die Tag-Vergleiche rufen `acc_git()` auf; sie bleiben wegen des Git-Verbots beim Orchestrator. REVIEW Prüflauf 3 dokumentiert die erfolgreiche Reviewer-Prüfung einschließlich Negativproben; BL-144 ist dort erledigt. Gate-Bestätigung bleibt offen. Kein Entfernen der vertraglich geforderten Seed-Attribute als Scheinfix. |
| **E12 / BL-139** | **Vertagt, nonblocking.** Ref: ADR-053 Nr. 18.3, REVIEW E12. Betroffen: CSV-Leser `R/run.R:171–177` und die Aussage in `?msa_run`. Der Text `"NA"` wird beim Einlesen als fehlend interpretiert; laut Review bleibt die Speicherdatei unverändert und K-M3d-1 erfüllt. Die Einschränkung ist nicht behoben. Dokumentationspräzisierung oder zitatbewusster Leser mit Regressionstest bleiben wie im Backlog für nach dem 26.11.2026 vorgesehen. |
| **E13 / BL-140** | **Vertagt, nonblocking.** Ref: ADR-053 Nr. 12.2 und 18.2, REVIEW E13. Betroffen: `R/report-data.R:84–95`, `inst/templates/validation_report.Rmd` (model-metadata), `R/backends.R:230`. Darstellung fehlender Metadaten neben vorhandenen Werten, der Satz „Missing values are not reported.“ und die Unterscheidung null/NA bleiben offen. Die vom Reviewer festgestellten Werte sind richtig; die Darstellungsänderung und das Durchreichen von NULL erfolgen nach dem 26.11.2026 gemäß Backlog. |
| **E14 / BL-141** | **Vertagt, nonblocking.** Ref: REVIEW E14. Der bestehende Chunk `boot` in `inst/templates/validation_report.Rmd` rendert den Hinweis ohne Bootstrap als Codeblock. `results='asis'`, die explizite Tabellenausgabe und die zugehörige Gegenprüfung der Berichtsleser bleiben für nach dem 26.11.2026 vorgesehen. Keine Vorlagenänderung in dieser Runde. |
| **E15 / BL-142** | **Vertagt, nonblocking.** Ref: `gate-mutgate.log:2255`, `reports/mutation/mutation.json`, REVIEW E15. `mutgate` ist mit 80,25 bei geforderten 80 grün; `mutfull` ist in M3d nicht fällig. Die genannten Testlücken in `R/parse.R`, `R/report-data.R`, `R/run.R` und `R/backends.R` sowie ungenutztes `hash_object()` in `R/utils.R` und doppelte Konventionen in `R/grr.R`/`R/report.R` bleiben im Backlog. Die Ausnahme für ein rotes Mutationsgate ist hier nicht einschlägig. Keine Änderung des richtigen Produktverhaltens zur Mutantentötung, keine Gleichwertigkeitsbehauptung und kein `MUT-EQUIV.json`. Ergänzungen beim nächsten Eingriff, frühestens nach dem 26.11.2026. |
| **E16 / QA-M3d-001 / BL-143** | **Vertagt, nonblocking.** Ref: ADR-053 Nr. 2–4 und 15.2, REVIEW E16, QA.md. Betroffen: Vektorlängenprüfung in `R/parse.R:53`, `:109`. Der Vertrag umfasst Skalare, NULL, Länge 0 und NA; die gemeldeten Vektoren der Länge 2 liegen außerhalb dieses Vertrags. `msa_run()` übergibt einen Skalar. Einheitliche Vorabprüfung und ein Längen-2-Test bleiben nach dem 26.11.2026 vorgesehen. Kein offener QA-PENDING-Auftrag und kein als behoben behaupteter Parserbefund. |
| **E17 / BL-128 (1)** | **Vertagt, nonblocking.** Ref: REVIEW E17. Der Plotblock in `tests/testthat/test-robustness-properties.R:277–312` ist noch nicht als Momentaufnahme der eigenen Darstellung gekennzeichnet. Die Kennzeichnung bleibt für den nächsten Eingriff vorgemerkt. Der aktuelle Auftrag untersagt Änderungen bestehender Tests; auch diese Datei bleibt bytegleich. BL-128 (2) ist laut Review bereits erledigt. |

Die früheren PLAN-Befunde **E9 / ACC-17 (4)** und **E10 / ACC-17 (1–3)**
sind damit ebenfalls eingeordnet: QA hat E9 nach ADR-053 Nr. 14.6 umgesetzt;
der unten ausgeführte unveränderte M3b-E2E-Test bestätigt die getrennte
Seed-Prüfung. E10 ist die unter E11 dokumentierte Reviewer-Korrektur.
Es gibt keinen offenen `[QA-PENDING]`-Befund im aktuellen Code-Review.
`BACKLOG.md` wurde nur gelesen.

Der historische lokale Socketbefund **M3d-BUILD-INFRA-01** bleibt eine
**OUT-OF-TERRITORY [INFRA]**-Grenze des Builder-Prüfwegs. Ref:
PROGRESS, M3d BUILD, und REVIEW Runde 1, „Gate-Fakten“; damals
`System failure for: socket() (Operation not permitted)` bei
`httr2::req_dry_run()`. Im regulären Gate der Runde 1 sind K-M3d-3
und K-M3d-6 mit 194 bzw. 52 Erwartungen grün (`gate-tests.log:2270`,
`:2340`). Kein Produktfix nötig. Die Socket verwendenden Abnahme- und
M3d-E2E-Replays werden hier nicht wiederholt und nicht als lokal bestanden
ausgegeben. Die unten geprüften Unit-Replays verwenden den vorhandenen
Unit-Helfer und die unveränderten Betreiberaufzeichnungen.

## Prüfkommandos und tatsächlicher Output

### P1 — Gate- und Handoff-Fakten, rein lesend

```bash
python3 /tmp/llmsa-m3d-r2-l52al90t/audit-inputs.py
```

Exit 0; vollständiger Output in
`/tmp/llmsa-m3d-r2-l52al90t/input-audit.log`:

```text
Review: M3d round 1; verdict=REWORK; blocking=0.
Nonblocking IDs: E11, E12, E13, E14, E15, E16, E17.
Gate facts: M3d round 1; result=fail.
  deps: pass
  lint: pass
  tests: fail
  trace: pass
  territory: pass
  mutgate: pass
  golden-adr: pass
  mutfull: pass
Gate status error: 0.
Failing expectations in acceptance detail section: 10.
  test-m1d-7-findings.R: 1
  test-m1d-8-robustness-wording.R: 9
gate-tests.log:2618: r-tests: fail — 866 Tests in tests/testthat, tests/acceptance, tests/simulation, tests/e2e, tests/fuzz; 3 fehlgeschlagen, 0 Fehler, 1 übersprungen
gate-mutgate.log:2255: mutgate: pass (score=80.25 required=80 baseline=80.25 floor=80)
M3d ARBITER.md: absent.
M3d MUT-EQUIV.json: absent.
M3d MUT-EQUIV-APPROVED.json: absent.
```

Der erste Lauf dieses temporären Logzählers endete mit Exit 1 und
`Logged failing expectations: 20.`: Er zählte Ausführungsdetails und die
identische Wiederholung in „Failed tests“ zusammen. Der Leser begrenzt
die Zählung jetzt auf die Abnahmedetails vor „Results“. Ausschließlich
der eigene Leser unter `/tmp` wurde korrigiert; Gate-Logs und Tests
blieben unverändert.

### P2 — Vorhandene Unit- und QA-Prüfungen

Ausführung in `/tmp/llmsa-m3d-r2-l52al90t/package`, einer bytegleichen
Positivlisten-Kopie von R, man, inst, data, den drei Testordnern und
Paketmetadaten. Keine Git-Metadaten oder Schlüsseldateien wurden kopiert.
Der temporäre Treiber `run-targeted.R` setzt `REPO_ROOT` auf das Original,
`NOT_CRAN=true`, `TZ=Europe/Berlin` und die bestehende Testoption
`llmsa.test.ap1_recordings` auf `tests/fixtures/api` im Original.
Er öffnet `pdf(NULL)` und verwendet unverändert
`testthat::test_dir(load_package = "source", reporter = "summary",
stop_on_failure = FALSE)`. Alle ausgewählten Blöcke laufen; der Exit-Code
folgt den tatsächlichen Fehlschlägen und Fehlern. Keine Testhelfer oder
Erwartungen werden ersetzt. Die Ergebnisse liegen zusätzlich als RDS vor.

```bash
Rscript --vanilla /tmp/llmsa-m3d-r2-l52al90t/run-targeted.R tests/testthat '^(run-resume|parser-properties|backend-metadata|report-provenance|seed-provenance|robustness-transform|robustness-properties)$' M3d-R2-unit > /tmp/llmsa-m3d-r2-l52al90t/unit.log 2>&1
Rscript --vanilla /tmp/llmsa-m3d-r2-l52al90t/run-targeted.R tests/e2e '^m3b-qa-e2e$' M3d-R2-QA-seeds > /tmp/llmsa-m3d-r2-l52al90t/qa-seeds.log 2>&1
Rscript --vanilla /tmp/llmsa-m3d-r2-l52al90t/run-targeted.R tests/fuzz '^m3d-qa-fuzz$' M3d-R2-QA-fuzz > /tmp/llmsa-m3d-r2-l52al90t/qa-fuzz.log 2>&1
```

Alle drei Prozesse Exit 0. Tatsächliche Ergebniszeilen:

```text
M3d-R2-unit: 45 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 932 passed expectations; elapsed 12.383 s
M3d-R2-QA-seeds: 3 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 259 passed expectations; elapsed 1.717 s
M3d-R2-QA-fuzz: 2 blocks; 0 failed expectations; 0 error blocks; 0 warnings; 0 skips; 195 passed expectations; elapsed 1.148 s
```

Das sind 50 Blöcke und 1.386 erfolgreiche Erwartungen. Insbesondere
bleiben Seed-Attribute, RNG-Zustände und sonstige Ergebnisfelder unter
den bestehenden Seed-Prüfungen korrekt; die vom Reviewer genannten
minor-Befunde werden dadurch nicht als behoben erklärt.

Die vollständigen Gates, die historischen Git-Vergleiche und der
Mutationslauf wurden nicht gestartet. Bei unverändertem Produktcode ist
auch kein erneuter Paketbau nötig; der letzte reguläre lint-Gate steht
auf `pass`. Ob der Betreiber Mutation erneut ausführt, entscheidet er
gemäß REVIEW. Der Builder setzt kein Gate aus und schreibt keinen Status.

### P3 — Integrität

Die SHA-256-Inventur vergleicht den Arbeitsbaum mit den 474 vor allen
Änderungen im Arbeitsbaum erfassten Dateien. Prüfkommando:

```bash
python3 /tmp/llmsa-m3d-r2-l52al90t/check-integrity.py
```

Exit 0; tatsächlicher Output:

```text
Inventory: 474 baseline files; 1 changed; 1 added; 0 removed.
Changed: PROGRESS.md
Added: orchestrator/handoff/M3d/REWORK-NOTES.md
Preserved baseline files: 473/474 byte-identical.
R/: 15/15 byte-identical.
man/: 21/21 byte-identical.
inst/: 94/94 byte-identical.
tests/: 169/169 byte-identical.
reference/anchors/: 56/56 byte-identical.
orchestrator/state/M3d/: 22/22 byte-identical.
Existing PROGRESS heading and history: byte-identical.
Tested package copy: 219 source, documentation, resource and test files byte-identical to the baseline.
Workspace: no Rplots.pdf or testthat-problems.rds.
Gate facts unchanged: round 1, result fail; no Builder verdict.
```

Die Inventur ersetzt weder das Territoriums-Gate noch die Abnahme.
Territoriumsprüfung, Phasen-Commit und erneute Gate-Fakten bleiben beim
Orchestrator; kein Git-Kommando wurde ausgeführt.
