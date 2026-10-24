<!-- projektierung_llmsa/docs/03-anwendungspipeline.md -->
# 03 — Fachspezifikation Anwendungspipeline ACMG/AMP (M2)

Gilt zusammen mit `01-fachspezifikation.md`. M2 baut die Pipeline für den echten Lauf AP1: eingefrorener Itemsatz, Prompt-Vorlagen, Backends mit festem Routing, Auswertung der ACMG-Klassen und den Validierungsplan als maschinenlesbare Datei. Der Lauf selbst (Aufrufe an OpenAI und OpenRouter, Budget `ANK-57`) ist Betreiberaufgabe außerhalb des Harness; die Pipeline muss ihn ohne Codeänderung tragen.

Stellung im Plan (Revision 24.10.2026, 21:45): M2 hängt nur an M0 und läuft als zweiter Meilenstein, vor dem Statistikkern. Grund: Die AP1-Erhebung (Pilot, zwei Erhebungstage) braucht Itemsatz, Prompts, Backends und Laufskript, nicht die abgenommene Statistik; sie läuft parallel zu M1a–M1d, und die Auswertung wird nach der Abnahme von M1 wiederholt (BL-52). K-M2-6 prüft deshalb die Struktur der Auswertung auf dem Statistikkern von v0.1.0, nicht ihre Zahlen. Der Store des Laufs liegt außerhalb des Arbeitsbaums (`--store`, Vorgabe `../llmsa-runs/ap1_runs.sqlite`), damit PREFLIGHT der folgenden Meilensteine einen sauberen Baum vorfindet.

Ergebnis in einem Satz: `acmg_items()`, `acmg_prompts()`, `acmg_evaluate()` (intern) und das Laufskript `inst/validation/ap1/run.R` führen den Validierungsplan aus Anhang A auf `backend_mock()` von Ende zu Ende aus und bedienen die drei Modelle des Plans über `backend_openai_compatible()` mit festem Anbieter und Quantisierung.

Keine neuen Exporte: `acmg_items(insaid_path = NULL)`, `acmg_prompts()`, `acmg_evaluate(runs, plan)` und `acmg_plan(path = NULL)` sind interne Funktionen in `R/acmg.R` (`@keywords internal`, nicht in `NAMESPACE`); Abnahmetests und `inst/validation/ap1/run.R` rufen sie über `llmsa:::`. Das Paket bleibt damit domänenunabhängig, und kein Export braucht Rd-Beispiele, die ohne INSAID-TSV und ohne Netz laufen müssten. Welche Teile nach AP1 generisch exportiert werden (etwa ein Item-Import aus CSV mit Referenzspalte oder ein Plan aus YAML), entscheidet ein ADR (BL-51). Bestehende Schnittstellen bleiben; `backend_openai_compatible()` erhält nur zusätzliche Verarbeitung in `meta`.

## Kriterien

- **K-M2-1:** Itemsatz: `inst/extdata/items_ap1_2026-10-24/items.csv` hat genau 100 Zeilen mit den Spalten `item_id`, `source` (`erepo`/`insaid`), `gene`, `hgvs` (ERepo-Ausdruck mit Transkript) oder `hgvs_c` (INSAID: cDNA ohne Transkript), `reference` (fünf Klassen; bei `insaid` leer), `panel` (ERepo: Expertenpanel), `prior_clinvar_class`, `prior_differs`; 75 Zeilen `erepo`, je 15 pro Klasse, nicht zurückgezogen, Freigabe- und Veröffentlichungsdatum nach dem Stichtag `ankerRef: ANK-50`, Panels im Umlauf nach absteigender Einstufungszahl, dann Zufall mit Seed `ankerRef: ANK-59`; 25 Zeilen `insaid`, je 5 pro Klasse, nur Status `Validated`, Gene MEFV, MVK, NLRP3, TNFRSF1A im Umlauf, gleicher Seed; `QUELLE.txt` nennt ERepo-Stand `ankerRef: ANK-51` und die SHA-256 der INSAID-TSV `ankerRef: ANK-52`; `data-raw/make_items_ap1.R` erzeugt die Datei aus `../quellen/daten/` byte-identisch, und `acmg_items()` liest sie. (Prüfweg: Test)
- **K-M2-2:** Memorisierungs-Kennzeichen: `prior_clinvar_class` ist für jedes ERepo-Item die vor dem Stichtag `ANK-50` zuletzt eingereichte Einstufung eines anderen Einreichers als des Expertenpanels aus ClinVar `submission_summary` (Stand `ANK-41`, Spaltenbelegung `ankerRef: ANK-63`), bei mehreren gleichzeitigen Einreichungen die Mehrheit, bei Gleichstand `conflicting`, ohne frühere Einreichung `none`; `prior_differs` ist `TRUE` genau dann, wenn `prior_clinvar_class` weder `none` noch gleich `reference` ist; für INSAID-Items bleiben beide Spalten leer. (Prüfweg: Test)
- **K-M2-3:** Prompt-Vorlagen: `acmg_prompts()` liefert genau drei Vorlagen mit den IDs `concise`, `role`, `json` (Wortlaut Anhang A.3), jede mit genau den Platzhaltern `{gene}` und `{hgvs}` und ohne Referenzklasse; `render_prompt` füllt sie für jedes Item ohne verbleibende Klammer; die zugehörigen Parser (`parse_choice()` mit den Aliasen aus Anhang A.3 für `concise` und `role`, `parse_json_field("classification")` gefolgt von `parse_choice()` für `json`) bilden die fünf Klassen und die Abkürzungen B, LB, VUS, LP, P auf die Skala ab und geben für jede andere Antwort `NA`. (Prüfweg: Test)
- **K-M2-4:** Backends mit festem Routing: `backend_openai_compatible(...)` reicht zusätzliche Body-Felder (`provider` mit `order`, `allow_fallbacks = FALSE`, `quantizations`; `reasoning_effort`; `seed`) unverändert in den JSON-Body durch und speichert in `meta` die gemeldete Modellkennung (`model`), den bedienenden Anbieter und die Quantisierung aus der Antwort (`provider`, Feldnamen `ankerRef: ANK-60`), `usage` und `system_fingerprint`; `msa_run()` schreibt `meta` als JSON in den Speicher; geprüft gegen httptest2-Aufzeichnungen unter `tests/fixtures/httptest2/` je Modell des Plans (`ankerRef: ANK-53`, `ANK-54`, `ANK-55`) und gegen einen konstruierten Fehlerfall (HTTP 4xx → `error`-Eintrag, kein Abbruch). (Prüfweg: Test)
- **K-M2-5:** Validierungsplan als Datei: `inst/validation/ap1/plan.yaml` enthält die Felder `cou`, `risk`, `acceptance` (mit Schwellen `ankerRef: ANK-58`), `models` (drei Einträge mit `id`, `endpoint`, `provider_order`, `quantizations`, `reasoning`, `temperature`, `price_in`, `price_out` nach `ANK-53`–`ANK-55`, `ANK-61`), `design` (100 Items, 3 Prompts, 3 Modelle, 3 Replikate, 2 Blöcke), `robustness` (acht Faktoren mit zwei Stufen nach `ankerRef: ANK-62`, zwölf Läufe, Antwortgröße), `budget` (`ANK-57`) und `cutoff_date` (`ANK-50`); `acmg_plan()` liest sie, und `msa_design()` mit den Planwerten ergibt im Hauptplan 5.400 Zeilen über die drei Modelle, also 1.800 Aufrufe je Modell, dazu 1.200 je Modell im Plackett-Burman-Teil (`ankerRef: ANK-56`); die daraus mit den Preisankern und den Token-Annahmen aus `ANK-56` berechnete Kostenschätzung liegt unter `ANK-57`. (Prüfweg: Test)
- **K-M2-6:** Auswertung von Ende zu Ende: `acmg_evaluate(runs, plan)` liefert für einen mit `backend_mock()` und `acmg_items()` erzeugten Lauf (`inst/validation/ap1/run.R --backend mock --store <tmp>`; ohne `--store` schreibt das Skript nach `../llmsa-runs/ap1_runs.sqlite`, nie in den Arbeitsbaum) ein Objekt mit ordinalem Fit (Probit, Klassen in Skalenordnung), `msa_grr()` auf der latenten Skala, `msa_agreement()` (Modalantwort und alle Antworten, linear gewichtetes Kappa, Krippendorffs Alpha) gegen `reference`, Trefferquote getrennt nach `prior_differs` und nach `source`, dem Anteil gefährlicher Fehlklassifikationen (P/LP ↔ B/LB) der Modalantwort, dem Verdikt gegen `acceptance` und einem gerenderten `msa_report()`; INSAID-Referenzen werden nur über `acmg_items(insaid_path = …)` aus der lokalen TSV gelesen, bleiben ohne Datei `NA` und führen zu keiner Fehlermeldung. (Prüfweg: Test)

## Anhang A — Validierungsplan AP1 (Entwurf der Projektierung, vom Betreiber vor Start von M2 freizugeben)

Der Plan entspricht einem statistischen Analyseplan: Er steht fest, bevor der erste Aufruf läuft. Die Harness-Kriterien binden seine Struktur (Anzahl Vorlagen, Faktoren, Felder); den Wortlaut und die Werte gibt der Betreiber frei. Nach Freigabe wird er wörtlich nach `inst/validation/ap1/plan.yaml` und in die Dokumentation übernommen.

### A.1 Context of Use, Risiko, Akzeptanz

- **Context of Use (Entwurf):** Vorklassifikation von Keimbahn-Sequenzvarianten in Genen mit ClinGen-Expertenpanel sowie in MEFV, MVK, NLRP3 und TNFRSF1A auf der ACMG/AMP-Fünf-Klassen-Skala zur Vorbereitung einer Expertenbewertung; keine Ausgabe der Pipeline erreicht einen Befund ohne Freigabe durch einen Humangenetiker.
- **Risikostufe (Entwurf):** mittel (Modelleinfluss mittel: die Vorklassifikation lenkt die Expertenbewertung; Entscheidungsfolge mittel: Fehler werden durch die Freigabe abgefangen, kosten aber Zeit und können Prioritäten verschieben). Begriffe nach FDA-Guidance-Entwurf Januar 2025 und FDA Credibility-Guidance 2023.
- **Akzeptanzkriterien (Entwurf, `ANK-58`):** %GRR auf der latenten Skala unter 30 % der Studienvariation (bedingt akzeptabel für diese Risikostufe; unter 10 % akzeptabel); linear gewichtetes Kappa der Modalantwort gegen die Referenz mindestens 0,8 für „akzeptabel“, 0,6 bis 0,8 „bedingt“, darunter „nicht akzeptabel“ (Grenzen sind Betreiberentscheidung aus dem Context of Use; die Bezeichnungen der Bänder folgen Landis & Koch 1977, was keine Evidenz für die Grenzen ist); kein gefährlicher Fehler (P/LP ↔ B/LB) in den Modalantworten der ERepo-Items; Robustheit: kein aktiver Faktor nach Lenth ME bei α = 0,05 für die Antwortgröße aus A.5.
- **Memorisierungsvorbehalt:** Trefferquote und Kappa werden zusätzlich getrennt für Items mit `prior_differs = TRUE` berichtet; die INSAID-Teilmenge (Stand 2017) trägt den Vorbehalt vollständig. Präzision ist davon unberührt.

### A.2 Itemsatz

Wie K-M2-1 und K-M2-2. Herkunft: ClinGen ERepo (CC0, Stand 22.10.2026, `ANK-51`), INSAID (Van Gijn et al. 2018, Stand März 2017, `ANK-52`). Stichtag `ANK-50` (Wissensstand GPT-6.1 Sol). Seed `ANK-59`.

### A.3 Prompt-Vorlagen (Entwurf, englisch, drei Varianten gleicher Bedeutung)

- `concise`: „Classify the germline variant {gene} {hgvs} according to the ACMG/AMP 2015 five-tier scheme. Answer with exactly one of: Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic.“
- `role`: „You are a clinical geneticist on a variant curation expert panel. Using the ACMG/AMP 2015 standards and guidelines, assign the five-tier classification for the germline variant {gene} {hgvs}. Reply with the classification only, as one of: Benign; Likely benign; Uncertain significance; Likely pathogenic; Pathogenic.“
- `json`: „Return a JSON object of the form {"classification": "<tier>"} for the germline variant {gene} {hgvs}, where <tier> is the ACMG/AMP 2015 five-tier classification: one of "Benign", "Likely benign", "Uncertain significance", "Likely pathogenic", "Pathogenic". Output the JSON object only.“
- Parser-Aliase (Groß-/Kleinschreibung unerheblich): `B`, `benign` → Benign; `LB`, `likely benign` → Likely benign; `VUS`, `VOUS`, `uncertain significance`, `uncertain` → Uncertain significance; `LP`, `likely pathogenic` → Likely pathogenic; `P`, `pathogenic` → Pathogenic. Antworten mit mehr als einer Klasse → `NA`.
- Kein Systemprompt im Hauptplan; kein Evidenzmaterial im Prompt; die Modelle klassifizieren aus ihrem Wissen (Memorisierung wird gemessen, nicht verhindert).

### A.4 Modelle, Routing, Einstellungen (Entwurf)

| Stufe | Modell | Weg | Festlegung | Preise | Quelle |
| --- | --- | --- | --- | --- | --- |
| proprietär | GPT-6.1 Sol | OpenAI-API, eigenes Projekt mit eigenem Schlüssel und Ausgabelimit | Reasoning `medium`; Temperatur nicht gesetzt, falls der Endpunkt sie für dieses Modell ablehnt (`ANK-61`); zurückgemeldete Modellkennung je Aufruf gespeichert | `ANK-53` | `quellen/anbieter_2026-10-22/openai/` |
| offen | Llama 3.3 70B Instruct | OpenRouter | `provider.order = ["CoreWeave"]`, `allow_fallbacks = false`, `quantizations = ["fp16"]`; Temperatur 0 | `ANK-54` | `quellen/anbieter_2026-10-22/openrouter/` |
| offen | Qwen3-32B | OpenRouter | `provider.order = ["DeepInfra"]`, `allow_fallbacks = false`, `quantizations = ["fp8"]`; Reasoning aus; Temperatur 0; `seed` gesetzt | `ANK-55` | ebenda |

Kein medizinisches Modell, kein Claude, kein Gemini 4 Argon (Entscheidungen 24.10.2026). Schlüssel nur in `orchestrator/secrets.env` beziehungsweise in der Umgebung des Betreiberlaufs; Ausgabelimits bei OpenAI und OpenRouter unter den Euro-Beträgen des Budgets.

### A.5 Versuchsplan, Ausführung, Robustheit

- Hauptplan je Modell: 100 Items × 3 Prompts × 3 Replikate × 2 Blöcke (Tage) = 1.800 Aufrufe; über drei Modelle 5.400. Innerhalb eines Blocks werden alle Items × Prompts × Modelle eines Replikats abgearbeitet, bevor das nächste Replikat beginnt (Replikate eines Items liegen Stunden auseinander); Itemreihenfolge je Replikat randomisiert mit Seed; `msa_run(store = <--store>, resume = TRUE)` mit Store außerhalb des Arbeitsbaums (Vorgabe `../llmsa-runs/ap1_runs.sqlite`), weil die Erhebung parallel zu M1a–M1d läuft und der Harness-Baum sauber bleiben muss; wie die Ergebnisse später eingefroren ins Paket kommen, entscheiden AP2/AP3 (Katalog).
- Robustheit: Plackett-Burman mit 12 Läufen und acht Störfaktoren (`ANK-62`, Entwurf), je Lauf alle 100 Items einmal mit Vorlage `concise` je Modell = 1.200 Aufrufe je Modell:

| Faktor | Stufe − | Stufe + |
| --- | --- | --- |
| F1 Variantenschreibweise | HGVS mit Transkript | Gen und c.-Bezeichnung ohne Transkript |
| F2 Proteinangabe | ohne p.-Angabe | mit p.-Angabe (sofern vorhanden) |
| F3 Tippfehler in der Anweisung | keiner | ein Buchstabendreher außerhalb der Variantenbezeichnung |
| F4 Reihenfolge | Aufgabe, dann Antwortformat | Antwortformat, dann Aufgabe |
| F5 Irrelevanter Zusatzkontext | keiner | ein Absatz klinischer Allgemeintext ohne Bezug zur Variante |
| F6 Systemprompt | keiner | „You are a careful clinical geneticist.“ |
| F7 Antwortformat | Klassen ausgeschrieben | Abkürzungen B, LB, VUS, LP, P |
| F8 Sprache der Anweisung | Englisch | Deutsch |

- Antwortgröße je Lauf (Entwurf): Anteil der Items, deren Klasse der Modalantwort des Modells aus dem Hauptplan gleicht (Stabilität), logit-transformiert; sekundär die Trefferquote gegen die Referenz. Auswertung mit `msa_robustness()` (Lenth PSE, ME, SME, Half-Normal-Plot).
- Temperatur ist kein Faktor (Reasoning-Endpunkte akzeptieren sie nicht einheitlich); Katalog.

### A.6 Budget und Kosten

3.000 Aufrufe je Modell, 1.000 Tokens Eingabe, höchstens 2.000 Tokens Ausgabe samt Reasoning (`ANK-56`); Kostenschätzung aus den Preisankern; Budget 150 € (`ANK-57`), Rest für Pilotlauf und einen wiederholten Tag. Ein Pilotlauf mit 10 Items × 3 Prompts × 1 Replikat je Modell geht dem Hauptplan voraus und prüft Parser-Trefferquote und Latenz.

### A.7 Berichtsinhalt

`msa_report()` mit `cou`, `risk`, `acceptance` aus `plan.yaml`; Varianzzerlegung auf der latenten Skala; Kappa, Alpha, Trefferquote (gesamt, nach `source`, nach `prior_differs`); Robustheitsergebnis; Modellkennungen, Anbieter, Quantisierung je Modell; Datenhash; Seeds; Paket- und R-Versionen. INSAID-Referenzklassen erscheinen nur als Kennzahlen der Teilmenge, nie je Variante.
