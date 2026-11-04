# PLAN-REVIEW — M3b, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 04.11.2026 · Gegenstand: `orchestrator/handoff/M3b/PLAN.md` (Runde 1, 466 Zeilen). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Es gibt keinen blocking-Befund.

- **Spec-Treue:**
  - Der Plan deckt K-M3b-1 bis K-M3b-6 vollständig ab, übernimmt die Auslegungen ACC-3, ACC-4, ACC-6, ACC-8, ACC-9, ACC-11 und ACC-15 (PLAN Z. 41–46) und die Entscheidungen aus ADR-050 Nr. 1 bis 4 (Z. 30–39, 116–127).
  - Keine Stelle widerspricht docs/04 M3b, docs/01 §2, §4 bis §6, §8, der Formelsammlung §7, ADR-050 oder den Abnahmetests.
  - Der Plan hält den Rahmen aus ADR-050, Konsequenzen: „`R/robustness.R` ändert nur den Hilfetext aus Nr. 3 zusätzlich zu dem, was K-M3b-4 und K-M3b-6 verlangen.“
- **Nachgeprüft (Prüfläufe 1 bis 3):**
  - Der Ausgangsstand des Plans stimmt Zahl für Zahl (27 Blöcke, 12 rote Erwartungen, 2 Fehlerblöcke, 414 grüne; Klasse-A-Studie grün).
  - Eine Attrappe genau nach den Schnittstellen des Plans macht alle 27 M3b-Blöcke grün. Der Standardpfad bleibt `identical()` zum heutigen `msa_robustness()`, also auch K-M1d-8.
  - Die geplante Fehlermeldung, der x-Achsentitel und der Hilfetext bestehen die Prüfungen aus ACC-11 (6), ACC-8 (4) und ACC-15.
  - Mutationsprobe: Mit den heutigen, nicht ausgeschlossenen Tests erreicht die Attrappe 63,2 % bei verlangten 80. Kein Mutant in `print.msa_robustness()` und `print.pb_design()` wird entdeckt (E1).
- **Einwände:** drei minor-Befunde, E1 bis E3. E1 betrifft das Gate mutgate und sollte vor dem ersten Gate-Lauf umgesetzt sein; keiner hält den Plan auf.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-051-m3b-reviewer-auslegungen.md`: hält ACC-3, ACC-4, ACC-6, ACC-8, ACC-9, ACC-11 und ACC-15 fest (Nr. 1 bis 7), die Anker und geschützten Daten aus ACC-1 und ACC-2 (Nr. 8), bestätigt neun Festlegungen des Plans (Nr. 9) und beschreibt den Mutationsumfang (Nr. 10, Hinweis).
  - In `CRITERIA.json` verweisen die Statuszeilen von ACC-1 bis ACC-4, ACC-6, ACC-8, ACC-9, ACC-11 bis ACC-13 und ACC-15 auf ADR-051. Kriterien und alle übrigen Felder sind unverändert (geprüft: Rundlauf durch jsonlite bytegleich, Vergleich der Objekte ohne `status`).

### An den Betreiber

1. **Keine Zuarbeit vor `40-build` nötig.**
   - FrF2 2.3.5, DoE.base 1.2.5 und unrepx 1.0.2 sind installiert; die deps-Prüfung findet sie nach der Suggests-Ergänzung.
   - `orchestrator/state/mut-baseline` fehlt, wie BL-123 verlangt; mutgate verlangt also `MUT_SCORE_MIN` = 80.
   - Die drei Lenth-Dateien unter `reference/quellen/data/lenth/` tragen die SHA-256 aus ANK-81: Die Prüfläufe 1 und 2 lesen sie über `acc_m3b_lenth_file()`, das bei Abweichung abbricht.
2. **Zur Planung (Hochrechnung, nicht gemessen):** mutgate wird `R/robustness.R` ganz mutieren, in der Probe 314 Mutanten. M1a r5 brauchte 15,5 s Wandzeit je Mutant bei 14 Workern (BL-13); der Testsatz ist seither länger. Das ergibt etwa 1,5 bis 2,5 Stunden je Durchgang, zweimal je Runde (nach BUILD und nach QA).
3. **Zur Kenntnis:** `MUT_TEST_EXCLUDE` (`config.env:267`) nimmt nach ADR-047 Nr. 4 alle `m1d-`-Tests aus, also auch K-M1d-8 und die M1d-QA-Tests. Nur sie prüfen die Druckausgabe von `print.msa_robustness()` (Prüflauf 3). Der Builder deckt das mit eigenen Unit-Tests ab (E1); eine Änderung der Konfiguration ist nicht nötig.

### Ablauf

Mit PASS gibt der Orchestrator den Plan frei, setzt den Tag `plan/M3b` und startet BUILD.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/04 M3b vollständig (Ergebnissatz, K-M3b-1 bis K-M3b-6); docs/01 §1 bis §9; Formelsammlung §7; `docs/gates-auswahl.md` §2 und §3; `ANKER-TODO.md` (M3b).
- **Handoff M3b:** `CRITERIA.json` (sechs Kriterien, ACC-1 bis ACC-15), `PLAN.md` vollständig. Zum Format: `PLAN-REVIEW.md` und `verdict-plan.json` aus M1d.
- **ADRs:** ADR-047, ADR-048 (Format), ADR-050.
- **Abnahmetests:**
  - `setup-acceptance.R`, `setup-m3b.R`, `test-m3b-1` bis `test-m3b-6` vollständig; `tests/simulation/setup-simulation.R` und `test-lenth-h0.R` vollständig;
  - `test-m1d-8-robustness-wording.R` Z. 80–121, `setup-m1d.R` Z. 680–736, `setup-m1c.R` Z. 719–739, `setup-m1b.R` Z. 172–185;
  - `test-m1a-7-vignette.R` Z. 100–134, `setup-m1a.R` Z. 540–580, Fundstellen der Literalprüfungen in `test-m1b-7-vignette.R`, `test-m1c-5-vignette.R` und `test-m1d-7-findings.R`.
- **Anker:** ANK-02 (`msa_robustness`, `pb_design`), ANK-06, ANK-80, ANK-81, ANK-82, ANK-TOL (`arithmetic`, `frf2_unrepx`, `mc_factor`, `sim_runtime`, `invariance`, `oracle`, `reml_anova`, `nist_digits`); die installierbare Kopie `inst/validation/numeric/anchors/ANK-TOL.json` ist bytegleich mit dem Anker.
- **Produktcode und Tests des Builders:** `R/robustness.R` vollständig, `R/acmg.R` Z. 1030–1089 und 230–232, `inst/templates/validation_report.Rmd` Z. 145–173, `DESCRIPTION`, `.Rbuildignore`, `NEWS.md` (Kopf), `vignettes/validation.Rmd` (Gliederung), `tests/testthat/test-robustness-plan-spc.R`, `helper-validation-numeric.R` Z. 1–17, `helper-validation-latent.R` (Fundstellen), `tests/e2e/test-m1d-qa-e2e.R` (Fundstellen).
- **Harness:** `orchestrate.sh` (`path_allowed` Z. 515–544), `gates.d/86-mutgate.sh` vollständig, `gates.d/70-trace.sh` Z. 11–36, `lib/r-mutation.R` Z. 40–150, `lib/r-deps.R` (Kopf), `config.env` Z. 196–270, `BACKLOG.md` (Status aller 126 Zeilen; gelesen BL-11, BL-13, BL-24, BL-38, BL-42, BL-48, BL-57, BL-118, BL-121 bis BL-126).

## Eigene Prüfläufe

Alle als R-Skripte unter `orchestrator/handoff/M3b/.probe-plan-review/` (danach gelöscht); Paketkopien unter `/tmp` (danach gelöscht). R 4.6.1, testthat 3.3.2, roxygen2 8.1.1, muttest 0.3.0, FrF2 2.3.5, DoE.base 1.2.5, unrepx 1.0.2; `test_dir(load_package = "source")`, `pdf(NULL)`, `REPO_ROOT` auf die Kopie. Im Arbeitsbaum nichts unter `R/`, `man/`, `tests/`, `vignettes/` oder `inst/` geschrieben. Kein Test mit Git-Aufruf ausgeführt (K-M1d-8 und K-M0-7 nicht).

### Prüflauf 1 — Ausgangsstand

- Kopie des Arbeitsbaums ohne Änderung (`R/robustness.R` mit gleicher Prüfsumme):
  - M3b-Abnahme: 27 Blöcke, 12 rote Erwartungen, 2 Fehlerblöcke, 0 übersprungen, 414 grüne Erwartungen.
  - Grün: `test-m3b-1` (101), `test-m3b-2` (11), `test-m3b-3` (183).
  - Rot: K-M3b-4 Benennung der Konvention (1 Test, 2 Erwartungen); K-M3b-5 Hilfeseite (3 Tests); K-M3b-6 `transform` (4 Tests, darunter die zwei Fehlerblöcke).
  - `tests/simulation`, `lenth-h0`: 1 Block, 6 Erwartungen, grün.
- Das gleicht PLAN Z. 420–436 und ACC-13. K-M3b-1 bis K-M3b-3 und der Simulationsteil von K-M3b-5 brauchen keine Produktänderung.

### Prüflauf 2 — Attrappe genau nach den Schnittstellen des Plans

- **Attrappe** (Kopie mit geändertem `R/robustness.R`, `man/msa_robustness.Rd` mit roxygen2 erzeugt):
  - `transform = "none"` als Literal hinter `alpha`; genau `"none"` oder `"logit"`, sonst Fehler;
  - im Logit-Pfad Prüfung auf numerische, endliche Werte in (0, 1) mit der Meldung aus PLAN Z. 105–107, danach `stats::qlogis()`;
  - x-Achsentitel „Half-normal quantile (Daniel, 1959)“;
  - Hilfetext mit „conservative“, „Nominal significance level for ME and SME.“, ohne den 5-%-Satz.
- **Abnahme:** M3b 27 Blöcke, 0 rot, 437 grüne Erwartungen; `lenth-h0` grün; `test-robustness-plan-spc.R`, `test-report.R` und `test-acmg-robustness-errors.R` grün (12 Blöcke, 118 Erwartungen).
- **Unverändertheit ohne Git:** `msa_robustness()` der Attrappe gleicht der unveränderten Funktion (aus `R/robustness.R` in eine Umgebung über dem Namensraum geladen) mit `identical()` auf sechs Aufrufen: Vorgabe, `alpha = 0.10`, Faktoruntermenge, einfacher data.frame, Antworten mit 0 und 1, konstante Antwort; jeweils auch mit `transform = "none"`.
- **Logit-Pfad:** auf vier Aufrufen `identical()` zur unveränderten Funktion auf `qlogis(p)`; Effekte gleich denen auf `log(p/(1 − p))` (größte Abweichung 0).
- **Fehler:**
  - Mit `"logit"` ergeben 0, 1, −0,1, 1,2, `Inf`, Zeichen, komplexe und logische Antworten die geplante Meldung; sie nennt 0 und 1 nach der Prüfung aus ACC-11 (6).
  - `NA` und `NaN` ergeben die bestehende Meldung „`response` must not contain NA.“
  - `transform` = `"probit"`, `c("none", "logit")`, `NA_character_`, `""`, `"LOGIT"`, `"lo"`, `1`, `TRUE` und `NULL` sind Fehler.
- **Hilfetext** nach `tools::Rd2txt`: Der Argumenteintrag lautet „alpha: Nominal significance level for ME and SME.“, der Satz mit „conservative“ steht in der Beschreibung. Alle drei Tests von `test-m3b-5` sind grün.

### Prüflauf 3 — Mutationsumfang von `R/robustness.R`

- **Mutanten:** `muttest::muttest_plan()` auf der Attrappe aus Prüflauf 2 mit den Mutatoren aus `orchestrator/lib/r-mutation.R:59–67`: 314 Mutanten. Je Mutant eine eigene Paketkopie, Tests im eigenen R-Prozess, 12 Worker.
  - Stufe 1: alle 314 gegen die M3b-Abnahme sowie `test-robustness-plan-spc.R`, `test-report.R` und `test-acmg-robustness-errors.R` (unmutiert grün, 23,9 s; 10,8 min).
  - Stufe 2: die 113 Überlebenden gegen alle übrigen nicht ausgeschlossenen Testdateien, die `acmg_`, `msa_report`, `pb_design`, `msa_robustness` oder `robustness` nennen: 16 unter `tests/testthat` (die übrigen zwölf `acmg-*`, `backend-finish-reason`, `backend-reasoning`, `fit-grr`, `parsers`), `m1c-7-latent-note`, die QA-Dateien `m1c` und `m2` unter `tests/e2e` und `tests/fuzz` (unmutiert grün, 113,8 s; 37,2 min). Wie im Gate bleiben die Tests nach `MUT_TEST_EXCLUDE` aus, darunter alle `m2-[0-9]`- und `m1d-`-Tests. Keine der Dateien ruft Git auf.
- **Ergebnis:** 194 entdeckt, 113 überlebt, 7 nicht ladbar (Parserfehler der Mutation selbst; das Gate zählt sie nicht). Score 194 / 307 = 63,2 %. Stufe 2 entdeckt keinen weiteren Mutanten.

  | Funktion | Mutanten | entdeckt | überlebt | nicht ladbar |
  | --- | --- | --- | --- | --- |
  | `pb_design()` | 102 | 67 | 35 | 0 |
  | `pb_matrix()` | 37 | 30 | 2 | 5 |
  | `print.pb_design()` | 8 | 0 | 8 | 0 |
  | `msa_robustness()` | 115 | 86 | 27 | 2 |
  | `print.msa_robustness()` | 27 | 0 | 27 | 0 |
  | `plot.msa_robustness()` | 25 | 11 | 14 | 0 |

- **Folgerung:** Für 80 müssen mindestens 52 der 113 Überlebenden entdeckt werden.
  - Ohne Tests für die Druck- und Plotmethoden bleiben dafür nur 64 Überlebende in den übrigen Funktionen, davon 8 Äquivalenzkandidaten (E1, Nr. 7). Selbst wenn jeder andere entdeckt würde, ergäbe das 250 / 307 = 81,4 %.
  - Die Druck- und Plotmethoden gehören deshalb in die Unit-Tests (E1).

## Antworten auf die Einwand-IDs

- **Runde 1:** Es gibt keine früheren Einwände.
- **ACC-1 und ACC-2:** Anker und Dateien liegen vor, der Plan prüft die SHA-256 vor BUILD erneut (Z. 149–150, 382–386); festgehalten in ADR-051 Nr. 8.
- **ACC-3, ACC-4, ACC-6, ACC-8, ACC-9, ACC-11 und ACC-15:** übernommen (Z. 41–46); der Testplan beschreibt die Prüfwege unverändert (Z. 297–317). Festgehalten in ADR-051 Nr. 1 bis 7.
- **ACC-5, ACC-7 und ACC-10:** richtig als entschieden wiedergegeben (Z. 30–39). Der Plan kalibriert nichts auf die gemessene Rate (Z. 180).
- **ACC-12:** umgesetzt mit `FrF2`, `DoE.base` und `unrepx` nur in Suggests (Z. 60, 153–155); ADR-051 Nr. 9.8.
- **ACC-13:** zu Recht als Infrastrukturhinweis behandelt. Er gilt für die Abnahmedateien; der Umfang der Mutation ist Gegenstand von E1.
- **ACC-14:** Der Plan formuliert die Meldung nach dem Hinweis aus ACC-14 (Z. 104–109); Prüflauf 2 bestätigt das.
- **BACKLOG:** Alle 126 Zeilen sind zugeordnet: 86 offene mit Behandlung oder begründeter Vertagung (Z. 195–282) und 40 erledigte (Z. 284–291). BL-38 trägt „erledigt“ klein in der Spalte Folge und zählt zu Recht zu den erledigten. Stichproben gegen den Text: BL-11, BL-42, BL-48, BL-57, BL-123, BL-125, BL-126. Jede Vertagung nennt Grund und Zuständigkeit (AGENTS.md, Handoff-Disziplin).

## Einwände (Runde 1)

- [E1] (minor) Gate mutgate (`orchestrator/gates.d/86-mutgate.sh:22`, `:87–93`; `config.env:228–229`, `:267`); ANK-32; docs/01 §2 Nr. 7 („die übrigen Dateien ab M3 über das mutgate mit derselben Schwelle“); ADR-047 Nr. 4; ADR-051 Nr. 10 — **Befund:** Der Plan weiß, dass die ganze Datei mutiert wird (Z. 183, 367–369). Er plant Tests aber nur „für den betroffenen Pfad“ (Z. 183, 319–347).
  - Prüflauf 3: Mit den heutigen, nicht ausgeschlossenen Tests erreicht die Attrappe 63,2 %, verlangt sind 80.
  - Unentdeckt bleiben alle 27 Mutanten in `print.msa_robustness()`, alle 8 in `print.pb_design()` und 14 von 25 in `plot.msa_robustness()`. Die Druckausgabe prüfen nur K-M1d-8 und die M1d-QA-Tests, und `MUT_TEST_EXCLUDE` nimmt sie aus.
  - Ohne Tests für diese drei Methoden reicht auch eine vollständige Abdeckung der übrigen Funktionen kaum (höchstens 81,4 %).

  — **Vorschlag:** vor dem ersten Gate-Lauf Unit-Tests unter `tests/testthat/` mit Namen außerhalb von `MUT_TEST_EXCLUDE`, nach Überlebenden geordnet (Zeilen nach `R/robustness.R` vor M3b):
  1. **`print.msa_robustness()`** (Z. 159–177, 27 überlebt): die ganze Ausgabe von `capture.output(print(x))` gegen Zeilen, die der Test aus den Attributen bildet:
     - Kopfzeile mit `n_runs`, Faktorzahl, `response_mean` und `response_sd`;
     - die Zeile mit PSE, ME (`formatC(…, format = "f", digits = 4)`), SME und `alpha`;
     - die Tabelle ohne Zeilennamen mit `t_lenth` auf zwei Stellen;
     - die Zeile der aktiven Faktoren mit „above ME only“ und „also above SME“ und, in einem zweiten Fall, der Satz ohne aktiven Faktor;
     - Rückgabe unsichtbar und identisch.
     Das ist die Unit-Fassung von K-M1d-8; die Abnahme selbst zählt im Mutationslauf nicht.
  2. **`print.pb_design()`** (Z. 91–96, 8): Kopfzeile genau, etwa „Plackett-Burman design: 12 runs, 9 factors (12-run design screens up to 11)“; Tabelle ohne Zeilennamen; Rückgabe unsichtbar.
  3. **`plot.msa_robustness()`** (Z. 180–191, 14): aus der Display-Liste wie `acc_m3b_plot_record()`:
     - `ylab` „|effect|“ und der Haupttitel;
     - `pch` 19 der Punktmenge;
     - zwei `C_abline` bei h = ME mit `lty` 2 und bei h = SME mit `lty` 3;
     - die Beschriftungen in der Reihenfolge von |Ê| an (q, |Ê|) mit `pos` 2 und `cex` 0,8.
  4. **Fehlerpfade von `pb_design()` und `msa_robustness()`** (Z. 41–50, 132–136 und die neuen Prüfungen):
     - jede Meldung genau (`expect_error(…, "…", fixed = TRUE)`) und `conditionCall()` gleich `NULL`; das deckt neun Mutanten `call. = FALSE` → `TRUE` und die leeren Meldungen ab;
     - je Teilbedingung ein eigener Fall: Liste ohne Namen und mit einem leeren Namen, ein Faktor mit drei Stufen, `n_runs = 10` und `NA`;
     - zu wenige Läufe an beiden Grenzen, `pb_design(8, n_runs = 8)` mit „8 factors need at least 12 runs.“ und `pb_design(11, n_runs = 8)` mit „11 factors need at least 12 runs.“. Erst beide zusammen decken die 13 Mutanten in Z. 50 ab: Der erste Fall trifft `n_runs - 1` und `sizes - 1` → `+ 1`, der zweite `>=` → `>` und `sizes - 2`;
     - für `transform` und den Logit-Pfad jede Teilbedingung einzeln;
     - `llmsa:::pb_matrix(10)` mit „unsupported size“.
  5. **Weitere Pfade von `pb_design()`:**
     - eine Zahl k ergibt keine `_level`-Spalten und das Attribut `factors` mit `c(-1, 1)` je Faktor `F1` … `Fk`;
     - eine Liste mit einem Faktor nimmt den Listenpfad;
     - ein Faktor mit Randomisierung behält eine Matrix (`drop = FALSE`);
     - nicht syntaktische Namen wie „extra context“ bleiben (`check.names = FALSE`);
     - die Klasse ist `c("pb_design", "data.frame")`.
  6. **`msa_robustness()`:**
     - eine ausgewählte Spalte aus `pb_design` und aus einem einfachen data.frame (`drop = FALSE`, zwei Stellen);
     - `t_lenth` gleich `effect / attr(x, "pse")` in einem Fall mit 0 < PSE < 1 (sonst bliebe `pse > 0` → `pse > 1` unentdeckt);
     - bei konstanter Antwort `pse` 0, `t_lenth` `identical()` zu `rep(NA_real_, m)` und kein Flag gesetzt. Das deckt `>` → `>=` in `active` und `active_simultaneous` ab, weil dann ME = SME = 0 ist.
  7. **Äquivalenzkandidaten** (8 der 113; keine Freigabe zugesagt, Antrag nur einzeln in `MUT-EQUIV.json` mit Beweis):
     - `matrix(NA_real_, …)` → `matrix(NA, …)` in `pb_matrix()`: Jeder Eintrag wird mit einer Zahl überschrieben.
     - `add = TRUE` → `FALSE` im einzigen `on.exit()` von `pb_design()`.
     - `X[, nm] > 0` → `>= 0` und `> -1` in Z. 64: X stammt immer aus `pb_matrix()`, also ±1.
     - Nur unter der dokumentierten ±1-Kodierung gleich: die vier Mutanten von `x > 0` und `x < 0` in Z. 137. `msa_robustness()` prüft die Kodierung nicht.
  8. **Laufzeit:** Die neuen Unit-Tests laufen für jeden der rund 300 Mutanten. Deshalb im Bereich von Sekunden bleiben, ohne Schleifen über `FrF2::pb()` und ohne Simulation.
  9. **Kein Score über den Code:** Bestehender Code in `R/robustness.R` wird für den Score nicht umgebaut oder entfernt, kein neuer Ausschluss (ADR-050, Konsequenzen; ADR-051 Nr. 10.4).

  Lokal lässt sich das vor der Übergabe nachprüfen, wenn die Sandbox es zulässt: Mutanten aus `muttest::muttest_plan()` in Paketkopien unter `tempdir()`, gegen die M3b-Abnahme und die betroffenen Unit-Tests. Prüflauf 3, Stufe 1, brauchte dafür 10,8 min auf 12 Workern.
- [E2] (minor) docs/01 §2 Nr. 8; AGENTS.md, Projektblock („`validation.Rmd` (ab M1a, liest Anker und Klasse-B-Ergebnisse ein, nichts abgetippt)“); `tests/acceptance/test-m1a-7-vignette.R:110–134`; `test-m1b-7-vignette.R:95–116`; `test-m1c-5-vignette.R:46–61`; `test-m1d-7-findings.R:87–97`; `tests/testthat/test-validation-latent.R:123–156` — **Befund:** Der Plan sieht einen kurzen Methodenabschnitt zu M3b in `vignettes/validation.Rmd` vor, ohne abgetippte Simulationsergebnisse (Z. 63). Vier Abnahmetests früherer Meilensteine prüfen aber jedes Zahlenliteral der ganzen Datei.
  - K-M1a-7 wertet jedes Literal als abgetippt, das einer Toleranz von ANK-TOL `reml_anova`, `oracle`, `nist_digits` oder `invariance` gleicht (1e-4, 1e-6, 1e-8), gleich mit wie vielen Stellen.
  - Ein Satz wie „agree with DoE.base to 1e-8“ machte K-M1a-7 rot, denn `frf2_unrepx.pse_me_tol` hat denselben Wert wie `oracle.closed_form_rel_tol`.
  - Dazu kommen Literale mit mindestens drei signifikanten Stellen aus ANK-10, ANK-13, ANK-14, ANK-16 (K-M1a-7), ANK-21, ANK-25, ANK-28 (K-M1b-7) und aus den Ergebnisdateien (K-M1b-7, K-M1c-5, K-M1d-7).

  — **Vorschlag:**
  - Der Abschnitt kommt ohne Zahlenliterale aus. Er nennt die Prüfwege mit Anker-IDs (ANK-80, ANK-81, ANK-82, ANK-TOL.frf2_unrepx, ANK-TOL.mc_factor) und Testdateien.
  - Kein Chunk ruft FrF2, DoE.base oder unrepx auf oder simuliert, außer bedingt mit `requireNamespace()`.
  - Kein neues `source()` oder `sys.source()`: Der Unit-Test verfolgt sie und bricht bei nicht wörtlichen Pfaden ab.
  - Sollen Zahlen erscheinen, liest die Vignette sie wie die übrigen Abschnitte zur Bauzeit; das verlangt M3b nicht.
- [E3] (minor) K-M3b-5 („Die Hilfeseite von `msa_robustness()` nennt das Verfahren konservativ und α einen Nominalwert“); ADR-050 Nr. 3; ACC-15; ANK-81 `further_quotes` (Druckseiten 470 und 472–473); K-M3b-6; docs/01 §2 Nr. 4 — **Befund:** Der Plan legt die Prüfwörter fest (Z. 131–134). Die Tests prüfen nur die Wörter, nicht den Inhalt der Sätze. Der Inhalt soll das gemessene Verhalten richtig wiedergeben.

  — **Vorschlag** für die Beschreibung und die Argumente:
  1. „Conservative“ bezieht sich auf ME und SME: Unter H0 liegen die tatsächlichen Fehlalarmraten je Effekt und je Plan unter dem nominalen `alpha` (Lenth 1989, S. 472–473; gemessen in K-M3b-5).
  2. Erwähnt die Seite γ, dann mit Lenths Satz, γ sei für unabhängige Schätzer „exact, not conservative“ (S. 470). Der Satz mit „conservative“ für das Verfahren steht dann getrennt, damit die Verneinung ihn nicht trifft.
  3. `@param transform`:
     - zulässig `"none"` (Vorgabe) und `"logit"`;
     - `"logit"` verlangt Anteile strikt zwischen 0 und 1 und korrigiert nicht;
     - Anteile von genau 0 oder 1 brauchen vorher eine Korrektur, etwa den empirischen Logit wie in `acmg_robustness()`, und gehen dann mit `"none"` ein;
     - alle Ergebnisse, auch `response_mean` und `response_sd`, stehen dann auf der Logit-Skala.
  4. Kein Rest von „5 %“ oder „5%“ mit „level per effect“, auch nicht in `@return` oder den Beispielen; Rd2txt fügt Zeilen zusammen.
  5. Daniel (1959) darf unter `@references` stehen; das dokumentiert K-M3b-4. Weitere Änderungen am Hilfetext von `R/robustness.R` sind nicht vorgesehen (ADR-050, Konsequenzen).
  6. Die drei Tests aus `test-m3b-5` lesen `man/msa_robustness.Rd` aus dem Wurzelverzeichnis und rufen kein Git auf; BUILD kann sie direkt laufen lassen.

## Prüfung nach Gesichtspunkten

### Spec-Treue

- **K-M3b-1, K-M3b-2, K-M3b-3:** Der Code vor M3b erfüllt sie (Prüflauf 1). Der Plan erhält PB-Konstruktion und Lenth-Rechnung und ändert keine Konstante (Z. 122–127).
- **K-M3b-4:**
  - Positionen und y-Werte bleiben (Z. 128–130).
  - Der x-Achsentitel nennt „Daniel“ und „1959“ im selben Text; der Haupttitel allein zählte nicht (ACC-8 (4)).
- **K-M3b-5:**
  - Die Klasse-A-Studie bleibt Reviewer-Territorium und unverändert (Z. 306–317); auf dem Code vor M3b ist sie grün.
  - Der Hilfetext nennt das Verfahren konservativ und α nominal und lässt den 5-%-Satz fallen (Z. 131–134; E3 zum Inhalt).
- **K-M3b-6:**
  - Den Teil zu `pb_design()` (Plangröße, Seed, Stufen) erfüllt der Code vor M3b schon (Prüflauf 1).
  - `transform` mit Vorgabe `"none"` am Ende; Logit nur für (0, 1); Fehler für 0 und 1 vor der Transformation; jeder andere Wert ein Fehler (Z. 84–115).
  - Werte außerhalb von [0, 1] als Fehler sind die sichere Lesart der schweigenden Spec (docs/01 §2 Nr. 4; Formelsammlung §7: „Anteile nahe 0 oder 1 vorher logit-transformieren“).

### Architektur und Verträge

- **Schnittstelle:** ein neues Argument mit Vorgabewert am Ende, ohne ADR erlaubt (docs/01 §4). ANK-02 bleibt Obermenge, BL-57 ist erfüllt. Kein neuer Export, kein neuer Import, nur Suggests.
- **Rückgabe:** kein neues Attribut, weil K-M1d-8 ganze Objekte mit `done/M1c` vergleicht (Z. 116–121; Prüflauf 2).
  - Der Logit-Pfad nennt seine Skala damit nur auf der Hilfeseite.
  - Druck und Bericht zeigen `response_mean` ohne Skalenangabe, wie heute schon, wenn ein Aufrufer transformierte Antworten übergibt (so `acmg_robustness()`). Eine Skalenangabe in der Ausgabe ginge über den Rahmen aus ADR-050, Konsequenzen, hinaus und ist kein M3b-Kriterium.
- **AP1:** `acmg_robustness()` transformiert selbst und bleibt bei `"none"` (Z. 138–141; `R/acmg.R:1065–1067`).
- **Parallelisierung:** keine in `R/`.

### Vollständigkeit

- Sechs Kriterien, ACC-1 bis ACC-15 und alle 126 BACKLOG-Zeilen sind zugeordnet.
- Die Dateiliste nennt `R/robustness.R`, die erzeugte Hilfeseite, `DESCRIPTION`, zwei neue Unit-Testdateien, Vignette, `NEWS.md`, `PROGRESS.md` und `REVIEW-INPUT.md` (Z. 56–66).
- Es fehlen nur Tests für die unveränderten Methoden derselben Datei (E1) und die Vorsicht bei Literalen in der Vignette (E2).

### Risiken

- Der Plan nennt die wesentlichen Risiken mit Gegenmaßnahme (Z. 176–184): doppelte Transformation, Orakelkonventionen, Kalibrierung, Beschriftung, fehlende Eingaben, Mutation, Sandbox.
- Dazu aus den Prüfläufen:
  - der Mutationsumfang der unveränderten Methoden (E1);
  - die Literalprüfungen der Vignette (E2).
- **Laufzeit:** M3b-Abnahme 3 bis 4 s, Klasse-A-Studie 3 s (Prüfläufe 1 und 2), weit unter ANK-TOL.sim_runtime.

### Gate-Abdeckung

- **deps:** Die drei Suggests sind installiert; die Prüfung findet sie in `DESCRIPTION`.
- **lint:** `R CMD check --as-cran` verlangt die erzeugte Hilfeseite mit dem neuen Argument (codoc, dokumentierte Argumente). Der Plan erzeugt sie aus roxygen (Z. 58–59, 68–69, 159–162).
- **tests:**
  - die M3b-Abnahme und die Klasse-A-Studie;
  - kumulativ K-M1d-8 (Unverändertheit) und K-M0-7 (ANK-02). Beide nutzen Git (K-M0-7 in Teilen) und laufen vollständig nur im Gate; der Plan prüft das Wesentliche vorher ohne Git (Z. 342–347; Prüflauf 2 zeigt, dass das geht).
- **trace:** Die Kriteriums-IDs stehen in den Abnahmetests.
- **territory:** Alle Dateien der Liste liegen in den Builder-Pfaden von `40-build` (`config.env:200`, `orchestrate.sh:526–534`).
- **mutgate:** Die ganze Datei `R/robustness.R`, Schwelle 80 ohne Baseline (E1).
- **golden-adr:** Unter `inst/extdata/` und `reference/anchors/` ändert sich nichts; die Anker liegen vor dem Tag `plan/M3b`.
- **mutfull:** nur M1c.

## Hinweise für BUILD

1. Vor der ersten Änderung `R/robustness.R` und `R/acmg.R` außerhalb des Arbeitsbaums sichern und danach ohne Git vergleichen (Z. 150–151, 342–345):
   - die fünf Aufrufe aus K-M1d-8 mit `identical()`;
   - die fünf Einstellungen von `acmg_robustness()`.
2. Umsetzung nach ADR-051 Nr. 9, Hilfetext nach E3.
3. Die Unit-Tests aus E1 vor dem ersten Gate-Lauf.
4. Den Vignettenabschnitt ohne Zahlenliterale (E2).
5. Die M3b-Abnahme (`filter = "^m3b-"`) und die Klasse-A-Studie rufen kein Git auf und können in BUILD laufen. Nachweise mit echtem Output in `PROGRESS.md` und `REVIEW-INPUT.md`; Proben vor dem Ende der Phase löschen.
