# ADR-020 — M1a: numerischer REML-Abschluss und konsistentes lme4-Modell

## Status

Builder-Entscheidung zur Umsetzung des freigegebenen PLAN-UPDATE (Runde 2)
und ADR-018/019 in BUILD M1a. Die Messbelege werden in dieser Phase
ergänzt; dieses ADR erteilt keine Abnahme.

## Entscheidung

- Numerische Eingaben bleiben Doubles; ausschließlich Zeichen und Faktoren
  werden über ihre Beschriftungen geparst. Nicht endliche Antworten und
  konstante gültige Antworten enden mit englischer Diagnose.
- Der Vorgabepfad konditioniert Differenzen zu einer beobachteten Antwort
  und skaliert mit der größten absoluten Differenz. Bei drohendem Überlauf
  wird vor der Differenzbildung mit einer Zweierpotenz skaliert. Auch bei
  vielen Gleichständen bleibt der Maßstab positiv, sofern Variation vorliegt.
- Vollständige balancierte Kreuzungen mit nichtnegativen EMS-Schätzern
  erhalten die geschlossene REML-Lösung aus Formelsammlung §2. Mittelquadrate
  entstehen aus orthogonalen Effekten und direkt gebildeten Residuen.
  Negative Momentenschätzer führen zum restringierten Gesamtmodell;
  ausschließlich im Einwegfall ist die restringierte Lösung unmittelbar
  bekannt (Item null, Rest SST/(N−1)).
- Für die übrigen Fälle liefert lme4 auf der konditionierten Antwort den
  Start. Ein analytischer Newton-Abschluss optimiert Varianzverhältnisse
  mit aktiven Nullgrenzen. Score und Krümmung folgen dem profilierten
  REML-Kriterium aus PLAN-UPDATE; Zufallseffektraum und sparse Cholesky
  ersetzen eine dichte Beobachtungs-Kovarianzmatrix. Abschluss verlangt
  kleinen projizierten Score und kleinen Krümmungs-Korrekturschritt,
  dimensionslos mit Ziel `sqrt(.Machine$double.eps)`. Ein gescheiterter
  Abschluss liefert einen Fehler, niemals den Startfit als Ersatz.
- `lFormula`, `mkLmerDevfun` und `mkMerMod` bauen auf den Originaldaten
  das endgültige Modell am endgültigen Theta. `vc` stammt ausschließlich
  aus `VarCorr(model)`; Antwort, Labels und Eingabereihenfolge bleiben.
  `checkConv` erhält analytische Ableitungen auf der Theta-Skala.
- Startwarnungen und Startmeldungen werden mit Herkunft in
  `numerics$start` gespeichert. Scheitert der Abschluss, werden die
  gesammelten Startwarnungen vor dem Fehler weitergegeben. Die finale
  lme4-Konvergenzprüfung bleibt aktiv. `numerics` und `optinfo` nennen das
  tatsächliche Abschlussverfahren zusätzlich zum Refit-Haken.
- Der Refit-Haken lautet `nloptwrap`, mit normalen lme4-Vorgaben und
  leerem `optCtrl`. Der gespeicherte Aufruf enthält den auswertbaren
  Ausdruck `lme4::lmerControl(optimizer = "nloptwrap")`. `refit` und
  `bootMer` bleiben gewöhnliche lme4-REML-Refits.
- Sobald irgendein Argument in `...` steht, läuft direkt
  `lme4::lmer(form, data = dat, REML = TRUE, ...)`, einschließlich der
  originalen Warnungen. Es gibt dort weder Konditionierung noch Abschluss.

## Abhängigkeit

`Matrix (>= 1.6-0)` wird direkter Import. Verwendet werden sparse Matrizen,
`Diagonal`, `forceSymmetric`, `Cholesky`, `solve`,
`crossprod`/`tcrossprod`, `rowSums` und `determinant` (bei CHMfactor mit
explizitem `sqrt = FALSE`). Das optionale `sqrt`-Argument kam laut dem
lokal installierten `Matrix/NEWS.Rd`, Abschnitt 1.6-0, erst in dieser
Version hinzu. Die vorläufige Annahme 1.3-0 wurde deshalb vor dem finalen
Paketcheck berichtigt. Die 1.6-Reihe nennt R >= 3.5 (NEWS 1.6-2,
Compatibility); die Anforderung ist unter R 4.1 erfüllbar. Keine
Schnittstelle von Matrix 1.7 wird vorausgesetzt; R >= 4.1 bleibt
unverändert. Ein Lauf unter R 4.1 wird hier nicht behauptet.
Die vorhandene Umgebung (Matrix 1.7.4, lme4 2.0.6) wird nicht aktualisiert.
Die Freigabe des Imports folgt docs/01 §5 und ADR-018 Nr. 6.

## Belege und Folgen

Der gesicherte Ausgangskern ist durch SHA-256 identifiziert:

```text
R/fit.R 761faa4c4519cea2770f4c746fe002f72b91979bb625cb3a598f2af7655c93e1
R/grr.R 6c0d8b57e54f4a72a5667ad89f3b0119acd9ca020bb669a060e3ec2ed9224fed
M1a baseline: 54 tests; 21 failed blocks; 6 error blocks; 0 skipped; elapsed 22.56 s
```

Der Go/No-Go einschließlich der zusätzlichen Szenarien nach ADR-018 Nr. 5,
Modellkonsistenz, Ableitungsprüfungen und Laufzeitvergleich ist vor der
Ressourcenproduktion erforderlich. Der Befund und die genauen Kommandos
werden in `PROGRESS.md` festgehalten. Fehler in `msa_plan()` beenden die
Planung; der bestehende AP1-Rückfall meldet sie mit seinem Präfix weiter.

## Numerische Umsetzung und Go/No-Go (29.10.2026)

Der Intercept wird vor der sparse Faktorisierung algebraisch eliminiert:
`C = Z'Z - Z'1 1'Z/N`, `B = I + sqrt(D) C sqrt(D)`. Das ist derselbe
REML-Operator wie im PLAN-UPDATE; `log|H| + log|X'H^-1 X|` wird zu
`log|B| + log(N)`. So entfällt die instabile Differenz im Intercept-
Schur-Komplement. `Q` ist die Summe der quadrierten konditionierten
Residuen und penalisierten Zufallseffekte, keine Differenz großer
Quadratsummen. Die größten dichten Zwischenmatrizen haben die Dimension
der Zufallseffekte, nie N × N. Score und Krümmung werden blockweise aus
`Z'PZ` und `Z'Py` gewonnen.

Die Newton-Richtung wird nach `max(1, lambda)` skaliert. Für eine
indefinite Krümmung begrenzt `sqrt(eps) * max(1, max(abs(eigenvalues)))`
die Eigenwerte der Schrittmatrix; das verändert nur die Richtung, nicht
das statistische Modell. Schrittbegrenzung trifft Nullgrenzen exakt,
Halbierung verlangt Abstieg. Innerhalb einer Rundungsreserve
`64 * eps * max(1, abs(F))` darf ein Schritt mit kleinerem projiziertem
Score angenommen werden. Abschluss verlangt weiterhin **beide** Normen
≤ `sqrt(eps)` und positive freie Krümmung. Höchstens 100 Newton-Schritte
und 50 Halbierungen je Schritt, keine aus Ankern gewählten Steuerwerte.

Echte Ausgaben vor der Ressourcenarbeit:

```text
Numeric first: 40 tests; 0 failed blocks; 1 error blocks; 0 skipped
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 465 ]
Invariance: 250 transformed fits; max component/TV 1.91366e-09; max relative metric 2.63966e-09; distant discrete cases 250; failures 0
Methods: analytic_reml 30; closed_form 220
Model consistency: VarCorr, sigma, response, fitted, residuals and predictions passed for all original and transformed fits
Dense reference: criterion error 1.06581e-14; score error 5.32907e-15; Hessian relative error 1.18928e-10
Serialization, refit control and same-seed bootMer: passed
```

Der einzige Fehler des frühen unveränderten Abnahmelaufs ist die noch
fehlende Vignette (`test-m1a-4-nist.R:94`), kein numerischer Fehlschlag.
Die Transformationen umfassen vier Designs × Seeds 1–6 sowie ic50_demo,
je Permutation, Umbenennung, Verschiebung um 100/10000, Skalierung mit
7,5/0,02/0,001/1000/−7,5 und kombinierte Transformation. Alle Fälle halten
die vorgeschriebenen Abstände zu diskreten Grenzen ein. Die bisherigen
Numerikgrenzen wurden unverändert aus ANK-TOL gelesen.

ADR-018 Nr. 5: je Szenario Seeds 1–20, ohne Fehler:

| Szenario | closed_form | analytic_reml | singulär | Median s | Maximum s |
| --- | ---: | ---: | ---: | ---: | ---: |
| S-boot-1 | 18 | 2 | 2 | 0,0470 | 0,154 |
| S-boot-2 | 15 | 5 | 5 | 0,0610 | 0,307 |
| S-boot-3 | 16 | 4 | 4 | 0,1045 | 0,559 |
| S-boot-4 | 20 | 0 | 0 | 0,1740 | 0,281 |
| S-boot-5 | 10 | 10 | 10 | 0,0685 | 0,139 |
| S-boot-6 | 13 | 7 | 7 | 0,0590 | 0,206 |
| msa_plan: 20 Items, 3 Prompts | 1 | 19 | 19 | 0,0775 | 0,197 |
| msa_plan: 40 Items, 3 Prompts | 3 | 17 | 17 | 0,1425 | 0,197 |
| msa_plan: 20 Items, 6 Prompts | 2 | 18 | 18 | 0,1320 | 0,242 |
| msa_plan: 40 Items, 6 Prompts | 5 | 15 | 15 | 0,2915 | 0,594 |

Laufzeitvergleich mit dem gesicherten Kern, ein Aufwärmlauf und drei
Messungen je Fall, dieselben installierten Pakete, Seed 20261029:

```text
ic50_demo: before median 0.389 [0.389, 0.389] s; after median 0.461 [0.460, 0.478] s; ratio 1.185
SmLs03: before median 0.043 [0.043, 0.050] s; after median 0.045 [0.045, 0.045] s; ratio 1.047
msa_plan: before median 0.216 [0.215, 0.230] s; after median 0.544 [0.543, 0.660] s; ratio 2.519
msa_boot: before median 0.103 [0.102, 0.108] s; after median 0.115 [0.113, 0.118] s; ratio 1.117
```

Planung: zwei Szenarien (12/20 Items, 3 Prompts, 2 Modelle, 2 Replikate),
fünf Wiederholungen. Bootstrap: 12 Items, 3 Prompts, 2 Modelle,
3 Replikate, acht Wiederholungen; Refit mit gewöhnlichen Vorgaben.
Die Planung bezahlt den zusätzlichen Erstfit bei jeder Wiederholung;
der Bootstrap behält die gewöhnliche Refit-Steuerung. Die Messung ist
ein endlicher Robustheits-/Laufzeitversuch, keine ADEMP- oder Coverage-
Aussage. Der Vorversuch trägt die Ressourcenarbeit. Gates und
Mutationsabnahme bleiben offen.

## Nachtrag REWORK M1a, Runde 2: ADR-022 umgesetzt

Die Nachprüfungen aus REVIEW Runde 1 zeigen zwei Grenzen, die der erste
BUILD nicht zuverlässig erkannt hat: Rundungsreste bei verschwindender
Restvarianz und Stellenverlust im Originalskalenmodell. Dieser Nachtrag
präzisiert die numerische Fehlerbehandlung, ohne Kriterien, Anker oder
Testtoleranzen zu ändern.

### Relative Restvarianzprüfung (E20)

Für konditionierte Antworten wird die Restquadratsumme gegen
`(64 * .Machine$double.eps)^2 * SST` geprüft. Die Größe ist eine relative
Rückwärtsfehlerschranke: Differenzen der Größenordnung von 64 Maschinen-
Epsilon der Antwortnorm können durch Mittelwertbildung, Projektion und
Effektabzug entstehen; ihre Quadratsumme ist kein Beleg für positive
Reststreuung. Der Faktor ist eine interne Rundungsreserve, keine empirische
Referenz oder absolute Varianzuntergrenze. Skalieren der Antwort skaliert
beide Seiten identisch.

Die Prüfung gilt für die balancierten Modellresiduen, für Einwegresiduen
auch bei ungleicher Besetzung sowie für das profilierte REML-`Q` im
allgemeinen Abschluss. Identische Zellreplikate allein sind kein Fehler:
Ist etwa eine nichtadditive Wechselwirkung ausgelassen, kann ihre Streuung
eine positive Modellrestvarianz tragen. Ein neuer Test belegt diesen
Gegenfall. Eine fehlgeschlagene sparse Faktorisierung oder Lösung wird
zusätzlich als benannte, nicht auflösbare Restvarianz gemeldet. Matrix-
Warnungen werden in diesem engen Rechenschritt in einen Fehler übersetzt;
es wird kein Startwert oder anderes Ergebnis als Ersatz zurückgegeben.
Startwarnungen von lme4 folgen weiterhin dem ursprünglichen Vertrag.

### Präzision auf der Originalskala (E21, E23)

Aus dem konditionierten Ergebnis entstehen zunächst die Standardabweichungen
`sqrt(residual) * scale * binary_scale` und `theta` mal diese Größe, erst
danach ihre Quadrate. So verursacht ein isoliert quadrierter Maßstab
keinen unnötigen Zwischenüberlauf oder Unterlauf.

Die interne relative Präzisionsgrenze ist `sqrt(.Machine$double.eps)`.
Sie wird ausschließlich aus der Rechnerarithmetik hergeleitet. Vor dem
Originalmodellbau werden nicht endliche oder auf null untergelaufene
positive Varianzen abgelehnt. Auch die kleinste Double-Schrittweite
`double.xmin * double.eps`, relativ zu jeder positiven Komponente, muss
diese Grenze einhalten. Damit kann die Übereinstimmung zweier bereits
grob quantisierter subnormaler Zahlen keinen erfolgreichen Fit vortäuschen.

Nach `mkMerMod()` werden sämtliche positiven `VarCorr`-Komponenten mit
der zurückskalierten konditionierten Lösung verglichen. Da dieselben
Varianzverhältnisse verwendet werden, sichert insbesondere die Prüfung
der Restvarianz auch die gemeinsame Skalierung. Ein relativer Fehler
einer Komponente von höchstens `sqrt(eps)` ist als Anteil der Gesamtvarianz
höchstens ebenso groß. Zusammen mit der zuvor begrenzten Darstellungs-
auflösung bleibt die Reserve `2 * sqrt(eps)` deutlich unter
`ANK-TOL.invariance.component_tol_fraction_of_total_variance`. Das ist
eine zusätzliche Produktprüfung; der Anker bleibt unverändert und wird
nicht vom Produktcode eingelesen.

Bei Überschreitung lautet der Fehler:
`Numeric model variance is not representable on the original scale at working precision.`
Es wird kein getrennt korrigierter `vc`-Wert neben einem ungenauen Modell
ausgegeben. SmLs07–SmLs09 dürfen deshalb nach ADR-022 als `NA` mit Grund
berichtet werden. Niedrige und mittlere NIST-Schwierigkeit bleiben
unveränderte Abnahmekriterien.

### Durchreichweg und Metadaten (E18, E19, E21)

`subset`, `weights` und `offset` werden in den dokumentierten Datenspalten
mit der Aufruferumgebung als Rahmen ausgewertet. Nicht datenbezogene
Argumente werden als ursprüngliche Promises erzwungen; ihre Werte stehen
danach im gespeicherten Aufruf. Auch weitergereichte lokale Steuerungen
und explizites `NULL` behalten dadurch ihre Bedeutung. Die Rechnung selbst
bleibt `lme4::lmer` auf der unveränderten Originalantwort. Modellaufrufe
beider numerischer Wege enthalten den Datenrahmen als Wert; sie funktionieren
nach Serialisierung und außerhalb des ursprünglichen Gültigkeitsbereichs.

Der Modellrahmen liefert die analysierten Zeilen. `data`, alle Zählungen
und `input_rows` folgen dieser Auswahl einschließlich `na.action`, Reihenfolge
und wiederholter Subset-Indizes. Numerisches `NaN` und geparstes `"NaN"`
werden gleich als fehlend behandelt. Fehlende Gruppierungswerte werden
vor der numerischen Pfadwahl benannt abgelehnt. Ordinale/binäre
Gruppierungsfehlstellen bleiben wie in ADR-022 dem Meilenstein M1b zugeordnet.

Die ausgeführten Belege und die Antwort auf jede Befund-ID stehen in
`orchestrator/handoff/M1a/REWORK-NOTES.md` und `PROGRESS.md`. Nur die Gates
des Orchestrators entscheiden über die Abnahme.

## Nachtrag REWORK M1a, Runde 3: Modellrest vor dem Startfit (E44)

Die Prüfung vor dem allgemeinen lme4-Startfit verwendet jetzt den
Kleinste-Quadrate-Rest der konditionierten Antwort auf dem Spaltenraum
des tatsächlich enthaltenen Zufalls-Intercept-Designs `Z`. Jeder vollständige
Indikatorblock enthält bereits den Intercept in seinem Spaltenraum; die
Projektion ist deshalb die auf `span(1, Z)`. `stats::lm.fit()` berechnet
den Rest durch rangaufdeckende QR mit seiner üblichen Rangprüfung. Abhängige
Indikatorspalten und fehlende Zellen sind zulässig. Es wird keine Kovarianz-
oder Projektionsmatrix von N × N gebildet; die zusätzliche dichte Matrix
ist ausschließlich das rechteckige Design N × q und nur im allgemeinen
Pfad nötig. Die analytische REML-Rechnung im Zufallseffektraum bleibt gleich.

Die zusätzliche Fehlerdiagnose setzt positive Restfreiheitsgrade dieser
Projektion voraus. Bei vollem Zeilenrang ist jeder Antwortvektor im
Spaltenraum; sein Projektionsrest ist dann ohne Aussage über die
REML-Restvarianz. Solche Pläne behalten den bisherigen allgemeinen
REML-Pfad. Ein sechszeiliger unbalancierter Gegenfall mit gesättigtem
Spaltenraum hat nach direktem lme4 und der geschlossenen Randlösung
`SST / (N - 1)` positive Restvarianz (Seed 1); ein eigener Unit-Test
sichert diesen Unterschied ab.

Die unveränderte relative Grenze `(64 * .Machine$double.eps)^2 * SST`
aus dem Nachtrag der Runde 2 entscheidet über verschwindenden Modellrest.
Damit scheitern auch unbalancierte Mehrfaktorpläne vor dem lme4-Startfit
benannt, statt rohe C++-/Matrix-Fehler oder Startwarnungen auszulösen.
Die Prüfung verändert weder Daten noch Varianzen. Ausgelassene
Wechselwirkungen können weiterhin positive Restvarianz tragen; gleiche
Replikate allein lösen keinen Fehler aus. Der explizite Durchreichweg
nach ADR-018 Nr. 2 bleibt die unveränderte lme4-Rechnung.

Neue Regressionen in `test-fit-residual-design.R` prüfen die Modellräume
unabhängig über `stats::aov`, positive Gegenfälle gegen `lme4::lmer` und
kleine positive profilierte Quadratsummen gegen eine Rang-eins-Formel.
Runde 3 dokumentiert die tatsächlichen Ergebnisse und Laufzeiten in
`REWORK-NOTES.md` und `PROGRESS.md`. Das bestehende Verhalten des gespeicherten
Modellaufrufs bleibt erhalten; `?msa_fit` nennt die große Druckausgabe
(E45) und die unmittelbare Aufruferumgebung für Datenmasken-Ausdrücke (E46).

Gemessen in Runde 3: Auf ic50_demo (2152 × 297 Design-Einträge,
4,88 MiB reine Double-Nutzlast) steigt die mediane Fit-Zeit über fünf
alternierende Läufe nach Aufwärmen von 0,489 s auf 0,564 s, Faktor 1,153.
Varianzkomponenten und Numerikdiagnosen sind dort, auf vier weiteren
unbalancierten Plänen mit Seeds 1–4 und auf dem gesättigten
Sechszeilenplan mit Seed 1 exakt gleich zum gesicherten
Ausgangscode. Die neue Testdatei besteht mit 124 Erwartungen, die
unveränderte M1a-Abnahme mit 54 Testblöcken / 722 Erwartungen. Dies sind
lokale Prüfbelege; Gatebudgets und Abnahme bleiben unverändert.

## Nachtrag REWORK M1a, Runde 4: Fehler des Startfits (E50–E52)

Auch der lme4-Startfit auf der konditionierten Antwort kann scheitern,
obwohl die Modellrestquadratsumme oberhalb der relativen Nullgrenze liegt
(E50). Genau dieser Aufruf erhält eine Fehlerbehandlung: Er endet mit
`Numeric model initialization failed: ` und der unveränderten Meldung
der Engine als Ursache. Die äußere Fehlerklasse ist ein gewöhnlicher
R-Fehler ohne internen Aufruf, keine durchgereichte `Rcpp::exception`.
Der Zusatz benennt die fehlgeschlagene Stufe, ohne jede mögliche
Startursache pauschal als Restvarianz null zu deklarieren. Vor dem Fehler
gesammelte Warnungen werden weiter vom vorhandenen `on.exit`-Handler in
ihrer Reihenfolge ausgegeben. Es gibt keinen Ersatzfit, keine künstliche
Reststreuung und keine Änderung der Null-, Präzisions- oder Abschlussgrenzen.
Der explizite Durchreichweg behält die originalen lme4-Fehler und Warnungen.

Die neue Datei `tests/testthat/test-fit-initialization.R` prüft die drei
Reproduktionen aus E50. `stats::aov` belegt unabhängig positive Reststreuung
oberhalb der Grenze; ein direkter lme4-Aufruf liefert die tatsächliche
Startursache. Ein ausdrücklich synthetischer Enginefehler mit zwei Warnungen
prüft deren Weitergabe auch beim Startabbruch. Positive Gegenfälle mit
ausgelassener Wechselwirkung werden gegen lme4 gerechnet, auch nach
Skalierung mit `1e-100`. Numerische Toleranzen stammen aus ANK-TOL; nur der
Präfix der eigenen Diagnose ist als Ausgabecharakterisierung gekennzeichnet.
Ausgeführte Kommandos und echte Ausgaben stehen in REWORK-NOTES und PROGRESS.

**E51 / BL-87:** Positive und darstellbare Restvarianz ist keine Garantie
für erfolgreiche Initialisierung oder analytischen Abschluss bei hoher
Wiederholpräzision. `?msa_fit` nennt diese Einschränkung jetzt ausdrücklich.
Die weitergehende Verbesserung des Abschlusskriteriums und der zusätzliche
Robustheitsnachweis für Restanteile `1e-4` und `1e-6` bleiben vor M1d offen.
Die bisherige Robustheitstabelle belegt diese zusätzlichen Szenarien nicht.

**E52 / BL-88:** Die Projektion aus Runde 3 benötigt O(Nq) zusätzlichen
Speicher und O(Nq²) Arbeit für die dichte QR; jeder allgemeine Fit in
`msa_plan()` trägt diesen Aufwand. Die Messungen des Reviewers aus REVIEW
Runde 3, Nachprüfung 7, zeigen die Grenze des bisherigen ic50-Vergleichs:
AP1-Gesamtplan, 5130 × 717, 28,1 MiB reine Double-Nutzlast, 0,76 s
Projektion und Fit 1,73 → 2,50 s; Plan mit 200 Items, 6840 × 2027,
105,8 MiB, 7,66 s Projektion und Fit 23,8 → 32,1 s. Das sind ausdrücklich
die Reviewer-Messungen, keine neuen Messungen oder Budgets dieser Runde.
Die Fehlerbehandlung aus E50 verändert die Projektion nicht. Ihre sparsame
Umsetzung oder Verlagerung bleibt eine getrennte Optimierung; dieser
Nachtrag erfüllt die vorgeschlagene Dokumentationsoption.

## Nachtrag REWORK M1a, Runde 5: Modellbau auf der Originalskala (E54, E56)

Nach ADR-022 Nr. 6.2 endet auch ein Abbruch beim Aufbau des
Originalskalenmodells mit
`Numeric model variance is not representable on the original scale at working precision.`
Das betrifft `lFormula`, `mkLmerDevfun`, die Auswertung von `devfun(theta)`,
`mkMerMod` und das anschließende Auslesen von `VarCorr`. Ein Fehler oder
eine Warnung innerhalb dieser eng begrenzten Engineaufrufe beendet den
Fit sofort mit `simpleError` und ohne internen Aufruf. Eine Warnung wird
damit in einen benannten Fehler übersetzt, nicht still unterdrückt; ein
teilweise aufgebautes Modell wird nicht verwendet. Die bestehenden
Darstellbarkeitsprüfungen vor und nach diesen Schritten verwenden dieselbe
Meldung. Nullgrenze, Präzisionsgrenze, Varianzschätzer und Abschlusskriterium
bleiben unverändert.

`checkConv` steht ausdrücklich außerhalb dieser Fehlerbehandlung. Seine
Warnungen erreichen weiterhin den Aufrufer, und seine Diagnostik geht in
das fertige Modell ein. Scheitert der Modellbau nach dem allgemeinen
REML-Abschluss, gibt der vorhandene `on.exit`-Handler die gesammelten
lme4-Startwarnungen weiterhin in ihrer Reihenfolge aus. Der direkte
Durchreichweg nach ADR-018 Nr. 2 behält die originalen Enginebedingungen.

`test-fit-model-construction.R` enthält 18 neue Testblöcke: die drei
E54-Reproduktionen, den positiven Gegenfall mit Replikatrauschen `1e-3`,
Fehler und Warnungen an allen fünf genannten Enginegrenzen, eine Warnung
mit anschließendem Fehler, die getrennte Konvergenzprüfung, Startwarnungen
nach einem späteren Modellbaufehler und den expliziten Durchreichweg.
Die Vorbedingungen und Komponenten kommen aus `stats::aov` und den
expliziten Zweifaktor-EMS-Formeln der Formelsammlung §2; numerische
Toleranzen aus ANK-TOL. Nur der englische Diagnosetext ist als eigene
Ausgabe charakterisiert. Wenn eine andere Plattform die drei schwierigen
Modelle darstellen kann, verlangt der Test die ANOVA-Komponenten statt
eines künstlich erzwungenen Enginefehlers. Die synthetischen
Enginebedingungen prüfen die Fehlerbehandlung unabhängig von der Plattform.
Mit dem Ausgangscode sind 15 Blöcke rot (47 fehlgeschlagene Erwartungen);
mit der Korrektur bestehen alle 129 Erwartungen.

**E56 / BL-87, zusätzliche balancierte Gegenrechnung:**
`/tmp/llmsa-m1a-r5/probe-construction.R` wurde gegen den gesicherten Code
der Runde 4 und den aktuellen Code ausgeführt. Synthetische Pläne:
6 Items × 4 Prompts × 1 Modell × 2 Replikate,
8 × 3 × 1 × 3 und 10 × 3 × 2 × 2, jeweils mit allen enthaltenen
Zweifach-Wechselwirkungen. Effekte mit Seed 11, Replikatrauschen
`10^(-3:-10)` mit Seeds 1001–1005, RNG
`Mersenne-Twister/Inversion/Rejection`. Das sind 120 feste Prüfeingaben,
keine ADEMP-, Coverage- oder populationsbezogene Erfolgsquotenaussage.
Alle haben positive Restfreiheitsgrade, Restquadratsumme über der
unveränderten Nullgrenze und endliche, nichtnegative ANOVA-Schätzer.

Tatsächlicher Output (`probe-construction.log`, Exit 0):

```text
120 cases; 8 raw errors before, 0 after; 6 arithmetic warnings before, 0 after
45 unchanged successful fits; maximum component/TV error against aov EMS 3.76805041e-09 (ANK-TOL.oracle 0.0001)
```

Die 45 erfolgreichen Fits behalten Komponenten, Theta, Numerikdiagnosen
und Warnungen exakt bei. Die übrigen 75 Fälle enden benannt: 34 wegen
Darstellbarkeit des Originalmodells, 41 wegen nicht auflösbarer Restskala
im konditionierten Rechenschritt. Die Korrektur erweitert also nicht den
Konvergenzbereich. Alle drei E54-Einzelfälle haben jetzt `simpleError`
mit dem Darstellbarkeitstext, ohne Aufruf und ohne Warnung; vorher lieferten
sie `Rcpp::exception`, einer davon zusätzlich zwei CHOLMOD-Warnungen.

Für 6 × 4 × 1 × 2 mit Seed 11/1001 ist bei Rauschen `1e-3` der
`closed_form`-Fit warnungsfrei. Bei `1e-4` und `1e-5` bleibt jeweils
`Hessian is numerically singular: parameters are not uniquely determined`
sichtbar, obwohl die Komponenten die EMS-Gegenrechnung bestehen.
`checkConv` verwendet Theta, also Standardabweichungsverhältnisse;
kleine Krümmung auf dieser Skala ist hier keine strukturelle
Nichtidentifizierbarkeit. `?msa_fit` nennt jetzt sowohl diese Grenze
als auch den Modellbau nach einer geschlossenen Lösung als mögliche
Fehlerstelle. Die weitergehende Verbesserung des allgemeinen Abschlusses
und dessen Robustheitsnachweis aus E51/BL-87 bleiben vor M1d offen.

Die vollständigen Befehle, M1a-Abnahme und Infrastrukturgrenzen stehen in
REWORK-NOTES und PROGRESS. Dieser Nachtrag erteilt keine Gate-Abnahme.
