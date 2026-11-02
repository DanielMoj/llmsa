# REVIEW-INPUT — M1c BUILD

Builder · 02.11.2026 · freigegebener PLAN r1 / PLAN-REVIEW `PASS`.
Es liegen keine PLAN-UPDATE- oder ARBITER-Direktiven zu M1c vor.
Implementierung, Unit-/Property-Tests, echte Kurzläufe und Dokumentation
sind fertig. Dies ist ein Prüfinput, kein Verdict und kein Gate-Bericht.

## Kriterien und Ergebnisse

| Ref | Implementierung und ausgeführter Beleg |
| --- | --- |
| K-M1c-1 | Sechs ursprüngliche Bootstrap-Kennzahlen, unveränderte Quantile und Seeds. Direkte `bootMer`-Gegenrechnungen für numerische/binäre Fits und beide Konfidenzniveaus bestehen. Kein verbotener Parallelisierungsaufruf in `R/`. |
| K-M1c-2 | `n_failed` zählt Zeilen mit nicht endlichen Kennzahlen; `n_singular` zählt nur endliche singuläre Replikate. Die Quantile behalten endliche Werte auch in teilweise ausgefallenen Zeilen, wie vor M1c. Singuläre Werte bleiben enthalten. Die interne siebte Spalte gelangt nicht in `attr(, "boot")`; beide Druckzeilen sind geprüft. |
| K-M1c-3 | Alle sieben generativen Szenarien, sämtliche Schätzziele, tatsächliche Fit-/Bootstrap-Zähler, MCSE, Diagnosen und Szenario-Zusammenführung implementiert. Der echte Kurzlauf von S-boot-1/-7 liegt als vollständiges Tripel vor. S-boot-2 bis -6 wurden in der unveränderten Abnahme ebenfalls tatsächlich gerechnet. |
| K-M1c-4 | Der endgültige Kurzlauf wird mit dem installierten Paket aus fremdem Arbeitsverzeichnis reproduziert: Abnahme-CLI Exit 0, 107,645 s einschließlich Startaufwand, deutlich unter ANK-TOL.sim_runtime (20 min). Zusätzlich stimmen alle 24 Replikatspalten eines sequentiellen Laufs in umgekehrter Szenarioreihenfolge mit dem Präfix des 14-Worker-Laufs überein. |
| K-M1c-5 | Die Vignette liest echte Kurz-/Volllauf-Ergebnisdateien. Beide unveränderten Knit-Abnahmen, einschließlich der Reviewer-Volllaufattrappe, bestehen. Der finale Paketcheck endet mit 0 ERROR, 0 WARNING, 1 Systemzeit-NOTE. |
| K-M1c-6 | Vollständiger Mutations-Scope bleibt `R/fit.R`, `R/grr.R`. Neue Zweige sind getestet; 19 konkrete Äquivalenzanträge sind an den endgültigen Quelltext gebunden. Der native Teillauf ist durch eine Socket-Sperre blockiert. `86-mutgate` und `88-mutfull` sind weiterhin vom Betreiber auszuführen; kein neuer Gesamt-Score wird behauptet. |
| K-M1c-7 | Der genaue latente Hinweis steht nach der Tabelle bzw. unter der Repeatability-/Reproducibility-Zeile und in Rd. Alle unveränderten Hinweis-Abnahmen bestehen. Ein separater Vergleich gegen die vor BUILD gesicherten, durch ANK-33 verifizierten Quellen bestätigt bitgleiche Tabellen/Zusammenfassungen/Verdikte in neun GRR-Fällen und bitgleiche bisherige Bootstrap-Felder in drei Fällen. Den Git-basierten offiziellen Vergleich führt der Orchestrator aus. |
| K-M1c-8 | Ohne benanntes `control` werden `clmm.control(iter.max = 2000, eval.max = 4000)` gesetzt. Explizite vollständige/partielle/leere Steuerungen gehen unverändert an die Engine. Alle drei M1b-Kurzläufe wurden neu gerechnet; Hash- und Reproduktionsabnahmen bestehen. Keine Wiederholung endet mehr am Iterationslimit; zwei ordinale Fits behalten `singular convergence (7)`. |

Die Variante mit `control = NULL` wird unverändert von `clmm` abgelehnt;
es gibt keine eigene Sonderbehandlung. `Hess = TRUE` verhindert die
Vorgabesteuerung nicht. Direkte Optimiereroptionen in `...` behalten die
Vorrangregel der Engine. Beide Fälle sind zusätzlich als Unit-Test belegt.

## Antworten auf PLAN-REVIEW

- **E1 — akzeptiert:** BUILD schreibt unter `orchestrator/` ausschließlich
  diese Datei und `MUT-EQUIV.json`. Proben, Kopien und Rohlogs liegen unter
  `/tmp/llmsa-m1c-build-_nxa5o1i/` (`$work`). Kein Git-Kommando ausgeführt.
- **E2 — akzeptiert:** Zusätzliche Tests unterscheiden die neuen Zweige,
  einschließlich `NA`, `NaN`, `Inf`, `-Inf`, teilweiser Ausfälle, endlicher
  singulärer Werte, beider Nullzähler und der Steuerungsfälle. Der native
  Adapter-Vorlauf ist grün; die nachfolgende Socket-Sperre und die separate
  Prozessdiagnose sind unten belegt. Alte Approvals wurden nicht übernommen.
  Die 17 Schlüssel betreffen 19 konkrete Mutanten, einschließlich beider
  ADR-039-Fälle. Freigaben bleiben ausschließlich beim Reviewer.
- **E3 — akzeptiert:** Ein älteres Objekt ohne `n_singular` druckt
  `singular replicates: not recorded for this object`; keine erfundene Null
  und keine verschwundene Zeile. Unit-Test und NEWS sind ergänzt.
- **E4 — akzeptiert:** `?msa_fit` erklärt den Vorrang direkter Optionen in
  `...`. Der Test `iter.max = 7` ohne `control` belegt den Engine-Vorrang
  und das erhaltene Vorgabe-`eval.max = 4000`.
- **E5 — akzeptiert:** `seed` in jeder Ergebniszeile ist der erste
  Daten-Seed des Szenarios. Start-Seeds beider Zufallsströme und die Regel
  stehen in der Session. Jede Ergebniszeile enthält `n_finite`/`n_failed`
  für ihren tatsächlichen Nenner; die Vignette erklärt diese Spalten.
- **E6 — akzeptiert:** Der Ergebnisleser prüft Schema, Schlüssel,
  Pflichtmaße, Szenarien, Endlichkeit, Anteile, MCSE und verankerte
  Laufgrößen. Er prüft Seeds nur als endliche Zahl und liest keine
  Replikat-/Session-Datei. Die unveränderte Volllaufattrappe besteht.

## Änderungen und Planabweichung

Produktänderungen liegen in `R/fit.R`, `R/grr.R`, den drei zugehörigen
Rd-Dateien, dem Report-Template, der Validierungsvignette, NEWS sowie
`inst/validation/sim/`. Vier neue Unit-Dateien und die geplante Anpassung
des vorhandenen Drucktests liegen unter `tests/testthat/`.

[ADR-043](../../../docs/decisions/ADR-043-m1c-ergebnisleser-ohne-simulator.md)
dokumentiert die einzige zusätzliche Abweichung von der freigegebenen
Dateiliste: `boot_coverage_results.R` trennt den reinen Ergebnisleser vom
Generator. Der erste vollständige Unit-/QA-/Paketcheck entdeckte, dass
die Vignette durch den gemeinsamen Helfer einen M1b-Szenarioparameter in
ihre transitive Literalprüfung zog. Die Korrektur entfernt diese unnötige
Abhängigkeit. Szenario und Herkunftstest bleiben unverändert. Der
Bootstrap-Kurzlauf wurde danach tatsächlich neu gerechnet; beide CSV
sind zum ersten echten Lauf bytegleich. Die separate Leserprüfung hat
371 erfolgreiche Erwartungen; alle finalen Gesamtläufe enthalten die
Korrektur. Die roten Erstlauf-Logs bleiben verfügbar.

Die öffentliche API bleibt Obermenge von ANK-02: 22 Exporte und alle 108
ursprünglichen Argumentnamen, Positionen und Vorgaben bestätigt.
DESCRIPTION, NAMESPACE, Anker, eingefrorene Abhängigkeiten und
Abnahmetests bleiben unverändert. Die neue Studie benutzt `msa_boot()`
ohne eigenes `nsim`; Kurz- und Volllauf verwenden damit die Paketvorgabe.

## Befehle und echte Outputs

Vollständige Befehle und Output-Auszüge stehen im M1c-Eintrag von
[PROGRESS.md](../../../PROGRESS.md). Alle unten genannten Proben sind
unter `$work` gespeichert. Rückgabecodes: 0, sofern ausdrücklich anders
angegeben. Keine dieser Proben schreibt Gate-Fakten.

| Befehl / Log | Tatsächliches Ergebnis |
| --- | --- |
| `Rscript --vanilla orchestrator/lib/r-deps.R --check-only` (`deps.log`) | 25 Anforderungen erfüllt; keine Installation oder Aktualisierung. |
| Unveränderter `orchestrator/lib/r-tests.R` über Unit, E2E, Fuzz (`unit-qa-final.log`) | Unit 5644, E2E 49, Fuzz 25 erfolgreiche Erwartungen; jeweils 0 Fehler/Warnings; ein bestehender optionaler `ellmer`-Skip; 299 Testblöcke insgesamt. |
| `Rscript --vanilla "$work/acceptance.R"` (`acceptance.log`) | M1a/M1b/M1c ohne Git-Datei: 8124 erfolgreiche Erwartungen, 0 FAIL, 2 bekannte BL-93-Warnungen, 0 SKIP; 190 Testblöcke, 761,822 s. |
| `Rscript --vanilla "$work/acceptance-final.R"` (`acceptance-final.log`) | Nach ADR-043 und finalem Kurzlauf: K-M1c-3/-4/-5, 3525 erfolgreiche Erwartungen, 0 FAIL/WARN/SKIP; 20 Testblöcke, 258,471 s. |
| `Rscript --vanilla "$work/byte-equality.R"` (`byte-equality.log`) | Neun GRR- und drei Bootstrap-Fälle bitgleich; ANK-33-Hashes der gesicherten Vorher-Quellen bestätigt; kein Git-Zugriff. |
| `Rscript --vanilla "$work/api-check.R"` (`api-check-final.log`) | 22 Exporte/108 Argumente unverändert; tatsächliche Mutanten für nsim 201, nsim 199 und seed NA vom Snapshotvergleich erkannt. |
| `R CMD build --no-manual src`, danach `R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz` (`package-check-final/build.log`, `check.log`) | Beide Exit 0; Vignetten einschließlich erneutem Bau OK; `Status: 1 NOTE` (Systemzeit), kein ERROR/WARNING. Installierte Tests: `[ FAIL 0 | WARN 0 | SKIP 9 | PASS 5568 ]`. |

Die Paketkopie umfasst 158 öffentliche Dateien einschließlich aller
Unit-Tests. `REPO_ROOT` ist für den Archivcheck entfernt;
`_R_CHECK_CRAN_INCOMING_REMOTE_=false` entspricht dem lokalen Betreiber-
Check. Die Systemzeitprüfung blieb aktiv. Die neun vorhandenen Archiv-
Skips betreffen nicht ausgelieferte Fixtures/Repository-Eingaben,
den bestehenden CRAN-Report-Skip und das optionale `ellmer`; im
Repository-Lauf ist allein letzterer vorhanden.
Der anfängliche Integrationslauf überlappte die Lesertrennung; deshalb
wurden sämtliche davon betroffenen Kriterien im endgültigen Zustand
erneut ausgeführt. Es wurden keine Abnahmetests ersetzt oder umgeschrieben.

## Kurzläufe, Laufzeit und Vollläufe

Die zwölf Repository-Dateien sind aus den vier tatsächlichen CLI-Läufen
übernommen. `R_LIBS=$work/library` verweist auf das zuvor installierte
eigene Paket; Abhängigkeiten stammen aus der eingefrorenen Umgebung.
Aufrufe: `Rscript --vanilla inst/validation/sim/<study>.R --n-sim 20
--out <frischer Pfad>`; bei Bootstrap zusätzlich
`--scenarios S-boot-1,S-boot-7`. Pfade: `$work/coverage-final`,
`$work/ordinal`, `$work/binary`, `$work/two-level`.

```text
boot_coverage: 2 scenarios x 20 repetitions; 96 result rows; elapsed 176.562 s; workers 14
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 167.588 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.937 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 9.007 s; workers 14
```

Aktuelle Implementierungshashes (gegen alle vier Sessiondateien geprüft):

```text
binary_recovery / ordinal_recovery / two_level:
203bc36478f5400b1db3ca42182e290451947f49a9e528d230c3ae0f574da3b8
boot_coverage:
2dcf076e648ab6d0a957db008a7853a952b33d4dc2bc037d7c0a290cc8bf9d79
```

40/40 Bootstrap-Ausgangsfits sind endlich und konvergiert, mit je 200
Refits und insgesamt null nicht endlichen Refits. Die singulären Refits
(32–155 in S-boot-1, 20–144 in S-boot-7) sind ausdrücklich erhalten.
Die 380 Replikatzeilen enthalten Punktwerte und Intervalle; die 96
Ergebniszeilen enthalten MCSE und wirkliche Nenner. Kein Kurzlaufwert
wurde in die Vignette übertragen.

**BL-92:** Ordinal bleiben 2/80 Fits nicht konvergiert, beide S-ord-4 mit
`singular convergence (7)`; kein Iterationslimit-Abbruch. Die kleinen
Zwei-Stufen-Designs behalten ihre vorgeschriebenen Warnungen. Binary und
Two-Level liefern jeweils 40/40 konvergierte Fits und zum Vorher-Stand
bytegleiche CSV; ihre neuen Sessiondateien belegen die echten Neuläufe.
Kein Fit wurde zur Ergebnisverbesserung wiederholt oder ersetzt.

**BL-12, gemessen auf dem endgültigen Code:** Die Abnahme führte zusätzlich
die CLI für S-boot-2 bis -6 mit je zwei Wiederholungen aus (71,196 s,
10 Worker), S-boot-7 allein mit zwei Wiederholungen (29,932 s, zwei Worker)
und den vollständigen Kurzlauf erneut (106,814 s, 14 Worker).
Grobe lineare Zeitplanung bei ANK-06.n_sim_min = 1000:
`1000 * (71.196 / 2 + 106.814 / 20) = 40938.7 s`, rund 11,4 Stunden
für Bootstrap. Das ist eine Hochrechnung, kein gemessener Volllauf;
unterschiedliche Workerzahl, Systemlast und die sehr kleine Zusatzprobe
begrenzen ihre Genauigkeit. Nacht-/Tagesfenster einplanen. Andere
Hochrechnungen aus den echten Kurzläufen: ordinal rund 2,33 Stunden,
binary rund 47 Sekunden, two_level rund 7,5 Minuten, jeweils ohne
zusätzlichen Start-/Installationsaufwand und ohne Laufzeitgarantie.

Die Betreiberbefehle und `boot_merge()` stehen in
`inst/validation/sim/README.md`. Vor M1d sind alle vier vollständigen
Studien mit mindestens ANK-06 je Szenario erforderlich, einschließlich
der Reproduktion ihrer ersten ANK-TOL.n_check Wiederholungen. Frühere
Vollläufe mit anderem Fit-Hash können nicht einfach umetikettiert werden.
BUILD liefert keine Betreiber-Ergebnisdateien ohne `_check_`.

## Mutation und numerische Grenzen

`Rscript --vanilla "$work/mutation-native.R"` wählt 123 tatsächliche
Mutanten der geänderten Funktionsbereiche aus dem unveränderten
Neun-Familien-Plan (1478 Mutanten insgesamt). Die Teststrategie wird aus
dem Betreiberadapter unverändert geladen. Auswahl nur für diese Diagnose:
`^(boot|grr.*|fit-grr|fit-ordinal-control)$`, 24 grüne Testblöcke,
13,238 s. Native Ausführung mit 14 Workern: Exit 1,
`.dispatcher_start ... 16 | Permission denied`.

Eine zusätzliche Diagnose startet dieselben Mutanten/Strategie in frischen
normalen R-Prozessen (`python3 "$work/mutation-processes.py"`, Exit 0):

```text
Focused mutation diagnosis: 123 mutants; {'Killed': 93, 'RuntimeError': 24, 'Survived': 6}; elapsed 270.141 s
```

RuntimeError wird nicht als erkannter Mutant gezählt. Aus dieser Auswahl
wird kein Gesamt- oder Gate-Score berechnet. Die beiden Singularitäts-
Überlebenden `== 1` → `!= 1` bzw. `== 0` zeigten eine symmetrische
Testbelegung. Der verstärkte Unit-Test enthält zwei singuläre und einen
nicht singulären endlichen Refit. Beide tatsächlichen Mutanten scheitern
jetzt mit je `[ FAIL 1 | WARN 0 | SKIP 0 | PASS 30 ]`; der Produktcode
besteht den finalen Kernlauf mit 180 Erwartungen. Drei andere Überlebende
ändern API-Vorgaben und scheitern am separaten Snapshotvergleich. Ein
älterer Druckeinrückungsmutant bleibt in der fokussierten Auswahl
unentdeckt. Diese getrennten Nachproben werden nicht zu einem fingierten
neuen Gesamtlauf zusammengesetzt.

`equivalence-bind.R`/`equivalence-proofs.R` prüfen die wirklichen finalen
Mutanten. Alle 19 Anträge, 17 Gate-Schlüssel, stehen mit Quellhash,
Quellzeile, Spalte, Ersetzung, Begründung und neuem Beleg in
[MUT-EQUIV.json](MUT-EQUIV.json). Die bisherigen M1b-Schlüssel sind neu
gebunden, nicht freigegeben. Die zwei zusätzlichen ADR-039-Anträge
betreffen `sparse` und `perm`: jeweils 27 geprüfte Zustände,
maximale absolute Abweichung 1,819e-12 bzw. 6,822e-13 innerhalb der
verankerten Arithmetiktoleranz. Mathematische Äquivalenz wird beantragt;
Bitgleichheit dieser beiden Rechenpfade wird ausdrücklich nicht behauptet.
Die anderen 17 konkreten Mutanten sind in ihren 7 bis 9844 Prüfungen
jeweils bitgleich; Details und Originaloutput in `equivalence-proofs.log`.
Der Reviewer entscheidet jeden Schlüssel; keine Approval-Datei geschrieben.

**BL-87:** `R_LIBS=$work/library Rscript --vanilla "$work/high-precision.R"` (Exit 0)
prüft 24 balancierte Designs, vier Rauschgrößen, drei Seeds, zwei Skalen
mit einer unabhängigen geschlossenen Rechnung. Ergebnis:

```text
High-precision diagnostic: 24 cases; 12 fits; 12 named errors; 10 warnings; max component error / TV 2.7517958028590135e-10
```

Die zwölf benannten Fehler sind zehn Grenzen der Originalskala und zwei
Grenzen der auflösbaren Restvarianz. Keine rohe Matrix-/CHOLMOD-Fehlermeldung
tritt aus; die zehn echten `checkConv`-Warnungen werden nicht unterdrückt.
`?msa_fit` dokumentiert, dass eine Engine-Warnung dem benannten
Präzisionsfehler vorausgehen kann. Kein numerischer Algorithmus wurde
für diese bekannten Grenzen geändert.

## Offene Betreiber-/Reviewer-Schritte

- **[M1C-INFRA-MUTTEST] [INFRA], ref: PLAN-REVIEW E2,
  K-M1c-6 / `86-mutgate` / `88-mutfull`:** Der native Dispatcher darf hier
  keinen Socket öffnen (`mutation-native.log`, Exit 1). Reguläre Gates
  außerhalb dieser Sperre erforderlich, mit vollständigem Scope,
  14 Workern, ursprünglicher Testauswahl und nur Reviewer-Approvals.
  Ratchet aktuell 92,09 (Baseline 94,09, Toleranz 2), Vollprüfung mindestens
  ANK-32. Nicht durch den fokussierten Diagnoselauf ersetzt.
- **[M1C-INFRA-M2-SOCKET] [INFRA], ref: K-M2-7,
  `test-m2-7-robustness-pilot.R:175`, `setup-m2.R:787`:** Zusätzlicher
  Rückfalllauf K-M2-6/-7: K-M2-6 vollständig grün (383 Erwartungen);
  Gesamtoutput `[ FAIL 1 | WARN 0 | SKIP 0 | PASS 736 ]`, Exit 1.
  Der eine Fehler entsteht in `httr2::req_dry_run` → `curl_echo` →
  `httpuv`/`find_port`: `socket() (Operation not permitted)`.
  Kein Produktfix und keine Umgehung; regulärer Gate-Lauf erforderlich.
- **[M1C-INFRA-CLOCK] [INFRA], ref: lokaler Paketcheck,
  BL-86:** `Unable to verify current time`, `Status: 1 NOTE`; Exit 0,
  0 ERROR/WARNING. Keine Systemzeitprüfung deaktiviert. Keine
  Implementierungsmaßnahme erforderlich.
- **K-M1c-7 / ACC-12:** Der unveränderte offizielle Byte-Test benutzt Git
  und wurde deshalb vom Builder nicht ausgeführt. Die lokale ANK-33-Probe
  ist grün. Der Orchestrator führt den vollständigen Test aus.
- **BL-93 / ACC-21 und offene PLAN-Vertagungen:** Zwei bekannte M1b-
  Deprecation-Warnungen und die bereits dokumentierte Gate-Zuordnung in
  der Spezifikation bleiben Reviewer-/Betreiberpflege. Keine fremde Datei
  wurde zur Bereinigung geändert. Vollstudien bleiben Betreiberarbeit;
  Aussagen über deren statistische Befunde folgen in M1d.

Abschließende Inventur ohne Git (`python3 "$work/integrity-final.py"`, Exit 0):

```text
Inventory: 16 changed, 13 added, 0 removed files
Unchanged baseline files: 323/339
Inventoried protected files unchanged: 214/214
Final checked public package sources unchanged: 158/158
Repository short-run files match genuine generated files: 12/12
Equivalence claims bound to current source: 19 mutants, 17 gate keys
Prior PROGRESS history: byte-identical
No unexpected files in inventoried path groups; no package-check artifacts in repository root
```

Die 29 geänderten/neuen Dateien liegen ausschließlich im zugewiesenen
Builder-Territorium. Freigegebene Pläne, Verträge, Spezifikationen,
Abnahmetests, QA-Tests, `tests/simulation/`, Fixtures, Anker und Golden-Daten
aus der Startinventur sind unverändert. Gate-Fakten, Orchestrator-Zustand
und Approval-Dateien wurden nicht geschrieben. Commit und formale
Territoriumsprüfung erfolgen durch den Orchestrator.
