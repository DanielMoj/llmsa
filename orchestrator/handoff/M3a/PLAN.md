# PLAN — M3a, Runde 1

Rolle: Builder · Phase: PLAN · Stand: 05.11.2026.

## Ziel

`msa_agreement()` und `msa_bias()` nach K-M3a-1 bis K-M3a-7 vervollständigen und gegen die Originalbeispiele, unabhängige Nachrechnungen und die benannten Paketorakel prüfen. Die bestehende API bleibt als Obermenge erhalten. Diese PLAN-Phase schreibt ausschließlich diese Datei; die unten genannten Produktänderungen sind der Vorschlag für BUILD. Eine Abnahme oder ein grünes Gate wird damit nicht behauptet.

Grundlage sind `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/handoff/M3a/CRITERIA.json`, `docs/00-vision.md`, `docs/01-fachspezifikation.md` insbesondere §§2–4, 6 und 8, `docs/04-weitere-bausteine.md` Abschnitt M3a sowie Formelsammlung §§5–6. Gelesen wurden außerdem `tests/acceptance/setup-m3a.R`, alle sieben `test-m3a-*.R`, `tests/simulation/test-bias-coverage.R`, ANK-70/72/73/74/75/76, ANK-06, ANK-32 und die einschlägigen Einträge von ANK-TOL. Bestandscode, Bericht, Vignette und ihre bisherigen Tests wurden auf die betroffenen Schnittstellen geprüft.

Der Plan übernimmt die Auslegungen ACC-3 bis ACC-16 aus CRITERIA.json. Die dort angekündigte Dokumentation als ADR in `30-plan-review` ist Aufgabe des Reviewers und steht noch aus. Insbesondere gilt:

- ACC-3/4: keine neue Schnittstelle für freie Cohen-Gewichtsmatrizen; für Paketvergleiche dieselbe geordnete Kategorienskala in Implementierung und Orakel.
- ACC-5/6/7: gültige Antworten bestimmen die Nenner; die vorhandenen Kappa-Felder reichen auch für die paarweise angeordnete AIAG-Attributstudie.
- ACC-8/9: Fleiss optional und in diesem Meilenstein **ohne Standardfehler**. Das ist nach K-M3a-2 ausdrücklich zulässig. Eine Varianz nach Fleiss (1971) wird nicht eingeführt.
- ACC-10/11: ausgeschlossene Alpha-Einheiten je Bereich zählen und alle drei Gewichtszuordnungen ausdrücklich dokumentieren.
- ACC-12/13: beide Linearitätsrechnungen ausgeben, das kontinuierliche Handbuchband entscheidet; Unterschied und Abhängigkeit der Replikate stehen im Objekt und Bericht.
- ACC-14/15: Überdeckungsstudie mit den festgelegten Szenarien, Seeds, RNG und Ankern; die Vignette berechnet ihre Tabelle aus dem jeweils geladenen Paket.
- ACC-16: die geforderten Hinweise sind tatsächlich signalisierte R-`message`- oder `warning`-Bedingungen.

ACC-2 beschreibt einen inzwischen überholten Dateistand: Die drei AIAG-Datenblätter sind vorhanden und ihre kanonischen Inhalts-Hashes stimmen mit den Ankern überein. Der Abgleich der gelieferten Dateien am Seitenbild bleibt beim Reviewer; die Vorprüfung ersetzt ihn nicht. Näheres unter Risiken. ACC-17, BL-15, BL-44, BL-113 und BL-123 sind unten ausdrücklich zugeordnet.

## Dateien

Die folgende Liste bezeichnet den vorgesehenen BUILD-Umfang. Gegenwärtig wird nur `orchestrator/handoff/M3a/PLAN.md` angelegt.

| Datei | Geplante Änderung und Zweck |
| --- | --- |
| `R/agreement.R` | Cohen-Randfälle, Fleiss, Alpha-Ausschlusszählung, korrekter Nenner vollständig richtiger Items; Bias unabhängig von der Schätzbarkeit einer Geraden; beide Linearitätsrechnungen, Band, Urteil und Hinweise; zugehörige Druckmethoden und roxygen-Dokumentation. |
| `man/msa_agreement.Rd`, `man/msa_bias.Rd` | Aus den geänderten roxygen-Blöcken erzeugte Hilfe: Gewichte, fehlende Antworten, Modalregel, Fleiss-Voraussetzungen, Ergebnisfelder, beide Linearitätsverfahren und ihre Grenzen. Generierung nötigenfalls in einer temporären Paketkopie; nur die zugehörigen Dateien übernehmen. |
| `inst/templates/validation_report.Rmd` | Abschnitt 4 kennzeichnet die allgemeinen Übereinstimmungsdiagnosen und die Modalregel; Abschnitt 5 zeigt beide Linearitätsrechnungen, Freiheitsgrade, Handbuchurteil und Abhängigkeit der Replikate. Neue Felder bei älteren Objekten defensiv behandeln. |
| `inst/validation/agreement/bias_coverage.R` (neu) | Installierbarer, sequenzieller Berechnungshelfer für die Überdeckungstabelle der Vignette; verwendet `llmsa::msa_bias()` aus dem geladenen Namespace und verifizierte Anker. |
| `inst/validation/agreement/README.md` (neu) | ADEMP, Herkunft der Szenarien, Seeds/RNG, MCSE, Ausführung in beiden Paketkontexten und Abgrenzung zum unabhängigen Klasse-A-Abnahmetest. |
| `vignettes/validation.Rmd` | Abschnitt „Bias interval: coverage by scenario“ mit berechneter Tabelle, `n_sim`, Seeds, RNG, Laufzeit und Versionsangaben; Erläuterung des geprüften Bias-Intervalls. Aussagen über nicht erneut gestartete Simulationen auf die bestehenden Klasse-B-Studien begrenzen. |
| `DESCRIPTION` | `irr`, `psych` und `DescTools` zu Suggests hinzufügen, damit die ohne Skip aufgerufenen Abnahmeorakel durch das deps-Gate bereitgestellt werden. Keine neuen Imports. |
| `NEWS.md` | Nutzersichtbare Ergänzungen und behobene Randfälle auf Englisch. |
| `tests/testthat/test-agreement-m3a.R` (neu) | Kleine unabhängige Referenzrechnungen, gültige Nenner, Modalregel, Ausschlusszählungen, Fleiss, Cohen-Randfälle und Invarianzen. |
| `tests/testthat/test-bias-linearity.R` (neu) | Bias gegen t-Test, beide Regressionen gegen unabhängige Rechnungen, kontinuierliches Band, Rang- und Stichprobenrandfälle, ungleiche Replikatzahlen. |
| `tests/testthat/test-agreement-report.R` (neu) | Druck und gerenderte Berichtsabschnitte mit Datenwerten und Methodenhinweisen; klare Trennung zu AP1-Entscheidungskennzahlen. |
| `tests/testthat/test-validation-bias.R` (neu) | Determinismus, MCSE/Nenner, RNG-Wiederherstellung, Datenfluss aus dem geladenen Paket und Einbindung der neuen Vignettenquelle. Kleine Testfixtures sind kein Überdeckungsbeleg. |
| `PROGRESS.md`, später zugewiesenes `orchestrator/handoff/M3a/REVIEW-INPUT.md` | Erst in BUILD: Änderungen, ausgeführte Befehle, echter Output, Laufzeiten, offene Befunde und Punkt-für-Punkt-Antworten dokumentieren. |

Es sind keine neuen Exporte vorgesehen; `NAMESPACE` und ANK-02 brauchen deshalb keine Änderung. Produktarbeit liegt in `R/agreement.R`, nicht im Fit-, Bootstrap-, AP1- oder Robustheitskern. Abnahmetests, Klasse-A-Simulationen, QA-Dateien, Spezifikationen, Anker, geschützte Quellen, Golden-Daten und Betreiberzustand bleiben im jeweiligen Territorium. Bestehende Klasse-B-Ergebnisdateien werden nicht neu erzeugt. Für diesen Vorschlag ist keine Änderung einer bestehenden Schnittstelle und damit kein Builder-ADR zur API vorgesehen; die offenen Reviewer-Auslegungen werden durch den angekündigten Reviewer-ADR festgehalten.

## Schnittstellen

### `msa_agreement()` — K-M3a-1 bis K-M3a-4

Vorgesehene Signatur, mit unverändertem Präfix aller bisherigen Argumente:

```r
msa_agreement(runs, levels = NULL, reference = NULL,
              weights = c("unweighted", "linear", "quadratic"),
              fleiss = FALSE)
```

Klasse `msa_agreement`, vorhandene Ergebnisnamen, Bedeutung der Prozentwerte und Reihenfolge der bisherigen Gewichtsoptionen bleiben erhalten. `fleiss` wird als einzelner nicht fehlender logischer Wert geprüft. Mit der Vorgabe gibt es weiterhin kein Listenelement `fleiss`; mit `TRUE` kommt `fleiss = list(kappa = <numeric scalar>)` hinzu. Die Alpha-Tabelle erhält additiv `n_units_excluded`. Neue Diagnosefelder verändern keine bestehenden AP1-Entscheidungsregeln.

**Cohen.** Die allgemeine Rechnung aus Formelsammlung §5 bleibt maßgeblich: beobachtete und erwartete gewichtete Übereinstimmung aus derselben Kreuztabelle, ohne Erkennen bestimmter Datensätze. Bei nur einer Skalenkategorie oder degeneriertem Nenner vor einer Division abfangen, `NA_real_` liefern und einen Hinweis mit „kappa“ signalisieren. Das gilt für alle drei Gewichte und beide vorhandenen Kappa-Ausgaben, auch bei einer größeren Skala mit nur einer besetzten Kategorie. Leere Randkategorien bleiben Teil der ausdrücklich übergebenen Skala. Die speziellen Gewichte aus Cohen (1968) werden durch die unabhängige Abnahme nachgerechnet; sie werden nicht als neue Produktoption eingeführt. Für Kappa über alle Antworten wird kein Standardfehler ausgewiesen, da Antworten desselben Items abhängig sein können.

**Fleiss.** Ein Item umfasst seine gültigen Antworten über alle Prompts, Modelle, Blöcke und Replikate. Zuerst die gültigen Anzahlen für alle tatsächlich vorkommenden Items feststellen; ein Item mit fehlenden Antworten wird nicht still entfernt, um gleiche Anzahlen herzustellen. Bei einheitlichem `m >= 2` werden je Item die Kategorienhäufigkeiten `n_ic` verwendet:

```text
P_i  = sum_c n_ic * (n_ic - 1) / (m * (m - 1))
p_c  = sum_i n_ic / (Anzahl_Items * m)
kappa_F = (mean(P_i) - sum_c p_c^2) / (1 - sum_c p_c^2)
```

Die Marginalanteile werden aus den Daten berechnet, nicht aus gerundeten Publikationswerten. Ungleiche Anzahlen ergeben `NA_real_` und eine Meldung mit „Krippendorff“; die übrigen Kennzahlen bleiben verfügbar. Auch gleiche Anzahlen unter zwei und ein degenerierter Nenner liefern keine scheinbar bestimmte Zahl. Die Druckmethode zeigt bei angefordertem Fleiss nur den Punktschätzer, keinen SE, Test oder Konfidenzbereich. BL-44 ist damit als bedingte Varianzanforderung berücksichtigt: Eine spätere SE-Erweiterung müsste Fleiss, Nee & Landis (1979), Gl. (12), erfüllen.

**Alpha.** Für die vier vorhandenen Bereiche gelten unverändert:

| `scope` | Einheit für Berechnung und Ausschlusszählung |
| --- | --- |
| `replicates (within prompt & model)` | Item × Prompt × Modell |
| `across prompts (within model)` | Item × Modell |
| `across models (within prompt)` | Item × Prompt |
| `all conditions` | Item |

Die Menge der vorkommenden Einheiten wird vor dem Entfernen ungültiger Antworten gebildet. `n_units_excluded` zählt darin alle Einheiten mit weniger als zwei gültigen Antworten, einschließlich vollständig fehlender Einheiten; nicht beobachtete Kombinationen werden nicht künstlich ergänzt. Blöcke bilden keine zusätzliche Trennung. Die Koinzidenzrechnung verwendet nur die verbleibenden Einheiten. Berechnung und Zählung müssen dieselben Gruppierungen benutzen. Die Hilfe nennt ausdrücklich `unweighted (nominal)`, `linear (ordinal)` und `quadratic (interval)`. Die Intervallmetrik arbeitet auf den Kategorienpositionen der übergebenen Skala, nicht auf zufällig numerisch aussehenden Labels.

**Attributkennzahlen.** Fehlende oder nicht parsbare Antworten bleiben fehlend. Trefferquoten beziehen sich auf gültige Vergleiche mit der Referenz. Für den Anteil vollständig richtiger Items muss wenigstens ein gültiger Vergleich existieren; `all(logical(0))` darf kein richtiges Item erzeugen. Die Modalantwort eines leeren Items ist `NA`; bei Gleichstand gewinnt die niedrigste der tatsächlich gleich häufigen Kategorien in der Skalenordnung. Wiederholbarkeit verwendet Item × Prompt × Modell, Reproduzierbarkeit die oben genannten größeren Einheiten; jeweils zählen nur Einheiten mit mindestens zwei gültigen Antworten, alle Replikate gehen ein.

BL-113 wird durch Dokumentation und Kennzeichnung behandelt: Die allgemeine Modalregel verwirft fehlende Antworten und löst Gleichstände nach der Skalenordnung. `acmg_modal()` führt fehlende Antworten als Kategorie und schließt Gleichstände für die Anwendung aus. Abschnitt 4 des Berichts und die Hilfe nennen diesen Unterschied; für das AP1-Band bleibt die vorhandene Entscheidungskennzahl maßgeblich. Die allgemeine Regel selbst ist durch Formelsammlung §5 festgelegt: „bei Gleichstand die niedrigere Kategorie in Skalenordnung (Konvention, im Bericht nennen)“.

### `msa_bias()` — K-M3a-5 und K-M3a-6

Die Signatur `msa_bias(runs, reference, level = 0.95)` und die Klasse `msa_bias` bleiben erhalten. `overall`, `by_condition`, `level` und `n_items` behalten ihre Bedeutung. Die vorhandenen Einträge `n`, `bias`, `sd`, `lower`, `upper`, `p_value` bleiben; `by_condition` verwendet weiterhin Prompt × Modell. Der Bias wird aus den gültigen Abweichungen Antwort minus Itemreferenz gerechnet, das zweiseitige t-Intervall mit `n - 1` Freiheitsgraden und dem übergebenen `level`.

Die Biasrechnung wird von der optional schätzbaren Geraden getrennt. Insbesondere liefert das AIAG-Biasbeispiel mit nur einem Referenzwert einen vollständigen Biasbefund statt des bisherigen Indexfehlers beim Zugriff auf den zweiten Regressionskoeffizienten.

| Feld | Vertrag für identifizierbare Regressionen |
| --- | --- |
| `linearity` | Benannter numerischer Vektor: bestehende Einträge `intercept`, `slope`, `slope_p_value` bleiben vorn; ergänzen um `r_squared`, `t_intercept`, `t_slope`, `df`, `t_quantile`. Regression aller gültigen Einzelabweichungen; `df = N - 2`, bei balancierten Daten `N = g*m`. R² als Anteil. |
| `linearity_item_means` | Benannter numerischer Vektor `intercept`, `slope`, `r_squared`, `t_intercept`, `t_slope`, `df`. Ein ungewichteter Mittelwert der gültigen Abweichungen je Item, Regression auf dessen Referenzwert; `df = g - 2`. Unterschiedliche Items mit gleichem Referenzwert bleiben unterschiedliche Items. |
| `linearity_band` | `data.frame` mit `reference`, `fit`, `lower`, `upper`, mindestens eine Zeile je verschiedenem beobachteten Referenzwert. Vertrauensband des mittleren Bias aus der Einzelwertregression beim angeforderten `level`, kein Vorhersageintervall für neue Einzelantworten. |
| `linearity_in_band` | Ein logischer Wert: Null liegt im Handbuchband über dem gesamten geschlossenen Bereich vom kleinsten bis größten Referenzwert. |
| `linearity_verdict` | Bei bestimmtem Band `acceptable` genau dann, wenn `linearity_in_band` wahr ist, sonst `unacceptable`. Die Item-Mittelwertrechnung ändert dieses Urteil nicht. |
| `linearity_note` | Englischer Methodentext mit „item means“, beiden Freiheitsgraden bzw. `gm - 2`/`g - 2` und dem Hinweis, dass Replikate desselben Items korreliert bzw. nicht unabhängig sein können. Im Objekt und in Berichtsabschnitt 5. |

Für ungleiche Replikatzahlen bleiben dies zwei verschiedene Gewichtungen: alle gültigen Einzelwerte für die Handbuchrechnung, jedes auswertbare Item genau einmal für die Zusatzrechnung. Die Zusatzrechnung wird nicht still mit Replikatzahlen gewichtet. Es kommt keine Kennzahl Steigung mal Prozessvariation hinzu; dafür besteht kein Vertrag der hier verwendeten Handbuchauflage.

**Kontinuierliche Bandprüfung.** Mit `z = x - mean(x)`, Steigung `b`, mittlerer Abweichung `d_bar`, `Sxx = sum(z^2)` und `Q = t_quantile * residual_sd` ist Null im Band genau dann, wenn

```text
q(z) = (d_bar + b*z)^2 - Q^2 * (1/N + z^2/Sxx) <= 0.
```

Über dem Referenzbereich wird das Maximum dieser quadratischen Funktion geprüft: beide Endpunkte sowie der innere Scheitel, falls die Funktion konkav ist und der Scheitel im Bereich liegt. Zentrierte Größen vermeiden unnötige Auslöschung; lineare/konstante Grenzfälle und ein Band ohne Reststreuung werden ausdrücklich behandelt. Die gerenderte Tabelle ist eine Darstellung, nicht die Entscheidungsgrundlage. Ein Band, das Null gerade berührt, enthält Null. Vergleiche gegen unabhängige Bandextrema und `stats::predict.lm(interval = "confidence")` prüfen diese Herleitung. Keine zusätzliche unankerte Entscheidungstoleranz verschiebt die Bandgrenze.

**Vorschlag für noch nicht vollständig spezifizierte Randfälle zur Prüfung in Runde 1.** `level` muss ein endlicher Skalar strikt zwischen null und eins sein. Nicht parsbare/fehlende Werte bleiben ausgeschlossen; nicht endliche numerische Eingaben und das Fehlen sämtlicher gültiger Paare erhalten benannte Fehler. Mit einem gültigen Paar bleibt der Mittelwert verfügbar, während Streuung, Intervall und p-Wert `NA` sind. Bei konstanter Abweichung bleibt ein bestimmtes Punktintervall darstellbar; nicht definierte Testgrößen werden mit Hinweis `NA`, niemals `NaN`. Bei nur einem verschiedenen Referenzwert werden die nicht identifizierbaren Linearitätsgrößen `NA_real_`, das Band eine leere Tabelle mit den vereinbarten Spaltentypen, `linearity_in_band = NA` und `linearity_verdict = NA_character_`; `linearity_note` benennt den fehlenden Referenzbereich. Bei identifizierbaren Koeffizienten ohne Restfreiheitsgrade bleiben die Koeffizienten verfügbar, Inferenz und Urteil unbestimmt. Eine unbestimmte Item-Mittelwertinferenz bei nur zwei Items verhindert kein sonst bestimmtes Handbuchurteil. Diese Details ergänzen den zwingenden Ein-Referenzwert-Fall aus ACC-12; sie sind kein bereits beschlossener Reviewer-Vertrag.

`print.msa_bias()` und Berichtsabschnitt 5 zeigen Schätzungen, beide Freiheitsgrade, Methodentext und Handbuchurteil. Bestehende Objekte ohne neue Felder bleiben druck- und berichtsfähig; für unbestimmte Linearität wird der Grund ausgegeben, kein positives Urteil aus dem erfolgreichen Bias-Test abgeleitet.

### Vignettenberechnung — K-M3a-7

Der neue installierte Helfer erhält die bereits verifizierten ANK-06/ANK-TOL-Objekte aus der vorhandenen latenten Validierungsinfrastruktur. Es werden keine weiteren Ankerkopien oder eingefrorenen Simulationsergebnisse eingeführt. Die Vignette lädt ihn über einen statisch auflösbaren Aufruf:

```r
sys.source(system.file("validation", "agreement", "bias_coverage.R",
                       package = "llmsa", mustWork = TRUE),
           envir = agreement_validation)
```

`agreement_validation` ist eine eigene Umgebung. Der Helfer verwendet eigene `agreement_`-Namen, lädt keine Klasse-B-Generatoren und überschreibt keine `sim_`- oder `boot_`-Bindungen. Er ruft den bereits geladenen `llmsa`-Namespace auf; ein Mutationstest darf nicht durch Laden eines unveränderten Pakets aus dem Arbeitsbaum umgangen werden. Bestehende Prüfungen der transitiv geladenen Vignettenquellen bleiben wirksam.

ADEMP und Reproduzierbarkeit:

- Ziel/Schätzziel: Überdeckung des t-Intervalls für den wahren mittleren Bias.
- Daten: 20 Items, 3 Prompts, 3 Modelle, 3 Replikate; Itemwahrheit `x_i ~ N(0, 1)`, Antworten `x_i + bias + e`, unabhängig gezogene Residuen. Keine zusätzliche Prompt-, Modell- oder Blockkomponente.
- S-bias-1: Restvarianz 0,1 und Bias 0,2; S-bias-2: Restvarianz 0,5 und Bias 0. Das sind Spec-Einstellungen, keine empirischen Referenzkonstanten.
- Methode: `msa_bias(level = 0.95)`, Grenzen aus `overall`. Die Itemwahrheit wird als Referenz übergeben, nicht geschätzt.
- Wiederholungen: je Szenario `ANK-06.value.n_sim_min`, gegenwärtig 1000; Seeds 20261106 und 20261107 gemäß ACC-14, RNG `Mersenne-Twister/Inversion/Rejection`. Ziehungs- und Designreihenfolge reproduzieren die Festlegung des Klasse-A-Tests. RNG-Art und vorheriger Seed werden nach dem Helferaufruf auch im Fehlerfall wiederhergestellt.
- Kennzahlen: Anteil `lower <= true_bias <= upper`, `MCSE = sqrt(coverage * (1 - coverage) / n_sim)` und Abstand zum Nominalniveau. Jede Wiederholung zählt; fehlgeschlagene Berechnungen werden benannt abgebrochen und nicht aus dem Nenner entfernt.
- Bestehenskriterium: Abstand zu 0,95 höchstens `ANK-TOL.mc_factor.pass * MCSE`; Berichtsschwelle nach `ANK-TOL.mc_factor.report`. Keine Seed-Suche, kein nachträgliches Erhöhen einer Toleranz.

Der Helfer liefert Zusammenfassung, im Speicher gehaltene Replikatergebnisse und Metadaten. Die Vignette berechnet die beiden Szenarien beim Knit sequenziell ohne Netz und ohne Ergebnisdateien und zeigt eine Tabelle mit den Spalten `scenario`, `coverage`, `MCSE`, `n_sim`; Seeds, RNG, Laufzeit und Versionen stehen daneben. Zahlen werden aus dem Ergebnis formatiert, nicht aus CRITERIA.json oder historischen Logs abgeschrieben. Die Rundung muss die MCSE und den Abstand zum Nominalniveau noch prüfbar lassen. Bestehende Klasse-B-Tabellen lesen weiter die abgenommenen Ergebnisse und starten ihre Studien beim Knit nicht neu.

## Reihenfolge

1. **Vertrag und Ressourcen festhalten.** Nach PLAN-REVIEW die Einwände mit stabilen IDs und den Reviewer-ADR einarbeiten. In BUILD die Datenverfügbarkeit und Ankerbindung erneut als Vorbedingung prüfen; deps-Gate versorgt die zusätzlichen Suggests. API-Präfix und Referenzwerte aus den bestehenden Verträgen lesen. Keine eigenen Downloads oder Änderungen geschützter Daten.
2. **Übereinstimmung vervollständigen.** Gemeinsame Gruppenbildung für Alpha und Ausschlusszählung, gültige Nenner und Modalregel absichern; Cohen-Randfälle und Meldungen behandeln; anschließend Fleiss und dessen additive Ausgabe implementieren. Früh die kleinen Unit- und K-M3a-1 bis K-M3a-4-Abnahmetests ausführen.
3. **Bias vom Regressionsrang entkoppeln.** Gültige Abweichungen und t-Zusammenfassungen gemeinsam für Gesamt- und Bedingungswerte verwenden. Den Ein-Referenzwert-Fall sowie Stichproben-, NA- und Varianzrandfälle als Klasse prüfen, entsprechend LESSONS.
4. **Linearität ergänzen.** Beide Regressionen und Ergebnisfelder, Handbuchband und analytische Bereichsprüfung implementieren. Gegen AIAG, unabhängige OLS-Rechnung, `lm`/`predict` und die beiden trennenden Bandfixtures prüfen; danach fehlende Freiheitsgrade und ungleiche Replikatzahlen.
5. **Ausgabe und Überdeckung integrieren.** Hilfe und Berichtsabschnitte 4/5 aktualisieren, installierten Helfer und Vignettenabschnitt hinzufügen, RNG und Datenherkunft prüfen. In beiden Paketkontexten rendern und die Laufzeit messen, bevor umfangreiche Regressionstests starten.
6. **Gesamten betroffenen Vertrag prüfen.** Unveränderte M3a-Abnahme und Klasse-A-Biasstudie, vollständige Unit-Tests, vorhandene E2E/Fuzz-Tests sowie die berührten älteren Bericht-/Vignettenprüfungen ausführen. Lint, Paketbau, Windows-CI und Mutation bleiben verpflichtende Gates; ihr tatsächlicher Status kommt vom Orchestrator.
7. **Handoff erstellen.** Tatsächliche Befehle, Outputs, Seeds, Paketversionen, Laufzeiten und verbleibende Einschränkungen in PROGRESS und REVIEW-INPUT dokumentieren. Das Review betrachtet den Diff ab `plan/M3a`; Diff-Ermittlung, Territoriumsprüfung und Commit erledigt der Orchestrator. Der Builder führt keine Git-Kommandos aus.

## Risiken

### Nachgewiesener Ausgangsstand und Zuständigkeiten

Eine lesende Python-Vorprüfung mit `csv`, `json` und `hashlib` hat Spalten, Zeilenanzahl und die in `value.data_file.canonical_form` festgelegte Kanonisierung geprüft. Der ausgeführte Prüflauf endete mit Exit 0; sein Output:

```text
attribute_study.csv: 450 rows; columns OK; canonical SHA-256 d64ed768122e56800de45a3ab036ffb9d40a705c94ebc9a95b899be000048c77; matches ANK-74
bias_study.csv: 15 rows; columns OK; canonical SHA-256 c31dd684517e15e55207bb905635e981c1e9e6e49de1d46dd995aa20a3835393; matches ANK-75
linearity_study.csv: 60 rows; columns OK; canonical SHA-256 dd196f84ae06fb89db94484c32dea9c9444b96559b483af67abd80572fa2780b; matches ANK-76
Data availability and canonical-content check only; no product acceptance tests executed.
```

Dies belegt die Bindung an die vorhandenen Anker, nicht eine eigene Prüfung der Originalseiten. `reference/quellen/data/aiag/QUELLE.txt` beschreibt die Lieferung und den noch ausstehenden Seitenbild-Abgleich. Zuständig dafür und für den ADR mit Datei-Hashes ist gemäß ACC-1/2 der Reviewer; für beschädigte oder künftig fehlende Dateien der Betreiber. Fehlende geschützte Dateien führen weiterhin zu benannten roten Tests, ohne Skip oder Ersatzdaten. Das ist für den Builder ein nicht blockierender `[INFRA]`-Befund, keine Aufforderung zum Ändern der Abnahme.

Eine lesende R-Abfrage ergab `irr 0.85`, `psych 2.6.9`, `DescTools 0.99.60`, `jsonlite 2.0.0`, `testthat 3.3.2`, `pkgload 1.5.3`, `knitr 1.52`, `rmarkdown 2.32`, `roxygen2 8.1.1`. Die ersten drei Pakete fehlen noch in Suggests. Eine installierte lokale Version ersetzt die deklarierte Abhängigkeit nicht.

Die gelesene effektive Konfiguration umfasst `MUT_SCOPE_REGEX='^R/.*\.R$'`, Mindestscore/Floor 80, Ratchet 2 und 14 Worker; `tests/simulation/` steht nicht in `MUT_TEST_DIRS`. `orchestrator/state/mut-baseline` ist derzeit nicht vorhanden, passend zum Betreibervermerk in BL-123. Der Builder ändert weder diese Konfiguration noch Baselines oder Gate-Auswahl. Im breiten R-Scope werden die tatsächlich seit `plan/M3a` geänderten Produktdateien mutiert; hier ist `R/agreement.R` vorgesehen.

### Technische Risiken und Gegenmaßnahmen

| Risiko / Referenz | Geplante Behandlung |
| --- | --- |
| Leere Einheiten verändern Nenner oder verschwinden vor dem Zählen; K-M3a-3/4, ACC-5/10 | Gruppierungen aus vorhandenen Zeilen vor Wertfilterung bestimmen; leere und einzelne Antworten in jedem Alpha-Bereich sowie vollständig fehlende Items gesondert testen. |
| Unterschiedliche Gewichtskonventionen der drei Cohen-Orakel; K-M3a-1, ACC-3/4 | Kategorienordnung angleichen; Übereinstimmungs- und Nichtübereinstimmungsgewichte ausdrücklich unterscheiden; Quelle und Mini-Rechnung zusätzlich zum Paketvergleich verwenden. |
| Rohfehler bei singulärer oder kleiner Regression; K-M3a-5/6, LESSONS | Rang, Restfreiheitsgrade und endliche Zwischenwerte vor Inferenz prüfen; Raster über Itemzahlen, Referenzbereiche, Rauschstufen und Seeds. Keine bloße Sonderbehandlung des AIAG-Datensatzes. |
| Bandverletzung zwischen beobachteten Referenzen; K-M3a-6, ACC-12 | Analytisches Maximum der quadratischen Ungleichung; unabhängige Extremwertrechnung sowie die Fixture `between_references`. |
| Übertriebenes Urteil aus der Zusatzrechnung; K-M3a-6, ACC-12/13 | Handbuchrechnung allein trägt das Urteil; Fixture `handbook_rejects` muss die abweichende Entscheidung der Item-Mittelwertrechnung sichtbar lassen. Hinweis auf korrelierte Replikate ist Teil der Ausgabe. |
| Vignettenknit wird in Mutation wiederholt; BL-13/46, ACC-17 | Helfer sequenziell und ohne Paket-Neuladen; Kosten des vollständigen Knits früh messen. Die historische Zeit in CRITERIA ist kein Laufzeitbeleg für die neue Implementierung. Kein Absenken von `n_sim`, kein Ausnehmen neuer Kriterien und kein Ergebnis-Cache über veränderte Produktstände. Bei einem Budgetproblem Messwerte an Reviewer/Betreiber geben. |
| Bestehende Vignetten prüfen ihre transitiven Quellen und Implementierungshashes; ADR-043, K-M1d-6 | Literal auflösbare Quellen, eigene Helfernamen/Umgebung, keine Klasse-B-Generatoren oder Ergebnisdateien anfassen; bestehende Quellen- und Reproduktionsprüfungen weiter ausführen. |
| Bericht verwendet andere Modalregeln als AP1; BL-113 | Generische Diagnose und Anwendungsentscheidung ausdrücklich beschriften; die festgelegte AP1-Bandentscheidung beibehalten. |
| Lokale Sandbox kann Mutationstreiber nicht starten; BL-86 | Keine Berechtigungsumgehung; lokale fachliche Tests ausführen, autorisierte Mutations- und Plattform-Gates dem Orchestrator überlassen und fehlende Belege offen benennen. |
| Nicht spezifizierte Randfalldetails | Die oben bezeichneten Vorschläge in PLAN-REVIEW entscheiden lassen; nach den Planrunden gilt bei schweigender Spec das Reviewer-Urteil mit ADR. Widersprüchliche Specs würden mit Fundstellen eskaliert. |

### Behandlung sämtlicher Backlog-Einträge

`BACKLOG.md` enthält 131 IDs. 41 tragen einen dokumentierten Erledigungs- bzw. Behebungsvermerk; die verbleibenden 90 werden nachfolgend einzeln behandelt. „In M3a“ bezeichnet geplante Arbeit, keinen bereits erfüllten Befund. Vertagungen ändern weder Backlog-Status noch Zuständigkeit. `[INFRA]` und `[QA-PENDING]` sind für den Builder nicht blockierend; insbesondere rechtfertigen sie keinen Eingriff in fremde Territorien.

| ID | Maßnahme oder begründete Vertagung, Zuständigkeit und Zeitpunkt |
| --- | --- |
| BL-01 | In M3a Umfang auf die sieben Kriterien und ihre Regressionen begrenzen. Frist und Vorrang des echten AP1-Laufs bleiben Betreiberentscheidung; keine zusätzliche Erhebung aus dieser Phase. |
| BL-02 | Zur AP1-/Publikationsauswertung vertagt, Betreiber/Autoren: Neuheitsabgrenzung benötigt Literatur- und Ergebnisvergleich, nicht die M3a-Rechenfunktionen. |
| BL-03 | Vorliegende M1b/M1d-Nachweise und Grenzen unverändert erhalten. Weitergehende Validierung der ordinalen Zwei-Stufen-Näherung gehört zu AP5 bzw. Statistikkernarbeit nach dem 26.11.; keine Fitänderung in M3a. |
| BL-04 | Die abgenommenen Überdeckungsbefunde der bisherigen Bootstrap-Studien erhalten. Weitere Forschung zu wenigen Stufen zu AP5/nach dem 26.11. vertagt; K-M3a-7 prüft ein anderes, ausdrücklich festgelegtes Intervall. |
| BL-05 | Betreiber bei AP1-Endauswertung: `prior_differs` und Memorisierungsvorbehalt ausweisen. M3a verändert weder Variantenmetadaten noch die fachliche Referenz. |
| BL-06 | Betreiber vor weiteren API-Erhebungen: Zugänge und Modellumleitung prüfen. M3a arbeitet offline und benötigt weder Modellaufrufe noch Schlüssel. |
| BL-07 | Bereits implementierte Routing-Festlegung beibehalten; verbleibende Provider-/Quantisierungsprüfung und Messungen über Tage beim Betreiber im AP1-Lauf. Kein Zusammenhang mit den M3a-Schätzern. |
| BL-08 | Datenschutzvereinbarung vor AP7/Partnerdaten beim Betreiber; in M3a nur vorhandene lokale und synthetische Daten. |
| BL-09 | In M3a beachten: geschützte AIAG-Blätter nur lokal lesen, keine Datenzeilen in Paket, Vignette oder Fixtures kopieren. Quellen-/Zitatpflege bleibt Reviewer/Betreiber. |
| BL-10 | Go/No-Go und Preprint-Termine bleiben beim Betreiber/den Autoren nach AP1-Auswertung. M3a liefert Methodenbelege, trifft keine Veröffentlichungsentscheidung. |
| BL-11 | Die dokumentierte Betreiberentscheidung M3b → M3a → M3d vor dem 26.11. berücksichtigen, M3c danach. Kostenmessung und Dashboard bleiben Betreiber-/Template-Aufgabe; keine neue Budgetfreigabe erforderlich. |
| BL-13 | In M3a Laufzeiten von Klasse A, Bericht und Knit messen und im Handoff nennen. Phase-Timeout und Ausführungsumgebung bleiben Betreiber-Territorium; wissenschaftliche Mindestumfänge werden nicht reduziert. |
| BL-14 | In M3a je Kennzahl die unabhängigen Belege aus der Testmatrix verwenden. M1-Nachweise bleiben erhalten; die historische Sammelposition kann der Reviewer anhand der bisherigen Abnahmen bereinigen, ohne hier weitere Kernarbeit zu eröffnen. |
| BL-15 | In M3a durch `fleiss = FALSE`/`TRUE`, Formel, Hinweise und Hilfe nach K-M3a-2 bearbeiten. Abschluss erst mit echten Abnahmebelegen. |
| BL-17 | Zu K-M3d-3 und dem vorgesehenen Live-/AP2-Nachweis vertagt; Backends und API-Aufzeichnungen sind nicht Gegenstand von M3a. |
| BL-18 | Die offene Umstellung auf SHA-256 gehört zu K-M3d-5. Die bereits bearbeiteten Bootstrap-Diagnosen aus M1c bleiben erhalten; keine Hash- oder Bootänderung in M3a. |
| BL-20 | Vorhandene Trennung von Wine-Paketvergleich und `clmm2`-Installationsprüfung erhalten. Historischen Backlog-Stand durch Reviewer mit M1b/M1d abgleichen; keine neue Fixed-Effects-Schnittstelle. |
| BL-21 | Geschachtelte NIST-Fallstudie zu späterer Anker-/Modellplanung vertagt, Reviewer/Betreiber; keines der M3a-Kriterien fordert dieses Design. |
| BL-22 | Vorhandenen Nachweis des AIAG-Poolings aus K-M1a-2 erhalten. M3a ändert weder Standardmodell noch Wechselwirkungsoption. |
| BL-23 | Bestehenden NIST-Präzisionsbericht erhalten. Weitere REML-Arbeit für hohe Offsets mit Statistikkernpflege nach dem 26.11.; M3a verwendet keine neue REML-Rechnung. |
| BL-25 | In M3a beachten: Anker aus ACCEPTANCE lesen; spätere Ergänzung ausschließlich durch Reviewer mit ADR im Meilenstein. Kein Ankerliteral als Ersatz im Produktcode. |
| BL-28 | Betreiber vor AP1: Konten, Guthaben, Limits und Benachrichtigung. Keine Schlüsselprüfung oder Kontoeinrichtung in dieser Builder-Phase. |
| BL-29 | Infevers-Anfrage/Export-/Nennungsrecht bei Betreiber/Autoren vor Nutzung der Quelle; in M3a keine neue Quelle und keine Kontaktaufnahme. |
| BL-30 | Pages-, DOI- und Release-Aufgaben zum Betreiber-Release/AP2 vertagt; M3a erzeugt weder Veröffentlichung noch Git-Aktion. |
| BL-31 | Git-Identität bleibt Betreiberaufgabe vor dessen Push. Modellrollen führen keine Git-Kommandos aus. |
| BL-33 | CLI-/Sandbox-Vorprüfung beim Betreiber vor Modellphasen; bestehende Umgebung verwenden, keine Berechtigungsfreigabe oder Umgehungsmodi in M3a. |
| BL-34 | Erreichbarkeit im Betreiber-Runbook festlegen. Ein echter Spec-Widerspruch ginge über den vorgesehenen Eskalationsweg; kein neuer Human-Touchpoint im Plan. |
| BL-35 | Benachrichtigungsfehler im Harness-Template durch Betreiber warten; projektseitig explizite Konfiguration erhalten. Keine Produktursache. |
| BL-36 | WSL-/Dateisystem-Verlagerung bei nachgewiesenem Bedarf durch Betreiber; M3a misst seine Laufzeiten, verschiebt aber weder Repo noch Quellen. |
| BL-37 | Kostenaufzeichnung pro Modellaufruf mit BL-11 zum Betreiber/Template vertagt; kein Eingriff in Logs oder Orchestrator. |
| BL-39 | Fehlende Normen/Quellen vor den jeweils betroffenen AP3/AP7-Arbeiten durch Betreiber beschaffen. Die M3a-Anker sind vorhanden und hängen davon nicht ab. |
| BL-40 | Vergleichsstudien und deren Katalogbelege bei Betreiber/Autoren vor ihrer Verwendung im Paper vervollständigen; keine neuen empirischen Vergleichszahlen in M3a. |
| BL-41 | Keine Landis-Koch-Kappa-Bänder oder unbelegten Gütegrenzen in M3a ergänzen. Quellenbeschaffung/Kritik vor einer späteren Zitierung beim Betreiber/Reviewer. |
| BL-42 | Aktuell sind die drei M3a-AIAG-Dateien vorhanden und kanonisch hashgleich, siehe Vorprüfung. `[INFRA]`: Seitenbild-Abgleich/ADR durch Reviewer in PLAN-REVIEW; weitere Quellenblätter bleiben bei ihren Meilensteinen. Builder ersetzt fehlende Daten nicht. |
| BL-43 | Live-Modellkennung, Provider-Slugs und Preise vor endgültiger AP1-Auswertung durch Betreiber überprüfen; keine aktuellen Onlineannahmen oder Änderung eingefrorener Anker in M3a. |
| BL-44 | In M3a bewusste zulässige Wahl ohne Fleiss-SE. Falls später ein SE eingeführt wird, ausschließlich Fleiss, Nee & Landis (1979), ANK-72, mit unabhängiger Prüfung; keine Verwendung der Formel von 1971. |
| BL-45 | Projektfassungen im externen Claude-Projekt nach dem Meilenstein durch Betreiber synchronisieren; außerhalb von Repo-Produkt und dieser Rolle. |
| BL-46 | In M3a den vollständigen Vignettenbau messen, public/repository prüfen und bestehende Klasse-B-Leser erhalten. Keine Kürzung des geforderten Überdeckungsumfangs zur Laufzeitkosmetik. |
| BL-47 | Bei späterer Publikation korrekt attribuieren, Betreiber/Autoren. M3a führt keine VariantBench-Zitation oder -Daten ein. |
| BL-48 | Die sieben M3a-Kriterien unten auf Testdateien abbilden. Eine allgemeine maschinelle Gate-Kriterien-Prüfung bleibt Betreiber/Reviewer beim Harness; Builder schreibt keine Gate-Auswahl. |
| BL-49 | Bestehende REML-Toleranz-/Optimiererentscheidungen erhalten. Für M3a ausschließlich passende ANK-TOL-Einträge verwenden; keine Verallgemeinerung einer REML-Toleranz auf geschlossene Formeln. |
| BL-50 | Zu K-M3c-6 nach dem 26.11. gemäß Betreiberreihenfolge vertagt; Fallzahl-CV und Randlösungen sind kein M3a-Vertrag. |
| BL-51 | Exportentscheidung für `acmg_*` nach AP1 mit ADR beim Betreiber/Reviewer; M3a benötigt keine neuen Exporte. |
| BL-52 | Betreiber soll AP1 mit dem abgenommenen Statistikkern auf demselben externen Store erneut auswerten. Das ist nach M1d fällig, aber kein lokaler M3a-Buildschritt. |
| BL-55 | In M3a beachten: auch ignorierte Betreiberdateien nicht während einer Modellphase verändern. Weiterentwicklung der Territoriumsprüfung beim Betreiber; Änderungen zwischen den vorgesehenen Phasenfenstern. |
| BL-57 | In M3a ausdrücklich prüfen, dass `fleiss` hinter `weights` steht und den Vorgabewert `FALSE` hat. Kein alleiniger Verlass auf die schwächere API-Obermengenprüfung; ANK-02 unverändert. |
| BL-60 | ellmer-/httr2-Transport mit den Aufzeichnungen in K-M3d-3 prüfen; kein Backend-, Streaming- oder API-Auftrag für M3a. |
| BL-64 | Pilotregeln in gesonderter AP1-Pflege, gegebenenfalls M3d, präzisieren. Keine Änderung an `acmg_pilot()` für die Übereinstimmungs- und Biasabnahme. |
| BL-68 | Irreführendes „store unchanged“ beim nächsten AP1-CLI-/Berichtsauftrag korrigieren; betrifft `R/acmg.R`, nicht die M3a-Rechnung. |
| BL-70 | Status-, Timeout- und Transportfehlerbehandlung ins Harness-Template vertagt, Betreiber. M3a dokumentiert echte Abbrüche, ändert aber keine Modellaufrufsteuerung. |
| BL-71 | Betreiber vor finaler AP1-Auswertung: archivierte Memorisierungsproxies/Quellenentscheidung treffen. Neue Golden-Daten bräuchten ADR und Abnahme; beides liegt außerhalb von M3a. |
| BL-72 | Bereits erfolgte Plattformkorrekturen erhalten; in neuen Tests normalisierte Pfade, Windows-taugliche Ressourcen und strikt geprüfte Toleranzschlüssel verwenden. Keine erneut verlangte Kernänderung aus dem historischen Hinweis. |
| BL-73 | Pilot-Kosten-/Reasoning-Spalten vor endgültigem AP1-Bericht in gesonderter Anwendungspflege vervollständigen; M3a ändert nur Berichtsteile 4/5 und keine Pilotbewertung. |
| BL-74 | API-Latenz und Blocklaufzeit beim Betreiber für AP1 planen; offline berechnete M3a-Tests lösen dieses Erhebungsproblem nicht. |
| BL-75 | Wartezeitanteile im nächsten AP1-Reporting-Auftrag getrennt ausweisen; Erhebungsmetadaten und Wiederholungslogik bleiben außerhalb von M3a. |
| BL-77 | QA/Reviewer sollen Befunde auf wörtliche Quellen prüfen; im Plan werden Belege mit Fundstelle verwendet. Änderungen an QA-Prompts oder QA-Dateien sind keine Builderarbeit. |
| BL-79 | Archivierung früherer Mutationsberichte durch Betreiber im Harness; Builder hält den tatsächlich verfügbaren Lauf und Pfad im Handoff fest, schreibt aber keine Gate-Logs. |
| BL-80 | Spec-Korrektur des NIST-Offsets durch Betreiber/Reviewer bei nächster Spec-Pflege; kein Einfluss auf die Datenrechnung und kein M3a-Produktfix. |
| BL-81 | PROGRESS M1b BUILD beschreibt die Behandlung fehlender Gruppierungswerte zu E3/K-M1b-6. Reviewer soll den alten offenen Eintrag mit diesem Nachweis abgleichen; keine ungeprüfte Schließung und kein erneuter Fitumbau in M3a. |
| BL-84 | Verbleibende numerische Mutationstestlücken zur Kernpflege nach dem 26.11. vertagt. Neuer M3a-Code erhält zielgerichtete Tests, aber keine Ausweitung auf unveränderte Fitpfade. |
| BL-85 | Approval-Zuordnung robuster machen: Betreiber/Reviewer. Keine Übertragung alter Äquivalenzfreigaben auf neue Zeilen; nötige Builder-Claims später nur pro nachweislich äquivalentem Mutanten. |
| BL-86 | `[INFRA]`: Mutationstreiber und Plattform-Gates in geeigneter Betreiberumgebung ausführen. Keine Sandbox-Umgehung; lokale Prüfumfänge und Grenzen ehrlich dokumentieren. |
| BL-87 | Hochpräzisions-/Konvergenzproblem der numerischen Fits für getrennte Kernarbeit nach dem 26.11. beibehalten. Bestehende Befunde nicht verdecken; ADR-035 liefert keine Ausnahme für M3a-Kriterien. |
| BL-91 | Vorhandene Dokumentation der latenten Invarianzgrenzen erhalten; weitergehende Optimierer-/Ankerentscheidung zu späterer Kernpflege mit Reviewer. M3a ändert keine Toleranz. |
| BL-93 | Veraltete lme4-Helferaufrufe in Abnahmetests durch Reviewer bei nächster Abnahmepflege ersetzen. Für Builder nonblocking; kein neuer Produkt-Import nur zur Reparatur fremder Tests. |
| BL-100 | Numerischer Durchreichweg/subset-Konfundierung ausdrücklich nach dem 26.11. in Kernpflege; keine Änderung an `msa_fit()` in M3a. |
| BL-101 | Stufenauswahl bei Gewicht null nach dem 26.11. in latenter Kernpflege; unabhängig von den M3a-Einheiten mit fehlenden Antworten. |
| BL-102 | Verbleibende latente Mutationstestbefunde nach dem 26.11.; keine pauschale Äquivalenzannahme und keine Mitänderung von `R/fit.R`. |
| BL-103 | Projektkorrektur aus ADR-039 und wiederhergestellte Quellen berücksichtigen. Restprüfung/Template-Übernahme beim Betreiber; keine Löschung oder Wiederherstellung ignorierter Quellen durch den Builder. |
| BL-105 | `[INFRA]`: Betreiber soll Rundenverbrauch ohne Builder-Befund vermeiden. Datenvorprüfung und klare Ursachen im Handoff helfen; ein Infrastrukturfehler wird weder durch Produkt-Scheinfix noch schwächere Tests behandelt. |
| BL-106 | `[INFRA]`: Commit-/Territoriumsbasis bei Betreiberänderungen durch Betreiber sichern; keine externen Änderungen zwischen BUILD und GATES. Keine Zustandskorrektur durch Builder. |
| BL-107 | Tatsächlicher R-Scope und Ratchet sind aktuell wieder gesetzt, siehe Vorprüfung. Scope-ohne-Treffer und rundenübergreifende Wiederverwendung bleiben Harness-Aufgaben beim Betreiber; M3a setzt keinen Ausnahme-Scope. |
| BL-108 | REML-Abbruch bei hoher Wiederholbarkeit nach dem 26.11. mit BL-87 bearbeiten; kein Zusammenhang mit der hier geschlossenen Bias-/OLS-Rechnung. |
| BL-109 | Bereits vorhandene Erklärung der latenten Repeatability erhalten. AP1-Sensitivität mit Wechselwirkungen bleibt Betreiberarbeit bei der Endauswertung; keine neue latente Kennzahl in M3a. |
| BL-110 | Härtung manipuliert eingelesener Klasse-B-CSV nach dem 26.11. in Validierungspflege. M3a fügt keine solche Ergebnisdatei hinzu und verändert die Leser nicht. |
| BL-113 | In M3a Modalregel und fehlende Antworten in Hilfe und Berichtsteil 4 kennzeichnen; AP1-Urteilswert bleibt getrennt maßgeblich. Fachliche Festlegung siehe Schnittstellen. |
| BL-114 | Paketgröße/Archivierung der Klasse-B-Vollläufe zur Release-/CRAN-Arbeit nach dem 26.11. vertagt, Betreiber/Builder nach gesondertem Auftrag. Für Abnahme erforderliche Ergebnisse bleiben erhalten. |
| BL-115 | Locale-Abhängigkeit des Bootstrap-Implementierungshashs nach dem 26.11. separat beheben. M3a prüft unter geeigneter UTF-8-Umgebung und regeneriert keine Klasse-B-Belege. |
| BL-117 | Härtung manuell veränderter Findings-CSV nach dem 26.11.; bestehende Leser unverändert, kein M3a-Kriterium und kein Anlass zur Neuerzeugung abgenommener Ergebnisse. |
| BL-119 | Betreiber entscheidet vor Verwendung im Paper über die Extraktionsregel. Bis dahin gelten die Zahlen als Ergebnisse der dokumentierten Regel; neue Regel würde Golden-ADR und erneute M1d-Abnahme verlangen. M3a ändert keine Extraktion. |
| BL-121 | Trotz geplanter Suggests-Ergänzung bleibt die pkgdown-URL dem ausdrücklich vorgesehenen Release-Auftrag nach dem 26.11. zugeordnet; unabhängige Veröffentlichungspflege wird nicht in M3a gezogen. |
| BL-123 | Betreiber hat die M3a-Baseline entfernt; derzeit fehlt die Datei. Für spätere M3-Scopewechsel und dauerhafte Scope-Bindung bleibt Betreiber zuständig. Builder schreibt keine Baseline und übernimmt nicht den M3b-Score als M3a-Schwelle. |
| BL-124 | Hohe ordinale Item-Varianz/Laplace-Bias benötigt eigene Fitdokumentation, Methodenentscheidung und Recovery-Szenario; gesonderte Kernarbeit, vor Verwendung entsprechender Paper-Aussagen zu beurteilen. M3a liefert dafür keine Evidenz und ändert `msa_fit()` nicht. |
| BL-125 | Option für alle PB-Kontraste nach erster Veröffentlichung; AP1-Sensitivität beim Betreiber. Der abgenommene M3b-Vertrag bleibt außerhalb von M3a. |
| BL-126 | Kalibrierte ME-/SME-Schranken nach erster Veröffentlichung, mit Lenth-Vorgabe beibehalten. Kein neues Robustheitsargument in M3a. |
| BL-127 | Defensive PB-/Robustheitsvalidierung nach dem 26.11. bzw. erster Veröffentlichung, sobald der Vertrag dies vorsieht. Keine gekoppelte Änderung der Robustheitsobjekte. |
| BL-128 | Beim nächsten Eingriff in Robustheitscode/-tests, frühestens M3d oder danach: Momentaufnahmen kennzeichnen und Zeilenumbruch testen. Für neue M3a-Tests gilt die Lehre sofort; keine alten Mutanten automatisch freigeben. |
| BL-129 | Robustheitsgrafik beim nächsten Grafikauftrag/nach dem 26.11. verbessern. M3a benötigt weder diesen Plot noch eine Änderung seiner Vertragsgrenzen. |
| BL-130 | Skalenkennzeichnung des Logit-Pfads in M3d nach K-M3d-4/-6 entscheiden. Berichtsteil 6 und Robustheitsobjekt bleiben im M3a-Plan unverändert. |
| BL-131 | `[QA-PENDING]`: Toleranzen, Generatoren, Optionen und Orakelpflicht in den M3b-QA-Dateien durch QA in der nächsten sie berührenden QA-Phase korrigieren. Für Builder nonblocking; neue Builder-Tests lesen Anker und überspringen erforderliche Orakel nicht still. |

Die folgenden IDs haben im gelesenen BACKLOG einen Erledigungs-/Behebungsvermerk; sie werden nicht als neue M3a-Arbeit geöffnet:

```text
BL-12, BL-16, BL-19, BL-24, BL-26, BL-27, BL-32, BL-38,
BL-53, BL-54, BL-56, BL-58, BL-59, BL-61, BL-62, BL-63,
BL-65, BL-66, BL-67, BL-69, BL-76, BL-78, BL-82, BL-83,
BL-88, BL-89, BL-90, BL-92, BL-94, BL-95, BL-96, BL-97,
BL-98, BL-99, BL-104, BL-111, BL-112, BL-116, BL-118,
BL-120, BL-122.
```

Die bei BL-104 noch genannte Übertragung ins Harness-Template bleibt Betreiberarbeit; die Projektkorrektur gilt als erledigt. BL-24 ersetzt nicht die weitere Scope-bezogene Baseline-Aufgabe aus BL-123. Historische Fortschrittsstände werden in einer späteren BUILD-Dokumentation nur anhand tatsächlich vorliegender Gate-/Reviewer-Belege fortgeschrieben.

## Testplan

### Unabhängige Nachweise je Kriterium

Alle aufgeführten Fachtests sind geplante BUILD-/Gate-Prüfungen. Die PLAN-Phase hat keine Produkt-, Abnahme-, Simulations- oder Mutationstests ausgeführt. Die oben dokumentierten lesenden Vorprüfungen sind kein Ersatz dafür. Abnahmetests und deren Mini-Referenzen werden unverändert genutzt, nicht in den Produktcode kopiert.

| Kriterium | Unabhängige Belege | Wichtige Fälle und Abnahmedatei |
| --- | --- | --- |
| K-M3a-1 | ANK-70 und Formel-Nachrechnung; live `irr::kappa2`, `psych::cohen.kappa`, `DescTools::CohenKappa`. Numerische Vergleiche nach ANK-TOL.package_compare. | Cohen-Tafel, `irr::vision`, alle 15 Paare von `irr::diagnoses`, konstruierte Tafeln mit zwei bis fünf Kategorien, leere Ränder, Ein-Kategorie-Skala, `NA` statt `NaN` mit signalisierter Bedingung. `test-m3a-1-cohen-kappa.R`. |
| K-M3a-2 | ANK-72 mit ungerundeter Formel-Nachrechnung und live `irr::kappam.fleiss`. | Drei Anordnungen derselben sechs Bewertungen, zufällige Tabellen einschließlich gleicher gültiger Anzahlen trotz NA; ungleiche Anzahlen, zu wenige Bewertungen, konstanter Fall; Default ohne Zusatzfeld. `test-m3a-2-fleiss-kappa.R`. |
| K-M3a-3 | ANK-73/Koinzidenzrechnung und live `irr::kripp.alpha` für jede Metrik. | Beobachter als Prompts bzw. Replikate; alle vier Bereiche, gezählte leere/einzelne Einheiten; Alpha unverändert beim Anhängen solcher Einheiten; jede Gewichtszuordnung trifft die richtige, nicht die anderen Metriken. `test-m3a-3-krippendorff-alpha.R`. |
| K-M3a-4 | Handgezählte kleine Fixtures und unabhängige Schleifenreferenz; zusätzlich ANK-74 mit geschützter AIAG-Studie und rekonstruierter Kreuztabelle/Cohen-Rechnung. | D1/D2, ausschließlich fehlendes Item, Gleichstand zwischen anderen als der ersten Skalenkategorie, alle Nenner und Gruppierungen; AIAG-Kappa und Attributtabelle. `test-m3a-4-attribute.R`. |
| K-M3a-5 | ANK-75 und unabhängige t-Formel; zusätzlich `stats::t.test` auf denselben Abweichungen, gesamt und je Prompt × Modell. | Ein Referenzwert ohne Regressionsfehler, mehrere Bedingungen, 90-/95-%-Niveau, fehlende Antworten und kleine Stichproben. Der p-Wert wird gegen die Live-Rechnung geprüft; keine angeblich gedruckte Zahl ergänzen, wenn die Quelle nur t berichtet. `test-m3a-5-bias.R`. |
| K-M3a-6 | ANK-76 und unabhängige OLS-/Extremwertrechnung; zusätzlich `stats::lm`, `summary` und `predict(..., interval = "confidence")`. | Einzelwerte und Itemmittel mit korrekten Freiheitsgraden; R² als Anteil; `between_references`, `handbook_rejects`, Niveauwechsel, gleiche Referenzen und ungleiche Replikatzahlen; Methodentext im Objekt und gerenderten Bericht. `test-m3a-6-linearity.R`. |
| K-M3a-7 | Unveränderte unabhängige Klasse-A-Simulation mit t-Mini-Referenz für jede Intervallgrenze; zusätzlich aus dem geladenen Paket berechnete Vignettentabelle. | Beide Szenarien, ANK-06, feste Seeds/RNG, vollständiger Nenner, gemessene MCSE, ANK-TOL.mc_factor, Laufzeit und Metadaten; keine Ergebnisliterale. `tests/simulation/test-bias-coverage.R`, `test-m3a-7-vignette.R`. |

Literaturtoleranzen kommen aus dem jeweiligen Anker, Rechentoleranzen aus ANK-TOL (`arithmetic`, `package_compare`, passende Simulationsschwellen). Kleine konstruierte Beispiele werden mit Herkunft und Handzählung als Fixtures markiert. Fehlende Ankerfelder oder erforderliche Orakelpakete erzeugen benannte Fehler. Es werden weder erwartete Paketoutputs eingefroren noch neue pauschale Epsilonwerte eingeführt.

### Randfälle, Invarianzen und Regressionen

- Zeilenreihenfolge und Umbenennung von Item-/Prompt-/Modell-IDs ändern die Kennzahlen nicht. Kategorien werden bei ordinalen Gewichten nur unter Erhalt ihrer Skalenordnung umbenannt; die nominale Rechnung verträgt beliebige Kategorienpermutation.
- Eine andere Verteilung derselben Bewertungen auf Prompts/Modelle/Replikate lässt Fleiss über alle Bedingungen gleich, während bereichsbezogene Alpha-/Attributwerte nur gemäß ihrer tatsächlichen Gruppierung verglichen werden.
- Fehlende und unparsebare Antworten, alle Antworten fehlend, einzelne gültige Antworten, leere Randkategorien und konstante Daten werden je betroffenem Pfad geprüft. Kein `NaN`, keine rohe Indizierungs-/Engine-Meldung als zufälliger Ersatz für eine definierte Randfallantwort.
- Gleiches Verschieben von numerischer Antwort und Referenz erhält die Abweichungen. Gemeinsame positive Skalierung skaliert Bias und Intervall; die OLS-Koeffizienten und das Band folgen der entsprechenden Transformation. Eine Referenzachsenverschiebung wird mit veränderter Achsenabschnittsparametrisierung, nicht mit falscher Interzept-Invarianz, geprüft.
- Für die Bandentscheidung werden innere Extrema, beide Randpunkte, flache Geraden und schrumpfende Reststreuung über mehrere konstruierte Pläne geprüft. Das Raster ergänzt die analytische Referenz; es ersetzt sie nicht.
- `formals()` gegen den unveränderten API-Anker prüfen: bisherige Namen, Positionen und Defaults, anschließend `fleiss = FALSE`. Vorhandene Objektfelder und Aufrufe ohne Fleiss bleiben nutzbar. Alte Bias-/Agreement-Objekte rendern ohne neue Felder.
- Bestehende `test-agreement.R` und `test-report.R`, die numerischen/latenten Vignettenprüfungen und die zwei M1d-Anwendungsvignetten bilden den Regressionsumfang. Insbesondere bleiben AP1-Urteil, M1d-Findings, Klasse-B-Reproduktionsbelege und Robustheitsausgabe erhalten.
- Die neuen Vignettenquellen werden durch die bestehenden transitiven Quellen-/Literalprüfungen erfasst. Die neue Berechnung darf weder deren Auflösung verhindern noch ein unverändertes Paket über den geladenen Namespace legen.
- Ausgabeprüfungen unterscheiden Vertragsaussagen und Zahlenherkunft von eigenen Formatmomentaufnahmen; Letztere werden als solche gekennzeichnet (Lehre BL-128). Englische Testnamen, Meldungen und Dokumentation.

### Vorgesehene Ausführung und Belege

Die folgenden Befehle sind für BUILD vorgesehen und wurden in PLAN nicht ausgeführt. Die gefilterten Testauswahlen benötigen keine Git-Unterprozesse; die gesamte historische Abnahmesuite enthält Git-basierte Prüfungen und wird deshalb vom Orchestrator gestartet.

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
testthat::test_dir("tests/acceptance", filter = "^m3a-",
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

Danach vollständige Unit-/E2E-/Fuzz-Läufe nach dem bestehenden Runner und gezielte ältere Bericht-/Vignettenregressionen. Installations-/Renderprüfungen erfolgen in temporären Bibliotheken bzw. Paketkopien: einmal mit gültigem `REPO_ROOT`, einmal als öffentliches Paket ohne Harness und geschützte Quellen. Der öffentliche Build benötigt für die neue Biasstudie nur die synthetischen Einstellungen und bereits installierten, verifizierten Anker. Der vollständige `R CMD build`/`R CMD check` und die Plattform-/Lint-Gates entscheiden über die Paketfreigabe; ihre Regeln bleiben unverändert.

Die gesamte Klasse-A-Suite muss weiterhin innerhalb `ANK-TOL.sim_runtime` bleiben; `tests/simulation/` wird nicht in Mutation aufgenommen. Das Mutations-Gate prüft den geänderten R-Code mit dem bestehenden Testumfang und ANK-32, ohne neue Ausnahmen. Zielgerichtete Tests müssen insbesondere veränderte Nenner, Gewichte, NA-Abzweige, Freiheitsgrade, Bandentscheidung, Meldungen und ausgegebene Methodenwerte unterscheiden. Überlebende werden anhand eines reproduzierbaren Unterschieds behoben oder einzeln mit echter Äquivalenzbegründung dem Reviewer vorgelegt; der Builder genehmigt nichts selbst.

In BUILD werden pro ausgeführtem Prüfschritt Befehl, Exitstatus, echter Ergebnisoutput und Laufzeit festgehalten, für Simulationen zusätzlich Seed, RNG, `n_sim`, MCSE und Versionen. Nicht ausgeführte oder infrastrukturell gescheiterte Schritte werden ausdrücklich so bezeichnet. Ein erfülltes Kriterium oder ein grünes Gate wird erst mit diesem Beleg gemeldet.

Die lesende Dokumentprüfung dieser PLAN-Datei wurde mit Python 3 (`pathlib`, `json`, `re`) gegen SCHEMA, die sieben IDs aus CRITERIA.json und die 131 Zeilen-IDs aus BACKLOG.md ausgeführt, Exit 0. Geprüft wurden Abschnittsreihenfolge, Kriterienzuordnung, eine eigene Maßnahmenzeile für jede offene/teilweise offene ID, fehlende/zusätzliche IDs und doppelte Maßnahmenzeilen. Echter Output, ohne die reine Dateigrößenzeile:

```text
PLAN schema: 6 required sections, in order
Criteria coverage: 7/7 IDs present
Backlog coverage: 90/90 open or partial entries individually addressed; 41/41 completed entries recorded; 131/131 IDs covered
Static document checks only; no product tests executed.
```
