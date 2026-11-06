# ADR-053 — Auslegungen des Reviewers zu M3d: Prüfformen K-M3d-1 bis K-M3d-6 (ACC-2 bis ACC-14), Anker, Seed-Provenienz neben den Vergleichen aus M1d und M3b, Festlegungen zum Plan

## Status

Angenommen (Reviewer, `30-plan-review` M3d, Runde 1, 06.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 12 halten die Auslegungen fest, die `orchestrator/handoff/M3d/CRITERIA.json` unter `open` als ACC-2 und ACC-4 bis ACC-14 führt.
  - ACC-1 kündigt dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh:518`, `path_allowed`).
  - `PLAN.md` (Runde 1) übernimmt diese Auslegungen (Abschnitt „Ziel“, Z. 37–43).
- Nr. 13 hält die Anker fest (ACC-1).
- Nr. 14 bis 16 entscheiden die Punkte, die `PLAN.md` dem Reviewer vorlegt (P-M3d-01 bis P-M3d-03, Abschnitt „Risiken“, Z. 316–367).
- Nr. 15, 17 und 18 präzisieren den Plan. Die Befunde in `orchestrator/handoff/M3d/PLAN-REVIEW.md` (Runde 1) verweisen hierher: E1 auf Nr. 17, E2 bis E6 und E8 auf Nr. 18, E7 auf Nr. 15, E9 auf Nr. 14.6, E10 auf Nr. 14.5.
- Nr. 19 enthält Hinweise, keine neuen Regeln.
- Außer den in Nr. 14.5 genannten Stellen ändern die Nummern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen. Einzelheiten stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M3d-1: Form und Ort des Abbruchs, Abbruchpunkt, Neustart des Backends, verglichene Spalten;
  - K-M3d-2: Grammatik der gültigen und ungültigen Formen; Modus, Aliase und umgebender Text bei `parse_choice()`; Feldtypen, Verschachtelung und Arten kaputten JSONs;
  - K-M3d-3: Chat-Objekte und Felder von `meta` bei ellmer; Fehlerarten und Form leerer Antworten; Prüfweg und Ort der dokumentierten Fehlermeldung;
  - K-M3d-4: Ausgabeformat, Fundstellen der Kennzahlen, Vergleichsregel; Argument, Abschnitt und Form der Westgard-Verletzungen;
  - K-M3d-5: Spaltenmenge, Kopfzeile, Zahlenformat, Anführung, Sortierregel;
  - K-M3d-6: Wortlaut und Ort der Konventionen, Ort und Form der Seeds und der Modelltabelle, Weg der Seeds in den Bericht.
- **Spec-Lage zu den Seeds** (P-M3d-01):
  - docs/01 §4: „Ohne ADR erlaubt: … zusätzliche Felder in Rückgabeobjekten; zusätzliche Attribute“.
  - docs/01 §5 und Formelsammlung §11: „jede Randomisierung (Laufreihenfolge, Plackett-Burman-Zuordnung, Bootstrap, …) trägt einen protokollierten Seed“.
  - K-M3d-6: Der Bericht nennt „alle Seeds (Design, Bootstrap, Plackett-Burman)“.
  - docs/02, M1d, Voraussetzung: „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“
  - K-M1d-8: „Das Objekt von `msa_robustness()` und die Bänder bleiben unverändert.“
  - K-M1c-7: „… und die Ergebnisse von `msa_boot()` bleiben bytegleich.“
  - ADR-051 (M3b) Nr. 9.3: „Im Standardpfad gleicht das Objekt dem bisherigen mit `identical()`, ohne neues Attribut“; Nr. 7.7: „Ein Seed-Attribut verlangt M3b nicht; die Seeds nennt der Bericht nach K-M3d-6.“
  - Die drei Sätze aus docs/02 sind Voraussetzung bzw. Kriterien ihres Meilensteins („M1d ändert …“; Kriterien K-M\<x\>-\<n\> nach docs/01 §1). So gelesen widerspricht keiner von ihnen docs/01 §4 oder K-M3d-6. Ein wörtlicher Widerspruch, der `ESCALATE` verlangte, liegt nicht vor. Die bindende Lesart steht in Nr. 14.
  - `msa_report()` erhält in den Abnahmetests nur die Objekte (`setup-m3d.R:642–646`). Bootstrap- und PB-Seed müssen also mit `msa_boot()` und `msa_robustness()` reisen. `msa_boot()` steht in `R/grr.R:193–218`; das Objekt trägt bisher keinen Seed.
- **Gemessen in dieser Phase** (PLAN-REVIEW M3d r1, Prüflauf 1; R 4.6.1, testthat 3.3.2; Paketkopie unter `tempdir()`; Arbeitsbaum ohne Produktänderung; Probe unter `orchestrator/handoff/M3d/.probe-plan-review-r1/`, danach gelöscht):
  - Die Kopie erhält eine Zusatzdatei, die `pb_design()`, `msa_robustness()` und `msa_boot()` genau die Attribute aus Nr. 14.2 gibt. Ausgewählt sind die Testdateien ohne Git-Kommando, die diese Objekte berühren: `tests/acceptance` test-m3b-\* und test-m1c-1/-2 (40 Blöcke), `tests/e2e` M1c, M1d, M3b (11), `tests/fuzz` M3b (2), `tests/testthat` Robustheit, Bootstrap, Bericht (32).
  - Ohne Zusatzdatei sind alle grün. Mit ihr ist nur QA-M3b-E2E-3 rot: `tests/e2e/test-m3b-qa-e2e.R` Z. 214 (Attributnamen ohne `seed`) und Z. 231 (PB-Plan gegen einfachen data.frame mit `identical()`).
  - Nicht gelaufen, weil sie Git-Kommandos ausführen (`acc_git()`, `setup-acceptance.R:91`): test-m1d-7 Z. 139–147, test-m1d-8 Z. 83–121, test-m1c-7-byte-equality. Aus dem Code gelesen:
    - test-m1d-7 vergleicht die Codezeilen von `R/grr.R` im Arbeitsbaum mit done/M1c; jede Codezeile für das Seed-Attribut macht ihn rot.
    - test-m1d-8 vergleicht mit `identical()` gegen done/M1c: `msa_robustness()` auf `pb_design(11, n_runs = 12, seed = 20261103L)` (`setup-m1d.R:731`) und `acmg_robustness()`, dessen `acmg_pb()` einen Seed übergibt (`R/acmg.R:231`). Das neue Attribut macht beide Vergleiche rot.
    - test-m1c-7-byte-equality vergleicht nur data.frame, `boot` und `level` (`setup-m1c.R:749–753`) und bleibt grün.

## Entscheidung

1. **(ACC-2) Prüfform K-M3d-1.**
   1. Plan: Items „001“ und „010“, Prompts P1 und P2, Modelle m1 und m2, zwei Replikate, zwei Blöcke, `order = "random"`, `seed = 3101`, also N = 32 Aufrufe. Backend `backend_mock(c("001" = 0.8, "010" = -0.4), p_fail = 0.25, seed = 3101)`, Parser `parse_number()`.
   2. Seeds 1 bis 50 aus ANK-TOL.resume_cutpoints. Je Seed s ist der Abbruchpunkt k = `sample.int(N − 1, 1)` unter `set.seed(s)` (Mersenne-Twister, Inversion, Rejection).
   3. Abbruch: Vor Aufruf k + 1 signalisiert das Backend eine Bedingung der Klasse `interrupt` (wie Strg+C), keinen `error`. `msa_run()` speichert dafür keine Zeile und endet: Es gibt die Bedingung weiter oder endet mit einer eigenen. Danach hält der Speicher genau die k abgeschlossenen Aufrufe.
   4. Fortsetzen: `msa_run(resume = TRUE)` mit einem neuen `backend_mock()` mit denselben Argumenten, wie nach einem Neustart der R-Sitzung. Die Antwort des Mocks auf eine Designzeile hängt nur vom Seed und von `block`, `item_id`, `prompt_id`, `model_id` und `rep` ab, nicht von der Zahl vorheriger Aufrufe.
   5. Verglichen werden alle gespeicherten Spalten außer `timestamp` und `latency_s`, Zeilen nach `run_key` sortiert; CSV-Felder als Text (`utils::read.csv(colClasses = "character")`), die SQLite-Tabelle wie gespeichert. `run_key` ist eindeutig, die Schlüsselmenge gleicht der des Plans.
2. **(ACC-4) Prüfform K-M3d-2, `parse_number()`.**
   1. 10.000 Eingaben, Seed 20261024 (ANK-TOL.parser_cases). Das Dezimalzeichen wird je Eingabe gezogen; geprüft mit `parse_number()` bzw. `parse_number(decimal = ",")`.
   2. Ungültig, erwartet `NA`: Text ohne Ziffer (auch „-“, „+“, „.“, „,“, „e“), `""`, Leerraum, `NA`.
   3. Gültig ist genau eine Zahl, die nicht an einem Buchstaben klebt:
      - Vorzeichen leer, „-“, „+“ oder in etwa 5 % der Fälle U+2212;
      - ganzzahliger Teil ohne führende Nullen (außer „0“), leer vor einem Dezimalzeichen;
      - 1 bis 5 Nachkommastellen mit dem Dezimalzeichen des Parsers;
      - Exponent e/E mit optionalem Vorzeichen und 1 bis 2 Ziffern;
      - davor optional Wörter, die an Buchstaben klebende Ziffern enthalten dürfen (IC50, EC50, pIC50, CYP3A4, H2O), Leerraum und eine öffnende Klammer oder ein Anführungszeichen; danach eine Einheit, auch ohne Leerzeichen, und Text ohne Ziffern.
   4. Erwartet ist `as.numeric()` der Zahl mit „.“ und ASCII-Minus, exakt gleich.
   5. Nicht im Vertrag: Tausendertrenner, „× 10^n“, hochgestellte Exponenten, Zahlen direkt hinter Buchstaben (USD12.50), mehrere Zahlen.
3. **(ACC-5) Prüfform K-M3d-2, `parse_choice()`.**
   1. Klassen und Aliase aus ANK-69; der Modus wird je Eingabe gezogen.
   2. Vorgabemodus (`whole_word = FALSE`, Teilzeichenkette): nur die Aliase VUS, VOUS und uncertain; die umgebenden Wörter enthalten keine Klassen- oder Aliaszeichenkette.
   3. Wortmodus (`whole_word = TRUE`): alle Aliase aus ANK-69; die umgebenden Wörter schließen ACMG-Kriterien ein (PS1, PM2, PP3, BS1, BP4, PVS1), nicht die Wörter der Klassen und nicht „likely“.
   4. Gültig: eine Klasse über eine ihrer Bezeichnungen in zufälliger Groß- und Kleinschreibung je Zeichen, mit 0 bis 4 Wörtern davor und danach und Trennern. In 20 % der Fälle wiederholt (dieselbe Klasse, auch über einen anderen Alias). Erwartet ist die Klasse.
   5. Ungültig, erwartet `NA`: keine Klasse, `""`, `NA`; im Wortmodus zusätzlich zwei verschiedene Klassen (K-M2-3).
   6. Zweiter Beleg: Die Mini-Referenzen von K-M2-3 (`acc_m2_parse_ww()`, `acc_m2_parse_v010()`) liefern auf allen Eingaben den erwarteten Wert.
4. **(ACC-6) Prüfform K-M3d-2, `parse_json_field()`.**
   1. Feld aus classification, class, value, result, label_1, Klasse.
   2. Gültig: Das Feld ist Mitglied der obersten Ebene des ersten Objekts. Sein Wert ist
      - eine Zeichenkette; erwartet ist die dekodierte Zeichenkette (Escapes für Anführungszeichen, Backslash, Schrägstrich, Zeilenumbruch, Tabulator, Wagenrücklauf und Steuerzeichen, wahlweise Nicht-ASCII-Zeichen als u-Escape);
      - oder eine Zahl, deren Text R mit `as.character(as.numeric(t))` wiedergibt; erwartet ist dieser Text.
   3. Weitere Mitglieder sind beliebige JSON-Werte einschließlich verschachtelter Objekte und Felder, Zeichenketten mit Klammern, Anführungszeichen, Doppelpunkten und Kommas. Verschachtelte Objekte dürfen denselben Schlüssel tragen; es gilt die oberste Ebene. Leerraum schließt CRLF ein.
   4. Einbettung: reines JSON, JSON in Text (Text davor ohne geschweifte Klammern, Text danach), Codeblock ```` ```json ````.
   5. Ungültig, erwartet `NA`:
      - kein „{“; ein vor der letzten schließenden Klammer abgeschnittenes Objekt;
      - Feld fehlt auf der obersten Ebene, auch wenn es nur in einem verschachtelten Objekt steht oder das Objekt `{}` ist; Feld nur in einem zweiten Objekt hinter dem ersten;
      - Syntaxfehler: einfache Anführungszeichen, Schlüssel ohne Anführungszeichen, fehlender Doppelpunkt, fehlendes Komma, Komma vor der schließenden Klammer, nicht beendete Zeichenkette, ungültiges Escape (Backslash vor x).
   6. Nicht im Vertrag: `null`, `true` und `false`, Felder oder Objekte als Feldwert, leere Zeichenkette als Wert, doppelte Schlüssel.
   7. Zweiter Beleg: `jsonlite::validate()` und `jsonlite::fromJSON()` bestätigen Form und Feldwert jeder erzeugten Eingabe.
5. **(ACC-7) Prüfform K-M3d-3, Aufzeichnungen.**
   1. Wiedergabe mit `acc_m2_replay()` (`setup-m2.R`): Zuordnung über URL und Feld `model`, Fehler ohne passende Aufzeichnung.
   2. `backend_ellmer()` erhält `list(sol =, llama =, qwen =)` aus `ellmer::chat_openai_compatible(base_url = <URL der Aufzeichnung ohne /chat/completions>, model = <request_model>, credentials = function() "acc-test-key", echo = "none")`.
   3. BL-60 ist durch Ausführung geklärt (ellmer 0.5.0, httr2 1.3.0, Probe 06.11.2026): `local_mocked_responses()` fängt die Aufrufe ab; je Aufruf geht eine Anfrage an die aufgezeichnete URL mit dem aufgezeichneten Modell; der Text ist „Uncertain significance“, auch bei Qwen mit Reasoning.
   4. `meta` beider Backends: `model_snapshot` = Feld `model` der Antwort; `provider` = Feld `provider` der Antwort (bei Sol fehlt es, also kein Eintrag); `usage` = Feld `usage` der Antwort, `identical()` mit `jsonlite::fromJSON(simplifyVector = FALSE)` der Aufzeichnung. Bei ellmer liegt der Antwortkörper in `ch$last_turn()@json`.
   5. `msa_run()` mit `backend_ellmer()` schreibt `meta` als JSON in den Speicher; das Chat-Objekt wird über `model_id` gewählt.
6. **(ACC-8) Prüfform K-M3d-3, Fehler.**
   1. Die Mock-Funktion wählt die Fehlerart über eine Marke „fail:\<art\>“ im Prompt, sonst die Aufzeichnung:
      - HTTP 500 und 401, nicht transient (keine Wartezeit durch `req_retry()`);
      - Zeitüberschreitung als Fehler der Klasse `curl_error_operation_timedout` aus der Mock-Funktion;
      - leere Antworten: HTTP 200 mit leerem Körper, mit `message.content` null und mit `message.content` `""` (sonst llama.json).
   2. Plan: ok_first, die sechs Fehlerarten, ok_last; Modell llama; `order = "fixed"`.
   3. Erwartet für beide Backends, im Rückgabewert und im SQLite-Speicher: acht Zeilen, der Lauf endet nicht. Jede Fehlerzeile hat einen nichtleeren Text in `error` und `value` `NA`; die beiden ok-Zeilen haben keinen Fehler und den aufgezeichneten Wert.
   4. Ob das Backend oder `msa_run()` den Fehler meldet, entscheidet der Builder (Form: Nr. 18.2). Antworten nur aus Leerraum sind nicht im Vertrag.
7. **(ACC-9) Prüfform K-M3d-3, ellmer fehlt.**
   1. Teilprozess `Rscript --vanilla`: Ein nicht ladbares Platzhalterpaket „ellmer“ (nur DESCRIPTION) steht zuerst in `.libPaths()`, `requireNamespace("ellmer")` ist `FALSE`. Dann `pkgload::load_all()` des Pakets unter Test (`export_all = FALSE`).
   2. `backend_ellmer(list(m = "not a chat object"))` endet mit einem Fehler. Seine Meldung muss im Klartext von `man/backends.Rd` (Rd2txt, Repository-Wurzel) gleich normalisiert vorkommen: Leerraum zusammengefasst, Anführungszeichen und Backticks entfernt, Kleinschreibung.
8. **(ACC-10) Prüfform K-M3d-4.**
   1. Gerendert mit `rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none")`. Abschnitte über den Titel der Überschrift zweiter Ebene, Nummer frei: Precision, Agreement, Bias, Robustness, Conclusion, je genau einer. Text normalisiert (Markdown-Escapes, `*`, Backticks, typografische Anführungszeichen und Striche).
   2. Die Zeilen der Vorlage seit v0.1.0 behalten ihre Form; neue Inhalte kommen als eigene Zeilen dazu. Gelesene Zeilen:
      - „Total gauge R&R: x % of study variation (y % contribution)“;
      - „Repeatability x %, reproducibility y % of study variation“;
      - „Number of distinct categories (ndc): n; ICC(items) = x“;
      - „Classification: VERDIKT“ und im Abschnitt Conclusion „classifies the pipeline as VERDIKT“;
      - „Cohen's kappa (modal response vs reference) x, (all responses vs reference) y“, „Fleiss' kappa: x“;
      - „Accuracy: x % of responses correct; y % of items correct in every call“;
      - „Mean bias x (L % CI a to b;“;
      - „Lenth PSE x, ME y, SME z“.
   3. Gelesene Tabellen (Kopfzellen): Source, Variance, SD, % Contribution, % Study variation (Zeile je Quelle ohne führende Leerzeichen); statistic, estimate, lower, upper (Bootstrap); scope, alpha; prompt_id, model_id, pct_correct; prompt_id, model_id, bias, lower, upper; factor, effect, t_lenth, active, active_simultaneous.
   4. Jedes Vorkommen muss stimmen. Die gedruckte Zahl trägt genau die Nachkommastellen aus ANK-93 und weicht vom Objektwert höchstens um ½ · 10^−d plus ANK-TOL.arithmetic ab. `NA` wird als „NA“ gedruckt, ndc über `format()` bzw. „Inf“, das Verdikt in Großbuchstaben, Aktivitätskennzeichen als TRUE/FALSE.
   5. Geprüft werden die Familien des Kriteriums, die Bootstrap-Tabelle als Intervalle derselben Kennzahlen. Nicht geprüft: Attribut-Wiederholbarkeit und -Reproduzierbarkeit, Linearität, p-Werte. Fleiss' Kappa (in 332a2d5 nicht vorhanden) mit den Kappa-Stellen (3).
   6. Objekte: numerische Studie (12 Items × 3 Prompts × 3 Modelle × 2 Replikate × 2 Blöcke über `msa_design()`, `msa_run()` und `backend_mock()`, Design-Seed 314159); `msa_boot(nsim = 4, seed = 271828)`; ordinale Studie für `msa_agreement(weights = "linear", fleiss = TRUE)`; `msa_bias()`; `msa_robustness()` auf `pb_design()` mit 8 Läufen, 7 Faktoren und `seed = 161803`.
9. **(ACC-11) Westgard-Verletzungen (K-M3d-4) und R_4s-Lesart (K-M3d-6).**
   1. `msa_report()` erhält das neue letzte Argument `control_chart = NULL`, ein `msa_control_chart`-Objekt (docs/01 §4: neues Argument mit Vorgabewert am Ende ohne ADR).
   2. Mit ihm hat der Bericht einen Abschnitt zweiter Ebene, dessen Titel Westgard, control chart oder system suitability nennt, mit einer Tabelle mit den Kopfzellen Rule, Violations und Positions:
      - je eine Zeile für jede Regel aus `attr(chart, "rules")` (Name wie im Objekt, etwa 1_2s oder R_4s) und eine Zeile reject;
      - Violations ist die Zahl der Punkte, an denen die Spalte der Regel `TRUE` ist;
      - Positions sind deren Werte von `index`, aufsteigend; ganze Zahlen in der Zelle, Trenner frei, ohne Zahl, wenn keine.
   3. Im selben Abschnitt nennt eine Zeile R_4s (auch R4s), die Spannweitenlesart („range“) und aufeinanderfolgende Werte („consecutive“ oder „successive“). Die Lesart „westgard“ ergänzt erst M3c (K-M3c-2).
   4. Ohne `control_chart` darf der Abschnitt „not assessed“ melden. Testkarte: 24 Werte auf der z-Skala (center 0, sd 1), an denen jede Regel mindestens einmal anschlägt.
10. **(ACC-12) Kanonische Form der Lauftabelle (K-M3d-5), Byte für Byte.**
    1. Spalten: block, item_id, prompt_id, model_id, rep, dann jede weitere Spalte von `as.data.frame(runs)` in Bytereihenfolge der Namen (C-Locale). Attribute bleiben außen vor.
    2. Erste Zeile: die Spaltennamen als Text.
    3. Zellen:
       - logisch TRUE/FALSE; integer in Dezimalziffern;
       - double mit `sprintf("%.17g")` (in R: NA als NA, NaN als NaN, Inf als Inf);
       - Faktoren über ihre Stufennamen, jede andere Spalte über `as.character()` als Text;
       - Text in doppelten Anführungszeichen mit verdoppelten inneren Anführungszeichen, UTF-8, eingebettete Zeilenumbrüche unverändert;
       - fehlende Werte NA ohne Anführungszeichen.
    4. Felder durch „,“ getrennt; jede Zeile endet mit LF, auch die letzte.
    5. Zeilen sortiert nach block, item_id, prompt_id, model_id, rep: numerische Spalten nach Wert, alle anderen nach den Bytes des Texts (wie `sort(method = "radix")`), fehlende Werte zuletzt, Gleichstände nach den Bytes der ganzen Zeile.
    6. SHA-256 über die UTF-8-Bytes, 64 Hexadezimalziffern klein. `%.17g` gibt jeder verschiedenen double-Zahl einen verschiedenen Text, auch bei einer Änderung im letzten Bit.
    7. Bericht: eine Zeile, die SHA-256 und die Daten oder die Lauftabelle nennt, mit dem 64-stelligen Hash (etwa „Data hash (SHA-256 of the canonical run table)“ im Abschnitt Traceability). Keine Zeile nennt den Datenhash MD5 (docs/01 §3 Nr. 9).
    8. Testtabellen, Permutationen und die 14 Zelländerungen stehen im Feld `note` von ACC-12.
11. **(ACC-13) Konventionen (K-M3d-6).** Als Nennung zählt, ohne Rücksicht auf Groß- und Kleinschreibung, im normalisierten Text:
    1. ndc-Konstante: eine Zeile im Abschnitt Precision mit „ndc“ oder „distinct categories“ und der Zahl 1.41 (ANK-16).
    2. Verdiktschwellen: Die Zeile „Classification: …“ nennt die Basis („% study variation“ bzw. „% contribution“) und beide Schwellen des Objekts (gleich ANK-16); geprüft für `basis = "study_var"` und `"contribution"`.
    3. %Contribution-Konvention: eine Zeile außerhalb von Tabellen mit „contribution“, „convention“ und den Zahlen 1 und 9 (ANK-16), in beiden Berichten.
    4. Abgeleitete Zwei-Stufen-Komponenten: für ordinale Fits mit zwei Modellen und mit zwei Blöcken (`acc_m1b_ordinal_runs()`, Seeds 41 und 42; `grr$derived` = model bzw. block) eine Zeile im Abschnitt Precision mit dem Namen der Quelle und „range method“ (oder „two-level“, „two fixed levels“).
    5. Modell: eine Zeile mit „interaction“, „block“, „three-way“ (oder 3-way, three-factor, triple) und einer Verneinung (no, not, without, pooled, exclud…, omit…).
    6. R_4s-Lesart: Nr. 9.3.
12. **(ACC-14) Seeds und Modelltabelle (K-M3d-6).**
    1. Seeds: Design-Seed `attr(attr(runs, "design"), "seed")` (`msa_run()`), Bootstrap-Seed aus `msa_boot(seed =)`, Plackett-Burman-Seed aus `pb_design(seed =)`. Für jeden eine Zeile, die „seed“ und die Bezeichnung (design, bootstrap, Plackett-Burman) nennt; die erste ganze Zahl nach der Bezeichnung ist der Seed. Wie die Seeds zum Bericht gelangen: Nr. 14.
    2. Modelltabelle mit den Kopfzellen Model ID, Model, Provider, Quantization; je `model_id` eine Zeile. Model nennt jeden verschiedenen Wert von `meta$model_snapshot`, Provider jeden von `meta$provider`, Quantization jeden von `meta$quantizations` der Zeilen des Modells; ohne Wert „not reported“.
    3. Testlauf: die drei aufgezeichneten Modelle über `msa_run()` mit zwei Items. Eine Llama-Zeile meldet als konstruierten Anbieterwechsel einen zweiten Anbieter „AccTestHost“; Sol hat weder Anbieter noch Quantisierung.
13. **(ACC-1) Anker.**
    1. Neu in `10-acceptance` M3d, vor dem Tag `plan/M3d`: ANK-93, die Rundungsstellen je Kennzahl aus `inst/templates/validation_report.Rmd` im Commit 332a2d5897598685c17efe893e2ad65478ec04eb (Git-Blob 2d5def34bbe15280deb92fb0e37a5b6266c3c536, SHA-256 5c6cea5b…4ddc, 8473 Byte).
       - Die Vorlage wurde ohne Git-Kommando aus den Git-Objekten gelesen (Pack-Index v2, Pack-Einträge mit Deltas, SHA-1 jedes Objekts nachgeprüft). 332a2d5 liegt vor dem ersten von `git filter-repo` umgeschriebenen Commit und behält seine Kennung.
       - 43 Einträge mit Objektfeld, Zeilennummer und wörtlicher Zeile. Varianz und SD 4 Nachkommastellen; % Contribution und % Studienvariation 1; ICC, Kappa und Alpha 3; Trefferquoten 1; Bias, Grenzen und SD 4; Konfidenzniveau in Prozent 0; p-Werte 3 signifikante Stellen; Lenth PSE, ME, SME und Effekte 4; t-Werte 2; Bootstrap 2; ndc ganzzahlig über `format()`, Verdikt über `toupper()`.
       - Die Vorlage vor M3d druckt jede dieser Kennzahlen mit denselben Stellen. Seither hinzugekommen: Fleiss' Kappa (`%.3f`), Linearitätsregressionen, Vertrauensband, t-Quantil. In 332a2d5 fehlen Westgard-Abschnitt und Fleiss' Kappa (Nr. 8.5, Nr. 9).
    2. Unverändert und erneut geprüft: ANK-94 (SHA-256 der drei Aufzeichnungen). Vorhanden: ANK-TOL.resume_cutpoints (50, Seeds 1 bis 50) und ANK-TOL.parser_cases (10.000, Seed 20261024). Wiederverwendet: ANK-16 (1,41; 10/30; 1/9), ANK-54 und ANK-55 (Quantisierung fp16, fp8), ANK-69 (Klassen, Aliase), ANK-TOL.arithmetic.
    3. Dieses ADR ist das ADR im selben Meilenstein für ANK-93 (docs/01 §6). Die Anker liegen vor `plan/M3d`; das Gate golden-adr ist unberührt. Unter `inst/extdata/` ändert sich in M3d nichts.
14. **(P-M3d-01) Seed-Provenienz und die Vergleiche aus M1d und M3b.**
    1. **Lesart.** Der Satz aus docs/02, M1d, Voraussetzung („M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation“) bindet M1d. K-M1d-8 („bleiben unverändert“) und K-M1c-7 („bleiben bytegleich“) binden die Änderungen ihrer Meilensteine. Für M3d gelten docs/01 §4 und K-M3d-6. ADR-051 Nr. 9.3 gilt ab M3d mit der einzigen Ausnahme aus Nr. 14.2.
    2. **Zulässige Attribute.** In M3d kommen genau diese drei Attribute hinzu:
       - `attr(pb_design(), "seed")`: `identical()` mit dem übergebenen `seed`, nur bei `randomize = TRUE` und `seed` nicht `NULL`; sonst kein Attribut.
       - `attr(msa_robustness(), "seed")`: `identical()` mit `attr(design, "seed")`, wenn das Design dieses Attribut trägt; sonst kein Attribut. Keine andere Quelle: kein globaler RNG-Zustand, kein Rückschluss aus Aufrufen.
       - `attr(msa_boot(), "seed")`: `identical()` mit dem übergebenen `seed`, wenn er nicht `NULL` ist; sonst kein Attribut.
       Alle anderen Spalten, Attribute und Werte bleiben identisch mit dem Stand vor M3d. Das gilt auch für `acmg_robustness()`, wo nur `effects` das neue Attribut trägt, und für die Bänder.
    3. **Code.** In M3d ändert sich `R/grr.R` nur in `msa_boot()` um die Zuweisung aus Nr. 14.2 und in roxygen-Zeilen; `R/fit.R` bleibt unverändert. In `R/robustness.R` kommen zu den roxygen-Zeilen nur die Zuweisungen aus Nr. 14.2 hinzu. Das Code-Review prüft das am Diff seit `plan/M3d`.
    4. Kein Schatten-Wrapper in einer anderen Datei, keine versteckte Ablage, kein Register (wie `PLAN.md` Z. 343–344).
    5. **Abnahmetests (Reviewer).** Diese drei Stellen prüfen bisher den Arbeitsbaum gegen done/M1c und werden auf ihren Gegenstand zurückgeführt:
       1. `tests/acceptance/test-m1d-7-findings.R` Z. 139–147 prüft die Regel aus docs/02 M1d an den Codezeilen von `R/fit.R` und `R/grr.R` im Tag done/M1d gegen done/M1c (ANK-34). Beide Stände werden aus den Git-Objekten gelesen wie bei `acc_m1c_baseline_text()`. Der Vergleich des Arbeitsbaums entfällt; für M3d gilt Nr. 14.3.
       2. `test-m1d-8-robustness-wording.R` Z. 83–99: Je Aufruf wird das Attribut `seed` vom neuen Objekt abgenommen und getrennt geprüft: gleich `attr(design, "seed")`, beim einfachen data.frame `NULL`. Der Rest muss mit done/M1c `identical()` sein.
       3. Z. 101–121: ebenso für `effects` von `acmg_robustness()`; `seed` gleich `plan$design$seed`. Der Rest muss mit done/M1c `identical()` sein, die Bänder gleich.
       4. Die Änderung macht der Reviewer im Code-Review M3d, Runde 1 (`50-code-review` darf `tests/acceptance/` schreiben, `orchestrate.sh:522`), oder der Betreiber vorher als Betreiber-Commit. Bis dahin sind genau diese drei Tests rot. Das ist kein Befund gegen den Builder.
       5. Das ist keine Abschwächung (AGENTS.md, Integrität Nr. 1): Der Test prüft weiter den Satz aus docs/02, und zwar an dessen Gegenstand; jedes andere Attribut und jeder Wert bleibt verglichen, das neue Attribut wird zusätzlich geprüft.
    6. **[QA-PENDING]** `tests/e2e/test-m3b-qa-e2e.R`, QA-M3b-E2E-3, Z. 214 und Z. 231 (Prüflauf 1). QA passt in der QA-Phase M3d die Erwartungen an: `seed` gehört bei einem PB-Plan mit `seed` zur Namensmenge; der Vergleich mit dem einfachen data.frame nimmt `seed` ab und prüft es getrennt. Bis dahin bricht der rote unmutierte Vorlauf auch mutgate vor dem ersten Mutanten ab (`config.env:242`, `MUT_TEST_DIRS` mit `tests/e2e`; `MUT_TEST_EXCLUDE` nimmt die Datei nicht aus).
    7. Builder-Tests unter `tests/testthat/`, die solche Objekte mit `identical()` oder einer Namensliste vergleichen, nehmen nur `seed` ab und prüfen es getrennt. Keine andere Erwartung ändert sich.
15. **(P-M3d-02, E7) jsonlite für `parse_json_field()`.**
    1. Bestätigt: Die Fabrik prüft `requireNamespace("jsonlite", quietly = TRUE)` und endet ohne jsonlite mit einer benannten englischen Meldung, die `?parsers` wörtlich nennt (Muster `backend_ellmer()`). Kein stiller Rückfall, kein neuer Import; jsonlite bleibt in Suggests (docs/01 §5).
    2. Der erzeugte Parser endet auf keiner Eingabe mit einem Fehler und gibt keine Warnung aus: `NULL`, Länge 0, `NA` und jede Zeichenkette. Fehler und Warnungen von jsonlite ergeben `NA`.
    3. Das erste Objekt wird mit `jsonlite::parse_json(…, simplifyVector = FALSE)` gelesen, nicht mit `jsonlite::fromJSON()` auf ungeprüftem Text. `fromJSON()` liest eine Zeichenkette, die kein gültiges JSON ist, als URL oder als vorhandene Datei.
    4. Rückgabe: eine Zeichenkette der Länge eins oder `NA_character_`. Eine Zeichenkette wird dekodiert, eine Zahl als `as.character()` des gelesenen Werts zurückgegeben. Für Werte außerhalb des Vertrags (Nr. 4.6) ist `NA` zulässig, nie ein Ergebnis anderer Länge oder Klasse.
16. **(P-M3d-03) Provenienz der Klasse-B-Studien.**
    1. Die historischen `*_session.txt` behalten ihre Implementierungshashes; nichts wird umetikettiert, kein neuer Volllauf.
    2. `boot_implementation()` (`inst/validation/sim/boot_coverage_helpers.R:242–255`) ändert sich mit dem Körper von `msa_boot()`. Kein Test vergleicht den Hash der boot_coverage-Sitzung mit einem Neulauf: K-M1c-8 prüft nur die drei Studien mit `msa_fit` (`test-m1c-8-check-runs.R:15`). K-M1c-4 und K-M1d-6 vergleichen Seeds, RNG, Versionen und Einzelschätzer, die das Seed-Attribut nicht ändert.
    3. Hinweis: `boot_merge()` (Z. 349) verbindet keine Teilläufe mit verschiedener Implementierung, also keine Teile von vor und nach M3d.
17. **(E1) Bericht und Hilfeseiten, die bestehende Tests lesen (bindend).**
    1. Die Abschnitte 1 bis 6 behalten Nummer und Titel, insbesondere:
       - „## 3. Precision …“ (K-M1c-7: Überschrift „3.“, `setup-m1c.R:682–689`);
       - „## 5. Bias and linearity“ (K-M3a-6: „5. Bias“, `test-m3a-6-linearity.R:208`);
       - „## 6. Robustness“ (K-M1d-8: „6. Robustness“, `setup-m1d.R:809`).
       Je genau ein Titel zweiter Ebene beginnt mit Precision, Agreement, Bias, Robustness und Conclusion (Nr. 8.1). Neue Abschnitte zweiter Ebene stehen hinter Abschnitt 6; ihre Titel beginnen mit keinem dieser Wörter. Genau ein Titel nennt Westgard, control chart oder system suitability.
    2. In den Abschnitten 3, 5 und 6 kommt keine neue Überschrift irgendeiner Ebene hinzu; die genannten Tests schneiden den Abschnitt an der nächsten Überschrift jeder Ebene ab.
    3. Abschnitt 3: Genau eine Zeile außerhalb von Überschriften nennt repeatability und reproducibility zusammen (`setup-m1c.R:694–697`). Bei ordinalen und binären Fits folgt ihr als nächste Zeile der Hinweis aus K-M1c-7 (QA-M1c-E2E-2, `tests/e2e/test-m1c-qa-e2e.R:120–122`: `lines[idx_rep + 1L]`). Neue Zeilen in Abschnitt 3 (ndc-Konstante, abgeleitete Komponenten, Konventionen) stehen hinter den bestehenden Listenzeilen und nennen nicht beide Wörter.
    4. Die Zeilen und Tabellen aus Nr. 8.2 und 8.3 behalten ihre Form. In „Number of distinct categories (ndc): n; ICC(items) = x“ wird nichts eingefügt. Die bestehende Zeile „Classification: …“ nennt Basis und Schwellen bereits (Nr. 11.2).
    5. Unverändert bleiben die Texte, die die QA-Tests von M1c, M1d, M3a und M3b lesen: Robustheitssätze und Zusätze, „Lenth PSE %.4f, ME %s, SME %.4f“, „lowest tied category in scale order“, „acmg_modal()“, „n_units_excluded“, „Handbook linearity verdict: \*\*…\*\*“, „regression on unweighted item means“, „df = …“ (`test-m1d-qa-e2e.R:307–312`, `test-m3b-qa-e2e.R:273–276`, `test-m3a-qa-e2e.R:321–328`).
    6. Hilfeseiten: In `man/msa_boot.Rd`, `man/msa_robustness.Rd` und `man/backends.Rd` kommt nur Text hinzu. Was K-M1c-3, K-M1d-7 (Befunde, Szenarien, Verweis auf die Vignette), K-M3b-5 („conservative“, „nominal“, kein „at the 5 % level per effect“) und K-M3d-3 lesen, bleibt stehen.
18. **(E2 bis E6, E8) Weitere Festlegungen.**
    1. **(E2) Bedingungen.** `msa_run()` speichert als Backendfehler nur Bedingungen der Klasse `error`. Jede andere Bedingung aus dem Backend verlässt `msa_run()` ohne Zeile und unverändert: `interrupt`, ebenso `acmg_network_abort` (`R/acmg.R:802–803`: „Not an error: msa_run() would store an error as a row.“). Kein `tryCatch(condition = )`, kein Umdeuten. Fehler beim Schreiben des Speichers sind keine Backendfehler.
    2. **(E3) Leere Antworten.** Leer ist ein Antworttext, der `NULL`, Länge 0, `NA` oder `""` ist. Daraus wird eine Fehlerzeile mit nichtleerer englischer Meldung, die die Art nennt (etwa „empty response: message content is null“); `value` ist `NA`; `meta` bleibt erhalten; der Parser wirkt nicht. Text nur aus Leerraum bleibt eine nicht parsbare Antwort (Nr. 6.4).
    3. **(E4) CSV-Leser.** `read_store()` liest eine CSV-Datei mit `colClasses`: `block`, `position` und `rep` als integer, `latency_s` als double, jede andere Spalte als Text, auch unbekannte.
    4. **(E5) Mock.**
       - Der Zeilenstrom von `backend_mock()` entsteht aus einer stellenabhängigen Mischung des Seeds und der längenmarkierten UTF-8-Teile von `block`, `item_id`, `prompt_id`, `model_id` und `rep`, mit begrenzter Ganzzahlarithmetik und ohne Aufrufzähler.
       - Zeilen mit gleicher Summe der Codepunkte erhalten verschiedene Ströme, etwa die Items „001“ und „010“.
       - Vorgabewerte für fehlendes `block` und `rep` sind dokumentiert.
       - Bestehende Tests mit festen Mock-Werten erhalten ihre Erwartung aus der dokumentierten Regel, nicht aus der neuen Ausgabe.
    5. **(E6) Formate.**
       - Seeds werden als ganze Zahl ohne Exponent und ohne Tausendertrenner gedruckt (etwa `format(x, scientific = FALSE, trim = TRUE)`), ohne Wert „not reported“. Die Bezeichnung steht unmittelbar vor der Zahl, etwa „Bootstrap seed: 271828“.
       - Schwellen und Konstanten werden mit `format()` bzw. `%g` gedruckt wie in der Zeile „Classification“: 1.41, 10, 30, 1, 9; nicht 1.0, 9.0 oder 1,41.
    6. **(E8) Fehlende Angaben.** `msa_report()` rendert auch für `runs` ohne Spalte `meta`, ohne Attribut `design`, mit `NA` in `meta` und mit `meta`, das kein JSON ist (Rückfall von `meta_to_json()` ohne jsonlite, `R/run.R:125–126`). Die Modelltabelle meldet dann „not reported“ oder nennt die unlesbaren Metadaten; der Datenhash wird berechnet. Hash, Seeds, Modelltabelle und Westgard-Tabelle werden in `R/` berechnet und als im YAML-Kopf erklärte Parameter übergeben; die Vorlage formatiert nur.
19. **Hinweise (keine neue Regel).**
    1. **Mutationsumfang.** mutgate mutiert jede seit `plan/M3d` geänderte Datei unter `R/` ganz (`86-mutgate.sh:22`, `MUT_SCOPE_REGEX='^R/.*\.R$'`). Mit Nr. 14.3 sind das auch ganz `R/grr.R` und `R/robustness.R`. Die Tests `m1d-…` sind dort ausgenommen (`config.env:267`). Über das Bestehen entscheidet allein das Gate; kein Ausweichen in andere Dateien (Nr. 14.4).
    2. **AP1.** Leere Antworten werden in M3d zu Fehlerzeilen (K-M3d-3). `acmg_pilot()` zählt Fehlerzeilen im Anteil `backend_errors` und nimmt sie aus Kostenquantil und Anbieterprüfung (`R/acmg.R:509–560`; ADR-014). Stores von vor M3d werden nicht umklassifiziert. Ob AP1 nach M3d mit neuen Läufen weiterläuft und wie gemischte Stores ausgewertet werden, entscheidet der Betreiber.
    3. **Backlog.** BL-60 ist durch ACC-7 beantwortet, BL-17 und BL-18 gehen in K-M3d-3 und K-M3d-5 auf, BL-130 gehört nicht zu M3d (ACC-15). Die Einträge pflegt der Reviewer im Code-Review.
    4. **Laufzeit.** Die M3d-Abnahmetests laufen je Mutant (ACC-15). Ob das so bleibt, entscheidet der Betreiber.

## Konsequenzen

- `PLAN.md` Runde 1 ist mit diesen Festlegungen freigegeben (PLAN-REVIEW M3d, Runde 1: PASS). BUILD baut die Seed-Attribute aus Nr. 14.2 in Runde 1.
- Die minor-Befunde E1 bis E8 sind Umsetzungshinweise, gebunden über Nr. 17 und 18. E9 ist [QA-PENDING], E10 eine Aufgabe des Reviewers.
- Bis zur Rückführung nach Nr. 14.5 sind test-m1d-7 (Z. 139–147) und test-m1d-8 (Z. 83–121) rot. Bis QA Nr. 14.6 umsetzt, ist QA-M3b-E2E-3 rot und mit ihm mutgate. Beides ist kein Befund gegen den Builder.
- Das Code-Review M3d prüft gegen Nr. 1 bis 18.
- Die Messwerte im Kontext sind Proben des Reviewers auf einer Paketkopie, weder Ergebnisse des Builders noch Referenzwerte für Tests.
