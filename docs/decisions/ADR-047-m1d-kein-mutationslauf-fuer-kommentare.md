# ADR-047 — M1d: kein Mutationslauf für reine Kommentaränderungen in `R/fit.R` und `R/grr.R`

## Status

Angenommen (Betreiber, 04.11.2026). Nur für die Gates von M1d. Betreiber-Commit vor `20-plan` von M1d.

## Kontext

- K-M1d-7 verlangt, dass die Dokumentation von `msa_fit()` und `msa_boot()` die Befunde der Klasse-B-Studien nennt. Diese Dokumentation steht als roxygen-Kommentar in `R/fit.R` und `R/grr.R`. docs/02, M1d: „M1d ändert `R/fit.R` und `R/grr.R` nur in der roxygen-Dokumentation.“
- `86-mutgate.sh` wählt nach Dateidiff. Jede geänderte Datei im Scope löst den Lauf aus, auch wenn nur Kommentare abweichen.
- Lauf in M1c: 1478 Mutanten, Score 92,80 bei verlangten 92,09 (K-M1c-6 mit 80 bestanden). Dauer je Gate-Runde 9 h 51 min und 10 h 36 min. Keiner der 1478 Mutanten liegt auf einer Kommentarzeile (Nachzählung in `reports/mutation/mutation.json`, 03.11.2026).
- Der Score hängt nur vom mutierten Quelltext und den Tests ab (ADR-038). ACC-12 aus M1d vergleicht beide Dateien ohne Zeilen, die mit `#'` beginnen, Zeile für Zeile mit `done/M1c` (ANK-34). Die Abnahmetests von M1d sind vom Lauf ausgenommen (ACC-13).

## Entscheidung

1. Für die Gates von M1d trifft `MUT_SCOPE_REGEX` keine Datei; mutgate meldet „kein geänderter Mutations-Scope“. Mutationsbeleg für M1d ist der Lauf aus M1c.
2. Bedingungen: ACC-12 ist grün; unter `tests/` entfällt kein Test und wird keine Erwartung abgeschwächt. Eine Verletzung ist ein blocking-Befund im Review mit `ref` auf dieses ADR.
3. Nach `done/M1d` rechnet der Betreiber den Lauf einmal mit der Konfiguration ohne Nr. 1 in einer Kopie des Repos nach, außerhalb des Harness. Liegt der Score unter 92,09, kommt das ins Backlog und wird vor dem Release geklärt.
4. Vor M3a setzt der Betreiber `MUT_SCOPE_REGEX` auf `'^R/.*\.R$'` und entfernt die Zeile dieses ADR aus `orchestrator/config.env` (BL-24). `MUT_TEST_EXCLUDE` behält `|m1d-`.

## Begründung

Der Lauf würde dieselben Mutanten gegen dieselben Tests prüfen und je Gate-Runde rund zehn Stunden kosten, mindestens zweimal (nach BUILD und nach QA). Der einzige Verlust ist die automatische Erkennung abgeschwächter Unit-Tests; dafür gelten Nr. 2 und Nr. 3.

## Konsequenzen

- mutgate ist in M1d kein eigener Beleg. Paper und Bericht nennen den Lauf aus M1c und den Kontrolllauf aus Nr. 3.
- `state/mut-baseline` bleibt 94,09.
- Harness-Liste: Kommentaränderungen im Gate erkennen und den Mutationsbericht bei unverändertem Code wiederverwenden (wie ADR-038).
