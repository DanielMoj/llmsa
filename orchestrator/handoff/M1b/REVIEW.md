# REVIEW — M1b, Runde 2 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 2 · Stand: 31.10.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `5764521…` (`gates.json`, `env.sha`). Schwerpunkt ist der Rework-Commit der Runde 2 gegenüber dem Review-Commit `5823adb…` der Runde 1;
- die Gate-Fakten `orchestrator/state/M1b/gates.json` der Runde 2 mit allen acht `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` der Runde 2 mit den beiden gemeldeten OUT-OF-TERRITORY-Ursachen.

## Ergebnis

**Verdict REWORK.** `gates.result` ist `fail` (tests). Es gibt einen blocking-Befund (E24) und vier nonblocking-Befunde (E25 bis E28).

- **Runde-1-Befunde:** E12 bis E18 sind behoben. Gate-Fakten und eigene Prüfläufe belegen das:
  - alle sechs QA-Tests QA-M1b-001 bis -006 sind im Gate grün;
  - mutgate ist grün: 91,91 bei verlangten 91,83, der unmutierte Vorlauf hat 363 Tests und 0 rote.
  - E19 ist bestätigt: K-M2-6 und K-M2-7 sind im Gate grün; BL-90 ist erledigt.
- **Rot im Gate tests sind zwei Ursachen außerhalb des Builder-Territoriums:**
  - meine eigene Abnahmefixture zu K-M1b-7. Sie erzeugte `derived_share` = 1,5, das der von ADR-027 Nr. 5.2 verlangte Bereichstest zu Recht abweist. Behoben in dieser Phase (E25, [INFRA], ADR-029 Nr. 1).
  - ein Seiteneffekt von QA-M1b-004 auf die M2-E2E-Tests (E26, [QA-PENDING], ADR-029 Nr. 3). Ohne QA-Nachlauf bleibt das Gate rot. Der Betreiber muss ihn anfordern.
- **Neu und blocking (E24):** Bei `type = "ordinal"` und `"binary"` liefert `msa_fit()` für nicht trennbare Zufallskomponenten still eine beliebige Aufteilung. Ein Beispiel: Prompt und Modell mit derselben Partition. Bei Items, die in Modellen verschachtelt sind, wird mit Wechselwirkungen ICC_items still halbiert. Der numerische Pfad bricht in denselben Plänen benannt ab.
  - Die Lücke liegt in meiner Aufzählung in ADR-027 Nr. 3, nicht in der Umsetzung der Runde 2.
  - ADR-029 Nr. 2 legt die Klasse fest.
- **In dieser Phase umgesetzt:**
  - die Fixture in `tests/acceptance/test-m1b-7-vignette-full-results.R`;
  - `docs/decisions/ADR-029-m1b-code-review-auslegungen-runde-2.md`;
  - in `BACKLOG.md` BL-94 bis BL-97, BL-90 gestrichen, Stand-Vermerke in BL-86, BL-91, BL-92 und BL-93.
- **MUT-EQUIV:** Es gibt keine Anträge und keine Freigaben. `MUT-EQUIV-APPROVED.json` wird nicht geschrieben.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`. Dazu die Prompts `50-code-review` Runde 2 und `60-rework` Runde 2 sowie `orchestrator/orchestrate.sh`:
  - `path_allowed`, Z. 483–512;
  - `verdict()`, Z. 701–723;
  - Code-Schleife mit dem QA-Nachlauf über `qa-requested`, Z. 963–1053;
  - `orchestrator/lib/r-tests.R`.
- **Handoff M1b:**
  - `CRITERIA.json`, insbesondere ACC-11 zur Fixture der Dateiwahl;
  - `REVIEW.md` und `verdict-code.json` der Runde 1;
  - `REWORK-NOTES.md` der Runde 2, `QA.md`, `ARBITER.md` und `verdict-arbiter.json` (nur E1 und K-M1b-5, hier nicht berührt).
  - Nicht vorhanden: `REVIEW-INPUT.md`, `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json`.
- **Spezifikation:** docs/02, Abschnitt M1b (Z. 20–45, K-M1b-1 bis K-M1b-7 und die Szenariotabelle); docs/01 §2 Nr. 4; ADR-023 Nr. 9 und 10, ADR-027 vollständig, ADR-028 (Builder) vollständig.
- **Diff, ohne Git:**
  - geänderte Dateien seit dem Review der Runde 1 über `find -newer orchestrator/state/M1b/code-review-r1-infra0.done`;
  - Inhalt aus den `diff --git`-Blöcken des Rework-Logs `orchestrator/logs/M1b-60-rework-r2-a1-20261031-121017.log`. Gelesen ist der letzte kumulative Stand, Z. 24442–25027; dazu Z. 10060–10100, wo `DESCRIPTION` und `man/llmsa-package.Rd` nach einem roxygen-Lauf bytegleich zurückgeschrieben werden.
  - Vollständig gelesen:
    - `R/fit.R`, Z. 1–379 und 705–759;
    - die Änderungen in `inst/validation/latent/reference_checks.R` (Z. 186–224) und `inst/validation/sim/simulation_helpers.R` (`sim_merge()`);
    - die neuen Testdateien `test-fit-latent-rework.R`, `test-validation-latent-rework.R` und `helper-validation-vignette.R`;
    - `helper-validation-latent.R`, `man/msa_fit.Rd` (neue Absätze), ADR-028, PROGRESS M1b Runde 2 und `NEWS.md` (Kopf);
    - der Inhalt von `DESCRIPTION`. Imports sind unverändert, Suggests wie in Runde 1 geprüft.
  - Die sechs Kurzlauf-CSVs gibt das Gate über K-M1b-2/-3 als bytegleich reproduziert aus. Die Sessiondateien tragen den Implementierungs-Hash `cc34f15d…`.
- **Visuelle Artefakte:** keine; M1b fordert keine (`orchestrator/state/M1b/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 2 (`gates.json`, `env.sha` `5764521`) |
| --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26) |
| lint | pass (`R CMD check --as-cran --no-manual`: Status OK, Tests und beide Vignetten OK) |
| tests | **fail** |
| trace | pass |
| territory | pass (builder/60-rework, Runde 2) |
| mutgate | pass: score=91.91 required=91.83 baseline=93.83 floor=80 |
| golden-adr | pass (keine Golden- oder Ankeränderung) |
| mutfull | pass („nicht fällig in M1b“) |
| **result** | **fail** |

- **tests** (`gate-tests.log`):
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3400 ]` (Z. 419). Runde 1 hatte 3221; der Skip ist der bekannte ellmer-Negativtest.
  - `tests/acceptance`: `[ FAIL 5 | WARN 2 | SKIP 0 | PASS 6355 ]` (Z. 912).
    - M0, M1a und sieben M1b-Dateien sind grün: m1b-1 34, m1b-2 2155, m1b-3 687, m1b-4 37, m1b-5 9, m1b-6 108, m1b-7-vignette 240 Erwartungen.
    - `m2-6-evaluate` 383 und `m2-7-robustness-pilot` 375 sind grün, einschließlich Orakel-Selbsttest und HTTP-Replay (Z. 813–871).
    - Rot ist allein `m1b-7-vignette-full-results`: vier Blöcke, fünf Erwartungen. Der Knit endet mit „Invalid latent study result measure range: …/two_level_results.csv“ (Z. 660–696; E25).
    - Die zwei Warnungen stammen aus dem Abnahmehelfer von m1b-4 (Z. 607–631; BL-93).
  - `tests/e2e`: `[ FAIL 4 | WARN 4 | SKIP 0 | PASS 40 ]` (Z. 1084).
    - `m1a-qa-e2e` 14 und `m1b-qa-e2e` 26 sind grün; QA-M1b-001 bis -004 bestehen.
    - Alle vier Blöcke von `m2-qa-e2e` enden mit „there is no package called 'llmsa'“. Laut Backtrace liegt `acmg.R` unter `qa-m1b-stage-…/R/` (Z. 933–1038; E26).
  - `tests/fuzz`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]`, auch QA-M1b-005 und -006 (Z. 1104).
  - Kurzbefund: „459 Tests …; 4 fehlgeschlagen, 4 Fehler, 1 übersprungen“ (Z. 1105).
- **mutgate** (`gate-mutgate.log`, `mutation.json`):
  - `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full)'` (Z. 2). Der unmutierte Vorlauf dauerte 121,7 s mit 363 Tests und 0 roten (Z. 3).
  - Bericht: 1308 Mutanten, davon `R/fit.R` 1062 und `R/grr.R` 246: 1118 Killed, 29 Timeout, 101 Survived, 0 NoCoverage, 60 RuntimeError.
  - Nachrechnung: (1118 + 29) / (1118 + 29 + 101) = 91,91 trifft den Gate-Wert. Für M1b gibt es keine Approvals.
  - `required` 91,83 ist die Baseline 93,83 minus Ratchet 2. Der Abstand beträgt 0,08 Punkte.
- **Status error:** keiner. [INFRA] ist die Fixture (E25), [QA-PENDING] die Ursache in QA-M1b-004 (E26).
- **Laufzeit:** Rework fertig 12:43, Gate fertig 19:08. Das sind ≈ 6 h 25 min, davon tests bis 13:09 und mutgate ≈ 6 h.

## Eigene Prüfläufe

Alle am 31.10.2026, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Produktstand `5764521`, `REPO_ROOT` gesetzt.

- Probeskripte lagen unter `tests/acceptance/.probe-m1b-r2/` im eigenen Territorium und sind per `unlink()` gelöscht.
- Daten sind synthetisch mit Seeds ab 20261101; Paketausgaben dienen nirgends als Referenz.
- Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **QA-M1b-004 und der Namespace (E26).** Ablauf: `pkgload::load_all(".")`, dann `testthat::test_file("tests/e2e/test-m1b-qa-e2e.R", load_package = "none")`:

   ```text
   before: /mnt/c/Users/Danie/dev/Llmsa/llmsa exists=TRUE
   acmg_plan before: ok
    nb failed error
     5      0 FALSE
     8      0 FALSE
     5      0 FALSE
     8      0 FALSE
   after: /tmp/Rtmp8j5moR/qa-m1b-stage-2a411622c5369a exists=FALSE
   acmg_plan after: there is no package called ‘llmsa’
   ```

2. **Rework-Verhalten gegen direkte Engines.** E12: ein binärer Fit über eine Hilfsfunktion `wrap <- function(r, ...) msa_fit(r, type = "binary", link = "logit", ...)`. E13: ein Ausdruck in `subset` gegen `clmm`/`glmer`, unabhängig auf denselben Zeilen aufgebaut. Toleranz ANK-TOL.engine_ordinal 1e-8 als Anteil an σ²_TV.

   ```text
   binary call symbols with '..': FALSE
   binary call fun: lme4::glmer ; control optimizer: bobyqa bobyqa
   binary call re-evaluated, max |theta diff|: 0
   msa_boot on wrapped binary fit: msa_boot
   ordinal call fun: ordinal::clmm ; '..' symbols: FALSE
   ordinal : share deviation 0 (tol 1e-08 ) ; n$items 13 n$models 2 obs 208 rows 208 nobs 208 ; derived model
   binary : share deviation 0 (tol 1e-08 ) ; n$items 13 n$models 2 obs 208 rows 208 nobs 208 ; derived -
   zero drift: singular = FALSE ; direct VarCorr item/prompt: 1.6938802 0.5236735 ; block derived: 1.444438e-14
   confounded model/block: Ordinal two-level factors model, block are not identifiable: the fixed-effect design is rank deficient.
   confounded prompt/model + interactions: Ordinal random-effect term prompt:model requires at least three observed levels.
   ordinal levels c("k1", NA) -> Ordinal `levels` must contain at least two distinct, non-missing, non-empty labels.
   binary levels c('', 'x') -> Binary `levels` must contain two distinct, non-missing labels; labels must not be empty.
   binary numeric 1/2 vs character with levels: identical y TRUE ; y equals original 0/1: TRUE
   binary 0/1 with levels c('no','yes') -> No valid response categories to analyse.
   (a) explicit levels over ordered factor: fit$levels = c("k4", "k3", "k2", "k1") ; y levels = c("k4", "k3", "k2", "k1")
   (b) two ordinal labels: fit
   (d) ordinal weights: n$observations 90 ; nobs 135 ; sum(w) 135
   ```

   Doppelte Labels, leere Labels und nur ein Label ergeben ordinal dieselbe Meldung wie der NA-Fall.

3. **Ordinale Offsets, unabhängig geprüft.** Ein Offset c · 1(model = M2) mit c = 0,7 muss den festen Kontrast um −c verschieben und die Zufallskomponenten unverändert lassen:

   ```text
   package: beta without offset 0.488745 ; with offset -0.211255 ; difference -0.7 (expected -0.7 )
   package: random components item/prompt without 1.29805419 0.58884008 with 1.29805419 0.58884008
   Error in model.offset(mf) : 'offset' must be numeric
   ```

   Die letzte Zeile stammt aus einem direkten `clmm` mit dem Offset hinter den Zufallstermen. Das bestätigt ADR-028 Nr. 3: Der Offset muss vor den Zufallstermen stehen.

4. **Nicht trennbare Zufallskomponenten (E24).**
   - a) Prompt und Modell mit derselben dreistufigen Partition (jeder Prompt nur mit einem Modell), 20 Items, zwei Replikate, Seed 20261101:

     ```text
     numeric, prompt=model with 3 levels: ERROR Numeric variance components are not identifiable.
     binary,  prompt=model with 3 levels: item=1.2061; prompt=0.3006; model=0.2815; Residual=1.0000 | singular=FALSE converged=FALSE
        warnings: Model failed to converge with max|grad| = 0.0296585 (tol = 0.002, component 1)
     ordinal, prompt=model with 3 levels: item=0.9425; model=0.3558; prompt=0.3558; Residual=1.0000 | singular=FALSE converged=TRUE
     ```

   - b) Derselbe Plan mit den Seeds 20261101 bis 20261110 (Häufigkeiten über die zehn Fits), dazu Items in Modellen verschachtelt mit `interactions = TRUE`:

     ```text
     ordinal, prompt and model with identical 3-level partitions:
     singular=FALSE converged=TRUE warnings=0
                                           10
       e.g. item=0.943 model=0.356 prompt=0.356 Residual=1.000
     binary, prompt and model with identical 3-level partitions:
     singular=FALSE converged=FALSE warnings=1
                                             4
     singular=FALSE converged=FALSE warnings=2
                                             4
       singular=TRUE converged=TRUE warnings=0
                                             2
       e.g. item=1.206 prompt=0.301 model=0.281 Residual=1.000
     items nested in models, interactions = TRUE (item:model has the partition of item):
      numeric: error: Numeric variance components are not identifiable. | NA
      ordinal: singular=TRUE converged=TRUE warnings=0 | item:prompt=0.0000 item:model=0.6817 item=0.6817 prompt:model=0.0000 model=0.0000 prompt=0.0948 Residual=1.0000
      binary: singular=TRUE converged=TRUE warnings=0 | item:prompt=0.000 item:model=0.327 item=0.353 prompt:model=0.000 model=0.000 prompt=0.115 Residual=1.000
     ```

   - c) Binär, zwei Modelle und zwei Blöcke derselben Partition; beide gehen bei `glmer` als Zufallsterme ein. 15 Items, vier Prompts, zwei Replikate:

     ```text
     seed 20261101: model 0.0751 block 0.0731 | singular=FALSE converged=FALSE warnings=2
     seed 20261102: model 0.0104 block 0.0176 | singular=FALSE converged=TRUE warnings=0
     seed 20261103: model 0.1553 block 0.0047 | singular=FALSE converged=FALSE warnings=2
     seed 20261104: model 0.3193 block 0.1977 | singular=FALSE converged=FALSE warnings=1
     seed 20261105: model 0.1277 block 0.0316 | singular=FALSE converged=FALSE warnings=2
     ```

5. **Gram-Kriterium für E24** (Vorschlag aus ADR-029):
   - G[i, j] = ‖Z_iᵀ P Z_j‖²_F, P projiziert auf das orthogonale Komplement des festen Designs;
   - nicht identifizierbar, wenn min(ev) ≤ k · eps · max(ev), wie `R/fit.R:558–562`;
   - gezeigt ist min(ev)/max(ev).

   ```text
   S-ord-1 (item, prompt, model, item:model)                      ratio 0.0144 identifiable TRUE
   S-ord-4 ordinal (block fixed)                                  ratio 0.0087 identifiable TRUE
   S-bin-1 (item, prompt, model)                                  ratio 0.0737 identifiable TRUE
   S-two-1 ordinal (model fixed)                                  ratio 0.0738 identifiable TRUE
   wine-like (bottle x judge, one replicate)                      ratio 0.617 identifiable TRUE
   S-ord-1 with all interactions                                  ratio 0.0102 identifiable TRUE
   prompt and model with identical 3-level partitions             ratio 0 identifiable FALSE
   items nested in models, interactions                           ratio -5.17e-17 identifiable FALSE
   items nested in models, no interactions                        ratio 0.158 identifiable TRUE
   binary: two-level model and block with one partition           ratio -3.16e-17 identifiable FALSE
   binary: crossed two-level model and block                      ratio 0.249 identifiable TRUE
   3-level prompt spanned by fixed model + block                  ratio 7.83e-29 identifiable FALSE
   ```

6. **K-M1b-7 nach der Fixture-Korrektur (E25).**
   - Aufbau: Kopien von `setup-*.R`, `test-m1b-7-vignette-full-results.R` und `test-m1b-7-vignette.R` in einem `tempfile()`-Verzeichnis, `testthat::test_dir(load_package = "none")` nach `pkgload::load_all(".")`.
   - An die Kopie der Fixture-Datei ist ein Probeblock angehängt. Er prüft, dass der Abschnitt des Kurzlaufs keine Fixture-Zelle (Bias und EmpSE, je value und mcse) und nicht die Marke 1234 zeigt.

   ```text
   ordinal_recovery: 0 of 100 fixture cells appear in the short-run section
   binary_recovery: 0 of 40 fixture cells appear in the short-run section
   two_level: 0 of 40 fixture cells appear in the short-run section
   ✔ |        211 | m1b-7-vignette-full-results [38.5s]
   ✔ |        240 | m1b-7-vignette [4.8s]
   [ FAIL 0 | WARN 0 | SKIP 0 | PASS 451 ]
   ```

   Von den 211 Erwartungen sind 204 die der Abnahmedatei, wie in Runde 1; 7 gehören zum Probeblock. Ohne Korrektur ist dieselbe Datei im Gate rot (Z. 660–696).

7. **Kurzlauf-Diagnose (BL-92)**, nachgezählt aus `*_check_replicates.csv`, nicht konvergierte Wiederholungen je Szenario:

   ```text
   ordinal_recovery : S-ord-1 S-ord-2 S-ord-3 S-ord-4
         1       5       2      10
   binary_recovery : S-bin-1 S-bin-2
         0       0
   two_level : S-two-1 S-two-2
         0       0
   ```

## Stand der Einwände aus Runde 1

| ID | Stand | Beleg |
| --- | --- | --- |
| E12 | erledigt | QA-M1b-001 grün (Gate); Prüflauf 2 (keine `..`-Platzhalter, Neuauswertung identisch, `msa_boot()` über eine Hilfsfunktion); `test-fit-latent-rework.R:16–53` gegen `bootMer()` mit unabhängiger ICC |
| E13 | erledigt | QA-M1b-002 grün; Prüflauf 2 (Abweichung 0 gegen direkte Engines, Zählungen gleich); Gewichtsfall nach ADR-029 Nr. 4 |
| E14 | erledigt für die Fälle aus ADR-027 Nr. 2 und 3 | QA-M1b-003 grün; Prüflauf 2. Die Klasse reicht weiter: E24 |
| E15 | erledigt | QA-M1b-004 grün; unmutierter Vorlauf von mutgate grün (363 Tests, 0 rot); Umsetzung über den Helfer zulässig (ADR-029 Nr. 5) |
| E16 | erledigt | QA-M1b-005 grün; Prüflauf 2, auch Fall (a) |
| E17 | erledigt | QA-M1b-006 grün; `sim_merge()` und `latent_read_results()` gelesen, Grenzfälle in `test-validation-latent-rework.R` |
| E18 | erledigt | mutgate pass 91,91; Überlebende in neuem Code: E27 |
| E19 | erledigt | K-M2-6 383 und K-M2-7 375 grün im Gate; BL-90 gestrichen |
| E20 | Builder-Teil erledigt | `R/fit.R:119–120`, `man/msa_fit.Rd:153`; BL-91 |
| E21 | unverändert, spec-gemäß | Prüflauf 7; BL-92 |
| E22 | Gate bestätigt | K-M2-7 einschließlich HTTP-Replay im Gate grün; lint-Zeitprüfung OK; BL-86 |
| E23 | offen, Reviewer | `gate-tests.log` Z. 607–631; BL-93 |

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **ADR-027 Nr. 1 (`...` latent):**
  - `subset`, `weights` und `offset` werden in der bereinigten Datenmaske ausgewertet, mit dem unmittelbaren Aufrufer als Umgebung (`R/fit.R:227–236`).
  - `model.frame()` wählt die Zeilen vor der Stufenregel (`:237–254`). Formel, `derived`, `data` und `n` beziehen sich damit auf dieselbe Auswahl (Prüflauf 2).
  - Die gespeicherten Aufrufe tragen ausgewertete Argumente (`:328–331`).
  - Ordinale Offsets stehen als Formelterm vor den Zufallstermen (`:300–308`), unabhängig bestätigt (Prüflauf 3).
  - Nr. 1.2 bei Gewichten: ADR-029 Nr. 4.
- **ADR-027 Nr. 2:** `singular` wird vor dem Anhängen der abgeleiteten Komponenten bestimmt; die Schwelle 1e-6 bleibt (`:348`).
- **ADR-027 Nr. 3:**
  - Nr. 3.1: Rang des festen Zwei-Stufen-Designs, mit übergebenen `contrasts` (`:290–297`);
  - Nr. 3.2: jeder ordinale Zufallsterm, auch Wechselwirkungen, braucht mehr als zwei beobachtete Stufen (`:284–289`).
  - Nicht trennbare Zufallsterme fehlen: E24.
- **ADR-027 Nr. 4:**
  - `levels` wird vor jeder Datenprüfung validiert (`:160–172`);
  - die binäre Meldung enthält weiter „two distinct, non-missing labels“;
  - explizite binäre Labels kodieren über `as.character()` unabhängig vom Speichertyp (`:202–205`);
  - ohne `levels` bleibt „Binary values must be 0 or 1.“ (`:212`).
- **ADR-027 Nr. 5:**
  - `sim_merge()` prüft alle fünf Designzählungen gegen das Szenario, NA nur ohne Schätzer, logische Flags und `singular` NA genau ohne Fit;
  - `latent_read_results()` prüft die Bereiche von EmpSE, RMSE und `derived_share` sowie ganzzahlige Seeds in [1, `.Machine$integer.max`] (`reference_checks.R:204–210`).
- **ADR-027 Nr. 6:** Der Satz zur Optimierertoleranz steht in `?msa_fit` (`R/fit.R:119–120`). Vorgabe-Optimierer und Toleranzen sind unverändert.
- **ADR-027 Nr. 7:** Neuer Helfer statt Pfadänderung im bestehenden Test; zulässig (ADR-029 Nr. 5).
- **K-M1b-1 bis K-M1b-7:** Im Gate sind alle Abnahmedateien außer der Fixture-Datei grün. K-M1b-2/-3 reproduzieren die neu erzeugten Kurzläufe bytegleich.

### API-Diff

- **Schnittstellen:** keine neuen Exporte, Argumente oder Vorgaben; der API-Snapshot ist grün (259 Erwartungen).
- **Neu in `fit$data`:** die Spalte `.msa_offset`, nur bei ordinalen Offsets. Sie ist dokumentiert (`R/fit.R:112–113`); ein neues Rückgabefeld ist nach docs/01 §4 ohne ADR zulässig.
- **Neue Fehlermeldungen für bisher angenommene ungültige Eingaben:** ungültige `levels` und nicht identifizierbare Designs. Sie folgen ADR-027 Nr. 3 und 4.
- **Abhängigkeiten:** Imports und Suggests unverändert; `DESCRIPTION` ist nach dem roxygen-Lauf bytegleich zurückgeschrieben (Rework-Log Z. 10060–10100).

### Tests: entkernt, eingefroren, hart

- **Bestandstests:** unter `tests/testthat` ist keine Bestandsdatei geändert; nach `find -newer` sind nur die drei neuen Dateien jünger. Abnahme- und QA-Tests sind unverändert, bis auf meine Fixture (E25).
- **Neue Tests belegen Verhalten:**
  - direkte `clmm`- und `glmer`-Fits auf unabhängig ausgewählten Zeilen, Gewichten und Offsets;
  - `bootMer()` mit unabhängig formulierter ICC;
  - der Rang einer unabhängig aufgebauten Designmatrix;
  - die Stichprobenvarianz {0, β̂};
  - synthetische CSV-Verfälschungen, als solche gekennzeichnet.
  - Keine Erwartung friert eine eigene Paketausgabe ein. Die festen Zählungen in `test-fit-latent-rework.R:92–96` folgen aus dem Design.
- **Harte Erwartungswerte:** keine abgetippten Referenzwerte; die Toleranzen kommen aus den ANK-TOL-Kopien.
- **Testlücken nach dem Mutationsbericht:** E27.

### Konfiguration, Daten, Golden

- **Konfiguration:** Keine Gate-, Schwellen- oder Lint-Regel ist gelockert. `MUT_TEST_EXCLUDE` ist Betreiber-Sache und schließt die Fixture-Datei schon aus.
- **Daten:** Die neun `_check_`-Dateien sind echte Läufe. Die Ergebnis-CSVs sind laut Gate bytegleich reproduziert, die Sessiondateien tragen den neuen Implementierungs-Hash. Volllaufdateien gibt es nicht.
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Öffentliches Repository:** Die neuen Dateien enthalten keinen privaten Bezug.

### MUT-EQUIV

Es gibt keine Anträge. Äquivalent und nicht beantragt sind unter anderem `R/fit.R:204`, `:243` (dreimal), `:285`, `:348`, `:352`, `:360–362` und `:369` (E27). Freigegeben wird nichts.

## Einwände (Runde 2)

- [E24] (blocking) docs/01 §2 Nr. 4 („Randfälle sind Pflicht: … unbalancierte Pläne … Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); ADR-027 Nr. 3 („Das gilt als Klasse für alle Zufallsterme und alle Zwei-Stufen-Faktoren“); `orchestrator/LESSONS.md` („Numerische Randfälle als Klasse beheben.“); ADR-029 Nr. 2 — **Befund:** Bei `type = "ordinal"` und `"binary"` prüft `msa_fit()` nicht, ob sich die Varianzen der Zufallsterme nach Abzug des festen Teils trennen lassen. Der numerische Pfad endet in denselben Plänen mit „Numeric variance components are not identifiable.“ (`R/fit.R:558–562`). Prüflauf 4:
  - Prompt und Modell mit derselben dreistufigen Partition: ordinal in 10 von 10 Fits ohne Warnung, mit `singular` FALSE und `converged` TRUE; bei Seed 20261101 still `model` = `prompt` = 0,356. Binär ist die Aufteilung beliebig, in 2 von 10 Fits ohne Warnung.
  - Items in Modellen verschachtelt mit `interactions = TRUE`: ordinal `item` = `item:model` = 0,6817, die Item-Varianz ist halbiert, ICC_items und %GRR sind still falsch; binär 0,353/0,327.
  - Binär mit zwei Modellen und zwei Blöcken derselben Partition: Seed 20261102 liefert ohne Warnung model 0,0104 und block 0,0176.
  - Die Prüfungen aus E14 (`R/fit.R:283–298`) erfassen nur feste Zwei-Stufen-Faktoren und Zufallsterme mit höchstens zwei Stufen. Das war die Aufzählung in ADR-027 Nr. 3; die Umsetzung der Runde 2 erfüllt sie.
  — **Vorschlag:**
  - Vor dem ordinalen und dem binären Engine-Aufruf die Identifizierbarkeit aller Zufallsterme prüfen, einschließlich Wechselwirkungen, nach Abzug des festen Teils (Achsenabschnitt und feste Zwei-Stufen-Faktoren). Bei Verstoß benannt abbrechen und die Terme nennen (ADR-029 Nr. 2).
  - Empfohlen ist das Gram-Kriterium aus Prüflauf 5 mit der Eigenwertregel von `R/fit.R:558–562`, also ohne neue Konstante. Ein gleichwertiges exaktes Kriterium ist zulässig.
  - Unit-Tests ordinal und binär: die drei Pläne aus Prüflauf 4 und ein dreistufiger Zufallsterm, den das feste Design aufspannt, je mit benanntem Fehler. Dazu unveränderte Komponenten identifizierbarer Pläne gegen direkte Engine-Fits, etwa Items in Modellen ohne Wechselwirkungen und gekreuzte Zwei-Stufen-Faktoren binär.
  - Die Tests müssen Mutanten der neuen Prüfung töten; der Abstand zur mutgate-Schwelle beträgt 0,08 Punkte.
  - Danach die neun `_check_`-Dateien neu erzeugen (ADR-023 Nr. 1.5).
- [E25] (minor) [INFRA] Gate tests (`tests/acceptance/test-m1b-7-vignette-full-results.R`, `gate-tests.log` Z. 660–696); ADR-027 Nr. 5.2; ADR-029 Nr. 1 — **Befund:** Meine Fixture addierte 0,5 auch auf `derived_share`, aus 1 wurde 1,5. Der Bereichstest weist die Datei zu Recht ab; der Builder hat das als M1B-R2-INFRA-FULL-FIXTURE belegt. In dieser Phase korrigiert:
  - Anteile werden zu (Wert + 0,5) mod 1, alles andere bleibt wie in ACC-11 (5);
  - Reviewer-Lauf: 204 Erwartungen grün, 0 von 180 Fixture-Zellen im Kurzlauf-Abschnitt (Prüflauf 6).
  — **Vorschlag:** Keine Builder-Arbeit; der Validator bleibt streng. Das nächste Gate tests bestätigt die Korrektur. BL-94.
- [E26] (minor) [QA-PENDING] Gate tests (`tests/e2e/test-m2-qa-e2e.R`, vier Fehler, `gate-tests.log` Z. 933–1084); `tests/e2e/test-m1b-qa-e2e.R:151–184`; ADR-029 Nr. 3 — **Befund:** QA-M1b-004 lädt mit `test_file(load_package = "source")` eine Paketkopie in den laufenden Prozess und löscht sie danach (Z. 160). Den vorher geladenen Namespace stellt der Test nicht wieder her. Alle folgenden Tests im selben Prozess finden kein `llmsa` mehr (Prüflauf 1). Die Ursache liegt allein im QA-Territorium; der Builder hat sie als M1B-R2-INFRA-QA-NAMESPACE belegt. — **Vorschlag:**
  - Keine Builder-Arbeit und kein Scheinfix im Produktcode.
  - QA: den verschachtelten Lauf in einem eigenen Prozess ausführen, etwa mit `callr::r()`, oder den zuvor geladenen Pfad wiederherstellen. Nicht aus `REPO_ROOT` nachladen, das würde im Mutationslauf den Mutanten ersetzen.
  - Betreiber: QA-Nachlauf mit `orchestrator/state/M1b/qa-requested` anfordern. Ohne ihn bleibt das Gate tests rot und `PASS` unmöglich. BL-95.
- [E27] (minor) Gate mutgate (pass; `reports/mutation/mutation.json`, Runde 2) — **Befund:** Von den 45 Überlebenden in `msa_fit()` haben drei im neuen Code eine fachliche Lücke:
  - `R/fit.R:160` `&& → ||`: kein Test mit geordnetem Faktor und davon abweichendem `levels`;
  - `:166` `< → <=`: kein ordinaler Fit mit genau zwei Labels;
  - `:331` `x[<i>] → x[<i> + 1L]` und `x[<i>] → x[<i> - 1L]`: der gespeicherte `glmer`-Aufruf wird nirgends neu ausgewertet.
  - Die übrigen sind Meldungs- und `call.`-Mutanten oder Äquivalente (`:204`, `:243`, `:285`, `:348`, `:352`, `:360–362`, `:369`).
  — **Vorschlag:** nicht verlangt, sinnvoll zusammen mit E24, weil die Schwelle knapp ist:
  - drei Tests: explizite Labels gewinnen über den geordneten Faktor, zwei ordinale Labels fitten, `eval(fit$model@call)` gleicht dem binären Fit (Prüflauf 2 zeigt das Sollverhalten);
  - Äquivalente nur einzeln in `MUT-EQUIV.json`.
  - BL-96.
- [E28] (minor) `NEWS.md` (Kopf) — **Befund:** Der Eintrag nennt die nutzersichtbaren Änderungen der Runde 2 an latenten Fits nicht: Zeilenargumente und Gewichte, Labelprüfung, Identifizierbarkeitsfehler, neu auswertbare Engine-Aufrufe und `data$.msa_offset`. — **Vorschlag:** bei der nächsten Produktänderung ergänzen. BL-97.

## Hinweise für REWORK (Runde 3)

- **Umfang:**
  - E24 im Produktcode, mit Tests und neu erzeugten Kurzläufen.
  - E27 ist empfohlen, weil neuer Code ohne tötende Tests die mutgate-Schwelle (91,83, zuletzt 91,91) unterschreiten kann.
  - E25 und E26 sind keine Builder-Arbeit. In `REWORK-NOTES.md` genügt der Verweis auf den Gate-Beleg als OUT-OF-TERRITORY.
- **Bestehende Meldungen beibehalten:** alle aus Runde 1 und die neuen Meldungen der Runde 2. Tests und QA prüfen sie wörtlich oder über Teilstrings, etwa „not identifiable“, „requires at least three observed levels“ und „levels“.
- **Unveränderter Vorgabepfad:** Identifizierbare Pläne behalten exakt den bisherigen Fit (K-M1b-1, K-M1b-5).
- **Belege:** echter Output der gezielten Läufe je Befund-ID in `REWORK-NOTES.md`.
- **Abnahme- und QA-Tests:** unverändert lassen.

## Backlog

- **Neu:**
  - BL-94: E25, Fixture korrigiert, Gate-Bestätigung ausstehend;
  - BL-95: E26, QA-M1b-004, QA und Betreiber;
  - BL-96: E27, Testlücken im neuen latenten Code;
  - BL-97: E28, `NEWS.md`.
- **Gestrichen:** BL-90, bestätigt im Gate Runde 2.
- **Stand-Vermerke:** BL-86 (E22), BL-91 (E20), BL-92 (E21) und BL-93 (E23).
- Der blocking-Befund E24 steht nicht im Backlog.
