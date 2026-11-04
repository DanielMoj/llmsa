# ADR-048 — Auslegungen des Reviewers zu M1d: Prüfformen K-M1d-1 bis K-M1d-8, Kerndateien nur roxygen, Anker ANK-34, ANK-40, ANK-42 bis ANK-47

## Status

Angenommen (Reviewer, `30-plan-review` M1d, Runde 1, 04.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 12 halten die Auslegungen fest, die `orchestrator/handoff/M1d/CRITERIA.json` unter `open` als ACC-1 bis ACC-12 führt.
  - ACC-1 bis ACC-11 und ACC-15 kündigen dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh`, `path_allowed`).
  - `PLAN.md` (Runde 1) übernimmt alle diese Auslegungen (Abschnitt „Übernahme der offenen Auslegungen“).
- Nr. 13 hält die Anker fest, die die Abnahmephase angelegt hat (ACC-15).
- Nr. 14 bestätigt Festlegungen aus `PLAN.md`, die diese Auslegungen ausfüllen.
- Nr. 15 ist ein Hinweis an den Betreiber ([INFRA]), keine Auslegung.
- Die Nummern ändern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen. Einzelheiten der Prüfformen stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M1d-1: Version der Läufe, Shot-Stufe und Laufordner (die Abbildung in docs/02 M1d kennt „die eine feste Aufgabenformulierung“), Werte der Spalten `answer` und `correct`, Abbildung beim Import;
  - K-M1d-1 und K-M1d-3: Format von `SHA256SUMS` über docs/01 §7 hinaus, Form der Neuerzeugung;
  - K-M1d-2: fehlende Antworten in Wiederholbarkeit und Trefferquote, Aufruf des Fits, Darstellung;
  - K-M1d-3: Quelle von `gene`, Kennung des Einreichers, Zählweise „mindestens zwei/drei Einreicher“, Datumsformat, Ort der Ausschlusszählung;
  - K-M1d-4: Abbildung im Aufruf, Konfliktbegriff, Filter der Sensitivität, Form des Literaturvergleichs;
  - K-M1d-5: Prüfform von Größe, Auswahlregel, INSAID-Suchmuster, Listung und Netz;
  - K-M1d-6: Prüfform von Vollständigkeit und Reproduktion; Vorbild sind ADR-023 Nr. 1 bis 8 und ADR-042 Nr. 3 bis 8;
  - K-M1d-7: Begriff der Komponente, Richtungswörter, Textform der Benennung, Zuordnung der Hilfeseiten;
  - K-M1d-8: Satzbau bei aktiven Faktoren, Bezug von „bleiben unverändert“.
- Die Regel „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ (docs/02, M1d, Voraussetzung) hat kein eigenes Kriterium (ACC-12).
- **Gemessen in dieser Phase** (PLAN-REVIEW M1d, Runde 1, Proben A bis C; R 4.6.1, pkgdown 2.2.1; Arbeitsbaum nach `3165a19` ohne Änderung unter `R/`, `inst/`, `vignettes/`, `man/`; die vier Kerndateien tragen die SHA-256 aus ANK-34):
  - Befundmenge nach Nr. 10.2 aus den vier Vollläufen (`n_sim` = 1000), 19 Befunde. Sie gleicht der Tabelle in `PLAN.md` (Abschnitt K-M1d-6 und K-M1d-7):
    - ordinal_recovery: Unterschätzung in S-ord-1 (model, prompt), S-ord-2 (model), S-ord-3 (model, prompt), S-ord-4 (model, prompt);
    - binary_recovery: Unterschätzung in S-bin-1 (model, prompt) und S-bin-2 (model);
    - two_level: S-two-1 und S-two-2 ohne Richtung (|bias| ≤ 3 MCSE);
    - boot_coverage: Überdeckung über dem Nominalwert für ndc in S-boot-1 bis S-boot-7 (0,991 bis 1,000; MCSE 0 bei 1,000). Keine weitere Überdeckung weicht um mehr als 3 MCSE ab. grr_pct_study_var, grr_pct_contribution und icc_items haben je Szenario dieselbe Überdeckung.
  - Alle 428 nach Nr. 10.1 zu tabellierenden Zellen (Szenario × Schätzziel × Kennzahl; 75, 30, 30 und 293 je Studie) haben endlichen Wert und MCSE.
  - `msa_agreement()` gleicht der Mini-Referenz `acc_m1d_kripp()` (setup-m1d.R) auf 20 synthetischen Datensätzen mit einer bis sechs Einreichungen je Einheit in beiden Metriken bis auf 2,2e-16.
  - Mini-Referenz der ClinVar-Teilmengen (115 s): HRF 1.383 Varianten mit 6.647 Einreichungen, Stichprobe 1.000 mit 5.010, Ausschlüsse 501 und 43.886, wie ACC-6 (5), (6) und (8).
  - Pflichtfits:
    - Ordinal mit Probit (Vorgabe) auf beiden Referenzteilmengen ohne Warnung, 3,6 s und 3,5 s.
    - Mit Logit bricht der Fit auf beiden ab: „optimizer nlminb failed to converge“.
    - Binär je Aufgabe von llm-stability, mit einem einfachen Etikettenparser des Reviewers: alle acht Fits in 0,2 bis 1,6 s, jeweils mit der Warnung über verworfene fehlende Antworten.
  - Rohdaten:
    - `DateLastEvaluated` der Referenzteilmengen nur „Mon DD, YYYY“ oder „-“.
    - Submitter-Namen mit Komma (4.294 und 3.130 Zeilen), mit Anführungszeichen (3 Zeilen in HRF) und mit Nicht-ASCII-Zeichen (46 und 38 Zeilen).
    - `review_status`: „criteria provided, single submitter“, „no assertion criteria provided“, „flagged submission“, „reviewed by expert panel“ (nur in der Stichprobe, 37 Zeilen).
    - ruin_names rubric_id 99 und 144 mit Text-Schlüssel (ANK-40, observations). Die Frage zerlegt dort die Optionen an Kommas, etwa „(I) dearth“ für den Schlüssel „dearth, wind, & fire“.
  - Ausgangsstand mit den Vollläufen:
    - `tests/testthat`: 283 Tests ohne Fehlschlag (1 übersprungen, ellmer), darunter die Literalprüfung `test-validation-latent.R:123–156` gegen die Vollauf-Werte.
    - Die Abnahmetests `m1a-7-vignette`, `m1b-7-vignette*` und `m1c-5-vignette*`: 26 Tests ohne Fehlschlag.

## Entscheidung

1. **(ACC-1) Datenauswahl llm-stability.**
   1. Rohdaten: `experiments/v3/runs.tgz` (SHA-256 aus ANK-40). Die v2-Daten haben fünf Läufe und entfallen.
   2. Je Modell und Aufgabe genau der Ordner, den `experiments/v3/stability_eval.csv` mit `top_p_k` 1.0 und `shots` 0 auswertet (Zero-shot). Die 40 Ordner stehen in ANK-40 `value.selection.folders`.
   3. Few-shot-Ordner, Läufe mit `top_p_k` 0.0 und leere Ordner entfallen. Ein Wechsel der Shot-Stufe ändert ANK-40 und braucht ein ADR.
2. **(ACC-2) Spalten und Werte von `items.csv.gz`.**
   1. Kopfzeile genau `task, model, run, item_id, answer, correct`; gzip; eine Zeile je Aufgabe × Modell × Lauf × Item, vollständiges Gitter (82.850 Zeilen).
   2. `task`, `model` und `run` wie in den Rohdateien, `item_id` = `rubric_id`.
   3. `answer`: aus `response` geparstes Optionsetikett „(A)“, „(B)“, … der Frage, bei navigate „Yes“ oder „No“. Fehlend, wenn keine oder keine eindeutige Antwort gefunden wird. Keine weiteren Spalten, kein Rohtext.
   4. `correct`: TRUE bei `answer` gleich `gt`, FALSE bei vorhandener abweichender `answer`, fehlend bei fehlender `answer`.
   5. Prüfform:
      - die Schlüssel sind vollständig;
      - jede `answer` ist ein Etikett der Optionen ihres Items oder der Schlüssel;
      - bei leerem `response` gibt es keine `answer`;
      - das Etikett jeder `answer` kommt im zugehörigen `response` als Wort vor (Groß- und Kleinschreibung gleichgültig);
      - `correct` folgt Nr. 2.4.
      Gleichheit mit den Zählungen von `stability_eval.csv` wird nicht verlangt, weil die Antworten der Quelle teils von Hand annotiert sind.
3. **(ACC-3) Import.**
   - Je Aufgabe `as_msa_runs()` mit item = `item_id`, einer konstanten Prompt-Stufe, model = `model`, rep = `run` und value = `correct` (binär) oder `answer` (nominal).
   - `msa_counts()` liefert je Aufgabe fünf Zeilen mit n = Items der Aufgabe × 10. Fehlende Antworten bleiben fehlend.
4. **(ACC-4) Ordnerinhalt, `SHA256SUMS`, Neuerzeugung.**
   1. `SHA256SUMS`: je Datei des Ordners außer `SHA256SUMS` genau eine Zeile im Format von sha256sum (`<sha256 klein>  <Datei>`) mit der SHA-256 der gespeicherten Datei.
   2. Neuerzeugung in einer Paketkopie:
      - Inhalt der Kopie: `DESCRIPTION`, `NAMESPACE`, `R/`, `inst/`, `data/`, `data-raw/`, `reference/anchors/`; der Geschwisterordner `quellen/` verweist auf `../quellen`.
      - Arbeitsverzeichnis und `REPO_ROOT` sind die Kopie; Aufruf `Rscript data-raw/<skript>`.
      - Die neu geschriebenen `.csv.gz` gleichen den eingefrorenen Byte für Byte (gzip ohne Zeitstempel).
      - Die Ausgabe hängt nicht von der Locale ab; der Test läuft mit `LC_COLLATE=C`.
   3. Ohne `../quellen` bricht das Skript mit einer Meldung ab, die „quellen“ nennt, und lässt die eingefrorenen Dateien unverändert.
5. **(ACC-5) Prüfform K-M1d-2.**
   1. Attribut-Wiederholbarkeit je Aufgabe und Modell: Anteil der Items der Aufgabe, deren zehn Läufe alle eine nicht fehlende und dieselbe `answer` tragen. Ein Lauf ohne Antwort bricht die Übereinstimmung. Nenner sind alle Items der Aufgabe.
   2. Trefferquote je Aufgabe und Modell: Anteil der Aufrufe mit `correct == TRUE` an allen Aufrufen der Zelle.
   3. Binärer Fit je Aufgabe: `msa_fit(as_msa_runs(…, value = correct), type = "binary")` mit den Vorgaben für `interactions` (FALSE) und `link` (probit) oder mit logit; dazu `msa_grr()`.
   4. Einlesen im R-Code mit `system.file("extdata", …)` unter Nennung von `llm-stability_2026-10-22` und `items.csv.gz`; kein Pfad zu `../quellen`, `inst/extdata` oder `REPO_ROOT`.
   5. Darstellung:
      - Tabellen je Aufgabe und Modell mit Wiederholbarkeit und Trefferquote (Anteil oder Prozent);
      - je Aufgabe die Komponenten item und model und %GRR (Studienvariation) des Fits;
      - mindestens zwei signifikante Stellen; verglichen wird auf eine Einheit der letzten gezeigten Stelle;
      - jede Aufgabe und jedes Modell mit dem Namen aus den Daten.
   6. Kein Literal mit mindestens drei signifikanten Stellen im Rmd gleicht einem berechneten Wert.
6. **(ACC-6) Auswahlregeln und Spalten der ClinVar-Teilmengen.**
   1. Fünf Klassen: `ClinicalSignificance` gleich einem der Begriffe Benign, Likely benign, Uncertain significance, Likely pathogenic, Pathogenic, exakt.
   2. `submitter_id` ist der Wert von `Submitter` unverändert.
   3. „Mindestens zwei/drei Einreicher“ heißt verschiedene `Submitter` unter den Fünf-Klassen-Einreichungen der Variante: erst filtern, dann zählen (ANK-47).
   4. `gene`: `GeneSymbol` aus `variant_summary.txt.gz` zur `VariationID`, unverändert, auch Listen mit „;“. Fehlt die `VariationID` dort, fehlt `gene`.
   5. HRF: Varianten, deren `GeneSymbol`-Liste MEFV, MVK, NLRP3 oder TNFRSF1A enthält und die mindestens zwei verschiedene Einreicher haben, mit allen ihren Fünf-Klassen-Einreichungen, auch mehreren SCV desselben Einreichers.
   6. Stichprobe:
      - die VariationIDs mit mindestens drei verschiedenen Einreichern, aufsteigend sortiert;
      - `set.seed(20261024)` und `sample(…, 1000)` mit dem Vorgabe-RNG (Mersenne-Twister, Inversion, Rejection);
      - alle Fünf-Klassen-Einreichungen der gezogenen Varianten.
   7. `date_last_evaluated`: ISO-Datum JJJJ-MM-TT oder Rohformat „Mon DD, YYYY“; „-“ wird fehlend. `review_status` unverändert.
   8. `QUELLE.txt` nennt die Zahl der Einreichungen mit einem Begriff außerhalb der fünf Klassen, (a) unter allen Einreichungen zu Varianten der vier Gene und (b) in der ganzen Datei. Tausendertrennzeichen sind erlaubt.
   9. Vergleich mit der Mini-Referenz als Multimenge der Zeilen; das Datum wird als Datum verglichen. Die Zeilenreihenfolge ist frei, aber durch die Byte-Gleichheit der Neuerzeugung festgelegt.
7. **(ACC-7) Prüfform K-M1d-4.**
   1. Abbildung: `as_msa_runs()` mit item = `variation_id`, prompt = `submitter_id`, je einer Modell- und Blockstufe, rep 1 und value = `classification`; `levels` in Skalenordnung.
   2. Krippendorffs Alpha:
      - `msa_agreement(runs, levels, weights = "unweighted")` für nominal, `weights = "linear"` für ordinal; jeweils die Zeile „all conditions“ (Einheit = Variante);
      - verglichen mit der Mini-Referenz nach Krippendorff (2011) auf ANK-TOL.package_compare.
   3. Anteile, Nenner jeweils die Varianten mit mindestens zwei Einreichungen:
      - vollständige Übereinstimmung: alle Einreichungen der Variante in derselben Klasse;
      - Konflikt: Einreichungen in mindestens zwei der Gruppen P/LP, VUS, LB/B (wie ANK-46).
   4. Ordinaler Fit: `msa_fit(runs, type = "ordinal", levels = fünf Klassen)` mit den Vorgaben für `interactions` und `link` (probit) oder mit logit; dazu `msa_grr()`. Die Vignette zeigt je Teilmenge die Komponenten item und prompt und %GRR.
   5. Sensitivität:
      - Zeilen, deren `review_status` mit „criteria provided“ beginnt;
      - die Vignette zeigt mindestens Alpha nominal und ordinal je Teilmenge und nennt „criteria provided“;
      - die Schwellen der Teilmengenbildung werden nicht neu angewandt.
   6. Literaturvergleich:
      - die gestrickte Vignette nennt ANK-42 bis ANK-46 mit ID und zeigt jeden Zahlenwert aus `value` dieser Anker;
      - die Werte werden gelesen, nicht abgetippt; Kopien der Anker unter `inst/` sind byte-gleich mit `reference/anchors/`;
      - der Satz „not an acceptance criterion“ steht wörtlich in der Vignette.
   7. Darstellung wie Nr. 5.5.
8. **(ACC-8) Prüfform K-M1d-5.**
   1. Größe: jede Datei ≤ `file_max_bytes`, jede Datei über `gzip_above_bytes` eine gzip-Datei mit Endung `.csv.gz`, jeder der beiden Ordner ≤ `folder_max_bytes`, `inst/extdata/` gesamt ≤ `extdata_total_max_bytes`; Bytes nach ANK-TOL.data_size.byte_reading.
   2. `QUELLE.txt` llm-stability: Lizenz Apache 2.0 und die Auswahlregel mit `experiments/v3/runs.tgz`, `stability_eval.csv`, `top_p_k` und „zero-shot“.
   3. `QUELLE.txt` ClinVar: „public domain“, die fünf Klassen, die vier Gene, Seed und Umfang aus ANK-47, `variant_summary` als Quelle von `gene`, die Zählungen nach Nr. 6.8.
   4. INSAID-Suchmuster: Jede Tabellendatei (`.csv`, `.tsv`, `.txt`, auch `.gz`) und jedes R-Datenobjekt (`.rda`, `.rdata`, `.rds`) des Arbeitsbaums außer `.git/`, `reference/quellen/` und `reference/privat/` mit einer Spalte `classification` ist ein Treffer, wenn eine Zelle „insaid“ lautet oder der Pfad „insaid“ enthält.
   5. `_pkgdown.yml`: `articles` enthält in `contents` die Einträge `llm-stability` und `clinvar-raters`.
   6. Netz: Der R-Code beider Vignetten, also alle Zeilen der R-Chunks einschließlich Kommentarzeilen und der Inline-Code, enthält weder `httr2` noch `curl` noch `download.file`.
9. **(ACC-9) Prüfform K-M1d-6.**
   1. Vollständigkeit:
      - die drei Dateien je Studie unter `inst/validation/sim/`;
      - Schema, Schätzziele, Kennzahlen und `mcse` wie in M1b und M1c;
      - eine `n_sim` für alle Zeilen, `n_sim` ≥ ANK-06.n_sim_min;
      - die Replikatdatei enthält jede Wiederholung 1 … `n_sim` je Szenario und Schätzziel, und die Kennzahlen folgen aus ihr (ANK-TOL.arithmetic).
   2. Reproduktion:
      - Neulauf jedes Skripts mit `--n-sim` ANK-TOL.n_check über alle Szenarien der Studie, für boot_coverage S-boot-1 und S-boot-7, mit dem Paket unter Test;
      - die Einzelschätzer gleichen den Zeilen `rep` ≤ n_check der Vollauf-Replikatdatei in allen Spalten nach `format(x, digits = 15)`;
      - der Seed je Szenario gleicht dem des Vollaufs.
   3. Session-Datei: R-Version, Versionen von llmsa, lme4 (und ordinal), Mersenne-Twister, Rejection, jeder Seed der Ergebnisdatei und eine Laufzeitangabe.
10. **(ACC-10) Prüfform K-M1d-7.**
    1. Tabellen:
       - `validation.Rmd` liest die vier Vollauf-Ergebnisdateien, nicht die Kurzläufe;
       - je Studie, Szenario und Schätzziel (außer dem Anteil `bootstrap`) zeigt eine Tabellenzeile Wert und MCSE von `bias`, `rel_bias` und `empse`, bei den Intervall-Schätzzielen von boot_coverage (`grr_pct_study_var`, `grr_pct_contribution`, `ndc`, `icc_items`) zusätzlich von `coverage` und `width`;
       - Wert und MCSE beide als Wert oder beide in Prozent, mit mindestens zwei signifikanten Stellen;
       - `n_sim` jeder Datei wird genannt;
       - kein Literal mit mindestens drei signifikanten Stellen aus den Dateien steht im Rmd.
    2. Befunde:
       - (a) ordinal_recovery und binary_recovery: jede wahre Komponente (Schätzziele des Szenarios außer Residual, `grr_pct_study_var` und `icc_items`) mit |rel_bias| > max(0,10; 3 × MCSE(rel_bias));
       - (b) two_level: die Verzerrung (`bias`) der Komponente model (β̂²/2) in jedem Szenario; eine Richtung wird verlangt, sobald |bias| > 3 × MCSE;
       - (c) boot_coverage: jede `coverage` eines Intervall-Schätzziels mit |coverage − 0,95| > 3 × MCSE.
       Die Schwellen kommen aus ANK-TOL.bias_report und ANK-TOL.mc_factor.report.
    3. Benennung in der Vignette: Für jeden Befund nennt eine Tabellenzeile oder ein Satz der gestrickten Vignette drei Dinge:
       - die Szenario-ID;
       - das Schätzziel wie in der Spalte `estimand`;
       - die Richtung mit einem dieser Wörter: „overestimation“ oder „underestimation“ (auch „over-estimat…“), „undercoverage“ oder „overcoverage“ (auch „under-cover…“), „below nominal“ oder „above nominal“.
    4. Hilfeseiten, gelesen als Text der Rd-Datei unter `man/` (`tools::Rd2txt`):
       - `?msa_fit` nennt jedes Szenario mit Befund aus ordinal_recovery, binary_recovery und two_level;
       - `?msa_boot` nennt jedes Szenario mit Befund aus boot_coverage;
       - beide jeweils mit den vorkommenden Richtungswörtern und einem Verweis auf die Vignette (`vignette("validation")` oder `validation.Rmd`).
    5. Kein Akzeptanzkriterium: Ein Befund lässt keinen Test fehlschlagen; geprüft wird nur, dass er benannt ist (BL-04).
11. **(ACC-11) Prüfform K-M1d-8.**
    1. Satz: zur Laufzeit aus docs/02 gelesen (Text zwischen „ und “ in der Zeile von K-M1d-8), x ersetzt durch `formatC(ME, format = "f", digits = 4)`, verglichen nach Normalisierung. Der ME-Wert der Zeile mit PSE, ME und SME ist dieselbe Zeichenkette.
    2. Aktive Faktoren:
       - jeder Faktor mit `active = TRUE` steht vor seinem Zusatz („also above SME“ bei `active_simultaneous = TRUE`, sonst „above ME only“), ohne dass vorher ein anderer Faktorname oder der andere Zusatz folgt;
       - kein inaktiver Faktor trägt einen Zusatz;
       - ohne aktiven Faktor steht kein Zusatz, mit aktiven Faktoren nicht der Satz aus Nr. 11.1.
    3. Bericht: Abschnitt „6. Robustness“ des mit `msa_report(…, robustness = …)` als GitHub-Markdown ohne Umbruch gerenderten Berichts.
    4. Altphrase: Keine Datei unter `R/` und `inst/templates/` enthält „robust to all screened perturbations“.
    5. Unverändert:
       - `msa_robustness()` liefert auf fünf Aufrufen dasselbe Objekt (`identical`) wie `R/robustness.R` aus `done/M1c` (ANK-34);
       - `acmg_robustness()` liefert auf synthetischen PB-Läufen des AP1-Plans, die alle drei Bänder erzeugen, dasselbe Ergebnis wie `R/acmg.R` und `R/robustness.R` aus `done/M1c`.
12. **(ACC-12) Kerndateien nur roxygen.**
    - `R/fit.R` und `R/grr.R` des Pakets unter Test gleichen ohne die Zeilen, die nach Leerraum mit `#'` beginnen, den Fassungen aus `done/M1c` (ANK-34) Zeile für Zeile.
    - Geführt im Test von K-M1d-7; zugleich Bedingung von ADR-047 Nr. 2.
13. **(ACC-15) Anker.**
    1. Neu in `10-acceptance` M1d:
       - ANK-40 (llm-stability: Struktur und Quellordner);
       - ANK-42 (Yang 2017), ANK-43 (Amendola 2016), ANK-44 (Harrison 2017), ANK-45 (Van Gijn 2018), ANK-46 (Lazareva 2024);
       - ANK-47 (Stichprobe);
       - ANK-34 (Ausgangsstand `done/M1c` für K-M1d-8 und Nr. 12, freie Nummer nach ANKER-TODO „Nicht vergeben“).
    2. Unverändert genutzt: ANK-06, ANK-41, ANK-63 und ANK-TOL (`bias_report`, `mc_factor`, `n_check`, `data_size`, `package_compare`, `arithmetic`).
    3. Die Literaturwerte sind am Original geprüft. Geschützte Quellen (Amendola 2016, Van Gijn 2018) stehen nur mit Kurzzitaten in den Ankern.
    4. Dieses ADR ist das ADR im selben Meilenstein für diese Ankeränderungen (docs/01 §6). Die Golden-Daten unter `inst/extdata/` dokumentiert das Builder-ADR aus `PLAN.md` (Abschnitt Dateien).
14. **Bestätigte Festlegungen aus `PLAN.md`.**
    1. Antwortparser: Der Schlüssel `gt` dient nur dem Vergleich nach Nr. 2.4, nie der Wahl zwischen mehreren Treffern. Die Regel des Parsers und die Zahl der fehlenden Antworten nach Grund (leer, kein Etikett, mehrdeutig) stehen in `QUELLE.txt` und im Builder-ADR.
    2. Text-Schlüssel ruin_names rubric_id 99 und 144:
       - `correct` folgt unverändert Nr. 2.4, ist also bei jeder Etikett-Antwort FALSE;
       - keine Reparatur über den Schlüssel;
       - `QUELLE.txt` und die Vignette nennen beide Items und ihre Wirkung auf die Trefferquote von ruin_names (docs/01 §2 Nr. 4: nie stillschweigend eine falsche Zahl).
    3. Fits: Alle Pflichtfits der beiden Vignetten laufen mit dem Vorgabelink probit und `interactions = FALSE`. Logit ist auf den ClinVar-Teilmengen keine Ausweichmöglichkeit (Kontext).
    4. Konvergenz-Sensitivität (BL-92):
       - gerechnet allein aus `ordinal_recovery_replicates.csv` (Spalten `estimate`, `true`, `converged`), getrennt von der Hauptauswertung, mit dem n der eigenen Zeilen;
       - kein Abgleich mit der Ergebnisdatei, keine Änderung der Ergebnisleser.
    5. Ressourcen unter `inst/validation/m1d/` folgen dem Muster von `inst/validation/latent/` (ADR-021, ADR-026):
       - ganze Ankerkopien, byte-gleich mit `reference/anchors/`, mit `SOURCES.json`, erzeugt von `data-raw/make_validation_m1d.R`;
       - `validation.Rmd` lädt neue Helfer nur in der Form `sys.source(system.file(…, package = "llmsa", mustWork = TRUE), …)` mit wörtlichen Argumenten (`tests/testthat/helper-validation-latent.R:51–98`);
       - neue Helfer tragen nicht die Präfixe `sim_` und `boot_`, damit sie außerhalb der Implementierungshashes bleiben (`simulation_helpers.R:209–218`, `boot_coverage_helpers.R:242–255`).
    6. two_level: Ohne Richtung nennt die Vignette Verzerrung und MCSE je Szenario und behauptet keine allgemeine Unverzerrtheit.
    7. Das Builder-ADR für die Golden-Daten erhält die nächste freie Nummer nach diesem ADR (ADR-049).
15. **Hinweis an den Betreiber ([INFRA], nicht blockierend für den Builder).**
    - `_pkgdown.yml` liegt außerhalb der Builder-Pfade (`orchestrator/config.env:200`, `BUILDER_EXTRA_PATHS_REGEX`; `orchestrate.sh`, `path_allowed`).
    - Für K-M1d-5 ergänzt der Betreiber vor `40-build` den Abschnitt `articles` (M1D-INFRA-01 in `PLAN.md`), und zwar mit `validation`. Grund: pkgdown 2.2.1 bricht bei einem `articles`-Index ab, wenn eine Vignette außer der Einstiegsvignette `llmsa` fehlt (`pkgdown:::data_articles_index`, „vignette missing from index“).
    - Vorschlag:

      ```yaml
      articles:
      - title: Validation
        contents:
        - validation
      - title: Applications
        contents:
        - llm-stability
        - clinvar-raters
      ```

## Konsequenzen

- `PLAN.md` Runde 1 ist mit diesen Festlegungen freigegeben (PLAN-REVIEW M1d, Runde 1: PASS).
- Die minor-Befunde E1 bis E15 in `orchestrator/handoff/M1d/PLAN-REVIEW.md` sind Umsetzungshinweise und keine neuen Kriterien.
- Das Code-Review M1d prüft gegen Nr. 1 bis 14, Nr. 12 zusammen mit ADR-047 Nr. 2.
- Die Messwerte im Kontext sind Proben des Reviewers auf den Mini-Referenzen und einem einfachen Parser. Sie sind weder Ergebnisse der Vignetten noch Referenzwerte für Tests.
- Ohne die Betreiberzuarbeit aus Nr. 15 bleibt K-M1d-5 in der Listung rot. Das ist kein Builder-Befund.
