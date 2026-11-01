# REVIEW — M1b, Runde 3 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 3 · Stand: 01.11.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `6f45bf7…` (`gates.json`, `env.sha`). Schwerpunkt:
  - der Rework der Runde 3 gegenüber dem Review der Runde 2;
  - der QA-Nachlauf zu E26;
  - die während des Gates geschriebenen Betreiberdateien (ADR-031, `MUT-EQUIV-APPROVED.json`).
- die Gate-Fakten `orchestrator/state/M1b/gates.json` der Runde 3 (Lauf nach dem QA-Nachlauf) mit allen acht `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` der Runde 3, `MUT-EQUIV.json` mit drei Anträgen und `QA.md` mit dem Nachlauf.

## Ergebnis

**Verdict REWORK.** `gates.result` ist `pass`; alle acht Gates sind grün. Es bleibt ein blocking-Befund (E29), dazu kommen drei nonblocking-Befunde (E30 bis E32).

- **Runde-2-Befunde:**
  - E24 ist so umgesetzt, wie ADR-029 das Kriterium definiert. Im Rastertest über 388 Pläne entscheidet der Builder in allen 381 geprüften Fällen wie eine unabhängige Rangrechnung (Prüflauf 2). Die Klasse ist aber nicht geschlossen: E29.
  - E25 und E26 sind im Gate bestätigt: `m1b-7-vignette-full-results` 204 Erwartungen; nach dem QA-Nachlauf `m1b-qa-e2e` 26 und `m2-qa-e2e` 9.
  - E27 ist erledigt: Alle vier benannten Mutanten sind getötet. E28 ist erledigt: `NEWS.md` ist ergänzt.
- **Neu und blocking (E29):** Die Identifizierbarkeitsprüfung latenter Fits hat zwei Lücken. Beide gehen auf meine Definition in ADR-029 zurück, nicht auf die Umsetzung.
  - a) Die feste latente Restvarianz fehlt im Kriterium. Ein Zufallsterm mit genau einer Beobachtung je Stufe lässt sich nicht von ihr trennen; `msa_fit()` liefert dann beliebige Zahlen. Beispiel: `ordinal::wine` mit `interactions = TRUE`, Probit, ergibt item 55,49, prompt 27,08, item:prompt 87,16 bei `converged` TRUE und `singular` FALSE, begleitet nur von rohen clmm-Warnungen.
  - b) Häufigkeitsgewichte 0 umgehen die Prüfung. Prompt und Modell mit derselben Partition auf den Zeilen mit positivem Gewicht ergeben ordinal in 5 von 5 Seeds still prompt = model, ohne Warnung. Mit `subset` endet derselbe Plan benannt.
  - ADR-032 Nr. 1 legt die Erweiterung fest. Das erweiterte Kriterium lässt alle Szenario- und Referenzpläne und alle latenten Fits der bestehenden Testsuiten unberührt (Prüfläufe 3 und 7).
- **MUT-EQUIV:**
  - Die drei Anträge des Builders (`R/fit.R:398`, `:405` zweimal) sind echte Äquivalenzen, ebenso die Betreiberneubindung `R/grr.R:99` `> → >=`. Alle vier stehen bestätigt in `MUT-EQUIV-APPROVED.json`.
  - `R/grr.R:99` `<n> - 1 → <n> - 1` ist äquivalent, aber nicht einzeln freigebbar (ADR-032 Nr. 2).
- **In dieser Phase umgesetzt:**
  - `docs/decisions/ADR-032-m1b-code-review-auslegungen-runde-3.md`;
  - `MUT-EQUIV-APPROVED.json` als Reviewer-Bestätigung;
  - in `BACKLOG.md`: BL-98 bis BL-100 neu, BL-94 bis BL-97 gestrichen, Stand-Vermerke in BL-85 und BL-93.

## Gelesen

- **Rollen und Protokoll:**
  - `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`;
  - die Prompts `50-code-review` Runde 3 und `60-rework` Runde 3 (Kopf des Rework-Logs);
  - `orchestrator/orchestrate.sh`: `path_allowed` Z. 483–512 und die Rundenlogik Z. 1035–1052. `LADDER_ENABLED` ist leer, Runde 4 ist ein gewöhnlicher Rework; mit Arbiter sind höchstens 7 Runden möglich;
  - `orchestrator/gates.d/86-mutgate.sh`: Die Freigaben werden über Datei, `mutatorName` und Anfangszeile zugeordnet, Z. 30–42.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 2, `REWORK-NOTES.md` der Runde 3;
  - `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json` in der Betreiberfassung, `QA.md` mit dem Nachlauf vom 01.11.;
  - `ARBITER.md` und `verdict-arbiter.json`: nur E1, Skala und Referenzwerte der binären ICC_items in K-M1b-5. E29 berührt die Skala nicht: Logit rechnet weiter mit π²/3, und BeetlesMale bleibt nach Prüflauf 3 identifizierbar.
  - `PLAN.md` und `PLAN-UPDATE.md` habe ich nur nach Zusagen zu Gewichten und Identifizierbarkeit durchsucht; es gibt keine.
  - Nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:**
  - docs/02 M1b, Z. 20–45; docs/01 §2 Nr. 4;
  - ADR-023 Nr. 9 und 10, ADR-027;
  - vollständig: ADR-029, ADR-030 (Builder) und ADR-031 (Betreiber).
- **Diff, ohne Git:**
  - geänderte Dateien seit dem Review der Runde 2 über `find -newer orchestrator/state/M1b/code-review-r2-infra0.done`;
  - der Inhalt aus dem letzten kumulativen `diff --git`-Block des Rework-Logs `orchestrator/logs/M1b-60-rework-r3-a1-20261031-193758.log`, Z. 17668–18485.
  - Vollständig gelesen:
    - `R/fit.R` und `R/grr.R`;
    - die neuen Testdateien `test-fit-latent-identifiability.R` und `test-fit-latent-calls-labels.R` sowie `helper-validation-latent.R`;
    - `tests/e2e/test-m1b-qa-e2e.R` Z. 140–193 (QA-Nachlauf);
    - `NEWS.md` (Kopf), `man/msa_fit.Rd` (neuer Absatz Z. 149–153), `DESCRIPTION` (Imports unverändert, `Matrix` seit M1a);
    - die Änderung in `inst/validation/sim/simulation_helpers.R:214` und die drei Sessiondateien (Implementierungshash `c2045c7c…`).
  - Abnahme- und Bestandstests sind seit Runde 2 unverändert. Neu sind genau die zwei Unit-Dateien; geändert ist der QA-Test QA-M1b-004.
- **Visuelle Artefakte:** keine; M1b fordert keine (`orchestrator/state/M1b/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 3 (`gates.json`, `env.sha` `6f45bf7`, 01.11.2026 10:17) |
| --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26) |
| lint | pass (`R CMD check --as-cran --no-manual`: Status OK, Tests und Vignetten OK) |
| tests | pass |
| trace | pass |
| territory | pass (qa/45-qa, Runde 3) |
| mutgate | pass: score=92.14 required=91.83 baseline=93.83 floor=80 |
| golden-adr | pass (keine Golden- oder Ankeränderung) |
| mutfull | pass („nicht fällig in M1b“) |
| **result** | **pass** |

- **tests** (`gate-tests.log`):
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3621 ]` (Z. 438). Der Skip ist der bekannte ellmer-Negativtest. Die neuen Dateien liefern `fit-latent-calls-labels` 17 und `fit-latent-identifiability` 204 Erwartungen (Z. 193, 214).
  - `tests/acceptance`: `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 6559 ]` (Z. 896).
    - M1b: m1b-1 34, m1b-2 2155, m1b-3 687, m1b-4 37, m1b-5 9, m1b-6 108, m1b-7-vignette-full-results 204 (Z. 715) und m1b-7-vignette 240.
    - M2: m2-6 383 und m2-7 375; API-Snapshot 259.
    - Die zwei Warnungen stammen aus dem Abnahmehelfer von m1b-4 (Z. 625–652; BL-93).
  - `tests/e2e`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]` (Z. 923), davon m1a 14, m1b 26 und m2 9. Der Namespace-Seiteneffekt aus E26 ist weg.
  - `tests/fuzz`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]` (Z. 943).
  - Kurzbefund: „469 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 944).
- **mutgate** (`gate-mutgate.log`, `mutation.json`):
  - `MUT_TEST_EXCLUDE` ist unverändert (Z. 2). Der unmutierte Vorlauf dauerte 130,9 s mit 373 Tests und 0 roten (Z. 3).
  - Bericht: 1369 Mutanten, davon `R/fit.R` 1123 und `R/grr.R` 246: 1179 Killed, 28 Timeout, 107 Survived, 0 NoCoverage, 55 RuntimeError (Z. 1703–1705).
  - Nachrechnung mit den vier Freigaben: (1179 + 28) / (1179 + 28 + 103) = 92,14, gleich dem Gate-Wert (Z. 1707). Ohne Freigaben ergibt sich 1207 / 1314 = 91,86, ebenfalls über 91,83.
  - Im neuen Prüfcode (`R/fit.R:302–310`, `:396–422`) sind 51 Mutanten getötet und 10 überlebend, davon 3 beantragt (E31).
- **Status error:** keiner. Offene [INFRA]- oder [QA-PENDING]-Ursachen: keine.
- **Betreiber während des Gates (ADR-031):**
  - vier Freigaben in `MUT-EQUIV-APPROVED.json`;
  - `MUT_RATCHET_TOL` 3 statt 2 in `orchestrator/config.env` (Z. 169). Das gilt ab dem nächsten Gate, verlangt sind dann 90,83; vor M1c setzt der Betreiber den Wert zurück.
- **Laufzeit:** Der Rework endete am 31.10. um 20:02. Der QA-Nachlauf lief am 01.11. von 03:00 bis 03:08, das Gate danach bis 10:17: tests bis 03:34, mutgate rund 6 h 40 min.

## Eigene Prüfläufe

Alle am 01.11.2026 mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, rptR 0.9.23 und dem Produktstand `6f45bf7` (Arbeitsbaum gleich HEAD, nur `orchestrator/.lock/` unversioniert), `REPO_ROOT` gesetzt.

- Die Probeskripte lagen unter `tests/acceptance/.probe-m1b-r3/` im eigenen Territorium und sind per `unlink()` gelöscht. Im Arbeitsbaum ist dabei keine weitere Datei entstanden.
- Daten sind synthetisch mit Seeds ab 20261102, dazu `ordinal::wine` und `rptR::BeetlesMale`. Paketausgaben dienen nirgends als Referenz.
- Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Zufallsterme mit einer Beobachtung je Stufe (E29 a).** Verglichen werden `msa_fit()` numerisch, ordinal und binär, dazu die exakte Profil-Likelihood. In (1) sind es 80 Items, in (3) 30 Items × 4 Prompts.

   ```text
   == (1) one observation per item, items only (1 prompt, 1 model, 1 replicate)
   numeric seed 20261102           ERROR number of levels of each grouping factor must be < number of observations (problems: item)
   ordinal probit seed 20261102    item=0.0543 Residual=1.0000 | ICC_items=0.0515 | singular=FALSE converged=FALSE warnings=3
   ordinal probit nAGQ=10 seed 20261102  item=0.3548 Residual=1.0000 | ICC_items=0.2619 | singular=FALSE converged=TRUE warnings=2
   binary logit seed 20261103      item=0.0000 Residual=3.2899 | ICC_items=0.0000 | singular=FALSE converged=TRUE warnings=0
   == (1b) exact profile likelihood, ordinal probit, one observation per item (seed 20261102)
     sigma2_item = 0      max log-likelihood over thresholds = -119.7427357931
     sigma2_item = 0.25   max log-likelihood over thresholds = -119.7427357931
     sigma2_item = 1      max log-likelihood over thresholds = -119.7427357931
     sigma2_item = 4      max log-likelihood over thresholds = -119.7427357931
   == (2) wine (bottle x judge, one replicate)
   ordinal probit interactions=FALSE   prompt=0.4217 item=0.9110 Residual=1.0000 | ICC_items=0.3905 | singular=FALSE converged=TRUE warnings=0
   ordinal probit interactions=TRUE    item:prompt=87.1617 prompt=27.0832 item=55.4910 Residual=1.0000 | ICC_items=0.3250 | singular=FALSE converged=TRUE warnings=2
       warnings: no. random effects (=72) >= no. observations (=72) for term: (1 | item) || no. random effects (=89) >= no. observations (=72)
   ordinal logit interactions=TRUE     item:prompt=0.0000 prompt=1.2101 item=2.7496 Residual=3.2899 | ICC_items=0.3793 | singular=TRUE converged=TRUE warnings=2
   numeric interactions=TRUE           ERROR number of levels of each grouping factor must be < number of observations (problems: item:prompt)
   == (3) crossed items x prompts, one model, one replicate, interactions = TRUE
   binary logit seed 20261102          item:prompt=0.0000 item=0.8326 prompt=1.3693 Residual=3.2899 | ICC_items=0.1516 | singular=FALSE converged=TRUE warnings=0
   ```

   - Die Profil-Likelihood ist flach: Beim Probit-Link ist σ²_item nicht identifizierbar, jeder Wert erklärt die Daten gleich gut.
   - Der Laplace-Fit liefert 0,054, die Quadratur mit `nAGQ = 10` liefert 0,355. Die Zahl hängt also von der Näherung ab, nicht von den Daten.
   - Der numerische Pfad bricht in denselben Plänen benannt ab.

2. **Rastertest über 388 zufällige Pläne.**
   - Gezogen wurden 3 bis 7 Items, 1 bis 4 Prompts, 1 bis 4 Modelle, 1 bis 2 Blöcke und 1 bis 2 Replikate. Die Pläne sind gekreuzt, haben gelöschte Zeilen oder sind auf drei Arten verschachtelt; ordinal oder binär, mit und ohne Wechselwirkungen.
   - Die Entscheidung des Builders wird bei gesperrten Engines ermittelt. Referenz ist der Rang von [vec(P Z_i Z_iᵀ P)] aus Beobachtungspaaren, mit P = I − X(XᵀX)⁻X.
   - Der Lauf gibt Kreuztabellen aus. Unten stehen ihre besetzten Zellen und die übrigen Zeilen wörtlich:

   ```text
   designs: 388
   builder × reference:                 identifiable/identifiable 290, rejected/rejected 91, identifiable/rejected 0, rejected/identifiable 0
   builder "other" (reference NA):      1 "Ordinal random-effect term prompt:model requires at least th…", 3 "Ordinal two-level factors … are not ident…", 3 "Response is constant: …"
   ratios of identifiable reference designs: min 0.216 ; rejected reference designs: max 2e-14
   builder × reference_with_residual:   identifiable/identifiable 266, identifiable/rejected 24, rejected/rejected 91
   builder identifiable, reference with residual rejected: one-observation-per-level term present
         type
   single binary ordinal
     TRUE      8      16
   ratio_resid of designs accepted by both: min 0.099
   ```

3. **Szenariopläne mit Restterm; stille binäre Fits.**
   - Das Eigenwertverhältnis der Gram-Matrix wird im Stufenraum gerechnet, ohne und mit Restterm. Für den Restterm ε gilt G[ε, j] = n − ‖QᵀZ_j‖²_F und G[ε, ε] = n − p.

   ```text
   S-ord-1 (item, prompt, model, item:model)  n= 1620  without residual 0.01439  with residual 0.00243
   S-ord-2                                    n= 2700  without residual 0.01439  with residual 0.001545
   S-ord-4 (block fixed)                      n= 5400  without residual 0.008697 with residual 0.0007839
   S-bin-1 (item, prompt, model)              n= 1620  without residual 0.07375  with residual 0.002664
   S-bin-2                                    n= 2700  without residual 0.07375  with residual 0.001625
   S-two-1 (model fixed)                      n= 1080  without residual 0.07375  with residual 0.003911
   S-two-2 (model fixed)                      n= 1440  without residual 0.08741  with residual 0.003533
   S-ord-1 with all interactions              n= 1620  without residual 0.01017  with residual 0.001724
   wine (bottle, judge)                       n=   72  without residual 0.903    with residual 0.09429
   wine, interactions = TRUE                  n=   72  without residual 0.09429  with residual 1.204e-16
   BeetlesMale (Population)                   n=  480  without residual 1        with residual 0.02656
   == binary, crossed 30 items x 4 prompts, one model, one replicate, interactions = TRUE (item:prompt: one row per level)
     probit: silent fits (no warning, converged, not singular) 1 of 10; ICC_items 0.147 0.365 0.525 0.385 0.252 0.409 0.503 0.495 0.205 0.053; item:prompt 0 0 1.1e-10 1.2e-10 1.3e-09 5.4e-09 7.2e-06 2.6e-06 0 9.7e-08
     logit: silent fits (no warning, converged, not singular) 1 of 10; ICC_items 0.152 0.342 0.509 0.362 0.224 0.380 0.479 0.489 0.181 0.052; item:prompt 3.6e-08 0 0 0 0 0 0 0 0 0
   == binary, one observation per item (60 items, 1 prompt, 1 model, 1 replicate)
     probit: silent fits 0 of 10; ICC_items 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000
     logit: silent fits 0 of 10; ICC_items 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000 0.0000
   ```

   Die übrigen 9 von 10 binären Fits je Link haben eine Warnung, keine Konvergenz oder sind singulär. Die Singularitätsnotiz erklärt den Punktschätzer für gültig („the point estimate is still valid“); für eine nicht identifizierbare Komponente trifft das nicht zu.

4. **Gewichte 0 (E29 b).** Plan: 20 Items, 3 Prompts, 3 Modelle, 2 Replikate. Gewicht 1 nur dort, wo Prompt i mit Modell i läuft, sonst 0. Auf den Zeilen mit positivem Gewicht teilen Prompt und Modell also eine Partition (120 von 360 Zeilen).

   ```text
   seed 20261102 ordinal weights: prompt 0.0545 model 0.0545 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   seed 20261103 ordinal weights: prompt 0.0436 model 0.0436 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   seed 20261104 ordinal weights: prompt 0.0548 model 0.0548 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   seed 20261104 binary  weights: prompt 0.0655 model 0.0745 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   seed 20261105 ordinal weights: prompt 0.0441 model 0.0441 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   seed 20261106 ordinal weights: prompt 0.1416 model 0.1416 | warnings 0 converged TRUE singular FALSE | subset: Latent variance components are not identifiable: ran
   ```

   Die Meldungen sind im Probeskript nach 52 Zeichen abgeschnitten.

   Die übrigen vier binären Fits enden mit einer Konvergenzwarnung und beliebiger Aufteilung, etwa prompt 0,0201 und model 0,0008.

5. **Äquivalenzbelege (MUT-EQUIV).**
   - Geprüft wurden die Originalfunktionen gegen die mutierten Fassungen auf 200 Zufallsplänen (1 bis 7 Terme, Achsenabschnitt oder fester Block).
   - Für `grr_stats()` dienen 1176 nichtnegative Komponentensätze mit Restvarianz 0, fehlenden Quellen und Werten bis 1e10.

   ```text
   strsplit fixed TRUE vs FALSE identical: TRUE
   gram initial value 1: identical result on 200 random designs: TRUE
   gram initial value -1: identical result on 200 random designs: TRUE
   grr_stats on 1176 nonnegative component sets: '>= 0' identical TRUE; '> -1' identical TRUE
   ```

   Schlüssel im Bericht: `R/fit.R` 405 `<n> + 1`, 405 `<n> - 1`, 398 `TRUE → FALSE` und `R/grr.R` 99 `> → >=` treffen je genau einen Mutanten. `R/grr.R` 99 `<n> - 1 → <n> - 1` trifft vier: Spalte 25 Killed, 54 Survived, 61 Killed, 70 Killed.

6. **Numerischer Durchreichweg (E32).** Plan wie in Prüflauf 4.

   ```text
   numeric default, subset w0 > 0       ERROR Numeric variance components are not identifiable.
   numeric explicit weights w0          item:model=0.2316 item:prompt=0.2316 item=0.2316 prompt:model=0.2316 model=0.2316 prompt=0.2316 Residual=0.2316 | singular FALSE converged FALSE warnings 0
   numeric explicit subset w0 > 0       item:model=0.0000 item:prompt=0.2112 item=0.7757 prompt:model=0.0127 model=0.0035 prompt=0.0994 Residual=1.0249 | singular FALSE converged TRUE warnings 0
   ```

7. **Verträglichkeit des erweiterten Kriteriums mit den bestehenden Suiten.**
   - `trace()` auf `msa_latent_information()` rechnet bei jeder vom Builder angenommenen latenten Prüfung das Kriterium mit Restterm auf denselben Eingaben mit. Alle Läufe ergaben 0 Fehlschläge und 0 Fehler.

   Je ein Lauf, in der Reihenfolge Filter `^m1b-(1|4|5|6|7-vignette$)`, Filter `^m2-(6|7)-`, `tests/testthat`, `tests/e2e`, `tests/fuzz`:

   ```text
   tests/acceptance: blocks 42, failed 0, errors 0; latent checks traced 25; extended criterion would reject 0; min ratio of accepted 0.00585
   tests/acceptance: blocks 20, failed 0, errors 0; latent checks traced 30; extended criterion would reject 0; min ratio of accepted 0.000831
   tests/testthat: blocks 247, failed 0, errors 0; latent checks traced 111; extended criterion would reject 8; min ratio of accepted 0.00203
     would reject: n=108 terms prompt ratio 1e-28 single-observation terms:
     would reject: n=108 terms prompt ratio 1.2e-28 single-observation terms:
     would reject: n=108 terms item ratio 1e-28 single-observation terms:
     would reject: n=108 terms item ratio 1e-28 single-observation terms:
     would reject: n=108 terms item ratio 1.2e-28 single-observation terms:
     would reject: n=108 terms item ratio 1.2e-28 single-observation terms:
     would reject: n=108 terms item ratio 6.1e-29 single-observation terms:
     would reject: n=108 terms item ratio 6.1e-29 single-observation terms:
   tests/e2e: blocks 11, failed 0, errors 0; latent checks traced 7; extended criterion would reject 0; min ratio of accepted 0.0153
   tests/fuzz: blocks 5, failed 0, errors 0; latent checks traced 2; extended criterion would reject 0; min ratio of accepted 0.023
   ```

   - Die acht Treffer in `tests/testthat` (n = 108, nur `prompt` oder nur `item`) sind die vom Builder über den Rangnachweis bereits abgewiesenen aufgespannten Terme (`test-fit-latent-identifiability.R:109–150`). Meine Probe rechnet sie ohne dessen Nullsetzung (`R/fit.R:416–420`) und hält sie deshalb für angenommen. Neu abgewiesen würde kein Plan.
   - K-M1b-2 und K-M1b-3 rechnen in eigenen Prozessen; ihre Szenarien deckt Prüflauf 3.

## Stand der Einwände aus Runde 2

| ID | Stand | Beleg |
| --- | --- | --- |
| E24 | umgesetzt wie in ADR-029 definiert; Klasse offen | Prüflauf 2: 381 von 381 Entscheidungen gleich der unabhängigen Rangrechnung; alle drei Teilklassen aus ADR-029 Nr. 2.2 sind getestet. Offen sind Restvarianz und Gewichte: E29 |
| E25 | erledigt | `m1b-7-vignette-full-results` 204 Erwartungen grün (`gate-tests.log` Z. 715); BL-94 gestrichen |
| E26 | erledigt (QA) | QA-M1b-004 läuft über `callr::r()` (`tests/e2e/test-m1b-qa-e2e.R:179–191`); Erwartungen unverändert; `m2-qa-e2e` 9 grün nach `m1b-qa-e2e` 26 (Z. 913–923); BL-95 gestrichen |
| E27 | erledigt | Bericht r3: `R/fit.R:163:44` `&& → \|\|`, `:169:46` `< → <=`, `:343:86` `x[<i>] → x[<i> + 1L]` und `x[<i>] → x[<i> - 1L]` Killed; BL-96 gestrichen |
| E28 | erledigt | `NEWS.md` (Kopf); BL-97 gestrichen. E29 verlangt eine Ergänzung |
| E12–E19 | erledigt (Runde 2) | QA-M1b-001 bis -006 im Gate grün |
| E20 | Builder-Teil erledigt | BL-91, Reviewer-Teil offen (M1c/M1d) |
| E21 | unverändert, spec-gemäß | Kurzlauf-CSVs bytegleich reproduziert; BL-92 |
| E22 | Gate bestätigt | BL-86 |
| E23 | offen, Reviewer | `gate-tests.log` Z. 625–652; BL-93 |

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **ADR-029 Nr. 2.1:**
  - Die Prüfung steht vor beiden latenten Engine-Aufrufen (`R/fit.R:302–310`), nach Bereinigung und Zeilenauswahl (`:240–257`).
  - Der feste Teil besteht aus dem Achsenabschnitt und den ordinalen Zwei-Stufen-Faktoren mit den übergebenen Kontrasten (`:293–303`).
  - Der Abbruch ist ein Fehler, keine Warnung (Nr. 2.6). Die Meldung nennt alle geprüften Terme, nicht die betroffenen (E30).
- **ADR-029 Nr. 2.2**, alle drei Teilklassen getestet:
  - gleiche Partition, binär auch zweistufig (`test-fit-latent-identifiability.R:61–107`);
  - Wechselwirkung mit der Partition eines Haupteffekts, auch erst nach `subset` (`:84–100`);
  - vom festen Design aufgespannte Terme mit q = p und q < p (`:109–150`; Rangnachweis `R/fit.R:416–420`);
  - dazu eine exakte Kovarianzrelation ohne gleiche Partitionen (`:152–170`).
- **ADR-029 Nr. 2.3:** Gram-Kriterium mit der Eigenwertregel des numerischen Pfads, ohne neue Konstante. Laut Prüflauf 2 exakt.
- **ADR-029 Nr. 2.4:**
  - Identifizierbare Pläne behalten ihren Fit: K-M1b-1 (34) und K-M1b-5 (9) sind grün.
  - K-M1b-2 und K-M1b-3 reproduzieren die Kurzläufe im Gate bytegleich.
  - Der Implementierungshash `c2045c7c…` schließt `msa_latent_information()` ein (`simulation_helpers.R:214`).
- **Lücken der Klasse:** E29 (ADR-032 Nr. 1).
- **K-M1b-1 bis K-M1b-7:** Alle Abnahmedateien sind im Gate grün.

### API-Diff

- **Schnittstellen:** keine neuen Exporte, Argumente oder Vorgaben; der API-Snapshot ist grün (259 Erwartungen).
- **Neue Fehlermeldung** für nicht identifizierbare latente Pläne, nach ADR-029. Sie ist in `?msa_fit` (`R/fit.R:117–120`, `man/msa_fit.Rd:149–153`) und `NEWS.md` beschrieben.
- **Abhängigkeiten:** Imports und Suggests unverändert; `Matrix` ist seit M1a importiert.

### Tests: entkernt, eingefroren, hart

- **Bestandstests:** Keine Bestands-, Abnahme- oder Fixture-Datei ist geändert; laut `find -newer` sind in `tests/testthat` nur die zwei neuen Dateien jünger.
  - QA hat QA-M1b-004 im eigenen Territorium umgebaut. Die Erwartungen (`sum(res$failed) == 0`, kein Fehler) und der Prüfgegenstand bleiben.
  - Der Code kommt aus dem geladenen Namespace, im Mutationslauf also der Mutant. Er wird nicht aus `REPO_ROOT` nachgeladen (ADR-029 Nr. 3).
- **Neue Tests belegen Verhalten:**
  - eine unabhängige Rechnung aus Beobachtungspaaren mit dem Projektor X(XᵀX)⁻¹Xᵀ;
  - gesperrte Engines, die den Abbruch vor dem Aufruf belegen;
  - Rangnachweise aufgespannter Terme;
  - direkte `clmm`- und `glmer`-Fits als Orakel;
  - explizite Labelkodierung, zwei ordinale Kategorien und die Neuauswertung des gespeicherten `glmer`-Aufrufs gegen ein direktes `glmer` mit Steuerung, Offset und Gewichten.
- **Keine Momentaufnahme der eigenen Ausgabe.** Toleranzen kommen aus den ANK-TOL-Kopien (`numeric_tolerance()`).
- **Testlücken nach dem Mutationsbericht:** E31.

### Konfiguration, Daten, Golden

- **Konfiguration:**
  - Der Builder hat keine Gate-, Schwellen- oder Lint-Regel gelockert.
  - `MUT_RATCHET_TOL` = 3 ist eine dokumentierte Betreiberentscheidung (ADR-031 Nr. 3). Sie gilt ab dem nächsten Gate; im Gate dieser Runde galt noch 91,83.
- **Daten:**
  - Die neun `_check_`-Dateien sind echte Läufe. Die Ergebnis- und Replikat-CSVs reproduziert das Gate bytegleich.
  - Die Sessiondateien tragen den neuen Implementierungshash. Volllaufdateien gibt es nicht.
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Öffentliches Repository:** Die neuen Dateien enthalten keinen privaten Bezug.

### MUT-EQUIV

Geprüft sind die drei Anträge in `MUT-EQUIV.json` und die vier Betreiberfreigaben aus ADR-031, jeweils einzeln gegen Bericht, Quelltext und Verhalten (Prüflauf 5).

| Stelle | Mutator | Entscheidung | Begründung |
| --- | --- | --- | --- |
| `R/fit.R:405` | `<n> + 1 → <n> + 1` | freigegeben | `gram <- matrix(1, k, k)`: Die Doppelschleife `:406–411` schreibt alle k² Zellen vor dem ersten Lesen. k ≥ 1, weil `item` stets Zufallsterm ist (`:282–285`). Identisch auf 200 Plänen; der Schlüssel trifft genau einen Mutanten |
| `R/fit.R:405` | `<n> - 1 → <n> - 1` | freigegeben | wie oben |
| `R/fit.R:398` | `TRUE → FALSE` | freigegeben | `strsplit(..., fixed = FALSE)`: Der Doppelpunkt ist ein Regex-Literal; identisch auf dem vollständigen internen Namensvorrat |
| `R/grr.R:99` | `> → >=` | bestätigt | Unterschied nur bei grr_v = 0, dort item_v > 0 und Ergebnis Inf wie im `else`-Zweig. Identisch auf 1176 nichtnegativen Sätzen; in M1a als `R/grr.R:94` freigegeben |
| `R/grr.R:99` | `<n> - 1 → <n> - 1` | nicht freigegeben | `grr_v > -1` ist auf nichtnegativen Komponenten äquivalent (Prüflauf 5). Der Schlüssel trifft aber vier Mutanten der Zeile, drei davon nicht äquivalent (Spalten 25, 61, 70). Eine Freigabe wäre nicht einzeln (SCHEMA.md; BL-85) |

- **Korrektur zu ADR-031 Nr. 1:** Der M1a-Mutant „damals Zeile 357“ ist `gram <- curvature <- matrix(0, k, k)` in `msa_numeric_reml()`, heute `R/fit.R:554`. Dort überleben beide Mutanten weiter. Die Freigabe von `:405` trägt der eigene Beweis (ADR-032 Nr. 2).
- **Unverbunden in M1b**, alle aus M1a freigegeben und textgleich:
  - `R/fit.R:162:47`, `:381` (dreimal `+ → -`), `:469:61` (zweimal), `:554:33` (zweimal), `:655:52`, `:657:41` und `:663:86`.
  - Weitere unbeantragte Äquivalente: `:288:47` (wie `:398`) und `:303:46` (`matrix(2, …)` spannt denselben Raum).
  - Sie zählen als Überlebende; der Score ist dadurch nicht geschönt.
  - Der Rework der Runde 4 verschiebt die Zeilen von `R/fit.R` ohnehin. Die Neubindung folgt dem nächsten Bericht (E31, BL-85).

## Einwände (Runde 3)

- [E29] (blocking) ADR-029 Nr. 2.1 („endet `msa_fit()` vor dem Engine-Aufruf mit einer benannten Fehlermeldung, wenn die Varianzen der Zufallsterme, einschließlich der Wechselwirkungen, nach Abzug des festen Teils nicht getrennt identifizierbar sind“) und ADR-029, Konsequenzen („Eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-029.“); docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); `orchestrator/LESSONS.md` („Numerische Randfälle als Klasse beheben.“); ADR-032 Nr. 1 — **Befund:** Die Prüfung `R/fit.R:302–310` mit `msa_latent_information()` (`:396–422`) erfasst zwei Glieder der Klasse nicht:
  - a) **Feste latente Restvarianz.**
    - Auf der latenten Skala normiert die Restvarianz die Skala. Ein Zufallsterm, dessen projizierte Kovarianz von der Einheitsmatrix der Beobachtungen abhängt, lässt sich nicht von ihr trennen. Der Regelfall ist genau eine Beobachtung je Stufe.
    - Beim Probit-Link ist die Profil-Likelihood exakt flach (Prüflauf 1b).
    - `ordinal::wine` mit `interactions = TRUE`, Probit: item 55,49, prompt 27,08, item:prompt 87,16 bei `converged` TRUE und `singular` FALSE, nur mit rohen clmm-Warnungen. Ohne Wechselwirkungen: item 0,911, prompt 0,422.
    - Binär, Items × Prompts, ein Modell, ein Replikat, `interactions = TRUE`: ICC_items je nach Seed 0,05 bis 0,53; 1 von 10 Fits je Link ohne jede Meldung, sonst nur die Singularitätsnotiz, die den Punktschätzer als gültig ausweist.
    - Der numerische Pfad bricht in denselben Plänen ab (Prüflauf 1).
    - Im Rastertest nimmt der Builder 24 solche Pläne an; alle haben einen Term mit einer Beobachtung je Stufe (Prüflauf 2).
  - b) **Gewichte 0.**
    - Die Prüfung rechnet auf allen Zeilen, auch auf solchen ohne Beitrag zur Likelihood.
    - Prompt und Modell mit derselben Partition auf den Zeilen mit positivem Gewicht: mit `subset` benannter Fehler. Mit `weights` liefert der ordinale Fit in 5 von 5 Seeds still prompt = model, etwa 0,0545 (`converged` TRUE, `singular` FALSE, keine Warnung); binär einmal ohne jede Meldung (Prüflauf 4).
  - Die Umsetzung des Kriteriums selbst ist exakt (Prüflauf 2). Die Lücke stammt aus meiner Definition in ADR-029, Kontext und Nr. 2.3.
  — **Vorschlag:**
  - Kriterium nach ADR-032 Nr. 1: das Gram-Kriterium um den Restterm (Einheitsmatrix der Beobachtungen) erweitern.
    - Im Stufenraum gilt mit dem Restterm ε: G[ε, j] = Spur(Z_jᵀWZ_j) − ‖R⁻ᵀXᵀWZ_j‖²_F mit XᵀWX = RᵀR und G[ε, ε] = Σw − p, ohne Gewichte n − ‖QᵀZ_j‖²_F und n − p (Prüflauf 3).
    - Für die Terme rechnen Z_iᵀWZ_j und XᵀWX, sodass Zeilen mit Gewicht 0 nichts beitragen. Der Rangnachweis aufgespannter Terme rechnet auf derselben Darstellung.
    - Die Eigenwertregel bleibt, mit k einschließlich des Restterms. Ein gleichwertiges exaktes Kriterium ist zulässig.
  - Meldung: Fehler vor dem Engine-Aufruf. Ist die Restvarianz beteiligt, nennt die Meldung den Grund, etwa einen Term mit einer Beobachtung je Stufe. „not identifiable“ und die Termnamen bleiben.
  - Unit-Tests ordinal und binär, beide Links, mit gesperrten Engines:
    - Items mit je einer Beobachtung;
    - `item:prompt` mit einer Beobachtung je Zelle, `interactions = TRUE`;
    - wine mit `interactions = TRUE`;
    - Gewichte 0/1 aus Prüflauf 4: derselbe Fehler wie mit `subset`.
  - Weitere Unit-Tests:
    - die unabhängige Paarrechnung (`test-fit-latent-identifiability.R:38–59`) um vec(P) und Gewichte erweitern;
    - identifizierbare Pläne auch mit Gewichten ungleich 1 gegen direkte Engine-Fits.
  - Die Tests müssen die Mutanten der Erweiterung töten. Ab dem nächsten Gate gelten 90,83, und die Freigaben in `R/fit.R` greifen nach Zeilenverschiebungen nicht mehr.
  - Unverändert bleiben müssen alle Pläne aus Prüflauf 3 und 7: Szenarien, wine ohne Wechselwirkungen, BeetlesMale, AP1-Attrappen sowie die Abnahme- und QA-Fits.
  - Danach die neun `_check_`-Dateien neu erzeugen (ADR-023 Nr. 1.5) und `?msa_fit` sowie `NEWS.md` ergänzen.
- [E30] (minor) ADR-029 Nr. 2.1 („Die Meldung nennt die betroffenen Terme.“); ADR-030 Nr. 5 — **Befund:** Die Meldung nennt alle geprüften Zufallsterme (`R/fit.R:307–308`), nicht die betroffenen.
  - Bei verschachtelten Items mit Wechselwirkungen lautet sie etwa „random-effect terms item, prompt, model, item:prompt, item:model, prompt:model“. Betroffen sind nur `item` und `item:model`.
  - ADR-030 Nr. 5 legt das offen; deshalb keine stille Abweichung.
  — **Vorschlag:** nicht verlangt, sinnvoll zusammen mit E29.
  - Die Terme mit nicht verschwindendem Gewicht im Eigenvektor oder Nullraum des kleinsten Eigenwerts nennen, gegebenenfalls einschließlich der Restvarianz.
  - Die Tests prüfen die Termnamen bisher nur als Teilmenge. BL-98.
- [E31] (minor) Gate mutgate (pass, score 92.14, required 91.83; `reports/mutation/mutation.json` Runde 3) — **Befund:** Im neuen Prüfcode überleben 10 Mutanten:
  - `R/fit.R:302:15` `<non-empty string> → ""` öffnet die Prüfung für numerische Fits; kein Test erwartet dort die numerische Meldung.
  - `:308:51` `<non-empty string> → ""` und `:308:99` `FALSE → TRUE`: Meldungsende und `call.` sind ungeprüft.
  - `:399:47` `TRUE → FALSE` (`drop = FALSE`) wirkt nur bei aufgespannten Wechselwirkungen mit unbeobachteten Kombinationen.
  - `:303:46`, `:305:42` und `:305:62` sind praktisch äquivalent; `:398:45` und `:405:18` (zweimal) sind beantragt und freigegeben.
  - Dazu kommen die aus M1a freigegebenen, in M1b unverbundenen Äquivalente (Abschnitt MUT-EQUIV).
  — **Vorschlag:** nicht verlangt, wegen der Zeilenbindung zusammen mit E29 sinnvoll:
  - ein Test mit der exakten numerischen Meldung „Numeric variance components are not identifiable.“ für einen Plan, den auch die latente Prüfung abwiese;
  - ein Test mit der exakten latenten Meldung samt `call.`;
  - echte Äquivalente einzeln mit den endgültigen Zeilen in `MUT-EQUIV.json` beantragen, auch die M1a-Übernahmen.
  - BL-99.
- [E32] (minor) außerhalb der M1b-Kriterien; docs/01 §2 Nr. 4; ADR-032 Nr. 3 — **Befund:**
  - Mit einem Argument in `...` fittet `msa_fit(type = "numeric")` direkt mit `lme4::lmer()`, auch in konfundierten Plänen. Prompt und Modell mit einer Partition über `subset` ergeben still prompt 0,0994, model 0,0035, prompt:model 0,0127 bei `converged` TRUE ohne Warnung.
  - Mit Gewichten 0 sind alle Komponenten 0,2316, `converged` FALSE, ohne Warnung (Prüflauf 6). Der Vorgabepfad bricht benannt ab.
  - Das Verhalten stammt aus M1a und ist dokumentiert („Explicit lme4 arguments retain lme4 warnings and errors.“).
  — **Vorschlag:** keine Builder-Arbeit in M1b. Der Betreiber entscheidet bei der Planung von M1c, ob der Durchreichweg die latente bzw. numerische Identifizierbarkeitsprüfung übernimmt. BL-100.

## Hinweise für REWORK (Runde 4)

- **Umfang:**
  - E29 im Produktcode, mit Tests, neu erzeugten Kurzläufen, `?msa_fit` und `NEWS.md`;
  - E30 und E31 empfohlen, weil dieselben Zeilen berührt werden;
  - E32 ist keine Builder-Arbeit.
- **mutgate:** Ab dem nächsten Gate gilt 90,83 (ADR-031 Nr. 3). Ohne Freigaben lag der Score bei 91,86.
  - Die Freigaben für `R/fit.R:398` und `:405` greifen nach jeder Zeilenverschiebung nicht mehr (BL-85). Neuer Code braucht tötende Tests.
  - Äquivalente beantragt der Builder in `MUT-EQUIV.json`; freigeben kann nur der Reviewer.
- **Bestehende Meldungen beibehalten:** alle aus den Runden 1 bis 3. Tests und QA prüfen sie wörtlich oder über Teilstrings, etwa „not identifiable“, „requires at least three observed levels“ und „levels“.
- **Unveränderter Vorgabepfad:** Identifizierbare Pläne behalten exakt den bisherigen Fit (K-M1b-1, K-M1b-5); die Kurzlauf-CSVs bleiben bytegleich.
- **Belege:** echter Output der gezielten Läufe je Befund-ID in `REWORK-NOTES.md`, einschließlich eines Rasters über Pläne wie in Prüflauf 2 (`orchestrator/LESSONS.md`).
- **Abnahme- und QA-Tests:** unverändert lassen.

## Backlog

- **Neu:** BL-98 (E30, Meldung nennt alle Terme), BL-99 (E31, Testlücken und Äquivalenzanträge im neuen Prüfcode), BL-100 (E32, numerischer Durchreichweg).
- **Gestrichen:**
  - BL-94 (E25) und BL-95 (E26), beide im Gate bestätigt;
  - BL-96 (E27), alle vier Mutanten getötet;
  - BL-97 (E28), `NEWS.md` ergänzt.
- **Stand-Vermerke:** BL-85 (Neubindung in M1b, mehrdeutiger Schlüssel `R/grr.R:99` `<n> - 1`) und BL-93 (unverändert).
- Der blocking-Befund E29 steht nicht im Backlog.
