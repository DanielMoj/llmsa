# ADR-004 — Betreiberfreigabe des Validierungsplans AP1 (BL-27)

## Status

Angenommen (Betreiber, 25.10.2026; bindend ab Start von M2), einschließlich der Wortlaute der Prompt-Vorlagen (A.3) und der Bausteine (A.5).

## Kontext

- `docs/03-anwendungspipeline.md`, Anhang A, trug den Vermerk „Entwurf der Projektierung, vom Betreiber vor Start von M2 freizugeben“; BL-27: „Vor Start von M2 freigeben; Freigabe in `plan.yaml` und ADR festhalten“.
- Am 25.10.2026 hat der Betreiber den Anhang prüfen lassen (Prüfung des Anhangs A, Betreiberunterlage außerhalb des Repos) und die Belege der Prüfung nachprüfen lassen (Belegprüfung). Die Vorschläge betreffen die Kriterien K-M2-1 bis K-M2-6, ein neues Kriterium K-M2-7 und den Plan selbst. Kriterien von M2 lassen sich ohne ADR nur vor dem Start von M2 ändern.
- Präzedenz: Wo die Belegprüfung von der Prüfung abweicht, gilt die Belegprüfung (gefährliche Fehler, Robustheit, Temperatur, Antwortmetadaten von OpenRouter, Wissensstände, INSAID-Transkripte).

## Entscheidung

Der Betreiber gibt den Validierungsplan AP1 in der Fassung von `docs/03-anwendungspipeline.md` frei, die mit diesem ADR committet wird. Im Einzelnen:

1. Variantenschreibweise: `hgvs` ist Transkript und c.-Bezeichnung ohne Gen und ohne p.-Angabe; Transkript und p.-Angabe stehen in eigenen Spalten `transcript` und `protein`. ERepo-Einstufungen ohne c.-Bezeichnung auf einem NM-Transkript kommen nicht in den Pool. INSAID-Items erhalten das Transkript aus den Methoden der Publikation (`ANK-64`); ihre p.-Angabe liest `acmg_items()` nur zur Laufzeit aus der lokalen TSV (K-M2-1, A.2, A.5).
2. Memorisierungs-Kennzeichen `prior_clinvar_class`, `prior_date` und `prior_differs` je Stichtag der drei Modelle mit den Suffixen `_sol` (`ANK-50`), `_llama` (`ANK-65`) und `_qwen` (`ANK-66`); die Hauptauswertung nutzt `_sol`, die Auswertung je Modell für Llama und Qwen deren eigene Spalten (K-M2-2, K-M2-6, A.1). BL-59 ist damit geschlossen.
3. Pilot- und Robustheitsläufe sind das eigene Kriterium K-M2-7: `acmg_prompts(robustness = TRUE)`, `run.R --part pilot|main|robustness`, Prompt-IDs `pb01` bis `pb12`, Systemprompt über die Spalte `system`, die `backend_openai_compatible()` nur nutzt, wenn sie vorhanden und nicht leer ist. K-M2-7 steht in `orchestrator/milestones.json` bei M2.
4. Aufrufreihenfolge: Replikat als äußere Schleife im Block, Zufallsreihenfolge innerhalb des Replikats (K-M2-6, A.5).
5. Prompt-Vorlagen ohne verbleibende Platzhalter `{gene}`, `{hgvs}`; der Parser erkennt Klassen nur als ganze Wörter über das neue Argument `parse_choice(…, whole_word = TRUE)`; die Vorgabe `FALSE` lässt das Verhalten von v0.1.0 unverändert (K-M2-3).
6. Bausteine, Wortlaute und Kompositionsregel der Robustheitsläufe (A.5, `ANK-62`) sowie die Wortlaute der drei Prompt-Vorlagen (A.3).
7. Auswertung je Modell mit Modalantwort, NA-Regel, Verdikt je Kriterium und Gesamtverdikt als schlechtestem Band; der gemeinsame Fit über die drei Modelle ist Forschungsergebnis ohne Verdikt (K-M2-6, A.1, `ANK-58`, `ANK-68`).
8. Akzeptanz: Kappa-Verdikt am Punktschätzer, berichtet mit 95-%-Bootstrap-Intervall über Items; gefährliche Fehler 0 / 1 / ab 2; Robustheit über Δp mit drei Bändern; %GRR nur zwischen Modellen auf demselben Itemsatz vergleichbar, mit Rückfall auf einen numerischen Fit; Antwortgröße der Robustheit als empirischer Logit mit Korrektur ½ (A.1, A.5, `ANK-58`, `ANK-68`).
9. Temperatur, Seed, Reasoning: Sol ohne Temperatur (`temperature = NULL` als Fehlerbehebung, K-M2-4), Llama und Qwen mit Temperatur 0; Seed 20261024 in allen Aufrufen; Qwen ohne Reasoning über `reasoning = {"enabled": false}`, im Pilot geprüft (A.4, `ANK-61`).
10. Pilot mit Bestehensregeln und vorab festgelegten Auslösern für einen Wiederholungstag (A.6, `ANK-67`).
11. Context of Use mit „Varianten in c.-Notation auf einem NM-Transkript“ und dem Satz „Eingabe: Gen und Variantenbezeichnung ohne Evidenz“; die Auswahl im Umlauf über Panels und Gene bleibt (A.1, A.2).
12. Die httptest2-Aufzeichnungen werden über URL und Modellkennung zugeordnet; ein mit `httptest2::set_requester()` gesetzter Requester reduziert den Request-Body dafür auf `model` (K-M2-4).
13. Ablauf der Erhebung ohne eigenes Kriterium (A.8): Zugänge und Limits (`ANK-57`), Live-Prüfung der Preise unmittelbar vor dem Pilot, Store mit absolutem Pfad, nach jedem Block kopiert und mit SHA-256 festgehalten; die Logging-Regeln der Anbieter aus `Provider_Logging.html` und die Datenregeln von OpenAI aus `Your_data.html` gehen in den Bericht (A.7).

Die neuen Zahlen dieser Freigabe sind Betreiberfestlegungen vom 25.10.2026 und stehen in `ANKER-TODO.md` (`ANK-57`, `ANK-58`, `ANK-61`, `ANK-62`, `ANK-67`, `ANK-68`). Der Reviewer erntet sie in der ACCEPTANCE-Phase von M2 mit Zitat dieses ADR.

## Konsequenzen

- `inst/validation/ap1/plan.yaml` übernimmt den Plan wörtlich (K-M2-5); der Builder setzt K-M2-1 bis K-M2-7 in M2 um. R-Code und Tests ändern sich erst dort.
- Schnittstellen nach `01-fachspezifikation.md` §4: `parse_choice()` erhält ein neues letztes Argument mit Vorgabe, das ist ohne ADR zulässig. `backend_openai_compatible()` sendet zusätzlich die Spalte `system` der Designzeile als Systemnachricht, wenn sie vorhanden und nicht leer ist; das ist eine additive Erweiterung, keine Bedeutungsänderung. Bei `temperature = NULL` lässt es das Feld weg (Fehlerbehebung mit Eintrag in `NEWS.md` im BUILD von M2). Die `formals()` der 22 Funktionen von v0.1.0 bleiben erhalten (`ANK-02`).
- Die Stichtage für die Kennzeichen `_llama` und `_qwen` sind Anker von K-M2-2; der Reviewer erntet sie in der ACCEPTANCE-Phase von M2 aus `models.json` (`ANK-65`, `ANK-66`).
- Nach dem Start von M2 ändert sich der Plan nur durch ein neues ADR; das gilt auch für Änderungen, die der Pilot nahelegt.
- BL-27 und BL-59 sind geschlossen.
