# REVIEW-INPUT — M1d BUILD, Runde 1

Builder, 04.11.2026. Grundlage: freigegebener PLAN, PLAN-REVIEW E1–E15,
CRITERIA ACC-1–ACC-20 und ADR-045/047/048. Kein PLAN-UPDATE oder ARBITER
vorhanden. Die Umsetzung präzisiert den Plan durch
[ADR-049](../../../docs/decisions/ADR-049-m1d-daten-und-validierungsressourcen.md);
es gibt keine fachliche Planabweichung. Dieser Handoff enthält keinen
Builder-Verdict; Gates und Abnahme bleiben beim Orchestrator und Reviewer.

## Zuordnung zu den Kriterien

| Kriterium | Umsetzung und Beleg |
| --- | --- |
| K-M1d-1 | `make_llm_stability.R` und `prepare.R`: Anker-Hashes, Auswahl/Gitter, schlüsselunabhängiger Parser, Fehlgründe, atomare Veröffentlichung. 82.850 Zeilen, 11.070 fehlende Antworten, zwei nicht zu den Optionen passende Schlüssel. Originaltexte bleiben außerhalb des Pakets. SHA256SUMS einschließlich QUELLE. |
| K-M1d-2 | `llm-stability.Rmd`: Wiederholbarkeit, Trefferquote und Fehlanteil je Aufgabe/Modell; acht binäre Probit-Fits mit Originalreihenfolge, `msa_counts()`, Komponenten, %GRR und sichtbaren Diagnosen. Tabellen werden beim Knit berechnet. |
| K-M1d-3 | `make_clinvar_subsets.R`: Klassenfilter vor Einreicherzählung, alle SCVs, Gene aus `variant_summary`, numerische Stichprobenordnung/ANK-47-RNG, Datumsnormierung und UTF-8. HRF: 6.647 Zeilen/1.383 Varianten; Stichprobe: 5.010/1.000. Berechnete Ausschlüsse vor Schwellen: 501 HRF, 43.886 insgesamt. |
| K-M1d-4 | `clinvar-raters.Rmd`: nominales/ordinales Alpha ohne Modalreduktion, vollständige Übereinstimmung, Konflikt nach drei Gruppen, zwei ordinale Probit-Fits, wörtliche Status-Sensitivität mit tatsächlichen Nennern. Ganze Anker ANK-42–ANK-46 liefern alle Literaturzahlen; Gruppen, Bezugsgrößen und die Abweichung Abstract/Results bei Van Gijn sind erläutert. |
| K-M1d-5 | Neue Datenordner: 258.865 bzw. 117.822 Byte; ganz `inst/extdata`: 627.618 Byte. Lizenz, Auswahl, Quellhashes und Fehlfälle sind dokumentiert. Beide Vignetten lesen installierte Ressourcen. Offene Betreiber-Listung: E1/M1D-INFRA-01 unten. |
| K-M1d-6 | Alle zwölf Betreiber-Volllaufdateien und alle bisherigen Simulationshelfer bleiben bytegleich. Aktuelle Implementierungshashes stimmen mit sämtlichen Sessiondateien überein. Der vollständige Reproduktionslauf und seine echten Ergebnisse stehen in PROGRESS. |
| K-M1d-7 | `findings.R` und `validation.Rmd`: 428 verlangte Wert/MCSE-Paare, 19 dynamisch ausgewählte Befunde, vollständige Szenario-IDs und qualitative Rd-Hinweise. BL-92 ergänzt 50 Zeilen mit eigenem n, Bias/relativem Bias/EmpSE samt MCSE für alle endlichen bzw. konvergierten endlichen Schätzungen. Generatoren und Ergebnisleser bleiben unverändert. |
| K-M1d-8 | Nur Robustheitswortlaut in Print und Bericht geändert. Die vier ANK-34-Dateien wurden vor dem Edit gesichert und gegen den Anker geprüft. Fünf `msa_robustness()`- und fünf `acmg_robustness()`-Objekte sind `identical()` zur Basis; alle drei AP1-Bänder sind abgedeckt. Beide Ausgabezweige, ME-Präzision und unsichtbare Rückgabe sind geprüft. |

## Antworten auf die Einwand-IDs

| ID | Antwort |
| --- | --- |
| E1 | akzeptiert: Betreiber-Vorschlag umfasst ausdrücklich auch `validation`. `_pkgdown.yml` bleibt unverändert, da nicht im Builder-Territorium. Offener Befund unten. |
| E2 | akzeptiert: Nur eindeutige gültige `(X)`-Etiketten, Groß-/Kleinschreibung gleichgültig, keine inneren Leerzeichen/nackten Buchstaben/Antwortformeln; Zitate zählen mit. `navigate`: Yes/No als Wort. Fehlgründe leer/kein Etikett/mehrdeutig in QUELLE, Fehlanteile in der Vignette, synthetische Unit-Fälle. |
| E3 | akzeptiert: Literalvergleich bleibt bestehen; `ruin_names` 99 und 144 und ihre Wirkung als Fehltreffer bei jeder Etikett-Antwort werden in QUELLE und Vignette genannt. |
| E4 | akzeptiert: UTF-8, doppeltes Quoting, LF, NA als leeres Feld, radix, gzip ohne Zeitstempel, Datum unter LC_TIME=C. Zusätzlicher C-Locale-Test fand eine echte Transkodierung; binärer TSV-Eingang und byteerhaltende CSV-Ausgabe beheben sie ohne vorausgesetzte UTF-8-Locale. Vignetten lesen CSV über Textverbindungen ohne native Transkodierung. |
| E5 | akzeptiert: Beide Datenskripte laufen als selbständige `Rscript`-Aufrufe, laden Helfer über die Skriptwurzel, lesen Originalanker und nennen fehlende `quellen`-Eingaben. Keine Abhängigkeit von einem installierten llmsa. |
| E6 | akzeptiert: QUELLE enthält alle verlangten Angaben und zur Laufzeit gezählte Ausschlüsse. Manifest schließt QUELLE ein. |
| E7 | akzeptiert: Identische Abbildungen/Reihenfolge wie der Vertrag, Vorgabelink Probit ohne Wechselwirkungen, vier signifikante Stellen für reale Kennzahlen. |
| E8 | akzeptiert: Signifikante statt feste Dezimalstellen für Studienwerte/MCSE; MCSE null bleibt sichtbar. Monotone Umformungen der stetigen Kennzahlen und ganzzahliges ndc werden getrennt erklärt. |
| E9 | akzeptiert: Jede Befund-ID steht einzeln neben Schätzziel und Richtung; Rd nennt jede betreffende ID und die Validierungsvignette. |
| E10 | akzeptiert: Wörtlicher `sys.source(system.file(...))`-Aufruf, Schwellen aus vollständigen Ankerkopien, nur neue `m1d_`-Helfer. Rekursive bestehende Literaltests bestehen. |
| E11 | akzeptiert: BL-92 liest ausschließlich seine Replikatdatei; kein Abgleich mit Ergebnis-n_sim und kein Simulationshelfer. Die alten Attrappen-Verträge M1b/M1c bestehen. |
| E12 | akzeptiert: Beide Rmd-Codebereiche enthalten keine der verbotenen Netzaufrufe; Paketbau und installierter Knit verwenden Paketressourcen. |
| E13 | akzeptiert: Zusätze unmittelbar beim aktiven Faktornamen; genau eine PSE/ME/SME-Zeile. Kein Zusatz bei inaktiven Faktoren. |
| E14 | akzeptiert: ANK-34-gesicherte Vorher-Dateien liefern den Git-freien Code-/Objektvergleich. Die Git aufrufenden vollständigen Tests K-M1d-7/-8 bleiben beim Orchestrator; keine Abnahmedatei wurde zur Teilprüfung umgeschrieben. |
| E15 | akzeptiert: Tabelle der vorhandenen/ausgeschlossenen Review-Status mit Zeilenzahlen; Hinweis auf ausgeschlossene Expert-Panel- und flagged-Zeilen. Nach dem Präfixfilter keine zweite Einreicherschwelle. |

## Ausgeführte Nachweise

Die vollständigen Befehle, kompakten echten Outputs und Grenzen stehen im
neuen M1d-Abschnitt von [PROGRESS.md](../../../PROGRESS.md).
Abschließende tatsächliche Ergebnisse:

```text
M1d unit tests: 15 test blocks; 0 failed expectations; 0 errors; 0 skips; 95 passed expectations
Vignette contracts: 40 test blocks; 0 failed expectations; 0 errors; 0 skips; 915 passed expectations; 112.15 seconds
Final M1d vignette contracts: 14 blocks; 0 failed expectations; 0 errors; 219 passed expectations
M1d acceptance 1-6: 59 test blocks; 3 failed expectations; 0 errors; 0 skips; 4530 passed expectations; 902.26 seconds
C-locale regeneration: all 7 frozen files (including QUELLE and SHA256SUMS) match
Status: 1 NOTE
```

Die drei fehlgeschlagenen Abnahme-Erwartungen gehören ausschließlich zu E1.
K-M1d-6 einschließlich der vier Neuläufe besteht; Ergebnisse, Replikate,
MCSE, Seeds, Sessionmetadaten und die vorgeschriebenen ersten Wiederholungen
wurden mit den unveränderten Abnahmetests geprüft. Der letzte Status stammt
aus dem vollständigen öffentlichen `R CMD check --as-cran --no-manual`:
Exit 0, keine ERRORs/WARNINGs; einzige NOTE ist die offline nicht mögliche
Zeitprüfung. Alle vier Vignetten wurden gebaut und erneut ausgeführt.

Rohlogs und ausführbare lokale Prüfscripte:
`/tmp/llmsa-m1d-build-w4061qzp/`. Sie wurden nicht in fremde
Harness-Verzeichnisse geschrieben. Der Orchestrator zeichnet die Modellphase
auf. Ausschließlich eingefrorene Abhängigkeiten; keine eigenen Git-Kommandos.

Die anfänglichen lokalen Abnahmefehler ohne `REPO_ROOT` und ein während der
UTF-8-Korrektur fehlgeschlagener CSV-Knit sind als Vorläuferlogs erhalten.
Sie wurden durch korrekte Laufumgebung bzw. Produktkorrektur behoben;
maßgeblich sind die abschließenden Läufe in PROGRESS. Abnahme- und QA-Tests,
Schwellen und Gates wurden dabei nicht geändert.

## Offene Befunde in fremden Territorien

- **E1 / M1D-INFRA-01 — [INFRA], nonblocking für den Builder.**
  **ref:** K-M1d-5; ACC-8(5); PLAN-REVIEW E1; ADR-048 Nr. 15.
  `_pkgdown.yml` enthält weiterhin keinen `articles`-Abschnitt. Der Test
  meldet deshalb drei fehlgeschlagene Erwartungen. Betreiber-Vorschlag
  bei unveränderten bestehenden Schlüsseln:

  ```yaml
  articles:
  - title: Validation
    contents:
    - validation
  - title: Applications
    contents:
    - llm-stability
    - clinvar-raters
  ```

- **M1D-QA-01 — [QA-PENDING], nonblocking für den Builder.**
  **ref:** `tests/e2e/test-m1c-qa-e2e.R:166–168`, Test
  `QA-M1c-E2E-4`; ADR-043; docs/02 K-M1d-6 und Voraussetzung; K-M1c-5
  (Vorrang vorhandener Volllauf-Ergebnisse).
  Der unveränderte QA-Test ruft `boot_read_results()` auf dem installierten
  Standardordner auf, erwartet aber stets `mode == "check"` und nur
  S-boot-1/S-boot-7. Seit den bereits vor BUILD vorhandenen Vollläufen
  liefert der vertragliche Leser dort `full`, n_sim=1000 und sieben Szenarien.
  Zwei Erwartungen in einem Testblock sind rot. Leser, QA-Test und drei
  Bootstrap-Volllaufdateien haben dieselben SHA-256 wie vor BUILD.

  Reproduktion: `Rscript --vanilla orchestrator/lib/r-tests.R tests/e2e`;
  der ausgeführte gemeinsame Lauf steht in `regression.log`. Ein zusätzlicher
  Git-freier Kontextcheck (`qa-context.log`) ergibt:

  ```text
  QA-M1c-E2E-4 context: default mode=full, n_sim=1000, 7 scenarios
  Explicit short-run directory: mode=check, n_sim=20, scenarios=S-boot-1,S-boot-7
  ```

  **Vorschlag an QA:** Für die bestehenden Kurzlauf-Erwartungen ein frisches
  temporäres Verzeichnis mit ausschließlich der unveränderten
  `boot_coverage_check_results.csv` an `boot_read_results(sim_dir)` übergeben;
  den vorhandenen Standardordner separat als Volllauf prüfen. Weder Pflicht-
  Vollläufe entfernen noch den Vorrang im Produktleser ändern. Bitte durch
  QA/Reviewer in BACKLOG aufnehmen; der Builder besitzt diese Datei nicht.

## Grenzen und anschließende Schritte

- Offizielle Git-basierte Abnahme und Gate-Fakten für M1d stehen aus.
  Die lokalen Gegenprüfungen sind Belege, kein Ersatz für diese Gates.
- ADR-047 übernimmt den **gelesenen** M1c-Mutationsbeleg (92,8 %,
  erforderlich 92,09 %). Kein neuer M1d-Mutationsscore wurde gemessen.
  Kontrolllauf nach done/M1d und Scope-Rückstellung vor M3a bleiben beim
  Betreiber.
- BL-114 bleibt Release-Arbeit: die vollständigen Studiendateien werden
  jetzt weiter mitgeliefert. BL-115 bleibt für Studienläufe relevant:
  C.UTF-8, während der zusätzliche LC_ALL=C-Lauf ausschließlich die
  Datenaufbereitung prüft.
- Die übrigen im PLAN begründeten Backlog-Vertagungen bleiben bestehen.
  BL-92 und BL-112 sind umgesetzt; die Änderungen des gemeinsamen
  BACKLOG und ihre abschließende Bewertung gehören QA/Reviewer.
