# REWORK-NOTES — M1d, Runde 5

Rolle: Builder · Phase: `60-rework` · Stand: 04.11.2026.

## Ergebnis und Ausgangslage

Die unveränderte Abnahmedatei **K-M1d-5 besteht mit 45 Erwartungen,
0 Fehlschlägen, 0 Warnungen und 0 Skips** (Exit 0). Die Betreiberergänzung
in `_pkgdown.yml` war bereits beim Beginn dieser Phase vorhanden;
Dateigröße und SHA-256 stimmen mit REVIEW Runde 4, Prüflauf 2, überein.
Damit ist die Ursache von E1 im aktuellen Arbeitsbaum lokal nicht mehr
reproduzierbar. Diese Runde ändert nur REWORK-NOTES und PROGRESS.

REVIEW und `verdict-code.json` der Runde 4 enthalten `blocking: []` und
verlangen für Runde 5 keine Produktänderung, auch nicht für E19.
Die unveränderten Gate-Fakten stammen weiterhin aus **Runde 4**:
`result: fail`, ausschließlich `tests` rot, sieben Gates `pass`, kein
Status `error`. Der lokale Prüflauf schreibt keine Gate-Fakten und nimmt
weder die Gates der Runde 5 noch das Reviewer-Verdict vorweg.

Gelesen: AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, die
M1d-Einträge in PROGRESS, REVIEW, Verdict, CRITERIA einschließlich
ACC-1 bis ACC-20, Gate-Fakten und die Fehler-/Warnungsberichte des roten
tests-Logs, bisherige REWORK-NOTES, LESSONS, die einschlägigen
Spezifikationen und der unveränderte Abnahmetest K-M1d-5. Ergänzend:
QA-M1d-001, die Backlog-Verweise des Reviews, ADR-035, ADR-047,
ADR-048 Nr. 15 und ADR-049. Eine `orchestrator/handoff/M1d/ARBITER.md`
liegt nicht vor. Die numerische Randfall-Lehre in LESSONS ergibt hier
keinen weiteren Produktauftrag.

## Antworten auf die Befund-IDs

| ID | Antwort, Dateien und Beleg |
| --- | --- |
| **E1 / M1D-INFRA-01 / BL-118** | **OUT-OF-TERRITORY [INFRA]; Betreiberergänzung in der Phasenbasis vorhanden, lokal erfolgreich geprüft.** Ref: K-M1d-5 (`docs/02-statistikkern.md:89`), ACC-8(5), ADR-048 Nr. 15, Gate tests Runde 4. Dessen `gate-tests.log:1189–1207` und `:1831–1849` belegen die drei Listungsfehler in `tests/acceptance/test-m1d-5-size-licence-network.R:97,99`. Jetzt enthält `_pkgdown.yml:36–43` die Einträge `validation`, `llm-stability` und `clinvar-raters`. Die vollständige unveränderte Abnahmedatei besteht mit 45 Erwartungen (Prüfung unten). `_pkgdown.yml` wurde vom Builder weder geschrieben noch ersetzt. BL-118 kann der Reviewer nach einem grünen tests-Gate schließen; ein Gate-Ergebnis der Runde 5 wird hier nicht behauptet. |
| **E16 / BL-119** | **Zurückgestellt wie verlangt; keine Änderung in M1d.** Ref: ACC-2(3), ADR-049 Nr. 2. Die im Review bestätigte Etikettenregel bleibt bestehen. Betroffene Dateien: `inst/validation/m1d/prepare.R`, `data-raw/make_llm_stability.R`, `inst/extdata/llm-stability_2026-10-22/` und `vignettes/llm-stability.Rmd`. Vor Verwendung der Zahlen im Paper entscheidet der Betreiber über die Salienzregel; eine Umstellung braucht den in BL-119 beschriebenen ADR-, Golden- und Abnahmeweg. |
| **E18 / QA-M1d-001 / BL-117** | **Nonblocking, nach dem 26.11.2026 zurückgestellt**, gemäß REVIEW Runde 4 und ADR-035. Kein roter reproduzierender Test. Ref: QA.md QA-M1d-001; `gate-tests.log:1943` der Runde 4 belegt `m1d-qa-fuzz` mit 51 Erwartungen. Die Härtung für manuell veränderte CSV-Dateien bleibt das spätere Arbeitspaket. `inst/validation/m1d/findings.R` bleibt unverändert; kein neuer QA-Lauf behauptet. |
| **E19 / BL-121** | **Nonblocking, nach dem 26.11.2026 zur Release-Arbeit zurückgestellt**, ausdrücklich gemäß REVIEW Runde 4. Ref: REVIEW Runde 3, Prüflauf 2; `_pkgdown.yml:1`; `DESCRIPTION:20`. Die Seiten-URL fehlt weiterhin im URL-Feld von DESCRIPTION. Der Reviewer-Beleg lautet: `In DESCRIPTION, URL is missing package url (https://danielmoj.github.io/llmsa).` Die Betreiberergänzung zu E1 ändert daran nichts. Später ergänzt der Builder die Seiten-URL in DESCRIPTION und führt `check_pkgdown()` erneut aus. In dieser Runde keine Änderung und kein eigener pkgdown-Prüflauf. |
| **E17 / BL-120** | **Bereits in Runde 2 erledigt, durch REVIEW Runde 4 erneut bestätigt.** `vignettes/validation.Rmd:285` sortiert die Szenarien; `vignettes/clinvar-raters.Rmd:131` verwendet `responseName = "submissions"`. Beide Stellen wurden gelesen. Das Gate-Log der Runde 4 belegt 106 Erwartungen für `m1d-4-clinvar-vignette` (`:1182`) und 512 für `m1d-7-findings` (`:1686`); `gate-lint.log:89` meldet `Status: OK`. Keine weitere Änderung und kein neuer Render-Lauf. |

**E2 bis E15** sind laut REVIEW bereits erledigt. Der historische
**M1D-QA-01 [QA-PENDING]** ist durch `45-qa` erledigt; kein offener
QA-PENDING-Auftrag. Das Gate-Log der Runde 4 belegt E2E mit 319 und
Fuzz mit 94 bestandenen Erwartungen (`:1920`, `:1952`).

**BL-93 bleibt OUT-OF-TERRITORY (Reviewer).** Die zwei bekannten
Warnungen aus `tests/acceptance/test-m1b-4-two-levels.R:41–42`
stehen in `gate-tests.log:778–803` der Runde 4:

```text
the 'nobars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
the 'findbars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
```

Laut REVIEW kein Produktbezug und kein Fehlschlag. Abnahmetests und
Abhängigkeiten bleiben unverändert; BACKLOG wird vom Reviewer gepflegt.

## Tatsächlich ausgeführte Prüfungen

Arbeitsverzeichnis jeweils `/mnt/c/Users/Danie/dev/Llmsa/llmsa`.

**Vorhandene Betreiberergänzung:**

```sh
sha256sum _pkgdown.yml
wc -c _pkgdown.yml
```

Echter Output, jeweils Exit 0:

```text
7e465e038e78aa7b5cd90c2caebd909c74ab588298a1a765a594c00c12c3b671  _pkgdown.yml
703 _pkgdown.yml
```

Dies entspricht genau der Bytefolge aus REVIEW Runde 4, „An den Betreiber“,
Nr. 1. Die Datei lag schon bei der Inventur vor dem Prüflauf so vor.
Es wurde keine temporäre YAML-Ersetzung für den Test vorgenommen.

**Vollständige unveränderte Abnahmedatei K-M1d-5:**

```sh
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa TZ=Europe/Berlin NOT_CRAN=true \
  /usr/bin/time -f 'K-M1d-5 acceptance: %e seconds; exit %x' \
  Rscript --vanilla -e 'options(testthat.progress.max_fails = Inf); testthat::test_dir("tests/acceptance", filter = "^m1d-5-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)' \
  > /tmp/llmsa-m1d-r5-3pltfgx8/pkgdown-acceptance.log 2>&1
```

Echter Output (Auszug), Exit **0**:

```text
✔ |         45 | m1d-5-size-licence-network [3.9s]
Duration: 3.9 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]
K-M1d-5 acceptance: 5.77 seconds; exit 0
```

Alle sechs Testblöcke laufen, einschließlich Größen-, Lizenz-, INSAID-,
Listungs- und Netzprüfung. Der Vignettenbau gehört weiterhin zum lint-Gate;
dieser gezielte Lauf ersetzt ihn nicht. Ein vollständiger Gate-Lauf oder
Paketcheck wurde bei diesen reinen Handoff-Änderungen nicht wiederholt.
Die Git-verwendenden Abnahmepfade bleiben beim Orchestrator.

Die gelesenen Mutationslogs der Runde 4 melden:

```text
mutgate: pass (kein geänderter Mutations-Scope)
mutfull: pass (nicht fällig in M1d)
```

ADR-047 gilt weiter. Kein rotes Mutationsgate, keine zu bearbeitenden
Überlebenden dieser Runde, kein eigener Mutationslauf oder Score.
Keine neuen Tests, MUT-EQUIV-Claims oder Approvals.

## Integrität und Übergabe

Die SHA-256-Inventur vor der Prüfung erfasst 462 Dateien aus Paket-,
Test-, Spezifikations-, Anker- und relevanten Harness-Pfaden.
Abschlusskontrolle:

```sh
python3 /tmp/llmsa-m1d-r5-3pltfgx8/integrity.py
```

Echter Output (Exit 0):

```text
Inventory: 462 baseline files; 2 changed; 0 new; 0 removed
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1d/REWORK-NOTES.md
All 460 other inventoried files are byte-identical
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
Gate facts unchanged: round 4; result fail; error statuses 0
Current review IDs addressed: E1, E16, E18, E19
Earlier PROGRESS entries preserved byte for byte
```

Kein neuer ADR erforderlich. Keine Git-Kommandos und keine
Abhängigkeitsinstallation. Die Inventur ersetzt kein Territoriums-Gate.
Territoriumsprüfung, Phasen-Commit, Gates der Runde 5 und Abnahme folgen
durch die zuständigen Rollen. E1 ist lokal erfolgreich nachgeprüft;
E16, E18 und E19 bleiben mit ihren bestehenden Backlog-Aufträgen vertagt.
