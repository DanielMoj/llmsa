# ADR-042 — Auslegungen des Reviewers zu M1c: Prüfformen K-M1c-1 bis K-M1c-8, Vertrag der Studie `boot_coverage`, Anker ANK-32 und ANK-33

## Status

Angenommen (Reviewer, `30-plan-review` M1c, Runde 1, 02.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1).

- Nr. 1 bis 16 halten die Auslegungen fest, die `orchestrator/handoff/M1c/CRITERIA.json` unter `open` als ACC-1 bis ACC-13 und ACC-18 bis ACC-20 führt.
  - ACC-15 kündigt dieses ADR an: `10-acceptance` darf `docs/decisions/` nicht schreiben (`orchestrate.sh`, `path_allowed`).
  - `PLAN.md` (Runde 1) übernimmt alle diese Auslegungen („ACC-1 bis ACC-13 und ACC-18 bis ACC-20 werden als Prüfform übernommen“).
- Nr. 17 hält die Anker ANK-32 und ANK-33 fest, die die Abnahmephase angelegt hat (ACC-15).
- Nr. 18 bestätigt drei Festlegungen aus `PLAN.md`, die diese Auslegungen ausfüllen: Seed-Regel der Studie, Erfassung der Singularität im Bootstrap, Ort von `msa_boot()`.
- Die Nummern ändern keinen Abnahmetest; sie schreiben fest, was die Tests prüfen. Einzelheiten der Prüfformen stehen im Feld `note` des jeweiligen ACC-Eintrags. Weicht ein Eintrag von diesem ADR ab, gilt dieses ADR.
- Eine zweite Planrunde darf Nr. 18 präzisieren, aber nicht stillschweigend ändern.

## Kontext

- **Die Spec schweigt** zu folgenden Punkten:
  - K-M1c-1: Quantildefinition, Toleranzbezug je Kennzahl, Umfang des Suchmusters;
  - K-M1c-2: Auslösung nicht endlicher Wiederholungen im Test, Begriff der singulären Wiederholung, Wortlaut der Druckausgabe;
  - K-M1c-3 und K-M1c-4: Aufrufform, Ausgabeort, Format der Replikatdatei, Bezeichner von Schätzzielen und Kennzahlen, MCSE von Breite und Anteilen, Seed-Regel, Inhalt der Session-Datei. Die Szenariotabelle in docs/02 nennt nur für S-boot-7 die Zielgröße;
  - K-M1c-5: Prüfform von Tabelle und Dateiwahl;
  - K-M1c-7: Vergleichsform und Bezug der Bytegleichheit, Lage des Hinweises in der Druckausgabe;
  - K-M1c-8: Beobachtungsgröße, Vergleichsform und Fälle; Prüfform von „neu erzeugt“ und der Angaben in `?msa_fit`.
- **Vorbild** sind die Verträge der Klasse-B-Studien aus M1b (ADR-023 Nr. 1 bis 8 und 13, ADR-029 Nr. 1).
- **Gemessen in dieser Phase** (PLAN-REVIEW M1c, Runde 1, Prüfläufe 1 bis 3 und 6; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26, Matrix 1.7.4, Referenz-BLAS 3.12.1; `R/fit.R` und `R/grr.R` mit den SHA-256 aus ANK-33):
  - Eine `FUN` für `lme4::bootMer()`, die neben den sechs Kennzahlen das Kennzeichen `lme4::isSingular()` liefert und nach `bootMer()` abgetrennt wird, lässt `names`, `class`, `row.names`, jede Spalte, `attr(, "boot")` und `attr(, "level")` von `msa_boot()` identisch mit dem heutigen Code (`identical()`). Geprüft in vier Läufen: numerisch 0,95; binär 0,90; mit drei injizierten Fehlschlägen 0,90; ohne Fehlschlag und Singularität 0,95.
  - Referenzzählungen der Abnahmetests: numerisch 9 von 20 Refits singulär, binär 5 von 20, Fehlerlauf 3 nicht endlich und 5 singulär unter 17 endlichen, Nulllauf 0 und 0. Die Zählungen der Variante nach Nr. 18.2 gleichen ihnen.
  - CRITERIA.json nennt abweichend „in der binären 2 von 20“ (ACC-1 (4)) und „3 und 7“ (ACC-2 (3)). Die Tests zählen zur Laufzeit; ihre Bedingungen gelten auch mit den gemessenen Werten (0 < 5 < 17; 5 ist weder 3 noch 20 noch 90; ohne die singulären Wiederholungen ändern sich im Fehlerlauf die Intervalle von fünf der sechs Kennzahlen).
  - `ordinal::clmm` verbindet `control` und `...` mit `getCtrlArgs(control, list(...))`; Optionen aus `...` gehen vor. Ein Aufruf mit `control = clmm.control(iter.max = 2000, eval.max = 4000)` und `iter.max = 7` in `...` legt `iter.max = 7, eval.max = 4000` ab.

## Entscheidung

1. **(ACC-1) Prüfform K-M1c-1.**
   1. Gegenrechnung: `lme4::bootMer(fit$model, FUN, nsim, seed, type = "parametric")` mit `acc_m1c_reference_fun()` (`tests/acceptance/setup-m1c.R`), unabhängig vom Produktcode nach Formelsammlung §3 aus `lme4::VarCorr`:
      - EV = Restvarianz (numerisch die Zeile Residual; binär die latente Restvarianz des Links nach ANK-28, Formelsammlung §4);
      - AV = prompt + model + block + item:prompt + item:model + prompt:model, GRR = EV + AV, PV = item, TV = GRR + PV;
      - ndc mit Konstante und Untergrenze aus ANK-16.
   2. Kennzahlen sind die sechs Namen von `msa_grr()$summary`: `grr_pct_study_var`, `grr_pct_contribution`, `repeatability_pct_study_var`, `reproducibility_pct_study_var`, `ndc`, `icc_items`. Die Spalte `statistic` von `msa_boot()` nennt genau diese.
   3. Quantil: `stats::quantile(type = 7)` je Kennzahl über deren endliche Werte, mit `probs` (1 − level)/2 und 1 − (1 − level)/2. Das ist die Definition des Codestands, auf den Formelsammlung §9 verweist.
   4. Vergleich je Kennzahl und Niveau (0,90 und 0,95):
      - `lower` und `upper` gegen das Perzentilintervall der bootMer-Wiederholungen, `estimate` gegen `t0` desselben Aufrufs;
      - Toleranz ANK-TOL.engine_boot relativ zum Referenzwert, weil alle sechs Größen abgeleitete Kennzahlen sind (docs/01 §2 Nr. 6); der Punktschätzer von ndc identisch;
      - die Testdaten halten den ungerundeten ndc jeder Wiederholung mehr als 1e-9 relativ von einer ganzen Zahl fern.
   5. Testparameter, keine Referenzwerte: numerisch 10 Items × 3 Prompts × 3 Modelle × 2 Replikate × 2 Blöcke mit allen sieben Komponenten (Seed 20261102), `msa_fit(type = "numeric")` mit Vorgaben; binär 30 × 4 × 4 × 2, Logit (Seed 20261103); nsim 20, Seeds 101 und 202; RNG Mersenne-Twister, Inversion, Rejection (docs/01 §5).
   6. Suchmuster:
      - Jede Datei `R/*.R` des Pakets unter Test (auch `.r`, `.S`, `.s`, `.q`) wird geparst (`utils::getParseData`). Kommentare sind keine Aufrufe und werden nicht durchsucht.
      - Treffer sind `mclapply`, `mcmapply`, `mcparallel` und `pvec` als Aufruf, Symbol, Name nach `::` oder Zeichenkette (`get()`, `match.fun()`) sowie die Zeichenkette `"multicore"`, die `parallel` zugewiesen wird (Argument, Listenelement, `$parallel <-`, `[["parallel"]] <-`).
      - Eine Gegenprobe auf konstruiertem Code prüft den Scanner selbst (neun verbotene, vier erlaubte Formen).
2. **(ACC-2) Prüfform K-M1c-2.**
   1. Nicht endliche Wiederholung: eine Zeile des Bootstraps mit mindestens einer nicht endlichen Kennzahl (`NA`, `NaN`, `Inf`, `-Inf`).
      - Der Test erzeugt sie durch Fehlerinjektion: `testthat::local_mocked_bindings(refit = …, .package = "lme4")` lässt den 2., 7. und 15. von 20 Refits scheitern.
      - `msa_boot()` muss deshalb über den Refit-Pfad von `lme4::bootMer()` laufen, wie K-M1c-1 es verlangt.
   2. Singuläre Wiederholung: ein gelungener Refit, für den `lme4::isSingular()` mit Vorgabetoleranz TRUE ist; so führt `msa_fit()` `singular` für lme4-Modelle. Ein gescheiterter Refit ist nicht singulär. `n_singular` zählt also nur unter den endlichen Wiederholungen, und `n_singular + n_failed ≤ nsim`.
   3. Die Attribute `n_failed` und `n_singular` sind je eine endliche Zahl und gleichen den Zählungen der Referenz: bootMer mit derselben Injektion und der FUN aus Nr. 1, die zusätzlich `isSingular()` ausgibt.
   4. Quantile wie Nr. 1.3 über alle endlichen Werte, singuläre Wiederholungen eingeschlossen. Der Test prüft vorab, dass ein Weglassen der singulären Wiederholungen mindestens ein Quantil ändern würde.
   5. Druckausgabe, je Zahl eine eigene Zeile, Groß- und Kleinschreibung gleichgültig, Zahlen als eigene Zahl:
      - Eine Zeile nennt `n_failed` mit einem Wort für Scheitern (fail, non-finite, nonfinite, not finite) und einem für Verwerfen (drop, discard, exclud, remov, omit) und enthält nicht „singular“.
      - Eine Zeile nennt `n_singular` mit „singular“ und einem Wort für Behalten (retain, kept, keep, includ, remain) und ohne Wort für Verwerfen.
      - Keine Zeile enthält „singular“ zusammen mit einem Wort für Verwerfen; Verneinungen wie „not dropped“ zählen als Verwerfen.
      - Beide Zeilen stehen immer da, auch bei 0.
   6. Testparameter: numerisches Design aus Nr. 1.5, nsim 20, Seed 303, level 0,90; Fall ohne Fehlschlag und ohne Singularität 12 × 5 × 5 × 2, `interactions = FALSE`, Seed 20261105, Bootstrap-Seed 404.
3. **(ACC-3) Aufruf und Laden von `boot_coverage`.**
   1. Aufruf: `Rscript inst/validation/sim/boot_coverage.R --n-sim <n> --scenarios <ID>[,<ID>…] --out <Verzeichnis>`.
      - Der Wert steht durch ein Leerzeichen getrennt hinter dem Schalter; die Reihenfolge der Schalter ist frei.
      - Szenario-IDs S-boot-1 … S-boot-7 wie in der Tabelle in docs/02, kommagetrennt. Fehlt `--scenarios`, gelten alle sieben (Builder-Erweiterung, zulässig).
   2. `--out` ist ein Verzeichnis und wird bei Bedarf angelegt. Darin entstehen `boot_coverage_results.csv`, `boot_coverage_replicates.csv` und `boot_coverage_session.txt`; der Exit-Status ist 0. Fehler enden benannt mit einem Exit-Status ungleich 0.
   3. Das Skript lädt das installierte Paket (`library(llmsa)`); Helfer und Ankerkopien kommen über `system.file()`. Es hängt nicht vom Arbeitsverzeichnis ab. Der Test installiert das Paket unter Test wie ADR-023 Nr. 1.3; die Bibliothek teilen sich die Tests von M1b und M1c.
   4. Der Seed steht fest im Skript und wird in der Spalte `seed` ausgewiesen.
   5. Kurzlauf im Repository: die drei Dateien eines Laufs mit `--n-sim <ANK-TOL.n_check> --scenarios S-boot-1,S-boot-7`, umbenannt in `inst/validation/sim/boot_coverage_check_results.csv`, `boot_coverage_check_replicates.csv` und `boot_coverage_check_session.txt`, erzeugt mit dem Paketstand, der in die Gates geht.
   6. Die Szenarien liest der Test zur Laufzeit aus der Tabelle in docs/02 (docs/01 §8: Spec, keine Anker).
4. **(ACC-4) Datenerzeugung und Verfahren.**
   1. S-boot-1 bis S-boot-6 sind numerisch: y = μ + unabhängige Normalverteilungen je Komponente der Tabelle (Item, Prompt, Modell, Block, Item×Prompt, Item×Modell, Prompt×Modell) + N(0, Rest) je Beobachtung (Formelsammlung §2); μ frei.
      - Verfahren: `msa_fit(type = "numeric")` mit Vorgaben (Wechselwirkungen an, Vorgabepfad ohne `...`) und `msa_grr(fit)` mit Vorgaben.
   2. S-boot-7: Bernoulli-Antworten mit P = plogis(μ + η), μ = 0, η = Summe der Effekte von Item, Prompt und Modell, ohne weiteres Rauschen (wie ADR-023 Nr. 13.3).
      - Verfahren: `msa_fit(type = "binary", link = "logit")` mit Vorgaben, also ohne Wechselwirkungen.
      - Die latente Restvarianz π²/3 (ANK-28) geht in die wahren Werte von %GRR, % Contribution GRR, ndc und ICC_items ein; sie ist kein Schätzziel.
   3. Bootstrap je Wiederholung: `msa_boot(fit, level = 0.95, seed = <Seed der Wiederholung>)` ohne `nsim`-Argument, also mit der Paketvorgabe (docs/02 M1c: „Bootstrap-Wiederholungen je Fit nach Paketvorgabe“). Der Test vergleicht `boot_nsim` mit `formals(msa_boot)$nsim` des Pakets unter Test.
5. **(ACC-5) Ergebnisdatei.**
   1. CSV wie `utils::write.csv(row.names = FALSE)` mit mindestens den Spalten `scenario`, `estimand`, `measure`, `value`, `mcse`, `n_sim`, `seed` (docs/01 §8); eine Zeile je Szenario × Schätzziel × Kennzahl. Weitere Zeilen und Spalten sind zulässig.
   2. Schätzziele:
      - jede Komponente der Szenariotabelle, benannt wie `msa_fit()$vc$source` (`item`, `prompt`, `model`, `block`, `item:prompt`, `item:model`, `prompt:model`, `Residual`; bei S-boot-7 `item`, `prompt`, `model` ohne die latente Restvarianz);
      - `grr_pct_study_var`, `grr_pct_contribution`, `ndc` und `icc_items`, benannt wie in `msa_grr()$summary` und `msa_boot()$statistic`.
   3. Für jedes Schätzziel `bias`, `rel_bias`, `empse` und `rmse` nach ADR-023 Nr. 5: rel_bias = Bias/θ mit MCSE(Bias)/|θ|; RMSE = √MSE mit MCSE(MSE)/(2 · RMSE). Ist RMSE = 0, ist MCSE(RMSE) = 0. Alle wahren Werte der Tabelle sind > 0.
   4. Für die vier Schätzziele mit Intervall zusätzlich:
      - `coverage` = Anteil der Wiederholungen mit lower ≤ θ ≤ upper (geschlossenes Intervall) über die Wiederholungen mit endlichen Grenzen, MCSE √(p(1 − p)/n) (Formelsammlung §9);
      - `width` = Mittel von upper − lower über dieselben Wiederholungen, MCSE eines Mittels √(Σ(w − w̄)²/(n(n − 1))).
   5. Je Szenario das Schätzziel `bootstrap` mit `singular_share` und `failed_share`:
      - q_r = n_singular_r/B_r beziehungsweise n_failed_r/B_r je Wiederholung r, mit B_r = `boot_nsim`;
      - Wert = Mittel der q_r über die Wiederholungen mit Bootstrap, MCSE eines Mittels wie bei `width`;
      - nicht √(p(1 − p)/(n · B)), weil die Bootstrap-Fits einer Wiederholung nicht unabhängig sind.
   6. Je Pflichtzeile: `value` endlich, `mcse` endlich und ≥ 0, `n_sim` gleich der Zahl der Wiederholungen des Laufs, `seed` eine Zahl. Weniger als zwei endliche Werte führen zu einem benannten Abbruch, nie zu einem Ersatzwert.
   7. Der Test rechnet jede Pflichtkennzahl aus der zugehörigen Replikatdatei nach, mit den wahren Werten der Tabelle und der Toleranz ANK-TOL.arithmetic absolut.
   8. Begründung des Kennzahlensatzes: docs/02 M1c nennt Bias, EmpSE, Überdeckung, mittlere Breite und die beiden Anteile; docs/01 §8 zusätzlich MSE, enthalten in `rmse` wie ADR-023 Nr. 3.2; K-M1d-7 tabelliert die relative Verzerrung für alle vier Studien. Ein fehlendes Maß im Vollauf hieße einen neuen Vollauf (BL-12).
6. **(ACC-6) Replikatdatei.**
   1. Langformat: eine Zeile je Szenario × Wiederholung × Schätzziel nach Nr. 5.2, ohne `bootstrap`.
   2. Spalten mindestens `scenario`, `rep` (1 … n_sim), `estimand`, `estimate`, `true`, `lower`, `upper`, `items`, `prompts`, `models`, `blocks`, `observations`, `boot_nsim`, `boot_level`, `n_singular`, `n_failed`.
   3. `true` ist der Wert der Szenariotabelle. %GRR, % Contribution GRR, ICC_items und ndc folgen Formelsammlung §3 mit GRR = alle Komponenten außer Item einschließlich Rest (S-boot-7: π²/3 nach ANK-28) und TV = GRR + Item; ndc mit Konstante und Untergrenze aus ANK-16.
   4. `lower` und `upper` tragen das Intervall von `msa_boot()` für die vier Intervall-Schätzziele: endlich und lower ≤ upper, wenn der Bootstrap lief und nicht alle seine Fits scheiterten. Bei Komponenten sind sie frei (`NA` zulässig).
   5. `items`, `prompts`, `models`, `blocks` und `observations` stammen aus `fit$n` des Fits dieser Wiederholung (wie ADR-023 Nr. 4.4).
      - `boot_nsim` ist die Zahl der Bootstrap-Wiederholungen, `boot_level` = 0,95; `n_singular` und `n_failed` stammen aus den Attributen von `msa_boot()`.
      - Diese vier Werte sind in allen Zeilen einer Wiederholung gleich; die Zählungen liegen in [0, boot_nsim], mit n_singular + n_failed ≤ boot_nsim.
   6. Scheitert der Fit, sind `estimate`, `lower`, `upper` und alle Zählspalten `NA`, nie Werte aus dem Sollplan. Scheitert nur `msa_boot()`, sind `lower`, `upper` und die vier Bootstrap-Spalten `NA`.
   7. Jede Spalte ist deterministisch und hängt weder von n_sim noch von der Szenarioauswahl noch von der Workerzahl ab. Laufzeiten und Versionen stehen nur in der Session-Datei; Einzelschätzer mit 15 signifikanten Stellen (`write.csv`).
7. **(ACC-7) Reproduktion, Präfix- und Teilmengenstabilität.**
   1. Neulauf gegen Kurzlauf: alle Spalten der Replikatdatei, Zahlen Element für Element nach `format(x, digits = 15)`, Zeilen nach `scenario`, `rep`, `estimand` sortiert (`acc_m1b_expect_same_replicates()`).
   2. Ein Lauf mit `--n-sim 2 --scenarios S-boot-7` enthält genau S-boot-7 und liefert in allen Spalten dieselben Zeilen wie die Wiederholungen 1 und 2 von S-boot-7 im Kurzlauf. Grund: K-M1d-6 vergleicht die ersten n_check Wiederholungen von S-boot-1 und S-boot-7 aus dem Vollauf des Betreibers (n_sim ≥ ANK-06, alle sieben Szenarien, auch szenarioweise über `--scenarios`) mit einem Neulauf.
   3. Der Zufallsstrom der Daten und der des Bootstraps hängen je Szenario und Wiederholung weder von n_sim noch von Auswahl oder Reihenfolge der Szenarien noch von der Workerzahl ab. RNG: Mersenne-Twister, `normal.kind = "Inversion"`, `sample.kind = "Rejection"` (docs/01 §5).
8. **(ACC-8) Session-Datei und Laufzeit.**
   1. Kurzlauf und Neulauf enthalten:
      - eine Zeile „R version …“ aus `sessionInfo()`;
      - die Versionsangaben `llmsa_…` und `lme4_…`;
      - jeden Seed der Spalte `seed` als Zahl;
      - die Wörter „Mersenne-Twister“ und „Rejection“;
      - eine Laufzeitangabe mit „runtime“ oder „elapsed“.
   2. Laufzeit: Wanduhrzeit des Rscript-Neulaufs des Kurzlaufs (S-boot-1 und S-boot-7, n_sim = ANK-TOL.n_check) ohne die Paketinstallation, höchstens ANK-TOL.sim_runtime. `parallel::mclapply` ist unter `inst/validation/sim/` zulässig (docs/01 §5), mit höchstens ANK-TOL.sim_runtime.cores Prozessen; unter `R/` bleibt es verboten (Nr. 1.6).
9. **(ACC-9) Szenarien außerhalb des Kurzlaufs.** Der Test ruft das Skript mit `--n-sim 2 --scenarios S-boot-2,S-boot-3,S-boot-4,S-boot-5,S-boot-6` auf und prüft Schema (Nr. 5), Replikate gegen die Szenariotabelle (Nr. 6), die Nachrechnung aller Kennzahlen und die Session-Datei. Für diesen Lauf gilt keine Laufzeitgrenze. So fällt ein falsch umgesetztes Szenario vor dem Vollauf auf (BL-12).
10. **(ACC-10) Dokumentation von `msa_boot()`.** Die Hilfeseite `man/msa_boot.Rd`, im Repository als Text über `tools::Rd2txt` gelesen, nennt „boot_coverage“ und die Vignette (`vignette("validation"` … oder „validation.Rmd“).
11. **(ACC-11) Prüfform K-M1c-5.**
    1. Eine Überschrift mit genau dem Text „Bootstrap intervals: coverage by scenario“; die Ebene ist frei.
    2. Die im Repository gestrickte Vignette (gemeinsamer Knit mit K-M1a-7 und K-M1b-7, `REPO_ROOT` gesetzt) zeigt den Abschnitt ohne Fehler.
    3. Die Tabellen des Abschnitts enthalten die Wörter coverage und MCSE.
       - Jede Szenario-ID der gelesenen Datei steht im Abschnitt.
       - Für jede Zeile mit `measure` = `coverage` (Szenario × Schätzziel) zeigt eine Tabellenzeile `value` und `mcse`, jeweils auf die gezeigte Stellenzahl (eine Einheit der letzten gezeigten Stelle), als Anteil oder in Prozent, beide in derselben Skala.
    4. `n_sim` aus der Datei steht im Abschnitt.
    5. Im Rmd-Text steht kein Zahlenliteral mit mindestens drei signifikanten Stellen, das einem `value` oder `mcse` der gelesenen Ergebnisdatei gleicht.
    6. Dateiwahl: In einer temporären Paketkopie liegt neben dem Kurzlauf eine als Testattrappe gekennzeichnete `boot_coverage_results.csv` mit allen sieben Szenarien wie ein Vollauf.
       - S-boot-2 bis S-boot-6 entstehen aus den Zeilen von S-boot-1, S-boot-7 aus seinen eigenen; die Werte sind verschoben, `n_sim` ist die Marke 1234, der Seed ist aus dem Kurzlauf kopiert. Replikat- und Session-Datei des Kurzlaufs liegen unter den Namen des Vollaufs daneben.
       - Die Vignette wird in einem eigenen R-Prozess mit `pkgload::load_all()` der Kopie und ohne `REPO_ROOT` gestrickt und zeigt Überdeckung und MCSE der Attrappe und n_sim 1234. Sie liest die Datei deshalb über `system.file("validation", "sim", …)`.
       - Eine Prüfung der Ergebnisdatei in der Vignette (Schema, Wertebereiche, alle sieben Szenarien, `n_sim`) ist zulässig; die Attrappe muss sie bestehen. Ein Abgleich mit Replikat- oder Session-Datei oder mit der Seed-Regel je Szenario gehört nicht dazu; K-M1c-5 verlangt nur das Einlesen der Ergebnisdatei.
    7. Den Bau durch `R CMD check` entscheidet das Gate lint.
12. **(ACC-12) Prüfform K-M1c-6.** Es entscheidet das Gate mutfull; kein Abnahmetest sieht sein Ergebnis.
    1. `test-m1c-6-mutfull.R` prüft die wirksame Konfiguration (letzte Zuweisung je Schlüssel in `orchestrator/config.env`, sonst die Vorgabe in `88-mutfull.sh`): `88-mutfull.sh` ist ausführbar; `MUTFULL_MILESTONES` enthält M1c; `MUTFULL_FILES` ist `R/fit.R,R/grr.R` (= ANK-32.scope); `MUT_SCORE_MIN`, `MUT_SCORE_FLOOR` und `MUT_RATCHET_TOL` gleichen ANK-32 (80, 80, 2); `MUT_WORKERS` = 14; `MUT_TEST_DIRS` enthält `tests/testthat` und `tests/acceptance` und nicht `tests/simulation`.
    2. Äquivalente Mutanten verlassen den Nenner nur nach einzelner Freigabe durch den Reviewer in `orchestrator/handoff/M1c/MUT-EQUIV-APPROVED.json`. Freigaben aus M1b gelten nicht von selbst.
    3. Übernimmt `88-mutfull` den Bericht von `86-mutgate` (ADR-041 Nr. 5), stammt er aus einem Lauf über beide Kerndateien, solange M1c beide ändert.
13. **(ACC-13) Prüfform K-M1c-7.**
    1. Hinweistext: zur Laufzeit aus docs/02 gelesen (Text zwischen „ und “ in der Zeile von K-M1c-7).
       - Verglichen wird nach Normalisierung: Markdown-Escapes, Backticks, Sternchen und Anführungszeichen entfernt, ein Unterstrich nur außerhalb eines Wortes (`msa_agreement` bleibt), Leerraum zusammengefasst, Groß- und Kleinschreibung unverändert.
       - Der normalisierte Satz muss als Teilzeichenkette vorkommen; Zeilenumbrüche und ein Präfix wie „note:“ sind zulässig.
    2. `print.msa_grr`: Die Ausgabe für wine (ordinal, Probit) und BeetlesMale (binär, Logit) enthält den Hinweis, die für `ic50_demo` und das numerische Testdesign aus Nr. 1.5 nicht. Die Lage in der Druckausgabe ist frei: „unter der Zeile mit Repeatability und Reproducibility“ bezieht sich auf die Berichtsvorlage, denn die Druckausgabe führt beide Quellen in getrennten Tabellenzeilen.
    3. Bericht: `msa_report(grr, output_format = rmarkdown::md_document(variant = "gfm", pandoc_args = "--wrap=none"))` rendert die Vorlage.
       - In Abschnitt 3 (Überschrift „3. …“) gibt es genau eine Zeile außerhalb von Überschriften mit „Repeatability“ und „Reproducibility“ (Groß- und Kleinschreibung gleichgültig).
       - Der Block unmittelbar darunter ist der Hinweis: die nächste nichtleere Zeile samt Fortsetzungszeilen bis zu Leerzeile, Überschrift oder nächstem Listenpunkt. Er darf eigener Listenpunkt, Unterpunkt oder Absatz sein.
       - Für `ic50_demo` steht der Hinweis nirgends im Bericht.
    4. `?msa_grr`: Der Text von `man/msa_grr.Rd` (`tools::Rd2txt`, im Repository) enthält den Hinweis.
    5. Bytegleichheit: Bezug ist der Stand vor M1c, der unveränderliche Tag `done/M1b` (ANK-33).
       - Der Test liest `R/fit.R` und `R/grr.R` mit `git cat-file` aus diesem Tag in temporäre Dateien, prüft die SHA-256 gegen ANK-33 und lädt beide mit `sys.source()` in eine Umgebung mit dem Namensraum unter Test als Elternumgebung.
       - Er vergleicht mit `identical()`: `table`, `summary` und `verdict` von `msa_grr()` in neun Fällen; `msa_boot()` auf dem numerischen (level 0,95) und dem binären Testdesign (level 0,90): `names`, `class`, `row.names`, jede Spalte, `attr(, "boot")` und `attr(, "level")`.
       - Nicht verglichen werden `n_failed`, `n_singular` (K-M1c-2) und zusätzliche Attribute (docs/01 §4). Eine Zusatzspalte in den Bootstrap-Wiederholungen, etwa ein Singularitätskennzeichen, verletzt die Bytegleichheit.
    6. Der Vergleich bleibt nach M1c bestehen. Eine spätere, gewollte Änderung dieser Rechnungen braucht ein ADR und die Anpassung dieses Tests.
14. **(ACC-18) Prüfform K-M1c-8: Steuerung des ordinalen Vorgabepfads und Komponenten auf wine.**
    1. Die Limits liest der Test zur Laufzeit aus docs/02, aus der Code-Spanne `control = ordinal::clmm.control(iter.max = <n>, eval.max = <m>)` in der Zeile von K-M1c-8; jede andere Form beendet den Test benannt. Es sind Spezifikationswerte (ADR-041 Nr. 1), keine empirischen Referenzkonstanten; kein neuer Anker.
    2. Beobachtet wird die Steuerung, die `ordinal::clmm` im Fit ablegt (`$control`). Während `msa_fit()` läuft, ersetzt `testthat::local_mocked_bindings(clmm = …, .package = "ordinal")` die Bindung durch eine Hülle, die denselben Aufruf mit dem Original auswertet und jedes `$control` aufzeichnet. Verlangt sind mindestens ein Aufruf; jeder aufgezeichnete Aufruf und `fit$model$control` tragen die erwartete Steuerung.
    3. Erwartet ist die Steuerung des direkten Aufrufs mit dem verlangten Argument (`acc_m1c_8_required_control()`): ohne das Argument `control` die von `ordinal::clmm.control(iter.max = 2000, eval.max = 4000)`, mit `control = X` die von genau X, ohne die Limits der Vorgabe hineinzumischen. Vergleich mit `expect_equal(tolerance = 0)`, nachdem Listenelemente und `optCtrl` nach Namen sortiert sind.
    4. „Ohne `control`“ heißt ohne das Argument `control`, nicht ohne `...`.
       - Fälle ohne `control`: wine (Item = bottle, Prompt = judge) mit Probit und mit Logit; wine (Probit) mit `Hess = TRUE`; der Plan mit zwei Modellen (Seed 20261108, 12 Items, Modell als fester Effekt) mit dem direkten Aufruf `ordinal::clmm(y ~ 1 + model + (1 | item) + (1 | prompt), link = "probit", control = …)` als Bezug.
       - Fälle mit `control` (wine, Probit): `ordinal::clmm.control(iter.max = 7)`, `list(eval.max = 50)` und `list()`. Auch eine leere Liste ist eine Angabe des Aufrufs. In diesen Fällen gleichen die Komponenten von `msa_fit()` denen des direkten Aufrufs mit derselben Steuerung (ANK-TOL.engine_ordinal je Komponente als Anteil von σ²_TV).
    5. wine ohne `control`: Komponenten gleich dem direkten Aufruf aus K-M1b-1 ohne `control` (ANK-TOL.engine_ordinal je Komponente als Anteil von σ²_TV, wie ADR-023 Nr. 9.1).
    6. Optionen des Optimierers, die ein Aufruf ohne `control` direkt in `...` übergibt (etwa `iter.max`), reicht `msa_fit()` wie jedes andere Engine-Argument durch. `ordinal::clmm` stellt sie vor die Vorgabesteuerung (Kontext). Das ist mit K-M1c-8 vereinbar und gilt nicht als Mischung im Sinne von Nr. 14.3.
15. **(ACC-19) `?msa_fit`.** Gelesen wird `man/msa_fit.Rd` im Repository über `tools::Rd2txt`, Leerraum zusammengefasst, Anführungszeichen und Backticks entfernt.
    1. Beide Limits stehen in der Form `iter.max = 2000` und `eval.max = 4000` (Werte aus docs/02, Nr. 14.1); Leerraum um das Gleichheitszeichen frei, statt `=` auch `:` oder `of`; der Wert ist nicht Anfang einer längeren Zahl.
    2. Ein Satz (getrennt nach `.`, `!` oder `?` vor einem Großbuchstaben oder einer öffnenden Klammer) enthält das Wort `control`, ein Wort für Ersetzen (replac, overrid, supersed, instead, precedence) und einen Bezug auf die Limits (limit, iter.max oder eval.max).
16. **(ACC-20) Kurzläufe der Studien aus M1b.**
    1. „mit diesem Code neu erzeugt“: Für `ordinal_recovery`, `binary_recovery` und `two_level` gleicht das Feld `implementation:` in `<studie>_check_session.txt` dem Feld, das der Neulauf des Kurzlaufs mit dem Paket unter Test schreibt (`--n-sim <ANK-TOL.n_check>`, alle Szenarien, geteilt mit K-M1b-2 und K-M1b-3). Je Session-Datei steht genau eine Zeile `implementation: <hash>` (Format `llmsa-class-b-v1`).
    2. „K-M1b-2 und K-M1b-3 bleiben grün“: Der Neulauf reproduziert `<studie>_check_replicates.csv` byte-identisch (alle Spalten nach `format(x, digits = 15)`). Schema, Nachrechnung, Präfixläufe und Laufzeit prüfen die unveränderten Tests von K-M1b-2 und K-M1b-3.
    3. „weil ihr Implementierungshash `msa_fit` einschließt“: Der Test lädt `inst/validation/sim/simulation_helpers.R` des Pakets unter Test, berechnet `sim_implementation()`, ersetzt `msa_fit` im Namensraum für die Dauer des Tests durch eine Funktion mit einer zusätzlichen ersten Anweisung und verlangt einen anderen Hash.
    4. `test-m1c-8-check-runs.R` startet drei Skriptläufe und gehört wie die Neuläufe von K-M1b-2 und K-M1b-3 nicht in mutgate und mutfull (ACC-14; umgesetzt in `orchestrator/config.env`, `MUT_TEST_EXCLUDE`). `test-m1c-8-iteration-limit.R` bleibt im Mutationslauf.
17. **(ACC-15) Anker.**
    1. ANK-32: Mutationsscore des Statistikkerns, Schwelle 80, Floor 80, Ratchet-Toleranz 2, Umfang `R/fit.R` und `R/grr.R`. Betreiberfestlegung vom 24.10.2026 mit vier gleichlautenden Fundstellen. Geerntet in `10-acceptance` M1c, erste Runde, nach ANKER-TODO, Abschnitt M1c; die Datei fehlte trotz Status „vorhanden“.
    2. ANK-33: Bezug der Bytegleichheit nach K-M1c-7, der Tag `done/M1b` mit den SHA-256 von `R/fit.R` (`acb4bac7…`) und `R/grr.R` (`004eedeb…`) aus ADR-038, bestätigt durch ADR-039. Nachtrag des Reviewers unter einer freien Nummer nach ANKER-TODO.
    3. Beide liegen vor dem Tag `plan/M1c`. Dieses ADR ist ihr Beleg nach docs/01 §6. Die Wiederholung der Abnahme (ADR-041 Nr. 6) hat keinen Anker geändert; K-M1c-8 braucht nur ANK-TOL.engine_ordinal.
18. **(PLAN.md, Runde 1) Bestätigte Festlegungen des Builders.**
    1. Seed-Regel von `boot_coverage`: Für S-boot-j und Wiederholung r gilt `data_seed = 20261102 + 2 · (j − 1) + 14 · (r − 1)` und `boot_seed = data_seed + 1`; j ist die feste Nummer der Szenario-ID.
       - Sie erfüllt Nr. 7.3: Für 7 Szenarien × 100.000 Wiederholungen sind alle 1,4 Mio. Seeds verschieden und ganzzahlig darstellbar bis n_sim = 151.944.467 (PLAN-REVIEW M1c, Prüflauf 3).
       - Die Zahlen sind Verfahrensparameter des Builders, keine Referenzwerte.
    2. Singularität in `msa_boot()`: Die `FUN` für `lme4::bootMer()` liefert zusätzlich das Kennzeichen `lme4::isSingular()` mit Vorgabetoleranz.
       - Es wird nach `bootMer()` abgetrennt und steht nicht in `attr(, "boot")`; Nr. 13.5 bleibt erfüllt (Kontext).
       - Es entstehen keine weiteren Refits oder Zufallszahlen, und der Weg funktioniert mit `parallel = "snow"`.
       - `n_failed` zählt Zeilen mit mindestens einer nicht endlichen Kennzahl, `n_singular` singuläre unter den endlichen Zeilen (Nr. 2.1 und 2.2).
    3. Ort: `msa_boot()` und `print.msa_boot()` bleiben in `R/grr.R` (ACC-17). Eine Verlegung nach `R/boot.R` nähme den Bootstrap aus dem Umfang von mutgate und mutfull (`MUT_SCOPE_REGEX`, `MUTFULL_FILES`) und braucht eine Betreiberentscheidung. docs/02 M1d nennt `R/boot.R` („M1d ändert `R/fit.R` und `R/boot.R` nur in der roxygen-Dokumentation“); die Auslegung dieses Satzes trifft das Review von M1d.

## Konsequenzen

- **Builder:** BUILD setzt Nr. 1 bis 18 um. `PLAN.md` (Runde 1) erfüllt sie (PLAN-REVIEW M1c, Runde 1).
- **Code-Review M1c:** prüft Nr. 1 bis 18 als Vertrag. Eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-042.
- **Abnahmetests:** bleiben unverändert. Die Messwerte „2 von 20“ in ACC-1 (4) und „3 und 7“ in ACC-2 (3) ersetzt die Messung im Kontext; die Statuszeilen in `CRITERIA.json` verweisen auf dieses ADR.
- **M1d:** Für den Vollauf von `boot_coverage` und für K-M1d-6 gelten Nr. 3 bis 8 und Nr. 18.1, solange kein späteres ADR sie ersetzt. Wer nach dem Vollauf Bezeichner, Kennzahlensatz oder Zufallsströme ändert, verlangt einen neuen Vollauf (BL-12).
- **Rücknahme:** nur per Reviewer-ADR.
