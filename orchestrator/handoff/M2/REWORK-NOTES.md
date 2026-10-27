# REWORK-NOTES — M2, Runde 2

Rolle: Builder · Phase: REWORK · Stand: 27.10.2026.
Grundlage: REVIEW und verdict-code der Runde 1, CRITERIA K-M2-1 bis
K-M2-7/ACC-1 bis ACC-25 sowie die angenommene ADR-010. AGENTS,
IMPLEMENTATION-RULES, PROTOCOLS, Handoff-Schema, PROGRESS,
Fachspezifikationen, betroffene Abnahmetests, QA und das rote
`orchestrator/state/M2/gate-tests.log` wurden gelesen.
`ARBITER.md` liegt für M2 nicht vor; LESSONS enthält noch keine Lehre.

Die Produktkorrekturen betreffen ausschließlich `R/acmg.R`.
`tests/testthat/test-acmg-rework.R` ergänzt neun Unit-Blöcke.
Bestehende Tests, QA-/Abnahmetests, Fixtures, Anker, Schwellen,
Plan-YAML und Gates werden nicht geändert. Der gelesene Gate-Stand
bleibt Runde 1: `result: fail`, nur `tests: fail`, alle übrigen Gates
`pass`. Kein Gate hat Status `error`. Die nachstehenden Ausführungen
sind Builder-Prüfungen; neue Gate-Fakten erzeugt nur der Orchestrator.

## Antworten auf die Befunde

### E21 / QA-M2-001 — behoben im Produktcode

Ref: Gate tests; ADR-006 Nr. 7.8; ADR-010 Nr. 1.
`R/acmg.R:570` (`acmg_repeat_day()`) gibt nur tatsächlich beobachtete
Modell-/Blockkombinationen aus. Ein Einzelmodellbericht enthält damit
ausschließlich dessen eigene Diagnosen; auch bei einem fehlenden Block
entsteht keine erfundene FALSE-/NA-Zeile. Die Aufruf- und Fehlerzählung
stammt weiter aus den übergebenen Hauptplanzeilen.

Belege: unverändertes QA-M2-001 grün; neuer Unit-Block
`tests/testthat/test-acmg-rework.R:3` prüft alle drei Berichte mit
gezielt unterschiedlichen Anbieter-/Modellwechseln und Fehleranteilen
sowie eine nur teilweise vorhandene Blockmenge. Output des gemeinsamen
Unit-/QA-Laufs siehe unten.

### E22 / QA-M2-002 — behoben im Produktcode

Ref: Gate tests; ADR-006 Nr. 7.2/7.8; ADR-010 Nr. 2.
`acmg_meta_text()` (`R/acmg.R:449`) erhält fehlende Textfelder als NA,
statt sie mit `unlist()` zu verlieren. `acmg_repeat_day()` zählt bei
angefordertem Anbieter auch fehlende, leere und reine Leerraumwerte
einer fehlerfreien Antwort als Abweichung. Ein fehlender Anbieter einer
Backendfehlerzeile löst diesen zusätzlichen Alarm nicht aus; bei Sol
ohne angeforderten Anbieter ebenfalls nicht.

Belege: unverändertes QA-M2-002 grün; Unit-Block
`tests/testthat/test-acmg-rework.R:44` prüft alle Planmodelle mit
teilweise und vollständig fehlenden Angaben, einschließlich NULL,
Leerstring, Leerraum und JSON-null sowie des Backendfehlerfalls.

### E23 / QA-M2-003 — behoben im Produktcode

Ref: Gate tests; ADR-006 Nr. 9; PLAN-UPDATE E3; ADR-010 Nr. 3.
`R/acmg.R:454` (`acmg_provenance()`) leitet Herkunft aus fehlerfreien
Zeilen ab. Ein API-Marker ersetzt keinen fehlenden Zeilenbeleg.
Mock-Belege bzw. ein Mock-Marker erhalten `synthetic` auch neben
unbelegten Zeilen. `api` verlangt vollständige Belege der fehlerfreien
Zeilen; ein markierter Store nur mit Fehlerzeilen bleibt möglich.
Ohne Marker begründen Fehlerzeilen allein keine Herkunft.
Explizite Metadaten, die einem persistierten Modus widersprechen,
bleiben ein benannter Fehler, auch im bestehenden Unit-Fall einer
Fehlerzeile mit API-Metadaten im Mock-Store. Die bisherigen
Store-Konfliktprüfungen bleiben damit wirksam.

`acmg_store_read()` bleibt unverändert: Es liest SQLite schreibgeschützt
und verwirft die nun korrekt erkannte unbelegte API-Herkunft mit
`AP1 store backend/provenance does not match --backend; store unchanged.`

Belege: unverändertes QA-M2-003 und alle bisherigen Store-Unit-Tests
grün. Neue Blöcke `tests/testthat/test-acmg-rework.R:63` und `:96`
prüfen die Kombinationen aus Marker, belegter/unbelegter Zeile und
Backendfehler sowie identische SHA-256 vor/nach abgelehntem Lesen.

### E24 / QA-M2-004 — behoben im Produktcode

Ref: Gate tests; K-M2-6; ADR-006 Nr. 8.1/11; ADR-010 Nr. 4.
`acmg_evaluate()` übergibt `acmg_modal_table()` alle eingefrorenen
Item-IDs (`R/acmg.R:799`, `:1025`). Jedes Modell erhält genau eine
Modalzeile je Planitem. Ohne Hauptplanaufrufe gilt `modal = NA`,
`has_modal = FALSE`; das Item zählt in `n_no_modal` und
`excluded_no_modal`. Itemmerkmale stammen aus den übrigen Zeilen von
`runs`, einschließlich PB-Zeilen. Fehlt das Item dort ganz, bleiben
die Merkmale NA. Widersprüche über die Zeilen eines Items führen zum
benannten Fehler; die IDs werden nicht zum Nachladen von Referenzen
aus der Paketdatei verwendet.

Die sekundäre PB-Trefferquote in `acmg_robustness()` (`R/acmg.R:870`)
nutzt die Referenzspalte der PB-Zeilen. Vorhandene NA-Referenzen werden
nicht durch Modalreferenzen ersetzt. Der Stabilitätsvergleich bleibt
gegen die Modalantwort des Hauptplans. Ein unvollständiger Hauptplan
erhält weiter ausschließlich Kriterienbänder `not assessed` und kein
Gesamtverdikt.

Belege: unverändertes QA-M2-004 grün. Der neue Unit-Block
`tests/testthat/test-acmg-rework.R:119` prüft fehlende Items je Modell,
ein nur in PB-Zeilen vorhandenes Item, vollständig fehlende Merkmale,
die Bilanz über alle Planitems, unveränderte Referenznenner, Konflikte
und Unabhängigkeit von der Reihenfolge der Metadatenzeilen.

### E25 / QA-M2-005 — behoben im Produktcode

Ref: Gate tests; ADR-005 Nr. 1; ADR-006 Nr. 8.2; ADR-010 Nr. 5.
`R/acmg.R:1000` (`acmg_evaluate()`) prüft Antwort- und Referenzklassen
über Hauptplan- und PB-Zeilen vor dem ersten Fit. Nicht normalisierte
oder unbekannte Klassen lösen denselben benannten Fehler aus:
`AP1 runs contain unknown response or reference classes.`

`acmg_robustness()` verlangt zusätzlich zu den bisherigen Zählungen
geplante Replikate, Block 1 und eindeutige `run_key`. Ein falscher,
gebrochener oder fehlender Schlüsselwert verhindert die Bewertung;
`complete = FALSE`, `effects = NULL`, `band = "not assessed"` und eine
Begründung werden zurückgegeben. Die vollständigen Laufspalten sind
am Eingang von `acmg_evaluate()` Pflicht. Der interne Rechenhelfer
unterstützt weiterhin reduzierte Item-/Prompttabellen ohne konstante
Designspalten, wie in den bestehenden Unit-Tests und im QA-Wortlaut
„sofern die Spalten … vorhanden sind“. Bei einer solchen internen
Tabelle darf die Referenz weiterhin aus `modal` kommen, wenn überhaupt
keine Referenzspalte übergeben wurde. Im Auswertungspfad sind die
Spalten vorhanden und die Prüfungen verbindlich; NA-Werte werden
nicht ergänzt. Kein Bestandstest wurde dafür verändert.

Belege: unverändertes QA-M2-005 grün; neue Blöcke
`tests/testthat/test-acmg-rework.R:166` und `:180` prüfen sämtliche
unzulässigen Klassen getrennt für Antwort/Referenz sowie falsche,
NA- und doppelte Designschlüssel und fremde Item-/Prompt-IDs.

### E26 — bestätigte Regel; keine Produktänderung

Ref: ADR-010 Nr. 6; BL-64. Die strengere Sperre bei einer
fehlerfreien Pilotantwort ohne API-ID bleibt wie vom Reviewer
bestätigt: Anbieterregel des Modells und Kostenregeln aller Modelle
scheitern. Der neue Unit-Block `tests/testthat/test-acmg-rework.R:215`
belegt dies für alle drei Modelle, bei weiterhin bestandenen Parser-
und 4xx-Regeln. Die Kopplung des Pilot-Quantiltyps an das
Bootstrap-Feld bleibt unverändert und als Restpunkt BL-64 offen.
Kein Schwellenwert und keine Pilotregel wurde umgedeutet.

### E27 — zusätzlich behoben im Produktcode

Ref: `docs/03` A.7; BL-65. `acmg_assessment()` (`R/acmg.R:923`)
nennt unter „Model and routing“ die Anzahl fehlerfreier Antworten
ohne Anbieter und ohne `system_fingerprint`, jeweils mit Nenner.
Vorhandene Werte bleiben sichtbar; Backendfehler zählen nicht in
diese Fehlstellenzählung.

Der neue Unit-Block `tests/testthat/test-acmg-rework.R:232` rendert
echte HTML-Berichte und vergleicht die ausgegebenen Zählungen.
Der erste Lauf dieses neuen Tests scheiterte allein am HTML-Zeilenumbruch
der geprüften Wortfolge. Der Test normalisiert nun HTML-Leerraum;
der erwartete Text und sämtliche Zahlen bleiben identisch.
Im abschließenden Unit-Lauf bestehen alle 194 Erwartungen der neun
neuen Blöcke. BL-65 kann der Reviewer anhand dieses Nachweises schließen.

### E28 — OUT-OF-TERRITORY [INFRA]

Ref: `docs/03` A.7; M2-BUILD-INFRA-02; BL-63.
Der eingefrorene `Provider_Logging.html` belegt keine spezifischen
Logging-Regeln von CoreWeave oder DeepInfra. Die erneute reine
Textprüfung ergibt in `/tmp/llmsa-m2-r2/infra-evidence.log`:

```text
E28: Provider_Logging snapshot: CoreWeave matches = 0; DeepInfra matches = 0
```

Das bestätigt REVIEW, Nachprüfung 8. Betreiber: datierte spezifische
Belege liefern; Reviewer: Übernahme per Anker/ADR. Plan und Berichte
benennen weiterhin die Quellenlücke. Keine erfundene Policy und keine
Änderung an Quellen, Ankern oder BACKLOG.

### E29 — OUT-OF-TERRITORY [INFRA]

Ref: BL-56; PLAN-REVIEW E14. Log-Beleg:

```text
orchestrator/state/M2/gate-tests.log:92:
• On CRAN (1): 'test-report.R:5:3'
orchestrator/lib/r-tests.R: NOT_CRAN references = 0
```

Der direkte Builder-Unit-Lauf setzt `NOT_CRAN=true` und führt damit
auch den generischen Bestandsbericht tatsächlich aus. Der unveränderte
Paketcheck behält seinen CRAN-Skip; die neuen AP1-Renderingtests laufen
dort ebenfalls. Eine dauerhafte Gate-Konfiguration bleibt Betreiberarbeit.

### E30 — OUT-OF-TERRITORY [INFRA]

Ref: BL-48; PLAN-REVIEW E15; `docs/gates-auswahl.md:87`.
Die Zuordnung enthält weiterhin `K-M2-1 bis K-M2-6`; K-M2-7 fehlt.
Der exakte Zeilenauszug steht in
`/tmp/llmsa-m2-r2/infra-evidence.log`; REVIEW E30 bestätigt denselben
Stand. Die Gate-Auswahl/-Zuordnung wird vom Builder nicht geändert.
Betreiber: K-M2-7 ergänzen. Das trace-Gate war bereits grün.

## Ausgeführte Prüfungen

Alle Befehle liefen in dieser REWORK-Phase ohne Git, Installation,
API-Zugriff oder reale Schlüssel. Testdaten sind ausdrücklich
synthetisch oder unveränderte vorhandene Ressourcen.

### Ausgangsfehler: unveränderte QA-Tests (Exit 1)

```bash
Rscript --vanilla orchestrator/lib/r-tests.R tests/e2e tests/fuzz
```

Vor der Produktänderung, Log `/tmp/llmsa-m2-r2/qa-before.log`:

```text
[ FAIL 8 | WARN 0 | SKIP 0 | PASS 2 ]
[ FAIL 5 | WARN 0 | SKIP 0 | PASS 0 ]
r-tests: fail — 5 Tests in tests/e2e, tests/fuzz; 5 fehlgeschlagen, 0 Fehler, 0 übersprungen
```

Dies reproduziert alle fünf Ursachen des roten Tests-Gates aus Runde 1.

### Abschließender Unit-/QA-Lauf (Exit 0)

```bash
NOT_CRAN=true /usr/bin/time -f 'Unit and QA elapsed seconds: %e; exit: %x' \
  Rscript --vanilla orchestrator/lib/r-tests.R tests/testthat tests/e2e tests/fuzz
```

Log `/tmp/llmsa-m2-r2/unit-qa.log`, tatsächliche Schlusszeilen je Ordner:

```text
✔ |        194 | acmg-rework [7.5s]
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 874 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
r-tests: pass — 73 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
Unit and QA elapsed seconds: 33.90; exit: 0
```

Der einzige Skip ist der unveränderte ellmer-Fehlerpfad
`test-backends.R:32:3`, weil ellmer installiert ist. Die neun statt
zehn QA-E2E-Erwartungen ergeben sich aus der vorhandenen Bedingung in
QA-M2-001: Im Sol-Bericht gibt es jetzt keine fremde Llama-Zeile, daher
entfällt die bedingte Prüfung ihrer Auslöser. Der QA-Test ist byte-identisch.

### Neue Regressionstests gegen den alten Produktstand (erwartet Exit 1)

Eine separate Paketkopie unter `/tmp/llmsa-m2-r2/regression-before`
enthält dieselben neuen Unit-Tests, aber die vor REWORK gesicherte
`R/acmg.R`. Ausgeführt in dieser Kopie:

```bash
NOT_CRAN=true Rscript --vanilla -e 'x <- testthat::test_dir("tests/testthat", filter = "acmg-rework", load_package = "source", reporter = "silent", stop_on_failure = FALSE); d <- as.data.frame(x); print(d[, c("test", "passed", "failed", "error", "skipped")], row.names = FALSE); cat(sprintf("Baseline regression blocks: %d; failed: %d; errors: %d; skipped: %d\n", nrow(d), sum(d$failed > 0), sum(d$error), sum(d$skipped))); quit(status = as.integer(any(d$failed > 0 | d$error)))'
```

Log `/tmp/llmsa-m2-r2/regression-before.log`:

```text
Baseline regression blocks: 9; failed: 7; errors: 4; skipped: 0
```

Fehlschlag und Fehler können denselben Block betreffen: Insgesamt sind
acht Blöcke rot. Der neunte (E26) besteht mit 18 Erwartungen auch im
alten Stand, weil er die bestätigte bestehende Pilotregel festhält.
Der aktuelle Quellbaum wurde hierfür nicht zurückgesetzt. Das ist ein
Nachweis der Regressionserkennung, kein Mutationsscore und kein Claim.

### Paketbau und installierter Paketcheck (Exit 0)

Explizite Kopierliste nach `/tmp/llmsa-m2-r2/package-check/src`:
DESCRIPTION, NAMESPACE, LICENSE, NEWS, README, .Rbuildignore, R, man,
data, inst, vignettes, tests/testthat.R und tests/testthat. Keine
Schlüssel-, Harness- oder geschützten Quelldateien. Ausgeführt im
übergeordneten temporären Verzeichnis:

```bash
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false \
  /usr/bin/time -f 'Package check elapsed seconds: %e; exit: %x' \
  R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Die Incoming-Einstellung entspricht dem gelesenen
`orchestrator/lib/r-check.sh`. Das Skript selbst wurde wegen seiner
Git-Kommandos nicht ausgeführt. Logs: `package-check/build.log`,
`package-check/check.log` und `llmsa.Rcheck/tests/testthat.Rout`
unter `/tmp/llmsa-m2-r2/`.

```text
* building ‘llmsa_0.1.0.tar.gz’
* checking R code for possible problems ... OK
* DONE
Status: 1 NOTE
Package check elapsed seconds: 66.19; exit: 0
[ FAIL 0 | WARN 0 | SKIP 2 | PASS 870 ]
```

Die unveränderten installierten Skips sind `On CRAN` im generischen
Berichtstest und der ellmer-Fehlerpfad. Die einzige NOTE lautet:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

**OUT-OF-TERRITORY [INFRA], M2-R2-INFRA-CLOCK:** Das Sandbox-Umfeld
kann die Uhrzeit nicht extern verifizieren; keine Produktursache,
kein ERROR/WARNING. Die Uhrzeitprüfung wurde nicht abgeschaltet.

### Betroffene unveränderte Abnahmetests K-M2-6/K-M2-7 (Exit 1: Sandbox-Infrastruktur)

```bash
/usr/bin/time -f 'M2 targeted acceptance elapsed seconds: %e; exit: %x' \
  Rscript --vanilla -e 'grDevices::pdf(tempfile(fileext = ".pdf")); testthat::test_dir("tests/acceptance", filter = "m2-[67]-", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

Log `/tmp/llmsa-m2-r2/acceptance.log`, tatsächlicher Output:

```text
✔ |        374 | m2-6-evaluate [216.3s]
✖ | 1      353 | m2-7-robustness-pilot [94.1s]
Duration: 310.4 s
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 727 ]
Error:
! Test failures.
Execution halted
Command exited with non-zero status 1
M2 targeted acceptance elapsed seconds: 312.17; exit: 1
```

**M2-R2-INFRA-SOCKET — OUT-OF-TERRITORY [INFRA].**
Ref: K-M2-7 Systemspalte;
`tests/acceptance/test-m2-7-robustness-pilot.R:175` und
`tests/acceptance/setup-m2.R:771`. Der einzige Fehler entsteht im
unveränderten Reviewer-Replay-Helfer:

```text
Error: System failure for: socket() (Operation not permitted)
httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:771:5
curl::curl_echo(handle, progress = FALSE)
httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
```

Dies ist die bereits aus BUILD bekannte Beschränkung der Builder-
Sandbox. Im regulären Gate von Runde 1 war derselbe Pfad grün
(`gate-tests.log`: K-M2-7, 375 Erwartungen; REVIEW erklärt
M2-BUILD-INFRA-01 dort für erledigt). Der neue lokale Befund erklärt
keine Produktabweichung und ändert diesen historischen Gate-Nachweis
nicht. Der Orchestrator muss den unveränderten Test im Gate-Umfeld
erneut ausführen. Weder der Replay-Helfer noch Berechtigungen oder
Produktcode wurden zur Umgehung geändert.

K-M2-6 besteht vollständig, einschließlich Gegenrechnung, Bootstrap,
INSAID-Join, erzwungenem Rückfall, tatsächlichen CLI-Läufen und Berichten.
Die fachlichen PB-Auswertungen von K-M2-7 bestehen ebenfalls. Die übrigen
M2-Abnahmedateien wurden in dieser gezielten REWORK-Prüfung nicht erneut
gestartet; ihr grüner Stand stammt aus dem gelesenen Gate der Runde 1.
Der vollständige M0/M2-Gatelauf bleibt dem Orchestrator vorbehalten,
auch weil M0-Prüfwege Git-Kommandos aufrufen.

## Integrität und Übergabe

Nach dem PROGRESS-Nachtrag wurde ausgeführt (Exit 0):

```bash
python3 /tmp/llmsa-m2-r2/integrity.py
```

Tatsächlicher Output, `/tmp/llmsa-m2-r2/integrity.log`:

```text
Inventory: 2 changed baseline files, 2 new files; all assigned Builder paths; no removed files
Preserved baseline: 154/154 files byte-identical
Existing tests and fixtures: 38/38 byte-identical
R source and new test comments: ASCII
Workspace artifacts: no Rplots.pdf, package archive, Rcheck directory or SQLite store
Gate facts: still round 1, result fail; no Builder verdict or state write
```

Die Inventur vergleicht die vor REWORK erfassten 156 Dateien per
SHA-256, ohne Git-Metadaten oder Schlüsseldateien zu lesen. Geändert
sind ausschließlich `R/acmg.R` und `PROGRESS.md`; neu sind die
Unit-Datei und diese zugewiesene Handoff-Datei. Sie ersetzt nicht die
Territoriumsprüfung des Orchestrators.

Es gibt keine MUT-EQUIV-Claims: `R/fit.R` und `R/grr.R`
sind unverändert, und der gelesene mutgate-Befund ist
`pass (kein geänderter Mutations-Scope)`. Kein eigener Claim wurde
approvt, kein Gate-Verdikt geschrieben. Im aktuellen Review gibt es
keinen offenen `[QA-PENDING]`-Befund; die vorhandenen QA-Tests liefen
unverändert grün.

Der Builder übergibt E21 bis E25 sowie E27 mit ausgeführten Belegen
zur Prüfung. E26 bleibt gemäß ADR-010, E28 bis E30 sowie die beiden
lokalen Infrastrukturbeobachtungen bleiben in der Zuständigkeit des
Betreibers/Reviewers. Phasen-Commit und vollständige Gates folgen
erst durch den Orchestrator; diese Datei erteilt keine Abnahme.
