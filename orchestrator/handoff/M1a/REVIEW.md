# REVIEW — M1a, Runde 4 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 4 · Stand: 30.10.2026

Gegenstand:
- der Diff seit `plan/M1a` (Commit `485c9605…`) bis HEAD `5757a24…`; Schwerpunkt ist der Rework-Commit `4f0547b…` gegenüber dem Review-Commit `e263066…` der Runde 3;
- die Gate-Fakten `orchestrator/state/M1a/gates.json` der Runde 4 (`env.sha` `4f0547b`) mit allen `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` und die zehn Anträge in `MUT-EQUIV.json`.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren). Zur Rundenfolge `orchestrate.sh` (`run_ms`) und die Rundengrenzen in `orchestrator/config.env` (`MAX_ROUNDS_REWORK=5`, `REBUILD_ROUND=6`, `LADDER_ENABLED` leer): Ein REWORK führt zu einem gewöhnlichen `60-rework` in Runde 5.
- **Handoff M1a:**
  - `CRITERIA.json` (K-M1a-1 bis K-M1a-7);
  - `REVIEW.md` und `verdict-code.json` der Runde 3, `REWORK-NOTES.md` der Runde 4, `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json` (Stand Runde 3);
  - `QA.md` (QA-M1a-001 bis -005; alle QA-Tests seit Runde 2 grün und unverändert).
  - Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`.
- **Spezifikation:**
  - K-M1a-1 bis K-M1a-7 im Wortlaut (`docs/02-statistikkern.md` Z. 10–16); das trace-Gate bestätigt die wörtliche Verknüpfung;
  - `docs/01-fachspezifikation.md` §2 Nr. 1 und Nr. 4;
  - ADR-012, ADR-018 Nr. 1 bis 5, ADR-020 mit allen Nachträgen bis Runde 4, ADR-022 vollständig.
- **Gates:** `gates.json` und alle acht `gate-*.log` der Runde 4; `mutation.json` mit 1108 Mutanten; zum Vergleich `gate-mutgate.log` der Runde 3 aus Commit `e263066`.
- **Diff, vollständig gelesen:**
  - `R/fit.R` ganz (Stand `4f0547b`) und als `diff -u` gegen `e263066`;
  - die Diffs zu `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md` und ADR-020 (angehängter Nachtrag Runde 4);
  - die neue Datei `tests/testthat/test-fit-initialization.R` ganz, dazu `helper-m1a-rework.R` und `helper-validation-numeric.R`.
- **Visuelle Artefakte:** keine; M1a fordert keine (`orchestrator/state/M1a/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 4 (`gates.json`, `env.sha` `4f0547b`) |
| --- | --- |
| deps | pass (22 Anforderungen, R 4.6.1, Matrix 1.7.4 ≥ 1.6-0) |
| lint | pass (`R CMD check --as-cran`: Status OK, Vignetten neu gebaut) |
| tests | pass |
| trace | pass |
| territory | pass (builder/60-rework, Runde 4) |
| mutgate | pass: score=93.74 required=91.79 baseline=93.79 floor=80 |
| golden-adr | pass |
| mutfull | pass („nicht fällig in M1a“) |
| **result** | **pass** |

- **tests:**
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2680 ]` (Runde 3: 2601; die 79 neuen Erwartungen stammen aus dem Kontext `fit-initialization`); der Skip ist der bekannte ellmer-Negativtest;
  - `tests/acceptance`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3070 ]`, unverändert;
  - `tests/e2e`: `PASS 23`, `tests/fuzz`: `PASS 12`; alle QA-Tests grün und unverändert.
- **mutgate:**
  - unmutierter Vorlauf 90,5 s, 265 Tests, 0 rot; Zeitlimit 453 s je Mutant;
  - Bericht: 1108 Mutanten (`R/fit.R` 866, `R/grr.R` 242): 942 Killed, 31 Timeout, 66 Survived, 0 NoCoverage, 69 RuntimeError;
  - `required` 91,79 = Baseline 93,79 − Ratchet 2.
  - Nachrechnung mit der Zuordnung des Gates (`86-mutgate.sh:29–47`): 973 / (973 + 66 − 1) = 93,74 trifft den Gate-Wert. Von den acht Approvals der Runde 3 traf wieder nur `R/grr.R:94`; die sieben `R/fit.R`-Einträge zeigten auf um vier Zeilen verschobene Stellen ohne passenden Überlebenden (E48/BL-85). Der Score ist also nicht verfälscht. Ohne jede Approval: 93,65, ebenfalls über der Schwelle.
- **Status error:** keiner. Kein Gate-Befund ist [INFRA].
- **Laufzeit (BL-13):** Gate-Lauf 14:16–19:11, also ≈ 4 h 55 min:
  - lint ≈ 3 min;
  - tests ≈ 19 min (Abnahme 1056,4 s, testthat 70,5 s, e2e 2,7 s, fuzz 1,1 s);
  - mutgate ≈ 4 h 33 min, ein muttest-Durchgang mit 16.286,2 s über 1108 Mutanten, 31 Timeouts.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

**Methode:**
- Den Diff habe ich mit einem eigenen R-Leser für lose Objekte unter `.git/objects` gelesen (Commit → Baum → Blob), die Bäume von `e263066` und HEAD verglichen und die Dateien mit `diff -u` gegenübergestellt.
- Arbeitsbaum = HEAD: Die Blob-SHA-1 von `R/fit.R` (`ae291ec6…`), der neuen Testdatei (`8d3e4ec2…`), `man/msa_fit.Rd`, `NEWS.md`, ADR-020, `PROGRESS.md` und `MUT-EQUIV.json` gleichen den HEAD-Einträgen. `R/fit.R` hat SHA-256 `73caf980…` wie in REWORK-NOTES. Der Quelltext im Mutationsbericht gleicht dem Arbeitsbaum (`R/fit.R`, `R/grr.R`).
- Gerechnet habe ich mit `pkgload::load_all()` gegen den Arbeitsbaum. `msa_fit()` der Runde 3 lief aus dem Blob von `e263066` in einer Kindumgebung des Namensraums.
- Hilfsdateien lagen nur unter `reports/rv-m1a-r4/` (git-ignoriert, Artefakt-Allowlist) und sind gelöscht.

1. **Inventar.**
   - `e263066` → HEAD: 20 Pfade.
     - 8 Builder-Pfade: `R/fit.R`, `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md`, ADR-020, die neue `tests/testthat/test-fit-initialization.R`, `REWORK-NOTES.md`, `MUT-EQUIV.json`;
     - sonst Gate-Zustand, `summary.json` und `STATUS.md`.
   - Unverändert: alle bestehenden Testdateien, `tests/acceptance/**`, `tests/e2e/**`, `tests/fuzz/**`, `tests/fixtures/**`, `reference/anchors/**`, `inst/**`, `R/grr.R`, `DESCRIPTION`, `NAMESPACE`, `BACKLOG.md`, `MUT-EQUIV-APPROVED.json`.
2. **Produktdiff.**
   - Neu ist nur `R/fit.R:471–475`: ein `tryCatch` um den lme4-Startfit auf der konditionierten Antwort. Ein Fehler endet mit `stop("Numeric model initialization failed: ", conditionMessage(e), call. = FALSE)`.
   - Der äußere `withCallingHandlers` sammelt Warnungen und Meldungen wie bisher; das innere `tryCatch` fängt nur `error`. `Rcpp::exception` erbt von `error` und wird gefangen.
   - Beim Abbruch bleibt `completed` falsch; der unveränderte `on.exit`-Handler (`R/fit.R:461`) gibt die Startwarnungen in ihrer Reihenfolge und ohne Aufruf weiter.
   - Planfehler prüft schon `lme4::lFormula()` in `R/fit.R:453`. Sie behalten die lme4-Meldung ohne Präfix, wie in v0.1.0. Nachgerechnet: `msa_simulate(6, 3, 1, 1, …, seed = 3)` endet mit „number of levels of each grouping factor must be < number of observations (problems: item:prompt)“.
   - Sonst nur roxygen (`R/fit.R:67–68`, `82–85`), `man/msa_fit.Rd` und ein Satz in `NEWS.md`.
3. **E50, Reproduktionen.** Alle drei Fälle aus REVIEW r3 E50 enden jetzt mit „Numeric model initialization failed: Downdated VtV is not positive definite“, Klasse `simpleError`, Aufruf `NULL`, ohne Warnung. In Runde 3 endeten sie mit `Rcpp::exception`. RSS/SST nach `stats::aov`: 6,4e-17, 1,0e-17 und 3,8e-19.
4. **Lauf A, Breite.**
   - Aufbau: fünf Pläne mit identischen Replikaten (E50 Nr. 1 und 2, QA-Fall A vollständig, der 5 × 3-Plan vollständig, neu ein balancierter 6 × 4 × 2-Plan mit Item-, Prompt- und Wechselwirkungseffekten), Rauschen 1e-3 bis 1e-13, Seeds 1001–1005; 275 Fits, jeweils mit dem Code der Runden 3 und 4.
   - Runde 3: 70 rohe Abbrüche (`Rcpp::exception`). Runde 4: 3. Die übrigen 67 enden jetzt mit dem Startpräfix; alle anderen Ausgänge sind gleich (27 Fits, 178 benannte Fehler).
   - Ausgänge Runde 4: 41 × „did not converge“, 60 × „not identifiable“, 67 × „cannot be resolved“, 67 × „initialization failed“, 10 × „not representable“, 3 roh.
   - Die drei rohen Fälle liegen alle im neuen balancierten Plan; Aufrufstapel `msa_numeric_fit` > `devfun` → **E54**.
5. **Lauf B, balancierte Pläne mit geschlossener Lösung.**
   - Aufbau: 6 × 4 × 2, 8 × 3 × 3 und 10 × 3 × 2 × 2 (zwei Modelle, alle Zweifach-Wechselwirkungen), Rauschen 1e-5 bis 1e-10, Seeds 2001–2010; 180 Fits mit dem Code der Runde 4.
   - Rauschen 1e-5: 26 Fits über `closed_form`, 4 benannt. 1e-6: 1 Fit, 25 × „not representable“, 4 sonst benannt. 1e-7: 5 roh, 21 × „not representable“, 4 sonst benannt. 1e-8 bis 1e-10: alle benannt, überwiegend „cannot be resolved“.
   - Die 5 rohen Fälle laufen alle über die geschlossene Lösung (λ_max 4,7e13 bis 1,9e14, RSS/SST 3,0e-15 bis 8,9e-15) und enden in `devfun(theta)` mit `Rcpp::exception` → **E54**.
   - In zwei Fällen mit benannter „not representable“-Meldung (8 × 3 × 3, Rauschen 1e-9 mit Seed 2007 und 1e-10 mit Seed 2010) erreichen je vier Warnungen den Aufrufer, darunter CHOLMOD „not positive definite“ aus `devfun(theta)` → E54.
6. **Warnungen bei benannten Fehlern (Lauf A).** Es sind lme4-Startwarnungen (Konvergenzprüfungen), nach ADR-020 (E17) zulässig. Ausnahmen: eine CHOLMOD-Warnung bei einem „not representable“-Fall und zwei beim rohen Fall Nr. 2 aus E54. Die 67 „initialization failed“-Fälle tragen keine Warnung.
7. **Testwirksamkeit (docs/01 §2 Nr. 1).** `test-fit-initialization.R` gegen `msa_numeric_fit()` der Runde 3: 4 von 6 Blöcken rot, 9 Erwartungen falsch, 70 richtig. Gegen Runde 4: 79 richtig. Das deckt die Angabe in REWORK-NOTES.
8. **Mutation.**
   - Die 66 Überlebenden gleichen nach Zeilenabbildung über den Quelltext genau den 66 der Runde 3: keiner getötet, keiner neu.
   - Alle fünf Mutanten im neuen Handler (`R/fit.R:472`, `:474` zweimal, `:478`, `:481`) sind getötet.
9. **MUT-EQUIV:** jeden Antrag einzeln gegen Bericht, Quelltext und Verhalten geprüft (Abschnitt MUT-EQUIV).

## Bewertung

### Spec- und Vertragstreue

- K-M1a-1 bis K-M1a-7: Alle Abnahmetests sind grün, die Vignette baut im lint-Gate. Die Änderung berührt keinen Abnahmepfad.
- **E50 ist erledigt.**
  - Der Startfit endet benannt (ADR-018 Nr. 3): kein `Rcpp::exception`, keine Matrix- oder CHOLMOD-Warnung, Startwarnungen weiter nach ADR-020 (E17).
  - Der Präfix nennt die Stufe, die Ursache bleibt die Meldung der Engine. Das ist eine klare Fehlermeldung im Sinn von docs/01 §2 Nr. 4.
  - Die Meldung „residual variance cannot be resolved“ war nur ein Vorschlag. Die Begründung des Builders trägt: Eine positive Reststreuung wird nicht pauschal zum Problem der Restskala erklärt.
- **Offen** ist derselbe rohe Abbruch an der zweiten ungeschützten lme4-Stelle des Vorgabepfads, dem Modellbau auf der Originalskala (`R/fit.R:516–518`) → E54 (blocking).
  - ADR-022 Nr. 6.2 verlangt dort den benannten Fehler mit „representable“.
  - `?msa_fit` sagt es selbst: „The default path rejects variances whose original-scale representation or model arithmetic loses working precision“ (`R/fit.R:87–89`).
- ADR-018 Nr. 1 und 2 bleiben gewahrt: `vc` stammt aus `VarCorr(model)`; den Durchreichweg vergleicht Block 3 des neuen Tests mit direktem `lmer`.
- Eine stille Abweichung nach ADR-022 Nr. 6.1 habe ich nicht gefunden. Die Nachbarfälle von E54 enden benannt über `R/fit.R:530–532`.
- Kein Widerspruch zwischen Spec-Stellen, also kein ESCALATE. E54 braucht keine neue Auslegung, ADR-022 Nr. 6.2 deckt den Fall.

### API-Diff

- `NAMESPACE`, Signaturen und Vorgaben sind unverändert.
- Neu ist nur der Präfix einer Fehlermeldung im Vorgabepfad. Er ist in ADR-020 (Nachtrag Runde 4), `?msa_fit` und `NEWS.md` genannt.
- `?msa_fit`: zwei neue Sätze (`R/fit.R:67–68`) und ein neu gefasster (`R/fit.R:82–85`). Beide habe ich am Code geprüft; sie stimmen. Der neue Satz nennt als Fehlerstellen nur „initialization or analytic completion“, den Modellbau nach der geschlossenen Lösung nicht → E56.

### Integrität

- **Entkernte oder geänderte Tests:** keine. Der Rework fügt eine Datei hinzu; alle bestehenden Test-, Abnahme-, QA- und Fixture-Dateien sind blob-gleich.
- **Gelockerte Konfiguration:** keine.
- **Harte Erwartungswerte:** keine. Rauschpegel und Seeds sind Eingaben; die Grenze (64 · eps)² aus ADR-020 dient nur als Vorbedingung.
- **Erfundene Daten:** keine. Die synthetischen Testdaten sind als solche gekennzeichnet (Z. 1–2, 52–53).
- **Golden-Daten und Anker:** unverändert.

### Neue Tests

- Die Tests belegen Verhalten gegen unabhängige Referenzen:
  - **Block 1** (drei Reproduktionen, Z. 22–49):
    - Die Vorbedingungen stammen aus `stats::aov` (Rest-FG > 0, RSS/SST über der Nullgrenze).
    - Die Ursache liefert ein direkter lme4-Aufruf auf derselben Konditionierung (Z. 34–38, gleichwertig zu `msa_numeric_condition()`).
    - Nur der Präfix ist eigene Ausgabe. Er ist als solche gekennzeichnet (Z. 42–43; `helper-m1a-rework.R:16–18`).
  - **Block 2** (Z. 51–73): Ein synthetischer Enginefehler über `local_mocked_bindings(.package = "lme4")` prüft Präfix, äußere Klasse, Reihenfolge der Warnungen und `call = NULL`. Er prüft auch, dass der Durchreichweg die Originalbedingung unverändert liefert. Der Block hängt nicht von der Plattform ab.
  - **Block 3** (Z. 75–95): Durchreichweg gegen direktes `lmer` mit `ANK-TOL.engine_boot`; er verzweigt sauber nach dem Ausgang der Engine.
  - **Block 4** (Z. 97–123): positive Gegenfälle gegen `lmer` mit bobyqa (`ANK-TOL.oracle`, Anteil von σ²_TV), auch bei Skala 1e-100.
- Lücken:
  - Kein Fall für den Modellbau (E54).
  - Block 1 setzt voraus, dass lme4 auf genau diesen Daten scheitert (Z. 39) → E55.

## Stand der Einwände aus Runde 3

Der Builder beantwortet alle IDs Punkt für Punkt (REWORK-NOTES).

| ID | Stand | Beleg |
| --- | --- | --- |
| E50 | erledigt | Nachprüfungen 3, 4 und 7; `R/fit.R:471–475`; `test-fit-initialization.R:22–73` |
| E51 | teilweise (Dokumentationsweg aus dem Vorschlag); die numerische Verbesserung bleibt offen | `R/fit.R:82–85`, `man/msa_fit.Rd`, ADR-020 Nachtrag Runde 4; BL-87, neuer Stand → E56 |
| E52 | erledigt (Dokumentationsweg aus dem Vorschlag) | ADR-020 Nachtrag Runde 4: O(Nq) Speicher, O(Nq²) Arbeit, die Reviewer-Messungen richtig zitiert; BL-88 gestrichen |
| E53 | teilweise | `:267` (vorher 263) beantragt und freigegeben; der Rest ist nicht verlangt und bleibt offen → BL-84 |
| E48 | offen, Betreiber | BL-85; Approvals in dieser Runde neu gebunden (Abschnitt MUT-EQUIV) |
| E49 | offen, Betreiber | BL-86; der Builder bestätigt beide Befunde unverändert |
| E39, E41, E42 | offen, Betreiber | BL-77, BL-79, BL-80 |
| E43 | vertagt nach M1b | BL-81 |

## Einwände

### Blocking

- [E54] (blocking) ADR-022 Nr. 6.1 und 6.2 (`docs/decisions/ADR-022-m1a-code-review-auslegungen.md:44–49`: „Bei Überschreitung gilt eine von zwei Lösungen: … ein benannter englischer Fehler. Ein stilles Ergebnis ist ausgeschlossen.“; „Varianzkomponenten, die auf der Originalskala nicht mit dieser Präzision darstellbar sind, … enden mit dem benannten Fehler, der „representable“ nennt.“); docs/01 §2 Nr. 4 (`docs/01-fachspezifikation.md:18`: „Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“); ADR-018 Nr. 3 (`docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md:51`: „`msa_fit()` endet mit einer benannten englischen Fehlermeldung (docs/01 §2 Nr. 4) …“); `?msa_fit` (`R/fit.R:87–89`: „The default path rejects variances whose original-scale representation or model arithmetic loses working precision …“); REVIEW M1a r3 E50 (dieselbe rohe Meldung am Startfit, blocking) — **Befund:**
  - Nach der Lösung baut der Vorgabepfad das Modell auf der Originalskala: `lFormula` → `mkLmerDevfun` → `devfun(theta)` (`R/fit.R:516–518`). Eine Fehler- oder Warnungsbehandlung gibt es dort nicht.
  - Die Darstellbarkeitsprüfungen davor (`R/fit.R:506–512`) und danach (`R/fit.R:529–533`) fangen nur ungenaue Ergebnisse, keinen Abbruch in `devfun`.
  - Bei sehr hoher Wiederholpräzision liefert die geschlossene Lösung exakte, endliche Verhältnisse λ ≈ 1e13 bis 1e16 (θ bis 1,1e8). Der PLS-Schritt von lme4 bricht dann auf der Originalskala mit `Rcpp::exception` „Downdated VtV is not positive definite“ ab. Die Meldung erreicht den Aufrufer roh, teils mit CHOLMOD-Warnungen.
  - Reproduktionen über die öffentliche API: ein balancierter 6 × 4 × 2-Plan mit einem Modell; die geschlossene Lösung greift.

    ```r
    set.seed(11L)
    d <- expand.grid(item_id = paste0("I", 1:6), prompt_id = paste0("P", 1:4),
                     model_id = "M1", rep = 1:2, stringsAsFactors = FALSE)
    it <- rnorm(6); pr <- rnorm(4, sd = 0.7); ip <- rnorm(24, sd = 0.4)
    d$value <- it[as.integer(factor(d$item_id))] + pr[as.integer(factor(d$prompt_id))] +
      ip[as.integer(interaction(factor(d$item_id), factor(d$prompt_id)))]
    set.seed(S); d$value <- d$value + e * rnorm(48)
    msa_fit(as_msa_runs(d))
    ```

    1. e = 1e-7, S = 1002: aov-RSS/SST 2,8e-15 (Rest-FG 24); λ (item:prompt, item, prompt) = 8,5e12, 1,5e14 und 6,3e13;
    2. e = 1e-8, S = 1001: 6,2e-17; λ bis 6,6e15. Dazu kommt zweimal „CHOLMOD warning 'not positive definite' at file 'Cholesky/t_cholmod_rowfac_worker.c', line 449“;
    3. e = 1e-8, S = 1005: 3,6e-17; λ bis 1,1e16.

    Alle drei enden mit Klasse `Rcpp::exception/C++Error/error/condition`; der innerste Paketrahmen ist `devfun(theta)`. Die Restquadratsumme liegt 11 bis 13 Größenordnungen über der Nullgrenze (64 · eps)² = 2,0e-28.
  - Unabhängige Referenz:
    - Die aov-EMS-Schätzer sind endlich und nichtnegativ: item 1,14, prompt 0,4945, item:prompt 0,0665; Rest 7,8e-15, 1,7e-16 und 1,0e-16. Es gibt also ein genaues, endliches Ergebnis.
    - Direktes lme4 endet auf diesen Daten teils roh, teils mit still falschen Komponenten (Nr. 2 mit nloptwrap: item 0,300, prompt 1,1e-4).
    - Richtig ist im Vorgabepfad deshalb nur das genaue Ergebnis oder die benannte Meldung.
  - Breite:
    - In Lauf A 3 von 275 Fits, in Lauf B 5 von 180 (8 × 3 × 3 und 10 × 3 × 2 × 2, Rauschen 1e-7, RSS/SST 3,0e-15 bis 8,9e-15). Alle laufen über die geschlossene Lösung und enden in `devfun(theta)`.
    - Nachbarfälle desselben Bandes enden benannt mit „… not representable …“ (`R/fit.R:530–532`). Dort rechnet `devfun` ungenau statt gar nicht. Der Ausgang hängt also nur an der Rundung im PLS-Schritt.
  - Kein Rückschritt: Runde 3 endet in allen drei Fällen gleich. Es ist aber dieselbe rohe Meldung wie in E50, jetzt an der zweiten ungeschützten lme4-Stelle. Der Fix der Runde 4 schützt nur den Startfit; die Reproduktionen von E50 lagen alle im allgemeinen Pfad.
  - Der Fall ist genau ADR-022 Nr. 6.2: Die Komponenten sind im lme4-Modell auf der Originalskala nicht darstellbar. Vorgesehen ist dafür der benannte Fehler mit „representable“.

  — **Vorschlag:**
  - Den Modellbau auf der Originalskala (`R/fit.R:516–529`, mindestens `devfun(theta)`) so absichern wie den Cholesky-Schritt in `msa_numeric_reml()` (`R/fit.R:334–339`):
    - Fehler enden mit der vorhandenen Meldung „Numeric model variance is not representable on the original scale at working precision.“ (ADR-022 Nr. 6.2);
    - Warnungen von Matrix oder CHOLMOD aus diesem Schritt erreichen den Aufrufer nicht, sondern führen zur selben Meldung (sinngemäß ADR-022 Nr. 7; E50: „keine Warnung von Matrix oder CHOLMOD“);
    - die lme4-Konvergenzprüfung `checkConv` (`R/fit.R:524`) bleibt, wie `?msa_fit` sie beschreibt.
  - Kein Ersatzwert, kein Rückfall auf eine lme4-Optimierung, keine angehobene Nullgrenze, keine künstliche Reststreuung.
  - Unit-Tests:
    - die drei Reproduktionen. Vorbedingungen unabhängig aus `stats::aov`: Rest-FG > 0, RSS/SST über (64 · eps)², alle EMS-Schätzer ≥ 0, damit die geschlossene Lösung greift. Verlangt sind die benannte Meldung, Klasse `simpleError` ohne Aufruf und keine Warnung von Matrix oder CHOLMOD.
    - zusätzlich, ohne Abhängigkeit von der Plattform, ein synthetischer Abbruch beim Modellbau, etwa über `local_mocked_bindings(mkLmerDevfun = …, .package = "lme4")` mit einer Devianzfunktion, die warnt und abbricht (vgl. E55);
    - ein positiver Gegenfall: derselbe Plan mit e = 1e-3 und S = 1001 fittet über `closed_form`, ohne Warnung, mit den aov-EMS-Schätzern als Komponenten (`ANK-TOL.oracle`). Nachgerechnet: 0,06644, 1,14, 0,4944, Rest 1,716e-6.
  - ADR-020 um einen Satz zum Modellbau ergänzen.

### Nonblocking

- [E55] (minor) AGENTS.md, Projektblock, Parallelisierung („Windows-CI ist Release-Bedingung“); ADR-012, Kontext (REML-Fits auf macOS weichen nach Zeilenumkehr um 2,7e-6 · σ²_TV ab) — **Befund:**
  - Block 1 von `test-fit-initialization.R` (Z. 22–49) verlangt, dass der direkte lme4-Start auf genau diesen Daten scheitert (`expect_s3_class(engine$value, "error")`, Z. 39).
  - Ob „Downdated VtV …“ eintritt, hängt an der Rundung im Optimiererpfad. Gelingt der Start auf einer anderen Plattform, ist der Test rot, obwohl `msa_fit()` dann korrekt fittet oder benannt endet.
  - Belegt ist das nicht: Die CI läuft erst nach einem Push (`PUSH_REMOTE=0`), geprüft ist nur Linux.
  - Den Vertrag selbst sichert Block 2 ohne Abhängigkeit von der Plattform; Block 3 verzweigt schon nach dem Ausgang der Engine.

  — **Vorschlag:**
  - Block 1 nach dem Ausgang der direkten Rechnung verzweigen. Scheitert sie, wird der Präfix verlangt. Gelingt sie, wird ein Fit oder eine benannte Meldung verlangt, nie `Rcpp::exception`.
  - Ebenso die Tests zu E54.
  - Nicht verlangt. BL-89.
- [E56] (minor) ADR-018 Nr. 5 (Robustheitsnachweis); `?msa_fit` (`R/fit.R:83–85`: „A positive residual variance does not guarantee a fit: with high repeatability, initialization or analytic completion can fail at working precision.“); BL-87 (E51) — **Befund:**
  - Auch der Weg über die geschlossene Lösung ist bei hoher Wiederholpräzision begrenzt.
    - In Lauf B enden bei Rauschen 1e-6 (RSS/SST ≈ 1e-12) 25 von 30 Fits mit „Numeric model variance is not representable on the original scale at working precision.“, obwohl die geschlossene Lösung die aov-EMS-Schätzer trifft.
    - Ursache ist die Präzisionsprüfung des lme4-Modells (`R/fit.R:529–533`). Nach ADR-022 Nr. 6 ist das zulässig.
  - Gelingt der Fit, meldet `checkConv` im E54-Plan bei e = 1e-4 und 1e-5 (RSS/SST 6e-9 bis 3e-11) „Hessian is numerically singular: parameters are not uniquely determined“.
    - Die Komponenten gleichen dabei die EMS-Schätzer: 0,06649, 1,14, 0,4945.
    - Die Warnung kommt aus der θ-Skala: Bei großem θ werden die Eigenwerte der Hesse-Matrix klein. Sie meldet hier Nichtidentifizierbarkeit, wo keine besteht. Bei e = 1e-3 erscheint sie nicht.
  - `?msa_fit` nennt als Fehlerstellen nur „initialization or analytic completion“; der Modellbau nach der geschlossenen Lösung fehlt.

  — **Vorschlag:**
  - Mit E54 den Satz in `?msa_fit` um den Modellbau ergänzen.
  - Die Szenarien hoher Wiederholpräzision (BL-87) um balancierte Pläne mit geschlossener Lösung erweitern und die checkConv-Warnung dort einordnen, etwa dokumentieren.
  - Spätestens vor M1d. BL-87.

[INFRA]: Zu E48 und E49 gibt es nichts Neues für den Builder. Den Stand führen BL-85 und BL-86.

## MUT-EQUIV

**Grundlage:**
- zehn Anträge in `MUT-EQUIV.json`: sieben auf um vier Zeilen verschobene, textgleiche `R/fit.R`-Zeilen, `R/grr.R:94` unverändert, zwei neu für `R/fit.R:267`. Sie betreffen zwölf überlebende Mutanten im Gate-Bericht der Runde 4.
- Jeden Antrag habe ich gegen `reports/mutation/mutation.json` (Datei, `mutatorName`, Zeile, Status Survived) und gegen den Quelltext geprüft. Auf keiner der Zeilen gibt es weitere Überlebende desselben `mutatorName`.
- Für die sieben verschobenen `R/fit.R`-Anträge habe ich je Mutant eine mutierte Kopie der Funktion in den Namensraum gesetzt und Ende-zu-Ende verglichen. Eingaben: 26, nämlich `ic50_demo`, je vier balancierte und unbalancierte Simulationen, Zeichenwerte, schlichte Listen und neun Pläne nahe der Nullgrenze. Darunter sind acht Fehlerwege, sechs davon mit Warnungen; vier dieser sechs geben Startwarnungen über `on.exit` weiter. Verglichen wurden `vc`, `numerics`, Startwarnungen, `singular`, `n`, θ, Warnungen und Fehler.

**Ergebnis:** Alle zehn sind echte Äquivalenzen und stehen in `MUT-EQUIV-APPROVED.json`.

| Datei:Zeile | `mutatorName` | Quelltext (Stand `4f0547b`) | Nachprüfung in Runde 4 |
| --- | --- | --- | --- |
| `R/fit.R:233` | `+ → -` (3 Mutanten, Spalten 37, 46, 54) | `stats::aggregate(y ~ item + prompt + model + block, …)` | Textgleich mit r3:229 (Freigabe Runde 3). Jeder der drei Mutanten ist Ende-zu-Ende identisch auf 26 Eingaben. |
| `R/fit.R:113` | `FALSE → TRUE` | `as.data.frame(runs, stringsAsFactors = FALSE)` | Textgleich mit r3:109. Identisch auf 26 Eingaben, auch mit Zeichenspalten und schlichter Liste. |
| `R/fit.R:352` | `<n> + 1 → <n> + 1` | `gram <- curvature <- matrix(0, k, k)` | Textgleich mit r3:348. Die Doppelschleife schreibt jedes Element vor dem ersten Lesen; identisch auf 26 Eingaben. |
| `R/fit.R:352` | `<n> - 1 → <n> - 1` | wie oben | wie oben |
| `R/fit.R:453` | `TRUE → FALSE` | `lme4::lFormula(form, data = scaled, REML = TRUE, …)` | Textgleich mit r3:449. Genutzt wird nur `reTrms` (Z. 454, 456, 457, 466); identisch auf 26 Eingaben. |
| `R/fit.R:455` | `TRUE → FALSE` | `strsplit(names, ":", fixed = TRUE)` | Textgleich mit r3:451; identisch auf 26 Eingaben. |
| `R/fit.R:461` | `TRUE → FALSE` | `on.exit(…, add = TRUE)` | Textgleich mit r3:457. Es bleibt das einzige `on.exit` in `msa_numeric_fit()`; der neue Handler in Z. 471–482 registriert keines. Identisch auf 26 Eingaben, auch auf den Fehlerwegen mit Startwarnungen. |
| `R/grr.R:94` | `> → >=` | `… else if (grr_v > 0) … else Inf` | `R/grr.R` ist blob-gleich; die Freigabe der Runde 3 trifft weiter. |
| `R/fit.R:267` | `<n> + 1 → <n> + 1` (`counts[1]` → `counts[2]`) | `if (length(counts) != prod(sizes) \|\| any(counts != counts[1])) {` | Neu beantragt. Der einzige Produktaufrufer ist `msa_numeric_fit()` (Z. 458). Dort steht `item` immer mit mindestens zwei Stufen in `factors`, denn `msa_fit()` verlangt `(1 \| item)` (Z. 180–183); also gilt `prod(sizes)` ≥ 2. Nach dem Kurzschluss ist `length(counts)` = `prod(sizes)` ≥ 2, und „alle gleich `counts[1]`“ ist gleichwertig mit „alle gleich `counts[2]`“. Geprüft: das Prädikat auf allen 5456 Vektoren der Längen 2–6 mit Einträgen 1–4; Hilfsfunktion und `msa_fit()` Ende-zu-Ende identisch auf 35 Eingaben, darunter Einweg-, Zwei-Item- und unbalancierte Pläne. |
| `R/fit.R:267` | `x[<i>] → x[<i> + 1L]` (`counts[1 + 1L]`) | wie oben | wie oben |

- **Wirkung:**
  - Mit der Zuordnungslogik des Gates nachgerechnet: Die Freigaben treffen genau diese zwölf Überlebenden.
  - Auf den Bericht der Runde 4 angewandt ergäbe sich 973 / (973 + 66 − 12) = 94,74. Mit den alten Approvals sind es 93,74, ohne Approval 93,65.
  - `mut-baseline` schreibt nur das Gate.
- **Bindung an den Stand:**
  - Die Freigaben gelten für `4f0547b` (`R/fit.R` SHA-256 `73caf980…`, `R/grr.R` `c468f439…`).
  - Verschiebt der Rework zu E54 Zeilen, etwa durch einen Satz im roxygen-Kopf von `?msa_fit`, beantragt der Builder die betroffenen Äquivalenzen in `MUT-EQUIV.json` mit den neuen Zeilen neu. Das nächste Review gleicht jede Freigabe mit dem neuen Bericht ab (BL-85).

## Verdict

**REWORK.**

- `gates.json` meldet `result: pass`. `blocking` ist aber nicht leer: E54 mit Bezug auf ADR-022 Nr. 6.2, docs/01 §2 Nr. 4, ADR-018 Nr. 3 und `?msa_fit`.
- Nonblocking: E55 und E56.
  - BACKLOG: BL-89 neu; BL-88 gestrichen;
  - neuer Stand in BL-13, BL-84, BL-85, BL-86 und BL-87.
- Kein Spec-Widerspruch. E54 braucht keine neue Auslegung; ADR-022 Nr. 6.2 deckt den Fall.

## Geschriebene Dateien

- `orchestrator/handoff/M1a/REVIEW.md` (diese Datei);
- `orchestrator/handoff/M1a/verdict-code.json` (`round: 4`);
- `orchestrator/handoff/M1a/MUT-EQUIV-APPROVED.json` (zehn Freigaben auf den Zeilen von `4f0547b`);
- `BACKLOG.md`: BL-89 neu; BL-88 erledigt; neuer Stand in BL-13, BL-84, BL-85, BL-86 und BL-87.

Keine Git-Kommandos. Ich habe weder Produktcode noch Tests, Gates oder Orchestrator-Zustand geändert.
