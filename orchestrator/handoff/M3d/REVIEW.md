# REVIEW — M3d, Runde 2

Rolle: Reviewer · Phase: `50-code-review` · Runde: 2 · Stand: 08.11.2026 · Gegenstand: Diff seit `plan/M3d` (`a4115ae`) bis `9077a71` (Builder r1 `638feaa`, QA `3a77744`, Reviewer r1 `ad96b54`, Builder r2 `f091eaa`, Gates r2 `9077a71`) · Gate-Fakten: `orchestrator/state/M3d/gates.json` (Runde 2, 08.11.2026 00:31, SHA `f091eaa`). Es gibt keine `ARBITER.md`, kein `PLAN-UPDATE.md`, keine `REVIEW-INPUT.md` und kein `MUT-EQUIV.json`. Keine Git-Kommandos.

Runde 1 steht in `REVIEW.md` von `ad96b54`. Was dort am Produkt geprüft ist, gilt weiter, weil das Produkt seitdem blobgleich ist (Prüflauf 1).

## Ergebnis

**Verdict PASS, blocking leer.**

- **Gates:** Alle acht Gates sind grün, `result: pass`.
  - tests: 866 Tests, 0 fehlgeschlagen, 0 Fehler, 1 übersprungen (`gate-tests.log` Z. 2450).
  - mutgate: Score 80,25 bei verlangten 80,00 (`gate-mutgate.log` Z. 2255).
  - Kein Gate hat Status `error`.
- **E11 ist erledigt und bestätigt.** Die in Runde 1 zurückgeführten Abnahmetests sind im Gate grün: `m1d-7-findings` mit 514 Erwartungen (Z. 1774), `m1d-8-robustness-wording` mit 49 (Z. 1782). Das sind genau die Zahlen aus Prüflauf 3 von Runde 1.
- **Rework des Builders:**
  - Geändert sind nur `PROGRESS.md` und `REWORK-NOTES.md`.
  - `R/`, `man/`, `inst/`, `DESCRIPTION`, `NAMESPACE`, `tests/testthat`, `tests/e2e` und `tests/fuzz` sind blobgleich zum Gate-Stand von Runde 1 (`4fc5539`).
  - Die Antworten zu E11 bis E17 nennen je eine Referenz und stimmen mit den Fakten überein.
- **Mutation:** Der Lauf von Runde 2 gleicht dem von Runde 1 je Mutant (Prüflauf 2). Die 265 Überlebenden sind nicht blocking, weil mutgate grün ist. Kein Antrag, daher kein `MUT-EQUIV-APPROVED.json`.
- **QA:** Kein roter reproduzierender QA-Test. Die Herabstufung von QA-M3d-001 bleibt begründet (E16).
- **Spec- und Vertragstreue:** Die Bewertung aus Runde 1 gilt weiter (K-M3d-1 bis K-M3d-6, ADR-053 Nr. 1 bis 18).
  - Die sechs M3d-Abnahmetests sind im Gate r2 grün, mit denselben Erwartungszahlen wie in Runde 1: 706, 13, 194, 513, 89 und 52 (Z. 2155, 2166, 2180, 2218, 2239, 2249).
- **Befunde:** Alle nonblocking.
  - E12 bis E17 sind unverändert offen und vertagt (BL-139 bis BL-143, BL-128).
  - Neu ist E18: zwei lme4-Warnungen im eigenen Abnahmehelfer. Sie bestehen schon seit M1b (BL-93) und liegen im Reviewer-Territorium.
- **Dateien dieser Phase:**
  - `REVIEW.md` und `verdict-code.json`.
  - `BACKLOG.md`: BL-93, BL-123, BL-128 und BL-139 bis BL-144 nachgeführt.
  - `CRITERIA.json`: Status von ACC-17 ergänzt. Der Rundlauf über `jsonlite` war vorher bytegleich. `criteria` und die übrigen `open`-Einträge sind unverändert (Prüflauf 4).
  - Keine Änderung unter `tests/acceptance/` (E18).

### An den Betreiber

1. **BL-123:** `orchestrator/state/mut-baseline` steht weiter auf `80.25`. Nach `done/M3d` und vor M3c entfernen.
2. **BL-138:** Nach dem nächsten Push die CI auf allen drei Systemen ansehen (`PUSH_REMOTE=0`).
   - M3d bringt fünf neue Unit-Testdateien unter `tests/testthat/`, die im lint-Gate nur unter Linux gelaufen sind.
3. **Laufzeit:** Der Gate-Lauf r2 dauerte vom 07.11. 09:45 bis 08.11. 00:31.
   - lint bis 09:49, tests bis 10:34, danach mutgate mit 49 921 s Mutationsdauer.
   - Das Ergebnis gleicht Runde 1 je Mutant, auch die vier Timeouts.
   - Für spätere Runden mit bytegleichem `R/` ist ein Neulauf also redundant. Ob er entfällt, entscheidet der Betreiber (Präzedenz ADR-038).
4. **AP1** (ADR-053 Nr. 19.2): unverändert. Leere Antworten werden Backendfehler. Über Fortsetzung und gemischte Stores entscheidet der Betreiber.

## Gate-Fakten (`orchestrator/state/M3d/gates.json`, Runde 2)

| Gate | Status | Kurzbefund | Bewertung |
| --- | --- | --- | --- |
| deps | pass | 31 Anforderungen erfüllt (R 4.6.1) | – |
| lint | pass | `R CMD check --as-cran`: Status: OK (`gate-lint.log` Z. 89) | Vignetten gebaut, Beispiele mit `--run-donttest` OK, Tests 95 s |
| tests | pass | 866 Tests; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen (Z. 2450) | E11 bestätigt; E18 (2 Warnungen, BL-93) |
| trace | pass | alle Kriterien wörtlich und beidseitig verknüpft | – |
| territory | pass | letzter Diff sauber (builder/60-rework, Runde 2, Basis `ad96b54`) | – |
| mutgate | pass | score 80,25, verlangt 80,00, Baseline 80,25, Floor 80 | je Mutant gleich Runde 1 (Prüflauf 2); E15 |
| golden-adr | pass | keine Golden-/Ankeränderung | – |
| mutfull | pass | nicht fällig in M3d | – |

- **tests im Einzelnen:**
  - `tests/testthat`: 7338 Erwartungen, 0 rot. Ein Skip, der bestehende Negativfall `test-backends.R:32` bei installiertem ellmer (Z. 693–697).
  - `tests/acceptance`: 18 550 Erwartungen, 0 rot, 2 Warnungen in `m1b-4-two-levels` (Z. 885–912, E18).
  - Grün sind unter anderem m0-api-snapshot (259), m1c-7-byte-equality (48), m1d-7 (514), m1d-8 (49), m2-4-backends (89), m2-7-robustness-pilot (375) und m3d-1 bis m3d-6.
  - `tests/simulation` 10, `tests/e2e` 818 und `tests/fuzz` 1580 Erwartungen, alle grün.
- **Gegen Runde 1** (Prüflauf 3): Die Schlusszeilen aller Testdateien sind gleich bis auf m1d-7 (vorher 1 rot und 511 grün, jetzt 514 grün) und m1d-8 (vorher 9 rot und 22 grün, jetzt 49 grün). Die zwei Warnungen standen schon im Gate r1.
- **Unveränderte Konfiguration:** Anzahl der Testdateien je Ordner (61, 66, 2, 8, 8) und `MUT_TEST_EXCLUDE` (`gate-mutgate.log` Z. 2) gleichen Runde 1. Nichts ist gelockert.

## Diff seit `plan/M3d` (Prüflauf 1)

- **Insgesamt 59 Pfade:** die 48 aus Runde 1 und elf neue. Seit dem Gate-Stand r1 (`4fc5539`) kamen drei Commits:
  - Reviewer r1 (`ad96b54`, 11 Pfade): `BACKLOG.md`, `CRITERIA.json`, `REVIEW.md`, `verdict-code.json`, `test-m1d-7-findings.R`, `test-m1d-8-robustness-wording.R`; dazu Orchestrator-Zustand (`STATUS.md`, `current-phase`, `territory-ok`, `code-review-r1-infra0.done`, `summary.json`).
  - Builder r2 (`f091eaa`, 8 Pfade): vom Builder `PROGRESS.md` und `REWORK-NOTES.md`; dazu Orchestrator-Zustand (`STATUS.md`, `current-phase`, `territory-ok`, `rework-r2.done`, `round`, `summary.json`).
  - Gates r2 (`9077a71`, 9 Pfade): nur Gate-Logs, `gates.json`, Marker und Status.
- **Gate-Stand r1 (`4fc5539`) gegen HEAD:** Kein Pfad unter `R/`, `man/`, `inst/`, `data/`, `vignettes/`, `reference/`, `tests/testthat`, `tests/e2e`, `tests/fuzz` und `tests/simulation` ist geändert. Ebenso unverändert sind `DESCRIPTION`, `NAMESPACE` und `orchestrator/state/mut-baseline`.
  - Unter `tests/acceptance/` sind nur die beiden Reviewer-Dateien aus Runde 1 geändert.
- **Arbeitsbaum gegen HEAD:** 894 versionierte Dateien. Abweichend sind nur die zwei QA-Dateien aus Runde 1, und zwar nur in CRLF (`QA.md` mit 1 CR, `tests/fuzz/test-m3d-qa-fuzz.R` mit 161 CR). Nach CRLF→LF sind beide gleich dem Blob.
- **Mutationsbericht:** Die eingebetteten Quellen aller sieben Dateien gleichen dem Arbeitsbaum. `report.key` nennt `f091eaa`.

## Rework des Builders (`REWORK-NOTES.md`, `PROGRESS.md`)

- **Punkt für Punkt:** E11 bis E17 sind je mit Referenz beantwortet.
  - E11 ist als [INFRA] eingeordnet, ohne Scheinfix. Die Seed-Attribute sind nicht entfernt.
  - E12 bis E17 sind vertagt, wie Runde 1 empfiehlt, und nicht als behoben ausgegeben.
  - Die Nachträge zu E9 und E10 aus PLAN-REVIEW stimmen: E9 setzte QA nach ADR-053 Nr. 14.6 um, E10 der Reviewer in Runde 1.
- **Belege:**
  - Gezielte Läufe in einer Paketkopie unter `/tmp`: 50 Blöcke, 1386 Erwartungen, 0 rot. Das sind Builder-Belege, keine Gate-Fakten. Sie widersprechen den Gates r2 nicht.
  - Die Inventur „R/: 15/15 byte-identical“ deckt sich mit Prüflauf 1.
- **PROGRESS:** Der neue Abschnitt „M3d — REWORK, Runde 2“ gibt die Fakten von Runde 1 richtig wieder (Gate-Zeilen, Score, Befund-IDs). „Die Bestätigung durch die Gates der Runde 2 steht aus“ ist mit diesem Review eingelöst. Die PROGRESS-Prüfung des Orchestrators vor `done/M3d` ist erfüllt, denn `PROGRESS.md` ist seit `plan/M3d` geändert.
- Kein neuer Test, keine geänderte Erwartung, keine Konfiguration, kein Antrag.

## Spec- und Vertragstreue, API-Diff, Integrität

- **K-M3d-1 bis K-M3d-6:** Die Bewertung aus Runde 1 gilt am blobgleichen Produkt (REVIEW r1, „Spec- und Vertragstreue“, Prüfläufe 3 bis 5).
  - Die Abnahme ist im Gate r2 grün: m3d-1 706, m3d-2 13, m3d-3 194, m3d-4 513, m3d-5 89 und m3d-6 52 Erwartungen.
- **ADR-053 Nr. 14.3:** Erfüllt, unverändert seit Runde 1.
  - `R/fit.R` ist seit `plan/M3d` unverändert.
  - `R/grr.R` und `R/robustness.R` ändern sich nur um die Seed-Zuweisungen und roxygen-Zeilen.
- **API:** `msa_report()` hat als letztes Argument `control_chart = NULL` (docs/01 §4, ohne ADR zulässig). m0-api-snapshot ist grün (259). Kein neuer Export, kein neuer Import.
- **Integrität:** Keine Golden- oder Ankeränderung (golden-adr). Keine entkernten oder übersprungenen Tests, keine gelockerte Konfiguration, keine erfundenen Daten. Harte Werte im Produkt wie in Runde 1 bewertet (BL-142 (3)).
- **ADR-053 Nr. 18.3** regelt für den CSV-Leser nur `colClasses`; das ist erfüllt. E12 bleibt deshalb ein Dokumentationsbefund.

## Mutation (Bericht `reports/mutation/mutation.json`, Prüflauf 2)

| Datei | Killed | Survived | RuntimeError | Timeout |
| --- | ---: | ---: | ---: | ---: |
| `R/backends.R` | 161 | 60 | 7 | 0 |
| `R/grr.R` | 239 | 6 | 15 | 0 |
| `R/parse.R` | 119 | 24 | 5 | 3 |
| `R/report-data.R` | 101 | 36 | 4 | 0 |
| `R/report.R` | 49 | 28 | 25 | 0 |
| `R/robustness.R` | 278 | 9 | 36 | 0 |
| `R/run.R` | 126 | 102 | 9 | 1 |

- **Score:** (1073 + 4 Timeout) / (1073 + 4 + 265 + 0 NoCoverage) = 80,25 %. Verlangt sind 80,00: Baseline 80,25 minus Ratchet 2 liegt unter dem Floor 80.
- **Gleich Runde 1:** Die Gate-Logs r1 (Blob `2bebd63`) und r2 haben je 2261 Zeilen. Sie unterscheiden sich nur in vier Zeilen:
  - Dauer des unmutierten Laufs 270,4 s gegen 272,4 s;
  - Zeitlimit je Mutant 1353 s gegen 1362 s;
  - Mutationsdauer 68 772,70 s gegen 49 920,87 s;
  - Schreibweise „required=80“ gegen „required=80.00“.
- **Je Mutant:** Die 1443 Fortschrittszeilen stimmen in Folge, Ergebnis, Mutator und Datei überein. Die 265 gelisteten Überlebenden sind dieselben in derselben Reihenfolge.
- **Timeouts:** wie in Runde 1 `R/parse.R:89` (2×), `:100` und `R/run.R:49`.
- **Überlebende auf seit `plan/M3d` geänderten Zeilen:** 67, wie in Runde 1 (backends 7, parse 9, report-data 36, report 3, robustness 1, run 11).
  - Die Einordnung aus Runde 1 gilt: gleichwertig nach Code-Lesung oder Testlücke bei richtigem Produkt (E15, BL-142).
  - mutgate ist grün, daher nicht blocking. Es gibt kein `MUT-EQUIV.json`, also keine Freigabe.

## QA

- QA läuft einmal je Meilenstein. In Runde 2 gibt es keine neue QA-Phase.
- Im Gate r2 sind alle QA-Tests grün: m3b-qa-e2e 259 (Z. 2352), m3d-qa-e2e 91 (Z. 2364), m3b-qa-fuzz 399 (Z. 2437) und m3d-qa-fuzz 195 (Z. 2444).
- **QA-M3d-001:** Die Herabstufung ist weiter begründet (E16). Kein roter reproduzierender Test; der Vertrag (ADR-053 Nr. 2 bis 4, 15.2) regelt Skalare, `NULL`, Länge 0 und `NA`; `msa_run()` übergibt einen Skalar.
- Kein offener [QA-PENDING]-Auftrag. BL-135 und ADR-053 Nr. 14.6 sind seit QA r1 erledigt.

## Abnahmetests des Reviewers

- **Runde 1:** Die drei Stellen aus ADR-053 Nr. 14.5 sind im Gate r2 grün, mit den in Prüflauf 3 vorhergesagten Zahlen (514 und 49). Die Gegenproben aus Runde 1 (neun verfälschte Varianten rot) gelten für dieselben Testdateien.
- **In dieser Phase:** keine Änderung unter `tests/acceptance/`. Eine Änderung nach dem Gate-Lauf ginge ungeprüft in `done/M3d`; deshalb bleibt auch E18 offen.

## Einwände (Runde 2)

- [E11] (minor) [INFRA] Gate tests Runde 1 (fail, `gate-tests.log` M3d r1 Z. 1784–1866, Z. 2618); ADR-053 Nr. 14.5.4; BL-144 — **Befund:** Rot waren nur test-m1d-7 Z. 145 und test-m1d-8 Z. 96 und 117, alle durch das zugelassene Attribut `seed`. Die Ursache lag im Reviewer-Territorium und ist seit Runde 1 zurückgeführt. **Erledigt** und durch das Gate r2 bestätigt: tests pass, m1d-7 514, m1d-8 49 (Z. 1774, 1782, 2450). — **Vorschlag:** keiner.
- [E12] (minor) ADR-053 Nr. 18.3; `?msa_run` („CSV stores retain text exactly“, `R/run.R:10`); BL-139 — **Befund:** unverändert seit Runde 1, `R/run.R` blobgleich. Ein Antworttext „NA“ wird nach `resume = TRUE` als fehlend zurückgegeben. Der Speicher bleibt bytegleich, K-M3d-1 ist erfüllt. — **Vorschlag:** wie Runde 1, nach dem 26.11.2026 (BL-139).
- [E13] (minor) ADR-053 Nr. 12.2, 18.2; `R/report-data.R:84–95`; Vorlage, Chunk `model-metadata`; `R/backends.R:230`; BL-140 — **Befund:** unverändert seit Runde 1. Die Darstellung „not reported“ steht neben beobachteten Werten, der Satz „Missing values are not reported.“ ist missverständlich, und `null` wird zu „NA“. Die Werte sind richtig. — **Vorschlag:** wie Runde 1, nach dem 26.11.2026 (BL-140).
- [E14] (minor) Sichtbarer Defekt im Bestand; `inst/templates/validation_report.Rmd`, Chunk `boot`; BL-141 — **Befund:** unverändert seit Runde 1. Ohne `boot` erscheint der Hinweis als Codeblock. — **Vorschlag:** wie Runde 1, nach dem 26.11.2026 (BL-141).
- [E15] (minor) Gate mutgate (pass, `gate-mutgate.log` M3d r2 Z. 2255); `reports/mutation/mutation.json`; BL-142 — **Befund:** Die Testlücken bei richtigem Produkt aus Runde 1 bleiben, je Mutant gleich (Prüflauf 2). Dazu `hash_object()` ohne Aufrufer und die doppelten Konstanten. — **Vorschlag:** wie Runde 1, beim nächsten Eingriff, frühestens nach dem 26.11.2026 (BL-142).
- [E16] (minor) `QA.md` QA-M3d-001; ADR-053 Nr. 2–4, 15.2; `R/parse.R:53`, `:109`; BL-143 — **Befund:** unverändert seit Runde 1, `R/parse.R` blobgleich. Vektoren der Länge 2 enden mit einem Fehler. Die Herabstufung bleibt begründet. — **Vorschlag:** wie Runde 1, nach dem 26.11.2026 (BL-143).
- [E17] (minor) Prüfauftrag 50-code-review (Momentaufnahme der eigenen Ausgabe nur gekennzeichnet); BL-128 (1) — **Befund:** unverändert seit Runde 1. Der Plotblock `tests/testthat/test-robustness-properties.R:277–312` ist nicht als Momentaufnahme gekennzeichnet. — **Vorschlag:** Kommentar beim nächsten Eingriff (BL-128).
- [E18] (minor) Gate tests (pass, `gate-tests.log` M3d r2 Z. 885–912); BL-93; Reviewer-Territorium — **Befund:** Die Abnahmehelfer `tests/acceptance/test-m1b-4-two-levels.R:30` und `:33` rufen `lme4::findbars()` und `lme4::nobars()` auf. lme4 2.0.6 warnt je einmal: „has moved to the reformulas package“. Kein Fehlschlag, kein Produktbezug. Die Warnungen standen schon in den Gates M3d r1 und seit M1b. — **Vorschlag:** Reviewer bei der nächsten Abnahmepflege, nicht im Code-Review (BL-93). Für den Builder kein Auftrag.

## Eigene Prüfläufe

R-Skripte unter `orchestrator/handoff/M3d/.probe-review-r2/`, am Ende gelöscht. Aufruf mit `Rscript --vanilla`, R 4.6.1, `REPO_ROOT` aus R gesetzt.

### Prüflauf 1 — Diff ohne Git

- Ein R-Leser der Git-Objekte (lose Objekte und Packs mit Index v2, OFS/REF-Deltas, SHA-1 jedes Objekts nachgeprüft) folgt:
  - `refs/tags/plan/M3d` (Tag-Objekt `807c1cf`) → `a4115ae`;
  - `refs/heads/main` → `9077a71`.
- **Kette:** `a4115ae` → `638feaa` → `414e1a9` → `3a77744` → `4fc5539` → `ad96b54` → `f091eaa` → `9077a71`. Die Pfade je Commit stehen oben.
- **Vergleich `4fc5539` gegen `9077a71`:** 20 Pfade, alle außerhalb des Produkts (Liste oben).
- **Arbeitsbaum:** SHA-1 jeder versionierten Datei gegen den Blob in HEAD. Abweichend sind nur die zwei CRLF-Dateien.

### Prüflauf 2 — Mutationsbericht und Gate-Log

- **Bericht:** mit `jsonlite` gelesen, Status je Datei (Tabelle oben). Der Score ist nachgerechnet.
- **Geänderte Zeilen:** Die neuen und geänderten Zeilen seit `plan/M3d` sind mit `diff` gegen den alten Blob bestimmt, die Überlebenden darauf zugeordnet.
- **Logvergleich:** Das Gate-Log r1 ist aus Blob `2bebd63` gelesen und zeilenweise verglichen, ebenso die Fortschrittszeilen je Mutant und die gelisteten Überlebenden. Ergebnis wie oben.

### Prüflauf 3 — tests-Gate r1 gegen r2

- Das Gate-Log r1 ist aus Blob `4697536` gelesen. Verglichen sind die Ergebniszeilen je Ordner und die Schlusszeile jeder Testdatei.
- Unterschiede gibt es nur bei m1d-7 und m1d-8. Die zwei Warnungen in m1b-4 stehen in beiden Läufen.

### Prüflauf 4 — `CRITERIA.json`

- Der Rundlauf `fromJSON` → `toJSON(pretty = TRUE, auto_unbox = TRUE)` + LF ist vorher bytegleich (33 488 Byte).
- Danach ist nur der Status von ACC-17 ergänzt. `criteria` und die übrigen 16 `open`-Einträge sind `identical()`, das JSON ist gültig.
- Der trace-Gate liest nur `.criteria` (`70-trace.sh:14–36`).

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/prompts/50-code-review.md`, `orchestrate.sh` (`path_allowed` Z. 515–544, `verdict()` Z. 734–756, Abschluss Z. 1059–1096), `gates.d/70-trace.sh`.
- **Spezifikation:** docs/04 M3d (Ergebnissatz, K-M3d-1 bis K-M3d-6); ADR-053 Nr. 17 bis 19 und Konsequenzen.
- **Handoff M3d:** `CRITERIA.json`, `QA.md`, `REVIEW.md` und `verdict-code.json` aus Runde 1, `REWORK-NOTES.md` Runde 2, `PROGRESS.md` (Abschnitt REWORK Runde 2 als Diff).
- **Gates:** `gates.json`, alle `gate-*.log` (tests: Ergebnisse, Warnungen, Schlusszeilen; mutgate: Kopf, Schluss und Vergleich mit r1), `reports/mutation/mutation.json` und `report.key`. `orchestrator/state/M3d/shots/` ist leer. `orchestrate.log` mit den Phasenzeiten.
- **Backlog:** BL-93, BL-123, BL-128 und BL-130 bis BL-144.
