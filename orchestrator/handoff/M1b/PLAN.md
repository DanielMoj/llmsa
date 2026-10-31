# PLAN — M1b, Runde 1

Stand: 31.10.2026. Rolle: Builder, Phase 20-plan.
Diese Phase schreibt ausschließlich diese Datei. Die nachfolgend genannten
Produktänderungen sind Vorschläge für BUILD nach der Planprüfung.
Es gibt noch keine Planfreigabe und kein Builder-Verdict.

## Ziel

M1b ergänzt die ordinalen und binären Fits auf der latenten Skala um die
verlangten Diagnosen und Herkunftshinweise, liefert drei ausführbare
ADEMP-Studien mit reproduzierbaren Kurzläufen und erweitert die
Validierungsvignette. Maßstab sind K-M1b-1 bis K-M1b-7, die unveränderten
Abnahmetests und die Formelsammlung §§3, 4 und 9.

**Offener Widerspruch ACC-1:** K-M1b-5 verlangt gleichzeitig zwei verschiedene
Definitionen der binären ICC. Eine vollständige grüne Abnahme ist mit diesem
Vertrag nicht möglich. Der Builder bestätigt den Befund durch eine eigene
Gegenrechnung (Testplan unten) und empfiehlt die in CRITERIA vorgeschlagene
Variante A: latente Restvarianz π²/3 beibehalten, gegen
`rptBinary(..., expect = "liability")` vergleichen und ANK-25 als separate
Installationsprüfung des rptR-Vorgabeaufrufs behandeln. Das ist ein
Entscheidungsvorschlag, keine eigenmächtige Änderung von Kriterium oder Test.
Vor einer verbindlichen Freigabe ist der Widerspruch durch den Betreiber zu
lösen; der Reviewer behandelt ihn nach dem ESCALATE-Vertrag.

Gelesene Grundlage:

- `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`,
  `PROGRESS.md`, der vollständige `BACKLOG.md`,
  `orchestrator/handoff/SCHEMA.md` und `orchestrator/LESSONS.md`.
- `orchestrator/handoff/M1b/CRITERIA.json`, alle acht
  `test-m1b-*.R`-Dateien und `setup-m1b.R` unter
  `tests/acceptance/`, die gemeinsame Setup-Datei und die verwendeten
  M1a-Helfer für Anker, Toleranzen, GRR und Vignetten.
- `docs/00-vision.md`, `docs/01-fachspezifikation.md` insbesondere §§1–9,
  `docs/02-statistikkern.md` einschließlich der Szenarien und der
  Übergabe an M1c/M1d; Formelsammlung §§3, 4 und 9.
- ANK-06, ANK-21, ANK-25, ANK-28 und die relevanten Einträge von ANK-TOL;
  ADR-017 Nr. 7, ADR-018, ADR-021 und ADR-022, insbesondere Nr. 2.
  Der bestehende Fit-/GRR-Code, die Simulation in `R/plan.R`, der
  AP1-Rückfallpfad, DESCRIPTION, Vignette und betroffene Unit-Tests
  wurden zur Planung gelesen.

Ausgangsstand: M1a ist laut `orchestrator/handoff/M1a/verdict-code.json`
in Runde 5 mit PASS und leerem `blocking` abgenommen;
`orchestrator/state/M1a/gates.json` nennt `result: pass`.
Das sind gelesene Fremdbelege. PROGRESS endet für M1a noch mit dem
Builder-Rework; BUILD ergänzt den Abschlussvermerk. M1b enthält bisher
nur CRITERIA, keinen PLAN-REVIEW und keine ARBITER-Datei.
Die roten Ausgangstests aus ACC-16 sind Reviewer-Belege, kein eigener
Abnahmelauf dieser PLAN-Phase.

## Dateien

Die folgende Liste bezeichnet den vorgesehenen BUILD-Umfang, nicht Änderungen
dieser PLAN-Phase.

| Pfad | Geplante Änderung und Zweck |
| --- | --- |
| `R/fit.R` | Ordinale/binäre Eingabeprüfung, Warnungen, Konvergenzfeld, Zwei-Stufen-Diagnose und Druckhinweis; roxygen-Dokumentation. Kernlogik bleibt im bestehenden Mutations-Scope. |
| `R/grr.R` | Abgeleitete Komponenten in das GRR-Objekt übernehmen und in `print.msa_grr` benennen; Dokumentation der Herkunft. |
| `man/msa_fit.Rd`, `man/msa_grr.Rd` | Ausschließlich aus der geänderten roxygen-Dokumentation erzeugen. |
| `DESCRIPTION` | `rptR` und `performance` als Suggests ergänzen; `parallel` für die Studienskripte deklarieren. Bestehender, per ADR-020 begründeter Matrix-Import bleibt erhalten; keine neuen Imports. |
| `inst/validation/sim/ordinal_recovery.R`, `binary_recovery.R`, `two_level.R` | Drei eigenständig aufrufbare Klasse-B-Einstiege mit dem vereinbarten CLI-Vertrag. |
| `inst/validation/sim/simulation_helpers.R`, `README.md` | Gemeinsame Argumentprüfung, Szenarien, Datengeneratoren, Zufallsströme, Ausführung, Kennzahlen und Dateiausgabe; englische ADEMP-/Betriebsanleitung. |
| `inst/validation/sim/<studie>_check_results.csv`, `<studie>_check_replicates.csv`, `<studie>_check_session.txt` | Genau neun tatsächlich erzeugte Kurzlaufdateien, je drei für ordinal_recovery, binary_recovery und two_level. |
| `data-raw/make_validation_latent.R` | Offline-Erzeuger ganzer Ankerkopien und ihres Herkunftsmanifests; alternativem Ausgabeort muss derselbe Inhalt entsprechen. |
| `inst/validation/latent/anchors/{ANK-06,ANK-21,ANK-25,ANK-28,ANK-TOL}.json`, `SOURCES.json`, `README.md` | Nachgewiesene Dokumentationseingaben nach dem Muster von ADR-021. Eigenes Verzeichnis, damit der numerische Ressourcenvertrag unverändert bleibt. |
| `inst/validation/latent/reference_checks.R` | Live-Rechnungen der Vignette, striktes Lesen der Anker und Ergebnisdateien, Tabellen und Diagnosen. |
| `vignettes/validation.Rmd` | Neuer Abschnitt „Ordinal and binary outcomes (latent scale)“; bestehender numerischer Abschnitt bleibt vollständig. |
| `tests/testthat/helper-validation-latent.R`, `test-fit-latent.R`, `test-fit-latent-diagnostics.R`, `test-grr-latent.R` | Kleine synthetische Eingaben, Engine-Gegenrechnungen, Randfälle, Herkunft und Druckmethoden. |
| `tests/testthat/test-validation-simulation.R`, `test-validation-latent.R`, `test-acmg-latent-diagnostics.R` | Statistik-/RNG-/CLI-Verträge, Ressourcenprüfung und AP1-Warnungsintegration; keine vollständigen Kurzläufe im Unit-Pfad. |
| `tests/testthat/test-fit-grr.R`, `test-fit-rework-inputs.R` | Bestehende Prüfungen um die nun vorgeschriebenen Warnungserwartungen ergänzen. Sämtliche bisherigen Zahlen-, Zählungs- und Fehlerprüfungen bleiben erhalten. |
| `docs/decisions/ADR-<freie Nummer>-m1b-validierungsressourcen.md` | Builder-ADR für Herkunft, öffentliche Vignette, Studienorganisation und Reproduzierbarkeit; Nummer erst nach den Reviewer-ADRs vergeben. |
| `NEWS.md`, `PROGRESS.md` | Englische Verhaltens-/Dokumentationsänderungen bzw. deutscher Fortschritt mit tatsächlich ausgeführten Befehlen, Outputs, Laufzeiten und Grenzen. |
| Zugewiesene Dateien unter `orchestrator/handoff/M1b/` | Bei Bedarf belegte Implementierungs-/Rework-Antworten und einzelne Äquivalenzanträge; keine eigenen Approvals oder Verdicts. |

Abnahmetests, QA-Dateien, `tests/simulation/`, Fixtures, Originalanker,
Specs, BACKLOG, Orchestrator-Zustand, Gate-Auswahl und Toolchain bleiben
in ihren jeweiligen Territorien. `*_results.csv`, `*_replicates.csv`
und `*_session.txt` der Vollläufe im Repository schreibt ausschließlich
der Betreiber nach der Abnahme. Kurzläufe erzeugt BUILD zunächst außerhalb
des Arbeitsbaums und übernimmt sie unter den `*_check_*`-Namen.
Es sind keine Änderungen an `inst/extdata/` vorgesehen.

## Schnittstellen

### Fit, GRR und Diagnosen

Die Argumente, ihre Reihenfolge und Vorgaben bleiben erhalten:

```r
msa_fit(runs, type = c("numeric", "ordinal", "binary"), levels = NULL,
        interactions = NULL, link = c("probit", "logit"), ...)
msa_grr(fit, threshold = NULL, basis = c("study_var", "contribution"))
```

Insbesondere wird die bisherige Probit-Vorgabe auch für binäre Aufrufe
beibehalten. Die Logit-Studien und BeetlesMale-Prüfungen setzen
`link = "logit"` ausdrücklich. Es gibt keinen neuen Export und keine
Änderung an ANK-02.

1. **Eingaben:** Für ordinal/binär werden fehlende Antworten und ordinale
   beziehungsweise binäre Labelwerte außerhalb von `levels` mit benannter
   Warnung und Anzahl entfernt. Faktoren werden danach von unbenutzten
   Stufen bereinigt. `data`, `n$observations`, Stufenzahlen,
   `n$reps_per_cell` und die vom Modell verwendeten Zeilen müssen
   übereinstimmen. Die numerische NA-/NaN-Regel von ADR-022 bleibt bestehen.
2. **Binäre Werte:** Numerische Eingaben und numerisch gelesene Zeichenwerte
   werden vor einer Ganzzahlkonversion auf Endlichkeit und Zugehörigkeit
   zu {0, 1} geprüft. Damit wird insbesondere 0,5 nicht mehr zu 0 gekürzt.
   Logische Eingaben bleiben zulässig. Bei Label-Eingaben bezeichnet die
   zweite der zwei unterschiedlichen, nicht fehlenden Klassen das Ereignis.
   Ungültige numerische Werte enden mit einer Meldung, die „Binary“ nennt.
3. **Frühe Fehler:** Fehlende Gruppierungswerte in item_id, prompt_id,
   model_id oder block werden bei ordinal/binär vor dem Engine-Aufruf
   benannt abgewiesen (ADR-022 Nr. 2, BL-81). Nach Bereinigung führen
   keine auswertbaren Antworten beziehungsweise nur eine beobachtete
   Kategorie zu klaren Fehlern. Für weniger als drei ordinale Items wird
   der bestehende Text „At least three items are needed for ordinal outcomes.“
   unverändert verwendet und wörtlich in der Hilfe dokumentiert.
4. **Konvergenz:** Zusätzliches logisches Feld `converged` der Länge eins;
   bei ordinal/binär TRUE nur bei bestätigter Engine-Konvergenz.
   Auswertung von `clmm$optRes` bzw. `merMod@optinfo$conv`, einschließlich
   der tatsächlichen Konvergenzdiagnosen. Ein von clmm nur gespeicherter
   Nichtkonvergenzcode erzeugt selbst eine Warnung mit „converge“ und
   Engine-Ursache. Bereits ausgegebene Engine-Warnungen werden weitergegeben,
   nicht stumm verworfen. `singular` bleibt eine getrennte Diagnose; eine
   Range-Warnung allein bedeutet keine Nichtkonvergenz. Für numerische
   Objekte wird das additive Feld aus der vorhandenen Enddiagnostik
   abgeleitet, ohne Optimierung oder Warnungspolitik umzubauen.
5. **Zwei Stufen:** Prompt, Modell und Block mit genau zwei beobachteten
   Stufen gehen ordinal als feste Haupteffekte ein; Item bleibt wegen der
   Mindestzahl eine Zufallskomponente. Der Schätzer ist die halbe quadrierte
   Differenz der zwei geschätzten Stufeneffekte. `vc`, dessen Attribut
   `derived` und das bestehende Feld `fit$derived` nennen dieselben Quellen.
   Die Umsetzung darf weder Referenzdaten noch bestimmte Stufennamen
   erkennen; Umbenennung und Vertauschung der Stufen werden geprüft.
   Ein Faktor mit einer Stufe erscheint auch nicht in Interaktionstermen.
6. **Warnung und Druck:** Jeder erfolgreiche ordinale Fit mit solchen
   Komponenten warnt, unabhängig von späterem Drucken. Vorgesehener Text:
   „Two-level component(s) <names> use the range method (beta-hat^2/2),
   with positive bias: E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2;
   see ?msa_fit.“ Beide Druckmethoden nennen jede betroffene Quelle mit
   „range method, see ?msa_fit“. Ohne solche Quelle gibt es keinen
   Range-Hinweis. `msa_grr` erhält dafür additiv `derived` aus
   `attr(fit$vc, "derived")`; seine Kennzahlen bleiben auf der latenten Skala.
7. **Dokumentation:** Hilfe und NEWS erklären Ausschlüsse, Wortlaut der
   Fehler, `converged`, positive Verzerrung, die Studie `two_level` und
   `vignette("validation")`. Kurzläufe werden als Reproduktionsnachweis
   bezeichnet; quantitative wissenschaftliche Befunde folgen erst aus
   den Vollläufen in K-M1d-7.

Die Warnungsänderungen erfordern insbesondere eine Erweiterung von
`test-fit-rework-inputs.R`: Der dortige ordinale Ausschlussfall mit zwei
Modellen und zwei Blöcken erwartet bisher ausschließlich die
Ausschlusswarnung. Künftig muss er zusätzlich die Range-Warnung prüfen,
bei unveränderten bisherigen Aussagen. Pauschales Unterdrücken von
Warnungen ist dafür kein Ersatz.

### Klasse-B-Skripte und Szenarien

CLI nach ACC-2:

```text
Rscript <Pfad>/<studie>.R --n-sim <n> --out <Verzeichnis> --scenarios <ID>[,<ID>...]
```

Die Skripte laden `library(llmsa)` aus der aktiven Bibliothek; gemeinsame
Helfer werden aus diesem installierten Paket über `system.file()` geladen.
Kein `pkgload`, kein Quellbaum-Fallback, keine Abhängigkeit vom
Arbeitsverzeichnis. `--n-sim` und `--out` sind erforderlich;
fehlendes `--scenarios` bedeutet alle Szenarien der Studie.
Unbekannte/mehrfach angegebene Schalter, ungültige oder doppelte
Szenario-IDs, nicht ganze Wiederholungszahlen, `n_sim < 2`,
Seed-Überlauf und unbeschreibbare Ausgaben enden benannt mit Exit ungleich 0.
Ein erfolgreicher Aufruf legt das Ausgabeverzeichnis nötigenfalls an und
schreibt die drei vereinbarten Dateien mit Exit 0.

Die Parameter stammen aus der Tabelle in docs/02, Abschnitt M1b;
sie sind Datenerzeugungsvorgaben, keine empirischen Referenzwerte.
Alle nicht genannten wahren Zufallskomponenten sind null.

| Szenario | Items × Prompts × Modelle × Replikate × Blöcke | Generator und wahre Komponenten |
| --- | --- | --- |
| S-ord-1 | 60 × 3 × 3 × 3 × 1 | Probit, fünf Klassen; Item 1, Prompt 0,0625, Modell 0,09, Item×Modell 0,09, Rest 1. |
| S-ord-2 | 60 × 5 × 3 × 3 × 1 | Wie S-ord-1. |
| S-ord-3 | 60 × 3 × 3 × 3 × 1 | Wie S-ord-1, Item 2,56. |
| S-ord-4 | 100 × 3 × 3 × 3 × 2 | Wie S-ord-1, zusätzlich Block 0,01. |
| S-bin-1 | 60 × 3 × 3 × 3 × 1 | Logit, Interzept 0; Item 1, Prompt 0,1, Modell 0,1, latenter Rest π²/3. |
| S-bin-2 | 60 × 5 × 3 × 3 × 1 | Wie S-bin-1, Interzept 1,5. |
| S-two-1 | 60 × 3 × 2 × 3 × 1 | Probit; Item 1, Prompt 0,0625, Modell 0,05, Rest 1. |
| S-two-2 | 60 × 4 × 2 × 3 × 1 | Wie S-two-1, Modell 0,25. |

Ordinal entstehen je Wiederholung unabhängige normalverteilte Stufeneffekte,
bei S-ord auch Item×Modell-Effekte, sowie Standardnormalrauschen je
Beobachtung. Klassifikation an −1,5/−0,5/0,5/1,5 nach S-ord-1.
Binär werden Bernoulli-Antworten mit `plogis(mu + eta)` erzeugt;
π²/3 ist die theoretische Restvarianz für die Kennzahlen, kein zusätzliches
normalverteiltes Beobachtungsrauschen. Im Zwei-Stufen-Versuch werden beide
Modell-Stufeneffekte in jeder Wiederholung neu aus ihrer vorgegebenen
Verteilung gezogen; eine fest vorgegebene Differenz würde ein anderes
Schätzziel untersuchen.

**PLAN-M1b-SIM-01, zur Bestätigung im PLAN-REVIEW**
(ref: docs/02, M1b-Szenariotabelle S-two-1/S-two-2):
Die Tabelle nennt für S-two keine Klassenzahl und keine Schwellen.
Vorschlag ist dasselbe Fünfklassen-/Schwellenschema wie S-ord-1.
Diese offengelegte Auslegung soll der Reviewer im angekündigten
Simulations-ADR festhalten; sie ist hier noch keine ergänzte Spec.

Für S-ord wird `msa_fit(..., interactions = TRUE)` verwendet, damit
Item×Modell schätzbar ist. Die API nimmt dadurch auch Item×Prompt und
Prompt×Modell auf; ihre wahren Komponenten sind null. Ihre geschätzten
Beiträge gehen regulär in `msa_grr()` ein. S-bin und S-two verwenden
`interactions = FALSE`. S-ord-4 behandelt den Zwei-Stufen-Block nach
K-M1b-4, einschließlich Warnung und abgeleiteter Komponente.
Die Wahrheiten für %GRR und ICC ergeben sich unabhängig aus der
Szenariotabelle: GRR = Summe aller Nicht-Item-Komponenten einschließlich
Rest, TV = GRR + Item, %GRR = 100·sqrt(GRR/TV), ICC = Item/TV.

### Zufall, Ausführung und Ergebnisformat

Vorgesehene feste Seed-Regel: Basis 20261031; die acht IDs erhalten in der
obigen Reihenfolge dauerhaft j = 1,…,8. Für Wiederholung r gilt
`seed(s, r) = 20261031 + j(s) + 8 * (r - 1)`.
Die Zahlen sind offen gewählte Verfahrensparameter, keine Referenzwerte
und keine anhand günstiger Schätzer ausgewählten Seeds.
RNG: `Mersenne-Twister`, `normal.kind = "Inversion"`,
`sample.kind = "Rejection"`.
Szenarioauswahl, deren Reihenfolge, Gesamtzahl der Wiederholungen und
Workerzahl verändern keinen Einzelstrom. Die Ergebnisse werden nach
Szenario, Wiederholung und Schätzziel stabil geordnet.

Parallelisierung erfolgt ausschließlich in `inst/validation/sim/`:
unter WSL per `parallel::mclapply` mit höchstens
`ANK-TOL.sim_runtime.cores` (derzeit 14), eigener Seed-Setzung je Aufgabe
und ohne zusätzliches automatisches Fork-Seeding. Die portable
Ausweichroute ist sequentiell; sie ändert keine Stichprobe.
Keine verschachtelte Parallelisierung. Vor dem Fork werden die verwendeten
Namespaces geladen, damit die Session-Datei auch lme4 und gegebenenfalls
ordinal ausweist. Das Laufzeitbudget wird auf der vorgesehenen WSL-Maschine
gemessen, nicht für die sequentielle Ausweichroute behauptet.

| Datei | Vertrag |
| --- | --- |
| `<studie>_results.csv` | Eine Zeile je Szenario × Schätzziel × Kennzahl; mindestens `scenario, estimand, measure, value, mcse, n_sim, seed`. `seed` nennt den Szenario-Startseed; die Session erklärt die Folge. |
| `<studie>_replicates.csv` | Langformat mit `scenario, rep, estimand, estimate, true, items, prompts, models, blocks, observations`; Designsummen aus dem tatsächlich zurückgegebenen `fit$n`. Dazu deterministische Diagnosefelder und `rep_seed`. Für two_level zusätzlich logisches `derived`: `model` steht tatsächlich in `attr(fit$vc, "derived")`. |
| `<studie>_session.txt` | Tatsächliches `sessionInfo()`, Startseeds und Seed-Regel, RNG, Szenarioauswahl, Aufruf, Workerzahl, Wanduhrzeit und auf Szenario/Wiederholung bezogene Warnungs-/Fehlerdiagnosen. Laufzeit steht ausschließlich hier. |

Pflichtschätzziele: `item`, `prompt`, `model`, für S-ord zusätzlich
`item:model` und bei S-ord-4 `block`; außerdem
`grr_pct_study_var` und `icc_items`. Der durch den Link festgelegte
Rest wird im Fit geprüft und als Wahrheit dokumentiert; er ist nach
ACC-3 kein erforderliches geschätztes Ziel.
Pflichtkennzahlen aller drei Studien sind `bias`, `rel_bias`,
`empse`, `rmse`; für `two_level/model` zusätzlich `derived_share`.

Mit n endlichen Einzelschätzern x und Wahrheit θ werden die Formeln aus
Formelsammlung §9 und ACC-5 umgesetzt:

- Bias = mean(x) − θ; EmpSE = sd(x); MCSE(Bias) = EmpSE/sqrt(n).
- Relative Verzerrung = Bias/θ, MCSE = MCSE(Bias)/abs(θ).
  Die Pflichtwahrheiten sind positiv.
- MCSE(EmpSE) = EmpSE/sqrt(2·(n−1)).
- MSE = mean((x−θ)^2), MCSE(MSE) = sd((x−θ)^2)/sqrt(n);
  RMSE = sqrt(MSE), MCSE(RMSE) = MCSE(MSE)/(2·RMSE).
  Für den exakt fehlerfreien Grenzfall RMSE = 0 werden Wert und MCSE
  als 0 dokumentiert und unit-getestet.
- Anteil abgeleiteter Modellkomponenten p über alle Wiederholungen;
  MCSE = sqrt(p·(1−p)/n_sim), nach ACC-5/der Coverage-Formel.

Fitfehler bleiben als Wiederholung mit `estimate = NA` und benannter
Diagnose erhalten; ihre nicht verfügbaren Fit-Zählungen werden nicht aus
dem Sollplan als angeblicher Fitbefund ergänzt. Ohne zurückgegebenen Fit
ist `derived = FALSE`, da keine abgeleitete Komponente vorliegt.
Endliche singuläre oder nicht konvergierte Schätzer bleiben mit ihren
Flags sichtbar. Die Aggregation nennt die Zahl endlicher und
fehlgeschlagener Schätzungen und nutzt nur endliche Werte für die vier
Leistungsmaße. Weniger als zwei endliche Werte führen zu einem benannten
Abbruch. Kein Nachziehen günstiger Wiederholungen, keine Ersatzwerte.

Die Dateien werden mit festem CSV-Schema und mindestens der in ACC-4
verlangten Genauigkeit geschrieben (`write.csv(row.names = FALSE)`,
15 signifikante Stellen). Alle Replikatspalten müssen den Vergleich
nach elementweisem `format(x, digits = 15)` bestehen.
Bei two_level verlangt die unveränderte Kurzlauf-Abnahme zusätzlich
endliche, nichtnegative Modellschätzer und `derived = TRUE` in jeder
Wiederholung. Ein Verstoß bleibt rot und wird untersucht.

### Vignette und installierbare Ressourcen

Der neue Abschnitt rechnet wine für Logit und Probit gegen direkte clmm-Fits
und zeigt ANK-21 separat für clmm2 mit temp/contact (Laplace und nAGQ = 10).
BeetlesMale wird gemäß ACC-14 auf Population/Prompt/Modell/Replikat
abgebildet. Die endgültige K-M1b-5-Tabelle folgt erst der Betreiberentscheidung
zu ACC-1; Skalenunterschiede dürfen nicht als Übereinstimmung erscheinen.
Paketdatensätze werden mit `utils::data(..., package = ...)` geladen.

Für jede Studie wird im aktuell geladenen Paket zuerst
`<studie>_results.csv`, nur bei deren Abwesenheit
`<studie>_check_results.csv` gelesen. `system.file("validation", "sim", ...)`
ist in beiden Kontexten die Quelle; das gilt auch in der temporären
Paketkopie des Abnahmetests. Eine vorhandene fehlerhafte Volllaufdatei
bewirkt einen benannten Fehler. Tabellen zeigen alle Szenarien und
Pflichtschätzziele mit Bias, relativer Verzerrung, EmpSE, RMSE und MCSE;
two_level zusätzlich den Anteil abgeleiteter Komponenten. `n_sim` und
der Kurz-/Volllaufstatus stammen aus der ausgewählten Datei.
Beim Knitten wird keine Simulation gestartet.

Die Ankerkopien entstehen vollständig und byte-identisch durch den
Offline-Erzeuger. SOURCES nennt Originalpfad, Kopienpfad und beide SHA-256;
Tests prüfen Schema, genaue Dateimenge, Hashes und Drift.
Mit gesetztem `REPO_ROOT` werden Originalanker gelesen, bei fehlenden
Originalen wird abgebrochen. Im öffentlichen Paketbau ohne `REPO_ROOT`
werden die geprüften Kopien verwendet. Nur der Originalvergleich darf im
Standalone-Tarball mangels Repository ausdrücklich überspringen.
Alle Paketressourcenprüfungen bleiben aktiv. Produktfunktionen unter
`R/` lesen keine Ankerkopien.

Empirische Werte, Toleranzen und Ergebniszahlen werden weder in den Rmd-Text
noch in ausgelagerte Helfer übertragen. Die Literalprüfung umfasst auch
Inline-R und rekursiv geladene Helfer; Quellenpfade in `source/sys.source`
bleiben statisch nachvollziehbar. Live-Rechnungen verwenden immer den
aktuell geladenen Namespace, auch während eines Mutationslaufs.

## Reihenfolge

1. **Vertrag abschließen:** ACC-1 durch Betreiberentscheidung lösen;
   Reviewer-ADR zu ACC-2 bis ACC-11 und PLAN-M1b-SIM-01 abwarten.
   Weitere Planrunden beantworten jede Einwand-ID im vorgeschriebenen Format.
   Eine noch offene Spec-Kollision wird nicht durch Produktcode umgangen.
2. **BUILD-Ausgangsstand sichern:** Dateiinventur ohne Git, Abhängigkeiten
   lesend prüfen, schnelle M1b- und betroffene Unit-Tests ausführen,
   rote Befunde mit Output erfassen. M1a-Abschluss in PROGRESS nachtragen.
3. **Fit-Verhalten vollständig umsetzen:** Eingaben, Konvergenz,
   Zwei-Stufen-Komponenten, beide Druckmethoden und Hilfe zusammen ändern;
   erst kleine Engine-/Fehler-/AP1-Regressionen und K-M1b-1/-4/-5/-6 prüfen.
   LESSONS anwenden: alle betroffenen ordinalen/binären Enginegrenzen und
   Diagnoseklassen prüfen, nicht nur einzelne Beispieldaten.
4. **Ressourcen und Studien entwickeln:** Ankerkopien mit Manifest erzeugen,
   ADEMP-Generatoren, feste Seed-Regel, CLI, Kennzahlen und Diagnosen
   implementieren. Handrechnungen und kleine Tests prüfen Formeln,
   Design, ungültige Eingaben, RNG-Rückgabe und Reihenfolgeunabhängigkeit.
5. **Endgültige Kurzläufe erzeugen:** Aktuellen Paketstand in temporärer
   Bibliothek installieren, alle drei Studien mit
   `n_sim = ANK-TOL.n_check` (derzeit 20) vollständig rechnen, Laufzeiten
   messen und nur diese echten Dateien als `*_check_*` übernehmen.
   Mit frisch installierter Paketkopie und fremdem Arbeitsverzeichnis
   unverändert reproduzieren; zusätzlich die n_sim=2-Teilmengen prüfen.
   Nach Fit-/Studienänderungen müssen die betroffenen Kurzläufe vor den
   Gates erneut erzeugt und geprüft werden.
6. **Dokumentation abschließen:** Vignette aus aktuellen Rechnungen und
   Dateien erweitern, roxygen in einer temporären Paketkopie ausführen,
   nur zugehörige Rd-Dateien übernehmen; NEWS, ADR und PROGRESS ergänzen.
   Voll-/Kurzlaufwahl einschließlich öffentlichem Kontext prüfen.
7. **Regression und Übergabe:** M1b-Abnahme, M1a-Regressionsabnahme,
   K-M2-6, Unit-/QA-Suite und Paketbau/-check mit echten Outputs belegen.
   Der Orchestrator führt vollständige kumulative Gates, Territoriumsprüfung
   und Phasen-Commit aus; der Reviewer nimmt ab.
   Danach rechnet der Betreiber die drei Vollläufe mit mindestens
   ANK-06.n_sim_min und stellt die Tripel vor M1d bereit. README/PROGRESS
   enthalten Befehle, Seeds, Versionen und Hochrechnung aus dem Kurzlauf.
   Befundbewertung und Dokumentation der Vollläufe gehören zu K-M1d-6/-7.

## Risiken

### ACC-1: widersprüchliche binäre Referenz

Ref: K-M1b-5 gegen docs/01 §5, Formelsammlung §4 und ANK-28.
Wörtlich verlangt K-M1b-5 eine ICC, die dem Aufruf
„`rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")`“
und „dem publizierten Vignettenwert gleicht“ sowie
„mit `performance::icc()` auf demselben `glmer`-Modell übereinstimmt“.
Dem steht docs/01 §5 gegenüber:
„Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit) (`ANK-28`)“.

Die eigene Rechnung ergibt 0,18793085973874585 für rptR mit Vorgaben
und 0,22329485030354693 auf der vorgeschriebenen latenten Skala.
Die Differenz 0,035363990564801079 überschreitet sowohl
ANK-TOL.rptr.live_tol als auch die Rundungstoleranz von ANK-25.
Das ist keine Optimiererabweichung.

Vorschlag A aus ACC-1 erhält die fachliche Skala. Der Betreiber muss den
Spec-Widerspruch entscheiden; der Reviewer passt danach seinen Vertrag und
die Abnahmetests mit begründetem ADR an. Ein gegebenenfalls nötiger
Ankernachtrag bleibt Reviewer-Territorium mit ADR im selben Meilenstein.
Bis dahin bleibt K-M1b-5 offen; kein Daten-Sonderfall, kein Toleranzwechsel,
keine Selbstfreigabe. Der einzige Human-Touchpoint ist die vom zuständigen
Betreiber/Orchestrator geführte `orchestrator/ESCALATION-M1b.md`;
der Builder schreibt sie in dieser Phase nicht.

### Behandlung der offenen ACCEPTANCE-Einträge

| ID | Planbehandlung |
| --- | --- |
| ACC-1 | Bestätigter Spec-Widerspruch, Entscheidungsvorschlag A und eigener Beleg oben/unten. Nicht als Produktfehler behandeln. |
| ACC-2 | CLI, installiertes Paket, fremdes Arbeitsverzeichnis, Dateinamen und alle Szenarien übernommen. |
| ACC-3 | Pflichtspalten, Schätzziele und alle vier Maße auch für two_level übernommen. |
| ACC-4 | Replikat-Langformat, echte Fit-Zählungen, derived und fehlgeschlagene Fits übernommen. |
| ACC-5 | Formeln und unabhängige Nachrechnung übernommen; exakter Nullfehler-Grenzfall ausdrücklich dokumentiert. |
| ACC-6 | Stabile Streams je ID/Replikat, vollständige Reproduktion und n_sim=2-Teilmengen übernommen. |
| ACC-7 | Session mit tatsächlich geladenen Paketversionen, RNG, Seeds und Laufzeit übernommen. |
| ACC-8 | Wanduhrzeit ohne Installation: ordinal_recovery + binary_recovery zusammen und two_level separat gegen ANK-TOL.sim_runtime. |
| ACC-9 | Bezug auf Referenz-TV, direkte Formelprüfung, Warnung, Drucktext und Hilfeseitenbezug übernommen. |
| ACC-10 | Frühe Fehler, Ausschlusszählung, Nichtkonvergenz, logisches converged, Singularität und BL-81 übernommen. |
| ACC-11 | Exakte Abschnittsüberschrift, Live-Prüfungen, Ergebniswahl im geladenen Paket, dynamisches n_sim und Literalregel übernommen. K-M1b-5 bleibt von ACC-1 abhängig. |
| ACC-12 | [INFRA], Betreiber vor M1b-Gates: teure Skript-/Zusatz-Knit-Tests aus der Mutantenausführung ausnehmen; reguläre Abnahme bleibt vollständig. |
| ACC-13 | rptR und performance in DESCRIPTION/Suggests aufnehmen; Installation verbleibt beim deps-Gate. |
| ACC-14 | Rollenabbildung der beiden Orakeldatensätze und rptR ohne Bootstrap/Permutation übernommen. |
| ACC-15 | [INFRA], Betreiber: fehlerhafter Rollback versionierter Dateien; kein Eingriff des Builders in Orchestrator oder BACKLOG. |
| ACC-16 | Historischer Ausgangslauf und Laufzeiten der Reviewer-Attrappen nur als Planungsinformation. Keine Übernahme von Attrappen oder deren Resultaten. |
| ACC-17 | Quellenhinweis zu ANK-06 berücksichtigt; Mindestzahl aus dem vorhandenen Anker lesen. Intake-Beschaffung bleibt beim Betreiber und blockiert diesen Kurzlaufplan nicht. |

ACC-2 bis ACC-11 sind in CRITERIA als Reviewer-Auslegungen mit angekündigtem
ADR geführt. Dieser Plan akzeptiert sie; er stellt das noch fehlende
Reviewer-ADR nicht selbst aus.

### Laufzeit, Integration und Infrastruktur

- **Laufzeit / ACC-8, BL-12, BL-13:** ANK-TOL setzt derzeit 20 Minuten
  für das Kurzlaufpaar und separat 20 Minuten für two_level auf 14 Kernen.
  ACC-16 nennt für die Reviewer-Attrappe mit Interaktionen etwa
  131–196 Sekunden ordinal, 4–8 Sekunden binär und 15–28 Sekunden two_level.
  Diese Werte sind keine Messung der geplanten Implementierung.
  Eigene Messung und Hochrechnung folgen vor Übernahme der Kurzlaufdateien.
  Ein Überschreiten rechtfertigt weder kleinere Szenarien noch weniger
  Wiederholungen.
- **Mutationsauswahl / ACC-12:** Der konkrete Vorschlag des Reviewers ist
  `MUT_TEST_EXCLUDE='^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full)'`.
  Das ändert ausschließlich der Betreiber. Das Test-Gate muss sämtliche
  K-M1b-Prüfungen weiter ausführen; schnelle Engine-/Diagnoseprüfungen bleiben
  in der Mutation. `config.env` ist bei der lesenden Dateiprüfung dieser
  PLAN-Phase nicht vorhanden; die wirksame Konfiguration ist deshalb durch
  den Betreiber zu prüfen, nicht aus ACC-12 als bereits umgesetzt anzunehmen.
- **Warnungsintegration / K-M2-6:** Die Range-Warnung darf nicht mit den
  Rückfallauslösern von `acmg_convergence_warning()` verwechselt werden.
  Ein echter clmm-Konvergenzcode ohne bisherige Warnung muss künftig auch
  AP1 erreichen. Beide Fälle erhalten ausführbare Regressionen.
- **Numerische Bestandsrisiken:** BL-84, BL-87 und BL-89 werden unten mit
  konkretem Folgezeitpunkt vertagt. Der additive Konvergenzstatus darf
  weder den analytischen REML-Abschluss noch dessen Fehlerpolitik ersetzen.
- **Versionen und Reproduktion / K-M1d-6:** Ergebnisse gelten für den
  protokollierten Paket-/R-/Engine-Stand. Ändert M1c einen für die M1b-Studien
  relevanten Pfad, muss die Präfixreproduktion vor M1d erneut geprüft und
  nötigenfalls der Betreiber-Volllauf erneuert werden. Alte Resultate dürfen
  nicht mit neuen Versionen etikettiert werden.
- **Sandbox / BL-86:** Fehlende lokale Sockets oder Zeitprüfungszugriffe
  werden mit Output als [INFRA] gemeldet. Kein Berechtigungs-Bypass und kein
  selbst erzeugter Ersatz für Gate-Fakten. QA bleibt über den Harness fällig;
  der Builder erstellt keine QA-Dateien.

### Jeder offene BACKLOG-Eintrag

Stand der Inventur: 66 offene Einträge. „Berücksichtigt“ bezeichnet eine
Maßnahme in M1b, keine Schließung durch den Builder. Vertagungen nennen
Zuständigkeit und Anlass der Wiederaufnahme. BACKLOG selbst bleibt unverändert.

| ID | Einordnung und Maßnahme |
| --- | --- |
| BL-01 | Berücksichtigt: M1b auf Kern, drei Kurzläufe und Vignette begrenzen; Betreiber priorisiert AP1 und entscheidet über optionale M3-Meilensteine nach M1d/Frist 26.11. |
| BL-02 | Vertagt an Betreiber für Preprint/Abgrenzung vor BL-10; Literatur-Neuheitsprüfung ist keine Änderung der M1b-Schätzer. |
| BL-03 | In M1b: K-M1b-3/-4, Verzerrungswarnung und two_level. Quantitative Bewertung nach Betreiber-Volllauf, Abnahme K-M1d-7; ein Ersatzverfahren braucht dann einen fachlichen ADR. |
| BL-04 | Vertagt auf M1c-Skript und Betreiber-Volllauf von boot_coverage; Überdeckungsbefunde in M1d. Ordinaler Bootstrap bleibt außerhalb dieses Meilensteins. |
| BL-05 | Bei AP1-Auswertung durch Betreiber weiter nach prior_differs berichten; M1b verändert weder Referenzentscheidungen noch Memorisierungskennzeichen. |
| BL-06 | Betreiber prüft Modellzugang/Umleitung anhand der Harness-Logs; keine Modell-/CLI-/Berechtigungsänderung durch den Builder. |
| BL-07 | Betreiber-Aufgabe im laufenden AP1: Anbieterbelege und Wiederholungstage prüfen; abgenommene Routing-/Metadatenlogik bleibt Regression. |
| BL-08 | Vertagt auf AP7 vor Partnerdatenübermittlung; M1b nutzt öffentliche Orakeldaten und gekennzeichnete Simulationen. |
| BL-09 | Berücksichtigt: nur vorhandene Anker samt Herkunft kopieren; keine Bücher, Original-PDFs oder geschützten Rohdaten ausliefern. Reviewer prüft Zitatumfang. |
| BL-10 | Betreiber entscheidet am 15.11. über Preprint; M1b-Kurzläufe ersetzen weder M1-Abnahme noch abschließende AP1-Auswertung. |
| BL-11 | Betreiber gleicht Kosten mit Dashboard ab; BUILD berichtet Lauf-/Prüfaufwand. Zusätzliche M3-Kostenentscheidung bleibt nach M1d. |
| BL-12 | In M1b: echte Kurzlaufzeiten und Hochrechnung dokumentieren; Betreiber plant die Vollläufe nach Codeabnahme und das Zeitfenster vor M1d. |
| BL-13 | In M1b: beide Runtime-Bedingungen messen; zusätzlich ACC-12 vor Mutationsgates an Betreiber. Gate-Gesamtdauer/Timeouts bleiben Betreiberzuständigkeit. |
| BL-14 | In M1b: unabhängige Engine-/Formelbelege, Randfälle und reproduzierte Studien ergänzen. Bootstrap- und endgültiger ADEMP-Nachweis folgen M1c/M1d. |
| BL-15 | Vertagt auf M3a, K-M3a-2; Fleiss und die Korrektur des Projektdokuments betreffen keine latenten Varianzkomponenten. |
| BL-17 | Vertagt auf M3d, K-M3d-3, und AP2 vor Release; ellmer-Aufzeichnungen/Live-Lauf sind außerhalb M1b. |
| BL-18 | Geteilt vertagt: Bootstrap-Zählung/-Meldung nach K-M1c-2; kanonischer SHA-256-Bericht nach K-M3d-5. |
| BL-20 | In M1b: wine mit msa-Formel gegen clmm; ANK-21 nur für das ausdrücklich andere clmm2-Modell als Installationsprüfung. |
| BL-21 | Reviewer prüft Zuordnung der geschachtelten NIST-Fallstudie bei einer späteren Ankererweiterung; kein M1b-Kriterium und kein zusätzlicher Modelltyp. |
| BL-22 | Berücksichtigt als Regression: gepooltes AIAG-Beispiel und Bericht mit Interaktion aus M1a bleiben erhalten. Keine Umdeutung des Poolings. |
| BL-23 | Berücksichtigt als Regression: NIST-LRE und Bericht höherer Schwierigkeit in der Vignette erhalten; keine neue Präzisionsregel in M1b. |
| BL-24 | Betreiber setzt/prüft Mutationsbaseline beim Scope-Wechsel vor M3a; M1b nutzt den unveränderten Kern-Scope. |
| BL-25 | Berücksichtigt: Originalanker nur lesen; jede nachträgliche Ankeränderung liegt mit ADR beim Reviewer. Kopien danach kontrolliert neu erzeugen. |
| BL-28 | Betreiber verwaltet AP1-Konten, Limits und Geheimnisse; keine Schlüssel-/Kontoarbeit für diesen statistischen Plan erforderlich. |
| BL-29 | Betreiber klärt Infevers vor Veröffentlichung von INSAID-Klassen; M1b erzeugt keine solchen Inhalte. |
| BL-30 | Vertagt an Betreiber für AP2/Release: Pages, About, Topics, Zenodo und DOI sind Veröffentlichungsschritte. |
| BL-31 | Betreiber prüft Commit-Identität vor Push; der Builder führt keine Git-Kommandos aus. |
| BL-33 | Betreiber verantwortet PREFLIGHT und CLI-Sandbox; keine entsprechende Konfigurationsänderung in M1b. |
| BL-34 | Betreiber hält Erreichbarkeit für Eskalationen im RUNBOOK fest; ACC-1 läuft ausschließlich über den vorgesehenen M1b-Eskalationsweg. |
| BL-35 | Vertagt an Template-Betreiber; notify-Verhalten ist unabhängig vom Statistikcode. |
| BL-36 | Betreiber entscheidet bei Bedarf über WSL-Dateisystemumzug; M1b misst Studienlaufzeit und belässt Rohdaten außerhalb. |
| BL-37 | Wie BL-11 an Betreiber für Kostenspur/Dashboard; keine Harness-Erweiterung im Builder-Territorium. |
| BL-39 | Betreiber beschafft Quellen für die jeweils betroffenen späteren Aufgaben; die geernteten M1b-Anker erfordern hier keinen Ersatz aus Modellwissen. |
| BL-40 | Vertagt auf Reviewer-ACCEPTANCE von M1d und Betreiber-Beschaffung fehlender Konkordanzquellen; kein M1b-Literaturvergleich. |
| BL-41 | Betreiber klärt Quelle vor Nutzung der Kappa-Bandnamen im AP1-Bericht; M1b ändert diese Bänder nicht. |
| BL-42 | Bestehendes AIAG-Blatt bleibt Voraussetzung der M1a-Regression; weitere Datenblätter rechtzeitig vor M3a/M3b durch Betreiber, Abgleich durch Reviewer. Fehlen erzeugt Fehler, keinen Skip. |
| BL-43 | Betreiber prüft Modellkennungen/Preise für AP1 live; M1b benötigt keine Anbieteraufrufe. |
| BL-44 | Vertagt auf M3a/K-M3a-2; Fleiss-Standardfehler nur nach passender Quelle, nicht als Nebenarbeit in M1b. |
| BL-45 | Betreiber pflegt externe Projektdokumente nach Meilensteinabschluss; BUILD liefert dafür PROGRESS und belegte Grenzen. |
| BL-46 | In M1b: Vignette liest Studienergebnisse und startet keine Kurzläufe; Check-Laufzeit messen. Vier-Vignetten-Budget erneut vor M1d prüfen. |
| BL-47 | Betreiber beachtet Autorenzuordnung in Veröffentlichungen; VariantBench bleibt außerhalb des Itemsatzes und M1b. |
| BL-48 | Reviewer/Betreiber prüfen Kriterien-Gate-Zuordnung, einschließlich K-M1b-7/lint; maschinelle Trace-Erweiterung bleibt Harness-Arbeit. |
| BL-49 | Berücksichtigt als M1a-Regression: bestätigte bobyqa-Steuerung und TV-bezogene Toleranz bleiben. Ordinale Enginevergleiche verwenden ihren eigenen Ankereintrag. |
| BL-50 | Vertagt auf M3c/K-M3c-6; Planungs-CV ist eine zu berichtende Näherung und kein neues M1b-Bestehenskriterium. |
| BL-51 | Vertagt bis nach AP1 an Betreiber/Reviewer für Export-ADR; acmg bleibt intern. M1b ergänzt keine Exporte. |
| BL-52 | Berücksichtigt: AP1-Zahlen bleiben vorläufig bis nach M1-Abnahme; Betreiber wiederholt Auswertung mit demselben externen Store. |
| BL-55 | Berücksichtigt als Betriebsgrenze: keine parallelen Betreiberdateien im Arbeitsbaum während Modellphasen; Rollback-Korrektur zusammen mit ACC-15 beim Betreiber. |
| BL-57 | Berücksichtigt: keine neuen Argumente; vorhandene Positionen/Vorgaben gegen ANK-02 prüfen. Reviewer behält Prüfung künftiger Default-Anhänge. |
| BL-60 | Vertagt auf Vorbereitung von M3d/K-M3d-3; Streaming-/httr2-Mockfähigkeit von ellmer gehört zur Backend-Abnahme. |
| BL-64 | Vertagt auf AP1-Berichtspflege bzw. M3d: Pilotquantil vom Kappa-Quantil entkoppeln nach ADR-006; keine Wirkung auf den unveränderten Plan mit Typ 7. |
| BL-68 | Vertagt auf nächsten freigegebenen AP1-Bericht-/CLI-Build vor Endbericht: Herkunftsmeldung nach Erhebung präzisieren; Store-Verhalten bleibt gleich. |
| BL-70 | Betreiber führt Template-Befunde weiter; Status, Timeout, STOP und Log-Ignore-Regeln liegen außerhalb dieses Plans. |
| BL-71 | Betreiber entscheidet vor endgültiger AP1-Auswertung über Historienkennzeichen/Limitations, bei Golden-Änderung mit ADR; M1b ändert keine Referenzdaten. |
| BL-72 | Berücksichtigt: portable Pfade und explizite, fehlertoleranzfreie Ankerzugriffe verwenden; bestehende numerische Tests behalten ihre bestätigten Toleranzen. |
| BL-73 | Vertagt auf AP1-Berichtspflege vor Endbericht: Kosten-/Reasoning-Spalten erläutern und Nachrechnung für Sol ergänzen; keine Statistik-Abhängigkeit zu M1b. |
| BL-74 | Betreiber plant AP1-Blöcke und gegebenenfalls Parallelisierung per ADR; Modellaufrufe sind nicht Teil der Simulationsstudien. |
| BL-75 | Vertagt auf AP1-Berichtspflege vor Endbericht: Netzwartezeit bei Latenzkennzahlen berücksichtigen; M1b arbeitet ohne API-Latenzen. |
| BL-77 | Berücksichtigt: Zitate mit überprüfbarer Fundstelle, Fremdmessungen als solche markieren; QA-Prompt-/Templatekorrektur beim Betreiber/Reviewer. |
| BL-79 | [INFRA], Betreiber archiviert vollständige Mutationsberichte je Runde; Builder belegt Claims nur am tatsächlich verfügbaren aktuellen Bericht. |
| BL-80 | Betreiber berichtigt Spec-Text zu NIST-Offsets bei Gelegenheit; numerische Kriterien, Anker und Tests bleiben unberührt. |
| BL-81 | In M1b verpflichtend: Gruppierungs-NA bei ordinal/binär benannt ablehnen und Zählungen gegen Modell prüfen (ADR-022 Nr. 2, K-M1b-6). |
| BL-84 | Nonblocking vertagt auf M1c zusammen mit mutfull/numerischer Robustheit: Darstellbarkeitsfälle, redundante Prüfungen und toter Default; keine rein scoregetriebene Änderung in M1b. |
| BL-85 | [INFRA], Betreiber verbessert Approval-Zuordnung; Reviewer prüft in jeder Runde Quelltext und neue Zeilen. Builder übernimmt keine alten Freigaben als eigene Genehmigung. |
| BL-86 | [INFRA], Mutationstreiber/Zeituhr im regulären Gate betreiben; lokale Grenzen mit Output melden, weder Socket-Freigabe noch Check-Regeln umgehen. |
| BL-87 | Vertagt auf M1c-BUILD vor dessen Volllauf und vor M1d: numerischer Abschluss bei hoher Wiederholpräzision, erweitertes Raster und E59-Warnungsreihenfolge. M1d darf nur noch dokumentieren; daher nicht bis M1d-BUILD aufschieben. |
| BL-89 | Nonblocking vertagt auf M1c-BUILD zusammen mit den numerischen Regressionen, spätestens vor erstem macOS-/Windows-Releasecheck. Falls CI früher ansteht, Betreiber-Auftrag vorziehen; Erfolgsfälle gegen Orakel, Fehlerfälle gegen dokumentierte Präzisionsdiagnosen und synthetische Fehlerverträge prüfen. |

Die im BACKLOG bereits erledigten Einträge werden nicht wieder geöffnet:
BL-16, BL-19, BL-26, BL-27, BL-32, BL-38, BL-53, BL-54, BL-56,
BL-58, BL-59, BL-61, BL-62, BL-63, BL-65, BL-66, BL-67, BL-69,
BL-76, BL-78, BL-82, BL-83 und BL-88. Ihre bestehenden
Regressionsprüfungen und dauerhaften Betriebsregeln bleiben maßgeblich.

## Testplan

### Prüfungen im BUILD und durch die Gates

| Kriterium | Unveränderter Abnahmeweg und ergänzender Builder-Nachweis |
| --- | --- |
| K-M1b-1 | `test-m1b-1-engine-ordinal.R`: wine mit beiden Links gegen direktes clmm; Rest gegen ANK-28; GRR gegen unabhängige Formeln; clmm2-Installationsprüfung Laplace/nAGQ gegen ANK-21. Komponentenfehler ≤ ANK-TOL.engine_ordinal.rel_tol × Referenz-TV, abgeleitete Maße relativ, ndc gleich. |
| K-M1b-2 | `test-m1b-2-recovery-scripts.R`: beide Skripte, alle sechs Szenarien, Schema, wahre Komponenten, echte Fit-Zählungen, MCSE-Nachrechnung, Session, vollständige Reproduktion und gemeinsame Laufzeit. Teilmengen mit n_sim=2: S-ord-2/S-ord-4 und S-bin-2. |
| K-M1b-3 | `test-m1b-3-two-level-script.R`: beide Szenarien, beta-hat²/2 und derived, alle Maße einschließlich RMSE/derived_share, Neulauf und eigener Runtime-Nachweis; Präfixprüfung S-two-2 mit n_sim=2. |
| K-M1b-4 | `test-m1b-4-two-levels.R`: fester statt zufälliger Effekt bei zwei Modellen/zwei Blöcken; Varianz der Stufeneffekte gegen direktes clmm; Warnung, beide Druckmethoden und Rd-Verweis; Gegenfall mit drei Stufen. Zusätzliche Unit-Fälle für zwei Prompts, mehrere Zwei-Stufen-Faktoren und umbenannte/vertauschte Stufen. |
| K-M1b-5 | `test-m1b-5-binary-rptr.R`: aktueller Vertrag bleibt bis ACC-1-Entscheidung unverändert und rot. Danach ausschließlich den durch Betreiber/Reviewer beschlossenen Vertrag prüfen; Live-rptR, performance und Formelrechnung bleiben unabhängige Belege, ANK-25 wird nicht aus einem Paketlauf neu erfunden. |
| K-M1b-6 | `test-m1b-6-edge-cases.R`: ein/zwei Items, eine Kategorie, fehlende/ungültige Antworten, Labelausschluss, binär −1/0,5/2, forcierte Nichtkonvergenz beider Engines und positive Gegenfälle, Singularität, Einstufenfaktoren, alle vier fehlenden Gruppierungsfelder. |
| K-M1b-7 | `test-m1b-7-vignette.R` und `test-m1b-7-vignette-full-results.R`: Abschnitt, tatsächliches Knitten, Anker-/Livewerte, alle Tabellen, n_sim, Literalregel und Auswahl vorhandener Volllaufdateien in temporärer öffentlicher Paketkopie. Lint-Gate trägt den Paketbau ohne ERROR/WARNING. |

Zusätzliche Unit-/Property-Prüfungen bleiben klein und haben einen
unabhängigen Maßstab:

- Diagnosematrix über beide Zieltypen/Links, mehrere kleine Pläne und Seeds,
  fehlende Werte, Randkomponenten, unbalancierte Zellen und enge
  Optimiererlimits; richtige Zahl gegen direktes Engine-Modell oder benannte
  Fehlermeldung. Injizierte Bedingungen prüfen gezielt die Warnungsweitergabe,
  ersetzen aber nicht die echten Engine-Gegenfälle.
- Zeilenpermutation und Stufenumbenennung; bei ordinal zusätzlich Vertauschung
  der beiden festen Stufen. Toleranzen aus ANK-TOL, kein Aufweiten nach
  einem Fehlschlag. Skalierungs-/Verschiebungsinvarianz numerischer Werte
  bleibt Gegenstand der unveränderten M1a-Regression.
- Handrechnung der Leistungsmaße auf kleinen ausdrücklich synthetischen
  Schätzervektoren, einschließlich NA-/Nullfehlerfällen und Nennern.
  Die Abnahme rechnet separat aus den gespeicherten Replikaten nach
  (ANK-TOL.arithmetic.abs_tol).
- Gleiche ersten Replikate bei größerem n_sim, anderer Szenarioauswahl,
  umgekehrter Auswahlreihenfolge und anderer Workerzahl; keine
  Laufzeit-/Versionsfelder im Replikatvergleich.
- CLI-Fehlerfälle, Schema-/Hash-/Ankerdrift, fehlende Originale, fehlende und
  beschädigte Resultate, Voll-/Kurzlaufwahl; Negativfälle nur in temporären,
  ausdrücklich synthetischen Kopien.
- AP1: Range-Warnung erhalten ohne numerischen Rückfall; echte
  Konvergenzwarnung erhalten mit Rückfall. K-M2-6 und bestehende QA bleiben
  Regression; kein echter API-Aufruf.

Vorgesehener eigener M1b-Prüfaufruf aus der Repo-Wurzel, erst in BUILD:

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath(".")); grDevices::pdf(NULL); testthat::set_max_fails(Inf); testthat::test_dir("tests/acceptance", filter = "^m1b-", load_package = "source", reporter = "summary", stop_on_failure = TRUE)'
```

M1a und K-M2-6 werden entsprechend mit den Filtern `^m1a-` und
`^m2-6-` geprüft; Unit/E2E/Fuzz über den unveränderten Testtreiber.
Der eigene Filter ist eine Diagnose, keine Änderung der Gate-Auswahl.
Git-verwendende M0-Prüfungen, Verifier, Mutation-Gates und Zustandsführung
verbleiben beim Orchestrator.

Paketbau und `R CMD check --as-cran --no-manual` erfolgen außerhalb des
Arbeitsbaums aus einer Positivlisten-Kopie der Paketdateien: einmal
öffentlich ohne `REPO_ROOT`, einmal im dokumentierten vollständigen
Kontext. Kein Download beim Knitten, keine Abhängigkeitsinstallation durch
den Builder. Geschützte AIAG-Rohdaten werden nicht ausgeliefert.
Neue Unit-Tests müssen auch im installierten Paket laufen.
Warnungen aus neu vorgeschriebenem Fitverhalten werden gezielt geprüft;
bestehende Abnahmekriterien, Schwellen und Golden-Werte werden nicht
abgeschwächt.

Mutation: geänderte Kernlogik bleibt in `R/fit.R` und `R/grr.R`;
Floor/Ratchet und deren Gate-Berechnung bleiben erhalten.
Die schnelle Suite muss die neuen falschen Verhaltensweisen erkennen
(z. B. stilles Abrunden binärer Werte, fehlende Warnung oder verlorenes
derived). Lange Studien gehören nach ACC-12 nicht in jede Mutation.
Ein lokaler Diagnoselauf ist kein Gate-Score. Etwaige Äquivalenzen werden
einzeln mit aktuellem Quelltext belegt und nur vom Reviewer genehmigt.

### Bereits ausgeführte lesende PLAN-Diagnose

Am 31.10.2026 wurde folgender Befehl ausgeführt (Exit 0). Er prüft den
Widerspruch mit installierten Orakeln; er lädt oder ändert keinen
llmsa-Produktcode und ist kein Abnahmelauf.

```bash
Rscript --vanilla - <<'RS'
for (p in c('lme4', 'rptR', 'performance', 'jsonlite')) {
  if (!requireNamespace(p, quietly = TRUE)) stop('Missing diagnostic dependency: ', p)
}
e <- new.env()
utils::data('BeetlesMale', package = 'rptR', envir = e)
d <- e$BeetlesMale
m <- lme4::glmer(Colour ~ (1 | Population), data = d, family = stats::binomial('logit'))
r_default <- rptR::rptBinary(Colour ~ (1 | Population), grname = 'Population', data = d, link = 'logit', nboot = 0, npermut = 0)
r_liability <- rptR::rptBinary(Colour ~ (1 | Population), grname = 'Population', data = d, link = 'logit', nboot = 0, npermut = 0, expect = 'liability')
v <- as.numeric(lme4::VarCorr(m)$Population)
a <- jsonlite::fromJSON('reference/anchors/ANK-25.json')
tol <- jsonlite::fromJSON('reference/anchors/ANK-TOL.json')$value$rptr
values <- c(population_variance = v, rpt_default_link = r_default$R['R_link', 'Population'], rpt_liability_link = r_liability$R['R_link', 'Population'], performance_adjusted = performance::icc(m)$ICC_adjusted, latent_formula = v / (v + pi^2 / 3), anchor_vignette = a$value$link_scale, live_tolerance = tol$live_tol, vignette_tolerance = tol$vignette_tol)
cat('R ', as.character(getRversion()), '\n', sep = '')
for (p in c('lme4', 'rptR', 'performance')) cat(p, ' ', as.character(utils::packageVersion(p)), '\n', sep = '')
for (n in names(values)) cat(n, ' = ', format(values[[n]], digits = 17), '\n', sep = '')
cat('absolute_scale_difference = ', format(abs(values[['rpt_default_link']] - values[['latent_formula']]), digits = 17), '\n', sep = '')
stopifnot(abs(values[['rpt_default_link']] - values[['latent_formula']]) > tol$live_tol,
          abs(values[['rpt_default_link']] - values[['anchor_vignette']]) <= tol$vignette_tol,
          abs(values[['rpt_liability_link']] - values[['latent_formula']]) <= tol$live_tol,
          abs(values[['performance_adjusted']] - values[['latent_formula']]) <= tol$live_tol)
cat('ACC-1 scale conflict reproduced; no acceptance verdict.\n')
RS
```

Tatsächlicher Output:

```text
R 4.6.1
lme4 2.0.6
rptR 0.9.23
performance 0.19.0
population_variance = 0.94580371035167532
rpt_default_link = 0.18793085973874585
rpt_liability_link = 0.22329485030354693
performance_adjusted = 0.22329485030354818
latent_formula = 0.22329485030354693
anchor_vignette = 0.188
live_tolerance = 9.9999999999999995e-07
vignette_tolerance = 0.00050000000000000001
absolute_scale_difference = 0.035363990564801079
ACC-1 scale conflict reproduced; no acceptance verdict.
```

In dieser PLAN-Phase wurden keine Abnahmesuite, Simulation, Paketprüfung
oder Gates ausgeführt und keine Git-Kommandos verwendet. Eine fachliche
Erfüllung von K-M1b-1 bis K-M1b-7 wird damit nicht behauptet.

