# M1a — PLAN, Runde 1

## Ziel

`msa_fit(type = "numeric")` und `msa_grr()` sollen K-M1a-1 bis K-M1a-7
aus `docs/02-statistikkern.md`, Abschnitt M1a, erfüllen: numerische
Varianzkomponenten gegen unabhängige ANOVA-Rechnungen, Literatur und
Laufzeit-Orakel, die NIST-Genauigkeitsanforderungen, AIAG-Kennzahlen,
Invarianzen und Randfälle sowie eine ausführbare Validierungsvignette.
Abnahmemaßstab sind die bestehenden Tests und Anker einschließlich
ADR-016; der Plan schlägt keine Änderung ihrer Grenzwerte vor.

Gelesen sind `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, `CRITERIA.json`, die sieben
M1a-Abnahmedateien samt `setup-acceptance.R` und `setup-m1a.R`,
`docs/01-fachspezifikation.md`, der M1a-Abschnitt der Statistikspezifikation
und die einschlägigen Abschnitte 1–3 der Formelsammlung. Ergänzend wurden
ADR-012, ADR-016, ANK-10/13/14/16 und ANK-TOL, der vorhandene Fit-/GRR-Code,
seine Bootstrap-Verwendung, Bestandstests und die Bau-/Testläufer gelesen.
`orchestrator/LESSONS.md` enthält noch keine Lehren.

Der Ausgangsbefund stammt aus **CRITERIA ACC-17**, nicht aus einem neuen
Builder-Testlauf: 54 M1a-Tests, 27 rot, keine Skips. Die bereits grünen
Vergleiche K-M1a-1 bis K-M1a-3 sind bei der Stabilisierung zu erhalten.
Die dokumentierten Lücken betreffen NIST, ndc unter eins, Invarianzen,
konstante Messwerte und die fehlende Vignette. Die inzwischen gelesenen
M2-Fakten (`orchestrator/state/M2/gates.json`, Runde 3, `result: pass`,
und `verdict-code.json`, `PASS`) ergänzen den historischen Stand von
`PROGRESS.md`; den Abschlussvermerk schreibt erst BUILD.

Diese PLAN-Phase liefert ausschließlich diese Datei. Die folgenden
Produktänderungen sind Vorhaben für die freigegebene BUILD-Phase.
Ordinale/binäre Verfahren, neue Bootstrap-Verfahren, AP1-Erhebung und
Klasse-B-Studien werden in M1a nicht vorgezogen. Die bestehenden
Nutzer dieser Kernfunktionen werden als Regression mitgeprüft.

## Dateien

| Geplanter Pfad in BUILD | Änderung und Zweck |
| --- | --- |
| `R/fit.R` | Numerischen Fit konditionieren, Standardoptimierung präzisieren, konstante/nicht endliche numerische Eingaben benannt behandeln und Modellkonsistenz sichern. Die numerischen Kernhelfer bleiben in dieser Mutations-Scope-Datei. |
| `R/grr.R` | ndc-Untergrenze nach ADR-016 E4; definierte Ausgabe bei Gesamtvarianz null; passende Darstellung von NA gegenüber Inf. Gemeinsame Berechnung für `msa_grr()` und `msa_boot()` erhalten. |
| `tests/testthat/test-fit-numeric.R` | Schnelle, unabhängige Regressionsprüfungen für Konditionierung, Modellkonsistenz, Invarianzen, Steuerungsdurchreichung und Fehlerpfade. |
| `tests/testthat/test-grr-numeric.R` | Rechenprüfungen auf konstruierten Komponenten einschließlich Block/Interaktionen, ndc, Verdiktsgrenzen und Nullfällen. Bestehende Tests bleiben erhalten. |
| `tests/testthat/helper-validation-numeric.R`, `tests/testthat/test-validation-numeric.R` | Installierbare Toleranzressourcen strikt einlesen; freie Validierungseingaben, Herkunft, fehlende/defekte Eingaben und die beiden Vignettenkontexte prüfen. Keine Abhängigkeit installierter Unit-Tests von `reference/` oder geschützten Daten. |
| `data-raw/make_validation_numeric.R` | Deterministischer Erzeuger für die freien NIST-Tabellen und die zur Auslieferung benötigten Ankerkopien. Liest die Originalanker und die lokalen NIST-Dateien, prüft deren SHA-256 und Schema vor Ausgabe; optionales `--out <Verzeichnis>` für die Reproduktion. Kein Download. |
| `inst/extdata/nist-strd-anova_2026-10-22/` | Aus den elf benannten NIST-Dateien extrahierte numerische Tabellen mit Behandlung, Replikat und Messwert, `SHA256SUMS` und englischer `QUELLE.txt`. CSV beziehungsweise `.csv.gz` nach ANK-TOL.data_size; keine `.dat`-Rohtexte. Erzeugung braucht einen Builder-ADR im selben Meilenstein. |
| `inst/validation/numeric/reference_checks.R` | Ausführbare Dokumentationsrechnungen und Tabellenaufbereitung: Paketfunktionen aufrufen, unabhängige ANOVA-/Formelrechnung und VCA/SixSigma zur Laufzeit. Kein `source()` aus Abnahmetests und kein Laden eines anderen Paketstands. |
| `inst/validation/numeric/anchors/`, `inst/validation/numeric/SOURCES.json` | Automatisch erzeugte, unveränderte Kopien von ANK-10/13/14/16 und ANK-TOL samt Herkunft und Quellhashes für den Paketbau. `reference/anchors/` bleibt die einzige redaktionelle Autorität; keine manuell gepflegten Ersatzwerte und keine eingefrorenen Orakel-Ausgaben. |
| `vignettes/validation.Rmd` | Neuer englischer Abschnitt „Variance components and gauge R&R (numeric)“, berechnete Referenztabellen und NIST-LRE-Bericht; Zahlen und Toleranzen aus Ankern beziehungsweise Live-Rechnungen. |
| `DESCRIPTION` | `VCA` und `SixSigma` als Suggests ergänzen (ACC-15); vorhandene Suggests für JSON, Hashes und Vignetten nutzen. Keine neuen Imports. |
| `man/msa_fit.Rd`, `man/msa_grr.Rd`, gegebenenfalls `man/msa_boot.Rd`, `NEWS.md`, `README.md` | Numerisches Verfahren, Nullfälle, ndc-Untergrenze und Ausführung der Validierung dokumentieren; Rd aus roxygen2 erzeugen. Bootstrap-Dokumentation nur, soweit die gemeinsame Kennzahlberechnung betroffen ist. |
| `docs/decisions/ADR-<freie Nummer>-m1a-numerische-stabilisierung.md`, `docs/decisions/ADR-<freie Nummer>-m1a-validierungsressourcen.md` | Allgemeines numerisches Verfahren mit Messbelegen sowie Herkunft, Reproduktion und öffentliche Auslieferung der neuen Ressourcen begründen. Nummern erst in BUILD nach dem dann vorhandenen ADR-Bestand vergeben. |
| `PROGRESS.md`, zugewiesene M1a-Builder-Handoffs | M2-Abschluss, Änderungen, ausgeführte Kommandos mit echtem Output, Abweichungen, Laufzeiten und verbleibende Befunde dokumentieren. |

`NAMESPACE` wird nur im Rahmen der Dokumentation auf unveränderte Exporte
und Registrierungen kontrolliert; neue Exporte sind nicht vorgesehen.
Abnahmetests, `tests/simulation/`, Fixtures, Originalanker, Spezifikationen,
BACKLOG, `.Rbuildignore`-Harness-Zeilen, Gate-Auswahl und Orchestratorzustand
bleiben bei ihren Eigentümern. Insbesondere werden keine Kernfunktionen
aus `R/fit.R` oder `R/grr.R` ausgelagert, um den Mutations-Scope zu umgehen.

## Schnittstellen

### Öffentliche API und Ergebnisobjekte

Die Positionen und Vorgaben der bestehenden Argumente bleiben erhalten:

```r
msa_fit(runs, type = c("numeric", "ordinal", "binary"), levels = NULL,
        interactions = NULL, link = c("probit", "logit"), ...)
msa_grr(fit, threshold = NULL, basis = c("study_var", "contribution"))
```

Das gilt auch für die übrigen Funktionen aus ANK-02, einschließlich
`msa_boot()` und `msa_simulate()`. Keine Snapshot-Änderung ist geplant.
`interactions = NULL` bedeutet weiterhin TRUE für numerische und FALSE
für andere Zielgrößen. Das Modell enthält dieselben Haupteffekte und
Zweifach-Wechselwirkungen, ohne Block- oder Dreifach-Wechselwirkungen.

`msa_fit` behält Klasse und Felder `model`, `type`, `link`, `formula`,
`vc`, `data`, `n`, `singular`, `levels`, `interactions`, `derived`.
`vc` bleibt eine Tabelle mit `source` und `variance` auf der ursprünglichen
Messskala. `data` erhält die analysierten Werte und ihre Zuordnung zu den
Eingabezeilen. Fehlende Werte werden nicht ersetzt; `n$observations` zählt
gültige analysierte Werte und `n$reps_per_cell` nur beobachtete Zellen.
Numerische Herkunfts-/Verfahrensangaben dürfen additiv in einem Feld
`numerics` erscheinen, etwa Konditionierung, interne Zeilenabbildung und
verwendetes Verfahren.

Der zurückgegebene `model` muss ein konsistentes lme4-`merMod` bleiben:
`VarCorr(model)` und `vc`, `sigma(model)`, analysierte Antwort,
Fitted Values, Residuen und Vorhersagen müssen dieselbe ursprüngliche
Skala und Beobachtungszuordnung beschreiben. Eine Korrektur ausschließlich
der Tabelle `vc` reicht nicht, weil `msa_boot()` die Komponenten erneut
aus `fit$model` liest. Die Rücktransformation ist deshalb ein eigener
Prüfschritt vor der Integration, kein nachträglicher Dokumentationshinweis.

### Numerische Entscheidung für BL-49, BL-72 und ACC-6

Der Standardfit wird präziser gemacht. K-M1a-6 bleibt bei
`ANK-TOL.invariance`; die lockerere M2-Vergleichstoleranz aus ADR-012 wird
nicht auf dieses Kriterium übertragen. Ein Wechsel des Optimierernamens
allein ist nach den Messungen in ACC-6 kein hinreichender Ansatz.

1. **Konditionierung:** Für den numerischen Rechenweg eine interne
   Darstellung aus stabil zentrierten und skalierten Antworten bilden.
   Den großen gemeinsamen Offset vor Summen-/Quadratbildung abziehen;
   keine Differenz zweier großer unzentrierter Quadratsummen verwenden.
   Ein positiver Maßstab kommt aus den beobachteten Daten. Transformation
   und Rückabbildung gelten für beliebige geeignete Eingaben, unabhängig
   von Datensatzname, Quelle, Größe oder erwarteten Testzahlen.
2. **Deterministische Darstellung:** Die interne Reihenfolge für
   Summation und Faktorcodierung an Beobachtungen und
   Stufenmitgliedschaften ausrichten, nicht an der Schreibweise der
   Labels. Zeilenpermutation, Umbenennung und Gleichstände ausdrücklich
   behandeln; die ursprüngliche Zuordnung bleibt erhalten. Die
   Darstellung verändert weder die Gruppierung noch das statistische
   Modell und rundet keine Messwerte oder Ergebnisse auf Teststellen.
3. **Standardoptimierung:** Ohne explizites `control` eine enge
   bobyqa-Steuerung im konditionierten REML-Problem verwenden.
   Konvergenz- und Singularitätsprüfungen bleiben aktiv. Die konkrete
   numerische Steuerung wird im frühen BUILD-Versuch anhand von
   Maschinengenauigkeit, Fehlern und Laufzeit bestimmt und im
   numerischen ADR dokumentiert; sie wird nicht aus erwarteten
   Komponenten oder einer gewünschten Klassifikation abgeleitet.
4. **Balancierter Einfaktorfall:** Die geschlossene REML-Lösung aus
   Formelsammlung §2 für den allgemeinen Intercept-/Random-Intercept-Fall
   als präzise Initialisierung beziehungsweise Nachpolitur nutzen:
   Rest = MS_within, Item = (MS_between − MS_within)/Replikate, sofern
   die Komponenten nichtnegativ sind. Die Mittelquadrate werden stabil
   aus den übergebenen Daten gerechnet, nicht aus ANK-14 gelesen.
   Bei negativer Item-Momentenschätzung gilt das restringierte Optimum
   mit Item null und neu geschätzter Restvarianz SST/(N−1), nicht bloßes
   Abschneiden bei unverändertem Rest. Das muss in das konsistente
   lme4-Modell eingehen. Voraussetzungen werden strukturell geprüft;
   unbalancierte/gewichtete oder anders spezifizierte Fälle gehen durch
   den allgemeinen REML-Pfad. Degenerierte Fälle erhalten einen
   benannten Fehler, falls kein auswertbares Modell entsteht.
5. **Explizite Steuerung:** Ein vom Aufrufer geliefertes `control`,
   einschließlich `lmerControl()` und absichtlich kleinem `maxeval`,
   wird unverändert wirksam. Kein Austausch durch die Standardsteuerung,
   keine stille erfolgreiche Nachoptimierung nach einem erzwungenen
   Abbruch. `start`, `weights`, `offset`, `subset` und weitere unterstützte
   lmer-Argumente behalten ihre Bedeutung; zeilenbezogene Angaben müssen
   bei internen Umordnungen mitgeführt werden. Die spezielle geschlossene
   Nachpolitur darf einen expliziten Optimiererauftrag nicht ersetzen.
6. **Grenzen und Diagnostik:** Nichtkonvergenz-Warnungen von lme4 erreichen
   den Aufrufer und bleiben im Modell nachvollziehbar. Nichtnegative
   Komponenten und `singular = TRUE` an der Grenze werden erhalten.
   Identische numerische Werte werden früh mit einer englischen
   Fehlermeldung abgewiesen; nach der numerischen Konvertierung wird
   auch eine leere beziehungsweise nicht endliche Antwort geprüft.

Die Konditionierung und Modellrücktransformation werden zunächst an
synthetischen Fällen sowie den unveränderten K-M1a-4/-6-Tests gemessen.
Bestehen sie die Modellkonsistenz oder die festen Genauigkeitsgrenzen
nicht, wird der Befund mit Kommando, Steuerung und Abweichungen vorgelegt.
Ein uneinheitliches Ergebnisobjekt, Rundung auf Ankerwerte oder eine
Toleranzänderung sind keine Ausweichlösung. ADR-016 E6 weist die dann
gegebenenfalls nötige Eskalation mit Messwerten dem Reviewer zu.

### GRR-Vertrag

EV bleibt die Restvarianz, AV die Summe von Prompt, Modell, Block und
den drei Zweifach-Wechselwirkungen, GRR = EV + AV und TV = GRR + PV.
`msa_grr()` berechnet aus `fit$vc$variance`, einschließlich konstruierter
Komponenten; es liest keine möglicherweise veralteten SD-/Prozentfelder.
Zeilenbezeichnungen, Tabellenspalten und Summary-Namen bleiben wie in
ACC-10/12 und im Bestand.

Für positive Gesamtvarianz gelten die Formeln aus §3 der Formelsammlung
und ANK-16, insbesondere ndc mit 1,41, Abrundung und Untergrenze eins.
Bei GRR null und PV positiv bleibt ndc Inf und das Verdikt acceptable.
Bei TV null hat die Nichtbestimmbarkeit Vorrang: Prozentanteile, ICC und
ndc werden als NA statt NaN geführt, Varianzen und SD bleiben null,
das Verdikt ist undetermined. Dies konkretisiert den Nullfall aus
K-M1a-5 ohne Division durch null. Die Ausgabe unterscheidet NA und Inf.
Die beiden exakten Study-Variation-Grenzen bleiben marginal, eigene
Schwellen und die Basis contribution mit der Konvention 1/9 bleiben
verfügbar. Die gemeinsame Berechnung gilt auch für Bootstrap-Statistiken;
die weitergehende Bootstrap-Abnahme folgt in M1c.

### Vignette und Herkunft der Eingaben

Die Vignette hat zwei ausdrücklich beschriebene Ausführungskontexte:

- **Vollständige lokale Validierung:** Ein gesetztes `REPO_ROOT` wählt
  die Originalanker unter `reference/anchors/`, das lokale AIAG-Blatt
  und die NIST-Originale neben dem Repo. Ungültiger Pfad, fehlender
  Anker, fehlendes Datenblatt oder falsche SHA-256 führen zu einem
  benannten Abbruch. Das ist der Kontext des unveränderten
  Abnahmetests ACC-14 und der Harness-Prüfungen.
- **Öffentlicher Paketbau ohne `REPO_ROOT`:** Anker werden aus den
  automatisch erzeugten Paketressourcen, freie NIST-Daten aus
  `system.file("extdata", ...)` gelesen. Alle freien Prüfungen werden
  neu gerechnet. Für die geschützten AIAG-Daten nennt die Vignette
  erwartete Ankerwerte, lokale Reproduktionsanleitung und ausdrücklich
  `Not rerun: protected data required`; sie zeigt dafür keinen
  erfundenen beobachteten Wert und keinen PASS. AIAG-Rohdaten und
  eingefrorene VCA-/SixSigma-Ergebnisse werden nicht ausgeliefert.

Diese Auslegung des öffentlichen Dokumentationsbaus wird im PLAN-REVIEW
zu ACC-14 ausdrücklich zur Prüfung gestellt: `docs/01` §6 verlangt
öffentliche Tests auf freien Daten, K-M1a-7 verlangt zugleich Bau ohne
ERROR/WARNING trotz des ausgeschlossenen `reference/`-Baums. Die lokale
Abnahme bleibt vollständig und scheitert bei fehlenden geschützten
Eingaben. Ein fehlendes lokales Blatt löst im Vollmodus niemals den
öffentlichen Modus aus. Der Builder-ADR dokumentiert nach Freigabe die
Ressourcen; eine bindende Spec-Auslegung dokumentiert der Reviewer.

Ankerkopien werden aus den Originaldateien erzeugt und byteweise samt
SHA-256 verglichen. Fehlende Schlüssel werden mit `[[ ]]` und expliziter
Prüfung erkannt (BL-72). Die Erzeugung der NIST-CSV erhält die
Zahlentokens so, dass erneutes Einlesen dieselben Doubles wie das
Original ergibt; keine nachträgliche Dezimalreparatur schwieriger Werte.
Bei Kompression werden variable gzip-Zeitstempel vermieden. Für jede
Datei werden Quelle, Lizenz, Auswahlregel, Quellhash und gespeicherter
Hash dokumentiert; die drei Größenlimits kommen aus ANK-TOL.data_size.

Im vorgeschriebenen Abschnitt stehen mindestens fünf Referenztabellen,
bei mehreren Gegenrechnungen getrennte Tabellen. Jede hat genau eine
Spalte mit den Präfixen `Anchor`, `Source`, `Expected`, `Observed`,
`Tolerance`, `Result`, ohne leere Pflichtzellen. Alle in ACC-14 genannten
Anker-IDs, AIAG-Größen und Penicillin-Varianzen/SD erscheinen. Weitere
Spalten dürfen Kennzahl, Datensatz und Diagnostik nennen.

Die NIST-Tabelle enthält für SmLs04–SmLs09 je Datensatz die vier
Spalten `LRE msa_fit residual`, `LRE msa_fit item`, `LRE aov residual`,
`LRE aov item`; Inf bei exakter Übereinstimmung, NA bei einem benannt
berichteten nicht auswertbaren Fit. Bei SmLs04–SmLs06 bleiben Fehler
oder zu kleiner LRE fehlgeschlagene Prüfungen. SmLs07–SmLs09 sind
Berichtsfälle. AtmWtAg wird als NIST-„Average“ bezeichnet und trotzdem
gegen die strengere Spec-Anforderung geprüft (ADR-016 E5).

Beobachtete Werte entstehen immer aus dem aktuell geladenen
Paketnamespace, auch in Mutationskopien. Die Vignette lädt keinen
unveränderten Repo-Paketstand nach. Referenzrechnung und Produktrechnung
werden getrennt formuliert; kein Kopieren der Reviewer-Helfer und keine
Erwartung aus der zu prüfenden Produktfunktion. Caches bleiben auf einen
Knit-Prozess beschränkt, damit nach Codeänderungen und je Mutant neu
gerechnet wird. Keine Netzaufrufe, keine Ausgabedateien in `vignettes/`,
keine Ergebnis-/Toleranzliterale im Rmd oder versteckt in Hilfsdateien.
Warnungen dürfen für einen ausdrücklich ausgewiesenen Befund gesammelt,
aber nicht als erfolgreicher Fit ausgegeben werden.

### Behandlung der Acceptance-Verträge

| ACC-ID | Festlegung für den Plan |
| --- | --- |
| ACC-1 | ADR-016 E1 und ANK-13 übernommen: Bates 2010, Varianzen und quadrierte gedruckte SD gegen die Summe der gedruckten Varianzen; ANOVA-Zweitbeleg erhalten. Die frühere Quellenlücke ist erledigt. |
| ACC-2 | ADR-016 E2 übernommen: anovaVCA auf unbalanciertem `ic50_demo` nur berichten; remlVCA bleibt Kriterium. |
| ACC-3 | Reviewer-Lesart übernommen: `ss.rr(time1, prototype, operator)` mit Paketvorgaben einschließlich alphaLim, msa_fit mit Wechselwirkung; Prozentwerte aus ungerundeter StdDev, weggepoolte Wechselwirkung als null. Der Reviewer hält die angekündigte Auslegung im ADR fest. |
| ACC-4 | Modellzuordnung bestätigt: AIAG ohne Wechselwirkung gegen beide VCA-Verfahren, zusätzlich mit Wechselwirkung gegen remlVCA; ic50 mit Interaktionen und Block. Reviewer-ADR wie angekündigt. |
| ACC-5 | ADR-016 E3 übernommen: bobyqa aus ANK-TOL.reml_anova wird bei K-M1a-1 explizit durch `...` übergeben; andere Kriterien behalten ihre Aufrufe mit Paketvorgaben. |
| ACC-6 | Entscheidung oben: konditionierter, enger Standardfit mit messbarer Invarianz; keine Lockerung von ANK-TOL.invariance. |
| ACC-7 | ADR-016 E4 umsetzen: ndc-Untergrenze eins auch für PV null bei positiver GRR. |
| ACC-8 | AtmWtAg-Einstufung und unveränderte Genauigkeitsanforderung explizit in der Vignette nennen. |
| ACC-9 | Dateihashes, Rollenabbildung, LRE-Definition, aus dem Anker gelesene Marge und vier LRE-Werte je Datensatz bestätigt. Höhere Schwierigkeit nur berichten. Reviewer-ADR wie angekündigt. |
| ACC-10 | Tabellenvertrag und ANK-10-Toleranzrechnung bestätigt: Komponenten/quadrierte SD relativ zur publizierten TV-Varianz; Rundung plus REML-Anteil für TV-SD und Prozente; ndc gleich. Reviewer dokumentiert die Auslegung. |
| ACC-11 | Vier balancierte Designs mit Seed 1 plus Penicillin, ANOVA-Voraussetzungen, ndc-Abstand und beide expliziten Kontrollaufrufe bestätigt. |
| ACC-12 | Konstruktion durch Ersetzen von `vc$variance`, alle acht Quellen, Grenzfälle und ANK-TOL.arithmetic bestätigt; TV-null-Ausgabe oben konkretisiert. |
| ACC-13 | Singularität, zufällig gelöschte Zellen/NA-Replikate, gültige Zählungen, Konstantenfehler und unverfälscht weitergegebene Konvergenzwarnungen bestätigt. |
| ACC-14 | Titel, Tabellen, dynamische Werte, Knit nach tempdir und Verbot neuer Dateien in `vignettes/` bestätigt. Öffentlicher Bau ohne lokale Quellen wie oben zur ausdrücklichen Planprüfung vorgeschlagen. |
| ACC-15 | VCA/SixSigma in Suggests aufnehmen; lokale Quellen strikt prüfen und Vignetten-/Mutationslaufzeit messen. Die Pakete sind bei der Lesediagnose bereits installiert. |
| ACC-16 | Reviewer-Nachweise einschließlich AIAG-Originalabgleich und Gegenproben gelesen. Der Builder ersetzt sie nicht durch eigene Abnahmebehauptungen. |
| ACC-17 | Historische rote Ausgangsmessung übernommen; aktueller Erfolg ist erst durch neue ausgeführte Tests belegbar. |
| ACC-18 | Penicillin in K-M1a-3(c) mit Paketvorgaben, Toleranz aus ANK-13, keine implizite Übernahme des K-M1a-1-Optimiererauftrags. Reviewer-ADR wie angekündigt. |

## Reihenfolge

1. **Freigegebenen Vertrag und Ausgangsstand sichern.** PLAN-REVIEW,
   gegebenenfalls PLAN-UPDATE/ARBITER und neue Reviewer-ADRs lesen.
   Produkt-/Test-/Ankerinventar ohne Git erstellen; Abhängigkeiten nur
   prüfen. In BUILD den unveränderten M1a-Testlauf mit echtem Output als
   Ausgangsmessung protokollieren und den M2-Abschluss in PROGRESS ergänzen.
2. **Numerischen Ansatz zuerst prüfen.** K-M1a-4 und K-M1a-6 sind der
   kritische Pfad. Konditionierung, enge Steuerung und Einfaktor-Lösung
   implementieren und ihre Rücktransformation separat prüfen. Die
   Prüffälle umfassen zusätzliche Seeds, positive und negative Skalierung,
   große Offsets und kleine Streuung sowie Umbenennungen mit Gleichständen.
   Erst nach konsistentem `merMod` und eingehaltenen Toleranzen die
   Integration abschließen; Messwerte und Verfahren im ADR dokumentieren.
3. **GRR und numerische Randfälle abschließen.** ndc/TV-null und Ausgabe
   korrigieren, Warnungen und Zählungen testen. Anschließend K-M1a-1 bis
   K-M1a-6 zusammen ausführen, damit Verbesserungen nicht die bestehenden
   AIAG-/Orakelvergleiche oder die explizite Steuerung beschädigen.
4. **Reproduzierbare öffentliche Ressourcen erzeugen.** Golden-ADR,
   NIST-Erzeuger, Ankerkopien und Provenienz hinzufügen. Alle Eingaben
   vor dem Schreiben prüfen, zweimal in getrennten Verzeichnissen
   erzeugen und Bytes/Hashes vergleichen; bestehende AP1-Golden-Dateien
   bleiben unverändert. Fehlender oder falscher Eingang muss den
   Erzeuger ohne teilweise veröffentlichte Ausgaben stoppen.
5. **Vignette und Dokumentation bauen.** Vollmodus mit lokalen Quellen,
   öffentlicher Modus ohne REPO_ROOT/geschützte Dateien und die verwendeten
   englischen Texte prüfen. roxygen2 in einer temporären Paketkopie
   ausführen und nur die betroffenen zulässigen Dokumentationsdateien
   übernehmen. Die Vignette wird bei jedem Lauf neu gerechnet.
6. **Regression, Paketbau und Übergabe.** Finale Unit-/QA-Bestandstests,
   vollständige M1a-Abnahme, betroffene M2-Auswertung und Paketcheck
   ausführen. Ausgaben, Zeiten und Grenzen in PROGRESS/Handoff aufnehmen.
   QA-E2E/Fuzz bleibt QA-Aufgabe. Orchestrator führt Territoriumsprüfung,
   Phasen-Commit und alle Gates aus; der Reviewer nimmt ab. Der Builder
   schreibt weder Verdicts noch Gate-Fakten.

## Risiken

| Risiko / Referenz | Behandlung und Entscheidungsgrenze |
| --- | --- |
| Flaches REML-Optimum, ACC-6, BL-49/72 | Präzise Steuerung mit Konditionierung und deterministischer Darstellung zusammen prüfen; zusätzliche synthetische Fälle verhindern eine Anpassung allein an Acceptance-Seeds. Bei belegtem Nichterreichen Abweichungen je Komponente/TV und Kennzahl melden, keine Toleranzkorrektur. |
| Inkonsistentes `merMod` nach Transformation, `R/grr.R` / K-M1c-1 als Folgeabhängigkeit | Modellskala, Originalzeilen, VarCorr, sigma, Vorhersagen, Residuen und Bootstrap-Punktschätzer vor Integration prüfen. Keine Ausgabe, deren `vc` und Modell zwei verschiedene Fits beschreiben. |
| NIST-Darstellungsgrenzen, K-M1a-4, BL-23 | Aus bereits eingelesenen Doubles verlorene Stellen nicht erfinden; LRE beider Verfahren auf denselben Daten berichten. AtmWtAg bleibt bei der strengen Vorgabe; höhere Schwierigkeit erhält Befunde statt einer Erfolgsbehauptung. |
| Lokale Quellen versus öffentliches Paket, K-M1a-7, BL-09/42 | Strikter Vollmodus und dokumentierter öffentlicher Bau; geschützte Eingaben niemals ausliefern. Quellenfehler sind benannte Fehler. Die Lesediagnose belegt aktuell alle benötigten Hashes. |
| Laufzeit, BL-13/46, ACC-15 | VCA und Vignette werden je Testprozess nur einmal für identische Prüfungen gerechnet; keine dauerhaften Ergebnis-Caches. Zeiten für Fit, Vignette, Tests, Build/Check und später Gate-Logs erfassen. Gate-Timeouts/Mutationsauswahl bleiben Betreiberentscheidungen. |
| Plattformen und Folgeanwender, ADR-012, BL-52/72 | Keine Fork-Parallelisierung in R/. Nur portable Pfade, Ressourcen über system.file; M2-Rückfall und Bootstrap gegen den geänderten Kern prüfen. Windows/macOS-Fakten stammen erst aus Betreiber-CI, nicht aus einem lokalen Linux-Lauf. AP1-Zahlen bleiben bis M1-Abnahme vorläufig. |

### Offene Backlog-Einträge

Alle 57 nach dem gelesenen BACKLOG offenen IDs sind unten einzeln
zugeordnet. „Vertagt“ bedeutet keine Schließung; Änderungen an BACKLOG
und die Statusentscheidung bleiben beim Reviewer beziehungsweise
Betreiber. Betriebspunkte und fremde Territorien erzeugen keinen
Builder-Scheinfix.

| ID | Maßnahme oder begründete Vertagung |
| --- | --- |
| BL-01 | M1a auf die sieben Kriterien begrenzen; M3-Entscheidung bleibt nach M1d beim Betreiber. AP1-Erhebung wird durch diese Phase nicht verändert. |
| BL-02 | Vertagt an Betreiber/Publikationsarbeit: Abgrenzung der Neuheit ist kein numerisches M1a-Kriterium; keine unbelegte Neuheitsbehauptung in der Vignette. |
| BL-03 | Vertagt nach M1b/M1d: ordinales Ersatzverfahren und dessen ADEMP-Studie; in M1a nur Regression des bestehenden numerischen AP1-Rückfalls. |
| BL-04 | Vertagt nach M1c/M1d: Überdeckungsstudie und Befunde brauchen das abgenommene Bootstrap-Verfahren. |
| BL-05 | Bestehende AP1-Vorbehalte bleiben erhalten; Memorisierungsauswertung an Betreiber/Endauswertung vertagt, da M1a keine Referenzklassifikation ändert. |
| BL-06 | Betreiber: Modellzugang und Umleitungsprüfung nach M0; außerhalb der Builder-Rolle. Keine Modellrouten-/Berechtigungsänderung. |
| BL-07 | Betreiber im AP1-Betrieb: Provider-Stichproben und Wiederholungstage; der M2-Code gilt laut jüngstem Backlog-Stand als abgedeckt. Keine API-Aufrufe in M1a. |
| BL-08 | Vertagt zu AP7/Betreiber: Partnerdaten und Datenschutzvereinbarung sind kein Eingang dieser lokalen statistischen Validierung. |
| BL-09 | In M1a aktiv beachten: AIAG-Rohblatt und Buchdateien bleiben lokal; öffentliche Ressourcen enthalten nur freie NIST-Daten und vorhandene zitierte Anker. |
| BL-10 | Betreibertermin bleibt abhängig von M1-Abnahme und erneuter AP1-Auswertung; M1a allein rechtfertigt keine Veröffentlichung. |
| BL-11 | Betreiber/Dashboard-Abgleich; M1a protokolliert seine Arbeit, führt aber keine Kosten- oder Harness-Telemetrie ein. |
| BL-12 | Vertagt zu Vollläufen nach M1b/M1c; M1a liefert keine vorgezogenen Klasse-B-Ergebnisse. |
| BL-13 | In M1a messen: eigene Laufzeiten sowie später vom Orchestrator erzeugte Gate-Dauern. Anpassungen von Budgets oder Studienklassen bleiben Betreiber-/ADR-Aufgabe. |
| BL-14 | Numerischen Anteil jetzt durch unabhängige Quellen, Rechenfälle und mutationstaugliche Regression abdecken; ordinal/binär und Bootstrap verbleiben bei M1b/M1c. |
| BL-15 | Vertagt nach M3a und zur Projektdokumentpflege: Fleiss-Kappa ist nicht Gegenstand von M1a. |
| BL-17 | Vertagt nach M3d/AP2: ellmer-Aufzeichnungen und Live-Lauf; bestehende Backendtests unverändert mitprüfen, keine neue Backendimplementierung. |
| BL-18 | Aufgeteilt vertagt: Bootstrap-Fehlzählung/Wortlaut nach M1c, Berichtshash nach M3d. ndc-/Nullfallkorrektur ändert diese Arbeiten nicht. |
| BL-20 | Vertagt nach M1b: wine-/clmm2-Vergleich betrifft die ordinale Engine. |
| BL-21 | Vertagt an Reviewer: geschachtelte NIST-Fallstudie hat kein M1a-Kriterium; keine Umdeutung in ein gekreuztes Modell. |
| BL-22 | In M1a erfüllen: AIAG mit interactions = FALSE reproduzieren; vollständiges Interaktionsmodell gesondert berichten. |
| BL-23 | In M1a erfüllen: allgemeine numerische Stabilisierung und LRE-Bericht mit Darstellungsgrenzen, ohne nachträgliche Datenreparatur. |
| BL-24 | Betreiber vor M3a: globale Mutations-Baseline zurücksetzen, wenn der Scope erweitert wird; kein Zustandszugriff durch den Builder. |
| BL-25 | In M1a beachten: Originalanker bleiben unverändert; notwendiger Nachtrag nur durch Reviewer mit ADR. Neue NIST-Golden-Daten erhalten ihren Builder-ADR. |
| BL-28 | Betreiber/AP1: Konten, Schlüssel und Limits sind außerhalb dieser Phase; kein Lesen von Geheimnisdateien. |
| BL-29 | Betreiber/Infevers: Anfrage und Veröffentlichungsrecht offen halten; keine INSAID-Referenzklassen in M1a-Artefakte übernehmen. |
| BL-30 | Vertagt zu AP2/Betreiber: Pages, DOI, About, Release; kein Veröffentlichungsauftrag in M1a. |
| BL-31 | Betreiber: Commitidentität/Push-Konfiguration; keine Git-Kommandos des Builders. |
| BL-33 | Betreiber/PREFLIGHT: Rollen-CLI und Sandboxvoraussetzungen; M1a ändert keine Berechtigungen. |
| BL-34 | Betreiber: Erreichbarkeit im RUNBOOK; Eskalation läuft über den vorgesehenen Orchestrator-Touchpoint, nicht über einen neuen Builder-Kanal. |
| BL-35 | Vertagt ins Template-Backlog; notify-Verhalten liegt außerhalb der Produkt- und Phasenaufgabe. |
| BL-36 | Betreiber bei Bedarf: WSL-Ablage optimieren. Quellen bleiben außerhalb; M1a erzeugt keine vollständige Rohdatenkopie. |
| BL-37 | Mit BL-11 an Betreiber vertagt: Kostenspur ist Harness-Arbeit. |
| BL-39 | Betreiber/Beschaffung; keine dieser fehlenden Quellen ist Ersatz für die vorhandenen M1a-Anker. DIN-Verfahren bleiben außerhalb des Scopes. |
| BL-40 | Vertagt nach M1d/Publikationsarbeit: Konkordanzliteratur betrifft die dortigen Anwendungsbeispiele. |
| BL-41 | Betreiber vor einer entsprechenden Zitierung; M1a führt keine Landis/Koch-Bezeichnungen ein. |
| BL-42 | M1a-Teil verfügbar: AIAG-Hash aktuell geprüft, Originalabgleich laut ACC-16 erledigt. Andere geschützte Blätter vor ihren späteren Meilensteinen an Betreiber/Reviewer vertagt. |
| BL-43 | Betreiber vor AP1: Live-Katalog/Preise prüfen; M1a benutzt keine Live-Anbieterinformationen. |
| BL-44 | Vertagt nach M3a: Fleiss-Varianz gegen die dort festgelegte Quelle prüfen. |
| BL-45 | Betreiber nach Meilenstein: externe Projekt-/Harness-Unterlagen pflegen; kein Builder-Schreiben außerhalb des Repos. |
| BL-46 | In M1a beginnen: kleine freie Datentabellen und Zeitmessung beider Vignettenkontexte; weitere Vignetten folgen M1d. Timeout-Anpassung bleibt Betreiberarbeit. |
| BL-47 | Bei späterer Publikation beachten; M1a verwendet keine VariantBench-Daten oder -Referenz. |
| BL-48 | Zuordnung für M1a unter docs/gates-auswahl.md gelesen; K-M2-7 ist inzwischen ergänzt. Die noch fehlende maschinelle Gate-Zuordnung bleibt Betreiber-/Reviewer-Aufgabe. |
| BL-49 | In M1a beachten: K-M1a-1 nutzt explizit bobyqa nach ADR-016 E3 bei unveränderter Toleranz; Standardfit zusätzlich nach ACC-6 stabilisieren. |
| BL-50 | Vertagt nach M3c: Planungsnäherung CV ist dort ein Bericht, kein Gleichheitskriterium; M1a ändert msa_plan nicht. |
| BL-51 | Vertagt bis nach AP1: acmg-Funktionen bleiben intern, keine Exportentscheidung in M1a. |
| BL-52 | In M1a dokumentieren: AP1-Erstzahlen bleiben vorläufig; Betreiber wiederholt die Auswertung nach M1-Abnahme mit demselben externen Store. |
| BL-55 | In M1a beachten: nur zugewiesene Dateien schreiben, Builds/Reports außerhalb des Arbeitsbaums; Betreiberdateien nicht während einer Modellphase erzeugen. Template-Verhalten bleibt Betreiberarbeit. |
| BL-57 | In M1a API-Obermenge und Defaults prüfen. Keine neuen öffentlichen Argumente vorgesehen; zusätzliche Review-Prüfung bleibt beim Reviewer. |
| BL-60 | Mit BL-17 nach M3d vertagt: ellmer-/Streaming-Mocks sind unabhängig vom numerischen Kern. |
| BL-64 | An die nächste freigegebene AP1-/M3d-Berichts- oder Pipelinepflege vertagt: Quantilkopplung wirkt bei Planwert 7 nicht auf M1a. Keine beiläufige Änderung von R/acmg.R. |
| BL-68 | Vor einer nächsten AP1-Berichts-/Pipelinekorrektur beheben lassen: Herkunftsmeldung ist ein nonblocking Wortlautbefund, kein M1a-Statistikkriterium. |
| BL-70 | Betreiber/Template-Backlog: Status, Timeout, STOP und QA-Probe-Logs; keine Harness-Änderung im Statistikkernplan. |
| BL-71 | Betreiberentscheidung vor AP1-Endauswertung, gegebenenfalls ADR für neue Memorisierungskennzeichen/Golden-Daten. M1a verändert die eingefrorenen AP1-Daten nicht. |
| BL-72 | Numerischen offenen Teil jetzt behandeln: enge Standardsteuerung plus Konditionierung, exaktes Toleranzeinlesen und plattformgeeignete Prüfungen. M2-Toleranzen/Pfadkorrekturen aus ADR-012 bleiben bestehen. |
| BL-73 | Vor AP1-Bericht an Betreiber/Pipelinepflege vertagt: Spaltenerklärung bleibt offen. Der aktuelle Code berechnet recomputed_cost_usd bereits ohne Einschränkung auf geroutete Modelle; Schließung/Restprüfung durch den Eigentümer. |
| BL-74 | Betreiber/AP1: geschlossene Blöcke und Laufzeitplanung; etwaige Parallelisierung braucht den eigenen Auftrag/ADR und gehört nicht in M1a. |
| BL-75 | Vor AP1-Bericht an Pipelinepflege vertagt: Netzwartezeiten bei Latenzkennzahlen abziehen; kein Einfluss auf Varianzkomponenten aus Messwerten. |

Bereits als erledigt geführt werden BL-16, BL-19, BL-26, BL-27, BL-32,
BL-38, BL-53, BL-54, BL-56, BL-58, BL-59, BL-61, BL-62, BL-63,
BL-65, BL-66, BL-67 und BL-69. Sie werden nicht erneut eröffnet.
Insbesondere sind die historischen M2-Hinweise zu NOT_CRAN und
Provider-Logging durch die späteren Betreiberänderungen überholt.

## Testplan

### Fachliche Nachweise nach der Implementierung

| Kriterium | Unveränderter Abnahmeweg und ergänzende Builder-Prüfung |
| --- | --- |
| K-M1a-1 | `test-m1a-1-reml-anova.R`: vier balancierte Designs und Penicillin gegen unabhängige stats::aov-EMS-Rechnung, nichtnegative Vorbedingungen und ndc-Abstand; Komponenten als Anteil von ANOVA-TV, abgeleitete Größen relativ. Optimiererauftrag aus ANK-TOL und explizites lmerControl() nachweisen. Ergänzend andere festgehaltene Seeds und Zwei-Stufen-Faktoren, ohne negative Momentenschätzer als REML-Fehler zu werten. |
| K-M1a-2 | `test-m1a-2-aiag.R`: lokale Datei/Hash/Design und Handbuch-ANOVA, danach EV/AV/GRR/PV/TV, beide Prozentarten und ndc gegen ANK-10. Zweitbeleg über ANOVA und VCA. Abweichung bei interactions = TRUE berichten, nicht mit dem gepoolten Handbuchmodell gleichsetzen. |
| K-M1a-3 | `test-m1a-3-oracles.R`: remlVCA auf ic50 und AIAG; anovaVCA auf AIAG, auf ic50 nur Bericht; SixSigma mit ACC-3; Penicillin gegen ANK-13 und ANOVA-Zweitbeleg. Orakel zur Laufzeit auf identischen Daten, Toleranzen unverändert. |
| K-M1a-4 | `test-m1a-4-nist.R`: alle elf Eingangsdateien; fünf strenge Fälle gegen zertifizierte Rest-/Itemwerte, drei mittlere gegen LRE(aov) minus Anker-Marge; drei hohe berichten. Zusätzlich Einfaktor-REML auf konstruierten Daten mit kleinen/großen Einheiten, negativem Momentenschätzer und unbalancierter Gegenprobe prüfen. |
| K-M1a-5 | `test-m1a-5-metrics-verdict.R`: alle Tabellen-/Summary-Größen aus konstruierten acht Komponenten, Konstante/Untergrenze, exakte und benachbarte Verdiktsgrenzen, GRR-null und TV-null. Ergänzend contribution-Basis, eigene Schwellen und druckbare NA-/Inf-Unterscheidung. Erwartung aus eigenständiger Algebra, nicht aus grr_stats. |
| K-M1a-6 | `test-m1a-6-invariance-edge.R`: ic50 und balancierter Blockplan mit Paketvorgaben, alle Transformationen, Singularität, unbalancierte Zellen und gültige Zählungen, konstante Werte, erzwungene Nichtkonvergenz. Zusätzlich kombinierte Transformationen, negative Skalierung, wiederholte Messwerte/Gleichstände und unveränderte RNG-/Eingabeobjekte prüfen. |
| K-M1a-7 | `test-m1a-7-vignette.R` plus LRE-Vignettentest aus K-M1a-4: Titel, Tabellen/IDs/Werte, dynamisches Einlesen, keine Ergebnisliterale, keine neuen Dateien im Vignettenordner. Vollmodus und öffentlicher Paketbau separat ausführen; lint trägt den tatsächlichen Bau ohne ERROR/WARNING. |

Für zusätzliche Modellkonsistenztests werden `vc` und `VarCorr(model)`
quellenweise verglichen, sigma² mit der Restkomponente, Antwort mit
Fitted Values plus Residuen, sowie die Beobachtungszuordnung nach
Permutation/Umbenennung geprüft. Vorhersagen und Bootstrap-Punktschätzer
werden gegen den Originalskalenfit beziehungsweise seine GRR-Statistiken
geprüft. Toleranzen kommen aus ANK-TOL (arithmetic, oracle,
reml_anova, invariance, engine_boot entsprechend dem Vergleich), niemals
aus fehlenden Schlüsseln oder neu gewählten Akzeptanzliteralen.

Für numerische Prüfdaten und Transformationen wird der Seed protokolliert,
mit Mersenne-Twister/Inversion/Rejection, R-/Paketversionen und
`sessionInfo()`. Diese endlichen Regressionsfälle beanspruchen keine
ADEMP-Aussage über Überdeckung oder Bias. Klasse-A-/Klasse-B-Studien und
ihre Vorgaben bleiben bei den vorgesehenen späteren Kriterien.

### Ausführung in BUILD und durch den Orchestrator

Geplante direkte Builder-Kommandos aus der Repo-Wurzel:

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
Rscript --vanilla -e 'grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m1a-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE); grDevices::dev.off()'
Rscript --vanilla -e 'grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m2-6-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE); grDevices::dev.off()'
```

Reproduktion des neuen Erzeugers erfolgt mit `--out` in zwei temporäre
Verzeichnisse; deren Inhalte werden byteweise miteinander und mit den
vorgesehenen Paketressourcen verglichen. Negativfälle verwenden nur
temporäre Eingabekopien. Fehlende Suggests werden im Builder nicht
installiert; das deps-Gate ist zuständig. Fehlende geschützte Quellen
werden nicht übersprungen oder durch Fixtures ersetzt.

Für einen zusätzlichen Paketcheck wird ausschließlich die Positivliste
der Paketdateien in ein temporäres Verzeichnis außerhalb des Arbeitsbaums
kopiert. Dort, ohne REPO_ROOT, lokale Quellen oder Harness-Dateien:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht dem bestehenden Betreiberprüfskript;
weitere Check-Regeln werden nicht abgeschaltet. Tarball, Rcheck,
Knit-Ausgaben, Plots und Logs entstehen außerhalb des Arbeitsbaums.
Ein bestätigter Fehler wird mit seinem echten Output dokumentiert,
einschließlich bekannter Sandbox-/Socketgrenzen bei M2-Prüfwegen.

Der vollständige kumulative Abnahmelauf mit M0-Prüfungen, lint,
trace, territory, golden-adr und mutgate bleibt beim Orchestrator:
mehrere dieser Wege enthalten Git-Kommandos. Der Builder startet weder
den Verifier noch `r-check.sh` oder Mutation-Gate-Skripte. Mutgate bleibt
bei Scope `R/fit.R`, `R/grr.R`, 80 Prozent, Floor 80, Ratchet 2 und
14 Workern; keine selbst genehmigten Äquivalenz-Claims. `88-mutfull` ist
erst in M1c fällig. MUT_TEST_DIRS bleibt unverändert;
`tests/simulation/` gehört weiterhin nicht dazu. Laufzeiten werden nicht
durch übersprungene Kriterien verkürzt. QA wird separat tätig; deren
Tests werden vom Builder gelesen und ausgeführt, nicht geschrieben.

### Tatsächlich ausgeführte Lesediagnosen dieser PLAN-Phase

Es wurden keine fachlichen Tests, Builds oder Gates ausgeführt.
Die folgenden Outputs stammen aus dieser Phase und belegen ausschließlich
die verfügbaren Eingaben und Werkzeuge:

```text
R: 4.6.1
lme4: 2.0.6
VCA: 1.5.2
SixSigma: 0.11.1
jsonlite: 2.0.0
digest: 0.6.39
knitr: 1.52
rmarkdown: 2.32
M1a anchors: 5 JSON files readable with matching IDs
AIAG data: SHA-256 matches ANK-10
NIST data: 11/11 SHA-256 matches ANK-14
```

Die Versionen wurden mit `Rscript --vanilla -e` über `getRversion()`,
`requireNamespace()` und `utils::packageVersion()` gelesen (Exit 0).
Die Hashprüfung lief mit `python3`, `json.loads()` und
`hashlib.sha256(Path.read_bytes())` gegen die unveränderten
`value.data_file`-/`value.datasets`-Einträge der Anker (Exit 0).
`lmerControl()` wurde ebenfalls lesend geprüft: explizite Steuerung ist
verfügbar; sein Vorgabeoptimierer heißt nloptwrap. Die lokale Verfügbarkeit
der modularen lme4-Helfer ersetzt keinen Beleg für die geplante
Konditionierung oder Rücktransformation.

Vor dem Schreiben dieses Plans wurden 173 Produkt-, Test-, Dokumentations-
und Kontextdateien per SHA-256 in einem Sitzungsinventar erfasst.
Die anschließende Python-Prüfung der Planstruktur und ID-Abdeckung endete
mit Exit 0 und folgendem Output:

```text
PLAN structure: 6/6 required sections, in schema order
Criteria coverage: 7/7 M1a criteria
Acceptance notes: 18/18 ACC IDs explicitly addressed
Open backlog: 57/57 IDs with a separate disposition
Markdown code fences: balanced
```

Der erneute SHA-256-Sitzungsvergleich der erfassten Dateien ergab
`{"count":173,"changed":[],"added":[]}`. Die Dateien wurden weder
geändert noch entfernt; in den kontrollierten Pfaden kamen keine hinzu.
Auch diese Kontrolle erteilt keine Abnahme. Keine Git-Kommandos, keine
Installation und kein Netzzugriff in dieser Phase. Die einzige
geschriebene Repository-Datei ist `orchestrator/handoff/M1a/PLAN.md`.
