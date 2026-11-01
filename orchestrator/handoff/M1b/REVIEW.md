# REVIEW — M1b, Runde 7 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 7 · Stand: 02.11.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `39bf5ff` (`gates.json`, `env.sha`). Seit dem Review der Runde 6 hat der Builder nur `PROGRESS.md` und `REWORK-NOTES.md` geändert. Produktcode, Tests, Daten und Konfiguration sind seit dem in Runde 5 geprüften Stand `a8f8db7` unverändert (Prüflauf 3).
- die Gate-Fakten der Runde 7: `orchestrator/state/M1b/gates.json`, alle acht `gate-*.log` und `reports/mutation/unmutated.json`. Ein `mutation.json` gibt es auch in dieser Runde nicht.
- `REWORK-NOTES.md` und `PROGRESS.md` der Runde 7, `MUT-EQUIV.json` (16 Anträge) und `MUT-EQUIV-APPROVED.json` (15 Freigaben), beide unverändert seit Runde 5.

## Ergebnis

**Verdict REWORK, `blocking` leer. Runde 7 ist die letzte Runde; nach diesem Verdict parkt der Orchestrator M1b (E40).**

- **Gates:** `gates.result` ist `fail`. Rot sind lint, tests und mutgate, die übrigen fünf sind grün.
  - Die Ursache ist zum dritten Mal dieselbe: Das geschützte Betreiber-Datenblatt `reference/quellen/data/aiag/anova_example.csv` fehlt (E37, [INFRA], BL-103). Unter `reference/quellen/**` und `reference/privat/**` liegt weiterhin keine Datei (Prüflauf 4).
  - Für den Builder ist das nicht blockierend (AGENTS.md, Handoff-Disziplin). PASS bleibt ausgeschlossen, solange `gates.result` nicht `pass` ist (SCHEMA.md). ADR-037 Nr. 2 gilt unverändert.
- **Rework der Runde 7:** richtig. Keine Produktänderung, keine Ersatzdaten; E37 bis E40 sind Punkt für Punkt beantwortet. R7-P1 und R7-P2 decken sich mit den Gate-Logs der Runde 7 und mit Prüflauf 1.
- **Produkt:** unverändert seit `a8f8db7`; SHA-256 beider Mutationsdateien und Implementierungshash der Sessiondateien stimmen (Prüflauf 3). K-M1b-1 bis K-M1b-6 und der Volllauf-Teil von K-M1b-7 sind auf dem Stand der Runde 7 grün (Prüflauf 1).
- **Neu: Der Weg aus der Sperre ist belegt.**
  - Das Datenblatt lässt sich aus dem Textspiegel des Betreibers unter `../quellen/text/` byte-gleich erzeugen. Der SHA-256 ist der von ANK-10, die Quadratsummen der Rekonstruktion treffen die ANOVA-Tabelle von ANK-10 (Prüflauf 5). Das Rezept steht im Abschnitt „An den Betreiber“.
  - Mit dieser Datei in einer temporären Kopie außerhalb des Repos sind alle 16 bisher roten Abnahmeblöcke grün: 600 Erwartungen in m1a-2, m1a-3, m1a-4, m1a-7 und m1b-7-vignette (Prüflauf 6).
  - `R CMD build` und `R CMD check --as-cran` im Repo-Kontext enden mit `Status: OK` (Prüflauf 7, Annäherung an das lint-Gate).
  - Nach der Wiederherstellung ist daher zu erwarten, dass die Gates wieder über das Produkt entscheiden. Offen bleibt der Mutationsscore (E39).
- **MUT-EQUIV:** keine neuen Anträge; alle 15 Freigaben treffen weiter Quellzeile und Spalte (Prüflauf 2). Ohne Bericht gibt es keinen Überlebenden zu benennen.
- **An den Betreiber (E40, BL-105):** Der Lauf parkt M1b mit „Codepfad festgefahren (Gates rc=1, Verdict=REWORK); Arbiter benötigt HUMAN.“ Zum Entparken: Datenblatt nach Rezept wiederherstellen, die Marker `parked`, `gates-r7-infra0.done` und `code-review-r7-infra0.done` per `git rm` entfernen, committen, neu starten. Einzelheiten stehen im gleichnamigen Abschnitt unten.
- **In dieser Phase umgesetzt:** Stand-Vermerke in BL-85, BL-93, BL-102, BL-103, BL-104 und BL-105. Kein neues ADR, denn ADR-037 Nr. 2 und 3 decken diese Runde. `MUT-EQUIV-APPROVED.json` bleibt unverändert.

## Gelesen

- **Rollen und Protokoll:**
  - `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`;
  - der Prompt `50-code-review` Runde 7 (`orchestrator/prompts/50-code-review.md`).
- **Orchestrator, nur lesend:**
  - `orchestrate.sh`: `verdict` (Z. 701–723), `park` (Z. 771–801), `arbiter` (Z. 803–841), `run_ms` (Z. 900–1069) und die Startschleife (Z. 1083–1093);
  - `lib/r-tests.R`, `lib/r-check.sh`, `gates.d/20-lint.sh` und aus `gates.d/86-mutgate.sh` die Schwellenrechnung (Z. 12–17, 86–115);
  - `config.env`, nur die Runden-, Gate- und Mutationswerte (wirksam Z. 213–217, 228–242, 267); `state/mut-baseline` (93.83);
  - `logs/orchestrate.log` bis 23:48.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 6, `REWORK-NOTES.md` (Runde 7) und der Abschnitt Runde 7 in `PROGRESS.md`;
  - `MUT-EQUIV.json` und `MUT-EQUIV-APPROVED.json`;
  - `QA.md`: kein neuer QA-Lauf seit dem Nachlauf vom 01.11. und kein offener QA-Befund; e2e und fuzz sind im Gate grün;
  - `ARBITER.md` und `verdict-arbiter.json`: Die Direktive zu K-M1b-5 gilt (π²/3, rptR auf der Liability-Skala, ANK-25 nur als Installationsprüfung). `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md` und `ESCALATION-M1b.md` tragen unverändert Zeiten vom 31.10. und sind in dieser Runde nicht erneut gelesen;
  - nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** docs/02, Abschnitt M1b (Z. 20–45); ADR-035 und ADR-037 vollständig; `reference/anchors/ANK-10.json` (Datenblatt, ANOVA-Tabelle, Zitate).
- **Diff, ohne Git:**
  - `find -newer orchestrator/state/M1b/code-review-r6-infra0.done` findet außerhalb von `orchestrator/logs/` nur `PROGRESS.md`, `REWORK-NOTES.md`, `STATUS.md`, Orchestrator-Zustand und `reports/mutation/unmutated.json`.
  - Über Produkt-, Test-, Daten- und Konfigurationspfade findet `find -newer orchestrator/state/M1b/gates-r6-infra0.done` nichts (Prüflauf 3).
  - Der kumulative Produkt-Diff seit `plan/M1b` ist also derselbe wie in den Runden 5 und 6; REVIEW r5 hat ihn vollständig geprüft. Neu gelesen sind die zwei Builder-Dateien der Runde 7.
- **Visuelle Artefakte:** keine; M1b fordert keine, und `orchestrator/state/M1b/shots/` ist leer.

## Gate-Fakten

| Gate | Runde 7 (`gates.json`, `env.sha` `39bf5ff`, 01.11.2026 23:41 bis 23:48) | Ursache |
| --- | --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4; gleich Runde 6) | – |
| lint | fail: `R CMD build` bricht beim Vignettenbau ab, „Validation input is missing: …/reference/quellen/data/aiag/anova_example.csv“ (`gate-lint.log` Z. 6–34) | E37 |
| tests | fail: `tests/testthat` `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5254 ]` (Z. 526). `tests/acceptance`: m1a-2 drei Abbrüche und m1a-3 ein Abbruch („local AIAG data sheet missing“), m1a-4 zehn Fehlschläge (Vignette), danach Abbruch des Ordners (Z. 569–686). e2e 49 und fuzz 25 grün (Z. 714, 735) | E37, E38 |
| trace | pass | – |
| territory | pass (builder/60-rework, Runde 7, Basis `64b1df9`) | – |
| mutgate | fail: unmutierter Vorlauf 125,6 s, 392 Tests, davon 12 fehlgeschlagen und 4 abgebrochen, alle von AIAG-Datei oder Vignette abhängig; kein Mutant gelaufen (`gate-mutgate.log` Z. 3–21) | E37 |
| golden-adr | pass (keine Golden- oder Ankeränderung) | – |
| mutfull | pass („nicht fällig in M1b“) | – |
| **result** | **fail** | |

- **Status error:** keiner. Die roten Gates melden `fail` (rc 1), weil die Abnahme bei fehlendem geschützten Datenblatt absichtlich scheitert (AGENTS.md, Domänenregeln: „sie überspringen nicht“).
- **Überlebende Mutanten:** keine benennbar. `reports/mutation/` enthält nur `unmutated.json` mit denselben 16 roten Testblöcken wie in den Runden 5 und 6.
- **Nicht gelaufen:** Im tests-Gate liefen wieder nur zehn der 28 Abnahmedateien, bis m1a-4 (E38). Prüflauf 1 schließt die Lücke für M1a und M1b.
- **Laufzeit:** Rework 23:37 bis 23:41, Gates 23:41 bis 23:48.

## Eigene Prüfläufe

Alle am 01. und 02.11.2026 mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4 und testthat 3.3.2 auf dem Produktstand `39bf5ff`, wie das Gate mit `REPO_ROOT`, `NOT_CRAN=true` und `load_package = "source"`.
- Zu Beginn der Sitzung war nur `orchestrator/.lock/` unversioniert (Git-Status der Sitzung). Hinzu kamen meine Handoff-Dateien und das Probeverzeichnis `orchestrator/handoff/M1b/.probe-r7/` mit vier Skripten und drei Logs. Es ist am Ende per `unlink()` gelöscht, ebenso das leere `tests/acceptance/_snaps/` aus dem Rework.
- Die Prüfläufe 5 bis 7 lesen den Textspiegel und die NIST-Originale unter `../quellen/` nur. Die rekonstruierte Datei entsteht ausschließlich im Arbeitsspeicher oder in einer Kopie in R's `tempdir()`, die am Ende entfernt ist. Nichts davon liegt im Repo, und kein Datenwert des Handbuchs erscheint in einer Ausgabe oder in diesem Handoff.
- Paketausgaben dienen nirgends als Referenz. Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Abnahme M1a und M1b ohne Abbruchgrenze, im Repo.** Filter `^m1[ab]-`, dazu `options(testthat.progress.max_fails = Inf)`; 01.11., 23:52 bis 23:56.

   ```text
   ✔ |         91 | m1a-1-reml-anova [1.3s]
   ✖ | 3        0 | m1a-2-aiag
   ✖ | 1       50 | m1a-3-oracles [12.6s]
   ✖ | 10       96 | m1a-4-nist [1.9s]
   ✔ |         99 | m1a-5-metrics-verdict
   ✔ |        172 | m1a-6-invariance-edge [4.6s]
   ✖ | 38       12 | m1a-7-vignette
   ✔ |         34 | m1b-1-engine-ordinal [2.6s]
   ✔ |        2155 | m1b-2-recovery-scripts [131.2s]
   ✔ |        687 | m1b-3-two-level-script [14.3s]
   ✔ |   2     37 | m1b-4-two-levels [3.1s]
   ✔ |          9 | m1b-5-binary-rptr
   ✔ |        108 | m1b-6-edge-cases [6.7s]
   ✔ |        204 | m1b-7-vignette-full-results [19.8s]
   ✖ | 7       11 | m1b-7-vignette
   [ FAIL 59 | WARN 2 | SKIP 0 | PASS 3765 ]
   blocks: 128 | failed blocks: 12 | error blocks: 4 | skipped: 0 | failed expectations: 55 | expectations: 3822 | warnings: 2
   elapsed: 3.37 mins
   ```

   - Rot sind 16 Testblöcke: 12 fehlgeschlagen, 4 Abbrüche. Die Liste der roten Blöcke ist Titel für Titel dieselbe wie im unmutierten mutgate-Vorlauf der Runde 7 (`gate-mutgate.log` Z. 4–19).
   - Jeder rote Block folgt aus der fehlenden Datei; Prüflauf 6 zeigt dieselben 16 Blöcke mit Datei grün.
   - K-M1b-1 bis K-M1b-6 sind grün. Die Neuläufe in K-M1b-2 und K-M1b-3 liefern dieselben Einzelschätzer wie die committeten Kurzläufe (2155 und 687 Erwartungen; ACC-6).
   - Der K-M1b-7-Abschnitt wird im öffentlichen Kontext gebaut und gelesen (m1b-7-vignette-full-results, 204 Erwartungen). Die zwei Warnungen in m1b-4 sind BL-93.
   - Nicht erneut gelaufen sind m0 und m2. m0 ist im Gate grün; m2-1 bis m2-7 waren in REVIEW r6, Prüflauf 1, auf demselben Produktstand grün.

2. **Freigaben gegen Quellzeilen.** Jede der 15 Freigaben in `MUT-EQUIV-APPROVED.json` wird mit der aktuellen Zeile verglichen: Feld `code` gegen die Quellzeile ohne Rand-Leerraum, dazu die Spalte innerhalb der Zeile.

   ```text
       file line col              mutator code_match col_in_line
    R/fit.R  314  47         TRUE → FALSE       TRUE        TRUE
    R/fit.R  315  64         FALSE → TRUE       TRUE        TRUE
    R/fit.R  329  46    <n> + 1 → <n> + 1       TRUE        TRUE
    R/fit.R  415  37                + → -       TRUE        TRUE
    R/fit.R  440  45         TRUE → FALSE       TRUE        TRUE
    R/fit.R  448  18    <n> + 1 → <n> + 1       TRUE        TRUE
    R/fit.R  448  18    <n> - 1 → <n> - 1       TRUE        TRUE
    R/fit.R  523  61    <n> + 1 → <n> + 1       TRUE        TRUE
    R/fit.R  523  61 x[<i>] → x[<i> + 1L]       TRUE        TRUE
    R/fit.R  608  33    <n> + 1 → <n> + 1       TRUE        TRUE
    R/fit.R  608  33    <n> - 1 → <n> - 1       TRUE        TRUE
    R/fit.R  709  52         TRUE → FALSE       TRUE        TRUE
    R/fit.R  711  41         TRUE → FALSE       TRUE        TRUE
    R/fit.R  717  86         TRUE → FALSE       TRUE        TRUE
    R/grr.R   99  52               > → >=       TRUE        TRUE
   all match: TRUE | lines R/fit.R: 855 | R/grr.R: 199
   claims: 16 | claim keys: 14 | approved keys: 15
   claim keys without approval:
   approvals without claim: R/grr.R > → >= 99
   claim code lines match: TRUE
   ```

   - `R/fit.R` ist seit `a8f8db7` unverändert (Prüflauf 3). Deshalb gilt die Bindung aus REVIEW r5, Prüflauf 2, fort: Jeder der 14 Schlüssel in `R/fit.R` trifft im Mutantenplan genau die beantragten 16 Mutanten.
   - `R/grr.R:99` bleibt freigegeben; die Freigabe stammt aus M1a und ist seit M1b Runde 3 bestätigt.

3. **Unveränderter Produktstand.**
   - `find … -newer orchestrator/state/M1b/gates-r6-infra0.done -type f` über `R`, `tests`, `inst`, `man`, `vignettes`, `data`, `data-raw`, `docs`, `reference/anchors`, `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `IMPLEMENTATION-RULES.md`, `contracts`, `AGENTS.md`, `toolchain.json`, `orchestrator/config.env`, `orchestrator/lib`, `orchestrator/gates.d`, `orchestrator/orchestrate.sh` und `.Rbuildignore` findet keine Datei. Über die Produktpfade gilt das auch seit `gates-r5-infra0.done`.
   - Hashes der Mutationsdateien und Implementierungshash:

     ```text
     acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180  R/fit.R
     004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e  R/grr.R
     sim_implementation(): 477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e | equals session files: TRUE | files: 3
     ```

   - Beide Hashes sind die von REVIEW r6, Prüflauf 3. `sim_implementation()` ist mit `pkgload::load_all()` und den Helfern aus `inst/validation/sim/simulation_helpers.R` neu gerechnet; der Wert steht so in allen drei `*_check_session.txt` (ADR-023 Nr. 1.5).
   - Das territory-Gate bestätigt für das Rework r7 einen sauberen Diff. Die Inventur des Builders (R7-P3) liegt unter `/tmp` und ist nicht nachprüfbar, nennt aber dieselben zwei geänderten Dateien.

4. **Bestand der geschützten Dateien und Quellen für ihre Wiederherstellung.**

   ```text
   files under reference/quellen and reference/privat: 0
   dirs: 37
   reference/privat:              2026-11-01 20:25:32.972741800 +0100
   reference/quellen/data/aiag:   2026-11-01 20:25:33.061383600 +0100
   ```

   - Die Zeiten zeigen, dass seit dem Rollback in Rework r5, Versuch 1, niemand diese Verzeichnisse berührt hat.
   - Eine Kopie des Datenblatts gibt es nicht: Weder unter `../quellen/` (neun CSV-Dateien unter 1 MB) noch in den übrigen Nachbarverzeichnissen des Repos (CSV-Dateien unter 20 KB, ohne `.git`) trägt eine Datei den SHA-256 von ANK-10.
   - **Textspiegel:** Die 33 Verzeichnisse von `reference/quellen/text/**` bestehen alle unter `../quellen/text/`; nur `data` und `data/aiag` gibt es dort nicht. Der dortige AIAG-Textspiegel trägt die Zitate von ANK-10 an den Zeilen, die der Anker nennt:

     ```text
     6352 : Appraiser 2 3.1673 1.58363 34.44*
     6356 : Total 89 94.6471
     6372 :  2 = 0.039973 EV = 0.199933 18.4 3.4
     6389 : Total Variation TV =1.085 100.0
     6482 : Number of distinct data categories (ndc) = 4
     ```

   - **`reference/privat/`, Kandidaten außerhalb des Repos, nicht als identisch belegt:**
     - `../unterlagen/07_Formelsammlung_llmsa.md` enthält alle vier Zitate, die ANK-06 und ANK-16 aus der Formelsammlung führen.
     - `../projektierung_llmsa/docs/90-katalog-offen.md`.
     - `../unterlagen/projekt_dateien/llmsa_Quellenkatalog.md` ist älter als der gelöschte Katalog: Der Schlüssel `Bates2010`, den ANK-13 dort verortet, fehlt; `AIAG2010`, `Christensen-clmm2`, `Nakagawa2010` und `Stoffel` sind vorhanden.

5. **Rekonstruktion des Datenblatts.** Gelesen werden die drei Versuchszeilen je Prüfer des Datenblatts in Fig. III-B 15 (PDF 127) im Textspiegel, Z. 5870–5872 (A), 5875–5877 (B) und 5880–5882 (C), je die zehn Teilewerte ohne den Zeilenmittelwert.
   - Geprüft werden 192 Kodierungen als CSV mit den Spalten von ANK-10: sechs Sortierungen, Prüfer als Buchstaben oder Zahlen, Werte wie gedruckt oder über `as.numeric`, mit oder ohne Anführungszeichen, LF oder CRLF, mit oder ohne Schlusszeilenumbruch.
   - Zur Gegenprobe des Einlesens dient `stats::aov(value ~ factor(appraiser) * factor(part))` gegen die gedruckte ANOVA-Tabelle von ANK-10.

   ```text
   mirror: /mnt/c/Users/Danie/dev/Llmsa/quellen/text/literatur/A_statistikkern/AIAG_2010_MSA_Reference_Manual_4th_Edition.pdf.layout.txt | sha256: d05bd16c07b3bc3c3b916ce740481925214c21b66948d977b518f6fe1f394fac
   values: 90 | parts: 10 | appraisers: 3 | trials: 3
   SS minus ANK-10 (printed to 4 decimals): appraiser -0.00004 | parts 0.00003 | interaction -0.00002 | equipment 0.00003 | total 0.00001
   parse matches ANK-10 within half a unit of the 4th decimal: TRUE
   candidates hashed: 192 | ANK-10 sha256 hits: 1
   order appraiser,trial,part | appraiser letters | values printed | no quotes | eol LF | final newline TRUE
   ```

   - Genau eine Kodierung trifft den SHA-256 `3161a373…acbff16` von ANK-10: Kopfzeile `part,appraiser,trial,value`, Zeilen nach Prüfer, Versuch und Teil, Prüfer `A`/`B`/`C`, Werte wie gedruckt, ohne Anführungszeichen, LF und Schlusszeilenumbruch.
   - Damit ist die Rekonstruktion bytegleich mit dem gelöschten Datenblatt. Sie ist keine Ersatzdatei: Der Anker entscheidet über den Hash, und die Quadratsummen sind ein zweiter, unabhängiger Beleg.

6. **AIAG-abhängige Abnahme mit rekonstruiertem Datenblatt.** Temporäre Kopie unter R's `tempdir()` mit `DESCRIPTION`, `NAMESPACE`, `R`, `inst`, `data`, `man`, `vignettes`, `docs`, `reference/anchors` und `tests/acceptance`. Dazu die Datei aus Prüflauf 5 unter `reference/quellen/data/aiag/` und die NIST-Originale als Nachbarverzeichnis `quellen/daten/`; `REPO_ROOT` ist die Kopie. Filter: m1a-2, m1a-3, m1a-4, m1a-7 und m1b-7-vignette; 01.11., 23:57 bis 23:58.

   ```text
   rebuilt sheet sha256 equals ANK-10: TRUE
   sheet in copy matches ANK-10: TRUE
   NIST files copied: 12
   ✔ |         40 | m1a-2-aiag
   ✔ |         66 | m1a-3-oracles [12.7s]
   ✔ |        106 | m1a-4-nist [14.7s]
   ✔ |        148 | m1a-7-vignette
   ✔ |        240 | m1b-7-vignette [4.8s]
   [ FAIL 0 | WARN 0 | SKIP 0 | PASS 600 ]
   blocks: 34 | failed blocks: 0 | error blocks: 0 | skipped: 0 | failed expectations: 0 | expectations: 600 | warnings: 0
   vignettes/ in copy holds only sources: llmsa.Rmd, validation.Rmd
   elapsed: 0.56 mins
   copy removed: TRUE
   ```

   - Alle 16 Blöcke, die in Prüflauf 1 und im Gate rot sind, sind mit der Datei grün: K-M1a-2, K-M1a-3, der Vignettenteil von K-M1a-4, K-M1a-7 und der Repo-Teil von K-M1b-7.
   - Die Ergebnisse von `msa_fit()` und `msa_grr()` auf dem AIAG-Beispiel sind damit erstmals seit der Änderung von `R/fit.R` in Runde 5 gegen ANK-10 und die VCA-Orakel geprüft.

7. **Paketbau und Check im Repo-Kontext mit rekonstruiertem Datenblatt (Annäherung an das lint-Gate).** Ablauf wie `orchestrator/lib/r-check.sh`: `R CMD build --no-manual`, dann `R CMD check --as-cran --no-manual` mit `_R_CHECK_CRAN_INCOMING_REMOTE_=false`, `REPO_ROOT` auf eine Kopie wie in Prüflauf 6, ergänzt um `tests/`; 01.11., 23:59, bis 02.11., 00:02.
   - Abweichung vom Gate: Die Paketkopie stammt aus dem Arbeitsbaum ohne `.git`, `orchestrator`, `reports`, `reference` und `projektierung`, nicht aus `git ls-files`. Die ausgelassenen Pfade stehen alle in `.Rbuildignore`.

   ```text
   sheet in copy matches ANK-10: TRUE
   R CMD build rc: 0
   * installing the package (it is needed to build vignettes)
   * creating vignettes ... OK
   * building ‘llmsa_0.1.0.tar.gz’
   tarball: llmsa_0.1.0.tar.gz | build minutes: 0.55
   R CMD check rc: 0 | check minutes: 2.57
   * checking tests ...
     Running ‘testthat.R’ [78s/77s]
   * checking package vignettes ... OK
   * checking re-building of vignette outputs ... [28s/28s] OK
   Status: OK
   testthat.Rout : [ FAIL 0 | WARN 0 | SKIP 7 | PASS 5180 ] [ FAIL 0 | WARN 0 | SKIP 7 | PASS 5180 ]
   copy removed: TRUE
   ```

   - Die Vignette baut im Repo-Kontext, und der Check endet ohne ERROR, WARNING und NOTE. Das ist der Prüfweg „Gate lint“ von K-M1b-7, hier mit Datei.
   - Das doppelte Testergebnis sind zwei Fundstellen derselben Zeile in `testthat.Rout`. Die sieben Skips habe ich nicht einzeln geprüft; für K-M1b-7 zählen ERROR und WARNING, und beide fehlen.
   - Entscheiden wird das lint-Gate selbst.

## Stand der Einwände aus Runde 6

| ID | Stand | Beleg |
| --- | --- | --- |
| E37 | offen, [INFRA], Betreiber; Wiederherstellungsweg jetzt belegt | Datenblatt und alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**` fehlen weiter (Prüflauf 4). Gate-Lauf r7 erneut rot aus derselben Ursache. Rekonstruktion bytegleich (Prüflauf 5), mit ihr Abnahme und Paketcheck grün (Prüfläufe 6 und 7). Builder: richtig als OUT-OF-TERRITORY belegt (REWORK-NOTES r7, R7-P1 und R7-P2) |
| E38 | offen, [INFRA], Betreiber | `gate-tests.log` r7 Z. 686; 18 Abnahmedateien nicht gelaufen. Prüflauf 1 schließt die Lücke für M1a und M1b |
| E39 | offen, nicht verlangt | kein `mutation.json`; die drei unbeantragten Überlebenden aus dem Teillauf des Builders (`R/fit.R:331:42`, `:337:55`, `:338:74`) bleiben ohne Freigabe; keine neuen Anträge |
| E40 | eingetreten | Runde 7 = `max_rounds`; Parken nach diesem Verdict. Entparken siehe „An den Betreiber“ |
| E33–E36 | erledigt (Runde 5) | Produkt unverändert (Prüflauf 3) |
| E32, E35 | zurückgestellt (ADR-035 Nr. 2 und 3) | BL-100, BL-101 |
| E20 | Builder-Teil erledigt | BL-91, Reviewer-Teil offen (M1c/M1d) |
| E21 | unverändert, spec-gemäß | Einzelschätzer der Kurzläufe reproduziert (Prüflauf 1, m1b-2 und m1b-3); BL-92 |
| E22 | Sandbox-Befunde unverändert | BL-86 |
| E23 | offen, Reviewer | BL-93 (Prüflauf 1) |

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:** Das Produkt ist unverändert. K-M1b-1 bis K-M1b-6 sind grün (Prüflauf 1). K-M1b-7 („`R CMD check` baut sie ohne ERROR und WARNING“; Prüfweg auch Gate lint) ist im Repo-Kontext nur wegen E37 rot. Mit der rekonstruierten Datei sind Abschnitt und Paketcheck auch im Repo-Kontext grün (Prüfläufe 6 und 7).
- **API-Diff:** keiner. m0-api-snapshot ist im Gate grün (259 Erwartungen, `gate-tests.log` Z. 537); `NAMESPACE` und `DESCRIPTION` sind unverändert.
- **Tests:** Keine Bestands-, Abnahme-, QA- oder Fixture-Datei ist geändert, und es gibt keinen neuen Test. Entkernte Tests, eingefrorene Ausgaben oder harte Erwartungswerte kann diese Runde deshalb nicht einführen.
- **Konfiguration:** Nichts ist gelockert. `config.env` und `toolchain.json` tragen weiter 21:34 (Betreiber); Schwellen, `MUT_TEST_EXCLUDE` und Testordner sind wie in Runde 6 (`gate-mutgate.log` Z. 2).
- **Daten:** Der Builder hat keine Ersatzdaten für das fehlende Datenblatt angelegt (REWORK-NOTES r7); das ist richtig. Die neun `_check_`-Dateien sind seit Runde 5 unverändert, ihre Einzelschätzer reproduzieren (Prüflauf 1), und ihr Implementierungshash stimmt (Prüflauf 3). Die Rekonstruktion aus Prüflauf 5 ist nicht erfunden, sondern über den SHA-256 von ANK-10 als das Original belegt. Sie liegt nicht im Repo; wiederherstellen kann sie nur der Betreiber (`reference/quellen/**` ist Betreiber-Territorium).
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Builder-Belege:** R7-P1 (K-M1a-2: drei Fehler) und R7-P2 (m1b-7-vignette: 7 Fehlschläge, 11 bestanden) stimmen mit Gate und Prüflauf 1 überein. Der Abschnitt Runde 7 in `PROGRESS.md` behauptet keine Abnahme und keine neuen Gate-Fakten.

## Einwände (Runde 7)

- [E37] (minor) [INFRA] Gates lint, tests und mutgate (`gates.json` Runde 7, `result` `fail`); AGENTS.md, Domänenregeln („Abnahmetests schlagen fehl, wenn eine lokale geschützte Datei (`reference/quellen/data/`) fehlt; sie überspringen nicht.“) — **Befund:** unverändert seit Runde 5. Das geschützte AIAG-Datenblatt fehlt, mit ihm alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**` (Prüflauf 4). Daraus folgen die 16 roten Abnahme-Testblöcke, der Abbruch des Vignettenbaus im lint-Gate und der rote unmutierte mutgate-Vorlauf.
  - Neu: Das Datenblatt ist aus dem Textspiegel unter `../quellen/text/` bytegleich wiederherstellbar (Prüflauf 5). Mit ihm sind die 16 Blöcke und der Paketcheck auf dem aktuellen Produkt grün (Prüfläufe 6 und 7).
  - Ursache und Abhilfe liegen im Betreiber-Territorium; für den Builder ist der Befund nicht blockierend.
  — **Vorschlag:** Betreiber, vor dem Neustart:
  - das Datenblatt nach dem Rezept im Abschnitt „An den Betreiber“ wiederherstellen;
  - den Textspiegel und `reference/privat/` aus den genannten Quellen wiederherstellen (für die Gates nicht nötig, für die Ankerarbeit ab M1c schon);
  - den Restore so ändern, dass er ignorierte Pfade weder sichert noch löscht (BL-103 Nr. 3).
  - Builder: keine Ersatzdaten, kein Umgehen.
- [E38] (minor) [INFRA] Gate tests (`gate-tests.log` Runde 7 Z. 686, „Maximum number of failures exceeded; quitting.“) — **Befund:** unverändert. Nach m1a-4 bleiben 18 Abnahmedateien ungeprüft, darunter alle Kriterien von M1b. — **Vorschlag:** Betreiber: `options(testthat.progress.max_fails = Inf)` in `r-tests.R` (BL-104). Mit wiederhergestellter Datei greift die Grenze voraussichtlich nicht, weil dann kein Abnahmeblock mehr rot ist (Prüfläufe 1 und 6).
- [E39] (minor) Gate mutgate (fail ohne Bericht, E37); SCHEMA.md („Nur einzeln vom Reviewer approvte, nachweislich verhaltensgleiche Mutanten verlassen den Nenner.“); ADR-037 Nr. 3 — **Befund:** Der Score ist weiter offen. Ohne `mutation.json` gibt es keinen Survived- oder NoCoverage-Eintrag, also nach ADR-037 (Konsequenzen) nichts, was blocking zu benennen wäre.
  - Die drei unbeantragten Überlebenden aus dem Teillauf des Builders bleiben ohne Freigabe (BL-102).
  - Nach dem Entparken läuft mutgate zum ersten Mal seit Runde 4 mit Mutanten, über 1456 Mutanten in `R/fit.R` und `R/grr.R` (`gate-mutgate.log` Z. 2). Verlangt sind 90,83: Baseline 93,83 aus `state/mut-baseline` minus `MUT_RATCHET_TOL=3` (`config.env` Z. 232), mindestens der Floor 80 (`86-mutgate.sh:86`); so auch in Runde 4.
  — **Vorschlag:** nicht verlangt. Entschieden wird über den nächsten Bericht; die 15 Freigaben sind an den aktuellen Stand gebunden (Prüflauf 2).
- [E40] (minor) [INFRA] Rundenbudget (`orchestrate.sh:963–964`, `:1030–1036`, `:805–808`; `config.env` Z. 215–217) — **Befund:** Der in Runde 6 angekündigte Fall tritt ein.
  - Runde 7 ist `max_rounds` (5 + 2, weil `arbiter-granted` seit der Planphase steht). Weil das Verdict nicht PASS bei grünen Gates ist, ruft `run_ms` den Arbiter; `arbiter()` kehrt sofort mit 1 zurück.
  - Der Lauf parkt M1b mit „Codepfad festgefahren (Gates rc=1, Verdict=REWORK); Arbiter benötigt HUMAN.“ und benachrichtigt (NEEDS_HUMAN, PARKED; `:797–798`).
  - `park()` überschreibt dabei `orchestrator/ESCALATION-M1b.md` und `ESCALATION.md` (`:777–786`). Der Betreiber-Entscheid vom 31.10. steht weiter in ADR-024 und in der Git-Historie.
  - Ein ESCALATE hätte dieselbe Folge, bleibt aber Spec-Widersprüchen vorbehalten (PROTOCOLS.md §3), und ein solcher liegt nicht vor.
  — **Vorschlag:** Betreiber: entparken wie im folgenden Abschnitt. Harness: fehlende geschützte Eingaben vor den Gates prüfen und als `error` melden (PROTOCOLS.md §4: „Exit 2: `error` — Infrastruktur; kein Builder-Fehlschlag“). Die Abnahmetests selbst scheitern weiter und überspringen nicht (BL-105).

## An den Betreiber: Entparken von M1b

1. **Datenblatt wiederherstellen.** Aus der Repo-Wurzel:

   ```sh
   Rscript --vanilla -e '
   a <- jsonlite::fromJSON("reference/anchors/ANK-10.json")$value$data_file
   x <- readLines("../quellen/text/literatur/A_statistikkern/AIAG_2010_MSA_Reference_Manual_4th_Edition.pdf.layout.txt", warn = FALSE)
   rows <- list(A = 5870:5872, B = 5875:5877, C = 5880:5882)
   body <- character()
   for (p in names(rows)) for (t in 1:3) {
     v <- regmatches(x[rows[[p]][t]], gregexpr("-?[0-9]*\\.[0-9]+", x[rows[[p]][t]]))[[1]]
     stopifnot(length(v) == 11L)
     body <- c(body, paste(1:10, p, t, v[1:10], sep = ","))
   }
   csv <- paste0(paste(c("part,appraiser,trial,value", body), collapse = "\n"), "\n")
   stopifnot(identical(digest::digest(charToRaw(csv), algo = "sha256", serialize = FALSE), a$sha256))
   dir.create(dirname(a$path), recursive = TRUE, showWarnings = FALSE)
   writeBin(charToRaw(csv), a$path)
   cat(tools::sha256sum(a$path), "\n")'
   ```

   - Das Skript schreibt die Datei nur, wenn ihr SHA-256 der von ANK-10 ist. Die Ausgabe ist dann `3161a373027b7e61d4818659d3897f8d516ba2776ae145ab5544d26e4acbff16`.
   - Die Zeilennummern gelten für den Textspiegel mit SHA-256 `d05bd16c…1f394fac` (Prüflauf 5).
   - `QUELLE.txt` im selben Ordner ist ein Herkunftsvermerk des Betreibers. Sein Inhalt ist mir nicht bekannt, und kein Test liest ihn.
2. **Übrige Dateien (für die Gates nicht nötig):**
   - Textspiegel `../quellen/text/**` nach `reference/quellen/text/**` (Prüflauf 4);
   - `reference/privat/` aus eigenen Sicherungen. Die Kandidaten aus Prüflauf 4 sind nicht als identisch belegt, und `QUELLENKATALOG.md` braucht eine neuere Fassung als `../unterlagen/projekt_dateien/llmsa_Quellenkatalog.md`.
   - Weiter offen ist BL-103 Nr. 2 (`orchestrator/secrets.env`, `orchestrator/mcp/*.log`, `connector.url`). Diese Pfade habe ich nicht geprüft.
3. **Marker entfernen**, alle versioniert, also `git rm`, dann committen:
   - `orchestrator/state/M1b/parked` (Startschleife, `orchestrate.sh:1089–1093`);
   - `orchestrator/state/M1b/gates-r7-infra0.done`, sonst übernimmt der Lauf die roten Gates der Runde 7 (`:968–975`);
   - `orchestrator/state/M1b/code-review-r7-infra0.done`, sonst übernimmt er dieses Verdict und parkt sofort wieder (`:1004–1036`);
   - `orchestrator/state/M1b/reason` ist nur Text und für den Neustart nicht nötig.
4. **Neustart und Ablauf:**
   - Die Gates der Runde 7 laufen neu, mutgate erstmals seit Runde 4 mit allen Mutanten. Die Mutationsläufe der Runden 2 bis 4 dauerten je etwa 7,5 Stunden (ADR-035, Kontext).
   - QA ist nicht fällig: `5b-qa.done` steht, und es gibt kein `qa-requested` (`:980–981`).
   - Danach folgt das Review der Runde 7. PASS bei grünen Gates und leerem `blocking` schließt M1b ab (`:1026–1028`). Jedes andere Ergebnis parkt erneut, weil Runde 7 `max_rounds` bleibt.
5. **Optional, Betreiber-Entscheidung:** Soll nach dem neuen Gate-Lauf noch eine Builder-Runde möglich sein, etwa für Überlebende bei rotem mutgate (E39), muss `MAX_ROUNDS_REWORK` oder `ARBITER_EXTRA_ROUNDS` in `config.env` steigen.

## Hinweise für eine weitere Builder-Runde

Nur falls der Betreiber das Rundenbudget erhöht:

- **Umfang:** Aus diesem Review folgt kein blocking-Befund und keine Produktänderung. ADR-037 Nr. 2 gilt weiter. E37, E38 und E40 sind Betreiber-Sache.
- **Nicht tun:**
  - das Datenblatt oder andere Dateien unter `reference/` anlegen, ersetzen oder aus einer anderen Darstellung erzeugen. Das Rezept oben ist Betreiber-Arbeit in Betreiber-Territorium;
  - Abnahmetests umgehen;
  - `R/fit.R` ohne blocking-Auftrag ändern: Die Freigaben sind an Zeile und Quelltext gebunden (BL-85). Eine Änderung an den gehashten Funktionen macht außerdem den Implementierungshash der neun `_check_`-Dateien ungültig (ADR-023 Nr. 1.5);
  - Arbeit an Befunden nach ADR-035 Nr. 2 beginnen (BL-100, BL-101).
- **Belege:** Fehlt die Datei weiterhin, genügt eine kurze OUT-OF-TERRITORY-Meldung mit dem Gate-Output wie in REWORK-NOTES r7.

## Backlog

- **Stand-Vermerke:**
  - BL-103: Gate-Lauf r7 erneut rot; Wiederherstellungsweg belegt (Prüfläufe 4 bis 7);
  - BL-104: unverändert (`gate-tests.log` r7 Z. 686);
  - BL-105: eingetreten, Parken nach Runde 7; Entparken nach diesem Review;
  - BL-85: Freigaben gelten fort, Quellzeilen geprüft (Prüflauf 2);
  - BL-102: kein Bericht, keine neuen Anträge (E39);
  - BL-93: unverändert (Prüflauf 1).
- Neu ist kein Eintrag, und ein blocking-Befund steht nicht offen.
