# PLAN — M2, Runde 1

Rolle: Builder · Phase: `20-plan` · Runde: 1 · Stand: 27.10.2026.
Status: Vorschlag zur Planprüfung; keine Implementierung und keine
Abnahmebehauptung. In dieser Phase wird ausschließlich diese Datei geschrieben.

## Ziel

M2 liefert die ausführbare AP1-Pipeline nach
`docs/03-anwendungspipeline.md`, K-M2-1 bis K-M2-7 und Anhang A:
reproduzierbare Itemdateien, Memorisierungskennzeichen, drei Hauptvorlagen,
zwölf Robustheitsvorlagen, festes API-Routing, den maschinenlesbaren Plan,
Pilot, Erhebung und Auswertung mit Berichten je Modell. Der vollständige
Prüflauf verwendet `backend_mock()` beziehungsweise die vorhandenen
API-Aufzeichnungen. Die echte Erhebung führt anschließend der Betreiber
mit einem Store außerhalb des Arbeitsbaums durch.

M2 verwendet den vorhandenen Statistikkern. Seine unabhängige fachliche
Abnahme bleibt in M1a–M1d; AP1-Auswertungen bis dahin werden als vorläufig
gekennzeichnet und nach M1 aus demselben Store wiederholt (BL-52). Die vier
`acmg_*`-Funktionen bleiben intern. Die 22 Exporte und ihre bisherigen
Argumentpositionen und Vorgaben bleiben gemäß ANK-02 erhalten.

Gelesene Grundlage: `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, M2 `CRITERIA.json` einschließlich ACC-1
bis ACC-25, sämtliche Abnahmetests und ihre Setup-Dateien, `docs/00`,
`docs/01`, `docs/03`, ADR-004 einschließlich beider Nachträge vom 26.10.,
die einschlägigen Anker ANK-41, ANK-50–69, ANK-94 und ANK-TOL sowie die
Formelsammlung §§5, 7 und 11. Zusätzlich wurden die betroffenen
Implementierungen, die bestehenden Unit-Tests für Lauf, Parser, Backends
und Bericht, `DESCRIPTION`, `toolchain.json`, die Fixture-README und die
M0-Abschlussbelege gelesen. `orchestrator/LESSONS.md` enthält noch keine
Lehren. Für M2 liegt bisher nur `CRITERIA.json` vor; dies ist keine
PLAN-UPDATE-Runde.

## Dateien

Die folgende Liste beschreibt den geplanten BUILD nach Planfreigabe.
Sie erweitert nicht das Schreibterritorium dieser PLAN-Phase.

| Datei/Pfad | Geplante Änderung und Zweck |
| --- | --- |
| `R/acmg.R` | Die vier internen Einstiegspunkte und kleine interne Hilfsfunktionen für Konfiguration, Items, Vorlagen, Laufplanung, Pilotprüfung, Auswertung und Berichtsdaten; K-M2-1 bis K-M2-7. |
| `R/parse.R`, `man/parsers.Rd` | Additives `whole_word = FALSE`; Wortfolgenparser für AP1 bei unverändertem Vorgabeverhalten; K-M2-3. |
| `R/run.R`, `man/msa_run.Rd` | Additives `parse_by_prompt = NULL`, damit ein gemischter Lauf vorlagenspezifisch parst; vorhandenen Store, Fehlerpfad und Resume-Schlüssel weiterverwenden; ACC-18. |
| `R/backends.R`, `man/backends.Rd` | Temperaturfeld bei `NULL` auslassen, Systemnachricht aus der Designzeile übernehmen, Antwort- und Routingmetadaten ergänzen; K-M2-4, K-M2-7. |
| `R/report.R`, `man/msa_report.Rd`, `inst/templates/validation_report.Rmd` | Optionale allgemeine Berichtsergänzung `assessment = NULL`, Kriterien und Gesamtverdikt sowie zusätzliche Tabellen/Texte und Half-Normal-Plot darstellen; K-M2-6, K-M2-7, A.7. |
| `data-raw/make_items_ap1.R` | Ausschließlich lokale, belegte Rohdateien prüfen, auswählen und in die beiden eingefrorenen CSVs überführen; K-M2-1, K-M2-2. |
| `inst/extdata/items_ap1_2026-10-24/items.csv`, `pilot.csv`, `QUELLE.txt`, `SHA256SUMS` | 100 Hauptitems und 10 separate Pilotitems samt Provenienz und SHA-256. Keine INSAID-Referenzen oder Proteinangaben in diesen Artefakten. |
| `inst/validation/ap1/plan.yaml` | Freigegebene Konfiguration mit Herkunftsverweisen auf die Anker und ADR-004, einschließlich aktueller Qwen-Regel; K-M2-5. |
| `inst/validation/ap1/run.R`, `inst/validation/ap1/README.md` | Quellbaumgebundener CLI-Einstieg für Mock- und Betreiberlauf, externe Stores, Pilotbefunde, erneute Auswertung und englische Bedienungsdokumentation. |
| `DESCRIPTION` | `yaml`, `digest` und `pkgload` als Suggests ergänzen: YAML-Lesen, SHA-256 auch unter R 4.1 und Laden des richtigen Quellbaums. Imports bleiben unverändert. Installation bleibt beim deps-Gate. |
| `man/acmg.Rd` | Interne roxygen2-Dokumentation der vier Funktionen mit `@keywords internal`, einschließlich Daten- und Rückgabeverträgen. |
| `tests/testthat/test-acmg-data.R`, `test-acmg-pipeline.R`, `test-acmg-evaluate.R`, `test-parsers.R` | Kleine, schnelle Verhaltens-, Grenzfall- und Fehlerpfadtests. Künstliche Daten sind im Test als solche bezeichnet; temporäre Dateien liegen außerhalb des Repos. |
| `tests/testthat/test-design-run.R`, `test-backends.R`, `test-report.R` | Regressionstests zu den additiven Schnittstellen und gezieltes Rendering; bestehende Erwartungen und Skips nicht abschwächen. |
| Neues Builder-ADR unter `docs/decisions/` | Auswahl und erstmaliges Einfrieren des AP1-Itemsatzes fachlich begründen, Quellen, Seed, Auswahlregeln und Prüfsummen nennen. Freie ADR-Nummer nach PLAN-REVIEW vergeben; im selben Meilenstein wie die Golden-Dateien. |
| `NEWS.md`, `PROGRESS.md` | Englischer Eintrag insbesondere zu `backend_openai_compatible(temperature = NULL)`; deutscher M0-Abschlussvermerk nach BL-54 und echte M2-Prüfoutputs mit offenen Befunden. |

`R/design.R`, `R/utils.R`, `R/agreement.R`, `R/robustness.R`, `R/fit.R`
und `R/grr.R` werden für diesen Plan wiederverwendet. Insbesondere werden
AP1-Regeln für Modalantworten und fehlende Werte in der Anwendungsschicht
umgesetzt. Die vorgesehenen roxygen2-Änderungen erzeugen keine neuen
Exporte; ANK-02 wird nicht angepasst. Abnahmetests, Anker, Fixtures,
Spezifikationen, BACKLOG, Gate-Auswahl und Orchestrator-Zustand sind
Lesekontext und bleiben im Besitz der jeweiligen anderen Rolle.

## Schnittstellen

### Interne Einstiegspunkte und Konfiguration

| Funktion | Vertrag |
| --- | --- |
| `acmg_items(insaid_path = NULL, pilot = FALSE)` | Liest die jeweilige eingefrorene CSV und liefert einen data.frame. INSAID-Referenzen sind ohne lokale TSV `NA`; vorhandene lokale Referenz- und Proteininformation wird nur im Speicher ergänzt. |
| `acmg_prompts(robustness = FALSE)` | Standard: benannter Zeichenvektor `concise`, `role`, `json`. Robustheit: data.frame mit `prompt_id`, `F1`–`F8`, `template`, `system`, zwölf Zeilen in PB-Designfolge. |
| `acmg_plan(path = NULL)` | Liest YAML aus dem angegebenen Pfad oder aus den Paketressourcen. Rückgabe ist eine validierte Liste; ein expliziter Pfad wird tatsächlich gelesen, kein Rückfall auf eine eingebettete Konfiguration. |
| `acmg_evaluate(runs, plan)` | Nimmt `msa_runs` mit den Store- und Itemspalten sowie den gelesenen Plan an. Liefert `models` mit Schlüsseln `sol`, `llama`, `qwen` und `joint` als gemeinsamen `msa_fit`. Berichte liegen außerhalb des Paketbaums. |

Alle vier Definitionen stehen in `R/acmg.R`, sind nicht exportiert und
werden im Laufskript über `llmsa:::` aufgerufen. Die Laufzeit verwendet
ausgelieferte CSVs und YAML, nicht `reference/anchors/`, `docs/` oder
Dateien des Harness. Diese fehlen insbesondere in der Mutationskopie
und im installierten Paket. Das Erzeugungsskript darf die Anker aus dem
Quellbaum lesen; die daraus übernommenen Konfigurationswerte erhalten
einen Herkunftsverweis in `plan.yaml` beziehungsweise `QUELLE.txt`.

`plan.yaml` enthält mindestens `cou`, `risk`, `acceptance`, `models`,
`design`, `pilot`, `robustness`, `evaluation`, `budget`, `cutoff_date`.
Zusätzliche Abschnitte für Hauptvorlagen, Klassen/Aliase und Provenienz
halten die ausgelieferte Konfiguration zusammen. Die freigegebenen
Prompt-Wortlaute und Bausteine aus A.3/A.5 werden unverändert übernommen,
einschließlich der vorgeschriebenen deutschen F8-Stufen; übrige
Paketdokumentation und Meldungen sind englisch. Alle Festlegungen aus
Anhang A und ADR-004 werden abgebildet, keine Ableitung aus Modellgedächtnis.

`models` hat je Eintrag genau die in K-M2-5 geforderten Felder als
Mindestvertrag. Preise werden einheitlich in USD je Million Tokens
geführt. `design` enthält `items`, `prompts`, `models`, `replicates`,
`blocks`, `order`, `seed`; `order: replicate_random` bezeichnet Replikat
außen und Randomisierung innen in der AP1-Hilfsfunktion. Datumswerte
werden als ISO-Zeichenketten geführt. Die Ladevalidierung prüft Schema,
Typen und zulässige Werte, erzwingt aber nicht bei jedem expliziten
`path` die eingefrorenen Vorgaben: insbesondere bleibt der in ACC-13
geprüfte abweichende Design-Seed lesbar. Der Ankerabgleich prüft die
ausgelieferte Planfassung.
Sol verwendet `temperature: null`, `reasoning: medium` und leere
Routinglisten. Llama und Qwen verwenden Temperatur 0, `reasoning: null`
und die Endpunkt-Tags/Quantisierungen aus ANK-54/55. Für Qwen wird weder
ein `reasoning`-Feld noch `/no_think` hinzugefügt (ADR-004, Nachtrag 2).

### Items und Memorisierung — K-M2-1, K-M2-2

Beide CSVs erhalten dieselben 17 Spalten in derselben Reihenfolge:
`item_id`, `source`, `gene`, `transcript`, `hgvs`, `protein`, `reference`,
`panel`, anschließend `prior_clinvar_class_*`, `prior_date_*`,
`prior_differs_*`, jeweils mit `_sol`, `_llama`, `_qwen`.
Klassen tragen die Schreibweise aus ANK-69. Leere Felder sind wirklich
leer, keine Zeichenkette `NA`; Daten werden als ISO-Datum, Kennzeichen
als `TRUE`/`FALSE` geschrieben. Beim Einlesen sind typisierte NA-Werte
zulässig. Eine zusätzliche Spalte `text` wird erst für `msa_design()`
aus `hgvs` hergestellt.

Das Erzeugungsskript arbeitet in folgenden Schritten:

1. Vor jeder Ausgabe alle drei erforderlichen Eingaben unter
   `../quellen/daten/` auf Existenz, Anker-Prüfsummen und Schema prüfen:
   ERepo nach ANK-51, INSAID nach ANK-52, ClinVar nach ANK-41/63. Fehlende
   Quellen führen zu einem benannten Fehler mit `quellen` im Text.
   Vorhandene Ausgaben bleiben bei Eingabe- oder Validierungsfehlern erhalten.
2. ERepo-Pool aus gültiger NM-c.-Notation, `Retracted = false` und beiden
   Datumswerten strikt nach ANK-50 bilden. Gen, Transkript, c.- und
   optionale p.-Angabe trennen; `hgvs` enthält weder Gen noch Protein.
   Die ClinVar-Variation-ID bleibt ein interner Join-Schlüssel.
3. **Lesart ACC-4:** Einstufungszahl bedeutet die Kandidatenzahl eines
   Panels innerhalb der jeweiligen Klasse im gefilterten Pool. Panels
   danach absteigend anordnen, Gleichstände mit dem Seed auflösen und
   Kandidaten je Panel zufällig ohne Zurücklegen ziehen. Der Umlauf
   besucht jedes noch nicht erschöpfte Panel einmal pro Runde. Pro
   Klasse bilden Picks 1–15 die Hauptauswahl, Picks 16–17 den Pilot;
   der Pilot wird nicht separat neu gezogen.
4. INSAID lokal auf `Validated` und die vier Gene aus ANK-59 filtern,
   Klassen einschließlich `VOUS` normalisieren und fünf Items je Klasse
   im Gen-Umlauf ziehen. **Lesart ACC-5:** Gene je Klasse nach
   Kandidatenzahl absteigend, Gleichstände geseedet; Kandidaten ebenfalls
   ohne Zurücklegen. Transkripte stammen ausschließlich aus ANK-64.
5. Sortiergrundlagen explizit mit stabiler, gebietsschemaunabhängiger
   Ordnung herstellen, dann mit ANK-59 randomisieren. RNG und
   `sample.kind` festlegen und protokollieren. Ausgabe in UTF-8/LF mit
   fester Spalten- und Zeilenordnung und leeren NA-Feldern. IDs leiten
   sich aus Quelle und Variantenidentität ab, nicht aus Referenzklassen.
   Auch die endgültige INSAID-Zeilenordnung codiert keine Klasse.
6. ClinVar in Blöcken lesen und nur Einreichungen der ausgewählten
   ERepo-Variation-IDs behalten. Kopfzeile und Spaltenpositionen nach
   ANK-63 prüfen, englische Datumsangaben gebietsschemaunabhängig parsen.
   Ein Extrakt darf im temporären Verzeichnis zwischengespeichert werden,
   nicht im Repo.
7. Beide CSVs vollständig im Speicher beziehungsweise in einem
   temporären Verzeichnis erstellen und validieren, dann die
   freigegebenen Ausgabeziele ersetzen. `QUELLE.txt` nennt Stand, URLs,
   Lizenz, Auswahl und Skript, INSAID-SHA-256 und die Transkripte aus den
   Methoden samt MEFV-Widerspruch zu Tabelle 1. `SHA256SUMS` deckt
   `items.csv`, `pilot.csv` und `QUELLE.txt` ab; die Summendatei hasht sich
   nicht selbst. Größen und Kompressionsregel folgen ANK-TOL.data_size.

**Festgelegte Lesart ACC-6 für alle Items, Modelle und Dateien:**

| Offener Punkt | Vorschlag für die Implementierung |
| --- | --- |
| Stichtag | `DateLastEvaluated < cutoff`; `_sol` nach ANK-50, `_llama` nach ANK-65, `_qwen` nach ANK-66. Undatierte Einreichungen zählen nie. |
| Einstufung | Nur die fünf ACMG-Klassen, unabhängig von Groß-/Kleinschreibung. `not provided`, `-`, leere Werte und andere Klassifikationssysteme zählen nicht. |
| Flagged submission | Zählt, sofern Datum und Fünfklassen-Einstufung vorliegen: Das Kennzeichen beschreibt frühere verfügbare Information, keine Qualitätsfreigabe dieser Einreichung. |
| Expertenpanel | Eigene Panel-Einreichungen ausschließen: normalisierter Name ohne nachgestelltes `VCEP` gegen Submitter, mit Expertenpanel-Status. Ohne eindeutige Namenszuordnung konservativ alle Expertenpanel-Einreichungen ausschließen und diesen Fall diagnostisch zählen; keine geratenen Namenszuordnungen. |
| Mehrere Einreichungen | Nur das jüngste zulässige Datum betrachten; eindeutige Mehrheit der Klassen, sonst `conflicting`. Ohne zulässige Einreichung `none` und leeres Datum. `prior_differs` ist genau die in K-M2-2 definierte logische Bedingung. |

Diese Entscheidungen sind zur Reviewer-Festschreibung in PLAN-REVIEW
vorgelegt; sie sind keine Änderung der Abnahmetests. Bei INSAID bleiben
alle neun Kennzeichenspalten, `reference` und `protein` auf der Platte
leer. `acmg_items()` verbindet eine vorhandene lokale TSV über Gen und
cDNA; Referenz und Protein verlassen diesen Arbeitsspeicher nur als
zulässiger Prompttext beziehungsweise aggregierte Auswertung. Fehlt die
optionale TSV, bleiben die Referenzen `NA` und die Auswertung läuft ohne
Fehler. Eine vorhandene, aber beschädigte oder nicht passende Datei wird
benannt abgewiesen. Das erforderliche Rohmaterial des Erzeugungsskripts
ist davon zu unterscheiden: Dort ist Fehlen ein Fehler.

### Vorlagen, Parser und Backends — K-M2-3, K-M2-4, K-M2-7

`parse_choice(levels, aliases = NULL, whole_word = FALSE)` behält den
bisherigen Teilzeichenkettenpfad als Vorgabe. Im neuen Modus werden
Leerraum und Satzzeichen als Worttrenner behandelt. Längere Wortfolgen
werden zuerst erkannt und ihre Wörter verbraucht; wiederholte Treffer
derselben Klasse sind erlaubt, verschiedene Klassen oder kein Treffer
ergeben `NA`. Die Aliase kommen aus A.3/ANK-69.

**Lösung zu ACC-18:** `msa_run()` erhält als letztes Argument
`parse_by_prompt = NULL`. Bei `NULL` gilt unverändert `parse(text)`.
Andernfalls ist es eine benannte Liste von Parserfunktionen, deren Namen
`prompt_id` entsprechen; ein vorhandener Eintrag ersetzt für diese Zeile
den allgemeinen Parser, für nicht genannte IDs gilt weiterhin `parse`.
Ungültige Listen werden vor dem ersten Aufruf abgewiesen. AP1 übergibt
den Wortparser allgemein und für `json` die Komposition
`parse_json_field("classification")` → Wortparser. Ein fehlendes
JSON-Objekt wird `NA`; es gibt keinen Rückfall auf den Volltext. Die
Auswahl hängt allein von der geplanten Vorlage ab und verändert weder
Ausführungsreihenfolge noch gespeicherte Rohantwort.

Die Hauptvorlagen enthalten ausschließlich `{gene}` und `{hgvs}` als
Platzhalter und keinen Systemprompt. Der vorhandene `render_prompt()`
wird wiederverwendet. Robustheitsvorlagen folgen
`pb_design(8, n_runs = 12, seed = ANK-59)` und ANK-62: F8 Sprache,
F3 Aufgabensatz/Dreher, F7 Format, F4 Satzfolge, F5 Kontext mit Leerzeile,
F6 separate Systemspalte. F1/F2 verändern den für diese Zeile gerenderten
Variantentext; die kanonischen Itemdaten werden dabei nicht überschrieben.
Der Lauf mit acht Minus-Stufen bleibt wortgleich zu `concise`.

`backend_openai_compatible()` behält exakt seine bisherigen formals.
`temperature = NULL` erzeugt kein Temperaturfeld. `provider` samt Listen
für `order`/`quantizations`, `allow_fallbacks = FALSE`, `reasoning_effort`
und `seed` werden unverändert durchgereicht. Die nicht leere, nicht-NA
Spalte `row$system` hat Vorrang vor dem Argument `system`; bei fehlender
Zeile, fehlender Spalte oder leerem Wert gilt das Argument. Die
Systemnachricht steht vor der Nutzernachricht.

`meta` behält `model_snapshot` und ergänzt/erhält `id`, `usage`,
`system_fingerprint` (auch als vorhandenen Null-Schlüssel), bei
OpenRouter `provider` aus der Antwort sowie `provider_order`,
`quantizations`, `allow_fallbacks` aus der Anfrage. Für Sol werden keine
Routingfelder erfunden. Zusätzliche protokollierte Anfrageparameter
enthalten keine Schlüssel oder Authorization-Header. Ausgewertet wird
ausschließlich `message.content`, niemals `message.reasoning`.
Der vorhandene JSON-Storepfad von `msa_run()` bleibt maßgeblich; die
AP1-Abhängigkeiten stellen eine echte JSON-Serialisierung sicher.

HTTP-4xx-Antworten bleiben Fehlerzeilen mit fehlendem Wert, und
`msa_run()` arbeitet die weiteren Zeilen ab. Es wird kein anderer
Provider als Ersatz angefragt. Fehlende oder abweichende
Providerinformation bei OpenRouter wird für den Pilot nicht als bestanden
ausgegeben. Sol wird als direkter OpenAI-Endpunkt beurteilt; dort ist
kein `provider`-Antwortfeld vorausgesetzt. Die aktuellen OpenRouter-
Aufzeichnungen enthalten den Provider; eine spätere
Stichprobe über `/api/v1/generation?id=…` anhand von `meta$id` ist
Betreiberarbeit nach K-M2-4, keine verdeckte Anfrage eines Tests.

### Laufskript und Pilot — K-M2-5 bis K-M2-7

Verbindlicher Aufrufvertrag nach ACC-11:

```text
Rscript <Paketwurzel>/inst/validation/ap1/run.R \
  --part pilot|main|robustness [--block n] --backend mock [--store pfad]
```

Für den Betreiber wird zusätzlich `--backend api` vorgesehen;
Vorgabe ist `mock`. `--insaid-path` erlaubt die lokale Laufzeitergänzung.
`--evaluate-only` liest und analysiert den vorhandenen Store ohne neue
Backend-Aufrufe; `--report-dir` legt dafür ein externes Berichtsziel fest.
Die Paketwurzel wird aus dem Skriptpfad bestimmt und genau dieser
Quellbaum mit `pkgload::load_all(..., export_all = FALSE, helpers = FALSE)`
geladen, auch in einer temporären Paketkopie. API-Schlüssel liest nur
der explizite Betreiberpfad aus dessen Umgebung; die Builder-Prüfungen
verwenden Mock-Backends und Dummy-Schlüssel.

Die Hauptplanung erzeugt zunächst den vollständigen gekreuzten Plan mit
`msa_design()`. Eine interne AP1-Hilfsfunktion ordnet innerhalb jedes
Blocks nach Replikat und mischt innerhalb jedes Replikats alle
Item×Prompt×Modell-Kombinationen. Der Zufallsstrom beginnt mit ANK-59;
erst nach Planung beider Blöcke wird `--block` angewendet. `position`
wird je Block fortlaufend neu vergeben. Damit haben blockweise und
vollständige Ausführung dieselbe Folge. API-Seed und Planrandomisierung
sind getrennt: Jede echte Anfrage trägt denselben Seed aus ANK-61,
unabhängig von Block und Replikat.

Der Hauptplan enthält 5.400 Zeilen, der Robustheitsteil 3.600, der Pilot
90 (ANK-56/67). Pilotitems sind von Hauptitems disjunkt, PB-Prompt-IDs
von den drei Hauptvorlagen. Der bestehende Schlüssel aus Block, Item,
Prompt, Modell und Replikat reicht deshalb für die Trennung der Teile.
Alle Teile verwenden `resume = TRUE`. Ein erneuter Aufruf ergänzt nur
fehlende Schlüssel. Die Auswertung liest stets den Store neu und ergänzt
Itemdaten passend zu den IDs; eine Rückgabe eines einzelnen Teillaufs
wird nicht versehentlich als vollständiger Hauptplan behandelt.

Die Store-Vorgabe wird relativ zur Paketwurzel zu
`../llmsa-runs/ap1_runs.sqlite` aufgelöst. Store, Berichte und
Hilfsartefakte werden auf ein Ziel außerhalb des Arbeitsbaums geprüft,
auch bei relativen Pfaden und symbolischen Links. Temporäre Dateien und
Grafikgeräte dürfen keine Dateien wie `Rplots.pdf` im Checkout erzeugen.

Im Mock-Pfad stammen Antworten aus einer ausdrücklich synthetischen,
geseedeten `backend_mock()`-Konfiguration über die fünf Klassen.
Eine kleine Formatadaption liefert für die JSON-Vorlage ein JSON-Objekt.
Die Simulation verwendet keine lokalen INSAID-Referenzen als versteckte
Antwortquelle. Sie belegt Ablauf und Auswertung, keine Modellleistung.
Provider- und Tokenmessungen werden nicht erfunden: Wenn der Mock diese
Daten nicht liefert, meldet die entsprechende Pilotregel erklärtes
`failed`; die Parameterregel meldet ohne HTTP-Fehler `passed`.
Mock-Teile können für die Tests unabhängig voneinander laufen.

Im API-Pfad wird vor dem Hauptplan der gespeicherte Pilot aller drei
Modelle auf Vollständigkeit und alle Regeln aus ANK-67 geprüft. Ein
fehlender oder gescheiterter Pilot verhindert neue Hauptplan-Aufrufe.
Mit `meta$mock = TRUE` markierte Pilotzeilen können diese Freigabe nicht
erteilen; ein Store mit Mock-Daten wird nicht für einen API-Lauf verwendet.
Jede Pilotregel erhält je Modell eine Zeile mit Modellschlüssel,
`4xx`, `provider`, `parser` beziehungsweise `cost` und `passed`/`failed`.
Das gilt auch nach Resume, anhand aller gespeicherten Pilotantworten.

Die Kostenprojektion verwendet je Modell die geplanten 3.000 Aufrufe,
die Eingabeannahme aus ANK-56, das 90-%-Quantil der gemessenen
`usage.completion_tokens` und die Preise des Plans. Die Beiträge werden
zum Gesamtbetrag addiert und nach der Betreiberregel ANK-57 ohne
Wechselkurs mit 150 verglichen. Reasoning wird nicht zusätzlich auf die
Completion-Tokens addiert. Fehlende Nutzungsdaten erlauben keinen
Kosten-Pass. Auszugeben sind außerdem Latenzmedian und je Modell Median
und 90-%-Quantil der Reasoning-Tokens; für Sol bleiben die Werte je
Aufruf zur Prüfung von BL-62 zugänglich. Anbieterwechsel, wechselnde
Modellkennung innerhalb eines Blocks und Fehleranteil über ANK-67
werden als Auslöser eines Wiederholungstags berichtet. Der Betreiber
entscheidet dessen Durchführung und archiviert Storekopien samt SHA-256
nach A.8.

### Auswertung und Berichte — K-M2-6, K-M2-7

Die Hauptauswertung wählt die Hauptitems mit `concise`, `role`, `json`.
Pilot- und PB-Zeilen gehen nicht in ihre Kennzahlen ein. Je Modell:

1. `msa_fit(type = "ordinal", levels = <ANK-69>, link = "probit")`
   und daraus `msa_grr()` berechnen. Fehler und Konvergenzwarnungen
   gezielt erfassen, Ursache berichten und mit den Scores 1–5 aus
   ANK-68 numerisch neu fitten. Eine bloße Nullkomponente ist kein
   zusätzlicher Rückfallgrund. Der numerische Fit wird nicht still
   als ordinal bezeichnet; scheitert auch er, folgt ein benannter Fehler.
2. Über die 18 Hauptplanantworten je Item die Häufigkeiten einschließlich
   NA bestimmen. Eindeutiger NA-Modalwert: `has_modal = TRUE`,
   `modal = NA`; Gleichstand: `has_modal = FALSE`. Gleichstände zählen
   in `n_no_modal` und fallen aus Kappa/Trefferquote heraus.
3. Kappa anhand der linearen Übereinstimmungsgewichte berechnen. Für
   fehlende Modalantworten mit `has_modal = TRUE` erhält die zusätzliche
   NA-Zeile der Kontingenztafel Gewicht 0 gegen jede Referenzklasse.
   Fehlende Referenzen sind keine Fehlklassifikation und werden aus
   Referenzmetriken ausgeschlossen. Bootstrap über auswertbare Items,
   2.000 Wiederholungen, Seed 20261024, 95-%-Perzentilintervall, Quantile
   Typ 7 (ANK-68; ACC-19). Zahl gültiger Wiederholungen berichten;
   nicht definierte Schätzer nicht durch Ersatzwerte kaschieren.
4. `msa_agreement(..., levels = <ANK-69>, reference = "reference",
   weights = "linear")` auf allen Hauptantworten des Modells rechnen.
   Dieses Objekt liefert die vorhandenen Modal-/Alle-Antworten-
   Diagnosen und Alpha. Es wird nicht überschrieben, um AP1 zu simulieren.
   Die eigenen AP1-Modalwerte und das entscheidende Kappa befolgen die
   speziellere Regel aus A.1/ANK-68/ADR-004 Nr. 7, einschließlich NA und
   Gleichstand. Die allgemeine Modal-Konvention der Formelsammlung §5
   bleibt in den generischen Funktionen davon getrennt.
5. Trefferquoten als `n`, `hits`, `rate` für Gesamt, Quelle und
   `prior_differs_sol`, für Llama/Qwen zusätzlich ihr eigenes Kennzeichen
   ausgeben. Bei `n = 0` ist `rate = NA`. A.1 verlangt auch getrenntes
   Kappa für den Memorisierungsvorbehalt: zusätzlich `kappa_by` mit
   `by`, `group`, `n`, `estimate` nach denselben NA-/Modalregeln anbieten.
   Den NA-Anteil über alle Hauptantworten berechnen; gefährliche Fehler
   zählen nur P/LP ↔ B/LB in den ERepo-Modalantworten, nicht VUS oder
   INSAID-Fehler.
6. Vorhandene vollständige PB-Läufe gegen die Hauptplan-Modalwerte
   vergleichen. NA-Antworten und Items ohne Modalwert sind nicht stabil,
   auch NA gegen NA ist kein Treffer. Je Prompt `x`, `n` und
   `y = log((x + 0.5)/(n - x + 0.5))` berechnen (ANK-68). In PB-Reihenfolge
   `msa_robustness()` aufrufen; Effekte, PSE, ME, SME, Half-Normal-Plot
   und `delta_p[F1:F8]` ausgeben. Dabei
   `delta_p = plogis(m + e/2) - plogis(m - e/2)`, `m = mean(y)`.
   Sekundär Trefferquoten gegen verfügbare Referenzen berichten (A.5).
   Fehlende PB-Läufe werden nicht mit synthetischen Nulltreffern ergänzt;
   Robustheit bleibt dann nicht bewertet.
7. Kriterienbänder aus `plan$acceptance` bestimmen, einschließlich
   exakter Grenzkonventionen von ANK-58: GRR 10 und 30 marginal;
   Kappa am Punktschätzer; gefährliche Fehler 0/1/ab 2; Robustheit nach
   praktischer Grenze und simultaner SME. Das Gesamtverdikt entsteht
   nur, wenn alle vier Kriterien bewertet sind, als schlechtestes Band.
   Fehlende oder nicht definierte Kennzahlen erhalten kein positives Band.

Der gemeinsame Fit verwendet ausschließlich die Hauptplanantworten
aller Modelle, mit Modellkomponente und demselben dokumentierten
Rückfallpfad. Er bleibt `msa_fit`, ohne `msa_grr` und ohne Verdikt.

Rückgabevertrag nach ACC-12:

| Feld je `models[[key]]` | Inhalt |
| --- | --- |
| `grr`, `fallback` | `msa_grr` und logische Kennzeichnung des numerischen Rückfalls; Ursache zusätzlich dokumentiert. |
| `modal`, `n_no_modal` | data.frame `item_id`, `modal`, `has_modal`; Zahl der Gleichstände. |
| `kappa`, `agreement` | `estimate`, `lower`, `upper`; unverändertes `msa_agreement`-Objekt der Hauptantworten. |
| `hit_rate`, `kappa_by` | `hit_rate`: `by`, `group`, `n`, `hits`, `rate` mit allen Gruppen aus ACC-12; zusätzlich die oben beschriebenen Kappa-Strata. |
| `na_share`, `dangerous` | NA-Anteil aller Hauptantworten und Zahl gefährlicher ERepo-Modalfehler. |
| `robustness` | `NULL` oder Liste mit `response` (`prompt_id`, `x`, `n`, `y`), `effects` (`msa_robustness`), benanntem `delta_p`, `band`; sekundäre Referenztrefferquoten additiv. |
| `verdicts`, `verdict` | Benannte Kriterien `grr`, `kappa`, `dangerous`, `robustness`; `acceptable`, `marginal`, `unacceptable`, `not assessed`. Gesamt ohne vollständige Bewertung: `not assessed`. |
| `report` | Pfad des tatsächlich gerenderten, nicht leeren Berichts außerhalb des Repos. |

`msa_report()` erhält als letztes Argument `assessment = NULL`.
Bei `NULL` bleibt die bisherige Verwendung erhalten. Andernfalls ist
`assessment` eine Liste mit `criteria` (data.frame mit mindestens
`criterion`, `band`), `verdict` und `sections` (benannte Liste von
Einträgen mit `text` und optionalem `table`-data.frame). Der allgemeine
Renderer kennt keine ACMG-Auswertungsregeln; `R/acmg.R` liefert die
berechneten Inhalte. Das Fazit verwendet dann das Gesamtverdikt aus
`assessment`, während die GRR-Einstufung im Präzisionsabschnitt bleibt.
Referenzbezogene AP1-Entscheidungstabellen verwenden die AP1-NA-Regel;
vorhandene Complete-Case-Diagnosen werden als solche benannt und nicht
als zweites, abweichendes AP1-Verdikt präsentiert.

Die neuen öffentlichen Argumente sind in diesem PLAN als additive
Verträge vorgeschlagen. Der Reviewer übernimmt ihre freigegebene
Beschreibung in die zentrale Vertragsdokumentation gemäß
`IMPLEMENTATION-RULES.md` (Verträge und Schnittstellen); der Builder
setzt dazu die beschriebenen Rd-Dokumente um.

Die Berichte erfüllen A.7: CoU, Risiko und Akzeptanz aus dem Plan,
Rückfallgrund, Kappa mit Intervall, Alpha, Strata, NA-Anteil,
Gleichstände, gefährliche Fehler, Robustheit samt Delta-p/Band und
gemeinsamer Forschungsfit; außerdem angeforderte und gemeldete
Modell-/Routingdaten, Wissensstände, Seeds, Versionen und Datenhash mit
Algorithmus. Für den bestehenden Laufdatenhash bleibt die Umstellung
auf kanonisches SHA-256 in M3d (BL-18); die eingefrorenen CSVs erhalten
bereits in M2 SHA-256. Logging-/Datenregeln werden aus den in A.7
benannten lokalen Schnappschüssen mit Stand und Fundstelle dokumentiert.
Die fehlende Erkennbarkeit stiller Modellwechsel, der Vergleich von
%GRR nur auf demselben Itemsatz, der Temperaturunterschied und die
Vorläufigkeit vor M1 werden ausdrücklich genannt. INSAID-Referenzen
erscheinen ausschließlich aggregiert, auch nicht als eingebettete
Rohdatentabelle. Ohne explizites externes Berichtsziel verwendet
`acmg_evaluate()` ein eigenes temporäres Verzeichnis.

### Behandlung der offenen Acceptance-Verträge

Die ACC-Punkte sind nach `CRITERIA.json` nonblocking. Die Tabelle macht
ihre Übernahme und die noch beim Reviewer liegende Festschreibung
explizit; ein eigener Prototyp des Reviewers wird nicht als Vorgabe genutzt.

| ID | Festlegung dieses Plans |
| --- | --- |
| ACC-1 | Klassenbezeichnungen und Skalenordnung nach ANK-69. |
| ACC-2 | Genau 17 eingefrorene Spalten, in beiden CSVs identische Reihenfolge. |
| ACC-3 | Leere CSV-Felder, ISO-Datum, TRUE/FALSE; typisierte Laufzeitwerte zulässig. |
| ACC-4 | Panelauswahl nach Kandidatenzahl je Klasse im gefilterten Pool; oben präzisiert, Reviewer-ADR ausstehend. |
| ACC-5 | Gen-Umlauf je Klasse mit absteigender Kandidatenzahl und geseedeten Gleichständen; Reviewer-ADR ausstehend. |
| ACC-6 | Einheitliche Kombination `<`, fünf Klassen, flagged beibehalten, eigenes Panel ausschließen mit konservativem Fallback; siehe Entscheidungstabelle. |
| ACC-7 | USD-Schätzung gegen numerischen Euro-Budgetbetrag nach ANK-57; kein Wechselkurs. |
| ACC-8 | Zeichenvektor für Hauptvorlagen, zwölfzeiliger data.frame für PB mit allen geforderten Spalten. |
| ACC-9 | Dieselbe Komposition für Vorlagenausgabe und tatsächliche Laufprompts, einschließlich F1/F2 und Systemspalte. |
| ACC-10 | Metadatenfeldnamen und Null-Schlüssel übernommen; Backend-formals unverändert. |
| ACC-11 | CLI, Modell-/Promptschlüssel, Quelle des geladenen Pakets, externe Stores und Pilotzeilenformat übernommen. |
| ACC-12 | Ergebnisstruktur übernommen, nur additive Felder für A.1/A.7 und Diagnostik. |
| ACC-13 | YAML-Mindestfelder und Werte übernommen; expliziter `path` wird gelesen. |
| ACC-14 | ANK-TOL gelesen; kein Builder-Nachtrag oder eigene Toleranz. |
| ACC-15 | ANK-69 als Quelle nutzen; Nachtrag in ANKER-TODO bleibt Betreiberaufgabe. |
| ACC-16 | Provenienz, SHA256SUMS, Größengrenzen, INSAID-Grenzen und Abbruch vor Änderung der Ausgaben eingeplant. |
| ACC-17 | Kanonische Sortierung, RNG und Ausgabe; keine Abhängigkeit von LC_COLLATE. |
| ACC-18 | Neues letztes Argument `msa_run(..., parse_by_prompt = NULL)`; kein Aufteilen der Laufreihenfolge nach Parser. |
| ACC-19 | Bootstrap und Toleranzen übernommen; keine eingefrorenen erwarteten Fit- oder Intervallwerte. |
| ACC-20 | Fit über `msa_fit()` mit allgemeiner Erkennung von Konvergenzwarnungen, nicht Erkennung eines Testtexts. |
| ACC-21 | Fehlendes/leeres/NA-Systemfeld beziehungsweise `row = NULL` nutzt das Argument. |
| ACC-22 | Gesamtplan vor Blockfilter bilden; Replikat außen, geseedete zufällige Folge innen. |
| ACC-23 | Korrektur 0,5 aus A.5/ANK-68; keine eigene Zahlenableitung aus beschädigtem OCR. |
| ACC-24 | Rohdatenzugriff, Laufzeit und temporäres Caching berücksichtigen; keine Kernänderung allein für M2. |
| ACC-25 | Nachweis zur Testwirksamkeit zur Kenntnis; die 62 M2-Tests werden später gegen die eigene Implementierung ausgeführt. |

## Reihenfolge

1. Nach PLAN-REVIEW die Auslegungen übernehmen und deren Reviewer-ADRs
   lesen. Im ersten BUILD den M0-Abschluss in `PROGRESS.md` ergänzen:
   Runde 1, `result: pass`, Verweis auf M0 `gates.json` und `REVIEW.md`
   (BL-54). Benötigte Suggests deklarieren; keine eigene Installation.
2. YAML-Vertrag, Ladefunktion, Klassen/Aliase und geseedete Hilfsfunktionen
   aufbauen. Den additiven Wortparser und Parserdispatch mit kleinen
   Tests absichern; so stehen sie für die übrige Pipeline bereit.
3. Erzeugungsskript und Laufzeit-Itemimport umsetzen, Rohquellen prüfen,
   Auswahl einmal erzeugen und in einer temporären Paketkopie
   reproduzieren. Golden-ADR im selben BUILD ergänzen. INSAID-Spalten,
   Dateigrößen, Provenienz und Prüfsummen prüfen.
4. Drei Hauptvorlagen und PB-Komposition ergänzen; Backend-Metadaten,
   Temperatur- und Systemregel umsetzen. Mit den vorhandenen
   Aufzeichnungen und konstruierten Fehlern prüfen, ohne Netz.
5. Vollständige Laufplanung, Blockfilter, Resume, CLI und Pilotregeln
   implementieren. Mock-Teile gemeinsam und wiederholt in einem
   temporären Store ausführen; live-relevante Prüfungen separat mit
   konstruierten Metadaten testen.
6. Modellweise Auswertung, Bootstrap, Robustheit und gemeinsamen Fit
   umsetzen; Grenzfälle vor der Berichtsintegration prüfen.
7. Berichtsergänzung, Half-Normal-Plot, lokale Provenienztexte und
   Bedienungsdokumentation fertigstellen. Rd-Dateien gezielt aus
   roxygen2 erzeugen und die API gegen ANK-02 prüfen. NEWS und echte
   Prüfbelege in PROGRESS ergänzen.
8. Gezielte Unit- und M2-Abnahmeläufe abschließen. Dann übernimmt der
   Orchestrator Territoriumsprüfung, Phasen-Commit, QA-Phase und die
   vollständigen Gates. Der Builder führt auch im BUILD keine eigenen
   Git-Kommandos aus und schreibt keine Gate-Fakten.

## Risiken

| ID / Bezug | Behandlung und Zuständigkeit |
| --- | --- |
| PLAN-M2-R1; K-M2-1/2, ACC-4–6 | Auswahl und frühere Einstufung sind an wenigen Stellen auslegungsbedürftig. Dieser PLAN legt eine reproduzierbare Lesart vor; der Reviewer hält die akzeptierte Auslegung in PLAN-REVIEW/ADR fest. Keine nachträgliche Anpassung an günstigere Trefferquoten. |
| PLAN-M2-R2; K-M2-1, ACC-17/24 | Große ClinVar-Datei und Gebietsschema können Laufzeit und Reproduktion beeinflussen. Blockweises Lesen, Prüfung vor Schreiben, feste Sortierung und Messung des echten Laufs. Kein Netzzugriff oder Ersatzdatensatz. |
| PLAN-M2-R3; K-M2-6, ANK-68, BL-03/52 | Ordinaler Fit und generische NA-/Modalregeln entsprechen nicht automatisch AP1. Rückfall und eigene AP1-Auswertung mit unabhängigen Gegenrechnungen; Statistik vor M1 als vorläufig kennzeichnen. |
| PLAN-M2-R4; K-M2-4/7, BL-07/62 | Fehlende Fingerprints und variable Anbieter-/Reasoningangaben begrenzen Nachweisbarkeit. Antwortwerte unverändert speichern, unbekannte Werte offen nennen, Pilotregeln aus tatsächlichen Messungen ableiten. Live-Prüfung durch Betreiber. |
| PLAN-M2-R5; K-M2-6/7, BL-55 | Gemeinsamer Store und Teilaufrufe könnten Daten vermischen. Identitäten, Planfolge, Filter und Resume prüfen; alle Laufartefakte außerhalb des Baums. Betreiber legt während Modellphasen keine fremden Dateien im Checkout an. |
| PLAN-M2-INFRA-1; BL-56, K-M2-6 | Entscheidung über `NOT_CRAN=true` im vollständigen Test-Gate liegt beim Betreiber. Der bisher übersprungene Berichtstest wird dadurch nicht zum Builder-Scheinfix. M2-Abnahme rendert ohnehin echte Berichte; der Builder führt gezielte Renderingtests aus. Nonblocking für den Builder. |
| PLAN-M2-QA-1; AGENTS Projektblock, docs/01 §9 | QA ist ab M2 Pflicht. E2E/Fuzz und QA-Handoff entstehen in `45-qa`; bis dahin `[QA-PENDING]`, nonblocking für den Builder. Keine Übernahme fremder Testterritorien. |

In der PLAN-Diagnose wurden keine fehlenden M2-Rohdateien oder benötigten
lokalen R-Pakete festgestellt. Das ist keine Zusicherung für spätere
Gate-Umgebungen. Erforderliche fremde Änderungen oder Infrastrukturfehler
werden mit Kriteriums-/Gate-Referenz im Handoff geführt; nur der
Orchestrator bedient den Human-Touchpoint `ESCALATION-M2.md`.

### Jeder offene Backlog-Eintrag

Stand dieser Datei: 62 Einträge, davon 54 offen. Die folgende Zuordnung
ändert `BACKLOG.md` nicht. „Vertagt“ nennt Ziel und Grund; Betriebsarbeit
bleibt beim Betreiber und ist kein Produktfix des Builders.

| ID | Behandlung im M2-Plan oder begründete Vertagung |
| --- | --- |
| BL-01 | M2 liefert zuerst die Erhebungspipeline für den Terminplan. Entscheidung über M3a–M3d nach M1d bleibt beim Betreiber; der Live-Lauf läuft außerhalb des Harness. |
| BL-02 | Vertagt auf Publikationsarbeit nach validierter AP1/M1-Auswertung: Neuheitsabgrenzung ändert keines der sieben M2-Kriterien. Betreiber dokumentiert den Forschungsstand. |
| BL-03 | M2 setzt den gekennzeichneten numerischen Rückfall nach K-M2-6 um. Quantifizierung des Zwei-Stufen-Verfahrens bleibt K-M1b-3/-4 und K-M1d-7; M2 ersetzt diese Untersuchung nicht. |
| BL-04 | Vertagt auf M1c/M1d beziehungsweise AP5: Bootstrap-Überdeckung der Varianzkomponenten ist dort spezifiziert. M2 implementiert nur den Item-Bootstrap für AP1-Kappa nach ANK-68. |
| BL-05 | In M2: drei Stichtage, prior-Kennzeichen, Trefferquoten und Kappa-Strata, Memorisierungsvorbehalt im Bericht; K-M2-2, K-M2-6, A.1. |
| BL-06 | Betreiber prüft M0-Reviewer-Logs auf Umleitung und Modellzugang. M2-Builder hat weder Schlüsselzugriff noch die Aufgabe, Rollen- oder Sandboxkonfiguration zu ändern. |
| BL-07 | In M2: festes Routing ohne Anbieterfallback, angeforderte Quantisierung und tatsächlich gemeldeten Anbieter getrennt speichern; Pilot- und Wiederholungstagsregeln. |
| BL-08 | Vertagt auf AP7: Partnerdaten sind nicht Bestandteil des öffentlichen AP1-Itemsatzes. Datenschutzvereinbarung und Freigabe bleiben Betreiberaufgabe vor dieser späteren Nutzung. |
| BL-09 | In M2: INSAID-Klassen/Protein nur lokal zur Laufzeit, keine geschützten Rohdateien im Repo, Berichte nur aggregiert. Reviewer behält die Prüfung von Ankerzitaten. |
| BL-10 | Betreibertermin für Preprint bleibt an M1-Abnahme und erneute AP1-Auswertung gebunden. M2 kennzeichnet vorläufige Zahlen und bietet erneute Auswertung ohne Erhebung an. |
| BL-11 | Vertagt auf Betreiber-Kostenabgleich mit Dashboard; die protokollierten M0-Tokens sind keine Geldmessung. Keine Schätzung von Harnesskosten aus erfundenen Preisen. |
| BL-12 | Vertagt auf Betreiber-Vollläufe nach M1b/M1c und vor M1d: M2 hat keine Klasse-B-Studie. Erhebung und externe Stores werden so angelegt, dass die Arbeiten parallel laufen können. |
| BL-13 | M2-Testdauer im BUILD/Gate-Output festhalten; ClinVar- und Mock-Aufwand aus ACC-24 berücksichtigen. Erneute Messung der Simulations-/Gatebudgets bleibt M1a; Timeoutänderungen sind Betreiberarbeit. |
| BL-14 | Vertagt auf M1a–M1c: unabhängige Kernvalidierung und mutfull sind dort vorgesehen. M2 verwendet den Kern, behauptet aber keine vorgezogene Abnahme. |
| BL-15 | Vertagt auf M3a/Betreiber-Dokumentpflege: Fleiss-Kappa gehört nicht zu AP1 und wird hier nicht ergänzt. |
| BL-16 | In M2: Metadaten aus Anfrage/Antwort korrekt trennen und `temperature = NULL` wirklich auslassen; NEWS und Backend-Regression nach K-M2-4. |
| BL-17 | Vertagt auf K-M3d-3 und AP2-Liveprüfung: AP1 verwendet den OpenAI-kompatiblen Backendpfad. Bestehendes ellmer-Verhalten bleibt erhalten. |
| BL-18 | Laufdatenhash-Umstellung auf SHA-256 bleibt K-M3d-5, Bootstrap-Zählung/Meldung K-M1c-2. M2 nennt den bestehenden Berichtshash korrekt und verwendet SHA-256 für seine neuen Golden-Dateien. |
| BL-20 | Vertagt auf K-M1b-1: Vergleich von `wine`/clmm-Kovariaten ist Kernvalidierung, kein Bestandteil des AP1-Designs. |
| BL-21 | Vertagt auf Reviewer-Zuordnung bei M1a/Ankerarbeit: der geschachtelte NIST-Fall besitzt kein M2-Kriterium; keine neue Modellklasse in M2. |
| BL-22 | Vertagt auf K-M1a-2: gepoolte ANOVA-Wechselwirkung wird dort mit `interactions = FALSE` geprüft. AP1 verwendet den in K-M2-6 benannten Fit. |
| BL-23 | Vertagt auf K-M1a-4/-6: Zentrierung und NIST-Genauigkeit betreffen `R/fit.R`; keine Nebenänderung in M2. |
| BL-24 | Betreiber setzt die Mutationsbaseline vor M3a beim Scope-Wechsel zurück. M2 schreibt weder Baseline noch Scope und arbeitet mit dem bestehenden Kern-Scope. |
| BL-25 | In M2: neues Golden-ADR zusammen mit dem Itemsatz. Ankernachträge bleiben beim Reviewer mit ADR; der Builder ändert keine Referenzwerte. |
| BL-28 | Betreiber richtet Schlüssel, Guthaben und Limits vor dem echten Pilot ein. Das Laufskript nutzt dessen Umgebung; PLAN und BUILD lesen keine Schlüsseldateien. |
| BL-29 | Betreiber bearbeitet die Infevers-Anfrage; keine Nachricht durch diese Rolle. Bis zur Klärung bleiben INSAID-Referenzklassen und Proteinangaben außerhalb des Repos, Berichte aggregiert. |
| BL-30 | Vertagt auf AP2: Pages, About, Zenodo und Releases sind Betreiber-Veröffentlichungsarbeit nach Validierung; M2 benötigt keinen Push. |
| BL-31 | Git-Identität bleibt Betreiberkonfiguration. Der Builder führt auch zur Diagnose keine Git-Kommandos aus; DESCRIPTION-Maintaineradresse wird nicht verändert. |
| BL-33 | Betreiber prüft vor QA die PREFLIGHT-Routen und CLI-Vertrauens-/Sandboxkonfiguration. Keine Rollenfreigabe oder Änderung am Harness durch den Builder. |
| BL-34 | Betreiber ergänzt Erreichbarkeit im RUNBOOK; Eskalationen laufen ausschließlich über `ESCALATION-<MS>.md`. Kein zusätzlicher Human-Touchpoint im Produkt. |
| BL-35 | Vertagt ins Harness-Template: Benachrichtigungsfehler ist kein M2-Produktcode. Die projektspezifische explizite Einstellung bleibt Betreiberzuständigkeit. |
| BL-36 | Rohdaten bleiben außerhalb; M2 liest ClinVar blockweise. Ein Umzug des Repos ins WSL-Dateisystem ist bei Bedarf Betreiberarbeit, kein Bestandteil des Builds. |
| BL-37 | Wie BL-11 Betreiber-Dashboardabgleich; eine Harness-Kostenspur wird in dieser Produktphase nicht eingebaut. |
| BL-39 | Vertagt auf die jeweils betroffenen späteren Module/AP7 und Betreiber-Beschaffung. Für M2 werden keine unbelegten Normkonstanten benötigt oder ersetzt. |
| BL-40 | Vertagt auf M1d und Publikationsvergleich: die noch fehlenden Konkordanzquellen ändern die freigegebenen AP1-Schwellen nicht. Keine Ergänzung von Referenzzahlen aus Erinnerung. |
| BL-41 | AP1-Bänder als Betreiberentscheidung aus ANK-58 dokumentieren. Beschaffung von Landis & Koch und eine entsprechende Quellenzuschreibung bleiben bis zu belegbarer Nutzung beim Betreiber. |
| BL-42 | Betreiber bereitet geschützte AIAG-/Lenth-Daten zwischen Phasen vor; Reviewer-Abgleich bei den zuständigen Acceptance-Phasen. M2 benötigt diese lokalen Datenblätter nicht. |
| BL-43 | M2 übernimmt Modellkennungen, Routing und Preise aus den geernteten Ankern. Betreiber prüft sie unmittelbar vor AP1 live; spätere Planänderung nur per ADR. |
| BL-44 | Vertagt auf K-M3a-2: Fleiss-Varianzquelle gehört zur späteren Agreement-Erweiterung, nicht zum linear gewichteten AP1-Cohen-Kappa. |
| BL-45 | Betreiber aktualisiert die Fassungen im Claude-Projekt nach dem Meilenstein. Diese externe Dokumentpflege ist kein Builder-Territorium. |
| BL-46 | Vertagt auf M1d: die zusätzlichen Vignetten entstehen dort. M2 ergänzt eine kleine AP1-README und testet Rendering außerhalb des Repos; keine langen Erhebungen beim Paketbau. |
| BL-47 | Bei späteren Veröffentlichungen Betreiberhinweis zu Autoren beachten. VariantBench wird für M2 weder als Datenquelle noch als Vergleichswert verwendet. |
| BL-48 | Betreiber berichtigt Ablageverweise; `gates-auswahl.md` ist laut aktuellem Backlog unter `reference/privat/` vorhanden. Reviewer prüft weiter die Zuordnung; die fehlende maschinelle Prüfung wird nicht als Produktfehler behandelt. |
| BL-49 | Vertagt auf K-M1a-1: REML/ANOVA-Toleranz gegen Gesamtvarianz dort anwenden. M2 nutzt für vorhandene Fit-Gegenrechnungen ANK-TOL.engine_ordinal, ohne Optimierer/Toleranzen zu lockern. |
| BL-50 | Vertagt auf K-M3c-6: Planungsnäherung und empirischer CV werden dort untersucht. M2 plant die vom Betreiber bereits freigegebenen Anzahlen. |
| BL-51 | In M2: alle `acmg_*` intern und Aufruf über `llmsa:::`. Entscheidung über spätere generische Exporte nach AP1 per ADR. |
| BL-52 | In M2: externer Store, vorläufige Kennzeichnung und erneute Auswertung nach M1 ohne neue Modellaufrufe; Publikationsfreigabe bleibt davon abhängig. |
| BL-53 | Reviewer prüft im ersten M2-Code-Review den echten `done/M0`-Zweig anhand des Test-Gate-Logs. Der Builder führt diesen Git verwendenden Test nicht selbst aus und ändert ihn nicht. |
| BL-54 | Im ersten BUILD von M2 M0-Abschlussvermerk in PROGRESS mit M0 `gates.json` Runde 1/result pass und `REVIEW.md` ergänzen. In dieser PLAN-Phase bleibt PROGRESS unangetastet. |
| BL-55 | Laufdaten/Reports außerhalb des Baums; Betreiberdateien nur zwischen Modellphasen einbringen. Änderungen an Territoriumsprüfung/Rollback bleiben Templatearbeit des Betreibers. |
| BL-56 | Betreiberentscheidung zu NOT_CRAN vor Berichtänderung vorlegen; nonblocking Infrastrukturpunkt. Direkter Berichtstest und M2-Abnahme belegen Rendering; ellmer-Sonderpfad bleibt BL-17. |
| BL-57 | Die neuen letzten Argumente haben explizite Vorgaben: `whole_word = FALSE`, `parse_by_prompt = NULL`, `assessment = NULL`. Builder prüft diese zusätzlich; Reviewer führt die Schnittstellenprüfung fort. |
| BL-60 | Vertagt auf K-M3d-3: Streaming-/Mock-Erreichbarkeit von ellmer ist für den in M2 verwendeten Backendpfad nicht erforderlich. |
| BL-62 | In M2: Reasoning-Tokens je Aufruf/Modell und Pilotsummaries berichten, fehlende Fingerprints und Sol-Modellkennung als Grenze im Bericht nennen. Wirkung von durchgehend null Reasoning klärt der Betreiber im echten Pilot; keine Änderung der freigegebenen Reasoning-Stufe durch den Builder. |

Bereits erledigt und nicht wieder geöffnet: BL-19, BL-26, BL-27, BL-32,
BL-38, BL-58, BL-59, BL-61. Die beiden Nachträge von ADR-004 haben dabei
Vorrang vor den historischen httptest2- und Qwen-Abschalter-Vorschlägen.

## Testplan

### Geplante Nachweise im BUILD und in den Gates

| Kriterium | Unveränderte Abnahme und ergänzende Builder-Prüfung |
| --- | --- |
| K-M2-1 | `test-m2-1-items.R`: 17 Spalten, 75/25 und Klassenbalance, Pool und Variationzerlegung, Umläufe/Pilotfortsetzung, Lizenzgrenzen, SHA-256/Größen, identische Neuerzeugung in Kopie und Erhalt der Ausgaben ohne Rohquelle. Unit-Tests ergänzen fehlerhafte Schemas, doppelte IDs, lokale TSV-Ergänzung und localeunabhängige Auswahl. |
| K-M2-2 | `test-m2-2-memorisation.R`: unabhängiger ClinVar-Join und Prüfung aller neun Kennzeichen auf Haupt- und Pilotitems. Kleine Unit-Fälle fixieren die gewählte ACC-6-Lesart: vor/am/nach Stichtag, fehlendes Datum, Mehrheit/Gleichstand/none, eigene/fremde Panels, flagged und Nicht-Fünfklassen-Werte. |
| K-M2-3 | `test-m2-3-prompts-parser.R`: wörtliche Vorlagen, vollständig gerenderte Texte, ursprünglicher Parserpfad, Pflichtbeispiele und 10.000 geseedete Vergleichsfälle aus ANK-TOL.parser_cases. Unit-Tests für zwei verschiedene Klassen, wiederholte Aliase derselben Klasse, Satzzeichen, fehlendes JSON und vorlagenspezifischen Dispatch. |
| K-M2-4 | `test-m2-4-backends.R`: SHA-gesicherte Aufzeichnungen, Request-Body einschließlich Listen, Null-Temperatur, Metadaten/JSON, HTTP-4xx mit fortgesetztem Lauf, unveränderte Backend-formals, NEWS. Kein Request ohne passenden Mock; keine Fixture-Änderung. |
| K-M2-5 | `test-m2-5-plan.R`: alle YAML-Abschnitte und Ankerwerte, tatsächliches Lesen eines anderen Pfads, 5.400/3.600/90 Aufrufe, Kosten aus Preisen und Tokenannahmen. Unit-Tests für fehlende/ungültige Felder und Ablehnung inkonsistenter Planwerte. |
| K-M2-6 | `test-m2-6-evaluate.R`: externer Default-Store, Blockfolge und Zufall, Prompt-Hashes, unabhängige Modal-/Kappa-/Quotenrechnung, Item-Bootstrap, direkte Fit-Gegenrechnung, erzwungener Fehler und Konvergenzwarnung, fehlende/ergänzte INSAID-Referenz, gemeinsamer Fit und echte Reports. Builder ergänzt Zeilenpermutation, leere Referenzgruppen, nicht definiertes Kappa und Berichtskonsistenz zum Gesamtverdikt. |
| K-M2-7 | `test-m2-7-robustness-pilot.R`: zwölf PB-Zeilen und jede F1–F8-Stufe, All-minus-Vorlage, Request-Systempriorität, tatsächliche Prompt-Hashes, Teilmengen/Resume, Pilotzeilen, empirischer Logit, Effekte/SME/Delta-p und schlechtestes Band. Builder prüft Pilotgrenzen 26/27 Treffer, fehlende/abweichende Providerdaten, fehlende Tokens, Kostenaggregation, genau 5-%-Grenze, unvollständige PB-Läufe und sekundäre Trefferquoten. |

Für Punktwerte gelten ANK-TOL.arithmetic, für Fit-Gegenrechnungen
ANK-TOL.engine_ordinal und für Bootstrap-Grenzen die in ACC-19
festgelegte Kombination aus ANK-TOL.mc_factor, MCSE und arithmetic.
Es werden keine Toleranzen aus den beobachteten Abweichungen gewählt.
Die Abnahmetests enthalten unabhängige Mini-Rechnungen und Negativfälle;
der Produktcode importiert keine Testhilfen oder erwarteten Ausgaben.
Referenz- und Simulationsvalidierung des Kerns bleibt den späteren
Meilensteinen zugeordnet.

Geplante direkte Builder-Aufrufe aus der Paketwurzel, mit allen
Testartefakten unter temporären/externen Pfaden:

```bash
NOT_CRAN=true Rscript --vanilla -e 'testthat::test_dir("tests/testthat", load_package = "source", stop_on_failure = TRUE)'
Rscript --vanilla -e 'testthat::test_dir("tests/acceptance", filter = "m2-", load_package = "source", stop_on_failure = TRUE)'
```

Die zweite Auswahl führt alle sieben M2-Dateien aus. Die M0-Abnahmetests
mit direkten oder indirekten Git-Aufrufen bleiben dem Orchestrator
vorbehalten. Eine zusätzliche lesende API-Prüfung lädt die
Snapshot-Hilfsfunktionen, vergleicht die formals und kontrolliert die
Vorgaben der neuen Argumente; sie startet nicht den API-Test mit seinem
Gate-/Git-Unterprozess. Installationen erfolgen ausschließlich über das
deps-Gate, bei fehlender Voraussetzung entsteht ein belegter INFRA-Punkt.

Der Orchestrator führt nach BUILD/QA die vollständigen ausgewählten
Gates aus: deps, lint mit externem Paketbau und `R CMD check --as-cran
--no-manual`, tests einschließlich M0/M2 und QA, trace, territory,
mutgate und golden-adr. `88-mutfull` ist erst in M1c fällig. Der
Mutations-Scope wird nicht verändert; bei ungeplant nötiger Änderung
von `R/fit.R` oder `R/grr.R` bleibt der reguläre Mutationslauf fällig.
Keine Testlöschung, kein Skip als Ersatz für fehlende Quellen und keine
Gate-Abschwächung. Tatsächliche Kommandos, Exit-Codes, Output, Laufzeiten
und verbleibende Befunde werden im BUILD in PROGRESS/Handoff festgehalten.

### Tatsächlich ausgeführte PLAN-Diagnosen

In dieser PLAN-Phase wurden keine Unit-/Abnahmetests, kein Paketbau,
kein Check und keine Gates ausgeführt. Die folgenden lesenden Diagnosen
liefen aus der Repo-Wurzel; sie sind keine Kriterienerfüllung.

**Abhängigkeiten und lokale Eingabepfade — Exit 0.**

```bash
Rscript --vanilla - <<'RS'
pkgs <- c('yaml', 'digest', 'pkgload', 'roxygen2', 'testthat', 'httr2', 'jsonlite', 'DBI', 'RSQLite', 'rmarkdown', 'knitr')
for (p in pkgs) {
  ok <- requireNamespace(p, quietly = TRUE)
  cat(p, if (ok) as.character(utils::packageVersion(p)) else 'MISSING', '\n')
}
cat('pandoc_available', rmarkdown::pandoc_available(), '\n')
paths <- c(
  erepo = '../quellen/daten/clingen-erepo_2026-10-22/erepo_classifications_all.tsv',
  insaid = '../quellen/daten/insaid-vangijn2018_2026-10-23/insaid_klassifikation_858_varianten.tsv',
  clinvar = '../quellen/daten/clinvar_2026-10-22/submission_summary.txt.gz')
for (p in names(paths)) cat(p, 'exists', file.exists(paths[[p]]), 'bytes', file.info(paths[[p]])$size, '\n')
cat('test_dir_arguments', paste(names(formals(testthat::test_dir)), collapse = ', '), '\n')
RS
```

```text
yaml 2.3.12
digest 0.6.39
pkgload 1.5.3
roxygen2 8.1.1
testthat 3.3.2
httr2 1.3.0
jsonlite 2.0.0
DBI 1.3.0
RSQLite 3.53.3
rmarkdown 2.32
knitr 1.52
pandoc_available TRUE
erepo exists TRUE bytes 32422295
insaid exists TRUE bytes 42155
clinvar exists TRUE bytes 404817924
test_dir_arguments path, filter, reporter, env, ..., load_helpers, stop_on_failure, stop_on_warning, package, load_package, shuffle
```

Eine zusätzliche Python-Inventur zählte die Testblöcke, verglich die
Fixture-Hashes mit ANK-94 und las die M0-Gate-Fakten; Output (Exit 0):

```text
m2_test_blocks 62
backlog_total 62 open 54
fixture sol.json sha256_match True
fixture llama.json sha256_match True
fixture qwen.json sha256_match True
M0 gate facts: round=1 result=pass
M2 handoff files: CRITERIA.json
```

Die letzte Zeile beschreibt den Bestand vor Erstellung dieses Plans.
Die Rohdaten wurden hier nur auf Vorhandensein/Größe geprüft; ihre
vollständige Hash-, Schema- und Inhaltsprüfung ist für BUILD/Abnahme
eingeplant. Die 62 Testblöcke wurden statisch gezählt, nicht ausgeführt.
Der vorhandene Renderer wurde außerdem mit fehlenden, nicht verwendeten
Itemfeldern aufgerufen; er lieferte `Classify PAH NM_000277.2:c.1A>G.`.
Es gibt daher aus dieser Diagnose keinen Anlass, `R/utils.R` zu ändern.

Eine lesende Nachrechnung aus ANK-53–57 ergab für Hauptplan und
Robustheit die folgende Schätzung (ohne Pilot/Reserve, keine Messung
eines echten Laufs; Exit 0):

```text
Anchored cost estimate (USD): sol=66.00, llama=6.39, qwen=1.92, total=74.31
Budget comparison by ANK-57: 74.31 < 150
```

Die Dokumentprüfung per Python verglich die Überschriften mit SCHEMA,
die IDs mit BACKLOG/CRITERIA und ein vor dem Schreiben aufgenommenes
SHA-256-Inventar der Produkt-, Test-, Anker-, Spezifikations- und
Vertragsdateien sowie der gelesenen Stammdateien. Output (Exit 0):

```text
PLAN schema: 6/6 sections in required order
Backlog: 54/54 open entries addressed exactly once; 8 closed entries named separately
Criteria: 7/7; acceptance notes: 25/25
Markdown: paired fences; no trailing whitespace; UTF-8/LF
Protected inventory unchanged: 120 files, SHA-256 4f4d997c39081718bf5da62c389fcbb9c52b6e63dfbd00531282879bbc6f7f4a
M2 handoff files: CRITERIA.json, PLAN.md
```

Dies ist eine Dokument- und Bestandsprüfung, keine vollständige
Territoriumsprüfung. Letztere und den Commit führt der Orchestrator aus.
Ein M2-Gate-Erfolg wird mit diesem PLAN nicht behauptet.
