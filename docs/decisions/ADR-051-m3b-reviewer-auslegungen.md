# ADR-051 — Auslegungen des Reviewers zu M3b: Prüfformen K-M3b-1 bis K-M3b-6, Anker ANK-80 bis ANK-82, Festlegungen des Plans, Mutationsumfang

## Status

Angenommen (Reviewer, `30-plan-review` M3b, Runde 1, 04.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 7 halten die Auslegungen fest, die `orchestrator/handoff/M3b/CRITERIA.json` unter `open` als ACC-3, ACC-4, ACC-6, ACC-8, ACC-9, ACC-15 und ACC-11 führt, in der Fassung nach der Wiederholung der Acceptance (ADR-050 Nr. 6).
  - ACC-1 kündigt dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh:518`, `path_allowed`).
  - `PLAN.md` (Runde 1) übernimmt diese Auslegungen (Abschnitt „Ziel“, Z. 41–46).
- Nr. 8 hält die Anker und geschützten Daten fest, die die Abnahmephase angelegt oder abgeglichen hat (ACC-1, ACC-2).
- Nr. 9 bestätigt Festlegungen aus `PLAN.md`, die diese Auslegungen ausfüllen.
- Nr. 10 ist ein Hinweis zum Mutationsumfang, keine neue Regel.
- ACC-5, ACC-7 und ACC-10 sind in ADR-050 entschieden; dieses ADR ändert daran nichts.
- Die Nummern ändern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen. Einzelheiten stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M3b-1: geprüftes Objekt, Verschiebungsrichtung, Zeilen- oder Spaltenform;
  - K-M3b-2: Aufruf des Orakels über `nruns` und `boxtyssedal` hinaus, Prüfverfahren;
  - K-M3b-3: Datenform der Beispiele, Toleranzen außerhalb der Orakel, Prüffälle;
  - K-M3b-4: Achse, Prüfweg, Wortlaut der Konvention;
  - K-M3b-5: MCSE-Form, Seed, Datenerzeugung; Ort, Wortlaut und Prüfweg der Hilfeseite;
  - K-M3b-6: Spaltennamen, Fehlermeldung, unbekanntes `transform`, mehr als 23 Faktoren, Werte außerhalb von [0, 1].
- **Gemessen in dieser Phase** (PLAN-REVIEW M3b, Runde 1, Prüfläufe 1 bis 3; R 4.6.1, testthat 3.3.2, roxygen2 8.1.1, muttest 0.3.0, FrF2 2.3.5, DoE.base 1.2.5, unrepx 1.0.2; Paketkopien unter `/tmp`, Arbeitsbaum unverändert):
  - Ausgangsstand (Kopie ohne Änderung): M3b-Abnahme 27 Blöcke, 12 rote Erwartungen, 2 Fehlerblöcke, 414 grüne Erwartungen; rot sind nur K-M3b-4 (Benennung der Konvention), K-M3b-5 (drei Hilfeseitentests) und K-M3b-6 (vier Tests zu `transform`). Die Klasse-A-Studie `test-lenth-h0.R` ist grün. Das gleicht `PLAN.md` (Testplan) und ACC-13.
  - Attrappe nach `PLAN.md` (Schnittstellen Nr. 1 bis 6, Hilfetext aus roxygen erzeugt): alle 27 Blöcke grün (437 Erwartungen), die Klasse-A-Studie grün, `test-robustness-plan-spc.R`, `test-report.R` und `test-acmg-robustness-errors.R` grün. Der Standardpfad gleicht dem unveränderten `msa_robustness()` mit `identical()` auf sechs Aufrufen, auch mit `transform = "none"`; der Logit-Pfad gleicht dem unveränderten Pfad auf `qlogis(p)`.
  - Mutanten der Attrappe mit den Mutatoren aus `orchestrator/lib/r-mutation.R`: 314. Gegen alle nicht ausgeschlossenen Testdateien, die den Code erreichen, sind 194 entdeckt, 113 überlebt und 7 nicht ladbar: 63,2 % (Nr. 10).

## Entscheidung

1. **(ACC-3) Prüfform K-M3b-1.**
   1. Geprüft wird das dokumentierte Attribut `coded` von `pb_design(N − 1, n_runs = N, randomize = FALSE)` als N × (N − 1)-Matrix aus ±1.
   2. Zulässig sind die drei Formen der Quelle:
      - Generatorzeile aus ANK-80 als erste Zeile, jede weitere Zeile die vorige um eine Stelle zyklisch nach rechts verschoben (Code vor M3b) oder nach links;
      - Generatorfolge als erste Spalte, jede weitere Spalte die vorige um eine Stelle nach unten verschoben (gedrucktes Beispiel S. 319);
      - jeweils dazu die letzte Zeile aus −1.
      Verlangt ist eintragsweise Gleichheit mit einer dieser Formen (Mini-Referenz `acc_m3b_pb_reference()` in `setup-m3b.R`).
   3. `cbind(1, X)`: `crossprod()` ist exakt N · I; `colSums(X)` ist 0.
   4. Die kodierten Spalten des zurückgegebenen data.frame gleichen `coded`.
2. **(ACC-4) Prüfform K-M3b-2.**
   1. Orakel `FrF2::pb(nruns = N, boxtyssedal = FALSE, randomize = FALSE)` zur Testlaufzeit, Matrix aus `attr(, "desnum")`. `boxtyssedal = FALSE` steht seit ADR-050 Nr. 1 im Kriterium und gilt für alle fünf Größen. `randomize = FALSE` legt nur die Zeilenfolge fest, die das Kriterium freigibt. Alle anderen Argumente bleiben auf ihrer Vorgabe; Warnungen und gedruckte Hinweise zur Vermengung werden unterdrückt.
   2. Gleich heißt: Es gibt eine Zeilenpermutation σ, eine Spaltenpermutation π und Spaltenvorzeichen s mit A[i, j] = s_j · B[σ(i), π(j)] für alle Einträge. Der Test sucht die Abbildung und prüft sie eintragsweise.
   3. Vor der Suche vergleicht er die Multimengen der |J3|-Werte und nennt sie im Fehlerfall.
   4. Positiv- und Negativkontrolle des Suchverfahrens in derselben Datei. Die Mini-Referenz für N = 16 wird auf `FrF2::pb(nruns = 16, boxtyssedal = FALSE)` abgebildet; der Box-Tyssedal-Plan der Vorgabe `boxtyssedal = TRUE` hat eine andere |J3|-Multimenge.
3. **(ACC-6) Prüfform K-M3b-3.**
   1. Haupteffekte: `effect` je Faktor gleich der Differenz der Stufenmittel und gleich `2 · coef(lm(y ~ Spalten))` auf `pb_design(11)` und `pb_design(8)` in 12 Läufen und auf beiden Beispielen; Toleranz ANK-TOL.arithmetic.
   2. Beispiele II und IV:
      - Design als data.frame mit allen 15 Kontrastspalten, Namen wie Spalte `contrast` der Tab. 3; `factors` sind diese Spalten, `alpha` ist ANK-81 `method.nominal_alpha`;
      - Effekte gegen Tab. 3; `response_mean`, `pse`, `me` und `sme` gegen den Druck mit halber Einheit der letzten gedruckten Stelle zuzüglich ANK-TOL.arithmetic (ANK-81 `tolerance`);
      - `pse`, `me` und `sme` zusätzlich gegen die Mini-Referenz von Gl. (1)–(5) mit ANK-TOL.arithmetic.
   3. Tab. 1: ME/PSE und SME/PSE für m = 7, 15, 31, 63, 127, 255 (volle 2^k-Kontrastmatrizen, Zufallsantwort) auf eine halbe Einheit der zweiten Stelle.
   4. Gl. (2) streng: ein Fall mit einem Kontrast genau auf 2,5 · s0 (Effekte 1, 1, 2, 2, 7,5, 30, 40 in exakter Binärarithmetik; PSE 2,25, mit ≤ wäre sie 3). Erwartet ist die Mini-Referenz auf den gemeldeten Effekten.
   5. `active` ist |Ê| > ME, `active_simultaneous` ist |Ê| > SME: die Mengen der Beispiele (II: WCR und TWCR; IV: keine), ein konstruierter Fall zwischen ME und SME und die Übereinstimmung mit der Mini-Referenz auf drei Zufallsplänen.
   6. PSE gegen `unrepx::PSE(effects, method = "Lenth")` mit ANK-TOL.frf2_unrepx.pse_me_tol auf beiden Beispielen und drei Zufallsplänen. Nicht im Grenzfall aus Nr. 3.4, weil unrepx über |c| ≤ 2,5 · s0 trimmt.
   7. PSE, ME und SME gegen `DoE.base::ME.Lenth(effects, simulated = FALSE, alpha = alpha)` mit ANK-TOL.frf2_unrepx.pse_me_tol, auch für SME (ADR-050 Nr. 2):
      - auf beiden Beispielen, `pb_design(11)` und `pb_design(8)` in 12 Läufen mit den Seeds 1 bis 3, den vollen Kontrastmatrizen mit m = 7, 15, 31, 63 (Seeds 203 bis 206) und dem Grenzfall;
      - das Orakel erhält die aus den Daten nachgerechneten Effekte, im Grenzfall die gemeldeten;
      - zusätzlich gleicht das Orakel der Mini-Referenz (ANK-TOL.arithmetic), im Grenzfall exakt deren PSE.
      `unrepx::ME` ist kein Orakel (ADR-050 Nr. 2).
4. **(ACC-8) Prüfform K-M3b-4.**
   1. `plot()` eines `msa_robustness`-Objekts wird auf einem `pdf(NULL)`-Gerät mit `recordPlot()` aufgezeichnet und aus der Display-Liste gelesen: Punktmengen (`C_plotXY` mit Typ p, b oder o und m Punkten), Achsentitel (`C_title`), Randtexte (`C_mtext`) und Texte (`C_text`, darin Legendeneinträge). Die Grafik bleibt Basisgrafik.
   2. Jede Punktmenge mit m Punkten trägt auf der x-Achse q_(i) = qnorm(1/2 + (i − 1/2)/(2m)) und auf der y-Achse die aufsteigend geordneten |Ê|_(i) (ANK-TOL.arithmetic); geprüft für m = 11 (`pb_design`), 31, 26 und 7.
   3. Beispiel der Quelle aus den gezeichneten Positionen mit P′ = 2Φ(q) − 1: Bei m = 31 ist P′ des 22. Punkts 0,693 (Toleranz 0,001 nach ANK-82, Druck abgeschnitten), der 22. Punkt liegt am nächsten an 0,683, der oberste bei 0,984; bei m = 26 liegt der oberste bei 0,981 (je halbe Einheit).
   4. „Konvention genannt“ heißt: Ein Achsentitel, Randtext oder Legendeneintrag enthält „Daniel“ und „1959“ im selben Text. Der Haupttitel zählt nicht.
5. **(ACC-9) Prüfform K-M3b-5, Simulation.**
   1. Klasse A, `tests/simulation/test-lenth-h0.R` mit den Hilfen aus `tests/simulation/setup-simulation.R`. Je Szenario `pb_design(k, n_runs = 12, randomize = FALSE)` mit k = 8 und 11; `n_sim` = ANK-06 `n_sim_min`; y ~ N(0, 1) unabhängig je Lauf; Seed 20261104 + k; RNG Mersenne-Twister/Inversion/Rejection; `msa_robustness(alpha = ANK-81 method.nominal_alpha)`.
   2. Kennzahl je Effekt: Mittel der Anteile aktiver Effekte je Plan, MCSE = sd/√n_sim (Formel MCSE(Bias), Formelsammlung §9; die Effekte eines Plans teilen dieselbe PSE). Kennzahl je Plan: Anteil der Pläne mit mindestens einem |Ê| > SME, MCSE = √(p(1 − p)/n_sim) (Formel MCSE(Coverage)).
   3. Bestehen: je Kennzahl ≤ α + ANK-TOL.mc_factor.pass · MCSE der gemessenen Kennzahl (ADR-050 Nr. 3). Zusätzlich gleichen in jedem der `n_sim` Pläne alle Entscheidungen `active` und `active_simultaneous` der Mini-Referenz von Lenth Gl. (1)–(5) auf denselben Daten.
   4. Eine Meldung nennt je Szenario beide Raten mit MCSE und dem Abstand zu α, absolut und in MCSE, dazu Seed, RNG, R- und Paketversion und Dauer.
6. **(ACC-15) Prüfform K-M3b-5, Hilfeseite.**
   1. Geprüft wird `man/msa_robustness.Rd` im Wurzelverzeichnis des Repos als Klartext (`tools::Rd2txt` über `acc_m1b_rd_text()`), geteilt in Sätze an . ; ! ? mit folgendem Leerraum. Die Dokumentation ist englisch.
   2. „Konservativ“: Ein Satz enthält „conservativ“ ohne Rücksicht auf Groß- und Kleinschreibung, nicht unmittelbar nach „not “, „non-“, „non“, „anti-“, „anti“ oder „un“.
   3. „α einen Nominalwert“: Ein Satz nennt alpha („alpha“, „α“ oder „significance level“) und enthält „nominal“.
   4. Der Satz „at the 5 % level per effect“ steht nicht mehr auf der Hilfeseite, auch nicht mit anderem Leerraum um das Prozentzeichen oder anderer Groß- und Kleinschreibung (ADR-050 Nr. 3).
   5. Die Prüfung steht in `tests/acceptance/test-m3b-5-help-page.R`, nicht in der Klasse-A-Datei, weil sie keine Simulation ist.
7. **(ACC-11) Prüfform K-M3b-6.**
   1. Plangröße: Für k = 1 bis 23 Faktoren (als Zahl) und für benannte Listen mit 7, 8, 11, 12, 15, 16, 19, 20 und 23 Faktoren hat `pb_design()` ohne `n_runs` genau N Zeilen, N die kleinste Größe aus ANK-80 mit N − 1 ≥ k. 24 Faktoren ergeben einen Fehler. Die kodierten Spalten bei weniger Faktoren sind Spalten der Matrix aus K-M3b-1 derselben Größe.
   2. Reproduzierbar: Gleicher `seed` ergibt identische Objekte unabhängig vom globalen Zufallszustand; die Zeilen sind eine Permutation der unrandomisierten; über die Seeds 1 bis 10 entstehen mehrere Reihenfolgen.
   3. Stufen: Die Spalte `<faktor>_level` trägt bei +1 den zweiten und bei −1 den ersten übergebenen Wert (`as.character`); die kodierten Spalten heißen wie die Listennamen.
   4. `transform` ist ein Formalargument hinter den vier Argumenten des Snapshots (ANK-02), `eval(Vorgabe)[1]` ist `"none"`, und ein Aufruf ohne `transform` gleicht `transform = "none"`.
   5. Mit `"logit"` gleichen Effekte, `pse`, `me` und `sme` der Mini-Referenz auf log(p/(1 − p)) (ANK-TOL.arithmetic).
   6. Ein Anteil von genau 0 oder 1 ergibt mit `"logit"` einen Fehler, dessen Meldung 0 und 1 als eigene Zahlen nennt: Weder vor noch hinter der Ziffer steht ein Punkt oder eine Ziffer. Mit `"none"` gibt es keinen Fehler.
   7. Ein anderer Wert von `transform` ist ein Fehler. Ein Seed-Attribut verlangt M3b nicht; die Seeds nennt der Bericht nach K-M3d-6.
8. **(ACC-1, ACC-2) Anker und geschützte Daten.**
   1. Neu in `10-acceptance` M3b, vor dem Tag `plan/M3b`:
      - ANK-80 (Plackett & Burman 1946: Generatorzeilen N = 8 bis 24, Konstruktion; Zweitquelle NIST 5.3.3.5);
      - ANK-81 (Lenth 1989: Gl. (1)–(5), Tab. 1, Beispiele II und IV, Nominalniveau; Tab. 2 und 3 als lokale CSV mit SHA-256, Spalten und Zeilenzahl);
      - ANK-82 (Daniel 1959: Plotting-Positionen, Beispiel 22. von 31 Kontrasten).
   2. Unverändert genutzt: ANK-02, ANK-06 und ANK-TOL (`arithmetic`, `frf2_unrepx`, `mc_factor`).
   3. Geschützte Daten: `reference/quellen/data/lenth/example_II.csv`, `example_IV.csv`, `table3_contrasts.csv` und `QUELLE.txt` (Betreiber, 04.11.2026, git-ignoriert; SHA-256 in ANK-81 und ACC-2), vom Reviewer am Seitenbild abgeglichen. Fehlt eine Datei oder weicht ihr SHA-256 ab, schlägt der Test fehl; er überspringt nicht.
   4. `tolerance_note` und `observations.unrepx` von ANK-81 beschreiben den Stand vor ADR-050 („Gegenrechnung mit unrepx … (PSE, ME 1e-8)“). Es gilt ADR-050 Nr. 2: `unrepx::PSE` für die PSE, `DoE.base::ME.Lenth(simulated = FALSE)` für PSE, ME und SME, beide mit `ANK-TOL.frf2_unrepx.pse_me_tol`. Kein Ankerwert ändert sich.
   5. Die Literaturwerte sind am Original geprüft; geschützte Quellen stehen nur mit Kurzzitaten in den Ankern. Dieses ADR ist das ADR im selben Meilenstein für diese Ankeränderungen (docs/01 §6). Unter `inst/extdata/` ändert sich in M3b nichts.
9. **Bestätigte Festlegungen aus `PLAN.md`** (Runde 1, Abschnitt „Schnittstellen“).
   1. Signatur `msa_robustness(design, response, factors = NULL, alpha = 0.05, transform = "none")`. Die Vorgabe ist das Literal `"none"`. Zulässig sind genau `"none"` und `"logit"`, ohne partielles Matching. Jeder andere Wert ist ein benannter Fehler, auch `NA`, `""`, eine Länge ungleich 1 und ein Wert, der keine Zeichenkette ist. ANK-02 bleibt unverändert (docs/01 §4: neues Argument mit Vorgabewert am Ende ohne ADR; BL-57).
   2. Logit-Pfad:
      - Die Prüfung läuft vor der Transformation und vor der Effektberechnung und verlangt reelle, endliche Werte mit 0 < p < 1.
      - Genau 0 oder 1, Werte außerhalb von (0, 1), unendliche Werte und Antworten, die keine Zahlen sind, ergeben die Meldung aus `PLAN.md` (Schnittstellen Nr. 2) oder eine gleichwertige nach Nr. 7.6. `NA` und `NaN` ergeben die bestehende NA-Meldung.
      - Keine Randkorrektur, keine Ersetzung einer ungültigen Antwort.
      - Danach geht `stats::qlogis(response)` genau einmal in den bisherigen Rechenweg.
   3. Ergebnis:
      - Im Standardpfad gleicht das Objekt dem bisherigen mit `identical()`, ohne neues Attribut (K-M1d-8, ANK-34).
      - Der Logit-Pfad hat dasselbe Schema. Effekte, PSE, ME, SME, `response_mean` und `response_sd` stehen dann auf der Logit-Skala; die Hilfeseite sagt das.
   4. `acmg_robustness()` bildet den empirischen Logit mit Korrektur selbst und ruft `msa_robustness()` weiter mit der Vorgabe `"none"` (`R/acmg.R:1065–1067`). Es gibt keine doppelte Transformation; Effekte, ME, SME und Bänder von AP1 bleiben.
   5. PB-Konstruktion, Lenth-Rechnung (Konstanten aus ANK-81, strikte Trimmung, d = m/3 ungerundet, Šidák-γ, strikte Entscheidungen), Sortierung und Druckausgabe bleiben (ADR-050 Nr. 4 und Konsequenzen). m ist die Zahl der ausgewählten Faktorspalten (BL-125).
   6. Plot: x-Achsentitel „Half-normal quantile (Daniel, 1959)“; Positionen und y-Werte unverändert.
   7. Hilfeseite:
      - Sie nennt das Verfahren „conservative“ und beschreibt `alpha` als „Nominal significance level for ME and SME“.
      - Der Satz „at the 5 % level per effect“ entfällt.
      - `man/msa_robustness.Rd` wird aus roxygen erzeugt (roxygen2 8.1.1 wie `RoxygenNote`); übernommen wird nur diese Seite.
   8. Suggests: `FrF2`, `DoE.base` und `unrepx` (ACC-12; docs/01 §5; ADR-050, Konsequenzen). Unit-Tests mit diesen Paketen überspringen mit `skip_if_not_installed()`, Abnahmetests nicht.
   9. Kein Builder-ADR. Keine Änderung unter `inst/extdata/` und `reference/anchors/`.
10. **Mutationsumfang (Hinweis, keine neue Regel).**
    1. mutgate mutiert jede seit `plan/M3b` geänderte Datei im Scope ganz (`orchestrator/gates.d/86-mutgate.sh:22`, `MUT_SCOPE_REGEX='^R/.*\.R$'` in `config.env:228`). Mit `R/robustness.R` sind das auch `pb_design()`, `pb_matrix()`, `print.pb_design()`, `print.msa_robustness()` und `plot.msa_robustness()`. Verlangt sind 80 (`MUT_SCORE_MIN`, `config.env:229`); eine Baseline gibt es nicht (BL-123).
    2. `MUT_TEST_EXCLUDE` (`config.env:267`) nimmt alle Tests mit Namen `m1d-…` aus (ADR-047 Nr. 4). Damit fehlen im Mutationslauf K-M1d-8 und die M1d-QA-Tests, die als einzige die Druckausgabe von `print.msa_robustness()` prüfen.
    3. Probe des Reviewers auf der Attrappe aus dem Kontext: In `print.msa_robustness()` (27 Mutanten) und `print.pb_design()` (8) wird kein Mutant entdeckt, in `plot.msa_robustness()` 11 von 25. Die Überlebenden je Funktion und Zeile stehen in PLAN-REVIEW M3b r1, E1.
    4. Der Score kommt aus Tests. Bestehender Code in `R/robustness.R` wird dafür nicht umgebaut oder entfernt (ADR-050, Konsequenzen: „`R/robustness.R` ändert nur den Hilfetext aus Nr. 3 zusätzlich zu dem, was K-M3b-4 und K-M3b-6 verlangen“), es kommen keine Ausschlüsse hinzu (AGENTS.md, Integrität Nr. 1 und 6). Ein Mutant verlässt den Nenner nur über `MUT-EQUIV.json` und Einzelfreigabe des Reviewers (SCHEMA.md).

## Konsequenzen

- `PLAN.md` Runde 1 ist mit diesen Festlegungen freigegeben (PLAN-REVIEW M3b, Runde 1: PASS).
- Die minor-Befunde E1 bis E3 in `orchestrator/handoff/M3b/PLAN-REVIEW.md` sind Umsetzungshinweise und keine neuen Kriterien. Über das Bestehen von Nr. 10 entscheidet allein das Gate mutgate.
- Das Code-Review M3b prüft gegen Nr. 1 bis 9 und ADR-050.
- Die Messwerte im Kontext sind Proben des Reviewers auf einer Attrappe; sie sind weder Ergebnisse des Builders noch Referenzwerte für Tests.
