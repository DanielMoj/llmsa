# PLAN-REVIEW — M1a, Runde 2

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 2 (letzte Planrunde, `MAX_ROUNDS_PLAN=2`) · Stand: 28.10.2026 · Gegenstand: `orchestrator/handoff/M1a/PLAN.md` (Runde 1) mit `PLAN-UPDATE.md` (Runde 2). Eine `ARBITER.md` gibt es nicht.

Neu in dieser Phase ist `docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md`. Es legt zwei Dinge fest:
- die Auslegung von Formelsammlung §2 („REML mit `lme4::lmer`“) für den neuen Vorgabepfad;
- die Punkte, die nach dem Ende der Planrunden für BUILD und Code-Review binden.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- **Spezifikation:**
  - `docs/02-statistikkern.md`: M1a (K-M1a-1 bis K-M1a-7) sowie die Folgestellen in M1c (Szenarien S-boot, K-M1c-1, K-M1c-2) und M1d (Abbildungen, Hinweis zu `R/fit.R`);
  - `docs/01-fachspezifikation.md` §1 bis §9;
  - Formelsammlung: Kopf mit den Statusbegriffen, §1 bis §3, §12;
  - ADR-012, ADR-016, ADR-017.
- **Handoff:** `CRITERIA.json`, `PLAN.md`, `PLAN-REVIEW.md` und `verdict-plan.json` der Runde 1, `PLAN-UPDATE.md`.
- **Abnahmetests:**
  - `setup-m1a.R` (Pläne, Mini-Referenzen, Helfer), `test-m1a-3`, `test-m1a-6`;
  - `test-m2-6-evaluate.R` (numerischer Rückfall), `test-m0-deps.R`;
  - die übrigen M1a-Tests wie in Runde 1.
  - Seit dem PLAN-REVIEW der Runde 1 hat sich keine Datei unter `tests/acceptance/`, `reference/anchors/`, `R/`, `docs/` und `DESCRIPTION` geändert (Zeitstempelvergleich; neuer als `PLAN.md` ist nur ADR-017).
- **Produktcode und Aufrufer:**
  - `R/fit.R` und `R/grr.R` vollständig;
  - `R/plan.R` (`msa_simulate()`, `msa_plan()`);
  - `R/acmg.R` (`acmg_mock_backend()`, `acmg_fit()`);
  - `DESCRIPTION`, `.github/workflows/R-CMD-check.yaml`.
- **Harness:**
  - `orchestrate.sh` (Planschleife, Arbiter, `path_allowed`);
  - `gates.d/86-mutgate.sh`, `lib/r-deps.R`, `toolchain.json`, `orchestrator/prompts/30-plan-review.md`.
- **Anker:** ANK-10 (Aufbau), ANK-TOL.
- **Quelle:** Bates et al. (2015), Verlagsfassung im Textspiegel, Abschnitt 3.4.

## Eigene Nachprüfung

Alle Prüfungen liefen ohne Git-Kommando, mit lesenden Aufrufen von `Rscript --vanilla` aus der Repo-Wurzel (R 4.6.1, lme4 2.0.6, VCA 1.5.2). Geschrieben habe ich nur die drei Dateien dieser Phase.

1. **Orakel `remlVCA` gegen das exakte REML-Optimum (K-M1a-3 (a)).**
   - Frage: Verschlechtert ein exakter Vorgabepfad den Orakelvergleich?
   - `VCA::remlVCA` ruft intern `lmer(form, Data, control = lmerControl(optimizer = "bobyqa"))` auf (Deparse, Zeilen 86–87).
   - Nahezu exaktes Optimum auf `ic50_demo` (2152 Zeilen), Antwort standardisiert:
     - enges nloptwrap: REML-Kriterium −2507.077334107915;
     - enges bobyqa: −2507.077334106804;
     - die beiden liegen höchstens 5,6e-6 · σ²_TV auseinander.
   - Vergleich mit `remlVCA` und mit dem Vorgabe-Fit von v0.1.0, als Anteil von σ²_TV des Orakels:

   ```text
   max |exact - remlVCA| / total = 1.12e-06 ; max |default - remlVCA| / total = 6.69e-05 ; proxy pair 5.6e-06 ; tol 1e-4
   ```

   Der exakte Vorgabepfad vergrößert also die Reserve von K-M1a-3 (a). v0.1.0 liegt bei 6,7e-5; das ist derselbe Wert wie in ADR-016 (Kontext ACC-2).

2. **Kriterium und Score aus PLAN-UPDATE (numerisches Verfahren, Punkt 3).**
   - Daten: kleiner unbalancierter Plan, 8 Items × 3 Prompts × 2 Replikate, vier Werte entfernt.
   - Terme: item, prompt, item:prompt; dichte Rechnung.

   ```text
   analytic score: -8.14001 -8.550702 -4.590551
   finite diff.:   -8.14001 -8.550702 -4.590551
   max rel diff: 1.77e-09
   lme4 term order: ip item prompt
   F(l1)-F(l2) = -7.10703 ; REMLcrit(l1)-REMLcrit(l2) = -7.10703
   ```

   - F ist das REML-Kriterium von lme4 bis auf eine Konstante, und der Score stimmt.
   - Analytisch: d log|H| = tr(H⁻¹K_j), d log|X′H⁻¹X| = −tr((X′H⁻¹X)⁻¹X′H⁻¹K_jH⁻¹X), dP = −P K_j P. Daraus folgt dF/dλ_j wie im PLAN-UPDATE.
   - lme4 sortiert die Terme nach ihrer Stufenzahl. Der Plan berücksichtigt das („Termreihenfolge von lme4“).
   - Die Quellenangabe stimmt: Bates et al. 2015, Abschnitt 3.4 „Evaluating and profiling the deviance and the REML criterion“, Gl. (39) bis (41) (Textspiegel der Verlagsfassung, Zeilen 1440–1644).

3. **Refit und Abhängigkeiten.**
   - `lme4::bootMer` (2.0.6) setzt `control` aus `eval.parent(x@call$control)` und ruft `refit(x, ss[[i]], control = control)` auf. Das bestätigt die Antwort auf E8.
   - Versionsvorgaben der Pakete:
     - Matrix 1.7.4: `Depends: R (>= 4.4), methods`;
     - lme4 2.0.6: `Depends: R (>= 3.6), Matrix, methods, stats` und `LinkingTo: Matrix (>= 1.5-0), …`;
     - llmsa: `DESCRIPTION` verlangt `R (>= 4.1)`.
   - Die CI prüft nur `release` (`.github/workflows/R-CMD-check.yaml`, Zeilen 19–21) (→ E15).
   - Das deps-Gate (`r-deps.R`) und K-M0-1 prüfen nur, ob Abhängigkeiten installiert sind. Matrix ist installiert.

4. **Aufrufer des Vorgabepfads.**
   - **`msa_plan()`:** Die Schleife `R/plan.R:82–87` ruft `msa_fit()` in Zeile 84 ohne Fehlerbehandlung auf. Ein Fehler beendet die ganze Planung (→ E13).
   - **`acmg_fit()`:** bricht in `R/acmg.R:950–951` mit „AP1 numeric fallback failed: …“ ab.
   - **Rückfalltest K-M2-6** (`test-m2-6-evaluate.R:110–135`):
     - Er fittet `msa_fit(type = "numeric")` auf die Klassen-Scores 1 bis 5 des Mock-Laufs.
     - Das Mock-Backend streut die Replikate (`sd_rep = 0.3`, `R/acmg.R:311`), die Restvarianz ist also positiv.
     - Die Werte haben aber viele Gleichstände (→ E14).
   - **`msa_simulate()`:** Blöcke sind vollständig gekreuzt (`R/plan.R:25–26`, `expand.grid` über rep, model, prompt, item, block). Die geschlossene Lösung greift deshalb für die simulierten Blockpläne von K-M1a-1 und K-M1a-6.

5. **Formelsammlung §2, Zeile 50:** „**Schätzung (Code).** REML mit `lme4::lmer`. …“ Der Status „Code“ heißt „so in v0.1.0 implementiert“ (Zeile 5) (→ ADR-018 Nr. 1).

6. **ANK-10 enthält keine Rohwerte.**
   - Schlüssel: `design`, `mapping`, `data_file` (Pfad, SHA-256, Spalten, Zeilenzahl), `anova_table`, `model`, `variance`, `sd`, `pct_study_var`, `pct_contribution`, `ndc`, `decimals`, `not_used`.
   - Die byte-identische Kopie unter `inst/validation/numeric/anchors/` liefert also nur Kennzahlen aus (ADR-017 Nr. 7.4 bleibt gewahrt).

7. **Zählung im mutgate.**
   - Das Gate mutiert ganze geänderte Dateien des Scopes (`86-mutgate.sh:15`).
   - Survived und NoCoverage zählen als unerkannt. Äquivalenz zählt nur mit `MUT-EQUIV-APPROVED.json` (Zeilen 22–37) (→ E16).

## Bewertung

### Spec-Treue

**Trägt:**
- **E1, Mechanismus:**
  - Für balancierte Pläne mit nichtnegativen ANOVA-Schätzern gilt die geschlossene Lösung. Nach Formelsammlung §2 ist REML dort gleich ANOVA (Searle, Casella & McCulloch 1992).
  - Alle übrigen Pläne erhalten einen analytischen REML-Abschluss mit aktiver Menge.
  - Die Formeln sind richtig (Messung 2).
  - Der Abbruch verlangt zugleich einen kleinen Score und einen kleinen Korrekturschritt. Das trifft die flache Item-Richtung von `ic50_demo` (ACC-6).
- **Kriterien im Vorgabepfad:**
  - K-M1a-2 (AIAG, `interactions = FALSE`), K-M1a-3 (c) (Penicillin) und K-M1a-4 (NIST) treffen über die geschlossene Lösung die exakten ANOVA-Schätzer. Runde 1, Messung 2: NIST bis 1,2e-10 relativ.
  - K-M1a-3 (a) gewinnt Reserve (Messung 1).
  - K-M1a-3 (b): REML mit Wechselwirkung an der Grenze 0 gleicht auf balancierten Daten dem gepoolten ANOVA-Schätzer von `ss.rr`, solange die übrigen Schätzer ≥ 0 sind (Formelsammlung §2).
  - K-M1a-6:
    - Der simulierte Blockplan läuft über die geschlossene Lösung; mit Seed 1 sind alle ANOVA-Schätzer ≥ 0 (ACC-5).
    - `ic50_demo` ist unbalanciert und läuft über den Abschluss.
    - Für die Randfälle gilt E7.
- **Kriterien mit expliziter Steuerung:** K-M1a-1 und der Nichtkonvergenztest von K-M1a-6 bleiben reine lme4-Prüfungen (E4).
- **K-M1a-5:** ADR-017 Nr. 6 ist übernommen (E11).
- **K-M1a-7:** Gewählt ist der öffentliche Rechenmodus nach ADR-017 Nr. 7.1 bis 7.6 (E10). `README.md` an der Wurzel ist gestrichen (E2).
- **Schnittstellen:**
  - Signaturen, Vorgaben und Klassen bleiben; `numerics` ist additiv (docs/01 §4).
  - Den neuen Fehler bei konstanten Werten und das geänderte Vorgabeverfahren nennen `NEWS.md` und `?msa_fit`.
- **Imports:** Matrix kommt mit einem Builder-ADR hinzu. Das ist zulässig (docs/01 §5); zur Version siehe E15.

**Auslegung:**
- Formelsammlung §2 nennt „REML mit `lme4::lmer`“ mit dem Status Code. ADR-018 Nr. 1 legt fest, was die Stelle für den zusammengesetzten Vorgabepfad verlangt: Kriterium und Modell kommen von lme4, `vc` aus dem zurückgegebenen Modell.
- Ein wörtlicher Widerspruch liegt nicht vor, weil diese Lesart beide Stellen trägt, Formelsammlung §2 und K-M1a-6.

### Architektur und Verträge

- **Eine Quelle für Modell und `vc`** (E3): Originalbeschriftungen, Originalskala und Eingabereihenfolge (E5); `numerics` ist additiv. Das trägt `msa_boot()` und K-M1c-1.
- **Durchreichweg** (E4): Mit irgendeinem Argument in `...` läuft genau `lme4::lmer`.
- **Refit** (E8):
  - Der Refit-Haken ist `nloptwrap` mit leerem `optCtrl`, und der Modellaufruf trägt einen auswertbaren `control`-Ausdruck (Messung 3).
  - Bootstrap-Refits sind damit gewöhnliche lme4-Fits. Ihre Genauigkeit liegt bei bis zu 4,7e-4 · σ²_TV (ADR-016, Kontext ACC-5, balancierte Pläne mit Standard-`lmerControl`); gegen die Streuung der Bootstrap-Verteilung ist das unerheblich.
  - K-M1c-1 vergleicht mit `bootMer(fit$model)`, also mit denselben Refits.
- **Offen:** Welche Warnungen der Vorgabepfad an den Aufrufer gibt, ist noch nicht festgelegt (E17).
- **Bindung:** ADR-018 Nr. 1 bis 6 bindet diese Punkte für BUILD und Code-Review.

### Vollständigkeit, Risiken, Reihenfolge

**Trägt:**
- **Go/No-Go vor der Ressourcenarbeit:**
  - Grenzen aus `ANK-TOL.invariance` und `ANK-TOL.nist_digits`;
  - zusätzliche Verschiebungen, Skalierungen (auch negative) und Seeds 1 bis 6 der vier Pläne;
  - Modellkonsistenz;
  - Eskalation nach ADR-016 E6.
- **Laufzeitvergleich mit v0.1.0** (E8): Erstfit und Refits getrennt.
- **Backlog:** alle offenen Einträge zugeordnet.
- **Toleranzen:** Keine wird gelockert, und keine Testdatei des Reviewers wird angefasst.

**Offen (minor):**
- E13: Robustheit des Vorgabepfads auf Plänen mit vielen Komponenten an der Grenze und Folgen für die Aufrufer;
- E14: Maßstab der Konditionierung bei vielen Gleichständen;
- E15: Matrix-Version und R ≥ 4.1;
- E16: Mutationsscore des neuen Numerikcodes;
- E17: Warnungen im Vorgabepfad.
- E12 bleibt [INFRA] beim Betreiber.

### Gate-Abdeckung

- **tests:**
  - Alle sieben Kriterien haben Abnahmetests.
  - Der kumulative Lauf enthält den Rückfalltest von K-M2-6 (numerischer Fit auf Scores).
  - Der Plan führt die M1a- und `m2-6`-Abnahme, die Unit-Tests sowie e2e und fuzz aus.
- **lint:** Das Gate baut im Vollmodus (`REPO_ROOT`). Den öffentlichen Modus prüfen nur der eigene Paketcheck des Builders und GitHub Actions (ADR-017, Konsequenzen).
- **deps:** Matrix 1.7.4 ist installiert. Das Gate und K-M0-1 bestehen.
- **golden-adr:** Für `inst/extdata/nist-strd-anova_2026-10-22/` ist das Ressourcen-ADR des Builders vorgesehen. ADR-017 und ADR-018 ersetzen es nicht.
- **territory:** Alle Zielpfade des BUILD liegen im Builder-Territorium. Das gilt auch für `inst/validation/numeric/README.md`.
- **trace:** Die Kriteriums-IDs stehen in den Tests.
- **mutgate:** siehe E12 [INFRA] und E16.

### Antworten auf die Einwände der Runde 1

Alle zwölf Antworten haben die Form „akzeptiert: <Änderung>“ (SCHEMA).

| ID | Antwort im PLAN-UPDATE | Bewertung |
| --- | --- | --- |
| E1 | geschlossene Lösung, analytischer Abschluss mit aktiver Menge, Go/No-Go, Matrix mit ADR; bobyqa-Festlegung entfällt | erledigt; Formeln nachgeprüft (Messung 2); Auslegung von Formelsammlung §2 in ADR-018 Nr. 1; Ergänzungen E13, E15 |
| E2 | `README.md` gestrichen, Anleitung unter `inst/validation/numeric/README.md` | erledigt |
| E3 | Modell am endgültigen θ auf Originaldaten, `vc` aus `VarCorr`, geschlossener Wert ist Endwert | erledigt; ADR-018 Nr. 1 und 3 |
| E4 | direkter `lme4::lmer`-Pfad bei jedem Argument in `...` | erledigt; ADR-018 Nr. 2 |
| E5 | `fit$data` und Stufennamen wie bisher, Zuordnung in `numerics` | erledigt |
| E6 | numerische Werte ohne Zeichenkettenumweg | erledigt |
| E7 | getrennte Regeln für konstante Werte, Restvarianz 0 und kleine Streuung | erledigt; Präzisierung E14 und ADR-018 Nr. 4 |
| E8 | Laufzeitvergleich, Refit-Haken `nloptwrap` | erledigt; ADR-018 Nr. 3; Ergänzung E13 |
| E9 | kleine Unit-Tests, kein Knitten, Toleranzen strikt | erledigt |
| E10 | öffentlicher Rechenmodus nach ADR-017 Nr. 7.1–7.6 | erledigt; Driftwache entspricht Nr. 7.3; ANK-10 ohne Rohwerte (Messung 6) |
| E11 | ADR-017 Nr. 6 einschließlich Druckmethoden | erledigt |
| E12 | [INFRA] an den Betreiber | Builder-Teil erledigt; offen beim Betreiber. Den BACKLOG-Eintrag schreibt der Reviewer im Code-Review: in `30-plan-review` ist `BACKLOG.md` kein freigegebener Pfad (`orchestrate.sh`, `path_allowed`). |

### Acceptance-Verträge

- Die Bewertung aus Runde 1 gilt für ACC-1 bis ACC-18 weiter, mit drei Ausnahmen:
  - ACC-6 ist jetzt erledigt (E1, ADR-018);
  - für ACC-14 ist der öffentliche Rechenmodus gewählt (E10);
  - ACC-15 bekommt zu den Suggests den Import von Matrix (E15).
- Abnahmetests und Anker bleiben unverändert.

### Backlog

Das PLAN-UPDATE ordnet alle 57 offenen IDs einzeln zu, und die 18 erledigten bleiben geschlossen. Querbezüge:
- BL-49 und BL-72 gehen in E1 und ADR-018 Nr. 1 bis 3 auf;
- BL-12 und BL-13 in E8 und E13;
- BL-46 in E9 und E10;
- BL-23 deckt die geschlossene Lösung.

Keine Zuordnung verlangt einen Einwand.

## Einwände (Runde 2)

- [E13] (minor) docs/01 §2 Nr. 4 („Randfälle sind Pflicht: … Komponenten an der Grenze null, … nicht konvergierende Fits. Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung“); `R/plan.R:82–87`; docs/02 M1c (Szenarien S-boot-1 bis S-boot-6); BL-12; ADR-018 Nr. 3 und 5 — Robustheit des Vorgabepfads und Folgen für die Aufrufer

  **Befund:**
  - Scheitert der analytische Abschluss, endet `msa_fit()` nach dem PLAN-UPDATE mit Fehler. Das ist zulässig.
  - Folgen für die Aufrufer:
    - `msa_plan()` fängt keinen Fehler ab (Messung 4); ein einziger gescheiterter Fit beendet die ganze Planung.
    - Der volle Lauf von `boot_coverage` nach M1c dauert Stunden bis Tage (BL-12). Er fittet jede Wiederholung über diesen Pfad.
  - Der Go/No-Go deckt das nicht ab:
    - Er misst die Pläne von K-M1a mit großen Prompt- und Modellkomponenten (0,1 und 0,08).
    - Die S-boot-Szenarien haben dagegen viele Komponenten nahe 0: Block 0,01, Prompt×Modell 0,005, zwei Blöcke.
    - Gerade die aktive Menge des Abschlusses wird dort ständig gebraucht.

  **Vorschlag:**
  - Robustheitsnachweis nach ADR-018 Nr. 5 vor Reihenfolge-Schritt 4:
    - S-boot-1 bis S-boot-6 und die vier Szenarien von `?msa_plan`, je Seeds 1 bis 20;
    - je Szenario Zahl der Fits über `closed_form` und `analytic_reml`, Fehler, singuläre Fits, Laufzeiten.
  - Ein Fehler auf diesen nicht degenerierten Daten wird behoben oder nach ADR-016 E6 vorgelegt.
  - `?msa_plan` oder `NEWS.md` nennt, dass ein gescheiterter Fit die Planung beendet.

- [E14] (minor) K-M1a-6 („identische Werte in allen Zeilen führen zu einer Fehlermeldung oder zu `verdict = "undetermined"`“); docs/01 §2 Nr. 4; `test-m2-6-evaluate.R:110–135` (K-M2-6, numerischer Rückfall auf Klassen-Scores); `R/acmg.R:946–951`; PLAN-UPDATE, numerisches Verfahren Punkt 1 („robust berechneten positiven Maßstab“); ADR-018 Nr. 4 — Maßstab der Konditionierung bei vielen Gleichständen

  **Befund:**
  - Robuste Streuungsmaße werden 0, obwohl die Werte variieren:
    - der Median der absoluten Abweichungen, sobald mehr als die Hälfte der Werte gleich ist;
    - der Interquartilsabstand schon früher.
  - Das ist typisch für Klassen-Scores 1 bis 5 mit einer häufigen Klasse, also für den numerischen Rückfall von AP1 (K-M2-6, `acmg_fit()`).
  - Ein Fehler „keine Variation“ träfe dann Daten mit Variation.

  **Vorschlag:**
  - Der Maßstab ist positiv, sobald nicht alle gültigen Werte gleich sind, etwa ein robustes Maß mit Rückfall auf die Standardabweichung oder die größte absolute Abweichung.
  - Unit-Test mit stark gebundenen Scores, etwa 70 % eines Werts, und mit genau zwei verschiedenen Werten.

- [E15] (minor) `DESCRIPTION` (`Depends: R (>= 4.1)`); AGENTS.md, Projektspezifika („R ab 4.1“); docs/01 §5 („neue Imports nur mit ADR“); Messung 3; ADR-018 Nr. 6 — Matrix-Import und Mindestversion von R

  **Befund:**
  - Matrix ab 1.7 verlangt R ≥ 4.4; lme4 2.0.6 verlangt Matrix ≥ 1.5-0.
  - Gates und CI laufen nur mit R 4.6.1 bzw. `release`.
  - Zwei Fehler blieben dort unbemerkt und machten das Paket vor R 4.4 unbrauchbar oder nicht installierbar:
    - eine Matrix-Funktion, die es erst ab 1.7 gibt;
    - eine Versionsangabe `Matrix (>= 1.7…)` unter `Imports`.

  **Vorschlag:**
  - Das numerische ADR nennt die Mindestversion von Matrix für die genutzten Funktionen; die Funktionen bleiben bei der lange bestehenden Schnittstelle (`sparseMatrix`, `Cholesky`, `solve`, `crossprod`, `determinant`).
  - Die Angabe unter `Imports` steht ohne Version oder mit einer Version, die unter R 4.1 erfüllbar ist.

- [E16] (minor) Gate mutgate (`orchestrator/gates.d/86-mutgate.sh:15` und 22–37; Schwelle 80); docs/01 §2 Nr. 7 („Ein verfälschter Kern muss einen Test rot machen.“); Messung 7 — Mutationsscore des neuen Numerikcodes

  **Befund:**
  - Der neue Abschluss liegt in `R/fit.R`, und das Gate mutiert die ganze Datei. Das betrifft auch Newton-Schritt, Dämpfung, aktive Menge und Binärskalierung.
  - Unerkannt bleiben dort:
    - Mutanten in Schutzzweigen, die kein Test erreicht (NoCoverage);
    - Mutanten, die nur die Konvergenzgeschwindigkeit ändern (Survived).
  - Beide senken den Score unter die Schwelle. Eine Äquivalenz zählt nur nach Approval des Reviewers.

  **Vorschlag:**
  - Wenige, erreichbare Zweige.
  - Für jeden Zweig ein Unit-Test, der ihn erzwingt: Schritthalbierung, Eintritt in die aktive Menge und Austritt daraus, Binärskalierung bei großen Werten, degenerierter Fall.
  - Wo sinnvoll, prüfen die Tests die Diagnostik in `numerics`: Verfahren, aktive Menge, Abschlussnormen.
  - Keine Schutzzweige ohne Test.
  - Behauptete Äquivalenz nur über `MUT-EQUIV.json` zur Prüfung durch den Reviewer.

- [E17] (minor) K-M1a-6 („ein nicht konvergierender Fit gibt die lme4-Warnung weiter“); IMPLEMENTATION-RULES („Fehler werden nicht stumm geschluckt“); PLAN-UPDATE, numerisches Verfahren Punkt 4 („lme4-Warnungen werden nicht still unterdrückt“); `R/acmg.R:950–956`; ADR-018 Nr. 3 — Warnungen im Vorgabepfad

  **Befund:**
  - Offen ist, ob eine Warnung des lme4-Startfits beim Aufrufer ankommt, wenn der Abschluss danach konvergiert.
  - Beides ist mit der Spec vereinbar. Eine Konvergenzwarnung zu einem überholten Startwert führt aber Nutzer in die Irre, ebenso den AP1-Bericht: `acmg_fit()` speichert die Warnungen des numerischen Fits.

  **Vorschlag:**
  - Das Verhalten im numerischen ADR und in `?msa_fit` festlegen und mit einem Unit-Test prüfen (ADR-018 Nr. 3: Warnungen gehen nicht verloren).
  - Empfohlen: Warnungen des Startfits mit ihrer Herkunft in `numerics` festhalten und nur weitergeben, wenn der Vorgabepfad scheitert. Der Durchreichweg gibt die lme4-Warnungen unverändert weiter.

- E12 bleibt [INFRA] beim Betreiber, unverändert seit Runde 1:
  - erster echter Mutationslauf über `R/fit.R` und `R/grr.R`;
  - je Mutant laufen alle Abnahmetests und das Knitten der Vignette.
  - Für den Builder nonblocking.

## Verdict

**PASS.**

- Kein blocking-Befund:
  - E1 (Mechanismus der Invarianz) ist erledigt;
  - E2 (`README.md` außerhalb des Territoriums) ist erledigt;
  - alle zwölf Einwände der Runde 1 sind akzeptiert und schlüssig umgesetzt.
- Neu sind E13 bis E17, alle minor. E12 bleibt [INFRA] beim Betreiber.
- ADR-018 bindet nach dem Ende der Planrunden:
  - die Auslegung von Formelsammlung §2;
  - den Durchreichweg;
  - Endwert, Fehler, Warnungen und Refit des Vorgabepfads;
  - den Maßstab der Konditionierung;
  - den Robustheitsnachweis;
  - die Bedingungen für den Matrix-Import.
- Kein wörtlicher Spec-Widerspruch:
  - Formelsammlung §2 und K-M1a-6 trägt die Lesart aus ADR-018 Nr. 1.
  - Die Nullfälle von K-M1a-5 entscheidet weiter ADR-017 Nr. 6.
- BUILD liest PLAN.md, PLAN-UPDATE.md, dieses Review, ADR-017 und ADR-018.
