# ADR-007 — Additive Schnittstellen in M2 (Reviewer-Vertrag)

## Status

Angenommen (Reviewer, M2 `30-plan-review` Runde 1, 27.10.2026). Bezug: `orchestrator/handoff/M2/PLAN.md` (Runde 1: „Lösung zu ACC-18“, `msa_report(…, assessment = NULL)`, Abschnitt „Vorlagen, Parser und Backends“), ACC-10 und ACC-18 in `orchestrator/handoff/M2/CRITERIA.json`, Einwand E13 in `orchestrator/handoff/M2/PLAN-REVIEW.md`.

## Kontext

- `docs/01-fachspezifikation.md` §4: „Ohne ADR erlaubt: neue exportierte Funktionen; neue Argumente mit Vorgabewert am Ende der Argumentliste; zusätzliche Felder in Rückgabeobjekten; … geänderte Druckausgabe“. Die beiden neuen Argumente sind damit ohne ADR zulässig. Dieses ADR legt ihre Bedeutung fest, nicht ihre Zulässigkeit.
- `IMPLEMENTATION-RULES.md`: „Public APIs sind explizit, klein und in `contracts/PROTOCOLS.md` oder `contracts/api/**` beschrieben.“ Nach dem Projektblock in AGENTS.md ist `reference/anchors/ANK-02.json` der API-Snapshot; `contracts/api/` trägt für dieses Paket keinen Snapshot. Der Builder bittet im PLAN darum, die freigegebene Beschreibung zentral festzuhalten.
- K-M2-3, K-M2-4, K-M2-7 und die Einleitung von `docs/03` legen `parse_choice(…, whole_word)` und das Verhalten von `backend_openai_compatible()` fest. `msa_run(…, parse_by_prompt)` und `msa_report(…, assessment)` schlägt der Builder vor (ACC-18; A.7).
- BL-57: Der Reviewer prüft die Vorgabewerte neu angehängter Argumente.

## Entscheidung

Die folgenden Verträge sind freigegeben. Die Rd-Seiten (roxygen2) der betroffenen Funktionen beschreiben sie gleichbedeutend; `NEWS.md` nennt die Ergänzungen.

1. **`parse_choice(levels, aliases = NULL, whole_word = FALSE)`**. Mit `FALSE` gilt das Verhalten von v0.1.0. Mit `TRUE` gilt:
   - Die Antwort wird kleingeschrieben und an jedem Zeichen, das weder Buchstabe noch Ziffer ist, in Wörter zerlegt.
   - Klassen und Aliase treffen nur als ganze Wortfolgen. Längere Folgen werden zuerst geprüft und verbrauchen ihre Wörter.
   - Mehrfache Treffer derselben Klasse sind zulässig. Zwei verschiedene Klassen oder keine ergeben `NA`.
   - `NA`, `NULL` oder eine leere Eingabe ergeben `NA`.
2. **`msa_run(design, backend, parse = parse_identity, block = NULL, store = NULL, resume = FALSE, delay = 0, verbose = TRUE, parse_by_prompt = NULL)`**. Mit `NULL` bleibt das Verhalten unverändert. Sonst gilt:
   - `parse_by_prompt` ist eine benannte Liste von Funktionen `function(text)` mit eindeutigen, nicht leeren Namen.
   - Für eine Zeile, deren `prompt_id` ein Name der Liste ist, ersetzt dieser Parser `parse`; alle anderen Zeilen verwenden `parse`.
   - Namen, die im Design nicht vorkommen, sind zulässig, damit dieselbe Liste allen Teilen eines Laufs dienen kann.
   - Eine ungültige Liste wird vor dem ersten Backend-Aufruf mit benanntem Fehler abgewiesen.
   - Rohantwort (`response`), Store-Schema, `run_key` und Ausführungsreihenfolge bleiben unverändert. Scheitert der gewählte Parser, ergibt das wie bisher `NA`.
3. **`msa_report(…, quiet = TRUE, assessment = NULL)`**. Mit `NULL` entsteht der Bericht wie bisher: gleiche Abschnitte und Texte, nur Zeitstempel und Versionen ändern sich. Sonst gilt:
   - `assessment` ist eine Liste mit drei Elementen. `criteria` ist ein data.frame mit mindestens `criterion` und `band`, wahlweise auch `value` und `note`. `verdict` ist eine Zeichenkette. `sections` ist eine benannte Liste; jeder Eintrag hat `text` und wahlweise `table` als data.frame.
   - Die Liste wird vor dem Rendern geprüft.
   - Der Renderer enthält keine ACMG-Regeln. Mit `assessment` nennt das Fazit `assessment$verdict`; die GRR-Einstufung bleibt im Abschnitt zur Präzision.
4. **`backend_openai_compatible()`** behält die `formals()` von `ANK-02` genau. Es gilt:
   - `temperature = NULL` lässt das Feld im JSON-Body weg.
   - Eine nicht leere, nicht-NA Spalte `row$system` ersetzt das Argument `system`. Sie geht als erste Nachricht mit der Rolle `system` vor die Nutzernachricht.
   - `meta` enthält `model_snapshot` (die gemeldete Modellkennung), `id`, `usage` und `system_fingerprint`; der Schlüssel `system_fingerprint` bleibt auch bei JSON-`null` erhalten. Trägt die Antwort ein Feld `provider`, steht es als `provider` in `meta`. Nur wenn die Anfrage ein Objekt `provider` trägt, enthält `meta` daraus `provider_order`, `quantizations` und `allow_fallbacks`.
   - `meta` enthält weder Schlüssel noch Header.
   - Der Text ist ausschließlich `message.content`.
5. **Keine neuen Exporte.** Die vier `acmg_*`-Funktionen bleiben intern (BL-51). Der Snapshot `ANK-02` ändert sich nicht.

## Konsequenzen

- Tests: `test-m0-api-snapshot.R` (Obermengenprüfung), `test-m2-3-prompts-parser.R` und `test-m2-4-backends.R` prüfen die Nummern 1 und 4. Die Nummern 2 und 3 prüfen die Unit-Tests des Builders: Vorgabe `NULL` wie in v0.1.0, Zuordnung der Parser, Prüfung der Liste, Rendern mit und ohne `assessment`. Der Reviewer prüft sie im Code-Review mit (BL-57).
- Später gilt für diese Argumente `docs/01` §4: Entfernen, Umbenennen oder eine geänderte Bedeutung nur mit ADR und Übergangsfrist.
