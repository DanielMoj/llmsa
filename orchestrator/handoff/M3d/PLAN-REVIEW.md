# PLAN-REVIEW — M3d, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 06.11.2026 · Gegenstand: `orchestrator/handoff/M3d/PLAN.md` (Runde 1, 644 Zeilen). Es gibt keine `ARBITER.md` und kein `PLAN-UPDATE.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Kein blocking-Befund. Zehn minor-Befunde (E1 bis E10); E9 ist [QA-PENDING], E10 ist eine Aufgabe des Reviewers.

- **Der Plan** deckt die sechs Kriterien mit den Auslegungen ACC-2 bis ACC-14 ab. Die vier Punkte, die der Reviewer entscheiden muss, legt er mit Fundstellen vor (P-M3d-01 bis P-M3d-04, Z. 316–381). Der tragende Punkt P-M3d-01 stimmt: Die Seed-Provenienz, die K-M3d-6 verlangt, macht drei Abnahmetests aus M1d rot. Prüflauf 1 findet eine vierte Stelle im QA-Territorium (E9).
- **Entscheidungen**, bindend in ADR-053:
  - P-M3d-01: Die Sätze aus docs/02 M1d, K-M1d-8 und K-M1c-7 binden ihre Meilensteine. M3d ergänzt genau drei Seed-Attribute (docs/01 §4: „zusätzliche Attribute“ ohne ADR). Die drei M1d-Vergleiche führt der Reviewer auf ihren Gegenstand zurück (Nr. 14).
  - P-M3d-02: jsonlite als dokumentierte Voraussetzung der Fabrik, mit Präzisierung (Nr. 15, E7).
  - P-M3d-03: keine Umetikettierung, kein Volllauf (Nr. 16).
  - P-M3d-04: Infrastruktur, für den Builder nonblocking.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-053-m3d-reviewer-auslegungen.md`: hält ACC-1 bis ACC-14 fest, entscheidet P-M3d-01 bis P-M3d-03 und bindet E1 bis E8.
  - `CRITERIA.json`: Status von ACC-1 bis ACC-15 nachgeführt („festgehalten in ADR-053 Nr. n“), ACC-17 neu (erwartete rote Tests, [QA-PENDING]). Die sechs Kriterien sind unverändert.

### An den Betreiber

1. **Erwartet rot in Runde 1**, kein Befund gegen den Builder:
   - `test-m1d-7-findings.R` Z. 139–147 und `test-m1d-8-robustness-wording.R` Z. 83–99 und Z. 101–121, bis der Reviewer sie im Code-Review r1 nach ADR-053 Nr. 14.5 anpasst. Das tests-Gate ist damit in Runde 1 rot; eine zweite Runde bestätigt grüne Gates.
   - QA-M3b-E2E-3 (`tests/e2e/test-m3b-qa-e2e.R` Z. 214 und 231), bis QA den Test in der QA-Phase r1 anpasst (ADR-053 Nr. 14.6, ACC-17). Solange er rot ist, endet mutgate im roten Vorlauf ohne Score.
   - Passt QA r1 den Test nicht an, kann der Reviewer es nicht (QA-Territorium). Dann bleibt `orchestrator/state/M3d/qa-requested` oder ein Betreiber-Commit.
2. **Runde sparen (optional):** Mit `AUTONOMY_LEVEL=1` beginnt BUILD direkt nach dieser Phase. Wer ADR-053 Nr. 14.5 und 14.6 vor BUILD einspielen will, braucht einen Halt (`orchestrator/STOP` während dieser Phase) und einen Betreiber-Commit. Dann kann Runde 1 mit grünen Gates enden.
3. **AP1** (ADR-053 Nr. 19.2): Leere Antworten werden Fehlerzeilen (K-M3d-3). `acmg_pilot()` zählt sie im Anteil `backend_errors` und lässt ihre Token aus Kostenquantil und Anbieterprüfung (`R/acmg.R:509–560`). Ob AP1 nach M3d mit neuen Läufen weiterläuft und wie gemischte Stores ausgewertet werden, entscheidet der Betreiber.
4. **Mutationsumfang** (Nr. 19.1): Zu den M3d-Dateien kommen `R/grr.R` und `R/robustness.R` ganz hinzu, und die M3d-Abnahme läuft je Mutant (ACC-15). `orchestrator/state/mut-baseline` fehlt, wie BL-123 verlangt.

### Ablauf

Mit PASS committet der Orchestrator diese Phase, setzt den Tag `plan/M3d` und startet `40-build`. BUILD folgt `PLAN.md` und ADR-053; wo beide abweichen, gilt das ADR. Die Seed-Attribute werden in Runde 1 gebaut. Sonst sähe QA r1 die rote Erwartung nicht, und in Runde 2 gibt es keine QA-Phase mehr.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`; die Prompts `30-plan-review.md`, `40-build.md`, `45-qa.md`, `50-code-review.md`.
- **Orchestrator und Gates:**
  - `orchestrate.sh`: `AUTONOMY_LEVEL` Z. 38–57, `path_allowed` Z. 515–544, Planschleife Z. 946–978, Codeschleife Z. 999–1086;
  - `config.env` Z. 195–270;
  - `gates.d/30-tests.sh`, `86-mutgate.sh` Z. 1–25, `70-trace.sh` Z. 11–36, `lib/r-tests.R`.
- **Spezifikation:** docs/04 M3d (Ergebnissatz, K-M3d-1 bis K-M3d-6); docs/01 §1 bis §9; docs/02 Z. 71 (K-M1c-7), Z. 78 (M1d, Voraussetzung), Z. 90 und 92 (K-M1d-6, K-M1d-8); Formelsammlung §8, §11 und §12.
- **Handoff M3d:** `CRITERIA.json` (sechs Kriterien, ACC-1 bis ACC-16); `PLAN.md` vollständig.
- **ADRs:** ADR-051 vollständig, ADR-052 Z. 1–60.
- **Abnahmetests:**
  - vollständig: `setup-m3d.R`, `test-m3d-1` bis `test-m3d-6`, `test-m1d-8-robustness-wording.R`, `test-m1c-7-byte-equality.R`, `test-m1c-7-latent-note.R`, `test-m1c-8-check-runs.R`;
  - in Teilen: `test-m1d-7-findings.R` Z. 121–147, `setup-m1d.R` Z. 678–838, `setup-m1c.R` Z. 206–215 und 678–774, `setup-acceptance.R` Z. 1–40 und 78–91, `test-m2-3` Z. 110–131, `test-m2-6` Z. 1–40 und 100–135, `test-m2-7` Z. 130–235, `test-m3a-6` Z. 195–220, `test-m3b-6` Z. 1–95.
- **QA-Tests:** `tests/e2e/test-m3b-qa-e2e.R` Z. 100–130, 205–236, 262–276; `test-m1c-qa-e2e.R` Z. 36–60, 108–123; `test-m1d-qa-e2e.R` Z. 296–313; `test-m3a-qa-e2e.R` Z. 312–329; `tests/fuzz/test-m3b-qa-fuzz.R` Z. 90–104.
- **Produktcode und Bestand:**
  - vollständig: `R/backends.R`, `R/run.R`, `R/parse.R`, `R/report.R`, `R/robustness.R`, `inst/templates/validation_report.Rmd`, `DESCRIPTION`;
  - in Teilen: `R/grr.R` Z. 140–236; `R/spc.R` Z. 1–100; `R/acmg.R` Z. 230–231, 295–330, 455–590, 730–830, 880–905, 1039–1075; `inst/validation/sim/boot_coverage_helpers.R` Z. 225–284; `tests/testthat/test-parsers.R` Z. 25–60, `test-validation-bootstrap.R` Z. 300–330;
  - `BACKLOG.md`: alle IDs; im Wortlaut BL-60, BL-123, BL-127, BL-128, BL-130 bis BL-138;
  - Anker: ANK-34, ANK-93, ANK-94 (Dateien), ANK-TOL (`resume_cutpoints`, `parser_cases`, `arithmetic`);
  - Datensätze `data/ic50_demo` und `data/acmg_demo`: Spalten block, item_id, prompt_id, model_id, rep, value, reference; ohne `meta`, ohne Attribut `design`.
  - Aufrufer von `backend_mock()`, `parse_json_field()`, `msa_report()` und Vergleiche ganzer Objekte mit `identical()` per Suche über `R/`, `tests/`, `vignettes/` und `inst/`.

## Eigene Prüfläufe

Zwei R-Skripte (Prüflauf 1 und 3) unter `orchestrator/handoff/M3d/.probe-plan-review-r1/` und ein Einzeiler (Prüflauf 2), mit `Rscript --vanilla` aus der Repo-Wurzel; das Verzeichnis ist am Ende gelöscht. R 4.6.1, testthat 3.3.2. Produktcode und Tests im Arbeitsbaum sind unverändert.

1. **Seed-Attribute gegen den Bestand** (`seed-attrs.R`):
   - Paketkopie unter `tempdir()` (DESCRIPTION, NAMESPACE, `R/`, `inst/`, `data/`, `man/` und ausgewählte Testdateien), `REPO_ROOT` auf das Repository, `NOT_CRAN=true`, `load_package = "source"` wie `orchestrator/lib/r-tests.R`.
   - Variante seed mit einer Zusatzdatei `R/zzz-probe.R`, die `pb_design()`, `msa_robustness()` und `msa_boot()` die Attribute aus ADR-053 Nr. 14.2 gibt; Variante base ohne sie.
   - Auswahl ohne Git-Kommando: `tests/acceptance` test-m3b-\* und test-m1c-1/-2 (mit allen setup-Dateien); `tests/e2e` test-m1c-, test-m1d- und test-m3b-qa-e2e.R; `tests/fuzz/test-m3b-qa-fuzz.R`; `tests/testthat` test-robustness\*, test-boot\*, test-report.R (mit helper- und setup-Dateien).
   - Ausgabe:

     ```text
     variant: base  R 4.6.1  testthat 3.3.2
     tests/acceptance: 40 test blocks, 0 with failures, 0 with errors, 0 skipped, 16 s
     tests/e2e: 11 test blocks, 0 with failures, 0 with errors, 0 skipped, 23 s
     tests/fuzz: 2 test blocks, 0 with failures, 0 with errors, 0 skipped, 1 s
     tests/testthat: 32 test blocks, 0 with failures, 0 with errors, 0 skipped, 4 s

     variant: seed  R 4.6.1  testthat 3.3.2
     tests/acceptance: 40 test blocks, 0 with failures, 0 with errors, 0 skipped, 16 s
     tests/e2e: 11 test blocks, 1 with failures, 0 with errors, 0 skipped, 23 s
       RED test-m3b-qa-e2e.R | QA-M3b-E2E-3: logit transform, help-page wording and msa_report integration work end-to-end without altering transform = 'none' (seed = 20261105) | failed=2 error=FALSE
         test-m3b-qa-e2e.R:214 Expected `sort(names(attributes(rob_default)))` to be identical to `sort(...)`. Differences: `actual[7:11]`: "response_mean" "response_sd" "row.names" "seed" "sme" `expected[7:10]`: "response_mean" "response_sd" "row.names" "sme"
         test-m3b-qa-e2e.R:231 Expected `rob_sub_pb` to be identical to `rob_sub_df`. Differences: `attr(actual, 'seed')` is an integer vector (20261105) `attr(expected, 'seed')` is absent
     tests/fuzz: 2 test blocks, 0 with failures, 0 with errors, 0 skipped, 1 s
     tests/testthat: 32 test blocks, 0 with failures, 0 with errors, 0 skipped, 5 s
     ```

   - Nicht gelaufen, weil sie über `acc_git()` Git-Kommandos ausführen: test-m1d-7, test-m1d-8, test-m1c-7-byte-equality. Ihr Befund ist aus dem Code gelesen (ADR-053, Kontext).
   - Die Zusatzdatei wickelt die Funktionen ein. Sie ist keine Vorlage für BUILD: Nr. 14.3 und 14.4 verlangen die Zuweisungen in den Funktionen selbst.
2. **Backlog-Abdeckung** (Einzeiler in R): 138 IDs in `BACKLOG.md` (BL-1 bis BL-138), 138 Zeilen in der Tabelle des Plans (Z. 401–540), jede genau einmal; keine fehlt, keine ist zusätzlich.
3. **CRITERIA.json** (`criteria-edit.R`):
   - Vor der Änderung gab `jsonlite::toJSON(pretty = TRUE, auto_unbox = TRUE)` mit abschließendem LF die Datei byte-gleich wieder (31271 Byte).
   - Danach: gültiges JSON, sechs Kriterien unverändert, 17 offene Einträge, 33316 Byte.

## Antworten auf die Punkte des Plans

- **P-M3d-01 — entschieden** (ADR-053 Nr. 14).
  - Der Befund des Plans stimmt:
    - `test-m1d-7-findings.R` (Block ab Z. 139, im Plan als Z. 138 zitiert) vergleicht die Codezeilen von `R/grr.R` im Arbeitsbaum mit done/M1c; jede Codezeile für das Seed-Attribut macht ihn rot.
    - `test-m1d-8-robustness-wording.R` Z. 83–99 rechnet auf `pb_design(11, n_runs = 12, seed = 20261103L)` (`setup-m1d.R:731`). Z. 101–121 rechnet über `acmg_pb()` mit `seed = plan$design$seed` (`R/acmg.R:231`). Beide vergleichen mit `identical()` gegen done/M1c.
  - Kein Spec-Widerspruch: Die Sätze aus docs/02 binden ihren Meilenstein („M1d ändert …“, Kriterien K-M1d-8 und K-M1c-7). docs/01 §4 erlaubt zusätzliche Attribute ohne ADR, und K-M3d-6 verlangt die Seeds im Bericht. Ohne Attribut gelangt der Bootstrap-Seed nicht in den Bericht: `msa_report()` erhält in der Abnahme nur die Objekte (`setup-m3d.R:642–646`), und `msa_boot()` (`R/grr.R:193–218`) speichert den Seed bisher nicht.
  - Der Vorschlag des Plans ist übernommen: Die M1d-Regel wird am Stand done/M1d geprüft. Die Objekte werden ohne das neue Attribut verglichen, das Attribut getrennt. Dazu legt ADR-053 fest:
    - die Werte der drei Attribute (Nr. 14.2);
    - den Umfang der Codeänderung in `R/grr.R`, `R/fit.R` und `R/robustness.R` (Nr. 14.3);
    - die Form der drei Testanpassungen (Nr. 14.5);
    - die QA-Stelle, die der Plan nicht nennt (Nr. 14.6; E9).
  - Die Teständerungen macht der Reviewer; `30-plan-review` darf `tests/acceptance/` nicht schreiben (`orchestrate.sh:520`), `50-code-review` darf es (Z. 522; E10).
- **P-M3d-02 — bestätigt**, präzisiert in ADR-053 Nr. 15 (E7).
  - So enden schon jetzt `backend_ellmer()`, `backend_openai_compatible()` (httr2), `append_store()` (DBI, RSQLite) und `msa_report()` (rmarkdown, knitr) benannt, wenn ihr Suggests-Paket fehlt.
  - docs/01 §2 Nr. 4 verlangt „eine richtige Zahl oder eine klare Fehlermeldung“. Der bisherige Weg mit regulären Ausdrücken gibt nach ACC-6 auf 2536 von 10.000 Eingaben ein falsches Ergebnis.
- **P-M3d-03 — bestätigt** (ADR-053 Nr. 16).
  - `boot_implementation()` (`inst/validation/sim/boot_coverage_helpers.R:242–255`) hasht den Körper von `msa_boot()`. Kein Test vergleicht den Hash der boot_coverage-Sitzung mit einem Neulauf: K-M1c-8 prüft nur die drei Studien mit `msa_fit` (`test-m1c-8-check-runs.R:15`).
  - Die Reproduktion der Einzelschätzer (K-M1c-4, K-M1d-6) ändert das Seed-Attribut nicht.
- **P-M3d-04 — nonblocking**, bei Bedarf [INFRA].
  - `httr2::req_dry_run()` steht in `setup-m3d.R:385`. Die Probe ACC-16 lief im Umfeld des Reviewers grün.
  - Ein Socket-Fehler im Sandkasten des Builders ist Infrastruktur (BL-86) und wird mit Befehl und Output dokumentiert, wie der Plan vorsieht (Z. 372–375).

## Einwände (Runde 1)

- [E1] (minor) K-M1c-7 (`setup-m1c.R:682–689`, `:694–697`); K-M3a-6 (`test-m3a-6-linearity.R:208`); K-M1d-8 (`setup-m1d.R:809`); ACC-10; QA-M1c-E2E-2 (`tests/e2e/test-m1c-qa-e2e.R:120–122`); PLAN.md Z. 207–209 („Die bestehenden Überschriften zweiter Ebene und erkannten Text-/Tabellenformen … bleiben nutzbar. Neue Erläuterungen stehen auf eigenen Zeilen.“) — **Befund:** Der Plan nennt nicht, wie ältere Tests den Bericht lesen. Neue Zeilen im Abschnitt Precision (ndc-Konstante, abgeleitete Komponenten, Konventionen) können diese Tests leicht rot machen.
  1. Die Tests finden die Abschnitte 3, 5 und 6 über ihre Nummer.
  2. Sie schneiden einen Abschnitt an der nächsten Überschrift jeder Ebene ab.
  3. K-M1c-7 verlangt in Abschnitt 3 genau eine Zeile, die repeatability und reproducibility zusammen nennt. QA-M1c-E2E-2 verlangt den Hinweis aus K-M1c-7 unmittelbar in der nächsten Zeile.
  4. K-M1c-3, K-M1d-7 und K-M3b-5 lesen Sätze aus `man/msa_boot.Rd` und `man/msa_robustness.Rd`, die der Plan neu erzeugt.

  — **Vorschlag:** ADR-053 Nr. 17 (bindend):
  - Nummern und Titel der Abschnitte 1 bis 6 bleiben; neue Abschnitte stehen hinter Abschnitt 6.
  - In den Abschnitten 3, 5 und 6 kommen keine neuen Überschriften hinzu.
  - Neue Zeilen in Abschnitt 3 stehen hinter den bestehenden Listenzeilen und nennen nicht beide Wörter.
  - Die Texte, die die QA-Tests lesen, bleiben.
  - In den Hilfeseiten kommt nur Text hinzu.
- [E2] (minor) K-M3d-1; ACC-2; ADR-015; `R/acmg.R:802–803` („Not an error: msa_run() would store an error as a row.“); PLAN.md Z. 132–135 — **Befund:** Der Plan regelt nur `interrupt`. Die AP1-Netzwache beendet `msa_run()` mit einer Bedingung der Klasse `acmg_network_abort`, die kein `error` ist, damit keine Zeile entsteht. Ein breiterer Fang (`tryCatch(condition = )`, `withCallingHandlers` mit Umdeutung) würde dort eine Zeile speichern. — **Vorschlag:** ADR-053 Nr. 18.1: Nur Bedingungen der Klasse `error` werden Fehlerzeilen; jede andere verlässt `msa_run()` unverändert. Ein Unit-Test mit einer Bedingung, die kein `error` ist; `test-acmg-network.R` bleibt grün.
- [E3] (minor) K-M3d-3; ACC-8; ADR-014; `R/acmg.R:509–560`; PLAN.md Z. 136–148 — **Befund:**
  1. „fehlender, `NA`- oder leerer Antworttext“ (Z. 136–137) lässt offen, ob `NULL` und Länge 0 dazu zählen, ob `meta` bleibt und ob der Parser läuft.
  2. Die Folge für AP1 ist nicht benannt. `acmg_pilot()` zählt Fehlerzeilen im Anteil `backend_errors` (Z. 553–557), nimmt `meta` und Token nur von Zeilen ohne Fehler (Z. 509–513) und wertet so auch den Wiederholungstag (ADR-014). Eine leere Antwort zählt nach M3d dort als Backendfehler, vorher als nicht parsbar.

  — **Vorschlag:**
  - ADR-053 Nr. 18.2: Leer sind `NULL`, Länge 0, `NA` und `""`. Die Fehlermeldung nennt die Art, `meta` bleibt, der Parser wirkt nicht.
  - Der Builder benennt die AP1-Folge in PROGRESS. Die AP1-Regeln ändern sich nicht; über Fortsetzung und gemischte Stores entscheidet der Betreiber (Nr. 19.2).
- [E4] (minor) K-M3d-1; ACC-3; docs/01 §2 Nr. 4; `R/run.R:153`; PLAN.md Z. 114–119 — **Befund:** Der Plan liest `item_id`, `prompt_id`, `model_id` und `value` als Text. „Weitere textuelle Speicherfelder behalten ihren Inhalt“ sagt nicht, wie. `read.csv()` rät weiter: Eine Antwort „0.810“ wird 0.81, `error` und `meta` nur aus `NA` werden logisch, eine Modellbezeichnung oder ein Hash kann als Zahl gelesen werden. — **Vorschlag:** ADR-053 Nr. 18.3: `colClasses` für alle Spalten; `block`, `position` und `rep` integer, `latency_s` double, alles andere Text, auch unbekannte Spalten.
- [E5] (minor) K-M3d-1; ACC-2, ACC-3; `R/backends.R:89`, `:105–108`; PLAN.md Z. 120–131 — **Befund:** Der Schlüssel der Prompt- und Modelleffekte ist `sum(utf8ToInt(key)) * 7919 + seed` (Z. 89). Er hängt nicht von der Reihenfolge der Zeichen ab; „001“ und „010“ haben dieselbe Summe. Ein Zeilenstrom, der so gebildet würde, gäbe beiden Items dieselbe Replikatstreuung. Außerdem ändern sich mit der neuen Ziehung die Mock-Werte für denselben Seed. — **Vorschlag:** ADR-053 Nr. 18.4:
  - eine stellenabhängige Mischung über längenmarkierte UTF-8-Teile, wie Z. 122–124 andeuten;
  - ein Unit-Test mit zwei Zeilen gleicher Zeichensumme;
  - Tests mit festen Mock-Werten erhalten ihre Erwartung aus der dokumentierten Regel, nicht aus der neuen Ausgabe;
  - die Prompt- und Modelleffekte (Z. 89) bleiben, wie der Plan vorsieht (Z. 126).
- [E6] (minor) K-M3d-6; ACC-13, ACC-14; `setup-m3d.R:759–766` (`acc_m3d_integers()`, `acc_m3d_has_number()`); `test-m3d-6-report-conventions.R:98–116` — **Befund:** Der Plan legt die Druckformen nicht fest. Die Tests nehmen die erste ganze Zahl hinter der Bezeichnung und suchen alleinstehende Zahlen. „1.0 %“, „1,41“, „271,828“, „1e+06“ oder „Bootstrap (4 replicates) seed …“ fallen durch. — **Vorschlag:** ADR-053 Nr. 18.5:
  - Seeds als ganze Zahl ohne Exponent und Tausendertrenner, die Bezeichnung unmittelbar davor;
  - Schwellen und Konstanten mit `format()` bzw. `%g` wie in der Zeile „Classification“: 1.41, 10, 30, 1, 9.
- [E7] (minor) K-M3d-2 („liefern … nie einen Fehler“); ACC-6; PLAN.md Z. 162–177 (P-M3d-02) — **Befund:**
  1. `jsonlite::fromJSON()` liest eine Zeichenkette, die kein gültiges JSON ist, als URL oder als vorhandene Datei. Ein ausgeschnittenes `{x}` würde so eine Datei dieses Namens im Arbeitsverzeichnis lesen.
  2. Warnungen von jsonlite und die Länge des Ergebnisses für Werte außerhalb des Vertrags (Felder, Objekte, `null`) sind offen.

  — **Vorschlag:** ADR-053 Nr. 15: `jsonlite::parse_json(simplifyVector = FALSE)`. Fehler und Warnungen ergeben `NA`. Das Ergebnis ist immer eine Zeichenkette der Länge eins oder `NA_character_`.
- [E8] (minor) K-M3d-5, K-M3d-6; ACC-12, ACC-14; docs/01 §2 Nr. 4; `R/run.R:125–126`; `tests/e2e/test-m3a-qa-e2e.R:317`; PLAN.md Z. 237–247 — **Befund:** Die neuen Teile des Berichts treffen auf Lauftabellen ohne Spalte `meta`. Beispiele sind `ic50_demo` (QA-M3a-E2E rendert damit einen Bericht) und die 48-Zeilen-Tabelle aus K-M3d-5. Andere Lauftabellen haben kein Attribut `design` oder ein `meta`, das kein JSON ist: Ohne jsonlite schreibt `meta_to_json()` „name=value;…“. Der Plan nennt nur „unlesbare Metadaten“ (Z. 244). Offen ist auch, wo die neuen Werte berechnet werden. — **Vorschlag:** ADR-053 Nr. 18.6:
  - Der Bericht rendert in allen diesen Fällen, mit „not reported“ bzw. benannten unlesbaren Metadaten und mit Datenhash.
  - Hash, Seeds, Modelltabelle und Westgard-Tabelle werden in `R/` berechnet und als im YAML-Kopf erklärte Parameter übergeben; die Vorlage formatiert nur.
- [E9] (minor) [QA-PENDING] ADR-053 Nr. 14.6; Prüflauf 1; `tests/e2e/test-m3b-qa-e2e.R:214`, `:231`; `config.env:242` (`MUT_TEST_DIRS`) — **Befund:** QA-M3b-E2E-3 legt die Attributnamen eines `msa_robustness()`-Objekts auf einem PB-Plan mit Seed fest (Z. 214–217) und vergleicht es mit `identical()` mit dem Ergebnis auf einem einfachen data.frame (Z. 231). Mit dem Seed-Attribut ist der Block rot, ohne dass ein Wert falsch ist. Ein roter unmutierter Vorlauf bricht mutgate vor dem ersten Mutanten ab. — **Vorschlag:**
  - QA passt die zwei Erwartungen in der QA-Phase M3d an: `seed` in der Namensmenge; Vergleich ohne `seed`, `seed` getrennt geprüft (ACC-17).
  - Der Builder ändert den Test nicht und nennt ihn in PROGRESS als erwartet rot.
  - Rückfall beim Betreiber (siehe oben).
- [E10] (minor) Aufgabe des Reviewers, kein Builder-Auftrag. ADR-053 Nr. 14.5; `tests/acceptance/test-m1d-7-findings.R:139–147`; `test-m1d-8-robustness-wording.R:83–99`, `:101–121`; docs/02, M1d, Voraussetzung; K-M1d-8 — **Befund:** Die drei Tests prüfen den Arbeitsbaum gegen done/M1c und werden mit der Seed-Provenienz rot. `30-plan-review` darf `tests/acceptance/` nicht schreiben (`orchestrate.sh:520`). — **Vorschlag:** Der Reviewer passt sie im Code-Review M3d, Runde 1, nach Nr. 14.5 an (`orchestrate.sh:522`), oder der Betreiber vorher. Bis dahin sind sie rot, ohne Befund gegen den Builder.

## Prüfung nach Gesichtspunkten

- **Spec-Treue:**
  - K-M3d-1: CSV-Leser mit Text-IDs, zeilenbezogener Mock-Strom ohne Aufrufzähler, Abbruch ohne Zeile, Fortsetzen überspringt jeden gespeicherten Schlüssel (Z. 114–135), wie ACC-2 und ACC-3. Präzisiert: E2, E4, E5.
  - K-M3d-2: U+2212 vor der bestehenden Erkennung; erstes Objekt mit Zustand für Zeichenketten und Escapes, dekodiert mit jsonlite, Feldzugriff nur auf der obersten Ebene; `parse_choice()` unverändert (Z. 152–177). Präzisiert: E7.
  - K-M3d-3:
    - Text und `meta` von ellmer aus `ch$last_turn()@json`, nichts erfunden (Z. 181–189);
    - leere Antworten im gemeinsamen Runner (Z. 136–142, 193);
    - die Hilfeseite nennt die bestehende Meldung wörtlich (Z. 193–195);
    - Präzisiert: E3.
  - K-M3d-4:
    - Stellen aus ANK-93 (Z. 212–219);
    - fehlendes ndc nicht als Inf: Die Vorlage druckt `NA` heute als „Inf“ (`validation_report.Rmd:94`), Z. 218–219 behebt das;
    - Westgard-Tabelle mit jeder Regel und reject (Z. 220–224).
  - K-M3d-5: Kanonische Form wie ACC-12, `digest(serialize = FALSE)`, die MD5-Zeile entfällt (`validation_report.Rmd:233`; Z. 256–282).
  - K-M3d-6:
    - 1.41; Basis und Schwellen in der bestehenden Zeile „Classification“ (`validation_report.Rmd:95–96`);
    - Konvention, abgeleitete Komponenten, Modell, R_4s;
    - Seeds aus den Objekten, Modelltabelle mit allen beobachteten Werten und exaktem Feldzugriff (Z. 225–247);
    - Präzisiert: E6, E8; Weg der Seeds: P-M3d-01.
- **Architektur:**
  - Arbeit in `R/run.R`, `R/backends.R`, `R/parse.R`, `R/report.R` und der neuen internen Datei `R/report-data.R`, in `R/grr.R` und `R/robustness.R` nur die Seed-Zuweisungen.
  - `R/fit.R`, `R/agreement.R`, `R/spc.R` und `R/acmg.R` bleiben unberührt; keine neuen Importe oder Exporte.
  - Die Berechnung liegt in `R/`, die Vorlage formatiert (E8).
- **Verträge:**
  - Nur zulässige Ergänzungen nach docs/01 §4: ein letztes Argument `control_chart = NULL`, zusätzliche Attribute, geänderte Druck- und Berichtsausgabe. ANK-02 bleibt; die Obermengenprüfung trägt das neue Argument.
  - Von der Spec verlangt: Leere Antworten werden Fehlerzeilen (K-M3d-3), kaputtes JSON wird `NA` (K-M3d-2).
  - Festgelegt in ADR-053:
    - jsonlite ist Voraussetzung der Fabrik (Nr. 15);
    - die Mock-Werte ändern sich für denselben Seed (Nr. 18.4); `data/` hängt nicht von `backend_mock()` ab, kein `data-raw/`-Skript ruft es;
    - die Seed-Attribute ändern die drei M1d-Vergleiche (Nr. 14).
- **Vollständigkeit:**
  - Dateien, Reihenfolge und Testplan decken alle sechs Kriterien.
  - Alle 138 Backlog-Einträge sind zugeordnet (Prüflauf 2). Gegen den Text geprüft: BL-60 (beantwortet), BL-123 (Baseline fehlt), BL-128 (in M3d), BL-130 (vertagt nach ACC-15), BL-137 und BL-138 (Betreiber).
- **Risiken:**
  - Die Liste des Plans (Z. 383–392) trifft die Klassen.
  - Hinzu kommen:
    - die QA-Stelle (E9);
    - die Struktur des Berichts (E1);
    - die Folge für AP1 (E3);
    - die Mutation ganzer Dateien `R/grr.R` und `R/robustness.R` (ADR-053 Nr. 19.1).
- **Gate-Abdeckung:**

  | Kriterium | Prüfweg | Gates |
  | --- | --- | --- |
  | K-M3d-1 | `tests/acceptance/test-m3d-1-resume.R` | tests; mutgate je Mutant |
  | K-M3d-2 | `tests/acceptance/test-m3d-2-parsers.R` | tests; mutgate je Mutant |
  | K-M3d-3 | `tests/acceptance/test-m3d-3-backends.R` | tests; mutgate je Mutant; deps (ellmer, httr2, jsonlite, DBI, RSQLite, pkgload) |
  | K-M3d-4 | `tests/acceptance/test-m3d-4-report-numbers.R` | tests; mutgate je Mutant; lint (`R CMD check`) |
  | K-M3d-5 | `tests/acceptance/test-m3d-5-data-hash.R` | tests; mutgate je Mutant; deps (digest) |
  | K-M3d-6 | `tests/acceptance/test-m3d-6-report-conventions.R` | tests; mutgate je Mutant |
  | alle | Kriteriums-IDs in `tests/acceptance` | trace |
  | Bestand | M0- bis M3b-Abnahme, QA- und Unit-Tests | tests; mutgate (ohne `MUT_TEST_EXCLUDE`) |
  | Anker, Golden-Daten | keine Änderung nach `plan/M3d` | golden-adr |
  | Pfade | Dateiliste des Plans | territory |

## Hinweise für BUILD

- **Vertrag:** `PLAN.md` und ADR-053 Nr. 1 bis 18; bei Abweichung gilt das ADR. Das Code-Review prüft gegen Nr. 1 bis 18.
- **Seeds in Runde 1** (Nr. 14.2 bis 14.4): genau drei Attribute; in `R/grr.R` nur die Zuweisung in `msa_boot()`. Unit-Tests vergleichen die übrigen Teile mit `identical()` gegen den Stand vor M3d und prüfen `seed` getrennt.
- **Erwartet rot** (ACC-17): test-m1d-7 Z. 139–147, test-m1d-8 Z. 83–121, QA-M3b-E2E-3. Nicht anfassen und nicht umgehen; in PROGRESS als erwartet benennen, mit dem Output der lokalen Läufe von `tests/e2e`.
- **Bericht** nach Nr. 17 und 18.5/18.6. Gerenderte Prüfung als GitHub-Markdown wie die Abnahme, dazu die Sätze, die die QA-Tests lesen.
- **Hilfeseiten** nur aus roxygen in einer Paketkopie erzeugen. Übernommen werden nur die betroffenen Rd-Dateien; die von K-M1c-3, K-M1d-7, K-M3b-5 und K-M3d-3 gelesenen Sätze bleiben.
- **AP1:** Folge der leeren Antworten in PROGRESS benennen (E3); keine AP1-Regel ändern.
- **Prüfumfang** laut Testplan (Z. 563–634), mit `REPO_ROOT`, `NOT_CRAN=true` und `options(testthat.progress.max_fails = Inf)`.
