# REVIEW-INPUT — M3b, BUILD, Runde 1

Datum: 04.11.2026. Rolle: Builder. Freigabe: PLAN Runde 1 und
PLAN-REVIEW mit `verdict-plan.json: PASS`, ADR-050 und ADR-051.
Keine PLAN-UPDATE- oder ARBITER-Datei für M3b vorhanden.

## Umsetzung

Der freigegebene Plan ist umgesetzt. Keine Planabweichung, kein neuer
Builder-ADR, keine neue Vertragslücke. Die Änderungen betreffen
`R/robustness.R`, die daraus erzeugte `man/msa_robustness.Rd`, `DESCRIPTION`,
zwei neue Unit-Testdateien, `vignettes/validation.Rmd`, `NEWS.md`,
`PROGRESS.md` und diesen zugewiesenen Handoff.

- K-M3b-1/-2/-3: PB-Konstruktion und Lenth-Rechnung bleiben erhalten;
  die unveränderte Abnahme bestätigt Matrizen, Orakel, Literaturwerte und
  strikte Aktivitätsentscheidungen. Empirische Konstanten wurden nicht ergänzt.
- K-M3b-4: Die x-Achse nennt `Half-normal quantile (Daniel, 1959)`;
  Quantile, Effektbeträge, Linien und Beschriftungen bleiben erhalten.
- K-M3b-5: roxygen und erzeugte Hilfe nennen ME/SME konservativ und
  `alpha` nominal; der alte Satz zum tatsächlichen 5-%-Niveau entfällt.
  Die unveränderte Klasse-A-Studie ist ausgeführt, einschließlich aller
  Entscheidungen gegen die unabhängige Referenz.
- K-M3b-6: `transform = "none"` ist das angehängte fünfte Argument.
  Nur exakt `"none"` und `"logit"` sind erlaubt. Im Logit-Pfad werden
  reelle, endliche numerische Vektoren mit Werten strikt in (0, 1)
  verlangt; auch Matrizen/Arrays, komplexe Werte, 0/1 und Werte außerhalb
  des Intervalls werden vor der Transformation zurückgewiesen. Die
  bestehenden Längen- und NA-Fehler bleiben. `stats::qlogis()` wird einmal
  angewandt, ohne Randkorrektur. Die Hilfe erklärt die Ergebnisskala
  einschließlich `response_mean`/`response_sd` und den Umgang mit vorab
  berechneten empirischen Logits.
- ACC-12: FrF2, DoE.base und unrepx sind zu Suggests ergänzt. Keine
  Abhängigkeit installiert oder aktualisiert; alle Imports bleiben erhalten.

## Antworten auf E1 bis E3

| ID | Antwort und ausgeführter Beleg |
| --- | --- |
| E1 | Akzeptiert: `test-robustness-properties.R` und `test-robustness-transform.R` ergänzen 19 Testblöcke mit 489 Erwartungen. Geprüft werden genaue Fehlermeldungen/`conditionCall()`, Grenzen und Typen, einzelne Faktoren, Faktor-Metadaten, RNG mit und ohne vorherigen Zustand, Invarianzen, kleine positive/verschwindende PSE, komplette Druckausgaben und unsichtbare Rückgaben sowie tatsächlich gezeichnete Punkte, Texte und ME-/SME-Linien. Die lokale Mutation erkennt 299 von 308 syntaktisch gültigen Mutanten (97,08 %), ohne Äquivalenzabzüge; Einzelheiten unten. Kein Umbau des bestehenden Codes für den Score. |
| E2 | Akzeptiert: Der neue Vignettenabschnitt nennt Anker und Prüfwege ohne abgetippte Ergebnisse, Toleranzen oder neue ausführbare Chunks. Kein neues `source()`/`sys.source()`. Vignettenregression: 26 Blöcke, 696 Erwartungen, keine Fehler/Warnungen/Skips. Der Git-freie M1d-Literalvergleich ist ebenfalls erfolgreich. |
| E3 | Akzeptiert: ME/SME sind unter H0 bei normalem Rauschen konservativ, `alpha` ist nominal. Die Hilfe dokumentiert die Logit-Grenzen, fehlende automatische Korrektur und die Skala aller betroffenen Zahlen. Die drei unveränderten Hilfeseitentests bestehen; die Seite wurde mit roxygen2 8.1.1 erzeugt. |

ACC-1/ACC-2: Die drei Lenth-CSV stimmen vor und nach BUILD mit ANK-81
überein; `QUELLE.txt` ist vorhanden. ACC-3/4/6/8/9/11/15 folgen ADR-051,
ACC-5/7/10 ADR-050. ACC-13 bleibt der vorhandene Infrastrukturhinweis;
ACC-14 wurde nicht verändert. Keine Anker, Abnahmetests oder Toleranzen
geändert. Die Vertagungen des PLAN bleiben bestehen, insbesondere BL-125
und BL-126; keine nachträgliche Kalibrierung der AP1-Methode.

## Ausgeführte Prüfungen

Arbeits- und Rohlogverzeichnis: `/tmp/llmsa-m3b-build-22ktixdh/`.
Die Befehle und maßgeblichen echten Outputzeilen stehen im neuen
M3b-Abschnitt von `PROGRESS.md`. R 4.6.1, testthat 3.3.2, pkgload 1.5.3,
roxygen2 8.1.1, FrF2 2.3.5, DoE.base 1.2.5, unrepx 1.0.2,
muttest 0.3.0; ausschließlich vorhandene Abhängigkeiten.

| Prüfung | Tatsächliches Ergebnis |
| --- | --- |
| deps, `--check-only` | Exit 0; 28 Anforderungen erfüllt. |
| Robustheits-Unit-Tests | Exit 0; 25 Blöcke, 538 Erwartungen, keine Fehler/Warnungen/Skips. |
| M3b-Abnahme, `filter = "^m3b-"` | Exit 0; 27 Blöcke, 437 Erwartungen, keine Fehler/Warnungen/Skips. |
| Lenth-H0, `filter = "^lenth-h0$"` | Exit 0; sechs Erwartungen; alle Entscheidungen in beiden Szenarien stimmen. Je Szenario 1.000 Pläne, Seeds 20261112/20261115; Studienzeit 1,8 s. |
| Unit/E2E/Fuzz, vollständig | Exit 0; 345 Testblöcke, keine Fehler/Warnungen; 6.230/319/94 grüne Erwartungen. Ein bestehender ellmer-Negativtest übersprungen, weil ellmer installiert ist. |
| Vignettenregressionen M1a/M1b/M1c | Exit 0; 26 Blöcke, 696 Erwartungen, keine Fehler/Warnungen/Skips. |
| Kompatibilität ohne Git | Exit 0; sieben Standardobjekte mit Vorgabe und explizitem `none` identisch zum vor BUILD gesicherten Code; fünf Logit-Objekte gleich der getrennten Transformation; fünf vollständige AP1-Objekte identisch, alle drei Bänder vertreten; alle 22 API-Signaturen erfüllen ANK-02 in beiden Reviewer-Helfern. |
| Öffentlicher Paketbau | Exit 0; alle vier Vignetten und alle vier Vollstudien-Ergebnisdateien im Tarball. |
| Öffentlicher Paketcheck | Exit 0; keine ERROR-/WARNING-Befunde, eine NOTE zur offline nicht überprüfbaren Uhrzeit; Beispiele, installierte Tests und erneuter Vignettenbau bestanden. |

Der vollständige `R CMD check --as-cran --no-manual` endet mit
`Status: 1 NOTE`. Die installierten Tests bestehen 6.154 Erwartungen ohne
Fehler oder Warnungen. Die neun bestehenden Skips betreffen fünf nicht
mitgelieferte API-Aufzeichnungen, einen CRAN-ausgenommenen Berichtstest,
zwei Originalanker-Vergleiche und den ellmer-Negativtest. Im Repo-Lauf
wurden alle davon bis auf den ellmer-Negativtest ausgeführt.

Die H0-Raten sind konservativ und nicht auf `alpha` nachkalibriert:

```text
8 factors: ME 0.02325 (MCSE 0.00222); SME 0.01500 (MCSE 0.00384)
11 factors: ME 0.02891 (MCSE 0.00231); SME 0.02500 (MCSE 0.00494)
```

Die vollständige unveränderte Studienausgabe mit Abstand zu `alpha`, Seeds,
RNG und Versionen steht in `PROGRESS.md` und `lenth-h0.log`.

## Lokale Mutationsdiagnose zu E1

Die neun Mutatorfamilien aus `orchestrator/lib/r-mutation.R` wurden mit
`muttest::muttest_plan()` auf die ganze endgültige `R/robustness.R`
angewandt. Je Mutant eine isolierte Paketkopie/ein frischer R-Prozess;
zwölf Prozesse gleichzeitig. Prüfsatz: alle `^robustness-`-Unit-Dateien und
alle `^m3b-`-Abnahmedateien, unverändert. Der unmutierte Vorlauf besteht
975 Erwartungen ohne Fehler, Warnungen oder Skips; 12,471 s.

```text
Final diagnostic counts: {'Killed': 299, 'Survived': 9, 'CompileError': 9}
Detected 299/308 parseable mutants (97.08%); no gate verdict
Elapsed 459.11 s
```

| Funktion | Entdeckt | Überlebt | Syntaxfehler |
| --- | ---: | ---: | ---: |
| `pb_design` | 99 | 3 | 0 |
| `pb_matrix` | 31 | 1 | 5 |
| `print.pb_design` | 8 | 0 | 0 |
| `msa_robustness` | 110 | 4 | 4 |
| `print.msa_robustness` | 26 | 1 | 0 |
| `plot.msa_robustness` | 25 | 0 | 0 |

Kein Timeout und kein Infrastrukturabbruch. Alle neun überlebenden
Varianten bleiben im Nenner. Acht entsprechen den Kandidatentypen aus
PLAN-REVIEW E1 Nr. 7 (Vergleiche bei ±1-Kodierung, einziges `on.exit()`,
überschriebene Matrixinitialisierung). Die neunte entfernt den abschließenden
Zeilenumbruch der aktiven Faktoren (`R/robustness.R:197`); `capture.output()`
unterscheidet diesen letzten Zeilenumbruch nicht. **Keine MUT-EQUIV-Claims
und keine eigene Äquivalenzfreigabe.** Der Produktcode enthält den Umbruch.

Rohdaten: `mutation-probe.log`, `mutation/diagnostic-results.json` und
`mutation/by-function.log`. Die Mutatorbezeichnungen wurden anschließend
aus `Mutator$print()` ergänzt; die SHA-256 aller 317 erzeugten Quellvarianten
blieben dabei gleich und keine Tests wurden wiederholt (`mutation/metadata.log`).
Dies ist eine gezielte lokale Diagnose; über Schwelle, Floor, Ratchet und
den vollständigen Mutationslauf entscheidet ausschließlich das reguläre Gate.

## Integrität und Übergabe

Die abschließende SHA-256-Inventur (`integrity.py`, Exit 0) bestätigt
`445 baseline files; 6 changed; 3 new; 0 removed`. Die übrigen 439 Dateien
sind bytegleich, darunter alle 136 vorhandenen Testdateien, 49 Anker,
sechs geschützten Datendateien, 24 Golden-Dateien und 32 Dateien unter
`inst/validation/sim/`. Nur die neun im PLAN genannten Dateien sind
geändert beziehungsweise neu. Die erzeugte Rd-Seite gleicht dem
roxygen-Output; die bisherigen PROGRESS-Einträge bleiben bytegleich
erhalten. Vollständiger Output im neuen PROGRESS-Abschnitt.

Keine Git-Kommandos, keine Änderung an Gate-Fakten, Gate-Konfiguration,
Schwellen, Betreiberdateien oder fremden Tests. Keine externe Erhebung und
keine zusätzlichen Daten. Die vollständigen Git-basierten K-M1d-8-/K-M0-7-
Prüfungen, QA, Phasen-Commit, Territoriums-Gate und Abnahme bleiben bei
Orchestrator, QA und Reviewer. Kein Builder-Verdict und kein vorweggenommener
M3b-Gate-Status.
