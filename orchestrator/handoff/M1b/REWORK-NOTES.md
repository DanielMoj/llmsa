# M1b — REWORK, Runde 4

Rolle: Builder · Stand: 01.11.2026 · Keine Git-Kommandos.

## Grundlage und Grenze der Aussage

Gelesen: AGENTS.md, IMPLEMENTATION-RULES.md, contracts/PROTOCOLS.md,
PROGRESS.md, Handoff-Schema, REVIEW/verdict-code Runde 3, CRITERIA.json,
ARBITER.md, LESSONS.md, gates.json und Gate-Logs, die M1b-Spezifikation,
ADR-029 bis ADR-032 sowie die betroffenen Abnahmetests. Maßgeblich für
E29 ist ADR-032 Nr. 1. Der Arbiterentscheid zu K-M1b-5 bleibt unverändert:
Logit-Restvarianz π²/3, ANK-25 nur Installationsprüfung.

Die vorhandenen Gate-Fakten stammen aus **Runde 3**: alle acht Gates
`pass`, kein `error`, keine offenen [INFRA]- oder [QA-PENDING]-Gate-Ursachen.
Mutgate meldet 92,14 bei verlangten 91,83. Die Betreiberentscheidung
ADR-031 für das nächste Gate bleibt unangetastet. Dieser Handoff berichtet
lokale Builder-Prüfungen und schreibt weder Gate-Ergebnis noch Verdict.

E29 ist umgesetzt; E30 und die konkret benannten Testlücken aus E31 sind
bearbeitet. E32 bleibt nach ausdrücklicher Reviewer-Entscheidung außerhalb
der M1b-Arbeit. Lokale Infrastrukturgrenzen stehen unten als
OUT-OF-TERRITORY mit echtem Log-Beleg.

Rohlogs, Prüfskripte und isolierte Paketkopien liegen unter
`/tmp/llmsa-m1b-r4-3lho07s_/`. Die vollständige Werkzeugspur bleibt im
Modellphasen-Log des Orchestrators. Alle nachstehenden Auszüge sind echter
Output. Temporäre Kopien enthalten keine Schlüssel oder Git-Daten.

## Antworten auf die Befund-IDs

### E29 — umgesetzt und gezielt geprüft

Ref: ADR-032 Nr. 1; ADR-029 Nr. 2.1; docs/01 §2 Nr. 4;
LESSONS „Numerische Randfälle als Klasse beheben.“

- `R/fit.R:262` validiert die ausgewerteten latenten Gewichte: numerisch,
  endlich, nichtnegativ, endliche positive Summe. Gewicht null liefert
  weder Antwortkategorien noch beobachtete ordinale Zufallsstufen oder
  Ranginformation. Der ordinale feste Rang wird gewichtet geprüft.
- `R/fit.R:313` fordert vor beiden latenten Engines die gemeinsame
  Identifizierbarkeit aller Zufallsterme **und der festen Restvarianz**.
  `msa_latent_information()` (`R/fit.R:417`) rechnet mit √W X und √W Z
  im Stufenraum. Mit B_j = Qᵀ√W Z_j gilt
  G_ij = ‖Z_iᵀWZ_j − B_iᵀB_j‖²_F,
  G_jε = Σw − ‖B_j‖²_F und G_εε = Σw − p.
  Nullgewichte werden für diese Rechnung entfernt. Vollständig vom
  gewichteten festen Design aufgespannte Terme erhalten exakt null als
  Zeile/Spalte, einschließlich ihrer Rest-Kreuzprodukte.
- Die Eigenwertregel bleibt min(ev) ≤ k · eps · max(ev), mit k einschließlich
  des Restterms. Der bisherige Aufruf mit `only.values = TRUE` entscheidet;
  zusätzliche Eigenvektoren erklären ausschließlich einen bereits
  festgestellten Verstoß. Ein exaktes synthetisches Nullraumbeispiel deckt
  unterschiedliche LAPACK-Rundungsreste dieser beiden Aufrufe ab.
- Bei beteiligter Restvarianz erklärt der Fehler die fehlende Trennbarkeit
  von der festen latenten Restvarianz. `not identifiable`, die betroffenen
  Termnamen und `call. = FALSE` bleiben. Fehler treten vor `clmm`/`glmer` auf.
- Die zwei neuen Dateien `tests/testthat/test-fit-latent-residual-weights.R`
  und `tests/testthat/test-fit-latent-design-grid.R` enthalten zwölf Blöcke
  mit 1088 Erwartungen. Sie prüfen die verlangten Singleton-Items,
  Singleton-Zellen und wine-Wechselwirkungen für ordinal/binär und
  Probit/Logit, Nullgewichte gegenüber `subset`, Häufigkeitsvielfachheiten,
  feste Rangdefizienz, mehrere Nullraumrelationen und gültige gewichtete
  Fits gegen direkte Engines. Referenzen sind expandierte Beobachtungspaare
  samt vec(P), algebraische Rangrelationen, unabhängige SVD und laufende
  Engine-Orakel; keine Momentaufnahmen eigener Fit-Ausgaben.
- Das Raster umfasst 96 synthetische Pläne, beide Zielgrößen und Links:
  384 Entscheidungen ohne Abweichung von der unabhängigen Referenz (P3).
  Dazu gehören unbalancierte, verschachtelte, gekreuzte, teilweise
  unbeobachtete und erst durch Nullgewichte konfundierte Pläne.
- `man/msa_fit.Rd`, `NEWS.md` und Builder-ADR-033 dokumentieren das Verhalten.
  Die Hilfeseite stimmt exakt mit der Roxygen-Erzeugung überein.
- Alle neun Kurzlaufdateien wurden mit dem installierten aktuellen Paket
  neu erzeugt. Die sechs CSVs sind bytegleich zum Rundenbeginn; die drei
  Sessiondateien enthalten den neuen, separat abgeglichenen Hash (P4).
  Engine-Aufrufe gültiger Pläne, numerischer Rechenkern und `R/grr.R`
  bleiben unverändert (P7).

Belege: P1 bis P8. Weder vorhandene Tests noch Akzeptanzregeln wurden geändert.

### E30 — umgesetzt: ausschließlich beteiligte Terme

Ref: ADR-029 Nr. 2.1; ADR-030 Nr. 5; REVIEW E30/BL-98.

`R/fit.R:323` bestimmt die Vereinigung der beteiligten Komponenten über
alle erkannten Nullraumrichtungen. Die quadrierte Zeilenlänge der
orthonormalen Nullraumbasis muss größer als k · eps sein; dies entfernt
Rundungsrauschen aus der Namensliste und verändert die Rangentscheidung
nicht. Bei mehreren unabhängigen Relationen werden alle betroffenen
Komponenten genannt. Die Restvarianz erhält zusätzlich die Erklärung aus
E29. Die neuen Tests prüfen **exakte** Meldungen, Termlisten, fehlenden Call
und fehlende Warnungen, auch bei verschachtelten Items und bei gleichzeitig
mehreren Relationen. Unbeteiligte Terme erscheinen nicht (P1, P5).

### E31 — benannte Testlücken geschlossen; Äquivalenzen beantragt

Ref: REVIEW E31, Mutationsbericht Runde 3, ADR-032 Nr. 2, BL-99/BL-85.

Die vier konkret als nicht äquivalent beschriebenen Überlebenden werden
jetzt durch neue Verhaltenstests getötet. Alte Dateien bleiben unverändert:

| Mutant aus Runde 3 | Gegenstück im aktuellen Code | Lokaler echter Output |
| --- | --- | --- |
| `R/fit.R:302:15`, `"numeric"` → `""` | `313:15`, ID 123 | Killed, 2 fehlgeschlagene Erwartungen, 0 Testfehler |
| `308:51`, Meldungsende → `""` | `327:12`, ID 127 | Killed, 32 fehlgeschlagene Erwartungen, 0 Testfehler |
| `308:99`, `call. FALSE` → `TRUE` | `327:60`, ID 62 | Killed, 32 fehlgeschlagene Erwartungen, 0 Testfehler |
| `399:47`, `interaction(drop=TRUE)` → `FALSE` | `425:47`, ID 55 | Killed, 4 fehlgeschlagene Erwartungen, 0 Testfehler |

Der erste Fall erwartet die exakte numerische Diagnose für einen auch
latent konfundierten Plan. Der vierte verwendet aufgespannte
Wechselwirkungen mit unbeobachteten Kombinationen. Weitere neue Tests
prüfen die exakte Nullmatrix bei gesättigtem festen Design, einen minimalen
internen Ein-Spalten-Datenrahmen und verschiedene ungültige Gewichte.

P5 erzeugt mit den neun Gate-Mutatorfamilien 163 Mutanten der betroffenen
Prüfblöcke. Nach den gezielten Ergänzungen: **154 Killed, 7 Survived,
2 RuntimeError**. Die beiden RuntimeErrors sind syntaktisch ungültige
Mutanten, keine getöteten Mutanten. Von den sieben Überlebenden sind sechs
begründet äquivalent. Der siebte, `R/fit.R:323:74`, `>` → `>=` allein an der
Namensdiagnoseschwelle, bleibt **ungeclaimt**: Die Tests unterscheiden den
exakten Gleichheitsfall k · eps nicht; allgemeine Äquivalenz ist nicht
bewiesen. Dieser Grenzfall ändert nicht die Annahme-/Ablehnungsentscheidung.
Es wird kein vollständiger Gate-Score aus dem Teillauf abgeleitet.

`MUT-EQUIV.json` enthält **17 einzeln begründete Anträge mit endgültigen
Zeilen**, einschließlich der M1a-Neubindungen und der drei bisherigen
latenten Äquivalente. Strukturbeweise und ausgeführte Gegenprüfungen stehen
in jedem Antrag und P5. Drei Aggregationsmutanten teilen denselben
Gate-Schlüssel; alle drei Spalten sind einzeln geprüft. Der problematische
Schlüssel `R/grr.R:99`, `<n> - 1`, wird nach ADR-032 Nr. 2 nicht beantragt.
Die bestehende Freigabe `R/grr.R:99`, `>` → `>=`, braucht keine Zeilenänderung.
`MUT-EQUIV-APPROVED.json` wurde nicht geändert. Neubindung und Freigabe der
Anträge anhand des nächsten vollständigen Berichts bleiben beim Reviewer.

### E32 — OUT-OF-TERRITORY für diesen M1b-Auftrag

Ref: ADR-032 Nr. 3; REVIEW E32; BL-100.

Wörtliche Direktive: „Kein Builder-Auftrag in M1b.“ Der explizite numerische
Durchreichweg wird deshalb nicht angepasst. Die Entscheidung gehört in
die Betreiberplanung von M1c. Numerische Helfer, numerischer Engine-Aufruf,
Refit-Aufruf und `R/grr.R` sind bytegleich zum Rundenbeginn; die unveränderte
M1a-Abnahme besteht mit 722 Erwartungen (P2, P7). Kein Scheinfix.

### Fortführung der älteren IDs aus REVIEW

| ID | Stand dieser Runde |
| --- | --- |
| E12 | Laut REVIEW erledigt; bestehende Refit-/Bootstrap-Tests und QA-M1b-001 bestehen (P1/P2). |
| E13 | Laut REVIEW erledigt; Zeilenauswahl, Gewichte, Offsets und QA-M1b-002 bestehen; E29 ergänzt Nullgewichte (P1/P2). |
| E14 | Laut REVIEW erledigt; die Identifizierbarkeitsklasse wird durch E29 vervollständigt, QA-M1b-003 bleibt grün (P1/P2). |
| E15 | Dokumentations-/Reproduktionsprüfungen und QA-M1b-004 bestehen; der frühere Namespace-Seiteneffekt E26 ist erledigt (P1/P2). |
| E16 | Bestehende Label- und Call-Prüfungen sowie QA-M1b-005 bestehen (P1). |
| E17 | Unveränderte Datei-/Bereichsvalidatoren und QA-M1b-006 bestehen; Volllauf-Fixture 204 Erwartungen grün (P1/P2). |
| E18 | Gate Runde 3 pass. P5 ist eine lokale Diagnose, keine neue Gate-Freigabe. |
| E19 | Laut REVIEW erledigt. `R/acmg.R` bleibt bytegleich; AP1-Regressionen P8. |
| E20 | Builder-Teil erledigt; Reviewer-Fortsetzung M1c/M1d gemäß BL-91 bleibt. |
| E21 | Unverändert spec-gemäß; sechs Kurzlauf-CSVs bytegleich (P4). Volllaufbewertung bleibt Betreiber/M1d, BL-92. |
| E22 | Gate Runde 3 bestätigt; keine Änderung der HTTP-Replay- oder Zeitprüfungen. Lokale Zeit-NOTE siehe P6. |
| E23 | OUT-OF-TERRITORY [INFRA], nonblocking: zwei unveränderte Deprecation-Warnungen aus dem Reviewer-Abnahmehelfer, P2/BL-93. |
| E24 | Bisheriges Kriterium beibehalten und gemäß E29 um Restvarianz/Gewichte erweitert. Bestehende Identifizierbarkeitstests bleiben grün. |
| E25 | Laut REVIEW/Gate erledigt. Unveränderte Volllauf-Fixture erneut grün, 204 Erwartungen in P2. |
| E26 | Laut REVIEW/Gate durch QA erledigt. Gemeinsamer E2E-Lauf nach M1b weiter grün einschließlich M2, P1. Kein offenes [QA-PENDING]. |
| E27 | Laut REVIEW/Gate erledigt. Bestehende Call-/Labeltests bleiben grün. |
| E28 | Erledigt; NEWS jetzt um die Restvarianz- und Gewichtsprüfung ergänzt. |

## Ausgeführte Prüfungen und echter Output

Alle Befehle liefen mit R 4.6.1, lme4 2.0.6, ordinal 2026.7.26 und
muttest 0.3.0. Für die folgenden Kurzschreibweisen gilt:

```sh
rework_dir=/tmp/llmsa-m1b-r4-3lho07s_
repo_dir=/mnt/c/Users/Danie/dev/Llmsa/llmsa
```

`run-tests.R` führt `testthat::test_dir(..., load_package="source",
stop_on_failure=FALSE)` aus, speichert die Ergebnisse, berichtet echte
Zähler und beendet den Prozess bei Fehlern mit Exit 1. Es ändert keine
Tests. Seine Grafikdatei liegt im temporären Verzeichnis.

### P1 — vollständige Units und unveränderte QA; gezielte latente Tests

```sh
REPO_ROOT="$repo_dir" Rscript --vanilla orchestrator/lib/r-tests.R \
  tests/testthat tests/e2e tests/fuzz
```

`unit-qa-final.log`, Exit 0:

```text
tests/testthat: [ FAIL 0 | WARN 0 | SKIP 1 | PASS 4709 ]
tests/e2e:      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 49 ]
tests/fuzz:     [ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]
r-tests: pass — 275 Tests in tests/testthat, tests/e2e, tests/fuzz; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen
```

Der vorhandene Skip in `test-backends.R:32:3` prüft den Fall eines fehlenden
ellmer-Pakets; ellmer ist installiert. Keine neue Skip-Regel.

Unmutierter Schlusslauf der Mutations-Testauswahl in der temporären
Paketkopie `mutation-source/`:

```sh
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/testthat '^fit-latent-(residual-weights|identifiability|design-grid|rework)$' \
  "$rework_dir/mutation-baseline-final.rds"
```

`mutation-baseline-final.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 1412 ]
Blocks: 25; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 16.697 s
```

### P2 — unveränderte Abnahme M1b und M1a

Jeweils vom Repository aus:

```sh
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/acceptance '^m1b-' "$rework_dir/acceptance-m1b.rds"
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/acceptance '^m1a-' "$rework_dir/acceptance-m1a.rds"
```

Beide Exit 0. `acceptance-m1b.log`:

```text
[ FAIL 0 | WARN 2 | SKIP 0 | PASS 3474 ]
Blocks: 74; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 236.385 s
```

`acceptance-m1a.log`:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 722 ]
Blocks: 54; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 74.888 s
```

**E23 — OUT-OF-TERRITORY [INFRA].** Die zwei Warnungen stammen aus dem
unveränderten Reviewer-Test `test-m1b-4-two-levels.R:41:5` und `:42:5`:

```text
the 'nobars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
the 'findbars' function has moved to the reformulas package. Please update your imports, or ask an upstream package maintainer to do so.
```

Kein Produkt-Workaround, keine Warnungsunterdrückung im Abnahmetest.
M0-Tests und der Git aufrufende Lint-Wrapper wurden wegen des ausdrücklichen
Git-Verbots nicht ausgeführt. Der direkte Paketcheck steht in P6.

### P3 — unabhängiges Raster und negative Produktgegenprobe

```sh
Rscript --vanilla "$rework_dir/design-grid.R"
```

`design-grid.log`, Exit 0:

```text
Seeds: 20261103 through 20261198; RNG: Mersenne-Twister/Inversion/Rejection
Plans: 384 (96 designs x 2 outcome types x 2 links)
              implementation
reference      identifiable precheck rejected
  identifiable          168        0        0
  precheck                0       18        0
  rejected                0        0      198
Mismatches: 0
Accepted minimum singular-value ratio: 0.1673327
Rejected maximum singular-value ratio: 1.969743e-14
Elapsed: 1.605 s
```

Die berichteten Verhältnisse sind Beobachtungen, keine neuen Toleranzen.
Dasselbe Raster liegt dauerhaft in der neuen Unit-Datei. Die Referenz
expandiert ganzzahlige Gewichte und bildet die Kovarianzen direkt aus
Beobachtungspaaren; sie ruft den Produkt-Gram-Helfer nicht auf.

Für die Gegenprobe wurde ausschließlich in `negative-control/` die
ursprüngliche `R/fit.R` vom Rundenbeginn eingesetzt; der Arbeitsbaum blieb
unverändert. Aus dieser Paketkopie:

```sh
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/testthat '^fit-latent-(residual-weights|design-grid)$' \
  "$rework_dir/negative-control.rds"
```

`negative-control.log`, erwarteter Exit 1:

```text
[ FAIL 191 | WARN 0 | SKIP 0 | PASS 848 ]
Blocks: 12; failed expectations: 188; error blocks: 3; skipped: 0; elapsed: 26.657 s
```

Die alte Fassung erreicht unter anderem die gesperrten Engines und
entscheidet im Raster falsch. Drei Testfehler entstehen, weil der alte
interne Helfer die neuen Argumente weights/residual noch nicht besitzt.
Der aktuelle Code besteht dieselben zwölf Blöcke mit 1088 Erwartungen
innerhalb von P1. Die negative Gegenprobe ist kein rotes aktuelles Gate.

### P4 — echte Regeneration der neun Kurzlaufdateien

```sh
R CMD INSTALL --no-docs --library="$rework_dir/library" "$rework_dir/package/src"
python3 "$rework_dir/generate-checks.py"
```

Die Erzeugung lädt das installierte Paket über `R_LIBS`; sie liest
`n_sim = ANK-TOL.n_check` (20) und die 14 Worker aus ANK-TOL. Die drei
installierten Studienprogramme werden mit `--n-sim 20 --out <tmp>` und
unveränderten Szenario-Seeds ausgeführt. Erst nach erfolgreicher Erzeugung
und Bytevergleich werden die neun `_check_`-Dateien übernommen.
`generate-checks.log`:

```text
ordinal_recovery: 4 scenarios x 20 repetitions; 100 result rows; elapsed 110.598 s; workers 14
ordinal_recovery: exit=0; wall_seconds=111.392
binary_recovery: 2 scenarios x 20 repetitions; 40 result rows; elapsed 0.909 s; workers 14
binary_recovery: exit=0; wall_seconds=1.569
two_level: 2 scenarios x 20 repetitions; 42 result rows; elapsed 12.002 s; workers 14
two_level: exit=0; wall_seconds=12.659
Nine genuine short-run files copied byte-identically; no full-run files written in the repository.
```

Alle sechs CSVs melden `same_bytes_as_before=True`; nur die drei
Sessiondateien ändern sich. `session-hashes.log`:

```text
Current implementation: 815a3da5b543b3301f28c72da167f1ec1621410dac74e1298e00d822889a15ba
ordinal_recovery session matches current code
binary_recovery session matches current code
two_level session matches current code
```

**M1B-R4-INFRA-TIMEZONE — OUT-OF-TERRITORY [INFRA].** In allen drei
Erzeugungsprozessen meldet die unveränderte Sessionerfassung:

```text
Failed to connect to system scope bus via local transport: Operation not permitted
Warning message:
In system("timedatectl", intern = TRUE) :
  running command 'timedatectl' had status 1
```

Alle drei Prozesse enden mit Exit 0 und echten Ergebnisdateien. Kein
Scheinfix, keine künstliche Sessiondatei und keine abgeschaltete Prüfung.

### P5 — Mutation und Äquivalenzbelege

```sh
Rscript --vanilla "$rework_dir/prepare-mutations.R"
Rscript --vanilla "$rework_dir/native-mutations.R"
python3 "$rework_dir/run-mutations.py"
python3 "$rework_dir/rerun-survivors.py"
Rscript --vanilla "$rework_dir/equivalence-proofs.R"
Rscript --vanilla "$rework_dir/validate-claims.R"
```

**M1B-R4-INFRA-MUTTEST — OUT-OF-TERRITORY [INFRA].** Der native Versuch
mit unverändertem muttest scheitert an der lokalen IPC-Berechtigung;
`native-mutations.log`, Exit 1:

```text
Unmutated targeted suite: 18 blocks; failed expectations 0; errors 0; skips 0
Error in .dispatcher_start(url, urld, tls_cfg, serial, envir[["stream"]],  :
  16 | Permission denied
Calls: <Anonymous> ... <Anonymous> -> launch_dispatcher -> .dispatcher_start
Execution halted
```

Als zusätzliche Diagnose wurden die **von muttest erzeugten** 163 Mutanten
in isolierten Paketkopien mit 14 gewöhnlichen R-Prozessen geprüft. Die neun
Mutatorfamilien entsprechen dem Gate: arithmetic_operators,
comparison_operators, logical_operators, boolean_literals,
condition_mutations, numeric_literals, na_literals, string_literals,
index_mutations. Abgedeckt sind die Gewichtsprüfung, der gesamte ordinale/
latente Prüfblock und `msa_latent_information()`.

Der erste Lauf dauerte 226,932 s: 148 Killed, 13 Survived, 2 RuntimeError.
Die 13 Überlebenden wurden nach gezielten neuen Tests und Einbeziehung der
bereits vorhandenen Kontrastprüfung erneut geprüft. Echte Auszüge aus
`rerun-survivors.log`:

```text
41: Killed 317:16 <= → <
45: Killed 263:58 || → &&
64: Killed 420:33 FALSE → TRUE
82: Killed 264:53 <n> + 1 → <n> + 1
97: Killed 263:75 <n> - 1 → <n> - 1
119: Killed 306:60 <non-empty string> → ""
Previously surviving mutants rechecked: 13
Combined counts: {'Killed': 154, 'Survived': 7, 'RuntimeError': 2}
Rerun elapsed seconds: 30.762
Previous Killed results remain from unchanged expectations; no gate score or approval.
```

Der Endbericht ist `targeted-mutations-final.json`; der abschließende
unmutierte Vorlauf mit 25 Blöcken/1412 Erwartungen steht in P1. Die früher
getöteten Mutanten behalten ihre Belege aus unveränderten Erwartungen;
der Bericht behauptet keinen erneuten vollständigen Durchlauf aller 163.

**M1B-R4-INFRA-MUTPARSE — OUT-OF-TERRITORY [INFRA].** Die Mutanten 67
und 78 verändern die mehrzeilige Gewichtsbedingung syntaktisch ungültig:

```text
Failed to load 'R/fit.R'
Caused by error in `parse()`:
! At 'R/fit.R:265:9': unexpected '!'
```

Sie sind als RuntimeError ausgewiesen und nicht als Killed gezählt.
Produkt und Mutatorwerkzeug wurden dafür nicht angepasst.

`equivalence-proofs.log` enthält die Gegenprüfungen zu allen 17 Anträgen:
9837 positive Zählvektoren, 33 REML-Zustände einschließlich Grenzen,
200 gewichtete Pläne mit und ohne Restterm (400 Matrixvergleiche),
1400 Gruppierungsfaktoren, 200 exakt skalierte QR-Basen sowie die
Strukturbelege für Formelgruppierung, Spaltentypen, Literaltrennung,
REML-Design und den einzigen Exit-Handler. Schlussausgabe:

```text
Proved candidates: 17 ; no approvals written.
17 explicit claims map to 17 distinct mutants across 15 gate keys.
Every multiply matched key is wholly documented; no approvals written.
```

Sechs der sieben aktuellen Überlebenden sind diese belegten Äquivalente;
der ungeclaimte siebte steht bei E31. Vollständiges mutgate und dessen
Bewertung bleiben beim Orchestrator/Reviewer.

### P6 — Roxygen, Paketbau und installierter Paketcheck

Roxygen wurde ausschließlich in einer temporären Paketkopie ausgeführt.
`roxygen.log`: `msa_fit.Rd matches roxygen generation exactly.` Nur die
betroffene generierte Hilfeseite wurde ins Produkt übernommen; keine
Roxygen-Metadatenänderung. Danach wurde die Paketkopie aus dem finalen
Produktstand erneuert.

Aus `$rework_dir/package`:

```sh
R CMD build --no-manual src
_R_CHECK_CRAN_INCOMING_REMOTE_=false R CMD check --as-cran --no-manual llmsa_0.1.0.tar.gz
```

Beide Exit 0. `build.log`: Vignettenbau OK, `llmsa_0.1.0.tar.gz` erzeugt.
`check.log` und `package/llmsa.Rcheck/00check.log`:

```text
* checking examples ... OK
* checking examples with --run-donttest ... [40s/40s] OK
* checking tests ... [90s/90s] OK
* checking package vignettes ... OK
* checking re-building of vignette outputs ... [30s/30s] OK
* DONE
Status: 1 NOTE
```

Installierte Tests (`package/llmsa.Rcheck/tests/testthat.Rout`):

```text
[ FAIL 0 | WARN 0 | SKIP 9 | PASS 4633 ]
```

Die neun vorhandenen Skips: fünf im öffentlichen Tarball nicht enthaltene
API-Aufzeichnungen, zwei Vergleiche mit Repository-Ankern, der CRAN-Skip
des Reporttests und der ellmer-Negativtest. Die neuen Tests überspringen
nichts. Die Repository-Ausführung P1 prüft die dort verfügbaren Artefakte.

**M1B-R4-INFRA-CLOCK — OUT-OF-TERRITORY [INFRA].** Einzige Check-NOTE:

```text
* checking for future file timestamps ... NOTE
Unable to verify current time.  To disable remote verification,
set environment variable _R_CHECK_SYSTEM_CLOCK_ to a false value.
```

Die Zeitprüfung wurde nicht abgeschaltet. Im Konsolenlog ist außerdem
der nicht erreichbare CRAN-Index sichtbar (`cannot open URL
'https://cloud.r-project.org/src/contrib/PACKAGES'`); die Abhängigkeitsprüfung
endet trotzdem mit OK. `_R_CHECK_CRAN_INCOMING_REMOTE_=false` entspricht
dem bestehenden Harness-Aufruf. Keine neuen ERRORs oder WARNINGs im
Check-Ergebnis und keine Regel- oder Schwellenlockerung.

### P7 — territoriale und numerische Integrität

```sh
python3 "$rework_dir/integrity.py"
```

`integrity-final.log`, Exit 0, SHA-256-Vergleich gegen den zu Rundenbeginn
gesicherten Bestand:

```text
Baseline files: 325; changed existing files: 9; added files: 3; deleted files: 0.
Existing test files unchanged: 93.
All baseline files outside the explicit change list are byte-identical, including approvals, gates, anchors and criteria.
Six short-run CSVs are byte-identical to the baseline; all nine files match the genuine regeneration.
Checked package source matches the final repository inputs: 144 files.
```

Die neun geänderten Bestandsdateien sind `R/fit.R`, `NEWS.md`,
`man/msa_fit.Rd`, die drei `*_check_session.txt`, `PROGRESS.md` sowie die
zugewiesenen Handoffs `REWORK-NOTES.md` und `MUT-EQUIV.json`. Neu sind nur
die zwei oben genannten Unit-Dateien und Builder-ADR-033. Alle 93 alten
Dateien unter `tests/`, einschließlich Abnahme/QA/Fixtures, bleiben bytegleich.
Keine Golden-, Anker-, Spezifikations-, Gate-, Approval- oder
Abhängigkeitsänderung. Keine Git-Kommandos.

```sh
python3 "$rework_dir/numeric-integrity.py"
```

`numeric-integrity.log`, Exit 0, ausgeführter Quellsegment-Bytevergleich:

```text
Numeric helpers, variance extraction and print methods: byte-identical to the baseline.
Numeric engine dispatch and refit call construction: byte-identical to the baseline.
R/grr.R: byte-identical to the baseline.
```

### P8 — unveränderte AP1-Abnahme K-M2-6 und K-M2-7

```sh
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/acceptance '^m2-6-' "$rework_dir/acceptance-m2-6.rds"
REPO_ROOT="$repo_dir" NOT_CRAN=true Rscript --vanilla "$rework_dir/run-tests.R" \
  tests/acceptance '^m2-7-' "$rework_dir/acceptance-m2-7.rds"
```

`acceptance-m2-6.log`, Exit 0:

```text
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 383 ]
Blocks: 11; failed expectations: 0; error blocks: 0; skipped: 0; elapsed: 313.587 s
```

`acceptance-m2-7.log`, Exit 1:

```text
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 353 ]
Blocks: 9; failed expectations: 0; error blocks: 1; skipped: 0; elapsed: 250.668 s
```

**M1B-R4-INFRA-HTTP — OUT-OF-TERRITORY [INFRA].** Der einzige Testfehler
ist die lokale Socket-Erzeugung des unveränderten HTTP-Replay-Helfers,
vor einer Prüfung der Anfrage. Echter Stacktrace:

```text
Error ('test-m2-7-robustness-pilot.R:175:5'): K-M2-7: backend_openai_compatible() sends a non-empty design column system as system message before the user message, otherwise the argument system
Error: System failure for: socket() (Operation not permitted)
 1. acc_m2_backend(s, system = cs$arg)(...)
 2. httr2::req_perform(req) at llmsa/R/backends.R:177:5
 3. mock(req)
 4. httr2::req_dry_run(req, quiet = TRUE) at ./setup-m2.R:787:5
 5. curl::curl_echo(handle, progress = FALSE)
 6. httpuv::startServer("0.0.0.0", port, list(call = echo_handler))
 9. curl::find_port()
```

Alle acht anderen Blöcke bestehen. Insbesondere liefert der abschließende
Robustheits-/Auswertungsblock 165 bestandene Erwartungen und keinen
Fehler, einschließlich der latenten Fits. Insgesamt sind 353 Erwartungen
grün und keine Erwartung fachlich fehlgeschlagen. `R/backends.R`,
`R/acmg.R` und der Abnahmehelfer sind bytegleich zum Rundenbeginn.
Kein Eingriff in HTTP-Test, Produkt oder Socket-Berechtigungen; die
vollständige HTTP-Replay-Bestätigung bleibt beim Betreiber-Gate.

