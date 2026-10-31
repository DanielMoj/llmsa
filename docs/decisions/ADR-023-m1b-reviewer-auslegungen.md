# ADR-023 — Auslegungen des Reviewers zu M1b: Klasse-B-Verträge, Prüfformen K-M1b-1/-4/-6/-7, Verfahren der Studien

## Status

Angenommen (Reviewer, `30-plan-review` M1b, Runde 1, 31.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 12 halten die Auslegungen fest, die `orchestrator/handoff/M1b/CRITERIA.json` unter `open` als ACC-2 bis ACC-11 und ACC-14 führt. `orchestrator/handoff/M1b/PLAN.md` (Runde 1) übernimmt sie vollständig („Dieser Plan akzeptiert sie“). Sie ändern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen.
- Nr. 10.9 präzisiert ACC-10 für das Feld `converged` (Einwand E2 in `PLAN-REVIEW.md` M1b, Runde 1).
- Nr. 13 entscheidet die Frage PLAN-M1b-SIM-01 aus PLAN.md und legt das Verfahren der drei Studien fest.
- Nicht Gegenstand ist ACC-1 (K-M1b-5). Dort widersprechen sich bindende Spec-Stellen wörtlich; das Verdict der Runde 1 lautet deshalb ESCALATE. Ein Reviewer-ADR kann diesen Widerspruch nicht auflösen (AGENTS.md: „Widersprüchliche Specs führen zu `ESCALATE`“).
- Eine zweite Planrunde darf Nr. 10.9 und Nr. 13 präzisieren, aber nicht stillschweigend ändern.

## Kontext

Die Spec schweigt zu folgenden Punkten:

- **Klasse-B-Skripte.** docs/01 §8 nennt die Parameter `--n-sim`, `--out` und `--scenarios`, die drei Dateien und die Spalten der Ergebnisdatei. Offen bleiben: Aufrufform, Ausgabeort, Format der Replikatdatei, Bezeichner von Schätzzielen und Kennzahlen, Seed-Regel und Inhalt der Session-Datei. K-M1b-2 und K-M1b-3 verlangen byte-identische Einzelschätzer, ein vollständiges Schema und eine Laufzeitgrenze.
- **Kennzahlen.** docs/02 M1b nennt Schätzziele und Kennzahlen („Bias, relative Verzerrung, EmpSE, RMSE, jeweils mit MCSE; für S-two zusätzlich Anteil der Wiederholungen mit `derived`-Komponente“), aber keine Bezeichner. Formelsammlung §9 enthält keine Formel für die relative Verzerrung, für MCSE(RMSE) und für das MCSE eines Anteils.
- **Prüfformen.** K-M1b-1, K-M1b-4, K-M1b-6 und K-M1b-7 lassen Toleranzbezug, Prüfform, Wortlaut, Feldnamen und Auslöser offen.
- **Szenarien.** Die Szenariotabelle in docs/02 nennt für S-two weder Klassenzahl noch Schwellen (PLAN-M1b-SIM-01). Item×Modell (S-ord) ist nur mit einer Wechselwirkung schätzbar, und `msa_fit(interactions =)` nimmt nur alle drei Zweifach-Wechselwirkungen zugleich auf (`R/fit.R:178–184`).
- **Engine-Verhalten, vom Reviewer am 31.10.2026 gemessen** (R 4.6.1, lme4 2.0.6, ordinal 2026.7.26):
  - Ein singulärer `glmer`-Fit vermerkt „boundary (singular) fit: see help('isSingular')“ in `optinfo$conv$lme4$messages`, bei `optinfo$conv$opt` = 0.
  - `clmm` mit `method = "ucminf"` und einem Zufallsterm meldet bei Erfolg `optRes$convergence` = 1 („Stopped by small gradient (grtol).“).
  - Bei mehreren Zufallstermen weicht `clmm` mit der Warnung „cannot use ucminf optimizer for this model, using nlminb instead“ auf nlminb aus.
  - `?ucminf::ucminf` nennt die Codes 1 (kleiner Gradient), 2 (kleiner Schritt), 3 (Grenze der Funktionsauswertungen) und 4 (Nullschritt der Liniensuche).

## Entscheidung

1. **(ACC-2) Aufruf und Laden der Klasse-B-Skripte.**
   1. Aufruf: `Rscript inst/validation/sim/<studie>.R --n-sim <n> --scenarios <ID>[,<ID>…] --out <Verzeichnis>` mit `<studie>` ∈ {`ordinal_recovery`, `binary_recovery`, `two_level`}.
      - Der Wert steht durch ein Leerzeichen getrennt hinter dem Schalter.
      - Die Reihenfolge der Schalter ist frei; der Abnahmetest ruft `--n-sim`, `--scenarios`, `--out` in dieser Reihenfolge.
      - Szenario-IDs wie in der Tabelle in docs/02 (S-ord-1 … S-ord-4, S-bin-1, S-bin-2, S-two-1, S-two-2), kommagetrennt.
      - Fehlt `--scenarios`, gelten alle Szenarien der Studie (Builder-Erweiterung, zulässig).
   2. `--out` ist ein Verzeichnis und wird bei Bedarf angelegt. Darin entstehen `<studie>_results.csv`, `<studie>_replicates.csv` und `<studie>_session.txt`; der Exit-Status ist 0. Fehler enden benannt mit einem Exit-Status ungleich 0.
   3. Das Skript lädt das installierte Paket (`library(llmsa)`), nicht den Quellbaum. Es hängt nicht vom Arbeitsverzeichnis ab; gemeinsame Helfer kommen über `system.file()` aus dem installierten Paket.
      - So prüft der Abnahmetest: Er installiert eine Kopie von DESCRIPTION, NAMESPACE, `R/`, `inst/`, `data/` (und, falls vorhanden, LICENSE und `src/`) mit `R CMD INSTALL --no-docs` in eine temporäre Bibliothek.
      - Er setzt `R_LIBS` auf diese Bibliothek vor den vorhandenen und startet Rscript aus einem temporären Arbeitsverzeichnis.
   4. Der Seed steht fest im Skript (die Spec nennt keinen Seed-Parameter) und wird in der Spalte `seed` ausgewiesen.
   5. Kurzlauf im Repository:
      - Er besteht aus den drei Dateien eines Laufs mit `--n-sim <ANK-TOL.n_check>` und allen Szenarien der Studie.
      - Die Dateien heißen `inst/validation/sim/<studie>_check_results.csv`, `<studie>_check_replicates.csv` und `<studie>_check_session.txt`.
      - Erzeugt wird er mit dem Paketstand, der in die Gates geht.
   6. Die Szenarien liest der Test zur Laufzeit aus der Tabelle in docs/02 (docs/01 §8: Szenarien sind Spec, keine Anker). Zielgröße und Link je Szenario folgen der Tabelle (ordinal Probit, binär Logit).
2. **(ACC-3) Ergebnisdatei.**
   1. CSV mit Kopfzeile wie von `utils::write.csv(row.names = FALSE)`. Mindestens die Spalten `scenario`, `estimand`, `measure`, `value`, `mcse`, `n_sim`, `seed`; eine Zeile je Szenario × Schätzziel × Kennzahl.
   2. Pflicht-Schätzziele:
      - jede wahre Komponente der Szenariotabelle außer Rest, benannt wie in `msa_fit()$vc$source` (`item`, `prompt`, `model`, `item:model`, `block`);
      - `grr_pct_study_var` (% Studienvariation der gesamten Gage R&R) und `icc_items`, benannt wie in `msa_grr()$summary`.
   3. Je Pflichtzeile gilt:
      - `value` ist endlich;
      - `mcse` ist endlich und ≥ 0;
      - `n_sim` ist die Zahl der Wiederholungen des Laufs;
      - `seed` ist ein Seed als Zahl.
   4. Weitere Zeilen (etwa `Residual`, `item:prompt`, `prompt:model`, `mse`) und weitere Spalten sind zulässig. Die Restvarianz der latenten Skala ist durch den Link festgelegt (ANK-28) und kein Pflicht-Schätzziel.
3. **(ACC-3, ACC-5) Kennzahlensatz.**
   1. Pflicht für jedes Schätzziel aller drei Studien, auch für `two_level`: `bias`, `rel_bias`, `empse`, `rmse`. Für S-two kommt beim Schätzziel `model` `derived_share` hinzu.
   2. Begründung: docs/02 M1b nennt genau diese Kennzahlen, und K-M1b-3 verlangt „Schema … wie in K-M1b-2“.
      - Die Überdeckung aus docs/01 §8 entfällt, weil die Studien von M1b keine Intervalle schätzen.
      - Der MSE aus docs/01 §8 steckt in der Zeile `rmse`: MSE = RMSE², MCSE(MSE) = 2 · RMSE · MCSE(RMSE) (Umkehrung von Nr. 5).
   3. Dieser Satz gilt als „alle Schätzziele und Kennzahlen nach Abschnitt 8“ in K-M1b-2 und K-M1b-3. Er gilt auch für die Vollläufe derselben Studien in K-M1d-6, solange kein späteres ADR ihn ersetzt.
4. **(ACC-4) Replikatdatei.**
   1. Langformat: eine Zeile je Szenario × Wiederholung × Schätzziel; weitere Schätzziele sind zulässig.
   2. Mindestens die Spalten `scenario`, `rep` (1 … n_sim), `estimand`, `estimate`, `true`, `items`, `prompts`, `models`, `blocks`, `observations`. `two_level` hat zusätzlich `derived` (TRUE/FALSE: `model` steht in `attr(fit$vc, "derived")`).
   3. `true` ist der wahre Wert aus der Szenariotabelle. Für %GRR und ICC_items gilt Formelsammlung §3 auf der latenten Skala, mit GRR = alle Komponenten außer Item, einschließlich Rest, und TV = GRR + Item.
   4. `items`, `prompts`, `models`, `blocks` und `observations` stammen aus `fit$n` des Fits dieser Wiederholung; der Test vergleicht sie mit der Tabelle. Bei einem fehlgeschlagenen Fit stehen dort `NA`, nie Werte aus dem Sollplan.
   5. In den Zeilen mit dem Schätzziel `model` von `two_level` steht in `estimate` der Schätzer β̂²/2.
   6. Jede Spalte ist deterministisch und hängt nicht von n_sim, der Szenarioauswahl oder der Workerzahl ab. Laufzeiten und Versionen stehen nur in der Session-Datei. Einzelschätzer werden mit 15 signifikanten Stellen geschrieben (`write.csv`).
   7. Ein fehlgeschlagener Fit hat `estimate` NA und `derived` FALSE (kein NA). Die Kennzahlen rechnen über die endlichen Schätzer.
5. **(ACC-5) Formeln.** Für die n endlichen Einzelschätzer x_s eines Szenarios und Schätzziels und den wahren Wert θ gilt:
   1. Bias, MCSE(Bias), EmpSE, MCSE(EmpSE), MSE, MCSE(MSE) und RMSE = √MSE nach Formelsammlung §9.
   2. rel_bias = Bias/θ mit MCSE = MCSE(Bias)/|θ|. θ ist konstant, und alle wahren Werte der Tabelle sind > 0. Morris, White & Crowther 2019, Druckseite 2086: „relative bias can be used only for |𝜃| > 0“.
   3. MCSE(RMSE) = MCSE(MSE)/(2 · RMSE) (Delta-Methode).
   4. `derived_share`: p ist der Anteil der Wiederholungen mit `derived` = TRUE, gerechnet über alle n_sim Wiederholungen des Szenarios. MCSE = √(p(1 − p)/n_sim), wie die Überdeckung in Formelsammlung §9; so rechnet `acc_m1b_share()` in `tests/acceptance/setup-m1b.R`.
   5. Weniger als zwei endliche Schätzer führen zu einem benannten Abbruch; es gibt keinen Ersatzwert.
   6. Der Abnahmetest rechnet jede Kennzahl der Ergebnisdatei aus der zugehörigen Replikatdatei nach (`acc_m1b_performance()`, `acc_m1b_share()`), mit der Toleranz ANK-TOL.arithmetic absolut.
6. **(ACC-6) Reproduktion, Präfix- und Teilmengenstabilität.**
   1. Neulauf gegen Kurzlauf: Verglichen werden alle Spalten der Replikatdatei, Zahlen Element für Element nach `format(x, digits = 15)`, die Zeilen nach `scenario`, `rep`, `estimand` sortiert.
   2. Ein Lauf mit `--n-sim 2` und einer echten Teilmenge der Szenarien (`ordinal_recovery`: S-ord-2,S-ord-4; `binary_recovery`: S-bin-2; `two_level`: S-two-2) enthält genau diese Szenarien. In allen Spalten liefert er dieselben Zeilen wie die Wiederholungen 1 und 2 des Kurzlaufs.
   3. Der Zufallsstrom je Szenario und Wiederholung hängt weder von n_sim noch von Auswahl oder Reihenfolge der Szenarien noch von der Workerzahl ab.
      - Die Seed-Regel in PLAN.md erfüllt das: feste Basis, feste Nummer je Szenario-ID, ein Seed je Szenario und Wiederholung.
      - Ihre Zahlen sind Verfahrensparameter des Builders, keine Referenzwerte.
   4. RNG: `Mersenne-Twister`, `normal.kind = "Inversion"`, `sample.kind = "Rejection"` (docs/01 §5).
7. **(ACC-7) Session-Datei.** Kurzlauf und Neulauf enthalten:
   - eine Zeile „R version …“ aus `sessionInfo()`;
   - die Versionsangaben `llmsa_…` und `lme4_…`, bei `ordinal_recovery` und `two_level` zusätzlich `ordinal_…` (die Namensräume werden vor dem Fork geladen);
   - jeden Seed der Spalte `seed` als Zahl;
   - die Wörter „Mersenne-Twister“ und „Rejection“;
   - eine Laufzeitangabe mit „runtime“ oder „elapsed“.
8. **(ACC-8) Laufzeit.**
   - Gemessen wird die Wanduhrzeit der Rscript-Aufrufe der Kurzläufe (n_sim = ANK-TOL.n_check, alle Szenarien), ohne die Paketinstallation.
   - Grenzen: `ordinal_recovery` und `binary_recovery` zusammen ≤ ANK-TOL.sim_runtime; `two_level` allein ≤ ANK-TOL.sim_runtime.
   - `parallel::mclapply` ist unter `inst/validation/sim/` zulässig (docs/01 §5), mit höchstens ANK-TOL.sim_runtime.cores Prozessen. Unter `R/` bleibt es verboten.
9. **(ACC-9) Prüfform K-M1b-1 und K-M1b-4.**
   1. ANK-TOL.engine_ordinal gilt je Komponente als Anteil von σ²_TV der direkten Rechnung. σ²_TV ist die Summe der `clmm`-Komponenten plus die latente Restvarianz aus ANK-28 (docs/01 §2 Nr. 6). Abgeleitete Kennzahlen werden relativ verglichen, ndc auf Gleichheit.
   2. Fester Effekt heißt: Der Faktor steht im festen Teil von `fit$formula` (`lme4::nobars`) und nicht als Zufallsterm (`lme4::findbars`).
   3. `attr(fit$vc, "derived")` nennt den Faktor, und `fit$vc` hat eine Zeile mit diesem `source`.
      - Ihr Wert ist β̂²/2 aus einem direkten `ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt), link = "probit")`.
      - Mini-Referenz ist die Stichprobenvarianz von {0, β̂} (Formelsammlung §4).
   4. `print.msa_fit` und `print.msa_grr`: Mindestens eine Ausgabezeile enthält „range method, see ?msa_fit“ und den Namen der Komponente. Ohne Faktor mit zwei Stufen erscheint die Wendung nicht.
   5. Jeder Fit mit einem solchen Faktor warnt; geprüft wird mit zwei Modellen und mit zwei Blöcken.
      - Die Warnung enthält „range method“ und außerdem „positive“, „bias“, „Var(“ und „?msa_fit“.
      - Ohne Faktor mit zwei Stufen gibt es keine Warnung mit „range method“.
      - Die Warnung enthält keinen Auslöser des AP1-Rückfalls (`R/acmg.R:928`: „converge“, „Hessian“, „max|grad“, „gradient“, „unidentifiable“).
   6. Die Hilfeseite `man/msa_fit.Rd` nennt „two_level“ und die Vignette (`vignette("validation"` … oder „validation.Rmd“). Gelesen wird sie im Repository, als Text über `tools::Rd2txt`.
10. **(ACC-10) Prüfform K-M1b-6.**
    1. Weniger als drei Items (1 und 2 Items): Die Fehlermeldung steht wörtlich im Text von `man/msa_fit.Rd` (`tools::Rd2txt`, Leerraum normalisiert, ohne Schlusspunkt).
    2. Alle Antworten in einer Kategorie (ordinal alle „c3“; binär alle 0 und alle 1): Fehler, dessen Meldung „categor“ oder „constant“ enthält; nie `NaN`.
    3. Fehlende Antworten (ordinal, binär) und Werte außerhalb von `levels` (ordinal; binär mit Labels und `levels`):
       - mindestens eine Warnung;
       - `n$observations` und `nobs(fit$model)` gleich der Zahl der verbliebenen Zeilen;
       - Komponenten gleich dem Fit auf den verbliebenen Zeilen (ANK-TOL.engine_ordinal · σ²_TV).
    4. Binäre Werte 2, −1 und 0,5: Fehler mit „binary“ in der Meldung.
    5. Nichtkonvergenz wird mit zwei Steuerungen geprüft:
       - `clmm` mit `control = ordinal::clmm.control(method = "nlminb", iter.max = 1, eval.max = 2)`;
       - `glmer` mit `control = lme4::glmerControl(optCtrl = list(maxfun = 10))`.
       In beiden Fällen erreicht mindestens eine Warnung den Aufrufer, und `fit$converged` ist identisch FALSE. Konvergierende Fits (Orakel ohne Meldung, nicht singulär) haben `fit$converged` identisch TRUE.
    6. Singulär (Antworten unabhängig vom Prompt): `fit$singular` ist TRUE, und keine Komponente ist negativ.
    7. Ein Faktor mit einer Stufe (ein Modell, ein Block) steht weder in `all.vars(fit$formula)` noch in `fit$vc`.
    8. ADR-022 Nr. 2 und BL-81: Ein fehlender Wert in `item_id`, `prompt_id`, `model_id` oder `block` beendet ordinale und binäre Fits mit einem Fehler, dessen Meldung „missing“ enthält.
    9. **Feld `converged`.** Es ist logisch, hat die Länge 1 und ist ein neues Rückgabefeld (nach docs/01 §4 ohne ADR zulässig). Es gibt das Urteil der Engine wieder, ohne eigene numerische Schwellen für Gradient, Hessematrix oder Schrittweite (Toleranzen nur aus Ankern, docs/01 §2 Nr. 6).
       - **`clmm`:** TRUE genau dann, wenn `optRes$convergence` einen Erfolgscode des tatsächlich verwendeten Optimierers trägt.
         - nlminb: 0.
         - ucminf: 1 und 2. Die Codes 3, 4 und negative Codes gelten als nicht konvergiert (`?ucminf::ucminf`).
         - Bei FALSE warnt `msa_fit()` selbst mit „converge“ und der Meldung der Engine (`optRes$message`). Diese Warnung ist zugleich der AP1-Rückfallauslöser (`R/acmg.R:928`), wie K-M2-6 es verlangt.
       - **`glmer`:** TRUE genau dann, wenn `optinfo$conv$opt` gleich 0 ist und `optinfo$conv$lme4$messages` keine andere Meldung enthält als die Randmeldung „boundary (singular) fit: see help('isSingular')“. Bei FALSE erreicht jede vermerkte lme4-Meldung den Aufrufer als Warnung, eine Randmeldung eingeschlossen.
       - **Singularität:** Eine singuläre Randlösung ist kein Konvergenzfehler. Sie steht in `singular`, nicht in `converged`. Die Range-Warnung (Nr. 9.5) berührt `converged` nicht.
       - **Numerische Fits:** Die Regel nennt PLAN-UPDATE; sie wird aus der vorhandenen Enddiagnostik abgeleitet. ADR-018, ADR-020 und ADR-022 bleiben unverändert.
11. **(ACC-11) Prüfform K-M1b-7.**
    1. Eine Überschrift mit genau dem Text „Ordinal and binary outcomes (latent scale)“; die Ebene ist frei.
    2. Die im Repository gestrickte Vignette (gemeinsamer Knit mit K-M1a-7, `REPO_ROOT` gesetzt) zeigt den Abschnitt ohne Fehler.
    3. Prüfungen aus K-M1b-1: Der Abschnitt nennt ANK-21 und ANK-TOL.engine_ordinal. Er zeigt die beiden Varianzen aus ANK-21 und die beobachteten Komponenten `item` und `prompt` von `msa_fit` auf wine (Logit und Probit), jeweils auf die gezeigte Stellenzahl.
    4. Prüfungen aus K-M1b-5: Der Abschnitt nennt ANK-25 und ANK-TOL.rptr. Er zeigt 0.188 (ANK-25) und die beobachtete ICC_items auf BeetlesMale. Inhalt und Vergleichsgrößen dieses Teils hängen von der Betreiberentscheidung zu ACC-1 ab.
    5. Je Studie:
       - Die Tabellen enthalten die Wörter bias, EmpSE und MCSE.
       - Sie zeigen für jedes Szenario und Schätzziel `value` und `mcse` von `bias` und `empse` der gelesenen Datei.
       - Jedes Szenario wird genannt, und n_sim aus der Datei steht im Abschnitt.
    6. Dateiwahl in einer temporären Paketkopie: Neben dem Kurzlauf liegt eine als Testattrappe gekennzeichnete `<studie>_results.csv`. Die Vignette wird mit `pkgload::load_all()` der Kopie und ohne `REPO_ROOT` gestrickt und muss deren Werte und n_sim zeigen.
       - Die Vignette liest die Ergebnisdateien deshalb aus dem Paket (`system.file("validation", "sim", …, package = "llmsa")`).
       - Für den öffentlichen Kontext braucht sie Ankerkopien nach dem Muster von ADR-021; die Ausgestaltung ist eine Builder-Entscheidung.
    7. Im Rmd-Text steht kein Zahlenliteral mit mindestens drei signifikanten Stellen, das einem `value` oder `mcse` der gelesenen Ergebnisdateien oder einem Wert aus ANK-21 oder ANK-25 gleicht.
    8. Den Bau durch `R CMD check` entscheidet das Gate lint.
12. **(ACC-14) Abbildung der Referenzdaten.**
    - wine: `item_id` = `bottle`, `prompt_id` = `judge`, `model_id` = „M1“, `rep` = 1, `value` = `rating` als Zeichen, `levels` = `levels(wine$rating)`.
    - BeetlesMale: `item_id` = `Population`, `prompt_id` = „P1“, `model_id` = „M1“, `rep` = laufende Nummer innerhalb der Population, `value` = `Colour` (0/1), `link = "logit"`.
    - `rptBinary` läuft mit `nboot = 0` und `npermut = 0`; der Punktschätzer hängt davon nicht ab.
13. **(PLAN-M1b-SIM-01) Datenerzeugung und Verfahren der Studien.**
    1. **S-two-1, S-two-2.**
       - Datenerzeugung: ordinal mit Probit-Link, fünf Klassen, Schwellen −1,5/−0,5/0,5/1,5 wie S-ord-1, latente Restvarianz 1 (ANK-28).
       - Die beiden Modell-Stufeneffekte werden in jeder Wiederholung neu aus N(0, σ²_Modell) gezogen. Schätzziel ist σ²_Modell der Tabelle.
       - Verfahren: `msa_fit(type = "ordinal", link = "probit", interactions = FALSE)`. Das Modell geht nach K-M1b-4 als fester Effekt ein; der Schätzer ist β̂²/2.
    2. **S-ord-1 bis S-ord-4.**
       - Datenerzeugung: Item, Prompt, Modell, Item×Modell (bei S-ord-4 zusätzlich Block) als unabhängige Normalverteilungen, dazu Standardnormalrauschen je Beobachtung; Klassen wie in der Tabelle.
       - Verfahren: `msa_fit(type = "ordinal", link = "probit", interactions = TRUE)`. `interactions` nimmt nur alle drei Zweifach-Wechselwirkungen zugleich auf, und nur so ist Item×Modell schätzbar.
       - item:prompt und prompt:model (wahrer Wert 0) gehören zum Verfahren. Ihre Schätzer gehen in %GRR und ICC_items ein wie in `msa_grr()`; der wahre Wert beider Größen kommt nur aus der Tabelle (Nr. 4.3). Eine daraus entstehende Verzerrung ist ein Befund für K-M1d-7, kein Fehler.
       - S-ord-4: Der Block mit zwei Stufen geht nach K-M1b-4 als fester Effekt ein. Schätzziel `block` ist dessen β̂²/2; die Range-Warnung jeder Wiederholung steht in den Diagnosen.
    3. **S-bin-1, S-bin-2.**
       - Datenerzeugung: Bernoulli-Antworten mit P = plogis(μ + η), η = Summe der Zufallseffekte. Das ist gleichwertig zum Schwellenmodell mit logistischem Rest (Formelsammlung §4); es gibt kein zusätzliches Normalrauschen.
       - Verfahren: `msa_fit(type = "binary", link = "logit", interactions = FALSE)`.

## Konsequenzen

- **Builder:** PLAN-UPDATE (Runde 2) bestätigt Nr. 10.9 und Nr. 13 oder lehnt sie mit wörtlichem Spec-Zitat ab. BUILD setzt Nr. 1 bis 13 um.
- **Code-Review M1b:** prüft Nr. 1 bis 13 als Vertrag. Eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-023.
- **Abnahmetests:** bleiben unverändert. Eine Änderung wegen ACC-1 betrifft nur K-M1b-5 und den K-M1b-5-Teil von K-M1b-7 und braucht ein eigenes ADR.
- **M1d:** Für die Vollläufe und K-M1d-6 gelten Nr. 1 bis 7, solange kein späteres ADR sie ersetzt.
- **Rücknahme:** nur per Reviewer-ADR. Wer nach den Vollläufen Bezeichner, Kennzahlensatz oder Zufallsströme ändert, verlangt neue Vollläufe (BL-12).
