# PLAN-REVIEW — M1c, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 02.11.2026 · Gegenstand: `orchestrator/handoff/M1c/PLAN.md` (Runde 1, 559 Zeilen). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Es gibt keinen blocking-Befund.

- **Spec-Treue:** Der Plan deckt K-M1c-1 bis K-M1c-8 vollständig ab und übernimmt alle Auslegungen ACC-1 bis ACC-13 und ACC-18 bis ACC-20 (PLAN Z. 38–43). Keine Stelle widerspricht docs/02, docs/01, ADR-040, ADR-041 oder den Abnahmetests.
- **Technische Zusagen nachgeprüft:**
  - Der geplante Weg für `n_singular` (Kennzeichen in der `FUN`, nach `bootMer()` abgetrennt) hält `msa_boot()` bytegleich mit dem Stand `done/M1b` und trifft die Referenzzählungen (Prüflauf 1).
  - Die Seed-Regel erfüllt Präfix- und Teilmengenstabilität (Prüflauf 3).
  - Alle geplanten BUILD-Pfade liegen im Builder-Territorium (Prüflauf 5); alle 109 BACKLOG-Einträge sind zugeordnet (Prüflauf 4).
- **Einwände:** sechs minor-Befunde, E1 bis E6. BUILD berücksichtigt sie; keiner hält den Plan auf.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-042-m1c-reviewer-auslegungen.md` hält ACC-1 bis ACC-13, ACC-18 bis ACC-20 und die Anker ANK-32 und ANK-33 fest (ACC-15) und bestätigt drei Festlegungen des Plans (Seed-Regel, Singularitätskennzeichen, Ort von `msa_boot()`).
  - In `CRITERIA.json` verweisen die Statuszeilen von ACC-1 bis ACC-13, ACC-15, ACC-17 bis ACC-20 darauf; ACC-14 steht auf „umgesetzt“. Berichtigt sind zwei Messwerte (Prüflauf 6). Kriterien und alle übrigen Felder sind unverändert.

### An den Betreiber

1. **ACC-14** ist umgesetzt: `orchestrator/config.env:267` trägt den vorgeschlagenen Ausdruck als letzte Zuweisung von `MUT_TEST_EXCLUDE`.
2. **ACC-21** ist weiter offen: `docs/gates-auswahl.md:122` nennt für das Gate tests „K-M1c-1 bis K-M1c-5“; K-M1c-7 und K-M1c-8 fehlen. Ohne Einfluss auf trace, das `CRITERIA.json` und `milestones.json` liest.
3. **`R/boot.R` in docs/02 M1d:** Der Satz „M1d ändert `R/fit.R` und `R/boot.R` nur in der roxygen-Dokumentation“ setzt eine Datei voraus, die es nach ADR-042 Nr. 18.3 nicht gibt; `msa_boot()` bleibt in `R/grr.R`, damit der Bootstrap im Mutationsumfang bleibt (ACC-17). Vor M1d sollte die Spec sagen, welche Datei gemeint ist.
4. **Mutationsreserve (E2):** Für M1c gibt es noch keine Freigabedatei. Runde 1 startet ohne Freigaben bei 92,95 gegen verlangte 92,09.

### Ablauf

Mit PASS gibt der Orchestrator den Plan frei, setzt den Tag `plan/M1c` und startet BUILD.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, Prompt `30-plan-review.md`.
- **Spezifikation:** docs/02 vollständig (M1b, M1c mit Szenariotabelle und K-M1c-1 bis K-M1c-8, M1d); docs/01 §1 bis §9; `docs/gates-auswahl.md` (Zuordnung der Gates).
- **Handoff M1c:** `CRITERIA.json` (acht Kriterien, ACC-1 bis ACC-22), `PLAN.md` vollständig.
- **Handoff M1b und M1a:** `PLAN-REVIEW.md` M1b (Runde 2), `verdict-plan.json` M1a, `MUT-EQUIV-APPROVED.json` M1b (15 Schlüssel).
- **ADRs:** ADR-023, ADR-025 (Format), ADR-035, ADR-039, ADR-040, ADR-041.
- **Abnahmetests:** `setup-acceptance.R`, `setup-m1c.R` vollständig; `test-m1c-1` bis `test-m1c-8` alle elf Dateien; `test-m2-6-evaluate.R` Z. 85–135 (Rückfall nach dem neuen Limit).
- **Anker:** ANK-32, ANK-33, ANK-TOL (engine_boot, engine_ordinal, arithmetic, n_check, sim_runtime, mc_factor), ANK-06.
- **Produktcode und Validierung:** `R/grr.R` vollständig; `R/fit.R` Z. 176–177, 240–400, 480–498; `R/acmg.R:932, 950`; `inst/validation/sim/simulation_helpers.R` vollständig; `inst/templates/validation_report.Rmd` Z. 1–114; `vignettes/validation.Rmd` Z. 120–235; die Unit-Tests, die `msa_boot()` aufrufen oder die ordinale Steuerung lesen (`test-grr-numeric.R:50–58`, `test-grr-rework.R:110–160`, `test-fit-latent-diagnostics.R:1–23`, `test-fit-latent-rework.R:25–45`, `test-fit-rework-inputs.R:1–30`, `test-fit-numeric.R:200–210`).
- **Harness:** `orchestrate.sh` (`path_allowed`, `ownership_check`), `gates.d/86-mutgate.sh`, `gates.d/87-golden-adr.sh`, `lib/r-mutation.R` (Testauswahl), `config.env` Z. 149–271, `state/mut-baseline`, `reports/mutation/mutation.json` (Gate-Lauf M1b Runde 7), `BACKLOG.md`.
- **Engines:** `ordinal:::getCtrlArgs`, `args(ordinal::clmm)`, `args(ordinal::clmm.control)`.

## Eigene Prüfläufe

- **Aufrufe:** am 02.11.2026 mit `Rscript --vanilla` auf eine Probe unter `orchestrator/handoff/M1c/` (danach mit `unlink()` gelöscht); das Paket über `pkgload::load_all()`, die Abnahmehelfer per `sys.source()` aus `tests/acceptance/setup-*.R`, `REPO_ROOT` über `Sys.setenv()`.
- **Versionen:** R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4, Referenz-BLAS 3.12.1.
- **Arbeitsbaum:** `R/fit.R` und `R/grr.R` tragen die SHA-256 aus ANK-33. Außer dieser Phase gehörenden Dateien wurde nichts geschrieben; `find -newer PLAN.md` zeigt sonst nur Orchestrator-Zustand und -Logs.
- **Output:** Gezeigt ist echter Output, gekürzt nur um Leerzeilen.

1. **Geplanter Bootstrap (PLAN Z. 91–110) gegen den heutigen Code.** Eine Variante von `msa_boot()` nach dem Plan: die `FUN` liefert `c(<sechs Kennzahlen>, .singular = isSingular(m))`, `attr(, "boot")` erhält nur die sechs Spalten, `n_failed` zählt Zeilen mit einer nicht endlichen Kennzahl, `n_singular` singuläre unter den endlichen. Verglichen mit `acc_m1c_boot_core()` aus `setup-m1c.R`, also genau den Teilen, die K-M1c-7 vergleicht; `ref` ist die Referenz der Abnahmetests.

   ```text
   R 4.6.1  lme4 2.0.6  ordinal 2026.7.26
   R/fit.R acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180
   R/grr.R 004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e
   numeric  level 0.95 | identical: names=TRUE class=TRUE row_names=TRUE columns=TRUE boot=TRUE level=TRUE | n_failed new 0 old 0 ref 0 | n_singular new 9 ref 9 | warnings new [] old [] | 1.7 s
   binary   level 0.90 | identical: names=TRUE class=TRUE row_names=TRUE columns=TRUE boot=TRUE level=TRUE | n_failed new 0 old 0 ref 0 | n_singular new 5 ref 5 | warnings new [] old [] | 6.9 s
   failed   level 0.90 | identical: names=TRUE class=TRUE row_names=TRUE columns=TRUE boot=TRUE level=TRUE | n_failed new 3 old 3 ref 3 | n_singular new 5 ref 5 | warnings new [some bootstrap runs failed (3/20)] old [some bootstrap runs failed (3/20)] | 1.5 s
   zero     level 0.95 | identical: names=TRUE class=TRUE row_names=TRUE columns=TRUE boot=TRUE level=TRUE | n_failed new 0 old 0 ref 0 | n_singular new 0 ref 0 | warnings new [] old [] | 0.7 s
   ```

   Der Weg des Plans trägt: K-M1c-2 (Zählungen) und K-M1c-7 (Bytegleichheit) sind zugleich erfüllbar, ohne zusätzliche Refits oder Zufallszahlen.
2. **Wie `clmm` `control` und `...` verbindet** (zu PLAN Z. 119–129 und E4):

   ```text
   clmm merges control and ...:      control <- getCtrlArgs(control, list(...))
   control = clmm.control(2000, 4000) plus ... iter.max = 7 -> optCtrl: trace=0, iter.max=7, eval.max=4000
   direct clmm(control = ctl, iter.max = 7): stored optCtrl trace=0, iter.max=7, eval.max=4000 | convergence 1 | iteration limit reached without convergence (10)
   ```

3. **Seed-Regel des Plans** (Z. 188–196): `data_seed = 20261102 + 2·(j − 1) + 14·(r − 1)`, `boot_seed = data_seed + 1`.

   ```text
   seeds for 7 scenarios x 100000 repetitions: 1400000 unique: 1400000 max: 21661101 integer.max: 2147483647 | largest n_sim without overflow: 151944467 | first seeds S-boot-1, S-boot-7: 20261102 20261114
   prefix property (rep 1-2 of S-boot-7 independent of n_sim and selection): TRUE
   ```

4. **BACKLOG gegen den Plan** (Z. 371–465):

   ```text
   BACKLOG rows 109 unique 109 | plan open 77 unique 77 | plan done 32 | overlap 0 | missing  | extra
   plan-done entries without strike-through or 'erledigt' in BACKLOG:
   plan-open entries struck through in BACKLOG (measure column starts with ~~): BL-91
   ```

   BL-91 ist richtig als offen geführt: Gestrichen ist nur der Builder-Teil, offen bleibt der Reviewer-Teil (Permutationsanker).
5. **Geplante BUILD-Pfade gegen das Territorium** (`orchestrate.sh`, `path_allowed`; `config.env:200`). `BUILD.md` ist ein Gegenbeispiel, kein Planinhalt.

   ```text
   BUILDER_EXTRA_PATHS_REGEX: ^(R/|man/|tests/testthat/|vignettes/|inst/|data/|data-raw/|DESCRIPTION$|NAMESPACE$|NEWS\.md$|\.Rbuildignore$)
   R/grr.R                                             allowed
   R/fit.R                                             allowed
   man/msa_boot.Rd                                     allowed
   man/msa_grr.Rd                                      allowed
   man/msa_fit.Rd                                      allowed
   inst/templates/validation_report.Rmd                allowed
   inst/validation/sim/boot_coverage.R                 allowed
   inst/validation/sim/boot_coverage_helpers.R         allowed
   inst/validation/sim/README.md                       allowed
   inst/validation/sim/boot_coverage_check_results.csv allowed
   vignettes/validation.Rmd                            allowed
   tests/testthat/test-boot.R                          allowed
   NEWS.md                                             allowed
   PROGRESS.md                                         allowed
   orchestrator/handoff/M1c/REVIEW-INPUT.md            allowed
   orchestrator/handoff/M1c/MUT-EQUIV.json             allowed
   orchestrator/handoff/M1c/BUILD.md                   NOT allowed
   ```

6. **Referenzzählungen in einem frischen Prozess**, nur so gerechnet wie `acc_m1c_2_counts()` in `test-m1c-2-boot-failed-singular.R`:

   ```text
   failed   nsim 20 seed 303 | failed 3 | singular among finite 5 of 17 | singular rows 1,6,10,18,20 | quantiles changed without singular: grr_pct_study_var,grr_pct_contribution,repeatability_pct_study_var,reproducibility_pct_study_var,icc_items
   binary   nsim 20 seed 202 | failed 0 | singular among finite 5 of 20 | singular rows 2,6,7,15,19 | quantiles changed without singular: grr_pct_study_var,grr_pct_contribution,repeatability_pct_study_var,reproducibility_pct_study_var,icc_items
   numeric  nsim 20 seed 101 | failed 0 | singular among finite 9 of 20 | singular rows 2,3,5,7,8,15,16,19,20 | quantiles changed without singular: grr_pct_study_var,grr_pct_contribution,repeatability_pct_study_var,reproducibility_pct_study_var,ndc,icc_items
   zero     nsim 20 seed 404 | failed 0 | singular among finite 0 of 20 | singular rows  | quantiles changed without singular:
   ```

   `CRITERIA.json` nannte „in der binären 2 von 20“ (ACC-1 (4)) und „3 und 7“ (ACC-2 (3)). Die Tests zählen zur Laufzeit; ihre Bedingungen gelten auch so (0 < 5 < 17; 5 ist weder 3 noch 20 noch 90; ohne die singulären Wiederholungen ändern sich Quantile). Die Statuszeilen sind berichtigt, damit eine richtige Umsetzung mit 5 nicht als Fehler gelesen wird.
7. **Letzter Mutationsbericht** (`reports/mutation/mutation.json`, Gate-Lauf M1b Runde 7; `state/mut-baseline` = 94.09):

   ```text
   R/fit.R 1210 Killed 1055 RuntimeError 34 Survived 93 Timeout 28
   R/grr.R 246 Killed 223 RuntimeError 17 Survived 6
     grr survivors lines: 99,128,99,79,87,99
     grr mutants in lines 166-199 (msa_boot/print.msa_boot): 63 survived 0
     grr mutants in lines 109-131 (print.msa_grr): 38 survived 1
   ```

   Ohne Freigaben: 1306 erkannt, 99 überlebt, Score 92,95. Die Schwelle 92,09 hält bei gleicher Zahl erkannter Mutanten bis 112 Überlebende, also eine Reserve von 13.

## Antworten auf die Einwand-IDs

Runde 1: Es gibt noch keine Einwand-IDs. Die offenen Punkte aus `CRITERIA.json` behandelt der Plan so:

| ID | Inhalt | PLAN | Urteil |
| --- | --- | --- | --- |
| ACC-1 | Prüfform K-M1c-1, Suchmuster | Z. 38, 83–89, 103–106, 476 | übernommen; ADR-042 Nr. 1 |
| ACC-2 | Prüfform K-M1c-2 | Z. 91–115, 477 | übernommen; Weg nachgeprüft (Prüfläufe 1 und 6); ADR-042 Nr. 2 und 18.2 |
| ACC-3 | Aufruf und Laden von `boot_coverage` | Z. 178–186, 214, 513–520 | übernommen; ADR-042 Nr. 3 |
| ACC-4 | Datenerzeugung und Verfahren | Z. 147–176, 198–200 | übernommen; ADR-042 Nr. 4 |
| ACC-5 | Ergebnisdatei | Z. 249–264 | übernommen; dazu E5; ADR-042 Nr. 5 |
| ACC-6 | Replikatdatei | Z. 218–247 | übernommen; ADR-042 Nr. 6 |
| ACC-7 | Reproduktion, Präfix, Teilmengen | Z. 188–207, 479 | übernommen; Seed-Regel geprüft (Prüflauf 3); ADR-042 Nr. 7 und 18.1 |
| ACC-8 | Session-Datei und Laufzeit | Z. 200–203, 266–268, 479 | übernommen; ADR-042 Nr. 8 |
| ACC-9 | S-boot-2 bis S-boot-6 | Z. 309–313, 478, 516 | übernommen; ADR-042 Nr. 9 |
| ACC-10 | `?msa_boot` | Z. 288–289, 478 | übernommen; ADR-042 Nr. 10 |
| ACC-11 | Prüfform K-M1c-5 | Z. 277–292, 480 | übernommen; dazu E6; ADR-042 Nr. 11 |
| ACC-12 | Konfiguration mutfull | Z. 350–369, 481 | richtig gelesen; dazu E2; ADR-042 Nr. 12 |
| ACC-13 | Prüfform K-M1c-7, Bytegleichheit | Z. 107–110, 133–143, 482, 530–536 | übernommen; Bytegleichheit des Wegs nachgeprüft (Prüflauf 1); ADR-042 Nr. 13 |
| ACC-14 | [INFRA] Testauswahl des Mutationslaufs | Z. 355–362 | umgesetzt (`config.env:267`) |
| ACC-15 | Reviewer-ADR und Anker | Z. 41–43 | erledigt: ADR-042 Nr. 1 bis 17 |
| ACC-16, ACC-22 | Testläufe vor der Implementierung | – | zur Kenntnis; zwei Messwerte berichtigt (Prüflauf 6) |
| ACC-17 | Ort von `msa_boot()` | Z. 39–40 | übernommen; ADR-042 Nr. 18.3; Betreiberhinweis 3 |
| ACC-18 | Prüfform K-M1c-8 | Z. 119–131, 483 | übernommen; dazu E4; ADR-042 Nr. 14 |
| ACC-19 | `?msa_fit` | Z. 126–129, 483 | übernommen; ADR-042 Nr. 15 |
| ACC-20 | Kurzläufe der Studien aus M1b | Z. 60, 266–273, 314–318, 483 | übernommen; ADR-042 Nr. 16 |
| ACC-21 | Zuordnung Kriterium → Gate | Z. 422 (BL-48) | Betreiber; weiter offen (Betreiberhinweis 2) |

## Einwände (Runde 1)

- [E1] (minor) `orchestrator/orchestrate.sh`, `path_allowed` (builder in `40-build`: `PROGRESS.md`, `docs/decisions/*`, `orchestrator/handoff/M1c/REVIEW-INPUT.md`, `REWORK-NOTES.md`, `MUT-EQUIV.json`, dazu `BUILDER_EXTRA_PATHS_REGEX`, `config.env:200`); AGENTS.md, Betreiber („verwirft einen verletzenden Versuch“) — **Befund:** PLAN Z. 64 nennt einen „zugewiesenen BUILD-Handoff unter `orchestrator/handoff/M1c/`“ ohne Dateinamen.
  - Im Handoff darf BUILD nur `REVIEW-INPUT.md` und `MUT-EQUIV.json` schreiben, ein Rework zusätzlich `REWORK-NOTES.md`.
  - Jede andere Datei dort ist eine Territoriumsverletzung; der Orchestrator verwirft den ganzen Versuch (Prüflauf 5).

  — **Vorschlag:** BUILD-Nachweise in `PROGRESS.md` und `orchestrator/handoff/M1c/REVIEW-INPUT.md`, Äquivalenzanträge nur in `MUT-EQUIV.json`. Proben und Zwischenstände außerhalb des Arbeitsbaums oder vor dem Ende der Phase gelöscht.
- [E2] (minor) Gate mutgate (`orchestrator/gates.d/86-mutgate.sh`: verlangt max(Floor, Baseline − `MUT_RATCHET_TOL`), Freigaben nur aus `orchestrator/handoff/M1c/MUT-EQUIV-APPROVED.json`); `orchestrator/state/mut-baseline` (94.09); `config.env:229–232`; ADR-035 Nr. 1 b; BL-85; BL-102 — **Befund:** PLAN Z. 363–369 nennt die verlangten 92,09, aber nicht die Reserve.
  - Der letzte Bericht erreicht 94,09 nur mit den 15 Freigaben aus M1b; ohne sie 92,95 (Prüflauf 7).
  - Für M1c gibt es noch keine Freigabedatei, und alte Schlüssel treffen nach jeder Zeilenverschiebung andere Mutanten (BL-85).
  - Runde 1 startet damit mit einer Reserve von etwa 13 Überlebenden. Neue Zweige in `msa_boot()`, `print.msa_boot()`, `print.msa_grr()` und im ordinalen Zweig von `msa_fit()` können sie aufbrauchen; ein rotes Gate ist blocking (ADR-035 Nr. 1 b).

  — **Vorschlag:**
  1. Für jeden neuen Zweig ein Unit-Test, der ihn unterscheidet:
     - Kennzeichen abgetrennt; eine endliche singuläre Zeile zählt, eine nicht endliche nicht; `Inf` neben `NA`;
     - beide Druckzeilen bei 0 und bei mehr als 0;
     - `control` fehlt, `list()`, partielle Liste, `Hess = TRUE` ohne `control`;
     - Hinweis je Typ an genau der Stelle.
  2. Vor der Übergabe ein Teil-Mutationslauf mit dem Adapter über die geänderten Funktionen; Ergebnis mit Befehl in `PROGRESS.md`.
  3. Äquivalente in `MUT-EQUIV.json` beantragen, gebunden an die endgültigen Zeilen mit `muttest::muttest_plan()` und dem Schlüssel des Gates, mit Spalte und Quellzeile: die in M1b freigegebenen Mutanten, soweit sie noch bestehen, und die beiden aus BL-89 (ADR-039). Der Reviewer entscheidet im Code-Review einzeln; keine Freigabe aus M1b gilt von selbst.
- [E3] (minor) docs/01 §4 („zusätzliche Attribute; geänderte Druckausgabe“ ohne ADR); K-M1c-2 („`print.msa_boot` nennt beide Zahlen“); IMPLEMENTATION-RULES, Fehler und Typen („Fehler werden nicht stumm geschluckt“) — **Befund:** Objekte von `msa_boot()` aus v0.1.0 bis M1b tragen kein `n_singular`, ebenso das synthetische Objekt in `tests/testthat/test-grr-rework.R:140–160`.
  - Der Plan sagt „immer zwei getrennte Zeilen“ (Z. 111), lässt diesen Fall aber offen. `sprintf("%d", NULL)` ergibt `character(0)`; die Zeile verschwände still.
  - `NEWS.md` fehlt in der Dateiliste, obwohl sich für Nutzer sichtbar ändern: Druckausgabe und Attribut des Bootstraps, Hinweis bei latenten Fits, Vorgabesteuerung ordinaler Fits (ADR-041).

  — **Vorschlag:** Fehlt `n_singular`, sagt die zweite Zeile, dass die Zahl nicht erfasst ist, etwa „singular replicates: not recorded for this object“, ohne Wort für Verwerfen; dazu ein Unit-Test. `NEWS.md` erhält Einträge zu den drei Änderungen, die Limits mit Verweis auf `?msa_fit`.
- [E4] (minor) K-M1c-8 („mit `control` gilt genau die Angabe des Aufrufs“; „`?msa_fit` nennt beide Limits und dass eine eigene `control`-Angabe sie ersetzt“); ACC-18 (4); ADR-042 Nr. 14.6 — **Befund:** `ordinal::clmm` stellt Optionen des Optimierers aus `...` vor `control` (Prüflauf 2).
  - Ein Aufruf `msa_fit(type = "ordinal", iter.max = 7)` ohne `control` erhält nach dem Plan die Vorgabesteuerung und endet mit `iter.max = 7, eval.max = 4000`.
  - Das ist spec-konform, denn ohne das Argument `control` ruft `msa_fit()` `clmm` mit der Vorgabe auf. Der geplante Rd-Satz (Z. 128–129) nennt aber nur `control`; ein Leser erwartet beide Limits ersetzt.

  — **Vorschlag:** ein Satz in `?msa_fit`, etwa „Optimizer options given directly in `...`, such as `iter.max`, take precedence over the corresponding default limit, as in `ordinal::clmm()`.“, und ein Unit-Test mit `iter.max` in `...`. Keine eigene Mischregel im Code.
- [E5] (minor) docs/01 §8 (Ergebnisdatei mit `seed`); ADR-023 Nr. 1.4; ADR-042 Nr. 5.1 und 5.4 bis 5.6 (weitere Spalten zulässig); K-M1d-7 — **Befund:** Der Plan legt nicht fest, welcher Seed in der Spalte `seed` steht (Z. 249–250), und weist nicht aus, über wie viele Wiederholungen eine Kennzahl gerechnet ist.
  - Überdeckung und Breite zählen nur Wiederholungen mit endlichen Grenzen, die Anteile nur Wiederholungen mit Bootstrap (Z. 259).
  - Ohne Zähler ist im Vollauf eine Überdeckung über 970 von 1000 Wiederholungen nicht von einer über 1000 zu unterscheiden. M1b weist dafür `n_finite` und `n_failed` je Zeile aus (`sim_summarize()`), und `validation.Rmd` erklärt beide.

  — **Vorschlag:** `seed` = `data_seed` der Wiederholung 1 des Szenarios (wie `sim_seed(s, 1L)` in M1b); Regel und Start-Seeds von Daten und Bootstrap in der Session-Datei. Je Ergebniszeile `n_finite` (verwendete Wiederholungen) und `n_failed` wie in M1b. Ein späteres Nachrüsten verlangte einen neuen Vollauf (BL-12).
- [E6] (minor) ACC-11 (6) („Eine Prüfung der Ergebnisdatei in der Vignette (Schema, Wertebereiche, alle sieben Szenarien, n_sim) ist zulässig, die Attrappe besteht sie“); ADR-042 Nr. 11.6; `tests/acceptance/test-m1c-5-vignette-full-results.R:21–37, 50–56` — **Befund:** Der Plan prüft im Ergebnisleser „Schema, eindeutige Schlüssel, Pflichtmaße, Zahlenbereiche und Szenarien“ (Z. 281–284), ohne die Grenzen dieser Prüfung zu nennen.
  - Die Attrappe kopiert für S-boot-2 bis S-boot-6 den Seed von S-boot-1, verschiebt nicht beschränkte Maße um 0,5 + j und setzt `n_sim` = 1234.
  - Daneben liegen Replikat- und Session-Datei des Kurzlaufs (nur S-boot-1 und S-boot-7, `n_sim` 20).
  - Eine Prüfung der Seeds gegen die Seed-Regel, ein Abgleich mit Replikat- oder Session-Datei oder Bereichsgrenzen für Bias, Breite oder MCSE ließen den Knit an der Attrappe scheitern.

  — **Vorschlag:** Wertebereiche nur für Anteile ([0, 1]), MCSE (≥ 0, endlich), `n_sim` (ganzzahlig, für eine Vollauf-Datei ≥ ANK-06) und die Endlichkeit der Werte; Seeds nur als Zahl. Replikat- und Session-Datei liest die Vignette nicht.

## Prüfung nach Gesichtspunkten

### Spec-Treue

- **K-M1c-1:** Der Plan bleibt beim Refit-Pfad von `lme4::bootMer()` mit Typ-7-Quantilen und unveränderter Reihenfolge der sechs Kennzahlen (Z. 83–89, 103–106). Unter `R/` kommen keine Fork-Aufrufe hinzu (Z. 204–205).
- **K-M1c-2:** Die Definitionen von `n_failed` und `n_singular` (Z. 98–102) decken sich mit ACC-2 und der Zählung des Tests. Quantile behalten singuläre Werte; zwei Druckzeilen ohne „singular“ neben einem Wort für Verwerfen (Z. 111–115). Formelsammlung §12 Nr. 5 ist damit erfüllt.
- **K-M1c-3:** Alle sieben Szenarien mit den Werten der Tabelle in docs/02 (Z. 154–167), alle Schätzziele und Kennzahlen nach ACC-5, Kurzlauf S-boot-1 und S-boot-7, Verweis in `?msa_boot` (Z. 288–289).
- **K-M1c-4:** Neulauf, Präfix- und Teilmengenstabilität über feste Seeds je Szenario-ID und Wiederholung (Prüflauf 3); Session nach `llmsa-class-b-v1`; Laufzeit mit höchstens ANK-TOL.sim_runtime.cores Prozessen. Die Messung der Abnahme (105 s Kurzlauf, 118 s Neulauf, ACC-16) liegt weit unter 20 Minuten.
- **K-M1c-5:** Abschnittstitel wörtlich, Dateiwahl über `system.file()`, `n_sim` aus der Datei, keine Simulation beim Knit (Z. 277–292). Grenzen der Dateiprüfung: E6.
- **K-M1c-6:** Gate mutfull mit Wiederverwendung des Berichts nach ADR-041 Nr. 5 (Z. 365–368). Reserve von mutgate: E2.
- **K-M1c-7:** Der Hinweis wörtlich aus docs/02 (Z. 135) in Druckausgabe, Bericht (Block unmittelbar unter der Zeile mit Repeatability und Reproducibility) und `?msa_grr`; nicht bei numerischen Fits. `table`, `summary`, `verdict` und der Bootstrap bleiben bytegleich (Prüflauf 1). Die Lage in der Druckausgabe ist frei (ADR-042 Nr. 13.2).
- **K-M1c-8:** Vorgabe nur ohne das Argument `control`, auch mit anderen Engine-Argumenten; jede eigene Angabe einschließlich `list()` gilt unverändert (Z. 119–124). wine bleibt gleich dem direkten Aufruf, weil die Fits unter dem alten Limit enden (ACC-18 (5)). Alle neun Kurzlaufdateien aus M1b werden mit dem endgültigen Code neu erzeugt (Z. 60, 314–318), ohne den Hash abzuschalten (Z. 270–273). Rd-Satz: E4.

### Architektur und Verträge

- **Schnittstellen:** Keine neuen Argumente, Exporte oder Vorgaben in den Formals (Z. 76–81); ANK-02 bleibt unberührt. `n_singular` ist ein zusätzliches Attribut, die Druckausgaben ändern sich; beides ist ohne ADR zulässig (docs/01 §4). Altobjekte: E3.
- **Bootstrap:** Das Singularitätskennzeichen läuft durch die `FUN` und wird abgetrennt (Z. 91–96). Das ist der einzige Weg ohne zweite Refit-Runde, funktioniert mit `parallel = "snow"` und hält `attr(, "boot")` bytegleich (Prüflauf 1). Festgehalten in ADR-042 Nr. 18.2.
- **Ordinale Steuerung:** Eine Stelle vor dem einzigen `clmm`-Aufruf (`R/fit.R:374`). `acmg_fit()` ruft `msa_fit()` ohne `control` (`R/acmg.R:932`) und erhält die neuen Limits, wie ADR-041 Nr. 3 es vorsieht. Die Abnahmetests von K-M2-6 vergleichen mit `msa_fit()` selbst (`test-m2-6-evaluate.R:101–107`) und bleiben gültig.
- **Studie:** eigener Einstieg und eigene Helfer (Z. 56–57); `simulation_helpers.R` und die Skripte aus M1b bleiben, so ändert sich der M1b-Hash nur über `msa_fit()`. Wahre Werte unabhängig vom Paketcode (Z. 150–152, 232–234). Anker über die vorhandenen, hashgeprüften Kopien (Z. 183–186), keine Literale aus dem Modellgedächtnis.
- **Parallelisierung:** `mclapply` nur unter `inst/validation/sim/`, äußere Wiederholungen, innerer Bootstrap sequentiell, Windows sequentiell (Z. 200–205); docs/01 §5 eingehalten.
- **Territorien:** Alle BUILD-Pfade liegen im Builder-Territorium (Prüflauf 5); keine Änderung unter `tests/acceptance/`, `reference/`, `orchestrator/` außer den zugewiesenen Handoffs (E1).
- **Golden-Daten:** `inst/extdata/` und `reference/anchors/` bleiben unberührt (Z. 69–70).

### Vollständigkeit

- **Dateiliste:** deckt K-M1c-1 bis K-M1c-8 ab, dazu Hilfe, Vorlage, README, PROGRESS und Unit-Tests. Es fehlt `NEWS.md` (E3).
- **Offene Punkte:** ACC-1 bis ACC-22 sind beantwortet (Tabelle oben). Alle 109 BACKLOG-Einträge sind zugeordnet, 77 offene mit Behandlung oder begründeter Vertagung, 32 erledigte (Prüflauf 4).
- **Reihenfolge:** Endgültige Kurzläufe erst nach der letzten Änderung an gehashten Funktionen, mit dem installierten Paket (Z. 314–318); Bytegleichheit lokal ohne Git gegen die ANK-33-geprüften Dateien, der offizielle Test nur im Gate (Z. 530–536). Das ist richtig: Ein Test, der `git cat-file` aufruft, wäre ein Git-Kommando des Builders.

### Risiken

- **Genannt mit Gegenmaßnahme** (Z. 338–348): RNG und Rundung, Nichtkonvergenz und Hashes, Laufzeit, Unterdeckung als Befund, fehlende Daten, numerische Grenzen, Sandbox-Infrastruktur, alte Freigaben, Rollback.
- **Ergänzt:** Mutationsreserve ohne Freigaben (E2); Altobjekte ohne `n_singular` (E3); Optionen in `...` (E4); Zähler und Seed der Ergebnisdatei (E5); Dateiprüfung der Vignette gegen die Attrappe (E6). Zu Diagnosespalten und Laufzeit der Unit-Tests siehe die Hinweise für BUILD.

### Gate-Abdeckung

- **deps:** keine neuen Imports; `digest` und `parallel` stehen schon in Suggests.
- **lint:** `R CMD check` baut `validation.Rmd` öffentlich; der neue Abschnitt liest nur die Ergebnisdatei (K-M1c-5, Bauanteil).
- **tests:** alle Abnahmetests einschließlich der Skriptläufe von K-M1c-3, K-M1c-4 und K-M1c-8 und der Bytegleichheit mit `done/M1b`.
- **trace:** Jede Testdatei von M1c nennt ihre K-ID; `CRITERIA.json` ändert sich nur in `open`, nicht in `criteria`.
- **mutgate:** Scope `R/fit.R` und `R/grr.R`, verlangt 92,09 (E2); die langen Skriptläufe sind ausgenommen (ACC-14).
- **mutfull:** mindestens ANK-32 (80) über beide Dateien, Bericht von mutgate bei gleichem Schlüssel (ADR-041 Nr. 5).
- **golden-adr:** keine Golden- oder Ankeränderung geplant.
- **territory:** Diese Phase schreibt `PLAN-REVIEW.md`, `verdict-plan.json` und `CRITERIA.json` (nur Statuszeilen) im Handoff sowie `docs/decisions/ADR-042-m1c-reviewer-auslegungen.md` (`orchestrate.sh`, `path_allowed`, `reviewer:30-plan-review`).

## Hinweise für BUILD

- **Vertrag:** `PLAN.md` (Runde 1) mit ADR-042 Nr. 1 bis 18; E1 bis E6 berücksichtigen.
- **Zählungen:** Die Referenz der Abnahme zählt im Fehlerlauf 3 nicht endliche und 5 singuläre Wiederholungen, binär 5 singuläre von 20 (Prüflauf 6). Eine Umsetzung, die das trifft, ist richtig, auch wenn ältere Notizen andere Zahlen nannten.
- **Diagnosespalten:** Der Vergleich mit dem Kurzlauf umfasst alle Spalten (ADR-042 Nr. 7.1), und der Neulauf im Gate wie der Vollauf des Betreibers können anders auf Worker verteilen. Meldungen, die R oder ein Paket nur einmal je Sitzung ausgibt, gehören nicht in Replikatspalten; Namensräume vor dem Fork laden, wie `sim_main()` es tut. Die geplante Prüfung der Workerunabhängigkeit (Z. 479) mit 1 und 2 Workern auf bytegleiche Replikate.
- **Laufzeit der Unit-Tests:** `tests/testthat/` läuft in `R CMD check` und je Mutant in mutgate und mutfull. Dort keine Skriptläufe der Studie und keine Bootstraps mit der Vorgabe 200; kleine `nsim` auf kleinen Fits genügen für Zählung und Druck.
- **Vollauf in Teilen:** ADR-042 Nr. 7.2 rechnet damit, dass der Betreiber szenarioweise rechnet. Eine Zusammenführung wie `sim_merge()` oder eine Anleitung im README spart ihm Handarbeit an der längsten Studie (BL-12).
- **BL-87:** nur Dokumentation in `R/fit.R`; jede Änderung am numerischen Pfad änderte das Verhalten von M1a, den Hash der Studien und den Mutationsumfang (Z. 53, 307–308).
- **Code-Review M1c:** prüft ADR-042 als Vertrag, die Freigaben einzeln gegen den neuen Bericht (BL-85) und die Kurzläufe gegen den Code, der in die Gates geht.
