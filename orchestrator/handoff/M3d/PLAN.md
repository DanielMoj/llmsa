# PLAN — M3d, Runde 1

Stand: 06.11.2026. Rolle: Builder, Phase `20-plan`, Runde 1.
Diese Phase schreibt ausschließlich diesen Plan. Produktcode und Tests wurden
nicht geändert; es wurden keine R-Tests, Gates oder Git-Kommandos ausgeführt.
Die nachstehenden Implementierungs- und Prüfaufträge gelten für BUILD nach
der Planfreigabe. Der Plan erteilt keine Abnahme.

## Ziel

M3d macht Ausführung und Wiederaufnahme reproduzierbar, schließt die belegten
Parser- und Backendlücken und ergänzt einen zahlen- und herkunftstreuen
Validierungsbericht. Die bereits abgenommenen statistischen Rechenverfahren
bleiben Grundlage der Darstellung.

Gelesene Pflichtgrundlage: `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`,
`orchestrator/handoff/M3d/CRITERIA.json`, sämtliche sechs M3d-Abnahmedateien
und `tests/acceptance/setup-m3d.R` einschließlich ihrer einschlägigen
gemeinsamen Helfer. Fachgrundlage sind `docs/00-vision.md`,
`docs/01-fachspezifikation.md`, `docs/04-weitere-bausteine.md`, Abschnitt M3d
(K-M3d-1 bis K-M3d-6), die betroffenen M1-/M2-Verträge und die
Formelsammlung §§2–4, 8, 11–12. Zusätzlich wurden die betroffenen
Produktdateien, Unit-Tests, Anker und historischen Gleichheitsprüfungen
abgeglichen.

| Kriterium | Geplantes Ergebnis | Maßgeblicher Nachweis |
| --- | --- | --- |
| K-M3d-1 | CSV bewahrt textuelle IDs; ein neu erzeugtes Mock-Backend mit gleichem Seed liefert dieselben Antworten je Designzeile. Abbruch und Resume verlieren und verdoppeln keine abgeschlossene Zeile. | 50 Abbruchpunkte nach ANK-TOL, beide Speicherarten; ACC-2/3. |
| K-M3d-2 | Unicode-Minus wird korrekt gelesen; das erste JSON-Objekt wird vollständig validiert und sein Feld auf oberster Ebene dekodiert. Beide bisherigen Choice-Modi bleiben erhalten. | Je 10.000 generierte Eingaben pro Parser nach ANK-TOL; unabhängige Erwartungswerte und Orakel, ACC-4–6. |
| K-M3d-3 | Beide realen Adapter geben die aufgezeichneten Texte und Metadaten wieder; HTTP-Fehler, Timeout und leere Antworten werden gespeichert und der Lauf geht weiter. Fehlendes ellmer hat eine dokumentierte Diagnose. | Unveränderte ANK-94-Aufzeichnungen, Fehlerfolgen und separater Prozess ohne ellmer; ACC-7–9. |
| K-M3d-4 | Alle verlangten Berichtszahlen folgen ihren Eingabeobjekten und ANK-93; eine übergebene Regelkarte wird mit Verletzungszahlen und Positionen dargestellt. | Tatsächlich gerendertes Markdown, zusätzliche HTML-Regression; ACC-10/11. |
| K-M3d-5 | Der Bericht nennt SHA-256 über eine vollständig festgelegte kanonische Lauftabelle. | Unabhängige Byte-Kanonisierung, Permutationen und einzelne Wertänderungen; ACC-12. |
| K-M3d-6 | Konventionen, abgeleitete Komponenten, Modellgrenzen, R_4s-Lesart, Seeds und sämtliche beobachteten Modellmetadaten sind nachvollziehbar. | Gerenderte Berichte einschließlich fehlender Angaben und Anbieterwechsel; ACC-13/14. |

Die Prüfauslegungen ACC-1 bis ACC-16 werden als Planbasis übernommen; die
angekündigte Festschreibung im ADR gehört dem Reviewer. Die nachfolgend
benannten Fragen P-M3d-01 und P-M3d-02 werden dabei ausdrücklich vorgelegt.
ACC-16 dokumentiert eine Reviewer-Probe mit 31 Tests und 20 roten Tests im
Ausgangsstand sowie eine erfolgreiche Attrappe. Das sind gelesene
Reviewer-Belege, keine Builder-Testläufe und keine Implementierungsvorlage.
Die Attrappe wird nicht in das Produkt übernommen.

Die Betreiberentscheidung in BL-11 zieht M3d vor M3c vor. M3d berichtet
deshalb die vorhandene Spannweiten-Lesart von R_4s; die zusätzliche
Westgard-Lesart, Simulator und Fallzahlplanung gehören weiterhin zu M3c.

## Dateien

Aktueller Schreibumfang: `orchestrator/handoff/M3d/PLAN.md`.
Der voraussichtliche BUILD-Umfang ist:

| Pfad | Änderung und Zweck |
| --- | --- |
| `R/run.R` | Texttypen beim CSV-Einlesen; Behandlung leerer Backendantworten und Fehlerwerte; bestehende zeilenweise Speicherung und Interrupt-Weitergabe absichern. |
| `R/backends.R` | Zeilenbezogene private Zufallsziehung im Mock; Antwortmetadaten des geklonten ellmer-Chats übernehmen; Backendvertrag dokumentieren. |
| `R/parse.R` | U+2212 normalisieren; erstes JSON-Objekt mit Zeichenketten-/Escape-Zustand abgrenzen und mit jsonlite validieren/dekodieren. |
| `R/report-data.R` (neu) | Interne `msa_report_*`-Helfer für kanonische Bytes, SHA-256 und Aufbereitung beobachteter Metadaten; keine neuen Exporte. |
| `R/report.R` | Letztes Argument `control_chart = NULL`, Eingabeprüfung, Übergabe der neuen Berichtsdaten und Dokumentation der Kanonisierung/Abhängigkeiten. |
| `R/grr.R` | Ausschließlich Seed-Provenienz am Ergebnis von `msa_boot()` und zugehörige roxygen-Dokumentation, nach Klärung P-M3d-01. |
| `R/robustness.R` | Verwendeten PB-Seed am Design halten und an `msa_robustness()` weitergeben; zugehörige roxygen-Dokumentation, nach Klärung P-M3d-01. |
| `inst/templates/validation_report.Rmd` | Westgard-Tabelle, SHA-256-Zeile, Konventionen, Seeds, Modelltabelle; bisherige Zahlenformate und fachliche Hinweise erhalten. |
| `man/backends.Rd`, `man/parsers.Rd`, `man/msa_run.Rd`, `man/msa_report.Rd`, `man/msa_boot.Rd`, `man/pb_design.Rd`, `man/msa_robustness.Rd` | Aus den betroffenen roxygen-Blöcken erzeugte Hilfen. Erzeugung in Paketkopie; nur sachlich betroffene Dateien übernehmen. |
| `tests/testthat/test-run-resume.R` (neu) | Neustart, Text-IDs, Interrupt, bestehende Fehlerzeilen, privater RNG und vollständig erledigter Store. |
| `tests/testthat/test-parser-properties.R` (neu) | Kleine semantische Parserregressionen und metamorphe Fälle zusätzlich zur großen Reviewer-Stichprobe. |
| `tests/testthat/test-backend-metadata.R` (neu) | Adaptermetadaten, leere Antworten, Weiterlauf, präziser JSON-Speicherrundlauf und Chat-Isolation. |
| `tests/testthat/test-report-provenance.R` (neu) | Kanonisierung, Seeds, vollständige Metadatensätze und Regelkartenbericht; kleine unabhängige Byte-Beispiele und echte Renderfälle. |
| `tests/testthat/test-seed-provenance.R` (neu) | Serialisierbare Seed-Attribute und unveränderte numerische Resultate/RNG-Wirkung von Bootstrap und PB. |
| `tests/testthat/test-robustness-transform.R`, `tests/testthat/test-robustness-properties.R` | BL-128: eigene Darstellungscharakterisierungen kennzeichnen; fehlenden abschließenden Zeilenumbruch mit Verbraucherbeispiel prüfen. |
| `NEWS.md`, `PROGRESS.md` | Englische Änderungsnotizen; deutsche Umsetzung, tatsächliche Befehle, Outputs, Grenzen und Handoff. |

Keine Änderungen an `DESCRIPTION`/Imports oder Exportliste sind vorgesehen:
jsonlite und digest stehen bereits in Suggests. `R/fit.R`, `R/agreement.R`,
`R/spc.R`, `R/acmg.R`, Studienerzeuger und eingefrorene Daten sind keine
Implementierungsbaustellen dieses Plans. Anker, Abnahme-, Simulations- und
QA-Tests, Fixtures, Specs, Orchestratorzustand und Gate-Auswahl gehören den
jeweiligen anderen Rollen. Ein gegebenenfalls erforderliches Auslegungs-ADR
und die Behandlung historischer Abnahmeverträge liegen beim Reviewer.

## Schnittstellen

### Öffentliche API und Seed-Provenienz

Die 22 bestehenden Exporte und sämtliche bisherigen Argumentpositionen und
Vorgabewerte bleiben erhalten. `msa_report()` bekommt hinter `assessment`
das letzte Argument `control_chart = NULL` (ACC-11). Akzeptiert wird ein
`msa_control_chart`-Objekt; ein anderer nichtleerer Objekttyp endet vor dem
Rendering mit benannter englischer Fehlermeldung. Der Rückgabewert bleibt
der unsichtbar zurückgegebene Berichtspfad. Assessment-Verdikt und
AP1-Zusatzabschnitte behalten ihre Wirkung.

Der Design-Seed ist bereits unter
`attr(attr(runs, "design"), "seed")` verfügbar. Geplant sind zusätzlich:

- `attr(boot, "seed")`: explizit übergebener, verwendeter Seed von
  `msa_boot()`, erst bei Bildung des Ergebnisobjekts ergänzt.
- `attr(pb_design, "seed")`: expliziter Seed der tatsächlich randomisierten
  PB-Zeilenfolge. Bei `randomize = FALSE` wird kein verwendeter Seed
  behauptet, auch wenn das ignorierte Argument gesetzt ist; damit bleibt
  die bestehende Gleichheit zum unrandomisierten Design erhalten.
- `attr(robustness, "seed")`: Weitergabe dieses Designattributs, ohne
  Rückschluss aus dem aktuellen RNG oder aus einer vermuteten Aufrufhistorie.

`seed = NULL`, alte serialisierte Ergebnisse und einfache Designs ohne
Provenienz liefern ausdrücklich `not reported`. Attribute werden am Objekt
gespeichert und überleben RDS-Rundläufe; es gibt kein globales Register.
Zusätzliche Attribute sind nach `docs/01` §4 erlaubt. Die konkrete
Abgrenzung gegenüber K-M1d-8/ADR-051 und der historischen Dateisperre ist
P-M3d-01; vor dessen Entscheidung werden keine Seed-Änderungen gebaut.

### Ausführung und Speicher — K-M3d-1 und K-M3d-3

1. Der CSV-Leser liest `item_id`, `prompt_id`, `model_id` und `value`
   ausdrücklich als Text. Weitere textuelle Speicherfelder behalten ihren
   Inhalt; numerische Struktur-/Zeitspalten behalten ihren bisherigen
   Zweck. Insbesondere bleiben `001` und `010` als IDs unterscheidbar.
   Bestehende CSV-/SQLite-Schemata und der Schlüssel aus Block, Item,
   Prompt, Modell und Replikat werden weiter unterstützt.
2. Das Mock zieht Replikatrauschen und `p_fail` aus einer stabilen Mischung
   des expliziten Seeds und der vollständigen Zeilenidentität
   `(block, item_id, prompt_id, model_id, rep)`. Längenmarkierte UTF-8-Teile
   vermeiden mehrdeutiges Zusammenkleben; begrenzte Ganzzahlarithmetik
   vermeidet Überlauf. Kein Aufrufzähler, keine Position im verbliebenen
   Plan und keine Sonderbehandlung der Abnahme-IDs gehen ein.
   Prompt-/Modelleffekte bleiben pro ID fest. Fehlende `block`/`rep` in
   direkten Backendaufrufen erhalten stabile, dokumentierte Standardwerte.
   Ohne expliziten Seed wird wie bisher beim Erzeugen ein privater
   Ausgangszustand gewählt; die Wiederaufnahmegarantie bezieht sich auf
   denselben expliziten Seed. Vorhandener und nicht vorhandener globaler
   RNG-Zustand werden nach privaten Ziehungen wiederhergestellt.
3. Eine `interrupt`-Bedingung beendet den Lauf und wird nicht als regulärer
   Backendfehler umgedeutet. Jede davor abgeschlossene Antwort ist bereits
   gespeichert. Resume überspringt alle gespeicherten Schlüssel, auch
   Fehler- und nicht parsbare Antworten, und kontaktiert sie nicht erneut.
4. Backendfehler sowie fehlender, `NA`- oder leerer Antworttext ergeben
   einen nichtleeren `error`-Text und `value = NA`; anschließend folgt die
   nächste Designzeile. Bei einem Backendfehler kann ein benutzerdefinierter
   Parser keinen scheinbar gültigen Wert erzeugen. Ein vorhandener,
   nichtleerer, aber nicht parsbarer Text bleibt dagegen eine nicht
   parsbare Antwort nach bisherigem Vertrag. Leerraum allein ist nach
   ACC-8 keine neue Fehlerklasse.
5. Antworttext, vorhandene Metadaten, Zeitstempel und Latenz bleiben echte
   Laufdaten. Metadaten werden weiterhin mit voller numerischer Präzision
   serialisiert (ADR-009). Der Resume-Vergleich nimmt ausschließlich
   `timestamp` und `latency_s` aus; der Datenhash umfasst später auch diese
   Spalten. Alte Stores werden nicht nachträglich umgeschrieben oder neu
   geparst.

### Parser — K-M3d-2

- `parse_number()` normalisiert U+2212 vor der bestehenden Zahlenerkennung
  auf ASCII-Minus; R-Quelltext verwendet die Unicode-Escape-Schreibweise.
  Dezimalzeichen, Vorzeichen, e/E-Exponenten, Einheiten und vorangestellte
  Bezeichner wie IC50 werden gemäß ACC-4 geprüft. Tausendertrennzeichen,
  mehrere Zahlen und zusätzliche Exponentenschreibweisen werden nicht
  stillschweigend als neue Grammatik eingeführt.
- `parse_choice()` behält Teilzeichenkettenmodus und `whole_word = TRUE`,
  längste passende Bezeichnung, Aliasbehandlung und Mehrdeutigkeitsregeln
  aus K-M2-3/ANK-69. Die grüne Ausgangsfunktion erhält keine fachliche
  Umgestaltung; beide Modi werden in der Regression geprüft.
- `parse_json_field(field)` findet das erste `{` und verfolgt Klammern,
  Zeichenketten und Escapes bis zum Ende genau dieses Objekts. Klammern
  innerhalb von Strings zählen nicht zur Verschachtelung. Anschließend
  validiert/dekodiert jsonlite das vollständige Objekt mit
  `simplifyVector = FALSE`; der Feldzugriff ist exakt auf oberster Ebene.
  Strings werden dekodiert, Zahlen wie `as.character(as.numeric(t))`
  zurückgegeben. Fehlendes Feld, nur verschachteltes Feld, Syntaxfehler,
  ungültiges Escape oder ein unvollständiges erstes Objekt ergeben `NA`.
  Ein zweites Objekt rettet das erste nicht. Datenabhängige Parsefehler
  verlassen die Parserfunktion nicht als Fehler.
- jsonlite bleibt eine optionale Paketabhängigkeit, wird aber für diese
  Parserfabrik benötigt. Die Fabrik prüft die Verfügbarkeit und nennt bei
  Fehlen eine dokumentierte englische Installationsdiagnose; für einen
  erzeugten Parser gilt die Fehlerfreiheit auf den vereinbarten Eingaben.
  Diese Festlegung wird in P-M3d-02 zur Bestätigung vorgelegt. Für die in
  ACC-6 ausgenommenen Feldwerte wird kein zusätzlicher Vertrag behauptet.

### Aufgezeichnete Backends — K-M3d-3

`backend_ellmer()` verwendet weiter pro Aufruf einen frischen Chat-Klon.
Nach dem Chat-Aufruf werden Text und Antwortkörper des letzten Turns
ausgelesen; in der eingefrorenen Version liegt letzterer laut ausgeführter
Reviewer-Probe in `ch$last_turn()@json`. `meta$model_snapshot` stammt exakt
aus `model`, `meta$provider` nur aus einem vorhandenen Antwortfeld
`provider`, `meta$usage` aus dem unveränderten verschachtelten Verbrauch.
Bestehende Metadaten wie `client` können erhalten bleiben. Fehlende Felder
werden nicht aus Chat-Namen, angefordertem Routing oder Token-Summen
erfunden. Auch hier gilt: Nur Antwortinhalt wird geparst, kein Reasoningtext.

`backend_openai_compatible()` behält seine bereits abgenommenen Felder,
Routingparameter, Systemnachrichten und Genauigkeit. Der gemeinsame
Runner behandelt leere Antworten beider Adapter. Die Hilfeseite nennt
die bestehende Diagnose wörtlich:
`Package \`ellmer\` is required for backend_ellmer().`

Verifikation erfolgt mit den unveränderten drei Antwortkörpern von ANK-94,
synthetischen Zugangsdaten und `httr2::local_mocked_responses()`. URL und
JSON-Feld `model` bestimmen die Zuordnung; eine nicht zugeordnete Anfrage
endet im Test mit Fehler. Es gibt keine echte API-Anfrage, keinen Zugriff
auf Schlüssel und keine neue Aufzeichnung durch den Builder. BL-60 gilt
nach ACC-7 als durch den Reviewer ausgeführt geklärt; die Regression wird
trotzdem gegen den implementierten Adapter durchgeführt.

### Berichtszahlen und Konventionen — K-M3d-4 und K-M3d-6

Die bestehenden Überschriften zweiter Ebene und erkannten Text-/Tabellenformen
für Precision, Agreement, Bias, Robustness und Conclusion bleiben nutzbar.
Neue Erläuterungen stehen auf eigenen Zeilen. Werte werden aus den
übergebenen Objekten gelesen, nicht im Renderer neu geschätzt.

- Rundungen aus ANK-93: Varianz und SD vier Nachkommastellen; Prozentwerte
  eine; ICC, Kappa einschließlich Fleiss und Alpha drei; Bias und
  Intervallgrenzen vier; Konfidenzniveau in Prozent null; Lenth PSE, ME,
  SME und Effekte vier; Lenth-t zwei; Bootstrap-Tabelle zwei. Bestehende
  p-Wert-Formate bleiben erhalten. `NA` bleibt `NA`, `Inf` bleibt `Inf`,
  ndc wird als Kategorieanzahl, Verdikte in Großbuchstaben und Flags als
  TRUE/FALSE dargestellt. Insbesondere darf fehlendes ndc nicht zu Inf
  werden. Die Darstellung verwendet einen Dezimalpunkt.
- Ein eigener Regelkartenabschnitt enthält die Tabelle `Rule`,
  `Violations`, `Positions`: jede Regel aus `attr(chart, "rules")` und
  `reject`; gezählt werden TRUE-Werte, die zugehörigen `index`-Werte
  erscheinen aufsteigend. Ohne Karte ist die Bewertung `not assessed`.
  Eine eigene Zeile erläutert R_4s als `range` auf `consecutive` Werten.
- Precision nennt 1.41 für ndc, die tatsächliche Verdiktbasis und beide
  Schwellen des GRR-Objekts. Die 1-%-/9-%-Contribution-Schwellen werden in
  beiden Basisvarianten ausdrücklich als Konvention bezeichnet. Auf
  latenter Skala bleiben auch die AIAG-Schwellen als Konvention benannt.
- Für jede Quelle in `grr$derived` wird die Zwei-Stufen-/Range-Methode
  ausgewiesen. Der Bericht nennt das Modell ohne Block- und
  Dreifach-Wechselwirkungen. Der Hinweis aus K-M1c-7 zur festgelegten
  latenten Restvarianz und die eingeschränkte Robustheitsaussage aus
  K-M1d-8 bleiben fachlich und zahlenmäßig erhalten.
- Je eine Zeile berichtet Design-, Bootstrap- und Plackett-Burman-Seed;
  fehlende Provenienz heißt `not reported`. Es werden keine Seeds aus
  aktuellen globalen Zuständen rekonstruiert.
- Eine Modelltabelle hat `Model ID`, `Model`, `Provider`, `Quantization`.
  Je Modell werden alle verschiedenen beobachteten Werte von
  `model_snapshot`, `provider`, `quantizations` aus allen zugehörigen
  `meta`-Zeilen aufgenommen. Ein zweiter Anbieter darf nicht verloren
  gehen. Feldzugriffe sind exakt, insbesondere kein Partial Matching von
  `provider` auf `provider_order` (M2 E31). Fehlende Werte heißen
  `not reported`; angeforderte Quantisierung bleibt als solche kenntlich.
  Unlesbare Metadaten werden benannt, nicht durch vermutete Angaben
  ersetzt. Versions- und Sessionangaben sowie die AP1-Abschnitte bleiben
  erhalten; geschützte Referenzklassen werden weiterhin nur aggregiert
  berichtet.

BL-130 wird bewusst vertagt (ACC-15): Ein zusätzliches Skalenattribut
für `transform = "logit"` und seine Druckausgabe sind kein M3d-Kriterium.
Die bestehende Hilfeseite erklärt die Logit-Skala. Hier kommen ausschließlich
die zur geforderten Seed-Provenienz nötigen Attribute hinzu.

### Kanonische Lauftabelle — K-M3d-5

Der interne Serialisierer setzt ACC-12 unmittelbar als allgemeines
Datenformat um; er verwendet keinen Produkt- oder Abnahme-Hash als Sollwert.

1. Ausgangspunkt ist `as.data.frame(runs)` mit sämtlichen Spalten und
   Zeilen, ohne Objektattribute und Zeilennamen. Spaltenfolge:
   `block`, `item_id`, `prompt_id`, `model_id`, `rep`, danach alle übrigen
   Namen in UTF-8-Bytereihenfolge. Die Kopfzeile enthält quotierte Namen.
2. Logische Werte werden TRUE/FALSE, Integer dezimal, Double mit
   `sprintf("%.17g")` und Dezimalpunkt serialisiert. NA, NaN, Inf und -Inf
   bleiben unterscheidbar. Faktoren über ihre Stufennamen und andere
   Spalten über `as.character()` werden UTF-8-Text; Text erhält doppelte
   Anführungszeichen, innere Anführungszeichen werden verdoppelt.
   Fehlende Werte sind unquotiertes NA. Eingebettete Zeilenumbrüche
   bleiben Teil des Textwerts.
3. Die Sortierung folgt Block, Item, Prompt, Modell, Replikat: numerische
   Schlüssel nach Wert, übrige nach Textbytes, fehlende Werte zuletzt.
   Schlüsselgleichstände werden nach den Bytes der gesamten serialisierten
   Zeile aufgelöst. Doppelte Zeilen bleiben enthalten.
4. Felder werden durch Komma getrennt; jede Zeile einschließlich der letzten
   endet mit LF. Der Hash ist `digest::digest()` mit `algo = "sha256"`,
   `serialize = FALSE` über genau diese Bytes, in kleinen Hexziffern.
   Keine RDS-Serialisierung, keine Locale-abhängige Sortierung und kein
   Abschneiden auf 15 signifikante Stellen.
5. Die Berichtzeile benennt Daten/Lauftabelle und SHA-256 ausdrücklich.
   Ohne `runs` gibt es keinen erfundenen Hash. digest wird vor der Nutzung
   geprüft und in der Hilfe genannt. Der bisherige Prompt-Hash aus
   `hash_text()` bleibt ein eigener, unveränderter Vertrag (ACC-15).

## Reihenfolge

1. **Planprüfung:** Reviewer bestätigt ACC-Auslegungen und entscheidet
   P-M3d-01/02. Die vorhandenen Seed-Anforderungen werden mit den
   historischen Prüfverträgen abgeglichen, bevor BUILD sie umsetzt.
2. **Ausgangsbelege:** In BUILD Positivlisten-Paketkopie und Datei-/API-
   Inventur anlegen. Kleine Reproduktionen der bekannten Produktfehler
   sowie die unveränderte M3d-Abnahme ausführen; echte Ergebnisse
   protokollieren. Infrastrukturfehler getrennt ausweisen.
3. **Ausführung und Parser:** Text-IDs, zeilenbezogenen Mock-RNG,
   Interrupt-/Fehlerpfade und beide Parserkorrekturen implementieren;
   unmittelbar mit kleinen Regressionen prüfen.
4. **Backend:** ellmer-Metadaten und dokumentierten Abhängigkeitsfehler
   ergänzen; beide Adapter mit Aufzeichnungen und kompletter Fehlerfolge
   prüfen, einschließlich persistierter JSON-Werte.
5. **Provenienz und Bericht:** Nach der Vertragsklärung Seed-Attribute
   ergänzen; kanonische Bytes unabhängig prüfen; Reportparameter,
   Regelkarte, Konventionen und Metadatentabelle integrieren. Bestehende
   Berichtszahlen und AP1-Assessment-Verwendung gezielt gegenprüfen.
6. **Dokumentation und Regression:** Hilfen erzeugen, BL-128 erledigen,
   NEWS/PROGRESS mit tatsächlichen Belegen schreiben. M3d-Abnahme,
   betroffene M2-/M1-/M3-Regressionswege, Unit-/QA-Suite und Paketcheck
   nach dem unten beschriebenen Testplan ausführen.
7. **Übergabe:** Befehle, Exit-Codes, Outputs, offene Grenzen und Dateien
   im zugewiesenen Handoff/PROGRESS dokumentieren. QA, Territoriumsprüfung,
   Phasen-Commit, kumulative Gates und Abnahme erfolgen durch die
   zuständigen Rollen. Kein Eingriff zwischen BUILD und GATES.

## Risiken

### Referenzierte Punkte für das Plan-Review

**P-M3d-01 — Historische Gleichheit und neue Seed-Attribute.**
Ref: K-M3d-6/ACC-14; `docs/01-fachspezifikation.md` §4:
„zusätzliche Attribute“ sind ohne ADR erlaubt; zugleich
`docs/02-statistikkern.md`, M1d-Voraussetzung, Zeile 78:
„M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“
K-M1d-8, Zeile 92: „Das Objekt von `msa_robustness()` und die Bänder bleiben
unverändert.“ ADR-051 Nr. 9.3 bestätigt für M3b das bisherige Objekt ohne
neues Attribut.

Die aktuellen Tests `test-m1d-7-findings.R:138` und
`test-m1d-8-robustness-wording.R:83` vergleichen weiterhin die aktuellen
Quelldateien bzw. vollständigen Ergebnisobjekte mit `done/M1c`.
Eine zusätzliche Seed-Zuweisung in `R/grr.R` verletzt den ersten Vergleich;
das Weiterreichen eines PB-Seeds berührt den zweiten einschließlich der
eingebetteten AP1-Ergebnisse. Das ist eine statisch erkannte
Vertragsabhängigkeit, kein hier ausgeführter roter Gate-Lauf.

Vorschlag an den Reviewer: Die historische M1d-Beschränkung auf dem
unveränderlichen Abschlussstand von M1d weiterhin vollständig prüfen und
für M3d ausschließlich die neuen Provenienzattribute zulassen. Gegenüber
dem alten Objekt müssen alle bisherigen Spalten, Attribute, Zahlen,
Bootstrap-Replikate und AP1-Bänder weiterhin identisch sein; Seed-Werte
werden zusätzlich separat geprüft. Der bestehende K-M1c-7-Vergleich des
Bootstrap-Kerns bleibt erforderlich. Der Reviewer hält die zeitliche
Abgrenzung und ihre Prüfform als ADR fest; der Builder verändert keine
Abnahmetests. Es werden weder ganze Tests übersprungen noch fachliche
Erwartungen entfernt. Falls die Spec diese Abgrenzung nicht trägt, gilt
`ESCALATE` nach PROTOCOLS §3; ein Schatten-Wrapper in einer anderen Datei
oder eine versteckte Seed-Ablage ist keine Lösung.

**P-M3d-02 — Optionale JSON-Abhängigkeit.**
Ref: K-M3d-2, ACC-6 und `docs/01` §5 (Suggests/Abhängigkeiten).
Vorgeschlagen ist die dokumentierte Voraussetzung jsonlite beim Erzeugen
von `parse_json_field()`. Sie ersetzt den unvollständigen Regex-Decoder
durch einen standardkonformen Decoder aus einer vorhandenen Abhängigkeit.
Die Factory-Diagnose bei fehlendem Paket wird von der zugesagten
Fehlerfreiheit bei beschädigten Eingabetexten unterschieden. Reviewer
bestätigt diese konkrete Auslegung; es gibt keinen stillen Fallback, der
bei fehlender Bibliothek alle Eingaben als NA ausgibt, und keinen neuen
Import ohne ADR.

**P-M3d-03 — Numerische Studienprovenienz.**
Ref: K-M1c-7, K-M1d-6/7, `boot_implementation()` in
`inst/validation/sim/boot_coverage_helpers.R`.
Der Implementierungshash umfasst den Funktionskörper von `msa_boot()` und
ändert sich auch bei einer reinen Seed-Attributergänzung. Historische
`*_session.txt`-Hashes werden deshalb nicht auf den neuen Code umetikettiert.
Die bisherigen numerischen Resultate und die vorgeschriebene Reproduktion
der ersten `n_check` Wiederholungen müssen weiterhin stimmen. Der Handoff
nennt den Provenienzunterschied; falls eine Neuerzeugung von Studienartefakten
verlangt wird, entscheidet der Reviewer fachlich, Vollläufe gehören dem
Betreiber. Die Seed-Ergänzung allein rechtfertigt keinen neuen Volllauf.

**P-M3d-04 — Infrastruktur und Aufwand, nonblocking für den Builder.**
Ref: BL-13, BL-86, BL-123, BL-138, ACC-15;
`tests/acceptance/setup-m3d.R:384` und `setup-m2.R` Replay.
`httr2::req_dry_run()` kann im Replay einen lokalen Socket benötigen;
frühere Builder-Läufe scheiterten daran. Im Fall eines erneuten Fehlers
werden Befehl und Output als `[INFRA]` dokumentiert; die unveränderte
Abnahme muss im Gate-Umfeld laufen. Testhelfer und Berechtigungen werden
nicht umgangen. Der M3d-Aufwand fällt nach aktueller Auswahl je Mutant an;
die 42,6 s der Ausgangsprobe sind ein Reviewer-Messwert, keine Prognose für
den vollständigen Mutationslauf. Neue Unit-Prüfungen bleiben klein.
Mutations-Scope, Auswahl, Floor/Ratchet und `MUT_WORKERS=14` verwaltet
allein der Betreiber. Die Baseline-Datei war bei der lesenden Prüfung
dieser PLAN-Phase nicht vorhanden; das stimmt mit BL-123 überein.

Weitere Regressionsrisiken: Die korrigierte Mock-Ziehung kann neue
synthetische Datensätze gegenüber früheren Aufrufzählerfolgen ändern;
bestehende Stores und Golden-Daten werden deshalb nicht regeneriert.
JSON wird strenger, bisher fälschlich angenommene Syntax wird NA. Bericht-
Hashes sind absichtlich typ- und wertgenau und umfassen auch Auditspalten;
sie garantieren keine Gleichheit verschiedener realer API-Läufe.
UTF-8, CRLF/LF, Kollation, Dezimaloptionen und Windows-Pfade werden geprüft.
Ein Linux-Test ersetzt weder Windows-CI noch den noLD-Nachweis (BL-137/138).
LESSONS wird durch vollständige Fehlerklassenprüfungen an beiden Adaptern
und beiden Speichern berücksichtigt, statt nur einzelne Texte zu behandeln.

### Vollständige Backlog-Zuordnung

Stand ist der gelesene Bestand BL-01 bis BL-138. „Bestand“ bezeichnet einen
bereits dokumentierten Nachweis oder eine weiter geltende Einschränkung,
keine neue Schließung durch diesen Plan. Offene Teilaufgaben bleiben beim
genannten Eigentümer; BACKLOG wird vom Builder nicht geschrieben.

| ID | Behandlung in M3d oder begründete Vertagung |
| --- | --- |
| BL-01 | M3d auf die sechs Kriterien begrenzen; die Betreiberpriorität für AP1 und den 26.11. bleibt. Terminsteuerung beim Betreiber. |
| BL-02 | Literatur-/Neuheitsabgrenzung an Betreiber/Publikationsarbeit vor Paper-Verwendung vertagen; keine Produktanforderung dieses Meilensteins. |
| BL-03 | M1d-Befund zu zwei Stufen als Bestand; abgeleitete Komponenten jetzt nach K-M3d-6 ausweisen. Allgemeine Methodenforschung bleibt AP5. |
| BL-04 | Bestehenden Coverage-/Overcoverage-Hinweis erhalten; weitergehende Bootstrap-Forschung AP5, keine neue Studie für M3d. |
| BL-05 | AP1-Memorisierungsvorbehalte und getrennte Auswertung erhalten; keine Änderung der historischen Klassifikationsdaten. |
| BL-06 | Modellzugang und Umleitungsprüfung bleiben Betreiber-PREFLIGHT/Logprüfung; kein Zugriff auf Rollen- oder API-Zugänge durch den Builder. |
| BL-07 | Beobachtete Anbieter vollständig im Bericht zeigen; Live-Stichprobe und Wiederholungstage bleiben AP1-Betreiberaufgaben. |
| BL-08 | Datenschutzvereinbarung bei AP7 durch Betreiber; M3d verwendet vorhandene Aufzeichnungen und synthetische Tests. |
| BL-09 | Schutzregel jetzt einhalten: Quellen/INSAID-Einzelklassen nicht kopieren oder in Berichte aufnehmen; Ankerzitate prüft Reviewer. |
| BL-10 | Go/No-Go und Einreichung bleiben Betreiber-/Publikationsentscheidungen nach AP1-Auswertung; kein zusätzliches M3d-Arbeitspaket. |
| BL-11 | Entscheidung vom 04.11. umsetzen: M3b, M3a, M3d vor Termin; M3c danach. Kosten-/Dashboard-Abgleich bleibt beim Betreiber. |
| BL-12 | Vollläufe laut Backlog erledigt; Bestand und Reproduktionsprüfung erhalten, keine Wiederholung wegen reiner Metadaten ohne Entscheidung. |
| BL-13 | Aktuelle Test-/Renderdauer im BUILD messen; Gate-/Mutationbudget und Infrastrukturentscheidung beim Betreiber, keine gelockerten Grenzen. |
| BL-14 | Vorhandene unabhängige Kernnachweise erhalten; neue M3d-Belege aus Bytes, Aufzeichnungen, Orakeln und Invarianzen statt Eigenwert-Snapshots. |
| BL-15 | Fleiss-Implementierung als Bestand in Zahlentreue einbeziehen; noch offene Projektdokument-Korrektur beim Betreiber. |
| BL-16 | Erledigtes Routing/Logging mit M2-/M3d-Replays regressionsprüfen; keine neue Routingkonvention. |
| BL-17 | ellmer-/OpenAI-Aufzeichnungsprüfung in K-M3d-3 übernehmen; Live-Lauf vor Release bleibt AP2/Betreiber. |
| BL-18 | MD5-Datenhash in K-M3d-5 ersetzen; bereits korrigierte Bootstrap-Zählung/Meldung erhalten. Prompt-MD5 bleibt eigener Vertrag. |
| BL-19 | Erledigtes Paket-/Seitenlayout erhalten; kein Betreiberpfad wird geändert. |
| BL-20 | Unterschied wine-Referenzmodell/msa-Modell bleibt dokumentierter M1b-Bestand; M3d ändert keine Modellformel. |
| BL-21 | Geschachtelten NIST-Ankerkandidaten an Reviewer/Forschungsplanung vertagen; kein M3d-Kriterium und keine neue Modellklasse. |
| BL-22 | Abgenommenen AIAG-Pooling-Nachweis erhalten; Report zeigt die übergebenen Ergebnisse ohne neue Interaktionsrechnung. |
| BL-23 | NIST-Genauigkeitsbefunde bleiben in der Validierung; numerische Verbesserungen außerhalb M3d, da kein Fit-Eingriff vorgesehen. |
| BL-24 | Scope-Umstellung als erledigten Betreiberbestand behandeln; aktuelle Baseline-Zuständigkeit unter BL-123. |
| BL-25 | ANK-93 liegt aus ACCEPTANCE vor; ADR/Festschreibung durch Reviewer. Keine Builder-Ankeränderung. |
| BL-26 | Vorliegende Aufzeichnungen unverändert gegen ANK-94 nutzen; keine neuen API-Aufnahmen. |
| BL-27 | Freigegebenen AP1-Plan/ADR-004 beibehalten; keine Änderung von Prompts, Faktoren oder Schwellen. |
| BL-28 | Zugänge, Schlüssel und Limits bleiben beim Betreiber vor Live-Erhebung; keine M3d-Abhängigkeit von echten Schlüsseln. |
| BL-29 | Infevers-Anfrage/Nennungsrecht bleiben Betreiberaufgabe; Veröffentlichungsbeschränkung gilt weiter. |
| BL-30 | Pages, About, Zenodo und Releases an AP2/Betreiber vertagen; kein Deployment in der Builderphase. |
| BL-31 | Git-Identität ist Betreiberkonfiguration; bei Push/Release prüfen lassen, kein Git-Aufruf durch Builder. |
| BL-32 | Ausführbare Gates/Ignore-Regeln als erledigten Bestand erhalten; keine neuen Gates vorgesehen. |
| BL-33 | CLI-/Sandbox-Routen und PREFLIGHT bleiben beim Betreiber; keine Änderung von Freigabemodi. |
| BL-34 | Erreichbarkeit im RUNBOOK durch Betreiber klären; Eskalationsweg bleibt der protokollierte Human-Touchpoint. |
| BL-35 | Template-Benachrichtigungsfehler an Betreiber/Template-Wartung vertagen; Projektkonfiguration bleibt in dessen Territorium. |
| BL-36 | Dateisystemumzug/Spiegelkosten bleiben Betreiberoptimierung bei Bedarf; M3d benötigt keinen Rohdatenimport. |
| BL-37 | Kosten-Telemetrie an Template-Wartung/Betreiber vertagen; Dashboard-Abgleich zusammen mit BL-11. |
| BL-38 | Erledigte Verdict-/Rundenzuordnung erhalten; aktuelle Entscheidungen ausschließlich in passenden Reviewer-/Gate-Artefakten. |
| BL-39 | Quellenbeschaffung beim Betreiber nach fachlichem Bedarf; für den beschriebenen M3d-Vertrag liegen Anker/Aufzeichnungen vor. |
| BL-40 | Weitere Quellen-/Publikationsbeschaffung bleibt Betreiber/Reviewer; keine ungesicherten Zahlen für M3d ergänzen. |
| BL-41 | Landis/Koch-Bandbezeichnungen nicht als empirisch bewiesene Grenzen darstellen; weitergehende Belege bei Publikationsarbeit klären. |
| BL-42 | Geschützte AIAG-/Lenth-Daten als lokale Regressionsvoraussetzung erhalten; fehlende Daten benannt melden, keine Ersatzwerte oder Skips. |
| BL-43 | Live-Modellkennungen/Preise prüft Betreiber vor AP1; M3d verifiziert aufgezeichnete Kennungen statt einen neuen Live-Stand zu behaupten. |
| BL-44 | Fleiss ohne zusätzlichen Standardfehler als abgenommenen Bestand erhalten; keine neue SE-Schnittstelle. |
| BL-45 | Veraltete Projekt-/Betreiberdokumente bei nächster Betreiberpflege korrigieren; Specs nicht durch Builder ändern. |
| BL-46 | Erforderliche Vignetten-/Paketchecklaufzeit protokollieren; keine zusätzlichen großen Studien im Unit-Pfad. |
| BL-47 | VariantBench-/Autoren-/Publikationsfragen bleiben Betreiberarbeit vor Paper; außerhalb der sechs M3d-Kriterien. |
| BL-48 | Gate-Zuordnung ist Betreiberbestand; noch offene Automatisierung an Harness-Wartung vertagen, keine Gate-Auswahl durch Builder. |
| BL-49 | Abgenommene REML-Toleranz-/Orakelregeln erhalten; ausschließlich ANK-TOL für numerische Vergleiche. |
| BL-50 | CV-/Planungsfrage an M3c nach dem 26.11. vertagen; M3d ändert `msa_plan()` nicht. |
| BL-51 | `acmg_*` bleiben intern; Exportentscheidung nach AP1 mit ADR, keine neue öffentliche Domänen-API. |
| BL-52 | Erneute AP1-Auswertung nach M1-Abnahme bleibt Betreiberauftrag; Berichtregression ersetzt diese Erhebung/Auswertung nicht. |
| BL-53 | Historische M0-Gleichheitsabgrenzung als erledigten Bestand erhalten; Analogon für P-M3d-01, keine eigenen Git-Prüfungen. |
| BL-54 | M0-Abschlussnachtrag ist vorhanden; nicht erneut als offenen Builderpunkt behandeln. |
| BL-55 | Rollback-/Basisfragen bleiben beim Betreiber; keine fremden Änderungen während dieser Phase und kein eigener Zustandsfix. |
| BL-56 | Vorhandene NOT_CRAN-Regel bei lokalen Reportprüfungen beachten; Gate-Konfiguration beim Betreiber. |
| BL-57 | Neue Reportoption ausschließlich angehängt mit NULL; API-Obermenge prüfen, Snapshot nicht verändern. |
| BL-58 | Gelieferte Quellen als Bestand erhalten; keine neue Quellenkopie/Datenerzeugung in M3d. |
| BL-59 | Erledigte Memorierungskennzeichen erhalten; M3d ändert keine Itemdaten. |
| BL-60 | Durch ACC-7 ausgeführte ellmer-Replay-Probe geklärt; Regression gegen den neuen Adapter und Reviewer-Pflege des Backlog-Status. |
| BL-61 | Qwen-Reasoningpolitik erhalten: Inhalt parsen, aufgezeichnete Reasoning-/Verbrauchsangaben nicht als Antwort behandeln. |
| BL-62 | Sol-Reasoning-/Fingerprint-Einschränkungen erhalten; fehlende Werte im Bericht nicht ergänzen. |
| BL-63 | Dokumentierte Anbieter-/Privacy-Regeln erhalten; verbleibende Betreiberbelege gehören in AP1/Publikationspflege, keine erfundenen Zusagen. |
| BL-64 | Pilot-Quantil vom Kappa-Plan zu entkoppeln bleibt gesonderte AP1-Wartung nach Betreiberauftrag; keine Änderung von `R/acmg.R` für M3d. |
| BL-65 | Erledigte Fehlstellenzählungen regressionsprüfen; neue generische Modelltabelle ergänzt, ersetzt aber keine AP1-Diagnose. |
| BL-66 | Erledigte Diagnose fehlender API-Belege erhalten; Weiterlauf/Resume darf die Pilotsperre nicht umgehen. |
| BL-67 | Erledigte Herkunftsdiagnose und schreibgeschütztes Ablehnen unklarer Stores erhalten. |
| BL-68 | Formulierung zum unveränderten AP1-Store an nächste AP1-Wartung vertagen; kein sachlicher Bezug zur generischen M3d-Korrektur. |
| BL-69 | Reasoning-Kostenbelege als Bestand erhalten; Prüfung am echten Pilot bleibt Betreiberaufgabe. |
| BL-70 | Phasen-/Status-/Timeout-Korrekturen gehören zur Harness-Wartung; außerhalb des Builderterritoriums. |
| BL-71 | Historische ClinVar-Stände/Kennzeichen an Betreiber-Auswertung nach geltendem ADR vertagen; Golden-Daten bleiben unangetastet. |
| BL-72 | Erledigte Pfad-/Toleranzbefunde berücksichtigen: neue Pfadtests plattformneutral, keine gelockerten Toleranzen. |
| BL-73 | AP1-Pilotbericht und Kostenformat bei nächster AP1-Wartung nach Betreiberauftrag; hier keine Änderung der Kosten- oder Quantilschätzung. |
| BL-74 | Erhebungsdauer/Blockplanung bleiben AP1-Betreiberaufgabe; keine parallelen Modellaufrufe als M3d-Zusatz. |
| BL-75 | AP1-Latenz inklusive Netzpausen vor endgültigem AP1-Bericht separat klären; M3d schreibt gespeicherte Latenz nicht um. |
| BL-76 | Erledigte Fit-/Planungs-NEWS als Bestand erhalten; neue NEWS betreffen nur die hier geplanten Änderungen. |
| BL-77 | Handoff-Zitat-/QA-Hygiene bleibt bei Reviewer/QA; neue eigene Bezüge nennen genaue Fundstellen. |
| BL-78 | Vorhandene Mutationsauswahl ist Betreiberbestand; Aufwand unter BL-13 messen, keine eigenmächtigen Ausschlüsse. |
| BL-79 | Archivierung von Mutationsberichten an Betreiber/Harness-Wartung vertagen; eigene Outputs vollständig im Handoff referenzieren. |
| BL-80 | Falschen Spec-Verweis/NIST-Reihenfolge durch Betreiber korrigieren lassen; kein Builder-Spec-Eingriff und keine Änderung des geprüften Falls. |
| BL-81 | Behandlung fehlender Gruppierungswerte aus M1b als Bestand erhalten; keine neue Fit-Semantik in M3d. |
| BL-82 | Dokumentierte eingebettete Engine-Aufrufe erhalten; Seed-Attribute verändern keinen Fit-Aufruf. |
| BL-83 | Dokumentierten Aufruferrahmen erhalten; keine Auslagerung/Neuverkabelung des Fit-Kerns für Metadaten. |
| BL-84 | Verbleibende numerische Mutationslücken an Kernwartung nach 26.11. vertagen; keine zusätzlichen Fit-Eingriffe ohne Kriterium. |
| BL-85 | Quellbindung von Äquivalenzfreigaben bleibt Reviewer/Betreiber; keine alten Freigaben auf neue Quellen übertragen. |
| BL-86 | Socket-/mirai-/Zeitprüfungsprobleme mit echtem Output als INFRA behandeln; regulärer Gate-Lauf beim Betreiber. |
| BL-87 | Hohe Wiederholpräzision als bekannte Einschränkung erhalten; numerische Verbesserung nach Termin separat, kein M3d-Fit-Rework. |
| BL-88 | Dokumentierten Aufwand der dichten Projektion erhalten; Performancearbeit an numerischer Engine vertagen. |
| BL-89 | Plattform-/Infrastrukturregeln aus bestehender Entscheidung erhalten; aktuelle Windows/noLD-Prüfung beim Betreiber. |
| BL-90 | Erledigte M2-Warnungs-/Orakelregel in Regression beibehalten; Backendfehler und Fit-Warnungen nicht vermischen. |
| BL-91 | Latente Permutations-/Ankerfrage beim Reviewer belassen; keine neue Toleranz durch Builder. |
| BL-92 | M1d-Konvergenzstudie als abgenommenen Befund erhalten; keine neue Ordinalsimulation für Berichtsdarstellung. |
| BL-93 | Veraltete Reviewer-Testhelfer/Warnungen bei nächster Reviewerpflege; nonblocking und außerhalb des Builderterritoriums. |
| BL-94 | Erledigte Negativfixture-Korrektur erhalten; Fixtures nicht bearbeiten. |
| BL-95 | Erledigte QA-/Namespace-Frage beachten: stets das Paket unter Test laden, keine unmutierte Fremdkopie. |
| BL-96 | Dokumentierte geschlossene Mutationslücken als Bestand; keinen neuen Score ohne ausgeführten Lauf behaupten. |
| BL-97 | Erledigte NEWS-Pflege erhalten; kein erneutes historisches Arbeitspaket. |
| BL-98 | Erledigte Identifizierbarkeitsbegriffe erhalten; keine statistischen Umbenennungen im Renderer. |
| BL-99 | Bereits erledigte Claims/Testlücken als Bestand; verbleibende Punkte unter BL-102, keine pauschale Äquivalenzfreigabe. |
| BL-100 | Numerische Dreiwege-/Degenerationsfälle an Kernwartung nach 26.11. vertagen; keine Änderung der Modellklasse für M3d. |
| BL-101 | Latente Auswahl/Nullgewichte nach 26.11. separat bearbeiten; Seed-Provenienz benötigt keine Eingabeselektion. |
| BL-102 | Restliche numerische Mutationslücken nach 26.11.; neue Äquivalenzanträge nur bei konkretem Bedarf mit Einzelbeleg. |
| BL-103 | Projekt-Rollbackfix als Bestand; verbleibende Template-Arbeit beim Betreiber außerhalb der Modellphase. |
| BL-104 | Projektregel zu vollständiger Testausführung erhalten; Template-Nachzug an Betreiber vertagen. |
| BL-105 | Durch Infrastruktur verbrauchte Runden/PREFLIGHT gehören zur Harness-Wartung; keine Budget-/Zustandsänderung durch Builder. |
| BL-106 | Betreiberänderungen nur zwischen Phasen als neue Basis; keine Reparatur fremder Dateien innerhalb BUILD/GATES. |
| BL-107 | Scope-/Ratchet-/Rundenwiederherstellung bleibt Betreiberaufgabe; aktuelle M3-Konfiguration nicht ändern. |
| BL-108 | Kleine positive REML-Varianzen/Präzisionsgrenzen nach 26.11. separat; vorhandene Diagnose bleibt. |
| BL-109 | Latenten Wiederholbarkeitshinweis erhalten; AP1-Sensitivität mit Interaktionen bleibt Betreiber-Auswertung. |
| BL-110 | Härtung der Studien-CSV-Eingaben nach 26.11.; keine Änderung dieser Erzeuger durch den generischen Store-Fix. |
| BL-111 | Korrigierten Spec-Pfad als erledigten Bestand behandeln. |
| BL-112 | Erledigte Robustheitswortwahl und ME-/SME-Unterscheidung ausdrücklich im Bericht erhalten. |
| BL-113 | Abgenommene Modalregel aus M3a erhalten; AP1-Sonderregel nicht angleichen. |
| BL-114 | Tarballgröße/Ignore-Zeilen an AP2 nach 26.11. und Betreiber vertagen; keine Klasse-B-Dateien löschen. |
| BL-115 | Locale-Abhängigkeit alter Studien-Implementierungshashes an spätere Studienwartung vertagen; neuer Datenhash erhält eigene explizite Byte-Regeln. |
| BL-116 | Erledigte Windows-Umgebungsvariable beachten; neue Tests verwenden keine leeren Environment-Einträge als vermeintliches Unsetzen. |
| BL-117 | Manuelle Studieninput-Schemahärtung nach 26.11.; kein M3d-Kriterium, keine Ergebnisdateiänderung. |
| BL-118 | Erledigte pkgdown-Artikelliste erhalten; Betreiberdatei nicht bearbeiten. |
| BL-119 | Herkunft/Extraktion der LLM-Stability-Labels vor Paper-Verwendung durch Betreiber entscheiden lassen; keine stille Golden-Neuerzeugung. |
| BL-120 | Erledigte Vignettenreihenfolge/Statusbeschriftung erhalten. |
| BL-121 | DESCRIPTION nennt inzwischen die Seiten-URL; Backlog-Abgleich und pkgdown-Prüfung bleiben Reviewer/Betreiber bei Release-Arbeit. Kein eigener Prüferfolg behauptet. |
| BL-122 | Nachträglichen M1d-Mutationsbeleg als laut Backlog erledigt behandeln; kein weiterer Volllauf für diesen historischen Auftrag. |
| BL-123 | Betreiber hat Baseline vor M3d entfernt; Existenzprüfung dieser Phase bestätigt das. Scope-bezogene Verwaltung bleibt Harness-Auftrag. |
| BL-124 | Hohe ordinale Item-Varianz/Laplace-Bias an eigenes Statistikkern-Arbeitspaket vertagen; Betreiber vor betroffener AP1-/Paper-Interpretation informieren, keine neue Engine in M3d. |
| BL-125 | Zusätzliche PB-Kontraste erst nach erster Veröffentlichung; AP1-Sensitivität separat durch Betreiber. Lenth-Rechnung hier unverändert. |
| BL-126 | Kalibrierte ME-/SME-Schranken erst nach erster Veröffentlichung; bestehende konservative Lenth-Konvention weiter benennen. |
| BL-127 | Erweiterte PB-/Robustness-Eingabevalidierung nach 26.11./erster Veröffentlichung; Seed-Metadaten erfordern keine Ausweitung dieses Vertrags. |
| BL-128 | In M3d übernehmen: eigene Ausgabecharakterisierungen kommentieren und abschließenden Zeilenumbruch prüfen. Äquivalenzanträge nur einzeln bei späterem Gate-Bedarf. |
| BL-129 | Plotlayout nach 26.11. oder bei späterem Grafikeingriff; M3d ändert weder Plotpositionen noch Grafikgrenzen. |
| BL-130 | Entscheidung: vertagt auf Robustheitsdarstellung nach 26.11.; gemäß ACC-15 außerhalb M3d, zusätzlicher Skalenvertrag neben Seed-Änderung würde Umfang erweitern. |
| BL-131 | Bereinigte QA-Hygiene als Bestand erhalten; QA-Dateien gehören QA. |
| BL-132 | Entartete Bias-/Level-Eingaben nach 26.11. separat; keine Änderung von `R/agreement.R` für einen zahlengetreuen Renderer. |
| BL-133 | Bedingungsreihenfolge/R²-Hinweis bei nächstem Agreement-Eingriff nach 26.11.; Report übernimmt jetzige Objekte ohne neue Statistik. |
| BL-134 | Agreement-Charakterisierungen und zusätzliche Grenztests bei nächstem Eingriff nach 26.11.; keine sachfremden Test-/Codeänderungen in M3d. |
| BL-135 | [QA-PENDING], nonblocking: QA entfernt `tests/e2e/testthat-problems.rds` in nächster QA-Phase und prüft ihre Artefakte. Builder löscht sie nicht. |
| BL-136 | Reviewer/QA berücksichtigen irr-Fehler bei vollständigen Matrizen; neue numerische Agreement-Belege nutzen unabhängige Paarzählung/geeigneten Orakelpfad. Report vergleicht mit Objektwerten. |
| BL-137 | Betreiber-CI-Fix als Ausgangsbestand erhalten; Reviewer liest dessen Diff im nächsten Code-Review mit, Betreiber bestätigt CI nach Push. Keine erneute Bias-Implementierung hier. |
| BL-138 | CI-/noLD-Rückkopplung ist Betreiber-/Harness-Auftrag vor folgendem Meilenstein/Release; lokale Linux-Checks ausdrücklich begrenzen. |

## Testplan

### M3d-Abnahme und unabhängige Builder-Regressionsfälle

| Prüfweg | Inhalt und Bestehensmaßstab |
| --- | --- |
| `test-m3d-1-resume.R` | Alle ANK-TOL-Abbruchpunkte in CSV und SQLite, Interrupt vor dem nächsten Aufruf, neuer Mock mit demselben Seed, exakte vergleichbare Zeilenmenge, eindeutige Schlüssel. Ergänzend: fertigen Store ohne weitere Backendaufrufe fortsetzen; Text-IDs, Fehlerzeilen und direkten Mock-Aufruf ohne block/rep prüfen. |
| `test-m3d-2-parsers.R` | Je Parser die volle vorgegebene Stichprobe und Seeds. Zahlenerwartung aus generierter Semantik, Choice zusätzlich gegen beide M2-Referenzen, JSON gegen gültige Syntax und dekodierte Feldwerte. Kleine Unitfälle für Unicode-Minus, Klammern im String, Escape-Decodierung, verschachtelte gleiche Schlüssel, beschädigtes erstes und gültiges zweites Objekt. |
| `test-m3d-3-backends.R` | Drei ANK-94-Aufzeichnungen gegen beide Adapter; gespeicherte verschachtelte usage exakt. Je Adapter ok_first, HTTP 500, HTTP 401, Timeout, leerer HTTP-Body, null content, leerer content, ok_last: acht Zeilen, sechs benannte Fehler, nachfolgender Erfolg. Fehlendes ellmer im isolierten Teilprozess gegen die erzeugte Hilfe. |
| `test-m3d-4-report-numbers.R` | Echtes GFM-Markdown mit unveränderter voller Kennzahlprüfung und ANK-93. Regelkarte: jede Regel und reject, TRUE-Anzahlen und tatsächliche Indexpositionen. Ergänzend NA/Inf, fehlende optionale Objekte, Seed-lose Altobjekte und HTML-Ausgabe. |
| `test-m3d-5-data-hash.R` | Unabhängiger Serialisierer/digest; echte Lauftabelle und konstruierte 48-Zeilen-Tabelle; Zeilen-/Spaltenpermutation, doppelte Schlüssel, UTF-8, Quotes, Komma, eingebetteter Zeilenumbruch, NA/NaN/Inf, Faktoren, logische Werte, kleine Doubles und Änderungen im letzten Bit. Alle 14 vorgegebenen Zelländerungen ändern den Hash. Kleine Builder-Bytebeispiele verwenden einen unabhängig ausgeschriebenen CSV-Text, nicht den Produkthelfer für beide Seiten. |
| `test-m3d-6-report-conventions.R` | Beide Verdiktbasen, 1.41 und Contribution-Konvention, abgeleitete Modell-/Blockkomponente, Modellgrenzen, R_4s, drei bekannte Seeds; pro Modell sämtliche beobachteten Kennungen/Anbieter/Quantisierungen einschließlich Anbieterwechsel und fehlender Sol-Angaben. |

Die genannten Dateien stehen unter `tests/acceptance/`; sie und ihre
Anker bleiben unverändert in Reviewerhand. Unit-Ergänzungen landen nur
unter `tests/testthat/`. Die große Zufallsstichprobe wird nicht noch einmal
als gleichartige Unit-Suite dupliziert. Darstellungstests werden als solche
gekennzeichnet und zählen nicht als unabhängige numerische Validierung.
Numerische Toleranzen stammen aus ANK-TOL, Berichtsrundungen aus ANK-93,
Konventionen aus ANK-16; keine neuen freien Toleranzliterale.

### Regressionen und ausführbare Prüfwege

Alle ausführenden lokalen BUILD-Prüfungen erfolgen in einer
Positivlisten-Paketkopie unter `/tmp`; `REPO_ROOT` zeigt für Anker und
Aufzeichnungen auf das Original. Keine Schlüssel-/Git-Dateien werden
kopiert. Geräte/Stores/Berichte/Check-Artefakte bleiben außerhalb des
Arbeitsbaums. Die Kopie lädt den zu prüfenden Quellstand, niemals einen
anderen installierten Namespace als Ersatz für das Produkt.

Beispiel für den unveränderten M3d-Lauf aus dieser Paketkopie:

```bash
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa NOT_CRAN=true Rscript --vanilla -e '
  grDevices::pdf(NULL)
  testthat::set_max_fails(Inf)
  testthat::test_dir("tests/acceptance", filter = "^m3d-",
    load_package = "source", reporter = "summary", stop_on_failure = TRUE)
'
```

Vor dem lokalen Aufruf wird geprüft, dass der ausgewählte Prüfpfad keine
Git-Kommandos startet. Historische Prüfungen, die Baselines über Git lesen,
führt ausschließlich der Orchestrator im kumulativen Gate aus; sie werden
nicht lokal umgangen. Ein Socket-Fehler im unveränderten Replay bleibt ein
gescheiterter lokaler Nachweis mit INFRA-Zuordnung, nicht ein grüner Ersatztest.

Zusätzlich nach den betroffenen Änderungen:

1. **Unit-/QA-Regression:** vollständige bestehende `tests/testthat`,
   `tests/e2e` und `tests/fuzz` plus neue Buildertests. Vorhandene QA-Tests
   werden ausgeführt, nicht editiert. `NOT_CRAN=true` führt den bestehenden
   Reporttest im lokalen Quelltest aus. Optionale Unit-Abhängigkeiten
   folgen der bestehenden Regel; notwendige Abnahmeabhängigkeiten und
   geschützte lokale Dateien dürfen nicht still übersprungen werden.
2. **M2-Regressionsumfang:** K-M2-3 für beide Choice-Modi und AP1-JSON,
   K-M2-4 für Routing/System-/Antwortmetadaten, K-M2-6/7 für Mock-CLI,
   Teile-/Resume-Schlüssel, Evaluation, Robustheit und echte Assessment-
   Berichte. Bestehende Backend-Tests zu Reasoning, finish_reason,
   präzisen Metadaten und AP1-Netzwache/Herkunftssperre einbeziehen.
   Betreiber-AP1-Stores werden nicht verwendet oder geändert.
3. **Numerik und Seeds:** Im selben Prozess Vorher-/Nachher-Rechnung auf
   gesicherten Builder-Ausgangsquellen mit identischen Eingaben/Seeds;
   sämtliche bisherigen Bootstrap-/PB-/Robustness-Ergebnisbestandteile,
   Warnungen und RNG-Wirkungen exakt vergleichen, neue Seed-Attribute
   separat prüfen. Keine versteckten numerischen Änderungen. M3b-Tests
   einschließlich Logit-/Standardpfad und Lenth-Klasse-A-Studie sowie
   K-M1c-7 und K-M1d-6/7/8 bleiben Bestandteil der zuständigen Gates nach
   Klärung P-M3d-01. Vorgeschriebene Klasse-B-Kurzreproduktion ausführen,
   keinen zusätzlichen Volllauf vortäuschen.
4. **Berichtsregression:** M3a-Ausgaben für Fleiss, Bias und beide
   Linearitätsrechnungen, bestehende Bootstrap-Diagnostik, latent/numerisch
   unterschiedlicher Wiederholbarkeitshinweis sowie ME-/SME-Wortlaut
   erhalten. Synthetische kleine Renderfälle teilen vorbereitete Objekte;
   maßgeblich bleibt das tatsächlich gerenderte Dokument. Hash- und
   Metadatenfälle zusätzlich unter abweichenden verfügbaren
   Kollationen/Dezimaloptionen prüfen und Optionen anschließend zurücksetzen.
5. **Dokumentation/API/Paket:** roxygen-Ausgabe in temporärer Kopie
   erzeugen, Exportliste und alle ANK-02-Formals als Obermenge prüfen;
   zusätzlich das letzte Defaultargument nachweisen. Paket in temporärer
   Positivlisten-Kopie mit `R CMD build --no-manual` und
   `R CMD check --as-cran --no-manual` einschließlich Vignetten prüfen,
   ohne Netzdownloads und ohne Absenkung von Check-Regeln. Abhängigkeiten
   installiert nur das deps-Gate. Plattform-/Zeitprüfungsgrenzen mit
   tatsächlichem Output berichten.
6. **Gates/Mutation:** Orchestrator führt unveränderte deps-, lint-, tests-,
   trace-, territory-, mutgate- und golden-adr-Prüfungen sowie die gemäß
   Konfiguration fälligen weiteren Gates aus. Scope umfasst die geänderten
   R-Dateien nach aktueller Betreiberregel; keine Auslagerung zur
   Mutationsvermeidung. Floor 80, Ratchet 2 und ANK-32 werden nicht verändert.
   Neue Behauptungen zu Äquivalenz benötigen bei Bedarf Einzelbelege und
   Reviewer-Approval; sie werden hier nicht vorweggenommen. Windows-/macOS-
   CI und noLD-Nachweis bleiben Betreiber-Releaseaufgaben.

Jeder ausgeführte Nachweis wird in BUILD mit vollständigem Befehl,
Exit-Code, echtem Output, Test-/Skipzahlen und Laufzeit im Handoff oder in
PROGRESS dokumentiert. Ein fehlgeschlagener Prüfweg bleibt sichtbar.
Nach erfolgreichen erforderlichen Prüfungen werden vollständige Läufe nur
bei neuen Änderungen, Fehlern oder konkreten offenen Risiken wiederholt.
Der Orchestrator prüft Territorium und erzeugt den Phasen-Commit; nur die
deterministischen Gates und der anschließende zuständige Review bestimmen
den Abnahmestand.
