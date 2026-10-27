# REWORK-NOTES — M2, Runde 3

Rolle: Builder · Phase: REWORK · Stand: 27.10.2026.
Grundlage: REVIEW und verdict-code der Runde 2, K-M2-1 bis K-M2-7,
CRITERIA ACC-1 bis ACC-25, ADR-006 und ADR-010. Gelesen wurden AGENTS,
IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, PROGRESS, die
Fachspezifikationen, die betroffenen Abnahmetests und Gate-Logs.
ARBITER liegt nicht vor; LESSONS enthält keine zusätzliche Lehre.

Der gelesene Gate-Stand ist Runde 2: alle acht Gates und `result` sind
`pass`. Kein Gate ist fachlich rot oder hat Status `error`. REVIEW
verlangt trotzdem REWORK wegen E31. Diese Notizen dokumentieren
Builder-Prüfungen; neue Gate-Fakten und die Abnahme stehen aus.

Produktänderungen: ausschließlich `R/acmg.R`. Neu sind sieben
Unit-Blöcke in `tests/testthat/test-acmg-pilot-metadata.R`; ergänzt
werden PROGRESS und dieser zugewiesene Handoff. Bestehende Tests,
Aufzeichnungen, Anker, Schwellen und der freigegebene Plan bleiben
unverändert. Ein neuer ADR ist für diese Umsetzung der bestehenden
Verträge nicht erforderlich.

## Antworten auf die Befunde

### E31 — behoben im Produktcode

Ref: K-M2-4, K-M2-7; ADR-006 Nr. 7.2, 7.6, 7.7; docs/01 §2 Nr. 4;
PLAN-REVIEW E18.

`acmg_pilot()` (`R/acmg.R:483`) liest den bedienenden Anbieter über
`acmg_meta_text(responses, "provider")`. Das Anfragerouting
`provider_order` kann damit kein fehlendes Antwortfeld ersetzen.
Fehlende, JSON-null-, leere und reine Leerraumwerte ergeben eine
nicht bestandene Anbieterregel, einen Hinweis auf
`GET /api/v1/generation` und die betroffene Antwort-ID. Eine fehlende
ID wird als `unavailable` ausgewiesen. Die Regel liefert stets einen
logischen Wert, auch bei fehlenden Anbietern.

Alle übrigen Metadatenzugriffe im Pilot und in `acmg_meta_kind()`
(`R/acmg.R:445`) verwenden ebenfalls exakte Feldnamen. Zusätze wie
`id_requested`, `model_snapshot_requested`, `mock_description` oder
`usage_estimate` ersetzen keine API-Belege oder gemessenen Tokens.
Die bisherigen Regeln und Schwellen bleiben bestehen: Fehlender
Anbieter beeinflusst weder 4xx noch Parser oder Kosten; fehlender
API-Beleg sperrt weiterhin Anbieter und die globalen Kostenregeln.

Belege in `test-acmg-pilot-metadata.R`:

- Zeile 46: Llama und Qwen über `acmg_api_backends()` und den echten
  HTTP-Backendpfad, mit allen vier Arten fehlender Anbieter. Zwölf
  Regelzeilen, fehlgeschlagene Anbieterregel, Generation-Hinweis und
  Antwort-ID; Gegenprobe mit wieder eingesetztem Anbieter.
- Zeilen 89 und 129: exakte API-/Mock-/Tokenfelder und fehlende IDs.
- Zeile 161: API-Pilot über den CLI-Treiber mit 90 gemockten Antworten,
  zwölf Regelzeilen und unverändertem Resume. Danach scheitern sowohl
  `main` als auch `robustness` benannt mit `AP1 pilot has not passed: …;
  no API calls made.`; Aufrufzahl und Store-Hash bleiben gleich. Die
  Robustheitsprüfung durchläuft zuvor die gültige synthetische
  INSAID-Vorprüfung.
- Zeile 209: vollständige synthetische Hauptplanzeilen mit
  API-artigen Metadaten und Pilotantworten ohne Anbieter; direkte
  Auswertung und `--evaluate-only` liefern identische Ergebnisse und
  Pilotregeln für alle drei Modelle. Fit und Renderer sind hier
  ausdrücklich Unit-Stubs; die an den Renderer übergebenen
  Pilot-Tabellen werden geprüft. Echte Fits und Berichte werden im
  unveränderten Abnahmelauf geprüft.

Die zusätzlichen Aufzeichnungsfälle verwenden `llama.json`,
`qwen.json` und `sol.json` aus dem Betreiberbestand; die Antworten
werden ausschließlich im Speicher verändert und über
`httr2::local_mocked_responses()` eingespielt. Der Test-Matcher prüft
URL und Modell und bricht bei unbekannten Anfragen ab. Er nutzt den
vorhandenen Unit-Serializer ohne Socket, keine Abnahme-Helfer.
Schlüssel sind ausschließlich synthetisch.

Die sieben Blöcke laufen im Paket immer mit synthetischen Antworten.
Die explizite Testoption `llmsa.test.ap1_recordings` fügt dieselben
Fälle mit den Betreiber-Aufzeichnungen hinzu; ein fehlender dort
angeforderter Datensatz führt zum Fehler. So bleibt der installierte
Pakettest gemäß PLAN-UPDATE E9 unabhängig von nicht ausgelieferten
Fixtures. Die Testoption wird vom Produktcode nicht gelesen.

### E32 — zusätzlich behoben im Produktcode

Ref: ADR-010 Nr. 6; ADR-006 Nr. 7.2; BL-66.

Die Anbieterbegründung nennt bei fehlendem API-Beleg nun ausdrücklich
`missing API evidence` sowie die Pflichtfelder `meta$id` und
`meta$model_snapshot` (`R/acmg.R:522`). Das gilt auch bei korrekt
angegebenem Anbieter. Leerraum im Anbieterfeld erhält den
Generation-Hinweis aus E31. Die strengere Sperre aus ADR-010 bleibt
unverändert.

Beleg: neuer Unit-Block ab Zeile 89 für alle drei Modelle, jeweils
fehlende ID oder Modellkennung, auch neben ähnlich benannten Feldern.
Anbieter und alle Kostenregeln scheitern; Parser und 4xx bleiben
bestanden. Der bisherige E26-Test bleibt ebenfalls grün. BL-66 kann
anhand dieser Belege vom Reviewer geschlossen werden.

### E33 — zusätzlich behoben im Produktcode

Ref: ADR-010 Nr. 3.4; ADR-006 Nr. 7.6; docs/01 §2 Nr. 4; BL-67.

`acmg_store_read()` (`R/acmg.R:622`) meldet für unbelegte Herkunft
nun `AP1 store backend/provenance is unverified`, die Anzahl der
betroffenen fehlerfreien Antworten, die fehlenden API-Belegfelder
`meta$id`/`meta$model_snapshot` und den nötigen neuen Store. Die
Zählung schließt Backendfehler und vollständig belegte Antworten aus.
Ein tatsächlicher Moduskonflikt behält seine bisherige Meldung.

Der Store wird weiterhin schreibgeschützt gelesen. Eine API-Kennung
heilt keine unbelegten Zeilen. Nach erstmaliger Erhebung mit fehlender
ID bleiben die bereits gespeicherten 90 Aufrufe erhalten; die
anschließende Herkunftsprüfung bricht weiterhin ab, bevor ein
Pilotbericht entsteht. Dieses Verhalten wird gemäß REVIEW E33 nicht
geändert; ein anderer Ablauf bedürfte einer gesonderten Entscheidung.

Belege: neue Unit-Blöcke ab Zeilen 255 und 284 zählen zwei unbelegte
Antworten neben einem Backendfehler sowie 30 unbelegte Llama-Antworten
unter 90 gespeicherten Aufrufen. Mock-Stores, echte Moduskonflikte,
identische SHA-256 nach abgelehntem Lesen und null weitere Aufrufe
beim erneuten CLI-Aufruf sind geprüft. BL-67 zur Prüfung an den
Reviewer.

### E26 — bestätigte Sperre; Quantil-Entkopplung bleibt offen

Ref: ADR-006 Nr. 7.4; ADR-010 Nr. 6; BL-64.

Die Sperre bei fehlendem API-Beleg bleibt erhalten und ist durch den
Bestandstest `test-acmg-rework.R:215` sowie die neuen E32-Fälle belegt.
Ihre Begründung ist mit E32 verbessert. Der Pilot-Quantiltyp wird
weiterhin aus `evaluation.kappa_bootstrap.quantile_type` gelesen.
Die Entkopplung wird in dieser Fehlerkorrektur vertagt: Der
freigegebene unveränderte Plan trägt Typ 7; Rechenverfahren, Planfelder
und Schwellen werden hier nicht geändert. BL-64 bleibt beim Reviewer
zur Fortschreibung.

### E28 — OUT-OF-TERRITORY [INFRA]

Ref: docs/03 A.7; M2-BUILD-INFRA-02; BL-63.

Der Textspiegel des eingefrorenen Provider-Logging-Dokuments belegt
weiterhin keine anbieterspezifischen Regeln. Tatsächlicher Output
in `/tmp/llmsa-m2-r3/infra-evidence.log`:

```text
E28: reference/quellen/text/anbieter_2026-10-22/openrouter/Provider_Logging.html.txt: CoreWeave matches = 0; DeepInfra matches = 0
```

Betreiber: datierte spezifische Belege liefern. Reviewer: Übernahme
per Anker/ADR. Keine erfundene Policy und kein Builder-Eingriff in
Quellen, Anker oder BACKLOG.

### E29 — OUT-OF-TERRITORY [INFRA]

Ref: BL-56; PLAN-REVIEW E14. Aktueller Log-Beleg:

```text
E29: orchestrator/lib/r-tests.R: NOT_CRAN references = 0
E29: orchestrator/state/M2/gate-tests.log:107: • On CRAN (1): 'test-report.R:5:3'
```

Der direkte Builder-Lauf führt den Bestandsbericht mit `NOT_CRAN=true`
aus. Im installierten Paketcheck bleibt dessen bisheriger CRAN-Skip
bestehen. Die dauerhafte Gate-Konfiguration ist Betreiberaufgabe.

### E30 — OUT-OF-TERRITORY [INFRA]

Ref: BL-48; docs/gates-auswahl.md:87.

Die Zuordnungszeile nennt weiterhin `K-M2-1 bis K-M2-6`; K-M2-7 fehlt.
Die vollständige Zeile ist in `infra-evidence.log` protokolliert.
Betreiber: Zuordnung ergänzen. Das trace-Gate der Runde 2 ist grün;
Gate-Auswahl und Zuordnungsdokument werden vom Builder nicht geändert.

### Bereits angenommene Befunde aus Runde 1

| ID | Antwort in Runde 3 |
| --- | --- |
| E21 / QA-M2-001 | Erledigt laut REVIEW Runde 2; unveränderter QA-Test und Bestandsregression grün. Nur beobachtete Modell-/Blockkombinationen bleiben im Bericht. |
| E22 / QA-M2-002 | Erledigt; unveränderter QA-Test grün. Fehlende Anbieter lösen weiter die Wiederholungstagsdiagnose aus. E31 behebt separat den Pilotpfad. |
| E23 / QA-M2-003 | Erledigt; unveränderte Store-/QA-Tests grün. E33 verbessert ausschließlich die Diagnose des unveränderten Abbruchs; exakte Belegfelder nach E31. |
| E24 / QA-M2-004 | Erledigt; unveränderte QA-/Unit-Tests grün, einschließlich fehlender Hauptplanitems und PB-Referenzen. |
| E25 / QA-M2-005 | Erledigt; unveränderter Fuzz-Test grün. Klassen- und PB-Schlüsselprüfung bleiben erhalten. |
| E27 | Erledigt; unveränderter Unit-Test rendert die Anbieter-/Fingerprint-Zählungen im echten HTML-Bericht. |

## Ausgeführte Prüfungen

Logs und temporäre Paketkopien liegen unter `/tmp/llmsa-m2-r3/`.
Kein Lauf schreibt Gate-Fakten. Keine Git-Kommandos, Installation,
realen API-Aufrufe oder realen Schlüssel. Die vorhandenen Aufzeichnungen
stimmen weiterhin mit ANK-94 überein:

```text
Operator recordings: 3/3 match ANK-94 SHA-256.
```

### Endgültige Regressionstests gegen den alten Produktstand (erwartet Exit 1)

Die temporäre Paketkopie `regression-before` enthält die endgültigen
neuen Tests und die vor dieser Phase gesicherte `R/acmg.R`. Der
Arbeitsbaum wird nicht zurückgesetzt. In der Kopie ausgeführt:

```bash
Rscript --vanilla -e 'options(llmsa.test.ap1_recordings = "/mnt/c/Users/Danie/dev/Llmsa/llmsa/tests/fixtures/api"); x <- testthat::test_dir("tests/testthat", filter = "acmg-pilot-metadata", load_package = "source", reporter = "silent", stop_on_failure = FALSE); d <- as.data.frame(x); print(d[, c("test", "passed", "failed", "error", "skipped")], row.names = FALSE); cat(sprintf("Regression blocks: %d; failed blocks: %d; error blocks: %d; skips: %d\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); for (block in x) for (result in block$results) if (inherits(result, "expectation_error")) cat("Error: ", result$message, "\n", sep = ""); quit(status = as.integer(any(d$failed > 0 | d$error)))'
```

Tatsächlicher Auszug aus `regression-final-before.log`:

```text
Regression blocks: 7; failed blocks: 4; error blocks: 5; skips: 0
Error: Error in `vapply(responses, function(x) x$provider %||% "", "")`: values must be type 'character',
 but FUN(X[[1]]) result is type 'list'
Error: Error: AP1 mixed mock/API provenance is not permitted.
Error: Error: AP1 store backend/provenance does not match --backend; store unchanged.
```

Fehlschlag und Fehler können denselben Block betreffen; insgesamt
sind alle sieben Blöcke rot. Das belegt die Regressionserkennung,
keinen Mutationsscore und keinen Äquivalenz-Claim.

### Gezielte Unit-Prüfung einschließlich Aufzeichnungsvarianten (Exit 0)

```bash
Rscript --vanilla -e 'options(llmsa.test.ap1_recordings = normalizePath("tests/fixtures/api")); testthat::test_dir("tests/testthat", filter = "acmg-pilot-metadata", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Tatsächlicher Schluss aus `targeted-after.log`:

```text
✔ |        370 | acmg-pilot-metadata [14.2s]
Duration: 14.2 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 370 ]
```

### Vollständiger Unit-/QA-Lauf (Exit 0)

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

Tatsächliche Schlusszeilen aus `unit-qa.log`:

```text
✔ |        222 | acmg-pilot-metadata [6.8s]
✔ |        194 | acmg-rework [7.8s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 1096 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 80 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 41.65; exit: 0
```

Der einzige Skip ist der unveränderte ellmer-Fehlerpfad, weil ellmer
installiert ist. Alle fünf QA-Befunde bleiben behoben. Die neuen
Blöcke laufen hier vollständig mit synthetischen HTTP-Antworten;
die zusätzlichen Aufzeichnungsfälle stehen im gezielten Lauf oben.

### Paketbau und installierter Paketcheck (je Exit 0)

Positivliste nach `package-check/src`: DESCRIPTION, NAMESPACE,
LICENSE, NEWS, README, .Rbuildignore, R, man, data, inst, vignettes,
tests/testthat.R und tests/testthat. Keine Schlüssel, geschützten
Quellen, Betreiber-Fixtures oder Harness-Dateien. Im übergeordneten
Verzeichnis ausgeführt:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Incoming-Remote entspricht dem unveränderten Betreiber-Prüfskript
`orchestrator/lib/r-check.sh`. Das Skript selbst wird wegen seiner
Git-Kommandos nicht ausgeführt. Tatsächlicher Output aus `build.log`,
`check.log` und `llmsa.Rcheck/tests/testthat.Rout`:

```text
* building ‘llmsa_0.1.0.tar.gz’
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 71.84; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 1092 ]
```

**M2-R3-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Die einzige NOTE
ist in `package-check/check.log:29–31` belegt:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Uhrzeitprüfung bleibt aktiv. Keine ERRORs oder WARNINGs. Die
beiden installierten Skips sind unverändert der generische Bericht
(On CRAN) und der ellmer-Fehlerpfad. Die neuen Regressionstests laufen
auch im installierten Paket.

### Betroffene unveränderte Abnahme K-M2-4, K-M2-6, K-M2-7 (Exit 1: Infrastruktur)

```bash
/usr/bin/time -f 'Targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[467]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Tatsächlicher Output aus `acceptance.log`:

```text
✖ | 6       14 | m2-4-backends [1.1s]
✔ |        374 | m2-6-evaluate [219.5s]
✖ | 1      353 | m2-7-robustness-pilot [93.7s]
Duration: 314.6 s
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 741 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
Targeted acceptance elapsed seconds: 316.37; exit: 1
```

**M2-R3-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].** Ref:
K-M2-4; K-M2-7 Systemspalte; `tests/acceptance/setup-m2.R:771`.
Der unveränderte HTTP-Replay-Helfer öffnet einen lokalen Socket,
den die Builder-Sandbox verweigert. Log-Belege in `acceptance.log`
ab Zeilen 11 und 140, mit demselben Stacktrace:

```text
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Die sieben negativen Erwartungen betreffen sechs Testblöcke: fünf
in K-M2-4 und die Systemspalte in K-M2-7. Der JSON-Parsefehler bei
`stored$meta` und die beiden Erwartungen an die zweite Antwort nach
HTTP 4xx sind Folgefehler des fehlgeschlagenen Replays. Die
fachliche PB-Auswertung besteht; K-M2-6 ist vollständig grün,
einschließlich echter Fits, Rückfall, INSAID-Join und HTML-Berichte.
Die beim Rendering ausgegebene System-Bus-Meldung verhindert den
Berichtsbau nicht und erzeugt keine testthat-Warnung.

Die gleiche Sandbox-Beschränkung ist aus BUILD und REWORK Runde 2
bekannt. Im regulären Gate der Runde 2 bestanden K-M2-4 und K-M2-7
mit 89 beziehungsweise 375 Erwartungen. Dieser historische Beleg
ersetzt keinen neuen Gate-Lauf: Der Orchestrator muss die unveränderte
Abnahme erneut im Gate-Umfeld ausführen. Keine Änderung an Replay,
Berechtigungen, Tests oder Produktcode zur Umgehung der Infrastruktur.

Die übrigen M2-Abnahmedateien wurden in dieser gezielten REWORK-Prüfung
nicht erneut gestartet. Ihr letzter Gate-Beleg stammt aus Runde 2.
M0-Prüfwege mit Git-Kommandos bleiben dem Orchestrator vorbehalten.

## Integrität und Übergabe

Nach den Produkt-/Teständerungen und den Handoff-/PROGRESS-Einträgen
wurde ausgeführt (Exit 0):

```bash
python3 /tmp/llmsa-m2-r3/integrity.py
```

Tatsächlicher Output, `integrity.log`:

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

Die SHA-256-Inventur umfasst 204 vor der Phase erfasste Dateien und
neue Dateien in den erfassten Pfaden. Sie ersetzt nicht das
Territoriums-Gate. Git-Metadaten und Schlüsseldateien werden nicht
gelesen. R/fit.R, R/grr.R, NAMESPACE, Plan, Golden-Dateien,
Abnahmetests, QA-Tests, Betreiber-Fixtures, Reviewer-Handoffs und
Gate-Fakten sind byte-identisch. Die geprüfte Paketkopie enthält den
endgültigen Produkt- und Teststand.

Keine MUT-EQUIV-Claims und keine Approvals. Kein offener
`[QA-PENDING]`-Befund im aktuellen Review; vorhandene QA-Tests grün.
E31, E32 und E33 werden mit ausgeführten Nachweisen zur Prüfung
übergeben. E26/BL-64 bleibt vertagt; E28 bis E30 und die lokalen
Socket-/Uhrzeitbeobachtungen bleiben OUT-OF-TERRITORY [INFRA].
BACKLOG-Pflege liegt beim Reviewer, Infrastruktur beim Betreiber.
Territoriumsprüfung, Phasen-Commit und neue Gates folgen ausschließlich
durch den Orchestrator. Diese Datei erteilt keine Abnahme.
