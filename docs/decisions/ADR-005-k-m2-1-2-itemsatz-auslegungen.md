# ADR-005 — Itemsatz AP1: Auslegungen zu K-M2-1 und K-M2-2

## Status

Angenommen (Reviewer, M2 `30-plan-review` Runde 1, 27.10.2026). Bindend nach Ende der Planrunden von M2 (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“). Ein Punkt fällt nur durch ein deckendes wörtliches Spec-Zitat in einem PLAN-UPDATE. Offene Punkte ACC-1 bis ACC-6, ACC-16 und ACC-17 in `orchestrator/handoff/M2/CRITERIA.json`; Lesarten des Builders aus `orchestrator/handoff/M2/PLAN.md` (Runde 1, Abschnitt „Items und Memorisierung“); Einwände E6 und E10 in `orchestrator/handoff/M2/PLAN-REVIEW.md`.

## Kontext

- K-M2-1 legt Spalten, Pool, Umlauf, Pilot, `QUELLE.txt` und die byte-identische Neuerzeugung fest, K-M2-2 die Memorisierungskennzeichen (`docs/03-anwendungspipeline.md`).
- Die Spec schweigt zu folgenden Punkten: zur Schreibweise von `reference` (ACC-1) und zu weiteren Spalten (ACC-2); dazu, was „leer“ heißt und welche Formate gelten (ACC-3); zur Bezugsmenge der „Einstufungszahl“ (ACC-4) und zur Reihenfolge der INSAID-Gene (ACC-5). Bei der früheren Einstufung (ACC-6) lässt sie offen, was „vor“ heißt, welche Werte zählen, ob „flagged submission“ zählt und wie das Expertenpanel ausgeschlossen wird. Offen sind auch die Prüfungen des eingefrorenen Ordners (ACC-16) und die Unabhängigkeit der Neuerzeugung vom Gebietsschema (ACC-17).
- Die Abnahmetests lassen mehrere Lesarten zu (ACC-4: drei, ACC-6: 16 Kombinationen). Dieses ADR legt genau eine fest. Erzeugungsskript, Golden-ADR des Builders, Bericht und spätere Meilensteine verwenden dann dieselbe Regel.
- `docs/01-fachspezifikation.md` §7: „keine Referenzklasse je Variante im Repo oder in Veröffentlichungen“ (INSAID). §5: „Seeds: jede Randomisierung (…, Datenauswahl) trägt einen protokollierten Seed“.

## Entscheidung

1. **Klassenbezeichnungen (ACC-1).** `reference` und alle Klassenwerte der Pipeline tragen die Bezeichnungen von A.3 in Skalenordnung (`ANK-69`): Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic. Die Schreibweisen der ERepo („Likely Pathogenic“, „Uncertain Significance“) und von INSAID („VOUS“) werden über die Aliase von A.3 abgebildet.
2. **Spalten (ACC-2).** `items.csv` und `pilot.csv` haben genau die 17 Spalten von K-M2-1, in beiden Dateien in derselben Reihenfolge: `item_id`, `source`, `gene`, `transcript`, `hgvs`, `protein`, `reference`, `panel`, `prior_clinvar_class_*`, `prior_date_*`, `prior_differs_*`, je mit `_sol`, `_llama`, `_qwen`. Weitere Spalten gibt es nicht, insbesondere keine ClinVar-Variation-ID, keine INSAID-Klasse und keine INSAID-p.-Angabe.
3. **Leere Felder und Formate (ACC-3).** „Leer“ ist ein leeres CSV-Feld; eingelesen ergibt es die leere Zeichenkette, nie die Zeichenkette „NA“. Formate:
   - `prior_differs_*`: `TRUE` oder `FALSE`.
   - `prior_date_*`: ISO-Datum `JJJJ-MM-TT`.
   - `prior_clinvar_class_*`: eine der fünf Klassen in der Schreibweise von A.3 (für diese Klassen gleich der Schreibweise von ClinVar), `conflicting` oder `none`.

   `acmg_items()` darf Typen umwandeln (logical, Date, `NA`). Ein leeres `prior_differs_*` wird dabei `NA`, nie `FALSE`; ein solches Item gehört in Auswertungen weder zur Gruppe `TRUE` noch zur Gruppe `FALSE`.
4. **Umlauf ERepo (ACC-4, Lesart (a) des Builders).** „Einstufungszahl“ ist die Zahl der Kandidaten des Panels in der jeweiligen Klasse, gezählt im Pool nach K-M2-1 nach allen Filtern. Je Klasse gilt:
   - Die Panels sind absteigend nach dieser Zahl geordnet; Gleichstände ordnet der Zufall mit dem Seed aus `ANK-59`.
   - Je Panel wird ohne Zurücklegen in Zufallsreihenfolge gezogen.
   - Der Umlauf besucht jedes nicht erschöpfte Panel einmal je Runde.
   - Picks 1–15 einer Klasse gehen nach `items.csv`, Picks 16–17 desselben Umlaufs nach `pilot.csv`. Der Pilot wird nicht neu gezogen.
5. **Umlauf INSAID (ACC-5).** Es zählen nur Varianten mit Status `Validated` aus den Genen von `ANK-59`. Je Klasse sind die Gene absteigend nach ihrer Kandidatenzahl in dieser Klasse geordnet; Gleichstände ordnet der Zufall mit demselben Seed. Je Gen wird ohne Zurücklegen gezogen, fünf Varianten je Klasse. Das Transkript stammt nur aus `ANK-64`; `hgvs` ist `<transcript>:<cDNA der TSV>`. Weder `item_id` noch die Zeilenfolge von `items.csv` lassen die INSAID-Klasse erkennen (`docs/01` §7).
6. **Memorisierungskennzeichen (ACC-6).** Eine einzige Kombination gilt für alle Items, alle drei Stichtage und beide Dateien:
   1. Das Datum ist `DateLastEvaluated` (`ANK-63`). Einreichungen ohne Datum („-“) zählen nie.
   2. „Vor dem Stichtag“ heißt strikt davor (`<`), je Suffix mit `ANK-50`, `ANK-65` beziehungsweise `ANK-66`.
   3. Als Einstufung zählen nur die fünf Klassen, ohne Rücksicht auf Groß- und Kleinschreibung. „not provided“, „-“, „other“ und Risikoallele zählen nicht.
   4. Einreichungen mit Status „flagged submission“ zählen.
   5. Ausgeschlossen sind die Einreichungen des eigenen Expertenpanels. Das sind Einreichungen mit Status „reviewed by expert panel“ (`ANK-63`), deren Einreichername den Panelnamen ohne nachgestelltes „VCEP“ enthält. Verglichen wird in Kleinschreibung, Leerraum wird zusammengefasst. Trifft das auf keine Einreichung der Variante zu, werden alle Einreichungen mit diesem Status ausgeschlossen.
   6. Unter den verbleibenden Einreichungen zählt das jüngste Datum. An diesem Datum entscheidet die Mehrheit der Klassen, bei Gleichstand gilt `conflicting`. Bleibt keine Einreichung, gilt `none` mit leerem `prior_date_*`.
   7. `prior_differs_*` ist `TRUE` genau dann, wenn die Klasse weder `none` noch (ohne Rücksicht auf Groß- und Kleinschreibung) gleich `reference` ist. `conflicting` ergibt damit `TRUE` (Wortlaut K-M2-2).
   8. Bei INSAID-Items bleiben alle neun Kennzeichenspalten leer.
7. **Eingefrorener Ordner (ACC-16).** Für den Ordner gilt:
   - `SHA256SUMS` hat je Datei des Ordners außer sich selbst eine Zeile `<sha256>  <name>`, mindestens für `items.csv`, `pilot.csv` und `QUELLE.txt`.
   - Die Größengrenzen folgen `ANK-TOL.data_size`; MB und KB zählen als 10^6 und 10^3 Byte.
   - `QUELLE.txt` nennt Quelle und URL (`erepo.clinicalgenome.org`), Stand (`ANK-51`), Lizenz CC0 und die Auswahlregel mit Verweis auf dieses ADR. Dazu kommen der Skriptpfad `data-raw/make_items_ap1.R`, die SHA-256 der INSAID-TSV (`ANK-52`) und die INSAID-Transkripte aus den Methoden samt Widerspruch zu Tab. 1 (`ANK-64`). Eine INSAID-Klasse oder -p.-Angabe steht dort nicht.
   - `QUELLE.txt` und `SHA256SUMS` sind deterministisch: kein Zeitstempel, nichts aus der Sitzung. Ein erneuter Lauf erzeugt alle vier Dateien byte-identisch.
   - Fehlt `../quellen/daten/`, bricht das Skript vor jedem Schreiben ab, mit einer Meldung, die „quellen“ nennt. Vorhandene Ausgaben bleiben unverändert.
8. **Reproduktion (ACC-17).** Das Skript arbeitet unabhängig vom Gebietsschema: Sortierung mit `method = "radix"` oder fester C-Kollation, Datumsangaben in C-Locale. Es setzt den Zufallsgenerator ausdrücklich (`RNGkind("Mersenne-Twister", "Inversion", "Rejection")`) und den Seed 20261024, als Literal oder mit Verweis „ANK-59“. Es schreibt UTF-8 mit LF. Vor der Auswahl prüft es den Pool gegen `ANK-51` (1.180 Einstufungen, 71 Gene, 35 Panels, Zahlen je Klasse) und bricht bei einer Abweichung mit benanntem Fehler ab.

## Konsequenzen

- Die Abnahmetests `tests/acceptance/test-m2-1-items.R` und `test-m2-2-memorisation.R` lassen diese Lesarten bereits zu: ACC-4 in der Lesart „class_pool“, ACC-6 in der Kombination „lt, five, keep, own“ mit Rückfall. Sie ändern sich nicht. Die Unit-Tests des Builders fixieren die gewählte Kombination (PLAN, Testplan K-M2-2).
- Golden-Daten: Das Golden-ADR des Builders entsteht im BUILD, also im Diff seit `plan/M2` (Gate golden-adr), und verweist für die Auswahlregeln auf dieses ADR. Dieses ADR liegt vor `plan/M2` und erfüllt golden-adr nicht.
- Der Bericht (A.7) nennt die Regeln der Memorisierungskennzeichen als Teil der Methode.
- Änderungen nur durch ein neues ADR. Nach dem Einfrieren des Itemsatzes ändert jede Änderung Golden-Dateien und verlangt das ADR im selben Meilenstein.
