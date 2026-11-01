# ADR-036 — M1b Rework: dünn besetzte Information und Prüfgewichte

## Status

Umsetzungsentscheidung des Builders, REWORK M1b Runde 5, 01.11.2026.
Setzt E33/E34 und ADR-034 Nr. 1/2 um. ADR-035 lässt diesen Auftrag
ausdrücklich bestehen. Keine neue Schwelle, Schnittstelle, Abhängigkeit
oder Änderung eines Tests aus dem Bestand.

## Entscheidung

1. `msa_latent_information()` berechnet dieselbe Gram-Matrix wie ADR-033,
   ohne einen dichten Block der Größe Stufen × Stufen zu erzeugen.
   Für N_ij = Z_iᵀWZ_j, B_j = Qᵀ√W Z_j und F_j = B_jB_jᵀ gilt:

   G_ij = Σ N_ij² − 2 Σ ((B_i N_ij) ⊙ B_j) + Σ (F_i ⊙ F_j).

   N_ij bleibt dünn besetzt; die beiden anderen Produkte haben die Größe
   Rang(X) × Stufen beziehungsweise Rang(X) × Rang(X). Dies ist die
   Expansion von ‖N_ij − B_iᵀB_j‖²_F aus ADR-034, keine Approximation.
   Insbesondere entfallen die Rundungsreste der quadrierten kleinen
   Einträge über sämtliche Stufenpaare einer dichten Projektion.
2. Restzeile, Restdiagonale und expliziter Rangnachweis vollständig
   aufgespannter Terme bleiben unverändert. Die Ablehnung bleibt
   min(ev) ≤ k · eps · max(ev), einschließlich des Restterms in k und
   mit der Eigenwertrechnung `only.values = TRUE`. Auch die Auswahl der
   Termnamen und sämtliche bisherigen Fehlermeldungen bleiben erhalten.
3. `msa_fit()` bestimmt nach Antwortbereinigung, `subset` und `na.action`
   die Gewichte der Vorprüfung. Sind alle verbleibenden Gewichte exakt
   ganzzahlig, bleiben es Häufigkeiten. Andernfalls wird jedes positive
   Gewicht zu eins, jedes Nullgewicht bleibt null. Keine Rundung oder
   neue Toleranz entscheidet über Ganzzahligkeit.
4. Dieselben Prüfgewichte gelten für Antwortkategorien, beobachtete
   Zufallsstufen, den ordinalen festen Rang und die Gram-Rechnung mit
   ihrem Rangnachweis. Der private Gram-Helfer erwartet diese bereits
   aufgelösten Vielfachheiten. Die ursprünglichen Engine-Argumente in
   `args`, Engine-Daten, Formeln und Engine-Gewichte werden nicht geändert.
5. E35 wird dokumentiert: Stufen auf Nullgewichtszeilen beeinflussen
   weiterhin die Termauswahl; bei beabsichtigtem Ausschluss dieser Zeilen
   verweist die Hilfe auf `subset`. Der Abschnitt „Known limitations“
   nennt außerdem den numerischen Durchreichweg aus BL-100. Dieser Weg
   erhält in M1b keine zusätzliche Prüfung.
6. Zu E36 entfällt das überflüssige `stringsAsFactors = FALSE` in
   `as.data.frame(runs)`. Es ist die Vorgabe seit R 4.0; das Paket verlangt
   R ≥ 4.1. Der widerlegte Äquivalenzantrag zum Umschalten auf `TRUE`
   wird zurückgenommen. Verbleibende Anträge werden mit endgültiger Zeile,
   Spalte und Quelltext neu gebunden; Freigaben erteilt allein der Reviewer.
7. Neue Unit-Tests prüfen exakte Kovarianzrelationen großer Pläne und
   identifizierbare Gegenbeispiele bei gesperrten Engines. Geschlossene
   Summen über Itemhäufigkeiten sowie direkte `clmm`-/`glmer`-Fits sind
   unabhängige Referenzen. Ein zusätzlicher lokaler Rasterlauf variiert
   Größen und Seeds. Die neuen Tests gelten auch im Mutationslauf.
8. Die neun Kurzlaufdateien werden mit dem aktuellen installierten Paket
   und den unveränderten Seeds neu erzeugt. Die sechs CSVs müssen zum
   Rundenbeginn bytegleich bleiben; die Sessiondateien dokumentieren den
   aktuellen Implementierungshash. Keine Volllaufdatei wird geschrieben.

## Belege

Die ausgeführten Befehle, Ergebnisse, Mutationsproben und gegebenenfalls
Infrastrukturgrenzen stehen in `orchestrator/handoff/M1b/REWORK-NOTES.md`
und `PROGRESS.md`. Dieser ADR ist kein Abnahme-Verdict. Bestehende Tests,
Anker, QA-Dateien und Orchestrator-Zustand sind nicht Teil der Änderung.
