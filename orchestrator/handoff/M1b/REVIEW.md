# REVIEW — M1b, Runde 7 (Code-Review nach dem Entparken)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 7, zweiter Review-Lauf nach dem Entparken · Stand: 02.11.2026 · Keine Git-Kommandos.

Gegenstand:
- die Gate-Fakten des Neulaufs der Runde 7: `orchestrator/state/M1b/gates.json` (`env.sha` `8d1763e`, Betreiber-Commit zum Entparken; 02.11.2026, 00:35 bis 08:47), alle acht `gate-*.log` und erstmals seit Runde 4 ein Mutationsbericht `reports/mutation/mutation.json`;
- der Diff seit `plan/M1b` (Basis `104ca4dd…`). Produktcode, Tests, Daten und Paketdateien sind seit dem in Runde 5 vollständig geprüften Stand `a8f8db7` unverändert. Seit dem Rework r7 sind nur Betreiberdateien (`orchestrator/config.env`, ADR-038) und die Reviewer-Dateien des ersten Laufs der Runde 7 hinzugekommen (Prüflauf 4);
- `MUT-EQUIV.json` (16 Anträge) und `MUT-EQUIV-APPROVED.json` (15 Freigaben), beide unverändert seit Runde 5; ADR-038 (Betreiber, 02.11.2026).

## Ergebnis

**Verdict REWORK, `blocking` leer. Es folgt Runde 8, die letzte (E40).**

- **Gates:** Sieben von acht sind grün: deps, lint, tests, trace, mutgate, golden-adr und mutfull. Rot ist nur territory; `gates.result` ist damit `fail`.
  - Ursache sind die Commits zum Parken und Entparken. `82-territory.sh` verlangt als Audit-Basis der letzten Modellphase `HEAD^`. Zwischen dieser Modellphase (erster Review-Lauf r7, Basis `6fdc42c`) und den Gates liegen aber zwei Commits außerhalb der Modellphasen: der Park-Commit des Orchestrators `c80fb40` und der Entpark-Commit des Betreibers `8d1763e` (E41).
  - Keine Rolle hat ihr Territorium verletzt. Der Befund ist [INFRA] und für den Builder nicht blockierend; ADR-038 (Kontext) stellt dasselbe fest.
  - PASS ist ausgeschlossen, solange `gates.result` nicht `pass` ist (SCHEMA.md; Prompt dieser Phase).
- **Seit dem Datenverlust in Runde 5 entscheiden die Gates erstmals wieder über das Produkt.** Das Datenblatt ist wiederhergestellt; sein SHA-256 ist der von ANK-10 (Prüflauf 4). Damit sind grün:
  - lint: `R CMD check --as-cran` endet mit `Status: OK`;
  - tests: Alle 28 Abnahmedateien liefen, `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 6559 ]`. Dazu kommen testthat (5254), e2e (49) und fuzz (25) ohne Fehlschlag.
  - K-M1b-1 bis K-M1b-7 sind damit erfüllt, ebenso M0, M1a und M2 ohne Rückschritt.
- **mutgate:** pass mit Score 94,09 bei verlangten 90,83 (1456 Mutanten, 7 h 43 min). Den Score habe ich aus dem Bericht nachgerechnet (Prüflauf 1).
  - Die 15 Freigaben treffen genau ihre 17 Mutanten, gebunden nach Spalte, Ersetzung und Quellzeile (BL-85): die 16 Anträge des Builders und die Freigabe `R/grr.R:99` aus M1a. Ohne Freigaben läge der Score bei 92,95.
  - 82 Überlebende sind ohne Freigabe. Bei grünem Gate sind sie nicht blocking, und keiner verdeckt einen Verstoß gegen ein Kriterium oder ein still falsches Ergebnis (ADR-035 Nr. 1).
  - Die Lücke im binären Konvergenzzweig habe ich gezielt nachgeprüft (Prüflauf 2): Das Verhalten stimmt, es fehlt nur der unterscheidende Test. Liste und Einordnung stehen unten, die Nacharbeit nach dem 26.11.2026 in BL-102.
- **Runde 8 (E40, E42):**
  - Der laufende Orchestrator hat beim Start `MAX_ROUNDS_REWORK=6` gelesen; `max_rounds` ist also 8. Dieses Verdict führt zu Rework r8, nicht zum Parken.
  - Nach ADR-038 läuft in Runde 8 kein Mutationslauf; Mutationsbeleg bleibt der Lauf dieser Runde.
  - Am Produkt ist nichts zu tun. ADR-038 Nr. 2 verlangt bytegleiche `R/fit.R` und `R/grr.R` und keinen entfallenen oder abgeschwächten Test.
- **In dieser Phase umgesetzt:**
  - Stand-Vermerke in BL-85, BL-93 und BL-102 bis BL-105, neuer Eintrag BL-106;
  - `MUT-EQUIV-APPROVED.json` unverändert, weil es keine neuen Anträge gibt;
  - kein neues ADR, weil ADR-037 und ADR-038 diese Runde decken.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` (mit Amendment ADR-027), `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, der Prompt dieser Phase (`orchestrator/logs/M1b-50-code-review-r7-20261102-084706-prompt.md`).
- **Orchestrator, nur lesend:**
  - `gates.d/82-territory.sh`, `gates.d/86-mutgate.sh` (Score- und Baseline-Rechnung) und `gates.d/_lib.sh`;
  - aus `orchestrate.sh`: `release_lock` und die Signalfalle (Z. 97–109), `rollback_attempt` (Z. 340–346), `changed_paths`, `snapshot_worktree` und `restore_worktree` (Z. 366–472), `ownership_check` (Z. 514–558), `commit_phase` (Z. 662–684), `verdict` (Z. 701–723), `park` (Z. 771–801) und `run_ms` (Z. 900–1071);
  - `config.env` (Kopf, Z. 198–276), `state/mut-baseline` (94.09), `state/M1b/territory-ok`, `state/M1b/reason`, `logs/orchestrate.log` bis Z. 168, `ESCALATION-M1b.md`.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` des ersten Laufs der Runde 7;
  - `REWORK-NOTES.md`, Abschnitt Runde 7;
  - `MUT-EQUIV.json` und `MUT-EQUIV-APPROVED.json`;
  - `QA.md`: QA-M1b-001 bis -006 sind behoben, ihre Tests in e2e und fuzz grün; kein neuer QA-Lauf;
  - `ARBITER.md` mit der Direktive zu K-M1b-5: π²/3, rptR auf der Liability-Skala, ANK-25 nur als Installationsprüfung;
  - `PLAN.md` und `PLAN-UPDATE.md` nur in der Gliederung, weil das Produkt seit Runde 5 unverändert ist und REVIEW r5 den Diff gegen den Plan geprüft hat;
  - nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** `docs/02-statistikkern.md`, M1b (Z. 20–45); ADR-035, ADR-037 und ADR-038 vollständig.
- **Produkt:** `R/fit.R` Z. 1–425 und 806–855, `R/grr.R` Z. 55–131, `vignettes/validation.Rmd` Z. 120–235. Dazu die Quelltexte aller übrigen Überlebenden im Mutationsbericht.
- **Visuelle Artefakte:** keine. M1b verlangt keine, und `orchestrator/state/M1b/shots/` ist leer.

## Gate-Fakten

| Gate | Runde 7, Neulauf (`env.sha` `8d1763e`, 02.11.2026 00:35 bis 08:47) | Einordnung |
| --- | --- | --- |
| deps | pass: 25 Anforderungen; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4 | – |
| lint | pass: Vignettenbau „creating vignettes ... OK“ (`gate-lint.log` Z. 6), `R CMD check --as-cran --no-manual`: `Status: OK` (Z. 86–88) | K-M1b-7, Prüfweg Gate lint |
| tests | pass: testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5254 ]` (Z. 524); acceptance, 28 Dateien in 1280,6 s, `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 6559 ]` (Z. 980–982); e2e 49 (Z. 1010) und fuzz 25 (Z. 1031) | die zwei Warnungen: BL-93 |
| trace | pass | – |
| territory | **fail**: „Audit-Basis 6fdc42cfad4176a097fe58198800902c4b409d33 passt nicht zur Modellphase c80fb4099d6dde76f0b3929820a9d36c02c60d70“ (`gate-territory.log` Z. 2) | E41, [INFRA] |
| mutgate | pass: `score=94.09 required=90.83 baseline=94.09 floor=80` (`gate-mutgate.log` Z. 1770). Unmutierter Vorlauf 144,6 s, 392 Tests, keiner rot (Z. 3); 1456 Mutanten, 27756 s (Z. 1464); muttest `[ KILLED 1278 \| SURVIVED 99 \| NO COVERAGE 0 \| ERRORS 79 \| TOTAL 1456 ]`, davon 28 Timeouts (Z. 1766–1768) | E39 |
| golden-adr | pass (keine Golden- oder Ankeränderung) | – |
| mutfull | pass („nicht fällig in M1b“) | – |
| **result** | **fail** | |

- **Status error:** keiner.
- **Kriterien im tests-Gate** (`gate-tests.log`):
  - K-M1b-1 `m1b-1-engine-ordinal`: 34 Erwartungen (Z. 633);
  - K-M1b-2 `m1b-2-recovery-scripts`: 2155 (Z. 683; 138,8 s einschließlich Installation und beider Kurzläufe);
  - K-M1b-3 `m1b-3-two-level-script`: 687 (Z. 702);
  - K-M1b-4 `m1b-4-two-levels`: 37, dazu zwei Warnungen aus dem Testhelfer (Z. 709–736, BL-93);
  - K-M1b-5 `m1b-5-binary-rptr`: 9 (Z. 742);
  - K-M1b-6 `m1b-6-edge-cases`: 108 (Z. 760);
  - K-M1b-7 `m1b-7-vignette-full-results`: 204 (Z. 801) und `m1b-7-vignette`: 240 (Z. 844); den Bau prüft lint.
- **Rückschritte:** keine. Grün sind m0-* (Z. 535–554), m1a-1 bis m1a-7 (Z. 564–624, darunter die AIAG-Blöcke m1a-2 mit 40 und m1a-3 mit 66 Erwartungen) und m2-1 bis m2-7 (Z. 858–977).
- **Abbruchgrenze (BL-104):** nicht erreicht, denn ohne Fehlschlag laufen alle Dateien.
- **Baseline:** mutgate hat `orchestrator/state/mut-baseline` von 93,83 auf 94,09 angehoben (`86-mutgate.sh:112–114`).

## Eigene Prüfläufe

Alle Läufe am 02.11.2026 mit R 4.6.1, lme4 2.0.6 und rptR 0.9.23, im Repo und nur lesend.
- Die Probeskripte lagen unter `orchestrator/handoff/M1b/.probe-r7-rerun/` und sind am Ende per `unlink()` gelöscht.
- Kein Paketergebnis dient als Referenz. Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Mutationsbericht gegen Freigaben und Gate-Rechnung.** Der Bericht wird mit `jsonlite` gelesen. Gezählt wird nach der Schlüsselregel von `86-mutgate.sh:32–45` (Datei, `mutatorName`, Anfangszeile). Jeder Treffer wird zusätzlich gegen `column`, Ersetzung und `code` der Freigabe geprüft.

   ```text
   mutants: 1456
             Killed RuntimeError Survived Timeout
     R/fit.R   1055           34       93      28
     R/grr.R    223           17        6       0
   report source equals file on disk: R/fit.R TRUE | sha256 acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180
   report source equals file on disk: R/grr.R TRUE | sha256 004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e
   detected 1306 | survivors 99 | approved hits 17 | undetected 82 | gate score 94.09
   R/fit.R:314 TRUE → FALSE | hits 1 | status Survived | cols 47 | claim cols 47 | code match TRUE | repl FALSE
   R/fit.R:315 FALSE → TRUE | hits 1 | status Survived | cols 64 | claim cols 64 | code match TRUE | repl TRUE
   R/fit.R:329 <n> + 1 → <n> + 1 | hits 1 | status Survived | cols 46 | claim cols 46 | code match TRUE | repl 2
   R/fit.R:415 + → - | hits 3 | status Survived | cols 37,46,54 | claim cols 37,46,54 | code match TRUE | repl - / - / -
   R/fit.R:440 TRUE → FALSE | hits 1 | status Survived | cols 45 | claim cols 45 | code match TRUE | repl FALSE
   R/fit.R:448 <n> + 1 → <n> + 1 | hits 1 | status Survived | cols 18 | claim cols 18 | code match TRUE | repl 1
   R/fit.R:448 <n> - 1 → <n> - 1 | hits 1 | status Survived | cols 18 | claim cols 18 | code match TRUE | repl -1
   R/fit.R:523 <n> + 1 → <n> + 1 | hits 1 | status Survived | cols 61 | claim cols 61 | code match TRUE | repl 2
   R/fit.R:523 x[<i>] → x[<i> + 1L] | hits 1 | status Survived | cols 61 | claim cols 61 | code match TRUE | repl 1 + 1L
   R/fit.R:608 <n> + 1 → <n> + 1 | hits 1 | status Survived | cols 33 | claim cols 33 | code match TRUE | repl 1
   R/fit.R:608 <n> - 1 → <n> - 1 | hits 1 | status Survived | cols 33 | claim cols 33 | code match TRUE | repl -1
   R/fit.R:709 TRUE → FALSE | hits 1 | status Survived | cols 52 | claim cols 52 | code match TRUE | repl FALSE
   R/fit.R:711 TRUE → FALSE | hits 1 | status Survived | cols 41 | claim cols 41 | code match TRUE | repl FALSE
   R/fit.R:717 TRUE → FALSE | hits 1 | status Survived | cols 86 | claim cols 86 | code match TRUE | repl FALSE
   R/grr.R:99 > → >= | hits 1 | status Survived | cols 52 | claim cols  | code match TRUE | repl >=
   unapproved survivors: 82 | distinct lines: 60
   == claims without approval ==
   ```

   - **Gate-Rechnung:** entdeckt sind Killed plus Timeout, also 1306; unentdeckt sind 99 minus 17 freigegebene, also 82. 100 · 1306 / 1388 = 94,09, wie im Gate. Ohne Freigaben wären es 100 · 1306 / 1405 = 92,95. Die 51 RuntimeError zählen nicht.
   - **BL-85 für diesen Bericht erledigt:**
     - Jede Freigabe trifft genau die beantragten Mutanten, mit Spalte und Ersetzung wie im Antrag. Der Schlüssel `R/fit.R:415` trifft die drei Spalten 37, 46 und 54.
     - Feld `code` ist jeweils die Quellzeile.
     - Der Quelltext im Bericht ist bytegleich mit den Dateien; die SHA-256 sind die aus ADR-038. Die Freigabe `R/grr.R:99` stammt aus M1a und hat keinen M1b-Antrag.
     - Es gibt keinen Antrag ohne Freigabe und keine neuen Anträge.

2. **Binäre Nichtkonvergenz, `R/fit.R:384–390`.** Für die Zweige dort gibt es keinen unterscheidenden Test (Überlebende `384:36`, `387:9` zweimal, `388:15`, `389:49`, `389:71`). Daten: `rptR::BeetlesMale`, abgebildet wie ACC-14, mit `pkgload::load_all()` des Repos.

   ```text
   == default control (test K-M1b-6 analogue: maxfun = 10, lme4 warns itself)
   converged: FALSE | singular: FALSE
   lme4 conv$opt: 4 | conv$lme4$messages: 1
     warning: convergence code 1 from bobyqa: bobyqa -- maximum number of function evaluations exceeded
     warning: failure to converge in 10 evaluations
     warning: convergence code 4 from Nelder_Mead: failure to converge in 10 evaluations
     warning: Model failed to converge with max|grad| = 0.0432823 (tol = 0.002, component 1)
   every recorded lme4 message reached the caller as a warning: TRUE
   == gradient check as message (diagnosis recorded, lme4 emits no warning)
   error: unknown check level for 'check.conv.grad'
   == all lme4 checks ignored (no recorded message, optimizer code only)
   converged: FALSE | singular: FALSE
   lme4 conv$opt: 4 | conv$lme4$messages: 0
     warning: convergence code 1 from bobyqa: bobyqa -- maximum number of function evaluations exceeded
     warning: failure to converge in 10 evaluations
     warning: convergence code 4 from Nelder_Mead: failure to converge in 10 evaluations
     warning: Binary model did not converge: optimizer code 4
   == regular fit
   converged: TRUE | singular: FALSE
   lme4 conv$opt: 0 | conv$lme4$messages: 0
   ```

   - **Ohne vermerkte lme4-Meldung** (alle Prüfungen von lme4 abgeschaltet) warnt `msa_fit()` selbst und setzt `converged` auf FALSE (`:387–390`). Das ist das dokumentierte Verhalten („Ordinal and binary non-convergence is warned, including a diagnosis stored by the engine without an emitted warning.“, `R/fit.R:144–145`).
   - **Der Wiederausgabe-Zweig `:386`** ist mit lme4 2.0.6 über dessen Prüfstufen nicht erreichbar. Die Stufe „message“ kennt lme4 nicht, und vermerkte Meldungen gibt lme4 selbst als Warnung aus. Der Zweig ist Absicherung.
   - **Folge:** Diese Überlebenden zeigen eine Testlücke, keinen Defekt. Die K-M1b-6-Prüfung deckt den Vorgabefall ab, in dem lme4 selbst warnt.
   - Ein Fehler der Probe selbst: Ihre letzte Zeile brach beim Ausgeben der Versionen ab (`cat()` mit `getRversion()`). Die Versionen stehen im deps-Gate.

3. **`R/fit.R:264` „+ → -“ in den Spalten 35, 44 und 52**, der `model.frame()`-Aufruf zur Zeilenauswahl. Verglichen werden je Plan Original und drei Mutanten: Spalten, Stufen, Zeilennamen sowie `(weights)` und `(offset)`. Die 200 zufälligen Pläne (Seed 20261102) nutzen `subset` mit doppelten Indizes, Gewichte, fehlende Gewichte, `offset` und `na.action`.

   ```text
   plans: 200 | mutant frames compared: 600 | identical selected columns, levels and row names: 600
   variables of y ~ item - prompt + model + block: list(y, item, prompt, model, block)
   ```

   - `model.frame()` wertet jede Variable der Formel aus; die Operatoren wählen nur Terme. Das ist derselbe Sachverhalt wie bei der freigegebenen Zeile 415.
   - Ohne Antrag gibt es keine Freigabe (SCHEMA.md), und bei grünem Gate ist keine nötig.

4. **Produktstand und geschützte Dateien.**

   ```text
   find R tests inst man vignettes data data-raw docs reference/anchors DESCRIPTION NAMESPACE NEWS.md IMPLEMENTATION-RULES.md contracts AGENTS.md toolchain.json PROGRESS.md BACKLOG.md .Rbuildignore orchestrator/lib orchestrator/gates.d orchestrator/orchestrate.sh orchestrator/verifier.sh orchestrator/config.env orchestrator/handoff -newer orchestrator/state/M1b/rework-r7.done -type f
   BACKLOG.md
   orchestrator/config.env
   orchestrator/handoff/M1b/REVIEW.md
   orchestrator/handoff/M1b/verdict-code.json
   docs/decisions/ADR-038-m1b-runde-8-territory-und-mutationsbefund.md
   acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180  R/fit.R
   004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e  R/grr.R
   3161a373027b7e61d4818659d3897f8d516ba2776ae145ab5544d26e4acbff16  reference/quellen/data/aiag/anova_example.csv
   files under reference/quellen and reference/privat: 646 (text mirror 638, privat 5)
   ```

   - Produkt, Tests, Daten und Paketdateien sind seit dem Rework r7 unverändert. Die SHA-256 der beiden Mutationsdateien sind die aus ADR-038 und aus REVIEW r5 bis r7.
   - Das Datenblatt hat den SHA-256 von ANK-10, `QUELLE.txt` liegt daneben. Wiederhergestellt hat es der Betreiber; seinen Inhalt habe ich nicht ausgegeben.
   - Die geänderte `config.env` und ADR-038 tragen 07:41. Beide sind Betreiberdateien.

## Überlebende Mutanten ohne Freigabe

mutgate ist grün; diese Liste ist **nicht blocking** (Prompt dieser Phase; ADR-035 Nr. 1). Zeile, Spalte und `mutatorName` sind wörtlich aus dem Bericht.

**`R/fit.R`, `msa_fit()` (Z. 176–425), M1b-Code, 34:**
- `call.` ohne Wirkung auf die Meldung, kosmetisch, 12 × `FALSE → TRUE`: 188:107, 191:112, 198:92, 201:91, 226:106, 245:78, 272:78, 273:113, 383:21, 386:82, 389:86, 413:83.
- Meldungstexte und Rückfalltexte, 5 × `<non-empty string> → ""`: 273:26, 382:75, 388:15, 389:49, 389:71.
- Logik ohne unterscheidenden Test, Verhalten des Originals richtig:
  - 384:36 `<non-empty string> → ""` sowie 387:9 `!<condition> → <condition>` und `<condition> → !(<condition>)`: binäre Nichtkonvergenz (Prüflauf 2);
  - 394:35 `<non-empty string> → ""`: `singular` für lme4-Modelle über `isSingular()` statt über die Schwelle 1e-6;
  - 184:15 `<non-empty string> → ""`: `levels` bei `type = "numeric"`;
  - 331:42 und 337:55 `TRUE → FALSE` (`symmetric` der beiden `eigen()`-Aufrufe) und 338:74 `> → >=` (Namensschwelle der Diagnose), wie schon in BL-102.
- Wirkungsgleich, aber nicht beantragt:
  - 264:35, 264:44, 264:52 `+ → -`, belegt durch Prüflauf 3;
  - nach dem Code, nicht gerechnet: 225:64 `NA_integer_ → NA` (Z. 234 wandelt nach `integer`), 370:46, 398:41, 406:54 und 408:54 `FALSE → TRUE` (`drop` bei mehrspaltigen Datenrahmen), 407:95 `FALSE → TRUE` (`stringsAsFactors` vor `rbind()` mit Zeichenspalte).

**`R/fit.R`, numerischer Kern aus M1a, 43:**
- `msa_numeric_balanced()`: 522:52 `TRUE → FALSE`; 525:25 `- → +`; 526:62 `- → +`; 526:76 `^ → *`; 526:77 `<n> - 1 → <n> - 1` und `<n> + 1 → <n> + 1`; 537:50 `TRUE → FALSE`; 549:58 `- → +`; 549:66 `^ → *`; 549:67 `<n> - 1 → <n> - 1`; 555:42 `< → <=`.
- `msa_numeric_reml()`: 593:64, 598:79 und 611:53 `FALSE → TRUE`; 604:38 `- → +`.
- `msa_numeric_step()`: 630:45 `< → <=`; 635:43 `FALSE → TRUE`; 636:31 `TRUE → FALSE`; 641:46 `< → <=`; 641:48 `<n> - 1 → <n> - 1` und `<n> + 1 → <n> + 1`.
- `msa_numeric_optimize()`: 656:40 und 656:60 `TRUE → FALSE`; 671:32 und 676:25 `<n> - 1 → <n> - 1`; 683:44 `* → /`.
- `msa_numeric_fit()`: 759:69 `* → /`; 764:23 `> → <`; 764:25 `<n> + 1 → <n> + 1`; 765:45 `NULL → NA`; 768:43 `|| → &&`; 768:79 `<= → <`; 768:82 `<n> - 1 → <n> - 1`; 769:50 `> → >=`; 772:29 `<n> - 1 → <n> - 1` und `<n> + 1 → <n> + 1`; 796:25 `|| → &&`; 797:71 `> → >=`.
- `vc_from_model()`: 815:32 `<non-empty string> → ""` und 815:53 `FALSE → TRUE`. `VarCorr()` eines `glmer`-Modells hat keine Zeile „Residual“; nach dem Code also ohne Wirkung.
- `print.msa_fit()`: 841:27 `<n> - 1 → <n> - 1` und `<n> + 1 → <n> + 1`, 841:34 `NA_real_ → NA`. Die Summe enthält die Restvarianz, Null tritt in gültigen Fits nicht auf.

**`R/grr.R`, 5:**
- `grr_stats()`: 79:66, 87:36 und 99:28 `NA_real_ → NA`; `vapply()`, die Division und `c()` heben das logische NA auf double. Dazu 99:54 `<n> - 1 → <n> - 1`: `grr_v > -1` gleicht bei nichtnegativen Komponenten `grr_v > 0`, wie die Freigabe 99:52. Alle vier sind nach dem Code wirkungsgleich und nicht beantragt.
- `print.msa_grr()`: 128:33 `<non-empty string> → ""`, nur die Einrückung der Zeile „range method“. Die Abnahme prüft den Inhalt (ACC-9 Nr. 4), nicht die Einrückung.

Einordnung:
- Kein Überlebender widerspricht einem Kriterium. Keiner zeigt ein still falsches Ergebnis bei regulären Plänen (ADR-035 Nr. 1 a und d).
- Die Testlücken im M1b-Code betreffen Nicht-Vorgabe-Steuerungen (Prüflauf 2), Diagnosetexte und Grenzwerte der Identifizierbarkeitsdiagnose.
- Nacharbeit nach dem 26.11.2026: Tests oder Äquivalenzanträge (BL-102). Vorher nicht, siehe E42.

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E37 | erledigt | Datenblatt wiederhergestellt, SHA-256 von ANK-10 (Prüflauf 4); lint, tests und mutgate grün |
| E38 | offen, [INFRA], in dieser Runde ohne Wirkung | Alle 28 Abnahmedateien liefen ohne Fehlschlag. `orchestrator/lib/r-tests.R` ist seit 27.10. unverändert (BL-104) |
| E39 | entschieden: mutgate pass | Score 94,09 ≥ 90,83; Freigaben gebunden (Prüflauf 1); 82 Überlebende ohne Freigabe, nicht blocking (BL-102) |
| E40 | geändert | `MAX_ROUNDS_REWORK=6`, `max_rounds` 8; Runde 8 folgt und ist die letzte |
| E41 | neu, [INFRA] | territory rot durch die Commits zum Parken (Orchestrator) und Entparken (Betreiber) (BL-106) |
| E42 | neu, Hinweis | Bedingungen für Runde 8 nach ADR-038 |
| E33–E36 | erledigt (Runde 5) | Produkt unverändert (Prüflauf 4) |
| E32, E35 | zurückgestellt (ADR-035 Nr. 2 und 3) | BL-100, BL-101 |
| E20 | Builder-Teil erledigt | BL-91; Reviewer-Teil offen (M1c, M1d) |
| E21 | unverändert, spec-gemäß | Kurzläufe im Gate reproduziert (m1b-2: 2155, m1b-3: 687 Erwartungen); BL-92 |
| E22 | unverändert | BL-86 |
| E23 | offen, Reviewer | BL-93 (Warnungen im Gate, Z. 711–735) |

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:**
  - K-M1b-1 bis K-M1b-6 und der Testteil von K-M1b-7 sind im tests-Gate grün; den Bau ohne ERROR und WARNING belegt das lint-Gate.
  - Die Vignette weist ANK-25 als Installationsprüfung aus, nicht als Referenz für ICC_items (`vignettes/validation.Rmd` Z. 174–177). Damit erfüllt sie den letzten Halbsatz von K-M1b-5 und den Prüfauftrag aus ACC-18.
  - Die Direktive aus ARBITER.md gilt weiter: π²/3 und rptR auf der Liability-Skala.
- **API-Diff:** keiner. m0-api-snapshot ist grün (259 Erwartungen, Z. 535). `NAMESPACE` und `DESCRIPTION` sind seit Runde 5 unverändert (Prüflauf 4).
- **Tests:** Seit Runde 5 ist keine Test-, Fixture-, QA- oder Abnahmedatei geändert, und es gibt keinen neuen Test. Entkernte Tests, eingefrorene eigene Ausgaben oder harte Erwartungswerte können in dieser Runde nicht hinzugekommen sein. Die QA-Befunde sind im Gate grün; kein reproduzierender QA-Test ist rot.
- **Konfiguration, nur Betreiber:**
  - `MAX_ROUNDS_REWORK=6` (`config.env` Z. 215) und das Aussetzen des Mutationslaufs für Runde 8 (Z. 275–276) tragen ADR-038; `MUT_RATCHET_TOL=3` trägt ADR-031.
  - Keine Modellrolle hat Konfiguration gelockert. Das Aussetzen ist kein Lockern, um einen Fehler verschwinden zu lassen (AGENTS.md, Integrität Nr. 6), denn mutgate dieser Runde ist grün auf demselben Quelltext.
  - Bedingung bleibt ADR-038 Nr. 2 (E42).
- **Daten:**
  - Das wiederhergestellte Datenblatt ist über den SHA-256 von ANK-10 als Original belegt; es ist keine Ersatzdatei.
  - Die neun `_check_`-Dateien sind unverändert, ihre Einzelschätzer reproduzieren im Gate (m1b-2, m1b-3).
  - Der Builder hat keine Daten angelegt.
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Sichtbare Defekte:** keine gefunden.
  - Der binäre Konvergenzpfad verhält sich wie dokumentiert (Prüflauf 2).
  - Die Druckausgaben kennzeichnen abgeleitete Komponenten (`R/fit.R:844–846`, `R/grr.R:128`).
- **Builder-Belege:** REWORK-NOTES r7 behauptet keine Abnahme und keine neuen Gate-Fakten. Die damals roten Gates sind durch diesen Lauf überholt.

## Einwände (Runde 7)

- [E37] (minor) [INFRA] Gates lint, tests und mutgate der früheren Läufe; BL-103 — **Befund:** erledigt. Der Betreiber hat das Datenblatt wiederhergestellt (SHA-256 `3161a373…acbff16` wie ANK-10), und die übrigen ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**` liegen wieder vor (646 Dateien). lint, tests und mutgate sind grün. — **Vorschlag:** keiner. Offen bleibt nur der Harness-Teil von BL-103 (Nr. 3), siehe „An den Betreiber“.
- [E38] (minor) [INFRA] Gate tests; BL-104 — **Befund:** In diesem Lauf ohne Wirkung: Kein Abnahmeblock ist rot, alle 28 Dateien liefen. `orchestrator/lib/r-tests.R` behält die Abbruchgrenze von zehn Fehlschlägen (Datei vom 27.10.). — **Vorschlag:** Betreiber: `options(testthat.progress.max_fails = Inf)`, nach M1b.
- [E39] (minor) Gate mutgate (pass, `gate-mutgate.log` Z. 1770); SCHEMA.md (MUT-EQUIV); BL-102 — **Befund:** Score 94,09 bei verlangten 90,83. Die Freigaben treffen genau die beantragten Mutanten (Prüflauf 1). 82 Überlebende sind ohne Freigabe, in 60 Zeilen (Liste oben). Nicht blocking: Das Gate ist grün, und kein Überlebender zeigt einen Verstoß nach ADR-035 Nr. 1. — **Vorschlag:** nach dem 26.11.2026 Tests für die Logiklücken im M1b-Code (`R/fit.R:184`, `:331`, `:337`, `:338`, `:384–389`, `:394`) und Äquivalenzanträge für die wirkungsgleichen Mutanten (unter anderem `:264` dreimal, Prüflauf 3). In Runde 8 nichts davon (E42).
- [E40] (minor) [INFRA] Rundenbudget: `orchestrate.sh:963–964`, `:1026–1050`, `:805–808`; `config.env` Z. 215 und 217; `orchestrate.log` Z. 165 — **Befund:**
  - Der Betreiber hat `MAX_ROUNDS_REWORK` auf 6 gesetzt; der laufende Orchestrator hat beim Start um 00:35 „REWORK<=6“ gelesen. Mit `arbiter-granted` ist `max_rounds` = 6 + 2 = 8.
  - Nach diesem Verdict REWORK ruft `run_ms` keinen Arbiter: Runde 7 ist kleiner als 8. Es startet Rework r8 (60-rework; `LADDER_ENABLED` ist leer).
  - Runde 8 ist `max_rounds`: Jedes Ergebnis außer PASS bei grünen Gates parkt M1b, weil der Arbiter verbraucht ist.
  - QA ist nicht fällig (`5b-qa.done`, kein `qa-requested`).
  - — **Vorschlag:** Betreiber: Nach M1b gilt ADR-038 Nr. 3 (zurück auf `MAX_ROUNDS_REWORK=5`).
- [E41] (minor) [INFRA] Gate territory (`gate-territory.log` Z. 2); `gates.d/82-territory.sh:11–14`; `orchestrator/state/M1b/territory-ok`; ADR-038 (Kontext); BL-106 — **Befund:**
  - Die Audit-Datei stammt aus der letzten Modellphase: dem ersten Review-Lauf r7, 00:11:32, mit Basis `6fdc42c` („orch(M1b): gates r7 (rc=1)“).
  - Das Gate vergleicht die Basis mit `HEAD^` zur Gate-Zeit. HEAD war der Entpark-Commit des Betreibers `8d1763e` (`gates.json` `env.sha`), `HEAD^` der Park-Commit des Orchestrators `c80fb40`. Zwischen der Basis `6fdc42c` und HEAD liegen der Review-Commit `fe26b61`, `c80fb40` und `8d1763e`; die Commit-Folge steht im Git-Status dieser Sitzung.
  - `territory-ok` schreibt `ownership_check()` nur nach einem sauberen Diff (`orchestrate.sh:553–556`). Das Rework r7 war im ersten Gate-Lauf der Runde 7 territory-grün (REVIEW r7, erster Lauf, Gate-Tabelle).
  - Rot ist also allein die Commit-Folge beim Parken und Entparken. Für den Builder ist das nicht blockierend (AGENTS.md, Handoff-Disziplin; SCHEMA.md).
  - In Runde 8 folgen Rework-Commit und Gates direkt aufeinander. Dann ist `HEAD^` die Basis des Reworks, und territory wird grün, sofern dazwischen niemand committet.
  - — **Vorschlag:** Betreiber: zwischen Rework r8 und Gates r8 nicht committen, nicht parken und nicht entparken. Harness nach M1b: BL-106. Builder: OUT-OF-TERRITORY.
- [E42] (minor) ADR-038 Nr. 1 und 2 — **Befund:** Für die Gates der Runde 8 trifft `MUT_SCOPE_REGEX` keine Datei; mutgate meldet dann „kein geänderter Mutations-Scope“ und ist kein eigener Beleg (ADR-038, Konsequenzen). Der Mutationsbeleg der Runde 7 gilt für Runde 8 nur unter diesen Bedingungen:
  - `R/fit.R` und `R/grr.R` sind bytegleich (SHA-256 `acb4bac7…` und `004eedeb…`);
  - unter `tests/` entfällt kein Test und wird keine Erwartung abgeschwächt.
  - Der Score hängt außerdem von dem übrigen Paketcode ab, den `msa_fit()` und `msa_grr()` aufrufen, etwa die Formatier- und Prüfhelfer unter `R/`. Jede Änderung unter `R/`, `tests/`, `inst/`, `data/` oder `vignettes/` müsste das Review r8 deshalb gesondert prüfen.
  - — **Vorschlag:** Builder, Runde 8: nur `PROGRESS.md` und `REWORK-NOTES.md` schreiben, nichts am Produkt, an Tests, Daten oder Dokumentation ändern, keine neuen MUT-EQUIV-Anträge. Reviewer r8: prüft ADR-038 Nr. 2 (SHA-256 der beiden Dateien, Bestand unter `tests/`); ein Verstoß ist blocking mit `ref` ADR-038.

## An den Betreiber

1. **Kein Eingriff nötig, damit Runde 8 läuft.** Nach diesem Verdict startet der Orchestrator selbst Rework r8, danach die Gates r8 und das Review r8 (E40).
2. **Zwischen Rework r8 und Gates r8 nichts committen** und M1b nicht parken oder entparken. Sonst ist territory wieder rot (E41), und Runde 8 ist die letzte.
3. **Während einer Modellphase kein Strg+C.**
   - `trap release_lock EXIT INT TERM` (`orchestrate.sh:109`) löscht bei INT die Sicherung `$OWNERSHIP_SNAPSHOT` (`:97–101`), und der Lauf geht weiter. Ein späterer Rollback löscht dann jeden gesicherten Pfad ohne Kopie (`:462–470`), auch die git-ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**`.
   - Den Ablauf vom 01.11. beschreibt der Kopf von `config.env` (Z. 1–6). `orchestrate.sh` ist seit 31.10. unverändert, BL-103 Nr. 3 also offen.
   - Ohne Datenblatt wären lint und tests der Runde 8 rot, und M1b parkte. Eine Kopie von `reference/quellen/` und `reference/privat/` außerhalb des Repos schützt dagegen.
4. **Gates r8, erwartet:**
   - mutgate „kein geänderter Mutations-Scope“ (ADR-038 Nr. 1), mutfull „nicht fällig“;
   - tests und lint wie in diesem Lauf: Abnahme rund 21 min, testthat rund 2 min, R CMD build und check rund 3 min.
5. **`orchestrator/ESCALATION-M1b.md`** trägt noch die Meldung vom Parken um 00:11 („Codepfad festgefahren …“). Sie ist veraltet, aber für den Lauf ohne Wirkung.
6. **Vor M1c:**
   - ADR-038 Nr. 3: die zwei ADR-038-Zeilen entfernen, `MUT_RATCHET_TOL=2`, `MAX_ROUNDS_REWORK=5`.
   - `state/mut-baseline` steht jetzt auf 94,09. Mit Toleranz 2 verlangt mutgate in M1c 92,09 über `R/fit.R` und `R/grr.R`. Dieser Lauf hatte 82 unentdeckte Mutanten (BL-102).
7. **Nach M1b:**
   - BL-103 Nr. 3: Signalfalle und Restore, nie ohne Sicherung löschen;
   - BL-104: Abbruchgrenze der Tests;
   - BL-106: territory nach Betreiber-Commits;
   - Betreiberänderungen in eigenen Commits. `config.env` und ADR-038 (07:41, während des Gate-Laufs geändert) sind nach Dateizeiten und Commit-Folge über `git add -A` (`orchestrate.sh:671`) im Gate-Commit `61f49c2` gelandet.

## Hinweise für Runde 8 (Builder)

- **Umfang:** kein blocking-Befund und keine Produktänderung. E38, E40 und E41 sind Betreiber-Sache. E39 ist bis nach dem 26.11.2026 zurückgestellt.
- **ADR-038 Nr. 2 und E42:**
  - `R/fit.R` und `R/grr.R` bytegleich;
  - unter `tests/` nichts entfernen oder abschwächen;
  - am besten außer `PROGRESS.md` und `REWORK-NOTES.md` gar nichts ändern.
- **Belege:**
  - die Gate-Fakten dieser Runde aus `gates.json` zitieren;
  - die SHA-256 der beiden Mutationsdateien mit echtem Output;
  - E41 als OUT-OF-TERRITORY beantworten;
  - auf jede Einwand-ID (E38 bis E42) Punkt für Punkt antworten.
- **Nicht tun:**
  - Dateien unter `reference/` anlegen oder ändern;
  - Tests umgehen;
  - lange Läufe starten, die Dateien im Arbeitsbaum hinterlassen, etwa `tests/acceptance/_snaps/` oder Ausgaben unter `inst/`;
  - an Befunden nach ADR-035 Nr. 2 oder an BL-102 arbeiten.

## Backlog

- **Stand-Vermerke:**
  - BL-85: Bindung gegen den Bericht dieser Runde geprüft;
  - BL-93: Warnungen auch im Gate;
  - BL-102: Bericht der Runde 7, Liste der Überlebenden, Folge für M1c;
  - BL-103: Dateien wiederhergestellt, Nr. 3 offen;
  - BL-104: in dieser Runde ohne Wirkung;
  - BL-105: Rundenbudget 6 + 2, Runde 8.
- **Neu:** BL-106, territory nach Betreiber-Commits zwischen der letzten Modellphase und den Gates.
- Kein blocking-Befund steht offen.
