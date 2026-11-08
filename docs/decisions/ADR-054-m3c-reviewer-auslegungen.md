# ADR-054 — Auslegungen des Reviewers zu M3c: Prüfformen K-M3c-1 bis K-M3c-6 (ACC-2 bis ACC-12), Anker ANK-86, ANK-87 und ANK-89, Festlegungen zum Plan

## Status

Angenommen (Reviewer, `30-plan-review` M3c, Runde 1, 08.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 7 halten die Auslegungen fest, die `orchestrator/handoff/M3c/CRITERIA.json` unter `open` als ACC-2 bis ACC-8 führt. ACC-1 kündigt dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh:518`, `path_allowed`).
- Nr. 8 hält die Anker fest (ACC-1). Nr. 9 hält den offenen Punkt ACC-9 fest. Nr. 10 hält die Hinweise ACC-10 und ACC-12 fest.
- Nr. 11 bis 18 präzisieren den Plan; die Befunde in `orchestrator/handoff/M3c/PLAN-REVIEW.md` (Runde 1) verweisen hierher: E1 auf Nr. 11, E2 auf Nr. 12, E3 auf Nr. 13, E4 auf Nr. 14, E5 auf Nr. 15, E7 auf Nr. 16, E8 auf Nr. 17, E9 auf Nr. 18. E6 ist ein Hinweis zum Gate mutgate (Nr. 19.1). Die Festlegungen binden, weil `PLAN.md` an diesen Stellen schweigt oder eine Festlegung nötig ist; wo `PLAN.md` und dieses ADR abweichen, gilt das ADR.
- Nr. 19 enthält Hinweise, keine neuen Regeln.
- Kein Abnahmetest ändert sich durch dieses ADR. Einzelheiten der Prüfreihen stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M3c-1: was „genau an der Grenze“ heißt, zu den Prüfreihen und zur Rechengenauigkeit der Standardisierung;
  - K-M3c-2: zur Paarbildung, zum Fehlerfall, zur Objektgleichheit und dazu, was als Nennen der Lesart gilt;
  - K-M3c-3: zu Reihenlänge, Wiederholungszahl über dem Minimum, Vorlauf, Abbruchregel und Toleranzform;
  - K-M3c-4: zum Ort, an dem die Grenzen der Karte abzulesen sind;
  - K-M3c-5: zu Seeds, Namen der Komponenten und zur Prüfung von „entspricht der Itemwahrheit“;
  - K-M3c-6: zu Spaltennamen, Form von `replicates`, Quantildefinition, Kandidatenplänen, Grenzschätzung, CV-Definition, Tabellenform und zum Weg der Zahlen in die Vignette.
- **MCSE:** Formelsammlung §9 nennt MCSE-Formeln für Bias, EmpSE, Coverage und MSE, keine für einen Variationskoeffizienten oder für 1/ARL; docs/01 §2 Nr. 3 verlangt einen MCSE für jede berichtete Kennzahl (ACC-9).
- **Gemessen in dieser Phase** (PLAN-REVIEW M3c r1; R 4.6.1; Paketkopien unter `/tmp`, Skripte unter `orchestrator/handoff/M3c/.probe-plan-review/`, danach gelöscht; im Arbeitsbaum keine Produktänderung):
  - `msa_fit()` hat bei einem Plan mit einer Prompt-Variante keine Zeile `prompt` in `$vc` (Plan 10/1/2/2/1; Quellen `item:model`, `item`, `model`, `Residual`). Bei zwei Prompt-Varianten ist `prompt` eine REML-Komponente (Plan 8/2/2/2/2).
  - In 300 Wiederholungen von S-plan-1 waren 13 Prompt-Schätzungen genau 0, die kleinste positive 7,87e-05; jede genau-0-Schätzung war singulär, 75 singuläre hatten eine positive Prompt-Schätzung.
  - Die Attrappe der Planschnittstellen bestand K-M3c-1, -2, -4, -5 und den Plan-Teil von K-M3c-6, K-M3d-4 bis -6, QA-M3d und die Bericht- und Plan-Unit-Tests.

## Entscheidung

1. **(ACC-2) Prüfform K-M3c-1.**
   1. Die Bedingungen sind strikt. „Genau an der Grenze auslösen“ heißt: Eine Regel schlägt bei Grenze + ε an und weder genau auf der Grenze noch bei Grenze − ε; ε = 2^-30, damit Summen mit den Grenzen in Gleitkomma exakt bleiben.
   2. Geprüft werden die konstruierten Reihen aus `acc_m3c_boundary_cases()`, die Mini-Referenz `acc_m3c_reference()` und 1500 Zufallsreihen (Seed 31081). Fenster lösen vor Erreichen ihrer vollständigen Länge nicht aus; `1_2s` ist nur Warnung; `reject` ist die Vereinigung der Ablehnungsregeln.
   3. Standardisierung: Mit übergebenem `center`/`sd` tragen die Attribute diese Werte und z = (x − center)/sd bis ANK-TOL.arithmetic; ohne sie gelten Mittelwert und `stats::sd()` (n − 1) der ersten `n_baseline` Werte; übergebene Werte haben Vorrang.
   4. Fehlende Kontrollwerte sind nicht Teil des Vertrags (Verhalten wie v0.1.0).
2. **(ACC-3) Prüfform K-M3c-2.**
   1. `r4s = c("range", "westgard")` steht hinter den Argumenten von v0.1.0 (ANK-02); ohne `r4s` ist das Ergebnis `identical()` mit `r4s = "range"`; ein unbekannter Wert ist ein Fehler.
   2. Westgard-Lesart: an jeder Position t ≥ 2 das Paar (z_(t−1), z_t); R_4s schlägt an, wenn ein Wert > 2 und der andere < −2 ist (strikt, beide Reihenfolgen). Die übrigen Regelspalten sind unter beiden Lesarten gleich; `reject` enthält R_4s der gewählten Lesart.
   3. `print()`: eine Zeile nennt R_4s und unter der Vorgabe das Wort range, unter `r4s = "westgard"` das Wort westgard, mit und ohne Verletzungen; die Mengen dieser Zeilen unterscheiden sich.
   4. `msa_report(control_chart =)`: Abschnitt wie M3d ACC-11; bei der Vorgabe nennt eine Zeile R_4s, range und consecutive oder successive, bei der Westgard-Lesart eine Zeile R_4s und westgard; die Verletzungstabelle zeigt die Positionen der gewählten Lesart.
3. **(ACC-4) Prüfform K-M3c-3.**
   1. Teil 1: je Lesart 100 × ANK-06 Reihen aus 12 unabhängigen N(0, 1)-Werten, Regeln und Positionen 1 bis 12, bestanden bei |Anteil − Formelwert aus ANK-86| ≤ ANK-TOL.mc_factor (pass) · MCSE; vor dem vollständigen Fenster genau 0.
   2. Teil 2: fortlaufender Fall nach Parvin (1992, S. 359) mit 10 Vorlaufwerten und den Regeln 1_3s, 2_2s, 4_1s, 10_x, 20 × ANK-06 Versuche je Bedingung SE 0, 1, 2; bestanden bei |1/ARL − p̄_cr| ≤ 0,016 (Toleranz von ANK-87); der eigene Monte-Carlo-Fehler wird nicht addiert.
4. **(ACC-5) Prüfform K-M3c-4.** Die Grenzen der Karte sind die waagerechten Linien, die `plot()` zeichnet. `qcc::qcc(type = "xbar.one")` wird je k = 1, 2, 3 zur Testlaufzeit aufgerufen; beide Grenzen und die Mittellinie liegen unter den gezeichneten Linien (relativ 1e-8, ANK-TOL.oracle.closed_form_rel_tol). qcc kommt in Suggests (Builder, docs/01 §5).
5. **(ACC-6) Prüfform K-M3c-5.** S-sim-1 mit den Komponenten von S-boot-1, `msa_simulate(…, seed = 20261108 + s)`, `msa_fit(type = "numeric")`, n_sim = ANK-06; bestanden bei |Mittel − Vorgabe| ≤ 4 MCSE. Itemwahrheit: `latent` ist je Item konstant und hat die Item-Varianz; deterministisch in `test-m3c-5-simulator-latent.R`.
6. **(ACC-7) Prüfform K-M3c-6, Kennzahlen.**
   1. Neue Spalten `bias`, `empse`, `mcse_bias`, `mcse_empse`; die Spalten von v0.1.0 bleiben. `attr(plan, "replicates")` ist ein data.frame mit mindestens `scenario` (Zeilennummer in `scenarios`), `sim`, `estimate` (geschätzter %GRR in % Studienvariation), `singular` (logisch, ohne NA) und `prompt` (REML-Schätzung der Prompt-Komponente aus `msa_fit()$vc`, ≥ 0; zur Grenze keiner Schätzung siehe Nr. 11).
   2. Nachrechnung je Plan nach Formelsammlung §9 mit θ = `grr_true`, Quantile nach Definition 7, Verdikt nach ANK-16; Toleranz ANK-TOL.arithmetic; `grr_true` mit allen Nicht-Item-Komponenten.
7. **(ACC-8) Prüfform K-M3c-6, Vignette und Klasse A.**
   1. Kandidatenpläne S-plan-1 bis S-plan-4 (20/20/40/40 Items, 3/5/3/5 Prompts, 3 Modelle, 2 Replikate, 2 Blöcke), Komponenten von S-boot-1, je Plan i ein Aufruf `msa_plan(plan, vc, nsim = ANK-06, seed = 20261108 + i, verbose = FALSE)` mit dem RNG aus docs/01 §5.
   2. Empirischer CV = sd/mean aller Prompt-Schätzungen einschließlich der Nullen; Grenzschätzung = Prompt-Schätzung genau 0; Anteil mit MCSE √(p(1 − p)/n_sim).
   3. Vignette: ein Abschnitt mit „planning rule“ in der Überschrift und eine Tabelle mit genau den Spalten plan, items, prompts, nu, cv_rule, cv_empirical, boundary_share, mcse_boundary, n_sim; keine Tabellenzahl als Literal im Rmd. Weitere Tabellen im Abschnitt sind zulässig (`acc_m3c_plan_table()` wählt die erste mit genau diesen Spalten).
   4. Klasse A erzeugt die Zahlen frisch und prüft Vollständigkeit sowie Gleichheit mit der gestrickten Vignette (halbe Einheit der letzten gezeigten Stelle plus ANK-TOL.arithmetic); den Abgleich mit der Planungsregel prüft kein Test. Die Vignette liest eine vorab erzeugte Ergebnisdatei; ändert sich `msa_plan()`, `msa_simulate()` oder `msa_fit()` ergebniswirksam, ist die Datei neu zu erzeugen.
8. **(ACC-1) Anker.**
   1. ANK-86 (Westgard et al. 1981, Druckseiten 494, 498, 500; Formelsammlung §8), ANK-87 (Parvin 1992, Tab. 1, Spalte N = 1, Toleranz 0,016 nach S. 360) und ANK-89 (Burdick & Graybill 1992, S. 30; Planungsregel Formelsammlung §2) sind in der ACCEPTANCE-Phase am Seitenbild erhoben; die Werte stehen in den Ankerdateien und in ACC-1.
   2. Wiederverwendet: ANK-06, ANK-16, ANK-02, ANK-TOL.mc_factor, ANK-TOL.oracle.closed_form_rel_tol, ANK-TOL.arithmetic.
   3. Dieses ADR ist das ADR zu den drei Ankern (docs/01 §6). Sie liegen vor `plan/M3c`; das Gate golden-adr ist nicht berührt. Unter `inst/extdata/` ändert sich in M3c nichts.
9. **(ACC-9) MCSE des empirischen CV und von 1/ARL.**
   1. Bis zu einer Entscheidung des Betreibers verlangen die Tests keinen MCSE für `cv_empirical`; der Klasse-A-Test zu K-M3c-3 berichtet den MCSE von 1/ARL nur über die Delta-Methode.
   2. Die in `PLAN.md` Z. 206–218 geplante, ausdrücklich benannte Delta-Methode über die ersten beiden empirischen Momente in einer eigenen Tabelle ist zulässig. Sie ändert keine Bestehensschwelle.
   3. Ob diese Formel in die Formelsammlung aufgenommen wird, entscheidet der Betreiber.
10. **(ACC-10, ACC-12) Hinweise an Builder, QA und Betreiber.**
    1. Bleibt der Satz „R_4s uses the range of two consecutive standardized values.“ für die Lesart range unverändert, bleibt QA-M3d-E2E-3 grün. Ändern kann ihn nur QA.
    2. `msa_report_control_chart()` bleibt attributfrei (Unit-Test `test-report-provenance.R`); `PLAN.md` gibt die Lesart in einem eigenen Renderparameter weiter.
    3. Die Abnahmetests von M3c laufen je Mutant; die Klasse-A-Studien laufen nicht in `MUT_TEST_DIRS`.
11. **(E1) `replicates$prompt` bei einem Plan ohne Prompt-Komponente.**
    1. Hat das Modell keine Prompt-Komponente, weil der Plan nur eine Prompt-Variante hat, ist `prompt` `NA_real_`. Null wäre eine Grenzschätzung, und eine solche liegt nicht vor (docs/01 §2 Nr. 4; AGENTS.md, Integrität Nr. 5).
    2. Bei mindestens zwei Prompt-Varianten bleibt `prompt` die REML-Schätzung aus `msa_fit()$vc`, ≥ 0 und endlich (ACC-7). Fehlt diese Zeile dort unerwartet oder ist sie ungültig, ist das ein benannter Fehler wie in `PLAN.md` Z. 146.
    3. Die Hilfe von `msa_plan()` nennt beides. Ein Unit-Test deckt den Plan mit einer Prompt-Variante ab.
12. **(E2) Lesart in `print()` bei älteren Objekten.** `print.msa_control_chart()` behandelt das Attribut `r4s` wie `msa_report()` (`PLAN.md` Z. 122–125): Fehlt es, gilt `range`; ist es ungültig, wird es weder still als `range` gedruckt noch verschwiegen (benannter Fehler oder ausdrücklicher Hinweis). Ein Unit-Test mit einem Objekt ohne Attribut.
13. **(E3) Westgard-Lesart bei fehlenden Kontrollwerten.** Die Westgard-Bedingung wird wie die bestehende Spannweitenbedingung vektorisiert (`&`, `|`, mit `& !is.na(lag)`), nicht mit `&&`. Fehlende Kontrollwerte brechen auch mit `r4s = "westgard"` nicht ab; die Spalte `R_4s` ist dort wie bei `range` `NA` oder `FALSE`, und `reject` bleibt mit `%in% TRUE` berechnet (ACC-2: Verhalten wie v0.1.0).
14. **(E4) Ankerkopien.** Unter `inst/validation/planning/anchors/` liegen nur Kopien von Ankern, die ein ausgelieferter Leser oder Text tatsächlich verwendet (Muster: `test-validation-latent.R:7`, `test-validation-numeric.R:102`). ANK-89 gehört dazu. ANK-86 und ANK-87 gehören nur dazu, wenn ein ausgelieferter Text sie liest (Nr. 15); sonst entfallen die Kopien.
15. **(E5) Dokumentation der übrigen Prüfungen in der Vignette.** `vignettes/validation.Rmd` erhält außer dem Abschnitt zur Planungsregel einen kurzen Methodentext zu K-M3c-1 bis K-M3c-5 (Regelgrenzen, Fehlalarm, Parvin, Shewhart-Grenzen gegen `qcc`, Simulator) nach dem Muster des M3b-Abschnitts (`validation.Rmd:406–428`), ohne abgetippte Ergebnisse (docs/01 §2 Nr. 8). Prüfwege werden mit Anker-IDs und Testdateien genannt. Zahlenliterale meidet der Text; die Literalwachen K-M1a-7, K-M1b-7, K-M1c-5, K-M1d-7 und `test-validation-latent.R` gelten für die ganze Datei. Sollen Ankerwerte erscheinen, werden sie aus den geprüften Kopien gelesen.
16. **(E7) Zahlenformat der Ergebnisdateien.** `replicates.csv.gz` speichert `estimate` und `prompt` mit voller Genauigkeit (`sprintf("%.17g", x)` oder gleichwertig). Eine Prompt-Schätzung genau 0 bleibt beim Einlesen genau 0, und alle Zusammenfassungen sind aus der Datei nachrechenbar. Die Zahlen der Tabelle entstehen aus den gespeicherten Replikaten, nicht aus gerundeten Zwischenwerten.
17. **(E8) Satz der Westgard-Lesart im Bericht.** Der Westgard-Satz nennt R_4s, die Lesart und aufeinanderfolgende Werte, etwa „R_4s uses the Westgard reading: one of two consecutive standardized values is above 2 and the other below -2.“; die Hilfe von `msa_control_chart()` nennt zusätzlich N = 2 bis 4 und „not intended for use across runs“ (ANK-86). Der Bericht wird nicht verpflichtet, die Laufzuordnung zu prüfen.
18. **(E9) Eingabeprüfung von `nsim`.** Die in `PLAN.md` Z. 172 geplante Prüfung (eine positive ganze Zahl, sonst benannter Fehler; `nsim = 1` bleibt ausführbar) ist keine Änderung der Bedeutung eines Arguments nach docs/01 §4: `nsim` bleibt die Zahl der Wiederholungen, und v0.1.0 hatte für Nicht-Ganzzahlen und null keine sinnvolle Bedeutung (Probe: `nsim = 2.5` rechnete zwei Wiederholungen, trug im Attribut 2,5, und `print()` brach mit „invalid format '%d'“ ab; `nsim = 0` gab eine Zeile aus `NaN`). `NEWS.md` nennt die Änderung.
19. **Hinweise (keine neue Regel).**
    1. **Mutationsumfang.** mutgate mutiert jede seit `plan/M3c` geänderte Datei unter `R/` ganz (`86-mutgate.sh:22`). Nach `PLAN.md` sind das `R/spc.R`, `R/plan.R` und `R/report.R` samt `validate_assessment()`. Probe des Reviewers auf der Attrappe (PLAN-REVIEW M3c r1, Prüflauf 4): 581 Mutanten, ohne die geplanten Unit-Tests 69,3 %. Über das Bestehen entscheidet allein das Gate; E6 nennt die nötigen Unit-Tests.
    2. **Backlog.** Die Abschnitte zu BL-50 (umgesetzt), BL-13 und BL-46 (Laufzeit gemessen) und BL-57 (Vorgabewerte) pflegt der Reviewer im Code-Review. In dieser Phase ist `BACKLOG.md` nicht Reviewer-Pfad (`orchestrate.sh:520`).
    3. **Betreiber:** ACC-9 (MCSE des CV) bleibt offen, nonblocking.

## Konsequenzen

- `PLAN.md` Runde 1 ist mit diesen Festlegungen freigegeben (PLAN-REVIEW M3c, Runde 1: PASS). BUILD folgt `PLAN.md` und diesem ADR; wo beide abweichen, gilt dieses ADR.
- Die minor-Befunde E1 bis E9 sind Umsetzungshinweise, gebunden über Nr. 11 bis 18 und PLAN-REVIEW.
- Das Code-Review M3c prüft gegen Nr. 1 bis 18.
- Die Messwerte im Kontext sind Proben des Reviewers auf einer Paketkopie, weder Ergebnisse des Builders noch Referenzwerte für Tests.
