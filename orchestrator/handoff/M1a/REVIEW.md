# REVIEW — M1a, Runde 1 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 29.10.2026

Gegenstand:
- der Diff seit `plan/M1a` (Tag-Objekt `a9d3f479…` → Commit `485c9605…`) bis HEAD `4701643…`;
- die Gate-Fakten `orchestrator/state/M1a/gates.json` der Runde 1 nach QA;
- `QA.md` mit den fünf QA-Tests.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- **Handoff M1a:** `CRITERIA.json` (K-M1a-1 bis K-M1a-7, ACC-1 bis ACC-18), `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md` und `verdict-plan.json` (Runde 2), `QA.md`.
  - Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`, `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json`.
- **Spezifikation:**
  - `docs/02-statistikkern.md`, Abschnitt M1a, K-M1a-1 bis K-M1a-7 im Wortlaut;
  - `docs/01-fachspezifikation.md` vollständig;
  - ADR-017 bis ADR-021 vollständig, davon ADR-019 (Betreiber) mit drei Nachträgen; ADR-016 über die Verweise in `CRITERIA.json` und ADR-018.
- **Gates:** `gates.json` und alle acht `gate-*.log` der Runde 1 nach QA. Dazu `gates.json` und `gate-mutgate.log` des ersten Gate-Laufs derselben Runde vor QA, aus dem Phasen-Commit `a92396f`.
- **Diff, vollständig gelesen:**
  - `R/fit.R`, `R/grr.R`;
  - `tests/testthat/test-fit-numeric.R`, `test-grr-numeric.R`, `test-validation-numeric.R`, `helper-validation-numeric.R`, der neue Block in `test-acmg-evaluate.R`;
  - `vignettes/validation.Rmd`, `inst/validation/numeric/reference_checks.R`, `README.md`, `SOURCES.json`;
  - `data-raw/make_validation_numeric.R`, `inst/extdata/nist-strd-anova_2026-10-22/QUELLE.txt` und `SHA256SUMS`;
  - `DESCRIPTION`, `NEWS.md`, die drei Rd-Diffs, `PROGRESS.md` (M1a), ADR-020, ADR-021;
  - die QA-Tests `tests/e2e/test-m1a-qa-e2e.R` und `tests/fuzz/test-m1a-qa-fuzz.R`.
- **Visuelle Artefakte:** keine; `orchestrator/state/M1a/shots/` ist leer, in M1a nicht gefordert.

## Gate-Fakten

| Gate | Runde 1 nach QA (`gates.json`, `env.sha` `3ca0dd9`) | erster Lauf Runde 1 vor QA (`a92396f`) |
| --- | --- | --- |
| deps | pass | pass |
| lint | pass (`R CMD check`: Status OK, Vignette gebaut) | pass |
| tests | **fail**: nur die fünf QA-Tests | pass |
| trace | pass | pass |
| territory | pass | pass |
| mutgate | **fail**: unmutierter Vorlauf rot, kein Mutant gelaufen | **fail**: score=60.26 required=80 |
| golden-adr | pass | pass |
| mutfull | pass (nicht fällig) | pass (nicht fällig) |
| result | **fail** | fail |

- **tests:**
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1998 ]`;
  - `tests/acceptance`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3070 ]`, alle Abnahmetests von M0, M2 und M1a grün;
  - `tests/e2e`: `[ FAIL 9 | … | PASS 12 ]`;
  - `tests/fuzz`: `[ FAIL 6 | … | PASS 6 ]`;
  - Kurzbefund: „281 Tests …; 5 fehlgeschlagen, 0 Fehler, 1 übersprungen“. Rot sind genau QA-M1a-001 bis -005.
- **mutgate:**
  - Nach QA: Vorlauf 86,1 s, 218 Tests, 5 rot (`reports/mutation/unmutated.json`); ein `mutation.json` gibt es nicht.
  - Vor QA (gleicher Produktcode, Nachprüfung 1): 1003 Mutanten (`R/fit.R` 783, `R/grr.R` 220); 517 Killed, 29 Timeout, 360 Survived, 97 RuntimeError; Score 60,26.
- **Status error:** keiner. Alle roten Gates haben Ursachen im Builder-Territorium (Produktcode beziehungsweise Tests unter `tests/testthat/`); kein roter Gate-Befund ist [INFRA].

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

Den Diff habe ich ohne Git-Kommando gelesen:
- mit einem eigenen R-Leser für `.git/objects` (lose Objekte und Pack mit Deltas);
- verglichen mit `diff -u` über `Rscript`;
- gerechnet mit `pkgload::load_all()` gegen den Arbeitsbaum und gegen eine Kopie des Paketbaums von `plan/M1a` (v0.1.0-Kern).

Hilfsdateien lagen nur unter `/tmp/rv-m1a/` und `reports/rv-m1a/` (git-ignoriert, Artefakt-Allowlist) und sind gelöscht.

1. **Inventar.** 69 Pfade seit `plan/M1a`:
   - 38 Builder-Pfade (`R/fit.R`, `R/grr.R`, `DESCRIPTION`, `NEWS.md`, drei Rd, `PROGRESS.md`, ADR-020/021, `data-raw/`, `inst/extdata/` mit 12 Dateien, `inst/validation/numeric/` mit 8, `tests/testthat/` mit 5, `vignettes/validation.Rmd`);
   - 2 QA-Tests und `QA.md`;
   - sonst Betreiber und Orchestrator (ADR-019, `docs/gates-auswahl.md`, `RUNBOOK.md`, `config.env.example`, `orchestrator/**`).

   Blob-gleich mit `plan/M1a`: `tests/acceptance/**` (24), `reference/anchors/**` (32), `tests/fixtures/**` (6), `NAMESPACE`, `.Rbuildignore`, `tests/testthat.R`. `R/fit.R` und `R/grr.R` in `a92396f` sind byte-gleich mit dem Arbeitsbaum.
2. **NIST-Golden-Daten.** Elf Tabellen gegen die Originale unter `../quellen/daten/nist-strd-anova_2026-10-22/`:
   - Quell-SHA-256 gleich ANK-14;
   - Zahlentokens, Behandlungen und Reihenfolge identisch;
   - eingelesene Doubles `identical()`;
   - größte Datei 44.487 B, Ordner 224.678 B, `inst/extdata/` 250.931 B (Grenzen aus ANK-TOL.data_size: 1 MB, 3 MB, 5 MB).

   Keine erfundenen Daten.
3. **QA-Befunde nachgerechnet**, gleiche Fälle auf dem Arbeitsbaum und auf v0.1.0:

   | QA | M1a (Arbeitsbaum) | v0.1.0 | Bewertung |
   | --- | --- | --- | --- |
   | 001 | `msa_boot()` auf Fit mit `control = lmerControl(optimizer = "bobyqa")`: „the ... list contains fewer than 1 element“; gespeicherter Aufruf `control = ..1` | gleich | gültig, E18 |
   | 002 | `subset = item != "I001"`: „object 'item' not found“; Index-Subset und `NA`-Gewichte: `n$observations` 24, `nobs()` 20, `n$items` 6 gegen 5 Items im Modell, `nrow(fit$data)` 24 | gleich | gültig, E19 |
   | 003 | balanciert: „leading principal minor of order 13 is not positive“, CHOLMOD-Warnung, zwei lme4-Warnungen; unbalanciert: „… order 4 …“, dazu CHOLMOD- und lme4-Warnungen | „Downdated VtV is not positive definite“ bzw. Rest 3,7e-13 mit Warnung | gültig, E20 |
   | 004 | × 1e-161: 9,05 % von σ²_TV still, × 1e-160: 0,19 %; `"NaN"` warnt, `NaN` nicht (beide 19 Beobachtungen); NA-Gruppierung explizit: 20 gegen `nobs()` 18, Vorgabepfad: benannter Fehler | × 1e-161: 15,5 % mit lme4-Warnung; NA-Gruppierung auch im Vorgabepfad still | gültig, E21 |
   | 005 | `c(30, 10)` → „unacceptable“, `"invalid"` → „acceptable“, `10` und `c(NA, 30)` → „missing value where TRUE/FALSE needed“; Manifestprüfung besteht ohne `datasets` und mit `ANK-99.json` | Schwellen gleich | gültig, E22 |

   - Jede QA-Erwartung ist mit Spec, ADR-018 und der eigenen Dokumentation des Builders vereinbar. Wo die Spec schweigt, legt ADR-022 die Auslegung fest.
   - Drei Zitate, die QA.md ADR-020 zuschreibt, stehen dort nicht (E39).
   - Einen QA-Test stufe ich nicht herab. Ein herabgestufter Test bliebe rot und hielte tests und mutgate rot, denn `tests/e2e` und `tests/fuzz` ändert nur QA.
4. **Präzision des Originalskalenmodells** (Vorgabepfad).

   **Vergleich:** σ²_e des zurückgegebenen Modells (`sigma(fit$model)^2`) gegen das eigene konditionierte Ergebnis `numerics$state$residual · (scale · binary_scale)²`.

   | Daten | Verfahren | σ²(Modell) | konditioniert | relative Lücke |
   | --- | --- | --- | --- | --- |
   | `ic50_demo` | analytic_reml | 1,401031e-02 | 1,401031e-02 | 1,1e-16 |
   | `ic50_demo` + 1e8 / + 1e9 / + 1e10 | analytic_reml | … | … | 1,2e-7 / 8,5e-6 / 6,8e-4 |
   | SiRstv, SmLs01–SmLs06, AtmWtAg | closed_form | … | … | höchstens 3,6e-11 |
   | SmLs07 | closed_form | 1,000154e-02 | 1,000054e-02 | 1,0e-4 |
   | SmLs08 | closed_form | 5,021323e-02 | 1,000054e-02 | 4,0 |
   | SmLs09 | closed_form | 1,531459e+02 | 1,000054e-02 | 1,5e+4 |
   | QA-004 × 1e-161 | analytic_reml | 9,881313e-324 | 9,881313e-324 | 0 |

   - **Verschiebung gegen dieselben, gleich gerundeten Daten ohne Offset** (`(y + c) − c`):
     - Die Varianzverhältnisse und %GRR sind bei jeder Verschiebung gleich.
     - Die Komponenten weichen bei `ic50_demo` + 1e9 um 8,1e-6 · σ²_TV ab, bei + 1e10 um 6,5e-4 · σ²_TV.
     - Beim balancierten Plan mit Block und Wechselwirkungen bleiben sie bis + 1e10 unter 4,7e-7.
   - **v0.1.0 zum Vergleich:**
     - SmLs07: 9,99e-3 und SmLs08: 1,14e-2, jeweils mit lme4-Warnung („Model is nearly unidentifiable … Rescale variables?“);
     - SmLs09: 7,86e-2.
     - Der neue Pfad ist auf SmLs08/09 schlechter und meldet nichts (E23).
   - **Subnormaler Fall:** Eine reine Konsistenzprüfung fängt ihn nicht, denn beide Werte sind gleich ungenau. Er braucht die Darstellbarkeitsprüfung (E21).
5. **Geschlossene Lösung gegen eine unabhängige EMS-Rechnung.**
   - Rechnung: aus `stats::aov`-Mittelquadraten, eigene Koeffizientenmatrix.
   - Pläne: `msa_simulate(12, 3, 3, 2, blocks)`, Komponenten der K-M1a-1-Pläne, ohne/mit Block, ohne/mit Wechselwirkungen, Seeds 1–3; elf Pläne mit nichtnegativen Schätzern.
   - Ergebnis: Alle laufen über `closed_form` und weichen höchstens 2,1e-15 · σ²_TV ab. Die Rechnung stimmt.
   - Kein Test sichert sie aber für Wechselwirkungen und Block ab (E28).
6. **Vertragsprüfungen.**
   - ADR-018:
     - Nr. 1 (a)–(d) erfüllt: `mkMerMod` am Endwert, `vc` gleich `vc_from_model(model)`, im Unit-Test mit `expect_identical`.
     - Nr. 2 erfüllt: `...length() == 0L`.
     - Nr. 3 erfüllt bis auf den Fehlerfall Restvarianz 0 (E20).
     - Nr. 4 erfüllt: Maßstab = größte absolute Differenz; Test mit 70 % Gleichständen.
     - Nr. 5 erfüllt: ADR-020, 200 Fits ohne Fehler, Laufzeiten.
     - Nr. 6 erfüllt: `Matrix (>= 1.6-0)`; `determinant(…, sqrt = )` laut installierter `Matrix/NEWS.Rd` neu in 1.6-0; `R (>= 4.1)` unverändert.
   - ADR-017:
     - Nr. 6 erfüllt.
     - Nr. 7.1–7.6 erfüllt: Kopien byte-gleich laut `SOURCES.json`, Driftwache grün, `R/` liest keine Kopie.
     - Lücke in der Manifestprüfung: E22.
   - PLAN-REVIEW: E14, E15 und E17 erfüllt; E13 als Nachweis erfüllt, die Doku fehlt (E38); E16 nicht erreicht (E24–E37).

## Bewertung

### Spec- und Vertragstreue

- Alle Abnahmetests von K-M1a-1 bis K-M1a-7 sind grün, und das lint-Gate baut die Vignette im Vollmodus ohne ERROR und WARNING. Der Builder hat sie nicht angefasst.
- Der zusammengesetzte Vorgabepfad hält ADR-018 und ADR-019 (b) ein. Eine Ausnahme ist der Fehlerfall bei verschwindender Restvarianz (E20).
- Offen sind drei Gruppen von Lücken:
  - die gültigen QA-Befunde (E18–E22);
  - die stille Ungenauigkeit des Originalskalenmodells bei großem Offset (E23);
  - der Mutationsscore (E24–E37).
- Kein wörtlicher Spec-Widerspruch, also kein ESCALATE. K-M1a-4 nimmt SmLs07–SmLs09 von der Genauigkeitsforderung aus. docs/01 §2 Nr. 4 verbietet unabhängig davon die stille falsche Zahl; beides ist zugleich erfüllbar (ADR-022 Nr. 6.3).

### API-Diff

- Keine neuen Exporte; `NAMESPACE` ist byte-gleich.
- Signaturen und Vorgaben sind gleich (`m0-api-snapshot` grün).
- Neu ist das Rückgabefeld `numerics`; Druckausgaben haben sich geändert. Beides ist nach docs/01 §4 ohne ADR erlaubt.
- `Matrix` wird mit ADR-020 importiert; VCA und SixSigma kommen unter Suggests hinzu.
- Neue Fehler im Vorgabepfad: konstante, nicht endliche oder fehlende Werte. `?msa_fit` nennt sie, `NEWS.md` nicht (E38).

### Integrität

- **Entkernte oder geänderte Tests:** keine. Abnahmetests, Fixtures und Anker sind blob-gleich. `test-acmg-evaluate.R` hat nur einen Block dazubekommen.
- **Gelockerte Konfiguration:** keine. `.Rbuildignore`, `NAMESPACE` und `tests/testthat.R` sind gleich; Toleranzen und Gates hat der Builder nicht geändert.
- **Harte Erwartungswerte:** keine. In `R/` stehen keine Datensatz- oder Ankerwerte. Die Tests lesen Toleranzen aus den Ankerkopien mit Pflichtprüfung (`numeric_tolerance()`).
- **Erfundene Daten:** keine (Nachprüfung 2).
- **Golden-Daten:** `inst/extdata/nist-strd-anova_2026-10-22/` kommt mit ADR-021; golden-adr ist grün.

### Neue Tests

- Die neuen Unit-Tests belegen Verhalten gegen unabhängige Referenzen:
  - EMS aus `aov`;
  - direkte `lme4::lmer`- und `bootMer`-Aufrufe;
  - dichte Matrixrechnung für Kriterium, Score und Krümmung;
  - synthetische Zielfunktionen mit bekanntem Optimum;
  - eigene Algebra für die GRR-Kennzahlen;
  - Negativfälle für Ressourcen.
- Keiner friert nur die eigene Ausgabe ein.
- Lücken (zeigen sich in den Überlebenden):
  - die geschlossene Lösung mit Wechselwirkungen und Block (E28);
  - die Konditionierung, die nur über Eigenschaften geprüft wird (E27);
  - `n` und `data` im Durchreichweg (E19);
  - Meldungs-, Druck- und Bootstrap-Pfade (E25–E37).

## Einwände

### Blocking aus QA (Gate tests)

- [E18] (blocking) QA-M1a-001 (`tests/e2e/test-m1a-qa-e2e.R:4–33`, Gate tests); `?msa_boot` (neu in M1a: „An explicit fitting control passed to [msa_fit()] remains the model's refit control.“); ADR-018 Nr. 3 („Der Modellaufruf enthält einen `control`-Ausdruck, der im Kontext des Aufrufers auswertbar ist. Grund: `bootMer` in lme4 2.0.6 wertet `eval.parent(x@call$control)` aus.“); ADR-022 Nr. 1.3 — **Befund:** Auf dem Durchreichweg speichert `lme4::lmer()` den Aufruf mit `control = ..1` (`R/fit.R:173`). Deshalb bricht `msa_boot()` bei jedem so gesteuerten Fit mit „the ... list contains fewer than 1 element“ ab, auch beim bobyqa-Auftrag aus ANK-TOL wie in K-M1a-1. Der Fehler bestand schon in v0.1.0; neu ist die gegenteilige Zusicherung in `?msa_boot`. — **Vorschlag:**
  - einen selbsttragenden Aufruf speichern: Steuerung und übrige nicht datenbezogene Argumente als Werte, ohne die lme4-Rechnung zu ändern (ADR-018 Nr. 2);
  - Unit-Test mit `msa_boot()` auf einem expliziten Fit, auch aus einer Hilfsfunktion mit lokaler Steuerung;
  - `?msa_boot` sichert nur zu, was ein Test belegt.
- [E19] (blocking) QA-M1a-002 (`tests/e2e/test-m1a-qa-e2e.R:35–68`, Gate tests); K-M1a-6 („`n$observations` die verbliebene Zahl“); docs/01 §2 Nr. 4 („nie stillschweigend eine falsche Zahl“); `?msa_fit` (`@return`: „the analysed `data`“; `@param ...`: „a direct [lme4::lmer()] call on the original response“); ADR-022 Nr. 1.1–1.2 — **Befund:**
  - (a) `subset = item != "I001"` scheitert mit „object 'item' not found“. Das Weiterreichen über `...` bricht die Datenmaskierung von lme4; ein direkter `lmer`-Aufruf auf `dat` rechnet dagegen.
  - (b) Verwirft lme4 Zeilen (Index-`subset`, `NA` in `weights`), beschreiben `fit$n`, `fit$data` und `numerics$input_rows` weiter die Zeilen vor dem Fit: 24 Beobachtungen und 6 Items gegen 20 und 5 im Modell. `print()` und `msa_grr()$n` zeigen die falschen Zahlen.
  - Altbestand aus v0.1.0; `input_rows` ist neu in M1a.

  — **Vorschlag:**
  - `...` unausgewertet an lme4 geben: Ausdrücke in `dat` auswerten, mit der Umgebung des Aufrufers als Rahmen; zusammen mit E18 einen selbsttragenden Aufruf speichern;
  - `data`, `n` und `input_rows` aus den tatsächlich analysierten Zeilen ableiten;
  - Unit-Tests mit Ausdrucks-Subset, Index-Subset und `NA`-Gewichten;
  - `?msa_fit` nennt die Spaltennamen und den Zeilenbezug.
- [E20] (blocking) QA-M1a-003 (`tests/e2e/test-m1a-qa-e2e.R:70–119`, Gate tests); ADR-018 Nr. 3 („`msa_fit()` endet mit einer benannten englischen Fehlermeldung (docs/01 §2 Nr. 4), wenn … das Problem kein endliches Optimum hat, etwa bei Restvarianz 0“); `?msa_fit` („… a degenerate residual variance produce named errors.“); ADR-022 Nr. 7 — **Befund:** Identische Replikate enden mit dem rohen Matrix-Fehler „leading principal minor of order 13 (bzw. 4) is not positive“, dazu mit einer CHOLMOD-Warnung und lme4-Konvergenzwarnungen. Betroffen sind ein balancierter Zweifaktorplan mit Wechselwirkung und ein unbalancierter Einwegplan. Ursachen:
  - Im balancierten Pfad prüft `R/fit.R:249` auf `residual_v == 0`. Der Rest nach Abzug der Effekte ist aber nicht genau 0, sondern ein Rundungsrest unter 1e-32 (konditionierte Skala; nachgerechnet 4,8e-33, QA nennt 7,17e-33).
  - Die EMS-Schätzer von Item und Prompt sind echt negativ (−2,79 und −1,30 aus `aov`), nicht durch Rundung, wie QA.md schreibt. Der Plan geht deshalb an den Abschluss.
  - Dort wächst λ ohne Grenze, bis `Matrix::Cholesky()` scheitert (`R/fit.R:281`).

  — **Vorschlag:**
  - verschwindende Restvarianz relativ zur Gesamtstreuung erkennen, im balancierten Pfad und im Abschluss (divergierendes λ, Q nahe 0), mit der benannten Meldung;
  - keine Matrix- oder CHOLMOD-Meldung erreicht den Aufrufer;
  - Unit-Tests für beide Pläne; die Grenze steht im numerischen ADR.
- [E21] (blocking) QA-M1a-004 (`tests/fuzz/test-m1a-qa-fuzz.R:4–56`, Gate tests); docs/01 §2 Nr. 4; docs/01 §5 („Fehlende oder nicht parsbare Antworten bleiben fehlend und werden gezählt, nie ersetzt.“); PLAN-UPDATE, Randfälle („Bei tatsächlichem Nullmaßstab, Über-/Unterlauf oder fehlender Identifizierbarkeit benannter Fehler.“); ADR-022 Nr. 2, 3 und 6.2 — **Befund:**
  - (1) Bei Messwerten × 1e-161 gibt `msa_fit()` subnormale Komponenten (≈ 1e-322) ohne Meldung zurück, 9,05 % von σ²_TV daneben (× 1e-160: 0,19 %). v0.1.0 warnte dort wenigstens. Die Prüfung `sigma(model) <= 0` (`R/fit.R:449`) greift nicht.
  - (2) Die Zeichenkette `"NaN"` löst die Warnung „could not be interpreted as numbers“ aus, numerisches `NaN` nicht.
  - (3) Fehlende Gruppierungswerte: Der Vorgabepfad bricht benannt ab, der Durchreichweg verwirft die Zeilen still in lme4 (`n$observations` 20, `nobs()` 18).
  - QA.md stützt (1) auf ein Zitat, das in ADR-020 nicht steht (E39). Der Befund trägt sich über die genannten Stellen.

  — **Vorschlag:**
  - Darstellbarkeitsprüfung auf der Originalskala nach ADR-022 Nr. 6.2, zusammen mit E23;
  - `NaN` nach ADR-022 Nr. 3;
  - fehlende Gruppierungswerte vor der Pfadwahl prüfen (ADR-022 Nr. 2);
  - je Punkt ein Unit-Test.
- [E22] (blocking) QA-M1a-005 (`tests/fuzz/test-m1a-qa-fuzz.R:58–94`, Gate tests); docs/01 §2 Nr. 4; K-M1a-5 (Klassifikation nach den Schwellen, `ankerRef: ANK-16`); ADR-017 Nr. 7.2 und 7.3; ADR-022 Nr. 4 und 5 — **Befund:**
  - (1) `msa_grr()` prüft `threshold` nicht. `c(30, 10)` und `c(-5, 30)` ergeben ein Verdikt ohne Meldung. `"invalid"` ergibt durch Zeichenvergleich „acceptable“. Länge 1 und `NA` enden mit „missing value where TRUE/FALSE needed“.
  - (2) `validation_verify_resources()` (`inst/validation/numeric/reference_checks.R:47–67`) besteht ohne `datasets` im Manifest und mit einer zusätzlichen `anchors/ANK-99.json`.
  - QA schlug nonblocking vor; ich stufe hoch:
    - der Test bleibt sonst rot und hält tests und mutgate rot;
    - nur eine Produktänderung macht ihn grün;
    - die Erwartung folgt docs/01 §2 Nr. 4 und ADR-017 Nr. 7.

  — **Vorschlag:** Schwellenprüfung nach ADR-022 Nr. 4 und Manifestprüfung nach ADR-022 Nr. 5, jeweils mit benannter Meldung und Unit-Test.

### Blocking aus eigener Nachprüfung

- [E23] (blocking) docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); K-M1a-6 („Verschieben aller Werte um eine Konstante lassen Varianzkomponenten (Toleranz `ankerRef: ANK-TOL.invariance` als Anteil von σ²_TV) … unverändert“); ADR-022 Nr. 6 — **Befund:** Der Vorgabepfad rechnet die Varianzverhältnisse auf der konditionierten Antwort genau. σ² übernimmt er aber ungeprüft aus der Devianzfunktion von lme4 auf den Originaldaten (`R/fit.R:435–448`). Bei großem Offset verliert diese Rechnung Stellen, und `msa_fit()` gibt die falsche Zahl ohne Meldung zurück (Nachprüfung 4):
  - **NIST:** SmLs08 liefert σ²_e = 5,02e-2, SmLs09 153,1. Die eigene konditionierte Lösung trifft dagegen 1,000054e-2 (zertifiziert 1e-2).
  - **Regression:** v0.1.0 lag auf SmLs08 bei 1,14e-2 und warnte „Rescale variables?“, auf SmLs09 bei 7,86e-2. Der neue Pfad ist schlechter, und die Warnung entfällt.
  - **Verschiebung:** `ic50_demo` + 1e9 verfehlt `ANK-TOL.invariance` (8,1e-6 · σ²_TV gegenüber denselben, gleich gerundeten Daten ohne Offset); + 1e10 weicht um 6,5e-4 ab.
  - **Abnahmefälle:** nicht betroffen (Lücke höchstens 3,6e-11). K-M1a-4 wertet SmLs07–SmLs09 nicht, erlaubt aber keine stillen Fehlwerte.

  — **Vorschlag:**
  - σ² des Modells gegen die konditionierte Lösung prüfen (ADR-022 Nr. 6.1).
  - Bei Überschreitung entweder ein Modell, das die genaue Lösung trägt (etwa mit konstantem Offset der Antwort, ADR-018 Nr. 1 gewahrt), oder ein benannter Fehler. SmLs07–SmLs09 dürfen dann `NA` mit Grund zeigen.
  - Die Grenze im numerischen ADR begründen.
  - Unit-Test mit der öffentlichen SmLs09-Tabelle oder `ic50_demo` + 1e10; SmLs04–SmLs06 bleiben grün.
  - Die Konsistenzprüfung fängt den subnormalen Fall aus E21 nicht; dort gilt ADR-022 Nr. 6.2.

### Blocking aus Gate mutgate

- [E24] (blocking) Gate mutgate (`gates.json` Runde 1: „mutgate: fail (unmutierter Vorlauf rot, kein Mutant gelaufen; 5 Tests: …)“) — **Befund:**
  - Der Mutationslauf brach vor dem ersten Mutanten ab, weil die fünf QA-Tests schon unmutiert scheitern. Einen `reports/mutation/mutation.json` gibt es deshalb nicht, nur `unmutated.json`.
  - Der erste Gate-Lauf derselben Runde (`a92396f`, Produktcode byte-gleich) lief vollständig: 1003 Mutanten, 517 Killed, 29 Timeout, 360 Survived, 97 RuntimeError. Score 60,26 bei Schwelle 80 (keine Baseline), also 19,74 Punkte darunter.
  - Bei unverändertem Mutantensatz fehlen 179 erkannte Mutanten: 725 von 906 gezählten.

  — **Vorschlag:**
  - E18 bis E22 beheben, damit der Vorlauf grün wird.
  - Die Überlebenden aus E25–E37 behandeln: töten (Test), Code entfernen oder Äquivalenz in `MUT-EQUIV.json` beantragen.
  - Neue Tests unter `tests/testthat/` prüfen Verhalten gegen unabhängige Werte (Anker, Orakel, Formel). Eine Momentaufnahme der eigenen Ausgabe ist nur zulässig, wo keine Referenz existiert, und dann gekennzeichnet (ADR-019, zweiter Nachtrag).

**Überlebende Mutanten nach Datei und Stelle.** Quelle ist der Abschnitt „Survived Mutants“ in `orchestrator/state/M1a/gate-mutgate.log` des Phasen-Commits `a92396f` (360 Mutanten, 147 Zeilen). Zeilen und Mutatorbezeichnungen stehen wörtlich so in diesem Log. NoCoverage: 0. Approvals: keine.
- Der Log nennt die Bezeichnung der muttest-Ausgabe. Die Gates ordnen eine Approval über Datei, `mutatorName` und Anfangszeile im JSON-Bericht zu.
- Ein Äquivalenzantrag braucht deshalb den `mutatorName` aus dem nächsten `mutation.json` (E41).
- Die genannten „Kandidaten für Verhaltensgleichheit“ sind Hinweise, keine Approval. Jeden Antrag prüfe ich einzeln.

- [E25] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 29 überlebende Mutanten in `R/fit.R`, `msa_fit()`: Eingabe, Parsing, ordinale und binäre Zweige, Prüfungen der numerischen Antwort — Vorschlag: Tests, die (a) den vollen Meldungstext und `conditionCall()` (NULL wegen `call. = FALSE`) der Fehler und Warnungen prüfen (Z. 95, 99, 111, 114, 125, 127, 134–136); (b) die ordinalen und binären Parsing-Zweige belegen: logische Werte, numerische 0/1, Labels mit `levels` (Ereignis = `levels[2]`, Werte außerhalb von `levels` → NA mit Warnung), ungültige Binärwerte, `is.ordered(fit$data$y)` bei ordinal (Z. 113–127); (c) die Konstantenprüfung mit genau einem gültigen Wert treffen (Z. 136). Z. 94 (`stringsAsFactors` bei `as.data.frame()` eines data.frame) und Z. 98/131 (`drop` bei mehrspaltigen Rahmen) sind Kandidaten für verhaltensgleiche Mutanten: Argument entfernen oder MUT-EQUIV-Antrag mit Begründung.
  - Z. 94: `FALSE → TRUE`
  - Z. 95: `<non-empty string> → ""`
  - Z. 98: `FALSE → TRUE`
  - Z. 99: `FALSE → TRUE`
  - Z. 111: `FALSE → TRUE`
  - Z. 113: `TRUE → FALSE`
  - Z. 114: `<condition> → !(<condition>)`, `<non-empty string> → ""`
  - Z. 118: `<condition> → !(<condition>)`
  - Z. 119: `<condition> → !(<condition>)`
  - Z. 120: `!<condition> → <condition>`, `<condition> → !(<condition>)`
  - Z. 122: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `== → !=`, `NA_integer_ → NA`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`
  - Z. 125: `<condition> → !(<condition>)`, `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 127: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 131: `FALSE → TRUE`
  - Z. 134: `FALSE → TRUE`
  - Z. 135: `FALSE → TRUE`
  - Z. 136: `<n> + 1 → <n> + 1`, `FALSE → TRUE`, `x[<i>] → x[<i> + 1L]`

- [E26] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 27 überlebende Mutanten in `R/fit.R`, `msa_fit()`: Modellterme, Fehlermeldungen zur Itemzahl, `numerics`, abgeleitete Zwei-Stufen-Komponente, `singular`, `n` — Vorschlag: Tests für: Wechselwirkungsterme, wenn ein Faktor nur eine Stufe hat (`interactions = TRUE` mit einem Modell → kein `item:model` in `fit$formula`; Z. 154); die Meldungen bei zu wenigen Items, numerisch und ordinal (Z. 160–161); `fit$numerics` gleich NULL bei ordinal/binär (Z. 166); Zeilenfolge von `vc` und `attr(vc, "derived")` bei einer Zwei-Stufen-Komponente (Z. 187–189); die `singular`-Regel für clmm-Fits (Z. 193); `n$reps_per_cell` gegen eine unabhängige Zählung mit `table()` auf einem Plan mit ungleicher Zellbesetzung je Prompt, Modell und Block (Z. 195).
  - Z. 154: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `> → >=`, `x[<i>] → x[<i> + 1L]`
  - Z. 160: `<condition> → !(<condition>)`, `<non-empty string> → ""`, `<non-empty string> → ""`, `== → !=`
  - Z. 161: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 166: `NULL → NA`
  - Z. 187: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 188: `FALSE → TRUE`
  - Z. 189: `FALSE → TRUE`
  - Z. 193: `!= → ==`, `< → >`, `< → <=`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<non-empty string> → ""`, `<non-empty string> → ""`
  - Z. 195: `+ → -`, `+ → -`, `+ → -`

- [E27] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 20 überlebende Mutanten in `R/fit.R`, `msa_numeric_condition()` — Vorschlag: Exakte Erwartungen für kleine Eingaben: `origin`, `center`, `scale` (größte absolute Differenz zum ersten Wert), `binary_scale = 1`, konditionierte Werte; für den Überlaufzweig `binary_scale = 2^floor(log2(max(abs(y))))` und die konditionierten Werte. Der vorhandene Test prüft nur `binary_scale > 1`, Endlichkeit und Mittelwert. Der Fehlerzweig in Z. 216 ist nach der Konstantenprüfung in `msa_fit()` womöglich unerreichbar: direkt über `msa_numeric_condition()` testen oder entfernen.
  - Z. 209: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 210: `- → +`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`
  - Z. 212: `- → +`, `^ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 213: `- → +`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`
  - Z. 216: `<n> - 1 → <n> - 1`, `<non-empty string> → ""`, `|| → &&`, `FALSE → TRUE`
  - Z. 219: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`

- [E28] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 26 überlebende Mutanten in `R/fit.R`, `msa_numeric_balanced()` (geschlossene EMS-Lösung) — Vorschlag: Vorrangig ein Unit-Test, der Vorgabe-Fits (ohne `...`, `numerics$method == "closed_form"`) mit Wechselwirkungen und Block gegen eine unabhängige EMS-Rechnung aus `stats::aov` prüft. Das prüft bisher kein Test: K-M1a-1 läuft über den expliziten bobyqa-Pfad, K-M1a-6 prüft nur Selbstkonsistenz, der vorhandene Unit-Test nur Haupteffekte. Deshalb überlebt Z. 240 `- → +`. Die Rechnung selbst stimmt (Nachprüfung 5: höchstens 2,1e-15 · σ²_TV auf elf Plänen). Dazu Tests der Anwendbarkeitsgrenzen über `numerics$method`: eine Beobachtung je Zelle, unvollständige Kreuzung, ungleiche Besetzung, ein EMS-Schätzer genau 0 (Z. 227, 229, 259). Ferner die Meldung ohne Restfreiheitsgrade (Z. 232) und die Einweg-Grenze gegen `var()` (Z. 255–257). Z. 238/244 (`- grand`) wirkt auf eine bereits zentrierte Antwort (Mittel 0 bis auf Rundung): Subtraktion entfernen oder Äquivalenz beantragen. Z. 228/237 (`drop`) sind ebenfalls Kandidaten. Z. 249 gehört zu E20.
  - Z. 227: `> → >=`, `NULL → NA`
  - Z. 228: `TRUE → FALSE`
  - Z. 229: `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`
  - Z. 232: `<= → <`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 237: `TRUE → FALSE`
  - Z. 238: `- → +`
  - Z. 240: `- → +`
  - Z. 244: `- → +`
  - Z. 249: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `FALSE → TRUE`
  - Z. 255: `< → <=`, `<n> - 1 → <n> - 1`
  - Z. 256: `<n> - 1 → <n> - 1`
  - Z. 257: `- → +`, `- → +`, `/ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 259: `< → <=`

- [E29] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 15 überlebende Mutanten in `R/fit.R`, `msa_numeric_reml()` (Kriterium, Score, Krümmung) — Vorschlag: Tests, die `information` (Grundlage der Identifizierbarkeitsprüfung) gegen eine unabhängige dichte Rechnung prüfen und einen knapp identifizierbaren von einem nicht identifizierbaren Plan trennen (Z. 306); den Fehlerzweig `Q <= 0` mit benannter Meldung (Z. 288, mit E20). Kandidaten für Verhaltensgleichheit, also Code vereinfachen oder MUT-EQUIV-Antrag mit Begründung: Z. 273 (`sparse`), Z. 281 (`LDL`, `perm`), Z. 283/296 (`drop`, alle Blöcke haben mindestens zwei Stufen), Z. 289 (`mean(residual)` ist bei zentrierter Antwort 0 bis auf Rundung), Z. 293 (Anfangswerte der Matrizen, die vollständig überschrieben werden).
  - Z. 273: `TRUE → FALSE`
  - Z. 281: `FALSE → TRUE`, `TRUE → FALSE`
  - Z. 283: `FALSE → TRUE`
  - Z. 288: `<= → <`, `<n> - 1 → <n> - 1`, `<non-empty string> → ""`, `|| → &&`, `FALSE → TRUE`
  - Z. 289: `- → +`
  - Z. 293: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 296: `FALSE → TRUE`
  - Z. 306: `- → +`, `/ → *`

- [E30] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 22 überlebende Mutanten in `R/fit.R`, `msa_numeric_step()` (Newton-Schritt, aktive Menge) — Vorschlag: Direkte Tests von `msa_numeric_step()` auf kleinen konstruierten Zuständen mit exakt bekannter Newton-Richtung: freie und aktive Menge, Blockierung an der Grenze 0, indefinite Krümmung (Eigenwert-Untergrenze), exakte Werte von `step`, `score`, `correction` und `positive`.
  - Z. 313: `<n> + 1 → <n> + 1`
  - Z. 315: `< → <=`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `> → >=`
  - Z. 317: `TRUE → FALSE`
  - Z. 320: `FALSE → TRUE`
  - Z. 321: `TRUE → FALSE`
  - Z. 322: `* → /`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 323: `<n> - 1 → <n> - 1`, `> → >=`
  - Z. 326: `< → <=`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`
  - Z. 333: `* → /`, `/ → *`
  - Z. 334: `/ → *`

- [E31] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 53 überlebende Mutanten in `R/fit.R`, `msa_numeric_optimize()` (Abschluss, Liniensuche, Zählungen) — Vorschlag: Tests auf konstruierten Zielfunktionen mit exakt erwarteten Zählungen: `iterations`, `evaluations`, `step_halvings`, `entered`, `released` als Gleichheit statt `> 0`. Ferner Schrittbegrenzung, die die Grenze 0 exakt trifft (Z. 357, 363); Armijo-Bedingung und Rundungsreserve getrennt erzwungen (Z. 368–372); Nicht-Konvergenz mit Meldung und `conditionCall()` (Z. 385–386); Identifizierbarkeitsfehler (Z. 340–343). Mutanten, die nachweislich nur die Zahl der Schritte ändern und nie das Ergebnis, nur mit Begründung per MUT-EQUIV-Antrag.
  - Z. 340: `* → /`, `<n> + 1 → <n> + 1`
  - Z. 341: `TRUE → FALSE`, `TRUE → FALSE`
  - Z. 342: `* → /`, `<= → <`
  - Z. 343: `FALSE → TRUE`
  - Z. 349: `&& → ||`, `<= → <`, `<= → <`
  - Z. 350: `- → +`
  - Z. 356: `<n> - 1 → <n> - 1`
  - Z. 357: `<n> + 1 → <n> + 1`
  - Z. 359: `FALSE → TRUE`
  - Z. 361: `<n> - 1 → <n> - 1`
  - Z. 362: `<condition> → !(<condition>)`
  - Z. 363: `/ → *`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> + 1L]`
  - Z. 367: `+ → -`
  - Z. 368: `* → /`, `* → /`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`
  - Z. 369: `* → /`, `/ → *`, `+ → -`, `<= → <`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 370: `&& → ||`, `+ → -`, `<= → >=`, `<= → <`
  - Z. 371: `< → >`, `< → <=`
  - Z. 372: `< → <=`, `<n> + 1 → <n> + 1`, `|| → &&`
  - Z. 376: `<n> + 1 → <n> + 1`
  - Z. 380: `& → |`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `== → !=`, `> → >=`
  - Z. 381: `& → |`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `== → !=`, `> → >=`
  - Z. 386: `FALSE → TRUE`

- [E32] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 37 überlebende Mutanten in `R/fit.R`, `msa_numeric_fit()` (Start, Modellbau, Diagnostik) — Vorschlag: Tests für: `numerics$start$theta` gegen `lme4::lmer(REML = TRUE)` auf der konditionierten Antwort (Z. 406, 418); `fit$model@optinfo$derivs` gegen Differenzenquotienten der Devianzfunktion des Modells selbst (Z. 432–434); `stats::update(fit$model)` und `getCall(fit$model)` (REML, Funktionskopf `lme4::lmer`; Z. 444, 446); `numerics$active` auf einem singulären Fit (Z. 453); die Feldnamen von `optinfo$completion` (Z. 455); `optinfo$message` (Z. 439); Meldungstexte und `conditionCall()` von Fehlern und weitergegebener Startwarnung (Z. 390, 403, 450). Z. 449–450 gehören zu E21 und E23. Kandidaten für Verhaltensgleichheit: Z. 395 (`REML` in `lFormula()`, dort nur für `Zt` und die Termnamen verwendet), Z. 397 (`fixed` bei `":"`), Z. 403 `add` (einziges `on.exit()`).
  - Z. 390: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 395: `TRUE → FALSE`
  - Z. 397: `TRUE → FALSE`
  - Z. 403: `FALSE → TRUE`, `TRUE → FALSE`
  - Z. 406: `TRUE → FALSE`
  - Z. 418: `^ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 432: `* → /`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 433: `+ → -`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 434: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 439: `<non-empty string> → ""`
  - Z. 444: `TRUE → FALSE`
  - Z. 446: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`
  - Z. 449: `<= → <`, `<n> - 1 → <n> - 1`, `|| → &&`, `|| → &&`
  - Z. 450: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 453: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `== → !=`
  - Z. 455: `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`

- [E33] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 9 überlebende Mutanten in `R/fit.R`, `vc_from_model()`, `latent_residual()` — Vorschlag: Binäre und ordinale Fits mit Logit-Link prüfen die latente Restvarianz π²/3 (Z. 480) und dass die Zeile `Residual` genau einmal am Ende steht (Z. 467). Ferner den Typ der Spalte `source` (Z. 473).
  - Z. 467: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 473: `FALSE → TRUE`
  - Z. 480: `/ → *`, `^ → *`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`

- [E34] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 47 überlebende Mutanten in `R/fit.R`, `print.msa_fit()` — Vorschlag: Tests der Druckausgabe gegen dokumentierte Inhalte: Kopf mit Zielgröße und Zusatz zur latenten Skala, Formelzeile, Zählzeile mit Spanne der Replikate, `NA` statt Prozent bei Gesamtvarianz 0, Hinweis auf abgeleitete Komponenten in Einzahl und Mehrzahl, Hinweis auf singulären Fit. Wo es keine unabhängige Referenz gibt, als Momentaufnahme der eigenen Ausgabe gekennzeichnet.
  - Z. 484: `<non-empty string> → ""`
  - Z. 485: `!= → ==`, `"" → "mutant"`, `<condition> → !(<condition>)`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`
  - Z. 486: `"" → "mutant"`, `<non-empty string> → ""`, `<non-empty string> → ""`
  - Z. 487: `<non-empty string> → ""`
  - Z. 489: `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`, `x[<i>] → x[<i> - 1L]`
  - Z. 493: `* → /`, `/ → *`, `<condition> → !(<condition>)`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `== → !=`, `NA_real_ → NA`
  - Z. 495: `FALSE → TRUE`
  - Z. 496: `<condition> → !(<condition>)`
  - Z. 497: `<condition> → !(<condition>)`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `> → <`, `> → >=`
  - Z. 498: `<non-empty string> → ""`
  - Z. 499: `"" → "mutant"`, `<non-empty string> → ""`
  - Z. 501: `<condition> → !(<condition>)`
  - Z. 502: `<non-empty string> → ""`
  - Z. 503: `"" → "mutant"`, `<non-empty string> → ""`

- [E35] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 9 überlebende Mutanten in `R/grr.R`, `msa_grr()`, `grr_stats()` — Vorschlag: Tests für den Typ von `table$source` (character, Z. 87), die Zeilenbeschriftungen (Z. 79), Meldung und `conditionCall()` (Z. 50). Kandidaten für Verhaltensgleichheit, MUT-EQUIV-Antrag mit Begründung: Z. 68/76/88 `NA_real_ → NA` (Typanhebung in `vapply()`, Arithmetik und `c()`) und Z. 88 `> → >=` bei σ²_GRR = 0 (`max(1, floor(Inf))` ist `Inf`).
  - Z. 50: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 68: `NA_real_ → NA`
  - Z. 76: `NA_real_ → NA`
  - Z. 79: `<non-empty string> → ""`
  - Z. 87: `FALSE → TRUE`
  - Z. 88: `<n> - 1 → <n> - 1`, `> → >=`, `NA_real_ → NA`

- [E36] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 30 überlebende Mutanten in `R/grr.R`, `print.msa_grr()` — Vorschlag: Tests der Druckausgabe: Kopf mit Zählungen und Zusatz zur latenten Skala, ndc-Zeile, ICC-Zeile, Verdiktzeile mit Basis und beiden Schwellen, Hinweis auf singulären Fit; gekennzeichnet wie bei E34.
  - Z. 98: `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 99: `<non-empty string> → ""`
  - Z. 100: `<non-empty string> → ""`
  - Z. 101: `!= → ==`, `"" → "mutant"`, `<condition> → !(<condition>)`, `<non-empty string> → ""`, `<non-empty string> → ""`
  - Z. 106: `FALSE → TRUE`
  - Z. 107: `FALSE → TRUE`, `FALSE → TRUE`
  - Z. 109: `<non-empty string> → ""`
  - Z. 113: `<non-empty string> → ""`
  - Z. 114: `<non-empty string> → ""`
  - Z. 115: `<condition> → !(<condition>)`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `== → !=`
  - Z. 116: `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`, `x[<i>] → x[<i> - 1L]`
  - Z. 117: `<condition> → !(<condition>)`, `<non-empty string> → ""`

- [E37] (blocking) Gate mutgate (gate-mutgate.log des ersten Gate-Laufs der Runde 1 vor QA, Phasen-Commit a92396f: score=60.26 required=80; R/fit.R und R/grr.R byte-gleich mit HEAD) — 36 überlebende Mutanten in `R/grr.R`, `msa_boot()`, `print.msa_boot()` — Vorschlag: Test, dass `lower` und `upper` die Quantile von `attr(b, "boot")` zu (1 − level)/2 und 1 − (1 − level)/2 sind, für zwei Werte von `level` (Z. 166, 169). Ferner Meldungen (Z. 155, 158), Klasse (Z. 174) und Druckausgabe einschließlich `n_failed` (Z. 180–185). Z. 167 `na.rm` wirkt nach dem Filter `is.finite()` nicht: entfernen oder Äquivalenz beantragen.
  - Z. 155: `<non-empty string> → ""`, `FALSE → TRUE`
  - Z. 158: `FALSE → TRUE`
  - Z. 166: `/ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`
  - Z. 167: `TRUE → FALSE`
  - Z. 169: `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `FALSE → TRUE`, `x[<i>] → x[<i> + 1L]`, `x[<i>] → x[<i> - 1L]`, `x[<i>] → x[<i> - 1L]`
  - Z. 174: `<non-empty string> → ""`
  - Z. 180: `<non-empty string> → ""`
  - Z. 181: `* → /`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<non-empty string> → ""`, `<non-empty string> → ""`
  - Z. 183: `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`, `<n> + 1 → <n> + 1`
  - Z. 184: `FALSE → TRUE`
  - Z. 185: `<condition> → !(<condition>)`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`, `<non-empty string> → ""`, `<non-empty string> → ""`, `<non-empty string> → ""`, `> → <`, `> → >=`

### Nonblocking

- [E38] (minor) PLAN-REVIEW E13 („`?msa_plan` oder `NEWS.md` nennt, dass ein gescheiterter Fit die Planung beendet“); PLAN-REVIEW, Spec-Treue („Den neuen Fehler bei konstanten Werten und das geänderte Vorgabeverfahren nennen `NEWS.md` und `?msa_fit`.“) — **Befund:** `NEWS.md` nennt das neue Verfahren, aber weder die neuen benannten Fehler (konstante oder nicht endliche Antworten, degenerierte Restvarianz) noch, dass ein gescheiterter Fit `msa_plan()` beendet. `R/plan.R` und `man/msa_plan.Rd` sind unverändert; nur ADR-020 nennt das Verhalten. — **Vorschlag:** ein NEWS-Punkt und ein Satz in `?msa_plan` im Rework. BL-76.
- [E39] (minor) [Prozess, Betreiber] `orchestrator/handoff/M1a/QA.md` (QA-M1a-001, -003, -004) — **Befund:** Drei Sätze, die QA ADR-020 zuschreibt, stehen weder in ADR-020 noch sonst im Repository:
  - „Explizite `...`-Aufrufe gehen unverändert an `lme4::lmer()` und behalten ihre Steuerung.“
  - „Verschwindet im Modell die Restvarianz, bricht der Fit wegen nicht darstellbarer `theta = sigma_j / sigma_e` benannt ab.“
  - „Eingaben mit Unter- oder Überlauf der Modellvarianz auf Originalskala werden benannt abgelehnt.“

  QA-M1a-003 nennt den negativen Haupteffekt zudem „durch Rundung“; er ist echt negativ. Die Befunde selbst sind nachgerechnet und anders belegt (E18–E21). — **Vorschlag:** QA-Prompt und Template verlangen wörtliche, per `grep` prüfbare Zitate mit Fundstelle. Für den Builder nichts zu tun. BL-77.
- [E40] (minor) [INFRA] E12 aus PLAN-REVIEW M1a, Runde 2 (`verdict-plan.json`); ADR-019 — **Befund:** BACKLOG-Eintrag wie angekündigt. Umgesetzt durch ADR-019:
  - `MUT_TEST_EXCLUDE`;
  - Zeitlimit je Mutant mit unmutiertem Vorlauf und Faktor;
  - Abbruch bei rotem Vorlauf;
  - Flake-Rerun nur innerhalb von `MUT_FLAKE_MARGIN`.

  Runde 1: Vorlauf 85–88 s, muttest 11.895 s je Durchgang bei 14 Workern. — **Vorschlag:** als erledigt führen; die Laufzeit bleibt bei BL-13. BL-78.
- [E41] (minor) [INFRA] Gate mutgate (`orchestrator/gates.d/86-mutgate.sh`, `run_mutation()`: `rm -f "$REPO_ROOT/$MUT_REPORT" …`) — **Befund:** Jeder Gate-Lauf löscht den Bericht des vorigen. Nach dem roten Vorlauf gibt es keinen `mutation.json` mehr. Die Überlebenden kommen deshalb aus dem Log, mit der Bezeichnung der muttest-Ausgabe; dass sie dem `mutatorName` gleicht, auf den die Approval-Zuordnung prüft, ist nicht belegt. — **Vorschlag:** Der Betreiber archiviert den vollständigen Bericht je Gate-Lauf unter `orchestrator/state/<MS>/` oder hält den letzten vollständigen Bericht vor. Für den Builder nichts zu tun. BL-79.
- [E42] (minor) [Spec, Betreiber] docs/02, K-M1a-4 („Bei mittlerer Schwierigkeit (`SmLs04`–`SmLs06`, Werte um 10¹²)“) — **Befund:** SmLs04–SmLs06 liegen um 10⁶ (`SmLs04.csv`: 1000000.4); um 10¹² liegen SmLs07–SmLs09. Kriterium, Tests und Anker sind nicht betroffen. — **Vorschlag:** Spec-Text bei Gelegenheit berichtigen (nur Betreiber). BL-80.
- [E43] (minor) [M1b] QA.md, QA-M1a-004 Nr. 3 — **Befund:** Laut QA.md verwerfen clmm und glmer bei `type = "ordinal"` und `"binary"` Zeilen mit fehlenden Gruppierungswerten still, und `n` zählt sie mit. Vom Reviewer nicht nachgerechnet; nicht getestet; außerhalb von M1a. — **Vorschlag:** in M1b mit K-M1b-6 wie ADR-022 Nr. 2 behandeln. BL-81.

## MUT-EQUIV

Es gibt keinen `MUT-EQUIV.json` und damit keinen Antrag. `MUT-EQUIV-APPROVED.json` habe ich nicht angelegt.

## Verdict

**REWORK.**

- `gates.json` meldet `result: fail` (tests, mutgate).
- 20 Einwände sind blocking, jeder mit `ref`:
  - E18–E22: QA-Befunde, alle reproduziert und gültig;
  - E23: stille Ungenauigkeit des Originalskalenmodells;
  - E24–E37: mutgate mit den Überlebenden nach Datei und Stelle.
- Nonblocking: E38–E43, nachgetragen als BL-76 bis BL-81.
- Kein Spec-Widerspruch. ADR-022 hält die Auslegungen fest, wo die Spec schweigt; es bindet das Rework.

## Geschriebene Dateien

- `orchestrator/handoff/M1a/REVIEW.md` (diese Datei);
- `orchestrator/handoff/M1a/verdict-code.json` (`round: 1`);
- `docs/decisions/ADR-022-m1a-code-review-auslegungen.md`;
- `BACKLOG.md`: BL-76 bis BL-81 neu, dazu ein Laufzeit-Stand in BL-13.

Keine Git-Kommandos. Weder Produktcode noch Tests habe ich geändert, ebenso wenig Gates oder Orchestrator-Zustand.
