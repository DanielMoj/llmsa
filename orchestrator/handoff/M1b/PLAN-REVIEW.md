# PLAN-REVIEW — M1b, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 (von `MAX_ROUNDS_PLAN=2`) · Stand: 31.10.2026 · Gegenstand: `orchestrator/handoff/M1b/PLAN.md` (Runde 1). Eine `ARBITER.md` und eine `PLAN-UPDATE.md` gibt es nicht. Keine Git-Kommandos.

## Ergebnis

**Verdict ESCALATE.**

- **Grund ist allein E1:** K-M1b-5 widerspricht wörtlich docs/01 §5 und Formelsammlung §4 (CRITERIA ACC-1). Builder und Reviewer dürfen diesen Widerspruch nicht auflösen (AGENTS.md: „Widersprüchliche Specs führen zu `ESCALATE`“; docs/01 §1: „Änderungen am Spec-Text nur durch den Betreiber“).
- **Der übrige Plan** ist spec-treu, vollständig und gut belegt. Alle anderen Befunde sind minor oder [INFRA]; PLAN-UPDATE beantwortet sie in Runde 2.
- **Neu in dieser Phase:** `docs/decisions/ADR-023-m1b-reviewer-auslegungen.md`. Es hält die in CRITERIA angekündigten Auslegungen ACC-2 bis ACC-11 und ACC-14 fest, regelt das Feld `converged` (E2) und entscheidet PLAN-M1b-SIM-01.
- **Ablauf:** Bei ESCALATE ruft der Orchestrator den Arbiter (`orchestrate.sh:926–927`), den es je Meilenstein nur einmal gibt (`:804–807`).
  - Löst der Arbiter auf (RESOLVE), muss Runde 2 mit PASS enden. Sonst ist der Arbiter verbraucht, und M1b wird geparkt.
  - Weder `30-plan-review` noch `70-arbiter` dürfen `tests/acceptance/` schreiben (`orchestrate.sh:488`, `:491`).

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`.
- **Spezifikation:**
  - `docs/02-statistikkern.md`: M1b vollständig (Szenariotabelle, Schätzziele, K-M1b-1 bis K-M1b-7) und die Folgestellen K-M1d-6 und K-M1d-7;
  - `docs/01-fachspezifikation.md` §1 bis §9;
  - Formelsammlung §3, §4, §9 und §12.
- **Handoff:** `CRITERIA.json` (sieben Kriterien, ACC-1 bis ACC-17), `PLAN.md` vollständig (661 Zeilen).
- **Abnahmetests:** `setup-m1b.R`, die acht Dateien `test-m1b-*.R` und, für den AP1-Rückfall, `test-m2-6-evaluate.R`.
- **Anker:** ANK-06, ANK-21, ANK-25, ANK-28 und die betroffenen Einträge von ANK-TOL (`engine_ordinal`, `rptr`, `n_check`, `sim_runtime`, `arithmetic`, `mc_factor`, `bias_report`, `package_compare`, `oracle`).
- **ADRs:** ADR-017 (Format), ADR-021 (Ankerkopien), ADR-022 Nr. 2 und 3.
- **Produktcode:** `R/fit.R` (`msa_fit`, `vc_from_model`, `print.msa_fit`), `R/grr.R` vollständig, `R/acmg.R:917–957`, `DESCRIPTION`.
- **Harness und Backlog:**
  - `BACKLOG.md` (Inventur, Prüflauf 5);
  - `orchestrate.sh`: `path_allowed`, `ownership_check`, `verdict`, Planschleife, `arbiter`, `park`;
  - die Prompts `30-plan-review.md` und `70-arbiter.md`;
  - `config.env` (nur die Zeilen 138–203, die Pfade, Tests und Mutation betreffen);
  - `lib/r-mutation.R` (Zeitlimit je Mutant).

## Eigene Prüfläufe

Alle Läufe am 31.10.2026 mit `Rscript --vanilla -e …` aus der Repo-Wurzel, ohne geschriebene Datei; ausgeführt wurden die Befehle, gezeigt ist ihr echter Output.

1. **ACC-1 nachgerechnet.** Aufrufe:
   - `glmer(Colour ~ (1 | Population), BeetlesMale, binomial("logit"))`;
   - `rptR::rptBinary(…, link = "logit", nboot = 0, npermut = 0)`, einmal mit Vorgabe und einmal mit `expect = "liability"`;
   - `performance::icc(m)`;
   - die Formel σ²/(σ² + π²/3);
   - Auszug aus `deparse(rptR::rptBinary)` zu `estdv_link`.

   ```text
   versions: R 4.6.1 lme4 2.0.6 rptR 0.9.23 performance 0.19.0
   sigma2_Population = 0.945803710351675
   rptBinary default R_link = 0.187930859738746  R_org = 0.18539884541501
   rptBinary liability R_link = 0.223294850303547
   performance::icc ICC_adjusted = 0.223294850303548
   sigma2/(sigma2+pi^2/3) = 0.223294850303547
   formals expect: "meanobs"
               if (expect == "meanobs")
                   estdv_link <- 1/(Ep * (1 - Ep))
               if (expect == "liability")
                   estdv_link <- pi^2/3
   ```
2. **Variante B gegengeprüft:** `performance::icc(m, approximation = a)` auf demselben Modell.

   ```text
   approximation = lognormal : 0.223294850303548
   approximation = delta : 0.223294850303548
   approximation = trigamma : 0.223294850303548
   approximation = observation_level : 0.187526014414148
   ```
3. **Konvergenzcodes der Engines.** Aufrufe:
   - `clmm` auf wine mit `(1 | bottle) + (1 | judge)`, einmal mit `method = "nlminb"` und einmal mit `method = "ucminf"`;
   - `clmm` mit nur `(1 | judge)`, mit `ucminf` und mit der Vorgabe;
   - ein singulärer `glmer` mit `(1 | item) + (1 | prompt) + (1 | model)` (Seed 1).

   ```text
   nlminb : optRes$convergence = 0 ; message = relative convergence (4) ; var = 1.210133696 2.749610704
     warning: cannot use ucminf optimizer for this model, using nlminb instead
   ucminf : optRes$convergence = 0 ; message = relative convergence (4) ; var = 1.210133696 2.749610704
   glmer singular: TRUE ; conv$opt = 0 ; recorded lme4 messages: boundary (singular) fit: see help('isSingular') ; emitted messages: boundary (singular) fit: see help('isSingular')
   ucminf single term: optRes$convergence = 1 ; message = Stopped by small gradient (grtol). ; var judge = 0.3193604702
   nlminb single term: optRes$convergence = 0 ; var judge = 0.3193604229
   ```
4. **`?ucminf::ucminf`, Rückgabewert `convergence`:** „1 Stopped by small gradient (grtol). 2 Stopped by small step (xtol). 3 Stopped by function evaluation limit (maxeval). 4 Stopped by zero step from line search“.
5. **BACKLOG-Inventur** gegen die Tabelle des Plans:

   ```text
   total 89  open 67  done 22
   plan rows: 66
   open but not in plan table: BL-38
   in plan table but done:
   in plan but unknown:
   ```

   BL-38 hat keine Fettmarke „**Erledigt**“, nennt sich aber im Text selbst erledigt: „`verdict()` prüfte die Runde nicht; behoben in v1.1.1 | erledigt, Hinweis für Logs“. Der Plan führt ihn zu Recht unter „bereits erledigt“. Damit sind alle offenen Einträge adressiert oder mit Begründung vertagt.
6. **`config.env`:**
   - Zeile 138: `BUILDER_EXTRA_PATHS_REGEX='^(R/|man/|tests/testthat/|vignettes/|inst/|data/|data-raw/|DESCRIPTION$|NAMESPACE$|NEWS\.md$|\.Rbuildignore$)'`;
   - Zeile 178: `MUT_TEST_DIRS='tests/testthat tests/acceptance tests/e2e tests/fuzz'`;
   - Zeile 202: `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$)'`;
   - Zeile 203: `MUT_TEST_TIMEOUT=353`.

   `lib/r-mutation.R:53` setzt `MUT_TEST_TIMEOUT_FACTOR` auf die Vorgabe 5 (Grenze mindestens das Fünffache des unmutierten Vorlaufs).
7. **ACC-15 im Orchestrator unverändert:**
   - `orchestrate.sh:543`: `[ "$before" != __clean__ ] || OWNERSHIP_REMOVE+=("$path")`;
   - `orchestrate.sh:456`: `rm -f -- "$path"`.

## Einwände

- [E1] (blocking) docs/02-statistikkern.md Z. 43, K-M1b-5, gegen docs/01-fachspezifikation.md Z. 58 (§5), Formelsammlung §4 Z. 175–181 und docs/01 Z. 10 (§1); ANK-25, ANK-28, ANK-TOL.rptr; CRITERIA ACC-1 — **Befund:** Wörtlicher Spec-Widerspruch.
  - **Die Stellen im Wortlaut:**
    - K-M1b-5: „liefert `msa_fit(type = "binary", link = "logit")` eine ICC_items, die dem Punktschätzer von `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")` auf der Link-Skala und dem publizierten Vignettenwert gleicht (`ankerRef: ANK-25`, Toleranz `ankerRef: ANK-TOL.rptr`) und mit `performance::icc()` auf demselben `glmer`-Modell übereinstimmt“.
    - docs/01 §5: „Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit) (`ANK-28`)“.
    - Formelsammlung §4: σ²_ε = π²/3 und „R_latent = σ²_α/(σ²_α + σ²_AV + π²/3)“.
    - docs/01 §1: „Weicht der Code von einer Soll-Formel ab, gilt die Formelsammlung“.
    - Formelsammlung §4 Z. 190 und docs/01 §3 Nr. 12 nennen zugleich 0,188 als Abnahmewert auf der Link-Skala.
  - **Die Zahlen (Prüflauf 1):**
    - Spec-gemäß ist ICC_items = 0,223294850303547. Das gleicht `performance::icc()` (0,223294850303548) und `rptBinary(…, expect = "liability")`.
    - Der wörtlich verlangte Vorgabeaufruf rechnet mit `expect = "meanobs"` und 1/(Ep(1 − Ep)) und liefert 0,187930859738746; ANK-25 druckt 0,188.
    - Der Abstand beträgt 0,0354. Die Toleranzen sind ANK-TOL.rptr.live_tol 1e-6 und vignette_tol 5e-4.
  - **Auch Variante B löst es nicht:** `performance::icc(approximation = "observation_level")` liefert 0,187526014414148, also 4,0e-4 neben der rptR-Vorgabe; das ist mehr als 1e-6 (Prüflauf 2).
  - **Keine Lesart erfüllt alle drei Vergleiche und docs/01 §5.**
    - Toleranzen aufweiten ist verboten (AGENTS.md, Integrität Nr. 1 und 6).
    - Ein anderer Aufruf (`expect = "liability"`) ändert den Kriteriumstext.
    - Die Quellenregel aus docs/01 §1 trägt nicht. Die Formelsammlung folgt für R_latent ihrer Quelle (Nakagawa & Schielzeth 2010, Tab. 1: π²/3). Die rptR-Vignette, Quelle von 0,188, rechnet ausdrücklich mit 1/(p(1 − p)): „The current version of rptR implements the more accurate approximation 1/(p(1-p))“ (ANK-25). Zwei treu zitierte Quellen definieren die Link-Skala verschieden; erst das Kriterium verbindet sie.
  - **Der Plan behandelt das richtig:** eigene Gegenrechnung, Empfehlung von Variante A, kein Eingriff in Test, Toleranz oder Anker (PLAN Ziel, Risiken ACC-1, Testplan K-M1b-5). — **Vorschlag:** ESCALATE und Betreiberentscheidung nach der Frage unten; dieses Review empfiehlt Variante A. Der Builder ändert bis zur Direktive nichts an K-M1b-5. PLAN-UPDATE übernimmt die Direktive in die K-M1b-5-Zeile des Testplans und in die K-M1b-5-Tabelle der Vignette.
- [E2] (minor) K-M1b-6 (docs/02 Z. 44: „Nichtkonvergenz von `clmm` oder `glmer` wird als Warnung weitergegeben und `singular`/Konvergenz im Objekt vermerkt“); docs/01 §2 Nr. 4 und Nr. 6; CRITERIA ACC-10 (5), (6); `orchestrator/LESSONS.md` — **Befund:** PLAN, Schnittstellen Nr. 4 („TRUE nur bei bestätigter Engine-Konvergenz … einschließlich der tatsächlichen Konvergenzdiagnosen“) lässt die Regel offen. Zwei Engine-Fakten (Prüflauf 3) machen naheliegende Regeln falsch:
  - (a) `clmm` mit `method = "ucminf"` und einem Zufallsterm meldet bei Erfolg `optRes$convergence = 1` („Stopped by small gradient (grtol).“). Mit „`== 0`“ gälte dieser Fit als nicht konvergiert und bekäme eine Warnung mit „converge“, und die ist zugleich AP1-Rückfallauslöser (`R/acmg.R:928`).
  - (b) Jeder singuläre `glmer`-Fit vermerkt „boundary (singular) fit: see help('isSingular')“ in `optinfo$conv$lme4$messages`, bei `conv$opt = 0`. Mit „keine vermerkte Meldung“ hätte jeder singuläre binäre Fit `converged = FALSE`; in S-bin mit drei Prompts und drei Modellen ist das häufig.

  Eigene Schwellen für Gradient oder Hessekondition wären Toleranzen ohne Anker. Für numerische Fits nennt der Plan keine Regel. LESSONS verlangt, Engine-Randfälle als Klasse zu behandeln. — **Vorschlag:** Regel nach ADR-023 Nr. 10.9 übernehmen:
  - Erfolgscodes des tatsächlich verwendeten Optimierers (nlminb 0, ucminf 1 und 2);
  - `glmer`: `conv$opt == 0` und keine Meldung außer der Randmeldung;
  - singulär heißt nicht „nicht konvergiert“;
  - keine eigenen Schwellen.

  PLAN-UPDATE nennt die Regel für numerische Fits. Unit-Tests:
  - `ucminf` mit einem Zufallsterm ergibt TRUE ohne Warnung;
  - ein singulärer `glmer` ergibt TRUE und `singular` TRUE;
  - ein erzwungener Abbruch ergibt FALSE mit Warnung.
- [E3] (minor) docs/01 §4 (Z. 52: „Nur mit ADR und Übergangsfrist: … geänderte Bedeutung eines Arguments“); docs/01 §2 Nr. 5; `R/fit.R:31–33` (`levels`: „For binary outcomes given as labels: a length-two vector whose second element is the event“), `R/fit.R:145–151` — **Befund:** PLAN, Schnittstellen Nr. 2 sagt: „Bei Label-Eingaben bezeichnet die zweite der zwei unterschiedlichen, nicht fehlenden Klassen das Ereignis“.
  - Offen bleibt, ob die Kodierung aus `levels` kommt oder aus den Daten, etwa nach der Reihenfolge des Auftretens.
  - Kommt sie aus den Daten, änderte sich die dokumentierte Bedeutung von `levels`, und die Kodierung hinge von der Zeilenreihenfolge ab.
  - Heute ist ein Label ohne `levels` ein benannter Fehler. — **Vorschlag:** PLAN-UPDATE legt fest:
    - Labels nur mit `levels`;
    - `levels` hat genau zwei verschiedene, nicht fehlende Werte, sonst ein benannter Fehler;
    - `levels[2]` ist das Ereignis;
    - Labels ohne `levels` bleiben ein Fehler.

    Unit-Test: Zeilen permutiert und `levels` vertauscht ergeben dieselben Komponenten (ANK-TOL.invariance).
- [E4] (minor) Formelsammlung §4 (Z. 170: „Das entspricht dem AIAG-Term (X̄_DIFF · K₂)² mit K₂ = 0,7071 für zwei Prüfer, aber ohne die Korrektur −EV²/(n·r) des Handbuchs und mit positiver Verzerrung“); K-M1b-4 — **Befund:** Hilfe und Druckhinweis setzen β̂²/2 heute mit dem Handbuchverfahren gleich:
  - `R/fit.R:25–26`: „which is how the AIAG X-bar/R procedure treats two appraisers“;
  - `R/fit.R:596`: „as in the AIAG X-bar/R procedure“.

  PLAN Nr. 6 und 7 sagt nicht, dass diese Gleichsetzung fällt. Der heutige Hinweis verteilt außerdem den Namen der Komponente und „range method“ auf zwei Zeilen (`R/fit.R:594–596`); der Test verlangt beides in einer Zeile. Geprüft und in Ordnung: Der vorgesehene Warnungstext erfüllt alle Bestandteile von ADR-023 Nr. 9.5 und enthält keinen AP1-Auslöser. — **Vorschlag:** Hilfe, NEWS und beide Druckmethoden nennen den AIAG-Bezug nur zusammen mit der fehlenden Handbuchkorrektur EV²/(n·r), oder sie lassen ihn weg. Je Quelle gibt es eine Druckzeile mit Namen und „range method, see ?msa_fit“.
- [E5] (minor) AGENTS.md, Integrität Nr. 5 („brechen sie benannt ab“); BL-12 (Vollläufe dauern Stunden bis Tage); CRITERIA ACC-6 („auch szenarioweise über `--scenarios`“); K-M1d-6 — **Befund:**
  - PLAN sagt „Weniger als zwei endliche Werte führen zu einem benannten Abbruch“, aber nicht, ob vor dem Abbruch Replikat- und Session-Datei geschrieben werden. Ohne sie verliert ein abgebrochener Vollauf alle Einzelschätzer und die Diagnose.
  - Für szenarioweise Vollläufe fehlt eine Anleitung, wie ihre Dateien zu den drei Dateien je Studie werden, die K-M1d-6 erwartet. — **Vorschlag:**
  - Erst Replikat- und Session-Datei schreiben, dann benannt abbrechen: Exit ungleich 0, keine Ergebnisdatei, die Session nennt Szenario und Schätzziel.
  - Die README unter `inst/validation/sim/` beschreibt den Vollauf in einem Aufruf je Studie. Für szenarioweise Läufe beschreibt sie die Zusammenführung: Zeilen nach `scenario`, `rep`, `estimand`, eine Session-Datei je Studie mit allen Seeds, ohne Neuberechnung von Einzelschätzern.
- [E6] (minor) docs/01 §5 (Z. 61: „Tests unter `tests/testthat/` überspringen mit `skip_if_not_installed()`, Abnahmetests nicht“; „neue Imports nur mit ADR“) — **Befund:** Der Testplan sieht Unit-Tests mit Gegenrechnungen gegen Suggests-Pakete vor (rptR, performance), nennt aber `skip_if_not_installed()` nicht. Die DESCRIPTION-Zeile („`parallel` für die Studienskripte deklarieren“) lässt das Feld offen. — **Vorschlag:** Jede Nutzung eines Suggests-Pakets unter `tests/testthat/` steht hinter `testthat::skip_if_not_installed()`. `parallel` kommt unter Suggests, nicht unter Imports.
- [E7] (minor) [INFRA] Gate mutgate; `orchestrator/config.env:202` (`MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$)'`), `:203`; `orchestrator/lib/r-mutation.R:53`; CRITERIA ACC-12; BL-13 — **Befund:** ACC-12 ist nicht umgesetzt (Prüflauf 6).
  - Im Vorlauf und je Mutant liefen dann `test-m1b-2-…` und `test-m1b-3-…` mit: Paketinstallation, Kurzläufe bis zweimal 20 Minuten, Teilmengenläufe.
  - Dazu käme das zweite Knit in `test-m1b-7-vignette-full-results.R`.
  - Das Zeitlimit je Mutant stiege auf das Fünffache des Vorlaufs, und mutgate dauerte Tage.
  - PLAN.md hält `config.env` für „nicht vorhanden“. Die Datei existiert mit Modus 600; der Builder konnte sie nur nicht lesen. — **Vorschlag:** an den Betreiber, vor den Gates von M1b: `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full)'`. Das Test-Gate führt weiter alle M1b-Tests aus. Für den Builder gibt es nichts zu tun. Den BACKLOG-Eintrag schreibt der Reviewer in `50-code-review`; in `30-plan-review` ist `BACKLOG.md` kein freigegebener Pfad (`orchestrate.sh:488`).
- [E8] (minor) [INFRA] `orchestrator/orchestrate.sh:543`, `:456`; CRITERIA ACC-15; BL-55 — **Befund:** Unverändert löscht ein Territoriums-Rollback vorher saubere, versionierte Dateien (Prüflauf 7). — **Vorschlag:** an den Betreiber: nur unversionierte Pfade in `OWNERSHIP_REMOVE` aufnehmen (`git ls-files --error-unmatch`). Für den Builder gibt es nichts zu tun.

## Betreiberfrage zu E1 (ACC-1)

K-M1b-5 verlangt, dass ICC_items von `msa_fit(type = "binary", link = "logit")` auf BeetlesMale drei Werten zugleich gleicht:

- (a) dem Vorgabeaufruf `rptBinary(…, link = "logit")`: 0,187930859738746, Toleranz 1e-6;
- (b) ANK-25: 0,188, Toleranz 5e-4;
- (c) `performance::icc()`: 0,223294850303548.

Die Spec legt die latente Restvarianz π²/3 fest (docs/01 §5, Formelsammlung §4). Danach ist ICC_items 0,223294850303547. Welche Fassung gilt?

- **Variante A (empfohlen von Reviewer 10-acceptance, Builder und diesem Review).**
  - K-M1b-5 vergleicht ICC_items live mit `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit", expect = "liability")` (ANK-TOL.rptr.live_tol) und mit `performance::icc()`.
  - ANK-25 bleibt eine Installationsprüfung des Vorgabeaufrufs, wie ANK-21 in K-M1b-1. Der Test „the installed rptR reproduces both published point estimates of ANK-25 with its default call“ besteht schon (ACC-16).
  - Im selben Sinn zu fassen sind Formelsammlung §4 Z. 190 („R = 0,188 auf der Link-Skala“) und docs/01 §3 Nr. 12 („Abnahme gegen rptR nur auf der Link-Skala“).
  - Die zwei unabhängigen Belege nach docs/01 §2 Nr. 2 bleiben: Gegenrechnung (rptR mit `liability`, performance) und Nachrechnung (σ²/(σ² + π²/3)). Messwerte: 0,223294850303547, 0,223294850303548 und 0,223294850303547.
  - Code und Plan folgen dieser Skala schon (`R/fit.R:577`). Am Plan ändert sich nur die K-M1b-5-Tabelle der Vignette.
- **Variante B (nicht empfohlen).**
  - Die binäre ICC rechnet mit der Beobachtungsvarianz 1/(p(1 − p)).
  - Das widerspricht docs/01 §5, ANK-28, Formelsammlung §4 und Nakagawa, Johnson & Schielzeth 2017 (Druckseite 7).
  - Auch B erfüllt K-M1b-5 nicht wörtlich: `performance::icc(approximation = "observation_level")` liegt 4,0e-4 neben der rptR-Vorgabe. Das Kriterium müsste zusätzlich umformuliert werden.
- **Nach der Entscheidung.**
  - Den Spec-Text ändert der Betreiber (docs/01 §1).
  - `tests/acceptance/test-m1b-5-binary-rptr.R` und die K-M1b-5-Prüfung in `test-m1b-7-vignette.R` passt der Reviewer mit ADR an.
  - Diese Anpassung sollte vor BUILD liegen, etwa durch eine Wiederholung von `10-acceptance` für M1b oder einen Betreiber-Commit. Sonst laufen BUILD und Gates gegen einen Test, den der Reviewer erst in `50-code-review` ändern darf; das kostet eine Rework-Runde.

## Prüfung nach Gesichtspunkten

### Spec-Treue

- **Szenariotabelle:** Die Tabelle des Plans stimmt Zeile für Zeile mit docs/02 Z. 28–35 überein: Pläne, wahre Komponenten, Links, μ und Schwellen. Für S-two füllt PLAN-M1b-SIM-01 die Lücke (ADR-023 Nr. 13.1).
- **Wahre Werte:** %GRR = 100·√(GRR/TV) und ICC = Item/TV mit Rest in GRR, wie `acc_m1b_truth()` sie rechnet.
- **Datenerzeugung:**
  - S-two zieht beide Modellstufen in jeder Wiederholung neu; damit gilt E[β²/2] = σ², wie Formelsammlung §4 es voraussetzt.
  - Für S-bin ist `plogis(μ + η)` gleichwertig zum logistischen Schwellenmodell.
- **K-M1b-1:** Die Prüfung ist schon grün (ACC-16), und der Plan ändert den Fitpfad dafür nicht.
- **K-M1b-2, K-M1b-3:** Skripte, Kurzläufe, Schema, Reproduktion, Teilmengen und Laufzeit sind vollständig geplant (ADR-023 Nr. 1–8).
- **Seed-Regel:** Die Regel `20261031 + j(s) + 8(r − 1)` ist für alle (j, r) eindeutig, denn j läuft von 1 bis 8. Sie hängt nicht von n_sim, Auswahl oder Workerzahl ab, und Überlauf wird benannt abgewiesen.
- **K-M1b-4:**
  - Der Fit mit festem Effekt und β̂²/2 besteht schon.
  - Neu sind Warnung, Druckzeilen, `msa_grr$derived` und Hilfe.
  - Der vorgeschlagene Warnungstext erfüllt alle Bestandteile von ADR-023 Nr. 9.5 und enthält keinen AP1-Auslöser.
  - Siehe auch E4.
- **K-M1b-5:** E1.
- **K-M1b-6:** Alle acht Prüfungen aus ACC-10 sind abgedeckt, BL-81 eingeschlossen.
  - Die Lücke 0,5 → 0 schließt Schnittstellen Nr. 2 (`R/fit.R:144` kürzt heute still).
  - Die stille Verwerfung binärer Labels außerhalb von `levels` behebt Nr. 1 (`R/fit.R:147`).
  - Siehe auch E2 und E3.
- **K-M1b-7:**
  - Abschnitt, Live-Prüfungen und Dateiwahl über `system.file()` in beiden Kontexten sind geplant, ebenso Ankerkopien für den öffentlichen Bau und die Literalregel einschließlich der Helfer.
  - Der K-M1b-5-Teil hängt an E1.

### Architektur und Verträge

- **Schnittstellen:**
  - Es gibt keine neuen Argumente oder Exporte und keine geänderten Vorgaben; ANK-02 bleibt unberührt.
  - `converged` und `msa_grr()$derived` sind zusätzliche Felder, und die Druckausgabe ändert sich; beides ist nach docs/01 §4 ohne ADR zulässig.
  - Die numerische NA-/NaN-Regel aus ADR-022 bleibt.
- **Abhängigkeiten:** Es gibt keine neuen Imports. rptR und performance kommen unter Suggests (ACC-13), `parallel` siehe E6.
- **Territorien:**
  - Alle Pfade des Plans liegen im Builder-Territorium: `config.env:138` sowie `docs/decisions/*` und `PROGRESS.md` (`orchestrate.sh:496`).
  - Geplant sind keine Dateien unter `tests/acceptance/`, `tests/simulation/`, `reference/` oder `orchestrator/` außer den zugewiesenen Handoffs.
- **Golden-Daten:**
  - `inst/extdata/` bleibt unberührt.
  - Die Ankerkopien unter `inst/validation/latent/anchors/` folgen dem Muster von ADR-021.
  - ANK-TOL liegt damit zweimal im Paket, unter `numeric/` und unter `latent/`. Der geplante Drifttest muss beide Kopien gegen das Original prüfen; mit „Tests prüfen Schema, genaue Dateimenge, Hashes und Drift“ ist das abgedeckt.
- **AP1 (K-M2-6):**
  - Die Range-Warnung und die neuen Verwerfungswarnungen lösen keinen numerischen Rückfall aus.
  - Die neue `clmm`-Konvergenzwarnung mit „converge“ soll ihn auslösen.
  - Der Plan sieht für beide Fälle Regressionen vor.
- **Parallelisierung:** `mclapply` steht nur unter `inst/validation/sim/` (docs/01 §5). Unter `R/` bleibt die Ausführung sequentiell (K-M1c-1).

### Vollständigkeit

- **Dateiliste:** Sie deckt K-M1b-1 bis K-M1b-7 ab, dazu Hilfe, NEWS, PROGRESS und das Builder-ADR. Das Builder-ADR bekommt eine Nummer nach ADR-023.
- **BACKLOG:** Alle 66 offenen Einträge sind adressiert oder mit Zuständigkeit und Anlass vertagt; BL-38 ist erledigt (Prüflauf 5).
- **Vertagungen:** BL-84, BL-87 und BL-89 sind mit Zeitpunkt vertagt (M1c-BUILD, vor M1d). Das ist mit LESSONS vereinbar, weil M1b den numerischen Pfad nicht umbaut.
- **ACC:** ACC-1 bis ACC-17 sind vollständig behandelt (Tabelle unten).

### Risiken

Der Plan nennt Laufzeit, Mutationsauswahl, AP1-Integration, numerische Bestandsrisiken, Versionsbindung der Vollläufe und Sandbox, jeweils mit Gegenmaßnahme. Er behauptet keine Messung, die er nicht hat; die Werte der Attrappe gelten ausdrücklich nur als Planungsinformation. Ergänzt werden:

- E2: Konvergenz als Klasse von Engine-Randfällen;
- E5: Vollauf und Abbruch.

### Gate-Abdeckung

- **tests:** führt alle M1b-Abnahmetests aus. Die Laufzeit des Gates wächst um die beiden Neuläufe (zusammen bis 2 × ANK-TOL.sim_runtime), die Paketinstallation und ein zweites Knit; die Messung folgt in BUILD (BL-13).
- **lint:** baut `validation.Rmd` öffentlich. Dafür braucht der Bau rptR und performance unter Suggests (ACC-13) und die Ankerkopien.
- **trace:** Jede Testdatei nennt ihre K-M1b-ID. Den Bau aus K-M1b-7 ordnet `test-m1b-7-vignette.R:10–11` dem lint-Gate zu.
- **mutgate:** Der Scope bleibt `R/fit.R` und `R/grr.R`; die schnellen Tests K-M1b-1, -4, -5, -6 und -7 erkennen die neuen Fehlbilder. Die Testauswahl ist E7.
- **golden-adr:** Unter `inst/extdata/` und `reference/anchors/` ist keine Änderung geplant.
- **territory:** siehe Architektur.

## Antworten auf die Einwand-IDs

| ID | Behandlung im Plan | Urteil |
| --- | --- | --- |
| ACC-1 | Widerspruch bestätigt, Variante A empfohlen, eigene Gegenrechnung, kein Eingriff | richtig; E1, ESCALATE |
| ACC-2 | übernommen: CLI, installiertes Paket, Arbeitsverzeichnis, Dateinamen | richtig. Die CLI-Zeile des Plans nennt eine andere Schalterreihenfolge als der Test; der benannte Parser verträgt das. ADR-023 Nr. 1 |
| ACC-3 | übernommen, alle vier Kennzahlen auch für `two_level` | richtig; ADR-023 Nr. 2 und 3 |
| ACC-4 | übernommen: echte Zählungen, `derived`, gescheiterte Fits | richtig; ADR-023 Nr. 4 |
| ACC-5 | übernommen; RMSE = 0 als Konvention 0 | richtig. Die Konvention ist zulässig und bei stetigen Schätzern ohne Wirkung. ADR-023 Nr. 5; Abbruch siehe E5 |
| ACC-6 | stabile Ströme je ID und Wiederholung, Teilmengen | richtig; die Seed-Regel erfüllt ADR-023 Nr. 6 |
| ACC-7 | übernommen, Namensräume vor dem Fork | richtig; ADR-023 Nr. 7 |
| ACC-8 | übernommen | richtig; ADR-023 Nr. 8 |
| ACC-9 | übernommen | richtig; ADR-023 Nr. 9, E4 |
| ACC-10 | übernommen | richtig. Die Konvergenzregel ist offen (E2, ADR-023 Nr. 10.9), ebenso die Binärkodierung (E3) |
| ACC-11 | übernommen; der K-M1b-5-Teil wartet | richtig; ADR-023 Nr. 11 |
| ACC-12 | [INFRA] beim Betreiber | richtig; E7 (Wert noch alt) |
| ACC-13 | rptR und performance unter Suggests | richtig; E6 |
| ACC-14 | übernommen | richtig; ADR-023 Nr. 12 |
| ACC-15 | [INFRA] beim Betreiber | richtig; E8 |
| ACC-16 | nur als Planungsinformation | richtig |
| ACC-17 | Mindestzahl aus ANK-06 | richtig |
| PLAN-M1b-SIM-01 | Fünfklassenschema wie S-ord-1 vorgeschlagen | angenommen; ADR-023 Nr. 13.1 |

## Hinweise für Runde 2

- **Antworten:** PLAN-UPDATE beantwortet E1 bis E8 nach SCHEMA, je mit `akzeptiert: <Änderung>` oder `abgelehnt: <wörtliches Spec-Zitat mit Fundstelle>`.
  - E1 nach der Direktive aus ARBITER.md bzw. vom Betreiber.
  - E7 und E8 betreffen nur den Betreiber; „akzeptiert: keine Builder-Änderung“ genügt.
- **Bindung:** ADR-023 bindet. Bestätigen oder mit Spec-Zitat ablehnen muss PLAN-UPDATE nur Nr. 10.9 und Nr. 13.
- **Letzte Runde:** Runde 2 ist die letzte Planrunde. Löst der Arbiter jetzt auf, ist er verbraucht, und ohne PASS in Runde 2 wird M1b geparkt (`orchestrate.sh:804–807`, `:926–932`).
