# REVIEW — M1d, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 04.11.2026 · Gegenstand: Diff seit `plan/M1d` (`0511335`) bis zum Stand der Gates (`gates.json`: `env.sha` `45ba4fc`, Commit der QA-Phase; HEAD `a96c7c2` ist der Gate-Commit), also BUILD r1 und QA r1. Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` zu M1d. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK, `blocking` leer.** `gates.json` meldet `result: "fail"`. Rot ist nur das Gate tests, und dort nur der Testblock „K-M1d-5: both vignettes are listed under articles in _pkgdown.yml“ mit drei Erwartungen. Grund: `_pkgdown.yml` hat keinen Abschnitt `articles`. Die Datei liegt im Betreiber-Territorium, der Befund ist [INFRA] und für den Builder nonblocking (E1).

- **Warum REWORK:** PASS verlangt `gates.result = pass` und ist ausgeschlossen. ESCALATE scheidet aus, weil keine Spec-Stellen einander widersprechen.
- **Spec-Treue:** K-M1d-1 bis K-M1d-8 sind umgesetzt.
  - Alle Abnahmetests von M1d außer dem Listungsblock sind im tests-Gate grün (Tabelle unten).
  - K-M1d-2, K-M1d-4 und K-M1d-5 sind zusätzlich im lint-Gate belegt: `R CMD check --as-cran` baut alle vier Vignetten, `Status: OK`.
  - Die Umsetzung folgt PLAN r1 mit E2 bis E15 aus PLAN-REVIEW. ADR-049 hält die Festlegungen des Builders fest und weicht fachlich nicht vom Plan ab.
- **Kerndateien und Mutation (ADR-047):**
  - `R/fit.R` und `R/grr.R` ändern sich nur in roxygen-Zeilen (Prüflauf 2); ACC-12 ist im Gate grün.
  - Unter `tests/` entfällt keine Datei. Die einzige geänderte bestehende Testdatei ist `tests/e2e/test-m1c-qa-e2e.R` (QA). Sie behält ihre Erwartungen und prüft zusätzlich den Vorrang des Vollaufs.
  - Damit gilt ADR-047 Nr. 2. mutgate („kein geänderter Mutations-Scope“) und mutfull („nicht fällig in M1d“) sind grün.
  - Es gibt keinen Mutationsbericht dieser Runde, keine Überlebenden zu benennen und keine `MUT-EQUIV.json`. Ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`.
- **QA:** Es gibt kein blockierendes Gegenbeispiel; `tests/e2e` und `tests/fuzz` sind grün. Zu QA-M1d-001 gibt es keinen roten reproduzierenden Test; ich bestätige ihn als nonblocking (E18, BL-117).
- **Einwände:** vier minor-Befunde, keiner blocking:
  - E1: [INFRA], an den Betreiber;
  - E16: Etikettenregel von llm-stability, Entscheidung des Betreibers nach der Abnahme;
  - E17: Darstellung, optional im Rework;
  - E18: BL-117 bestätigt.
- **Für das Rework r2:** Der Builder hat keinen Pflichtpunkt.
  - E17 kann er mitnehmen.
  - Golden-Daten unter `inst/extdata/`, `data-raw/`, `R/fit.R`, `R/grr.R`, die Rd-Befundtexte und die Betreiberdateien unter `inst/validation/sim/` bleiben unverändert.
  - Grün wird die Runde erst mit dem Betreiber-Eintrag aus E1.

### An den Betreiber

1. **`_pkgdown.yml` (E1, M1D-INFRA-01, ADR-048 Nr. 15, neu BL-118).** Ergänzen, bestehende Schlüssel unverändert:

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

   - **Geprüft (Prüflauf 5):**
     - Die Logik des Abnahmeblocks findet `articles`, `llm-stability` und `clinvar-raters`.
     - K-M0-5 behält die Zeile `destination: pkgdown-site`.
     - `pkgdown:::data_articles_index()` (pkgdown 2.2.1) läuft durch. Ohne `validation` bricht pkgdown ab: „1 vignette missing from index: "validation"“.
   - **Zeitpunkt.** Der Betreiber-Commit muss vor einer Modellphase liegen, sonst wird territory rot (BL-106).
     - **Empfohlen:** `orchestrator/STOP` noch während dieser Review-Phase anlegen. Dann hält der Lauf direkt nach dem Review-Commit (`commit_phase` → `stop_check`, `orchestrate.sh:718`). Das geschieht, bevor das Verdict gelesen und `state/M1d/round` auf 2 gesetzt wird (`:1042`, `:1074–1077`).
     - Danach `_pkgdown.yml` committen, `STOP` entfernen und neu starten. Der Lauf liest das Verdict von r1 und startet Rework r2 auf dem Betreiber-Commit, danach die Gates r2. territory ist dann grün, weil `HEAD^` die Audit-Basis von Rework r2 ist.
     - **Falle:** Wird `STOP` erst nach dem Review-Commit angelegt, hält der Lauf erst in `run_model` von 60-rework (`:621`). Dann steht `state/M1d/round` schon unversioniert auf 2.
       - Diese Datei vor dem Commit entfernen; sonst scheitert der Neustart an der Prüfung des Arbeitsbaums (`:294–297`).
       - Wird sie mitcommittet, überspringt der Neustart das Rework und startet die Gates r2 sofort (`:980–1003`). territory meldet dann „Audit stammt aus Runde 1 statt 2“ (`gates.d/82-territory.sh:9–10`).
     - **Läuft Rework r2 schon:** Zwischen Rework und Gates nicht committen (BL-106). Die Gates r2 werden dann aus demselben Grund rot, und jede weitere Runde kostet einen Builder-Aufruf ohne Builder-Befund (wie BL-105). Den Eintrag dann wie oben während der Review-Phase r2 vorbereiten: `STOP` anlegen, nach dem Review-Commit committen.
2. **ADR-047 Nr. 3:** Nach `done/M1d` den Mutationslauf ohne die Scope-Sperre einmal in einer Kopie nachrechnen, verlangt sind 92,09. Vor M3a folgt die Scope-Rückstellung nach Nr. 4 (BL-24).
3. **Etikettenregel llm-stability (E16, neu BL-119):** Vor einer Verwendung der Wiederholbarkeiten und Trefferquoten aus `vignettes/llm-stability.Rmd` im Paper entscheiden, ob die Regel auf eine Salienzfolge wie in der Quelle umgestellt wird. Das ist keine Aufgabe in M1d.

## Gate-Fakten (`orchestrator/state/M1d/gates.json`, Runde 1)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`: `creating vignettes ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK`; `installed size is 22.3Mb` als INFO (BL-114) |
| tests | **fail** | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5741 ]` (Skip: ellmer-Negativtest); acceptance `[ FAIL 3 \| WARN 2 \| SKIP 0 \| PASS 15638 ]`; e2e `[ FAIL 0 \| … PASS 319 ]`; fuzz `[ FAIL 0 \| … PASS 94 ]`. Kurzbefund: „674 Tests …; 1 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (`gate-tests.log` Z. 1952) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | letzter Diff sauber (qa/45-qa, Runde 1, Basis `f76b592`) |
| mutgate | pass | `kein geänderter Mutations-Scope` (ADR-047 Nr. 1, `config.env:276`) |
| golden-adr | pass | `Änderung und ADR liegen im selben Meilenstein` (ADR-049 deckt `inst/extdata/`) |
| mutfull | pass | `nicht fällig in M1d` |

- **Die drei Fehlschläge** (`gate-tests.log` Z. 1193–1213, wiederholt Z. 1829–1851) liegen alle in `test-m1d-5-size-licence-network.R:97–99`:
  - „Expected _pkgdown.yml has an articles section to be TRUE“;
  - „llm-stability is listed under articles“;
  - „clinvar-raters is listed under articles“.
- **Die zwei Warnungen** sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 780–807). Sie liegen im Reviewer-Territorium, kein Produktbezug.

Erwartungen der M1d-Tests im tests-Gate:

| Testdatei | Erwartungen |
| --- | --- |
| `m1d-1-llm-stability-data` | 97 (23,8 s) |
| `m1d-2-llm-stability-vignette` | 113 (15,1 s) |
| `m1d-3-clinvar-data` | 47 (545,6 s) |
| `m1d-4-clinvar-vignette` | 106 (15,4 s) |
| `m1d-5-size-licence-network` | 42 grün, 3 rot (E1) |
| `m1d-6-full-runs` | 4125 |
| `m1d-7-findings` | 512 (77,1 s), einschließlich ACC-12 über `done/M1c` |
| `m1d-8-robustness-wording` | 31, einschließlich ACC-11 (5) über `done/M1c` |
| Unit `m1d-data`, `m1d-findings` | 47, 48 |
| QA `m1d-qa-e2e`, `m1d-qa-fuzz`, `m1c-qa-e2e` | 224, 51, 46 |

- **Regression der Vormeilensteine** im selben Lauf grün, darunter:
  - `m0-api-snapshot` (259);
  - `m1a-7-vignette` (148);
  - `m1b-7-vignette-full-results` (204);
  - `m1c-5-vignette-full-results` (49);
  - `m2-7-robustness-pilot` (375).
- **Laufzeit:** Die Abnahme dauert 2328,8 s, davon 545,6 s für die ClinVar-Mini-Referenz (ACC-16 (5)).
- **Visuelle Artefakte:** `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.

## Gelesen

- **Rahmen:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/02 M1d vollständig (Voraussetzung, Abbildungen, K-M1d-1 bis K-M1d-8), dazu K-M1c-3 bis K-M1c-5.
- **Entscheidungen:** ADR-045, ADR-047, ADR-048 (als Vertrag), ADR-049 (neu, Builder).
- **Handoff M1d:** `CRITERIA.json` (ACC-1 bis ACC-20), `PLAN.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `REVIEW-INPUT.md`, `QA.md`; zum Format `REVIEW.md` und `verdict-code.json` aus M1c.
- **Gates und Harness:**
  - `gates.json` und alle acht `gate-*.log`, `state/M1d/territory-ok`;
  - `orchestrate.sh`: `path_allowed`, `run_model`, `commit_phase`, `verdict()`, `run_ms`;
  - `gates.d/82-territory.sh`;
  - `config.env` (Territorien, Mutation).
- **Diff seit `plan/M1d`** (Prüflauf 1), Änderungen vollständig als `diff -u`:
  - Produkt und Doku: `R/fit.R`, `R/grr.R`, `R/robustness.R`, `inst/templates/validation_report.Rmd`, `man/msa_fit.Rd`, `man/msa_boot.Rd`, `vignettes/validation.Rmd`, `NEWS.md`;
  - Handoffs und Tests: `PROGRESS.md` (M1d-Eintrag), `BACKLOG.md` (BL-117 der QA), `tests/e2e/test-m1c-qa-e2e.R`.
- **Neue Dateien, vollständig gelesen:**
  - `data-raw/make_llm_stability.R`, `make_clinvar_subsets.R`, `make_validation_m1d.R`;
  - `inst/validation/m1d/prepare.R`, `findings.R`, `README.md`, `SOURCES.json`;
  - beide `QUELLE.txt` und `SHA256SUMS`;
  - `vignettes/llm-stability.Rmd`, `clinvar-raters.Rmd`;
  - `tests/testthat/test-m1d-data.R`, `test-m1d-findings.R`, `tests/e2e/test-m1d-qa-e2e.R` (Teil), `tests/fuzz/test-m1d-qa-fuzz.R`;
  - ADR-049.
- **Abnahme und Anker:** `tests/acceptance/setup-m1d.R` (Helfer, Teil), `test-m1d-5-size-licence-network.R`, `test-m0-layout.R:29–33`; ANK-40 und ANK-42 bis ANK-46 (Wert, Zitat, Beobachtungen).
- **Quelle zu E16:** `../quellen/daten/llm-stability_2026-10-22/llm-stability-main/helper_functions.py:84–187`, gelesen mit Rscript.

## Eigene Prüfläufe

Am 04.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1d/.probe-cr1/`, vor Phasenende mit `unlink()` gelöscht. Paket über `pkgload::load_all()`. Umgebung: R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, pkgdown 2.2.1. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff seit `plan/M1d` ohne Git-Kommando.**
   - Vorgehen: R liest den Tag aus `.git/refs/tags/plan/M1d` und folgt ihm über das Tag-Objekt (`0456afb…`) zum Commit und zu dessen Baum, dazu den Baum von HEAD. Alle Objekte stammen aus den losen Objektdateien (`memDecompress`); es fehlte keines.
   - Danach Vergleich der Blob-IDs; alte Fassungen geänderter Dateien ausgeschrieben und mit `diff -u` verglichen.

   ```text
   base commit: 051133562fa0197a70535fb24d3afbd5c7d2a0d2
   head commit: a96c7c2a5616645411eef41a8460809f35e2e333
   base files: 674  head files: 722
   added: 48  removed: 0  changed: 15  worktree-diff: 0
   ```

   - Geändert:
     - Produkt und Doku: `BACKLOG.md`, `NEWS.md`, `PROGRESS.md`, `R/fit.R`, `R/grr.R`, `R/robustness.R`, `inst/templates/validation_report.Rmd`, `man/msa_boot.Rd`, `man/msa_fit.Rd`, `vignettes/validation.Rmd`;
     - Tests: `tests/e2e/test-m1c-qa-e2e.R`;
     - Orchestrator-Zustand: `STATUS.md`, `orchestrator/state/…`.
   - Neu sind die 48 Dateien der Builder- und QA-Liste: Datenskripte, `inst/extdata/` (zwei Ordner), `inst/validation/m1d/` (Helfer, elf Ankerkopien, Manifest), zwei Vignetten, zwei Unit- und zwei QA-Testdateien, ADR-049, Handoffs und Gate-Zustand.
   - Unverändert sind:
     - `DESCRIPTION`, `NAMESPACE`, `_pkgdown.yml`, `.Rbuildignore`;
     - `tests/acceptance/**`, `reference/anchors/**`, die Specs;
     - `inst/validation/sim/**` (alle zwölf Volllaufdateien und die Skripte), `R/acmg.R` und die übrigen Rd-Dateien.
   - Kein Arbeitsbaum-Unterschied zu HEAD.
2. **Kerndateien und Robustheit (`diff -u`).**
   - `R/fit.R` (Hunk `@@ -28,8 +28,16 @@`) und `R/grr.R` (`@@ -169,8 +169,13 @@`): jede geänderte Zeile beginnt mit `#'`. Die Rd-Dateien folgen daraus.
   - `R/robustness.R` ändert nur `print.msa_robustness()` (`:159–177`):
     - ME als `formatC(…, format = "f", digits = 4)` in der Zeile mit PSE, ME und SME und im neuen Satz;
     - Zusatz „(also above SME)“ oder „(above ME only)“ unmittelbar hinter jedem aktiven Faktor.
   - `msa_robustness()` ist unverändert. Die Vorlage ändert sich nur im Chunk `robustness` (`:152–169`).
   - Die Altphrase steht in `R/` und `inst/templates/` nicht mehr, nur noch in BACKLOG, Specs, ADRs und Tests.
3. **Vignetten gestrickt** (Markdown in der Probe, `REPO_ROOT` gesetzt):

   ```text
   llm-stability: ok (7.3 s)
   clinvar-raters: ok (7.8 s)
   validation: ok (17.4 s)
   ```

   - Keine unerwartete Warnung; die erwarteten Fit-Warnungen stehen in den Diagnosetabellen.
   - `llm-stability`:
     - Wiederholbarkeit, Trefferquote und Fehlanteil je Aufgabe und Modell (40 Zeilen);
     - `msa_counts()` mit n = Items × 10;
     - acht konvergierte, nicht singuläre Probit-Fits. high_school_european_history und public_relations zeigen Item-Komponenten von 44,08 und 41,93 (flache Likelihood, im Text erklärt).
   - `clinvar-raters`:
     - HRF: Alpha nominal 0,528 und ordinal 0,7529, vollständige Übereinstimmung 0,5264, Konflikt 0,3565;
     - Stichprobe: Alpha 0,6037 und 0,8508;
     - Fits ohne Diagnose;
     - Statusfilter mit 5958/4479 behaltenen Zeilen;
     - Literaturtabellen ANK-42 bis ANK-46 mit Einheit je Wert.
   - `validation`: 19 Befundzeilen:
     - sieben ordinal und drei binär, alle „underestimation“;
     - zwei two_level mit „no direction resolved at the report threshold“;
     - sieben ndc mit „overcoverage“.
     - Dazu die Sensitivität mit 50 Zeilen. Sie zeigt S-ord-4 zuerst (E17).
4. **Etikettenregel gegen die Salienzfolge der Quelle (E16).**
   - Rohläufe über `acc_m1d_llm_raw()`. Die eingefrorene Regel (`m1d_parse_answers()`) reproduziert `items.csv.gz` auf allen 82.850 Zeilen.
   - Die Salienzfolge der Quelle ist nachgebaut: letzter Satz, letzte drei, ganzer Text; je Stufe „The answer is (X)“, exaktes, dann groß/klein-unabhängiges Etikett. Ihr letzter Rückfall auf nackte Buchstaben (`sub_string`) ist weggelassen. navigate folgt `parse_string()`: ganzes Wort exakt, dann ohne Groß-/Kleinschreibung.

   ```text
   ambiguous     empty  no_label    parsed
        8974       155      1941     71780
   ambiguous under the frozen rule: 8974 of 82850 (10.8 %)
   of these, unique under the source salience order without bare letters: 6913 (77.0 %); equal to the key: 2076
                            task        model ambiguous resolved calls
         professional_accounting   llama3-70b      1332     1203  2820
         professional_accounting    llama3-8b      1321     1200  2820
                public_relations   llama3-70b       617      487  1100
         professional_accounting mixtral-8x7b       603      334  2820
                public_relations    llama3-8b       512      428  1100
    high_school_european_history   llama3-70b       507      328  1650
   (gekürzt auf die ersten sechs Zellen)
   ```
5. **pkgdown-Listung (E1)** auf einer temporären Kopie mit dem YAML aus „An den Betreiber“ Nr. 1:

   ```text
   K-M1d-5 logic: articles present: TRUE | llm-stability: TRUE | clinvar-raters: TRUE
   K-M0-5 logic: destination line kept: TRUE
   pkgdown version: 2.2.1
   data_articles_index with validation listed: ok
   data_articles_index without validation: ERROR In _pkgdown.yml, 1 vignette missing from index: "validation".
   ```
6. **Ankerkopien:** Die elf Dateien unter `inst/validation/m1d/anchors/` gleichen `reference/anchors/` per SHA-256, und `SOURCES.json` trägt beide Werte. Ausgabe je Anker etwa `ANK-40 orig=d384028d6799 copy=TRUE manifest=TRUE`, alle elf `TRUE`.

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **K-M1d-1:**
  - Auswahl und Herkunft: Zero-shot-Ordner aus ANK-40 mit Konfigurations-, Datums- und Dimensionsprüfung gegen `stability_eval.csv`.
  - Daten: vollständiges Gitter, Spalten wie verlangt, kein Rohtext.
  - Begleitdateien: `QUELLE.txt` mit Commit, Lizenz, Auswahlregel und Zählungen; `SHA256SUMS` einschließlich `QUELLE.txt`.
  - Neuerzeugung bytegleich im Test; benannter Abbruch ohne `quellen` (`prepare.R:18–23`).
- **K-M1d-2:**
  - Kennzahlen: Wiederholbarkeit mit fehlender Antwort als Bruch, Trefferquote über alle Aufrufe (ACC-5 (1), (2)).
  - Fits: binär je Aufgabe mit Item und Modell als Zufallseffekten, `msa_grr()`.
  - Daten über `system.file("extdata", …)`, kein abgetipptes Ergebnis.
- **K-M1d-3:**
  - Auswahl: Filter vor Zählung, alle SCV, `gene` aus `variant_summary`, Ziehung über `sample.int()` auf aufsteigend sortierten IDs; das gleicht `sample()` nach ACC-6 (6).
  - Spalten und Datum wie verlangt.
  - Ausschlusszählungen 501 und 43.886 berechnet, nicht eingetragen.
- **K-M1d-4:**
  - Alpha ohne Modalreduktion; vollständige Übereinstimmung und Konflikt mit dem Nenner aus ACC-7 (3).
  - Ordinale Fits mit Probit; Sensitivität mit wörtlichem Präfix und offengelegten Zählungen (E15).
  - Literatur gelesen statt getippt, die Gruppierungen sind erklärt (ACC-18, ACC-19). Der Satz „not an acceptance criterion“ steht wörtlich.
- **K-M1d-5:** Größen aus ANK-TOL (neue Ordner 258.865 und 117.822 Byte); keine INSAID-Daten; kein Netzaufruf in den Chunks. Offen ist nur die Listung (E1).
- **K-M1d-6:** Die Betreiberdateien sind unverändert, der Neulauf im Gate ist bytegleich (4125 Erwartungen).
- **K-M1d-7:**
  - Tabellen mit Wert und MCSE je Zeile.
  - Befundregeln dynamisch aus ANK-TOL (`findings.R:66–97`), mit dem Nominalwert 0,95 aus docs/02 M1c.
  - Hilfetexte nennen alle Szenario-IDs einzeln mit Richtung und Verweis auf `vignette("validation")`.
  - BL-92 als getrennte Sensitivität.
- **K-M1d-8:** Satz, ME-Format und Zusätze wie verlangt; Objekt und Bänder sind im Gate gleich `done/M1c`.
- **„M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“:** eingehalten (Prüflauf 2).

### API, Tests, Konfiguration

- **API:** Kein neuer Export, kein neues Argument, kein neuer Import; ANK-02 ist im Gate grün. Geändert ist nur die Druckausgabe von `print.msa_robustness()`, gedeckt durch ADR-045.
- **Bestehende Tests:** Keine Testdatei ist gelöscht oder entkernt, und keine Erwartung ist abgeschwächt.
  - QA-M1c-E2E-4 (`tests/e2e/test-m1c-qa-e2e.R:166–179`) prüft den Standardordner jetzt als Volllauf (`full`, S-boot-1 bis S-boot-7), wie K-M1c-5 es verlangt.
  - Die alten Kurzlauf-Erwartungen (`check`, S-boot-1 und S-boot-7) laufen unverändert auf einem isolierten Ordner mit der unveränderten Kurzlaufdatei.
  - Damit ist M1D-QA-01 aus REVIEW-INPUT erledigt.
- **Neue Unit-Tests des Builders** belegen Verhalten, keine eigene Ausgabe:
  - synthetische Eingaben mit Erwartungen aus der Regel oder von Hand gerechnet (Bias-, EmpSE- und MCSE-Formeln);
  - Invarianzen: Reihenfolge, Locale, RNG-Zustand;
  - Fehlerpfade und Grenzfälle der Schwellen.
  Momentaufnahmen gibt es nicht.
- **QA-Tests:** prüfen Eigenschaften gegen ANK-40 und ANK-47 und die Verträge (Zählungen, Schwellen, Fehlpfade), keine eingefrorenen Ergebniswerte.
- **Konfiguration:** Der Builder hat weder `DESCRIPTION`, `.Rbuildignore`, Gates noch Testauswahl geändert. Die Mutationseinstellungen stammen aus ADR-047 und ACC-13 (Betreiber, vor dem Plan).

### Werte, Daten, Golden

- **Harte Werte:**
  - Im Produkt stehen nur Spec-Größen: die vier HRF-Gene und „mindestens zwei Einreicher“ aus K-M1d-3 (a), der Nominalwert 95 % aus docs/02 M1c.
  - Seeds, Umfang, Schwellen, Ordner und Itemzahlen kommen aus den Ankern.
  - Die Rd-Texte nennen die Befunde statisch, wie K-M1d-7 es verlangt; der Abnahmetest gleicht sie mit den Dateien ab.
- **Erfundene Daten:**
  - Beide Teilmengen entstehen aus den hashgeprüften Rohdaten.
  - Der Abnahmetest vergleicht sie mit einer unabhängigen Mini-Referenz und erzeugt sie bytegleich neu.
  - Fehlende Antworten bleiben fehlend.
- **Golden und Anker:** `inst/extdata/` ist neu mit ADR-049 (Gate golden-adr grün). `reference/anchors/` ist unverändert, die Kopien unter `inst/` sind bytegleich (Prüflauf 6).

### Sichtbare Defekte

- Keine Fehlberechnung gefunden. Zur Darstellung: E17.
- Die Etikettenregel ist spec-konform, aber folgenreich (E16): Die Vignette weist die Fehlanteile aus und sagt, dass die Trefferquote diese Extraktionsregel beschreibt.

## Einwände (Runde 1)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“); ACC-8 (5); Gate tests (`gate-tests.log` Z. 1193–1213); PLAN-REVIEW E1; ADR-048 Nr. 15 — **Befund:** `_pkgdown.yml` hat weiterhin keinen Abschnitt `articles`. Die drei roten Erwartungen in `test-m1d-5-size-licence-network.R:97–99` sind der einzige Grund für `gates.result = fail`.
  - Die Datei gehört zum Betreiber-Territorium (`config.env:200`, `orchestrate.sh:515–544`). Der Builder hat sie zu Recht nicht angefasst und den Punkt in REVIEW-INPUT gemeldet.
  - — **Vorschlag:** Betreiber nach „An den Betreiber“ Nr. 1, YAML in Prüflauf 5 geprüft. Für den Builder nicht blockierend. Neu BL-118.
- [E16] (minor) ACC-2 (3) („fehlend, wenn keine oder keine eindeutige Antwort gefunden wird“); ADR-049 Nr. 2; PLAN-REVIEW E2; docs/01 §5 — **Befund:** Die Regel zählt jedes gültige Etikett im ganzen Antworttext gleich, ohne Vorrang für den Schluss.
  - 8.974 von 82.850 Aufrufen (10,8 %) sind deshalb mehrdeutig und fehlen. In einzelnen Zellen ist es fast die Hälfte: professional_accounting mit llama3-70b 1.332 von 2.820, mit llama3-8b 1.321.
  - Die Quelle (`helper_functions.py:110–153`) wertet zuerst den letzten Satz und „The answer is (X)“ aus. Nach dieser Folge, ohne nackte Buchstaben, wären 6.913 der 8.974 eindeutig, davon 2.076 gleich dem Schlüssel (Prüflauf 4).
  - Das ist spec-konform: ACC-2 verlangt keine Gleichheit mit der Quelle, E2 verlangte nur eine festgelegte Regel, und Regel wie Fehlanteile stehen in `QUELLE.txt` und in der Vignette. Wiederholbarkeit und Trefferquote messen damit aber vor allem bei den Llama-Modellen die Extraktionsregel mit.
  - — **Vorschlag:** In M1d nichts ändern, weil jede Änderung neue Golden-Daten bedeutet.
    - Der Betreiber entscheidet vor einer Verwendung der Zahlen im Paper über eine Salienzregel ohne nackte Buchstaben. Dazu gehören ein Builder-ADR, ein Neulauf von `make_llm_stability.R` und eine neue Abnahme von K-M1d-1 und K-M1d-2.
    - Bis dahin die Zahlen als Werte dieser Regel zitieren. Neu BL-119.
- [E17] (minor) K-M1d-7 (BL-92, ADR-048 Nr. 14.4); K-M1d-4 (E15); `inst/validation/m1d/findings.R:126`; `vignettes/validation.Rmd:285` — **Befund:** zwei Darstellungsmängel, der Inhalt stimmt jeweils.
  - Die Konvergenz-Sensitivität zeigt S-ord-4 vor S-ord-1 bis S-ord-3. `split(d, list(d$scenario, d$estimand), drop = TRUE)` ordnet nach Schätzziel, und nur S-ord-4 hat `block`; die Vignette übernimmt die Reihenfolge mit `unique()`.
  - Die Statustabelle in `clinvar-raters.Rmd` heißt in der Zählspalte `Freq`, der Rohname aus `as.data.frame(table())`.
  - — **Vorschlag:** Szenarien sortiert ausgeben (etwa `sort(unique(…))`) und die Spalte z. B. `submissions` nennen. Optional im Rework r2, kein Testbezug, sonst nach dem 26.11.2026. Neu BL-120.
- [E18] (minor) QA.md QA-M1d-001; BL-117; ADR-035 Nr. 1 bis 3 — **Befund:** Es gibt keinen roten reproduzierenden Test, QA-M1d-FUZZ-2 ist grün.
  - In der Vignette erreichen `m1d_findings()` nur Tabellen, deren Kennzahlen die Leser je Szenario und Schätzziel vollständig geprüft haben (`inst/validation/latent/reference_checks.R:211–222`, `inst/validation/sim/boot_coverage_results.R:43–47`).
  - `m1d_convergence_sensitivity()` bricht bei einer reinen NA-Spalte benannt ab und liefert keine stille falsche Zahl (docs/01 §2 Nr. 4).
  - — **Vorschlag:** nonblocking bestätigt; Härtung nach dem 26.11.2026 laut BL-117.

## Antworten auf REVIEW-INPUT

- **E1 bis E15:** Alle Antworten des Builders („akzeptiert“) sind am Code nachvollzogen:
  - E2: Regel in ADR-049 Nr. 2 und `QUELLE.txt`, Fehlgründe gezählt, synthetische Unit-Fälle, Fehlanteil in der Vignette;
  - E3: Items 99 und 144 in `QUELLE.txt` und Vignette;
  - E4: UTF-8, Quoting, `radix`, `LC_TIME=C`;
  - E5: `sys.source()` relativ zur Paketwurzel;
  - E6: `QUELLE.txt` vollständig;
  - E7: Abbildung wie die Tests, vier signifikante Stellen;
  - E8 und E9: signifikante Stellen, Befund-IDs einzeln;
  - E10: `sys.source(system.file(…))`, kein Literal, kein `sim_`/`boot_`;
  - E11: Sensitivität nur aus den Replikaten;
  - E12: keine Netzbegriffe in den Chunks;
  - E13: Zusätze direkt hinter dem Faktornamen;
  - E14: Git-freie Belege in PROGRESS;
  - E15: Statustabelle mit Zählungen.
- **M1D-INFRA-01:** als E1 übernommen.
- **M1D-QA-01:** durch QA in 45-qa erledigt (oben), kein Backlog-Eintrag nötig.
- **Hinweis zu QA.md:** QA.md nennt `tests/testthat/test-robustness.R` als geändert; die Datei gibt es nicht. QA-M1d-E2E-1 spricht von „21 Aufgaben“; ANK-40 hat acht, der Test prüft gegen ANK-40. Beides betrifft nur den Handoff-Text.

## BACKLOG

- **Neu:**
  - BL-118 (E1, [INFRA], Betreiber);
  - BL-119 (E16, Betreiber-Entscheidung);
  - BL-120 (E17, Builder, nicht verlangt).
- **Stand ergänzt:**
  - BL-04: Überdeckung berichtet;
  - BL-92: umgesetzt, Streichung mit der Abnahme;
  - BL-93: Warnungen unverändert;
  - BL-112: umgesetzt, Streichung mit der Abnahme;
  - BL-117: nonblocking bestätigt.
