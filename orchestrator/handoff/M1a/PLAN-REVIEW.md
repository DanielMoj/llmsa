# PLAN-REVIEW — M1a, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 · Stand: 28.10.2026 · Gegenstand: `orchestrator/handoff/M1a/PLAN.md` (Runde 1). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Neu in dieser Phase ist `docs/decisions/ADR-017-m1a-reviewer-auslegungen.md`. Es enthält die geschuldeten Auslegungen zu ACC-3, ACC-4, ACC-9, ACC-10 und ACC-18 sowie die Entscheidungen zu zwei Punkten, die der Plan vorlegt: Nullfall σ²_TV = 0 und Bau der Vignette außerhalb des Repos.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- **Spezifikation:**
  - `docs/02-statistikkern.md`, Abschnitt M1a (K-M1a-1 bis K-M1a-7);
  - Folgekriterien, soweit `validation.Rmd` und `msa_boot()` betroffen sind (K-M1b-7, K-M1c-1, K-M1c-5, K-M1d-7);
  - `docs/01-fachspezifikation.md` §1 bis §9;
  - Formelsammlung §2 und §3 (`reference/privat/07_Formelsammlung_llmsa.md`);
  - ADR-012 und ADR-016.
- **Handoff:** `CRITERIA.json` (K-M1a-1 bis K-M1a-7, ACC-1 bis ACC-18), `PLAN.md`.
- **Abnahmetests:** `setup-acceptance.R`, `setup-m1a.R`, `test-m1a-1` bis `test-m1a-7`, alle vollständig.
- **Anker:** ANK-10, ANK-13, ANK-14, ANK-16, ANK-TOL.
- **Produktcode:**
  - `R/fit.R` und `R/grr.R` vollständig;
  - `R/acmg.R` (`acmg_capture_fit()`, `acmg_fit()`) und `R/plan.R` (`msa_plan()`);
  - `DESCRIPTION`, `.Rbuildignore`, Kopf von `vignettes/llmsa.Rmd`.
- **Harness:**
  - `orchestrator/verifier.sh` (Export von `REPO_ROOT`) und `orchestrate.sh` (`path_allowed`);
  - `gates.d/20-lint.sh`, `30-tests.sh`, `86-mutgate.sh`, `87-golden-adr.sh`;
  - `lib/r-check.sh`, `lib/r-mutation.R`, `lib/r-tests.R`;
  - `config.env`: Territorien, `TEST_CMD`, `LINT_CMD`, `MUT_*`, `GOLDEN_PATH_REGEX`.
- **Weitere:** `BACKLOG.md` (75 IDs, 57 offen), `PROGRESS.md` (Ende: M2, Runde 3).

## Eigene Nachprüfung

Die Prüfungen liefen ohne Git-Kommando, nur mit lesenden Aufrufen `Rscript --vanilla` aus der Repo-Wurzel (R 4.6.1, lme4 2.0.6). Danach waren im Arbeitsbaum nur die vom Orchestrator geschriebenen Dateien neuer als `PLAN.md` (`STATUS.md`, `orchestrator/state/…`). Geschrieben habe ich ausschließlich die drei Dateien dieser Phase.

1. **Invarianz bei konditioniertem Fit (Planpunkte 1 und 3, ACC-6).**

   Aufbau der Messung:
   - **Modell:** wie `msa_fit()`, also `y ~ 1 + (1|item) + (1|prompt) + (1|model) + (1|block) + (1|item:prompt) + (1|item:model) + (1|prompt:model)`.
   - **Konditionierung:** Antwort mit Mittelwert und Standardabweichung standardisiert, Komponenten zurücktransformiert.
   - **Messgröße:** größte Abweichung einer Komponente vom Fit der unveränderten Daten, als Anteil von σ²_TV. Bei Skalierung zuerst durch c² geteilt.
   - **bobyqa:** `rhoend = 1e-12`, `maxfun = 1e5`.
   - **nloptwrap:** `xtol_abs = 1e-12`, `ftol_abs = 1e-14`, `xtol_rel = 1e-12`, `maxeval = 1e5`.
   - **Daten:**
     - `ic50_demo` ohne fehlende Werte (2152 Zeilen);
     - der simulierte Plan aus `test-m1a-6`: `msa_simulate(20, 4, 3, 3, 3, …, seed = 1)` mit den Komponenten aus `acc_m1a_designs()`, Variante „interactions, 3 blocks“, RNG Mersenne-Twister/Inversion/Rejection.
   - **Permutation:** Seed 20261024 bzw. Seeds 1 bis 6.

   ```text
   bobyqa_tight (conditioned): shift100=4.75e-06 scale7.5=1.85e-06 scale0.02=8.74e-06 permute=8.49e-06 [3 s]
   nlopt_tight (conditioned): shift100=4.18e-08 scale7.5=6.58e-07 scale0.02=2.08e-07 permute=5.95e-07 [2 s]
   ic50_demo nloptwrap tight, conditioned: shift100=4.18e-08 shift1e4=1.72e-06 scale7.5=6.58e-07 scale0.02=2.08e-07 perm_max6=1.92e-06
   sim nloptwrap tight, conditioned: shift100=2.12e-06 shift1e4=3.32e-06 scale7.5=1.01e-06 scale0.02=1.15e-06 perm_max6=2.58e-06
   ```

   `ANK-TOL.invariance` = 1e-6 · σ²_TV. Nach der Konditionierung gleichen verschobene und skalierte Daten den Originaldaten nur bis auf Rundung. Den Endpunkt bestimmt dann die Rauschgrenze des ableitungsfreien Optimierers auf der flachen REML-Fläche. Das ist eine Messung des Reviewers, keine Abnahme (→ E1).

2. **Geschlossene Einweglösung und konsistentes `merMod` (Planpunkt 4, K-M1a-4).**
   - **Mittelquadrate:** aus Daten, die um den ersten Wert verschoben sind.
   - **Modell:** `merMod` über `lFormula()`, `mkLmerDevfun()` und `mkMerMod()`, ausgewertet am θ der geschlossenen Lösung auf den Originaldaten.
   - **Messgröße:** relative Abweichung vom zertifizierten Wert aus ANK-14, je Zeile Rest und Item.

   ```text
   AtmWtAg : closed form rel.err 1.2e-11 6.2e-11 | merMod(original scale) rel.err 2.5e-11 5e-11
   SiRstv : closed form rel.err 7.6e-14 4.8e-13 | merMod(original scale) rel.err 1.4e-13 4.2e-13
   SmLs03 : closed form rel.err 5.2e-16 5.2e-16 | merMod(original scale) rel.err 1.3e-13 1.3e-13
   SmLs06 : closed form rel.err 5.2e-11 1.2e-10 | merMod(original scale) rel.err 5.1e-11 1.2e-10
   ```

   Der Weg trägt K-M1a-4 mit großem Abstand: 1e-8 relativ bei niedriger Schwierigkeit, die LRE-Regel bei mittlerer. `vc` und Modell kommen dabei aus einer Quelle (→ E3).
3. **`refit()` übernimmt die Steuerung des Modells.** In `lme4:::refit.merMod`:
   - deparse-Zeilen 29–33: `obj.control <- object@optinfo$control` wird zu `ctrl.arg$optCtrl`;
   - deparse-Zeilen 125–130: `optimizer <- object@optinfo$optimizer`, danach `optwrap(optimizer, …)`.

   Exportiert sind `lFormula`, `mkLmerDevfun`, `optimizeLmer`, `mkMerMod`, `checkConv`, `refit` und `isSingular` (→ E3, E8).
4. **Bau der Vignette.** In `tools:::.build_packages` (R 4.6.1) läuft der Bau in drei Schritten:
   - `R CMD build` kopiert den Quellbaum vollständig (`cp -LR`, Zeile 842);
   - es baut die Vignetten in `prepare_pkg()` (Zeile 857);
   - erst danach entfernt es die `.Rbuildignore`-Pfade (Zeilen 863–884).

   `R CMD check` baut aus dem Tarball neu, dort ohne `reference/`. `orchestrator/verifier.sh:31` exportiert `REPO_ROOT` an jedes Gate (→ ADR-017 Nr. 7, E10).
5. **Konvertierung in `msa_fit()`** (`R/fit.R:70`). `x - as.numeric(as.character(x))` für 1/3, 0.1 + 0.2 und e:

   ```text
   [1]  3.330669e-16  5.551115e-17 -4.884981e-15
   ```

   (→ E6)
6. **Mutanten heute.** `muttest::muttest_plan()` mit den neun Mutatoren aus `r-mutation.R`: `R/fit.R` 240, `R/grr.R` 211 (→ E12).
7. **Territorium.** Die Zielpfade des Plans liegen bis auf eine Ausnahme im Builder-Territorium. Geprüft wurden `orchestrate.sh:492–499` und `BUILDER_EXTRA_PATHS_REGEX` (`config.env:138`):
   - erlaubt: `R/`, `man/`, `tests/testthat/`, `vignettes/`, `inst/`, `data-raw/`, `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `PROGRESS.md`, `docs/decisions/`, die zugewiesenen Handoffs;
   - Ausnahme: `README.md` (→ E2).

## Bewertung

### Spec-Treue

**Trägt:**
- **Schnittstellen:** Argumente, Positionen und Vorgaben bleiben (ANK-02, docs/01 §4). Das Feld `numerics` ist additiv und ohne ADR zulässig.
- **Abhängigkeiten:** Die Imports bleiben unverändert. VCA und SixSigma kommen unter Suggests (docs/01 §5, ACC-15).
- **Toleranzen:** Sie kommen nur aus Ankern, werden nicht verändert und mit `[[ ]]` und Abbruch eingelesen (BL-72).
- **Keine Ergebnisrundung:** Der Plan rundet nicht auf Ankerwerte.
- **Geschlossene Einweglösung:**
  - Sie ist ein allgemeines Verfahren für eine Klasse von Plänen, kein Erkennen von Testwerten (AGENTS.md, Integrität Nr. 2).
  - Formelsammlung §2: Bei balancierten Plänen mit nichtnegativen ANOVA-Schätzern ist REML = ANOVA; im Randfall gilt σ̂²_e = SST/(N − 1).
  - Bedingung: Die Voraussetzungen werden strukturell geprüft, wie der Plan zusagt.
- **K-M1a-1:** Die explizite Steuerung bleibt wirksam. Damit prüft K-M1a-1 weiter das REML von lme4 (siehe E4).
- **K-M1a-6:** Ein benannter Fehler bei identischen Werten ist zulässig („führen zu einer Fehlermeldung oder zu `verdict = "undetermined"`“).

**Offen:**
- Nullfall σ²_TV = 0 (K-M1a-5): entschieden durch ADR-017 Nr. 6 (E11).
- Bau der Vignette ohne `reference/` (K-M1a-7): entschieden durch ADR-017 Nr. 7 (E10).

### Architektur und Verträge

- Der Plan verlangt zu Recht ein konsistentes `merMod`: `msa_boot()` liest `fit$model`, und K-M1c-1 prüft gegen `bootMer(fit$model)`. Den Bauweg nennt er nicht. Messung 2 und 3 zeigen einen genauen und tragfähigen Weg (E3).
- Offen bleiben zwei Punkte:
  - wie sich explizite Steuerung und Konditionierung zueinander verhalten (E4);
  - ob die Ergebnisfelder ihre Bedeutung behalten (E5).
- Die Vignette rechnet beobachtete Werte im geladenen Namespace, auch in der Mutationskopie, und lädt keinen anderen Paketstand. Caches gelten nur für einen Knit-Lauf. Das trägt den Abnahmetest und den Mutationslauf.

### Vollständigkeit, Risiken, Reihenfolge

**Trägt:**
- Der kritische Pfad K-M1a-4/-6 ist richtig erkannt.
- Die Reihenfolge ist sinnvoll: erst die Numerik, dann Ressourcen und Vignette.
- Die frühe Messung mit Zusatzfällen und der Eskalationsweg nach ADR-016 E6 sind vorgesehen.

**Offen:**
- **Numerik:** Der gewählte Mechanismus ist für Verschiebung und Skalierung durch Messung 1 widerlegt (E1, blocking).
- **Datei außerhalb des Territoriums:** `README.md` würde den BUILD-Versuch verwerfen (E2, blocking).
- **Randfälle jenseits „alle Werte gleich“:** E7.
- **Laufzeit von Fit, Plan, Bootstrap und Klasse B:** E8.
- **Unit-Tests über drei Plattformen und je Mutant:** E9.
- **Laufzeit des ersten echten Mutationslaufs:** E12 [INFRA].

### Gate-Abdeckung

- **tests:** Alle sieben Kriterien haben Abnahmetests. Der Plan führt die M1a-Abnahme, `m2-6`, die Unit-Tests sowie e2e und fuzz aus.
- **lint (Bau von K-M1a-7):** Das Gate baut im Vollmodus, weil `REPO_ROOT` exportiert ist. Der öffentliche Modus wird nur im eigenen Paketcheck des Builders ohne `REPO_ROOT` geprüft, den der Plan vorsieht, und in GitHub Actions.
- **golden-adr:** Die NIST-Daten unter `inst/extdata/` brauchen ein Builder-ADR im selben Meilenstein. ADR-017 ersetzt es nicht.
- **trace und territory:** Die Kriteriums-IDs stehen in den Tests. Das Territorium ist bis auf E2 eingehalten.
- **mutgate:** Der Scope `R/fit.R`, `R/grr.R` ändert sich, deshalb gibt es den ersten echten Lauf. Der Plan verzichtet auf Auslagerung und auf Selbstgenehmigung (E12).
- **deps:** VCA 1.5.2 und SixSigma 0.11.1 sind installiert (Lesediagnose des Plans).

### Antworten auf die Acceptance-Verträge

| ACC | Festlegung im Plan | Bewertung |
| --- | --- | --- |
| ACC-1 | ADR-016 E1, ANK-13 übernommen | erledigt |
| ACC-2 | ADR-016 E2 übernommen | erledigt |
| ACC-3 | Reviewer-Lesart übernommen | erledigt; Auslegung in ADR-017 Nr. 1 |
| ACC-4 | Modellzuordnung bestätigt | erledigt; ADR-017 Nr. 2 |
| ACC-5 | ADR-016 E3 übernommen | erledigt |
| ACC-6 | konditionierter, enger Standardfit | offen: E1 (blocking) |
| ACC-7 | Untergrenze 1 auch für PV = 0 | erledigt; Nullfall nach ADR-017 Nr. 6 (E11) |
| ACC-8 | Vignette nennt die NIST-Einstufung | erledigt |
| ACC-9 | Hashes, Abbildung, LRE, Marge, vier LRE je Datensatz | erledigt; ADR-017 Nr. 3 |
| ACC-10 | Tabellenvertrag und Toleranzen bestätigt | erledigt; ADR-017 Nr. 4 |
| ACC-11 | Pläne, Vorbedingungen, beide Steuerungsaufrufe bestätigt | erledigt; Hinweis E4 |
| ACC-12 | konstruierte Komponenten, Grenzfälle bestätigt | erledigt; E11 |
| ACC-13 | Randfälle bestätigt | erledigt; Hinweise E4, E7 |
| ACC-14 | Vertrag bestätigt; öffentlicher Bau zur Prüfung vorgelegt | entschieden in ADR-017 Nr. 7; E10 |
| ACC-15 | Suggests, Laufzeit messen | erledigt; E8, E12 |
| ACC-16 | gelesen | zur Kenntnis |
| ACC-17 | historischer Ausgangsstand | zur Kenntnis |
| ACC-18 | Paketvorgaben für Penicillin | erledigt; ADR-017 Nr. 5 |

### Backlog

Der Plan ordnet alle 57 offenen IDs einzeln zu, und die 18 erledigten führt er als erledigt. Die Zuordnungen sind schlüssig. Querbezüge:

- BL-49 und BL-72 gehen in E1 auf, BL-13 in E8 und E12.
- BL-46 wird durch E9 und E10 eingegrenzt.
- BL-23 deckt der Plan.

Keine Zuordnung verlangt einen Einwand.

## Einwände

- [E1] (blocking) K-M1a-6 („Permutation der Zeilen, Umbenennen der Stufen aller Faktoren und Verschieben aller Werte um eine Konstante lassen Varianzkomponenten (Toleranz `ankerRef: ANK-TOL.invariance` als Anteil von σ²_TV) … unverändert; Skalieren mit c multipliziert alle Varianzen mit c² …“, `docs/02-statistikkern.md:15`); ANK-TOL.invariance (1e-6 · σ²_TV); ADR-016 E6; ACC-6; PLAN.md, „Numerische Entscheidung“, Punkte 1 bis 4

  **Befund:**
  - Planpunkt 2 macht Permutation und Umbenennung bitgleich. Verschiebung und Skalierung gleichen nach Planpunkt 1 nur bis auf Rundung. Den Endpunkt bestimmt dann die Rauschgrenze des ableitungsfreien Optimierers auf der flachen REML-Fläche.
  - Messung 1 zeigt das in drei Fällen:
    - Mit Konditionierung und „enger bobyqa-Steuerung“ (`rhoend` 1e-12) weicht `ic50_demo` um 4,75e-6 (Verschiebung um 100), 1,85e-6 (Skalierung mit 7,5) und 8,74e-6 (Skalierung mit 0,02) ab.
    - Auch enges nloptwrap verfehlt den simulierten Plan aus `test-m1a-6`: 2,12e-6, 1,01e-6 und 1,15e-6.
    - Ebenso `ic50_demo` bei Verschiebung um 1e4: 1,72e-6.
  - Der Plan enthält keinen Schritt, der das Optimum unter diese Grenze legt. Die geschlossene Lösung (Punkt 4) deckt nur den balancierten Einfaktorfall. Die Risikotabelle behandelt das Problem als Frage der Optimierersteuerung. So geschrieben führt der Plan absehbar in die Eskalation nach E6 statt zur Erfüllung.

  **Vorschlag:**
  - **Mechanismus:** PLAN-UPDATE ersetzt Punkt 3 durch einen Mechanismus, den der Builder nach E6 wählt. Er bestimmt im Vorgabepfad das REML-Optimum unabhängig von Rundungsunterschieden der Eingabe, und zwar für alle Pläne, nicht nur für die Testdaten. Tragfähig wären etwa:
    - (a) für balancierte Pläne, deren ANOVA-Schätzer alle ≥ 0 sind: die exakte Lösung über die erwarteten Mittelquadrate (Formelsammlung §2: dort ist REML = ANOVA), also die geplante Einweglösung, verallgemeinert auf das Modell von `msa_fit()`;
    - (b) für alle übrigen Pläne (`ic50_demo` ist unbalanciert): ein abschließender Schritt mit analytischen Ableitungen des REML-Kriteriums auf dem konditionierten Problem, mit Score und Information, Abbruch über die Score-Norm und Komponenten an der Grenze 0 als aktiver Menge; oder ein gleichwertiges, dokumentiertes Verfahren.
  - **Optimierer:** Ihn bestimmt die Messung; die Festlegung auf bobyqa entfällt.
  - **Go/No-Go vor Reihenfolge-Schritt 4:** Gemessen werden `ic50_demo` und der simulierte Plan mit den vier Transformationen des Abnahmetests. Dazu kommen mindestens Verschiebung um 1e4, Skalierungen über mehrere Größenordnungen, negative Skalierung und weitere Seeds. Kriterium ist `ANK-TOL.invariance`; die Messwerte stehen in PROGRESS und im numerischen ADR.
  - **Explizite Steuerung:** Sie bleibt der lme4-Pfad (E4). So prüft K-M1a-1 weiter das REML von lme4.
  - **Imports:** Neue Imports, etwa Matrix, nur mit ADR (AGENTS.md, Projektspezifika).
  - **Eskalation:** Bleibt die Invarianz nach belegtem Versuch unerreichbar, gilt der Weg aus ADR-016 E6.

- [E2] (blocking) Gate territory; `orchestrator/orchestrate.sh:492–499` (`path_allowed`, Builder in `40-build`, `60-rework`, `62-rebuild`); `orchestrator/config.env:138` (`BUILDER_EXTRA_PATHS_REGEX` ohne `README.md`); AGENTS.md, Betreiber („Der Orchestrator erzwingt die Territorien nach jeder Modellphase per Git-Diff und verwirft einen verletzenden Versuch“)

  **Befund:** Die Dateitabelle von PLAN.md plant Änderungen an `README.md`. Der Pfad steht weder in den Grundpfaden des Builders noch in `BUILDER_EXTRA_PATHS_REGEX`. Ein BUILD, der ihn ändert, wird in der Territoriumsprüfung verworfen; ein zweiter Verstoß endet FATAL.

  **Vorschlag:**
  - `README.md` aus dem Plan streichen.
  - Die Ausführung der Validierung dokumentieren in `man/`, `NEWS.md`, der Vignette oder einer `README.md` unter `inst/validation/numeric/`. Alles das ist Builder-Territorium.
  - Eine Erweiterung der Regex wäre eine Betreiberentscheidung, kein Teil des BUILD.

- [E3] (minor) PLAN.md, „Öffentliche API und Ergebnisobjekte“ („Der zurückgegebene `model` muss ein konsistentes lme4-`merMod` bleiben …“); K-M1a-4; K-M1c-1 (`msa_boot()` gegen `bootMer(fit$model)`); `refit.merMod` in lme4 2.0.6 (Messung 3)

  **Befund:**
  - Die Konsistenz ist richtig gefordert, aber nicht konstruiert.
  - Offen bleibt, ob die Einweglösung der Endwert oder nur ein Startwert ist („Initialisierung beziehungsweise Nachpolitur“). Ein Optimierer, der am exakten Optimum startet, kann es wieder verlassen (Messung 1).
  - `refit()` und damit `bootMer()` und `msa_boot()` übernehmen Optimierer und `optCtrl` aus `fit$model@optinfo`.

  **Vorschlag:** PLAN-UPDATE legt fest:
  - **Bau des Modells:** Das zurückgegebene `merMod` entsteht auf den Originaldaten am endgültigen θ. Originaldaten heißt Originalskala, Originalbeschriftungen und Eingabereihenfolge nach Entfernen fehlender Werte. Der Bau läuft über die exportierten modularen Funktionen von lme4: `lFormula`, `mkLmerDevfun`, `mkMerMod`, für Meldungen `checkConv`.
  - **Eine Quelle:** `vc` wird aus diesem Modell gelesen (`VarCorr`), nicht getrennt gerechnet. Messung 2 belegt den Weg für NIST: höchstens 1,2e-10 relativ, bei einer Grenze von 1e-8 bzw. der LRE-Regel.
  - **Endwert:** Im geschlossenen Fall ist das endgültige θ die geschlossene Lösung.
  - **optinfo:** Es nennt einen Optimierer, den lme4 kennt, samt `optCtrl`, damit `refit()` arbeitet.
  - **Konvergenz:** Konvergenzcode und lme4-Meldungen stammen aus dem Lauf, der θ tatsächlich bestimmt hat.

- [E4] (minor) K-M1a-1 („über `...` an `msa_fit` durchgereicht“); K-M1a-6 („ein nicht konvergierender Fit gibt die lme4-Warnung weiter“); PLAN.md, Punkt 5; ACC-17 (beide auf v0.1.0 grün)

  **Befund:**
  - Punkt 5 sagt „unverändert wirksam“. Offen bleibt, ob Konditionierung, Umordnung und Nachpolitur bei expliziter Steuerung trotzdem greifen.
  - Der Plan will zeilenbezogene Argumente (`weights`, `offset`, `subset`) durch interne Umordnungen tragen. Das ist eine zusätzliche Fehlerfläche ohne Kriterium.

  **Vorschlag:**
  - Ist `control` oder ein anderes lme4-Argument in `...` gesetzt, fittet `msa_fit()` genau `lme4::lmer(form, data, REML = TRUE, ...)` auf den Originaldaten, ohne Konditionierung, Umordnung oder Nachpolitur. Das steht in `?msa_fit`.
  - So behalten der Durchreichtest (K-M1a-1) und der Nichtkonvergenztest (K-M1a-6) ihr Verhalten von v0.1.0, und zeilenbezogene Argumente müssen nicht mitgeführt werden.
  - Eine Abweichung davon begründet der Plan mit Tests.

- [E5] (minor) docs/01 §4 („Ohne ADR erlaubt: … zusätzliche Felder in Rückgabeobjekten …“; „Nur mit ADR und Übergangsfrist: … Entfernen oder Umbenennen von Rückgabefeldern …“); PLAN.md („`data` erhält die analysierten Werte und ihre Zuordnung zu den Eingabezeilen“)

  **Befund:** Die interne kanonische Darstellung darf nicht ins Ergebnis durchschlagen. Der Plan lässt offen, ob `fit$data`, der Modellrahmen und die Namen in `ranef()` und `coef()` die Originalbeschriftungen und die Eingabereihenfolge tragen.

  **Vorschlag:** PLAN-UPDATE sagt zu:
  - `fit$data` behält die Spalten `item`, `prompt`, `model`, `block` und `y` mit Originalbeschriftungen, Originalskala und Eingabereihenfolge nach Entfernen fehlender Werte.
  - Die Zuordnung zu den Eingabezeilen steht nur in einer zusätzlichen Spalte oder in `numerics`.
  - `formula`, `levels`, `n`, `interactions` und `derived` behalten ihre Bedeutung.
  - Die Stufennamen von `fit$model` sind die Originalbeschriftungen; kanonische Codes bleiben intern.

- [E6] (minor) `R/fit.R:70`; docs/01 §2 Nr. 4 („nie stillschweigend eine falsche Zahl“); Messung 5

  **Befund:** `msa_fit()` wandelt numerische Werte über `as.numeric(as.character(…))` um. R 4.6.1 behält dabei 15 signifikante Stellen; der gemessene Verlust beträgt bis zu 4,9e-15 relativ. Der Plan behandelt die Konditionierung, nicht aber diese Umwandlung.

  **Vorschlag:**
  - Numerische oder ganzzahlige `value` direkt übernehmen.
  - Nur Zeichen- oder Faktoreingaben parsen.
  - Die Warnung für nicht lesbare Werte bleibt.
  - Unit-Test mit Doubles in voller Genauigkeit.

- [E7] (minor) docs/01 §2 Nr. 4 („Randfälle sind Pflicht: … identische Antworten … Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung“); K-M1a-6; `R/acmg.R:950–951` (numerischer Rückfall); `R/plan.R:84`

  **Befund:** Der Plan deckt „alle Werte gleich“ mit einem frühen Fehler. Offen sind drei Fälle:
  - identische Replikate bei unterschiedlichen Zellen: Rest 0, typisch bei Temperatur 0;
  - nahezu konstante Daten: Maßstab der Konditionierung nahe 0;
  - die Wirkung des neuen Fehlers auf Aufrufer: `acmg_fit()` bricht mit „AP1 numeric fallback failed: …“ ab, `msa_plan()` ist ebenfalls betroffen.

  **Vorschlag:** PLAN-UPDATE legt das Verhalten fest:
  - jeweils ein benannter englischer Fehler oder ein richtiges Ergebnis, nie `NaN` oder eine stille falsche Zahl, belegt durch Unit-Tests;
  - der Maßstab der Konditionierung wird robust gewählt; bei 0 folgt ein benannter Fehler;
  - `NEWS.md` nennt die Verhaltensänderung bei konstanten Werten;
  - ein Regressionstest zu M2 deckt den numerischen Rückfall mit konstanten Scores.

- [E8] (minor) BL-12; BL-13; PLAN.md, „Risiken“ (Laufzeit); Messung 3 (`refit()` übernimmt `optCtrl`)

  **Befund:** Engere Vorgaben, Nachpolitur und Neuaufbau des Modells verteuern jeden numerischen Fit. Das vervielfachen:
  - `msa_plan()` mit `nsim` Fits je Szenario;
  - `msa_boot()`, dessen Refits die Steuerung aus `fit$model` übernehmen;
  - die Klasse-B-Studien in M1b und M1c; `boot_coverage` ist schon jetzt der längste Lauf (BL-12).

  **Vorschlag:**
  - Die Fitdauer messen, v0.1.0 gegen neu, für `ic50_demo`, einen NIST-Satz mit 18.009 Zeilen und je ein kleines Beispiel für `msa_plan()` und `msa_boot()`.
  - Die Werte im numerischen ADR und in PROGRESS nennen.
  - Festlegen, welche Steuerung `fit$model` für Bootstrap-Refits trägt, und warum.

- [E9] (minor) docs/01 §2 Nr. 8; ADR-012 Nr. 1; BL-72; `orchestrator/config.env:170` (`MUT_TEST_DIRS` mit `tests/testthat`)

  **Befund:**
  - Die geplanten Unit-Tests (`test-fit-numeric.R`, `test-validation-numeric.R` mit „die beiden Vignettenkontexte prüfen“) laufen in `R CMD check`, auf drei CI-Plattformen und in jedem Mutanten.
  - Ein vollständiges Knitten oder `remlVCA` auf `ic50_demo` (rund 13 s, ACC-15) verlängern dort Check und Mutationslauf.
  - Invarianztests mit 1e-6 sind plattformempfindlich (BL-72). Messung 1 zeigt Abstände unter Faktor 2.

  **Vorschlag:**
  - `tests/testthat/` prüft die Hilfsfunktionen der Vignette an kleinen Eingaben, ohne vollständiges Knitten und ohne VCA-Aufruf auf `ic50_demo`.
  - REML-Vergleiche folgen dort ADR-012 Nr. 1: `invariance` nur, wo die Steuerung es messbar erreicht, sonst `reml_anova`.
  - Toleranzen kommen aus installierten Ressourcen, gelesen über `[[ ]]` mit Prüfung auf `NULL` (BL-72).

- [E10] (minor) K-M1a-7; ACC-14; ADR-017 Nr. 7; AGENTS.md, Integrität Nr. 7

  **Befund:** Der Entwurf mit zwei Kontexten ist zulässig (ADR-017 Nr. 7). Im Plan fehlen drei Punkte:
  - die Driftwache im Test-Gate (Nr. 7.3);
  - der ausdrückliche Ausschluss von AIAG-Rohwerten in allen Modi (Nr. 7.4);
  - die Literalregel für Dateien, die die Vignette einliest oder ausführt, etwa `inst/validation/numeric/reference_checks.R` (Nr. 7.6).

  **Vorschlag:**
  - PLAN-UPDATE bestätigt ADR-017 Nr. 7.1 bis 7.6 oder erklärt den reduzierten öffentlichen Modus (Nr. 7.7).
  - Hinweis: Das lint-Gate baut im Vollmodus (`verifier.sh:31` exportiert `REPO_ROOT`). Den öffentlichen Modus prüfen nur der eigene Paketcheck ohne `REPO_ROOT` und GitHub Actions.

- [E11] (minor) K-M1a-5 („der Fall σ²_GRR = 0 liefert `ndc = Inf` und `verdict = "acceptable"`, der Fall σ²_TV = 0 liefert `verdict = "undetermined"` ohne Fehler“); K-M1a-6 („nie zu `NaN` in `summary`“); ADR-017 Nr. 6; `R/fit.R:188`; `R/grr.R:105–106`

  **Befund:** Der GRR-Vertrag des Plans entspricht ADR-017 Nr. 6. Zwei Druckstellen fehlen:
  - `print.msa_fit` rechnet die Spalte `pct` als `variance / sum(variance)`; bei einem konstruierten Fit mit allen Komponenten 0 ergibt das `NaN`.
  - `print.msa_grr` druckt für jedes nicht endliche ndc „Inf“, also auch für `NA`.

  **Vorschlag:**
  - Nach ADR-017 Nr. 6 umsetzen, beide Druckmethoden eingeschlossen.
  - Unit-Tests für drei Fälle, jeweils mit Druckausgabe:
    - GRR = 0 bei PV > 0;
    - PV = 0 bei GRR > 0, ndc 1;
    - TV = 0: `NA`, kein `NaN`, `undetermined`.
  - `msa_boot()` zählt Wiederholungen mit `NA` weiter in `n_failed`.

- [E12] (minor) [INFRA] Gate mutgate (`orchestrator/gates.d/86-mutgate.sh`; `orchestrator/lib/r-mutation.R:93–103`); `orchestrator/config.env:165–170` (`MUT_SCOPE_REGEX`, `MUT_WORKERS`, `MUT_TEST_DIRS`); BL-13; Messung 6

  **Befund:**
  - M1a ändert `R/fit.R` und `R/grr.R`, deshalb läuft mutgate erstmals wirklich. Schon heute sind es 451 Mutanten; mit dem Plan werden es mehr.
  - Jeder Mutant führt alle vier Testordner aus. Darin stecken alle Abnahmetests, M2 allein rund 930 bis 946 s je Lauf (BL-13), und das Knitten von `validation.Rmd`.
  - Das ergibt rund 16 bis 17 min je Mutant. Bei 14 Workern dauern 451 Mutanten etwa 9 h, dazu kommt bei Unterschreitung ein Flake-Rerun.
  - Das liegt außerhalb des Builder-Territoriums.

  **Vorschlag:**
  - Der Betreiber entscheidet vor den Gates von M1a, etwa über eine Testauswahl je Meilenstein oder Zeitgrenzen.
  - Für den Builder nonblocking: den Kern schlank halten, nichts aus dem Mutationsumfang auslagern (wie geplant), keine Äquivalenz-Claims ohne Reviewer-Approval.
  - Der Reviewer trägt den Punkt im nächsten Code-Review in `BACKLOG.md` ein.

## Verdict

**REWORK.**

- Blocking sind E1 (Mechanismus der Invarianz, K-M1a-6) und E2 (`README.md` außerhalb des Builder-Territoriums). E3 bis E12 sind minor; E12 ist [INFRA] und an den Betreiber gerichtet.
- ADR-017 hält die Auslegungen zu ACC-3, ACC-4, ACC-9, ACC-10 und ACC-18 fest und entscheidet den Nullfall (Nr. 6) und den Bau der Vignette außerhalb des Repos (Nr. 7).
- Ein wörtlicher Spec-Widerspruch liegt nicht vor.
  - Die Überschneidung der Nullfälle in K-M1a-5 löst die speziellere Regel (ADR-017 Nr. 6).
  - Die Invarianz ist nach Messung nicht unerreichbar, nur mit dem geplanten Mechanismus nicht erreicht.
- PLAN-UPDATE beantwortet E1 bis E12 einzeln mit `akzeptiert: <Änderung>` oder `abgelehnt: <wörtliches Spec-Zitat mit Fundstelle>` (SCHEMA). Runde 2 ist die letzte Planrunde (`MAX_ROUNDS_PLAN=2`).
