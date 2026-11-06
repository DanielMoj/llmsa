# QA — M3d (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M3d` · Stand: 06.11.2026 · Fester, geloggter Seed aller neuen QA-Tests: `20261106` (`set.seed(20261106L)`)

---

## 1. Geprüfter Umfang und Kontextmanifest

Geprüft wurden gegen `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/M3d/CRITERIA.json`, `docs/01-fachspezifikation.md`, `docs/04-weitere-bausteine.md` (`K-M3d-1` bis `K-M3d-6`), `docs/decisions/ADR-053-m3d-reviewer-auslegungen.md` (Nr. 1 bis 18), `orchestrator/handoff/M3d/PLAN.md`, `orchestrator/handoff/M3d/PLAN-REVIEW.md` (Befunde `E1` bis `E10`), `PROGRESS.md` sowie `orchestrator/state/M3d/gates.json` und `orchestrator/state/M3d/gate-*.log`:

- **Wiederaufnahme und Audit-Store (`K-M3d-1`, `R/run.R`, `R/backends.R`):**
  - Zeilenweiser,reihenfolgeunabhängiger Stream-Seed in `backend_mock()` über `(block, item_id, prompt_id, model_id, rep)` (`row_seed()`) und vollständige Wiederherstellung von `.Random.seed` (auch wenn `.Random.seed` vor dem Aufruf `NULL` war).
  - Typfester CSV-Store-Reader in `read_store()` (`block`, `position`, `rep` als `integer`; `latency_s` als `numeric`; alle übrigen Spalten einschließlich `item_id`, `prompt_id`, `model_id`, `model`, `prompt_hash`, `timestamp`, `response`, `value`, `error`, `meta` als `character`, sodass führende Nullen wie `"001"`/`"010"` und Dezimaldarstellungen erhalten bleiben).
  - Mehrstufige Unterbrechungen (`interrupt` und benutzerdefinierte Bedingungen wie `acmg_network_abort`) und Fortsetzung mit `resume = TRUE` für CSV und SQLite; bereits gespeicherte Fehler- und `NA`-Zeilen werden nicht erneut aufgerufen.
- **Parser-Eigenschaften (`K-M3d-2`, `R/parse.R`, `man/parsers.Rd`):**
  - `parse_number()`: Unterstützung des Unicode-Minuszeichens `U+2212` (`−`) neben ASCII `-`/`+`, Dezimalpunkt und Dezimalkomma, führendem Dezimalzeichen (`.25`, `,25`), Exponenten (`e`/`E`) sowie Einheiten und Bezeichnern mit angeklebten Ziffern (`IC50`, `EC50`, `pIC50`, `CYP3A4`, `H2O`, `mg/m3`, `m2`).
  - `parse_choice()`: Eingabeprüfung für `whole_word` (`TRUE` oder `FALSE`, sonst sauberer `stop(..., call. = FALSE)`), Groß-/Kleinschreibung, Aliase, Teilwort- und Ganzwortmodus sowie `NA` bei widersprüchlichen Klassen im Ganzwortmodus.
  - `parse_json_field()`: Vorabprüfung auf `jsonlite` mit dem in `man/parsers.Rd` dokumentierten Wortlaut (`ADR-053` Nr. 15.1), zustandsbasierter Klammer-Scanner für das erste vollständige JSON-Objekt `{ ... }` unter Beachtung von Strings und Escapes, sicheres Parsen über `jsonlite::parse_json(json, simplifyVector = FALSE)` ohne Dateipfad-/URL-Deutung, exakter Top-Level-Zugriff `object[[field, exact = TRUE]]` nur für Länge-1-Strings oder -Zahlen sowie vollständige Unterdrückung von Warnungen und Fehlern zu `NA_character_`.
- **Backends und leere Modellantworten (`K-M3d-3`, `R/backends.R`, `R/run.R`, `man/backends.Rd`):**
  - `backend_openai_compatible()`: Aufzeichnung von `meta$usage` aus `parsed$usage` und verlustfreie JSON-Serialisierung verschachtelter `meta`-Listen in `meta_to_json()` (`digits = NA`).
  - `backend_ellmer()`: Vorabprüfung auf `ellmer` mit dem in `man/backends.Rd` dokumentierten Wortlaut (`ADR-053` Nr. 7), Unterstützung eines einzelnen `Chat`-Objekts oder einer nach `row$model_id` bzw. `model` benannten Liste, Turn-Isolation über `chat$clone()` und Extraktion von `model_snapshot`, `provider` und `usage` aus `ch$last_turn()@json`.
  - Leere Modellantworten (`NULL`, `character(0)`, `NA`, `""`) in `msa_run()` werden vor dem Parser als Backend-Fehler (`error` nicht leer, `value = NA`) bei vollständig erhaltenem `meta` erfasst; Antworten nur aus Leerraum (`" 	"`) gelten nicht als leere Antwort (`error = NA`), sondern gehen an den Parser (`ADR-053` Nr. 6.4).
- **Berichtstreue, kanonischer SHA-256-Daten-Hash und Provenienz (`K-M3d-4`, `K-M3d-5`, `K-M3d-6`, `R/report-data.R`, `R/report.R`, `R/grr.R`, `R/robustness.R`, `inst/templates/validation_report.Rmd`, `man/msa_report.Rd`):**
  - Neues letztes Formulargument `control_chart = NULL` in `msa_report()` mit S3-Klassenprüfung auf `"msa_spc"` und tabellarischer Darstellung (`Rule | Violations | Positions`) sowie `R_4s`-Konventionssatz im Abschnitt 7.
  - Bytegenaue kanonische CSV-Form `msa_report_canonical()` und `msa_report_hash()` (SHA-256 über `digest::digest(..., algo = "sha256", serialize = FALSE)`, Spalten `block, item_id, prompt_id, model_id, rep` gefolgt von den übrigen Spalten in Radix-Byteordnung, IEEE-754-Zahlen über `%.17g` mit Dezimalpunkt, Text in doppelten Anführungszeichen mit `""`-Verdopplung, `NA` ungequotet, Zeilensortierung nach den fünf Schlüsseln und der Gesamtzeile als Tie-Breaker).
  - Seed-Provenienz (`attr(..., "seed")`) auf `msa_boot()` und `msa_robustness()` (sowie bestehend auf `msa_design()` und `pb_design()`) ohne Veränderung von `.Random.seed` bei `seed = NULL`, ausgegeben als `Design seed`, `Bootstrap seed` und `Plackett-Burman seed`.
  - Modelltabelle `Model ID | Model | Provider | Quantization` in `msa_report_models()` ausschließlich aus `meta$model_snapshot`, `meta$provider` (ohne Rückgriff auf `provider_order`) und `meta$quantizations` sowie Hinweiszeilen bei unlesbarem `meta`.
  - Konventionsangaben im Bericht (`ndc`-Konstante `1.41`, Verdict-Schwellen `10 / 30` mit Basis, `%Contribution`-Schwellen `1 % and 9 %` als Konvention, abgeleitete Zwei-Stufen-Komponenten, Modell ohne Block- und Dreifach-Wechselwirkungen).

---

## 2. Erledigte `[QA-PENDING]`-Aufträge aus `ADR-053` und `BACKLOG.md`

1. **`ADR-053` Nr. 14.6 (`[QA-PENDING]` in `tests/e2e/test-m3b-qa-e2e.R`, `QA-M3b-E2E-3`):**
   - **Ursache im Vorlauf:** Seit `M3d` trägt das Rückgabeobjekt von `msa_robustness(d, ...)` für ein aus `pb_design(..., seed = 20261105L)` stammendes Design vereinbarungsgemäß `attr(rob, "seed") = 20261105L`, während `msa_robustness(df_plain, ...)` für ein einfaches `data.frame` kein `seed`-Attribut trägt. Dadurch schlugen in `orchestrator/state/M3d/gate-tests.log` (Z. 2542–2554) und im unmutierten Vorlauf von `gate-mutgate.log` die beiden Prüfungen in `tests/e2e/test-m3b-qa-e2e.R` (Z. 214 und Z. 231) fehl.
   - **Umsetzung in QA M3d:** In `tests/e2e/test-m3b-qa-e2e.R` (`QA-M3b-E2E-3`) wird gemäß `ADR-053` Nr. 14.6 `attr(rob_default, "seed", exact = TRUE) == 20261105L` geprüft, `"seed"` in die erwartete Attributnamensmenge aufgenommen und beim Vergleich zwischen `rob_sub_pb` (aus `pb_design`) und `rob_sub_df` (aus einfachem `data.frame`) das `seed`-Attribut getrennt geprüft (`expect_identical(attr(rob_sub_pb, "seed", exact = TRUE), 20261105L)`, `expect_null(attr(rob_sub_df, "seed", exact = TRUE))`, `expect_identical(structure(rob_sub_pb, seed = NULL), rob_sub_df)`).
2. **`BL-135` (`[QA-PENDING]` Entfernung von `tests/e2e/testthat-problems.rds`):**
   - Die aus `M3a` stammende Datei `tests/e2e/testthat-problems.rds` wurde entfernt; nach Ausführung aller Suiten unter `tests/e2e/` und `tests/fuzz/` liegen im gesamten `tests/`-Baum keine `testthat-problems.rds`-Artefakte vor.

*(Hinweis zu den in `gate-tests.log` Z. 1781–1863 verbleibenden 3 Stellen in `tests/acceptance/test-m1d-7-findings.R` und `tests/acceptance/test-m1d-8-robustness-wording.R`: Diese sind in `ADR-053` Nr. 14.5 ausdrücklich als `[OUT-OF-TERRITORY]` dokumentiert und für QA wie Builder gesperrt.)*

---

## 3. Neue QA-Testsuiten (`tests/e2e/` und `tests/fuzz/`)

1. **`tests/e2e/test-m3d-qa-e2e.R` (3 `test_that`-Blöcke, 91 `expect_*`-Prüfungen, Seed `20261106`):**
   - `QA-M3d-E2E-1`: Mehrstufige Unterbrechungen (`interrupt` nach 7 Aufrufen, `acmg_network_abort` nach weiteren 11 Aufrufen, anschließend Abschlusslauf) mit jeweils neu erzeugtem `backend_mock(..., seed = 20261106L)` über CSV- und SQLite-Stores (`K-M3d-1`). Prüft die exakte Übereinstimmung des fortgesetzten Stores und Rückgabeobjekts mit dem ununterbrochenen Referenzlauf (ohne `timestamp` und `latency_s`), den Erhalt führender Nullen (`"001"`, `"010"`, `"01"`, `"02"`, `"01.00"`, `"02.00"`) im CSV-Store sowie, dass ein erneuter Aufruf mit `resume = TRUE` auf vollständigem Store weder Backend noch Parser aufruft.
   - `QA-M3d-E2E-2`: Replay der drei aufgezeichneten Antworten aus `ANK-94` (`sol.json`, `llama.json`, `qwen.json`) über `backend_openai_compatible()` und `backend_ellmer()` mit Turn-Isolation (`length(chat$get_turns()) == 0L`), vollständiger `meta$usage`-Rundreise über `meta_to_json()` sowie gemischter Fehlerinjektion (`http_500`, `http_401`, `timeout`, `empty_body`, `null_content`, `empty_content`, `ws_content`) in `msa_run()` (`K-M3d-3`). Prüft, dass der benutzerdefinierte Parser ausschließlich für `ok_first`, `ws_content` (nur Leerraum, kein leerer Antwortfehler gemäß `ADR-053` Nr. 6.4) und `ok_last` aufgerufen wird, während alle 6 Transport- und Leer-Antwort-Fehler einen nicht-leeren `error`-Eintrag und `value = NA` erzeugen.
   - `QA-M3d-E2E-3`: End-to-End-Validierungsbericht (`msa_report()`) in GitHub-Markdown (`md_document(variant = "gfm", pandoc_args = "--wrap=none")`) und HTML (`html_document()`) über eine vollständige Studie (`msa_design` -> `msa_run` -> `msa_fit` -> `msa_grr` -> `msa_boot` -> `msa_bias` -> `pb_design` -> `msa_robustness` -> `msa_control_chart`) (`K-M3d-4`, `K-M3d-5`, `K-M3d-6`). Prüft den kanonischen SHA-256-Daten-Hash, das Fehlen von `MD5`, alle drei Seeds (`Design seed: 314159`, `Bootstrap seed: 271828`, `Plackett-Burman seed: 161803`), die Konventionssätze (`1.41`, `1 % and 9 %`, Ausschluss von Block- und Dreifach-Wechselwirkungen, `R_4s`), die Westgard-Tabelle sowie die Modelltabelle inkl. Mehrfach-Provider (`AccTestHost; Chutes`), Mehrfach-Quantisierung (`bf16; fp16`), Ausschluss von `provider_order` (`Inception`) und Hinweis auf unlesbare `meta`-Zeilen.
2. **`tests/fuzz/test-m3d-qa-fuzz.R` (2 `test_that`-Blöcke, 195 `expect_*`-Prüfungen, Seed `20261106`):**
   - `QA-M3d-FUZZ-1`: Property- und Grenz-Fuzzing für `parse_number()`, `parse_choice()` und `parse_json_field()` (`K-M3d-2`, `ADR-053` Nr. 2–4, 15). Prüft Unicode-Minus `U+2212`, Dezimalpunkt/-komma, führende Dezimalzeichen, Exponenten, Bezeichner mit Ziffern (`CYP3A4`, `H2O`, `pIC50`, `EC50`, `mg/m3`), ungültige `whole_word`-Argumente, mehrfache Alias-Treffer vs. Klassenkonflikte sowie `parse_json_field()` gegen unpaarige Anführungszeichen vor `{`, geschachtelte Objekte mit identischem Schlüsselnamen, Escapes (`"`, ``, `\/`, `
`, `	`, `
`, `\u00e4`), nachfolgende Zweitobjekte, Nicht-Skalare (`null`, `true`, `false`, Arrays, Objekte), Vektoreingaben (`NULL`, `character(0)`, Länge > 1) und Dateipfad-/URL-Attrappen (`"{nonexistent_file.json}"`, `"https://example.com/data.json"`).
   - `QA-M3d-FUZZ-2`: Metamorphes und 1-ULP-Sensitivitäts-Fuzzing für `msa_report_canonical()`, `msa_report_hash()`, `msa_report_seed()`, `msa_report_models()` und `msa_report_control_chart()` (`K-M3d-5`, `K-M3d-6`, `ADR-053` Nr. 10, 12, 14). Prüft Permutationsinvarianz über 25 zufällige Zeilen-/Spaltenpermutationen, zusätzliche Attribute, Zeilennamen und feindliche globale R-Optionen (`OutDec = ","`, `scipen = 999`, `digits = 2`), strikte Hash-Änderung bei 1-ULP-Abweichung (`1 - .Machine$double.neg.eps`), `NaN` vs. `NA_real_`, `-Inf` vs. `Inf`, `"NA"` vs. `NA_character_` vs. `""` und Zeilenduplikaten sowie Randfälle der Provenienz-Helfer.

---

## 4. Befunde

Es wurden **keine `blocking`-Befunde** gegen `K-M3d-1` bis `K-M3d-6` oder `ADR-053` Nr. 1 bis 18 festgestellt. Alle M3d-Abnahmetests (`test-m3d-1-resume.R` bis `test-m3d-6-report-conventions.R` in `orchestrator/state/M3d/gate-tests.log`) sowie sämtliche E2E- und Fuzz-Tests sind grün.

Als nicht-blockierende Randbeobachtung außerhalb des M3d-Änderungsumfangs (Bestandscode seit `332a2d5`) wird für die Pflege nach dem 26.11.2026 dokumentiert:

### `QA-M3d-001` — Vektoreingaben der Länge > 1 in `parse_number()` und `parse_choice(..., whole_word = FALSE)`

- **Testpfad (Dokumentation / Nachweis):** `R/parse.R` Z. 36 (`parse_number`) und Z. 96 (`parse_choice`, Zweig `!whole_word`); vgl. `tests/fuzz/test-m3d-qa-fuzz.R` (`QA-M3d-FUZZ-1` für `parse_choice(..., whole_word = TRUE)` und `parse_json_field()`).
- **Reproduktion (Seed `20261106`):**
  ```r
  set.seed(20261106L)
  parse_number()(c("1.5", "2.5"))
  parse_choice(c("A", "B"), whole_word = FALSE)(c("A", "B"))
  ```
- **Beobachtet:** In R >= 4.3 wirft `if (is.null(text) || !length(text) || is.na(text))` bei einem Zeichenkettenvektor mit `length(text) > 1L` einen Laufzeitfehler (`Error in is.null(text) || !length(text) || is.na(text) : 'length = 2' in coercion to 'logical(1)'`), obwohl die Folgezeile `x <- as.character(text)[1]` auf das erste Element zugreift. Im Gegensatz dazu geben `parse_choice(..., whole_word = TRUE)` (`R/parse.R:81`) und `parse_json_field()` (`R/parse.R:128`) über `length(text) != 1L || is.na(text)` sauber `NA_character_` zurück.
- **Erwartet (Empfehlung für die Pflege nach dem 26.11.2026):** Einheitliche Vorabprüfung `if (length(text) != 1L || is.na(text))` (bzw. `is.na(text[1L])`) in `parse_number()` und im Teilwortzweig von `parse_choice()`, sobald die nach `ADR-035` eingefrorenen Bestandszeilen nach dem 26.11.2026 geöffnet werden. Im regulären Betrieb über `msa_run()` tritt der Fall nicht auf, da `txt <- as.character(content)[1L]` (`R/run.R:106`) dem Parser stets einen Skalar der Länge 1 übergibt.
- **Vorgeschlagene Schwere:** `nonblocking` (`ADR-053` Nr. 2–4 und Nr. 15.2 regeln Skalar-, `NULL`-, Länge-0- und `NA`-Eingaben; `R/parse.R:36,96` ist unveränderter Bestandscode aus `332a2d5`; Entscheidung beim Reviewer).

---

## 5. Lokaler Ausführungsnachweis

```text
tests/e2e/test-m3b-qa-e2e.R:  3 Blöcke,  259 PASS, 0 FAIL, 0 ERROR, 0 SKIP
tests/e2e/test-m3d-qa-e2e.R:  3 Blöcke,   91 PASS, 0 FAIL, 0 ERROR, 0 SKIP
tests/fuzz/test-m3d-qa-fuzz.R: 2 Blöcke, 195 PASS, 0 FAIL, 0 ERROR, 0 SKIP
Gesamtsuite tests/e2e:       28 Blöcke,  818 PASS, 0 FAIL, 0 ERROR, 0 SKIP
Gesamtsuite tests/fuzz:      15 Blöcke, 1580 PASS, 0 FAIL, 0 ERROR, 0 SKIP
```
