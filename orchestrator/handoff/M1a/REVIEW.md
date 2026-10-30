# REVIEW — M1a, Runde 2 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 2 · Stand: 30.10.2026

Gegenstand:
- der Diff seit `plan/M1a` (Tag-Objekt `a9d3f479…` → Commit `485c9605…`) bis HEAD `c47521a…`; Schwerpunkt ist der Rework-Commit `597b0c3…` gegenüber dem Review-Commit `595d240…` der Runde 1;
- die Gate-Fakten `orchestrator/state/M1a/gates.json` der Runde 2 (`env.sha` `597b0c3`) mit allen `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` und die acht Anträge in `MUT-EQUIV.json`.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- **Handoff M1a:**
  - `CRITERIA.json` (K-M1a-1 bis K-M1a-7, ACC-1 bis ACC-18);
  - `PLAN-UPDATE.md`, Abschnitte Schnittstellen, numerisches Verfahren, Wiederanpassung und Randfälle;
  - `PLAN.md` und `PLAN-REVIEW.md` nur über die Verweise in REVIEW r1, ADR-018 und ADR-022;
  - `QA.md`, `REVIEW.md` und `verdict-code.json` der Runde 1, `REWORK-NOTES.md`, `MUT-EQUIV.json`.
  - Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`. `MUT-EQUIV-APPROVED.json` gab es vor diesem Review nicht.
- **Spezifikation:**
  - K-M1a-1 bis K-M1a-7 im Wortlaut aus `CRITERIA.json`; das trace-Gate bestätigt die wörtliche Verknüpfung mit `docs/02-statistikkern.md`.
  - ADR-018, ADR-022 und den Rework-Nachtrag zu ADR-020 habe ich vollständig gelesen, ADR-020 sonst in den numerischen Abschnitten.
  - docs/01 §2 Nr. 4 und §5 über die Zitate in ADR-022.
- **Gates:** `gates.json` und alle acht `gate-*.log` der Runde 2; `reports/mutation/mutation.json` mit 1097 Mutanten.
- **Diff, vollständig gelesen:**
  - `R/fit.R` und `R/grr.R` ganz, dazu `R/plan.R`, `NEWS.md` und die drei Rd-Diffs (`msa_fit`, `msa_grr`, `msa_plan`);
  - `inst/validation/numeric/reference_checks.R` als Diff, dazu `validation_run()`;
  - den Nachtrag zu ADR-020 und `PROGRESS.md` (M1a r2);
  - die neuen Tests `helper-m1a-rework.R`, `test-fit-rework-inputs.R`, `test-fit-rework-numerics.R`, `test-grr-rework.R`, `test-validation-rework.R`;
  - zum Abgleich `tests/e2e/test-m1a-qa-e2e.R`, Z. 70–119 (QA-M1a-003).
- **Visuelle Artefakte:** keine; M1a fordert keine.

## Gate-Fakten

| Gate | Runde 2 (`gates.json`, `env.sha` `597b0c3`) |
| --- | --- |
| deps | pass (22 Anforderungen, R 4.6.1, Matrix 1.7.4 ≥ 1.6-0) |
| lint | pass (`R CMD check --as-cran`: Status OK, Vignetten neu gebaut) |
| tests | pass |
| trace | pass |
| territory | pass (builder/60-rework, Runde 2) |
| mutgate | pass: score=93.79 required=80 baseline=93.79 floor=80 |
| golden-adr | pass |
| mutfull | pass („nicht fällig in M1a“) |
| **result** | **pass** |

- **tests:**
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2477 ]`; der Skip ist der bekannte ellmer-Negativtest;
  - `tests/acceptance`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3070 ]`;
  - `tests/e2e`: `PASS 23`, `tests/fuzz`: `PASS 12`. Alle fünf QA-Tests (QA-M1a-001 bis -005) sind grün, unverändert.
  - Kurzbefund: „314 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“.
- **mutgate:**
  - unmutierter Vorlauf 90,4 s, 251 Tests, 0 rot; Zeitlimit 452 s je Mutant;
  - Bericht: 1097 Mutanten (`R/fit.R` 855, `R/grr.R` 242). Davon 935 Killed, 31 Timeout, 64 Survived, 0 NoCoverage und 67 RuntimeError.
  - Die Nachrechnung (Killed + Timeout) / (Killed + Timeout + Survived + NoCoverage) = 966 / 1030 ergibt 93,79 und trifft den Gate-Wert.
- **Status error:** keiner. Kein Gate-Befund ist [INFRA].
- **Laufzeit (BL-13):** Gate-Lauf 00:06–04:13, also ≈ 4 h 7 min:
  - lint ≈ 3 min;
  - tests ≈ 18,5 min (Abnahme 1038,1 s, testthat 65,1 s);
  - mutgate ≈ 3 h 45 min, ein muttest-Durchgang mit 13.432,7 s.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

**Methode:**
- Den Diff habe ich mit einem eigenen R-Leser für `.git/objects` gelesen (lose Objekte und Pack mit Deltas) und mit `diff -u` über `Rscript` verglichen.
- Gerechnet habe ich mit `pkgload::load_all()` gegen den Arbeitsbaum.
- Den Code von Runde 1 (`595d240`) und von v0.1.0 (`plan/M1a`) habe ich zum Vergleich in eine Kindumgebung des Namensraums geladen.
- Hilfsdateien lagen nur unter `reports/rv-m1a-r2/` (git-ignoriert, Artefakt-Allowlist) und sind gelöscht.

1. **Inventar.**
   - 87 Pfade seit `plan/M1a`.
   - Der Rework ändert 23 Pfade:
     - 17 Builder-Pfade: `R/fit.R`, `R/grr.R`, `R/plan.R`, drei Rd, `NEWS.md`, `PROGRESS.md`, ADR-020, `reference_checks.R`, fünf neue Testdateien, `REWORK-NOTES.md`, `MUT-EQUIV.json`;
     - sonst Orchestrator-Zustand und `STATUS.md`.
   - Rework → HEAD: 10 Pfade, nur Gate-Zustand und `STATUS.md`.
   - Blob-gleich mit `plan/M1a`: `tests/acceptance/**`, `reference/anchors/**`, `tests/fixtures/**`, `NAMESPACE`, `.Rbuildignore`, `tests/testthat.R`.
   - Im Rework unverändert: `DESCRIPTION`, `vignettes/validation.Rmd`, `inst/extdata/**` und alle bestehenden Testdateien.
   - Der Arbeitsbaum gleicht HEAD bis auf `STATUS.md` und `orchestrator/state/summary.json` (Orchestrator).
2. **E18, Refit.**
   - `msa_boot()` läuft auf einem Fit aus einer Hilfsfunktion mit lokaler `lmerControl(optimizer = "bobyqa")`. `refit()` meldet dann bobyqa.
   - Über eine weiterreichende Hilfsfunktion mit lokaler Steuerung ergibt sich ebenso bobyqa.
   - Der gespeicherte Aufruf enthält kein `..N`.
3. **E19, Durchreichweg.**
   - `subset = item != levels(item)[1]` mit `control = lmerControl()` auf `ic50_demo`: `nobs` 2098 gleich `n$observations`, `nrow(fit$data)` und `length(input_rows)`. Items 39 sind gleich den Stufen im Modell.
   - `subset = 1:200` endet wie der direkte `lmer`-Aufruf mit derselben Formel mit „grouping factors must have > 1 sampled level“. Das entspricht ADR-022 Nr. 1.1.
   - Über eine Hilfsfunktion weitergereichte `subset`-Werte werden nicht gefunden (E46).
4. **E20, Restvarianz null.**
   - Benannt enden:
     - balancierte Pläne (QA-Fall A; 5 × 3 × 3 mit identischen Replikaten), ohne Warnung;
     - der unbalancierte Einwegplan (QA-Fall B);
     - QA-Fall A ohne Zeile 1 oder ohne Zeilen 1 und 6 („… cannot be resolved at working precision.“, mit weitergegebenen lme4-Startwarnungen).
   - **Nicht benannt** endet QA-Fall A mit einem einzigen fehlenden Wert (`value[16] <- NA`): „Downdated VtV is not positive definite“ (Klasse `Rcpp::exception`). Ebenso endet ein 5 × 3-Plan mit drei identischen Replikaten (Zellwerte `rnorm`, Seed 7) ohne Zeile 1 oder ohne Zeilen 1, 17 und 33.
     - Unabhängig mit `aov` nachgerechnet: Restquadratsumme 4,0e-30 auf 7 FG bei SST 36,48, Verhältnis 1,1e-31. Das liegt unter der Grenze (64 · eps)² = 2,0e-28 aus ADR-020.
     - Ohne Wechselwirkung läuft derselbe Datensatz (σ²_e = 2,591).
     - Runde 1 und v0.1.0 liefern denselben Rohfehler (E44).
5. **E21, Darstellbarkeit.**
   - Messwerte × 1e-161, × 1e-160 und × 1e-158 enden benannt („… not representable …“).
   - × 1e-155 bis × 1e153 rechnen; zurückskaliert höchstens 1,0e-13 · σ²_TV vom unskalierten Fit.
   - × 1e154 und × 1e155 (Überlauf) enden benannt.
   - Beide NaN-Formen und fehlende Gruppierungswerte auf beiden Pfaden prüft der Builder-Test; der QA-Test ist grün.
6. **E22.**
   - Die Schwellen `c(30, 10)`, `c(-5, 30)`, `"invalid"`, `10` und `c(NA, 30)` enden mit „`threshold` must contain two finite, nonnegative, nondecreasing numbers.“
   - `c(10, 10)` und `c(0, 30)` ergeben ein Verdikt (ADR-022 Nr. 4).
   - Die Manifestprüfung folgt ADR-022 Nr. 5; Diff und Tests habe ich gelesen.
7. **E23, Präzision des Originalskalenmodells.**
   - `ic50_demo` + c, verglichen mit denselben, gleich gerundeten Daten ohne Offset:

     | c | Abweichung · σ²_TV |
     | --- | --- |
     | 100 | 8,8e-16 |
     | 1e4 | 3,8e-13 |
     | 1e6 | 4,3e-11 |
     | 1e7 | 8,6e-10 |

     Ab c = 3e7 folgt der benannte Fehler. `ANK-TOL.invariance` beträgt 1e-6.
   - NIST, öffentliche Kopien:
     - SiRstv, SmLs01–SmLs06 und AtmWtAg laufen über `closed_form`.
     - LRE von `msa_fit` gegen `aov`:

       | Datensatz | `msa_fit` (Rest / Item) | `aov` (Rest / Item) |
       | --- | --- | --- |
       | SmLs04 | 10,81 / 10,27 | 10,29 / 10,04 |
       | SmLs05 | 10,24 / 9,92 | 10,29 / 9,94 |
       | SmLs06 | 10,29 / 9,94 | 10,29 / 9,94 |

     - SmLs07–SmLs09 enden benannt. `validation_run()` zeigt sie als `NA` mit dem Grund in der Diagnosetabelle (ADR-022 Nr. 6.3).
8. **MUT-EQUIV:** jeden Antrag einzeln und unabhängig von den Builder-Belegen unter `/tmp/llmsa-m1a-r2/` nachgeprüft (Abschnitt MUT-EQUIV).

## Bewertung

### Spec- und Vertragstreue

- K-M1a-1 bis K-M1a-7: Alle Abnahmetests sind grün, die Vignette baut im lint-Gate. Die Prüfungen von SmLs04–SmLs06 halten die Marge aus `ANK-TOL.nist_digits`.
- ADR-022:
  - Nr. 1 bis 6 sind erfüllt (Nachprüfungen 2, 3 und 5 bis 7).
  - Nr. 7 ist nur für balancierte Pläne, Einwegpläne und den analytischen Abschluss erfüllt. Im unbalancierten Mehrfaktorplan endet der Vorgabepfad noch roh (E44).
  - Das betrifft auch ADR-018 Nr. 3, die Zusage in `?msa_fit` (`R/fit.R:71–72`) und die Tabelle „Randfälle“ im PLAN-UPDATE.
- ADR-018 Nr. 1 bleibt gewahrt: `vc` stammt aus `VarCorr(model)`. Die Prüfung nach dem Modellbau (`R/fit.R:507–511`) wirft einen Fehler und setzt keine zweite Tabelle daneben.
- Kein Widerspruch zwischen Spec-Stellen, also kein ESCALATE.

### API-Diff

- `NAMESPACE` ist byte-gleich; Signaturen und Vorgaben sind gleich (`m0-api-snapshot` grün).
- Neu sind benannte Fehler:
  - in `msa_fit()`: Gruppierungswerte, Restvarianz, Darstellbarkeit;
  - in `msa_grr()`: `threshold`.
- `NEWS.md`, `?msa_fit` und `?msa_grr` nennen sie, `?msa_plan` den Abbruch der Planung (E38 erledigt).
- Der gespeicherte Modellaufruf enthält jetzt den Datenrahmen als Wert (E45).

### Integrität

- **Entkernte oder geänderte Tests:** keine. Der Rework fügt fünf Testdateien hinzu und ändert keine bestehende. Abnahme-, QA- und Fixture-Dateien sind blob-gleich.
- **Gelockerte Konfiguration:** keine.
- **Harte Erwartungswerte:** keine. Die neuen Konstanten in `R/fit.R` stammen aus der Maschinenarithmetik und stehen in ADR-020:
  - (64 · eps)²;
  - `sqrt(eps)`;
  - `double.xmin · double.eps`.
- **Erfundene Daten:** keine.
- **Golden-Daten:** im Rework unverändert.
- Der Builder hat die tote Neuberechnung von `residual_v` nach `variance <- 0` entfernt. Der zurückgegebene Quotient ist ohnehin 0; die Restvarianz bestimmt danach das REML-Kriterium, der Test vergleicht sie mit `var()`. Ebenso hat er `na.rm` nach dem Filter `is.finite()` entfernt. Beides ist verhaltensgleich.

### Neue Tests

- Die neuen Tests belegen Verhalten gegen unabhängige Referenzen:
  - EMS aus `stats::aov` mit eigener Koeffizientenmatrix;
  - direkte `lme4::lmer`-, `bootMer`-, `VarCorr`- und `ordinal::VarCorr`-Aufrufe;
  - dichte projizierte Kovarianzformel für die Informationsmatrix;
  - Richardson-Differenzenquotienten der lme4-Devianzfunktion;
  - von Hand hergeleitete Newton-Schritte auf Quadratiken und Quartiken;
  - `stats::quantile` und Formeln mit ANK-16.
- Die Konstanten des Abschlusses (Rundungsreserve, Armijo, Normen) prüfen die Tests gegen ADR-020.
- Momentaufnahmen der eigenen Ausgabe gibt es nur für Wortlaut und Layout von Meldungen und Druck, jeweils gekennzeichnet:
  - `helper-m1a-rework.R:16–18`;
  - `test-grr-rework.R:60–61, 95, 144–145`;
  - `test-fit-rework-inputs.R:218–219`.

  Die Zahlen darin prüft jeweils ein Formeltest.
- Lücken, ohne Gate-Wirkung (mutgate grün): E47.

## Stand der Einwände aus Runde 1

Der Builder beantwortet alle 26 IDs Punkt für Punkt (REWORK-NOTES).

| ID | Stand | Beleg |
| --- | --- | --- |
| E18 | erledigt | Nachprüfung 2; `test-fit-rework-inputs.R:1–33` |
| E19 | erledigt | Nachprüfung 3; Tests mit Ausdrucks-Subset, Index-Subset mit Dubletten, `NA`-Gewichten und `na.exclude`; Hinweis E46 |
| E20 | **teilweise** | balanciert, Einweg und Abschluss benannt; unbalancierter Mehrfaktorplan roh → E44 |
| E21 | erledigt | Nachprüfung 5 |
| E22 | erledigt | Nachprüfung 6 |
| E23 | erledigt | Nachprüfung 7 |
| E24 | erledigt | Vorlauf grün, mutgate 93,79 ≥ 80 |
| E25–E37 | durch das Gate erledigt | 64 Überlebende, davon 10 als äquivalent freigegeben; Hinweise in E47 |
| E38 | erledigt | `NEWS.md`, `?msa_plan`; BL-76 gestrichen |
| E39 | offen, Betreiber | BL-77 |
| E40 | erledigt | BL-78 |
| E41 | offen, Betreiber | BL-79; in Runde 2 lag `mutation.json` vor |
| E42 | offen, Betreiber | BL-80 |
| E43 | vertagt nach M1b | BL-81 |

## Einwände

### Blocking

- [E44] (blocking) ADR-022 Nr. 7 („Die Meldung nennt „residual variance“.“) mit Konsequenzen („Blocking-Befund mit Bezug auf dieses ADR ist … jeder Fehler ohne benannte Meldung nach Nr. 2, 4, 5 oder 7.“); ADR-018 Nr. 3 („`msa_fit()` endet mit einer benannten englischen Fehlermeldung (docs/01 §2 Nr. 4), wenn … das Problem kein endliches Optimum hat, etwa bei Restvarianz 0.“); PLAN-UPDATE, Randfälle („Ist das restringierte Optimum ohne positive Restvarianz und damit ohne endliches darstellbares Theta, benannter Fehler über die degenerierte Restvarianz“); REVIEW r1 E20 und QA-M1a-003 (Titel: „… in mehrfaktoriellen balancierten sowie in unbalancierten Designs …“) — **Befund:**
  - Der Vorgabepfad erkennt verschwindende Restvarianz an drei Stellen:
    - im balancierten Plan (`R/fit.R:282`);
    - im unbalancierten Einwegplan (`R/fit.R:257–260`);
    - im analytischen Abschluss (`R/fit.R:323–328`, `336`).
  - Bei unbalancierten Plänen mit mehreren Termen gibt `msa_numeric_balanced()` ohne Prüfung `NULL` zurück (`R/fit.R:256–261`). Der lme4-Startfit auf der konditionierten Antwort (`R/fit.R:453`) bricht dann mit einem rohen C++-Fehler ab.
  - Reproduktion: QA-M1a-003 Fall A (4 Items × 2 Prompts × 2 Replikate, identische Replikate, `interactions = TRUE`) mit einem fehlenden Wert, `value[16] <- NA`. `msa_fit()` endet mit „Downdated VtV is not positive definite“ (`Rcpp::exception`); „residual variance“ kommt nicht vor.
  - Unabhängig: Restquadratsumme aus `aov` 4,0e-30 auf 7 FG bei SST 36,48, unter der eigenen Grenze aus ADR-020. Ohne Wechselwirkung rechnet derselbe Datensatz normal.
  - Ebenso endet ein 5 × 3-Plan mit drei identischen Replikaten nach Entfernen einer Zeile (Nachprüfung 4).
  - Kein Rückschritt: Runde 1 und v0.1.0 enden gleich. `?msa_fit` sichert aber zu: „a degenerate residual variance produce named errors“.
  - Deterministische LLM-Studien (gleiche Antwort je Zelle) mit einzelnen fehlenden Antworten treffen genau diesen Fall.

  — **Vorschlag:**
  - Die Restvarianz im allgemeinen Pfad vor dem Startfit prüfen: etwa der Kleinste-Quadrate-Rest der konditionierten Antwort auf span(1, Z), mit Z aus `lf$reTrms$Zt`, über `msa_numeric_check_residual()`.
    - Das verallgemeinert die vorhandenen Prüfungen; balanciert und Einweg sind Spezialfälle.
    - Alternativ den Startfit abfangen und den Fehler über diese Prüfung benennen.
  - Keine absolute Grenze, keine künstliche Reststreuung (PLAN-UPDATE, Randfälle).
  - Unit-Tests: QA-Fall A mit `value[16] <- NA` und mit einer entfernten Zeile.
    - Verlangt: die benannte Meldung, kein Rohfehler aus lme4 oder Matrix.
    - Der Gegenfall mit ausgelassener Wechselwirkung (positive Restvarianz) bleibt grün.
  - Der Durchreichweg bleibt lme4 (ADR-018 Nr. 2).

### Nonblocking

- [E45] (minor) ADR-022 Nr. 1.3 (Werte verlangt nur für „`control` und alle übrigen nicht datenbezogenen Argumente“); lme4 `.prt.call()` (druckt `call$data`, `call$weights`, `call$offset` und `call$control` per `deparse()`) — **Befund:**
  - Beide numerischen Wege legen den analysierten Datenrahmen als Wert in `fit$model@call` ab: `R/fit.R:192` über `do.call` und `R/fit.R:503`. Der Durchreichweg legt dort auch `subset`, `weights` und `offset` als Werte ab.
  - Auf `ic50_demo`:
    - `print(fit$model)`: 313 Zeilen;
    - `summary(fit$model)`: 321 Zeilen, beginnend mit `Data: structure(list(item = structure(c(1L, …`;
    - `deparse(getCall(fit$model))`: 813 Zeilen.
  - In Runde 1 stand dort `Data: dat`. `update()`, `refit()` und `msa_boot()` laufen.

  — **Vorschlag:**
  - Den Aufruf selbsttragend halten, ohne Daten einzubetten. Etwa: `data` als Symbol, gebunden in einer mit dem Modell gespeicherten Umgebung; `lme4::update.merMod` wertet zuerst in `environment(formula(object))` aus.
  - Oder das Verhalten in `?msa_fit` nennen.
  - Test: `print(fit$model)` zeigt eine kurze `Data:`-Zeile; `update()`, `refit()` und `msa_boot()` laufen nach `serialize()`.
  - BL-82.
- [E46] (minor) ADR-022 Nr. 1.1; `?msa_fit`, `@param ...` („Other arguments are evaluated in the caller's environment.“) — **Befund:**
  - `subset`, `weights` und `offset` werden in `dat` mit `parent.frame()` als Rahmen ausgewertet (`R/fit.R:184–189`).
  - Über eine weiterreichende Hilfsfunktion (`wrap <- function(r, ...) msa_fit(r, ...)`) findet `msa_fit()` eine lokale Variable des äußeren Aufrufers nicht, auch als fertigen Vektor nicht: „object 'sel' not found“. `control` geht über denselben Weg durch (Promise, `R/fit.R:190`).
  - Der direkte lme4-Aufruf hat dieselbe NSE-Grenze; Nr. 1.1 ist also erfüllt. `?msa_fit` sagt aber nicht, wo andere Symbole dieser Ausdrücke gesucht werden.

  — **Vorschlag:** ein Satz in `?msa_fit`, wahlweise eine robustere Auswertung mit Test über eine Hilfsfunktion. BL-83.
- [E47] (minor) Gate mutgate (grün, score=93.79; Überlebende in `reports/mutation/mutation.json`; ohne Gate-Wirkung) — **Befund:** Einige Überlebende liegen in Code, der Befunde der Runde 1 trägt:
  - `R/fit.R:254` `NULL → NA`: kein Test mit weniger Zeilen als Zellen; der Mutant würde solche Fits brechen. E28 verlangte Tests der Anwendbarkeitsgrenzen.
  - `R/fit.R:336` `^ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`: Die Q-Prüfung des Abschlusses entscheidet in keinem Test.
  - Darstellbarkeitsprüfung: kein Fall trennt die Komponenten vom Rest oder die zweite Prüfung von der ersten. Betroffen sind:
    - `R/fit.R:486` `> → <` und `<n> + 1 → <n> + 1`;
    - `:487` `|| → &&`, `<= → <` und `<n> - 1 → <n> - 1`;
    - `:488` `> → >=`;
    - `:508` `|| → &&`;
    - `:509` `> → >=`.

  — **Vorschlag:** mit E44 Tests für einen dünn besetzten Plan, für den Abschluss mit Q nahe 0 und für eine positive Komponente mit sehr kleinem Verhältnis bei darstellbarem Rest. Nicht verlangt. BL-84.
- [E48] (minor) [INFRA] Gate mutgate (`orchestrator/gates.d/86-mutgate.sh:38–41`: Zuordnung über `endswith(file)`, `mutatorName` und `location.start.line`) — **Befund:**
  - Eine Approval gilt für jede überlebende Mutante mit gleicher Datei, gleichem `mutatorName` und gleicher Anfangszeile.
  - Verschiebt ein Rework die Zeilen, trifft eine alte Approval andere Mutanten. `mutation.json` trägt den Quelltext, die Zuordnung prüft ihn nicht.
  - Die Approvals dieser Runde gelten für den Stand `597b0c3` (Abschnitt MUT-EQUIV).

  — **Vorschlag:**
  - Betreiber: die Approval um den Quelltext der Zeile oder dessen Hash ergänzen und im Gate vergleichen.
  - Bis dahin prüft das Review jeder Runde jede Approval gegen den aktuellen Bericht.
  - Für den Builder nichts zu tun. BL-85.
- [E49] (minor) [INFRA] `REWORK-NOTES.md`, „OUT-OF-TERRITORY: lokale Infrastruktur“ (M1a-R2-INFRA-MUT-DISPATCH, M1a-R2-INFRA-CLOCK) — **Befund:**
  - In der Builder-Sandbox endet `mirai::daemons(1L)` mit „16 | Permission denied“. Der Builder kann den Mutationstreiber des Gates nicht nutzen und hat eine eigene Diagnose gerechnet, korrekt als kein Gate-Ersatz gekennzeichnet.
  - Lokales `R CMD check` meldet „Unable to verify current time“; im lint-Gate ist die Prüfung OK.

  — **Vorschlag:** Der Betreiber prüft, ob die Builder-Sandbox lokale Sockets für mirai erlauben kann, oder hält im RUNBOOK fest, dass Mutationsläufe nur im Gate laufen. Für den Builder nichts zu tun. BL-86.

## MUT-EQUIV

**Grundlage:**
- acht Anträge in `MUT-EQUIV.json`, die zehn überlebende Mutanten im Gate-Bericht betreffen;
- jeden habe ich gegen `reports/mutation/mutation.json` (Datei, `mutatorName`, Zeile, Status Survived) und den Quelltext geprüft.

**Ergebnis:** Alle acht sind echte Äquivalenzen und stehen in `MUT-EQUIV-APPROVED.json`.

| Datei:Zeile | `mutatorName` | Quelltext (Stand `597b0c3`) | Nachprüfung |
| --- | --- | --- | --- |
| `R/fit.R:222` | `+ → -` (3 Mutanten) | `stats::aggregate(y ~ item + prompt + model + block, …)` | `model.frame()` baut aus `attr(terms(), "variables")` = `list(y, item, prompt, model, block)`, unabhängig von `-`. `aggregate()` ist auf 200 Zufallsplänen identisch, auch mit `NA` in `prompt` und `y`. |
| `R/fit.R:102` | `FALSE → TRUE` | `as.data.frame(runs, stringsAsFactors = FALSE)` | Kein `as.data.frame`-Verfahren für `msa_runs`. `as.data.frame.data.frame(x, row.names, ...)` verwirft das Argument. Für `msa_runs` mit Zeichenspalten und für `msa_simulate()` identisch, sogar für eine schlichte Liste Ende-zu-Ende. |
| `R/fit.R:341` | `<n> + 1 → <n> + 1` | `gram <- curvature <- matrix(0, k, k)` | Die Doppelschleife schreibt jedes Element vor dem ersten Lesen. REML-Zustand für die Startwerte 1, −1 und `NA` auf vier λ-Vektoren identisch; `NA` belegt, dass der Startwert nie gelesen wird. |
| `R/fit.R:341` | `<n> - 1 → <n> - 1` | wie oben | wie oben |
| `R/fit.R:442` | `TRUE → FALSE` | `lme4::lFormula(form, data = scaled, REML = TRUE, …)` | `lFormula` nutzt `REML` nur im Rückgabewert (`c(res, list(REML = REML))`). `lf` dient nur `reTrms$cnms`, `$Gp` und `$Zt`. `reTrms`, `fr` und `X` sind auf sechs Plänen identisch. |
| `R/fit.R:444` | `TRUE → FALSE` | `strsplit(names, ":", fixed = TRUE)` | `:` ist kein Metazeichen. Die Teilung ist identisch, auch für `"a::b"`, `":x"`, `"x:"` und `""`. |
| `R/fit.R:450` | `TRUE → FALSE` | `on.exit(…, add = TRUE)` | einziges `on.exit` in `msa_numeric_fit()` |
| `R/grr.R:94` | `> → >=` | `… else if (grr_v > 0) max(1, floor(…)) else Inf` | Identisch auf 512 nichtnegativen Kombinationen, auch −0, subnormal und `Inf`. Abweichung nur bei negativer Item-Varianz, die `msa_fit()` nie liefert (ADR-018 Nr. 1 (d)). |

- **Wirkung:** Auf denselben Bericht angewandt ergäben die Freigaben 966 / 1020 = 94,71. `mut-baseline` (93.79) schreibt nur das Gate.
- **Bindung an den Stand:**
  - Die Freigaben gelten für die Zeilen von `597b0c3`.
  - Verschiebt der Rework zu E44 diese Zeilen, beantragt der Builder die betroffenen Äquivalenzen in `MUT-EQUIV.json` mit den neuen Zeilen neu.
  - Das Review der Runde 3 gleicht jede Freigabe mit dem neuen Bericht ab und entfernt veraltete (E48).

## Verdict

**REWORK.**

- `gates.json` meldet `result: pass`. `blocking` ist aber nicht leer: E44 mit Bezug auf ADR-022 Nr. 7, ADR-018 Nr. 3 und das PLAN-UPDATE.
- Nonblocking: E45–E49, nachgetragen als BL-82 bis BL-86. BL-76 ist gestrichen, BL-13 hat einen Laufzeit-Stand bekommen.
- Kein Spec-Widerspruch. E44 braucht keine neue Auslegung, ADR-022 Nr. 7 deckt den Fall.

## Geschriebene Dateien

- `orchestrator/handoff/M1a/REVIEW.md` (diese Datei);
- `orchestrator/handoff/M1a/verdict-code.json` (`round: 2`);
- `orchestrator/handoff/M1a/MUT-EQUIV-APPROVED.json` (acht Freigaben);
- `BACKLOG.md`: BL-82 bis BL-86 neu, BL-76 erledigt, Laufzeit-Stand in BL-13.

Keine Git-Kommandos. Ich habe weder Produktcode noch Tests, Gates oder Orchestrator-Zustand geändert.
