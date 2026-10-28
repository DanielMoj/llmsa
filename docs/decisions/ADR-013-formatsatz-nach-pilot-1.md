# ADR-013 — Formatsatz nach Pilot 1: nur die Klasse

## Status

Angenommen (Betreiber, 27.10.2026; Betreiberänderung nach BL-01). Bindend ab Pilot 2.

## Kontext

- Pilot 1 (A.6, ADR-006 Nr. 7) lief am 27.10.2026 von 13:21 bis 14:00 (MEZ): 90 Aufrufe, je Modell 10 Pilotitems × 3 Vorlagen, ohne Backendfehler. Belege: Log `unterlagen/ap1/pilot_2026-10-27.log` (Betreiberunterlage außerhalb des Repos), Store `llmsa-runs/ap1_runs.sqlite`, Kopie `llmsa-runs/ap1_runs_nach_pilot.sqlite` mit SHA-256 `ad45ee49f537f331d6bca7778f583a42cda87a3908658a8b47a2865293c8fe77` (A.8 Nr. 4).
- Befund:
  - Sol und Qwen bestehen alle vier Regeln.
  - Llama scheitert an der Parser-Regel: 21 von 30 Antworten erkannt, verlangt sind mindestens 27 von 30 (`ANK-67`).
  - Alle neun nicht erkannten Antworten stammen aus der Vorlage `concise` (9 von 10). Llama begründet ausführlich (387–728 `completion_tokens`), nennt dabei mehrere Klassen und schließt mit einer; der Parser gibt nach K-M2-3 `NA`.
  - Mit `role` („Reply with the classification only“) und `json` antwortet Llama 20 von 20 lesbar.
- `concise` ist zugleich die Grundlage der Robustheitsläufe: Der Lauf mit allen Faktoren auf − ist wörtlich `concise` (A.5; `ANK-62`, `all_minus`). `format_full` und `format_abbrev` begannen mit „Answer with exactly one of:“, deutsch mit „Antworte mit genau einer der folgenden Klassen:“.
- Weitere Befunde aus Pilot 1:
  - Sol meldet bei `reasoning_effort` `medium` Reasoning-Tokens (Median 821; BL-62).
  - Qwens Reasoning-Text steht in 30 von 30 Antworten in `meta$reasoning` (ADR-011 Nr. 7).
  - `usage.cost` und die nachgerechneten Kosten stimmen bei Llama und Qwen überein (ADR-011 Nr. 5): 0,00580070 USD und 0,01166892 USD für je 30 Aufrufe.
- Der Hauptplan beginnt erst, wenn jedes Modell alle Regeln besteht (A.6; ADR-006 Nr. 7.7). Planänderungen, die der Pilot nahelegt, entscheidet der Betreiber per ADR (ADR-004 und ADR-006, jeweils „Konsequenzen“).

## Entscheidung

1. Der Formatsatz verlangt ausdrücklich nur die Klasse, für alle Modelle gleich. Die Bausteine lauten (A.5, `ANK-62`):
   - `format_full.en`: „Answer with exactly one of the following and nothing else: Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic.“
   - `format_abbrev.en`: „Answer with exactly one of the following and nothing else: B, LB, VUS, LP, P.“
   - `format_full.de`: „Antworte mit genau einer der folgenden Klassen und sonst nichts: Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic.“
   - `format_abbrev.de`: „Antworte mit genau einer der folgenden Klassen und sonst nichts: B, LB, VUS, LP, P.“
2. `concise` ergibt sich nach `ANK-62` (`all_minus`) aus `task.en`, einem Leerzeichen und `format_full.en` (A.3, `ANK-69`): „Classify the germline variant {gene} {hgvs} according to the ACMG/AMP 2015 five-tier scheme. Answer with exactly one of the following and nothing else: Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic.“
3. Parser-Regel (K-M2-3, A.3), Bestehensregeln (A.6, `ANK-67`) und alle übrigen Wortlaute bleiben unverändert, also `role`, `json`, Aufgabensatz mit und ohne Dreher, Kontextabsatz und Systemprompt.
4. Pilot 1 ist nicht bestanden. Er bleibt als Beleg erhalten: Store `llmsa-runs/ap1_runs.sqlite` und Kopie `llmsa-runs/ap1_runs_nach_pilot.sqlite` mit der SHA-256 oben.
5. Pilot 2 läuft mit den neuen Wortlauten für alle drei Modelle in einem neuen Store. In diesem Store laufen danach auch Hauptplan und Robustheitsläufe.
6. Der AP1-Bericht nennt Pilot 1 und diese Änderung.

## Konsequenzen

- Betreiberänderung nach BL-01 außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`; Umsetzung mit Claude Code). Geändert:
  - `inst/validation/ap1/plan.yaml`: `templates.concise`, `robustness.blocks.format_full` und `format_abbrev`, je `en` und `de`; `provenance.plan` nennt zusätzlich ADR-011, ADR-012 und ADR-013; ein neuer Eintrag in `reporting.limitations` (Nr. 6);
  - `reference/anchors/ANK-62.json` und `ANK-69.json`: Wortlaute, Zitate, `source`, `method`, `verification`; dieses ADR deckt die Ankeränderung (AGENTS.md, Golden-Daten);
  - `ANKER-TODO.md`: Zeilen von ANK-62 und ANK-69 (Quelle und Status);
  - `docs/03-anwendungspipeline.md`: A.3 und A.5;
  - `BACKLOG.md`.
- Nr. 6 ist umgesetzt: Der neue Eintrag in `reporting.limitations` nennt Pilot 1, den Befund bei Llama und diese Änderung. Der Bericht gibt ihn je Modell im Abschnitt „Limitations“ aus (`R/acmg.R:1014`).
- Unverändert sind `R/`, `tests/` (alle Ordner), `inst/extdata/` und `orchestrator/`. Die Kriterien K-M2-1 bis K-M2-7 bleiben wortgleich. `acmg_prompts()` liest die Wortlaute aus `plan.yaml`, die Abnahmetests lesen sie aus `ANK-62` und `ANK-69`. `tests/fixtures/api/record.R` und `README.md` dokumentieren die Aufzeichnungen vom 26.10.2026. Deren Anfrage stammt nicht aus dem Plan: Systemprompt „You are a clinical variant scientist. Answer with exactly one of: Pathogenic, Likely pathogenic, Uncertain significance, Likely benign, Benign.“ und eine Testfrage als Nutzernachricht (`record.R:26–27`).
- Zum neuen Store: `run.R` setzt Läufe mit `resume = TRUE` fort, und `run_key` besteht aus Block, Item, Prompt-ID, Modell und Replikat, ohne den Prompttext (`R/run.R:109`). Ein zweiter Pilot im Store von Pilot 1 überspränge deshalb alle 90 Aufrufe und wertete die Antworten von Pilot 1. `--part main` und `--part robustness` prüfen den Pilot desselben Stores (ADR-006 Nr. 7.7). Die Vorgabe `../llmsa-runs/ap1_runs.sqlite` ist der Store von Pilot 1; Pilot 2 braucht also ein eigenes `--store`. Kopien mit SHA-256 nach A.8 Nr. 4.
- BL-62 ist erledigt. BL-74 (neu) hält die Laufzeit aus Pilot 1 fest.
