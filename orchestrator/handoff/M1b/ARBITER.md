# ARBITER — M1b, Streitphase plan, Runde 1

Rolle: Arbiter · Phase: `70-arbiter` · Stand: 31.10.2026 · Gegenstand: der einzige blocking-Punkt E1 aus `verdict-plan.json` (Runde 1), entschieden gegen die vom Betreiber berichtigte Spec (ADR-024 Nr. 2: „er entscheidet E1 gegen die berichtigte Spec“). Der Arbiter war an keiner vorigen Phase beteiligt. Er hat nichts neu gerechnet, keine Git-Kommandos ausgeführt und nur diese Datei und `verdict-arbiter.json` geschrieben.

Diese Fassung ersetzt die ARBITER.md vom 31.10.2026, 04:27 (Verdict HUMAN). Deren Direktive ist nach ADR-024 (Folgen) erledigt; ihre Nr. 2 (Logit rechnet mit π²/3) gilt als Teil von Variante A fort.

## Ergebnis

**Verdict RESOLVE.**

- **E1 ist aufgelöst.** Der gemeldete Widerspruch bestand zwischen der alten Fassung von K-M1b-5 und docs/01 §5 sowie Formelsammlung §4.
  - Der Betreiber hat K-M1b-5 neu gefasst (docs/02 Z. 43) und docs/01 §3 Nr. 12 und Formelsammlung §4 Z. 190 im selben Sinn ergänzt (ADR-024 Nr. 1).
  - Alle drei Vergleiche der ICC_items rechnen jetzt mit π²/3. Die Vignettenwerte aus ANK-25 prüfen nur noch die rptR-Installation.
- **Die Builder-Position ist wörtlich gedeckt.** Der Plan empfahl Variante A (PLAN.md Z. 16–25); die neue Fassung von K-M1b-5 ist Variante A. Nach der Regel „Deckt ein wörtliches Spec-Zitat die Builder-Position, fällt der Einwand“ fällt E1 als blocking-Punkt. In der Sache waren Reviewer und Builder ohnehin einig.
- **Kein ADR des Arbiters.** Die Spec schweigt nicht; ADR-024 kodifiziert die Betreiberentscheidung.
- **Runde 2:** PLAN-UPDATE übernimmt die Direktive unten. Zu E1 sind keine neuen Einwände derselben Sache zulässig (SCHEMA.md).

## Gelesen

- **Handoff M1b:**
  - `ARBITER-REQUEST.md`; `verdict-plan.json` (Runde 1) und `PLAN-REVIEW.md` (Runde 1) vollständig;
  - aus `PLAN.md` (Runde 1) Z. 1–80, 86–127, 184–223, 280–414 und 530–660 (Ziel, Dateien, Schnittstellen, Szenarien, Vignette, Reihenfolge, Risiken, Testplan, eigene Gegenrechnung);
  - aus `CRITERIA.json` K-M1b-5, ACC-1, ACC-11 und ACC-18 vollständig, dazu die Statuszeilen aller `open`-Einträge;
  - die ARBITER.md und `verdict-arbiter.json` des ersten Laufs, vor dem Überschreiben.
- **Betreiberentscheidung:** `orchestrator/ESCALATION-M1b.md` und `docs/decisions/ADR-024-betreiberentscheidungen-vor-build-m1b.md`. Beide gehören zum Streit: Sie beantworten die Betreiberfrage des ersten Laufs und ordnen diesen Lauf an.
- **Regeln:** `AGENTS.md` (Pflichtlektüre laut `CLAUDE.md`) und `orchestrator/handoff/SCHEMA.md`.
- **gates.json:** Für M1b gibt es keine. `orchestrator/state/M1b/` enthält nur Phasenmarken (`current-phase`: `70-arbiter-request`); Gates laufen erst nach BUILD.
- **Spec im Original:**
  - `docs/02-statistikkern.md` Z. 1–50, darin M1b vollständig (Szenarien, Schätzziele, K-M1b-1 bis K-M1b-7);
  - `docs/01-fachspezifikation.md` vollständig;
  - Formelsammlung (`reference/privat/07_Formelsammlung_llmsa.md`): Stand-Zeile (Z. 3) und §4 (Z. 148–190);
  - die Anker ANK-25 und ANK-28 vollständig, aus ANK-TOL der Eintrag `rptr` und `tolerance_note`.
- **Abgleich:** Der Wortlaut von K-M1b-5 in `CRITERIA.json` ist zeichengleich mit docs/02 Z. 43 (`identical()` in R: `TRUE`).
- **Zahlen:** nicht neu erhoben. Sie liegen mit echtem Output vor (PLAN.md Z. 638–655; PLAN-REVIEW.md Prüflauf 1 und 2; ANK-25 `verification`; nach der Testanpassung CRITERIA.json ACC-1) und sind zwischen den Rollen unstrittig.
- **Nicht gelesen:** Produktcode, Abnahmetests, ADR-023, `orchestrate.sh` und `config.env`. Wo sie unten vorkommen, stammt die Angabe aus PLAN-REVIEW.md, CRITERIA.json oder ADR-024 und ist so gekennzeichnet.

## E1 — K-M1b-5 gegen docs/01 §5 und Formelsammlung §4

### Direktive (bindend)

1. **K-M1b-5 gilt in der Fassung von docs/02 Z. 43** (Betreiber, 31.10.2026; ADR-024 Nr. 1). Der in E1 gemeldete Widerspruch besteht nicht mehr; E1 trägt kein ESCALATE mehr.
2. **Der Code rechnet ICC_items für `type = "binary"` mit `link = "logit"` weiter mit σ²_ε = π²/3** (docs/01 Z. 58; Formelsammlung §4 Z. 175–181).
   - Keine Umstellung auf 1/(p(1 − p)), kein Sonderfall für BeetlesMale (AGENTS.md, Integrität Nr. 2).
   - Laut CRITERIA.json ACC-1 rechnet der Code schon so (ICC_items 0,223294779042746).
3. **Tests, Anker und Toleranzen bleiben, wie ADR-024 sie festlegt.**
   - Abgenommen wird nach der neuen Fassung mit dem in der wiederholten Abnahmephase angepassten `tests/acceptance/test-m1b-5-binary-rptr.R` (ADR-024 Nr. 2; CRITERIA.json ACC-1). Für die K-M1b-5-Prüfung in `test-m1b-7-vignette.R` gilt CRITERIA.json ACC-18.
   - ANK-25, ANK-28 und ANK-TOL bleiben unverändert (ADR-024 Nr. 1). Keine Toleranz wird aufgeweitet (AGENTS.md, Integrität Nr. 1 und 6).
   - Der Builder ändert keine Abnahmetests (AGENTS.md, Territorien).
4. **PLAN-UPDATE (Runde 2) beantwortet E1 mit `akzeptiert:`.**
   - Es erklärt die Stellen für erledigt, die ACC-1 als offen führen: PLAN.md Z. 16–25, 330–333, 369–392, 398 und 408.
   - Die Testplanzeile K-M1b-5 (Z. 545) nennt statt „unverändert und rot“ beide Teile des Kriteriums:
     - (i) ICC_items gegen `rptR::rptBinary(…, expect = "liability")`, `performance::icc()` und die Nachrechnung σ²_Population/(σ²_Population + π²/3) mit ANK-28, Toleranz ANK-TOL.rptr.live_tol;
     - (ii) die Installationsprüfung: Der Vorgabeaufruf reproduziert die publizierten Punktschätzer aus ANK-25, Toleranz ANK-TOL.rptr.vignette_tol.
   - Die K-M1b-5-Tabelle der Vignette (Z. 296–298) zeigt die Prüfungen aus K-M1b-5 in dieser Fassung. Die Werte aus ANK-25 erscheinen dort nur als Installationsprüfung des rptR-Vorgabeaufrufs, nie als Referenz- oder Vergleichswert für ICC_items.
5. **Reichweite.**
   - K-M1b-1 bis K-M1b-4 und K-M1b-6 berührt E1 nicht.
   - S-bin-1 und S-bin-2 behalten den wahren Rest π²/3 (docs/02 Z. 32–33 und 37; PLAN.md Z. 191 und 199–201).
   - K-M1b-7 bleibt im Wortlaut; seine K-M1b-5-Prüfung folgt der neuen Fassung (Nr. 4).
   - Die Prüfform dieses Teils hat der Reviewer in CRITERIA.json ACC-18 ausgelegt; das ADR dazu folgt laut ACC-18 in `30-plan-review` Runde 2. Sie ist nicht Gegenstand dieses Schiedsspruchs.
6. **Bindung für Runde 2.**
   - Zu Skala und Referenzwerten der binären ICC_items in K-M1b-5 sind keine neuen Einwände zulässig (SCHEMA.md). Zu E1 prüft das Plan-Review nur, ob PLAN-UPDATE diese Direktive übernimmt.
   - Dieser Schiedsspruch stellt keine Erfüllung von K-M1b-5 fest. Die belegt BUILD mit echtem Output (AGENTS.md, Integrität Nr. 4); „nur deterministische Gates entscheiden über grün oder rot“ (AGENTS.md, Einleitung).

### Beleg

**Die Stellen im Wortlaut (berichtigte Fassung)**

1. docs/02 Z. 43 (K-M1b-5): „liefert `msa_fit(type = "binary", link = "logit")` eine ICC_items, die dem Punktschätzer von `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit", expect = "liability")` auf der Link-Skala, `performance::icc()` auf demselben `glmer`-Modell und der Nachrechnung σ²_Population/(σ²_Population + π²/3) (`ankerRef: ANK-28`) gleicht (Toleranz `ankerRef: ANK-TOL.rptr.live_tol`); die installierte `rptR`-Version reproduziert mit dem Vorgabeaufruf `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")` die in der Vignette publizierten Punktschätzer (`ankerRef: ANK-25`, Toleranz `ankerRef: ANK-TOL.rptr.vignette_tol`); diese rechnen mit der Beobachtungsvarianz 1/(p(1 − p)) und sind kein Referenzwert für ICC_items.“
2. docs/01 Z. 58 (§5), unverändert: „Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit) (`ANK-28`)“.
3. Formelsammlung §4, unverändert:
   - Z. 175: σ²_ε = π²/3 für das logistische GLMM;
   - Z. 178: „identisch mit ICC_items aus Abschnitt 3, wenn σ²_ε = π²/3 in GRR eingeht“;
   - Z. 181: R_latent = σ²_α/(σ²_α + σ²_AV + π²/3).
4. Formelsammlung §4 Z. 190 (Nachtrag 31.10.2026; Stand-Zeile Z. 3: „Nachtrag 31.10.2026: §4 Abnahmesatz binär, ADR-024“): „Abnahme: Gegenrechnung von R_latent gegen `rptR::rptBinary(…, expect = "liability")` (Link-Skala mit π²/3) und `performance::icc()` … Die Vignettenwerte … rechnet rptR mit der Beobachtungsvarianz 1/(P(1 − P)) (Vorgabe `expect = "meanobs"`); sie prüfen nur die rptR-Installation und sind kein Referenzwert für R_latent.“
5. docs/01 Z. 41 (§3 Nr. 12): „Binär, Beobachtungsskala | nicht im Scope, Katalog; Abnahme gegen rptR nur auf der Link-Skala (`expect = "liability"`, Restvarianz π²/3 nach `ANK-28`; ADR-024)“.
6. Anker, unverändert:
   - ANK-28 `value.logit` 3.289868133696453 (`expression` „pi^2/3“);
   - ANK-25 `link_scale` 0.188, `original_scale` 0.185, `tolerance` 5e-4; `tolerance_note`: „gleich ANK-TOL.rptr.vignette_tol … Gilt für beide Werte“;
   - ANK-TOL `rptr`: `live_tol` 1e-6, `vignette_tol` 5e-4.
7. Befugnis: docs/01 Z. 8: „Änderungen am Spec-Text nur durch den Betreiber“. ADR-024 Nr. 1 ordnet die Stellen 1, 4 und 5 an. `ESCALATION-M1b.md` Z. 11 hält den Entscheid fest: „Frage 1: Variante A (π²/3 bleibt; K-M1b-5 in docs/02 neu gefasst)“.

**Befund: Die berichtigte Fassung ist widerspruchsfrei und erfüllbar**

1. **Eine Skala für alle Vergleiche der ICC_items.** rptR mit `expect = "liability"`, `performance::icc()` und die Nachrechnung rechnen mit π²/3, wie docs/01 §5 und Formelsammlung §4 es festlegen. BeetlesMale hat einen Prompt und ein Modell, also σ²_AV = 0; die Nachrechnung ist dann R_latent aus Formelsammlung Z. 181.
2. **Der Kern des alten Widerspruchs ist beseitigt.** Die alte Fassung verlangte, dass dieselbe Zahl rund 0,188 und 0,2233 gleicht. Die neue nimmt die Werte aus ANK-25 ausdrücklich aus („sind kein Referenzwert für ICC_items“). Sie prüfen nur noch den rptR-Vorgabeaufruf, nach dem Vorbild von ANK-21 in K-M1b-1 (docs/02 Z. 39).
3. **Prüfstandard und Orakelregel sind erfüllt.** Mit diesen beiden Stellen begründete der erste Lauf, dass kein Spec-Zitat Variante A deckt; die neue Fassung erfüllt beide.
   - docs/01 Z. 16 (§2 Nr. 2): „Welche zwei je Baustein gelten, legen die Kriterien fest.“ K-M1b-5 legt jetzt Gegenrechnung (rptR, performance) und Nachrechnung (ANK-28) fest.
   - docs/01 Z. 71 (§6): „Ein Orakel ersetzt einen Literaturwert nur dort, wo das Kriterium es sagt.“ Das Kriterium sagt es jetzt wörtlich.
4. **Installationsprüfung und docs/01 §3 Nr. 12.** Die Installationsprüfung umfasst auch den Punktschätzer der Beobachtungsskala (0,185); „die … Punktschätzer“ und „diese rechnen“ stehen im Plural.
   - Sie vergleicht rptR mit seiner eigenen Vignette, nicht eine Ausgabe von llmsa mit rptR. Eine Abnahme des Pakets auf der Beobachtungsskala entsteht dadurch nicht; „Abnahme gegen rptR nur auf der Link-Skala“ bleibt gewahrt.
   - Die Toleranz für beide Werte legt ANK-25 fest („Gilt für beide Werte“).
5. **Code und Formelsammlung.** docs/01 Z. 10: „Weicht der Code von einer Soll-Formel ab, gilt die Formelsammlung“. Code mit π²/3 folgt Formelsammlung §4, und das verlangt jetzt auch K-M1b-5.
6. **Erfüllbar.** Werte laut CRITERIA.json ACC-1 (Reviewer, nach der Testanpassung; R 4.6.1, lme4 2.0.6, rptR 0.9.23, performance 0.19.0):
   - ICC_items von `msa_fit` 0,223294779042746; rptR mit `liability` 0,223294850303547; `performance::icc()` 0,223294850303548; Nachrechnung 0,223294850303547. Abstand 7,1e-8, also unter 1e-6.
   - Vorgabeaufruf: R_link 0,187930859738746 gegen 0,188 (Abstand 6,9e-5) und R_org 0,18539884541501 gegen 0,185 (Abstand 4,0e-4), beide unter 5e-4.

   Die Abstände folgen per Subtraktion aus den dokumentierten Werten. Sie zeigen nur, dass das Kriterium erfüllbar ist, und sind kein Abnahmebeleg (Direktive Nr. 6).

**Builder-Position gedeckt**

- PLAN.md Z. 20–22: „Variante A: latente Restvarianz π²/3 beibehalten, gegen `rptBinary(..., expect = "liability")` vergleichen und ANK-25 als separate Installationsprüfung des rptR-Vorgabeaufrufs behandeln.“ Das ist der Inhalt der neuen Fassung (Stelle 1).
- PLAN.md Z. 545: „Danach ausschließlich den durch Betreiber/Reviewer beschlossenen Vertrag prüfen; Live-rptR, performance und Formelrechnung bleiben unabhängige Belege“. Das sind genau die drei Vergleiche der neuen Fassung.
- PLAN.md Z. 297–298: „Skalenunterschiede dürfen nicht als Übereinstimmung erscheinen.“ Das entspricht „sind kein Referenzwert für ICC_items“.
- Der Reviewer empfahl dieselbe Variante (PLAN-REVIEW.md Z. 174–179). Strittig war nie die Sache, nur die fehlende Spec-Deckung.

**Warum RESOLVE und kein ADR**

- HUMAN ist „ausschließlich bei einem echten Widerspruch bindender Spec-Stellen zulässig“ (SCHEMA.md). Nach der Berichtigung besteht keiner mehr (Befund 1 bis 5).
- Die Spec schweigt nicht: K-M1b-5 nennt Aufrufe, Nachrechnung, Anker und Toleranzen. Eine Auslegung des Arbiters, die ein ADR bräuchte, gibt es nicht; ADR-024 kodifiziert die Betreiberentscheidung.
- Der Weg folgt ADR-024 Nr. 2: „Danach führt das liegengebliebene Plan-Verdict (Runde 1, ESCALATE) regulär zum Arbiter; er entscheidet E1 gegen die berichtigte Spec. Plan Runde 2 beantwortet E1 bis E8 in PLAN-UPDATE.md.“

## Nicht Gegenstand

- **E2 bis E8** sind nonblocking (`verdict-plan.json`) und nicht Gegenstand (ARBITER-REQUEST.md: „Entscheide ausschließlich die referenzierten blocking-Punkte“). PLAN-UPDATE beantwortet sie nach PLAN-REVIEW.md, „Hinweise für Runde 2“. E7 und E8 hat der Betreiber laut ADR-024 Nr. 3 und 4 erledigt; der Arbiter hat das nicht geprüft.
- **CRITERIA.json ACC-13 und ACC-18** sind keine blocking-Punkte dieses Verdicts.
- **`orchestrator/ESCALATION-M1b.md`** gehört dem Betreiber; der Arbiter schreibt sie nicht.

## Hinweis zum Ablauf

- Laut ADR-024 (Folgen) ist der Arbiter in M1b mit dieser Auflösung verbraucht.
- Runde 2 ist die letzte Planrunde (`MAX_ROUNDS_PLAN=2`). Endet sie nicht mit PASS, wird M1b geparkt (PLAN-REVIEW.md Z. 13 und 287, dort nach `orchestrate.sh`).
