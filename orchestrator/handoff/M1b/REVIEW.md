# REVIEW — M1b, Runde 6 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 6 · Stand: 01.11.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `ca34c5a` (`gates.json`, `env.sha`). Seit dem Review der Runde 5 hat der Builder nur `PROGRESS.md` und `REWORK-NOTES.md` geändert. Produktcode, Tests, Daten und Konfiguration sind unverändert (Prüflauf 3).
- die Gate-Fakten der Runde 6: `orchestrator/state/M1b/gates.json`, alle acht `gate-*.log` und `reports/mutation/unmutated.json`. Ein `mutation.json` gibt es auch in dieser Runde nicht.
- `REWORK-NOTES.md` der Runde 6, `MUT-EQUIV.json` (16 Anträge, unverändert seit Runde 5) und `MUT-EQUIV-APPROVED.json` (Runde 5).

## Ergebnis

**Verdict REWORK, `blocking` leer.**

- **Gates:** `gates.result` ist `fail`. Rot sind lint, tests und mutgate, die übrigen fünf sind grün.
  - Die Ursache ist dieselbe wie in Runde 5: Das geschützte Betreiber-Datenblatt `reference/quellen/data/aiag/anova_example.csv` fehlt (E37, [INFRA], BL-103).
  - Unter `reference/quellen/**` und `reference/privat/**` liegt weiterhin keine einzige Datei. Die Verzeichniszeiten stehen unverändert auf 20:25:32 bis 20:25:33, dem Rollback in Rework r5, Versuch 1 (Prüflauf 4).
  - Für den Builder ist das nicht blockierend (AGENTS.md, Handoff-Disziplin). PASS bleibt ausgeschlossen, solange `gates.result` nicht `pass` ist (SCHEMA.md). Es gilt ADR-037 Nr. 2 unverändert.
- **Rework der Runde 6:** richtig.
  - keine Produktänderung und keine Ersatzdaten;
  - E37 bis E39 sind Punkt für Punkt beantwortet, E37 und E38 als OUT-OF-TERRITORY mit echtem Output;
  - die Belege (R6-P2 bis R6-P4) decken sich mit den Gate-Logs der Runde 6 und mit Prüflauf 1.
- **Produkt:** Es ist unverändert seit dem in Runde 5 geprüften Stand `a8f8db7`, und der Implementierungshash der drei Sessiondateien stimmt (Prüflauf 3).
  - Die Prüfläufe 2 bis 8 der Runde 5 gelten deshalb unverändert.
  - Die Abnahme ohne Abbruchgrenze zeigt dasselbe Bild wie in Runde 5: Rot sind nur die 16 Testblöcke, die vom AIAG-Datenblatt abhängen (Prüflauf 1).
- **MUT-EQUIV:** Es gibt keine neuen Anträge. Alle 15 Freigaben treffen weiter ihre Quellzeile (Prüflauf 2). Ohne Bericht gibt es keinen Überlebenden, der zu benennen wäre.
- **An den Betreiber (E40, BL-105): Runde 7 ist die letzte Runde.**
  - Das Arbiter-Kontingent von M1b ist seit der Planphase verbraucht (`arbiter-granted`, 31.10.).
  - Ist das Verdict der Runde 7 nicht PASS bei grünen Gates, parkt der Orchestrator M1b mit „Codepfad festgefahren“. Benachrichtigt wird erst dann.
  - Das Rework der Runde 7 hat nach diesem Review nichts am Produkt zu tun. Werden die Dateien nach BL-103 vor dem Gate-Lauf der Runde 7 wiederhergestellt, entscheiden die Gates wieder über das Produkt, und ein PASS ist möglich.
- **In dieser Phase umgesetzt:** Stand-Vermerke in BL-85, BL-93, BL-102, BL-103 und BL-104 sowie BL-105 neu in `BACKLOG.md`. Kein neues ADR: ADR-037 Nr. 2 und 3 decken diese Runde. `MUT-EQUIV-APPROVED.json` bleibt unverändert.

## Gelesen

- **Rollen und Protokoll:**
  - `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`;
  - der Prompt `50-code-review` Runde 6.
- **Orchestrator, nur lesend:**
  - `orchestrate.sh`: Autonomie-Vorgaben (Z. 37–57), `verdict`, `arbiter`, `rebuild_reset` und `run_ms`;
  - `lib/r-tests.R`;
  - `config.env`, nur die Runden- und Gate-Werte;
  - `logs/orchestrate.log` bis 23:08, dazu Prompt und Diff-Blöcke des Rework-Logs der Runde 6 (`M1b-60-rework-r6-a1-20261101-225716.log`, Z. 9656–9733).
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 5, `REWORK-NOTES.md` der Runde 6;
  - `MUT-EQUIV.json` und `MUT-EQUIV-APPROVED.json`, beide seit Runde 5 unverändert;
  - `QA.md`: kein neuer QA-Lauf seit dem Nachlauf vom 01.11., kein offener QA-Befund; e2e und fuzz im Gate grün;
  - `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md`, `ARBITER.md` und `ESCALATION-M1b.md`: unverändert seit 31.10. Die Direktive des Arbiters zu K-M1b-5 (π²/3, ANK-25 nur als Installationsprüfung) gilt weiter;
  - Nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** docs/02 M1b (Z. 20–45), ADR-035 und ADR-037 vollständig.
- **Diff, ohne Git:**
  - `find -newer orchestrator/state/M1b/code-review-r5-infra0.done` findet außerhalb von `orchestrator/logs/` nur `PROGRESS.md`, `REWORK-NOTES.md`, `STATUS.md`, Orchestrator-Zustand und `reports/mutation/unmutated.json`.
  - Über Produkt-, Test-, Daten- und Konfigurationspfade findet `find -newer orchestrator/state/M1b/gates-r5-infra0.done` nur ADR-037 (Reviewer, Runde 5).
  - Der kumulative Produkt-Diff seit `plan/M1b` ist also derselbe wie in Runde 5; REVIEW r5 hat ihn vollständig geprüft. Neu gelesen sind die zwei Builder-Dateien der Runde 6.
- **Visuelle Artefakte:** keine; M1b fordert keine, `orchestrator/state/M1b/shots/` ist leer.

## Gate-Fakten

| Gate | Runde 6 (`gates.json`, `env.sha` `ca34c5a`, 01.11.2026 23:01 bis 23:08) | Ursache |
| --- | --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4; gleich Runde 5) | – |
| lint | fail: `R CMD build` bricht beim Vignettenbau ab, „Validation input is missing: …/reference/quellen/data/aiag/anova_example.csv“ (`gate-lint.log` Z. 6–34) | E37 |
| tests | fail: `tests/testthat` `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5254 ]` (Z. 525). `tests/acceptance`: m1a-2 drei Abbrüche und m1a-3 ein Abbruch („local AIAG data sheet missing“), m1a-4 zehn Fehlschläge (Vignette), danach Abbruch des Ordners (Z. 567–686). e2e 49 und fuzz 25 grün (Z. 713, 734) | E37, E38 |
| trace | pass | – |
| territory | pass (builder/60-rework, Runde 6, Basis `72f6b7c`) | – |
| mutgate | fail: unmutierter Vorlauf 125,3 s, 392 Tests, davon 12 fehlgeschlagen und 4 abgebrochen, alle von AIAG-Datei oder Vignette abhängig; kein Mutant gelaufen (`gate-mutgate.log` Z. 3–21) | E37 |
| golden-adr | pass (keine Golden- oder Ankeränderung) | – |
| mutfull | pass („nicht fällig in M1b“) | – |
| **result** | **fail** | |

- **Status error:** keiner. Die roten Gates melden `fail` (rc 1), weil die Abnahme bei fehlendem geschützten Datenblatt absichtlich scheitert (AGENTS.md, Domänenregeln: „sie überspringen nicht“).
- **Überlebende Mutanten:** keine benennbar. `reports/mutation/` enthält nur `unmutated.json` mit denselben 16 roten Testblöcken wie in Runde 5 (3 in m1a-2, 1 in m1a-3, 1 in m1a-4, 5 in m1a-7, 6 in m1b-7-vignette).
- **Nicht gelaufen:** Im tests-Gate liefen nur zehn der 28 Abnahmedateien (bis m1a-4). Es fehlen 18 Dateien, m1a-5 bis m2-7; REVIEW r5 hatte 17 gezählt, richtig sind 18 (E38). Prüflauf 1 schließt die Lücke.
- **Laufzeit:** Rework 22:57 bis 23:01, Gates 23:01 bis 23:08.

## Eigene Prüfläufe

Alle am 01.11.2026 mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4 und testthat 3.3.2 auf dem Produktstand `ca34c5a`. Zu Beginn der Sitzung war nur `orchestrator/.lock/` unversioniert (Git-Status der Sitzung). Dazu kamen meine Handoff-Dateien und das Probeverzeichnis `orchestrator/handoff/M1b/.probe-r6/` mit einer Logdatei; es ist am Ende per `unlink()` gelöscht. Paketausgaben dienen nirgends als Referenz. Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Abnahme ohne Abbruchgrenze.** Aufruf wie in `lib/r-tests.R`: `REPO_ROOT` gesetzt, `NOT_CRAN=true`, `load_package = "source"`, dazu `options(testthat.progress.max_fails = Inf)`.

   ```text
   ✔ |        259 | m0-api-snapshot
   ✔ |         51 | m0-deps
   ✔ |          7 | m0-gates
   ✔ |         16 | m0-layout
   ✔ |         55 | m0-r-unchanged
   ✔ |          2 | m0-testthat-count [114.1s]
   ✔ |         91 | m1a-1-reml-anova [1.4s]
   ✖ | 3        0 | m1a-2-aiag
   ✖ | 1       50 | m1a-3-oracles [12.3s]
   ✖ | 10       96 | m1a-4-nist [1.8s]
   ✔ |         99 | m1a-5-metrics-verdict
   ✔ |        172 | m1a-6-invariance-edge [4.9s]
   ✖ | 38       12 | m1a-7-vignette
   ✔ |         34 | m1b-1-engine-ordinal [2.4s]
   ✔ |        2155 | m1b-2-recovery-scripts [132.6s]
   ✔ |        687 | m1b-3-two-level-script [15.2s]
   ✔ |   2     37 | m1b-4-two-levels [2.9s]
   ✔ |          9 | m1b-5-binary-rptr
   ✔ |        108 | m1b-6-edge-cases [6.7s]
   ✔ |        204 | m1b-7-vignette-full-results [19.7s]
   ✖ | 7       11 | m1b-7-vignette
   ✔ |        149 | m2-1-items [137.3s]
   ✔ |         34 | m2-2-memorisation [88.8s]
   ✔ |        837 | m2-3-prompts-parser [512.2s]
   ✔ |         89 | m2-4-backends [1.7s]
   ✔ |        106 | m2-5-plan [2.4s]
   ✔ |        383 | m2-6-evaluate [107.7s]
   ✔ |        375 | m2-7-robustness-pilot [96.8s]
   blocks: 206 | failed blocks: 12 | error blocks: 4 | skipped: 0 | failed expectations: 55 | expectations: 6185
   elapsed: 21.12101 mins
   ```

   - Rot sind 16 Testblöcke (12 fehlgeschlagen, 4 Abbrüche, 55 fehlgeschlagene Erwartungen). Es sind dieselben 16 wie im unmutierten mutgate-Vorlauf der Runde 6 und wie in REVIEW r5, Prüflauf 1.
   - Jeder rote Block folgt aus der fehlenden Datei. Die vier Abbrüche melden „local AIAG data sheet missing“. Die Vignettenblöcke in m1a-4, m1a-7 und m1b-7-vignette scheitern, weil das gemeinsame Knit mit „Validation input is missing: …/anova_example.csv“ endet (`test-m1a-4-nist.R:95`, `test-m1a-7-vignette.R:46`, `test-m1b-7-vignette.R:31`). Alle übrigen Fehlschläge sind Folgeprüfungen am fehlenden Abschnitt.
   - K-M1b-1 bis K-M1b-6 sind grün. Die Neuläufe in K-M1b-2 und K-M1b-3 liefern dieselben Einzelschätzer wie die committeten Kurzläufe (`format(x, digits = 15)`), auch als Präfix- und Teilmengenlauf (ACC-6; m1b-2 2155, m1b-3 687 Erwartungen).
   - Der K-M1b-7-Abschnitt wird im öffentlichen Kontext gebaut und gelesen (m1b-7-vignette-full-results, 204 Erwartungen).
   - Die zwei Warnungen in m1b-4 sind BL-93.
   - m2-1 bis m2-7 sind grün, ebenso m1a-5 und m1a-6.

2. **Freigaben gegen Quellzeilen.** Jede der 15 Freigaben in `MUT-EQUIV-APPROVED.json` wird mit der aktuellen Zeile verglichen: Feld `code` gegen die Quellzeile, ohne Rand-Leerraum, und Spalte innerhalb der Zeile.

   ```text
       file line col              mutator code_match
    R/fit.R  314  47         TRUE → FALSE       TRUE
    R/fit.R  315  64         FALSE → TRUE       TRUE
    R/fit.R  329  46    <n> + 1 → <n> + 1       TRUE
    R/fit.R  415  37                + → -       TRUE
    R/fit.R  440  45         TRUE → FALSE       TRUE
    R/fit.R  448  18    <n> + 1 → <n> + 1       TRUE
    R/fit.R  448  18    <n> - 1 → <n> - 1       TRUE
    R/fit.R  523  61    <n> + 1 → <n> + 1       TRUE
    R/fit.R  523  61 x[<i>] → x[<i> + 1L]       TRUE
    R/fit.R  608  33    <n> + 1 → <n> + 1       TRUE
    R/fit.R  608  33    <n> - 1 → <n> - 1       TRUE
    R/fit.R  709  52         TRUE → FALSE       TRUE
    R/fit.R  711  41         TRUE → FALSE       TRUE
    R/fit.R  717  86         TRUE → FALSE       TRUE
    R/grr.R   99  52               > → >=       TRUE
   all match: TRUE | lines R/fit.R: 855 | R/grr.R: 199
   ```

   - Die Anträge in `MUT-EQUIV.json` gegen die Freigaben und die Quellzeilen:

     ```text
     claims: 16 | fields: file,mutator,line,column,code,replacement,reason
     claim keys: 14 | approved keys: 15
     claim keys without approval:
     approvals without claim: R/grr.R > → >= 99
     claim code lines match: TRUE
     ```

   - Da `R/fit.R` seit `a8f8db7` unverändert ist (Prüflauf 3), gilt die Bindung aus REVIEW r5, Prüflauf 2 fort: Jeder der 14 Schlüssel in `R/fit.R` trifft im Mutantenplan genau die beantragten 16 Mutanten.
   - `R/grr.R:99` bleibt freigegeben; die Freigabe stammt aus M1a und ist seit M1b Runde 3 bestätigt.

3. **Unveränderter Produktstand.**
   - `find … -newer orchestrator/state/M1b/gates-r5-infra0.done -type f` über `R`, `tests`, `inst`, `man`, `vignettes`, `data`, `data-raw`, `docs`, `reference/anchors`, `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `IMPLEMENTATION-RULES.md`, `contracts`, `AGENTS.md`, `toolchain.json`, `orchestrator/config.env`, `orchestrator/lib` und `orchestrator/gates.d`:

     ```text
     == since gates r5 (22:22) ==
     docs/decisions/ADR-037-m1b-code-review-auslegungen-runde-5.md
     ```

   - Hashes der Mutationsdateien und Implementierungshash:

     ```text
     sha256 R/fit.R: acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180
     sha256 R/grr.R: 004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e
     sim_implementation(): 477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e | equals session files: TRUE
     ```

   - `sim_implementation()` ist mit `pkgload::load_all()` und den Helfern aus `inst/validation/sim/simulation_helpers.R` neu gerechnet. Der Wert steht so in allen drei `*_check_session.txt` (ADR-023 Nr. 1.5).
   - Das territory-Gate bestätigt für das Rework r6 einen sauberen Diff. Die Inventur des Builders (R6-P5) nennt dieselben zwei geänderten Dateien.

4. **Bestand der geschützten Betreiber-Dateien.**

   ```text
   files under reference/quellen and reference/privat:
   0
   dirs:
   37
   reference/privat:              2026-11-01 20:25:32.972741800 +0100 .
   reference/quellen/data/aiag:   2026-11-01 20:25:33.061383600 +0100 .
   ```

   Die 37 Verzeichnisse schließen die beiden Wurzeln ein; keines enthält eine Datei. Die Zeiten zeigen, dass seit dem Rollback niemand diese Verzeichnisse berührt hat.

## Stand der Einwände aus Runde 5

| ID | Stand | Beleg |
| --- | --- | --- |
| E37 | offen, [INFRA], Betreiber | Datenblatt und alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**` fehlen weiter (Prüflauf 4); Gate-Lauf r6 erneut rot aus derselben Ursache. Builder: richtig als OUT-OF-TERRITORY belegt (REWORK-NOTES r6, R6-P1 bis R6-P3) |
| E38 | offen, [INFRA], Betreiber | `gate-tests.log` r6 Z. 685; 18 Abnahmedateien nicht gelaufen. Prüflauf 1 schließt die Lücke |
| E39 | offen, nicht verlangt | kein `mutation.json`; die drei unbeantragten Überlebenden aus dem Teillauf des Builders (`R/fit.R:331:42`, `:337:55`, `:338:74`) bleiben ohne Freigabe; keine neuen Anträge |
| E33–E36 | erledigt (Runde 5) | Produkt unverändert (Prüflauf 3) |
| E32, E35 | zurückgestellt (ADR-035 Nr. 2 und 3) | BL-100, BL-101 |
| E20 | Builder-Teil erledigt | BL-91, Reviewer-Teil offen (M1c/M1d) |
| E21 | unverändert, spec-gemäß | Einzelschätzer der Kurzläufe reproduziert (Prüflauf 1, m1b-2 und m1b-3); BL-92 |
| E22 | Sandbox-Befunde unverändert | BL-86 |
| E23 | offen, Reviewer | BL-93 (Prüflauf 1) |

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:** Das Produkt ist unverändert. K-M1b-1 bis K-M1b-6 sind grün (Prüflauf 1). K-M1b-7 („`R CMD check` baut sie ohne ERROR und WARNING“; Prüfweg auch Gate lint) ist im Repo-Kontext nur wegen E37 rot. Im öffentlichen Kontext sind Abschnitt und Paketbau grün: m1b-7-vignette-full-results in Prüflauf 1 und `R CMD check` mit `Status: OK` in REVIEW r5, Prüflauf 6, auf demselben Produktstand.
- **API-Diff:** keiner. m0-api-snapshot ist im Gate grün (259 Erwartungen, `gate-tests.log` Z. 536); `NAMESPACE` und `DESCRIPTION` sind unverändert.
- **Tests:** Keine Bestands-, Abnahme-, QA- oder Fixture-Datei ist geändert, und es gibt keinen neuen Test. Entkernte Tests, eingefrorene Ausgaben oder harte Erwartungswerte kann diese Runde deshalb nicht einführen.
- **Konfiguration:** Nichts ist gelockert. `config.env` und `toolchain.json` tragen weiter 21:34 (Betreiber); Schwellen, `MUT_TEST_EXCLUDE` und Testordner sind wie in Runde 5 (`gate-mutgate.log` Z. 2).
- **Daten:** Es gibt keine Ersatzdaten für das fehlende Datenblatt (REWORK-NOTES r6, R6-P5); das ist richtig. Die neun `_check_`-Dateien sind seit Runde 5 unverändert, ihre Einzelschätzer reproduzieren (Prüflauf 1), und ihr Implementierungshash stimmt (Prüflauf 3).
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Builder-Belege:** R6-P2 (K-M1a-2: drei Fehler), R6-P3 (m1b-7-vignette: 7 Fehlschläge, 11 bestanden) und R6-P4 (K-M1b-1 und K-M1b-5: 43 bestanden) stimmen mit Gate und Prüflauf 1 überein. Die Inventur R6-P5 liegt unter `/tmp` und ist nicht nachprüfbar; das territory-Gate und Prüflauf 3 bestätigen ihr Ergebnis unabhängig.

## Einwände (Runde 6)

- [E37] (minor) [INFRA] Gates lint, tests und mutgate (`gates.json` Runde 6, `result` `fail`); AGENTS.md, Domänenregeln („Abnahmetests schlagen fehl, wenn eine lokale geschützte Datei (`reference/quellen/data/`) fehlt; sie überspringen nicht.“) — **Befund:** unverändert seit Runde 5. Das geschützte AIAG-Datenblatt fehlt, mit ihm alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**` (Prüflauf 4). Daraus folgen die 16 roten Abnahme-Testblöcke, der Abbruch des Vignettenbaus im lint-Gate und der rote unmutierte mutgate-Vorlauf. Ursache und Abhilfe liegen im Betreiber-Territorium; für den Builder ist der Befund nicht blockierend.
  — **Vorschlag:** Betreiber nach BL-103, vor dem Gate-Lauf der Runde 7 (E40):
  - die Dateien aus den Originalen unter `../quellen/` wiederherstellen; ANK-10 prüft den SHA-256 des Datenblatts;
  - den Restore so ändern, dass er ignorierte Pfade weder sichert noch löscht.
  - Builder: keine Ersatzdaten, kein Umgehen.
- [E38] (minor) [INFRA] Gate tests (`gate-tests.log` Runde 6 Z. 685, „Maximum number of failures exceeded; quitting.“) — **Befund:** unverändert. Nach m1a-4 bleiben 18 Abnahmedateien ungeprüft, darunter alle Kriterien von M1b. — **Vorschlag:** Betreiber: `options(testthat.progress.max_fails = Inf)` in `r-tests.R` (BL-104). Bis dahin prüft das Review die übrigen Dateien selbst (Prüflauf 1).
- [E39] (minor) Gate mutgate (fail ohne Bericht, E37); SCHEMA.md („Nur einzeln vom Reviewer approvte, nachweislich verhaltensgleiche Mutanten verlassen den Nenner.“); ADR-037 Nr. 3 — **Befund:** Der Score ist weiter offen. Ohne `mutation.json` gibt es keinen Survived- oder NoCoverage-Eintrag, also nach ADR-037 (Konsequenzen) nichts, was blocking zu benennen wäre. Die drei unbeantragten Überlebenden aus dem Teillauf des Builders bleiben ohne Freigabe (BL-102). — **Vorschlag:** nicht verlangt; entschieden wird über den nächsten Bericht.
- [E40] (minor) [INFRA] Rundenbudget (`orchestrate.sh:963–964`, `:1030–1036`, `:805–808`; `config.env` Z. 215–217) — **Befund:** Die roten Gates verbrauchen Runden, ohne dass ein Builder-Befund offen ist.
  - Eine fehlende geschützte Datei meldet `fail` (rc 1), nicht `error` (rc 2). Deshalb greift `GATE_ERROR_RETRIES` nicht, und jede Runde kostet einen Builder-Aufruf.
  - `max_rounds` ist 5 + 2 = 7, weil `arbiter-granted` seit der Planphase steht. Nach diesem Verdict folgt Runde 7, die letzte.
  - Ist deren Verdict nicht PASS bei grünen Gates, ruft `run_ms` den Arbiter. `arbiter()` kehrt wegen `arbiter-granted` sofort mit 1 zurück, und M1b wird geparkt („Codepfad festgefahren“).
  - Benachrichtigt wird erst beim Parken (NEEDS_HUMAN, PARKED); ein REWORK-Verdict löst keine Nachricht aus.
  - Nach dem Entparken liest der Lauf Gates und Verdict der Runde 7 aus den Markern `gates-r7-infra0.done` und `code-review-r7-infra0.done` und parkt erneut, solange diese stehen (`:966–1009`).
  - Ein Rebuild droht nicht: `LADDER_ENABLED` ist in `config.env` leer und wird bei `AUTONOMY_LEVEL=1` zu 0 (`orchestrate.sh:45`, `:1045`).
  - Ein ESCALATE hätte M1b schon jetzt geparkt. Es bleibt aber Spec-Widersprüchen vorbehalten (PROTOCOLS.md §3), und ein solcher liegt nicht vor.
  — **Vorschlag:** Betreiber (BL-105):
  - BL-103 vor dem Gate-Lauf der Runde 7 erledigen. Das Rework r7 beginnt direkt nach diesem Review und dauerte in Runde 6 vier Minuten.
  - Gelingt das nicht: nach dem Parken die Dateien wiederherstellen und die beiden r7-Marker entfernen, damit Gates und Review der Runde 7 neu laufen. Eine Produktänderung ist nicht nötig.
  - Harness: fehlende geschützte Eingaben vor den Gates prüfen und als `error` melden (PROTOCOLS.md §4: „Exit 2: `error` — Infrastruktur; kein Builder-Fehlschlag“). Die Abnahmetests selbst scheitern weiter und überspringen nicht.

## Hinweise für REWORK (Runde 7)

- **Umfang:** Es gibt keinen blocking-Befund, und keine Produktänderung ist verlangt. ADR-037 Nr. 2 gilt für Runde 7 unverändert. E37, E38 und E40 sind Betreiber-Sache.
- **Nicht tun:**
  - das Datenblatt oder andere Dateien unter `reference/` anlegen, ersetzen oder aus einer anderen Darstellung erzeugen;
  - Abnahmetests umgehen;
  - `R/fit.R` ändern: Die Freigaben sind an Zeile und Quelltext gebunden (BL-85). Eine Änderung an den gehashten Funktionen (`msa_fit()`, `msa_latent_information()` und weitere, `inst/validation/sim/simulation_helpers.R:214`) macht außerdem den Implementierungshash der neun `_check_`-Dateien ungültig (ADR-023 Nr. 1.5);
  - Arbeit an Befunden nach ADR-035 Nr. 2 beginnen (BL-100, BL-101).
- **Belege:** Fehlt die Datei weiterhin, genügt eine kurze OUT-OF-TERRITORY-Meldung mit dem Gate-Output wie in REWORK-NOTES r6 (R6-P1 bis R6-P3). Die Diagnosen der Runde 5 müssen nicht wiederholt werden.

## Backlog

- **Neu:** BL-105, [INFRA], Rundenverbrauch durch Infrastrukturursachen und Parken in Runde 7 (E40).
- **Stand-Vermerke:**
  - BL-103: unverändert, Gate-Lauf r6 erneut rot (E37);
  - BL-104: unverändert, 18 statt 17 nicht gelaufene Dateien (E38);
  - BL-85: Freigaben gelten fort, Quellzeilen geprüft (Prüflauf 2);
  - BL-102: kein Bericht, keine neuen Anträge (E39);
  - BL-93: unverändert (Prüflauf 1).
- Ein blocking-Befund steht nicht offen.
