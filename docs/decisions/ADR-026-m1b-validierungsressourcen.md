# ADR-026 — M1b: installierbare Validierungsressourcen und Studienprovenienz

## Status

Angenommen durch den Builder in BUILD M1b, 31.10.2026; Umsetzung des
freigegebenen PLAN-UPDATE und ADR-023/ADR-025. Keine Änderung der
Abnahmekriterien, Ankerwerte, Toleranzen oder Exportverträge.

## Kontext

K-M1b-7 verlangt einen Offline-Bau der Vignette aus dem installierten Paket.
K-M1b-2/-3 verlangen ausführbare Studien samt reproduzierbaren Kurzläufen;
Vollläufe gehören dem Betreiber. Originalanker unter `reference/anchors/`
gehören dem Reviewer und sind im öffentlichen Paket nicht verfügbar.
PLAN-UPDATE, Abschnitte „Dateien“, „Ressourcen“ und E5, verlangt vollständige
Ankerkopien, strikte Herkunftsprüfung und eine ausführbare Zusammenführung
getrennter Szenarioläufe. ADR-021 ist das bestehende Vorbild.

## Entscheidung

1. `data-raw/make_validation_latent.R` kopiert ANK-06, ANK-21, ANK-25, ANK-28
   und ANK-TOL vollständig und byte-identisch nach `inst/validation/latent/`.
   `SOURCES.json` nennt Generator, Original- und Kopierpfad sowie beide
   SHA-256-Werte. Originalanker bleiben unverändert. Die dokumentierten
   Literaturwerte und Vergleichstoleranzen werden aus diesen Dateien gelesen.
2. Ein gesetztes `REPO_ROOT` erzwingt Originalprüfung und Originalzugriff;
   fehlende oder veränderte Eingaben brechen benannt ab. Ohne `REPO_ROOT`
   verwendet die öffentliche Vignette die geprüften Kopien. Unit-Tests prüfen
   auch die Gleichheit der numerischen und latenten ANK-TOL-Kopie.
3. Die Vignette lädt Helfer und Studienergebnisse über `system.file()` aus
   dem tatsächlich geladenen Paket. Vorhandene Vollaufergebnisse haben
   Vorrang; ungültige Vollaufergebnisse lösen keinen Rückfall auf Kurzläufe
   aus. Der Bau startet keine Simulation. Die ANK-25-Installationsprüfung
   bleibt von den latenten ICC-Vergleichen nach ADR-024/025 getrennt.
4. Die drei Studien teilen einen installierbaren Helfer für Generatoren,
   feste szenario-/wiederholungsbezogene Zufallsströme, Kennzahlen und
   Diagnoseausgabe. Zusätzliche Spalten erfassen tatsächliche Konvergenz,
   Singularität, Warnungen, Fehler, Wiederholungsseed und Stichprobenzahlen.
   Die Zahl finiter Schätzer ist gesondert sichtbar. Vor einem
   Aggregationsfehler werden Replikate und Session gesichert; es entsteht
   keine erfolgreiche Ergebnisdatei.
   Fehlende Fehler-/Warnungs-/Meldungsdiagnosen werden als `NA` geschrieben:
   Leere Zeichenketten werden von gewöhnlichen CSV-Lesern unterschiedlich
   typisiert, je nachdem, ob spätere Wiederholungen eine Meldung enthalten.
   Der echte Präfix-Abnahmelauf deckte diesen Fall auf; ein kleiner
   Regressionstest prüft die Verlängerung mit unverändertem `read.csv()`.
5. Sessiondateien enthalten zusätzlich maschinenlesbare Versionen, RNG-Regel,
   Szenarien und einen SHA-256-Wert der verwendeten Fit-/Studienfunktionen.
   `sim_merge()` verlangt disjunkte vollständige Szenariomengen, gleiche
   Implementierung, R-/Paketversionen und Wiederholungszahl sowie gültige
   Seeds und Kennzahlen. Es übernimmt die vorhandenen Schätz- und
   Ergebniszellen, führt keine Fits aus und bewahrt die Original-Sessions
   samt Datei-Hashes. Laufzeiten werden nicht zu einer fiktiven gemeinsamen
   Wanduhrzeit verrechnet.
6. `LLMSA_SIM_WORKERS` erlaubt für Reproduktionsprüfungen eine kleinere
   Workerzahl innerhalb der unveränderten ANK-TOL-Grenze. Windows rechnet
   sequentiell. Forks liegen ausschließlich unter `inst/validation/sim/`.
   Alle CLI-Parameter und Standarddateinamen bleiben gemäß ADR-023.
7. Der Zwei-Stufen-Kontrast wird aus der Differenz der beiden
   Designmatrixzeilen berechnet. Das liefert bei Treatment-Codierung den
   bisherigen Koeffizienten und erhält die Formel auch bei einer vom Nutzer
   gewählten Kontrastcodierung. Kein neuer Schätzer und keine Bias-Korrektur.
8. Präzisierung gegenüber dem nicht auf einen Optimierer eingegrenzten
   Unit-Testplan: Die Metamorphieprüfung der binären Ereignisumkehr verwendet
   den öffentlichen `control`-Parameter mit `bobyqa` auf beiden Stufen und
   `rhoend = ANK-TOL.engine_boot.tol`; die ordinale Umbenennungs- und
   Kontrastprüfung verwendet den echten `ucminf`-Eintermpfad mit seinen
   Standardeinstellungen. Die Grenze bleibt `ANK-TOL.invariance`, ebenso
   die ursprünglichen Daten und Transformationen. Der Produkt-Vorgabepfad
   wird nicht verändert. Begründung: Für dieselben synthetischen Daten
   überschreiten die Standardoptimierer die Invarianzgrenze geringfügig;
   bloßes Verkleinern der clmm-Optimierertoleranzen behebt das nicht
   zuverlässig und kann ucminf-Code 4 ergeben. Die rohen Messwerte und
   Reproduktionsbefehle werden als Einschränkung und Handoff-Vorschlag in
   `PROGRESS.md` festgehalten; kein Anspruch auf Invarianz des
   Vorgabeoptimierers für diese Fälle. Die Default-Engine-Gleichheit und
   echten Nichtkonvergenzdiagnosen bleiben separat geprüft.
9. Zusätzliche Datei gegenüber PLAN-UPDATE: Der eigene Drucktext-Snapshot
   in `tests/testthat/test-grr-rework.R` erwartet je abgeleiteter Quelle
   genau die neue Zeile aus K-M1b-4. Im vollständigen Unit-Lauf schlugen
   zwei Textvergleiche desselben Blocks fehl, weil sie noch die alte
   gemeinsame Erklärung samt AIAG-Zuordnung verlangten. Diese
   Ausgabeerwartung wird auf den neuen Vertrag gebracht; Tabellenwerte,
   numerische Erwartungen, Rückgabewert, Sichtbarkeit und beide
   Singularitätshinweise bleiben unverändert und weiterhin exakt geprüft.

## Konsequenzen

Die Ressourcen sind zusätzliche, installierbare Dokumentationsdaten, keine
neuen Golden- oder Orakelwerte. `rptR`, `performance` und `parallel` werden
als Suggests deklariert; neue Imports oder Exporte entstehen nicht.
Der Builder liefert ausschließlich die neun `_check_`-Ergebnisdateien.
Der Betreiber erzeugt die Vollläufe nach der Abnahme; K-M1d-6/-7 bewerten
deren Vollständigkeit und Befunde. Das bekannte M2-Warnungsorakelproblem
E9/E10 bleibt gemäß ADR-025 ein [INFRA]-Handoff, ohne Eingriff in `R/acmg.R`.
Ausgeführte Prüfungen und echte Outputs stehen in `PROGRESS.md`.
