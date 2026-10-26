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

## Nachtrag 26.10.2026 — Berichtigung zu Punkt 12

- Punkt 12 verlangt einen mit `httptest2::set_requester()` gesetzten Requester. Diese Funktion gibt es in httptest2 nicht: Das Referenzhandbuch 1.2.2 (CRAN) und die Exportliste der Entwicklungsfassung 1.2.2.9000 (`NAMESPACE` auf GitHub) kennen nur `set_redactor()`, das Antworten beim Aufzeichnen redigiert; `set_requester()` stammt aus httptest für httr. Nachgeprüft am 26.10.2026, zusätzlich an der installierten httptest2 1.2.2 (`getNamespaceExports()`).
- Ersatz für Punkt 12:
  1. Die Aufzeichnungen sind die unveränderten JSON-Antwortkörper je Modell unter `tests/fixtures/api/` (statt `tests/fixtures/httptest2/`), dazu das Aufnahmeskript `record.R` und `README.md`.
  2. Tests spielen sie mit `httr2::local_mocked_responses()` ein. Die Mock-Funktion ordnet über die URL und das Feld `model` des JSON-Bodys zu, sodass Feldreihenfolge und übrige Body-Felder die Zuordnung nicht ändern; findet sie keine Aufzeichnung, bricht sie mit Fehler ab, statt `NULL` zu liefern (httr2 schickte die Anfrage sonst ab). Der konstruierte Fehlerfall ist eine Mock-Antwort mit HTTP 4xx.
  3. httptest2 entfällt als Abhängigkeit.
- Angepasst: `docs/03-anwendungspipeline.md` K-M2-4, `docs/04-weitere-bausteine.md` K-M3d-3, `docs/01-fachspezifikation.md` (Suggests in §5, Betreiber-Territorium in §9), `AGENTS.md` (Suggests, Aufzeichnungen), `ANKER-TODO.md` ANK-94, `BACKLOG.md` BL-26 und neu BL-60 (vor M3d prüfen, ob die httr2-Mocks die Aufrufe von `backend_ellmer()` abfangen), `docs/gates-auswahl.md` §2. `orchestrator/handoff/M0/PLAN.md` bleibt als Verlauf unverändert. Punkt 12 bleibt als Verlauf stehen; an seiner Stelle gilt dieser Nachtrag.

## Nachtrag 26.10.2026 (2) — Reasoning bei Qwen, zu Punkt 9

- Befund: Die Aufzeichnung `tests/fixtures/api/qwen.json` vom 26.10.2026, 20:37:10 UTC, mit `reasoning = {"enabled": false}` nach Punkt 9 enthält Reasoning-Text in `message.reasoning` und meldet 308 Reasoning-Tokens; `content` ist die bloße Klasse (BL-61). Die OpenRouter-Doku „Reasoning Tokens“ (Schnappschuss 26.10.2026, `quellen/anbieter_2026-10-26/openrouter/Reasoning_Tokens.md`) nennt `enabled` nur als Einschalter; dokumentierter Abschalter ist `"effort": "none"` („Disables reasoning entirely“), Modelle mit Pflicht-Reasoning lehnen ihn ab. Der Abschnitt zur Effort-Stufe nennt als unterstützte Modelle die Reasoning-Modelle von OpenAI und Grok.
- Test 1 (26.10.2026, 20:54:34 UTC), Anfrage wie die Aufzeichnung, nur mit `reasoning = {"effort": "none"}`: HTTP 200, Anbieter DeepInfra, 223 Completion-Tokens, 274 Reasoning-Tokens, Reasoning-Text in `message.reasoning`, `content` „Uncertain significance“. Der Endpunkt nimmt den Abschalter an und ignoriert ihn.
- Test 2 (26.10.2026, 20:54:53 UTC), ohne Feld `reasoning`, Systemnachricht mit angehängtem „ /no_think“: HTTP 200, Anbieter DeepInfra, 7 Completion-Tokens, 1 Reasoning-Token, `message.reasoning` = `"\n\n"`, `content` „Uncertain significance“.
- Entscheidung (Betreiber, 26.10.2026): Qwen läuft mit dem Reasoning, das der Endpunkt ausliefert; die Anfrage trägt kein Feld `reasoning` und kein `/no_think`, weil dieser Schalter den Prompt nur für Qwen änderte. Die Pilotregel „bei Qwen kein Reasoning“ und die Prüfregel „kein Feld `reasoning`“ entfallen; der Pilot berichtet je Modell die Reasoning-Tokens (Median und 90-%-Quantil), und die Kostenprojektion aus dem 90-%-Quantil der Ausgabetokens (`usage.completion_tokens`) schließt Reasoning ein. Ausgewertet wird nur `content`; `message.reasoning` geht nicht in den Parser. `ANK-56` und `ANK-57` bleiben unverändert, weil A.6 schon höchstens 2.000 Ausgabetokens samt Reasoning annimmt.
- Angepasst: `docs/03-anwendungspipeline.md` K-M2-4 (Beispiel `reasoning` gestrichen, das Durchreichen weiterer Body-Felder bleibt), A.4 (Tabelle und Text) und A.6; `ANKER-TODO.md` ANK-61 und ANK-67; `tests/fixtures/api/` (`record.R` ohne Feld `reasoning` für Qwen, `qwen.json` neu aufgezeichnet, `README.md` mit beiden Tests); `BACKLOG.md` BL-61 (erledigt) und BL-62. Die Testantworten sind keine Aufzeichnungen und liegen nicht im Repo. Punkt 9 bleibt als Verlauf stehen; für Qwen gilt dieser Nachtrag.
