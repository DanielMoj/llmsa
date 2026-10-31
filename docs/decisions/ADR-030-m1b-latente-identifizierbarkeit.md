# ADR-030 — M1b Rework: Identifizierbarkeit latenter Varianzkomponenten

## Status

Umsetzungsentscheidung des Builders, REWORK M1b Runde 3, 31.10.2026.
Setzt E24 und ADR-029 Nr. 2 um; keine Änderung von Kriterien,
Schnittstellen, Engine-Vorgaben oder empirischen Toleranzen.

## Entscheidung

1. Nach Antwortbereinigung und Zeilenauswahl prüft `msa_fit()` für
   ordinale und binäre Zielgrößen alle tatsächlich verwendeten
   Zufallsterme einschließlich Wechselwirkungen. Das feste Design ist
   der Achsenabschnitt mit den ordinalen Zwei-Stufen-Faktoren; deren
   vorhandene Rangprüfung und übergebene Kontraste bleiben maßgeblich.
2. `msa_latent_information()` berechnet das in ADR-029 empfohlene
   Gram-Kriterium. Für die Indikatormatrizen Z_i und eine orthonormale
   Basis Q des festen Designs gilt P = I − QQᵀ und
   G_ij = ‖Z_iᵀ P Z_j‖²_F. Gleichwertig ist G das Gram der
   projizierten Kovarianzmatrizen P Z_i Z_iᵀ P. Lineare Abhängigkeit
   bedeutet, dass sich die Komponenten nicht trennen lassen.
3. Die Berechnung verwendet dünn besetzte Indikatormatrizen und
   Kreuzprodukte im Raum der Faktorstufen. Sie erzeugt weder P noch
   Beobachtungs-Kovarianzmatrizen mit n × n Einträgen. `Matrix` ist
   bereits eine genehmigte Abhängigkeit; kein Import kommt hinzu.
4. Vollständig vom festen Design aufgespannte Terme erhalten exakt
   eine Nullzeile und Nullspalte in G. Der Nachweis benutzt den Rang:
   Eine Indikatormatrix Z mit q beobachteten Stufen hat Spaltenrang q.
   Sie kann nur bei q ≤ p im p-dimensionalen festen Raum liegen;
   Rang([X, Z]) = p beweist dies. Die kleine QR-Prüfung verwendet
   dieselbe R-Rangkonvention wie die bestehende feste Designprüfung.
   Das verhindert insbesondere, dass bei nur einem vollständig
   aufgespannten Zufallsterm Rundungsreste eine positive 1 × 1-Matrix
   mit scheinbarer Konditionszahl eins erzeugen. Tests decken q = p
   sowie q < p ab.
5. Die Eigenwertregel bleibt die aus ADR-029 und dem numerischen
   Pfad: min(ev) ≤ k · `.Machine$double.eps` · max(ev), mit k als
   Zahl der Zufallsterme. Ein Verstoß endet vor dem Engine-Aufruf mit
   einem Fehler, der die gemeinsam geprüften Zufallsterme nennt.
   Es entsteht keine empirische Konstante oder neue Abnahmetoleranz.
6. Identifizierbare Pläne erhalten dieselbe Formel, Daten und Argumente
   wie zuvor. Die Prüfung verändert weder Antworten noch Zufallszustand,
   Varianzkomponenten, Optimierer oder Konvergenzdiagnosen.
7. `sim_implementation()` nimmt den neuen Rechenhelfer ausdrücklich in
   den Implementierungsnachweis auf. Die neun Kurzlaufdateien werden
   mit dem installierten aktuellen Paket und den bisherigen Seeds
   erzeugt. Vollläufe bleiben Betreiberarbeit.

## Prüfungen

Die neuen Unit-Tests verwenden eine unabhängig aufgebaute Rechnung mit
Beobachtungspaaren und dem Projektor X(XᵀX)⁻¹Xᵀ, Rangnachweise,
identische Partitionen sowie eine exakte lineare Kovarianzrelation ohne
identische Partitionen. Für gültige verschachtelte und gekreuzte Pläne
dienen direkte `clmm`- und `glmer`-Fits als Orakel. ANK-TOL liefert die
Vergleichstoleranzen. Erfolgreiches Fitten und der Abbruch vor dem
Engine-Aufruf sind ausdrückliche Erwartungen.

Zusätzliche neue Tests zu E27 prüfen explizite Labelreihenfolge,
zwei ordinale Kategorien und den erneut ausgewerteten gespeicherten
binären Aufruf. E28 wird in `NEWS.md` dokumentiert. Bestehende Unit-,
Abnahme- und QA-Tests bleiben unverändert.

Ausgeführte Befehle, echte Outputs und Infrastrukturgrenzen stehen in
`orchestrator/handoff/M1b/REWORK-NOTES.md` und `PROGRESS.md`.
