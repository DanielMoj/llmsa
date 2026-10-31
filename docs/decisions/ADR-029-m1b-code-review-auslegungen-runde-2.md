# ADR-029 — Auslegungen des Reviewers im Code-Review M1b, Runde 2: Volllauf-Fixture, Identifizierbarkeit latenter Zufallskomponenten, Namespace-Lebenszyklus von QA-M1b-004, Zählung gewichteter ordinaler Fits

## Status

Angenommen (Reviewer, `50-code-review` M1b, Runde 2, 31.10.2026). Bindet nach dem Ende der Planrunden (AGENTS.md, Handoff-Disziplin: „Schweigt die Spec, bindet nach Ende der Planrunden das Reviewer-Urteil und wird als ADR dokumentiert.“).

- Ergänzt ADR-027; ADR-023, ADR-025 und ADR-027 gelten unverändert weiter. Nr. 2 erweitert ADR-027 Nr. 3.
- Ändert genau einen Abnahmetest, die Fixture in `tests/acceptance/test-m1b-7-vignette-full-results.R` (Nr. 1). Kein QA-Test, kein Anker, keine Toleranz ändert sich.
- Einwände: E24 bis E26 in `orchestrator/handoff/M1b/REVIEW.md` (Runde 2).

## Kontext

- **Gate-Fakten Runde 2** (`orchestrator/state/M1b/gates.json`, `env.sha` `5764521`): `tests` fail, alle anderen sieben Gates pass, mutgate mit 91,91 bei verlangten 91,83. Rot sind genau zwei Stellen außerhalb des Builder-Territoriums:
  - `tests/acceptance/test-m1b-7-vignette-full-results.R`: vier Blöcke, fünf Erwartungen; der Knit endet mit „Invalid latent study result measure range: …/two_level_results.csv“ (`gate-tests.log` Z. 660–696).
  - `tests/e2e/test-m2-qa-e2e.R`: alle vier Blöcke mit „there is no package called 'llmsa'“ (`gate-tests.log` Z. 933–1084).
- **Fixture.** Die Fixture addierte 0,5 auf jeden Ergebniswert. Beide `derived_share`-Werte des Kurzlaufs `two_level` sind 1, die Fixture schrieb also 1,5. ADR-027 Nr. 5.2 verlangt, dass `latent_read_results()` einen Anteil außerhalb [0, 1] abweist; der Builder hat das umgesetzt (`inst/validation/latent/reference_checks.R:204–207`). Der Widerspruch liegt zwischen meiner Fixture und meinem eigenen ADR, nicht im Produktcode.
- **QA-M1b-004** (`tests/e2e/test-m1b-qa-e2e.R:151–184`) lädt mit `testthat::test_file(load_package = "source")` eine temporäre Paketkopie in den laufenden R-Prozess und löscht sie per `on.exit()` (Z. 160). Den zuvor geladenen Namespace stellt der Test nicht wieder her.
  - Reviewer-Probe (31.10.2026): Vorher zeigt der Namespace auf die Repo-Wurzel, danach auf `/tmp/Rtmp8j5moR/qa-m1b-stage-2a411622c5369a` mit `dir.exists()` FALSE. `llmsa:::acmg_plan()` endet dann mit „there is no package called ‘llmsa’“. Alle vier M1b-QA-Blöcke bestehen dabei.
  - `45-qa` läuft je Meilenstein einmal. Ein weiterer Lauf entsteht nur über `orchestrator/state/<MS>/qa-requested` (`orchestrator/orchestrate.sh:981–986`), also durch den Betreiber.
- **Identifizierbarkeit.** ADR-027 Nr. 3 verlangte für ordinale Fits benannte Fehler bei rangdefizienten festen Zwei-Stufen-Faktoren und bei Zufallstermen mit höchstens zwei beobachteten Stufen. Der Builder hat beides umgesetzt (`R/fit.R:283–298`). Nicht erfasst sind Zufallsterme, die je für sich schätzbar sind, sich aber nicht voneinander trennen lassen. Reviewer-Proben (31.10.2026; R 4.6.1, lme4 2.0.6, ordinal 2026.7.26; synthetische Daten, Seeds 20261101 bis 20261110):
  - Prompt und Modell mit derselben Partition (jeder Prompt nur mit einem Modell, je drei Stufen, 20 Items, zwei Replikate):
    - numerisch: „Numeric variance components are not identifiable.“ (`R/fit.R:558–562`);
    - ordinal: in 10 von 10 Fits `singular` FALSE, `converged` TRUE und keine Warnung; bei Seed 20261101 `model` = `prompt` = 0,356;
    - binär: in 8 von 10 Fits `converged` FALSE mit Konvergenzwarnung, in 2 von 10 `singular` TRUE ohne Warnung; die Aufteilung ist beliebig, etwa prompt 0,301 und model 0,281.
  - Binär mit zwei Modellen und zwei Blöcken derselben Partition; `glmer` schätzt beide als Zufallsterme, das ordinale Gegenstück erfasst ADR-027 Nr. 3.1. Bei fünf Seeds ist die Aufteilung beliebig, viermal mit Konvergenzwarnung. Bei Seed 20261102 gibt es keine Warnung: model 0,0104, block 0,0176, `singular` FALSE, `converged` TRUE.
  - Items in Modellen verschachtelt, `interactions = TRUE`: `item:model` hat dieselbe Partition wie `item`.
    - numerisch: derselbe benannte Fehler;
    - ordinal: `item` = `item:model` = 0,6817, die Item-Varianz ist halbiert, ICC_items und %GRR sind still falsch;
    - binär: `item` 0,353 und `item:model` 0,327.
  - Ein Gram-Kriterium trennt die Fälle. Gemeint ist G[i, j] = ‖Z_iᵀ P Z_j‖²_F der Indikatormatrizen aller Zufallsterme, mit P als Projektion auf das orthogonale Komplement des festen Designs. Ein Fall ist nicht identifizierbar, wenn der kleinste Eigenwert höchstens k · eps · größter Eigenwert ist, nach derselben Regel wie `R/fit.R:558–562`.
    - Identifizierbar: S-ord-1 (auch mit allen Wechselwirkungen), S-ord-4 mit festem Block, S-bin-1, S-two-1 mit festem Modell, ein wine-artiger Plan (9 × 5, ein Replikat) und Items in Modellen ohne Wechselwirkungen. Das Verhältnis der Eigenwerte liegt hier bei 0,0087 oder mehr.
    - Nicht identifizierbar, Verhältnis höchstens 1e-16: die drei Fälle oben und ein dreistufiger Prompt, den die festen Faktoren Modell und Block aufspannen.
- **Gewichtete ordinale Fits.** Mit Häufigkeitsgewichten meldet `stats::nobs()` für `clmm` die Summe der Gewichte, `fit$n` zählt Zeilen (`R/fit.R:114–115`, ADR-028 Nr. 4). Reviewer-Probe: 90 Zeilen, `nobs` 135, Summe der Gewichte 135.

## Entscheidung

1. **(E25) Volllauf-Fixture zu K-M1b-7 (ACC-11).**
   - `acc_m1b_7f_fixture()` verschiebt jeden Wert um 0,5 und jede MCSE um 0,25 wie bisher. Ein `derived_share` wird auf (Wert + 0,5) mod 1 gesetzt.
   - Die Abbildung bleibt in [0, 1] und hat keinen Fixpunkt. Damit unterscheidet sich weiter jeder Fixture-Wert vom Kurzlauf. `n_sim` bleibt die Marke 1234.
   - Geprüft wird unverändert dasselbe: Bias, EmpSE und MCSE jedes Szenarios und Schätzziels der Datei sowie `n_sim` aus der Datei erscheinen im Abschnitt. `derived_share` ist nicht Gegenstand der Anzeigeprüfung (`tests/acceptance/setup-m1b.R:587–603`).
   - Das ist keine Abschwächung: keine Erwartung, keine Toleranz und kein geprüfter Wert entfällt. Die Fixture wird nur fachlich gültig.
   - Beleg: Reviewer-Lauf mit dem Produktstand `5764521`:
     - `m1b-7-vignette-full-results` 204 Erwartungen grün, `m1b-7-vignette` 240;
     - von 180 Fixture-Zellen (Bias und EmpSE mit MCSE) erscheint keine im Abschnitt des Kurzlaufs, die Marke 1234 ebenfalls nicht.
   - Die Fixture bleibt eine gekennzeichnete Testfixture, die nie ins Repository geschrieben wird.
2. **(E24) Identifizierbarkeit latenter Zufallskomponenten; erweitert ADR-027 Nr. 3.**
   1. Für `type = "ordinal"` und `type = "binary"` endet `msa_fit()` vor dem Engine-Aufruf mit einer benannten Fehlermeldung, wenn die Varianzen der Zufallsterme, einschließlich der Wechselwirkungen, nach Abzug des festen Teils nicht getrennt identifizierbar sind. Zum festen Teil gehören Achsenabschnitt und feste Zwei-Stufen-Faktoren. Die Meldung nennt die betroffenen Terme.
   2. Das gilt als Klasse (`orchestrator/LESSONS.md`). Erfasst sind mindestens:
      - Zufallsterme mit derselben Partition, bei `type = "binary"` auch zweistufige;
      - Wechselwirkungen mit der Partition eines Haupteffekts;
      - Zufallsterme, die das feste Design aufspannt.
   3. Empfohlen ist das Gram-Kriterium aus dem Kontext mit der Eigenwertregel von `R/fit.R:558–562`. So entsteht keine neue Konstante. Ein gleichwertiges exaktes Kriterium ist zulässig.
   4. Pläne, die identifizierbar sind, behalten exakt den bisherigen Fit. Das betrifft insbesondere K-M1b-1, K-M1b-5, die Szenarien S-ord, S-bin und S-two und den AP1-Plan. Die Gleichheit mit den Vorgabeaufrufen der Engines bleibt.
   5. Grundlage: docs/01 §2 Nr. 4 („Ergebnis ist eine richtige Zahl oder eine klare Fehlermeldung, nie stillschweigend eine falsche Zahl.“). Der numerische Pfad endet in denselben Plänen schon benannt.
   6. Die Meldung ist ein Fehler, keine Warnung. ADR-023 Nr. 9.5 (Zwei-Stufen-Warnung ohne AP1-Rückfallauslöser) bleibt unberührt.
3. **(E26) QA-M1b-004 ist [QA-PENDING] und für den Builder nonblocking.**
   - Die Ursache liegt im QA-Territorium. Kein Produktcode kann den gelöschten Namespace-Pfad heilen; ein Eingriff dort wäre ein Scheinfix.
   - **Abhilfe (QA):** den verschachtelten Lauf in einem eigenen R-Prozess ausführen, etwa mit `callr::r()`, oder den zuvor geladenen Namespace-Pfad exakt wiederherstellen.
   - Nicht zulässig ist, aus `REPO_ROOT` nachzuladen: Im Mutationslauf ersetzte das den Mutanten durch den Originalcode.
   - Erwartungen und Prüfgegenstand von QA-M1b-004 bleiben.
   - **Betreiber:** Einen QA-Nachlauf fordert `orchestrator/state/M1b/qa-requested` an. Bis dahin bleibt das Gate tests rot, und `PASS` ist nicht möglich.
4. **(ADR-027 Nr. 1.2) Gewichtete ordinale Fits.**
   - Für `clmm` mit Häufigkeitsgewichten ist `nobs(model)` die Summe der Gewichte, `n$observations` die Zahl der Zeilen. Beide beschreiben dieselbe Auswahl; ADR-027 Nr. 1.2 ist erfüllt. Kein Engine-Feld wird umgeschrieben.
   - Die Spalte `data$.msa_offset` bei ordinalen Offsets ist zulässig. Paketcode liest `fit$data` nicht; die Suche nach `$data` unter `R/` findet nichts.
5. **(E15) Testumgebung.** `tests/testthat/helper-validation-vignette.R` setzt ADR-027 Nr. 7 zulässig um.
   - Der Helfer kopiert die Original-Rmd nur in eine Quellpaketkopie, der installierte und lokale Vignette fehlen, und nur bei gesetztem `REPO_ROOT`.
   - Er lädt keinen Produktcode aus `REPO_ROOT` und ändert keine Erwartung. Im Gate ist der unmutierte Vorlauf von mutgate grün: 363 Tests, 0 rot.

## Konsequenzen

- **Builder (REWORK M1b, Runde 3):**
  - setzt Nr. 2 um;
  - belegt das mit Unit-Tests: je ein benannter Fehler für die Pläne aus dem Kontext, ordinal und binär, auch mit `interactions = TRUE`, sowie unveränderte Komponenten identifizierbarer Pläne gegen direkte Engine-Fits;
  - schreibt Tests, die Mutanten des neuen Kriteriums töten. Der Abstand von mutgate zur Schwelle beträgt 0,08 Punkte;
  - erzeugt danach die neun `_check_`-Dateien neu (ADR-023 Nr. 1.5).
- **Reviewer:** bestätigt Nr. 1 im nächsten Gate tests.
- **QA und Betreiber:** Nr. 3.
- **Code-Review:** prüft Nr. 2 als Vertrag. Eine stille Abweichung ist ein blocking-Befund mit `ref` ADR-029.
- **Rücknahme:** nur per Reviewer-ADR.
