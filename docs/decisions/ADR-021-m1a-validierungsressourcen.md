# ADR-021 — M1a: freie NIST-Tabellen und nachgewiesene Ankerkopien

## Status

Builder-Entscheidung in BUILD M1a nach bestandenem numerischem Vorversuch
(ADR-020), zur Umsetzung von PLAN-UPDATE und ADR-017 Nr. 7.1–7.6.

## Entscheidung und Golden-Begründung

Neu unter `inst/extdata/nist-strd-anova_2026-10-22/` entstehen die
numerischen Behandlung-/Replikat-/Messwerttabellen aller elf Datensätze
von ANK-14. Das ist eine neue Golden-Ressource für die öffentliche
Validierungsvignette, keine Änderung einer bisherigen Referenz oder
eines erwarteten Ergebnisses. Quelle sind ausschließlich die lokalen,
per Originalanker gehashten NIST-Dateien. NIST-Daten sind gemeinfrei;
Rohtext und Metadatenköpfe werden nicht ausgeliefert. Zahlentokens bleiben
erhalten. Dateien oberhalb ANK-TOL.data_size.gzip_above_bytes erhalten
deterministische gzip-Köpfe. `QUELLE.txt`, `SHA256SUMS` und das Manifest
nennen Herkunft und Reproduktion.

`data-raw/make_validation_numeric.R` prüft vor Veröffentlichung sämtliche
Eingaben, Schemata, Hashes und Größenlimits. `--out <Verzeichnis>` wählt
eine andere Paketwurzel für eine unabhängige Reproduktion. Kein Download,
keine numerische Reparatur und keine gespeicherten Paketresultate.

Unter `inst/validation/numeric/anchors/` liegen ganze byte-identische
Kopien von ANK-10/13/14/16 und ANK-TOL. `SOURCES.json` nennt je Datei
Originalpfad, Kopienpfad und beide SHA-256. Nur der Erzeuger schreibt
die Kopien. Die Originale unter `reference/anchors/` bleiben die einzige
redaktionelle Autorität; Produktcode unter `R/` liest keine Kopie.

Die Vignette nutzt genau die zwei Kontexte von ADR-017:

- Mit nicht leerem `REPO_ROOT`: vollständige lokale Prüfung mit
  Originalankern, AIAG-Blatt und NIST-Originalen. Fehlende/veränderte
  Quellen brechen ab, ohne Rückfall in den öffentlichen Modus.
- Ohne `REPO_ROOT`: alle freien Rechnungen aus Paketressourcen; AIAG
  zeigt nur erwartete Kennzahlen und `not rerun: protected data required`,
  niemals einen beobachteten Ersatzwert oder PASS. In keinem Kontext
  werden geschützte AIAG-Rohwerte ausgegeben.

Jeder beobachtete Wert entsteht im aktuell geladenen Paketnamespace.
Orakel werden zur Laufzeit aufgerufen. Caches leben höchstens während
einer Rechnung. Neue Unit-Tests prüfen Ressourcen, Drift zum erreichbaren
Repository, Kontextwahl, Literalherkunft und Fehlerpfade. Nur der
Originalvergleich darf ohne erreichbares Repository ausdrücklich skippen;
die Paketressourcen werden auch im Tarball geprüft.

`VCA` und `SixSigma` werden als bereits installierte Suggests deklariert.
Kein Abhängigkeitsupdate, kein neuer Export, keine Änderung an
Abnahmetests, Ankern oder Toleranzen. Reproduktions- und Baubelege stehen
mit echten Outputs in `PROGRESS.md`.

## Ausgeführte Nachweise (29.10.2026)

Zwei unabhängige Erzeugungen und der Checkout haben 19 identische
generierte Dateien. Alle elf NIST-Tabellen bewahren Zahlentokens und
Zeilenreihenfolge der per ANK-14 geprüften Originale; drei gzip-Dateien
haben identische normalisierte Köpfe. Sechs temporäre Negativfälle
(fehlender Anker, fehlende Quelle, Hashfehler, Parsefehler, fehlender
Größenschlüssel, Größenüberschreitung) brechen vor Veröffentlichung ab.

Beide separaten Paketbauten und `R CMD check --as-cran --no-manual`
bestehen ohne ERROR oder WARNING, jeweils mit einer NOTE zur nicht
verifizierbaren Systemzeit. Die Uhrzeitprüfung bleibt aktiv. Der
öffentliche Bau zeigt neun Referenztabellen und 23 AIAG-Zeilen mit
`NOT RERUN`; der Vollmodus zeigt 13 Referenztabellen. Kein beobachteter
Ersatzwert für geschützte Daten, keine Rohdaten-Ausgabe, keine
eingefrorenen Orakelergebnisse. Diese Builder-Diagnosen sind kein
Gate-Verdikt.
