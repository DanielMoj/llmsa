# REVIEW — M1c, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 03.11.2026 · Gegenstand: Diff seit `plan/M1c` (`ddba246`) bis zum Stand der Gates (`gates.json`: `env.sha` `001026c`, Commit der QA-Phase), also BUILD r1 und QA r1. Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` zu M1c. Keine Git-Kommandos (Abweichung im Vorgehen: siehe Prüflauf 1).

## Ergebnis

**Verdict PASS.** `gates.json` meldet `result: "pass"` mit allen acht Gates grün; es gibt keinen blocking-Befund.

- **Spec-Treue:** K-M1c-1 bis K-M1c-8 sind umgesetzt und durch die Gates entschieden: die Abnahmetests von M1c sind im tests-Gate grün (siehe Gate-Fakten), K-M1c-6 im Gate mutfull. Der Produktdiff ist klein und entspricht PLAN r1 mit den Ergänzungen E1 bis E6 aus PLAN-REVIEW. Einzige zusätzliche Planabweichung ist der eigenständige Ergebnisleser nach ADR-043; sie ist begründet und schwächt keinen Test.
- **Mutation:** mutgate 92,80 bei verlangten 92,09, mutfull 92,80 bei verlangten 80 (ANK-32). Im neuen M1c-Code überlebt kein Mutant (Prüflauf 4).
- **Äquivalenzanträge:** Alle 19 Anträge (17 Gate-Schlüssel) sind einzeln am tatsächlichen Mutanten geprüft und in `MUT-EQUIV-APPROVED.json` freigegeben.
  - 17 Freigaben sind bitgleich belegt.
  - `R/fit.R:592` (`sparse`) und `:603` (`perm`) sind nach ADR-039 rechnerisch gleichwertig, aber nicht bitgleich. Die Abweichungsschranke des Antrags gilt nicht allgemein (E7).
  - Auf den Bericht angewandt ergäbe sich 94,05. Das Gate läuft in M1c nicht erneut; die Baseline bleibt 94,09.
- **QA:** Kein blockierendes Gegenbeispiel. Die QA-Tests (`tests/e2e`, `tests/fuzz`) sind im tests-Gate grün. QA-M1c-001 ist kein reproduzierender roter Test; ich bestätige ihn als nonblocking (E8, BL-110).
- **Einwände:** fünf minor-Befunde, E7 bis E11, keiner davon an den Builder gerichtet.
  - E7: Äquivalenzbeleg der beiden ADR-039-Fälle.
  - E8: BL-110 bestätigt.
  - E9 bis E11: an den Betreiber.

### An den Betreiber

1. **Vollläufe vor M1d (E11, BL-12, BL-92, ADR-041):** Alle vier Studien sind mit dem abgenommenen Code neu zu rechnen.
   - Die Vollläufe von M1b (Hash `477e84a5…`) gelten nicht mehr. Die neuen Implementierungshashes lauten `203bc364…` (ordinal, binary, two_level) und `2dcf076e…` (boot_coverage).
   - Hochrechnungen des Builders aus den Kurzläufen, keine Messung: Bootstrap rund 11,4 Stunden bei 1000 Wiederholungen, ordinal rund 2,3 Stunden, binary rund 47 Sekunden, two_level rund 7,5 Minuten.
   - Befehle, `boot_merge()` für szenarioweise Läufe und die Seed-Regel stehen in `inst/validation/sim/README.md`.
2. **ACC-21 (E10, BL-48):** `docs/gates-auswahl.md:122` nennt für das Gate tests weiter „K-M1c-1 bis K-M1c-5“. K-M1c-7 und K-M1c-8 fehlen, obwohl ihre Abnahmetests im tests-Gate laufen. trace ist nicht betroffen.
3. **`R/boot.R` in docs/02, M1d (E9, BL-111):** Die Datei gibt es nicht. `msa_boot()` liegt nach ADR-042 Nr. 18.3 in `R/grr.R`. Vor M1d sollte die Spec die Datei richtig nennen.
4. **[INFRA]-Punkte aus REVIEW-INPUT** sind durch den regulären Gate-Lauf erledigt, ohne Backlog-Eintrag:
   - M1C-INFRA-MUTTEST: mutgate und mutfull sind gelaufen.
   - M1C-INFRA-M2-SOCKET: `m2-7-robustness-pilot` ist im tests-Gate grün (375 Erwartungen).
   - M1C-INFRA-CLOCK: lint meldet `Status: OK`.
5. **Mutations-Baseline:** `state/mut-baseline` bleibt 94,09, denn der Gate-Score 92,80 liegt darunter. Die Freigaben gelten nur für `orchestrator/handoff/M1c/` (BL-85); M1d braucht eigene, neu gebundene Anträge.

## Gate-Fakten (`orchestrator/state/M1c/gates.json`, Runde 1)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 25 Anforderungen erfüllt (R 4.6.1)` |
| lint | pass | `R CMD check --as-cran --no-manual`: Vignetten neu gebaut OK, Tests OK, `Status: OK` |
| tests | pass | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 5644 ]` (Skip: optionales `ellmer`); acceptance `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 10535 ]` (die zwei BL-93-Warnungen aus `test-m1b-4-two-levels.R:41–42`); e2e `[ … PASS 92 ]`; fuzz `[ … PASS 43 ]` |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | letzter Diff sauber (qa/45-qa, Runde 1) |
| mutgate | pass | 1478 Mutanten; Killed 1299, Timeout 28, RuntimeError 48, Survived 103, NoCoverage 0; `score=92.8 required=92.09 baseline=94.09 floor=80` |
| golden-adr | pass | `keine Golden-/Ankeränderung` |
| mutfull | pass | Bericht von mutgate übernommen (gleicher Commit, gleiche Konfiguration, gleiche Dateien); `score=92.8 required=80 files=R/fit.R,R/grr.R` |

Erwartungen der M1c-Abnahmetests im tests-Gate:

| Testdatei | Erwartungen |
| --- | --- |
| `m1c-1-boot-bootmer` | 142 |
| `m1c-2-boot-failed-singular` | 74 |
| `m1c-3-coverage-script` | 2695 |
| `m1c-4-coverage-rerun` | 756 (139,6 s) |
| `m1c-5-vignette` | 25 |
| `m1c-5-vignette-full-results` | 49 |
| `m1c-6-mutfull` | 13 |
| `m1c-7-byte-equality` | 48 |
| `m1c-7-latent-note` | 18 |
| `m1c-8-check-runs` | 94 |
| `m1c-8-iteration-limit` | 62 |

Die Regression der Vormeilensteine ist im selben Lauf grün, darunter `m1b-2-recovery-scripts` (2155), `m1b-3-two-level-script` (687), `m0-api-snapshot` (259) und `m2-6-evaluate` (383). Der Mutationslauf schließt genau die Dateien aus ACC-14 aus (`gate-mutgate.log`, Kopfzeile). Visuelle Artefakte: `orchestrator/state/M1c/shots/` ist leer und in M1c nicht verlangt.

mutgate und mutfull sind grün. Die Pflicht, überlebende Mutanten als blocking-Befunde zu nennen, greift daher nicht.

## Gelesen

- **Rahmen:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, Prompt `50-code-review.md`.
- **Spezifikation:** docs/02 M1c (Szenariotabelle, K-M1c-1 bis K-M1c-8) und M1d (Voraussetzungen); `docs/gates-auswahl.md` (Zuordnung).
- **Entscheidungen:** ADR-039, ADR-040, ADR-041, ADR-042 (als Vertrag), ADR-043 (neu, Builder).
- **Handoff M1c:** `CRITERIA.json` (K-M1c-1 bis K-M1c-8, ACC-1 bis ACC-22), `PLAN-REVIEW.md`, `verdict-plan.json`, `REVIEW-INPUT.md`, `MUT-EQUIV.json`, `QA.md`; M1b `MUT-EQUIV-APPROVED.json` zum Vergleich.
- **Gates:** `gates.json`, alle acht `gate-*.log`, `reports/mutation/mutation.json`, `report.key`, `orchestrator/gates.d/86-mutgate.sh` (Schlüssel und Score), `orchestrator/lib/r-mutation.R` (Mutatorfamilien), `orchestrate.sh` (`path_allowed`, `verdict()`).
- **Diff:** `R/fit.R`, `R/grr.R`, `man/msa_boot.Rd`, `man/msa_fit.Rd`, `man/msa_grr.Rd`, `inst/templates/validation_report.Rmd`, `vignettes/validation.Rmd`, `NEWS.md`, `inst/validation/sim/README.md`, `tests/testthat/test-grr-rework.R`, `PROGRESS.md` (M1c-Eintrag) und `BACKLOG.md` (BL-110 der QA) als Diff gegen `plan/M1c`.
- **Neue Dateien, vollständig gelesen:**
  - `inst/validation/sim/boot_coverage.R`, `boot_coverage_helpers.R`, `boot_coverage_results.R`;
  - die vier neuen Unit-Testdateien;
  - Kurzlauf-Ergebnis- und Session-Datei von boot_coverage;
  - ADR-043.
- **Kurzläufe aus M1b:** Session-Felder und Konvergenz der neu erzeugten Dateien.

## Eigene Prüfläufe

Am 03.11.2026 mit `Rscript --vanilla` auf Proben unter `orchestrator/handoff/M1c/.probe-r1/`, vor Phasenende mit `unlink()` gelöscht. Das Paket wurde über `pkgload::load_all()` geladen. Umgebung: R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4, muttest 0.3.0. Gezeigt ist echter Output, gekürzt nur wie angegeben.

1. **Diff seit `plan/M1c` ohne Git-Kommando.**
   - Vorgehen: Den Baum des Tags habe ich mit R aus den losen Objektdateien unter `.git/objects/` gelesen (Tag `815c75e…` → Commit `ddba246` → Baum `9d81d11…`; `memDecompress`, SHA-1 jeder Blob-Datei geprüft). Jede Datei des Arbeitsbaums habe ich über ihre Blob-ID verglichen. Lesend, ohne Git-Aufruf.

   ```text
   old tree paths: 594
   status: MODIFIED 21, same 573   (kein Pfad gelöscht)
   Modified: BACKLOG.md NEWS.md PROGRESS.md R/fit.R R/grr.R STATUS.md inst/templates/validation_report.Rmd
     inst/validation/sim/README.md inst/validation/sim/binary_recovery_check_session.txt
     inst/validation/sim/ordinal_recovery_check_{replicates,results,session}.* inst/validation/sim/two_level_check_session.txt
     man/msa_boot.Rd man/msa_fit.Rd man/msa_grr.Rd orchestrator/state/M1c/{current-phase,territory-ok}
     orchestrator/state/summary.json tests/testthat/test-grr-rework.R vignettes/validation.Rmd
   New: docs/decisions/ADR-043-… inst/validation/sim/boot_coverage{.R,_helpers.R,_results.R,_check_*}
     orchestrator/handoff/M1c/{MUT-EQUIV.json,QA.md,REVIEW-INPUT.md} tests/e2e/test-m1c-qa-e2e.R
     tests/fuzz/test-m1c-qa-fuzz.R tests/testthat/test-{boot,fit-ordinal-control,grr-latent-note,validation-bootstrap}.R
   ```

   - Ergebnis: Unverändert sind `DESCRIPTION`, `NAMESPACE`, `tests/acceptance/**`, `reference/anchors/**`, `inst/extdata/**`, alle Specs und die übrigen Rd-Dateien; deren neuere Zeitstempel sind keine Inhaltsänderung.
   - binary_recovery und two_level: Ergebnis- und Replikat-CSV sind bytegleich zu `plan/M1c`, nur die Session-Dateien sind neu (ACC-20 (1)).
2. **Mutationsbericht gegen die Anträge** (Score nach der Regel von `86-mutgate.sh`):

   ```text
   R/fit.R  Killed 1062  RuntimeError 32  Survived 97  Timeout 28
   R/grr.R  Killed 237   RuntimeError 16  Survived 6
   gate score without approvals: 92.7972 (detected 1327, survivors 103, runtime errors 48)
   R/fit.R / R/grr.R: report source identical to work tree: TRUE / TRUE
   R/fit.R | + → - | 427   claims at columns 37,46,54 | report: col 37 Survived; col 46 Survived; col 54 Survived
   … jeder der übrigen 16 Schlüssel: genau ein Mutant im Bericht, Status Survived, Spalte und Ersetzung wie beantragt
   survivors matched by the 17 claim keys: 19
   code at every claimed line equals the claim's code field: 19/19
   R/fit.R e65c6b8119cae7ca4999ac83f76b7cacfd3d7646ce20c2a27ea85d22ee5af706 (= source_sha256 der Anträge)
   R/grr.R 75bee6a200e031a4827270a013cfed28df2e10441a13c0472ff1a5419037a083 (= source_sha256 der Anträge)
   ```

   Kein Schlüssel trifft einen nicht beantragten Mutanten, auch nicht `R/fit.R:338` (`1L` am Zeilenende überlebt nicht).
3. **Äquivalenz am tatsächlichen Mutanten.**
   - Vorgehen: `muttest::muttest_plan()` mit den neun Mutatorfamilien des Adapters erzeugt 1478 Mutanten, so viele wie der Bericht. Jeder Antrag trifft genau eine Planzeile (Zeile, Spalte, Ersetzung). Die mutierte und die unmutierte Datei werden gleich ausgewertet, jeweils in `new.env(parent = asNamespace("llmsa"))`.
   - Verglichen wird mit `identical()`:
     - numerische `msa_fit()`-Läufe: Komponenten, Zähler, `numerics`, `theta`, angepasste Werte, Warnungen, Meldungen, Fehler;
     - latente Fits;
     - Zufallseingaben der betroffenen Hilfsfunktionen.
   - Die elf numerischen Fälle umfassen:
     - geschlossene und analytische REML-Lösung;
     - Nullkomponenten und unbalancierte Pläne;
     - einen nahezu singulären Plan (Rest 1e-6 · Item);
     - zwei benannte Fehlerfälle (nicht darstellbar, entarteter Rest);
     - den `lmer`-Pfad mit `control`.
   - Die acht latenten Fälle umfassen:
     - wine Probit und Logit mit nicht ganzzahligen Gewichten;
     - ordinal mit zwei Modellen (fester Effekt);
     - Gewichte 0;
     - binär mit und ohne Wechselwirkungen;
     - einen nicht identifizierbaren verschachtelten Plan.

   ```text
   original outcomes (numeric): ic50=analytic_reml; small=closed_form; blocks=closed_form; unbalanced=analytic_reml; no_interactions=closed_form; zero_component=analytic_reml; unbalanced_zero=analytic_reml; tiny_scale=ERROR: Numeric model variance is not representable on the; near_singular=analytic_reml; degenerate=ERROR: Degenerate numeric model: residual variance is zer; lmer_dots=lmer
   original outcomes (latent): wine_probit=fit; wine_weights=fit; ord_two_models=fit; ord_zero_levels=fit; bin=fit; bin_interactions=fit; bin_nested=ERROR: Latent variance components are not identifiable: random-effe; bin_weights=fit
   R/fit.R:323:47 TRUE → FALSE   level-count decision identical on 300/300 random weighted inputs; msa_fit end-to-end: 8/8 bit-identical
   R/fit.R:324:64 FALSE → TRUE   level-count decision identical on 300/300 random weighted inputs; msa_fit end-to-end: 8/8 bit-identical
   R/fit.R:338:46 <n> + 1        information with matrix(2) design identical on 300/300 random weighted inputs; msa_fit end-to-end: 8/8 bit-identical
   R/fit.R:427:37/46/54 + → -    aggregate(...) identical on 11/11 designs; msa_fit end-to-end: 11/11 bit-identical (je Mutant)
   R/fit.R:452:45 TRUE → FALSE   msa_latent_information identical on 300/300 random weighted inputs; msa_fit end-to-end: 8/8 bit-identical
   R/fit.R:460:18 <n> ± 1        msa_latent_information identical on 300/300 random weighted inputs; msa_fit end-to-end: 8/8 bit-identical (je Mutant)
   R/fit.R:535:61 <n> + 1, x[<i>] → x[<i> + 1L]   msa_numeric_balanced identical on 300/300 random designs; msa_fit end-to-end: 11/11 bit-identical (je Mutant)
   R/fit.R:620:33 <n> ± 1        msa_numeric_reml state: 60/60 bit-identical; msa_fit end-to-end: 11/11 bit-identical (je Mutant)
   R/fit.R:721:52 TRUE → FALSE   lme4 2.0.6: 'REML' occurs 3 times in lFormula body; msa_fit end-to-end: 11/11 bit-identical
   R/fit.R:723:41 TRUE → FALSE   msa_fit end-to-end: 11/11 bit-identical
   R/fit.R:729:86 TRUE → FALSE   msa_fit end-to-end: 11/11 bit-identical
   R/grr.R:102:52 > → >=         grr_stats identical on 403/403 nonnegative component sets (12 with zero GRR)
   R/fit.R:592:43 TRUE → FALSE   msa_numeric_reml state: 12/60 bit-identical, max abs deviation 4.66e-10, NA (outcome differs) 0
                                 msa_fit end-to-end: 4/11 bit-identical; max |dVC|/TV 3.02e-09; warnings equal in all; no error differs
                                 (ic50 2.89e-13, unbalanced 1.3e-13, unbalanced_zero 1.11e-14, zero_component 1.58e-16, near_singular 3.02e-09)
   R/fit.R:603:57 TRUE → FALSE   msa_numeric_reml state: 25/60 bit-identical, max abs deviation 1.46e-11, NA (outcome differs) 0
                                 msa_fit end-to-end: 6/11 bit-identical; max |dVC|/TV 3.62e-09; warnings equal in all; no error differs
                                 (zero_component 1.74e-15, unbalanced_zero 3.48e-15, near_singular 3.62e-09)
   ```

   - Die drei Vorkommen von `REML` in `lFormula` sind Formalargument, Vorgabe und `c(res, list(REML = REML))`; `reTrms` hängt nicht davon ab.
   - Bei `small` und `blocks` bleiben unter `sparse`/`perm` die Komponenten gleich (Abweichung 0), nur `numerics` unterscheidet sich im letzten Bit.
4. **Mutanten im neuen M1c-Code** (`R/grr.R` Z. 122–126, 195–199, 208–210, 222–228; `R/fit.R` Z. 382–384):

   ```text
   R/grr.R mutants on M1c lines: 23   Killed 22, RuntimeError 1
   R/fit.R mutants on M1c lines: 9    Killed 9
   ```

   Der RuntimeError ist `R/grr.R:199:37` `FALSE → TRUE` (`b$t[, seq_along(est), drop = TRUE]`). Mit `nsim = 1` wird das Ergebnis eindimensional, und `colnames<-` bricht ab („attempt to set 'colnames' on an object with less than two dimensions“, nachgestellt). Davon ist der Unit-Test `one bootstrap replicate retains its matrix shape …` betroffen. Der Mutant wird also bemerkt, zählt nach K-M1c-6 aber nicht. Alle 103 Überlebenden liegen in Code, der vor M1c bestand.
5. **Freigabedatei** nach der Score-Regel von `86-mutgate.sh` nachgerechnet:

   ```text
   approvals 17 | detected 1327 | survivors 103 | approved survivors 19 | score 94.05 (without approvals 92.80)
   ```

6. **Kurzläufe aus M1b:**
   - Alle drei Session-Dateien tragen `implementation: 203bc364…`.
   - ordinal_recovery: 2 von 80 Wiederholungen sind nicht konvergiert, beide in S-ord-4 mit `singular convergence (7)`. Keine Wiederholung nennt das Iterationslimit. Damit ist die Angabe in REVIEW-INPUT bestätigt.

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **K-M1c-1:**
  - `msa_boot()` bleibt beim Refit-Pfad von `lme4::bootMer()`, mit Typ-7-Quantilen über die endlichen Werte je Kennzahl und mit unveränderter Reihenfolge der sechs Kennzahlen.
  - Das Singularitätskennzeichen läuft als siebte Spalte durch die `FUN` und wird vor `attr(, "boot")` abgetrennt (ADR-042 Nr. 18.2). Unter `R/` kommt kein Fork-Aufruf hinzu.
- **K-M1c-2:**
  - `n_failed` zählt Zeilen mit mindestens einer nicht endlichen Kennzahl (ACC-2 (1)). `n_singular` zählt singuläre Zeilen unter den übrigen.
  - Druck in zwei Zeilen: „… failed or non-finite replicates (non-finite values dropped)“ ohne „singular“ und „… singular replicates retained in the intervals“ ohne Wort für Verwerfen. Altobjekte melden „not recorded for this object“ (E3 aus PLAN-REVIEW).
- **K-M1c-3:**
  - Alle sieben Szenarien stimmen mit der Tabelle in docs/02 überein (`boot_scenarios()`: Komponenten A und B, Items, Prompts, je drei Modelle und Replikate, Blöcke 2 bzw. 1). S-boot-7 ist binär mit Logit und μ = 0, ohne Rauschen; die Restvarianz kommt aus ANK-28 und geht nur in die wahren Werte ein.
  - Die wahren Werte folgen Formelsammlung §3 mit ndc-Konstante und -Untergrenze aus ANK-16.
  - Kennzahlen nach ACC-5: bias, rel_bias, empse, rmse; coverage und width für die vier Intervall-Schätzziele; singular_share und failed_share als Mittel der Anteile je Wiederholung; überall MCSE, dazu `n_finite`/`n_failed` je Zeile (E5).
  - Der Kurzlauf ist als Tripel vorhanden, `?msa_boot` verweist auf Studie und Vignette.
- **K-M1c-4:**
  - Seeds: `data_seed = 20261102 + 2(j − 1) + 14(r − 1)`, `boot_seed = data_seed + 1`. Sie sind unabhängig von Auswahl, Reihenfolge, `n_sim` und Workerzahl; ein Überlauf wird vor dem Fitten abgewiesen.
  - Die Session nennt Seeds, RNG, R- und Paketversionen sowie Laufzeit. Der Neulauf im Gate ist bytegleich und dauerte 139,6 s.
- **K-M1c-5:**
  - Der Abschnitt hat den Titel wörtlich und liest die Datei über `system.file()`; eine vorhandene Volllaufdatei hat Vorrang.
  - `n_sim` kommt aus der Datei, die Tabellen je Szenario zeigen coverage und MCSE, es gibt kein Ergebnisliteral im Rmd.
  - Die Dateiprüfung ist auf Anteile, MCSE, `n_sim` und Endlichkeit beschränkt (E6, ADR-042 Nr. 11.6). lint: `Status: OK`.
- **K-M1c-6:** Gate mutfull ist grün.
- **K-M1c-7:**
  - Der Hinweis steht wörtlich in `print.msa_grr`, in der Vorlage als eigener Listenpunkt unmittelbar unter der Zeile mit Repeatability und Reproducibility (`inst/templates/validation_report.Rmd:93`) und in `?msa_grr`.
  - Bei numerischen Fits fehlt er. Die Bytegleichheit mit `done/M1b` ist im Gate grün.
- **K-M1c-8:**
  - Ohne das Argument `control` übergibt der Code `ordinal::clmm.control(iter.max = 2000, eval.max = 4000)` (`R/fit.R:382–384`). Jede eigene Angabe, auch `list()` und `NULL`, geht unverändert an die Engine.
  - `?msa_fit` nennt beide Limits, das Ersetzen und den Vorrang direkter Optionen in `...` (E4).
  - Die drei M1b-Kurzläufe sind mit dem Code der Gates neu erzeugt (Prüflauf 6).

### API-Diff und Schnittstellen

- `NAMESPACE` und `DESCRIPTION` sind bytegleich zu `plan/M1c`. Es gibt keine neuen Exporte, Argumente oder Vorgaben; `m0-api-snapshot` ist grün.
- Neu sind das Attribut `n_singular` und die geänderten Druckausgaben; beides ist nach docs/01 §4 ohne ADR zulässig. Die geänderte ordinale Vorgabesteuerung deckt ADR-041.
- `acmg_fit()` erhält die neuen Limits wie in ADR-041 Nr. 3 vorgesehen; `m2-6-evaluate` ist grün.

### Tests

- **Unveränderte Tests:** Kein Abnahmetest und kein QA-Test wurde vom Builder geändert (Prüflauf 1).
- **Geänderter Unit-Test:** Die einzige geänderte bestehende Testdatei, `test-grr-rework.R:140–165`, verlangt jetzt die beiden von K-M1c-2 geforderten Zeilen, auch bei 0. Sie prüft damit mehr als vorher und ist als „Own-output snapshot of display wording“ gekennzeichnet.
- **Neue Tests mit unabhängiger Referenz:**
  - `test-boot.R`: synthetische `bootMer`-Matrix mit `stats::quantile` als Referenz; echte Refits mit injizierten Fehlern und unabhängiger `isSingular()`-Zählung; Grenzfall `nsim = 1`.
  - `test-fit-ordinal-control.R`: direkter `clmm`-Aufruf als differentielle Referenz.
  - `test-validation-bootstrap.R`: geschlossene Sollwerte auf gekennzeichneten synthetischen Fixtures, Seed-Disjunktheit, Reihenfolgeinvarianz, RNG-Wiederherstellung, Fehler- und Zusammenführungspfade.
- **Wortlaut-Prüfungen ohne Momentaufnahme:**
  - Der Text der Altobjekt-Zeile folgt dem Vorschlag aus E3.
  - `test-grr-latent-note.R` prüft den Spec-Satz aus K-M1c-7.
- **Mutation:** Die neuen Zweige werden im Mutationslauf erkannt (Prüflauf 4).

### Konfiguration, Daten, Golden

- Keine Gate- oder Lint-Regel wurde gelockert und kein Skip ergänzt; der eine Unit-Skip (`ellmer`) bestand schon vorher.
- Die Testauswahl des Mutationslaufs ist der Betreiber-Ausdruck aus ACC-14.
- **Literale:**
  - Die Limits 2000/4000 sind Spezifikationswerte (ADR-041 Nr. 1, ACC-18 (1)).
  - Die Szenarioparameter sind die Tabelle aus docs/02.
  - Anker (ANK-06, ANK-16, ANK-28, ANK-TOL) kommen aus den hashgeprüften Kopien.
  - Kein empirisches Literal aus dem Modellgedächtnis.
- **Kurzläufe:** Alle Kurzlaufdateien stammen aus echten Läufen; die Gates reproduzieren sie (K-M1c-4, K-M1b-2, K-M1b-3, ACC-20). Synthetische Testdaten sind als solche markiert.
- **Golden und Anker:** `inst/extdata/` und `reference/anchors/` sind unverändert; golden-adr ist grün.

### ADR-043 und sichtbare Defekte

- **ADR-043:**
  - Die Trennung von Leser und Generator behebt eine echte Literalherkunftsmeldung (`test-validation-latent.R:143`). Die Vignette zog sonst den M1b-Generator mit seinem Szenarioparameter transitiv in ihre Quellen.
  - Weder die Prüfung noch der Parameter wurde geändert. Der Hash der Studie umfasst den Leser weiter, und der Kurzlauf ist danach neu gerechnet.
  - Ich trage die Entscheidung mit.
- **Sichtbare Defekte:** keine gefunden.
  - Zählung, Druck, Hinweis und Steuerung habe ich gegen Spec und Tests gelesen.
  - Die Diagnosen der Replikatdatei sind deterministisch je Wiederholung: Die `lme4`-Meldung „boundary (singular) fit“ kommt je Fit, nicht einmal je Sitzung.
  - Die Session des Kurzlaufs enthält keinen privaten Pfad.

### Territorien und PLAN-REVIEW E1 bis E6

- **Territorien:** Builder-Dateien liegen nur im Builder-Territorium, QA-Dateien nur im QA-Territorium (`tests/e2e`, `tests/fuzz`, `QA.md`, `BACKLOG.md`); das territory-Gate ist grün.
- **E1 bis E6 aus PLAN-REVIEW:**
  - E1 (nur `REVIEW-INPUT.md` und `MUT-EQUIV.json` im Handoff): erfüllt.
  - E2 (Unit-Tests je Zweig, Teillauf, neu gebundene Anträge): erfüllt; der native Teillauf scheiterte an der Sandbox, die Gates liefen regulär.
  - E3: Altobjekt-Zeile und NEWS sind umgesetzt.
  - E4: Rd-Satz und Test mit `iter.max = 7` sind vorhanden.
  - E5: Spalte `seed` und `n_finite`/`n_failed` sind umgesetzt.
  - E6: Leserprüfung beschränkt.

### QA

- QA meldet kein blockierendes Gegenbeispiel; beide QA-Dateien sind im tests-Gate grün.
- QA-M1c-001 betrifft manuell manipulierte CSV-Dateien, die der Schreiber der Studie nicht erzeugt (E8). Ein roter reproduzierender Test liegt nicht vor, also gibt es nichts herabzustufen.

## MUT-EQUIV — Entscheidung je Antrag

Alle Schlüssel aus Datei, `mutatorName` und Anfangszeile treffen im Bericht genau die beantragten Überlebenden (Prüflauf 2). Die Belege stammen aus Prüflauf 3.

| Antrag | Mutant | Urteil | Grund |
| --- | --- | --- | --- |
| `R/fit.R:323:47` | `TRUE → FALSE` (`fixed`) | freigegeben, bitgleich | Doppelpunkt ist auch als regulärer Ausdruck ein Literal |
| `R/fit.R:324:64` | `FALSE → TRUE` (`drop`) | freigegeben, bitgleich | `interaction()` entpackt Faktor, Liste und Datenrahmen gleich |
| `R/fit.R:338:46` | `<n> + 1 → <n> + 1` | freigegeben, bitgleich | Skalierung mit 2 ist im QR exakt |
| `R/fit.R:427:37/46/54` | `+ → -` (drei) | freigegeben, bitgleich | `model.frame()` nimmt alle Variablen der Formel |
| `R/fit.R:452:45` | `TRUE → FALSE` (`fixed`) | freigegeben, bitgleich | Doppelpunkt-Literal |
| `R/fit.R:460:18` | `<n> + 1`, `<n> - 1` | freigegeben, bitgleich | jede Zelle wird vor dem Lesen überschrieben |
| `R/fit.R:535:61` | `<n> + 1`, `x[<i>] → x[<i> + 1L]` | freigegeben, bitgleich im erreichbaren Bereich | `prod(sizes) >= 2`, wenn die rechte Seite ausgewertet wird |
| `R/fit.R:620:33` | `<n> + 1`, `<n> - 1` | freigegeben, bitgleich | jede Zelle wird vor dem Lesen überschrieben |
| `R/fit.R:721:52` | `TRUE → FALSE` (`REML`) | freigegeben, bitgleich | nur `reTrms` wird gelesen |
| `R/fit.R:723:41` | `TRUE → FALSE` (`fixed`) | freigegeben, bitgleich | Doppelpunkt-Literal |
| `R/fit.R:729:86` | `TRUE → FALSE` (`add`) | freigegeben, bitgleich | einziger `on.exit()`-Aufruf der Funktion |
| `R/grr.R:102:52` | `> → >=` | freigegeben, bitgleich für nichtnegative Komponenten | nur bei GRR = +0 verschieden, dort beide `Inf` |
| `R/fit.R:592:43` | `TRUE → FALSE` (`sparse`) | freigegeben nach ADR-039, nicht bitgleich (E7) | dieselbe Algebra in dichter Darstellung |
| `R/fit.R:603:57` | `TRUE → FALSE` (`perm`) | freigegeben nach ADR-039, nicht bitgleich (E7) | Lösung in Originalkoordinaten, Determinante permutationsinvariant |

Nicht beantragt und daher nicht freigegeben sind unter anderem die Überlebenden aus BL-102: `R/fit.R:340:42` und `:346:55` (`symmetric`) sowie `:347:74` (`> → >=`).

## Einwände (Runde 1)

- [E7] (minor) `orchestrator/handoff/M1c/MUT-EQUIV.json`, Anträge `R/fit.R:592:43` und `:603:57`; ADR-039, Konsequenzen; SCHEMA.md („nachweislich verhaltensgleiche Mutanten“) — **Befund:** Der Antrag belegt die Gleichwertigkeit mit „27 tatsächliche Mutanten-Gegenrechnungen liegen innerhalb ANK-TOL.arithmetic.abs_tol = 1e-10“ (größte Abweichung 1,82e-12 bzw. 6,82e-13).
  - Allgemein gilt diese Schranke nicht (Prüflauf 3). Im REML-Zustand weichen `sparse` bis 4,66e-10 und `perm` bis 1,46e-11 absolut ab.
  - Bei `msa_fit()` weichen die Komponenten im nahezu singulären Plan um 3,02e-9 bzw. 3,62e-9 · σ²_TV ab, sonst um höchstens 2,9e-13 · σ²_TV.
  - Warnungen, Fehler und Konvergenz sind in allen geprüften Fällen gleich.
  - Mathematisch bleiben beide Varianten dieselbe Rechnung. ADR-039 erklärt sie für äquivalent und überlässt die Freigabe dem Reviewer.

  — **Vorschlag:** Freigegeben als rechnerisch gleichwertig nach ADR-039, ausdrücklich nicht bitgleich (Begründung in `MUT-EQUIV-APPROVED.json`). Künftige Anträge für Gleitkommavarianten nennen ihren Prüfbereich und die größte gemessene Abweichung einschließlich nahezu singulärer Pläne. Keine Änderung in M1c; Stand in BL-85.
- [E8] (minor) `QA.md` QA-M1c-001; BL-110; ADR-042 Nr. 11.6; PLAN-REVIEW E6 — **Befund:** Die Härtung der CSV-Leser gegen manuell veränderte Dateien bestätige ich als nonblocking.
  - Regulär schreibt nur `boot_replicate()`/`boot_write()` diese Dateien. Die Leserprüfung der Vignette ist absichtlich auf Anteile, MCSE, `n_sim` und Endlichkeit beschränkt (E6).
  - Der QA-Test QA-M1c-FUZZ-2 prüft die aktiven Regeln und ist grün; ein roter reproduzierender Test liegt nicht vor.

  — **Vorschlag:** Umsetzung nach BL-110 nach dem 26.11.2026. Die dort genannten Prüfungen sind mit der Volllaufattrappe aus `test-m1c-5-vignette-full-results.R` vereinbar: dieselben Schätzziele, verschobene Werte, `width`, `empse`, `rmse` ≥ 0.
- [E9] (minor) [Betreiber] docs/02, M1d: „M1d ändert `R/fit.R` und `R/boot.R` nur in der roxygen-Dokumentation.“; ADR-042 Nr. 18.3; ACC-17 — **Befund:** `R/boot.R` gibt es nicht. `msa_boot()` und `print.msa_boot()` liegen in `R/grr.R` und damit im Mutationsumfang von K-M1c-6. Wörtlich genommen ließe der Satz Codeänderungen an `R/grr.R` in M1d zu oder liefe ins Leere.

  — **Vorschlag:** Vor M1d nennt die Spec `R/grr.R`, oder sie beschreibt die Regel für beide Kerndateien. Neu BL-111.
- [E10] (minor) [Betreiber] ACC-21; `docs/gates-auswahl.md:122` („K-M1c-1 bis K-M1c-5“) — **Befund:** K-M1c-7 und K-M1c-8 haben den Prüfweg Test und sind im tests-Gate entschieden (`m1c-7-*`, `m1c-8-*` grün), fehlen aber in der Zuordnung. trace ist nicht betroffen.

  — **Vorschlag:** „K-M1c-1 bis K-M1c-5, K-M1c-7, K-M1c-8“. Stand in BL-48.
- [E11] (minor) [Betreiber] BL-12; BL-92; ADR-041 Nr. 4; docs/02 M1d (Voraussetzung); K-M1d-6 — **Befund:** Die Vollläufe von M1b sind mit dem neuen Implementierungshash ungültig: ordinal, binary und two_level tragen jetzt `203bc364…` statt `477e84a5…`. boot_coverage (`2dcf076e…`) ist neu. Ohne alle vier Vollläufe scheitern K-M1d-6 und K-M1d-7, und sie überspringen nicht.

  — **Vorschlag:** Nach der Abnahme von M1c alle vier Studien mit mindestens ANK-06 Wiederholungen je Szenario rechnen und vor M1d committen. Planungsgrundlage ist die Hochrechnung des Builders, Bootstrap rund 11,4 Stunden; vor der Planung an einem vollständigen Szenario mit der vorgesehenen Workerzahl messen (README). Stand in BL-12 und BL-92.

## BACKLOG

- **Neu:** BL-111 (E9).
- **Statuszeilen „Stand 03.11. (M1c REVIEW r1)“ ergänzt:**
  - BL-12 und BL-92: E11; Kurzlauf ordinal mit 2/80 nicht konvergierten Wiederholungen, keine am Iterationslimit.
  - BL-48: E10.
  - BL-85: Bindung der Freigaben, E7.
  - BL-87: nur Dokumentation in M1c.
  - BL-102: Überlebende weiter unbeantragt.
  - BL-109: der K-M1c-7-Teil ist erledigt.
  - BL-110: E8.
