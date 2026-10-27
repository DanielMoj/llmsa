# QA — M2 (Red Team)

Rolle: QA / Red Team (keine Verdict-Macht; Schweregrade sind Vorschläge für den Reviewer) · Meilenstein: `M2` · Stand: 27.10.2026 · Fester, geloggter Seed aller QA-Tests: `20261027` (`set.seed(20261027L)`).

## Geprüfter Kontext

- Rahmen und Verträge: `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`.
- Meilenstein-Spezifikation und Entscheidungen: `orchestrator/handoff/M2/CRITERIA.json` (`K-M2-1` bis `K-M2-7`, `ACC-1` bis `ACC-25`), `docs/03-anwendungspipeline.md` (einschließlich Anhang A.1–A.8), `docs/01-fachspezifikation.md`, `docs/decisions/ADR-004-freigabe-validierungsplan-ap1.md` bis `docs/decisions/ADR-009-m2-json-metadaten-praezision.md`, `orchestrator/handoff/M2/PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md`, `PROGRESS.md`.
- Gate-Stand und Logs: `orchestrator/state/M2/gates.json`, `gate-deps.log`, `gate-lint.log`, `gate-tests.log`, `gate-trace.log`, `gate-territory.log`, `gate-mutgate.log`, `gate-golden-adr.log`, `gate-mutfull.log`.
- Geänderte Produkt- und Testdateien seit `plan/M2`: `R/acmg.R`, `R/parse.R`, `R/backends.R`, `R/run.R`, `R/report.R`, `inst/templates/validation_report.Rmd`, `inst/validation/ap1/plan.yaml`, `inst/validation/ap1/run.R`, `data-raw/make_items_ap1.R`, `inst/extdata/items_ap1_2026-10-24/`.

---

## Befunde

### QA-M2-001 — Einzelmodell-Berichte (`acmg_assessment`) enthalten im Abschnitt `Repeat-day diagnostics` falsche `FALSE`/`NA`-Diagnosen für die jeweils anderen beiden Modelle

- **ID:** `QA-M2-001`
- **Reproduzierender Test:** `tests/e2e/test-m2-qa-e2e.R` (`test_that("QA-M2-001: per-model assessment Repeat-day diagnostics must not report false FALSE/NA rows for other models (seed = 20261027)", ...)`, Zeilen 52–100)
- **Seed:** `20261027`
- **Spezifikations-/ADR-Bezug:** `docs/03-anwendungspipeline.md` A.6, A.7 (`ANK-67`); `docs/decisions/ADR-006-k-m2-5-7-lauf-pilot-auswertung.md` Nr. 7.8; `docs/01-fachspezifikation.md` §2 Nr. 4 („nie stillschweigend eine falsche Zahl“).
- **Beobachtetes Verhalten:**
  In `R/acmg.R` (Zeile 1034–1038) übergibt `acmg_evaluate()` je Modell `key` nur den modellspezifischen Teildatensatz `data <- main[main$model_id == key, , drop = FALSE]` an `acmg_assessment(m, key, data, joint, plan)`. Während `pilot$rules` und `pilot$summary` zuvor auf `model == key` gefiltert werden, ruft `acmg_assessment()` in Zeile 962 `acmg_repeat_day(runs, plan)` auf `runs` (= `data`) auf. Da `acmg_repeat_day()` über alle drei Plan-Modelle (`sol`, `llama`, `qwen`) iteriert und `data` für die beiden anderen Modelle 0 Zeilen enthält, entstehen im Bericht jedes Modells (z. B. `ap1-sol.html`) vier Zeilen für die jeweils anderen beiden Modelle mit `provider_change = FALSE`, `model_change = FALSE`, `backend_error_share = NA` und `error_trigger = FALSE` — selbst dann, wenn `llama` im übergebenen `runs`-Objekt in Block 1 tatsächlich > 11 % HTTP-500-Fehler (`error_trigger = TRUE`), einen Anbieterwechsel (`provider_change = TRUE`) und einen Modellkennungswechsel (`model_change = TRUE`) aufweist.
- **Erwartetes Verhalten:**
  Die Tabelle im Abschnitt `Repeat-day diagnostics` eines Einzelmodell-Berichts darf keine falschen `FALSE`/`NA`-Einträge für andere Modelle ausweisen: Entweder wird `acmg_repeat_day` wie `pilot$rules` und `pilot$summary` auf das jeweilige Modell `model == key` beschränkt, oder `acmg_repeat_day` wird auf `main` (allen Modellen) berechnet, sodass jede im Bericht enthaltene Modellzeile die tatsächlichen Wiederholungstags-Auslöser aus `runs` wiedergibt.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M2-002 — `acmg_repeat_day()` übersieht fehlende oder teilweise fehlende `provider`-Felder in erfolgreichen OpenRouter-Antworten (`provider_change = FALSE`)

- **ID:** `QA-M2-002`
- **Reproduzierender Test:** `tests/e2e/test-m2-qa-e2e.R` (`test_that("QA-M2-002: acmg_repeat_day flags missing or partially missing provider fields on OpenRouter API responses (seed = 20261027)", ...)`, Zeilen 102–139)
- **Seed:** `20261027`
- **Spezifikations-/ADR-Bezug:** `docs/03-anwendungspipeline.md` K-M2-4, A.6 (`ANK-60`, `ANK-67`); `docs/decisions/ADR-006-k-m2-5-7-lauf-pilot-auswertung.md` Nr. 7.2 und Nr. 7.8 („Auslöser sind: ein `provider`, der vom angeforderten abweicht oder innerhalb des Blocks wechselt“).
- **Beobachtetes Verhalten:**
  In `R/acmg.R` (Zeile 565–568) extrahiert `acmg_repeat_day()` die Anbieter über `providers <- unique(unlist(lapply(m, `[[`, "provider"), use.names = FALSE))`. Da `unlist()` in R `NULL`-Elemente stillschweigend verwirft, wird ein fehlendes `provider`-Feld in `meta` einer erfolgreichen OpenRouter-API-Antwort (`id` und `model_snapshot` vorhanden, kein Backend-Fehler) ignoriert:
  1. Liefert ein Teil der erfolgreichen Antworten eines Blocks für `llama` `"CoreWeave"` und ein anderer Teil kein `provider`-Feld (`NULL`), ist `providers` nur `"CoreWeave"` (Länge 1) und `provider_change` ist `FALSE`.
  2. Liefern alle erfolgreichen Antworten eines Blocks für `qwen` kein `provider`-Feld (`NULL`, wie in `ANK-60` für die dokumentierte OpenRouter-Antwort festgehalten), ist `providers` `NULL` (Länge 0) und `provider_change` ist ebenfalls `FALSE` statt `TRUE`.
  (Zum Vergleich: `acmg_pilot()` ersetzt in Zeile 502 fehlende `provider`-Felder auf erfolgreichen Antworten durch `""` via `x$provider %||% ""`, sodass `all(providers == model$provider_name)` dort `FALSE` liefert.)
- **Erwartetes Verhalten:**
  Bei Modellen mit angefordertem OpenRouter-Anbieter (`length(model$provider_name) > 0L`) muss eine erfolgreiche API-Antwort ohne `provider`-Feld (oder mit leerem `provider`) in `acmg_repeat_day()` als Abweichung vom angeforderten `model$provider_name` bzw. als Wechsel innerhalb des Blocks erkannt werden (`provider_change = TRUE`).
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M2-003 — `acmg_provenance()` und `acmg_store_read()` kennzeichnen nicht-fehlgeschlagene Zeilen ohne `meta` bei gesetztem `ap1_mode = "api"` als `"api"` und verlieren bei Mock-Läufen mit einzelnen `meta = NA`-Zeilen die Kennzeichnung `"synthetic"`

- **ID:** `QA-M2-003`
- **Reproduzierender Test:** `tests/e2e/test-m2-qa-e2e.R` (`test_that("QA-M2-003: acmg_provenance and acmg_store_read never certify non-error rows without meta as api or strip synthetic from mock runs (seed = 20261027)", ...)`, Zeilen 141–178)
- **Seed:** `20261027`
- **Spezifikations-/ADR-Bezug:** `AGENTS.md` Integrität Nr. 5; `docs/decisions/ADR-006-k-m2-5-7-lauf-pilot-auswertung.md` Nr. 9 („`acmg_evaluate()` bricht bei gemischter Eingabe mit benanntem Fehler ab. Ergebnisse und Berichte aus Mock-Zeilen kennzeichnet es sichtbar als synthetisch.“); `orchestrator/handoff/M2/PLAN-REVIEW.md` E16 („Zeilen ohne `meta` gelten als Herkunft ‚nicht belegt‘, nie als `api`.“).
- **Beobachtetes Verhalten:**
  In `R/acmg.R` (Zeile 455–457) prüft `acmg_provenance(runs)`:
  ```r
  if (!is.null(marker)) known <- marker
  if (is.null(marker) && any(row_kind == "unknown" & !acmg_errors(runs))) return("unverified")
  if (!length(known)) "unverified" else if (known == "mock") "synthetic" else "api"
  ```
  1. Ist `attr(runs, "ap1_mode")` auf `"api"` gesetzt (etwa nach `acmg_store_init(store, "api")` und Lesen über `acmg_store_read(store, "api")` bzw. `run.R --evaluate-only --backend api`), wird die Prüfung auf `row_kind == "unknown" & !acmg_errors(runs)` wegen `is.null(marker) == FALSE` komplett übersprungen. Nicht-fehlgeschlagene Zeilen (`error = NA`) mit `meta = NA` oder `meta = "{}"` (ohne `id` und `model_snapshot`) erhalten dadurch `provenance = "api"` statt als unbelegt (`"unverified"`) oder fehlerhaft abgewiesen zu werden.
  2. Enthält ein an `acmg_evaluate(runs, plan)` übergebener Mock-Datensatz (`meta = '{"mock":true}'`, ohne `ap1_mode`-Attribut) auch nur eine einzige nicht-fehlgeschlagene Zeile mit `meta = NA`, gibt Zeile 456 `"unverified"` statt `"synthetic"` (oder eines Fehlers bei gemischter Herkunft) zurück und entfernt damit die Pflichtkennzeichnung `"synthetic"`.
- **Erwartetes Verhalten:**
  Nicht-fehlgeschlagene Zeilen ohne API-Metadaten (`row_kind == "unknown" & !acmg_errors(runs)`) dürfen auch bei gesetztem Store-Marker niemals als `"api"` zertifiziert werden (`acmg_provenance()` darf nicht `"api"` liefern bzw. `acmg_store_read(store, "api")` muss abbrechen), und ein Datensatz mit Mock-Zeilen (`"mock"`) darf durch einzelne `meta = NA`-Zeilen nicht seine `"synthetic"`-Kennzeichnung verlieren (entweder `"synthetic"` oder Abbruch wegen gemischter Herkunft).
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M2-004 — `acmg_modal_table()`, `acmg_evaluate()` und `acmg_robustness()` verlieren bei unvollständigem Hauptplan Items mit 0 beobachteten Hauptplanaufrufen aus `modal`, `n_no_modal`, `reference_basis` und `robustness$response$reference_n`

- **ID:** `QA-M2-004`
- **Reproduzierender Test:** `tests/e2e/test-m2-qa-e2e.R` (`test_that("QA-M2-004: incomplete main-plan runs with 0 calls for an item retain all 100 items in modal, reference_basis and PB reference_n (seed = 20261027)", ...)`, Zeilen 180–221)
- **Seed:** `20261027`
- **Spezifikations-/ADR-Bezug:** `docs/03-anwendungspipeline.md` K-M2-6, K-M2-7, A.1, A.5, A.7 (`ANK-68`); `docs/decisions/ADR-006-k-m2-5-7-lauf-pilot-auswertung.md` Nr. 8.1, Nr. 8.2 und Nr. 11; `orchestrator/handoff/M2/PLAN-REVIEW.md` E19.
- **Beobachtetes Verhalten:**
  Fehlt in einem unvollständigen Hauptplan-Lauf für ein Modell (z. B. `sol`) für ein ERepo-Item aus `items.csv` jede Hauptplanzeile (0 von 18 Aufrufen), während die übrigen Modelle und die PB-Robustheitsläufe (`pb01`–`pb12`) alle 100 Items in `runs` enthalten:
  1. `acmg_modal_table(data)` (`R/acmg.R`, Zeile 800) bildet `ids <- sort(unique(runs$item_id), method = "radix")` nur über die in `data` vorhandenen Zeilen des einzelnen Modells. Dadurch hat `ev$models$sol$modal` nur 99 statt 100 Zeilen, das fehlende Item fehlt in `sol$modal$item_id`, `sol$n_no_modal` (`sum(!modal$has_modal)`) zählt das Item ohne Modalantwort nicht mit, und `kappa_items + excluded_no_modal + excluded_missing_reference` in `sol$reference_basis` summiert sich auf 99 statt 100.
  2. `acmg_robustness()` (`R/acmg.R`, Zeile 874) liest die Referenzklasse für die sekundäre Trefferquote der PB-Läufe über `reference <- modal[match(r$item_id, modal$item_id), , drop = FALSE]` aus `modal` statt aus `r$reference` (bzw. einem alle 100 Plan-Items umfassenden `modal`). Dadurch sinkt `sol$robustness$response$reference_n` in allen 12 PB-Läufen von 75 auf 74, obwohl alle 75 ERepo-Referenzen in den PB-Zeilen von `runs` vorliegen.
- **Erwartetes Verhalten:**
  `modal` je Modell umfasst alle 100 Plan-Items (mit `modal = NA_character_` und `has_modal = FALSE` für Items mit 0 Hauptplanaufrufen des Modells sowie den aus `runs` stammenden Item-Spalten nach ADR-006 Nr. 11), `n_no_modal` und `reference_basis` bilanzieren alle 100 Items vollständig, und `robustness$response$reference_n` zählt alle 75 ERepo-Referenzen.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)

---

### QA-M2-005 — `acmg_evaluate()` und `acmg_robustness()` akzeptieren in PB-Robustheitszeilen (`pb01`–`pb12`) unbekannte Antwortklassen in `value` sowie ungültige `rep`-/`block`-Werte

- **ID:** `QA-M2-005`
- **Reproduzierender Test:** `tests/fuzz/test-m2-qa-fuzz.R` (`test_that("QA-M2-005: acmg_evaluate and acmg_robustness reject unknown response classes and out-of-range rep/block in PB runs (seed = 20261027)", ...)`, Zeilen 30–101)
- **Seed:** `20261027`
- **Spezifikations-/ADR-Bezug:** `docs/01-fachspezifikation.md` §2 Nr. 4 („nie stillschweigend eine falsche Zahl“); `docs/decisions/ADR-005-k-m2-1-2-itemsatz-auslegungen.md` Nr. 1 („`reference` und alle Klassenwerte der Pipeline tragen die Bezeichnungen von A.3 in Skalenordnung (`ANK-69`)“); `docs/decisions/ADR-006-k-m2-5-7-lauf-pilot-auswertung.md` Nr. 8.2; `docs/03-anwendungspipeline.md` K-M2-7.
- **Beobachtetes Verhalten:**
  1. `acmg_evaluate()` prüft in `R/acmg.R` (Zeile 988–990) nur `main$value` und `main$reference` auf unbekannte Klassen außerhalb von `acmg_classes(plan)`. Enthält eine PB-Robustheitszeile (`pb01`–`pb12`) in `value` eine unbekannte oder unnormierte Bezeichnung (im Test mit Seed `20261027` gezogen aus `c("VOUS", "Likely Pathogenic", "Uncertain Significance", "InvalidClass_99")`), bricht `acmg_evaluate()` nicht mit `"AP1 runs contain unknown response or reference classes."` ab, sondern `acmg_robustness()` wertet die Zeile stillschweigend als gültige Nicht-Übereinstimmung (`r$value == reference$modal` ergibt `FALSE`) und berechnet daraus verfälschte Logit-Werte `y`, Lenth-Effekte, `delta_p` und Bänder.
  2. `acmg_robustness()` prüft in Zeile 868–869 lediglich die Häufigkeitstabelle über `(item_id, prompt_id)`, ignoriert aber vorhandene `rep`- und `block`-Spalten (anders als `main` in Zeile 1014–1015). Dadurch werden PB-Zeilen mit `rep = 2` (obwohl `plan$robustness$replicates == 1`) oder `block = 2` als `complete = TRUE` und `band = "acceptable"` statt `complete = FALSE` und `band = "not assessed"` gewertet.
- **Erwartetes Verhalten:**
  `acmg_evaluate()` weist unbekannte Antwort- oder Referenzklassen auch in den PB-Robustheitszeilen mit benanntem Fehler (`"AP1 runs contain unknown response or reference classes."`) zurück, und `acmg_robustness()` prüft (sofern die Spalten `rep` bzw. `block` in `runs` vorhanden sind), dass `rep` in `seq_len(plan$robustness$replicates)` und `block` in `1L` liegt sowie keine doppelten `run_key` vorliegen, andernfalls `complete = FALSE` und `band = "not assessed"`.
- **Vorgeschlagene Schwere:** `blocking` (Vorschlag, Entscheidung beim Reviewer)
