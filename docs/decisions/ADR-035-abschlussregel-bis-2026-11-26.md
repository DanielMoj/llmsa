# ADR-035 — Abschlussregel für Befunde bis zum 26.11.2026 (M1b bis M1d)

## Status

Angenommen (Betreiber, 01.11.2026). Gilt für M1b, M1c und M1d bis zum 26.11.2026; danach entfällt die Regel (Nr. 5). Betreiber-Commit
vor dem Neustart von M1b Runde 5, nachdem der Orchestrator nach der
Territoriumsverletzung in Rework r5 (Versuch 1) beim Start von Versuch 2
angehalten hatte; Builder und Reviewer sehen die Regel ab Runde 5.

## Kontext

- Seit Runde 2 kostet jede Runde in M1b rund acht Stunden, davon etwa 7,5 für
  den Mutationstest.
- Die blockierenden Befunde der Runden 2 bis 4 betreffen dieselbe Klasse, die
  Identifizierbarkeit latenter Zufallsterme: E24 (ADR-029), E29 (ADR-032),
  E33 und E34 (ADR-034). Jede Runde fand Fälle, die die vorherige Definition
  nicht abdeckte, zuletzt Rundung bei exakten Relationen ab etwa 900 Items mit
  je einer Beobachtung (E33) und nicht ganzzahlige Gewichte (E34).
- Diese Fälle betreffen Pläne, in denen sich ein Zufallsterm nicht von der
  Restvarianz oder einem anderen Term trennen lässt. Reguläre
  Messsystemanalysen haben Wiederholmessungen; AP1 hat 100 Items mit je 54
  Beobachtungen und verwendet in den Fits keine Gewichte.
- Der Zeitplan (Frist 26.11.2026) braucht die Abnahme von M1 bis zum
  Go/No-Go am 15.11.2026. Weitere Runden für entartete Pläne verschieben das,
  ohne Ergebnisse auf regulären Plänen zu ändern.

## Entscheidung

1. Blockierend sind bis zum 26.11.2026 nur:
   a) Verstöße gegen die Abnahmekriterien des Meilensteins
      (`orchestrator/handoff/<MS>/CRITERIA.json` und die K-Kriterien in `docs/`);
   b) rote Gates;
   c) Rückschritte bei bereits abgenommenem Verhalten;
   d) Befunde, die bei regulären Plänen still falsche Ergebnisse liefern.
      Regulär sind Pläne wie in den Abnahmekriterien, den Szenarien der
      Simulationsstudien (`docs/02-statistikkern.md`) und AP1
      (`inst/validation/ap1/plan.yaml`), auch mit einzelnen fehlenden Werten.
2. Nicht blockierend sind Randfälle entarteter Pläne: Pläne, in denen ein
   geschätzter Zufallsterm nicht von der Restvarianz oder einem anderen Term
   trennbar ist (etwa eine Beobachtung je Item oder je Zelle eines geschätzten
   Terms, deckungsgleiche Partitionen), nicht ganzzahlige Gewichte, Gewicht 0
   und Konstruktionen, die nur über `weights`, `subset` oder `offset`
   entstehen. Das schließt numerische Grenzfälle der
   Identifizierbarkeitsprüfung bei solchen Plänen ein.
3. Jeder nach Nr. 2 zurückgestellte Befund erhält einen BACKLOG-Eintrag mit
   Reproduktion (Aufruf, Seed, beobachtet, erwartet) und der Markierung
   „nach 26.11.2026“. Die Hilfe zu `msa_fit()` nennt die bekannten Einschränkungen
   in einem Abschnitt „Known limitations“; fehlt er, ist das nicht blockierend.
4. Die Umsetzung von E33 und E34 (ADR-034) bleibt Auftrag von M1b Runde 5.
   Ist sie unvollständig, sind die Reste nach Nr. 2 nicht blockierend.
5. Nach dem 26.11.2026 werden alle mit „nach 26.11.2026“ markierten Befunde in einem
   eigenen Arbeitspaket vor der nächsten Version behoben. Zurückgestellt heißt
   nicht gestrichen.

## Konsequenzen

- Reviewer: Befunde nach Nr. 2 sind nonblocking mit BACKLOG-Verweis. Die
  Regel ist eine Spec-Entscheidung des Betreibers
  (AGENTS.md: Spec > Reviewer > Builder).
- Builder: bis zum 26.11.2026 keine Arbeit an Befunden nach Nr. 2, außer sie fällt
  im selben Zug mit blockierender Arbeit an.
- Risiko: Bis zur Behebung kann das Paket bei entarteten Plänen still
  unsinnige Varianzanteile ausgeben; deshalb Nr. 3 und Nr. 5.
- Rücknahme: mit dem 26.11.2026 (Nr. 5) oder durch ein neues Betreiber-ADR.
