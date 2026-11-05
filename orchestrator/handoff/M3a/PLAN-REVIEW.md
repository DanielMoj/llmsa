# PLAN-REVIEW — M3a, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 05.11.2026 · Gegenstand: `orchestrator/handoff/M3a/PLAN.md` (Runde 1, 366 Zeilen). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK.** Drei blocking-Befunde (E1 bis E3), vier minor-Befunde (E4 bis E7).

- **Spec-Treue:**
  - Der Plan deckt K-M3a-1 bis K-M3a-7 ab und übernimmt die Auslegungen ACC-3 bis ACC-16 (PLAN Z. 11–19).
  - Signatur (`fleiss = FALSE` hinter `weights`), Fleiss-Formel, Alpha-Zählung, Nenner der Attributkennzahlen, Linearitätsfelder, Handbuchverdikt, Hinweistext und Vignettenweg stimmen mit docs/04 M3a, docs/01 §2 bis §5 und §8, der Formelsammlung §5, §6 und §9 und den Abnahmetests überein.
  - Die geplante Bandprüfung ist richtig: Prüflauf 2 findet sie in 4000 von 4000 Zufallsfällen gleich der Mini-Referenz.
- **Warum REWORK:** Drei Stellen verletzen docs/01 §2 Nr. 4 oder §5, und der Plan regelt sie nicht. Alle drei sind an v0.1.0 nachgewiesen.
  - **E1:** Cohens Kappa ist still falsch, sobald die Referenz eine Kategorie außerhalb der Skala enthält; mit `levels = NULL` reicht eine Referenzkategorie, die keine Antwort verwendet (0,571 statt 0,500, 0,400 und 0,286). Widersprüchliche Referenzen eines Items ersetzt das Paket still durch die erste.
  - **E2:** `msa_bias()` zählt fehlende und nicht lesbare Werte nicht, und eine Bedingung ohne gültiges Paar verschwindet aus `by_condition`.
  - **E3:** Identische Antworten enden in `msa_bias()` mit dem Rohfehler „data are essentially constant“ von `stats::t.test`, sobald die Subtraktion der Referenz Rundungsreste lässt.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-052-m3a-reviewer-auslegungen.md`:
    - hält ACC-3 bis ACC-16 fest (Nr. 1 bis 14);
    - hält Anker und Datenblätter mit dem Abgleich am Seitenbild fest (Nr. 15; ACC-1, ACC-2);
    - bestätigt die Festlegungen des Plans einschließlich seiner Randfallvorschläge (Nr. 16);
    - nennt die Mindestanforderungen zu E1 bis E3 (Nr. 17);
    - beschreibt den Mutationsumfang (Nr. 18, Hinweis).
  - In `CRITERIA.json` verweisen die Statuszeilen von ACC-1 bis ACC-16 auf ADR-052; ACC-2 ist erledigt. Kriterien und alle übrigen Felder sind unverändert (Prüflauf 6).

### An den Betreiber

1. **Keine Zuarbeit vor Runde 2 nötig.**
   - Die drei AIAG-Datenblätter sind geliefert und am Seitenbild abgeglichen (Prüflauf 1): 15 + 60 Messwerte, 5 Referenzwerte, 450 Entscheidungen und 50 Referenzentscheidungen gleich, die kanonischen Prüfsummen gleich den Ankern. Die Datei-SHA-256 stehen in ADR-052 Nr. 15.2.
   - `orchestrator/state/mut-baseline` fehlt, wie BL-123 verlangt.
   - irr 0.85, psych 2.6.9 und DescTools 0.99.60 sind installiert; das deps-Gate findet sie nach der Suggests-Ergänzung.
2. **Zur Kenntnis:** `data_file.status` von ANK-74 bis ANK-76 nennt noch „Datei fehlt“. Das Feld ist kein Wert, kein Test liest es; es wird mit der nächsten Änderung dieser Anker nachgeführt (ADR-052 Nr. 15.4).
3. **Zur Planung (Hochrechnung, nicht gemessen):** Die Vignettentabelle wird beim Knit gerechnet. Auf v0.1.0 kosten 2 × 1000 Aufrufe von `msa_bias()` etwa 6,6 s (Prüflauf 2, (e)). Der Knit läuft im lint-Gate zweimal (Build und Check) und im mutgate je Mutant einmal.

### Ablauf

Mit REWORK erhöht der Orchestrator die Planrunde auf 2. Der Builder schreibt `PLAN-UPDATE.md` und beantwortet E1 bis E7 Punkt für Punkt.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/prompts/30-plan-review.md`.
- **Spezifikation:** docs/04 M3a vollständig (Ergebnissatz, K-M3a-1 bis K-M3a-7); docs/01 §1 bis §10; Formelsammlung §1, §5, §6, §9, §11 bis §13.
- **Handoff M3a:** `CRITERIA.json` (sieben Kriterien, ACC-1 bis ACC-17), `PLAN.md` vollständig. Zum Format: `PLAN-REVIEW.md` und `verdict-plan.json` aus M3b.
- **ADRs:** ADR-022 (fehlende Werte, Nullgrenze), ADR-043, ADR-048 Nr. 14 und 15, ADR-051 (Format, Mutationsumfang).
- **Abnahmetests:**
  - `setup-m3a.R`, `test-m3a-1` bis `test-m3a-7` vollständig; `tests/simulation/setup-simulation.R` und `test-bias-coverage.R` vollständig;
  - `setup-m1a.R` Z. 380–450 (gemeinsamer Knit), `setup-m2.R` Z. 860–890 (AP1-Vergleich mit `msa_agreement()`), Fundstellen der Abschnittsprüfungen in `test-m1a-7`, `test-m1b-7` und `test-m1c-5`.
- **Anker:** ANK-06, ANK-75, ANK-76 vollständig; ANK-70, ANK-72 bis ANK-74 über die Tests und `CRITERIA.json`; ANK-TOL (`arithmetic`, `package_compare`, `mc_factor`, `sim_runtime`, `invariance`, `oracle`).
- **Daten:** `reference/quellen/data/aiag/QUELLE.txt` und die drei Datenblätter; Textspiegel der AIAG-PDF Z. 4400–4431, 4888–4935, 6620–6694; Seitenbilder der PDF-Seiten 99, 108 und 143.
- **Produktcode und Tests des Builders:** `R/agreement.R` vollständig, `R/report.R` Z. 1–80, `R/acmg.R` Z. 959–1000 und 1224, `R/fit.R` (Fundstellen zu `NaN`, `Inf`, fehlenden Werten), `inst/templates/validation_report.Rmd` Z. 105–205, `vignettes/validation.Rmd` Z. 1–30, 120–160 und 290–392, `DESCRIPTION`, `tests/testthat/test-agreement.R`, `test-report.R` Z. 1–80, `test-fit-grr.R` Z. 60–75, `helper-validation-latent.R` vollständig, `test-validation-latent.R` Z. 90–157.
- **Harness:** `orchestrate.sh` (`path_allowed` Z. 515–544, `verdict()` Z. 734–756, Planschleife Z. 946–978), `config.env` Z. 196–274, `lib/r-mutation.R` Z. 55–94, `lib/r-deps.R` vollständig, `toolchain.json`, `BACKLOG.md` (alle 131 Zeilen maschinell; gelesen BL-13, BL-15, BL-42, BL-44, BL-46, BL-57, BL-113, BL-122, BL-123, BL-131).

## Eigene Prüfläufe

Alle als R-Skripte unter `orchestrator/handoff/M3a/.probe-plan-review/`, mit `Rscript --vanilla` aus der Repo-Wurzel; die Seitenbilder sofort nach dem Ablesen und das Verzeichnis am Ende gelöscht. R 4.6.1, testthat 3.3.2, pkgload 1.5.3, irr 0.85, psych 2.6.9, DescTools 0.99.60, jsonlite 2.0.0. Produktcode ist v0.1.0 (`R/agreement.R` unverändert); `REPO_ROOT` gesetzt; Abnahmehilfen aus allen `tests/acceptance/setup-*.R`.

1. **Datenblätter (ACC-2).** `data.R` und `crops.R`. Ausgabe (gekürzt auf die Prüfzeilen):

   ```text
   PDF sha256 aeb067807277a89a484844f33667eacfa2de4e3c70f66a042a83a815f73a2e5f
   Creator:         Acrobat PDFMaker 9.1 for Word | Producer:        GPL Ghostscript 9.55.0 | Pages:           241 | Page size:       612.826 x 790.99 pts
   attribute_study.csv file sha256 c6d393eff6dc11665e13be8506714c79394477cac0f6ab4bdd2b635c91b01ab5 bytes 4906
   bias_study.csv file sha256 9ddcba5ff48078b36385e7bd8adb5c4906372d99aba743c1fad5389d4550caab bytes 228
   linearity_study.csv file sha256 cfefaecd2ef2089d7fbfd512c3cc06a828a03b3b00cfe6b8af7a893400292253 bytes 894
   ANK-74: canonical hash = anchor, 450 rows, columns part,appraiser,trial,value,reference
   ANK-75: canonical hash = anchor, 15 rows, columns part,reference,trial,value
   ANK-76: canonical hash = anchor, 60 rows, columns part,reference,trial,value
   bias: text rows 15; trial equal TRUE; value equal TRUE; printed bias = value - 6 TRUE; reference all 6 TRUE; part all 1 TRUE
   linearity: text value matrix equal TRUE; printed bias matrix = value - reference TRUE; reference per part 2 4 6 8 10
   attribute: text parts 1..50 TRUE; decisions A-1..C-3 equal TRUE; reference equal TRUE; reference constant per part TRUE
   ```

   - Die Datei-SHA-256 gleichen `QUELLE.txt`.
   - Danach Seitenbilder mit pdftoppm (60 dpi Übersicht, 150 dpi Ausschnitte) der PDF-Seiten 99, 108 und 143, Zeile für Zeile gegen die Ausgabe der Dateien in Tabellenform gelesen: Tab. III-B 1 (15 Messungen), Tab. III-B 4 (12 × 5 Messungen, Referenzwerte 2.00 bis 10.00) und Tab. III-C 1 (50 Teile, A-1 bis C-3, Reference) sind gleich. Keine Abweichung.
2. **Planbehauptungen und Lücken auf v0.1.0.** `claims.R`. Ausgabe:

   ```text
   (a) unweighted: levels NULL -> a,b, kappa_all 0.571429; levels a,b,c -> kappa_all 0.500000; mini-reference 0.500000; irr::kappa2 0.500000
   (a) linear: levels NULL -> a,b, kappa_all 0.571429; levels a,b,c -> kappa_all 0.400000; mini-reference 0.400000; irr::kappa2 0.400000
   (a) quadratic: levels NULL -> a,b, kappa_all 0.571429; levels a,b,c -> kappa_all 0.285714; mini-reference 0.285714; irr::kappa2 0.285714
   (b) levels a,b with reference value c: kappa_all 0.571429, accuracy 66.6667, messages none (silent)
       v0.1.0 cohen_kappa table sum after factor(): 0.6667 of 1 (pairs with reference c fall out of the table, not of the denominator)
   (c) band check: plan q(z) and acceptance mini-reference agree in 4000 of 4000 random cases (NA inside)
       acceptable: plan TRUE (margin -1.0000), mini-reference TRUE
       handbook_rejects: plan FALSE (margin 0.1994), mini-reference FALSE
       between_references: plan FALSE (margin 0.2357), mini-reference FALSE
   (d) deviations 0.1+0.2, 0.3, 0.3, 0.3 (sd 3.2e-17): msa_bias v0.1.0 ERROR: subscript out of bounds
       stats::t.test: ERROR: data are essentially constant
       exactly constant 0.3: msa_bias v0.1.0 ERROR: subscript out of bounds
   (e) 200 msa_bias() calls on 540 values: 0.66 s, i.e. about 6.6 s for 2 x 1000
   (f) bias study, one reference value: msa_bias v0.1.0 ERROR: subscript out of bounds
   (g) condition P1 x M2 without valid values: by_condition rows 1 (P1 x M1)
   ```

   - (a), (b): Antworten a, a, b, b, a, b; Referenz a, a, b, c, c, b; ein Item je Paar.
   - (c): Bandprüfung nach PLAN Z. 103–109, nachgebaut in der Probe, gegen `acc_m3a_in_band_ref()`; Zufallspläne mit 3 bis 8 Items und 2 bis 6 Replikaten, Fälle mit relativem Rand unter 1e-6 ausgenommen. „NA inside“ ist ein Formatierungsrest der Probe ohne Bedeutung.
   - (d): Alle Referenzen 0, also ein Referenzwert; der Abbruch kommt aus der Linearität (wie (f)). Deshalb Prüflauf 3.
3. **Fast konstante Abweichungen mit zwei Referenzwerten.** `claims2.R`, Referenzen 0, 0, 1, 1. Ausgabe:

   ```text
   deviations 0.30000000000000004 0.29999999999999999 0.30000000000000004 0.30000000000000004, sd 3.2e-17
   msa_bias v0.1.0: ERROR: data are essentially constant
   stats::t.test: ERROR: data are essentially constant
   lm warning: essentially perfect fit: summary may be unreliable
   done
   ```

4. **Backlog-Abdeckung.** `backlog.R` und eine Gegenprobe. `BACKLOG.md` hat 131 Zeilen mit eindeutigen IDs. Der Plan hat 90 Maßnahmenzeilen (PLAN Z. 187–278) und 41 IDs in der Liste der erledigten (Z. 283–288); zusammen alle 131, keine doppelt. Alle 41 erledigten tragen in `BACKLOG.md` einen Erledigungs- oder Behebungsvermerk:

   ```text
   done-list ids: 41
   without marker:
   ```

   BL-07, BL-64, BL-87, BL-91, BL-101, BL-102, BL-103 und BL-109 enthalten ein solches Wort, sind aber nur zum Teil erledigt; der Plan behandelt sie zu Recht als offen.
5. **Ausgangsstand der M3a-Abnahme und Referenzauflösung.** `baseline.R`. Ausgabe (Kopf; die Zeilen je Test stehen in der Probe):

   ```text
   (1) item i1 with references 2 and 5: bias 0.0000 (order 2, 3, 5) and -1.5000 (order 5, 3, 2); no message
   (2) CRITERIA.json round trip byte-identical: TRUE (26823 bytes)
   (3) m3a acceptance: 35 tests, 628 expectations, 34 failed, 8 with error, 0 skipped, 28.1 s
   ```

   - Grün auf v0.1.0: Cohen-Beispiel und Orakel (sechs Blöcke), Fleiss-Mini-Referenz, Krippendorff-Beispiel, Orakel und Zuordnung, D2, beide AIAG-Attributtests (Tab. III-C 3, Kappa gegen die Referenz, Tab. III-C 5), K-M3a-5 je Prompt × Modell und auf Zufallsdaten.
   - Rot oder Fehler: Ein-Kategorien-Tafel, alle Fleiss-Tests am Paket, Hilfeseite, `n_units_excluded`, D1 (eine Erwartung, der Anteil vollständig richtiger Items; Prüflauf 6), AIAG-Biasstudie (Abbruch wie Prüflauf 2, (f)), alle Linearitätstests, Vignette.
   - Kein Test übersprungen. Das leere `tests/acceptance/_snaps/` des Laufs ist entfernt.
   - Dazu einzeln: `acmg_demo` hat nur Referenzen aus den fünf Klassen (B 360, LB 540, LP 324, P 468, VUS 468); `ic50_demo` hat 8 fehlende Werte.
6. **D1 und `CRITERIA.json`.** `criteria.R`. Nur `status` von ACC-1 bis ACC-16 neu, aus R geschrieben (`jsonlite::toJSON(auto_unbox = TRUE, pretty = TRUE)` plus Zeilenende; Rundlauf vorher bytegleich, Prüflauf 5, (2)). Ausgabe (Kopf):

   ```text
   CRITERIA.json sha256 before: 4335a63fdd7c278adf0c4a418753d972ec88d1984f84f88efec8aa334138df05
   D1 v0.1.0: pct_items_all_correct 50.0000 (hand 40.0000); accuracy_overall 60.6061 (hand 60.6061); repeatability 66.6667 (hand 66.6667)
   CRITERIA.json: status changed for ACC-1, ACC-2, ACC-3, ACC-4, ACC-5, ACC-6, ACC-7, ACC-8, ACC-9, ACC-10, ACC-11, ACC-12, ACC-13, ACC-14, ACC-15, ACC-16; criteria identical TRUE; all fields except status identical TRUE; valid JSON TRUE
   ```

   Neue Statuszeilen: ACC-1 „…; festgehalten in ADR-052 Nr. 15“; ACC-2 „erledigt: Datenblätter vom Betreiber am 05.11.2026 geliefert, vom Reviewer am Seitenbild abgeglichen (PLAN-REVIEW M3a r1, Prüflauf 1); festgehalten in ADR-052 Nr. 15“; ACC-3 bis ACC-16 „…; festgehalten in ADR-052 Nr. 1“ bis „Nr. 14“ statt „ADR im 30-plan-review“. ACC-17 bleibt.

## Antworten auf die Einwand-IDs

- **Runde 1:** Es gibt keine früheren Einwände.
- **ACC-1 und ACC-2:** Der Plan stellt richtig fest, dass die Datenblätter vorliegen und ihre kanonischen Prüfsummen den Ankern gleichen (Z. 21, 153–162). Den Abgleich am Seitenbild hat der Reviewer nachgeholt (Prüflauf 1). Festgehalten in ADR-052 Nr. 15; ACC-2 ist erledigt.
- **ACC-3 bis ACC-16:** übernommen (Z. 11–19) und im Testplan je Kriterium wiedergegeben (Z. 299–307). Festgehalten in ADR-052 Nr. 1 bis 14. Die Wahl ohne Fleiss-Standardfehler ist nach ACC-9 zulässig (Z. 15, 69).
- **ACC-17:** Suggests (Z. 35), BL-15, BL-44 und BL-113 (Z. 202, 224, 264), Baseline (Z. 166, 270), Laufzeit (Z. 177) sind zugeordnet.
- **Randfallvorschläge des Plans (Z. 111):** bestätigt in ADR-052 Nr. 16.5, ergänzt um `NaN` als fehlend (wie ADR-022 Nr. 3) und `NA` statt `NaN` bei R². Offen sind nur die Teile, die E2 und E3 betreffen.
- **BACKLOG:** Alle 131 Zeilen sind zugeordnet (Prüflauf 4). Jede Vertagung nennt Grund und Zuständigkeit (AGENTS.md, Handoff-Disziplin). Stichproben gegen den Text: BL-13, BL-15, BL-42, BL-44, BL-46, BL-57, BL-113, BL-123, BL-131.

## Einwände (Runde 1)

- [E1] (blocking) docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); K-M3a-1; Formelsammlung §5 („p\_cd relative Häufigkeit der Kombination (Antwort c, Referenz d)“); K-M3a-5 — **Befund:** Der Plan regelt für Cohens Kappa eine einzige Skalenkategorie, einen entarteten Nenner und leere Randkategorien der übergebenen Skala (Z. 59). Referenzwerte außerhalb der Skala regelt er nicht, ebenso wenig widersprüchliche Referenzen.
  - v0.1.0 bildet die Vorgabeskala nur aus den gültigen Antworten (`R/agreement.R:40`). `cohen_kappa()` macht Referenzwerte außerhalb der Skala über `factor()` zu `NA`; `table()` verwirft diese Paare, der Nenner `length(x)` behält sie (Z. 187–191). Die Kreuztafel summiert dann nicht zu 1, und beide Kappa-Felder sind falsch, ohne Meldung.
  - Prüflauf 2, (a) und (b): Mit `levels = NULL` und einer Referenzkategorie, die keine Antwort verwendet, ist `kappa_all_vs_reference` 0,571429 für alle drei Gewichtungen. Richtig (Skala a, b, c; Mini-Referenz und `irr::kappa2`) sind 0,500000, 0,400000 und 0,285714. Die Tafel summiert sich auf 0,6667. Mit `levels = c("a", "b")` ist es dasselbe.
  - `resolve_reference()` (Z. 109–121, für beide Funktionen) nimmt bei mehreren Referenzwerten eines Items still den ersten. Prüflauf 5, (1): Item i1 mit den Referenzen 2 und 5 ergibt in `msa_bias()` den mittleren Bias 0,0000 oder −1,5000, je nach Zeilenfolge.

  — **Vorschlag:** In `PLAN-UPDATE.md` das Verhalten für beide Kappa-Felder und beide Funktionen festlegen (Mindestanforderung ADR-052 Nr. 17.1). Empfohlen:
  1. Ein nicht fehlender Referenzwert außerhalb der Skala ist ein benannter englischer Fehler, der die Werte nennt und auf `levels` verweist, bei übergebenen wie bei abgeleiteten `levels`.
     - Die Alternative, die Vorgabeskala aus Antworten und Referenz zu bilden, verschiebt K der Gewichte und die Positionen der Intervallmetrik, sobald eine Referenzkategorie zwischen Antwortkategorien liegt. Alpha hinge dann von der Referenz ab. Sie braucht deshalb eine eigene Begründung und Tests.
  2. Ein Item mit zwei verschiedenen Referenzwerten ist ein benannter Fehler, gleich ob die Referenz als Vektor, als data.frame oder als Spalte von `runs` kommt.
  3. Unit-Tests für beide Pfade, alle drei Gewichtungen und beide Kappa-Felder; Vergleich mit der Rechnung über die volle Kategorienmenge.
  4. Rückwirkung prüfen: AP1 übergibt die Klassen ausdrücklich (`R/acmg.R:1224`), und die Referenzen von `acmg_demo` liegen in der Skala (Prüflauf 5). Die M2-, M1d- und Berichtstests laufen in BUILD mit.
- [E2] (blocking) docs/01 §5 („Fehlende oder nicht parsbare Antworten bleiben fehlend und werden gezählt, nie ersetzt.“); K-M3a-5 („je Prompt×Modell dasselbe“) — **Befund:** Der Plan lässt fehlende und nicht lesbare Werte in `msa_bias()` „ausgeschlossen“ (Z. 111), zählt sie aber nirgends.
  - v0.1.0 filtert sie ohne Zählung (`R/agreement.R:225`). Eine Bedingung Prompt × Modell ohne gültiges Paar verschwindet aus `by_condition` (`split(…, drop = TRUE)`, Z. 235).
  - Prüflauf 2, (g): P1 × M2 nur mit fehlenden Werten ergibt eine einzige Zeile in `by_condition` (P1 × M1), ohne Meldung.
  - Das Paket zählt sonst: `msa_agreement()` mit `n["missing"]`, `msa_fit()` mit einer Warnung samt Zahl, `print()` eines `msa_runs`-Objekts mit „missing values“. `msa_bias(ic50_demo, "reference")` verwirft dagegen 8 fehlende Werte ohne Spur (Prüflauf 5).

  — **Vorschlag:** zusätzliche Felder (docs/01 §4, ohne ADR; Mindestanforderung ADR-052 Nr. 17.2):
  1. die Zahl der nicht eingehenden Werte gesamt (fehlende, nicht lesbare oder `NaN`-Antwort, fehlende Referenz), dazu je Zeile von `by_condition`;
  2. jede Bedingung aus `runs` bleibt eine Zeile von `by_condition`, ohne gültiges Paar mit `n = 0` und `NA`;
  3. Druckausgabe und Abschnitt 5 nennen die Zahl;
  4. Unit-Test mit einer leeren Bedingung und Fehlwerten beider Arten.
  Namen und Form legt `PLAN-UPDATE.md` fest.
- [E3] (blocking) docs/01 §2 Nr. 4 („Randfälle sind Pflicht: fehlende Werte, unbalancierte Pläne, Komponenten an der Grenze null, Faktoren mit zwei Stufen, identische Antworten, nicht konvergierende Fits. Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); K-M3a-5; K-M3a-6; ADR-022 Nr. 7 — **Befund:** Der Plan regelt konstante Abweichungen (Punktintervall, p `NA` mit Hinweis, Z. 111) und nennt ein Raster gegen Rohfehler (Z. 174). Er legt aber nicht fest, wann Abweichungen numerisch konstant sind.
  - v0.1.0 ruft `stats::t.test` auf, sobald der Standardfehler größer als 0 ist (`R/agreement.R:231`).
  - Prüflauf 3: Abweichungen 0,1 + 0,2, 0,3, 1,3 − 1 und 1 + 0,1 + 0,2 − 1 (sd 3,2e-17, zwei Referenzwerte) beenden `msa_bias()` mit „data are essentially constant“. `summary(lm)` warnt dabei „essentially perfect fit: summary may be unreliable“.
  - Sind alle Abweichungen exakt 0, gibt `stats::t.test` den p-Wert `NaN`.
  - Solche Werte entstehen bei identischen Antworten schon durch die Subtraktion der Referenz. LESSONS: Einzelbefunde dieser Art kosteten in M1a je eine Runde.

  — **Vorschlag:** in `PLAN-UPDATE.md` eine Regel für den ganzen Pfad (Mindestanforderung ADR-052 Nr. 17.3):
  1. Kein Aufruf von `stats::t.test` oder `summary.lm` im Produkt. t, p und Intervall kommen aus eigener Rechnung mit p = 2 · pt(−|t|, n − 1), gleich `stats::t.test`, wo dieses ein Ergebnis liefert.
  2. „Konstant“ ist relativ: Standardfehler < 10 · `.Machine$double.eps` · |Mittel| (die Grenze von `stats::t.test`) oder exakt 0. Dann Punktintervall, t und p `NA` mit Hinweis.
  3. Für die Reststreuung beider Regressionen eine relative Grenze (Restquadratsumme gegen Gesamtquadratsumme, wie ADR-022 Nr. 7). Darunter sind t-Werte und p `NA` mit Hinweis, das Band ist die Gerade, die Entscheidung folgt aus ihr. R² ist `NA`, wenn die Gesamtstreuung null ist.
  4. Rastertest über Itemzahlen, Referenzbereiche, Rauschstufen bis zur Arbeitsgenauigkeit (nur Rundungsrauschen) und mehrere Seeds: kein Fehler, keine Warnung, kein `NaN`.
- [E4] (minor) ACC-8; ACC-9; ACC-12; `tests/acceptance/test-m3a-2-fleiss-kappa.R:144–163`; `test-m3a-6-linearity.R:138–139` — **Befund:** Vertragsdetails, an denen eine richtige Rechnung scheitern kann.
  - Eine Druckzeile, die „Fleiss“ und „SE“, „standard error“ oder „std err“ nennt, muss den Wert nach Gl. (12) zeigen. Ein Satz wie „Fleiss' kappa … (no standard error)“ in einer Zeile macht K-M3a-2 rot, obwohl der Plan zu Recht keinen Standardfehler ausgibt (Z. 69).
  - Jedes Element von `fleiss`, dessen Name das Muster `acc_m3a_se_pattern` trifft, gilt als Standardfehler, auch Teilnamen wie `n_sd` oder `std_counts`.
  - `linearity_in_band` und `linearity_verdict` vergleicht der Test mit `expect_identical()`.

  — **Vorschlag:**
  - Die Fleiss-Zeile der Druckausgabe nennt nur den Punktschätzer. Ein Hinweis auf den fehlenden Standardfehler gehört, falls gewünscht, in die Hilfe.
  - `fleiss` enthält neben `kappa` höchstens Zählgrößen mit eindeutigen Namen, etwa `ratings_per_item` oder `n_items`.
  - Beide Linearitätsfelder ohne Namen und Attribute (`unname()`), Länge 1.
- [E5] (minor) K-M3a-7; ACC-15; docs/01 §2 Nr. 3 („Berichtet wird, was herauskommt, nicht was herauskommen soll“); ADR-048 Nr. 14.5; `tests/acceptance/test-m1c-5-vignette.R:38`; PLAN-REVIEW M3b r1, E2 — **Befund:** Der Plan legt Inhalt und Herkunft der Vignettentabelle richtig fest (Z. 115–137), aber nicht ihren Ort und den Umgang mit Literalen.
  - K-M1c-5 liest alle Tabellen des Abschnitts „Bootstrap intervals: coverage by scenario“ bis zur nächsten Überschrift gleicher oder höherer Ebene. Ein dort eingeschobener Unterabschnitt mit der Bias-Tabelle läge in diesem Bereich.
  - K-M1a-7 wertet jedes Literal der ganzen Datei als abgetippt, das einer ANK-TOL-Toleranz gleicht (etwa 1e-8). Weitere Tests prüfen Literale mit mindestens drei signifikanten Stellen aus Ankern und Ergebnisdateien (M3b r1, E2).
  - Über das Bestehen entscheidet der Klasse-A-Test, die Vignette berichtet.

  — **Vorschlag:**
  - ein eigener Abschnitt der Ebene zwei, etwa „## Bias interval: coverage by scenario“, hinter dem Bootstrap-Abschnitt;
  - im Rmd keine Zahlenliterale: Szenarien, Seeds und n_sim kommen aus dem Helfer und aus ANK-06, Toleranzen aus ANK-TOL;
  - die Tabelle zeigt zusätzlich den Abstand zu 0,95 in MCSE; eine Abweichung über ANK-TOL.mc_factor (report) wird benannt und bricht den Bau nicht ab;
  - die Laufzeit des ganzen Knits vor und nach der Änderung in `PROGRESS.md` nennen, weil er je Mutant läuft.
- [E6] (minor) Gate mutgate (`orchestrator/gates.d/86-mutgate.sh`; `config.env:228–229`, `:242`, `:267`); ANK-32; docs/01 §2 Nr. 7; ADR-051 Nr. 10; ADR-052 Nr. 18 — **Befund:** Der Plan plant Druck- und Berichtstests (Z. 39, 321) und zielgerichtete Tests gegen Überlebende (Z. 354).
  - mutgate mutiert `R/agreement.R` aber ganz, auch die bestehenden Teile: `print.msa_agreement()` (Z. 123–147), `print.msa_bias()` (Z. 248–262), die Fehlerpfade von `resolve_reference()` und `krippendorff_alpha()`.
  - Die Mutatoren `string_literals` und `numeric_literals` treffen jede Formatzeichenkette (`orchestrator/lib/r-mutation.R:59–67`).
  - Heute prüft nur `test-m3a-2-fleiss-kappa.R:157–162` eine Druckausgabe, und nur Zeilen mit Fleiss-Standardfehler. In M3b lag eine Attrappe ohne Drucktests bei 63,2 % (ADR-051 Nr. 10).

  — **Vorschlag:**
  - Unit-Tests vergleichen die ganze Ausgabe von `capture.output(print(x))` beider Druckmethoden mit Zeilen, die der Test aus dem Objekt bildet (wie M3b r1, E1 Nr. 1), mit und ohne Referenz, mit und ohne Fleiss, bestimmte und unbestimmte Linearität.
  - Jede Fehlermeldung genau (`expect_error(…, fixed = TRUE)`) und `conditionCall()` gleich `NULL`; jede Teilbedingung einzeln.
  - Die Tests bleiben schnell, weil sie je Mutant laufen. Kein Umbau bestehenden Codes für den Score, keine Ausschlüsse; Äquivalenz nur einzeln über `MUT-EQUIV.json`.
- [E7] (minor) docs/01 §5 („Tests unter `tests/testthat/` überspringen mit `skip_if_not_installed()`, Abnahmetests nicht (das deps-Gate installiert Suggests)“); ADR-051 Nr. 9.8 — **Befund:** Der Plan nimmt irr, psych und DescTools in Suggests auf (Z. 35) und plant „unabhängige Referenzrechnungen“ in neuen Unit-Tests (Z. 37–40), ohne zu sagen, ob diese die Pakete rufen.

  — **Vorschlag:** Jeder Unit-Test unter `tests/testthat/`, der irr, psych oder DescTools ruft, beginnt mit `skip_if_not_installed()`. Hilfebeispiele, Bericht und Vignette brauchen die Pakete nicht.

## Prüfung nach Gesichtspunkten

- **Spec-Treue:**
  - K-M3a-1: Formel nach Formelsammlung §5, keine freie Gewichtsmatrix (ACC-3), Hinweis bei einer Kategorie (ACC-16). Lücke: E1.
  - K-M3a-2: `fleiss = FALSE` hinter `weights`, κ_F mit Marginalanteilen aus den Daten, `NA` mit Krippendorff-Meldung, kein Standardfehler (zulässig). Die Formel im Plan (Z. 64–66) gleicht Formelsammlung §5 und der Mini-Referenz.
  - K-M3a-3: `n_units_excluded` aus Einheiten vor dem Entfernen ungültiger Antworten (Z. 80), die drei Zuordnungen in der Hilfe.
  - K-M3a-4: Nenner nach ACC-5 und ACC-6 (Z. 82), Modalregel, BL-113 (Z. 84).
  - K-M3a-5: Biasrechnung von der Geraden getrennt (Z. 90), t-Intervall mit n − 1. Lücken: E2, E3.
  - K-M3a-6: alle Felder aus ACC-12 (Z. 92–99), beide Gewichtungen bei ungleichen Replikaten (Z. 101), stetige Bandprüfung (Z. 103–109), Verdikt nur aus der Handbuchrechnung, Hinweis in Objekt und Bericht. Lücke: E3 für die Regressionen.
  - K-M3a-7: ADEMP nach docs/01 §8 (Z. 127–135), Seeds und RNG nach ACC-14, Zahlen aus dem geladenen Paket. Hinweis: E5.
- **Architektur:** Die Produktarbeit bleibt in `R/agreement.R`; Fit-, Bootstrap- und AP1-Kern bleiben unberührt (Z. 43). Der Vignettenhelfer folgt ADR-048 Nr. 14.5 und ADR-043. Weil der Knit den Helfer über `system.file()` aus dem geladenen Paket lädt, ruft er im Mutationslauf den mutierten Namespace (`lib/r-mutation.R:77`: `inst` wird mitkopiert).
- **Verträge:** Nur additive Änderungen nach docs/01 §4: ein neues Argument mit Vorgabe am Ende, neue Felder, neue Spalte, geänderte Druckausgabe. ANK-02 bleibt. Die Prüfung der Eingaben von `level`, `fleiss` und nicht endlichen Werten ersetzt bisher stille `NaN`-Ergebnisse durch benannte Fehler und ändert keine Bedeutung.
- **Vollständigkeit:** Dateiliste (Z. 27–41) und Territorium passen zu `BUILDER_EXTRA_PATHS_REGEX` (`config.env:200`). `README.md` und `_pkgdown.yml` bleiben unberührt. Alle 131 Backlog-Zeilen sind zugeordnet.
- **Risiken:** Die Risikotabelle (Z. 170–181) nennt die richtigen Klassen. E3 macht die Klasse „Rohfehler bei kleiner Streuung“ prüfbar. Laufzeit: E5 und „An den Betreiber“ Nr. 3.
- **Gate-Abdeckung:**

  | Kriterium | Prüfweg | Gates |
  | --- | --- | --- |
  | K-M3a-1 bis K-M3a-6 | `tests/acceptance/test-m3a-1` bis `-6` | tests; mutgate je Mutant |
  | K-M3a-7 | `tests/simulation/test-bias-coverage.R`, `tests/acceptance/test-m3a-7-vignette.R` | tests; lint (Bau der Vignette); mutgate je Mutant nur der Vignettenteil |
  | alle | Kriteriums-IDs in `tests/acceptance` | trace |
  | Suggests | `DESCRIPTION` | deps |
  | Anker, Golden-Daten | keine Änderung nach `plan/M3a` geplant | golden-adr |
  | Pfade | Dateiliste des Plans | territory |

## Hinweise für BUILD

- Prüfumfang laut Plan (Z. 327–352) mit `REPO_ROOT` und `options(testthat.progress.max_fails = Inf)`. Zusätzlich vor der Übergabe die Abnahmetests, die `msa_agreement()` oder den gemeinsamen Knit außerhalb von M3a nutzen, soweit sie ohne Git laufen: `filter = "^(m1a-7|m1b-7|m1c-5|m1d-4)"` (Knit und ClinVar-Alpha). Den AP1-Vergleich mit `msa_agreement()` in `setup-m2.R` Z. 873–882 deckt der Gate-Lauf ab.
- Hilfeseiten nur aus roxygen erzeugen; übernommen werden nur `man/msa_agreement.Rd` und `man/msa_bias.Rd` (Plan Z. 30).
- Datenblätter nicht kopieren, nicht in Tests unter `tests/testthat/` lesen (BL-09).
