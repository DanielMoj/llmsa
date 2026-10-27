# ADR-009 — Numerische API-Metadaten ohne Rundungsverlust speichern

## Status

Angenommen als Builder-Entscheidung im M2-BUILD (27.10.2026).
Dokumentierte Ergänzung zum freigegebenen PLAN; Prüfung durch Reviewer
und Gates steht aus.

## Kontext

K-M2-4 verlangt `usage` in den Metadaten und deren Speicherung als JSON
durch `msa_run()`. Der PLAN ergänzt dafür Felder des HTTP-Backends,
sieht aber keine Änderung der numerischen Serialisierung vor.
Bei der ergänzenden Wiedergabe der unveränderten Betreiber-Aufzeichnungen
aus `tests/fixtures/api/` fiel ein bereits in v0.1.0 vorhandener Fehler
in `meta_to_json()` auf: `jsonlite::toJSON()` verwendet ohne Angabe von
`digits` vier Dezimalstellen. Dadurch gehen kleine und gebrochene Werte
verloren, obwohl das Backend sie zunächst unverändert übernimmt.

Ausdrücklich benanntes Orakel ist die unveränderte Aufzeichnung
`tests/fixtures/api/llama.json`, gesichert durch ANK-94. Ihr
`usage.cost` von `0.00004615` wird durch den bisherigen Serializer zu
`0`; dasselbe betrifft die Felder `cost_details.upstream_inference_cost`
und `cost_details.upstream_inference_prompt_cost`. Der separate
BUILD-Prüflauf scheiterte deshalb am identischen Vergleich der
gespeicherten `usage` mit dem Original. Dies ist keine neue empirische
Konstante der Implementierung; die Zahl stammt ausschließlich aus dem
benannten Orakel.

## Entscheidung

Der JSON-Zweig von `meta_to_json()` setzt zusätzlich `digits = 17`.
Die 17 Stellen reichen zur Wiederherstellung binärer Double-Werte;
sie sind eine Serialisierungsregel, keine empirische Referenzkonstante.
Der zunächst geprüfte Wert `digits = NA` lässt bei der eingefrorenen
jsonlite-Version noch einen Rundungsfehler bei der synthetischen Zahl
`1 / 3` zurück. Mit `digits = 17` werden auch diese numerischen Werte
nach dem JSON-Rundweg identisch wiederhergestellt. `auto_unbox = TRUE`
und `null = "null"` gelten
weiterhin. Die übrige Verarbeitung, Store-Spalten, Schlüssel,
Rohantworten und Funktionssignaturen bleiben gemäß ADR-007 erhalten.

Diese kleine Planergänzung ist erforderlich, damit der neue AP1-
Auditpfad keine Kostenmetadaten durch Rundung auf null verfälscht.
Ein Unit-Test verwendet ausdrücklich synthetische kleine und gebrochene
Zahlen und prüft den vollständigen Weg durch `msa_run()` und SQLite.
Der separate BUILD-Prüflauf vergleicht die realen Aufzeichnungen
einschließlich verschachtelter `usage` identisch mit dem gespeicherten JSON.
Beide Belege stehen in `PROGRESS.md`.

## Konsequenzen

Neue JSON-Strings können mehr Dezimalstellen enthalten. Aus bereits
gerundeten alten Stores werden keine Werte rekonstruiert und keine
Daten nachträglich erfunden. Die Pilot-Kostenformel nach ADR-006 nutzt
die ganzzahligen Completion-Tokens und die Preisanker; die zusätzlichen
Kostenfelder der Antwort ersetzen diese Rechnung nicht.

NEWS und die Rd-Dokumentation benennen die Fehlerbehebung. Es entstehen
keine neue Abhängigkeit, kein neues Argument und keine Änderung an
Ankern, Golden-Dateien, Aufzeichnungen oder Abnahmetests. Der separate
Wiedergabeweg ist ergänzende Builder-Evidenz und ersetzt nicht den
weiterhin durch lokale Socket-Rechte blockierten Abnahmeweg.
