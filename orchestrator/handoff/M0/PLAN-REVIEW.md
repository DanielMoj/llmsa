# PLAN-REVIEW — M0, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Stand: 25.10.2026 · Gegenstand: `orchestrator/handoff/M0/PLAN.md` (Runde 1). Es gibt keine `PLAN-UPDATE.md` und keine `ARBITER.md`; Einwand-IDs aus Vorrunden gibt es nicht.

## Gelesen

`AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `docs/01-fachspezifikation.md` (vollständig, insbesondere §2, §4, §9, §10 mit K-M0-1 bis K-M0-7), `CRITERIA.json`, `PLAN.md`, `orchestrator/LESSONS.md` (keine Lehren), `BACKLOG.md`, `PROGRESS.md`, `orchestrator/milestones.json` und `projektierung/SPEC-KONTRAKT.md`. Außerdem `projektierung/presets/r-paket/PRESET.md`, alle Abnahmetests und Setup-Dateien unter `tests/acceptance/`, die Anker ANK-01, ANK-02 und ANK-03 sowie die aktiven Gates `orchestrator/gates.d/{10,20,30,70,82,86,87,88}-*.sh` mit `_lib.sh`. Dazu kamen `orchestrator/verifier.sh`, `orchestrator/lib/r-{deps,tests,mutation}.R`, `orchestrator/lib/r-check.sh`, die Projektzeilen in `orchestrator/config.env` und in `orchestrator/orchestrate.sh` die Funktionen `path_allowed`, `ownership_check`, `verdict`, `run_ms` und die DONE-Prüfung. Schließlich das ACCEPTANCE-Log und das Ende des PLAN-Logs.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

1. `sha256sum R/*.R`: Alle 13 Werte gleichen ANK-01, von `eeb92e3b…` (`R/agreement.R`) bis `3352d768…` (`R/utils.R`). Das bestätigt die Inventur des Builders unabhängig.
2. Die Versionen per `Rscript` gemeldet: testthat 3.3.2, pkgload 1.5.3, jsonlite 2.0.0, lme4 2.0.6, ordinal 2026.7.26, DBI 1.3.0, ellmer 0.5.0, httr2 1.3.0, knitr 1.52, rmarkdown 2.32, RSQLite 3.53.3, muttest 0.3.0, R6 2.6.1, digest 0.6.39 (R 4.6.1). Pandoc 3.7.0.2 ist verfügbar. `qpdf`, `jq`, `git` und `timeout` liegen in `/usr/bin`; `tidy` fehlt, was nur eine NOTE erzeugt. Damit sind alle Pakete aus `DESCRIPTION` (Depends, Imports, Suggests) und die Wrapper-Voraussetzungen `pkgload`/`testthat` vorhanden.
3. Vorab-Check außerhalb des Repos: Die Paketdateien (`DESCRIPTION`, `NAMESPACE`, `LICENSE*`, `README.md`, `NEWS.md`, `.Rbuildignore`, `R/`, `man/`, `data/`, `inst/`, `vignettes/`, `tests/testthat/`, `tests/testthat.R`) wurden nach `/tmp/m0-review-check-073405` kopiert. `R CMD build --no-manual` lief mit rc 0 in 12 s. `R CMD check --as-cran --no-manual` lief mit `_R_CHECK_CRAN_INCOMING_REMOTE_=false` und rc 0 in 49 s; die letzte Zeile lautete `Status: OK`. Das ist **kein** Gate-Beleg für K-M0-3: Das lint-Gate baut den `git ls-files`-Export, und erst `gate-lint.log` entscheidet. Der Lauf zeigt aber, dass der unveränderte Bestand v0.1.0 voraussichtlich ohne ERROR und WARNING durchläuft. Das Risiko „unbehebbare WARNING in `R/`“ ist damit gering.
4. Jeder `pkg::`-Aufruf in `R/`, `tests/testthat/` und `vignettes/` nennt ein in `DESCRIPTION` deklariertes Paket. Die Tests unter `tests/testthat/` schreiben nur in `tempfile()` und plotten nicht.
5. `.github/workflows/pkgdown.yaml` setzt `dest_dir = "pkgdown-site"` und `folder: pkgdown-site`; die Aussage des PLANs zu BL-19 stimmt.
6. Die Angaben in R-M0-5 stimmen. `orchestrate.sh:614` begrenzt nur Modellaufrufe mit `PHASE_TIMEOUT`. `:750` ruft den Verifier ohne Timeout auf. `r-check.sh:27–29` begrenzt Build und Check über `R_CHECK_TIMEOUT`.

## Bewertung

### Spec-Treue

Der Plan beschränkt den Builder-Diff in BUILD auf `PROGRESS.md`. Das deckt §10: „M0 ändert `R/` nicht. Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“ `R/`, `DESCRIPTION`, `NAMESPACE`, `tests/testthat/` und `inst/` bleiben unberührt. Auch die Betreiberaufgaben (pkgdown-Umstellung, `.Rbuildignore`-Harness-Zeilen, `tests/testthat.R`, Gates) bleiben beim Betreiber. Es gibt keine Abweichung von der Spec.

### Architektur und Verträge

Die Schnittstellen bleiben unverändert. Die Obermengenprüfung beschreibt der Plan korrekt nach §4 und K-M0-7: Position, Name und `deparse`-Vorgabewert werden geprüft, ein fehlender Vorgabewert bleibt von `NULL` unterscheidbar, und zusätzliche Exporte und Argumente am Ende sind erlaubt. Der Plan hält das Rollenprotokoll ein: keine Gate-, Git-, Anker- oder Testeingriffe, Belege nur mit echtem Output. Der PLAN enthält die Pflichtabschnitte nach SCHEMA.md in der richtigen Reihenfolge.

### Vollständigkeit

Der Plan ordnet alle sieben Kriterien einem Prüfweg und einer Testdatei zu. ACC-1 bis ACC-3 sind berücksichtigt. Alle 52 Backlog-IDs sind einzeln behandelt oder begründet vertagt. Die Vertagungen sind sachlich richtig, denn §10 schließt Produktarbeit in M0 aus. Die vom Builder belegte Vorprüfung trennt sauber, was geprüft wurde und was nicht: Die Formals sind nicht ausgewertet, Git-Semantik und Gates sind nicht ausgeführt.

### Risiken

R-M0-1 bis R-M0-5 und PLAN-M0-INFRA-01 sind zutreffend, belegt und richtig zugeordnet. Für einen Fehler im unveränderlichen Bestand gibt der Plan den richtigen Umgang vor: Er wird belegt und an die zuständige Rolle gegeben; es gibt keinen Codefix und keinen geänderten Hash. Die Nachprüfung 3 senkt das Risiko für K-M0-3 zusätzlich. Ergänzungen dazu stehen in E1 und E2.

### Offene Punkte ACC-1 bis ACC-3: Reviewer-Entscheidung

| ID | Entscheidung | ADR |
| --- | --- | --- |
| ACC-1 (K-M0-4) | Bis `orchestrator/state/M0/8-done.done` existiert, wird der Arbeitsbaum geprüft, danach der Baum des Tags `done/M0`. Es gibt kein `skip`; ein fehlender Tag ist ein benannter Fehlschlag. | `docs/decisions/ADR-001-k-m0-4-pruefgegenstand-nach-m0.md` |
| ACC-2 (K-M0-5) | „leer“ heißt Exit 1 ohne Ausgabe, „nicht leer“ heißt Exit 0 mit genau dem Pfad, jeder andere Status scheitert. Für `docs/00-vision.md` gilt zusätzlich `--no-index`. | `docs/decisions/ADR-002-k-m0-5-git-check-ignore-auslegung.md` |
| ACC-3 (K-M0-2) | Gezählt werden `test_that()`-Blöcke einschließlich Skips (Zeilen von `as.data.frame()`), mindestens `ANK-03.value`. Neue Skips zum Erreichen der Grenze sind eine Abschwächung. | `docs/decisions/ADR-003-k-m0-2-testzaehlung.md` |

Alle drei ADRs bestätigen die Auslegung, die die Abnahmetests bereits umsetzen. Tests, Anker und Plan müssen dafür nicht geändert werden. Wie der Builder die Punkte im PLAN behandelt, ist damit vereinbar. Für den Builder bleiben sie nonblocking.

### Gate-Abdeckung (BL-48, vom Reviewer geprüft)

Die Zuordnung im Testplan des PLANs ist richtig und vollständig. Jedes aktive Gate trägt mindestens ein Kriterium (§9):

| Gate | M0-Kriterien | Beleg in der Abnahme |
| --- | --- | --- |
| `10-deps` | K-M0-1, K-M0-6 | `gate-deps.log` mit den Versionen; Zusatztest `test-m0-deps.R` |
| `20-lint` | K-M0-3, K-M0-6 | `gate-lint.log`, Zeile `Status:` ohne ERROR und WARNING |
| `30-tests` | K-M0-2; trägt als Läufer die Test-Kriterien K-M0-4, K-M0-5, K-M0-7 sowie die Zusatztests zu K-M0-1 und K-M0-6; K-M0-6 | `gate-tests.log` (Zahl der Tests, Fehlschläge, Fehler, Skips) |
| `70-trace` | K-M0-6 | Kurzbefund „alle Kriterien sind wörtlich und beidseitig verknüpft“ |
| `82-territory` | K-M0-6 | Audit der Runde 1 mit Basis gleich `HEAD^` |
| `86-mutgate` | K-M0-6 | Kurzbefund wörtlich `mutgate: pass (kein geänderter Mutations-Scope)` |
| `87-golden-adr` | K-M0-6, K-M0-7 (Satz 2) | `golden-adr: keine Golden-/Ankeränderung` |
| `88-mutfull` | kein M0-Kriterium; K-M1c-6 (§9: „nur M1c“) | in M0 `mutfull: pass (nicht fällig in M0)`; ein `fail`/`error` dort machte `result` rot |

Im Code-Review gelten folgende Maßstäbe. `orchestrator/state/M0/gates.json` muss `round` 1, `base` gleich dem SHA von `plan/M0`, `env.sha` gleich HEAD und `result` gleich `pass` melden, dazu die sieben Gates aus K-M0-6 mit `pass` und den mutgate-Kurzbefund wörtlich wie oben. Der Diff seit `plan/M0` darf im Builder-Territorium nur `PROGRESS.md` berühren. `R/` muss gleich ANK-01 bleiben.

## Einwände

### Blocking

Keine.

### Minor (nonblocking)

- [E1] (minor) `orchestrator/orchestrate.sh:1052–1053` („kann nicht DONE werden: PROGRESS.md wurde seit plan/$ms nicht aktualisiert“); PLAN, Reihenfolge Nr. 3 — Befund: DONE setzt eine Änderung an `PROGRESS.md` seit `plan/M0` voraus. Der Plan lässt den Inhalt davon abhängen, ob Diagnosen ausgeführt wurden („Nur ausgeführte Diagnosen mit Output in PROGRESS.md aufnehmen“). Bleibt die Datei in BUILD unverändert, endet M0 trotz grüner Gates FATAL. Endet das Code-Review in Runde 1 mit PASS, gibt es nach den Gates keine Builder-Phase mehr; der Satz im Testplan zu K-M0-2 („Skips und Testzahl aus dem aktuellen Lauf berichten“) erfüllt sich dann nur über `gate-tests.log` und `REVIEW.md`. — Vorschlag: In BUILD `PROGRESS.md` auf jeden Fall fortschreiben. Hinein gehören der M0-Umfang, mindestens die gitfreie ANK-01-Prüfung mit echtem Output und die ausdrücklich offenen Gates. Gate-Ergebnisse dürfen dort erst stehen, wenn `gates.json` sie enthält.
- [E2] (minor) `projektierung/presets/r-paket/PRESET.md`, Abschnitt „Artefakte“; `orchestrator/orchestrate.sh` `commit_phase` (`git add -A`) — Befund: Diagnosen im Checkout können Artefakte hinterlassen, etwa durch `R CMD build .`/`check`, einen testthat-Lauf im Arbeitsbaum (`_snaps`) oder `Rplots.pdf`. Solche Dateien landen entweder im Phasen-Commit oder lösen eine Territoriumsverletzung aus. Die geplanten Diagnosen sind lesend; der Plan sagt das aber nicht als Regel. — Vorschlag: BUILD-Diagnosen nur lesend oder unter `/tmp` ausführen. Keine Builds, Checks oder Testläufe im Checkout; einen Check nur auf einer Kopie außerhalb des Repos (wie Nachprüfung 3).
- [E3] (minor) [INFRA] `docs/01-fachspezifikation.md` §9 („Gates (Begründung in `gates-auswahl.md`)“; „jedes Gate trägt mindestens ein Kriterium (Zuordnung in `gates-auswahl.md`)“); BL-48 — Befund: Die Datei fehlt im Repo, auch unter den ignorierten Pfaden. `orchestrator/config.env:136` verweist auf `projektierung_llmsa/gates-auswahl.md` außerhalb des Repos. Die vom Builder vorgelegte Zuordnung ist richtig und oben vom Reviewer bestätigt. — Vorschlag: Der Betreiber legt `gates-auswahl.md` ins Repo oder berichtigt den Verweis. Der Reviewer trägt die bestätigte M0-Zuordnung in `50-code-review` in BL-48 nach; `BACKLOG.md` liegt in `30-plan-review` nicht im Reviewer-Territorium. Für den Builder ist nichts zu tun.
- [E4] (minor) `docs/01-fachspezifikation.md` §4 („Ohne ADR erlaubt: … neue Argumente mit Vorgabewert am Ende der Argumentliste“) gegen K-M0-7 („zusätzliche Argumente hinter den Snapshot-Argumenten bestehen den Test“) — Befund: Die Obermengenprüfung lässt, dem Wortlaut von K-M0-7 entsprechend, angehängte Argumente auch ohne Vorgabewert passieren. Ohne ADR erlaubt §4 nur solche mit Vorgabewert. Das ist kein Widerspruch, denn der Test ist notwendig, aber nicht hinreichend. Für M0 ist es ohne Belang, weil M0 keine Argumente ergänzt. — Vorschlag: Ab M2 prüft der Reviewer im Code-Review die Vorgabewerte neuer angehängter Argumente. Plan und Builder müssen nichts ändern.

## Verdict

**PASS.** Es gibt keinen blocking-Befund. Der Plan hält sich an die Spec, ist vollständig, schätzt die Risiken richtig ein und deckt alle Gates ab. ACC-1 bis ACC-3 sind durch ADR-001 bis ADR-003 entschieden. E1 bis E4 sind nonblocking; E1 und E2 sind Hinweise für BUILD, E3 und E4 betreffen Betreiber und Reviewer.
