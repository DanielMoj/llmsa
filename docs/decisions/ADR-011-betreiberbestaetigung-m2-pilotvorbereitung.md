# ADR-011 — Betreiberbestätigung der M2-ADRs und Festlegungen vor dem AP1-Pilot

## Status

Angenommen (Betreiber, 27.10.2026). Bindend ab dem AP1-Pilot.

## Kontext

- ADR-005 bis ADR-010 entstanden im Lauf von M2 am 26./27.10.2026 ohne Betreiberfreigabe: ADR-005 bis ADR-007 vom Reviewer in `30-plan-review` Runde 1, ADR-008 und ADR-009 vom Builder in `40-build` Runde 1, ADR-010 vom Reviewer in `50-code-review` Runde 1. Nach ADR-004 („Konsequenzen“) ändert sich der Plan nach dem Start von M2 nur durch ein neues ADR; Planänderungen, die der Pilot nahelegt, entscheidet der Betreiber per ADR.
- Code-Review M2 Runde 3, nicht blockierend: E28 (BL-63), E29 (BL-56), E30 (BL-48), E35 (BL-69); `CRITERIA.json` ACC-15 (ANK-69).
- Prüfung vom 27.10.2026 (Betreiberunterlage außerhalb des Repos).

## Entscheidung

1. ADR-005 bis ADR-010 sind vom Betreiber geprüft und bestätigt.
2. Logging- und Datenregeln der OpenRouter-Anbieter (E28): Quelle sind die Schnappschüsse vom 27.10.2026 unter `quellen/anbieter_2026-10-27/` (`QUELLE.txt`). Sie ersetzen in A.7 und A.8 Nr. 5 den Verweis auf `Provider_Logging.html` vom 22.10.2026, der keine anbieterspezifische Zeile enthält. Der Bericht nennt die Klassifikation von OpenRouter mit deren Einschränkung, die Aussagen von DeepInfra und CoreWeave wörtlich mit Datum und die offenen Punkte; eine Aufbewahrungsdauer wird nicht behauptet. Die Einstellungen im OpenRouter-Konto sind am 27.10.2026 mit drei Bildschirmfotos unter `quellen/anbieter_2026-10-27/openrouter/` festgehalten (`privacy_settings_2026-10-27.png`, `privacy_settings_2026-10-27_teil2.png`, `observability_settings_2026-10-27.png`): ZDR-Durchsetzung für die Modellgruppe „All other models“ eingeschaltet (Option „Zero retention only“; die Gruppe umfasst Llama und Qwen); alle Schalter unter „Data Training“ aus (Endpunkte, die mit Anfragedaten trainieren oder Prompts veröffentlichen, sowie die Datennutzung durch OpenRouter gegen 1 % Rabatt); Input & Output Logging im Default Workspace aus, unter „Traces“ (in der Doku „Broadcast“) kein Ziel eingerichtet. Der Bericht nennt auch die Datenregeln von OpenRouter selbst (`quellen/anbieter_2026-10-27/openrouter/openrouter_docs_guides_privacy_data-collection.md`) und diese Kontoeinstellungen. Der OpenRouter-Schlüssel für AP1 wird im Default Workspace angelegt; nur dort ist Input & Output Logging aus (A.8 Nr. 1).
3. Das Test-Gate setzt `NOT_CRAN=true` (`orchestrator/lib/r-tests.R`), ebenso der Workflow `R-CMD-check`; das Lint-Gate bleibt bei `--as-cran` (E29, BL-56). Gilt im Test-Gate ab M1a, im Workflow ab diesem Commit.
4. `docs/gates-auswahl.md` §3 nennt für das Gate tests K-M2-1 bis K-M2-7 (E30).
5. `usage.completion_tokens` ist die abgerechnete Zählung und enthält das Reasoning (OpenRouter-Doku, Schnappschuss 26.10.2026; Nachzählung mit dem Tokenizer von Qwen3-32B am 27.10.2026: 158 gegen gemeldet 157). `usage.completion_tokens_details.reasoning_tokens` wird nur „wie gemeldet“ berichtet; bei Qwen3-32B über DeepInfra liegt es über `completion_tokens` (197 gegen 157). Die Kostenregel des Pilots bleibt; der Berichtssatz zu Reasoning wird vor dem AP1-Bericht präzisiert (E35, BL-69).
6. Backendfehler in den Robustheitsläufen: Liegt der Anteil der Backendfehler eines Modells in einem PB-Lauf über `error_share_trigger` (5 %, ANK-67), wiederholt der Betreiber den Robustheitsteil auf der Storekopie vor den Robustheitsläufen (A.8 Nr. 4); darunter werden die Fehler je Lauf berichtet.
7. Qwens Reasoning-Text wird ab dem Pilot als `meta$reasoning` gespeichert; Umsetzung als Betreiberänderung vor dem Pilot nach BL-01.
8. ANK-69 ist in `ANKER-TODO.md` nachgetragen (ACC-15).

## Konsequenzen

- Betreiber-Commit vor dem Pilot mit diesem ADR, `docs/03-anwendungspipeline.md` (A.7, A.8 Nr. 4 und 5), `orchestrator/lib/r-tests.R`, `.github/workflows/R-CMD-check.yaml`, `docs/gates-auswahl.md`, `ANKER-TODO.md`, `BACKLOG.md` und `.gitignore` (`orchestrator/logs/qa-probe-*.md`). Die Kriterien K-M2-1 bis K-M2-7 bleiben wortgleich.
- Nr. 7 ergänzt den Inhalt von `meta` aus ADR-007 Nr. 4 um `reasoning`; ausgewertet wird weiter nur `message.content` (ADR-004, Nachtrag 2).
- `inst/validation/ap1/plan.yaml` (`reporting.policies`) und der Berichtssatz in `R/acmg.R` ändern sich vor dem AP1-Bericht im Meilenstein, der den Bericht berührt, oder als Betreiberänderung mit Gates.
- BL-56 ist erledigt; in BL-48 ist die Zuordnung von K-M2-7 ergänzt. BL-63 bleibt offen, bis `plan.yaml` `reporting.policies` angepasst ist, BL-69, bis der Berichtssatz präzisiert ist. BL-71 hält die Grenze der Memorisierungskennzeichen aus ADR-005 fest; Entscheidung vor der Endauswertung.

## Nachtrag 27.10.2026 — Umsetzung vor dem Pilot

- Die Nummern 2, 5, 6 und 7 sind vor dem AP1-Pilot umgesetzt, als Betreiberänderung nach BL-01 außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`; Umsetzung mit Claude Code). Abnahme-, E2E- und Fuzz-Tests, `tests/fixtures/`, `reference/anchors/` und `inst/extdata/` sind unverändert; die Kriterien K-M2-1 bis K-M2-7 bleiben wortgleich, die `formals()` der 22 exportierten Funktionen ebenso (ANK-02).
- Nr. 7: `backend_openai_compatible()` (`R/backends.R`) übernimmt `choices[[1]]$message$reasoning` als `meta$reasoning`, wenn es eine nicht leere Zeichenkette ist; sonst fehlt der Schlüssel. `reasoning_details` wird nicht gespeichert, der Antworttext bleibt ausschließlich `message.content`. `man/backends.Rd` und `NEWS.md` sind ergänzt. Beleg: `tests/testthat/test-backend-reasoning.R`. Mit `qwen.json` ist `meta$reasoning` gleich dem aufgezeichneten Text, auch nach `msa_run()` und einem SQLite-Store, und der geparste Wert stammt nur aus `content`; mit `sol.json` und `llama.json` fehlt der Schlüssel. Dazu kommen synthetische Randfälle (leer, `null`, keine Zeichenkette, nur `reasoning_details`). Die Erwartung in `tests/testthat/test-acmg-api.R`, der Reasoning-Text stehe nicht in `meta`, folgt jetzt Nr. 7.
- Nr. 6: `acmg_robustness_errors()` (`R/acmg.R`) zählt je Modell und Prompt-ID `pb01` bis `pb12` die Zeilen, die Fehlerzeilen und deren Anteil. Fehlerzeilen sind Backendfehler (Spalte `error` gesetzt), nicht unlesbare Antworten (wie ADR-006 Nr. 7.8). Anteile über `error_share_trigger` sind markiert (`error_trigger`). `run.R --part robustness` gibt die Tabelle nach dem Lauf aus; `acmg_evaluate()` führt sie je Modell als `robustness$errors`, der Bericht im Abschnitt „Robustness backend errors“. Erzwungen wird nichts. Beleg: `tests/testthat/test-acmg-robustness-errors.R` mit `backend_mock()` und eingestreuten Fehlerzeilen. Geprüft sind Ausgabe von `run.R`, Ergebnis von `acmg_evaluate()` und Berichtsabschnitt; ein Fehler in 20 Zeilen, also genau 5 %, wird nicht markiert.
- Nr. 5 (E35, BL-69): Der Berichtssatz in `R/acmg.R` lautet jetzt „Latency and token summaries use available recorded values. Costs use usage.completion_tokens, which includes reasoning. Reasoning token counts are shown as reported by the API; for Qwen3-32B via DeepInfra they can exceed completion_tokens and are then not on the model's token scale.“ Die Pilotzusammenfassung nennt je Modell zusätzlich drei Werte:
  - `reasoning_exceeds_completion`: die Zahl der fehlerfreien Zeilen mit `reasoning_tokens > completion_tokens`;
  - `usage_cost_usd`: die Summe von `usage.cost`;
  - `recomputed_cost_usd`: die Summe aus (prompt_tokens × price_in + completion_tokens × price_out) / 10^6 mit den Preisen aus `plan.yaml` in USD je 1 Mio. Tokens.

  Die beiden Summen gelten nur für die OpenRouter-Modelle und nur, wenn jede fehlerfreie Zeile die Felder trägt; sonst und bei Sol stehen sie auf NA. Die vier Bestehensregeln und die Kostenprojektion sind unverändert. Beleg: `tests/testthat/test-acmg-pilot-costs.R` mit den drei Aufzeichnungen: Qwen meldet 197 gegen 157 Tokens; gemeldete und nachgerechnete Kosten je Aufruf sind gleich (Llama 4,615e-05 USD, Qwen 4,876e-05 USD); Sol trägt kein `usage.cost`.
- Nr. 2 (E28, BL-63): In `inst/validation/ap1/plan.yaml`, `reporting.policies`, ersetzen drei Einträge im selben Schema den gemeinsamen Eintrag „CoreWeave and DeepInfra via OpenRouter“: DeepInfra, CoreWeave und OpenRouter selbst, mit den Schnappschüssen vom 27.10.2026. Der OpenAI-Eintrag ist unverändert. Die summaries von DeepInfra und CoreWeave enden mit „ZDR was enforced in the OpenRouter account settings during AP1.“ Alle in `location` genannten Dateien liegen unter `quellen/anbieter_2026-10-27/` (W&B Master Service Agreement: `wandb/wandb_site_terms.html.gz`). Die Zitate stehen wörtlich in ihren Quellen; das von DeepInfra steht in `deepinfra_terms.html`, Abschnitt 7(b), über Zeilenumbrüche verteilt. Beleg: `tests/testthat/test-acmg-policies.R` prüft das Schema und den gerenderten Bericht (je Anbieter Datum, Zitat und URL).
- Prüfläufe am 27.10.2026 im Ordner `llmsa/`:
  - `NOT_CRAN=true Rscript orchestrator/lib/r-tests.R tests/testthat tests/acceptance tests/simulation tests/e2e tests/fuzz` endet mit „pass — 168 Tests in tests/testthat, tests/acceptance, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“. Übersprungen ist nur „backend_ellmer needs ellmer“ (BL-17); `tests/simulation` enthält keine Testdateien.
  - `bash orchestrator/lib/r-check.sh` endet mit „pass — Status: OK“.
  - `git diff --stat done/M2 -- tests/acceptance tests/e2e tests/fuzz tests/fixtures reference/anchors inst/extdata` ist leer.
- BL-63 und BL-69 sind erledigt.
