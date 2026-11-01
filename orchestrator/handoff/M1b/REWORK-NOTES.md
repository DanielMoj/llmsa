# M1b — REWORK, Runde 6

Rolle: Builder · Stand: 01.11.2026 · Keine Git-Kommandos.

## Ergebnis und Grundlage

**Kein offener blocking-Befund und keine verlangte Produktänderung.**
REVIEW/verdict-code der Runde 5 enthalten `blocking: []`. ADR-037 Nr. 2
ordnet für Runde 6 ausdrücklich die Dokumentation fortbestehender
Infrastrukturursachen an. Die Datei
`reference/quellen/data/aiag/anova_example.csv` fehlt weiterhin; die
gezielten Abnahmeläufe reproduzieren den Fehler. M1b ist damit weiterhin
**nicht abgenommen**.

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
Handoff-Schema, REVIEW.md und verdict-code.json der Runde 5, gates.json
samt roten Logs, CRITERIA.json, ARBITER.md, LESSONS.md, PROGRESS.md
(aktueller M1b-Stand), docs/01 und docs/02 (M1b), ADR-035/037 sowie die
unten ausgeführten unveränderten Abnahmedateien und ihre Helfer.
Die beiden privaten Belegdokumente sind wie die übrigen Dateien unter
`reference/privat/` nicht vorhanden (R6-P1).

Die vorhandenen Gate-Fakten gehören zu **Runde 5**, Zeitpunkt
`2026-11-01T22:22:23+01:00`, Produktstand `a8f8db7`:
lint, tests und mutgate `fail`; deps, trace, territory, golden-adr und
mutfull `pass`; `result: fail`. Kein Gate hat Status `error`, kein
offenes `[QA-PENDING]` ist im aktuellen Verdict ausgewiesen. Die roten
Gates bleiben als Fakten bestehen, obwohl ihre Ursache nach ADR-037
für den Builder nonblocking ist. Die folgenden Läufe sind gezielte
Diagnosen und kein neuer Gate-Lauf oder Mutationsscore.

## Antworten auf die Befund-IDs

### E37 — OUT-OF-TERRITORY [INFRA], weiterhin reproduzierbar

Ref: REVIEW E37; ADR-037 Nr. 2; AGENTS.md, Handoff-Disziplin und
Domänenregeln; docs/01 §6; BL-103.

Das geschützte AIAG-Datenblatt fehlt samt `QUELLE.txt`; auch
`reference/quellen/` und `reference/privat/` enthalten weiterhin keine
Dateien (R6-P1). Die Wiederherstellung gehört dem Betreiber.

Belege aus den vorhandenen Gate-Logs:

- `orchestrator/state/M1b/gate-lint.log:16` und `:26`:
  `Validation input is missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv`;
  Zeile 34: `r-check: fail — R CMD build fehlgeschlagen`.
- `orchestrator/state/M1b/gate-tests.log:571` und die nachfolgenden
  AIAG-Stacktraces nennen `acceptance: local AIAG data sheet missing`.
- `orchestrator/state/M1b/gate-mutgate.log:3`:
  `r-mutation: unmutierter Testlauf: 125 s; 392 Tests, davon 12 fehlgeschlagen, 4 abgebrochen`;
  Zeile 20: `r-mutation: Abbruch vor dem ersten Mutanten: Schon unmutiert scheitern 16 Tests (/mnt/c/Users/Danie/dev/Llmsa/llmsa/reports/mutation/unmutated.json)`.

Eigene Reproduktion: K-M1a-2 endet mit drei Fehlern und Exit 1 (R6-P2);
die Repository-Vignette K-M1b-7 endet wegen derselben fehlenden Datei mit
sieben fehlgeschlagenen Erwartungen und Exit 1 (R6-P3). Das vorgeschriebene
Fehlschlagen bleibt erhalten. Es wurden keine Ersatzdaten erzeugt.

Weiterer Schritt laut BL-103: Betreiber stellt die Originaldateien wieder
her, prüft den Datenblatt-Hash gegen ANK-10 und den Rollback-Mechanismus
und führt danach die Gates erneut aus. BACKLOG und Orchestrator bleiben
außerhalb dieses Builder-Auftrags.

### E38 — OUT-OF-TERRITORY [INFRA], Testtreiber beim Betreiber

Ref: REVIEW E38; ADR-037 Nr. 2; BL-104;
`orchestrator/state/M1b/gate-tests.log:685`.

Echter Log-Output:

```text
Maximum number of failures exceeded; quitting.
```

Der Testordner wurde nach m1a-4 abgebrochen. Der gelesene Treiber
`orchestrator/lib/r-tests.R` verwendet weiterhin den ProgressReporter
ohne eigene Aufhebung seiner Abbruchgrenze. Die in BL-104 verlangte
Korrektur am Gate-Treiber gehört dem Betreiber.

R6-P3 und R6-P4 führen ausgewählte M1b-Abnahmedateien unmittelbar aus.
Dies ersetzt weder die im Gate ausgelassenen Dateien noch einen
vollständigen Abnahmelauf. Die übrige Abnahme wird in dieser Runde ohne
Produktänderung nicht wiederholt; der vollständige zusätzliche Lauf
des Reviewers steht in REVIEW Runde 5, Prüflauf 1.

### E39 — nonblocking, Entscheidung nach neuem Mutationsbericht

Ref: REVIEW E39; ADR-037 Nr. 3; Handoff-Schema MUT-EQUIV; BL-102.

`reports/mutation/mutation.json` fehlt weiterhin (R6-P1).
`unmutated.json` enthält 16 rote Testblöcke (12 fehlgeschlagen,
4 abgebrochen); das Gate ist vor dem ersten Mutanten abgebrochen.
Es gibt damit keinen aktuellen vollständigen Score und keinen neuen
Survived-/NoCoverage-Bericht, aus dem ein Testauftrag abgeleitet wird.

Die drei nicht freigegebenen Überlebenden des früheren lokalen Teillaufs
bleiben ausdrücklich offen: `R/fit.R:338:74` (`>` → `>=`) sowie
`:331:42` und `:337:55` (`symmetric = TRUE` → `FALSE`). Gemäß REVIEW
E39 ist deren Bearbeitung jetzt nicht verlangt; entschieden wird über
den nächsten Bericht. Eine allgemeine Äquivalenz wird nicht behauptet.

`R/fit.R`, `R/grr.R`, die 16 bestehenden Anträge in `MUT-EQUIV.json`
und `MUT-EQUIV-APPROVED.json` bleiben unverändert. Die vom Reviewer
gebundenen Quellzeilen werden nicht verschoben. Neue Claims oder eigene
Approvals gibt es nicht.

### Fortgeltung der früheren Befunde

E33/E34 sind laut REVIEW Runde 5 und ADR-037 Nr. 1 erledigt, E35 ist
dokumentiert, E36 ist behoben. Die früheren Antworten und Prüfnachweise
bleiben unten als historischer Handoff der Runde 5 erhalten; sie sind
keine neuen Läufe dieser Runde. E32/BL-100 und E35/BL-101 bleiben nach
ADR-035 zurückgestellt. Der Arbiterentscheid zu K-M1b-5 (π²/3,
rptR-Liability-Vergleich, ANK-25 nur Installationsprüfung) gilt weiter;
R6-P4 prüft diesen Vertrag erneut gegen die Orakel.

## Ausgeführte gezielte Prüfungen

Alle Befehle liefen aus `/mnt/c/Users/Danie/dev/Llmsa/llmsa` mit
R 4.6.1, testthat 3.3.2, lme4 2.0.6, ordinal 2026.7.26,
rptR 0.9.23 und performance 0.19.0. Die folgenden Ausgaben sind echte,
auf die Befunde gekürzte Auszüge; die vollständige Werkzeugspur liegt
im vom Orchestrator geführten Modellphasen-Log.

### R6-P1 — fehlende Betreiberdateien und fehlender Mutationsbericht

```sh
python3 - <<'PY'
from pathlib import Path
for name in ('reference/quellen/data/aiag/anova_example.csv', 'reference/quellen/data/aiag/QUELLE.txt', 'reference/privat/QUELLENKATALOG.md', 'reference/privat/07_Formelsammlung_llmsa.md', 'reports/mutation/mutation.json', 'reports/mutation/unmutated.json'):
    path = Path(name)
    print(f'{name}: {"PRESENT" if path.is_file() else "MISSING"}')
for name in ('reference/quellen', 'reference/privat'):
    print(f'{name}: {sum(p.is_file() for p in Path(name).rglob("*"))} files')
PY
```

Exit 0 (Bestandsaufnahme, kein Abnahmelauf):

```text
reference/quellen/data/aiag/anova_example.csv: MISSING
reference/quellen/data/aiag/QUELLE.txt: MISSING
reference/privat/QUELLENKATALOG.md: MISSING
reference/privat/07_Formelsammlung_llmsa.md: MISSING
reports/mutation/mutation.json: MISSING
reports/mutation/unmutated.json: PRESENT
reference/quellen: 0 files
reference/privat: 0 files
```

### R6-P2 — unveränderte AIAG-Abnahme, Exit 1

```sh
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath("."), NOT_CRAN = "true"); grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m1a-2-aiag$", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
Error: acceptance: local AIAG data sheet missing (K-M1a-2, ANK-10, docs/01 §6): /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 0 ]
Error:
! Test failures.
Execution halted
```

Alle drei Fehler stammen aus `acc_m1a_aiag()`, aufgerufen in
`test-m1a-2-aiag.R:14`, `:39` und `:69`.

### R6-P3 — unveränderte Repository-Vignette, Exit 1

```sh
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath("."), NOT_CRAN = "true"); grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m1b-7-vignette$", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
Failure ('test-m1b-7-vignette.R:31:3'): K-M1b-7: the vignette knits in the repository without error and shows the section
Expected `k$error` to be NULL.
Differences:
`actual` is a character vector ('Validation input is missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv')
`expected` is NULL
[ FAIL 7 | WARN 0 | SKIP 0 | PASS 11 ]
Error:
! Test failures.
Execution halted
```

Die übrigen sechs fehlgeschlagenen Erwartungen betreffen den durch den
Knit-Abbruch fehlenden Abschnitt (`test-m1b-7-vignette.R:33`, `:39`,
`:64` sowie `:84` je Studie).

### R6-P4 — ordinale und binäre Orakel, Exit 0

```sh
Rscript --vanilla -e 'Sys.setenv(REPO_ROOT = normalizePath("."), NOT_CRAN = "true"); grDevices::pdf(NULL); testthat::test_dir("tests/acceptance", filter = "^m1b-(1-engine-ordinal|5-binary-rptr)$", load_package = "source", reporter = testthat::ProgressReporter$new(show_praise = FALSE), stop_on_failure = TRUE)'
```

```text
✔ |         34 | m1b-1-engine-ordinal [2.7s]
✔ |          9 | m1b-5-binary-rptr
Duration: 3.2 s
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 43 ]
```

### R6-P5 — Integrität, Exit 0

Vor den Testläufen wurde eine SHA-256-Inventur von 376 Dateien angelegt
(`/tmp/llmsa-m1b-r6-_4e_x1e3/before.json`). Sie umfasst Produkt- und
Testverzeichnisse, Referenzen, Specs, Handoffs, Gate-Skripte, M1b-Zustand
und die einzeln aufgeführten Regel-/Paketdateien; keine Git-Metadaten
oder Schlüsseldateien. Die Vergleichsprüfung liest diese Inventur und
erlaubt ausschließlich die beiden hier beauftragten Dokumentänderungen.

```sh
python3 /tmp/llmsa-m1b-r6-_4e_x1e3/verify_integrity.py
```

```text
Inventory: 2 changed, 0 added, 0 removed files
Changed: PROGRESS.md
Changed: orchestrator/handoff/M1b/REWORK-NOTES.md
Unchanged inventory files: 374/374
Tests and fixtures unchanged: 96/96
Prior REWORK-NOTES and PROGRESS history: byte-identical
Gate facts unchanged: round 5, result fail
AIAG data sheet and mutation.json: still missing
```

Diese Dateiinventur ersetzt nicht die Territoriumsprüfung des Orchestrators.

## Änderungen und Übergabe

Geändert wurden nur dieser zugewiesene Handoff und PROGRESS.md.
Produktcode, bestehende Tests, Gates, Schwellen, Anker, Daten,
Kurzlaufdateien, Claims und Approvals bleiben erhalten. Kein neuer
Paketcheck, keine Simulation und kein Mutationslauf wurde gestartet.
Der Betreiberauftrag aus BL-103/104 ist Voraussetzung für aussagekräftige
neue Gate-Fakten; ein PASS wird hier nicht behauptet.

---

# M1b — REWORK, Runde 5

Rolle: Builder · Stand: 01.11.2026 · Keine Git-Kommandos.

## Grundlage und Grenze der Aussage

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
PROGRESS.md, Handoff-Schema, REVIEW/verdict-code Runde 4, CRITERIA.json,
ARBITER.md, LESSONS.md, gates.json samt Gate-Logs, M1b-Spezifikation,
ADR-029 bis ADR-035 und die betroffenen Abnahmetests. ADR-034 Nr. 1/2
legt die Umsetzung von E33/E34 fest; ADR-035 Nr. 4 erhält diesen Auftrag.
Der Arbiterentscheid bleibt unverändert: Logit-Restvarianz π²/3,
ANK-25 als Installationsprüfung, Vergleich mit rptR auf der Liability-Skala.

Die vorhandenen Gate-Fakten stammen aus **Runde 4**: alle acht Gates
`pass`, kein `error`; mutgate 93,02 bei verlangten 90,83, Baseline 93,83,
Floor 80. Kein offenes [QA-PENDING]. Dieser Handoff berichtet lokale
Prüfungen, schreibt kein Gate-Ergebnis und erteilt kein Verdict.

E33 und E34 sind umgesetzt. E35 ist dokumentiert; der widerlegte Antrag
aus E36 ist zurückgenommen. Die lokale Abnahme ist wegen der fehlenden
geschützten AIAG-Datei **nicht grün**. Diese Ursache und die weiteren
lokalen Infrastrukturgrenzen sind unten mit echtem Output als
OUT-OF-TERRITORY ausgewiesen. Es wurden keine Ersatzdaten angelegt.

Rohlogs, ausgeführte Prüfskripte und isolierte Paketkopien liegen unter
`/tmp/llmsa-m1b-r5-VqXqW8/`. Die vollständige Werkzeugspur bleibt im
Modellphasen-Log des Orchestrators. Im Folgenden steht `work` für dieses
Verzeichnis und `REPO_ROOT` für `/mnt/c/Users/Danie/dev/Llmsa/llmsa`.
Temporäre Paketkopien enthalten keine Schlüssel oder Git-Daten.

## Antworten auf die Befund-IDs

### E33 — umgesetzt und gezielt geprüft

Ref: REVIEW E33; ADR-034 Nr. 1; ADR-032 Nr. 1; ADR-029 Nr. 2.1/2.2;
docs/01 §2 Nr. 4; LESSONS „Numerische Randfälle als Klasse beheben.“

`R/fit.R:433` berechnet die Gram-Matrix aus dünn besetzten Kreuztabellen.
Mit N_ij = Z_iᵀWZ_j, B_i = Qᵀ√WZ_i und F_i = B_iB_iᵀ lautet der
Eintrag jetzt ΣN_ij² − 2Σ((B_iN_ij) ⊙ B_j) + Σ(F_i ⊙ F_j).
Die dichten Stufen-mal-Stufen-Projektionsblöcke entfallen. Dies ist die
algebraische Expansion derselben Quadratsumme gemäß ADR-034.

Restzeile, Restdiagonale, Rangnachweis vollständig aufgespannter Terme,
Eigenwertregel und Namensdiagnose bleiben unverändert. Insbesondere gilt
weiter min(ev) ≤ k · eps · max(ev), mit dem Restterm in k und der
Entscheidung durch `only.values = TRUE`. Es gibt keine neue Toleranz.

Die neue Datei `tests/testthat/test-fit-latent-precision.R` prüft bei
gesperrten Engines beide Zielgrößen und beide Links: 900/1500/2000
Singleton-Items, Nullgewichtsduplikate, 1200/2000 Singleton-Zellen mit
Wechselwirkungen, verschachtelte 1000 Items sowie identifizierbare
Vergleichspläne. Auch ein einziges zusätzliches Beobachtungspaar muss die
Trennung von der Restvarianz erlauben. Geschlossene Formeln aus
Itemhäufigkeiten prüfen die Matrix bis 5000 Items, zusätzlich mit der
absoluten Toleranz aus ANK-TOL.arithmetic. Keine Fit-Momentaufnahme dient
als Referenz.

Ein zusätzliches Raster über sieben Größen und drei Seeds liefert
588 Entscheidungen ohne Abweichung (P1). Die unveränderten Abnahmetests
reproduzieren die sechs Kurzlauf-CSVs bytegleich (P3/P4).
`man/msa_fit.Rd`, `NEWS.md` und Builder-ADR-036 dokumentieren die Änderung.

### E34 — umgesetzt; ursprüngliche Engine-Gewichte bleiben erhalten

Ref: REVIEW E34; ADR-034 Nr. 2; ADR-032 Nr. 1.2; docs/01 §2 Nr. 4.

`R/fit.R:281` löst die Prüfgewichte erst nach Antwortbereinigung,
`subset` und `na.action` auf: Sind alle verbleibenden Gewichte exakt
ganzzahlig, zählen sie als Vielfachheiten. Andernfalls zählt jede positive
Zeile einmal, jede Nullgewichtszeile nullmal. Dieselbe Darstellung gilt
für Antwortkategorien, beobachtete Zufallsstufen, ordinalen festen Rang,
Gram-Matrix und deren Rangnachweis. Das ursprüngliche `args` und damit
Engine-Daten, Formeln und Engine-Gewichte bleiben erhalten.

Die neue Unit-Datei prüft 1,25/1,5 und gemischte Gewichte bei Singletons,
0,1 und 1/n bei identifizierbaren Plänen mit und ohne Wechselwirkungen,
ganzzahlige Vielfachheiten 2 und die Auswahl vor der Ganzzahligkeitsprüfung.
Ein fester ordinaler Rangfall unterscheidet sehr kleine positive Gewichte
von null. Gültige gewichtete Fits werden gegen direkte `clmm`-/`glmer`-
Aufrufe verglichen, einschließlich Daten, Modellgewichten und nobs;
Komponententoleranz aus ANK-TOL.engine_ordinal.

Die unabhängige Beobachtungspaarrechnung mit SVD liefert in einem zweiten
Raster 768 übereinstimmende Entscheidungen (P1). Auf dem alten Produktcode
scheitern die sieben neuen Blöcke mit 73 fehlgeschlagenen Erwartungen
und ohne Testfehler. Hilfe, NEWS und ADR-036 beschreiben die Gewichtsregel.

### E35 — bekannte Einschränkung dokumentiert

Ref: REVIEW E35; BL-101; ADR-035 Nr. 2/3.

`R/fit.R:148` und der erzeugte Abschnitt „Known limitations“ in
`man/msa_fit.Rd` erklären, dass Nullgewichtszeilen bei der Auswahl
zufälliger gegenüber zweistufigen festen Effekten weiterhin Stufen
beisteuern. Bei beabsichtigtem Ausschluss wird auf `subset` verwiesen.
Die Termauswahl und die Engine-Daten werden nicht geändert. Dieselbe
Hilfeseite nennt den numerischen Durchreichweg aus E32/BL-100.

### E36 — widerlegten Claim entfernt; verbleibende Anträge neu gebunden

Ref: REVIEW E36; ADR-034 Nr. 3; SCHEMA.md; BL-85/BL-102.

Das überflüssige `stringsAsFactors = FALSE` in `as.data.frame(runs)`
entfällt (`R/fit.R:180`). Die Vorgabe ist seit R 4.0 gleich; das Paket
verlangt R ≥ 4.1. Der nicht äquivalente FALSE→TRUE-Mutant ist nicht mehr
erzeugbar und wird nicht mehr beantragt. P7 vergleicht `msa_runs`,
Datenrahmen, Liste und Zeichenmatrix mit dem bisherigen Code: Koerzierung,
Daten, Häufigkeiten, Komponenten und numerische Diagnosen sind identisch.

`MUT-EQUIV.json` enthält jetzt **16 Anträge** mit endgültiger Zeile,
Spalte, Quelltext und Ersatz. Die Gegenprüfungen matchen 16 verschiedene
Mutanten über 14 vollständige Gate-Schlüssel. Die drei Aggregations-
Mutanten teilen einen Schlüssel und sind einzeln begründet. Es wird kein
problematischer `<n> - 1`-Claim für `R/grr.R:99` hinzugefügt.
`MUT-EQUIV-APPROVED.json` bleibt unangetastet; Freigabe und Neubindung
gehören dem Reviewer.

P5 dokumentiert 168 Killed, 9 Survived und 2 syntaktische RuntimeErrors
im gezielten Teillauf. Sechs Überlebende sind in den Äquivalenzanträgen
enthalten. **Ungeclaimt** bleiben `R/fit.R:338:74` (`>`→`>=` an der
Namensschwelle) sowie `:331:42` und `:337:55` (`symmetric = TRUE`→`FALSE`
der beiden Eigenwertaufrufe). Für diese drei ist keine allgemeine
Verhaltensgleichheit bewiesen; sie werden nicht aus einem Nenner entfernt.
Die betreffenden Produktzeilen sind unverändert. Es wird kein vollständiger
Mutationsscore aus der Diagnose abgeleitet.

Der zusätzliche Überlebende `:465:13` (`<=`→`>=`) wird durch einen neuen
Test getötet: Drei Itemindikatoren sind exakt feste Linearkombinationen
von vier Designspalten. Der Test erwartet deshalb die algebraisch
begründete Nullzeile/-spalte, auch mit Häufigkeitsgewichten (P5).

### Fortführung der älteren IDs

| ID | Antwort und Beleg |
| --- | --- |
| E12 / QA-M1b-001 | Laut REVIEW erledigt; bestehende Refit-/Bootstrap-Tests und QA erneut ausgeführt, P2. |
| E13 / QA-M1b-002 | Zeilenauswahl, Gewichte und Offsets bleiben geprüft; E34 ergänzt die lokale Prüfgewichtsregel, P1/P2. |
| E14 / QA-M1b-003 | Bestehende Identifizierbarkeitstests bleiben erhalten; E33/E34 ergänzen die Klasse, P1/P2. |
| E15 / QA-M1b-004 | Dokumentations-/Reproduktionsprüfungen und QA bleiben erhalten; Kurzlauf-Reproduktion und Volllauf-Fixture bestehen, P2/P3. Die Repo-Vignette ist lokal durch INFRA-AIAG blockiert. |
| E16 / QA-M1b-005 | Bestehende Label- und Call-Prüfungen erneut grün, P2. |
| E17 / QA-M1b-006 | Unveränderte Datei-/Bereichsvalidatoren und QA erneut grün; Volllauf-Fixture 204 Erwartungen, P2/P3. |
| E18 | Gate Runde 4 pass; P5 ist nur eine lokale Diagnose. |
| E19 | Laut REVIEW erledigt; `R/acmg.R` bytegleich, AP1-Units und QA in P2. |
| E20 | Builder-Teil erledigt; Reviewer-Fortsetzung M1c/M1d gemäß BL-91 bleibt. |
| E21 | Sechs Kurzlauf-CSVs bytegleich, P4. Volllaufbewertung bleibt Betreiber/M1d, BL-92. |
| E22 | Gate Runde 4 bestätigt; keine Änderung der HTTP-Replay- oder Zeitprüfungen. Lokale Zeit-NOTE in P6. |
| E23 | OUT-OF-TERRITORY [INFRA], nonblocking: zwei unveränderte Reviewer-Abnahmehelfer-Warnungen, P3/BL-93. |
| E24 | Eigenwertregel beibehalten; bestehende Identifizierbarkeitsprüfungen und neue Fälle bestehen, P1/P2. |
| E25 | Laut REVIEW/Gate erledigt; unveränderte Volllauf-Fixture erneut 204 Erwartungen grün, P3. |
| E26 | Laut REVIEW/Gate erledigt; gemeinsamer E2E-Lauf einschließlich M2 grün, P2. Kein offenes [QA-PENDING]. |
| E27 | Bestehende Call-/Labeltests erneut grün, P2. |
| E28 | NEWS um große Pläne, Prüfgewichte und dokumentierte Einschränkungen ergänzt. |
| E29 | Grundregel beibehalten, offene Teilfälle durch E33/E34 bearbeitet; Restterm und Rangnachweis bleiben, P1/P7. |
| E30 | Laut REVIEW erledigt; Auswahl der beteiligten Termnamen bytegleich, Tests erneut grün, P1/P7. |
| E31 | Laut REVIEW erledigt; bestehende tötende Tests unverändert, Anträge neu gebunden, P5/P7. |
| E32 | OUT-OF-TERRITORY für M1b: ADR-032 Nr. 3 verlangt „Kein Builder-Auftrag in M1b.“ BL-100/ADR-035 bleiben maßgeblich; numerische Helfer bytegleich, Einschränkung dokumentiert, P7. |

## Ausgeführte Prüfungen und echter Output

### P1 — gezielte Tests, unabhängige Raster, negative Gegenprobe

Ausgeführt mit `REPO_ROOT` wie oben; `run-tests.R` lädt die Quellkopie,
speichert alle Ergebnisse als RDS und gibt bei Fehlschlag Exit 1 zurück.
Ausführung der gezielten Tests in `$work/mutation-source`:

```sh
Rscript --vanilla "$work/run-tests.R" tests/testthat '^fit-latent-(precision|residual-weights|identifiability|design-grid|rework)$' "$work/mutation-baseline-final.rds"
```

Echter Output (`mutation-baseline-final.log`), Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1957 ]
Blocks: 32; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 22.585 s
```

`R_LIBS="$work/library" Rscript --vanilla "$work/design-grid.R"`
(`design-grid.log`, `large-grid.csv`, `weighted-grid.csv`), Exit 0:

```text
Large designs: 588 decisions, seeds 20261121-20261123, sizes 300-5000, 6.146 s
              observed
expected       identifiable rejected
  identifiable          252        0
  rejected                0      336
Large-design mismatches: 0
Independent observation-pair SVD: 768 decisions, seeds 20261201-20261296, 5.791 s
              observed
expected       identifiable precheck rejected
  identifiable          340        0        0
  precheck                0       60        0
  rejected                0        0      368
Weighted-grid mismatches: 0
```

Die große Referenz verwendet exakte Kovarianzrelationen, die kleine
Referenz expandierte Beobachtungspaare und einen unabhängigen SVD-Projektor.
Sie umfasst ganzzahlige und gebrochene Gewichte, Nullgewichte,
unbalancierte, gekreuzte und verschachtelte Pläne.

Gegenprobe in `$work/regression-source`, dort ausschließlich `R/fit.R`
auf dem Stand vor diesem Rework, alle sieben neuen Testblöcke unverändert:

```sh
Rscript --vanilla "$work/run-tests.R" tests/testthat '^fit-latent-precision$' "$work/regression-complete.rds"
```

Echter Output (`regression-complete.log`), erwarteter Exit 1:

```text
[ FAIL 73 | WARN 0 | SKIP 0 | PASS 470 ]
Blocks: 7; failed expectations: 73; error blocks: 0; skipped: 0; elapsed: 9.642 s
```

### P2 — vollständige Units und unveränderte QA

```sh
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa Rscript --vanilla "$work/run-unit-qa.R" tests/testthat tests/e2e tests/fuzz
```

Echter Output (`unit-qa-final.log`), Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 1 | PASS 5254 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 282 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

Die neue Datei liefert sieben Blöcke und 545 bestandene Erwartungen.
Der einzige Unit-Skip ist der bestehende ellmer-Negativtest
(`test-backends.R:32`). E2E und Fuzz umfassen M1a, M1b und M2. Alle
Bestandstests und QA-Dateien bleiben bytegleich; kein Skip wurde ergänzt.

### P3 — unveränderte Abnahme M1a/M1b und lokale Infrastrukturgrenze

Im Repo, mit `REPO_ROOT` wie oben:

```sh
Rscript --vanilla "$work/run-tests.R" tests/acceptance '^m1[ab]-' "$work/acceptance.rds"
```

Echter Output (`acceptance.log`), Exit 1:

```text
[ FAIL 59 | WARN 2 | SKIP 0 | PASS 3765 ]
Blocks: 128; failed expectations: 55; error blocks: 4; skipped: 0; elapsed: 216.189 s
```

Die gespeicherten Ergebnisse (`acceptance-summary.log`) weisen M1a mit
48 fehlgeschlagenen Erwartungen/4 Fehlern/520 bestandenen Erwartungen
und M1b mit 7 fehlgeschlagenen Erwartungen/0 Fehlern/3245 bestandenen
Erwartungen aus. Alle 3030 Erwartungen aus K-M1b-1 bis K-M1b-6 bestehen;
hinzu kommen 204 bestandene Erwartungen der Volllauf-Fixture. Die
verbleibenden sieben M1b-Fehlschläge betreffen ausschließlich die
Repo-Vignette. Kein Test wird übersprungen.

**INFRA-AIAG — OUT-OF-TERRITORY.** Die geschützte Betreiber-Datei fehlt.
Vier direkte Abnahmefehler sowie sämtliche 55 fehlgeschlagenen
Vignetten-Erwartungen folgen daraus. Belege: `acceptance.log:18`, `:94`,
`:180` und die Fehlerstelle `test-m1b-7-vignette.R:31`:

```text
Error: acceptance: local AIAG data sheet missing (K-M1a-2, ANK-10, docs/01 §6): /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv
`actual` is a character vector ('Validation input is missing: /mnt/c/Users/Danie/dev/Llmsa/llmsa/reference/quellen/data/aiag/anova_example.csv')
```

AGENTS.md verlangt bei fehlenden geschützten Quelldateien einen
Fehlschlag; `reference/quellen/**` ist Betreiber-Territorium. Die Datei
wird weder erfunden noch aus einer anderen Darstellung ersetzt, und
die Abnahme wird nicht umgangen. Bereitstellung bleibt beim Betreiber.

**E23 — OUT-OF-TERRITORY [INFRA], nonblocking (BL-93).** Die zwei
Warnungen stammen unverändert aus `test-m1b-4-two-levels.R:41/42`,
Reviewer-Territorium. Echter Output (`acceptance.log:627/640`):

```text
the 'nobars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
the 'findbars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
```

### P4 — echte Regeneration aller neun Kurzlaufdateien

Das Paket wurde aus der aktuellen temporären Quellkopie installiert;
keine Abhängigkeit wurde installiert oder heruntergeladen:

```sh
R CMD INSTALL --no-docs --library="$work/library" "$work/source"
R_LIBS="$work/library" Rscript --vanilla "$work/regenerate.R"
```

Beide Befehle Exit 0; `install.log` und `regenerate.log`.
`regenerate.R` liest n_sim = 20 aus ANK-TOL.n_check und startet die drei
unveränderten installierten Skripte mit ihren unveränderten Seeds und
14 Workern in neuen Ausgabeordnern. Echter Output:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 107.327 s; workers 14
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.964 s; workers 14
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 9.623 s; workers 14
Nine genuine short-run files copied; six CSVs byte-identical to the pre-rework files.
No full-run files written in the repository.
```

Alle neun tatsächlichen Ausgaben wurden in die jeweiligen `_check_`-
Dateien übernommen. Die sechs CSVs sind bytegleich zum Rundenbeginn;
die drei Sessiondateien tragen den separat abgeglichenen aktuellen Hash
`477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e`.
P3 reproduziert die CSVs nochmals bytegleich. Keine Betreiber-Vollläufe.

**INFRA-TIMEZONE — OUT-OF-TERRITORY.** Die Sessionerfassung erreicht
den Systembus in der Sandbox nicht. Alle drei Prozesse enden dennoch
mit Exit 0; die Sessiondaten bleiben unverfälscht. `regenerate.log:3–19`:

```text
Failed to connect to system scope bus via local transport: Operation not permitted (consider using --machine=<user>@.host --user to connect to bus of other user)
Warning message:
In system("timedatectl", intern = TRUE) :
  running command 'timedatectl' had status 1
```

### P5 — gezielte Mutationen und Äquivalenzbelege

```sh
Rscript --vanilla "$work/prepare-mutations.R"
Rscript --vanilla "$work/native-mutations.R"
python3 "$work/run-mutations.py"
python3 "$work/summarize-mutations.py"
Rscript --vanilla "$work/equivalence-proofs.R"
```

Die Pläne verwenden dieselben neun Mutatorfamilien wie das Gate und die
endgültigen Produktzeilen 274–282, 312–344 und 433–477, insgesamt
179 Mutanten. Kein Gate-Skript oder Gate-Status wurde ausgeführt/geändert.

**INFRA-MUTTEST — OUT-OF-TERRITORY.** Der native Lauf endet nach dem
grünen unmutierten Vorlauf mit Exit 1 (`native-mutations.log`):

```text
Unmutated targeted suite: 31 blocks; failed expectations 0; errors 0; skips 0
Error in .dispatcher_start(...):
  16 | Permission denied
Calls: ... launch_dispatcher -> .dispatcher_start
Execution halted
```

Danach wurden dieselben erzeugten Quellmutanten als zusätzliche Diagnose
in gewöhnlichen R-Unterprozessen in getrennten temporären Paketkopien
ausgeführt, weiter innerhalb der Sandbox, ohne Berechtigungsänderung.
Dieser Teillauf ersetzt weder mutgate noch dessen Score. Output
`targeted-mutations.log`, Exit 0 des Diagnosetreibers:

```text
Counts: {'Killed': 167, 'Survived': 10, 'RuntimeError': 2}
Elapsed seconds: 554.422
Diagnostic run only; no gate score or equivalence approval.
```

Der neue kleine Test für Mutant 33 wurde anschließend unverändert in
`$work/span-target/tests/target/test-span.R` isoliert, einmal mit dem
aktuellen Produkt und einmal mit `mutation-code/033.R`. Befehl jeweils
aus `$work/span-target`:

```sh
Rscript --vanilla "$work/run-tests.R" tests/target '^span$' "$work/span-original.rds"
Rscript --vanilla "$work/run-tests.R" tests/target '^span$' "$work/span-mutant.rds"
```

Echter Output (`span-original.log`, Exit 0; `span-mutant.log`, Exit 1):

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 6 ]
Blocks: 1; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 0.811 s
[ FAIL 3 | WARN 0 | SKIP 0 | PASS 3 ]
Blocks: 1; failed expectations: 3; error blocks: 0; skipped: 0; elapsed: 1.084 s
```

`targeted-mutations-final.json` bewahrt die ursprünglichen Einzelberichte
und ergänzt den zusätzlichen Beleg für ID 33. Zusammenfassender echter
Output (`targeted-mutations-final.log`):

```text
Combined targeted evidence: 179 mutants; 168 Killed, 9 Survived, 2 RuntimeError.
Changed normalization/sparse-expression lines: 32 mutants; all Killed.
RuntimeError mutants 74 and 86 have invalid generated R syntax; neither counts as Killed.
No complete gate score calculated; no approvals written.
```

Die sechs beantragten Überlebenden liegen bei `314:47`, `315:64`,
`329:46`, `440:45` und zweimal `448:18`. Die drei ungeclaimten stehen
bei E36. Das neue vollständige mutgate und die Entscheidung über alle
Anträge bleiben beim Orchestrator beziehungsweise Reviewer.

**INFRA-MUTPARSE — OUT-OF-TERRITORY.** Die beiden RuntimeErrors entstehen
durch syntaktisch ungültige Mutanten der mehrzeiligen Gewichtsvalidierung,
nicht durch das unmutierte Produkt. Echter Output in
`mutation-runs/074/R-output.log` und `mutation-runs/086/R-output.log`:

```text
Failed to load 'R/fit.R'
Caused by error in `parse()`:
! At 'R/fit.R:277:9': unexpected '!'
```

Die Äquivalenzbelege (`equivalence-proofs.log/.json`, Exit 0) umfassen
9837 positive Häufigkeitsvektoren, 33 REML-Zustände, 1400 beobachtete
Gruppierungsfaktoren, 200 gewichtete QR-Prüfungen, 400 Gram-Vergleiche
mit/ohne Restterm sowie Strukturbeweise für Gruppennamen, Initialisierung,
Aggregation und den einzigen `on.exit`-Handler. Schlussausgabe:

```text
Proved candidates: 16 ; no approvals written.
```

### P6 — erzeugte Hilfe und installiertes Quellpaket

Roxygen wurde in einer isolierten Dokumentationskopie ausgeführt; nur
`man/msa_fit.Rd` wurde übernommen. P7 prüft die Bytegleichheit mit dieser
Erzeugung. Die endgültige Paketkopie enthält die **unveränderte**
`.Rbuildignore` des Repos. Aus `$work/package-check`:

```sh
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Endgültiger Bau und Check enden mit Exit 0
(`package-check/build-configured.log`, `package-check/check-configured.log`).
Keine ERRORs oder WARNINGs; Beispiele einschließlich `--run-donttest`,
Tests und Neubau der Vignetten sind OK. Echter Schlussoutput:

```text
* checking tests ...
  Running ‘testthat.R’ [79s/79s]
 [79s/79s] OK
* checking for unstated dependencies in vignettes ... OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [29s/29s] OK
* checking for non-standard things in the check directory ... OK
* checking for detritus in the temp directory ... OK
* DONE

Status: 1 NOTE
```

Installierte Tests (`package-check/llmsa.Rcheck/tests/testthat.Rout`):

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 5178 ]
```

Die neun Skips folgen den unveränderten CRAN-/Umgebungsbedingungen der
Bestandstests; die Repo-Originalankerprüfungen sind separat in P2 belegt.

**INFRA-CLOCK — OUT-OF-TERRITORY.** Einzige NOTE,
`package-check/check-configured.log:29–31`:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Zeitprüfung wurde nicht deaktiviert. Die Remote-Incoming-Einstellung
entspricht dem unveränderten Check-Aufruf des Harness.

Der erste Paketversuch hatte zusätzlich eine LICENSE.md-NOTE, weil in
der temporären Kopie `.Rbuildignore` fehlte. Der endgültige Lauf verwendet
die unveränderte Repo-Datei; keine Ausschlussregel wurde neu eingeführt.
Der Paketcheck ersetzt die durch INFRA-AIAG rote Repo-Abnahme nicht.

### P7 — Schnittstellen, Hash, Äquivalenzbindung und Territorium

```sh
REPO_ROOT=/mnt/c/Users/Danie/dev/Llmsa/llmsa Rscript --vanilla "$work/verify-contracts.R"
python3 "$work/integrity.py"
```

`verify-contracts.log`, Exit 0:

```text
E36: msa_runs, data.frame, list and character matrix: default coercion and numeric data, counts, vc and diagnostics identical.
Numeric helper functions unchanged: 7
API: all 22 snapshot exports retain argument order and defaults; both independent references agree.
All three genuine sessions match current implementation: 477e84a5ad763c15cbcd4e12142b7ca02797fb96571f66ceb0b2a68368ae5c1e
16 claims match 16 distinct mutants across 14 complete gate keys; no approvals written.
```

`integrity.log`, Exit 0 (SHA-256-Inventar vom Rundenbeginn):

```text
Inventory: 9 changed baseline files, 2 new files; all assigned Builder paths; no removals.
Changed: NEWS.md, PROGRESS.md, R/fit.R, inst/validation/sim/binary_recovery_check_session.txt, inst/validation/sim/ordinal_recovery_check_session.txt, inst/validation/sim/two_level_check_session.txt, man/msa_fit.Rd, orchestrator/handoff/M1b/MUT-EQUIV.json, orchestrator/handoff/M1b/REWORK-NOTES.md
New: docs/decisions/ADR-036-m1b-duenn-besetzte-information-und-pruefgewichte.md, tests/testthat/test-fit-latent-precision.R
Protected baseline: 405/405 files byte-identical.
Existing tests and fixtures: 95/95 files byte-identical.
Numerical helper suffix, eigenvalue rule and name diagnostics byte-identical.
R source and new unit test: ASCII. Generated help matches roxygen2; checked package copy matches final files.
Nine short-run files match their real outputs; six CSVs unchanged; no full-run files created.
Gate facts unchanged: round 4, result pass; approval file and other handoffs unchanged.
Workspace root: no Rplots.pdf, package archive or Rcheck directory.
```

Kein bestehender Test, keine Fixture, kein Anker, keine Spezifikation,
keine Schwelle, keine Freigabe und kein Orchestrator-Zustand wurde
geändert. Geändert sind ausschließlich Builder-Produkt-/Dokumentations-
dateien, echte Kurzlauf-Sessiondateien, PROGRESS und die zwei zugewiesenen
Builder-Handoffs. Neu sind ADR-036 und die Unit-Datei. Die territoriale
Gate-Prüfung, der Phasen-Commit und der neue Gate-Lauf bleiben beim
Orchestrator; der Builder führt keine Git-Kommandos aus.
