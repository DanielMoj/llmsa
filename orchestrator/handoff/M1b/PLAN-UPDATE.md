# PLAN-UPDATE — M1b, Runde 2

Stand: 31.10.2026. Rolle: Builder, Phase `20-plan`, Runde 2.
Diese Phase schreibt ausschließlich `orchestrator/handoff/M1b/PLAN-UPDATE.md`.
Alle nachfolgend beschriebenen Produktänderungen gehören zum späteren BUILD.
Dieses Update ergänzt `PLAN.md` aus Runde 1 und ersetzt dessen hier ausdrücklich
berichtigte Aussagen. Die übrigen dort angenommenen Verträge gelten weiter.

## Ziel

K-M1b-1 bis K-M1b-7 umsetzen: ordinale und binäre Fits mit nachvollziehbaren
Diagnosen, das gekennzeichnete Zwei-Stufen-Ersatzverfahren, drei ADEMP-Skripte
mit reproduzierten Kurzläufen und den neuen Abschnitt der Validierungsvignette.
Die quantitative Bewertung der Vollläufe folgt in K-M1d-6/-7.

E1 ist durch die berichtigte Spec, ADR-024 und die aktuelle `ARBITER.md`
aufgelöst. ICC_items bei Logit verwendet weiterhin die latente Restvarianz
π²/3. ANK-25 prüft ausschließlich die Installation von rptR mit dessen
Vorgabeaufruf. Ein offener Spec-Widerspruch zu K-M1b-5 wird nicht fortgeführt;
eine Erfüllung des Kriteriums wird damit noch nicht behauptet.

Gelesene Grundlage: `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, der vollständige `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, die aktuelle
M1b-`CRITERIA.json`, `PLAN.md`, `PLAN-REVIEW.md` und die bindende `ARBITER.md`.
Außerdem: alle acht M1b-Abnahmedateien, `setup-m1b.R` und das gemeinsame
Setup, die betroffene K-M2-6-Abnahme, docs/01 insbesondere §§1–9,
docs/02 insbesondere M1b und K-M1d-6/-7, Formelsammlung §§3, 4 und 9,
ANK-06/-21/-25/-28 und die einschlägigen ANK-TOL-Einträge, ADR-018/-022/-023/-024
sowie die einschlägigen Numerik- und Ressourcenentscheidungen aus ADR-020/-021.
Der bestehende Fit-/GRR-Code, AP1-Rückfall, betroffene Unit-Tests, DESCRIPTION
und Vignette wurden lesend abgeglichen. LESSONS wird durch die unten geplante
Prüfung ganzer Diagnoseklassen berücksichtigt.

### Antworten auf die Einwand-IDs

- **E1 — akzeptiert:** Die Direktive aus `ARBITER.md`, E1 Nr. 1–6, wird
  vollständig übernommen. Maßgeblich ist K-M1b-5 in `docs/02-statistikkern.md:43`
  nach ADR-024 Nr. 1, mit den in der wiederholten ACCEPTANCE-Phase angepassten
  Tests. Die als offen geführten Passagen in `PLAN.md` Z. 16–25, 330–333,
  369–392, 398 und 408 sind erledigt und durch dieses Update ersetzt. Z. 545
  wird durch die neue K-M1b-5-Zeile im Testplan unten ersetzt; Z. 296–298 durch
  den Vignettenvertrag unten. Auch der historische Schlusssatz zur noch
  ausstehenden Reviewer-Auslegung nach der ACC-Tabelle gilt nicht mehr:
  ADR-023 liegt vor. ANK-25, ANK-28 und ANK-TOL bleiben unverändert.
- **E2 — akzeptiert:** ADR-023 Nr. 10.9 wird übernommen: Erfolgscodes des
  tatsächlich verwendeten Optimierers, getrennte Singularitätsdiagnose und
  keine eigenen Gradient-/Hesse-Schwellen. Die verbindliche Regel für
  numerische Fits wird unter „Schnittstellen“ ergänzt. Unit-Tests prüfen
  ucminf-Erfolg, tatsächlichen nlminb-Fallback, singulären glmer-Erfolg und
  erzwungene Nichtkonvergenz sowie die numerischen Enddiagnosen.
- **E3 — akzeptiert:** Binäre Labels erfordern das Argument `levels` mit
  genau zwei verschiedenen, nicht fehlenden Werten. `levels[2]` bezeichnet
  das Ereignis. Labels ohne `levels` bleiben ein benannter Fehler; weder
  Auftretensreihenfolge noch Faktorstufen ersetzen dieses Argument.
  Zeilenpermutation und Vertauschen von `levels` erhalten eigene
  Invarianzprüfungen mit ANK-TOL.invariance.
- **E4 — akzeptiert:** Die unqualifizierte Gleichsetzung von β̂²/2 mit dem
  AIAG-Handbuchverfahren entfällt. Hilfe und NEWS erläutern die fehlende
  Korrektur EV²/(n·r) und die positive Verzerrung. Beide Druckmethoden geben
  je abgeleiteter Quelle eine Zeile mit deren Namen und dem vollständigen
  Text „range method, see ?msa_fit“ aus; dort entfällt die AIAG-Gleichsetzung.
- **E5 — akzeptiert:** Vor einem Abbruch wegen weniger als zwei endlichen
  Schätzern werden Replikat- und Session-Datei gesichert. Die Session nennt
  Szenario, Schätzziel und Fehler; Exit ungleich 0, keine Ergebnisdatei dieses
  Laufs. Die README beschreibt je Studie einen vollständigen Aufruf und die
  kontrollierte Zusammenführung disjunkter Szenarioläufe zu einem Tripel
  für K-M1d-6, ohne Einzelschätzer neu zu berechnen.
- **E6 — akzeptiert:** Jede Nutzung eines Suggests-Pakets in den neuen oder
  betroffenen Unit-Tests steht hinter `testthat::skip_if_not_installed()`;
  das gilt auch vor dem Laden eines Helfers, der das Paket benötigt.
  `rptR`, `performance` und `parallel` werden unter Suggests ergänzt.
  Die Abnahmetests bleiben ohne solche Skips; Installationen erfolgen im
  deps-Gate. Es entsteht kein neuer Import.
- **E7 — akzeptiert:** Keine Builder-Änderung. ADR-024 Nr. 3 und die aktuelle
  CRITERIA ACC-12 melden die Mutationsauswahl als erledigt. Die Aussage aus
  PLAN.md, `config.env` sei nicht vorhanden, wird berichtigt: Laut
  PLAN-REVIEW E7 existiert sie, war aber für den damaligen Builder nicht
  lesbar. Die Umsetzung ist hier ein gelesener Betreiber-/Reviewer-Beleg,
  keine eigene Konfigurationsprüfung. Das Test-Gate führt weiterhin alle
  M1b-Abnahmetests aus.
- **E8 — akzeptiert:** Keine Builder-Änderung. ADR-024 Nr. 4 und CRITERIA
  ACC-15 melden die Korrektur des Rollbacks versionierter Dateien als
  erledigt. Eine eigene Rollback-Probe oder ein Git-Aufruf erfolgt nicht.
  Die allgemeine Betriebsregel aus BL-55 bleibt bestehen; die Übernahme der
  Korrektur in das Harness-Template bleibt Betreiberarbeit.

**ADR-023 Nr. 13 / PLAN-M1b-SIM-01 — akzeptiert:** Die in Runde 1 vorgeschlagene
S-two-Datenerzeugung ist jetzt entschieden. Beide S-two-Szenarien verwenden
Probit, fünf Klassen und die Schwellen −1,5/−0,5/0,5/1,5; beide Modellstufen
werden je Wiederholung neu gezogen. S-two und S-bin verwenden
`interactions = FALSE`, S-ord verwendet `interactions = TRUE` einschließlich
der beiden zusätzlichen Wechselwirkungen mit wahrer Varianz null.
Der Zwei-Stufen-Block von S-ord-4 wird fest und abgeleitet behandelt.
ADR-023 Nr. 1–13 wird im Ganzen übernommen; Nr. 11.4 und 11.7 werden für den
K-M1b-5-Teil gemäß ADR-024 und ACC-18 konkretisiert.

**ACC-18 — akzeptiert:** Die Vignette zeigt beide publizierten Punktschätzer
aus ANK-25 als Installationsprüfung und die beobachtete ICC_items auf
BeetlesMale, nennt ANK-28 sowie beide Einträge von ANK-TOL.rptr und erweitert
die Literalregel um den Logit-Wert aus ANK-28. Das angekündigte Reviewer-ADR
zu ADR-023 Nr. 11.4/11.7 gehört in `30-plan-review`, Runde 2; der Builder
schreibt in dieser PLAN-Phase kein ADR und ändert keine Abnahmedatei.

## Dateien

Die vollständige BUILD-Dateiliste aus PLAN.md gilt mit folgenden Präzisierungen.
Die nachstehenden Pfade sind keine Schreibfreigabe für diese PLAN-Phase.

| Pfad im späteren BUILD | Änderung |
| --- | --- |
| `R/fit.R` | Eingabediagnosen und BL-81, exakte Binärkodierung, additives `converged`, Range-Warnung und Druckzeilen, roxygen; E2–E4. |
| `R/grr.R` | Additives `derived` aus `attr(fit$vc, "derived")`, Druckzeilen und Dokumentation; E4. |
| `man/msa_fit.Rd`, `man/msa_grr.Rd` | Aus roxygen erzeugte Hilfe; Fehlerwortlaut, Konvergenzregel, Ersatzverfahren und Verweise auf `two_level`/`validation`. |
| `DESCRIPTION` | Suggests um `rptR`, `performance`, `parallel` ergänzen; Matrix-Import nach ADR-020 beibehalten; E6/ACC-13. |
| `inst/validation/sim/{ordinal_recovery,binary_recovery,two_level}.R` | Drei CLI-Einstiege nach ADR-023. |
| `inst/validation/sim/simulation_helpers.R`, `inst/validation/sim/README.md` | Generatoren, feste Zufallsströme, Kennzahlen, Diagnosesicherung und Dateiausgabe; ausführbare Anleitung zum Vollauf und zum Zusammenführen von Szenarioläufen, E5. |
| `inst/validation/sim/<studie>_check_{results.csv,replicates.csv,session.txt}` | Neun echte Kurzlaufdateien, erzeugt mit dem endgültigen BUILD-Stand. |
| `data-raw/make_validation_latent.R` | Offline-Erzeuger vollständiger Ankerkopien und Herkunftsmanifest. |
| `inst/validation/latent/anchors/{ANK-06,ANK-21,ANK-25,ANK-28,ANK-TOL}.json`, `inst/validation/latent/{SOURCES.json,README.md,reference_checks.R}` | Geprüfte Ankerkopien und Live-Prüfungen; beide Teile von K-M1b-5, ACC-18, Ergebniswahl. |
| `vignettes/validation.Rmd` | Abschnitt „Ordinal and binary outcomes (latent scale)“ mit aktualisierter K-M1b-5-Prüfung; numerischen Abschnitt erhalten. |
| `tests/testthat/helper-validation-latent.R`, `test-fit-latent.R`, `test-fit-latent-diagnostics.R`, `test-grr-latent.R`, `test-validation-simulation.R`, `test-validation-latent.R`, `test-acmg-latent-diagnostics.R` | Kleine unabhängige Nachrechnungen und Regressionen zu E1–E6; keine vollständigen Kurzläufe im Unit-Pfad. |
| `tests/testthat/test-fit-grr.R`, `tests/testthat/test-fit-rework-inputs.R` | Die neu vorgeschriebenen Warnungen gezielt erwarten; alle bisherigen Zahlen-, Zählungs- und Fehlerprüfungen erhalten. |
| `docs/decisions/ADR-<freie Nummer>-m1b-validierungsressourcen.md`, `NEWS.md`, `PROGRESS.md` | Builder-Entscheidungen, englische Paketänderungen, deutsche Prüfbelege; ADR-Nummer nach den Reviewer-ADRs dieser Runde wählen. |

Originalanker, Golden-Daten, Specs, BACKLOG, Abnahmetests, QA-Dateien,
`tests/simulation/`, Fixtures, Gate-Auswahl und Orchestrator-Zustand gehören
weiterhin den zuständigen anderen Rollen. Die Volllaufdateien ohne `_check_`
schreibt und committet ausschließlich der Betreiber nach M1b-Abnahme.
Der Orchestrator erstellt auch den Phasen-Commit dieses Updates.

## Schnittstellen

### Fit, Kodierung und Konvergenz

Die öffentlichen Argumentlisten, ihre Vorgaben und Positionen bleiben:

```r
msa_fit(runs, type = c("numeric", "ordinal", "binary"), levels = NULL,
        interactions = NULL, link = c("probit", "logit"), ...)
msa_grr(fit, threshold = NULL, basis = c("study_var", "contribution"))
```

Es gibt keine neuen Exporte. Die Probit-Vorgabe bleibt auch binär erhalten;
BeetlesMale und S-bin setzen Logit ausdrücklich. ANK-02 wird nicht geändert.

Binäre numerische Werte und ohne `levels` numerisch gelesene Zeichenwerte
werden vor jeder Ganzzahlkonversion auf Endlichkeit und Mitgliedschaft in
{0, 1} geprüft; 0,5 wird nicht gekürzt. Logische Werte bleiben zulässig.
Bei Labels bestimmt allein das validierte Argument `levels` die Kodierung:
`levels[1]` → 0, `levels[2]` → 1. Ungültige Längen, doppelte oder fehlende
Klassen im Argument sowie Labels ohne `levels` enden benannt. Werte außerhalb
eines gültigen Labelvektors und fehlende Antworten werden mit Warnung und
Anzahl entfernt. `data`, `n`, `nobs(model)` und die tatsächlich verwendeten
Stufen beziehen sich auf dieselben verbliebenen Zeilen. Keine Kategorie oder
nur eine beobachtete Kategorie führt zu einem benannten Fehler, nie `NaN`.
Fehlende Gruppierungswerte werden nach ADR-022 Nr. 2/BL-81 vor dem Fit
abgewiesen. Die numerische NA-/NaN-Regel bleibt bestehen.

`converged` ist logisch, Länge eins, ohne `NA`. Es bezeichnet die bestätigte
Enddiagnose des zurückgegebenen Modells, unabhängig vom Feld `singular`.

| Fitpfad | Regel für `converged` und Warnungen |
| --- | --- |
| `clmm` | Erfolg genau bei `optRes$convergence = 0` für nlminb oder 1/2 für ucminf. Maßgeblich ist der tatsächlich verwendete Optimierer. Der einfache Zufallsinterzeptpfad ohne `useMatrix` kann ucminf verwenden; der Matrixpfad verwendet nlminb auch bei angefordertem ucminf. `control$method` allein genügt deshalb nicht. Bei FALSE warnt `msa_fit()` mit „converge“ und der Engine-Meldung `optRes$message`; vorhandene Engine-Warnungen bleiben sichtbar. |
| `glmer` | `optinfo$conv$opt == 0` und keine lme4-Meldung außer „boundary (singular) fit: see help('isSingular')“. Nur diese Randmeldung ist von der Negativdiagnose ausgenommen. Bei FALSE erreicht jede vermerkte lme4-Meldung den Aufrufer als Warnung, einschließlich einer zusätzlich vorhandenen Randmeldung; auch ein reiner Optimiererfehler wird benannt gewarnt. |
| Numerischer Durchreichweg (`numerics$method = "lmer"`) | Dieselbe Prüfung der finalen `model@optinfo$conv` wie bei glmer: Erfolgscode 0 und keine Meldung außer der Randmeldung. Die direkte lme4-Rechnung und ihre originale Warnungs-/Fehlerpolitik bleiben nach ADR-018/ADR-022 erhalten. |
| Numerischer Vorgabepfad (`closed_form`, `analytic_reml`) | Ein Objekt entsteht erst nach erfolgreichem Abschluss und Modellbau. Danach entscheidet ebenfalls die finale `model@optinfo$conv`, einschließlich der gespeicherten `checkConv`-Meldungen, nach derselben Regel. `numerics$start$convergence` und Startwarnungen entscheiden nicht über den Endstatus. Eine finale Hesse-/Gradientenmeldung ergibt FALSE, auch wenn der analytische Abschluss erfolgreich war; ein gescheiterter Abschluss bleibt der bisherige benannte Fehler ohne Ersatzfit. |

Fehlende oder nicht interpretierbare Erfolgscodes bestätigen keine Konvergenz
und dürfen weder TRUE noch `NA` erzeugen. Es werden keine neuen numerischen
Schwellen eingeführt und keine vorhandenen Diagnosen umgeschrieben. Insbesondere
bleiben die Einschränkungen hoher Wiederholpräzision aus BL-87 sichtbar.
Eine bloße Range-Warnung verändert `converged` nicht. Die Wahl des tatsächlichen
clmm-Optimierers wird gegen echte Ein- und Mehrtermfits sowie `useMatrix`
geprüft, nicht aus dem Warnungstext oder pauschal aus der Menge {0, 1, 2} geraten.

### Zwei Stufen, Dokumentation und AP1

Ordinal gehen Prompt, Modell oder Block mit genau zwei beobachteten Stufen als
feste Haupteffekte ein; ihre Komponenten sind β̂²/2. `fit$derived` und
`attr(fit$vc, "derived")` nennen dieselben Quellen. `msa_grr()` übernimmt die
Herkunft additiv als `derived`. Eine Stufe verschwindet aus Formel und vc,
auch aus Interaktionstermen. Für weniger als drei ordinale Items steht der
bestehende Fehlertext „At least three items are needed for ordinal outcomes.“
wörtlich in der Hilfe.

Jeder zurückgegebene ordinale Fit mit abgeleiteten Komponenten warnt:

```text
Two-level component(s) <names> use the range method (beta-hat^2/2),
with positive bias: E[beta-hat^2/2] = sigma^2 + Var(beta-hat)/2;
see ?msa_fit.
```

Jede abgeleitete Quelle erhält in beiden Druckmethoden eine eigene Zeile,
beispielsweise `model: range method, see ?msa_fit`. Ohne solche Quelle
erscheint kein Range-Hinweis. Hilfe und NEWS erläutern, dass das Ersatzverfahren
die Handbuchkorrektur EV²/(n·r) nicht abzieht; sie nennen positive Verzerrung,
`two_level` und `vignette("validation")`. Wissenschaftliche Größen der
Verzerrung werden erst mit den Betreiber-Vollläufen in K-M1d-7 berichtet.

Range- und Ausschlusswarnungen enthalten keinen der AP1-Rückfallauslöser
„converge“, „Hessian“, „max|grad“, „gradient“, „unidentifiable“.
Die neue Warnung bei echter clmm-Nichtkonvergenz enthält dagegen „converge“.
Regressionen prüfen den tatsächlichen Rückfallpfad; an dessen Kriterien
oder Warnungsfilter in `R/acmg.R` ist keine Änderung geplant.

### Studienvertrag, Abbruch und Zusammenführung

CLI, Formate und Kennzahlen folgen ADR-023 Nr. 1–8 und dem detaillierten
PLAN.md. Der Aufruf aus einem beliebigen Arbeitsverzeichnis lautet:

```text
Rscript <Pfad>/<studie>.R --n-sim <n> --scenarios <ID>[,<ID>...] --out <Verzeichnis>
```

Die Schalterreihenfolge ist frei; ohne `--scenarios` laufen alle Szenarien
der Studie. Die Skripte laden das installierte `llmsa` und Helfer über
`system.file()`. Ungültige Schalter, Szenarien, Wiederholungszahlen und
Seed-Überläufe werden benannt abgewiesen. Datenerzeugung und Fitverfahren
folgen vollständig ADR-023 Nr. 13 und der M1b-Szenariotabelle.

Die Seed-Regel aus Runde 1 bleibt unverändert:
`seed(s, r) = 20261031 + j(s) + 8 * (r - 1)`, mit dauerhaft j = 1,…,8 für
S-ord-1,…,S-ord-4, S-bin-1,S-bin-2, S-two-1,S-two-2 in dieser Reihenfolge.
RNG: `Mersenne-Twister`, `normal.kind = "Inversion"`,
`sample.kind = "Rejection"`. Jeder Strom ist unabhängig von Auswahl,
Reihenfolge, n_sim und Workerzahl. Forks bleiben auf `inst/validation/sim/`
beschränkt, höchstens ANK-TOL.sim_runtime.cores, ohne automatisches zusätzliches
Fork-Seeding; sequentielle Ausführung liefert dieselben Einzelschätzer.
Die benötigten Namensräume werden vor dem Fork geladen.

| Datei | Inhalt |
| --- | --- |
| `<studie>_results.csv` | `scenario, estimand, measure, value, mcse, n_sim, seed`; je Pflichtschätzziel `bias`, `rel_bias`, `empse`, `rmse`, bei `two_level/model` zusätzlich `derived_share`. n_sim zählt alle geplanten Wiederholungen, seed den Szenario-Startseed. |
| `<studie>_replicates.csv` | `scenario, rep, estimand, estimate, true, items, prompts, models, blocks, observations`, dazu deterministische Diagnosefelder und `rep_seed`; für two_level logisches `derived`. Zählungen stammen aus `fit$n`. Ordnung nach `scenario`, `rep`, `estimand`; Genauigkeit gemäß `write.csv`, Vergleich aller Spalten nach `format(x, digits = 15)`. |
| `<studie>_session.txt` | Tatsächliches `sessionInfo()`, RNG, alle protokollierten Seeds mit Regel, Aufruf, Auswahl, Workerzahl, Laufzeiten sowie Warnungen/Fehler mit Szenario und Wiederholung. Zeit- und Versionsfelder stehen ausschließlich hier. |

Die Pflichtschätzziele und Wahrheiten bleiben aus PLAN.md/ADR-023 erhalten:
alle wahren Komponenten außer dem linkfesten Rest sowie %GRR der
Studienvariation und ICC_items. Wahres GRR umfasst alle Nicht-Item-Komponenten
einschließlich Rest, TV = GRR + Item. Auch die mitgeschätzten Wechselwirkungen
mit wahrer Varianz null gehen regulär in die geschätzten GRR-Kennzahlen ein.

Die vier Leistungsmaße und ihre MCSE rechnen über die endlichen Schätzer nach
Formelsammlung §9/ADR-023 Nr. 5. Fehlgeschlagene Fits bleiben als Zeilen mit
`estimate = NA`, nicht verfügbaren Zählungen `NA` und `derived = FALSE`
erhalten; endliche singuläre oder nicht konvergierte Fits bleiben mit Flags
enthalten. Die Zahl verfügbarer Schätzer wird zusätzlich ausgewiesen.
`derived_share` verwendet alle n_sim Wiederholungen. Der bereits angenommene
Grenzfall RMSE = 0 hat MCSE = 0. Es werden keine Wiederholungen ersetzt.

**Abbruchprotokoll zu E5:** Nach dem Rechnen werden zuerst die Replikate und
die Session geschrieben. Erst nach erfolgreicher Prüfung aller benötigten
Schätzziele wird die Ergebnisdatei veröffentlicht. Bei weniger als zwei
endlichen Werten nennt die Session mindestens Szenario, Schätzziel,
verfügbare Zahl und Ursache; die CLI endet benannt mit Exit ungleich 0.
Ein Zielpfad mit bereits vorhandenen Studienausgabedateien wird vor dem Lauf
benannt abgewiesen, damit kein alter Erfolg neben einem neuen Fehllauf steht.
Die README verlangt getrennte Ausgabeverzeichnisse je Versuch. Schreibfehler
werden ebenfalls benannt gemeldet; ein erfolgreicher Dateierhalt wird nur
nach erfolgreichem Schreiben behauptet.

**Betreiberanleitung zu E5:** Der bevorzugte Vollauf ist genau ein Aufruf je
Studie mit allen Szenarien und n_sim ≥ ANK-06.value.n_sim_min, nach Abnahme
des Codes und in einer protokollierten installierten Paketversion. Die README
enthält diese drei konkreten Aufrufmuster und zusätzlich ausführbaren
Zusammenführungscode für szenarioweise Läufe:

1. Erfolgreiche Teiltripel aus getrennten Verzeichnissen einlesen. Szenarien
   müssen disjunkt sein und zusammen genau die Studie abdecken. Schema,
   n_sim, Seed-Regel, RNG, R-/Paketversionen und Implementierungsstand müssen
   zusammenpassen; ein fehlendes Tripel oder doppelte Schlüssel führt zum
   benannten Abbruch. Wiederholungen innerhalb eines Szenarios werden nicht
   als getrennte Läufe zusammengefügt.
2. Replikatzeilen unverändert zusammenführen und nach `scenario`, `rep`,
   `estimand` sortieren. Die vollständigen Ergebniszeilen je Szenario
   zusammenführen und nach `scenario`, `estimand`, `measure` sortieren;
   Kennzahlen/MCSE werden weder gemittelt noch aus gerundeten Anzeigen
   gewonnen. Es werden keine Fits oder Einzelschätzer neu berechnet.
3. Eine Session-Datei je Studie mit allen Seeds und den zugehörigen
   Original-Sessionangaben, Aufrufen und Diagnosen erstellen. Laufzeiten
   bleiben als Zeiten der Teilläufe gekennzeichnet; keine erfundene
   gemeinsame Wanduhrzeit. Herkunft der Teildateien und Zusammenführung
   wird protokolliert.
4. Vollständigkeit und die unveränderten Einzelschätzer nach
   `format(x, digits = 15)` prüfen, dann das zusammengeführte Tripel in ein
   neues Ausgabeziel schreiben. Kleine positive und negative Unit-Fälle
   prüfen dieses Verfahren schon in M1b. Die Übernahme der echten Vollläufe
   in das Repository vor M1d bleibt beim Betreiber.

### Vignette und Ankerkopien

Der Abschnitt heißt exakt „Ordinal and binary outcomes (latent scale)“.
K-M1b-1 zeigt wine mit Logit/Probit gegen direkte clmm-Fits und separat die
Installationsprüfung von clmm2 mit den beiden Varianzen aus ANK-21.
K-M1b-5 wird nach der Arbiter-Direktive in zwei ausdrücklich bezeichneten
Prüfungen dargestellt:

| Prüfung | Berechnung und Referenz |
| --- | --- |
| ICC_items auf der latenten Logit-Skala | Beobachtete ICC_items von `msa_fit`/`msa_grr` auf BeetlesMale gegen `rptR::rptBinary(Colour ~ (1 \| Population), grname = "Population", link = "logit", expect = "liability")`, `performance::icc()` und die Nachrechnung σ²_Population/(σ²_Population + π²/3) mit ANK-28. Absolute Toleranz ANK-TOL.rptr.live_tol. |
| rptR-Installationsprüfung | Vorgabeaufruf mit Logit, ohne `expect`-Override; beide Punktschätzer `R_link` und `R_org` gegen ANK-25 `link_scale` und `original_scale`. Absolute Toleranz ANK-TOL.rptr.vignette_tol. Diese Werte sind ausdrücklich keine Referenzwerte für ICC_items. |

rptR läuft jeweils mit `nboot = 0`, `npermut = 0`. Die Datenabbildung bleibt
ADR-023 Nr. 12. Orakelwerte entstehen zur Laufzeit; beide ANK-25-Werte werden
aus dem Anker gelesen und zusammen mit der beobachteten ICC_items gezeigt.
Der Abschnitt nennt ANK-25, ANK-28, ANK-TOL.rptr.live_tol und
ANK-TOL.rptr.vignette_tol. Vergleiche verwenden ungerundete Werte.

Für jede Studie wird über `system.file("validation", "sim", …)` zuerst die
vorhandene `<studie>_results.csv`, sonst der Kurzlauf gelesen. Tabellen und
n_sim stammen aus der tatsächlich gewählten Datei. Eine vorhandene
fehlerhafte Datei führt zum benannten Fehler. Die Dateiwahl funktioniert
auch in der öffentlichen temporären Paketkopie des Abnahmetests; beim
Knitten läuft keine Simulation.

Die Literalregel gilt einschließlich ANK-28: kein abgetippter Dezimalwert
von π²/3, kein publizierter oder simulierter Ergebniswert im Rmd-Text oder
in ausgelagerten Helfern; `pi^2 / 3` ist ein mathematischer Ausdruck und
zulässig. Die Herkunftsprüfung schließt Inline-R und nachgeladene Helfer ein.
Ankerkopien folgen ADR-021: vollständige byte-identische Dateien, Manifest
mit Original-/Kopienpfad und SHA-256, strikte Kontexte mit/ohne `REPO_ROOT`.
Der Drifttest vergleicht insbesondere beide ANK-TOL-Kopien unter `numeric/`
und `latent/` mit dem Original. Die Originalprüfung darf nur im Standalone-
Paket ohne erreichbares Repository überspringen; Paketressourcen bleiben
geprüft. Fehlende Suggests werden in Unit-Tests vor ihrer Nutzung behandelt
wie unter E6; ein Abnahmelauf erhält dadurch keine zusätzliche Ausnahme.

## Reihenfolge

1. Runde 2 wird gegen dieses Update, ADR-023/-024 und die aktuelle
   Arbiter-Direktive geprüft. Der Reviewer dokumentiert ACC-18 in seinem
   angekündigten ADR. E1 wird sachlich nicht wieder geöffnet.
2. In BUILD Ausgangsinventur und Abhängigkeiten lesend prüfen, schnelle
   Ausgangstests belegen und den M1a-Abschluss anhand der vorhandenen
   Gate-/Review-Fakten in PROGRESS nachtragen.
3. Fit-Eingaben, Engine-Diagnosen, Range-Warnung, beide Druckmethoden und
   Hilfe zusammen umsetzen; zuerst E2–E4, BL-81, AP1-Integration sowie
   K-M1b-1/-4/-5/-6 prüfen. Die numerische Optimierung bleibt im bisherigen
   Vertrag; das neue Feld liest ihre Enddiagnose.
4. Ressourcen und Studien nach ADR-023 implementieren; kleine unabhängige
   Formel-, RNG-, CLI-, Abbruch- und Zusammenführungsprüfungen ausführen.
   Suggests deklarieren; fehlende Installation dem deps-Gate zuordnen.
5. Den endgültigen Paketstand temporär installieren. Alle drei Kurzläufe
   mit ANK-TOL.n_check erzeugen, reale Laufzeiten messen und die neun
   `_check_`-Dateien übernehmen. Neuläufe aus fremdem Arbeitsverzeichnis
   und die n_sim=2-Teilmengen reproduzieren. Nach einer relevanten Änderung
   betroffene Kurzläufe vor den Gates erneut erzeugen und prüfen.
6. Vignette, erzeugte Rd-Hilfen, Builder-ADR, NEWS und PROGRESS abschließen;
   beide Prüfungen von K-M1b-5, Ergebniswahl und öffentlichen Paketbau prüfen.
7. Vollständige M1b-Abnahme, M1a-Regression, K-M2-6, Unit-/QA-Regression und
   Paketcheck mit echten Outputs übergeben. Territoriumsprüfung, kumulative
   Gates, Verdict und Phasen-Commit erfolgen durch die zuständigen Rollen.
8. Nach M1b-Abnahme rechnet der Betreiber die drei Vollläufe; README und
   PROGRESS liefern Aufrufe, Seeds, Versionen und Hochrechnung aus gemessenen
   Kurzlaufzeiten. K-M1d-6/-7 prüfen Reproduktion und wissenschaftliche Befunde.

## Risiken

- **Engine-Diagnosen:** Verwechslung von angefordertem und verwendetem
  Optimierer oder von Singularität und Nichtkonvergenz erzeugt falsche
  Studienflags und AP1-Rückfälle. E2 und die Engine-Gegenfälle prüfen diese
  Klasse. Das numerische Feld darf alte Warnungen nicht verdecken.
- **Laufzeit und Mutation:** Gemessen werden ordinal_recovery plus
  binary_recovery gemeinsam sowie two_level separat, jeweils gegen
  ANK-TOL.sim_runtime. Die Laufzeiten aus ACC-16 bleiben Fremdbelege einer
  Reviewer-Attrappe. Die in ADR-024 Nr. 3 beschlossene Mutationsauswahl
  nimmt nur die beiden Skriptprüfungen und das zusätzliche Vollauf-Knit
  heraus; schnelle M1b-Abnahme bleibt enthalten. Keine Szenario-, Seed-,
  Toleranz- oder Testkürzung bei langsamen beziehungsweise roten Läufen.
- **Lange Fehlläufe:** E5 sichert Einzelschätzer und Diagnosen vor einem
  Aggregationsabbruch. Ein Betriebssystemabbruch oder unbeschreibbares
  Medium ist damit nicht als vollständig gesicherter Lauf ausgegeben.
  Die Betreiberanleitung erlaubt getrennte Szenarioläufe mit überprüfter
  Zusammenführung.
- **Reproduktion bis M1d:** Änderungen an Fit, Engineversion, Generator,
  Schema oder Zufallsströmen können Vollläufe ungültig machen. Nach M1c
  Präfixreproduktion prüfen und nötigenfalls Betreiber-Volllauf erneuern;
  Ergebnisse niemals mit einer anderen Version etikettieren.
- **Numerische Bestandsgrenzen und Plattformen:** BL-84/-87/-89 behalten
  die unten genannten Termine. M1b behauptet keinen zusätzlichen
  Windows-/macOS- oder Hochpräzisionsnachweis. BL-86 bleibt Infrastruktur;
  lokale Fehler werden mit Output gemeldet, nicht durch Gate-Änderungen
  oder Berechtigungsumgehungen behandelt.

### ACCEPTANCE-Einträge, aktueller Stand

| ID | Behandlung in Runde 2 |
| --- | --- |
| ACC-1 | akzeptiert: geschlossen gemäß ADR-024/ARBITER; E1 und aktualisierter Test-/Vignettenvertrag. |
| ACC-2 | akzeptiert: CLI, installiertes Paket, Arbeitsverzeichnis und Dateinamen nach ADR-023 Nr. 1. |
| ACC-3 | akzeptiert: Pflichtspalten, Schätzziele und Kennzahlensatz aller drei Studien nach ADR-023 Nr. 2–3. |
| ACC-4 | akzeptiert: deterministisches Langformat, wirkliche Fit-Zählungen, abgeleitete und fehlgeschlagene Fits nach Nr. 4. |
| ACC-5 | akzeptiert: Nachrechnungen/MCSE nach Nr. 5, bereits angenommene Null-RMSE-Konvention; Diagnosesicherung gemäß E5. |
| ACC-6 | akzeptiert: Präfix-/Teilmengen-/Workerstabilität nach Nr. 6; E5 ergänzt die Betriebsanleitung. |
| ACC-7 | akzeptiert: Session, Seeds, RNG, geladene Namensräume und Laufzeit nach Nr. 7. |
| ACC-8 | akzeptiert: beide Wanduhrzeitbedingungen ohne Installation nach Nr. 8. |
| ACC-9 | akzeptiert: Referenz-TV, Formel, Warnung, Druckzeile und Hilfe nach Nr. 9; E4 präzisiert die Darstellung. |
| ACC-10 | akzeptiert: alle Randfälle nach Nr. 10 einschließlich 10.9; E2/E3 und BL-81. |
| ACC-11 | akzeptiert: Abschnitt, aktuelle Livewerte, Ergebniswahl und Literalregel nach Nr. 11; K-M1b-5 gemäß ACC-18. |
| ACC-12 | akzeptiert: [INFRA] laut ADR-024 Nr. 3/CRITERIA erledigt, E7; keine Builder-Konfiguration. |
| ACC-13 | akzeptiert: rptR/performance als Suggests, ergänzt um parallel, E6. |
| ACC-14 | akzeptiert: Referenzdatenabbildung und rptR ohne Bootstrap/Permutation nach Nr. 12. |
| ACC-15 | akzeptiert: [INFRA] laut ADR-024 Nr. 4/CRITERIA erledigt, E8; keine Builder-Rollbackarbeit. |
| ACC-16 | akzeptiert: aktuelle Reviewer-Ausgangsläufe nur als gelesene Fremdbelege, keine eigene Abnahme oder übernommenen Attrappendaten. |
| ACC-17 | akzeptiert: Mindestzahl aus ANK-06; fehlendes Intake bleibt Beschaffung beim Betreiber, keine Blockade der Kurzläufe. |
| ACC-18 | akzeptiert: beide ANK-25-Werte, beobachtete ICC_items, ANK-28, benannte Toleranzen und erweiterte Literalregel; Reviewer-ADR in Runde 2. |

### Jeder offene BACKLOG-Eintrag

66 Einträge sind offen. Die 23 bereits erledigten Einträge, einschließlich
des nur im Fließtext als erledigt bezeichneten BL-38, werden nicht wieder
geöffnet. „Berücksichtigt“ ist eine Planmaßnahme, keine Schließung durch den
Builder. BACKLOG bleibt unverändert; Vertagungen nennen Zuständigkeit und
Zeitpunkt beziehungsweise Anlass.

| ID | Maßnahme oder begründete Vertagung |
| --- | --- |
| BL-01 | Berücksichtigt: M1b auf Kern, Kurzläufe und Vignette begrenzen; Betreiber priorisiert AP1 und entscheidet nach M1d über M3 vor der Frist 26.11. |
| BL-02 | Vertagt an Betreiber zur Neuheitsabgrenzung vor Preprint/BL-10; keine Änderung der M1b-Schätzer erforderlich. |
| BL-03 | M1b setzt K-M1b-3/-4 mit Warnung und two_level um; quantitative Bewertung nach Betreiber-Volllauf in K-M1d-7, Ersatz nur mit fachlichem ADR. |
| BL-04 | Vertagt auf M1c/boot_coverage, Betreiber-Volllauf danach und Befunde in M1d; ordinaler Bootstrap ist außerhalb M1b. |
| BL-05 | Betreiber berichtet AP1 bei der Auswertung getrennt nach prior_differs; M1b ändert keine Referenz-/Memorisierungsfelder. |
| BL-06 | Betreiber prüft Modellumleitung in Harness-Logs; keine Modell-/CLI-Konfiguration im Statistik-BUILD. |
| BL-07 | Betreiber prüft Anbieter im laufenden AP1 und entscheidet über Wiederholungstage; bestehende Metadatenlogik bleibt Regression. |
| BL-08 | Vertagt auf Betreibervereinbarung vor Partnerdaten in AP7; M1b verwendet öffentliche Orakeldaten und Simulationen. |
| BL-09 | Berücksichtigt: nur belegte Ankerkopien mit Kurzzitaten, keine Bücher, PDFs oder geschützten Rohdaten ausliefern; Reviewer prüft Quellenumfang. |
| BL-10 | Betreiber entscheidet am 15.11. über den Preprint; Kurzläufe ersetzen weder M1-Abnahme noch AP1-Endauswertung. |
| BL-11 | Betreiber gleicht Kosten mit Dashboard ab; BUILD berichtet tatsächlichen Aufwand, M3-Entscheidung nach M1d. |
| BL-12 | M1b misst Kurzlaufzeiten, liefert Hochrechnung und E5-Anleitung; Betreiber plant Vollläufe nach Abnahme und vor M1d. |
| BL-13 | M1b misst beide Runtime-Bedingungen und Paketcheck; ACC-12 ist laut ADR-024 erledigt, Gate-Gesamtdauer/Timeout bleiben beim Betreiber. |
| BL-14 | M1b ergänzt unabhängige Engine-/Formelbelege und Randfälle; Bootstrap-/vollständige ADEMP-Bewertung folgt M1c/M1d. |
| BL-15 | Vertagt auf M3a/K-M3a-2; Fleiss und Projektdokumentkorrektur betreffen keine latenten Varianzkomponenten. |
| BL-17 | Vertagt auf M3d/K-M3d-3 und AP2 vor Release; ellmer-Aufzeichnungen und Live-Prüfung sind außerhalb M1b. |
| BL-18 | Geteilt vertagt: Bootstrap-Zählung nach K-M1c-2, SHA-256-Bericht nach K-M3d-5. |
| BL-20 | M1b: wine gegen clmm mit msa-Formel; ANK-21 separat als clmm2-Installationsprüfung. |
| BL-21 | Reviewer prüft die geschachtelte NIST-Fallstudie bei einer späteren Ankererweiterung; kein M1b-Kriterium. |
| BL-22 | Berücksichtigt als M1a-Regression: AIAG-Pooling und separater Interaktionsbericht bleiben erhalten. |
| BL-23 | Berücksichtigt als M1a-Regression: NIST-LRE und Berichte höherer Schwierigkeit bleiben; keine neue Präzisionsregel. |
| BL-24 | Betreiber behandelt Baseline-Wechsel vor M3a; M1b bleibt im Kern-Scope R/fit.R und R/grr.R. |
| BL-25 | Originalanker nur lesen; Nachträge mit ADR beim Reviewer, Kopien danach kontrolliert neu erzeugen. |
| BL-28 | Betreiber verwaltet AP1-Konten und Limits im laufenden Betrieb; M1b benötigt keine Schlüssel. |
| BL-29 | Betreiber klärt Infevers vor Veröffentlichung; M1b erzeugt keine INSAID-Klassifikationen. |
| BL-30 | Vertagt auf Betreiber für AP2/Release: Pages, Metadaten, Zenodo und DOI sind Veröffentlichungsschritte. |
| BL-31 | Betreiber prüft Commit-Identität vor Push; kein Git durch den Builder. |
| BL-33 | Betreiber verantwortet PREFLIGHT und CLI-Sandbox; keine entsprechende M1b-Produktarbeit. |
| BL-34 | Betreiber regelt Erreichbarkeit vor weiteren Eskalationen; E1 ist bereits entschieden, einzig zulässiger Human-Touchpoint bleibt ESCALATION-M1b.md. |
| BL-35 | Vertagt an Template-Betreiber bei nächster Harness-Pflege; notify ist unabhängig vom Statistikcode. |
| BL-36 | Betreiber entscheidet bei Laufzeitbedarf über WSL-Umzug; M1b misst Zeiten und hält Rohdaten außerhalb. |
| BL-37 | Vertagt an Betreiber zum Kosten-/Dashboard-Abgleich wie BL-11; keine Harness-Kostenspur durch M1b. |
| BL-39 | Betreiber beschafft Quellen vor den jeweils späteren Aufgaben; M1b verwendet die vorhandenen geernteten Anker. |
| BL-40 | Vertagt auf M1d-ACCEPTANCE und Betreiber-Beschaffung fehlender Konkordanzquellen; kein M1b-Vergleich. |
| BL-41 | Betreiber klärt Quellenbezug der Kappa-Bandnamen vor AP1-Endbericht; M1b ändert keine Bänder. |
| BL-42 | AIAG-Blatt bleibt Pflicht der M1a-Regression; Betreiber/Reviewer liefern bzw. prüfen weitere Blätter vor M3a/M3b, fehlende Daten werden nicht übersprungen. |
| BL-43 | Betreiber prüft Modellkennungen und Preise vor AP1-Nutzung; kein Anbieteraufruf für M1b nötig. |
| BL-44 | Vertagt auf M3a/K-M3a-2; Fleiss-Standardfehler nur aus passender Quelle. |
| BL-45 | Betreiber pflegt externe Projektdokumente nach Meilensteinabschluss; BUILD liefert PROGRESS mit Belegen. |
| BL-46 | M1b-Vignette liest Ergebnisse ohne Simulation; Checkdauer messen, Vier-Vignetten-Budget vor M1d erneut prüfen. |
| BL-47 | Betreiber beachtet Autorenzuordnung vor Veröffentlichung; VariantBench bleibt außerhalb M1b. |
| BL-48 | Reviewer prüft Kriterien-Gate-Zuordnung, insbesondere K-M1b-7/lint; maschinelle Erweiterung bleibt Template-Arbeit beim Betreiber. |
| BL-49 | M1a-Regression erhält bestätigte bobyqa-Steuerung und TV-Toleranz; M1b nutzt den eigenen Engine-Anker. |
| BL-50 | Vertagt auf M3c/K-M3c-6; Planungs-CV ist keine zusätzliche M1b-Bestehensbedingung. |
| BL-51 | Vertagt bis nach AP1 an Betreiber/Reviewer für Export-ADR; acmg bleibt intern, M1b ergänzt keine Exporte. |
| BL-52 | Betreiber wiederholt AP1-Auswertung nach M1-Abnahme mit demselben externen Store; vorherige Zahlen bleiben vorläufig. |
| BL-55 | Betriebsregel weiter berücksichtigt: keine parallelen Betreiberdateien im Arbeitsbaum; die gesonderte Rollback-Korrektur ACC-15 ist laut ADR-024 erledigt. |
| BL-57 | Keine neuen Argumente; vorhandene Positionen/Vorgaben gegen ANK-02 prüfen, Reviewpflicht für künftige Anhänge bleibt. |
| BL-60 | Vertagt auf Vorbereitung von M3d/K-M3d-3; ellmer-Streaming und httr2-Mocks betreffen Backend-Abnahme. |
| BL-64 | Vertagt auf AP1-Berichtspflege/M3d vor Endbericht: Pilotquantil entkoppeln; unveränderter Typ 7 ist von M1b nicht betroffen. |
| BL-68 | Vertagt auf nächsten freigegebenen AP1-CLI-/Berichts-BUILD vor Endbericht; Erhebungshinweis betrifft keine M1b-Fits. |
| BL-70 | Betreiber führt Status-/Timeout-/STOP-Befunde in der nächsten Template-Pflege weiter; außerhalb des M1b-Territoriums. |
| BL-71 | Betreiber entscheidet vor AP1-Endauswertung über Historienkennzeichen/Limitations; Golden-Änderung nur mit ADR, keine M1b-Datenänderung. |
| BL-72 | Berücksichtigt: portable Pfade, strikt gelesene Toleranzen und bestätigte M1a-Regression; kein plattformabhängiger Ersatzmaßstab. |
| BL-73 | Vertagt auf AP1-Berichtspflege vor Endbericht: Kosten-/Reasoning-Spalten und Sol-Nachrechnung; ohne M1b-Abhängigkeit. |
| BL-74 | Betreiber plant AP1-Blöcke und etwaige Parallelisierung per ADR vor Erhebung; kein Teil der statistischen Simulationen. |
| BL-75 | Vertagt auf AP1-Berichtspflege vor Endbericht: Netzwartezeit bei Latenz berücksichtigen; M1b hat keine API-Latenzen. |
| BL-77 | Berücksichtigt: Zitate mit Fundstelle, Fremdbelege gekennzeichnet; QA-Promptkorrektur bei Betreiber/Reviewer in Template-Pflege. |
| BL-79 | [INFRA] Betreiber archiviert Mutationsberichte vor weiteren Läufen; Builder belegt Claims nur gegen tatsächlich verfügbaren aktuellen Bericht. |
| BL-80 | Betreiber berichtigt NIST-Offsettext bei Spec-Pflege; Kriterien, Anker und Tests werden durch M1b nicht geändert. |
| BL-81 | M1b-Pflicht: ordinale/binäre Gruppierungs-NA benannt ablehnen, Modellzeilen und Zählungen prüfen, ADR-022 Nr. 2/K-M1b-6. |
| BL-84 | Nonblocking auf M1c-BUILD mit mutfull vertagt: Darstellbarkeitsfälle, Redundanzen und unbenutzter Default gehören zur numerischen Robustheit. |
| BL-85 | [INFRA] Betreiber verbessert Approval-Zuordnung; Reviewer prüft je Runde aktuellen Quelltext, Builder erteilt keine Freigaben. |
| BL-86 | [INFRA] Betreiber hält Mutation im regulären Gate vor; lokale Socket-/Zeitprobleme mit Output melden, keine Umgehung. |
| BL-87 | Auf M1c-BUILD vor dessen Volllauf und vor M1d vertagt: numerischer Abschluss, Hochpräzisionsraster und E59-Warnungsreihenfolge; M1b ändert nur den abgelesenen Endstatus. |
| BL-89 | Nonblocking auf M1c-BUILD mit numerischen Regressionen vertagt, spätestens vor erstem macOS-/Windows-Releasecheck; bei früherer CI Betreiberauftrag vorziehen, erfolgreiche Fits gegen Orakel prüfen. |

## Testplan

### Abnahme und Regression im BUILD

| Kriterium | Prüfweg und Maßstab |
| --- | --- |
| K-M1b-1 | `test-m1b-1-engine-ordinal.R`: wine mit beiden Links gegen direktes clmm, Rest gegen ANK-28, GRR gegen unabhängige Formeln; separate clmm2-Installationsprüfung Laplace/nAGQ gegen ANK-21. Komponentenfehler ≤ ANK-TOL.engine_ordinal.rel_tol × Referenz-TV, abgeleitete Kennzahlen relativ, ndc gleich. |
| K-M1b-2 | `test-m1b-2-recovery-scripts.R`: sechs Szenarien, Schema, Wahrheiten, Fit-Zählungen, MCSE-Nachrechnung, Session, Reproduktion aller Replikatspalten und gemeinsame Laufzeit. Präfix-Teilmengen mit n_sim=2: S-ord-2/S-ord-4 und S-bin-2. |
| K-M1b-3 | `test-m1b-3-two-level-script.R`: zwei Szenarien, β̂²/2 und derived, alle Maße einschließlich RMSE/derived_share, Neulauf und eigene Laufzeitgrenze; S-two-2 mit n_sim=2. Nicht endliche Modellschätzer oder fehlendes derived im verlangten Kurzlauf bleiben ein echter Fehlschlag. |
| K-M1b-4 | `test-m1b-4-two-levels.R`: feste statt zufällige Zwei-Stufen-Faktoren, β̂²/2 gegen direktes clmm und Stichprobenvarianz der Stufeneffekte, Warnung, Name und Range-Text in derselben Druckzeile, Hilfe, Gegenfall mit drei Stufen. |
| K-M1b-5 | `test-m1b-5-binary-rptr.R` in der Fassung nach ADR-024: (i) ICC_items gegen live rptBinary mit `expect = "liability"`, performance::icc auf direktem glmer und fit$model sowie Nachrechnung mit ANK-28, jeweils ANK-TOL.rptr.live_tol; (ii) rptR-Vorgabeaufruf reproduziert beide publizierten Punktschätzer aus ANK-25 mit ANK-TOL.rptr.vignette_tol. Kein Vergleich ICC_items gegen ANK-25. |
| K-M1b-6 | `test-m1b-6-edge-cases.R`: ein/zwei Items und dokumentierter Wortlaut, eine Kategorie, fehlende/ungültige Antworten und Zählungen, Labels, binär −1/0,5/2, forcierte Nichtkonvergenz und positive Gegenfälle beider Engines, Singularität, eine Stufe, vier Gruppierungs-NA-Fälle. |
| K-M1b-7 | Beide `test-m1b-7-*.R`: echter Knit, Abschnitt und Anker-/Livewerte einschließlich beider ANK-25-Werte und ANK-28, alle Ergebnistabellen/n_sim, Literalregel und Wahl vorhandener Vollaufdateien in öffentlicher Paketkopie. Das lint-Gate trägt den Bau ohne ERROR/WARNING. |

Zusätzliche kleine Unit-Prüfungen sichern die Änderungen dieser Runde:

- E2: echter ucminf-Eintermfit mit Erfolgscode 1/2 ergibt TRUE ohne
  Nichtkonvergenzwarnung; Mehrterm- und `useMatrix`-Fallback werden anhand
  des tatsächlichen nlminb-Status eingeordnet. Ein singulärer glmer mit
  Optimierererfolg und alleiniger Randmeldung hat `singular = TRUE` und
  `converged = TRUE`. Limitabbruch ergibt FALSE und sichtbare Warnungen.
  Synthetische Diagnosen ergänzen echte Fits für seltene Codes 2/3/4 und
  fehlende Codes; sie ersetzen keine Engine-Gegenrechnung.
- Numerischer Teil von E2: direkter lmer-Erfolg/-Abbruch sowie erfolgreiche
  `closed_form`-/`analytic_reml`-Fits gegen ihre finalen `optinfo`-Diagnosen;
  bloße Startwarnung beeinflusst den Endstatus nicht, finale Hesse-Meldung
  wird nicht als Erfolg ausgegeben. Schätzer, Startdiagnosen und bestehende
  Fehler-/Warnungswege bleiben durch M1a-Regression belegt.
- E3: logische/numerische/Zeichen-0/1-Eingaben, explizite Labels,
  ungültige/fehlende `levels`, Ausschlüsse und Ereigniskodierung; nach
  Zeilenpermutation gleiche Kodierung je Eingabezeile, nach Vertauschen von
  `levels` komplementäre Antworten. Komponenten bleiben jeweils innerhalb
  ANK-TOL.invariance als Anteil von Referenz-TV, Kennzahlen relativ.
- E4/AP1: zwei Prompts, Modelle, Blöcke und mehrere Zwei-Stufen-Faktoren,
  Umbenennung/Vertauschung der Stufen, Warnung pro Fit und Druckzeile pro
  Quelle; Range-/Ausschlusswarnungen ohne Rückfall, echte Konvergenzwarnung
  mit numerischem Rückfall. K-M2-6 bleibt ein eigener Regressionslauf.
- E5: kleine synthetische Schätzervektoren mit unabhängiger Nachrechnung
  einschließlich NA, Null-RMSE und Nennern. Bei null/einem endlichen Wert
  bleiben Replikat-/Session-Datei vorhanden, Ergebnisdatei fehlt, Fehler
  nennt Szenario/Schätzziel. Zusammenführen disjunkter Szenarien erhält
  jede Zelle nach `format(x, digits = 15)`; Lücken, Duplikate, verschiedene
  Versionen/Seeds oder n_sim werden abgewiesen. Kein Vollauf im Unit-Test.
- Ressourcen: genaue Ankerdateimenge, Hashes, doppelte ANK-TOL-Drift,
  fehlende Originale, ungültige Ergebnisdateien, Voll-/Kurzlaufwahl und
  Literalherkunft einschließlich Helfern. Negativfälle ausschließlich in
  temporären, ausdrücklich synthetischen Kopien.
- E6: Suggests-Prüfungen vor optionaler Nutzung; paketinterne Tests laufen
  auch installiert. Abnahmetests und ihre Anker-/Datenpflichten werden nicht
  geändert. Die schnellen Tests müssen falsche Kodierung, fehlende
  Konvergenz-/Range-Warnungen und verlorene derived-Herkunft erkennen.

Vorgesehener Aufruf aus der Repo-Wurzel, erst im BUILD:

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath(".")); grDevices::pdf(NULL); testthat::set_max_fails(Inf); testthat::test_dir("tests/acceptance", filter = "^m1b-", load_package = "source", reporter = "summary", stop_on_failure = TRUE)'
```

M1a und K-M2-6 entsprechend mit `^m1a-` und `^m2-6-`; Unit/E2E/Fuzz über
den unveränderten Testtreiber. Diese direkten Diagnosen verändern keine
Gate-Auswahl. Git-verwendende M0-Prüfungen, Verifier und Mutation-Gates
verbleiben beim Orchestrator. Paketbau und
`R CMD check --as-cran --no-manual` laufen außerhalb des Arbeitsbaums in
einer Positivlisten-Kopie, öffentlich ohne und vollständig mit `REPO_ROOT`.
Keine Simulation oder Netzabfrage beim Knitten. Echte Kommandos, Outputs,
Laufzeiten und etwaige Infrastrukturgrenzen gehören in PROGRESS/Handoff.

In dieser PLAN-Runde werden keine Abnahmesuite, Kurz-/Vollläufe,
Paketchecks oder Gates ausgeführt. Die oben genannten Testläufe sind
geplante BUILD-Nachweise; die aktuelle Phase erteilt kein Verdict.

### Ausgeführte Handoff-Prüfung dieser PLAN-Runde

Die folgende Struktur- und Vollständigkeitsprüfung wurde ausgeführt
(Exit 0). Sie prüft das Plan-Update; sie ist kein Abnahmenachweis für M1b.

```bash
python3 - <<'PY'
from pathlib import Path
import json, re
p = Path('orchestrator/handoff/M1b/PLAN-UPDATE.md')
s = p.read_text()
sections = ['Ziel', 'Dateien', 'Schnittstellen', 'Reihenfolge', 'Risiken', 'Testplan']
assert all(s.count('## ' + x + '\n') == 1 for x in sections)
review = Path('orchestrator/handoff/M1b/PLAN-REVIEW.md').read_text()
expected = set(re.findall(r'^- \[(E\d+)\]', review, re.M))
answers = re.findall(r'^- \*\*(E\d+) — (akzeptiert|abgelehnt):', s, re.M)
assert len(answers) == len(expected) and {x[0] for x in answers} == expected
assert all(x[1] == 'akzeptiert' for x in answers)
criteria = json.loads(Path('orchestrator/handoff/M1b/CRITERIA.json').read_text())
acc = [x['id'] for x in criteria['open']]
assert re.findall(r'^\| (ACC-\d+) \|', s, re.M) == acc
rows = [x for x in Path('BACKLOG.md').read_text().splitlines() if re.match(r'^\| BL-\d+ \|', x)]
open_ids = [re.match(r'^\| (BL-\d+) \|', x).group(1) for x in rows if '**Erledigt**' not in x and not x.startswith('| BL-38 |')]
actual = re.findall(r'^\| (BL-\d+) \|', s, re.M)
assert actual == open_ids
spec = Path('docs/02-statistikkern.md').read_text().splitlines()
for c in criteria['criteria']:
    line = next(x for x in spec if x.startswith('- **' + c['id'] + ':**'))
    assert c['quote'] == line[2:], c['id']
    assert '| ' + c['id'] + ' |' in s
assert s.count('\n```') % 2 == 0
assert not any(x.rstrip() != x for x in s.splitlines())
print('PLAN schema: 6/6 required sections present exactly once')
print('Review replies: E1-E8 each answered once with akzeptiert:')
print('Acceptance entries: ACC-1-ACC-18 all addressed')
print(f'Backlog: {len(open_ids)}/{len(open_ids)} open entries addressed; {len(rows) - len(open_ids)} completed entries excluded (including BL-38)')
print('Criteria: 7/7 current quotes identical to specification; all in test plan')
print('Markdown: balanced fences; no trailing whitespace')
PY
```

Echter Output:

```text
PLAN schema: 6/6 required sections present exactly once
Review replies: E1-E8 each answered once with akzeptiert:
Acceptance entries: ACC-1-ACC-18 all addressed
Backlog: 66/66 open entries addressed; 23 completed entries excluded (including BL-38)
Criteria: 7/7 current quotes identical to specification; all in test plan
Markdown: balanced fences; no trailing whitespace
```

Zusätzlich wurde die vor dem Schreiben erfasste SHA-256-Inventur erneut
berechnet: alle 236 erfassten Bestandsdateien sind byte-identisch, keine
fehlt. Erfasst waren Produkt-, Test-, Spezifikations-, Vertrags- und
Ankerverzeichnisse, das M1b-Handoff sowie die gelesenen Stamm-/Regeldateien.
Einziger neuer Pfad in dieser Inventur ist dieses Plan-Update. Das ist
ein Dateiabgleich ohne Git, keine vorweggenommene Territoriumsprüfung des
Orchestrators. Ergebnis des Abgleichs:

```json
{
  "baseline_files": 236,
  "current_files": 237,
  "changed": [],
  "missing": [],
  "added": [
    "orchestrator/handoff/M1b/PLAN-UPDATE.md"
  ]
}
```
