# ADR-032 — Auslegungen des Reviewers im Code-Review M1b, Runde 3: feste latente Restvarianz und Gewichte in der Identifizierbarkeitsprüfung, Äquivalenzfreigaben

## Status

Angenommen (Reviewer, `50-code-review` M1b, Runde 3, 01.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“).

- Ergänzt ADR-029 Nr. 2. ADR-023, ADR-025, ADR-027 und ADR-029 gelten unverändert weiter. ADR-030 (Builder) bleibt als Umsetzung des Gram-Kriteriums gültig; Nr. 1 unten erweitert dessen Gegenstand.
- Ändert keinen Abnahmetest, keinen QA-Test, keinen Anker und keine Toleranz.
- Einwände: E29 bis E32 in `orchestrator/handoff/M1b/REVIEW.md` (Runde 3).

## Kontext

- **Gate-Fakten Runde 3** (`orchestrator/state/M1b/gates.json`, `env.sha` `6f45bf7`): alle acht Gates `pass`; mutgate 92,14 bei verlangten 91,83, ohne Freigaben 1207 / 1314 = 91,86.
- **Umsetzung von ADR-029 Nr. 2** in `R/fit.R:302–310` und `msa_latent_information()` (`R/fit.R:396–422`). Der Rastertest des Reviewers (REVIEW r3, Prüflauf 2) umfasst 388 zufällige ordinale und binäre Pläne: gekreuzt, mit gelöschten Zeilen, verschachtelt, mit und ohne Wechselwirkungen.
  - Die Entscheidung des Builders stimmt in allen 381 geprüften Plänen mit einer unabhängigen Rangrechnung über vec(P Z_i Z_iᵀ P) aus Beobachtungspaaren überein: 290 identifizierbar, 91 abgewiesen.
  - Das Verhältnis der Singulärwerte liegt bei identifizierbaren Plänen bei mindestens 0,216, bei abgewiesenen höchstens bei 2e-14.
  - Das Kriterium ist für seine Definition exakt umgesetzt.
- **Zwei Lücken der Klasse bleiben.** Beide gehen auf die Definition in ADR-029 zurück (Kontext und Nr. 2.3), nicht auf die Umsetzung.
  1. **Feste latente Restvarianz.**
     - Auf der latenten Skala normiert die Restvarianz (1 bei Probit, π²/3 bei Logit) die Skala; Schwellen und feste Effekte sind frei. Bestimmbar sind deshalb nur die Verhältnisse σ²_i / σ²_Rest.
     - Ist die projizierte Kovarianz eines Zufallsterms oder einer Linearkombination linear abhängig von der projizierten Einheitsmatrix der Beobachtungen, lässt sich seine Varianz nicht von der Restvarianz trennen. Der häufigste Fall ist ein Zufallsterm mit genau einer Beobachtung je Stufe (Z_i Z_iᵀ = I). Beispiele: `item:prompt` mit `interactions = TRUE` bei einem Modell und einem Replikat, oder `item` bei einem Prompt, einem Modell und einem Replikat.
     - Beim Probit-Link ist das exakt: Die exakte Profil-Likelihood ist flach. REVIEW r3, Prüflauf 1b, ordinal, eine Beobachtung je Item: −119,7427357931 für σ²_item = 0; 0,25; 1 und 4.
     - Beim Logit-Link bleibt nur die Formabweichung der logistisch-normalen Faltung von der logistischen Verteilung, praktisch keine Information.
     - Der numerische Pfad endet in denselben Plänen benannt: „number of levels of each grouping factor must be < number of observations“.
     - Befunde (Prüfläufe 1 und 3):
       - `ordinal::wine` mit `interactions = TRUE`, Probit: item 55,49, prompt 27,08, item:prompt 87,16 bei `converged` TRUE und `singular` FALSE. Gemeldet werden nur rohe clmm-Warnungen „no. random effects (=72) >= no. observations (=72)“. Ohne Wechselwirkungen: item 0,911, prompt 0,422.
       - Binär, 30 Items × 4 Prompts, ein Modell, ein Replikat, `interactions = TRUE`: item:prompt ≈ 0, ICC_items je nach Seed zwischen 0,05 und 0,53. Je Link endet 1 von 10 Fits ohne Warnung, nicht singulär und konvergiert. Sonst erscheint nur die Singularitätsnotiz, die den Punktschätzer als gültig ausweist.
     - Im Rastertest weist das um die Einheitsmatrix erweiterte Kriterium 24 der 290 vom Builder angenommenen Pläne ab. Alle 24 enthalten einen Zufallsterm mit genau einer Beobachtung je Stufe.
     - Identifizierbar bleiben mit einem Eigenwertverhältnis von mindestens 7,8e-4 (Prüflauf 3): S-ord-1 bis S-ord-4, S-bin-1 und S-bin-2, S-two-1 und S-two-2, S-ord-1 mit allen Wechselwirkungen, wine ohne Wechselwirkungen und BeetlesMale.
     - Ebenso unberührt bleiben alle latenten Fits der bestehenden Testsuiten (Prüflauf 7):
       - Abnahme K-M1b-1, -4, -5, -6, -7 (Vignette): 25 Prüfungen, kleinstes Verhältnis 0,0059;
       - K-M2-6/-7 mit AP1-Attrappen: 30 Prüfungen, 8,3e-4;
       - Unit-Tests: 111 Prüfungen, 0,0020;
       - QA: 9 Prüfungen.
  2. **Gewichte.**
     - Die Prüfung rechnet auf allen Zeilen, auch auf Zeilen mit Gewicht 0. Diese tragen zur Likelihood nichts bei.
     - Beispiel (Prüflauf 4): Prompt und Modell haben auf den Zeilen mit positivem Gewicht dieselbe Partition.
       - Mit `subset` endet der Fit mit dem benannten Fehler.
       - Mit `weights` = 0/1 liefert der ordinale Fit in 5 von 5 Seeds still prompt = model, etwa 0,0545, bei `converged` TRUE, `singular` FALSE und ohne Warnung.
       - Binär ist die Aufteilung beliebig, einmal ohne jede Warnung.

## Entscheidung

1. **(E29) Ergänzung zu ADR-029 Nr. 2.**
   1. Die Prüfung vor dem ordinalen und dem binären Engine-Aufruf bezieht die feste latente Restvarianz ein.
      - Kriterium: das Gram-Kriterium aus ADR-029 über die Indikatormatrizen aller Zufallsterme und zusätzlich über die Einheitsmatrix der Beobachtungen (Restterm).
      - Es gilt dieselbe Eigenwertregel, mit k als Zahl der Matrizen einschließlich des Restterms.
      - Ein gleichwertiges exaktes Kriterium ist zulässig.
   2. Grundlage der Prüfung ist die Information, die in die Likelihood eingeht.
      - Zeilen mit Gewicht 0 zählen nicht. Häufigkeitsgewichte gehen als Vielfachheiten ein; das gilt auch für binomiale Vorgewichte bei 0/1-Antworten.
      - Gleichwertig ist die gewichtete Darstellung: Z_iᵀWZ_j und XᵀWX statt Z_iᵀZ_j und XᵀX. Für den Restterm gelten Spur(Z_jᵀWZ_j) − ‖R⁻ᵀXᵀWZ_j‖²_F mit XᵀWX = RᵀR sowie Σw − p.
      - Der Rangnachweis aufgespannter Terme (ADR-030 Nr. 4) rechnet auf derselben Darstellung.
   3. Ein Verstoß endet vor dem Engine-Aufruf mit einer benannten Fehlermeldung, nicht mit einer Warnung (ADR-029 Nr. 2.6).
      - Ist die Restvarianz beteiligt, nennt die Meldung den Grund verständlich, etwa: Ein Zufallsterm mit einer Beobachtung je Stufe lässt sich nicht von der festen latenten Restvarianz trennen.
      - Die bestehenden Teilzeichenketten bleiben („not identifiable“ und die Termnamen).
   4. Unverändert gilt ADR-029 Nr. 2.4: Identifizierbare Pläne behalten exakt den bisherigen Fit. Die Kurzlauf-CSVs bleiben bytegleich, die Sessiondateien tragen den neuen Implementierungshash.
   5. Grundlage:
      - docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“);
      - ADR-029 Nr. 2.1 („wenn die Varianzen der Zufallsterme, einschließlich der Wechselwirkungen, nach Abzug des festen Teils nicht getrennt identifizierbar sind“) und Nr. 2.2 („Das gilt als Klasse“);
      - `orchestrator/LESSONS.md`.
2. **(MUT-EQUIV) Freigaben M1b.**
   - Der Reviewer prüft die vier Betreiberfreigaben aus ADR-031 Nr. 1 einzeln und bestätigt sie. Jeder der vier Schlüssel aus Datei, Mutator und Zeile trifft genau einen Mutanten des Berichts (Begründungen in `MUT-EQUIV-APPROVED.json`, Belege in REVIEW r3, Prüflauf 5).
   - Entscheidung zu ADR-031 Nr. 2: `R/grr.R:99` `<n> - 1 → <n> - 1` (`grr_v > -1`) ist auf nichtnegativen Komponenten äquivalent (Prüflauf 5), wird aber nicht freigegeben.
     - Das Gate ordnet Freigaben über Datei, Mutator und Zeile zu (BL-85). Dieser Schlüssel trifft vier Mutanten der Zeile (Spalten 25, 54, 61, 70); nur Spalte 54 ist äquivalent.
     - Eine Freigabe würde drei nicht äquivalente Mutanten mit freigeben, sobald einer von ihnen überlebt. Das widerspricht SCHEMA.md („Nur einzeln vom Reviewer approvte, nachweislich verhaltensgleiche Mutanten verlassen den Nenner.“).
   - Korrektur zu ADR-031 Nr. 1:
     - Der in M1a freigegebene Mutant „damals Zeile 357“ ist `gram <- curvature <- matrix(0, k, k)` in `msa_numeric_reml()`. Heute steht er in `R/fit.R:554`, und beide Mutanten dort überleben weiter.
     - `R/fit.R:405` gehört zu `msa_latent_information()`, die es in M1a nicht gab.
     - Die Freigabe von `R/fit.R:405` trägt deshalb der eigene Beweis, nicht die M1a-Freigabe.
   - Freigaben bleiben an Zeilen gebunden (BL-85). Nach dem Rework der Runde 4 bindet der Reviewer sie anhand des neuen Berichts neu.
3. **(E32) Numerischer Durchreichweg.**
   - Mit einem Argument in `...` fittet `msa_fit(type = "numeric")` direkt mit `lme4::lmer()`. In konfundierten Plänen geschieht das still: Bei Prompt und Modell mit derselben Partition über `subset` sind prompt 0,0994, model 0,0035, prompt:model 0,0127, `converged` TRUE und keine Warnung (Prüflauf 6). Der Vorgabepfad bricht benannt ab.
   - Das Verhalten stammt aus M1a, ist dokumentiert („Explicit lme4 arguments retain lme4 warnings and errors.“) und liegt außerhalb der M1b-Kriterien.
   - Kein Builder-Auftrag in M1b. BL-100 hält es für die Planung von M1c fest.

## Konsequenzen

- **Builder (REWORK M1b, Runde 4):**
  - setzt Nr. 1 um;
  - belegt das mit Unit-Tests, ordinal und binär, beide Links:
    - ein Zufallsterm mit einer Beobachtung je Stufe, etwa `item:prompt` mit `interactions = TRUE` bei einem Modell und einem Replikat, und Items mit je einer Beobachtung: je ein benannter Fehler vor dem Engine-Aufruf;
    - Gewichte 0/1, die auf den Zeilen mit positivem Gewicht eine Partition teilen: derselbe Fehler wie mit `subset`;
    - die unabhängige Paarrechnung um vec(P) erweitert;
    - unveränderte Komponenten identifizierbarer Pläne, auch mit Gewichten ungleich 1, gegen direkte Engine-Fits;
  - schreibt Tests, die die Mutanten der Erweiterung töten;
  - erzeugt die neun `_check_`-Dateien neu (ADR-023 Nr. 1.5);
  - ergänzt `?msa_fit` und `NEWS.md`.
- **Reviewer:** prüft Nr. 1 im nächsten Code-Review als Vertrag; eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-032.
- **Betreiber:** BL-100 (Nr. 3) bei der Planung von M1c entscheiden.
- **Rücknahme:** nur per Reviewer-ADR.
