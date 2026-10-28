# ADR-017 — Auslegungen des Reviewers zu M1a: Orakel, AIAG-Toleranzen, NIST, Nullfall, Vignette außerhalb des Repos

## Status

Angenommen (Reviewer, `30-plan-review` M1a, Runde 1, 28.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1). Nummer 1 bis 5 halten die Verträge der bestehenden Abnahmetests fest und ändern sie nicht. Nummer 6 und 7 entscheiden zwei Punkte, die `orchestrator/handoff/M1a/PLAN.md` (Runde 1) ausdrücklich zur Prüfung vorlegt. Eine zweite Planrunde darf Nummer 6 und 7 präzisieren, aber nicht stillschweigend ändern.

## Kontext

- `orchestrator/handoff/M1a/CRITERIA.json` führt fünf Auslegungen, zu denen der Reviewer in `30-plan-review` ein ADR schuldet: ACC-3, ACC-4, ACC-9, ACC-10 und ACC-18. PLAN.md bestätigt alle fünf (Tabelle „Behandlung der Acceptance-Verträge“).
- Die Spec schweigt jeweils zu einem Teil:
  - K-M1a-3 (b) nennt für `SixSigma::ss.rr` weder die Zielgröße von `ss.data.rr` noch `alphaLim` (ACC-3).
  - K-M1a-3 (a) nennt für die AIAG-Daten kein Modell (ACC-4).
  - K-M1a-4 lässt die Abbildung der Dateien, die LRE-Formel im Randfall und die Ablesung der Marge offen (ACC-9).
  - K-M1a-2 und ANK-10 enthalten gedruckte Werte mit unterschiedlicher Stellenzahl. Die halbe Einheit der letzten Stelle (docs/01 §2 Nr. 6) trägt nicht für alle Werte (ACC-10, ANK-10 `tolerance_note`).
  - K-M1a-3 (c) nennt keine Optimierer-Einstellung (ACC-18).
- Nullfall in K-M1a-5: „der Fall σ²_GRR = 0 liefert `ndc = Inf` und `verdict = "acceptable"`, der Fall σ²_TV = 0 liefert `verdict = "undetermined"` ohne Fehler“. σ²_TV = 0 schließt σ²_GRR = 0 ein. Für ndc, Prozentwerte und ICC bei σ²_TV = 0 sagt die Spec nichts. K-M1a-6 verbietet `NaN` in `summary`.
- Bau der Vignette außerhalb des Repos: K-M1a-7 verlangt „die Werte werden im Code der Vignette berechnet und aus `reference/anchors/` gelesen, nicht abgetippt, und `R CMD check` baut die Vignette ohne ERROR und WARNING“. `.Rbuildignore` schließt `^reference$` aus. Geprüft am 28.10.2026 mit R 4.6.1:
  - `R CMD build` baut Vignetten in einer vollständigen Kopie des Quellbaums. Erst danach entfernt es die `.Rbuildignore`-Pfade (`tools:::.build_packages`: `prepare_pkg()` vor `inRbuildignore()`).
  - `R CMD check` baut die Vignette aus dem Tarball neu; dort fehlt `reference/`.
  - `orchestrator/verifier.sh` exportiert `REPO_ROOT` an jedes Gate (Zeile 31), also auch an `orchestrator/lib/r-check.sh`. In GitHub Actions ist `REPO_ROOT` nicht gesetzt.
  - Für den Bau ohne Repository sagt die Spec nichts. Lokale geschützte Daten (AIAG) dürfen nie ins Paket (docs/01 §6, §7; BL-09).

## Entscheidung

1. **(ACC-3) `ss.rr` in K-M1a-3 (b).**
   - Aufruf wie im Beispiel der Hilfe: `SixSigma::ss.rr(var = "time1", part = "prototype", appr = "operator", data = ss.data.rr)`, sonst mit den Paketvorgaben (`errorTerm = "interaction"`, `alphaLim = 0.05`).
   - `msa_fit()` läuft mit `interactions = TRUE`; die Wechselwirkung steht damit im Modell.
   - Verglichen werden die Komponenten Residual, prompt, item:prompt und item mit `ANK-TOL.oracle` (Komponentenwert · σ²_TV des Orakels). Poolt `ss.rr` die Wechselwirkung nach seinem Test und fehlt deshalb die Zeile `prototype:operator`, gilt ihre Komponente als 0.
   - % Studienvariation des Orakels wird aus der ungerundeten Spalte `StdDev` berechnet (`ANK-TOL.oracle.derived_rel_tol`). ndc ist gleich `ncat`.
   - Die wörtlichere Lesart ist für REML nicht erfüllbar: Wechselwirkung im Endmodell erzwungen, `alphaLim = 1`. Bei `time1` ist der ANOVA-Schätzer der Wechselwirkung negativ, bei `time2` der des Prüfers. `ss.rr` setzt ihn ohne Neuschätzung auf 0. REML schätzt die übrigen Komponenten neu; nach Formelsammlung §2 ist das der dokumentierte Unterschied, kein Fehler.
2. **(ACC-4) Modelle auf den AIAG-Daten in K-M1a-3 (a).**
   - Kriterium sind `VCA::remlVCA` und `VCA::anovaVCA` im Modell des Handbuchs: Wechselwirkung gepoolt, `msa_fit(..., interactions = FALSE)`, wie K-M1a-2 und BL-22.
   - Zusätzlich Kriterium ist `remlVCA` mit Wechselwirkung (REML gegen REML, `interactions = TRUE`).
   - `anovaVCA` mit Wechselwirkung ist kein Kriterium. Der ANOVA-Schätzer der Wechselwirkung ist negativ (Formelsammlung §2).
   - `ic50_demo` läuft im Vorgabemodell von `msa_fit()` (`interactions = TRUE`, mit Block). `anovaVCA` wird dort nur berichtet (ADR-016 E2).
3. **(ACC-9) NIST in K-M1a-4.**
   - Daten aus `../quellen/daten/nist-strd-anova_2026-10-22/<Name>.dat` mit der SHA-256 aus ANK-14. Eine fehlende Datei ist ein Fehlschlag; eine abweichende SHA-256 bricht ab.
   - Abbildung: `item_id` = Behandlung, `rep` = laufende Nummer innerhalb der Behandlung, je ein Prompt, Modell und Block. `msa_fit()` läuft mit Paketvorgaben.
   - Referenz der Item-Komponente: (MS_between − MS_within) / Replikate je Zelle, aus den zertifizierten Werten.
   - LRE = −log10(|x − c| / |c|), `Inf` bei x = c.
   - Die Marge der mittleren Schwierigkeit kommt aus `ANK-TOL.nist_digits`; Regeltext und Zitat müssen übereinstimmen.
   - SmLs07 bis SmLs09 werden nur berichtet. Ein Fehler von `msa_fit()` dort ist kein Fehlschlag; die Vignette weist ihn als `NA` mit benanntem Grund aus.
   - Die Vignette zeigt je Datensatz SmLs04 bis SmLs09 vier LRE-Einträge: `msa_fit` und `aov`, je für Rest und Item.
4. **(ACC-10) Toleranzen von K-M1a-2.**
   - Die Varianzen von EV, AV, GRR und PV werden mit `ANK-TOL.reml_anova.component_tol_fraction_of_total_variance` · σ²_TV verglichen, σ²_TV = gedrucktes σ²_GRR + σ²_PV. Dasselbe gilt für ihre gedruckten Standardabweichungen, quadriert auf der Varianzskala.
   - TV (drei Stellen): halbe Einheit der letzten Stelle plus REML-Toleranz · σ²_TV / (2 · TV).
   - Prozentwerte (eine Stelle): halbe Einheit plus `derived_rel_tol` · |Wert|.
   - ndc gleich.
   - Begründung: Das Handbuch rundet Zwischenergebnisse (ANK-10 `tolerance_note`). Die halbe Einheit gilt nach docs/01 §2 Nr. 6 nur, „sofern der Anker nichts anderes belegt“.
   - `msa_fit()` läuft mit Paketvorgaben außer `interactions = FALSE`; die Optimierer-Einstellung von `ANK-TOL.reml_anova` gilt hier nicht (ADR-016 E3).
   - Mit `interactions = TRUE` wird nur berichtet. Geprüft wird, dass Fit und `msa_grr()` laufen, alle Größen endlich sind und keine Komponente negativ ist.
5. **(ACC-18) Penicillin in K-M1a-3 (c).**
   - `msa_fit()` läuft mit Paketvorgaben: Item = `sample`, Prompt = `plate`, `interactions = FALSE`.
   - Die Toleranz folgt ANK-13 (ADR-016 E1).
   - Die Optimierer-Einstellung von `ANK-TOL.reml_anova` gilt nur für K-M1a-1. ADR-016 E3: „Das gilt für die Prüfungen, die die Optimierer-Einstellung aus `ANK-TOL.reml_anova` übernehmen (K-M1a-1).“
6. **(K-M1a-5, Nullfall) `msa_grr()` und `grr_stats()`.** Gilt auch für `msa_boot()`, das `grr_stats()` teilt.
   - σ²_TV > 0: Es gelten die Formeln der Formelsammlung §3.
     - σ²_GRR > 0: ndc = max(1, ⌊1,41 · σ_PV/σ_GRR⌋), auch für σ²_PV = 0.
     - σ²_GRR = 0: ndc = `Inf`; das Verdikt folgt den Schwellen und ist mit den Vorgaben `acceptable`.
   - σ²_TV = 0, also alle Komponenten 0: Der speziellere Fall geht vor.
     - `verdict = "undetermined"`, ohne Fehler.
     - Varianzen und Standardabweichungen sind 0.
     - `NA_real_`, weder `NaN` noch `Inf`, gilt für `pct_contribution` und `pct_study_var` aller Tabellenzeilen. Ebenso für `grr_pct_study_var`, `grr_pct_contribution`, `repeatability_pct_study_var`, `reproducibility_pct_study_var`, `icc_items` und `ndc` in `summary`.
     - Die Druckausgaben von `msa_grr` und `msa_fit` unterscheiden `NA` und `Inf` und zeigen kein `NaN`.
   - Begründung: 0/0 ist unbestimmt. `ndc = Inf` würde eine unendliche Auflösung behaupten, wo keine Variation vorliegt.
7. **(K-M1a-7) Bau der Vignette außerhalb des Repos.** Zulässig ist der Entwurf aus PLAN.md mit zwei Ausführungskontexten unter diesen Bedingungen:
   1. **Vollmodus.** Er gilt genau dann, wenn `REPO_ROOT` gesetzt und nicht leer ist.
      - Anker kommen nur aus `$REPO_ROOT/reference/anchors/`.
      - Das AIAG-Blatt kommt aus `$REPO_ROOT/reference/quellen/data/aiag/anova_example.csv`.
      - Die NIST-Originale kommen aus `dirname($REPO_ROOT)/quellen/daten/nist-strd-anova_2026-10-22/`, je mit Prüfung der SHA-256 aus ANK-10 bzw. ANK-14.
      - Fehlt eine Eingabe oder weicht sie ab, bricht das Knitten benannt ab. Ein Rückfall in den öffentlichen Modus findet bei gesetztem `REPO_ROOT` nicht statt.
      - Das ist der Kontext des Abnahmetests (ACC-14) und des lint-Gates.
   2. **Öffentlicher Modus ohne `REPO_ROOT`.**
      - Er liest Anker nur aus ganzen, byte-identischen Kopien unter `inst/validation/numeric/anchors/`.
      - Die Kopien erzeugt ausschließlich `data-raw/make_validation_numeric.R`; sie werden nie von Hand bearbeitet.
      - Ein Manifest (`inst/validation/numeric/SOURCES.json`) nennt je Kopie den Originalpfad und die SHA-256 von Original und Kopie.
      - Die Kopien sind Dokumentationseingaben. Keine Datei unter `R/` liest sie, und keine Abnahmeprüfung stützt sich auf sie.
   3. **Driftwache im Test-Gate.**
      - Ein Test unter `tests/testthat/` vergleicht jede Kopie byteweise oder per SHA-256 mit ihrem Original unter `reference/anchors/`. Er prüft auch, dass die Menge der Kopien die Menge der Anker umfasst, die die Vignette liest.
      - Ist `REPO_ROOT` gesetzt oder ein Repository mit `reference/anchors/` oberhalb des Testverzeichnisses erreichbar, schlagen fehlende Originale und jede Abweichung fehl.
      - Überspringen ist nur erlaubt, wenn kein Repository erreichbar ist, also bei `R CMD check` des Tarballs ohne `REPO_ROOT`.
      - Ändert der Reviewer später einen Anker (mit ADR), erzeugt der Builder die Kopien im selben oder nächsten Meilenstein neu.
   4. **Geschützte Daten.**
      - In keinem Modus gibt die Vignette Rohwerte des AIAG-Blatts aus; sie zeigt nur Kennzahlen.
      - Im öffentlichen Modus tragen die AIAG-Zeilen den erwarteten Wert aus der Kopie und als beobachteten Wert den Vermerk „not rerun: protected data required“. Das Ergebnis ist nie PASS.
   5. **Freie NIST-Daten** liegen unter `inst/extdata/nist-strd-anova_2026-10-22/` nach docs/01 §7:
      - `SHA256SUMS` und eine englische `QUELLE.txt` mit Quelle, URL, Stand, Lizenz, Auswahlregel und Skript;
      - Erzeugung durch das Skript unter `data-raw/`;
      - Grenzen aus `ANK-TOL.data_size`; Dateien über 100 KB als `.csv.gz` mit deterministischem gzip-Kopf;
      - Zahlentokens erhalten, sodass das Einlesen dieselben Doubles ergibt wie die Originale;
      - Builder-ADR im selben Meilenstein (golden-adr).
   6. **Rechnen beim Knitten.**
      - Beide Modi rechnen jeden beobachteten Wert beim Knitten mit dem geladenen Paketnamespace neu. Es gibt keine eingefrorenen Paket- oder Orakelausgaben.
      - Jede Datei, die die Vignette einliest oder per `source()` ausführt, unterliegt derselben Literalregel wie das Rmd (ACC-14). Ein Builder-Test prüft das.
   7. **Reduzierter öffentlicher Modus.** Statt des öffentlichen Rechenmodus darf der Builder ihn im PLAN-UPDATE erklären:
      - Ohne `REPO_ROOT` enthält der Abschnitt einen Hinweis, dass die Referenzprüfungen die Anker und lokalen Daten des Repositorys brauchen und im Harness laufen.
      - Ohne Tabellen, ohne Ankerkopien und ohne NIST-Daten unter `inst/extdata/`.
      - Der Vollmodus bleibt unverändert.
      - Die Wahl fällt im PLAN-UPDATE, nicht erst im BUILD.
   - Begründung: Byte-identische, im Test-Gate geprüfte Kopien sind „aus `reference/anchors/` gelesen“ im Sinn von K-M1a-7 und AGENTS.md, Integrität Nr. 7. Ihre Herkunft ist maschinell an die Originale gebunden, und `reference/anchors/` bleibt die einzige redaktionelle Quelle. Die Freiheit von `inst/validation/**` (Builder-Territorium, AGENTS.md Projektblock) wird damit für Dokumentationseingaben genutzt, nicht für neue Referenzwerte.

## Konsequenzen

- Abnahmetests, Anker, `CRITERIA.json` und Spec bleiben unverändert. Nummer 1 bis 5 beschreiben, was die Tests bereits prüfen.
- Builder:
  - setzt Nummer 6 in `R/grr.R` um (PLAN-REVIEW M1a E11);
  - erklärt im PLAN-UPDATE für Nummer 7, ob er den öffentlichen Rechenmodus mit den Bedingungen 1 bis 6 oder den reduzierten Modus (Nummer 7.7) baut (PLAN-REVIEW M1a E10).
- Code-Review: prüft Nummer 6 und 7 als Vertrag. Fehlt die Driftwache (7.3) oder liest eine Datei unter `R/` die Kopien, ist das ein blocking-Befund mit Bezug auf dieses ADR.
- Gates:
  - Das lint-Gate baut die Vignette im Vollmodus, weil `REPO_ROOT` exportiert ist.
  - Den öffentlichen Modus prüfen der eigene Paketcheck des Builders ohne `REPO_ROOT` und GitHub Actions.
  - golden-adr verlangt für `inst/extdata/nist-strd-anova_2026-10-22/` ein Builder-ADR. Dieses ADR ersetzt es nicht.
- Rücknahme: Ändert der Betreiber K-M1a-5 oder K-M1a-7 oder die Datenregeln in docs/01 §7, ersetzt ein neues ADR die betroffenen Nummern.
