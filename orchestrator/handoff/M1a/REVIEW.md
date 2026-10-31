# REVIEW — M1a, Runde 5 (Code-Review)

Rolle: Reviewer · Phase: `50-code-review` · Runde: 5 · Stand: 31.10.2026

Gegenstand:
- der Diff seit `plan/M1a` (Commit `485c9605…`) bis HEAD `8223d1a…`; Schwerpunkt ist der Rework-Commit `f25ff79…` gegenüber dem Review-Commit `b0d2854…` der Runde 4;
- die Gate-Fakten `orchestrator/state/M1a/gates.json` der Runde 5 (`env.sha` `f25ff79`) mit allen `gate-*.log` und dem Mutationsbericht `reports/mutation/mutation.json`;
- `REWORK-NOTES.md` und die zehn Anträge in `MUT-EQUIV.json`.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren). Dazu `orchestrator/prompts/60-rework.md`, weil der Builder sich zu E55 auf diesen Auftrag beruft.
- **Handoff M1a:**
  - `CRITERIA.json` (K-M1a-1 bis K-M1a-7, ACC-1 bis ACC-18);
  - `REVIEW.md` und `verdict-code.json` der Runde 4, `REWORK-NOTES.md` der Runde 5, `MUT-EQUIV.json`, `MUT-EQUIV-APPROVED.json` (Stand Runde 4);
  - `QA.md` (QA-M1a-001 bis -005; alle QA-Tests grün und unverändert).
  - Nicht vorhanden: `ARBITER.md`, `REVIEW-INPUT.md`.
- **Spezifikation:**
  - K-M1a-1 bis K-M1a-7 im Wortlaut (`docs/02-statistikkern.md`, über `CRITERIA.json`); das trace-Gate bestätigt die wörtliche Verknüpfung;
  - `docs/01-fachspezifikation.md` §2 Nr. 1, 4 und 7;
  - ADR-018 Nr. 1 bis 3, ADR-020 mit dem Nachtrag Runde 5, ADR-022 Nr. 6 und 7 mit den Konsequenzen.
- **Gates:** `gates.json` und alle acht `gate-*.log` der Runde 5; `mutation.json` mit 1107 Mutanten; zum Vergleich `gate-mutgate.log` und `gate-tests.log` der Runde 4 aus Commit `5757a24`.
- **Diff, vollständig gelesen:**
  - `R/fit.R` ganz (Stand `f25ff79`) und als `diff -u` gegen `b0d2854`;
  - die Diffs zu `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md` und ADR-020 (angehängter Nachtrag Runde 5);
  - die neue Datei `tests/testthat/test-fit-model-construction.R` ganz, dazu `helper-m1a-rework.R` und `helper-validation-numeric.R`;
  - zur Frage, welche Warnungen die neuen Handler fangen können: die lme4-Quellen (2.0.6) von `lFormula` mit `mkFormula`, `mkLmerDevfun` und `mkMerMod`;
  - im Gesamtdiff seit `plan/M1a` zusätzlich die einzige geänderte ältere Testdatei `tests/testthat/test-acmg-evaluate.R`: rein additiv (ein neuer Block), nichts abgeschwächt.
- **Visuelle Artefakte:** keine; M1a fordert keine (`orchestrator/state/M1a/shots/` ist leer).

## Gate-Fakten

| Gate | Runde 5 (`gates.json`, `env.sha` `f25ff79`) |
| --- | --- |
| deps | pass (22 Anforderungen, R 4.6.1, lme4 2.0.6, Matrix 1.7.4) |
| lint | pass (`R CMD check --as-cran`: Status OK, Vignetten neu gebaut, Rd und Code/Doku-Abgleich OK) |
| tests | pass |
| trace | pass |
| territory | pass (builder/60-rework, Runde 5) |
| mutgate | pass: score=93.83 required=91.79 baseline=93.83 floor=80 |
| golden-adr | pass |
| mutfull | pass („nicht fällig in M1a“) |
| **result** | **pass** |

- **tests:**
  - `tests/testthat`: `[ FAIL 0 | WARN 0 | SKIP 1 | PASS 2809 ]` (Runde 4: 2680; die 129 neuen Erwartungen stammen aus `test-fit-model-construction.R`); der Skip ist der bekannte ellmer-Negativtest;
  - `tests/acceptance`: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3070 ]`, unverändert;
  - `tests/e2e`: `PASS 23`, `tests/fuzz`: `PASS 12`; alle QA-Tests grün und unverändert.
  - Die Berichte zu `SmLs07`–`SmLs09` enden wie in Runde 4 benannt mit „not representable“ (`gate-tests.log`; nach ADR-022 Nr. 6.3 zulässig, kein Kriterium).
- **mutgate:**
  - unmutierter Vorlauf 90,7 s, 283 Tests, 0 rot; Zeitlimit 454 s je Mutant;
  - Bericht: 1107 Mutanten (`R/fit.R` 865, `R/grr.R` 242): 939 Killed, 34 Timeout, 65 Survived, 0 NoCoverage, 69 RuntimeError;
  - `required` 91,79 = alte Baseline 93,79 − Ratchet 2; das Gate hat die Baseline auf 93,83 angehoben.
  - Nachrechnung mit der Zuordnung des Gates (`86-mutgate.sh:29–47`): 973 / (973 + 65 − 1) = 93,83 trifft den Gate-Wert. Von den zehn Approvals der Runde 4 traf nur `R/grr.R:94`; die neun `R/fit.R`-Einträge zeigten auf um fünf Zeilen verschobene Stellen ohne passenden Überlebenden (BL-85). Der Score ist also nicht verfälscht. Ohne jede Approval: 93,74, ebenfalls über der Schwelle.
- **Status error:** keiner. Kein Gate-Befund ist [INFRA].
- **Laufzeit (BL-13):** Gate-Lauf 19:57–01:06, also ≈ 5 h 9 min:
  - deps und lint ≈ 3 min;
  - tests ≈ 19 min (Abnahme 1047,4 s, testthat 67,7 s, e2e 2,8 s, fuzz 1,1 s);
  - mutgate ≈ 4 h 47 min, ein muttest-Durchgang mit 17.142,0 s über 1107 Mutanten, 34 Timeouts.

## Eigene Nachprüfung (ausgeführt, ohne Git-Kommando)

**Methode:**
- Den Diff habe ich mit einem eigenen R-Leser für lose Objekte unter `.git/objects` gelesen (Commit → Baum → Blob), die Bäume von `b0d2854` und HEAD verglichen und die Dateien mit `diff -u` gegenübergestellt.
- Arbeitsbaum = HEAD: `R/fit.R`, `R/grr.R`, die neue Testdatei, `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md`, ADR-020, `MUT-EQUIV.json`, `REWORK-NOTES.md`, `test-fit-initialization.R`, `DESCRIPTION`, `NAMESPACE`, `BACKLOG.md` und `MUT-EQUIV-APPROVED.json` gleichen den HEAD-Blobs (vor meinen Schreibvorgängen). `R/fit.R` hat SHA-256 `fff305a2…` wie in REWORK-NOTES, `R/grr.R` unverändert `c468f439…`. Der Quelltext im Mutationsbericht gleicht dem Arbeitsbaum.
- Gerechnet habe ich mit `pkgload::load_all()` gegen den Arbeitsbaum. Der Code der Runde 4 lief aus dem Blob von `b0d2854` in einer Kindumgebung des Namensraums.
- Hilfsdateien lagen nur unter `reports/rv-m1a-r5/` (git-ignoriert, Artefakt-Allowlist) und sind gelöscht.

1. **Inventar.**
   - `b0d2854` → HEAD: 21 Pfade.
     - 8 Builder-Pfade: `R/fit.R`, `man/msa_fit.Rd`, `NEWS.md`, `PROGRESS.md`, ADR-020, die neue `tests/testthat/test-fit-model-construction.R`, `REWORK-NOTES.md`, `MUT-EQUIV.json`;
     - sonst Gate- und Orchestrator-Zustand, `summary.json` und `STATUS.md`.
   - Unverändert: alle bestehenden Testdateien, `tests/acceptance/**`, `tests/e2e/**`, `tests/fuzz/**`, `tests/fixtures/**`, `reference/anchors/**`, `inst/**`, `R/grr.R`, `DESCRIPTION`, `NAMESPACE`, `BACKLOG.md`, `MUT-EQUIV-APPROVED.json`.
2. **Produktdiff.**
   - `R/fit.R:514–516`: eine lokale Funktion `not_representable()` mit der vorhandenen Meldung „Numeric model variance is not representable on the original scale at working precision.“ (`call. = FALSE`). Die Prüfungen davor (`:517–520`) und danach (`:545–548`) nutzen sie; Text und Bedingungen sind unverändert.
   - `R/fit.R:526–530`: `lFormula`, `mkLmerDevfun` und `devfun(theta)` stehen in einem `tryCatch` mit `warning = not_representable, error = not_representable`. `R/fit.R:541–544`: ebenso `mkMerMod` und `VarCorr`.
   - `checkConv` (`R/fit.R:537`) steht zwischen beiden Blöcken, außerhalb der Behandlung; Warnungen und Diagnose bleiben.
   - Zuweisungen im `tryCatch`-Ausdruck (`original`, `devfun`, `model`) landen im Rahmen von `msa_numeric_fit()`; `tryCatch` registriert dort kein `on.exit`. Der Weitergabe-Handler `R/fit.R:466` bleibt das einzige `on.exit` und gibt Startwarnungen bei einem Abbruch weiter.
   - Welche Warnungen können die Handler im Vorgabepfad treffen? `lFormula` prüft mit derselben festen `lmerControl(optimizer = "nloptwrap")` dieselbe Struktur wie der Aufruf `R/fit.R:458` auf der konditionierten Antwort; unter den festen Vorgaben steht nur `check.scaleX` auf „warning“, und X ist hier nur der Achsenabschnitt. `mkLmerDevfun` und `mkMerMod` rufen selbst kein `warning()` auf. Übrig bleiben im Wesentlichen numerische Warnungen aus Matrix/CHOLMOD beim Auswerten von `devfun`; genau die Fälle von E54. Eine strukturelle Warnung würde schon `R/fit.R:458` ungefangen melden.
   - Sonst nur roxygen (`R/fit.R:69–70`, `:85–90`), `man/msa_fit.Rd` (deckungsgleich mit roxygen) und ein Satz in `NEWS.md`.
3. **E54, Reproduktionen.** Alle drei Fälle aus REVIEW r4 E54 enden jetzt mit „Numeric model variance is not representable on the original scale at working precision.“, Klasse `simpleError/error/condition`, Aufruf `NULL`, ohne Warnung. Mit dem Code der Runde 4: `Rcpp::exception` „Downdated VtV is not positive definite“, beim zweiten Fall mit zwei Warnungen. Der positive Gegenfall (e = 1e-3, S = 1001) fittet über `closed_form` ohne Warnung: 1,1396, 0,49438, 0,066438, Rest 1,7162e-6; Abweichung von den aov-EMS-Schätzern 1,4e-14 · σ²_TV.
4. **Breitenprobe mit eigenen Seeds** (unabhängig von den Seeds des Builders und der Runde 4).
   - Aufbau: vier Pläne (Items × Prompts × Modelle × Replikate) 6 × 4 × 1 × 2, 8 × 3 × 1 × 3, 10 × 3 × 2 × 2 (alle Zweifach-Wechselwirkungen) und 5 × 5 × 1 × 3; Effekte mit Seed 21; Replikatrauschen 1e-3 bis 1e-10; Seeds 3001–3005; je balanciert und mit drei zufällig entfernten Zeilen (analytischer Pfad mit lme4-Start). 320 Eingaben, jeweils mit dem Code der Runden 4 und 5.
   - Runde 4: 10 rohe Abbrüche (`Rcpp::exception` „Downdated VtV …“), alle balanciert über die geschlossene Lösung, aov-RSS/SST 6,1e-17 bis 3,6e-15. Runde 5: 0. Alle zehn enden jetzt benannt mit „not representable“.
   - Matrix-/CHOLMOD-Warnungen beim Aufrufer: Runde 4 acht in vier Fits (10 × 3 × 2 × 2, Rauschen 1e-7, Seeds 3002–3005; drei davon roh, einer benannt). Runde 5: keine.
   - Alle übrigen 310 Ausgänge sind in Meldung und Warnungen gleich. Die 74 erfolgreichen Fits (60 `closed_form`, 14 `analytic_reml`) sind bitgleich (`vc`, `numerics`, Warnungen). Kein Fit kippt von Erfolg zu Fehler oder umgekehrt.
   - Die 60 balancierten Erfolge treffen die unabhängig aus `stats::aov` gerechneten EMS-Schätzer auf höchstens 1,6e-9 · σ²_TV (`ANK-TOL.oracle` 1e-4).
   - Ausgänge Runde 5: 74 Fits, 41 × „not representable“, 68 × „residual variance cannot be resolved“, 63 × „initialization failed“, 73 × „Analytic REML did not converge“, 1 × „not identifiable“, 0 roh.
5. **Testwirksamkeit (docs/01 §2 Nr. 1).** `test-fit-model-construction.R` gegen `msa_numeric_fit()` der Runde 4: 15 von 18 Blöcken rot, 47 Erwartungen falsch. Gegen Runde 5: 129 richtig. Das deckt die Angabe in REWORK-NOTES. Grün bleiben gegen Runde 4 nur der positive Gegenfall, der Konvergenztest und der Durchreichweg, wie dort angegeben.
6. **Neue Tests gegen rechnerisch gleichwertige Varianten** → **E58.**
   - In Runde 4 überlebten `R/fit.R:329` (`Matrix::Matrix(cross, sparse = TRUE)`, `TRUE → FALSE`) und `:340` (`Matrix::Cholesky(B, LDL = FALSE, perm = TRUE)`, `TRUE → FALSE`). In Runde 5 sind beide Killed.
   - Beide Mutanten rechnen dieselbe Zerlegung, nur dicht gespeichert bzw. ohne füllmindernde Permutation. Mit ihnen enden die E54-Eingaben benannt mit „Numeric model residual variance cannot be resolved at working precision.“ (`R/fit.R:343`): `:329` in allen drei Fällen, `:340` bei e = 1e-8, S = 1001. Rot werden nur die zugehörigen Reproduktionsblöcke (3 bzw. 1 von 18), weil deren Fehlerzweig genau die Darstellbarkeitsmeldung verlangt.
7. **Warnung von `checkConv` vor dem benannten Fehler** → **E59.** In 30 der 160 balancierten Fits der Breitenprobe (Rauschen 1e-6: 20 von 20; 1e-7: 10 von 20) erreicht „Hessian is numerically singular: parameters are not uniquely determined“ (dreimal zusätzlich „unable to evaluate scaled gradient“) den Aufrufer, danach endet der Fit mit „not representable“. Ebenso mit dem Generator der neuen Testdatei, `model_build_runs(1e-6, 1001L)`, `1002L`, `1003L` und `model_build_runs(1e-7, 1001L)`. Runde 4 verhält sich in allen 30 Fällen gleich; kein Rückschritt.
8. **Mutation.**
   - Die 65 Überlebenden gleichen nach Quelltext denen der Runde 4 (66) mit zwei Ausnahmen: `:329` und `:340` sind getötet (Nr. 6), neu überlebt `R/fit.R:514` `NULL → NA` (E57).
   - Mutanten in den neuen Zeilen: `:514` `NULL → NA` überlebt; `:515` `<non-empty string> → ""` und `FALSE → TRUE` (`call.`) sind getötet. Der in den Block verschobene `lFormula`-Aufruf (`:527`, `TRUE → FALSE`) ist getötet.
9. **MUT-EQUIV:** jeden Antrag einzeln gegen Bericht, Quelltext und Verhalten geprüft (Abschnitt MUT-EQUIV).

## Bewertung

### Spec- und Vertragstreue

- K-M1a-1 bis K-M1a-7: Alle Abnahmetests sind grün, die Vignette baut im lint-Gate. Die Änderung berührt keinen Abnahmepfad; erfolgreiche Fits sind bitgleich zur Runde 4 (Nachprüfung 4).
- **E54 ist erledigt.**
  - Der Modellbau auf der Originalskala endet bei Fehler oder Warnung der Engine benannt mit der Meldung aus ADR-022 Nr. 6.2: kein `Rcpp::exception`, keine Matrix- oder CHOLMOD-Warnung beim Aufrufer (ADR-022 Nr. 7 sinngemäß), Klasse `simpleError` ohne Aufruf.
  - `checkConv` bleibt aktiv und außerhalb der Behandlung, wie im Vorschlag zu E54 verlangt; Startwarnungen gehen bei einem späteren Abbruch weiter an den Aufrufer (ADR-020, E17). Der Durchreichweg nach ADR-018 Nr. 2 ist unberührt.
  - Kein Ersatzwert, kein Rückfall auf eine lme4-Optimierung, keine geänderte Nullgrenze oder Präzisionsgrenze.
- ADR-022 Nr. 6.1 und 6.2: In der Breitenprobe gibt es kein stilles Ergebnis. Die 60 balancierten Erfolge treffen die unabhängigen EMS-Schätzer, die 14 unbalancierten sind bitgleich zur Runde 4, alle anderen Ausgänge sind benannt.
- Kein Widerspruch zwischen Spec-Stellen, also kein ESCALATE.

### API-Diff

- `NAMESPACE`, Signaturen und Vorgaben sind unverändert; der API-Snapshot-Test (ANK-02) ist grün.
- Neu ist nur, dass der Vorgabepfad an einer weiteren Stelle mit der vorhandenen benannten Meldung endet statt roh. Das steht in ADR-020 (Nachtrag Runde 5), `?msa_fit` (`R/fit.R:69–70`) und `NEWS.md`.
- `?msa_fit`, `R/fit.R:85–90`, nennt jetzt den Modellbau als Fehlerstelle und ordnet die Hesse-Warnung von `checkConv` der θ-Skala zu. Beides habe ich nachgerechnet (Nachprüfung 4 und 7); es stimmt.

### Integrität

- **Entkernte oder geänderte Tests:** keine. Der Rework fügt eine Datei hinzu; alle bestehenden Test-, Abnahme-, QA- und Fixture-Dateien sind blob-gleich.
- **Gelockerte Konfiguration:** keine.
- **Harte Erwartungswerte:** keine. Rauschpegel und Seeds sind Eingaben; die Nullgrenze (64 · eps)² dient nur als Vorbedingung; die Toleranz kommt aus `ANK-TOL.oracle` (die installierte Kopie unter `inst/validation/numeric/anchors/` ist bytegleich mit `reference/anchors/`).
- **Erfundene Daten:** keine. Die synthetischen Testdaten sind als solche gekennzeichnet (Z. 1–2).
- **Golden-Daten und Anker:** unverändert.

### Neue Tests

- Die Tests belegen Verhalten gegen unabhängige Referenzen:
  - **Reproduktionen** (Z. 61–75): Vorbedingungen und Referenz aus `stats::aov` mit den expliziten Zweifaktor-EMS-Formeln (Formelsammlung §2), nicht aus dem EMS-Löser des Produkts. Gelingt der Fit, müssen die Komponenten diesen Schätzern gleichen; scheitert er, muss er benannt enden. Matrix-/CHOLMOD-Warnungen sind in beiden Zweigen verboten.
  - **Positiver Gegenfall** (Z. 77–84): `closed_form`, keine Warnung, EMS-Gleichheit, Originalantwort im Modell (ADR-018 Nr. 1).
  - **Synthetische Bedingungen** (Z. 86–124) an allen fünf Engine-Grenzen, je Fehler und Warnung, über `local_mocked_bindings(.package = "lme4")`; sie zählen die Treffer und prüfen, dass keine Warnung durchsickert. Sie hängen nicht von der Plattform ab.
  - Warnung mit folgendem Fehler (Z. 126–137), aktive Konvergenzprüfung (Z. 139–155), Startwarnungen in Reihenfolge nach einem späteren Abbruch (Z. 157–183) und unveränderte Bedingungen im Durchreichweg (Z. 185–195).
  - Eigene Ausgabe ist nur der Meldungstext. Er ist als solcher gekennzeichnet (Z. 52–53) und von ADR-022 Nr. 6.2 vorgegeben.
- Lücke: Der Fehlerzweig der Reproduktionen hängt an der Rundung im konditionierten Schritt → E58.

## Stand der Einwände aus Runde 4

Der Builder beantwortet alle IDs Punkt für Punkt (REWORK-NOTES).

| ID | Stand | Beleg |
| --- | --- | --- |
| E54 | erledigt | Nachprüfungen 2 bis 5; `R/fit.R:514–548`; `test-fit-model-construction.R` |
| E55 | offen, nonblocking. Der Builder lehnt den Umbau ab: Der Rework-Auftrag verbietet Änderungen bestehender Tests (`orchestrator/prompts/60-rework.md:5,7`). Die Begründung trifft zu; der Befund war nicht verlangt | BL-89, neuer Stand → E58 |
| E56 | erledigt, soweit verlangt: `?msa_fit` (`R/fit.R:85–90`) und ADR-020 Nachtrag Runde 5 mit balancierter Gegenrechnung. Robustheitsnachweis und Abbruchkriterium bleiben offen | BL-87, neuer Stand → E59 |
| E53 | `:272` (vorher 267) erneut beantragt und freigegeben; der Rest ist nicht verlangt und bleibt offen | BL-84 |
| E48 | offen, Betreiber; Approvals in dieser Runde neu gebunden (Abschnitt MUT-EQUIV) | BL-85 |
| E49 | offen, Betreiber; der Builder bestätigt beide Befunde mit Log-Beleg | BL-86 |
| E39, E41, E42 | offen, Betreiber | BL-77, BL-79, BL-80 |
| E43 | vertagt nach M1b | BL-81 |

## Einwände

### Blocking

Keine.

### Nonblocking

- [E57] (minor) `reports/mutation/mutation.json` (Gate-Lauf Runde 5): `R/fit.R`, Zeile 514, `mutatorName` „NULL → NA“, Status Survived; `orchestrator/prompts/60-rework.md:7` („Produktcode änderst du dafür nur dort, wo ein Mutant toten oder überflüssigen Code zeigt.“) — **Befund:**
  - `not_representable <- function(condition = NULL)` (`R/fit.R:514`) benutzt `condition` nie. Als Handler erhält die Funktion die Bedingung, bei den direkten Aufrufen (`:519`, `:547`) bleibt das Argument fehlend und wird nie ausgewertet. Der Vorgabewert ist toter Code, der Mutant `NULL → NA` ist äquivalent.
  - Einziger neuer Überlebender dieser Runde; das mutgate ist grün.

  — **Vorschlag:**
  - Code entfernen: Vorgabewert oder Argument streichen, etwa `function(...)`.
  - Alternativ den Mutanten in `MUT-EQUIV.json` beantragen.
  - Nicht verlangt. BL-84.
- [E58] (minor) AGENTS.md:125, Projektblock, Parallelisierung („Windows-CI ist Release-Bedingung“); ADR-012, Kontext; REVIEW r4 E55; REWORK-NOTES Runde 5 zu E55 („Die neuen E54-Reproduktionstests erzwingen keinen plattformabhängigen Engineabbruch …“) — **Befund:**
  - Die Reproduktionsblöcke `tests/testthat/test-fit-model-construction.R:61–75` verzweigen nach dem Ausgang. Im Fehlerzweig verlangt `model_build_expect_failure()` (Z. 49–59) aber genau die Darstellbarkeitsmeldung.
  - Ob die Eingaben den Modellbau überhaupt erreichen, hängt an der Rundung im konditionierten REML-Schritt. Mit den rechnerisch gleichwertigen Varianten `R/fit.R:329` (`sparse = FALSE`) und `:340` (`perm = FALSE`) enden dieselben Eingaben benannt mit „Numeric model residual variance cannot be resolved at working precision.“ (`:343`). Das ist eine zulässige benannte Meldung (ADR-018 Nr. 3, docs/01 §2 Nr. 4), trotzdem werden 3 bzw. 1 der 18 Blöcke rot. Deshalb tötet der Mutationslauf diese beiden Mutanten jetzt (Nachprüfung 6).
  - Mit einer anderen Matrix-, CHOLMOD- oder BLAS-Version kann dasselbe geschehen; dann ist der Test rot, obwohl `msa_fit()` benannt endet. Belegt ist das nicht: geprüft ist nur Linux, die CI läuft erst nach einem Push (`PUSH_REMOTE=0`). Den Modellbauvertrag prüfen die synthetischen Blöcke (Z. 86–124) ohne Abhängigkeit von der Plattform.

  — **Vorschlag:**
  - Im Fehlerzweig der Reproduktionen jede dokumentierte benannte Präzisionsmeldung des Vorgabepfads zulassen („… not representable …“, „… residual variance cannot be resolved …“). Rohe Enginefehler und durchgesickerte Matrix-/CHOLMOD-Warnungen bleiben verboten.
  - Zusammen mit E55 in einer Build-Phase umsetzen, weil der Rework-Auftrag Änderungen bestehender Tests ausschließt.
  - Nicht verlangt. BL-89.
- [E59] (minor) ADR-018 Nr. 3 (`docs/decisions/ADR-018-m1a-vorgabepfad-numerischer-fit.md:56–58`: „Warnungen eines lme4-Laufs im Vorgabepfad gehen nicht verloren. … Welches von beiden gilt, legen das numerische ADR und `?msa_fit` fest“); `?msa_fit` (`R/fit.R:85–90`); BL-87 (E51, E56) — **Befund:**
  - `checkConv` (`R/fit.R:537`) läuft vor dem zweiten Modellbaublock (`:541–544`) und vor der letzten Darstellbarkeitsprüfung (`:545–548`). Endet einer davon benannt, hat der Aufrufer schon die Konvergenzwarnung eines Modells erhalten, das verworfen wird.
  - Dort meldet sie „Hessian is numerically singular: parameters are not uniquely determined“ für ein balanciertes, identifizierbares Modell (E56: Artefakt der θ-Skala). Neben dem Fehler „not representable“ führt sie in die falsche Richtung.
  - Häufigkeit: 30 der 160 balancierten Fits der Breitenprobe (Rauschen 1e-6: 20 von 20; 1e-7: 10 von 20). Reproduktion mit dem Generator der neuen Testdatei: `msa_fit(model_build_runs(1e-6, 1001L))`. Runde 4 verhält sich gleich; kein Rückschritt.
  - ADR-022 Nr. 7 (`docs/decisions/ADR-022-m1a-code-review-auslegungen.md:53`) ist nicht verletzt (lme4-Warnung, nicht Matrix oder CHOLMOD), und die Warnung geht nicht verloren.

  — **Vorschlag:**
  - Die Warnungen von `checkConv` sammeln und erst nach der letzten Darstellbarkeitsprüfung ausgeben; die Diagnose im Modell (`optinfo$conv$lme4`) bleibt unverändert.
  - Oder den Fall in `?msa_fit` nennen.
  - Mit BL-87, spätestens vor M1d. Nicht verlangt.

[INFRA]: Zu E48 und E49 gibt es nichts Neues für den Builder. Den Stand führen BL-85 und BL-86.

## MUT-EQUIV

**Grundlage:**
- zehn Anträge in `MUT-EQUIV.json`: neun `R/fit.R`-Einträge auf um fünf Zeilen verschobenen, textgleichen Zeilen (fünf neue roxygen-Zeilen), `R/grr.R:94` unverändert. Sie betreffen zwölf überlebende Mutanten im Gate-Bericht der Runde 5.
- Jeden Antrag habe ich gegen `reports/mutation/mutation.json` (Datei, `mutatorName`, Zeile, Spalte, Status Survived) und gegen den Quelltext geprüft. Auf keiner der Zeilen gibt es weitere Überlebende desselben `mutatorName`.
- Für die elf `R/fit.R`-Mutanten habe ich je eine mutierte Kopie von `R/fit.R` (Ersetzung genau an der Berichtsspalte) in eine Kindumgebung des Namensraums geladen und Ende-zu-Ende verglichen. Eingaben: 19, nämlich `ic50_demo`, drei balancierte und zwei unbalancierte Simulationen, die drei E54-Reproduktionen, der positive Gegenfall, ein Fit mit Hesse-Warnung, Zeichenwerte, schlichter Datenrahmen und schlichte Liste, identische Werte, Einweg- und Zwei-Item-Plan, der Durchreichweg, sowie zwei Fälle mit synthetischen Startwarnungen (analytischer Pfad, einmal mit Modellbaufehler, einmal mit Erfolg). Verglichen wurden `vc`, `numerics`, `n`, `singular`, θ, Antwort, `optinfo`, `devcomp`, β, u, Warnungen und Fehler (Klasse, Meldung, Aufruf). Kontrolle: unmutiert gegen unmutiert gleich.

**Ergebnis:** Alle zehn sind echte Äquivalenzen und stehen in `MUT-EQUIV-APPROVED.json`.

| Datei:Zeile | `mutatorName` | Quelltext (Stand `f25ff79`) | Nachprüfung in Runde 5 |
| --- | --- | --- | --- |
| `R/fit.R:238` | `+ → -` (3 Mutanten, Spalten 37, 46, 54) | `stats::aggregate(y ~ item + prompt + model + block, …)` | Textgleich mit r4:233 (Freigabe Runde 4). Jeder der drei Mutanten ist auf 19 Eingaben identisch. |
| `R/fit.R:118` | `FALSE → TRUE` | `as.data.frame(runs, stringsAsFactors = FALSE)` | Textgleich mit r4:113. Identisch auf 19 Eingaben, auch mit Zeichenwerten, schlichtem Datenrahmen und schlichter Liste. |
| `R/fit.R:357` | `<n> + 1 → <n> + 1` | `gram <- curvature <- matrix(0, k, k)` | Textgleich mit r4:352. Die Doppelschleife schreibt jedes Element vor dem ersten Lesen; identisch auf 19 Eingaben. |
| `R/fit.R:357` | `<n> - 1 → <n> - 1` | wie oben | wie oben |
| `R/fit.R:458` | `TRUE → FALSE` | `lme4::lFormula(form, data = scaled, REML = TRUE, …)` | Textgleich mit r4:453. Genutzt wird nur `reTrms` (Z. 459, 461, 462, 471); der Modellbau ruft `lFormula` mit eigenem `REML = TRUE` (Z. 527). Identisch auf 19 Eingaben. |
| `R/fit.R:460` | `TRUE → FALSE` | `strsplit(names, ":", fixed = TRUE)` | Textgleich mit r4:455; identisch auf 19 Eingaben. |
| `R/fit.R:466` | `TRUE → FALSE` | `on.exit(…, add = TRUE)` | Textgleich mit r4:461. Es bleibt das einzige `on.exit` in `msa_numeric_fit()`; die neuen `tryCatch`-Blöcke und `not_representable()` registrieren keines im Rahmen der Funktion. Identisch auf 19 Eingaben, auch beim Modellbaufehler mit zwei weitergegebenen Startwarnungen. |
| `R/grr.R:94` | `> → >=` | `… else if (grr_v > 0) … else Inf` | `R/grr.R` ist blob-gleich; die Freigabe der Runden 3 und 4 trifft weiter. |
| `R/fit.R:272` | `<n> + 1 → <n> + 1` (`counts[1]` → `counts[2]`) | `if (length(counts) != prod(sizes) \|\| any(counts != counts[1])) {` | Textgleich mit r4:267. Einziger Produktaufrufer bleibt `msa_numeric_fit()` (Z. 463) mit `item` in `factors`, also `prod(sizes)` ≥ 2; nach dem Kurzschluss ist „alle gleich `counts[1]`“ gleichwertig mit „alle gleich `counts[2]`“. Identisch auf 19 Eingaben, darunter Einweg- und Zwei-Item-Plan. |
| `R/fit.R:272` | `x[<i>] → x[<i> + 1L]` (`counts[1 + 1L]`) | wie oben | wie oben |

- **Wirkung:**
  - Mit der Zuordnungslogik des Gates nachgerechnet: Die Freigaben treffen genau diese zwölf Überlebenden.
  - Auf den Bericht der Runde 5 angewandt ergäbe sich 973 / (973 + 65 − 12) = 94,83. Mit den alten Approvals sind es 93,83, ohne Approval 93,74.
  - `mut-baseline` schreibt nur das Gate.
- **Nicht beantragt und nicht freigegeben:** `R/fit.R:514` `NULL → NA` (E57).
- **Bindung an den Stand:** Die Freigaben gelten für `f25ff79` (`R/fit.R` SHA-256 `fff305a2…`, `R/grr.R` `c468f439…`). Verschiebt eine spätere Änderung Zeilen, gleicht das nächste Review jede Freigabe mit dem neuen Bericht ab (BL-85).

## Verdict

**PASS.**

- `gates.json` meldet `result: pass`; `blocking` ist leer. E54, der einzige blocking-Befund der Runde 4, ist behoben und nachgerechnet.
- Nonblocking: E57, E58 und E59.
  - BACKLOG: neuer Stand in BL-13, BL-84 (E57), BL-85, BL-86, BL-87 (E59) und BL-89 (E58).
- Kein Spec-Widerspruch, kein ESCALATE.

## Geschriebene Dateien

- `orchestrator/handoff/M1a/REVIEW.md` (diese Datei);
- `orchestrator/handoff/M1a/verdict-code.json` (`round: 5`);
- `orchestrator/handoff/M1a/MUT-EQUIV-APPROVED.json` (zehn Freigaben auf den Zeilen von `f25ff79`);
- `BACKLOG.md`: neuer Stand in BL-13, BL-84, BL-85, BL-86, BL-87 und BL-89.

Keine Git-Kommandos. Ich habe weder Produktcode noch Tests, Gates oder Orchestrator-Zustand geändert.
