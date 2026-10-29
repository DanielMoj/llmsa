# ADR-022 — M1a Code-Review Runde 1: Durchreichweg, Eingabeprüfungen, Schwellen, Manifest und Präzision des Originalskalenmodells

## Status

Angenommen (Reviewer, `50-code-review` M1a, Runde 1, 29.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1). Ergänzt ADR-017 und ADR-018. Abnahmetests, Anker, Toleranzen, QA-Tests und `CRITERIA.json` bleiben unverändert.

## Kontext

- QA hat fünf reproduzierende Tests vorgelegt (`tests/e2e/test-m1a-qa-e2e.R`, `tests/fuzz/test-m1a-qa-fuzz.R`, QA-M1a-001 bis -005). Alle fünf sind rot (`gate-tests.log`) und halten tests und mutgate rot (`gate-mutgate.log`: roter Vorlauf). Der Reviewer hat jeden Befund nachgerechnet (REVIEW M1a r1, Nachprüfung 3). Wo die Spec schweigt, legt dieses ADR die Auslegung fest.
- Eigene Nachprüfung (REVIEW M1a r1, Nachprüfung 4): Der Vorgabepfad rechnet die Varianzverhältnisse auf der konditionierten Antwort genau. Die Restvarianz des zurückgegebenen Modells stammt aber aus der Devianzfunktion von lme4 auf den Originaldaten (ADR-018 Nr. 1). Bei großem Offset weicht sie stark ab, ohne Meldung:
  - SmLs08: 5,02e-2 statt 1,000054e-2 (konditioniert; zertifiziert 1e-2);
  - SmLs09: 153,1 statt 1,000054e-2;
  - `ic50_demo` + 1e9: relative Abweichung 8,5e-6; Komponenten 8,1e-6 · σ²_TV neben denselben, gleich gerundeten Daten ohne Offset.
  Auf allen Abnahmedaten liegt die Abweichung höchstens bei 3,6e-11.
- Spec-Stellen:
  - docs/01 §2 Nr. 4: „Randfälle sind Pflicht: fehlende Werte, unbalancierte Pläne, Komponenten an der Grenze null, Faktoren mit zwei Stufen, identische Antworten, nicht konvergierende Fits. Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“
  - docs/01 §5: „Fehlende oder nicht parsbare Antworten bleiben fehlend und werden gezählt, nie ersetzt.“
  - K-M1a-6: „Verschieben aller Werte um eine Konstante lassen Varianzkomponenten (Toleranz `ankerRef: ANK-TOL.invariance` als Anteil von σ²_TV) … unverändert“ und „`n$observations` die verbliebene Zahl“.
  - K-M1a-4: „Die Sätze höherer Schwierigkeit (`SmLs07`–`SmLs09`) werden ebenso berichtet, sind aber kein Kriterium.“
- Paketdokumentation (Builder, M1a):
  - `?msa_fit`, `@param ...`: „supplying any argument here selects a direct [lme4::lmer()] call on the original response“;
  - `?msa_fit`, `@return`: „the analysed `data`“;
  - `?msa_boot`: „An explicit fitting control passed to [msa_fit()] remains the model's refit control.“
- Drei Zitate, die `QA.md` ADR-020 zuschreibt, stehen dort nicht (REVIEW M1a r1, E39). Die Auslegungen unten stützen sich nur auf die hier genannten Stellen.

## Entscheidung

1. **Durchreichweg (`...`, `type = "numeric"`).** ADR-018 Nr. 2 bleibt: dieselbe lme4-Rechnung, keine Konditionierung, keine geschlossene Lösung, kein Abschluss, dieselben lme4-Warnungen. Dazu gilt:
   1. **Datenbezug.** Argumente, die lme4 im Datenrahmen auswertet (`subset`, `weights`, `offset`), wirken wie in einem direkten Aufruf `lme4::lmer(form, data = dat, REML = TRUE, ...)`. Ein Ausdruck wie `subset = item != "I001"` wird also in `dat` ausgewertet (Spalten `item`, `prompt`, `model`, `block`, `y`). `?msa_fit` nennt diese Spalten. Es sagt auch, dass sich zeilenbezogene Argumente auf die Zeilen nach dem Entfernen fehlender oder nicht lesbarer Antworten beziehen.
   2. **Analysierte Zeilen.** Verwirft lme4 Zeilen (über `subset` oder `na.action`), beschreiben `fit$data`, alle Felder von `fit$n` und `fit$numerics$input_rows` genau die Zeilen und Stufen, die das Modell analysiert hat:
      - `n$observations`, `nrow(fit$data)` und `length(fit$numerics$input_rows)` sind gleich `nobs(fit$model)`;
      - `n$items`, `n$prompts`, `n$models` und `n$blocks` gleichen den Stufenzahlen im Modell (Stufen ohne Beobachtung zählen nicht).
   3. **Refit.** `fit$model@call` ist selbsttragend. `control` und alle übrigen nicht datenbezogenen Argumente stehen als Werte im Aufruf oder als Ausdrücke, die ohne `..N` und unabhängig vom Gültigkeitsbereich des Aufrufers auswertbar sind. `msa_boot()`, `lme4::bootMer()` und `lme4::refit()` laufen dann auch, wenn `msa_fit()` in einer Hilfsfunktion mit lokaler Steuerung aufgerufen wurde. Die übergebene Steuerung bleibt die Refit-Steuerung. ADR-018 Nr. 3 („Refit“) gilt damit auch für den Durchreichweg.
2. **Fehlende Gruppierungswerte.** Bei `type = "numeric"` endet `msa_fit()` auf beiden Pfaden vor dem Fit mit einer benannten englischen Fehlermeldung, die „missing“ nennt, wenn `item_id`, `prompt_id`, `model_id` oder `block` einen fehlenden Wert enthält. Ordinale und binäre Zielgrößen folgen in M1b (BACKLOG).
3. **NaN.** Ein numerisches `NaN` und die Zeichenkette `"NaN"` gelten gleich als fehlender Wert wie `NA` (docs/01 §5): Sie werden entfernt, nicht als „could not be interpreted as numbers“ gemeldet und wie fehlende Werte behandelt. `?msa_fit` nennt die Regel.
4. **Schwellen in `msa_grr()`.** `threshold` ist `NULL` oder ein endlicher numerischer Vektor der Länge 2 mit 0 ≤ `threshold[1]` ≤ `threshold[2]`. Jede andere Eingabe endet mit einer benannten englischen Fehlermeldung, die `threshold` nennt. Begründung: Bisher ergaben vertauschte, negative oder nicht numerische Schwellen ein falsches Verdikt ohne Meldung (docs/01 §2 Nr. 4).
5. **Manifestprüfung (`validation_verify_resources()`, ADR-017 Nr. 7.2 und 7.3).** Die Funktion prüft:
   - (a) `anchors/` enthält genau die Dateien der Anker im Manifest;
   - (b) `datasets` ist vorhanden und nennt genau die Datensätze von ANK-14;
   - je Datensatz ist `original_sha256` gleich dem SHA-256 aus ANK-14, und `copied_sha256` trifft die gespeicherte Datei.

   Fehlt etwas oder ist etwas zu viel, folgt ein benannter Fehler.
6. **Präzision des Originalskalenmodells (Vorgabepfad).**
   1. Die Restvarianz des zurückgegebenen Modells (`sigma(fit$model)^2`) darf vom konditionierten REML-Ergebnis, auf die Originalskala zurückskaliert, höchstens um eine relative Grenze abweichen. Das numerische ADR des Builders begründet diese Grenze; sie muss `ANK-TOL.invariance` für alle Komponenten sichern. Bei Überschreitung gilt eine von zwei Lösungen:
      - ein Modell, das das genaue Ergebnis trägt und ADR-018 Nr. 1 einhält (Originalantwort, eine Quelle für Modell und `vc`);
      - ein benannter englischer Fehler.

      Ein stilles Ergebnis ist ausgeschlossen.
   2. Varianzkomponenten, die auf der Originalskala nicht mit dieser Präzision darstellbar sind, etwa im subnormalen Bereich (QA-M1a-004 Nr. 1), enden mit dem benannten Fehler, der „representable“ nennt.
   3. Für `SmLs07`–`SmLs09` ist dieser Fehler zulässig; die Vignette weist ihn als `NA` mit benanntem Grund aus (ADR-017 Nr. 3). `SmLs04`–`SmLs06` bleiben Kriterium (K-M1a-4) und dürfen nicht scheitern.
7. **Restvarianz null (QA-M1a-003).** ADR-018 Nr. 3 deckt den Fall: „… wenn das Problem kein endliches Optimum hat, etwa bei Restvarianz 0“. Präzisiert wird:
   - Die Meldung nennt „residual variance“.
   - Fehler und Warnungen von `Matrix` oder CHOLMOD erreichen den Aufrufer nicht.
   - Startwarnungen von lme4 dürfen nach ADR-020 (E17) weitergegeben werden.
   - Die Erkennung prüft nicht auf exakt 0. Eine Restquadratsumme in der Größenordnung der Rundung relativ zur Gesamtstreuung gilt als null. Die Grenze ist relativ und im numerischen ADR begründet; eine absolute Grenze für kleine Streuung gibt es weiterhin nicht (PLAN-UPDATE, Randfälle).

## Konsequenzen

- **Builder:** setzt Nr. 1 bis 7 im Rework um, jeweils mit Unit-Tests unter `tests/testthat/`. Er ergänzt ADR-020 (Grenzen zu Nr. 6 und 7), `?msa_fit`, `?msa_grr` und `NEWS.md`. Die QA-Tests werden damit grün, ohne geändert zu werden.
- **Code-Review:** prüft Nr. 1 bis 7 als Vertrag. Blocking-Befund mit Bezug auf dieses ADR ist jede stille Abweichung nach Nr. 1.2 oder Nr. 6 und jeder Fehler ohne benannte Meldung nach Nr. 2, 4, 5 oder 7.
- **Gates:** keine Änderung.
- **Rücknahme:** Ändert der Betreiber docs/01 §2 Nr. 4, docs/01 §5, K-M1a-4 oder K-M1a-6, ersetzt ein neues ADR die betroffenen Nummern.
