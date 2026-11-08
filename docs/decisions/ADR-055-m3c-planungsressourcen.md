# ADR-055 — M3c-Planungsressourcen und ergänzender CV-MCSE

## Status

Im BUILD M3c, Runde 1, umgesetzt (Builder, 08.11.2026); zur Prüfung durch
den Reviewer. Grundlage: freigegebener PLAN und ADR-054, insbesondere Nr. 7,
9, 11–18. Keine Änderung eines Abnahmetests, Ankers oder Bestehenskriteriums.

## Kontext

K-M3c-6 verlangt vollständige Einzelreplikate und eine aus echten Rechnungen
gespeiste Vignettentabelle. Die Simulation beim Knitten zu wiederholen wäre
besonders im Mutationslauf unnötig teuer. Der PLAN verlangt deshalb einen
getrennten Erzeuger und Ergebnisleser sowie dieses Ressourcen-ADR. ACC-9
enthält weiterhin die Betreiberfrage nach einer verbindlichen CV-MCSE-Formel;
ADR-054 Nr. 9 erlaubt die im PLAN ausdrücklich benannte Delta-Methode.

## Entscheidung

1. `inst/validation/sim/planning_rule.R` führt genau einen `msa_plan()`-Aufruf
   je Kandidat aus, mit den Designs, Komponenten, Seeds und dem RNG aus
   ADR-054 Nr. 7. Die Wiederholungszahl stammt aus ANK-06. Die Vorgabe ist
   sequentiell, optional werden unter Unix ganze Kandidaten verteilt. Der
   Produktcode unter `R/` bleibt sequentiell. Fehler brechen benannt ab.
2. Ergebnisse liegen unter `inst/validation/planning/`, getrennt von den
   vorhandenen Klasse-B-Dateien. `replicates.csv.gz` speichert alle Fits und
   Schätzungen mit `sprintf("%.17g")`. Die Nachrechnung von `summary.csv`
   verwendet die wieder eingelesenen Replikate. Genau null bleibt eine
   Grenzschätzung; eine nicht geschätzte Prompt-Komponente bei nur einer
   Prompt-Variante bleibt im Produkt `NA_real_` (ADR-054 Nr. 11).
3. `reference_checks.R` ist ein reiner Leser mit Arithmetik- und
   Herkunftsprüfung. Er prüft Dateihashes, Schema, Schlüssel, Wiederholungszahl,
   Wertebereiche und alle gespeicherten Zusammenfassungen. Er lädt keinen
   Erzeuger und keinen fremden Produktnamespace (ADR-043). Fehlende Eingaben
   lösen weder Neusimulation noch Ersatzdaten aus.
4. `data-raw/make_validation_planning.R` kopiert ausschließlich den tatsächlich
   ausgewerteten ANK-89 vollständig und bytegleich. ANK-06, ANK-16 und ANK-TOL
   werden über die vorhandenen installierten Kopien samt Hashes wiederverwendet.
   ANK-86 und ANK-87 werden im Methodentext mit ihren Prüfwegen genannt, aber
   ihre Zahlen nicht wiedergegeben; nach ADR-054 Nr. 14 entfallen ihre im
   ursprünglichen PLAN vorgesehenen zusätzlichen Kopien. Originalanker und
   `inst/extdata/` ändern sich nicht.
5. Ergänzender CV-MCSE: mit m1 = Mittel(y), m2 = Mittel(y²) und
   g = sqrt(n/(n−1)) · sqrt(m2−m1²)/m1 wird
   sqrt(grad(g)' · cov((y,y²))/n · grad(g)) berechnet. Es gelten die im PLAN
   genannten Voraussetzungen: positiver Mittelwert, positive Streuung und
   endliche Momente. Ein undefinierter Zusatzwert erhält NA und eine
   Erklärung. Eine unabhängige Unit-Nachrechnung parametrisiert stattdessen
   über Mittelwert und zentriertes zweites Moment. Die Vignette zeigt den
   Näherungswert in einer eigenen Tabelle; ihre erste Planungstabelle behält
   die neun vorgeschriebenen Spalten. Keine Toleranz und kein Urteil über
   die Güte der Planungsregel wird daraus abgeleitet.
6. SOURCES/session dokumentieren tatsächliche Eingaben, Methoden, Seeds, RNG,
   Versionen, Quell-/Funktionshashes und Laufzeit. Ein Quellhash beschreibt
   den Erzeugungslauf; der Leser vergleicht ihn nicht pauschal mit dem
   aktuellen Funktionskörper. Ergebniswirksame Produktänderungen erfordern
   einen echten neuen Lauf. Der unveränderte Klasse-A-Test prüft die fachliche
   Aktualität durch frische Fits gegen die gerenderte Tabelle.
7. Ergänzende Korrektur des geplanten Druckpfads: Bei `rules = "R_4s"`
   fehlt die Warnungsspalte `1_2s`. Der alte Ausdruck
   `reject | (x$\`1_2s\` %in% TRUE)` lieferte dann einen leeren Zeilenindex
   und verschwieg vorhandene Ablehnungen in der Tabelle. Der Druckpfad
   behandelt eine nicht ausgewählte Warnungsregel ausdrücklich als FALSE.
   Die Kennzahlen und Ablehnungsregeln ändern sich nicht. Der neue Unit-Test
   prüft die tatsächliche Ablehnungszeile. Alte `msa_plan`-Objekte ohne die
   ergänzten Spalten bleiben ebenfalls druckbar; vorhandene Spalten werden
   unverändert formatiert. Dies präzisiert die geplanten Darstellungsprüfungen
   aus E6, ohne eine bestehende Schnittstelle zu entfernen.

## Konsequenzen und Belege

Die öffentliche Erweiterung bleibt auf das letzte Defaultargument `r4s`,
zusätzliche Ergebnisfelder/-attribute und Druckausgabe begrenzt. `msa_report()`
behält seine Signatur und seine attributfreie Verletzungstabelle. Die Lesart
wird über einen eigenen Renderparameter weitergegeben. qcc wird ausschließlich
als Suggests ergänzt; keine Installation und kein neuer Import.

Der tatsächliche Rechen-/Reproduktionsnachweis, die Antworten auf E1–E9,
die lokalen Prüfgrenzen und die unveränderten Backlog-Vertagungen stehen in
`PROGRESS.md`. Gate-Fakten und Abnahmeentscheidung erzeugen ausschließlich
Orchestrator und Reviewer. Die Entscheidung zu ACC-9 bleibt beim Betreiber.
