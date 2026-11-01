# REVIEW — M1b, Runde 4 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 4 · Stand: 01.11.2026 · Keine Git-Kommandos.

Gegenstand:
- der Diff seit `plan/M1b` (Basis `104ca4dd…`) bis zum Gate-Stand `91d82c1…` (`gates.json`, `env.sha`), mit Schwerpunkt auf dem Rework der Runde 4 gegenüber dem Review der Runde 3;
- die Gate-Fakten `orchestrator/state/M1b/gates.json` der Runde 4 mit allen acht `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` der Runde 4 und `MUT-EQUIV.json` mit 17 Anträgen.

## Ergebnis

**Verdict REWORK.** `gates.result` ist `pass`; alle acht Gates sind grün. Es bleiben zwei blocking-Befunde (E33, E34), dazu kommen zwei nonblocking-Befunde (E35, E36).

- **Runde-3-Befunde:**
  - E29 ist umgesetzt, wie ADR-032 Nr. 1 das Kriterium definiert. In kleinen Plänen ist die Umsetzung exakt: Im Reviewer-Raster entscheidet sie 480-mal wie eine unabhängige Rangrechnung (Prüflauf 2). Die Klasse ist aber in zwei Gliedern offen: E33 und E34.
  - E30 ist erledigt: Die Meldung nennt nur die beteiligten Terme.
  - E31 ist erledigt: Die vier benannten Mutanten sind getötet, die Äquivalente beantragt.
  - E32 bleibt nach ADR-032 Nr. 3 außerhalb von M1b (BL-100).
- **Neu und blocking:**
  - **E33, Arbeitsgenauigkeit.** In großen Plänen erkennt die Prüfung exakte Relationen mit der Restvarianz nicht.
    - Die Gram-Einträge entstehen als Quadratsummen über dichte Blöcke aus Stufen × Stufen. Ihr Rundungsfehler wächst mit der Zahl der Stufen und übersteigt die Eigenwertregel k · eps.
    - Von 110 exakten Relationen mit 300 bis 4200 Items oder Zellen erreichen 26 die Engine, die kleinste mit 900 Items.
    - Bei 900 Items mit je einer Beobachtung liefert der binäre Fit item = 0 bei `converged` TRUE und ohne Warnung; bei 2000 Items fehlt auch die Singularitätsnotiz.
    - Dieselbe Matrix, aus dünn besetzten Kreuztabellen gerechnet, erkennt mit der unveränderten Regel alle 72 geprüften Relationen bis 5000 Stufen (Prüfläufe 3 bis 5).
  - **E34, nicht ganzzahlige Gewichte.** Die Prüfung setzt Vielfachheiten auch für nicht ganzzahlige Gewichte fort.
    - 54 Items mit je einer Beobachtung und dem Gewicht 1,5 bestehen die Prüfung; der ordinale Fit liefert still item = 416,29.
    - Umgekehrt weist das Gewicht 0,1 einen identifizierbaren Plan ab (Prüflauf 6).
  - Beide Lücken gehen auf Definitionen in ADR-032 zurück, die ich offen gelassen habe: Arbeitsgenauigkeit großer Pläne und Gewichte, die keine Häufigkeiten sind. ADR-034 Nr. 1 und 2 schließen sie.
- **MUT-EQUIV:** 16 der 17 Anträge sind echte Äquivalenzen und freigegeben. `R/fit.R:168` ist es nicht: Mit einer Zeichenmatrix als Eingabe unterscheidet sich der Mutant beobachtbar (E36).
- **In dieser Phase umgesetzt:**
  - `docs/decisions/ADR-034-m1b-code-review-auslegungen-runde-4.md`;
  - `MUT-EQUIV-APPROVED.json` neu gebunden auf den Bericht der Runde 4;
  - in `BACKLOG.md`: BL-101 und BL-102 neu, BL-98 und BL-99 gestrichen, Stand-Vermerke in BL-85, BL-86, BL-93 und BL-100.

## Gelesen

- **Rollen und Protokoll:**
  - `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md` mit dem Amendment [ADR-027], `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`;
  - der Prompt `50-code-review` Runde 4;
  - `orchestrator/orchestrate.sh`: `path_allowed` (Z. 483–512);
  - `orchestrator/gates.d/86-mutgate.sh`: Zuordnung der Freigaben über Datei, `mutatorName` und Anfangszeile.
- **Handoff M1b:**
  - `CRITERIA.json` (K-M1b-1 bis K-M1b-7);
  - `REVIEW.md` und `verdict-code.json` der Runde 3, `REWORK-NOTES.md` der Runde 4;
  - `MUT-EQUIV.json` mit 17 Anträgen, `MUT-EQUIV-APPROVED.json` der Runde 3;
  - `QA.md`: kein neuer QA-Lauf seit dem Nachlauf vom 01.11.;
  - `ARBITER.md` und `ESCALATION-M1b.md`: unberührt. E33 und E34 betreffen die Logit-Skala π²/3 nicht.
  - Nicht vorhanden: `REVIEW-INPUT.md`.
- **Spezifikation und ADRs:** docs/02 M1b (Z. 20–45), docs/01 §2 Nr. 4, ADR-023 Nr. 1.5, ADR-029, ADR-031 und ADR-032 vollständig, ADR-033 (Builder) vollständig.
- **Diff, ohne Git:**
  - geänderte Dateien seit dem Review der Runde 3 über `find -newer orchestrator/state/M1b/code-review-r3-infra0.done`;
  - der Inhalt aus dem letzten kumulativen `diff --git`-Block des Rework-Logs `orchestrator/logs/M1b-60-rework-r4-a1-20261101-105453.log` (Z. 29035–29501).
  - Geändert sind `R/fit.R`, `NEWS.md`, `man/msa_fit.Rd`, `PROGRESS.md`, die drei `*_check_session.txt` und die Handoffs `REWORK-NOTES.md` und `MUT-EQUIV.json`. Die sechs Kurzlauf-CSVs tragen neue Zeitstempel. Neu sind ADR-033 und zwei Testdateien.
  - Vollständig gelesen:
    - `R/fit.R:100–470` und `:480–800`;
    - `tests/testthat/test-fit-latent-residual-weights.R`, `test-fit-latent-design-grid.R` und `helper-validation-latent.R`;
    - `inst/validation/sim/two_level_check_session.txt` (Kopf; Implementierungshash `815a3da5…`).
  - Abnahme-, QA- und Bestandstests sind unverändert. `find -newer` findet unter `tests/` nur die zwei neuen Unit-Dateien.
- **Visuelle Artefakte:** keine; M1b fordert keine (`orchestrator/state/M1b/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 4 (`gates.json`, `env.sha` `91d82c1`, 01.11.2026 19:21) |
| --- | --- |
| deps | pass (25 Anforderungen, R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4) |
| lint | pass (`R CMD check --as-cran --no-manual`: Status OK, Tests und Vignetten OK) |
| tests | pass |
| trace | pass |
| territory | pass (builder/60-rework, Runde 4, Basis `3b9861c`) |
| mutgate | pass: score=93.02 required=90.83 baseline=93.83 floor=80 |
| golden-adr | pass (keine Golden- oder Ankeränderung) |
| mutfull | pass („nicht fällig in M1b“) |
| **result** | **pass** |

- **tests** (`gate-tests.log`):
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 4709 ]` (Z. 488). Der Skip ist der bekannte ellmer-Negativtest (`test-backends.R:32:3`, Z. 484–486). Die neuen Dateien liefern `fit-latent-design-grid` 768 und `fit-latent-residual-weights` 320 Erwartungen (Z. 221, 263).
  - `tests/acceptance`: `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 6559 ]` (Z. 950).
    - M1b: m1b-1 34, m1b-2 2155, m1b-3 687, m1b-4 37, m1b-5 9, m1b-6 108, m1b-7-vignette-full-results 204 und m1b-7-vignette 240 (Z. 597–811).
    - M2: m2-6 383 und m2-7 375 (Z. 922, 945); API-Snapshot 259 (Z. 499).
    - Die zwei Warnungen stammen aus dem Abnahmehelfer von m1b-4 (Z. 675–690; BL-93).
  - `tests/e2e`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]` (Z. 978), davon m1a 14, m1b 26 und m2 9.
  - `tests/fuzz`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]` (Z. 999).
  - Kurzbefund: „481 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 1000).
- **mutgate** (`gate-mutgate.log`, `mutation.json`):
  - `MUT_TEST_EXCLUDE` ist unverändert (Z. 2). Der unmutierte Vorlauf dauerte 141,7 s mit 385 Tests und 0 roten (Z. 3).
  - Bericht: 1441 Mutanten, davon `R/fit.R` 1195 und `R/grr.R` 246 (Z. 1748). Status: 1264 Killed, 28 Timeout, 98 Survived, 0 NoCoverage, 51 RuntimeError.
  - Nachrechnung: Von den vier Freigaben der Runde 3 trifft nur `R/grr.R:99` „> → >=“ einen Mutanten. (1264 + 28) / (1292 + 98 − 1) = 93,02, gleich dem Gate-Wert (Z. 1752); ohne Freigaben 92,95. Die Einträge `R/fit.R:398` und `:405` zeigten auf verschobene Zeilen ohne Treffer; der Score ist nicht verfälscht.
  - Im geänderten Prüfcode (`R/fit.R:262–267`, `:297–329`, `:412–454`): 154 Killed, 7 Survived, 2 RuntimeError, genau wie im Teillauf des Builders. Sechs der sieben Überlebenden sind beantragt; offen bleibt `:323:74` „> → >=“ (E36).
- **Status error:** keiner. Offene [INFRA]- oder [QA-PENDING]-Ursachen: keine.
- **Laufzeit:** Der Rework endete um 11:27, tests lief bis 11:53, mutgate bis 19:21 (rund 7,5 h).

## Eigene Prüfläufe

Alle am 01.11.2026 mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26 und dem Produktstand `91d82c1` (Arbeitsbaum gleich HEAD, nur `orchestrator/.lock/` unversioniert).

- Die Probeskripte lagen unter `tests/acceptance/.probe-m1b-r4/` im eigenen Territorium und sind per `unlink()` gelöscht.
- Engines sind dort, wo nur die Entscheidung zählt, über `testthat::with_mocked_bindings()` gesperrt: Die Engine endet mit „ENGINE-REACHED“, die Entscheidung des Produkts ist also ablesbar.
- Daten sind synthetisch mit Seeds ab 20261111. Paketausgaben dienen nirgends als Referenz.
- Gezeigt ist echter Output, gekürzt auf die Zeilen zur Sache.

1. **Mutationsbericht und Freigaben.**
   - Jeder der 17 Anträge trifft im Bericht genau den beantragten Mutanten. `R/fit.R:400` „+ → -“ trifft drei, die Spalten 37, 46 und 54; alle drei sind beantragt.
   - Die Freigaben der Runde 3 für `R/fit.R:398` und `:405` treffen nichts. Die Gate-Zuordnung wurde mit der neuen Freigabedatei in R nachgerechnet:

   ```text
   valid JSON: TRUE | approvals: 15
   detected 1292, survivors 98, approved survivors 17, mutants matched by any status 17, score 94.10
   ```

2. **Rastertest über 240 zufällige Pläne mit unabhängiger Referenz.**
   - Gezogen wurden 3 bis 12 Items, 1 bis 4 Prompts, 1 bis 4 Modelle, 1 bis 3 Blöcke und 1 bis 3 Replikate, höchstens 90 Zeilen. Die Gewichte sind 1, 2, 0 bis 2 oder 0, 1 und 3.
   - Neun Topologien: gekreuzt, zufällig gelöscht, Prompt = Modell, Modell in Items verschachtelt, Block = Modell, teils einfach besetzte Zellen, Items mit Gewicht 0 im zweiten Replikat und Konfundierung nur auf den Zeilen mit positivem Gewicht. Jeder Plan wird ordinal und binär gerechnet, mit und ohne Wechselwirkungen.
   - Die Referenz expandiert die Gewichte zu Beobachtungen und bildet den Projektor aus einer SVD-Basis des festen Designs. Entschieden wird über den Rang von [vec(P K_j P), vec(P)] aus den Singulärwerten. Den Gram-Helfer des Produkts ruft sie nicht auf.

   ```text
   Part B: 480 decisions in 3.1 s
                 product
   reference      identifiable precheck rejected
     identifiable          272        0        0
     precheck                0       26        0
     rejected                0        0      182
   mismatches: 0
   reference ratio, identifiable: min 0.004649 | rejected: max 6.518e-26
   ```

3. **Exakte Relationen in großen Plänen.** Die Pläne sind exakt nicht identifizierbar, erwartet ist also „rejected“.

   Einzelbeobachtungen je Item, nur Achsenabschnitt, über die Plangröße:

   ```text
   L | G11 - (L-1) | G1e - (L-1) | Gee - (L-1) | ev_min/ev_max | threshold 2*eps | decision
     500 | +6.821e-13 | +0.000e+00 | +0.000e+00 | +3.702e-16 | 4.441e-16 | rejected
    1000 | -1.251e-11 | +0.000e+00 | +0.000e+00 | -3.130e-15 | 4.441e-16 | rejected
    1500 | +3.547e-11 | +0.000e+00 | +0.000e+00 | +5.916e-15 | 4.441e-16 | ACCEPTED
    2000 | +4.934e-11 | +0.000e+00 | +0.000e+00 | +6.142e-15 | 4.441e-16 | ACCEPTED
    3000 | +1.637e-10 | +0.000e+00 | +0.000e+00 | +1.361e-14 | 4.441e-16 | ACCEPTED
    5000 | +5.430e-10 | +0.000e+00 | +0.000e+00 | +2.715e-14 | 4.441e-16 | ACCEPTED
   ```

   - Der Fehler sitzt in G_11 = Quadratsumme über den dichten L × L-Block (`R/fit.R:434–435`); Restzeile und Restdiagonale sind exakt.
   - L = 1024, 1999 und 2048 werden abgewiesen. Die Entscheidung hängt am Vorzeichen des Rundungsfehlers.

   Fünf Planfamilien, 300 bis 4200 Items oder Zellen, ordinal und binär (Kürzel: a = angenommen, r = abgewiesen):

   ```text
   accepted (exactly non-identifiable): 26 of 110
     binary  items, one observation each              a bei 900, 1500, 1800, 2100, 2400, 3000 Items
     ordinal items, one observation each              a bei 900, 1500, 1800, 2100, 2400, 3000 Items
     ordinal items x 2 prompts, item:prompt one obs.  a bei 1200 und 1800 Zeilen (Prompt fest)
     binary/ordinal items, second replicate weight 0  a bei 900, 1500, 1800, 2100, 2400, 3000 Items
     items x 3 und x 4 prompts, item:prompt one obs.  r durchgehend
   ```

   - Dazu kommt ein zweiter Lauf mit drei Seeds: Bei 2000 Items enden Einzelbeobachtungen, Gewicht-0-Duplikate und ungleich oft beobachtete Items mit je einer positiv gewichteten Beobachtung in 18 von 18 Fällen an der Engine.
   - Gleich große identifizierbare Vergleichspläne erreichen die Engine wie erwartet: drei Beobachtungen je Item; zwei Replikate je Zelle; L Einzelbeobachtungen plus ein doppelt beobachtetes Item. Bei Letzterem fällt das Verhältnis von 0,0397 (L = 10) auf 1,67e-4 (L = 3000), weit über der Schwelle.
   - In Modellen verschachtelte Items mit Wechselwirkungen (`item:model` = `item`, 300 bis 3000 Items) werden alle abgewiesen.

4. **Gegenprobe: dieselbe Gram-Matrix aus dünn besetzten Kreuztabellen.**
   - G_ij = ‖N_ij‖²_F − 2 Spur(B_i N_ij B_jᵀ) + Spur(B_iB_iᵀ B_jB_jᵀ) mit N_ij = Z_iᵀWZ_j und B_j = Qᵀ√W Z_j; Restzeile, Restdiagonale und Rangnachweis wie im Produkt.
   - Ausgegeben ist das Eigenwertverhältnis geteilt durch k · eps; ≤ 1 heißt erkannt. Gezeigt ist je Fall das Maximum über drei Seeds:

   ```text
                                      case    L   product    sparse
     item:prompt singleton, prompt fixed  2000  1.50e+00 -5.00e-02
     item:prompt singleton, prompt fixed  5000 -2.28e+01  0.00e+00
                         singleton items   900  2.63e+00  0.00e+00
                         singleton items  2000  1.38e+01  0.00e+00
                         singleton items  5000  6.11e+01  0.00e+00
   max relative entry difference product vs sparse: 1.09e-13
   product margins > 1 (missed): 18 of 72 | sparse margins > 1: 0
   ```

   - Die übrigen Fälle bis 5000 Stufen (`item:prompt` mit zufälligem Prompt, verschachtelte Items) liegen in beiden Rechnungen unter 1, in der dünn besetzten höchstens bei 0,17.

5. **Ergebnisse angenommener, nicht identifizierbarer Pläne** (echte Engines, wahre Item-Varianz 1):

   ```text
   900 single-observation items ordinal probit item=0.0607 ICC_items=0.0572 converged=FALSE singular=FALSE warnings=3 (clmm „no. random effects (=900) >= no. observations (=900)“, Nichtkonvergenz)
   900 single-observation items binary  probit item=0.0000 ICC_items=0.0000 converged=TRUE singular=TRUE warnings=0
   900 single-observation items binary  logit  item=0.0000 ICC_items=0.0000 converged=TRUE singular=TRUE warnings=0
   2000 single-observation items binary probit item=0.0000 | converged=TRUE singular=FALSE warnings=0
   ordinal 600 items x 2 prompts, interactions, probit: item:prompt=0.0000 item=0.9128 prompt=0.0742 | converged=TRUE singular=TRUE warnings=3 (clmm-Rohwarnungen, Spannweitenmethode)
   ```

   - Binär ist das Ergebnis still falsch. Ordinal kommen nur rohe Engine-Warnungen oder eine Nichtkonvergenzwarnung; die Singularitätsnotiz weist den Punktschätzer als gültig aus.
   - Damit gehören diese Pläne zum Befund aus E29, den ADR-032 als Fehler vor dem Engine-Aufruf verlangt.

6. **Nicht ganzzahlige Gewichte.**

   ```text
   18 items x 3 prompts x 3 models x 3 replicates, ordinal (n = 486): uniform weight c
     c = 1, 0.5, 0.3         interactions FALSE/TRUE -> ENGINE-REACHED
     c = 0.1      interactions=TRUE  -> Latent variance components are not identifiable: random-effect terms item, prompt, model, item:prompt, item:model, prompt:model cannot be separated fr…
     c = 0.002058 interactions=FALSE -> Latent variance components are not identifiable: random-effect terms item, prompt, model cannot be separated from the fixed latent residual variance a…
   single-observation items (54), ordinal: uniform weight c
     c = 0.5, 1  -> Latent variance components are not identifiable: random-effect terms item cannot be separated from the fixed latent residual variance …
     c = 1.25, 1.5, 2, 3 -> ENGINE-REACHED
     fit with c = 1.5: item=416.2907 converged=TRUE singular=FALSE warnings=0
   ```

   Die Meldungen sind im Probeskript nach 150 Zeichen abgeschnitten.

7. **Äquivalenzbelege (MUT-EQUIV).**
   - Jeder Mutant wurde aus der Berichtsstelle neu erzeugt, in eine eigene Umgebung über dem Namespace geladen und gegen das Original gerechnet:

   ```text
   400 (3 mutants): 159 comparisons identical TRUE
   501 (2 mutants): 600 comparisons identical TRUE
   586 (2 mutants): 160 evaluations identical TRUE
   687: lFormula parts other than REML and msa_fit results identical TRUE
   strsplit fixed TRUE vs FALSE identical on internal names: TRUE
   689 msa_fit numeric identical: TRUE
   695: on.exit calls in msa_numeric_fit: 1
   300 drop: identical TRUE | 314 matrix(2): identical TRUE | 431 init +/-1: identical TRUE | 424 strsplit: identical TRUE (600 Gram matrices each)
   msa_fit decisions (120 designs x 2 types): 299 TRUE, 300 TRUE, 314 TRUE
   168: 36 input variants (data frames, lists, character matrix; numeric/ordinal/binary): identical FALSE
   ```

   - Gegenbeispiel `R/fit.R:168`, Zeichenmatrix als `runs`, numerisch:

   ```text
   differs: data     "Attributes: < Component “row.names”: target is numeric, current is character >"
   differs: numerics "Component “input_rows”: names for current but not for target"
   ```

   - Datenrahmen, `msa_runs` und Listen ergeben identische Ergebnisse. Die Differenzen in `model` und `formula` sind Umgebungen und eingebettete Daten; sie entstehen auch beim zweimaligen Lauf des Originals.

8. **Stufen nur mit Gewicht 0** (12 Items × 3 Prompts × 3 Modelle × 2 Replikate; Modell M3 nur mit Gewicht 0):

   ```text
   ordinal model M3 only at weight 0: weights -> Ordinal random-effect term model requires at least three observed levels.
   ordinal same rows via subset          -> ENGINE-REACHED
   binary  model M3 only at weight 0: weights -> ENGINE-REACHED
   binary  same rows via subset          -> ENGINE-REACHED
   ```

9. **Numerischer Vorgabepfad zum Vergleich:** in Modellen verschachtelte Items mit Wechselwirkungen.

   ```text
   items= 300 numeric: ERROR Numeric variance components are not identifiable. [0.5 s]
   items= 900 numeric: ERROR Numeric variance components are not identifiable. [7.9 s]
   items=1500 numeric: ERROR Numeric variance components are not identifiable. [39.3 s]
   items=3000 numeric: ERROR Numeric variance components are not identifiable. [334.8 s]
   ```

   Der numerische Pfad (M1a) entscheidet hier richtig; Einzelbeobachtungen beendet dort lme4 benannt (REVIEW r3, Prüflauf 1).

## Stand der Einwände aus Runde 3

| ID | Stand | Beleg |
| --- | --- | --- |
| E29 | umgesetzt wie in ADR-032 Nr. 1 definiert; Klasse offen | Prüflauf 2: 480 von 480 Entscheidungen gleich der unabhängigen Referenz, einschließlich Gewichten 0 bis 3, Restterm und Konfundierung über Gewichte 0. Wine mit Wechselwirkungen, Einzelbeobachtungen und Gewichte 0/1 enden benannt (`test-fit-latent-residual-weights.R:84–184`). Offen: Arbeitsgenauigkeit großer Pläne (E33) und nicht ganzzahlige Gewichte (E34) |
| E30 | erledigt | `R/fit.R:318–327` nennt die Vereinigung der Nullraumrichtungen; die Tests prüfen exakte Meldungen, auch bei mehreren Relationen und verschachtelten Items (`test-fit-latent-residual-weights.R:113–137`, `:186–207`); BL-98 gestrichen |
| E31 | erledigt | Bericht r4: `R/fit.R:313:15`, `:327:12`, `:327:60` und `:425:47` sind Killed; 17 Anträge mit endgültigen Zeilen; BL-99 gestrichen |
| E32 | unverändert, außerhalb M1b | numerischer Durchreichweg bytegleich (REWORK-NOTES P7); BL-100 |
| E12–E19 | erledigt (Runde 2) | QA-M1b-001 bis -006 im Gate grün |
| E20 | Builder-Teil erledigt | BL-91, Reviewer-Teil offen (M1c/M1d) |
| E21 | unverändert, spec-gemäß | Kurzlauf-CSVs im Gate bytegleich reproduziert; BL-92 |
| E22 | Gate bestätigt | lint: Zeitprüfung OK; m2-7 mit 375 Erwartungen grün; BL-86 |
| E23 | offen, Reviewer | `gate-tests.log` Z. 675–690; BL-93 |

## Prüfung nach Gesichtspunkten

### Spec- und Vertragstreue

- **ADR-032 Nr. 1.1 (Restterm):**
  - Das Kriterium rechnet über alle Zufallsterme und den Restterm (`R/fit.R:315`, `:445–450`), mit G_jε = Σw − ‖B_j‖²_F und G_εε = Σw − p.
  - Die Eigenwertregel zählt den Restterm in k mit (`:317`). Entschieden wird über `only.values = TRUE`; die Eigenvektoren dienen nur der Meldung (`:322–323`).
  - Für die Definition ist das exakt (Prüflauf 2), aber nicht bis an die Arbeitsgenauigkeit großer Pläne: E33.
- **ADR-032 Nr. 1.2 (Gewichte):**
  - Zeilen mit Gewicht 0 entfallen in der Gram-Rechnung (`:419–422`), in der Kategorien- und Stufenprüfung (`:267`, `:300`) und im festen Rang (`:307`).
  - Ganzzahlige Gewichte wirken als Vielfachheiten; Prüflauf 2 bestätigt das mit expandierten Beobachtungen.
  - Nicht ganzzahlige Gewichte setzt die Umsetzung ebenfalls als Vielfachheiten fort: E34.
  - Die Termauswahl zählt weiter alle Zeilen: E35.
- **ADR-032 Nr. 1.3:** Fehler vor beiden Engines mit `call. = FALSE`, keine Warnung. Ist die Restvarianz beteiligt, nennt die Meldung den Grund („cannot be separated from the fixed latent residual variance“); „not identifiable“ und die Termnamen bleiben.
- **ADR-032 Nr. 1.4:** Identifizierbare Pläne behalten ihren Fit.
  - K-M1b-1 (34) und K-M1b-5 (9) sind grün; K-M1b-2 und K-M1b-3 reproduzieren die Kurzläufe im Gate bytegleich.
  - Die gewichteten Fits gleichen direkten `clmm`- und `glmer`-Aufrufen (`test-fit-latent-residual-weights.R:263–299`).
- **K-M1b-1 bis K-M1b-7:** Alle Abnahmedateien sind im Gate grün.

### API-Diff

- **Schnittstellen:** keine neuen Exporte, Argumente oder Vorgaben; der API-Snapshot ist grün (259 Erwartungen).
- **Neue Meldungen:**
  - die Gewichtsprüfung „Ordinal and binary weights must be finite, non-negative numeric values with a finite positive sum.“;
  - der Restvarianzgrund in der Identifizierbarkeitsmeldung.
  - Beide stehen in `?msa_fit` (`R/fit.R:117–126`, `man/msa_fit.Rd`) und `NEWS.md`. Der lint-Gate-Lauf bestätigt die Übereinstimmung von Code und Dokumentation.
- **Abhängigkeiten:** Imports und Suggests unverändert.

### Tests: entkernt, eingefroren, hart

- **Bestandstests:** Keine Bestands-, Abnahme-, QA- oder Fixture-Datei ist geändert.
- **Neue Tests belegen Verhalten:**
  - Beobachtungspaare expandierter Häufigkeiten samt vec(P) als unabhängige Referenz (`test-fit-latent-residual-weights.R:9–22`, `test-fit-latent-design-grid.R:4–34`);
  - algebraische Relationen, darunter vier Partitionen mit Σ P K_j P = 3P (`test-fit-latent-residual-weights.R:113–137`) und ein gesättigtes festes Design;
  - gesperrte Engines, die den Abbruch vor dem Aufruf belegen;
  - direkte Engine-Fits als Orakel mit Toleranz aus ANK-TOL (`numeric_tolerance("engine_ordinal", "rel_tol")`).
- **Keine Momentaufnahme der eigenen Ausgabe:**
  - Exakte Meldungstexte sind der dokumentierte Vertrag aus ADR-032 Nr. 1.3.
  - `got[6L, 6L] == sum(weights) − ncol(X)` folgt aus der Formel, nicht aus einem früheren Lauf.
- **Grenze der Tests:** Das Raster des Builders reicht bis 64 Zeilen, die Einzeltests bis 18 Items mit je einer Beobachtung und `ordinal::wine` (72 Zeilen). Die Größen, in denen die Rundung die Regel übersteigt, deckt kein Test ab (E33).

### Konfiguration, Daten, Golden

- **Konfiguration:** Der Builder hat keine Gate-, Schwellen- oder Lint-Regel gelockert. `MUT_RATCHET_TOL` = 3 ist die Betreiberentscheidung aus ADR-031 Nr. 3; im Gate galt 90,83.
- **Daten:**
  - Die neun `_check_`-Dateien sind echte Läufe; das Gate reproduziert die Ergebnis- und Replikat-CSVs bytegleich.
  - Die Sessiondateien tragen den Implementierungshash `815a3da5…`. Volllaufdateien gibt es nicht.
- **Golden:** `inst/extdata/` und `reference/anchors/` sind unverändert (golden-adr pass).
- **Öffentliches Repository:** Die neuen Dateien enthalten keinen privaten Bezug.
- **[INFRA] des Builders** (REWORK-NOTES P2, P4 bis P6, P8): mirai-Dispatcher, `timedatectl`, Zeitprüfung und Sockets. Sie bestehen nur in der Builder-Sandbox; im Gate sind lint und m2-7 grün (BL-86).

### MUT-EQUIV

Geprüft sind die 17 Anträge in `MUT-EQUIV.json` einzeln gegen Bericht, Quelltext und Verhalten (Prüfläufe 1 und 7).

| Stelle | Mutator | Entscheidung | Begründung |
| --- | --- | --- | --- |
| `R/fit.R:168:47` | `FALSE → TRUE` | nicht freigegeben | `as.data.frame(runs, stringsAsFactors = TRUE)` ändert bei Datenrahmen nichts und bei Listen das Ergebnis nicht. Eine Zeichenmatrix, die `msa_fit()` ohne Fehler annimmt, ergibt aber Zeichen-Zeilennamen in `fit$data` und benannte `numerics$input_rows` (Prüflauf 7). Abhilfe: Argument entfernen oder Test (E36) |
| `R/fit.R:299:47`, `:424:45`, `:689:41` | `TRUE → FALSE` | freigegeben | `strsplit(..., fixed = FALSE)`: Der Doppelpunkt ist auch als regulärer Ausdruck ein Literal; Gruppennamen nur intern |
| `R/fit.R:300:64` | `FALSE → TRUE` | freigegeben | `dat[rows, columns, drop = TRUE]`: Bei einer Spalte entpackt `interaction()` den Datenrahmen ohnehin, bei zwei wirkt `drop` nicht; identische Stufenzahlen |
| `R/fit.R:314:46` | `<n> + 1 → <n> + 1` | freigegeben | `matrix(2, …)`: Die Skalierung um eine Zweierpotenz ist exakt; bitgleiche Gram-Matrizen auch mit nicht ganzzahligen Gewichten |
| `R/fit.R:400` (Spalten 37, 46, 54) | `+ → -` | freigegeben | `aggregate.formula()` gruppiert über `model.frame()` nach allen Formelvariablen; der Schlüssel trifft genau die drei beantragten Mutanten, alle äquivalent |
| `R/fit.R:431:18` | `<n> ± 1` (zweimal) | freigegeben | Alle Zellen werden vor dem ersten Lesen geschrieben, mit und ohne Restterm |
| `R/fit.R:501:61` | `<n> + 1 → <n> + 1`, `x[<i>] → x[<i> + 1L]` | freigegeben | `counts[2]` statt `counts[1]`: Erreichbar nur mit `prod(sizes)` ≥ 2, weil jeder numerische Zufallsterm mindestens zwei Stufen hat |
| `R/fit.R:586:33` | `<n> ± 1` (zweimal) | freigegeben | `gram` und `curvature` werden vor dem ersten Lesen vollständig geschrieben |
| `R/fit.R:687:52` | `TRUE → FALSE` | freigegeben | Von `lFormula()` werden nur `reTrms` gelesen; alle Teile außer `REML` sind gleich |
| `R/fit.R:695:86` | `TRUE → FALSE` | freigegeben | genau ein `on.exit()` in `msa_numeric_fit()` |
| `R/grr.R:99:52` | `> → >=` | bestätigt | wie in Runde 3 |

- Auf den Bericht der Runde 4 angewandt ergibt sich ein Score von 94,10 statt 93,02.
- Die Freigaben sind an die Zeilen von `91d82c1` gebunden. Jede trägt Spalte und Quellzeile (`column`, `code`); nach dem nächsten Rework bindet der Reviewer sie neu (BL-85).

## Einwände (Runde 4)

- [E33] (blocking) ADR-032 Nr. 1 („Die Prüfung vor dem ordinalen und dem binären Engine-Aufruf bezieht die feste latente Restvarianz ein.“) und ADR-032, Konsequenzen („eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-032“); ADR-029 Nr. 2.1 und 2.2 („Das gilt als Klasse“); docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); `orchestrator/LESSONS.md` („Rastertest über Pläne, Rauschstufen bis an die Arbeitsgenauigkeit und mehrere Seeds“); ADR-034 Nr. 1 — **Befund:** Die Prüfung erkennt exakte Relationen großer Pläne nicht.
  - **Ursache:** `msa_latent_information()` bildet jeden Eintrag als `sum(block^2)` über einen dichten Block aus Stufen × Stufen (`R/fit.R:434–435`).
    - Der Rundungsfehler wächst mit der Zahl der Stufen. Bei 2000 Einzelbeobachtungen liegt G_11 um 4,9e-11 neben L − 1, das sind 2,5e-14 relativ.
    - Die Regel lässt nur k · eps zu, hier 4,4e-16. Das berechnete Verhältnis beträgt 6,1e-15 (Prüflauf 3).
  - **Umfang:**
    - Von 110 exakten Relationen mit 300 bis 4200 Items oder Zellen erreichen 26 die Engine, die kleinste mit 900 Items. Betroffen sind Einzelbeobachtungen je Item, `item:prompt` mit einer Beobachtung je Zelle bei festem Prompt und Gewicht-0-Duplikate.
    - Ob ein Plan abgewiesen wird, hängt am Vorzeichen des Rundungsfehlers: 1000, 1024, 1999 und 2048 Items werden abgewiesen, 1500, 2000 und 2500 nicht.
  - **Folge** (Prüflauf 5):
    - binär bei 900 und 2000 Einzelbeobachtungen still item = 0 und ICC_items = 0, `converged` TRUE, ohne Warnung;
    - ordinal nur rohe clmm-Warnungen und eine Nichtkonvergenzwarnung, etwa item = 0,061 bei wahrer Varianz 1;
    - ordinal 600 Items × 2 Prompts mit Wechselwirkungen: item:prompt = 0 bei `converged` TRUE.
  - **Gegenprobe:** Dieselbe Matrix aus dünn besetzten Kreuztabellen erkennt mit der unveränderten Regel 72 von 72 Relationen bis 5000 Stufen, mit höchstens dem 0,17-Fachen der Schwelle; das Produkt erreicht das 61-Fache (Prüflauf 4).
  - Die Raster des Builders (bis 64 Zeilen) und meines aus Runde 3 (3 bis 7 Items) reichten nicht in diese Größen; die Schwelle stammt aus meiner Vorgabe in ADR-029 und ADR-032.
  — **Vorschlag** (ADR-034 Nr. 1):
  - Die Gram-Matrix so berechnen, dass ihr Rundungsfehler nicht mit der Zahl der Stufen wächst. Geprüft ist G_ij = ‖N_ij‖²_F − 2 Spur(B_i N_ij B_jᵀ) + Spur(B_iB_iᵀ B_jB_jᵀ) mit N_ij = Z_iᵀWZ_j dünn besetzt und B_j = Qᵀ√W Z_j; Restzeile, Restdiagonale und Rangnachweis unverändert.
  - Das entfernt auch die dichten Blöcke; bei 5000 Stufen hält ein Block mit Zwischenergebnissen mehrere 200-MB-Matrizen.
  - Die Eigenwertregel bleibt unverändert; keine größere Schwelle. Ein gleichwertiges exaktes Kriterium ist zulässig.
  - Unit-Tests bei gesperrten Engines, ordinal und binär, in den versagenden Größen:
    - mindestens 900, 1500 und 2000 Einzelbeobachtungen;
    - Items × 2 Prompts mit Wechselwirkungen ab 1200 Zeilen;
    - Gewicht-0-Duplikate ab 900 Items;
    - verschachtelte Items mit Wechselwirkungen ab 1000 Items;
    - gleich große identifizierbare Vergleichspläne, die die Engine erreichen.
  - Dazu ein Raster über Plangrößen und Seeds nach `orchestrator/LESSONS.md` mit echtem Output in `REWORK-NOTES.md`.
- [E34] (blocking) ADR-032 Nr. 1.2 („Grundlage der Prüfung ist die Information, die in die Likelihood eingeht. Zeilen mit Gewicht 0 zählen nicht. Häufigkeitsgewichte gehen als Vielfachheiten ein“); docs/01 §2 Nr. 4; ADR-029 Nr. 2.1; ADR-034 Nr. 2 — **Befund:** Die Umsetzung setzt Vielfachheiten auch für nicht ganzzahlige Gewichte fort (ADR-033 Nr. 2, `R/fit.R:262–266`, `:422`, `:426`).
  - 54 Items mit je einer Beobachtung und dem einheitlichen Gewicht 1,25 oder 1,5 bestehen die Prüfung. Mit 1,5 liefert der ordinale Fit item = 416,29 bei `converged` TRUE und `singular` FALSE, ohne jede Warnung (Prüflauf 6).
  - Ein nicht ganzzahliges Gewicht beschreibt keine wiederholte Beobachtung. Die einzelne Beobachtung je Item trennt die Item-Varianz nicht von der Restvarianz.
  - Umgekehrt weist das Gewicht 0,1 den identifizierbaren Plan 18 × 3 × 3 × 3 mit Wechselwirkungen ab, das Gewicht 1/n jeden Plan, mit der Meldung „cannot be separated from the fixed latent residual variance“.
  - ADR-032 hat nur Häufigkeitsgewichte geregelt; die Lücke liegt in meiner Definition.
  — **Vorschlag** (ADR-034 Nr. 2):
  - Sind alle Gewichte ganze Zahlen, bleiben sie Vielfachheiten. Andernfalls zählt jede Zeile mit positivem Gewicht genau einmal, auch im festen Rang und im Rangnachweis.
  - Engine-Aufruf und Engine-Daten bleiben unverändert. Ein pauschaler Fehler für nicht ganzzahlige Gewichte setzt das nicht um (Schnittstellenregel).
  - Unit-Tests bei gesperrten Engines:
    - Einzelbeobachtungen mit 1,25 und 1,5 enden benannt;
    - 0,1 und 1/n auf dem identifizierbaren Plan erreichen die Engine;
    - ganzzahlige Gewichte 2 und gemischte Gewichte werden geprüft.
  - `?msa_fit` und `NEWS.md` ergänzen.
- [E35] (minor) ADR-032 Nr. 1.2 („Zeilen mit Gewicht 0 zählen nicht.“); ADR-033 Nr. 7 — **Befund:** Die Termauswahl (`R/fit.R:275–292`) zählt Stufen auf allen Zeilen, die Stufenprüfung (`:300`) nur auf positiv gewichteten.
  - Kommt eine Modellstufe nur mit Gewicht 0 vor, endet der ordinale Fit mit „Ordinal random-effect term model requires at least three observed levels.“. Mit `subset` auf dieselben Zeilen fittet er mit festem Zwei-Stufen-Modell (Prüflauf 8).
  - Benannt, nicht still. Binär erreichen beide Wege die Engine.
  — **Vorschlag:** nicht verlangt. In `?msa_fit` nennen, dass Stufen mit Gewicht 0 bei der Termauswahl mitzählen, oder auf `subset` verweisen. Eine Termauswahl nur über positiv gewichtete Zeilen änderte die Engine-Daten (ADR-033 Nr. 7). BL-101.
- [E36] (minor) Gate mutgate (pass, score 93,02, required 90,83; `reports/mutation/mutation.json` Runde 4); SCHEMA.md („Nur einzeln vom Reviewer approvte, nachweislich verhaltensgleiche Mutanten verlassen den Nenner.“); ADR-034 Nr. 3 — **Befund:**
  - `R/fit.R:168:47` „FALSE → TRUE“ ist nicht äquivalent: Gegenbeispiel Zeichenmatrix (Prüflauf 7). Die M1a-Freigabe desselben Mutanten wird nicht fortgeführt.
  - Unbeantragt überlebt `R/fit.R:323:74` „> → >=“ an der Namensschwelle; der Builder legt das offen.
  — **Vorschlag:** nicht verlangt.
  - `stringsAsFactors = FALSE` in `:168` entfernen; für Datenrahmen ohne Wirkung, für Listen und Matrizen ab R 4.0 die Vorgabe, und DESCRIPTION verlangt R ≥ 4.1. Alternativ ein Test mit Zeichenmatrix.
  - Nach der Zeilenverschiebung der Runde 5 die Anträge mit den endgültigen Zeilen erneuern. BL-102.

## Hinweise für REWORK (Runde 5)

- **Umfang:** E33 und E34 im Produktcode, mit Tests, neu erzeugten Kurzläufen, `?msa_fit` und `NEWS.md`. E35 und E36 sind empfohlen, nicht verlangt.
- **Budget:** Runde 5 ist die letzte reguläre Rework-Runde (`MAX_ROUNDS_REWORK=5`). ADR-034 legt deshalb Formel, Regel, Testgrößen und Gewichtsregel fest. Was dort steht, genügt; weitere Klassenglieder sind nicht verlangt.
- **Unverändert bleiben:**
  - alle Meldungen der Runden 1 bis 4;
  - der Vorgabepfad identifizierbarer Pläne, also K-M1b-1, K-M1b-5 und die bytegleichen Kurzlauf-CSVs;
  - Abnahme-, QA- und Bestandstests.
- **mutgate:** Es gelten 90,83 (ADR-031 Nr. 3). Die Freigaben in `MUT-EQUIV-APPROVED.json` sind an die Zeilen von `91d82c1` gebunden und greifen nach jeder Verschiebung nicht mehr; neuer Code braucht tötende Tests. Äquivalente beantragt der Builder mit den endgültigen Zeilen in `MUT-EQUIV.json`.
- **Laufzeit:** Die großen Testpläne mit gesperrten Engines kurz halten. mutgate wiederholt die Unit-Tests je Mutant; der unmutierte Vorlauf dauert 141,7 s.
- **Belege:** echter Output je Befund-ID in `REWORK-NOTES.md`, einschließlich des Rasters über Plangrößen und Seeds.

## Backlog

- **Neu:** BL-101 (E35, Termauswahl und Gewicht 0), BL-102 (E36, Äquivalenz `R/fit.R:168` und unbeantragter Mutant `:323:74`).
- **Gestrichen:** BL-98 (E30 erledigt), BL-99 (E31 erledigt).
- **Stand-Vermerke:** BL-85 (Neubindung auf `91d82c1`, Felder `column` und `code`), BL-86 (Sandbox-Befunde Runde 4), BL-93 (unverändert), BL-100 (unverändert).
- Die blocking-Befunde E33 und E34 stehen nicht im Backlog.
