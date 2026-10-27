# REVIEW — M2, Runde 2 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde 2 · Stand: 27.10.2026 · Gegenstand: Diff seit `plan/M2` (Tag-Objekt `9d91937d…` → Commit `f4b81117…`) bis HEAD `3e68e084…`, Schwerpunkt der Rework-Commit `ec55d908…` (Basis `ad6801cc…`), sowie die Gate-Fakten `orchestrator/state/M2/gates.json` der Runde 2.

## Gelesen

- Rollen und Protokoll: `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- Handoff M2: `CRITERIA.json` (K-M2-1 bis K-M2-7, ACC-1 bis ACC-25), `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `QA.md`, `REVIEW.md` und `verdict-code.json` der Runde 1, `REWORK-NOTES.md` der Runde 2.
- Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`, `MUT-EQUIV.json`.
- Spezifikation: `docs/03-anwendungspipeline.md` vollständig, `docs/01-fachspezifikation.md` §2 und §4, ADR-005 bis ADR-010, Anker `ANK-60`.
- Gates: `gates.json` der Runde 2 und alle acht `gate-*.log`.
- Diff:
  - `R/acmg.R`: alle Rework-Hunks mit Umgebung, dazu `acmg_pilot()`, `acmg_run_cli()` und `acmg_store_read()` vollständig.
  - Tests: `tests/testthat/test-acmg-rework.R`, `helper-acmg.R`, `test-acmg-pipeline.R`; `tests/e2e/`, `tests/fuzz/`; `tests/fixtures/api/*.json`.
  - Seit `plan/M2` außerdem `R/backends.R`, `R/run.R`, `R/report.R`, `R/parse.R` sowie `inst/validation/ap1/{run.R,README.md}`.
  - Der Nachtrag in `PROGRESS.md`.
- Visuelle Artefakte: keine (`orchestrator/state/M2/shots/` ist leer).

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

Den Diff habe ich aus `.git/objects` gelesen, mit dem R-Leser aus Runde 1 (`/tmp/rv-m2/gitread.R`, lose Objekte und Pack). Gerechnet habe ich mit `Rscript` gegen eine Paketkopie unter `/tmp/rv-m2-r2/pkg` (`pkgload::load_all()`, Arbeitsverzeichnis `tempdir()`). Im Arbeitsbaum geschrieben sind nur `REVIEW.md`, `verdict-code.json` und `BACKLOG.md`.

1. **Inventar.**
   - Phasen-Commits seit `plan/M2`:
     - `4187c51` build;
     - `b635395` gates r1, rc=0;
     - `a818d5b` qa;
     - `ce29620` gates r1, rc=1;
     - `ad6801c` review r1;
     - `ec55d90` rework r2;
     - `3e68e08` gates r2, rc=0.
   - Das Rework ändert nur `R/acmg.R` und `PROGRESS.md`. Neu sind `tests/testthat/test-acmg-rework.R` und `REWORK-NOTES.md`; sonst ändern sich nur Orchestrator-Zustand und `STATUS.md`.
   - Seit `plan/M2` unverändert sind `tests/acceptance/**`, `tests/fixtures/**`, `reference/anchors/**`, `R/fit.R`, `R/grr.R`, `NAMESPACE` und `.Rbuildignore`. `tests/e2e/` und `tests/fuzz/` sind seit dem QA-Commit unverändert.
   - Der Arbeitsbaum gleicht HEAD für alle Diff-Pfade außerhalb von `orchestrator/state/` (Blob-SHA-1).
2. **E23, Herkunft: Gitter gegen eine eigene Mini-Referenz nach ADR-010 Nr. 3.**
   - Geprüft wurden alle Folgen von 0 bis 3 Zeilen aus acht Zeilentypen, je mit Kennung `NULL`, `mock` oder `api`: zusammen 1.755 Fälle.
   - Die Zeilentypen: Mock, API-belegt, nicht belegt (`NA`, nur `id`, nur `model_snapshot`), jeweils als fehlerfreie Zeile oder Fehlerzeile.
   - Ergebnis: 0 Abweichungen. In der Referenz kann auch eine Fehlerzeile mit widersprechendem `meta` einer Kennung widersprechen. Das verlangt ADR-010, Abschnitt Konsequenzen: Der Bestandsfall `test-acmg-pipeline.R:100–104` muss gültig bleiben.
   - Unter der engeren Lesart (nur fehlerfreie Zeilen widersprechen) wichen 282 Fälle ab. In allen bricht der Code wegen einer solchen Fehlerzeile ab. Diese Lesart schlösse den Bestandsfall aus.
3. **E22, Wiederholungstag: Gitter mit 5.652 Fällen.**
   - Je Modell 1 bis 3 Zeilen. `provider` ist angefordert, ein anderer, fehlt, JSON-`null`, `""` oder `"  "`; jede Zeile ist fehlerfrei oder eine Fehlerzeile.
   - `meta` trägt `provider_order` wie vom Backend erzeugt.
   - Ergebnis: 0 Abweichungen gegen eine Referenz nach ADR-006 Nr. 7.8 mit ADR-010 Nr. 2.
4. **E21 und E24 mit `acmg_evaluate()`** auf konstruierten Läufen (API-artiges `meta`, Fit-Stub):
   - E21: Die Wiederholungstagstabelle jedes Berichts gleicht meiner Nachrechnung aus den Hauptplanzeilen des Modells: je zwei Blöcke, nur das eigene Modell. Fehleranteil (Qwen, Block 2) und Modellwechsel (Llama, Block 1) sind erkannt.
   - E24, Sol ohne zwei Items und mit Gleichstandsitems:
     - `modal` hat 100 Zeilen; `has_modal` und `modal` gleichen meiner Rechnung.
     - `n_no_modal` ist 4 (2 fehlend, 2 Gleichstand), die Summe von `reference_basis` ist 100, und `kappa_items` ist 73 wie in meiner Zählung.
     - PB: `reference_n` ist 75 je Lauf; `reference_hits`, Stabilität x und Logit y gleichen meiner Rechnung.
     - Sol hat `complete = FALSE` und alle Verdikte „not assessed“; Llama hat `complete = TRUE`.
5. **Regressionsnachweis.** `test-acmg-rework.R` lief in einer zweiten Paketkopie gegen das `R/acmg.R` aus `ad6801c`: 8 von 9 Blöcken sind rot. E26 bleibt grün, weil der Block die bestätigte Regel festhält. Gegen den aktuellen Stand sind alle 9 Blöcke grün (194 Erwartungen). Das bestätigt REWORK-NOTES.
6. **Gerenderter Bericht** (`msa_report()`, Fit-Stub, drei Qwen-Zeilen ohne `provider`):
   - Unter „Model and routing“ steht „Successful responses without provider: 3 of 1800; without system_fingerprint: 1800 of 1800.“
   - Die Wiederholungstagstabelle enthält nur Qwen; in Block 2 ist `provider_change` TRUE.
7. **Neu (E31): Pilot mit fehlendem `provider`.** Grundlage ist `meta`, wie `backend_openai_compatible()` es für Llama ohne Antwortfeld `provider` erzeugt: `tests/fixtures/api/llama.json` mit `provider` entfernt (nur im Speicher), eingespielt mit `httr2::local_mocked_responses()`.
   - Gespeichertes `meta`: `{"model_snapshot":…,"id":…,"usage":…,"system_fingerprint":null,"provider_order":["coreweave/fp16"],"quantizations":["fp16"],"allow_fallbacks":false,"seed":20261024,"temperature":0}`.
   - `m$provider` liefert per Partial Matching `list("coreweave/fp16")`, `m[["provider"]]` dagegen `NULL`.
   - `acmg_pilot()` endet mit dem Fehler „values must be type 'character', but FUN(X[[1]]) result is type 'list'“.
   - `acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", <tmp>))` lief in-process mit gemockten Antworten aller drei Modelle. Gespeichert wurden 90 Aufrufe, danach kam derselbe Fehler und keine einzige Regelzeile.
   - `--part main --backend api` auf diesem Store endet mit demselben unbenannten Fehler. Weitere Aufrufe gab es nicht.
   - `acmg_evaluate()` mit vollständigen API-artigen Hauptplanzeilen und einer Llama-Pilotzeile ohne `provider` endet mit demselben Fehler; kein Modell wird ausgewertet. Kontrolle mit `provider`: läuft, die Regel `provider` ist bestanden.
8. **E32 und E33.**
   - Eine Llama-Pilotzeile ohne `id` ergibt `provider failed` mit der Begründung „requested CoreWeave ; reported CoreWeave“.
   - CLI-Pilot mit einer Llama-Antwort ohne `id`: Nach 90 Aufrufen steht „AP1 store backend/provenance does not match --backend; store unchanged.“; Regelzeilen erscheinen nicht.
   - Kontrolle mit unveränderten Fixtures: zwölf Regelzeilen und die Messwerte.

## Gate-Fakten

`gates.json`:

- `milestone` M2, `round` 2, `base` `f4b81117…` (`baseRef` `plan/M2`), `env.sha` `ec55d908…` (Rework-Commit).
- R 4.6.1, pandoc 3.7.0.2, `result` **pass**.

| Gate | Status | Kurzbefund |
| --- | --- | --- |
| deps | pass | 18 Anforderungen erfüllt |
| lint | pass | `R CMD check --as-cran --no-manual`: `Status: OK`, auch „future file timestamps … OK“ |
| tests | pass | 150 Tests, 0 fehlgeschlagen, 0 Fehler, 2 übersprungen |
| trace | pass | alle Kriterien wörtlich und beidseitig verknüpft |
| territory | pass | letzter Diff sauber (builder/60-rework, Runde 2) |
| mutgate | pass | kein geänderter Mutations-Scope |
| golden-adr | pass | Änderung und ADR im selben Meilenstein |
| mutfull | pass | nicht fällig in M2 |

Aufschlüsselung des Test-Gates:

| Ordner | Ergebnis |
| --- | --- |
| `tests/testthat` | `FAIL 0 / WARN 0 / SKIP 2 / PASS 870`, davon `acmg-rework` 194. Skips wie bisher: `test-report.R:5`, `test-backends.R:32` |
| `tests/acceptance` | `FAIL 0 / SKIP 0 / PASS 2340` in 941,0 s, darunter `m2-6-evaluate` 374, `m2-7-robustness-pilot` 375 |
| `tests/e2e` | `PASS 9` (QA-M2-001 bis -004) |
| `tests/fuzz` | `PASS 5` (QA-M2-005) |
| `tests/simulation` | keine Testdateien |

- Kein Gate hat Status `error`.
- Die lokalen Builder-Beobachtungen sind im Gate nicht aufgetreten:
  - M2-R2-INFRA-SOCKET (Socket in `setup-m2.R:771`): K-M2-7 ist im Gate mit 375 Erwartungen grün.
  - M2-R2-INFRA-CLOCK (NOTE zur Uhrzeit): lint ohne NOTE.
- Laufzeit: 04:51:31 bis 05:09:05, also ≈ 17,6 min. Davon entfallen ≈ 16,3 min auf tests (Abnahme 941,0 s, darin `m2-3-prompts-parser` 493,6 s) und ≈ 76 s auf lint (BL-13).

## QA-Befunde

Alle fünf reproduzierenden QA-Tests sind byte-unverändert und im Gate grün. Den Grund prüfe ich jeweils am Code, nicht nur am Test:

| QA | Stand | Beleg |
| --- | --- | --- |
| QA-M2-001 | behoben | Nachprüfung 4; im Sol-Bericht entfällt die bedingte Llama-Prüfung (9 statt 10 Erwartungen), zulässig nach ADR-010 Nr. 1 |
| QA-M2-002 | behoben | Nachprüfung 3 |
| QA-M2-003 | behoben | Nachprüfung 2; ein API-Store mit unbelegter Zeile wird benannt und ohne Byteänderung abgewiesen (`test-acmg-rework.R:96`) |
| QA-M2-004 | behoben | Nachprüfung 4 |
| QA-M2-005 | behoben | Klassenprüfung über Hauptplan- und PB-Zeilen vor dem ersten Fit (`R/acmg.R:1009–1014`); PB-Schlüssel (`:876–881`) |

## Antworten des Builders (REWORK-NOTES), Einzelbewertung

- **E21 — angenommen, erledigt.** `acmg_repeat_day()` überspringt Modell-Block-Paare ohne Zeilen (`R/acmg.R:574`). Der Bericht übergibt nur die Hauptplanzeilen des Modells (`:986`, `:1063`); das erfüllt ADR-010 Nr. 1. Im Laufpfad (`:738–740`) hat nach einem vollständigen `msa_run()` jedes Modell Zeilen im Block, auch Fehlerzeilen.
- **E22 — angenommen, erledigt.**
  - `acmg_meta_text()` (`:449–452`) liest exakt mit `[[`. Fehlende, leere oder nur aus Leerraum bestehende Werte werden `NA`.
  - Der Auslöser (`:580–582`) gleicht der Referenz in allen 5.652 Fällen.
  - Bei Sol ist ein fehlendes Feld kein Auslöser, ebenso ein fehlender `provider` in einer Fehlerzeile.
- **E23 — angenommen, erledigt.** `acmg_provenance()` (`:454–469`) folgt ADR-010 Nr. 3.1 bis 3.3, Nachprüfung 2 zeigt 1.755 Fälle ohne Abweichung. `acmg_store_read()` bleibt unverändert und bricht nach Nr. 3.4 benannt ab; die Meldung behandelt E33.
- **E24 — angenommen, erledigt.**
  - `acmg_modal_table(data, item_ids = ids, item_runs = runs)` (`:799–815`, `:1025`) gibt je Item aus `items.csv` genau eine Zeile.
  - Merkmale kommen nur aus `runs`; Widersprüche über alle Zeilen eines Items bleiben ein benannter Fehler.
  - Die PB-Trefferquote nimmt die PB-Referenzen (`:889–891`).
- **E25 — angenommen, erledigt.**
  - Die Klassenprüfung erfasst `main` und alle `pb*`-Zeilen vor dem gemeinsamen Fit.
  - `acmg_robustness()` verlangt `rep` in `seq_len(plan$robustness$replicates)`, `block` gleich 1 und eindeutige `run_key`.
  - Die Nachsicht für kompakte interne Tabellen ohne Designspalten wirkt im Auswertungspfad nicht, denn `acmg_evaluate()` verlangt die Spalten (`:1003–1004`).
- **E26 — bestätigt, ohne Produktänderung.** `test-acmg-rework.R:215` belegt die Sperre für alle drei Modelle. Offen bleibt BL-64. Die Begründung in der Ausgabe fehlt (E32).
- **E27 — erledigt.** Die Zählung steht im Bericht (`:958–959`, Nachprüfung 6). BL-65 ist geschlossen.
- **E28 bis E30 — [INFRA], Stand unverändert.** Bewertung wie in Runde 1; siehe Einwände.

## Bewertung je Kriterium

- **K-M2-1 bis K-M2-5 erfüllt.** Gate: `m2-1-items` 149, `m2-2-memorisation` 34, `m2-3-prompts-parser` 837, `m2-4-backends` 89, `m2-5-plan` 106. In Runde 2 hat sich nichts davon geändert.
- **K-M2-6 erfüllt.** Gate `m2-6-evaluate` 374 grün; E21, E23 und E24 sind behoben (Nachprüfungen 2 und 4). Hinweis: Der Absturz aus E31 trifft auch `acmg_evaluate()` auf API-Stores; die Behebung von E31 muss diesen Pfad mit abdecken.
- **K-M2-7 nicht abnahmefähig.**
  - Gate `m2-7-robustness-pilot` 375 grün, E22 und E25 sind behoben.
  - Aber `--part pilot` gibt im spezifizierten Fall „Antwort ohne `provider`“ keine einzige Regel aus und endet mit einem unbenannten Typfehler (E31).

## Prüfliste aus dem Auftrag

- **Spec- und Vertragstreue:**
  - Die Rework-Behebungen folgen ADR-010 Nr. 1 bis 5.
  - Blocking-Abweichung: E31 (K-M2-4, K-M2-7, ADR-006 Nr. 7.2, 7.6 und 7.7).
  - Minor-Abweichung: E32 (ADR-010 Nr. 6, „Die Ausgabe nennt den Grund.“).
- **API-Diff:** In Runde 2 ist nur das interne `R/acmg.R` geändert; `NAMESPACE` ist seit `plan/M2` unverändert. `m0-api-snapshot` ist mit 259 Erwartungen grün; BL-57 ist für M2 erledigt.
- **Entkernte Tests:** keine. Kein bestehender Test, kein Abnahme-, QA- oder Fixture-Test wurde geändert. Die neuen Blöcke greifen am alten Code (Nachprüfung 5). Die Leerraum-Normalisierung im neuen E27-Test betrifft nur Builder-eigenen neuen Code, Text und Zahlen bleiben exakt.
- **Gelockerte Konfiguration:** keine. `DESCRIPTION`, `.Rbuildignore`, Gates und `orchestrator/**` sind vom Builder unverändert; territory ist grün.
- **Harte Erwartungswerte:** keine. Der Produktcode erkennt keine Testwerte. Die neuen Tests rechnen ihre Erwartungen aus Planwerten und den konstruierten Daten.
- **Erfundene Daten:** keine. Testdaten sind als synthetisch gekennzeichnet; für CoreWeave und DeepInfra wird keine Aufbewahrung behauptet (E28).
- **Golden-Änderungen ohne ADR:** keine. `inst/extdata/` ist in Runde 2 unverändert (ADR-008, golden-adr pass).
- **Sichtbare Defekte:**
  - Der Pilotbericht und die Auswertung stürzen bei fehlendem `provider` ab (E31).
  - Die Begründung der Pilotregel `provider` führt in die Irre (E32).
  - Die Abbruchmeldung bei unbelegter API-Herkunft führt in die Irre (E33).
  - Die Berichte selbst sind ohne Befund (Nachprüfung 6).
- **MUT-EQUIV:** keine Claims; deshalb keine `MUT-EQUIV-APPROVED.json`. mutgate meldet „kein geänderter Mutations-Scope“.
- **[INFRA] / [QA-PENDING]:** `[INFRA]` sind E28 bis E30; `[QA-PENDING]` gibt es nicht.

## Einwände

### Blocking

- [E31] (blocking) K-M2-7 („`--part pilot` gibt je Modell jede Bestehensregel aus `ANK-67` mit bestanden oder nicht bestanden aus“); K-M2-4 („zeigt sie es nicht, wird der Anbieter stichprobenweise über `GET /api/v1/generation` (Feld `provider_name`) erhoben“); ADR-006 Nr. 7.2 („Fehlt das Feld in der Antwort, ist die Regel nicht bestanden; die Ausgabe weist darauf hin, den Anbieter nach K-M2-4 stichprobenweise über `GET /api/v1/generation` zu erheben“), Nr. 7.6 („… endet mit Exit 0, auch wenn Regeln scheitern“) und Nr. 7.7 („… mit einem benannten Fehler …, der die gescheiterten Regeln nennt“); `docs/01` §2 Nr. 4 („klare Fehlermeldung“); PLAN-REVIEW E18 — Befund:
  - Ursache: `acmg_pilot()` liest den Anbieter mit `x$provider %||% ""` (`R/acmg.R:509`). `$` matcht auf Listen partiell. Für Llama und Qwen schreibt `backend_openai_compatible()` immer `provider_order` aus der Anfrage ins `meta` (`R/backends.R:176–179`); `provider` steht dort nur, wenn die Antwort das Feld trägt (`:175`).
  - Folge: Fehlt das Feld (das ist die dokumentierte OpenRouter-Antwort, `ANK-60`), liefert `x$provider` die Liste aus `provider_order`. `vapply(…, "")` bricht dann mit „values must be type 'character', but FUN(X[[1]]) result is type 'list'“ ab (Nachprüfung 7).
  - `run.R --part pilot --backend api` speichert die 90 Aufrufe und endet dann ohne Regelzeile, ohne Hinweis auf `GET /api/v1/generation` und mit Exit ungleich 0 (`:744`).
  - `--part main|robustness --backend api` enden mit demselben unbenannten Fehler statt mit „AP1 pilot has not passed: …“ (`:715`); die Sperre hält.
  - `acmg_evaluate()` und `--evaluate-only` stürzen ganz ab, sobald eine einzige Pilotzeile von Llama oder Qwen ohne `provider` im Store liegt (`:1057`).
  - Die README sagt das Gegenteil zu (`inst/validation/ap1/README.md:69–71`). Der Bestandstest `test-acmg-pipeline.R:38–42` verfehlt den Fall, weil `ap1_test_meta()` kein `provider_order` setzt (`helper-acmg.R:25–31`).

  — Vorschlag:
  - Den Anbieter exakt lesen, etwa mit `acmg_meta_text(responses, "provider")`. Dann gelten auch leere Werte und Leerraum als fehlend und erhalten den Hinweis mit `meta$id`.
  - Die übrigen `meta`-Zugriffe in `acmg_pilot()` und `acmg_meta_kind()` ebenfalls auf `[[` umstellen.
  - Regeln, Schwellen und die strengere Sperre aus ADR-010 Nr. 6 bleiben unverändert.
  - Dazu Unit-Tests ohne Netz, siehe „Für die Rework-Runde“.

### Minor (nonblocking)

- [E32] (minor) ADR-010 Nr. 6 („Die Ausgabe nennt den Grund.“); ADR-006 Nr. 7.2 — Befund:
  - Ist eine fehlerfreie Pilotantwort von Llama oder Qwen nicht API-belegt, etwa ohne `id`, scheitert `provider` zu Recht. Die Begründung lautet aber „requested CoreWeave ; reported CoreWeave“ (`R/acmg.R:510`, `:516`; Nachprüfung 8).
  - Ein `provider` nur aus Leerraum scheitert ebenfalls ohne Hinweis auf `GET /api/v1/generation`.
  - ADR-010 Nr. 6 hielt den Code von Runde 1 für ausreichend. Der Builder ist deshalb gedeckt.

  — Vorschlag: Im selben Zug wie E31 nennt die Begründung den fehlenden API-Beleg (`id`/`model_snapshot`). → BL-66.
- [E33] (minor) ADR-010 Nr. 3.4; ADR-006 Nr. 7.6; `docs/01` §2 Nr. 4 — Befund:
  - Ein `api`-Store mit fehlerfreien, nicht belegten Zeilen endet nach Nr. 3.4 zu Recht mit benanntem Abbruch, ohne Änderung des Stores.
  - Die Meldung lautet aber „AP1 store backend/provenance does not match --backend; store unchanged.“ (`R/acmg.R:641–643`). Für den Betreiber stimmt `--backend`; es fehlt der Beleg.
  - Im CLI-Pilot kommt der Abbruch erst nach dem Speichern aller 90 Aufrufe, und Regelzeilen erscheinen nicht (Nachprüfung 8).

  — Vorschlag: eigene Meldung für unbelegte Herkunft, mit Zahl der Zeilen, Hinweis auf `meta` `id`/`model_snapshot` und auf einen neuen Store (README, Abschnitt Resume). Verhalten unverändert. Ob der Pilotbericht dann trotzdem erscheinen soll, entscheidet bei Bedarf ein ADR. → BL-67.
- [E26] (minor) ADR-006 Nr. 7.4; ADR-010 Nr. 6 — Befund: unverändert; die Sperre ist belegt (`test-acmg-rework.R:215`). Das Pilot-Quantil liest weiter `evaluation.kappa_bootstrap.quantile_type` (`R/acmg.R:529`). — Vorschlag: bei Gelegenheit entkoppeln. → BL-64.
- [E28] (minor) [INFRA] `docs/03` A.7 (Logging-Regeln CoreWeave/DeepInfra aus `Provider_Logging.html`) — Befund: unverändert; die Builder-Nachprüfung findet 0 Treffer je Anbieter. — Vorschlag: Der Betreiber liefert datierte Belege vor dem AP1-Bericht. → BL-63.
- [E29] (minor) [INFRA] BL-56; PLAN-REVIEW E14 — Befund: `NOT_CRAN` steht weder in `orchestrator/lib/r-tests.R` noch in `config.env` (je 0 Treffer). `test-report.R:5` bleibt im Gate übersprungen (`gate-tests.log`: „On CRAN (1)“). — Vorschlag: Betreiberentscheidung. → BL-56.
- [E30] (minor) [INFRA] BL-48; `docs/gates-auswahl.md:87` („K-M2-1 bis K-M2-6“) — Befund: unverändert; trace ist nicht betroffen. — Vorschlag: Der Betreiber ergänzt K-M2-7. → BL-48.

## Für die Rework-Runde

- E31 in `R/acmg.R` beheben, wie oben vorgeschlagen.
- Unit-Tests ohne Netz unter `tests/testthat/`:
  1. Das `meta` entsteht über `backend_openai_compatible()` aus `acmg_api_backends()`, mit `httr2::local_mocked_responses()` und synthetischen Schlüsseln. Als Antwort dient `tests/fixtures/api/llama.json` bzw. `qwen.json`, dem `provider` nur im Speicher entfernt wird; die Fixtures bleiben unverändert. Erwartet:
     - `acmg_pilot()` liefert zwölf Regelzeilen;
     - `provider` ist für dieses Modell `failed`, die Begründung enthält `/api/v1/generation` und die `id` der Antwort;
     - 4xx und parser hängen nicht vom Fehlen des Feldes ab.
  2. `acmg_evaluate()` läuft mit einer solchen Pilotzeile durch und berichtet die Pilotregeln.
  3. `acmg_run_cli(c("--part", "pilot", "--backend", "api", "--store", <tempfile>))` läuft in-process mit gemockten Antworten aller drei Modelle ohne Fehler durch und gibt die Regelzeilen aus.
  4. `--part main --backend api` endet danach mit „AP1 pilot has not passed: …“, ohne weiteren Aufruf.
- E32 und E33 sind erwünscht, nicht blocking.
- `tests/acceptance/`, `tests/e2e/`, `tests/fuzz/` und `tests/fixtures/` bleiben unberührt. Alle Ordner des Test-Gates bleiben grün.
- In `PROGRESS.md` die echten Outputs nachtragen und E31 bis E33 Punkt für Punkt beantworten.

## Backlog-Pflege in dieser Phase

- **BL-65** gestrichen: E27 ist umgesetzt und belegt.
- **BL-07** fortgeschrieben: E22 ist behoben, E31 offen.
- **BL-13** fortgeschrieben: Gate-Laufzeiten der Runde 2.
- **BL-48**, **BL-56**, **BL-63** und **BL-64** fortgeschrieben, Stand jeweils unverändert.
- Neu sind **BL-66** (E32) und **BL-67** (E33).

## Verdict

**REWORK.**

- `gates.json` meldet `result: pass`, und alle fünf Blocking-Befunde der Runde 1 (E21 bis E25) sind behoben und unabhängig nachgeprüft.
- Blocking bleibt E31: Im spezifizierten Fall einer OpenRouter-Antwort ohne `provider` stürzen Pilotbericht, Pilot-Sperre und Auswertung mit einem unbenannten Typfehler ab. Der Befund trägt die `ref` K-M2-7, K-M2-4 und ADR-006 Nr. 7.2, 7.6 und 7.7.
- Ein Widerspruch zwischen Spec-Stellen, der `ESCALATE` verlangte, liegt nicht vor.
