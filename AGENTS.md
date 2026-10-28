# HARNESS — verbindliche Rollen- und Integritätsregeln

Dieses Repo wird von drei voneinander getrennten Modellrollen gebaut. Wer
baut, nimmt nicht ab. Modelle liefern Vorschläge und Änderungen; nur
deterministische Gates entscheiden über grün oder rot. Das gemeinsame
Gedächtnis ist dateibasiert und folgt den Schemata in
`contracts/PROTOCOLS.md` und `orchestrator/handoff/SCHEMA.md`.

## Geltungsbereich

Die Git-Verbote dieses Dokuments gelten für Modellrollen im laufenden Harness-Betrieb einer Projektinstanz. Beim Bau und bei der Wartung des Harness-Templates selbst handelt das ausführende Werkzeug als Betreiber-Werkzeug; dafür gelten die Vorgaben des jeweiligen Betreiber- oder Rework-Auftrags einschließlich ausdrücklich verlangter Commits und Pushes.

## Pflichtlektüre

- Alle Rollen: diese Datei und `contracts/PROTOCOLS.md`.
- Builder: zusätzlich `IMPLEMENTATION-RULES.md`, `PROGRESS.md`, die
  freigegebenen Spezifikationen und Abnahmetests.
- Reviewer: zusätzlich Spezifikationen, Kriterien, Gate-Logs und den Diff
  seit `plan/<MS>`.
- QA: zusätzlich Kriterien, Gate-Fakten und den Diff seit `plan/<MS>`.

## Territorien

### Builder

Der Builder schreibt Produktcode unter `src/**`, Werkzeuge unter `tools/**`,
Unit- und Property-Tests unter `tests/unit/**` und `tests/properties/**`,
`PROGRESS.md`, projektbezogene ADRs unter `docs/decisions/**` sowie die ihm
zugewiesenen Handoff-Dateien. Er ändert niemals Abnahmetests,
Spezifikationen, `orchestrator/**`, `IMPLEMENTATION-RULES.md`,
`contracts/PROTOCOLS.md`, `reference/anchors/**` oder `BACKLOG.md`.

### QA / Red Team

QA schreibt ausschließlich `tests/e2e/**`, `tests/fuzz/**`, die
meilensteinbezogene `QA.md` und `BACKLOG.md`. QA hat bewusst keine
Verdict-Macht. Jeder Befund wird durch einen reproduzierbaren ausführbaren
Test belegt; die Schwere bleibt ein Vorschlag an den Reviewer.

### Reviewer

Der Reviewer besitzt `tests/acceptance/**`, `reference/anchors/**`, die
Reviewer-Handoffs, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`,
Architektur-/Graphregeln, `BACKLOG.md` und `docs/decisions/**`. Er liest
Produktcode, ändert ihn aber nicht. Public-API-Snapshots werden vom Builder
gegen den Reviewer-Vertrag aktualisiert und vom Reviewer geprüft.

### Betreiber

`orchestrator/**`, `config.env`, `toolchain.json` und die Gate-Auswahl sind
Betreiber-Territorium. Keine Modellrolle darf Orchestrator-Zustand oder
`gates.json` schreiben. Der Orchestrator erzwingt die Territorien nach jeder
Modellphase per Git-Diff und verwirft einen verletzenden Versuch; genau ein
angekündigter Wiederholungsversuch ist erlaubt.

## Integrität der Abnahme

Abnahmekriterien werden erfüllt, niemals passend gemacht:

1. Tests, Benchmarks und Golden-Hashes dürfen nie abgeschwächt,
   übersprungen, auskommentiert oder gelöscht werden, um grün zu erreichen.
   Schlägt ein Kriterium fehl, wird der Produktcode behoben oder das
   Scheitern mit Beleg dokumentiert.
2. Referenzwerte in Tests stammen aus den in der Spezifikation genannten
   Quellen. Die Implementierung darf erwartete Testwerte niemals erkennen
   und hart zurückgeben: Sie rechnet den allgemeinen Fall.
3. Ein Golden-Hash ändert sich nur zusammen mit einem ADR, das fachlich
   begründet, warum sich das Ergebnis ändern durfte.
4. „Kriterium erfüllt“ heißt: Der Befehl wurde ausgeführt und sein echter
   Output steht im Handoff oder in `PROGRESS.md`. Behauptungen ohne
   ausgeführten Beleg zählen nicht.
5. Pipelines erfinden keine Daten. Scheitert Download, Parse oder
   Validierung, brechen sie benannt ab. Fixtures sind als solche markiert
   und klein.
6. Compiler-, Lint-, Test- und Gate-Regeln werden nicht gelockert, um Fehler
   verschwinden zu lassen. `--no-verify` und vergleichbare Umgehungen sind
   verboten.
7. Empirische Referenzkonstanten kommen ausschließlich aus
   `reference/anchors/*.json` mit Quelle und Beleg-Zitat oder aus einem
   ausdrücklich benannten Orakel; nie aus Modellgedächtnis als nacktes
   Literal.
8. Gewaltenteilung ist hart: Abnahmetests gehören dem Reviewer, Produktcode
   dem Builder, E2E/Fuzz der QA und der Orchestrator dem Betreiber. Verboten
   sind `--dangerously-skip-permissions`, `--dangerously-bypass-*`,
   `bypassPermissions`, Yolo-, Full-Access- und Klassifikator-Freigabemodi
   (etwa `--approval-mode auto`) in jeder Rolle.

## Handoff-Disziplin

- Blocking-Befunde tragen immer `ref`: Gate, Kriteriums-ID oder wörtliches
  Spec-Zitat mit Fundstelle. Ohne `ref` ist ein Befund nonblocking.
- `[INFRA]` und `[QA-PENDING]` sind für den Builder nonblocking und gehören
  in `BACKLOG.md`, nicht in einen Scheinfix.
- Einwände haben stabile IDs; Builder antworten Punkt für Punkt.
- Präzedenz: Spec > Reviewer > Builder. Deckt ein Spec-Zitat die
  Builder-Position, fällt der Einwand. Schweigt die Spec, bindet nach Ende
  der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.
  Widersprüchliche Specs führen zu `ESCALATE`.
- Jeder spätere PLAN adressiert offene Backlog-Einträge oder vertagt sie mit
  Begründung.
- `orchestrator/ESCALATION-<MS>.md` ist der einzige Human-Touchpoint.

## Arbeitsweise

- Jede Phase ist eine frische Einweg-Session; Resume-/Continue-Flags sind
  verboten.
- Modelle führen keine eigenen Git-Kommandos aus. Der Orchestrator prüft den
  Diff und erzeugt genau den Phasen-Commit.
- Reviews betrachten den Diff seit dem unveränderlichen Tag `plan/<MS>`.
- Logs und Prompts bleiben vollständig unter `orchestrator/logs/`.
- Sprache: Code und Kommentare Englisch; Projektdokumentation nach Vorgabe
  des Projektblocks.

<!-- projektierung_llmsa/AGENTS-PROJEKTBLOCK.md — ersetzt den Abschnitt „Projektblock“ in AGENTS.md des Zielrepos -->
## Projektblock — llmsa (Projektierung 24.10.2026)

- **Vision:** `docs/00-vision.md`. Fachspezifikationen: `docs/01-fachspezifikation.md` (Querschnitt, Prüfstandard, M0), `docs/02-statistikkern.md` (M1a–M1d), `docs/03-anwendungspipeline.md` (M2), `docs/04-weitere-bausteine.md` (M3a–M3d). Nicht bindend: `reference/privat/90-katalog-offen.md`. Belegdokumente: `reference/privat/07_Formelsammlung_llmsa.md`, `reference/privat/QUELLENKATALOG.md`.

### Projektspezifika

- llmsa ist ein R-Paket in CRAN-Struktur (Preset `r-paket`): `DESCRIPTION`, `NAMESPACE` (roxygen2), `R/`, `man/`, `tests/testthat/`, `vignettes/`, `inst/`, `data/`, `data-raw/`. R ab 4.1; Imports nur `lme4`, `ordinal`, `stats`, `graphics`, `tools`, `utils`; neue Imports nur mit ADR; Suggests frei erweiterbar (Validierungssuite: VCA, SixSigma, irr, psych, DescTools, rptR, performance, FrF2, unrepx, qcc, daewr, muttest, digest).
- Sprache: Code, Kommentare, Dokumentation, Fehlermeldungen, Testnamen, `NEWS.md`, Commit-Nachrichten englisch; Specs, ADRs, Handoffs, `BACKLOG.md`, `PROGRESS.md` deutsch.
- Namensschema `msa_*` (Kern), `acmg_*` (Anwendungspipeline, M2; intern, nicht exportiert, Aufruf über `llmsa:::`; Exportentscheidung nach AP1 per ADR, BL-51), `parse_*`, `backend_*`, `pb_*`.
- **Schnittstellenregel:** Die 22 exportierten Funktionen von v0.1.0 behalten ihre Schnittstellen (`docs/01-fachspezifikation.md` §4). Ohne ADR: neue Exporte, neue Argumente mit Vorgabewert hinter den bestehenden, neue Rückgabefelder, geänderte Druckausgabe. Mit ADR und einer Minor-Version Warnphase: alles andere. Der API-Snapshot ist der Anker `reference/anchors/ANK-02.json` (Reviewer); der Abnahmetest prüft das Paket als Obermenge des Snapshots (alles aus dem Snapshot bleibt mit gleichem Vorgabewert an gleicher Position, Neues besteht ohne Snapshot-Änderung); der Snapshot ändert sich nur, wenn eine bestehende Schnittstelle sich ändert, und dann mit ADR.
- **Parallelisierung:** In `R/` kein `mclapply`, `mcmapply`, `mcparallel`, `pvec`, kein `bootMer(parallel = "multicore")` (Windows-CI ist Release-Bedingung); sequentiell oder `parallel = "snow"` mit übergebenem Cluster. In `tests/simulation/` und `inst/validation/sim/` ist `mclapply` zulässig.
- **Prüfstandard** (`docs/01-fachspezifikation.md` §2): nichts gilt als geprüft, weil ein Test grün ist; zwei unabhängige Belege je Kennzahl; ADEMP-Simulation mit Seed, `n_sim` ≥ ANK-06 und MCSE, wo keine geschlossene Lösung existiert; Randfälle und Invarianzen Pflicht; Toleranzen nur aus Ankern.
- **AIAG-Konventionen:** ndc mit 1,41, Abrundung und mindestens 1; Verdikt nach % Studienvariation mit Schwellen 10 und 30, Grenzwerte „bedingt“; %Contribution-Schwellen 1 und 9 als Konvention. Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit).
- **Formelsammlung:** bindend mit den Festlegungen zu §12 in `docs/01-fachspezifikation.md` §3; nur die DIN-32645-Formeln tragen (!) und sind nicht im Scope.
- **Keine lokalen Modelle.** Alle Modelle über APIs; offene Modelle über OpenRouter mit `provider.order`, `allow_fallbacks = false`, `quantizations`. Kein Rollen-Zugriff auf API-Schlüssel; Aufzeichnungen (unveränderte JSON-Antwortkörper, in Tests eingespielt mit `httr2::local_mocked_responses()`) liefert der Betreiber unter `tests/fixtures/api/`.
- **Daten:** eingefrorene Teilmengen unter `inst/extdata/<quelle>_<stand>/` mit `SHA256SUMS` und `QUELLE.txt`, erzeugt von Skripten unter `data-raw/` aus `../quellen/daten/`; Größengrenze ANK-TOL.data_size (Dateien über 100 KB als `.csv.gz`); nur CC0/gemeinfrei/Apache-2.0/MIT. INSAID: nur Gen, cDNA, SHA-256 der Datei; keine Referenzklasse je Variante im Repo. Rohdaten, PDFs, EPUB bleiben außerhalb des Repos.
- **Vignetten:** `llmsa.Rmd` (Einstieg, vorhanden), `validation.Rmd` (ab M1a, liest Anker und Klasse-B-Ergebnisse ein, nichts abgetippt), `llm-stability.Rmd` und `clinvar-raters.Rmd` (M1d); kein Netzzugriff beim Bau.

### Territorien-Ergänzungen

| Rolle | zusätzlich schreiben | ausdrücklich nicht |
| --- | --- | --- |
| Builder | Preset-Pfade; darin `inst/extdata/**`, `inst/validation/**` (Skripte und Kurzlauf-Dateien `*_check_*` der Klasse-B-Studien, Laufskript AP1), `data-raw/**`, `vignettes/**`; `docs/decisions/**` für Builder-ADRs | `tests/acceptance/`, `tests/simulation/`, `tests/fixtures/`, `reference/**`, `orchestrator/**`, `toolchain.json`, Specs |
| Reviewer | `tests/acceptance/**`, `tests/simulation/**` (Klasse-A-Simulationen, `REVIEWER_EXTRA_PATHS_REGEX='^tests/simulation/'`), `reference/anchors/**`, `docs/decisions/**`, `BACKLOG.md` | Produktcode, `inst/`, `data-raw/`, `reference/quellen/**`, `reference/privat/QUELLENKATALOG.md` |
| QA | `tests/e2e/**`, `tests/fuzz/**`, `orchestrator/handoff/<MS>/QA.md`, `BACKLOG.md` | alles andere; QA-Tests dürfen die Testlaufzeit nicht um mehr als die Klasse-A-Grenze (ANK-TOL.sim_runtime) verlängern |
| Betreiber | `orchestrator/**` (einschließlich `gates.d/88-mutfull.sh`), `config.env`, `secrets.env`, `toolchain.json`, `tests/testthat.R`, `tests/fixtures/**`, `reference/quellen/**` (Textspiegel, lokale Datenblätter), `reference/privat/QUELLENKATALOG.md`, `reference/privat/07_Formelsammlung_llmsa.md`, `.Rbuildignore`-Harness-Zeilen, `_pkgdown.yml`-Ziel, Klasse-B-Vollläufe zwischen den Meilensteinen (Ergebnisdateien `*_results.csv`, `*_replicates.csv`, `*_session.txt` unter `inst/validation/sim/`, committet vor M1d), AP1-Erhebung mit Store außerhalb des Arbeitsbaums | – |

Golden-Daten: `GOLDEN_PATH_REGEX='^inst/extdata/'`; jede Änderung dort oder unter `reference/anchors/` braucht ein ADR im selben Meilenstein.

### Domänenregeln und Budgets

- Reihenfolge der Meilensteine = Reihenfolge im Manifest: M0 → M2 → M1a → M1b → M1c → M1d → M3a → M3b → M3c → M3d; `deps` nennen nur fachliche Abhängigkeiten (M2 nur M0; M1d M1c; M3a/M3b M0; M3c M1a; M3d M2). M2 steht vor dem Statistikkern, damit die AP1-Erhebung (Betreiber, außerhalb des Harness, Store außerhalb des Arbeitsbaums) parallel zu M1a–M1d läuft; die AP1-Auswertung wird nach der Abnahme von M1 wiederholt, Zahlen davor sind vorläufig (BL-52). Bis 26.11.2026 zählen M0, M2 und M1a–M1d; M3a–M3d nur, falls Zeit und Geld bleiben (Entscheidung nach M1d).
- Rundenbudget: `MAX_ROUNDS_PLAN=2`, `MAX_ROUNDS_REWORK=5`, `REBUILD_ROUND=4`, `ARBITER_EXTRA_ROUNDS=2` (höchstens 9 Builder-Aufrufe je Meilenstein). Fünf erfolglose Runden deuten auf eine Lücke in Spec oder Ankern, die der Betreiber schließt; kein Weichklopfen von Tests.
- Effort: M0 low; M1a–M1d max; M2, M3a–M3d high. QA ab M2 Pflicht (Gemini 4 Argon, Ersatz Kimi K3). Geld: AP1 150 €. M0 ist der Messlauf für die Kosten je Builder-Aufruf; nach der Messung ergibt sich, was M3a–M3d zusätzlich kosten.
- Mutationstests: Scope `R/fit.R`, `R/grr.R` in M0, M2 und M1a–M1d, ab M3a alle `R/*.R`; Schwelle 80 %, Floor 80, Ratchet 2 (ANK-32); `MUT_WORKERS=14`; `tests/simulation/` nie in `MUT_TEST_DIRS`. In M1c zusätzlich das Betreiber-Gate `88-mutfull` über beide Kerndateien.
- Simulationen: Klasse A unter `tests/simulation/` (Laufzeit je Gate-Lauf ≤ ANK-TOL.sim_runtime). Klasse B in zwei Stufen (`01` §8): Der einführende Meilenstein (M1b, M1c) liefert Skript und Kurzlauf (`*_check_*`, `n_sim = ANK-TOL.n_check`), den der Abnahmetest byte-identisch reproduziert; den vollen Lauf (`n_sim` ≥ ANK-06) rechnet der Betreiber nach der Abnahme dieses Meilensteins und committet die Ergebnisdateien vor M1d; M1d prüft Vollständigkeit, Reproduktion der ersten `n_check` Wiederholungen und die Befunde (K-M1d-6, K-M1d-7). Kein Eingriff zwischen BUILD und GATES.
- Abnahmetests schlagen fehl, wenn eine lokale geschützte Datei (`reference/quellen/data/`) fehlt; sie überspringen nicht. Gate-Kriterien erhalten im Abnahmetest einen ID-Verweis (`skip("K-M0-3: decided by the lint gate")`).
- Builder-Sandbox hat kein Netz: Abhängigkeiten installiert das deps-Gate; nichts wird heruntergeladen; Daten kommen aus `../quellen/daten/` über die `data-raw/`-Skripte, die der Betreiber vorab ausführen kann.
- Benachrichtigung: `NOTIFY_ENABLED=1`, ntfy-Topic als Geheimnis; `WATCHDOG_STALE_SECONDS=4200`; `PUSH_REMOTE=0`.
- Nach M0 prüft der Betreiber die Reviewer-Logs auf Modellumleitung (RUNBOOK „Modellwechsel“).

### Orakel- und Ankerstrategie

- Quelle der Wahrheit für Zahlen: `reference/anchors/*.json` (Reviewer) mit Quelle, Seite, Wert, Einheit, Toleranz, Kurzzitat, Abrufdatum; Liste der zu erhebenden Anker in `ANKER-TODO.md`; Fundstellen im `reference/privat/QUELLENKATALOG.md`; Volltext im Textspiegel `reference/quellen/text/` (`grep -n "Table III-B 7" reference/quellen/text/literatur/A_statistikkern/*.layout.txt`). Zahlen aus OCR-Texten (Cornfield & Tukey, Burdick & Graybill, Randall, Westgard 1981, Maxwell) am PDF prüfen; der Betreiber liefert auf Anfrage die Seite als Bild.
- Zwei Belege je Kennzahl: Literaturwert plus Nachrechnung im Test, oder Literaturwert plus Gegenrechnung mit etabliertem Paket (VCA, SixSigma, lme4, ordinal, rptR, performance, irr, psych, DescTools, FrF2, unrepx, qcc, daewr, stats). Welche zwei, steht im Kriterium.
- Anker werden in der ACCEPTANCE-Phase vollständig geerntet; Nachträge brauchen ein ADR (Gate golden-adr). Werte werden nie aus dem Modellgedächtnis ergänzt; ein unbelegbarer Anker bleibt blocking offen.
- Geschützte Quellen: in Ankern nur Kurzzitate mit Fundstelle; Datenblätter als lokale CSV unter `reference/quellen/data/` (git-ignoriert), vom Betreiber angelegt, vom Reviewer am Original abgeglichen.
- Toleranzen: halbe Einheit der letzten publizierten Stelle, sofern der Anker nichts anderes belegt; Varianzkomponenten immer je Komponente als Anteil der Gesamtvarianz σ²_TV der Vergleichsrechnung, nie relativ zur einzelnen Komponente (abgeleitete Kennzahlen relativ, ndc und Verdikt gleich, Testfälle fern der Rundungs- und Schwellengrenzen); Engine-Gleichheit (gleicher Algorithmus, gleicher Seed) eng (ANK-TOL.engine_ordinal, ANK-TOL.engine_boot); Gegenrechnungen mit Paketen laufen zur Testlaufzeit als Orakel (ANK-TOL.oracle mit zwei Werten für Komponenten und geschlossene Formeln, ANK-TOL.package_compare), eingefrorene Paketausgaben gibt es nicht; Simulationsergebnisse gegen Nominalwerte innerhalb von ANK-TOL.mc_factor Monte-Carlo-Standardfehlern (Bestehenskriterium 4, Berichtsschwelle 3). Alle Toleranzen stehen in einer Datei `reference/anchors/ANK-TOL.json` (bestätigt 24.10., 22:20).
- Referenzdaten aus R-Paketen (`Penicillin`, `ss.data.rr`, `wine`, `BeetlesMale`, `diagnoses`, `vision`, VCA-Datensätze) sind Orakeldaten; ihre publizierten Auswertungen sind Anker.
