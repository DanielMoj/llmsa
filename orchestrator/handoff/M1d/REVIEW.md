# REVIEW — M1d, Runde 5

Rolle: Reviewer · Phase: `50-code-review` · Runde: 5 · Stand: 04.11.2026 · Gegenstand: Diff seit `plan/M1d` (`0511335`) bis zum Stand der Gates (`gates.json`: `env.sha` `9ddebf8`, Commit von Rework r5; HEAD `1982ccd` ist der Gate-Commit). Neu in dieser Runde sind der Betreiber-Commit `a08a90d` (`_pkgdown.yml`) und Rework r5 (`a08a90d` → `9ddebf8`). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` noch `MUT-EQUIV.json` zu M1d. Keine Git-Kommandos.

## Ergebnis

**Verdict PASS, `blocking` leer.** `gates.result` ist `pass`; alle acht Gates sind grün, keines meldet `error`.

- **E1 ist erledigt.** Der Betreiber hat nach dem Halt den Abschnitt `articles` an `_pkgdown.yml` angehängt (`a08a90d`, 08:07:45).
  - Der Commit ändert nur diese Datei. Er hängt 129 Byte an, die ersten 574 Byte gleichen `plan/M1d` (Prüflauf 1).
  - 703 Byte und SHA-256 `7e465e03…c12c3b671` sind die Werte aus M1d REVIEW r4, „An den Betreiber“ Nr. 1. Der Inhalt ist der Vorschlag aus ADR-048 Nr. 15.
  - Im tests-Gate der Runde 5 besteht `m1d-5-size-licence-network` mit 45 Erwartungen (`gate-tests.log` Z. 1195); in Runde 4 waren es 42 grün und 3 rot.
  - Die Abnahme insgesamt meldet `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 15641 ]` (Z. 1811), genau 3 Erwartungen mehr als in Runde 4.
- **Der Ablauf beim Betreiber war wie vorgesehen.**
  - Halt nach dem Review-Commit r4 um 08:07:36 (`orchestrate.log` Z. 214), Neustart um 08:07:48 mit „REWORK<=5“ (Z. 216).
  - Rework r5 lief auf dem Betreiber-Commit; territory ist grün mit Basis `a08a90d`. `orchestrator/STOP` ist entfernt.
- **Rework r5** ändert nur `PROGRESS.md` und `REWORK-NOTES.md` (Prüflauf 1). Die Belege des Builders stimmen, auch die Zeilenverweise auf die Gate-Logs der Runde 4 und sein Log unter `/tmp`.
- **Gesamtdiff seit `plan/M1d`:** dieselben Pfade wie in den Runden 1 bis 4 und dazu nur `_pkgdown.yml`. Kein Abnahmetest ist geändert, keine Datei entfernt. Arbeitsbaum und HEAD sind gleich.
- **Befunde aus K-M1d-7 unabhängig nachgerechnet**, aus den vier Vollauf-Dateien und ohne die Helfer des Pakets (Prüflauf 2). Sie stimmen mit `?msa_fit` und `?msa_boot` überein.
- **Mutation:**
  - mutgate („kein geänderter Mutations-Scope“, ADR-047 Nr. 1) und mutfull („nicht fällig in M1d“) sind grün. Die Bedingungen aus ADR-047 Nr. 2 sind erfüllt (unten, Spec- und Vertragstreue).
  - Es gibt keinen Mutationsbericht dieser Runde. `reports/mutation/mutation.json` stammt vom 03.11., 13:25, also aus M1c.
  - Es gibt keine `MUT-EQUIV.json`; ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`.
- **Offen und nonblocking** bleiben E16 (BL-119), E18 (QA-M1d-001, BL-117) und E19 (BL-121).
- **Was jetzt folgt** (`orchestrate.sh:1059–1099`):
  - Bei PASS und grünen Gates prüft der Orchestrator `PROGRESS.md`. Die Datei ist seit `plan/M1d` geändert, die Prüfung besteht.
  - Danach setzt er `8-done`, committet und taggt `done/M1d`.
  - Der Lauf endet dann mit „MAX_MS_PER_RUN=1 erreicht“ (`:1135`); M3a startet in diesem Lauf nicht.

### An den Betreiber

1. **Kontrolllauf Mutation nach `done/M1d` (ADR-047 Nr. 3, neu BL-122).**
   - Einmal ohne die Scope-Sperre (`config.env:276`) in einer Kopie des Repos rechnen, außerhalb des Harness.
   - Verlangt sind 92,09. In M1c dauerte ein Lauf rund zehn Stunden (ADR-047, Kontext).
2. **Vor einem Lauf, der M3a beginnt.** Ein neuer Lauf ohne Ziel startet M3a: Es ist der nächste Eintrag in `milestones.json`, und seine Abhängigkeit M0 ist erfüllt.
   - Zuerst über M3a bis M3d entscheiden (Projektblock: „Entscheidung nach M1d“; BL-11).
   - Falls M3a läuft, ADR-047 Nr. 4 und BL-24 umsetzen:
     - `MUT_SCOPE_REGEX` auf `'^R/.*\.R$'` setzen und die Zeile aus ADR-047 entfernen (`config.env:276`);
     - `orchestrator/state/mut-baseline` zurücksetzen (`config.env:228`, Kommentar);
     - `MUT_TEST_EXCLUDE` behält `|m1d-`.
3. **AP1-Auswertung wiederholen (BL-52).** Mit `done/M1d` sind M1a bis M1d abgenommen. AP1-Zahlen von davor sind vorläufig. Für das Go/No-Go am 15.11. braucht es abgenommenes M1 und ausgewertetes AP1 (BL-10).
4. **Etikettenregel llm-stability (E16, BL-119, unverändert):** vor einer Verwendung der Zahlen aus `vignettes/llm-stability.Rmd` im Paper entscheiden.
5. **URL der pkgdown-Seite (E19, BL-121, unverändert):** nach dem 26.11.2026 mit der Release-Arbeit; zuständig ist der Builder (`DESCRIPTION`).

## Gate-Fakten (`orchestrator/state/M1d/gates.json`, Runde 5)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 07:14:23 UTC (08:14:23 MEZ), also nach dem Rework-Commit (08:13:29): `creating vignettes ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK` (Z. 89); `installed size is 22.3Mb` als INFO (BL-114) |
| tests | pass | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5741 ]` (Z. 595; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 15641 ]` (Z. 1811, Dauer 2307,4 s); e2e `[ FAIL 0 \| … PASS 319 ]` (Z. 1877); fuzz `[ FAIL 0 \| … PASS 94 ]` (Z. 1908). Kurzbefund: „674 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1909) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (builder/60-rework, Runde 5, Basis a08a90d…, 2026-11-04T08:13:27+01:00)` |
| mutgate | pass | `kein geänderter Mutations-Scope` (ADR-047 Nr. 1) |
| golden-adr | pass | `Änderung und ADR liegen im selben Meilenstein` (ADR-049 deckt `inst/extdata/`) |
| mutfull | pass | `nicht fällig in M1d` |

- **Die zwei Warnungen** sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 783–809). Sie liegen im Reviewer-Territorium und haben keinen Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.

Erwartungen der M1d-Tests im tests-Gate der Runde 5:

| Testdatei | Erwartungen | Zeile |
| --- | --- | --- |
| `m1d-1-llm-stability-data` | 97 (23,9 s) | 1138 |
| `m1d-2-llm-stability-vignette` | 113 (15,3 s) | 1163 |
| `m1d-3-clinvar-data` | 47 (543,5 s) | 1173 |
| `m1d-4-clinvar-vignette` | 106 (14,8 s) | 1190 |
| `m1d-5-size-licence-network` | 45 (3,7 s); Runde 4: 42 grün, 3 rot | 1195 |
| `m1d-6-full-runs` | 4125 (10,9 s) | 1290 |
| `m1d-7-findings` | 512 (77,7 s), einschließlich ACC-12 | 1668 |
| `m1d-8-robustness-wording` | 31 (1,2 s) | 1676 |
| Unit `m1d-data`, `m1d-findings` | 47, 48 | 431, 439 |
| QA `m1d-qa-e2e`, `m1d-qa-fuzz`, `m1c-qa-e2e` | 224, 51, 46 | 1867, 1899, 1845 |

- Außer bei `m1d-5` sind die Zahlen gleich denen der Runden 1 bis 4.
- **Regression der Vormeilensteine** im selben Lauf grün, darunter:
  - `m0-api-snapshot` (259), `m0-layout` (16, prüft unter K-M0-5 die Zeile `destination`);
  - `m1a-7-vignette` (148);
  - `m1b-7-vignette-full-results` (204), `m1b-7-vignette` (240);
  - `m1c-5-vignette-full-results` (49), `m1c-5-vignette` (55), `m1c-8-check-runs` (94), `m1c-8-iteration-limit` (62);
  - `m2-7-robustness-pilot` (375).

## Gelesen

- **Rahmen:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/02 M1d (Ergebnis, Voraussetzung, Abbildungen, K-M1d-1 bis K-M1d-8).
- **Entscheidungen:** ADR-047 Nr. 1 bis 4 mit Kontext und Konsequenzen; ADR-048 Nr. 14 und 15 mit Konsequenzen. ADR-049 habe ich nicht erneut gelesen. Sein Gegenstand `inst/extdata/` ist seit den Gates r4 blobgleich (Prüflauf 1) und laut den Reviews r2 bis r4 seit Runde 1.
- **Handoff M1d:**
  - `CRITERIA.json` (K-M1d-1 bis K-M1d-8, ACC-1 bis ACC-20), `QA.md`, `REWORK-NOTES.md` (Runde 5, dazu die Fassung der Runde 4 als Blob);
  - mein `REVIEW.md` und `verdict-code.json` der Runde 4.
  - `PLAN.md`, `PLAN-REVIEW.md` und `REVIEW-INPUT.md` nicht erneut; die Runde berührt keine Planstelle, und alle drei sind seit den Gates r4 blobgleich.
- **Gates und Harness:**
  - `gates.json`, alle acht `gate-*.log`, `state/M1d/territory-ok`, `round`, `current-phase`, `shots/`; die `gates.json` der Runde 4 als Blob;
  - `orchestrator/logs/orchestrate.log` (CONFIG-Zeilen 200 und 216, Ereignisse M1d bis Z. 220);
  - `orchestrate.sh`: `verdict` und das Ende von `run_ms` (PASS-Pfad, PROGRESS-Prüfung, `done/<MS>`, `MAX_MS_PER_RUN`);
  - `config.env` (Runden, Mutations-Scope, Dateizeit), `milestones.json`, `.git/refs/tags/done/`, Dateizeiten von `reports/mutation/`.
- **Diff:** seit `plan/M1d` und in der Folge Gates r4 → Review r4 → Betreiber → Rework r5 → Gates r5 (Prüflauf 1). `diff -u` zu `plan/M1d` für `_pkgdown.yml`, `R/robustness.R`, `R/fit.R`, `R/grr.R`, `inst/templates/validation_report.Rmd`, `NEWS.md` und `tests/e2e/test-m1c-qa-e2e.R`; `PROGRESS.md` gegen den Betreiber-Commit.
- **Tests:** `tests/acceptance/test-m1d-5-size-licence-network.R:94–112`, `tests/testthat/test-m1d-findings.R` vollständig, `tests/testthat/test-m1d-data.R:1–80`.
- **BACKLOG:** BL-10, BL-11, BL-24, BL-52, BL-92, BL-93, BL-105, BL-106, BL-112, BL-114 und BL-117 bis BL-121.

## Eigene Prüfläufe

Am 04.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1d/.probe-cr5/`, vor Phasenende mit `unlink()` gelöscht. Umgebung: R 4.6.1, pkgdown 2.2.1. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff ohne Git-Kommando.**
   - R liest `.git/refs/tags/plan/M1d` und `refs/heads/main` und folgt Tag, Commits und Bäumen über die Objektdateien. Jedes gelesene Objekt ist gegen seine SHA-1 geprüft.
   - Die Probe kann auch Packdateien lesen (idx v2 mit Deltas). Das war nicht nötig: Alle 535 Objekte lagen lose.
   - Verglichen habe ich die Blob-IDs für `plan/M1d` → HEAD und für die Folge Gates r4 → Review r4 → Betreiber → Rework r5 → Gates r5, dazu HEAD → Arbeitsbaum.
   - Für `diff -u` habe ich die Blobs aus `plan/M1d` und aus dem Betreiber-Commit in die Probe geschrieben. Geprüft habe ich außerdem die Zeilen der Gate-Logs der Runde 4 aus dem Baum von Gates r4, auf die der Builder verweist, und sein Log unter `/tmp`.

   ```text
   plan/M1d ref: 0456afbfc5bf7648e09d9fc2f6c69703606af837 type tag -> base commit 051133562fa0197a70535fb24d3afbd5c7d2a0d2
   HEAD (refs/heads/main): 1982ccd574c11d97d32d3a16d69d9fb9279a1e33
   commits after plan/M1d up to HEAD: 17
   commit 1982ccd574c11d97d32d3a16d69d9fb9279a1e33 msg: orch(M1d): gates r5 (rc=0) parent: 9ddebf89727ba8009c280663a89d19a57d628d6d
   commit 9ddebf89727ba8009c280663a89d19a57d628d6d msg: orch(M1d): builder 60-rework r5 parent: a08a90d66dbccb531d3a09a375c9c87766c51fad
   commit a08a90d66dbccb531d3a09a375c9c87766c51fad msg: betreiber: list the vignettes under articles in _pkgdown.yml (K-M1d-5, BL-118) parent: 379fc5223480fee1aab4e514911750a3034e54c8
   commit 379fc5223480fee1aab4e514911750a3034e54c8 msg: orch(M1d): reviewer 50-code-review r4 parent: 0bc6b6b91b7fc2081284ce8d0cd983353457f228
   plan/M1d -> HEAD: files 674 -> 738; added 64 removed 0 changed 16
     tests/acceptance touched: 0
   review r4 -> operator: files 736 -> 736; added 0 removed 0 changed 1
     changed: _pkgdown.yml
   operator -> rework r5: files 736 -> 737; added 1 removed 0 changed 7
     added: orchestrator/state/M1d/rework-r5.done
     changed: PROGRESS.md STATUS.md orchestrator/handoff/M1d/REWORK-NOTES.md orchestrator/state/M1d/current-phase orchestrator/state/M1d/round orchestrator/state/M1d/territory-ok orchestrator/state/summary.json
   rework r5 -> gates r5 (HEAD): files 737 -> 738; added 1 removed 0 changed 7
     added: orchestrator/state/M1d/gates-r5-infra0.done
     changed: STATUS.md orchestrator/state/M1d/current-phase orchestrator/state/M1d/gate-lint.log orchestrator/state/M1d/gate-territory.log orchestrator/state/M1d/gate-tests.log orchestrator/state/M1d/gates.json orchestrator/state/summary.json
   product/test/spec/harness paths touched since gates r4: BACKLOG.md _pkgdown.yml
   plan/M1d -> HEAD minus plan/M1d -> gates r4 (changed): _pkgdown.yml
   package paths with identical blob gates r4 vs HEAD: 429 of 431 ; differing: BACKLOG.md _pkgdown.yml
   _pkgdown.yml base 574 bytes; head 703 bytes; work tree 703 bytes
   _pkgdown.yml head starts with base bytes (pure append): TRUE
   _pkgdown.yml sha256 work tree: 7e465e038e78aa7b5cd90c2caebd909c74ab588298a1a765a594c00c12c3b671 ; CR bytes: 0
   tracked files whose work-tree blob differs from HEAD: 0 :
   untracked files under package paths:
   objects read: loose 535 pack 0
   r4 tests 1182: ✔ |        106 | m1d-4-clinvar-vignette [15.2s]
   r4 tests 1189: Failure ('test-m1d-5-size-licence-network.R:97:3'): K-M1d-5: both vignettes are listed under articles in _pkgdown.yml
   r4 tests 1686: ✔ |        512 | m1d-7-findings [77.9s]
   r4 tests 1943: ✔ |         51 | m1d-qa-fuzz
   r4 lint 89: Status: OK
   HEAD round 1: 5
   builder log exists: TRUE
   [ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]
   K-M1d-5 acceptance: 5.77 seconds; exit 0
   (Auszug; die übrigen geprüften Zeilen 778, 791, 803, 1207, 1831, 1849, 1920 und 1952 der Runde 4 tragen den jeweils genannten Inhalt)
   ```

   - **Betreiber-Commit:** Er ändert nur `_pkgdown.yml`, sein Vorgänger ist Review r4. `diff -u` zeigt nach `- llmsa-package` eine Leerzeile und den Block `articles` mit `Validation: validation` und `Applications: llm-stability, clinvar-raters`. Die Schlüssel `url`, `destination`, `template` und `reference` sind unverändert.
   - **Rework r5:** Es ändert nur `PROGRESS.md` und `REWORK-NOTES.md`; die übrigen Pfade sind Orchestrator-Zustand (`round` 4 → 5). `diff -u` von `PROGRESS.md` zeigt nur den neuen Abschnitt „M1d — REWORK, Runde 5“ am Anfang; die älteren Einträge sind unverändert.
   - **Gegenüber `plan/M1d`:** Geändert sind die 15 Pfade der Runden 1 bis 4 und dazu `_pkgdown.yml`. Die 64 neuen Pfade sind die 61 der Runde 4 und drei Zustandsmarker. Seit den Gates r4 sind unter Paket-, Test-, Spec- und Harness-Pfaden nur `BACKLOG.md` (Review r4) und `_pkgdown.yml` (Betreiber) geändert.
   - **Tests seit `plan/M1d`:** keine Datei entfernt, kein Abnahmetest geändert. Neu sind vier Testdateien (`test-m1d-data.R`, `test-m1d-findings.R`, `test-m1d-qa-e2e.R`, `test-m1d-qa-fuzz.R`). Geändert ist nur `tests/e2e/test-m1c-qa-e2e.R` (QA, M1D-QA-01). Der Test prüft jetzt zusätzlich, dass das Standardverzeichnis den Vollauf liefert, und den Kurzlauf auf einer isolierten Kopie; abgeschwächt ist nichts.
   - **Kerndateien:** In `R/fit.R` und `R/grr.R` gleichen die Zeilen ohne `#'` denen aus `plan/M1d` (`non-roxygen lines identical: TRUE` für beide).
   - **Die letzten zwei Zeilen** des Blocks stammen aus dem Builder-Log `/tmp/llmsa-m1d-r5-3pltfgx8/pkgdown-acceptance.log`.

2. **Befunde aus K-M1d-7 unabhängig nachgerechnet.**
   - Die Probe liest die vier Ergebnisdateien und die Schwellen aus `reference/anchors/ANK-TOL.json` und wendet die Regeln aus ACC-10 (2) direkt an. Die Helfer aus `inst/validation/m1d/findings.R` benutzt sie nicht.
   - Danach liest sie die Szenario-IDs aus dem Text der Rd-Dateien (`tools::Rd2txt`).

   ```text
   bias_report rel_bias 0.1 mcse_multiple 3 ; mc_factor report 3
   ordinal_recovery: n_sim 1000; components checked 17; findings 7
     S-ord-1 model rel_bias -0.2022 (mcse 0.0252) -> underestimation
     S-ord-1 prompt rel_bias -0.1524 (mcse 0.0265) -> underestimation
     S-ord-2 model rel_bias -0.1873 (mcse 0.0256) -> underestimation
     S-ord-3 model rel_bias -0.1707 (mcse 0.0249) -> underestimation
     S-ord-3 prompt rel_bias -0.1094 (mcse 0.0287) -> underestimation
     S-ord-4 model rel_bias -0.2337 (mcse 0.0241) -> underestimation
     S-ord-4 prompt rel_bias -0.1987 (mcse 0.0241) -> underestimation
   binary_recovery: n_sim 1000; components checked 6; findings 3
     S-bin-1 model rel_bias -0.2237 (mcse 0.0255) -> underestimation
     S-bin-1 prompt rel_bias -0.2137 (mcse 0.0268) -> underestimation
     S-bin-2 model rel_bias -0.2042 (mcse 0.0246) -> underestimation
   two_level S-two-1 model bias -0.00035 mcse 0.00227 |bias|/mcse 0.16 -> no direction
   two_level S-two-2 model bias -0.00168 mcse 0.01160 |bias|/mcse 0.14 -> no direction
   boot_coverage coverage rows: 28 ; estimands: grr_pct_contribution grr_pct_study_var icc_items ndc ; n_sim 1000
     S-boot-1 ndc coverage 0.9980 (mcse 0.0014) -> overcoverage
     S-boot-2 ndc coverage 1.0000 (mcse 0.0000) -> overcoverage
     S-boot-3 ndc coverage 0.9910 (mcse 0.0030) -> overcoverage
     S-boot-4 ndc coverage 0.9960 (mcse 0.0020) -> overcoverage
     S-boot-5 ndc coverage 1.0000 (mcse 0.0000) -> overcoverage
     S-boot-6 ndc coverage 1.0000 (mcse 0.0000) -> overcoverage
     S-boot-7 ndc coverage 1.0000 (mcse 0.0000) -> overcoverage
   boot findings other than ndc: 0
   msa_fit .Rd scenario IDs: S-bin-1 S-bin-2 S-ord-1 S-ord-2 S-ord-3 S-ord-4 S-two-1 S-two-2 ; vignette ref: TRUE
   msa_boot .Rd scenario IDs: S-boot-1 S-boot-2 S-boot-3 S-boot-4 S-boot-5 S-boot-6 S-boot-7 ; vignette ref: TRUE
   ```

   - Das deckt sich Satz für Satz mit `R/fit.R` (Unterschätzung von prompt und model in S-ord-1, S-ord-3, S-ord-4 und S-bin-1, von model in S-ord-2 und S-bin-2; S-two-1 und S-two-2 ohne Richtung, ohne Behauptung allgemeiner Unverzerrtheit). Ebenso mit `R/grr.R` (Überdeckung der ndc-Intervalle in S-boot-1 bis S-boot-7, kein anderes Intervall-Schätzziel über der Schwelle).
   - Keine Recovery-Komponente liegt zwischen 80 % und 100 % ihrer Schwelle. Die Zuordnung hängt also an keiner knappen Grenze.

3. **Artikelindex aus der Datei im Arbeitsbaum.** `pkgdown::as_pkgdown()` auf dem Repo selbst, nur lesend, dann `pkgdown:::data_articles_index()` und `pkgdown::check_pkgdown()`.

   ```text
   pkgdown 2.2.1
   Validation : validation
   Applications : llm-stability clinvar-raters
   keys: url destination template reference articles
   destination: pkgdown-site
   check_pkgdown: In DESCRIPTION, URL is missing package url
   (https://danielmoj.github.io/llmsa).
   ```

   - Der Index baut aus der versionierten Datei, nicht nur auf der Kopie aus Runde 4. `check_pkgdown()` bricht weiter nur an der URL ab (E19).

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:**
  - K-M1d-1 bis K-M1d-8 sind im tests-Gate grün. Für K-M1d-2, K-M1d-4 und K-M1d-5 („werden von `R CMD check` gebaut“) baut das lint-Gate alle vier Vignetten mit `Status: OK`.
  - K-M1d-5, Listung: erfüllt durch den Betreiber-Eintrag nach ADR-048 Nr. 15. `validation` steht mit, damit pkgdown den Index baut (Prüflauf 3).
  - „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ ist eingehalten: ACC-12 ist im Gate grün, und Prüflauf 1 bestätigt es an den Blobs.
  - ADR-047 Nr. 2 ist eingehalten. ACC-12 ist grün; unter `tests/` ist seit `plan/M1d` kein Test entfallen und keine Erwartung abgeschwächt (Prüflauf 1, Tests).
  - K-M1d-8: `R/robustness.R` und die Berichtsvorlage schreiben den Satz der Spec. ME im Satz und in der Zeile mit PSE, ME und SME ist dieselbe Zeichenkette (`formatC(…, format = "f", digits = 4)`).
- **API:** `NAMESPACE` und `DESCRIPTION` sind seit `plan/M1d` unverändert; ANK-02 ist im Gate grün (`m0-api-snapshot`, 259). Die geänderte Druckausgabe von `print.msa_robustness` ist nach der Schnittstellenregel ohne ADR zulässig und durch ADR-045 und K-M1d-8 gedeckt.
- **Tests:** Runde 5 bringt keinen neuen Test. Die Unit-Tests des Builders aus Runde 1 belegen Verhalten:
  - `test-m1d-data.R` und `test-m1d-findings.R` prüfen die Regeln auf kleinen synthetischen Eingaben;
  - die Erwartungen sind Handrechnungen (etwa MCSE `sqrt(5 / 12)`), Grenzfälle an den Ankerschwellen, Permutationsinvarianz und Fehlerpfade;
  - keine Momentaufnahme eigener Ausgabe.
- **Konfiguration:**
  - `orchestrator/config.env` ist seit 01:01:26 unverändert und wurde vor beiden Starts des Orchestrators gelesen (CONFIG Z. 200 und 216).
  - Unter `orchestrator/gates.d/` und `orchestrator/lib/` sowie an `.Rbuildignore` und `DESCRIPTION` hat sich seit `plan/M1d` nichts geändert.
  - Die Scope-Sperre für mutgate ist die aus dem Betreiber-ADR-047.
- **Werte, Daten, Golden:**
  - Unter `R/` und `inst/templates/` sind neu nur die Texte aus K-M1d-8 und ihr Format (vier Nachkommastellen); es gibt dort keinen neuen Zahlenwert.
  - Die Szenarien in den Hilfeseiten folgen aus den Vollauf-Dateien (Prüflauf 2).
  - `inst/extdata/` trägt ADR-049 (golden-adr grün); `reference/anchors/` ist seit `plan/M1d` unverändert.
- **Sichtbare Defekte:** keiner in M1d. E19 besteht schon vor M1d und betrifft kein Kriterium.
- **Builder-Belege:**
  - REWORK-NOTES r5 behauptet kein Gate-Ergebnis der Runde 5 und keine Abnahme.
  - Die Inventur „2 changed; 0 new; 0 removed“ bestätigt Prüflauf 1 unabhängig, über die Blob-IDs statt über das Skript des Builders unter `/tmp`.
  - Die gezielte K-M1d-5-Abnahme (`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]`) passt zum tests-Gate der Runde 5.

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E1 (M1D-INFRA-01) | erledigt (Betreiber `a08a90d`, Runde 5) | K-M1d-5 im tests-Gate r5 grün (45 Erwartungen, Z. 1195); BL-118 gestrichen |
| E16 | offen, nonblocking; Betreiber-Entscheidung vor einer Verwendung im Paper | BL-119 |
| E17 | erledigt (Rework r2) | M1d REVIEW r2; BL-120 gestrichen |
| E18 (QA-M1d-001) | nonblocking, nach dem 26.11.2026 | BL-117 |
| E19 | nonblocking, nach dem 26.11.2026 | BL-121 |
| E2 bis E15 | erledigt (Runde 1) | M1d REVIEW r1, Antworten auf REVIEW-INPUT |
| M1D-QA-01 | erledigt (45-qa) | M1d REVIEW r1 |

## Einwände (Runde 5)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“, docs/02-statistikkern.md:89); ACC-8 (5); ADR-048 Nr. 15; Gate tests (`gate-tests.log` M1d r5 Z. 1195); BL-118 — **Befund:** erledigt. Der Betreiber-Commit `a08a90d` hängt den Block aus ADR-048 Nr. 15 an `_pkgdown.yml` an und ändert sonst nichts. K-M1d-5 ist im tests-Gate der Runde 5 grün, und pkgdown 2.2.1 baut den Artikelindex aus der Datei (Prüfläufe 1 und 3). — **Vorschlag:** keiner; BL-118 gestrichen.
- [E16] (minor) ACC-2 (3); ADR-049 Nr. 2; PLAN-REVIEW E2; BL-119 — **Befund:** unverändert. `items.csv.gz`, `prepare.R`, `make_llm_stability.R` und `llm-stability.Rmd` sind seit den Gates r4 blobgleich (Prüflauf 1), nach den Reviews r2 bis r4 seit Runde 1. Die Etikettenregel ist spec-konform und offengelegt. — **Vorschlag:** keine Änderung in M1d; der Betreiber entscheidet vor einer Verwendung der Zahlen im Paper.
- [E18] (minor) QA.md QA-M1d-001; BL-117; ADR-035 Nr. 1 — **Befund:** unverändert nonblocking.
  - Es gibt keinen roten reproduzierenden Test; QA-M1d-FUZZ-2 ist grün (`m1d-qa-fuzz`, 51 Erwartungen, `gate-tests.log` M1d r5 Z. 1899).
  - Die Herabstufung begründet M1d REVIEW r1 (E18): In der Vignette erreichen `m1d_findings()` nur vollständig geprüfte Tabellen, und die Sensitivität bricht bei einer reinen NA-Spalte benannt ab.
  - `inst/validation/m1d/findings.R` ist seit den Gates r4 blobgleich, nach den Reviews r2 bis r4 seit Runde 1.
  - — **Vorschlag:** Härtung nach dem 26.11.2026 (BL-117).
- [E19] (minor) M1d REVIEW r3, Prüflauf 2; `_pkgdown.yml:1` (`url: https://danielmoj.github.io/llmsa/`); `DESCRIPTION:20` (`URL: https://github.com/DanielMoj/llmsa`); `.github/workflows/pkgdown.yaml:32`; BL-121 — **Befund:** unverändert. `pkgdown::check_pkgdown()` bricht auch auf der Datei im Arbeitsbaum nur ab mit „In DESCRIPTION, URL is missing package url (https://danielmoj.github.io/llmsa).“ (Prüflauf 3). Das ist kein M1d-Kriterium; `DESCRIPTION` und die Zeile `url` sind seit `plan/M1d` unverändert. — **Vorschlag:** keine Änderung in M1d. Nach dem 26.11.2026 mit der Release-Arbeit die Seiten-URL in `DESCRIPTION` unter `URL` ergänzen (Builder) und `check_pkgdown()` erneut laufen lassen.

## Antworten auf REWORK-NOTES (Runde 5)

- **E1:** OUT-OF-TERRITORY ist richtig; der Builder hat `_pkgdown.yml` nicht angefasst, die Datei ändert sich nur in `a08a90d` (Prüflauf 1). Größe, SHA-256 und die Zeilen `_pkgdown.yml:36–43` stimmen. Sein Log unter `/tmp` endet mit `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 45 ]`, wie das Gate r5. Richtig.
- **E16:** zurückgestellt ohne Änderung, wie verlangt. Richtig.
- **E17:** in Runde 2 erledigt, nicht erneut angefasst. Die Verweise `validation.Rmd:285` und `clinvar-raters.Rmd:131` stimmen, ebenso `:1182`, `:1686` und `gate-lint.log:89` der Runde 4. Richtig.
- **E18:** zurückgestellt nach ADR-035, kein neuer QA-Lauf behauptet; der Verweis `:1943` der Runde 4 stimmt. Richtig.
- **E19:** zurückgestellt, `DESCRIPTION` unverändert, kein eigener pkgdown-Lauf behauptet; `_pkgdown.yml:1` und `DESCRIPTION:20` stimmen. Richtig.
- **E2 bis E15, M1D-QA-01:** Die Verweise `:1920` und `:1952` der Runde 4 stimmen.
- **BL-93:** Die Verweise `:778–803` der Runde 4 stimmen; in Runde 5 stehen dieselben Warnungen in Z. 783–809.
- **Integrität und Mutation:** Die Inventur bestätigt Prüflauf 1. Die Angaben zu mutgate und mutfull stimmen mit den Gate-Logs der Runde 4 überein und gelten auch in Runde 5.

## Backlog

- **Gestrichen:**
  - BL-118: K-M1d-5 im tests-Gate grün;
  - BL-92 und BL-112: mit der Abnahme von M1d, wie dort vorgesehen.
- **Stand ergänzt:** BL-93 (Warnungen auch im Gate r5), BL-117, BL-119 und BL-121 (unverändert).
- **Fällig nach `done/M1d`, Stand ergänzt:** BL-11 (Entscheidung über M3a bis M3d), BL-24 (mit ADR-047 Nr. 4 vor M3a) und BL-52 (AP1-Auswertung wiederholen).
- **Neu:** BL-122, der Kontrolllauf Mutation nach ADR-047 Nr. 3.
