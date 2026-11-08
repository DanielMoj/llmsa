# PLAN-REVIEW — M3c, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 08.11.2026 · Gegenstand: `orchestrator/handoff/M3c/PLAN.md` (Runde 1, 494 Zeilen). Es gibt keine `ARBITER.md` und kein `PLAN-UPDATE.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Kein blocking-Befund. Neun minor-Befunde (E1 bis E9).

- **Der Plan** deckt die sechs Kriterien mit den Auslegungen ACC-2 bis ACC-8 ab. Schnittstellen, Formeln und Reihenfolge stimmen mit docs/04 M3c, Formelsammlung §§2, 8 und 9, docs/01 §4 und den Abnahmetests überein. Eine Attrappe genau nach den Planschnittstellen besteht die M3c-Abnahme außer dem Vignettenabschnitt, dazu K-M3d-4 bis -6, QA-M3d und die berührten Unit-Tests (Prüflauf 3). Alle 144 Backlog-Einträge sind zugeordnet (Prüflauf 1).
- **Entscheidungen**, bindend in ADR-054:
  - Die Auslegungen ACC-2 bis ACC-8 und die Anker (ACC-1), Nr. 1 bis 8.
  - ACC-9 bleibt offen beim Betreiber; die geplante, benannte Delta-Methode für den CV-MCSE ist bis dahin zulässig (Nr. 9).
  - Präzisierungen zum Plan (Nr. 11 bis 18), auf die E1 bis E5 und E7 bis E9 verweisen. E6 ist ein Gate-Hinweis mit Zielen für die Unit-Tests.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-054-m3c-reviewer-auslegungen.md`;
  - `CRITERIA.json`: Status von ACC-1 bis ACC-10 und ACC-12 nachgeführt („festgehalten in ADR-054 Nr. n“); die sechs Kriterien sind unverändert.

### An den Betreiber

1. **ACC-9 bleibt offen (nonblocking):** Soll der MCSE eines Variationskoeffizienten in die Formelsammlung (Formel, Methode)? Bis zur Antwort berichtet der Plan ihn nach der benannten Delta-Methode in einer eigenen Tabelle (ADR-054 Nr. 9).
2. **Laufzeit mutgate:** `R/spc.R`, `R/plan.R` und `R/report.R` werden ganz mutiert (Attrappe: 581 Mutanten). M3d brauchte für 1443 Mutanten 13,9 und 19,1 Stunden je Durchgang (BL-144); bei 581 Mutanten hochgerechnet etwa 6 bis 8 Stunden je Durchgang (zweimal, vor und nach QA). Der Betreiber muss nichts tun; `orchestrator/state/mut-baseline` fehlt wie nach BL-123 verlangt.

### Ablauf

Mit PASS committet der Orchestrator diese Phase, setzt den Tag `plan/M3c` und startet `40-build`. BUILD folgt `PLAN.md` und ADR-054; wo beide abweichen, gilt das ADR. Der Builder-ADR des Plans erhält die nächste freie Nummer (ADR-055).

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`; die Prompts `30-plan-review.md` und `40-build.md`.
- **Orchestrator und Gates:** `orchestrate.sh` (`path_allowed` Z. 515–544, `verdict` Z. 734–756, Planschleife Z. 940–978), `gates.d/86-mutgate.sh`, `87-golden-adr.sh`, `70-trace.sh`, `lib/r-mutation.R`, `lib/r-deps.R`, `config.env` (Mutation und Pfade), `milestones.json`, `STATUS.md`, `artifact-paths.allowlist`.
- **Spezifikation:** docs/04 M3c; docs/01 §§1 bis 9; docs/02 Z. 55 (S-boot-1); Formelsammlung §§2, 8, 9 und §12 Nr. 6.
- **Handoff:** `orchestrator/handoff/M3c/CRITERIA.json`, `PLAN.md` vollständig; zum Format M3d `PLAN-REVIEW.md` und `verdict-plan.json`, M3b `PLAN-REVIEW.md` Z. 40–169; M3d `REVIEW.md` Z. 98–121 (Mutation je Datei).
- **ADRs:** ADR-021, ADR-043, ADR-053 (Z. 1–60, 150–217), Fundstellen in ADR-026, ADR-049, ADR-051, ADR-052.
- **Abnahmetests:** `setup-m3c.R`, `test-m3c-1` bis `test-m3c-6` vollständig; `setup-m1a.R` Z. 396–503 und 560–578; Literalwachen `test-m1a-7` Z. 95–134, `test-m1b-7` Z. 90–117, `test-m1c-5` Z. 42–62, `test-m1d-7` Z. 83–98; `test-m3a-7` und `test-m1d-5` vollständig; `test-m0-deps.R`; Fundstellen in `test-m3d-4`, `test-m3d-6` und `setup-m3d.R`.
- **Klasse-A-Studien:** `tests/simulation/setup-simulation.R`, `test-plan-satterthwaite.R`, `test-simulator-recovery.R`, `test-westgard-false-alarm.R`.
- **QA und Unit-Tests:** `tests/e2e/test-m3d-qa-e2e.R` Z. 325–374, `test-report-provenance.R` Z. 100–149, `test-robustness-plan-spc.R` Z. 45–76, `helper-validation-latent.R`, `helper-validation-vignette.R`, `test-validation-numeric.R` Z. 1–95 und 225–254, `test-validation-latent.R` Z. 125–156.
- **Produktcode und Bestand:** `R/spc.R`, `R/plan.R`, `R/report.R`, `R/report-data.R`, `R/utils.R` vollständig; `R/fit.R` (Fundstellen); `inst/templates/validation_report.Rmd`, `inst/validation/agreement/bias_coverage.R`; `vignettes/validation.Rmd` (Gliederung, Z. 355–437); `DESCRIPTION`, `.Rbuildignore`, `ANKER-TODO.md` Z. 120–126.
- **Anker und Backlog:** ANK-86, ANK-87, ANK-89, ANK-06 vollständig, ANK-TOL (`sim_runtime`, `data_size`), ANK-93 (Fundstelle); `BACKLOG.md` (alle IDs; im Wortlaut BL-13, BL-46, BL-50, BL-57, BL-76, BL-110, BL-114, BL-115, BL-123, BL-142 bis BL-144).

## Eigene Prüfläufe

R-Skripte unter `orchestrator/handoff/M3c/.probe-plan-review/` (danach gelöscht), Paketkopien unter `/tmp/m3c-pr-mock` (danach gelöscht), mit `Rscript --vanilla`. R 4.6.1. Produktcode und Tests im Arbeitsbaum sind unverändert. Kein Test mit Git-Aufruf (`acc_git()`) ausgeführt.

1. **Backlog-Abdeckung:** 144 IDs in `BACKLOG.md` (BL-01 bis BL-144), 98 Zeilen in der Tabelle des Plans (Z. 296–393), 46 weitere in der Liste der erledigten Einträge (Z. 395–400); keine fehlt, keine zusätzlich. BL-38 steht zu Recht als erledigt (kleingeschrieben in der Spalte „Folge“). In Z. 401–403 nennt der Plan zusätzlich BL-17/28, BL-104/113, BL-123 und BL-137/138 mit ihren offenen Restaufgaben.
2. **Formen von `msa_fit()` und Altverhalten von `msa_plan()`** (Arbeitsbaum):
   - Plan 10/1/2/2/1 (eine Prompt-Variante): `$vc` hat die Quellen `item:model`, `item`, `model`, `Residual`, keine Zeile `prompt`. Plan 8/2/2/2/2: `prompt` ist eine REML-Komponente (0,0446), singulär wegen anderer Komponenten. `msa_plan()` läuft auch mit einer Prompt-Variante.
   - `nsim`: 0 ergibt eine Zeile aus `NaN`; 2,5 rechnet zwei Wiederholungen, trägt im Attribut 2,5, und `print()` bricht mit „invalid format '%d'“ ab; −1 und `NA` enden mit R-Fehlern.
   - 300 Wiederholungen von S-plan-1 (19,6 s): 13 Prompt-Schätzungen genau 0, die kleinste positive 7,87e-05; jede genau-0-Schätzung ist singulär, 75 singuläre haben eine positive Prompt-Schätzung.
3. **Attrappe genau nach den Planschnittstellen** (Kopie unter `/tmp`): `R/spc.R` (`r4s`, `match.arg`, vektorisierte Westgard-Bedingung, Lesart in `print()`), `R/plan.R` (neue Spalten, `replicates`, `nsim`-Prüfung, Prompt-Schätzung, NA bei `nsim = 1`), `R/report.R` (`control_chart_reading` als eigener Renderparameter) und die Vorlage. `REPO_ROOT` zeigt auf die Kopie, `NOT_CRAN=true`, `load_package = "source"`:
   - M3c-Abnahme ohne Vignette (`^m3c-(1|2|4|5|6-plan)`): 22 Blöcke, 477 Erwartungen, 0 rot, 8 s.
   - `^m3d-(4|5|6)`: 19 Blöcke, 654 Erwartungen, 0 rot, 6 s. `tests/e2e` `m3d`: 3 Blöcke, 91 Erwartungen, 0 rot, 5 s (mit QA-M3d-E2E-3). `tests/testthat` (`robustness-plan-spc`, `report-provenance`, `report`, `fit-numeric`): 28 Blöcke, 271 Erwartungen, 0 rot, 7 s.
   - `test-m3c-6-vignette.R` und die Klasse-A-Studien liefen hier nicht (ACC-11, Attrappe der Acceptance: 25 Tests und Klasse A grün).
   - Spalte `R_4s` auf `c(0, 2.5, -2.1, NA, 3, -0.5, 2.1, -2.1, 0)`: unter beiden Lesarten `FALSE FALSE TRUE NA FALSE FALSE FALSE TRUE FALSE`.
   - `print()` eines alten Objekts ohne `r4s`: Kopfzeile, Zeile „R_4s reading: range (…)“, leere Tabelle.
4. **Mutationsschätzung** (Attrappe, Mutatoren wie `orchestrator/lib/r-mutation.R:59–67`): 581 Mutanten, 208 in `R/spc.R`, 256 in `R/plan.R`, 117 in `R/report.R`; ein Mutant nicht ladbar (das Gate zählt ihn nicht). Je Mutant eine eigene Paketkopie, Tests im eigenen R-Prozess, 12 Worker.
   - Stufe 1, direkt berührte Tests (19,9 min): M3c-Abnahme ohne Vignette, `m3d-4/5/6`, `robustness-plan-spc`, `report-provenance`, `report`, `agreement-report`, `fit-numeric`, `fit-grr`, `tests/e2e` m3d: 367 entdeckt, 213 überlebt.
   - Stufe 2, die Überlebenden gegen die übrigen Testdateien, die die Funktionen aufrufen: 25 Dateien unter `tests/testthat`, alle unter `tests/e2e` und `tests/fuzz`, dazu `m1a-1/5/6` und `m1c-7-latent-note` (keine `MUT_TEST_EXCLUDE`-Dateien; 257 Blöcke grün im unmutierten Lauf, 115 s; 59,6 min): 13 weitere entdeckt, alle in `R/plan.R`.
   - Stufe 3, `m0-api-snapshot` (ohne den Block, der das Gate-Skript und `git` braucht): 22 weitere entdeckt (Vorgabewerte). Nicht gelaufen: `test-m3c-6-vignette.R`, `test-m3a-6` (brauchen Vignettenbau bzw. geschützte Daten).
   - Ergebnis ohne die vom Plan vorgesehenen Unit-Tests: 402 entdeckt, 178 überlebt, Score 69,3 % (402/580); `R/spc.R` 69,7 %, `R/plan.R` 68,8 %, `R/report.R` 69,8 %. Für 80 % fehlen 62 weitere Entdeckungen.

   | Funktion | Mutanten | entdeckt | überlebt |
   | --- | ---: | ---: | ---: |
   | `msa_control_chart()` | 118 | 110 | 8 |
   | `print.msa_control_chart()` | 40 | 12 | 28 |
   | `plot.msa_control_chart()` | 50 | 23 | 27 |
   | `msa_simulate()` | 51 | 46 | 5 |
   | `msa_plan()` | 179 | 130 | 49 |
   | `print.msa_plan()` | 26 | 0 | 26 |
   | `msa_report()` | 70 | 50 | 20 |
   | Lesart der Karte (Hilfsfunktion) | 15 | 8 | 7 |
   | `validate_assessment()` | 31 | 23 | 8 |

5. **CRITERIA.json:** Vor der Änderung gab `jsonlite::toJSON(pretty = TRUE, auto_unbox = TRUE)` mit abschließendem LF die Datei byte-gleich wieder. Danach gültiges JSON, die sechs Kriterien unverändert.

## Antworten auf die Einwand-IDs

- **Runde 1:** Es gibt keine früheren Einwände.
- **ACC-1:** Die Anker liegen vor; festgehalten in ADR-054 Nr. 8, wie der Plan vorsieht (Z. 78–80).
- **ACC-2 bis ACC-8:** übernommen (Ziel, Schnittstellen und Testplan); festgehalten in ADR-054 Nr. 1 bis 7. Präzisiert: E1 (`prompt`), E7 (Datenformat).
- **ACC-9:** offen beim Betreiber; der Plan nutzt die zugelassene benannte Delta-Methode in einer eigenen Tabelle (Z. 206–218, ADR-054 Nr. 9).
- **ACC-10:** `qcc` in Suggests (Z. 57); Laufzeit der Klasse A gemessen (Z. 451–455).
- **ACC-11:** erledigt; der Plan übernimmt die Attrappenzahlen nicht als Nachweis (Z. 25–26).
- **ACC-12:** beachtet. Der QA-Satz bleibt für `range` wörtlich (Z. 117–119), `R/report-data.R` bleibt unverändert und attributfrei (Z. 72–76); Prüflauf 3 bestätigt beides.
- **BACKLOG:** alle 144 Einträge zugeordnet (Prüflauf 1); BL-50 umgesetzt; Vertagungen nennen Grund und Zuständigkeit (AGENTS.md, Handoff-Disziplin).

## Einwände (Runde 1)

- [E1] (minor) K-M3c-6; ACC-7; docs/01 §2 Nr. 4; AGENTS.md, Integrität Nr. 5; `PLAN.md` Z. 146 — **Befund:** „Eine strukturell nicht geschätzte Prompt-Komponente ist null“ kennzeichnet einen Plan mit nur einer Prompt-Variante als Grenzschätzung 0, obwohl gar keine Schätzung vorliegt (Prüflauf 2: keine Zeile `prompt` in `$vc`, Plan 10/1/2/2/1). Die Null wäre von einer echten REML-Grenzschätzung nicht zu unterscheiden. — **Vorschlag:** ADR-054 Nr. 11: `NA_real_` bei einem Plan mit einer Prompt-Variante; bei mindestens zwei Varianten REML-Schätzung ≥ 0; eine unerwartet fehlende Zeile bleibt ein benannter Fehler; Hilfe und ein Unit-Test.
- [E2] (minor) K-M3c-2; ACC-3; `PLAN.md` Z. 122–125 — **Befund:** Den Fall eines alten Objekts ohne Attribut `r4s` und eines ungültigen Attributs regelt der Plan nur für den Bericht, nicht für `print()`. — **Vorschlag:** ADR-054 Nr. 12: `print.msa_control_chart()` behandelt beide Fälle wie der Bericht; Unit-Test mit einem Objekt ohne Attribut.
- [E3] (minor) K-M3c-2; ACC-2 („Fehlende Kontrollwerte sind nicht Teil dieses Vertrags (Verhalten wie v0.1.0)“); `PLAN.md` Z. 93–96 — **Befund:** Die Bedingung ist skalar mit `&&` notiert. Skalar umgesetzt brächen `NA`-Werte in `x` mit `r4s = "westgard"` ab oder ergäben ein anderes Verhalten als `range`. Prüflauf 3: Vektorisiert wie die Spannweitenbedingung entstehen dieselben `NA` bzw. `FALSE`. — **Vorschlag:** ADR-054 Nr. 13: vektorisiert wie `range`, kein neuer Abbruch bei fehlenden Werten, `reject` wie bisher mit `%in% TRUE`.
- [E4] (minor) docs/01 §6; ADR-021; `tests/testthat/test-validation-latent.R:7`; `tests/testthat/test-validation-numeric.R:102`; `PLAN.md` Z. 62–63 — **Befund:** Der Plan kopiert ANK-86 und ANK-87 nach `inst/validation/planning/anchors/`, ohne einen Leser zu nennen. Der Leser braucht nur ANK-89 (Zähler, Freiheitsgrad-Versatz; `PLAN.md` Z. 197–198). Bisherige Ressourcen kopieren genau die verwendeten Anker. — **Vorschlag:** ADR-054 Nr. 14: nur Kopien von Ankern, die ein ausgelieferter Leser oder Text verwendet; ANK-86 und ANK-87 entfallen, sofern nicht E5 sie liest.
- [E5] (minor) docs/01 §2 Nr. 8 („… ist in der Vignette `vignettes/validation.Rmd` dokumentiert“); Muster M3b `vignettes/validation.Rmd:406–428`; `PLAN.md` Z. 67 — **Befund:** Der Plan ergänzt die Vignette nur um die Planungsregel. Die Prüfwege von K-M3c-1 bis K-M3c-5 (Regelgrenzen, Fehlalarm, Parvin, `qcc`-Grenzen, Simulator) bleiben undokumentiert. — **Vorschlag:** ADR-054 Nr. 15: kurzer Methodentext ohne abgetippte Ergebnisse, Prüfwege mit Anker-IDs und Testdateien; die Literalwachen K-M1a-7, K-M1b-7, K-M1c-5, K-M1d-7 und `test-validation-latent.R` gelten für die ganze Datei. Sollen Ankerwerte erscheinen, werden sie aus den geprüften Kopien gelesen (dann gilt E4 entsprechend).
- [E6] (minor) Gate mutgate (`gates.d/86-mutgate.sh:22`, `:87–93`; `config.env:228–230`, `:267`); ANK-32; docs/01 §2 Nr. 7; ADR-047 Nr. 4; `PLAN.md` Z. 58–61, 483–488 — **Befund:** Der Plan weiß, dass ganze Dateien mutiert werden (Z. 483–488), und nennt Drucktests für die Karte (Z. 58). Für `print.msa_plan()` und `plot.msa_control_chart()` sieht er keine Tests vor. Prüflauf 4: Ohne die geplanten Unit-Tests erreicht die Attrappe 69,3 %, verlangt sind 80 %; es fehlen 62 Entdeckungen. Allein `print.msa_control_chart()`, `print.msa_plan()` und `plot.msa_control_chart()` stellen 81 Überlebende. — **Vorschlag:** Unit-Tests unter `tests/testthat/` (Namen außerhalb von `MUT_TEST_EXCLUDE`, Laufzeit im Bereich von Sekunden, weil sie je Mutant laufen), nach Überlebenden geordnet:
  1. **`print.msa_control_chart()`** (28): ganze Ausgabe von `capture.output(print(x))`, gebildet aus dem Objekt: Kopfzeile, Lesart beider Fälle, Zeile „rules fired“ mit Anzahlen und nur den ausgelösten Regeln, Tabelle nur mit abgelehnten oder gewarnten Zeilen ohne Zeilennamen; dazu eine Karte ohne Verletzung und `1_2s`-Zeilen ohne Ablehnung; Rückgabe unsichtbar und identisch.
  2. **`print.msa_plan()`** (26): zwei Szenarien; ganze Ausgabe mit Kopfzeile (`nsim`), Zeile des wahren %GRR, Tabelle ohne `grr_true`, die neuen Spalten auf der vorgesehenen Stellenzahl, Rückgabe unsichtbar.
  3. **`plot.msa_control_chart()`** (27): aus der Display-Liste (`recordPlot()`, wie die M3b-Tests): `pch` und `col` je `reject`, `ylim` auf Daten innerhalb von ±3 sd (dann gleich `ctr ± 3.2·s`), `lty` und `col` der Linien, Achsenbeschriftung, Haupttitel. Die drei `+`/`-`-Mutanten in `ctr + c(-k, k) * s` sind mengengleich; dafür kein Test.
  4. **`msa_plan()`** (49):
     - je Teilbedingung von `nsim` und der Prompt-Prüfung ein eigener Fall, Meldungen genau (`expect_error(…, fixed = TRUE)`), `conditionCall()` gleich `NULL`;
     - `nsim = 1`: `identical()` mit `NA_real_`, Spalten vom Typ double, nicht `NaN` (trifft `n > 1` → `>=` und `NA_real_` → `NA`);
     - Verdikte genau bei 10 und 30 mit `testthat::local_mocked_bindings(grr_stats = …)`, das `msa_plan()` diese Schätzer gibt (die Simulation trifft sie nie);
     - unabhängige Nachrechnung von `replicates` mit demselben Seed und derselben RNG-Reihenfolge über `msa_simulate()` und `msa_fit()` (trifft die Index-Mutanten `est[b - 1]`, `sing[b - 1]`, `prompt[b - 1]`, `replicates[[i + 1]]`);
     - `verbose = TRUE` mit `expect_message()`, `n_blocks` als fehlende Spalte, Fehler bei fehlenden Spalten.
  5. **`msa_report()`** und **Lesart der Karte** (27): jede Fehlermeldung genau, `conditionCall()` gleich `NULL` (die meisten Überlebenden); ungültiges Attribut `r4s` in den Formen Länge 2, kein Text, unbekannter Wert; fehlendes Attribut.
  6. **`validate_assessment()`** (8, offen seit M3d, BL-142): je Teilbedingung genau ein ungültiger Eingabeteil.
  7. **`msa_control_chart()`** (8): nur `center` oder nur `sd` gegeben; `NA` im Basisbereich (`na.rm`); Meldung bei ungültigem `sd` genau; `rules` ohne Ablehnungsregel (`reject` überall `FALSE`).
  8. **`msa_simulate()`** (5): Nachrechnung von `value` und `latent` mit festem Seed und derselben Zufallsfolge (die Vorzeichenmutanten verteilen sich sonst gleich).
  9. **Äquivalenzkandidaten** (keine Freigabe zugesagt, Antrag nur einzeln in `MUT-EQUIV.json` mit Beweis): `lagz` mit `NA_real_`/`NA_integer_`, `add = TRUE` beim einzigen `on.exit()`, `showWarnings`/`recursive`/`overwrite` in `msa_report()`, die drei Mengen-Mutanten aus Punkt 3.
  10. Kein Score über den Code (keine Umbauten oder Ausschlüsse), wie ADR-051 Nr. 10.4.
- [E7] (minor) K-M3c-6; ACC-8; `PLAN.md` Z. 65 — **Befund:** Das Zahlenformat von `replicates.csv.gz` ist offen. Eine gerundete Speicherung kann eine sehr kleine positive Schätzung auf 0 ziehen und die Nachrechnung der Tabelle verfälschen (Prüflauf 2: kleinste positive Schätzung 7,87e-05 in 300 Wiederholungen). — **Vorschlag:** ADR-054 Nr. 16: `estimate` und `prompt` mit voller Genauigkeit (`sprintf("%.17g", x)` oder gleichwertig); die Tabellenzahlen entstehen aus den gespeicherten Replikaten.
- [E8] (minor) K-M3c-2 („Paare aufeinanderfolgender Werte“); ANK-86 (S. 498, 500); `PLAN.md` Z. 121–122 — **Befund:** Der Westgard-Satz im Bericht soll laut Plan Lesart und Schwellen nennen. Er sollte auch die Anwendung auf aufeinanderfolgende Werte nennen, denn die Karte kennt keine Läufe. — **Vorschlag:** ADR-054 Nr. 17: Satz wie „R_4s uses the Westgard reading: one of two consecutive standardized values is above 2 and the other below -2.“; Hilfe wie im Plan (Z. 105–110).
- [E9] (minor) docs/01 §4 („geänderte Bedeutung eines Arguments“); `PLAN.md` Z. 172 — **Befund:** Die geplante Prüfung von `nsim` macht bisher lauffähige Eingaben (0, 2,5) zum Fehler. Prüflauf 2 zeigt: Beide hatten keine sinnvolle Bedeutung (0 ergibt `NaN`-Zeilen, 2,5 rechnet zwei Wiederholungen, und `print()` bricht ab). — **Vorschlag:** ADR-054 Nr. 18: Die Prüfung ist keine Bedeutungsänderung; `NEWS.md` nennt sie.

## Prüfung nach Gesichtspunkten

- **Spec-Treue:**
  - K-M3c-1 und K-M3c-2: strikte Ungleichungen, Fenster, Standardisierung, `r4s` mit Vorgabe `range` an letzter Stelle, Lesart in `print()` und Bericht (Z. 86–125).
  - K-M3c-3: keine Produktänderung außer `r4s`; Klasse-A-Prüfung unverändert (Z. 439–440).
  - K-M3c-4: gezeichnete Linien unverändert, `qcc` in Suggests (Z. 33, 57).
  - K-M3c-5: Simulator unverändert, Itemwahrheit mitgeführt (Z. 129–133).
  - K-M3c-6: neue Spalten, `replicates`, Formeln wie Formelsammlung §9 (Z. 135–177), Tabelle wie ACC-8 (Z. 181–204), Vergleich ohne Bestehensschwelle.
- **Architektur:** Änderungen in `R/spc.R`, `R/plan.R`, `R/report.R` und der Vorlage; keine neuen Exporte oder Importe (`qcc` nur Suggests). Leser ohne Generator nach ADR-043; `mclapply` nur unter `inst/validation/sim/`; `system.file()` mit wörtlichen Pfaden (Z. 280).
- **Verträge:** nur zulässige Ergänzungen nach docs/01 §4 (letztes Argument mit Vorgabe, neue Spalten und Attribute, Druckausgabe); `msa_report()`-Signatur unverändert; ANK-02 bleibt. `nsim`: E9.
- **Vollständigkeit:** Die Dateiliste deckt alle Kriterien; Unit-Tests (E6), `prompt` (E1), Druck alter Objekte (E2). Alle 144 Backlog-Einträge zugeordnet.
- **Risiken:** Die Liste des Plans (Z. 274–284) trifft die Klassen. Hinzu kommen: Mutationsgrad der drei ganzen Dateien (E6), Zahlenformat (E7) und `R/report.R` samt `validate_assessment()` im Mutationsumfang (ADR-054 Nr. 19.1). LESSONS: Der Plan bindet Numerikfehler als Klasse (Z. 282).
- **Gate-Abdeckung:**

  | Kriterium | Prüfweg | Gates |
  | --- | --- | --- |
  | K-M3c-1 | `tests/acceptance/test-m3c-1-westgard-rules.R` | tests; mutgate je Mutant |
  | K-M3c-2 | `tests/acceptance/test-m3c-2-r4s-reading.R` | tests; mutgate je Mutant |
  | K-M3c-3 | `tests/simulation/test-westgard-false-alarm.R` (ID auch in `setup-m3c.R`) | tests; trace |
  | K-M3c-4 | `tests/acceptance/test-m3c-4-qcc-limits.R` | tests; mutgate je Mutant; deps (`qcc`) |
  | K-M3c-5 | `tests/simulation/test-simulator-recovery.R`, `tests/acceptance/test-m3c-5-simulator-latent.R` | tests; mutgate je Mutant (Abnahmeteil) |
  | K-M3c-6 | `tests/acceptance/test-m3c-6-plan-replicates.R`, `test-m3c-6-vignette.R`, `tests/simulation/test-plan-satterthwaite.R` | tests; mutgate je Mutant (Abnahmeteil); lint (Vignette) |
  | alle | Kriteriums-IDs in `tests/acceptance` | trace |
  | Bestand | M0- bis M3d-Abnahme, QA- und Unit-Tests | tests; mutgate (ohne `MUT_TEST_EXCLUDE`) |
  | Anker | vor `plan/M3c` geerntet; `inst/extdata/` unverändert | golden-adr |
  | Pfade | Dateiliste des Plans liegt in `R/`, `man/`, `tests/testthat/`, `vignettes/`, `inst/`, `data-raw/`, `DESCRIPTION`, `NEWS.md`, `PROGRESS.md`, `docs/decisions/` und den zugewiesenen Handoffs | territory |

## Hinweise für BUILD

- **Vertrag:** `PLAN.md` und ADR-054; bei Abweichung gilt das ADR. Das Code-Review prüft gegen Nr. 1 bis 18.
- **Numerik:** Die Planungsdaten erst nach Stabilisierung von `R/plan.R`, `msa_simulate()` und `msa_fit()` rechnen, wie der Plan sagt (Z. 266–268); ändern sie sich ergebniswirksam, neu erzeugen (Klasse A wird sonst rot).
- **Unit-Tests** nach E6, vor dem ersten Gate-Lauf; bei Bedarf lokal schätzen (Prüflauf 4 lief mit 12 Workern, Stufe 1 in 20 Minuten).
- **Bericht:** Satz für `range` wörtlich (QA-M3d-E2E-3), Satz für `westgard` nach ADR-054 Nr. 17; `msa_report_control_chart()` bleibt attributfrei.
- **Vignette:** Abschnitt zur Planungsregel mit den neun Spalten; Methodentext nach Nr. 15; `sys.source()` nur mit wörtlichem `system.file()`-Pfad; keine Zahlenliterale, die die Literalwachen treffen.
- **Prüfumfang** laut Testplan (Z. 405–493), mit `REPO_ROOT`, `NOT_CRAN=true` und `options(testthat.progress.max_fails = Inf)`.
