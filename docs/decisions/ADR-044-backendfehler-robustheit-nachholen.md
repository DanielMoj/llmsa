# ADR-044 — Backendfehler der AP1-Robustheitsläufe: Fehlerzeilen nachholen statt den Teil wiederholen

## Status

Angenommen (Betreiber, 02.11.2026; ausgeführt 03.11.2026). Betreiber-Commit vor M1d. Ändert ADR-011 Nr. 6 für den englischen Lauf von AP1.

## Kontext

- ADR-011 Nr. 6: Liegt der Anteil der Backendfehler eines Modells in einem PB-Lauf über `error_share_trigger` (5 %, ANK-67), wiederholt der Betreiber den Robustheitsteil auf der Storekopie vor den Robustheitsläufen.
- Erster Durchgang, 02.11., 10:57 bis 03.11., 7:04: Sol und Llama ohne Backendfehler. Qwen 82 von 1200 Aufrufen (6,83 %), davon 81-mal HTTP 429 nach den Wiederholungen und einmal `parse error: premature EOF`. Über 5 % in 8 von 12 PB-Läufen.
- Die Fehler hängen an der Tageszeit und nicht am Inhalt: vor 15 Uhr keiner, danach über den Abend und die Nacht verteilt, ab 5:41 keiner mehr. Block 2 begann am 29.10. um 10:21, der erste 429 kam um 15:39. Die Reihenfolge der Aufrufe ist über alle Läufe zufällig, die Fehler verteilen sich also auf alle zwölf Läufe.
- Eine Wiederholung hätte rund 9 $ und einen knappen Tag gekostet, vollständige Daten von Sol und Llama verworfen und wäre in dieselbe Drosselung gelaufen.
- Qwen zu streichen ist keine Alternative: Der Plan mit drei Modellen ist öffentlich, und mit zwei Modellen ginge der Faktor Modell über β̂²/2 statt als Zufallseffekt in den gemeinsamen Fit.

## Entscheidung

1. Liegt ein Modell in einem PB-Lauf über `error_share_trigger`, werden auf einer Storekopie nur seine Zeilen mit gesetztem `error` in `pb01` bis `pb12` gelöscht und mit `msa_run(resume = TRUE)` (`run.R --part robustness`, gleicher Commit) einmal nachgeholt. Unlesbare Antworten sind keine Backendfehler; sie bleiben stehen.
2. Die Kopie vor dem Nachholen bleibt unverändert als Beleg. Die gelöschten Zeilen werden als CSV festgehalten.
3. Die Auswertung rechnet auf der Kopie mit den nachgeholten Zeilen, als Sensitivität auch auf der Kopie davor (Backendfehler zählen dort als Nichtübereinstimmung).
4. Bericht und Paper nennen Zahl und Zeitpunkt der Fehler, den Zeitpunkt des Nachholens und dass Qwen damit teils an einem anderen Tag gemessen ist.
5. Bleiben danach Fehler unter `error_share_trigger`, werden sie nach ADR-011 Nr. 6 berichtet; einen zweiten Durchgang gibt es nicht. Bleibt ein Lauf über der Grenze, steht die Robustheit des Modells im Bericht als „nicht auswertbar“. Der Hauptplan bleibt davon unberührt.

## Ausführung

- 03.11.2026, 9:37:54 bis 10:55:59, Klon auf `f948105`, ohne Änderung an Code oder Plan.
- Gegen die Kopie davor unterscheiden sich nur die 82 Qwen-Zeilen; die Schlüsselmenge ist gleich, Sol und Llama sind zeilengleich. 79 Zeilen kamen vom festgelegten Anbieter zurück, 3 enden erneut mit HTTP 429, 3 der 79 sind unlesbar. Qwen danach 0 oder 1 Fehler je PB-Lauf, höchstens 1 %, kein `error_trigger`.
- Stores (SHA-256): vor dem Nachholen `08d37c20962cb5c876d641b8d91e09caee38ae0f810708a61913d70ad392211f`, danach `e43926bdd919f708c90898023311748711198984189cf782734461553c6a9a25`.

## Konsequenzen

- Der Code ändert sich nicht. `acmg_robustness_errors()` und der Berichtsabschnitt zeigen die Fehler des jeweils ausgewerteten Stores; die Zahlen des ersten Durchgangs liefert die Sensitivitätsrechnung aus Nr. 3.
- Qwen ist in den nachgeholten Zeilen zu einer anderen Zeit gemessen als in den übrigen. Das Nachholen ändert nach der vorläufigen Rechnung weder Band noch aktive Faktoren; die Endauswertung prüft das erneut.
