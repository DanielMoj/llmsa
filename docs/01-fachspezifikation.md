<!-- projektierung_llmsa/docs/01-fachspezifikation.md -->
# 01 — Fachspezifikation: Querschnitt und M0

Bindender Inhalt für alle Meilensteine (Prüfstandard, Konventionen, Schnittstellenregel, Quellen, Daten, Simulationen) und die Kriterien von M0. Fachliche Kriterien stehen in `02-statistikkern.md` (M1a–M1d), `03-anwendungspipeline.md` (M2) und `04-weitere-bausteine.md` (M3a–M3d). Erwogenes, aber nicht Entschiedenes steht in `reference/privat/90-katalog-offen.md` und ist nicht bindend.

## 1. Geltung und Vorrang

- Präzedenz: Spec > Reviewer > Builder. Diese Dateien binden nach Betreiberfreigabe alle Rollen; Änderungen am Spec-Text nur durch den Betreiber. Schweigt die Spec, hält der Reviewer die Auslegung in einem ADR unter `docs/decisions/` fest (SPEC-KONTRAKT, Abschnitt 6).
- Kriterien heißen `K-M<x>-<n>` und nennen Artefakt oder Verhalten, Zielpfad, Ja/Nein-Bedingung und Prüfweg (`Test` = Abnahmetest unter `tests/acceptance/` oder `tests/simulation/`, `Gate` = Gate-Skript, `Judge` = eindeutige Ja/Nein-Entscheidung des Reviewers mit Beleg). Zahlen stehen nur als `ankerRef: ANK-nn` oder, bei Toleranzen und Betreiberfestlegungen, als benannter Eintrag des Toleranzankers `ANK-TOL.<name>` (eine Datei `reference/anchors/ANK-TOL.json`); die Werte erhebt beziehungsweise bestätigt der Reviewer nach `ANKER-TODO.md` unter `reference/anchors/`.
- Zwei Belegdokumente sind Teil der Spec und liegen unter `reference/privat/`: `07_Formelsammlung_llmsa.md` (Fassung nach Zweitprüfung 24.10.2026; Status je Formel in Abschnitt 3 unten) und `QUELLENKATALOG.md`. Weicht der Code von einer Soll-Formel ab, gilt die Formelsammlung; weicht die Formelsammlung von ihrer Quelle ab, gilt die Quelle, und der Reviewer dokumentiert den Befund als ADR.
- Sprache: Spezifikationen, ADRs, Handoffs, `BACKLOG.md`, `PROGRESS.md` deutsch. Alles im Paket (`R/`, `man/`, `vignettes/`, `inst/`, `NEWS.md`, `README.md`, Testnamen, Commit-Nachrichten) englisch.

## 2. Prüfstandard (bindend)

1. Nichts gilt als geprüft, weil ein Test grün ist. Ein Test zählt erst, wenn er ein falsches Ergebnis erkennen würde. Plausibilitätsprüfungen („obere Grenze über der unteren“) sind Beiwerk, nie Beleg.
2. Jede Kennzahl hat mindestens zwei unabhängige Belege aus drei Arten: (a) Literatur- oder zertifizierter Referenzwert mit Fundstelle, (b) eigene Nachrechnung im Test (etwa erwartete Mittelquadrate von Hand), (c) Gegenrechnung mit einem etablierten Paket auf denselben Daten. Welche zwei je Baustein gelten, legen die Kriterien fest.
3. Wo es keine geschlossene Lösung gibt (Intervalle, Bootstrap, Tests, Fallzahlplanung, Ersatzverfahren), entscheidet eine Simulationsstudie nach ADEMP (Morris, White & Crowther 2019) mit festem Seed, mindestens `ankerRef: ANK-06` Wiederholungen je Szenario und angegebenem Monte-Carlo-Standardfehler für jede berichtete Kennzahl (Formeln: Formelsammlung §9). Berichtet wird, was herauskommt, nicht was herauskommen soll; eine Unterdeckung ist ein Befund, kein Testfehler, solange sie berichtet wird. Wo ein Simulationsergebnis gegen einen Nominal- oder Literaturwert geprüft wird, gilt als Übereinstimmung eine Abweichung von höchstens `ANK-TOL.mc_factor` Monte-Carlo-Standardfehlern (Bestehenskriterium; für Befunde, die nur berichtet werden, gilt die kleinere Berichtsschwelle desselben Ankers).
4. Randfälle sind Pflicht: fehlende Werte, unbalancierte Pläne, Komponenten an der Grenze null, Faktoren mit zwei Stufen, identische Antworten, nicht konvergierende Fits. Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.
5. Invarianzen: Zeilenreihenfolge, Umbenennen von Stufen und Verschieben der Messwerte ändern nichts (Toleranz `ANK-TOL.invariance`); Skalieren mit c skaliert Varianzen mit c² und lässt %GRR, %Contribution, ndc und Verdikt unverändert.
6. Referenzwerte stammen ausschließlich aus `reference/anchors/*.json` (Quelle, Seite, Wert, Einheit, Toleranz, Kurzzitat, Abrufdatum) oder aus einem im Kriterium benannten Orakel (etabliertes Paket auf denselben Daten). Toleranz für publizierte Werte: halbe Einheit der letzten publizierten Stelle, sofern der Anker nichts anderes belegt. Toleranzen für Varianzkomponenten gelten je Komponente als Anteil der Gesamtvarianz σ²_TV der Vergleichsrechnung, nie relativ zur einzelnen Komponente (Komponenten nahe null); abgeleitete Kennzahlen relativ, ndc und Verdikt gleich. Nie aus dem Modellgedächtnis.
7. Mutationstests: Ein verfälschter Kern muss einen Test rot machen. Statistikkern (`R/fit.R`, `R/grr.R`) mindestens `ANK-32` erkannte Mutanten (Kriterium K-M1c-6); die übrigen Dateien ab M3 über das mutgate mit derselben Schwelle.
8. Zwei Ebenen: schnelle Tests unter `tests/testthat/` laufen im `R CMD check`; die Validierungssuite (Abnahmetests, Simulationen Klasse A, Klasse-B-Ergebnisse) läuft im Harness und ist in der Vignette `vignettes/validation.Rmd` dokumentiert (Abschnitt 8).

## 3. Status der Formelsammlung

Die Formelsammlung ist bindend mit folgenden Festlegungen zu ihrem Abschnitt 12:

| Nr. | Stelle | Festlegung | Meilenstein |
| --- | --- | --- | --- |
| 1 | Fleiss' Kappa | implementieren als Option von `msa_agreement()`; Varianz nach Fleiss, Nee & Landis (1979) nur, wenn ein Standardfehler ausgegeben wird | M3a |
| 2 | Linearität | Handbuchrechnung (alle g·m Einzelwerte, gm − 2 Freiheitsgrade) bleibt und trägt das Verdikt (Vertrauensband, „Bias = 0 im Band“); zusätzlich wird die Regression auf die Item-Mittelwerte (g − 2 Freiheitsgrade) ausgewiesen und der Unterschied im Bericht benannt | M3a |
| 3 | Zwei-Stufen-Faktor (ordinal), β²/2 | per ADEMP quantifizieren; Verhalten nach K-M1b-4 | M1b |
| 4 | Bootstrap ordinal | nicht im Scope (AP5), Katalog | – |
| 5 | Bootstrap-Ausgabe | umsetzen: nicht endliche und singuläre Wiederholungen getrennt zählen und melden | M1c |
| 6 | R_4s | beide Lesarten als Option `r4s = c("range", "westgard")`; Vorgabe bleibt die Spannweiten-Lesart des Codes; Bericht und `print` nennen die Lesart | M3c |
| 7 | ndc-Konstante 1,41 | bestätigt | M1a |
| 8 | Verdikt an 10,0 % und 30,0 % „bedingt“ | bestätigt | M1a |
| 9 | Datenhash | SHA-256 über die kanonische Form (§11) ersetzt MD5; Algorithmus im Bericht | M3d |
| 10 | Modell ohne Block- und Dreifach-Wechselwirkungen | bestätigt; im Bericht benannt | M3d |
| 11 | EWMA | nicht im Scope, Katalog | – |
| 12 | Binär, Beobachtungsskala | nicht im Scope, Katalog; Abnahme gegen rptR nur auf der Link-Skala | – |
| 13 | %Contribution-Schwellen 1 % und 9 % | bestätigt als Konvention; im Bericht so benannt | M3d |
| Zusatz | OpenRouter-Routing durchreichen und speichern | umsetzen | M2 |

Mit (!) markiert und ungeprüft bleiben nur die DIN-32645-Formeln (§10, AP7); sie sind nicht im Scope und erzeugen kein Kriterium. Keine andere Stelle trägt (!).

## 4. Schnittstellenregel

Die 22 exportierten Funktionen von v0.1.0 (NAMESPACE bei Commit `332a2d5`: `as_msa_runs`, `backend_ellmer`, `backend_mock`, `backend_openai_compatible`, `msa_agreement`, `msa_bias`, `msa_boot`, `msa_control_chart`, `msa_counts`, `msa_design`, `msa_fit`, `msa_grr`, `msa_plan`, `msa_report`, `msa_robustness`, `msa_run`, `msa_simulate`, `parse_choice`, `parse_identity`, `parse_json_field`, `parse_number`, `pb_design`) behalten ihre Schnittstellen.

- Ohne ADR erlaubt: neue exportierte Funktionen; neue Argumente mit Vorgabewert am Ende der Argumentliste; zusätzliche Felder in Rückgabeobjekten; zusätzliche Attribute; geänderte Druckausgabe (`print`-Methoden); neue S3-Methoden.
- Nur mit ADR und Übergangsfrist: Entfernen, Umbenennen oder Umsortieren von Argumenten; geänderte Vorgabewerte; Entfernen oder Umbenennen von Rückgabefeldern; geänderte Klassennamen; geänderte Bedeutung eines Arguments. Übergangsfrist: die alte Form funktioniert mindestens eine Minor-Version mit `warning()` (lifecycle-Hinweis in der Dokumentation).
- Prüfung: Abnahmetest gegen den API-Snapshot `reference/anchors/ANK-02.json` (Exportliste und `formals()` jeder Funktion, erhoben aus Commit `332a2d5`) ab M0 als Obermengenprüfung: jede Funktion des Snapshots ist exportiert, jedes ihrer Argumente ist vorhanden, trägt denselben Vorgabewert (`deparse`) und steht an derselben Position; zusätzliche Exporte und zusätzliche Argumente hinter den Snapshot-Argumenten bestehen den Test ohne Änderung des Snapshots. Der Snapshot ist der Anker selbst und ändert sich nur, wenn eine bestehende Schnittstelle sich ändert, und dann zusammen mit dem ADR (Gate golden-adr, K-M0-7). Ein Gleichheitstest wäre mit der Regel „ohne ADR erlaubt“ unvereinbar, weil jeder neue Export ein ADR erzwänge.

## 5. Konventionen

- AIAG: ndc = ⌊1,41 · σ_PV/σ_GRR⌋; Verdikt nach % Studienvariation mit Schwellen 10 und 30, genau 10,0 % und 30,0 % sind „bedingt“ (`marginal`); Basis `contribution` mit 1 und 9 als Konvention. Schwellen sind Vorgaben, der Bericht übernimmt sie aus Context of Use und Risikostufe (`ANK-16`).
- Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit) (`ANK-28`); AIAG-Schwellen dort nur Konvention, im Bericht so benannt.
- Namensschema: `msa_*` für Kernfunktionen; `acmg_*` für die Anwendungspipeline (M2) als interne Funktionen (`@keywords internal`, nicht exportiert, Aufruf über `llmsa:::` in Abnahmetests und `inst/validation/ap1/`; Export erst nach AP1 per ADR, BL-51); `parse_*`, `backend_*`, `pb_*` bleiben. Englisch in Code, Kommentaren, Dokumentation, Fehlermeldungen. roxygen2, testthat 3. Edition.
- Parallelisierung: In `R/` kein `parallel::mclapply`, `mcmapply`, `mcparallel`, `pvec` und kein `bootMer(parallel = "multicore")`; erlaubt sind sequentielle Ausführung oder `parallel = "snow"` mit einem vom Aufrufer übergebenen Cluster (Vorgabe sequentiell). In `tests/simulation/` und `inst/validation/sim/` ist `mclapply` zulässig (WSL). Grund: Windows-CI ist Release-Bedingung (AP2), wird aber bei `PUSH_REMOTE=0` vor dem Push nie geprüft; `msa_boot()` ist der erste Kandidat. Prüfweg: Suchmuster-Test über `R/` ab M1c (K-M1c-1) und Code-Review.
- Abhängigkeiten: Imports bleiben `lme4`, `ordinal`, `stats`, `graphics`, `tools`, `utils`; neue Imports nur mit ADR. Suggests dürfen ergänzt werden; die Validierungssuite nutzt `VCA`, `SixSigma`, `irr`, `psych`, `DescTools`, `rptR`, `performance`, `FrF2`, `unrepx`, `qcc`, `daewr`, `muttest`, `httptest2`, `digest` als Suggests; Tests unter `tests/testthat/` überspringen mit `skip_if_not_installed()`, Abnahmetests nicht (das deps-Gate installiert Suggests).
- Seeds: jede Randomisierung (Laufreihenfolge, Plackett-Burman-Zuordnung, Bootstrap, Simulation, Datenauswahl) trägt einen protokollierten Seed; Simulationen nennen RNG (`Mersenne-Twister`, `sample.kind = "Rejection"`), R- und Paketversionen (`sessionInfo()`).
- Fehlende oder nicht parsbare Antworten bleiben fehlend und werden gezählt, nie ersetzt.
- Keine neuen Daten erfinden: scheitert Download, Parse oder Validierung, bricht die Funktion benannt ab. Fixtures sind klein und als solche markiert.

## 6. Quellen, Anker, Orakel

- `reference/privat/QUELLENKATALOG.md` (git-ignoriert) nennt je Quelle Schlüssel, Datei, Textspiegel, Zweck, Formelsammlung-Abschnitt, Fundstellen und Lizenz. Der Textspiegel liegt unter `reference/quellen/text/` (git-ignoriert, Suche mit `grep`); Originale (PDF, EPUB) bleiben in `Llmsa\quellen\` außerhalb des Repos. Kein RAG; die Rollen suchen mit `grep` und prüfen Zahlen aus OCR-Texten am Original (Katalog-Hinweis).
- Anker erntet der Reviewer in der ACCEPTANCE-Phase nach `ANKER-TODO.md`. Jede spätere Änderung unter `reference/anchors/` braucht ein ADR im selben Meilenstein (Gate golden-adr). Nicht verifizierbare Anker bleiben blocking offen; nichts wird geschätzt.
- Geschützte Beispieldaten (AIAG-Datenblätter, Fleiss' Tabelle 1 außerhalb von `irr::diagnoses`, Lenth 1989 Tabellen) liegen als CSV unter `reference/quellen/data/<quelle>/` (git-ignoriert); der Betreiber legt sie an, der Reviewer gleicht sie am Original ab. Abnahmetests, die solche Daten brauchen, schlagen fehl, wenn die Datei fehlt (kein `skip`). Öffentliche Tests laufen auf freien Daten (NIST, `Penicillin`, VCA-, SixSigma-, ordinal-, rptR-, irr-Datensätze).
- Orakel für Gegenrechnungen: VCA (`anovaVCA`, `remlVCA`), SixSigma (`ss.rr`), lme4 (`lmer`, `bootMer`), ordinal (`clmm`, `clmm2`), rptR (`rptBinary`), performance (`icc`), irr (`kappa2`, `kappam.fleiss`, `kripp.alpha`), psych (`cohen.kappa`), DescTools (`CohenKappa`), FrF2 (`pb`), unrepx (`PSE`, `ME`), qcc (`qcc`), daewr (`vci`), `stats` (`aov`, `t.test`, `lm`). Ein Orakel ersetzt einen Literaturwert nur dort, wo das Kriterium es sagt.

## 7. Daten im Repository

- Eingefrorene Teilmengen liegen unter `inst/extdata/<quelle>_<stand>/` mit `SHA256SUMS` (eine Zeile je Datei) und `QUELLE.txt` (Quelle, URL, Stand, Lizenz, Auswahlregel, Skript). Erzeugende Skripte liegen unter `data-raw/` und lesen die Rohdaten aus `../quellen/daten/<ordner>/` relativ zur Repo-Wurzel (Ordnerlayout `Llmsa\llmsa\` und `Llmsa\quellen\` ist fest). Fehlt der Rohdatenordner, bricht das Skript benannt ab.
- Größe: je Datei, je Ordner und für `inst/extdata/` insgesamt höchstens `ankerRef: ANK-TOL.data_size` (drei Werte, bezogen auf die gespeicherte Datei; die Gesamtgrenze folgt der CRAN-Regel, dass Daten eines Pakets zusammen 5 MB nicht überschreiten sollen). Dateien über 100 KB werden gzip-komprimiert gespeichert (`.csv.gz`, gelesen über `gzfile()`), `SHA256SUMS` nennt die gespeicherte Datei. Rohtexte, Modellantworten im Wortlaut und Rohdaten bleiben außerhalb des Repos.
- Lizenzen: ins Repo nur CC0, gemeinfreie, Apache-2.0- oder MIT-Daten (ClinGen ERepo, ClinVar, llm-stability, CIViC, NIST). Die INSAID-Liste (alle Rechte bei den Autoren, keine kommerzielle Nutzung) bleibt außerhalb; ins Repo kommen nur Gen, cDNA-Bezeichnung und die SHA-256 der Datei (`ANK-52`); in Prompts nur die Variantenbezeichnung; keine Referenzklasse je Variante im Repo oder in Veröffentlichungen, bis Infevers antwortet.
- `GOLDEN_PATH_REGEX='^inst/extdata/'`: jede Änderung an eingefrorenen Daten verlangt ein ADR (Gate golden-adr).
- Rohdaten für AP1 und die Vignetten: ClinGen ERepo (`clingen-erepo_2026-10-22`), ClinVar (`clinvar_2026-10-22`, Stand 19.10.2026), llm-stability (`llm-stability_2026-10-22`), INSAID (`insaid-vangijn2018_2026-10-23`); Herkunft in der jeweiligen `QUELLE.txt`.

## 8. Simulationsstudien

ADEMP: Ziel (Aims), Datenerzeugung (Data-generating mechanisms = Szenarien), Schätzziel (Estimands), Verfahren (Methods), Kennzahlen (Performance measures: Bias, EmpSE, Coverage, MSE, je mit MCSE nach Formelsammlung §9). Szenarien stehen in den Fachspezifikationen als Tabellen; sie sind Vorgaben der Spec, keine Anker.

Zwei Klassen:

- **Klasse A (schnell):** Tests unter `tests/simulation/` (Reviewer-Territorium über `REVIEWER_EXTRA_PATHS_REGEX`), vom Test-Gate mitgelaufen (`TEST_CMD` mit Zusatzordner), nicht in `MUT_TEST_DIRS`. Gesamtlaufzeit des Ordners je Gate-Lauf höchstens `ankerRef: ANK-TOL.sim_runtime` auf 14 Kernen (`parallel::mclapply`); jede Datei protokolliert ihre Laufzeit im Testnamen oder einer Meldung.
- **Klasse B (lang):** Skript des Builders unter `inst/validation/sim/<studie>.R` mit Parametern `--n-sim`, `--out` und `--scenarios` (Teilmenge der Szenarien), das drei Dateien schreibt: `<studie>_results.csv` (eine Zeile je Szenario und Kennzahl: `scenario`, `estimand`, `measure`, `value`, `mcse`, `n_sim`, `seed`), `<studie>_replicates.csv` (Einzelschätzer je Wiederholung) und `<studie>_session.txt` (`sessionInfo()`, Seed, RNG, Laufzeit). Zwei Stufen:
  - *Im einführenden Meilenstein (M1b, M1c):* Der Builder liefert das Skript und committet einen Kurzlauf mit `n_sim = ANK-TOL.n_check` als `<studie>_check_results.csv`, `<studie>_check_replicates.csv`, `<studie>_check_session.txt` (für `boot_coverage` nur die Szenarien S-boot-1 und S-boot-7). Der Abnahmetest führt den Kurzlauf erneut aus, verlangt byte-identische Einzelschätzer (nach `format(x, digits = 15)`), prüft das Schema (alle Szenarien des Kurzlaufs, alle Schätzziele und Kennzahlen, `mcse` vorhanden) und misst die Laufzeit gegen `ANK-TOL.sim_runtime`.
  - *Nach der Abnahme des einführenden Meilensteins:* Der Betreiber rechnet den vollen Lauf (`n_sim` ≥ `ANK-06`, alle Szenarien) und committet `<studie>_results.csv`, `<studie>_replicates.csv`, `<studie>_session.txt` vor dem Start von M1d. M1d prüft Vollständigkeit (alle Szenarien, alle Kennzahlen, `n_sim` ≥ `ANK-06`, `mcse` vorhanden), reproduziert die ersten `ANK-TOL.n_check` Wiederholungen mit demselben Seed byte-identisch (für `boot_coverage` die Szenarien S-boot-1 und S-boot-7) und nimmt die Befunde in Dokumentation und Vignette ab (K-M1d-6, K-M1d-7).
  - Grund für die Trennung (Revision 24.10.2026): Ergebnisse, die mitten in M1b oder M1c entstünden, würde jede REWORK-Runde am Fit- oder Bootstrap-Code ungültig machen (der Reproduktionstest schlüge an), also bis zu fünf Vollläufe von jeweils Stunden bis Tagen (BL-12). Der volle Lauf gehört hinter die Abnahme des Codes; ein Eingriff zwischen BUILD und GATES entfällt.
- Welche Studie in welche Klasse fällt, legt das Kriterium fest. Klasse-B-Ergebnisse werden in `vignettes/validation.Rmd` eingelesen, nie abgetippt; solange nur Kurzlauf-Dateien vorliegen, liest die Vignette diese und nennt `n_sim` aus der Datei.

## 9. Tests, Gates, Rollen

- Gates (Begründung in `gates-auswahl.md`): deps, lint, tests, trace, territory, mutgate, golden-adr aus dem Preset; dazu das projektspezifische Betreiber-Gate `88-mutfull` (nur M1c).
- Abnahmetests (`tests/acceptance/`, Reviewer) referenzieren Kriterien-IDs wörtlich. Gate-Kriterien erhalten im Abnahmetest einen Verweis (`# K-M0-3: decided by the lint gate` oder `skip("K-M0-3: gate")`), damit trace die beidseitige Zuordnung sieht.
- `tests/testthat.R` gehört keiner Rolle; der Betreiber legt es an oder behält es. `tests/fixtures/` (httptest2-Aufzeichnungen) ist Betreiber-Territorium.
- `.Rbuildignore` ergänzt der Betreiber um `^tests/simulation$` und `^tests/fixtures$`; die Preset-Einträge bleiben.
- Jedes Kriterium nennt seinen Prüfweg; bei Vignetten-Kriterien trägt der Abnahmetest Struktur und Einlesen, das lint-Gate den Bau. Jeder Abnahmetest nennt mindestens eine Kriteriums-ID; jedes Gate trägt mindestens ein Kriterium (Zuordnung in `gates-auswahl.md`).
- Rework-Runden: `MAX_ROUNDS_PLAN=2`, `MAX_ROUNDS_REWORK=5`, `REBUILD_ROUND=4`, `ARBITER_EXTRA_ROUNDS=2`; QA ab M1a Pflicht (`QA_REQUIRED_FROM=M1a`, `QA_ENABLED=1` ab M1a).

## 10. Kriterien M0 — Gerüst und Gates auf v0.1.0

M0 ändert `R/` nicht. Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation. Die pkgdown-Umstellung (`docs/` nicht mehr ignoriert, Ziel `pkgdown-site/`) nimmt der Betreiber beim Einsetzen des Harness vor (Startanleitung Schritt 5); M0 prüft sie nur.

- **K-M0-1:** Das deps-Gate meldet `pass`: alle in `DESCRIPTION` unter Depends, Imports und Suggests genannten Pakete sind in der Gate-Umgebung installiert, Versionen im Gate-Log. (Prüfweg: Gate deps)
- **K-M0-2:** Das tests-Gate meldet `pass`: ein testthat-Lauf über `tests/testthat`, `tests/acceptance`, `tests/e2e`, `tests/fuzz` mit aus den Quellen geladenem Paket endet ohne Fehlschlag und Fehler, und die Zahl der ausgeführten Tests unter `tests/testthat/` ist mindestens `ankerRef: ANK-03`. (Prüfweg: Gate tests)
- **K-M0-3:** Das lint-Gate meldet `pass`: `R CMD build` und `R CMD check --as-cran --no-manual` außerhalb des Repos enden ohne ERROR und ohne WARNING. (Prüfweg: Gate lint)
- **K-M0-4:** Die 13 Dateien unter `R/` sind byte-identisch mit Commit `332a2d5`: die SHA-256-Summen gleichen `ankerRef: ANK-01`. (Prüfweg: Test)
- **K-M0-5:** Repository-Layout nach Preset: `git check-ignore docs/00-vision.md` ist leer; `git check-ignore reference/quellen/probe.txt` ist nicht leer; `_pkgdown.yml` enthält `destination: pkgdown-site`; `.Rbuildignore` enthält `^pkgdown-site$`, `^docs$`, `^reference$`, `^orchestrator$`, `^tests/acceptance$`, `^tests/simulation$`, `^tests/fixtures$`; `git check-ignore reference/privat/probe.txt` ist nicht leer. (Prüfweg: Test)
- **K-M0-6:** `orchestrator/state/M0/gates.json` meldet `pass` für deps, lint, tests, trace, territory, mutgate und golden-adr; mutgate meldet „kein geänderter Mutations-Scope“. (Prüfweg: Gate, Aggregat)
- **K-M0-7:** Der API-Snapshot liegt als Anker `reference/anchors/ANK-02.json` vor (Exportliste und `formals()` der 22 Funktionen, erhoben aus Commit `332a2d5`, `ankerRef: ANK-02`), und ein Abnahmetest prüft das geladene Paket als Obermenge des Snapshots: jede Snapshot-Funktion ist exportiert, jedes Snapshot-Argument steht an derselben Position mit demselben Vorgabewert; zusätzliche Exporte und zusätzliche Argumente hinter den Snapshot-Argumenten bestehen den Test (negativ geprüft mit einer konstruierten Funktionsliste, in der ein Argument fehlt, einen anderen Vorgabewert trägt oder umsortiert ist). Eine Änderung des Snapshots ohne ADR im selben Meilenstein lässt das Gate golden-adr fehlschlagen. (Prüfweg: Test)
