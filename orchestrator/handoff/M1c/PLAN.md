# M1c — PLAN, Runde 1

Stand: 02.11.2026. Rolle: Builder. Vorschlag zur Planprüfung, keine Abnahme.
In dieser Phase wird ausschließlich diese Datei geschrieben. Die folgenden
Produktänderungen und Prüfläufe sind für BUILD vorgesehen. Der Builder führt
keine Git-Kommandos aus.

## Ziel

K-M1c-1 bis K-M1c-8 erfüllen: den parametrischen Bootstrap gegen
`lme4::bootMer` absichern, fehlgeschlagene und singuläre Wiederholungen
korrekt unterscheiden, die Überdeckungsstudie mit reproduzierbarem Kurzlauf
liefern, ihre Ergebnisse offline darstellen, den vollständigen Mutationslauf
bestehen, die latente Repeatability erläutern und das ordinale
Iterationslimit gemäß ADR-041 setzen. Die bisherigen numerischen Ergebnisse
von GRR und Bootstrap bleiben gemäß K-M1c-7 bytegleich. Vollläufe und deren
Befundbewertung folgen durch den Betreiber beziehungsweise in M1d.

Grundlage: gelesen sind `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`,
`orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`,
`orchestrator/handoff/M1c/CRITERIA.json`, sämtliche M1c-Abnahmetests samt
`setup-m1c.R`, die betroffenen M1b-Reproduktionstests,
`docs/01-fachspezifikation.md` insbesondere §§2–5 und §8,
`docs/02-statistikkern.md` insbesondere M1b/M1c/M1d sowie die Formelsammlung
§§2–4, §9 und §12 Nr. 5. Umfangsentscheidungen aus ADR-035 und ADR-038 bis
ADR-041 sowie der Simulationsvertrag aus ADR-023 sind berücksichtigt.
Bestehender Produktcode, Validierungsskripte, Berichtsvorlage und relevante
Anker wurden dagegen geprüft.

M1b ist laut `orchestrator/handoff/M1b/verdict-code.json` (Code, Runde 8,
`PASS`, leeres `blocking`) und `orchestrator/state/M1b/gates.json`
(Runde 8, alle acht Gates `pass`, `result: pass`) abgenommen. Den älteren
Kopf von `PROGRESS.md` ordnet der BUILD-Nachtrag anhand dieser Fakten ein.
Der R8-Mutationsstatus ersetzt keinen M1c-Lauf: Er beruhte auf ADR-038 und
dem R7-Beleg.

ACC-1 bis ACC-13 und ACC-18 bis ACC-20 werden als Prüfform übernommen.
Nach ACC-17 bleibt `msa_boot()` in `R/grr.R`; die Erwähnung von `R/boot.R`
bei M1d begründet keine Verschiebung aus dem Mutationsumfang. ACC-15 ist
nonblocking Reviewer-Arbeit: Auslegungen und die vor PLAN erhobenen
ANK-32/ANK-33 in der PLAN-REVIEW-Phase per ADR festhalten. Der Builder
schreibt weder Reviewer-ADR noch Anker oder Abnahmetests.

## Dateien

Die Liste beschreibt den vorgesehenen BUILD-Diff. Der PLAN-Diff bleibt auf
`orchestrator/handoff/M1c/PLAN.md` beschränkt.

| Datei/Pfad | Geplante Änderung |
| --- | --- |
| `R/grr.R` | Diagnoseerfassung in `msa_boot()`, zwei Diagnosezeilen in `print.msa_boot()`, latenter Hinweis in `print.msa_grr()`, roxygen für Boot/GRR. GRR-Rechenoperationen und ihre Reihenfolge erhalten. |
| `R/fit.R` | Ordinale Vorgabesteuerung gemäß K-M1c-8 und roxygen; ergänzender Dokumentationssatz zum Warnungsfall BL-87. Numerisches Lösungsverfahren unverändert. |
| `man/msa_boot.Rd`, `man/msa_grr.Rd`, `man/msa_fit.Rd` | Aus roxygen erzeugte Limits, Ersetzungsregel, Diagnosen, Studienverweis und latenter Hinweis. |
| `inst/templates/validation_report.Rmd` | Hinweis unmittelbar unter der Zeile mit Repeatability und Reproducibility. |
| `inst/validation/sim/boot_coverage.R` (neu) | CLI-Einstieg für alle sieben Szenarien mit installiertem Paket. |
| `inst/validation/sim/boot_coverage_helpers.R` (neu) | Szenarien, Generator, Seeds, Wiederholungen, Aggregation, Metadaten und Ergebnisleser. Reine bestehende Helfer wiederverwenden. |
| `inst/validation/sim/README.md` | ADEMP, MCSE, Fehlerbehandlung, Seeds, Reproduktion, Laufzeiten und Betreiberübergabe ergänzen. |
| `inst/validation/sim/boot_coverage_check_results.csv`, `boot_coverage_check_replicates.csv`, `boot_coverage_check_session.txt` | Tatsächlich erzeugter Kurzlauf S-boot-1/-7 mit `ANK-TOL.n_check`. |
| `inst/validation/sim/ordinal_recovery_check_*`, `binary_recovery_check_*`, `two_level_check_*` | Alle neun vorhandenen Kurzlaufdateien mit endgültigem installiertem Code neu erzeugen; keine bloße Hash-Ersetzung. |
| `vignettes/validation.Rmd` | Abschnitt „Bootstrap intervals: coverage by scenario“ mit eingelesener Überdeckung und MCSE. |
| `tests/testthat/test-boot.R`, `test-fit-ordinal-control.R`, `test-grr-latent-note.R`, `test-validation-bootstrap.R` (neu) | Gezielte Unit-Regressionen zu Diagnosen/Quantilen, Steuerung, Text-/Objektintegrität und Simulationsvertrag; keine zusätzlichen Vollstudien. |
| `tests/testthat/test-grr-rework.R` | Eigene Druckausgabe-Prüfung auf beide vorgeschriebenen Diagnosezeilen einschließlich null umstellen; bisherige Zahlen-, Format- und Rückgabevergleiche erhalten. |
| `PROGRESS.md`, zugewiesener BUILD-Handoff unter `orchestrator/handoff/M1c/` | Reale Befehle, Ausgaben, Laufzeiten und Grenzen dokumentieren. `MUT-EQUIV.json` nur für tatsächliche begründete Claims zum endgültigen Bericht. |

Die M1b-CLI-Skripte und deren Seed-Zuordnung können unverändert bleiben.
Falls gemeinsame Helfer erweitert werden müssen, geschieht dies vor allen
Kurzläufen. Neue Abhängigkeiten, Exporte oder öffentliche Argumente werden
nicht benötigt. Keine Golden-Änderung unter `inst/extdata/` oder
`reference/anchors/` ist geplant.

## Schnittstellen

### Öffentliche API, Bootstrap und Diagnosen

Die 22 Schnittstellen aus ANK-02 behalten Positionen und Vorgabewerte.
Insbesondere bleibt
`msa_boot(fit, nsim = 200, level = 0.95, seed = NULL, ...)` unverändert;
auch Fit, GRR und Druckmethoden erhalten keine neuen Argumente.
Zusätzliche Attribute und verlangte Druckausgabe fallen unter `docs/01` §4.
Ein ordinaler Bootstrap wird nicht eingeführt.

`msa_boot()` bleibt beim parametrischen Refit-Pfad von `lme4::bootMer`.
Die sechs Statistiken behalten ihre Reihenfolge:
`grr_pct_study_var`, `grr_pct_contribution`,
`repeatability_pct_study_var`, `reproducibility_pct_study_var`, `ndc`,
`icc_items`. Numerische Refits bleiben gewöhnliche lme4-Refits mit der im
Modell gespeicherten Steuerung; die analytische Vervollständigung des
Originalfits wird nicht in die Wiederholungen verlegt.

Die interne `FUN` liefert zusätzlich ein Kennzeichen aus
`lme4::isSingular()` mit Vorgabetoleranz. Nach `bootMer` wird es von den
sechs Statistikspalten getrennt. Das erfordert keine weiteren Refits oder
Zufallszahlen und unterstützt den erlaubten Snow-Pfad; ein globaler
veränderlicher Zähler wäre dort ungeeignet. Originalfit/`t0` zählt nicht
als Bootstrap-Wiederholung.

- `n_failed`: Zahl der Wiederholungen mit mindestens einer nicht endlichen
  Statistik, einschließlich `Inf`, `-Inf`, `NaN` und `NA`.
- `n_singular`: Zahl der gültigen, endlichen Wiederholungen mit singulärem
  Refit. Gescheiterte Wiederholungen werden nicht zusätzlich singulär
  gezählt. Beide Attribute sind einzelne endliche Zählwerte, auch bei null.
- Quantile: pro Statistik nur deren nicht endliche Werte entfernen,
  endliche Werte singulärer Fits behalten; bisheriger Typ 7 bei
  `(1 - level) / 2` und `1 - (1 - level) / 2`. Eine teilweise nicht endliche
  Zeile verliert ihre endlichen Werte nicht pauschal aus anderen Spalten.
- Rückgabe: keine Zusatzspalte in `attr(result, "boot")`. Matrix,
  Datenrahmenspalten, Namen, Klasse, Punktschätzer und `level` bleiben nach
  ACC-13 bytegleich. Auch die GRR-Summationsreihenfolge bleibt erhalten;
  numerisch nahe Ergebnisse genügen K-M1c-7 nicht.
- Ausgabe: immer zwei getrennte Zeilen, eine für fehlgeschlagene/nicht
  endliche Wiederholungen und das Verwerfen nicht endlicher Werte, eine für
  singuläre Wiederholungen und ihr Behalten. „singular“ und „dropped“ stehen
  nie in derselben Zeile, auch nicht als Verneinung. Print gibt das Objekt
  unverändert und unsichtbar zurück.

### Ordinale Steuerung und latenter Hinweis

Im ordinalen Zweig wird vor dem Engine-Aufruf geprüft, ob das benannte
Argument `control` übergeben wurde. Fehlt es, wird
`ordinal::clmm.control(iter.max = 2000, eval.max = 4000)` eingesetzt.
Andere Argumente in `...`, etwa `Hess = TRUE`, verhindern die Vorgabe nicht.
Ein ausdrücklich übergebenes `control` ersetzt sie vollständig, auch
`list()`. Partielle Listen werden nicht mit den erhöhten Limits vermischt.

Die gespeicherte Modellsteuerung muss dem jeweiligen direkten Engine-Aufruf
entsprechen. Die Limits sind Spezifikationswerte aus K-M1c-8/ADR-041,
keine neuen empirischen Anker. Die Rd-Datei nennt beide Zuweisungen und:
„An explicit `control` passed in `...` replaces both limits.“ Numerische
und binäre Steuerung sowie Konvergenz-, Identifizierbarkeits- und
Zwei-Stufen-Regeln bleiben erhalten.

Für ordinale und binäre GRR-Ausgaben wird der Text aus K-M1c-7 übernommen:

> On the latent scale, Repeatability is the residual variance fixed by the link, not a measurement of disagreement between replicates; see the share of cells with identical replicates from `msa_agreement()`.

Er steht in `print.msa_grr()` im Anschluss an die Komponententabelle,
im Bericht als nächster Textblock unmittelbar unter der Zeile mit
Repeatability und Reproducibility sowie in `?msa_grr`. Bei numerischen Fits
fehlt er. Es werden keine zusätzlichen Kennzahlen berechnet; `table`,
`summary` und `verdict` bleiben gleich. AP1-Wechselwirkungen und
Sensitivitätsrechnungen aus ADR-040/ADR-041 bleiben Betreiberarbeit;
`acmg_fit()` und `plan.yaml` werden in M1c nicht dafür geändert.

### Überdeckungsstudie: ADEMP, CLI und Zufallsströme

Ziel ist die empirische Überdeckung der bestehenden 95-%-Perzentilintervalle
unter den in `docs/02` festgelegten Designs. Pro Wiederholung werden Daten
neu erzeugt; die Schätzung verwendet `msa_fit()`, `msa_grr()` und
`msa_boot()` aus dem installierten Paket. Generator und wahre Kennzahlen
werden aus den festgelegten Komponenten unabhängig berechnet;
`msa_simulate()` dient nicht als Orakel für die eigenen wahren Werte.

| Szenario | Typ | Items | Prompts | Modelle | Replikate | Blöcke | Komponenten |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| S-boot-1 | numeric | 20 | 3 | 3 | 3 | 2 | A |
| S-boot-2 | numeric | 20 | 5 | 3 | 3 | 2 | A |
| S-boot-3 | numeric | 50 | 3 | 3 | 3 | 2 | A |
| S-boot-4 | numeric | 50 | 5 | 3 | 3 | 2 | A |
| S-boot-5 | numeric | 20 | 3 | 3 | 3 | 2 | B |
| S-boot-6 | numeric | 20 | 5 | 3 | 3 | 2 | B |
| S-boot-7 | binary/logit | 60 | 3 | 3 | 3 | 1 | C |

A ist der Vektor aus `docs/02`, Tabelle M1c: Item 1; Prompt 0,05;
Modell 0,05; Block 0,01; Item×Prompt 0,01; Item×Modell 0,05;
Prompt×Modell 0,005; Rest 0,1. B ersetzt nur Prompt durch 0,3 und Rest durch
0,5. C hat Item 1, Prompt 0,1 und Modell 0,1, mit μ = 0.

Numerische Zufallseffekte einschließlich der drei Wechselwirkungen und
des Rests sind unabhängige zentrierte Normalvariablen; die Fit-Vorgabe
enthält Wechselwirkungen. S-boot-7 zieht unabhängige normale Item-, Prompt-
und Modelleffekte, danach Bernoulli-Antworten mit `plogis(eta)`; kein
zusätzliches normalverteiltes Residuum wird addiert. Der binäre Fit
verwendet Logit und die Vorgabe ohne Wechselwirkungen. Die latente
Restvarianz π²/3 aus ANK-28 geht nur in die wahren latenten Gesamt-/GRR-Werte
ein. Die numerischen Lageparameter können null sein.

`boot_coverage.R` akzeptiert `--n-sim`, `--out` und optional `--scenarios`
als kommaseparierte Teilmenge; ohne Auswahl laufen alle sieben Szenarien.
Unbekannte/mehrfache Szenarien, unzulässige Argumente, zu kleine
Wiederholungszahlen oder bestehende Ausgabedateien werden benannt
abgewiesen. Der Einstieg lädt `library(llmsa)` und Ressourcen über
`system.file()`, unabhängig vom Arbeitsverzeichnis. Vorhandene hashgeprüfte
öffentliche Ankerkopien liefern ANK-16 aus der numerischen und
ANK-06/ANK-28/ANK-TOL aus der latenten Validierung. Neue Kopien oder
gefälschte Ersatzdaten werden nicht benötigt.

Daten- und Bootstrap-Seeds sind getrennt und an die feste Szenario-ID und
Wiederholungsnummer gebunden. Vorgesehene dokumentierte Zuordnung für
S-boot-j, Wiederholung r:
`data_seed = 20261102 + 2 * (j - 1) + 14 * (r - 1)`;
`boot_seed = data_seed + 1`. Es sind festgelegte Design-Seeds, keine
empirischen Referenzwerte. Integer-Überlauf wird vor dem Lauf geprüft.
`RNGkind("Mersenne-Twister", "Inversion", "Rejection")` wird pro Aufgabe
gesetzt; der aufrufende RNG-Zustand wird wie im vorhandenen Helfer geschützt.
Die bisherigen M1b-Seeds mit ihrer festen Schrittweite bleiben unverändert.

`msa_boot()` erhält den zugehörigen Seed und `level = 0.95`, aber kein
`nsim`-Argument: Die Anzahl folgt der Paketvorgabe, derzeit 200. Eine
Verkürzung für den Kurzlauf ist unzulässig. Parallelisiert werden nur
äußere Wiederholungen, höchstens `ANK-TOL.sim_runtime.cores` (derzeit 14);
der innere Bootstrap arbeitet sequentiell. `LLMSA_SIM_WORKERS` kann die
Zahl reduzieren; unter Windows arbeitet die Studie sequentiell.
Gegebenenfalls genutzte Fork-Aufrufe stehen nur unter
`inst/validation/sim/`, nicht unter `R/`. Replikatergebnisse, ihre
Reihenfolge und Seeds hängen nicht von Szenarioauswahl/-reihenfolge,
`n_sim` oder Workerzahl ab.

### Ausgabedateien, Kennzahlen und Provenienz

Ausgabe sind `boot_coverage_results.csv`, `boot_coverage_replicates.csv`
und `boot_coverage_session.txt` im angegebenen Verzeichnis. Nach Prüfung
werden die tatsächlichen Kurzlaufergebnisse als `boot_coverage_check_*`
übernommen. Replikate und Diagnosen bleiben bei einem Aggregationsfehler
erhalten; eine unvollständige Ergebnisdatei wird nicht als erfolgreicher
Lauf ausgegeben.

Replikatdatei: eine Zeile je Szenario, Wiederholung und Schätzziel,
mit mindestens diesen Spalten:

```text
scenario,rep,estimand,estimate,true,lower,upper,items,prompts,models,blocks,observations,boot_nsim,boot_level,n_singular,n_failed
```

Schätzziele sind die acht numerischen Komponenten beziehungsweise für
S-boot-7 `item`, `prompt`, `model`, dazu in allen Szenarien
`grr_pct_study_var`, `grr_pct_contribution`, `ndc`, `icc_items`.
Die festgelegte latente Restvarianz ist kein geschätztes binäres
Komponentenziel. Die vier abgeleiteten Ziele erhalten die tatsächlichen
Bootstrap-Grenzen; für Komponenten können `lower` und `upper` `NA` sein.

Wahre abgeleitete Werte folgen unabhängig der Formelsammlung §3:
GRR = alle Komponenten außer Item einschließlich Rest, TV = GRR + Item;
ndc mit Faktor, Abrundung und Mindestwert aus ANK-16. Design-/Beobachtungszahlen
kommen aus dem jeweiligen `fit$n`, nicht aus dem Sollplan. Bootstrap-Zahl,
Niveau und Diagnosen stammen aus dem tatsächlichen Ergebnis und sind
innerhalb einer Wiederholung identisch;
`n_failed + n_singular <= boot_nsim` gilt.

Scheitert der Fit, sind Schätzung, Grenzen und sämtliche Zählspalten `NA`.
Scheitert nur der Bootstrap, bleiben Fit-Schätzungen und Fit-Zählungen
erhalten; Grenzen und die vier Bootstrap-Spalten werden `NA`. Endliche
Schätzungen nicht konvergierter Fits bleiben wie im M1b-Vertrag mit
Diagnose enthalten. Es gibt keine erneute Ziehung als Ersatz für eine
misslungene Wiederholung. Warnungen/Fehler werden nachvollziehbar erfasst;
zusätzliche CSV-Diagnosespalten müssen ebenfalls deterministisch sein,
fehlender Text ist `NA`. Laufzeiten und Versionen stehen nur in der Session.

Die Ergebnisdatei enthält mindestens
`scenario,estimand,measure,value,mcse,n_sim,seed`. Nach ACC-5 gilt:

| Maß | Berechnung und MCSE |
| --- | --- |
| `bias`, `rel_bias`, `empse`, `rmse` | Für jedes Schätzziel nach Formelsammlung §9/ADR-023 Nr. 5; vorhandenen reinen Aggregationshelfer wiederverwenden. Relative Verzerrung = Bias/θ, ihr MCSE = MCSE(Bias)/abs(θ). RMSE = √MSE, MCSE = MCSE(MSE)/(2·RMSE); bei exakt RMSE = 0 auch MCSE = 0. |
| `coverage` | Für die vier Intervallziele: Anteil mit `lower <= true <= upper` über endliche Grenzen, geschlossenes Intervall; MCSE = √(p(1−p)/n). |
| `width` | Mittel der Breiten über dieselben Wiederholungen; MCSE = Stichproben-SD der Breiten/√n. |
| `singular_share`, `failed_share` | Je Szenario unter `estimand = bootstrap`: zunächst q_r = Zählung/`boot_nsim` je äußerer Wiederholung, danach Mittel und Stichproben-SD(q)/√n. Kein binomialer MCSE über n·B. |

Jedes Maß verwendet seine tatsächlich endlichen Beobachtungen; `n_sim`
bleibt die verlangte Zahl äußerer Wiederholungen. Weniger als zwei nutzbare
Werte einer Pflichtkennzahl führen zum benannten Abbruch, ohne Ersatznullen.
Die Ergebnisgruppe `bootstrap` erzeugt keine zusätzlichen Replikatzeilen.
Alle Pflichtwerte/MCSE sind endlich, MCSE nicht negativ. Die CSV-Ausgabe
bewahrt 15 signifikante Stellen wie im bestehenden Vertrag.

Die Session folgt `llmsa-class-b-v1`: Studie/Szenarien, Aufruf, `n_sim`,
Seed-Regeln samt Start-Seeds, alle RNG-Arten, R-/Paketversionen,
`sessionInfo()`, Worker, reale Laufzeit und Diagnosen. Der neue
Implementierungshash umfasst auch `msa_boot()`, Generator, Seed-Zuordnung
und verwendete Helfer. Der bestehende `sim_implementation()`-Hash der drei
M1b-Studien behält `msa_fit()` im Umfang; er wird weder abgeschaltet noch
durch ein Literal ersetzt. Alle drei M1b-Tripel werden nach der Codeänderung
neu gerechnet, selbst wenn binäre/Zwei-Stufen-Schätzungen gleich bleiben.

### Vignette und Dokumentation

Die Überschrift lautet exakt „Bootstrap intervals: coverage by scenario“.
Ein Ergebnisleser wählt über `system.file()` zuerst
`boot_coverage_results.csv`, sonst `boot_coverage_check_results.csv`.
Ein vorhandener ungültiger Vollauf löst einen benannten Fehler aus.
Prüfungen umfassen Schema, eindeutige Schlüssel, Pflichtmaße, Zahlenbereiche
und Szenarien: Vollauf alle sieben, Kurzlauf S-boot-1/-7. Das reine Einlesen
setzt keinen Abgleich mit einer separaten Replikatdatei voraus; die
Integrität von Ergebnissen und Replikaten prüft der Studien-/Abnahmepfad.

Tabellen und `n_sim` stammen vollständig aus der gewählten Datei. Knit
startet weder Simulationen noch Downloads. Kurzläufe belegen Struktur und
Reproduktion, keine nominale Überdeckung. `?msa_boot` verweist auf
`boot_coverage` und `vignette("validation", package = "llmsa")`.
Überdeckungsbefunde ergänzt erst K-M1d-7 anhand der Vollläufe. Die
Dokumentation trennt behaltene singuläre Fits von verworfenen nicht
endlichen Werten.

## Reihenfolge

1. **Ausgangsstand und Prüfwege sichern.** Anker-Hashes und geschützte
   Eingaben lesend prüfen. Vor BUILD-Änderungen `R/fit.R` und `R/grr.R`
   außerhalb des Arbeitsbaums sichern und gegen ANK-33 prüfen, für die
   lokale Bytegleichheits-Gegenprobe ohne Git. Reviewer-ADR zu ACC-15
   lesen, sobald vorhanden; Einwände nach Schema beantworten.
2. **K-M1c-1/-2/-8 implementieren.** Diagnose-FUN und Zählungen bei
   unveränderten Quantilen; ordinale Steuerung eng begrenzt ergänzen.
   Engine-Gegenrechnungen, Fehlerklassen, explizites `control` und API früh
   prüfen. Gemäß LESSONS die Fehlerklasse über alle betroffenen Aufrufwege
   untersuchen, nicht nur den zuerst beobachteten Einzelfall.
3. **K-M1c-7 und Dokumentation umsetzen.** Hinweis in Print, Bericht und
   Rd; Bytegleichheit der Werte separat prüfen. BL-87 mit Dokumentationssatz
   und belegter Robustheitsdiagnose adressieren, ohne numerischen Umbau.
4. **Studienvertrag vollständig implementieren.** Alle sieben Szenarien,
   wahre Kennzahlen, Seeds, Fehlermetadaten, Aggregation und Session.
   Zuerst kleine echte Läufe und unabhängige Nachrechnungen, auch für
   S-boot-2 bis -6; keine nur für die zwei Kurzlauf-Szenarien funktionierende
   Implementierung.
5. **Endgültige Kurzläufe erzeugen.** Endgültiges Paket in temporärer Library
   installieren; S-boot-1/-7 mit `ANK-TOL.n_check`, danach alle drei
   M1b-Studien neu rechnen. Jedes Tripel gemeinsam prüfen und übernehmen.
   Weitere Änderungen an gehashten Funktionen erfordern die betroffenen
   Neuläufe erneut.
6. **Reproduktion und Darstellung prüfen.** Unveränderte Abnahme für
   Schema, Nachrechnung, alle CSV-Spalten, Präfix/Teilmengen, Laufzeiten
   und Hash; Vignette mit Kurzlauf sowie gesonderter Vollauf-Testkopie;
   Berichte für alle drei Typen; installierter Paketcheck.
7. **Mutation und Übergabe.** Nach grünem unmutiertem Vorlauf führt der
   Orchestrator mutgate/mutfull aus. Reale Überlebende auf Vertragslücken
   prüfen, notwendige Unit-Regressionen ergänzen und betroffene Prüfungen
   wiederholen. Nur bewiesene Äquivalenz am endgültigen Quelltext beantragen.
   Befehle und echten Output in PROGRESS/Handoff; Abnahme und Commit bei
   Gates, Reviewer und Orchestrator.

Nach M1c-Abnahme rechnet der Betreiber alle vier vollständigen Studien mit
`n_sim >= ANK-06.value.n_sim_min` (derzeit 1000), festgehaltenem
Paket-/Engine-Stand und denselben Seeds. ADR-041 macht auch vorhandene
M1b-Vollläufe mit altem Implementierungshash ungültig; alle vier Studien
müssen vor M1d aktuell vorliegen.

## Risiken

| Risiko / Referenz | Umgang |
| --- | --- |
| Diagnosen verändern RNG, Rückgabematrix oder Rundung; K-M1c-1/-2/-7 | Zusatzkennzeichen nur intern, keine weiteren Refits/Zufallsziehungen; getrennte Engine- und Bytegleichheitsprüfungen. |
| Ordinales Budget verändert bisher abgebrochene Fits und Hashes; K-M1c-8, BL-92 | Vorgabe nur bei fehlendem `control`; alle neun M1b-Dateien wirklich neu erzeugen, Nichtkonvergenz weiter erfassen. |
| Studienlaufzeit; BL-12/-13, ACC-8/-9 | Bootstrap-Vorgabe und n_check beibehalten; äußere Wiederholungen bis zur erlaubten Kernzahl. Auch S-boot-2 bis -6 messen, bevor der Vollauf geschätzt wird. |
| Unterdeckung bei wenigen Faktorstufen; BL-04 | Untersuchungsergebnis mit MCSE, kein Anlass zum Ändern von Quantilen oder Auswahlfiltern. Befunde des Vollaufs in M1d. |
| Fehlende Daten / zu wenige endliche Werte; §8, ACC-5/-6 | Benannter Fehler mit Szenario/Schätzziel/Phase, Replikate und Diagnosen bewahren, keine Ersatzdaten. |
| Numerische Grenzen / Optimierertoleranz; BL-87/-91/-108 | Grenzen und Regressionen erhalten; stille Fehler regulärer Pflichtdesigns beheben, bekannte benannte Grenzen belegen und gemäß Backlog terminieren. |
| Socket-/Uhrzeitfehler der Sandbox; BL-86 | Echte `[INFRA]`-Befunde mit Befehl/Output übergeben. Keine Berechtigungsumgehung, Teständerung oder Netzinstallation; reguläre Gates entscheiden. |
| Alte Mutationsfreigaben nach Zeilenverschiebung; BL-85/-102 | Keine M1b-Approvals übernehmen. Claims auf endgültige Datei, Mutator, Zeile und konkreten Ausdruck des M1c-Berichts beziehen; Reviewer entscheidet. |
| Betreiberänderungen / Rollback; BL-55/-103/-105/-106 | Nur zugewiesene Pfade bearbeiten; fehlende Eingaben melden. Harness-/Gate-Zustandskorrekturen bleiben beim Betreiber. |

Lesend geprüft wurden die letzten Zuweisungen in `orchestrator/config.env`:
Scope `^R/(fit|grr)\.R$`, Mindestwert und Floor 80, Ratchet 2, Worker 14,
`MAX_ROUNDS_REWORK=5`, `MUTFULL_MILESTONES=M1c` und
`MUTFULL_FILES=R/fit.R,R/grr.R`. `88-mutfull.sh` liegt ausführbar vor.
`MUT_TEST_DIRS` umfasst Unit, Acceptance, E2E und Fuzz, nicht Simulation.
Die von ACC-14 verlangte Ergänzung ist bereits konfiguriert:

```text
^(m2-[0-9]|m0-testthat-count$|m1b-[23]-|m1b-7-vignette-full|m1c-[34]-|m1c-5-vignette-full|m1c-8-check-runs)
```

Diese Ausschlüsse gelten nur für Mutation; die Langläufe bleiben im
regulären tests-Gate. Der Builder ändert diese Auswahl nicht.
`orchestrator/state/mut-baseline` enthält 94,09: bei unverändertem Stand
verlangt `86-mutgate` 92,09, während K-M1c-6/`88-mutfull` mindestens 80
fordern. Beide Gates bleiben maßgeblich. ADR-041 erlaubt dem zweiten Gate,
denselben tatsächlich erzeugten Bericht innerhalb derselben Gate-Runde
bei passendem Commit, Konfigurationsschlüssel und vollständiger Dateiliste
zu prüfen. Der Umfang wird nicht verkürzt. Ein unmutiert roter Vorlauf ist
kein verwertbarer Mutationsbeleg.

### Offenes BACKLOG: Entscheidung zu jedem Eintrag

Die folgenden 77 Einträge sind offen oder enthalten noch offene Teilaufgaben.
Vertagungen nennen Zuständigkeit und nächsten Anlass. Bereits erledigte
Teilaufgaben schließen einen Eintrag nicht automatisch. `[INFRA]` und
fremde Territorien sind für den Builder nonblocking. Änderungen an
`BACKLOG.md` erfolgen durch Reviewer beziehungsweise QA.

| ID | Behandlung in M1c / Begründung und nächste Zuständigkeit |
| --- | --- |
| BL-01 | M0/M2/M1 bis 26.11. priorisieren; M1c liefert den dafür erforderlichen Umfang. Entscheidung über M3 nach M1d beim Betreiber. |
| BL-02 | Neuheitsprüfung für die Publikation an Betreiber/Autoren vor Einreichung vertagt; kein M1c-Kriterium. |
| BL-03 | `two_level_check_*` in K-M1c-8 neu erzeugen, β̂²/2 unverändert. Vollauf durch Betreiber, Biasbefund in K-M1d-7 statt unbelegter Korrektur. |
| BL-04 | In K-M1c-3/-4 durch Überdeckungsstudie mit MCSE bearbeiten; quantitative Befunde des Vollaufs nach M1d. Unterdeckung nicht zur Programmabweichung umdefinieren. |
| BL-05 | M2-Memorization-/`prior_differs`-Regel erhalten. Bewertung am AP1-Store vor endgültigem Bericht durch Betreiber; keine Pipelineänderung für M1c. |
| BL-06 | Modellumleitung anhand Reviewer-Logs durch Betreiber beim nächsten Logcheck prüfen; Builder ändert keine Rollen-/Modellkonfiguration. |
| BL-07 | Anbieter-/Generation-Metadaten und Wiederholungstag bei Live-AP1 durch Betreiber prüfen. M2-Verhalten als Regression erhalten; M1c braucht keine Liveaufrufe. |
| BL-08 | Datenschutzkonzept für AP7 bis zu dessen Betreiberfreigabe vertagt; M1c nutzt synthetische Studiendaten und bestehende Orakeldaten. |
| BL-09 | Quellen-/Urheberrechtsgrenzen fortführen: vorhandene öffentliche Ankerkopien nutzen, keine Rohquellen oder INSAID-Klassen veröffentlichen. Spätere Freigaben bei Betreiber/Reviewer. |
| BL-10 | Preprint-Termine 15./19.11. bleiben Betreiber-/Autorenaufgabe. M1c liefert Statistikbelege; Publikationsentscheidung erst mit M1/AP1-Befunden. |
| BL-11 | Kostenmessung aus Betreiber-Logs bei ihm belassen, kein Dashboard-/Schlüsselzugriff. M1c liefert Laufzeiten für nächste Budgetentscheidung. |
| BL-12 | Reale Szenario-/Worker-Laufzeiten protokollieren und Vollaufkosten daraus schätzen. Betreiber reserviert Rechenzeit nach M1c; alle Volläufe vor M1d. |
| BL-13 | Test-/Simulations-/Mutationslaufzeiten belegen. Langsimulationen nur gemäß bestehender Mutationsauswahl ausnehmen; weitere Harnessoptimierung beim Betreiber, ohne Grenzwertänderung. |
| BL-14 | Bootstrap-Testlücken durch unabhängige Engine-Gegenrechnung, Randfälle, Reproduktionsnachrechnung und Mutation bearbeiten. Übrige alte Pfade bleiben ihren Meilensteinen zugeordnet. |
| BL-15 | Fleiss-Dokumentation bis M3a vertagt; betrifft keine M1c-Schnittstelle. Zuständig dort Builder gegen Reviewer-Vertrag. |
| BL-17 | ellmer-/Livevergleich nach M3d beziehungsweise AP2 vertagt; M1c benötigt keine neuen Backend-Fixtures oder Modellaufrufe. |
| BL-18 | Falsche Bootstrap-Meldung in K-M1c-2 korrigieren. Separater Datenhash-Wechsel MD5 → SHA-256 bleibt K-M3d-5. |
| BL-20 | Wine-Komponentenvergleich und Installationskontrolle getrennt erhalten; K-M1b-1 und K-M1c-8 als Regression. Keine Formelanpassung zur künstlichen Literaturübereinstimmung. |
| BL-21 | Weiterer geschachtelter NIST-Fall mangels M1c-Kriterium vertagt; Reviewer legt bei numerischer Erweiterung Quelle, Anker und Abnahme fest. |
| BL-22 | AIAG-Pooling/Interaktionswahl unverändert durch bestehende numerische Abnahme absichern; keine neue ANOVA-Konvention. |
| BL-23 | NIST-Schwierigkeitsbericht erhalten, weitergehende numerische Optimierung vertagen. Aktuelle Pflichtdesigns dürfen keine Regression zeigen. |
| BL-24 | Mutationsbaseline erst vor Ausweitung auf alle R-Dateien ab M3a durch Betreiber zurücksetzen; keine Rücksetzung in M1c. |
| BL-25 | Keine neuen Builder-Anker. Reviewer hält ANK-32/ANK-33 und Auslegungen nach ACC-15 fest; spätere Ankernachträge nur mit ADR. |
| BL-28 | AP1-Schlüssel, Budget und Erhebung beim Betreiber außerhalb des Arbeitsbaums; M1c führt keine Modellaufrufe aus. |
| BL-29 | Infevers-Nutzungsfreigabe vor dem betreffenden Anwendungsfall durch Betreiber beschaffen; für die synthetische M1c-Studie nicht benötigt. |
| BL-30 | Pages-/Zenodo-/AP2-Veröffentlichung bis Release/Paper durch Betreiber vertagt. M1c liefert offline baubare Dokumentation. |
| BL-31 | Git-Identität beim nächsten Betreiber-Releasecheck klären; Commits durch Orchestrator, keine Git-Kommandos durch Builder. |
| BL-33 | CLI-/Sandbox-Vorabprüfung vor Harness-Läufen durch Betreiber; Builder verändert weder Berechtigungen noch Modell-Flags. |
| BL-34 | Erreichbarkeit für Eskalationen beim Betreiber; einziger Human-Touchpoint bleibt die vom Harness bediente `orchestrator/ESCALATION-M1c.md`. |
| BL-35 | Benachrichtigungs-/Templatepflege im nächsten Betreiber-Wartungslauf; kein Produktkriterium von M1c. |
| BL-36 | WSL-/Textspiegel-Leistung beim Betreiber. Tatsächliche M1c-Laufzeiten messen; geschützte Quellen/Arbeitsbäume nicht eigenmächtig verlagern. |
| BL-37 | Kostentelemetrie beim nächsten Betreiber-Kostenreview auswerten; keine fachlich unverbundene Harnessänderung. |
| BL-39 | Fehlende Standards vor späterer M3-/AP7-Nutzung durch Betreiber beschaffen und Reviewer verankern; M1c nutzt keine unbeschafften Zahlenquellen. |
| BL-40 | Konkordanzliteratur/-anker vor ClinVar-Vignette in M1d durch Betreiber/Reviewer bereitstellen; nicht Teil der Bootstrap-Studie. |
| BL-41 | Landis-/Koch-Quelle vor einer tatsächlichen Kappa-Klassennutzung beschaffen/verankern; M1c führt diese Konvention nicht ein. |
| BL-42 | AIAG-Datenblatt liegt wieder vor; vor Regressionen Existenz und ANK-10-Hash prüfen. Weitere lokale Datenblätter vor ihren Meilensteinen durch Betreiber/Reviewer, keine Ersatzdaten oder Skips. |
| BL-43 | Modellkennungen, Preise und Provider vor Live-AP1 durch Betreiber prüfen; synthetische M1c-Studien hängen nicht daran. |
| BL-44 | Fleiss-Varianzquellen bis M3a an Reviewer/Betreiber vertagt; M1c verwendet festgelegte Bootstrap-/MCSE-Formeln. |
| BL-45 | Externe Projekt-/Claude-Dokumentation nach Meilensteinabschluss durch Betreiber pflegen; verbindliches Gedächtnis hier bleibt Handoff/PROGRESS. |
| BL-46 | Neue Vignette liest Ergebnisse ohne Studienlauf. Weiteren Zeit-/Größenzuwachs durch M1d-Vignetten dort prüfen; M1c-Paketcheck bleibt Pflicht. |
| BL-47 | VariantBench-Zitation/Autorenklärung vor Veröffentlichung durch Betreiber/Autoren; keine neue Datennutzung in M1c. |
| BL-48 | `[INFRA]`/ACC-21: In `docs/gates-auswahl.md` fehlen für M1c K-M1c-7/-8. Betreiber ergänzt die Zuordnung; Builder ändert keine Gate-Auswahl. |
| BL-49 | Verankerte Steuerung für REML-/ANOVA-Vergleiche erhalten, Bootstrap bleibt bei gespeicherten gewöhnlichen Refits. Bestehende Abnahme schützt vor stiller Optimiereränderung. |
| BL-50 | CV-/Planungsapproximation bis M3c vertagt; sie steuert weder diese Studie noch die Bootstrap-Schnittstelle. |
| BL-51 | `acmg_*` bleibt intern; Exportentscheidung nach AP1 per ADR. M1c fügt keine Exporte hinzu. |
| BL-52 | AP1 nach M1 endgültig auswerten, frühere Zahlen vorläufig nennen. Betreiber berücksichtigt dann ADR-040/ADR-041-Sensitivitäten. |
| BL-55 | `[INFRA]` Betreiberdateien/Rollback: keine Nebenänderungen; verbleibende Harnesspflege beim Betreiber, siehe BL-103/-106. |
| BL-57 | Argumentpositionen/-defaults gemäß ANK-02 erhalten; keine neuen Argumente und keine Snapshot-Änderung. Paketprüfung als Obermenge bleibt erhalten. |
| BL-60 | ellmer-/httr2-Streaming-Machbarkeit bis M3d vertagt; Betreiber liefert zuvor nötige Aufzeichnungen/Abhängigkeiten. |
| BL-64 | Pilot-Quantiltyp-Entkopplung bis nächster AP1-Pipelinepflege vertagt. Freigegebener Plan nutzt Typ 7; M1c ändert keinen Pilotvertrag. |
| BL-68 | Meldung über unveränderten Store vor endgültigem AP1-Bericht in Pipelinepflege klären; keine Abhängigkeit zu K-M1c-1 bis -8. |
| BL-70 | Template-Status/Timeout/STOP-Verhalten beim nächsten Betreiber-Wartungslauf; Builder schreibt keinen Orchestrator-Zustand. |
| BL-71 | ClinVar-Datumsproxy/Archiventscheidung für Memorization vor endgültigem AP1 durch Betreiber/Reviewer per ADR; keine Golden-Änderung in M1c. |
| BL-72 | Plattformfeste Pfad-/Toleranzprüfungen als Regression erhalten; Windows-Releasebeleg beim Betreiber, neue R-Produktpfade forkfrei. |
| BL-73 | Pilotkosten-Dokumentation/Sol-Vorberechnung vor AP1-Abschluss in Betreiber-/Pipelinepflege vertagt; M1c benötigt keine API-Kostendaten. |
| BL-74 | Blockparallelisierung gegen API-Latenz an AP1-Betrieb vertagt; Simulation parallelisiert nur äußere Wiederholungen. |
| BL-75 | `network_wait_s`-/Latenzdokumentation vor AP1-Endbericht korrigieren; kein Zusammenhang mit R-Simulationslaufzeiten. |
| BL-77 | Befunde mit prüfbaren Kriterien-/Spec-Referenzen übergeben. Falsche QA-Zitate und Template-Regeln korrigieren Reviewer/Betreiber; keine Builder-Änderung an QA-Handoffs. |
| BL-79 | Mutationsbericht-Archivierung bei Betreiber-Harnesspflege. ADR-041 deckt bereits Wiederverwendung innerhalb einer Runde; Builder referenziert echte aktuelle Berichte. |
| BL-80 | Nonblocking falsche NIST-Zeilenangabe in Spec durch Betreiber korrigieren. Produkt-/Testbezug bleibt unverändert; keine Builder-Spec-Bearbeitung. |
| BL-81 | Fehlende latente Gruppierungswerte weist der aktuelle Code bereits ab. K-M1b-6 als Regression erhalten; formale Schließung dem Reviewer überlassen. |
| BL-84 | Alte nicht blockierende Mutationslücken erneut bearbeiten, wenn aktueller Bericht eine Pflichtlücke oder ein rotes Gate zeigt; übrige Erweiterungen nach 26.11. gemäß ADR-035. Keine pauschale Äquivalenz. |
| BL-85 | Neue Claims an endgültige Zeilen und konkrete Mutanten binden, alte Freigaben nicht übernehmen. Hashfestere Approval-Zuordnung später beim Betreiber. |
| BL-86 | Socket-/Zeit-Infrastruktur mit echten Ausgaben getrennt übergeben; reguläre Gates durch Betreiber. Kein Scheinfix und keine geänderte Prüfschwelle. |
| BL-87 | E59-Dokumentationsweg in M1c: `checkConv`-Warnungen können einem Darstellbarkeitsfehler vorangehen. Hohe Wiederholpräzision mit vorhandenen Generatoren diagnostisch belegen, Erfolg/benannten Fehler protokollieren und vor M1d-Vignette einordnen. Numerische Abbruchregel separat gemäß BL-108/ADR-035. |
| BL-91 | Vorhandene Builder-Dokumentation erhalten. Reviewer entscheidet in M1c/M1d über eigenen Permutationsanker; Builder erweitert keine Toleranz oder Optimierervorgabe. |
| BL-92 | K-M1c-8 erhöht ordinale Limits und erzeugt alle Kurzläufe neu. Nichtkonvergenz sichtbar halten; Volläufe durch Betreiber neu rechnen, Befunde in M1d. |
| BL-93 | Reviewer-interne Formel-/Warnungsbereinigung der Abnahmetests bleibt nonblocking Wartung; keine Builder-Teständerung oder Warnungsunterdrückung im Produkt. |
| BL-100 | Numerische Identifizierbarkeit bei `...`/`subset` ausdrücklich nach 26.11. gemäß ADR-035 Nr. 2/3 vertagt. Dokumentierte Grenze bleibt, kein neuer Durchreichpfad. |
| BL-101 | Termauswahl bei Gewicht null nach 26.11. gemäß ADR-035 vertagt; bekannte Grenze bleibt. K-M1c-8 ändert nur die fehlende ordinale Steuerung. |
| BL-102 | Historische 82 nicht freigegebene Überlebende nach 26.11. gemäß ADR-035 Nr. 5. In M1c zählen neuer Bericht und aktuelle Ratchet; nötige Pflicht-/Gatelücken sofort bearbeiten. |
| BL-103 | Wiederherstellung und Projekt-Rollbackschutz laut ADR-039 umgesetzt; AIAG liegt vor. Weitere Inventur ignorierter Betreiberdateien und Template-Übertragung bleiben Betreiberarbeit; keine Schlüsselzugriffe. |
| BL-105 | M1b abgenommen, Rundenbudget wieder 5. Vorabprüfung geschützter Eingaben als Infrastruktur bleibt Harnessaufgabe; Abnahmetests dürfen nicht überspringen. |
| BL-106 | Dauerhafte Bindung der Territoriumsprüfung an Modellphasen-Commit beim Betreiber/Template. Betreiberänderungen in eigenen Phasen, keine nebenläufigen Eingriffe während Builder/Gates. |
| BL-107 | Scope/Ratchet/Rundenbudget zurückgestellt, Berichtsnutzung innerhalb einer Runde umgesetzt. Betreiber prüft CONFIG beim Start; leerer Scope als Fehler, rundenübergreifender Cache und Template-Übernahme bleiben offen. |
| BL-108 | Numerische Abbruchregel auf x86-64/arm64 nach 26.11. gemäß ADR-039/ADR-035 untersuchen; benannte Grenze dokumentiert lassen, Tests nicht lockern. |
| BL-109 | Repeatability-Hinweis mit K-M1c-7 vollständig umsetzen/testen. AP1-Sensitivität mit Wechselwirkungen und Bericht bei endgültiger Betreiber-Auswertung. |

Als erledigt geführter Bestand wird nicht wieder eröffnet: BL-16, BL-19,
BL-26, BL-27, BL-32, BL-38, BL-53, BL-54, BL-56, BL-58, BL-59,
BL-61, BL-62, BL-63, BL-65, BL-66, BL-67, BL-69, BL-76, BL-78,
BL-82, BL-83, BL-88, BL-89, BL-90, BL-94, BL-95, BL-96, BL-97,
BL-98, BL-99 und BL-104. Bestehende Regressionen bleiben erhalten, auch
für die Betreiberkorrekturen aus ADR-039. Damit sind alle 109 Einträge
des gelesenen BACKLOG zugeordnet.

## Testplan

Die folgenden Läufe sind BUILD-/Gate-Arbeit. In PLAN wurde kein R-Test,
Paketcheck, Simulations- oder Mutationslauf ausgeführt und kein M1c-Kriterium
als erfüllt erklärt. Abnahmetests, Anker, Schwellen, Golden-Daten und
Gate-Regeln bleiben unverändert.

| Kriterium | Nachweis und Fälle |
| --- | --- |
| K-M1c-1 | Unverändertes `test-m1c-1-boot-bootmer.R`: numeric und binary, jeweils Niveau 0,90/0,95, feste Seeds, unabhängige `VarCorr`-/GRR-FUN gegen bootMer, alle sechs Punkt-/Intervallschätzer, ANK-TOL.engine_boot. AST-Prüfung aller R-Dateien auf verbotene Parallelaufrufe. |
| K-M1c-2 | `test-m1c-2-boot-failed-singular.R`: Fehler im 2., 7. und 15. Refit von 20; Referenzzählungen, Quantile einschließlich singulärer Fits, getrennte Diagnosezeilen auch bei 0/0. Eigene kleine Fälle für teilweise nicht endliche Zeilen, `Inf` statt nur `NA`, unveränderte Rückgabematrix und unsichtbaren Print-Rückgabewert. Keine aus erwarteten Testzahlen hart erzeugten Diagnosen. |
| K-M1c-3 | `test-m1c-3-coverage-script.R`: Skript/Tripel, alle Schätzziele/Diagnosespalten und MCSE, unabhängige wahre Kennzahlen und Nachrechnung. Installierter Aufruf aus fremdem Arbeitsverzeichnis; S-boot-2 bis -6 mit je zwei Wiederholungen. Rd verweist auf Studie und Vignette. |
| K-M1c-4 | `test-m1c-4-coverage-rerun.R`: S-boot-1/-7, ANK-TOL.n_check = 20; alle Replikatspalten nach elementweisem `format(x, digits = 15)` identisch. Sämtliche Maße aus Replikaten nachrechnen, ANK-TOL.arithmetic. Präfix n=2 nur S-boot-7, vollständige Session. Walltime des Rscript-Laufs ohne Installation höchstens ANK-TOL.sim_runtime = 20 Minuten auf höchstens 14 Kernen. Eigene kleine Prüfung von Auswahlreihenfolge/Workerunabhängigkeit. |
| K-M1c-5 | Beide Vignettentests: Kurzlauf sowie temporäre installierte Vollauf-Testkopie mit abweichenden Werten und `n_sim`; Ausgabe muss die eingelesene Datei spiegeln. Keine Ergebnisliterale oder festes Kurzlauf-n. Offline bauen, R CMD check ohne ERROR/WARNING. |
| K-M1c-6 | `test-m1c-6-mutfull.R` prüft Konfiguration; maßgeblicher Beleg ist `88-mutfull: pass` über beide Kerndateien, jeweils mit tatsächlich bearbeiteten Mutanten. Killed/Timeout zählen, RuntimeError nicht; Äquivalenz nur nach Reviewer-Approval. `86-mutgate` muss zusätzlich seine aktuelle Ratchet erfüllen. |
| K-M1c-7 | `test-m1c-7-latent-note.R`: ordinale/binäre Ausgabe, Berichtposition/Rd, Abwesenheit bei numeric. `test-m1c-7-byte-equality.R`: neun GRR-Fälle mit Basis/Schwellen, Logit/Probit und abgeleitetem Zwei-Stufen-Modell sowie zwei Bootstrap-Fälle gegen ANK-33/`done/M1b`. Werte, Namen, Klassen und Bootstrap-Matrix identisch; nur zugelassene Diagnose-/Zusatzattribute ausgenommen. |
| K-M1c-8 | `test-m1c-8-iteration-limit.R`: beobachtete Steuerung bei Probit/Logit ohne control, mit Hess und im Zwei-Stufen-Modell; `clmm.control(iter.max = 7)`, `list(eval.max = 50)` und `list()` unverändert. Wine-Komponenten gegen direkte Engine innerhalb ANK-TOL.engine_ordinal, je Komponente relativ zur Referenz-Gesamtvarianz. Rd nennt Limits/Ersetzung. `test-m1c-8-check-runs.R` prüft neue M1b-Hashes und Abhängigkeit von `msa_fit`; K-M1b-2/-3 prüfen alle Spalten, Maße, Präfixe und bestehenden Laufzeitgrenzen. |

Belege werden unabhängig vom jeweiligen Produkthelfer berechnet:
Bootstrap-Referenz mit eigener `VarCorr`-/GRR-FUN nach Formelsammlung §3
und ANK-16/ANK-28, zusätzlich explizite Quantilnachrechnung aus den
Referenzwiederholungen. Für die Studie werden analytische wahre Kennzahlen
und sämtliche Performance-Maße separat aus gespeicherten Einzelschätzern
nachgerechnet (Formelsammlung §9/ADR-023). Eigene Unit-Tests ergänzen
Fehler-/Invarianzklassen und kopieren nicht bloß den Implementierungspfad.
Engine-Toleranzen, arithmetische Toleranzen und MCSE-Berichtsschwelle werden
nicht vermischt. Der Kurzlauf beweist keine quantitative Überdeckung.

Vorgesehene lokale Testaufrufe mit dem Quellpaket:

```bash
Rscript --vanilla -e 'testthat::test_dir("tests/testthat", filter = "^(boot|fit-ordinal-control|grr-latent-note|grr-rework|validation-bootstrap)$", load_package = "source", stop_on_failure = TRUE)'
REPO_ROOT="$PWD" Rscript --vanilla -e 'testthat::test_dir("tests/acceptance", filter = "^(m1c-(1-|2-|3-|4-|5-|7-latent-note|8-)|m1b-[1-7]-)", load_package = "source", stop_on_failure = TRUE)'
```

Der zweite Aufruf enthält teure Läufe und folgt erst nach Erzeugung der
endgültigen Artefakte. M1b-/M1c-Tests teilen so ihren Reproduktionscache in
einem frischen Prozess. Wiederholung nur nach relevanten Änderungen oder
ungeklärtem Fehler. Gesamte bestehende Unit-Suite und betroffene numerische
Regressionen bleiben erforderlich. Eigene Studien-Negativtests verwenden
kleine ausdrücklich synthetische temporäre Daten, keine Änderung unter
`tests/fixtures/`.

Reproduktionsbefehle mit dem zuvor installierten endgültigen Paket,
jeweils in frische Ausgabeverzeichnisse:

```bash
Rscript --vanilla inst/validation/sim/boot_coverage.R --n-sim 20 --scenarios S-boot-1,S-boot-7 --out /tmp/llmsa-m1c-build/coverage
Rscript --vanilla inst/validation/sim/boot_coverage.R --n-sim 2 --scenarios S-boot-7 --out /tmp/llmsa-m1c-build/prefix
Rscript --vanilla inst/validation/sim/boot_coverage.R --n-sim 2 --scenarios S-boot-2,S-boot-3,S-boot-4,S-boot-5,S-boot-6 --out /tmp/llmsa-m1c-build/other-scenarios
Rscript --vanilla inst/validation/sim/ordinal_recovery.R --n-sim 20 --out /tmp/llmsa-m1c-build/ordinal
Rscript --vanilla inst/validation/sim/binary_recovery.R --n-sim 20 --out /tmp/llmsa-m1c-build/binary
Rscript --vanilla inst/validation/sim/two_level.R --n-sim 20 --out /tmp/llmsa-m1c-build/two-level
```

20 ist der gelesene Wert aus ANK-TOL.n_check. Im BUILD-Handoff stehen
Installation, Library, Befehle, Laufzeiten und echte Ausgaben des verwendeten
Paketstands. Danach folgen offline Paketbau und
`R CMD check --as-cran --no-manual` in einer Paketkopie ohne Schlüssel,
Harness-Logs oder geschützte Rohquellen; das reguläre lint-Gate prüft
zusätzlich den Repository-Kontext. Keine Check-Regel wird für Grün
abgeschaltet.

Die lokale Bytegleichheits-Gegenprobe nutzt die vor BUILD gesicherten,
ANK-33-geprüften Dateien. Der unveränderte offizielle Test liest den
Bezug mit Git; ihn und andere Git-verwendende Prüfwege startet ausschließlich
der Orchestrator im vollständigen Gate-Lauf. Der Builder verändert oder
mockt diese Zugriffe nicht. Auch Gate-Skripte, Zustandsdateien und die
vollständige Mutationsausführung bleiben beim Orchestrator; Builder
bewertet echte Berichte, schreibt aber weder `gates.json` noch Approvals.

Bereits in PLAN ausgeführter, rein lesender SHA-256-Befund:

```text
R/fit.R SHA256 acb4bac7680a9f3c2f4ac4a556b81cdf3bef0cd4a0f1535a5339a0111a64f180
R/grr.R SHA256 004eedebd4e491fbecf043d695faa38b7dad39bd6f0ffd800dbd2d05c709512e
```

Beide stimmen mit `reference/anchors/ANK-33.json` überein. Das geschützte
AIAG-Datenblatt liegt vor; dessen Hashprüfung bleibt Teil der BUILD-
Vorabprüfung. Ein SHA-256-Inventar der Produkt-, Test-, Dokumentations- und
Vertragsbereiche dient abschließend nur der Kontrolle dieser PLAN-Änderung
und ersetzt weder Territoriumsgate noch Abnahme.

Die ausgeführte Python-Strukturprüfung endete mit Exit 0: sechs
Pflichtabschnitte in Schema-Reihenfolge, alle acht Kriterien, 77 eindeutige
Zeilen für offene/teiloffene Backlog-Einträge und 32 erledigte Einträge,
insgesamt 109. Der Inventarvergleich zeigte ausschließlich die Ergänzung
dieser PLAN-Datei im M1c-Handoff; die anderen 28 inventarisierten Bereiche
und die bestehende `CRITERIA.json` blieben unverändert. Beide
ANK-33-Dateihashes stimmen weiter überein. Diese Prüfung ist kein
M1c-Gate-Verdict.
