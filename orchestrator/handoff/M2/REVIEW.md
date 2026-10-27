# REVIEW — M2, Runde 3 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde 3 · Stand: 27.10.2026 · Gegenstand: Diff seit `plan/M2` (Tag-Objekt `9d91937d…` → Commit `f4b81117…`) bis HEAD `f4b9bf23…`, Schwerpunkt der Rework-Commit `5e3541da…` (Basis `6f2ae76f…`), sowie die Gate-Fakten `orchestrator/state/M2/gates.json` der Runde 3.

## Gelesen

- Rollen und Protokoll: `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- Handoff M2: `CRITERIA.json` (K-M2-1 bis K-M2-7), `PLAN-UPDATE.md` und `PLAN-REVIEW.md` (E9), `QA.md`, `REVIEW.md` und `verdict-code.json` der Runde 2, `REWORK-NOTES.md` der Runde 3.
- Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`, `MUT-EQUIV.json`.
- Spezifikation: K-M2-4 und K-M2-7 im Wortlaut von `CRITERIA.json`, `docs/03` A.6, ADR-006 Nr. 7 und 8, ADR-010 vollständig, Anker `ANK-94` (Aufzeichnungen) und `ANK-61`.
- Gates: `gates.json` der Runde 3 und alle acht `gate-*.log`.
- Diff:
  - `R/acmg.R`: alle vier Rework-Hunks mit Umgebung. Vollständig gelesen: `acmg_meta()`, `acmg_meta_kind()`, `acmg_meta_text()`, `acmg_provenance()`, `acmg_pilot()`, `acmg_repeat_day()`, `acmg_store_read()`, `acmg_run_cli()`, `acmg_assessment()` und `acmg_evaluate()`.
  - Tests: `tests/testthat/test-acmg-pilot-metadata.R` vollständig, `helper-acmg.R`.
  - Außerdem `R/backends.R` (`backend_openai_compatible()`, `meta` des Mocks), `inst/validation/ap1/run.R`, `inst/validation/ap1/README.md` (Pilot, Resume) und die Qwen-Preise in `inst/validation/ap1/plan.yaml`.
  - Der Nachtrag „M2 — REWORK, Runde 3“ in `PROGRESS.md`.
- Visuelle Artefakte: keine (`orchestrator/state/M2/shots/` ist leer).

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

Den Diff habe ich aus `.git/objects` gelesen, mit dem R-Leser der Vorrunden (`/tmp/rv-m2/gitread.R`, lose Objekte und Pack). Gerechnet habe ich mit `Rscript` gegen eine Paketkopie unter `/tmp/rv-m2-r3/pkg` (`pkgload::load_all()`, Arbeitsverzeichnis `tempdir()`). Antworten kamen nur über `httr2::with_mocked_responses()`, mit synthetischen Schlüsseln; es gab keinen echten API-Aufruf. Im Arbeitsbaum geschrieben sind nur `REVIEW.md`, `verdict-code.json` und `BACKLOG.md`.

1. **Inventar.**
   - Phasen-Commits seit dem Review der Runde 2: `6f2ae76` review r2; `5e3541d` rework r3; `f4b9bf2` gates r3, rc=0.
   - Das Rework ändert `R/acmg.R` in vier Hunks: 1.072 → 1.081 Zeilen, 16 neu, 7 entfernt. An `PROGRESS.md` hängt es an (828 → 1.006 Zeilen, die ersten 828 byte-gleich).
   - Neu sind `tests/testthat/test-acmg-pilot-metadata.R` (sieben Blöcke) und `REWORK-NOTES.md`. Sonst ändern sich nur Orchestrator-Zustand und `STATUS.md`.
   - Seit `plan/M2` unverändert (Blob-gleich): `tests/acceptance/**`, `tests/fixtures/**`, `tests/simulation/**` und `reference/anchors/**` (zusammen 50 Dateien), dazu `R/fit.R`, `R/grr.R`, `NAMESPACE` und `.Rbuildignore`.
   - `tests/e2e/` und `tests/fuzz/` sind seit dem QA-Commit `a818d5b` unverändert. In Runde 3 hat sich weder ein bestehender Test unter `tests/testthat/` noch `DESCRIPTION` geändert.
   - Der Arbeitsbaum gleicht HEAD für alle 46 Diff-Pfade außerhalb von `orchestrator/state/` und `orchestrator/logs/` (Blob-SHA-1).
   - `sol.json`, `llama.json` und `qwen.json` gleichen `ANK-94` in SHA-256 und Bytes.
   - `R/acmg.R` und der neue Test sind ASCII. Im Arbeitsbaum liegen weder `Rplots.pdf` noch ein Store, ein Archiv oder ein `.Rcheck`-Verzeichnis.
2. **E31, Pilotregel mit echtem Backend-`meta`.**
   - Grundlage: die Aufzeichnungen `llama.json` und `qwen.json`, nur im Speicher verändert und über `acmg_api_backends()` → `backend_openai_compatible()` eingespielt. Das gespeicherte `meta` trägt wie im Befund `provider_order`, `quantizations` und `allow_fallbacks`.
   - Varianten je Modell: `provider` fehlt, JSON-`null`, `""`, Leerraum, Zahl, Array, mit Leerzeichen gepolstert, fremd („Together“), klein geschrieben, korrekt. Je zwei Pilotzeilen des Modells tragen die Variante.
   - Ergebnis in allen 20 Fällen: zwölf Regelzeilen, kein Abbruch.
     - Die sechs Fehlend-Varianten (fehlt, `null`, `""`, Leerraum, Zahl, Array) ergeben `provider failed` mit „GET /api/v1/generation“ und der `id` der Aufzeichnung.
     - Gepolstert, fremd und klein geschrieben ergeben `failed` mit „requested … ; reported …“; korrekt ergibt `passed`.
     - `4xx`, `parser`, `cost` und die Regeln der anderen Modelle bleiben bestanden.
   - Kontrolle ohne Änderung: alle zwölf Regeln bestanden, S = 8,6904 USD.
3. **E31 und E32, Gitter gegen eine eigene Mini-Referenz** nach ADR-006 Nr. 7.2 mit ADR-010 Nr. 3.1 und Nr. 6.
   - Verglichen werden drei Größen: bestanden ja/nein, Hinweis auf `GET /api/v1/generation`, Hinweis „missing API evidence“.
   - 13 Zeilentypen:
     - belegt mit richtigem `provider`;
     - `provider` fehlt, `null`, `""`, Leerraum oder fremd;
     - ohne `id`; ohne `id`, aber mit `id_requested`; ohne `model_snapshot`; ohne `id` und `provider`; ohne `meta`;
     - Fehlerzeile ohne `meta`; Fehlerzeile ohne `provider`.
   - Je zwei Typen stehen in zwei Pilotzeilen von Llama bzw. Sol: zusammen 338 Fälle.
   - Ergebnis: 0 Abweichungen, 0 Abbrüche, stets zwölf Regelzeilen. Die Regel `provider` der anderen Modelle bleibt bestanden.
4. **E31, CLI in-process** (`acmg_run_cli()`, alle drei Aufzeichnungen, Llama und Qwen ohne `provider`):
   - `--part pilot --backend api`: 90 Aufrufe, kein Fehler, zwölf Regelzeilen. `llama provider failed` und `qwen provider failed` nennen „GET /api/v1/generation“ und die Antwort-IDs.
   - `parser` scheitert bei allen drei Modellen mit 20 von 30. Das ist richtig: Die Aufzeichnungen tragen Klartext, der `json`-Prompt verlangt JSON.
   - Resume: Ausgabe identisch, kein weiterer Aufruf, SHA-256 des Stores gleich.
   - `--part main` und `--part main --block 1` enden mit „AP1 pilot has not passed: sol parser, llama provider, llama parser, qwen provider, qwen parser; no API calls made.“ Es folgt kein weiterer Aufruf, der Store bleibt unverändert.
5. **E31, Auswertung mit echten Fits und Berichten** (ohne Stub):
   - Derselbe Pilot mit Llama ohne `provider`, danach 5.400 synthetische, API-artige Hauptplanzeilen im selben Store.
   - `acmg_run_cli(c("--evaluate-only", "--backend", "api", …))` läuft durch. `provenance` ist `api`; jedes Modell hat `complete = TRUE` und seine vier Pilotregeln (`llama provider` FALSE).
   - `ap1-llama.html` enthält „Pilot result“ und den Hinweis auf `GET /api/v1/generation`. Der Store bleibt unverändert.
6. **E33, unbelegte Herkunft im CLI-Pilot** (Llama-Antworten ohne `id`):
   - Nach 90 Aufrufen endet der Lauf mit „AP1 store backend/provenance is unverified: 30 successful responses lack valid meta$id or meta$model_snapshot; use a new store; store unchanged.“
   - Erneuter Aufruf: dieselbe Meldung, kein weiterer Aufruf, Store gleich. `--evaluate-only` und `--backend mock` auf diesem Store bringen dieselbe Meldung.
   - Echte Moduskonflikte behalten „AP1 store backend/provenance does not match --backend; store unchanged.“: ein Mock-Store mit `--backend api` und ein API-Store mit `--backend mock`.
   - Im ersten Lauf trifft „store unchanged“ nicht zu, denn die 90 Aufrufe sind gerade gespeichert (E34).
7. **Regressionsnachweis.**
   - Der neue Testblock lief mit der Aufzeichnungsoption in einer zweiten Paketkopie gegen das `R/acmg.R` aus `6f2ae76`: Alle 7 Blöcke sind rot.
   - Die Fehler sind der `vapply`-Typfehler aus E31, „AP1 mixed mock/API provenance is not permitted.“ (`m$mock` trifft partiell `mock_description`) und „does not match --backend“.
   - Gegen den aktuellen Stand sind alle 370 Erwartungen grün. Das bestätigt REWORK-NOTES.
8. **Suche nach weiteren `$`-Zugriffen auf `meta`-Felder** in `R/acmg.R`, `R/report.R`, `R/run.R`, `R/backends.R`, `R/parse.R`, der Berichtsvorlage und `run.R`:
   - Treffer gibt es nur auf Plan-Strukturen (`m$seed`, `model$provider_order` …) und im unveränderten Antwortparser des Backends (`R/backends.R:172–174`).
   - Die übrigen `meta`-Leser, `acmg_repeat_day()` und `acmg_assessment()`, nutzen `[[` oder `acmg_meta_text()`.
   - `backend_mock()` schreibt `mock = TRUE` exakt (`R/backends.R:104`, `:110`). Die Umstellung auf `[[` ändert die Einstufung echter Mock-Zeilen also nicht.
9. **Aufzeichnung Qwen** (`ANK-94`, `qwen.json`; E35):
   - `usage` meldet `completion_tokens` 157 und `completion_tokens_details.reasoning_tokens` 197.
   - Abgerechnet sind 157 Ausgabetokens: `upstream_inference_completions_cost` beträgt 4,396e-05 USD = 157 · 0,28 / 10^6 (Preis `price_out` aus `plan.yaml`).

## Gate-Fakten

`gates.json`:

- `milestone` M2, `round` 3, `base` `f4b81117…` (`baseRef` `plan/M2`), `env.sha` `5e3541da…` (Rework-Commit).
- R 4.6.1, pandoc 3.7.0.2, `result` **pass**.

| Gate | Status | Kurzbefund |
| --- | --- | --- |
| deps | pass | 18 Anforderungen erfüllt |
| lint | pass | `R CMD check --as-cran --no-manual`: `Status: OK`, auch „checking for future file timestamps ... OK“; Tests im installierten Paket OK |
| tests | pass | 157 Tests, 0 fehlgeschlagen, 0 Fehler, 2 übersprungen |
| trace | pass | alle Kriterien wörtlich und beidseitig verknüpft |
| territory | pass | letzter Diff sauber (builder/60-rework, Runde 3, Basis `6f2ae76…`) |
| mutgate | pass | kein geänderter Mutations-Scope |
| golden-adr | pass | Änderung und ADR im selben Meilenstein |
| mutfull | pass | nicht fällig in M2 |

Aufschlüsselung des Test-Gates:

| Ordner | Ergebnis |
| --- | --- |
| `tests/testthat` | `FAIL 0 / WARN 0 / SKIP 2 / PASS 1092`, davon `acmg-pilot-metadata` 222 (neu) und `acmg-rework` 194. Skips wie bisher: `test-report.R:5`, `test-backends.R:32` |
| `tests/acceptance` | `FAIL 0 / SKIP 0 / PASS 2340` in 946,4 s, darunter `m2-4-backends` 89, `m2-6-evaluate` 374, `m2-7-robustness-pilot` 375 |
| `tests/e2e` | `PASS 9` (QA-M2-001 bis -004) |
| `tests/fuzz` | `PASS 5` (QA-M2-005) |
| `tests/simulation` | keine Testdateien |

- Kein Gate hat Status `error`.
- Die lokalen Builder-Beobachtungen sind im Gate nicht aufgetreten:
  - M2-R3-INFRA-SOCKET (Socket in `setup-m2.R:771`): K-M2-4 und K-M2-7 sind im Gate mit 89 und 375 Erwartungen grün.
  - M2-R3-INFRA-CLOCK (NOTE zur Uhrzeit): lint ohne NOTE.
- Laufzeit: 05:42:27 bis 06:00:19, also ≈ 17,9 min (BL-13).
  - tests ≈ 16,5 min: Abnahme 946,4 s, darin `m2-3-prompts-parser` 493,7 s; testthat 33,4 s.
  - lint ≈ 81 s; deps und trace bis mutfull je ≈ 2 s.

## QA-Befunde

Alle fünf reproduzierenden QA-Tests sind byte-unverändert und im Gate grün. Runde 3 ändert keinen ihrer Pfade fachlich:

| QA | Stand | Beleg |
| --- | --- | --- |
| QA-M2-001 | behoben | `acmg_repeat_day()` und die Übergabe der Hauptplanzeilen sind in Runde 3 unberührt |
| QA-M2-002 | behoben | Der Auslöser liest `provider` weiter mit `acmg_meta_text()` (`R/acmg.R:579–584`) |
| QA-M2-003 | behoben | `acmg_meta_kind()` liest jetzt exakt (`:445–447`); die Herkunftsregeln aus ADR-010 Nr. 3 sind unverändert (Nachprüfungen 3 und 6) |
| QA-M2-004 | behoben | `acmg_modal_table()` ist in Runde 3 unberührt |
| QA-M2-005 | behoben | Klassen- und PB-Schlüsselprüfung unverändert (`:1020–1023`) |

## Antworten des Builders (REWORK-NOTES), Einzelbewertung

- **E31 — angenommen, erledigt.**
  - `acmg_pilot()` liest den Anbieter mit `acmg_meta_text(responses, "provider")` (`R/acmg.R:509`). Fehlende, `null`-, leere, nur aus Leerraum bestehende und nicht als Zeichenkette vorliegende Werte gelten als fehlend.
  - Die Begründung nennt dann `GET /api/v1/generation` und die IDs; eine fehlende ID erscheint als `unavailable` (`:512–516`).
  - `acmg_meta_kind()` (`:445–447`), die Tokenfelder (`:525`) und die Token-IDs (`:542`) lesen exakt mit `[[`.
  - Regeln, Schwellen und Sperre sind unverändert (Nachprüfungen 2 bis 5 und 7).
  - Testweg:
    - Die sieben Blöcke laufen im Paket mit synthetischen Antworten durch den echten Backendpfad. Die Aufzeichnungen kommen nur mit der Testoption `llmsa.test.ap1_recordings` hinzu.
    - Das weicht vom Vorschlag der Runde 2 ab, ist aber durch PLAN-REVIEW E9 gedeckt („Unit-Tests nur mit Paketressourcen“); `tests/fixtures/` wird nicht ausgeliefert.
    - Der synthetische Weg erzeugt dasselbe `provider_order` wie im Befund. Die Aufzeichnungsvariante habe ich selbst laufen lassen (Nachprüfung 7) und in den Nachprüfungen 2, 4 und 5 unmittelbar verwendet.
- **E32 — erledigt.**
  - Bei fehlendem API-Beleg hängt `R/acmg.R:522` „missing API evidence: requires non-mock successful responses with meta$id and meta$model_snapshot“ an, auch bei richtigem Anbieter.
  - Leerraum erhält den Generation-Hinweis (Nachprüfungen 2 und 3, `test-acmg-pilot-metadata.R:89`). BL-66 ist geschlossen.
- **E33 — erledigt.**
  - Die eigene Meldung nennt Zahl, Belegfelder und „use a new store“ (`R/acmg.R:644–650`). Die Zählung lässt Fehlerzeilen und belegte Zeilen aus; Abbruch und Schreibschutz bleiben (ADR-010 Nr. 3.4).
  - Offen war aus Runde 2, ob der Pilotbericht in diesem Fall trotzdem erscheinen soll. Das entscheidet ADR-010 Nr. 3.4 bereits: Der Lesevorgang bricht benannt ab, Abhilfe ist ein neuer Store (README, Abschnitt Resume). Ein neues ADR ist nicht nötig.
  - BL-67 ist geschlossen; der Restpunkt zum Wortlaut ist E34.
- **E26 — vertagt, gedeckt.** Die Sperre ist durch `test-acmg-rework.R:215` und `test-acmg-pilot-metadata.R:89` belegt, die Begründung mit E32 ergänzt. Das Quantil bleibt gekoppelt (`R/acmg.R:531`); BL-64.
- **E28 bis E30 — [INFRA], Stand unverändert.** Die Builder-Belege (0 Treffer je Anbieter, 0 Verweise auf `NOT_CRAN`, `docs/gates-auswahl.md:87`) decken sich mit meiner Nachprüfung.
- **M2-R3-INFRA-SOCKET und M2-R3-INFRA-CLOCK** sind Beobachtungen der Builder-Sandbox. Im Gate sind sie nicht aufgetreten (siehe Gate-Fakten); ein Backlog-Eintrag ist nicht nötig.

## Bewertung je Kriterium

- **K-M2-1, K-M2-2, K-M2-3 und K-M2-5 erfüllt.** Gate: `m2-1-items` 149, `m2-2-memorisation` 34, `m2-3-prompts-parser` 837, `m2-5-plan` 106. Der Code dieser Kriterien ist seit Runde 2 unberührt.
- **K-M2-4 erfüllt.** Gate `m2-4-backends` 89. Zum Teil „zeigt sie es nicht, wird der Anbieter stichprobenweise über `GET /api/v1/generation` (Feld `provider_name`) erhoben“: Der Pilot weist jetzt genau in diesem Fall darauf hin und nennt die IDs (Nachprüfungen 2 und 4).
- **K-M2-6 erfüllt.** Gate `m2-6-evaluate` 374. Auch ein API-Store mit Pilotzeilen ohne `provider` wird mit echten Fits ausgewertet (Nachprüfung 5).
- **K-M2-7 erfüllt.**
  - Gate `m2-7-robustness-pilot` 375.
  - „`--part pilot` gibt je Modell jede Bestehensregel aus `ANK-67` mit bestanden oder nicht bestanden aus“ gilt jetzt auch ohne `provider` (Nachprüfung 4).
  - ADR-006 Nr. 7.6 (Bericht statt Abbruch) und Nr. 7.7 (benannte Sperre ohne Aufruf) sind erfüllt.

## Prüfliste aus dem Auftrag

- **Spec- und Vertragstreue:** Die Behebungen folgen K-M2-4, K-M2-7, ADR-006 Nr. 7.2, 7.6 und 7.7 sowie ADR-010 Nr. 3 und Nr. 6. Es gibt keine Blocking-Abweichung. Minor sind E34 (Wortlaut) und E35 (Annahme der Spec, Sache des Betreibers).
- **API-Diff:** In Runde 3 ist nur das interne `R/acmg.R` geändert; `NAMESPACE` ist seit `plan/M2` unverändert. `m0-api-snapshot` ist mit 259 Erwartungen grün; neue Argumente gibt es nicht (BL-57).
- **Entkernte Tests:** keine. Kein bestehender Test, kein Abnahme-, QA- oder Fixture-Test wurde geändert. Der neue Block greift am alten Code (Nachprüfung 7) und überspringt nur über `skip_if_not_installed()`.
- **Gelockerte Konfiguration:** keine. `DESCRIPTION`, `.Rbuildignore`, Gates und `orchestrator/**` sind vom Builder unverändert; territory ist grün.
- **Harte Erwartungswerte:** keine. Der Produktcode erkennt keine Testwerte. Die neuen Tests leiten ihre Erwartungen aus Planwerten (`calls_per_model`, Zahl der Modelle), aus den konstruierten Zeilen und aus den IDs der Antworten ab.
- **Erfundene Daten:** keine. Das Routing der Anfrage ersetzt keinen fehlenden Anbieter mehr. Testdaten sind als synthetisch gekennzeichnet, Schlüssel synthetisch.
- **Golden-Änderungen ohne ADR:** keine. `inst/extdata/` ist in Runde 3 unverändert (golden-adr pass).
- **Sichtbare Defekte:**
  - Nach einer frischen Erhebung meldet die Herkunftsprüfung „store unchanged“ (E34).
  - Der Berichtssatz „Reasoning is already included in completion_tokens.“ (`R/acmg.R:993`) trifft für die Qwen-Aufzeichnung nicht zu. Er folgt dem Wortlaut der Spec; der Builder ist gedeckt (E35).
  - Beobachtung ohne Befund: Fehlt `provider` in 30 Antworten, listet die Begründung alle 30 IDs in einer Zeile (≈ 1.150 Zeichen). Für die Stichprobe ist das zweckmäßig.
- **MUT-EQUIV:** keine Claims; deshalb keine `MUT-EQUIV-APPROVED.json`. mutgate meldet „kein geänderter Mutations-Scope“.
- **[INFRA] / [QA-PENDING]:** `[INFRA]` sind E28 bis E30; `[QA-PENDING]` gibt es nicht.

## Einwände

### Blocking

Keine. E31 ist behoben und unabhängig nachgeprüft (Nachprüfungen 2 bis 7).

### Minor (nonblocking)

- [E34] (minor) `docs/01` §2 Nr. 4 („klare Fehlermeldung“); ADR-010 Nr. 3.4 — Befund:
  - Die neue Meldung endet immer mit „store unchanged.“ (`R/acmg.R:647`). Bei Folgeaufrufen stimmt das, denn der Lesevorgang bricht vor jedem Aufruf ab.
  - Im ersten CLI-Pilot mit unbelegten Antworten liest `acmg_run_cli()` den Store aber erst nach `msa_run()` (`R/acmg.R:743–745`). Dann sind die 90 Aufrufe gerade gespeichert und bezahlt; „store unchanged“ führt in die Irre (Nachprüfung 6).
  - Die Wendung stammt aus der bisherigen Meldung; der Builder ist durch den Vorschlag der Runde 2 gedeckt.

  — Vorschlag: Wortlaut je Lage. Nach einer Erhebung etwa „stored calls are kept; no pilot report“, „store unchanged“ nur beim Lesen vor einem Aufruf. Das Verhalten bleibt unverändert. → BL-68.
- [E35] (minor) `docs/03` A.6 („`usage.completion_tokens`, schließt Reasoning ein“); ADR-006 Nr. 7.4; `ANK-94` — Befund:
  - Die Qwen-Aufzeichnung meldet 197 Reasoning-Tokens bei 157 `completion_tokens`. Abgerechnet sind 157 (Nachprüfung 9); die Kostenregel trifft also die Abrechnung.
  - Der Satz „Reasoning is already included in completion_tokens.“ im Berichtsabschnitt „Pilot measurements“ (`R/acmg.R:993`) gilt für diese Antwort aber nicht. Auch das berichtete Reasoning-Quantil von Qwen lässt sich dann nicht als Anteil von `completion_tokens` lesen.
  - Der Code folgt dem Wortlaut von A.6; für den Builder ist nichts zu tun.

  — Vorschlag: Der Betreiber prüft das Verhältnis im Pilot. Eine Grenze im AP1-Bericht oder eine geänderte Formulierung entsteht nur per ADR. → BL-69.
- [E26] (minor) ADR-006 Nr. 7.4; ADR-010 Nr. 6 — Befund: unverändert. Die Sperre ist belegt (`test-acmg-rework.R:215`, `test-acmg-pilot-metadata.R:89`), die Begründung jetzt vorhanden (E32). Das Pilot-Quantil liest weiter `evaluation.kappa_bootstrap.quantile_type` (`R/acmg.R:531`). — Vorschlag: bei Gelegenheit entkoppeln. → BL-64.
- [E28] (minor) [INFRA] `docs/03` A.7 (Logging-Regeln CoreWeave/DeepInfra aus `Provider_Logging.html`) — Befund: unverändert; der Textspiegel enthält je Anbieter 0 Treffer. — Vorschlag: Der Betreiber liefert datierte Belege vor dem AP1-Bericht. → BL-63.
- [E29] (minor) [INFRA] BL-56; PLAN-REVIEW E14 — Befund: `NOT_CRAN` steht weder in `orchestrator/lib/r-tests.R` noch in `config.env` (je 0 Treffer). `test-report.R:5` bleibt im Gate übersprungen (`gate-tests.log`: „On CRAN (1)“). — Vorschlag: Betreiberentscheidung. → BL-56.
- [E30] (minor) [INFRA] BL-48; `docs/gates-auswahl.md:87` („K-M2-1 bis K-M2-6“) — Befund: unverändert; trace ist nicht betroffen. — Vorschlag: Der Betreiber ergänzt K-M2-7. → BL-48.

## Backlog-Pflege in dieser Phase

- **BL-66** und **BL-67** gestrichen: E32 und E33 sind umgesetzt und belegt. Den Restpunkt zum Wortlaut führt **BL-68**.
- **BL-07** fortgeschrieben: E31 ist behoben; offen bleibt der Betrieb (Stichprobe, Wiederholungstag).
- **BL-13** fortgeschrieben: Gate-Laufzeiten der Runde 3.
- **BL-48**, **BL-56**, **BL-63** und **BL-64** fortgeschrieben.
- Neu sind **BL-68** (E34) und **BL-69** (E35).

## Verdict

**PASS.**

- `gates.json` der Runde 3 meldet `result: pass`; alle acht Gates sind `pass`, keines `error`.
- Der einzige Blocking-Befund der Runde 2, E31, ist behoben und unabhängig nachgeprüft: Pilotbericht, Resume, Sperre und Auswertung bei fehlendem `provider` (Nachprüfungen 2 bis 5). Der neue Testblock greift am alten Code (Nachprüfung 7).
- `blocking` ist leer. E34, E35, E26 und E28 bis E30 sind nonblocking und stehen in `BACKLOG.md`.
- Ein Widerspruch zwischen Spec-Stellen, der `ESCALATE` verlangte, liegt nicht vor.
