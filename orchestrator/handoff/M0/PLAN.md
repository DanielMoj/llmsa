# PLAN — M0, Runde 1

Rolle: Builder · Phase: `20-plan` · Stand: 25.10.2026 · Status: Planung, Abnahme offen.

## Ziel

M0 prüft das Gerüst und die Gates auf dem unveränderten Paket v0.1.0 gegen **K-M0-1 bis K-M0-7**. Maßgeblich ist `docs/01-fachspezifikation.md` §10, Zeilen 103–113, insbesondere Zeile 105: „M0 ändert `R/` nicht. Der Builder ergänzt höchstens `PROGRESS.md`, `NEWS.md` oder Dokumentation.“ Die pkgdown-Umstellung gehört dort ausdrücklich dem Betreiber; M0 prüft das eingesetzte Layout.

Ergebnis des späteren BUILD soll ein dokumentierter Ausgangsstand in `PROGRESS.md` sein. Die Abnahme verlangt anschließend die echten Gate-Fakten: installierte Abhängigkeiten, fehlerfreie Testläufe mit mindestens ANK-03 Testblöcken, Paketbau und Prüfung ohne ERROR/WARNING, unveränderte R-Dateien gemäß ANK-01, das vorgeschriebene Layout und API-Kompatibilität gemäß ANK-02. M0 liefert die Ausgangsmessung für Betrieb und Laufzeiten; die fachliche Validierung des Statistikkerns folgt in M1a–M1d.

Gelesen wurden `AGENTS.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `PROGRESS.md`, `BACKLOG.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/handoff/M0/CRITERIA.json`, beide Setup-Dateien und alle sechs M0-Testdateien unter `tests/acceptance/`, `docs/00-vision.md`, `docs/01-fachspezifikation.md` sowie `orchestrator/LESSONS.md`. PROGRESS und LESSONS enthalten bisher keine Einträge. Ergänzend wurden ANK-01/02/03, Paketmetadaten, Layout-Dateien und die zuständigen Gate-Skripte gelesen.

## Dateien

| Pfad | Geplante Behandlung und Zuständigkeit |
| --- | --- |
| `orchestrator/handoff/M0/PLAN.md` | Einzige Schreibdatei dieser PLAN-Runde; enthält Vorgehen, Belege der Vorprüfung und vollständige Backlog-Zuordnung. |
| `PROGRESS.md` | Erst in BUILD ergänzen: M0-Umfang, tatsächlich ausgeführte Befehle samt Output, offene Prüfungen und referenzierte Befunde. Noch nicht gelaufene Gates bleiben ausdrücklich offen. |
| `NEWS.md`, `README.md`, `man/**`, `vignettes/**` | Kein Änderungsbedarf festgestellt, deshalb keine Änderung eingeplant. Ein späterer, belegter Dokumentationsfehler wäre innerhalb des M0-Umfangs gesondert zu behandeln. |
| `R/**`, `DESCRIPTION`, `NAMESPACE`, `tests/testthat/**`, `inst/**`, `data/**`, `data-raw/**` | Unveränderte Prüfgegenstände. Keine Produkt-, Abhängigkeits-, Test- oder Datenänderung vorgesehen. Insbesondere kein roxygen-Lauf, der R-Dateien oder Schnittstellen verändert. |
| `tests/acceptance/**`, `reference/anchors/ANK-01.json`, `ANK-02.json`, `ANK-03.json` | Nur lesen und über die bestehenden Gates prüfen; Reviewer-Territorium. Kein zweiter API-Snapshot. |
| `.gitignore`, `.Rbuildignore`, `_pkgdown.yml`, `.github/workflows/pkgdown.yaml`, `tests/testthat.R`, `toolchain.json` | Bestandsprüfung; die M0-Einrichtung und die Harness-Zeilen bleiben Betreiberaufgaben nach §9/§10 der Fachspezifikation. |
| `orchestrator/config.env`, `orchestrator/gates.d/**`, `orchestrator/lib/**`, `orchestrator/state/**` | Nur lesen. Gate-Ausführung, Zustandsdateien, Territoriumsprüfung, Commits und Tags erzeugt ausschließlich der Orchestrator. |
| `docs/decisions/**`, `BACKLOG.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, Specs | Keine Builder-Änderung in dieser Runde. ADRs zu ACC-1 bis ACC-3 und gegebenenfalls Backlog-Ergänzungen liegen beim Reviewer. |

Der erwartete Builder-Diff in BUILD beschränkt sich damit auf `PROGRESS.md`. In dieser PLAN-Phase bleibt auch diese Datei unverändert.

## Schnittstellen

- Die 22 Funktionen aus `docs/01-fachspezifikation.md` §4 und ANK-02 behalten Exporte, Argumentreihenfolge und Vorgabewerte. M0 plant keine zusätzlichen Exporte, Argumente, Rückgabefelder oder S3-Methoden.
- Der Abnahmetest bleibt eine **Obermengenprüfung**: Snapshot-Exporte müssen vorhanden sein; Snapshot-Argumente bilden mit identischem `deparse()`-Vorgabewert den unveränderten Anfang jeder Signatur. Fehlender Vorgabewert und der Ausdruck `NULL` bleiben unterscheidbar. Zusätzliche Exporte und hinten angehängte Argumente mit Vorgabewert bleiben nach §4 zulässig, auch wenn M0 sie nicht einführt.
- `test-m0-api-snapshot.R` prüft das geladene Paket und konstruierte Funktionslisten mit zwei unabhängig formulierten Prüfern. Fehlende, umsortierte und umbenannte Argumente, geänderte Vorgabewerte sowie fehlende Exporte müssen erkannt werden. Das ist bereits Reviewer-Code; der Builder ergänzt oder verändert ihn nicht.
- `DESCRIPTION` bleibt mit R ≥ 4.1, den bestehenden sechs Imports und den bestehenden Suggests erhalten. Installation und Versionserfassung erfolgen durch das deps-Gate; der Builder installiert nichts und nutzt kein Netz.
- Die Rollenkommunikation folgt `contracts/PROTOCOLS.md` und dem Handoff-Schema. Befunde nennen Kriterium, Gate oder Spec-Fundstelle. Ein fehlgeschlagener Prüfweg wird mit echtem Output dokumentiert; daraus entsteht kein selbst vergebenes Verdict.

## Reihenfolge

1. **PLAN, diese Runde:** Pflichtkontext und Prüfer lesen, den Ausgangsstand ausschließlich lesend untersuchen und diesen Plan schreiben. Die unten protokollierte Vorprüfung ist abgeschlossen; Abnahmetests und Gates wurden nicht gestartet. Git-Kommandos wurden nicht ausgeführt.
2. **PLAN-REVIEW:** Der Reviewer behandelt ACC-1 bis ACC-3 und dokumentiert seine Auslegungen als ADR. Außerdem prüft er die Gate-Zuordnung zu BL-48. Bei einer zweiten Planrunde beantwortet der Builder jede Einwand-ID in `PLAN-UPDATE.md` nach dem vorgegebenen Format und berücksichtigt eine vorhandene bindende `ARBITER.md`.
3. **BUILD:** Den dann gültigen Plan und Reviewer-ADRs lesen. ANK-01-Dateimenge, Größen und Hashes erneut gitfrei prüfen; bei Bedarf den installierenden deps-Lauf durch die rein lesende Diagnose `Rscript orchestrator/lib/r-deps.R --check-only` vorbereiten. Nur ausgeführte Diagnosen mit Output in `PROGRESS.md` aufnehmen. Keine Prüfbehauptung aus dem historischen Ankerlauf übernehmen. Keine zusätzlichen Tests für unverändertes Produktverhalten schreiben.
4. **Orchestrator nach BUILD:** Territorium prüfen, den Phasen-Commit erzeugen und die unveränderliche Vergleichsbasis `plan/M0` verwenden. Anschließend die konfigurierten Gates ausführen. Zwischen BUILD und GATES ist kein Modelleingriff vorgesehen.
5. **Abnahme und gegebenenfalls REWORK:** Der Reviewer liest den Diff seit `plan/M0`, aktuelle Gate-Logs und das Aggregat. Ein zulässiger Dokumentationsfehler wird in einer regulären Builder-Phase behoben. Ein Befund, der eine Änderung unter `R/`, an Tests, Ankern oder Betreiberdateien erfordert, wird mit Referenz an die zuständige Rolle gegeben; der Builder erweitert den M0-Umfang nicht eigenmächtig. `[INFRA]` bleibt für den Builder nonblocking, ersetzt aber keinen fehlenden Abnahmebeleg.
6. **Nach M0:** Der Betreiber prüft Reviewer-Modellumleitungen, Kosten und vorhandene Laufzeitbelege (BL-06, BL-11, BL-13, BL-37). Nächster Meilenstein ist M2; die AP1-Erhebung kann danach parallel zu M1a–M1d laufen. Veröffentlichbare AP1-Zahlen setzen die erneute Auswertung nach M1-Abnahme voraus (BL-52).

## Risiken

### Abnahme und Zuständigkeiten

| ID / Referenz | Risiko und Umgang |
| --- | --- |
| R-M0-1 — K-M0-4; §10, Zeile 105 | Formatierung, Zeilenenden oder automatische Dokumentationserzeugung könnten die 13 R-Dateien verändern. Keine solchen Schreibläufe; Pfadmenge, Größe und SHA-256 gegen ANK-01 prüfen. Ein Fehler im unveränderlichen Produktbestand wird belegt, nicht durch einen M0-Codefix oder einen geänderten Hash verdeckt. |
| R-M0-2 — K-M0-1, K-M0-3; AGENTS, Builder-Sandbox | Fehlende R-Pakete, Pandoc oder Gate-Werkzeuge können die Prüfung verhindern. Zuständig ist der Betreiber beziehungsweise das deps-Gate. `pkgload` ist eine Voraussetzung des Test-Wrappers; `tools::sha256sum()` eine Voraussetzung der Hash-Abnahme. Die Vorprüfung findet R 4.6.1, bestätigt damit aber noch keine vollständige Gate-Umgebung. |
| R-M0-3 — K-M0-2; ANK-03; ACC-3 | Testblöcke, Erwartungen und tatsächlich bestandene Blöcke sind verschiedene Zählungen. Mindestzahl nach ANK-03 verwenden und Fehlschläge, Fehler sowie Skips getrennt berichten. Der im Anker dokumentierte historische Lauf ist kein aktueller Gate-Lauf. Zusätzliche Skips zum Erreichen von grün sind ausgeschlossen. |
| R-M0-4 — K-M0-6; `test-m0-gates.R:8` | Das endgültige `gates.json` entsteht erst nach den Tests. Der Test prüft deshalb aktive Gate-Dateien; der Reviewer prüft anschließend das aktuelle Aggregat einschließlich Runde und Basis. Eine vorhandene ausführbare Datei allein belegt keinen Gate-Erfolg. |
| R-M0-5 — BL-13; `orchestrator/orchestrate.sh:614`, `:750`; `orchestrator/lib/r-check.sh:27` | `PHASE_TIMEOUT` begrenzt im gelesenen Runner Modellaufrufe; der Verifier wird ohne diesen Timeout aufgerufen. `r-check.sh` begrenzt Build und Check jeweils über `R_CHECK_TIMEOUT` (Vorgabe 3600 s). M0 misst nur den vorhandenen Paketbau und Testbestand, keine späteren Simulationen oder vollen Mutationsläufe. Fehlende Dauerangaben werden als Messlücke berichtet; Konfiguration ändert der Betreiber. |
| PLAN-M0-INFRA-01 — [INFRA], BL-48; `docs/01-fachspezifikation.md` §9, Zeilen 96/100 | Die referenzierte `gates-auswahl.md` fehlt; auch die Suche unter ignorierten Dateien fand sie nicht. Die konkrete Zuordnung steht unten im Testplan zur Prüfung bereit. Reviewer/Betreiber ergänzen den vorhandenen BL-48 beziehungsweise das vorgesehene Betreiberartefakt. Kein Builder-Eingriff in Gate-Auswahl, Specs oder BACKLOG; dieser Dokumentationsbefund ist für den Builder nonblocking. |

### Offene Punkte aus CRITERIA.json

Die drei Punkte sind dort ausdrücklich `blocking_builder: false`. Der Plan berücksichtigt die vorhandene Testauslegung; das ausstehende ADR schreibt der Reviewer in `30-plan-review`, nicht der Builder in dieser PLAN-Runde.

| ID | Behandlung im Plan |
| --- | --- |
| ACC-1 — K-M0-4 | Während M0 wird der Arbeitsbaum gegen ANK-01 geprüft. Nach dem vom Orchestrator erzeugten Abschlussmarker prüft der bestehende Test den eingefrorenen Tag `done/M0`. So bleibt der M0-Beleg erhalten, während spätere Produktänderungen und Mutanten fachlich geprüft werden können. Keine eigene Erzeugung von Marker oder Tag; Auslegung für spätere Meilensteine im Reviewer-ADR festhalten. |
| ACC-2 — K-M0-5; §2 Nr. 1 | Die zusätzliche Ignore-Prüfung mit `--no-index` wird berücksichtigt: Sie macht die fehlerhafte Ignorierung einer bereits versionierten Spec erkennbar. Der bestehende Test prüft zugleich die wörtliche Kriteriumsform und die Exit-Codes; ein Git-Fehler zählt nicht als leere Ausgabe. Die Prüfung läuft ausschließlich im Harness. |
| ACC-3 — K-M0-2 | Mindestzahl = Zeilen des testthat-Ergebnisses für `tests/testthat/`, einschließlich übersprungener Blöcke, wie in ANK-03 beschrieben. Der Abnahmetest wiederholt diesen Teil des Laufs; sein Zähler ersetzt nicht den Erfolg des gesamten tests-Gates. Reviewer bestätigt die Zählweise per ADR; aktuelle Skips werden sichtbar berichtet. |

### Vollständige Behandlung des Backlogs

Alle 52 IDs aus `BACKLOG.md` werden einzeln behandelt. BL-38 ist dort bereits als erledigt bezeichnet. Die übrigen Einträge bleiben offen, bis die zuständige Rolle den jeweiligen Beleg liefert; eine Vormerkung im Plan schließt keinen Eintrag. Vertagungen betreffen insbesondere Produktarbeit, die §10 in M0 ausschließt.

| ID | Behandlung, Zuständigkeit und Begründung |
| --- | --- |
| BL-01 | In M0 berücksichtigen: auf Bestandsprüfung begrenzen, danach M2 vor M1a–M1d. Betreiber entscheidet nach M1d über M3a–M3d anhand Frist und Budget; zusätzliche Features würden den M0-Zweck überschreiten. |
| BL-02 | Vertagt an Betreiber vor Veröffentlichung: Neuheitsabgrenzung und Literaturprüfung gehören zur Forschungsdarstellung, nicht zur Abnahme des unveränderten Gerüsts. |
| BL-03 | Vertagt nach M1b (K-M1b-3/-4), Betreiber-Volllauf danach und Befund in M1d (K-M1d-7): ordinales Ersatzverfahren benötigt die vorgesehene ADEMP-Studie; M0 ändert es nicht. |
| BL-04 | Vertagt nach M1c (K-M1c-3), Betreiber-Volllauf und M1d (K-M1d-7): Bootstrap-Überdeckung muss gemessen werden; M0 liefert dafür keinen Beleg. |
| BL-05 | Vertagt nach M2/K-M2-2 und AP1: Memorisierungsvorbehalt und Trennung nach `prior_differs` betreffen Itemsatz und Richtigkeitsauswertung, die M0 nicht einführt. |
| BL-06 | Nach M0 durch Betreiber prüfen: Reviewer-Sitzungsbelege gemäß RUNBOOK „Modellwechsel“ auf Umleitung prüfen. Rollen- und Territoriumsschutz bleiben unverändert; der Builder prüft keine Schlüssel oder Kontozugänge. |
| BL-07 | Vertagt nach M2/K-M2-4: festes Routing, gespeicherter Anbieter und Abbruch ohne Fallback gehören zur Backend-Erweiterung und deren Aufzeichnungstests. |
| BL-08 | Vertagt an Betreiber vor AP7: Partnerdaten setzen die genannte Vereinbarung voraus. M0 verarbeitet oder versendet keine Partnerdaten. |
| BL-09 | In M0 beachten: geschützte Quellen bleiben lokal, keine neuen Quellenkopien im Repo. Reviewer prüft Ankerzitate; bestehende Ignore-Regeln werden über K-M0-5 geprüft. |
| BL-10 | Vertagt an Betreiber zum Go/No-Go am 15.11. und möglicher Einreichung bis 19.11.: Voraussetzung bleiben abgenommenes M1 und ausgewertetes AP1, nicht allein ein grünes M0. |
| BL-11 | M0 als Kostenmesslauf vormerken. Betreiber gleicht danach Dashboard-Kosten je Builder-Aufruf ab und plant bis zu neun Aufrufe je Meilenstein; kein eigener Kostenlogger oder Dashboard-Zugriff des Builders. |
| BL-12 | Vertagt auf die Zeitfenster nach M1b beziehungsweise M1c: Betreiber plant Vollläufe aus den Kurzlaufzeiten, Ergebnisdateien vor M1d. M0 enthält keine Klasse-B-Studie. |
| BL-13 | In M0 Laufzeitbelege aus den späteren Gate-Logs sichern; Timeout-Zuordnung siehe R-M0-5. In M1a erneut messen, weil dessen Simulationen hier noch fehlen. Anpassungen bleiben Betreiberaufgabe. |
| BL-14 | Vertagt nach M1a–M1c einschließlich mutfull: vorhandene Tests laufen in M0 unverändert. Der Testzähler und der M0-Mutationspfad belegen noch keine statistische Validierung. |
| BL-15 | Vertagt: Betreiber korrigiert die Aussage im Projektdokument; Fleiss-Implementierung und Abnahme folgen in M3a/K-M3a-2. In M0 entsteht kein neuer Export oder Algorithmus. |
| BL-16 | Vertagt nach M2/K-M2-4: Antwortmetadaten ergänzen, vorhandenes Durchreichen von `...` berücksichtigen. Backend-Code bleibt in M0 byte-identisch. |
| BL-17 | Vertagt nach M3d/K-M3d-3 und AP2: Betreiber liefert Aufzeichnungen, später folgt der Live-Lauf. M0 bestätigt nur den vorhandenen Offline-Testbestand. |
| BL-18 | Getrennt vertagt: Bootstrap-Meldung nach M1c/K-M1c-2, Datenhash nach M3d/K-M3d-5. Beide verlangen in M0 ausgeschlossene Produktänderungen. |
| BL-19 | In M0 über K-M0-5 und K-M0-3 prüfen. Statisch sind `pkgdown-site/`, Ziel und Workflow bereits umgestellt; die wirksamen Ignore-Regeln entscheidet der Abnahmetest. Betreiber behebt einen Layoutfehler. |
| BL-20 | Vertagt nach M1b/K-M1b-1: direkter `clmm`-Vergleich mit msa-Formel; veröffentlichter Vignettenwert nur Installationsprüfung. Für M0 ist keine ordinal-fachliche Änderung vorgesehen. |
| BL-21 | Vertagt an Reviewer zur Anker-/Fallauswahl für M1a: geschachtelte NIST-Studie nicht ohne passende Modellannahmen übernehmen. Sie ist kein zusätzliches M0-Kriterium. |
| BL-22 | Vertagt nach M1a/K-M1a-2: AIAG-Reproduktion mit `interactions = FALSE`, Unterschied mit Wechselwirkung berichten. Der M0-Bestand bleibt unangetastet. |
| BL-23 | Vertagt nach M1a/K-M1a-4: Genauigkeit gegen `stats::aov` und ANK-TOL.nist_digits beurteilen, schwierige Fälle berichten; eine mögliche Zentrierung ist spätere Produktarbeit. |
| BL-24 | Vertagt an Betreiber unmittelbar vor M3a: Mutations-Baseline beim Scope-Wechsel zurücksetzen. In M0 ist der Scope unverändert und es wird kein Score-Lauf erwartet. |
| BL-25 | Bereits in M0 beachten: ANK-01/02/03 nur lesen. Jeder Reviewer-Nachtrag nach ACCEPTANCE benötigt ein ADR im selben Meilenstein; keine Ankerkorrektur zur Anpassung an Produktfehler. |
| BL-26 | Vertagt an Betreiber vor BUILD von M2: modellbezogene httptest2-Aufzeichnungen für ANK-94 bereitstellen. M0 benötigt keine neuen API-Aufzeichnungen; der Builder hat keine Schlüssel. |
| BL-27 | Vertagt an Betreiber vor Start von M2: AP1-Entwurf freigeben, Freigabe in `plan.yaml` und ADR festhalten. M0 enthält noch keinen AP1-Plan oder Lauf. |
| BL-28 | Vertagt an Betreiber vor M2/AP1: Konten, Guthaben, Limits und Geheimnisse einrichten beziehungsweise prüfen. Builder liest oder verändert keine Schlüsseldateien. |
| BL-29 | Vertagt an Betreiber vor Veröffentlichung von INSAID-Referenzklassen: Anfrage und Antwort klären. Der Builder versendet keine Anfrage und veröffentlicht in M0 keine solchen Daten. |
| BL-30 | Vertagt an Betreiber zu AP2: Pages-Einstellung, Metadaten, Zenodo und Releases sind Veröffentlichungsschritte außerhalb der M0-Gates. |
| BL-31 | Betreiberprüfung für Commit-/Push-Konfiguration vormerken; ohne Beleg nicht als erledigt schließen. Maintainer-Adresse in DESCRIPTION bleibt bestehen, der Builder führt keine Git-Kommandos aus. |
| BL-32 | In M0 prüfen: geforderte `.Rbuildignore`-Zeilen sind vorhanden, Gate-Dateien aktuell ausführbar; `tests/testthat.R` bleibt Betreiberdatei. Versionierte Ausführungsmodi kann nur der Betreiber prüfen; die lokale Vorprüfung beweist sie nicht. |
| BL-33 | Vertagt an Betreiber vor M1a: QA-Routenprobe und CLI-/Sandbox-Voraussetzungen prüfen. M0 führt keine QA-Pflicht ein und ändert keine Berechtigungsmodi. |
| BL-34 | Betreiber soll Erreichbarkeit im RUNBOOK festlegen. Das ist Betriebsorganisation; ein notwendiger Human-Touchpoint bleibt ausschließlich `orchestrator/ESCALATION-M0.md`, vom vorgesehenen Prozess erzeugt. |
| BL-35 | Für M0 ist `NOTIFY_ENABLED=1` in der Betreiberkonfiguration gesetzt. Template-Fehler bleibt Betreiber-/Template-Backlog; keine Änderung an `notify.sh` durch den Builder. |
| BL-36 | Vertagt an Betreiber bei belegtem IO-Engpass: möglicher Wechsel ins WSL-Dateisystem. M0 kopiert weder Repo noch Quellenbestand und nimmt keine Rohdaten auf. |
| BL-37 | Nach M0 gemeinsam mit BL-11 durch Betreiber auswerten; eine neue Kostenspur im Template gehört nicht zum Produkt- oder M0-Auftrag. |
| BL-38 | Laut BACKLOG bereits in v1.1.1 erledigt. Keine neue Änderung; Rundengültigkeit bleibt Teil des bestehenden Verdict-Vertrags und der Logprüfung. |
| BL-39 | Vertagt an Betreiber zur Quellenbeschaffung bei den betroffenen späteren Arbeiten. Die drei benötigten M0-Anker liegen vor; ausgeschlossene DIN-Formeln erzeugen kein M0-Kriterium. |
| BL-40 | Vertagt nach M1d an Reviewer/Betreiber: Konkordanzanker aus verfügbaren Quellen erheben, offene Beschaffung getrennt verfolgen. M0 wertet keine Konkordanzstudie aus. |
| BL-41 | Vertagt nach M2/AP1: Betreiber/Reviewer entscheiden über Beschaffung für zitierte Bandbezeichnungen. ANK-58 bleibt eine Context-of-Use-Festlegung; keine Literaturbegründung erfinden. |
| BL-42 | Vertagt an Betreiber vor den betroffenen Abnahmen: AIAG-Daten für M1a/M3a, Lenth-Daten für M3b lokal bereitstellen und vom Reviewer abgleichen lassen. Fehlende Daten später benannt fehlschlagen lassen; M0 benötigt diese Tabellen nicht. |
| BL-43 | Vertagt nach M2 an Reviewer für ANK-53 bis ANK-55 und vor AP1 an Betreiber für Live-Abgleich. Modellkennungen, Provider und Preise sind keine M0-Abnahmegegenstände. |
| BL-44 | Vertagt nach M3a/K-M3a-2: Fleiss, Nee & Landis 1979 als Varianzquelle prüfen, sofern ein Standardfehler ausgegeben wird. M0 fügt keinen Fleiss-Schätzer hinzu. |
| BL-45 | Betreiberpflege nach Einsetzen und jedem Meilenstein: externe Projektfassungen aktualisieren. Diese PLAN-Runde schreibt ausschließlich das zugewiesene Handoff. |
| BL-46 | Vertagt bis zum Ausbau der Vignetten, insbesondere M1d. M0 protokolliert den vorhandenen Bau; spätere Bauzeiten mit vier Vignetten werden erneut gemessen und vom Betreiber beurteilt. |
| BL-47 | Bei späteren Veröffentlichungen durch Betreiber beachten: VariantBench bleibt ausgeschlossen, Autorennennung korrekt halten. M0 führt keinen Itemsatz oder Literaturtext dazu ein. |
| BL-48 | In M0 adressieren: Gate-/Kriterienmatrix steht unten, vom Reviewer zu prüfen. Fehlende `gates-auswahl.md` als PLAN-M0-INFRA-01 festhalten; der Trace-Fallback ersetzt diese Prüfung nicht. |
| BL-49 | Vertagt nach M1a/K-M1a-1: Komponentenvergleich gegen ANK-TOL.reml_anova relativ zur Gesamtvarianz. Keine zusätzliche Toleranz oder Optimiererkorrektur in M0. |
| BL-50 | Vertagt nach M3c/K-M3c-6: Näherungsvergleich berichten und Kennzahlen aus Einzelschätzern nachrechnen. Eine CV-Gleichheit wird weder in M0 noch als neuer Grenzwert eingeführt. |
| BL-51 | Vertagt nach M2 und zur Exportentscheidung nach AP1: `acmg_*` bleibt intern; Exporte erst nach vorgesehenem ADR. M0 erhält die vorhandenen 22 Schnittstellen. |
| BL-52 | Reihenfolge bereits im Plan berücksichtigen: M2 folgt M0, AP1-Store liegt außerhalb des Arbeitsbaums. Betreiber wiederholt die Auswertung nach M1-Abnahme; vorherige Zahlen bleiben vorläufig und unveröffentlicht. |

## Testplan

### Geplante Abnahme durch den Orchestrator

Die folgenden Kommandos sind **geplant, in dieser Runde nicht ausgeführt**. Sie stammen aus `orchestrator/config.env:142–144`. Der Orchestrator startet in der GATES-Phase `bash orchestrator/verifier.sh M0` mit der richtigen Runde und Basis. Der Builder ruft den Verifier, die Git nutzenden Abnahmetests oder die zustandsschreibenden Gates nicht selbst auf.

| Gate / Kommando im Harness | Erwarteter Nachweis |
| --- | --- |
| deps: `Rscript orchestrator/lib/r-deps.R` | Alle Anforderungen aus DESCRIPTION erfüllt, installierte Versionen im Log. Installationen ausschließlich in der Gate-Umgebung. |
| lint: `bash orchestrator/lib/r-check.sh` | Export des versionierten Paketstands in ein temporäres Verzeichnis außerhalb des Repos; `R CMD build --no-manual` und `R CMD check --as-cran --no-manual` ohne ERROR/WARNING. Bestehende Gate-Einstellungen bleiben erhalten; kein Netzzugriff beim Vignettenbau. |
| tests: `Rscript orchestrator/lib/r-tests.R tests/testthat tests/acceptance tests/simulation tests/e2e tests/fuzz` | Paket aus Quellen geladen, keine fehlgeschlagenen Tests oder Fehler. Leere Zusatzordner werden als solche protokolliert; daraus folgt keine QA- oder Simulationsabnahme. |

| Kriterium / Spec-Fundstelle | Bestehender Prüfweg und konkrete Erwartung |
| --- | --- |
| K-M0-1 — §10, Zeile 107 | deps-Gate plus `test-m0-deps.R`: unabhängiger DESCRIPTION-Parser, installierte Pakete und Versionsbedingungen; maßgeblicher Gate-Output in `orchestrator/state/M0/gate-deps.log`. |
| K-M0-2 — §10, Zeile 108 | tests-Gate plus `test-m0-testthat-count.R`: mindestens `ANK-03.value` (aktuell 27) Ergebniszeilen aus `tests/testthat/`, Zählweise ACC-3; Gesamtlauf ohne Fehlschläge/Fehler. Skips und Testzahl aus dem aktuellen Lauf berichten. |
| K-M0-3 — §10, Zeile 109 | lint-Gate; `test-m0-gates.R` enthält den Kriterienverweis. Bau-/Check-Output in `gate-lint.log`, keine eigene Erfolgsaussage aus einem bloßen Testverweis. |
| K-M0-4 — §10, Zeile 110 | `test-m0-r-unchanged.R`: genau die 13 ANK-01-Pfade, gleiche Bytezahlen und SHA-256. Während M0 Arbeitsbaum; nach Abschluss eingefrorener M0-Stand gemäß ACC-1. |
| K-M0-5 — §10, Zeile 111 | `test-m0-layout.R`: Spec-Pfad nicht ignoriert, beide geschützten Probepfade ignoriert, jeweils korrekte Exit-Codes; zusätzlich ACC-2. Top-Level-Ziel `destination: pkgdown-site`; alle sieben geforderten `.Rbuildignore`-Zeilen wörtlich vorhanden. |
| K-M0-6 — §10, Zeile 112 | `test-m0-gates.R` prüft aktive Pflichtgates. Anschließend muss das aktuelle `gates.json` für deps, lint, tests, trace, territory, mutgate und golden-adr `pass` melden. Die mutgate-Zusammenfassung muss `mutgate: pass (kein geänderter Mutations-Scope)` lauten; ein anderer erfolgreicher Mutationspfad genügt für M0 nicht. |
| K-M0-7 — §10, Zeile 113; §4 | `test-m0-api-snapshot.R`: ANK-02-Struktur mit 22 Funktionen, echte API als Obermenge, zulässige Erweiterungen und die konstruierten Negativfälle mit beiden Prüfern. Der vorhandene isolierte Gate-Test verlangt Fehlschlag bei Snapshot-Änderung ohne ADR und Erfolg mit ADR beziehungsweise ohne Ankeränderung. Keine Änderung echter Anker für diese Prüfung. |

Zuordnung für BL-48: **deps → K-M0-1/-6; lint → K-M0-3/-6; tests → K-M0-1/-2/-4/-5/-6/-7; trace → K-M0-6; territory → K-M0-6; mutgate → K-M0-6; golden-adr → K-M0-6/-7.** Das ebenfalls vorhandene Betreiber-Gate `88-mutfull.sh` gehört fachlich zu K-M1c-6 und meldet in M0 erwartungsgemäß `mutfull: pass (nicht fällig in M0)`; es liefert hier keinen Mutationsscore.

Trace muss die wörtlichen Kriterien aus CRITERIA.json mit Specs, Manifest und Testverweisen verknüpfen. Territory muss den zur Runde und letzten Modellphase passenden Auditbeleg prüfen. Golden-adr muss den wirklichen Diff seit der Vergleichsbasis prüfen; Builder-seitig sind weder Golden- noch Ankeränderungen vorgesehen. Die Mutationskonfiguration bleibt im Kernscope `R/fit.R` und `R/grr.R`; Schwellen, Baseline, Workers und Testordner werden nicht verändert.

Die endgültigen Belege sind `orchestrator/state/M0/gate-<name>.log` und `orchestrator/state/M0/gates.json` mit aktueller Runde, Basis und Toolversionen. Der Reviewer entscheidet auf diesen Fakten. Der Builder übernimmt in regulären Builder-Phasen nur tatsächlich vorliegende Ergebnisse und referenzierte Befunde in PROGRESS; es gibt keinen nachgeschobenen Eingriff zwischen BUILD und GATES. Ein Infrastrukturfehler ist kein bestandener Test; ein Produktfehler erlaubt kein Abschwächen von Tests oder Regeln.

### Bereits ausgeführte Vorprüfung dieser PLAN-Runde

Die folgende gitfreie, ausschließlich lesende Inventur wurde aus der Repo-Wurzel ausgeführt (Exit 0). Sie prüft den heutigen Arbeitsbaum gegen die vorhandenen Anker, ersetzt aber weder den geladenen API-Test noch die Ignore-Prüfung oder die Gate-Abnahme.

```bash
python3 - <<'PY'
from pathlib import Path
import hashlib
import json
import os
import re

root = Path.cwd()
anchor = json.loads((root / 'reference/anchors/ANK-01.json').read_text())
expected = anchor['value']
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

Echter Output:

```text
ANK-01: 13/13 files match path, bytes and SHA-256
ANK-02: 22 NAMESPACE exports match; formals not evaluated
Layout: 7/7 required .Rbuildignore lines and pkgdown destination present; Git ignore semantics not executed
Executable gate files: 10-deps.sh, 20-lint.sh, 30-tests.sh, 70-trace.sh, 82-territory.sh, 86-mutgate.sh, 87-golden-adr.sh, 88-mutfull.sh
M0 gates.json exists: False
gates-auswahl.md exists at repository root: False
```

Zusätzlich ausgeführt: `Rscript --version` (Exit 0), mit Output `Rscript (R) version 4.6.1 (2026-06-24)`. Die Suche `rg --files --hidden --no-ignore -g '*gates-auswahl*' -g '!.git/**' -g '!orchestrator/logs/**' -g '!renv/**' -g '!node_modules/**'` lieferte Exit 1 und keine Ausgabe. Für K-M0-1 bis K-M0-7 wird in dieser PLAN-Runde noch kein Abnahmeerfolg behauptet.
