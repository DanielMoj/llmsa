# PLAN-UPDATE — M3a, Runde 2

## Ziel

Builder · PLAN, Runde 2 · 05.11.2026. Dieses Update ergänzt `PLAN.md` und ersetzt dessen Aussagen zu den nachstehend präzisierten Punkten. Ziel bleibt die Umsetzung und unabhängige Prüfung von K-M3a-1 bis K-M3a-7. In dieser Phase wird ausschließlich diese Handoff-Datei geschrieben; Produktarbeit und die unten geplanten Tests gehören in BUILD.

Gelesen wurden AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md, PROGRESS.md, BACKLOG.md, orchestrator/handoff/SCHEMA.md, orchestrator/LESSONS.md, der bisherige Plan, PLAN-REVIEW.md, CRITERIA.json einschließlich ACC-1 bis ACC-17, alle sieben M3a-Abnahmedateien samt `setup-m3a.R` und die Bias-Klasse-A-Simulation. Fachliche Grundlage sind `docs/04-weitere-bausteine.md` M3a, `docs/01-fachspezifikation.md` insbesondere §2, §4, §5 und §8, die Formelsammlung §5, §6 und §9 sowie ADR-022, ADR-043 und ADR-052. Eine `ARBITER.md` für M3a liegt nicht vor.

ADR-052 Nr. 1–16 wird übernommen. Insbesondere sind die drei geschützten AIAG-Datenblätter laut Reviewer am Seitenbild abgeglichen; ACC-2 ist erledigt (ADR-052 Nr. 15, PLAN-REVIEW Prüflauf 1). Der frühere Vorbehalt des Plans entfällt. Das ist ein übernommener Reviewer-Beleg, keine eigene Quellenprüfung dieser Runde. Die alten `data_file.status`-Texte der Anker begründen keine neue Anforderung an den Betreiber.

### Antworten auf alle Einwand-IDs

- [E1] akzeptiert: Gemeinsame, reihenfolgeunabhängige Referenzauflösung für beide Funktionen; widersprüchliche Itemreferenzen führen in allen drei Eingabeformen zum benannten Fehler. `msa_agreement()` weist vorhandene Referenzkategorien außerhalb der ausdrücklichen oder aus Antworten abgeleiteten Skala mit einer englischen Fehlermeldung zurück. Beide Kappa-Felder erhalten ausschließlich vollständige, gültig kategorisierte Paare. Tests prüfen alle Gewichtungen, die vollständige Skala und die Rückwirkung auf AP1, M1d und Bericht. Bezug: docs/01 §2 Nr. 4; K-M3a-1/-5; ADR-052 Nr. 17.1.
- [E2] akzeptiert: `overall` und jede Zeile von `by_condition` erhalten das zusätzliche Feld `n_excluded`. Jede tatsächlich beobachtete Prompt×Modell-Bedingung bleibt sichtbar, auch mit `n = 0`. Druckausgabe und Berichtsteil 5 nennen die Ausschlusszahlen. Zählweise, Typen und Verhalten alter Objekte sind unten festgelegt. Bezug: docs/01 §5; K-M3a-5; ADR-052 Nr. 17.2.
- [E3] akzeptiert: Bias-Inferenz und beide OLS-Rechnungen verwenden eigene geschlossene Rechnungen mit relativer Erkennung numerischer Konstanz. Im Produktpfad werden weder `stats::t.test()` noch `stats::lm()`/`summary.lm()` aufgerufen. Numerisch konstante Abweichungen ergeben ein Punktintervall und undefinierte t-/p-Inferenz mit Hinweis; numerisch verschwindende Regressionsreste ergeben ein auf die Gerade zusammenfallendes Band. Ein Raster prüft die ganze Fehlerklasse. Bezug: docs/01 §2 Nr. 4; K-M3a-5/-6; ADR-022 Nr. 7; ADR-052 Nr. 17.3.
- [E4] akzeptiert: `fleiss` enthält genau `kappa`, die Fleiss-Druckzeile allein den Punktschätzer. Kein SE-Feld oder vermeintlicher SE-Platzhalter wird angelegt. `linearity_in_band` und `linearity_verdict` sind unbenannte Skalare der festgelegten Typen, auch im NA-Fall. Bezug: ACC-8/-9/-12; K-M3a-2/-6.
- [E5] akzeptiert: Die Bias-Tabelle erhält einen eigenen Abschnitt der Ebene zwei hinter dem vollständigen Bootstrap-Abschnitt. Der neue Rmd-Teil enthält keine Zahlenliterale; Einstellungen und Zahlen stammen aus Helfer, Ankern und Rechnung. Die Tabelle berichtet den Abstand zum Nominalniveau in MCSE und kennzeichnet Überschreitungen der Berichtsschwelle, ohne deshalb den Knit abzubrechen. In BUILD werden ganze Knits vor und nach der Änderung gemessen. Bezug: K-M3a-7; ACC-15; docs/01 §2 Nr. 3; ADR-048 Nr. 14.5.
- [E6] akzeptiert: Schnelle Unit-Tests prüfen die vollständigen Ausgaben beider Druckmethoden, den letzten Zeilenumbruch, die unsichtbare Rückgabe und sämtliche Fehlerzweige der geänderten Datei einschließlich genauer Meldungen und `conditionCall()`. Fachliche Zahlen werden zusätzlich unabhängig geprüft. Keine Mutationsausnahme wird eingeplant. Bezug: mutgate; ANK-32; ADR-051 Nr. 10; ADR-052 Nr. 18; BL-128.
- [E7] akzeptiert: Jeder Unit-Test, der `irr`, `psych` oder `DescTools` verwendet, beginnt vor deren Verwendung mit dem jeweiligen `skip_if_not_installed()`. Formeltests stehen in eigenen Blöcken und laufen auch ohne diese Pakete. Die Abnahmetests bleiben ohne solche Skips; Hilfe, Bericht und Vignette benötigen die drei Orakelpakete nicht. Bezug: docs/01 §5; ADR-051 Nr. 9.8.

Es bleibt kein Einwand strittig. Nach der Präzedenz Spec > Reviewer > Builder gelten die Reviewer-Auslegungen in ADR-052; dessen Nr. 17 sieht die Festschreibung der konkreten Regeln dieses Updates durch das Plan-Review der Runde 2 vor. Der Builder ändert in dieser PLAN-Phase weder das ADR noch Kriterien oder Verdicts.

## Dateien

Aktuelle Änderung: ausschließlich `orchestrator/handoff/M3a/PLAN-UPDATE.md`. Der folgende Umfang bezeichnet die spätere BUILD-Arbeit aus PLAN Runde 1 mit den Ergänzungen dieser Runde.

| Datei | Geplante Arbeit |
| --- | --- |
| `R/agreement.R` | Gemeinsame Referenzvalidierung; Cohen-Randfälle; Fleiss; Alpha-Ausschlusszählung; Attributnenner; Bias-Ausschlusszählung; stabile geschlossene Bias-/OLS-Rechnungen; Band, Urteil und Hinweise; vollständige Druckmethoden und roxygen. |
| `man/msa_agreement.Rd`, `man/msa_bias.Rd` | Aus roxygen generierte Dokumentation der Referenz-, Fehlwert-, Modal-, Gewichts- und Randfallregeln sowie aller zusätzlichen Felder. Generierung nötigenfalls in temporärer Paketkopie; nur diese Hilfeseiten übernehmen. |
| `inst/templates/validation_report.Rmd` | Abschnitt 4: allgemeine Modalregel gegenüber AP1 benennen. Abschnitt 5: Ausschlusszahlen, beide Regressionen, Freiheitsgrade, Handbuchurteil und Methodenhinweis; ältere Objekte unterstützen. |
| `inst/validation/agreement/bias_coverage.R` und `README.md` (neu) | Installierbarer sequenzieller Helfer und ADEMP-Dokumentation; berechnen mit dem geladenen `llmsa`-Namespace; geprüfte vorhandene Anker nutzen; vollständige Metadaten und RNG-Wiederherstellung. |
| `vignettes/validation.Rmd` | Eigener Bias-Abschnitt auf Ebene zwei, berechnete Tabelle mit MCSE-Abstand und Befundtext; vorhandene Abschnittsgrenzen und Klasse-B-Leser erhalten. |
| `DESCRIPTION`, `NEWS.md` | `irr`, `psych`, `DescTools` als Suggests; englische Beschreibung der Ergänzungen und behobenen Randfälle. |
| `tests/testthat/test-agreement-m3a.R` (neu) | Referenzformen und -konflikte, vollständige Kappa-Tafeln, Fleiss, Alpha-Zählung, Attributnenner, Modalregel und Invarianzen. |
| `tests/testthat/test-bias-linearity.R` (neu) | Ausschlusszählungen und leere Bedingungen; unabhängige t-/OLS-/Bandrechnungen; Rang-, Präzisions- und Skalierungsraster. |
| `tests/testthat/test-agreement-report.R` (neu) | Vollständige Druckausgaben, Fehlertexte, gerenderte Berichtsteile und Verhalten alter Objekte. |
| `tests/testthat/test-validation-bias.R` (neu) | Determinismus, vollständiger Nenner, MCSE, RNG auch im Fehlerfall, installierter Datenfluss und Einbindung der Quelle. Kleine Fixtures ersetzen keinen Überdeckungsnachweis. |
| `PROGRESS.md`, später zugewiesenes `orchestrator/handoff/M3a/REVIEW-INPUT.md` | Erst in BUILD: tatsächliche Änderungen, Befehle, Ergebnisoutput, Laufzeiten, Regressionen und verbleibende Befunde. |

Keine neuen Exporte oder Imports; keine Änderung an ANK-02 oder `NAMESPACE`. Die bestehende API wird nur additiv erweitert. Fit-, Bootstrap-, AP1- und Robustheitskern bleiben außerhalb der Produktarbeit. Abnahme-, Klasse-A-, QA-, Anker-, Quellen- und Betreiberdateien bleiben im jeweiligen Territorium; vorhandene Klasse-B-Ergebnisse werden nicht neu erzeugt.

## Schnittstellen

### Referenzen und Kategorienskala (E1)

`msa_agreement()` erhält weiterhin nur das neue Argument `fleiss = FALSE` hinter `weights`; die vorhandenen Argumente und Vorgaben behalten ihre Position. Die Signatur von `msa_bias(runs, reference, level = 0.95)` bleibt erhalten.

Die gemeinsame Referenzauflösung unterstützt unverändert benannten Vektor, `data.frame(item_id, reference)` und den Namen einer Spalte von `runs`. Sie bildet eine eindeutige Zuordnung je Item, bevor Kennzahlen berechnet werden:

- Kategorielle Referenzen werden als Kategorienamen verglichen, Bias-Referenzen nach numerischer Konvertierung. Faktoren werden über ihre Beschriftungen gelesen. Für Bias sind etwa `"2"` und `"2.0"` derselbe Wert.
- Mehrere identische, nicht fehlende Referenzen desselben Items sind zulässig. Zwei verschiedene nicht fehlende Werte führen zum englischen Fehler mit Item-ID und den widersprüchlichen Werten, unabhängig von Zeilenreihenfolge und Eingabeform. Beispiel: `Conflicting reference values for item_id 'i1': 2, 5.` Die Ausgabe der Konfliktwerte wird deterministisch geordnet.
- Liegt neben fehlenden Einträgen genau ein nicht fehlender Wert für ein Item vor, ist dieser die belegte Itemreferenz. Fehlt für ein Item jeder lesbare Referenzwert oder die Zuordnung ganz, bleibt seine Referenz fehlend. Das verändert keine Antwort und ergänzt keinen geschätzten Referenzwert. Tests unterscheiden diese itembezogene Zuordnung von einem vollständig unbelegten Item.
- Bei `msa_agreement()` ist die Skala entweder das übergebene `levels` oder unverändert die aus nicht fehlenden Antworten abgeleitete Skala. Jede einem Item aus `runs` zugeordnete nicht fehlende Referenz muss darin liegen. Andernfalls endet der Aufruf vor jeder Kennzahlenrechnung mit einer Meldung wie `` `reference` contains values outside `levels`: c. ``; alle betroffenen Kategorien und der Hinweis auf `levels` werden genannt. Das gilt auch, wenn die betreffende Antwort fehlt.
- Eine Vereinigung der Referenzkategorien mit der Vorgabeskala findet nicht statt. Damit ändern Referenzen weder die Positionsmetrik des Alpha noch K und die Gewichte einer bereits festgelegten Skala. Wer eine nur in der Referenz vorkommende Kategorie auswerten will, übergibt die vollständige Skala ausdrücklich.
- Beide Kappa-Felder filtern dieselben Arten unvollständiger Paare vor Kreuztafel und Nenner. Jede berücksichtigte Paarbeobachtung gehört genau einer Zelle an; die relative Tafel summiert sich zu eins. Für modales Kappa gilt zusätzlich die dokumentierte Modalregel. Leere Tafeln, eine einzige Skalenkategorie und entartete Nenner liefern `NA_real_` mit Kappa-Hinweis, kein `NaN`.

Alle neuen Eingabefehler sind englische, benannte Fehler mit `call. = FALSE`. Die Regeln gelten für alle drei Gewichtungen und beide Kappa-Felder. M2 übergibt die AP1-Klassen ausdrücklich; die Regressionstests prüfen trotzdem die gemeinsamen Aufrufpfade.

### Agreement-Felder und Attributnenner (E4; unveränderte Fachentscheidung)

Ohne angefordertes Fleiss bleibt das bisherige Objekt ohne `fleiss`-Element. Mit `fleiss = TRUE` kommt genau `list(kappa = <unbenannter numerischer Skalar>)` hinzu. Kein Name kann versehentlich als SE-Feld gelesen werden. Die Druckzeile lautet sinngemäß `Fleiss' kappa: <value>`; sie erwähnt keinen Standardfehler. Die bewusste Wahl ohne Standardfehler wird nur in der Hilfe erläutert.

Fleiss verwendet alle gültigen Bewertungen eines Items über Prompts, Modelle und Replikate. Alle beobachteten Items müssen dieselbe gültige Anzahl von mindestens zwei haben. Bei ungleichen Anzahlen, einem vollständig leeren Item oder sonst nicht schätzbarem Fleiss folgt `NA_real_` mit einem Hinweis auf Krippendorffs Alpha; Items werden nicht zur Herstellung eines balancierten Plans entfernt. Die übrigen Kennzahlen bleiben nutzbar.

Alpha behält die vier vorhandenen Bereiche und erhält `n_units_excluded`: gezählt werden je Bereich alle vor der Antwortfilterung beobachteten Einheiten mit weniger als zwei gültigen Bewertungen, einschließlich vollständig leerer Einheiten. Es werden keine unbeobachteten Kombinationen erzeugt. Die Hilfe ordnet `unweighted` → nominal, `linear` → ordinal und `quadratic` → interval ausdrücklich zu; Intervallabstände verwenden Skalenpositionen.

Trefferanteile verwenden gültige Antwort-Referenz-Paare. Beim Anteil vollständig richtiger Items geht nur ein Item mit mindestens einem gültigen Vergleich in den Nenner ein; ein vollständig leeres Item ist nicht automatisch richtig. Wiederholbarkeit benötigt mindestens zwei gültige Bewertungen in ihrer Gruppe. Allgemeine Modalwerte ignorieren fehlende Antworten; bei Gleichstand gewinnt die niedrigste der tatsächlich gebundenen Skalenkategorien, bei ausschließlich fehlenden Antworten bleibt der Modalwert fehlend. Berichtsteil 4 benennt diese Regel und die abweichende AP1-Regel ausdrücklich; AP1-Entscheidungen bleiben maßgeblich für die Anwendung (BL-113).

### Bias-Ausschlüsse und Ergebnisform (E2)

Antwort und zugeordnete Referenz werden numerisch gelesen. `NA`, `NaN` und nicht parsbare Werte gelten als fehlend. Positive oder negative Unendlichkeit ist ein benannter Eingabefehler; eine nicht endlich darstellbare Differenz endlicher Eingaben führt ebenfalls zu einer klaren Meldung. Eine Beobachtung ist genau dann gültig, wenn beide Werte vorliegen und ihre Differenz endlich ist.

`n_excluded` zählt je Eingabezeile die Vereinigung von fehlender/nicht lesbarer Antwort und fehlender/nicht lesbarer zugeordneter Referenz. Eine Zeile mit beiden Problemen zählt einmal. Nach obiger Referenzauflösung gilt `n + n_excluded = Zahl der Eingabezeilen`, insgesamt und je beobachteter Bedingung.

| Ergebnis | Festgelegte Form |
| --- | --- |
| `overall` | Benannter numerischer Vektor mit den bisherigen Feldern `n`, `bias`, `sd`, `lower`, `upper`, `p_value` in dieser Reihenfolge; `n_excluded` wird am Ende als numerischer Zählwert angehängt. `n` bleibt die Anzahl gültiger Paare. |
| `by_condition` | Bestehender Dataframe mit zusätzlicher numerischer Spalte `n_excluded` am Ende. Eine Zeile je tatsächlich beobachteter Prompt×Modell-Kombination aus den ungefilterten Eingaben; kein kartesisches Auffüllen. |
| Bedingung ohne gültiges Paar | `n = 0`, `n_excluded` gleich ihrer Eingabezeilenzahl; `bias`, `sd`, `lower`, `upper`, `p_value` jeweils `NA_real_`. Die Bedingung bleibt sichtbar. |
| Bedingung mit einem Paar | Mittelwert der einzigen Abweichung; SD, Intervallgrenzen und p-Wert `NA_real_`; Ausschlusszählung bleibt verfügbar. |
| Insgesamt kein gültiges Paar | Benannter Fehler mit Ursache und Ausschlusszahl; kein scheinbar auswertbares leeres Biasobjekt. |
| `n_items` | Bisherige Bedeutung bleibt: Anzahl Items mit gültigen Paaren. |

Die Druckausgabe und Berichtsteil 5 zeigen gültige und ausgeschlossene Beobachtungen insgesamt und je Bedingung. Bei alten Objekten ohne `n_excluded` wird die Ausschlusszahl als `not recorded` gekennzeichnet; aus dem fehlenden Feld wird keine Null erfunden. Die übrigen alten Ergebnisfelder bleiben verwendbar.

### Numerische Konstanz, Regressionen und Band (E3)

Für mindestens zwei gültige Abweichungen d werden Mittel m, Stichproben-SD s und SE = s/√n berechnet. Mit ε = `.Machine$double.eps` gilt numerische Konstanz genau dann, wenn SE exakt null ist oder SE < 10 ε |m|. Der zweite Zweig folgt der in E3 benannten relativen Konstanzgrenze von `stats::t.test`; auch m = SE = 0 ist erfasst. Die Grenze ist eine Regel des Rechenverfahrens zur Arbeitsgenauigkeit, keine neue empirische Konstante und keine Testtoleranz.

- Im regulären Fall: t = m/SE, p = 2·`stats::pt(-abs(t), df = n - 1)`, Grenzen m ± q·SE mit dem t-Quantil zum übergebenen `level`. Der obere Quantilwert wird über die obere Verteilungsseite berechnet, damit bei zulässigen Niveaus nahe eins keine vermeidbare Rundung auf eins entsteht. Gegen `stats::t.test()` wird dort verglichen, wo es ein Ergebnis liefert.
- Im konstanten Fall: beide Intervallgrenzen sind m; t-Inferenz und p bleiben `NA_real_`, ein englischer Hinweis nennt die betroffene Auswertung. Die gemessene SD wird nicht nachträglich verändert. Das bestehende Biasobjekt erhält kein zusätzliches öffentliches t-Feld; die t-Rechnung ist intern.
- `level` muss ein endlicher numerischer Skalar strikt zwischen null und eins sein. Für die Meldungen werden Gesamtstichprobe, einzelne Bedingungen und die beiden Regressionsverfahren unterscheidbar benannt. Hinweise sind bewusst signalisierte R-Messages, keine durchgereichten Engine-Warnungen und keine pauschal unterdrückten Fehler.

Beide Regressionen verwenden zentrierte OLS-Summen mit skalierter Rechnung, soweit Quadrate andernfalls über-/unterlaufen würden: einmal über alle gültigen Einzelwerte mit N − 2 Freiheitsgraden, einmal über gleich gewichtete Itemmittel mit g − 2 Freiheitsgraden. Koeffizienten, Residuen, Standardfehler und R² werden ohne `lm()` oder `summary.lm()` ausgerechnet. Die bestehende Trennung von Bias und Schätzbarkeit der Linearität bleibt bestehen.

Für die Reststreuung wird zusätzlich folgende relative Regel festgelegt: Bei positiver Gesamtquadratsumme TSS gilt RSS ≤ (10 ε)²·TSS als numerisch verschwindend. Rechnerisch wird die entsprechende Normrelation √RSS ≤ 10 ε √TSS skaliert ausgewertet, damit ein quadrierter Grenzwert nicht selbst unterläuft. Dies vergleicht Rest- und Gesamtamplitude auf derselben relativen Präzisionsskala; es gibt keine absolute Streuungsuntergrenze. Exakt konstante Zielwerte sowie Zielwerte, die nach der obigen SE-Regel numerisch konstant sind, fallen ebenfalls in den degenerierten Zweig. Die Regel wird separat für Einzelwerte und Itemmittel angewandt.

Bei schätzbarer Geraden und positiven Freiheitsgraden, aber degenerierter Reststreuung, bleiben die berechneten Koeffizienten erhalten; t-Werte und p-Werte sind `NA_real_` mit Hinweis. Das Konfidenzband fällt auf die geschätzte Gerade zusammen. R² ist bei TSS = 0 `NA_real_`, sonst der rechnerische Anteil 1 − RSS/TSS. Die Bandentscheidung folgt dieser Geraden: eine durchgehend exakt null liegende Gerade ist eingeschlossen, eine nur an einem Punkt null schneidende Gerade nicht. Der Konstanzzweig darf kein `NaN` erzeugen und keine Raw-Engine-Meldung erreichen lassen.

Die in ADR-052 Nr. 16.5 bestätigten Rangfälle gelten weiter: Bei nur einem unterschiedlichen Referenzwert sind die Linearitätsfelder einschließlich Freiheitsgrad `NA_real_`; Bias bleibt auswertbar. Bei zwei Beobachtungen mit zwei Referenzwerten bleiben die Koeffizienten erhalten, df = 0, Inferenz und Band sind nicht bestimmbar. Zwei Itemmittel verhindern nur die Inferenz der Itemmittelrechnung, nicht die eventuell mögliche Handbuchrechnung mit mehr Einzelwerten. Ein nicht bestimmbares Band ist ein leerer Dataframe mit den vorgesehenen numerischen Spalten.

Die zusätzlichen Felder bleiben wie in PLAN Runde 1 und ADR-052 Nr. 16 festgelegt:

- `linearity` behält zuerst `intercept`, `slope`, `slope_p_value`; anschließend kommen `r_squared`, `t_intercept`, `t_slope`, `df`, `t_quantile` hinzu.
- `linearity_item_means` enthält `intercept`, `slope`, `r_squared`, `t_intercept`, `t_slope`, `df`. Unterschiedliche Replikatzahlen ändern die Gewichtung nur in der Einzelwertrechnung.
- `linearity_band` enthält die numerischen Spalten `reference`, `fit`, `lower`, `upper` für die verschiedenen gültigen Referenzwerte. Das Urteil wird trotzdem über das gesamte geschlossene Referenzintervall gebildet.
- `linearity_in_band` ist ein unbenannter logischer Skalar ohne weitere Attribute; `linearity_verdict` ein unbenannter Zeichenketten-Skalar `acceptable` oder `unacceptable`. Bei fehlender Bestimmbarkeit stehen dort entsprechend `NA` und `NA_character_`.
- `linearity_note` erklärt auf Englisch die möglicherweise abhängigen Replikate, die Rechnung über `item means`, beide Freiheitsgrade und die maßgebliche Handbuchentscheidung. Degenerierte Fälle erhalten den zutreffenden Grund auch in Druck und Bericht.

Die kontinuierliche Bandentscheidung aus Runde 1 bleibt bestehen: Mit z = Referenz − Referenzmittel und Q = t-Quantil × Reststandardabweichung wird das Maximum von q(z) = (mittlerer Bias + Steigung·z)² − Q²·(1/N + z²/Sxx) an beiden Intervallenden und gegebenenfalls am inneren Maximum der quadratischen Funktion geprüft. Einschluss gilt genau bei Maximum ≤ 0; Berührung zählt. Es wird keine zusätzliche Toleranz auf das Urteil gelegt. Entartete Inferenz und ein zusammengefallenes, bestimmbares Band sind getrennte Fälle.

### Vignette, Herkunft und Überdeckungsbericht (E5, E7)

Der neue Abschnitt heißt `## Bias interval: coverage by scenario` und steht nach dem vollständigen Abschnitt `Bootstrap intervals: coverage by scenario` auf derselben Überschriftenebene. Dadurch fällt keine Bias-Tabelle in den von K-M1c-5 ausgewerteten Bootstrap-Abschnitt.

Der neue Rmd-Teil enthält keine Zahlenliterale, auch nicht für Toleranzen oder Seeds. Er lädt den Helfer über wörtliche Argumente in `sys.source(system.file("validation", "agreement", "bias_coverage.R", package = "llmsa", mustWork = TRUE), envir = ...)`. Der Helfer erhält die schon verifizierten ANK-06-/ANK-TOL-Objekte aus dem bestehenden Validierungspfad; keine neue Ankerkopie und keine eingefrorene Ergebnistabelle. Namen tragen das Präfix `agreement_`, nicht `sim_` oder `boot_`; Quellen bleiben transitiv auffindbar (ADR-043, ADR-048 Nr. 14.5, ADR-052 Nr. 16.8).

Die ADEMP-Festlegungen aus K-M3a-7/ACC-14/ADR-052 bleiben: zwei synthetische Szenarien mit jeweils 20 Items, drei Prompts, drei Modellen, drei Replikaten, Itemvarianz eins und Niveau 0,95. S-bias-1 verwendet Restvarianz 0,1 und wahren Bias 0,2; S-bias-2 verwendet Restvarianz 0,5 und wahren Bias null. Die Itemwahrheit ist normalverteilt mit Mittelwert null; jede Antwort ist Itemwahrheit plus wahrer Bias plus unabhängig gezogener normalverteilter Fehler. Diese Designeinstellungen stehen mit ihrer Herkunft im Helfer, nicht als abgetippte Rmd-Ergebnisse. `n_sim` kommt aus ANK-06; Seeds sind 20261106 und 20261107, RNG ist Mersenne-Twister/Inversion/Rejection. Die Reihenfolge der Zufallsziehungen folgt dem bestehenden Plan und der unabhängigen Klasse-A-Simulation: Design mit Replikat als schnellstem Index, danach Modell, Prompt und Item; je Wiederholung zuerst alle Itemwahrheiten, danach alle Antwortfehler.

Pro Szenario werden alle Wiederholungen aus dem geladenen `llmsa::msa_bias()` gerechnet. Die Tabelle zeigt Szenario, Überdeckung, MCSE = √(c(1 − c)/n_sim), `n_sim` und den vorzeichenbehafteten Abstand `(coverage - level) / MCSE`. Bei MCSE null wird ein Abstand ungleich null als entsprechend vorzeichenbehaftet unendlich berichtet, nie als `NaN`. Metadaten nennen Seeds, RNG, Laufzeit und R-/Paketversionen.

Die Überschreitung von `ANK-TOL.mc_factor` für die Berichtsschwelle wird als Unter- oder Überdeckung benannt. Sie bricht den Knit nicht ab; über das Bestehen entscheiden die unveränderten Tests und ihre Bestehensschwelle. Tatsächliche Rechenfehler oder nicht endliche Intervallgrenzen brechen dagegen mit Szenario und Wiederholung benannt ab. Es gibt weder Ersatzdaten noch entfernte Wiederholungen, Seed-Suche oder verkürzte Produktionsläufe. Der Zufallszustand des Aufrufers wird auch im Fehlerfall wiederhergestellt.

Die Berechnung ist offline und sequenziell, benutzt den bereits geladenen Namespace und lädt kein unmutiertes Paket darüber. Hilfe, Bericht, Vignette und Helfer benötigen keine der drei neuen optionalen Orakelbibliotheken.

## Reihenfolge

1. In BUILD die bestätigten Daten-/Anker-Voraussetzungen lesend prüfen und den vollständigen bisherigen Knit unter dokumentierten Bedingungen messen. Fehlende geschützte Quellen benannt als Infrastrukturproblem melden; keine Ersatzdaten erzeugen.
2. Kleine synthetische Regressionstests für E1–E3 und API-Formen anlegen; gemeinsame Referenzauflösung, Fehlerbehandlung und Ausschlusszählung implementieren. Dabei dieselben Referenzregeln in beiden Funktionen verwenden.
3. Agreement-Facharbeit aus Runde 1 umsetzen: Cohen, Fleiss, Alpha-Zählung, Attributnenner. Bestehende Modal-/AP1-Grenze in Hilfe und Bericht kennzeichnen.
4. Bias und beide Regressionen einschließlich der relativen Konstanzregeln, Rangfälle, kontinuierlichen Bandentscheidung und eindeutigen skalaren Felder implementieren. Das ganze numerische Raster ausführen, nicht nur den einzelnen Reviewer-Reproduktionsfall.
5. Druckmethoden und Berichtsteile ergänzen; vollständige Ausgabe-, Fehler- und Altobjektprüfungen ausführen. Help aus roxygen erzeugen, Suggests und NEWS ergänzen.
6. Installierbaren ADEMP-Helfer und getrennten Bias-Vignettenabschnitt ergänzen; Kontext-, RNG- und Quellenprüfungen ausführen. Vollständigen Knit nachher unter denselben Bedingungen messen, zusätzlich beide Paketkontexte prüfen.
7. Gezielte Unit-, M3a-Abnahme-, Klasse-A- und ältere Agreement-/Vignettenregressionen ausführen. Gesamtprüfungen und Git verwendende Gates verbleiben beim Orchestrator. Neue Fehler durch Produkt-/Builder-Testkorrekturen behandeln, ohne Abnahmeregeln zu verändern.
8. Tatsächlichen Output, Laufzeiten, Einschränkungen und offene Punkte in den zugewiesenen BUILD-Nachweisen festhalten. Reviewer ergänzt ADR-052 Nr. 17 gemäß Planentscheidung; Gates und anschließendes Code-Review entscheiden über die Abnahme.

## Risiken

| Risiko | Behandlung |
| --- | --- |
| Strengere Referenzprüfung macht bisher still falsche Eingaben sichtbar | Aussagekräftige Meldungen, dokumentierte vollständige Skala und Tests aller Referenzformen; gemeinsame M2-/M1d-/Berichtspfade mitprüfen. |
| Numerische Rundung, Rangmangel und kleine echte Streuung werden verwechselt | Relative Konstanzregeln explizit; Grenzfälle ober-/unterhalb der Regeln und Skalierungsraster; keine absolute Mindeststreuung und keine weichere Abnahmetoleranz. |
| Benannte Vektorelemente oder zufällige Typen verletzen den Vertrag | Rückgabeformen einschließlich NA-Zweigen mit `expect_identical()` prüfen; Fleiss enthält genau `kappa`. |
| Die neue Tabelle verändert alte Vignettenabschnitte oder lädt fremden Code | Eigene Ebene zwei, keine neuen Rmd-Zahlenliterale, wörtlich auflösbare Quelle, gemeinsamer Knit und transitive Quellenprüfungen; geladener Namespace bleibt maßgeblich. |
| Knit-Kosten multiplizieren sich im mutgate | Vollständige Knits vor/nach der Änderung unter gleichen Bedingungen messen; keine Reduktion von `n_sim`. Die vom Reviewer hochgerechneten Sekunden sind keine eigene Laufzeitmessung. |
| Scope umfasst auch bestehende Druck- und Fehlerpfade in `R/agreement.R` | Vollständige schnelle Ausgabetests und einzeln geprüfte Fehlerzweige; ANK-32, Floor und Ratchet bleiben unverändert. Keine eigene Baseline oder pauschale Äquivalenzfreigabe. |

### Offene und teilweise offene Backlog-Einträge

Alle 90 offenen oder teilweise offenen Einträge bleiben einzeln zugeordnet. Keine Vertagung schließt einen Befund; Arbeiten anderer Rollen werden nur benannt. Die bereits bestätigte Betreiberreihenfolge M3b → M3a → M3d vor dem 26.11. und M3c danach bleibt berücksichtigt (BL-11).

| ID | Maßnahme oder begründete Vertagung |
| --- | --- |
| BL-01 | Termin-/Budgetpriorität für AP1 bleibt Betreiberentscheidung; M3a bleibt auf die sieben Kriterien beschränkt. |
| BL-02 | Neuheitsabgrenzung vor Veröffentlichung durch Autoren/Betreiber fortführen; keine Literatur-Neuheitsentscheidung in der Implementierung von M3a. |
| BL-03 | Vorhandene M1b-/M1d-Befunde erhalten; weitere ordinale Recovery-/AP5-Forschung getrennt, weil M3a keinen latenten Fit ändert. |
| BL-04 | Gemessene Bootstrap-Befunde weiterhin berichten; offene AP5-Forschung nach dem 26.11. außerhalb dieses Meilensteins. |
| BL-05 | Betreiber berücksichtigt `prior_differs` bei endgültiger AP1-Auswertung; M3a liefert keine neue Memorisierungsevidenz. |
| BL-06 | API-Zugänge und Modellumleitungen im Betrieb durch Betreiber prüfen; keine Schlüssel oder Modellaufrufe für M3a. |
| BL-07 | Restaufgabe Provider-Stichprobe/Wiederholungstage beim AP1-Betreiber; vorhandene Routingregeln erhalten. |
| BL-08 | Datenschutzvereinbarung vor AP7 durch Betreiber; M3a verwendet synthetische Tests und vorhandene lokale Belege. |
| BL-09 | In M3a beachten: geschützte AIAG-Blätter nur in Abnahme lesen, weder in öffentliche Unit-Tests noch Paketdaten kopieren. |
| BL-10 | Go/No-Go und Einreichungstermin entscheiden Betreiber/Autoren; keine Veröffentlichung durch diese Phase. |
| BL-11 | Betreiberreihenfolge beachten; Kostenentscheidung für weitere Meilensteine bleibt beim Betreiber. |
| BL-13 | Neue BUILD-/Knit-Laufzeiten messen und dokumentieren; allgemeine Gate-Laufzeitsteuerung bleibt Betreiberaufgabe. |
| BL-14 | M3a-Kennzahlen erhalten unabhängige Formel-/Literatur-/Paketbelege; frühere Fitvalidierung wird dadurch nicht ersetzt. |
| BL-15 | Fleiss in M3a implementieren und tatsächlich dokumentieren; keine bloße Behauptung seiner Existenz. |
| BL-17 | Backend-/ellmer-Nachweis zu K-M3d-3 vertagt; kein Transportpfad wird in M3a geändert. |
| BL-18 | Hashumstellung zu K-M3d-5; bereits erledigte Bootstrap-Meldung erhalten, kein Bootstrapumbau in M3a. |
| BL-20 | Bisherige Trennung von wine-Installationsprüfung und Engine-Gleichheit erhalten; keine neue ordinale Vignettenrechnung. |
| BL-21 | Geschachtelte NIST-Quelle bei späterer Anker-/Kriterienarbeit durch Reviewer zuordnen; kein M3a-Kriterium. |
| BL-22 | Abgenommene AIAG-Pooling-/Interaktionsentscheidung erhalten; M3a verändert `msa_fit()` nicht. |
| BL-23 | Dokumentierte NIST-Präzisionsgrenzen erhalten; weitergehende REML-Arbeit getrennt nach dem 26.11. |
| BL-25 | In M3a keine Ankeränderung; erforderliche Nachträge wären Reviewerarbeit mit ADR im selben Meilenstein. |
| BL-28 | Accounts und Budgetgrenzen beim Betreiber für AP1; keine Netzabhängigkeit der M3a-Prüfungen. |
| BL-29 | Infevers-Anfrage/Nutzungsentscheidung bleibt Betreiberaufgabe; keine Referenzklasse je INSAID-Variante aufnehmen. |
| BL-30 | Pages, Release und DOI zum Veröffentlichungsauftrag durch Betreiber; kein M3a-Produktkriterium. |
| BL-31 | Git-Identität durch Betreiber verwalten; Builder führt keine Git-Kommandos aus. |
| BL-33 | Sandbox-/Template-Pflege beim Betreiber; nur erlaubte Prüfwege verwenden. |
| BL-34 | Erreichbarkeit und Eskalationsablauf im Harness durch Betreiber sichern; keine Änderung von Orchestratorzustand. |
| BL-35 | Bestehende Benachrichtigungskonfiguration erhalten; weitere Template-Arbeit beim Betreiber. |
| BL-36 | WSL-/Dateisystem-Verlagerung nur durch Betreiber bei gemessenem Bedarf; M3a misst Laufzeiten, verschiebt das Repo nicht. |
| BL-37 | Kostenaufzeichnung je Modellaufruf zum Betreiber/Template vertagt; kein Produktproblem. |
| BL-39 | Andere Normen/Quellen vor den jeweiligen AP3-/AP7-Arbeiten durch Betreiber beschaffen; M3a-Belege sind vorhanden. |
| BL-40 | Vergleichsstudien und Katalogbelege vor Verwendung im Paper durch Autoren/Betreiber vervollständigen. |
| BL-41 | In M3a keine unbelegten Kappa-Gütegrenzen ergänzen; Quellenkritik vor späterer Zitierung durch Reviewer/Autoren. |
| BL-42 | M3a-Teil geklärt: AIAG-Dateien und Seitenbildabgleich sind in ADR-052 Nr. 15 belegt; andere Quellenblätter bleiben ihren Meilensteinen zugeordnet. |
| BL-43 | Live-Modellkennungen, Provider-Slugs und Preise vor finaler AP1-Auswertung durch Betreiber prüfen; keine Liveannahmen in M3a. |
| BL-44 | Zulässige M3a-Wahl ohne Fleiss-SE. Ein späterer SE muss Fleiss, Nee & Landis 1979/ANK-72 folgen, nicht der alten Formel. |
| BL-45 | Externe Projektfassungen nach dem Meilenstein durch Betreiber synchronisieren; außerhalb dieses Repos/Builderauftrags. |
| BL-46 | In M3a ganze Knits vorher/nachher messen, öffentlichen und Repository-Kontext prüfen; keine Kürzung der Überdeckungsstudie. |
| BL-47 | Korrekte Zuschreibung bei späterer Publikation durch Autoren; keine neue VariantBench-Nutzung in M3a. |
| BL-48 | Alle sieben Kriterien unten zugeordnet; allgemeine maschinelle Gate-Abdeckung bleibt Betreiber-/Reviewerarbeit. |
| BL-49 | Für M3a passende Ankertoleranzen verwenden; REML-Optimierertoleranzen nicht auf geschlossene Rechnungen übertragen. |
| BL-50 | Fallzahl-CV/Randlösungen zu K-M3c-6 nach dem 26.11.; kein M3a-Vertrag. |
| BL-51 | Exportentscheidung für `acmg_*` nach AP1 mit Betreiber/Reviewer und ADR; M3a benötigt keinen Export. |
| BL-52 | AP1-Endauswertung auf demselben externen Store mit abgenommenem M1 durch Betreiber; keine lokale M3a-Erhebung. |
| BL-55 | Keine Änderung ignorierter Betreiberdateien während der Modellphase; Territoriumshärtung bleibt Betreiberarbeit. |
| BL-57 | In M3a `fleiss` hinter `weights` und Default `FALSE` explizit prüfen; ANK-02 bleibt unverändert. |
| BL-60 | ellmer-/httr2-Transport mit Aufzeichnungen in K-M3d-3 prüfen; kein Backendumbau in M3a. |
| BL-64 | Offene Pilotregeln bei gesonderter AP1-Pflege/M3d klären; kein Eingriff in `acmg_pilot()`. |
| BL-68 | „store unchanged“-Text beim nächsten AP1-CLI-/Berichtsauftrag berichtigen; M3a ändert keinen Storepfad. |
| BL-70 | Status-/Timeout-/Transportbehandlung im Harness durch Betreiber; tatsächliche Abbrüche ohne Scheinfix dokumentieren. |
| BL-71 | Archiv-/Memorisierungsquellen vor finaler AP1-Auswertung durch Betreiber entscheiden; keine neuen Golden-Daten in M3a. |
| BL-72 | In neuen Tests normalisierte Pfade, Windows-taugliche Ressourcen und strikt gelesene Ankertoleranzen verwenden; historische Korrekturen erhalten. |
| BL-73 | Pilot-Kosten-/Reasoning-Spalten vor finalem AP1-Bericht gesondert vervollständigen; kein Gegenstand der M3a-Berichtsteile 4/5. |
| BL-74 | Erhebungslatenz für AP1 durch Betreiber planen; offline laufende M3a-Rechnungen lösen dieses Betriebsproblem nicht. |
| BL-75 | Wartezeitanteile beim nächsten AP1-Reporting-Auftrag ausweisen; keine Erhebungsmetadatenänderung in M3a. |
| BL-77 | Wörtliche Belege für Befunde verwenden; QA-/Reviewer-Promptpflege bleibt außerhalb des Builderterritoriums. |
| BL-79 | Mutationsberichte im Harness durch Betreiber archivieren; Builder dokumentiert nur tatsächlich verfügbare Nachweise. |
| BL-80 | NIST-Offset in Spec durch Betreiber/Reviewer bei nächster Pflege korrigieren; keine Produktursache für M3a. |
| BL-81 | Reviewer gleicht alten Gruppierungsbefund mit PROGRESS M1b BUILD ab; keine ungeprüfte Schließung oder erneuter Fitumbau in M3a. |
| BL-84 | Numerische Fit-Testlücken nach dem 26.11. separat bearbeiten; neue M3a-Pfade erhalten jetzt gezielte Tests. |
| BL-85 | Approval-Zuordnung im Harness durch Betreiber/Reviewer härten; Äquivalenzbehauptungen nur einzeln, nie aus alten Zeilen übernehmen. |
| BL-86 | Infrastrukturabhängige Mutations-/Plattform-Gates durch Betreiber; Sandboxgrenzen dokumentieren und nicht umgehen. |
| BL-87 | Verbleibende hochpräzise Fit-/Konvergenzfälle getrennte Kernarbeit nach dem 26.11.; bestehende Befunde bleiben sichtbar. |
| BL-91 | Dokumentierte latente Invarianzgrenzen erhalten; weitergehende Optimierer-/Ankerentscheidung in späterer Kernpflege. |
| BL-93 | Veraltete lme4-Aufrufe in Abnahme durch Reviewer bei nächster Testpflege ersetzen; nonblocking für Builder. |
| BL-100 | Numerisches `...`/subset-Problem nach dem 26.11. in Kernpflege; kein `msa_fit()`-Eingriff in M3a. |
| BL-101 | Stufenauswahl bei Gewicht null in späterer latenter Kernpflege; unabhängig von den M3a-Ausschlusszählungen. |
| BL-102 | Verbleibende latente Mutationsbefunde nach dem 26.11.; keine zusätzliche Änderung an `R/fit.R`. |
| BL-103 | Projektkorrektur ADR-039 erhalten; verbleibende Template-Übernahme durch Betreiber, keine Veränderung ignorierter Quellen. |
| BL-105 | `[INFRA]`: Rundenverbrauch ohne Produktbefund durch Betreiber beheben; Ursachen im Handoff benennen, Kriterien nicht lockern. |
| BL-106 | `[INFRA]`: Commit-/Territoriumsbasis und zulässige Änderungsfenster durch Betreiber sichern; kein Eingriff zwischen BUILD und GATES. |
| BL-107 | Tatsächlichen ganzen Dateiscope in M3a berücksichtigen; Scope-ohne-Treffer/Wiederverwendung bleibt Harnessarbeit beim Betreiber. |
| BL-108 | REML-Abbruch bei hoher Wiederholbarkeit mit BL-87 nach dem 26.11. bearbeiten; keine Ursache im geschlossenen M3a-Biaspfad. |
| BL-109 | Vorhandenen latenten Methodenhinweis erhalten; AP1-Interaktionssensitivität in der Endauswertung durch Betreiber. |
| BL-110 | Klasse-B-CSV-Härtung nach dem 26.11.; M3a verändert weder diese Leser noch deren Ergebnisdateien. |
| BL-113 | In M3a allgemeine Modal-/Fehlwertregel in Hilfe und Berichtsteil 4 kennzeichnen, AP1-Urteilskennzahl getrennt erhalten. |
| BL-114 | Paketgröße/Archivierung zur CRAN-/Release-Arbeit nach dem 26.11.; abnahmerelevante Vollläufe bleiben erhalten. |
| BL-115 | Locale-Abhängigkeit des Bootstrap-Hashes separat nach dem 26.11.; M3a regeneriert keine Klasse-B-Belege. |
| BL-117 | Härtung veränderter Findings-CSV nach dem 26.11.; unveränderte Leser sind kein M3a-Auftrag. |
| BL-119 | Extraktionsregel vor Verwendung im Paper durch Betreiber entscheiden; neue Regel bräuchte Golden-ADR und erneute M1d-Abnahme. |
| BL-121 | pkgdown-URL zum vorgesehenen Release-Auftrag nach dem 26.11.; Suggests-Ergänzung ist kein Anlass zur Veröffentlichungspflege. |
| BL-123 | Fehlende M3a-Mutationsbaseline ist laut Reviewer bestätigt; spätere Scope-Bindung bleibt Betreiberaufgabe, keine Übernahme des M3b-Scores. |
| BL-124 | Große ordinale Itemvarianz/Laplace-Bias braucht eigene Kernarbeit vor entsprechenden Paper-Aussagen; M3a liefert dafür keine Evidenz. |
| BL-125 | Weitere PB-Kontraste nach erster Veröffentlichung; AP1-Sensitivität beim Betreiber, abgenommener M3b-Vertrag bleibt erhalten. |
| BL-126 | Kalibrierte ME-/SME-Schranken nach erster Veröffentlichung; keine Robustheitsmethodenänderung in M3a. |
| BL-127 | Defensive PB-/Robustheitsvalidierung nach dem 26.11./erster Veröffentlichung im passenden Auftrag; keine Kopplung an M3a. |
| BL-128 | Neue M3a-Ausgabetests jetzt als Formatprüfungen kennzeichnen und letzten Zeilenumbruch prüfen; Altbestand beim nächsten Robustheitseingriff. |
| BL-129 | Robustheitsgrafik im nächsten Grafikauftrag/nach dem 26.11. verbessern; kein M3a-Plotvertrag. |
| BL-130 | Logit-Skalenkennzeichnung in M3d nach K-M3d-4/-6 entscheiden; Berichtsteil 6 bleibt hier erhalten. |
| BL-131 | `[QA-PENDING]`: QA korrigiert M3b-Testhygiene in der nächsten berührenden QA-Phase. Neue Builder-Orakeltests verwenden die ausdrücklich verlangten sichtbaren Unit-Skips aus E7; Abnahme bleibt ohne Skip. |

Die 41 im gelesenen BACKLOG bereits erledigten/behobenen Einträge bleiben geschlossen und werden nicht als neue Arbeit beansprucht:

```text
BL-12, BL-16, BL-19, BL-24, BL-26, BL-27, BL-32, BL-38,
BL-53, BL-54, BL-56, BL-58, BL-59, BL-61, BL-62, BL-63,
BL-65, BL-66, BL-67, BL-69, BL-76, BL-78, BL-82, BL-83,
BL-88, BL-89, BL-90, BL-92, BL-94, BL-95, BL-96, BL-97,
BL-98, BL-99, BL-104, BL-111, BL-112, BL-116, BL-118,
BL-120, BL-122.
```

Die bei BL-104 verbleibende Template-Übertragung bleibt Betreiberaufgabe; BL-24 ersetzt die weitere Scope-Aufgabe aus BL-123 nicht. Teilweise erledigte Einträge wie BL-07, BL-64, BL-87, BL-91, BL-101, BL-102, BL-103 und BL-109 stehen bewusst weiterhin in der Maßnahmentabelle.

## Testplan

### Nachweise je Kriterium

Diese Fachprüfungen sind für BUILD/GATES vorgesehen und in dieser PLAN-Phase nicht ausgeführt. Vorhandene Abnahmetests, Quellen, Anker und Schwellen bleiben unverändert; Produktcode übernimmt keine Test-Mini-Referenz und erkennt keine erwarteten Beispielwerte.

| Kriterium | Unabhängige Nachweise und Ergänzung dieser Runde |
| --- | --- |
| K-M3a-1 | ANK-70 plus Formelrechnung und live `irr::kappa2`, `psych::cohen.kappa`, `DescTools::CohenKappa`; vorhandene Vision-/Diagnoses-/Tafelfälle. Zusätzlich E1: beide Kappa-Felder und alle Gewichte mit ausdrücklich vollständiger Skala gegen unabhängige Rechnung; außerhalb ausdrücklicher/abgeleiteter Skala jeweils benannter Fehler. `test-m3a-1-cohen-kappa.R`. |
| K-M3a-2 | ANK-72 plus ungerundete Formel und live `irr::kappam.fleiss`; gleiche Bewertungen in verschiedenen Anordnungen, fehlende Werte, ungleiche Anzahlen und entartete Nenner. Zusätzlich genaues Objektformat und vollständige Fleiss-Ausgabe ohne SE. `test-m3a-2-fleiss-kappa.R`. |
| K-M3a-3 | ANK-73 plus unabhängige Koinzidenzrechnung und live `irr::kripp.alpha` für jede Metrik; alle vier Bereiche und Zählung leerer/einzelner Einheiten. Referenzänderungen innerhalb unveränderter Skala dürfen Alpha nicht ändern. `test-m3a-3-krippendorff-alpha.R`. |
| K-M3a-4 | Handgezählte D1/D2-/Unit-Fixtures plus unabhängige Schleifenrechnung; ANK-74 und geschützte AIAG-Attributstudie. Nenner, vollständig fehlende Items und echte Modalgleichstände prüfen; AP1-Abgrenzung im Bericht. `test-m3a-4-attribute.R`. |
| K-M3a-5 | ANK-75, unabhängige t-Formel und `stats::t.test` insgesamt/je Bedingung, wo definiert. Zusätzlich Zählfixture für beide Fehlwertarten, leere Bedingungen, Konflikte aller Referenzformen und Präzisionsgrenzen. `test-m3a-5-bias.R`. |
| K-M3a-6 | ANK-76, unabhängige OLS-/Extremwertrechnung sowie `stats::lm`, `summary` und `predict(..., interval = "confidence")` in regulären Testfällen. Beide Gewichtungen, Freiheitsgrade, `between_references`, `handbook_rejects`, exakte Skalarformen, Rang- und Konstanzraster; Hinweis im gerenderten Bericht. `test-m3a-6-linearity.R`. |
| K-M3a-7 | Unabhängige Klasse-A-Studie `tests/simulation/test-bias-coverage.R` mit Mini-Referenz jeder Intervallgrenze; daneben Vignettentabelle aus dem geladenen Paket in `test-m3a-7-vignette.R`. Beide Szenarien, ANK-06, Seeds/RNG, vollständiger Nenner, MCSE und bestehende Bericht-/Bestehensschwellen. |

Literaturtoleranzen werden aus dem jeweiligen Anker gelesen; Rechen-/Paket-/Invarianzvergleiche aus den passenden ANK-TOL-Feldern. Die algorithmischen Präzisionszweige aus E3 ersetzen keine Abnahmetoleranz. Neue Unit-Tests rufen optionale Orakel nur nach dem jeweils nötigen `skip_if_not_installed()` auf; Formel-, Zähl-, API- und Formatprüfungen sind davon getrennt. Das deps-Gate liefert Suggests für die ohne Skip laufende Abnahme.

### Gezielte Regressionen und Fehlerklassen

1. **Referenzen:** Für Vektor, Dataframe und Spaltenname jeweils gleiche Mehrfachbelege, Konflikt, fehlende Zuordnung und fehlend-plus-belegt prüfen; Konflikte in beiden Funktionen auch nach Zeilenpermutation. Für Bias numerisch gleiche Schreibweisen und Faktorlabels. Für Kappa außerhalb der Skala sowohl bei `levels = NULL` als auch ausdrücklich eingeschränkter Skala; mit voller Skala beide Felder gegen die unabhängige Rechnung. Keine Übernahme der vom Reviewer gemessenen falschen Bestandswerte als Sollwerte.
2. **Ausschlüsse:** Kleine als synthetisch markierte Fixture mit gültigen, fehlenden, nicht parsbaren und `NaN`-Antworten, fehlenden Referenzen, beidseitig ungültigen Zeilen, einer leeren und einer Singleton-Bedingung. Handzählung prüft Gesamt- und Gruppensummen sowie `n + n_excluded`; unbeobachtete Bedingungen werden nicht erzeugt. Gültige Kennzahlen gegen dieselben gültigen Paare rechnen. Unendlichkeiten separat als Fehler prüfen.
3. **Numerisches Raster:** Unterschiedliche Item-/Replikatzahlen, ungleiche Replikation, Referenzbereiche und Achsenverschiebungen, positive gemeinsame Skalierungen, mehrere feste Seeds sowie Rauschstufen von regulär bis zur Arbeitsgenauigkeit. Einschließlich exakt null, konstant ungleich null, reiner Geraden, der Reviewer-Subtraktionsfälle und Werten auf beiden Seiten der relativen Konstanzgrenzen. In unterstützten endlichen Fällen kein Fehler, keine Warnung und kein `NaN`; vorgesehene Messages gezielt prüfen. Reguläre Rechnungen gegen t-/lm-Orakel, degenerierte gegen algebraisch bekannte Ergebnisse. Nicht darstellbare Eingaben müssen benannt scheitern.
4. **Ausgabe und Meldungen:** Beide `print()`-Methoden vollständig mit `capture.output(print(x))` prüfen: mit/ohne Referenz, mit/ohne Fleiss, schätzbare/unbestimmte/degenerierte Linearität, Ausschlüsse und alte Objekte. Sollzeilen werden im Test unabhängig aus den Objektfeldern formatiert und ausdrücklich als Formatprüfungen gekennzeichnet; das ist kein fachlicher Zahlenbeleg. Ein nachfolgendes `cat("|\n")` prüft den letzten Zeilenumbruch, `withVisible()` die identische unsichtbare Rückgabe. Englische Fehlertexte mit `expect_error(..., fixed = TRUE)` und zusätzlich vollständiger `conditionMessage()`-Gleichheit sowie `conditionCall() == NULL`; jede Teilbedingung für Typ, Länge, fehlende/nicht endliche Werte und Bereich einzeln. Das umfasst auch bestehende Fehlerpfade von `resolve_reference()` und `krippendorff_alpha()` in der geänderten Datei.
5. **Integration:** Bestehende `test-agreement.R`, `test-report.R`, M2-AP1-Vergleich, M1d-ClinVar-Alpha sowie die gemeinsame Vignette mit K-M1a-7, K-M1b-7, K-M1c-5 und K-M1d-4 prüfen. Die API-Prüfung kontrolliert zusätzlich zu ANK-02 ausdrücklich Position/Default von `fleiss`. Reporttests prüfen beide Verfahren, Freiheitsgrade, Ausschlüsse und Methodenhinweise mit berechneten Werten; Altobjekte rendern ohne neue Felder.
6. **Vignette/Laufzeit:** Gemeinsame Abschnitts- und transitive Literal-/Quellenprüfungen ausführen. Für die Laufzeitmessung ganzen Knit ohne wiederverwendeten Knit-Cache jeweils vor/nach Änderung in frischem Prozess unter identischer R-/Paket-/Kontextkonfiguration ausführen und Befehl, Versionen, Exitstatus und Laufzeit in PROGRESS dokumentieren. Öffentlichen installierten Paketkontext ohne Harness/geschützte Quellen und Repository-Kontext mit gültigem `REPO_ROOT` prüfen. Kleine Helfer-Unit-Tests bleiben schnell; der echte Vignetten- und Klasse-A-Lauf behält den geforderten Umfang.

### Geplante Ausführung in BUILD

Die folgenden Befehle sind Prüfaufträge, keine in dieser Runde ausgeführten Tests. Sie benötigen keine eigenen Git-Kommandos. Wo Paketinstallation/Rendern nötig ist, werden geeignete temporäre Paketkopien und Bibliotheken benutzt; bestehende Quellen und Handoffs werden dadurch nicht überschrieben.

```sh
REPO_ROOT="$PWD" NOT_CRAN=true Rscript --vanilla - <<'RS'
options(testthat.progress.max_fails = Inf)
testthat::test_dir("tests/testthat",
  filter = "^(agreement|agreement-m3a|bias-linearity|agreement-report|validation-bias|report)$",
  load_package = "source", reporter = "summary", stop_on_failure = TRUE)
RS
```

```sh
REPO_ROOT="$PWD" NOT_CRAN=true Rscript --vanilla - <<'RS'
options(testthat.progress.max_fails = Inf)
testthat::test_dir("tests/acceptance",
  filter = "^(m3a-|m1a-7|m1b-7|m1c-5|m1d-4)",
  load_package = "source", reporter = "summary", stop_on_failure = TRUE)
RS
```

```sh
REPO_ROOT="$PWD" NOT_CRAN=true Rscript --vanilla - <<'RS'
options(testthat.progress.max_fails = Inf)
testthat::test_dir("tests/simulation", filter = "^bias-coverage$",
  load_package = "source", reporter = "summary", stop_on_failure = TRUE)
RS
```

Danach vollständige Unit-/E2E-/Fuzz- und Paket-/Plattformprüfungen über die bestehenden vorgesehenen Prüfwege. Die gesamte historische Abnahme mit Git-basierten Prüfungen, der M2-Gate-Vergleich, `R CMD build`/`R CMD check` als Gates, Lint, Trace, Territory und Mutation bleiben beim Orchestrator. Ein lokaler Teillauf wird nicht als Ersatz für diese Gates ausgewiesen.

Die Klasse-A-Suite bleibt innerhalb ANK-TOL.sim_runtime; `tests/simulation/` wird nicht in Mutation aufgenommen. mutgate prüft die gesamte geänderte `R/agreement.R` mit ANK-32 (80 %, Floor 80, Ratchet 2; bestehende 14 Worker), einschließlich bestehender Druck-, Literal- und Fehlerpfade. Tests unterscheiden fachliche Änderungen und beobachtbare Ausgabeänderungen; kein Umbau ausschließlich für den Score und keine neuen Ausschlüsse. Nur tatsächlich nachgewiesene Einzelfalläquivalenz darf später als Claim in `MUT-EQUIV.json` dem Reviewer vorgelegt werden.

In BUILD werden je ausgeführtem Schritt Befehl, Exitstatus, echter Output und Laufzeit dokumentiert, bei Simulationen zusätzlich Seeds, RNG, `n_sim`, MCSE und Versionen. Nicht ausgeführte oder infrastrukturell gescheiterte Prüfungen bleiben ausdrücklich so bezeichnet. Diese PLAN-Phase behauptet weder erfüllte Fachkriterien noch grüne Gates.

### Ausgeführte Prüfung dieser PLAN-Phase

Ausgeführt wurde `python3 -` mit einem lesenden Skript aus `pathlib`, `json` und `re`, Exit 0: Abschnittsfolge gegen SCHEMA, Einwand-IDs gegen PLAN-REVIEW, Kriterien-IDs gegen CRITERIA.json und die vollständige Backlog-Zuordnung gegen BACKLOG.md sowie die vom Reviewer bestätigte Offenliste aus PLAN Runde 1. Zusätzlich wurden die Abwesenheit von ARBITER.md, die beibehaltenen Bias-Feldnamen, die beiden Szenarioeinstellungen und die Textformatierung geprüft. Echter Output:

```text
PLAN-UPDATE schema: 6 required sections, in order
Review coverage: 7/7 objection IDs answered individually with accepted changes
Criteria coverage: 7/7 IDs present
Backlog coverage: 90/90 open or partial entries individually addressed; 41/41 completed entries recorded; 131/131 IDs covered
ARBITER.md: absent
Static document checks only; no product tests or gates executed.
```

Ein ergänzender lesender SHA-256-Vergleich gegen den unmittelbar vor dem Schreiben erhobenen Stand fand alle 418 erfassten Bestandsdateien inhaltlich unverändert. Erfasst waren `R/`, `man/`, `tests/`, `docs/`, `inst/`, `vignettes/`, `contracts/`, `reference/anchors/`, `tools/`, `data/`, `data-raw/`, die bestehenden M3a-Handoffs sowie die gelesenen Stammvorgaben, DESCRIPTION, NAMESPACE, NEWS, SCHEMA und LESSONS; die neue PLAN-UPDATE-Datei war vom Vergleich ausgenommen. Ausgabe des Vergleichs:

```json
{
  "compared_files": 418,
  "changed_or_missing": [],
  "additional_files_in_checked_paths": []
}
```

Dieser Vergleich ist eine lokale Dokumentationskontrolle und kein vom Builder ausgesprochenes Gate-Verdikt. Keine Produkt-, Abnahme-, Simulations- oder Mutationstests und keine Git-Kommandos wurden in dieser Phase ausgeführt.
