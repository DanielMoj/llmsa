# ADR-028 — M1b Rework: analysierte Zeilen und Dokumentationsfixture

## Status

Umsetzungsentscheidung des Builders, REWORK M1b Runde 2, 31.10.2026.
Implementiert ADR-027 Nr. 1–7; ändert keine Kriterien, Toleranzen,
Engine-Vorgaben, bestehenden Tests oder öffentlichen Funktionssignaturen.

## Entscheidung

1. `msa_fit()` wertet `subset`, `weights` und `offset` nach der
   Antwortbereinigung in der dokumentierten Datenmaske aus. Die übrigen
   Argumente behalten ihre Promise-Umgebung. Im latenten Pfad verarbeitet
   `stats::model.frame()` Auswahl, doppelte Indizes und `na.action` vor
   dem Formelaufbau; Gewichte und Offsets werden gemeinsam mit den Zeilen
   ausgewählt. Dadurch gelten Ein-/Zwei-Stufen-Regel, Rangprüfung,
   Zufallstermprüfung und Studienzählungen für dieselben Daten.
2. Die Engines erhalten ausgewertete Argumente über `do.call()`. Gespeicherte
   Aufrufe enthalten Daten und Steuerung, keine `..1`-Platzhalter. Numerischer
   Direktweg und latente Wege teilen die Argumentauswertung; die numerische
   Schätzung und die Vorgabe-Optimierer bleiben unverändert.
3. `clmm()` hat kein formales `offset`-Argument. Ordinale Offsets gehen als
   `offset(.msa_offset)` in die Formel ein, mit der ausgewählten numerischen
   Spalte in `data`. Der Offset steht vor den Zufallstermen: `clmm.frames()`
   übernimmt die Terms des festen Rahmens in den vollständigen Rahmen;
   stehen die Gruppierungsspalten vor dem Offset, adressiert `model.offset()`
   dort die falsche Spalte. Die neuen Tests vergleichen mit unabhängig
   aufgebauten direkten Engine-Formeln und ausgewählten Vektoren.
4. Die Zählungen in `n` bleiben Zeilenzählungen. Bei ordinalen
   Häufigkeitsgewichten meldet das unveränderte `stats::nobs(clmm)` die Summe
   der Gewichte; der direkte Engine-Aufruf bestätigt diese Bedeutung.
   Hilfe und Unit-Test nennen beide Größen ausdrücklich. Kein Engine-Feld
   wird zur Gleichsetzung verschiedener Größen überschrieben.
5. Die ordinale Singularitätsprüfung erfolgt vor dem Hinzufügen der
   abgeleiteten Komponenten. Rang des festen Designs und Zahl der
   beobachteten Stufen aller Zufallsterme werden vor dem Engine-Aufruf
   geprüft. Die bisherige Singularitätsschwelle bleibt unverändert.
6. Der aktuelle Rework-Auftrag verbietet Änderungen an bestehenden Tests.
   E15 wird deshalb durch den neuen Helfer
   `tests/testthat/helper-validation-vignette.R` umgesetzt: Fehlen einer
   temporären Quellpaketkopie sowohl die installierte Vignette als auch
   `vignettes/validation.Rmd`, kopiert er bei gesetztem `REPO_ROOT` genau
   die Original-Rmd byte-identisch an den bestehenden Fixture-Pfad. Eine
   fehlende Originaldatei bleibt ein Fehler. Der Helfer verändert weder
   Testfunktionen noch Erwartungen, Quellenliste oder Literalprüfung und
   lädt keinen Produktcode aus `REPO_ROOT`. Insbesondere bleiben mutierte
   Produktfunktionen und installierbare Helfer der Paketkopie Gegenstand
   ihrer Tests. Öffentliche installierte Pakete verwenden weiterhin ihre
   gebaute Vignette.

## Prüfung und Grenzen

Neue Tests verwenden direkte `clmm`-/`glmer`-Fits, `refit()`, `bootMer()`,
die latente Varianzformel, den Rang einer unabhängig aufgebauten Matrix
und ausdrücklich synthetische CSV-Verfälschungen. Alle Toleranzen kommen
weiter aus ANK-TOL. Der Vorgabepfad erhält keine engere Steuerung.

Die Änderung der CSV-Validierung folgt ADR-027 Nr. 5 auch dann, wenn eine
Abnahmefixture einen unmöglichen Anteil erzeugt. Ein solcher Konflikt
wird mit ausgeführtem Beleg an den Reviewer übergeben; die Fixture wird
nicht im Produktcode erkannt oder bevorzugt behandelt. Die vollständigen
Prüfbelege und Grenzen stehen in `REWORK-NOTES.md` und `PROGRESS.md`.
