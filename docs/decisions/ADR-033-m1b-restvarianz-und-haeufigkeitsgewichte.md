# ADR-033 — M1b Rework: Restvarianz und Häufigkeitsgewichte

## Status

Umsetzungsentscheidung des Builders, REWORK M1b Runde 4, 01.11.2026.
Setzt E29 und ADR-032 Nr. 1 um und ergänzt die Diagnose nach E30.
Keine Änderung von Kriterien, empirischen Toleranzen, Engine-Vorgaben,
exportierten Schnittstellen oder Abhängigkeiten. ADR-030 bleibt Grundlage
der Berechnung im Raum der Faktorstufen.

## Entscheidung

1. Die Identifizierbarkeitsprüfung von `msa_fit()` umfasst sämtliche
   Zufallskomponenten und die feste latente Restvarianz. Für die latente
   Skala bleiben 1 bei Probit und π²/3 bei Logit maßgeblich. Weder wird
   eine zusätzliche Restvarianz geschätzt noch eine Konfundierung durch
   Entfernen eines angeforderten Zufallsterms verdeckt.
2. Häufigkeitsgewichte und binomiale Vorgewichte für 0/1-Antworten
   gehen als Vielfachheiten ein. Nach der vorhandenen Antwortbereinigung
   und Zeilenauswahl werden Gewichte auf endliche, nichtnegative
   numerische Werte mit endlicher positiver Summe geprüft. Zeilen mit
   Gewicht null liefern für diese Prüfung weder Antwortkategorien noch
   beobachtete Stufen oder Ranginformation. Ungültige Eingaben enden
   benannt vor der Engine.
3. `msa_latent_information()` verwendet auf den Zeilen mit positivem
   Gewicht die Indikatormatrizen Z_j und das feste Design X, jeweils
   zeilenweise mit √w multipliziert. Q ist eine orthonormale Basis des
   gewichteten festen Designs. Mit B_j = Qᵀ√W Z_j gilt:
   - G_ij = ‖Z_iᵀWZ_j − B_iᵀB_j‖²_F;
   - G_jε = Σw − ‖B_j‖²_F;
   - G_εε = Σw − p, mit p als Rang des festen Designs.
   Dies ist dieselbe Rechnung wie auf einer nach ganzzahligen
   Häufigkeitsgewichten expandierten Beobachtungstabelle, einschließlich
   deren Einheitsmatrix für den Restterm. Produktcode expandiert keine
   Beobachtungen und erzeugt keine n × n-Kovarianzmatrizen.
4. Der bestehende Rangnachweis aufgespannter Zufallsterme arbeitet auf
   derselben gewichteten Darstellung. Unbeobachtete Interaktionsstufen
   werden entfernt. Vollständig aufgespannte Terme erhalten weiterhin
   exakt Nullzeilen und Nullspalten; ihre Kreuzprodukte mit dem Restterm
   ebenfalls. Ein rangdefizientes ordinales festes Design wird vorab mit
   seiner bisherigen benannten Fehlermeldung abgewiesen.
5. Die Entscheidungsregel bleibt min(ev) ≤ k · eps · max(ev), jetzt mit
   k einschließlich des Restterms. Die Eigenwerte werden wie bisher
   mit `eigen(..., symmetric = TRUE, only.values = TRUE)` berechnet.
   Erst bei Ablehnung werden zusätzlich Eigenvektoren zur Erklärung
   berechnet. Eine synthetische exakte Kovarianzrelation zeigt, dass die
   andere LAPACK-Rechnung mit Eigenvektoren einen anderen Rundungsrest
   liefern kann; sie ersetzt deshalb nicht die bestehende Entscheidung.
   Keine Schwelle wird vergrößert.
6. Die Fehlermeldung nennt die Vereinigung der Komponenten im erkannten
   Nullraum, auch bei mehreren unabhängigen Relationen. Die quadrierten
   Zeilenlängen der orthonormalen Nullraumbasis müssen dafür größer als
   k · eps sein; dies entfernt numerisches Rauschen aus der Namensliste
   und beeinflusst die Ablehnungsentscheidung nicht. Ist der Restterm
   beteiligt, nennt die Meldung die fehlende Trennbarkeit von der festen
   latenten Restvarianz. `not identifiable`, Termnamen und `call. = FALSE`
   bleiben Teil der Diagnose.
7. Der interne Helfer kann mit `residual = FALSE` weiterhin die reine
   Zufalls-Gram-Matrix für algebraische Diagnosen liefern. `msa_fit()`
   fordert immer `residual = TRUE` an. Identifizierbare Eingaben erhalten
   dieselben Engine-Daten, Formeln und Argumente wie zuvor; die lokalen
   Prüfgewichte werden nicht zusätzlich an die Engine übergeben.
   Daten und `n$observations` zählen weiterhin Zeilen, während `clmm`
   bei Häufigkeitsgewichten deren Summe als `nobs` ausweist (ADR-029 Nr. 4).
8. Die neuen Unit-Dateien prüfen Beobachtungspaare einschließlich vec(P),
   echte Frequenzexpansion, exakte Rangrelationen, beide Links und beide
   latenten Zielgrößen mit gesperrten Engines. Ein Raster umfasst 96
   synthetische Pläne mit 384 Aufrufen. Direkte `clmm`-/`glmer`-Aufrufe
   prüfen identifizierbare gewichtete Fits; Toleranzen kommen aus ANK-TOL.
   Die bestehenden Unit-, Abnahme- und QA-Dateien bleiben unverändert.
9. Die neun Kurzlaufdateien werden mit dem installierten aktuellen Paket
   und unveränderten Seeds neu erzeugt. Die sechs CSVs müssen bytegleich
   bleiben; die drei Sessiondateien dokumentieren den neuen
   Implementierungsnachweis. Der vorhandene Hash umfasst bereits
   `msa_fit()` und `msa_latent_information()`.

## Abgrenzung und Belege

E32 bleibt nach ADR-032 Nr. 3 außerhalb der M1b-Arbeit; am numerischen
Durchreichweg wird nichts geändert. Äquivalenzanträge stehen ausschließlich
in `MUT-EQUIV.json`; eine Freigabe bleibt Reviewer-Arbeit.

Tatsächlich ausgeführte Befehle, Output, gezielte Mutationsproben und
Infrastrukturgrenzen stehen in `orchestrator/handoff/M1b/REWORK-NOTES.md`
und `PROGRESS.md`. Dieser ADR ist kein Abnahme-Verdict.
