# ADR-037 — Auslegungen des Reviewers im Code-Review M1b, Runde 5: Abschluss von ADR-034, rote Gates aus Infrastruktur, Äquivalenzfreigaben ohne Bericht

## Status

Angenommen (Reviewer, `50-code-review` M1b, Runde 5, 01.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“).

- Ergänzt ADR-034; ADR-035 (Betreiber) gilt unverändert.
- Ändert keinen Abnahmetest, keinen QA-Test, keinen Anker und keine Toleranz.
- Einwände: E37 bis E39 in `orchestrator/handoff/M1b/REVIEW.md` (Runde 5).

## Kontext

- **Gate-Fakten Runde 5** (`orchestrator/state/M1b/gates.json`, `env.sha` `a8f8db7`): deps, trace, territory, golden-adr und mutfull `pass`; lint, tests und mutgate `fail`; `result` `fail`.
  - Alle Fehlschläge gehen auf eine Ursache zurück: `reference/quellen/data/aiag/anova_example.csv` fehlt. Die Datei ist git-ignoriert und liegt im Betreiber-Territorium.
  - lint: Der Vignettenbau bricht mit „Validation input is missing“ ab (`gate-lint.log` Z. 12–27).
  - tests: Drei AIAG-Abnahmetests brechen ab, die Vignettenprüfung von K-M1a-4 scheitert; danach endet der Ordner nach zehn Fehlschlägen (`gate-tests.log` Z. 567–686).
  - mutgate: Der unmutierte Vorlauf ist rot mit 16 Tests, alle von AIAG-Datei oder Vignette abhängig; kein Mutant lief (`gate-mutgate.log` Z. 3–21).
- Mit der Datei fehlen alle ignorierten Dateien unter `reference/quellen/**` und `reference/privat/**`. Die Verzeichniszeiten fallen in den Rollback nach der Territoriumsverletzung in Rework r5, Versuch 1 (20:25:31 bis 20:25:33; `orchestrate.log` Z. 149). Mechanismus und Maßnahmen: BL-103.
- **Umsetzung von ADR-034** in `R/fit.R:281` (Prüfgewichte) und `:433–476` (dünn besetzte Gram-Rechnung). Die Prüfläufe 3 bis 5 der REVIEW r5 bestätigen sie unabhängig:
  - 198 von 198 großen Plänen bis 5000 Stufen werden richtig entschieden. Die exakten Relationen liegen beim höchstens 0,09-Fachen der Schwelle; die Rechnung der Runde 4 erreichte auf denselben Matrizen bis zum 30,6-Fachen.
  - Bei nicht ganzzahligen Gewichten stimmen 78 von 78 Prüfungen, und die Engine erhält die Gewichte unverändert.
  - 50 reguläre Pläne erreichen die Engine mit dem 10¹¹- bis 10¹⁴-Fachen der Schwelle: AP1, die acht Simulationsszenarien sowie die Daten von K-M1b-1 und K-M1b-5, auch mit fehlenden Werten. Alte und neue Gram-Matrix stimmen dabei auf 3,4e-16 relativ überein.

## Entscheidung

1. **(E33, E34) ADR-034 ist für M1b erfüllt.**
   - Die Umsetzung entspricht ADR-034 Nr. 1 (Gram-Matrix ohne mit der Stufenzahl wachsenden Rundungsfehler, Eigenwertregel unverändert) und Nr. 2 (Vielfachheiten nur bei ganzzahligen Gewichten; Engine-Aufruf, Daten und Gewichte unverändert).
   - Weitere Glieder dieser Klasse sind nach ADR-035 Nr. 2 nicht blockierend. Sie erhalten einen BACKLOG-Eintrag mit Reproduktion und der Markierung „nach 26.11.2026“ (ADR-035 Nr. 3).
2. **(E37, E38) Rote Gates aus Infrastruktur.**
   - Ein Gate, das wegen einer fehlenden geschützten Betreiber-Datei rot ist, ist ein `[INFRA]`-Befund und für den Builder nicht blockierend (AGENTS.md, Handoff-Disziplin; SCHEMA.md). ADR-035 Nr. 1 b) begrenzt, was blockieren darf; es macht Infrastrukturursachen nicht zum Builder-Auftrag.
   - Das Fehlschlagen ist richtig: Abnahmetests schlagen fehl, wenn eine lokale geschützte Datei fehlt (AGENTS.md, Domänenregeln). Kein Rework ersetzt die Datei, umgeht die Prüfung oder überspringt den Test (AGENTS.md, Integrität Nr. 1 und 5).
   - Solange `gates.result` nicht `pass` ist, ist PASS ausgeschlossen (SCHEMA.md). Das Verdict der Runde 5 lautet deshalb REWORK mit leerem `blocking`.
   - Für Runde 6 ist keine Produktänderung verlangt. Ändert ein Rework `R/fit.R`, greifen die Freigaben aus Nr. 3 nicht mehr (BL-85). Ändert er `msa_fit()` oder `msa_latent_information()`, stimmt außerdem der Implementierungshash der Sessiondateien nicht mehr (ADR-023 Nr. 1.5).
3. **(MUT-EQUIV) Freigaben ohne Bericht.**
   - Im Gate-Lauf der Runde 5 lief kein Mutant; einen Bericht, an dem die Freigaben neu zu binden wären (ADR-034 Nr. 3), gibt es nicht.
   - Die Freigaben werden deshalb an `muttest::muttest_plan()` über den aktuellen Stand gebunden. Der Plan nutzt dieselben neun Mutatorfamilien wie `orchestrator/lib/r-mutation.R` und denselben Schlüssel wie `86-mutgate.sh` (Datei, `mutatorName`, Anfangszeile).
   - Jeder der 14 Schlüssel trifft genau die beantragten 16 Mutanten. Jeder Mutant verhält sich auf dem Prüfraster gleich wie das Original (REVIEW r5, Prüflauf 2).
   - `R/grr.R:99` „> → >=“ bleibt freigegeben.
   - Nicht freigegeben sind die unbeantragten Überlebenden `R/fit.R:331:42`, `:337:55` und `:338:74` (BL-102).
   - Den nächsten Bericht prüft der Reviewer gegen `column` und `code` (BL-85).

## Konsequenzen

- **Betreiber:**
  - stellt die gelöschten Dateien wieder her (BL-103) und lässt die Gates danach laufen;
  - setzt die Abbruchgrenze des tests-Gates außer Kraft (BL-104).
- **Builder (REWORK M1b, Runde 6):** kein blocking-Auftrag. Er legt keine Ersatzdaten an und meldet einen fortbestehenden Infrastrukturgrund als OUT-OF-TERRITORY.
- **Reviewer:** prüft in Runde 6 die Gates und den Mutationsbericht. Überlebende ohne Freigabe sind bei rotem mutgate blocking.
- **Rücknahme:** nur per Reviewer-ADR.
