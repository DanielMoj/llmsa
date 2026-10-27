# PROGRESS — Langzeitgedächtnis des Builders

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
