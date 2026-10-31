# ARBITER — M1b, Streitphase plan, Runde 1

Rolle: Arbiter · Phase: `70-arbiter` · Stand: 31.10.2026 · Gegenstand: der einzige blocking-Punkt E1 aus `verdict-plan.json` (Runde 1). Der Arbiter war an keiner vorigen Phase beteiligt. Er hat nichts neu gerechnet, keine Git-Kommandos ausgeführt und nur diese Datei und `verdict-arbiter.json` geschrieben.

## Ergebnis

**Verdict HUMAN.**

- **E1 ist ein echter, wörtlicher Widerspruch bindender Spec-Stellen.** K-M1b-5 verlangt, dass dieselbe Zahl zugleich rund 0,188 und 0,2233 gleicht; keine Implementierung erfüllt das Kriterium. Zwei seiner drei Vergleiche widersprechen außerdem der latenten Restvarianz π²/3 aus docs/01 §5 und Formelsammlung §4.
- **Ohne neue Spec gibt es keine Auflösung.** Jede erfüllbare Fassung ändert den Text von K-M1b-5, dazu Formelsammlung §4 Z. 190 (Variante A) oder docs/01 §5 und Formelsammlung §4 Z. 175–181 (Variante B). Den Spec-Text ändert nur der Betreiber (docs/01 Z. 8).
- **Die Betreiberfrage** steht unten. Bis zur Entscheidung gilt die Direktive zu E1.
- **Kein ADR des Arbiters.** Die Spec schweigt nicht, sie widerspricht sich. Ein ADR kodifiziert später die Betreiberentscheidung, keine Auslegung des Arbiters.

## Gelesen

- **Handoff:**
  - `ARBITER-REQUEST.md`, `verdict-plan.json` (Runde 1) und `PLAN-REVIEW.md` (Runde 1) vollständig;
  - aus `PLAN.md` (Runde 1) die Stellen zu ACC-1 und K-M1b-5 (Z. 1–40, 285–409, 535–660);
  - aus `CRITERIA.json` K-M1b-5, K-M1b-7 und ACC-1;
  - `orchestrator/handoff/SCHEMA.md`.
- **Regeln:** `AGENTS.md` (Pflichtlektüre laut `CLAUDE.md`) und `orchestrator/prompts/70-arbiter.md` (gleich dem Auftrag).
- **gates.json:** Für M1b gibt es keine. `orchestrator/state/M1b/` enthält nur Phasenmarken; Gates laufen erst nach BUILD.
- **Spec im Original:**
  - `docs/02-statistikkern.md` Z. 1–50, darin M1b vollständig (Szenarien, Schätzziele, K-M1b-1 bis K-M1b-7);
  - `docs/01-fachspezifikation.md` vollständig;
  - Formelsammlung (`reference/privat/07_Formelsammlung_llmsa.md`): Kopf, §4 (Z. 148–190), §12 und §13;
  - die Anker ANK-25 und ANK-28 sowie aus ANK-TOL der Eintrag `rptr` und `tolerance_note`.
- **Zahlen:** nicht neu gerechnet.
  - Sie liegen zweimal unabhängig mit echtem Output vor: Builder in PLAN.md Z. 605–655, Reviewer in PLAN-REVIEW.md Prüflauf 1 und 2. Dazu kommt ANK-25 `verification`.
  - Beide Läufe stimmen auf 15 Stellen überein; zwischen den Rollen sind die Zahlen unstrittig.
- **Nicht gelesen:** Produktcode, Abnahmetests, ADR-023 und `orchestrate.sh`. Wo sie unten vorkommen, stammt die Angabe aus PLAN-REVIEW.md oder CRITERIA.json und ist so gekennzeichnet.

## E1 — K-M1b-5 gegen docs/01 §5 und Formelsammlung §4

### Direktive (bindend bis zur Betreiberentscheidung)

1. **Den Abnahmevertrag von K-M1b-5 entscheidet der Betreiber** nach der Frage unten. Arbiter, Reviewer und Builder lösen ihn nicht auf.
2. **Der Code rechnet für `type = "binary"` mit Logit weiter mit σ²_ε = π²/3.**
   - Belege: docs/01 Z. 58; Formelsammlung §4 Z. 175–181; docs/01 Z. 10: „Weicht der Code von einer Soll-Formel ab, gilt die Formelsammlung“.
   - Keine vorgreifende Umstellung auf 1/(p(1 − p)), kein Sonderfall für BeetlesMale (AGENTS.md, Integrität Nr. 2).
3. **Abnahmetests, Anker und Toleranzen bleiben bis zur Entscheidung unverändert.**
   - Das betrifft `tests/acceptance/test-m1b-5-binary-rptr.R`, die K-M1b-5-Prüfung in `tests/acceptance/test-m1b-7-vignette.R`, ANK-25 und ANK-TOL.
   - Keine Toleranz wird aufgeweitet und keine Teilprüfung gestrichen (AGENTS.md, Integrität Nr. 1 und 6).
   - Nach der Entscheidung passt der Reviewer sie mit ADR an (AGENTS.md, Territorien; für Anker docs/01 Z. 69), auf dem Weg, den der Betreiber zu Frage 2 bestimmt.
4. **Der Plan bleibt zu E1, wie er ist.**
   - Er behandelt den Punkt richtig (PLAN.md Z. 16–25, 369–392 und 545).
   - Nach der Entscheidung übernimmt PLAN-UPDATE sie in die K-M1b-5-Zeile des Testplans und in die K-M1b-5-Tabelle der Vignette.
5. **Reichweite:**
   - K-M1b-1 bis K-M1b-4 und K-M1b-6 berührt E1 nicht. Unter Variante B wären die Schätzziele der S-bin-Szenarien zu prüfen (Frage 1).
   - K-M1b-7 braucht keine Textänderung; seine K-M1b-5-Prüfung folgt der gewählten Fassung von K-M1b-5.

### Beleg

**Die Stellen im Wortlaut**

1. docs/02 Z. 43 (K-M1b-5): „liefert `msa_fit(type = "binary", link = "logit")` eine ICC_items, die dem Punktschätzer von `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")` auf der Link-Skala und dem publizierten Vignettenwert gleicht (`ankerRef: ANK-25`, Toleranz `ankerRef: ANK-TOL.rptr`) und mit `performance::icc()` auf demselben `glmer`-Modell übereinstimmt“. Das sind drei Forderungen an dieselbe Zahl:
   - (a) gleich dem Vorgabeaufruf von `rptBinary`;
   - (b) gleich dem Vignettenwert ANK-25;
   - (c) gleich `performance::icc()`.
2. docs/01 Z. 58 (§5): „Latente Skala: Restvarianz 1 (Probit), π²/3 (Logit) (`ANK-28`)“.
3. Formelsammlung §4:
   - Z. 175: σ²_ε = π²/3 für das logistische GLMM;
   - Z. 178: „identisch mit ICC_items aus Abschnitt 3, wenn σ²_ε = π²/3 in GRR eingeht“;
   - Z. 181: R_latent = σ²_α/(σ²_α + σ²_AV + π²/3).
4. Formelsammlung §4 Z. 190: „Abnahme: Gegenrechnung gegen `rptR::rptBinary` (Vignette, Datensatz `BeetlesMale`, Gruppe Population: R = 0,188 auf der Link-Skala, 0,185 auf der Beobachtungsskala; Punktschätzer).“
5. ANK-25:
   - `link_scale` 0.188;
   - `link_scale_variance_in_source`: „1 / (p(1 - p)) … (Vorgabe expect = "meanobs"), nicht π²/3“;
   - Quelle: „The current version of rptR implements the more accurate approximation \(1 / (p(1-p))\).“
6. ANK-TOL `rptr`: „1e-6 gegen den Live-Aufruf, 5e-4 gegen den gerundeten Vignettenwert 0,188 (ANK-25)“. `tolerance_note`: „Betreiberfestlegungen, exakt“.
7. Bindung:
   - docs/02 Z. 4: „Gilt zusammen mit `01-fachspezifikation.md` … und der Formelsammlung“;
   - docs/01 Z. 4: „Bindender Inhalt für alle Meilensteine“;
   - docs/01 Z. 26: „Die Formelsammlung ist bindend“.

**Befund**

1. **K-M1b-5 ist in sich unerfüllbar.** Auf BeetlesMale (σ²_Population = 0,945803710351675) gilt:
   - (a) `rptBinary` mit der Vorgabe `expect = "meanobs"`, also 1/(Ep(1 − Ep)): 0,187930859738746;
   - (b) ANK-25: 0,188;
   - (c) `performance::icc()`: 0,223294850303548.

   (c) liegt 0,0354 neben (a) und 0,0353 neben (b). Das ist rund das 35 000-Fache von `live_tol` und das 70-Fache von `vignette_tol`. Keine Zahl erfüllt (b) und (c) zugleich, wie immer der Code rechnet.
2. **(a) und (b) widersprechen der Formel der Spec.** Mit σ²_ε = π²/3 (Stellen 2 und 3) ist ICC_items = σ²/(σ² + π²/3) = 0,223294850303547. Laut CRITERIA.json ACC-1 rechnet der Code schon so (0,223294779042746). Das erfüllt (c) und verfehlt (a) und (b).
   - Mit 1/(p(1 − p)) wären (a) und (b) erreichbar, aber docs/01 §5 und Formelsammlung §4 verletzt.
   - (c) bliebe dann trotzdem rot: `performance::icc(approximation = "observation_level")` ergibt 0,187526014414148, also 4,0e-4 neben (a) (PLAN-REVIEW.md Prüflauf 2).

**Warum keine Auflösung ohne neue Spec**

- **Die Spec schweigt nicht.** K-M1b-5 nennt Aufruf, Literaturwert und Toleranz. Der Auslegungsweg „Schweigt die Spec, hält der Reviewer die Auslegung in einem ADR … fest“ (docs/01 Z. 8) steht deshalb nicht offen.
- **Kein Spec-Zitat deckt Variante A**, die Builder (PLAN.md Z. 16–25) und Reviewer empfehlen. A vergleicht ICC_items nicht mehr mit dem Literaturwert, sondern mit Orakeln und einer Nachrechnung.
  - docs/01 Z. 71 (§6): „Ein Orakel ersetzt einen Literaturwert nur dort, wo das Kriterium es sagt.“ K-M1b-5 sagt das nicht; es verlangt beides.
  - docs/01 Z. 16 (§2 Nr. 2): „Welche zwei je Baustein gelten, legen die Kriterien fest.“ K-M1b-5 legt Literaturwert und Gegenrechnung fest; A tauscht den Literaturwert gegen die Nachrechnung.
  - Der Aufruf mit `expect = "liability"` steht nicht im Kriterium. Der Reviewer stellt zutreffend fest: „ein anderer Aufruf ändert den Kriteriumstext“ (verdict-plan.json E1).
  - docs/01 Z. 41 (§3 Nr. 12: „Abnahme gegen rptR nur auf der Link-Skala“) ist mit A vereinbar, trägt aber den Wegfall von (b) nicht.
- **Die Vorrangregeln aus docs/01 Z. 10 tragen nicht.**
  - „Weicht der Code von einer Soll-Formel ab, gilt die Formelsammlung“ bestimmt den Code (Direktive Nr. 2), nicht den Abnahmevertrag.
  - „weicht die Formelsammlung von ihrer Quelle ab, gilt die Quelle“ greift nicht. R_latent folgt seinen Quellen (ANK-28: Nakagawa & Schielzeth 2010, Tab. 1; Nakagawa, Johnson & Schielzeth 2017, Druckseite 7). Der Wert 0,188 folgt seiner Quelle (ANK-25: rptR-Vignette mit 1/(p(1 − p))). Den falschen Brückenschluss, 0,188 sei ein π²/3-Wert, ziehen erst K-M1b-5 und Formelsammlung Z. 190.
- **Eine Rangregel zwischen docs/01 und docs/02** (allgemein vor speziell oder umgekehrt) enthält die Spec nicht. Sie hier einzuführen hieße, eine Anforderung zu erfinden. Sie hülfe auch nicht, weil K-M1b-5 schon in sich widersprüchlich ist (Befund 1).
- **Toleranzen aufweiten, Teilprüfungen streichen oder Daten-Sonderfälle bilden** ist verboten (AGENTS.md, Integrität Nr. 1, 2 und 6).

Damit trifft die Regel des Arbiter-Auftrags zu: „Nur wenn bindende Spec-Stellen einander wörtlich widersprechen und keine Auflösung ohne neue Spec möglich ist, lautet das Verdict HUMAN.“ Ebenso gilt AGENTS.md, Handoff-Disziplin: „Widersprüchliche Specs führen zu `ESCALATE`.“ SCHEMA.md verlangt für HUMAN die konkrete Betreiberfrage; sie folgt.

## Betreiberfrage

### Frage 1 — Welche Fassung von K-M1b-5 gilt?

K-M1b-5 verlangt für ICC_items auf BeetlesMale zugleich 0,187930859738746 (rptR-Vorgabe), 0,188 (ANK-25) und 0,223294850303548 (`performance::icc()`). Nach docs/01 §5 und Formelsammlung §4 ist ICC_items 0,223294850303547.

**Variante A: π²/3 bleibt; neu gefasst werden nur die Stellen, die 0,188 als π²/3-Wert behandeln.**

- Wortlaut für docs/02 Z. 43, Vorschlag. Die Installationsprüfung ist gebaut wie die zu ANK-21 in K-M1b-1 (docs/02 Z. 39).

  > **K-M1b-5:** Engine-Gleichheit und Literaturwert binär: Auf `rptR::BeetlesMale` (Item = `Population`, ein Prompt, ein Modell) liefert `msa_fit(type = "binary", link = "logit")` eine ICC_items, die dem Punktschätzer von `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit", expect = "liability")` auf der Link-Skala und der Nachrechnung σ²_Population/(σ²_Population + π²/3) (`ankerRef: ANK-28`) gleicht (Toleranz `ankerRef: ANK-TOL.rptr`) und mit `performance::icc()` auf demselben `glmer`-Modell übereinstimmt; die installierte `rptR`-Version reproduziert mit dem Vorgabeaufruf `rptR::rptBinary(Colour ~ (1 | Population), grname = "Population", link = "logit")` den in der Vignette publizierten Punktschätzer auf der Link-Skala (`ankerRef: ANK-25`, Toleranz `ankerRef: ANK-TOL.rptr`), der mit der Beobachtungsvarianz 1/(p(1 − p)) rechnet und kein Referenzwert für ICC_items ist. (Prüfweg: Test)

- **Belege für ICC_items** nach docs/01 §2 Nr. 2: Gegenrechnung (rptR mit `expect = "liability"`, `performance::icc()`) und Nachrechnung. Der Wortlaut nennt beides ausdrücklich, weil ein Orakel einen Literaturwert nur ersetzt, „wo das Kriterium es sagt“ (docs/01 Z. 71).
- **Formelsammlung §4 Z. 190**, Vorschlag: „Abnahme: Gegenrechnung von R_latent gegen `rptR::rptBinary(…, expect = "liability")` (Link-Skala mit π²/3) und `performance::icc()`. Die Vignettenwerte (Datensatz `BeetlesMale`, Gruppe Population: R = 0,188 auf der Link-Skala, 0,185 auf der Beobachtungsskala; Punktschätzer) rechnet rptR mit der Beobachtungsvarianz 1/(p(1 − p)) (Vorgabe `expect = "meanobs"`); sie prüfen nur die rptR-Installation und sind kein Referenzwert für R_latent.“
- **docs/01 §3 Nr. 12** kann bleiben. Eindeutiger wäre „Abnahme gegen rptR nur auf der Link-Skala (`expect = "liability"`)“.
- **Unverändert** bleiben docs/01 §5, Formelsammlung §4 Z. 175–181, ANK-25, ANK-28, ANK-TOL und der Code.
- **Messwerte unter A:**
  - 0,223294850303547 (rptR mit `liability`), 0,223294850303548 (`performance::icc()`) und 0,223294850303547 (Nachrechnung);
  - Installationsprüfung: rptR-Vorgabe 0,187930859738746 gegen 0,188, Abstand 6,9e-5, also innerhalb 5e-4 (ANK-25 `verification`).

**Variante B: Die binäre ICC rechnet mit der Beobachtungsvarianz 1/(p(1 − p)).**

- Neu zu fassen wären:
  - docs/01 Z. 58 und Formelsammlung §4 Z. 175–181 einschließlich Z. 178, als Ausnahme für die binäre ICC;
  - die gleichlautende Konvention im Projektblock von AGENTS.md;
  - K-M1b-5 (c);
  - der Code.
- Zu prüfen wären die Schätzziele „ICC_items auf der latenten Skala“ für S-bin-1 und S-bin-2, deren wahrer Rest π²/3 ist (docs/02 Z. 32–33 und 37).
- Auch dann bliebe K-M1b-5 in der heutigen Form rot: `performance::icc(approximation = "observation_level")` liegt 4,0e-4 neben der rptR-Vorgabe.

**Einordnung, keine Entscheidung:** A ändert nur die beiden Stellen, die die falsche Prämisse tragen (K-M1b-5 (a) und (b), Formelsammlung Z. 190), und ist mit allen übrigen bindenden Stellen vereinbar. B ändert die Konvention selbst und reicht bis in die Simulationsszenarien. Builder und Reviewer empfehlen A.

### Frage 2 — Wie kommt der angepasste Abnahmetest vor BUILD ins Repo?

- Laut PLAN-REVIEW.md (Ergebnis; `orchestrate.sh:488`, `:491`) dürfen `30-plan-review` und `70-arbiter` `tests/acceptance/` nicht schreiben.
- Ohne Anpassung vor BUILD laufen BUILD und Gates gegen den heutigen K-M1b-5-Test, der für spec-treuen Code rot ist. Der Reviewer dürfte ihn erst in `50-code-review` ändern; das kostet eine Rework-Runde.
- Möglich sind eine Wiederholung von `10-acceptance` für M1b oder ein Betreiber-Commit mit Reviewer-ADR, jeweils vor BUILD.

## Nicht Gegenstand

- **E2 bis E8** sind nonblocking (`verdict-plan.json`) und nicht Gegenstand dieses Schiedsspruchs (ARBITER-REQUEST.md: „Entscheide ausschließlich die referenzierten blocking-Punkte“). Sie bleiben so, wie der Reviewer sie für Runde 2 vorgesehen hat.
- **`orchestrator/ESCALATION-M1b.md`** gehört dem Betreiber (AGENTS.md: „der einzige Human-Touchpoint“); der Arbiter schreibt sie nicht.
