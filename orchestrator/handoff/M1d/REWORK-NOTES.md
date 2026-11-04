# REWORK-NOTES — M1d, Runde 2

Rolle: Builder · Phase: `60-rework` · Stand: 04.11.2026.

## Ausgangslage und Umfang

`REVIEW.md` und `verdict-code.json` der Runde 1 enthalten keinen
blocking-Befund. `orchestrator/state/M1d/gates.json` meldet `result: fail`:
Nur `tests` ist rot, ausschließlich wegen der fehlenden Artikelliste in
der Betreiberdatei `_pkgdown.yml` (E1). Kein Gate hat Status `error`.
Der optionale Darstellungspunkt E17 ist in dieser Runde umgesetzt.

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, PROGRESS,
REVIEW, Verdict, Gate-Fakten und das rote tests-Log, CRITERIA einschließlich
ACC-1 bis ACC-20, die einschlägigen Specs und Abnahmetests, PLAN-REVIEW,
QA und LESSONS sowie ADR-035, ADR-047 und ADR-049. Eine `ARBITER.md` zu
M1d existiert nicht. Die numerische Randfall-Lehre aus LESSONS erfordert
für die beiden Darstellungsänderungen keine Änderung am Statistikkern.

## Antworten auf die Befund-IDs

| ID | Antwort, Dateien und Beleg |
| --- | --- |
| **E1 / M1D-INFRA-01 / BL-118** | **OUT-OF-TERRITORY [INFRA].** Ref: K-M1d-5, ACC-8(5), ADR-048 Nr. 15, `orchestrator/state/M1d/gate-tests.log:1193–1213`. `_pkgdown.yml` enthält weiterhin keinen Abschnitt `articles`. Der unveränderte Abnahmetest reproduziert genau die drei Fehler zur Artikelliste; 42 andere Erwartungen bestehen (Prüfung B). Zuständig bleibt der Betreiber: `validation`, `llm-stability` und `clinvar-raters` unter `articles` eintragen, nach dem in REVIEW beschriebenen Ablauf außerhalb einer Modellphase. YAML und Commit-Zeitpunkt stehen in REVIEW unter „An den Betreiber“, Nr. 1. Kein Produkt-Scheinfix. |
| **E16 / BL-119** | **Zurückgestellt wie im Review verlangt; keine Änderung in M1d.** Ref: ACC-2(3), ADR-049 Nr. 2. Die dokumentierte Extraktionsregel ist spec-konform. Eine Salienzregel braucht vor der Verwendung der Zahlen im Paper die Betreiberentscheidung, einen Builder-ADR, neue Golden-Daten und eine neue Abnahme von K-M1d-1/-2. Die derzeitigen Zahlen sind weiterhin Werte der dokumentierten Extraktionsregel. Daten, Parser und `llm-stability.Rmd` bleiben unverändert. |
| **E17 / BL-120** | **Akzeptiert und behoben.** Ref: K-M1d-7/BL-92, K-M1d-4. `vignettes/validation.Rmd:285` sortiert die Szenario-IDs für die Ausgabe der Konvergenz-Sensitivität. `vignettes/clinvar-raters.Rmd:130` verwendet `responseName = "submissions"` für die Häufigkeitsspalte. Der Helfer `inst/validation/m1d/findings.R`, die Kennzahlen, Auswahlregeln und Nenner bleiben unverändert. Prüfungen A und C belegen die Vignetten; das gerenderte Dokument zeigt S-ord-1, S-ord-2, S-ord-3, S-ord-4 und die Spalte `submissions`. BL-120 zur Prüfung und Schließung an den Reviewer; BACKLOG nicht geändert. |
| **E18 / QA-M1d-001 / BL-117** | **Nonblocking und nach dem 26.11.2026 zurückgestellt**, gemäß REVIEW und ADR-035. Es gibt keinen roten reproduzierenden Test. Die regulären Ergebnisleser prüfen die vollständigen Kennzahlen; die reine NA-Spalte scheitert benannt. Die zusätzliche Validierung manuell veränderter CSV-Dateien wird in dieser Runde nicht vorgezogen. `findings.R` bleibt unverändert. Der bestehende QA-M1d-FUZZ-2 ist laut Gate-Log Runde 1 grün; hier kein neuer QA-Lauf behauptet. |

E2 bis E15 aus PLAN-REVIEW sind laut REVIEW Runde 1 erledigt; diese Runde
ändert ihre fachliche Umsetzung nicht. Der historische
**M1D-QA-01 [QA-PENDING]** wurde in `45-qa` erledigt, wie REVIEW bestätigt.
Das gelesene Gate-Log belegt E2E mit 319 und Fuzz mit 94 bestandenen
Erwartungen (`:1919`, `:1951`); kein offener QA-PENDING-Auftrag.

Die bekannten zwei Warnungen aus **BL-93** bleiben **OUT-OF-TERRITORY**:
`gate-tests.log:782` und `:795` nennen die lme4-Helfer in
`tests/acceptance/test-m1b-4-two-levels.R:41–42`. Laut REVIEW kein
Produktbezug und kein Fehlschlag; die Abnahmepflege gehört dem Reviewer.

`mutgate` und `mutfull` sind laut ihren unveränderten Logs grün
(`kein geänderter Mutations-Scope`, `nicht fällig in M1d`, ADR-047).
Kein Mutationsbericht mit zu bearbeitenden Überlebenden dieser Runde,
kein neuer Mutationslauf, keine MUT-EQUIV-Claims und keine Approvals.

## Ausgeführte gezielte Prüfungen

Arbeitsverzeichnis der Befehle: Repositorywurzel. Vollständige lokale
Outputs und das Render-Skript liegen unter
`/tmp/llmsa-m1d-r2-cdsfmtsl/`. Für die folgenden Kommandos:

```sh
m1d_work=/tmp/llmsa-m1d-r2-cdsfmtsl
llmsa_root=/mnt/c/Users/Danie/dev/Llmsa/llmsa
```

### A. Unveränderte Vignetten-Abnahme — Exit 0

```sh
REPO_ROOT="$llmsa_root" TZ=Europe/Berlin NOT_CRAN=true \
  /usr/bin/time -f 'Vignette acceptance: %e seconds; exit %x' \
  Rscript --vanilla -e 'options(testthat.progress.max_fails = Inf); grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "^m1[abc]-[57]-vignette|^m1d-4-", load_package = "source", reporter = "summary", stop_on_failure = TRUE)' \
  > "$m1d_work/vignette-acceptance.log" 2>&1
```

Die sechs ausgewählten Dateien prüfen die numerische und latente
Validierung, den Vorrang vorhandener Vollläufe einschließlich
Bootstrap und die ClinVar-Vignette gegen unabhängige Werte und Anker.
Echter Abschluss des Testprozesses:

```text
══ DONE ════════════════════════════════════════════════════════════════════════
Vignette acceptance: 87.28 seconds; exit 0
```

### B. Unveränderte Abnahme K-M1d-5 — Exit 1, E1 [INFRA]

```sh
REPO_ROOT="$llmsa_root" TZ=Europe/Berlin NOT_CRAN=true \
  /usr/bin/time -f 'K-M1d-5 acceptance: %e seconds; exit %x' \
  Rscript --vanilla -e 'options(testthat.progress.max_fails = Inf); testthat::test_dir("tests/acceptance", filter = "^m1d-5-", load_package = "source", reporter = "summary", stop_on_failure = TRUE)' \
  > "$m1d_work/pkgdown-acceptance.log" 2>&1
```

Echte Fehlermeldungen aus dem Log, in Testreihenfolge:

```text
Expected _pkgdown.yml has an articles section to be TRUE.
Expected llm-stability is listed under articles to be TRUE.
Expected clinvar-raters is listed under articles to be TRUE.
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
K-M1d-5 acceptance: 5.10 seconds; exit 1
```

`python3 "$m1d_work/summarize.py"` zählt die tatsächlich ausgegebenen
SummaryReporter-Marker und Fehlermeldungen aus A und B (Exit 0):

```text
vignette-acceptance.log
  m1a-7-vignette: 148 passed expectations
  m1b-7-vignette-full-results: 204 passed expectations
  m1b-7-vignette: 240 passed expectations
  m1c-5-vignette-full-results: 49 passed expectations
  m1c-5-vignette: 55 passed expectations
  m1d-4-clinvar-vignette: 106 passed expectations
  SummaryReporter: 6 files; 802 passes; 0 failures; 0 warnings; 0 skips
Vignette acceptance: 87.28 seconds; exit 0
pkgdown-acceptance.log
  m1d-5-size-licence-network: 42 passed expectations
  SummaryReporter: 1 files; 42 passes; 3 failures; 0 warnings; 0 skips
K-M1d-5 acceptance: 5.10 seconds; exit 1
```

### C. HTML-Rendering und konkrete Darstellung — Exit 0

Das temporäre Skript lädt den Arbeitsbaum mit `pkgload::load_all()`
(`export_all = FALSE`, `helpers = FALSE`), entfernt `REPO_ROOT` für den
öffentlichen Validierungskontext und rendert Kopien beider Rmd-Dateien
mit `rmarkdown::render(output_options = list(keep_md = TRUE))`.
Alle Artefakte entstehen im temporären Verzeichnis.

```sh
TZ=Europe/Berlin /usr/bin/time -f 'Public rendering: %e seconds; exit %x' \
  Rscript --vanilla "$m1d_work/render-vignettes.R" "$llmsa_root" "$m1d_work" \
  > "$m1d_work/render.log" 2>&1
```

Echter Output:

```text
HTML render: validation completed in public context
HTML render: clinvar-raters completed in public context
Review-status columns: subset, review_status, submissions, retained
 subset                       review_status submissions retained
    hrf criteria provided, single submitter        5958     TRUE
    hrf                  flagged submission          14    FALSE
    hrf      no assertion criteria provided         675    FALSE
 sample criteria provided, single submitter        4479     TRUE
 sample                  flagged submission           6    FALSE
 sample      no assertion criteria provided         488    FALSE
 sample            reviewed by expert panel          37    FALSE
Public rendering: 28.64 seconds; exit 0
```

Zusätzlich ausgeführte Ausgabekontrolle:

```sh
sed -n '/### Ordinal convergence sensitivity/,/## Bootstrap intervals:/p' \
  "$m1d_work/validation.md" | rg '^S-ord-'
rg -n '\|subset.*review_status.*submissions.*retained' \
  "$m1d_work/clinvar-raters.md"
```

```text
S-ord-1
S-ord-2
S-ord-3
S-ord-4
137:|subset |review_status                       | submissions|retained |
```

Die HTML-Dateien enthalten dieselbe Reihenfolge und Tabellenüberschrift
(zusätzlich mit `rg` geprüft). Es wurde kein vollständiger Gate-Lauf oder
`R CMD check` in dieser Runde gestartet. Die Git-verwendenden
Abnahmepfade K-M1d-7/ACC-12 und K-M1d-8 bleiben beim Orchestrator;
die obigen lokalen Prüfungen behaupten keine vollständige Abnahme.

## Integrität und Übergabe

Vor der ersten Änderung wurden die SHA-256 von 430 Dateien in den
Paket-, Test-, Spezifikations-, Anker- und relevanten Harness-Pfaden
erfasst. `python3 "$m1d_work/integrity.py"` vergleicht diese Inventur,
meldet neue/entfernte Dateien und verlangt, dass ausschließlich die vier
zugewiesenen Änderungspfade betroffen sind. Echter Output (Exit 0):

```text
Inventory: 430 baseline files; 3 changed; 1 new; 0 removed; all assigned Builder paths
Changed: PROGRESS.md
Changed: vignettes/clinvar-raters.Rmd
Changed: vignettes/validation.Rmd
New: orchestrator/handoff/M1d/REWORK-NOTES.md
Preserved tests/: 127/127 byte-identical
Preserved R/: 14/14 byte-identical
Preserved man/: 21/21 byte-identical
Preserved data-raw/: 7/7 byte-identical
Preserved inst/extdata/: 24/24 byte-identical
Preserved inst/validation/sim/: 32/32 byte-identical
Preserved reference/anchors/: 46/46 byte-identical
Preserved orchestrator/gates.d/: 32/32 byte-identical
Preserved orchestrator/lib/: 5/5 byte-identical
Preserved: _pkgdown.yml
Preserved: orchestrator/state/M1d/gates.json
Preserved: orchestrator/state/M1d/gate-tests.log
Preserved: inst/validation/m1d/findings.R
Preserved: BACKLOG.md
Gate facts unchanged: round 1; result fail; error statuses 0
```

Diese Dateiinventur ersetzt nicht das Territoriums-Gate. Keine Git-Kommandos,
keine Abhängigkeitsinstallation, keine Änderungen an Tests, Gates, Schwellen,
Ankern, Golden-Daten oder Betreiber-Vollläufen. Kein neuer ADR erforderlich:
Die Ausgabeänderungen erfüllen E17 ohne fachliche Vertragsänderung.
Territoriumsprüfung, Phasen-Commit und vollständige Gates bleiben beim
Orchestrator; E1 bleibt mit den obigen Log-Belegen beim Betreiber.
