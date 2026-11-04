# PLAN — M3b, Runde 1

Datum: 04.11.2026. Rolle: Builder. Phase: `20-plan`.
Diese Phase schreibt ausschließlich diesen Plan. Die nachfolgend genannten
Produktänderungen sind Vorschläge für BUILD nach dem Plan-Review; ein
Abnahme-Verdict wird nicht erteilt.

## Ziel

`pb_design()`, `msa_robustness()` und der Half-Normal-Plot erfüllen
K-M3b-1 bis K-M3b-6 in der aktuellen Fassung von
`docs/04-weitere-bausteine.md`, Abschnitt M3b. Die vorhandenen PB- und
Lenth-Berechnungen werden erhalten. Ergänzt werden die wählbare
Logit-Transformation, die sichtbare Daniel-Konvention, die fachlich korrigierte
Hilfeseite und die deklarierten Validierungsabhängigkeiten.

Gelesene Grundlage: `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, sämtliche 126 Einträge von
`BACKLOG.md`, `orchestrator/handoff/SCHEMA.md`, die vollständige
`orchestrator/handoff/M3b/CRITERIA.json`, alle sechs M3b-Abnahmedateien samt
`setup-m3b.R` und den benötigten gemeinsamen Helfern sowie
`tests/simulation/setup-simulation.R` und `test-lenth-h0.R`.
Zusätzlich maßgeblich: `docs/01-fachspezifikation.md` §§1–9,
Formelsammlung §§7 und 9, ANK-02, ANK-06, ANK-32, ANK-80 bis ANK-82,
die einschlägigen Einträge von ANK-TOL und ADR-050. Die Lehre aus
`orchestrator/LESSONS.md` wird auf die neue Eingabeprüfung angewandt:
ungültige Logit-Eingaben als Klasse prüfen, einschließlich endlicher Werte
außerhalb des zulässigen Intervalls und nicht endlicher Werte.

ADR-050 ist seit der wiederholten ACCEPTANCE bindend:

- ACC-5 ist entschieden: FrF2 wird mit `boxtyssedal = FALSE` verglichen;
  alle fünf Plangrößen einschließlich 16 bleiben im Nachweis.
- ACC-7 ist entschieden: `unrepx::PSE(method = "Lenth")` prüft die PSE;
  `DoE.base::ME.Lenth(simulated = FALSE)` prüft PSE, ME und SME.
- ACC-10 ist entschieden: Die H0-Raten dürfen das Nominalniveau zuzüglich
  der MCSE-Reserve nicht überschreiten. Zusätzlich muss jede Entscheidung
  der unabhängigen Mini-Referenz gleichen. Die konservative Methode wird
  nicht auf eine gemessene Rate kalibriert.

Die Prüfformen ACC-3, ACC-4, ACC-6, ACC-8, ACC-9, ACC-11 und ACC-15
werden übernommen; die in ACC-1 angekündigte Dokumentation dieser
Auslegungen im PLAN-REVIEW-ADR bleibt beim Reviewer. ACC-12 wird durch
die Suggests-Ergänzung umgesetzt. ACC-1/ACC-2 liefern die vorhandenen
Anker und geschützten Eingaben; ACC-13 bleibt ein Infrastrukturhinweis,
ACC-14 ein Nachweis des Reviewers zur Trennschärfe seiner Tests.

Der eigene Ausgangslauf dieser PLAN-Phase bestätigt K-M3b-1/-2/-3 und
den Simulationsteil von K-M3b-5 auf dem unveränderten Produktstand.
Die roten Erwartungen betreffen die drei vorgesehenen Änderungen;
Kommandos und echte Outputs stehen im Testplan. Das ist eine lokale
Bestandsdiagnose, keine Gate-Abnahme.

## Dateien

| Datei | Geplante Änderung in BUILD und Zweck |
| --- | --- |
| `R/robustness.R` | `transform` an `msa_robustness()` anhängen, nur im neuen Logit-Pfad validieren und transformieren; roxygen für Transformation und konservatives Nominalniveau berichtigen; Daniel (1959) in der Plot-Achse nennen. PB-Konstruktion, Lenth-Rechenfolge und bestehende Druckmethode erhalten. |
| `man/msa_robustness.Rd` | Aus dem geänderten roxygen erzeugen: neue Signatur, zulässiger Eingabebereich, Bedeutung der Ergebnisskala, konservatives Verfahren und nominales `alpha`. |
| `DESCRIPTION` | `FrF2`, `DoE.base` und `unrepx` ausschließlich zu Suggests hinzufügen, gemäß ADR-050/ACC-12. |
| `tests/testthat/test-robustness-transform.R` (neu) | Verhalten der neuen Option, unabhängige Logit-/Regressionsgegenrechnung, Fehlerklasse und Bereichsgrenzen, Standardaufruf und Faktoruntermenge prüfen. |
| `tests/testthat/test-robustness-properties.R` (neu) | Kleine synthetische Invarianz-, RNG- und Randfallprüfungen für den betroffenen Robustheitspfad; vorhandene Tests bleiben bestehen. |
| `vignettes/validation.Rmd` | Kurzer englischer Methodenabschnitt zu den M3b-Prüfwegen und der konservativen Interpretation nach `docs/01` §2 Nr. 8; keine abgetippten Simulationsergebnisse und keine Simulation beim Bau. |
| `NEWS.md` | Neue Option, Daniel-Beschriftung und fachliche Präzisierung der Hilfe auf Englisch nennen. |
| `PROGRESS.md` | BUILD-Änderungen, tatsächliche Kommandos/Outputs, Einschränkungen und offene Fremdterritorien auf Deutsch festhalten. Den inzwischen belegten M1d-Abschluss als Nachtrag mit Quellenverweis ergänzen. |
| `orchestrator/handoff/M3b/REVIEW-INPUT.md` | Nach BUILD Umsetzungszuordnung, Prüfergebnisse und gegebenenfalls konkret referenzierte Fremdterritoriums-Befunde übergeben. |

Die Rd-Erzeugung erfolgt in einer temporären Paketkopie; übernommen wird
nur die betroffene Hilfeseite. `NAMESPACE` und `man/pb_design.Rd` benötigen
inhaltlich keine Änderung. Die bestehenden Imports, Exporte, Klassen,
AP1-Konfiguration und eingefrorenen Daten bleiben erhalten. Numerische
Unit-Toleranzen liest der vorhandene Helfer `numeric_tolerance()` aus
der installierbaren Kopie von ANK-TOL; M3b benötigt keine neue Ankerkopie.

Der Plan erfordert keinen neuen Builder-ADR: Das angehängte Argument ist
ausdrücklich spezifiziert, die übrigen Änderungen setzen ADR-050 um.
Eine nachträgliche Vertrags- oder Golden-Änderung wäre gesondert zu
begründen und im zuständigen Territorium zu behandeln. Ein eventueller
`MUT-EQUIV.json`-Antrag entsteht erst für einen tatsächlich nachgewiesenen
Einzelfall am endgültigen Code; Freigaben schreibt ausschließlich der Reviewer.

## Schnittstellen

Die öffentliche Signatur wird additiv erweitert:

```r
msa_robustness(design, response, factors = NULL, alpha = 0.05,
               transform = "none")
```

Die ersten vier Argumente behalten Namen, Reihenfolge und Vorgaben aus
ANK-02. `pb_design(factors, n_runs = NULL, randomize = TRUE, seed = NULL)`
und die S3-Signaturen bleiben erhalten. Der API-Snapshot wird nicht geändert.

1. **Auswahl und Eingabe.** `transform` ist ein einzelner, nicht fehlender
   Zeichenwert; zulässig sind exakt `"none"` und `"logit"`. Andere Werte,
   leere oder mehrwertige Angaben werden mit einem benannten Fehler
   zurückgewiesen. Der ausgelassene Parameter verwendet `"none"`.
   Bestehende Längen- und NA-Prüfungen bleiben erhalten.
2. **Logit-Pfad.** Für `"logit"` muss `response` ein reeller numerischer
   Vektor endlicher Anteile mit `0 < p < 1` sein. Die vollständige Prüfung
   erfolgt vor der Transformation und vor der Effektberechnung. Auch
   `0`, `1`, Werte außerhalb des Intervalls, `NA`, `NaN` und Unendlichkeiten
   scheitern klar. Ein geeigneter englischer Bereichsfehler lautet:
   ```text
   `response` must contain finite proportions strictly between 0 and 1 for transform = 'logit'.
   ```
   Er benennt beide Grenzen ohne einen Punkt unmittelbar hinter der 0 oder
   1 und erfüllt damit auch die unveränderte Prüfung aus ACC-11/ACC-14.
3. **Berechnung.** Nach erfolgreicher Prüfung wird `stats::qlogis(response)`
   dem bisherigen allgemeinen Rechenweg übergeben. Das entspricht
   `log(p / (1 - p))`; jede Antwort wird genau einmal transformiert.
   Es erfolgt keine Randkorrektur oder Ersetzung einer ungültigen Antwort.
   Effekte, PSE, ME, SME, `response_mean` und `response_sd` beziehen sich
   dann auf die Logit-Skala; die Hilfeseite erklärt dies.
4. **Bestehender Ergebnisvertrag.** Ohne Transformation bleiben das gesamte
   Ergebnisobjekt und seine Attribute identisch zum bisherigen Aufruf,
   einschließlich Sortierung, `t_lenth`, Aktivitätsflags, `alpha` und
   Antwortzusammenfassung. Es wird insbesondere kein neues Standardattribut
   angehängt: K-M1d-8 vergleicht ganze Objekte mit `done/M1c`.
   Der Logit-Pfad verwendet dasselbe Rückgabeschema.
5. **Lenth-Verfahren.** `m` bleibt die Zahl der ausgewählten Faktorspalten.
   Die Konstanten aus ANK-81, strikte Trimmung bei `< 2.5 * s0`,
   nicht gerundetes `m / 3`, t-Quantile, Sidak-Ausdruck für `gamma` und
   die strikten Entscheidungen `abs(effect) > me` beziehungsweise `> sme`
   bleiben erhalten. Die Beispiele gehen im Test mit ihren vollständigen
   Kontrastspalten ein. BL-125/BL-126 ändern diese Vorgabe nicht.
6. **Plot und Hilfe.** Die x-Positionen bleiben
   `qnorm(0.5 + (seq_len(m) - 0.5) / (2 * m))`, die y-Werte die geordneten
   absoluten Effekte. Vorgesehener x-Achsentext:
   `Half-normal quantile (Daniel, 1959)`; der Haupttitel allein genügt nicht.
   Die Hilfe nennt Lenth ausdrücklich `conservative` und beschreibt `alpha`
   als `Nominal significance level for ME and SME`.
   Der Satz `at the 5 % level per effect` entfällt. Der bereits abgenommene
   Hinweis aus K-M1d-8, dass kein aktiver Faktor keine Robustheit beweist,
   bleibt in Druckausgabe und Bericht erhalten.

`acmg_robustness()` bildet bereits den empirischen Logit mit der festgelegten
Korrektur und übergibt diesen an `msa_robustness()` (`R/acmg.R:1065–1067`).
Dieser Aufruf behält den neuen Vorgabewert `"none"`; damit bleibt es bei
einer Transformation und bei den bisherigen AP1-Effekten und Bändern.

## Reihenfolge

1. PLAN-REVIEW lesen und die vereinbarten Auslegungen übernehmen. Bei einer
   zweiten Planrunde jede Einwand-ID in `PLAN-UPDATE.md` beantworten;
   einen bindenden Arbiter berücksichtigen. Echte Spec-Widersprüche über
   den vorgesehenen Handoff an den Orchestrator geben.
2. Zu BUILD-Beginn Eingaben und Umgebung erneut lesend prüfen: ANK-80/81/82,
   SHA-256 der drei Lenth-CSV, Suggests-Verfügbarkeit und aktuelle Gate-
   Konfiguration. Ausgangsfunktionen und Dateihashes ohne Git sichern,
   insbesondere für den Vergleich der bisherigen Robustheitsobjekte.
3. DESCRIPTION um die drei Suggests ergänzen. Der Builder installiert oder
   aktualisiert keine Abhängigkeit; bei fehlendem Paket ist das deps-Gate
   beziehungsweise der Betreiber zuständig.
4. Neue Option samt vollständiger Prüfung im Logit-Pfad implementieren.
   Kleine neue Unit-/Eigenschaftstests prüfen den neuen Vertrag und die
   Erhaltung des Standardpfads. Keine Umstellung der PB- oder Lenth-Algorithmen.
5. Plot-Beschriftung und roxygen ändern, Rd in temporärer Kopie erzeugen;
   NEWS und den kurzen Validierungsabschnitt ergänzen. In diesem Schritt
   die Worte `conservative` und `nominal` in der tatsächlich erzeugten
   Hilfeseite prüfen.
6. Nach der letzten Produktänderung die zielgerichteten Tests, M3b-Abnahme
   und H0-Simulation ausführen, danach Unit-/Integrationsregressionen und
   den öffentlichen Paketbau/-check. Relevante Fehler werden im Produkt
   behoben; erneute Läufe betreffen die dadurch geänderten Prüfpfade.
7. PROGRESS und REVIEW-INPUT mit echten Outputs abschließen. SHA-256-
   Vergleich der geschützten Eingaben, Tests und erzeugten Dokumentation;
   alle Artefakte außerhalb des Arbeitsbaums. Anschließend führen
   Orchestrator und Reviewer die Territoriumsprüfung, Phasen-Commits,
   vollständigen Gates und Abnahme aus. QA schreibt ihre eigenen E2E-/Fuzz-
   Tests in der vorgesehenen Phase.

## Risiken

| Risiko / Referenz | Behandlung |
| --- | --- |
| Doppelte Logit-Transformation oder veränderte AP1-Bänder; K-M3b-6, K-M1d-8, ADR-050 Nr. 4 | Literalvorgabe `"none"`, bisherige vollständige Objekte erhalten, Vergleich an Faktoruntermenge, anderem `alpha`, normalem data.frame und AP1-Robustheitsfällen. |
| Abweichende Orakelkonventionen; ACC-4/ACC-6 und ADR-050 | Genau die festgelegten Aufrufparameter verwenden. Den strikten Trimmungsgrenzfall gegen Mini-Referenz und DoE.base prüfen; unrepx-PSE wird nur in den dafür vorgesehenen Fällen verglichen. |
| Scheinbare Kalibrierung an die H0-Rate; K-M3b-5 | Formeln und Seeds erhalten. Obergrenze mit gemessener MCSE und Gleichheit sämtlicher Entscheidungen verlangen; kleinere Raten offen als konservativ berichten. |
| Beschriftung nur im Haupttitel oder roxygen/Rd auseinander; ACC-8/ACC-15 | Tatsächlich gezeichnete Achse und aus Rd erzeugten Klartext prüfen. Die bestehenden unabhängigen Abnahmetests entscheiden. |
| Fehlende geschützte CSV oder Abhängigkeit; ACC-2/ACC-12, BL-42/BL-103/BL-105 | Vorprüfen und mit Pfad/Hashfehler übergeben. Fehlende Daten bleiben Fehler; Betreiber liefert Originale, deps installiert Pakete. |
| Mutation erfasst die ganze geänderte R-Datei; ANK-32, BL-123 | Schnelle, aussagekräftige Tests für den betroffenen Pfad; keine neuen Ausschlüsse. Aktuell steht der Scope auf alle R-Dateien, `tests/simulation/` ist nicht in MUT_TEST_DIRS, die Baseline-Datei fehlt wie vorgesehen. Der reguläre Lauf muss den Score erst belegen. |
| Sandbox, Laufzeit und Paketkopien; BL-13/BL-72/BL-86 | Null-PDF-Gerät, temporäre Ausgaben, installierbare Testressourcen und echte Exit-Codes. Socket-/Dispatcher-Grenzen werden als Infrastruktur dokumentiert, nicht durch Erlaubnis- oder Teständerungen umgangen. |

### Offene Backlog-Einträge

Alle 86 nicht ausdrücklich geschlossenen Zeilen sind unten zugeordnet.
Historisch bereits behandelte Teilpunkte werden dem Reviewer zur Pflege
benannt; dieser Plan schließt keinen Backlog-Eintrag selbst. Die
Terminierungen für bestehende Befunde werden übernommen. ADR-035 gilt
laut eigenem Status für M1b–M1d; seine erleichterte Blocking-Regel wird
nicht auf neue M3b-Befunde ausgedehnt.

| ID | Behandlung in M3b oder begründete Vertagung, Zuständigkeit und Zeitpunkt |
| --- | --- |
| BL-01 | Berücksichtigt: auf die sechs M3b-Kriterien begrenzter Umfang. Die Priorisierung gegenüber AP1 und dem 26.11. bleibt beim Betreiber. |
| BL-02 | Vertagt an Betreiber/Paper-Arbeit: Literaturabgrenzung betrifft den Publikationsanspruch, nicht die PB-/Lenth-Implementierung; vor Veröffentlichung fortführen. |
| BL-03 | M1d hat den Zwei-Stufen-Volllauf und seinen begrenzten Befund berichtet. Weitere Generalisierung/Ersatzverfahren bleiben ein eigener Statistikkern-/AP5-Auftrag; M3b ändert keine latenten Fits. |
| BL-04 | M1d hat die Intervallüberdeckung einschließlich ndc-Überdeckung berichtet. Weitergehende Bootstrap-Forschung bleibt AP5; kein Bootstrap-Eingriff für M3b. |
| BL-05 | Memorisierungsvorbehalt und getrennte AP1-Auswertung erhalten; Betreiber berücksichtigt die Grenzen bei der Endauswertung. M3b ändert weder Items noch Referenzen. |
| BL-06 | Betreiber: Modellzugang und Umleitungsprüfung der Harness-Logs. Als Betriebsaufgabe vertagt; kein Zusammenhang mit der deterministischen Robustheitsberechnung. |
| BL-07 | Routing-/Provider-Regeln erhalten. Generation-Stichprobe und Entscheidung über Wiederholungstage bleiben beim Betreiber während AP1; M3b führt keine API-Erhebung aus. |
| BL-08 | Vertagt an Betreiber/AP7 vor Partnerdatennutzung: Datenschutzvereinbarung gehört nicht zu den M3b-Eingaben. |
| BL-09 | Berücksichtigt: geschützte Lenth-Daten bleiben lokal und werden nur gelesen; öffentliche Unit-Tests verwenden synthetische Daten, Literaturangaben verweisen auf die Anker. |
| BL-10 | Betreiber/Paper: Go/No-Go und Einreichung hängen an M1-Abnahme und AP1-Endauswertung. M3b liefert seinen Validierungsbeitrag, trifft die Publikationsentscheidung nicht. |
| BL-11 | Betreiberentscheidung vom 04.11. für M3b vor M3a/M3d berücksichtigt. Dashboard-Abgleich und weitere Budgetentscheidungen bleiben Betreiberarbeit; kein Manifest-Eingriff durch den Builder. |
| BL-13 | Berücksichtigt durch gemessene M3b-Laufzeiten und einen einmaligen abschließenden Paketcheck; Gate-Budgets und Zeitlimits bleiben Betreiberzuständigkeit. |
| BL-14 | Für M3b durch Literaturwerte, unabhängige Mini-Referenzen, Laufzeitorakel, H0-Entscheidungsvergleich und Mutation adressiert. Die schon abgenommenen Kernnachweise aus M1 werden erhalten. |
| BL-15 | Vertagt auf M3a/K-M3a-2: Fleiss-Implementierung und zugehörige Dokumentation betreffen `msa_agreement()`. |
| BL-17 | Vertagt auf M3d/K-M3d-3; Live-Lauf bleibt Betreiber/AP2. Backend- und Replay-Code gehört nicht zum M3b-Pfad. |
| BL-18 | Bootstrap-Meldung ist laut M1c behandelt; SHA-256-Bericht bleibt M3d/K-M3d-5. Für M3b bleibt das Berichtsobjekt unverändert. |
| BL-20 | Engine-/wine-Trennung ist in M1b umgesetzt. Weitergehende Kovariatenschnittstellen gehören in einen eigenen Statistikauftrag, nicht in M3b. |
| BL-21 | Reviewer entscheidet bei künftiger Ankerpflege über das geschachtelte NIST-Beispiel. Kein K-M3b-Kriterium verlangt diesen Datensatz. |
| BL-22 | Gepoolte AIAG-Rechnung und Unterschied mit Wechselwirkung sind M1a/K-M1a-2 zugeordnet und bereits berichtet; Reviewer kann den historischen Status pflegen. Kein M3b-Rechenbedarf. |
| BL-23 | NIST-Präzisionsbefunde bleiben in `validation.Rmd`; M3b übernimmt weder andere Toleranzen noch Änderungen des REML-Kerns. Weitere Numerikarbeit separat. |
| BL-25 | Berücksichtigt: vollständige M3b-Anker liegen vor. Etwaige Nachträge erfordern Reviewer und ADR im selben Meilenstein; keine Builder-Änderung an Ankern. |
| BL-28 | Betreiber/AP1: Schlüssel, Guthaben und Limits. M3b benötigt ausschließlich lokale Tests; keine Abhängigkeit von Zugangsdaten. |
| BL-29 | Betreiber führt die Infevers-Klärung vor einer Veröffentlichung der Referenzklassen fort. M3b benötigt keine INSAID-Referenzdaten. |
| BL-30 | Vertagt auf Betreiber/AP2: Pages, About, Topics, Zenodo und DOI gehören zur Veröffentlichung. |
| BL-31 | Betreiber: Git-Identität vor einem Push prüfen. Der Builder führt in dieser und der folgenden Modellphase keine Git-Kommandos aus. |
| BL-33 | Betreiber: CLI-/Sandbox-Voraussetzungen bei Betriebswartung prüfen. M3b verwendet die vorhandene Umgebung ohne Freigabe- oder Konfigurationsänderung. |
| BL-34 | Betreiber legt Erreichbarkeit im RUNBOOK fest. Eskalationsweg bleibt das Rollenprotokoll mit `ESCALATION-M3b.md` als einzigem Human-Touchpoint. |
| BL-35 | Vertagt in die Harness-/Template-Wartung: Benachrichtigungslogik liegt im Betreiber-Territorium und beeinflusst keine M3b-Zahl. |
| BL-36 | Betreiber entscheidet bei Bedarf über den Dateisystemstandort. M3b liest gezielt kleine Eingaben; kein Repo-Umzug oder Rohdatenimport. |
| BL-37 | Dashboard-/Kostenspur bleibt Betreiber-/Template-Arbeit zusammen mit BL-11; keine fachliche M3b-Abhängigkeit. |
| BL-39 | Beschaffungsentscheidungen bleiben beim Betreiber für die betreffenden Vorhaben. Die für M3b erforderlichen Quellen/Anker sind vorhanden. |
| BL-40 | Weitere Konkordanzquellen bleiben Betreiber-/Reviewer-Arbeit für Literaturvergleich und Paper. M3b verwendet PB-, Lenth- und Daniel-Quellen. |
| BL-41 | Landis-&-Koch-Bezeichnungen erst nach Quellenklärung zitieren; Betreiber/Reviewer vor AP1-Publikation. Für M3b kein Kappa-Band und keine Beschaffung nötig. |
| BL-42 | M3b-Anteil adressiert: beide Lenth-Beispiel-CSV und die Kontrasttabelle gegen ANK-81 gehasht; alle stimmen. Originalabgleich ist laut ACC-2 erledigt. Weitere AIAG-Blätter bleiben Betreiber/Reviewer vor M3a. |
| BL-43 | Live-Katalog-/Preisprüfung bleibt Betreiber vor API-Betrieb/Endbericht. M3b erhält die festgelegte AP1-Konfiguration und führt keine Netzprüfung aus. |
| BL-44 | Vertagt auf Reviewer/M3a/K-M3a-2: Varianzformel für Fleiss-Kappa hat keinen Bezug zu Lenth. |
| BL-45 | Betreiber aktualisiert externe Projektunterlagen nach Meilensteinabschluss; M3b-Handoff/PROGRESS liefern die interne Grundlage. |
| BL-46 | Berücksichtigt: abschließender Paketbau einschließlich vorhandener Vignetten; der neue Methodenabschnitt führt keine Simulation aus. Timeout-Steuerung bleibt beim Betreiber. |
| BL-47 | Betreiber/Paper pflegt die korrekte VariantBench-Zuschreibung vor Veröffentlichung. M3b führt weder diesen Datensatz noch eine neue Zitierung ein. |
| BL-48 | Die aktuelle Zuordnungstabelle `docs/gates-auswahl.md` nennt K-M3b-1 bis K-M3b-6. Eine maschinelle Gate-Kriterienprüfung bleibt Betreiber-/Template-Arbeit; der Reviewer prüft die Zuordnung. |
| BL-49 | M1a-Optimiererentscheidung und ANK-TOL.reml_anova erhalten. Für die Robustheitsnachweise gelten die eigenen Einträge arithmetic/frf2_unrepx; keine REML-Änderung. |
| BL-50 | Vertagt auf M3c/K-M3c-6 nach der Betreiberpriorisierung: Satterthwaite-Planungsbericht gehört nicht zum Screening. |
| BL-51 | Interne `acmg_*`-Schnittstellen erhalten. Exportentscheidung bleibt Betreiber/ADR nach AP1; M3b ergänzt keinen Export. |
| BL-52 | Die erneute AP1-Auswertung mit dem abgenommenen M1-Code ist jetzt Betreiberaufgabe. M3b erhält dafür den Standardpfad; Store und Erhebung bleiben außerhalb des Arbeitsbaums. |
| BL-55 | Berücksichtigt: keine eigenen Artefakte in fremden Repo-Pfaden, lesende Integritätsprüfung. Gleichzeitige Betreiberänderungen und Rollback-Verhalten bleiben Betreiber-/Template-Thema. |
| BL-57 | Direkt adressiert: `transform = "none"` hinter den vier Snapshot-Argumenten, Prüfung von Position/Vorgabe und unverändertem Standardaufruf. |
| BL-60 | Vertagt zur Vorbereitung von M3d/K-M3d-3: ellmer/httr2-Replay einschließlich Streaming untersuchen. M3b nutzt diese Backends nicht. |
| BL-64 | Quantil-Entkopplung vertagt auf die nächste AP1-/M3d-Pflege; freigegebener Plan bleibt bei Typ 7. Die Änderung ist für PB/Lenth nicht erforderlich. |
| BL-68 | Lageabhängige Store-Fehlermeldung vertagt auf M3d/CLI-Pflege. Persistenz- und Erhebungsverhalten sind vom M3b-Auftrag unabhängig. |
| BL-70 | Status-, Timeout- und STOP-Befunde bleiben Betreiber-/Template-Wartung. M3b ändert weder Steuerlogik noch Phasenbudget. |
| BL-71 | Betreiber entscheidet vor AP1-Endauswertung über archivbasierte Memorisierungskennzeichen beziehungsweise deren Grenze im Bericht; Umsetzung nur mit ADR/Golden-Verfahren. Keine Änderung des Itemsatzes in M3b. |
| BL-72 | Berücksichtigt: Toleranzen über geprüfte Schlüssel, Ressourcen über Paket-/Repo-Kontext auflösen, portable Tests und keine neue Fork-Parallelisierung. Die alten REML-Fälle bleiben unverändert. |
| BL-73 | Erläuterung der Pilotspalten und Sol-Kostennachrechnung vertagt auf AP1-Berichtspflege/M3d vor dem Endbericht; kein Eingriff in Robustheitseffekte nötig. |
| BL-74 | Betreiber plant AP1-Blöcke und Laufzeiten; eine Parallelisierung realer Aufrufe erfordert einen eigenen Auftrag/ADR. M3b hat keinen Erhebungslauf. |
| BL-75 | Bereinigung der Latenzkennzahlen um Netzwartezeiten bleibt AP1-Berichtspflege vor dem Endbericht, gegebenenfalls M3d. Die M3b-Schätzungen verwenden keine Latenzen. |
| BL-77 | Berücksichtigt durch wörtliche, verortete Spec-Verweise; weitere QA-Prompt-/Template-Pflege bleibt Betreiber/Reviewer. |
| BL-79 | Archivierung vollständiger Mutationsberichte bleibt Betreiberarbeit. Der M3b-Handoff verweist nur auf tatsächlich vorhandene Läufe und behauptet keinen Score aus einem roten Vorlauf. |
| BL-80 | Betreiber berichtigt bei Spec-Pflege die Größenordnung im NIST-Text; weder Kriterien noch M3b-Code werden dafür geändert. |
| BL-81 | PROGRESS M1b BUILD, E3, dokumentiert die benannte Zurückweisung fehlender Gruppierungen. Reviewer kann den historischen Eintrag abgleichen; kein erneuter `msa_fit()`-Umbau in M3b. |
| BL-84 | Freiwillige Testlücken im numerischen Kern vertagt auf dessen Nacharbeit nach dem 26.11.; `R/fit.R` bleibt in M3b unverändert. Aktuelle Robustheitsmutanten werden separat behandelt. |
| BL-85 | Berücksichtigt: keine alten Äquivalenzfreigaben übernehmen. Etwaige neue Claims einzeln am endgültigen Quelltext belegen; Schlüssel-/Hash-Härtung und Freigaben bleiben Betreiber/Reviewer. |
| BL-86 | Bekannte Socket-/Dispatcher-/Zeitprüfungsgrenzen als Infrastruktur behandeln; reguläre Mutation beim Orchestrator, keine Berechtigungsumgehung oder Änderung der Prüfregeln. |
| BL-87 | Weiter offen, trotz früherer Zielmarke vor M1d. Abbruchkriterium und Hochpräzisionsraster in eigenem Statistikkern-Auftrag zusammen mit BL-108 nach dem 26.11. behandeln; dokumentierte Grenzen erhalten. PB/Lenth benutzt diesen Fitpfad nicht. |
| BL-91 | Latente Permutations-/Ankerfrage bleibt beim Reviewer vor weiterer Statistikkern-Pflege; Dokumentationshinweis erhalten. Keine neue Engine-Toleranz für M3b. |
| BL-93 | Reviewer behebt die zwei veralteten lme4-Helfer bei Abnahmepflege. Für den Builder nonblocking und fremdes Territorium; kein Produkt-Scheinfix. |
| BL-100 | Wie im Backlog auf nach dem 26.11. vertagt: Identifizierbarkeit des numerischen Durchreichwegs, eigener Statistikkern-Auftrag. M3b verwendet keine Fits mit `subset` oder Gewichten. |
| BL-101 | Wie terminiert nach dem 26.11.: Auswahl latenter Terme bei Gewicht null. Bestehende Einschränkungsdokumentation erhalten; kein Zusammenhang mit der neuen Antworttransformation. |
| BL-102 | Verbleibende M1-Mutanten nach dem 26.11. bearbeiten. Keine Freigabe ohne Beweis und keine Anrechnung des alten Scores auf M3b. |
| BL-103 | Projektwiederherstellung und Signal-/Restore-Fix laut Nachtrag vorhanden; Template-Übernahme bleibt Betreiberarbeit. Aktuelle M3b-Dateien werden vor BUILD erneut gehasht, fehlende Eingaben nicht rekonstruiert. |
| BL-105 | Infrastrukturklassifikation fehlender geschützter Eingaben bleibt Betreiber-/Template-Auftrag. Vorprüfung der Lenth-Dateien vermeidet einen bekannten Anlass; Rollenrunden oder Gate-Status werden nicht verändert. |
| BL-106 | Berücksichtigt: keine Betreiber-/Zustandsänderungen durch den Builder und keine Git-Kommandos. Audit-Regel für zwischenliegende Betreiber-Commits bleibt Betreiberarbeit. |
| BL-107 | Aktuell lesend bestätigt: echter R-Scope, Ratchet 2 und fünf Rework-Runden; die M1b/M1d-Scope-Sperren sind nicht mehr wirksam. No-match-Diagnose und rundenübergreifender Berichtscache bleiben Harness-Arbeit. |
| BL-108 | Wie terminiert nach dem 26.11.: Abbruchregel bei sehr hoher Wiederholbarkeit auf x86-64/arm64 untersuchen. Die benannte Fitgrenze ist unabhängig von M3b. |
| BL-109 | Latente Skalenbenennung ist in M1c behandelt; AP1-Sensitivitätslauf mit Interaktionen bleibt Betreiberaufgabe bei der Endauswertung. M3b verändert diesen Fit nicht. |
| BL-110 | CSV-/Merge-Härtung nach dem 26.11. im dafür vorgesehenen Studienauftrag. Reguläre Betreiberdateien bleiben unverändert; M3b erzeugt keine Klasse-B-Datei. |
| BL-113 | Vertagt auf M3a/Übereinstimmungsdokumentation und AP1-Endbericht: unterschiedliche Modal-/Kappa-Regeln ausdrücklich benennen. Kein Kappa-Eingriff in M3b. |
| BL-114 | Vor CRAN-Einreichung als gemeinsamer Paketierungs-/Betreiberauftrag behandeln; für den 26.11. laut Backlog keine Änderung. M3b erhält vorhandene Vollstudien und Build-Regeln. |
| BL-115 | UTF-8-Laufkontext beibehalten; locale-unabhängige Studienhashes nach dem 26.11. bearbeiten. M3b ändert weder Studiencode noch Sessiondateien. |
| BL-117 | Validierung künstlich veränderter M1d-CSV bleibt nach dem 26.11. terminiert. Keine neue M3b-CSV-Schnittstelle und keine Änderung der abgenommenen Befundleser. |
| BL-119 | Betreiberentscheidung vor Paper-Nutzung der llm-stability-Zahlen; bis dahin Werte nur als Ergebnis der dokumentierten Extraktionsregel verwenden. Eine neue Salienzregel braucht einen eigenen Daten-/ADR-/Abnahmeauftrag. |
| BL-121 | Release-Arbeit nach dem 26.11. wie ausdrücklich terminiert. DESCRIPTION wird in M3b nur um die nötigen Suggests ergänzt; die pkgdown-URL ist kein M3b-Kriterium. |
| BL-122 | Betreiber-Kontrolllauf nach done/M1d außerhalb des Harness bleibt offen bis zu seinem Ergebnis. Der neue M3b-Mutationslauf ersetzt diesen Statistikkernbeleg nicht. |
| BL-123 | Für M3b geprüft: keine globale Baseline-Datei vorhanden. Betreiber setzt sie vor jedem weiteren M3-Scope wie verlangt zurück; scopebezogene Baselines bleiben Harness-Arbeit. |
| BL-124 | Hinweis und Untersuchung der Laplace-Grenze in separatem Statistikkern-Auftrag vor belastbarer Verwendung dieses Varianzbereichs; zusätzliche Recovery/Quadratur braucht eigene Belege. M3b ändert ausschließlich den Robustheitspfad und übernimmt keine nackten empirischen Zahlen. |
| BL-125 | Nach erster Veröffentlichung als Option für zusätzliche Kontraste vertagt, wie ADR-050 festlegt. AP1-Sensitivität bleibt eine ausgewiesene Zusatzanalyse des Betreibers; M3b verwendet weiter nur die ausgewählten Faktorspalten. |
| BL-126 | Konservative Interpretation jetzt in der Hilfe umsetzen. Option für kalibrierte Schranken erst nach erster Veröffentlichung; AP1-Schlussauswertung kann die vereinbarte Sensitivität ausweisen. Vorgabe bleibt Lenth 1989. |

Die übrigen 40 Zeilen sind im Backlog ausdrücklich erledigt und werden
nicht wieder geöffnet: BL-12, BL-16, BL-19, BL-24, BL-26, BL-27, BL-32,
BL-38, BL-53, BL-54, BL-56, BL-58, BL-59, BL-61, BL-62, BL-63, BL-65,
BL-66, BL-67, BL-69, BL-76, BL-78, BL-82, BL-83, BL-88, BL-89, BL-90,
BL-92, BL-94, BL-95, BL-96, BL-97, BL-98, BL-99, BL-104, BL-111,
BL-112, BL-116, BL-118 und BL-120. Ihre fortgeltenden Regeln, etwa die
Windows-Hinweise und die korrigierte Robustheitsinterpretation, bleiben
berücksichtigt. Template-Nachführungen bleiben Betreiberarbeit.

## Testplan

### Abnahme und unabhängige Belege nach BUILD

| Kriterium | Unveränderter Prüfweg und erwarteter Nachweis |
| --- | --- |
| K-M3b-1 | `test-m3b-1-pb-matrices.R`: alle fünf vollständigen Matrizen gegen Generatoren aus ANK-80 und unabhängige Konstruktion; exakt `H'H = N I`, balancierte Spalten, korrekte letzte Zeile und Identität von data.frame-Spalten und `coded`. |
| K-M3b-2 | `test-m3b-2-frf2.R`: FrF2-Orakel zur Laufzeit mit `boxtyssedal = FALSE`, explizit gefundene Zeilen-/Spalten-/Vorzeichenabbildung und eintragsweiser Vergleich. J3-Invarianten und positive/negative Kontrollen bleiben erhalten. |
| K-M3b-3 | `test-m3b-3-lenth.R`: lokale Beispiele II/IV mit ANK-81-Prüfsummen; publizierte Kontraste, Mittelwerte und PSE/ME/SME; Stufenmittel und `2 * coef(lm())`; Tabelle 1 bis m = 255; strikter Trimmungsgrenzfall; beide Aktivitätsflags; unrepx-PSE und DoE.base-PSE/ME/SME. Drucktoleranzen aus ANK-81, Rechenreserve aus ANK-TOL.arithmetic und Orakeltoleranz aus ANK-TOL.frf2_unrepx auch für SME. |
| K-M3b-4 | `test-m3b-4-half-normal.R`: tatsächlich aufgezeichnete Grafik bei m = 7, 11, 26, 31, Positionen gegen Formel und ANK-82, sortierte Effektbeträge sowie Daniel/1959 in Achse, Randtext oder Legende. |
| K-M3b-5 | `test-m3b-5-help-page.R` prüft die erzeugte Hilfe. `tests/simulation/test-lenth-h0.R` prüft getrennt die beiden H0-Szenarien samt vollständigem Entscheidungsvergleich und berichtet Raten, MCSE und Abstand zu alpha. |
| K-M3b-6 | `test-m3b-6-design-transform.R`: kleinste Größe für k = 1 bis 23, benannte Listen und Bereichsende, Spaltenuntermenge, seedabhängige reproduzierbare Zeilenpermutation und Stufenlabels; additive Signatur, Identität bei `none`, Logit-Rechnung, klare Fehler bei 0/1 und unbekannter Option. |

Die Klasse-A-Studie folgt ihrem vorhandenen ADEMP-Plan: je 12 Läufe mit
8 und 11 Faktoren, unabhängiges Normalrauschen unter H0,
`n_sim = ANK-06.value.n_sim_min`, Seeds 20261112 und 20261115 und
RNG `Mersenne-Twister/Inversion/Rejection`. ME wird je Effekt ausgewertet
als Mittel der aktiven Anteile je Plan; dessen MCSE ist
`sd(Anteile je Plan) / sqrt(n_sim)`. SME wird als Anteil der Pläne mit
mindestens einem aktiven Effekt mit `sqrt(p * (1 - p) / n_sim)` berichtet.
Beide Raten müssen `<= alpha + ANK-TOL.mc_factor.pass * MCSE` sein;
jede einzelne Entscheidung muss der Mini-Referenz gleichen.
Die Gesamtlaufzeit des Klasse-A-Ordners bleibt gegen ANK-TOL.sim_runtime
zu beurteilen. Der Builder verändert weder diese Studie noch ihre Seeds,
Umfänge, Prüfungen oder Schwellen.

### Zusätzliche Unit-/Eigenschaftsprüfungen und Regressionen

- **Transformation:** pb_design und gewöhnlicher data.frame mit expliziten
  Faktorenspalten, Faktoruntermenge und anderes gültiges `alpha`.
  Vergleich der Logit-Effekte mit `2 * coef(stats::lm(log(p / (1 - p)) ~ X))`
  sowie der vollständigen Ausgabe mit dem bisherigen Pfad auf separat
  transformierten Daten. Antwortmittel und -SD werden ebenfalls geprüft.
- **Fehler und Grenzen:** 0/1 an mehreren Positionen, Werte unter 0/über 1,
  fehlende/nicht endliche/nicht reelle oder nicht numerische Antworten,
  falsche Antwortlänge und ungültige Optionswerte. Benannte Fehler vor
  Rechenausgaben; der Standardpfad akzeptiert weiterhin gültige numerische
  Antworten einschließlich 0/1. Gültige Anteile nahe den Intervallgrenzen
  werden ohne zusätzliche, erfundene Schranke verarbeitet.
- **Invarianzen:** gemeinsam permutierte Design-/Antwortzeilen, Faktor-
  umbenennung und Spaltenvorzeichen; im untransformierten Pfad Verschiebung
  und Skalierung, im Logit-Pfad Komplement `p -> 1-p` sowie eine feste
  Verschiebung der Log-Odds. Nach Faktorzuordnung Effekte/Schranken und
  Entscheidungen vergleichen, fern von Entscheidungsschwellen; Toleranzen
  aus ANK-TOL. Die Tests enthalten feste Seeds.
- **Bestehende Randfälle:** eine ausgewählte Spalte, konstante Antworten
  mit PSE null, klare bestehende Eingabefehler und reproduzierbare
  PB-Randomisierung einschließlich Wiederherstellung des RNG-Zustands.
  Synthetische Daten bleiben klein und ausdrücklich als solche markiert.
- **Kompatibilität:** vor BUILD gesicherte Funktionen ohne Git auf denselben
  Eingaben auswerten; vollständige Standardobjekte vergleichen. Die bereits
  vorhandenen Unit-Tests für Robustheit, AP1 und Bericht weiter ausführen.
  Der vollständige K-M1d-8-Vergleich mit `done/M1c` und der vollständige
  K-M0-7-Test bleiben beim Orchestrator, weil ihre Prüfhilfen Git aufrufen.
  Lokal können die geladenen Signaturen direkt gegen ANK-02 geprüft werden.

Geplante lokale Prüfbefehle nach der letzten Produktänderung, jeweils aus
der Repo-Wurzel mit `REPO_ROOT`, `TZ=Europe/Berlin` und `pdf(NULL)` für
Grafiken: `Rscript --vanilla orchestrator/lib/r-deps.R --check-only`;
`testthat::test_dir("tests/testthat", filter = "^robustness-",
load_package = "source")`; derselbe M3b-Abnahmeaufruf und derselbe
H0-Aufruf wie unten; anschließend die vollständige Unit-Suite und
betroffene, Git-freie Integrationsprüfungen. Zusätzliche Orakel in
öffentlichen Unit-Tests verwenden `skip_if_not_installed()` nach
`docs/01` §5; die Abnahmetests überspringen fehlende Pakete nicht.

`R CMD build --no-manual` und `R CMD check --as-cran --no-manual` laufen
auf einer öffentlichen Paketkopie außerhalb des Arbeitsbaums, einschließlich
Vignettenbau und installierter Unit-Tests. Eingefrorene Abhängigkeiten und
Prüfregeln bleiben erhalten. Ausgeführte Befehle, echte Outputs, Skips und
Infrastrukturgrenzen werden im BUILD-Handoff einzeln ausgewiesen.

Die vollständige kumulative Suite einschließlich Git-basierter Regressionen,
QA, deps/lint/tests/trace/territory/mutgate/golden-adr und die jeweils fälligen
Betreibergates läuft anschließend durch den Orchestrator. Für M3b ist
`R/robustness.R` die geplante geänderte Datei innerhalb des R-Scope;
Mutation umfasst die ganze Datei, nicht nur die neuen Zeilen.
ANK-32 bestimmt Schwelle/Floor und Ratchet. Die neuen M3b-Abnahmetests
bleiben im Mutationslauf, die Klasse-A-Studie bleibt außerhalb.
Ein Score wird erst aus einem tatsächlich abgeschlossenen Gate-Lauf berichtet.

### In dieser PLAN-Phase ausgeführte Bestandsdiagnose

Umgebung lesend geprüft: R 4.6.1, testthat 3.3.2, pkgload 1.5.3,
roxygen2 8.1.1, FrF2 2.3.5, DoE.base 1.2.5 und unrepx 1.0.2 vorhanden.
Es wurde kein Paket installiert. Die drei CSV-Dateien aus ANK-81 wurden
mit Python `hashlib.sha256(Path(...).read_bytes())` gegen ihre Ankerwerte
verglichen. Echter Output:

```text
reference/quellen/data/lenth/example_II.csv: SHA-256 matches ANK-81
reference/quellen/data/lenth/example_IV.csv: SHA-256 matches ANK-81
reference/quellen/data/lenth/table3_contrasts.csv: SHA-256 matches ANK-81
Lenth QUELLE.txt: present
M3 mutation baseline exists: False
```

Die gelesenen M1d-Fakten melden Runde 5, `result: pass` beziehungsweise
`verdict: PASS`, `blocking: []` (`orchestrator/state/M1d/gates.json`,
`orchestrator/handoff/M1d/verdict-code.json`). Das sind historische
Orchestrator-/Reviewer-Fakten, keine neuen Gate-Läufe.

Beide folgenden R-Blöcke wurden jeweils als
`TZ=Europe/Berlin Rscript --vanilla -e '<R-Block>'` ausgeführt.
Die Setup-Dateien wurden vorher auf ausführbare Top-Level-Ausdrücke
geprüft; die gewählten Tests rufen kein Git auf.

```r
Sys.setenv(REPO_ROOT = normalizePath("."))
grDevices::pdf(NULL)
testthat::set_max_fails(Inf)
started <- proc.time()[["elapsed"]]
res <- testthat::test_dir("tests/acceptance", filter = "^m3b-",
  load_package = "source", reporter = "summary", stop_on_failure = FALSE)
tab <- as.data.frame(res)
cat(sprintf(paste0("M3b baseline: %d blocks; %d failed expectations; ",
  "%d error blocks; %d skips; %d passed expectations; elapsed %.2f s\n"),
  nrow(tab), sum(tab$failed), sum(tab$error), sum(tab$skipped),
  sum(tab$passed), proc.time()[["elapsed"]] - started))
for (f in unique(tab$file)) {
  z <- tab[tab$file == f, ]
  cat(sprintf("%s: %d blocks; failed %d; errors %d; passed %d\n",
    f, nrow(z), sum(z$failed), sum(z$error), sum(z$passed)))
}
quit(status = as.integer(any(tab$failed > 0 | tab$error)))
```

Echter Schlussoutput, Exit 1:

```text
M3b baseline: 27 blocks; 12 failed expectations; 2 error blocks; 0 skips; 414 passed expectations; elapsed 12.50 s
test-m3b-1-pb-matrices.R: 4 blocks; failed 0; errors 0; passed 101
test-m3b-2-frf2.R: 2 blocks; failed 0; errors 0; passed 11
test-m3b-3-lenth.R: 7 blocks; failed 0; errors 0; passed 183
test-m3b-4-half-normal.R: 3 blocks; failed 2; errors 0; passed 13
test-m3b-5-help-page.R: 3 blocks; failed 3; errors 0; passed 0
test-m3b-6-design-transform.R: 8 blocks; failed 7; errors 2; passed 106
```

Die zwei Plotfehler betreffen denselben Beschriftungstest bei zwei
Plänen. Drei Erwartungen betreffen die Hilfeseite. Die übrigen
Fehlschläge/Fehler kommen vom noch fehlenden `transform`-Argument,
darunter `unused argument (transform = "none")` und
`unused argument (transform = "logit")`.
Der SummaryReporter zeigt höchstens zehn Fehlerdetails an; die
anschließende Ergebnistabelle umfasst alle 27 ausgeführten Testblöcke.

```r
Sys.setenv(REPO_ROOT = normalizePath("."))
testthat::set_max_fails(Inf)
started <- proc.time()[["elapsed"]]
res <- testthat::test_dir("tests/simulation", filter = "^lenth-h0$",
  load_package = "source", reporter = "summary", stop_on_failure = FALSE)
tab <- as.data.frame(res)
cat(sprintf(paste0("Lenth H0 baseline: %d blocks; %d failed expectations; ",
  "%d error blocks; %d skips; %d passed expectations; elapsed %.2f s\n"),
  nrow(tab), sum(tab$failed), sum(tab$error), sum(tab$skipped),
  sum(tab$passed), proc.time()[["elapsed"]] - started))
quit(status = as.integer(any(tab$failed > 0 | tab$error)))
```

Echter Output, Exit 0:

```text
K-M3b-5 (tests/simulation/test-lenth-h0.R, 1.9 s):
N = 12,  8 factors: per effect (ME) 0.02325 (MCSE 0.00222), distance to alpha 0.05: -0.02675 (-12.0 MCSE); per plan (SME) 0.01500 (MCSE 0.00384), distance to alpha 0.05: -0.03500 (-9.1 MCSE); n_sim 1000, seed 20261112, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
N = 12, 11 factors: per effect (ME) 0.02891 (MCSE 0.00231), distance to alpha 0.05: -0.02109 (-9.1 MCSE); per plan (SME) 0.02500 (MCSE 0.00494), distance to alpha 0.05: -0.02500 (-5.1 MCSE); n_sim 1000, seed 20261115, RNG Mersenne-Twister/Inversion/Rejection, R version 4.6.1 (2026-06-24), llmsa 0.1.0
Lenth H0 baseline: 1 blocks; 0 failed expectations; 0 error blocks; 0 skips; 6 passed expectations; elapsed 5.25 s
```

In PLAN wurden kein Produktcode, Test, Anker oder Gate verändert und
keine Git-Kommandos ausgeführt. BUILD, vollständige Gates,
Territoriumsprüfung und Abnahme stehen für M3b noch aus.
