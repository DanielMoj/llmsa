# ADR-043 — Ergebnisleser der Bootstrap-Vignette ohne Simulationsgenerator

## Status

In M1c BUILD umgesetzt (Builder, 02.11.2026); zur Prüfung im Code-Review.
Begrenzte Abweichung von der Dateiliste des freigegebenen PLAN: zusätzlicher
interner Helfer `inst/validation/sim/boot_coverage_results.R`.

## Kontext

K-M1c-5 verlangt die aus Dateien gelesene Überdeckungstabelle. Der PLAN
sieht Leser und Generator gemeinsam in `boot_coverage_helpers.R` vor.
Dieser Helfer lädt auch `simulation_helpers.R` für die bestehenden
reinen Studienfunktionen. Beim Laden durch die Vignette gelangen damit
die M1b-Szenariodefinitionen in deren Quellabhängigkeiten, obwohl das
Darstellen der Ergebnisse keinen Generator braucht.

Der vollständige Unit-Lauf fand deshalb einen Fehler im unveränderten
`test-validation-latent.R:143`: Der Szenarioparameter `0.0625` aus
`simulation_helpers.R` entspricht einem geschützten Referenzwert und
wird von der rekursiven Literalherkunftsprüfung erfasst. Derselbe Fehler
tritt in der unveränderten QA-Paketkopie und im installierten Paketcheck
auf. Die Szenarioparameter sind spezifiziert; ihre Änderung oder eine
Lockerung der Herkunftsprüfung wäre keine sachgerechte Lösung.

## Entscheidung

1. Der reine Ergebnisleser und die Namen seiner Pflichtschätzziele werden
   nach `boot_coverage_results.R` ausgelagert. Er lädt ausschließlich die
   bestehenden latenten Anker-/Darstellungshelfer. Größen des Kurz- und
   Volllaufs kommen weiter aus den hashgeprüften Ankerkopien. Er lädt
   keinen Generator, berechnet keine Fits und liest keine Replikat- oder
   Sessiondateien (PLAN-REVIEW E6, ADR-042 Nr. 11.6).
2. Die Vignette lädt direkt diesen Leser. Dessen Rückgabe ergänzt das aus
   ANK-06 gelesene `n_min` für den erläuternden Text. Dateiwahl, Tabellen,
   Endlichkeits-, Schlüssel-, Szenario- und Größenprüfungen bleiben
   erhalten. Schätzzielnamen sind Schema, keine numerischen Referenzwerte.
3. Der Studienhelfer lädt denselben Leser. Ein neuer Unit-Test prüft dessen
   eigenständigen Ladeumfang und die Übereinstimmung des Schemas mit allen
   sieben Szenarien. Bestehende Tests werden nicht verändert.
4. Der Implementierungshash der Bootstrap-Studie umfasst weiterhin alle
   `boot_*`-Funktionen einschließlich des ausgelagerten Lesers. Ihr
   Kurzlauf wird nach der Änderung vollständig neu gerechnet; keine
   Ersetzung des Hashes in einer alten Sessiondatei. Die drei M1b-Helfer,
   ihre Seed-Zuordnung und ihr Implementierungshash ändern sich dadurch
   nicht. Die bereits in dieser BUILD-Phase neu gerechneten M1b-Tripel
   bleiben gültig; der Hashabgleich wird im Handoff belegt.

## Folgen und Nachweis

Keine öffentliche API, keine Abhängigkeit, kein Studienparameter und keine
statistische Rechenregel ändert sich. Die Vignette benötigt nur die
Ergebnisdatei und vorhandene öffentliche Ankerressourcen. Die ausgelagerten
Definitionen bleiben vollständig über die normalen `sys.source`-Aufrufe
für die bestehenden Herkunftstests sichtbar.

Vor Übernahme bestand die Paketkopie mit der Trennung die unveränderte
latente Unit-Prüfung und die neuen Bootstrap-Studienprüfungen:
`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 358 ]` (4,8 s). Endgültige Kurzlauf-,
Abnahme-, Unit-/QA- und Paketcheck-Belege stehen in `PROGRESS.md` und
`orchestrator/handoff/M1c/REVIEW-INPUT.md`.
