# ADR-052 — Auslegungen des Reviewers zu M3a: Prüfformen K-M3a-1 bis K-M3a-7 (ACC-3 bis ACC-16), Abgleich der AIAG-Datenblätter, Festlegungen zum Plan

## Status

Angenommen (Reviewer, `30-plan-review` M3a, Runde 1, 05.11.2026; ergänzt in Runde 2, 05.11.2026: Nr. 17 und Nr. 19). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 14 halten die Auslegungen fest, die `orchestrator/handoff/M3a/CRITERIA.json` unter `open` als ACC-3 bis ACC-16 führt.
  - ACC-1 kündigt dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh:518`, `path_allowed`).
  - `PLAN.md` (Runde 1) übernimmt diese Auslegungen (Abschnitt „Ziel“, Z. 11–19).
- Nr. 15 hält Anker und geschützte Daten fest (ACC-1, ACC-2), mit dem Abgleich der drei AIAG-Datenblätter am Seitenbild.
- Nr. 16 bestätigt Festlegungen aus `PLAN.md`. Darunter sind die Randfallvorschläge, die der Plan dem Reviewer zur Entscheidung vorlegt (Schnittstellen, Z. 111).
- Nr. 17 nennt die Mindestanforderungen zu den blocking-Befunden E1 bis E3 aus PLAN-REVIEW M3a r1. Das Plan-Review der Runde 2 trägt die Form aus `PLAN-UPDATE.md` nach, mit zwei Präzisierungen des Reviewers (Nr. 17.2.2 und Nr. 17.3.6).
- Nr. 18 ist ein Hinweis zum Mutationsumfang, keine neue Regel.
- Nr. 19 bestätigt die Formen aus `PLAN-UPDATE.md` zu den minor-Befunden E4, E5 und E7 der Runde 1 und nennt die Spaltennamen der Überdeckungstabelle (E10 der Runde 2).
- Die Nummern ändern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen. Einzelheiten stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M3a-1: wie das gewichtete Kappa des Beispiels von Cohen (1968) mit den drei Gewichtungen des Pakets zusammenhängt; Skala und Aufruf der drei Orakel; Form des Hinweises;
  - K-M3a-2: wer die „Bewerter“ eines Items im Datenmodell sind; Name und Form des Ergebnisses; was als Standardfehler gilt; Form der Meldung;
  - K-M3a-3: wo und wie die ausgeschlossenen Einheiten gezählt werden; was „dokumentiert“ heißt;
  - K-M3a-4: Nenner bei fehlenden Antworten; Einheiten der Reproduzierbarkeit; wie die Kappa-Tabelle des Handbuchs auf `msa_agreement()` abgebildet wird;
  - K-M3a-5 und K-M3a-6: Namen und Form der neuen Ergebnisfelder; der Fall mit nur einem Referenzwert; Inhalt des Hinweises auf den Unterschied beider Rechnungen; wann Abweichungen und Reste numerisch konstant bzw. null sind und was dann gilt (docs/01 §2 Nr. 4 verlangt nur „eine richtige Zahl oder eine klare Fehlermeldung“);
  - K-M3a-7: Datenerzeugung, Seeds und Bestehensprüfung der Studie; Form der Tabelle in der Vignette.
- **Gemessen in dieser Phase** (PLAN-REVIEW M3a, Runde 1, Prüfläufe 1 bis 6; R 4.6.1, testthat 3.3.2, irr 0.85; Arbeitsbaum ohne Produktänderung; Proben unter `orchestrator/handoff/M3a/.probe-plan-review/`, danach gelöscht):
  - Datenblätter: Datei- und Inhaltsprüfsummen, Textschicht und Seitenbild (Nr. 15).
  - M3a-Abnahme auf dem heutigen Stand, mit den gelieferten Datenblättern: 35 Tests, 628 Erwartungen, 34 rot, 8 Fehlerblöcke, 0 übersprungen, 28,1 s. Grün sind unter anderem beide AIAG-Attributtests (K-M3a-4); der Test der AIAG-Biasstudie (K-M3a-5) bricht mit „subscript out of bounds“ ab.
  - v0.1.0 mit `levels = NULL`, Antworten a, a, b, b, a, b und Referenz a, a, b, c, c, b:
    - `kappa_all_vs_reference` ist 0,571429 für alle drei Gewichtungen, ohne Meldung;
    - richtig (Skala a, b, c; Mini-Referenz und `irr::kappa2`) sind 0,500000, 0,400000 und 0,285714;
    - die Kreuztafel summiert sich auf 0,6667;
    - mit `levels = c("a", "b")` ebenso (E1).
  - v0.1.0, Item mit den Referenzen 2 und 5: mittlerer Bias 0,0000 oder −1,5000, je nach Reihenfolge der Zeilen, ohne Meldung (E1).
  - v0.1.0, `msa_bias()`:
    - Abweichungen, die sich nur in der Rundung unterscheiden (sd 3,2e-17, zwei Referenzwerte), enden mit „data are essentially constant“ aus `stats::t.test`;
    - `summary(lm)` warnt dabei „essentially perfect fit: summary may be unreliable“ (E3);
    - eine Bedingung Prompt × Modell ohne gültigen Wert fehlt ohne Meldung in `by_condition` (E2).
  - Bandprüfung nach `PLAN.md` (Maximum von q(z) über den Bereich) gegen `acc_m3a_in_band_ref()`: auf 4000 Zufallsplänen (3 bis 8 Items, 2 bis 6 Replikate; Fälle mit relativem Rand unter 1e-6 ausgenommen) 4000 gleich; die Testfälle acceptable, handbook_rejects und between_references gleich.
  - Laufzeit: 200 Aufrufe von `msa_bias()` v0.1.0 auf 540 Werten dauern 0,66 s; hochgerechnet etwa 6,6 s für 2 × 1000.
- **Gemessen in Runde 2** (PLAN-REVIEW M3a, Runde 2, Prüfläufe 1 bis 3; R 4.6.1; Produktcode v0.1.0 unverändert; Proben unter `orchestrator/handoff/M3a/.probe-plan-review-r2/`, danach gelöscht):
  - Daten der bestehenden Aufrufer von `msa_agreement()` und `msa_bias()`: `acmg_demo` (60 Items), AP1-Items aus `items.csv` und `pilot.csv` (110 Items, davon 25 INSAID-Items mit fehlender Referenz `NA`), `ic50_demo` (40 Items), `msa_simulate()` der Einstiegsvignette (30 Items, `latent` je Item konstant, `R/plan.R:28`). Jedes Item hat höchstens eine Referenz, keine liegt außerhalb der Skala, keine ist eine leere Zeichenkette. Die Regeln von Nr. 17.1 lösen auf diesen Pfaden keinen neuen Fehler aus.
  - Konstanzregel von Nr. 17.3.2 (SE = s/√n): auf 20000 Zufallsfällen nahe der Grenze in jedem Fall dieselbe Entscheidung wie „`stats::t.test` bricht mit ‚data are essentially constant‘ ab oder alle Werte sind 0“; mit SE = √(var/n) ebenso.
  - Antworten = Referenz + 0,3 an den Referenzwerten 2, 4, 6, 8, 10 (je 12 Werte): sd der Abweichungen 4,4e-16, die Konstanzregel greift, TSS = 1,1e-29 > 0, 1 − RSS/TSS = 0,7506; `summary.lm` gibt 0,6960 mit „essentially perfect fit“. Zwei weitere Fälle: 0,5867 und 0,6223 (Nr. 17.3.6).
  - Restregel von Nr. 17.3.5 (b): auf der exakt linearen Abweichung 0,1 + 0,05 · x ist √RSS/√TSS = 1,6e-15 ≤ 10 ε, die Regel greift; bei relativem Rauschen von 1e-15 bis 1e-6 greift sie nicht, und die eigene t-Rechnung bleibt endlich.
  - `as.character()` einer Zahl behält 15 signifikante Stellen: 1/3, 0,1 + 0,2 und 10 + 1e-14 ändern sich im Rundlauf `as.numeric(as.character(x))`.

## Entscheidung

1. **(ACC-3) Beispiel von Cohen (1968), K-M3a-1.**
   1. κ = .492 (ungewichtet) prüft der Test am Paket: `kappa_all_vs_reference` und `kappa_modal_vs_reference` von `msa_agreement()` auf den 200 Paaren der Tab. 1. Je Paar gibt es ein Item; Judge B ist die Antwort, Judge A die Referenz.
   2. κ_w = .348 und .574 beruhen auf den Nichtübereinstimmungsgewichten 0/1/3/6 (ANK-70). Keine der drei Gewichtungen des Pakets bildet sie ab. Der Test prüft sie an der Mini-Referenz der Formelsammlung §5 mit w = 1 − v/v_max, an `psych::cohen.kappa` (Nichtübereinstimmungsgewichte) und an `DescTools::CohenKappa` (Übereinstimmungsgewichte).
   3. Auf derselben Tafel gleichen die lineare und die quadratische Gewichtung von `msa_agreement()` der Mini-Referenz und den drei Orakeln.
   4. Eine freie Gewichtsmatrix verlangt der Vertrag nicht; `msa_agreement()` erhält kein Argument dafür.
2. **(ACC-4) Orakel, K-M3a-1.**
   1. Verglichen wird auf Daten, in denen jede Kategorie der Skala vorkommt: `irr::kappa2` bildet seine Skala aus den beobachteten Codes, und die gewichteten Kappas hängen von K ab.
   2. `irr::diagnoses`: Jedes der 15 Bewerterpaare erhält als Skala die Kategorien, die es verwendet, in Skalenordnung, für Paket und Orakel gleich. `irr::vision`: rechtes Auge als Antwort, linkes als Referenz (7477 Paare).
   3. Aufrufe:
      - `irr::kappa2` mit den Codes 1..K und `weight` "unweighted", "equal" oder "squared";
      - `psych::cohen.kappa` mit der Kreuztafel und den Nichtübereinstimmungsgewichten |i − j| bzw. (i − j)²;
      - `DescTools::CohenKappa` mit der Kreuztafel und "Unweighted", "Equal-Spacing" oder "Fleiss-Cohen".
      Die Kreuztafel des Pakets entsteht aus einem Item je Paar (erste Spalte Antwort, zweite Referenz).
   4. Konstruierte Tafeln: K = 2 bis 5 (Seeds 312 bis 315) und eine 4 × 4-Tafel mit leerer Zeile und leerer Spalte (Seed 319), RNG Mersenne-Twister/Inversion/Rejection.
   5. Toleranz ANK-TOL.package_compare.
3. **(ACC-5) Fehlende Antworten in den Attributkennzahlen, K-M3a-4.**
   1. Fehlende Antworten zählen weder als richtig noch als falsch. Trefferquote ist der Anteil der gültigen Antworten, die der Referenz gleichen, gesamt und je Prompt × Modell.
   2. Anteil vollständig richtiger Items: Anteil der Items mit mindestens einem gültigen Vergleich, deren gültige Vergleiche alle richtig sind. Ein Item ohne gültigen Vergleich geht nicht ein; v0.1.0 zählt es über `all(logical(0))` als richtig.
   3. Modalantwort: die häufigste gültige Antwort; bei Gleichstand die niedrigste der gleich häufigen Kategorien in Skalenordnung (Formelsammlung §5); ohne gültige Antwort `NA`.
   4. „Exakt“ heißt ANK-TOL.arithmetic auf der Prozentskala, geprüft an den Handwerten der Datensätze D1 und D2 (Brüche mit Zählkommentar in `test-m3a-4-attribute.R`) und an der Mini-Referenz.
4. **(ACC-6) Einheiten der Wiederholbarkeit und Reproduzierbarkeit, K-M3a-4.**
   1. Wiederholbarkeit: Zellen Item × Prompt × Modell, je Prompt × Modell und gesamt.
   2. Reproduzierbarkeit über Prompts: Einheiten Item × Modell mit allen Prompts und Replikaten; über Modelle: Item × Prompt; über alle Bedingungen: Item.
   3. Es zählen nur Einheiten mit mindestens zwei gültigen Antworten. Blöcke trennen keine Einheit.
5. **(ACC-7) Kappa-Tabelle der AIAG-Attributstudie, K-M3a-4.**
   1. Tab. III-C 3 vergleicht die Prüfer paarweise über 150 Paare (Teil, Durchgang). Der Test bildet die Paare selbst, prüft sie gegen die Kreuztabellen der Tab. III-C 2 und rechnet sie mit Cohens Kappa von `msa_agreement()` (ein Item je Paar; erster Prüfer Antwort, zweiter Referenz). Ein Kappa zwischen Prompts wird kein Ergebnisfeld.
   2. Kappa gegen die Referenz (S. 138): `kappa_all_vs_reference` auf den 150 Entscheidungen eines Prüfers (Prüfer = Prompt, Durchgang = Replikat) mit der Referenzentscheidung je Teil.
   3. Über den Wortlaut hinaus ist Tab. III-C 5 die zweite Quelle der Attributkennzahlen auf denselben Daten: Wiederholbarkeit je Prüfer, vollständig richtige Teile je Prüfer, Übereinstimmung aller Prüfer, zugleich mit der Referenz.
6. **(ACC-8) Fleiss' Kappa, K-M3a-2.**
   1. Die Bewertungen eines Items sind alle seine gültigen Antworten über Prompts, Modelle, Blöcke und Replikate. Gleiche Bewerterzahl heißt gleiche Zahl gültiger Antworten je Item, mindestens zwei.
   2. `fleiss` ist ein Formalargument hinter `weights` mit der Vorgabe `FALSE`. Mit der Vorgabe hat das Ergebnis kein Element `fleiss` (Verhalten v0.1.0). Mit `TRUE` trägt es die Liste `fleiss` mit dem numerischen Element `kappa` der Länge 1 (κ_F).
   3. Bei ungleicher Zahl ist `kappa` `NA_real_`, nicht `NaN`, mit der Meldung nach Nr. 14.
   4. Bei P̄_e = 1 (gleiche Antworten auf allen Items) ist `kappa` `NA_real_`, ohne Abbruch; die übrigen Kennzahlen bleiben (docs/01 §2 Nr. 4).
   5. Geprüft auf `irr::diagnoses` in drei Anordnungen der sechs Bewertungen (sechs Prompts; drei Prompts × zwei Replikate; zwei Modelle × drei Prompts) und auf drei konstruierten Datensätzen (Seeds 3201 bis 3203, einer mit je einer fehlenden Antwort je Item).
7. **(ACC-9) Standardfehler von κ_F, K-M3a-2.**
   1. Zulässig sind zwei Wege: kein Standardfehler oder einer nach Fleiss, Nee & Landis (1979), Gl. (12), der Varianz unter der Nullhypothese (ANK-72). `irr::kappam.fleiss` rechnet dieselbe Varianz (`value/statistic`).
   2. Als Standardfehler gilt jedes Element von `fleiss`, dessen Name ihn bezeichnet: Muster `acc_m3a_se_pattern` in `setup-m3a.R` (se, se0, ase, sd, std, stderr, std_err, standard_error, auch mit Präfix oder Suffix wie `kappa_se`). Jedes muss Gl. (12) auf ANK-TOL.package_compare treffen; auf `irr::diagnoses` sind das 0,024374, die Formel von Fleiss (1971), Gl. (16), gäbe 0,027503.
   3. Druckzeilen, die „Fleiss“ und „SE“, „standard error“ oder „std err“ nennen, zeigen diesen Wert.
8. **(ACC-10) Ausgeschlossene Einheiten, K-M3a-3.**
   1. Die Alpha-Tabelle erhält die Spalte `n_units_excluded`. Sie zählt je Bereich die vorkommenden Einheiten (Item × Prompt × Modell, Item × Modell, Item × Prompt, Item) mit weniger als zwei gültigen Antworten, auch solche ohne gültige Antwort. Nicht beobachtete Kombinationen zählen nicht.
   2. Krippendorffs Beispiel mit den Beobachtern als Prompts ergibt 48, 1, 48 und 1, als Replikate je 1. Drei angehängte Einheiten mit einer oder keiner gültigen Antwort ändern kein Alpha und erhöhen die Zahl in „all conditions“ um drei.
   3. Die Bereichsnamen der Spalte `scope` bleiben wie in v0.1.0.
9. **(ACC-11) Zuordnung der Gewichte, K-M3a-3.**
   1. „Dokumentiert“: Die Hilfeseite `man/msa_agreement.Rd` (roxygen in `R/agreement.R`) nennt jede Zuordnung in der Form „Gewicht (Metrik)“, „Gewicht → Metrik“, „Gewicht -> Metrik“, „Gewicht: Metrik“ oder „Gewicht = Metrik“, auch umgekehrt; Anführungszeichen und Code-Auszeichnung zählen nicht. Keine falsche Paarung steht in einer dieser Formen.
   2. „Getestet“: Jede Gewichtung trifft Mini-Referenz und `irr::kripp.alpha` der zugeordneten Metrik und keine der beiden anderen Metriken.
10. **(ACC-12) Linearität: Felder, Band und Verdikt, K-M3a-6.**
    1. Neue Rückgabefelder von `msa_bias()` (docs/01 §4: zusätzliche Felder ohne ADR):
       - `linearity` behält `intercept`, `slope` und `slope_p_value` vorn und erhält `r_squared` (Anteil, nicht Prozent), `t_intercept`, `t_slope`, `df` (gm − 2) und `t_quantile` (t_{gm−2; 1−(1−level)/2});
       - `linearity_item_means` mit `intercept`, `slope`, `r_squared`, `t_intercept`, `t_slope` und `df` (g − 2): Regression der ungewichteten Item-Mittelwerte der gültigen Abweichungen auf den Referenzwert des Items;
       - `linearity_band`: data.frame mit `reference`, `fit`, `lower` und `upper`, mindestens eine Zeile je Referenzwert der Items, Niveau = Argument `level`;
       - `linearity_in_band`: ein logischer Wert ohne Namen; wahr, wenn „Bias = 0“ über den ganzen Bereich vom kleinsten bis zum größten Referenzwert im Band liegt, nicht nur an den Referenzwerten (die untere Grenze ist konkav; Testfall between_references);
       - `linearity_verdict`: "acceptable" bei `linearity_in_band`, sonst "unacceptable", als Zeichenkette ohne Namen.
    2. Die Handbuchrechnung trägt das Verdikt (docs/01 §3 Nr. 2; Testfall handbook_rejects: Handbuchband ohne die Null, Item-Mittelwert-Band mit ihr).
    3. Bei nur einem Referenzwert liefert `msa_bias()` ein Ergebnis, sonst wäre K-M3a-5 auf der AIAG-Biasstudie nicht erfüllbar. Die Form steht in Nr. 16.5.
11. **(ACC-13) Unterschied beider Rechnungen, K-M3a-6.**
    1. Im Objekt die Zeichenkette `linearity_note`, im Bericht der Abschnitt „5. Bias and linearity“ von `msa_report(bias = …)`, gerendert als GitHub-Markdown.
    2. Beide nennen
       - (a) die Item-Mittelwerte („item mean“),
       - (b) Freiheitsgrade („degrees of freedom“ oder „df“),
       - (c) die Freiheitsgrade beider Rechnungen als Zahlen der Daten (im Test 18 und 3) oder als gm − 2 und g − 2,
       - (d) die Korrelation der Replikate eines Items („correlat…“, „dependen…“ oder „not independent“).
12. **(ACC-14) Überdeckungsstudie, K-M3a-7, Klasse A.**
    1. `tests/simulation/test-bias-coverage.R`: Referenz x_i ~ N(0, Item-σ²) als Itemwahrheit; Antwort y = x_i + Bias + e mit e ~ N(0, Rest-σ²), unabhängig je Item, Prompt, Modell und Replikat. Die Szenarien nennen keine Prompt-, Modell- oder Blockkomponente.
    2. Verfahren `msa_bias(level = 0.95)`, Intervall `overall[c("lower", "upper")]`.
    3. n_sim = ANK-06 `n_sim_min` (1000), Seeds 20261106 und 20261107, RNG Mersenne-Twister/Inversion/Rejection.
    4. Bestanden bei |c − 0,95| ≤ ANK-TOL.mc_factor (pass) · √(c(1 − c)/n_sim) mit der gemessenen Überdeckung c (Formelsammlung §9). Jedes Intervall gleicht der Mini-Referenz (ANK-TOL.package_compare).
13. **(ACC-15) Vignette, K-M3a-7.**
    1. Die gestrickte `vignettes/validation.Rmd` (gemeinsamer Knit, `acc_m1a_knit_validation()`) hat einen Abschnitt, dessen Überschrift „bias“ und „coverage“ nennt. Er enthält eine Pipe- oder HTML-Tabelle, deren Spalten mit scenario, coverage, MCSE und n_sim beginnen, mit den Zeilen S-bias-1 und S-bias-2; coverage als Anteil oder mit Prozentzeichen.
    2. Die gezeigten Werte erfüllen das Bestehenskriterium der Simulation mit dem Rundungsspielraum der gezeigten Stellen; n_sim ≥ ANK-06; MCSE = √(c(1 − c)/n_sim).
    3. Kein gezeigter Wert mit mindestens drei signifikanten Stellen steht als Literal im Rmd (wie K-M1c-5). Woher die Vignette die Zahlen nimmt, legt der Vertrag nicht fest; der Plan rechnet sie beim Knit (Nr. 16.8).
    4. Den Bau im `R CMD check` entscheidet das Gate lint.
14. **(ACC-16) Hinweis und Meldung, K-M3a-1 und K-M3a-2.**
    1. Hinweis und Meldung sind R-Bedingungen der Klasse `message` oder `warning`, die `msa_agreement()` signalisiert, ohne abzubrechen.
    2. Der Hinweis zu Kappa nennt „kappa“, die Meldung zu Fleiss nennt „Krippendorff“, jeweils ohne Rücksicht auf Groß- und Kleinschreibung.
    3. Geprüft für alle drei Gewichtungen mit drei Kategorien, von denen eine besetzt ist, und mit einer Skala aus einer Kategorie.
15. **(ACC-1, ACC-2) Anker und geschützte Daten.**
    1. Neu in `10-acceptance` M3a, vor dem Tag `plan/M3a`: ANK-70 (Cohen 1968), ANK-72 (Fleiss 1971 mit Fleiss, Nee & Landis 1979), ANK-73 (Krippendorff 2011) und ANK-74 bis ANK-76 (AIAG 2010: Attribut-, Bias- und Linearitätsstudie). Unverändert genutzt: ANK-02, ANK-06 und ANK-TOL (`arithmetic`, `package_compare`, `mc_factor`).
       - Die Literaturwerte sind am Original geprüft (ACC-1); geschützte Quellen stehen nur mit Kurzzitaten in den Ankern.
       - Dieses ADR ist das ADR im selben Meilenstein für diese Anker (docs/01 §6). Unter `inst/extdata/` ändert sich in M3a nichts.
    2. Geschützte Daten: Der Betreiber hat am 05.11.2026 unter `reference/quellen/data/aiag/` (git-ignoriert) drei Dateien angelegt und in `QUELLE.txt` beschrieben.

       | Datei | Zeilen | Bytes | SHA-256 der Datei |
       | --- | --- | --- | --- |
       | `attribute_study.csv` | 450 | 4906 | `c6d393eff6dc11665e13be8506714c79394477cac0f6ab4bdd2b635c91b01ab5` |
       | `bias_study.csv` | 15 | 228 | `9ddcba5ff48078b36385e7bd8adb5c4906372d99aba743c1fad5389d4550caab` |
       | `linearity_study.csv` | 60 | 894 | `cfefaecd2ef2089d7fbfd512c3cc06a828a03b3b00cfe6b8af7a893400292253` |

    3. Abgleich durch den Reviewer (05.11.2026):
       - Die SHA-256 der Original-PDF gleicht `source_url` der Anker (`aeb067807277a89a484844f33667eacfa2de4e3c70f66a042a83a815f73a2e5f`; Creator Acrobat PDFMaker 9.1 for Word, also echte Textschicht).
       - Die kanonische Form jeder Datei gleicht `content_sha256` ihres Ankers; gelesen mit `acc_m3a_aiag()` aus `setup-m3a.R`.
       - Die Textschicht gleicht den Dateien Zelle für Zelle (`.layout.txt` Z. 4411–4425, 4897–4908, 6634–6683). Die gedruckten Bias-Werte der Tab. III-B 1 und III-B 5 (Z. 4919–4930) sind gleich Messwert minus Referenzwert.
       - Am Seitenbild gelesen und gleich (pdftoppm, 150 dpi; PDF-Seiten 99, 108 und 143): die 15 Messungen der Tab. III-B 1, die 60 Messungen und 5 Referenzwerte der Tab. III-B 4 und die 450 Entscheidungen A-1 bis C-3 mit den 50 Referenzentscheidungen der Tab. III-C 1. Die Seitenbilder sind gelöscht.
    4. `data_file.status` von ANK-74 bis ANK-76 nennt noch „Datei fehlt (Stand 05.11.2026)“. Das Feld trägt keinen Wert, und kein Test liest es. Es wird mit der nächsten Änderung dieser Anker nachgeführt, die ohnehin ein ADR braucht. ACC-2 ist damit erledigt.
16. **Bestätigte Festlegungen aus `PLAN.md`** (Runde 1, Abschnitte „Schnittstellen“ und „Risiken“).
    1. Signatur `msa_agreement(runs, levels = NULL, reference = NULL, weights = c("unweighted", "linear", "quadratic"), fleiss = FALSE)`. `fleiss` ist ein einzelner, nicht fehlender logischer Wert, sonst ein benannter Fehler. ANK-02 bleibt unverändert (docs/01 §4; BL-57).
    2. Fleiss:
       - Marginalanteile aus den Daten, nicht aus gerundeten Druckwerten.
       - Ungleiche Zahl gültiger Antworten (auch ein Item ohne gültige Antwort), gleiche Zahl unter zwei und P̄_e = 1 ergeben `NA_real_`. Die ungleiche Zahl kommt mit der Meldung nach Nr. 14.
       - Kein Standardfehler, kein Test, kein Konfidenzbereich (Nr. 7.1). Die Druckausgabe zeigt nur den Punktschätzer. Eine spätere SE-Erweiterung folgt nur Gl. (12) von Fleiss, Nee & Landis (1979), mit eigener Prüfung (BL-44).
    3. Alpha:
       - Die Einheiten je Bereich entstehen aus den vorkommenden Zeilen vor dem Entfernen ungültiger Antworten; Berechnung und Zählung nutzen dieselben Gruppierungen.
       - Die Intervallmetrik rechnet auf den Positionen der Kategorien in der Skala (Formelsammlung §5: δ² = (c − d)² auf 1 … K).
       - Die Hilfe nennt `unweighted (nominal)`, `linear (ordinal)` und `quadratic (interval)`.
    4. Attributkennzahlen nach Nr. 3 und 4. Abschnitt 4 des Berichts und die Hilfe nennen die Modalregel. Sie sagen auch, dass die allgemeinen Kennzahlen fehlende Antworten verwerfen, während das AP1-Urteil (`acmg_modal()`) seine eigene Regel behält (BL-113). Entscheidungsregeln von AP1 ändern sich nicht.
    5. `msa_bias()`:
       - Signatur und Klasse bleiben. `overall`, `by_condition`, `level` und `n_items` behalten Namen und Bedeutung. Die Biasrechnung hängt nicht davon ab, ob die Gerade schätzbar ist.
       - `level` ist ein endlicher Skalar strikt zwischen 0 und 1, sonst ein benannter Fehler.
       - `NA`, numerisches `NaN`, die Zeichenkette "NaN" und nicht lesbare Antworten sind fehlend, wie bei `msa_fit()` (ADR-022 Nr. 3); eine fehlende Referenz ebenso. Gezählt werden sie nach Nr. 17.2.
       - ±Inf in Antwort oder Referenz ist ein benannter Fehler, wie bei `msa_fit()` (`R/fit.R:259`); ebenso ein Aufruf ohne jedes gültige Paar.
       - Ein gültiges Paar: `bias` ist bestimmt; `sd`, `lower`, `upper` und `p_value` sind `NA_real_`.
       - Nur ein Referenzwert: alle Einträge von `linearity` und `linearity_item_means` mit ihren Namen als `NA_real_`; `linearity_band` ist ein data.frame ohne Zeilen mit den numerischen Spalten `reference`, `fit`, `lower` und `upper`; `linearity_in_band` ist logisch `NA`, `linearity_verdict` `NA_character_`; `linearity_note` nennt den fehlenden Bereich der Referenzwerte.
       - Steigung und Achsenabschnitt bestimmt, aber keine Restfreiheitsgrade: Die Koeffizienten bleiben; Inferenz, Band und Verdikt sind unbestimmt (`NA`).
       - Zwei Items: Die Inferenz der Item-Mittelwert-Regression ist `NA`; das Verdikt der Handbuchrechnung bleibt bestimmt.
       - Nicht definierte Größen sind `NA`, nie `NaN`; das gilt auch für R² bei Gesamtstreuung null.
       - `print.msa_bias()` und Abschnitt 5 zeigen die Schätzungen, beide Freiheitsgrade, `linearity_note` und das Verdikt der Handbuchrechnung. Bei unbestimmter Linearität nennen sie den Grund und leiten kein Urteil aus dem Biastest ab. Objekte ohne die neuen Felder bleiben druck- und berichtsfähig.
    6. Bandprüfung: Mit z = x − x̄, Steigung b, mittlerer Abweichung d̄, Sxx = Σz² und Q = t_quantile · s liegt „Bias = 0“ genau dann im Band, wenn q(z) = (d̄ + bz)² − Q²(1/N + z²/Sxx) ≤ 0 auf dem ganzen Bereich gilt.
       - Geprüft wird das Maximum von q an beiden Enden und, wenn q konkav ist, am Scheitel im Inneren.
       - Ein Band, das die Null berührt, enthält sie. Keine zusätzliche Toleranz verschiebt die Grenze.
       - Die Regel ist gleichwertig zu `acc_m3a_in_band_ref()` (Kontext: 4000 von 4000).
    7. Item-Mittelwerte ungewichtet, jedes auswertbare Item einmal; Items mit gleichem Referenzwert bleiben getrennte Items. Keine Kennzahl „|b| · Prozessvariation“ (Formelsammlung §6).
    8. Vignette:
       - Helfer `inst/validation/agreement/bias_coverage.R`, geladen mit `sys.source(system.file("validation", "agreement", "bias_coverage.R", package = "llmsa", mustWork = TRUE), envir = …)` mit wörtlichen Argumenten (ADR-048 Nr. 14.5); seine Namen tragen nicht die Präfixe `sim_` und `boot_`.
       - ANK-06 und ANK-TOL kommen aus den bestehenden, hashgeprüften Ankerkopien unter `inst/validation/`; keine neue Ankerkopie, keine Ergebnisdatei.
       - Die Rechnung läuft beim Knit mit dem geladenen Namespace, sequentiell und ohne Netz; Seeds und RNG nach Nr. 12.3. Der Zufallszustand des Aufrufers wird auch im Fehlerfall wiederhergestellt. Jede Wiederholung zählt; eine gescheiterte Rechnung bricht benannt ab.
    9. Suggests `irr`, `psych` und `DescTools` (docs/01 §5; ACC-17). Keine neuen Imports, keine neuen Exporte, kein Builder-ADR zur API. Keine Änderung unter `inst/extdata/` und `reference/anchors/`.
17. **E1 bis E3: Mindestanforderungen und Form** (PLAN-REVIEW M3a r1, blocking; Form aus `PLAN-UPDATE.md` Runde 2, Abschnitt „Schnittstellen“, Z. 45–111, nachgetragen im Plan-Review der Runde 2). Jede Nummer nennt zuerst die Mindestanforderung der Runde 1, dann die Form. Die Form gilt; die Präzisierungen Nr. 17.2.2 und Nr. 17.3.6 gehen `PLAN-UPDATE.md` vor.
    1. (E1) Referenzauflösung, gemeinsam für `msa_agreement()` und `msa_bias()`.
       - Mindestanforderung: Ein nicht fehlender Referenzwert außerhalb der Skala (`levels`, übergeben oder abgeleitet) geht in keine stille Rechnung ein. Entweder gehen alle Paare mit gültiger Antwort und vorhandener Referenz in die Kreuztafel beider Kappa-Felder ein, oder der Aufruf endet mit einem benannten Fehler. Widersprüchliche Referenzwerte für dasselbe Item sind ein benannter Fehler.
       - Form:
         1. Eingabeformen wie v0.1.0: benannter Vektor, data.frame mit `item_id` und `reference`, Name einer Spalte von `runs`. Faktoren gelten mit ihren Beschriftungen. Kategorielle Referenzen werden als Kategorienamen verglichen, Referenzen von `msa_bias()` nach der Umwandlung in Zahlen („2“ und „2.0“ sind derselbe Wert).
         2. Mehrere gleiche, nicht fehlende Referenzen eines Items sind zulässig. Zwei verschiedene nicht fehlende Werte sind ein englischer Fehler, der die `item_id` und die Werte in fester Ordnung nennt, gleich in welcher Zeilenfolge und Eingabeform (Beispiel des Plans: `Conflicting reference values for item_id 'i1': 2, 5.`).
         3. Steht neben fehlenden Einträgen genau ein nicht fehlender Wert, ist er die Referenz des Items. Ohne lesbaren Wert oder ohne Zuordnung ist die Referenz des Items fehlend. Keine Antwort wird verändert, keine Referenz ergänzt.
         4. `msa_agreement()`: Die Skala ist `levels` oder, wie in v0.1.0, die aus den nicht fehlenden Antworten abgeleitete. Jede nicht fehlende Referenz eines Items aus `runs` muss in ihr liegen, auch wenn die Antworten des Items fehlen. Sonst endet der Aufruf vor jeder Rechnung mit einem englischen Fehler, der alle betroffenen Werte und `levels` nennt. Die Referenzkategorien werden nicht mit der Skala vereinigt; K, Gewichte und Skalenpositionen hängen nicht von der Referenz ab.
         5. Beide Kappa-Felder entfernen dieselben unvollständigen Paare vor Kreuztafel und Nenner; jedes verbleibende Paar liegt in genau einer Zelle, die relative Tafel summiert sich zu 1. Leere Tafel, Skala aus einer Kategorie und entarteter Nenner ergeben `NA_real_` mit dem Hinweis nach Nr. 14, nie `NaN`; für alle drei Gewichtungen.
         6. Alle neuen Eingabefehler sind englisch, mit `call. = FALSE`.
    2. (E2) Ausschlüsse in `msa_bias()`.
       - Mindestanforderung: `msa_bias()` zählt die Werte, die nicht eingehen, gesamt und je Prompt × Modell, in zusätzlichen Feldern. Eine Bedingung aus `runs` ohne gültiges Paar verschwindet nicht ungezählt. Druckausgabe und Abschnitt 5 nennen die Zahl.
       - Form:
         1. Antwort und zugeordnete Referenz werden als Zahlen gelesen. `NA`, `NaN` und nicht lesbare Werte sind fehlend (Nr. 16.5), ±Inf in Antwort oder Referenz ist ein benannter Fehler. Eine Zeile ist gültig, wenn beide Werte vorliegen und ihre Differenz endlich ist.
         2. Präzisierung des Reviewers (PLAN-REVIEW M3a r2, E9): Ist die Differenz zweier endlicher Werte nicht endlich (Überlauf), endet der Aufruf mit einem benannten englischen Fehler. `PLAN-UPDATE.md` Z. 72 nennt hier nur eine „klare Meldung“; die Zeile wäre dann weder gültig noch ausgeschlossen, und Nr. 17.2.3 gälte nicht.
         3. `n_excluded` zählt je Eingabezeile die Vereinigung von fehlender Antwort und fehlender Referenz; eine Zeile zählt einmal. Es gilt `n + n_excluded` = Zahl der Eingabezeilen, gesamt und je Bedingung.
         4. `overall` behält `n`, `bias`, `sd`, `lower`, `upper`, `p_value` in dieser Folge und erhält dahinter `n_excluded` (numerisch). `by_condition` behält seine Spalten und erhält dahinter die numerische Spalte `n_excluded`. Es hat eine Zeile je beobachteter Kombination Prompt × Modell der ungefilterten Eingabe, ohne kartesisches Auffüllen.
         5. Bedingung ohne gültiges Paar: `n` = 0, `n_excluded` gleich ihrer Zeilenzahl, `bias`, `sd`, `lower`, `upper` und `p_value` `NA_real_`. Ein gültiges Paar: Nr. 16.5. Kein gültiges Paar insgesamt: benannter Fehler mit Ursache und Ausschlusszahl. `n_items` zählt wie bisher die Items mit gültigem Paar.
         6. Druckausgabe und Abschnitt 5 zeigen gültige und ausgeschlossene Werte gesamt und je Bedingung. Bei Objekten ohne `n_excluded` steht „not recorded“; aus dem fehlenden Feld wird keine Null.
    3. (E3) Numerik von `msa_bias()`.
       - Mindestanforderung: Keine Fehlermeldung und keine Warnung von `stats::t.test`, `stats::lm` oder `summary.lm` erreicht den Aufrufer von `msa_bias()`. Abweichungen, die bis auf die Arbeitsgenauigkeit gleich sind, behandelt `msa_bias()` wie exakt gleiche: Punktintervall, t und p `NA` mit Hinweis. Die Grenze ist relativ, nicht exakt 0 (wie ADR-022 Nr. 7). Wo `stats::t.test` ein Ergebnis liefert, gleicht `msa_bias()` ihm (K-M3a-5). Dasselbe gilt für die Reststreuung beider Regressionen.
       - Form:
         1. `msa_bias()` ruft weder `stats::t.test` noch `stats::lm` noch `summary.lm`; alle Größen kommen aus eigener geschlossener Rechnung.
         2. Konstanz: Für n ≥ 2 gültige Abweichungen mit Mittel m, Standardabweichung s und SE = s/√n gilt „numerisch konstant“ genau dann, wenn SE = 0 oder SE < 10 · ε · |m| mit ε = `.Machine$double.eps` (die Grenze von `stats::t.test`; Kontext, Runde 2). Sonst sind t = m/SE, p = 2 · pt(−|t|, n − 1) und die Grenzen m ± q · SE mit dem t-Quantil q zu `level`, über die obere Seite der Verteilung gerechnet. Bei Konstanz sind `lower` und `upper` gleich m, p ist `NA_real_`, ein englischer Hinweis nennt die Auswertung (gesamt oder die Bedingung); `sd` bleibt der gerechnete Wert. Es gibt kein öffentliches t-Feld.
         3. `level` ist ein endlicher numerischer Skalar strikt zwischen 0 und 1, sonst ein benannter Fehler.
         4. Beide Regressionen rechnen mit zentrierten Summen, skaliert, wo Quadrate über- oder unterliefen: alle gültigen Einzelwerte mit N − 2 Freiheitsgraden und die ungewichteten Item-Mittelwerte mit g − 2. Koeffizienten, Reste, Standardfehler und R² entstehen ohne `lm`.
         5. Entarteter Zweig, für jede Regression getrennt: (a) Die Zielwerte (Abweichungen bzw. Item-Mittelwerte) haben TSS = 0 oder sind nach Nr. 17.3.2 numerisch konstant. (b) TSS > 0 und √RSS ≤ 10 · ε · √TSS (gleichwertig RSS ≤ (10 ε)² · TSS, ohne Unterlauf gerechnet). Ist die Gerade bestimmt und df > 0, bleiben die gerechneten Koeffizienten. t-Werte und p-Werte sind `NA_real_` mit Hinweis, das Band fällt auf die Gerade. „Bias = 0“ liegt genau dann im Band, wenn die Gerade auf dem ganzen geschlossenen Bereich null ist (q(z) ≤ 0 nach Nr. 16.6 mit Q = 0). Eine zusätzliche absolute Untergrenze der Streuung gibt es nicht.
         6. Präzisierung des Reviewers (PLAN-REVIEW M3a r2, E8): Im Fall (a) ist R² `NA_real_`, auch wenn TSS > 0 ist; der Hinweis nennt den Grund. Sonst ist R² = 1 − RSS/TSS, im Fall (b) also nahe 1. Grund: Bei exakt gleichen Zielwerten ist R² nicht definiert (Nr. 16.5: „das gilt auch für R² bei Gesamtstreuung null“). Bei bis auf die Rundung gleichen Zielwerten wäre 1 − RSS/TSS eine Zahl aus der Rundung (Kontext, Runde 2: 0,7506). `PLAN-UPDATE.md` Z. 99 setzt R² nur bei TSS = 0 auf `NA`.
         7. Die Rangfälle von Nr. 16.5 bleiben. Kein Ergebnis ist `NaN`, keine Meldung einer Engine erreicht den Aufrufer; Hinweise sind gezielt signalisierte R-Meldungen, die die betroffene Rechnung nennen.
         8. Unit-Raster über Itemzahlen, Replikate (auch ungleiche), Referenzbereiche, Verschiebungen und positive Skalierungen, Rauschstufen bis zur Arbeitsgenauigkeit, Werte beiderseits beider Grenzen und mehrere Seeds: kein Fehler, keine Warnung, kein `NaN`. Reguläre Fälle werden gegen `stats::t.test` und `stats::lm` geprüft, entartete gegen die algebraisch bekannten Werte.
18. **Mutationsumfang (Hinweis, keine neue Regel).**
    1. mutgate mutiert jede seit `plan/M3a` geänderte Datei im Scope ganz (`orchestrator/gates.d/86-mutgate.sh`; `MUT_SCOPE_REGEX='^R/.*\.R$'`, `config.env:228`). Mit `R/agreement.R` sind das auch `print.msa_agreement()`, `print.msa_bias()`, `resolve_reference()`, `krippendorff_alpha()` und `cohen_kappa()`. Verlangt sind 80 (`config.env:229`); eine Baseline gibt es nicht (BL-123).
    2. Die Mutatoren (`orchestrator/lib/r-mutation.R:59–67`) umfassen `string_literals` und `numeric_literals`, also auch die Formatzeichenketten der Druckmethoden. Heute prüft nur `test-m3a-2-fleiss-kappa.R:157–162` eine Druckausgabe von `msa_agreement()`, und nur Zeilen mit einem Fleiss-Standardfehler. In M3b lag eine Attrappe ohne Drucktests bei 63,2 % (ADR-051 Nr. 10).
    3. Die M3a-Abnahmetests mit dem gemeinsamen Knit von `validation.Rmd` laufen je Mutant (`MUT_TEST_DIRS` und `MUT_TEST_EXCLUDE`, `config.env:242` und `:267`). Die Rechnung der Vignettentabelle kostet nach dem Kontext einige Sekunden je Mutant.
    4. Der Score kommt aus Tests. Es kommen keine Ausschlüsse hinzu (AGENTS.md, Integrität Nr. 1 und 6). Ein Mutant verlässt den Nenner nur über `MUT-EQUIV.json` und Einzelfreigabe des Reviewers (SCHEMA.md).
19. **Formen aus `PLAN-UPDATE.md` zu E4, E5 und E7 (Runde 1) und zu E10 (Runde 2).** Bestätigt im Plan-Review der Runde 2; minor, aber Teil des Umsetzungsvertrags.
    1. (E4) `fleiss` ist `list(kappa = <numerischer Skalar ohne Namen>)` ohne weiteres Element. Die Fleiss-Zeile der Druckausgabe zeigt nur den Punktschätzer und nennt keinen Standardfehler; warum keiner ausgegeben wird, steht nur in der Hilfe. `linearity_in_band` ist ein logischer Skalar ohne Namen und Attribute, `linearity_verdict` eine Zeichenkette ohne Namen; im unbestimmten Fall `NA` bzw. `NA_character_`.
    2. (E5) Der Abschnitt `## Bias interval: coverage by scenario` steht hinter dem vollständigen Abschnitt „Bootstrap intervals: coverage by scenario“ auf derselben Ebene. Der neue Rmd-Teil enthält keine Zahlenliterale. Die Tabelle zeigt scenario, coverage, MCSE, n_sim und den vorzeichenbehafteten Abstand (coverage − level)/MCSE; bei MCSE 0 ist ein Abstand ungleich 0 ±Inf, nie `NaN`. Ein Überschreiten von ANK-TOL.mc_factor (report) wird als Unter- oder Überdeckung benannt und bricht den Knit nicht ab; Rechenfehler und nicht endliche Grenzen brechen mit Szenario und Wiederholung benannt ab. Der Helfer trägt das Präfix `agreement_` und rechnet mit dem geladenen Namespace.
    3. (E10) In der Tabelle beginnt genau je eine Spaltenüberschrift mit scenario, coverage, MCSE und n_sim (ohne Rücksicht auf Groß- und Kleinschreibung; `acc_m1a_column()`, `tests/acceptance/setup-m1a.R:519–523`). Die Abstandsspalte und jede weitere Spalte beginnen mit keinem dieser Wörter. n_sim steht als ganze Zahl ohne Exponent.
    4. (E7) Unit-Tests unter `tests/testthat/`, die irr, psych oder DescTools rufen, beginnen mit `skip_if_not_installed()`. Hilfe, Bericht, Vignette und Helfer brauchen diese Pakete nicht.

## Konsequenzen

- `PLAN.md` Runde 1 war nicht freigegeben (PLAN-REVIEW M3a, Runde 1: REWORK wegen E1 bis E3). `PLAN-UPDATE.md` beantwortet E1 bis E7 Punkt für Punkt.
- `PLAN.md` mit `PLAN-UPDATE.md` ist freigegeben (PLAN-REVIEW M3a, Runde 2: PASS). Wo beide von Nr. 17 oder Nr. 19 abweichen, gilt dieses ADR (Nr. 17.2.2, Nr. 17.3.6).
- Nr. 1 bis 16 gelten unverändert. Nr. 17 trägt die Form aus `PLAN-UPDATE.md` nach; Nr. 19 kommt hinzu.
- Die minor-Befunde E4 bis E7 (Runde 1) und E8 bis E11 (Runde 2) in `orchestrator/handoff/M3a/PLAN-REVIEW.md` sind Umsetzungshinweise und keine neuen Kriterien. Verbindlich sind ihre Formen in Nr. 17 und Nr. 19.
- Das Code-Review M3a prüft gegen Nr. 1 bis 17 und Nr. 19.
- Die Messwerte im Kontext sind Proben des Reviewers auf v0.1.0. Sie sind weder Ergebnisse des Builders noch Referenzwerte für Tests.
- Rücknahme: Ändert der Betreiber docs/04 M3a, docs/01 §2, §4 oder §5 oder die Formelsammlung §5 oder §6, ersetzt ein neues ADR die betroffenen Nummern.
