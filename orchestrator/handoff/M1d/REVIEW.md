# REVIEW — M1d, Runde 4

Rolle: Reviewer · Phase: `50-code-review` · Runde: 4 · Stand: 04.11.2026 · Gegenstand: Diff seit `plan/M1d` (`0511335`) bis zum Stand der Gates (`gates.json`: `env.sha` `77c1485`, Commit von Rework r4; HEAD `0bc6b6b` ist der Gate-Commit). Neu in dieser Runde ist nur Rework r4 (`05de457` → `77c1485`). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` noch `MUT-EQUIV.json` zu M1d. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK, `blocking` leer.** `gates.result` ist `fail`. Rot ist wie in den Runden 1 bis 3 nur das Gate tests, und dort nur der Block „K-M1d-5: both vignettes are listed under articles in _pkgdown.yml“ mit drei Erwartungen. `_pkgdown.yml` gleicht weiterhin `plan/M1d` und hat keinen Abschnitt `articles` (Prüflauf 1). Die Datei ist Betreiber-Territorium; der Befund bleibt [INFRA] und für den Builder nonblocking (E1).

- **Neu: `orchestrator/STOP` liegt**, angelegt um 07:52:12, also während dieses Reviews (Start 07:51:58, `orchestrate.log` Z. 213). Das ist der in Runde 3 empfohlene Zeitpunkt.
  - Der Lauf hält direkt nach dem Commit dieses Reviews. Er liest das Verdict noch nicht und erhöht `state/M1d/round` nicht.
  - Es fehlt nur noch der Betreiber-Commit von `_pkgdown.yml` (An den Betreiber, Nr. 1).
- **Warum REWORK:** PASS verlangt `gates.result = pass`. ESCALATE scheidet aus, weil keine Spec-Stellen einander widersprechen. K-M1d-5 ist erfüllbar: Mit genau den Bytes aus Nr. 1 besteht die unveränderte Abnahme K-M1d-5 auf einer Paketkopie vollständig (Prüflauf 2).
- **Rework r4:** Der Builder hat nur `PROGRESS.md` und `REWORK-NOTES.md` geändert (Prüflauf 1). Seine Belege stimmen:
  - Die gezielte K-M1d-5-Abnahme (42 grün, 3 rot) deckt sich mit dem Gate r4. Sein Log `/tmp/llmsa-m1d-r4-f1rjqj2b/pkgdown-acceptance.log` liegt vor und endet mit derselben Zusammenfassung.
  - Alle Zeilenverweise treffen den genannten Inhalt: die auf die Gate-Logs der Runde 3 und die auf `validation.Rmd:285`, `clinvar-raters.Rmd:131` und `DESCRIPTION:20`.
- **Sonst unverändert:** Seit den Gates r3 hat sich unter `R/`, `man/`, `tests/`, `inst/`, `data/`, `data-raw/`, `vignettes/`, `reference/anchors/` und `docs/` nichts geändert, ebenso wenig an `DESCRIPTION`, `NAMESPACE`, `_pkgdown.yml` und `.Rbuildignore`.
  - Alle Abnahmetests von M1d außer dem Listungsblock sind im tests-Gate grün, mit denselben Erwartungszahlen wie in den Runden 1 bis 3.
  - lint baut alle vier Vignetten, `Status: OK`.
- **Mutation:** mutgate („kein geänderter Mutations-Scope“, ADR-047 Nr. 1) und mutfull („nicht fällig in M1d“) sind grün.
  - Es gibt keinen Mutationsbericht dieser Runde. `reports/mutation/mutation.json` stammt vom 03.11., 13:25, also aus M1c.
  - Es gibt keine `MUT-EQUIV.json`; ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`.
- **QA:** E18 (QA-M1d-001) bleibt nonblocking. Es gibt keinen roten reproduzierenden Test, QA-M1d-FUZZ-2 ist grün.
- **Für das Rework r5:** Der Builder hat keinen Pflichtpunkt.
  - REWORK-NOTES mit Antworten auf E1, E16, E18 und E19 genügt.
  - Steht der Abschnitt `articles` in `_pkgdown.yml` der Phasenbasis, die gezielte K-M1d-5-Abnahme erneut ausführen und den echten Output nennen. Nach Prüflauf 2 sind 45 grüne Erwartungen zu erwarten. Ein Ergebnis der Gates r5 nicht vorwegnehmen.
  - Ausdrücklich keine Änderung an Produkt, `DESCRIPTION`, `_pkgdown.yml`, Vignetten, Daten oder Tests, auch nicht für E19.

### An den Betreiber

**1. `_pkgdown.yml` jetzt ergänzen, nach dem Halt (E1, M1D-INFRA-01, ADR-048 Nr. 15, BL-118).**

- **Halt abwarten, STOP bis dahin liegen lassen.**
  - Nach dem Review-Commit ruft `commit_phase` die Prüfung `stop_check` auf (`orchestrate.sh:718`, `:150–152`).
  - Der Lauf endet dann mit „FATAL: STOP-Datei gefunden — vor der nächsten Phase angehalten.“ und Exit 2. Die Sperre `orchestrator/.lock` wird freigegeben (`:88–95`, `:97–105`, `:117`). Diese FATAL-Meldung, auch per ntfy, ist hier gewollt.
  - Das Verdict r4 ist dann noch nicht gelesen; `state/M1d/round` steht auf dem versionierten Wert 4 (`:1042`, `:1074–1077`).
- **Schritt A: anhängen und prüfen**, mit absoluten Pfaden. Der Block beginnt mit einer Leerzeile und wird ohne Einrückung übernommen, so wie er hier steht:

```sh
cat >> /mnt/c/Users/Danie/dev/Llmsa/llmsa/_pkgdown.yml <<'EOF'

articles:
- title: Validation
  contents:
  - validation
- title: Applications
  contents:
  - llm-stability
  - clinvar-raters
EOF
sha256sum /mnt/c/Users/Danie/dev/Llmsa/llmsa/_pkgdown.yml
```

- **Prüfsumme:** erwartet `7e465e038e78aa7b5cd90c2caebd909c74ab588298a1a765a594c00c12c3b671`, 703 Byte (Prüflauf 2). Weicht sie ab, ist eine andere Bytefolge angehängt worden; dann die Datei ansehen, bevor committet wird. Die Abnahme prüft nur den Inhalt (`yaml::read_yaml`), nicht die Prüfsumme.
- **Schritt B: committen und STOP entfernen**, erst nach dem Vergleich:

```sh
git -C /mnt/c/Users/Danie/dev/Llmsa/llmsa add _pkgdown.yml
git -C /mnt/c/Users/Danie/dev/Llmsa/llmsa commit -m "M1d: list the vignettes under articles in _pkgdown.yml (BL-118)"
rm /mnt/c/Users/Danie/dev/Llmsa/llmsa/orchestrator/STOP
```

- **Nur `_pkgdown.yml` stagen**, kein `git add -A`. `orchestrator/STOP` ist weder versioniert noch ignoriert und käme sonst mit in den Commit.
  - `STATUS.md` und `orchestrator/state/summary.json` (FATAL-Status) dürfen geändert liegen bleiben; der Preflight nimmt sie aus (`:294–297`).
  - Die Commit-Nachricht oben ist ein Vorschlag (englisch, wie im Projektblock verlangt).
- **Neu starten** wie gewohnt.
  - Der Lauf liest das Verdict r4, setzt `round` auf 5 und startet Rework r5 auf dem Betreiber-Commit (`:1074–1083`), danach die Gates r5 und das Review r5.
  - territory ist dann grün, weil `HEAD^` die Audit-Basis von Rework r5 ist (`gates.d/82-territory.sh:11–14`).
- **Wirkung, geprüft (Prüflauf 2).** Ich habe genau diese Bytes an die heutige Datei angehängt, in einer Paketkopie, mit pkgdown 2.2.1.
  - Die bisherigen Schlüssel `url`, `destination`, `template` und `reference` bleiben gleich.
  - Die unveränderte Abnahmedatei `test-m1d-5-size-licence-network.R` besteht vollständig: 6 Blöcke, 45 Erwartungen, 0 rot.
  - Die Zeile `destination: pkgdown-site`, die K-M0-5 prüft (`tests/acceptance/test-m0-layout.R:29–33`), bleibt. Sonst liest kein Test die Datei, und `R CMD build` lässt sie aus (`.Rbuildignore:6`).
  - pkgdown baut den Artikelindex „Validation: validation | Applications: llm-stability, clinvar-raters“.
- **Fallen:**
  - STOP nicht vor dem Halt entfernen. Sonst startet Rework r5 ohne den Eintrag, und Runde 5 ist die letzte reguläre Runde (Nr. 2).
  - Nie während einer laufenden Modellphase `_pkgdown.yml` ändern oder committen. Die Territoriumsprüfung rechnet die Änderung der Rolle zu und setzt mit `git reset --hard` auf die Basis der Phase zurück (`:350–356`, `:551–554`).
  - Nicht zwischen Rework r5 und Gates r5 committen (BL-106).
  - Hält der Lauf wider Erwarten erst in `run_model` des Reworks (`:621`), steht in `round` schon 5. Diese Änderung vor dem Commit auf den versionierten Stand 4 zurücknehmen, nicht löschen (M1d REVIEW r3, Nr. 1, Falle 1, dort mit 4 → 3).

**2. Rundenbudget (BL-118).** Der laufende Orchestrator arbeitet mit „REWORK<=5“ (`orchestrate.log` Z. 200); `arbiter-granted` gibt es in M1d nicht.

- Runde 5 ist damit die letzte reguläre Runde. PASS im Review r5 setzt grüne Gates r5 voraus.
- Ohne den Eintrag folgt nach dem Review r5 der Arbiter (`orchestrate.sh:1063–1071`) bei leerem `blocking`. RESOLVE gibt zwei Zusatzrunden (`:1071`); HUMAN parkt M1d (`:1067`).

**3. ADR-047 Nr. 3 (unverändert):** Nach `done/M1d` den Mutationslauf ohne die Scope-Sperre einmal in einer Kopie nachrechnen, verlangt sind 92,09. Vor M3a folgt die Scope-Rückstellung nach Nr. 4 (BL-24).

**4. Etikettenregel llm-stability (E16, BL-119, unverändert):** Vor einer Verwendung der Wiederholbarkeiten und Trefferquoten aus `vignettes/llm-stability.Rmd` im Paper entscheiden, ob die Regel auf eine Salienzfolge wie in der Quelle umgestellt wird. Das ist keine Aufgabe in M1d.

**5. URL der pkgdown-Seite (E19, BL-121, unverändert):** Der Block aus Nr. 1 behebt E19 nicht und soll es auch nicht. `url` in `_pkgdown.yml` bleibt unverändert; die Abhilfe gehört nach dem 26.11.2026 in `DESCRIPTION` (Builder).

## Gate-Fakten (`orchestrator/state/M1d/gates.json`, Runde 4)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 06:06:27 UTC, also nach dem Rework-Commit (07:05:30 MEZ): `creating vignettes ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK` (Z. 89); `installed size is 22.3Mb` als INFO (BL-114) |
| tests | **fail** | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5741 ]` (Z. 590; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 3 \| WARN 2 \| SKIP 0 \| PASS 15638 ]` (Z. 1852, Dauer 2341,0 s); e2e `[ FAIL 0 \| … PASS 319 ]` (Z. 1920); fuzz `[ FAIL 0 \| … PASS 94 ]` (Z. 1952). Kurzbefund: „674 Tests …; 1 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1953) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (builder/60-rework, Runde 4, Basis 05de457…, 2026-11-04T07:05:30+01:00)` |
| mutgate | pass | `kein geänderter Mutations-Scope` (ADR-047 Nr. 1) |
| golden-adr | pass | `Änderung und ADR liegen im selben Meilenstein` (ADR-049 deckt `inst/extdata/`) |
| mutfull | pass | `nicht fällig in M1d` |

- **Die drei Fehlschläge** (`gate-tests.log` Z. 1189–1207, wiederholt Z. 1831–1849) liegen in `test-m1d-5-size-licence-network.R:97` und `:99`:
  - „Expected _pkgdown.yml has an articles section to be TRUE“;
  - „Expected llm-stability is listed under articles to be TRUE“;
  - „Expected clinvar-raters is listed under articles to be TRUE“.
- **Die zwei Warnungen** sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 778–803), Reviewer-Territorium, kein Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M1d/shots/` ist leer und in M1d nicht verlangt.

Erwartungen der M1d-Tests im tests-Gate der Runde 4, jeweils gleich den Runden 1 bis 3:

| Testdatei | Erwartungen |
| --- | --- |
| `m1d-1-llm-stability-data` | 97 (24,1 s) |
| `m1d-2-llm-stability-vignette` | 113 (15,3 s) |
| `m1d-3-clinvar-data` | 47 (545,2 s) |
| `m1d-4-clinvar-vignette` | 106 (15,2 s) |
| `m1d-5-size-licence-network` | 42 grün, 3 rot (E1) |
| `m1d-6-full-runs` | 4125 |
| `m1d-7-findings` | 512 (77,9 s), einschließlich ACC-12 |
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
- **Spezifikation:** docs/02 M1d (Ergebnis, Voraussetzung, Abbildungen, K-M1d-1 bis K-M1d-8).
- **Entscheidungen:** ADR-048 Nr. 8 und 15 mit Konsequenzen, ADR-047 Nr. 1 bis 4. ADR-049 habe ich nicht erneut gelesen; es gilt wie in Runde 1 geprüft, die Runde ändert nichts an seinem Gegenstand.
- **Handoff M1d:**
  - `CRITERIA.json` (K-M1d-1 bis K-M1d-8; ACC-8 im Wortlaut), `REWORK-NOTES.md` (Runde 4, dazu die Fassung der Runde 3 als Blob), `QA.md`;
  - mein `REVIEW.md` und `verdict-code.json` der Runde 3.
  - `PLAN.md`, `PLAN-REVIEW.md` und `REVIEW-INPUT.md` nicht erneut; die Runde berührt keine Planstelle, und alle drei sind seit Runde 1 blobgleich.
- **Gates und Harness:**
  - `gates.json`, alle acht `gate-*.log`, `state/M1d/territory-ok`, `round`, `current-phase`, Dateizeiten von `orchestrator/STOP`, `gates.json` und `reports/mutation/mutation.json`;
  - `orchestrator/logs/orchestrate.log` (CONFIG-Zeile, Ereignisse M1d);
  - `orchestrate.sh`: `fatal`, `release_lock`, `stop_check`, Preflight, `commit_phase`, `model_phase`, `verdict`, `run_ms`;
  - `config.env` (Runden, Mutations-Scope), `.gitignore` (STOP, Logs), `.Rbuildignore`.
- **Diff:** seit `plan/M1d`, Review r3 → Rework r4 und Rework r4 → Gates r4 (Prüflauf 1); `PROGRESS.md` als `diff -u`, `REWORK-NOTES.md` vollständig.
- **Abnahme:** `tests/acceptance/test-m1d-5-size-licence-network.R:94–112`, `tests/acceptance/test-m0-layout.R`; dazu eine Suche nach `_pkgdown` in `tests/`, `R/`, `orchestrator/gates.d/`, `orchestrator/lib/` und `.github/`.
- **BACKLOG:** BL-92, BL-93, BL-106, BL-112 und BL-117 bis BL-121.

## Eigene Prüfläufe

Am 04.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1d/.probe-cr4/`, vor Phasenende mit `unlink()` gelöscht. Umgebung: R 4.6.1, pkgdown 2.2.1. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff ohne Git-Kommando.**
   - Vorgehen wie in den Runden 1 bis 3: R liest `.git/refs/tags/plan/M1d` und `refs/heads/main` und folgt Tag, Commits und Bäumen über die losen Objektdateien (`memDecompress`); es fehlte keines.
   - Blob-IDs verglichen für `plan/M1d` → HEAD, Review r3 → Rework r4, Rework r4 → Gates r4 und Gates r3 → HEAD, dazu HEAD → Arbeitsbaum. Die Blobs von `PROGRESS.md` und `REWORK-NOTES.md` aus Review r3 habe ich für `diff -u` in die Probe geschrieben.
   - Geprüft habe ich außerdem die Zeilen der Gate-Logs der Runde 3 aus dem Baum von Gates r3, auf die der Builder verweist, und sein Log unter `/tmp`.

   ```text
   base commit: 051133562fa0197a70535fb24d3afbd5c7d2a0d2
   commit 0bc6b6b91b7fc2081284ce8d0cd983353457f228 msg: orch(M1d): gates r4 (rc=1) parent: 77c1485e874b498396819c2b5a20484dfa7fce7d
   commit 77c1485e874b498396819c2b5a20484dfa7fce7d msg: orch(M1d): builder 60-rework r4 parent: 05de45715121b18aa8b585f1f8030831b4aa370f
   commit 05de45715121b18aa8b585f1f8030831b4aa370f msg: orch(M1d): reviewer 50-code-review r3 parent: 46c81b19431dff576eb8ed4439336c69997ccf34
   plan/M1d -> HEAD: files 674 -> 735; added 61 removed 0 changed 15
     tests/acceptance touched: 0
   review r3 -> rework r4: files 733 -> 734; added 1 removed 0 changed 7
     added: orchestrator/state/M1d/rework-r4.done
     changed: orchestrator/handoff/M1d/REWORK-NOTES.md orchestrator/state/M1d/current-phase orchestrator/state/M1d/round orchestrator/state/M1d/territory-ok orchestrator/state/summary.json PROGRESS.md STATUS.md
   rework r4 -> gates r4 (HEAD): files 734 -> 735; added 1 removed 0 changed 7
     added: orchestrator/state/M1d/gates-r4-infra0.done
     changed: orchestrator/state/M1d/current-phase orchestrator/state/M1d/gate-lint.log orchestrator/state/M1d/gate-territory.log orchestrator/state/M1d/gate-tests.log orchestrator/state/M1d/gates.json orchestrator/state/summary.json STATUS.md
   product/test/data/spec paths touched since gates r3: 0
   _pkgdown.yml base == head: TRUE
   state round in HEAD: 4
   tracked files whose work-tree blob differs from HEAD: 0
   untracked files under package paths: 
   r3 tests 1185: ✔ |        106 | m1d-4-clinvar-vignette [15.5s]
   r3 tests 1192: Failure ('test-m1d-5-size-licence-network.R:97:3'): K-M1d-5: both vignettes are listed under articles in _pkgdown.yml
   r3 tests 1830: Failure ('test-m1d-5-size-licence-network.R:97:3'): K-M1d-5: both vignettes are listed under articles in _pkgdown.yml
   r3 tests 1851: [ FAIL 3 | WARN 2 | SKIP 0 | PASS 15638 ]
   r3 tests 1685: ✔ |        512 | m1d-7-findings [79.2s]
   r3 tests 1941: ✔ |         51 | m1d-qa-fuzz
   r3 lint 89: Status: OK
   validation.Rmd:285:   for (scenario in sort(unique(sensitivity$tables$scenario))) {
   clinvar-raters.Rmd:131:                           responseName = "submissions", stringsAsFactors = FALSE)
   DESCRIPTION:20: URL: https://github.com/DanielMoj/llmsa
   builder log exists: TRUE
   [ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]
   K-M1d-5 acceptance: 5.76 seconds; exit 1
   (Auszug; die übrigen geprüften Zeilen 1193, 1210, 1831, 1917, 1950, 779, 780 und 804 tragen den jeweils genannten Inhalt)
   ```

   - **Rework r4 ändert** nur `PROGRESS.md` und `REWORK-NOTES.md`; die übrigen Pfade sind Orchestrator-Zustand (`round` 3 → 4).
   - **`diff -u` von `PROGRESS.md`:** nur ein neuer Abschnitt „M1d — REWORK, Runde 4“ am Anfang. Die älteren Einträge sind unverändert.
   - **`REWORK-NOTES.md`:** vollständig neu für Runde 4; Inhalt unten unter „Antworten“ geprüft.
   - **Gegenüber `plan/M1d`:** dieselben 15 geänderten Pfade wie in den Runden 1 bis 3. Kein Abnahmetest unter `tests/acceptance/` ist seit `plan/M1d` geändert. `DESCRIPTION` ist unverändert.
   - **Gate-Logs der Runde 3:** Die Fehlschläge stehen in Z. 1192–1210 und Z. 1830–1851, die Warnungen aus BL-93 in Z. 779–804. Die Verweise des Builders stimmen also.
2. **`_pkgdown.yml` mit dem Betreiber-Block als angehängte Bytes, auf einer Paketkopie.**
   - Vorgehen:
     - `DESCRIPTION`, `NAMESPACE`, `R/`, `inst/`, `data/`, `man/`, `vignettes/`, `docs/`, `reference/anchors/`, `tests/acceptance/` und `.Rbuildignore` nach `tempdir()` kopiert.
     - Dort `_pkgdown.yml` aus der heutigen Datei und genau den Bytes erzeugt, die der Befehl `cat >> … <<'EOF'` aus „An den Betreiber“ Nr. 1 anhängt: Leerzeile, Block, abschließendes LF.
     - `REPO_ROOT` auf die Kopie gesetzt und `testthat::test_dir(…, filter = "^m1d-5-", load_package = "source")` ausgeführt; danach den Artikelindex mit `pkgdown:::data_articles_index()` gebildet.
     - Die Kopie ist gelöscht; am Arbeitsbaum ist nichts geändert.

   ```text
   current _pkgdown.yml: 574 bytes, last byte 0x0a, CR bytes: 0
   new file: 703 bytes; sha256 7e465e038e78aa7b5cd90c2caebd909c74ab588298a1a765a594c00c12c3b671; git blob 1e10a121bc2a14e26d7385a98045d574dc8d4b01
   existing keys kept unchanged: TRUE | keys: url destination template reference articles
   listed under articles: validation llm-stability clinvar-raters
   K-M0-5 destination line still present: TRUE
   m1d-5-size-licence-network: .............................................
   K-M1d-5 on the copy with articles: 6 blocks, 0 failed, 0 errors, 0 skipped, 45 passed expectations (1.1 s)
   pkgdown 2.2.1
   articles index with the block: Validation: validation | Applications: llm-stability, clinvar-raters
   copy removed: TRUE
   ```

   - Gegenüber Runde 3, Prüflauf 2, ist neu: die genaue Bytefolge des Befehls, die Prüfsumme und die Zeile für K-M0-5. Die Wirkung auf K-M1d-5 und den Index ist dieselbe.
   - Weitere Leser der Datei: Die Suche nach `_pkgdown` findet außer K-M1d-5 nur K-M0-5 (`test-m0-layout.R:29–33`, prüft `destination`). In Produktcode, Gate-Skripten und Harness-Bibliotheken kommt die Datei nicht vor.

## Prüfung nach Gesichtspunkten

- **Spec- und Vertragstreue:** K-M1d-1 bis K-M1d-8 sind wie in Runde 1 umgesetzt, mit der Darstellungsänderung E17 aus Runde 2. Im Gate fehlt nur die Listung aus K-M1d-5 (E1). Die Runde 4 berührt keine Kennzahl, keine Auswahlregel und keine Datei des Pakets.
  - „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“ ist eingehalten (ACC-12 im Gate grün).
  - Die Bedingungen von ADR-047 Nr. 2 gelten weiter: ACC-12 ist grün, und unter `tests/` ist seit Runde 3 nichts geändert.
- **API:** kein Export, kein Argument, kein Import, keine Druckausgabe geändert; ANK-02 im Gate grün (`m0-api-snapshot`, 259).
- **Tests:** Keine Testdatei ist geändert, gelöscht oder entkernt; seit `plan/M1d` ist kein Abnahmetest verändert. Der Builder hat in Runde 4 keine Tests geschrieben, es gibt also keine neue Momentaufnahme.
- **Konfiguration:** `DESCRIPTION`, `.Rbuildignore`, Gate-Skripte, Schwellen und Testauswahl sind unverändert.
  - `orchestrator/config.env` ist nicht versioniert (`.gitignore:18`). Die Datei wurde zuletzt am 04.11. um 01:01 geändert, vor dem Start des laufenden Orchestrators (CONFIG-Zeile 01:01:30, `orchestrate.log` Z. 200).
  - Die Datei setzt weiter „REWORK<=5“ und die Scope-Sperre aus ADR-047 (`config.env:215`, `:276`).
- **Werte, Daten, Golden:** kein neues Literal im Paket; `inst/extdata/` und `reference/anchors/` sind unverändert; golden-adr ist grün.
- **Sichtbare Defekte:** keiner in M1d. Die URL-Abweichung aus E19 besteht schon vor M1d.
- **Builder-Belege:**
  - REWORK-NOTES r4 behauptet keine Abnahme und keinen Gate-Stand der Runde 4.
  - Die Inventur „2 changed; 0 new; 0 removed“ bestätigt Prüflauf 1 unabhängig, über die Blob-IDs statt über das Skript des Builders unter `/tmp`.
  - Die gezielte K-M1d-5-Abnahme (`[ FAIL 3 | WARN 0 | SKIP 0 | PASS 42 ]`) passt zum tests-Gate der Runde 4: 42 grün, 3 rot.

## Stand der Einwände

| ID | Stand | Beleg |
| --- | --- | --- |
| E1 (M1D-INFRA-01) | offen, [INFRA], Betreiber; STOP liegt, Commit nach dem Halt | `_pkgdown.yml` unverändert seit `plan/M1d`; tests r4 rot mit denselben drei Erwartungen; Wirkung der Bytes aus Nr. 1 belegt (Prüflauf 2; BL-118) |
| E16 | offen, Betreiber-Entscheidung nach M1d | Daten, Parser und Vignette blobgleich zu Runde 1 (BL-119) |
| E17 | erledigt (Rework r2) | M1d REVIEW r2; Vignetten seit Runde 2 blobgleich; BL-120 gestrichen |
| E18 (QA-M1d-001) | nonblocking, nach dem 26.11.2026 | `findings.R` blobgleich; QA-M1d-FUZZ-2 grün (BL-117) |
| E19 | nonblocking, nach M1d | `DESCRIPTION` und `_pkgdown.yml` unverändert (BL-121) |
| E2 bis E15 | erledigt (Runde 1) | M1d REVIEW r1, Antworten auf REVIEW-INPUT |
| M1D-QA-01 | erledigt (45-qa) | M1d REVIEW r1 |

## Einwände (Runde 4)

- [E1] (minor) [INFRA] K-M1d-5 („beide Vignetten sind in `_pkgdown.yml` unter `articles` gelistet“, docs/02-statistikkern.md:89); ACC-8 (5); Gate tests (`gate-tests.log` M1d r4 Z. 1189–1207, 1831–1849); ADR-048 Nr. 15; BL-118 — **Befund:** unverändert seit Runde 1. `_pkgdown.yml` gleicht `plan/M1d` und hat keinen Abschnitt `articles`; die drei Erwartungen in `test-m1d-5-size-licence-network.R:97–99` sind der einzige Grund für `gates.result = fail`.
  - Die Datei liegt außerhalb der Builder-Pfade (`config.env:200`, `orchestrate.sh:515–544`) und der Reviewer-Pfade dieser Phase (`orchestrate.sh:522`, `config.env:201`).
  - ACC-8 nennt den Builder als Zuständigen. Für Nr. 5 gilt ADR-048 Nr. 15: [INFRA], Betreiber.
  - `orchestrator/STOP` liegt seit 07:52:12, während Review r4. Der Lauf hält nach diesem Review-Commit, `round` bleibt 4.
  - Mit den Bytes aus „An den Betreiber“ Nr. 1 besteht K-M1d-5 vollständig (Prüflauf 2).
  - — **Vorschlag:** Betreiber nach „An den Betreiber“ Nr. 1: Halt abwarten, Block anhängen, Prüfsumme vergleichen, nur `_pkgdown.yml` stagen und committen, STOP entfernen, neu starten. Für den Builder nicht blockierend.
- [E16] (minor) ACC-2 (3); ADR-049 Nr. 2; PLAN-REVIEW E2; BL-119 — **Befund:** unverändert. `items.csv.gz`, `prepare.R`, `make_llm_stability.R` und `llm-stability.Rmd` sind blobgleich zu Runde 1. Die Etikettenregel ist spec-konform und offengelegt. — **Vorschlag:** keine Änderung in M1d; Entscheidung des Betreibers vor einer Verwendung im Paper.
- [E18] (minor) QA.md QA-M1d-001; BL-117; ADR-035 Nr. 1 — **Befund:** unverändert nonblocking.
  - Es gibt keinen roten reproduzierenden Test; QA-M1d-FUZZ-2 ist grün (`m1d-qa-fuzz`, 51 Erwartungen, `gate-tests.log` M1d r4 Z. 1943).
  - Die Herabstufung begründet M1d REVIEW r1 (E18): In der Vignette erreichen `m1d_findings()` nur vollständig geprüfte Tabellen, und die Sensitivität bricht bei einer reinen NA-Spalte benannt ab.
  - `inst/validation/m1d/findings.R` ist blobgleich zu Runde 1.
  - — **Vorschlag:** Härtung nach dem 26.11.2026 (BL-117).
- [E19] (minor) M1d REVIEW r3, Prüflauf 2; `_pkgdown.yml:1` (`url: https://danielmoj.github.io/llmsa/`); `DESCRIPTION:20` (`URL: https://github.com/DanielMoj/llmsa`); `.github/workflows/pkgdown.yaml:32`; BL-121 — **Befund:** unverändert. `pkgdown::check_pkgdown()` bricht ab mit „In DESCRIPTION, URL is missing package url (https://danielmoj.github.io/llmsa).“; beim Seitenbau erscheint nur „URLs not ok.“, ohne Abbruch. Kein M1d-Kriterium; beide Dateien sind seit `plan/M1d` unverändert. — **Vorschlag:** keine Änderung in M1d, auch nicht im Rework r5. Nach dem 26.11.2026 mit der Release-Arbeit die Seiten-URL in `DESCRIPTION` unter `URL` ergänzen (Builder) und `check_pkgdown()` erneut laufen lassen.

## Antworten auf REWORK-NOTES (Runde 4)

- **E1:** OUT-OF-TERRITORY bestätigt; kein Scheinfix im Produkt. Die Reproduktion mit 42 grün und 3 rot deckt sich mit dem Gate r4. Die Verweise `gate-tests.log:1192–1210` und `:1830–1851` (Runde 3) stimmen. Richtig.
- **E16:** zurückgestellt ohne Änderung, wie verlangt. Richtig.
- **E17:** in Runde 2 erledigt, in Runde 4 nicht erneut angefasst. Die Verweise `validation.Rmd:285`, `clinvar-raters.Rmd:131`, `:1185`, `:1685` und `gate-lint.log:89` (Runde 3) stimmen. Richtig.
- **E18:** zurückgestellt nach ADR-035, kein neuer QA-Lauf behauptet; die Verweise `:1941`, `:1917` und `:1950` stimmen. Richtig.
- **E19:** zurückgestellt, `DESCRIPTION` unverändert, kein eigener pkgdown-Lauf behauptet; `_pkgdown.yml:1` und `DESCRIPTION:20` stimmen. Richtig.
- **Betreiberübergabe:** YAML gleich M1d REVIEW r3 und ADR-048 Nr. 15. Seine Wirkung belegt Prüflauf 2 jetzt auch für die genaue Bytefolge des Befehls.
- **Integrität, BL-93, Mutation:** Die Inventur (nur `PROGRESS.md` und `REWORK-NOTES.md` geändert) bestätigt Prüflauf 1. Die Angaben zu BL-93 (`:779–804`) und zu mutgate/mutfull stimmen mit den Gate-Logs der Runde 3 überein und gelten auch in Runde 4.

## Backlog

- **Stand ergänzt:**
  - BL-118: Gate r4 wieder rot; STOP liegt seit Review r4; Bytes, Prüfsumme und Wirkung des Blocks belegt; Ablauf nach dem Halt; Runde 5 ist die letzte reguläre Runde;
  - BL-93: Warnungen auch im Gate r4;
  - BL-117: unverändert nonblocking;
  - BL-119 und BL-121: unverändert.
- BL-92 und BL-112 bleiben bis zur Abnahme von M1d stehen (Streichung dann).
