# M1a — REWORK, Runde 2

Bearbeitung 29.–30.10.2026.

## Grundlage und Rollenabgrenzung

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS und Handoff-Schema,
REVIEW und verdict-code Runde 1, CRITERIA, gates.json einschließlich der
roten Logs, freigegebener Plan/PLAN-UPDATE, einschlägige Spezifikationen,
Abnahmetests und ADR-016 bis ADR-022. ARBITER.md existiert nicht;
LESSONS.md enthält keine Lehren. ADR-022 ist für diesen Rework bindend.

Die Ausgangsfakten bleiben unverändert: `orchestrator/state/M1a/gates.json`
nennt Runde 1, `tests: fail`, `mutgate: fail`; kein Gate hat Status `error`.
`mutfull: pass` bedeutet ausdrücklich „nicht fällig in M1a“. Nur ein neuer
Orchestratorlauf kann diese Gate-Fakten ablösen. Es wurden keine eigenen
Git-Kommandos ausgeführt und keine vorhandenen Tests, Abnahmetests,
QA-Dateien, Gates, Schwellen, Anker, Golden-Daten oder Specs geändert.

`orchestrator/state/M1a/gate-tests.log` endet fachlich mit:

```text
r-tests: fail — 281 Tests in tests/testthat, tests/acceptance, tests/e2e, tests/fuzz; 5 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

`orchestrator/state/M1a/gate-mutgate.log` belegt den Abbruch vor Mutationen:

```text
r-mutation: unmutierter Testlauf: 86.1 s; 218 Tests, davon 5 fehlgeschlagen, 0 abgebrochen
r-mutation: Abbruch vor dem ersten Mutanten: Schon unmutiert scheitern 5 Tests (/mnt/c/Users/Danie/dev/Llmsa/llmsa/reports/mutation/unmutated.json)
```

## Antworten auf jeden Befund

- **E18 — behoben, QA-M1a-001:** `R/fit.R` erzwingt nicht datenbezogene
  `...`-Argumente in ihrer ursprünglichen Promise-Umgebung und speichert
  Werte im vollständigen `lme4::lmer`-Aufruf. Explizite lokale Steuerungen,
  `start`, weitergereichte Argumente und explizites `NULL` behalten ihre
  Bedeutung. Auch der Vorgabeaufruf enthält die Daten als Wert.
  `test-fit-rework-inputs.R` prüft Serialisierung, `update`, `refit` und
  gleich geseedetes `bootMer` gegen einen direkten lme4-Aufruf.

- **E19 — behoben, QA-M1a-002:** `subset`, `weights` und `offset` werden im
  internen Datenrahmen mit der Aufruferumgebung als Rahmen ausgewertet.
  `data`, alle Zählungen und `numerics$input_rows` folgen anschließend den
  Zeilen des tatsächlichen Modellrahmens. Neue Tests vergleichen mit
  direktem `lmer`, einschließlich `na.exclude`, fehlenden Gewichten,
  widersprechender Aufrufervariable, Reihenfolge und doppelten Indizes.

- **E20 — behoben, QA-M1a-003:** Der numerische Kern prüft die quadrierte
  Restnorm relativ zur zentrierten Gesamtquadratsumme. Die aus
  Maschinenpräzision abgeleitete Grenze steht im Rework-Nachtrag zu
  ADR-020. Eine zusätzliche Einwegprüfung erfasst ungleiche Besetzungen.
  Nicht auflösbare Matrix-Faktorisierungen enden mit einer benannten
  Restvarianzdiagnose; rohe Matrix-Warnungen werden nicht als erfolgreiche
  Rechnung weitergereicht. Startwarnungen von lme4 bleiben erhalten.
  Tests umfassen exakt degenerierte Pläne, die Gleichheit an der
  relativen Grenze, eine injizierte Faktorisierungswarnung und einen
  Gegenfall mit identischen Replikaten, aber schätzbarer ausgelassener
  Wechselwirkung. Kleine positive Streuung wird nicht absolut abgeschnitten.

- **E21 — behoben, QA-M1a-004:** Die Rückskalierung multipliziert zuerst
  Standardabweichungen. Positive Varianzen mit nicht ausreichender
  Originalskalengenauigkeit werden mit `representable` benannt abgelehnt.
  Numerisches `NaN` und geparstes `"NaN"` sind ohne Parsingwarnung fehlend.
  Alle vier numerischen Gruppierungsfaktoren werden vor beiden Fit-Pfaden
  auf fehlende Werte geprüft. Tests decken beide NaN-Formen, beide Pfade,
  jede Gruppierung, subnormale Skalen und darstellbare kleine Skalen ab.

- **E22 — behoben, QA-M1a-005:** `R/grr.R` validiert `threshold` gemäß
  ADR-022; Gleichheit und Null bleiben zulässig. Der öffentliche
  Ressourcenprüfer in `inst/validation/numeric/reference_checks.R` prüft
  die exakte Anker-Dateimenge, die exakte NIST-Datensatzmenge, doppelte
  Einträge, Originalhashes gegen ANK-14 sowie Hashes und Pfade der Kopien.
  Ein explizites `data_dir` wird bis zum Prüfer durchgereicht.
  Neue Tests unter `test-grr-rework.R` und `test-validation-rework.R`
  verändern ausschließlich temporäre Kopien der Ressourcen.

- **E23 — behoben:** Nach dem Modellbau werden dessen Varianzen gegen die
  zurückskalierten konditionierten Varianzen geprüft. Bei unzureichender
  Genauigkeit entsteht derselbe benannte Darstellbarkeitsfehler. Der
  zurückgegebene Fit enthält weiterhin die Originalantwort; `vc` stammt
  ausschließlich aus `VarCorr(model)`. Keine zweite Varianztabelle
  überschreibt das Modell. `ic50_demo + 1e10` und NIST werden gegen
  zentrierte Rechnung bzw. ANOVA geprüft. SmLs01–SmLs06 bestehen;
  SmLs07–SmLs09 werden bei Präzisionsverlust ausdrücklich als NA mit
  Fehlermeldung berichtet. Verfahren und Grenze sind in ADR-020 begründet.

- **E24 — fachlicher Vorlauf repariert; Gate-Wiederholung offen:** Die fünf
  unveränderten QA-Tests bestehen. Die Unit-/QA-Suite und die M1a-Abnahme
  wurden tatsächlich ausgeführt, siehe Belege unten. Neue Tests schließen
  die in E25–E37 beschriebenen Lücken. Der reguläre Mutationsdispatcher
  ist in dieser Sandbox infrastrukturell blockiert; das wird unten als
  OUT-OF-TERRITORY dokumentiert und nicht als grünes Gate ausgegeben.
  Die vollständige lokale Diagnose erreicht ohne Äquivalenzabzug 85,41 %;
  auch allein `Killed` ergibt 82,80 % bei im Nenner belassenen Timeouts.
  Umfang und Grenzen dieses Belegs stehen im Abschlussabschnitt.

- **E25 — neue Tests:** `test-fit-rework-inputs.R` prüft vollständige
  Fehlertexte und `conditionCall()`, genau einen gültigen numerischen
  Wert, beide Parsingwarnungen, logische/numerische/textuelle Binärwerte,
  Labelreihenfolge und ordinale Ordnung. Unbekannte binäre Labels werden
  entsprechend dem bestehenden Code verworfen; dieser Zweig hatte keine
  Warnung. Dafür wurde kein neues Verhalten zur Mutationstötung eingebaut.

- **E26 — neue Tests:** Ein-Stufen-Faktoren und ihre ausgeschlossenen
  Wechselwirkungen, Mindest-Itemzahl, `numerics = NULL` für nichtnumerische
  Fits, Reihenfolge und Attribute abgeleiteter Komponenten sowie alle
  Zählungen werden geprüft. Zellbesetzungen kommen unabhängig aus
  `table()`. Die bestehende clmm-Singularitätsanzeige ist ausdrücklich
  als Charakterisierung des bisherigen Ausgabe-Verhaltens markiert.

- **E27 — neue Tests:** `test-fit-rework-numerics.R` prüft alle
  Konditionierungsfelder gegen kleine rationale Rechnungen sowie den
  Überlaufzweig einschließlich `double.xmax`, dessen `log2` auf den
  nächsten Exponenten rundet. Fehlertexte und fehlender interner Call
  werden direkt geprüft.

- **E28 — neue Tests und eine tote Rechnung entfernt:** Vier balancierte
  Vorgabepläne mit/ohne Block und Wechselwirkungen werden gegen ein
  unabhängig aus `stats::aov` aufgebautes EMS-System geprüft, zusätzlich
  dessen Translationsinvarianz. Anwendbarkeitsgrenzen, null/negative
  Einwegkomponente, Restfreiheitsgrade und Grenzlösung gegen `var()` sind
  abgedeckt. Die Neuberechnung von `residual_v` nach `variance <- 0` war
  wirkungslos: der zurückgegebene Quotient ist in beiden Fällen null,
  die endgültige Restvarianz wird danach im REML-Kriterium bestimmt.
  Nur diese überflüssige Rechnung wurde entfernt.

- **E29 — neue Tests:** Die Informationsmatrix wird gegen die dichte
  projizierte Kovarianzformel gerechnet. Identifizierbarkeit einschließlich
  skalenabhängiger Ranggrenze, Null-Restnorm und benannte Matrixfehler
  werden getrennt geprüft. Es wurden keine Rechenregeln zugunsten von
  Mutanten vereinfacht, deren Gleichwertigkeit nur vermutet wird.

- **E30 — neue Tests:** Kleine quadratische Zielfunktionen liefern
  unabhängige exakte Newton-Richtungen, projizierte Scores, Korrekturen und
  Positivitätswerte. Freie/aktive Mengen, gekoppelte blockierte
  Richtungen und indefinite bzw. verschwindende Krümmung sind enthalten.

- **E31 — neue Tests:** Exakte Schritte und Zählungen prüfen Eintritt und
  Freigabe von Grenzen getrennt, Halbierungen, Rundung beim Grenztreffer,
  beide Konvergenznormen sowie Fehler beim Iterationslimit. Quartische
  Zielfunktionen erzwingen die Armijo-Grenze; ausdrücklich synthetische
  Funktionswertstörungen isolieren die Rundungsreserve. Ein stationäres
  Maximum darf nicht erfolgreich abschließen. Keine Störung wird als
  empirische Referenz ausgegeben.

- **E32 — neue Tests:** Startwerte werden mit direktem konditioniertem
  `lmer` verglichen; Gradient und Hesse-Matrix des finalen Modells mit
  Richardson-Differenzenquotienten seiner lme4-Devianzfunktion, auch an
  einer aktiven Nullgrenze. Modellaufruf, Aktualisierung, Abschlussfelder,
  aktive Komponenten und erneut ausgegebene Startwarnungen werden geprüft.

- **E33 — neue Tests:** Binäre und ordinale Varianzkomponenten werden mit
  `lme4::VarCorr` bzw. `ordinal::VarCorr` verglichen; Logit-Restvarianz mit
  der Formel pi²/3. Quelltyp, eindeutige letzte Residualzeile und die
  abgeleiteten Zwei-Stufen-Komponenten werden explizit geprüft.

- **E34 — neue Tests:** `test-grr-rework.R` prüft die Fit-Ausgabe mit
  synthetischen rationalen Komponenten, Formel, Zählungen, fehlenden
  Prozenten, latentem Link und beiden Hinweisen. Nur Wortlaut und Layout
  sind als eigene Ausgabe-Snapshots markiert; Zahlen werden unabhängig
  durch Formeln geprüft.

- **E35 — neue Tests:** Tabellenbezeichnungen, Typen, Nullfälle, Varianzen,
  Standardabweichungen, Prozentwerte und Zusammenfassung werden gegen
  Formeln geprüft; AIAG-Konstanten und Vorgabeschwellen kommen aus ANK-16.
  Die Fehlermeldung für ein fremdes Objekt wird vollständig geprüft.

- **E36 — neue Tests:** GRR-Druckausgabe einschließlich Genauigkeit,
  Schwellen, gewählter Basis, latenter Skala, Zählungen und Singularhinweis.
  Wortlaut/Layout sind gekennzeichnete Ausgabe-Charakterisierungen;
  zugrunde liegende Kennzahlen werden unabhängig geprüft.

- **E37 — neue Tests und redundantes Argument entfernt:** Zwei
  Konfidenzniveaus werden gegen `stats::quantile` der tatsächlichen
  Bootstrapreplikate geprüft. Klasse, Statistiknamen, Fehler, Fehlanzahl
  und Ausgabe sind abgedeckt. `na.rm = TRUE` im Quantilaufruf war nach
  dem vorhandenen `is.finite`-Filter redundant und wurde entfernt.

- **E38 — behoben:** NEWS, `?msa_fit`, `?msa_grr` und `?msa_plan` nennen die
  neuen Fehler/Validierungen und dass ein fehlgeschlagener Fit die Planung
  beendet. Rd-Dateien wurden mit roxygen2 in einer temporären Paketkopie
  erzeugt; nur die drei zugehörigen Rd-Dateien übernommen. NAMESPACE blieb
  bytegleich.

- **E39 — OUT-OF-TERRITORY, Betreiber/QA:** REVIEW nennt drei falsche
  ADR-Zuschreibungen in QA.md. Der Builder schreibt weder QA.md noch
  Reviewer-/Betreiberbefunde um. Grundlage der Korrekturen ist ADR-022,
  nicht ein nachträglich ergänztes angebliches Zitat. Verweis: REVIEW E39,
  QA-M1a-001/-003/-004.

- **E40 — OUT-OF-TERRITORY, [INFRA]:** Die durch ADR-019 erfolgte
  Betreiberreparatur und BL-78 werden zur Kenntnis genommen. Keine
  Änderung an Dispatcher, Timeout, Gateauswahl oder Laufzeitgrenze.
  Verweis: REVIEW E40; `gate-mutgate.log` nennt 1003 erzeugte Mutanten und
  den 86,1-s-Vorlauf, aber wegen QA keinen ausgeführten Mutanten.

- **E41 — OUT-OF-TERRITORY, [INFRA]:** Der aktuelle Gate-Lauf hat laut
  `gate-mutgate.log` vor Mutationen abgebrochen; ein vollständiger
  `reports/mutation/mutation.json` liegt nicht vor. Archivierung und
  Approval-Zuordnung bleiben Betreiber-/Reviewerarbeit (BL-79).
  Der Builder schreibt keinen Ersatzbericht in den Gatezustand und
  genehmigt keine Äquivalenz selbst.

- **E42 — OUT-OF-TERRITORY, Spec/Betreiber:** Der redaktionelle Fehler
  10¹² statt 10⁶ für SmLs04–SmLs06 bleibt dem Betreiber (BL-80).
  Die unveränderten Originaldaten, Anker und Abnahmetests wurden verwendet;
  kein Testwert wurde an den Spec-Tippfehler angepasst.

- **E43 — vertagt gemäß Reviewer/ADR-022:** Fehlende Gruppierungswerte
  bei ordinalen/binären Fits gehören zu M1b (BL-81). Die vorliegende
  Produktkorrektur prüft ausschließlich die numerischen Pfade. Weder
  behauptet der Builder einen nicht ausgeführten QA-Beleg noch einen
  fachlichen Abschluss dieses M1b-Punkts.

## Ausgeführte Prüfungen

Arbeitsbelege liegen unter `/tmp/llmsa-m1a-r2/`. Echte Ausgaben werden hier
festgehalten; sie sind keine vom Builder gesetzten Gate-Fakten.

### Regression und unveränderte QA

Vor der Produktkorrektur wurde die unveränderte QA mit dem vorhandenen
R-Testtreiber ausgeführt:

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT=normalizePath(".")); grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' tests/e2e tests/fuzz
```

`qa-before.log`, Exit 1:

```text
r-tests: fail — 10 Tests in tests/e2e, tests/fuzz; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
```

Derselbe Prüfweg nach der Produktkorrektur, `qa-after-first.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 10 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 0 übersprungen
```

Zusätzlich wurden die ersten neuen Regressionstests gegen die vorab
gesicherten Originaldateien `R/fit.R`, `R/grr.R` und
`reference_checks.R` in einer temporären Paketkopie ausgeführt.
`regression-before.log`, erwarteter Exit 1:

```text
[ FAIL 58 | WARN 0 | SKIP 0 | PASS 253 ]
Original implementation with new tests: 29 tests; 8 failed blocks; 3 errors; 0 skipped
```

Ein erster Ressourcenprüfer-Entwurf änderte die Meldung bei einer fehlenden
Ankerdatei; der vorhandene Unit-Test scheiterte deshalb. Die Prüfungsfolge
wurde korrigiert, sodass der konkrete Dateifehler erhalten bleibt.
Eine anfangs entweichende injizierte Matrix-Warnung wurde ebenfalls im
Produkt behoben. Bestehende Tests wurden dafür nicht verändert.

### Unit-, Abnahme- und Paketprüfungen

Der vollständige Unit-/QA-Prüfweg wurde ausgeführt:

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT=normalizePath(".")); grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' tests/testthat tests/e2e tests/fuzz
```

`unit-qa-current.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2403 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 182 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

Der vorhandene Skip ist der Negativtest für fehlendes `ellmer`, das hier
installiert ist. Weitere Mutationsregressionen wurden danach ergänzt und
werden im Abschlussbeleg separat ausgewiesen.

M1a-Abnahme mit `REPO_ROOT`, `pdf(NULL)` und
`testthat::test_dir("tests/acceptance", filter="^m1a-", load_package="source")`:
`acceptance-first.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped; 35.68 s
```

Die M2-Auswertung wurde wegen der Verwendung des geänderten numerischen
Kerns zusätzlich mit `filter="^m2-6-"` ausgeführt.
`acceptance-m2-current.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 374 ]
M2 evaluation: 10 tests; 0 failed blocks; 0 errors; 0 skipped; 424.42 s
```

Paketbau und `R CMD check --as-cran --no-manual` wurden in zwei temporären
Paketkopien ausgeführt, einmal ohne REPO_ROOT (öffentlich) und einmal mit
REPO_ROOT (Originalanker/geschützte lokale Daten). Die Paketkopien enthalten
die vorgesehenen CRAN-Pfade, keine Harness-Dateien oder Geheimnisse.
`package-check-public/{build,check}.log` und
`package-check-full/{build,check}.log`, jeweils Exit 0:

```text
* checking package vignettes ... OK
* DONE
Status: 1 NOTE
```

Die enthaltene Testsuite meldet öffentlich `PASS 2303, SKIP 8`, mit
Originalankern `PASS 2304, SKIP 7`, jeweils ohne Fehler/Warnungen. Vorhandene
Skips: fünf nicht mitgelieferte API-Aufzeichnungen, ein CRAN-Reporttest,
der ellmer-Negativtest sowie nur öffentlich der Originalankervergleich.
Es wurden keine Skips hinzugefügt.

### OUT-OF-TERRITORY: lokale Infrastruktur

- **M1a-R2-INFRA-MUT-DISPATCH:** `Rscript --vanilla -e 'mirai::daemons(1L)'`
  scheitert in dieser Sandbox. `mirai-probe.log`, Exit 1:

  ```text
  Error in .dispatcher_start(url, urld, tls_cfg, serial, envir[["stream"]],  :
    16 | Permission denied
  Calls: <Anonymous> -> launch_dispatcher -> .dispatcher_start
  Execution halted
  ```

  Das ist keine fachliche Mutation und keine Produktreparatur. Die
  Sandbox, der Dispatcher und die Gates wurden nicht geändert. Als
  zusätzliche Diagnose wurden dieselben von `muttest` erzeugten Mutanten
  in unabhängigen lokalen R-Prozessen gegen eine benannte Unit-Teilmenge
  geprüft. Diese Ergebnisse entscheiden nicht über das Gate; der reguläre
  Lauf bleibt beim Orchestrator.

- **M1a-R2-INFRA-CLOCK:** Beide unveränderten Zeitprüfungen des Paketchecks
  melden unter „checking for future file timestamps“:

  ```text
  Unable to verify current time.  To disable remote verification,
  set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
  ```

  Beleg: beide `llmsa.Rcheck/00check.log`, Zeilen 27–29. Der Builder hat
  diese Prüfung nicht deaktiviert. Keine Produktänderung für den NOTE.

## Abschlussbelege vom 30.10.2026

Die M1a-Abnahme wurde nach Entfernen der überflüssigen Rechnung erneut
ausgeführt, unveränderte Tests und derselbe oben beschriebene Prüfweg.
`acceptance-final.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped; 65.65 s
```

Der vollständige Unit-/QA-Prüfweg lief nach den zusätzlichen numerischen
Grenztests nochmals. `unit-qa-final.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2475 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 183 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed: 143.56 s
```

Danach wurden noch die Datenmaske für den Ausdruck in `weights` und
sämtliche sechs optionalen GRR-Zeilenbezeichnungen ergänzt. Alle neuen
Regressionstests wurden daraufhin gemeinsam erneut ausgeführt:

```r
testthat::test_local(
  filter = "^(fit-rework-.*|grr-rework|validation-rework)$",
  reporter = testthat::ProgressReporter$new(show_praise = FALSE),
  stop_on_failure = FALSE
)
```

`rework-final.log`, Exit 0, mit `pdf(NULL)` und Auswertung des echten
Testresultats für den Prozess-Exit:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 479 ]
Final rework regression: 33 tests; 0 failed blocks; 0 errors; 0 skipped; 14.12 s
```

Bei der Erweiterung scheiterten vorübergehend zwei neue Erwartungen:
JSON lieferte Integer statt Double für die Vorgabeschwellen; die Referenz
wird jetzt explizit numerisch typisiert. Ein zweiter Test verglich eine
algebraisch gleichwertige, aber anders gerundete Konditionierung mit einer
Engine-Toleranz. Die Orakelrechnung verwendet nun die dokumentierte
Reihenfolge der Gleitkommaoperationen. Kein Referenzwert und keine
Toleranz wurde geändert. Ein bereits gestarteter weiterer Paketbau wurde
für diese Testkorrektur angehalten und danach vollständig neu gestartet.

Die beiden Paketchecks wurden ebenfalls mit dem abschließenden Produktcode
wiederholt (Paketkopien vor den letzten zwei rein testseitigen Ergänzungen):

```bash
env -u REPO_ROOT R CMD build --no-manual src
env -u REPO_ROOT _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Für den vollständigen Modus dieselben Befehle mit
`REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa` statt `env -u REPO_ROOT`.
Die lokale Incoming-Einstellung entspricht dem vorhandenen `r-check.sh`;
die Systemzeitprüfung wurde nicht deaktiviert. Beide Prozesse Exit 0,
`package-check-{public,full}-final/{build,check}.log`:

```text
* checking package vignettes ... OK
* DONE
Status: 1 NOTE
```

Enthaltene Tests: öffentlich `[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2400 ]`,
mit Originalankern `[ FAIL 0 | WARN 0 | SKIP 7 | PASS 2401 ]`. Gründe der
bestehenden Skips und der einzige Zeitprüfungs-NOTE wie oben.

### Lokale Mutationsdiagnose, kein Gate-Ersatz

Wegen des belegten Dispatcherfehlers wurde die unveränderte installierte
`muttest`-Generation verwendet, mit denselben neun Mutatorgruppen wie im
Betreiber-Treiber: arithmetische, Vergleichs-, logische und boolesche
Operatoren, Bedingungen, Zahlen, NA, Strings und Indizes. Keine Gruppe
wurde abgeschaltet. Scope: vollständig `R/fit.R`, `R/grr.R`.

Die temporäre Paketkopie enthält Produktquellen, Daten, installierbare
Ressourcen, Unit-Tests und vorhandene API-Fixtures. Die Diagnose testet
die bewusst benannte Unit-Teilmenge
`^(fit-(numeric|rework-.*)|grr-(numeric|rework))$`, anfangs 41 Tests.
Es sind **keine vollständigen Gate-Testläufe je Mutant**. Je Mutant laufen
eigene R-Prozesse, höchstens 14 gleichzeitig; der lokale Timeout beträgt
120 s. Keine Sandbox-Einstellung oder Gate-Datei wurde geändert.

Ausgeführt:

```bash
python3 /tmp/llmsa-m1a-r2/run-mutations.py
```

Die eingefrorene erste Diagnose verwendet den Produktstand direkt vor
Entfernung der einen überflüssigen Restvarianzrechnung; `R/grr.R` ist
bytegleich mit dem Abschlussstand. `mutations.log`, Exit 0:

```text
Diagnostic only: 1105 muttest mutants, 14 independent R processes; targeted unit suite 41 tests, timeout 120s.
Completed 1105/1105; {'Killed': 823, 'Survived': 145, 'RuntimeError': 111, 'Timeout': 26}; elapsed 1245.6s
Finished diagnostic mutation run in 1245.6s; {'Killed': 823, 'Survived': 145, 'RuntimeError': 111, 'Timeout': 26}
```

Ohne irgendeinen Äquivalenzabzug ergibt die Statusformel
`(Killed + Timeout) / (Killed + Timeout + Survived)` **85,41 %**.
Werden Timeouts ausschließlich im Nenner belassen, sind es **82,80 %**.
Die 111 RuntimeErrors werden wie im Mutationsverfahren gesondert
ausgewiesen, nicht zu Killed umbenannt. Rohbelege und tatsächlich
ausgeführte Testresultate liegen in `mutation-results.json`,
`mutation-results.jsonl` und `mutation-results/{NNNN.log,NNNN.json,NNNN.rds}`.

Für den Abschlusscode wurde der Plan frisch erzeugt:

```bash
Rscript --vanilla /tmp/llmsa-m1a-r2/generate-final-mutations.R
python3 /tmp/llmsa-m1a-r2/prepare-recheck.py
```

Echter Output:

```text
Fresh muttest plan for the final product sources: 1097 mutants
Initial completed diagnosis: {'Survived': 145, 'Killed': 823, 'Timeout': 26, 'RuntimeError': 111}
Mutants removed with the dead residual-variance calculation: [38, 39, 105, 144, 499, 500, 635, 636]
Verified final source mappings: 1097
Survivors to recheck with the final test subset: 140
```

Die Zuordnung prüft nicht nur Zeilennummern: Nach Entfernen genau der
überflüssigen Zeile wurden alle 1097 generierten Mutantenquellen mit den
frisch generierten Quellen verglichen. Fünf der 145 Überlebenden gehörten
zu der entfernten Rechnung. Der aktuelle unmutierte Vorlauf der erweiterten
Teilmenge (`mutation-final-baseline-v2.log`, Exit 0) lautet:

```text
Mutation unit subset: 45 tests; 0 failed expectations; 0 errors; 0 skipped; 575 passed; 9.52 s
```

Die übrigen 140 Überlebenden wurden mit genau diesem Teststand erneut
ausgeführt:

```bash
python3 /tmp/llmsa-m1a-r2/run-mutation-recheck.py
```

`mutation-recheck.log`, Exit 0:

```text
Diagnostic survivor recheck only: 140 muttest mutants, 14 independent R processes; targeted unit suite 45 tests, timeout 120s.
Completed 140/140; {'Survived': 70, 'Killed': 61, 'RuntimeError': 9}; elapsed 120.7s
Finished diagnostic mutation run in 120.7s; {'Survived': 70, 'Killed': 61, 'RuntimeError': 9}
```

Damit sind 61 zuvor überlebende Mutanten zusätzlich durch ausgeführte
Fehlererwartungen getötet. Neun erzeugen nun RuntimeErrors und werden
ausdrücklich nicht als Killed bezeichnet. Die 70 übrigen Überlebenden
bleiben im Rohbericht; zehn davon sind Gegenstand der acht untenstehenden
Äquivalenzanträge. Der Nachlauf wird nicht zu einem angeblichen
vollständigen Gate-Lauf zusammengerechnet. Einzelbelege stehen unter
`mutation-recheck-results/`, der vollständige Nachlauf in
`mutation-recheck-results.json`.

### Beantragte Äquivalenzen

`MUT-EQUIV.json` enthält acht Claims mit den Namen und Zeilen des frisch
generierten Abschlussplans. Es gibt **keine** Builder-Genehmigung und
keine `MUT-EQUIV-APPROVED.json`. Der gemeinsame Schlüssel einer Zeile
umfasst bei `aggregate` drei Mutanten; die Begründung gilt ausdrücklich
für alle drei. Die acht Claims betreffen damit zehn erzeugte Mutanten.

Ausgeführt:

```bash
Rscript --vanilla /tmp/llmsa-m1a-r2/equivalence-proofs.R
```

`equivalence-proofs.log`, Exit 0:

```text
PROVED R/fit.R:222 + → - (3 generated mutants)
PROVED R/fit.R:102 FALSE → TRUE (1 generated mutants)
PROVED R/fit.R:341 <n> + 1 → <n> + 1 (1 generated mutants)
PROVED R/fit.R:341 <n> - 1 → <n> - 1 (1 generated mutants)
PROVED R/fit.R:442 TRUE → FALSE (1 generated mutants)
PROVED R/fit.R:444 TRUE → FALSE (1 generated mutants)
PROVED R/fit.R:450 TRUE → FALSE (1 generated mutants)
PROVED R/grr.R:94 > → >= (1 generated mutants)
Equivalence claims prepared: 8; no approvals written
```

Das sind Builder-Begründungen mit ausgeführten exakten Vergleichen und
Argumenten zum gültigen Eingabebereich; die formale Einzelfreigabe bleibt
beim Reviewer. Weder diese Claims noch die lokalen Diagnoseergebnisse
wurden auf Gate-Berichte oder Baselines angewendet.

### Integrität und Vollständigkeit

Die vor Beginn gesicherte SHA-256-Inventur wurde ohne Git verglichen:

```bash
python3 /tmp/llmsa-m1a-r2/check-integrity.py
```

`integrity-final.log`, Exit 0:

```text
Baseline inventory: 255 files
Existing files changed: 10 (all on the explicit Builder allowlist)
Unchanged inventory files: 245
Existing tests changed: 0
Missing existing files: 0
New files in inventoried directories: 7 (five test files, two assigned handoffs)
Unchanged NAMESPACE SHA-256: a0e54e3f20c8ea478e684af3c38e124d04854ef684a2b0d0a79b333a4032385f
Valid equivalence claims: 8 ; matching final-source mutants: 10
Approval file exists: False
```

Die automatische Zuordnung der REVIEW-IDs zu den Antworten ergibt:

```text
Missing responses: []
Point-by-point coverage: 26 of 26
```

Kein Builder-Verdict, kein Phasen-Commit, keine Änderung am Gatezustand.
Der Orchestrator übernimmt Territoriumsprüfung, reguläre Gates und Commit;
der Reviewer entscheidet über die Claims.
