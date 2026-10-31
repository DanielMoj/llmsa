# ADR-025 — Auslegungen des Reviewers zu M1b nach ADR-024: K-M1b-5-Teil von K-M1b-7, Feld `converged`, Rückfallorakel der AP1-Abnahme

## Status

Angenommen (Reviewer, `30-plan-review` M1b, Runde 2, 31.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 und 2 ersetzen ADR-023 Nr. 11.4 und 11.7. Sie halten die Auslegung fest, die `orchestrator/handoff/M1b/CRITERIA.json` als ACC-18 führt. ACC-18 und `ARBITER.md` (Runde 1, Direktive Nr. 5) kündigen dieses ADR für `30-plan-review` Runde 2 an.
- Nr. 3 präzisiert ADR-023 Nr. 10.9 für numerische Fits und für die Bestimmung des tatsächlich verwendeten `clmm`-Optimierers, wie `PLAN-UPDATE.md` (Runde 2) sie vorschlägt.
- Nr. 4 richtet das Rückfallorakel der Abnahmetests zu K-M2-6 und K-M2-7 an K-M2-6, ANK-68 und ADR-006 Nr. 4.2 aus (Einwände E9 und E10 in `PLAN-REVIEW.md` M1b, Runde 2).
- Alle übrigen Nummern von ADR-023 gelten unverändert. Zu Skala und Referenzwerten der binären ICC_items entscheidet dieses ADR nichts neu (ADR-024 Nr. 1; ARBITER.md, Direktive Nr. 6).

## Kontext

- **K-M1b-5 nach ADR-024.** Der Betreiber hat K-M1b-5 neu gefasst (docs/02 Z. 43; ADR-024 Nr. 1).
  - Die wiederholte Abnahmephase hat `tests/acceptance/test-m1b-5-binary-rptr.R` angepasst (ADR-024 Nr. 2) und den K-M1b-5-Teil von `tests/acceptance/test-m1b-7-vignette.R` nach ACC-18 gefasst.
  - `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh:486`). ADR-023 (Konsequenzen) verlangt für diese Änderung „ein eigenes ADR“.
- **Numerische Fits und `clmm`.** ADR-023 Nr. 10.9 überließ die Regel für numerische Fits dem PLAN-UPDATE; PLAN-UPDATE Runde 2 nennt sie. Gemessen am 31.10.2026 (PLAN-REVIEW Runde 2, Prüfläufe 1 und 2; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26):
  - Der numerische Vorgabepfad baut das Modell mit `opt$conv = 0L` und `lme4conv = lme4::checkConv(...)` auf den analytischen Ableitungen (`R/fit.R:531–542`). Ein regulärer Fit hat `optinfo$conv$opt` = 0 ohne Meldung; ein Randfit vermerkt nur „boundary (singular) fit: see help('isSingular')“.
  - lme4 bildet Erfolg auf den Code 0 ab (`nloptwrap`: `conv = if (status < 0 || status == 5) status else 0`). Ein abgebrochener direkter `lmer`-Fit hat `conv$opt` = 5 und vermerkte checkConv-Meldungen.
  - `ordinal::clmm` nutzt den angeforderten Optimierer nur bei genau einem einfachen Zufallsterm ohne `useMatrix` (`use.ssr <- (retrms$ssr && !control$useMatrix)`, dann `clmm.fit.ssr`). Sonst rechnet `clmm.fit.env` immer mit nlminb und warnt bei angefordertem ucminf „cannot use ucminf optimizer for this model, using nlminb instead“. Vorgabe ist `method = "nlminb"`.
- **AP1-Abnahme.** K-M2-6 verlangt den numerischen Rückfall, „wenn dieser Fit mit Fehler oder Konvergenzwarnung endet“ (docs/03 Z. 19). ANK-68 nennt als Auslöser „Fehler oder Konvergenzwarnung des ordinalen Fits“.
  - ADR-006 Nr. 4.2 bestimmt, was eine Konvergenzwarnung ist: „Alle Warnungen des ordinalen Fits, auslösende wie andere, bleiben im Ergebnis erhalten“. `acmg_fit()` folgt dem (`R/acmg.R:926–957`).
  - Das Orakel der Abnahmetests ist weiter gefasst. `acc_m2_with_conditions()` setzt `failed` bei jedem Fehler und bei jeder Warnung (`tests/acceptance/setup-m2.R:714`). Bei `failed` verlangen `acc_m2_check_model()` (Z. 869–883) und `test-m2-6-evaluate.R` (Z. 101–107) den numerischen Rückfall.
  - Bis M1b blieb das folgenlos, weil der ordinale Fit auf den AP1-Daten keine Warnung ausgab.
  - Der AP1-Hauptplan hat zwei Blöcke (docs/03 Z. 67). Die Mock-Daten der Abnahme enthalten fehlende Antworten: im Hauptplan 96, je Modell 30, 36 und 30, im konstruierten Fall je Modell 100.
  - K-M1b-4 verlangt bei jedem ordinalen Fit mit Zwei-Stufen-Faktor „immer eine `warning()`“, K-M1b-6 eine Warnung beim Verwerfen fehlender Antworten. Keine der beiden ist eine Konvergenzwarnung.
  - Gegenprobe (PLAN-REVIEW Runde 2, Prüflauf 5): Mit den geplanten Warnungen erwartet das Orakel für alle drei Modelle und für den gemeinsamen Fit den Rückfall. `acmg_fit()` behält spec-gemäß den ordinalen Fit.
  - Rot würden `test-m2-6-evaluate.R` Z. 87, 93 und 164 sowie `test-m2-7-robustness-pilot.R` Z. 211.

## Entscheidung

1. **(ACC-18; ersetzt ADR-023 Nr. 11.4) Prüfungen aus K-M1b-5 im Abschnitt „Ordinal and binary outcomes (latent scale)“.**
   1. Der Abschnitt nennt ANK-25, ANK-28 und ANK-TOL.rptr. Die Einträge `ANK-TOL.rptr.live_tol` und `ANK-TOL.rptr.vignette_tol` erfüllen die Teilzeichenkette ANK-TOL.rptr.
   2. **Prüfung der ICC_items.**
      - Der Abschnitt zeigt die beobachtete ICC_items von `msa_fit(type = "binary", link = "logit")` und `msa_grr()` auf BeetlesMale (Abbildung nach ADR-023 Nr. 12), auf die gezeigte Stellenzahl.
      - Ihre drei Vergleichsgrößen rechnet die Vignette zur Laufzeit: `rptR::rptBinary(…, link = "logit", expect = "liability")` (R_link), `performance::icc()` auf demselben `glmer`-Modell und σ²_Population/(σ²_Population + π²/3) mit ANK-28.
      - Verglichen wird ungerundet mit `ANK-TOL.rptr.live_tol`. Der Abnahmetest verlangt die Anzeige der Vergleichsgrößen nicht getrennt, weil sie der ICC_items innerhalb dieser Toleranz gleichen.
   3. **Installationsprüfung.** Der Abschnitt zeigt beide in der rptR-Vignette publizierten Punktschätzer aus ANK-25 (`link_scale`, `original_scale`) neben den Punktschätzern R_link und R_org des Vorgabeaufrufs `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")`, Toleranz `ANK-TOL.rptr.vignette_tol`. Ebenso zeigt der K-M1b-1-Teil beide Varianzen aus ANK-21 (ADR-023 Nr. 11.3).
   4. **Trennung.** Die Werte aus ANK-25 stehen nur in der Installationsprüfung.
      - Keine Zeile, Spalte oder Aussage stellt ICC_items einem Wert aus ANK-25 gegenüber oder nennt ihn Referenz- oder Erwartungswert der ICC_items.
      - Grundlage: K-M1b-5 („diese rechnen mit der Beobachtungsvarianz 1/(p(1 − p)) und sind kein Referenzwert für ICC_items“) und ARBITER.md, Direktive Nr. 4.
      - Der Abnahmetest prüft die Trennung nicht; das Code-Review prüft sie (CRITERIA.json ACC-18).
   5. rptR läuft mit `nboot = 0` und `npermut = 0` (ADR-023 Nr. 12).
2. **(ACC-18; ersetzt ADR-023 Nr. 11.7) Literalregel.**
   1. Im Rmd-Text steht kein Zahlenliteral mit mindestens drei signifikanten Stellen, das einem der folgenden Werte gleicht oder auf seine geschriebenen Stellen rundet:
      - einem `value` oder `mcse` der gelesenen Ergebnisdateien;
      - einem Wert aus ANK-21 (`laplace`, `nagq10`) oder ANK-25 (`link_scale`, `original_scale`);
      - dem Logit-Wert von ANK-28.
   2. Ein Ausdruck wie `pi^2 / 3` ist kein Literal in diesem Sinn.
   3. Der Abnahmetest prüft den Rmd-Text. PLAN-UPDATE erstreckt die Regel auf Inline-R und ausgelagerte Helfer; das bindet als Vertrag des Builders, und das Code-Review prüft es.
3. **(präzisiert ADR-023 Nr. 10.9) Feld `converged`.**
   1. **Numerische Fits, beide Pfade.** `converged` ist TRUE genau dann, wenn `model@optinfo$conv$opt` gleich 0 ist und `model@optinfo$conv$lme4$messages` keine andere Meldung enthält als die Randmeldung „boundary (singular) fit: see help('isSingular')“.
      - Fehlt der Code oder ist er nicht als Zahl lesbar, ist `converged` FALSE, nie `NA`.
      - Startdiagnosen (`numerics$start`, auch `start$convergence` und gespeicherte Startwarnungen) entscheiden nicht.
      - Eine finale checkConv-Meldung zu Gradient oder Hessematrix ergibt FALSE, auch nach erfolgreichem analytischem Abschluss. Die Hilfe von `msa_fit()` nennt das.
      - Der numerische Pfad gibt keine zusätzliche Warnung aus; lme4 und checkConv geben ihre Warnungen weiter (K-M1a-6). ADR-018, ADR-020 und ADR-022 bleiben unverändert.
   2. **`clmm`: tatsächlich verwendeter Optimierer.**
      - Er folgt aus dem Rechenweg von `ordinal::clmm` (siehe Kontext), nicht aus dem Warnungstext und nicht aus `control$method` allein.
      - Die Erfolgscodes bleiben nach ADR-023 Nr. 10.9: nlminb 0, ucminf 1 und 2.
      - Unit-Tests belegen beide Wege an echten Fits: ein Zufallsterm mit ucminf; mehrere Terme oder `useMatrix = TRUE` mit nlminb.
   3. Für `glmer`, Singularität und Range-Warnung gilt ADR-023 Nr. 10.9 unverändert.
4. **(K-M2-6, K-M2-7; ADR-006 Nr. 4.2) Rückfallorakel der Abnahmetests.**
   1. Das betrifft das Orakel von `acc_m2_check_model()` (`tests/acceptance/setup-m2.R`) und den gemeinsamen Fit in `test-m2-6-evaluate.R`. Dort endet der ordinale Fit „mit Fehler oder Konvergenzwarnung“ genau dann, wenn er einen Fehler wirft oder eine Warnung ausgibt, deren Meldung nach ADR-006 Nr. 4.2 eine Konvergenzwarnung ist.
      - Maßgeblich sind die Teile „converge“, „Hessian“, „max|grad“, „gradient“ und „unidentifiable“, ohne Rücksicht auf Groß- und Kleinschreibung.
      - Die bloße Optimiererumstellung zählt nicht.
   2. Andere Warnungen lösen keinen Rückfall aus. Gibt der ordinale Fit nur solche aus, etwa die Range-Warnung (K-M1b-4) oder die Verwerfungswarnung (K-M1b-6), verlangt das Orakel den ordinalen Fit, wie bisher bei einem Fit ohne Warnung.
   3. Die Regel steht im Test unabhängig vom Produktcode, also ohne Aufruf von `llmsa:::acmg_convergence_warning()`.
      - Alle übrigen Erwartungen von K-M2-6 und K-M2-7 bleiben unverändert.
      - Das gilt auch für den Test mit erzwungenem Fehler und erzwungener Konvergenzwarnung (`test-m2-6-evaluate.R` Z. 110–135).
   4. Umsetzung durch den Reviewer in `50-code-review` M1b Runde 1, oder früher, falls der Betreiber eine wiederholte Abnahmephase anordnet (wie in ADR-024 Nr. 2). `30-plan-review` darf `tests/acceptance/` nicht schreiben (`orchestrate.sh:488`).
   5. Der Builder ändert dafür weder `acmg_fit()` noch `acmg_convergence_warning()` und unterdrückt oder bedingt keine der verlangten Warnungen.

## Konsequenzen

- **Builder (BUILD M1b):** setzt Nr. 1 bis 3 um.
  - Rote Prüfungen von K-M2-6 und K-M2-7, deren einzige Ursache Nr. 4 ist, meldet er mit echtem Output in `PROGRESS.md` als [INFRA]. Erkennbar sind sie daran, dass das Orakel den Rückfall verlangt, `acmg_fit()` den ordinalen Fit behält und der ordinale Fit nur Range- oder Verwerfungswarnungen ausgibt.
  - Jede andere Abweichung in K-M2-6 oder K-M2-7 bleibt ein Befund gegen den Builder.
- **Code-Review M1b:**
  - Es prüft Nr. 1 bis 3 als Vertrag; eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-025.
  - Es setzt Nr. 4 um, sofern das noch nicht geschehen ist, und prüft dabei, dass sich nur die Rückfallbedingung des Orakels ändert.
  - Den BACKLOG-Eintrag zu Nr. 4 schreibt es; in `30-plan-review` ist `BACKLOG.md` nicht freigegeben.
- **Abnahmetests:** `test-m1b-5-binary-rptr.R` und `test-m1b-7-vignette.R` folgen Nr. 1 und 2 bereits (wiederholte Abnahmephase vom 31.10.2026; CRITERIA.json ACC-1 und ACC-18); dieses ADR ist ihr Beleg nach ADR-023 (Konsequenzen). Die Änderung nach Nr. 4 steht aus.
- **Gates:**
  - Bis Nr. 4 umgesetzt ist, ist das tests-Gate nach einem spec-treuen BUILD rot.
  - Der Prompt von `50-code-review` erlaubt „PASS nur bei gates.result=pass“. Ohne frühere Umsetzung kostet das eine Rework-Runde.
  - mutgate ist nicht betroffen: `MUT_TEST_EXCLUDE` schließt `m2-[0-9]` aus (`orchestrator/config.env:202`).
- **Rücknahme:** nur per Reviewer-ADR.
