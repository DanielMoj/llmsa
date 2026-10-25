<!-- projektierung_llmsa/ANKER-TODO.md -->
# ANKER-TODO — zu erhebende Referenzwerte

Der Reviewer erhebt jeden Anker in der ACCEPTANCE-Phase des genannten Meilensteins unter `reference/anchors/ANK-nn.json` (Schema `reference/anchors/README.md`: `value`, `unit`, `tolerance`, `source_url` oder Katalogschlüssel mit Seite, wörtliches Kurzzitat, `retrieved`). Diese Liste nennt die vermutete Quelle und Fundstelle. Literatur-, Orakel- und zertifizierte Werte stehen hier absichtlich nicht, auch wenn der Quellenkatalog Kandidatenwerte nennt — sie sind am Original zu erheben. Katalogschlüssel beziehen sich auf `reference/privat/QUELLENKATALOG.md`; Textspiegel unter `reference/quellen/text/`. „Betreiberfestlegung“ heißt: der Wert kommt aus Intake, Projektdokument, Formelsammlung oder einer Entscheidung des Betreibers und wird mit Zitat dieser Datei belegt; wo die Projektierung einen Wert vorschlägt, steht er als „Vorschlag“ und gilt erst nach Bestätigung (Status „Betreiber bestätigt“). Mehrere Werte eines Beispiels dürfen in einer Ankerdatei als Objekt stehen (`values` mit benannten Einträgen), wenn sie dieselbe Fundstelle haben. Toleranzen und Betreiberfestlegungen ohne Messwertcharakter stehen gebündelt in `ANK-TOL.json` (Abschnitt unten); Kriterien verweisen auf `ANK-TOL.<name>`. Gegenrechnungen mit Paketen (VCA, SixSigma, qcc, irr, psych, DescTools, rptR, FrF2, unrepx, stats) sind Orakel, die der Test zur Laufzeit aufruft; ihre Ausgaben werden nicht als Anker eingefroren.

## ANK-TOL — Toleranzen und Betreiberfestlegungen (eine Datei, benannte Einträge)

Vorschläge der Projektierung, am 24.10.2026, 22:20 vom Betreiber mit den Änderungen der Toleranzrevision bestätigt (OFFENE-PUNKTE §5c). Jede spätere Änderung braucht ein ADR (Gate golden-adr). Bezugsgröße: Toleranzen für Varianzkomponenten gelten als Anteil der Gesamtvarianz σ²_TV der Vergleichsrechnung je Komponente, nie relativ zur einzelnen Komponente, weil Komponenten nahe null relative Toleranzen unbrauchbar machen; abgeleitete Kennzahlen (%GRR, %Contribution, ICC) werden relativ verglichen, ndc und Verdikt müssen gleich sein.

| Eintrag | Was | Kriterien | Vorschlag | Begründung, Quelle |
| --- | --- | --- | --- | --- |
| reml_anova | Toleranz REML = ANOVA bei balancierten Plänen, je Komponente als Anteil der Gesamtvarianz σ²_TV des ANOVA-Schätzers, und die dafür verwendeten Optimierer-Einstellungen | K-M1a-1 | 1e-4 · σ²_TV je Komponente mit Standard-`lmerControl`; abgeleitete Kennzahlen 1e-4 relativ; ndc gleich, Testfälle nicht näher als 0,01 an einer ganzen Zahl | Intake Feld 5 nennt 1e-6 relativ; lme4 liefert numerische Optima (Bates et al. 2015, `?lmerControl`), Komponenten nahe null vertragen keine relative Toleranz (Revision 22:20); Exaktheit nach Searle 1992 §3.8; BL-49 |
| oracle | Toleranz für Gegenrechnungen mit Paketen zur Testlaufzeit (zwei Werte) | K-M1a-3, K-M3c-4 | Varianzkomponenten (`remlVCA`, `anovaVCA`, `ss.rr`, `lmer`): 1e-4 · σ²_TV je Komponente, abgeleitete Kennzahlen 1e-4 relativ; geschlossene Formeln (qcc-Grenzen, Mittelquadrate): 1e-8 relativ | Verschiedene Optimierer mit eigenen Abbruchkriterien (VCA Fisher-Scoring, lme4 BOBYQA) treffen dasselbe Optimum nur auf etwa 1e-5; geschlossene Formeln stimmen auf Maschinengenauigkeit (Revision 22:20) |
| package_compare | absolute Toleranz für Kappa, Alpha, Bias-Statistiken gegen irr, psych, DescTools, stats | K-M3a-1, -2, -3, -5 | 1e-8 | geschlossene Formeln; abweichende Gewichte oder Definitionen zeigen sich bei 1e-2 und größer, Rundungsunterschiede unter 1e-12 (Revision 22:20) |
| engine_ordinal | relative Toleranz `msa_fit` gegen direktes `clmm` | K-M1b-1 | 1e-8 | gleicher Aufruf, gleiche Daten, gleicher Optimierer; eine abweichende `control`-Einstellung läge zwischen 1e-8 und 1e-6 und soll auffallen (Revision 22:20) |
| engine_boot | Toleranz `msa_boot` gegen `bootMer` bei gleichem Seed | K-M1c-1 | 1e-10 | identische Zufallsfolge |
| rptr | Toleranz gegen rptR und performance | K-M1b-5 | 1e-6 gegen den Live-Aufruf, 5e-4 gegen den gerundeten Vignettenwert 0,188 (ANK-25) | halbe Einheit der letzten publizierten Stelle (Prüfstandard Nr. 6; Revision 22:20) |
| nist_digits | Genauigkeit gegen zertifizierte NIST-Werte (zwei Regeln) | K-M1a-4 | niedrige Schwierigkeit (`SiRstv`, `SmLs01`–`SmLs03`, `AtmWtAg`): 1e-8 relativ; mittlere Schwierigkeit (`SmLs04`–`SmLs06`): LRE von `msa_fit` mindestens LRE von `stats::aov` auf denselben Daten minus 1, beide LRE in der Vignette | NIST StRD „Background Information“ (LRE = −log₁₀ |x − c| / |c|); Werte um 10¹² mit Abweichungen 0,1 liegen an der Grenze der Double-Darstellung (Auflösung etwa 1e-4 je Wert), die erreichbare Genauigkeit ist vor der Messung unbekannt, deshalb Kopplung an `aov` statt geratener Zahl (Revision 22:20); BL-23 |
| invariance | Toleranz für Permutation, Umbenennung, Verschiebung, Skalierung | K-M1a-6, 01 §2 | 1e-6 · σ²_TV je Komponente, abgeleitete Kennzahlen 1e-6 relativ; ndc und Verdikt gleich; Testfälle mit ndc nicht näher als 0,01 an einer ganzen Zahl und %GRR nicht näher als 0,1 Punkte an 10 oder 30 | Permutation ändert die Summationsreihenfolge, Skalierung die absoluten Abbruchschwellen des Optimierers; 1e-8 prüfte den Optimierer, nicht die Invarianz (Revision 22:20) |
| arithmetic | absolute Toleranz für Nachrechnungen von Kennzahlen aus Einzelwerten (Formelsammlung §3, §9) | K-M3c-6 | 1e-10 | reine Arithmetik |
| mc_factor | Faktor der Monte-Carlo-Standardfehler, innerhalb dessen ein Simulationsergebnis als übereinstimmend mit Nominal- oder Literaturwert gilt (zwei Werte) | 01 §2, K-M1d-7, K-M3a-7, K-M3b-5, K-M3c-3, K-M3c-5 | Bestehenskriterium 4; Berichtsschwelle (K-M1d-7) 3 | Morris, White & Crowther 2019 (MCSE-Formeln, Tab. 6); die Kriterien prüfen Dutzende Kombinationen Szenario × Kennzahl: bei 3 MCSE fiele unter der Nullhypothese etwa jede zehnte Suite zufällig durch (50 Vergleiche × 0,27 %), bei 4 MCSE etwa eine von 300 (Revision 22:20) |
| bias_report | Schranke der relativen Verzerrung, ab der ein Simulationsbefund in Dokumentation und Vignette benannt wird | K-M1d-7 | 10 % oder 3 MCSE, was größer ist | Betreiberfestlegung |
| sim_runtime | Laufzeitgrenze `tests/simulation/` je Gate-Lauf auf 14 Kernen; gilt auch für die Kurzläufe der Klasse-B-Studien im Abnahmetest | 01 §8, K-M1b-2, K-M1c-4, QA-Regel | 20 Minuten; nach M1a an der Messung prüfen | Betreiberfestlegung; BL-13 |
| n_check | Wiederholungen für Kurzlauf und byte-identische Reproduktion der Klasse-B-Studien | 01 §8, K-M1b-2, K-M1b-3, K-M1c-3, K-M1c-4, K-M1d-6 | 20 | Betreiberfestlegung |
| data_size | Größengrenze eingefrorener Daten (drei Werte), bezogen auf die gespeicherte Datei | 01 §7, K-M1d-5 | 1 MB je Datei (Dateien über 100 KB gzip-komprimiert als `.csv.gz`, SHA-256 über die gespeicherte Datei), 3 MB je Ordner, 5 MB `inst/extdata/` gesamt | CRAN Repository Policy: Daten eines Pakets sollen zusammen 5 MB nicht überschreiten; Ordnergrenze allein ließe bei drei Ordnern 9 MB zu; llm-stability auf Item-Ebene wird unkomprimiert mehrere MB groß (Revision 22:20) |
| frf2_unrepx | Toleranz gegen FrF2 und unrepx | K-M3b-2, K-M3b-3 | Matrizen exakt bis auf Permutation und Vorzeichen; PSE, ME 1e-8 | Betreiberfestlegung |
| resume_cutpoints | Zahl zufälliger Abbruchpunkte und Seeds im Fortsetzen-Test | K-M3d-1 | 50, Seeds 1 bis 50 | Betreiberfestlegung |
| parser_cases | Zahl zufälliger Parser-Eingaben je Parser und Generator-Seed | K-M3d-2 | 10.000, Seed 20261024 | Parser laufen in Millisekunden; zehnfache Abdeckung ohne Mehrkosten (Revision 22:20) |

## Querschnitt und M0

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-01 | SHA-256 der 13 Dateien unter `R/` | K-M0-4 | Repo `DanielMoj/llmsa`, Commit `332a2d5` (`git show 332a2d5:R/<datei>` → `sha256sum`) | Datenstand | Reviewer berechnet |
| ANK-02 | API-Snapshot: Exportliste (NAMESPACE) und `formals()` der 22 Funktionen; die Ankerdatei `ANK-02.json` ist zugleich der Snapshot, den der Abnahmetest als Obermenge prüft (Snapshot-Funktionen und -Argumente unverändert vorhanden; neue Exporte und nachgestellte Argumente zulässig; keine zweite Kopie unter `tests/`); Änderung nur bei Änderung einer bestehenden Schnittstelle, mit ADR | K-M0-7, Schnittstellenregel | Commit `332a2d5`, `NAMESPACE` und `R/*.R` (`deparse(formals(f))` je Export) | Datenstand | Reviewer erzeugt in ACCEPTANCE M0 |
| ANK-03 | Zahl der testthat-Tests in v0.1.0 | K-M0-2 | Projektdokument „Das R-Paket llmsa 0.1.0“ (27 Tests); testthat-Lauf auf `332a2d5` | Betreiberfestlegung / Datenstand | Reviewer zählt |
| ANK-06 | Mindestzahl Wiederholungen je Simulationsszenario und MCSE-Grundlage | 01 §2, K-M1d-6, alle Simulationskriterien | Prüfstandard (Projektdokument, Intake Feld 5: mindestens 1.000); Morris, White & Crowther 2019, S. 2089 (Morris2019) | Betreiberfestlegung | vorhanden |

## M1a — numerisch

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-10 | AIAG-ANOVA-Beispiel: Datenblatt (10 Teile × 3 Prüfer × 3 Wiederholungen), EV, AV, GRR, PV, TV, % Studienvariation, % Contribution je Quelle, ndc | K-M1a-2, K-M1a-5 | AIAG2010, Tab. III-B 6a (Datenblatt) und Tab. III-B 7–10, Druck S. 103 und 127–129 (PDF 112, 136–138); Datenblatt als CSV `reference/quellen/data/aiag/anova_example.csv` | Literatur (geschützt, lokal) | Datei anlegen (Betreiber), Reviewer prüft |
| ANK-13 | `Penicillin`: publizierte REML-Schätzer (Standardabweichungen plate, sample, residual) | K-M1a-1, K-M1a-3 | Bates2015 (JSS 67(1)), Abschnitt zum Penicillin-Beispiel; `lme4::Penicillin` | Literatur (frei) | vorhanden |
| ANK-14 | NIST-StRD-ANOVA zertifizierte Werte (Between/Within SS, df, MS, F, R², Residual-SD) für SiRstv, SmLs01–06, AtmWtAg | K-M1a-4 | `quellen/daten/nist-strd-anova_2026-10-22/*.dat` (Kopfzeilen „Certified Values“), itl.nist.gov/div898/strd/anova | zertifiziert (frei) | vorhanden |
| ANK-16 | AIAG-Verdiktschwellen 10 %/30 % mit Wortlaut, ndc-Konstante 1,41, Mindest-ndc; %Contribution-Schwellen 1/9 als Konvention | K-M1a-5, 01 §5 | AIAG2010, Tab. II-D 1 Druck S. 78 (PDF 87), S. 128; Formelsammlung §3 für 1/9 | Literatur (geschützt, lokal) | vorhanden |

## M1b — ordinal und binär

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-21 | `wine`: σ²_judge aus `clmm2(rating ~ temp + contact, random = judge)` (Laplace und nAGQ = 10) | K-M1b-1 | Christensen-clmm2 (Vignette, Fassung 26.07.2026), PDF 2–3 | Literatur (frei) | vorhanden |
| ANK-25 | `rptR::BeetlesMale`: Wiederholbarkeit Population auf Link- und Beobachtungsskala (Punktschätzer) | K-M1b-5 | rptR (Vignette, Fassung 29.04.2025), Abschnitt rptBinary; Stoffel2017 | Literatur (frei) | vorhanden |
| ANK-28 | Verteilungsvarianz der latenten Skala: 1 (Probit), π²/3 (Logit), π²/6 (cloglog) | 01 §5 | Nakagawa2010 Tab. 1 S. 942; Nakagawa2017 §7 S. 6–7 | Literatur | vorhanden |

## M1c — Bootstrap und Mutation

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-32 | Mutationsscore Statistikkern: Schwelle, Floor, Ratchet-Toleranz | K-M1c-6, Prüfstandard Nr. 7 | Intake Abschnitt 5 und Projektdokument „Offene Punkte“ (24.10.2026: 80/80/2) | Betreiberfestlegung | vorhanden |

## M1d — echte Daten

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-40 | llm-stability: Commit, Lizenz, Struktur (Modelle, Aufgaben, Läufe, Itemzahl je Aufgabe) | K-M1d-1 | `quellen/daten/llm-stability_2026-10-22/QUELLE.txt`; Repo breckbaldwin/llm-stability, Ordner `experiments/`; Atil2024 | Datenstand (frei) | Reviewer zählt |
| ANK-41 | ClinVar-Stand (Last-Modified 19.10.2026) und md5 der Rohdateien | K-M1d-3, K-M2-2 | `quellen/daten/clinvar_2026-10-22/QUELLE.txt`, `*.md5` | Datenstand (frei) | vorhanden |
| ANK-42 | Yang et al. 2017: vollständige Übereinstimmung und Mehrheitskonsens (Pathogenität, Fünf-Klassen), Teilmenge klinische Labore ab 2014; Datenbasis | K-M1d-4 | Yang2017 (Katalog E): Genet Med 19:1118–1126, doi 10.1038/gim.2017.60, Open Access CC BY-NC-ND; Results „Dataset“, „Concordance“, PDF 2–4 | Literatur (frei) | vorhanden (seit 24.10.) |
| ANK-43 | Amendola et al. 2016: Krippendorffs Alpha zwischen Laboren (ACMG-AMP und Laborkriterien), vollständige Übereinstimmung vor/nach Konsens, 99 Varianten | K-M1d-4 | Amendola2016 (Katalog E): AJHG 98:1067–1076, doi 10.1016/j.ajhg.2016.03.024, PMC4908185; Abschnitt „Inter-laboratory Concordance in Classification“, PDF 4–5, Tab. 2 | Literatur (Verlags-PDF, geschützt, lokal) | vorhanden (seit 24.10.) |
| ANK-44 | Harrison et al. 2017: Anteil konkordanter gemeinsamer Varianten, medizinisch bedeutsame Unterschiede, Konkordanz nach Neubewertung; Zahl der gemeinsamen Varianten mit P/LP gegen LB/B (Vergleichswert für gefährliche Fehler) | K-M1d-4, A.1 | Harrison2017 (Katalog E): Genet Med 19:1096–1104, doi 10.1038/gim.2017.14; Autorenmanuskript Harvard DASH (17 Seiten, Seitenzahlen des Manuskripts); Abstract und Results; P/LP gegen LB/B: Manuskriptfassung S. 5 (PDF 6); „medizinisch bedeutsam“ umfasst P/LP gegen VUS/LB/B (Belegprüfung 25.10.2026) | Literatur (frei lesbar) | vorhanden (seit 24.10.) |
| ANK-45 | Van Gijn et al. 2018: Anteil ohne Konsens in Runde 1 (vier Experten), Konsens am Ende (804/858), Validierungsregel ≥ 75 % | K-M1d-4 | VanGijn2018, PDF-Seite 1 (Abstract) und 3 („Interpretation workflow“, „Consensus validation“), Tab. 2 | Literatur (geschützt, lokal) | vorhanden |
| ANK-46 | Lazareva et al. 2024: Anteil Varianten mit Konflikt in Krankheitsgenen 2018–2024 | K-M1d-4 | Lazareva2024 (Katalog E): J Pers Med 14(8):864, doi 10.3390/jpm14080864, PMC11355203, CC BY; Volltext als JATS-XML/HTML (Europe PMC REST), Fundstellen nach Abschnitt (Abstract, Results 3.1), keine Seitenmarken | Literatur (frei) | vorhanden (seit 24.10.) |
| ANK-47 | Umfang, Seed und Auswahlreihenfolge der genomweiten ClinVar-Stichprobe: zuerst Filter auf Einreichungen mit einer der fünf Klassen, dann Varianten mit mindestens drei verbliebenen verschiedenen Einreichern, dann Ziehung von 1.000 Varianten mit `set.seed(20261024)` und `sample()` über die nach `variation_id` sortierte Liste | K-M1d-3 | Betreiberfestlegung 24.10.2026 (Projektierung Frage 7: 1.000 Varianten, Seed 20261024; Reihenfolge Revision 22:20) | Betreiberfestlegung | Betreiber bestätigt 24.10., 22:20 |

## M2 — Anwendungspipeline

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-50 | Stichtag Wissensstand GPT-6.1 Sol | K-M2-1, K-M2-2, A.1, A.2, A.4 | `quellen/anbieter_2026-10-22/openai/Models.html` (OpenAI-Modellseite, Schnappschuss 22.10.2026); Intake Abschnitt 6 (30.04.2026); bestätigt in der Belegprüfung 25.10.2026 | Anbieterdokumentation | vorhanden |
| ANK-51 | ClinGen ERepo Stand 22.10.2026: Gesamtzahl Einstufungen, Pool nach Stichtag (Einstufungen, Varianten, Gene, Minimum je Klasse) | K-M2-1 | `quellen/daten/clingen-erepo_2026-10-22/QUELLE.txt` und `erepo_classifications_all.tsv`; Projektdokument „Offene Punkte“ (Itemsatz) | Datenstand (CC0) | Reviewer berechnet aus Datei |
| ANK-52 | INSAID-TSV: SHA-256, Gesamtzahl Varianten, Zahl „Validated“, Minimum je Klasse, Lizenz | K-M2-1, 01 §7 | `quellen/daten/insaid-vangijn2018_2026-10-23/QUELLE.txt` und TSV; VanGijn2018 | Datenstand (geschützt, lokal) | Reviewer berechnet |
| ANK-53 | GPT-6.1 Sol: API-Modellkennung, Reasoning-Stufe, Preise Eingabe/Ausgabe | K-M2-4, K-M2-5, A.4 | `quellen/anbieter_2026-10-22/openai/Models.html`, `Pricing.html` | Anbieterdokumentation (Stand 22.10.2026) | vorhanden; vor AP1 live prüfen |
| ANK-54 | Llama 3.3 70B Instruct auf OpenRouter: Modell-Slug, Endpunkt-Tag `coreweave/fp16` für `provider.order`, Quantisierung fp16, Kontext, Preise | K-M2-4, K-M2-5, A.4 | `quellen/anbieter_2026-10-22/openrouter/` (models.json, Endpunktdatei des Modells) | Anbieterdokumentation | vorhanden; vor AP1 live prüfen |
| ANK-55 | Qwen3-32B auf OpenRouter: Modell-Slug, Endpunkt-Tag `deepinfra/fp8` für `provider.order`, Quantisierung fp8, Seed-Unterstützung, Preise | K-M2-4, K-M2-5, A.4 | ebenda | Anbieterdokumentation | vorhanden; vor AP1 live prüfen |
| ANK-56 | Aufrufe je Modell (Hauptplan, Plackett-Burman) und Token-Annahmen | K-M2-5, A.6 | Intake Abschnitt 8 („Rechnung AP1“) | Betreiberfestlegung | vorhanden |
| ANK-57 | Budget AP1 in Euro | K-M2-5, A.6 | Intake Abschnitt 8 | Betreiberfestlegung | vorhanden |
| ANK-58 | Akzeptanzkriterien AP1: %GRR-Schwelle auf der latenten Skala, Kappa-Grenzen 0,8/0,6, gefährliche Fehlklassifikation (P/LP ↔ B/LB; unter den 75 ERepo-Items 0 akzeptabel, 1 bedingt, ab 2 nicht akzeptabel), Robustheit (drei disjunkte Bänder: akzeptabel, wenn kein Faktor \|Δp\| über 5 Prozentpunkten hat; nicht akzeptabel, wenn mindestens ein Faktor \|Δp\| über 5 Prozentpunkten hat und zugleich die SME überschreitet; bedingt, wenn Faktoren über 5 Prozentpunkten liegen, aber keiner davon die SME überschreitet; SME- oder ME-Überschreitungen bei \|Δp\| bis 5 Prozentpunkte werden berichtet und ändern das Verdikt nicht) | K-M2-5, K-M2-6, A.1 | Betreiberentscheidung aus Context of Use und Risikostufe (Validierungsplan nach Freigabe, BL-27); keine Literaturevidenz für die Grenzen: AIAG-Schwellen sind auf der latenten Skala nur Konvention (Formelsammlung §4), Landis & Koch 1977 (Biometrics 33:159–174, Tab. 3; BL-41) liefert nur die Bezeichnungen der Bänder; das gefährliche Fehlurteil ist das einzige inhaltlich zwingende Element; seine Bänder begründet die Dreierregel (Hanley & Lippman-Hand 1983, JAMA 249:1743–1745; BL-58), Vergleichswert `ANK-44` (Belegprüfung 25.10.2026) | Betreiberfestlegung | Betreiber gibt frei |
| ANK-59 | Itemsatz-Festlegung: 100 Items = 75 ERepo + 25 INSAID, 15 bzw. 5 je Klasse, Panels/Gene im Umlauf, Seed 20261024 | K-M2-1, A.2 | Intake Abschnitt 6 und Projektdokument „Offene Punkte“ (24.10.2026); Seed: Projektierung Frage 8d | Betreiberfestlegung | vorhanden |
| ANK-60 | OpenRouter: Namen der Routing-Felder im Request; Antwort ohne Anbieter- und Quantisierungsfeld; Feld `provider_name` von `GET /api/v1/generation` | K-M2-4 | Routing-Felder: OpenRouter Provider Routing Doku (Katalog D, HTML-Schnappschuss); Antwort und Generation-Endpunkt: OpenRouter-API-Referenz (Belegprüfung 25.10.2026; kein Schnappschuss, BL-58); ob die Antwort trotzdem ein Feld `provider` trägt, zeigt die Aufzeichnung (`ANK-94`) | Anbieterdokumentation | Routing-Felder vorhanden; API-Referenz als Schnappschuss sichern (Betreiber, vor M2) |
| ANK-61 | Temperatur-Policy je Modell: Llama und Qwen 0; GPT-6.1 Sol ohne Feld (`temperature = NULL`), weil Sol `temperature` nicht unterstützt (keine Reasoning-Stufe `none`) | K-M2-4, K-M2-5, A.4 | Betreiberfestlegung (Projektierung Anhang A.4); OpenAI Models-Dokumentation zu Reasoning-Modellen; Belegprüfung 25.10.2026 | Betreiberfestlegung | Betreiber gibt frei |
| ANK-62 | Acht Störfaktoren mit Stufen | K-M2-5, A.5 | Validierungsplan Anhang A.5 nach Freigabe | Betreiberfestlegung | Betreiber gibt frei |
| ANK-63 | ClinVar `submission_summary`: Spaltenbelegung für Einreicher, Einstufung, Datum, Bewertungsstatus (Stand 19.10.2026) | K-M2-2, K-M1d-3 | `quellen/daten/clinvar_2026-10-22/README` | Datenstand | vorhanden |
| ANK-64 | INSAID-Transkripte je Gen (MEFV, MVK, NLRP3, TNFRSF1A) für `hgvs` der INSAID-Items; Widerspruch zwischen Methoden und Tab. 1 für MEFV | K-M2-1, A.2 | VanGijn2018, Methoden (PDF 2) und Tab. 1; die Methoden gelten, der Widerspruch wird im Anker vermerkt (Belegprüfung 25.10.2026) | Literatur (geschützt, lokal) | vorhanden |
| ANK-65 | Wissensstand Llama 3.3 70B Instruct (Berichtswert, kein Bestehenskriterium) | A.1, A.4 | Meta-Modellkarte zu Llama 3.3 (Belegprüfung 25.10.2026); kein Schnappschuss (BL-58) | Anbieterdokumentation | Schnappschuss sichern (Betreiber) |
| ANK-66 | Wissensstand Qwen3-32B: keine Herstellerangabe; Angabe des OpenRouter-Katalogs, Veröffentlichungsdatum als obere Schranke (Berichtswert, kein Bestehenskriterium) | A.1, A.4 | `quellen/anbieter_2026-10-22/openrouter/models.json` (Schnappschuss 22.10.2026, Eintrag Qwen3-32B); Veröffentlichungsdatum: Fundstelle aus der Belegprüfung 25.10.2026 nachtragen (BL-58) | Anbieterdokumentation | Katalogangabe vorhanden; Fundstelle des Veröffentlichungsdatums offen |

## M3a — Übereinstimmung, Bias, Linearität

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-70 | Cohen 1968: Beispieltabelle (3×3, N = 200), Gewichte, κ und κ_w | K-M3a-1 | Cohen1968, Tab. 1 S. 214, Ergebnisse S. 214–216 | Literatur (geschützt, lokal) | vorhanden |
| ANK-72 | Fleiss 1971: Tab. 1 (30 Items, 6 Bewerter, 5 Kategorien), P̄, P_e, κ | K-M3a-2 | Fleiss1971, S. 379; Datensatz `irr::diagnoses` | Literatur (geschützt, lokal) | vorhanden |
| ANK-73 | Krippendorff 2011: Rechenbeispiel 4 Beobachter × 12 Einheiten, α nominal, ordinal, Intervall (und Ratio) | K-M3a-3 | Krippendorff2011, PDF 4–8 | Literatur (frei) | vorhanden |
| ANK-74 | AIAG-Attributstudie: Datenblatt und Kappa-Tabelle | K-M3a-4 | AIAG2010, Kap. III C ab PDF 140, Tab. III-C 3; CSV `reference/quellen/data/aiag/attribute_study.csv` | Literatur (geschützt, lokal) | Datei anlegen (Betreiber) |
| ANK-75 | AIAG-Bias-Beispiel: Daten (n = 15), σ_r, σ_b, t, Intervall | K-M3a-5 | AIAG2010, Tab. III-B 1–2, Druck S. 88–92; CSV `reference/quellen/data/aiag/bias_study.csv` | Literatur (geschützt, lokal) | Datei anlegen (Betreiber) |
| ANK-76 | AIAG-Linearitätsbeispiel: Daten (g = 5, m = 12), Steigung, Achsenabschnitt, R², t-Werte, t-Quantil; zusätzlich Item-Mittelwert-Regression (R², t_a) | K-M3a-6 | AIAG2010, Tab. III-B 4–5, Druck S. 96–101; Item-Mittelwerte: Formelsammlung §6 und Prüfprotokoll 24.10.; CSV `reference/quellen/data/aiag/linearity_study.csv` | Literatur (geschützt, lokal) + Betreiberfestlegung | Datei anlegen (Betreiber) |

## M3b — Robustheit

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-80 | Plackett & Burman 1946: Generatorzeilen N = 8, 12, 16, 20, 24 und Konstruktionsregel | K-M3b-1 | PlackettBurman1946, „Table of Designs, A. Designs for L = 2“, S. 323 (Scan); NIST-5.3.3.5 Tab. 3.18/3.19 als Zweitquelle | Literatur (geschützt, lokal) | vorhanden |
| ANK-81 | Lenth 1989: Beispiele II und IV (Effekte, PSE, ME, SME), Konstanten 1,5 und 2,5, d = m/3, Tab. 1 | K-M3b-3 | Lenth1989, S. 469–473, Tab. 1–3; Daten als CSV `reference/quellen/data/lenth/` | Literatur (geschützt, lokal) | Datei anlegen (Betreiber) |
| ANK-82 | Daniel 1959: Plotting-Position P′ = (i − ½)/n; Beispiel 22. von 31 Kontrasten | K-M3b-4 | Daniel1959, S. 313–315 | Literatur (geschützt, lokal) | vorhanden |

## M3c — Westgard, Simulator, Planung

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-86 | Westgard 1981: Regeldefinitionen; Fehlalarmwahrscheinlichkeit je Regel unter Unabhängigkeit (Herleitung) | K-M3c-1, K-M3c-3 | Westgard1981, S. 494 (Definitionen), S. 498–500 (R_4s-Lesart, N); Formelsammlung §8 (Herleitungen 1_3s, 1_2s, 2_2s, 4_1s, 10_x, R_4s) | Literatur (geschützt, lokal) + Betreiberfestlegung | vorhanden |
| ANK-87 | Parvin 1992: mittlere Ablehnungswahrscheinlichkeit je Lauf (1/ARL) der Kombination ohne R_4s, N = 1, unter Kontrolle und bei 1σ, 2σ; Monte-Carlo-Toleranz | K-M3c-3 | Parvin1992, Tab. 1 S. 361, Toleranzangabe S. 360 | Literatur (geschützt, lokal) | vorhanden |
| ANK-89 | Planungsregel CV(σ̂²) ≈ √(2/ν), ν = a − 1, als berichteter Vergleichswert (kein Bestehenskriterium, K-M3c-6) | K-M3c-6 | BurdickGraybill1992, S. 30 (Var(γ̂) = 2 Σ c_q² θ_q²/n_q); Formelsammlung §2 | Literatur (geschützt, lokal) | vorhanden |

## M3d — Ausführung, Parser, Backends, Bericht

| ANK | Was | Kriterien | Vermutete Quelle und Fundstelle | Art | Status |
| --- | --- | --- | --- | --- | --- |
| ANK-93 | Rundungsstellen der Berichtsvorlage je Kennzahl | K-M3d-4 | `inst/templates/validation_report.Rmd` (Stand `332a2d5`) | Datenstand | Reviewer liest aus Vorlage |
| ANK-94 | httptest2-Aufzeichnungen: Datum, Modellkennungen, Anbieter je Aufzeichnung | K-M2-4, K-M3d-3 | `tests/fixtures/httptest2/` (Betreiber zeichnet vor M2 auf, BL-26) | Datenstand | Betreiber erzeugt |

## Nicht vergeben

ANK-04, 05, 07–09, 11, 12, 15, 17–20, 22–24, 26, 27, 29–31, 33–39, 48, 49, 67–69, 71, 77–79, 83–85, 88, 90–92 sind frei für Nachträge des Reviewers (jeder Nachtrag mit ADR, wenn er ein Kriterium ändert); die am 24.10. gestrichenen Nummern (Toleranzen, jetzt in ANK-TOL; Orakel ohne Anker) werden nicht neu belegt, damit alte Verweise eindeutig bleiben.
