# REVIEW — M1b, Runde 5 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 5 · Stand: 01.11.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `a8f8db7` (`gates.json`, `env.sha`), mit Schwerpunkt auf dem Rework der Runde 5 gegenüber dem Review der Runde 4;
- die Gate-Fakten `orchestrator/state/M1b/gates.json` der Runde 5 mit allen acht `gate-*.log` und `reports/mutation/unmutated.json`; ein `mutation.json` gibt es in dieser Runde nicht;
- `REWORK-NOTES.md` der Runde 5, `MUT-EQUIV.json` mit 16 Anträgen, ADR-035 (Betreiber) und ADR-036 (Builder).

## Ergebnis

**Verdict REWORK, `blocking` leer.**

- **Gates:** `gates.result` ist `fail`; lint, tests und mutgate sind rot.
  - Alle drei haben dieselbe Ursache außerhalb des Builder-Territoriums: Die geschützte Betreiber-Datei `reference/quellen/data/aiag/anova_example.csv` fehlt (E37, [INFRA]).
  - Mit ihr fehlen alle git-ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**`. Gelöscht wurden sie im Rollback nach der Territoriumsverletzung in Rework r5, Versuch 1, um 20:25 (BL-103).
  - Für den Builder ist das nicht blockierend (AGENTS.md, Handoff-Disziplin). PASS ist dennoch ausgeschlossen, solange `gates.result` nicht `pass` ist (SCHEMA.md). Deshalb lautet das Verdict REWORK ohne blocking-Befund (ADR-037 Nr. 2).
- **Rework:** Er erfüllt ADR-034.
  - E33 ist umgesetzt: 198 von 198 großen Plänen bis 5000 Stufen werden richtig entschieden (Prüflauf 3).
  - E34 ist umgesetzt: 78 von 78 Gewichtsprüfungen stimmen (Prüflauf 4).
  - E35 ist dokumentiert, E36 ist behoben.
  - Reguläre Pläne erreichen die Engine wie bisher, mit großem Abstand zur Schwelle (Prüflauf 5).
  - Alle Abnahmedateien ohne AIAG-Bezug sind grün, auch die im Gate nicht gelaufenen (Prüflauf 1).
  - `R CMD check --as-cran` ohne `REPO_ROOT` endet mit `Status: OK` (Prüflauf 6).
- **MUT-EQUIV:** Alle 16 Anträge sind echte Äquivalenzen. Die Freigaben sind auf die aktuellen Zeilen gebunden (Prüflauf 2, ADR-037 Nr. 3).
- **An den Betreiber:** Vor dem nächsten Gate-Lauf die Dateien wiederherstellen (BL-103). Ohne sie bleiben lint, tests und mutgate in jeder weiteren Runde rot. Der Orchestrator läuft mit `AUTONOMY_LEVEL=1` direkt in Runde 6 weiter; der Code der Runde 5 braucht nur einen neuen Gate-Lauf.
- **In dieser Phase umgesetzt:**
  - `docs/decisions/ADR-037-m1b-code-review-auslegungen-runde-5.md`;
  - `MUT-EQUIV-APPROVED.json` neu gebunden auf die Zeilen von `a8f8db7`;
  - in `BACKLOG.md`: BL-103 und BL-104 neu, Stand-Vermerke in BL-85, BL-93, BL-100, BL-101 und BL-102, BL-100 und BL-101 markiert „nach 26.11.2026“ (ADR-035 Nr. 3).

## Gelesen

- **Rollen und Protokoll:**
  - `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`;
  - der Prompt `50-code-review` Runde 5.
- **Orchestrator, nur lesend:**
  - `orchestrate.sh`: `rollback_attempt`, `changed_paths`, `snapshot_worktree`, `phase_logs_intact`, `restore_worktree`, `ownership_check`, `run_model`, `verdict` und `run_ms`;
  - `gates.d/86-mutgate.sh`, `lib/r-tests.R`, `lib/r-check.sh`, `lib/r-mutation.R`;
  - `config.env`, nur die Gate-Werte;
  - `logs/orchestrate.log` vollständig, die beiden Rework-Logs der Runde 5 über gezielte Suche.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 4, `REWORK-NOTES.md` der Runde 5;
  - `MUT-EQUIV.json` mit 16 Anträgen, `MUT-EQUIV-APPROVED.json` der Runde 4;
  - `QA.md`: kein neuer QA-Lauf seit dem Nachlauf vom 01.11., kein offener QA-Befund;
  - `ARBITER.md` und `ESCALATION-M1b.md`: unberührt;
  - Nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** docs/02 M1b (Z. 20–45), ADR-032 Nr. 1 bis 3, ADR-034, ADR-035 und ADR-036 vollständig.
- **Diff, ohne Git:**
  - geänderte Dateien seit dem Review der Runde 4 über `find -newer orchestrator/state/M1b/code-review-r4-infra0.done`;
  - der Inhalt aus dem letzten kumulativen `diff --git`-Block des Rework-Logs `orchestrator/logs/M1b-60-rework-r5-a1-20261101-214155.log` (Z. 28837–29313).
  - Geändert sind `R/fit.R`, `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md`, die drei `*_check_session.txt` sowie die Handoffs `REWORK-NOTES.md` und `MUT-EQUIV.json`. Die sechs Kurzlauf-CSVs tragen neue Zeitstempel; ihr Inhalt ist bytegleich (Prüflauf 1, K-M1b-2 und K-M1b-3). Neu sind ADR-036 und `tests/testthat/test-fit-latent-precision.R`.
  - Vom Betreiber: ADR-035 (21:26), `orchestrator/config.env` und `toolchain.json` (21:34).
  - Vollständig gelesen: `R/fit.R:170–489`, dazu die geänderten roxygen-Zeilen 117–156 aus Diff und Quelltext, und die neue Testdatei.
  - Abnahme-, QA- und Bestandstests sind unverändert; `find -newer` findet unter `tests/` nur die neue Unit-Datei.
- **Visuelle Artefakte:** keine; M1b fordert keine (`orchestrator/state/M1b/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 5 (`gates.json`, `env.sha` `a8f8db7`, 01.11.2026 22:22) | Ursache |
| --- | --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4) | – |
| lint | fail: `R CMD build` bricht beim Vignettenbau ab, „Validation input is missing: …/reference/quellen/data/aiag/anova_example.csv“ (`gate-lint.log` Z. 6–34) | E37 |
| tests | fail: `tests/testthat` `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5254 ]` (Z. 525); `tests/acceptance`: m1a-2 drei Abbrüche und m1a-3 ein Abbruch („local AIAG data sheet missing“), m1a-4 zehn Fehlschläge (Vignette), danach Abbruch des Ordners nach zehn Fehlschlägen (Z. 567–686); e2e 49 und fuzz 25 grün (Z. 713, 734) | E37, E38 |
| trace | pass | – |
| territory | pass (builder/60-rework, Runde 5, Basis `19c4140`) | – |
| mutgate | fail: unmutierter Vorlauf 125 s, 392 Tests, davon 12 fehlgeschlagen und 4 abgebrochen, alle von AIAG-Datei oder Vignette abhängig; kein Mutant gelaufen (`gate-mutgate.log` Z. 3–21) | E37 |
| golden-adr | pass (keine Golden- oder Ankeränderung) | – |
| mutfull | pass („nicht fällig in M1b“) | – |
| **result** | **fail** | |

- **Status error:** keiner. Die roten Gates melden `fail` (rc 1), weil ein fehlendes geschütztes Datenblatt die Abnahme absichtlich scheitern lässt (AGENTS.md, Domänenregeln: „sie überspringen nicht“).
- **Überlebende Mutanten:** keine benennbar. Ohne `mutation.json` gibt es keinen Survived- oder NoCoverage-Eintrag; der rote mutgate ist [INFRA] (E37).
- **Nicht gelaufen:** Im tests-Gate fehlen 17 Abnahmedateien nach m1a-4 (E38). m1b-2, m1b-3, m1b-7-vignette-full-results und m2-1 bis m2-7 liefen in keinem Gate, weil der mutgate-Vorlauf sie über `MUT_TEST_EXCLUDE` auslässt. Prüflauf 1 schließt die Lücke.
- **Laufzeit:** Rework 21:41 bis 22:15, Gates bis 22:22.

## Ursache der roten Gates (E37)

- **Zeitlinie:**
  - 19:21: Gates der Runde 4 grün, die AIAG-Abnahme eingeschlossen (REVIEW r4).
  - 20:03: Rework r5, Versuch 1 (`orchestrate.log` Z. 148). In diesem Versuch lief der AIAG-Abnahmetest noch mit der Datei (`M1b-60-rework-r5-a1-20261101-200310.log` Z. 25850, „K-M1a-2 report, AIAG example …“). Der Versuch berührt weder `reference/quellen/` noch `reference/privat/`.
  - 20:25:31 bis 20:25:33: Die Verzeichnisse `reference/quellen/text/`, `reference/privat/`, `reference/quellen/text/normen/`, alle sechs `literatur/`-Unterordner, `reference/quellen/data/aiag/` und `orchestrator/mcp/` ändern ihre Zeit.
  - 20:25:33: „WARN: builder verletzt Territorium: orchestrator/logs/** (Hash-Manifest)“ (`orchestrate.log` Z. 149). Die Meldung steht im Log nach `restore_worktree()`.
  - 21:34: Der Betreiber legt `config.env` und `toolchain.json` ab. Um 21:41 startet Runde 5 neu, der Builder findet die Datei nicht mehr (REWORK-NOTES P3, INFRA-AIAG).
- **Bestand jetzt:**
  - Unter `reference/quellen/**` und `reference/privat/**` liegt keine einzige Datei mehr; übrig sind 36 leere Verzeichnisse.
  - Es fehlen also auch `QUELLE.txt` des Datenblatts, der ganze Textspiegel sowie `QUELLENKATALOG.md`, `07_Formelsammlung_llmsa.md` und `90-katalog-offen.md`.
- **Mechanismus nach dem Code** (Betreiber-Territorium, nur gelesen):
  - `changed_paths()` und damit `snapshot_worktree()` lesen `git ls-files --others` ohne `--exclude-standard`. Ignorierte Dateien stehen deshalb in `OWNERSHIP_BEFORE`.
  - `restore_worktree()` löscht jeden dieser Pfade, für den keine Sicherung unter `$OWNERSHIP_SNAPSHOT/files` existiert (`orchestrate.sh:462–470`).
  - `phase_logs_intact()` schreibt und vergleicht seine Manifeste im selben Sicherungsverzeichnis (`:401–405`).
  - Eine fehlende oder unvollständige Sicherung erzeugt also die gemeldete Hash-Manifest-Verletzung und die Löschung zugleich. Den Auslöser zeigt das Repo nicht.
  - `git clean -qfd` in `rollback_attempt()` (`:343`) lässt ignorierte Dateien stehen und kommt als Ursache nicht in Frage.
- **Abgrenzung:** ACC-15 (ADR-024 Nr. 4) betraf versionierte Dateien; dies ist ein neuer Fall.

## Eigene Prüfläufe

Alle am 01.11.2026 mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4, testthat 3.3.2 und muttest 0.3.0, Produktstand `a8f8db7`. Der Arbeitsbaum ist gleich HEAD; dazu kommen `orchestrator/.lock/` und meine Probeskripte.

- Die Probeskripte lagen unter `tests/acceptance/.probe-m1b-r5/` und `orchestrator/handoff/M1b/.probe-r5/` im eigenen Territorium; beide sind per `unlink()` gelöscht. Paketkopien lagen unter `tempdir()`.
- Wo nur die Entscheidung zählt, sind die Engines über `testthat::with_mocked_bindings()` gesperrt: Sie enden mit „ENGINE-REACHED“.
- Die Daten sind synthetisch, mit Seeds ab 20261201. Die Referenzentscheidung folgt aus der Konstruktion: exakte Relation oder identifizierbarer Kontrollplan.
- Paketausgaben dienen nirgends als Referenz. Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Abnahme ohne Abbruchgrenze.** Aufruf wie in `lib/r-tests.R`: `REPO_ROOT` gesetzt, `NOT_CRAN=true`, dazu `options(testthat.progress.max_fails = Inf)`.

   ```text
   ✔ |        259 | m0-api-snapshot            ✔ |        687 | m1b-3-two-level-script [17.2s]
   ✔ |          2 | m0-testthat-count [117.3s] ✔ |   2     37 | m1b-4-two-levels [3.2s]
   ✔ |         91 | m1a-1-reml-anova [1.2s]    ✔ |          9 | m1b-5-binary-rptr
   ✖ | 3        0 | m1a-2-aiag                 ✔ |        108 | m1b-6-edge-cases [7.0s]
   ✖ | 1       50 | m1a-3-oracles [12.6s]      ✔ |        204 | m1b-7-vignette-full-results [20.3s]
   ✖ | 10       96 | m1a-4-nist [1.8s]         ✖ | 7       11 | m1b-7-vignette
   ✔ |         99 | m1a-5-metrics-verdict      ✔ |        149 | m2-1-items [137.7s]
   ✔ |        172 | m1a-6-invariance-edge      ✔ |         34 | m2-2-memorisation [89.2s]
   ✖ | 38       12 | m1a-7-vignette            ✔ |        837 | m2-3-prompts-parser [504.2s]
   ✔ |         34 | m1b-1-engine-ordinal       ✔ |         89 | m2-4-backends [1.6s]
   ✔ |        2155 | m1b-2-recovery-scripts    ✔ |        106 | m2-5-plan [1.9s]
                                                ✔ |        383 | m2-6-evaluate [104.3s]
                                                ✔ |        375 | m2-7-robustness-pilot [95.8s]
   elapsed: 21.10399 mins
   ```

   - Rot sind 16 Testblöcke (55 fehlgeschlagene Erwartungen, 4 Abbrüche), dieselben 16 wie im unmutierten mutgate-Vorlauf. Jeder davon in m1a-2, m1a-3, m1a-4, m1a-7 und m1b-7-vignette folgt aus der fehlenden Datei. Entweder bricht der Test mit „local AIAG data sheet missing“ ab, oder das Knit endet mit „Validation input is missing: …/anova_example.csv“. In m1b-7 ist danach der Abschnitt `NULL` (`test-m1b-7-vignette.R:31–84`).
   - K-M1b-1 bis K-M1b-6 sind grün. K-M1b-2 und K-M1b-3 reproduzieren die sechs Kurzlauf-CSVs bytegleich.
   - Der K-M1b-7-Abschnitt wird im öffentlichen Kontext gebaut und gelesen (m1b-7-vignette-full-results, 204 Erwartungen). Die zwei Warnungen in m1b-4 sind BL-93.

2. **MUT-EQUIV gegen den Mutantenplan.**
   - `muttest::muttest_plan()` über `R/fit.R` mit den neun Mutatorfamilien aus `lib/r-mutation.R` ergibt 1210 Mutanten. Der Schlüssel aus Datei, `mutatorName` und Anfangszeile ist derselbe wie in `86-mutgate.sh`.
   - Jeder Mutant ist aus dem Plan erzeugt und in eine eigene Umgebung über dem Namespace geladen. Verglichen ist er mit dem Original auf 150 gewichteten latenten Plänen bei gesperrten Engines, auf 14 numerischen Fits und auf 50 unbalancierten `aggregate()`-Aufrufen. Zwei der numerischen Fits enden mit Fehler; der verschachtelte Plan erst in `msa_numeric_optimize()`, also nach der Registrierung von `on.exit()` (`R/fit.R:658`, `:717`, `:743`).

   ```text
   mutants in R/fit.R: 1210
   key R/fit.R:415 '+ → -': 3 hit(s) [37 -; 46 -; 54 -] | claimed [37 -; 46 -; 54 -] | exact TRUE
   ... 13 weitere Schlüssel (314, 315, 329, 440, 448 zweimal, 523 zweimal, 608 zweimal, 709, 711, 717): je 1 hit, exact TRUE
   baseline latent decisions: 130 engine, 20 stopped; information matrices: 149
   baseline numeric fits without error: 12 of 14
   je Mutant (16): latent decisions identical TRUE | info matrices identical TRUE (149) | numeric identical TRUE | aggregate identical TRUE
   control 455:49 '- → +'      | latent decisions identical FALSE | info identical FALSE
   control 315:86 '<= → >='    | latent decisions identical FALSE | info identical FALSE
   control 338:94 '* → /'      | latent decisions identical FALSE | info identical TRUE
   control 332:16 '<= → <'     | latent decisions identical TRUE  | info identical TRUE
   control 331:42 'TRUE → FALSE' | latent decisions identical TRUE | info identical TRUE
   control 337:55 'TRUE → FALSE' | latent decisions identical TRUE | info identical TRUE
   ```

   - Die Kontrollen zeigen, dass das Raster Abweichungen sieht.
   - Die unbeantragten `symmetric`-Mutanten `:331:42` und `:337:55` verhalten sich hier gleich. Ein allgemeiner Beweis fehlt, weil `eigen()` dann einen anderen LAPACK-Pfad nimmt; sie sind nicht freigegeben (E39).

3. **Exakte Relationen großer Pläne (E33).**
   - Je Plan ordinal und binär, drei Seeds (Zeilenpermutation).
   - Ausgegeben ist das Verhältnis min(ev)/(k · eps · max(ev)) der Produktmatrix („new“). Zum Vergleich steht dieselbe Matrix nach der Rechnung der Runde 4 („old“, dichte Blöcke, im Probeskript nachgebaut). Ein Wert ≤ 1 heißt abgewiesen.

   ```text
   singleton items L=500..5000 (11 Größen)          rejected | new 0.000e+00 | old 8.3e-01 bis 3.064e+01 (L=900: 2.634, L=2000: 13.83, L=3000: 30.64)
   weight-0 duplicates L=900/2000/3000              rejected | new 0.000e+00 | old 2.634 / 13.83 / 30.64
   unequal counts, one positive each L=900..3000    rejected | new 0.000e+00
   item:prompt singletons, 2 prompts, L=600..2500   rejected | new -5.0e-02 bis 9.1e-02 | old (L=1000, ordinal) 1.501
   item:prompt singletons, 4 prompts, L=400/1000    rejected | new 6.8e-02 / 8.7e-02
   items nested in 3 models, interactions, L=1002/2001 rejected | new 5.2e-02 / 1.3e-02
   control: three obs per item L=900..3000          engine   | new 3.87e+14
   control: singletons + one doubled L=900..3000    engine   | new 1.25e+12 bis 3.75e+11
   control: 2 reps per item:prompt, L=600..2500     engine   | new 1.6e+11 bis 9.4e+13
   B summary: 198 cases, 198 as expected, 0 mismatches
   ```

   - Die alte Rechnung hätte 900, 1500, 2000, 2500 und 3000 Einzelbeobachtungen angenommen, dazu ordinal 600 und 1000 Items × 2 Prompts mit Wechselwirkung; 1000, 1024, 1999 und 2048 Einzelbeobachtungen wies sie ab. Die neue erkennt jede Relation bis 5000 Stufen mit höchstens dem 0,09-Fachen der Schwelle.
   - Identifizierbare Kontrollpläne gleicher Größe liegen beim 10¹¹- bis 10¹⁴-Fachen.

4. **Nicht ganzzahlige Gewichte (E34).** Je ordinal und binär, mit Prüfung der Gewichte, die die gesperrte Engine erhält.

   ```text
   54 singletons, uniform weight 0.5 / 1 / 1.25 / 1.5      rejected (exp rejected)
   54 singletons, uniform weight 2 / 3                    engine   (exp engine)
   54 singletons, weights 1, 2, 1.5                       rejected (exp rejected)
   singletons with weight 2 and weight-0 duplicates       engine   (exp engine)
   weight 2, the only 1.5 removed by subset               engine   (exp engine)
   18x3x3x3 uniform 0.1 / 0.5 / 1/486 / 0.002058 / 1e-30 / 1 / 2, interactions FALSE/TRUE   engine (exp engine)
   18x3x3x3 weights 0.1 / 1e-30 alternating               engine   (exp engine)
   C summary: 78 checks, 78 as expected, 0 mismatches (including engine weights passed unchanged)
   ```

5. **Reguläre Pläne** (ADR-035 Nr. 1 d).
   - Geprüft sind AP1 (100 × 3 × 3 × 3 × 2) und die Szenarien S-ord-1 bis S-ord-4 und S-two-1/-2 in ihrer Plangröße; S-bin-1/-2 haben dieselben Größen.
   - Jeder Plan ordinal und binär, mit und ohne Wechselwirkungen, mit 0 % und 1 % fehlenden Werten; dazu `ordinal::wine` (K-M1b-1) und `rptR::BeetlesMale` (K-M1b-5).

   ```text
   AP1 100x3x3x3x2 ... (8 Fälle)      engine | margin new 3.3e+11 bis 9.3e+11 | old gleich; rel. diff <= 2.5e-16
   S-ord-1/-3, S-ord-2, S-ord-4, S-two-1, S-two-2 (40 Fälle)  engine | margin 3.3e+11 bis 5.9e+12; rel. diff <= 3.4e-16
   K-M1b-1 wine bottle x judge        engine | margin 1.415e+14
   K-M1b-5 BeetlesMale Population     engine | margin 5.980e+13
   D summary: 50 cases, 50 as expected, 0 mismatches
   ```

   - Alte und neue Gram-Matrix stimmen dort auf 3,4e-16 relativ überein. Eine Gefahr falscher Abweisung regulärer Pläne ist nicht zu sehen.
   - Die Fits selbst sind unverändert: K-M1b-1, K-M1b-5 und die bytegleichen Kurzläufe aus Prüflauf 1.

6. **`R CMD check` im öffentlichen Kontext.**
   - Paketteile in eine Kopie unter `tempdir()`, ohne `REPO_ROOT`, sonst wie `lib/r-check.sh`: `R CMD build --no-manual`, dann `R CMD check --as-cran --no-manual` mit `_R_CHECK_CRAN_INCOMING_REMOTE_=false`.

   ```text
   build exit: 0 | * creating vignettes ... OK
   * checking for code/documentation mismatches ... OK
   * checking examples with --run-donttest ... [33s/33s] OK
     Running ‘testthat.R’ [81s/80s]  OK   [ FAIL 0 | WARN 0 | SKIP 9 | PASS 5178 ]
   * checking re-building of vignette outputs ... [30s/30s] OK
   Status: OK
   ```

   - Im Gate scheitert der Bau nur, weil `REPO_ROOT` die lokale Validierung mit dem geschützten Datenblatt wählt (`vignettes/validation.Rmd` Z. 37–45).

7. **Dokumentation, Namespace, Implementierungshash.**
   - `roxygen2::roxygenise()` in einer Kopie: `man/msa_fit.Rd` ist identisch mit dem Ergebnis, `NAMESPACE` ebenso.
   - `man/llmsa-package.Rd` weicht ab: roxygen ergänzt einen Autorenblock. Die Datei stammt vom 31.10. und ist nicht Teil dieser Runde.
   - `sim_implementation()` ergibt `477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e`, gleich den drei Sessiondateien.

8. **Reproduktionen der zurückgestellten Befunde** (ADR-035 Nr. 3).

   ```text
   BL-101 ordinal, weights 0 on M3   -> ERROR: Ordinal random-effect term model requires at least three observed levels.
   BL-101 ordinal, subset without M3 -> item=0 prompt=0 model=0.0025 Residual=1 | converged TRUE | warnings 1
   BL-100 numeric default path on the same rows -> ERROR: Numeric variance components are not identifiable.
   BL-100 numeric pass-through, subset -> item:model=0.1146 item:prompt=0.0383 item=10.7664 prompt:model=0.059 model=0.0306 prompt=0.1227 Residual=0.8028 | converged FALSE | warnings 2
   ```

   Aufrufe und Seeds stehen in BL-100 und BL-101.

## Stand der Einwände aus Runde 4

| ID | Stand | Beleg |
| --- | --- | --- |
| E33 | erledigt | Dünn besetzte Gram-Rechnung `R/fit.R:449–459` nach ADR-034 Nr. 1; Eigenwertregel, Restzeile, Restdiagonale und Rangnachweis unverändert (`:331–332`, `:464–472`). Prüflauf 3: 198 von 198; neue Unit-Datei mit den Größen aus ADR-034 |
| E34 | erledigt | `R/fit.R:279–281` nach Zeilenauswahl und Gewichtsprüfung. Die aufgelösten Prüfgewichte gelten für Kategorien (`:282`), Stufen (`:315`), festen Rang (`:322`) und Gram-Matrix (`:330`); `args` und Engine-Aufruf unverändert (`:374–375`). Prüflauf 4: 78 von 78; `?msa_fit` (`:123–130`) und `NEWS.md` |
| E35 | dokumentiert | „Known limitations“ (`R/fit.R:148–154`, `man/msa_fit.Rd`); Verhalten unverändert, BL-101 nach 26.11.2026 |
| E36 | erledigt | `as.data.frame(runs)` (`R/fit.R:180`); der widerlegte Antrag ist zurückgenommen; die 16 übrigen sind neu beantragt und freigegeben (Prüflauf 2). Unbeantragte Überlebende: E39, BL-102 |
| E32 | unverändert, außerhalb M1b | in „Known limitations“ genannt; BL-100 nach 26.11.2026 (Prüflauf 8) |
| E12–E19 | erledigt (Runde 2) | QA-M1b-001 bis -006 im Gate grün (e2e 49, fuzz 25) |
| E20 | Builder-Teil erledigt | BL-91, Reviewer-Teil offen (M1c/M1d) |
| E21 | unverändert, spec-gemäß | Kurzlauf-CSVs bytegleich reproduziert (Prüflauf 1); BL-92 |
| E22 | Sandbox-Befunde unverändert | REWORK-NOTES P4 und P6; BL-86 |
| E23 | offen, Reviewer | zwei Warnungen in m1b-4 (Prüflauf 1); BL-93 |

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **ADR-034 Nr. 1 (E33):**
  - G_ij = ΣN_ij² − 2Σ((B_iN_ij) ⊙ B_j) + Σ(F_i ⊙ F_j) mit F_i = B_iB_iᵀ ist die Entwicklung von ‖N_ij − B_iᵀB_j‖²_F. Die Spurformen aus ADR-034 sind elementweise geschrieben, also keine Näherung.
  - Die Rechnung bleibt im Stufenraum: N_ij dünn besetzt, B_iN_ij von der Größe Rang(X) × Stufen. Dichte Stufen-mal-Stufen-Blöcke entfallen.
  - Eigenwertregel, Restterm in k und `only.values = TRUE` sind unverändert. Neue Schwelle oder Toleranz: keine.
- **ADR-034 Nr. 2 (E34):**
  - Die Ganzzahligkeit wird nach `model.frame()` auf den behaltenen Zeilen entschieden; `weights != trunc(weights)` braucht keine Rundungstoleranz.
  - Nicht ganzzahlige Gewichte werden für alle Vorprüfungen zu Anzeigern positiver Zeilen.
  - Die Engine erhält `args` unverändert; Prüflauf 4 vergleicht die übergebenen Gewichte mit `identical()`.
- **ADR-032 Nr. 1.3 und 1.4:** Die Meldungen sind unverändert. Identifizierbare Pläne behalten ihren Fit: K-M1b-1 (34), K-M1b-5 (9), bytegleiche Kurzläufe (m1b-2 2155, m1b-3 687), Sessionhash wie in den Dateien.
- **ADR-035:** Die Umsetzung von E33 und E34 war Auftrag der Runde 5 (Nr. 4) und ist vollständig. Die übrigen offenen Fälle sind solche nach Nr. 2: Gewicht 0 bei der Termauswahl (BL-101) und der numerische Durchreichweg über `subset` (BL-100). Beide sind „nach 26.11.2026“ markiert, mit Reproduktion.
- **K-M1b-1 bis K-M1b-7:**
  - Builder-seitig erfüllt.
  - K-M1b-7 („`R CMD check` baut sie ohne ERROR und WARNING“) ist im Repo-Kontext nur wegen E37 rot. Im öffentlichen Kontext sind Vignette und Abschnitt grün (Prüfläufe 1 und 6).
- **Regulär vs. entartet (ADR-035 Nr. 1 d):** Kein Befund liefert bei regulären Plänen still falsche Ergebnisse (Prüflauf 5).

### API-Diff

- **Schnittstellen:** keine neuen Exporte, Argumente oder Vorgaben. Der API-Snapshot ist grün (259 Erwartungen im Gate und in Prüflauf 1); `NAMESPACE` und `DESCRIPTION` sind unverändert.
- **Verhalten:** Neue Abweisungen gibt es nur für exakt nicht identifizierbare Pläne. Nicht ganzzahlige Gewichte weisen identifizierbare Pläne nicht mehr ab. Die Engine-Gewichte sind unverändert.
- **Dokumentation:**
  - `?msa_fit` nennt die Gewichtsregel und die dünn besetzte Rechnung (`R/fit.R:123–130`) sowie den Abschnitt „Known limitations“ (`:148–154`, ADR-035 Nr. 3).
  - `NEWS.md` ergänzt den Eintrag zu latenten Fits.
  - `man/msa_fit.Rd` entspricht roxygen (Prüflauf 7).
- **Abhängigkeiten:** Imports und Suggests unverändert; `Matrix` war schon in Gebrauch.

### Tests: entkernt, eingefroren, hart

- **Bestandstests:** keine Bestands-, Abnahme-, QA- oder Fixture-Datei geändert.
- **Neue Datei `test-fit-latent-precision.R`** (7 Blöcke, 545 Erwartungen, 3,9 s im Gate). Sie belegt Verhalten:
  - Abweisung bei gesperrten Engines in den Größen aus ADR-034, ordinal und binär, beide Links; gleich große identifizierbare Kontrollen erreichen die Engine. Die Zählung `reached` folgt aus der Schleifenstruktur (24 und 8).
  - Geschlossene Formeln aus Itemhäufigkeiten als unabhängige Referenz: G = Σc² − 2Σc³/n + (Σc²/n)², Restrand n − Σc²/n, Restdiagonale n − 1. Ich habe sie aus tr(PKPK) nachgerechnet. Die Toleranz stammt aus ANK-TOL (`arithmetic.abs_tol`).
  - eine algebraisch exakte Nullzeile für eine vom festen Teil aufgespannte Partition;
  - Engine-Argumente unverändert (`identical()` auf Gewichte und Daten);
  - direkte `clmm`- und `glmer`-Fits als Orakel mit `engine_ordinal.rel_tol`.
- **Momentaufnahmen der eigenen Ausgabe:** keine. Die exakten Meldungstexte sind der Vertrag aus ADR-032 Nr. 1.3.
- **Harte Erwartungswerte:** nur abgeleitete. Die Gegenprobe des Builders auf dem alten `R/fit.R` scheitert mit 73 Erwartungen (REWORK-NOTES P1). Die Datei trennt also alt und neu.

### Konfiguration, Daten, Golden

- **Konfiguration:**
  - Der Builder hat keine Gate-, Schwellen- oder Lint-Regel gelockert.
  - `config.env` und `toolchain.json` tragen 21:34 (Betreiber). Die Gate-Werte entsprechen Runde 4: `MUT_RATCHET_TOL` 3 (ADR-031), Schwellen 80, unveränderter `MUT_TEST_EXCLUDE` (`gate-mutgate.log` Z. 2).
- **Daten:**
  - Die neun `_check_`-Dateien sind echte Läufe. Die sechs CSVs reproduzieren bytegleich (Prüflauf 1), der Hash stimmt (Prüflauf 7).
  - Keine Ersatzdaten für das fehlende Datenblatt (REWORK-NOTES P3); das ist richtig so.
- **Golden:** `inst/extdata/` und `reference/anchors/` unverändert (golden-adr pass).
- **Öffentliches Repository:** Die neuen Dateien enthalten keinen privaten Bezug.
- **[INFRA] des Builders** (REWORK-NOTES P4 bis P6): `timedatectl`, mirai-Dispatcher, Zeit-NOTE. Diese Grenzen bestehen nur in der Builder-Sandbox (BL-86). Prüflauf 6 zeigt die Zeitprüfung OK.

### MUT-EQUIV

Geprüft sind die 16 Anträge in `MUT-EQUIV.json` einzeln gegen den Mutantenplan, den Quelltext und das Verhalten (Prüflauf 2).

| Stelle | Mutator | Entscheidung | Begründung |
| --- | --- | --- | --- |
| `R/fit.R:314:47`, `:440:45`, `:711:41` | `TRUE → FALSE` | freigegeben | `strsplit(..., fixed = FALSE)`: Der Doppelpunkt ist auch als regulärer Ausdruck ein Literal; die Gruppennamen sind intern |
| `R/fit.R:315:64` | `FALSE → TRUE` | freigegeben | `drop = TRUE`: `interaction()` entpackt einen einspaltigen Datenrahmen; bei zwei Spalten wirkt `drop` nicht. Die aufgelösten Prüfgewichte ändern daran nichts |
| `R/fit.R:329:46` | `<n> + 1 → <n> + 1` | freigegeben | `matrix(2, …)`: Die Skalierung um eine Zweierpotenz ist exakt, auch in der neuen Gram-Rechnung; ein Zufallsterm hat mindestens zwei Stufen, der Rangnachweis greift also nie |
| `R/fit.R:415` (Spalten 37, 46, 54) | `+ → -` | freigegeben | `aggregate.formula()` gruppiert über `model.frame()` nach allen Formelvariablen; der Schlüssel trifft genau die drei beantragten Mutanten |
| `R/fit.R:448:18` | `<n> ± 1` (zweimal) | freigegeben | In der neuen Doppelschleife wird jede Zelle vor dem ersten Lesen geschrieben, mit und ohne Restterm |
| `R/fit.R:523:61` | `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]` | freigegeben | `counts[2]` statt `counts[1]`: erreichbar nur mit `prod(sizes)` ≥ 2 |
| `R/fit.R:608:33` | `<n> ± 1` (zweimal) | freigegeben | `gram` und `curvature` werden vor dem ersten Lesen vollständig geschrieben |
| `R/fit.R:709:52` | `TRUE → FALSE` | freigegeben | Von `lFormula()` werden nur `reTrms` gelesen |
| `R/fit.R:717:86` | `TRUE → FALSE` | freigegeben | genau ein `on.exit()` in `msa_numeric_fit()` (`R/fit.R:704–809`) |
| `R/grr.R:99:52` | `> → >=` | bestätigt | wie in Runde 3; `R/grr.R` unverändert |

- Die Quellzeilen von 314, 415, 440, 523, 608, 709, 711 und 717 sind bytegleich mit den Freigaben der Runde 4 (dort 299, 400, 424, 501, 586, 687, 689 und 695).
- Bei 315, 329 und 448 hat sich der Kontext geändert. Dort trägt der neue Verhaltensvergleich die Freigabe.
- Gebunden ist an die Zeilen von `a8f8db7` (ADR-037 Nr. 3). Jede Freigabe trägt `column` und `code`; nach dem nächsten Bericht prüft der Reviewer jeden Treffer dagegen (BL-85).

## Einwände (Runde 5)

- [E37] (minor) [INFRA] Gates lint, tests und mutgate (`gates.json` Runde 5, `result` `fail`); AGENTS.md, Domänenregeln („Abnahmetests schlagen fehl, wenn eine lokale geschützte Datei (`reference/quellen/data/`) fehlt; sie überspringen nicht.“) — **Befund:** Das geschützte AIAG-Datenblatt `reference/quellen/data/aiag/anova_example.csv` fehlt. Daraus folgen alle 16 roten Testblöcke der Abnahme (m1a-2, m1a-3, m1a-4, m1a-7, m1b-7-vignette; 55 fehlgeschlagene Erwartungen, 4 Abbrüche), der Abbruch des Vignettenbaus im lint-Gate und der rote mutgate-Vorlauf.
  - Mit dem Datenblatt fehlen alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**`, gelöscht im Rollback um 20:25:31 bis 20:25:33. Zeitlinie und Mechanismus stehen im Abschnitt „Ursache der roten Gates“.
  - Ursache und Abhilfe liegen im Betreiber-Territorium (`reference/quellen/**`, `reference/privat/**`, `orchestrator/**`). Für den Builder ist der Befund nicht blockierend.
  — **Vorschlag:** Betreiber nach BL-103:
  - die Dateien aus den Originalen unter `../quellen/` wiederherstellen; ANK-10 prüft den SHA-256 des Datenblatts;
  - prüfen, ob weitere ignorierte Dateien fehlen;
  - den Restore so ändern, dass er ignorierte Pfade weder sichert noch löscht und ohne vorhandene Sicherung nie löscht;
  - danach die Gates laufen lassen.
  - Builder: keine Ersatzdaten, kein Umgehen; einen fortbestehenden Grund als OUT-OF-TERRITORY melden.
- [E38] (minor) [INFRA] Gate tests (`gate-tests.log` Z. 685, „Maximum number of failures exceeded; quitting.“) — **Befund:** `lib/r-tests.R` lässt den `ProgressReporter` mit der testthat-Vorgabe von zehn Fehlschlägen laufen. Nach m1a-4 blieben 17 Abnahmedateien ungeprüft, darunter alle Kriterien von M1b; der Kurzbefund zählt 322 statt rund 480 Tests. Zusammen mit `MUT_TEST_EXCLUDE` liefen m1b-2, m1b-3, m1b-7-vignette-full-results und m2-1 bis m2-7 in Runde 5 in keinem Gate.
  — **Vorschlag:** Betreiber: `options(testthat.progress.max_fails = Inf)` in `r-tests.R` (BL-104). Bis dahin prüft das Review die übrigen Dateien bei rotem tests-Gate selbst (Prüflauf 1).
- [E39] (minor) Gate mutgate (fail ohne Bericht, E37); SCHEMA.md („Nur einzeln vom Reviewer approvte, nachweislich verhaltensgleiche Mutanten verlassen den Nenner.“); ADR-037 Nr. 3 — **Befund:** Ohne `mutation.json` ist der Score der Runde 5 offen. Im Teillauf des Builders (REWORK-NOTES P5) überleben drei Mutanten unbeantragt:
  - `R/fit.R:338:74` „> → >=“ an der Namensschwelle;
  - `:331:42` und `:337:55` „TRUE → FALSE“ (`symmetric` der beiden `eigen()`-Aufrufe).
  - Im Reviewer-Raster verhalten sich die beiden `symmetric`-Mutanten gleich. Ein Beweis fehlt, also gibt es keine Freigabe (Prüflauf 2).
  — **Vorschlag:** nicht verlangt. Nach den Zahlen der Runde 4 (93,02 bei verlangten 90,83) und den neu gebundenen Freigaben gefährden die drei die Schwelle nicht. Entschieden wird über den nächsten Bericht (BL-102).

## Hinweise für REWORK (Runde 6)

- **Umfang:** Es gibt keinen blocking-Befund, und keine Produktänderung ist verlangt (ADR-037 Nr. 2). E37 und E38 sind Betreiber-Sache.
- **Nicht tun:**
  - das Datenblatt oder andere Dateien unter `reference/` anlegen, ersetzen oder aus einer anderen Darstellung erzeugen;
  - Abnahmetests umgehen;
  - Arbeit an Befunden nach ADR-035 Nr. 2 beginnen (BL-100, BL-101).
- **Bindungen beachten:**
  - Jede Änderung an `R/fit.R` verschiebt die Zeilen der Freigaben (BL-85).
  - Eine Änderung an `msa_fit()` oder `msa_latent_information()` macht außerdem den Implementierungshash der neun `_check_`-Dateien ungültig (ADR-023 Nr. 1.5).
- **Belege:** Fehlt die Datei weiterhin, die Abnahme mit echtem Output als OUT-OF-TERRITORY ausweisen, wie in REWORK-NOTES r5 (P3).

## Backlog

- **Neu:**
  - BL-103: [INFRA], Rollback löscht git-ignorierte Betreiber-Dateien (E37);
  - BL-104: [INFRA], Abbruchgrenze des tests-Gates (E38).
- **Stand-Vermerke:**
  - BL-85: Neubindung auf `a8f8db7` über den Mutantenplan;
  - BL-93: unverändert;
  - BL-100 und BL-101: „nach 26.11.2026“ mit Reproduktion, ADR-035 Nr. 3;
  - BL-102: `stringsAsFactors` entfernt, unbeantragte Überlebende, E39.
- Ein blocking-Befund steht nicht offen.
