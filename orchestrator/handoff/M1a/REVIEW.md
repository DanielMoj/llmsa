# REVIEW — M1a, Runde 3 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 3 · Stand: 30.10.2026

Gegenstand:
- der Diff seit `plan/M1a` (Commit `485c9605…`) bis HEAD `3441b49…`; Schwerpunkt ist der Rework-Commit `173a536…` gegenüber dem Review-Commit `380e40c…` der Runde 2;
- die Gate-Fakten `orchestrator/state/M1a/gates.json` der Runde 3 (`env.sha` `173a536`) mit allen `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` und die acht Anträge in `MUT-EQUIV.json`.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- **Handoff M1a:**
  - `CRITERIA.json` (K-M1a-1 bis K-M1a-7);
  - `REVIEW.md` und `verdict-code.json` der Runde 2, `REWORK-NOTES.md` der Runde 3, `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json` (Stand Runde 2);
  - `QA.md` (QA-M1a-001 bis -005);
  - `PLAN-UPDATE.md`, Abschnitt „Randfälle und gemeinsame GRR-Berechnung“ (Z. 306–316).
  - Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`.
- **Spezifikation:**
  - K-M1a-1 bis K-M1a-7 im Wortlaut (`docs/02-statistikkern.md` Z. 10–16); das trace-Gate bestätigt die wörtliche Verknüpfung;
  - `docs/01-fachspezifikation.md` §2 Nr. 4 und §4; `docs/02` Z. 55–60 (S-boot) und Z. 74 (M1d);
  - ADR-018 Nr. 1 bis 5, ADR-020 mit den Nachträgen der Runden 2 und 3, ADR-022 vollständig.
- **Gates:** `gates.json` und alle acht `gate-*.log` der Runde 3; `mutation.json` mit 1106 Mutanten; zum Vergleich `gate-mutgate.log` der Runde 2 aus Commit `c47521a`.
- **Diff, vollständig gelesen:**
  - `R/fit.R` ganz (Stand `173a536`), `R/grr.R` Z. 1–100;
  - die Diffs zu `NEWS.md`, `man/msa_fit.Rd`, ADR-020 und `PROGRESS.md`;
  - die neue Datei `tests/testthat/test-fit-residual-design.R` ganz, dazu `helper-m1a-rework.R` und `helper-validation-numeric.R`.
- **Visuelle Artefakte:** keine; M1a fordert keine.

## Gate-Fakten

| Gate | Runde 3 (`gates.json`, `env.sha` `173a536`) |
| --- | --- |
| deps | pass (22 Anforderungen, R 4.6.1, Matrix 1.7.4 ≥ 1.6-0) |
| lint | pass (`R CMD check --as-cran`: Status OK, Vignetten neu gebaut) |
| tests | pass |
| trace | pass |
| territory | pass (builder/60-rework, Runde 3) |
| mutgate | pass: score=93.72 required=91.79 baseline=93.79 floor=80 |
| golden-adr | pass |
| mutfull | pass („nicht fällig in M1a“) |
| **result** | **pass** |

- **tests:**
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2601 ]` (Runde 2: 2477; die 124 neuen Erwartungen stammen aus der neuen Datei); der Skip ist der bekannte ellmer-Negativtest;
  - `tests/acceptance`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3070 ]`, unverändert;
  - `tests/e2e`: `PASS 23`, `tests/fuzz`: `PASS 12`; alle QA-Tests grün und unverändert.
- **mutgate:**
  - unmutierter Vorlauf 89,7 s, 259 Tests, 0 rot; Zeitlimit 449 s je Mutant;
  - Bericht: 1106 Mutanten (`R/fit.R` 864, `R/grr.R` 242): 939 Killed, 31 Timeout, 66 Survived, 0 NoCoverage, 70 RuntimeError;
  - `required` 91,79 = Baseline 93,79 − Ratchet 2.
  - Nachrechnung mit der Zuordnung des Gates: 970 / (970 + 66 − 1) = 93,72 trifft den Gate-Wert. Von den acht Approvals der Runde 2 traf nur `R/grr.R:94` noch einen Überlebenden; die sieben `R/fit.R`-Einträge zeigten auf verschobene Zeilen ohne passenden Überlebenden. E48 hat den Score also nicht verfälscht. Ohne jede Approval: 93,63, ebenfalls über der Schwelle.
- **Status error:** keiner. Kein Gate-Befund ist [INFRA].
- **Laufzeit (BL-13):** Gate-Lauf 08:30–13:17, also ≈ 4 h 47 min:
  - lint ≈ 3 min;
  - tests ≈ 18 min (Abnahme 1038,4 s, testthat 66,1 s, e2e 2,8 s, fuzz 1,1 s);
  - mutgate ≈ 4 h 26 min, ein muttest-Durchgang mit 15.860,8 s (Runde 2: 13.432,7 s), 31 Timeouts.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

**Methode:**
- Den Diff habe ich mit einem eigenen R-Leser für `.git/objects` gelesen (lose Objekte und Pack mit Deltas) und mit `diff -u` verglichen.
- Gerechnet habe ich mit `pkgload::load_all()` gegen den Arbeitsbaum. Für alle Dateien der Runde 3 ist er per MD5 gleich den HEAD-Blobs.
- Den Code von Runde 2 (`380e40c`) und von v0.1.0 (`plan/M1a`) habe ich zum Vergleich in Kindumgebungen des Namensraums geladen.
- Hilfsdateien lagen nur unter `reports/rv-m1a-r3/` (git-ignoriert, Artefakt-Allowlist) und sind gelöscht.

1. **Inventar.**
   - 92 Pfade seit `plan/M1a`.
   - Der Rework ändert 14 Pfade:
     - 8 Builder-Pfade: `R/fit.R`, `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md`, ADR-020, die neue `tests/testthat/test-fit-residual-design.R`, `REWORK-NOTES.md`, `MUT-EQUIV.json`;
     - sonst Orchestrator-Zustand und `STATUS.md`.
   - Rework → HEAD: 9 Pfade, nur Gate-Zustand und `STATUS.md`.
   - Seit `plan/M1a` unberührt: `tests/acceptance/**`, `reference/anchors/**`, `tests/fixtures/**`, `NAMESPACE`, `tests/testthat.R`, `.Rbuildignore`.
   - Im Rework unverändert: `R/grr.R`, `DESCRIPTION`, `inst/**`, `vignettes/**` und alle bestehenden Testdateien.
   - Der Quelltext im Mutationsbericht gleicht dem Arbeitsbaum (`R/fit.R` SHA-256 `6ab0a2a5…`; Ausgangsstand `a8252955…` wie in REWORK-NOTES).
2. **Produktdiff.**
   - Neu ist nur `R/fit.R:460–466`: der Kleinste-Quadrate-Rest der konditionierten Antwort auf span(Z) über `stats::lm.fit(as.matrix(Matrix::t(Zt)))`. Geprüft wird nur bei `rank < N`, mit der unveränderten Grenze aus `msa_numeric_check_residual()`.
   - `sum(scaled$y^2)` ist die zentrierte SST, denn `msa_numeric_condition()` zentriert (`R/fit.R:252–253`).
   - Sonst nur roxygen-Sätze zu E45 und E46.
   - Mathematisch stimmig:
     - Liegt y in span(1, Z) und gilt N > rang(Z), fällt das REML-Kriterium entlang θ = t · θ₀ wie 2 (rang(Z) − N) log t ohne untere Schranke. Ein endliches Optimum gibt es dann nicht.
     - Liegt y nicht in diesem Raum, bleibt die penalisierte Restquadratsumme nach unten beschränkt.
     - Die Prüfung trifft also genau den Fall aus ADR-018 Nr. 3. Den gesättigten Fall (rang = N) nimmt sie zu Recht aus.
3. **E44, Reproduktionen.**
   - Benannt enden jetzt („Degenerate numeric model: residual variance is zero at working precision.“, ohne Warnung):
     - QA-Fall A mit `value[16] <- NA` und QA-Fall A ohne Zeile 1;
     - der 5 × 3-Plan mit Seed 7 ohne Zeile 1 und ohne Zeilen 1, 17 und 33.
     - In Runde 2 endeten sie mit `Rcpp::exception` beziehungsweise „cannot be resolved“.
   - Eigene degenerierte Pläne außerhalb der Builder-Tests, ebenfalls benannt:
     - additive Daten ohne Wechselwirkung (6 × 3 × 2, drei Zeilen entfernt; aov-RSS/SST 2,4e-31). Runde 2 endete hier mit „Downdated VtV …“;
     - zwei Modelle und zwei Blöcke mit Wechselwirkungen, vier Zeilen entfernt (3,1e-30);
     - QA-Fall A mit + 1e6, × 1e-150, × 1e150 und × (−1).
   - Gegenfälle laufen:
     - identische Replikate mit Dreifachstruktur (5 × 3 × 3, außerhalb des Modellraums; aov-RSS/SST 0,34) fittet unverändert;
     - `ic50_demo` mit Zellmitteln fittet über `closed_form`;
     - 20 LLM-artige Ganzzahlpläne (12 × 3 × 3 × 3, je 10 fehlende Antworten) fitten alle.
4. **Positive Restvarianz unverändert.**
   - 40 Zufallspläne aus `msa_simulate()` (balanciert und unbalanciert, mit und ohne Wechselwirkung): 37 haben `vc`, `numerics` und Warnungen identisch zu Runde 2.
   - Die drei übrigen (ein Replikat je Zelle mit Wechselwirkung) enden in beiden Ständen und wie v0.1.0 mit der lme4-Meldung „number of levels of each grouping factor must be < number of observations (problems: item:prompt)“.
   - Der gesättigte Sechszeilenplan mit 30 Seeds verhält sich in beiden Ständen gleich: 23 Fits, 7 × „Analytic REML did not converge“.
5. **Kleine positive Restvarianz.**
   - Aufbau: Rauschen e · `rnorm()` auf die identischen Replikate von vier Plänen, e = 1e-3 bis 1e-13, je 5 Seeds; 220 Fits.
   - Runde 3 und Runde 2 enden in allen 220 Fällen gleich.
   - 42 Fits enden roh mit `Rcpp::exception` „Downdated VtV is not positive definite“, alle bei e ≤ 1e-7, also RSS/SST ≈ 1e-15 bis 1e-27, oberhalb der Nullgrenze 2,0e-28 → **E50**.
   - Bei e = 1e-3 bis 1e-6 enden viele Fits benannt mit „did not converge“ oder „not identifiable“ → E51.
6. **Hohe Wiederholpräzision in typischen Plänen.**
   - Aufbau: vier `msa_simulate()`-Szenarien, Rest 1e-2, 1e-4 und 1e-6 bei Item 1, balanciert und mit 10 % entfernten Zeilen, je 4 Seeds; 96 Fits.
   - Der Vorgabepfad endet 6-mal mit „Analytic REML did not converge“ (Rest 1e-4: 1-mal; 1e-6: 5-mal); v0.1.0 fittet alle 96 → E51.
7. **Laufzeit der Projektion:**

   | Plan | N × q | dicht | Projektion | `msa_fit` Runde 2 → 3 |
   | --- | --- | --- | --- | --- |
   | AP1-Gesamtplan (100 × 3 × 3 × 3 × 2, 5 % fehlend) | 5130 × 717 | 28,1 MiB | 0,76 s | 1,73 → 2,50 s (Faktor 1,44) |
   | 200 × 6 × 3 × 2, 5 % fehlend | 6840 × 2027 | 105,8 MiB | 7,66 s | 23,8 → 32,1 s (Faktor 1,35) |

   Die Ergebnisse sind identisch, der erkannte Rang stimmt (1610 = 1 + 199 + 5 + 2 + 995 + 398 + 10) → E52.
8. **Überlebende im Vergleich zu Runde 2:** 64 → 66; vier getötet, sechs neu → E53.
9. **MUT-EQUIV:** jeden Antrag einzeln gegen Bericht und Quelltext geprüft (Abschnitt MUT-EQUIV).

## Bewertung

### Spec- und Vertragstreue

- K-M1a-1 bis K-M1a-7: Alle Abnahmetests sind grün, die Vignette baut im lint-Gate.
- E44 ist für seinen Gegenstand erledigt. ADR-022 Nr. 7 („Restquadratsumme in der Größenordnung der Rundung“) und ADR-018 Nr. 3 („kein endliches Optimum … etwa bei Restvarianz 0“) gelten jetzt auch für unbalancierte Mehrfaktorpläne:
  - Die Meldung nennt „residual variance“.
  - Es gibt keine Warnung von Matrix oder CHOLMOD.
  - Die Grenze bleibt relativ.
- Offen bleibt der ungeschützte Startfit (`R/fit.R:467`). Knapp oberhalb der Nullgrenze endet der Vorgabepfad roh (E50, blocking nach ADR-018 Nr. 3 und docs/01 §2 Nr. 4).
- ADR-018 Nr. 1 bleibt gewahrt: `vc` stammt aus `VarCorr(model)`, die neue Prüfung verändert weder Daten noch Varianzen (Nachprüfung 4).
- ADR-018 Nr. 2: Der Durchreichweg ist unverändert. Der neue Test vergleicht ihn auf dem degenerierten Fall mit direktem `lmer`.
- Kein Widerspruch zwischen Spec-Stellen, also kein ESCALATE.

### API-Diff

- `NAMESPACE`, Signaturen und Vorgaben sind unverändert. Eine neue Fehlermeldung gibt es nicht; die Prüfung nutzt die vorhandene.
- `?msa_fit` hat zwei neue Sätze (E45, E46). Beide habe ich am Code geprüft; sie stimmen.
- `NEWS.md` hat einen neuen Satz.

### Integrität

- **Entkernte oder geänderte Tests:** keine. Der Rework fügt eine Datei hinzu und ändert keine bestehende. Abnahme-, QA- und Fixture-Dateien sind blob-gleich.
- **Gelockerte Konfiguration:** keine.
- **Harte Erwartungswerte:** keine. Die einzige Konstante ist das unveränderte (64 · eps)² aus ADR-020.
- **Erfundene Daten:** keine. Die synthetischen Testdaten sind als solche gekennzeichnet.
- **Golden-Daten:** unverändert.

### Neue Tests

- Die neuen Tests belegen Verhalten gegen unabhängige Referenzen:
  - `stats::aov` für die Modellräume (Vorbedingungen RSS/SST ≤ Grenze und Rest-FG > 0);
  - direktes `lme4::lmer` mit bobyqa für die positiven Gegenfälle (`ANK-TOL.oracle`);
  - `var()` für die Randlösung SST / (N − 1);
  - Sherman-Morrison, Q = 4 / (1 + 4λ), für die Rang-eins-Prüfung;
  - direktes `lmer` für den Durchreichweg (`ANK-TOL.engine_boot`).
- Eine Momentaufnahme der eigenen Ausgabe gibt es nur für den Meldungswortlaut, über `rework_error()`; sie ist gekennzeichnet (`helper-m1a-rework.R:16–18`).
- In `test-fit-residual-design.R:133–134` steht `ANK-TOL.arithmetic.abs_tol` (1e-10), von `expect_equal` relativ angewandt. Das ist strenger als `oracle.closed_form_rel_tol` und unkritisch.
- Lücken: kein Fall mit kleiner positiver Restvarianz oberhalb der Grenze (E50) und keiner mit hoher Wiederholpräzision (E51).

## Stand der Einwände aus Runde 2

Der Builder beantwortet alle IDs Punkt für Punkt (REWORK-NOTES).

| ID | Stand | Beleg |
| --- | --- | --- |
| E44 | erledigt | Nachprüfungen 2 und 3; `test-fit-residual-design.R:25–66` |
| E45 | erledigt (Dokumentationsweg aus dem Vorschlag) | `R/fit.R:73–76`, `man/msa_fit.Rd`; BL-82 gestrichen |
| E46 | erledigt (Dokumentationsweg aus dem Vorschlag) | `R/fit.R:43–46`, `man/msa_fit.Rd`; BL-83 gestrichen |
| E47 | teilweise | 4 der in E47 genannten Überlebenden getötet, die Darstellbarkeitsfälle offen → E53, BL-84 |
| E48 | offen, Betreiber | BL-85; Approvals in dieser Runde neu gebunden (Abschnitt MUT-EQUIV) |
| E49 | offen, Betreiber | BL-86; der Builder bestätigt beide Befunde unverändert |
| E39, E41, E42 | offen, Betreiber | BL-77, BL-79, BL-80 |
| E43 | vertagt nach M1b | BL-81 |

## Einwände

### Blocking

- [E50] (blocking) ADR-018 Nr. 3 (`docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md:51–53`: „`msa_fit()` endet mit einer benannten englischen Fehlermeldung (docs/01 §2 Nr. 4), wenn der Abschluss sein Abbruchkriterium nicht erreicht oder das Problem kein endliches Optimum hat …“); docs/01 §2 Nr. 4 (`docs/01-fachspezifikation.md:18`: „Randfälle sind Pflicht: … identische Antworten, nicht konvergierende Fits. Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung …“); PLAN-UPDATE M1a, Randfälle (`PLAN-UPDATE.md:312`, „Sehr kleine positive Streuung“: „Bei tatsächlichem Nullmaßstab, Über-/Unterlauf oder fehlender Identifizierbarkeit benannter Fehler.“); `?msa_fit` (`R/fit.R:78–81`: „… a degenerate residual variance produce named errors. Small representable variation and tied scores are supported …“) — **Befund:**
  - Der allgemeine Vorgabepfad startet mit `lme4::lmer()` auf der konditionierten Antwort (`R/fit.R:467`), ohne Fehlerbehandlung.
  - Die neue Projektion (`R/fit.R:462–466`) fängt nur Reste unterhalb der Nullgrenze (64 · eps)² · SST ab.
  - Liegt der Modellrest knapp darüber, bricht der Startfit im PLS-Schritt von lme4 ab, mit `Rcpp::exception` „Downdated VtV is not positive definite“. Der Aufrufstapel: `msa_numeric_fit` > `lme4::lmer` > `optwrap`.
  - Reproduktionen (Restvarianz nach ADR-020 jeweils positiv; RSS/SST aus `stats::aov`):
    1. 5 × 3-Plan mit drei identischen Replikaten (Seed 7, wie `test-fit-residual-design.R:35–38`) ohne Zeile 1, dann `set.seed(1001); value + 1e-8 * rnorm(44)`: RSS/SST 6,4e-17;
    2. QA-Fall A (`residual_design_runs()`) mit `value[16] <- NA`, dann `set.seed(1003); value + 1e-8 * rnorm(16)`: 1,0e-17;
    3. QA-Fall A vollständig (balanciert; die geschlossene Lösung greift nicht), `set.seed(1001); value + 1e-9 * rnorm(16)`: 3,8e-19.
  - Breite: Im Lauf aus Nachprüfung 5 enden 42 von 220 Fits so, alle bei e ≤ 1e-7. Nachbarfälle desselben Bandes enden benannt („… cannot be resolved at working precision.“, „not identifiable“). Der Ausgang hängt also nur von der Rundung im Startfit ab.
  - Kein Rückschritt: Runde 2 und v0.1.0 enden in Nr. 1 gleich, und Runde 2 gleicht Runde 3 in allen 220 Fällen.
  - Es ist dieselbe rohe Meldung aus demselben Startfit wie in E44. ADR-018 Nr. 3 verlangt für den Vorgabepfad eine benannte Meldung, gleich ob die Restvarianz null oder nur nicht auflösbar ist.

  — **Vorschlag:**
  - Fehler des Startfits in `msa_numeric_fit()` abfangen und mit einer benannten englischen Meldung enden.
    - Liegt die Ursache in der Restskala, passt die Meldung des Abschlusses: „Numeric model residual variance cannot be resolved at working precision.“ (`R/fit.R:334`; im Sinn von ADR-022 Nr. 7).
    - Gesammelte Startwarnungen gehen wie bisher über `on.exit` weiter (ADR-020, E17).
  - Wahlweise bei gescheitertem Start mit einem Startwert ohne lme4 (etwa aus der Projektion oder λ = 1) in den analytischen Abschluss gehen. Der fittet dann oder endet benannt.
  - Kein Ersatz durch eine angehobene Nullgrenze aus ADR-020 und keine künstliche Reststreuung (PLAN-UPDATE, Randfälle; ADR-022 Nr. 7).
  - Unit-Tests: die drei Reproduktionen.
    - Verlangt: eine benannte Meldung, keine Klasse `Rcpp::exception`, keine Warnung von Matrix oder CHOLMOD.
    - Die positiven Gegenfälle der neuen Datei bleiben grün.
  - ADR-020 um einen Satz zum Startfit ergänzen.

### Nonblocking

- [E51] (minor) ADR-018 Nr. 3 (ein benannter Fehler bei nicht erreichtem Abbruchkriterium ist zulässig); PLAN-UPDATE M1a, Randfälle (`PLAN-UPDATE.md:311`: „Ist die Modellrestvarianz positiv, normaler Fit.“); `?msa_fit` (`R/fit.R:80–81`); docs/02 Z. 74 (M1d: „llm-stability für die Wiederholpräzision bei Temperatur 0“) — **Befund:**
  - Bei hoher Wiederholpräzision endet der Vorgabepfad oft benannt mit „Analytic REML did not converge“ oder „Numeric variance components are not identifiable.“. lme4 und v0.1.0 liefern dort Schätzungen.
  - Die Pläne aus E44 mit Replikatrauschen 1e-3 (Restvarianz ≈ 1e-6 bei einer Zellkomponente von 1,5 bis 2,8) enden in 5 von 6 geprüften Fällen mit „did not converge“. `lmer` mit bobyqa, `VCA::remlVCA` (intern lme4) und v0.1.0 stimmen dort auf drei bis vier Stellen überein, etwa beim 5 × 3-Plan mit Seed 7 ohne Zeile 1: item:prompt 1,539, prompt 0,4465 bis 0,4466, Rest 1,665e-6.
  - Typische Pläne (Nachprüfung 6): 6 Fehler in 96 Fits, v0.1.0 keiner. Beispiel 20 × 4 × 3 × 2 mit Wechselwirkungen, Rest 1e-4, `seed = 504`, balanciert: „… (iterations 100, scaled score 5.44e-09, scaled step 1.63e-07)“. lmer mit bobyqa und v0.1.0 liegen auf dem REML-Kriterium nur 1e-5 auseinander (−2022,33557 gegen −2022,33558).
  - In zwei der sechs Fälle trennen sich die lme4-Optimierer selbst um 1,4 und 2,8 REML-Einheiten. Dort schützt die Meldung vor einer stillen falschen Zahl. Ein Vertragsbruch ist das deshalb nicht.
  - Aber die Zusage „Small representable variation … supported“ ist für diesen Bereich zu weit. Der Fall ist zudem Kern von M1d.
  - Der Robustheitsnachweis nach ADR-018 Nr. 5 (ADR-020, Tabelle) enthält nur Restanteile ab 0,1 (S-boot) und kein Szenario hoher Wiederholpräzision.

  — **Vorschlag:**
  - Das Abbruchkriterium an der erreichbaren Genauigkeit ausrichten, etwa: Der vorhergesagte REML-Abstieg des Newton-Schritts liegt unter der vorhandenen Rundungsreserve 64 · eps · max(1, |F|). Oder eine andere Parametrisierung wählen.
  - Szenarien mit Restanteil 1e-4 und 1e-6 in den Robustheitsbericht aufnehmen.
  - Bis dahin die Grenze in `?msa_fit` nennen.
  - Spätestens vor der Vignette llm-stability (M1d). BL-87.
- [E52] (minor) IMPLEMENTATION-RULES, Fehler und Typen („Hot Paths vermeiden unnötige Allokationen; messbare Budgets werden nur aus Ankern gelesen …“); ADR-020, Nachtrag Runde 3 (gemessen nur auf `ic50_demo`) — **Befund:**
  - Die Projektion baut das Design dicht (N × q) und rechnet eine QR mit Aufwand O(N q²).
  - Auf dem AP1-Gesamtplan steigt die Fit-Zeit um den Faktor 1,44, auf einem 200-Item-Plan um 1,35 (+ 8,3 s; Nachprüfung 7).
  - `msa_plan()` zahlt die Projektion in jeder Wiederholung, in der die geschlossene Lösung nicht greift. Laut ADR-020 sind das 15 bis 19 von 20 Fits.
  - Kein Budget-Anker ist berührt.

  — **Vorschlag:**
  - Den Rest ohne dichtes Design bestimmen. Möglich wäre eine rangaufdeckende Zerlegung im Zufallseffektraum aus dem sparsamen Z'Z.
  - Oder die Projektion erst nach einem gescheiterten Startfit rechnen, zusammen mit E50.
  - Oder den Aufwand für große Pläne in ADR-020 nennen.
  - BL-88.
- [E53] (minor) Gate mutgate (grün, score=93.72; Überlebende in `reports/mutation/mutation.json`; ohne Gate-Wirkung) — **Befund:**
  - Gegenüber Runde 2 (`gate-mutgate.log` aus `c47521a`) sind vier Überlebende aus E47 getötet: `R/fit.R:343` (vorher 336) mit `^ → *`, `<n> - 1 → <n> - 1` und `<n> + 1 → <n> + 1`, dazu `:261` (vorher 254) mit `NULL → NA`.
  - Sechs neue Überlebende liegen in älteren Restprüfungen. Ihre Fälle erkennt jetzt eine spätere Prüfung mit derselben Meldung:
    - `R/fit.R:265` `- → +`; `:266` `^ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1`. Das ist die Einwegprüfung; die Projektion rechnet bei einem einzigen Term denselben Rest mit derselben SST, `R/fit.R:264–267` ist damit redundant.
    - `:289` `^ → *`, `<n> - 1 → <n> - 1`. Das ist die balancierte Prüfung; die Q-Prüfung in `R/fit.R:343` endet mit derselben Meldung.
  - Aus E47 weiter offen sind die Darstellbarkeitsfälle:
    - `:500` `> → <`, `<n> + 1 → <n> + 1`;
    - `:501` `|| → &&`, `<= → <`, `<n> - 1 → <n> - 1`;
    - `:502` `> → >=`;
    - `:522` `|| → &&`;
    - `:523` `> → >=`.
  - `R/fit.R:263` `<n> + 1 → <n> + 1` und `x[<i>] → x[<i> + 1L]` (`counts[1]` → `counts[2]`) sind nach meiner Prüfung äquivalent, aber nicht beantragt. Grund: Es gibt immer mindestens zwei Zellen, weil `item` mindestens zwei Stufen hat; „alle gleich `counts[1]`“ ist dann gleichwertig mit „alle gleich `counts[2]`“.

  — **Vorschlag:**
  - Den Einwegzweig `R/fit.R:264–267` entfernen oder durch einen Test unterscheidbar machen. Für `:289` einen Test oder eine Begründung.
  - `:263` als Äquivalenz in `MUT-EQUIV.json` beantragen.
  - Die Darstellbarkeitsfälle wie in BL-84.
  - Nicht verlangt. BL-84.

[INFRA]: Zu E48 und E49 gibt es nichts Neues für den Builder. Den Stand führen BL-85 und BL-86.

## MUT-EQUIV

**Grundlage:**
- acht Anträge in `MUT-EQUIV.json` (sieben auf neue Zeilen verschoben, `R/grr.R:94` gleich), die zehn überlebende Mutanten im Gate-Bericht der Runde 3 betreffen;
- jeden habe ich gegen `reports/mutation/mutation.json` (Datei, `mutatorName`, Zeile, Status Survived) und gegen den Quelltext geprüft. Auf keiner der Zeilen gibt es einen weiteren Mutanten desselben Typs.

**Ergebnis:** Alle acht sind echte Äquivalenzen und stehen in `MUT-EQUIV-APPROVED.json`.

| Datei:Zeile | `mutatorName` | Quelltext (Stand `173a536`) | Nachprüfung in Runde 3 |
| --- | --- | --- | --- |
| `R/fit.R:229` | `+ → -` (3 Mutanten, Spalten 37, 46, 54) | `stats::aggregate(y ~ item + prompt + model + block, …)` | `model.frame()` nimmt alle Variablen aus `attr(terms(), "variables")`. `aggregate()` ist für alle drei Formeln identisch auf fünf Plänen: `ic50_demo`, zwei Simulationen, unbalanciert, mit `NA` in `value` und `prompt_id`. |
| `R/fit.R:109` | `FALSE → TRUE` | `as.data.frame(runs, stringsAsFactors = FALSE)` | Es gibt kein `as.data.frame`-Verfahren für `msa_runs`. Identisch für sechs `msa_runs`-Eingaben, auch mit Zeichenspalten; Ende-zu-Ende identisch auf einer schlichten Liste. |
| `R/fit.R:348` | `<n> + 1 → <n> + 1` | `gram <- curvature <- matrix(0, k, k)` | Die Doppelschleife schreibt jedes Element vor dem ersten Lesen. Der REML-Zustand ist für die Startwerte 1, −1 und `NA` auf drei Plänen × vier λ-Vektoren identisch. |
| `R/fit.R:348` | `<n> - 1 → <n> - 1` | wie oben | wie oben |
| `R/fit.R:449` | `TRUE → FALSE` | `lme4::lFormula(form, data = scaled, REML = TRUE, …)` | `lFormula` nutzt `REML` nur in `c(res, list(REML = REML))`. `reTrms`, `fr`, `X`, `formula` und `wmsgs` sind auf fünf Plänen identisch. Genutzt wird nur `reTrms`, auch von der neuen Projektion in Z. 462. |
| `R/fit.R:451` | `TRUE → FALSE` | `strsplit(names, ":", fixed = TRUE)` | `:` ist kein Metazeichen. Identisch für elf Namen, auch `"a::b"`, `":x"`, `"x:"` und `""`. |
| `R/fit.R:457` | `TRUE → FALSE` | `on.exit(…, add = TRUE)` | Einziges `on.exit` in `msa_numeric_fit()`. Erfolgs- und Fehlerweg sind mit einer mutierten Kopie identisch. |
| `R/grr.R:94` | `> → >=` | `… else if (grr_v > 0) … else Inf` | Identisch auf 512 nichtnegativen Kombinationen, auch −0, 5e-324 und 1e300. `grr_v = repeat_v + sum(…)` kann nicht −0 sein. Eine Abweichung gibt es nur bei negativer Item-Varianz, die keine Produktionsquelle liefert (ADR-018 Nr. 1 (d)). |

- **Wirkung:**
  - Die neue Datei trifft genau diese zehn Überlebenden; nachgerechnet habe ich mit der Zuordnungslogik des Gates.
  - Auf den Bericht der Runde 3 angewandt ergäbe sich 970 / 1026 = 94,54 (ohne Approval 93,63).
  - Die sieben veralteten `R/fit.R`-Einträge (Zeilen 222, 102, 341 zweimal, 442, 444 und 450) sind entfernt (E48).
  - `mut-baseline` schreibt nur das Gate.
- **Bindung an den Stand:**
  - Die Freigaben gelten für `173a536` (`R/fit.R` SHA-256 `6ab0a2a5…`, `R/grr.R` `c468f439…`).
  - Verschiebt der Rework zu E50 eine dieser Zeilen, beantragt der Builder die betroffenen Äquivalenzen in `MUT-EQUIV.json` mit den neuen Zeilen neu. Das nächste Review gleicht jede Freigabe mit dem neuen Bericht ab.

## Verdict

**REWORK.**

- `gates.json` meldet `result: pass`. `blocking` ist aber nicht leer: E50 mit Bezug auf ADR-018 Nr. 3, docs/01 §2 Nr. 4, PLAN-UPDATE (Randfälle) und `?msa_fit`.
- Nonblocking: E51 bis E53.
  - BACKLOG: BL-87 und BL-88 neu, BL-84 mit neuem Stand;
  - BL-82 und BL-83 gestrichen;
  - neuer Stand in BL-13 und BL-85.
- Kein Spec-Widerspruch. E50 braucht keine neue Auslegung; ADR-018 Nr. 3 deckt den Fall.

## Geschriebene Dateien

- `orchestrator/handoff/M1a/REVIEW.md` (diese Datei);
- `orchestrator/handoff/M1a/verdict-code.json` (`round: 3`);
- `orchestrator/handoff/M1a/MUT-EQUIV-APPROVED.json` (acht Freigaben auf den Zeilen von `173a536`);
- `BACKLOG.md`: BL-87 und BL-88 neu; BL-82 und BL-83 erledigt; neuer Stand in BL-13, BL-84 und BL-85.

Keine Git-Kommandos. Ich habe weder Produktcode noch Tests, Gates oder Orchestrator-Zustand geändert.
