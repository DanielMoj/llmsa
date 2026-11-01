# PROGRESS — Langzeitgedächtnis des Builders

## M1b — REWORK Runde 4 (01.11.2026)

Grundlage: REVIEW/verdict-code Runde 3 (E29–E32), gates.json und Gate-Logs,
CRITERIA, ARBITER, LESSONS sowie ADR-032. Die vorhandenen acht Gates sind
Runde 3, alle `pass`; kein `error`. Dieser Eintrag berichtet lokale
Builder-Prüfungen und ersetzt weder Gate-Fakten noch Reviewer-Verdict.
Vollständige Antworten, Befehle, Rohlogpfade und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E29 umgesetzt:** `R/fit.R` prüft die latente Identifizierbarkeit mit
  fester Restvarianz und Häufigkeitsgewichten. Nullgewichte liefern keine
  Ranginformation, Antwortkategorien oder beobachteten Zufallsstufen.
  Das Gram-Kriterium enthält die Rest-Kreuzprodukte Σw − ‖Qᵀ√W Z_j‖²_F
  und die Restdiagonale Σw − p. Gewichteter fester Rang und vollständig
  aufgespannte Terme werden auf derselben Darstellung geprüft. Die
  Eigenwertregel bleibt unverändert, k zählt den Restterm mit. Fehler
  erfolgen vor beiden Engines; bei Restkonfundierung wird der Grund
  benannt. Keine neue empirische Toleranz oder Engine-Vorgabe.
- **E30 umgesetzt:** Die Fehlermeldung nennt über die Vereinigung aller
  erkannten Nullraumrichtungen ausschließlich beteiligte Terme, auch
  bei mehreren unabhängigen Relationen. Neue Tests prüfen die genaue
  Namensliste, vollständige Meldung und `call. = FALSE`.
- **E31 bearbeitet:** Alle vier konkret benannten nicht äquivalenten
  Überlebenden aus REVIEW werden getötet. Der gezielte Lauf über 163 von
  muttest erzeugte Mutanten ergibt nach Ergänzungen 154 Killed,
  7 Survived, 2 RuntimeError. Sechs Überlebende sind begründet äquivalent;
  `R/fit.R:323:74`, `>` → `>=` an der Namensdiagnoseschwelle, bleibt mangels
  allgemeinem Beweis ungeclaimt. Die zwei RuntimeErrors sind syntaktisch
  ungültige Mutanten und zählen nicht als Killed. `MUT-EQUIV.json` enthält
  17 einzeln begründete Anträge mit endgültigen Zeilen, einschließlich
  M1a-Neubindungen. Freigaben bleiben beim Reviewer; APPROVED unverändert.
- **E32 OUT-OF-TERRITORY für M1b:** ADR-032 Nr. 3 verlangt ausdrücklich
  keinen Builder-Fix; Betreiberentscheidung in M1c, BL-100. Numerischer
  Rechenkern, numerische Engine-/Refit-Aufrufe und `R/grr.R` sind bytegleich.
- **Ältere IDs:** E25 und E26 sind laut REVIEW/Gate erledigt und lokal
  erneut bestätigt (Volllauf-Fixture 204 Erwartungen; gemeinsamer QA-Lauf
  nach M1b einschließlich M2 grün). Kein offenes [QA-PENDING]. E23 bleibt
  wegen zweier Reviewer-Abnahmehelfer-Warnungen OUT-OF-TERRITORY (BL-93).

Zwei neue Unit-Dateien enthalten zwölf Blöcke mit 1088 Erwartungen:
unabhängige expandierte Beobachtungspaarrechnung samt Restterm, exakte
algebraische Rangfälle, Nullgewichte, Frequenzvielfachheiten, beide Links
und Zielgrößen mit gesperrten Engines sowie gültige gewichtete Fits gegen
direkte Engines. Das Raster über 96 Pläne/384 Aufrufe stimmt vollständig
mit der unabhängigen SVD-Referenz überein (168 identifizierbar, 198
konfundiert, 18 durch Eingabe-/Stufenprüfung abgewiesen). Die Gegenprobe
mit ursprünglicher `R/fit.R` in einer isolierten Kopie ergibt erwartete
188 fehlgeschlagene Erwartungen und drei Fehler wegen neuer interner
Argumente. Bestehende Unit-, Abnahme- und QA-Dateien wurden nicht geändert.

`man/msa_fit.Rd`, `NEWS.md` und Builder-ADR-033 dokumentieren den Rework.
Die Hilfe stimmt exakt mit der Roxygen-Erzeugung überein. Alle neun
Kurzlaufdateien wurden mit dem installierten aktuellen Paket, unveränderten
Seeds, `n_sim = ANK-TOL.n_check` (20) und 14 Workern neu erzeugt. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 110.598 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.909 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 12.002 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle Erzeugungsprozesse Exit 0; sechs CSVs bytegleich zum Rundenbeginn.
Die drei Sessiondateien tragen den separat abgeglichenen Hash
`815a3da5b543b3301f28c72da167f1ec1621410dac74e1298e00d822889a15ba`.
Keine Volllaufdateien oder Betreiberartefakte geschrieben.

Ausgeführte Schlussprüfungen, vollständige Befehle in REWORK-NOTES P1–P8:

```text
tests/testthat: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 4709 ]
tests/e2e:      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
tests/fuzz:     [ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 275 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1b: [ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
Blocks: 74; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 236.385 s
M1a: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
Blocks: 54; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 74.888 s
K-M2-6: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 383 ]
Blocks: 11; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 313.587 s
K-M2-7: [ FAIL 1 | WARN 0 | SKIP 0 | PASS 353 ]
Blocks: 9; failed expectations: 0; error blocks: 1; skipped: 0; elapsed: 250.668 s
```

Der vorhandene Unit-Skip ist der ellmer-Negativtest. Die M1b-Warnungen
sind die unveränderten `nobars`-/`findbars`-Deprecations im Abnahmehelfer.
K-M2-7 hat genau einen Infrastrukturfehler im HTTP-Replay; alle acht
anderen Blöcke, einschließlich der Robustheitsauswertung mit 165
Erwartungen, bestehen. Die Socket-Erzeugung scheitert in
`setup-m2.R:787` über `httr2::req_dry_run()`/`httpuv::startServer()` mit
`System failure for: socket() (Operation not permitted)`.

Paketbau und direkter `R CMD check --as-cran --no-manual` sind mit Exit 0
abgeschlossen: keine ERRORs/WARNINGs, eine NOTE `Unable to verify current
time.` Installierte Tests: `[ FAIL 0 | WARN 0 | SKIP 9 | PASS 4633 ]`;
die neun bestehenden Skips betreffen nicht mitgelieferte API-Fixtures/
Repository-Anker, den CRAN-Reporttest und ellmer. Beispiele einschließlich
`--run-donttest`, Vignetten und Vignettenneubau sind OK.

**OUT-OF-TERRITORY [INFRA], ohne Scheinfix:** nativer muttest-Dispatcher
(`16 | Permission denied`), zwei syntaktisch ungültige Mutanten, lokale
HTTP-Replay-Sockets, `timedatectl` ohne Systembus und externe Zeitprüfung.
Log-Belege und stabile IDs stehen in REWORK-NOTES P2/P4/P5/P6/P8. Kein
Eingriff in Berechtigungen, Tests, Gates, Schwellen oder Orchestrator-Zustand;
keine Git-Kommandos. Der vollständige Mutationslauf und neue Gate-Fakten
bleiben beim Orchestrator, Äquivalenzfreigaben beim Reviewer.

## M1b — REWORK Runde 3 (31.10.2026)

Grundlage: REVIEW/verdict-code Runde 2 (E24–E28), gates.json samt roten
Logs, CRITERIA, ARBITER, LESSONS und ADR-029. Dieser Eintrag berichtet
Builder-Prüfungen; Gate-Fakten bleiben unverändert Runde 2, `result: fail`
wegen der beiden in REVIEW beschriebenen Fremdterritoriums-Ursachen.
Die vollständigen Antworten, Befehle und echten Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E24 umgesetzt:** `R/fit.R` prüft nach Zeilenauswahl alle ordinalen
  und binären Zufallsterme einschließlich Wechselwirkungen auf getrennte
  Identifizierbarkeit nach Abzug des festen Designs. Das Gram-Kriterium
  verwendet die Eigenwertregel aus ADR-029. Vollständig aufgespannte Terme
  werden mittels Rangnachweis exakt als null behandelt, auch wenn alle
  Zufallsterme betroffen sind. Keine neue empirische Toleranz, keine
  Änderung der Engine-Vorgaben. Hilfe und Builder-ADR-030 dokumentieren
  die Umsetzung. Gültige Pläne stimmen weiter mit direkten Engines überein.
- **E27 umgesetzt:** Zwei neue Testdateien liefern zehn Blöcke mit 221
  Erwartungen: unabhängige Kovarianzrechnung, Konfundierung als Klasse,
  gültige Pläne gegen direkte Engines, explizite Labelreihenfolge, zwei
  ordinale Kategorien und erneut ausgewerteter binärer Aufruf. Alle vier
  von E27 benannten Mutanten werden getötet. Eine Gegenprobe mit der
  ursprünglichen `msa_fit()`-Definition ergibt 93 fehlgeschlagene
  Erwartungen in sieben Blöcken, keine Testfehler.
- **E28 umgesetzt:** NEWS nennt die Änderungen der Runden 2 und 3 an
  latenten Fits, einschließlich Zeilenauswahl, Gewichten, Labelprüfung,
  gespeicherten Engine-Aufrufen und `data$.msa_offset`.
- **E25 OUT-OF-TERRITORY [INFRA]:** Die bereits vor dieser Runde vom
  Reviewer korrigierte Volllauf-Fixture besteht jetzt mit 204 Erwartungen;
  Produktvalidator und Abnahmetest blieben unverändert. Reguläre
  Gate-Bestätigung bleibt bei Orchestrator/Reviewer (BL-94).
- **E26 OUT-OF-TERRITORY [QA-PENDING]:** Alle sechs M1b-QA-Befunde bestehen,
  danach scheitern die vier M2-E2E-Blöcke weiterhin am gelöschten Namespace
  von QA-M1b-004. Der frische M2-Prozess besteht mit neun Erwartungen.
  Kein Produkt-Scheinfix und kein Eingriff in QA oder Betreiberzustand;
  erforderlicher QA-Nachlauf nach ADR-029 Nr. 3 bleibt offen (BL-95).

Alle neun Kurzlaufdateien wurden nach der Produktänderung mit dem
installierten aktuellen Paket, `n_sim = ANK-TOL.n_check` (20), den
bisherigen Seeds und 14 Workern erzeugt. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 108.138 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.905 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.037 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle drei Prozesse endeten mit Exit 0. Die sechs CSVs sind bytegleich zum
Rundenbeginn, die drei Sessiondateien tragen den separat abgeglichenen
Implementierungsnachweis
`c2045c7c594adda23b5ecd516fcedf0ed28a52df00180c79f9cbea9ea0238c9d`.
Der neue Rechenhelfer gehört ausdrücklich zum Hash. Keine Betreiber-
Volllaufdatei wurde geschrieben; E21/BL-92 bleibt inhaltlich unverändert.

Abschließende tatsächlich ausgeführte Prüfungen; Rohlogs unter
`/tmp/llmsa-m1b-r3-2ug3odnl/`:

| Prüfung | Echter Output / Ergebnis |
| --- | --- |
| Vollständige Unit-Suite | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3621 ]`, 247 Blöcke, Exit 0 |
| Vollständige M1b-Abnahme | `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 3474 ]`, 74 Blöcke, Exit 0 |
| M1a-Abnahme | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 722 ]`, 54 Blöcke, Exit 0 |
| Vollständige QA-Verzeichnisse | `16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen`, Exit 1 wegen E26 |
| M2-E2E allein, frischer Prozess | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 9 ]`, Exit 0 |
| K-M2-6 | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 383 ]`, 11 Blöcke, Exit 0; wiederholt nach der im Handoff belegten Dateiinventur-Kollision |
| Öffentlicher Paketbau und installierter `R CMD check --as-cran --no-manual` | Je Exit 0, `Status: 1 NOTE`; installierte Tests `[ FAIL 0 \| WARN 0 \| SKIP 9 \| PASS 3545 ]` |
| 80 gezielte Mutationsproben | `{"Killed": 65, "RuntimeError": 4, "Survived": 11}`; Diagnose, kein vollständiger Gate-Score |

Die Unit-/Paket-Skips sind unverändert: ellmer-Negativtest sowie im
öffentlichen Paket fehlende lokale API-Aufzeichnungen/Originalanker und
der bestehende Report-CRAN-Skip. Die beiden M1b-Abnahmewarnungen kommen
weiter aus `lme4::nobars`/`findbars` im Reviewer-Helfer (E23/BL-93).
M0-Prüfwege mit Git wurden nicht ausgeführt.

**Zusätzliche OUT-OF-TERRITORY-Infrastruktur, keine Scheinreparaturen:**
Der native parallele `muttest`-Start scheitert nach grünem Vorlauf mit
`16 | Permission denied` in `.dispatcher_start` (M1B-R3-INFRA-MUTTEST).
Die 80 generierten Mutanten wurden deshalb als lokale Diagnose jeweils
in einer eigenen Paketkopie mit frischem R-Prozess ausgeführt; vier
RuntimeErrors werden nicht als getötet gezählt. Die einzige Paketcheck-
NOTE lautet `Unable to verify current time` (M1B-R3-INFRA-CLOCK);
die Zeitprüfung bleibt aktiv. Befehle und Logstellen stehen im Handoff.

Drei einzeln bewiesene Äquivalenzanträge stehen in `MUT-EQUIV.json`:
literaler Doppelpunkt bei `strsplit`, vollständig überschriebene
Gram-Anfangswerte 1 und −1. Keine Builder-Freigabe. Der letzte reguläre
mutgate-Wert bleibt Runde 2 mit 91,91 bei 91,83; ein neuer vollständiger
Lauf folgt durch den Orchestrator.

Die abschließende SHA-256-Inventur bestätigt neun geänderte und vier neue
Dateien ausschließlich im zugewiesenen Builder-Territorium. Alle 291
geschützten Bestandsdateien und alle 91 bestehenden Test-/Fixture-Dateien
sind bytegleich. Produktcode, Hilfe, `inst/`, Unit-Tests und Paketmetadaten
stimmen mit dem tatsächlich gebauten und geprüften Paketstand überein.
Keine Git-Kommandos; keine Änderung an Gates, Schwellen, Ankern, Specs,
BACKLOG oder Betreiberzustand. Drei Äquivalenzanträge bleiben ohne
Builder-Freigabe. E26 und der reguläre Gate-/Reviewer-Nachlauf bleiben offen;
dieser Eintrag erklärt kein Meilenstein-PASS.

## M1b — REWORK Runde 2 (31.10.2026)

Grundlage: REVIEW/verdict-code Runde 1 (E12–E23), gates.json samt roten
Logs, CRITERIA, ARBITER, LESSONS und ADR-027. Rollen-/Buildregeln,
Protokoll, Handoff-Schema, Spezifikationen und bestehende Prüfungen wurden
gelesen. Dieser Eintrag berichtet Builder-Prüfungen, kein Abnahme-Verdict.
Die Antworten auf jede Befund-ID, Befehle und echte Outputs stehen in
[REWORK-NOTES.md](orchestrator/handoff/M1b/REWORK-NOTES.md).

- **E12/E13:** `R/fit.R` wertet Argumente aus und speichert erneut
  ausführbare Engine-Aufrufe. Zeilenauswahl, Gewichte und Offsets gelten
  vor dem Formelaufbau; Daten, Stufen, abgeleitete Komponenten und
  Zählungen beziehen sich auf dieselben Beobachtungen. Ordinale Offsets
  sind Formelterme. Bei ordinalen Häufigkeitsgewichten ist `nobs(clmm)`
  die Gewichtssumme, während `n` Zeilen zählt; direkte Engine-Vergleiche
  belegen das. Hilfe und ADR-028 dokumentieren die Einzelheiten.
- **E14/E16:** Singularität zählt nur Zufallskomponenten. Alle ordinalen
  Zufallsterme und festen Zwei-Stufen-Designs werden vorab auf Schätzbarkeit
  geprüft. Explizite Labels werden unabhängig vom Speichertyp validiert
  und verwendet; bisherige Warnungen und Fehlermeldungen bleiben erhalten.
- **E15:** Neuer Unit-Helfer ergänzt ausschließlich die fehlende
  Dokumentationsfixture in Paketkopien über `REPO_ROOT`. Er lädt keinen
  Produktcode aus dem Original nach. Der bestehende Test bleibt
  byte-identisch; die vollständige Suite besteht auch ohne ursprünglich
  vorhandenes `vignettes/` in der Kopie.
- **E17:** Studien-Merge prüft alle Designzählungen und Diagnoseflags;
  Ergebnisleser weist ungültige EmpSE/RMSE, Anteile und Seeds zurück.
- **E18/E20:** Acht neue Testblöcke mit 179 Erwartungen verwenden
  direkte Engines, Formeln und synthetische Korruptionen. Alle acht
  erkennen den ursprünglichen Produktcode; am finalen Stand bestehen
  sie. Die Hilfe nennt die Optimierertoleranz latenter Invarianz.
  Kein Mutationsscore und kein MUT-EQUIV-Antrag ohne Mutationsbericht.

Die neun Kurzlaufdateien wurden nach der letzten Implementierungsänderung
mit dem installierten Paket, `n_sim = ANK-TOL.n_check` (20), den bestehenden
Seeds und 14 Workern neu erzeugt. Echter Generator-Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 104.210 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.879 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.795 s; workers 14
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle drei Prozesse endeten mit Exit 0. Die sechs CSVs bleiben bytegleich
zum Rundenbeginn; die drei Sessiondateien tragen den neuen Hash
`cc34f15d2cd96684043f688b41b85ab70ffefb2ba41044e161a7bf9c88c5c4a7`,
der separat mit den finalen Quellen abgeglichen wurde. E21 bleibt
unverändert berichtet: 18/80 ordinale Wiederholungen nicht konvergiert,
alle mit endlichen Schätzern (17 Iterationslimits, einmal singular
convergence). Je Szenario 1/20, 5/20, 2/20 und 10/20; S-bin und S-two
jeweils 0/40. Die Vollauswertung bleibt bei Betreiber/M1d (BL-92).

Abschließende ausgeführte Prüfungen; Details und Rohlogs unter
`/tmp/llmsa-m1b-r2/` sowie im Handoff:

| Prüfung | Echter Output / Ergebnis |
| --- | --- |
| Vollständige Unit-Suite, Arbeitsbaum | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3400 ]`, 237 Blöcke, Exit 0 |
| Vollständige Unit-Suite, Paketkopie ohne Vignetten | `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 3400 ]`, 237 Blöcke, Exit 0 |
| M1a-Abnahme | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 722 ]`, 54 Blöcke, Exit 0 |
| Alle acht M1b-Abnahmedateien | `[ FAIL 5 \| WARN 2 \| SKIP 0 \| PASS 3270 ]`, 74 Blöcke, Exit 1; ausschließlich die ungültige Volllauf-Fixture rot |
| Vollständige QA-Verzeichnisse | `16 Tests in tests/e2e, tests/fuzz; 0 fehlgeschlagen, 4 Fehler, 0 übersprungen`; alle sechs M1b-QA-Befunde grün, die vier M2-E2E-Blöcke scheitern am Namespace-Lebenszyklus |
| M2-E2E allein, frischer Prozess | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 9 ]`, Exit 0 |
| K-M2-6 und K-M2-7 | `[ FAIL 1 \| WARN 0 \| SKIP 0 \| PASS 736 ]`, 20 Blöcke, Exit 1; K-M2-6 grün mit 383 Erwartungen, ein Socket-Fehler in K-M2-7 |
| Paketbau und `R CMD check --as-cran --no-manual` | Exit 0, `Status: 1 NOTE` (Zeitprüfung); keine ERROR/WARNING; installierte Tests `[ FAIL 0 \| WARN 0 \| SKIP 9 \| PASS 3324 ]` |

Der Unit-Skip ist der unveränderte ellmer-Negativtest. Die neun Skips im
öffentlichen Paketcheck sind unveränderte Prüfungen, die lokale
API-Aufzeichnungen bzw. Originalanker verlangen, der Report-CRAN-Skip
und derselbe ellmer-Negativtest. Der vollständige Quellpaketlauf führt
die Repository-Prüfungen aus. K-M1b-2/-3 reproduzieren die Kurzläufe
byte-identisch. Es wurden keine Tests abgeschwächt oder neue Skips ergänzt.

**OUT-OF-TERRITORY, mit Log-Belegen im Handoff:**

- **M1B-R2-INFRA-FULL-FIXTURE:** Der geschützte Abnahmetest addiert 0.5
  auf jeden Ergebniswert und erzeugt dadurch `derived_share = 1.5`.
  ADR-027 Nr. 5 verlangt dessen Zurückweisung. Der Reviewer muss die
  Fixture fachlich gültig machen; der Produktvalidator bleibt streng.
- **M1B-R2-INFRA-QA-NAMESPACE:** QA-M1b-004 löscht seine temporäre
  Paketkopie, während deren Namespace noch aktiv ist. Die nachfolgenden
  M2-Tests finden kein Paket mehr. Auch mit dem alten Produktcode und
  ohne den neuen Vignettenhelfer reproduziert; Zuständigkeit QA/Betreiber.
- **E19 [INFRA]/BL-90:** Das vom Reviewer korrigierte M2-Orakel besteht
  mit 383 Erwartungen; `R/acmg.R` bleibt byte-identisch.
- **E22 [INFRA]/BL-86:** Der HTTP-Replay-Test endet mit „System failure for: socket() (Operation not permitted)“. Die lokale NOTE lautet
  „Unable to verify current time“. Keine Umgehung der Sandbox oder
  Abschaltung der Prüfungen.
- **E23/BL-93:** Zwei Deprecation-Warnungen aus dem geschützten
  Abnahmehelfer (`lme4::nobars`/`findbars`); kein Produktfehler.

Bestehende Tests, QA, Abnahme, Fixtures, Specs, Anker, Gate-Fakten und
Schwellen bleiben unverändert. Der abschließende SHA-256-Abgleich prüft
die Änderungen gegen 303 zu Rundenbeginn gesicherte Dateien sowie die
final getesteten Quellen und Paketbaueingaben. Keine Git-Kommandos,
keine Änderungen an BACKLOG oder Betreiberzustand, keine Betreiber-
Volllaufdateien. E18 und die Gate-Bestätigung bleiben offen bis zum
nächsten regulären Lauf; dieser Builder erklärt den Meilenstein nicht
für abgenommen.

## M1b — BUILD (31.10.2026)

Grundlage: freigegebener PLAN und PLAN-UPDATE, PLAN-REVIEW Runde 2 mit
PASS, ARBITER zu E1, CRITERIA samt ACC-18 sowie ADR-023/024/025.
AGENTS, IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, Spezifikationen,
Abnahmetests, bisheriger PROGRESS und LESSONS wurden gelesen.
Dieser Eintrag enthält Builder-Prüfbelege, kein Abnahme-Verdict.

Nachgetragener M1a-Abschluss gemäß PLAN-UPDATE, Reihenfolge Nr. 2:
`orchestrator/handoff/M1a/verdict-code.json` dokumentiert für Runde 5
`"verdict": "PASS"`, `"blocking": []`; die bestehenden Gate-Fakten unter
`orchestrator/state/M1a/gates.json` nennen achtmal `pass` und
`"result": "pass"`. Die dort gelesene Mutationszusammenfassung lautet:

```text
mutgate: pass (score=93.83 required=91.79 baseline=93.83 floor=80)
```

Das sind übernommene Orchestrator-/Reviewer-Fakten, kein neuer Gate-Lauf.
Die nichtblockierenden E57/BL-84, E58/BL-89 und E59/BL-87 bleiben nach
dem freigegebenen M1b-Plan vertagt; der aktuelle Builder-Lauf ändert ihre
Freigabe oder Bewertung nicht.

### Umsetzung und Einwände

- **E1 / K-M1b-5 / ACC-18:** latente Logit-ICC gegen live
  `rptBinary(expect = "liability")`, `performance::icc()` auf direktem und
  zurückgegebenem Modell und die Rechnung mit ANK-28. ANK-25 steht separat
  neben beiden rptR-Vorgabewerten als Installationsprüfung. Die wine-Prüfung
  rechnet beide Links direkt nach; ANK-21 prüft clmm2 getrennt.
- **E2:** `converged` kommt aus der finalen Engine-Diagnose. Echte
  ucminf-Eintermfits, nlminb-Matrix-/Mehrtermfits trotz ucminf-Anforderung,
  singulärer glmer-Erfolg und Limitabbrüche sind geprüft. Numerischer
  Direktweg, geschlossener und analytischer Abschluss verwenden den
  finalen lme4-Code samt Meldungen; Startdiagnosen entscheiden nicht,
  numerische Warnungswege werden nicht ergänzt oder umgeschrieben.
- **E3 / BL-81:** Binärwerte werden vor Ganzzahlkonversion exakt geprüft;
  Labelkodierung verlangt zwei eindeutige nichtfehlende Labels. Fehlende
  Gruppierungen, konstante/fehlende Kategorien enden benannt. Entfernte
  Antworten werden gewarnt; Modell, bereinigte Daten und Zählungen stimmen
  überein. Gegenrechnungen und Metamorphieprüfungen siehe ADR-026 Nr. 8.
- **E4 / K-M1b-4:** jeder ordinale Zwei-Stufen-Fit warnt mit Formel,
  positiver Verzerrung und Dokumentationsverweis. Fit und GRR nennen jede
  abgeleitete Quelle einzeln; GRR übernimmt `attr(vc, "derived")`.
  Kontrastdifferenzen liefern die gleiche Formel auch bei Sum-Codierung.
  Hilfe, NEWS und Vignette erklären die fehlende AIAG-Korrektur und
  verweisen auf `two_level`. Echte AP1-Tests behalten Range-/Ausschluss-
  warnungen ohne Rückfall und führen bei clmm-Limitabbruch den numerischen
  Rückfall mit erhaltenen Diagnosen aus.
- **E5 / K-M1b-2/-3:** drei installierbare CLI-Skripte, alle acht
  ADEMP-Szenarien, feste Seeds je Szenario/Wiederholung, alle geforderten
  Schätzziele und Kennzahlen samt MCSE. Finite nichtkonvergierte/singuläre
  Fits bleiben enthalten. Fehler bleiben als NA-Zeilen erhalten; weniger
  als zwei finite Schätzer sichert Replikate/Session vor benanntem Abbruch
  ohne Ergebnisdatei. CLI-, RNG-, Null-RMSE- und Zusammenführungsprüfungen
  verwenden kleine ausdrücklich synthetische Fixtures. Die ausführbare
  Betreiberanleitung deckt Vollläufe und geprüfte disjunkte Teilläufe ab.
- **E6:** nur Suggests ergänzt (`rptR`, `performance`, `parallel`), keine
  neue Import-Abhängigkeit und kein Export. Optionale Unit-Abhängigkeiten
  werden vor Nutzung geprüft. Vollständige Ankerkopien, Hashmanifest,
  doppelte ANK-TOL-Kopie, fehlende/veränderte Originale und öffentliche
  Paketverwendung sind geprüft; Referenzwerte werden nicht abgetippt.
- **E7/E8:** Betreiberentscheidungen ADR-024 übernommen; keine Änderung
  an Mutationsauswahl, Rollback, Gates oder deren Fakten.
- **E9/E10:** Warnungsorakel-Konflikt gemäß ADR-025 Nr. 4 separat unten
  als OUT-OF-TERRITORY [INFRA] belegt; `R/acmg.R` bleibt bytegleich.
- **E11 / K-M1b-7:** sechs signifikante Stellen vor `kable`, ganzzahliges
  `n_sim` aus der gewählten Datei. Vorhandene Vollläufe haben Vorrang;
  ungültige Volllaufdateien brechen ab. Die Vignette führt keine Simulation
  aus. Literalprüfung verfolgt Inline-R und nachgeladene Helfer.

ADR-026 dokumentiert Ressourcen/Provenienz sowie zwei Planpräzisierungen:
die ausdrücklich gewählten Optimierer in den neuen Metamorphieprüfungen
und die zusätzlich nötige Aktualisierung des eigenen Drucktext-Snapshots
in `test-grr-rework.R`. Dort bleiben alle Zahlen-, Format-, Rückgabe- und
Singularitätsprüfungen erhalten; nur die vom neuen Vertrag ersetzte
Range-Erklärung wird exakt auf die Zeilen je Quelle umgestellt. Die beiden
bereits geplanten Bestands-Testdateien erwarten die neuen Warnungen
gezielt. Abnahmetests, QA, Fixtures, Anker und Schwellen wurden nicht geändert.

### Nachweis der Entwicklung und der Kurzläufe

Der ausgeführte Ausgangslauf mit `test_dir("tests/acceptance",
filter = "^m1b-", load_package = "source")` endete mit Exit 1:

```text
M1b baseline: 74 tests; 26 failed blocks; 27 error blocks; 0 skipped
M1b baseline elapsed seconds: 32.64; exit: 1
```

Der erste vollständige Lauf nach Implementierung fand einen tatsächlichen
CSV-Fehler: `FAIL 1 | WARN 2 | SKIP 0 | PASS 3473`; beim binären Präfix
mit zwei Wiederholungen unterschieden sich zehn Meldungszellen (`NA` versus
leere Zeichenkette). Der neue Unit-Test mit normalen `read.csv()`-Vorgaben
war vor der Korrektur rot, danach grün. Fehlende Diagnosen stehen nun als
`NA` im CSV, vorhandene Meldungen bleiben erhalten. Der erste Gesamt-Unit-
und Paketcheck fand außerdem zwei alte Drucktext-Erwartungen desselben
Blocks; ADR-026 Nr. 9 und der exakte neue Snapshot beheben das.

```text
`actual$messages`:   NA NA NA NA NA NA NA NA NA NA
`expected$messages`: "" "" "" "" "" "" "" "" "" ""
After: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 253 ]
```

Die 253 Erwartungen stammen aus dem ausgeführten Nachlauf
`test_dir("tests/testthat", filter = "^validation-simulation$|^grr-rework$",
load_package = "source")`. Die unveränderte neue Präfixprüfung ist darunter.
Die übrigen gezielten Kernprüfungen bestanden zuvor mit 533 Erwartungen;
die Ressourcen- und Literalprüfungen mit 172, jeweils ohne Fehler/Warnung/Skip.

Das finale Paket wurde nur in `/tmp/llmsa-m1b-build/library` installiert;
vorhandene Abhängigkeitsversionen blieben erhalten. Erzeugung mit dem
installierten Paket aus einem fremden Arbeitsverzeichnis, `n_sim` aus
ANK-TOL.n_check; die Dateien wurden erst nach drei erfolgreichen Prozessen
byte-identisch als `_check_` übernommen:

```bash
R CMD INSTALL --library=/tmp/llmsa-m1b-build/library .
M1B_SHORT_RUN=checks-final-v2 python3 /tmp/llmsa-m1b-build/generate_checks.py
```

Der Treiber führt je Studie tatsächlich aus:

```text
Rscript --vanilla /tmp/llmsa-m1b-build/library/llmsa/validation/sim/<study>.R --n-sim 20 --out /tmp/llmsa-m1b-build/checks-final-v2/<study>
```

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 104.660 s; workers 14
ordinal_recovery: exit=0; wall_seconds=105.346
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.878 s; workers 14
binary_recovery: exit=0; wall_seconds=1.533
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 10.696 s; workers 14
two_level: exit=0; wall_seconds=11.352
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle 160 Wiederholungen liefern finite Schätzer. Gespeicherte Diagnosen:
ordinal 18/80 nichtkonvergiert und 63/80 singulär; binär 0/40 und 7/40;
two_level 0/40 und 1/40. Das sind Kurzlauf-Diagnosen, keine Befunde zur
statistischen Güte der Vollstudien. Nur neun Kurzlaufdateien liegen im
Repo, keine Betreiber-Volllaufdateien.

Weitere ausgeführte Reproduktionsprüfungen:

```bash
Rscript --vanilla data-raw/make_validation_latent.R --out /tmp/llmsa-m1b-build/resource-reproduction
M1B_WORKER_RUN=workers-final python3 /tmp/llmsa-m1b-build/check_workers.py
```

```text
Latent validation inputs: 5 byte-identical anchors; SHA-256 provenance recorded
Resource reproduction: all five whole anchor copies and SOURCES.json are byte-identical.
Worker/order reproduction: result and replicate CSVs byte-identical; 78 installed files unchanged in read-only library.
```

Die Workerprüfung rechnet S-bin-1/S-bin-2 mit `--n-sim 2` einmal mit einem
und einmal mit zwei Workern sowie umgekehrter Szenarioreihenfolge. Sie lädt
eine schreibgeschützte Installation aus einem fremden Arbeitsverzeichnis
und prüft anschließend deren vollständige Dateihashes.

### Abschließende Abnahme- und Regressionsdiagnosen

Alle folgenden Läufe verwenden R 4.6.1, lme4 2.0.6, ordinal 2026.7.26,
Matrix 1.7.4, rptR 0.9.23 und performance 0.19.0. `TZ=Europe/Berlin`
vermeidet die hier gesperrte Systembus-Abfrage von `sessionInfo()`;
Zufallsströme und Engine-Einstellungen werden dadurch nicht verändert.
Nach Abschluss der Dateierzeugung blieb der gesamte Testinput unverändert.

**Unveränderte M1b-Abnahme (Exit 0).** Ausgeführt als eigener
`TZ=Europe/Berlin /usr/bin/time -f 'M1b acceptance elapsed seconds: %e; exit: %x'
Rscript --vanilla -e '<R-Code>'` mit diesem R-Code:

```r
Sys.setenv(REPO_ROOT = normalizePath("."))
grDevices::pdf(NULL)
testthat::set_max_fails(Inf)
r <- testthat::test_dir("tests/acceptance", filter = "^m1b-",
  load_package = "source",
  reporter = testthat::ProgressReporter$new(show_praise = FALSE),
  stop_on_failure = FALSE)
d <- as.data.frame(r)
write.csv(d[, c("file", "test", "failed", "error", "skipped", "passed")],
  "/tmp/llmsa-m1b-build/m1b-tests-final.csv", row.names = FALSE)
cat(sprintf("M1b acceptance: %d tests; %d failed blocks; %d error blocks; %d skipped\n",
  nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped)))
quit(status = as.integer(any(d$failed > 0 | d$error)))
```

```text
[ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
M1b acceptance: 74 tests; 0 failed blocks; 0 error blocks; 0 skipped
M1b acceptance elapsed seconds: 225.55; exit: 0
```

Der ausgeführte Abnahmelauf für alle sieben Kriterien besteht,
einschließlich kompletter Reproduktionen aller Kurzläufe, Präfixen,
MCSE-Nachrechnungen, Laufzeitgrenzen, echtem Knit und Auswahl vorhandener
Volllaufdateien in der öffentlichen temporären Paketkopie. Die beiden
Warnungen stammen unverändert aus `test-m1b-4-two-levels.R:41–42`:
`nobars` und `findbars` sind laut installiertem lme4 nach `reformulas`
verschoben. Keine Fehl-Erwartung, kein Skip und kein Produkt-Scheinfix.

**M1a-Regression (Exit 0).** Separater Rscript-Aufruf mit demselben
`test_dir`-Laufkern, Filter `^m1a-`, gesetztem `REPO_ROOT`, PDF-Gerät nach
`NULL`, vollständiger Ergebnisauswertung und Exit ungleich 0 bei Fehlern:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a regression: 54 tests; 0 failed blocks; 0 error blocks; 0 skipped
M1a regression elapsed seconds: 47.05; exit: 0
```

**Unit-, E2E- und Fuzz-Regression (Exit 0).** Tatsächlicher Aufruf:

```bash
TZ=Europe/Berlin REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa \
  /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(NULL); source("orchestrator/lib/r-tests.R")' \
  tests/testthat tests/e2e tests/fuzz
```

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 3221 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 239 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 133.90; exit: 0
```

Der eine Skip ist der unveränderte ellmer-Fehlerpfad bei installiertem
ellmer. Beide QA-Verzeichnisse laufen vollständig und bytegleich zum
Ausgangsstand. Der bestehende Report-Test läuft hier durch `NOT_CRAN=true`
im unveränderten Testtreiber.

**Öffentlicher Paketbau und installierter Check (je Exit 0).** Eine
Positivliste kopiert 138 Paket-/Testdateien ohne Git und ohne Betreiber-
Fixtures, Schlüssel oder Harness-Zustand nach
`/tmp/llmsa-m1b-build/package-check-final/src`. Der ausgeführte Treiber ist
`M1B_CHECK_WORK=/tmp/llmsa-m1b-build/package-check-final python3
/tmp/llmsa-m1b-build/check_package.py`; er entfernt `REPO_ROOT` aus der
Prozessumgebung und führt dort mit `TZ=Europe/Berlin` aus:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
build.log: exit=0; wall_seconds=59.157
check.log: exit=0; wall_seconds=172.713
Status: 1 NOTE
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 3145 ]
```

Beide Vignetten wurden gebaut und beim Check erneut gebaut. Die neun
installierten Skips sind fünf ausgeschlossene Betreiber-Aufzeichnungen,
der CRAN-Report-Test, die beiden Originalanker-Vergleiche ohne Repository
und der bestehende ellmer-Fehlerpfad. Alle anderen neuen Tests laufen auch
installiert. Remote-Incoming entspricht dem Betreiber-Prüfskript; keine
weitere Check-Regel wurde abgeschaltet.

Vollständige Logs und Auswertungs-CSV liegen unter
`/tmp/llmsa-m1b-build/`: `m1b-acceptance-final.log`, `m1a-regression.log`,
`unit-qa-final.log`, `m2-regression-final.log`, `package-check-final/`.


### Einschränkungen und Handoff-Vorschläge

**E9/E10 — OUT-OF-TERRITORY [INFRA].** Ref: ADR-025 Nr. 4 und
Konsequenzen; K-M2-6/-7; `tests/acceptance/setup-m2.R:714,869–883`.
Der Builder unterdrückt keine Range-/Ausschlusswarnung und erweitert
keinen AP1-Rückfallauslöser. Der Reviewer muss die bereits beschlossene
unabhängige Orakelregel umsetzen und den BACKLOG-Eintrag führen.

Unveränderte K-M2-6/-7, separat ausgeführt mit demselben Rscript-
Laufkern wie oben, Filter `^m2-[67]-`, CSV `m2-tests-final.csv`, Auswertung
aller 19 Testblöcke und Exit 1 bei roten Tests. Echte Endausgabe:

```text
[ FAIL 20 | WARN 0 | SKIP 0 | PASS 689 ]
M2 regression: 19 tests; 4 failed blocks; 1 error blocks; 0 skipped
M2 regression elapsed seconds: 398.75; exit: 1
```

Genau 19 Erwartungen in vier Blöcken betreffen die bereits beschlossene
Orakelkorrektur: je Modell zweimal (`fallback` und Typ) im Hauptplan, in
den konstruierten Läufen und mit Robustheitsauswertung, dazu der Typ des
gemeinsamen Fits. Tatsächliche Ausgabe jeweils `FALSE` statt erwartetem
`TRUE` bzw. `"ordinal"` statt `"numeric"`. Der fünfte rote Block ist der
gesperrte Socket (unten). Erzwungene Fehler/Konvergenzwarnungen lösen den
geforderten Rückfall aus; die übrigen Erwartungen bleiben grün.

Ein vorheriger Lauf meldete zusätzlich zwei Datei-Inventurfehler, weil
der parallel abgeschlossene Kurzlauf seine neun neuen Dateien während
der AP1-Inventur kopierte. Das war eine Störung durch die Reihenfolge
der Builder-Diagnosen. Die vollständige Wiederholung erfolgte erst nach
Abschluss aller Dateischreibvorgänge; beide Inventurprüfungen bestehen
jetzt. Diese beiden alten Fehlschläge werden nicht als [INFRA] abgegeben.


**M1B-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Ref:
K-M2-7, `tests/acceptance/setup-m2.R:771`, `req_dry_run()` und der
HTTP-Replay-Test. Der echte Fehler lautet
`System failure for: socket() (Operation not permitted)`.
Kein Bypass und keine Abschwächung dieses Tests.

**M1B-NUM-01 — offener fachlicher Befund / Handoff-Vorschlag.** Ref: docs/01 §2
(Metamorphie), PLAN-UPDATE „Testplan“ E3/E4, ADR-026 Nr. 8.
Für den neuen synthetischen Fixture-Seed liefern Standardoptimierer trotz
gleichem mathematischem Modell kleine Parameterisierungsunterschiede
oberhalb ANK-TOL.invariance. Tatsächlich gemessen (Komponentendifferenz/TV):

```text
binary, default bobyqa/Nelder_Mead, event reversal: 1.60286127649222e-06
binary, bobyqa/bobyqa with rhoend from ANK-TOL.engine_boot: 1.03795717323999e-07
ordinal, default nlminb, sum contrasts: 1.12331735442896e-06
ordinal, default nlminb, renamed/reversed levels and rows: 8.13388012911663e-06
ordinal, default ucminf, sum contrasts: 3.25822451182535e-08
ordinal, default ucminf, renamed/reversed levels and rows: 1.16080065153201e-08
```

Reproduktion: `pkgload::load_all(".")`, beide Testhelfer
`helper-validation-numeric.R` und `helper-validation-latent.R` sourcen;
binär `latent_test_runs("binary", prompts=1L, models=1L)` in die Labels
`no`/`yes` umwandeln und `levels` vertauschen; ordinal
`latent_test_runs(prompts=2L, models=2L, blocks=2L)` mit Treatment-/Sum-
Kontrasten bzw. umgekehrten Zeilen und Zuordnung erste Stufe→`z`, zweite→`a`
fitten. Verglichen wird `max(abs(vc_new - vc_reference))/sum(vc_reference)`
nach Quellennamen. Die neuen Property-Tests verwenden die expliziten
Steuerungen aus ADR-026 bei unveränderter Toleranz und prüfen echten
Optimierererfolg. Kleinere clmm-Toleranzen allein halfen nicht zuverlässig
(ucminf-Code 4); deshalb keine pauschale Änderung der Produktvorgaben.
Die allgemeine Invarianzforderung ist für diese Vorgabepfade mit diesem
Beleg nicht erfüllt; die erfolgreichen Prüfungen mit expliziten
Optimierern ersetzen den offenen Nachweis nicht. Vorschlag an den
Reviewer: ADR-026 Nr. 8 bewerten und erforderliche Nacharbeit am
Vorgabepfad festlegen. Die Einstufung verbleibt beim Reviewer.
Logs: `invariance-diagnosis.log`, `contrast-diagnosis.log`
unter `/tmp/llmsa-m1b-build/`.

**M1B-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Ref: lint,
Paketcheck `00check.log`, „checking for future file timestamps“.
Die einzige NOTE lautet `Unable to verify current time.` Die Prüfung
blieb aktiv; der Check hat keine ERRORs oder WARNINGs. Windows wurde in
dieser Linux-Sitzung nicht ausgeführt; die Windows-CI bleibt Release-Bedingung.

### Integrität

`python3 /tmp/llmsa-m1b-build/integrity.py` endet mit Exit 0:

```text
Baseline inventory: 269 files; 11 changed in assigned Builder paths; 258 byte-identical; no removed files.
New files: 31, all in assigned Builder paths.
Changed: DESCRIPTION, NEWS.md, PROGRESS.md, R/fit.R, R/grr.R, man/msa_fit.Rd, man/msa_grr.Rd, tests/testthat/test-fit-grr.R, tests/testthat/test-fit-rework-inputs.R, tests/testthat/test-grr-rework.R, vignettes/validation.Rmd
Protected baseline tests/acceptance/: 33/33 files byte-identical.
Protected baseline tests/e2e/: 2/2 files byte-identical.
Protected baseline tests/fuzz/: 2/2 files byte-identical.
Protected baseline tests/fixtures/: 6/6 files byte-identical.
Protected baseline tests/simulation/: 1/1 files byte-identical.
Protected baseline reference/anchors/: 36/36 files byte-identical.
Protected baseline inst/extdata/: 17/17 files byte-identical.
Protected baseline orchestrator/handoff/M1b/: 8/8 files byte-identical.
Protected baseline orchestrator/state/: 3/3 files byte-identical.
final-test-inputs.json: 170 files byte-identical to the final tested inputs.
package-check-final/source-sha256.json: 138 files byte-identical to the final tested inputs.
All nine check files match the final generated files; no full-run files in the repository.
No package-check, plot, archive or SQLite artifacts at the repository root.
This inventory is a Builder integrity check, not an orchestrator gate verdict.
```

Keine Git-Kommandos, fremden Schreibterritorien, Abhängigkeitsdownloads,
realen API-Aufrufe, Test-/Gate-Umgehungen oder Builder-Verdicts. Formale
Territoriumsprüfung, Gates einschließlich Mutation und Phasen-Commit
verbleiben beim Orchestrator; kein neuer Mutationsscore wird behauptet.


## M1a — REWORK, Runde 5 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 4 verlangt REWORK wegen E54.
Die unveränderten Orchestrator-Fakten nennen acht grüne Gates, `result:
pass`, mutgate 93,74 bei required 91,79; kein Status error und kein
aktueller QA-PENDING-Befund. ARBITER fehlt, LESSONS enthält keine Lehren.
Die neue Gate-Abnahme verbleibt beim Orchestrator und Reviewer.

**E54 ist im Produktcode behoben.** `R/fit.R:514–547` schützt den
Aufbau des numerischen Originalskalenmodells: `lFormula`, `mkLmerDevfun`,
`devfun(theta)`, `mkMerMod` und das Auslesen von `VarCorr`. Fehler und
Warnungen an diesen Enginegrenzen beenden den Fit mit
`Numeric model variance is not representable on the original scale at working precision.`
Die Klasse ist `simpleError`, der Aufruf `NULL`. `checkConv` steht
separat und gibt Konvergenzwarnungen weiter. Gesammelte Startwarnungen
werden beim späteren Abbruch weiterhin in ihrer Reihenfolge ausgegeben.
Der explizite Durchreichweg behält die originalen Enginebedingungen.
Schätzer, Nullgrenze, Präzisionsgrenze und Abschlusskriterium bleiben
unverändert; ein Teilmodell wird nicht als Ergebnis verwendet.

Neu sind 18 Testblöcke in `tests/testthat/test-fit-model-construction.R`.
Die drei E54-Reproduktionen und der positive Gegenfall werden mit
`stats::aov` und den expliziten EMS-Formeln aus der Formelsammlung §2
geprüft. Fehler und Warnungen an allen fünf Enginegrenzen, aktive
Konvergenzprüfung, Startwarnungen und Durchreichweg werden zusätzlich
synthetisch geprüft. Numerische Toleranzen kommen aus ANK-TOL; nur der
Diagnosetext ist eigene Ausgabe. Vor der Korrektur scheitern 15 Blöcke
mit 47 falschen Erwartungen, danach bestehen alle 129 Erwartungen.
Die neue Datei blieb zwischen beiden Läufen gleich.

E55/BL-89 bleibt **OUT-OF-TERRITORY für diesen Auftrag, nonblocking**:
Der Auftrag untersagt die Änderung bestehender Tests. Deshalb bleibt
`test-fit-initialization.R:22–49` byte-identisch. Die neuen E54-Tests
erlauben auf einer anderen Plattform einen erfolgreichen Fit nur mit
den unabhängig berechneten ANOVA-Komponenten; sie erzwingen keinen
Engineabbruch. Synthetische Bedingungen sichern den genauen Fehlervertrag.
Windows/macOS wurden hier nicht geprüft.

E56: `?msa_fit` nennt jetzt auch den Modellbau nach geschlossener Lösung
als mögliche Fehlerstelle bei hoher Wiederholpräzision und ordnet die
mögliche Hessian-Warnung auf der Theta-Skala ein. ADR-020, Nachtrag
Runde 5, enthält die zusätzliche balancierte Gegenrechnung. Die allgemeine
Verbesserung des Abschlusses und dessen weitergehender Robustheitsnachweis
aus E51/BL-87 bleiben vor M1d offen. NEWS und die erzeugte Rd-Hilfe
dokumentieren den Produktfix.

E50 und E52 sind laut REVIEW Runde 4 erledigt. E53/BL-84 bleibt mit
seinen nicht verlangten Darstellbarkeits- und Redundanzfällen offen.
Die zehn bestehenden Äquivalenzanträge wurden gegen identische
Quellzeilen und die zwölf zugehörigen Überlebenden des Berichts Runde 4
neu gebunden: neun Einträge in R/fit.R um fünf Zeilen verschoben,
R/grr.R bytegleich. Keine neue Äquivalenz und keine eigene Approval.
E48/BL-85, E49/BL-86 und E41/BL-79 sind OUT-OF-TERRITORY [INFRA].
E39/BL-77 und E42/BL-80 bleiben beim Betreiber/Reviewer,
E43/BL-81 gemäß ADR-022 in M1b. BACKLOG bleibt unverändert.

Vollständige Antworten, Kommandos und Log-Bezüge stehen in
`orchestrator/handoff/M1a/REWORK-NOTES.md`; Diagnoseartefakte unter
`/tmp/llmsa-m1a-r5/`. Echte Ausgaben dieser Runde:

```text
Model construction regression: 18 tests; 15 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 129 ]
Model construction regression: 18 tests; 0 failed blocks; 0 errors; 0 skipped
120 cases; 8 raw errors before, 0 after; 6 arithmetic warnings before, 0 after
45 unchanged successful fits; maximum component/TV error against aov EMS 3.76805041e-09 (ANK-TOL.oracle 0.0001)
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2809 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 215 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 80.00; exit: 0
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 37.05; exit: 0
```

Die drei E54-Einzelfälle liefern jetzt den Darstellbarkeitstext,
`simpleError`, `call = NULL` und null Warnungen. Die Sensitivitätsrechnung
verwendet 120 feste synthetische Prüfeingaben: 6×4×1×2, 8×3×1×3 und
10×3×2×2 (Items×Prompts×Modelle×Replikate), Effekte mit Seed 11,
Rauschen `10^(-3:-10)` mit Seeds 1001–1005. Alle haben nichtnegative
EMS-Schätzer und positive Reststreuung über der unveränderten Nullgrenze.
45 Fits bleiben erfolgreich und exakt gleich zum Ausgangscode;
34 Fälle enden benannt wegen Darstellbarkeit, 41 wegen nicht auflösbarer
Restskala. Kein zusätzlicher Konvergenzerfolg, keine ADEMP-/Coverage-Aussage.
Bei Rauschen `1e-4` und `1e-5` bleibt im E54-Plan die vom Reviewer
beschriebene Hessian-Warnung sichtbar; bei `1e-3` ist der Fit warnungsfrei.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual`: jeweils
Exit 0, keine ERRORs/WARNINGs, Vignetten neu gebaut. Echter Check-Output:

```text
Status: 1 NOTE
Package check elapsed seconds: 123.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2734 ]
```

Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
den CRAN-Report-Test, Originalanker ohne Repository und ellmer. Alle neuen
Tests laufen installiert. Der NOTE lautet `Unable to verify current time.`;
die Zeitprüfung blieb aktiv. Die mirai-Probe endet mit `16 | Permission
denied` (Exit 1). `sessionInfo()` meldet zusätzlich den gesperrten lokalen
Systembus/`timedatectl`; der numerische Diagnosetreiber endet mit Exit 0.
Diese Infrastrukturgrenzen sind mit tatsächlichen Logs OUT-OF-TERRITORY
dokumentiert. Kein neuer Mutationsscore wurde erzeugt.

`python3 /tmp/llmsa-m1a-r5/integrity.py` bestätigt mit Exit 0:
315 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
308 bytegleich, keine gelöscht; eine neue Testdatei. Alle 69 bestehenden
Test-/Fixture-Dateien bleiben bytegleich, ebenso Anker, Golden-Daten,
Specs, Gates, Mutationsbericht, Reviewer-Approvals und BACKLOG. Alle
110 öffentlichen Quelldateien stimmen mit der geprüften Paketkopie
überein. R/fit.R SHA-256:
`fff305a2c353c1f6bce60e549712913525e9c731087b0e6eac33fa1f6933be1c`.
Die Inventur ersetzt keine Territoriumsprüfung. Keine Git-Kommandos,
Abhängigkeitsinstallation oder eigenen API-Aufrufe. Territoriumsprüfung,
Phasen-Commit, Gates und Review verbleiben bei den zuständigen Rollen;
dieser Eintrag ist ein Builder-Prüfbeleg, kein Verdict.


## M1a — REWORK, Runde 4 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 3 verlangt REWORK wegen E50.
Die unveränderten Orchestrator-Fakten nennen acht grüne Gates, `result:
pass`, mutgate 93,72 bei required 91,79; kein Status error und kein
QA-PENDING. ARBITER fehlt, LESSONS enthält keine Lehren. Die aktuelle
Gate-Abnahme verbleibt beim Orchestrator und Reviewer.

**E50 ist im Produktcode behoben.** `R/fit.R:471` fängt Fehler des
lme4-Startfits im numerischen Vorgabepfad ab und meldet
`Numeric model initialization failed: ` mit der ursprünglichen
Engine-Meldung als Ursache. Die äußere Klasse ist `simpleError` ohne
internen Aufruf; die Warnungen des fehlgeschlagenen Starts werden weiterhin
in ihrer Reihenfolge weitergegeben. Positive Reststreuung wird nicht als
null umgedeutet. Daten, Nullgrenze, Präzisionsprüfung und Abschlusskriterium
bleiben gleich. Der explizite lme4-Durchreichweg behält seine Fehlerklassen,
Meldungen und Warnungen. ADR-020, Nachtrag Runde 4, NEWS.md und die
erzeugte Hilfe `man/msa_fit.Rd` dokumentieren die Änderung.

Die neue Datei `tests/testthat/test-fit-initialization.R` prüft die drei
realen E50-Reproduktionen mit positiver Restquadratsumme aus `stats::aov`,
die Engine-Ursache gegen einen direkten lme4-Aufruf, die Weitergabe zweier
synthetischer Startwarnungen, den expliziten Durchreichweg und positive
Gegenfälle gegen lme4 bei zwei absoluten Skalen. Vor der Codeänderung
scheitern vier der sechs Blöcke; danach bestehen alle 79 Erwartungen.
Die Testdatei wurde zwischen diesen beiden Läufen nicht verändert.

E51: `?msa_fit` nennt jetzt die Einschränkung bei hoher Wiederholpräzision;
die numerische Verbesserung und der zusätzliche Robustheitsnachweis
bleiben BL-87/nonblocking vor M1d. E52: ADR-020 dokumentiert den
Speicher-/Rechenaufwand der dichten Projektion und die größeren Messfälle
aus REVIEW Runde 3 mit ausdrücklicher Quellenangabe; keine Behauptung
einer Performanceverbesserung. E53: zwei Index-Äquivalenzen sind mit
ausgeführtem Beleg beantragt, weitere Darstellbarkeits- und Redundanzpunkte
bleiben BL-84/nonblocking. Sieben ältere R/fit.R-Claims wurden auf
identische Quellzeilen versetzt; R/grr.R bleibt unverändert. MUT-EQUIV.json
enthält zehn Anträge, keine Genehmigung. MUT-EQUIV-APPROVED.json bleibt
bytegleich. E48/BL-85 und E49/BL-86 sind OUT-OF-TERRITORY [INFRA].

Echter Output unter `/tmp/llmsa-m1a-r4/`; Befehle, einzelne Antworten und
vollständige Log-Bezüge in `orchestrator/handoff/M1a/REWORK-NOTES.md`:

```text
[ FAIL 9 | WARN 0 | SKIP 0 | PASS 70 ]
Initialization regression: 6 tests; 4 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 79 ]
Initialization regression: 6 tests; 0 failed blocks; 0 errors; 0 skipped
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2680 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 197 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 85.75; exit: 0
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.65; exit: 0
Count-vector enumeration: 9837 vectors, lengths 2..8, entries 1..3; both predicates identical
Balanced helper: 4 valid designs x 2 index mutations; outputs and warnings exactly identical
Equivalence evidence only; no mutation score or approval.
```

Die M1a-Abnahme enthält Originalanker, geschützte AIAG-Daten, NIST,
Paketorakel und geknittete Vignette. Der einzige Quellbaum-Skip ist der
bestehende ellmer-Negativtest. Keine neuen Skips oder geänderten Tests.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual` jeweils
Exit 0; keine ERRORs/WARNINGs, Vignetten neu gebaut. Echter Check-Output:

```text
Status: 1 NOTE
Package check elapsed seconds: 129.93; exit: 0
[ FAIL 0 | WARN 0 | SKIP 8 | PASS 2605 ]
```

Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
den CRAN-Report-Test, Originalanker ohne Repository und ellmer. Alle neuen
Tests werden ausgeführt. Der NOTE lautet `Unable to verify current time`;
die Zeitprüfung bleibt aktiv. Die lokale mirai-Probe endet mit
`16 | Permission denied` (Exit 1). Beides ist mit aktuellem Log-Beleg als
OUT-OF-TERRITORY [INFRA] dokumentiert. Kein vollständiger Mutationslauf
oder neuer Gate-Score wurde erzeugt.

`python3 /tmp/llmsa-m1a-r4/integrity.py` bestätigt mit Exit 0:
295 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
288 bytegleich, keine gelöscht; eine neue Testdatei. Alle 68 bestehenden
Test-/Fixture-Dateien sind bytegleich. Alle 109 öffentlichen Quelldateien
stimmen mit der geprüften Paketkopie überein. Gate-Fakten, Mutationsbericht
und Reviewer-Approvals sind unverändert. R/fit.R SHA-256:
`73caf9801081da31ef01ab26c3e026c44c34f4060804329b7f63e84e902ebd94`.
Die Inventur ersetzt keine Territoriumsprüfung.

Keine Git-Kommandos, Abhängigkeitsinstallation oder eigenen API-Aufrufe.
Orchestratorzustand, BACKLOG, Abnahmetests, QA-Tests, Fixtures, Anker,
Golden-Daten, Specs, Gates und Schwellen bleiben unverändert.
Territoriumsprüfung, Phasen-Commit, Gates und Review erfolgen durch die
zuständigen Rollen. Das ist ein Builder-Prüfbeleg, kein Verdict.


## M1a — REWORK, Runde 3 (30.10.2026)

Ausgangslage: REVIEW/verdict-code Runde 2 verlangt REWORK wegen E44.
`orchestrator/state/M1a/gates.json` nennt Runde 2 mit acht grünen Gates,
`result: pass`, mutgate 93,79; kein Status error, kein QA-PENDING.
ARBITER fehlt, LESSONS enthält keine Lehren. Diese historischen
Gate-Fakten bleiben unverändert; die aktuelle Abnahme folgt durch den
Orchestrator und Reviewer.

**E44 ist im Produktcode behoben.** Der allgemeine numerische Pfad
prüft vor dem lme4-Startfit die Restnorm der konditionierten Antwort
auf dem Spaltenraum des tatsächlichen Zufalls-Intercept-Designs.
Rangaufdeckende QR erlaubt unbalancierte Pläne, abhängige Spalten und
fehlende Zellen. Die vorhandene relative Restvarianzgrenze bleibt gleich.
Die Diagnose verlangt positive Restfreiheitsgrade der Projektion:
Ein gesättigter Spaltenraum lässt keinen Schluss auf die REML-Restvarianz
zu; der neue Gegenfall wird gegen lme4 und die geschlossene Randlösung geprüft.
Identische Replikate mit ausgelassener Wechselwirkung dürfen weiterhin
positive Modellrestvarianz haben. Der explizite lme4-Durchreichweg bleibt
unverändert. Umsetzung: R/fit.R; Begründung: ADR-020, Nachtrag Runde 3;
neue Regressionen: tests/testthat/test-fit-residual-design.R.

E45 und E46 sind über die vom Reviewer vorgeschlagene Dokumentationsoption
in R/fit.R und man/msa_fit.Rd behandelt: große gespeicherte lme4-Aufrufe
sowie die unmittelbare Aufruferumgebung datenbezogener Ausdrücke.
NEWS nennt die Diagnose vor dem Startfit. E47 ist teilweise behandelt:
dünn besetzte Pläne gegen lme4 und kleines positives Q gegen eine
unabhängige Rang-eins-Formel; vier benannte Überlebende werden lokal
erkannt. Die getrennten Darstellbarkeitsfälle bleiben BL-84/nonblocking.

E48/BL-85 und E49/BL-86 sind **OUT-OF-TERRITORY [INFRA]**, mit aktuellen
Log-Belegen und vollständiger Antwort auf alle IDs in
`orchestrator/handoff/M1a/REWORK-NOTES.md`. Die sieben verschobenen
Äquivalenz-Claims in R/fit.R wurden bei unverändertem Quelltext auf neue
Zeilen gesetzt und erneut beantragt; der achte in R/grr.R:94 bleibt gleich.
Die Reviewer-Approval-Datei wurde nicht geändert. E39/E41/E42 bleiben
beim Betreiber/Reviewer, E43 gemäß ADR-022 in M1b.

Echte Ausgaben aus `/tmp/llmsa-m1a-r3/`; vollständige Kommandos im Handoff:

```text
Baseline regression: 8 tests; 3 failed blocks; 0 errors; 0 skipped
Neue Tests: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 124 ]
Unit: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 2601 ]
E2E: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 23 ]
Fuzz: [ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
r-tests: pass — 191 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 78.44; exit: 0
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped
M1a acceptance elapsed seconds: 40.72; exit: 0
```

Die M1a-Abnahme besteht mit 722 Erwartungen einschließlich Originaldaten,
Orakeln und geknitteter Vignette. Bestehende Tests sind unverändert.
Der einzige Quellbaum-Skip ist der bekannte ellmer-Negativtest.
Die endgültigen neuen Tests wurden gegen die alte R/fit.R ausschließlich
in einer temporären Paketkopie geprüft; der Arbeitsbaum wurde nicht
zurückgesetzt. Die vier gezielten Mutationsversuche sind kein Gate-Lauf
und ergeben keinen neuen Mutationsscore.

Öffentlicher Paketbau und `R CMD check --as-cran --no-manual`: jeweils
Exit 0, keine ERRORs/WARNINGs, Vignetten gebaut, `Status: 1 NOTE`,
121,91 s; installierte Tests `FAIL 0 | WARN 0 | SKIP 8 | PASS 2526`.
Die acht bestehenden Standalone-Skips betreffen fünf Betreiber-Fixtures,
On CRAN, Originalanker ohne Repository und ellmer. Die neuen Tests
werden ausgeführt. Der einzige NOTE ist die weiterhin aktive
Zeitprüfung (`Unable to verify current time`). Der mirai-Probeaufruf
endet erneut mit `16 | Permission denied` (Exit 1). Keine Scheinreparatur
dieser Infrastruktur; Incoming-Remote entspricht dem Betreiber-Prüfskript.

Sechs positive Pläne haben exakt gleiche Varianzkomponenten und
Numerikdiagnosen wie der gesicherte Ausgangscode. Lokale Messung auf
ic50_demo, fünf alternierende Läufe nach Aufwärmen: Median vorher
0,489 s, nachher 0,564 s (Faktor 1,153); das zusätzliche Design mit
2152 × 297 Einträgen benötigt 4,88 MiB. Die geschlossene Lösung
benötigt diese zusätzliche Projektion nicht.

`python3 /tmp/llmsa-m1a-r3/integrity.py` bestätigt mit Exit 0:
289 Bestandsdateien inventarisiert, sieben zugewiesene Dateien geändert,
282 bytegleich, keine gelöscht; eine neue Unit-Datei. Alle 67 vorhandenen
Test-/Fixture-Dateien bleiben bytegleich. R/fit.R, die Rd-Datei und die
neue Testdatei gleichen der geprüften Paketkopie. Gate-Fakten und
Reviewer-Approvals bleiben bytegleich; keine eigene Approval, kein Verdict
und keine Git-Kommandos. Die Inventur ersetzt nicht die Territoriumsprüfung.

## M1a — REWORK, Runde 2 (29.–30.10.2026)

Grundlage: REVIEW/verdict-code und rote Gate-Logs aus Runde 1,
CRITERIA K-M1a-1 bis K-M1a-7 sowie ADR-022. ARBITER liegt nicht vor;
LESSONS enthält keine Lehren. Die vollständige Antwort auf **E18–E43**
mit Dateien, Kommandos und echtem Output steht in
`orchestrator/handoff/M1a/REWORK-NOTES.md`.

Produktkorrekturen: selbsttragende lme4-Aufrufe auch bei lokalem explizitem
`control`; Datenmaske für `subset`/`weights`/`offset` und tatsächliche
Modellzeilen in `data`, `n` und `input_rows`; relative Restvarianzdiagnose;
benannte Ablehnung von Originalskalen mit unzureichender Genauigkeit;
einheitliches numerisches NaN-/Gruppierungsverhalten; validierte
GRR-Schwellen und vollständige Ressourcenprovenienz. ADR-020 begründet
die Numerikergänzung. NEWS und die Hilfen dokumentieren die Fehler und den
Abbruch der Planung bei einem gescheiterten Fit.

Neue Unit-Tests unter `tests/testthat/` prüfen die Mutationsbefunde gegen
ANOVA/EMS, dichte REML-Formeln, lme4/ordinal, Differenzenquotienten,
ANK-16 und Quantile. Ausgabe-Charakterisierungen sind ausdrücklich markiert.
Die einzige rein mutationsbezogene Produktvereinfachung entfernt eine
wirkungslose Restvarianzrechnung nach Festlegung des Quotienten auf null
und das redundante `na.rm` nach Filterung auf endliche Bootstrapwerte.
Keine bestehenden Tests, Abnahmetests, QA-Tests, Gates, Schwellen, Anker
oder Specs wurden geändert. Keine eigenen Git-Kommandos.

Ausgeführte Belege unter `/tmp/llmsa-m1a-r2/`:

```text
QA vor Korrektur: r-tests: fail — 10 Tests; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
QA nach Korrektur: r-tests: pass — 10 Tests; 0 fehlgeschlagen, 0 Fehler, 0 übersprungen
Unit-/QA-Abschlusslauf: r-tests: pass — 183 Tests; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
M1a acceptance: 54 tests; 0 failed blocks; 0 errors; 0 skipped; 65.65 s
M2 evaluation: 10 tests; 0 failed blocks; 0 errors; 0 skipped; 424.42 s
Final rework regression: 33 tests; 0 failed blocks; 0 errors; 0 skipped; 14.12 s
```

M1a-Abnahme: `PASS 722`, M2-Auswertung: `PASS 374`, jeweils `FAIL 0`,
`WARN 0`, `SKIP 0`. Der Unit-Skip ist der bestehende ellmer-Negativtest.
Beide Paketchecks (öffentlich/mit Originalankern) liefen mit Exit 0,
ohne ERROR/WARNING und mit dem Infrastruktur-NOTE „Unable to verify
current time“. Die Prüfung wurde nicht deaktiviert. Die letzten zwei
Testergänzungen sind im separaten Abschlusslauf der 33 neuen Tests mit
`PASS 479`, `FAIL 0`, `WARN 0`, `SKIP 0` belegt.

Zusätzliche lokale Mutationsdiagnose (ausdrücklich kein Gate-Ersatz):
vollständige `muttest`-Generation über `R/fit.R`, `R/grr.R`, 14 unabhängige
R-Prozesse, zunächst eine benannte Teilmenge mit 41 Unit-Tests. Output:

```text
Finished diagnostic mutation run in 1245.6s; {'Killed': 823, 'Survived': 145, 'RuntimeError': 111, 'Timeout': 26}
```

Das sind 85,41 % nach der Statusformel ohne Äquivalenzabzug; allein Killed
bei im Nenner belassenen Timeouts ergibt 82,80 %. Dieser eingefrorene Stand
enthält noch die später entfernte überflüssige Restvarianzrechnung. Der
frische Plan zum Abschlusscode enthält 1097 Mutanten, deren Quellen mit
den alten Mutanten nach Entfernung genau dieser Zeile abgeglichen wurden.
Fünf Überlebende entfielen mit dieser Rechnung; die übrigen 140 wurden
gegen den finalen Stand mit 45 Tests/575 Erwartungen erneut ausgeführt:

```text
Finished diagnostic mutation run in 120.7s; {'Survived': 70, 'Killed': 61, 'RuntimeError': 9}
```

Keine Zusammenrechnung zu einem angeblichen Gate-Lauf. Acht einzeln
begründete Claims in `orchestrator/handoff/M1a/MUT-EQUIV.json` betreffen
zehn dieser verbleibenden Mutanten. Exakte Vergleichsrechnungen wurden
ausgeführt und in REWORK-NOTES protokolliert. Es gibt keine Approval-Datei.

Abschließende Integritätsprüfung: 255 Bestandsdateien verglichen, zehn
geplante Builder-Dateien geändert, 245 bytegleich, keine Bestandsdatei
gelöscht und kein vorhandener Test geändert. Neu: fünf Testdateien
einschließlich Helper und die beiden zugewiesenen Handoffs. NAMESPACE ist
bytegleich; alle 26 REVIEW-IDs sind beantwortet (`integrity-final.log`).

**Offene Betreiber-/Reviewer-Schritte:** Nur der Orchestrator schreibt die
Gate-Fakten. `gates.json` ist weiterhin der unveränderte rote Stand aus
Runde 1. Der lokale `mirai::daemons(1L)`-Probeaufruf endet mit
`16 | Permission denied` (`mirai-probe.log`); deshalb ersetzt die zusätzliche
Prozessdiagnose keinen regulären mutgate-Lauf. Die Infrastrukturpunkte
E40/E41 sowie lokale Dispatcher-/Zeitprüfungsprobleme sind in den
REWORK-NOTES ausdrücklich OUT-OF-TERRITORY. E39/E42 bleiben beim
Betreiber, E43 gemäß ADR-022 in M1b. Keine selbst genehmigte Äquivalenz.

## M2 — Abschlussnachtrag im M1a-BUILD (29.10.2026)

`orchestrator/state/M2/gates.json` nennt Runde 3, `result: pass` und
acht Gates mit `pass`; `orchestrator/handoff/M2/verdict-code.json`
bestätigt `PASS` ohne blocking-Einwand. Das sind gelesene Fakten des
Orchestrators/Reviewers, kein neuer Builder-Gate-Lauf.

## M1a — BUILD, Runde 1 (29.10.2026)

Grundlage: freigegebener PLAN samt PLAN-UPDATE und PLAN-REVIEW Runde 2,
CRITERIA K-M1a-1 bis K-M1a-7, unveränderte Abnahmetests einschließlich
Setup-Dateien, Rollen-/Implementierungsregeln, PROTOCOLS, Fachspezifikation
§2–§8, Statistikkern M1a und die numerischen S-boot-Szenarien,
Formelsammlung §1–§3 sowie ADR-016 bis ADR-019. ARBITER liegt nicht vor;
LESSONS enthält keine Lehren. ADR-019 bestätigt ADR-018 und regelt die
Mutationsinfrastruktur ausschließlich beim Betreiber.

### Numerischer Vorversuch vor der Ressourcenarbeit

Der Ausgangskern wurde ohne Git nach `/tmp/llmsa-m1a-build/baseline/`
kopiert. Die Inventur erfasst 198 Produkt-, Test-, Anker-, Vertrags-,
Dokumentations- und Handoff-Dateien. Schlüssel und Git-Metadaten wurden
nicht gelesen. Gesicherte SHA-256:

```text
R/fit.R 761faa4c4519cea2770f4c746fe002f72b91979bb625cb3a598f2af7655c93e1
R/grr.R 6c0d8b57e54f4a72a5667ad89f3b0119acd9ca020bb669a060e3ec2ed9224fed
```

Der unveränderte Ausgangslauf wurde mit `testthat::test_dir()` aus den
Quellen ausgeführt (`filter = "^m1a-"`, `set_max_fails(Inf)`,
`stop_on_failure = FALSE`, PDF-Gerät `pdf(NULL)`). Echter Output,
Exit 1, `/tmp/llmsa-m1a-build/baseline-acceptance.log`:

```text
[ FAIL 88 | WARN 5 | SKIP 0 | PASS 486 ]
M1a baseline: 54 tests; 21 failed blocks; 6 error blocks; 0 skipped; elapsed 22.56 s
```

Nach dem ersten Numerikentwurf lief derselbe Prüfweg mit
`filter = "^m1a-[12346]-"`. Echter Output, Exit 1:

```text
Duration: 18.5 s
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 465 ]
Numeric first: 40 tests; 0 failed blocks; 1 error blocks; 0 skipped
Error: acceptance: vignette missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/vignettes/validation.Rmd
```

Alle numerischen Abnahmefälle dieses Laufs bestehen. Der eine Fehler
ist die zu diesem Zeitpunkt bewusst noch nicht erzeugte Vignette in
`test-m1a-4-nist.R:94`; der Test wurde weder geändert noch übersprungen.

Anschließend ausgeführt (je Exit 0):

```bash
Rscript --vanilla /tmp/llmsa-m1a-build/go-no-go.R
Rscript --vanilla /tmp/llmsa-m1a-build/robustness.R
Rscript --vanilla /tmp/llmsa-m1a-build/derivatives.R
Rscript --vanilla /tmp/llmsa-m1a-build/timing.R
```

Tatsächlicher Output:

```text
Invariance: 250 transformed fits; max component/TV 1.91366e-09; max relative metric 2.63966e-09; distant discrete cases 250; failures 0
Methods: analytic_reml 30; closed_form 220
Model consistency: VarCorr, sigma, response, fitted, residuals and predictions passed for all original and transformed fits
Robustness: 200/200 fits completed; no errors
Dense reference: criterion error 1.06581e-14; score error 5.32907e-15; Hessian relative error 1.18928e-10
Serialization, refit control and same-seed bootMer: passed
ic50_demo: before median 0.389 [0.389, 0.389] s; after median 0.461 [0.460, 0.478] s; ratio 1.185
SmLs03: before median 0.043 [0.043, 0.050] s; after median 0.045 [0.045, 0.045] s; ratio 1.047
msa_plan: before median 0.216 [0.215, 0.230] s; after median 0.544 [0.543, 0.660] s; ratio 2.519
msa_boot: before median 0.103 [0.102, 0.108] s; after median 0.115 [0.113, 0.118] s; ratio 1.117
```

Aufbau, Seeds, Transformationen, Tabellen je Robustheitsszenario und
Laufzeitgrößen stehen vollständig in ADR-020. Die CSVs unter demselben
temporären Verzeichnis enthalten alle Einzelmessungen. Vier balancierte
Designs × Seeds 1–6 und ic50_demo tragen je zehn Transformationen.
Die S-boot-Szenarien 1–6 und die vier `msa_plan`-Beispielpläne tragen
je Seeds 1–20. Keine ADEMP-/Coverage-Behauptung. Der Bootstrap-Vergleich
verwendet acht Wiederholungen und Seed 37.

Zwei frühe Fehler betrafen ausschließlich das temporäre Diagnoseskript:
`refit()` ergänzt in lme4 das normale `print_level = 0` (daher Vergleich
mit direktem lme4 statt Annahme einer leeren Ergebnisliste); eine lokal
`eval` genannte Prüffunktion verdeckte `base::eval`. Beide Ursachen
wurden im Skript korrigiert. Die Modellsteuerung selbst ist leer und
der gespeicherte `lmerControl`-Ausdruck bleibt auswertbar. Der endgültige
Nachweis oben lief danach vollständig.

Der Vorversuch trägt die nächste Planstufe. ADR-020 begründet Numerik
und Matrix-Import; ADR-021 begründet die neuen Validierungsressourcen
einschließlich Golden-Pfad. Die endgültigen Prüfungen und die
Territoriumsübergabe werden unten ergänzt; Gates sind noch nicht
abgenommen.

### Umsetzung und Antworten auf die Planhinweise

`R/fit.R` enthält den gesamten neuen numerischen Pfad im bestehenden
Mutations-Scope: unveränderte Doubles, stabile Konditionierung, EMS-Lösung,
analytischer restringierter REML-Abschluss und endgültiger lme4-Modellbau
auf Originaldaten. `vc` wird ausschließlich aus `VarCorr(model)` gewonnen.
`numerics` ergänzt Methode, aktive Grenzen, Normen, Startdiagnostik und
Zuordnung der beim Parsen behaltenen Eingabezeilen. Fehler werden benannt;
ein gescheiterter Abschluss gibt keinen ungenauen Startfit zurück.

`R/grr.R` setzt die ndc-Untergrenze und den spezielleren Nullfall aus
ADR-017 um. Bei Gesamtvarianz null bleiben Varianzen/SD null, während
Prozentwerte, ICC und ndc `NA_real_` sind; das Verdikt ist `undetermined`.
Die Druckmethoden unterscheiden `NA` und `Inf`. Alle bisherigen
öffentlichen Argumentpositionen und Vorgaben bleiben erhalten.

| Planhinweis | Antwort und Beleg |
| --- | --- |
| E1, E3, E5–E7 | ADR-020; numerischer Vorversuch oben; unabhängige dichte Score-/Hessian-Rechnung, VarCorr-/sigma-/Antwort-/Vorhersageprüfungen, Serialisierung und Invarianz. Kleine positive Streuung und degenerierte Fälle werden getrennt behandelt. |
| E2 | Wurzel-README unverändert. Anleitung unter `inst/validation/numeric/README.md`. |
| E4 | Jeder Eintrag in `...` wählt den direkten lme4-Pfad. Unit-Vergleiche für Steuerung einschließlich `NULL`, Gewichte, Offset, Subset und Startwerte; unveränderter Nichtkonvergenz-Abnahmetest. |
| E8, E13 | Gewöhnliche nloptwrap-Refits; derselbe Seed gegen direktes `bootMer`; getrennte Zeitmessungen und 200 erfolgreiche S-boot-/Planungsfits vor Ressourcenarbeit. Degenerierte Planung und AP1-Fehlerpräfix zusätzlich geprüft. |
| E9 | Kleine Unit- und metamorphe Prüfungen; kein vollständiges Knitten und kein großes VCA-Orakel im Unit-Pfad. Der vollständige Testlauf steht unten. |
| E10 | ADR-021; ganze Ankerkopien, Quellenmanifest, zwei strikte Kontexte, Original-/Kopien-Driftwache, rekursive Prüfung der `source`-/`sys.source`-Abhängigkeiten einschließlich Inline-R, Daten-/Hash-/Schema-Negativfälle. |
| E11 | Nullfälle einschließlich Druckmethoden und `grr_stats()`-Verwendung durch den Bootstrap geprüft. Keine Abnahme vorweggenommen für die spätere Coverage-Studie. |
| E12 [INFRA], E16 | Numerik bleibt in `R/fit.R`/`R/grr.R`. Testauswahl, Mutation-Scope und Schwellen bleiben unverändert. Der Builder schreibt keine Mutationsfakten und führt keine Git-verwendenden Gates aus; Beurteilung/Score liegen beim Betreiber und Reviewer (ADR-019). |
| E14 | Positive Skala aus tatsächlichen Differenzen, keine MAD-Nullfalle. Zwei Gleichstandsmuster sowie sehr kleine/große Skalen geprüft; K-M2-6 erhält einen eigenen Regressionslauf. |
| E15 | Direkter Import `Matrix (>= 1.6-0)`, im numerischen ADR begründet; R >= 4.1 bleibt. Lokale Matrix-NEWS belegen die Einführung von `determinant(..., sqrt=)` in 1.6-0. Der zunächst angesetzte Mindeststand 1.3-0 wurde vor dem abschließenden Paketcheck korrigiert. Keine Paketinstallation oder Aktualisierung. |
| E17 | Startwarnungen mit Herkunft in `numerics$start`, bei Fehlschlag erneut als Warnung; finale Konvergenzprüfung aktiv. Roxygen-Dokumentation und gezielter Unit-Test belegen beide Fälle. |

Technische Festlegungen sind in ADR-020 und ADR-021 dokumentiert.
Es wurde keine neue Vertragslücke festgestellt. Spezifikationen,
Abnahmetests, ursprüngliche Anker und bestehende Testtoleranzen bleiben
unverändert. Die Hilfsrechnung der Vignette lädt den aktuellen Namespace
und nie eine unmutierte Paketkopie.

### Ressourcen, Herkunft und Dokumentation

Ausgeführt (Exit 0):

```bash
Rscript --vanilla data-raw/make_validation_numeric.R
Rscript --vanilla data-raw/make_validation_numeric.R --out /tmp/llmsa-m1a-build/reproduction-a
Rscript --vanilla data-raw/make_validation_numeric.R --out /tmp/llmsa-m1a-build/reproduction-b
Rscript --vanilla /tmp/llmsa-m1a-build/resource-negative-current.R
```

Der Erzeuger meldete jeweils:

```text
Numeric validation inputs: 11 NIST tables; 5 byte-identical anchors; 224678 stored data bytes
```

Eine anschließende unabhängige Python-Prüfung verglich alle Bytes mit
beiden Ausgaben und dem Checkout sowie die Zahlentokens/Zeilen mit den
gehashten Originalen. Echter Output (`reproduction-current.log`, Exit 0):

```text
Reproduction: 19 generated files byte-identical in both independent outputs and the repository
NIST tokens and row order: 11/11 original datasets reproduced exactly; 3 deterministic gzip headers
```

Die sechs Negativfälle verändern ausschließlich temporäre Kopien. Auch
der Fall einer bereits gestagten, aber zu großen Ausgabe veröffentlicht
nichts. Output aus `resource-negative-current.log`:

```text
Generator negative missing-anchor: rejected before publication; existing output unchanged
Generator negative missing-source: rejected before publication; existing output unchanged
Generator negative source-hash: rejected before publication; existing output unchanged
Generator negative malformed-source: rejected before publication; existing output unchanged
Generator negative missing-size-key: rejected before publication; existing output unchanged
Generator negative size-limit: rejected before publication; existing output unchanged
Generator negative cases: 6/6 passed; original inputs never edited
API snapshot ANK-02: 22 exports and 108 ordered arguments retained
```

`vignettes/validation.Rmd` rechnet K-M1a-1 bis K-M1a-5 mit
`inst/validation/numeric/reference_checks.R`. Die AIAG-Darstellung nimmt
nur aggregierte GRR-Tabellen an. Die gepoolte Interaktion wird ausdrücklich
als nicht separat geschätzt berichtet, nicht mit einem erfundenen Fitwert.
Im öffentlichen Kontext sind sämtliche AIAG-Beobachtungsfelder
`not rerun: protected data required`. Keine geschützten Rohdaten werden
in irgendeinem Kontext ausgegeben.

Die Roxygen-Erzeugung lief ausschließlich in
`/tmp/llmsa-m1a-build/roxygen-current-h_c1v8g9/` mit
`roxygen2::roxygenise(..., roclets = c("rd", "namespace"))` (Exit 0).
Nur `msa_fit.Rd`, `msa_grr.Rd` und `msa_boot.Rd` wurden übernommen.
`NAMESPACE` blieb byte-identisch. Die zusätzliche automatisch erzeugte
Autorenformatierung in `llmsa-package.Rd` wurde nicht übernommen.
`NEWS.md` beschreibt Numerik, Nullfälle und Validierung.

### Ausgeführte Regressionen

Eingefrorene Umgebung, rein prüfender Aufruf:

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
```

Output des endgültigen Laufs (`deps-complete-current.log`, Exit 0):

```text
r-deps: R              4.6.1        (verlangt: >= 4.1)
r-deps: lme4           2.0.6        (verlangt: beliebig)
r-deps: Matrix         1.7.4        (verlangt: >= 1.6-0)
r-deps: ordinal        2026.7.26    (verlangt: beliebig)
r-deps: SixSigma       0.11.1       (verlangt: beliebig)
r-deps: VCA            1.5.2        (verlangt: beliebig)
r-deps: pass — 22 Anforderungen erfüllt (R 4.6.1)
```

Der vollständige M1a-Abnahmelauf wurde aus den Quellen mit
`Sys.setenv(REPO_ROOT = normalizePath("."))`, `pdf(NULL)`,
`pkgload::load_all(".", quiet = TRUE)`, `testthat::set_max_fails(Inf)`
und `testthat::test_dir("tests/acceptance", filter = "^m1a-",
reporter = "progress", stop_on_failure = FALSE,
stop_on_warning = FALSE)` ausgeführt. Der Prozess beendete sich anhand
der tatsächlich fehlgeschlagenen/fehlerhaften Testblöcke; Abnahmeinhalte
wurden nicht verändert. Echter Output des endgültigen Laufs
(`acceptance-complete-current.log`, Exit 0):

```text
Duration: 38.7 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
M1a final: 54 tests; 0 failed blocks; 0 error blocks; 0 skipped; elapsed 38.88 s
```

Vorherige Diagnoseausgänge bleiben sichtbar: Der erste Vignettenlauf
ohne gesetztes `REPO_ROOT` endete mit sechs Setup-Fehlern (573 erfolgreiche
Prüfungen), weil der Abnahmehelfer nach dem Wechsel ins temporäre
Verzeichnis die Repo-Wurzel nicht mehr fand. Der Aufruf wurde dem
Harness-Kontext angepasst; die Abnahmedatei blieb unverändert. Ein erster
neuer Darstellungstest meldete vier fehlende INT-Zeilen. Daraufhin wurde
die Darstellung um die explizit gepoolte Interaktion ergänzt; keine
Erwartung wurde entfernt. Danach bestand die Teilmenge
`fit-numeric|grr-numeric|validation-numeric|acmg-evaluate` mit
`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 382 ]` (29 Blöcke, 8,3 s).
Eine zusätzliche Inline-Quellverfolgungsprüfung ist im folgenden
Gesamtlauf enthalten.

Gesamtregression mit dem unveränderten Betreiber-Testtreiber und offenem
Null-PDF-Gerät (Dateiausgaben außerhalb des Checkouts):

```bash
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath(".")); grDevices::pdf(NULL); started <- proc.time()[["elapsed"]]; source("orchestrator/lib/r-tests.R"); cat(sprintf("Unit and QA elapsed: %.2f s\n", proc.time()[["elapsed"]] - started))' tests/testthat tests/e2e tests/fuzz
```

Echter Output (`unit-qa-current.log`, Exit 0):

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1998 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 145 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed: 70.60 s
```

Der eine bestehende Skip betrifft `test-backends.R:32`:
`requireNamespace("ellmer", quietly = TRUE) is TRUE` (Negativfall für
eine fehlende optionale Abhängigkeit). Die neuen Drift-/Numerikprüfungen
wurden im Repository nicht übersprungen. Bestehende QA-Dateien blieben
unverändert. Die System-Bus-Diagnose aus `acmg-policies` ist stderr des
vorhandenen Prüfwegs; testthat meldet null Warnungen und keinen Fehler.

Die schwierigen NIST-Fälle bleiben ausdrücklich Berichte, wie ADR-017
und K-M1a-4 verlangen. Gemessene LRE aus dem unveränderten Abnahmetest:

```text
K-M1a-4 report SmLs07: LRE msa_fit residual 3.81, item 3.71; LRE aov residual 4.16, item 4.02
K-M1a-4 report SmLs08: LRE msa_fit residual -0.60, item -0.60; LRE aov residual 2.67, item 3.92
K-M1a-4 report SmLs09: LRE msa_fit residual -4.19, item -4.19; LRE aov residual -0.28, item 3.94
```

Die Originalskala des lme4-Modells begrenzt hier die Genauigkeit trotz
präziser Varianzverhältnisse. Es gibt keine nachträgliche Korrektur nur
der `vc`-Tabelle und keine Datenreparatur. Alle vorgeschriebenen niedrigen
und mittleren Schwierigkeitsfälle bestehen.

K-M2-6 wurde mit demselben direkten Abnahmeaufruf und
`filter = "^m2-6-"` ausgeführt (`acceptance-m2-current.log`, Exit 0):

```text
Duration: 234.7 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 374 ]
M2 evaluation regression: 10 tests; 0 failed blocks; 0 error blocks; 0 skipped; elapsed 234.76 s
```

### Paketbau und Check in beiden Kontexten

Zwei Positivlisten-Kopien enthalten nur `DESCRIPTION`, `NAMESPACE`,
Lizenzen, `NEWS.md`, `README.md`, `.Rbuildignore`, `R/`, `man/`, `data/`,
`inst/`, `vignettes/`, `tests/testthat.R` und `tests/testthat/`.
Originalanker, geschützte Daten, API-Aufzeichnungen, Harness,
Git-Metadaten und Geheimnisse wurden nicht kopiert.

Öffentliches Arbeitsverzeichnis:
`/tmp/llmsa-m1a-build/public-check-current-1_8k9lha/`.
Vollmodus-Arbeitsverzeichnis:
`/tmp/llmsa-m1a-build/full-check-current-lsm9_tb3/`.
Jeweils ausgeführt, alle vier Prozesse Exit 0:

```bash
env -u REPO_ROOT R CMD build --no-manual src
env -u REPO_ROOT _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz

REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa R CMD build --no-manual src
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa _R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die finalen Builds mit dem korrigierten Matrix-Minimum stehen jeweils in
`build-complete.log`, die Checks in `check.log` und `llmsa.Rcheck/`.
Echter gemeinsamer Build-Output:

```text
* creating vignettes ... OK
* building ‘llmsa_0.1.0.tar.gz’
```

Check-Auszüge, zuerst öffentlich:

```text
* checking examples with --run-donttest ... [31s/31s] OK
* checking tests ...
  Running ‘testthat.R’ [49s/49s]
 [49s/49s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [27s/27s] OK
* DONE
Status: 1 NOTE
```

Vollmodus:

```text
* checking examples with --run-donttest ... [31s/31s] OK
* checking tests ...
  Running ‘testthat.R’ [48s/48s]
 [48s/48s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [28s/29s] OK
* DONE
Status: 1 NOTE
```

Beide Checks haben **keinen ERROR und keine WARNING**. Die einzige NOTE
lautet `Unable to verify current time` bei `checking for future file
timestamps`. Die Uhrzeitprüfung wurde nicht deaktiviert. Nur die bereits
im Betreiberprüfweg vorgesehene CRAN-Incoming-Netzeinstellung ist gesetzt.

Die installierten Tests melden öffentlich
`[ FAIL 0 | WARN 0 | SKIP 8 | PASS 1923 ]`, im Vollmodus
`[ FAIL 0 | WARN 0 | SKIP 7 | PASS 1924 ]`.
Fünf bestehende Skips betreffen nicht ausgelieferte API-Aufzeichnungen,
einer den bisherigen CRAN-Report-Test, einer die installierte optionale
ellmer-Abhängigkeit. Nur öffentlich kommt der nach ADR-017 erlaubte
Originalanker-Vergleich hinzu. Kopien, Schema, Hashes, numerische
Unit-Tests und Literalherkunft laufen in beiden Paketen; im Vollmodus
läuft auch die Original-Driftwache.

Die tatsächlich erzeugten HTML-Dateien wurden ohne erneute Rechnung aus
den Tarballs gelesen und ihre Tabellen geprüft. Output
(`rendered-vignettes-current.log`, Exit 0):

```text
public: 9 computed reference tables; results {'PASS': 94, 'NOT RERUN': 23, 'REPORT': 8, 'REPORT (higher difficulty)': 6}; 23 AIAG rows; no raw-data columns or protected input files
full: 13 computed reference tables; results {'PASS': 123, 'REPORT (pooled interaction)': 4, 'REPORT': 12, 'REPORT (higher difficulty)': 6}; 23 AIAG rows; no raw-data columns or protected input files
```

Alle erwarteten, beobachteten und Toleranzwerte wurden beim Knitten
berechnet beziehungsweise aus den autorisierten Eingaben gelesen.
Die HTML-Prüfung fand weder FAIL- noch WARNING-Ergebniszeilen. Die
Tarballs enthalten kein geschütztes Eingabeblatt; die HTML-Tabellen
enthalten keine Rohdaten-Spalten.

### Übergabe und verbleibende Grenzen

Die Builder-Umsetzung und die oben genannten Prüfungen sind abgeschlossen.
Abnahme, kumulative Gates, Mutation-Score einschließlich E16,
Territoriumsprüfung und Phasen-Commit bleiben beim Orchestrator/Reviewer.
E12 bleibt ein nonblocking Infrastrukturhinweis in dessen Zuständigkeit;
der Builder hat weder BACKLOG noch Gate-/Zustandsdateien geändert.
Ein Windows-, macOS- oder R-4.1-Lauf wird nicht behauptet. Gemessen wurde
die eingefrorene Linux-Umgebung mit R 4.6.1 und Matrix 1.7.4.

Keine Git-Kommandos, keine Änderung der Abnahme- oder Gate-Regeln,
keine Installation/Aktualisierung von Abhängigkeiten. Temporäre
Paketinstallationen durch R CMD build/check liegen unter `/tmp/`.
Sämtliche Bauartefakte und Diagnoseprotokolle liegen außerhalb des
Arbeitsbaums. Abschließend ausgeführte Python-/SHA-256-Inventur
(`integrity-current.log`, Exit 0):

```text
Integrity: 198 inventoried files; 9 authorized existing-file changes; 29 authorized new files; 0 removed files
Protected inventoried files: 95/95 byte-identical
Existing AP1 evaluation tests: retained byte-for-byte with one added test block
public checked package source: 103 files byte-identical to the final corresponding repository files
full checked package source: 103 files byte-identical to the final corresponding repository files
Workspace artifacts: none; vignettes contains only the two Rmd sources
```

Die vollständige Pfadliste liegt in
`/tmp/llmsa-m1a-build/integrity-current.json`. Die neun Änderungen
bestehender Dateien betreffen `R/fit.R`, `R/grr.R`, die drei genannten
Rd-Dateien, den zusätzlichen AP1-Unit-Test, `DESCRIPTION`, `NEWS.md` und
dieses Fortschrittsdokument. Die neuen Dateien liegen ausschließlich in
den im Plan genannten Builder-Pfaden. Diese Inventur ersetzt nicht die
Territoriumsprüfung des Orchestrators.

## M0 — BUILD, Runde 1 (25.10.2026)

Der freigegebene Plan ist im Builder-Territorium umgesetzt: Diese Phase
aktualisiert ausschließlich `PROGRESS.md` und dokumentiert die unten
ausgeführten, rein lesenden Diagnosen. **Die Gate-Abnahme steht aus.**
Beim Diagnosezeitpunkt existiert
`orchestrator/state/M0/gates.json` noch nicht.

### Umfang und verbindlicher Kontext

Grundlage sind `orchestrator/handoff/M0/PLAN.md`,
`PLAN-REVIEW.md` und `verdict-plan.json` (Runde 1, `PASS`, keine
blocking-Einwände). PLAN-UPDATE und ARBITER liegen für M0 nicht vor.
Gelesen wurden außerdem `AGENTS.md`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`,
`CRITERIA.json`, sämtliche M0-Abnahmetests einschließlich Setup-Dateien,
`docs/01-fachspezifikation.md` mit K-M0-1 bis K-M0-7,
die Reviewer-ADRs ADR-001 bis ADR-003, der bisher leere `PROGRESS.md`,
`BACKLOG.md` und `orchestrator/LESSONS.md` (noch keine Lehren).

Die Begrenzung folgt der Fachspezifikation §10: „M0 ändert `R/` nicht.
Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“
Daher bleiben Produktcode, Schnittstellen, Abhängigkeiten und sämtliche
Tests unverändert; zusätzliche Unit-/Property-Tests sind in diesem
freigegebenen M0-Plan ausdrücklich nicht vorgesehen. Es gibt keine
Planabweichung und keinen neuen Builder-ADR.

Für die Diagnosen wurde die vorhandene Umgebung nach `toolchain.json`
und dem unveränderten Manifest `DESCRIPTION` verwendet. Es erfolgten keine
Installation, kein Update und kein Netzzugriff. Abnahmetests, Verifier und
Gates wurden nicht gestartet; auch indirekte Git-Aufrufe durch diese
Prüfwege wurden vermieden. Keine Git-Kommandos, keine Builds oder
Testläufe im Checkout, keine Bauartefakte und keine Schreibzugriffe auf
fremde Territorien.

### Behandlung der Reviewer-Hinweise

| ID | Antwort und Stand |
| --- | --- |
| E1 | Akzeptiert: `PROGRESS.md` wird in BUILD fortgeschrieben, einschließlich aktueller ANK-01-Diagnose mit echtem Output. Die noch fehlenden Gate-Fakten werden ausdrücklich als offen geführt. |
| E2 | Akzeptiert: ausschließlich lesende Diagnosen; kein Build, Check oder Testlauf im Checkout. Damit entstehen dort keine Tarballs, `*.Rcheck`, `_snaps` oder `Rplots.pdf` durch diese Phase. |
| E3 / PLAN-M0-INFRA-01 | Übernommen als nonblocking `[INFRA]`; ref: Fachspezifikation §9, BL-48. `gates-auswahl.md` fehlt weiterhin an der Repo-Wurzel. Die Zuordnung ist in PLAN-REVIEW bestätigt. Betreiber: Datei bereitstellen oder Verweis berichtigen; Reviewer: BL-48 in CODE-REVIEW nachtragen. Kein Builder-Eingriff in BACKLOG oder Gate-Auswahl. |
| E4 | Berücksichtigt; ref: Fachspezifikation §4, K-M0-7. M0 ergänzt keine Argumente. Ab M2 prüft der Reviewer zusätzlich, ob angehängte Argumente ohne ADR einen Vorgabewert haben. |

ACC-1 bis ACC-3 sind durch die angenommenen Reviewer-ADRs entschieden:
ADR-001 legt den Prüfgegenstand von K-M0-4 nach M0 fest,
ADR-002 die wirksame Ignore-Prüfung samt Exit-Codes,
ADR-003 die Zählung der testthat-Blöcke einschließlich bestehender Skips.
Die noch als „ADR ausstehend“ formulierten Einträge in CRITERIA.json
werden hier nicht geändert; maßgeblich sind die Planfreigabe und die
vorliegenden ADRs. Es wurde keine neue Vertragslücke festgestellt.

### Ausgeführte Diagnosen

Alle folgenden Befehle liefen in dieser BUILD-Phase aus der Repo-Wurzel.
Die Ausgaben sind die tatsächlichen Outputs dieses Laufs, keine
Übernahme historischer PLAN- oder Reviewer-Ergebnisse.

**1. Dateiintegrität, statische Exportliste und Layout (Exit 0).**

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import json
import os
import re

root = Path.cwd()
expected = json.loads((root / 'reference/anchors/ANK-01.json').read_text())['value']
actual = {p.relative_to(root).as_posix(): p for p in (root / 'R').rglob('*') if p.is_file()}
assert set(actual) == set(expected), 'R/ file set differs from ANK-01'
for name, path in sorted(actual.items()):
    data = path.read_bytes()
    assert len(data) == expected[name]['bytes'], name
    assert hashlib.sha256(data).hexdigest() == expected[name]['sha256'], name
print(f'ANK-01: {len(actual)}/{len(expected)} files match path, bytes and SHA-256')
snapshot = json.loads((root / 'reference/anchors/ANK-02.json').read_text())['value']
exports = re.findall(r'^export\(([^)]+)\)$', (root / 'NAMESPACE').read_text(), re.M)
assert set(exports) == set(snapshot['exports']), 'NAMESPACE exports differ from ANK-02'
print(f'ANK-02: {len(exports)} NAMESPACE exports match; formals not evaluated')
required = ['^pkgdown-site$', '^docs$', '^reference$', '^orchestrator$', '^tests/acceptance$', '^tests/simulation$', '^tests/fixtures$']
assert set(required) <= set((root / '.Rbuildignore').read_text().splitlines())
assert re.search(r'^destination: pkgdown-site\s*$', (root / '_pkgdown.yml').read_text(), re.M)
print('Layout: 7/7 required .Rbuildignore lines and pkgdown destination present; Git ignore semantics not executed')
gates = sorted(p.name for p in (root / 'orchestrator/gates.d').glob('[0-9][0-9]-*.sh') if os.access(p, os.X_OK))
print('Executable gate files: ' + ', '.join(gates))
print('M0 gates.json exists: ' + str((root / 'orchestrator/state/M0/gates.json').exists()))
print('gates-auswahl.md exists at repository root: ' + str((root / 'gates-auswahl.md').exists()))
PY
```

Output:

```text
ANK-01: 13/13 files match path, bytes and SHA-256
ANK-02: 22 NAMESPACE exports match; formals not evaluated
Layout: 7/7 required .Rbuildignore lines and pkgdown destination present; Git ignore semantics not executed
Executable gate files: 10-deps.sh, 20-lint.sh, 30-tests.sh, 70-trace.sh, 82-territory.sh, 86-mutgate.sh, 87-golden-adr.sh, 88-mutfull.sh
M0 gates.json exists: False
gates-auswahl.md exists at repository root: False
```

Damit sind die Pfadmenge, Bytezahlen und SHA-256-Werte aller R-Dateien
aktuell gegen ANK-01 geprüft. Der NAMESPACE-Vergleich ist eine
Bestandsdiagnose der Exportliste; er prüft weder `formals()` noch die
Negativfälle des API-Abnahmetests. Die Layoutdiagnose prüft die
geforderten Dateiinhalte, nicht die wirksamen Git-Ignore-Regeln.
Ausführbare Gate-Dateien belegen keinen Gate-Erfolg.

**2. Vorhandene Abhängigkeiten, ohne Installation (Exit 0).**

```bash
Rscript orchestrator/lib/r-deps.R --check-only
```

Output:

```text
r-deps: R              4.6.1        (verlangt: >= 4.1)
r-deps: graphics       4.6.1        (verlangt: beliebig)
r-deps: lme4           2.0.6        (verlangt: beliebig)
r-deps: ordinal        2026.7.26    (verlangt: beliebig)
r-deps: stats          4.6.1        (verlangt: beliebig)
r-deps: tools          4.6.1        (verlangt: beliebig)
r-deps: utils          4.6.1        (verlangt: beliebig)
r-deps: DBI            1.3.0        (verlangt: beliebig)
r-deps: ellmer         0.5.0        (verlangt: beliebig)
r-deps: httr2          1.3.0        (verlangt: beliebig)
r-deps: jsonlite       2.0.0        (verlangt: beliebig)
r-deps: knitr          1.52         (verlangt: beliebig)
r-deps: rmarkdown      2.32         (verlangt: beliebig)
r-deps: RSQLite        3.53.3       (verlangt: beliebig)
r-deps: testthat       3.3.2        (verlangt: >= 3.0.0)
r-deps: pass — 15 Anforderungen erfüllt (R 4.6.1)
```

Alle Anforderungen aus DESCRIPTION sind in der Builder-Umgebung
erfüllt. Dies ist der ausdrücklich lesende `--check-only`-Lauf,
kein deps-Gate-Beleg; das Gate muss seine eigene Umgebung und
Versionen in `gate-deps.log` dokumentieren.

**3. R-Laufzeit (Exit 0).**

```bash
Rscript --version
```

Output:

```text
Rscript (R) version 4.6.1 (2026-06-24)
```

### Offene Abnahme und Übergabe

| Kriterium | Aktueller Builder-Beleg | Noch erforderlicher Nachweis |
| --- | --- | --- |
| K-M0-1 | Lesende Abhängigkeitsdiagnose: 15 Anforderungen erfüllt; Versionen oben. | deps-Gate `pass` und Versionen in `gate-deps.log`. |
| K-M0-2 | ANK-03 und ADR-003 gelesen; kein aktueller Testlauf durch den Builder. | tests-Gate ohne Fehlschlag/Fehler; mindestens `ANK-03.value` testthat-Blöcke (derzeit 27); Testzahl und Skips aus dem echten Lauf berichten. |
| K-M0-3 | Kein Build-/Check-Lauf in dieser BUILD-Phase. | lint-Gate: Paketbau und `R CMD check --as-cran --no-manual` außerhalb des Repos ohne ERROR/WARNING. |
| K-M0-4 | 13/13 R-Dateien stimmen in Pfad, Bytezahl und SHA-256 mit ANK-01 überein. | Unveränderter Abnahmetest im tests-Gate. |
| K-M0-5 | Sieben geforderte `.Rbuildignore`-Zeilen und pkgdown-Ziel vorhanden. | Vollständiger Layout-Abnahmetest einschließlich tatsächlicher Git-Ignore-Semantik nach ADR-002. |
| K-M0-6 | Acht ausführbare Gate-Dateien vorhanden; `gates.json` fehlt noch. | Aktuelles Aggregat mit `pass` für deps, lint, tests, trace, territory, mutgate, golden-adr; mutgate-Kurzbefund `mutgate: pass (kein geänderter Mutations-Scope)`. `88-mutfull` ist in M0 nicht fällig. |
| K-M0-7 | Die 22 NAMESPACE-Exporte gleichen der Liste aus ANK-02; keine Snapshot-Änderung. | Geladenes Paket als API-Obermenge einschließlich Positionen/Vorgabewerten, positive und negative Prüffälle sowie golden-adr-Prüfung im Harness. |

Der Orchestrator prüft das Territorium, erzeugt den Phasen-Commit und
führt danach die konfigurierten Gates aus. Der Reviewer beurteilt den
Diff seit `plan/M0` und die aktuellen Gate-Fakten. Für Runde 1 verlangt
PLAN-REVIEW ein `gates.json` mit passendem `round`, `base`, `env.sha`
und `result: pass`; solche Fakten liegen dieser BUILD-Phase noch nicht
vor. Es wird kein Kriterium allein aufgrund der Vorprüfung als
abgenommen und kein Gate als bestanden erklärt.

Die Backlog-Zuordnung aus dem freigegebenen PLAN bleibt bestehen.
E3/BL-48 bleibt bei Betreiber und Reviewer; ein neuer blocking-Befund
wurde nicht festgestellt. Nach M0 wertet der Betreiber Modellumleitung,
Kosten und Gate-Laufzeiten aus (BL-06, BL-11, BL-13, BL-37). Der nächste
Meilenstein ist M2; AP1-Zahlen vor der erneuten Auswertung nach
M1-Abnahme bleiben vorläufig (BL-52).

## M0 — Abschlussnachtrag im M2-BUILD (27.10.2026, BL-54)

Der oben dokumentierte M0-BUILD-Stand ist historisch. Die anschließend
erzeugten Fakten liegen inzwischen vor und wurden in dieser Phase
gelesen: `orchestrator/state/M0/gates.json` nennt Runde 1,
`baseRef: plan/M0`, Basis `6783f2874340f62c4de53d30b5415708e1a45073`,
Umgebungs-SHA `9866ba2f5fcef6538338a1612f4e849cb77355e9` und
`result: pass`. deps, lint, tests, trace, territory, mutgate und
golden-adr stehen auf `pass`; mutfull ist „nicht fällig in M0“.
`orchestrator/handoff/M0/REVIEW.md` und `verdict-code.json` bestätigen
`PASS` ohne blocking-Einwand. Dies ist der verlangte Abschlussvermerk,
kein neuer M0-Gate-Lauf. Der Git-verwendende `done/M0`-Zweig bleibt dem
Test-Gate des Orchestrators vorbehalten (BL-53).

## M2 — BUILD, Runde 1 (27.10.2026)

Der freigegebene PLAN einschließlich PLAN-UPDATE ist implementiert;
ADR-009 dokumentiert die zusätzlich erforderliche Korrektur der
numerischen JSON-Metadaten, deren Prüfung durch den Reviewer aussteht.
Maßgeblich sind die Planfreigabe Runde 2 (`PASS`, keine blocking-Einwände),
CRITERIA ACC-1 bis ACC-25, K-M2-1 bis K-M2-7 sowie ADR-004 mit beiden
Nachträgen und ADR-005 bis ADR-007. Eine ARBITER-Datei liegt nicht vor.
Rollenregeln, Protokolle, Spezifikationen, Abnahmetests und Handoffs
wurden gelesen; `orchestrator/LESSONS.md` enthält keine zusätzliche Lehre.
Die noch als ausstehend beschriebenen Auslegungen in CRITERIA werden
durch die angenommenen ADRs konkretisiert, ohne CRITERIA zu verändern.

### Umsetzung und Umfang

- `R/acmg.R` enthält die vier internen Einstiegspunkte sowie die
  AP1-Helfer für Konfiguration, Import, Design, API-/Mock-Betrieb,
  Pilot, Store-Herkunft, Auswertung und Berichte. `run.R` unter
  `inst/validation/ap1/` lädt den richtigen Quellbaum und delegiert
  an denselben in den Unit-Tests geprüften Treiber.
- `data-raw/make_items_ap1.R` erzeugt den eingefrorenen Satz aus den
  vorhandenen Quellen nach ADR-005. Alle Quellhashes, Schemata,
  Poolzahlen und Größenlimits werden vor dem Schreiben geprüft.
  Hauptsatz, Pilot, Herkunft und Hashliste liegen unter
  `inst/extdata/items_ap1_2026-10-24/`. ADR-008 begründet diese erste
  Golden-Erzeugung; Auswahl und Referenzregeln weichen nicht vom PLAN ab.
- `plan.yaml` enthält die Zahlen aus den geernteten Ankern, die
  unveränderten Vorlagen und F8-Bausteine, Pilotregeln, Schwellen,
  Metadaten, Policy-Belege und Grenzen der Interpretation. Die drei
  Prüf-Toleranzen für paketinterne Unit-Tests stammen ebenfalls aus
  ANK-TOL und sind mit Herkunft im ausgelieferten Plan hinterlegt.
- `parse_choice()` ergänzt `whole_word = FALSE`, `msa_run()` ergänzt
  `parse_by_prompt = NULL`, `msa_report()` ergänzt `assessment = NULL`,
  jeweils am Ende. Die bisherigen Vorgaben bleiben erhalten. Das
  HTTP-Backend lässt Temperatur bei NULL weg, berücksichtigt `row$system`
  und hält Anfrage- und Antwortmetadaten auseinander. Es speichert
  weder Schlüssel noch Header. Die zusätzlichen Request-Metadaten
  Seed, Temperatur und Reasoning-Effort dienen der Nachvollziehbarkeit.
  ADR-009 korrigiert die bisherige Rundung kleiner und gebrochener
  Metadatenwerte bei der JSON-Speicherung; auch verschachtelte `usage`
  bleibt im SQLite-Rundlauf numerisch identisch.
- Auswertung und Berichte erhalten NA-Modalwerte, Gleichstände,
  Referenzbasis, Vollständigkeit, Rückfallgründe und alle Fit-Warnungen.
  Der numerische Rückfall nutzt die Paketvorgaben mit Interaktionen.
  Der gemeinsame Fit erhält kein Verdikt. Ein fehlendes Kriterium oder
  unvollständiger Hauptplan verhindert ein Gesamtband. Die Kennzeichnung
  `synthetic`/`unverified` bleibt zusätzlich zu den Kriterienbändern.
- README, NEWS und fünf von roxygen2 erzeugte Rd-Dateien beschreiben
  die Schnittstellen und den Betreiberablauf. Neue Suggests sind
  ausschließlich `digest`, `pkgload` und `yaml`. Imports und die
  22 Exporte bleiben unverändert; es gibt keine Installation und
  keine Änderung der eingefrorenen Abhängigkeiten.

### Antworten auf die Planhinweise

| ID | Antwort und Umsetzung |
| --- | --- |
| E1 | Akzeptiert: Ein API-Konstruktor für CLI und Tests; exakter HTTPS-Host bestimmt den Schlüssel, Routing bleibt Array, kein `max_tokens` aus Kostenannahmen und kein Qwen-Reasoning-Override. Fehler vor Requests. |
| E2 | Akzeptiert: alle vier Pilotregeln einschließlich globaler strikter Kostensumme, vollständiger Schlüssel, technischer Parserquote und Wiederholungstagsdiagnostik. API-main und API-robustness sind bis zum bestandenen API-Pilot gesperrt. |
| E3 | Akzeptiert: expliziter Modus, persistente `ap1_metadata`, Prüfung vor Resume/Schreiben, keine Mischung; auch reine Fehlerstores und reine Auswertung sind geprüft. |
| E4 | Akzeptiert: Fehler und vereinbarte Konvergenzwarnungen lösen den Rückfall aus; Standardinteraktionen bleiben erhalten, Fehler des numerischen Fits enden benannt. |
| E5 | Akzeptiert: an Fits gehen die übergebenen Zeilen in unveränderter Reihenfolge und mit ihren Typen. Direkter Vergleich und separate Permutation sind geprüft. |
| E6 | Akzeptiert: Referenzen und Prior-Felder stammen ausschließlich aus `runs`; der CLI-Join erhält die Reihenfolge. Eingeladene INSAID-Referenzen werden nicht überschrieben. |
| E7 | Akzeptiert: vollständige Haupt-/PB-Zählungen einschließlich Fehlern; fehlende, zusätzliche oder doppelte Designzellen verhindern vollständige Bewertung. Nicht definiertes Kappa/%GRR bleibt `not assessed`. |
| E8 | Akzeptiert: API-Robustheit verlangt den verifizierten INSAID-Eingang vor Aufrufen. Produktivhash aus QUELLE; synthetische TSVs nur als explizite Unit-Eingaben unter temporären Pfaden. |
| E9 | Akzeptiert: ASCII in R/, Paketressourcen statt Repo-Quellen in Unit-Tests, Suggests werden geprüft. Deutsche F8-Stufe ausschließlich in YAML. |
| E10 | Akzeptiert: ADR-008 für den ersten Golden-Satz; byte-identische Reproduktion aller vier Dateien unter beiden verfügbaren Kollationen. |
| E11 | Akzeptiert: Policy-Texte mit Fundstelle aus den lokalen Schnappschüssen. Der fehlende konkrete Anbieterbeleg wird offengelegt, siehe M2-BUILD-INFRA-02. |
| E12 | Akzeptiert: Stores, Berichte, Pakettarball, Check-Verzeichnis und Diagnose-Logs außerhalb des Arbeitsbaums. Dateiinventur und geschützte Hashes ohne Git. |
| E13 | Akzeptiert: ADR-007 umgesetzt; neue Defaults, Parserdispatch, Assessment-Prüfung und tatsächliches Rendering mit/ohne Assessment sind geprüft. |
| E14 | Akzeptiert als nonblocking `[INFRA]`: direkter Unit-Lauf mit `NOT_CRAN=true`; keine Änderung der Gate-Konfiguration. Entscheidung zu BL-56 bleibt beim Betreiber. |
| E15 | Akzeptiert als nonblocking `[INFRA]`: Ergänzung von K-M2-7 in `docs/gates-auswahl.md` bleibt Betreiberarbeit. |
| E16 | Akzeptiert: synthetische Herkunft überschreibt keine berechneten Bänder; Eingaben ohne belegende Metadaten heißen `unverified`. Gemischte Eingabe scheitert vor Fit und Rendering. |
| E17 | Akzeptiert: ausschließlich SQLite-Endungen für den AP1-Store, unabhängig vom generischen CSV-Pfad von msa_run. |
| E18 | Akzeptiert: README beschreibt neuen Store nach gescheitertem Pilot, Archivierung mit SHA-256 und Wiederholung aus der Kopie vor dem Block. Fehlender Provider führt zum Generation-Endpunkt-/ADR-Hinweis, ohne Override. |
| E19 | Akzeptiert: Ergebnis und Bericht nennen Kappa-Basis, ausgeschlossene Items und geladene INSAID-Referenzen. API-Auswertung ohne TSV gibt einen Hinweis und bleibt ausführbar. |
| E20 | Akzeptiert: Erkennung folgt ADR-006, nicht dem weiteren Warnungsbegriff der Mini-Referenz. Keine Anpassung der Mock-Parameter an Fit-Warnungen. Der direkte Mock-Hauptlauf und sein gemeinsamer Fit ergaben keine Fit-Warnungen. |

### Tatsächlich ausgeführte Prüfungen

Alle folgenden Prüfungen liefen in dieser BUILD-Phase. Sie sind
Builder-Diagnosen und ersetzen keine Gate-Abnahme. Die ausgeführten
Skripte und vollständigen Logs liegen unter `/tmp/llmsa-m2-*`; im
Arbeitsbaum wurden keine Laufdaten oder Reports abgelegt.

**Abhängigkeiten (Exit 0):**

```bash
Rscript --vanilla orchestrator/lib/r-deps.R --check-only
```

Tatsächlicher Schluss:

```text
r-deps: pass — 18 Anforderungen erfüllt (R 4.6.1)
```

Vorhanden waren unter anderem `yaml 2.3.12`, `digest 0.6.39`,
`pkgload 1.5.3`, `httr2 1.3.0`, `jsonlite 2.0.0`, `DBI 1.3.0`,
`RSQLite 3.53.3`, `testthat 3.3.2`, `lme4 2.0.6`,
`ordinal 2026.7.26`, `rmarkdown 2.32` und `knitr 1.52`.
Es wurden keine Pakete installiert, aktualisiert oder heruntergeladen.

**Golden-Erzeugung (Exit 0):**

```bash
Rscript --vanilla data-raw/make_items_ap1.R
```

Output:

```text
AP1 freeze: pool 1180 classifications / 71 genes / 35 panels; main 100; pilot 10
Expert-panel conservative exclusions (item/cutoff pairs): 120
2b9f56914b40221512ac20bb217d874bf97c60fbddf6b73977f976fca5c8aa5b  items.csv
6690501d9a6725a08cbdd1f3f3d573bbaa8750153bdcdbf30a308b8038750b63  pilot.csv
85616580d6b7d8163e79d899f22a5a25c1bf4138df3f3f4f8b7b2a079616624d  QUELLE.txt
```

**Reproduktion und negativer Poolfall (Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-reproduce.R
```

Das Diagnoseskript kopiert Produktcode, Daten und Anker in eine
temporäre Paketkopie und verknüpft nur dort die vorhandenen lokalen
Quellen. Es führt denselben Erzeuger unter `C` und `C.UTF-8` aus und
vergleicht SHA-256 aller vier Dateien mit dem erzeugten Satz. Danach
erhöht es ausschließlich in der temporären Ankerkopie die erwartete
Poolzahl um eins und verlangt Abbruch ohne veränderte Ausgabedatei.
Tatsächlicher Output:

```text
AP1 byte reproduction: C 4/4 files identical
AP1 byte reproduction: C.UTF-8 4/4 files identical
AP1 pool mismatch: ERepo pool differs from ANK-51 (counts by classification, gene, panel or class). ; 4/4 existing files unchanged
AP1 reproduction elapsed seconds: 191.414
2b9f56914b40221512ac20bb217d874bf97c60fbddf6b73977f976fca5c8aa5b  items.csv
6690501d9a6725a08cbdd1f3f3d573bbaa8750153bdcdbf30a308b8038750b63  pilot.csv
85616580d6b7d8163e79d899f22a5a25c1bf4138df3f3f4f8b7b2a079616624d  QUELLE.txt
76005dc691e837eb9c6cdcda8273ea5b12baff2e7d7c0d6aaa6434cd9f7930f6  SHA256SUMS
```

Die Dateigrößen sind 21.291, 2.816, 1.917 und 229 Bytes. Die
Größenprüfung im Erzeuger nutzt ANK-TOL; es gibt keinen Rohdatenimport
in den Arbeitsbaum. Eine weitere Kollation ist nicht installiert
(`locale -a`: C, C.utf8, POSIX).

**Dokumentation, API und Zeichensatz (jeweils Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-docs.R
Rscript --vanilla /tmp/llmsa-m2-api.R
```

Roxygen wurde in einer temporären Paketkopie ausgeführt; nur die fünf
betroffenen Rd-Dateien wurden übernommen. Der API-Vergleich lädt das
Paket, liest ANK-02 und vergleicht sämtliche vorhandenen Positionen
und Vorgabewerte; zusätzlich verlangt er Defaults für Anhänge. Output:

```text
Documentation: generated 5 Rd files with roxygen2 8.1.1 ; NAMESPACE byte-identical
Appended default: msa_report assessment = NULL
Appended default: msa_run parse_by_prompt = NULL
Appended default: parse_choice whole_word = FALSE
ANK-02: 22 exports; all original argument positions/defaults preserved; no acmg export
R ASCII: pass
```

**Unit-, Integrations- und Berichtstests:**

Die neuen Unit-Tests verwenden nur installierbare Paketressourcen und
kleine ausdrücklich synthetische Eingaben. Sie decken T1 bis T5 und T7
ab: serialisierte HTTP-Anfragen, Dummy-Schlüsselzuordnung, API-Pilot
durch den CLI-Treiber, HTTP-Fehler mit Weiterlauf, Pilotgrenzen,
Herkunftskonflikte und unveränderte Stores, INSAID-Vorprüfung, Evaluation
ohne API-Konstruktion, Modal-/NA-Regeln, unabhängige Kappa-Gegenrechnung,
Bootstrap mit verworfenen Wiederholungen und RNG-Rückgabe, Fit-Rückfall,
unveränderte Reihenfolge, Referenzbasis, Unvollständigkeit, PB-Denominatoren,
Effekte, Bänder und tatsächliches Rendering. Die schnelle Unit-Prüfung
ersetzt keine wissenschaftliche Kernvalidierung aus M1.

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat
```

Abschließender tatsächlicher Output (Exit 0):

```text
Duration: 19.7 s
── Skipped tests (1) ──
• requireNamespace("ellmer", quietly = TRUE) is TRUE (1):
  'test-backends.R:32:3'
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 680 ]
r-tests: pass — 59 Tests in tests/testthat; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit elapsed seconds: 21.44; exit: 0
```

Der vorhandene ellmer-Skip wurde nicht geändert. Der Berichtstest mit
`skip_on_cran()` lief in diesem direkten Aufruf durch `NOT_CRAN=true`
tatsächlich mit. Der neue HTTP-400-Fall prüft den gespeicherten Fehler,
den erfolgreichen Folgeaufruf und JSON-null in den persistierten
Metadaten. Frühe Tests fanden Fehler in den neuen Testhilfen
(leerer R-Listenname, Argumentposition und NULL-Serialisierung des
synthetischen httr2-Response-Bauers); diese wurden berichtigt, ohne
die geforderten Prüfungen abzuschwächen. Der abschließende Lauf enthält
auch die Qualifizierung von `utils::head`/`utils::tail`, eine echte
numerische Fit-Permutation mit Abweichungen relativ zur Gesamtvarianz
und eine unabhängige Gegenrechnung des interpolierten Pilot-Quantils.
Der zusätzliche Präzisionsfall führte zunächst zu einem echten
Fehlschlag für `1 / 3`; die JSON-Serialisierung wurde korrigiert,
der identische Vergleich beibehalten. Der obige abschließende Lauf
enthält diese Korrektur aus ADR-009.

**Unveränderte API-Aufzeichnungen, ergänzender Builder-Prüfweg (Exit 0):**

```bash
Rscript --vanilla /tmp/llmsa-m2-recordings.R
```

Das separate Diagnoseskript lädt keine Abnahme-Helfer. Es prüft die
drei Betreiber-Aufzeichnungen gegen ANK-94, übergibt ihre unveränderten
JSON-Bytes mit `httr2::local_mocked_responses()` an die tatsächlichen
AP1-Backends und führt `msa_run()` mit SQLite aus. Der Request-Abgleich
nutzt URL, Modell und den tatsächlichen httr2-Body-Serializer ohne
Socket. Schlüssel sind ausdrücklich synthetisch. Antworttext, IDs,
Modell, Fingerprint einschließlich NULL, Routing und verschachtelte
`usage` werden identisch mit den Originalen verglichen. Die erste
Ausführung fand den in ADR-009 dokumentierten Rundungsfehler; nach
der Produktkorrektur lautet der tatsächliche Output:

```text
Raw recording replay: sol response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Raw recording replay: llama response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Raw recording replay: qwen response, metadata, routing and SQLite persistence passed; parsed = Uncertain significance
Recording checksums: 3/3 match ANK-94 and remain unchanged; live API calls: 0
Ran 1/1 deferred expressions
```

Dieser zusätzliche Nachweis ersetzt den unveränderten roten
Abnahmelauf nicht und verändert weder dessen Helfer noch die Fixtures.

**Paketbau und installierter Paketcheck (Exit 0):**

Eine explizite Positivliste kopiert nur Paketdateien in
`/tmp/llmsa-m2-check/src`: DESCRIPTION, NAMESPACE, LICENSE, NEWS,
README, .Rbuildignore, R, man, data, inst, vignettes sowie
tests/testthat.R und tests/testthat. Kein Git-Export, keine
Schlüsseldatei, keine geschützte Quelle und kein Harness-Pfad wird
kopiert. Dort wurden ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht exakt dem gelesenen Betreiber-
Prüfskript `orchestrator/lib/r-check.sh`; dieses selbst wurde wegen
seiner Git-Kommandos nicht gestartet. Keine andere Prüfregel wurde
gelockert. Der erste Check ergab zwei NOTEs; der Produktcode-Hinweis
auf unqualifizierte `head`/`tail` wurde im Produktcode behoben. Der
erneute Check nach der Korrektur ergab nur noch die Uhrzeit-NOTE.
Nach Ergänzung der letzten Unit-Fälle und der Präzisionskorrektur
aus ADR-009 wurde die Paketkopie nochmals mit dem aktuellen
Produkt- und Teststand gebaut und geprüft. Der abschließende
vollständige Check endet mit:

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 57.15; exit: 0
```

Die verbleibende NOTE ist wörtlich:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Uhrzeitprüfung wurde nicht deaktiviert. Installierte Tests:
`[ FAIL 0 | WARN 0 | SKIP 2 | PASS 676 ]`. Die beiden vorhandenen
Skips sind der Berichtstest mit `skip_on_cran()` und der ellmer-
Fehlerpfad, weil ellmer installiert ist. Der neue AP1-Berichtstest
läuft auch im Paketcheck. Der HTTP-400-Fall, die echte numerische
Permutation, die Pilot-Quantilprüfung und der numerische Metadaten-
Rundlauf sind im abschließenden direkten Unit-Lauf und im
abschließenden Paketcheck enthalten.

**Direkter Mock-Lauf und Bericht:**

```bash
Rscript --vanilla inst/validation/ap1/run.R --part pilot --backend mock --store /tmp/llmsa-m2-pilot.sqlite
Rscript --vanilla inst/validation/ap1/run.R --part main --backend mock --store /tmp/llmsa-m2-main.sqlite
Rscript --vanilla inst/validation/ap1/run.R --evaluate-only --backend mock --store /tmp/llmsa-m2-main.sqlite --report-dir /tmp/llmsa-m2-smoke-reports
```

Alle drei Aufrufe endeten mit Exit 0. Relevanter tatsächlicher Output:

```text
AP1 pilot backend=mock; stored calls=90; store=/tmp/llmsa-m2-pilot.sqlite
sol parser passed: 29 recognized of 30 planned; complete=TRUE
llama parser passed: 29 recognized of 30 planned; complete=TRUE
qwen parser passed: 30 recognized of 30 planned; complete=TRUE
AP1 main backend=mock; stored calls=5400; store=/tmp/llmsa-m2-main.sqlite
```

Alle drei Modelle meldeten `4xx passed`, `provider failed` und
`cost failed`; der Mock liefert keine Provider- oder Tokenmessungen.
Beide Hauptplanblöcke hatten im Wiederholungstagsbericht Fehleranteil
0 und keine beobachteten Anbieter-/Modellwechsel. Die drei HTML-Dateien
`ap1-sol.html`, `ap1-llama.html`, `ap1-qwen.html` wurden gerendert.
Sie berichten für diese Mock-Daten jeweils `No fit warnings.`; der
gemeinsame Fit hat ebenfalls keine Warnung. Die Formate tragen die
vorläufige und synthetische Kennzeichnung. Zusätzlich erscheint vom
R-/Pandoc-Umfeld die Meldung `Failed to connect to system scope bus via
local transport: Operation not permitted`; das Rendering endet dennoch
erfolgreich und die Dateien wurden in den Tests inhaltlich geprüft.

**Vollständiger unveränderter M2-Abnahmelauf vor ADR-009 (Exit 1):**

```bash
/usr/bin/time -f 'M2 acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Alle sieben M2-Dateien mit ihren 62 Testblöcken liefen, ohne Skip.
Es wurde keine Acceptance-Funktion ersetzt und keine Replay-Hilfe
angepasst. Die längste Teilprüfung enthält die unabhängige
Parser-Gegenrechnung sowie sämtliche Mock-CLI-Läufe und Resume.
Tatsächlicher Reporter-Output nach Datei:

```text
✔ |        149 | m2-1-items [132.3s]
✔ |         34 | m2-2-memorisation [83.7s]
✔ |        837 | m2-3-prompts-parser [488.2s]
✖ | 6       14 | m2-4-backends [1.6s]
✔ |        106 | m2-5-plan [1.7s]
✔ |        374 | m2-6-evaluate [96.5s]
✖ | 1      353 | m2-7-robustness-pilot [93.1s]
Duration: 897.2 s
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 1867 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
M2 acceptance elapsed seconds: 899.16; exit: 1
```

Die sieben negativen Erwartungen verteilen sich auf sechs Testblöcke:
fünf in K-M2-4 und den Systemspalten-Test von K-M2-7. Ursprung ist
jeweils der unveränderte HTTP-Replay-Pfad:

```text
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Die nachgelagerte JSON-Prüfung sieht deshalb fehlende `meta` statt einer
Aufzeichnung. Im 4xx-Fall ist auch der zweite Aufruf ein Socket-Fehler
statt der aufgezeichneten erfolgreichen Antwort; daraus entstehen zwei
fehlgeschlagene Erwartungen. Der Systemspalten-Test stoppt bereits beim
ersten Replay. Alle übrigen M2-Testblöcke bestehen. Die beiden Stores
des Mock-Prüfwegs enthalten 9.090 Zeilen (Hauptplan, PB, Pilot; erneuter
Pilot unverändert) und 5.400 Zeilen (Hauptplan am Stück); Reihenfolge,
Prompthashes und Ausschluss neuer Dateien bestehen in der Abnahme.
Die K-M2-6-Nachrechnungen bestehen auch bei erzwungenem Rückfall und
nach lokalem INSAID-Join. Für die reale API-Wiedergabe bleibt
M2-BUILD-INFRA-01 offen, für die Anbieter-Policy A.7 zusätzlich
M2-BUILD-INFRA-02. Das Gesamtergebnis dieses Abnahmelaufs ist rot.

Nach der alleinigen Änderung der numerischen Metadaten-Serialisierung
durch ADR-009 wurden alle Unit-Tests, der installierte Paketcheck,
der separate Aufzeichnungsprüfweg und die betroffene unveränderte
API-Abnahmedatei erneut ausgeführt. Die vollständige M2-Suite wurde
nicht nochmals ausgeführt. Befehl des gezielten Abnahmelaufs:

```bash
/usr/bin/time -f 'M2 API acceptance after ADR-009 elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'testthat::test_dir("tests/acceptance",filter="m2-4-",load_package="source",reporter=testthat::ProgressReporter$new(show_praise=FALSE),stop_on_failure=TRUE)'
```

Tatsächlicher Schluss nach ADR-009, weiterhin dieselben Socket- und
Folgefehler in den fünf betroffenen Testblöcken:

```text
[ FAIL 6 | WARN 0 | SKIP 0 | PASS 14 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
M2 API acceptance after ADR-009 elapsed seconds: 3.08; exit: 1
```

**Abschließende Dateiintegrität (Exit 0):**

Ein lesender Python-Vergleich gegen das vor BUILD angelegte Inventar
unter `/tmp/llmsa-m2-before.json` prüft neue und geänderte Pfade sowie
SHA-256 der erfassten geschützten Dateien. Git-Metadaten und
Geheimnisdateien sind vom Inhaltsvergleich ausgeschlossen; es werden
keine Geheimnisinhalte gelesen. Ausgeführt wurde
`python3 /tmp/llmsa-m2-integrity.py`. Tatsächlicher Output:

```text
Inventory: 18 new files; 13 changed baseline files; all in Builder paths; no missing baseline files
Protected baseline: 78 files byte-identical
Workspace artifacts: no Rplots.pdf, tarball or Rcheck directory
R ASCII: pass
```

Die 78 Dateien umfassen alle erfassten Abnahmetests, API-Fixtures,
Anker, Spezifikationen, Verträge, Handoffs sowie AGENTS,
IMPLEMENTATION-RULES, toolchain.json, NAMESPACE, .Rbuildignore,
tests/testthat.R und beide Mutations-Scope-Dateien. Die
Inventur ersetzt nicht die Territoriumsprüfung des Orchestrators.

### Offene Punkte und Übergabe

- **M2-BUILD-INFRA-01 — `[INFRA]`, nonblocking für den Builder.**
  Ref: K-M2-4, K-M2-7 Systemspalte, ACC-10 und
  `tests/acceptance/setup-m2.R:771`. Der unveränderte Replay-Helfer
  verwendet `httr2::req_dry_run()`, das in httr2 1.3.0 über curl/httpuv
  einen lokalen Socket öffnet. Die Builder-Sandbox verweigert ihn mit
  `System failure for: socket() (Operation not permitted)`. Dadurch
  können diese Abnahmefälle hier keine erfolgreiche HTTP-Wiedergabe
  belegen; Folgefehler betreffen fehlende Metadaten und die zweite
  Antwort nach einem HTTP-Fehler. Kein Test und keine Berechtigung
  wurde geändert. Die eigenen Unit-Tests prüfen die Bytes mit dem
  tatsächlichen httr2-Serializer ohne Socket und durchlaufen den
  Produkt-HTTP-Pfad mit synthetischen Antworten. Der zusätzliche
  separate Prüfweg reproduziert außerdem alle drei unveränderten
  Betreiber-Aufzeichnungen einschließlich persistierter Metadaten.
  Das ist ergänzende Evidenz, kein Ersatz für die Aufzeichnungsabnahme. Vorschlag an
  Betreiber/Reviewer: unveränderte Abnahme im regulären Gate-Umfeld
  mit funktionsfähigen lokalen Sockets ausführen.
- **M2-BUILD-INFRA-02 — `[INFRA]`, Quellenlücke.**
  Ref: `docs/03-anwendungspipeline.md` A.7 und PLAN-UPDATE E11.
  Die bezeichnete eingefrorene `Provider_Logging.html` liefert
  allgemeine OpenRouter-Regeln, aber keine spezifischen Belege für
  CoreWeave oder DeepInfra. Sowohl Textspiegel als auch HTML wurden
  geprüft. Tatsächlicher Output der HTML-Suche:
  `Provider_Logging snapshot: CoreWeave lines = 0 ; DeepInfra lines = 0`.
  YAML und Berichte nennen den belegten allgemeinen Stand und diese
  Lücke; sie erfinden keine Aufbewahrungsdauer. Handoff-Vorschlag:
  Betreiber liefert datierte Anbieterbelege, Reviewer bestätigt die
  Ergänzung mit dem nötigen ADR-/Ankerweg. A.7 gilt in diesem Punkt
  nicht als vollständig belegt.
- **E14 / BL-56 und E15 / BL-48 — `[INFRA]`.** Gate-Umgebung für
  `NOT_CRAN` und die dokumentierte Zuordnung von K-M2-7 bleiben beim
  Betreiber. BACKLOG wurde nicht angefasst; der Reviewer übernimmt
  offene Punkte im Code-Review.
- **PLAN-M2-QA-1 — `[QA-PENDING]`.** Eigenständige E2E-/Fuzz-Prüfung
  bleibt bei QA. Der Builder ersetzt weder diese Rolle noch die
  Reviewer-Abnahme durch eigene Tests.

Die einzige Planergänzung ist die in ADR-009 dokumentierte Korrektur
der numerischen JSON-Präzision. Es gab keinen API-Netzzugriff, keine
Verwendung realer API-Schlüssel, keine Git-Kommandos und keinen Bypass. Statistikkern
`R/fit.R`/`R/grr.R`, Abnahmetests, Anker, Verträge und Orchestrator
bleiben unverändert. Der Orchestrator führt Territoriumsprüfung,
Phasen-Commit und die vollständigen M0/M2-/QA-Gates aus. Insbesondere
werden hier weder `gates.json` geschrieben noch K-M2 pauschal als
abgenommen erklärt.

## M2 — REWORK, Runde 2 (27.10.2026)

Die fünf blocking-Befunde E21 bis E25 aus REVIEW Runde 1 sind im
Produktcode `R/acmg.R` nach ADR-010 behoben; E27 ist zusätzlich
umgesetzt. Der aktuelle Builder-Lauf belegt die unveränderten fünf
QA-Tests grün. Die vollständige Gate-Abnahme steht weiterhin aus.
Maßgeblich bleiben die gelesenen Gate-Fakten von Runde 1:
`tests: fail`, `result: fail`, alle anderen Gates `pass`, kein
Status `error`. Deren Ursache waren ausschließlich QA-M2-001 bis
QA-M2-005; die Abnahme war dort mit 2.340 Erwartungen grün.

Die vollständigen Antworten mit Referenzen, Dateistellen, Kommandos
und tatsächlichem Output stehen in
`orchestrator/handoff/M2/REWORK-NOTES.md`. ARBITER liegt nicht vor;
LESSONS enthält keine zusätzliche Lehre. Kein neuer Builder-ADR ist
nötig, da die Änderungen die angenommene ADR-010 umsetzen.

| Befund | Antwort und Stand |
| --- | --- |
| E21 / QA-M2-001 | Behoben: Wiederholungstagsdiagnosen enthalten nur beobachtete Modell-/Blockkombinationen. Jeder Einzelmodellbericht enthält seine eigenen korrekten Diagnosen. |
| E22 / QA-M2-002 | Behoben: Fehlende oder leere Anbieterwerte fehlerfreier OpenRouter-Antworten lösen den Wiederholungstagshinweis aus; Sol und fehlende Angaben bei Backendfehlern erzeugen diesen zusätzlichen Auslöser nicht. |
| E23 / QA-M2-003 | Behoben: Ein API-Marker ersetzt keine fehlenden Zeilenbelege. Mock-Herkunft bleibt synthetisch. API-Stores mit unbelegten fehlerfreien Zeilen werden schreibgeschützt abgewiesen; reine Fehlerstores mit Marker und bisherige Konfliktprüfungen bleiben unterstützt. |
| E24 / QA-M2-004 | Behoben: Modal- und Ausschlusszählungen umfassen jedes Planitem, auch ohne Hauptplanzeile. Merkmale stammen nur aus runs; vollständig fehlende Merkmale bleiben NA. PB-Referenzquoten verwenden die PB-Referenzspalte. Unvollständige Hauptpläne bleiben not assessed. |
| E25 / QA-M2-005 | Behoben: Klassenprüfung auch über PB-Zeilen vor dem Fit. Ungültige Replikat-/Blockwerte oder doppelte Schlüssel verhindern eine vollständige Robustheitsbewertung. |
| E26 | ADR-010 Nr. 6 bestätigt die strengere Pilotsperre ohne API-ID. Keine Produktänderung; für alle drei Modelle unit-getestet. Die Entkopplung des Pilot-Quantiltyps bleibt BL-64. |
| E27 | Behoben: Bericht nennt fehlende provider- und system_fingerprint-Felder unter fehlerfreien Antworten mit Nenner; echtes HTML-Rendering geprüft. BL-65 zur Schließung an den Reviewer. |
| E28 / BL-63 | OUT-OF-TERRITORY [INFRA]: Provider_Logging-Snapshot erneut geprüft, jeweils 0 Treffer für CoreWeave/DeepInfra. Datierte spezifische Belege fehlen; Betreiber/Reviewer müssen sie liefern und verankern. |
| E29 / BL-56 | OUT-OF-TERRITORY [INFRA]: gate-tests.log:92 enthält weiter den On-CRAN-Skip von test-report.R:5. Der direkte Builder-Lauf führt ihn mit NOT_CRAN=true aus; Gate-Konfiguration bleibt Betreiberarbeit. |
| E30 / BL-48 | OUT-OF-TERRITORY [INFRA]: docs/gates-auswahl.md:87 nennt weiterhin K-M2-1 bis K-M2-6. Ergänzung von K-M2-7 bleibt Betreiberarbeit. |

### Echte Prüfbelege dieser Runde

**Unveränderte QA vor der Änderung (Exit 1):**

```bash
Rscript --vanilla orchestrator/lib/r-tests.R tests/e2e tests/fuzz
```

```text
[ FAIL 8 | WARN 0 | SKIP 0 | PASS 2 ]
[ FAIL 5 | WARN 0 | SKIP 0 | PASS 0 ]
r-tests: fail — 5 Tests in tests/e2e, tests/fuzz; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
```

**Unit- und unveränderte QA-Tests nach der Korrektur (Exit 0):**

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

```text
✔ |        194 | acmg-rework [7.5s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 874 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 73 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 33.90; exit: 0
```

Neun neue Unit-Blöcke unter `tests/testthat/test-acmg-rework.R`
decken E21 bis E27 ab. Alle bestehenden Tests bleiben byte-identisch.
Der einzige direkte Skip ist der vorhandene ellmer-Fehlerpfad, weil
ellmer installiert ist. Der generische Berichtstest wird tatsächlich
ausgeführt. Die neue HTML-Prüfung normalisiert nur Render-Leerraum;
erwarteter Text und Zahlen bleiben exakt.

In einer temporären Paketkopie mit denselben neuen Tests, aber der
gesicherten alten `acmg.R`, scheitern acht der neun neuen Blöcke;
E26 besteht auch vorher. Echter Schluss des in REWORK-NOTES vollständig
angegebenen Kommandos (erwartet Exit 1):

```text
Baseline regression blocks: 9; failed: 7; errors: 4; skipped: 0
```

Fehler und Fehlschläge überlappen in den Blockzählungen. Der aktuelle
Quellbaum wurde für diese Gegenprobe nicht zurückgesetzt.

**Betroffene unveränderte Abnahme (Exit 1, lokale Infrastruktur):**

```bash
/usr/bin/time -f 'M2 targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[67]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✔ |        374 | m2-6-evaluate [216.3s]
✖ | 1      353 | m2-7-robustness-pilot [94.1s]
Duration: 310.4 s
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 727 ]
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
M2 targeted acceptance elapsed seconds: 312.17; exit: 1
```

**M2-R2-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Der einzige
negative Test ist die Systemspalten-Wiedergabe in K-M2-7: Der
unveränderte Reviewer-Helfer öffnet über curl/httpuv einen lokalen
Socket, den die Builder-Sandbox verweigert. Vollständiger Stacktrace
in REWORK-NOTES und `/tmp/llmsa-m2-r2/acceptance.log`. Kein Testhelfer,
keine Berechtigung und kein Produktcode wurden zur Umgehung geändert.
K-M2-6 und die fachliche Robustheitsauswertung bestehen. Im regulären
Gate der Runde 1 bestand auch dieser Socket-Pfad; der historische
M2-BUILD-INFRA-01 ist dort laut REVIEW erledigt. Der Orchestrator
führt den aktuellen vollständigen M0/M2-Lauf im Gate-Umfeld aus.
Die übrigen M2-Abnahmedateien wurden hier nicht erneut gestartet;
M0-Prüfwege mit Git-Kommandos wurden nicht ausgeführt.

**Paketbau und installierter Check (je Exit 0):**

Mit einer Positivliste der Paketdateien wurde eine Kopie ohne
Schlüssel, geschützte Quellen und Harness-Dateien unter
`/tmp/llmsa-m2-r2/package-check/src` angelegt. Darin ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 66.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 870 ]
```

Incoming-Remote entspricht dem Betreiber-Prüfskript; keine andere
Prüfregel wurde abgeschaltet. **M2-R2-INFRA-CLOCK — OUT-OF-TERRITORY
[INFRA]:** Die einzige NOTE lautet `Unable to verify current time.`
Die Uhrzeitprüfung bleibt aktiv. Die beiden installierten Skips sind
unverändert On-CRAN im generischen Bericht und ellmer. Neue AP1-
Berichts- und Regressionsprüfungen laufen auch im installierten Paket.

### Integrität und Übergabe

`python3 /tmp/llmsa-m2-r2/integrity.py` endete mit Exit 0:

```text
Inventory: 2 changed baseline files, 2 new files; all assigned Builder paths; no removed files
Preserved baseline: 154/154 files byte-identical
Existing tests and fixtures: 38/38 byte-identical
R source and new test comments: ASCII
Workspace artifacts: no Rplots.pdf, package archive, Rcheck directory or SQLite store
Gate facts: still round 1, result fail; no Builder verdict or state write
```

Geändert sind `R/acmg.R` und dieser Nachtrag; neu sind die Unit-Datei
und die zugewiesene `orchestrator/handoff/M2/REWORK-NOTES.md`.
Die SHA-256-Inventur ersetzt nicht das Territoriums-Gate.
R/fit.R und R/grr.R bleiben unverändert; keine MUT-EQUIV-Claims und
keine Approvals. Es gibt keinen offenen QA-PENDING-Befund aus dem
aktuellen Review. Keine Git-Kommandos, keine Abhängigkeitsinstallation,
keine realen API-Schlüssel oder API-Aufrufe, keine Golden- oder
Schwellenänderung, kein eigener Gate- oder Verdict-Schreibzugriff.
Territoriumsprüfung, Phasen-Commit und Abnahme folgen durch den
Orchestrator und Reviewer.

## M2 — REWORK, Runde 3 (27.10.2026)

Der Abschluss der vorigen Runde ist inzwischen belegt:
`orchestrator/state/M2/gates.json` nennt Runde 2 und `result: pass`;
alle acht Gates sind grün, kein Status `error`. REVIEW Runde 2 nimmt
E21 bis E25 und E27 an und bestätigt E26. Es verlangt trotzdem
REWORK wegen E31: R-Partial-Matching verwechselt im Pilot einen
fehlenden Antwortanbieter mit dem Anfragerouting `provider_order`.
Die lokalen Socket-/Uhrzeitbefunde der Runde 2 traten im damaligen
regulären Gate nicht auf.

E31 ist jetzt im Produktcode behoben; E32 und E33 sind zusätzlich
umgesetzt. Die Belege und vollständigen Kommandos stehen in
`orchestrator/handoff/M2/REWORK-NOTES.md` der Runde 3. ARBITER liegt
weiterhin nicht vor, LESSONS enthält keine Lehre. Diese Builder-
Prüfungen erteilen keine Gate-Abnahme.

Geändert ist ausschließlich Produktcode in `R/acmg.R`, dazu dieser
Nachtrag und der zugewiesene Handoff. Neu sind sieben Unit-Blöcke in
`tests/testthat/test-acmg-pilot-metadata.R`. Bestehende Tests, Fixtures,
Anker, Plan, Schwellen, Schnittstellen und Mutations-Scope bleiben
unverändert; kein neuer ADR ist erforderlich.

| Befund | Antwort und Stand |
| --- | --- |
| E31 | Behoben: exakte Metadatenfelder für Anbieter, API-/Mock-Belege und Tokens. Fehlender/null/leerer/Leerraum-Anbieter liefert zwölf Pilotregeln und den Generation-Hinweis mit Antwort-ID. Pilot und Resume berichten; main und robustness bleiben vor weiteren Aufrufen benannt gesperrt. Direkte Auswertung und evaluate-only übergeben alle Pilotregeln an die Berichte. |
| E32 / BL-66 | Behoben: Eine gescheiterte Anbieterregel nennt fehlende API-Belege (`meta$id`, `meta$model_snapshot`), auch bei richtigem Anbieter. Die strengere Sperre bleibt erhalten. |
| E33 / BL-67 | Behoben: Unbelegte Store-Herkunft erhält eine eigene Meldung mit Zahl der betroffenen fehlerfreien Antworten, Belegfeldern und Hinweis auf einen neuen Store. Schreibgeschützter Abbruch und unveränderter Store bleiben erhalten. |
| E26 / BL-64 | Sperre bestätigt und weiter belegt. Quantil-Entkopplung vertagt: Der unveränderte freigegebene Plan trägt Typ 7; diese Korrektur ändert keine statistische Rechenregel. |
| E28 / BL-63 | OUT-OF-TERRITORY [INFRA]: Provider-Logging-Textspiegel enthält weiter je 0 Treffer für CoreWeave und DeepInfra. Betreiber liefert datierte spezifische Belege; Reviewer verankert sie. |
| E29 / BL-56 | OUT-OF-TERRITORY [INFRA]: Gate-Log Runde 2, Zeile 107, enthält den On-CRAN-Skip; r-tests.R enthält 0 NOT_CRAN-Verweise. Der direkte Unit-Lauf führt den Bestandsbericht aus. Dauerhafte Gate-Konfiguration bleibt beim Betreiber. |
| E30 / BL-48 | OUT-OF-TERRITORY [INFRA]: docs/gates-auswahl.md:87 nennt weiter K-M2-1 bis K-M2-6. Betreiber ergänzt K-M2-7. |
| E21–E25 / QA-M2-001–005 | Laut REVIEW Runde 2 erledigt; alle unveränderten QA- und bisherigen Regressionsprüfungen bleiben grün. |
| E27 | Erledigt; der unveränderte Bestandsregressionstest rendert und prüft die Fehlstellenzählungen im HTML-Bericht. |

### Ausgeführte Prüfungen

**Regressionserkennung (erwartet Exit 1).** Die endgültigen sieben
neuen Blöcke laufen in einer temporären Paketkopie mit der vor dieser
Phase gesicherten `R/acmg.R`. Alle sieben sind rot; zwei enthalten
sowohl fehlgeschlagene Erwartungen als auch einen Fehler. Tatsächlicher
Output aus `/tmp/llmsa-m2-r3/regression-final-before.log`:

```text
Regression blocks: 7; failed blocks: 4; error blocks: 5; skips: 0
Error: Error in `vapply(responses, function(x) x$provider %||% "", "")`: values must be type 'character',
 but FUN(X[[1]]) result is type 'list'
```

Der Arbeitsbaum wurde dafür nicht zurückgesetzt. Dies ist kein
Mutationsscore und kein Äquivalenz-Claim.

**Neue Tests einschließlich Betreiber-Aufzeichnungen (Exit 0).**

```bash
Rscript --vanilla -e 'options(llmsa.test.ap1_recordings = normalizePath("tests/fixtures/api")); testthat::test_dir("tests/testthat", filter = "acmg-pilot-metadata", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✔ |        370 | acmg-pilot-metadata [14.2s]
Duration: 14.2 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 370 ]
```

Alle Blöcke laufen im installierten Paket mit ausdrücklich synthetischen
Antworten. Die explizite Testoption fügt die vorhandenen Aufzeichnungen
hinzu und verlangt dann deren Dateien. Änderungen an den Antworten
finden nur im Speicher statt; alle drei Dateien entsprechen weiterhin
ANK-94. URL-/Modell-Matching und synthetische Schlüssel verhindern
reale Aufrufe. Die Auswertungs-Unit-Prüfung nutzt Fit-/Renderer-Stubs
und prüft die an den Renderer übergebenen Pilot-Tabellen; echte Fits
und Berichte sind durch die unveränderte Abnahme unten belegt.

**Unit- und unveränderte QA-Tests (Exit 0).**

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

```text
✔ |        222 | acmg-pilot-metadata [6.8s]
✔ |        194 | acmg-rework [7.8s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1096 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 80 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 41.65; exit: 0
```

Der unveränderte ellmer-Fehlerpfad ist der einzige Skip. Der generische
Bestandsbericht wird durch `NOT_CRAN=true` tatsächlich ausgeführt.

**Paketbau und installierter Paketcheck (je Exit 0).** Eine Positivliste
kopiert Paketdateien nach `/tmp/llmsa-m2-r3/package-check/src`, ohne
Schlüssel, Betreiber-Fixtures oder Harness-Dateien. Im übergeordneten
Verzeichnis ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

```text
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 71.84; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 1092 ]
```

**M2-R3-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Die einzige NOTE
laut `package-check/check.log:29–31` lautet `Unable to verify current
time.` Die Uhrzeitprüfung bleibt aktiv. Incoming-Remote entspricht
dem Betreiber-Prüfskript; keine weitere Prüfregel wurde abgeschaltet.
Die beiden installierten Skips sind wie bisher der generische Bericht
(On CRAN) und ellmer. Keine ERRORs/WARNINGs.

**Betroffene unveränderte Abnahme (Exit 1, Infrastruktur).**

```bash
/usr/bin/time -f 'Targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[467]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✖ | 6       14 | m2-4-backends [1.1s]
✔ |        374 | m2-6-evaluate [219.5s]
✖ | 1      353 | m2-7-robustness-pilot [93.7s]
Duration: 314.6 s
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 741 ]
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
Targeted acceptance elapsed seconds: 316.37; exit: 1
```

**M2-R3-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Der unveränderte
HTTP-Replay-Helfer von K-M2-4/K-M2-7 öffnet über curl/httpuv einen
lokalen Socket; die Sandbox verweigert ihn. Folgefehler betreffen
fehlende gespeicherte Metadaten und die zweite Antwort nach HTTP 4xx.
Es sind dieselben sechs Testblöcke wie im ursprünglichen BUILD.
`acceptance.log` enthält die vollständigen Stacktraces; REWORK-NOTES
ordnet die sieben negativen Erwartungen zu. Keine Umgehung, kein
Test- oder Produkt-Scheinfix.

K-M2-6 besteht vollständig mit echten Fits, Rückfall und HTML-Berichten;
die fachliche PB-Auswertung in K-M2-7 ebenfalls. Die übrigen
M2-Abnahmedateien wurden hier nicht wiederholt. Die vollständigen
Gates, einschließlich der Git-verwendenden M0-Prüfwege, führt der
Orchestrator nach der Territoriumsprüfung aus.

### Integrität und Übergabe

`python3 /tmp/llmsa-m2-r3/integrity.py` endete mit Exit 0:

```text
Inventory: 3 changed baseline files, 1 new file; all assigned Builder paths; no removed files
Changed: PROGRESS.md, R/acmg.R, orchestrator/handoff/M2/REWORK-NOTES.md
New: tests/testthat/test-acmg-pilot-metadata.R
Protected baseline: 201/201 files byte-identical
Existing tests and fixtures: 39/39 files byte-identical
R source and new test: ASCII
Checked package copy: final R/acmg.R and new test byte-identical
Workspace artifacts: no Rplots.pdf, package archive, Rcheck directory or SQLite store at the root
Gate facts: still round 2, result pass; no Builder verdict or state write
```

Die Inventur ersetzt nicht das Territoriums-Gate. Kein Zugriff auf
Git-Metadaten oder Schlüsseldateien, keine Git-Kommandos, keine
Installation und keine realen API-Aufrufe. R/fit.R und R/grr.R sind
unverändert; keine MUT-EQUIV-Claims und keine Approvals. Es gibt
keinen offenen QA-PENDING-Befund im aktuellen Review. E31 bis E33
werden zur Prüfung übergeben; E26/BL-64 bleibt vertagt, Infrastruktur
mit Log-Belegen OUT-OF-TERRITORY. BACKLOG-Pflege und vollständige
Gate-Abnahme bleiben bei Reviewer und Orchestrator.
