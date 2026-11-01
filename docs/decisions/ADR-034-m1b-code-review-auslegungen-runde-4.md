# ADR-034 — Auslegungen des Reviewers im Code-Review M1b, Runde 4: Arbeitsgenauigkeit der latenten Identifizierbarkeitsprüfung, nicht ganzzahlige Gewichte, Äquivalenzfreigaben

## Status

Angenommen (Reviewer, `50-code-review` M1b, Runde 4, 01.11.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“).

- Ergänzt ADR-029 Nr. 2 und ADR-032 Nr. 1; beide gelten unverändert weiter. ADR-030 und ADR-033 (Builder) bleiben Umsetzungsgrundlage; Nr. 2 unten schränkt ADR-033 Nr. 2 und 3 für nicht ganzzahlige Gewichte ein.
- Ändert keinen Abnahmetest, keinen QA-Test, keinen Anker und keine Toleranz.
- Einwände: E33 bis E36 in `orchestrator/handoff/M1b/REVIEW.md` (Runde 4).

## Kontext

- **Gate-Fakten Runde 4** (`orchestrator/state/M1b/gates.json`, `env.sha` `91d82c1`): alle acht Gates `pass`; mutgate 93,02 bei verlangten 90,83, ohne Freigaben 92,95.
- **Umsetzung von ADR-032 Nr. 1** in `R/fit.R:262–267`, `:297–329` und `msa_latent_information()` (`:412–454`). In kleinen Plänen ist sie exakt: Im Rastertest des Reviewers (REVIEW r4, Prüflauf 2) entscheidet das Produkt 480-mal wie eine unabhängige Rangrechnung über expandierte Beobachtungspaare. Das Verhältnis der Gram-Eigenwerte liegt bei identifizierbaren Referenzplänen bei mindestens 0,0046, bei abgewiesenen höchstens bei 6,5e-26.
- **Zwei Lücken bleiben.**
  1. **Arbeitsgenauigkeit.**
     - Jeder Eintrag G_ij entsteht als Quadratsumme über einen dichten Block der Größe L_i × L_j (`R/fit.R:434–435`). Der Rundungsfehler wächst mit der Zahl der Stufen. Bei 2000 Items mit je einer Beobachtung weicht G_11 um 4,9e-11 vom exakten Wert L − 1 ab; das sind 2,5e-14 relativ.
     - Die Eigenwertregel lässt nur k · eps zu, bei einem Term mit Restterm also 4,4e-16. Das Eigenwertverhältnis dieser exakt nicht identifizierbaren Relation beträgt 6,1e-15, und der Plan erreicht die Engine (Prüflauf 3).
     - Von 110 exakten Relationen mit 300 bis 4200 Items oder Zellen erreichen 26 die Engine, ordinal wie binär, die kleinste mit 900 Items (Prüflauf 3). Betroffen sind Items mit je einer Beobachtung, `item:prompt` mit einer Beobachtung je Zelle bei festem Prompt und Items, deren zweites Replikat das Gewicht 0 trägt.
     - Ergebnisse (Prüflauf 5): 900 Items mit je einer Beobachtung, binär: item 0, ICC_items 0, `converged` TRUE, keine Warnung. Bei 2000 Items zusätzlich `singular` FALSE.
     - Gegenprobe (Prüflauf 4): Dieselbe Gram-Matrix, aus dünn besetzten Kreuztabellen gerechnet, erkennt alle 72 geprüften exakten Relationen bis 5000 Stufen mit der unveränderten Regel. Das größte Verhältnis liegt beim 0,17-Fachen der Schwelle; die heutige Rechnung erreicht das 61-Fache. Beide Matrizen stimmen auf 1,1e-13 relativ überein.
  2. **Nicht ganzzahlige Gewichte.**
     - ADR-032 Nr. 1.2 legt nur Häufigkeitsgewichte fest („Häufigkeitsgewichte gehen als Vielfachheiten ein“).
     - Die Umsetzung setzt Vielfachheiten für jedes nichtnegative Gewicht fort (ADR-033 Nr. 2). Prüflauf 6:
       - 54 Items mit je einer Beobachtung und dem Gewicht 1,25 oder 1,5 bestehen die Prüfung. Mit 1,5 liefert der ordinale Fit item = 416,29 bei `converged` TRUE und `singular` FALSE, ohne jede Warnung.
       - Umgekehrt weist das Gewicht 0,1 einen identifizierbaren Plan ab: 18 Items × 3 Prompts × 3 Modelle × 3 Replikate mit Wechselwirkungen. Das Gewicht 1/n weist jeden Plan ab.
     - Ein nicht ganzzahliges Gewicht beschreibt keine wiederholte Beobachtung. Es fügt keine Information hinzu, die eine Komponente von der Restvarianz trennt.
- **MUT-EQUIV:** Der Builder beantragt 17 Mutanten mit endgültigen Zeilen. 16 sind verhaltensgleich (Prüflauf 7).
  - `R/fit.R:168` „FALSE → TRUE“ (`as.data.frame(runs, stringsAsFactors = TRUE)`) ist es nicht.
  - Mit einer Zeichenmatrix als `runs` erzeugt der Mutant benannte Faktorspalten. Danach trägt `fit$data` Zeichen-Zeilennamen statt automatischer, und `fit$numerics$input_rows` trägt Namen.
  - `msa_fit()` nimmt die Matrix ohne Fehler an.

## Entscheidung

1. **(E33) Arbeitsgenauigkeit; ergänzt ADR-032 Nr. 1.**
   1. Die Entscheidung nach ADR-032 Nr. 1 gilt unabhängig von der Plangröße. Exakte Relationen werden bis an die Arbeitsgenauigkeit erkannt, auch bei Tausenden Stufen eines Terms.
   2. Die Eigenwertregel bleibt unverändert: min(ev) ≤ k · eps · max(ev), mit k einschließlich des Restterms. Eine größere Schwelle oder eine neue Konstante ist nicht zulässig.
   3. Die Gram-Matrix wird deshalb so berechnet, dass ihr Rundungsfehler nicht mit der Zahl der Stufen oder Beobachtungen wächst.
      - Geprüft ist eine gleichwertige Darstellung ohne dichte Blöcke aus Stufen × Stufen. Mit den dünn besetzten Kreuztabellen N_ij = Z_iᵀWZ_j und B_j = Qᵀ√W Z_j gilt G_ij = ‖N_ij‖²_F − 2 Spur(B_i N_ij B_jᵀ) + Spur(B_iB_iᵀ B_jB_jᵀ). Restzeile, Restdiagonale und Rangnachweis bleiben wie in ADR-033 Nr. 3 und 4.
      - Ein gleichwertiges exaktes Kriterium bleibt zulässig.
   4. Nebenbei entfällt der Speicherbedarf der dichten Blöcke: Bei 5000 Stufen belegt heute jeder Block mit seinen Zwischenergebnissen mehrere 200-MB-Matrizen.
   5. Grundlage:
      - ADR-029 Nr. 2.1 und 2.2;
      - ADR-032 Nr. 1 und Konsequenzen („eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-032“);
      - docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“);
      - `orchestrator/LESSONS.md` („Rastertest über Pläne, Rauschstufen bis an die Arbeitsgenauigkeit und mehrere Seeds“).
2. **(E34) Nicht ganzzahlige Gewichte; ergänzt ADR-032 Nr. 1.2.**
   1. Sind alle Gewichte ganze Zahlen, gehen sie wie bisher als Vielfachheiten ein.
   2. Andernfalls zählt für die Prüfung jede Zeile mit positivem Gewicht genau einmal. Zeilen mit Gewicht 0 zählen weiterhin nicht.
      - Das gilt auch für die Prüfung des festen ordinalen Rangs und für den Rangnachweis aufgespannter Terme.
      - Grundlage ist ADR-032 Nr. 1.2: „Grundlage der Prüfung ist die Information, die in die Likelihood eingeht.“
   3. Engine-Aufruf, Engine-Daten und Gewichte bleiben unverändert. Identifizierbare Pläne behalten exakt ihren Fit (ADR-029 Nr. 2.4).
   4. Ein pauschaler Fehler für nicht ganzzahlige Gewichte setzt Nr. 2 nicht um. Er wiese identifizierbare Pläne ab und änderte eine bestehende Schnittstelle (AGENTS.md, Schnittstellenregel).
   5. `?msa_fit` und `NEWS.md` nennen die Regel.
3. **(MUT-EQUIV) Freigaben M1b, Runde 4.**
   - **Freigegeben** sind 16 Mutanten unter 14 Schlüsseln, jeweils einzeln geprüft (Begründungen in `MUT-EQUIV-APPROVED.json`, Belege in REVIEW r4, Prüflauf 7):
     - `R/fit.R:299`, `:300`, `:314`, `:400` (drei Spalten, alle beantragt), `:424`, `:431` (zweimal), `:501` (zweimal), `:586` (zweimal), `:687`, `:689`, `:695`.
     - `R/grr.R:99` „> → >=“ bleibt freigegeben.
   - Jeder Schlüssel trifft im Bericht der Runde 4 genau die beantragten Mutanten.
   - **Nicht freigegeben** ist `R/fit.R:168` „FALSE → TRUE“ (Gegenbeispiel im Kontext).
     - Die M1a-Freigabe desselben Mutanten (damals `R/fit.R:118`) wird nicht fortgeführt.
     - Abhilfe: das wirkungslose Argument entfernen. `stringsAsFactors = FALSE` ist für Datenrahmen ohne Wirkung und für Listen und Matrizen ab R 4.0 die Vorgabe; DESCRIPTION verlangt R ≥ 4.1. Alternativ ein Test.
   - Die veralteten Einträge `R/fit.R:398` und `:405` sind entfernt. Sie trafen im Bericht der Runde 4 keinen Mutanten.
   - Jede Freigabe trägt zusätzlich Spalte und Quellzeile (Felder `column` und `code`). Das Gate liest sie nicht; nach dem nächsten Rework prüft der Reviewer jeden Treffer gegen sie (BL-85).

## Konsequenzen

- **Builder (REWORK M1b, Runde 5):**
  - setzt Nr. 1 und 2 um;
  - belegt Nr. 1 mit Unit-Tests bei gesperrten Engines, ordinal und binär, in Größen, in denen die heutige Rechnung versagt. Jeweils endet der Plan mit dem benannten Fehler vor dem Engine-Aufruf:
    - mindestens 900, 1500 und 2000 Items mit je einer Beobachtung;
    - Items × 2 Prompts mit Wechselwirkungen und einer Beobachtung je Zelle, mindestens 1200 Zeilen (ordinal Prompt fest, binär zufällig);
    - Items mit Gewicht 0 im zweiten Replikat, mindestens 900 Items;
    - in Modellen verschachtelte Items mit Wechselwirkungen, mindestens 1000 Items;
    - gleich große identifizierbare Vergleichspläne erreichen die Engine: drei Beobachtungen je Item, zwei Replikate je Zelle, Einzelbeobachtungen plus ein doppelt beobachtetes Item;
  - belegt Nr. 2 mit Unit-Tests. Bei Einzelbeobachtungen mit den Gewichten 1,25 und 1,5 endet der Plan benannt vor der Engine. Mit 0,1 und 1/n erreicht der identifizierbare Plan aus dem Kontext die Engine. Ganzzahlige Gewichte 2 verhalten sich unverändert, gemischte Gewichte werden geprüft;
  - schreibt Tests, die die Mutanten der Änderung töten, und hält die Laufzeit der Unit-Tests klein (mutgate wiederholt sie je Mutant);
  - erzeugt die neun `_check_`-Dateien neu (ADR-023 Nr. 1.5) und ergänzt `?msa_fit` und `NEWS.md`.
- **Reviewer:** prüft Nr. 1 und 2 im nächsten Code-Review als Vertrag; eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-034. Er bindet die Freigaben aus Nr. 3 am nächsten Bericht neu.
- **Rücknahme:** nur per Reviewer-ADR.
