# ADR-027 — Auslegungen des Reviewers im Code-Review M1b, Runde 1: `...` bei ordinalen und binären Fits, `singular` und Identifizierbarkeit bei Zwei-Stufen-Faktoren, `levels`, Integrität der Klasse-B-Dateien, Invarianzbeleg latenter Fits, Testumgebung

## Status

Angenommen (Reviewer, `50-code-review` M1b, Runde 1, 31.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“).

- Ergänzt ADR-023 und ADR-025; beide gelten unverändert weiter.
- Ändert keinen Abnahmetest, keinen QA-Test, keinen Anker und keine Toleranz.
- Einwände: E12 bis E17 und E20 in `orchestrator/handoff/M1b/REVIEW.md` (Runde 1).

## Kontext

- **QA-Befunde.** QA hat sechs Befunde mit reproduzierenden Tests geliefert (`orchestrator/handoff/M1b/QA.md`, QA-M1b-001 bis -006).
  - Alle sechs Tests sind im Gate tests rot (`gate-tests.log` Z. 958–1070 und 1090–1183).
  - Zusammen mit `tests/testthat/test-validation-latent.R` halten sie den unmutierten Vorlauf von mutgate rot (`gate-mutgate.log` Z. 3–11).
  - QA-Tests laufen in jeder weiteren Gate-Runde mit. Ein roter QA-Test hält das Gate rot, bis der Produktcode ihn erfüllt. Dieses Review hat deshalb jede QA-Erwartung einzeln gegen Spec, Dokumentation und Plan geprüft. Keine widerspricht einer Spec-Stelle. Wo die Spec schweigt, legt dieses ADR die Auslegung fest.
- **Prüfläufe des Reviewers** (31.10.2026; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26; Daten wie `tests/e2e/test-m1b-qa-e2e.R`, Seed 20261031):
  - Zwei Blöcke mit identischen Antworten: `fit$singular` ist TRUE. Die Zufallseffekte liegen bei item 0,898 und prompt 0,972, die abgeleitete Komponente block bei 7,8e-14.
  - Modell und Block konfundiert: `clmm` meldet nur als Message „design is column rank deficient so dropping 1 coef“. `model$beta` enthält nur `modelM2`, und `fit$vc` nennt block mit der Varianz 0.
- **Dokumentierte Zusagen.**
  - `?msa_fit`, `@param ...` (`R/fit.R:47–50`): „Expressions in `subset`, `weights` and `offset` can use the internal columns `item`, `prompt`, `model`, `block` and `y`. Row-based arguments refer to the rows remaining after missing or unreadable responses are removed.“
  - `R/fit.R:104–105`: „All returned data and study counts describe the retained observations.“
  - `?msa_boot` (`R/grr.R:141`, `:153–154`): „Available for numeric and binary outcomes (lme4 models).“ und „An explicit fitting control passed to [msa_fit()] remains the model's refit control.“
  - Umgesetzt ist das nur im numerischen Zweig (`R/fit.R:241–259`). Der ordinale und der binäre Zweig reichen `...` unausgewertet an die Engine (`R/fit.R:261–264`). Das ist Bestand aus v0.1.0, liegt aber im Gegenstand von M1b.
- **Invarianz.** ADR-026 Nr. 8 und `PROGRESS.md` (M1B-NUM-01) melden für die Vorgabe-Optimierer von `clmm` und `glmer` Abweichungen bis 8,1e-6 · σ²_TV.
  - Gemessen wurden Zeilenumkehr, Umbenennen der Stufen und Ereignistausch; ANK-TOL.invariance ist 1e-6 · σ²_TV.
  - Mit expliziter Steuerung (glmer: bobyqa auf beiden Stufen mit `rhoend` = ANK-TOL.engine_boot.tol; clmm: ucminf mit einem Zufallsterm) liegen sie darunter.
  - K-M1b-1 und K-M1b-5 verlangen dagegen Gleichheit mit den Vorgabeaufrufen von `clmm` und `glmer`.
- **Rework-Auftrag.** `orchestrator/prompts/60-rework.md` verlangt, Befunde am Produktcode zu beheben, „niemals an Tests“. QA-M1b-004 liegt aber in einem Unit-Test des Builders. Er bricht in der Paketkopie des Mutationslaufs vor seinen Erwartungen ab, weil er `vignettes/validation.Rmd` nicht über `REPO_ROOT` sucht (`tests/testthat/test-validation-latent.R:129–132`).

## Entscheidung

1. **(QA-M1b-001, -002) `...` bei `type = "ordinal"` und `type = "binary"`.** Es gelten dieselben Zusagen wie im numerischen Durchreichweg.
   1. Ausdrücke in `subset`, `weights` und `offset` werden in der Datenmaske der internen Spalten ausgewertet. Umschließende Umgebung ist der unmittelbare Aufrufer von `msa_fit()`. Zeilenargumente beziehen sich auf die Zeilen nach dem Verwerfen fehlender und nicht lesbarer Antworten.
   2. `data`, alle Zählungen in `n`, `nobs(model)`, die Stufen in `data`, `formula` und `derived` beschreiben dieselben analysierten Zeilen.
      - Die Regeln „eine Stufe → entfernt“ (K-M1b-6) und „zwei Stufen → fest“ (K-M1b-4) gelten für die analysierten Zeilen.
      - Empfohlen: die Zeilenauswahl vor dem Formelaufbau anwenden und `weights` und `offset` mit ihr ausrichten.
   3. Der im Modell gespeicherte Aufruf enthält ausgewertete Argumente, keine Platzhalter wie `..1`. So laufen `lme4::refit()`, `lme4::bootMer()` und `msa_boot()` auch außerhalb des Aufrufrahmens mit der übergebenen Steuerung. Dasselbe gilt für den gespeicherten Aufruf von `clmm`.
2. **(QA-M1b-003 Nr. 1) `singular` bei ordinalen Fits.**
   - `singular` meldet eine Zufallseffekt-Komponente am Rand null, wie `lme4::isSingular()` bei `glmer`.
   - Abgeleitete Komponenten (β̂²/2, `attr(vc, "derived")`) entscheiden nicht: β̂ ist ein innerer Parameter ohne Rand bei null.
   - Die bestehende Schwelle des ordinalen Zweigs (`R/fit.R:301`) bleibt; es entsteht keine neue Konstante.
   - ADR-023 Nr. 10.6 bleibt: Schätzt `clmm` die Prompt-Varianz exakt 0, ist `singular` TRUE.
3. **(QA-M1b-003 Nr. 2 und 3) Identifizierbarkeit.** Vor dem ordinalen Fit enden mit einer benannten Fehlermeldung (docs/01 §2 Nr. 4: „Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“):
   1. Zwei-Stufen-Faktoren, deren fester Teil keinen vollen Spaltenrang hat, etwa konfundierte Modelle und Blöcke. Die Meldung nennt die Faktoren und die fehlende Identifizierbarkeit. Für einen verworfenen Koeffizienten entsteht nie die Varianz 0.
   2. jeder Zufallsterm, den `clmm` nicht schätzen kann, also mit höchstens zwei beobachteten Stufen, etwa die Wechselwirkung zweier konfundierter Zwei-Stufen-Faktoren. Die rohe Assertion „all(sapply(gfl, nlevels) > 2) is not TRUE“ erreicht den Aufrufer nie.

   Das gilt als Klasse für alle Zufallsterme und alle Zwei-Stufen-Faktoren (`orchestrator/LESSONS.md`).
4. **(QA-M1b-005) `levels`.**
   1. **Ordinal:** `levels` besteht aus mindestens zwei verschiedenen, nicht fehlenden und nicht leeren Labels. Sonst endet der Fit vor jeder Datenprüfung mit einem benannten Fehler, dessen Meldung „levels“ enthält; das ersetzt auch den R-internen Fehler „factor level [3] is duplicated“. Die bestehende Meldung bei fehlendem `levels` bleibt.
   2. **Binär, Argument:** Die bestehende Prüfung bleibt: genau zwei verschiedene, nicht fehlende Labels, Meldung mit „two distinct, non-missing labels“ (`tests/testthat/test-fit-latent.R:11–13` prüft sie). Leere Labels werden ebenso benannt abgewiesen.
   3. **Binär mit `levels`:** Allein die Labels bestimmen die Kodierung, unabhängig vom Speichertyp von `value` (Vergleich über `as.character()`).
      - `levels[1]` wird 0, `levels[2]` wird 1.
      - Andere Werte werden nach K-M1b-6 mit Warnung verworfen und gezählt.
      - Ohne `levels` gilt K-M1b-6 unverändert: numerische oder logische Werte und numerisch lesbare Zeichen außerhalb {0, 1} enden mit einem Fehler, dessen Meldung „binary“ enthält.
      - Grundlage: `?msa_fit` („Labels require this explicit argument“), PLAN-UPDATE, Schnittstellen („Bei Labels bestimmt allein das validierte Argument `levels` die Kodierung“) und die Invarianz gegenüber dem Speichertyp.
5. **(QA-M1b-006) Integrität der Klasse-B-Dateien.**
   1. **`sim_merge()`** prüft je Replikatzeile die Designspalten gegen das Szenario.
      - `items`, `prompts`, `models` und `blocks` gleichen der Tabelle in docs/02; `observations` gleicht Items × Prompts × Modelle × Replikate × Blöcke.
      - `NA` ist nur zulässig, wenn `estimate` NA ist (ADR-023 Nr. 4.4).
      - `converged` ist logisch und nie NA. `singular` ist logisch und nur ohne Fit NA.
      - Abweichungen enden benannt.
   2. **`latent_read_results()`** weist zusätzlich ab: `value` < 0 bei `empse` und `rmse`, `derived_share` außerhalb [0, 1] sowie einen `seed`, der nicht ganzzahlig, kleiner als 1 oder größer als `.Machine$integer.max` ist.
   3. Grundlage: ADR-026 Nr. 5 („gültige Seeds und Kennzahlen“), PLAN-UPDATE („Eine vorhandene fehlerhafte Datei führt zum benannten Fehler.“), ADR-023 Nr. 2.3 und Nr. 4.4.
6. **(ADR-026 Nr. 8, M1B-NUM-01) Invarianzbeleg latenter Fits (docs/01 §2 Nr. 5).**
   - Für `clmm` und `glmer` ist der Beleg mit ausdrücklich engerer Engine-Steuerung über `...` zulässig. Die Toleranz bleibt ANK-TOL.invariance, und der Optimierer muss nach `converged` erfolgreich sein.
   - Der Vorgabepfad bleibt gleich den Vorgabeaufrufen der Engines (K-M1b-1, K-M1b-5). Vorgabe-Optimierer werden dafür nicht verändert.
   - Die gemessenen Abweichungen der Vorgabepfade (bis 8,1e-6 · σ²_TV) sind Optimierertoleranz der Engines, kein Kodierungs- oder Permutationsfehler des Pakets.
   - `?msa_fit` soll diese Grenze nennen (nonblocking, E20). Es gibt keinen neuen Anker und keine Toleranzänderung.
7. **(QA-M1b-004) Testumgebung von Builder-Tests.**
   - Bricht ein Unit-Test des Builders unter `tests/testthat/` in einer Gate-Umgebung vor seinen Erwartungen ab, ist das ein Defekt im Builder-Territorium. Hier fehlt `vignettes/` in der Paketkopie des Mutationslaufs, obwohl `REPO_ROOT` gesetzt ist.
   - Behoben wird er, indem die Testumgebung aufgelöst wird, etwa der Pfad zu `validation.Rmd` über `REPO_ROOT` wie in `tests/testthat/test-validation-numeric.R:236–238` (`validation_find_repo()`, sonst `system.file("doc", …)`).
   - Erwartungen, geprüfte Quellen, Literalprüfung und Toleranzen bleiben unverändert.
   - Das ist keine Behebung „an Tests“ im Sinn von `orchestrator/prompts/60-rework.md`: Kein rotes Ergebnis wird durch Abschwächen grün.
   - Festgehalten als Projekt-Amendment in `IMPLEMENTATION-RULES.md`.

## Konsequenzen

- **Builder (REWORK M1b, Runde 2):**
  - setzt Nr. 1 bis 5 und 7 um, im Produktcode, unter `inst/validation/` und im genannten Test;
  - belegt sie mit Unit-Tests gegen unabhängige Referenzen: direkter Engine-Aufruf auf den ausgewählten Zeilen, `lme4::bootMer()` auf dem gespeicherten Modell, Rang des festen Designs;
  - erzeugt danach die neun `_check_`-Dateien mit dem Paketstand neu, der in die Gates geht (ADR-023 Nr. 1.5).
- **Code-Review:** prüft Nr. 1 bis 7 als Vertrag. Eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-027.
- **QA-Tests:** bleiben unverändert; nach dieser Auslegung sind sie erfüllbar.
- **Rücknahme:** nur per Reviewer-ADR.
