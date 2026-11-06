# REVIEW — M3a, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 06.11.2026 · Gegenstand: Diff seit `plan/M3a` (Tag-Objekt `30db968` → Commit `438ffb9`) bis HEAD `d916c93` (Gate-Commit). Die Gates liefen auf `72315f9` (`gates.json` `env.sha`, Commit von QA r1). Dazwischen liegen BUILD r1 (`184f7a9`), der erste Gate-Lauf (`cc693fd`) und QA r1 (`72315f9`). Es gibt weder `ARBITER.md` noch `MUT-EQUIV.json` noch `REVIEW-INPUT.md` zu M3a; die Build-Antworten stehen in `PROGRESS.md` (Abschnitt „M3a — BUILD, Runde 1“). Keine Git-Kommandos; den Diff habe ich aus den Objekten unter `.git/` in R gelesen (Prüflauf 1).

## Ergebnis

**Verdict PASS, `blocking` leer.** `gates.result` ist `pass`; alle acht Gates sind grün, keines meldet `error`.

- **Spec-Treue:** K-M3a-1 bis K-M3a-7 sind erfüllt. Die unveränderte Abnahme ist grün (7 Dateien, 872 Erwartungen; vor M3a 34 rot und 8 Fehlerblöcke, ADR-052, Kontext), ebenso die Klasse-A-Studie. Die Umsetzung folgt ADR-052 Nr. 1 bis 17 und Nr. 19, auch den Präzisierungen Nr. 17.2.2 (Überlauf) und Nr. 17.3.6 (R²); nur der Hinweis bei df = 0 nennt den Grund für R² nicht (E13).
- **Schnittstelle:** `msa_agreement(…, fleiss = FALSE)` ist das fünfte Formalargument, `msa_bias()` ist unverändert. NAMESPACE, ANK-02, Imports und `inst/extdata/` sind unverändert. Neue Rückgabefelder und Druckänderungen sind ohne ADR zulässig (docs/01 §4); `m0-api-snapshot` ist grün (259 Erwartungen).
- **Integrität:**
  - Kein Abnahmetest und keine Klasse-A-Studie ist geändert. Keine Konfiguration ist gelockert, kein Golden geändert.
  - Im Produktcode gibt es keine harten Erwartungswerte und keine erfundenen Daten. Die Szenario-Einstellungen im Vignettenhelfer sind Vorgaben der Spec (K-M3a-7, ADR-052 Nr. 12).
- **Mutation:** mutgate besteht mit 91 bei verlangten 86,85.
  - 875 Mutanten: 718 entdeckt, 71 überlebt, 86 `RuntimeError` (fallen aus dem Nenner), 0 `NoCoverage`.
  - Es gibt keinen Äquivalenzantrag, also schreibe ich keine `MUT-EQUIV-APPROVED.json`. Die Überlebenden bewerte ich unter E15.
- **QA:** Kein QA-Test ist rot. QA-M3a-001 (BL-132) bestätige ich am Produkt; die Herabstufung begründe ich unter E14. Die Bereinigung aus BL-131 schwächt keinen M3b-Test ab.
- **Neue Tests:** Sie belegen Verhalten gegen unabhängige Referenzen (Paarzählung, `stats::lm`, `stats::t.test`, `predict()`, Handzählung, `irr`). Die Drucktests sind als Formatprüfungen gekennzeichnet. Nur die genauen Meldungstexte in zwei Dateien sind nicht als Momentaufnahme gekennzeichnet (E16).
- **Eigene Gegenproben:**
  - Bandentscheidung gegen eine dichte, unabhängige Auswertung mit `lm`/`predict` auf 3000 Zufallsplänen: 0 Abweichungen.
  - Nicht gekreuzte Pläne zählen richtig; kein `NaN` auf entarteten Eingaben.
  - Vignettentabelle und Berichtsteile 4 und 5 sind richtig und ohne sichtbaren Defekt (Prüfläufe 2 und 3).
- **Nonblocking**, alle in `BACKLOG.md`:
  - E12: Zeilenfolge von `by_condition` hängt von der Eingabereihenfolge ab;
  - E13: R² `NA` ohne Grund im Hinweis bei df = 0;
  - E14: QA-M3a-001 und BL-132;
  - E15: Bewertung der mutgate-Überlebenden und Testlücken;
  - E16: Momentaufnahmen der Meldungstexte nicht gekennzeichnet;
  - E17: [QA-PENDING] eingecheckte `tests/e2e/testthat-problems.rds`;
  - E18: Orakelgrenze von `irr::kripp.alpha` (Hinweis M3a-B1 des Builders, Reviewer).
- **Was jetzt folgt** (`orchestrate.sh`, Abschluss wie in M3b): Bei PASS und grünen Gates prüft der Orchestrator, ob `PROGRESS.md` seit `plan/M3a` geändert ist. Das ist der Fall (Prüflauf 1). Danach setzt er `8-done`, committet und taggt `done/M3a`.

### An den Betreiber

1. **Mutations-Baseline vor dem nächsten M3-Meilenstein wieder entfernen (BL-123).**
   - `orchestrator/state/mut-baseline` steht jetzt auf `91` (seit `d916c93` versioniert).
   - Der erste Gate-Lauf verlangte 80 und erreichte 88,85; der zweite verlangte daraus 86,85 und erreichte 91.
   - Bleibt die Datei, verlangt M3c oder M3d auf anderen Dateien 89 statt 80 (ANK-32).
2. **Nächster Lauf:** Nach der Entscheidung vom 04.11. (BL-11) folgt M3d vor dem 26.11.2026, M3c danach. In `milestones.json` steht M3c vor M3d, und seine Abhängigkeit M1a ist erfüllt. Ein Lauf ohne Ziel startete also M3c; für M3d braucht es das Ziel ausdrücklich.
3. **Geschützte AIAG-Datenblätter:** `reference/quellen/data/aiag/` hat `anova_example.csv`, `attribute_study.csv`, `bias_study.csv`, `linearity_study.csv` und `QUELLE.txt` (05.11. 10:21). Das tests-Gate hat sie über die Ankerprüfsummen gelesen (`m3a-4` bis `m3a-6` grün). Nach einem Rollback vor dem nächsten Lauf prüfen (BL-103).
4. **Sandbox-Befund M3a-B2 des Builders** (HTTP-Mock von `test-m2-7` scheitert am Socketverbot): Er betrifft nur die Builder-Sandbox. Im tests-Gate ist `m2-7-robustness-pilot` grün (375 Erwartungen, `gate-tests.log` Z. 1875). Kein Backlog-Eintrag nötig.

## Gate-Fakten (`orchestrator/state/M3a/gates.json`, Runde 1)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 31 Anforderungen erfüllt (R 4.6.1)` (Z. 33); `DescTools 0.99.60`, `irr 0.85`, `psych 2.6.9` gefunden (Z. 12, 18, 24) |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 19:45:13 UTC (Z. 19), also nach dem QA-Commit um 20:44:06 MEZ. `creating vignettes ... OK` (Z. 6), Tests `[86s/86s]` (Z. 80), `re-building of vignette outputs ... [51s/51s] OK` (Z. 84), `Status: OK` (Z. 89); `installed size is 22.4Mb` als INFO (Z. 36, BL-114) |
| tests | pass | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 6888 ]` (Z. 654; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 16962 ]` (Z. 2043); simulation `[ … PASS 10 ]` (Z. 2060); e2e `[ … PASS 724 ]` (Z. 2147); fuzz `[ … PASS 1385 ]` (Z. 2218); Kurzbefund „803 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 2219) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (qa/45-qa, Runde 1, Basis cc693fd…)`; der BUILD-Commit ging durch den ersten Gate-Lauf (`cc693fd`, „gates r1 (rc=0)“) |
| mutgate | pass | `mutgate: pass (score=91 required=86.85 baseline=91 floor=80)` (Z. 1104); 875 Mutanten in `R/agreement.R` (Z. 2), unmutierter Lauf 216,8 s mit 585 Tests (Z. 3), Dauer 25549,87 s (Z. 883), Ergebnis Z. 1101 |
| golden-adr | pass | `keine Golden-/Ankeränderung` |
| mutfull | pass | `nicht fällig in M3a` |

M3a-Erwartungen im tests-Gate:

| Testdatei | Erwartungen | Zeile |
| --- | --- | --- |
| `m3a-1-cohen-kappa` (K-M3a-1) | 309 | 1917 |
| `m3a-2-fleiss-kappa` (K-M3a-2) | 37 | 1924 |
| `m3a-3-krippendorff-alpha` (K-M3a-3) | 92 | 1937 |
| `m3a-4-attribute` (K-M3a-4) | 83 | 1944 |
| `m3a-5-bias` (K-M3a-5) | 155 | 1964 |
| `m3a-6-linearity` (K-M3a-6) | 178 | 1986 |
| `m3a-7-vignette` (K-M3a-7, Vignette) | 18 | 1989 |
| `tests/simulation/test-bias-coverage` (K-M3a-7, Klasse A) | 4 | 2050 |
| Unit `agreement-m3a`, `bias-linearity`, `agreement-report`, `validation-bias` (neu) | 177, 345, 70, 64 | 162, 201, 170, 512 |
| Unit `agreement`, `report` (Bestand) | 13, 33 | 173, 483 |
| QA `m3a-qa-e2e`, `m3a-qa-fuzz` (neu) | 149, 892 | 2132, 2203 |

- **Klasse-A-Studie** (stderr, `gate-tests.log` gegen Ende): S-bias-1 Überdeckung 0,9590 (MCSE 0,0063; +1,4 MCSE), S-bias-2 0,9520 (MCSE 0,0068; +0,3 MCSE), je 1000 Wiederholungen, Seeds 20261106 und 20261107, 7,2 s. Das gleicht dem Lauf auf v0.1.0 (ACC-14): Die t-Rechnung gibt dieselben Intervalle.
- **Regression der Vormeilensteine**, im selben Lauf grün:
  - `m0-api-snapshot` 259 (Z. 665), `m0-layout` 16;
  - `m1a-7-vignette` 148, `m1b-7-vignette` 240, `m1c-5-vignette` 55, `m1d-4-clinvar-vignette` 106 (Z. 1254), `m1d-7-findings` 512, `m1d-8-robustness-wording` 31;
  - `m2-6-evaluate` 383 (Z. 1852, AP1-Vergleich mit `msa_agreement()`), `m2-7-robustness-pilot` 375.
  - Die Literal- und Quellenprüfungen der Vignette bestehen also mit dem neuen Abschnitt.
- **Die zwei Warnungen** der Abnahme sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, Z. 841–856). Sie liegen im Reviewer-Territorium und haben keinen Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M3a/shots/` ist leer; M3a hat keine Grafik. Druck, Bericht und Vignettentabelle habe ich selbst erzeugt (Prüfläufe 2 und 3).
- **Konfiguration:** `orchestrator/config.env` ist git-ignoriert und zuletzt am 04.11. um 15:44:21 geändert, also vor der CONFIG-Zeile dieses Laufs (`orchestrate.log` Z. 251, 05.11. 10:30:02). MUT-Werte unverändert: Scope `^R/.*\.R$`, Schwelle 80, Floor 80, Toleranz 2 (ANK-32).

## Diff seit `plan/M3a` (Prüflauf 1)

| Pfad | Status | Rolle | Inhalt |
| --- | --- | --- | --- |
| `R/agreement.R` | M | Builder | gemeinsame Referenzauflösung, Cohen-Randfälle mit Hinweis, Fleiss, `n_units_excluded`, Attributnenner, `msa_bias()` mit Ausschlusszählung, eigener t- und OLS-Rechnung, Band, Verdikt und Hinweis; Druckmethoden; roxygen |
| `man/msa_agreement.Rd`, `man/msa_bias.Rd` | M | Builder | aus roxygen erzeugt |
| `inst/templates/validation_report.Rmd` | M | Builder | Abschnitt 4: Modalregel gegen AP1, Fleiss; Abschnitt 5: Ausschlüsse, beide Regressionen, Verdikt, Hinweis, Band |
| `inst/validation/agreement/bias_coverage.R`, `README.md` | A | Builder | Vignettenhelfer mit ADEMP |
| `vignettes/validation.Rmd` | M | Builder | Abschnitt „Bias interval: coverage by scenario“; zwei Sätze im Klasse-B-Teil umformuliert („does not rerun these class B simulations“) |
| `DESCRIPTION` | M | Builder | Suggests `DescTools`, `irr`, `psych`; sonst nichts |
| `NEWS.md` | M | Builder | drei Punkte zu M3a |
| `tests/testthat/test-agreement-m3a.R`, `test-bias-linearity.R`, `test-agreement-report.R`, `test-validation-bias.R` | A | Builder | 11, 14, 4 und 7 Blöcke |
| `PROGRESS.md` | M | Builder | neuer Abschnitt M3a mit Kommandos und Outputs; ältere Einträge bytegleich |
| `tests/e2e/test-m3a-qa-e2e.R`, `tests/fuzz/test-m3a-qa-fuzz.R` | A | QA | 3 und 2 Blöcke |
| `tests/e2e/test-m3b-qa-e2e.R`, `tests/fuzz/test-m3b-qa-fuzz.R` | M | QA | BL-131 |
| `tests/e2e/testthat-problems.rds` | A | QA | Rest eines roten Zwischenlaufs (E17) |
| `orchestrator/handoff/M3a/QA.md`, `BACKLOG.md` (BL-131, BL-132) | A, M | QA | |
| `orchestrator/state/**`, `STATUS.md`, `orchestrator/state/mut-baseline` | M, A | Orchestrator | Gate-Logs, Marker, Baseline `91` |

Alle Pfade liegen in der Rolle, die sie geschrieben hat; das gleicht den beiden grünen territory-Läufen. Kein Pfad ist gelöscht. Arbeitsbaum und HEAD sind für alle geänderten Pfade gleich.

## Spec- und Vertragstreue

- **K-M3a-1 (Cohen):**
  - Beide Kappa-Felder filtern dieselben unvollständigen Paare auf der vollen Skala (`R/agreement.R:258–285`). Eine leere Tafel, eine Skala aus einer Kategorie und P_e ≥ 1 geben `NA_real_` mit einer Meldung, die „kappa“ nennt (ADR-052 Nr. 14, Nr. 17.1.5). Die Hilfe nennt „Undefined Cohen's kappa gives `NA` with a message“.
  - Referenzen außerhalb der Skala ergeben einen benannten Fehler vor jeder Rechnung (`:75–83`), auch bei fehlender Antwort; Konflikte ebenso, in allen drei Eingabeformen (`:155–182`, ADR-052 Nr. 17.1).
- **K-M3a-2 (Fleiss):**
  - `msa_fleiss_kappa()` (`:287–305`) rechnet κ_F aus den Daten über alle gültigen Bewertungen eines Items; kein Item wird entfernt.
  - Ungleiche Zahl ergibt `NA` mit dem Verweis auf Krippendorff. Weniger als zwei Bewertungen und P̄_e = 1 nennen ihren eigenen Grund (E11).
  - `fleiss` ist genau `list(kappa = <Skalar ohne Namen>)`. Es gibt keinen Standardfehler, und keine Druckzeile nennt einen (ADR-052 Nr. 7, Nr. 19.1).
- **K-M3a-3 (Krippendorff):**
  - Die Einheiten entstehen vor dem Filtern aus Ganzzahlcodes, ohne Trennzeichen (`:185–188`). `n_units_excluded` zählt je Bereich die beobachteten Einheiten mit weniger als zwei gültigen Antworten, ohne kartesisches Auffüllen; am nicht gekreuzten Plan geprüft (Prüflauf 2, (a)).
  - Die Hilfe ordnet `unweighted` (nominal), `linear` (ordinal) und `quadratic` (interval) zu; Abstände auf Skalenpositionen.
- **K-M3a-4 (Attribute):**
  - Items ohne gültigen Vergleich gehen nicht in den Anteil vollständig richtiger Items ein (`:134–136`). Der Modalwert nimmt die niedrigste gleich häufige Kategorie, ohne gültige Antwort `NA`.
  - Hilfe und Bericht nennen die Regel und die AP1-Regel von `acmg_modal()` (BL-113; Bericht Abschnitt 4, Prüflauf 3).
- **K-M3a-5 (Bias):**
  - `msa_bias()` ruft weder `stats::t.test` noch `stats::lm` noch `summary.lm` (Suche über `R/agreement.R`).
  - t und p aus eigener Rechnung; die Konstanzregel ist die Grenze von `stats::t.test` (`:454–456`, ADR-052 Nr. 17.3.2).
  - Eine Biasstudie mit einem Referenzwert liefert ein vollständiges Ergebnis.
  - `n_excluded` steht hinten in `overall` und in `by_condition`; Bedingungen ohne gültiges Paar bleiben mit `n = 0` (Nr. 17.2).
  - Numerische Eingaben werden ohne Zeichenkettenumweg gelesen (`:428–436`). Überlauf der Differenz ist ein benannter Fehler (Nr. 17.2.2).
- **K-M3a-6 (Linearität):**
  - Beide Regressionen rechnen geschlossen, zentriert und skaliert (`:486–551`).
  - Felder, Namen und Typen wie ADR-052 Nr. 10.1 und Nr. 19.1. R² ist `NA` bei numerisch konstanten Zielwerten (Nr. 17.3.6; Lücke im Hinweis bei df = 0: E13).
  - Das Band wird über den ganzen geschlossenen Bereich mit innerem Scheitel geprüft (`:556–569`); auf 3000 Zufallsplänen gleicht es einer dichten Auswertung mit `predict.lm` (Prüflauf 2, (2)).
  - `linearity_note` nennt „item means“, beide df als Zahlen und gm − 2 bzw. g − 2 sowie „correlated … not independent“; ebenso Druck und Abschnitt 5.
- **K-M3a-7 (Überdeckung):**
  - Der Helfer folgt ADR-052 Nr. 12 und Nr. 16.8: Design mit dem Replikat als schnellstem Index, je Wiederholung erst die Itemwahrheiten und dann die Fehler. Er rechnet mit dem geladenen Namensraum, holt ANK-06 und ANK-TOL aus den hashgeprüften Ankerkopien und stellt den Zufallszustand wieder her, auch im Fehlerfall.
  - Die Tabelle hat die Spalten aus Nr. 19.3, und der Rmd-Teil enthält keine Zahlenliterale.
  - Der eigene volle Lauf ergibt dieselben Werte wie die Klasse-A-Studie (Prüflauf 2, (3)).
- **Schnittstelle (docs/01 §4, BL-57):** `fleiss = FALSE` steht am Ende mit Vorgabe. Alle neuen Felder kommen hinzu, keins ist entfernt oder umbenannt. Die neuen Eingabefehler ersetzen stille falsche Zahlen nach ADR-052 Nr. 17.1 und 16.5. Die Zeilenfolge von `by_condition` hat sich geändert (E12); das ist keine der Änderungen, die §4 an ein ADR bindet.
- **Abweichungen vom Plan:** keine. Die Umsetzung der Einwände E1 bis E11 habe ich an den genannten Stellen geprüft. `PROGRESS.md` beantwortet jeden Punkt mit Beleg.

## Neue Tests: Verhalten oder Momentaufnahme

**Builder, `tests/testthat/test-agreement-m3a.R`.** Die Tests belegen Verhalten:

- Kappa über eine eigene Aufzählung der Paargewichte (Z. 32–45);
- Alpha über eine eigene Paarzählung mit Midranks, auch mit unvollständigen Einheiten (Z. 88–116, 136–157);
- Fleiss aus Handzählung (Z. 74–78) und gegen `irr::kappam.fleiss` und `irr::kripp.alpha` hinter `skip_if_not_installed("irr")` (Z. 118–134);
- Attributkennzahlen aus Handzählung (Z. 159–176);
- Trennzeichen- und Reihenfolgeinvarianz (Z. 178–190).

Der Orakeladapter hängt bei `irr::kripp.alpha` eine leere Bewerterzeile an. Das ist begründet (E18, Prüflauf 4).

**Builder, `tests/testthat/test-bias-linearity.R`.** Die Tests belegen Verhalten:

- gegen `stats::t.test`, `stats::lm`/`summary.lm` und `predict(interval = "confidence")` bei vier Niveaus, ungleichen Replikaten und Bedingungen (Z. 91–138);
- ein Raster mit 240 Fällen über Skalen 1e±180, Verschiebung, Rauschen bis zur Arbeitsgenauigkeit und zwei Seeds (Z. 295–343);
- analytische Zeugen für das Band, auch den inneren Scheitel (Z. 140–172);
- Invarianzen gegen Einheit, Ursprung und Zeilenfolge (Z. 174–203);
- algebraisch bekannte entartete Fälle (Z. 205–293).

**Builder, `tests/testthat/test-agreement-report.R`.** Die Datei ist im Kopf als Formatprüfung gekennzeichnet. Die Sollzeilen entstehen aus den Objektfeldern; geprüft werden auch der letzte Zeilenumbruch, die unsichtbare Rückgabe und alte Objekte. Der gerenderte Bericht wird mit Werten aus dem Objekt geprüft. Die genauen Meldungstexte (Z. 111–142) gehören zu dieser gekennzeichneten Datei.

**Builder, `tests/testthat/test-validation-bias.R`.** Die Intervalle des Helfers werden gegen `stats::t.test` mit derselben Ziehung geprüft (Z. 26–67). Determinismus, RNG-Wiederherstellung auch bei Fehler und ohne vorherigen Zustand, der geladene Namensraum (über `local_mocked_bindings`) und der volle Nenner sind getestet. Kleine `n_sim` sind als Rohrleitungstest gekennzeichnet (Z. 1–2).

**Momentaufnahmen ohne Kennzeichnung (E16):** genaue Fehlertexte in `test-agreement-m3a.R:7–20`, `:217–238` und `test-bias-linearity.R:345–403`. Vertraglich belegt sind darin nur einzelne Teile: Anführungszeichen (E11), 17 Stellen (E9), „outside `levels`“ (Nr. 17.1.4), `conditionCall()` `NULL` (Nr. 17.1.6). Der Rest ist eigener Wortlaut.

**QA, `tests/e2e/test-m3a-qa-e2e.R` und `tests/fuzz/test-m3a-qa-fuzz.R`.** Die Tests belegen Verhalten:

- Anker ANK-70, ANK-72 und ANK-73 und die drei Orakel;
- ein unbalancierter Plan gegen `t.test`/`lm`;
- Bericht und Hilfeseiten;
- 30 metamorphe Zufallsläufe;
- die Konstanzgrenze bei 15 ε und 19 ε;
- die kritische Bandbreite und der innere Scheitel.

Toleranzen kommen aus ANK-TOL, Orakel stehen hinter `skip_if_not_installed()`.

## Mutation (Bericht `reports/mutation/mutation.json`, Prüflauf 5)

- **Bericht:** Er stammt vom zweiten Gate-Lauf (06.11. 04:40:58); seine Quelle gleicht `R/agreement.R` im Arbeitsbaum.
- **Status:** `Killed` 718, `Survived` 71, `NoCoverage` 0, `RuntimeError` 86 (fallen aus Zähler und Nenner).
- **Score:** 718 / 789 = 91,0 ≥ 86,85.
- Es gibt keinen Äquivalenzantrag. Die Überlebenden, Zeile und `mutatorName` wörtlich aus dem Bericht:

| Zeilen | `mutatorName` | Bewertung |
| --- | --- | --- |
| 275, 276, 277 | `* → /`, `- → +` (Spalte 34 bzw. 35: `k - 1` → `k + 1`), `/ → *`, `<n> - 1 → <n> - 1` (Ersatz `0` in `k - 1`) | gleichwertig: κ_w = 1 − Σ v·p_o / Σ v·p_e ist invariant gegen positive Skalierung der Nichtübereinstimmungsgewichte v = 1 − w; die Bedingung P_e ≥ 1 bleibt D_e = 0 |
| 84, 87, 88, 135, 138, 253, 434, 462, 463, 487, 488, 489 | `NA → NA_real_`, `NA → NA_integer_`, `NA → NA_character_`, `NA_real_ → NA`, `NA_character_ → NA` | gleichwertig nach Code-Lesung: Zuweisung in einen typisierten Vektor oder `c()` mit Zahl wandelt um |
| 71, 383, 172, 399, 445 | `FALSE → TRUE` (`stringsAsFactors` auf `msa_runs`, `drop` auf mehreren Spalten), `<n> + 1 → <n> + 1` (`scale <- 2` für den Nullvektor) | gleichwertig nach Code-Lesung |
| 91, 93, 99, 100, 130 | `+ → -` in `aggregate()`-Formeln | gleichwertig: `model.frame()` behält die Variable eines abgezogenen Terms (`attr(terms(v ~ a - b + c), "variables")` ist `list(v, a, b, c)`), `aggregate()` gibt `identical()` dasselbe (Prüflauf 5) |
| 187 | `TRUE → FALSE` (`split(…, drop = FALSE)`) | **Testlücke**: Kein Test hat einen nicht gekreuzten Plan. Das Produkt ist richtig (Prüflauf 2, (a)); der Mutant zählte unbeobachtete Kombinationen und füllte `by_condition` auf (ADR-052 Nr. 8.1, Nr. 17.2.4) |
| 562, 566 | `^ → *`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1` (Exponenten), `&& → \|\|` | **Testlücke**: Der innere Scheitel ist nur grob geprüft; `&& → \|\|` nähme einen Scheitel außerhalb des Bereichs auf. `> → >=` und `< → <=` in Z. 566 sind gleichwertig (Scheitel am Rand = Endpunkt) |
| 514 | `<= → <`, `<n> - 1 → <n> - 1` (9), `<n> + 1 → <n> + 1` (11) | **Testlücke**: Die Grenze der Restregel (ADR-052 Nr. 17.3.5 (b)) ist nur bei 8 ε und 32 ε geprüft |
| 505 | `== → !=`, `<n> - 1 → <n> - 1`, `<n> + 1 → <n> + 1` | Testlücke am Rückfall für `slope == 0`, zugleich QA-M3a-001 (1) (E14) |
| 240 | `< → <=`, `<n> + 1 → <n> + 1` (3); `<n> - 1 → <n> - 1` (1) | `<= 2`/`< 3` weichen nur bei genau zwei paarbaren Werten ab (Testlücke); `< 1` ist gleichwertig, weil n nie 1 ist |
| 397, 400, 401, 402 | `<non-empty string> → ""`, `x[<i>] → x[<i> + 1L]`, `<n> + 1 → <n> + 1` | **Testlücke**: Etikett „overall“ in der Konstanzmeldung von `msa_bias()`; `prompt_id`/`model_id` und Etikett einer Bedingung mit einer Zeile |
| 176, 122, 403, 379 | `TRUE → FALSE` (`trim`), `FALSE → TRUE` (`stringsAsFactors` der Alpha-Tabelle und von `by_condition`), `\|\| → &&` | Testlücken ohne Zahlenfolge: Konfliktwerte verschiedener Breite, Typ der Spalten `scope`, `prompt_id` und `model_id`, Klassen wie `difftime` als `level` |

Die gleichwertigen Gruppen dürfte ein späterer Antrag einzeln freigeben, wenn ein mutgate sie braucht. Die Testlücken stehen unter E15 und in BL-134.

## QA

- Kein QA-Test ist rot. QA.md meldet keinen blockierenden Befund und schlägt QA-M3a-001 (BL-132) als nonblocking vor.
- Beide Teile reproduziere ich am Produkt (Prüflauf 2, (b)). Die Herabstufung begründe ich unter E14.
- BL-131 ist erledigt; der Diff der M3b-QA-Dateien schwächt keinen Test ab (Prüflauf 1):
  - Toleranzen aus ANK-TOL, Generatorzeilen aus ANK-80;
  - Skips mit Grund statt stiller Zweige;
  - die Option lokal je Block.

## Einwände (Runde 1)

- [E12] (minor) docs/01 §2 Nr. 5 („Invarianzen: Zeilenreihenfolge, Umbenennen von Stufen und Verschieben der Messwerte ändern nichts“); ADR-052 Nr. 17.2.4; `R/agreement.R:185–188`, `:398–405` — **Befund:** `by_condition` ordnet die Bedingungen jetzt nach ihrem ersten Auftreten in `runs`. v0.1.0 ordnete nach sortierten Stufen (`split(d, list(prompt_id, model_id), drop = TRUE)`), unabhängig von der Eingabereihenfolge.
  - Prüflauf 2, (1): Auf permutiertem `ic50_demo` ändert sich die Zeilenfolge; jede Zeile ist nach Abgleich der Schlüssel gleich.
  - `msa_run()` ordnet nach Block und Position (`R/run.R:100`), bei `order = "random"` also zufällig. Druck und Abschnitt 5 zeigen die Bedingungen dann in zufälliger Folge.
  - Keine Zahl ist falsch, die Abnahme greift über Namen zu, und §4 bindet die Zeilenfolge an kein ADR. Deshalb nonblocking.

  — **Vorschlag:** die Bedingungen wie v0.1.0 ordnen (sortierte Stufen, Prompt innerhalb Modell) und mit einem Test sichern, der `by_condition` auf permutierten Zeilen mit `identical()` vergleicht (BL-133 (1)).
- [E13] (minor) ADR-052 Nr. 17.3.6 („Im Fall (a) ist R² `NA_real_`, auch wenn TSS > 0 ist; der Hinweis nennt den Grund“); `R/agreement.R:516–521` — **Befund:** Bei genau zwei Beobachtungen einer Regression (df = 0) und numerisch konstanten Zielwerten ist R² richtig `NA`. Der Hinweis nennt aber nur „has no residual degrees of freedom; inference and the confidence band are undefined“, nicht den Grund für R².
  - Prüflauf 2, (c): zwei Items mit den Item-Mittelwerten 0,2 und 0,2. Das ist ein seltener Randfall, und keine falsche Zahl entsteht. Deshalb nonblocking.

  — **Vorschlag:** In diesem Zweig auch „R-squared is undefined for numerically constant targets“ nennen, wenn die Konstanzregel greift (BL-133 (2)).
- [E14] (minor) QA.md QA-M3a-001; BL-132; docs/01 §2 Nr. 4; ADR-052 Nr. 17.1, Nr. 17.3.4 — **Befund:** Beide Teile bestätigt (Prüflauf 2, (b)). Die Herabstufung ist begründet:
  1. Kein ausführbarer roter Test belegt den Befund; die QA-Tests der aktiven Regeln sind grün.
  2. Teil (1): Die wahre Steigung von −3·10⁻⁴⁰¹ liegt unter der kleinsten darstellbaren Zahl und wird zu −0. Achsenabschnitt (2,5·10⁻²⁰¹ statt 7·10⁻²⁰¹) und `t_intercept` (0,7715 statt 2,1602) folgen aus dieser Rundung. Die Bandwerte, das Verdikt und alle anderen Felder stimmen. Der Fall braucht Eingaben, die über 400 Größenordnungen reichen, und tritt bei keinem Messsystem auf. Ergänzt: Der Aufruf meldet nichts.
  3. Teil (2): Doppelte oder fehlende Einträge in `levels` behandeln `krippendorff_alpha()` und `cohen_kappa()` wie in v0.1.0. M3a hat das nicht geändert. ADR-052 Nr. 17.1 betrifft die Referenzen, nicht `levels`.

  — **Vorschlag:** wie BL-132 nach dem 26.11.2026; für (1) auch eine Meldung, wenn die Steigung unterläuft.
- [E15] (minor) Gate mutgate (pass, `gate-mutgate.log` Z. 1101–1104); `reports/mutation/mutation.json` — **Befund:** 71 Überlebende (Tabelle oben). Gleichwertig nach Code-Lesung sind die Gewichtsskalierung (Z. 275–277), die NA-Typen, `stringsAsFactors`/`drop` ohne Wirkung und die Formel-Terme. Echte Testlücken liegen bei:
  1. nicht gekreuzten Plänen (Z. 187), obwohl ADR-052 Nr. 8.1 und Nr. 17.2.4 „ohne kartesisches Auffüllen“ verlangen;
  2. dem inneren Scheitel (Z. 562, 566) und der Restgrenze (Z. 514);
  3. Etikett und Schlüsseln einer Bedingung mit einer Zeile (Z. 397, 400–402).

  Das Produkt ist an diesen Stellen richtig (Prüfläufe 2 und 3), und der Score besteht. — **Vorschlag:** beim nächsten Eingriff in `R/agreement.R`:
  - ein nicht gekreuzter Plan für Alpha-Zählung und `by_condition`;
  - ein Scheitelzeuge mit Scheitel außerhalb des Bereichs und q > 0 dort;
  - Werte bei 9 ε, 10 ε und 11 ε für die Restregel;
  - eine Bedingung mit einer Zeile und zweitem Modell.

  Äquivalenzanträge nur einzeln über `MUT-EQUIV.json` (BL-134 (2)).
- [E16] (minor) Prüfauftrag 50-code-review (Momentaufnahme der eigenen Ausgabe nur ohne unabhängige Referenz und gekennzeichnet); IMPLEMENTATION-RULES.md, Tests; BL-128 (Lehre aus M3b); PLAN-UPDATE, Testplan Nr. 4 — **Befund:** `test-agreement-m3a.R:7–20`, `:217–238` und `test-bias-linearity.R:345–403` vergleichen den vollen Wortlaut eigener Fehlermeldungen mit `expect_identical(conditionMessage(err), …)`, ohne das als Momentaufnahme zu kennzeichnen.
  - Der Plan hat diese Prüfungen für die Mutationsabdeckung verlangt (E6). Sie ersetzen keine Logikprüfung, die fachlichen Zahlen sind daneben unabhängig geprüft. Deshalb nonblocking.

  — **Vorschlag:** an diesen Blöcken kommentieren, etwa „snapshot of the package's own wording; contract parts: …“ (BL-134 (1)).
- [E17] (minor) [QA-PENDING] AGENTS.md, Territorien (QA schreibt `tests/e2e/**`) — **Befund:** `tests/e2e/testthat-problems.rds` (63847 Bytes, 05.11. 20:38:27, also während QA r1) ist mit dem QA-Commit versioniert.
  - Die Datei ist der Rest eines roten Zwischenlaufs: sieben Fehlschläge einer früheren Fassung von QA-M3a-E2E-1 (Prüflauf 4).
  - Sie hält im `srcref` den lokalen absoluten Pfad der Testdatei fest.
  - `tests/e2e` steht in `.Rbuildignore`, Bau und Check sind also unberührt. Für den Builder nonblocking.

  — **Vorschlag:** QA löscht die Datei in der nächsten QA-Phase und prüft vor dem Ende der Phase, dass kein `testthat-problems.rds` liegen bleibt (BL-135).
- [E18] (minor) PROGRESS.md M3a-B1 (Builder); K-M3a-3; docs/01 §6 (Orakel) — **Befund:** `irr::kripp.alpha()` 0.85 rechnet bei vollständig beobachteten Matrizen mit mehr als zwei Bewertern falsch, weil der Zweig ohne `NA` `mc = 1` setzt.
  - Prüflauf 4: unabhängige Koinzidenzrechnung 0,243243, `irr` 0,216216; mit einer leeren Bewerterzeile 0,243243; bei zwei Bewertern gleich.
  - Die Abnahme M3a ruft `irr::kripp.alpha` nur auf Daten mit fehlenden Werten (`test-m3a-3-krippendorff-alpha.R` Z. 52, 76) und ist nicht betroffen. Der Unit-Test des Builders umgeht die Grenze offen gekennzeichnet.

  — **Vorschlag:** künftige Abnahme- und QA-Tests mit `irr::kripp.alpha` auf vollständigen Daten mit mehr als zwei Bewertern nur mit leerer Bewerterzeile oder eigener Paarzählung (Reviewer, QA; BL-136).

## Eigene Prüfläufe

Alle Skripte lagen unter `tests/acceptance/.probe-code-review/` und sind nach dem Lauf gelöscht. Werkzeuge: `Rscript --vanilla`, R 4.6.1, `pkgload::load_all()` aus dem Arbeitsbaum, `jsonlite`, `knitr`, `rmarkdown`, irr 0.85. Außer diesem Ordner und den Handoff-Dateien habe ich im Arbeitsbaum nichts geschrieben; es gab keinen Test-Gate- und keinen Git-Aufruf.

### Prüflauf 1 — Diff ohne Git

- **Einlesen:** R liest `.git/refs/tags/plan/M3a` (Tag-Objekt `30db968` → Commit `438ffb9`) und `refs/heads/main` (`d916c93`). Beide Bäume kommen aus losen und gepackten Objekten (idx v2, Deltas).
- **Ergebnis:** 40 geänderte Pfade (Tabelle oben), keiner gelöscht. Für alle hinzugefügten und geänderten Pfade gleicht der Arbeitsbaum dem Blob in HEAD.
- **Inhalt:** Die alten Blobs habe ich in den Probenordner geschrieben und mit `diff -u` gegen den Arbeitsbaum verglichen für `R/agreement.R`, `DESCRIPTION`, `NEWS.md`, `inst/templates/validation_report.Rmd`, `vignettes/validation.Rmd`, `PROGRESS.md`, `BACKLOG.md` und beide M3b-QA-Dateien. Der Inhalt gleicht der Beschreibung in PROGRESS und QA.md.

### Prüflauf 2 — Randfälle, Reihenfolge, Band, Vignette, Bericht

- **(a) Nicht gekreuzter Plan:** Drei Items unter verschiedenen Kombinationen ergeben `n_units_excluded` 1, 1, 1, 1 und `by_condition` mit drei beobachteten Bedingungen ohne Auffüllen.
- **(b) QA-M3a-001:**
  - Teil (1): Achsenabschnitt 2,5e-201, Bandwert bei 0 7e-201, `t_intercept` 0,7715167, Steigung −0, keine Meldung.
  - Teil (2): Alpha −0,1904762 mit gültiger Skala, −0,1363636 mit doppeltem „A“. `NA` in `levels` mit Referenz ergibt „non-conformable arrays“.
- **(c) df = 0:** `msa_bias_regression(c(1, 2), c(0.5, 0.5), …)` gibt R² `NA` mit dem Hinweis „no residual degrees of freedom“; ebenso zwei Items mit gleichem Item-Mittelwert (E13).
- **(d) und (1) Reihenfolge:** `ic50_demo` sortiert und permutiert (Seed 20261106):
  - sortiert: direct/stepwise/table × model-a…c;
  - permutiert: table model-a, direct model-a, stepwise model-a, table model-c, …;
  - v0.1.0 hätte auf den permutierten Daten die sortierte Folge geliefert;
  - die Zeilen sind nach Abgleich der Schlüssel gleich (E12).
- **(e) NaN-Suche:** 36 entartete Aufrufe von `msa_agreement()` mit Fleiss und Referenz: alle `NA`, leer, eine Kategorie, abwechselnd; drei Skalen; alle Gewichte. Kein `NaN`, keine Warnung.
- **(2) Band:** 3000 Zufallspläne (3 bis 8 Items, 2 bis 6 Replikate, teils gleiche Referenzen, Seed 20261107).
  - Referenz: `predict.lm(interval = "confidence")` auf 4001 Punkten über den Bereich.
  - Ausgenommen sind 28 Fälle mit relativem Rand unter 1e-6.
  - 0 Abweichungen von `linearity_in_band`.
- **(3) Vignettentabelle:** Helfer aus dem Arbeitsbaum, volle ANK-06-Größe:
  - S-bias-1: 0,959000, MCSE 0,006270, n_sim 1000, Abstand 1,435295;
  - S-bias-2: 0,952000, 0,006760, 1000, 0,295863;
  - beide „within report threshold“ und `within_pass` wahr, 7,0 s.
- **(4) Bericht:** `msa_report()` mit `acmg_demo` (Fleiss angefordert, ungleiche Zahl ergibt `NA` mit Meldung) und `ic50_demo`, als GitHub-Markdown.
  - Abschnitt 4 nennt die Modalregel und die AP1-Regel, Fleiss und `n_units_excluded`.
  - Abschnitt 5 nennt gültige und ausgeschlossene Paare, beide Regressionen mit df 2150 und 38, Verdikt **unacceptable**, den Hinweis und das Band mit 40 Zeilen.
  - Kein sichtbarer Defekt.
- **Druck:** `print()` beider Objekte vollständig und ohne Defekt; `Fleiss' kappa: NA` folgt der Meldung.

### Prüflauf 3 — Druck und Hilfe

Druckausgaben von `msa_agreement(acmg_demo, …, fleiss = TRUE)` und `msa_bias(ic50_demo, …)` habe ich gelesen (Prüflauf 2). Die Hilfeseiten sind aus roxygen erzeugt (`R CMD check`: `code/documentation mismatches ... OK`). Ihre Sätze zu Gewichten, Modalregel, Referenzen, Konstanz und Band gleichen dem Code.

### Prüflauf 4 — QA-Rest und Orakel

- **`tests/e2e/testthat-problems.rds`:** eine Liste mit 7 `expectation_failure` einer früheren QA-Fassung („Expected `unname(ag_wt$kappa[["kappa_all_vs_reference"]])` to equal `k_irr`“ und ähnliche). Die serialisierte Form enthält den lokalen Pfad der Testdatei (E17).
- **Orakel-Skips:** Unit-Tests rufen nur `irr` (`test-agreement-m3a.R` Z. 129, 131), nach `skip_if_not_installed("irr")` in Z. 119. `psych` und `DescTools` kommen in Unit-Tests nicht vor.
- **`irr::kripp.alpha`:** Matrix der Builder-Probe (fünf Items, drei Bewerter, vollständig). Unabhängige Koinzidenzrechnung 0,243243243243; `irr` 0,216216216216; mit leerer Bewerterzeile 0,243243243243. Bei den ersten zwei Bewertern beide 0,15625 (E18).

### Prüflauf 5 — Mutationsbericht

- **Bericht:** `jsonlite` auf `reports/mutation/mutation.json`; die Quelle gleicht `R/agreement.R` (`identical()`).
- **Status:** 718 `Killed`, 86 `RuntimeError`, 71 `Survived`, 0 `NoCoverage`.
- **Ausgabe:** Für jeden Überlebenden Zeile, Spalte, `mutatorName` und Ersatz; die Tabelle oben folgt dieser Ausgabe.
- **Formel-Mutanten:** `aggregate(v ~ a - b + c, …)` und `aggregate(v ~ a + b + c, …)` auf einem Datensatz mit drei Gruppierungen: `identical()` wahr.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` (über PLAN-REVIEW-Bezüge), `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/04 M3a (K-M3a-1 bis K-M3a-7 über `CRITERIA.json`), docs/01 §2 bis §9; ADR-052 vollständig.
- **Handoff M3a:** `CRITERIA.json` mit ACC-1 bis ACC-17, `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md` (Runde 2), `verdict-plan.json`, `QA.md`.
- **Gate-Fakten:** `gates.json`; alle acht `gate-*.log`, `gate-tests.log` gezielt (Ergebniszeilen, Warnungen, stderr); `orchestrate.log` (CONFIG-Zeilen, M3a-Ereignisse); `config.env` (Mutation, Runden); `mut-baseline`.
- **Code und Tests:**
  - `R/agreement.R` vollständig, alter Stand aus `plan/M3a` im Diff;
  - `inst/validation/agreement/bias_coverage.R` und `README.md`; Bericht, Vignette, `DESCRIPTION`, `NEWS.md` im Diff;
  - alle vier neuen Unit-Dateien vollständig; beide neuen QA-Dateien gezielt; beide geänderten M3b-QA-Dateien im Diff;
  - `PROGRESS.md`, neuer Abschnitt; `BACKLOG.md`: Kopf, BL-11, BL-15, BL-42, BL-44, BL-57, BL-113, BL-121 bis BL-132;
  - `R/run.R` Z. 56 und 100.
