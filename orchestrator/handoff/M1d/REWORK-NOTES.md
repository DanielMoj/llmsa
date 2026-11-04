# REWORK-NOTES — M1d, Runde 4

Rolle: Builder · Phase: `60-rework` · Stand: 04.11.2026.

## Ausgangslage und Umfang

`REVIEW.md` und `verdict-code.json` der Runde 3 enthalten
`blocking: []`. Das Review verlangt für Runde 4 ausdrücklich keine Änderung
an Produkt, DESCRIPTION, Vignetten, Daten oder Tests, auch nicht für E19.
Die gelesenen Gate-Fakten sind ebenfalls Runde 3: `result: fail`,
ausschließlich `tests` rot, sieben Gates `pass`, kein Status `error`.
Ursache sind weiterhin die drei Erwartungen zur Artikelliste in
`_pkgdown.yml` (E1). Der Gate-Status bleibt `fail`; die Zuordnung als
`[INFRA]` folgt REVIEW und ADR-048 Nr. 15.

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, die
M1d-Einträge in PROGRESS, REVIEW, Verdict, CRITERIA mit ACC-1 bis ACC-20,
Gate-Fakten und Fehler-/Warnungsberichte des roten tests-Logs, LESSONS,
die einschlägigen Spezifikationen und der unveränderte Abnahmetest
K-M1d-5. Zusätzlich: bisherige REWORK-NOTES, QA, die Backlog-Verweise im Review,
ADR-035, ADR-047, ADR-048 Nr. 15 und ADR-049. Eine
`orchestrator/handoff/M1d/ARBITER.md` liegt nicht vor. Die numerische
Randfall-Lehre in LESSONS ergibt hier keinen zusätzlichen Produktauftrag.

Diese Runde aktualisiert nur diesen zugewiesenen Handoff und PROGRESS.
Die Belege aus Runde 3 bleiben im bisherigen PROGRESS-Eintrag und im
REVIEW erhalten.

## Antworten auf die Befund-IDs

| ID | Antwort, Dateien und Beleg |
| --- | --- |
| **E1 / M1D-INFRA-01 / BL-118** | **OUT-OF-TERRITORY [INFRA].** Ref: K-M1d-5 (`docs/02-statistikkern.md:89`), ACC-8(5), ADR-048 Nr. 15, Gate tests Runde 3. `_pkgdown.yml` enthält weiterhin keinen Abschnitt `articles`. `gate-tests.log:1192–1210` und `:1830–1851` belegen genau die drei Listungsfehler in `tests/acceptance/test-m1d-5-size-licence-network.R:97,99`. Die gezielte unveränderte Abnahme dieser Runde reproduziert sie mit 42 bestandenen Erwartungen, ohne Warnung oder Skip (Prüfung unten). Die Datei gehört dem Betreiber; keine Reparatur im Produktcode und keine Änderung an Test oder Schwelle. Konkrete erforderliche Ergänzung unten. |
| **E16 / BL-119** | **Zurückgestellt wie im Review verlangt; keine Änderung in M1d.** Ref: ACC-2(3), ADR-049 Nr. 2. Die im Review als spec-konform bestätigte Etikettenregel bleibt bestehen. `inst/validation/m1d/prepare.R`, `data-raw/make_llm_stability.R`, `inst/extdata/llm-stability_2026-10-22/` und `vignettes/llm-stability.Rmd` werden nicht geändert. Vor einer Verwendung der Zahlen im Paper entscheidet der Betreiber über die Salienzregel; eine Umstellung braucht den in BL-119 beschriebenen ADR-, Golden- und Abnahmeweg. |
| **E17 / BL-120** | **Bereits in Runde 2 erledigt, durch REVIEW Runde 3 erneut bestätigt.** `vignettes/validation.Rmd:285` verwendet `sort(unique(sensitivity$tables$scenario))`; `vignettes/clinvar-raters.Rmd:131` verwendet `responseName = "submissions"`. Beide Stellen wurden gelesen. Gate tests Runde 3 belegt 106 Erwartungen für `m1d-4-clinvar-vignette` (`:1185`) und 512 für `m1d-7-findings` (`:1685`); lint meldet `Status: OK` (`gate-lint.log:89`). In dieser Runde keine weitere Änderung und kein neuer Render-Lauf. |
| **E18 / QA-M1d-001 / BL-117** | **Nonblocking, nach dem 26.11.2026 zurückgestellt**, gemäß REVIEW Runde 3 und ADR-035. Es gibt keinen roten reproduzierenden Test. Ref: QA.md QA-M1d-001; Gate tests Runde 3 `:1941` (`m1d-qa-fuzz`, 51 Erwartungen). Die zusätzliche Validierung manuell veränderter CSV-Dateien bleibt das spätere Arbeitspaket. `inst/validation/m1d/findings.R` bleibt unverändert; kein neuer QA-Lauf behauptet. |
| **E19 / BL-121** | **Nonblocking, nach dem 26.11.2026 zur Release-Arbeit zurückgestellt**, ausdrücklich gemäß REVIEW Runde 3. Ref: dessen Prüflauf 2, `_pkgdown.yml:1`, `DESCRIPTION:20`. Die Seiten-URL `https://danielmoj.github.io/llmsa/` fehlt weiterhin im URL-Feld von DESCRIPTION. REVIEW belegt die Meldung von `pkgdown::check_pkgdown()` mit „In DESCRIPTION, URL is missing package url (https://danielmoj.github.io/llmsa).“ und beim Seitenbau „URLs not ok.“ ohne Abbruch. Kein M1d-Kriterium; beide Dateien bleiben in dieser Runde unverändert. Später ergänzt der Builder die Seiten-URL in DESCRIPTION und prüft erneut. Der pkgdown-Prüflauf wird hier nicht als eigener Lauf behauptet. |

**E2 bis E15** sind laut REVIEW bereits erledigt. Der historische
**M1D-QA-01 [QA-PENDING]** wurde in `45-qa` erledigt; kein offener
QA-PENDING-Auftrag. Das bestehende Gate-Log der Runde 3 belegt E2E mit
319 und Fuzz mit 94 bestandenen Erwartungen (`:1917`, `:1950`).

**BL-93 bleibt OUT-OF-TERRITORY (Reviewer).** Die zwei bekannten
Warnungen im Gate-Log (`:779–804`) stammen aus
`tests/acceptance/test-m1b-4-two-levels.R:41–42`:

```text
the 'nobars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
the 'findbars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
```

Laut REVIEW kein Produktbezug und kein Fehlschlag; Abnahmetest und
Abhängigkeiten bleiben unverändert. BACKLOG wird nicht vom Builder gepflegt.

## Betreiberübergabe zu E1

Erforderliche Ergänzung von `_pkgdown.yml` nach REVIEW Runde 3,
„An den Betreiber“, Nr. 1, und ADR-048 Nr. 15:

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

Die vorhandenen Schlüssel bleiben erhalten. Auch `validation` gehört
gemäß ADR-048 in den Index. REVIEW Runde 3, Prüflauf 2, belegt bereits die
Wirkung dieser Ergänzung auf einer Paketkopie: 45 bestandene Erwartungen
und ein vollständiger Artikelindex. Das ist der Beleg des Reviewers,
kein eigener neuer Lauf und keine Behebung im Arbeitsbaum.

Der Betreiber setzt die Ergänzung außerhalb einer laufenden Modellphase
als Basis einer folgenden Modellphase um; Ablauf und Rundenmarker-Fallen
stehen im REVIEW, Abschnitt „An den Betreiber“, Nr. 1. Kein Eingriff
zwischen Rework und Gates (BL-106). Diese Runde schreibt weder
`_pkgdown.yml` noch STOP, Rundenmarker oder sonstigen Orchestrator-Zustand.
Der Eintrag behebt ausschließlich E1; E19 bleibt wie verlangt vertagt.

## Tatsächlich ausgeführte gezielte Prüfung

Arbeitsverzeichnis: Repositorywurzel. Unveränderte Abnahmedatei
`tests/acceptance/test-m1d-5-size-licence-network.R`, vollständig
ausgeführt. Befehl:

```sh
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa TZ=Europe/Berlin NOT_CRAN=true \
  /usr/bin/time -f 'K-M1d-5 acceptance: %e seconds; exit %x' \
  Rscript --vanilla -e 'options(testthat.progress.max_fails = Inf); testthat::test_dir("tests/acceptance", filter = "^m1d-5-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)' \
  > /tmp/llmsa-m1d-r4-f1rjqj2b/pkgdown-acceptance.log 2>&1
```

Exit **1**, echter Output (Auszug; die drei Erwartungen gehören zu einem
Testblock):

```text
Expected _pkgdown.yml has an articles section to be TRUE.
Expected llm-stability is listed under articles to be TRUE.
Expected clinvar-raters is listed under articles to be TRUE.
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
K-M1d-5 acceptance: 5.76 seconds; exit 1
```

Damit ist E1 weiterhin reproduziert, nicht behoben. Größen-, Lizenz-,
INSAID- und Netzprüfungen derselben Abnahmedatei bestehen. Ein neuer
vollständiger Gate-Lauf, Paketcheck oder die Git-verwendenden Abnahmepfade
wurden nicht gestartet. Dafür besteht bei reinen Handoff-Änderungen kein
zusätzlicher Prüfbedarf; die vollständigen Gates bleiben beim Orchestrator.

Die gelesenen Mutationslogs der Runde 3 melden:

```text
mutgate: pass (kein geänderter Mutations-Scope)
mutfull: pass (nicht fällig in M1d)
```

ADR-047 gilt weiter. Kein rotes Mutationsgate und kein neuer Bericht mit
zu bearbeitenden Überlebenden; kein Mutationslauf, keine neuen Tests,
keine MUT-EQUIV-Claims und keine Approvals in dieser Runde.

## Integrität und Übergabe

Vor der Prüfung wurden 445 Dateien aus Paket-, Test-, Spezifikations-,
Anker- und relevanten Harness-Pfaden mit SHA-256 inventarisiert.
Die abschließende Kontrolle verwendet:

```sh
python3 /tmp/llmsa-m1d-r4-f1rjqj2b/integrity.py
```

Echter Output (Exit 0):

```text
Inventory: 445 baseline files; 2 changed; 0 new; 0 removed
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1d/REWORK-NOTES.md
All 443 other inventoried files are byte-identical
Preserved tests/: 127/127 byte-identical
Preserved R/: 14/14 byte-identical
Preserved vignettes/: 4/4 byte-identical
Preserved inst/extdata/: 24/24 byte-identical
Preserved inst/validation/sim/: 32/32 byte-identical
Preserved reference/anchors/: 46/46 byte-identical
Preserved orchestrator/gates.d/: 32/32 byte-identical
Preserved: _pkgdown.yml
Preserved: DESCRIPTION
Preserved: inst/validation/m1d/findings.R
Preserved: BACKLOG.md
Preserved: orchestrator/state/M1d/gates.json
Preserved: orchestrator/state/M1d/gate-tests.log
Gate facts unchanged: round 3; result fail; error statuses 0
Current review IDs addressed: E1, E16, E18, E19
Earlier PROGRESS entries preserved byte for byte
```

Die Inventur ersetzt kein Territoriums-Gate. Keine Git-Kommandos,
Abhängigkeitsinstallation, Änderungen an Tests, Gates, Schwellen, Ankern,
Golden-Daten oder Betreiber-Vollläufen. Kein neuer ADR erforderlich.
E1 bleibt mit Log-Belegen OUT-OF-TERRITORY; Territoriumsprüfung,
Phasen-Commit, Gate-Lauf und Abnahme folgen durch die zuständigen Rollen.
