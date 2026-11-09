# REVIEW — M3c, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 09.11.2026 · Gegenstand: Diff seit `plan/M3c` (Basis 146008d), Stand nach QA (`gates.json`: sha 474c07e). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Keine Git-Kommandos: Der Diff ist aus den Objektdateien rekonstruiert (Prüflauf 1).

## Ergebnis

**Verdict PASS, blocking leer.** `gates.result = pass`, kein blocking-Befund. Fünf minor-Befunde (E10 bis E14), alle in `BACKLOG.md` (BL-145 bis BL-148, E12 in BL-146).

- **Spec und Verträge:** K-M3c-1 bis K-M3c-6 sind nach den Auslegungen ACC-2 bis ACC-8 (ADR-054 Nr. 1 bis 7) und den Festlegungen Nr. 11 bis 18 umgesetzt. Die sechs Kriterien sind im tests-Gate grün (M3c-Abnahme 528 Erwartungen, Klasse A 257, QA 4394).
- **API:** Einzige Schnittstellenänderung ist `r4s = c("range", "westgard")` als sechstes und letztes Argument von `msa_control_chart()`. Alle anderen Signaturen und der NAMESPACE sind unverändert. Neue Spalten und das Attribut `replicates` sind ergänzend (docs/01 §4).
- **Integrität:** Kein bestehender Test geändert oder gelöscht, keine Abnahme- oder Klasse-A-Datei berührt. Keine Golden-Änderung (`inst/extdata/`, `reference/anchors/`), keine gelockerte Konfiguration. Die Planungsdaten sind echte Rechnungen (Prüflauf 2 und 4; Klasse A rechnet sie im Gate frisch nach und vergleicht mit der Vignette).
- **Mutation:** mutgate pass (93,8 % bei 91,6 % verlangt). Von 34 Überlebenden sind 24 äquivalent oder ohne beobachtbare Wirkung; 10 sind Testlücken bei richtigem Produkt (E10). Es gibt keine Äquivalenzanträge, daher kein `MUT-EQUIV-APPROVED.json`.
- **BACKLOG:** BL-13, BL-46, BL-50 und BL-57 nachgeführt (ADR-054 Nr. 19.2), BL-145 bis BL-148 neu.

Einschränkung der Prüfung: Die Gates habe ich nicht wiederholt (Gates sind Fakten). `R CMD check` und die volle Abnahme liefen nur im Gate; Windows und macOS sind wie bisher nicht geprüft (BL-137, BL-138).

### An den Betreiber

1. **ACC-9 bleibt offen (E13, BL-147):** Soll der MCSE eines Variationskoeffizienten in die Formelsammlung (Formel und Methode)? Bis dahin steht die benannte Delta-Methode in einer eigenen Tabelle der Vignette (ADR-054 Nr. 9).
2. **README, Statustabelle (E14, BL-148):** `README.md:188–190` nennt Westgard, Simulator und Planung weiter „implemented; not yet validated“, ebenso Agreement („validation in progress“) und Ausführung/Bericht („not yet validated“), obwohl M3a, M3c und M3d abgenommen sind. Die Datei liegt außerhalb der Pfade des Builders (`BUILDER_EXTRA_PATHS_REGEX`).
3. **Laufzeit:** Gate-Lauf nach QA rund 7 h 35 min, davon mutgate rund 6 h 40 min (582 Mutanten, 23 676 s; BL-13). Der Betreiber muss nichts tun.

## Gate-Fakten (`orchestrator/state/M3c/gates.json`, Runde 1)

| Gate | Status | Beleg |
| --- | --- | --- |
| deps | pass | 32 Anforderungen erfüllt, darunter qcc 2.7 (`gate-deps.log`) |
| lint | pass | `R CMD check --as-cran --no-manual`: `Status: OK` (`gate-lint.log` Z. 89–91) |
| tests | pass | 930 Tests, 0 fehlgeschlagen, 0 Fehler, 1 übersprungen (`gate-tests.log` Z. 2712) |
| trace | pass | alle Kriterien beidseitig verknüpft |
| territory | pass | letzter Diff sauber (qa/45-qa, Runde 1) |
| mutgate | pass | score 93,8, verlangt 91,60, Baseline 93,8, Floor 80 (`gate-mutgate.log` Z. 700) |
| golden-adr | pass | keine Golden-/Ankeränderung |
| mutfull | pass | nicht fällig in M3c |

Zu den Tests im Einzelnen (`gate-tests.log`): testthat 7917 (Z. 774), Abnahme 19 080 (Z. 2390), Klasse A 257 in 261,6 s (Z. 2428), e2e 1037 (Z. 2550), fuzz 5755 (Z. 2711). M3c-Abnahme: m3c-1 223, m3c-2 124, m3c-4 43, m3c-5 16, m3c-6-plan 71, m3c-6-vignette 51. Der einzige Skip ist `test-backends.R:32` (ellmer installiert). Die zwei Warnungen der Abnahme stammen aus `test-m1b-4-two-levels.R:41` und `:42` (BL-93), kein Bezug zu M3c. Klasse A liegt unter ANK-TOL.sim_runtime (20 min).

## Diff seit `plan/M3c` (Prüflauf 1)

Geändert: `R/spc.R`, `R/plan.R`, `R/report.R`, `inst/templates/validation_report.Rmd`, `man/msa_control_chart.Rd`, `man/msa_plan.Rd`, `man/msa_report.Rd`, `vignettes/validation.Rmd`, `DESCRIPTION` (nur `qcc` in Suggests), `NEWS.md`, `PROGRESS.md`. Neu: `inst/validation/planning/**`, `inst/validation/sim/planning_rule.R`, `data-raw/make_validation_planning.R`, vier Unit-Testdateien, `tests/e2e/test-m3c-qa-e2e.R`, `tests/fuzz/test-m3c-qa-fuzz.R`, `docs/decisions/ADR-055-m3c-planungsressourcen.md`, `orchestrator/handoff/M3c/QA.md`. Unverändert: alle bestehenden Tests, `tests/acceptance/**`, `tests/simulation/**`, `R/report-data.R`, `R/fit.R`, `R/grr.R`, `NAMESPACE`, Anker und `inst/extdata/`.

## Spec- und Vertragstreue, API-Diff, Integrität

- **K-M3c-1:** Grenzen strikt, Fenster vollständig, `1_2s` nur Warnung, Standardisierung wie Formelsammlung §8. Im Gate und gegen die Mini-Referenz grün; Prüflauf 3: 3000 Zufallsreihen (auch mit `NA`) unter der Vorgabe je Spalte `identical()` zu `plan/M3c`.
- **K-M3c-2:** Argument an letzter Stelle, `match.arg()`, Westgard-Bedingung vektorisiert wie die Spannweite (ADR-054 Nr. 13). `print()` nennt die Lesart immer, Bericht mit eigenem Parameter `control_chart_reading`; `msa_report_control_chart()` bleibt attributfrei (Nr. 10.2). Der Range-Satz steht wörtlich, der Westgard-Satz nach Nr. 17 (Prüflauf 5, beide Berichte gerendert). Alte Karten ohne Attribut gelten als `range`, ungültige Attribute sind ein benannter Fehler (Nr. 12). Die Hilfe nennt N = 2 bis 4 und „not intended for use across runs“ mit den Seiten aus ANK-86.
- **K-M3c-3:** Keine Produktänderung außer `r4s`; `test-westgard-false-alarm.R` im Gate grün (Bewertung nach ADR-054 Nr. 3).
- **K-M3c-4:** `plot.msa_control_chart()` ist unverändert; `m3c-4-qcc-limits` grün, `qcc` in Suggests (ADR-054 Nr. 4).
- **K-M3c-5:** `msa_simulate()` ist unverändert; deterministisch `m3c-5-simulator-latent` und Klasse A `test-simulator-recovery.R` grün.
- **K-M3c-6:** Spalten `bias`, `empse`, `mcse_bias`, `mcse_empse`, Attribut `replicates`, `grr_true` nach Formelsammlung §9, Formeln und Verdikte nach ADR-054 Nr. 6; `prompt` `NA_real_` bei einer Prompt-Variante (Nr. 11); `nsim` geprüft und in `NEWS.md` genannt (Nr. 18). Vignette: Abschnitt „Planning rule …“ mit genau den neun Spalten, CV-MCSE nach ADR-054 Nr. 9 in eigener Tabelle, Daten mit `%.17g` (Nr. 16). Methodentext zu K-M3c-1 bis K-M3c-5 (Nr. 15), nur ANK-89 kopiert (Nr. 14).
- **Plan gegen Umsetzung:** Abweichungen nur wie ADR-054 verlangt (Nr. 11, 14). Die ergänzende Druckkorrektur für `rules = "R_4s"` (ADR-055 Nr. 7) ist richtig: Vorher fehlte die Spalte `1_2s`, und die Ablehnungszeile verschwand; jetzt steht sie in der Tabelle (Unit-Test und QA-E2E-1). `REVIEW-INPUT.md` hat der Builder nicht geliefert (PLAN Z. 70); der Inhalt steht in `PROGRESS.md`, kein Befund. Antworten auf E1 bis E9 stehen in `PROGRESS.md`; alle neun sind umgesetzt.
- **ADR-055:** Die Ressourcenablage entspricht ADR-054 Nr. 7, 14 und 16. Die Delta-Rechnung habe ich nachgerechnet: Gradient nach m1 ist `-m2/(m1² sqrt(v))`, nach m2 `1/(2 m1 sqrt(v))`, jeweils mal `sqrt(n/(n-1))`, Kovarianz `cov((y, y²))/n`; das stimmt mit `reference_checks.R:124–125` überein.
- **Provenienz (Prüflauf 2):** Alle 17 Quell-Hashes aus `session.txt` und `SOURCES.json` gleichen den aktuellen Dateien; die vier Anker-Hashes gleichen den Originalen.
- **Altverhalten `msa_plan()` (Prüflauf 3):** 108 Pläne im Gitter (Items, Prompts, Modelle, Replikate, Blöcke bis 2): 93 rechnen, 15 scheitern in beiden Ständen (Meldung im neuen Stand: „number of levels of each grouping factor must be < number of observations“), keine Statusänderung, alle gemeinsamen Spalten gleich.

### Neue Tests

Die vier Unit-Dateien belegen Verhalten: Grenzreihen von Hand (`test-control-chart.R:9–23`), Replikate unabhängig über `msa_simulate()`/`msa_fit()` mit gleicher RNG-Folge nachgerechnet (`test-plan.R:40–79`), Verdikte an den Grenzen 10 und 30 mit gemockten Schätzern, Ressourcenfehler in Kopien. Die Druckausgaben sind Momentaufnahmen und als solche gekennzeichnet (`test-control-chart.R:81`, `test-plan.R:209`). Harte Werte sind von Hand nachgerechnet und richtig (etwa `test-control-chart.R:14–15`, `:153`). Keine Abnahme- oder Bestandsdatei wurde geschwächt.

QA (`tests/e2e/test-m3c-qa-e2e.R`, `tests/fuzz/test-m3c-qa-fuzz.R`) nutzt eigene Orakel und Handnachrechnungen; 219 und 4175 Erwartungen grün. QA nennt 0 blocking-Befunde; der eine nonblocking-Befund ist E11.

### Visuelle Artefakte

`orchestrator/state/M3c/shots` ist leer (keine Web-UI). Eigene Sichtung (Prüflauf 5): Vignette gestrickt (Tabellen und Text richtig, Überschriften konsistent), Berichtsabschnitt beider Lesarten gerendert, Regelkarte als PNG. Keine sichtbaren Defekte. Kleinigkeiten stehen in E12.

## Mutation (Bericht `reports/mutation/mutation.json`, `gate-mutgate.log` Z. 590–700)

582 Mutanten in `R/plan.R`, `R/report.R`, `R/spc.R` (Schlüssel `report.key`): 514 Killed, 34 Survived, 34 RuntimeError, 0 NoCoverage. Score nach Gate 514/548 = 93,8 %. Bei den RuntimeError nennt der Bericht in 7 Fällen einen Parsefehler beim Laden (negierte Mehrzeilenbedingungen), in 27 Fällen ist `statusReason` leer (Laufabbruch); alle 34 verlassen den Nenner.

Es liegt kein `MUT-EQUIV.json` vor, also ist nichts zu genehmigen. Einordnung der Überlebenden (nicht blocking, Gate grün):

| Stelle (Datei:Zeile, mutatorName) | Einordnung |
| --- | --- |
| `plan.R:21`, `:96`, `report.R:118` `TRUE → FALSE` (`add`) | äquivalent, je ein `on.exit` |
| `plan.R:26` `FALSE → TRUE` (`stringsAsFactors`) | äquivalent: `as_msa_runs()` wandelt in `character` (`R/run.R:208–209`), Reihenfolge der Schlüssel gleich |
| `plan.R:102` (3×) `<non-empty string> → ""` | äquivalent, Labels werden nur verglichen |
| `plan.R:131` `> → >=`; `plan.R:140` `<n> - 1` (0), `> → >=` | äquivalent bei `nsim = 1` (`sd` und `NA/0` sind `NA_real_`) |
| `spc.R:61` `NA → NA_real_`, `NA_integer_` | äquivalent (`c()` erzwingt double) |
| `spc.R:121`, `:122`, `:123` `+ → -` | mengengleich, schon in E6 als äquivalent genannt |
| `spc.R:90`, `report.R:104` `TRUE → FALSE` (`exact`); `report.R:92` (2×) (`quietly`); `report.R:114`, `:115` (2×), `:116` (2×) (Pfade, `showWarnings`, `recursive`, `overwrite`) | ohne beobachtbare Wirkung im Vertrag |
| `plan.R:113` (4×) `< → <=`, `<n> + 1` (0→1), `<n> - 1` (100→99), `> → >=` | Testlücke, siehe E10 |
| `plan.R:140` `<n> + 1` (`nsim > 2`), `plan.R:151` (2×) `x[<i>] → x[<i> + 1L]`, `<n> + 1` | Testlücke, siehe E10 |
| `spc.R:119` `TRUE → FALSE` (`na.rm`), `report.R:113` `<non-empty string> → ""`, `report.R:127` `\|\| → &&` | Testlücke, siehe E10 |

Bestätigung zu `plan.R:113`: Eine Schätzung von genau 100 kommt vor. Im Plan 4/2/2/2/1 mit Item-Komponente 1e-6 lagen 15 von 25 Wiederholungen genau bei 100 (Prüflauf 5); der Lauf endet richtig ohne Abbruch.

## Einwände (Runde 1)

Die Nummern setzen die PLAN-REVIEW fort (E1 bis E9), damit jede ID im Meilenstein eindeutig bleibt. Kein Eintrag ist blocking.

- [E10] (minor) Gate mutgate (pass, `gate-mutgate.log` Z. 593–694, Z. 700); `reports/mutation/mutation.json` — **Befund:** Zehn Überlebende sind echte Testlücken bei richtigem Produkt: `R/plan.R:113` (Grenzen der Schätzerprüfung, gültige Werte 0 bis 1 und 99 bis 100, genau 100 kommt vor), `:140` (`nsim > 2`, ungeprüft bei `nsim = 2`), `:151` (Druck der Zeile „true %GRR“ bei einem Plan mit einer Zeile), `R/spc.R:119` (`plot()` mit fehlendem Kontrollwert), `R/report.R:113` (Format von `rendered_at`), `:127` (`|| → &&`, benannter Atomvektor). — **Vorschlag:** Tests beim nächsten Eingriff (BL-146); kein Äquivalenzantrag nötig.
- [E11] (minor) `orchestrator/handoff/M3c/QA.md` QA-M3c-001; `R/spc.R:74–85`; ADR-035 — **Befund:** Unbekannte Regelnamen in `rules` werden still ignoriert (`rules = "1_3S"` ergibt `reject` überall `FALSE`), und `n_baseline` unter 2 führt nur über `sd` zum Fehler. Reproduziert (Prüflauf 5). Herabstufung begründet: kein roter reproduzierender Test, QA schlägt nonblocking vor, Bestand seit v0.1.0, außerhalb von ADR-054 Nr. 1 und 2, Abschlussregel ADR-035. — **Vorschlag:** BL-145, nach dem 26.11.2026.
- [E12] (minor) `R/plan.R:90`; `vignettes/validation.Rmd:447`; `inst/templates/validation_report.Rmd:221–225` — **Befund:** (1) `is.complex(nsim)` ist unerreichbar, denn `!is.numeric(1i)` greift zuerst. (2) „so the caller supplies that grouping“: Die Schnittstelle nimmt keine Laufzuordnung an; gemeint ist „must ensure“ (wie die Hilfe). (3) Der Satz zur R_4s-Lesart erscheint im Bericht auch, wenn `R_4s` nicht in `rules` liegt (Probe, Bestand seit M3d); die Lesart stimmt, gezeigt wird keine R_4s-Zeile. — **Vorschlag:** beim nächsten Eingriff (BL-146); kein Eingriff vor dem 26.11.2026 nötig.
- [E13] (minor) ACC-9; ADR-054 Nr. 9 — **Befund:** Der MCSE des empirischen CV ist nicht in der Formelsammlung; die Vignette nutzt die zulässige benannte Delta-Methode in einer eigenen Tabelle, ohne Bestehensschwelle. — **Vorschlag:** Betreiberentscheidung (BL-147).
- [E14] (minor) `README.md:188–190`; `BUILDER_EXTRA_PATHS_REGEX` — **Befund:** Die Statustabelle ist nach M3a, M3c und M3d veraltet; die Datei liegt außerhalb der Builder-Pfade. — **Vorschlag:** Betreiber nach Abschluss der Meilensteine (BL-148).

## Eigene Prüfläufe

Probe-Skripte unter `orchestrator/handoff/M3c/.probe-r1/`, Ausgaben dort; danach gelöscht. `Rscript --vanilla`, R 4.6.1, `pkgload::load_all()` auf dem Arbeitsbaum, `REPO_ROOT` gesetzt.

1. **Diff ohne Git:** `refs/tags/plan/M3c` → Commit 146008d → Tree 243e7845 (919 Dateien) aus losen Objekten und Packs; Blob-SHA-1 des Arbeitsbaums (mit und ohne CR) gegen die Basis; alte Blobs nach `.probe-r1/old/`, dann `diff -u`.
2. **Provenienz:** `digest()` über die 17 Quellen aus `SOURCES.json` und `session.txt`: alle gleich; vier Anker gleich ihren Originalen.
3. **Altverhalten:** Alte Funktionen aus den Blobs in eine Umgebung über dem Namespace geladen. 3000 Zufallsreihen mit und ohne `rules`-Teilmenge: Karte `identical()` bis auf `r4s`. `msa_plan()` auf 108 Plänen mit `nsim = 2`: 93 beide grün mit gleichen Werten (`all.equal`, Toleranz 1e-12), 15 beide rot.
4. **Replikate unabhängig:** Für S-plan-1 bis S-plan-4 je sechs Wiederholungen direkt mit `msa_simulate()` und `msa_fit()` aus dem Seed nachgerechnet: `estimate` und `prompt` auf zehn Stellen und `singular` gleich den gespeicherten Werten.
5. **Artefakte und Randfälle:** Vignette gestrickt; `msa_report()` mit Westgard- und Spannweiten-Karte; `plot()` als PNG gelesen; `print()`-Proben; QA-M3c-001 reproduziert; Bericht ohne `R_4s` in `rules`; `msa_plan()` mit genau 100 % Schätzungen und ohne Abbruch; Lesart über Zeilen-Subset bleibt erhalten (R 4.6.1 behält die Attribute).

Nicht gelaufen: volle Abnahme, `R CMD check`, Mutation (Gate-Fakten); keine Git-Kommandos.

## Gelesen

`AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/handoff/M3c/CRITERIA.json`, `PLAN.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `QA.md`, ADR-054, ADR-055, `orchestrator/state/M3c/gates.json`, `gate-*.log` (deps, lint, trace, territory, golden-adr, mutfull vollständig; tests und mutgate in Zusammenfassungen und Überlebenden), `reports/mutation/mutation.json`, `orchestrator/gates.d/86-mutgate.sh`, `docs/04-weitere-bausteine.md` (M3c), `reference/privat/07_Formelsammlung_llmsa.md` §8, §9, §12, ANK-86, ANK-89, der Diff seit `plan/M3c` (alle geänderten und neuen Dateien), `tests/testthat/test-control-chart.R`, `test-plan.R`, `test-report-control-chart.R`, `test-validation-planning.R`, `tests/acceptance/setup-m3c.R`, `test-m3c-2-r4s-reading.R`, `test-m3c-6-plan-replicates.R`, `test-m3c-6-vignette.R`, `tests/simulation/test-plan-satterthwaite.R`, die QA-Tests in den relevanten Teilen, `PROGRESS.md` M3c.
