# ADR-008 — Erster eingefrorener AP1-Itemsatz in M2

## Status

Angenommen im freigegebenen M2-BUILD-Auftrag als verlangter Golden-ADR.
Die Abnahme des erzeugten Satzes bleibt beim Reviewer und den Gates.

## Kontext

K-M2-1 und K-M2-2 verlangen den reproduzierbaren AP1-Itemsatz samt
Memorierungskennzeichen. ADR-005 legt Auswahl, Schema, Quellen und
Ausnahme für lokale INSAID-Referenzklassen fest. PLAN-UPDATE E10/T6 und
AGENTS.md verlangen für jede Änderung unter `inst/extdata/` einen ADR
im selben Meilenstein. Dies ist die erste Erzeugung dieses Ordners;
bestehende Golden-Werte oder Anker werden nicht ersetzt.

## Entscheidung

`data-raw/make_items_ap1.R` erzeugt
`inst/extdata/items_ap1_2026-10-24/` aus den lokalen, vorher per SHA-256
geprüften Quellen. Herkunft und Auswahl entsprechen unverändert
ADR-005, ANK-41, ANK-50 bis ANK-52, ANK-59, ANK-63 bis ANK-67 und
ANK-69. Der ERepo-Pool umfasst die belegten 1.180 Klassifikationen,
71 Gene und 35 Panels. Pro Klasse werden 15 Haupt- und anschließend
zwei disjunkte Pilotitems ausgewählt; fünf INSAID-Items pro Klasse
ergänzen die 75 ERepo-Hauptitems auf 100.

Die Ziehung benutzt Seed 20261024 aus ANK-59 mit
Mersenne-Twister/Inversion/Rejection, Radixsortierung und dem
festgelegten zyklischen Verfahren. Kennungen werden aus Quelle, Gen
und c.-Notation abgeleitet; Reihenfolge und Kennungen enthalten keine
INSAID-Klasse. Klinische Referenzklassen und Proteinnotation von
INSAID bleiben lokal. Im ausgelieferten CSV stehen für diese Felder,
Panel und sämtliche Prior-Felder leere Werte. Die drei
ClinVar-Kennzeichengruppen der ERepo-Items folgen ADR-005 einschließlich
striktem Datum, Panel-Ausschluss, Mehrheitsentscheidung und Gleichstand.

Die beabsichtigten Ergebnisse sind fachlich durch diese feste Auswahl
begründet. Die Hashes werden aus dem Skriptoutput berechnet; sie sind
keine handgesetzten Referenzantworten für die Implementierung:

| Datei | SHA-256 |
| --- | --- |
| `items.csv` | `2b9f56914b40221512ac20bb217d874bf97c60fbddf6b73977f976fca5c8aa5b` |
| `pilot.csv` | `6690501d9a6725a08cbdd1f3f3d573bbaa8750153bdcdbf30a308b8038750b63` |
| `QUELLE.txt` | `85616580d6b7d8163e79d899f22a5a25c1bf4138df3f3f4f8b7b2a079616624d` |

`SHA256SUMS` enthält genau diese drei Dateien. `QUELLE.txt` dokumentiert
zusätzlich die drei Eingabehashes, Datenstände, Quellen, Lizenzlage,
Transkriptentscheidung aus ANK-64, Auswahl und Erzeugerbefehl.

## Konsequenzen

Es gibt keine Abweichung vom PLAN oder von ADR-005. Alle vier Dateien
müssen mit den eingefrorenen Quellen byte-identisch reproduzierbar
sein. Fehlende oder abweichende Quellen, ungültige Schemata,
Poolabweichungen und überschrittene Datenbudgets brechen vor dem
Schreiben ab; es gibt keinen Download und keinen Fixture-Ersatz.
ANK-TOL bestimmt die Größenlimits. Tatsächlich ausgeführte Prüfungen
und deren Outputs stehen im M2-Abschnitt von `PROGRESS.md`.

Änderungen an Auswahl, Quellen oder Golden-Dateien benötigen erneut
einen fachlich begründeten ADR. Dieser ADR lockert weder Abnahmetests
noch das golden-adr-Gate; der Builder verändert keine Anker.
