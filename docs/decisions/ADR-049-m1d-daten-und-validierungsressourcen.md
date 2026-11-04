# ADR-049 — M1d: eingefrorene Daten und Offline-Validierungsressourcen

## Status

Builder-Entscheidung zur Umsetzung des freigegebenen PLAN M1d und ADR-048,
04.11.2026. Neue Golden-Daten im selben Meilenstein nach docs/01 §7.
Keine Änderung von Ankern, Abnahmetests, Rechenverfahren oder Schnittstellen.

## Kontext

K-M1d-1 bis K-M1d-5 verlangen zwei reproduzierbare öffentliche Datenquellen
und installierbare Vignetten. ADR-048 Nr. 14 verlangt eine abschließende
Parserregel und die Zählung ihrer Ausfälle. K-M1d-7 verlangt den Bericht der
vorhandenen Betreiber-Vollläufe; BL-92 zusätzlich eine Konvergenz-Sensitivität.
Die Hinweise E2–E15 des PLAN-REVIEW konkretisieren die Umsetzung.

## Entscheidung

1. **llm-stability.** Ausschließlich Archiv und Auswahltabelle aus ANK-40,
   mit SHA-256-Prüfung. Die verankerten v3-Zero-shot-Ordner müssen mit den
   Konfigurationen, Zeitkennungen und Dimensionen der Auswahltabelle
   übereinstimmen. Prüfung des vollständigen Itemgitters sowie der eindeutigen
   Frage und des Schlüssels vor der Ausgabe. Keine Ergänzung fehlender Zeilen.
2. **Abschließende Etikettenregel (E2).** Nur ein unmittelbar geklammerter
   ASCII-Buchstabe `(A)` bis `(Z)`, Groß-/Kleinschreibung gleichgültig,
   ohne Leerzeichen innerhalb der Klammer, der zu den Optionen des Items
   gehört. Keine nackten Buchstaben, keine zusätzlichen Antwortformeln.
   Alle Vorkommen im Antworttext zählen, auch in Zitaten. Wiederholung
   desselben Etiketts ist eindeutig; verschiedene gültige Etiketten sind
   mehrdeutig. Bei `navigate` gelten die ganzen Wörter `Yes` und `No`,
   unabhängig von Groß-/Kleinschreibung; Buchstaben, Ziffern oder Unterstriche
   begrenzen kein solches Wort. Keine Priorität für letzte Sätze oder
   vermeintliche Schlussantworten. Der Schlüssel ist kein Parserargument.
   Fehlend bleiben leere Antworten, Antworten ohne gültiges Etikett und
   mehrdeutige Antworten; `QUELLE.txt` zählt die Gründe je Aufgabe/Modell.
3. **Schlüsselvergleich (E3).** `correct` ist ausschließlich `answer == gt`,
   bei fehlender Antwort NA. Die beiden Text-Schlüssel aus ANK-40
   (`ruin_names`, Items 99 und 144) werden nicht repariert. Der Generator
   ermittelt alle nicht zu den Optionen passenden Schlüssel und nennt die
   Itemkennungen in `QUELLE.txt`. Die Vignette übernimmt diesen Hinweis und
   erklärt die Wirkung auf die Trefferquote: Etikett-Antworten zu diesen
   Items können nach dem Vertrag nur Fehltreffer sein.
4. **ClinVar.** ANK-41 fixiert beide Rohdateien, ANK-63 deren
   Einreichungsschema. Exakter Klassenfilter nach ANK-47 vor der Zählung
   verschiedener Submitter. Alle SCVs bleiben erhalten. HRF-Auswahl und
   Stichprobe folgen docs/02 M1d und ANK-47; numerisch sortierte IDs,
   explizit Mersenne-Twister/Inversion/Rejection und verankerter Seed.
   `GeneSymbol` kommt aus `variant_summary`; Genlisten und Submittertexte
   bleiben unverändert, fehlende Genzuordnungen fehlen weiter. Widersprüchliche
   Assemblierungszuordnungen scheitern benannt. Ausschlüsse werden vor den
   Einreicherschwellen für sämtliche HRF-Varianten und die Gesamtdatei gezählt.
5. **Dateiformat und Veröffentlichung (E4–E6).** TSV-Eingaben werden in
   Blöcken mit ausschließlich benötigten Spalten gelesen. Große Indizes
   halten nur IDs, Submittercodes oder Genzuordnungen, keine vollständigen
   Rohdatensätze. Datumsnormalisierung unter `LC_TIME=C`, danach
   Wiederherstellung der Locale. Ausgabe als UTF-8 CSV, Textfelder in
   Anführungszeichen, innere Anführungszeichen verdoppelt, LF, fehlende Werte
   als leere Felder, `gzfile()` ohne Zeitstempel. Sortierung mit `radix`;
   llm-stability nach task/model/run/item_id, ClinVar nach den sechs
   Ausgabespalten mit numerischer VariationID. `SHA256SUMS` umfasst auch
   `QUELLE.txt`. Alle Größenprüfungen verwenden ANK-TOL.data_size.
   Fehlende/falsche Eingaben ändern keine Zieldatei. Ein vollständiges
   geprüftes Staging-Verzeichnis ersetzt den Zielordner; bei gescheitertem
   Umbenennen wird der vorherige Ordner wiederhergestellt.
   UTF-8 wird über Binärverbindungen gelesen und mit `writeLines(useBytes=TRUE)`
   geschrieben. Die drei vorkommenden CSV-Typen (Text, Integer, Logical)
   werden ausdrücklich serialisiert: Ein zusätzlicher Test unter
   `LC_CTYPE=C` zeigte, dass Textverbindungen bzw. `write.table()` sonst
   UTF-8 nach nativ umkodieren und Zeichen verlieren oder als `<U+...>`
   schreiben. Diese Korrektur erfüllt E4 ohne eine installierte UTF-8-Locale
   vorauszusetzen; das CSV-Format bleibt gleich.
6. **Installierte Ressourcen (E10).** Ganze Ankerdateien ANK-06,
   ANK-40–ANK-47, ANK-63 und ANK-TOL werden bytegleich nach
   `inst/validation/m1d/anchors/` kopiert. `SOURCES.json` bindet Pfade und
   SHA-256, erzeugt durch `data-raw/make_validation_m1d.R`.
   Vignetten verwenden nur installierte Daten und Ressourcen. Kein Original,
   Rohantworttext oder geschütztes Variantenlabel wird mitgeliefert.
7. **Befunde und Sensitivität (E8–E11).** Vorhandene Ergebnisleser und
   Simulationsdateien bleiben unverändert. Neue Helfer ohne `sim_`-/`boot_`-
   Präfix arbeiten außerhalb der Studienhashes. Befunde folgen dynamisch
   ADR-048 Nr. 10 und ANK-TOL; Nominalüberdeckung bleibt der Studienvertrag
   docs/02 M1c. Jede Szenario-ID wird einzeln genannt. Ohne überschrittene
   Schwelle behauptet die Zwei-Stufen-Studie keine allgemeine Unverzerrtheit.
   BL-92 verwendet ausschließlich eigene Replikatzeilen, mit tatsächlichem n
   und MCSE je Gruppe; keine Kopplung an n_sim einer Ergebnistabelle und
   kein Ausschluss allein wegen Singularität. Fehlende Zusatzreplikate
   werden ausdrücklich als nicht verfügbar bezeichnet; K-M1d-6 bleibt
   davon unabhängig verpflichtend.
8. **Vignetten und Ausgabe (E7, E12–E15).** Vorgabefits mit Probit und
   ohne Wechselwirkungen; vier signifikante Stellen für reale Fits, sechs
   für Studienbefunde. Warnungen und Fitdiagnosen werden sichtbar erfasst.
   ClinVar-Sensitivität mit wörtlichem Präfix `criteria provided` nennt
   behaltene/verwarfene Status mit Zählungen und wendet die ursprünglichen
   Schwellen nicht nochmals an. Literaturwerte werden vollständig gelesen;
   ihre Gruppierungen und Bezugsgruppen werden erklärt. K-M1d-8 wird nur
   in der Ausgabe umgesetzt, mit unmittelbar faktorbezogenen Zusätzen.

## Konsequenzen und Grenzen

- Die Parserregel misst Gleichheit extrahierter Etiketten, nicht die
  menschliche Interpretation einer ausführlichen Antwort. Ausfälle werden
  offengelegt; fehlende Antworten werden im Fit nicht in FALSE umcodiert.
- Günstige oder ungünstige Studienbefunde bleiben Berichtsergebnisse,
  keine neuen Bestehensschwellen. Keine Betreiber-Vollläufe werden erzeugt
  oder überschrieben.
- Kernverhalten und Robustheitsobjekte werden gegen die vor BUILD gesicherten,
  mit ANK-34 geprüften Dateien verglichen. Die Git-basierten Abnahmepfade
  bleiben beim Orchestrator.
- Der fehlende `_pkgdown.yml`-Eintrag bleibt E1 / M1D-INFRA-01 im
  Betreiber-Territorium; dieses ADR erteilt keine Schreibfreigabe dafür.
- Dies präzisiert den freigegebenen Plan, ohne fachliche Planabweichung.
