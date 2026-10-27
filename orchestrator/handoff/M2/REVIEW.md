# REVIEW — M2, Runde 1 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde 1 · Stand: 27.10.2026 · Gegenstand: Diff seit `plan/M2` (Tag-Objekt `9d91937d…` → Commit `f4b81117…`) bis HEAD `ce296200…` sowie die Gate-Fakten `orchestrator/state/M2/gates.json` der Runde 1 (Lauf nach QA).

## Gelesen

- Rollen und Protokoll: `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- Handoff M2: `CRITERIA.json` (K-M2-1 bis K-M2-7, ACC-1 bis ACC-25), `PLAN.md`, `PLAN-UPDATE.md`, `PLAN-REVIEW.md` und `verdict-plan.json` (Runde 2), `QA.md`.
- Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`, `MUT-EQUIV.json`.
- Spezifikation: `docs/03-anwendungspipeline.md` vollständig, `docs/01-fachspezifikation.md` §1 bis §9, ADR-005 bis ADR-007 (Reviewer), ADR-008 und ADR-009 (Builder, im Diff).
- Gates: `gates.json` mit allen acht `gate-*.log`; `gates.json` des Laufs vor QA (Commit `b635395`); `orchestrate.sh` (`path_allowed`, `run_ms`).
- Diff: alle Builder- und QA-Dateien, insbesondere `R/acmg.R` vollständig, die Änderungen an `R/backends.R`, `R/parse.R`, `R/run.R`, `R/report.R` und `inst/templates/validation_report.Rmd`.
- Dazu `inst/validation/ap1/{run.R,plan.yaml,README.md}`, `data-raw/make_items_ap1.R`, `DESCRIPTION`, `NEWS.md`, die Rd-Änderungen, die neuen Unit-Tests, `tests/e2e/test-m2-qa-e2e.R`, `tests/fuzz/test-m2-qa-fuzz.R`, `PROGRESS.md` und `BACKLOG.md`.
- Abnahmetests: `test-m2-6-evaluate.R`, `test-m2-7-robustness-pilot.R`, `setup-m2.R` Z. 590–906.
- Visuelle Artefakte gibt es nicht: `orchestrator/state/M2/shots/` ist leer, die Berichte entstehen außerhalb des Repos.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

Ohne Freigabe blieben Python, `diff` und Schreibzugriffe außerhalb des Arbeitsbaums über die Dateiwerkzeuge. Gerechnet wurde deshalb mit `Rscript`, lesend gegen das Repo. Geschrieben wurde nur unter `/tmp/rv-m2/`: Skripte, Basis-Blobs und eine Paketkopie für `pkgload::load_all()`.

1. **Diff `plan/M2` → HEAD**, gelesen aus `.git/objects/` (lose Objekte und Pack-Datei mit Deltas, eigener R-Leser). Die Phasen-Commits sind `4187c51` (builder 40-build r1), `b635395` (gates r1, rc=0), `a818d5b` (qa 45-qa r1) und `ce29620` (gates r1, rc=1).
   - Builder, hinzugefügt: `R/acmg.R`, `data-raw/make_items_ap1.R`, `inst/extdata/items_ap1_2026-10-24/{items.csv,pilot.csv,QUELLE.txt,SHA256SUMS}`, `inst/validation/ap1/{plan.yaml,README.md,run.R}`, `man/acmg.Rd`, ADR-008, ADR-009, `tests/testthat/{helper-acmg.R,test-acmg-api.R,test-acmg-data.R,test-acmg-evaluate.R,test-acmg-pipeline.R,test-parsers.R}`.
   - Builder, geändert: `R/{backends,parse,report,run}.R`, `inst/templates/validation_report.Rmd`, `man/{backends,msa_report,msa_run,parsers}.Rd`, `DESCRIPTION`, `NEWS.md`, `PROGRESS.md`, `tests/testthat/test-report.R`.
   - QA: `tests/e2e/test-m2-qa-e2e.R`, `tests/fuzz/test-m2-qa-fuzz.R`, `orchestrator/handoff/M2/QA.md`. Sonst nur Orchestrator-Zustand und `STATUS.md`.
   - Unverändert sind `tests/acceptance/**`, `tests/fixtures/**`, `reference/anchors/**`, `R/fit.R`, `R/grr.R`, `NAMESPACE`, `.Rbuildignore`, `orchestrator/gates.d/**` und `orchestrator/lib/**`.
2. **Arbeitsbaum gleich HEAD:** Für alle 34 Pfade des Diffs außerhalb von `orchestrator/state/` gleicht die Blob-ID (SHA-1 über `blob <n>\0<inhalt>`) dem HEAD-Baum.
3. **Gates vor QA:** `gates.json` in `b635395` meldet `result: pass`, alle acht Gates auf `pass`, tests „Kommando erfolgreich“. Rot ist nur der Lauf nach QA.
4. **QA-Ursachen, minimal reproduziert** (Paketkopie, direkte Aufrufe):
   - QA-M2-001: `acmg_repeat_day()` auf den Zeilen nur von Sol liefert sechs Zeilen. Für Llama und Qwen stehen dort `FALSE` und `backend_error_share = NA`.
   - QA-M2-002: Llama mit einer CoreWeave-Zeile und einer Zeile ohne `provider` ergibt `provider_change = FALSE`, ebenso Llama nur mit Zeilen ohne `provider`.
   - QA-M2-003: Ein API-Store mit einer fehlerfreien Zeile ohne `meta` wird ohne Abbruch gelesen, `provenance = api`. Mock-Zeilen mit einer Zeile ohne `meta` ergeben `unverified`.
   - QA-M2-004: Fehlt einem Modell ein ERepo-Item ganz, hat `modal` 99 Zeilen, das Item fehlt, und `n_no_modal` ist 0. In den PB-Läufen ist `reference_n` 74, obwohl die PB-Zeilen 75 ERepo-Referenzen tragen.
   - QA-M2-005: Eine PB-Zeile mit `rep = 2` ergibt `complete = TRUE` mit Band `acceptable`. Eine PB-Zeile mit „Likely Pathogenic“ zählt still als Nichtübereinstimmung (x = 99 von 100).
5. **Pilotregeln ADR-006 Nr. 7, unabhängig nachgerechnet.** Zugesagt war das in PLAN-REVIEW, Abschnitt Vollständigkeit. Die Mini-Referenz folgt dem Wortlaut von Nr. 7.1 bis 7.5, mit eigener HTTP-Status-Erkennung und eigenem Quantil. Sie lief auf 15 konstruierten Pilot-Stores mit je 90 Zeilen. 14 Fälle sind in allen 12 Regeln und in den Kosten je Modell identisch:
   - Basis S = 20,60239 USD (17,13 + 2,525115 + 0,94728), von Hand gleich.
   - HTTP 429 und HTTP 400 → `4xx failed`. HTTP 500 und ein Timeout → `4xx passed`.
   - Anbieter fehlt oder falsch → `provider failed`.
   - 26 Treffer → `parser failed`, 27 Treffer → `passed`; 29 Zeilen oder ein doppelter Schlüssel → `failed`.
   - S = 159,4724 → `cost failed`, S = 147,4724 → `passed`. Fehlende `usage` oder nur Mock → `cost failed`.
   - Abweichung im 15. Fall: Eine fehlerfreie Sol-Zeile ohne `id` lässt im Code auch `cost` für alle Modelle scheitern. Nach dem Wortlaut von Nr. 7.4 bestünde `cost` (E26).
6. **API und Vorgabewerte (BL-57):** `NAMESPACE` ist unverändert; es gibt keinen neuen Export. Neu angehängt sind genau `parse_choice(…, whole_word = FALSE)`, `msa_run(…, parse_by_prompt = NULL)` und `msa_report(…, assessment = NULL)`, je am Ende und mit Vorgabe (`formals()`). `backend_openai_compatible()` endet unverändert auf `timeout = 120, ...`.
7. **ADR-009:** Der Serializer von v0.1.0 schreibt `usage.cost = 0.00004615` (aus `tests/fixtures/api/llama.json`) als `0`. Mit `digits = 17` ist der Rundweg für 4,615e-05, 0,1, 1/3, 308L und 1e-12 identisch. Die Darstellung wird länger (`0.10000000000000001`), ist aber exakt. ADR-009 ist sachlich richtig.
8. **A.7, Logging-Regeln:** `../quellen/anbieter_2026-10-22/openrouter/Provider_Logging.html` ergibt ohne Tags 4.659 Zeichen Text, darin 0 Treffer für CoreWeave oder DeepInfra. Die Angabe des Builders (M2-BUILD-INFRA-02) stimmt (E28).
9. **Weitere Regeln:**
   - Kein `mclapply`, `mcmapply`, `mcparallel`, `pvec` oder `multicore` in den geänderten R-Dateien.
   - `data-raw/make_items_ap1.R` liest Seeds, Zahlen und Hashes aus den Ankern. Es prüft die Quell-Hashes, bricht ohne `../quellen/daten/` benannt ab und lädt nichts herunter.

## Gate-Fakten

`gates.json`: `milestone` M2, `round` 1, `base` `f4b81117…` (`baseRef` `plan/M2`), `env.sha` `a818d5bf…` (QA-Commit), R 4.6.1, pandoc 3.7.0.2, `result` **fail**.

| Gate | Status | Kurzbefund |
| --- | --- | --- |
| deps | pass | 18 Anforderungen erfüllt; neu `digest`, `pkgload`, `yaml` (Suggests) |
| lint | pass | `R CMD check --as-cran --no-manual`: `Status: OK` |
| tests | **fail** | „5 fehlgeschlagen, 0 Fehler, 2 übersprungen“ über 141 Tests |
| trace | pass | alle Kriterien wörtlich und beidseitig verknüpft |
| territory | pass | letzter Diff sauber (qa/45-qa, Runde 1) |
| mutgate | pass | kein geänderter Mutations-Scope |
| golden-adr | pass | Änderung und ADR (ADR-008) im selben Meilenstein |
| mutfull | pass | nicht fällig in M2 |

Aufschlüsselung des Test-Gates:

| Ordner | Ergebnis |
| --- | --- |
| `tests/testthat` | 59 Blöcke, `FAIL 0 / WARN 0 / SKIP 2 / PASS 676`; Skips wie in M0 (`test-report.R:5`, `test-backends.R:32`) |
| `tests/acceptance` | 77 Blöcke (M0 15, M2 62), `FAIL 0 / SKIP 0 / PASS 2340` in 930,5 s |
| `tests/e2e` | 4 Blöcke, alle rot: QA-M2-001 bis -004, 8 Erwartungen |
| `tests/fuzz` | 1 Block, rot: QA-M2-005, 5 Erwartungen |
| `tests/simulation` | keine Testdateien |

- Der Socket-Fehler aus PROGRESS (M2-BUILD-INFRA-01) tritt im Gate nicht auf. `m2-4-backends` ist mit 89 Erwartungen grün, `m2-7-robustness-pilot` mit 375. Der Punkt ist erledigt.
- `m0-r-unchanged` ist mit 55 Erwartungen grün, nun erstmals mit echtem `done/M0` (BL-53).
- Laufzeit des Gate-Laufs nach QA: 03:50:22 bis 04:07:33, also ≈ 17 min. Davon tests ≈ 16 min (Abnahme 930,5 s, darin `m2-3-prompts-parser` 492 s) und lint ≈ 1 min. Der Lauf vor QA dauerte ebenfalls ≈ 17 min (BL-13).

## QA-Befunde: Einzelbewertung

Reproduzierende QA-Tests sind blocking, außer eine Herabstufung ist begründet. Dazu kommt ein Verfahrensgrund: `tests/e2e/` und `tests/fuzz/` schreibt nur QA, und QA läuft je Meilenstein einmal. Ein herabgestufter, weiter roter QA-Test hielte das Test-Gate dauerhaft rot. Eine Herabstufung wäre also nur richtig, wenn die Erwartung des Tests der Spec widerspräche. Das trifft auf keinen der fünf zu:

| QA | Ursache bestätigt | Erwartung spec-treu | Konflikt mit Abnahme | Entscheidung |
| --- | --- | --- | --- | --- |
| QA-M2-001 | ja, `R/acmg.R:962`, `:1033–1037` | ja: docs/01 §2 Nr. 4, ADR-006 Nr. 7.8 | nein | blocking (E21) |
| QA-M2-002 | ja, `R/acmg.R:568–571` | ja: ADR-006 Nr. 7.8 mit Nr. 7.2; Auslegung in ADR-010 Nr. 2 | nein | blocking (E22) |
| QA-M2-003 | ja, `R/acmg.R:458–459` | ja: ADR-006 Nr. 9, PLAN-UPDATE E3, PLAN-REVIEW E16 | nein | blocking (E23) |
| QA-M2-004 | ja, `R/acmg.R:789`, `:867–870` | ja: K-M2-6, A.7, ADR-006 Nr. 8.1 und 11 | nein (`acc_m2_check_model()` vergleicht über die Items der Hauptplanzeilen) | blocking (E24) |
| QA-M2-005 | ja, `R/acmg.R:985–988`, `:861–864` | ja: ADR-005 Nr. 1, ADR-006 Nr. 8.2 mit PLAN-UPDATE E7 | nein (Abnahme-PB mit `rep = 1`, `block = 1`) | blocking (E25) |

Wo die Spec zu diesen Randfällen schweigt, legt ADR-010 die Auslegung bindend fest. Alle fünf Behebungen sind klein, verlangen keine Teständerung und lassen die Abnahmetests grün.

## Bewertung je Kriterium

- **K-M2-1 erfüllt.** Gate: `m2-1-items` 149 Erwartungen grün, einschließlich byte-identischer Neuerzeugung, `QUELLE.txt` und `SHA256SUMS`. ADR-008 deckt die Golden-Erzeugung. Die INSAID-Felder `reference`, `protein`, `panel` und die Kennzeichen sind leer (ADR-005 Nr. 2, `docs/01` §7).
- **K-M2-2 erfüllt.** `m2-2-memorisation` 34 grün; die Kombination folgt ADR-005 Nr. 6.
- **K-M2-3 erfüllt.** `m2-3-prompts-parser` 837 grün. `parse_choice(whole_word)` entspricht ADR-007 Nr. 1. Der JSON-Parser fällt nicht auf den Volltext zurück (`R/parse.R:113–137`).
- **K-M2-4 erfüllt.** `m2-4-backends` 89 grün:
  - `temperature = NULL` lässt das Feld weg; `NEWS.md` nennt die Änderung.
  - `meta` enthält `model_snapshot`, `id`, `usage`, `system_fingerprint`, gegebenenfalls `provider` und das Routing aus der Anfrage.
  - ADR-009 behebt den Rundungsfehler beim Speichern (Nachprüfung 7).
- **K-M2-5 erfüllt.** `m2-5-plan` 106 grün. Der Pilot rechnet die Kosten mit 3.000 Aufrufen; Nachprüfung 5 bestätigt den Rechenweg.
- **K-M2-6 nicht abnahmefähig.** Die Abnahme ist grün (`m2-6-evaluate` 374): Modalantwort, Kappa mit Bootstrap, Trefferquoten, NA-Anteil, gefährliche Fehler, Fit und Rückfall, Verdikte, gemeinsamer Fit und Berichte. Für Randfälle derselben Auswertung verletzen E21, E23 und E24 aber `docs/01` §2 Nr. 4 und ADR-006.
- **K-M2-7 nicht abnahmefähig.** Die Abnahme ist grün (`m2-7-robustness-pilot` 375). E22 (Wiederholungstag) und E25 (PB-Zeilen) betreffen die Robustheits- und Laufpfade.

## Prüfliste aus dem Auftrag

- **Spec- und Vertragstreue:**
  - Die vier `acmg_*`-Einstiegspunkte haben die Signaturen aus `docs/03`, sind intern (`man/acmg.Rd`, `@keywords internal`) und werden nicht exportiert.
  - ADR-005 bis ADR-007 sind umgesetzt.
  - Abweichungen: E21 bis E25 (blocking) und E26 (strenger als ADR-006 Nr. 7.4, durch ADR-010 Nr. 6 bestätigt).
- **API-Diff:** nur additive, angehängte Argumente mit Vorgabe (Nachprüfung 6). `docs/01` §4 ist eingehalten, BL-57 für M2 erledigt.
- **Entkernte Tests:** keine. In `tests/testthat/test-report.R` kamen nur zwei Blöcke hinzu; Bestandstests, Abnahmetests und Fixtures sind unverändert.
- **Gelockerte Konfiguration:** keine. `DESCRIPTION` ändert nur Suggests und `RoxygenNote`. `.Rbuildignore` und die Gate-Skripte sind unverändert. `R CMD check` ergibt `Status: OK`.
- **Harte Erwartungswerte:** keine gefunden. Schwellen, Seeds, Zählungen und Preise stammen aus `plan.yaml` und den Ankern. Die Streuungen des Mock-Backends sind ausdrücklich synthetisch (`R/acmg.R:298–316`) und lesen keine Referenz.
- **Erfundene Daten:** keine. Mock-Ergebnisse sind gekennzeichnet. Für CoreWeave und DeepInfra wird keine Aufbewahrungsdauer behauptet (E28). Der Itemsatz entsteht nur aus den hash-geprüften Quellen.
- **Golden-Änderungen ohne ADR:** keine (ADR-008; Gate golden-adr pass).
- **Sichtbare Defekte:**
  - Berichte: Wiederholungstagstabelle mit fremden Modellen (E21); verdeckte fehlende Felder (E27).
  - Herkunft: falsche Kennzeichnung `api` bzw. `unverified` (E23).
  - Zählungen: Itembasis 99 statt 100 und `reference_n` 74 statt 75 (E24).
- **MUT-EQUIV:** keine Claims; daher keine `MUT-EQUIV-APPROVED.json`. mutgate meldet „kein geänderter Mutations-Scope“.
- **Gate-Status `error`:** bei keinem Gate. `[INFRA]` sind E28 bis E30; `[QA-PENDING]` gibt es nicht.

## Planhinweise und offene Punkte

- **E16:** umgesetzt sind das Zusatzfeld `provenance`, der Hinweis im Titel und die unveränderten Bänder. „Nie als `api`“ ist verletzt (E23).
- **E17:** umgesetzt: nur SQLite-Stores.
- **E18:** umgesetzt (README, Abschnitt API collection).
- **E19:** umgesetzt (`reference_basis`, Hinweis ohne `--insaid-path`). Lücke bei fehlenden Items: E24.
- **E20:** Laut PROGRESS ergab der Mock-Hauptlauf keine Fit-Warnung. `acc_m2_with_conditions()` muss deshalb nicht angeglichen werden.
- **ADR-006, Konsequenz zu Nr. 10:** Ein nicht definiertes Kappa tritt in den Testdaten nicht auf; `acc_m2_band_kappa()` bleibt unverändert.
- `CRITERIA.json` bleibt unverändert. ACC-1 bis ACC-25 sind durch ADR-005 bis ADR-007 und den PLAN festgelegt.

## Einwände

### Blocking

- [E21] (blocking) Gate tests (`gate-tests.log`: `test-m2-qa-e2e.R:93`, `:96`; QA-M2-001); `docs/01` §2 Nr. 4 („nie stillschweigend eine falsche Zahl“); ADR-006 Nr. 7.8; ADR-010 Nr. 1 — Befund: `acmg_assessment()` übergibt `acmg_repeat_day()` nur die Hauptplanzeilen des berichteten Modells (`R/acmg.R:962` mit `:1033–1037`). `acmg_repeat_day()` iteriert aber über alle drei Planmodelle (`:564`). Jeder Bericht weist deshalb für die beiden anderen Modelle Zeilen mit `provider_change`, `model_change` und `error_trigger` gleich `FALSE` sowie `backend_error_share = NA` aus, auch wenn diese Modelle Auslöser haben. — Vorschlag: Je Bericht nur die Zeilen des eigenen Modells, oder alle Modelle aus allen Hauptplanzeilen (ADR-010 Nr. 1). `run.R` bleibt unverändert.
- [E22] (blocking) Gate tests (`test-m2-qa-e2e.R:135`, `:136`; QA-M2-002); ADR-006 Nr. 7.8 („ein `provider`, der vom angeforderten abweicht“) mit Nr. 7.2 („Fehlt das Feld in der Antwort, ist die Regel nicht bestanden“); `docs/03` A.6; ADR-010 Nr. 2 — Befund: ``unique(unlist(lapply(m, `[[`, "provider")))`` (`R/acmg.R:568`) verwirft fehlende Felder. Eine fehlerfreie OpenRouter-Zeile ohne `provider` ergibt deshalb `provider_change = FALSE`, mit oder ohne weitere CoreWeave-Zeilen (Nachprüfung 4). — Vorschlag: Für Modelle mit `provider_name` zählt eine fehlerfreie Zeile mit fehlendem oder leerem `provider` als Abweichung (ADR-010 Nr. 2); Sol bleibt unberührt. Die gleiche Ursache im Bericht behandelt E27.
- [E23] (blocking) Gate tests (`test-m2-qa-e2e.R:166`, `:175`; QA-M2-003); ADR-006 Nr. 9 („Ergebnisse und Berichte aus Mock-Zeilen kennzeichnet es sichtbar als synthetisch“); PLAN-UPDATE E3, akzeptiert („… bei einem vorhandenen Store nicht belegbare Herkunft führt zum benannten Abbruch; sie wird nicht als API-Herkunft geraten“); PLAN-REVIEW E16; ADR-010 Nr. 3 — Befund: Ist eine Store-Kennung gesetzt, übernimmt `acmg_provenance()` sie und prüft fehlerfreie Zeilen ohne Beleg nicht mehr (`R/acmg.R:458–459`).
  - Ein API-Store mit einer fehlerfreien Zeile ohne `meta` wird gelesen und als `api` zertifiziert.
  - Ohne Kennung wird aus Mock-Daten mit einer einzigen Zeile ohne `meta` `unverified` statt `synthetic`.

  Beides widerspricht auch der eigenen README (`inst/validation/ap1/README.md:113`: „never represented as an API collection“). — Vorschlag: Herkunft nach ADR-010 Nr. 3.1 bis 3.3 bestimmen. `acmg_store_read()` vergleicht wie bisher mit `--backend` und bricht damit für einen API-Store mit nicht belegten fehlerfreien Zeilen benannt ab (Nr. 3.4). Die bestehenden Unit-Fälle (`test-acmg-pipeline.R:86–113`) bleiben gültig.
- [E24] (blocking) Gate tests (`test-m2-qa-e2e.R:212`, `:219`; QA-M2-004); K-M2-6 („die Modalantwort je Item … die Zahl solcher Items wird berichtet“); `docs/03` A.7 („Zahl der Items ohne Modalantwort“); ADR-006 Nr. 8.1 („rechnet … die Kennzahlen und kennzeichnet das Ergebnis als unvollständig, mit den Zählungen“) und Nr. 11; `docs/01` §2 Nr. 4; ADR-010 Nr. 4 — Befund: `acmg_modal_table()` bildet die Itemliste aus den vorhandenen Zeilen des Modells (`R/acmg.R:789`). Fehlt ein Item im Hauptplan eines Modells ganz, gilt Folgendes (Nachprüfung 4):
  - Das Item fehlt in `modal`, `n_no_modal` ist 0, und `reference_basis` summiert sich auf 99.
  - `acmg_robustness()` liest die Referenz der PB-Zeilen aus `modal` (`:867–870`). `reference_n` sinkt deshalb in allen zwölf Läufen auf 74, obwohl die PB-Zeilen 75 Referenzen tragen.

  — Vorschlag: `modal` über alle Items aus `items.csv`. Ein Item ohne Zeilen bekommt `has_modal = FALSE` und zählt in `n_no_modal` und `excluded_no_modal`; seine Merkmale kommen aus `runs`. Die PB-Referenz kommt aus den PB-Zeilen (ADR-010 Nr. 4). Verdikte bleiben „not assessed“.
- [E25] (blocking) Gate tests (`test-m2-qa-fuzz.R:76`, `:92`, `:93`, `:98`, `:99`; QA-M2-005); ADR-005 Nr. 1 („`reference` und alle Klassenwerte der Pipeline tragen die Bezeichnungen von A.3“); `docs/01` §2 Nr. 4; ADR-006 Nr. 8.2 mit PLAN-UPDATE E7, akzeptiert („Fehlende/zusätzliche oder doppelte Zeilen verhindern eine vollständige Bewertung“); ADR-010 Nr. 5 — Befund:
  - Die Klassenprüfung von `acmg_evaluate()` erfasst nur Hauptplanzeilen (`R/acmg.R:985–988`). Eine PB-Zeile mit „Likely Pathogenic“, „VOUS“ oder einer erfundenen Klasse zählt still als Nichtübereinstimmung und verschiebt Logit, Effekte, Δp und Band.
  - `acmg_robustness()` prüft nur die Zählung je Item und Prompt (`:861–864`). Eine PB-Zeile mit `rep = 2` oder `block = 2` ergibt `complete = TRUE` und ein Band.

  — Vorschlag: Klassenprüfung über alle ausgewerteten Zeilen, mit derselben Meldung. Robustheit nur mit den Designschlüsseln des PB-Plans: `rep` in `seq_len(plan$robustness$replicates)`, `block = 1`, kein doppelter `run_key`. Sonst `complete = FALSE` und „not assessed“ mit Begründung (ADR-010 Nr. 5).

### Minor (nonblocking)

- [E26] (minor) ADR-006 Nr. 7.2 und 7.4; PLAN-UPDATE E2 (Tabelle, Zeile `cost`); ADR-010 Nr. 6 — Befund: Die Nachrechnung der Pilotregeln (Nachprüfung 5) weicht nur bei einer fehlerfreien Zeile ohne `id` ab. Der Code lässt dann `provider` des Modells und `cost` aller Modelle scheitern (`R/acmg.R:499`, `:502`, `:523`); nach dem Wortlaut von Nr. 7.4 bestünde `cost`. Das ist strenger als der Wortlaut, die Sperre nach Nr. 7.7 wirkt gleich, und PROGRESS nennt es nicht als Planergänzung. Nebenbei liest das Pilot-Quantil `type` aus `evaluation.kappa_bootstrap.quantile_type` (`:521`) statt fest 7 nach Nr. 7.4; gleichwertig, solange der Plan 7 trägt. — Vorschlag: keine Codeänderung; ADR-010 Nr. 6 bestätigt die strengere Regel. Bei Gelegenheit das Quantil vom Bootstrap-Feld entkoppeln. → BL-64.
- [E27] (minor) `docs/03` A.7 („Modellkennungen, Anbieter, Quantisierung und Wissensstand je Modell“); `R/acmg.R:906–909`, `:930–935` — Befund: `reported()` im Abschnitt „Model and routing“ verwirft fehlende Felder wie in E22. Fehlt `provider` oder `system_fingerprint` in einem Teil der Zeilen, nennt der Bericht nur die vorhandenen Werte. Nach E22 zeigt die Wiederholungstagstabelle desselben Berichts das Fehlen; der Abschnitt selbst bleibt still. — Vorschlag: zusätzlich die Zahl der fehlerfreien Zeilen ohne `provider` und ohne `system_fingerprint` nennen, im selben Zug wie E22. → BL-65.
- [E28] (minor) [INFRA] `docs/03` A.7 („die Logging-Regeln der OpenRouter-Anbieter CoreWeave und DeepInfra aus `quellen/anbieter_2026-10-22/openrouter/Provider_Logging.html`“); PROGRESS M2-BUILD-INFRA-02 — Befund: Der Schnappschuss enthält keine Zeile zu CoreWeave oder DeepInfra (Nachprüfung 8). `plan.yaml` und die Berichte nennen die Lücke, statt eine Aufbewahrung zu erfinden; das ist richtig. — Vorschlag: Der Betreiber liefert vor dem AP1-Bericht datierte anbieterspezifische Belege. Der Reviewer übernimmt sie per Anker und ADR; der Builder ergänzt dann die Policy in `plan.yaml`. Für den Builder jetzt nichts zu tun. → BL-63.
- [E29] (minor) [INFRA] BL-56; PLAN-REVIEW E14 — Befund: `NOT_CRAN` ist weiter weder in `config.env` noch in `r-tests.R` gesetzt. Der Bestandstest `test-report.R:5` bleibt übersprungen. Neu rendert `test-report.R:36` (ohne `skip_on_cran()`) im Gate drei AP1-Berichte über `msa_report(assessment = …)`. Damit prüft ein Gate das Rendern, den generischen Bericht ohne `assessment` aber weiter nicht. — Vorschlag: Der Betreiber entscheidet über `NOT_CRAN=true`. → BL-56 fortgeschrieben.
- [E30] (minor) [INFRA] BL-48; PLAN-REVIEW E15; `docs/gates-auswahl.md:87` („K-M2-1 bis K-M2-6“) — Befund: Die Zuordnung nennt K-M2-7 weiter nicht; trace ist nicht betroffen. — Vorschlag: Der Betreiber ergänzt K-M2-7. → BL-48 fortgeschrieben.

## ADR in dieser Phase

`docs/decisions/ADR-010-m2-randfaelle-wiederholungstag-herkunft-vollstaendigkeit.md` legt die Reviewer-Auslegung zu E21 bis E26 fest. Nr. 1 bis 5 sind die Behebung der QA-Befunde. Nr. 6 bestätigt das strengere Pilotverhalten ohne Codeänderung. Abnahmetests, Anker und `CRITERIA.json` ändern sich nicht.

## Für die Rework-Runde

- E21 bis E25 nach ADR-010 beheben, je mit einem Unit-Test ohne Netz unter `tests/testthat/`.
- `tests/e2e/`, `tests/fuzz/`, `tests/acceptance/` und die Fixtures bleiben unberührt.
- Danach müssen alle Ordner des Test-Gates grün sein, einschließlich der unveränderten QA-Tests.
- In `PROGRESS.md` die echten Outputs nachtragen und E21 bis E27 Punkt für Punkt beantworten.
- E27 ist erwünscht, nicht blocking; E26 und E28 bis E30 verlangen vom Builder nichts.

## Backlog-Pflege in dieser Phase

- **BL-53** gestrichen: `m0-r-unchanged` ist im Test-Gate von M2 grün (55 Erwartungen).
- **BL-54** gestrichen: `PROGRESS.md` trägt den Abschnitt „M0 — Abschlussnachtrag im M2-BUILD“.
- **BL-16** gestrichen: K-M2-4 ist im Gate grün.
- **BL-57** fortgeschrieben: Prüfung für M2 erledigt; die Pflicht bleibt für spätere Meilensteine.
- **BL-07** fortgeschrieben: Stand nach M2, Auslöser bei fehlendem Anbieter offen bis E22.
- **BL-13** fortgeschrieben: Gate-Laufzeiten von M2.
- **BL-62** fortgeschrieben: Grenze im Plan und im Bericht genannt.
- **BL-48** und **BL-56** fortgeschrieben (E30, E29).
- Neu sind **BL-63** (E28), **BL-64** (E26) und **BL-65** (E27).

## Verdict

**REWORK.** `gates.json` meldet `result: fail`. Das Test-Gate ist rot, allein durch die fünf reproduzierenden QA-Befunde; alle 2.340 Abnahme-Erwartungen und alle Unit-Tests sind grün. E21 bis E25 sind blocking und tragen je eine `ref` aus Gate und Spec- oder ADR-Stelle. Ein Widerspruch zwischen Spec-Stellen, der `ESCALATE` verlangte, liegt nicht vor; wo die Spec schweigt, bindet ADR-010.
