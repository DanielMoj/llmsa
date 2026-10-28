# ADR-015 — Netzwache und Fortschrittslog für den AP1-Lauf

## Status

Angenommen (Betreiber, 28.10.2026; Betreiberänderung nach BL-01). Bindend ab Block 1 des Hauptplans. Pilot 3 lief mit dem Stand von `254f9fa` (ADR-014).

## Kontext

- `msa_run()` speichert jeden Backendfehler als Zeile und geht sofort zum nächsten Aufruf (`R/run.R:71–94`). Resume überspringt jeden gespeicherten Schlüssel, auch Fehlerzeilen (`R/run.R:59–64`).
- Fällt die Netzverbindung des Rechners aus (Neuverbindung des Routers, WLAN, DNS), scheitert jeder Aufruf binnen Millisekunden bis Sekunden, etwa mit „Could not resolve host“.
  - Wenige Minuten Ausfall erzeugen so genug Fehlerzeilen für den Wiederholungstag (mehr als 5 % eines Modells in einem Block, `acmg_repeat_day()`).
  - Ein Block von etwa 24 h muss dann neu laufen. Hauptplan und Robustheit laufen zusammen etwa 3,4 Tage am Stück (BL-74).
- `acmg_run_cli()` ruft `msa_run()` mit `verbose = FALSE` auf.
  - Während eines Blocks steht deshalb nichts im Log, und den Store während eines Laufs zu lesen ist ausgeschlossen.
  - Ein Problem zeigt sich erst nach 24 h.
- Grundlage der Erkennung in der installierten Fassung, nur lesend geprüft, ohne Netz:
  - httr2 1.3.0: `req_perform1()` fängt den Fehler von curl mit `capture_curl_error()` ab.
    - Daraus wird eine Bedingung der Klassen `httr2_failure`, `httr2_error`, `rlang_error`, `error` mit dem curl-Fehler als `parent`; `handle_resp()` löst sie aus.
    - Mit `req_retry(max_tries = 3)` und `retry_on_failure = FALSE` wiederholt httr2 solche Fehler nicht.
  - curl 8.1.0: `raise_libcurl_error()` erzeugt die Klassen `curl_error_<Name>`, `curl_error`, `error`, `condition`.
    - Die Meldung lautet „<libcurl-Fehler> [<Host>]:\n<Fehlerpuffer>“, etwa „Could not resolve hostname [openrouter.ai]:\nCould not resolve host: openrouter.ai“.
    - In dieser Form stehen auch die drei Fehlerzeilen von Pilot 2 („Timeout was reached [openrouter.ai]:\nOperation timed out after 120002 milliseconds with 334 bytes received“).
  - libcurl 8.18.0 mit OpenSSL 3.5.5: Formatzeichenketten aus `/usr/lib/x86_64-linux-gnu/libcurl.so.4`.
    - Die Fehlerpuffer einer Zeitüberschreitung nennen die Phase: „Resolving timed out after %ld milliseconds“, „Connection timed out after %ld milliseconds“ und „Connection timeout after %ld ms“.
    - Dagegen stehen während der Übertragung „Operation timed out after %ld milliseconds with %ld bytes received“ und „… with %ld out of %ld bytes received“.
    - Eine eigene Meldung für eine Zeitüberschreitung im TLS-Handshake gibt es in dieser Fassung nicht; der Handshake gehört zur Verbindungsphase.
- Pilot 3 lief am 28.10.2026 von 11:00 bis 11:37 (MEZ) mit dem Stand von `254f9fa`.
  - Geprüft an einer Kopie von `llmsa-runs/ap1_runs_3_nach_pilot.sqlite` (SHA-256 `450ba03d961e79ca35212d3328cb2cc8a1b7091ffeb6fde9c083982c614ad12b`): 90 Zeilen, keine Fehlerzeile, also keine mit einer Ursache nach E1, und keine unlesbare Antwort.
  - Pilot 3 bleibt damit nach E5 gültig. Mit den Regeln von ADR-014 bestehen alle drei Modelle alle fünf Regeln (projizierte Summe 46,54 USD).

## Entscheidung

1. (E1) Netzwache im AP1-Runner (`R/acmg.R`, `acmg_watch()`), nicht in exportierten Funktionen:
   - Scheitert ein API-Aufruf, bevor die Anfrage gesendet wurde, speichert der Runner keine Zeile, wartet und wiederholt denselben Aufruf. Gemeint sind: Name nicht auflösbar, Verbindung nicht aufgebaut, TLS-Handshake gescheitert, jeweils auch als Zeitüberschreitung in dieser Phase.
   - Erkannt wird das an diesen curl-Klassen in der Bedingung oder einem ihrer `parent`:
     - `curl_error_couldnt_resolve_host` und `curl_error_couldnt_resolve_proxy` (Name);
     - `curl_error_couldnt_connect` (Verbindung);
     - `curl_error_ssl_connect_error` und `curl_error_peer_failed_verification` (TLS-Handshake);
     - `curl_error_operation_timedout` mit einem der drei Fehlerpuffer der Verbindungsphase.
   - Neue Pflichtfelder in `plan.yaml`, validiert als endliche Zahlen > 0: `network.first_pause_s` 30, `network.max_pause_s` 600, `network.total_pause_s` 43200 (12 h).
   - Die Pause beginnt bei 30 s, verdoppelt sich bis höchstens 600 s, und die Pausen sind zusammen höchstens 43200 s.
     - Die Grenzen gelten je Aufruf; die letzte Pause wird auf den Rest gekürzt (30, 60, 120, 240, 480, 70-mal 600, 270 s).
     - Scheitert der Aufruf danach erneut vor dem Senden, endet der Lauf mit Status ungleich 0 und klarer Meldung, ohne Zeile für diesen Aufruf. Die Meldung beginnt mit „AP1 network unavailable:“, nennt den Aufruf und endet mit „continue with the same command.“
     - Der Betreiber setzt mit demselben Befehl fort; der Lauf beginnt dann genau mit diesem Aufruf.
   - Jede Pause steht mit Uhrzeit, Ursache (Meldung von curl, ohne Zeilenumbruch) und Dauer im Log.
2. (E2) Alle anderen Fehler bleiben ohne Pause Fehlerzeilen wie bisher:
   - HTTP-Statusfehler;
   - Zeitüberschreitung während der Übertragung („Operation timed out … bytes received“);
   - Abbruch beim Senden oder Empfangen (`curl_error_send_error`, `curl_error_recv_error`);
   - leere Antwort und jeder andere Fehler.

   Dort kann die Anfrage den Anbieter erreicht haben und berechnet sein (ADR-014 E6). Ausfälle beim Anbieter bleiben Sache des Wiederholungstags. Im Zweifel gilt ein Fehler als E2.
3. (E3) Gelingt ein Aufruf nach Pausen, trägt `meta` `network_retries` und `network_wait_s`. Endet er nach Pausen mit einem Fehler nach E2, erhält die Fehlermeldung den Zusatz „ [after N network retries, W s]“. Ohne Pause ändert sich nichts.
4. (E4) Fortschritt im Log (stderr, jede Zeile beginnt mit „[JJJJ-MM-TT hh:mm:ss Zone] AP1 <Teil> block <n>:“):
   - beim Start eines Teils oder Blocks „start, <offen> open“;
   - danach alle 100 Aufrufe und nach jedem Backendfehler „<erledigt> done, <offen> open; backend errors since start: sol <n>, llama <n>, qwen <n>“, nach einem Backendfehler mit „backend error (<Modell>);“ davor.
   - Erledigt und offen zählen je Block, die Backendfehler je Modell seit Start des Prozesses.
   - Antworttexte und Schlüssel stehen nie im Log.
5. (E5) Im Normalbetrieb bleiben Anfragen, Antworten, gespeicherte Felder und Parser unverändert. Pilot 3 bleibt deshalb gültig, wenn sein Store keine Fehlerzeile mit einer Ursache nach E1 enthält; der Hauptplan läuft im Store von Pilot 3.
6. (E6) Hauptplan und Robustheit laufen aus einem eigenen Klon (`/mnt/c/Users/Danie/dev/Llmsa/llmsa-ap1`, Commit dieses ADR). So kann der Harness in `llmsa/` weiterarbeiten, ohne den Code eines folgenden Blocks zu ändern.

## Konsequenzen

- Betreiberänderung nach BL-01 außerhalb des Harness (Orchestrator angehalten, kein `orchestrator/.lock`; Umsetzung mit Claude Code). Geändert:
  - `R/acmg.R`:
    - `acmg_validate_plan()`;
    - neu `acmg_watch()` mit `acmg_network_failure()`, `acmg_network_cause()`, `acmg_wait()` und `acmg_log()`;
    - `acmg_run_cli()`.
  - `inst/validation/ap1/plan.yaml`: neuer Abschnitt `network`, `provenance.plan`;
  - `DESCRIPTION`: `curl` unter Suggests. Die Tests erzeugen die Bedingungen mit `curl:::raise_libcurl_error()` und `httr2:::capture_curl_error()` der installierten Fassungen. curl ist ohnehin eine Abhängigkeit von httr2.
  - `docs/03-anwendungspipeline.md`: A.8 Nr. 4 als neuer Satz; die Zeilenzahl bleibt;
  - `inst/validation/ap1/README.md`, `NEWS.md`, `BACKLOG.md` (BL-75 neu);
  - neu `tests/testthat/test-acmg-network.R`: je Meldungsform ein Test und die Abläufe nach E1 bis E4.
- Unverändert:
  - `R/run.R`, `R/backends.R`, die exportierten Funktionen und ihre `formals()` (`ANK-02`);
  - `tests/acceptance/`, `tests/e2e/`, `tests/fuzz/`, `tests/fixtures/`, `inst/extdata/`, `reference/anchors/` und `orchestrator/`.

  Die Kriterien K-M2-1 bis K-M2-7 bleiben wortgleich. Kein Abnahmetest schreibt stderr der CLI fest; K-M2-7 sucht die Regelzeilen in stdout und stderr.
- Der Abbruch nach E1 ist eine Bedingung der Klasse `acmg_network_abort`, die kein Fehler ist. Daher speichert `msa_run()` sie nicht als Zeile; `acmg_run_cli()` fängt sie und endet mit einem Fehler.
- Nach Pausen ist `timestamp` der Beginn des ersten Versuchs, und `latency_s` schließt die Pausen ein. Wie lang sie waren, nennen `network_wait_s` bzw. der Zusatz der Fehlermeldung. Vor dem AP1-Bericht ziehen dessen Latenzkennzahlen `meta$network_wait_s` ab, sobald Netzpausen vorkommen (BL-75).
- Pausen sind keine Backendfehler. Die Fehlerquote eines Blocks misst damit nur Fehler nach E2; ein Ausfall des eigenen Netzes verlängert den Block um die Pausen.
- Ein Ausfall von mehr als 12 h an einem Aufruf beendet den Lauf. Ein E1-Fehler, der nicht vorübergeht (etwa ein dauerhaft scheiterndes Zertifikat), kostet ebenfalls bis zu 12 h, bevor der Lauf endet.
- Die Tests hängen an der Struktur der Bedingungen von httr2 1.3.0 und curl 8.1.0. Ändert eine neue Fassung Klassen, Meldungen oder die genutzten internen Funktionen, schlagen sie fehl; dann ist die Erkennung neu zu prüfen.
