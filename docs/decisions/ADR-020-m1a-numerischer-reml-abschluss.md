# ADR-020 — M1a: numerischer REML-Abschluss und konsistentes lme4-Modell

## Status

Builder-Entscheidung zur Umsetzung des freigegebenen PLAN-UPDATE (Runde 2)
und ADR-018/019 in BUILD M1a. Die Messbelege werden in dieser Phase
ergänzt; dieses ADR erteilt keine Abnahme.

## Entscheidung

- Numerische Eingaben bleiben Doubles; ausschließlich Zeichen und Faktoren
  werden über ihre Beschriftungen geparst. Nicht endliche Antworten und
  konstante gültige Antworten enden mit englischer Diagnose.
- Der Vorgabepfad konditioniert Differenzen zu einer beobachteten Antwort
  und skaliert mit der größten absoluten Differenz. Bei drohendem Überlauf
  wird vor der Differenzbildung mit einer Zweierpotenz skaliert. Auch bei
  vielen Gleichständen bleibt der Maßstab positiv, sofern Variation vorliegt.
- Vollständige balancierte Kreuzungen mit nichtnegativen EMS-Schätzern
  erhalten die geschlossene REML-Lösung aus Formelsammlung §2. Mittelquadrate
  entstehen aus orthogonalen Effekten und direkt gebildeten Residuen.
  Negative Momentenschätzer führen zum restringierten Gesamtmodell;
  ausschließlich im Einwegfall ist die restringierte Lösung unmittelbar
  bekannt (Item null, Rest SST/(N−1)).
- Für die übrigen Fälle liefert lme4 auf der konditionierten Antwort den
  Start. Ein analytischer Newton-Abschluss optimiert Varianzverhältnisse
  mit aktiven Nullgrenzen. Score und Krümmung folgen dem profilierten
  REML-Kriterium aus PLAN-UPDATE; Zufallseffektraum und sparse Cholesky
  ersetzen eine dichte Beobachtungs-Kovarianzmatrix. Abschluss verlangt
  kleinen projizierten Score und kleinen Krümmungs-Korrekturschritt,
  dimensionslos mit Ziel `sqrt(.Machine$double.eps)`. Ein gescheiterter
  Abschluss liefert einen Fehler, niemals den Startfit als Ersatz.
- `lFormula`, `mkLmerDevfun` und `mkMerMod` bauen auf den Originaldaten
  das endgültige Modell am endgültigen Theta. `vc` stammt ausschließlich
  aus `VarCorr(model)`; Antwort, Labels und Eingabereihenfolge bleiben.
  `checkConv` erhält analytische Ableitungen auf der Theta-Skala.
- Startwarnungen und Startmeldungen werden mit Herkunft in
  `numerics$start` gespeichert. Scheitert der Abschluss, werden die
  gesammelten Startwarnungen vor dem Fehler weitergegeben. Die finale
  lme4-Konvergenzprüfung bleibt aktiv. `numerics` und `optinfo` nennen das
  tatsächliche Abschlussverfahren zusätzlich zum Refit-Haken.
- Der Refit-Haken lautet `nloptwrap`, mit normalen lme4-Vorgaben und
  leerem `optCtrl`. Der gespeicherte Aufruf enthält den auswertbaren
  Ausdruck `lme4::lmerControl(optimizer = "nloptwrap")`. `refit` und
  `bootMer` bleiben gewöhnliche lme4-REML-Refits.
- Sobald irgendein Argument in `...` steht, läuft direkt
  `lme4::lmer(form, data = dat, REML = TRUE, ...)`, einschließlich der
  originalen Warnungen. Es gibt dort weder Konditionierung noch Abschluss.

## Abhängigkeit

`Matrix (>= 1.6-0)` wird direkter Import. Verwendet werden sparse Matrizen,
`Diagonal`, `forceSymmetric`, `Cholesky`, `solve`,
`crossprod`/`tcrossprod`, `rowSums` und `determinant` (bei CHMfactor mit
explizitem `sqrt = FALSE`). Das optionale `sqrt`-Argument kam laut dem
lokal installierten `Matrix/NEWS.Rd`, Abschnitt 1.6-0, erst in dieser
Version hinzu. Die vorläufige Annahme 1.3-0 wurde deshalb vor dem finalen
Paketcheck berichtigt. Die 1.6-Reihe nennt R >= 3.5 (NEWS 1.6-2,
Compatibility); die Anforderung ist unter R 4.1 erfüllbar. Keine
Schnittstelle von Matrix 1.7 wird vorausgesetzt; R >= 4.1 bleibt
unverändert. Ein Lauf unter R 4.1 wird hier nicht behauptet.
Die vorhandene Umgebung (Matrix 1.7.4, lme4 2.0.6) wird nicht aktualisiert.
Die Freigabe des Imports folgt docs/01 §5 und ADR-018 Nr. 6.

## Belege und Folgen

Der gesicherte Ausgangskern ist durch SHA-256 identifiziert:

```text
R/fit.R 761faa4c4519cea2770f4c746fe002f72b91979bb625cb3a598f2af7655c93e1
R/grr.R 6c0d8b57e54f4a72a5667ad89f3b0119acd9ca020bb669a060e3ec2ed9224fed
M1a baseline: 54 tests; 21 failed blocks; 6 error blocks; 0 skipped; elapsed 22.56 s
```

Der Go/No-Go einschließlich der zusätzlichen Szenarien nach ADR-018 Nr. 5,
Modellkonsistenz, Ableitungsprüfungen und Laufzeitvergleich ist vor der
Ressourcenproduktion erforderlich. Der Befund und die genauen Kommandos
werden in `PROGRESS.md` festgehalten. Fehler in `msa_plan()` beenden die
Planung; der bestehende AP1-Rückfall meldet sie mit seinem Präfix weiter.

## Numerische Umsetzung und Go/No-Go (29.10.2026)

Der Intercept wird vor der sparse Faktorisierung algebraisch eliminiert:
`C = Z'Z - Z'1 1'Z/N`, `B = I + sqrt(D) C sqrt(D)`. Das ist derselbe
REML-Operator wie im PLAN-UPDATE; `log|H| + log|X'H^-1 X|` wird zu
`log|B| + log(N)`. So entfällt die instabile Differenz im Intercept-
Schur-Komplement. `Q` ist die Summe der quadrierten konditionierten
Residuen und penalisierten Zufallseffekte, keine Differenz großer
Quadratsummen. Die größten dichten Zwischenmatrizen haben die Dimension
der Zufallseffekte, nie N × N. Score und Krümmung werden blockweise aus
`Z'PZ` und `Z'Py` gewonnen.

Die Newton-Richtung wird nach `max(1, lambda)` skaliert. Für eine
indefinite Krümmung begrenzt `sqrt(eps) * max(1, max(abs(eigenvalues)))`
die Eigenwerte der Schrittmatrix; das verändert nur die Richtung, nicht
das statistische Modell. Schrittbegrenzung trifft Nullgrenzen exakt,
Halbierung verlangt Abstieg. Innerhalb einer Rundungsreserve
`64 * eps * max(1, abs(F))` darf ein Schritt mit kleinerem projiziertem
Score angenommen werden. Abschluss verlangt weiterhin **beide** Normen
≤ `sqrt(eps)` und positive freie Krümmung. Höchstens 100 Newton-Schritte
und 50 Halbierungen je Schritt, keine aus Ankern gewählten Steuerwerte.

Echte Ausgaben vor der Ressourcenarbeit:

```text
Numeric first: 40 tests; 0 failed blocks; 1 error blocks; 0 skipped
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 465 ]
Invariance: 250 transformed fits; max component/TV 1.91366e-09; max relative metric 2.63966e-09; distant discrete cases 250; failures 0
Methods: analytic_reml 30; closed_form 220
Model consistency: VarCorr, sigma, response, fitted, residuals and predictions passed for all original and transformed fits
Dense reference: criterion error 1.06581e-14; score error 5.32907e-15; Hessian relative error 1.18928e-10
Serialization, refit control and same-seed bootMer: passed
```

Der einzige Fehler des frühen unveränderten Abnahmelaufs ist die noch
fehlende Vignette (`test-m1a-4-nist.R:94`), kein numerischer Fehlschlag.
Die Transformationen umfassen vier Designs × Seeds 1–6 sowie ic50_demo,
je Permutation, Umbenennung, Verschiebung um 100/10000, Skalierung mit
7,5/0,02/0,001/1000/−7,5 und kombinierte Transformation. Alle Fälle halten
die vorgeschriebenen Abstände zu diskreten Grenzen ein. Die bisherigen
Numerikgrenzen wurden unverändert aus ANK-TOL gelesen.

ADR-018 Nr. 5: je Szenario Seeds 1–20, ohne Fehler:

| Szenario | closed_form | analytic_reml | singulär | Median s | Maximum s |
| --- | ---: | ---: | ---: | ---: | ---: |
| S-boot-1 | 18 | 2 | 2 | 0,0470 | 0,154 |
| S-boot-2 | 15 | 5 | 5 | 0,0610 | 0,307 |
| S-boot-3 | 16 | 4 | 4 | 0,1045 | 0,559 |
| S-boot-4 | 20 | 0 | 0 | 0,1740 | 0,281 |
| S-boot-5 | 10 | 10 | 10 | 0,0685 | 0,139 |
| S-boot-6 | 13 | 7 | 7 | 0,0590 | 0,206 |
| msa_plan: 20 Items, 3 Prompts | 1 | 19 | 19 | 0,0775 | 0,197 |
| msa_plan: 40 Items, 3 Prompts | 3 | 17 | 17 | 0,1425 | 0,197 |
| msa_plan: 20 Items, 6 Prompts | 2 | 18 | 18 | 0,1320 | 0,242 |
| msa_plan: 40 Items, 6 Prompts | 5 | 15 | 15 | 0,2915 | 0,594 |

Laufzeitvergleich mit dem gesicherten Kern, ein Aufwärmlauf und drei
Messungen je Fall, dieselben installierten Pakete, Seed 20261029:

```text
ic50_demo: before median 0.389 [0.389, 0.389] s; after median 0.461 [0.460, 0.478] s; ratio 1.185
SmLs03: before median 0.043 [0.043, 0.050] s; after median 0.045 [0.045, 0.045] s; ratio 1.047
msa_plan: before median 0.216 [0.215, 0.230] s; after median 0.544 [0.543, 0.660] s; ratio 2.519
msa_boot: before median 0.103 [0.102, 0.108] s; after median 0.115 [0.113, 0.118] s; ratio 1.117
```

Planung: zwei Szenarien (12/20 Items, 3 Prompts, 2 Modelle, 2 Replikate),
fünf Wiederholungen. Bootstrap: 12 Items, 3 Prompts, 2 Modelle,
3 Replikate, acht Wiederholungen; Refit mit gewöhnlichen Vorgaben.
Die Planung bezahlt den zusätzlichen Erstfit bei jeder Wiederholung;
der Bootstrap behält die gewöhnliche Refit-Steuerung. Die Messung ist
ein endlicher Robustheits-/Laufzeitversuch, keine ADEMP- oder Coverage-
Aussage. Der Vorversuch trägt die Ressourcenarbeit. Gates und
Mutationsabnahme bleiben offen.
