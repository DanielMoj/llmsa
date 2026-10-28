<!-- projektierung_llmsa/docs/00-vision.md -->
# 00 — Vision

Projektierung vom 24.10.2026 nach `projektierung/PROJEKTIERUNG.md` (harness-template v1.1.1), Preset `r-paket`. Eingabe: `02_Intake_Destillat_llmsa.md` (Stand 24.10.2026). Bindend erst nach Freigabe durch den Betreiber.

## Vision in drei Sätzen

1. **Was:** llmsa ist ein R-Paket, das eine Auswertung mit einem Sprachmodell (LLM) wie ein Messsystem im Labor validiert: gekreuzte Präzisionsstudien mit Varianzkomponenten (Gage R&R), Übereinstimmung mit einer Referenz, Robustheits-Screening per Plackett-Burman, Fallzahlplanung, laufende Systemeignung mit Westgard-Regeln und ein prüffähiger Validierungsbericht.
2. **Für wen:** Labore, Forschungsgruppen und regulierte Umgebungen (Pharma, Diagnostik, klinische Genetik), die LLM-Auswertungen einsetzen, sowie die Lehre in den Naturwissenschaften.
3. **Warum:** LLM-Auswertungen werden ohne bekannte Messunsicherheit eingesetzt. Die Antworten schwanken auch bei Temperatur 0, Anbieter tauschen Modelle ohne Ankündigung aus, und der FDA-Guidance-Entwurf von Januar 2025 verlangt eine Bewertung der Glaubwürdigkeit für einen definierten Einsatzzweck. Vorhandene Evaluationswerkzeuge messen Trefferquoten, keine Messunsicherheit.

Das Paket beurteilt nie „das LLM“, sondern die konkrete Pipeline (Modell, Prompt, Einstellungen) für eine konkrete Aufgabe und Risikostufe. Zieltermin für M0, M2 und M1a–M1d ist der 26.11.2026.

## Zielgruppe und Nutzungskontext

- R-Anwender in Laboren und Forschungsgruppen, Biometrie und Qualitätssicherung.
- Studierende in Praktika zur Qualitätssicherung KI-gestützter Auswertungen: Sie validieren eine Pipeline mit API-Modellen und schreiben den Validierungsbericht.
- Humangenetik: Anwendungsbeispiel Variantenklassifikation nach ACMG/AMP (Gene MEFV, MVK, NLRP3, TNFRSF1A).
- Plattform: R ab 4.1 auf Linux, macOS und Windows. Modelle ausschließlich über APIs: proprietäre Anbieter und OpenRouter für offene Modelle; keine lokale Ausführung (Entscheidung 21.10.2026). Ergebnisse anderer Pipelines lassen sich importieren.
- Rechner für Statistik und Harness: Laptop mit 16 Kernen und 64 GB RAM, WSL2; Simulationen und Mutationstests laufen parallel auf 14 Kernen.

Drei Momente, in denen ein Anwender zum Paket greift: vor dem Einsatz (Validierung), nach einer Änderung (Vergleich mit dem validierten Stand) und im laufenden Betrieb (Kontrollsatz und Regelkarte).

## Scope

Entschiedene Bestandteile des Harness-Projekts (Meilensteine M0 bis M3d, `orchestrator/milestones.json`; Reihenfolge M0 → M2 → M1a → M1b → M1c → M1d → M3a–M3d, Revision 24.10.2026, 21:45):

- **M0** Gerüst: Toolchain, Preset `r-paket`, die gewählten Gates grün auf v0.1.0, `R/` unverändert.
- **M2** Pipeline für das Anwendungsbeispiel, als zweiter Meilenstein, damit die AP1-Erhebung parallel zum Statistikkern läuft: eingefrorener Itemsatz (75 ClinGen-ERepo, 25 INSAID) mit SHA-256, drei Prompt-Vorlagen, Backends für GPT-6.1 Sol, Llama 3.3 70B (CoreWeave, fp16) und Qwen3-32B (DeepInfra, fp8) mit festem Anbieter und Quantisierung, Auswertung der ACMG-Klassen (interne `acmg_*`-Funktionen, kein neuer Export), Validierungsplan AP1.
- **M1a–M1c** Abnahme des Statistikkerns nach dem Prüfstandard: Varianzkomponenten numerisch mit %GRR, %Contribution, ndc und Verdikt (M1a); ordinal auf der latenten Skala und binär auf der Logit-Skala samt Ersatzverfahren bei zwei Stufen, Simulationsstudien als Skripte mit reproduziertem Kurzlauf (M1b); parametrischer Bootstrap, Überdeckungsstudie als Skript mit Kurzlauf und Mutationslauf über `R/fit.R` und `R/grr.R` (M1c).
- **M1d** Zwei Läufe auf echten Daten ohne Modellaufruf als Vignetten: llm-stability (Wiederholpräzision bei Temperatur 0, Faktor Modell) und ClinVar-Einreichungen (Prüferstudie mit Alpha, Kappa und ordinalen Varianzkomponenten, Vergleich mit publizierten Konkordanzstudien); dazu die Abnahme der vom Betreiber nach M1b und M1c gerechneten Klasse-B-Vollläufe (Vollständigkeit, Reproduktion, Befunde).
- **M3a–M3d** Abnahme der übrigen Bausteine: Übereinstimmung (Cohen, Fleiss, Krippendorff), Bias und Linearität (M3a); Plackett-Burman und Lenth (M3b); Westgard-Regelkarte, Simulator und Fallzahlplanung (M3c); Ausführung mit Speicher und Fortsetzen, Parser, Backends gegen Aufzeichnungen, Bericht mit SHA-256 und Zahlenabgleich (M3d).

Außerhalb des Harness, aber Teil des Vorhabens (Betreiber): der echte Lauf AP1, Release v0.1.x mit Zenodo-DOI (AP2), Normbezug-Vignette und Praktikumsblatt (AP3), Preprint auf bioRxiv (Go/No-Go 15.11., Einreichung bis 19.11.). Sie sind in `reference/privat/90-katalog-offen.md`, Abschnitt „Außerhalb des Harness“, aufgeführt.

## Out-of-Scope

Ausdrücklich nicht Teil des Projekts oder verworfen:

- Kein weiteres Bioinformatik-Werkzeug für LLMs (MCP-Server, Skill-Bibliothek) und kein Benchmark für Trefferquoten; dieses Feld ist besetzt (MCPmed, gget-mcp, BioMCP, LifeSciBench, StatEval, StatABench).
- Keine Entwicklung und kein Training von Sprachmodellen.
- Keine Bewertung von Freitext durch ein zweites Modell (LLM-als-Richter, geschachtelte MSA) vor Version 0.5 (AP9).
- Keine grafische Oberfläche, keine Python-Version.
- Keine lokalen Modelle (Ollama, vLLM, llama.cpp, LM Studio als Laufzeit; Entscheidung 21.10.2026). Quantisierung ist deshalb kein Faktor des eigenen Laufs; offene Modelle laufen über OpenRouter mit festgelegtem Anbieter und Quantisierung.
- Verworfene Themenkandidaten: Design-Auditor für Labordaten; Pharmakometrie auf In-vitro-Daten.
- Verworfene Architektur der ersten Skizze: sechs Funktionsfamilien (`design_*`, `run_*`, `extract_*`, `grr_*`, `spc_*`, `report_*`) auf Basis von VCA, mcr, qcc, SixSigma; Quarto-Bericht. Umgesetzt ist das Präfix `msa_` mit lme4 und ordinal als einzigen Pflichtabhängigkeiten und einer R-Markdown-Vorlage. VCA, SixSigma, irr und weitere Pakete dienen nur der Gegenrechnung in der Validierungssuite.
- VariantBench als Itemsatz (Entscheidung 24.10.2026: Code nicht veröffentlicht, keine Lizenz). ClinGen-ERepo deckt den Zweck ab.
- Medizinisch feinabgestimmte Modelle im Lauf bis 26.11.2026 (MedGemma nicht auf OpenRouter, GPT-Rosalind nur für zugelassene Organisationen); Claude und Gemini 4 Argon als Messmodelle in AP1 (stille Umleitung bzw. fehlender Wissensstand).
- Daten des Corpas-Preprints (ClawBench): nicht veröffentlicht, keine Anfrage eingeplant.
- MedQA, MedMCQA, PubMedQA als Referenz für Richtigkeit (vermutlich im Training); nur für Präzision und Lehre.
- JOSS-Einreichung vor Ende April 2027 (sechs Monate öffentliche Entwicklung sind Voraussetzung).
- Änderungen an den Schnittstellen der 22 exportierten Funktionen von v0.1.0 ohne ADR und Übergangsfrist (`docs/01-fachspezifikation.md`, Abschnitt 4).
- Urheberrechtlich geschützte Bücher, Normen, PDFs, EPUB, Rohdaten und die INSAID-TSV im öffentlichen Repo; Partnerdaten an API-Anbieter vor einer Datenschutzvereinbarung.

Wieder aufgenommen (nicht verworfen): der Preprint bis 26.11.2026 (23.10.2026, bioRxiv statt arXiv stat.AP).

## Qualitätsbild

Verbindlicher Grundsatz (Intake Feld 5, bindend in `docs/01-fachspezifikation.md`, Abschnitt 2): Nichts gilt als geprüft, weil ein Test grün ist. Ein Test zählt erst, wenn er ein falsches Ergebnis erkennen würde. Jede Kennzahl hat mindestens zwei unabhängige Belege; wo es keine geschlossene Lösung gibt, entscheidet eine Simulationsstudie nach ADEMP mit festem Seed, mindestens `ankerRef: ANK-06` Wiederholungen je Szenario und angegebenem Monte-Carlo-Fehler. Referenzwerte nur mit Quelle, Seite, Wert und Toleranz als Anker unter `reference/anchors/`; nie geschätzt.

Messbare Maßstäbe je Kernfeature (Kriterien in `docs/02` bis `docs/04`):

| Kernfeature | Maßstab | Kriterien |
| --- | --- | --- |
| Varianzkomponenten, numerisch | gleich den ANOVA-Schätzern bei balancierten Plänen (Toleranz `ANK-TOL.reml_anova`); Literaturbeispiele auf die publizierte Stelle; Gegenrechnung VCA, SixSigma, lme4; Invarianzen und Randfälle | K-M1a-1 bis K-M1a-3, K-M1a-6 |
| %GRR, %Contribution, ndc, Verdikt | AIAG-Formeln; ndc mit 1,41, Abrundung und mindestens 1; Verdikt nach % Studienvariation mit Schwellen 10 und 30, Grenzwerte „bedingt“ (`ANK-16`) | K-M1a-5 |
| Numerische Genauigkeit | NIST StRD, Sätze niedriger und mittlerer Schwierigkeit, zertifizierte Stellen (`ANK-TOL.nist_digits`) | K-M1a-4 |
| Ordinal (latente Skala), binär (Logit) | Engine-Gleichheit mit `ordinal`/`lme4`, Wiederholbarkeit wie rptR, Wiederfinden simulierter Komponenten und β²/2 beziffert (Skripte M1b, Vollläufe und Befunde M1d) | K-M1b-1 bis K-M1b-7, K-M1d-6, K-M1d-7 |
| Bootstrap | Quantile wie `lme4::bootMer`; Überdeckung je Szenario gemessen und berichtet (Skript M1c, Volllauf und Befunde M1d) | K-M1c-1 bis K-M1c-5, K-M1d-6, K-M1d-7 |
| Testsuite | Mutationsscore über `R/fit.R` und `R/grr.R` mindestens `ANK-32` | K-M1c-6 |
| Kappa (Cohen, gewichtet, Fleiss), Krippendorffs Alpha | Originalwerte aller Gewichtungen und Skalenniveaus; gleich den etablierten Paketen | K-M3a-1 bis K-M3a-4 |
| Bias, Linearität | AIAG-Beispiele; Überdeckung simuliert | K-M3a-5 bis K-M3a-7 |
| Plackett-Burman, Lenth | Generatorzeilen 1946; Hadamard; `FrF2::pb` bis auf Tausch und Vorzeichen; Lenth 1989; Fehlalarmrate am Nominalniveau | K-M3b-1 bis K-M3b-6 |
| Westgard-Regeln, Simulator, Planung | Regeln genau an der Grenze; Fehlalarm gegen Westgard 1981/Parvin 1992; Komponenten wiedergefunden; Satterthwaite-Näherung | K-M3c-1 bis K-M3c-6 |
| Ausführung, Parser, Backends, Bericht | Abbruch und Fortsetzen ergeben denselben Speicher; Parser bestehen Zufallseingaben; aufgezeichnete echte Antworten; jede Zahl im Bericht gleich dem Objektwert; SHA-256 | K-M3d-1 bis K-M3d-6 |
| Paket gesamt | `R CMD check --as-cran` lokal ohne ERROR und WARNING (lint-Gate); drei Betriebssysteme als Release-Bedingung in AP2 (GitHub Actions, kein Harness-Kriterium) | K-M0-3 |
| Anwendungsbeispiel | eingefrorener Itemsatz mit SHA-256 aus belegter, versionierter Quelle; Routing festgelegt; Validierungsplan vor dem Lauf | K-M2-1 bis K-M2-6 |

## Quellen und Originale

- Bestehender Code: Repo `DanielMoj/llmsa`, Commit `332a2d5` (v0.1.0, 22 exportierte Funktionen, 27 Tests); lokal `Llmsa\llmsa\`.
- Formelsammlung: `reference/privat/07_Formelsammlung_llmsa.md` (Fassung nach Zweitprüfung 24.10.2026); Teil der Spezifikation nach Abschnitt 3 von `docs/01-fachspezifikation.md`. Mit (!) markiert und ungeprüft: nur noch die DIN-32645-Formeln (AP7, nicht im Scope).
- Quellenkatalog: `reference/privat/QUELLENKATALOG.md` (aus `Llmsa\quellen\KATALOG.md`, 189 Einträge, Stand 24.10. abends); Textspiegel `reference/quellen/text/` (git-ignoriert); Originale unter `Llmsa\quellen\` außerhalb des Repos.
- Freie Referenzdaten: NIST/SEMATECH e-Handbook (Gauge-Studie, Plackett-Burman), NIST StRD ANOVA; R-Datensätze `Penicillin` (lme4), `dataEP05A2_1`–`_3` (VCA), `ss.data.rr` (SixSigma), `wine` (ordinal), `BeetlesMale` (rptR), `diagnoses` und `vision` (irr).
- Echte Daten: llm-stability (Commit `c089c02…`, Apache 2.0), ClinVar `submission_summary`/`variant_summary` (Stand 19.10.2026, gemeinfrei), ClinGen ERepo (Stand 22.10.2026, CC0), INSAID-Liste (Van Gijn et al. 2018, Stand März 2017, keine kommerzielle Nutzung, bleibt lokal), CIViC (CC0), eigene PBPK-Literaturdatenbank. Herkunft je Datensatz: `Llmsa\quellen\daten\*\QUELLE.txt`.
- Konkordanzstudien als Vergleichswerte (seit 24.10.2026 in `Llmsa\quellen\literatur\E_anwendungsfall_acmg\`, Katalog Teil E): Yang et al. 2017, Amendola et al. 2016, Harrison et al. 2017, Lazareva et al. 2024, ergänzend Lincoln et al. 2017, Amendola et al. 2020 und Harrison et al. 2018 (`ANKER-TODO.md`, ANK-42 bis ANK-46; Katalogschlüssel Yang2017, Amendola2016, Harrison2017, Lazareva2024, Lincoln2017, Amendola2020, Harrison2018).
- Regulatorik: FDA-Guidance-Entwurf Januar 2025, FDA Credibility-Guidance 2023, EMA-Reflexionspapier 2024, EMA/FDA-Leitprinzipien Januar 2026, ICH Q2(R2), CLSI EP05-A2, EP09c, C24, ASME V&V 40 (nicht beschafft), DIN 32645 (nicht beschafft).
- Anbieterdokumentation (Schnappschüsse 22.10.2026): Modellkennungen, Abschaltpläne, Preise, Endpunkte je Modell (OpenRouter), Datenschutz; `Llmsa\quellen\anbieter_2026-10-22\`.
