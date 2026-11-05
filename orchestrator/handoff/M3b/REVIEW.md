# REVIEW — M3b, Runde 1

Rolle: Reviewer · Phase: `50-code-review` · Runde: 1 · Stand: 05.11.2026 · Gegenstand: Diff seit `plan/M3b` (Tag-Objekt `3bb7a93` → Commit `a4709b1`) bis HEAD `6dacb29` (Gate-Commit); die Gates liefen auf `1c912c4` (`gates.json` `env.sha`, Commit von QA r1). Dazwischen liegen BUILD r1 (`fcd29a4`), der erste Gate-Lauf (`192bace`) und QA r1 (`1c912c4`). Es gibt weder `PLAN-UPDATE.md` noch `ARBITER.md` noch `MUT-EQUIV.json` zu M3b. Keine Git-Kommandos; den Diff habe ich aus den Objekten unter `.git/` in R gelesen (Prüflauf 1).

## Ergebnis

**Verdict PASS, `blocking` leer.** `gates.result` ist `pass`; alle acht Gates sind grün, keines meldet `error`.

- **Spec-Treue:** K-M3b-1 bis K-M3b-6 sind erfüllt; die Abnahme prüft sie unverändert (27 Blöcke, 437 Erwartungen, dazu die Klasse-A-Studie). Die Umsetzung folgt ADR-050 und ADR-051 Nr. 9.
  - `transform = "none"` ist das fünfte Argument (`R/robustness.R:142–147`). Nur genau `"none"` und `"logit"` sind zulässig.
  - Der Logit-Pfad prüft vor der Transformation und wendet `stats::qlogis()` genau einmal an (`:155–162`). Eine Randkorrektur gibt es nicht.
  - Die x-Achse heißt „Half-normal quantile (Daniel, 1959)“ (`:210`).
  - Die Hilfeseite nennt ME und SME konservativ und `alpha` nominal. Der 5-%-Satz ist entfernt, die Logit-Skala ist erklärt.
  - `FrF2`, `DoE.base` und `unrepx` stehen in Suggests.
- **Was sich nicht ändert:** PB-Konstruktion, Lenth-Rechnung, Druck- und Plotlogik bis auf den Achsentitel, NAMESPACE, Anker, `inst/` und alle bestehenden Tests.
  - Der Standardpfad bleibt gleich: K-M1d-8 (31 Erwartungen) und `m2-7-robustness-pilot` (375) sind im tests-Gate grün, ebenso der API-Snapshot `m0-api-snapshot` (259).
- **Diff:** neun Builder-Pfade und vier QA-Pfade, dazu Orchestrator-Zustand (Prüflauf 1). Kein Abnahmetest ist geändert, keine Datei entfernt, keine Konfiguration gelockert. Arbeitsbaum und HEAD sind gleich.
- **Mutation:** mutgate besteht mit 96,6 bei verlangten 94,53.
  - 317 Mutanten: 256 entdeckt, 9 überlebt, 52 `RuntimeError`, die aus dem Nenner fallen, und 0 `NoCoverage`.
  - Es gibt keinen Äquivalenzantrag, ich schreibe deshalb keine `MUT-EQUIV-APPROVED.json`. Die Überlebenden sind unten bewertet (E5).
- **QA:** Es gibt keinen roten reproduzierenden Test. QA-M3b-001 (BL-127) bleibt nonblocking; die Begründung steht unter E8.
- **Neue Tests:** Sie belegen überwiegend Verhalten gegen unabhängige Referenzen. Einige Erwartungen frieren die eigene Ausgabe ein und sind nicht als Momentaufnahme gekennzeichnet (E4).
- **Nonblocking**, alle in `BACKLOG.md`:
  - E4: Momentaufnahmen in den neuen Unit-Tests nicht gekennzeichnet;
  - E5: Bewertung der Überlebenden aus dem mutgate;
  - E6: sichtbare Mängel des Half-Normal-Plots, alle seit v0.1.0 vorhanden;
  - E7: Logit-Skala in Druck und Bericht nicht benannt;
  - E8: QA-M3b-001 und BL-127;
  - E9: [QA-PENDING] Testhygiene der QA-Dateien.
- **Was jetzt folgt** (`orchestrate.sh:1059–1099`):
  - Bei PASS und grünen Gates prüft der Orchestrator, ob `PROGRESS.md` seit `plan/M3b` geändert ist. Das ist der Fall (Prüflauf 1).
  - Danach setzt er `8-done`, committet und taggt `done/M3b`. Der Lauf endet mit `MAX_MS_PER_RUN=1`.

### An den Betreiber

1. **Mutations-Baseline vor dem nächsten M3-Meilenstein entfernen (BL-123).**
   - `orchestrator/state/mut-baseline` steht jetzt auf `96.6`.
   - Der zweite Gate-Lauf verlangte schon 94,53, also die 96,53 des ersten Laufs minus 2. Bleibt die Datei, braucht M3a, M3c oder M3d auf ganz anderen Dateien mindestens 94,6 statt 80 (ANK-32).
2. **Nächster Lauf:** M3a steht in `milestones.json` vor M3b und ist offen; ein Lauf ohne Ziel startet M3a, denn die Abhängigkeit M0 ist erfüllt. Die Entscheidung über M3a, M3c und M3d bleibt beim Betreiber (BL-11).
3. **Zur Planung von M3d (E7, BL-130):** Bericht und Druck nennen bei `transform = "logit"` die Skala nicht. Das ist vor K-M3d-4 und K-M3d-6 zu entscheiden.
4. **Geschützte Lenth-Dateien:** `reference/quellen/data/lenth/` ist vollständig (vier Dateien, 04.11. 10:59). Das tests-Gate hat sie mit SHA-256-Prüfung gelesen. Nach einem Rollback vor dem nächsten Lauf prüfen (BL-103).

## Gate-Fakten (`orchestrator/state/M3b/gates.json`, Runde 1)

| Gate | Status | Beleg aus dem Log |
| --- | --- | --- |
| deps | pass | `r-deps: pass — 28 Anforderungen erfüllt (R 4.6.1)`; `DoE.base 1.2.5`, `FrF2 2.3.5`, `unrepx 1.0.2` gefunden (Z. 13, 15, 27, 30) |
| lint | pass | `R CMD check --as-cran --no-manual`, Beginn 23:17:37 UTC, also nach dem QA-Commit um 00:15:36 MEZ (Z. 19). `creating vignettes ... OK`, `code/documentation mismatches ... OK`, Tests OK, `re-building of vignette outputs ... OK`, `Status: OK` (Z. 89); `installed size is 22.3Mb` als INFO (BL-114) |
| tests | pass | testthat `[ FAIL 0 \| WARN 0 \| SKIP 1 \| PASS 6230 ]` (Z. 846; Skip: ellmer-Negativtest `test-backends.R:32`); acceptance `[ FAIL 0 \| WARN 2 \| SKIP 0 \| PASS 16084 ]` (Z. 2343); simulation `[ … PASS 6 ]` (Z. 2353); e2e `[ … PASS 575 ]` (Z. 2429); fuzz `[ … PASS 494 ]` (Z. 2470); Kurzbefund „726 Tests …; 0 fehlgeschlagen, 0 Fehler, 1 übersprungen“ (Z. 2471) |
| trace | pass | `alle Kriterien sind wörtlich und beidseitig verknüpft` |
| territory | pass | `letzter Diff sauber (qa/45-qa, Runde 1, Basis 192bace…)`; der BUILD-Commit ging durch den ersten Gate-Lauf (`192bace`, „gates r1 (rc=0)“) |
| mutgate | pass | `mutgate: pass (score=96.6 required=94.53 baseline=96.6 floor=80)` (Z. 360); 317 Mutanten in `R/robustness.R` (Z. 2), unmutierter Lauf 193,5 s mit 509 Tests (Z. 3), Dauer 8523,77 s (Z. 325) |
| golden-adr | pass | `keine Golden-/Ankeränderung` |
| mutfull | pass | `nicht fällig in M3b` |

M3b-Erwartungen im tests-Gate:

| Testdatei | Erwartungen | Zeile |
| --- | --- | --- |
| `m3b-1-pb-matrices` (K-M3b-1) | 101 | 2302 |
| `m3b-2-frf2` (K-M3b-2) | 11 | 2307 |
| `m3b-3-lenth` (K-M3b-3) | 183 | 2322 |
| `m3b-4-half-normal` (K-M3b-4) | 15; vor M3b 13 grün, 2 rot | 2325 |
| `m3b-5-help-page` (K-M3b-5, Hilfeseite) | 3; vor M3b 3 rot | 2328 |
| `m3b-6-design-transform` (K-M3b-6) | 124; vor M3b 106 grün, 7 rot, 2 Fehlerblöcke | 2338 |
| `tests/simulation/test-lenth-h0` (K-M3b-5, Klasse A) | 6 | 2350 |
| Unit `robustness-properties`, `robustness-transform` (neu), `robustness-plan-spc` | 188, 301, 49 | 669, 682, 657 |
| QA `m3b-qa-e2e`, `m3b-qa-fuzz` (neu) | 256, 400 | 2424, 2465 |

- **Klasse-A-Studie** (stderr, Z. 2556–2558): bei 8 Faktoren je Effekt 0,02325 (MCSE 0,00222; −12,0 MCSE zu α) und je Plan 0,01500 (MCSE 0,00384; −9,1 MCSE). Bei 11 Faktoren 0,02891 (0,00231; −9,1) und 0,02500 (0,00494; −5,1).
  - Seeds 20261112 und 20261115, je 1000 Pläne; alle Entscheidungen gleichen der Mini-Referenz.
  - Die Zahlen gleichen dem Stand vor M3b (ACC-10) und dem Lauf des Builders (PROGRESS). Die Lenth-Rechnung ist unverändert.
- **Regression der Vormeilensteine**, im selben Lauf grün: `m0-api-snapshot` 259 (Z. 864), `m0-layout` 16, `m1a-7-vignette` 148, `m1b-7-vignette` 240, `m1c-5-vignette` 55, `m1d-7-findings` 512, `m1d-8-robustness-wording` 31 (Z. 2159), `m2-7-robustness-pilot` 375 (Z. 2290).
  - Die Vignetten-Literalprüfungen bestehen also mit dem neuen Abschnitt in `validation.Rmd`.
- **Die zwei Warnungen** der Abnahme sind die bekannten aus BL-93 (`test-m1b-4-two-levels.R:41–42`, `lme4::nobars()`/`findbars()`, Z. 1128–1153). Sie liegen im Reviewer-Territorium und haben keinen Produktbezug.
- **Visuelle Artefakte:** `orchestrator/state/M3b/shots/` ist leer. Die Grafik habe ich selbst gerendert (Prüflauf 2, E6).

## Diff seit `plan/M3b` (Prüflauf 1)

| Pfad | Status | Rolle | Inhalt |
| --- | --- | --- | --- |
| `R/robustness.R` | M | Builder | Argument `transform` mit Prüfungen und Logit-Pfad, x-Achsentitel, roxygen für Beschreibung, `alpha`, `transform`, Rückgabe und Daniel (1959) unter `@references` |
| `man/msa_robustness.Rd` | M | Builder | aus roxygen erzeugt, gleich dem roxygen-Text |
| `DESCRIPTION` | M | Builder | Suggests `DoE.base`, `FrF2`, `unrepx`; sonst nichts |
| `NEWS.md` | M | Builder | zwei Punkte zu M3b |
| `vignettes/validation.Rmd` | M | Builder | Abschnitt „Robustness screening: Plackett-Burman and Lenth“, ohne Zahlenliteral und ohne Chunk (E2 umgesetzt) |
| `tests/testthat/test-robustness-transform.R` | A | Builder | 7 Blöcke, 301 Erwartungen |
| `tests/testthat/test-robustness-properties.R` | A | Builder | 12 Blöcke, 188 Erwartungen |
| `PROGRESS.md` | M | Builder | neuer Abschnitt M3b mit Kommandos und Outputs; ältere Einträge bytegleich |
| `orchestrator/handoff/M3b/REVIEW-INPUT.md` | A | Builder | Übergabe |
| `tests/e2e/test-m3b-qa-e2e.R`, `tests/fuzz/test-m3b-qa-fuzz.R` | A | QA | 3 und 2 Blöcke |
| `orchestrator/handoff/M3b/QA.md`, `BACKLOG.md` (BL-127) | A, M | QA | |
| `orchestrator/state/**`, `STATUS.md`, `orchestrator/state/mut-baseline` | M, A | Orchestrator | Gate-Logs, Marker, Baseline `96.6` |

Alle Pfade liegen in der Rolle, die sie geschrieben hat; das gleicht den beiden grünen territory-Läufen. `orchestrator/config.env` ist git-ignoriert und zuletzt am 04.11. um 15:44:21 geändert, fünf Sekunden vor der CONFIG-Zeile dieses Laufs (`orchestrate.log` Z. 234). Am Rundenbudget und an den Gate-Einstellungen hat sich seit dem Start also nichts geändert. MUT-Werte: Schwelle 80, Floor 80, Toleranz 2 (`config.env:229–232`, ANK-32).

## Spec- und Vertragstreue

- **K-M3b-1 und K-M3b-2:** `pb_matrix()` und `pb_design()` sind unverändert. Die Abnahme vergleicht eintragsweise mit ANK-80 und mit `FrF2::pb(boxtyssedal = FALSE)` (ADR-050 Nr. 1, ADR-051 Nr. 1 und 2).
- **K-M3b-3:** Die Lenth-Rechnung ist unverändert (`:163–171`): Konstanten 1,5 und 2,5, strikte Trimmung, d = m/3, Šidák-γ und strikte Entscheidungen. Die Beispiele II und IV, Tab. 1, der Grenzfall, `unrepx::PSE` und `DoE.base::ME.Lenth(simulated = FALSE)` sind in `m3b-3-lenth` grün.
- **K-M3b-4:** Die Positionen sind unverändert (`:209`). Der x-Achsentitel nennt „Daniel“ und „1959“ im selben Text; das verlangt ADR-051 Nr. 4.4 und Nr. 9.6. Die Abnahme ist grün, auch für P′ des 22. von 31 Punkten.
- **K-M3b-5:** Die Klasse-A-Studie ist grün (oben). Gerendert lautet die Hilfeseite (Prüflauf 2):
  - Beschreibung: „Lenth's ME and SME are conservative: with normal noise and all effects zero, actual false alarm rates per effect (ME) and per experiment (SME) are below the nominal ‘alpha’.“;
  - Argument: „alpha: Nominal significance level for ME and SME.“
  - Das gleicht PLAN-REVIEW E3 Nr. 1 und Lenth 1989, S. 472–473 („suggesting that the method is conservative“, ANK-81 `further_quotes`). γ wird nicht erwähnt, damit entfällt E3 Nr. 2. Kein Rest des 5-%-Satzes.
- **K-M3b-6:**
  - `pb_design()` ist unverändert und war schon vor M3b konform (ACC-11 (1) bis (3)).
  - `transform`: Ein Formalargument hinter den vier Argumenten des Snapshots mit dem Literal `"none"` als Vorgabe (ADR-051 Nr. 9.1). Jeder andere Wert ergibt einen benannten Fehler, auch `NA`, `""`, eine andere Länge oder ein Wert, der keine Zeichenkette ist (`:144–147`). Es gibt kein partielles Matching.
  - Logit (`:155–161`): reelle, endliche, nicht dimensionierte numerische Werte mit 0 < p < 1, sonst die Meldung „… strictly between 0 and 1 for transform = 'logit'.“ Auf 0 und 1 folgt dort kein Punkt und keine Ziffer, wie ACC-11 (6) und ADR-051 Nr. 7.6 verlangen. `NA` und `NaN` geben die bestehende NA-Meldung (`:154`, ADR-051 Nr. 9.2).
  - `is.complex(response)` ist neben `!is.numeric(response)` überflüssig, weil `is.numeric()` für komplexe Werte schon `FALSE` liefert. Das ist harmlos, und die Mutanten dieser Bedingung sind entdeckt.
- **Schnittstelle:** Ein neues Argument mit Vorgabe am Ende ist ohne ADR zulässig (docs/01 §4, BL-57). ANK-02 bleibt Obermenge (`m0-api-snapshot` 259). Es gibt kein neues Attribut, keinen neuen Export und keinen neuen Import; die Rückgabe hat dasselbe Schema (ADR-051 Nr. 9.3).
- **AP1:** `acmg_robustness()` ruft `msa_robustness()` weiter ohne `transform` auf, es gibt also keine doppelte Transformation (ADR-051 Nr. 9.4; `m2-7` grün).
- **Rahmen aus ADR-050, Konsequenzen:** `R/robustness.R` ändert nur, was K-M3b-4 und K-M3b-6 verlangen, und den Hilfetext. Daniel (1959) unter `@references` ist nach PLAN-REVIEW E3 Nr. 5 zulässig. Es gibt keinen Umbau für den Score (ADR-051 Nr. 10.4).
- **Vignette:** Der neue Abschnitt nennt die Prüfwege mit Anker-IDs und hat keine Zahl, kein `source()` und keinen Chunk (PLAN-REVIEW E2). Inhaltlich stimmt er mit ADR-050 Nr. 3 und 4 überein. Die Wendung „no factor exceeding ME does not establish pipeline robustness“ ist sprachlich holprig, aber richtig.
- **Integrität:**
  - Kein Test wurde abgeschwächt oder entfernt, keine Regel gelockert.
  - Im Produktcode gibt es keinen harten Erwartungswert und keine erfundenen Daten.
  - Unter `inst/extdata/` und `reference/anchors/` hat sich nichts geändert.
  - Die Belege in `PROGRESS.md` und `REVIEW-INPUT.md` sind echte Outputs. Die lokale Mutationsdiagnose des Builders (299 von 308, 97,08 %) zählt Laufzeitfehler als entdeckt und ist als Diagnose ohne Gate-Verdict gekennzeichnet.

## Neue Tests: Verhalten oder Momentaufnahme

**Builder, `tests/testthat/test-robustness-transform.R`.** Die Tests belegen Verhalten gegen unabhängige Referenzen:

- Effekte gleich `2 · coef(lm(log(p/(1 − p)) ~ X))` und `response_mean`/`response_sd` gleich `mean`/`sd` der Log-Odds, für `pb_design` und einen einfachen data.frame, alle oder einige Faktoren und `alpha = 0.1` (Z. 11–36);
- genau 0, 1, −0,1, 1,1 und ±Inf an drei Positionen sowie neun Typen ergeben Fehler (Z. 70–87);
- keine stille Randkorrektur bei `.Machine$double.xmin` und `1 − .Machine$double.eps` gegen `log(p/(1 − p))` (Z. 109–123);
- ein einzelner Faktor (Z. 125–137).

Die Gleichheit mit `msa_robustness(design, qlogis(p))` ist eine metamorphe Relation zum eigenen Code. Sie steht neben der lm-Gegenrechnung, nicht an ihrer Stelle.

**Builder, `tests/testthat/test-robustness-properties.R`.**

- **Belegen Verhalten:** Effekte aus der Konstruktion `y = 3 + X β/2` (Z. 2–9) und Invarianzen gegen Zeilenfolge, Umbenennen, Spaltenfolge, Vorzeichen, Verschieben, Skalieren, Komplement und Log-Odds-Verschiebung (Z. 114–184).
- **Ebenfalls Verhalten:** RNG-Erhaltung mit und ohne vorherigen Zustand (Z. 79–112), PSE 0 und `t_lenth = effect/PSE` bei 0 < PSE < 1 (Z. 186–207) sowie die Plotpositionen gegen Daniels Formel in anderer algebraischer Form (Z. 286–289).
- **Toleranzen:** durchgehend `ANK-TOL.arithmetic`, enger als `ANK-TOL.invariance`. Das ist keine Lockerung.

**Momentaufnahmen der eigenen Ausgabe ohne Kennzeichnung (E4).** Diese Erwartungen haben keine unabhängige Referenz:

- der genaue Wortlaut der Fehlermeldungen (transform Z. 2–9, 57–107; properties Z. 60–77);
- die Kopfzeile von `print.pb_design()` (Z. 213);
- Kopf, Zahlenformate und Tabelle von `print.msa_robustness()` (Z. 230–236);
- im Plot der Haupttitel, `ylab`, `pch` 19, `lty` 2 und 3, `pos` 2 und `cex` 0,8 (Z. 290–304).

Unabhängige Referenzen gibt es nur für den Schlusssatz (ADR-045, K-M1d-8), den x-Achsentitel (ADR-051 Nr. 9.6), „strictly between 0 and 1“ (ACC-11 (6)) und die Plangrößen (ANK-80). PLAN-REVIEW E1 hat diese Prüfungen für die Mutationsabdeckung verlangt. Sie ersetzen keine Logikprüfung (IMPLEMENTATION-RULES, Tests), sie sind nur nicht als Momentaufnahme gekennzeichnet.

**QA, `tests/e2e/test-m3b-qa-e2e.R` und `tests/fuzz/test-m3b-qa-fuzz.R`.** Die Tests belegen Verhalten:

- Generatorzeilen, zyklische Verschiebung und HᵀH;
- kleinste Plangröße für k = 1 bis 23;
- Gegenrechnung mit lm, `unrepx::PSE` und `DoE.base::ME.Lenth`;
- Plotpositionen;
- Logit-Pfad, Hilfeseitenwörter und Bericht;
- 20 metamorphe Zufallsläufe;
- Randfälle PSE 0 und m = 1.

Die Hygienemängel stehen unter E9.

## Mutation (Bericht `reports/mutation/mutation.json`, Prüflauf 4)

- **Bericht:** Er gehört zu `1c912c4`; die Quelle im Bericht gleicht `R/robustness.R` im Arbeitsbaum.
- **Status:**
  - `Killed` 256, `Survived` 9, `NoCoverage` 0.
  - `RuntimeError` 52: 9 Mutanten lassen sich nicht laden (Parserfehler in `load_all()`, Z. 76–80, 144, 156), 43 brechen im Testlauf ab.
  - Die `RuntimeError` fallen aus Zähler und Nenner. Das ist strenger, als sie als entdeckt zu zählen (299/308).
- **Score:** 256 / 265 = 96,60 ≥ 94,53.

Die Überlebenden, Zeile und `mutatorName` wörtlich aus dem Bericht:

| Zeile | `mutatorName` | Änderung | Bewertung (Prüflauf 3) |
| --- | --- | --- | --- |
| 56 | `TRUE → FALSE` | `on.exit(…, add = TRUE)` → `add = FALSE` | gleichwertig: das einzige `on.exit()` in `pb_design()` |
| 64 | `> → >=` | `X[, nm] > 0` → `>= 0` | gleichwertig: `X` kommt immer aus `pb_matrix()` und ist ±1; `identical()` auf beschrifteten Plänen mit k = 1 bis 23 und den Seeds 1 bis 3 |
| 64 | `<n> - 1 → <n> - 1` (Ersatz `-1`) | `X[, nm] > 0` → `> -1` | gleichwertig, wie oben |
| 84 | `NA_real_ → NA` | `matrix(NA_real_, n, m)` → `matrix(NA, n, m)` | gleichwertig: jeder Eintrag wird überschrieben; `identical()` für N = 8 bis 24 |
| 163 | `< → <=` | `x < 0` → `x <= 0` | nur unter der dokumentierten ±1-Kodierung gleich. Bei 0/1-Kodierung bricht das Original mit „missing value where TRUE/FALSE needed“ ab, der Mutant rechnet Zahlen |
| 163 | `<n> - 1 → <n> - 1` (Ersatz `-1`) | `x > 0` → `x > -1` | nur unter ±1 gleich, siehe BL-127 (2) |
| 163 | `<n> + 1 → <n> + 1` (Ersatz `1`) | `x < 0` → `x < 1` | nur unter ±1 gleich; bei 0/1-Kodierung rechnet der Mutant Zahlen |
| 163 | `> → >=` | `x > 0` → `x >= 0` | nur unter ±1 gleich |
| 197 | `<non-empty string> → ""` | letzter Zeilenumbruch nach den aktiven Faktoren | **nicht gleichwertig**: Eine nachfolgende Ausgabe hängt dann an derselben Zeile (`capture.output({print(x); cat("\|\n")})` unterscheidet beide). Eine Testlücke |

Es gibt keinen Antrag. Die vier gleichwertigen Mutanten (Z. 56, 64 zweimal, 84) dürfte ein späterer Antrag einzeln freigeben. Die vier Mutanten in Z. 163 sind nicht nachweislich verhaltensgleich, weil `msa_robustness()` die Kodierung nicht prüft.

## QA

- Kein QA-Test ist rot. QA.md meldet keinen blockierenden Gegenbeispielfall und schlägt QA-M3b-001 als nonblocking vor.
- Ich folge dem Vorschlag und begründe die Herabstufung unter E8.

## Einwände (Runde 1)

- [E4] (minor) IMPLEMENTATION-RULES.md, Tests („Unit-Tests prüfen Verhalten, Grenzfälle und Fehlerpfade; Snapshots ersetzen keine Logikprüfung“); Prüfauftrag 50-code-review (Momentaufnahme der eigenen Ausgabe nur ohne unabhängige Referenz und gekennzeichnet); PLAN-REVIEW E1 Nr. 1 bis 4 — **Befund:** Die neuen Unit-Tests frieren an den oben genannten Stellen die eigene Ausgabe ein, ohne das zu kennzeichnen: Meldungstexte, Druckformate und Plotgestaltung (`test-robustness-transform.R:2–9`, `:57–107`; `test-robustness-properties.R:60–77`, `:213`, `:230–236`, `:290–304`). Sie ersetzen keine Logikprüfung, die Spec verlangt die Kennzeichnung nicht, deshalb nonblocking. — **Vorschlag:** Beim nächsten Eingriff in diese Dateien an den Stellen kommentieren, etwa „snapshot of the package's own output; no independent reference“. Die Stellen mit Referenz (ADR-045, ADR-051 Nr. 9.6, ACC-11 (6), ANK-80) bleiben unmarkiert (BL-128).
- [E5] (minor) Gate mutgate (pass, `gate-mutgate.log` Z. 327–360); `reports/mutation/mutation.json` — **Befund:**
  - Neun Mutanten überleben (Tabelle oben). Der in Z. 197 ist eine echte Testlücke; REVIEW-INPUT benennt ihn, ohne ihn zu schließen.
  - Vier sind gleichwertig (Z. 56, 64, 64, 84). Vier hängen an der fehlenden ±1-Prüfung (Z. 163, BL-127 (2)).
  - Der Score besteht trotzdem. — **Vorschlag:** einen Test, der nach `print()` weiter ausgibt und die letzte Zeile prüft; Äquivalenzanträge nur einzeln und nur, wenn ein späterer Meilenstein `R/robustness.R` wieder mutiert und der Score sie braucht (BL-128).
- [E6] (minor) K-M3b-4 (erfüllt); ADR-050, Konsequenzen (Änderungsrahmen von `R/robustness.R` in M3b) — **Befund:** Der Half-Normal-Plot hat sichtbare Mängel aus v0.1.0, die M3b nicht berührt (Prüflauf 2):
  1. Die Beschriftung des kleinsten |Ê| steht links vom Punkt (`pos = 2`) und wird am Rand abgeschnitten; bei m = 11 erscheint „F11“ als „11“.
  2. `ylim` folgt nur den Daten. Erreicht kein Effekt SME, liegt die SME-Linie außerhalb der Grafik; bei m = 31 ist sie nicht zu sehen.
  3. Eine Legende für ME (gestrichelt) und SME (gepunktet) fehlt.
  4. Bei m = 31 überlagern sich die Beschriftungen.

  — **Vorschlag:** nach dem 26.11.2026 oder beim nächsten Eingriff in `plot.msa_robustness()`: `ylim` über max(|Ê|, ME, SME), Rand oder `xpd` für die Beschriftung, Legende der Linien. Der Achsentitel aus K-M3b-4 bleibt (BL-129).
- [E7] (minor) K-M3b-6; ADR-051 Nr. 9.3 („Der Logit-Pfad hat dasselbe Schema … die Hilfeseite sagt das“); PLAN-REVIEW, Architektur und Verträge — **Befund:** Bei `transform = "logit"` drucken `print.msa_robustness()` und `msa_report()` die Werte auf der Logit-Skala ohne Skalenangabe, etwa „response mean -0.2747 (sd 1.1852)“ (Prüflauf 3; QA-M3b-E2E-3 bettet ein solches Objekt in den Bericht ein). Nur die Hilfeseite nennt die Skala. Das ist so festgelegt und kein M3b-Kriterium. — **Vorschlag:** in M3d (K-M3d-4, K-M3d-6) entscheiden, ob ein Attribut nur im Logit-Pfad und eine Skalenangabe in Druck und Bericht kommen. Ein Attribut nur im Logit-Pfad ließe den Standardpfad für K-M1d-8 gleich (BL-130).
- [E8] (minor) QA.md QA-M3b-001; BL-127; ADR-050, Konsequenzen; ADR-051 Nr. 10.4; docs/01 §2 Nr. 4 — **Befund:** Die Herabstufung ist begründet:
  1. Kein ausführbarer roter Test belegt den Befund; die QA-Tests prüfen die aktiven Regeln und sind grün.
  2. Alle genannten Verhalten bestehen seit v0.1.0, liegen außerhalb des M3b-Rahmens aus ADR-050, Konsequenzen, und berühren kein K-M3b-Kriterium.
  3. Die Randfälle aus docs/01 §2 Nr. 4 behandelt der Code richtig: fehlende Werte ergeben einen benannten Fehler, identische Antworten PSE 0 ohne Flag, Faktoren haben genau zwei Stufen.

  Ergänzt (Prüflauf 3):
  - `pb_design(24)` ohne `n_runs` meldet „`n_runs` must be one of 8, 12, 16, 20, 24.“, obwohl kein `n_runs` übergeben ist. ACC-11 (1) verlangt nur einen Fehler.
  - Ein 0/1-kodierter data.frame endet in der rohen Meldung „missing value where TRUE/FALSE needed“.

  — **Vorschlag:** bei BL-127 nach dem 26.11.2026; beide Ergänzungen dort vermerkt.
- [E9] (minor) [QA-PENDING] AGENTS.md, Integrität Nr. 7 („nie aus Modellgedächtnis als nacktes Literal“); AGENTS.md, Projektblock, Orakel- und Ankerstrategie („Alle Toleranzen stehen in einer Datei `reference/anchors/ANK-TOL.json`“) — **Befund:** In den QA-Dateien:
  1. Die Toleranzen sind Literale (`1e-8`, `1e-11`, `1e-12`; e2e Z. 133, 137, 141–143, 151–154, 198–211; fuzz Z. 97–105, 139–152, 172–174).
  2. Die Generatorzeilen stehen als Literale in e2e Z. 44–50 statt aus ANK-80; die Werte gleichen ANK-80.
  3. `testthat::set_max_fails(Inf)` setzt auf Dateiebene (je Z. 2) eine globale Option für alle folgenden Dateien.
  4. Die Orakelvergleiche hinter `if (requireNamespace(…))` bestehen ohne das Paket stillschweigend (e2e Z. 69, 135, 139).
  5. Fuzz Z. 185 schreibt die irreführende Meldung von `pb_design(24)` fest (E8).

  Das ist für den Builder nonblocking. — **Vorschlag:** QA liest Toleranzen und Generatorzeilen aus den Ankern, setzt die Option lokal, überspringt mit Grund (oder schlägt fehl) und prüft für 24 Faktoren nur, dass ein Fehler kommt (BL-131).

## Eigene Prüfläufe

Alle Skripte lagen unter `orchestrator/handoff/M3b/.probe-r1/` und sind nach dem Lauf gelöscht. Werkzeuge: `Rscript --vanilla`, R 4.6.1, `pkgload::load_all()` aus dem Arbeitsbaum, `digest`, `jsonlite`. Außer diesem Ordner habe ich im Arbeitsbaum nichts geschrieben; es gab keinen Test- und keinen Git-Aufruf.

### Prüflauf 1 — Diff ohne Git

- **Einlesen:** R liest `.git/refs/tags/plan/M3b` (Tag-Objekt `3bb7a93` → Commit `a4709b1`) und `refs/heads/main` (`6dacb29`).
  - Es durchläuft beide Bäume aus losen und gepackten Objekten (`pack-41a109f4…`, idx v2, Deltas) und prüft die SHA-1 jedes Objekts.
  - Ergebnis: 763 Dateien unter `plan/M3b`, 784 unter HEAD, 32 geänderte Pfade (Tabelle oben), keiner gelöscht.
- **Arbeitsbaum gegen HEAD:** alle 784 Blob-IDs gleich.
- **Erste-Eltern-Kette:** `6dacb29` gates r1 ← `1c912c4` qa 45-qa r1 ← `192bace` gates r1 ← `fcd29a4` builder 40-build r1 ← `a4709b1` approve plan.
- **Inhalt:** die alten Blobs in den Probenordner geschrieben, dann `diff -u` gegen den Arbeitsbaum für `R/robustness.R`, `DESCRIPTION`, `NEWS.md`, `man/msa_robustness.Rd`, `vignettes/validation.Rmd`, `PROGRESS.md` und `BACKLOG.md`. Der Inhalt gleicht der Beschreibung in REVIEW-INPUT und PROGRESS.

### Prüflauf 2 — Hilfeseite und Grafik

- **Hilfeseite:** `tools::Rd2txt()` auf `man/msa_robustness.Rd`; die zitierten Sätze stehen oben unter K-M3b-5.
- **Grafik:** `plot()` auf ein PNG mit 700 × 700 Pixeln für zwei Fälle:
  - m = 11: `pb_design(11)`, Effekte aus der Konstruktion von `robust_property_case()`. Achsentitel, beide Linien und die Beschriftungen stimmen; „F11“ ist links abgeschnitten.
  - m = 31: volle 2⁵-Kontrastmatrix, `rnorm(32)` mit Seed 31. Die ME-Linie bei 0,68 ist sichtbar; die SME-Linie liegt über dem größten |Ê| von 0,82 und fehlt, die Beschriftungen überlagern sich (E6).
- Die Bilder sind gelöscht.

### Prüflauf 3 — Überlebende und Randfälle

- **Verfahren:** Jeder Mutant ist aus `R/robustness.R` mit genau der geänderten Zeile gebaut und in einer Umgebung über dem Namensraum geladen.
- **Ergebnisse der Überlebenden:**
  - Z. 84: `identical()` für N = 8, 12, 16, 20, 24.
  - Z. 56: `pb_design()` enthält genau ein `on.exit()`.
  - Z. 64, beide Mutanten: `identical()` auf beschrifteten Plänen mit k ∈ {1, 7, 8, 11, 12, 15, 19, 23} und den Seeds 1 bis 3.
  - Z. 163, alle vier: `identical()` auf `pb_design(11)` mit ±1-Kodierung. Bei 0/1-Kodierung bricht das Original mit „missing value where TRUE/FALSE needed“ ab; die Mutanten `<=` und `< 1` rechnen Zahlen, die beiden anderen brechen gleich ab.
  - Z. 197: `capture.output(print(x))` ist gleich. Mit einer nachfolgenden Ausgabe endet die letzte Zeile beim Mutanten auf „F2 (above ME only)|“.
- **Randfälle des neuen Arguments:**
  - Ein benanntes `p` ergibt dieselben Effekte.
  - Ganzzahlig `0:1`, `difftime` und `1 − 1e−17` (in double gleich 1) ergeben die Logit-Meldung.
  - `factors = character(0)` ergibt die Warnung „NaNs produced“ und dann einen Fehler; das bestand schon vorher (BL-127 (2)).
  - `pb_design(24)` meldet wie unter E8.
  - Der Druck eines Logit-Ergebnisses beginnt mit „Robustness screening: 8 runs, 7 factors; response mean -0.2747 (sd 1.1852)“.

### Prüflauf 4 — Mutationsbericht

- **Bericht:** `jsonlite` auf `reports/mutation/mutation.json`. `report.key` nennt `1c912c4`; die Quelle im Bericht gleicht der Datei im Arbeitsbaum.
- **Status:**
  - Zahlen: 256 `Killed`, 52 `RuntimeError`, 9 `Survived`, 0 `NoCoverage`.
  - Die 52 `RuntimeError`: 9 mit Parserfehler beim Laden, 43 mit Abbruch im Testlauf.
  - Für jeden nicht entdeckten Mutanten sind Zeile, Spalte, `mutatorName` und Ersatz ausgegeben, gleich `gate-mutgate.log` Z. 327–354.

## Gelesen

- **Rollen und Protokoll:** `AGENTS.md`, `CLAUDE.md`, `IMPLEMENTATION-RULES.md`, `contracts/PROTOCOLS.md`, `orchestrator/handoff/SCHEMA.md`, `orchestrator/LESSONS.md`. Dazu `orchestrate.sh` mit `path_allowed` (Z. 515–544), `verdict()` (Z. 734–756) und dem Abschluss (Z. 1059–1099).
- **Spezifikation:** docs/04 M3b (K-M3b-1 bis K-M3b-6), docs/01 §2 und §4; ADR-050, ADR-051; ANK-80, ANK-81 (`further_quotes`), ANK-TOL (`arithmetic`, `invariance`, `frf2_unrepx`, `mc_factor`).
- **Handoff M3b:** `CRITERIA.json` mit ACC-1 bis ACC-15, `PLAN.md`, `PLAN-REVIEW.md`, `verdict-plan.json`, `REVIEW-INPUT.md`, `QA.md`.
- **Gate-Fakten:** `gates.json`; alle acht `gate-*.log`, `gate-tests.log` gezielt (Ergebniszeilen, Warnungen, stderr); `orchestrate.log` (Ende); `config.env` (Mutation); `milestones.json`; `STATUS.md`.
- **Code und Tests:**
  - `R/robustness.R` vollständig, alter Stand aus `plan/M3b` im Diff;
  - `man/msa_robustness.Rd`, `DESCRIPTION`, `NEWS.md` und `vignettes/validation.Rmd` im Diff;
  - `PROGRESS.md`, neuer Abschnitt;
  - beide neuen Unit-Dateien und beide QA-Dateien vollständig;
  - `tests/simulation/test-lenth-h0.R` (Ausgabe), `helper-validation-numeric.R` Z. 11–17;
  - `BACKLOG.md`: Kopf, BL-86, BL-93, BL-107, BL-121 bis BL-127.
