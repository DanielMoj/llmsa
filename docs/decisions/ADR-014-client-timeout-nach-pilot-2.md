# ADR-014 — Client-Timeout nach Pilot 2: `timeout_s` im Plan und fünfte Pilotregel

## Status

Angenommen (Betreiber, 28.10.2026; Betreiberänderung nach BL-01). Bindend ab Pilot 3.

## Kontext

- Pilot 2 (A.6, ADR-013 Nr. 5) lief am 28.10.2026 von 08:15 bis 09:03 (MEZ): 90 Aufrufe, je Modell 10 Pilotitems × 3 Vorlagen. Belege: Log `unterlagen/ap1/pilot2_2026-10-28.log` (Betreiberunterlage außerhalb des Repos), Store `llmsa-runs/ap1_runs_2.sqlite`, Kopie `llmsa-runs/ap1_runs_2_nach_pilot.sqlite` (A.8 Nr. 4); beide haben dieselbe SHA-256 (unten).
- Befund, an einer Kopie des Stores nachgerechnet:
  - Alle vier damals geltenden Regeln sind bestanden, Qwen mit 27 von 30 erkannten Klassen (verlangt mindestens 27, `ANK-67`).
  - Die drei fehlenden Klassen sind keine Parserfehler, sondern Backendfehler, alle drei mit der Vorlage `role`: Start 08:36:10, 08:54:48 und 08:56:48, Latenz je 120,0 s, Meldung „Timeout was reached [openrouter.ai]: Operation timed out after 120002 milliseconds with 334 bytes received“. Die Pilotausgabe zeigt das nicht; sie meldet nur „27 recognized of 30 planned“.
  - 120 s ist der Vorgabewert von `backend_openai_compatible()` (`R/backends.R`). `acmg_api_backends()` übergab keinen Wert; `plan.yaml`, docs/03 und die Anker nannten ihn nicht.
  - Vier weitere Qwen-Aufrufe kamen nach 113,4 bis 118,9 s an. Latenz der 27 fehlerfreien Qwen-Aufrufe: Median 61,3 s, Maximum 118,9 s, vier über 100 s. Zum Vergleich Pilot 1 (27.10.2026, 30 fehlerfreie Qwen-Aufrufe): Median 39,6 s, Maximum 91,8 s, keiner über 100 s.
  - Durchsatz `usage.completion_tokens`/`latency_s` der fehlerfreien Qwen-Zeilen, in beiden Pilots derselbe Endpunkt `deepinfra/fp8` mit Anbieter DeepInfra: Pilot 1 Median 32,2 Tokens/s, Minimum 20,1; Pilot 2 Median 17,8, Minimum 11,8. Ob ein Aufruf abbricht, hängt also von der Last beim Anbieter ab, und lange Reasoning-Ketten fallen bevorzugt aus.
  - Sol und Llama hatten keinen Backendfehler. Mittel je Aufruf über alle Zeilen: Sol 27,9 s, Qwen 68,2 s (mit den drei Abbrüchen), Llama 0,4 s.
- Folge für den Hauptplan: Qwen hat 900 Aufrufe je Block. Bei 10 % Abbrüchen (3 von 30; 95-%-Intervall nach Clopper-Pearson 2,1 bis 26,5 %) löst der Wiederholungstag (Fehleranteil über `error_share_trigger` 0,05; `acmg_repeat_day()`) fast sicher aus, und eine Wiederholung beseitigt die Ursache nicht.
- OpenRouter: Nicht gestreamte Anfragen laufen nach einem Abbruch weiter und werden voll berechnet („For non-streaming requests or unsupported providers, the model will continue processing and you will be billed for the complete response.“). Die drei Aufrufe sind also berechnet, ohne `usage` im Store.
- `max_completion_tokens` des Endpunkts `deepinfra/fp8` für `qwen/qwen3-32b` ist 16384, in den Endpunktlisten vom 27.10. und vom 28.10.2026 gleich.
- Quellen:
  - Store von Pilot 2 und Kopie: `llmsa-runs/ap1_runs_2.sqlite`, `llmsa-runs/ap1_runs_2_nach_pilot.sqlite`, SHA-256 `0b5b2a1c81a83dab585b76b894f1b96d780324abfd50b55af55c4665584f7514`;
  - Store von Pilot 1 (Kopie): `llmsa-runs/ap1_runs_nach_pilot.sqlite`, SHA-256 `ad45ee49f537f331d6bca7778f583a42cda87a3908658a8b47a2865293c8fe77`;
  - OpenRouter-Doku „API Streaming“: `quellen/anbieter_2026-10-28/openrouter/openrouter_docs_api_reference_streaming.md`, Z. 131, SHA-256 `1fbdb8e87859af6717aa75fc741a78d8aba4aabb739872656fcf60e6272d01ce`;
  - OpenRouter-Endpunktliste `qwen/qwen3-32b` vom 27.10.2026: `quellen/anbieter_2026-10-27/openrouter/openrouter_api_v1_endpoints_qwen3-32b.json`, SHA-256 `118c672ea76509e676d832964e4a208df1aa78e13b26684ee492bbe339775c18`;
  - dieselbe Liste vom 28.10.2026: `quellen/anbieter_2026-10-28_preise/openrouter/openrouter_api_v1_endpoints_qwen3-32b.json`, SHA-256 `50d639d3d4c69b0e063780baf25654a5b9bfa97c5aa09d7380c1b9132facd2c6`.

## Entscheidung

1. (E1) Timeout: In `plan.yaml` erhält jedes Modell das Pflichtfeld `timeout_s`, für alle drei 1800. `acmg_validate_plan()` verlangt dort eine endliche Zahl über 0, und `acmg_api_backends()` übergibt sie als `timeout` an `backend_openai_compatible()`. Herleitung: Beim langsamsten beobachteten Durchsatz von 11,8 Tokens/s brauchen die 16384 Tokens von `max_completion_tokens` 1388 s; 1800 s reichen bis 9,1 Tokens/s. Der Timeout schützt damit nur vor hängenden Verbindungen und schneidet keine Antwort ab, die der Anbieter im beobachteten Tempo liefert. Der Anfragekörper bleibt unverändert. Wert und Herleitung stehen in `ANK-71`.
2. (E2) Protokoll: `backend_openai_compatible()` schreibt `meta$timeout_s`, dazu `choices[[1]]$finish_reason` als `meta$finish_reason` und `choices[[1]]$native_finish_reason` als `meta$native_finish_reason`, jeweils nur als nicht leere Zeichenkette und mit exaktem Zugriff (`[[ ]]`). Damit ist eine an der Tokengrenze abgeschnittene Antwort von einer unlesbaren unterscheidbar. `formals()` und der Vorgabewert `timeout = 120` bleiben (`ANK-02`).
3. (E3) Fünfte Pilotregel `backend_errors`: je Modell Anteil der Backendfehler höchstens `error_share_trigger`, also höchstens 1 von 30; unlesbare Antworten zählen nicht. Wie `acmg_repeat_day()` zählt die Regel die gespeicherten Pilotzeilen des Modells mit einem Fehlereintrag. Sie spiegelt den Wiederholungstag: Ein Pilot, der im Hauptplan den Wiederholungstag auslösen würde, besteht nicht. Der Hauptplan startet nur, wenn alle fünf Regeln bestanden sind. Die Zeile nennt die Zahl der Backendfehler und den Anteil, etwa „qwen backend_errors failed: 3 of 30 backend errors (share 0.1 > 0.05)“.
4. (E4) Die Pilotzusammenfassung nennt zusätzlich die maximale Latenz je Modell (`latency_max`), wie der Median über alle gespeicherten Pilotzeilen des Modells einschließlich der Fehlerzeilen.
5. (E5) Pilot 3 läuft in einem neuen Store (`llmsa-runs/ap1_runs_3.sqlite`), der Hauptplan anschließend dort. Store und Log von Pilot 2 bleiben Beleg; der Bericht nennt Pilot 2 unter den Einschränkungen neben Pilot 1.
6. (E6) Nicht umgesetzt: keine automatische Wiederholung abgebrochener Aufrufe (Fehlerzeilen bleiben Fehler; eine Wiederholung verdeckte die Fehlerrate, und der abgebrochene Aufruf wird trotzdem berechnet), kein Streaming, kein `max_tokens`.

## Konsequenzen

- Betreiberänderung nach BL-01 außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`; Umsetzung mit Claude Code). Geändert:
  - `R/backends.R` (E2) und `R/acmg.R` (`acmg_validate_plan()`, `acmg_api_backends()`, `acmg_pilot()`), dazu `man/backends.Rd` und `NEWS.md`;
  - `inst/validation/ap1/plan.yaml`: `timeout_s` und `anchor` je Modell, `pilot.pass_rules.backend_errors`, `pilot.reported`, ein neuer Eintrag in `reporting.limitations` (Nr. 7), `provenance.plan`;
  - `reference/anchors/ANK-67.json` (`pass_rules`, `reported`, `source`, `verification`, zwei weitere Zitate) und neu `ANK-71.json`; dieses ADR deckt die Ankeränderung (AGENTS.md, Golden-Daten);
  - `ANKER-TODO.md`: Zeile ANK-67 (fünfte Regel, maximale Latenz, Quelle, Status) und neu Zeile ANK-71; die Nummer 71 ist aus „Nicht vergeben“ gestrichen;
  - `docs/03-anwendungspipeline.md`: A.4 und A.6, je als neue Sätze; die Zeilenzahl bleibt, die Zeilenverweise in `ANK-62` und `ANK-69` bleiben gültig;
  - `inst/validation/ap1/README.md` (Pilotabschnitt), `BACKLOG.md` (BL-74);
  - Unit-Tests unter `tests/testthat/`: drei neue Dateien; in `test-acmg-pilot-metadata.R` erwartet die Regelzählung fünf statt vier Regeln je Modell.
- Unverändert sind `tests/acceptance/`, `tests/e2e/`, `tests/fuzz/`, `tests/fixtures/`, `inst/extdata/` und `orchestrator/`. Die Kriterien K-M2-1 bis K-M2-7 bleiben wortgleich. K-M2-7 prüft jede Bestehensregel aus `ANK-67` einzeln, nicht ihre Zahl.
- Pilot 2 mit der neuen Prüfung (an einer Storekopie, einmalig): Qwen scheitert an `backend_errors` mit 3 von 30, Sol und Llama bestehen alle fünf Regeln. Pilot 2 gilt nach diesem ADR also nicht als bestanden; der Hauptplan beginnt erst nach einem bestandenen Pilot 3.
- Pilot 3 braucht ein eigenes `--store`: `run.R` setzt mit `resume = TRUE` fort und überspringt jeden gespeicherten Schlüssel einschließlich der Fehlerzeilen. Im Store von Pilot 2 überspränge Pilot 3 alle 90 Aufrufe, auch die drei abgebrochenen. Kopien mit SHA-256 nach A.8 Nr. 4.
- Ein hängender Aufruf kostet bis zu 30 min, bei Wiederholung durch httr2 nach 429 oder 503 (`req_retry(max_tries = 3)`) je Versuch. Einen Timeout selbst wiederholt httr2 nicht.
- Die Kostenprognose aus Pilot 2 enthält die drei abgebrochenen Qwen-Aufrufe nicht: Sie sind berechnet, haben aber keine `usage` im Store, und Projektion wie `usage_cost_usd` beruhen nur auf erfolgreichen Aufrufen.
- Laufzeit nach BL-74: Pilot 2 hochgerechnet etwa 24 h je Block und 32 h für die Robustheitsläufe, nacheinander; mit `timeout_s` 1800 eher mehr.
