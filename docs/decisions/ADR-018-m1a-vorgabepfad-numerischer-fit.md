# ADR-018 — M1a: Vorgabepfad von `msa_fit(type = "numeric")`, Auslegung von Formelsammlung §2 und Vertrag für BUILD und Code-Review

## Status

Angenommen (Reviewer, `30-plan-review` M1a, Runde 2, 28.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin; docs/01 §1). Ergänzt ADR-016 E6 und ADR-017. Abnahmetests, Anker, Toleranzen und `CRITERIA.json` bleiben unverändert.

## Kontext

- K-M1a-6 verlangt mit Paketvorgaben Invarianz auf `ANK-TOL.invariance` (1e-6 · σ²_TV je Komponente). Nach ADR-016 E6 wählt der Builder den Weg. lme4-Optimierer allein erreichen die Grenze nicht, auch eng gesteuert und auf konditionierten Daten:
  - ADR-016, Kontext ACC-6;
  - PLAN-REVIEW M1a Runde 1, Messung 1: auf `ic50_demo` bis 8,7e-6 · σ²_TV mit bobyqa und bis 1,9e-6 mit nloptwrap, auf dem simulierten Blockplan bis 3,3e-6 mit nloptwrap.
- `PLAN-UPDATE.md` (Runde 2, Antworten auf E1, E3, E4 und E8) plant deshalb einen zusammengesetzten Vorgabepfad:
  - balancierte Pläne mit nichtnegativen ANOVA-Schätzern: geschlossene Lösung über die erwarteten Mittelquadrate;
  - alle übrigen Pläne: lme4-Startfit, danach analytischer REML-Abschluss (Newton auf λ_j = σ²_j/σ²_e, aktive Menge an der Grenze 0);
  - Modellbau mit `lFormula`, `mkLmerDevfun` und `mkMerMod` am endgültigen θ, `vc` aus `VarCorr`;
  - direkter `lme4::lmer`-Pfad, sobald ein Argument in `...` steht;
  - Refit-Haken `nloptwrap` für `refit()` und `bootMer()`.
- Formelsammlung §2 (`reference/privat/07_Formelsammlung_llmsa.md`, Zeile 50): „**Schätzung (Code).** REML mit `lme4::lmer`. Negative Komponenten gibt es nicht; eine Komponente an der Grenze 0 wird als singulärer Fit gemeldet.“
  - Der Status „Code“ heißt nach dem Kopf der Sammlung (Zeile 5) „so in v0.1.0 implementiert“.
  - Die Sammlung ist Teil der Spec (docs/01 §1).
- Die Spec sagt nicht, ob „REML mit `lme4::lmer`“ nur Kriterium und Modell meint oder auch den Optimierungsschritt von `lmer`. Sie sagt auch nicht, wie ein Vorgabepfad, der nicht nur aus `lmer` besteht, Konvergenz und Fehler meldet.
- Nachgeprüft in `30-plan-review` Runde 2 (PLAN-REVIEW, Messungen 1 und 2):
  - Das Kriterium aus PLAN-UPDATE gleicht dem REML-Kriterium von lme4 bis auf eine Konstante.
  - Sein analytischer Score weicht vom Differenzenquotienten höchstens 1,8e-9 relativ ab.
  - `VCA::remlVCA` (intern `lmer` mit bobyqa) liegt auf `ic50_demo` 1,1e-6 · σ²_TV vom nahezu exakten Optimum entfernt, der Vorgabe-Fit von v0.1.0 6,7e-5 · σ²_TV.

## Entscheidung

1. **Formelsammlung §2, „REML mit `lme4::lmer`“.** Die Stelle ist erfüllt, wenn alle vier Bedingungen gelten:
   - (a) Geschätzt wird das REML-Kriterium von lme4 für das Modell der Formelsammlung §2 (`mkLmerDevfun` auf den Originaldaten).
   - (b) `fit$model` ist ein lme4-`merMod`, gebaut mit den modularen Funktionen von lme4 (`lFormula`, `mkLmerDevfun`, `mkMerMod`; die dokumentierte Zerlegung von `lmer`) am endgültigen θ.
   - (c) `fit$vc` stammt aus `VarCorr(fit$model)`.
   - (d) Keine Komponente ist negativ. Eine Komponente an der Grenze 0 ergibt `singular = TRUE` (`lme4::isSingular(fit$model)`).

   Den Optimierungsschritt darf der Vorgabepfad ersetzen:
   - durch die geschlossene Lösung (balancierter Plan, alle ANOVA-Schätzer ≥ 0; nach Formelsammlung §2 ist REML dort gleich ANOVA);
   - oder durch einen analytischen REML-Abschluss.

   Nicht erfüllt:
   - eine getrennt gerechnete `vc`-Tabelle neben einem Modell mit anderem θ;
   - jedes andere Kriterium als REML.

   Begründung:
   - Schätzer und Modellklasse bleiben die von v0.1.0. Nur der Optimierungsschritt ändert sich, und nur so erreicht der Vorgabepfad K-M1a-6 nach den Messungen.
   - lme4 sieht die modulare Zerlegung und eigene Optimierer ausdrücklich vor.
2. **Durchreichweg.** Steht in `...` irgendein Argument, rechnet `msa_fit(type = "numeric")` genau `lme4::lmer(form, data = dat, REML = TRUE, ...)` auf den Originaldaten. Konditionierung, Umordnung, geschlossene Lösung und Abschluss entfallen dann (PLAN-UPDATE E4).
   - Damit prüfen K-M1a-1 (Optimierer aus `ANK-TOL.reml_anova`) und der Nichtkonvergenztest von K-M1a-6 lme4 selbst.
   - Warnungen und Konvergenzcode von lme4 kommen unverändert beim Aufrufer an.
3. **Vorgabepfad: Endwert, Fehler, Meldungen, Refit.**
   - **Endwert:** die geschlossene Lösung oder der Punkt, an dem der analytische Abschluss sein Abbruchkriterium erfüllt. Kein späterer Optimierer verändert ihn (PLAN-UPDATE E3).
   - **Fehler:** `msa_fit()` endet mit einer benannten englischen Fehlermeldung (docs/01 §2 Nr. 4), wenn
     - der Abschluss sein Abbruchkriterium nicht erreicht oder
     - das Problem kein endliches Optimum hat, etwa bei Restvarianz 0.

     Der Startwert wird nicht als Ergebnis zurückgegeben (PLAN-UPDATE E1, E7).
   - **Warnungen:** Warnungen eines lme4-Laufs im Vorgabepfad gehen nicht verloren.
     - Sie kommen beim Aufrufer als Warnung an oder stehen mit ihrer Herkunft in `fit$numerics`.
     - Welches von beiden gilt, legen das numerische ADR und `?msa_fit` fest; ein Unit-Test prüft es.
   - **Diagnostik:** `fit$numerics` nennt das Verfahren (`closed_form` oder `analytic_reml`) und die Abschlussdiagnostik.
   - **Refit:**
     - `fit$model@optinfo` nennt einen lme4-Optimierer samt `optCtrl`.
     - Der Modellaufruf enthält einen `control`-Ausdruck, der im Kontext des Aufrufers auswertbar ist. Grund: `bootMer` in lme4 2.0.6 wertet `eval.parent(x@call$control)` aus.
     - Refits sind gewöhnliche lme4-Fits (PLAN-UPDATE E8).
4. **Maßstab der Konditionierung.** Er ist positiv, sobald nicht alle gültigen Werte gleich sind.
   - Ein Streuungsmaß, das bei vielen Gleichständen 0 wird, trägt ihn nicht allein. Beispiele: Median der absoluten Abweichungen, Interquartilsabstand.
   - Der Fehler wegen fehlender Variation gilt nur, wenn alle gültigen Werte identisch sind (K-M1a-6).
5. **Robustheitsnachweis vor Reihenfolge-Schritt 4 des PLAN-UPDATE.** Der Go/No-Go wird um zwei Gruppen von Szenarien ergänzt:
   - die numerischen Szenarien S-boot-1 bis S-boot-6 aus docs/02, M1c, simuliert mit `msa_simulate()`, Seeds 1 bis 20 je Szenario;
   - die vier Szenarien des Beispiels von `?msa_plan`, Seeds 1 bis 20 je Szenario.

   Berichtet wird je Szenario, in PROGRESS und im numerischen ADR:
   - die Zahl der Fits über `closed_form` und über `analytic_reml`;
   - die Zahl der Fehler und die Zahl singulärer Fits;
   - Median und Maximum der Laufzeit.

   Diese Daten sind nicht degeneriert (Restvarianz > 0). Ein Fehler dort gilt wie ein verfehlter Go/No-Go: Ursache beheben oder mit Datenaufbau, Seed und Diagnostik nach ADR-016 E6 dem Reviewer vorlegen.
6. **Import von `Matrix`.** Mit dem numerischen Builder-ADR zulässig (docs/01 §5: „neue Imports nur mit ADR“).
   - Das Paket bleibt ab R 4.1 installierbar und lauffähig (DESCRIPTION `Depends: R (>= 4.1)`; AGENTS.md, Projektspezifika).
   - Matrix ab 1.7 verlangt R ≥ 4.4; lme4 2.0.6 verlangt Matrix ≥ 1.5-0.
   - Das numerische ADR nennt die Mindestversion von Matrix, die der Code braucht. Eine Versionsangabe unter `Imports` muss unter R 4.1 erfüllbar sein.

## Konsequenzen

- **Builder:** setzt Nummer 1 bis 6 in BUILD um. Das numerische ADR nennt:
  - Verfahren und Abbruchgrößen;
  - das Warnungsverhalten;
  - die Mindestversion von Matrix;
  - die Messungen aus dem Go/No-Go und aus Nummer 5.
- **Code-Review:** prüft Nummer 1 bis 6 als Vertrag. Blocking-Befund mit Bezug auf dieses ADR ist:
  - eine getrennte `vc`-Rechnung (1c);
  - der Vorgabepfad trotz eines Arguments in `...` (2);
  - ein als Ergebnis zurückgegebener Startwert nach gescheitertem Abschluss (3);
  - ein Fehler wegen fehlender Variation bei nicht identischen Werten (4);
  - ein fehlender Nachweis nach Nummer 5.
- **Gates:** keine Änderung.
  - Das deps-Gate prüft `Matrix` wie jede Abhängigkeit (K-M0-1).
  - Die CI prüft nur `release`. Nummer 6 ist deshalb Gegenstand des Code-Reviews.
- **Betreiber, zur Kenntnis:** Formelsammlung §2 „Schätzung (Code)“ beschreibt v0.1.0. Nach M1a beschreibt sie den Vorgabepfad nicht mehr vollständig. Den Spec-Text ändert nur der Betreiber (docs/01 §1).
- **Rücknahme:** Ändert der Betreiber K-M1a-6, `ANK-TOL.invariance` oder Formelsammlung §2, ersetzt ein neues ADR die betroffenen Nummern.
