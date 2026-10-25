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
