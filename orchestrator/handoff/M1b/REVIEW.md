# REVIEW — M1b, Runde 8 (Code-Review, letzte Runde)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 8 · Stand: 02.11.2026 · Keine Git-Kommandos.

Gegenstand:
- die Gate-Fakten der Runde 8: `orchestrator/state/M1b/gates.json` (`env.sha` `20b32da`, Phasen-Commit des Reworks r8; Gates 09:16 bis 09:43) und alle acht `gate-*.log`;
- der Diff seit `plan/M1b` (Basis `104ca4dd…`). Seit dem in Runde 5 vollständig geprüften Stand `a8f8db7` sind Produkt, Tests, Daten, Vignetten und Paketdateien unverändert (Prüflauf 1). Das Rework r8 hat nur `PROGRESS.md` und `REWORK-NOTES.md` geändert;
- der Mutationsbericht der Runde 7 (`reports/mutation/mutation.json`, 08:47:01), der nach ADR-038 Nr. 1 auch für Runde 8 gilt;
- `MUT-EQUIV.json` (16 Anträge) und `MUT-EQUIV-APPROVED.json` (15 Freigaben), beide unverändert seit Runde 5.

## Ergebnis

**Verdict PASS, `blocking` leer. M1b ist abgenommen.**

- **Gates:** Alle acht sind grün, `gates.result` ist `pass`. Kein Gate steht auf `error`.
  - territory ist wieder grün. Zwischen Rework r8 und Gates r8 lag kein weiterer Commit; die Audit-Basis `415857c` ist `HEAD^` des Rework-Commits `20b32da` (E41).
  - tests: alle 28 Abnahmedateien `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 6559 ]`, dazu testthat 5254, e2e 49 und fuzz 25 ohne Fehlschlag. Die Erwartungszahlen je Datei gleichen denen der Runde 7.
  - lint: `R CMD check --as-cran` endet mit `Status: OK`; die Vignette wird gebaut.
  - mutgate meldet nach ADR-038 Nr. 1 „kein geänderter Mutations-Scope“. Mutationsbeleg ist der Lauf der Runde 7 mit 94,09 bei verlangten 90,83; ich habe ihn aus dem Bericht nachgerechnet (Prüflauf 2).
- **ADR-038 Nr. 2 ist erfüllt (E42):**
  - `R/fit.R` und `R/grr.R` tragen die SHA-256 aus ADR-038;
  - alle 96 Dateien unter `tests/` und die übrigen 138 Paket-, Anker- und Regeldateien sind bytegleich mit dem Stand vor Rework r7. Keine Datei kam hinzu, keine fiel weg (Prüflauf 1);
  - laut Phasenlog des Reworks r8 schrieb der Builder nur `PROGRESS.md`, `REWORK-NOTES.md` und Diagnoseskripte unter `/tmp`.
- **Kriterien:** K-M1b-1 bis K-M1b-7 sind im tests-Gate grün; den Vignettenbau von K-M1b-7 belegt lint. M0, M1a und M2 laufen ohne Rückschritt.
- **Kein blocking-Befund nach ADR-035 Nr. 1:** kein Verstoß gegen ein Kriterium, kein rotes Gate, kein Rückschritt, kein still falsches Ergebnis bei regulären Plänen. Die 82 nicht freigegebenen Überlebenden sind Arbeit nach dem 26.11.2026 (BL-102).
- **In dieser Phase umgesetzt:**
  - Stand-Vermerke in BL-85, BL-93 und BL-102 bis BL-106, neuer Eintrag BL-107 (E43);
  - `MUT-EQUIV-APPROVED.json` unverändert, weil es keine neuen Anträge gibt;
  - kein neues ADR, weil ADR-035, ADR-037 und ADR-038 diese Runde decken.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` (mit Amendment ADR-027), `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` und der Prompt dieser Phase (`orchestrator/logs/M1b-50-code-review-r8-20261102-094318-prompt.md`).
- **Orchestrator, nur lesend:**
  - `gates.d/82-territory.sh`, `gates.d/86-mutgate.sh` (Z. 1–60) und `gates.d/88-mutfull.sh` (Fälligkeit, Dateiwahl);
  - `orchestrator/lib/r-mutation.R` Z. 95–101;
  - `config.env`: Kopf, Z. 104–107, 205–242, 267–276;
  - `state/M1b/` mit `territory-ok`, `round`, `reason` und `current-phase`, dazu `state/mut-baseline` (94.09);
  - `logs/orchestrate.log` (Ende) und das Phasenlog des Reworks r8 (`M1b-60-rework-r8-a1-20261102-091001.log`, 11331 Zeilen), dort alle ausgeführten Kommandos und alle Patches;
  - `ESCALATION-M1b.md`.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 7 (Neulauf);
  - `REWORK-NOTES.md`, Abschnitt Runde 8, und `PROGRESS.md`, Abschnitt Runde 8;
  - `MUT-EQUIV.json` und `MUT-EQUIV-APPROVED.json`;
  - `QA.md`: QA-M1b-001 bis -006 sind behoben, ihre Tests in e2e und fuzz grün; kein neuer QA-Lauf (`5b-qa.done`, kein `qa-requested`);
  - `ARBITER.md` mit der Direktive zu K-M1b-5: π²/3, rptR auf der Liability-Skala, ANK-25 nur als Installationsprüfung;
  - `PLAN.md` und `PLAN-UPDATE.md` nur in der Gliederung. Das Produkt ist seit Runde 5 unverändert, und REVIEW r5 hat den Diff gegen den Plan geprüft;
  - nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** `docs/02-statistikkern.md`, M1b (Z. 20–45), vollständig; ADR-035, ADR-037 und ADR-038 vollständig.
- **Produkt:** `R/fit.R` Z. 176–186, `R/grr.R` Z. 55–106, `R/run.R` Z. 177–182, `man/msa_fit.Rd` (Verweise auf `two_level` und die Vignette, Z. 85–86), `vignettes/validation.Rmd` Z. 120–235.
- **Visuelle Artefakte:** keine. M1b verlangt keine, und `orchestrator/state/M1b/shots/` ist leer.

## Gate-Fakten

| Gate | Runde 8 (`env.sha` `20b32da`, 02.11.2026, 09:16 bis 09:43) | Einordnung |
| --- | --- | --- |
| deps | pass: 25 Anforderungen; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4, rptR 0.9.23, performance 0.19.0 (`gate-deps.log` Z. 2–27) | – |
| lint | pass: „creating vignettes ... OK“ (`gate-lint.log` Z. 6), „checking re-building of vignette outputs ... OK“ (Z. 81), `R CMD check --as-cran --no-manual`: `Status: OK` (Z. 86) | K-M1b-7, Prüfweg Gate lint |
| tests | pass: testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5254 ]` (Z. 525); acceptance, 28 Dateien in 1273,9 s, `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 6559 ]` (Z. 979–981); e2e 49 (Z. 1008), fuzz 25 (Z. 1029); Kurzbefund „488 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1030) | Warnungen: BL-93 |
| trace | pass: „alle Kriterien sind wörtlich und beidseitig verknüpft“ | – |
| territory | pass: „letzter Diff sauber (builder/60-rework, Runde 8, Basis 415857c3…, 2026-11-02T09:16:26+01:00)“ (`gate-territory.log` Z. 2) | E41 erledigt |
| mutgate | pass: „kein geänderter Mutations-Scope“ (`gate-mutgate.log` Z. 2); `MUT_SCOPE_REGEX` nach ADR-038 Nr. 1 (`config.env` Z. 275–276) | kein eigener Beleg (ADR-038, Konsequenzen); Beleg: Lauf r7, Prüflauf 2 |
| golden-adr | pass: „keine Golden-/Ankeränderung“ | – |
| mutfull | pass: „nicht fällig in M1b“ | – |
| **result** | **pass** | |

- **Status error:** keiner.
- **Kriterien im tests-Gate** (`gate-tests.log`):
  - K-M1b-1 `m1b-1-engine-ordinal`: 34 Erwartungen (Z. 634);
  - K-M1b-2 `m1b-2-recovery-scripts`: 2155 (Z. 685; 130,7 s einschließlich Installation und beider Kurzläufe);
  - K-M1b-3 `m1b-3-two-level-script`: 687 (Z. 704; 15,4 s);
  - K-M1b-4 `m1b-4-two-levels`: 37, dazu zwei Warnungen aus dem Testhelfer (Z. 711–737, BL-93);
  - K-M1b-5 `m1b-5-binary-rptr`: 9 (Z. 744);
  - K-M1b-6 `m1b-6-edge-cases`: 108 (Z. 762);
  - K-M1b-7 `m1b-7-vignette-full-results`: 204 (Z. 802) und `m1b-7-vignette`: 240 (Z. 845). Den Bau prüft lint.
- **Rückschritte:** keine. Grün sind m0-* (Z. 536–555, darunter `m0-api-snapshot` mit 259 Erwartungen), m1a-1 bis m1a-7 (Z. 565–625, darunter die AIAG-Blöcke m1a-2 mit 40 und m1a-3 mit 66 Erwartungen) und m2-1 bis m2-7 (Z. 859–976).
- **Gleich Runde 7:** Jede dieser Zahlen und alle vier Summenzeilen stimmen mit REVIEW r7 (Neulauf) überein.

## Eigene Prüfläufe

Alle Läufe am 02.11.2026 mit R 4.6.1, lme4 2.0.6 und ordinal 2026.7.26, im Repo und nur lesend.
- Die Probeskripte lagen unter `orchestrator/handoff/M1b/.probe-r8/` und sind am Ende per `unlink()` gelöscht.
- Kein Paketergebnis dient als Referenz. Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Bestand gegen ADR-038 Nr. 2.** SHA-256 aller Dateien unter `R/`, `tests/`, `inst/`, `man/`, `vignettes/`, `data/`, `data-raw/` und `reference/anchors/` sowie von `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `.Rbuildignore`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md` und `toolchain.json`. Verglichen wird gegen zwei Hash-Inventuren, die der Builder vor Rework r7 und vor Rework r8 unter `/tmp` angelegt hat. Die Hashes rechnet die Probe selbst; die Inventuren sind nur der Vergleichsstand.

   ```text
   acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180 R/fit.R
   004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e R/grr.R
   current files in scope: 234 | under tests/: 96
   == P1b: builder inventory before rework r7 (01.11.)
   snapshot file: /tmp/llmsa-m1b-r7-xqkpg5mb/before.json | mtime: 2026-11-01 23:38:41
   snapshot files in scope: 234 | under tests/: 96
   identical: 234 | changed: 0 | removed since snapshot: 0 | added since snapshot: 0
   == P1b: builder inventory before rework r8 (02.11.)
   snapshot file: /tmp/llmsa-m1b-r8-tbm5gjjf/before.json | mtime: 2026-11-02 09:11:42
   snapshot files in scope: 234 | under tests/: 96
   identical: 234 | changed: 0 | removed since snapshot: 0 | added since snapshot: 0
   == P1c: newest mtime per area (rework r8 started 09:10:01, gates r8 09:16-09:43)
   R                  files   14 | newest 2026-11-01 21:46:17 (R/fit.R)
   tests/testthat     files   49 | newest 2026-11-01 22:05:42 (tests/testthat/test-fit-latent-precision.R)
   tests/acceptance   files   33 | newest 2026-10-31 19:23:19 (tests/acceptance/test-m1b-7-vignette-full-results.R)
   tests/e2e          files    3 | newest 2026-11-01 03:06:33 (tests/e2e/test-m1b-qa-e2e.R)
   tests/fuzz         files    3 | newest 2026-10-31 11:17:10 (tests/fuzz/test-m1b-qa-fuzz.R)
   inst               files   52 | newest 2026-11-01 21:51:01 (inst/validation/sim/two_level_check_session.txt)
   man                files   21 | newest 2026-11-01 21:47:33 (man/msa_fit.Rd)
   vignettes          files    2 | newest 2026-10-31 10:15:25 (vignettes/validation.Rmd)
   ```

   - Seit dem Code-Review r7 (Marker 09:09:34) sind außerhalb von `orchestrator/` nur `PROGRESS.md` (09:15:38) und `STATUS.md` geändert, dazu `orchestrator/handoff/M1b/REWORK-NOTES.md` (09:15:38) (`find -newer`). Die Testverzeichnisse tragen Zeiten aus dem Gate-Lauf (09:23 bis 09:43); die Dateien darin sind unverändert.
   - Das Phasenlog des Reworks r8 enthält Patches nur für `/tmp/llmsa-m1b-r8-tbm5gjjf/verify_*.py`, `PROGRESS.md` und `REWORK-NOTES.md` (Log-Z. 8934–11033). Die übrigen Kommandos lesen oder schreiben nach `/tmp`.
   - **Folge:** Kein Test entfiel, keine Erwartung wurde geändert. Produkt, Anker, Daten und Vignette sind der Stand, den REVIEW r5 geprüft hat und auf dem der Mutationslauf der Runde 7 lief.

2. **Mutationsbericht der Runde 7 gegen Freigaben und Gate-Rechnung.** Der Bericht wird mit `jsonlite` gelesen, gezählt nach dem Schlüssel von `86-mutgate.sh` (Datei, `mutatorName`, Anfangszeile).

   ```text
   report mtime: 2026-11-02 08:47:01
   R/fit.R | report source == file: FALSE | report source + final LF == file: TRUE
   R/grr.R | report source == file: FALSE | report source + final LF == file: TRUE
             Killed RuntimeError Survived Timeout
     R/fit.R   1055           34       93      28
     R/grr.R    223           17        6       0
   mutants: 1456 | detected: 1306 | survivors: 99 | approved hits: 17 | undetected: 82
   gate score (approvals): 94.09 | without approvals: 92.95
   claims: 16 | approvals: 15
   approvals without builder claim: 1 R/grr.R:99 > → >=
   claims without approval: 0
   baseline file: 94.09
   ```

   - Der Bericht speichert den Quelltext ohne das letzte Zeilenende. Mit ihm sind beide Dateien bytegleich mit dem gemessenen Quelltext.
   - Score 100 · 1306 / 1388 = 94,09 ≥ 90,83 (Baseline 93,83 vor dem Lauf, `MUT_RATCHET_TOL=3` nach ADR-031). ADR-038 Nr. 2, Bedingung 1 ist damit belegt.
   - Die Bindung der Freigaben gilt fort (BL-85): gleicher Quelltext, gleiche 17 Treffer wie in REVIEW r7 (Neulauf), Prüflauf 1. Die Freigabe `R/grr.R:99` stammt aus M1a.
   - Es gibt keine neuen Anträge und keinen Antrag ohne Freigabe; nach `MUT-EQUIV-APPROVED.json` ist nichts zu schreiben.

3. **Funktionsdurchlauf am Endstand** (`pkgload::load_all()`), um sichtbare Defekte zu finden; Referenzen außerhalb des Pakets.

   ```text
   == S1 BeetlesMale: msa_fit ICC_items vs. direct glmer and sigma2 / (sigma2 + pi^2/3)
   msa ICC_items 0.223295 | direct 0.223295 | diff -7.13e-08
     formula: y ~ 1 + (1 | item)
     12 items x 1 prompts x 1 models x 1 block(s); 480 observations; 40-40 valid replicates per cell
      source variance     sd    pct
        item   0.9458 0.9725 22.3 %
    Residual   3.2899 1.8138 77.7 %
   == S2 two models (ordinal, probit): warning and derived marking
   warnings:
     - Two-level component(s) model use the range method (beta-hat^2/2), with positive bias: E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2; see ?msa_fit.
   derived: model
     formula: y ~ 1 + model + (1 | item) + (1 | prompt)
     model: range method, see ?msa_fit
   Gauge R&R of an LLM measurement system
     model: range method, see ?msa_fit
   == S3 edge cases (messages verbatim)
   ordinal, 2 items: At least three items are needed for ordinal outcomes.
   binary, value 2: Binary values must be 0 or 1.
   ordinal, one category: Response is constant: at least two observed categories are needed.
   ```

   - S1: Die direkte Rechnung ist `lme4::glmer(Colour ~ 1 + (1 | Population), family = binomial("logit"))` mit σ²/(σ² + π²/3); die Restvarianz 3,2899 ist π²/3 (ANK-28).
   - S2: Plan mit 30 Items, 3 Prompts, 2 Modellen und 2 Replikaten, `set.seed(20261102)`. Die Warnung nennt Ersatzverfahren, positive Verzerrung und Dokumentation. Beide Druckausgaben kennzeichnen die Komponente: die erste Zeile „range method“ stammt aus `print.msa_fit`, die zweite steht am Ende von `print.msa_grr` (Tabellen dazwischen gekürzt).
   - **Folge:** keine sichtbaren Defekte.

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:**
  - K-M1b-1 bis K-M1b-6 und der Testteil von K-M1b-7 sind im tests-Gate grün; den Bau ohne ERROR und WARNING belegt lint.
  - Der Vignettenabschnitt „Ordinal and binary outcomes (latent scale)“ weist ANK-25 als Installationsprüfung aus, „not reference values for `ICC_items`“ (`vignettes/validation.Rmd` Z. 174–177). Die Studientabellen lesen `<study>_results.csv`, sonst `<study>_check_results.csv`, und nennen `n_sim` aus der Datei (Z. 191–193, 225–226).
  - Die Direktive aus ARBITER.md gilt weiter: π²/3, rptR auf der Liability-Skala. Prüflauf 3 bestätigt die Nachrechnung unabhängig.
  - `?msa_fit` verweist auf die Studie `two_level` und die Vignette (`man/msa_fit.Rd` Z. 85–86).
- **API-Diff:** keiner. `m0-api-snapshot` ist grün (259 Erwartungen, Z. 536). `NAMESPACE` und `DESCRIPTION` sind bytegleich mit dem Stand vor Rework r7 (Prüflauf 1).
- **Tests:**
  - Keine Test-, Fixture-, QA- oder Abnahmedatei ist geändert, und es gibt keinen neuen Test (Prüflauf 1). Entkernte Tests, eingefrorene eigene Ausgaben oder harte Erwartungswerte können in dieser Runde nicht hinzugekommen sein.
  - Alle reproduzierenden QA-Tests sind grün (m1b-qa-e2e 26, m1b-qa-fuzz 13 Erwartungen).
- **Konfiguration:**
  - Keine Modellrolle hat Konfiguration geändert.
  - Der Betreiber hat drei Werte gesetzt, alle mit ADR: `MUT_SCOPE_REGEX` für Runde 8 (ADR-038 Nr. 1), `MAX_ROUNDS_REWORK=6` (ADR-038) und `MUT_RATCHET_TOL=3` (ADR-031).
  - Das Aussetzen des Mutationslaufs lässt keinen Fehler verschwinden (AGENTS.md, Integrität Nr. 6). Der Lauf der Runde 7 auf demselben Quelltext und denselben Tests ist grün (Prüfläufe 1 und 2).
  - Die Rückstellung vor M1c ist offen (E43, BL-107).
- **Daten:**
  - Die neun `_check_`-Dateien sind unverändert, ihre Einzelschätzer reproduzieren im Gate (m1b-2: 2155, m1b-3: 687 Erwartungen).
  - Der Builder hat keine Daten angelegt. Das AIAG-Datenblatt liegt vor; die AIAG-Blöcke sind grün.
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass; Prüflauf 1).
- **Sichtbare Defekte:** keine (Prüflauf 3).
- **Builder-Belege:**
  - REWORK-NOTES r8 behauptet keine Abnahme; Gate-Fakten zitiert der Builder als die der Runde 7, wie sie zur Phase vorlagen.
  - Die Hash- und Bestandsaussagen (R8-P1 bis R8-P3) bestätigt Prüflauf 1.
  - Eine Kleinigkeit: Als Erzeuger des Berichtsquelltexts nennt R8-P2 `orchestrator/lib/r-mutation.R:99`. Diese Zeile gehört zum Zweig für einen leeren Mutationsplan (Z. 96–100). Die Sache selbst stimmt, der Bericht speichert den Quelltext ohne letztes Zeilenende (Prüflauf 2).

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E42 | erledigt | ADR-038 Nr. 2 erfüllt (Prüfläufe 1 und 2) |
| E41 | erledigt | territory r8 grün (`gate-territory.log` Z. 2); Harness-Teil offen (BL-106) |
| E40 | erledigt für M1b | Runde 8 mit grünen Gates und PASS, kein Parken; Rückstellung vor M1c offen (E43) |
| E39 | entschieden: mutgate pass (Lauf r7) | 94,09 ≥ 90,83; 82 Überlebende ohne Freigabe, nicht blocking (BL-102) |
| E38 | offen, [INFRA], ohne Wirkung | alle 28 Abnahmedateien liefen; `r-tests.R` unverändert seit 27.10. (BL-104) |
| E43 | neu, [INFRA] | ADR-038-Zeile in `config.env` vor M1c entfernen (BL-107) |
| E37 | erledigt (Runde 7) | Datenblatt vorhanden, AIAG-Blöcke grün; Harness-Teil BL-103 Nr. 3 offen |
| E33–E36 | erledigt (Runde 5) | Produkt unverändert (Prüflauf 1) |
| E32, E35 | zurückgestellt (ADR-035 Nr. 2 und 3) | BL-100, BL-101 |
| E20 | Builder-Teil erledigt | BL-91; Reviewer-Teil offen (M1c, M1d) |
| E21 | unverändert, spec-gemäß | Kurzläufe im Gate reproduziert; BL-92 |
| E22 | unverändert | BL-86 |
| E23 | offen, Reviewer | BL-93 (Warnungen im Gate, Z. 711–737) |

## Einwände (Runde 8)

- [E38] (minor) [INFRA] Gate tests; BL-104 — **Befund:** Auch in Runde 8 ohne Wirkung: Kein Abnahmeblock ist rot, alle 28 Dateien liefen (`gate-tests.log` Z. 981). `orchestrator/lib/r-tests.R` (27.10.) behält die Abbruchgrenze von zehn Fehlschlägen. — **Vorschlag:** Betreiber: `options(testthat.progress.max_fails = Inf)` vor M1c.
- [E39] (minor) Gate mutgate (Lauf r7: `score=94.09 required=90.83`; r8: „kein geänderter Mutations-Scope“); ADR-038 Nr. 1; ADR-035 Nr. 1; BL-102 — **Befund:** Mutationsbeleg für Runde 8 ist der Lauf der Runde 7 auf bytegleichem Quelltext (Prüfläufe 1 und 2). 82 Überlebende ohne Freigabe in 60 Zeilen, Liste und Einordnung unverändert wie in REVIEW r7 (Neulauf). Nicht blocking: Das Gate ist grün, und kein Überlebender zeigt einen Verstoß nach ADR-035 Nr. 1. — **Vorschlag:** Nach dem 26.11.2026 Tests für die Logiklücken im M1b-Code (`R/fit.R:184`, `:331`, `:337`, `:338`, `:384–389`, `:394`) und Äquivalenzanträge für die wirkungsgleichen Mutanten (BL-102). Für M1c: Mit `MUT_RATCHET_TOL=2` verlangt mutgate 92,09.
- [E40] (minor) [INFRA] Rundenbudget; ADR-038 Nr. 3; BL-105 — **Befund:** Runde 8 ist `max_rounds` (6 + 2). Mit grünen Gates und PASS endet M1b regulär, ohne Parken. — **Vorschlag:** Betreiber: vor M1c `MAX_ROUNDS_REWORK=5` (ADR-038 Nr. 3; AGENTS.md, Rundenbudget).
- [E41] (minor) [INFRA] Gate territory (`gate-territory.log` Z. 2); BL-106 — **Befund:** erledigt für M1b. Die Audit-Datei (`territory-ok`: Rework r8, 09:16:26, Basis `415857c`) passt zu `HEAD^` des Rework-Commits `20b32da`, weil zwischen Rework und Gates niemand committet hat. — **Vorschlag:** Harness-Korrektur nach BL-106 Nr. 2 und 3.
- [E42] (minor) ADR-038 Nr. 2 — **Befund:** erfüllt.
  - mutgate r7 bestanden (94,09);
  - `R/fit.R` `acb4bac7…` und `R/grr.R` `004eedeb…` bytegleich;
  - unter `tests/` 96 von 96 Dateien bytegleich, keine entfallen oder hinzugekommen (Prüflauf 1). Damit wurde auch keine Erwartung abgeschwächt.
  - — **Vorschlag:** keiner.
- [E43] (minor) [INFRA] `orchestrator/config.env` Z. 275–276; `gates.d/86-mutgate.sh` Z. 20–24; ADR-038 Nr. 3; BL-107 — **Befund:**
  - `MUT_SCOPE_REGEX=^ADR-038-kein-Mutationslauf-M1b-Runde-8$` trifft keine Datei; mutgate meldet dann ohne Lauf „pass (kein geänderter Mutations-Scope)“.
  - Bleibt die Zeile stehen, ist mutgate in M1c und allen späteren Meilensteinen wirkungslos, und kein Log kennzeichnet das als Ausnahme. `88-mutfull.sh` liest `MUTFULL_FILES` und ist nicht betroffen.
  - Bis zur Rückstellung gelten außerdem `MUT_RATCHET_TOL=3` (Z. 232) und `MAX_ROUNDS_REWORK=6` (Z. 215).
  - — **Vorschlag:** Betreiber: ADR-038 Nr. 3 vor dem Start von M1c umsetzen; beim Start die CONFIG-Zeile in `orchestrate.log` auf „REWORK<=5“ prüfen. Harness: mutgate meldet `error`, wenn `MUT_SCOPE_REGEX` keine versionierte Datei trifft.
- [E23] (minor) BL-93 — **Befund:** unverändert. Die Abnahmehelfer in `tests/acceptance/test-m1b-4-two-levels.R:30–33` lösen über `lme4::nobars()` und `lme4::findbars()` zwei Warnungen aus (`gate-tests.log` Z. 713–737), kein Fehlschlag. Nach der letzten Gate-Runde ändere ich keinen Abnahmetest. — **Vorschlag:** Reviewer: bei der nächsten Abnahmepflege umstellen (BL-93).

## An den Betreiber

1. **M1b ist abgenommen.** Nach PASS bei grünen Gates folgt die Phase `done` (PROTOCOLS.md §1 Nr. 10: Tag `done/M1b` und PROGRESS-Prüfung).
2. **Vor dem Start von M1c** (E43, E40, BL-107):
   - ADR-038 Nr. 3: die zwei ADR-038-Zeilen in `config.env` löschen (Z. 275–276), `MUT_RATCHET_TOL=2`, `MAX_ROUNDS_REWORK=5`;
   - danach die CONFIG-Zeile in `orchestrate.log` prüfen.
   - `state/mut-baseline` steht auf 94,09. Mit Toleranz 2 verlangt mutgate in M1c 92,09 über `R/fit.R` und `R/grr.R`; ohne neue Tests oder Freigaben lag der Lauf der Runde 7 bei 94,09 (BL-102).
3. **Klasse-B-Vollläufe** nach der Abnahme (K-M1b-2, K-M1b-3; AGENTS.md, Domänenregeln):
   - `ordinal_recovery`, `binary_recovery` und `two_level` mit `n_sim` ≥ ANK-06; Anleitung in `inst/validation/sim/README.md`;
   - die Ergebnisdateien vor M1d committen;
   - BL-92: Nichtkonvergenzanteil je Szenario aus der Replikatdatei ablesen.
4. **`orchestrator/ESCALATION-M1b.md`** trägt noch die Meldung vom Parken am 02.11. um 00:11 („Codepfad festgefahren …“). Sie ist überholt.
5. **Harness nach M1b:**
   - BL-103 Nr. 3: Signalfalle und Restore, nie ohne Sicherung löschen;
   - BL-104: Abbruchgrenze der Tests;
   - BL-106: territory nach Betreiber-Commits;
   - BL-107: mutgate bei einem Scope, der keine Datei trifft.

## Backlog

- **Stand-Vermerke:**
  - BL-85: Bindung gilt fort, Bericht r7 auf bytegleichem Quelltext;
  - BL-93: Warnungen auch im Gate r8;
  - BL-102: Mutationsbeleg r7 gilt für r8;
  - BL-103: Nr. 3 offen;
  - BL-104: ohne Wirkung;
  - BL-105: Runde 8 mit PASS, kein Parken;
  - BL-106: territory r8 grün.
- **Neu:** BL-107, ADR-038-Zeile in `config.env` neutralisiert mutgate.
- Kein blocking-Befund steht offen.
