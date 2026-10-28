# M1a — PLAN-UPDATE, Runde 2

Rolle: Builder · Phase: `20-plan` · Runde: 2 · Stand: 28.10.2026.
Grundlage: `PLAN.md` und `PLAN-REVIEW.md`, jeweils Runde 1.

## Ziel

K-M1a-1 bis K-M1a-7 werden gegen die bestehenden Abnahmetests und Anker
umgesetzt. Dieses Update ersetzt die unten bezeichneten Teile des Plans
aus Runde 1; insbesondere entfallen die alleinige Präzisierung eines
ableitungsfreien Optimierers als Invarianzlösung und der Schreibauftrag
für die `README.md` an der Repo-Wurzel. Alle zwölf Einwände werden
akzeptiert. Die numerische Eignung des neuen Verfahrens muss BUILD erst
durch Messungen belegen; dieses Dokument behauptet keine erfüllte Abnahme.

Gelesen wurden `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, `CRITERIA.json`, `PLAN.md`,
`PLAN-REVIEW.md`, das Verdict der Runde 1, sämtliche sieben
M1a-Abnahmedateien mit `setup-acceptance.R` und `setup-m1a.R`,
`docs/01-fachspezifikation.md`, der M1a-Abschnitt von
`docs/02-statistikkern.md`, Formelsammlung §1–§3 und ADR-012/016/017.
Ergänzend: die relevanten Ankerfelder, Fit-/GRR-Code, die Aufrufer
`msa_plan()`, `msa_boot()` und `acmg_fit()` sowie ihre Bestandstests.
`orchestrator/LESSONS.md` enthält keine Lehren. Eine
`orchestrator/handoff/M1a/ARBITER.md` liegt nicht vor.

ADR-017 Nr. 1–5 erfüllt die in Runde 1 noch ausstehenden
Reviewer-Auslegungen zu ACC-3, ACC-4, ACC-9, ACC-10 und ACC-18.
Nr. 6 und Nr. 7 werden ebenfalls übernommen. Die übrigen Antworten zu
ACC-1 bis ACC-18 aus PLAN.md gelten mit den folgenden Präzisierungen
weiter. Es wird kein neuer Spec-Widerspruch behauptet und kein weiteres
Reviewer-ADR für bereits entschiedene Punkte verlangt. Eigene technische
ADRs entstehen erst in BUILD im dort erlaubten Territorium.

### Antworten auf die Einwand-IDs

- [E1] akzeptiert: Der Vorgabepfad erhält eine geschlossene EMS-Lösung
  für strukturell geeignete balancierte Modelle und einen analytischen
  REML-Abschluss mit aktiven Nullgrenzen für die übrigen Modelle.
  Konditionierung bleibt eine Vorbereitung, nicht der Genauigkeitsbeleg.
  Die Festlegung auf enge bobyqa-Steuerung entfällt. Vor Ressourcen- und
  Vignettenarbeit muss der unten definierte Go/No-Go-Versuch
  `ANK-TOL.invariance` und Modellkonsistenz nachweisen. Für die sparse
  Rechnung wird `Matrix` als direkter Import mit numerischem Builder-ADR
  geplant; keine stillschweigende Nutzung einer transitiven Abhängigkeit.
  Ref: K-M1a-6, ACC-6, ADR-016 E6, BL-49, BL-72.
- [E2] akzeptiert: `README.md` an der Repo-Wurzel wird aus der
  BUILD-Dateiliste gestrichen. Die Ausführungsanleitung liegt unter
  `inst/validation/numeric/README.md`, ergänzt durch Vignette, Rd und
  NEWS. Eine Erweiterung der Territoriumsregeln ist nicht beantragt.
  Ref: Gate territory, PLAN-REVIEW E2.
- [E3] akzeptiert: Das endgültige `merMod` wird mit `lFormula()`,
  `mkLmerDevfun()` und `mkMerMod()` auf Originalskala, mit ursprünglichen
  Beschriftungen und in Eingabereihenfolge am endgültigen Theta gebaut.
  `vc` kommt ausschließlich aus `VarCorr(model)`. Eine geschlossene
  Lösung ist der Endwert, kein erneut zu optimierender Startwert.
  Abschlussdiagnostik, lme4-kompatible Refit-Steuerung und tatsächliches
  Abschlussverfahren werden nachvollziehbar gespeichert und geprüft.
  Ref: K-M1a-4, K-M1c-1 als Folgeabhängigkeit, PLAN-REVIEW E3.
- [E4] akzeptiert: Sobald ein lme4-Argument in `...` übergeben wird,
  läuft nach der gemeinsamen Eingabeaufbereitung ausschließlich
  `lme4::lmer(form, data = dat, REML = TRUE, ...)` auf den Originaldaten.
  Das gilt auch für explizites `control = lmerControl()` beziehungsweise
  `control = NULL`. Konditionierung, Umordnung und Nachpolitur greifen
  dort nicht. `weights`, `offset`, `subset`, `start` und weitere
  lme4-Argumente behalten den bisherigen Durchreichweg. Der Unterschied
  zum Vorgabepfad wird in `?msa_fit` dokumentiert und direkt gegen lme4
  getestet. Ref: K-M1a-1, K-M1a-6, ACC-11, ACC-13.
- [E5] akzeptiert: `fit$data` behält `item`, `prompt`, `model`, `block`
  und `y` mit Originalbeschriftungen, Originalwerten und Reihenfolge nach
  Entfernen fehlender beziehungsweise nicht parsbarer Antworten.
  Modellrahmen, `ranef()`, `coef()` und Vorhersagen verwenden dieselben
  Stufennamen. `formula`, `levels`, `n`, `interactions` und `derived`
  behalten ihre Bedeutung. Eingabezeilenabbildung und numerische
  Diagnostik stehen ausschließlich additiv in `numerics`.
  Ref: docs/01 §4, PLAN-REVIEW E5.
- [E6] akzeptiert: Numerische und ganzzahlige Antworten werden ohne
  Zeichenkettenrundlauf übernommen; nur Zeichen-/Faktoreingaben werden
  geparst. Die Warnung mit Anzahl nicht lesbarer Antworten bleibt.
  Ein Unit-Test prüft die unveränderten Doubles im Ergebnis und
  Modellrahmen, unter anderem bei `1 / 3`, `0.1 + 0.2` und `exp(1)`.
  Ref: docs/01 §2 Nr. 4, `R/fit.R`, PLAN-REVIEW E6.
- [E7] akzeptiert: Konstante Antworten, verschwindende Reststreuung und
  sehr kleine, aber darstellbare Streuung erhalten die unten festgelegten
  getrennten Verhaltensregeln. Kleine Streuung wird nicht pauschal auf
  null gesetzt. Regressionen prüfen den echten numerischen AP1-Rückfall
  bei konstanten Scores und den Abbruch von `msa_plan()` bei einem
  degenerierten Szenario. NEWS nennt die Änderung. Produktänderungen an
  `R/acmg.R` oder `R/plan.R` sind dafür nicht vorgesehen.
  Ref: K-M1a-6, docs/01 §2 Nr. 4, PLAN-REVIEW E7.
- [E8] akzeptiert: BUILD misst unveränderten v0.1.0-Kern gegen neuen Kern
  auf `ic50_demo`, `SmLs03` mit 18.009 Zeilen sowie kleinen festgelegten
  `msa_plan()`- und `msa_boot()`-Läufen. Steuerung, Seed, Zeiten und
  Verhältnis werden in PROGRESS und im numerischen ADR dokumentiert.
  Standardmodelle tragen für Refits ausdrücklich die normale
  `nloptwrap`-Steuerung ohne erhöhte Iterationsbudgets; der analytische
  Erstfit wird separat ausgewiesen. Explizite Aufrufersteuerung bleibt
  erhalten. Ref: BL-12, BL-13, PLAN-REVIEW E8.
- [E9] akzeptiert: Neue Unit-Tests verwenden kleine freie oder klar
  synthetische Eingaben. Sie knitten nicht die ganze Vignette und rufen
  nicht `remlVCA` auf `ic50_demo` auf. Kontexte, Ressourcenleser und
  Tabellenhelfer werden isoliert geprüft. Toleranzen stammen aus
  installierbaren Ressourcen und werden mit `[[ ]]` samt Prüfung auf
  `NULL` gelesen. Standard-lme4-Vergleiche folgen ADR-012; die feste
  M1a-Invarianzprüfung bleibt unverändert. Ref: docs/01 §2 Nr. 8, BL-72.
- [E10] akzeptiert: Gewählt wird der öffentliche **Rechenmodus** nach
  ADR-017 Nr. 7.1–7.6. Die Driftwache läuft im Test-Gate, beide Modi geben
  ausschließlich AIAG-Kennzahlen aus, und die Literalprüfung umfasst
  auch eingelesene beziehungsweise ausgeführte Hilfsdateien. Vollmodus
  und öffentlicher Bau werden getrennt belegt; das lint-Gate mit
  `REPO_ROOT` belegt allein den Vollmodus. Der reduzierte Modus nach
  Nr. 7.7 wird nicht gewählt. Ref: K-M1a-7, ACC-14, ADR-017 Nr. 7.
- [E11] akzeptiert: ADR-017 Nr. 6 gilt für `grr_stats()`, `msa_grr()`
  und beide Druckmethoden. Bei TV null sind Prozentwerte, ICC und ndc
  `NA_real_`, das Verdikt `undetermined`; bei GRR null und positiver PV
  ist ndc `Inf`; bei PV null und positiver GRR ist ndc eins.
  Alle drei Fälle werden einschließlich Druckausgabe geprüft.
  Bootstrap-Wiederholungen mit NA bleiben in `n_failed` enthalten.
  Ref: K-M1a-5, K-M1a-6, ADR-017 Nr. 6.
- [E12] akzeptiert: Als nonblocking `[INFRA]` an den Betreiber
  übergeben. Die Abschätzung des Reviewers von rund neun Stunden ist
  eine Hochrechnung, kein gemessener M1a-Gate-Lauf. Gate-Auswahl,
  `MUT_TEST_DIRS`, Workerzahl und Zeitgrenzen bleiben Betreiberaufgabe.
  Der Builder hält den Kern im Mutations-Scope und genehmigt keine
  Äquivalenz-Claims selbst. Der angekündigte Backlog-Nachtrag bleibt
  beim Reviewer. Ref: Gate mutgate, BL-13, PLAN-REVIEW E12.

## Dateien

**Diese PLAN-Phase schreibt nur diese `PLAN-UPDATE.md`.** Die folgende
Liste ersetzt die BUILD-Dateiliste aus Runde 1.

| Pfad in BUILD | Zweck |
| --- | --- |
| `R/fit.R` | Präzisionserhaltende Eingabe, numerischer Vorgabepfad einschließlich aller Kernhelfer, direkter lme4-Pfad mit `...`, Modellbau und `print.msa_fit`. |
| `R/grr.R` | ndc-Untergrenze, TV-null-Berechnung, NA-/Inf-Ausgabe; gemeinsame Kennzahlberechnung und bestehende Bootstrap-Fehlzählung erhalten. |
| `tests/testthat/test-fit-numeric.R` | Kleine Verhaltens-, Modellkonsistenz-, Ableitungs-, Invarianz-, Durchreich- und Grenzfallprüfungen. |
| `tests/testthat/test-grr-numeric.R` | Unabhängige Algebra auf konstruierten Komponenten, alle Nullfälle mit Druckausgabe sowie NA-Zählung im Bootstrap-Pfad. |
| `tests/testthat/test-acmg-evaluate.R` | Additiver Regressionstest: ordinaler Fehler, echte numerische Berechnung konstanter Scores, benannter AP1-Abbruch. Bestehende Erwartungen bleiben. |
| `tests/testthat/helper-validation-numeric.R`, `tests/testthat/test-validation-numeric.R` | Striktes Toleranzlesen, Driftwache, Literalprüfung, kleine Tests der Kontextwahl, Datenleser und Tabellenaufbereitung. |
| `data-raw/make_validation_numeric.R` | Reproduzierbarer Offline-Erzeuger mit optionalem `--out`; Quellhashes und Schema prüfen, NIST-Tokens und ganze Ankerdateien erhalten. |
| `inst/extdata/nist-strd-anova_2026-10-22/` | Freie numerische NIST-Tabellen, `SHA256SUMS`, englische `QUELLE.txt`; Kompression und Größenprüfung nach ANK-TOL.data_size, mit Golden-ADR. |
| `inst/validation/numeric/anchors/`, `inst/validation/numeric/SOURCES.json` | Byte-identische Kopien von ANK-10/13/14/16 und ANK-TOL mit Originalpfaden und Original-/Kopienhashes; ausschließlich erzeugt. |
| `inst/validation/numeric/reference_checks.R`, `inst/validation/numeric/README.md` | Laufzeitrechnungen und englische Reproduktionsanleitung; keine Produkt-Kernlogik und keine eingefrorenen Orakelausgaben. |
| `vignettes/validation.Rmd` | Vorgeschriebener englischer Abschnitt, Referenztabellen und LRE-Bericht in beiden vereinbarten Kontexten. |
| `DESCRIPTION` | VCA/SixSigma als Suggests; Matrix als begründeter direkter Import nach numerischem ADR. Kein Wechsel der Mindest-R-Version. |
| `man/msa_fit.Rd`, `man/msa_grr.Rd`, bei Bedarf `man/msa_boot.Rd`, `NEWS.md` | Verfahren, Durchreichweg, Nullfälle, Refit-Steuerung und Ressourcen dokumentieren. Roxygen in temporärer Paketkopie. |
| `NAMESPACE` | Nur eine gegebenenfalls von roxygen erforderliche Importregistrierung; Exporte und öffentliche Argumentlisten bleiben. Matrix-Aufrufe vorzugsweise qualifiziert. |
| Zwei neue Builder-ADRs unter `docs/decisions/` | Numerik einschließlich Matrix-Import, Konvergenz-/Refit-Vertrag und Messungen; Validierungsressourcen einschließlich Golden-Begründung. Freie Nummern erst in BUILD vergeben. |
| `PROGRESS.md`, zugewiesene M1a-Builder-Handoffs | M2-Abschluss anhand der dann gelesenen Fakten, echte BUILD-Kommandos/Outputs, Laufzeiten, Abweichungen und Übergabe. |

`README.md` an der Wurzel ist ausdrücklich kein Schreibziel. Ebenso
bleiben Abnahmetests, Originalanker, Specs, BACKLOG, Fixtures,
`tests/simulation/`, Toolchain, Gate-Auswahl und Orchestratorzustand bei
ihren Eigentümern. Kernhelfer werden nicht aus `R/fit.R` oder `R/grr.R`
in Dokumentationsressourcen ausgelagert. Neue Abhängigkeiten installiert
ausschließlich das deps-Gate; Matrix ist in der gelesenen Umgebung
bereits vorhanden, wird aber trotzdem als direkter Import begründet.

## Schnittstellen

### Öffentliche Verträge und Durchreichweg

Die Signaturen aus PLAN.md bleiben unverändert, ebenso die übrigen
Schnittstellen aus ANK-02. Es gibt keine neuen Exporte, keine geänderten
Vorgabewerte und keine Snapshot-Änderung. Die Standardwahl der
Interaktionen und die Modellterme bleiben: zufällige Haupteffekte mit
mehr als einer Stufe sowie gegebenenfalls `item:prompt`, `item:model`
und `prompt:model`; keine Block- oder Dreifach-Wechselwirkungen.

Nur `type = "numeric"` ohne übergebene lme4-Zusatzargumente nutzt den
neuen numerischen Pfad. Der explizite Pfad aus E4 bleibt die direkte
Engine-Rechnung, einschließlich ihrer Warnungen und ihres
Konvergenzcodes. Insbesondere bleiben K-M1a-1 mit bobyqa aus dem Anker
und der absichtlich abgebrochene Fit aus K-M1a-6 echte lme4-Prüfungen.
Ordinale/binäre Schätzverfahren werden in M1a nicht geändert.

`fit$data` und der Modellrahmen behalten die Bedeutung aus E5. Die
Zuordnung analysierter Zeilen zu `runs` steht additiv in `numerics`.
`n$observations` zählt gültige Antworten, `n$reps_per_cell` nur
beobachtete Zellen. Ein fehlender beziehungsweise nicht parsbarer Wert
wird gezählt und entfernt, niemals ersetzt. Ein nach der Konvertierung
leerer Eingang oder eine unendliche numerische Antwort endet benannt.

### Numerisches Verfahren — ersetzt PLAN.md, numerische Punkte 1–6

1. **Antwort konditionieren.** Numerische Werte werden ohne
   Zeichenkettenkonvertierung übernommen. Eine interne Antwort wird
   zuerst um einen beobachteten Offset verschoben und dann durch einen
   robust berechneten positiven Maßstab geteilt. Summen und Normen
   werden auf den kleinen Differenzen gebildet; bei drohendem Überlauf
   erfolgt zuvor eine Binärskalierung. Es gibt keinen absoluten
   Grenzwert, der kleine positive Streuung zu null erklärt. Die
   ursprünglichen Antworten und Labels bleiben für den Modellbau
   erhalten. Bitgleiche kanonische Umcodierung ist keine Voraussetzung
   mehr: stabile Summation und der analytische Abschluss müssen die
   verlangte Invarianz innerhalb der Ankertoleranz erreichen.
2. **Geschlossener balancierter Fall.** Vollständige Kreuzung, gleiche
   Zahl gültiger Beobachtungen je Zelle, positive Restfreiheitsgrade und
   die tatsächlich enthaltenen Modellterme werden strukturell geprüft.
   Orthogonale Effektsummen werden aus zentrierten Randmitteln und
   Residuen berechnet. Die EMS-Gleichungen aus Formelsammlung §2 werden
   für genau diese Terme gelöst; ausgelassene Terme bleiben mit dem Rest
   gepoolt. Sind alle Schätzer nichtnegativ und die Restvarianz positiv,
   ist diese Lösung der endgültige REML-Schätzer, auch für mehrere
   gekreuzte Faktoren mit Block und Interaktionen. Die Rechnung wird
   eigenständig aus der Formel implementiert, nicht aus dem
   Acceptance-Helfer kopiert. Bei einem negativen Schätzer geht das
   gesamte Modell an den restringierten allgemeinen Pfad. Der
   Einweg-Randfall darf direkt Item null und Rest `SST / (N - 1)` lösen.
   Kein Abschneiden mit unverändert übernommenen übrigen Komponenten.
3. **Allgemeiner REML-Abschluss.** Für unbalancierte Pläne und aktive
   Nullgrenzen wird das konditionierte REML-Kriterium mit analytischem
   Score und analytischer Krümmung gelöst. Ein regulärer lme4-Lauf liefert
   höchstens den Startwert. Ein kleiner Unterschied zweier Zielfunktionswerte
   ist kein Konvergenzkriterium. Das Verfahren gilt für alle vom
   numerischen Vorgabemodell erzeugten Zufalls-Intercept-Terme, unabhängig
   von Datensatznamen, Quellen, Zeilenzahlen, Seeds oder Ankerwerten.

   Konkret werden Varianzverhältnisse `lambda_j = variance_j / variance_e`
   statt allein deren Quadratwurzeln optimiert. Mit der konditionierten
   Antwort `z`, dem Intercept-Design `X`, Gruppierungsmatrizen `Z_j`,
   `K_j = Z_j Z_j'`, `H = I + sum(lambda_j K_j)` und
   `P = H^-1 - H^-1 X (X' H^-1 X)^-1 X' H^-1` ist das profilierte
   Kriterium bis auf Konstanten

   ```text
   nu = N - rank(X), Q = z' P z
   F = log|H| + log|X' H^-1 X| + nu * log(Q / nu)
   dF/dlambda_j = tr(P K_j) - nu * (z' P K_j P z) / Q
   variance_e = Q / nu
   ```

   Die Ableitungen entstehen durch Differenzieren dieses Kriteriums
   (profilierte REML-Grundlage: Bates et al. 2015, §3.4, Gl. 39–41,
   lokaler Textspiegel, PDF-Seite 17). An einer Nullgrenze muss die
   einseitige Ableitung nichtnegativ sein; ein negatives Vorzeichen
   nimmt die Komponente wieder in die freie Menge auf. So wird die
   künstliche Stationarität von Theta null vermieden. Freie Komponenten
   werden mit gedämpften Newton-Schritten und Schrittweitenprüfung
   aktualisiert; alle anderen Komponenten werden dabei neu geschätzt.
   Bei ungeeigneter Krümmung wird die Schrittrichtung abgesichert, ohne
   dem statistischen Modell eine zusätzliche Varianz hinzuzufügen.

   Der Abschluss verlangt zugleich einen kleinen skalierten projizierten
   Score, einen kleinen aus der Krümmung bestimmten Korrekturschritt und
   gültige Randbedingungen. Die anfängliche numerische Zielgröße dafür
   ist `sqrt(.Machine$double.eps)` auf dimensionslosen, nach
   Parametermaßstab und Freiheitsgraden normierten Größen. Eine flache
   Richtung wird auch über ihren Korrekturschritt geprüft. Änderungen
   dieser internen Steuerung brauchen Messbegründung im numerischen ADR;
   sie ändern keine Testtoleranz. Rundung auf erwartete Zahlen,
   Klassifikationsgrenzen oder Ankerwerte ist ausgeschlossen.

   Die Formeln bezeichnen Operatoren, keine anzulegenden dichten
   `N x N`-Matrizen. Sparse Gruppierungsmatrizen, Cholesky-Lösungen im
   Zufallseffektraum und blockweise Produkte liefern Score und Krümmung;
   dieselbe Faktorisierung wird je Iteration wiederverwendet. Dafür dient
   der deklarierte Matrix-Import. Kleine unabhängige Dichtrechnungen
   sind ausschließlich Testorakel. Nichtidentifizierbare Systeme,
   unzulässige Skalierung oder ein nicht erreichter Abschluss werden
   mit englischer Diagnose gemeldet, nicht als erfolgreiche Optima
   ausgegeben.
4. **Konsistentes Modell am Endwert.** Aus den endgültigen Verhältnissen
   entsteht `theta_j = sqrt(lambda_j)` in der Termreihenfolge von lme4.
   `lFormula()` und `mkLmerDevfun()` werden für die Originaldaten
   aufgebaut. Die Devianzfunktion wird am endgültigen Theta ausgewertet,
   danach erzeugt `mkMerMod()` das Modell; keine erneute freie Optimierung
   darf den geschlossenen beziehungsweise analytischen Endwert verändern.
   `vc_from_model()` liest daraus `VarCorr()`. `sigma()`, Modellrahmen,
   Fitted Values, Residuen und Vorhersagen müssen dazu passen.

   `checkConv()` erhält die Abschlussableitungen in der von lme4
   erwarteten Theta-Parametrisierung; die zusätzliche Prüfung an der
   Nullgrenze erfolgt auf der Varianzverhältnisskala. Die gespeicherten
   Codes und Warnungen beschreiben den Lauf, der den Endwert bestimmt
   hat. Startfit, geschlossene Lösung beziehungsweise Score-Abschluss
   werden in `numerics` und den Optimierungsinformationen unterschieden.
   Ein erfolgreicher Startfit darf keinen fehlgeschlagenen Abschluss
   verdecken; lme4-Warnungen werden nicht still unterdrückt.

### Wiederanpassung und Diagnostik

Das Standardmodell erhält einen von lme4 erkannten Wiederanpassungshaken
`nloptwrap` mit normalen `lmerControl()`-Vorgaben und leerem `optCtrl`.
Das Feld ist für `refit()` nutzbar; zusätzlich nennen die
Optimierungsinformationen und `numerics` ausdrücklich das tatsächliche
Abschlussverfahren (`closed_form` oder `analytic_reml`) und dessen
Score-/Randdiagnostik. Es wird nicht behauptet, `nloptwrap` allein habe
den analytischen Endwert gefunden. Das numerische ADR beschreibt diesen
zusammengesetzten Fit und die Bedeutung der gespeicherten Felder.

Der gespeicherte Modellaufruf enthält eine im späteren Aufruferkontext
auswertbare `lme4::lmerControl(optimizer = "nloptwrap")`-Angabe, keinen
Bezug auf eine inzwischen verschwundene lokale Variable. Das ist nötig,
weil `bootMer()` den `control`-Ausdruck des Modellaufrufs auswertet.
Refits bleiben damit gewöhnliche lme4-REML-Fits ohne den zusätzlichen
analytischen Erstfit-Schritt. Das begrenzt die Vervielfachung der Arbeit
in Bootstrap-Läufen. Beide Wege schätzen dasselbe statistische Modell;
die unterschiedliche numerische Steuerung wird dokumentiert und gegen
direktes `refit()`/`bootMer()` geprüft. Explizite Fits behalten ihre
tatsächlich übergebene lme4-Steuerung. Ein anderer Refit-Optimierer oder
verschärfte Vorgaben werden nicht ohne Messbeleg eingeführt.

### Randfälle und gemeinsame GRR-Berechnung

| Fall | Geplantes Verhalten |
| --- | --- |
| Alle gültigen Antworten gleich | Früher englischer Fehler in `msa_fit()`, etwa `Numeric response has zero variation.`; keine scheinbar geschätzte GRR. |
| Identische Replikate, unterschiedliche Zellen | Kein pauschaler Fehler allein wegen gleicher Replikate. Ist die Modellrestvarianz positiv, normaler Fit. Ist das restringierte Optimum ohne positive Restvarianz und damit ohne endliches darstellbares Theta, benannter Fehler über die degenerierte Restvarianz; keine künstliche Reststreuung. |
| Sehr kleine positive Streuung | Stabile Differenzen und skalierte Norm; fitten, solange Eingang und rücktransformierte Varianzen darstellbar sind. Bei tatsächlichem Nullmaßstab, Über-/Unterlauf oder fehlender Identifizierbarkeit benannter Fehler. AtmWtAg bleibt ein verpflichtender Genauigkeitsfall. |
| Zufallskomponente null, Rest positiv | Zulässiges restringiertes Optimum; übrige Komponenten neu schätzen, `singular = TRUE`, keine negative Ausgabe. |
| `acmg_fit()` mit konstanten Scores im Rückfall | Der echte numerische Fehler wird durch den bestehenden Präfix `AP1 numeric fallback failed: ...` weitergegeben. Keine geratene Kennzahl und kein neuer Rückfall. |
| Degeneriertes Szenario in `msa_plan()` | Bestehender Fehlerdurchlauf bleibt erhalten; ein Nullvarianz-Szenario endet benannt statt mit NaN-Ergebnistabelle. |

`msa_grr()` berechnet weiterhin allein aus `fit$vc$variance`, auch bei
konstruierten Komponenten. Zeilen, Spalten und Summary-Namen bleiben
wie in ACC-10/12. EV, AV einschließlich Block und Wechselwirkungen,
GRR, PV und TV folgen Formelsammlung §3. Bei TV null bleiben Varianzen
und SD null, alle Prozentwerte, ICC und ndc werden `NA_real_`, das
Verdikt `undetermined`. Bei GRR null und PV positiv bleiben ndc `Inf`
und mit Vorgabeschwellen `acceptable`. Bei positiver GRR gilt die
Untergrenze eins auch bei PV null. Beide Druckmethoden unterscheiden
NA und Inf ohne NaN. Die Grenzwerte 10/30 bleiben `marginal`, die
Contribution-Konvention und individuelle Schwellen bleiben erhalten.
Die umfassendere Bootstrap-Fehlzählung nach BL-18 bleibt M1c; in M1a
wird die bestehende Einbeziehung von NA-Wiederholungen gesichert.

### Vignette — verbindliche Wahl nach ADR-017 Nr. 7.1–7.6

1. Ein gesetztes, nicht leeres `REPO_ROOT` wählt ausschließlich den
   Vollmodus. Originalanker, geschütztes AIAG-Blatt und NIST-Originale
   werden an den Pfaden aus ADR-017 gelesen und anhand der Originalanker
   geprüft. Fehlende oder veränderte Eingaben brechen benannt ab; kein
   Rückfall in den öffentlichen Modus.
2. Ohne `REPO_ROOT` liest der öffentliche Rechenmodus ganze,
   byte-identische Ankerkopien und freie NIST-Tabellen aus den
   installierten Paketressourcen. Nur der Erzeuger schreibt diese Kopien.
   `SOURCES.json` nennt Originalpfad und Original-/Kopienhash. Keine
   Datei unter `R/` liest diese Ressourcen; keine Abnahme verwendet die
   Kopien als redaktionelle Autorität.
3. Die neue Unit-Driftwache vergleicht Kopien, Originale und Manifest und
   prüft, dass alle von der Vignette gelesenen Anker enthalten sind.
   Ein gesetztes `REPO_ROOT` ist verbindlich; andernfalls wird aufwärts
   nach einem Repository gesucht. Ist eines erreichbar, sind fehlende
   Originale oder Abweichungen Fehler. Nur ohne erreichbares Repository
   darf dieser Originalvergleich mit benanntem Grund überspringen.
   Paketinterne Ressourcen-/Schemaprüfungen laufen auch im Tarball.
4. AIAG-Rohwerte erscheinen in keinem Modus, auch nicht in Codeausgabe,
   Tabellen, Beispielen oder erzeugten Ressourcen. Öffentlich stehen
   erwartete Kennzahlen aus der Ankerkopie und als beobachteter Wert
   `not rerun: protected data required`; dafür gibt es keinen PASS.
5. NIST-Dateien entstehen nach docs/01 §7 mit Quellnachweis, Lizenz,
   Auswahlregel, Hashliste und deterministischem gzip-Kopf. Die
   Zahlentokens bleiben erhalten. Alle gespeicherten Größen werden gegen
   ANK-TOL.data_size geprüft. Das Ressourcen-ADR begleitet die erste
   Golden-Änderung; ADR-017 ersetzt es nicht.
6. Beide Modi rechnen sämtliche als beobachtet bezeichneten Werte beim
   Knitten im geladenen Paketnamespace neu. Caches gelten höchstens
   innerhalb dieses Knit-Laufs. Die Literalregel aus ACC-14 gilt auch
   für eingelesene oder ausgeführte Hilfsdateien; ein Builder-Test prüft
   deren vollständige Abhängigkeiten. Zulässige Referenzzahlen stammen
   aus Originalankern beziehungsweise nachgewiesen byte-identischen
   Kopien, nicht aus weiteren Konstantendateien. Originaldaten und
   numerische Tabellen bleiben als Daten erkennbar; sie enthalten keine
   eingefrorenen Paketresultate. Die Prüfung der Herkunft der Anker und
   Daten ersetzt nicht die Literalprüfung der rechnenden Dateien.

Titel, mindestens fünf Referenztabellen mit `Anchor`, `Source`,
`Expected`, `Observed`, `Tolerance`, `Result`, alle geforderten IDs und
die Darstellung der AIAG-/Penicillin-Werte bleiben wie in ACC-14.
SmLs04–SmLs09 erhalten je vier LRE-Werte, für `msa_fit` und `aov`, je
Rest und Item. SmLs07–SmLs09 dürfen NA mit benanntem Grund berichten.
AtmWtAg wird als NIST-„Average“ bezeichnet und dennoch gegen die feste
strengere Spec-Anforderung geprüft. Es entstehen weder Netzaufrufe noch
neue Dateien in `vignettes/`. Warnungen werden als Diagnostik ausgewiesen,
nicht in erfolgreiche Referenzprüfungen umgedeutet.

## Reihenfolge

1. **BUILD-Ausgangsstand sichern.** Freigegebenes Update und dann aktuelle
   Handoffs/ADRs lesen. Den bisherigen Kern ohne Git in einer temporären
   Paketkopie für den Laufzeitvergleich sichern, mit SHA-256 identifizieren
   und den M2-Abschluss anhand der echten Gate-/Review-Fakten nachtragen.
   Aktuellen M1a-Ausgangslauf mit seinem tatsächlichen roten Ergebnis
   dokumentieren; ACC-17 bleibt ein historischer Reviewer-Beleg.
2. **Numerik und Modellbau zuerst.** Das numerische ADR anlegen, Matrix-
   Nutzung begründen, dann E1/E3–E7 umsetzen. Geschlossene Fälle,
   analytischer Score, aktive Menge, Originalmodell und expliziter
   lme4-Pfad werden getrennt geprüft. Ein benanntes Scheitern wird
   dokumentiert, nicht durch ein ungenaueres erfolgreiches Ergebnis
   ersetzt.
3. **Verpflichtender Go/No-Go vor Ressourcenarbeit.** Die unveränderten
   numerischen Acceptance-Prüfungen soweit schon ausführbar und separate
   Numerikdiagnosen müssen Folgendes belegen: `ic50_demo`, der simulierte
   Blockplan aus K-M1a-6, alle vier Transformationen des Tests, zusätzlich
   Verschiebung um 1e4, Skalierungen über mehrere Größenordnungen,
   negative Skalierung und weitere Seeds. Komponentenabweichungen nach
   Rückskalierung, relative Kennzahlabweichungen, ndc, Verdikt und
   Modellkonsistenz werden tabelliert. Die Grenzen bleiben
   `ANK-TOL.invariance` beziehungsweise `ANK-TOL.nist_digits`.
   Zusätzlich die Laufzeitvergleiche aus E8 messen. Ohne tragfähige
   numerische Ergebnisse folgt weitere Arbeit an der Ursache, keine
   Ressourcenproduktion. Bleibt die Vorgabe nach belegtem Versuch
   unerreichbar, erhält der Reviewer die Messwerte nach ADR-016 E6.
4. **GRR und Ressourcen abschließen.** Nullfälle und Druckmethoden
   vervollständigen, Ressourcen-ADR und Erzeuger hinzufügen. Erzeugung
   zweimal in getrennten temporären Verzeichnissen, Vergleich der Bytes
   und Hashes. Driftwache, Literalprüfung und kleine Hilfstests ergänzen.
   Beschädigte Eingaben werden nur in temporären Kopien geprüft und
   dürfen keine teilweise veröffentlichten Ausgaben hinterlassen.
5. **Vignette und Dokumentation.** Vollmodus mit unveränderten lokalen
   Quellen knitten, danach aus einer Paketkopie ohne `REPO_ROOT` und ohne
   geschützte Quellen öffentlich bauen und prüfen. Installierbare
   Ressourcen müssen beide Kontexte tragen. Rd-Dateien nur aus der
   temporären Roxygen-Ausgabe übernehmen; Wurzel-README nicht anfassen.
6. **Vollständige Regression und Übergabe.** Alle M1a-Abnahmetests samt
   Vignette, betroffene M2-Auswertung, Unit- und bestehende QA-Tests sowie
   Paketcheck ausführen. Befehle, echte Outputs, Zeiten und Grenzen in
   PROGRESS/Handoff aufnehmen. Territoriumsprüfung, Phasen-Commit,
   kumulative Gates und Abnahme bleiben bei Orchestrator und Reviewer.

## Risiken

| Risiko / Referenz | Behandlung |
| --- | --- |
| Flache REML-Fläche, E1 | Analytischer Score und Krümmung mit aktiven Grenzen; Korrekturschritt zusätzlich zur Score-Norm. Go/No-Go mit festen Grenzen und Zusatzfällen, keine Erfolgsaussage allein aus dem Optimierercode. |
| Falsche EMS-Anwendbarkeit | Vollständige Kreuzung, Zellbesetzung, Restfreiheitsgrade und Vorzeichen prüfen. Unbalancierte und restringierte Mehrfaktorfälle vollständig neu optimieren. |
| Modellrückbau/Diagnostik, E3/E5 | Eine Quelle für Komponenten; Originalskala und Zeilen testen, Abschlussverfahren offenlegen, keine Korrektur nur von `vc`. Modell nach Serialisierung ebenfalls refit-fähig prüfen. |
| Datenauflösung, BL-23/E6/E7 | Numerische Eingaben direkt erhalten, stabile Differenzen und Normen. Bereits verlorene Stellen nicht rekonstruieren; degenerierte Darstellung benannt melden. |
| Refit- und Klasse-B-Laufzeit, E8 | Normaler lme4-Refit mit dokumentierter Steuerung; Zeiten für Erstfit und Wiederanpassung getrennt. Keine vorgezogene Coverage-Aussage. |
| Sparse Ableitungsrechnung/Import | Matrix-Import mit ADR und ohne Mindest-R-Wechsel. Kleine unabhängige Matrixrechnung prüft algebraische Fehler; keine dichten Beobachtungskovarianzen im Produktpfad. |
| Vignettenherkunft, E10 | Strikter Vollmodus, verifizierte Kopien mit Driftwache, keine AIAG-Rohwerte und keine eingefrorenen Orakelergebnisse. |
| Laufzeit je Mutant, E9/E12 | Unit-Tests klein halten; vollständige Referenzrechnung bleibt in Abnahme/Vignette. Betreiber entscheidet über Infrastruktur, der Builder verändert keine Gates. |
| Plattformen, BL-72 | Portable Matrix-/lme4-APIs, normalisierte Pfade, keine Forks. Neue Tests lesen Toleranzen exakt; lokales Linux-Ergebnis ist kein Windows-/macOS-Beleg. |

### Offene Backlog-Einträge

Alle 57 offenen IDs des gelesenen BACKLOG erhalten hier eine Zuordnung.
Vertagung schließt keinen Befund. Die Statuspflege bleibt beim Eigentümer.

| ID | Maßnahme oder begründete Vertagung |
| --- | --- |
| BL-01 | M1a auf seine Kriterien begrenzen; M3-Zeitentscheidung nach M1d bleibt beim Betreiber. |
| BL-02 | Neuheitsabgrenzung an Publikationsarbeit/Betreiber vertagt; keine neue Neuheitsbehauptung in der Vignette. |
| BL-03 | Ordinaler Ersatz und ADEMP nach M1b/M1d; numerischen AP1-Rückfall jetzt als Regression prüfen. |
| BL-04 | Überdeckungsstudie nach M1c/M1d; ein kleiner Bootstrap-Regressionslauf in M1a ersetzt sie nicht. |
| BL-05 | Memorisierungsvorbehalt bis AP1-Endauswertung erhalten; keine Änderung der Referenzklassifikationen. |
| BL-06 | Modellzugang/Umleitung bleiben Betreiberarbeit nach M0; keine Rollen- oder Routingänderung. |
| BL-07 | Im Code für M2 abgedeckt; Provider-Stichprobe und Wiederholungstage bleiben AP1-Betrieb. |
| BL-08 | Datenschutz/Partnerdaten nach AP7 vertagt; keine solchen Eingaben in M1a. |
| BL-09 | Jetzt beachten: geschützte Rohblätter und Bücher bleiben lokal, keine AIAG-Rohwerte in irgendeinem Vignettenmodus. |
| BL-10 | Publikationsentscheidung bleibt an M1 und AP1-Endauswertung gebunden; M1a ist keine Freigabe dafür. |
| BL-11 | Dashboard-/Kostenabgleich beim Betreiber; keine Harness-Telemetrie im Produkt. |
| BL-12 | Vollläufe erst nach M1b/M1c; jetzt Fit-/Bootstrap-Laufzeiten als Planungsgrundlage messen (E8). |
| BL-13 | BUILD-Zeiten messen und spätere Gate-Fakten lesen; Mutationsdauer E12 separat als Betreiber-[INFRA] führen. |
| BL-14 | Numerischen Kern jetzt unabhängig und mutationstauglich prüfen; ordinal/binär und Bootstrap-Abnahme M1b/M1c. |
| BL-15 | Fleiss-Kappa und Projektdokument nach M3a vertagt, außerhalb der M1a-Kriterien. |
| BL-17 | ellmer-Aufzeichnungen/Live-Lauf nach M3d/AP2; vorhandene Regressionen bleiben. |
| BL-18 | Vollständige Bootstrap-Fehlzählung und Wortlaut M1c, Berichtshash M3d; jetzt NA-Einbeziehung erhalten (E11). |
| BL-20 | Ordinaler wine-/clmm2-Abgleich nach M1b vertagt. |
| BL-21 | Geschachtelte NIST-Fallstudie bleibt Reviewer-Ankerkandidat ohne M1a-Kriterium. |
| BL-22 | Jetzt: AIAG ohne Wechselwirkung reproduzieren; Interaktionsmodell gesondert berichten. |
| BL-23 | Jetzt: NIST-Genauigkeit und LRE-Bericht mit ausgewiesenen Darstellungsgrenzen, ohne Datenreparatur. |
| BL-24 | Mutations-Baseline vor Scope-Erweiterung M3a bleibt Betreiberzustand. |
| BL-25 | Originalanker unverändert; Nachträge nur Reviewer mit ADR. Neue NIST-Golden-Daten mit Builder-ADR. |
| BL-28 | AP1-Zugänge, Schlüssel und Limits bleiben Betreiberarbeit; keine Schlüssel lesen. |
| BL-29 | Infevers-Anfrage/Nennungsrecht beim Betreiber; keine INSAID-Referenzklasse veröffentlichen. |
| BL-30 | Pages/DOI/Release nach AP2 beziehungsweise an Betreiber vertagt. |
| BL-31 | Commitidentität und Push-Konfiguration beim Betreiber; Builder führt kein Git aus. |
| BL-33 | CLI-/Sandboxvoraussetzungen beim Betreiber/PREFLIGHT; keine Berechtigungsänderungen. |
| BL-34 | Erreichbarkeit im RUNBOOK bleibt Betreiberaufgabe; vorhandener Eskalationsweg bleibt. |
| BL-35 | notify-Verhalten ins Template-Backlog vertagt, kein Statistikkernbefund. |
| BL-36 | WSL-Ablage bei Bedarf durch Betreiber; keine vollständige Rohdatenkopie in M1a. |
| BL-37 | Kostenspur zusammen mit BL-11 an Betreiber vertagt. |
| BL-39 | Beschaffung beim Betreiber; vorhandene M1a-Quellen werden nicht durch unbelegte Werte ersetzt, DIN außerhalb Scope. |
| BL-40 | Konkordanzliteratur nach M1d/Publikationsarbeit vertagt. |
| BL-41 | Landis/Koch erst vor entsprechender Zitierung beschaffen; M1a führt keine solchen Bänder ein. |
| BL-42 | AIAG-Originalabgleich laut ACC-16 erledigt; BUILD prüft Eingangsdatei/Hash erneut. Weitere geschützte Blätter vor späteren Meilensteinen. |
| BL-43 | Live-Katalog/Preise vor AP1 durch Betreiber prüfen; kein API-Netzzugriff in M1a. |
| BL-44 | Fleiss-Varianz nach M3a vertagt. |
| BL-45 | Externe Projekt-/Harness-Unterlagen nach Meilenstein beim Betreiber. |
| BL-46 | Jetzt beide Vignettenkontexte und Laufzeit prüfen; Unit-Tests ohne vollständiges Knitten (E9); weitere Vignetten M1d. |
| BL-47 | VariantBench-Nennung bei späterer Publikation; keine Verwendung in M1a. |
| BL-48 | Maschinelle Gate-Zuordnung bleibt Betreiber/Reviewer; K-M2-7-Dokumentationsnachtrag laut Backlog bereits vorhanden. |
| BL-49 | K-M1a-1 weiter mit explizitem bobyqa-Auftrag; neuen Vorgabefit unabhängig analytisch absichern (E1/E4). |
| BL-50 | CV-Planungsnäherung nach M3c vertagt; in M1a nur Laufzeit-/Fehlerregression von msa_plan. |
| BL-51 | acmg-Exporte erst nach AP1 per ADR entscheiden, weiterhin intern. |
| BL-52 | AP1-Zahlen bis M1-Abnahme vorläufig; Betreiber wiederholt Auswertung desselben externen Stores. |
| BL-55 | Nur zugewiesene Repository-Dateien schreiben, BUILD-Artefakte außerhalb; keine gleichzeitige Erzeugung fremder Dateien veranlassen. |
| BL-57 | API-Obermenge und Defaults erhalten; keine neuen öffentlichen Argumente, zusätzliche Review-Prüfung bleibt. |
| BL-60 | ellmer-/Streaming-Mocks nach M3d vertagt, unabhängig vom numerischen Kern. |
| BL-64 | Quantilkopplung bei späterer AP1-/M3d-Pipelinepflege; bei Planwert 7 kein M1a-Einfluss. |
| BL-68 | Herkunftswortlaut vor nächster AP1-Berichtspflege; kein beiläufiger Eingriff in R/acmg.R. |
| BL-70 | Status/Timeout/STOP/QA-Probe-Logs beim Betreiber beziehungsweise Template-Backlog. |
| BL-71 | Memorisierungsnäherung vor AP1-Endauswertung durch Betreiber entscheiden, gegebenenfalls eigenes ADR/Golden-Änderung. |
| BL-72 | Jetzt analytische Invarianz, exaktes Toleranzlesen und portable Unit-Tests; bestehende ADR-012-Toleranzen nicht ändern. |
| BL-73 | Spaltenerklärung/Restprüfung vor AP1-Bericht an Pipelinepflege vertagt, kein M1a-Kriterium. |
| BL-74 | Block- und Laufzeitplanung im AP1-Betrieb; keine API-Parallelisierung durch M1a. |
| BL-75 | Latenzbereinigung vor AP1-Bericht an Pipelinepflege vertagt; Messwert-Varianzkomponenten unberührt. |

Die 18 erledigten IDs BL-16, BL-19, BL-26, BL-27, BL-32, BL-38,
BL-53, BL-54, BL-56, BL-58, BL-59, BL-61, BL-62, BL-63, BL-65,
BL-66, BL-67 und BL-69 werden nicht erneut eröffnet. E12 erhält hier
keine erfundene BL-ID; der Reviewer übernimmt seinen angekündigten
Infrastrukturnachtrag im Code-Review.

## Testplan

### Unveränderte Abnahme und ergänzende Prüfungen in BUILD

| Kriterium | Nachweis |
| --- | --- |
| K-M1a-1 | Vier balancierte Designs und Penicillin gegen unabhängige ANOVA; expliziter Optimierer aus ANK-TOL, Komponenten relativ zu Referenz-TV, Kennzahlen relativ, ndc gleich. Direkter lme4-Pfad bleibt nachweisbar. |
| K-M1a-2 | AIAG-Datei und Hash, ANOVA-Tabelle und gedruckte Kennzahlen nach ANK-10; Modell ohne Wechselwirkung, Interaktionsmodell nur berichten. |
| K-M1a-3 | VCA/SixSigma live auf denselben Daten nach ADR-016/017; Penicillin mit Paketvorgaben gegen ANK-13, Varianzen und quadrierte SD. Kein eingefrorenes Orakelergebnis. |
| K-M1a-4 | Elf NIST-Eingänge; fünf strenge Fälle, drei mittlere nach LRE-Regel, drei hohe als Bericht. Allgemeine Einweg-Gegenproben mit negativem Momentenschätzer und unbalancierten Daten ergänzen. |
| K-M1a-5 | Konstruierte Komponenten, alle Prozent-/ICC-/ndc-Formeln, Grenzwerte, Nullfälle; zusätzlich beide Druckmethoden und contribution/eigene Schwellen. |
| K-M1a-6 | Unveränderte Transformationen auf ic50/Blockplan, Singularität, fehlende Zellen/Replikate, Konstantenfall und lme4-Warnungen. Zusätzliche Numerikmatrix wie unten. |
| K-M1a-7 | Vollständiges Knitten, Struktur/Anker-/Literal-/LRE-Prüfungen; Driftwache und öffentlicher Paketcheck separat. lint trägt den Vollmodus-Bau. |

**Numerischer Go/No-Go-Versuch:** Neben den Acceptance-Seeds werden die
vier simulierten Designs mit Seeds 1–6 sowie `ic50_demo` geprüft.
Transformationen: Permutation mit protokollierten Seeds, Umbenennen
aller Faktorstufen einschließlich Block, Verschiebungen um 100 und
1e4, Skalierungen 7.5, 0.02, 1e-3 und 1e3 sowie negative Skalierung
und kombinierte Transformationen mit erhaltener Eingabestreuung.
Abstände zu ndc-/Verdiktsgrenzen werden aus ANK-TOL geprüft und
berichtet; grenznahe Zusatzfälle werden nicht zur Behauptung gleicher
diskreter Klassifikationen benutzt. Komponentenprüfungen bleiben auch
dort aktiv. Die vorgegebenen Abnahmefälle und ihre Grenzen bleiben
uneingeschränkt. Bei jedem Fehlfall stehen Datenaufbau, Seed,
Steuerung, aktive Menge, Abschlussnormen und Abweichung je Komponente
im Befund. Die Messung ist ein endlicher Numeriktest, keine ADEMP-Studie.

**Modell- und Unit-Regressionen:** `vc` gegen `VarCorr(model)`, sigma²
gegen Rest, Antwort gegen Fitted Values plus Residuen, Namen und
Reihenfolge von Modellrahmen/`ranef()`/`coef()`, Vorhersagen sowie
`refit()` nach Serialisierung. Kleine unabhängige Matrixrechnungen und
Richtungsableitungen prüfen Score/Krümmung und Randvorzeichen. Explizite
Steuerung einschließlich erzwungenem Abbruch sowie `weights`, `offset`,
`subset` und `start` werden gegen direkte lme4-Aufrufe auf denselben
Originaldaten geprüft. E6/E7/E11 erhalten die beschriebenen
Verhaltensprüfungen; RNG-Zustand und Eingabeobjekte bleiben erhalten.
Standard-lme4-Vergleiche verwenden `ANK-TOL.reml_anova`; die strikte
Invarianztoleranz gilt für die nachgewiesen präzise neue Methode und
geschlossene Rechnungen. Keine bestehende Erwartung wird gelockert.
Toleranzleser prüfen Existenz und gültigen numerischen Wert jedes
benötigten Schlüssels, auch im installierten Paket.

**Laufzeitversuch E8:** Vorher-/Nachher-Paketkopien auf derselben Maschine
mit gleichen Paketversionen und Seeds. Je ein Aufwärmlauf und drei
gemessene Läufe, Median und Spanne, getrennt nach Erstfit und Refits.
Prüffälle: `ic50_demo`; `SmLs03`; eine kleine Planung mit zwei Szenarien
und fünf Wiederholungen je Szenario; ein numerischer Bootstrap mit acht
Wiederholungen. Größen, Komponenten und Seeds werden im Diagnoseaufruf
festgehalten. Diese kleinen Läufe messen Mehrkosten, nicht Coverage.
Der Bootstrap wird außerdem bei gleichem Seed und gleicher Statistik
gegen direktes `bootMer(fit$model)` geprüft. Ein neuer Laufzeitgrenzwert
wird daraus nicht erfunden. Schlechte Skalierung wird vor Schritt 4
bearbeitet; Gate-Zeitbudgets bleiben Betreiberentscheidungen.

**Vignettenprüfungen E9/E10:** Kleine Unit-Fälle prüfen Kontextwahl,
fehlende/defekte Dateien, Schlüssel, Hashes, vollständige Ankermenge,
Tabellenaufbereitung, Literalherkunft und die verbotene Ausgabe von
AIAG-Rohwerten. Das vollständige Knitten und große VCA-Orakel bleiben
in der Abnahme beziehungsweise im gesonderten BUILD-Prüflauf. Drift-
Negativfälle verändern ausschließlich temporäre Kopien. Ein ungültiges
gesetztes `REPO_ROOT` muss scheitern; ein fehlendes Original im
erreichbaren Repository darf nicht als Tarball-Skip gelten.

Geplante direkte BUILD-Kommandos aus der Repo-Wurzel:

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
Rscript --vanilla -e 'grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m1a-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE); grDevices::dev.off()'
Rscript --vanilla -e 'grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m2-6-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE); grDevices::dev.off()'
```

Die frühe Numerikdiagnose ersetzt keinen vollständigen Abnahmelauf.
Solange die Vignette noch fehlt, wird ihr erwarteter Fehler in
`test-m1a-4` beziehungsweise `test-m1a-7` ausdrücklich als offen
geführt; Tests werden dafür weder übersprungen noch verändert.

Der öffentliche Check erfolgt in einer Positivlisten-Kopie der
Paketdateien außerhalb des Arbeitsbaums, ohne `REPO_ROOT`, Originalanker
oder geschützte Daten. Dort wie im vorherigen Plan:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht dem vorhandenen Betreiberprüfweg;
weitere Check-Regeln bleiben aktiv. Die endgültige Paketversion wird
aus DESCRIPTION gelesen, falls der Betreiber sie zwischenzeitlich
ändert. Bauartefakte, Knitausgaben und Diagnoseprotokolle bleiben
außerhalb des Arbeitsbaums. Die geplanten technischen ADRs und
PROGRESS nennen die tatsächlichen Kommandos, Outputs und Laufzeiten.

Der Builder startet weder Verifier noch Git-verwendende Gate-Skripte
oder kumulative M0-Prüfwege. Orchestrator-Gates prüfen territory,
trace, lint, deps, tests, golden-adr und mutgate. Mutations-Scope
`R/fit.R`/`R/grr.R`, Schwelle/Floor/Ratchet, 14 Worker und bestehende
Testauswahl bleiben unverändert; `88-mutfull` folgt M1c.
QA bleibt eine getrennte Rolle. Der Builder schreibt kein Verdict,
keine Gate-Fakten und keine Zustandsdatei.

### Nachweise dieser PLAN-Phase

Es wurden keine fachlichen Tests, Builds oder Gates ausgeführt.
Lesende R-Diagnosen prüften die vorhandenen Versionen, die exportierten
modularen Funktionen und den lokalen lme4-Code von `mkMerMod`,
`refit.merMod`, `bootMer` und den Optimiererhilfen. Tatsächlicher
Versions-/Exportoutput von `Rscript --vanilla -` (Exit 0):

```text
R: 4.6.1
lme4: 2.0.6
Matrix: 1.7.4
Exported modular functions: lFormula, mkLmerDevfun, optimizeLmer, mkMerMod, checkConv, refit, getME
```

Die gelesene Implementierung präzisiert E8: `bootMer` liest
`eval.parent(x@call$control)` und übergibt das Ergebnis an `refit`.
Dort kann eine explizite Steuerung den Optimierer überschreiben;
bei expliziter Steuerung mit leerem `optCtrl` werden die gespeicherten
Optimiererparameter übernommen. Deshalb werden Modellaufruf und
`optinfo` gemeinsam geprüft. Diese Lesediagnose beweist noch nicht,
dass der geplante neue numerische Pfad funktioniert.

Die lesende Strukturprüfung mit `python3 -` (`pathlib`, `re`, `json`)
verglich die Abschnitte mit dem Schema, die Antworten mit den
Einwand-IDs aus PLAN-REVIEW, die Kriteriumstabelle mit CRITERIA und die
Backlog-Tabelle mit den offenen Zeilen aus BACKLOG. Tatsächlicher
Output (Exit 0):

```text
PLAN-UPDATE structure: 6/6 required sections, in schema order
Review responses: 12/12 IDs, each explicitly accepted
Criteria coverage: 7/7 M1a criteria with a test plan
Open backlog: 57/57 IDs with a separate disposition
Markdown code fences: balanced
ARBITER.md: absent
```

Vor dem Schreiben wurden 234 bestehende Produkt-, Test-, Anker-,
Dokumentations-, Vertrags-, Handoff- und Harness-Dateien mit Python
und SHA-256 erfasst. Der erneute lesende Vergleich ergab:

```json
{"baseline_files":234,"changed":[],"removed":[],"added":["orchestrator/handoff/M1a/PLAN-UPDATE.md"]}
```

Die Inventur ersetzt keine Territoriumsprüfung des Orchestrators.
Die einzige geschriebene Repository-Datei ist dieses Update.
Keine Git-Kommandos, keine Installation, kein Netzzugriff und keine
Produktcodeänderung in dieser PLAN-Phase.
