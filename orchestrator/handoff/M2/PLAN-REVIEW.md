# PLAN-REVIEW — M2, Runde 2

Rolle: Reviewer · Phase: `30-plan-review` · Runde: 2 · Stand: 27.10.2026 · Gegenstand: `orchestrator/handoff/M2/PLAN-UPDATE.md` (Runde 2) zusammen mit `PLAN.md` (Runde 1), soweit das Update ihn nicht ersetzt. Eine `ARBITER.md` gibt es nicht. Offen waren die Einwände E1 bis E15 aus Runde 1. In dieser Phase entsteht kein neues ADR. ADR-005 bis ADR-007 bleiben unverändert und binden nach dieser letzten Planrunde (`MAX_ROUNDS_PLAN=2`).

## Gelesen

- Rollen und Protokoll: `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md` (keine Lehren).
- Spezifikation: `docs/03-anwendungspipeline.md` vollständig (K-M2-1 bis K-M2-7, Anhang A), `docs/01-fachspezifikation.md` §1 bis §9, ADR-004 mit beiden Nachträgen, ADR-005 bis ADR-007.
- Handoff: `CRITERIA.json` (ACC-1 bis ACC-25), `PLAN.md`, `PLAN-REVIEW.md` und `verdict-plan.json` aus Runde 1, `PLAN-UPDATE.md`.
- Abnahmetests: `setup-m2.R` vollständig; `test-m2-1` (Ordner, Neuerzeugung, `acmg_items()`), `test-m2-4` bis `test-m2-7` vollständig. `test-m2-2` und `test-m2-3` berührt das Update nicht (Stand Runde 1).
- Anker: ANK-54 bis ANK-57, ANK-60, ANK-61, ANK-67, ANK-68.
- Produktcode: `R/run.R`, `R/backends.R`, `R/parse.R`, `R/design.R`, `R/fit.R`; dazu `DESCRIPTION`, `.Rbuildignore`, `tests/fixtures/api/README.md` und `record.R`.
- Harness: aus `orchestrator/orchestrate.sh` `path_allowed`, die Planschleife in `run_ms` und `arbiter`; `orchestrator/config.env` (Territorien, `TEST_CMD`, `MUT_TEST_DIRS`); `orchestrator/lib/r-tests.R`; `docs/gates-auswahl.md` Zeile 87; `BACKLOG.md` (Bestand).

## Eigene Nachprüfung

Ausgeführt ohne Git-Kommando; geschrieben wurde nur unter `tempdir()`. Danach war im Arbeitsbaum außer dem vom Orchestrator geschriebenen `STATUS.md` keine Datei neuer als `PLAN-UPDATE.md`.

1. **Store mit Moduskennung (E3).** Ein Aufruf `Rscript --vanilla -e '…'` lud das Paket mit `pkgload::load_all(".")`. Er legte in `tempdir()` einen Store mit der Tabelle `ap1_metadata` und einer leeren Tabelle `runs` aus `llmsa:::empty_runs()` an. Danach lief `msa_run(…, resume = TRUE)` zweimal mit `backend_mock()`. Ausgabe:

   ```text
   Resuming: 6 calls already stored, 0 to go.
   tables: ap1_metadata runs | rows in runs: 6 | returned: 6 6
   meta of first row: {"mock":true,"latent":-1.6698}
   yaml round trip: has temperature key: TRUE | is NULL: TRUE | provider_order length: 0
   clmm.control default method: nlminb
   ordinal 2026.7.26 | R 4.6.1
   ```

   Der geplante Weg trägt: Die vorab angelegte leere Tabelle mit dem Schema von `empty_runs()` stört weder den ersten Lauf noch Resume. Mock-Zeilen tragen `"mock":true` in `meta`.
2. **YAML-Rundreise (ACC-13).** `temperature: null` übersteht `as.yaml()` und `yaml.load()` als vorhandener Schlüssel mit `NULL`, eine leere Routingliste als leere Liste. Darauf baut der Abnahmetest zu `acmg_plan(path)` mit umgeschriebenem Seed (`test-m2-5:23–38`).
3. **Optimierer von `clmm`.** Die Vorgabe ist `nlminb`. Die Meldung „cannot use ucminf optimizer …“ entsteht mit den Paketvorgaben also nicht. Die übrigen Warnungen von `ordinal` sind Konvergenzwarnungen nach ADR-006 Nr. 4.2 (Runde 1, Nachprüfung 3).
4. **Resume und Fehlerzeilen.** `msa_run()` überspringt jeden gespeicherten `run_key`, Fehlerzeilen eingeschlossen (`R/run.R:47–48`). Gescheiterte Pilotaufrufe lassen sich im selben Store deshalb nicht nachholen (E18).
5. **Art des Stores.** `msa_run()` schreibt nur bei den Endungen `.sqlite`, `.sqlite3` und `.db` nach SQLite, sonst in eine CSV (`R/run.R:114`, `append_store()`) (E17).
6. **Mini-Referenz zum Rückfall.** `acc_m2_with_conditions()` wertet jede Warnung als Scheitern (`setup-m2.R:714`). ADR-006 Nr. 4.2 wertet nur Konvergenzwarnungen (E20).
7. **Territorien.** Alle Pfade, die das Update für den BUILD nennt, liegen im Builder-Territorium: `R/`, `man/`, `tests/testthat/`, `inst/`, `data-raw/`, `DESCRIPTION`, `NAMESPACE` und `NEWS.md` über `BUILDER_EXTRA_PATHS_REGEX`, dazu `PROGRESS.md` und `docs/decisions/`.
8. **Betreiberpunkte.**
   - `NOT_CRAN` ist weder in `config.env` noch in `r-tests.R` gesetzt; E14 ist offen.
   - `docs/gates-auswahl.md:87` nennt weiterhin „K-M2-1 bis K-M2-6“; E15 ist offen.
   - `BACKLOG.md` ist seit Runde 1 unverändert: 62 Einträge, davon 54 offen.

## Bewertung

### Antworten auf die Einwände aus Runde 1

| ID | Antwort im PLAN-UPDATE | Bewertung |
| --- | --- | --- |
| E1 | akzeptiert: `acmg_api_backends(plan)` als einziger Bauweg von `run.R`. Abbildung: `endpoint` in beiden Formen, `id`, `seed`, `reasoning` → `reasoning_effort`, ausdrücklich `temperature = NULL`, `provider` mit `as.list()`, kein `max_tokens`, kein `reasoning`. Schlüssel je geparstem Host, benannte Fehler vor dem ersten Request. T1 prüft den serialisierten Request; dazu ein kurzer API-Pilot durch den CLI-Treiber. | erledigt |
| E2 | akzeptiert: ADR-006 Nr. 7 und Nr. 1 vollständig, mit ausgeschriebener Kostenformel, Sperre für `main` und `robustness` und Auslösern des Wiederholungstags; T2 | erledigt; Hinweise E18 |
| E3 | akzeptiert: `--backend` ohne Vorgabe, auch bei `--evaluate-only`. Die Moduskennung steht in `ap1_metadata` und wird vor Resume geprüft; Abbruch ohne Änderung; Herkunftsprüfung in `acmg_evaluate()`; T3 | erledigt; Präzisierungen E16, E17 |
| E4 | akzeptiert: ADR-006 Nr. 4 | erledigt; Hinweis E20 |
| E5 | akzeptiert: ADR-006 Nr. 4.1, auch für den gemeinsamen Fit und den Join im CLI | erledigt |
| E6 | akzeptiert: ADR-006 Nr. 11 und ADR-005 Nr. 3; Zusammenführen im CLI-Treiber | erledigt |
| E7 | akzeptiert: ADR-006 Nr. 8 und Nr. 10 | erledigt |
| E8 | akzeptiert: ADR-006 Nr. 12; Hash aus der ausgelieferten `QUELLE.txt` | erledigt |
| E9 | akzeptiert: ASCII unter `R/`, F8-Texte aus der YAML, Unit-Tests nur mit Paketressourcen, `skip_if_not_installed()` | erledigt |
| E10 | akzeptiert: ADR-005 Nr. 7 und Nr. 8; Golden-ADR im BUILD mit der nächsten freien Nummer | erledigt |
| E11 | akzeptiert: `reporting.policies` in `plan.yaml` aus den lokalen Schnappschüssen. Ihre Textspiegel liegen unter `reference/quellen/text/anbieter_2026-10-22/` vor. | erledigt |
| E12 | akzeptiert: Artefakte nur unter `tempdir()`, Dateiinventur ohne Git, gezieltes Grafikgerät | erledigt |
| E13 | akzeptiert: ADR-007 | erledigt |
| E14 | akzeptiert als `[INFRA]` | beim Betreiber offen (Nachprüfung 8) |
| E15 | akzeptiert als `[INFRA]` | beim Betreiber offen (Nachprüfung 8) |

Alle 15 Antworten haben die Form „akzeptiert: <Änderung>“ nach SCHEMA.md. Kein Einwand ist mit Spec-Zitat abgelehnt.

### Spec-Treue

Das Update schließt die drei Lücken aus Runde 1, ohne ein Kriterium umzudeuten:

- **Betreiberpfad (E1).** Die Einleitung von `docs/03` verlangt: „die Pipeline muss ihn ohne Codeänderung tragen“. Dieser Pfad ist jetzt festgelegt und ohne Netz geprüft. Die Request-Bodies entsprechen der Tabelle in A.4 und den Produktions-Bodies der Aufzeichnungen:
  - Routing als Arrays mit `allow_fallbacks` false;
  - Sol ohne Temperatur und ohne `provider`;
  - Qwen ohne `reasoning` (ADR-004, Nachtrag 2).
- **Pilot (E2).** Die Pilotregeln folgen A.6 und `ANK-67`:
  - Ein Treffer ist eine erkannte Klasse. Der Pilot prüft die technische Kette, nicht die Messgröße von AP1.
  - Die Kosten werden „für Hauptplan und Robustheit“ projiziert, mit 3.000 Aufrufen (`ANK-56`) und `completion_tokens` einschließlich Reasoning. Bestanden ist die Regel bei S < 150 nach `currency_rule` von `ANK-57`.
  - Die Pilotausgabe endet mit Exit 0.
  - Die Sperre setzt „Der Hauptplan beginnt erst, wenn jedes Modell alle Regeln besteht“ um (A.6, A.8 Nr. 3 und 4).
- **Store (E3).** Die Trennung von Mock und API setzt AGENTS.md, Integrität Nr. 5 um.

Die übrigen Festlegungen bleiben spec-treu wie in Runde 1 bewertet. Sprache und Wortlaut von `plan.yaml` folgen ADR-006 Nr. 13. Ein wörtlicher Widerspruch zwischen Spec-Stellen, der `ESCALATE` verlangte, liegt nicht vor.

### Architektur und Verträge

- `acmg_api_backends(plan)` und `acmg_run_cli(args)` stehen intern in `R/acmg.R`. Neue Exporte entstehen nicht (BL-51, ADR-007 Nr. 5). `run.R` wird zu einer dünnen Hülle, und T1 bis T3 prüfen Konstruktor, Pilotsperre und Storetrennung im selben Prozess. Die Abnahme ruft `run.R` weiter als Unterprozess auf.
- `ap1_metadata` ist eine zusätzliche Tabelle. Tabelle `runs`, ihre Spalten und `run_key` bleiben unverändert (ADR-007 Nr. 2), und Resume trägt (Nachprüfung 1). Die Kennung reist mit jeder Storekopie, deren SHA-256 der Betreiber nach A.8 Nr. 4 festhält.
- Die Schlüssel wählt der Treiber nach dem geparsten Host. Sie stehen nur im Header `Authorization`, nie in `meta`, Store, Log oder Bericht (ADR-007 Nr. 4). Mock- und reine Auswertungspfade lesen keine Schlüssel.
- T1 formuliert die erwarteten Requests unabhängig vom Produktkonstruktor aus YAML und Vertrag (IMPLEMENTATION-RULES, Abschnitt Tests). Die Werte der YAML sichert der Abnahmetest K-M2-5 gegen die Anker; zusammen decken beide die Kette Anker → `plan.yaml` → Request ab.
- Zu präzisieren bleibt, wie `acmg_evaluate()` Mock-Ergebnisse kennzeichnet (E16), und dass `run.R` nur SQLite-Stores annimmt (E17).

### Vollständigkeit

- Alle 15 Einwände sind beantwortet. T1 bis T7 belegen E1 bis E14 mit Unit-Tests ohne Netz und ohne Repo-Pfade außerhalb des Pakets.
- Die sieben Abnahmedateien bleiben unverändert. Sie sind mit dem Update verträglich:
  - Jeder Aufruf von `run.R` nennt `--backend mock` (`setup-m2.R:597–618`, `test-m2-6:20`).
  - Die Mock-Teile laufen ohne Pilotsperre in der Reihenfolge main, robustness, pilot.
  - Die konstruierten Läufe ohne `meta` (`test-m2-6:164–205`) bleiben auswertbar.
  - `acmg_plan(path)` liest die umgeschriebene YAML (Nachprüfung 2).
- ACC-1 bis ACC-25 sind über ADR-005 bis ADR-007 festgelegt oder vom Builder bestätigt.
- Alle 54 offenen Backlog-Einträge sind genau einmal behandelt oder mit Begründung vertagt.
- Pilotregeln und Storetrennung prüft im Gate nur der Unit-Test des Builders. Im Code-Review rechnet der Reviewer die Regeln von ADR-006 Nr. 7 auf einem konstruierten Store unabhängig nach.

### Risiken

PLAN-M2-R1 bis -R7, -INFRA-1, -INFRA-2 und -QA-1 treffen zu. Restrisiken ohne Blockade:

- Die Kennzeichnung „synthetic“ könnte Bänder überschreiben und K-M2-6/K-M2-7 rot machen (E16).
- Ein CSV-Store hätte keine Moduskennung (E17).
- Für gescheiterte Pilotaufrufe, einen Wiederholungstag und eine Antwort ohne `provider` sind die Betreiberwege nicht beschrieben (E18).
- Ohne INSAID-TSV bliebe die Basis des Kappa-Verdikts unsichtbar (E19).
- Der Warnungsbegriff der Mini-Referenz ist weiter als der von ADR-006 (E20).

### Gate-Abdeckung

| Gate | Bezug in M2 | Beleg in der Abnahme |
| --- | --- | --- |
| `10-deps` | Voraussetzung aller K-M2; neue Suggests `yaml`, `digest`, `pkgload` | `gate-deps.log` mit Versionen |
| `20-lint` | `R CMD check --as-cran` ohne ERROR und WARNING (Maßstab K-M0-3); ASCII unter `R/`, neue Rd-Seiten, Suggests (E9) | `gate-lint.log` |
| `30-tests` | K-M2-1 bis K-M2-7 (Prüfweg Test); Unit-Tests T1 bis T7 einschließlich API-Pfad, Pilotsperre und Storetrennung ohne Netz; QA-Tests; die M0-Abnahmetests laufen weiter (BL-53) | `gate-tests.log` |
| `70-trace` | K-M2-1 bis K-M2-7 wörtlich in `docs/03` und beidseitig mit `tests/acceptance` verknüpft | Kurzbefund |
| `82-territory` | Diff des Builders nur in seinem Territorium (Nachprüfung 7), ohne Artefakte (E12) | Audit |
| `86-mutgate` | Scope `R/fit.R`, `R/grr.R` unverändert → „kein geänderter Mutations-Scope“ | Kurzbefund |
| `87-golden-adr` | K-M2-1: neue Dateien unter `inst/extdata/` mit Builder-ADR im Diff seit `plan/M2`; ohne neues Reviewer-ADR in dieser Phase ist die nächste freie Nummer ADR-008 | „Änderung und ADR liegen im selben Meilenstein“ |
| `88-mutfull` | nicht fällig (nur M1c) | „nicht fällig“ |

Den Live-Lauf mit `--backend api` prüft wie vorgesehen kein Gate; er ist Betreiberaufgabe nach A.8. Bau, Serialisierung und Sperren des API-Pfads deckt jetzt das Test-Gate über T1 bis T3 ab.

## Einwände

### Blocking

Keine.

### Minor (nonblocking)

- [E16] (minor) ADR-006 Nr. 9 („Ergebnisse und Berichte aus Mock-Zeilen kennzeichnet es sichtbar als synthetisch“); ACC-12; `acc_m2_check_model()` in `setup-m2.R:885–896` (K-M2-6, K-M2-7) — Befund: Laut PLAN-UPDATE tragen reine Mock-Ergebnisse die Kennzeichnung `synthetic`; wo sie steht, sagt es nicht. Die Abnahme wertet Mock-Zeilen aus und erwartet in `verdicts` und `verdict` die Bänder nach ANK-58. Ersetzte die Kennzeichnung ein Band oder das Gesamtverdikt, schlügen K-M2-6 und K-M2-7 fehl. — Vorschlag: Die Kennzeichnung ist ein zusätzliches Feld, etwa `provenance = "synthetic"` am Ergebnis und je Modell, und ein sichtbarer Hinweis in Titel oder Fazit des Berichts. `verdicts` und `verdict` behalten die Bänder. Zeilen ohne `meta` gelten als Herkunft „nicht belegt“, nie als `api`.
- [E17] (minor) ADR-006 Nr. 9 („Erkannt wird die Art über `meta` oder über eine eigene Kennzeichnung des Stores“); K-M2-6 (Vorgabe `../llmsa-runs/ap1_runs.sqlite`); PLAN-UPDATE E3 („Metadatentabelle `ap1_metadata` des SQLite-Stores“) — Befund: Bei jeder anderen Endung als `.sqlite`, `.sqlite3` oder `.db` schreibt `msa_run()` eine CSV (Nachprüfung 5). Für einen CSV-Store nennt das Update keinen Ort für die Moduskennung. Ein solcher Store mit nur Fehlerzeilen ließe sich keinem Modus zuordnen. — Vorschlag: `run.R` nimmt als `--store` nur SQLite-Pfade an. Bei anderen Pfaden bricht es mit benanntem Fehler ab, bevor es schreibt oder ein Backend aufruft. T3 erhält dafür einen Fall.
- [E18] (minor) docs/03 A.6 („Der Hauptplan beginnt erst, wenn jedes Modell alle Regeln besteht.“; „Auslöser für einen Wiederholungstag, vorab festgelegt …“); A.8 Nr. 3 und 4; ADR-006 Nr. 7.2, 7.6, 7.7, 8.1; ADR-004, Konsequenzen („Nach dem Start von M2 ändert sich der Plan nur durch ein neues ADR; das gilt auch für Änderungen, die der Pilot nahelegt.“) — Befund: Laut Update beschreibt die README die CLI-Pflichten und die Pilotformeln. Drei Betreiberwege fehlen:
  - Ein gescheiterter Pilot lässt sich im selben Store nicht wiederholen. Resume überspringt gespeicherte Fehlerzeilen (Nachprüfung 4), und gewertet werden alle gespeicherten Pilotzeilen. Schon ein HTTP 429 nach den Wiederholungen von `req_retry()` (`R/backends.R:157`) zählt als 4xx.
  - Ein Wiederholungstag muss einen Block ersetzen, denn die Auswertung verlangt genau 18 Zeilen je Item und Modell. Das geht nur auf der Storekopie vor dem betroffenen Block (A.8 Nr. 4).
  - Fehlt `provider` in OpenRouter-Antworten, scheitert der Pilot, und der Hauptplan bleibt gesperrt. Die dokumentierte Antwort kennt dieses Feld nicht (`ANK-60`). Eine Freigabe ist dann eine Planänderung per ADR, keine Funktion von M2.

  — Vorschlag: Die README beschreibt die drei Wege:
  - Ein neuer Pilot läuft in einem neuen Store.
  - Ein Wiederholungstag läuft auf der Kopie vor dem Block weiter; die ersetzte Kopie bleibt mit SHA-256 archiviert.
  - Bei fehlendem Anbieter nennt die Pilotausgabe die betroffenen `meta$id` für die Stichprobe über `GET /api/v1/generation` (K-M2-4) und verweist auf den ADR-Weg.

  Es gibt keinen automatischen Neuversuch und kein Übersteuern der Sperre.
- [E19] (minor) K-M2-6 („INSAID-Referenzen … bleiben ohne Datei `NA` und führen zu keiner Fehlermeldung“); A.7 (Kappa, Trefferquote „gesamt, nach `source`“); docs/01 §2 Nr. 4 („nie stillschweigend eine falsche Zahl“) — Befund: Ohne `--insaid-path` beruhen Kappa, Trefferquote und ihre Verdikte nur auf den 75 ERepo-Items. Das ist nach K-M2-6 richtig und kein Fehler. Ohne Angabe der Basis ließe sich ein Verdikt über 75 Items aber als Verdikt über 100 lesen. — Vorschlag: Ergebnis und Bericht nennen je Modell die Zahl der Items im Kappa, die Zahl der ausgeschlossenen Items (Gleichstand, fehlende Referenz) und ob INSAID-Referenzen geladen waren. `run.R --evaluate-only --backend api` ohne `--insaid-path` gibt einen Hinweis aus. Es gibt keinen Abbruch und keine andere Verdiktregel.
- [E20] (minor) K-M2-6 („… wenn dieser Fit mit Fehler oder Konvergenzwarnung endet …“); ADR-006 Nr. 4.2; ACC-20 — Befund: Die Mini-Referenz `acc_m2_with_conditions()` wertet jede Warnung des ordinalen Fits als Scheitern (Nachprüfung 6). ADR-006 Nr. 4.2 und das PLAN-UPDATE werten nur Konvergenzwarnungen. Mit den Paketvorgaben (Nachprüfung 3) und den Mock-Daten des Prototyps trat keine andere Warnung auf (ACC-20, ACC-25). Für die Mock-Daten des BUILD ist das noch zu belegen. — Vorschlag: Der Builder bleibt bei ADR-006 Nr. 4.2. Er passt die Erkennung nicht dem Test an und ändert die Mock-Konfiguration nicht eigens, um eine solche Warnung zu vermeiden. Tritt beim ordinalen Fit eine andere Warnung auf, nennt er sie wörtlich im Handoff. Der Reviewer gleicht dann die Mini-Referenz im Code-Review an, wie bei `acc_m2_band_kappa()` (ADR-006, Konsequenzen).
- [E14] (minor) [INFRA] BL-56 („Betreiber entscheidet vor dem ersten Meilenstein, der `msa_report()` oder den Validierungsbericht ändert, ob das Test-Gate `NOT_CRAN=true` setzt“) — Befund: weiter offen (Nachprüfung 8). Die M2-Abnahme rendert Berichte über `acmg_evaluate()`, und T7 prüft das Rendern direkt. — Vorschlag: Der Betreiber entscheidet vor dem BUILD. Für den Builder ist der Punkt nonblocking; der Reviewer schreibt BL-56 im Code-Review fort.
- [E15] (minor) [INFRA] `docs/gates-auswahl.md:87` („Gate tests … K-M2-1 bis K-M2-6“) — Befund: weiter offen (Nachprüfung 8). trace prüft gegen `orchestrator/milestones.json` und ist nicht betroffen. — Vorschlag: Der Betreiber ergänzt K-M2-7. Für den Builder ist nichts zu tun.

## Verdict

**PASS.** Es gibt keinen blocking-Befund:

- Der Betreiberpfad mit `--backend api` ist festgelegt und ohne Netz prüfbar (E1).
- Die Pilotregeln sind mit Rechenweg und Sperre definiert (E2).
- Mock- und API-Daten bleiben getrennt (E3).
- Die Minor-Punkte E4 bis E13 sind übernommen.

ADR-005 bis ADR-007 binden ab jetzt; Abweichungen im BUILD sind Befunde mit diesen ADRs als `ref`. E16 bis E20 sind Präzisierungen für den BUILD. E14 und E15 liegen beim Betreiber. Was nach dem Code-Review offen bleibt, trägt der Reviewer dort in `BACKLOG.md` ein; in dieser Phase liegt `BACKLOG.md` nicht in seinem Territorium.
