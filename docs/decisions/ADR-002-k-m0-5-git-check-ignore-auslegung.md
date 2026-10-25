# ADR-002 — K-M0-5: „leer“ und „nicht leer“ bei `git check-ignore`

## Status

Angenommen (Reviewer, M0 `30-plan-review` Runde 1; bindend ab Planfreigabe von M0). Offener Punkt ACC-2 in `orchestrator/handoff/M0/CRITERIA.json`.

## Kontext

- `docs/01-fachspezifikation.md` §10, K-M0-5: „`git check-ignore docs/00-vision.md` ist leer; `git check-ignore reference/quellen/probe.txt` ist nicht leer; … `git check-ignore reference/privat/probe.txt` ist nicht leer. (Prüfweg: Test)“
- Ohne `--no-index` meldet `git check-ignore` keine versionierten Pfade. `docs/00-vision.md` ist versioniert; die wörtliche Prüfung wäre also auch dann leer, wenn `.gitignore` `docs/` weiterhin ignorierte (BL-19). Sie könnte nie scheitern. Nach §2 Nr. 1 („Ein Test zählt erst, wenn er ein falsches Ergebnis erkennen würde.“) reicht das nicht.
- Exit-Status von `git check-ignore`: 0 = mindestens ein Pfad ignoriert, 1 = kein Pfad ignoriert, 128 = Fehler. Auch ein Fehler lässt stdout leer, deshalb darf „leer“ nicht allein aus leerem stdout geschlossen werden.
- Die Spec legt weder die Exit-Status fest noch den Umgang mit versionierten Pfaden.

## Entscheidung

1. „leer“ heißt Exit-Status 1 und keine Zeile auf stdout. „nicht leer“ heißt Exit-Status 0 und als stdout genau der abgefragte Pfad. Jeder andere Exit-Status (etwa 128) lässt den Test scheitern.
2. Für `docs/00-vision.md` bleibt der wörtliche Aufruf Pflicht. Zusätzlich muss `git check-ignore --no-index docs/00-vision.md` „leer“ sein: Damit werden die Ignore-Regeln selbst geprüft. `docs/` darf nach der pkgdown-Umstellung (§10, BL-19) nicht mehr ignoriert sein.
3. Die Probepfade werden nicht angelegt. `git check-ignore` bewertet den Pfadnamen und erfasst über die Regel des ignorierten Elternordners auch Pfade, die es nicht gibt.
4. Git läuft mit der Repo-Wurzel als Arbeitsverzeichnis (`git -C <wurzel>`). Damit gilt jede wirksame Ignore-Quelle: `.gitignore`, `.git/info/exclude` und `core.excludesFile`. Geprüft wird das tatsächlich wirksame Layout.

## Konsequenzen

- Tests: `tests/acceptance/test-m0-layout.R` setzt die Punkte 1 bis 4 bereits um. Das Kriterium wird nicht umgedeutet: Die wörtliche Form wird weiter geprüft, die Zusatzprüfung macht sie nur falsifizierbar.
- Zuständigkeit bei Rot: Eine falsche Ignore-Regel behebt der Betreiber (§10: „Die pkgdown-Umstellung … nimmt der Betreiber … vor“). Einen Fehler im Test behebt der Reviewer in `50-code-review`. Der Builder ist in beiden Fällen nicht zuständig. Ignoriert eine globale Ignore-Datei der Gate-Umgebung `docs/`, ist das ein `[INFRA]`-Befund.
- Restrisiko: In der ACCEPTANCE-Phase liefen die Git-Prüfungen nur gegen eine Attrappe. Der erste echte Lauf ist das Test-Gate von M0.
- Rücknahme oder Änderung nur durch ein neues ADR.
