# REVIEW — M3d, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 07.11.2026 · Gegenstand: Diff seit `plan/M3d` (`a4115ae`) bis `4fc5539` (Builder `638feaa`, QA `3a77744`, Gates `414e1a9` und `4fc5539`) · Gate-Fakten: `orchestrator/state/M3d/gates.json` (Runde 1, nach QA, 07.11.2026 09:07). Es gibt keine `ARBITER.md`, kein `PLAN-UPDATE.md`, keine `REVIEW-INPUT.md` und kein `MUT-EQUIV.json`. Keine Git-Kommandos.

## Ergebnis

**Verdict REWORK, blocking leer.**

- **Gates:** Rot ist nur `tests`: 3 Blöcke mit 10 fehlgeschlagenen Erwartungen, alle in `test-m1d-7-findings.R:145` und `test-m1d-8-robustness-wording.R:96`, `:117` (`gate-tests.log` Z. 1784–1866, Z. 2618).
  - Alle übrigen Gates sind grün: deps, lint (`R CMD check --as-cran`, „Status: OK“), trace, territory, mutgate (80,25 bei verlangten 80), golden-adr, mutfull (in M3d nicht fällig).
  - Jede rote Erwartung zeigt nur das in M3d zugelassene Attribut `seed` (ADR-053 Nr. 14.2) gegenüber done/M1c bzw. die Codezeile `attr(out, "seed") <- seed` in `R/grr.R`.
- **Ursache im Reviewer-Territorium:** ADR-053 Nr. 14.5.4 sagt: „Bis dahin sind genau diese drei Tests rot. Das ist kein Befund gegen den Builder.“ Damit ist der rote Gate [INFRA] und für den Builder nonblocking (E11).
- **In dieser Phase erledigt:** Die drei Stellen sind nach ADR-053 Nr. 14.5 zurückgeführt und ohne Git geprüft (Prüflauf 3).
  - Auf dem Paket von Runde 1 sind sie grün.
  - Neun verfälschte Varianten machen sie am vorgesehenen Test rot. Eine reine roxygen-Änderung in done/M1d bleibt erlaubt und grün.
- **Warum nicht PASS:** Der Prüfauftrag erlaubt PASS nur bei `gates.result = pass`; `gates.json` Runde 1 meldet `fail`. Deshalb REWORK ohne blocking-Befund. Runde 2 bestätigt die Gates.
- **Arbeit des Builders:**
  - Spec- und Vertragstreue zu K-M3d-1 bis K-M3d-6 und ADR-053 Nr. 1 bis 18 sind erfüllt. Die sechs M3d-Abnahmetests sind im Gate grün mit 706, 13, 194, 513, 89 und 52 Erwartungen (`gate-tests.log` Z. 2244–2340).
  - `R/fit.R` ist unverändert. `R/grr.R` und `R/robustness.R` ändern sich nur um die drei Seed-Zuweisungen und roxygen-Zeilen (Nr. 14.3).
  - Kein neuer Export, kein neuer Import, keine Golden- oder Ankeränderung.
- **Befunde:** Sechs minor-Befunde (E12 bis E17), alle nonblocking. Sie stehen im Backlog unter BL-139 bis BL-143; E11 ist BL-144 (erledigt). Nachgeführt sind BL-17, BL-18, BL-60, BL-123, BL-128, BL-130, BL-135 und BL-137.
- **Weitere Dateien dieser Phase:** `CRITERIA.json` führt den Status von ACC-17 nach; die sechs Kriterien sind unverändert (Rundlauf über `jsonlite` vorher bytegleich). Kein `MUT-EQUIV-APPROVED.json`, weil es keinen Antrag gibt.

### Für REWORK Runde 2 (Builder)

- Es gibt keinen Pflichtpunkt und keine verlangte Produktänderung. E12 bis E17 sind vertagt (Backlog: nach dem 26.11.2026 oder beim nächsten Eingriff in die Datei).
- Empfehlung: `R/`, `man/` und `inst/` nicht ändern.
  - Jede Änderung unter `R/` lässt mutgate alle seit `plan/M3d` geänderten Dateien erneut ganz mutieren. In Runde 1 dauerte das rund 19 Stunden.
  - Der Lauf muss wieder 80 erreichen. Der Abstand in Runde 1 betrug 0,25 Punkte, also etwa drei Mutanten.
- `REWORK-NOTES.md` beantwortet E11 bis E17 Punkt für Punkt.

### An den Betreiber

1. **Gate Runde 2:** `tests` sollte grün werden.
   - Die angepassten Tests lesen über `acc_git()` vier Blobs: `git cat-file blob done/M1c:R/fit.R`, `done/M1c:R/grr.R`, `done/M1d:R/fit.R` und `done/M1d:R/grr.R`. done/M1c wird wie bisher gegen ANK-34 geprüft.
   - Die Tags done/M1c und done/M1d müssen bestehen bleiben.
2. **Laufzeit:** Der Gate-Lauf nach QA dauerte von 06.11. 13:07 bis 07.11. 09:07. Davon entfielen auf tests 13:11–13:57, der Rest auf mutgate (1443 Mutanten, unmutierter Lauf 270 s).
   - Bleibt `R/*.R` in Runde 2 bytegleich mit `3a77744`, gilt das Mutationsergebnis von Runde 1 für denselben Code.
   - Ob Runde 2 mutgate erneut rechnet oder wie in ADR-038 (M1b, Runde 8) per Betreiberentscheidung mit ADR auslässt, entscheidet der Betreiber.
   - Die vier Timeouts sind deterministisch: die Endlosschleifen in `R/parse.R:89` und `:100` sowie `delay = 1` in `R/run.R:49`. Ein Neulauf auf unverändertem Code sollte denselben Score ergeben.
3. **BL-123:** `orchestrator/state/mut-baseline` steht jetzt auf `80.25` (versioniert seit `4fc5539`). Vor M3c entfernen.
4. **BL-137:** Den Betreiber-Commit `b59e3f4` (vor `plan/M3d`, CI-Fix) habe ich gelesen (Prüflauf 6); kein Einwand. Die Prüfung der CI nach dem Push bleibt beim Betreiber.
5. **AP1** (ADR-053 Nr. 19.2): PROGRESS M3d nennt die Folge. Leere Antworten werden Backendfehler; vorhandene Stores werden nicht umklassifiziert. Über Fortsetzung und gemischte Stores entscheidet der Betreiber.

## Gate-Fakten (`orchestrator/state/M3d/gates.json`, Runde 1)

| Gate | Status | Kurzbefund | Bewertung |
| --- | --- | --- | --- |
| deps | pass | 31 Anforderungen erfüllt (R 4.6.1) | – |
| lint | pass | `R CMD check --as-cran`: Status: OK (`gate-lint.log` Z. 89) | Vignetten gebaut, Beispiele mit `--run-donttest` OK |
| tests | fail | 866 Tests; 3 fehlgeschlagen, 0 Fehler, 1 übersprungen | [INFRA], E11: nur die drei Stellen aus ADR-053 Nr. 14.5, in dieser Phase zurückgeführt |
| trace | pass | alle Kriterien wörtlich und beidseitig verknüpft | – |
| territory | pass | letzter Diff sauber (qa/45-qa, Runde 1) | – |
| mutgate | pass | score 80,25, verlangt 80, Baseline 80,25, Floor 80 | Überlebende nicht blocking (siehe Mutation, E15) |
| golden-adr | pass | keine Golden-/Ankeränderung | – |
| mutfull | pass | nicht fällig in M3d | – |

- **tests im Einzelnen:**
  - `tests/testthat`: 0 Fehlschläge, 1 Überspringen; das ist der bestehende Negativfall `test-backends.R:32` bei installiertem ellmer (`gate-tests.log` Z. 693–697).
  - Abnahme: rot nur m1d-7 (1 von 512 Erwartungen) und m1d-8 (9 Erwartungen in zwei Blöcken).
  - Grün sind unter anderem m0-api-snapshot (259), m1c-7-byte-equality (48), m2-4-backends (89), m2-7-robustness-pilot (375) und m3d-1 bis m3d-6.
  - `tests/simulation`, `tests/e2e` (818) und `tests/fuzz` (1580) sind grün.
- **M3d-BUILD-INFRA-01 aus PROGRESS** (lokales Socketverbot bei `req_dry_run`) betrifft nur die Sandbox des Builders. Im Gate laufen die Wiedergaben (m3d-3, m3d-6, m2-4, m2-7) grün. Nichts zu tun.

## Diff seit `plan/M3d` (Prüflauf 1)

48 Pfade, davon 29 im Builder-Commit `638feaa`:

- **Produkt:**
  - `R/backends.R`, `R/grr.R`, `R/parse.R`, `R/report.R`, `R/robustness.R`, `R/run.R`;
  - neu `R/report-data.R`;
  - `inst/templates/validation_report.Rmd`;
  - sieben Hilfeseiten (`backends`, `msa_boot`, `msa_report`, `msa_robustness`, `msa_run`, `parsers`, `pb_design`);
  - `NEWS.md` und `PROGRESS.md`.
- **Unit-Tests:** fünf neue Dateien (`test-run-resume.R`, `test-parser-properties.R`, `test-backend-metadata.R`, `test-report-provenance.R`, `test-seed-provenance.R`). Zwei Dateien sind ergänzt (`test-robustness-properties.R`, `test-robustness-transform.R`: nur Kommentare und zwei zusätzliche Erwartungen, nichts entfernt).
- **QA (`3a77744`):** `tests/e2e/test-m3b-qa-e2e.R` geändert, neu `test-m3d-qa-e2e.R` und `tests/fuzz/test-m3d-qa-fuzz.R`, gelöscht `tests/e2e/testthat-problems.rds`, `QA.md`.
- **Unverändert:** `DESCRIPTION`, `NAMESPACE`, `R/fit.R`, `R/acmg.R`, `R/agreement.R`, `R/spc.R`, `inst/extdata/`, `inst/validation/`, `reference/anchors/`, `data/`, Abnahme-, Simulations- und Fixture-Dateien.
- **Nr. 14.3 am Diff:**
  - `R/grr.R`: zwei roxygen-Zeilen und Z. 218 `attr(out, "seed") <- seed` in `msa_boot()`. Mit `seed = NULL` entfällt das Attribut, weil `attr<-` mit `NULL` es löscht.
  - `R/robustness.R`: fünf roxygen-Zeilen, Z. 71 `if (randomize && !is.null(seed)) attr(out, "seed") <- seed` in `pb_design()` und Z. 185 `attr(out, "seed") <- attr(design, "seed", exact = TRUE)` in `msa_robustness()`. Kein Schatten-Wrapper, kein Register (Nr. 14.4).
- **Arbeitsbaum gegen HEAD:** gleich bis auf zwei QA-Dateien, die nur in CRLF abweichen (`* text=auto eol=lf`). Betroffen sind `QA.md` mit 1 CR und `tests/fuzz/test-m3d-qa-fuzz.R` mit 161 CR; nach CRLF→LF sind beide gleich dem Blob. Ohne Folge.

## Spec- und Vertragstreue

- **K-M3d-1** (ADR-053 Nr. 1, 18.1, 18.3, 18.4):
  - `read_store()` liest CSV mit `colClasses`: `block`, `position` und `rep` als integer, `latency_s` als double, alles andere als Text, auch unbekannte Spalten (`R/run.R:171–177`).
  - Nur `error` wird zur Fehlerzeile (`tryCatch(…, error =)`, Z. 79). `interrupt` und `acmg_network_abort` verlassen den Lauf ohne Zeile.
  - Der Mock-Strom ist zeilenbezogen (`row_seed()`, `R/backends.R:98–105`). Er folgt der dokumentierten Faltung `s = (131 s + byte) mod 2147483647` über längenmarkierte UTF-8-Teile, exakt in double (unter 2^39), ohne Aufrufzähler. Vorgaben `block = 1`, `rep = 1` sind dokumentiert.
  - Prompt- und Modelleffekte bleiben wie vorher. Der RNG-Zustand des Aufrufers wird wiederhergestellt, auch ein fehlender. Gate m3d-1: 706 Erwartungen.
  - Randfall außerhalb des Kriteriums: E12.
- **K-M3d-2** (Nr. 2–4, 15):
  - U+2212 wird vor der Erkennung ersetzt (Escape im Quelltext, `R/parse.R:55`).
  - `parse_json_field()`: Die Fabrik prüft jsonlite mit der dokumentierten Meldung (Hilfeseite parsers). Der Scanner kennt Zeichenketten und Escapes. Geparst wird mit `jsonlite::parse_json(simplifyVector = FALSE)`, zugegriffen exakt auf oberster Ebene (`[[field, exact = TRUE]]`). Nur Länge-1-Zeichenketten oder -Zahlen gelten, sonst `NA_character_`. Fehler und Warnungen ergeben `NA`.
  - `parse_choice()` ist unverändert. Gate m3d-2 grün.
- **K-M3d-3** (Nr. 5–7, 18.2):
  - `backend_ellmer()` übernimmt `model` → `model_snapshot`, `provider` und `usage` aus `ch$last_turn()@json`, nur wenn vorhanden. Nichts wird aus dem Request erfunden.
  - Leere Antworten (`NULL`, Länge 0, `NA`, `""`) werden Fehlerzeilen mit benannter Art. `meta` bleibt, der Parser wird nicht aufgerufen (Z. 85–99). Nur Leerraum geht an den Parser.
  - Die Meldung ohne ellmer steht wörtlich in `?backends`. Gate m3d-3: 194 Erwartungen.
  - Darstellung der null-Antwort: E13 (3).
- **K-M3d-4** (Nr. 8, 9, 17):
  - Die Abschnitte 1–6 behalten Nummer und Titel; neu ist „## 7. System suitability: Westgard control chart“, dahinter „8. Conclusion“ und „9. Traceability“.
  - In den Abschnitten 3, 5 und 6 gibt es keine neue Überschrift.
  - Fehlendes ndc wird „NA“, nicht mehr „Inf“.
  - Die Westgard-Tabelle zählt `TRUE` je Regel und `reject` und gibt die sortierten `index`-Werte aus. Prüflauf 5 hat die Werte von Hand nachgezählt.
  - Gate m3d-4: 513 Erwartungen.
- **K-M3d-5** (Nr. 10):
  - `msa_report_canonical()` setzt die Bytevorschrift um: Schlüssel zuerst, übrige Namen per radix, Kopfzeile in Anführungszeichen, `%.17g`, NA ohne Anführungszeichen, Sortierung mit `na.last = TRUE`, Gleichstände nach der ganzen Zeile, LF am Ende.
  - Gehasht wird mit `digest(algo = "sha256", serialize = FALSE)`. Fehlende Schlüsselwerte stehen zuletzt (Prüflauf 4 (a)).
  - Die MD5-Zeile ist entfallen. Gate m3d-5: 89 Erwartungen.
- **K-M3d-6** (Nr. 11, 12, 14, 18.5, 18.6):
  - Gedruckt werden 1.41, Basis und Schwellen in „Classification“ sowie die Konvention 1 % und 9 % mit dem Wortlaut der Formelsammlung (Abschnitt Verdikt: „Konvention, Quadrat der StudyVar-Schwellen; nicht im Handbuch“).
  - Dazu kommen die latente Konvention, abgeleitete Komponenten („range method“), das Modell ohne Block- und Dreifach-Wechselwirkungen und die R_4s-Zeile („range of two consecutive standardized values“, gleich `R/spc.R:62`).
  - Die Seeds stehen als „Design seed: 314159“ usw. im Bericht; ohne Wert „not reported“.
  - Die Modelltabelle wird in `R/` berechnet und als deklarierte YAML-Parameter übergeben. Gate m3d-6: 52 Erwartungen. Darstellung: E13.
- **Nr. 14.2:** Die Attribute sind `identical()` mit dem übergebenen Seed bzw. mit `attr(design, "seed")`. Ohne Seed oder ohne Randomisierung entsteht kein Attribut. `test-seed-provenance.R` und die zurückgeführten M1d-Tests belegen das.
- **Nr. 16:** Klasse-B-Dateien sind unverändert, nichts ist umetikettiert.
- **Nr. 19.2:** PROGRESS nennt die AP1-Folge.

## API-Diff und Konfiguration

- `msa_report()` erhält als letztes Argument `control_chart = NULL` (docs/01 §4: neues Argument mit Vorgabewert am Ende, ohne ADR). Die Obermengenprüfung gegen ANK-02 ist grün (m0-api-snapshot, 259 Erwartungen).
- Die neuen Helfer `msa_report_*` sind intern. NAMESPACE und DESCRIPTION sind bytegleich; jsonlite und digest stehen in Suggests und werden vor Gebrauch benannt geprüft.
- Keine gelockerte Konfiguration, keine neuen `skip()` außer `skip_if_not_installed()` für Suggests in `tests/testthat` (docs/01 §5), keine entfernte Erwartung.
- Harte Werte im Produkt: `ndc_constant = 1.41, contribution_thresholds = c(1, 9)` (`R/report.R:107`) wiederholen die Konventionen aus `R/grr.R:61` und `:102` mit Verweis auf ANK-16. Sie erkennen keine Testwerte. Eine gemeinsame Konstante würde `R/grr.R` ändern, was Nr. 14.3 in M3d sperrt; vorgemerkt in BL-142 (3).

## Neue Tests: Verhalten oder Momentaufnahme

- **Verhalten belegt:**
  - Resume mit Text-IDs und unbekannten Spalten, Abbruch mit `interrupt` und eigener Nicht-Fehler-Bedingung bei frischem Mock (CSV und SQLite), kein Neuaufruf gespeicherter Fehler, Schreibfehler verlassen den Runner (`test-run-resume.R`);
  - zeilenbezogener Mock mit gleicher Zeichensumme, Teilgrenzen, Unicode, Block, Replikat und Reihenfolge; RNG-Wiederherstellung;
  - Parser mit Unicode-Minus, Escapes, Verschachtelung, Syntaxfehlern und Dateinamen-Attrappe;
  - beide Adapter gegen die Aufzeichnungen (Text, `model_snapshot`, `provider`, `usage` mit `identical()`, Chat-Isolation) und die Fehlerfolge in SQLite (`test-backend-metadata.R`);
  - Seed-Attribute gegen den ungeseedeten Aufruf mit gleichem globalem Seed und Serialisierung (`test-seed-provenance.R`).
- **Unabhängige Referenz:** Die kanonischen Bytes in `test-report-provenance.R:11–16` sind von Hand nach ADR-053 Nr. 10 geschrieben; die Seeds werden gegen `sprintf("%.0f")` geprüft, die Konstanten gegen ANK-16.
- **Gekennzeichnete Momentaufnahmen:** der Dateikopf von `test-report-provenance.R:1` („presentation checks, not numerical oracles“), Z. 104 („Explicit output fixture“), Z. 130 („Presentation fixture“) und die Robustheitsdruckblöcke (`test-robustness-properties.R:211`, `:224`).
  - Trennzeichen „; “, Reihenfolge und „not reported“ der Modelltabelle (Z. 81–83) sind eigene Darstellung; gedeckt durch die Kopfkennzeichnung.
- **Rest aus BL-128:** Der Plotblock `test-robustness-properties.R:277–312` (Titel, Achsentitel, `pch`, `lty`, `pos`, `cex`) ist weiter nicht als Momentaufnahme gekennzeichnet (E17). BL-128 (2) ist erledigt (Z. 218, 254; der M3b-Überlebende in `R/robustness.R` überlebt nicht mehr).

## Mutation (Bericht `reports/mutation/mutation.json`, Prüflauf 2)

| Datei | Killed | Survived | RuntimeError | Timeout |
| --- | ---: | ---: | ---: | ---: |
| `R/backends.R` | 161 | 60 | 7 | 0 |
| `R/grr.R` | 239 | 6 | 15 | 0 |
| `R/parse.R` | 119 | 24 | 5 | 3 |
| `R/report-data.R` | 101 | 36 | 4 | 0 |
| `R/report.R` | 49 | 28 | 25 | 0 |
| `R/robustness.R` | 278 | 9 | 36 | 0 |
| `R/run.R` | 126 | 102 | 9 | 1 |

- **Score:** (1073 + 4 Timeout) / (1073 + 4 + 265) = 80,25 % (`gate-mutgate.log` Z. 2251–2255). 0 NoCoverage, kein `MUT-EQUIV.json`, also keine Freigabe und kein `MUT-EQUIV-APPROVED.json`. mutgate ist grün, die Überlebenden sind deshalb nicht blocking.
- **Überlebende auf geänderten Zeilen:** 67 (backends 7, parse 9, report-data 36, report 3, robustness 1, run 11). Der Rest liegt im Bestand der ganz mutierten Dateien (`print.msa_runs()`, `msa_counts()`, `as_msa_runs()` usw.).
- **Gleichwertig nach Code-Lesung:**
  - `R/report-data.R:20` (Dezimalzeichen; R hält `LC_NUMERIC` auf C);
  - NA-Typen (`R/run.R:99`, `R/report-data.R:47`, `:73`);
  - `quietly`, `use.names`, `fixed` bei einem Zeichen;
  - `exact` bei `attr()` ohne Präfixkonkurrenz;
  - `R/parse.R:128` und `:131` (der umschließende `tryCatch` gibt `NA`).
- **Testlücken bei richtigem Produkt** (E15): `R/parse.R:154` (`exact = TRUE`), `R/report-data.R:40` (`na.last`), `:91`, `:117`, `R/run.R:86`, `R/backends.R:169`.
  - Dazu `R/backends.R:100`, `:101` und `:103` (Trennzeichen „:“, Startwert, Faktor 131 und `+`): Diese Faltung dokumentiert `?backends` unter `seed` wörtlich. Kein Test rechnet sie unabhängig nach; die Tests prüfen nur Determinismus und Verschiedenheit.

## QA

- **ADR-053 Nr. 14.6:** QA hat QA-M3b-E2E-3 genau wie verlangt angepasst. `seed` gehört zur Namensmenge; der Vergleich mit dem einfachen data.frame nimmt `seed` ab und prüft es getrennt mit `20261105L` bzw. `NULL`. Das ist keine Abschwächung.
- **BL-135:** erledigt; unter `tests/` gibt es kein `testthat-problems.rds` mehr (Prüflauf 4 (d)).
- **Neue QA-Tests** `test-m3d-qa-e2e.R` (91) und `test-m3d-qa-fuzz.R` (195) sind im Gate grün. Kein reproduzierender roter QA-Test.
- **QA-M3d-001** ist als nonblocking vorgeschlagen und bestätigt reproduziert (Prüflauf 4 (b)). Begründung der Herabstufung: E16.

## Abnahmetests des Reviewers (ADR-053 Nr. 14.5, E10 aus PLAN-REVIEW)

1. **`tests/acceptance/test-m1d-7-findings.R`**, Kommentar Z. 139–143, Block ab Z. 144:
   - Der Block prüft die Regel aus docs/02 M1d jetzt an `R/fit.R` und `R/grr.R` im Tag done/M1d gegen done/M1c.
   - Beide Stände kommen aus `acc_m1c_baseline_text()`; done/M1c wird weiter über `acc_m1d_baseline_file()` gegen ANK-34 geprüft.
   - Der Vergleich des Arbeitsbaums entfällt; für M3d gilt Nr. 14.3, geprüft oben am Diff.
   - Neu ist eine Prüfung, dass done/M1d Codezeilen liefert.
2. **`test-m1d-8-robustness-wording.R`**, Kommentar Z. 84–87, Block ab Z. 88:
   - Je Aufruf wird `attr(new, "seed")` mit `attr(design, "seed")` verglichen (beim einfachen data.frame `NULL`). Dann wird das Attribut abgenommen und der Rest mit done/M1c `identical()` verglichen.
   - Neu sind zwei Gegenproben: Der PB-Plan trägt ein Seed-Attribut, der data.frame keines. So ist der Vergleich nicht leer.
3. **Derselbe Test**, Block ab Z. 112:
   - Je Einstellung muss `effects` vorhanden sein und `attr(new$effects, "seed")` gleich `plan$design$seed` (neu: `plan$design$seed` ist nicht `NULL`).
   - Danach wird das Attribut abgenommen; der Rest einschließlich `band` wird mit done/M1c `identical()` verglichen. Die Bandprüfung `expect_setequal()` bleibt.
4. **Kopfkommentar** von test-m1d-8 um den Hinweis auf ADR-053 Nr. 14.2 und 14.5 ergänzt; sonst nichts geändert.

Das ist keine Abschwächung (Nr. 14.5.5): Jedes andere Attribut und jeder Wert bleibt verglichen; das neue Attribut wird zusätzlich und mit Wert geprüft. Keine Kriteriums-ID von M3d kommt hinzu; der trace-Gate bleibt unberührt.

## Einwände (Runde 1)

- [E11] (minor) [INFRA] Gate tests (fail, `gate-tests.log` Z. 1784–1866, Z. 2618); ADR-053 Nr. 14.5.4 („Bis dahin sind genau diese drei Tests rot. Das ist kein Befund gegen den Builder.“) — **Befund:** Rot sind nur test-m1d-7 Z. 145 und test-m1d-8 Z. 96 und 117, alle durch das zugelassene Attribut `seed`. Die Ursache liegt im Reviewer-Territorium. — **Erledigt** in dieser Phase (siehe oben, Prüflauf 3). Runde 2 bestätigt die Gates. Für den Builder nonblocking; BL-144.
- [E12] (minor) ADR-053 Nr. 18.3 („jede andere Spalte als Text“); `?msa_run` („CSV stores retain text exactly“, `R/run.R:10`); `R/run.R:171–177` — **Befund:** Ein Antworttext „NA“ wird als `"NA"` in Anführungszeichen gespeichert. `read.csv()` liest ihn mit dem Vorgabewert `na.strings = "NA"` als fehlend (Prüflauf 4).
  - Nach `resume = TRUE` trägt das zurückgegebene Objekt für solche Zeilen `response` als `NA`, mit `parse_identity()` auch `value`. Der ununterbrochene Lauf trägt den Text „NA“.
  - Die Speicherdatei bleibt bytegleich; K-M3d-1 vergleicht den Speicher und ist erfüllt. SQLite ist nicht betroffen.
  - — **Vorschlag:** nach dem 26.11.2026 die Grenze in `?msa_run` nennen oder den CSV-Leser zitatbewusst machen; Test mit dem Antworttext „NA“ über `resume = TRUE`. BL-139.
- [E13] (minor) ADR-053 Nr. 12.2 („ohne Wert ‚not reported‘“), Nr. 18.2 („Meldung, die die Art nennt“); `R/report-data.R:84–95`; `inst/templates/validation_report.Rmd`, Chunk `model-metadata`; `R/backends.R:230` — **Befund:** Darstellung, Werte richtig (Prüflauf 5):
  1. Die Modelltabelle hängt „not reported“ an die beobachteten Werte, sobald eine Zeile des Modells kein `meta` hat, etwa eine Transportfehlerzeile. Beispiel: „gpt-6.1-sol; not reported“. In AP1 träfe das jedes Modell mit mindestens einem Backendfehler.
  2. Der Satz „Missing values are not reported.“ liest sich als „werden weggelassen“; gemeint ist „shown as not reported“.
  3. `backend_openai_compatible()` macht aus `message.content: null` ein `NA`. Die Fehlerzeile heißt deshalb „Empty response: message content is NA.“, nicht „… is null“ (Prüflauf 4 (f)).
  - — **Vorschlag:** „not reported“ nur ohne jeden Wert oder mit Zeilenzahl; Satz umformulieren; `NULL` im Adapter durchreichen. Geänderte Berichtsausgabe ist ohne ADR zulässig (docs/01 §4). BL-140.
- [E14] (minor) Sichtbarer Defekt im Bestand; `inst/templates/validation_report.Rmd`, Chunk `boot` (seit `plan/M3d` unverändert) — **Befund:** Ohne `boot` erscheint in Abschnitt 3 „*Not assessed in this validation.*“ als eingerückter Codeblock. Der Chunk hat kein `results='asis'`; die anderen Abschnitte zeigen den Satz kursiv (Prüflauf 5, Bericht mit abgeleiteter Komponente und Bericht mit Regelkarte). — **Vorschlag:** `results='asis'` und `print(knitr::kable(…))`, die Leser der Bootstrap-Tabelle (K-M1c-3, K-M3d-4) gegenprüfen. Nach dem 26.11.2026. BL-141.
- [E15] (minor) Gate mutgate (pass, `gate-mutgate.log` Z. 2251–2255); `reports/mutation/mutation.json` — **Befund:** Testlücken bei richtigem Produkt:
  - `R/parse.R:154` `TRUE → FALSE` (`exact = TRUE`): Ein Feld „class“ neben „classification“ ist ungeprüft; mit `exact = FALSE` gäbe `parse_json_field("class")` den Wert von „classification“ zurück (Prüflauf 4 (e)).
  - `R/report-data.R:40` `TRUE → FALSE` (`na.last`): Fehlende Schlüsselwerte sind weder im Unit-Test noch in der K-M3d-5-Abnahme belegt; das Produkt sortiert sie richtig zuletzt.
  - `R/report-data.R:117` (`big.mark`, `trim` bei Positionen ab 1000 oder ungleicher Breite) und `:91` `& → |` (leere oder fehlende Feldwerte).
  - `R/run.R:86` `NULL → NA` (`meta` einer Antwort, die keine Liste ist) und `R/backends.R:169` (Kennung `client = "ellmer"`).
  - `R/backends.R:100`, `:101`, `:103` (`"" → "mutant"`, `<non-empty string> → ""`, `%% → *`, `+ → -`, 131 → 130/132): Die Faltung, die `?backends` unter `seed` dokumentiert, ist durch keine unabhängige Nachrechnung belegt.
  - Außerdem hat `hash_object()` (`R/utils.R:13–18`, MD5) seit M3d keinen Aufrufer mehr, und 1.41 und `c(1, 9)` stehen doppelt (`R/grr.R:61`, `:102`; `R/report.R:107`).
  - — **Vorschlag:** Tests ergänzen (darunter eine unabhängige Nachrechnung der dokumentierten Mock-Regel für eine Zeile) und `hash_object()` entfernen beim nächsten Eingriff, frühestens nach dem 26.11.2026; die Konstanten zusammenführen, wenn `R/grr.R` wieder offen ist. Die Abnahme ergänzt der Reviewer, falls K-M3d-5 wieder geöffnet wird. BL-142.
- [E16] (minor) QA.md QA-M3d-001; ADR-053 Nr. 2–4, 15.2; `R/parse.R:53`, `:109` — **Befund:** `parse_number()` und `parse_choice(whole_word = FALSE)` enden bei einem Zeichenvektor der Länge 2 mit „'length = 2' in coercion to 'logical(1)'“ (Prüflauf 4 (b)).
  - Die Herabstufung ist begründet: Es gibt keinen roten reproduzierenden Test; der Vertrag (Nr. 2–4, 15.2) regelt Skalare, `NULL`, Länge 0 und `NA`.
  - Die Prüfzeilen sind Bestand aus `332a2d5`, und `msa_run()` übergibt immer einen Skalar (`R/run.R:87`).
  - — **Vorschlag:** einheitlich `length(text) != 1L || is.na(text)` nach dem 26.11.2026. BL-143.
- [E17] (minor) Prüfauftrag 50-code-review (Momentaufnahme nur gekennzeichnet); BL-128 (1) — **Befund:** Der Plotblock `tests/testthat/test-robustness-properties.R:277–312` vergleicht Titel, Achsentitel, `pch`, `lty`, `pos` und `cex` mit Literalen, ohne als Momentaufnahme gekennzeichnet zu sein. Die übrigen Stellen aus BL-128 sind gekennzeichnet. — **Vorschlag:** Kommentar beim nächsten Eingriff; BL-128 nachgeführt.

## Eigene Prüfläufe

R-Skripte unter `orchestrator/handoff/M3d/.probe-review-r1/` (am Ende gelöscht), `Rscript --vanilla` aus der Repo-Wurzel, R 4.6.1, testthat 3.3.2, `REPO_ROOT` und `NOT_CRAN=true` aus R gesetzt.

### Prüflauf 1 — Diff ohne Git

- Ein R-Leser der Git-Objekte (lose Objekte und Packs mit OFS/REF-Deltas, SHA-1 jedes Objekts nachgeprüft) folgt `refs/tags/plan/M3d` → `a4115ae` → Baum und `refs/heads/main` → `4fc5539` → Baum.
- Ergebnis: 48 geänderte Pfade; Liste je Commit wie oben. Alte Blobs sind in die Probe geschrieben, Vergleich mit `diff -u`.
- Der Arbeitsbaum gleicht HEAD bis auf die zwei CRLF-Dateien von QA.

### Prüflauf 2 — Mutationsbericht

- Status je Datei (Tabelle oben). Die Überlebenden sind den geänderten Zeilen zugeordnet (Hunks aus `diff`) und am Code gelesen.
- Die vier Timeouts: `R/parse.R:89` (2×, `while`), `:100` (`+ → -`) und `R/run.R:49` (`delay = 0 → 1`).

### Prüflauf 3 — Zurückgeführte M1d-Tests ohne Git

- **Aufbau:**
  - Kopie aller `tests/acceptance/setup-*.R` und der Testdatei unter `tempdir()`;
  - `setup-zz-probe.R` ersetzt `acc_git()`: Nur `cat-file blob <ref>:<path>` wird aus den Git-Objekten bedient, jeder andere Aufruf bricht ab;
  - `pkgload::load_all()` des Repos, `test_dir(load_package = "none")`.
- **Ausgabe:**

  ```text
  variant positive, tests m1d8: 8 blocks, 0 with failures, 0 errors, 0 skipped, 49 expectations, 2.8 s
    git emulated: done/M1c:R/robustness.R, done/M1c:R/acmg.R
  variant positive, tests m1d7full: 9 blocks, 0 with failures, 0 errors, 0 skipped, 514 expectations, 101.1 s
    git emulated: done/M1c:R/fit.R, done/M1d:R/fit.R, done/M1c:R/grr.R, done/M1d:R/grr.R
  variant seed_wrong (seed + 1):               2 blocks red (seed checks, msa_robustness and acmg)
  variant seed_missing:                        2 blocks red (seed checks)
  variant seed_on_plain (seed on data.frame):  1 block red ("plain data.frame")
  variant extra_attr (attribute "probe"):      2 blocks red (identical() without seed)
  variant value_changed (effect * (1+1e-12)):  2 blocks red (identical() without seed)
  variant acmg_seed_missing:                   1 block red (seed of effects)
  variant acmg_band (marginal -> acceptable):  1 block red (band and expect_setequal)
  variant acmg_effects_attr:                   1 block red (identical() without seed)
  variant m1d7_codechange (done/M1d grr.R c(10, 31)):  1 block red ("1/124 mismatches")
  variant m1d7_roxygen_only (done/M1d roxygen line):   0 red, 4 expectations
  variant positive, tests m1d7block:                   0 red, 4 expectations
  ```

### Prüflauf 4 — Randfälle

- **„NA“-Text:** `write.table(qmethod = "double")` schreibt `"NA"` und `NA`; `read.csv(colClasses = "character")` liest beide als `NA` (E12).
- **(a)** Fehlende `block`- und `item_id`-Werte stehen in der kanonischen Form zuletzt.
- **(b)** `parse_number()(c("1.5", "2.5"))` und `parse_choice(c("A", "B"), whole_word = FALSE)(c("A", "B"))` enden mit „'length = 2' in coercion to 'logical(1)'“. `whole_word = TRUE` und `parse_json_field()` geben `NA`.
- **(d)** Kein `testthat-problems.rds` unter `tests/`.
- **(e)** `parse_json_field("class")('{"classification":"x"}')` gibt `NA`; mit `exact = FALSE` wäre es „x“.
- **(f)** Ein Backend, das wie der Adapter `NULL` zu `NA` macht, erzeugt „Empty response: message content is NA.“.
- **(g)** Die in `?backends` dokumentierte Mock-Regel, unabhängig nachgerechnet (`set.seed()` der gefalteten Zahl, dann `rnorm(1)` bei `sd_prompt = sd_model = 0`), gleicht `backend_mock(seed = 3101)` mit `identical()` für drei Zeilen. Geprüft sind `("1", "001", "P1", "m1", "1")`, `("2", "010", "P2", "m2", "2")` und eine Zeile ohne `block`/`rep` mit Item „ä“. Dokumentation und Code stimmen also; die Überlebenden in `R/backends.R:100–103` sind eine Testlücke (E15).

### Prüflauf 5 — Gerenderte Berichte

- Gerendert als GitHub-Markdown mit den Abnahmehelfern:
  - Hauptbericht der K-M3d-4-Studie;
  - Bericht mit Regelkarte (24 Werte aus `acc_m3d_chart()`);
  - Bericht mit den drei aufgezeichneten Modellen und einer Transportfehlerzeile bei Sol;
  - ordinaler Bericht mit abgeleiteter Modellkomponente.
- **Westgard:** 1_2s 3 (3, 4, 6), 1_3s 1 (6), 2_2s 1 (4), R_4s 1 (7), 4_1s 1 (12), 10_x 1 (24), reject 5 (4, 6, 7, 12, 24). Das stimmt mit der Nachzählung aus den Werten überein.
- **Konventionen, Seeds, Hash und Traceability** wie verlangt. Der Hinweis zur latenten Restvarianz folgt unmittelbar der Zeile mit repeatability und reproducibility (Nr. 17.3).
- **Modelltabelle mit Fehlerzeile:** „sol | gpt-6.1-sol; not reported | not reported | not reported“ (E13).
- **Ohne `boot`:** „    *Not assessed in this validation.*“ (eingerückt, also Codeblock; E14).

### Prüflauf 6 — Betreiber-Commit `b59e3f4` (BL-137)

- `msa_bias_scaled_mean()` teilt durch `p = 2^min(floor(log2(max|x|)), 1023)`. Das ist exakt, und |x/p| < 2, also kein Überlauf in Summe oder Ergebnis.
- `msa_bias_center()` nutzt den Rückfall nur bei nicht endlichem `mean()` endlicher Werte.
- Der Unit-Test prüft Grenzwerte und Bitgleichheit auf vier Vektoren. Der Pfadvergleich in `test-validation-bias.R:177` ist portabel.
- Kein Einwand. `R/agreement.R` liegt nicht im Mutationsumfang von M3d.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`, `orchestrator/prompts/50-code-review.md`, `orchestrate.sh` (`path_allowed` Z. 515–544, `verdict()` Z. 734–756), `gates.d/70-trace.sh`, `lib/r-tests.R`.
- **Spezifikation:** docs/04 M3d (Ergebnissatz, K-M3d-1 bis K-M3d-6); docs/01 §1–§5; Formelsammlung, Abschnitt Verdikt (Konvention 1 und 9) und §12 Nr. 13.
- **Handoff M3d:**
  - `CRITERIA.json` (ACC-1 bis ACC-17), `PLAN.md` (Ziel, Dateien, Schnittstellen, Reihenfolge, P-M3d-01);
  - `PLAN-REVIEW.md` (E1 bis E10), `verdict-plan.json`, `QA.md`;
  - ADR-053 vollständig, `PROGRESS.md` (M3d).
- **Gates:** `gates.json`, alle `gate-*.log` (tests: Fehlschläge, Ergebniszeilen, Skips; mutgate: Kopf und Schluss); `reports/mutation/mutation.json`; `orchestrator/state/M3d/shots/` ist leer.
- **Diff seit `plan/M3d`:**
  - vollständig: alle Produktdateien, Vorlage, Hilfeseiten, NEWS, die sieben Unit-Testdateien, die QA-Änderung an `test-m3b-qa-e2e.R`;
  - dazu `R/run.R` und `R/backends.R` ganz, `R/report-data.R` ganz.
- **Abnahme:** `test-m1d-7-findings.R` Z. 100–147, `test-m1d-8-robustness-wording.R` ganz, `setup-m1d.R` Z. 670–838, `setup-m1c.R` Z. 700–780, `setup-acceptance.R` Z. 1–107, `setup-m3d.R` Z. 440–655; ANK-34.
- **Bestand:** `R/spc.R:13–62`, `R/grr.R:23–133` (Konstanten), `R/utils.R:1–25`, `R/acmg.R` (Seed-Stellen, `acmg_robustness()`), `BACKLOG.md` (BL-11, BL-17, BL-18, BL-60, BL-120 bis BL-138), Betreiber-Commit `b59e3f4`.
