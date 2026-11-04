# REVIEW — M1d, Runde 3

Rolle: Reviewer · Phase: `50-code-review` · Runde: 3 · Stand: 04.11.2026 · Gegenstand: Diff seit `plan/M1d` (`0511335`) bis zum Stand der Gates (`gates.json`: `env.sha` `6d03fe5`, Commit von Rework r3; HEAD `46c81b1` ist der Gate-Commit). Neu in dieser Runde ist nur Rework r3 (`93c2a3d` → `6d03fe5`). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` noch `MUT-EQUIV.json` zu M1d. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK, `blocking` leer.** `gates.result` ist `fail`. Rot ist wie in Runde 1 und 2 nur das Gate tests, und dort nur der Block „K-M1d-5: both vignettes are listed under articles in _pkgdown.yml“ mit drei Erwartungen. `_pkgdown.yml` gleicht weiterhin `plan/M1d` und hat keinen Abschnitt `articles` (Prüflauf 1). Die Datei ist Betreiber-Territorium; der Befund bleibt [INFRA] und für den Builder nonblocking (E1).

- **Warum REWORK:** PASS verlangt `gates.result = pass`. ESCALATE scheidet aus, weil keine Spec-Stellen einander widersprechen. K-M1d-5 ist erfüllbar: Mit dem Betreiber-YAML besteht die unveränderte Abnahme K-M1d-5 auf einer Paketkopie vollständig (Prüflauf 2).
- **Rework r3:** Der Builder hat nur `PROGRESS.md` und `REWORK-NOTES.md` geändert (Prüflauf 1). Seine Belege stimmen:
  - Die gezielte K-M1d-5-Abnahme (42 grün, 3 rot) deckt sich mit dem Gate r3.
  - Alle Zeilenverweise auf das Gate-Log der Runde 2 stimmen (Prüflauf 1).
- **Sonst unverändert:** `R/**`, `man/**`, `tests/**`, `inst/**`, `data-raw/**`, `vignettes/**`, `reference/anchors/**`, `DESCRIPTION`, `NAMESPACE` und `_pkgdown.yml` sind blobgleich zu Runde 2. Seit Review r1 haben sich außerhalb von Handoffs, `BACKLOG.md` und `PROGRESS.md` nur die beiden Vignetten aus E17 geändert (Rework r2).
  - Alle Abnahmetests von M1d außer dem Listungsblock sind im tests-Gate grün, mit denselben Erwartungszahlen wie in Runde 1 und 2.
  - lint baut alle vier Vignetten, `Status: OK`.
- **Mutation:** mutgate („kein geänderter Mutations-Scope“, ADR-047 Nr. 1) und mutfull („nicht fällig in M1d“) sind grün. Es gibt keinen Mutationsbericht dieser Runde und keine `MUT-EQUIV.json`; ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`.
- **QA:** E18 (QA-M1d-001) bleibt nonblocking. Es gibt keinen roten reproduzierenden Test, QA-M1d-FUZZ-2 ist grün.
- **Neu, nonblocking:** E19. `pkgdown::check_pkgdown()` meldet eine URL-Abweichung zwischen `DESCRIPTION` und `_pkgdown.yml` (Prüflauf 2). Kein M1d-Kriterium, keine Änderung in M1d (BL-121).
- **Für das Rework r4:** Der Builder hat keinen Pflichtpunkt.
  - REWORK-NOTES mit Antworten auf E1, E16, E18 und E19 genügt.
  - Ausdrücklich keine Änderung an Produkt, `DESCRIPTION`, Vignetten, Daten oder Tests, auch nicht für E19. Dann hängt das Ergebnis der Runde 4 nur am Betreiber-Eintrag aus E1.

### An den Betreiber

1. **`_pkgdown.yml` (E1, M1D-INFRA-01, ADR-048 Nr. 15, BL-118).** Ergänzen, bestehende Schlüssel unverändert:

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

   - **Wirkung, geprüft (Prüflauf 2):** Ich habe den Block an die unveränderte Datei angehängt, in einer Paketkopie unter `tempdir()`, mit pkgdown 2.2.1.
     - Die bisherigen Schlüssel `url`, `destination`, `template` und `reference` bleiben gleich.
     - Die unveränderte Abnahmedatei `test-m1d-5-size-licence-network.R` besteht vollständig: 6 Blöcke, 45 Erwartungen, 0 rot.
     - pkgdown baut den Artikelindex „Validation: validation | Applications: llm-stability, clinvar-raters“. Ohne `validation` bricht pkgdown mit „1 vignette missing from index“ ab.
   - **Zeitpunkt.** Der Betreiber-Commit muss die Basis der nächsten Modellphase sein, sonst wird territory rot (BL-106). In den Runden 2 und 3 ist der Eintrag ausgeblieben; deshalb wiederholt sich das Ergebnis.
     - **Empfohlen, jetzt:** `orchestrator/STOP` anlegen. `orchestrate.log` endet mit „RUN reviewer 50-code-review (M1d r3, Versuch 1)“ (Z. 211), und STOP liegt noch nicht.
     - Der Lauf hält dann direkt nach dem Review-Commit (`commit_phase` → `stop_check`, `orchestrate.sh:718`). Das geschieht, bevor das Verdict gelesen und `state/M1d/round` erhöht wird (`:1042`, `:1074–1077`). `fatal` beendet den Lauf mit Exit 2 und gibt die Sperre `orchestrator/.lock` frei (`:88–95`, `:97–105`, `:117`).
     - Danach `_pkgdown.yml` ergänzen und nur diese Datei stagen und committen (`git add _pkgdown.yml`). Kein `git add -A`: Das nähme `orchestrator/STOP` mit in den Commit. `STATUS.md` und `orchestrator/state/summary.json` dürfen geändert liegen bleiben, der Preflight nimmt sie aus (`:294–297`).
     - Dann `STOP` entfernen und neu starten. Der Lauf liest das Verdict r3 und startet Rework r4 auf dem Betreiber-Commit, danach die Gates r4. territory ist dann grün, weil `HEAD^` die Audit-Basis von Rework r4 ist (`gates.d/82-territory.sh:11–14`). Für das tests-Gate zeigt Prüflauf 2 die Wirkung auf K-M1d-5.
   - **Falle 1, STOP erst nach dem Review-Commit angelegt:** Der Lauf hält dann erst in `run_model` von 60-rework (`:621`). In `orchestrator/state/M1d/round` steht dann schon 4; versioniert ist 3.
     - Diese Änderung vor dem Commit auf den versionierten Stand 3 zurücknehmen, nicht löschen; dann wie oben.
     - Bleibt sie liegen, scheitert der Neustart an der Prüfung des Arbeitsbaums (`:294–297`).
     - Wird sie mitcommittet, startet der Neustart die Gates r4 ohne Rework (`:999–1003`), und territory meldet „Audit stammt aus Runde 3 statt 4“ (`82-territory.sh:9–10`).
   - **Falle 2, Halt nach einem Rework- oder Gate-Commit:** `stop_check` greift auch dort (`:718`, `:784`). Dann nichts committen, `STOP` entfernen, neu starten und `STOP` erst in der nächsten Review-Phase anlegen. Ein Commit zwischen Rework und Gates macht territory rot (BL-106).
   - **Nie während einer laufenden Modellphase** (Review, Rework, QA) `_pkgdown.yml` ändern oder committen. Die Territoriumsprüfung rechnet die Änderung der Rolle zu und setzt mit `git reset --hard` auf die Basis der Phase zurück (`:350–356`, `:551–554`).
2. **Rundenbudget (BL-118, wie BL-105).** Der laufende Orchestrator arbeitet mit „REWORK<=5“ (`orchestrate.log` Z. 200, Start 01:01:30); `arbiter-granted` gibt es in M1d nicht.
   - Ohne den Eintrag folgen die Runden 4 und 5 ohne Builder-Befund. Jede kostet einen Builder-Aufruf und einen Gate-Lauf von rund 45 Minuten (Gates r3: 06:02 bis 06:47).
   - Nach dem Review r5 folgt der Arbiter (`orchestrate.sh:1063–1071`). Er entscheidet „ausschließlich die referenzierten blocking-Punkte“ (`:848`), und `blocking` ist leer. RESOLVE gibt zwei Zusatzrunden (`:1071`); HUMAN parkt M1d (`:1067`).
   - Kein Rebuild: `LADDER_ENABLED` ist leer und bei `AUTONOMY_LEVEL=1` gleich 0 (`orchestrate.sh:45`, `:1078`).
3. **ADR-047 Nr. 3 (unverändert):** Nach `done/M1d` den Mutationslauf ohne die Scope-Sperre einmal in einer Kopie nachrechnen, verlangt sind 92,09. Vor M3a folgt die Scope-Rückstellung nach Nr. 4 (BL-24).
4. **Etikettenregel llm-stability (E16, BL-119, unverändert):** Vor einer Verwendung der Wiederholbarkeiten und Trefferquoten aus `vignettes/llm-stability.Rmd` im Paper entscheiden, ob die Regel auf eine Salienzfolge wie in der Quelle umgestellt wird. Das ist keine Aufgabe in M1d.
5. **URL der pkgdown-Seite (E19, BL-121, neu):** Der Eintrag aus Nr. 1 behebt E19 nicht und soll es auch nicht. `url` in `_pkgdown.yml` bleibt unverändert; die Abhilfe gehört nach dem 26.11.2026 in `DESCRIPTION` (Builder).

## Gate-Fakten (`orchestrator/state/M1d/gates.json`, Runde 3)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 05:02:49 UTC, also nach dem Rework-Commit (06:01:53 MEZ): `creating vignettes ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK`; `installed size is 22.3Mb` als INFO (BL-114) |
| tests | **fail** | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5741 ]` (Z. 589; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 3 \| WARN 2 \| SKIP 0 \| PASS 15638 ]` (Z. 1851, Dauer 2316,9 s); e2e `[ FAIL 0 \| … PASS 319 ]` (Z. 1917); fuzz `[ FAIL 0 \| … PASS 94 ]` (Z. 1950). Kurzbefund: „674 Tests …; 1 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1951) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (builder/60-rework, Runde 3, Basis 93c2a3d…, 2026-11-04T06:01:53+01:00)` |
| mutgate | pass | `kein geänderter Mutations-Scope` (ADR-047 Nr. 1) |
| golden-adr | pass | `Änderung und ADR liegen im selben Meilenstein` (ADR-049 deckt `inst/extdata/`) |
| mutfull | pass | `nicht fällig in M1d` |

- **Die drei Fehlschläge** (`gate-tests.log` Z. 1192–1210, wiederholt Z. 1829–1851) liegen in `test-m1d-5-size-licence-network.R:97` und `:99`:
  - „Expected _pkgdown.yml has an articles section to be TRUE“;
  - „Expected llm-stability is listed under articles to be TRUE“;
  - „Expected clinvar-raters is listed under articles to be TRUE“.
- **Die zwei Warnungen** sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 778–804), Reviewer-Territorium, kein Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.

Erwartungen der M1d-Tests im tests-Gate der Runde 3, jeweils gleich Runde 1 und 2:

| Testdatei | Erwartungen |
| --- | --- |
| `m1d-1-llm-stability-data` | 97 (24,4 s) |
| `m1d-2-llm-stability-vignette` | 113 (15,4 s) |
| `m1d-3-clinvar-data` | 47 (542,9 s) |
| `m1d-4-clinvar-vignette` | 106 (15,5 s) |
| `m1d-5-size-licence-network` | 42 grün, 3 rot (E1) |
| `m1d-6-full-runs` | 4125 |
| `m1d-7-findings` | 512 (79,2 s), einschließlich ACC-12 |
| `m1d-8-robustness-wording` | 31 |
| Unit `m1d-data`, `m1d-findings` | 47, 48 |
| QA `m1d-qa-e2e`, `m1d-qa-fuzz`, `m1c-qa-e2e` | 224, 51, 46 |

- **Regression der Vormeilensteine** im selben Lauf grün, darunter:
  - `m0-api-snapshot` (259);
  - `m1a-7-vignette` (148);
  - `m1b-7-vignette-full-results` (204), `m1b-7-vignette` (240);
  - `m1c-5-vignette-full-results` (49), `m1c-5-vignette` (55), `m1c-8-check-runs` (94), `m1c-8-iteration-limit` (62);
  - `m2-7-robustness-pilot` (375).

## Gelesen

- **Rahmen:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:** docs/02 M1d (Voraussetzung, Abbildungen, K-M1d-1 bis K-M1d-8).
- **Entscheidungen:** ADR-048 (Status, Kontext, Nr. 8, 10 bis 15, Konsequenzen). ADR-047 und ADR-049 habe ich nicht erneut gelesen; sie gelten wie in Runde 1 geprüft, die Runde ändert nichts an ihrem Gegenstand.
- **Handoff M1d:** `CRITERIA.json` (K-M1d-1 bis K-M1d-8, ACC-1 bis ACC-20), `REWORK-NOTES.md` (Runde 3, dazu die Fassung der Runde 2 als Blob), `QA.md`, `REVIEW-INPUT.md`, mein `REVIEW.md` und `verdict-code.json` der Runde 2. `PLAN.md` und `PLAN-REVIEW.md` nicht erneut; die Runde berührt keine Planstelle.
- **Gates und Harness:**
  - `gates.json`, alle acht `gate-*.log`, `state/M1d/territory-ok`, `round`, `current-phase`;
  - `orchestrator/logs/orchestrate.log` (CONFIG-Zeile, Ereignisse M1d) und der Prompt dieser Phase;
  - `orchestrate.sh`: Vorgaben je `AUTONOMY_LEVEL`, `fatal`, `release_lock`, `stop_check`, Preflight, `path_allowed`, `commit_phase`, `model_phase`, `park`, `arbiter`, `run_ms`;
  - `gates.d/82-territory.sh`; `config.env` (Territorien, Runden).
- **Diff:** seit `plan/M1d`, gegen Review r1 und gegen Review r2 (Prüflauf 1); die zwei Builder-Dateien des Reworks vollständig als `diff -u`.
- **Abnahme:** `tests/acceptance/test-m1d-5-size-licence-network.R` vollständig.
- **BACKLOG:** BL-92, BL-93, BL-105, BL-106 und BL-112 bis BL-120.

## Eigene Prüfläufe

Am 04.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1d/.probe-cr3/`, vor Phasenende mit `unlink()` gelöscht. Umgebung: R 4.6.1, pkgdown 2.2.1. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff ohne Git-Kommando.**
   - Vorgehen wie in Runde 1 und 2: R liest `.git/refs/tags/plan/M1d` und `refs/heads/main` und folgt Tag, Commits und Bäumen über die losen Objektdateien (`memDecompress`); es fehlte keines.
   - Blob-IDs verglichen für `plan/M1d` → HEAD, Review r1 → HEAD, Review r2 → Rework r3 und Rework r3 → Gates r3, dazu HEAD → Arbeitsbaum.

   ```text
   base commit: 051133562fa0197a70535fb24d3afbd5c7d2a0d2
   head commit: 46c81b19431dff576eb8ed4439336c69997ccf34 msg: orch(M1d): gates r3 (rc=1) parent: 6d03fe5028149d1a5c4753db27cade5e7dee467d
   rework commit: 6d03fe5028149d1a5c4753db27cade5e7dee467d msg: orch(M1d): builder 60-rework r3 parent: 93c2a3d2b3e50771abff876f4ec52e766eb60281
   plan/M1d -> HEAD: files 674 -> 732; added 58 removed 0 changed 15
   review r2 -> rework r3: files 730 -> 731; added 1 removed 0 changed 7
     rework r3 added: orchestrator/state/M1d/rework-r3.done
     rework r3 changed: PROGRESS.md STATUS.md orchestrator/handoff/M1d/REWORK-NOTES.md orchestrator/state/M1d/current-phase orchestrator/state/M1d/round orchestrator/state/M1d/territory-ok orchestrator/state/summary.json
   rework r3 -> gates r3 (HEAD): files 731 -> 732; added 1 removed 0 changed 7
   worktree differs from HEAD: 0
   product/test/data/spec paths touched since review r2: 0
   _pkgdown.yml base == head: TRUE
   review r1 -> HEAD: files 725 -> 732; added 7 removed 0 changed 14
     non-orchestrator changes since review r1: BACKLOG.md orchestrator/handoff/M1d/REVIEW.md orchestrator/handoff/M1d/REWORK-NOTES.md orchestrator/handoff/M1d/verdict-code.json PROGRESS.md vignettes/clinvar-raters.Rmd vignettes/validation.Rmd
   r2 log 1183: ✔ |        106 | m1d-4-clinvar-vignette [15.2s]
   r2 log 1681: ✔ |        512 | m1d-7-findings [77.5s]
   r2 log 1934: ✔ |         51 | m1d-qa-fuzz
   (Auszug; die übrigen geprüften Zeilen 780, 793, 1190, 1824, 1845, 1911, 1943 tragen den jeweils genannten Inhalt)
   ```

   - **Rework r3 ändert** nur `PROGRESS.md` und `REWORK-NOTES.md`; die übrigen Pfade sind Orchestrator-Zustand (`round` 2 → 3).
   - **`diff -u` von `PROGRESS.md`:** nur ein neuer Abschnitt „M1d — REWORK, Runde 3“ am Anfang. Die älteren Einträge sind unverändert.
   - **`REWORK-NOTES.md`:** vollständig neu für Runde 3; Inhalt unten unter „Antworten“ geprüft.
   - **Gegenüber `plan/M1d`:** dieselben 15 geänderten Pfade wie in Runde 1 und 2. Kein Abnahmetest unter `tests/acceptance/` ist seit `plan/M1d` geändert. `DESCRIPTION` ist unverändert.
   - **Die Zeilenverweise des Builders** auf das Gate-Log der Runde 2 (Blob im Baum von Rework r3) treffen alle den genannten Inhalt.
2. **`_pkgdown.yml` mit dem Betreiber-Block, auf einer Paketkopie.**
   - Vorgehen: `DESCRIPTION`, `NAMESPACE`, `R/`, `inst/`, `data/`, `man/`, `vignettes/`, `docs/`, `reference/anchors/`, `tests/acceptance/`, `.Rbuildignore` und `_pkgdown.yml` nach `tempdir()` kopiert.
   - Dort den YAML-Block aus „An den Betreiber“ Nr. 1 an die unveränderte `_pkgdown.yml` angehängt, `REPO_ROOT` auf die Kopie gesetzt und `testthat::test_dir(…, filter = "^m1d-5-", load_package = "source")` ausgeführt.
   - Danach den Artikelindex mit `pkgdown:::data_articles_index()` gebildet, für drei Fassungen: mit dem Block, ohne `validation` und für die heutige Datei. Die Kopie ist gelöscht; am Arbeitsbaum ist nichts geändert.

   ```text
   existing keys kept unchanged: TRUE | keys: url destination template reference articles
   listed under articles: validation llm-stability clinvar-raters
   m1d-5-size-licence-network: .............................................
   K-M1d-5 on the copy with articles: 6 blocks, 0 failed, 0 errors, 0 skipped, 45 passed expectations
   pkgdown 2.2.1
   check_pkgdown with the proposed block: In DESCRIPTION, URL is missing package url
   (https://danielmoj.github.io/llmsa).
   articles index with the proposed block: ok; Validation: validation | Applications: llm-stability, clinvar-raters
   articles index without validation: error: In _pkgdown.yml, 1 vignette missing from index: "validation".
   articles index of the current _pkgdown.yml: ok; All vignettes: clinvar-raters, llm-stability, llmsa, validation
   DESCRIPTION URL field: https://github.com/DanielMoj/llmsa
   ```

   - Die Meldung von `check_pkgdown()` ist unabhängig vom Block. Sie kommt aus `check_urls()`, weil `DESCRIPTION` die Seiten-URL aus `_pkgdown.yml` nicht nennt (E19).
   - `build_site_local()` ruft dieselbe Prüfung über `pkgdown_sitrep()` auf. Dort fängt `error_to_sitrep()` den Fehler ab und meldet nur „URLs not ok.“. Der Seitenbau bricht daran nicht ab. Ein fehlender Index-Eintrag bricht dagegen den Seitenbau ab.

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:** K-M1d-1 bis K-M1d-8 sind wie in Runde 1 umgesetzt, mit der Darstellungsänderung E17 aus Runde 2. Im Gate fehlt nur die Listung aus K-M1d-5 (E1). Die Runde 3 berührt keine Kennzahl, keine Auswahlregel und keine Datei des Pakets. „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ ist eingehalten (ACC-12 im Gate grün).
- **API:** kein Export, kein Argument, kein Import, keine Druckausgabe geändert; ANK-02 im Gate grün (`m0-api-snapshot`, 259).
- **Tests:** Keine Testdatei ist geändert, gelöscht oder entkernt; seit `plan/M1d` ist kein Abnahmetest verändert. Der Builder hat in Runde 3 keine Tests geschrieben, es gibt also keine neue Momentaufnahme.
- **Konfiguration:** `DESCRIPTION`, `.Rbuildignore`, Gates, Schwellen und Testauswahl sind unverändert.
- **Werte, Daten, Golden:** kein neues Literal im Paket; `inst/extdata/` und `reference/anchors/` sind unverändert; golden-adr ist grün.
- **Sichtbare Defekte:** keiner in M1d. Die URL-Abweichung aus E19 besteht schon vor M1d.
- **Builder-Belege:**
  - REWORK-NOTES r3 behauptet keine Abnahme und keinen Gate-Stand der Runde 3.
  - Die Inventur „2 changed; 0 new; 0 removed“ bestätigt Prüflauf 1 unabhängig, über die Blob-IDs statt über das Skript des Builders unter `/tmp`.
  - Die gezielte K-M1d-5-Abnahme (`[ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]`) passt zum tests-Gate der Runde 3: 42 grün, 3 rot.

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E1 (M1D-INFRA-01) | offen, [INFRA], Betreiber | `_pkgdown.yml` unverändert seit `plan/M1d`; tests r3 rot mit denselben drei Erwartungen; Wirkung des YAML belegt (Prüflauf 2; BL-118) |
| E16 | offen, Betreiber-Entscheidung nach M1d | Daten, Parser und Vignette blobgleich zu Runde 1 (BL-119) |
| E17 | erledigt (Rework r2) | M1d REVIEW r2; Vignetten seit Runde 2 blobgleich; BL-120 gestrichen |
| E18 (QA-M1d-001) | nonblocking, nach dem 26.11.2026 | `findings.R` blobgleich; QA-M1d-FUZZ-2 grün (BL-117) |
| E19 | neu, nonblocking, nach M1d | Prüflauf 2 (BL-121) |
| E2 bis E15 | erledigt (Runde 1) | M1d REVIEW r1, Antworten auf REVIEW-INPUT |
| M1D-QA-01 | erledigt (45-qa) | M1d REVIEW r1 |

## Einwände (Runde 3)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“, docs/02-statistikkern.md:89); ACC-8 (5); Gate tests (`gate-tests.log` M1d r3 Z. 1192–1210, 1829–1851); ADR-048 Nr. 15; BL-118 — **Befund:** unverändert seit Runde 1. `_pkgdown.yml` gleicht `plan/M1d` und hat keinen Abschnitt `articles`; die drei Erwartungen in `test-m1d-5-size-licence-network.R:97–99` sind der einzige Grund für `gates.result = fail`.
  - Die Datei liegt außerhalb der Builder-Pfade (`config.env:200`, `orchestrate.sh:515–544`) und der Reviewer-Pfade dieser Phase (`orchestrate.sh:522`, `config.env:201`).
  - ACC-8 nennt den Builder als Zuständigen. Für Nr. 5 gilt ADR-048 Nr. 15: [INFRA], Betreiber.
  - Mit dem Betreiber-YAML besteht K-M1d-5 vollständig (Prüflauf 2).
  - — **Vorschlag:** Betreiber nach „An den Betreiber“ Nr. 1 (YAML, Zeitpunkt, nur `_pkgdown.yml` stagen, Fallen). Für den Builder nicht blockierend.
- [E16] (minor) ACC-2 (3); ADR-049 Nr. 2; PLAN-REVIEW E2; BL-119 — **Befund:** unverändert. `items.csv.gz`, `prepare.R`, `make_llm_stability.R` und `llm-stability.Rmd` sind blobgleich zu Runde 1. Die Etikettenregel ist spec-konform und offengelegt. — **Vorschlag:** keine Änderung in M1d; Entscheidung des Betreibers vor einer Verwendung im Paper.
- [E18] (minor) QA.md QA-M1d-001; BL-117; ADR-035 Nr. 1 — **Befund:** unverändert nonblocking.
  - Es gibt keinen roten reproduzierenden Test; QA-M1d-FUZZ-2 ist grün (`m1d-qa-fuzz`, 51 Erwartungen, `gate-tests.log` M1d r3 Z. 1941).
  - Die Herabstufung begründet M1d REVIEW r1 (E18): In der Vignette erreichen `m1d_findings()` nur vollständig geprüfte Tabellen, und die Sensitivität bricht bei einer reinen NA-Spalte benannt ab.
  - `inst/validation/m1d/findings.R` ist blobgleich zu Runde 1.
  - — **Vorschlag:** Härtung nach dem 26.11.2026 (BL-117).
- [E19] (minor) Prüflauf 2; `_pkgdown.yml` (`url: https://danielmoj.github.io/llmsa/`); `DESCRIPTION` (`URL: https://github.com/DanielMoj/llmsa`); `.github/workflows/pkgdown.yaml:32`; BL-121 — **Befund:** `pkgdown::check_pkgdown()` bricht ab mit „In DESCRIPTION, URL is missing package url (https://danielmoj.github.io/llmsa).“
  - Beim Seitenbau des Workflows (`build_site_github_pages()` → `build_site_local()` → `pkgdown_sitrep()`) erscheint nur „URLs not ok.“, ohne Abbruch (pkgdown 2.2.1).
  - Kein M1d-Kriterium. Beide Dateien sind seit `plan/M1d` unverändert; der Befund ist älter als M1d.
  - — **Vorschlag:** keine Änderung in M1d, auch nicht im Rework r4. Eine Änderung an `DESCRIPTION` liefe durch die CRAN-Eingangsprüfung im lint-Gate, und Runde 4 soll nur am Betreiber-Eintrag hängen. Nach dem 26.11.2026 mit der Release-Arbeit (wie BL-114): die Seiten-URL in `DESCRIPTION` unter `URL` ergänzen (Builder) und `check_pkgdown()` erneut laufen lassen.

## Antworten auf REWORK-NOTES (Runde 3)

- **E1:** OUT-OF-TERRITORY bestätigt; kein Scheinfix im Produkt. Die Reproduktion mit 42 grün und 3 rot deckt sich mit dem Gate r3. Richtig.
- **E16:** zurückgestellt ohne Änderung, wie verlangt. Richtig.
- **E17:** in Runde 2 erledigt, in Runde 3 nicht erneut angefasst; die Verweise `:1183` und `:1681` auf das Log der Runde 2 stimmen. Richtig.
- **E18:** zurückgestellt nach ADR-035, kein neuer QA-Lauf behauptet; der Verweis `:1934` stimmt. Richtig.
- **Betreiberübergabe:** YAML gleich M1d REVIEW r2; seine Wirkung belegt Prüflauf 2.
- **Integrität, BL-93, Mutation:** Die Inventur (nur `PROGRESS.md` und `REWORK-NOTES.md` geändert) bestätigt Prüflauf 1. Die Angaben zu BL-93 (`:780–805`) und zu mutgate/mutfull stimmen mit den Gate-Logs der Runde 2 überein und gelten auch in Runde 3.

## Backlog

- **Neu:** BL-121 (E19).
- **Stand ergänzt:**
  - BL-118: Gate r3 wieder rot; Wirkung des YAML belegt; nur `_pkgdown.yml` stagen; Falle 1 jetzt mit `round` 4 → 3; verbleibend Runden 4 und 5, dann der Arbiter;
  - BL-93: Warnungen auch im Gate r3;
  - BL-117: unverändert nonblocking;
  - BL-119: unverändert.
- BL-92 und BL-112 bleiben bis zur Abnahme von M1d stehen (Streichung dann).
