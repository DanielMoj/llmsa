# PLAN-REVIEW — M2, Runde 1

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 1 · Stand: 27.10.2026 · Gegenstand: `orchestrator/handoff/M2/PLAN.md` (Runde 1). Eine `PLAN-UPDATE.md` und eine `ARBITER.md` gibt es nicht, Einwand-IDs aus Vorrunden ebenfalls nicht. In dieser Phase neu: `docs/decisions/ADR-005` bis `ADR-007` mit den Auslegungen des Reviewers.

## Gelesen

- Rollen- und Protokolldateien: `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `contracts/api/README.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- Spezifikation: `docs/03-anwendungspipeline.md` vollständig (K-M2-1 bis K-M2-7, Anhang A), `docs/01-fachspezifikation.md` §1 bis §9, `docs/decisions/ADR-004` mit beiden Nachträgen.
- Handoff: `CRITERIA.json` mit ACC-1 bis ACC-25, `PLAN.md` vollständig, `BACKLOG.md`.
- Abnahmetests: `tests/acceptance/test-m2-1` bis `test-m2-7` mit `setup-m2.R` und `setup-acceptance.R`.
- Anker: ANK-51 bis ANK-69, ANK-94 und ANK-TOL.
- Aufzeichnungen: `tests/fixtures/api/README.md` und `record.R`.
- Produktcode: `R/backends.R`, `R/run.R`, `R/parse.R`, `R/design.R`, `R/utils.R`, `R/report.R`, `R/agreement.R`, `R/robustness.R`, `R/fit.R`, `R/grr.R`, dazu `DESCRIPTION` und `.Rbuildignore`.
- Harness: `orchestrator/milestones.json`, `docs/gates-auswahl.md` (Zuordnungen), `orchestrator/config.env` (Territorien, Gates), aus `orchestrator/orchestrate.sh` die Funktionen `path_allowed`, `ownership_check` und `run_ms`, `orchestrator/verifier.sh`, `orchestrator/lib/r-tests.R` und die Gates `70-trace.sh` und `87-golden-adr.sh`.
- Format nach `orchestrator/handoff/M0/PLAN-REVIEW.md`.

## Eigene Nachprüfung

Ausgeführt ohne Git-Kommando und ohne Schreiben im Arbeitsbaum.

1. **YAML → JSON-Body.** Ein Aufruf `Rscript --vanilla -e '…'` lieferte nur Ausgabe, keine Datei:

   ```text
   List of 4
    $ provider_order: chr "coreweave/fp16"
    $ quantizations : chr "fp16"
    $ temperature   : NULL
    $ empty         : list()
   as read from yaml: {"model":"m","provider":{"order":"coreweave/fp16","allow_fallbacks":false,"quantizations":"fp16"}}
   with as.list():    {"model":"m","provider":{"order":["coreweave/fp16"]}}
   auto_unbox default: TRUE
   tools::sha256sum: TRUE R 4.6.1
   ```

   Ein aus `plan.yaml` gelesenes `provider_order: ["coreweave/fp16"]` ginge also als JSON-String an OpenRouter, nicht als Array. Das Aufnahmeskript des Betreibers vermeidet genau das (`tests/fixtures/api/record.R:36–37`: „arrays are lists so that they stay JSON arrays“). Die Produktions-Bodies in `tests/fixtures/api/README.md` tragen Arrays.
2. **Abdeckung des Betreiberpfads.** Alle Aufrufe von `run.R` in den Abnahmetests nennen `--backend mock` (`setup-m2.R:597–618`, `test-m2-6:20`). Die API-Backends bauen die Tests selbst (`setup-m2.R:787–809`, mit `list(a$endpoint_tag)`). Kein Abnahmetest und kein Gate prüft, wie `run.R` die Backends aus `plan.yaml` baut. Ohne Argument liest `backend_openai_compatible()` den Schlüssel `OPENAI_API_KEY` (`R/backends.R:138`). `record.R` nimmt `OPENAI_API_KEY` für `api.openai.com` und `OPENROUTER_API_KEY` für `openrouter.ai` (`record.R:29–32`).
3. **Warnungen von ordinal 2026.7.26.** Eine Durchsicht der Namespace-Funktionen per `Rscript` fand unter anderem diese Meldungen:
   - „cannot use ucminf optimizer for this model, using nlminb instead“ (`clmm.fit.env`);
   - „Inner loop did not converge at termination …“ (`update.u`);
   - „Model failed to converge with max|grad| = …“, „Hessian is numerically singular: parameters are not uniquely determined“, „Model is nearly unidentifiable …“ (`conv.check`);
   - „non-finite values in Hessian: illegitimate model fit“.

   Eine Konvergenzwarnung ist also nicht dasselbe wie jede beliebige Warnung (ADR-006 Nr. 4).
4. **Rückfall-Fit im Abnahmetest.** `test-m2-6:127–130` rechnet den Rückfall mit `msa_fit(<Scores>, type = "numeric")` und den Vorgaben des Pakets nach; nach `R/fit.R:98` gilt dann `interactions = TRUE`. Verglichen wird mit `ANK-TOL.engine_ordinal` (1e-8), ebenso beim ordinalen Fit (`setup-m2.R:869–877`).
5. **Phasenregeln.** Nach `orchestrate.sh:486` darf der Reviewer in `30-plan-review` nur `orchestrator/handoff/M2/*`, `contracts/PROTOCOLS.md`, `IMPLEMENTATION-RULES.md` und `docs/decisions/*` schreiben, `BACKLOG.md` nicht. `verifier.sh:24` setzt `BASE_SHA` auf `plan/M2`; diesen Tag setzt `orchestrate.sh:940` erst nach der Planfreigabe. `87-golden-adr.sh` sucht das ADR im Diff seit `BASE_SHA`. ADR-005 bis ADR-007 liegen damit vor `plan/M2` und erfüllen golden-adr für `inst/extdata/` nicht. Das Golden-ADR des Builders muss im BUILD entstehen; so ist es geplant.
6. **Bestand.**
   - `BACKLOG.md` hat 62 Einträge, davon 8 erledigt (BL-19, -26, -27, -32, -38, -58, -59, -61). Alle 54 offenen stehen genau einmal in der Tabelle des PLANs.
   - `DESCRIPTION` nennt yaml, digest und pkgload noch nicht; die Ergänzung als Suggests ist geplant.
   - `docs/gates-auswahl.md` ordnet in Zeile 87 dem Gate tests „K-M2-1 bis K-M2-6“ zu. K-M2-7 fehlt dort, steht aber in `orchestrator/milestones.json`; trace prüft gegen das Manifest.
   - ANK-51 nennt den Pool (1.180 Einstufungen, 71 Gene, 35 Panels, Zahlen je Klasse). Gegen diese Zahlen kann das Erzeugungsskript prüfen.
   - ANK-52 belegt, dass Gen und cDNA in der INSAID-TSV eindeutig sind; die Zuordnung in `acmg_items(insaid_path)` ist damit eindeutig.

## Bewertung

### Spec-Treue

Im Kern setzt der Plan K-M2-1 bis K-M2-7 und Anhang A richtig um:

- vier interne `acmg_*` in `R/acmg.R`, keine neuen Exporte (BL-51);
- `parse_choice(…, whole_word = FALSE)` als neues letztes Argument;
- `backend_openai_compatible()` mit unveränderten `formals()`, ohne Temperaturfeld bei `NULL`, mit Vorrang der Systemspalte und Metadaten nach ACC-10;
- Qwen ohne Feld `reasoning` und ohne `/no_think` (ADR-004, Nachtrag 2), Sol ohne Temperatur;
- Replikat als äußere Schleife, beide Blöcke geplant, bevor `--block` filtert;
- Modalregel mit NA als eigenem Wert, Gleichstand ohne Modalantwort, NA mit Gewicht 0 im Kappa;
- Bänder nach ANK-58 einschließlich der Grenzen 10,0 und 30,0, empirischer Logit mit ½, Δp am Achsenabschnitt;
- gemeinsamer Fit ohne Verdikt;
- INSAID-Referenz und -p.-Angabe nur zur Laufzeit, Kennzeichnung als vorläufig vor M1 (BL-52), Store außerhalb des Arbeitsbaums.

Gut ist auch, dass die Zeilenfolge von `items.csv` keine INSAID-Klasse verrät (`docs/01` §7) und dass die Laufzeit nur ausgelieferte Dateien liest.

Die Sperre des Hauptplans hinter dem bestandenen Pilot entspricht A.6: „Der Hauptplan beginnt erst, wenn jedes Modell alle Regeln besteht.“ Nach A.8 Nr. 3 und 4 gilt sie auch für die Robustheitsläufe (ADR-006 Nr. 7.7).

Zur Sprache von `plan.yaml` sieht der Plan vor: Prosa englisch, Vorlagen und Bausteine zeichengleich, die deutschen F8-Stufen deutsch. Das ist mit `docs/01` §1 und mit dem „wörtlich“ von Anhang A vereinbar, wenn „wörtlich“ inhaltsgleich heißt; so legt es ADR-006 Nr. 13 fest. Ein wörtlicher Widerspruch der Spec, der `ESCALATE` verlangte, liegt nicht vor.

Lücken mit Spec-Bezug:

- Der Plan macht die Pilotregeln zur harten Sperre, gibt aber ihre Rechenregeln nicht an (E2).
- Der Betreiberpfad mit `--backend api` ist weder festgelegt noch geprüft, obwohl die Pipeline den Lauf „ohne Codeänderung tragen“ muss (E1).
- Mock- und API-Daten können im selben Store landen (E3).

### Architektur und Verträge

Die Schichtung stimmt: generische Erweiterungen in `msa_run()` und `msa_report()`, ACMG-Regeln nur in `R/acmg.R`, Konfiguration in `plan.yaml`, Zugriff auf Rohdaten nur in `data-raw/`. `parse_by_prompt = NULL` löst ACC-18, ohne die Bedeutung von `parse` zu ändern. `assessment = NULL` hält den Renderer frei von AP1-Regeln. ADR-007 gibt beide Verträge frei und hält sie zentral fest, wie der Plan es erbittet; `contracts/api/` trägt für dieses Paket keinen Snapshot (Projektblock: ANK-02).

Drei Vertragsstellen fehlen:

- der Bau der API-Backends aus `plan.yaml` (E1);
- die Trennung von Mock- und API-Stores (E3);
- die Herkunft der Itemmerkmale in `acmg_evaluate()` (E6, ADR-006 Nr. 11).

### Vollständigkeit

Alle sieben Kriterien haben einen Abnahmetest und ergänzende Tests des Builders. ACC-1 bis ACC-25 sind übernommen oder beantwortet. Alle 54 offenen Backlog-Einträge sind behandelt oder mit Begründung vertagt.

Es fehlen:

- die Definition der vier Pilotregeln (E2);
- ein Test des API-Pfads (E1);
- Regeln für unvollständige Daten und nicht definierte Kennzahlen (E7);
- die Festlegung des numerischen Rückfalls und der Konvergenzwarnung (E4).

### Risiken

PLAN-M2-R1 bis -R5, -INFRA-1 und -QA-1 treffen zu. Zu ergänzen sind:

- Fehlrouting oder 4xx im echten Pilot durch Serialisierung oder falschen Schlüssel (E1);
- ein Pilot, der den Hauptplan wegen einer falsch gelesenen Regel sperrt (E2);
- synthetische Zeilen im Store des Betreibers (E3);
- Engine-Gleichheit mit 1e-8 bei umsortierten Zeilen (E5);
- WARNING des lint-Gates bei Nicht-ASCII-Zeichen in `R/` (E9);
- Artefakte im Arbeitsbaum während des BUILD (E12, BL-55).

### Offene Punkte ACC-1 bis ACC-25: Reviewer-Entscheidung

| ID | Entscheidung | Fundstelle |
| --- | --- | --- |
| ACC-1 | A.3-Bezeichnungen in Skalenordnung (ANK-69) | ADR-005 Nr. 1 |
| ACC-2 | genau 17 Spalten, gleiche Reihenfolge in beiden Dateien | ADR-005 Nr. 2 |
| ACC-3 | leeres Feld, ISO-Datum, TRUE/FALSE; leeres `prior_differs` nie FALSE | ADR-005 Nr. 3 |
| ACC-4 | Lesart (a) des Builders: Kandidatenzahl je Klasse im Pool | ADR-005 Nr. 4 |
| ACC-5 | Gene je Klasse absteigend, Gleichstände geseedet | ADR-005 Nr. 5 |
| ACC-6 | `<`, nur fünf Klassen, „flagged“ zählt, eigenes Panel mit Rückfall auf alle Expertenpanels | ADR-005 Nr. 6 |
| ACC-7 | Dollar gegen Eurozahl ohne Wechselkurs | ADR-006 Nr. 1 |
| ACC-8 | vom Builder bestätigt: Zeichenvektor; data.frame mit `prompt_id`, F1–F8, `template`, `system` | PLAN |
| ACC-9 | Nutzernachricht und `prompt_hash` ohne Systemprompt | ADR-006 Nr. 2 |
| ACC-10 | vom Builder bestätigt | ADR-007 Nr. 4 |
| ACC-11 | vom Builder bestätigt; `--backend` ohne Vorgabe (E3) | ADR-006 Nr. 7.6, Nr. 9 |
| ACC-12 | vom Builder bestätigt; zusätzliche Felder (`kappa_by`, Diagnostik, Kennzeichnungen) zulässig | ADR-006 Nr. 8, 10, 11 |
| ACC-13 | vom Builder bestätigt; Zusatzfeld `provider_name` je Modell zulässig | ADR-006 Nr. 7.2 |
| ACC-14, -15, -23, -24, -25 | zur Kenntnis; ANK-69 trägt der Betreiber in ANKER-TODO nach | – |
| ACC-16 | Ordnerprüfungen, deterministische `QUELLE.txt` und `SHA256SUMS` | ADR-005 Nr. 7 |
| ACC-17 | unabhängig vom Gebietsschema, RNG ausdrücklich, Poolprüfung gegen ANK-51 | ADR-005 Nr. 8 |
| ACC-18 | `msa_run(…, parse_by_prompt = NULL)` angenommen | ADR-007 Nr. 2 |
| ACC-19 | Perzentil-Bootstrap, Toleranzen aus Ankern | ADR-006 Nr. 3 |
| ACC-20 | Konvergenzwarnung nach Meldungstext; numerischer Rückfall mit Paketvorgaben | ADR-006 Nr. 4 |
| ACC-21 | NA, leer oder fehlend → Argument `system` | ADR-006 Nr. 5 |
| ACC-22 | Replikat außen, Zufallsstrom mit ANK-59, Prüfmaß < 0,5 | ADR-006 Nr. 6 |

Die Abnahmetests lassen alle Entscheidungen zu und ändern sich nicht. Eine Abweichung gibt es: ADR-006 Nr. 10 bewertet ein nicht definiertes Kappa mit „not assessed“, die Mini-Referenz `acc_m2_band_kappa()` gäbe dort `NA`. Mit den Testdaten tritt der Fall nicht auf.

### Gate-Abdeckung

| Gate | Bezug in M2 | Beleg in der Abnahme |
| --- | --- | --- |
| `10-deps` | Voraussetzung aller K-M2; neue Suggests yaml, digest, pkgload | `gate-deps.log` mit Versionen |
| `20-lint` | Bestandsregel mit dem Maßstab von K-M0-3: `R CMD check --as-cran` ohne ERROR und WARNING, mit neuen Rd, Suggests und `R/acmg.R` (E9) | `gate-lint.log` |
| `30-tests` | K-M2-1 bis K-M2-7 (Prüfweg Test), Unit-Tests des Builders, QA-Tests; die M0-Abnahmetests laufen weiter (BL-53) | `gate-tests.log` |
| `70-trace` | K-M2-1 bis K-M2-7 wörtlich in `docs/03` und beidseitig mit `tests/acceptance` verknüpft | Kurzbefund |
| `82-territory` | Diff des Builders nur in seinem Territorium, ohne Artefakte (E12) | Audit |
| `86-mutgate` | Scope `R/fit.R`, `R/grr.R` bleibt unverändert → „kein geänderter Mutations-Scope“ | Kurzbefund |
| `87-golden-adr` | K-M2-1: neue Dateien unter `inst/extdata/` mit Builder-ADR im Diff seit `plan/M2` | „Änderung und ADR liegen im selben Meilenstein“ |
| `88-mutfull` | nicht fällig (nur M1c) | „nicht fällig“ |

Den Betreiberpfad `--backend api` prüft kein Gate. E1 schließt diese Lücke mit einem Unit-Test im Test-Gate.

## Einwände

### Blocking

- [E1] (blocking) docs/03 Einleitung („die Pipeline muss ihn ohne Codeänderung tragen“); docs/03 A.4, Tabelle („`provider.order = ["coreweave/fp16"]`, `allow_fallbacks = false`, `quantizations = ["fp16"]`“, ebenso `deepinfra/fp8`; bei Sol „`temperature = NULL`, Feld fehlt im Body“); K-M2-4 — Befund: Der PLAN sieht `run.R --backend api` vor, legt aber nicht fest, wie die drei Backends aus `plan.yaml` entstehen, und plant dafür keinen Test. Die Abnahmetests decken diesen Pfad nicht ab (Nachprüfung 2). Zwei Fehlerbilder sind konkret: (1) `provider_order` und `quantizations` aus `plan.yaml` sind Zeichenvektoren der Länge 1 und gingen als JSON-String statt als Array an OpenRouter (Nachprüfung 1). (2) Ein OpenRouter-Backend ohne ausdrücklichen Schlüssel schickte `OPENAI_API_KEY` an openrouter.ai (`R/backends.R:138`). Der echte Pilot würde dann mit 4xx scheitern oder ohne festes Routing laufen; beides verlangte nach der Abnahme eine Codeänderung. — Vorschlag: Das PLAN-UPDATE legt eine interne Funktion fest, mit der `run.R` und nur sie die API-Backends baut. Sie bildet ab: `base_url` aus `endpoint` (beide Formen nach ACC-13); `model` = `id`; `reasoning` → `reasoning_effort` nur, wenn gesetzt; `temperature` nur, wenn nicht `null`; `seed`; `provider = list(order = as.list(…), allow_fallbacks = FALSE, quantizations = as.list(…))` nur bei nicht leeren Routinglisten; kein `max_tokens`, kein `reasoning`. Schlüssel: `OPENAI_API_KEY` für `api.openai.com`, `OPENROUTER_API_KEY` für `openrouter.ai`, wie in `record.R`. Ein leerer Schlüssel führt vor dem ersten Aufruf zu einem benannten Fehler; Schlüssel stehen nie in Ausgabe, Log, Store oder `meta`. Dazu kommt ein Unit-Test unter `tests/testthat/` ohne Netz: Er erfasst je Modell aus der ausgelieferten `plan.yaml`, mit Dummy-Schlüsseln, `httr2::local_mocked_responses()` und einer synthetischen Antwort, URL, `Authorization`-Header und JSON-Body. Er prüft sie gegen die Werte der `plan.yaml` und die Feldstruktur der Produktions-Bodies in `tests/fixtures/api/README.md`: Arrays, `allow_fallbacks` false, bei Sol weder `temperature` noch `provider`, nirgends `reasoning`, kein fremder Schlüssel.
- [E2] (blocking) K-M2-7 („`--part pilot` gibt je Modell jede Bestehensregel aus `ANK-67` mit bestanden oder nicht bestanden aus“); docs/03 A.6 („Parser-Trefferquote mindestens 27 von 30“; „Anbieter gleich dem angeforderten (K-M2-4)“; „Der Hauptplan beginnt erst, wenn jedes Modell alle Regeln besteht.“) — Befund: Im API-Pfad macht der PLAN die vier Pilotregeln zur harten Sperre, definiert sie aber nicht. Offen ist:
  - was ein Parser-Treffer ist (erkannte Klasse oder richtige Klasse), was der Nenner ist und wie Fehlerzeilen zählen;
  - wie „Anbieter gleich dem angeforderten“ verglichen wird (Endpunkt-Tag `coreweave/fp16` gegen die Antwort `CoreWeave`) und wann Sol besteht;
  - woran ein 4xx erkannt wird;
  - ob die Kostenregel je Modell oder über die Summe gegen 150 entscheidet.

  Liest der Build „Treffer“ als Richtigkeit, sperrt der echte Pilot den Hauptplan, sobald ein Modell weniger als 27 der 30 Pilotaufrufe richtig beantwortet. Das ist genau die Größe, die AP1 messen soll. — Vorschlag: Das PLAN-UPDATE übernimmt ADR-006 Nr. 7 oder widerspricht mit einem wörtlichen Spec-Zitat. Kurz gefasst legt Nr. 7 fest:
  - Treffer = erkannte Klasse, Nenner 30, Fehler zählen als Nichttreffer;
  - Anbieter gegen `provider_name` aus ANK-54/55, als Zusatzfeld in `plan.yaml`; Sol als direkter Endpunkt;
  - 4xx aus der gespeicherten Fehlermeldung;
  - Kostenprojektion je Modell, Entscheidung über die Summe;
  - Mock besteht weder Anbieter noch Kosten;
  - Pilotausgabe mit Exit 0;
  - Sperre für `main` und `robustness`.

  Dazu ergänzt das PLAN-UPDATE den Testplan um Unit-Fälle: 26, 27 und 30 Treffer unabhängig von `reference`; fehlender und abweichender Anbieter; 4xx-Erkennung; unvollständiger Pilot; fehlende `usage`; Summenregel; Mock-Zeilen; Sperre mit `--backend api`.
- [E3] (blocking) AGENTS.md, Integrität der Abnahme Nr. 5 („Pipelines erfinden keine Daten.“); K-M2-6 („ohne `--store` schreibt das Skript nach `../llmsa-runs/ap1_runs.sqlite`“); docs/03 A.8 Nr. 4 (Store nach jedem Block kopiert und mit SHA-256 festgehalten) — Befund: Im PLAN hat `--backend` die Vorgabe `mock`, und die Vorgabe des Stores ist der Ort des Betreiberstores. Ein Aufruf ohne `--backend api` schreibt damit synthetische Antworten in den echten Store. Der PLAN schließt nur die Gegenrichtung aus („ein Store mit Mock-Daten wird nicht für einen API-Lauf verwendet“). Danach wäre der Store für die API-Teile gesperrt, und `--evaluate-only` würde Mock-Zeilen als Modellantworten auswerten. — Vorschlag: Das PLAN-UPDATE übernimmt ADR-006 Nr. 9:
  - `--backend` hat keine Vorgabe; fehlt die Angabe, folgt ein benannter Fehler. Alle Abnahmeaufrufe nennen `--backend mock`.
  - `run.R` schreibt vor dem ersten Aufruf weder Mock-Zeilen in einen Store mit API-Zeilen noch umgekehrt; erkannt wird die Art über `meta` oder eine eigene Kennzeichnung des Stores.
  - `acmg_evaluate()` bricht bei gemischter Eingabe mit benanntem Fehler ab und kennzeichnet Ergebnisse und Berichte aus Mock-Zeilen als synthetisch.
  - Für jeden dieser Punkte gibt es einen Unit-Test.

### Minor (nonblocking)

- [E4] (minor) K-M2-6 („… oder, wenn dieser Fit mit Fehler oder Konvergenzwarnung endet, den numerischen Fit auf den Klassenscores …“); ANK-68; ACC-20 — Befund: Der PLAN sagt nicht, welcher numerische Fit der Rückfall ist und welche Warnung als Konvergenzwarnung gilt. Der Abnahmetest rechnet `msa_fit(…, type = "numeric")` mit den Vorgaben des Pakets nach (Nachprüfung 4). `ordinal` meldet Konvergenzprobleme mit verschiedenen Texten, warnt aber auch bei einer bloßen Optimiererumstellung (Nachprüfung 3). — Vorschlag: ADR-006 Nr. 4 umsetzen, also Erkennung nach dem Meldungstext mit Unit-Tests für diese Meldungen, Rückfall mit den Vorgaben des Pakets, alle Warnungen speichern und berichten, die Diagnostik von clmm berichten, ohne dass sie den Rückfall auslöst.
- [E5] (minor) K-M2-6; ANK-TOL.engine_ordinal (1e-8) — Befund: Die Abnahme vergleicht Fits mit eigenen Aufrufen von `msa_fit()` auf denselben Zeilen in derselben Reihenfolge. Sortiert oder dedupliziert `acmg_evaluate()` vorher, kann der ordinale Optimierer um mehr als 1e-8 abweichen. — Vorschlag: Die Zeilen in der übergebenen Reihenfolge an `msa_fit()` geben (ADR-006 Nr. 4.1). Die geplante Permutationsprüfung des Builders mit `ANK-TOL.invariance` bleibt davon getrennt.
- [E6] (minor) K-M2-6 („INSAID-Referenzen werden nur über `acmg_items(insaid_path = …)` aus der lokalen TSV gelesen“); ACC-12 — Befund: Der Satz „Die Auswertung liest stets den Store neu und ergänzt Itemdaten passend zu den IDs“ ist mehrdeutig. Ergänzte `acmg_evaluate()` die Itemspalten selbst aus `items.csv`, gingen die INSAID-Referenzen aus `acmg_items(insaid_path = …)` verloren, und der INSAID-Test von K-M2-6 schlüge fehl. — Vorschlag: ADR-006 Nr. 11 umsetzen: Itemmerkmale nur aus `runs`, die IDs von `acmg_items()` nur zur Trennung der Teile, Zusammenführen in `run.R`. Dazu ADR-005 Nr. 3: Ein leeres `prior_differs_*` ist NA, nie FALSE; die Gruppen heißen `"TRUE"` und `"FALSE"`.
- [E7] (minor) K-M2-6, K-M2-7; ANK-68 („über alle 18 Hauptplanaufrufe“); docs/03 A.5 („je Lauf alle 100 Items einmal je Modell“) — Befund: Der PLAN spricht von „vollständigen PB-Läufen“, legt Vollständigkeit aber nicht fest. Für einen unvollständigen Hauptplan und für nicht definierte Kennzahlen fehlt eine Regel. — Vorschlag: ADR-006 Nr. 8 und Nr. 10 umsetzen: 18 Zeilen je Item und Modell, sonst „not assessed“; Robustheit nur mit 12 Läufen über alle Items, n mit NA- und Fehlerzeilen; nicht definiertes Kappa oder %GRR → „not assessed“.
- [E8] (minor) ADR-004 Nr. 1 („ihre p.-Angabe liest `acmg_items()` nur zur Laufzeit aus der lokalen TSV (K-M2-1, A.2, A.5)“); docs/03 A.5 (F2) — Befund: Im PLAN ist `--insaid-path` wahlfrei. Ein Robustheitslauf ohne TSV wendet F2 auf die 25 INSAID-Items nicht an. Das fällt nicht auf und lässt sich auch über Resume nicht ausgleichen. — Vorschlag: ADR-006 Nr. 12 umsetzen: `--part robustness --backend api` verlangt `--insaid-path` mit Prüfung der SHA-256; p.-Angabe und Referenz stehen in keiner Datei und keiner Ausgabe außer als aggregierte Kennzahl.
- [E9] (minor) Gate `20-lint` („`R CMD check --as-cran` … ohne ERROR und ohne WARNING“, Maßstab K-M0-3); docs/01 §5 („Tests unter `tests/testthat/` überspringen mit `skip_if_not_installed()`“) — Befund: Nicht-ASCII-Zeichen im Code unter `R/` erzeugen die WARNING „non-ASCII characters“; Beispiele sind die deutschen F8-Bausteine, typografische Anführungszeichen und „–“. Unit-Tests, die `../quellen`, `reference/` oder `tests/fixtures/` brauchen, scheitern im Check-Verzeichnis. — Vorschlag: Texte nur aus `plan.yaml` (UTF-8) lesen oder `\uxxxx` verwenden. Unit-Tests mit `skip_if_not_installed()` für Suggests und ohne Repo-Pfade außerhalb des Pakets. Nach roxygen2 (installiert 8.1.1, `RoxygenNote` 7.3.1) bleiben die Exporte in `NAMESPACE` die 22 von ANK-02.
- [E10] (minor) K-M2-1; ANK-51; docs/01 §7; Gate `87-golden-adr` — Befund: Laut PLAN prüft das Erzeugungsskript Prüfsummen und Schema der Eingaben, nicht aber den Pool selbst. Offen ist auch, ob `QUELLE.txt` und `SHA256SUMS` deterministisch sind; ein erneuter Lauf mit Zeitstempel änderte Golden-Dateien. — Vorschlag: ADR-005 Nr. 7 und 8 umsetzen: Poolprüfung gegen ANK-51 vor der Auswahl, deterministische Begleitdateien, `RNGkind` ausdrücklich. Das Golden-ADR des Builders entsteht im BUILD und nimmt die nächste freie Nummer, ADR-008; ADR-005 bis ADR-007 liegen vor `plan/M2` und zählen für golden-adr nicht (Nachprüfung 5).
- [E11] (minor) docs/03 A.7 (Logging- und Datenregeln aus `Provider_Logging.html` und `Your_data.html`); PLAN, Schnittstellen („Die Laufzeit verwendet ausgelieferte CSVs und YAML …“) — Befund: Offen ist, woher der Bericht diese Regeln nimmt. Ein Lesen unter `../quellen/` zur Laufzeit scheiterte im installierten Paket und in der Mutationskopie. — Vorschlag: kurze Zusammenfassungen mit Kurzzitat, Stand 22.10.2026 und Fundstelle als Teil der ausgelieferten Konfiguration (`plan.yaml`); kein Zugriff auf `../quellen` in `acmg_evaluate()` oder `msa_report()`.
- [E12] (minor) AGENTS.md, Territorien; BL-55; M0 PLAN-REVIEW E2 — Befund: Laut Testplan laufen Unit- und Abnahmetests im Checkout. Dabei könnten `run.R`, Berichte oder Grafikgeräte Dateien im Baum hinterlassen, etwa `Rplots.pdf`, Berichte oder Stores. Eine neue Datei außerhalb des BUILD-Territoriums verwirft den Versuch. — Vorschlag: Tests im Checkout nur so starten, wie das Test-Gate es tut; vor Phasenende den Baum ohne Git auf neue Dateien prüfen, etwa per Dateiliste; alle Laufartefakte unter `tempdir()`.
- [E13] (minor) IMPLEMENTATION-RULES.md („Public APIs sind explizit, klein und … beschrieben“); docs/01 §4; BL-57 — Befund: Der PLAN bittet den Reviewer, die neuen Argumente zentral zu beschreiben. — Vorschlag: ADR-007 ist dieser Vertrag. Unter anderem sind dort Namen in `parse_by_prompt` zulässig, die im Design fehlen, und `NULL` erhält das Verhalten von v0.1.0. Die Rd-Seiten folgen dem ADR; NEWS nennt beide Ergänzungen und die Temperaturkorrektur.
- [E14] (minor) [INFRA] BL-56 („Betreiber entscheidet vor dem ersten Meilenstein, der `msa_report()` oder den Validierungsbericht ändert, ob das Test-Gate `NOT_CRAN=true` setzt“) — Befund: M2 ist dieser Meilenstein (`R/report.R`, `inst/templates/validation_report.Rmd`). Die Abnahme von M2 rendert Berichte über `acmg_evaluate()` ohnehin. — Vorschlag: Der Betreiber entscheidet vor dem BUILD von M2; für den Builder ist der Punkt nonblocking. Der Reviewer schreibt BL-56 im Code-Review fort; `BACKLOG.md` liegt in dieser Phase nicht in seinem Territorium.
- [E15] (minor) [INFRA] docs/gates-auswahl.md, Zuordnung „Gate tests … K-M2-1 bis K-M2-6“ — Befund: In der Zuordnung fehlt K-M2-7 (ADR-004 Nr. 3). trace prüft gegen das Manifest und ist nicht betroffen. Die Aussage des PLANs zu BL-48, `gates-auswahl.md` liege unter `reference/privat/`, ist überholt: Die Datei liegt unter `docs/`. — Vorschlag: Der Betreiber ergänzt K-M2-7. Für den Builder ist nichts zu tun.

## Verdict

**REWORK.** E1 bis E3 sind blocking:

- Der Betreiberpfad mit `--backend api` ist weder festgelegt noch geprüft und hat zwei nachgewiesene Fehlerbilder (E1).
- Die Pilotregeln, die im Plan den Hauptplan sperren, sind nicht definiert (E2).
- Synthetische Daten können in den Store des Betreibers gelangen (E3).

Das PLAN-UPDATE beantwortet E1 bis E15 Punkt für Punkt nach SCHEMA.md. Für E2, E3 und die Minor-Punkte genügt „akzeptiert: ADR-005/-006/-007 Nr. …“ mit der Ergänzung im Testplan. ADR-005 bis ADR-007 legen ACC-1 bis ACC-7, ACC-9 und ACC-16 bis ACC-22 fest. Sie binden nach Ende der Planrunden und fallen nur durch ein deckendes Spec-Zitat. Der übrige Plan ist spec-treu und vollständig und braucht keine Änderung.
