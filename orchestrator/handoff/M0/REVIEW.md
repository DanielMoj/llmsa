# REVIEW — M0, Runde 1 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde 1, Versuch 2 · Stand: 25.10.2026 · Gegenstand: Diff seit `plan/M0` (Tag-Objekt `48ac0c14…` → Commit `6783f2874340…`) bis HEAD `506eaec8bb9c…` sowie die Gate-Fakten `orchestrator/state/M0/gates.json` der Runde 1.

Den ersten Versuch dieser Phase hat der Orchestrator verworfen (`orchestrate.log`, 08:10:07). Während der Phase waren `reference/quellen/data/aiag/anova_example.csv` und `reference/quellen/data/aiag/QUELLE.txt` entstanden. Sie stammen nicht aus der Reviewer-Rolle; Inhalt und Herkunftsvermerk (im Log von Versuch 1 wiedergegeben) weisen sie als Datenvorbereitung des Betreibers zu BL-42 aus. Der Rollback hat beide gelöscht. Dieser Versuch schreibt nur `orchestrator/handoff/M0/REVIEW.md`, `orchestrator/handoff/M0/verdict-code.json` und `BACKLOG.md`. Die nötige Wiederherstellung durch den Betreiber beschreibt der Abschnitt „Benötigte fremde Änderung“ (E6).

## Gelesen

`AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `CRITERIA.json`, `PLAN.md`, `PLAN-REVIEW.md` und `verdict-plan.json`. Es gibt keine `PLAN-UPDATE.md`, `ARBITER.md`, `QA.md`, `REVIEW-INPUT.md` und `MUT-EQUIV.json`. Dazu `docs/01-fachspezifikation.md` (§2, §4, §9, §10 mit K-M0-1 bis K-M0-7), ADR-001 bis ADR-003, die Anker ANK-01 bis ANK-03, alle Abnahmetests und Setup-Dateien unter `tests/acceptance/`, `PROGRESS.md`, `BACKLOG.md` und `orchestrator/LESSONS.md` (keine Lehren). Ferner `gates.json` mit allen acht `gate-*.log`, die Gates `70-trace`, `82-territory`, `86-mutgate`, `87-golden-adr` und `88-mutfull` samt `_lib.sh`, `verifier.sh`, `orchestrator/lib/r-deps.R`, `r-tests.R` und `r-check.sh`. In `orchestrate.sh` die Funktionen `preflight`, `changed_paths`, `restore_worktree`, `ownership_check`, `verdict`, `run_gates` und `run_ms` mit der DONE-Prüfung. Schließlich das BUILD-Log, das Log von Versuch 1 dieser Phase, `orchestrate.log` und `reference/privat/gates-auswahl.md`. Visuelle Artefakte gibt es in M0 nicht.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

In dieser Sitzung waren Python und Schreibzugriffe außerhalb des Arbeitsbaums nicht freigegeben (`--allowedTools "Bash(Rscript:*)"`). Alle Rechnungen liefen deshalb als `Rscript -e` mit `setwd(tempdir())` und nur lesend. Den Diff habe ich direkt aus `.git/objects/` gelesen (`memDecompress(type = "gzip")`, Vergleich der Bäume); alle benötigten Objekte lagen lose vor.

1. **Diff `plan/M0` → HEAD**, vollständig (Baum von `6783f287…` gegen `506eaec8…`):
   - Builder-Territorium: nur `PROGRESS.md` (Blob `71726489…` → `bff44043…`).
   - Orchestrator: `orchestrator/state/M0/` (`5-built.done`, `current-phase`, `territory-ok`, acht `gate-*.log`, `gates-r1-infra0.done`, `gates.json`), `orchestrator/state/summary.json`, `STATUS.md`.
   - Sonst kein Pfad, insbesondere nichts unter `R/`, `tests/`, `man/`, `vignettes/`, `inst/`, `data/`, `data-raw/`, `reference/anchors/`, `docs/`, `orchestrator/gates.d/`, `orchestrator/lib/` und weder `DESCRIPTION`, `NAMESPACE`, `NEWS.md` noch `.Rbuildignore`.
   - Phasen-Commits: `9866ba2` (builder 40-build r1) enthält `PROGRESS.md` und Orchestrator-Zustand, `506eaec` (gates r1) nur Orchestrator-Zustand.
2. **Arbeitsbaum gleich HEAD:** Die Blob-IDs (SHA-1 über `blob <n>\0<inhalt>`, mit `digest`) von `PROGRESS.md` (`bff44043…`), `gates.json` (`2620fd10…`), `gate-tests.log`, `gate-lint.log`, `gate-deps.log`, `territory-ok` und `BACKLOG.md` (`31db22b8…`) gleichen den Einträgen im HEAD-Baum. Die Gate-Fakten unten sind also die versionierten, und `BACKLOG.md` ist nach dem Rollback von Versuch 1 wieder im Stand von HEAD.
3. **K-M0-4 unabhängig:** Unter `R/` liegen 13 Dateien, die Menge gleicht ANK-01. Je Datei stimmen `tools::sha256sum`, Bytezahl und Git-Blob-ID mit ANK-01 überein (13 von 13).
4. **PROGRESS.md gegen das BUILD-Log:** Der Patch im Log (`index 71726489…bff44043…`) ist genau der versionierte Stand. Die drei zitierten Ausgaben (Inventur, `r-deps.R --check-only`, `Rscript --version`) stimmen wörtlich mit dem Log überein, beide Diagnosen endeten mit „succeeded“. Außer `apply patch` auf `PROGRESS.md` zeigt das Log nur lesende Kommandos: `cat`, `sed -n`, `rg --files`, die Python-Inventur, `Rscript --version` und `r-deps.R --check-only`. Es gibt kein Git-Kommando und keinen Build, Check oder Testlauf im Checkout. Keine Aussage in PROGRESS.md geht über die Belege hinaus („**Die Gate-Abnahme steht aus.**“).
5. **Trace unabhängig:** Alle sieben Zitate aus `CRITERIA.json` stehen wörtlich in `docs/01-fachspezifikation.md`. `criteriaRef` von M0 im Manifest lautet K-M0-1 bis K-M0-7.
6. **K-M0-1 unabhängig:** `DESCRIPTION` nennt `R (>= 4.1)` unter Depends, sechs Imports und acht Suggests, aber kein LinkingTo. Das sind genau die 15 Zeilen in `gate-deps.log`.
7. **Ausführbarkeit versioniert:** Im HEAD-Baum tragen alle acht `orchestrator/gates.d/NN-*.sh` und die fünf Skripte unter `orchestrator/lib/` den Modus `100755`.
8. **Layout:** `.github/workflows/pkgdown.yaml` baut mit `dest_dir = "pkgdown-site"` und veröffentlicht `folder: pkgdown-site`. `.gitignore` enthält `pkgdown-site/`, `reference/quellen/` und `reference/privat/`, aber keine Regel, die `docs/` trifft.

## Gate-Fakten

`gates.json`: `milestone` M0, `round` 1, `base` `6783f2874340…` (`baseRef` `plan/M0`, gleich dem Commit hinter dem Tag), `env.sha` `9866ba2f5fce…` (Builder-Commit; der heutige HEAD `506eaec` fügt nur Gate-Zustand hinzu), R 4.6.1, pandoc 3.7.0.2, `result` **pass**.

| Gate | Status | Kurzbefund | Kriterien |
| --- | --- | --- | --- |
| deps | pass | `r-deps: pass — 15 Anforderungen erfüllt (R 4.6.1)`, Versionen im Log | K-M0-1, K-M0-6 |
| lint | pass | `Status: OK`; build und `check --as-cran --no-manual` in `/tmp/harness-r-check.*` | K-M0-3, K-M0-6 |
| tests | pass | `42 Tests in tests/testthat, tests/acceptance; 0 fehlgeschlagen, 0 Fehler, 2 übersprungen` | K-M0-2, K-M0-6; Läufer der Tests zu K-M0-1, -4, -5, -7 |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` | K-M0-6 |
| territory | pass | `letzter Diff sauber (builder/40-build, Runde 1, Basis 6783f287…)` | K-M0-6 |
| mutgate | pass | `mutgate: pass (kein geänderter Mutations-Scope)` | K-M0-6 |
| golden-adr | pass | `golden-adr: keine Golden-/Ankeränderung` | K-M0-6, K-M0-7 |
| mutfull | pass | `mutfull: pass (nicht fällig in M0)` | kein M0-Kriterium (K-M1c-6) |

Testzahl und Skips gehören nach PLAN-REVIEW E1 hierher, weil in M0 keine Builder-Phase mehr folgt:

| Ordner | Dateien | `test_that()`-Blöcke | Skips | bestandene Erwartungen | Fehlschläge / Fehler / Warnungen |
| --- | --- | --- | --- | --- | --- |
| `tests/testthat` | 6 | 27 (= ANK-03, Zählung nach ADR-003) | 2: `test-report.R:5:3` (`skip_on_cran()`), `test-backends.R:32:3` (ellmer installiert) | 136 | 0 / 0 / 0 |
| `tests/acceptance` | 6 | 15 | 0 | 370 | 0 / 0 / 0 |
| `tests/simulation`, `tests/e2e`, `tests/fuzz` | 0 | – | – | – | „keine Testdateien, übersprungen“ |

Die 27 Blöcke ergeben sich aus 42 Blöcken insgesamt abzüglich der 15 Abnahmeblöcke (api-snapshot 6, deps 1, gates 1, layout 4, r-unchanged 2, testthat-count 1). `test-m0-testthat-count.R` hat die Untergrenze mit einem eigenen Lauf geprüft und bestanden. Beide Skips stammen aus dem Bestand v0.1.0 und treten genauso im ANK-03-Lauf auf; neue Skips gibt es nicht.

Gate-Laufzeiten: Das Ende jedes Gates stammt aus der Änderungszeit von `gate-*.log`, der Start 07:46:57 aus `orchestrate.log`. deps dauerte ≈ 1 s, lint ≈ 63 s (build ≈ 13 s bis zum Check-Start 06:47:11 UTC, check ≈ 50 s), tests ≈ 20 s (testthat 8,5 s und 9,0 s), trace bis mutfull zusammen ≈ 1 s. Insgesamt sind das ≈ 86 s.

## Bewertung je Kriterium

- **K-M0-1 erfüllt:** Das deps-Gate meldet pass, die Versionen stehen im Gate-Log. Der Zusatztest `test-m0-deps.R` ist grün (31 Erwartungen = 1 + 15 × 2).
- **K-M0-2 erfüllt:** Das tests-Gate meldet pass, ohne Fehlschlag und Fehler über `tests/testthat` und `tests/acceptance`. `tests/e2e` und `tests/fuzz` sind leer, weil QA in M0 nicht aktiv ist. Unter `tests/testthat` laufen 27 Blöcke, das erreicht ANK-03 = 27.
- **K-M0-3 erfüllt:** Das lint-Gate meldet pass. `R CMD build` und `R CMD check --as-cran --no-manual` liefen im temporären Verzeichnis außerhalb des Repos und endeten mit `Status: OK`, also ohne ERROR, WARNING und NOTE.
- **K-M0-4 erfüllt:** Der Abnahmetest ist im Arbeitsbaum-Zweig grün (55 Erwartungen; `8-done.done` fehlt noch, ADR-001). Nachprüfung 3 ergibt 13 von 13.
- **K-M0-5 erfüllt:** Der Layout-Test ist grün (16 Erwartungen). Seine Git-Prüfungen liefen dabei zum ersten Mal gegen echtes `git`; das Restrisiko aus ADR-002 ist damit erledigt.
- **K-M0-6 erfüllt:** `gates.json` meldet pass für deps, lint, tests, trace, territory, mutgate und golden-adr. Der mutgate-Kurzbefund steht wörtlich da, `result` ist pass, Runde, Basis und SHA passen (siehe oben).
- **K-M0-7 erfüllt:** ANK-02 liegt vor (22 Exporte, 22 Argumentlisten). Grün sind der Obermengentest gegen das geladene Paket, die Positiv- und Negativfälle mit beiden Prüfern und der isolierte golden-adr-Lauf (259 Erwartungen). Dieser Lauf endet bei einer Snapshot-Änderung ohne ADR mit Exit 1, mit ADR und ohne Ankeränderung mit Exit 0.

## Prüfliste aus dem Auftrag

- **Spec- und Vertragstreue:** Der Builder-Diff besteht genau aus `PROGRESS.md`. Damit ist §10 eingehalten: „M0 ändert `R/` nicht. Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“ `PROGRESS.md` ist deutsch (01 §1).
- **API-Diff:** keiner, denn `R/` und `NAMESPACE` sind unverändert (Nachprüfungen 1 und 3).
- **Entkernte Tests, gelockerte Konfiguration:** keine. `tests/**`, `orchestrator/gates.d/` und `orchestrator/lib/` stehen nicht im Diff. `orchestrator/config.env` ist git-ignoriert; der Orchestrator schützt die Datei über ihren Hash je Modellphase.
- **Harte Erwartungswerte, erfundene Daten:** keine. Produktcode blieb unverändert, und die Ausgaben in PROGRESS.md sind echte Outputs (Nachprüfung 4).
- **Golden- oder Ankeränderung ohne ADR:** keine (golden-adr pass, Nachprüfung 1).
- **Sichtbare Defekte:** keine.
- **MUT-EQUIV:** Es gibt keine Claims, deshalb keine `MUT-EQUIV-APPROVED.json`.
- **QA:** In M0 nicht aktiv (`QA_REQUIRED_FROM=M1a`), daher kein `[QA-PENDING]`.
- **Gate-Status `error`:** bei keinem Gate, daher kein `[INFRA]` aus den Gates.

## Offene Punkte aus CRITERIA.json

ACC-1 bis ACC-3 sind durch ADR-001 bis ADR-003 entschieden (PLAN-REVIEW). Die Tests setzen die Auslegungen um, die Gate-Läufe bestätigen sie. `CRITERIA.json` bleibt unverändert, damit der von trace geprüfte Stand gilt. Der Vermerk „ADR ausstehend“ unter `open` ist durch die ADRs überholt.

## Einwände

### Blocking

Keine.

### Minor (nonblocking)

- [E5] (minor) [INFRA] `orchestrator/orchestrate.sh`, `all_untracked_paths`/`changed_paths` (Z. 365–376: `git ls-files --others` ohne `--exclude-standard`) und `restore_worktree` (Z. 449–470); `orchestrate.log` 08:10:07 — Befund: Die Territoriumsprüfung rechnet jede neue oder geänderte Datei im Arbeitsbaum der laufenden Modellrolle zu, auch unter git-ignorierten Pfaden. Versuch 1 dieser Phase wurde verworfen, weil Betreiberdateien unter `reference/quellen/data/aiag/` während der Phase entstanden (07:56 und 08:00). Der Rollback hat sie gelöscht; ein zweiter Treffer in derselben Phase endet FATAL. Nach den Verzeichniszeiten (08:09:56) hat `git clean -qfd` vermutlich außerdem die leeren Ordner `tests/e2e`, `tests/fuzz` (gates-auswahl §5) und `orchestrator/state/M0/shots` entfernt. Das bleibt folgenlos: `r-tests.R` überspringt fehlende Ordner, `verifier.sh` legt `shots/` neu an. Das RUNBOOK warnt nicht vor Schreibzugriffen während einer Modellphase. — Vorschlag: Der Betreiber legt während einer Modellphase nichts im Arbeitsbaum an, auch nicht unter `reference/quellen/`. Eine Phase läuft, solange eine lebende PID in `orchestrator/.lock/pid` steht und `orchestrate.log` noch kein „Halt nach Phase …“ zeigt. Daten bereitet er außerhalb (`../quellen/`) vor und kopiert sie zwischen zwei Phasen; ein Hinweis gehört ins RUNBOOK. Im Template-Backlog wäre zu prüfen, ob Betreiberpfade gemeldet statt gelöscht werden, ohne die Prüfung ignorierter Pfade aufzugeben. Für den Builder ist nichts zu tun. → BL-55.
- [E6] (minor) [INFRA] Prompt dieser Phase („eine benötigte fremde Änderung wird im Handoff dokumentiert“); BL-42; 01 §6 („Abnahmetests, die solche Daten brauchen, schlagen fehl, wenn die Datei fehlt (kein `skip`)“) — Befund: Nach dem Rollback fehlen beide AIAG-Dateien. Spätestens die Abnahmetests von M1a, die auf diese Daten zugreifen (K-M1a-2, BL-22), schlügen daran benannt fehl. Der Reviewer darf sie nicht anlegen, denn `reference/quellen/**` ist Betreiber-Territorium. — Vorschlag: Der Betreiber stellt die Dateien nach dem Ende dieser Phase wieder her und gleicht die Prüfsummen ab (Abschnitt „Benötigte fremde Änderung“). Der Abgleich am Original durch den Reviewer bleibt für die ACCEPTANCE von M1a offen (BL-42).
- [E7] (minor) [INFRA] BL-48; PLAN-REVIEW E3; 01 §9 („Gates (Begründung in `gates-auswahl.md`)“, „Zuordnung in `gates-auswahl.md`“) — Befund: `gates-auswahl.md` liegt seit 25.10.2026, 07:25:39, als `reference/privat/gates-auswahl.md` vor (git-ignoriert, nicht versioniert). Die Aussage in E3, die Datei fehle „auch unter den ignorierten Pfaden“, ist damit überholt. Ihre Zuordnung (§1 und §3) deckt sich mit der in PLAN-REVIEW bestätigten M0-Zuordnung: Jedes aktive Gate trägt mindestens ein Kriterium, `88-mutfull` trägt K-M1c-6. Eine maschinelle Prüfung gibt es weiterhin nicht. — Vorschlag: Der Betreiber nennt den Ablageort dort, wo die Spec und `orchestrator/config.env:136` (`projektierung_llmsa/gates-auswahl.md`) auf die Datei verweisen. Der Reviewer prüft die Zuordnung in jeder ACCEPTANCE-Phase weiter. → BL-48 fortgeschrieben.
- [E8] (minor) ADR-001, Konsequenzen („Restrisiko: Der Tag-Zweig lief in der ACCEPTANCE-Phase nur gegen eine Git-Attrappe.“); K-M0-4 — Befund: In M0 lief nur der Arbeitsbaum-Zweig von `test-m0-r-unchanged.R`. Der Zweig über `done/M0` (`git ls-tree`, `git cat-file`) läuft zum ersten Mal echt im ersten Test-Gate von M2. — Vorschlag: Der Reviewer prüft im ersten Code-Review von M2 in `gate-tests.log`, dass `m0-r-unchanged` dort grün ist. Ein Fehler im Test ist Reviewer-Sache, kein Builder-Befund. → BL-53.
- [E9] (minor) PLAN-REVIEW E1; `orchestrator/orchestrate.sh:1052–1053`; `PROGRESS.md` („**Die Gate-Abnahme steht aus.**“) — Befund: Mit PASS in Runde 1 folgt in M0 keine Builder-Phase mehr. `PROGRESS.md` bleibt auf dem BUILD-Stand: für den damaligen Zeitpunkt richtig, als Langzeitgedächtnis aber veraltet. Die DONE-Prüfung besteht trotzdem, weil sich `PROGRESS.md` seit `plan/M0` geändert hat (Blob `71726489…` → `bff44043…`). Testzahl und Skips stehen oben unter „Gate-Fakten“. — Vorschlag: Der Builder ergänzt im ersten BUILD von M2 einen kurzen M0-Abschlussvermerk mit Verweis auf `orchestrator/state/M0/gates.json` (Runde 1, `result: pass`) und auf diese REVIEW.md. → BL-54.
- [E10] (minor) [INFRA] ADR-003, Kontext; `tests/testthat/test-report.R:5` (`skip_on_cran()`) und `tests/testthat/test-backends.R:32` (`skip_if(requireNamespace("ellmer", quietly = TRUE))`); `gate-tests.log` („Skipped tests (2)“); 01 §2 Nr. 1 — Befund: Zwei Bestandstests laufen in keinem Gate. Den Berichtstest „the validation report renders“ überspringt `skip_on_cran()`, weil weder `orchestrator/lib/r-tests.R` noch `R CMD check` `NOT_CRAN` setzen. Damit prüft kein Gate, ob `msa_report()` rendert. Der ellmer-Fehlerpfad läuft nur ohne ellmer, und das deps-Gate installiert es. Für M0 ist das kein Mangel: K-M0-2 zählt Skips mit (ADR-003), und der Builder darf in M0 keine Tests ändern. — Vorschlag: Der Betreiber entscheidet vor dem ersten Meilenstein, der `msa_report()` oder den Validierungsbericht ändert, ob das Test-Gate `NOT_CRAN=true` setzt. Die ANK-03-Zählung bleibt davon unberührt. Die ellmer-Abdeckung bleibt bei BL-17 (K-M3d-3). → BL-56.
- [E11] (minor) PLAN-REVIEW E4; 01 §4 („Ohne ADR erlaubt: … neue Argumente mit Vorgabewert am Ende der Argumentliste“) — Befund: E4 kommt hiermit ins BACKLOG, weil `BACKLOG.md` in `30-plan-review` nicht im Reviewer-Territorium lag. Die Obermengenprüfung von K-M0-7 lässt angehängte Argumente auch ohne Vorgabewert passieren; das entspricht dem Wortlaut („zusätzliche Argumente hinter den Snapshot-Argumenten bestehen den Test“). §4 erlaubt ohne ADR aber nur angehängte Argumente mit Vorgabewert. — Vorschlag: Der Reviewer prüft ab M2 in jedem Code-Review die Vorgabewerte neu angehängter Argumente und erwägt in einer ACCEPTANCE-Phase eine eigene Abnahmeprüfung dafür (`...` ausgenommen). → BL-57.

## Benötigte fremde Änderung (Betreiber)

Wiederherstellung von `reference/quellen/data/aiag/anova_example.csv` und `reference/quellen/data/aiag/QUELLE.txt` (E6), erst nach dem Ende dieser Phase. Dann steht in `orchestrator/logs/orchestrate.log` „Halt nach Phase 50-code-review“, und `orchestrator/.lock/pid` nennt keinen lebenden Prozess mehr.

1. Beide Dateien neu erzeugen, aus der eigenen Vorlage oder aus dem Anhang im Log von Versuch 1 (`orchestrator/logs/M0-50-code-review-r1-a1-20261025-074906.log`, git-ignoriert), jeweils UTF-8 mit LF.
2. Prüfsummen abgleichen. Die Werte stammen aus dem Log von Versuch 1, der sie am damaligen Arbeitsbaum berechnet hat; dieser Versuch kann sie nicht nachprüfen, weil die Dateien fehlen:
   - `anova_example.csv`: 1069 Byte, SHA-256 `3161a373027b7e61d4818659d3897f8d516ba2776ae145ab5544d26e4acbff16`
   - `QUELLE.txt`: 2939 Byte, SHA-256 `25bc77ec83efd6fe31879c1718b0997902ee7e564f059df049ea2f62d83e208d`
3. Ein Commit ist nicht nötig, weil `reference/quellen/` git-ignoriert ist. PREFLIGHT prüft `git status --porcelain` mit den Standard-Ausschlüssen; die Dateien stören den nächsten Lauf also nicht.
4. Die Datenwerte gehören in keine versionierte Datei (01 §6, BL-09); dieses Handoff nennt deshalb nur Pfade und Prüfsummen.

## Backlog-Pflege in dieser Phase

- **BL-11:** Messwerte von M0 ergänzt: laut Codex-Log PLAN r1 mit 128.452 Tokens, BUILD r1 mit 91.764 Tokens. Der Dashboard-Abgleich bleibt beim Betreiber.
- **BL-13:** Gate-Laufzeiten von M0 ergänzt (siehe „Gate-Fakten“). Der Eintrag bleibt offen bis M1a.
- **BL-19:** als erledigt gestrichen. Belege: K-M0-5 ist mit echtem `git check-ignore` einschließlich `--no-index` grün (ADR-002), dazu Nachprüfung 8.
- **BL-32:** als erledigt gestrichen. Belege: Modus `100755` im HEAD-Baum (Nachprüfung 7), `tests/testthat.R` liegt unverändert vor, die beiden `.Rbuildignore`-Zeilen prüft K-M0-5.
- **BL-42:** Stand der AIAG-Dateien vermerkt (E6).
- **BL-48:** fortgeschrieben (E7).
- Neu sind BL-53 (E8), BL-54 (E9), BL-55 (E5), BL-56 (E10) und BL-57 (E11).

## Verdict

**PASS.** `gates.json` meldet `result: pass`, und `blocking` ist leer. K-M0-1 bis K-M0-7 sind mit Gate-Fakten und eigener Nachprüfung belegt. Der Builder hat seit `plan/M0` nur `PROGRESS.md` geändert, mit echten Outputs und ohne Eingriff in Produktcode, Tests, Anker oder Konfiguration. E5 bis E11 sind nonblocking und stehen im BACKLOG; für den Builder in M0 ist nichts zu tun. Die DONE-Bedingung des Orchestrators (`PROGRESS.md` seit `plan/M0` geändert, `orchestrate.sh:1052`) ist erfüllt.
