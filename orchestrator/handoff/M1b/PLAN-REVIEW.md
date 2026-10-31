# PLAN-REVIEW — M1b, Runde 2

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 2 (von `MAX_ROUNDS_PLAN=2`, letzte Planrunde) · Stand: 31.10.2026 · Gegenstand: `orchestrator/handoff/M1b/PLAN.md` (Runde 1) mit `PLAN-UPDATE.md` (Runde 2). Bindend: `ARBITER.md` (Verdict RESOLVE zu E1). Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Es gibt keinen blocking-Befund.

- **E1:** PLAN-UPDATE übernimmt die Direktive aus ARBITER.md Nr. 1 bis 6 vollständig (Tabelle unten). Nach Direktive Nr. 6 prüft dieses Review zu E1 nur die Übernahme; neue Einwände derselben Sache gibt es nicht.
- **E2 bis E8:** Alle sind mit `akzeptiert:` und der verlangten Änderung beantwortet. E7 und E8 hat der Betreiber umgesetzt (Prüflauf 7).
- **Weitere Pflichten:** ADR-023 Nr. 10.9 und Nr. 13 sind bestätigt. ACC-1 bis ACC-18 und alle 66 offenen BACKLOG-Einträge sind adressiert (Prüflauf 6).
- **Technische Zusagen nachgeprüft:** Konvergenzregel je Fitpfad, Optimiererwahl von `clmm` und numerische Enddiagnose (Prüfläufe 1 bis 3). Sie tragen.
- **Neu in dieser Runde:** drei minor-Befunde, E9 bis E11; E10 ist [INFRA].
- **Neu in dieser Phase:** `docs/decisions/ADR-025-m1b-reviewer-auslegungen-runde-2.md`.
  - Es hält ACC-18 fest und ersetzt ADR-023 Nr. 11.4 und 11.7.
  - Es präzisiert ADR-023 Nr. 10.9 für numerische Fits und den tatsächlich verwendeten `clmm`-Optimierer.
  - Es richtet das Rückfallorakel der Abnahmetests zu K-M2-6 und K-M2-7 an ADR-006 Nr. 4.2 aus.
  - In `CRITERIA.json` verweisen die Statuszeilen von ACC-10, ACC-11 und ACC-18 darauf. Kriterien und alle übrigen Felder sind unverändert.

### Hinweis an den Betreiber (E10)

- **Folge:** Nach einem spec-treuen BUILD wird das tests-Gate in K-M2-6 und K-M2-7 rot, ohne Fehler des Builders.
- **Ursache:** Das Abnahmeorakel `acc_m2_with_conditions()` (`tests/acceptance/setup-m2.R:714`) wertet jede Warnung des ordinalen Fits als Rückfallauslöser. K-M2-6, ANK-68 und ADR-006 Nr. 4.2 nennen nur Fehler und Konvergenzwarnungen.
  - Bisher war das folgenlos.
  - Ab M1b verlangen K-M1b-4 und K-M1b-6 auf den AP1-Daten Warnungen, die keine Konvergenzwarnungen sind. Die Daten haben zwei Blöcke und fehlende Antworten (Prüfläufe 4 und 5).
- **Betroffen:** `test-m2-6-evaluate.R` Z. 87, 93 und 164 sowie `test-m2-7-robustness-pilot.R` Z. 211.
- **Zuständigkeit:** Der Reviewer darf `tests/acceptance/` erst in `50-code-review` schreiben (`orchestrate.sh:488`, `:490`). Dort kostet die Anpassung eine Rework-Runde, weil PASS `gates.result=pass` verlangt.
- **Empfehlung:** Anpassung nach ADR-025 Nr. 4 vor den Gates von M1b, etwa durch eine wiederholte Abnahmephase wie in ADR-024 Nr. 2.

### Ablauf

Mit PASS gibt der Orchestrator den Plan frei, setzt den Tag `plan/M1b` und startet BUILD (`orchestrate.sh:926`, `:940–943`).

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, die Prompts `30-plan-review.md` und `50-code-review.md`.
- **Spezifikation:**
  - docs/02: M1b vollständig (Szenariotabelle, Schätzziele, K-M1b-1 bis K-M1b-7);
  - docs/01 vollständig;
  - docs/03: K-M2-6 (Z. 19) und der Hauptplan (Z. 67).
- **Handoff M1b:**
  - `ARBITER-REQUEST.md`, `ARBITER.md`, `verdict-arbiter.json`;
  - `PLAN-REVIEW.md` und `verdict-plan.json` der Runde 1;
  - `CRITERIA.json` (sieben Kriterien, ACC-1 bis ACC-18);
  - `PLAN.md` (661 Zeilen) und `PLAN-UPDATE.md` (630 Zeilen), beide vollständig;
  - `orchestrator/ESCALATION-M1b.md`.
- **ADRs:** ADR-006 Nr. 4, ADR-021, ADR-023, ADR-024.
- **Abnahmetests:**
  - `setup-acceptance.R`, `setup-m1b.R`;
  - `test-m1b-4-two-levels.R`, `test-m1b-5-binary-rptr.R`, `test-m1b-6-edge-cases.R`, `test-m1b-7-vignette.R`, `test-m1b-7-vignette-full-results.R`;
  - `setup-m2.R` (Mock-Lauf, Orakel, `acc_m2_check_model()`), `test-m2-6-evaluate.R`, `test-m2-7-robustness-pilot.R` Z. 205–234;
  - Durchsicht von `tests/e2e/` und `tests/fuzz/` auf ordinale Fits: Beide ersetzen `msa_fit()` durch eine Attrappe und sind nicht betroffen.
- **Anker:** ANK-68 (`fallback_fit`).
- **Produktcode:** `R/fit.R` vollständig, `R/acmg.R:905–957`.
- **Harness:**
  - `orchestrate.sh`: `path_allowed`, `ownership_check`, `verdict`, `arbiter`, `park`, Planschleife;
  - `config.env` Z. 143, 178 und 189–204.
- **Engines:** Quelltext von `ordinal::clmm`, `clmm.fit.env`, `clmm.fit.ssr`, `clmm.control`; `lme4::checkConv`, `lme4::nloptwrap`, `lme4:::optwrap`.

## Eigene Prüfläufe

- **Aufrufe:** am 31.10.2026 mit `Rscript --vanilla -e …` aus der Repo-Wurzel, das Paket bei Bedarf über `pkgload::load_all()`.
- **Abnahmehelfer:** per `sys.source()` aus `tests/acceptance/setup-*.R` geladen, mit `REPO_ROOT` über `Sys.setenv()`.
- **Versionen:** R 4.6.1, lme4 2.0.6, ordinal 2026.7.26.
- **Arbeitsbaum:** Keine Datei wurde dort geschrieben. Die Prüfung mit `find -newer STATUS.md` zeigt nur die Orchestrator-Logs dieser Phase.
- **Output:** Gezeigt ist der echte Output.

1. **Optimiererwahl von `clmm`.** Auszug aus dem echten Output: die einschlägigen Zeilen aus `deparse()` von `ordinal::clmm` und `clmm.fit.env` sowie zwei Einträge von `formals(clmm.control)`; Leerzeilen und übrige Steuerparameter weggelassen.

   ```text
   ordinal 2026.7.26  lme4 2.0.6
   29     use.ssr <- (retrms$ssr && !control$useMatrix)
   62         clmm.fit.ssr(rho, control = control$optCtrl, method = control$method,
   64     else clmm.fit.env(rho, control = control$optCtrl, method = control$method,
   ====  clmm.fit.env
   5     if (method == "ucminf")
   6         warning("cannot use ucminf optimizer for this model, using nlminb instead")
   $method
   c("nlminb", "ucminf", "model.frame")
   $useMatrix
   [1] FALSE
   ```

   Den angeforderten Optimierer nutzt `clmm` also nur bei einem einfachen Zufallsterm ohne `useMatrix`; sonst rechnet es immer mit nlminb. Das deckt die Aussage in PLAN-UPDATE Z. 165.
2. **Enddiagnose numerischer Fits.** Gefittet wurden:
   - `ic50_demo` auf dem Vorgabepfad;
   - ein Plan mit wahrer Prompt- und Modellvarianz null (8 Items × 3 × 3 × 2, Seed 5), einmal auf dem Vorgabepfad;
   - derselbe Plan zweimal auf dem Durchreichweg: mit `control = lme4::lmerControl()` und mit `lmerControl(optCtrl = list(maxeval = 3))`.

   Auszug aus drei Läufen, Zeilen unverändert.

   ```text
   ic50_demo default            method=analytic_reml  opt=0 lme4.class=list msgs=[] singular=FALSE
   zero prompt/model (default)  method=analytic_reml  opt=0 lme4.class=list msgs=[boundary (singular) fit: see help('isSingular')] singular=TRUE
   lmer passthrough: optimizer=nloptwrap opt=0 msgs=[boundary (singular) fit: see help('isSingular')] optinfo$warnings=[]
     emitted=[]
   lmer passthrough: optimizer=nloptwrap opt=5 msgs=[unable to evaluate scaled gradient | Model failed to converge: degenerate  Hessian with 5 negative eigenvalues
     See ?lme4::convergence and ?lme4::troubleshooting.] optinfo$warnings=[]
     emitted=[convergence code 5 from nloptwrap: NLOPT_MAXEVAL_REACHED: Optimization stopped because maxeval (above) was reached. | unable to evaluate scaled gradient | Model failed to converge: degenerate  Hessian with 5 negative eigenvalues
     See ?lme4::convergence and ?lme4::troubleshooting.]
   8         conv = if (status < 0 || status == 5) status else 0,
   [1] "bobyqa"      "Nelder_Mead"
   ```

   Die vorletzte Zeile stammt aus `lme4::nloptwrap`, die letzte ist `glmerControl()$optimizer`. Die Regel „Erfolgscode 0 und keine Meldung außer der Randmeldung“ (PLAN-UPDATE Z. 166–168) ergibt also TRUE für reguläre Fits und Randfits und FALSE für den Abbruch, auf beiden numerischen Wegen.
3. **glmer-Fall von K-M1b-6:** `acc_m1b_binary_runs(seed = 69L, items = 20L)`, direkter `glmer` mit `glmerControl(optCtrl = list(maxfun = 10))`.

   ```text
   conv$opt = 4
   recorded lme4 messages:
   [1] "Model failed to converge with max|grad| = 0.172332 (tol = 0.002, component 1)\n  See ?lme4::convergence and ?lme4::troubleshooting."
   emitted warnings:
   [1] "maxfun < 10 * length(par)^2 is not recommended."
   [2] "convergence code 1 from bobyqa: bobyqa -- maximum number of function evaluations exceeded"
   [3] "failure to converge in 10 evaluations"
   [4] "convergence code 4 from Nelder_Mead: failure to converge in 10 evaluations"
   [5] "Model failed to converge with max|grad| = 0.172332 (tol = 0.002, component 1)\n  See ?lme4::convergence and ?lme4::troubleshooting."
   emitted messages:
   character(0)
   ```

4. **K-M2-6 auf dem heutigen Stand.** Ausgewertet wurden der Mock-Lauf aus `acc_m2_evaluation()`, der ordinale Fit je Modell und der gemeinsame Fit mit `acc_m2_with_conditions()`, dazu dasselbe für die konstruierten Läufe aus `test-m2-6-evaluate.R` Z. 165–197. Auszug aus drei Läufen, Zeilen unverändert.

   ```text
   evaluation in 132 s
   rows 5400  NA values 96
   block
      1    2
   2700 2700
   prompt
   concise    json    role
      1800    1800    1800
   model
   llama  qwen   sol
    1800  1800  1800
   rep
      1    2    3
   1800 1800 1800
   model sol  : NA=30 | today: failed=FALSE derived=[block] formula=y ~ 1 + block + (1 | item) + (1 | prompt) warnings=[] | AP1 fallback=FALSE type=ordinal converge-code=0
   model llama: NA=36 | today: failed=FALSE derived=[block] formula=y ~ 1 + block + (1 | item) + (1 | prompt) warnings=[] | AP1 fallback=FALSE type=ordinal converge-code=0
   model qwen : NA=30 | today: failed=FALSE derived=[block] formula=y ~ 1 + block + (1 | item) + (1 | prompt) warnings=[] | AP1 fallback=FALSE type=ordinal converge-code=0
   joint     : NA=96 | today: failed=FALSE derived=[block] warnings=[] | AP1 joint type=ordinal
   AP1 trigger on planned warnings: FALSE FALSE
   constructed sol  : NA=100 failed=FALSE derived=[block] warnings=[] | AP1 fallback=FALSE type=ordinal
   constructed llama: NA=100 failed=FALSE derived=[block] warnings=[] | AP1 fallback=FALSE type=ordinal
   constructed qwen : NA=100 failed=FALSE derived=[block] warnings=[] | AP1 fallback=FALSE type=ordinal
   ```

   „AP1 trigger on planned warnings“ wendet `acmg_convergence_warning()` auf zwei Texte an:
   - den Range-Warnungstext aus PLAN-UPDATE Z. 190–194;
   - einen Platzhalter „32 missing response(s) were dropped.“, denn der Wortlaut der Verwerfungswarnung ist nicht festgelegt.
5. **Gegenprobe mit den geplanten Warnungen.** Eine Attrappe ersetzte `msa_fit()` nur im Prozess über `testthat::local_mocked_bindings(.package = "llmsa")`.
   - Für ordinale Fits gab sie vor dem echten Fit die Verwerfungswarnung aus, wenn Antworten fehlten.
   - Danach gab sie die Range-Warnung nach PLAN-UPDATE aus, wenn `derived` nicht leer war.
   - Alles andere reichte sie unverändert an das Original durch.

   ```text
   with planned warnings, sol  : test helper failed=TRUE -> test expects fallback=TRUE type=numeric | AP1 gives fallback=FALSE type=ordinal reason=[]
   with planned warnings, llama: test helper failed=TRUE -> test expects fallback=TRUE type=numeric | AP1 gives fallback=FALSE type=ordinal reason=[]
   with planned warnings, qwen : test helper failed=TRUE -> test expects fallback=TRUE type=numeric | AP1 gives fallback=FALSE type=ordinal reason=[]
   joint: test expects type=numeric | AP1 joint type=ordinal
   ```

6. **Vollständigkeit von PLAN-UPDATE**, gegen `BACKLOG.md`, `CRITERIA.json` und docs/02. Die letzte Spalte prüft das Zitat gegen docs/02 und die Zeile im Testplan.

   ```text
   BACKLOG rows 89  unique 89  open 66  done 23
   plan BL rows 66  missing:   extra:   identical order: TRUE
   ACC in CRITERIA 18  in plan 18  identical: TRUE
   answers: - **E1 — akzeptiert: - **E2 — akzeptiert: - **E3 — akzeptiert: - **E4 — akzeptiert: - **E5 — akzeptiert: - **E6 — akzeptiert: - **E7 — akzeptiert: - **E8 — akzeptiert:
   K-M1b-1 TRUE TRUE
   K-M1b-2 TRUE TRUE
   K-M1b-3 TRUE TRUE
   K-M1b-4 TRUE TRUE
   K-M1b-5 TRUE TRUE
   K-M1b-6 TRUE TRUE
   K-M1b-7 TRUE TRUE
   ```

7. **Betreiberpunkte E7 und E8**, gelesen:
   - `config.env:202`: `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full)'`;
   - `config.env:203–204`: `MUT_TEST_TIMEOUT=353`, `MUT_TEST_TIMEOUT_FACTOR=5`;
   - `orchestrate.sh:544`: `[ "$before" != __clean__ ] || git ls-files --error-unmatch -- "$path" >/dev/null 2>&1 || OWNERSHIP_REMOVE+=("$path")`.

## Antworten auf die Einwand-IDs

### E1 gegen die Arbiter-Direktive

| Direktive | Verlangt | PLAN-UPDATE | Urteil |
| --- | --- | --- | --- |
| Nr. 1 | K-M1b-5 nach docs/02 Z. 43 | Ziel Z. 16–20; E1 Z. 37–39 | übernommen |
| Nr. 2 | Logit mit π²/3, kein Sonderfall | Z. 17–18: „ICC_items bei Logit verwendet weiterhin die latente Restvarianz π²/3“ | übernommen |
| Nr. 3 | Tests, Anker und Toleranzen nach ADR-024; der Builder ändert keine Abnahmetests | Z. 39–45, 102–103, 126–129 | übernommen |
| Nr. 4 | E1 mit `akzeptiert:` | Z. 37 | erfüllt |
| Nr. 4 | PLAN.md Z. 16–25, 330–333, 369–392, 398 und 408 sind erledigt | Z. 40–45, wörtlich diese Stellen, dazu der Schlusssatz nach der ACC-Tabelle | erfüllt |
| Nr. 4 | Testplanzeile K-M1b-5 mit (i) und (ii) | Z. 498 enthält (i) mit `expect = "liability"`, performance auf direktem `glmer` und `fit$model`, Nachrechnung mit ANK-28 und live_tol sowie (ii) mit Vorgabeaufruf, beiden Punktschätzern aus ANK-25 und vignette_tol; dazu „Kein Vergleich ICC_items gegen ANK-25“ | erfüllt |
| Nr. 4 | Vignettentabelle: ANK-25 nur als Installationsprüfung | Z. 298–310: zwei getrennte Prüfungen; „Diese Werte sind ausdrücklich keine Referenzwerte für ICC_items.“ | erfüllt; die Darstellung bindet ADR-025 Nr. 1.4 |
| Nr. 5 | S-bin mit π²/3; K-M1b-7 im Wortlaut | ADR-023 Nr. 13 übernommen (Z. 88–96); Szenarien unverändert | erfüllt |
| Nr. 6 | keine Erfüllungsbehauptung | Z. 19–20: „eine Erfüllung des Kriteriums wird damit noch nicht behauptet“ | erfüllt |

### E2 bis E8, ADR-023 und ACC

| ID | Verlangt (Runde 1) | Antwort in PLAN-UPDATE | Urteil |
| --- | --- | --- | --- |
| E2 | Regel nach ADR-023 Nr. 10.9, Regel für numerische Fits, drei Unit-Tests | Z. 46–51; Tabelle je Fitpfad Z. 160–176; Unit-Tests Z. 504–515 (ucminf mit einem Term, nlminb bei mehreren Termen und `useMatrix`, singulärer `glmer`, Limitabbruch, seltene Codes synthetisch, numerischer Teil) | richtig; Engine-Fakten nachgeprüft (Prüfläufe 1 bis 3); festgehalten in ADR-025 Nr. 3 |
| E3 | Labels nur mit `levels`; zwei verschiedene, nicht fehlende Werte; `levels[2]` ist das Ereignis; Invarianztest | Z. 52–57, 147–158, 516–520 | richtig |
| E4 | AIAG-Bezug nur mit fehlender Korrektur oder gestrichen; eine Druckzeile je Quelle | Z. 58–62, 188–201 | richtig. Der Warnungstext erfüllt ADR-023 Nr. 9.5 und enthält keinen AP1-Auslöser |
| E5 | Replikat- und Session-Datei vor dem Abbruch; README mit Vollauf und Zusammenführung | Z. 63–68, 254–291, 525–530 | richtig. Es geht über den Vorschlag hinaus: belegte Zielverzeichnisse werden abgewiesen, und der Zusammenführungscode ist ausführbar und mit Unit-Fällen geprüft. Das ist mit ADR-023 Nr. 1.2 verträglich und mit den Abnahmetests, die je Lauf ein frisches Verzeichnis anlegen (`setup-m1b.R:365–366`) |
| E6 | `skip_if_not_installed()` in Unit-Tests; `parallel` unter Suggests | Z. 69–74, 115, 535–538 | richtig |
| E7 | [INFRA], Betreiber | Z. 75–81 | richtig; umgesetzt (Prüflauf 7) |
| E8 | [INFRA], Betreiber | Z. 82–86 | richtig; umgesetzt (Prüflauf 7) |
| ADR-023 Nr. 10.9 und Nr. 13 | bestätigen oder mit Spec-Zitat ablehnen | Z. 46–51, 88–96 | bestätigt |
| ACC-18 | Vignette nach ACC-18; Reviewer-ADR in Runde 2 | Z. 98–103, 298–310, 319–322 | richtig; ADR-025 Nr. 1 und 2 |
| ACC-1 bis ACC-17 | — | Tabelle Z. 390–409 | richtig (Prüflauf 6) |
| BACKLOG | jeder offene Eintrag | Z. 411–486 mit 66 Zeilen | vollständig (Prüflauf 6); Vertagungen wie in Runde 1 |

## Einwände (Runde 2)

- [E9] (minor) K-M2-6 (docs/03 Z. 19: „oder, wenn dieser Fit mit Fehler oder Konvergenzwarnung endet, den numerischen Fit auf den Klassenscores als gekennzeichneten Rückfall (`ankerRef: ANK-68`)“); ADR-006 Nr. 4.2; K-M1b-4 („gibt in diesem Fall immer eine `warning()` aus“); K-M1b-6 („fehlende oder nicht in `levels` enthaltene Werte werden mit Warnung verworfen“); ADR-025 Nr. 4 — **Befund:** PLAN-UPDATE behandelt K-M2-6 als unveränderten Regressionslauf. Belege: Z. 203–207 („Regressionen prüfen den tatsächlichen Rückfallpfad; an dessen Kriterien oder Warnungsfilter in `R/acmg.R` ist keine Änderung geplant“), Reihenfolge Nr. 7 und Testplan Z. 521–524.
  - Der Plan sieht nicht vor, dass die verlangten Warnungen vier Prüfungen von K-M2-6 und K-M2-7 rot machen.
    - Der AP1-Hauptplan hat zwei Blöcke (docs/03 Z. 67), also hat jeder ordinale AP1-Fit die abgeleitete Komponente `block`.
    - Die Mock-Daten enthalten fehlende Antworten (Prüflauf 4).
    - Das Abnahmeorakel wertet jede Warnung als Rückfallauslöser, `acmg_fit()` zu Recht nicht (Prüflauf 5).
  - Ohne Festlegung droht eine Abhilfe an der falschen Stelle.
    - Ein Rückfall bei jeder Warnung machte jeden AP1-Fit numerisch und widerspräche K-M2-6 und ADR-006 Nr. 4.2.
    - Unterdrückte oder bedingte Warnungen widersprächen K-M1b-4 („immer“) und K-M1b-6.

  — **Vorschlag:**
  - Der Plan bleibt, wie er ist: keine Änderung in `R/acmg.R`; die Regressionen „Range-/Ausschlusswarnungen ohne Rückfall, echte Konvergenzwarnung mit numerischem Rückfall“ bleiben.
  - BUILD führt K-M2-6 und K-M2-7 aus. Rote Prüfungen mit genau dieser Ursache meldet der Builder mit echtem Output in `PROGRESS.md` als [INFRA] (ADR-025, Konsequenzen).
  - Jede andere Abweichung bleibt ein Befund gegen den Builder.
- [E10] (minor) [INFRA] Gate tests; `tests/acceptance/setup-m2.R:714` (`failed = inherits(value, "error") || length(warns) > 0L`), `:869–883`; `tests/acceptance/test-m2-6-evaluate.R:101–107`; K-M2-6; K-M2-7; ANK-68 (`fallback_fit.trigger`: „Fehler oder Konvergenzwarnung des ordinalen Fits“); ADR-006 Nr. 4.2; ADR-025 Nr. 4 — **Befund:** Das Abnahmeorakel weicht von K-M2-6, ANK-68 und ADR-006 Nr. 4.2 ab.
  - Bei jeder Warnung verlangen `acc_m2_check_model()` und der Test des gemeinsamen Fits den numerischen Rückfall.
  - Bis M1b war das folgenlos. Mit den verlangten Warnungen werden rot (Prüfläufe 4 und 5):
    - `test-m2-6-evaluate.R` Z. 87, je Modell, dreimal;
    - Z. 93, der gemeinsame Fit;
    - Z. 164, die konstruierten Läufe, dreimal;
    - `test-m2-7-robustness-pilot.R` Z. 211, dreimal.
  - Die Ursache liegt außerhalb des Builder-Territoriums. `30-plan-review` darf `tests/acceptance/` nicht schreiben (`orchestrate.sh:488`).

  — **Vorschlag:**
  - Der Reviewer passt das Orakel nach ADR-025 Nr. 4 an: eine vom Produktcode unabhängige Auslöserregel nach ADR-006 Nr. 4.2. Bei Warnungen ohne Auslöser wird der ordinale Fit erwartet; alle übrigen Erwartungen bleiben.
  - Am besten geschieht das vor den Gates von M1b. Der Betreiber entscheidet über eine wiederholte Abnahmephase für M1b; ihr Pfad `tests/acceptance/*` ist freigegeben (`orchestrate.sh:486`), Vorbild ist ADR-024 Nr. 2.
  - Sonst geschieht es in `50-code-review` Runde 1 und kostet eine Rework-Runde („PASS nur bei gates.result=pass“).
  - Den BACKLOG-Eintrag schreibt der Reviewer in `50-code-review`.
- [E11] (minor) K-M1b-7 („Tabellen je Szenario mit Bias, EmpSE, MCSE“); ADR-023 Nr. 11.5 (CRITERIA ACC-11 (4)); `tests/acceptance/setup-m1b.R:566–583` (`acc_m1b_shows`: „at least two significant digits written and within one unit of the last written digit“) — **Befund:** PLAN-UPDATE legt fest, welche Werte die Vignette zeigt (Z. 312–317), aber nicht, mit welcher Genauigkeit.
  - Eine feste Zahl von Dezimalstellen, etwa `knitr::kable(digits = 3)`, zeigt kleine Werte mit weniger als zwei signifikanten Stellen, als „0.000“ oder „0.004“. Das betrifft kleine Bias-Werte und das MCSE von EmpSE, das bei n_check = 20 etwa EmpSE/√38 beträgt.
  - Solche Zahlen zählt der Test nicht als gezeigt, obwohl der Wert richtig gelesen wurde.
  - ACC-16 nennt bereits die doppelte Rundung durch `kable`.

  — **Vorschlag:**
  - Ergebnis- und Vergleichswerte nach signifikanten Stellen formatieren, etwa mit `signif(x, 3)` oder `format(x, digits = 3)` vor `kable`.
  - `n_sim` als ganze Zahl zeigen.
  - Verglichen wird weiter ungerundet (Z. 310).

## Prüfung nach Gesichtspunkten

### Spec-Treue

- **Szenarien und Wahrheiten:** unverändert gegenüber Runde 1. S-two folgt ADR-023 Nr. 13.1, S-ord Nr. 13.2, S-bin Nr. 13.3. Die Wahrheiten für %GRR und ICC entsprechen `acc_m1b_truth()`.
- **K-M1b-1:** Der Fitpfad bleibt; dazu kommen nur Eingabeprüfungen und `converged`. Der Test ist heute schon grün (ACC-16).
- **K-M1b-2 und K-M1b-3:**
  - Skripte, Formate, Kennzahlen und Seed-Regel folgen ADR-023 Nr. 1 bis 8 und 13.
  - Das Abbruchprotokoll aus E5 hält ADR-023 Nr. 5.5 ein: benannter Abbruch, kein Ersatzwert.
- **K-M1b-4:**
  - Fester Effekt und β̂²/2 bestehen schon.
  - Die Warnung (PLAN-UPDATE Z. 190–194) enthält „range method“, „positive“, „bias“, „Var(“ und „?msa_fit“.
  - Je Quelle gibt es eine Druckzeile in beiden Druckmethoden.
  - Die Hilfe nennt `two_level` und die Vignette.
- **K-M1b-5:** gemäß Direktive. Der Code bleibt bei π²/3 (`R/fit.R:577`).
- **K-M1b-6:**
  - Alle acht Prüfungen aus ACC-10 sind abgedeckt, auch BL-81 und die Kodierung aus E3.
  - Der glmer-Test vergleicht jede vermerkte lme4-Meldung wörtlich, nach Normalisierung der Zahlen, mit den Warnungen (`test-m1b-6-edge-cases.R:145–149`).
  - Die geplante Regel „jede vermerkte lme4-Meldung als Warnung“ erfüllt das, wenn die Meldung ohne Präfix weitergegeben wird. Im Testfall warnt lme4 die einzige vermerkte Meldung schon selbst (Prüflauf 3).
- **K-M1b-7:**
  - Geplant sind der Abschnitt, beide K-M1b-5-Prüfungen getrennt, die Dateiwahl über `system.file()` und die Literalregel einschließlich ANK-28.
  - Zur Anzeigegenauigkeit siehe E11.

### Architektur und Verträge

- **Schnittstellen:**
  - Keine neuen Argumente, Exporte oder Vorgaben; ANK-02 bleibt unberührt.
  - `converged` und `msa_grr()$derived` sind zusätzliche Felder, und die Druckausgabe ändert sich; beides ist ohne ADR zulässig (docs/01 §4).
- **Abhängigkeiten:** keine neuen Imports. `rptR`, `performance` und `parallel` kommen unter Suggests (ACC-13, E6).
- **Konvergenz:** Die Regel je Fitpfad ist widerspruchsfrei zu ADR-023 Nr. 10.9 und zu ADR-018, ADR-020 und ADR-022.
  - Der numerische Vorgabepfad liest `opt$conv = 0L` und die checkConv-Meldungen (`R/fit.R:531–542`).
  - Startdiagnosen entscheiden nicht.
  - Festgehalten in ADR-025 Nr. 3.
- **Territorien:**
  - Alle BUILD-Pfade liegen im Builder-Territorium (`config.env:138`, `orchestrate.sh:496`).
  - Unter `tests/acceptance/`, `tests/simulation/`, `reference/` und `orchestrator/` ist außer den Handoffs nichts geplant.
- **Golden-Daten:**
  - `inst/extdata/` und `reference/anchors/` bleiben unberührt.
  - Die Ankerkopien unter `inst/validation/latent/anchors/` folgen ADR-021; der Drifttest prüft beide ANK-TOL-Kopien.
- **AP1:**
  - Keine Änderung in `R/acmg.R`. Das ist richtig (ADR-006 Nr. 4.2).
  - Die neue Nichtkonvergenzwarnung von `clmm` enthält „converge“ und löst den Rückfall aus, wie K-M2-6 es verlangt.
  - Zum Abnahmeorakel siehe E9 und E10.
- **Parallelisierung:** `mclapply` nur unter `inst/validation/sim/`; unter `R/` bleibt die Ausführung sequentiell (docs/01 §5).

### Vollständigkeit

- **Dateiliste:** Sie deckt K-M1b-1 bis K-M1b-7 ab, dazu Hilfe, NEWS, PROGRESS und das Builder-ADR. Dessen Nummer beginnt bei ADR-026.
- **Einwände und Einträge:** E1 bis E8, ACC-1 bis ACC-18 und alle 66 offenen BACKLOG-Einträge sind beantwortet (Prüflauf 6).
- **Vertagungen:** BL-84, BL-87 und BL-89 sind mit Zeitpunkt vertagt, wie in Runde 1 angenommen.
- **Verfahrensfragen:** Mit ADR-025 sind alle Reviewer-Auslegungen festgehalten, die CRITERIA.json für diese Runde ankündigt.

### Risiken

- **Genannt mit Gegenmaßnahme:** Engine-Diagnosen als Klasse (LESSONS), Laufzeit und Mutationsauswahl, lange Fehlläufe, Reproduktion bis M1d, numerische Bestandsgrenzen und Plattformen.
- **Ergänzt:**
  - E9 und E10: Abnahmeorakel von K-M2-6 und K-M2-7;
  - E11: Anzeigegenauigkeit der Vignettentabellen.

### Gate-Abdeckung

- **tests:** führt alle Abnahmetests aus. K-M2-6 und K-M2-7 bleiben rot, bis ADR-025 Nr. 4 umgesetzt ist (E10).
- **lint:** baut `validation.Rmd` öffentlich. Dafür braucht der Bau `rptR` und `performance` unter Suggests und die Ankerkopien.
- **trace:**
  - Jede Testdatei nennt ihre K-M1b-ID.
  - Den Bau aus K-M1b-7 trägt das lint-Gate (`test-m1b-7-vignette.R:10–11`).
  - `trace` liest aus `CRITERIA.json` nur `.criteria`, unverändert.
- **mutgate:**
  - Der Scope bleibt `R/fit.R` und `R/grr.R`; die Testauswahl ist gesetzt (E7).
  - `m2-[0-9]` ist ausgeschlossen; E10 berührt mutgate daher nicht.
- **golden-adr:** Unter `inst/extdata/` und `reference/anchors/` ist keine Änderung geplant.
- **territory:**
  - Diese Phase schreibt nur `PLAN-REVIEW.md`, `verdict-plan.json` und `CRITERIA.json` (nur Statuszeilen) im Handoff, dazu `docs/decisions/ADR-025-…` (`orchestrate.sh:488`).
  - BUILD siehe Architektur.

## Hinweise für BUILD

- **Vertrag:** `PLAN.md` mit den Berichtigungen aus `PLAN-UPDATE.md`; ADR-023 Nr. 1 bis 13 mit ADR-025 Nr. 1 bis 4.
- **E9 und E10:** Rote Prüfungen von K-M2-6 und K-M2-7, deren einzige Ursache das Abnahmeorakel ist, gehören mit Output als [INFRA] in `PROGRESS.md`.
  - Keine Änderung an `acmg_fit()` oder `acmg_convergence_warning()`.
  - Keine unterdrückte oder bedingte Pflichtwarnung.
- **E11:** Vignettenwerte nach signifikanten Stellen anzeigen.
- **Code-Review M1b:**
  - Als Judge prüft es ADR-025 Nr. 1.4 (Trennung von ICC_items und ANK-25) und Nr. 2.3 (Literalregel einschließlich Helfer).
  - Es setzt ADR-025 Nr. 4 um, falls der Betreiber das nicht vorher veranlasst hat.
