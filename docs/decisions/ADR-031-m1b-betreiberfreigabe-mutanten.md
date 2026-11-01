# ADR-031 — M1b: Betreiberfreigabe äquivalenter Mutanten und Mutationstoleranz

## Status

Angenommen (Betreiber, 01.11.2026). Ausnahme für M1b. Die Dateien entstanden
während der Gates nach dem QA-Nachlauf in Runde 3 und gehen mit dem Gate-Commit
des Orchestrators ins Repository; kein Betreiber-Commit, keine laufende
Modellphase. Keine Änderung an Kriterien, Schnittstellen, Spezifikation oder Code.

## Kontext

- Das Mutationsgate (`orchestrator/gates.d/86-mutgate.sh`) verlangt
  Basis − `MUT_RATCHET_TOL` = 93,83 − 2 = 91,83. Die Basis stammt aus M1a
  (973 / (973 + 65 − 1) laut `orchestrator/handoff/M1a/REVIEW.md`) und enthält
  eine Äquivalenzfreigabe: `R/grr.R:94`, `> → >=`.
- Gates Runde 3: mutgate pass mit 91,86 (Killed 1180, Timeout 28, Survived 107;
  1208 / 1315). Ein Mutant macht rund 0,08 Punkte aus; Timeouts zählen als
  entdeckt und schwanken mit der Rechnerlast. Der Lauf nach dem QA-Nachlauf lag
  bei 874 von 1369 Mutanten gleichauf (82 überlebt).
- Liegt der erste Durchgang unter der Schwelle, folgt genau ein vollständiger
  Flake-Rerun (ADR-019, dritter Nachtrag), rund 6,5 Stunden.
- Freigaben sind an Meilenstein und Zeilennummer gebunden (E48/BL-85, offen seit
  M1a). Für M1b gab es keine Freigabedatei. Der in M1a freigegebene Mutant steht
  jetzt in `R/grr.R:99` und zählt wieder als Überlebender. Der Builder hat in
  `orchestrator/handoff/M1b/MUT-EQUIV.json` drei Anträge gestellt.
- Basis, Toleranz und Wiederholungsregel liest das Gate beim Start ein; die
  Freigabeliste liest es erst nach dem ersten Durchgang. Nur sie wirkt auf den
  laufenden Durchgang.

## Entscheidung

1. Der Betreiber gibt vier überlebende Mutanten als äquivalent frei
   (`orchestrator/handoff/M1b/MUT-EQUIV-APPROVED.json`):

   | Stelle | Mutator | Prüfung |
   | --- | --- | --- |
   | `R/fit.R:405` | `<n> + 1 → <n> + 1` (`matrix(1, k, k)`) | Die Doppelschleife in `msa_latent_information()` weist für alle i ≤ j `gram[i, j]` und `gram[j, i]` zu, bevor eine Zelle gelesen wird; bei k = 0 ist die Matrix leer. Antrag des Builders; derselbe Mutant war in M1a vom Reviewer freigegeben (damals Zeile 357). |
   | `R/fit.R:405` | `<n> - 1 → <n> - 1` (`matrix(-1, k, k)`) | wie oben |
   | `R/fit.R:398` | `TRUE → FALSE` (`strsplit(groups, ":", fixed = FALSE)`) | Das Trennmuster `":"` ist auch als regulärer Ausdruck ein Literal; beide Varianten trennen die intern gebildeten Gruppennamen identisch. Antrag des Builders. |
   | `R/grr.R:99` | `> → >=` (`grr_v >= 0`) | Unterschied nur bei `grr_v = 0`. Dann gilt wegen `total_v != 0` und nichtnegativer Varianzanteile `item_v > 0`, und der mutierte Zweig liefert `max(1, floor(Inf)) = Inf` wie der `else`-Zweig. In M1a als `R/grr.R:94` vom Reviewer freigegeben und in der Basis 93,83 enthalten. |

2. Keine weiteren Freigaben. Nicht freigegeben sind `NA_real_ → NA`
   (`R/grr.R:79`, `:87`, `:99`; Typ beobachtbar) und `R/grr.R:128` (Druckausgabe
   beobachtbar); das sind Testlücken. `R/grr.R:99` `<n> - 1 → <n> - 1`
   (`grr_v > -1`) ist unter der Invariante `grr_v >= 0` vermutlich ebenfalls
   äquivalent, war aber weder beantragt noch in M1a freigegeben; Entscheidung beim
   Reviewer.
3. `MUT_RATCHET_TOL` = 3 statt 2 in `orchestrator/config.env` (nicht versioniert),
   Schwelle 90,83. Gilt ab dem nächsten Gate für den Rest von M1b. Vor dem Start
   von M1c setzt der Betreiber den Wert auf 2 zurück.
4. Der Reviewer kann jede Freigabe in Review r3 oder später widerrufen; ein
   Widerruf gilt ab dem nächsten Gate.

## Begründung

- Äquivalente Mutanten kann kein Test töten; das Gate sieht ihre Freigabe vor.
  Die Freigabe korrigiert den Nenner und senkt die Anforderung an die Tests nicht.
- Die Basis aus M1a enthielt eine Freigabe, die in M1b nur wegen verschobener
  Zeilen nicht mehr greift. Ohne Neubindung vergleicht der Ratchet ungleiche Größen.
- Mit den Freigaben liegt der Score der Nacht bei 1208 / 1311 = 92,14; der
  laufende Durchgang darf vier Mutanten schlechter ausfallen, ohne den
  Flake-Rerun auszulösen. Ein Rerun von rund 6,5 Stunden wegen Abweichungen unter
  einem Mutanten bringt keinen Erkenntnisgewinn.
- Die Toleranz 3 fängt den Fall ab, dass der Builder in einer weiteren Runde Code
  verschiebt und die Zeilenbindung aus Nr. 1 verloren geht.

## Konsequenzen

- Abweichung vom Verfahren: Die Freigabe erteilt ausnahmsweise der Betreiber,
  nicht der Reviewer (`86-mutgate.sh`, Kopf: „Äquivalenz nur nach
  Reviewer-Approval“); deshalb Nr. 4.
- Rücknahme: Einträge aus `MUT-EQUIV-APPROVED.json` entfernen;
  `MUT_RATCHET_TOL` zurück auf 2.
- Offene Ursache (E48/BL-85): Freigaben hängen an Zeilennummern, und die Basis
  gilt über Meilensteine mit wachsendem Mutations-Scope. Vorschlag für die
  Harness-Überarbeitung: Freigaben am Mutanten binden (Datei, Mutator, Codezeile
  vorher und nachher) statt an der Zeilennummer; Basis je Meilenstein beim ersten
  bestandenen Gate neu setzen.
