# REVIEW — M1d, Runde 2

Rolle: Reviewer · Phase: `50-code-review` · Runde: 2 · Stand: 04.11.2026 · Gegenstand: Diff seit `plan/M1d` (`0511335`) bis zum Stand der Gates (`gates.json`: `env.sha` `044b06d`, Commit von Rework r2; HEAD `14e58c7` ist der Gate-Commit). Neu in dieser Runde ist nur Rework r2 (`40d7530` → `044b06d`). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` zu M1d. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK, `blocking` leer.** `gates.result` ist `fail`. Rot ist wie in Runde 1 nur das Gate tests, und dort nur der Block „K-M1d-5: both vignettes are listed under articles in _pkgdown.yml“ mit drei Erwartungen. Grund: `_pkgdown.yml` hat weiterhin keinen Abschnitt `articles`. Die Datei ist Betreiber-Territorium; der Befund bleibt [INFRA] und für den Builder nonblocking (E1).

- **Warum REWORK:** PASS verlangt `gates.result = pass`. ESCALATE scheidet aus, weil keine Spec-Stellen einander widersprechen: K-M1d-5 ist erfüllbar, nur nicht im Builder-Territorium (ADR-048 Nr. 15).
- **Rework r2:** Der Builder hat nur das optionale E17 umgesetzt, je eine Stelle in zwei Vignetten (Prüflauf 1).
  - Gestrickt zeigt die Konvergenz-Sensitivität S-ord-1 bis S-ord-4 in dieser Reihenfolge, mit denselben 109 Zeilen wie in Runde 1.
  - Die Statustabelle heißt in der Zählspalte `submissions`; die Zählungen sind unverändert (Prüflauf 2).
  - E17 ist erledigt, BL-120 gestrichen.
- **Sonst unverändert:** Alle übrigen Dateien von Paket, Tests, Daten und Ankern sind blobgleich zu Runde 1 (Prüflauf 1).
  - Alle Abnahmetests von M1d außer dem Listungsblock sind im tests-Gate grün, mit denselben Erwartungszahlen wie in Runde 1.
  - lint baut alle vier Vignetten, `Status: OK`.
- **Mutation:** mutgate („kein geänderter Mutations-Scope“, ADR-047 Nr. 1) und mutfull („nicht fällig in M1d“) sind grün. `R/fit.R` und `R/grr.R` sind seit Runde 1 unverändert. Es gibt keinen Mutationsbericht dieser Runde und keine `MUT-EQUIV.json`; ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`.
- **QA:** E18 (QA-M1d-001) bleibt nonblocking. Es gibt keinen roten reproduzierenden Test, QA-M1d-FUZZ-2 ist grün.
- **Für das Rework r3:** Der Builder hat keinen Pflichtpunkt.
  - Keine Änderung an Produkt, Vignetten, Daten oder Tests ist nötig; REWORK-NOTES mit Antworten auf E1, E16 und E18 genügt.
  - Grün wird die Runde nur mit dem Betreiber-Eintrag aus E1.

### An den Betreiber

1. **`_pkgdown.yml` (E1, M1D-INFRA-01, ADR-048 Nr. 15, BL-118).** Ergänzen, bestehende Schlüssel unverändert (in Runde 1 mit pkgdown 2.2.1 geprüft, M1d REVIEW r1, Prüflauf 5):

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

   - **Zeitpunkt.** Der Betreiber-Commit muss die Basis der nächsten Modellphase sein, sonst wird territory rot (BL-106). Rework r2 hatte keinen Builder-Befund zu beheben; ohne den Eintrag wiederholt sich Runde 2.
     - **Empfohlen:** `orchestrator/STOP` anlegen, solange `orchestrate.log` mit „RUN reviewer 50-code-review (M1d r…)“ endet. Jetzt ist das Review r2 (Z. 209).
     - Der Lauf hält dann direkt nach dem Review-Commit (`commit_phase` → `stop_check`, `orchestrate.sh:718`). Das geschieht, bevor das Verdict gelesen und `state/M1d/round` erhöht wird (`:1042`, `:1074–1077`).
     - Danach `_pkgdown.yml` ergänzen und committen, `STOP` entfernen und neu starten. Der Lauf liest das Verdict r2 und startet Rework r3 auf dem Betreiber-Commit, danach die Gates r3. territory ist dann grün, weil `HEAD^` die Audit-Basis von Rework r3 ist (`gates.d/82-territory.sh:11–14`).
   - **Falle 1, STOP nach dem Review-Commit angelegt:** Der Lauf hält dann erst in `run_model` von 60-rework (`:621`). In `orchestrator/state/M1d/round` steht schon 3. Die Datei ist seit Rework r2 versioniert (Stand 2).
     - Diese Änderung vor dem Commit auf den versionierten Stand 2 zurücknehmen, nicht löschen; dann wie oben.
     - Bleibt sie liegen, scheitert der Neustart an der Prüfung des Arbeitsbaums (`:294–297`).
     - Wird sie mitcommittet, startet der Neustart die Gates r3 ohne Rework (`:999–1003`), und territory meldet „Audit stammt aus Runde 2 statt 3“ (`82-territory.sh:9–10`).
   - **Falle 2, Halt nach einem Rework- oder Gate-Commit:** `stop_check` greift auch dort (`:718`, `:784`). Dann nichts committen, `STOP` entfernen, neu starten und `STOP` erst in der nächsten Review-Phase anlegen. Ein Commit zwischen Rework und Gates macht territory rot (BL-106).
   - **Nie während einer laufenden Modellphase** (Review, Rework, QA) `_pkgdown.yml` ändern oder committen. Die Territoriumsprüfung rechnet die Änderung der Rolle zu und setzt mit `git reset --hard` auf die Basis der Phase zurück (`:350–356`, `:551–554`, `:567–583`). Ein Betreiber-Commit verschwindet dabei aus `main`.
2. **Rundenbudget (BL-118, wie BL-105).** Der laufende Orchestrator arbeitet mit „REWORK<=5“ (`orchestrate.log` Z. 200, Start 01:01:30); `arbiter-granted` gibt es in M1d nicht.
   - Ohne den Eintrag folgen die Runden 3 bis 5 ohne Builder-Befund, je Runde ein Builder-Aufruf und ein Gate-Lauf von rund 45 Minuten (Gates r2: 04:56 bis 05:42).
   - Nach Runde 5 folgt der Arbiter (`orchestrate.sh:1063–1071`).
3. **ADR-047 Nr. 3 (unverändert):** Nach `done/M1d` den Mutationslauf ohne die Scope-Sperre einmal in einer Kopie nachrechnen, verlangt sind 92,09. Vor M3a folgt die Scope-Rückstellung nach Nr. 4 (BL-24).
4. **Etikettenregel llm-stability (E16, BL-119, unverändert):** Vor einer Verwendung der Wiederholbarkeiten und Trefferquoten aus `vignettes/llm-stability.Rmd` im Paper entscheiden, ob die Regel auf eine Salienzfolge wie in der Quelle umgestellt wird. Das ist keine Aufgabe in M1d.

## Gate-Fakten (`orchestrator/state/M1d/gates.json`, Runde 2)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 03:57:40 UTC, also nach dem Rework-Commit (04:56:41 MEZ): `creating vignettes ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK`; `installed size is 22.3Mb` als INFO (BL-114) |
| tests | **fail** | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5741 ]` (Z. 592; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 3 \| WARN 2 \| SKIP 0 \| PASS 15638 ]` (Z. 1845, Dauer 2322,7 s); e2e `[ FAIL 0 \| … PASS 319 ]` (Z. 1911); fuzz `[ FAIL 0 \| … PASS 94 ]` (Z. 1943). Kurzbefund: „674 Tests …; 1 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1944) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (builder/60-rework, Runde 2, Basis 40d7530…, 2026-11-04T04:56:41+01:00)` |
| mutgate | pass | `kein geänderter Mutations-Scope` (ADR-047 Nr. 1, `config.env:276`) |
| golden-adr | pass | `Änderung und ADR liegen im selben Meilenstein` (ADR-049 deckt `inst/extdata/`) |
| mutfull | pass | `nicht fällig in M1d` |

- **Die drei Fehlschläge** (`gate-tests.log` Z. 1188–1208, wiederholt Z. 1823–1843) liegen in `test-m1d-5-size-licence-network.R:97` und `:99`:
  - „Expected _pkgdown.yml has an articles section to be TRUE“;
  - „Expected llm-stability is listed under articles to be TRUE“;
  - „Expected clinvar-raters is listed under articles to be TRUE“.
- **Die zwei Warnungen** sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 778–805), Reviewer-Territorium, kein Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.

Erwartungen der M1d-Tests im tests-Gate der Runde 2, jeweils gleich Runde 1:

| Testdatei | Erwartungen |
| --- | --- |
| `m1d-1-llm-stability-data` | 97 (24,2 s) |
| `m1d-2-llm-stability-vignette` | 113 (15,1 s) |
| `m1d-3-clinvar-data` | 47 (546,3 s) |
| `m1d-4-clinvar-vignette` | 106 (15,2 s) |
| `m1d-5-size-licence-network` | 42 grün, 3 rot (E1) |
| `m1d-6-full-runs` | 4125 |
| `m1d-7-findings` | 512 (77,5 s), einschließlich ACC-12 |
| `m1d-8-robustness-wording` | 31 |
| Unit `m1d-data`, `m1d-findings` | 47, 48 |
| QA `m1d-qa-e2e`, `m1d-qa-fuzz`, `m1c-qa-e2e` | 224, 51, 46 |

- **Regression der Vormeilensteine** im selben Lauf grün, darunter:
  - `m0-api-snapshot` (259);
  - `m1a-7-vignette` (148);
  - `m1b-7-vignette-full-results` (204), `m1b-7-vignette` (240);
  - `m1c-5-vignette-full-results` (49), `m1c-5-vignette` (55);
  - `m2-7-robustness-pilot` (375).

## Gelesen

- **Rahmen:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/02 M1d (Voraussetzung, K-M1d-1 bis K-M1d-8).
- **Entscheidungen:** ADR-048 Nr. 7, 8, 10, 14 und 15. ADR-047 und ADR-049 habe ich nicht erneut gelesen; sie gelten wie in Runde 1 geprüft, die Runde ändert nichts an ihrem Gegenstand.
- **Handoff M1d:** `CRITERIA.json` (K-M1d-1 bis K-M1d-8, ACC-1 bis ACC-20 als Übersicht, vollständig ACC-7, ACC-8 und ACC-17), `REWORK-NOTES.md` (Runde 2), `QA.md`, `REVIEW-INPUT.md`, mein `REVIEW.md` und `verdict-code.json` der Runde 1; in `PLAN.md` und `PLAN-REVIEW.md` die Stellen zu Statustabelle und Sensitivität (PLAN Z. 111, PLAN-REVIEW E15).
- **Gates und Harness:**
  - `gates.json`, alle acht `gate-*.log`, `state/M1d/territory-ok`, `state/summary.json`;
  - `orchestrator/logs/orchestrate.log` (CONFIG-Zeile, Ereignisse M1d) und der Prompt dieser Phase;
  - `orchestrate.sh`: `fatal`, `rollback_attempt`, `restore_worktree`, `path_allowed`, `ownership_check`, `run_model`, `commit_phase`, `verdict()`, `run_gates`, `park`, `arbiter`, `run_ms`;
  - `gates.d/82-territory.sh`; `config.env` (Territorien, Runden, Mutation).
- **Diff:** seit `plan/M1d` und gegen Runde 1, Prüflauf 1; die drei Dateien des Reworks vollständig als `diff -u`.
- **Abnahme:** `tests/acceptance/test-m1d-5-size-licence-network.R:94–100`.
- **BACKLOG:** BL-92, BL-93, BL-105, BL-106 und BL-112 bis BL-120.

## Eigene Prüfläufe

Am 04.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1d/.probe-cr2/`, vor Phasenende mit `unlink()` gelöscht. Paket über `pkgload::load_all()`. Umgebung: R 4.6.1. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff ohne Git-Kommando.**
   - Vorgehen wie in Runde 1: R liest `.git/refs/tags/plan/M1d` und `refs/heads/main` und folgt Tag, Commits und Bäumen über die losen Objektdateien (`memDecompress`); es fehlte keines.
   - Blob-IDs verglichen für `plan/M1d` → HEAD, Review r1 → Rework r2 und Rework r2 → Gates r2, dazu HEAD → Arbeitsbaum.

   ```text
   base commit: 051133562fa0197a70535fb24d3afbd5c7d2a0d2
   head commit: 14e58c798ef84cd0e69d90d761c8c7d09cc568ea
   rework commit: 044b06d3a09cca4c35c55bacfb6e5b41cfc5cb24 parent: parent 40d7530a9c411f0de18dda23bb0db7b23c9ca4d0
   plan/M1d -> HEAD: files 674 -> 729; added 55 removed 0 changed 15
   review r1 -> rework r2: files 725 -> 728; added 3 removed 0 changed 7
   rework r2 -> gates r2 (HEAD): files 728 -> 729; added 1 removed 0 changed 7
   worktree differs from HEAD: 0
   ```

   - **Rework r2 ändert** `PROGRESS.md`, `vignettes/clinvar-raters.Rmd` und `vignettes/validation.Rmd` und legt `REWORK-NOTES.md` an. Die übrigen Pfade sind Orchestrator-Zustand (`STATUS.md`, `summary.json`, `current-phase`, `territory-ok`, `round`, `rework-r2.done`).
   - **`diff -u` der Vignetten:**
     - `validation.Rmd:285`: `unique(…)` wird zu `sort(unique(sensitivity$tables$scenario))`.
     - `clinvar-raters.Rmd:130–131`: `as.data.frame(table(…), responseName = "submissions", stringsAsFactors = FALSE)`.
     - Keine weitere Zeile. Kein späterer Chunk liest die alte Spalte `Freq`.
   - **Gegenüber `plan/M1d`:** 15 geänderte Dateien, dieselben Pfade wie in Runde 1. Gegenüber dem in Runde 1 geprüften Stand (`a96c7c2`, 722 Dateien) sind sieben Dateien neu, alles Handoffs und Orchestrator-Marker: `REVIEW.md`, `verdict-code.json`, `REWORK-NOTES.md`, `code-review-r1-infra0.done`, `gates-r2-infra0.done`, `rework-r2.done`, `round`.
   - **Unverändert seit Runde 1:** `R/**`, `man/**`, `tests/**`, `inst/**`, `data-raw/**`, `reference/anchors/**`, `DESCRIPTION`, `NAMESPACE`, `_pkgdown.yml` und `vignettes/llm-stability.Rmd`. `Freq` steht in keiner Datei unter `vignettes/` und `inst/validation/m1d/` mehr.
2. **Vignetten gestrickt, Runde 1 gegen Runde 2** (`knitr::knit` nach Markdown in der Probe, `root.dir` = `vignettes/`, `REPO_ROOT` gesetzt; die Fassung der Runde 1 aus dem Blob von `40d7530`):

   ```text
   vignettes/validation.Rmd -> validation-head.md: ok (16.8 s)
   .probe-cr2/out/r1/vignettes/validation.Rmd -> validation-r1.md: ok (16.3 s)
   vignettes/clinvar-raters.Rmd -> clinvar-raters-head.md: ok (7.4 s)
   .probe-cr2/out/r1/vignettes/clinvar-raters.Rmd -> clinvar-raters-r1.md: ok (7.4 s)
   sensitivity scenario headers (head): S-ord-1, S-ord-2, S-ord-3, S-ord-4
   sensitivity scenario headers (r1):   S-ord-4, S-ord-1, S-ord-2, S-ord-3
   sensitivity lines: head 109 r1 109 | same multiset: TRUE
   rest of validation identical: TRUE
   status table header (head): |subset |review_status                       | submissions|retained |
   status table header (r1):   |subset |review_status                       | Freq|retained |
   S-ord-1 : rows 12 scenarios in rows: S-ord-1
   S-ord-2 : rows 12 scenarios in rows: S-ord-2
   S-ord-3 : rows 12 scenarios in rows: S-ord-3
   S-ord-4 : rows 14 scenarios in rows: S-ord-4
   (Ausgaben zweier Aufrufe zusammengefasst, Pfade gekürzt)
   ```

   - **`validation`:** Unter jeder Szenario-Überschrift stehen nur Zeilen dieses Szenarios, zusammen 50 wie in Runde 1. Außerhalb des Abschnitts ist das gestrickte Dokument zeilengleich.
   - **`clinvar-raters`:** `diff -u` der beiden Markdown-Dateien zeigt nur den Codeblock und die Statustabelle. Diese hat die Kopfzeile `submissions`, dazu breitere Spalten. Die Zählungen 5958, 14, 675 (hrf) und 4479, 6, 488, 37 (sample) sind gleich.

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:**
  - K-M1d-1 bis K-M1d-8 sind wie in Runde 1 umgesetzt; im Gate fehlt nur die Listung aus K-M1d-5 (E1).
  - Die Änderungen der Runde 2 berühren keine Kennzahl und keine Auswahlregel.
  - K-M1d-4 und ACC-7 (5): Die Sensitivität filtert unverändert mit `startsWith(…, "criteria provided")`; die Statustabelle nennt weiterhin jeden Status mit Zeilenzahl, wie PLAN-REVIEW E15 es verlangte.
  - K-M1d-7 und ADR-048 Nr. 14.4: Die Sensitivität rechnet weiter nur aus der Replikatdatei; `findings.R` und die Ergebnisleser sind unverändert.
  - „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“: eingehalten (seit Runde 1 blobgleich, ACC-12 im Gate grün).
- **API:** kein Export, kein Argument, kein Import, keine Druckausgabe geändert; ANK-02 im Gate grün (`m0-api-snapshot`, 259).
- **Tests:** Keine Testdatei ist geändert, gelöscht oder entkernt. Der Builder hat in Runde 2 keine Tests geschrieben, es gibt also keine neue Momentaufnahme.
- **Konfiguration:** `DESCRIPTION`, `.Rbuildignore`, Gates, Schwellen und Testauswahl sind unverändert.
- **Werte, Daten, Golden:**
  - Kein neues Literal; `sort()` und der Spaltenname tragen keinen Wert aus Ergebnis- oder Ankerdateien (ADR-048 Nr. 10.1, Nr. 7.6).
  - `inst/extdata/` und `reference/anchors/` sind unverändert; golden-adr ist grün.
- **Sichtbare Defekte:** keine. `sort()` ordnet die vier IDs S-ord-1 bis S-ord-4 in jeder Locale gleich.
- **Builder-Belege:**
  - REWORK-NOTES r2 behauptet keine Abnahme und keinen Gate-Stand der Runde 2.
  - Die genannten Änderungen und die Inventur (drei geänderte Dateien, ein neuer Handoff, keine entfernte) bestätigt Prüflauf 1.
  - Die Zahlen der Vignetten-Abnahme (802 Erwartungen) und der K-M1d-5-Abnahme (42 grün, 3 rot) passen zum tests-Gate der Runde 2.

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E1 (M1D-INFRA-01) | offen, [INFRA], Betreiber | `_pkgdown.yml` unverändert seit `plan/M1d`; tests r2 rot mit denselben drei Erwartungen (BL-118) |
| E16 | offen, Betreiber-Entscheidung nach M1d | Daten, Parser und Vignette blobgleich zu Runde 1 (BL-119) |
| E17 | erledigt (Rework r2) | Prüfläufe 1 und 2; BL-120 gestrichen |
| E18 (QA-M1d-001) | nonblocking, nach dem 26.11.2026 | `findings.R` blobgleich; QA-M1d-FUZZ-2 grün (BL-117) |
| E2 bis E15 | erledigt (Runde 1) | M1d REVIEW r1, Antworten auf REVIEW-INPUT |
| M1D-QA-01 | erledigt (45-qa) | M1d REVIEW r1 |

## Einwände (Runde 2)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“, docs/02-statistikkern.md:89); ACC-8 (5); Gate tests (`gate-tests.log` M1d r2 Z. 1188–1208, 1823–1845); ADR-048 Nr. 15; BL-118 — **Befund:** unverändert seit Runde 1. `_pkgdown.yml` gleicht `plan/M1d` und hat keinen Abschnitt `articles`; die drei Erwartungen in `test-m1d-5-size-licence-network.R:97–99` sind der einzige Grund für `gates.result = fail`.
  - Die Datei liegt außerhalb der Builder-Pfade (`config.env:200`, `orchestrate.sh:515–544`).
  - ACC-8 nennt den Builder als Zuständigen. Für Nr. 5 gilt ADR-048 Nr. 15: [INFRA], Betreiber.
  - Das Rework r2 hatte deshalb keinen Pflichtpunkt.
  - — **Vorschlag:** Betreiber nach „An den Betreiber“ Nr. 1 (YAML, Zeitpunkt, Fallen). Für den Builder nicht blockierend.
- [E16] (minor) ACC-2 (3); ADR-049 Nr. 2; PLAN-REVIEW E2; BL-119 — **Befund:** unverändert. `items.csv.gz`, `prepare.R`, `make_llm_stability.R` und `llm-stability.Rmd` sind blobgleich zu Runde 1. Die Etikettenregel ist spec-konform und offengelegt; 10,8 % der Aufrufe sind nach ihr mehrdeutig (M1d REVIEW r1, Prüflauf 4). — **Vorschlag:** keine Änderung in M1d; Entscheidung des Betreibers vor einer Verwendung im Paper.
- [E17] (minor) K-M1d-7 (BL-92, ADR-048 Nr. 14.4); K-M1d-4 (PLAN-REVIEW E15); BL-120 — **Befund:** erledigt.
  - `vignettes/validation.Rmd:285` gibt die Szenarien sortiert aus.
  - `vignettes/clinvar-raters.Rmd:130–131` nennt die Zählspalte `submissions`.
  - Gestrickt mit denselben Werten wie in Runde 1 (Prüflauf 2). Im Gate sind `m1d-4-clinvar-vignette` (106) und `m1d-7-findings` (512) grün; lint baut beide Vignetten.
  - — **Vorschlag:** keiner.
- [E18] (minor) QA.md QA-M1d-001; BL-117; ADR-035 Nr. 1 — **Befund:** unverändert nonblocking.
  - Es gibt keinen roten reproduzierenden Test; QA-M1d-FUZZ-2 ist grün (`m1d-qa-fuzz`, 51 Erwartungen).
  - Die Herabstufung begründet M1d REVIEW r1 (E18): In der Vignette erreichen `m1d_findings()` nur vollständig geprüfte Tabellen, und die Sensitivität bricht bei einer reinen NA-Spalte benannt ab.
  - `inst/validation/m1d/findings.R` ist blobgleich zu Runde 1.
  - — **Vorschlag:** Härtung nach dem 26.11.2026 (BL-117).

## Antworten auf REWORK-NOTES (Runde 2)

- **E1:** OUT-OF-TERRITORY bestätigt; kein Scheinfix im Produkt. Richtig.
- **E16:** zurückgestellt ohne Änderung, wie verlangt. Richtig.
- **E17:** akzeptiert und behoben; am Code und an den gestrickten Vignetten nachvollzogen (Prüfläufe 1 und 2).
- **E18:** zurückgestellt nach ADR-035, kein neuer QA-Lauf behauptet. Richtig.
- **BL-93, Mutation, M1D-QA-01:** Die Angaben stimmen mit den Gate-Logs der Runde 2 überein.

## Backlog

- **Gestrichen:** BL-120 (E17, erledigt in Rework r2).
- **Stand ergänzt:**
  - BL-118: Gate r2 wieder rot; Rundenbudget; Zeitpunkt und Fallen für den Betreiber-Commit;
  - BL-93: Warnungen auch im Gate r2;
  - BL-117: unverändert nonblocking;
  - BL-119: unverändert.
- BL-92 und BL-112 bleiben bis zur Abnahme von M1d stehen (Streichung dann).
