# PLAN-REVIEW — M3a, Runde 2

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 2 (von `MAX_ROUNDS_PLAN=2`) · Stand: 05.11.2026 · Gegenstand: `orchestrator/handoff/M3a/PLAN.md` (Runde 1, 366 Zeilen) mit `PLAN-UPDATE.md` (Runde 2, 346 Zeilen). Es gibt keine `ARBITER.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Kein blocking-Befund. Neu sind vier minor-Befunde (E8 bis E11).

- **Antworten auf Runde 1:** `PLAN-UPDATE.md` beantwortet E1 bis E7 je mit „akzeptiert“ und legt die Form fest (Z. 13–19, 45–125). Die blocking-Befunde E1 bis E3 sind damit erledigt; die Form erfüllt die Mindestanforderungen von ADR-052 Nr. 17. Die Prüfläufe bestätigen die tragenden Annahmen:
  - Die Daten der bestehenden Aufrufer haben je Item höchstens eine Referenz, und keine liegt außerhalb der Skala. Die neuen Fehler nach E1 treffen keinen bestehenden Pfad (Prüflauf 1).
  - Die Konstanzregel des Plans entscheidet auf 20000 Fällen nahe der Grenze genau wie `stats::t.test` (Prüflauf 2, (a)).
  - Die Restregel greift auf der exakt linearen Abweichung und nicht bei echtem Rauschen (Prüflauf 2, (c)).
- **Zwei Präzisierungen** schreibt der Reviewer bindend in ADR-052. Die Spec schweigt dazu, und nach dem Ende der Planrunden bindet das Reviewer-Urteil (AGENTS.md, Handoff-Disziplin):
  - E8, ADR-052 Nr. 17.3.6: R² ist `NA_real_`, wenn die Zielwerte einer Regression numerisch konstant sind. Der Plan setzt R² nur bei TSS = 0 auf `NA` (Z. 99). Bei bis auf die Rundung gleichen Abweichungen gäbe er etwa 0,7506 aus (Prüflauf 2, (b)).
  - E9, ADR-052 Nr. 17.2.2: Ein Überlauf der Differenz ist ein benannter Fehler. Sonst gilt die Gleichung `n + n_excluded` = Zahl der Eingabezeilen (Z. 74) nicht.
- **Neu in dieser Phase:** `docs/decisions/ADR-052-m3a-reviewer-auslegungen.md`:
  - Status, Kontext („Gemessen in Runde 2“) und Konsequenzen sind nachgeführt;
  - Nr. 17 enthält jetzt je Befund E1 bis E3 die Mindestanforderung und die Form aus `PLAN-UPDATE.md`;
  - Nr. 19 ist neu: die Formen zu E4, E5, E7 und E10.
  - `CRITERIA.json` bleibt unverändert.

### An den Betreiber

1. **Keine Zuarbeit vor BUILD nötig.** `orchestrator/state/mut-baseline` fehlt weiterhin, wie BL-123 verlangt. Die drei AIAG-Datenblätter liegen vor (ADR-052 Nr. 15).
2. **Zur Planung (unverändert aus Runde 1, Hochrechnung):** Die Vignette rechnet ihre Bias-Tabelle beim Knit mit 2 × 1000 Aufrufen von `msa_bias()`. Auf v0.1.0 kostet das etwa 6,6 s, und der Knit läuft in mutgate je Mutant. Der Builder misst den ganzen Knit vor und nach der Änderung (PLAN-UPDATE Z. 284).

### Ablauf

Mit PASS gibt der Orchestrator den Plan frei und setzt den Tag `plan/M3a`; danach folgt `40-build`. BUILD folgt `PLAN.md`, `PLAN-UPDATE.md` und ADR-052. Weichen die Pläne von ADR-052 Nr. 17 oder Nr. 19 ab, gilt das ADR.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/prompts/30-plan-review.md`; `orchestrate.sh` (`path_allowed` Z. 515–544, Planschleife Z. 946–978).
- **Spezifikation:** docs/04 M3a (Ergebnissatz, K-M3a-1 bis K-M3a-7); docs/01 §1 bis §9; Formelsammlung §1, §5, §6.
- **Handoff M3a:**
  - `CRITERIA.json` (sieben Kriterien, ACC-1 bis ACC-17);
  - `PLAN.md` und `PLAN-UPDATE.md` vollständig;
  - `PLAN-REVIEW.md` und `verdict-plan.json` der Runde 1.
- **ADRs:** ADR-052 vollständig, ADR-022 Nr. 7, ADR-048 Nr. 14.5.
- **Abnahmetests:**
  - vollständig: `setup-m3a.R`, `test-m3a-1`, `test-m3a-5`, `test-m3a-6`, `test-m3a-7`;
  - in Teilen: `test-m3a-2` Z. 120–177, `test-m3a-4` Z. 20–69 und alle Aufrufe, `test-m3a-3` alle Aufrufe;
  - `tests/simulation/test-bias-coverage.R` Z. 20–75;
  - außerhalb von M3a: `setup-m1a.R` Z. 519–523 und 540–580, `setup-m1c.R` Z. 595–640, `setup-m2.R` Z. 855–894, `test-m1d-7-findings.R` Z. 52–100.
- **Produktcode und Bestand:**
  - `R/agreement.R` vollständig;
  - `R/acmg.R` Z. 155–228, 855–875, 974–1063, 1170–1230; `R/plan.R` Z. 1–36;
  - `vignettes/validation.Rmd` (Überschriften), `vignettes/llmsa.Rmd` Z. 100–150;
  - `tests/testthat/helper-validation-latent.R` Z. 45–140, `test-validation-latent.R` Z. 118–160;
  - Ankerkopien unter `inst/validation/latent/anchors/` und `inst/validation/m1d/anchors/`: ANK-06 und ANK-TOL sind byte-gleich mit `reference/anchors/` (`sha256sum`).
  - Aufrufer von `msa_agreement()` und `msa_bias()` per Suche über `R/`, `tests/`, `vignettes/` und `inst/`.

## Eigene Prüfläufe

Drei R-Skripte unter `orchestrator/handoff/M3a/.probe-plan-review-r2/`, mit `Rscript --vanilla` aus der Repo-Wurzel; das Verzeichnis ist am Ende gelöscht. R 4.6.1, pkgload 1.5.3, testthat 3.3.2. Produktcode ist v0.1.0. Die Mathematik der Pläne ist in den Proben unabhängig von `R/agreement.R` nachgebaut. Außer ADR-052 hat sich seit dem Schreiben von `PLAN-UPDATE.md` keine Datei geändert (`find -newer`, ohne Orchestrator-Zustand).

1. **Aufrufer und Daten gegen E1 und E2.** `callers.R`, Paket mit `pkgload::load_all()`. Ausgabe:

   ```text
   acmg_demo (llmsa.Rmd, test-report) items   60, rows  2160, items with NA reference   0, conflicting items 0, references outside levels 0, empty strings 0
     acmg_demo levels derived from responses: B LB LP P VUS
   ic50_demo (msa_bias examples)      items   40, rows  2160, items with NA reference   0, conflicting items 0, references outside levels NA, empty strings 0
     ic50_demo: rows 2160, missing values 8, prompt x model conditions 9, conditions without a valid value 0
   llmsa.Rmd num$latent as reference  items   30, rows   540, items with NA reference   0, conflicting items 0, references outside levels NA, empty strings 0
   AP1 items.csv + pilot.csv          items  110, rows   110, items with NA reference  25, conflicting items 0, references outside levels 0, empty strings 0
     AP1 classes: Benign Likely benign Uncertain significance Likely pathogenic Pathogenic ; sources without reference: insaid 25
   as.character round trip identical: FALSE FALSE FALSE | as.character: 0.333333333333333 0.3 10
   ```

   - Abgedeckt sind die Einstiegsvignette (`msa_agreement()` mit `levels = tiers`, `msa_bias(num, reference = "reference")` mit `num$reference <- num$latent`), die Hilfebeispiele, `test-report.R` und AP1 (`R/acmg.R:1224`).
   - AP1 liest leere Referenzen als `NA` (`na.strings = ""`, `R/acmg.R:212`). `acmg_evaluate()` lehnt Klassen außerhalb der Skala schon vorher ab (Z. 1185–1187). Der M2-Abnahmetest setzt leere Referenzen ebenfalls auf `NA` (`setup-m2.R:875–876`).
   - Alle M3a-Abnahmetests übergeben `levels` ausdrücklich, und ihre Referenzen liegen darin. Das gilt auch für die Tafel mit leerer Zeile und Spalte (`test-m3a-1` Z. 133–140) und für das Item i6 von D1 ohne gültige Antwort (`test-m3a-4` Z. 31–32).
   - Die E2E-Tests und die ClinVar-Vignette rufen `msa_agreement()` ohne Referenz.
   - Die letzte Zeile gehört zu E9.
2. **Numerik der Regeln von E3.** `numerics.R`, ohne Paket. Ausgabe:

   ```text
   R 4 6.1
   (a) 20000 cases: plan rule constant 16715, t.test error 15241, exactly zero 1474
       plan rule (sd/sqrt(n)) differs from 't.test error or all zero': 0; with sqrt(var/n): 0
   (b) answers = reference + bias, deviations constant up to rounding
       x 2,4.., bias  0.30: sd 4.39e-16, plan rule constant TRUE, TSS 1.14e-29, RSS 2.84e-30, R2 (plan formula) 0.7506, summary.lm R2 0.6960 (essentially perfect fit: summary may be unreliable)
       x 2,4.., bias  0.70: sd 4.39e-16, plan rule constant TRUE, TSS 1.14e-29, RSS 2.84e-30, R2 (plan formula) 0.7506, summary.lm R2 0.5473 (essentially perfect fit: summary may be unreliable)
       x 1.1,2.3.., bias  0.10: sd 2.01e-16, plan rule constant TRUE, TSS 4.44e-31, RSS 1.83e-31, R2 (plan formula) 0.5867, summary.lm R2 0.6135 (none)
       x 0.5,1.5.., bias -0.20: sd 9.76e-17, plan rule constant TRUE, TSS 1.05e-31, RSS 3.96e-32, R2 (plan formula) 0.6223, summary.lm R2 0.6215 (essentially perfect fit: summary may be unreliable)
       x 10,20.., bias  0.03: sd 5.42e-16, plan rule constant FALSE, TSS 8.52e-30, RSS 6.20e-30, R2 (plan formula) 0.2727, summary.lm R2 0.2713 (none)
   (c) bias = 0.1 + 0.05 x plus relative noise
       rel noise 0e+00: sqrt(RSS)/sqrt(TSS) 1.61e-15, plan rule vanishing TRUE, t_slope (own) 4.739e+15, summary.lm warning: essentially perfect fit: summary may be unreliable
       rel noise 1e-15: sqrt(RSS)/sqrt(TSS) 3.06e-15, plan rule vanishing FALSE, t_slope (own) 2.488e+15, summary.lm warning: none
       rel noise 1e-13: sqrt(RSS)/sqrt(TSS) 2.58e-13, plan rule vanishing FALSE, t_slope (own) 2.952e+13, summary.lm warning: none
       rel noise 1e-10: sqrt(RSS)/sqrt(TSS) 2.57e-10, plan rule vanishing FALSE, t_slope (own) 2.958e+10, summary.lm warning: none
       rel noise 1e-06: sqrt(RSS)/sqrt(TSS) 2.57e-06, plan rule vanishing FALSE, t_slope (own) 2.958e+06, summary.lm warning: none
   ```

   - (a): Zufallsfälle mit n = 2 bis 60, Mittel 0,3, 1, 7,5, 1e3, 1e-3, −2 oder 0 und relativem Rauschen von 10^−17,5 bis 10^−13,5. Seed 20261105, RNG Mersenne-Twister/Inversion/Rejection. Die Regel von PLAN-UPDATE Z. 89 gleicht der Abbruchregel von `stats::t.test`, ergänzt um exakt 0, und zwar mit SE = s/√n wie mit √(var/n).
   - (b): Die Konstanzregel führt diese Fälle in den entarteten Zweig. Weil TSS > 0 ist, gäbe Z. 99 als R² eine Zahl aus der Rundung, keine Eigenschaft der Daten (E8). Im fünften Fall greift die Regel knapp nicht; dort rechnet auch `stats::t.test`, und der Plan gleicht ihm, wie K-M3a-5 verlangt.
   - (c): Die Restregel von Z. 97 greift nur auf der exakt linearen Abweichung. Ab relativem Rauschen von 1e-15 bleibt die eigene t-Rechnung endlich und ohne Meldung.
3. **Backlog-Abdeckung.** `backlog.R`. Ausgabe:

   ```text
   BACKLOG ids 131 (unique 131); PLAN-UPDATE rows 90 (unique 90); closed list 41 (unique 41)
   missing from PLAN-UPDATE:
   in both lists:
   not in BACKLOG:
   same open set as PLAN round 1: TRUE
   ```

   Die offene Menge ist dieselbe wie in Runde 1. Dort war geprüft, dass alle 41 erledigten Einträge einen Erledigungs- oder Behebungsvermerk tragen (PLAN-REVIEW r1, Prüflauf 4).

## Antworten auf die Einwand-IDs

- **[E1] erledigt.** PLAN-UPDATE Z. 13 und 49–58 erfüllen ADR-052 Nr. 17.1 und folgen dem Vorschlag der Runde 1 in allen vier Punkten:
  - benannter Fehler für Referenzwerte außerhalb der übergebenen oder abgeleiteten Skala, auch wenn die Antworten des Items fehlen; keine Vereinigung mit der Skala, also bleiben K, Gewichte und Skalenpositionen unabhängig von der Referenz (Z. 54–55);
  - benannter Fehler bei widersprüchlichen Referenzen in allen drei Eingabeformen, gleich in welcher Zeilenfolge (Z. 52);
  - Unit-Tests für alle Gewichtungen und beide Kappa-Felder gegen die Rechnung über die volle Skala (Z. 267, 279);
  - Rückwirkung auf AP1, M1d und Bericht (Z. 58, 142, 283). Prüflauf 1 zeigt, dass kein bestehender Pfad an den neuen Fehlern scheitert.
  - Eine Referenz neben fehlenden Einträgen gilt als die Referenz des Items (Z. 53); in v0.1.0 hing das von der Zeilenfolge ab (`R/agreement.R:111–112`). Die Formelsammlung kennt eine Referenz je Item („Referenz x_i: der von Experten kuratierte Wert oder die Klasse des Items i“, §1).
  - Hinweise: E9 (Nr. 2) und E11 (Nr. 2).
- **[E2] erledigt.** PLAN-UPDATE Z. 14 und 72–85 erfüllen ADR-052 Nr. 17.2:
  - `n_excluded` in `overall` (am Ende) und als letzte Spalte von `by_condition`;
  - jede beobachtete Bedingung bleibt, ohne gültiges Paar mit `n = 0` und `NA`;
  - kein gültiges Paar insgesamt ist ein benannter Fehler;
  - Druckausgabe und Abschnitt 5 nennen die Zahlen, alte Objekte zeigen „not recorded“;
  - die Zählfixture steht in Z. 280.
  - Die Abnahmetests lesen `overall` und `by_condition` über Namen (`test-m3a-5` Z. 11–27, 60–63); das angehängte Feld stört sie nicht.
  - Hinweis: E9 (Nr. 1, Überlauf).
- **[E3] erledigt.** PLAN-UPDATE Z. 15 und 89–111 erfüllen ADR-052 Nr. 17.3:
  - kein Aufruf von `stats::t.test`, `stats::lm` oder `summary.lm` (Z. 15, 95);
  - t und p aus eigener Rechnung, gleich `stats::t.test`, wo dieses rechnet (Z. 91);
  - relative Konstanzregel mit der Grenze von `stats::t.test` (Z. 89; Prüflauf 2, (a));
  - relative Restregel für beide Regressionen (Z. 97; Prüflauf 2, (c));
  - Band und Entscheidung im entarteten Fall folgen der Regel q(z) ≤ 0 mit Q = 0 (Z. 99, 111);
  - Raster über die ganze Fehlerklasse (Z. 281), wie LESSONS verlangt.
  - Lücke: R² bei numerisch konstanten Zielwerten, siehe E8.
- **[E4] akzeptiert** (Z. 16, 62, 108): `fleiss` enthält genau `kappa`, die Druckzeile nennt keinen Standardfehler, beide Linearitätsfelder sind Skalare ohne Namen. Festgehalten in ADR-052 Nr. 19.1.
- **[E5] akzeptiert** (Z. 17, 115–123): eigener Abschnitt der Ebene zwei hinter dem Bootstrap-Abschnitt; keine Zahlenliterale; Abstand in MCSE; die Berichtsschwelle wird benannt, der Knit bricht nicht ab; Knit-Laufzeit vorher und nachher. Festgehalten in ADR-052 Nr. 19.2. Hinweis: E10.
  - Geprüft: `vignettes/validation.Rmd` hat „## Bootstrap intervals: coverage by scenario“ (Z. 293) und danach „## Robustness screening: Plackett-Burman and Lenth“ (Z. 361). Ein neuer Abschnitt der Ebene zwei beendet den Bootstrap-Abschnitt, den K-M1c-5 liest.
  - Der Literalfilter der Abnahme (`setup-m1a.R:565–580`) und die transitive Quellenprüfung (`helper-validation-latent.R:51–111`) zählen nur Dezimal- und Exponentenliterale mit mindestens drei Stellen. Die Design- und Seed-Literale im Helfer fallen nicht darunter.
- **[E6] akzeptiert** (Z. 18, 282): vollständige Druckausgaben mit letztem Zeilenumbruch und unsichtbarer Rückgabe, jede Fehlermeldung genau und mit `conditionCall()` `NULL`, auch die bestehenden Pfade; keine Ausschlüsse.
- **[E7] akzeptiert** (Z. 19, 275): `skip_if_not_installed()` vor jedem Aufruf der drei Orakel in Unit-Tests; Formeltests laufen ohne sie. Festgehalten in ADR-052 Nr. 19.4.
- **Backlog:** Alle 131 Einträge sind zugeordnet, die offene Menge ist dieselbe wie in Runde 1 (Prüflauf 3). Gegen den Text geprüft: BL-09, BL-15, BL-44, BL-113, BL-123, BL-128, BL-131.

## Einwände (Runde 2)

- [E8] (minor) ADR-052 Nr. 16.5 („Nicht definierte Größen sind `NA`, nie `NaN`; das gilt auch für R² bei Gesamtstreuung null.“) und Nr. 17.3 („behandelt `msa_bias()` wie exakt gleiche“); docs/01 §2 Nr. 4; K-M3a-6; PLAN-UPDATE Z. 97–99 — **Befund:** Der Plan führt Zielwerte, die nach der SE-Regel numerisch konstant sind, in den entarteten Zweig (Z. 97). R² setzt er aber nur bei TSS = 0 auf `NA_real_`, sonst auf 1 − RSS/TSS (Z. 99).
  - Prüflauf 2, (b): Antworten = Referenz + 0,3 an den Referenzwerten 2, 4, 6, 8, 10 mit je 12 Werten. Die Abweichungen haben sd 4,4e-16, die Regel greift, TSS = 1,1e-29 > 0. 1 − RSS/TSS ist 0,7506; `summary.lm` gibt 0,6960 mit „essentially perfect fit“. Zwei weitere Fälle geben 0,5867 und 0,6223.
  - Bei exakt gleichen Abweichungen ist R² nicht definiert. Objekt und Bericht zeigten für eine konstante Abweichung ein R² von 75 %.

  — **Vorschlag:**
  1. R² beider Regressionen ist `NA_real_` mit Hinweis, sobald ihre Zielwerte TSS = 0 haben oder nach der SE-Regel numerisch konstant sind.
  2. Sonst gilt 1 − RSS/TSS, bei verschwindenden Resten also nahe 1.
  3. Das Raster prüft das für beide Regressionen.

  Bindend festgehalten in ADR-052 Nr. 17.3.6.
- [E9] (minor) ADR-052 Nr. 17.2; PLAN-UPDATE Z. 72 und Z. 74 („Nach obiger Referenzauflösung gilt `n + n_excluded = Zahl der Eingabezeilen`, insgesamt und je beobachteter Bedingung.“); docs/01 §2 Nr. 4 — **Befund:**
  1. Ist die Differenz zweier endlicher Werte nicht endlich (Überlauf), führt sie nach Z. 72 „zu einer klaren Meldung“, und die Zeile ist ungültig. `n_excluded` zählt nach Z. 74 aber nur fehlende Werte. Die Zeile stünde weder in `n` noch in `n_excluded`, und die Gleichung von Z. 74 gälte nicht.
  2. v0.1.0 liest Antwort und Referenz über `as.character()` (`R/agreement.R:112`, `:116`, `:118`, `:223`). Das behält 15 signifikante Stellen; nach Prüflauf 1 ändern sich 1/3, 0,1 + 0,2 und 10 + 1e-14 im Rundlauf. Konstanzregel (Z. 89) und Konfliktprüfung (Z. 52) urteilten dann über gerundete Werte. Vergleicht der Builder dagegen die Zahlen selbst, kann eine Konfliktmeldung im Standardformat zwei gleich aussehende Werte zeigen („0.3, 0.3“).

  — **Vorschlag:**
  1. Überlauf ist ein benannter englischer Fehler. Bindend festgehalten in ADR-052 Nr. 17.2.2.
  2. Numerische Eingaben werden als Zahlen gelesen, ohne Umweg über `as.character()`. Nur Zeichenketten und Faktorbeschriftungen gehen durch `as.numeric()`.
  3. Konflikte werden auf den gelesenen Zahlen geprüft. Die Meldung zeigt die Werte so, dass sie sich unterscheiden, etwa mit `format(x, digits = 17)`.
- [E10] (minor) K-M3a-7; ACC-15; `tests/acceptance/setup-m1a.R:519–523` (`acc_m1a_column()`); `tests/acceptance/setup-m3a.R:624–635`; `tests/acceptance/test-m3a-7-vignette.R:43` — **Befund:** Der Abnahmetest nimmt eine Spalte nur, wenn genau eine Überschrift (klein geschrieben, ohne Rand) mit dem gesuchten Wort beginnt. Der Plan gibt der Tabelle eine fünfte Spalte mit dem Abstand in MCSE (Z. 121).
  - Hieße sie etwa „coverage − level (MCSE)“ oder „MCSE distance“, begännen zwei Überschriften mit „coverage“ bzw. „mcse“. Der Test fände dann keine Tabelle, und K-M3a-7 wäre rot.
  - n_sim liest der Test als Ziffernfolge, alle anderen Zeichen entfernt: aus „1e+03“ würde 103.

  — **Vorschlag:**
  1. Die Überschriften lauten scenario, coverage, MCSE und n_sim. Die Abstandsspalte beginnt mit keinem dieser Wörter, etwa „distance to level (MCSE)“; ebenso jede weitere Spalte.
  2. n_sim steht als ganze Zahl ohne Exponent.

  Festgehalten in ADR-052 Nr. 19.3.
- [E11] (minor) docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung“); K-M3a-2; ADR-052 Nr. 14 und Nr. 16.2; PLAN-UPDATE Z. 54 und Z. 64 — **Befund:**
  1. Z. 64 gibt jedem nicht schätzbaren Fleiss-Fall einen Hinweis auf Krippendorffs Alpha. Das schließt P̄_e = 1 und weniger als zwei Bewertungen je Item ein. Dort ist auch das Alpha von `msa_agreement()` `NA`: bei D_e = 0 (`R/agreement.R:180`) und ohne Einheit mit zwei Werten (Z. 161, 167).
  2. Die Beispielmeldung von Z. 54 nennt die Werte ohne Anführungszeichen. Eine leere Zeichenkette als Referenz wäre unsichtbar („…: .“).

  — **Vorschlag:**
  1. Der Verweis auf Krippendorff steht bei ungleicher Zahl gültiger Bewertungen, auch für ein Item ohne gültige Antwort (K-M3a-2, ADR-052 Nr. 14).
  2. In den anderen Fällen nennt die Meldung den Grund: gleiche Antworten auf allen Items oder weniger als zwei Bewertungen je Item.
  3. Werte in Meldungen stehen in Anführungszeichen, etwa mit `encodeString(x, quote = "\"")`.

## Prüfung nach Gesichtspunkten

- **Spec-Treue:**
  - K-M3a-1 bis K-M3a-4: wie Runde 1. Dazu die Referenzregeln für beide Kappa-Felder (Formelsammlung §5: p_cd über die Paare aus Antwort und Referenz).
  - K-M3a-5: t-Intervall und p aus eigener Rechnung, gleich `stats::t.test`, gesamt und je Prompt × Modell.
  - K-M3a-6: Handbuchrechnung und Item-Mittelwerte ohne `lm`; Band, Verdikt und Hinweis wie ADR-052 Nr. 10, 11 und 16.6; entartete Fälle nach Nr. 17.3.
  - K-M3a-7: Szenarien, Seeds 20261106 und 20261107, RNG und Ziehungsfolge gleich der Klasse-A-Studie (`test-bias-coverage.R` Z. 23–60).
- **Architektur:**
  - Eine gemeinsame Referenzauflösung für beide Funktionen.
  - Die Produktarbeit bleibt in `R/agreement.R`; Fit-, Bootstrap-, AP1- und Robustheitskern bleiben unberührt.
  - Der Vignettenhelfer lädt sich mit `sys.source(system.file(…))` und wörtlichen Argumenten, trägt das Präfix `agreement_`, rechnet mit dem geladenen Namespace und nutzt die vorhandenen, byte-gleichen Ankerkopien.
- **Verträge:**
  - Nur zusätzliche Felder und Druckänderungen (docs/01 §4); Signaturen und ANK-02 bleiben.
  - Die neuen Eingabefehler ersetzen stille falsche Zahlen, etwa bei Referenzen außerhalb der Skala oder bei widersprüchlichen Referenzen; die Bedeutung keines Arguments ändert sich.
  - Die Abnahmetests greifen über Namen zu; nach Prüflauf 1 brechen keine bestehenden Aufrufer.
- **Vollständigkeit:**
  - Dateiliste, Reihenfolge und Testplan decken alle sieben Kriterien und E1 bis E7 ab; alle 131 Backlog-Einträge sind zugeordnet.
  - Offene Details sind E8 bis E11; die bindenden davon stehen in ADR-052.
- **Risiken:** Die Tabelle (Z. 140–147) nennt die richtigen Klassen. Hinzu kommt das Risiko der Spaltennamen (E10). Die Laufzeit des Knits je Mutant wird gemessen, nicht geschätzt.
- **Gate-Abdeckung:**

  | Kriterium | Prüfweg | Gates |
  | --- | --- | --- |
  | K-M3a-1 bis K-M3a-6 | `tests/acceptance/test-m3a-1` bis `-6` | tests; mutgate je Mutant |
  | K-M3a-7 | `tests/simulation/test-bias-coverage.R`, `tests/acceptance/test-m3a-7-vignette.R` | tests; lint (Bau der Vignetten); mutgate je Mutant nur der Vignettenteil |
  | alle | Kriteriums-IDs in `tests/acceptance` | trace |
  | Suggests | `DESCRIPTION` | deps |
  | Anker, Golden-Daten | keine Änderung nach `plan/M3a` | golden-adr |
  | Pfade | Dateiliste des Plans | territory |

## Hinweise für BUILD

- **Vertrag:** `PLAN.md`, `PLAN-UPDATE.md` und ADR-052 Nr. 1 bis 19. Vorrang hat das ADR, insbesondere Nr. 17.2.2 (Überlauf) und Nr. 17.3.6 (R²). Das Code-Review prüft gegen Nr. 1 bis 17 und Nr. 19.
- **Minor-Befunde der Runde 1** (dieses Dokument ersetzt `PLAN-REVIEW.md` der Runde 1):
  - E4: keine Druckzeile, die „Fleiss“ und „SE“, „standard error“ oder „std err“ nennt; in `fleiss` kein Name nach `acc_m3a_se_pattern` (`setup-m3a.R:246`), auch keine Teilnamen wie `n_sd`.
  - E5: in `validation.Rmd` kein Literal, das einem ANK-TOL-Wert gleicht (etwa 1e-8).
  - E6: Drucktests vergleichen die ganze Ausgabe von `capture.output(print(x))` mit Zeilen, die der Test aus dem Objekt bildet; die Tests bleiben schnell, weil sie je Mutant laufen.
  - E7: `skip_if_not_installed()` vor jedem Aufruf von irr, psych oder DescTools in Unit-Tests.
- **Prüfumfang** laut PLAN-UPDATE Z. 290–314, mit `REPO_ROOT` und `options(testthat.progress.max_fails = Inf)`. Den AP1-Vergleich mit `msa_agreement()` in `setup-m2.R` Z. 873–882 deckt der Gate-Lauf ab.
- **Hilfeseiten** nur aus roxygen erzeugen; übernommen werden nur `man/msa_agreement.Rd` und `man/msa_bias.Rd`.
- **Datenblätter** nicht kopieren und nicht in Tests unter `tests/testthat/` lesen (BL-09).
