# PLAN-REVIEW — M1d, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 04.11.2026 · Gegenstand: `orchestrator/handoff/M1d/PLAN.md` (Runde 1, 385 Zeilen). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md`. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS.** Es gibt keinen blocking-Befund.

- **Spec-Treue:**
  - Der Plan deckt K-M1d-1 bis K-M1d-8 vollständig ab und übernimmt alle Auslegungen ACC-1 bis ACC-12 (PLAN Z. 164–180).
  - Keine Stelle widerspricht docs/02 M1d, docs/01 §2, §5 bis §8, ADR-045, ADR-047 oder den Abnahmetests.
  - Das Gebot „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ ist eingehalten (PLAN Z. 9, 51).
- **Nachgeprüft (Prüfläufe A bis C):**
  - Die Befundtabelle des Plans (Z. 139–148) gleicht der Befundmenge, die der Abnahmetest aus den vier Vollläufen bildet: 19 Befunde.
  - Alle 428 zu tabellierenden Zellen sind endlich.
  - Die geforderten Fits laufen auf den Mini-Referenzen der echten Daten: ordinal mit Probit, binär je Aufgabe.
  - `msa_agreement()` gleicht der Alpha-Referenz des Tests.
  - Der Ausgangsstand mit den Vollläufen ist grün: 283 Unit-Tests und die 26 Vignetten-Abnahmetests aus M1a bis M1c.
- **Einwände:** 15 minor-Befunde, E1 bis E15. E1 ist [INFRA] für den Betreiber. BUILD berücksichtigt die übrigen; keiner hält den Plan auf.
- **Neu in dieser Phase:**
  - `docs/decisions/ADR-048-m1d-reviewer-auslegungen.md`: hält ACC-1 bis ACC-12 und die Anker aus ACC-15 fest und bestätigt sieben Festlegungen des Plans (Nr. 14).
  - In `CRITERIA.json` verweisen die Statuszeilen von ACC-1 bis ACC-12, ACC-15 und ACC-17 auf ADR-048. ACC-13 und ACC-14 stehen auf „umgesetzt“ bzw. „erledigt“, ACC-20 nennt die Antwort des Plans. Kriterien und alle übrigen Felder sind unverändert.

### An den Betreiber

1. **M1D-INFRA-01 (E1, ADR-048 Nr. 15).** `_pkgdown.yml` ist für den Builder gesperrt, K-M1d-5 verlangt die Listung.
   - Vor `40-build` und außerhalb einer Modellphase (etwa nach `orchestrator/STOP` am Ende dieser Phase) den Abschnitt `articles` ergänzen und committen.
   - Der Abschnitt nennt auch `validation`, sonst bricht `pkgdown::build_site()` ab (pkgdown 2.2.1). YAML in E1.
   - Fehlt der Eintrag bei den Gates, ist K-M1d-5 in der Listung rot, ohne Builder-Befund.
2. **ACC-13** ist umgesetzt: `orchestrator/config.env:267` endet auf `|m1d-)`. ADR-047 Nr. 1 steht in `config.env:276` (`MUT_SCOPE_REGEX='^ADR-047-kein-Treffer$'`).
3. **ACC-14** ist erledigt: Alle zwölf Vollauf-Dateien liegen unter `inst/validation/sim/` (BL-12, 04.11.2026). Die Prüfläufe A und C lesen sie.

### Ablauf

Mit PASS gibt der Orchestrator den Plan frei, setzt den Tag `plan/M1d` und startet BUILD.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/02 M1d vollständig (Voraussetzung, Abbildungen, K-M1d-1 bis K-M1d-8), dazu K-M1b-2, K-M1b-4, K-M1c-3, K-M1c-7 und K-M1c-8; docs/01 vollständig.
- **Handoff M1d:** `CRITERIA.json` (acht Kriterien, ACC-1 bis ACC-20), `PLAN.md` vollständig. Zum Format: `PLAN-REVIEW.md` und `verdict-plan.json` aus M1c.
- **ADRs:** ADR-035, ADR-040, ADR-042 (Format), ADR-043, ADR-044, ADR-045, ADR-046, ADR-047.
- **Abnahmetests:** `setup-acceptance.R`, `setup-m1d.R` vollständig, `test-m1d-1` bis `test-m1d-8` vollständig, `test-m1b-7-vignette-full-results.R`, `test-m1c-5-vignette-full-results.R`; aus `setup-m1b.R` Z. 160–294 und 560–616, aus `setup-m1c.R` Z. 301–306 und 719–733.
- **Anker:** ANK-06, ANK-34, ANK-40, ANK-41, ANK-42 bis ANK-47, ANK-TOL (`data_size`, `bias_report`, `mc_factor`, `n_check`, `package_compare`).
- **Produktcode und Validierung:**
  - `R/agreement.R` Z. 30–190, `R/run.R` Z. 160–222, `R/fit.R` Z. 296–365 und die Fehlerstellen, `R/robustness.R` Z. 120–184, `inst/templates/validation_report.Rmd` Z. 150–166;
  - `inst/validation/sim/simulation_helpers.R` Z. 195–234, `inst/validation/sim/boot_coverage_helpers.R` Z. 236–266, `data-raw/make_items_ap1.R` (Fehlerpfade);
  - `tests/testthat/helper-validation-latent.R`, `tests/testthat/test-validation-latent.R` Z. 1–60 und 115–156;
  - Kopfzeilen der Vollauf-Dateien, `DESCRIPTION`, `_pkgdown.yml`, `.Rbuildignore`.
- **Harness:** `orchestrate.sh` (`path_allowed` Z. 515–544, `verdict()` Z. 734–756), `gates.d/87-golden-adr.sh`, `lib/r-tests.R`, `config.env` Z. 149–276, `BACKLOG.md` (BL-03, BL-04, BL-12, BL-13, BL-46, BL-87, BL-92, BL-94, BL-110, BL-111, BL-113 bis BL-116).

## Eigene Prüfläufe

Alle als R-Skripte unter `orchestrator/handoff/M1d/.probe-plan-review/` (danach gelöscht). R 4.6.1, `pkgload::load_all()` des Arbeitsbaums nach `3165a19`, Abnahmehelfer aus `tests/acceptance/setup-*.R`. Nichts unter `R/`, `inst/`, `vignettes/`, `man/` oder `tests/` geschrieben; geprüft mit `find -newer STATUS.md`. Die vier Dateien aus ANK-34 tragen dessen SHA-256.

### Prüflauf A — Befunde, Tabellenzellen, Alpha

- **Befundmenge:** `acc_m1d_findings()` aus den vier Vollauf-Ergebnisdateien (`n_sim` = 1000) ergibt 19 Befunde. Sie gleichen der Tabelle in PLAN Z. 141–146.

  | Studie | Szenario | Schätzziel | Richtung | Wert | MCSE |
  | --- | --- | --- | --- | --- | --- |
  | ordinal_recovery | S-ord-1 | prompt, model | under | rel_bias −0,152; −0,202 | 0,026; 0,025 |
  | ordinal_recovery | S-ord-2 | model | under | −0,187 | 0,026 |
  | ordinal_recovery | S-ord-3 | prompt, model | under | −0,109; −0,171 | 0,029; 0,025 |
  | ordinal_recovery | S-ord-4 | prompt, model | under | −0,199; −0,234 | 0,024; 0,024 |
  | binary_recovery | S-bin-1 | prompt, model | under | −0,214; −0,224 | 0,027; 0,025 |
  | binary_recovery | S-bin-2 | model | under | −0,204 | 0,025 |
  | two_level | S-two-1, S-two-2 | model | none | bias −0,00035; −0,0017 | 0,0023; 0,0116 |
  | boot_coverage | S-boot-1 bis S-boot-7 | ndc | over | coverage 0,998; 1; 0,991; 0,996; 1; 1; 1 | 0,0014; 0; 0,0030; 0,0020; 0; 0; 0 |

  - Unterhalb der Schwelle bleiben S-ord-2 prompt (−0,070), S-bin-2 prompt (−0,077) und S-ord-4 block (+0,0995 bei MCSE 0,045).
  - Bei boot_coverage haben `grr_pct_study_var`, `grr_pct_contribution` und `icc_items` je Szenario dieselbe Überdeckung (0,928 bis 0,953, |z| ≤ 2,7).
- **Tabellenzellen nach ACC-10 (1):** 75, 30, 30 und 293 Zellen je Studie, keine fehlt, alle mit endlichem Wert und MCSE.
- **Alpha:** `msa_agreement()` gegen `acc_m1d_kripp()` auf 20 synthetischen Datensätzen (300 Einheiten, eine bis sechs Einreichungen, 40 Einreicher), nominal und ordinal: größte Abweichung 2,2e-16. `R/agreement.R` braucht keine Änderung.
- **Zählung:** `msa_counts()` zählt in `n` alle Zeilen, fehlende Werte eingeschlossen. Das trägt ACC-3.

### Prüflauf B — Pflichtfits und Rohdaten

- **llm-stability:**
  - Die Rohläufe der 40 Ordner aus ANK-40 (82.850 Zeilen) sind in 8,6 s gelesen.
  - Einfacher Parser des Reviewers: genau ein Etikett „(X)“ aus den Optionen, bei navigate genau eines der Wörter Yes oder No. Damit fehlen je Aufgabe 1,9 % (navigate, 237 von 12.500) bis 33,8 % (college_mathematics, 1.692 von 5.000) der Antworten.
  - `msa_fit(type = "binary")` mit Vorgaben je Aufgabe: alle acht Fits in 0,2 bis 1,6 s, jeweils mit der Warnung „N missing response(s) were dropped.“
  - In high_school_european_history und public_relations ist die Item-Komponente auf der Probit-Skala groß (≈ 44 und ≈ 42); die Likelihood ist dort flach.
  - Text-Schlüssel ruin_names rubric_id 99 und 144 (ANK-40): Die Frage zerlegt die Optionen an Kommas. In Lauf 0 wählen bei Item 99 drei Modelle „(I) dearth“ (Schlüssel „dearth, wind, & fire“), mixtral-8x7b nennt „(A)“ und „(I)“. Bei Item 144 wählen alle fünf „(D) sue and bob poo“ (Schlüssel „rita, sue and bob poo“).
- **ClinVar (Mini-Referenz `acc_m1d_clinvar_reference()`, 115 s):**
  - HRF 1.383 Varianten mit 6.647 Einreichungen, Stichprobe 1.000 mit 5.010, Ausschlüsse 501 und 43.886. Das gleicht ACC-6 (5), (6) und (8).
  - Einreicher: HRF 129, Stichprobe 266. Zweite und weitere SCV desselben Einreichers zur selben Variante: 611 und 108 Zeilen.
  - `gene` ist nie fehlend oder „-“.
  - Submitter-Namen: mit Komma 4.294 und 3.130 Zeilen, mit Anführungszeichen 3 Zeilen (HRF), mit Nicht-ASCII-Zeichen 46 und 38.
  - `DateLastEvaluated`: nur „Mon DD, YYYY“ (6.202 und 4.628) oder „-“ (445 und 382).
  - `review_status`:
    - „criteria provided, single submitter“: 5.958 und 4.479;
    - „no assertion criteria provided“: 675 und 488;
    - „flagged submission“: 14 und 6;
    - „reviewed by expert panel“: 0 und 37.
  - Ordinaler Fit mit Probit (Vorgabe): beide Teilmengen ohne Warnung, 3,6 s und 3,5 s.
  - Mit Logit endet der Fit auf beiden mit dem Fehler „optimizer nlminb failed to converge“.
  - `msa_agreement()` braucht je Teilmenge und Metrik 0,1 s.

### Prüflauf C — Ausgangsstand mit den Vollläufen

- `testthat::test_dir("tests/testthat", load_package = "source")`, `NOT_CRAN=true`, `max_fails = Inf`: 283 Tests, 0 Fehlschläge, 0 Fehler, 1 übersprungen (ellmer), 141 s.
  - Darin `test-validation-latent.R:123–156`: Literalprüfung aller Dateien, die `validation.Rmd` lädt, gegen die Werte der jetzt vorhandenen Vollläufe.
- `tests/acceptance` mit `filter = "m1a-7-vignette|m1b-7-vignette|m1c-5-vignette"`: 26 Tests, 0 Fehlschläge, 0 Fehler, 65 s.
- Die Vollläufe brechen also keinen abgenommenen Vertrag. Der Builder beginnt auf grünem Stand.
- Weitere Messungen:
  - `pkgdown:::data_articles_index` (pkgdown 2.2.1) bricht mit „vignette(s) missing from index“ ab, sobald `articles` gesetzt ist und eine Vignette außer der Einstiegsvignette fehlt (E1).
  - `inst/extdata/` umfasst heute 250.931 Byte (Grenze 5.000.000).

## Antworten auf die Einwand-IDs

- **Runde 1:** Es gibt keine früheren Einwände.
- **ACC-1 bis ACC-12:** übernommen (PLAN Z. 166–173). Inhaltlich geprüft:
  - Auswahl und Zero-shot-Ordner (Z. 82);
  - Spalten, Gitter, Parser, `correct` (Z. 84–86);
  - Import (Z. 90);
  - Manifest und Neuerzeugung (Z. 88, 119);
  - Wiederholbarkeit, Trefferquote, Fits (Z. 92);
  - ClinVar-Reihenfolge, Gen, Stichprobe, Datum, Zählungen (Z. 98–104);
  - Alpha, Anteile, Fit, Sensitivität, Literatur (Z. 108–113);
  - Größe, Netz (Z. 119–123);
  - Neulauf (Z. 127);
  - Befundregeln (Z. 133–137);
  - Wortlaut und Unverändertheit (Z. 156–162);
  - roxygen-only (Z. 51).
- **ACC-13:** an den Betreiber verwiesen; umgesetzt (oben Nr. 2).
- **ACC-14:** zu Recht als überholt beantwortet (oben Nr. 3).
- **ACC-15:** Die Anker nutzt der Plan unverändert, das Reviewer-ADR ist ADR-048. Der Plan sieht ein Builder-ADR für `inst/extdata/` vor (Z. 57); das deckt das Gate golden-adr.
- **ACC-16:** zu Recht als historischer Stand behandelt.
- **ACC-17:**
  - BL-92 wird umgesetzt (Z. 150–152, 306).
  - BL-113 ist mit Grund vertagt (Z. 115, 327): kein Kappa in den Vignetten. Das ist zulässig, K-M1d-4 verlangt Alpha.
- **ACC-18 und ACC-19:** im Literaturvergleich aufgenommen (Z. 113).
- **ACC-20:** Die Rohdaten sind aus der Builder-Sandbox lesbar (Z. 17), Prüflauf B liest sie ebenfalls. Es ist kein Betreiberlauf nötig.
- **BACKLOG:** Alle 116 Einträge sind zugeordnet (Z. 213–330). Stichproben gegen den Text: BL-03, BL-04, BL-12, BL-92, BL-94, BL-110, BL-113, BL-114, BL-115, BL-116. Jede Vertagung nennt Grund und Zuständigkeit (AGENTS.md, Handoff-Disziplin).

## Einwände (Runde 1)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“); ACC-8 (5); `orchestrator/config.env:200` (`BUILDER_EXTRA_PATHS_REGEX`); `orchestrator/orchestrate.sh:515–544` (`path_allowed`) — **Befund:** M1D-INFRA-01 (PLAN Z. 64–74) trifft zu.
  - `_pkgdown.yml` ist in keinem Builder-Pfad; der Builder darf den Eintrag nicht schreiben.
  - Das vorgeschlagene YAML nennt aber nur `llm-stability` und `clinvar-raters`. pkgdown 2.2.1 bricht bei gesetztem `articles` ab, wenn eine Vignette fehlt (`data_articles_index`); nur die Einstiegsvignette `llmsa` ist ausgenommen. `validation` fehlte, `pkgdown::build_site()` bräche ab. Das ist kein Gate, betrifft aber Site und Release (BL-30).

  — **Vorschlag (Betreiber, vor `40-build`, außerhalb einer Modellphase):** bestehende Schlüssel unverändert lassen und ergänzen:

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

  Für den Builder nicht blockierend; der Code-Review führt einen fehlenden Eintrag als [INFRA].
- [E2] (minor) ACC-2 (3) („fehlend, wenn keine oder keine eindeutige Antwort gefunden wird“), ACC-2 (5); docs/01 §5 („Fehlende oder nicht parsbare Antworten bleiben fehlend und werden gezählt, nie ersetzt.“) — **Befund:** Der Plan legt die Etikettenregel nicht fest (Z. 86, 198).
  - Die Rohantworten enthalten Großbuchstaben als englische Wörter, etwa „A clever question!“ vor „(I) dearth“. Eine Regel, die nackte Buchstaben annimmt, erzeugt falsche Etiketten oder Scheinmehrdeutigkeit.
  - Der Abnahmetest prüft nur notwendige Bedingungen; eine solche Regel bestünde ihn.
  - Die Regel bestimmt Wiederholbarkeit und Trefferquote stark: Schon der einfache Parser aus Prüflauf B lässt bis zu 34 % der Aufrufe einer Aufgabe ohne Antwort.

  — **Vorschlag:**
  1. Die Muster abschließend im Builder-ADR und in `QUELLE.txt` festlegen: welche Schreibweisen von „(X)“, welche ausdrücklichen Antwortformeln, Yes/No als Wort.
  2. Fehlende Antworten nach Grund zählen: leer, kein Etikett, mehrdeutig (ADR-048 Nr. 14.1).
  3. Unit-Tests mit synthetischen Antworten in den beobachteten Formen (Artikel „A“, Pronomen „I“, mehrere Etiketten, Etikett in Zitat); kein Rohtext im Repo.
  4. Die Vignette nennt den Anteil fehlender Antworten je Aufgabe und Modell.
- [E3] (minor) ACC-2 (4) („correct = TRUE bei answer gleich gt“); ANK-40, `observations` (ruin_names rubric_id 99 und 144); docs/01 §2 Nr. 4 („nie stillschweigend eine falsche Zahl“) — **Befund:** Bei den zwei Text-Schlüsseln ist jede Etikett-Antwort nach der Regel FALSE, auch die richtige (Prüflauf B: „(I) dearth“, „(D) sue and bob poo“).
  - Der Plan zählt „abweichende Schlüssel-/Optionsformate“ (Z. 86), nennt die Wirkung auf die Trefferquote aber nicht.

  — **Vorschlag:** Regel und Daten unverändert lassen, keine Reparatur über den Schlüssel. `QUELLE.txt` und die Vignette nennen beide Items und dass sie in der Trefferquote von ruin_names nur als Fehltreffer zählen können (ADR-048 Nr. 14.2).
- [E4] (minor) ACC-4 (2) („Die Ausgabe darf nicht von der Locale abhängen“); ACC-6 (2), (7), (9); `tests/acceptance/setup-m1d.R:41–47` (Leser `read.csv`, `quote = "\""`, UTF-8) — **Befund:** Der Plan legt Typen, NA, Reihenfolge, Zeilenenden und gzip fest (Z. 119), nicht aber Quoting und Kodierung.
  - Die Submitter-Namen enthalten Kommas, doppelte Anführungszeichen und Nicht-ASCII-Zeichen (Prüflauf B).
  - Alle Rohdaten haben „Mon DD, YYYY“ oder „-“; der Plan will eine „englische Monats-Locale explizit“ (Z. 104).

  — **Vorschlag:**
  1. Felder in Anführungszeichen, innere verdoppelt (`write.csv`, `qmethod = "double"`).
  2. UTF-8 beim Lesen und Schreiben ausdrücklich, unabhängig von `LC_CTYPE`.
  3. Sortieren mit `method = "radix"`, Zeilenende `"\n"`, gzip über `gzfile()`.
  4. Datumsumwandlung unter `LC_TIME = "C"` statt einer benannten englischen Locale, die im Gate fehlen kann. Das Rohformat zu behalten ist nach ACC-6 (7) ebenfalls zulässig.
- [E5] (minor) ACC-4 (2); `tests/acceptance/setup-m1d.R:222–241` (`acc_m1d_run_data_raw()`); docs/01 §7 („Fehlt der Rohdatenordner, bricht das Skript benannt ab.“) — **Befund:** Im Test laufen beide Skripte als bloßes `Rscript` in einer Paketkopie ohne geladenes llmsa; Arbeitsverzeichnis und `REPO_ROOT` sind die Kopie. Der Plan sagt nicht, wie die Skripte `inst/validation/m1d/prepare.R` und die Anker finden.

  — **Vorschlag:**
  - Helfer mit `sys.source(file.path(<Paketwurzel>, "inst", "validation", "m1d", "prepare.R"), …)` laden, wie `data-raw/make_items_ap1.R:18` die Dateien aus `R/`.
  - Kein `library(llmsa)`, kein `system.file(package = "llmsa")`; Anker aus `reference/anchors/`.
  - Die Meldung ohne Rohdaten nennt „quellen“ (Vorbild `make_items_ap1.R:7`).
- [E6] (minor) K-M1d-1, K-M1d-3, K-M1d-5; ACC-8 (2), (3); `tests/acceptance/test-m1d-1-llm-stability-data.R:28–35`, `test-m1d-3-clinvar-data.R:32–44, 80–87`, `test-m1d-5-size-licence-network.R:37–54` — **Befund:** Für llm-stability nennt der Plan den Inhalt von `QUELLE.txt` einzeln (Z. 88), für ClinVar nur über ACC-6 und ACC-8.

  — **Vorschlag:** Die Tests verlangen folgende Inhalte; BUILD prüft sie als Liste.
  - ClinVar:
    - Stand `2026-10-19` (ANK-41), „public domain“, `ftp.ncbi.nlm.nih.gov/pub/clinvar`;
    - SHA-256 oder md5 beider Rohdateien;
    - `data-raw/make_clinvar_subsets.R`;
    - die fünf Klassen wörtlich, die vier Gene, Seed 20261024 und Umfang 1000 aus ANK-47, `variant_summary`;
    - die Zählungen 501 und 43.886, die das Skript selbst berechnet.
  - llm-stability:
    - Commit und Repository-URL aus ANK-40, „Apache“ und „2.0“;
    - `data-raw/make_llm_stability.R`;
    - `experiments/v3/runs.tgz`, `stability_eval.csv`, `top_p_k`, „zero-shot“.
- [E7] (minor) ACC-5 (5), ACC-7 (4), (7); `tests/acceptance/test-m1d-2-llm-stability-vignette.R:14–18, 75–91`, `test-m1d-4-clinvar-vignette.R:18–24, 97–113` — **Befund:** Die Tests vergleichen die gezeigten Komponenten und %GRR mit ihrem eigenen `msa_fit()`-Aufruf auf eine Einheit der letzten gezeigten Stelle.
  - Der Plan zeigt „bevorzugt sechs“ signifikante Stellen (Z. 92). Weicht der Aufbau der Daten ab (Zeilenreihenfolge, Kodierung von Item und Prompt), können sich die Fits in den hinteren Stellen unterscheiden, gerade wo die Likelihood flach ist (Prüflauf B: Item-Komponente ≈ 44).
  - Weitere Lesart der Tests:
    - Komponenten, %GRR und Alpha werden nur auf Skala 1 gesucht (%GRR als Prozentzahl wie in `msa_grr()`, nicht als Anteil); Anteile und Quoten auf Skala 1 oder 100.
    - In `llm-stability.Rmd` zählen nur Tabellen (Pipe oder HTML), nicht die Druckausgabe; in `clinvar-raters.Rmd` das ganze Dokument.

  — **Vorschlag:** `msa_runs` genau wie die Testabbildung bauen:
  - Zeilen in der Reihenfolge der Datei;
  - `item_id` als Zeichen, eine konstante Prompt-Stufe, `model_id`, `rep = run`, `value = as.integer(correct)` bzw. `classification`.
  - Für ClinVar `prompt_id = submitter_id`, `model_id` konstant, `rep = 1L`.
  - Dazu höchstens vier signifikante Stellen; mindestens zwei sind verlangt.
- [E8] (minor) ACC-10 (1) („mindestens zwei signifikante Stellen“); docs/01 §8 — **Befund:** Die Werte in `validation.Rmd` reichen über Größenordnungen; Zahlen mit festen Dezimalen verlieren dort Stellen.
  - Beispiele: bias −0,00035 mit MCSE 0,0023 in S-two-1, coverage 1 mit MCSE 0 bei ndc.
  - `knitr::kable(digits = )` rundet auf Dezimalstellen, nicht auf signifikante Stellen.
  - Die drei Intervall-Schätzziele außer ndc haben je Szenario dieselbe Überdeckung (Prüflauf A).

  — **Vorschlag:**
  - Wert und MCSE mit signifikanten Stellen formatieren (etwa `signif()` oder der vorhandene Darstellungshelfer); MCSE 0 als 0 zeigen.
  - Ein Satz erklärt die gleiche Überdeckung: Perzentilintervalle folgen monotonen Umformungen derselben Bootstrap-Verteilung.
  - Ein Satz ordnet die ndc-Überdeckung ein: ndc ist ganzzahlig.
- [E9] (minor) ACC-10 (3), (4); `tests/acceptance/setup-m1d.R:669–673` (`acc_m1d_has_id()`, `acc_m1d_has_estimand()`), `test-m1d-7-findings.R:100–137` — **Befund:** Der Test sucht jede Szenario-ID einzeln und das Schätzziel als ganzes Wort.
  - „S-boot-1 to S-boot-7“ nennt S-boot-2 bis S-boot-6 nicht.
  - `item:model` ist ein anderes Schätzziel als `model`.
  - Der Plan sagt nur „nennt die betreffenden Szenarien“ (Z. 148).

  — **Vorschlag:** Jede ID ausschreiben, in einer Tabellenzeile oder einem Satz je Befund mit Schätzziel und Richtungswort.
  - `?msa_fit`: S-ord-1 bis S-ord-4, S-bin-1, S-bin-2, S-two-1, S-two-2 einzeln, „underestimation“ und `vignette("validation")`.
  - `?msa_boot`: S-boot-1 bis S-boot-7 einzeln, „overcoverage“ oder „above nominal“ und `vignette("validation")`.
  - Die Liste aus den Befunden zur Laufzeit erzeugen, die Rd-Texte nach der Befundmenge aus Prüflauf A schreiben.
- [E10] (minor) `tests/testthat/test-validation-latent.R:123–156`; `tests/testthat/helper-validation-latent.R:51–111`; ADR-043 — **Befund:** Der Unit-Test verfolgt jeden `source()`- und `sys.source()`-Aufruf aus `validation.Rmd` rekursiv.
  - Er akzeptiert nur einen wörtlichen Pfad oder `system.file()` mit wörtlichen Argumenten; sonst bricht er mit „Unresolved documentation dependency“ ab.
  - Alle erreichten Dateien prüft er auf Dezimalliterale mit mindestens drei signifikanten Stellen, die einem Vollauf-Wert oder einem latenten Anker gleichen. Seit den Vollläufen sind das deren Werte (Ausgangsstand grün, Prüflauf C).
  - Der Plan sieht `inst/validation/m1d/findings.R` als neuen Helfer der Vignette vor (Z. 45).

  — **Vorschlag:**
  - Laden als `sys.source(system.file("validation", "m1d", "findings.R", package = "llmsa", mustWork = TRUE), envir = …)`.
  - Im Helfer keine solchen Literale; Schwellen aus den Ankerkopien.
  - Keine Funktionsnamen mit `sim_` oder `boot_`, damit nichts in die Implementierungshashes gerät (`simulation_helpers.R:209–218`, `boot_coverage_helpers.R:242–255`; ADR-048 Nr. 14.5).
- [E11] (minor) ACC-9; BL-94; ADR-043; `tests/acceptance/test-m1b-7-vignette-full-results.R:47–49`, `test-m1c-5-vignette-full-results.R:54–56` — **Befund:** In den Attrappen-Kopien der M1b- und M1c-Verträge überschreibt `file.copy()` nicht.
  - Neben der Attrappe `<studie>_results.csv` (n_sim 1234) liegen dort seit den Vollläufen deren echte Replikat- und Session-Dateien.
  - Der Plan entkoppelt die Sensitivität richtig (Z. 152). Ein Abgleich von Ergebnis- und Replikatdatei, etwa über `n_sim`, ließe beide Verträge scheitern.

  — **Vorschlag:** Die BL-92-Sensitivität nur aus `ordinal_recovery_replicates.csv` rechnen; die Datei hat die Spalten `estimate`, `true` und `converged`. Keine Prüfung gegen die Ergebnisdatei, kein Laden von `simulation_helpers.R` (ADR-048 Nr. 14.4).
- [E12] (minor) ACC-8 (6); `tests/acceptance/setup-m1d.R:148–161` (`acc_m1d_rmd_code()`), `test-m1d-5-size-licence-network.R:102–112` — **Befund:** Der Netztest liest alle Zeilen der R-Chunks einschließlich Kommentaren und den Inline-Code.

  — **Vorschlag:** `httr2`, `curl` und `download.file` kommen in keiner Chunk-Zeile der beiden neuen Vignetten vor, auch nicht in einem Kommentar wie „no curl call“. Erklärender Text steht außerhalb der Chunks.
- [E13] (minor) ACC-11 (1), (2); `tests/acceptance/setup-m1d.R:752–793` (`acc_m1d_me_in_pse_line()`, `acc_m1d_suffixes_ok()`) — **Befund:** Die Prüfung liest nach jedem Vorkommen eines Faktornamens den Text bis zum nächsten Faktornamen.
  - Steht hinter dem letzten inaktiven Faktor der Tabelle ein erklärender Text mit „above ME only“ oder „also above SME“, ist die Prüfung rot.
  - Zwei Zeilen mit PSE und SME machen den ME-Abgleich mehrdeutig.

  — **Vorschlag:** Die Zusätze nur unmittelbar hinter dem Faktornamen, etwa „F1 (also above SME), F2 (above ME only)“. Erklärungen mit anderen Worten. Die Zeile mit PSE, ME und SME in Druck und Bericht bleibt einzeln (`R/robustness.R:162–163`, Vorlage Z. 155).
- [E14] (minor) ACC-11 (5); ACC-12; ADR-047 Nr. 2; AGENTS.md, Integrität Nr. 4 („Der Befehl wurde ausgeführt und sein echter Output steht im Handoff“) — **Befund:** Der Plan überlässt die Git-Pfade dem Gate (Z. 334): `test-m1d-7` letzter Block, `test-m1d-8` letzte zwei Blöcke. In BUILD bleiben ACC-11 (5) und ACC-12 damit ungeprüft.

  — **Vorschlag:**
  - Vor der ersten Änderung `R/fit.R`, `R/grr.R`, `R/robustness.R` und `R/acmg.R` in ein temporäres Verzeichnis kopieren; sie tragen jetzt die SHA-256 aus ANK-34.
  - Danach ohne Git vergleichen: Zeilen ohne `#'`, `msa_robustness()` und `acmg_robustness()` mit `identical()`.
  - Die Abnahmedateien `test-m1d-1` bis `test-m1d-6` rufen kein Git auf. BUILD kann sie mit `filter = "m1d-[1-6]"` ausführen und den Output in `REVIEW-INPUT.md` stellen.
- [E15] (minor) K-M1d-4 („Sensitivitätsrechnung nur mit `review_status` „criteria provided““); ACC-7 (5) — **Befund:** Der wörtliche Filter (`startsWith(…, "criteria provided")`) behält in beiden Teilmengen nur Zeilen mit „criteria provided, single submitter“.
  - In der Stichprobe fallen damit auch 37 Zeilen „reviewed by expert panel“ heraus, eine höhere Prüfstufe, dazu „flagged submission“ (Prüflauf B).
  - Der Plan nennt den Filter und die Nenner (Z. 111), nicht die Folge.

  — **Vorschlag:** Die Vignette nennt die Werte von `review_status`, die der Filter behält und verwirft, mit ihren Zeilenzahlen. Keine zweite Sensitivität nötig.

## Prüfung nach Gesichtspunkten

### Spec-Treue

- **K-M1d-1:**
  - Ordner, Spalten, Gitter, Manifest einschließlich `QUELLE.txt`, Lizenz und Commit (Z. 82–88).
  - Bytegleiche Offline-Neuerzeugung und benannter Abbruch ohne `../quellen` (Z. 119).
  - Import und `msa_counts()` (Z. 90): Prüflauf A zeigt, dass `n` fehlende Werte mitzählt.
- **K-M1d-2:** Wiederholbarkeit nach ACC-5 (1), Trefferquote mit allen Aufrufen im Nenner, binärer Fit mit Vorgaben, `msa_grr()`, `system.file()`, kein abgetippter Wert (Z. 90–94). Die Fits laufen (Prüflauf B).
- **K-M1d-3:**
  - Filter vor Zählung, verschiedene Submitter, alle SCV, Gen aus `variant_summary`, numerische Sortierung, Seed und Umfang aus ANK-47, Spalten, Datum, Ausschlusszählungen vor den Schwellen (Z. 98–104).
  - Die Mini-Referenz ergibt die Zählungen von ACC-6.
- **K-M1d-4:**
  - Alpha ohne Modalreduktion, Anteile mit dem Nenner aus ACC-7 (3) und Konflikt nicht als Komplement, ordinaler Fit mit Probit, Sensitivität, Literatur gelesen, Satz wörtlich (Z. 106–113).
  - Probit ist hier der einzige gangbare Link (Prüflauf B).
- **K-M1d-5:**
  - Grenzen aus ANK-TOL, Gesamtprüfung über `inst/extdata/`, keine INSAID-Daten, kein Netz (Z. 119–123).
  - Die Listung braucht den Betreiber (E1).
- **K-M1d-6:** Die Betreiberdateien bleiben unverändert; der Neulauf geschieht im Abnahmetest; Skripte und Hashbereich bleiben unberührt (Z. 127, 201).
- **K-M1d-7:**
  - Tabellen mit Wert und MCSE in einer Zeile, Prozent für beide, `n_sim` je Datei (Z. 131).
  - Befundregeln exakt nach ACC-10 (2), MCSE 0 berücksichtigt (Z. 135–137); Befundmenge nachgeprüft (Prüflauf A).
  - Hilfeseiten nur über roxygen (Z. 51, 148).
- **K-M1d-8:**
  - Satz, `formatC(…, "f", 4)`, Zusätze, keine Zusätze bei inaktiven Faktoren, Altphrase entfernt (Z. 156–160).
  - Objekt und Bänder unverändert, ohne neue Rechnung (Z. 162; ADR-045 Nr. 2).
  - Die Altphrase steht heute genau in `R/robustness.R:168` und in der Vorlage Z. 161. Kein Test hängt am bisherigen Wortlaut aktiver Faktoren.

### Architektur und Verträge

- **Keine neue Schnittstelle:** keine Exporte, keine Argumente, kein neuer Import; ANK-02 bleibt Obermenge (Z. 60, 78). Die Druckausgabe ändert sich mit ADR-045 (docs/01 §4).
- **Ressourcen:** `inst/validation/m1d/` folgt dem Muster von `inst/validation/latent/` und `numeric/`: Ankerkopien, `SOURCES.json`, Erzeugung unter `data-raw/` (ADR-048 Nr. 14.5). Hilfen der Datenskripte und der Vignette sind getrennt (`prepare.R`, `findings.R`).
- **Hashbereich:**
  - `sim_implementation()` und `boot_implementation()` hashen `deparse()` der Namensraumfunktionen und der Helfer mit Präfix `sim_` bzw. `boot_`.
  - roxygen-Zeilen gehen nicht ein; neue Helfer ohne diese Präfixe bleiben draußen (E10).
  - Die Vollläufe bleiben damit gültig.
- **Parallelisierung:** keine neue in `R/` (Z. 78).

### Vollständigkeit

- Acht Kriterien, ACC-1 bis ACC-20 und alle 116 BACKLOG-Einträge sind zugeordnet.
- Dateiliste mit Builder-ADR, `NEWS.md`, `PROGRESS.md` und `REVIEW-INPUT.md` (Z. 39–58).
- Fehlte nur die Präzisierung der Etikettenregel (E2) und des ClinVar-Inhalts von `QUELLE.txt` (E6).

### Risiken

- Der Plan nennt die wesentlichen Risiken mit Gegenmaßnahme (Z. 193–207): Laufzeit großer Rohdaten, mehrdeutige Ausgaben, Locale, Nichtkonvergenz, Hashbereich, Leserverträge, pkgdown, Paketgröße.
- Dazu aus den Prüfläufen:
  - Quoting und Kodierung der Submitter-Namen (E4);
  - der Ladeweg der Datenskripte im Test (E5);
  - die Stellenzahl gegen den Testvergleich (E7);
  - der Dokumentationsgraph des Unit-Tests (E10).
- **Laufzeit im Gate:** Mini-Referenz ClinVar 115 s, Rohläufe llm-stability 9 s, Fits je unter 4 s. Hinzu kommen beide Datenskripte (Dauer offen; der Plan misst sie), drei gestrickte Vignetten, zwei Berichte und die geteilten Neuläufe von K-M1d-6.

### Gate-Abdeckung

- **deps:** `DESCRIPTION` bleibt; jsonlite, knitr, rmarkdown, yaml und digest stehen unter Suggests.
- **lint:**
  - `R CMD build` und `check --as-cran` bauen alle vier Vignetten; ERROR und WARNING bleiben Fehler.
  - Die Größen-NOTE aus BL-114 ist bekannt (Z. 205, 370).
  - Der Builder sieht K-M1d-2 und K-M1d-4 im Bau als Gate-Kriterium (Z. 356, 358).
- **tests:** alle Abnahmedateien von M1d; der Plan ändert keinen Test (ADR-047 Nr. 2).
- **trace:** Kriteriums-IDs stehen in den Abnahmetests, auch für den lint-Anteil als Kommentar.
- **territory:** Alle Dateien der Liste liegen im Builder-Territorium von `40-build`; `_pkgdown.yml` ausdrücklich nicht (E1).
- **mutgate:** ADR-047 Nr. 1, Bedingung ACC-12 (E14).
- **golden-adr:** Das Builder-ADR deckt `inst/extdata/` (Z. 57).
- **mutfull:** nur M1c.

## Hinweise für BUILD

1. Mit dem Betreiber klären, ob M1D-INFRA-01 vor dem Start erledigt ist; sonst den roten Listungstest als [INFRA] in `REVIEW-INPUT.md` nennen.
2. Reihenfolge wie Plan Z. 182–191. Die Pflichtfits früh auf den echten Teilmengen laufen lassen (Z. 187).
3. E2, E4 und E5 vor dem ersten Lauf der Datenskripte umsetzen; jede spätere Änderung erzeugt neue Golden-Daten.
4. Die Builder-ADR-Nummer ist ADR-049 (ADR-048 Nr. 14.7).
5. Nachweise mit echtem Output in `PROGRESS.md` und `REVIEW-INPUT.md`; Proben vor dem Ende der Phase löschen.
