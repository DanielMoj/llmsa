<!-- projektierung_llmsa/gates-auswahl.md -->
# Gates-Auswahl

Typ-Grundsatz Software/R-Paket nach `PROJEKTIERUNG.md` und Preset `r-paket`. Sieben Gates aus dem Preset, dazu ein projektspezifisches Betreiber-Gate für den Mutationslauf über den Statistikkern (Entscheidung 24.10.2026, Frage 3). Jedes Gate trägt mindestens ein Kriterium; jedes Kriterium hat genau einen Prüfweg (Tabelle in Abschnitt 3).

## 1. Gewählte Gates

| Gate | Datei | Begründung | Prüfweg | Trägt |
| --- | --- | --- | --- | --- |
| deps | `10-deps.sh` (`DEPS_CMD='Rscript orchestrator/lib/r-deps.R'`) | Depends, Imports und Suggests aus `DESCRIPTION` müssen installiert sein, auch die Validierungssuite (VCA, irr, …); im Codex-Sandbox-Modus hat der Builder kein Netz, also installiert das Gate vorab | Exit 1 bei unerfüllter Anforderung, Versionen im Log | K-M0-1 (und Voraussetzung aller Tests) |
| lint | `20-lint.sh` (`LINT_CMD='bash orchestrator/lib/r-check.sh'`) | `R CMD build` + `R CMD check --as-cran --no-manual` außerhalb des Repos; ERROR oder WARNING ist `fail`; baut die Vignetten (validation, llm-stability, clinvar-raters) | Exit 1 bei ERROR/WARNING | K-M0-3, K-M1a-7, K-M1b-7, K-M1c-5, K-M1d-2, K-M1d-4, K-M1d-5 (Bauanteil) |
| tests | `30-tests.sh` (`TEST_CMD='Rscript orchestrator/lib/r-tests.R tests/testthat tests/acceptance tests/simulation tests/e2e tests/fuzz'`) | ein testthat-Lauf über alle Rollenordner plus `tests/simulation/` (Klasse A), Paket aus den Quellen geladen; jeder Abnahmetest trägt eine Kriteriums-ID | Exit 1 bei Fehlschlag oder Fehler; leere Ordner übersprungen | K-M0-2, K-M0-4, K-M0-5, K-M0-7 und alle Kriterien mit Prüfweg Test in 02–04 |
| trace | `70-trace.sh` (ohne `TRACE_CMD`) | `CRITERIA.json` muss jede Manifest-ID mit wörtlichem Spec-Zitat und Quelldatei führen, jede ID muss unter `tests/acceptance/` referenziert sein, jede dort gefundene ID bekannt sein | Exit 1 bei Waisen oder falschem Zitat | K-M0-6; Traceability aller Meilensteine (SPEC-KONTRAKT §3) |
| territory | `82-territory.sh` | der letzte Territoriums-Audit muss zu Runde und Basis passen; schützt `tests/acceptance/`, `reference/anchors/`, `orchestrator/**` vor dem Builder | Exit 1 bei Verstoß | K-M0-6; Gewaltenteilung aller Meilensteine |
| mutgate | `86-mutgate.sh` (`MUT_CMD='Rscript orchestrator/lib/r-mutation.R'`) | Mutation-Score der seit `plan/<MS>` geänderten Dateien im Scope; Scope in M0, M2 und M1a–M1d `R/fit.R` und `R/grr.R`, ab M3a alle `R/*.R`; Schwelle 80 % (`ANK-32`), Floor 80, Ratchet-Toleranz 2 | Exit 1 unter Schwelle; `pass` ohne geänderten Scope | K-M0-6 (leer), Prüfstandard Nr. 7 in M1a–M3d |
| golden-adr | `87-golden-adr.sh` (`GOLDEN_PATH_REGEX='^inst/extdata/'`) | Änderungen an eingefrorenen Daten (`inst/extdata/`) oder Ankern (`reference/anchors/`) verlangen ein ADR im selben Meilenstein | Exit 1 ohne ADR | K-M0-6; K-M1d-1, K-M1d-3, K-M2-1 (Datenänderungen), Ankerpflege 01 §6 |
| mutfull (projektspezifisch) | `88-mutfull.sh` (Betreiber, Abschnitt 4) | mutgate mutiert nur Diff-Dateien; der Prüfstandard verlangt einen Lauf über beide Kerndateien unabhängig vom Diff; nur in M1c fällig | Exit 1 unter `MUT_SCORE_MIN`; `pass (nicht fällig)` in anderen Meilensteinen | K-M1c-6 |

Nicht gewählt: smoke, graph, api, bench, e2e, shots, research, Text- und Datengates. Begründung: kein Server, keine Performance-Kriterien, kein sichtbarer Output; die API-Stabilität prüft der Snapshot-Abnahmetest (K-M0-7) statt eines api-Gates; QA schreibt e2e/fuzz-Tests, die das tests-Gate mitführt.

## 2. Konfiguration (`orchestrator/config.env`)

Preset-Block unverändert übernommen, Projektwerte darunter:

```sh
# Preset r-paket (geprüft 23.10.2026)
BUILDER_EXTRA_PATHS_REGEX='^(R/|man/|tests/testthat/|vignettes/|inst/|data/|data-raw/|DESCRIPTION$|NAMESPACE$|NEWS\.md$|\.Rbuildignore$)'
REVIEWER_EXTRA_PATHS_REGEX='^tests/simulation/'
QA_EXTRA_PATHS_REGEX=
REBUILD_PATHS='R tests/testthat'
DEPS_CMD='Rscript orchestrator/lib/r-deps.R'
TEST_CMD='Rscript orchestrator/lib/r-tests.R tests/testthat tests/acceptance tests/simulation tests/e2e tests/fuzz'
LINT_CMD='bash orchestrator/lib/r-check.sh'
MUT_CMD='Rscript orchestrator/lib/r-mutation.R'
MUT_REPORT=reports/mutation/mutation.json
GATE_ERROR_CODES='2 126 127'

# Projekt llmsa (Intake Abschnitt 5 und 8, Entscheidungen 24.10.2026)
PROJECT_SLUG=llmsa
AUTONOMY_LEVEL=0            # Vorgabe; höchstens 1 nach eigener Entscheidung. Kein Eingriff zwischen Phasen nötig: Klasse-B-Vollläufe liegen zwischen den Meilensteinen (01 §8)
MAX_ROUNDS_PLAN=2
MAX_ROUNDS_REWORK=5
REBUILD_ROUND=4
ARBITER_EXTRA_ROUNDS=2
PHASE_TIMEOUT=3600
WATCHDOG_STALE_SECONDS=4200
QA_ENABLED=0                # M0; ab M2: 1
QA_REQUIRED_FROM=M2
NOTIFY_ENABLED=1
NOTIFY_URL=https://ntfy.sh/<langer Zufalls-Topic>   # Topic wie ein Geheimnis behandeln
NOTIFY_TOPIC=llmsa
PUSH_REMOTE=0               # der Betreiber pusht nach jedem done/<MS>

# Mutationstests
MUT_SCOPE_REGEX='^R/(fit|grr)\.R$'   # M0, M2, M1a–M1d; ab M3a: '^R/.*\.R$' und orchestrator/state/mut-baseline zurücksetzen
MUT_SCORE_MIN=80
MUT_SCORE_FLOOR=80
MUT_RATCHET_TOL=2
MUT_WORKERS=14
MUT_TEST_DIRS='tests/testthat tests/acceptance tests/e2e tests/fuzz'   # ohne tests/simulation
MUTFULL_MILESTONES='M1c'
MUTFULL_FILES='R/fit.R,R/grr.R'

# Golden-Daten
GOLDEN_PATH_REGEX='^inst/extdata/'
```

Rollenkommandos nach `config.env.example` (Block „drei Anbieter“): Builder `codex exec -m gpt-6-astra -c model_reasoning_effort=max --sandbox workspace-write`, Reviewer und Schiedsrichter `claude -p --model claude-opus-5-5 --effort max --permission-mode acceptEdits --allowedTools "Bash(Rscript:*)"`, QA `gemini -m gemini-4-argon --approval-mode auto_edit --policy orchestrator/policies/qa-gemini.toml` (Ersatz Weg C: Kimi K3 über Qwen Code). `BUILDER_MODEL`, `REVIEWER_MODEL`, `QA_MODEL` sind nur Bezeichnungen.

Wechsel je Phase (Betreiber-Commits zwischen Meilensteinen):

| Zeitpunkt | Änderung |
| --- | --- |
| vor M2 (zweiter Meilenstein, direkt nach M0) | `QA_ENABLED=1`; Validierungsplan Anhang A freigegeben; API-Aufzeichnungen unter `tests/fixtures/api/` (BL-26); Zugänge und Ausgabelimits angelegt; `--store`-Pfad außerhalb des Repos |
| vor M1a | Formelsammlung gegen Quellen geprüft (erledigt 24.10.) |
| nach M1b | Vollläufe `ordinal_recovery`, `binary_recovery`, `two_level` mit den Builder-Skripten rechnen und `*_results.csv`, `*_replicates.csv`, `*_session.txt` committen (01 §8) |
| nach M1c, vor M1d | Volllauf `boot_coverage` rechnen (Nachtlauf, BL-12) und committen; erst dann M1d starten |
| vor M3a | `MUT_SCOPE_REGEX='^R/.*\.R$'`; `orchestrator/state/mut-baseline` entfernen oder zurücksetzen (BL-24) |
| nach M1d | `AUTONOMY_LEVEL` höchstens 1, wenn gewünscht |

## 3. Zuordnung Kriterium → Prüfweg (beidseitig)

| Prüfweg | Kriterien |
| --- | --- |
| Gate deps | K-M0-1 |
| Gate lint | K-M0-3; Bauanteil von K-M1a-7, K-M1b-7, K-M1c-5, K-M1d-2, K-M1d-4, K-M1d-5 |
| Gate tests (Abnahmetests, Klasse-A-Simulationen, Kurzläufe der Klasse B) | K-M0-2, K-M0-4, K-M0-5, K-M0-7; K-M1a-1 bis K-M1a-7; K-M1b-1 bis K-M1b-7; K-M1c-1 bis K-M1c-5; K-M1d-1 bis K-M1d-7; K-M2-1 bis K-M2-6; K-M3a-1 bis K-M3a-7; K-M3b-1 bis K-M3b-6; K-M3c-1 bis K-M3c-6; K-M3d-1 bis K-M3d-6 |
| Gate trace, territory, golden-adr, mutgate | K-M0-6 (Aggregat); Querschnitt aller Meilensteine |
| Gate mutfull | K-M1c-6 |
| Judge | keines; alle Kriterien sind maschinell entscheidbar |

Gate-Kriterien erhalten im Abnahmetest einen ID-Verweis (`skip("K-M0-3: decided by the lint gate")`), damit der Trace-Fallback die Zuordnung sieht.

## 4. Betreiber-Gate `orchestrator/gates.d/88-mutfull.sh`

```bash
#!/usr/bin/env bash
# Projektgate llmsa: Mutationslauf über feste Kerndateien, unabhängig vom Diff.
# Fällig nur in MUTFULL_MILESTONES (Vorgabe M1c); sonst pass. Zählung wie 86-mutgate
# (Killed und Timeout erkannt, RuntimeError nicht gezählt, Äquivalenz nur nach Reviewer-Approval).
set -euo pipefail
source "$ORCH/gates.d/_lib.sh"
gate_load_config

MUTFULL_MILESTONES="${MUTFULL_MILESTONES:-M1c}"
MUTFULL_FILES="${MUTFULL_FILES:-R/fit.R,R/grr.R}"
MUT_REPORT="${MUT_REPORT:-reports/mutation/mutation.json}"
MUT_SCORE_MIN="${MUT_SCORE_MIN:-80}"
APPROVED="$ORCH/handoff/$MILESTONE/MUT-EQUIV-APPROVED.json"

case " $MUTFULL_MILESTONES " in
  *" $MILESTONE "*) ;;
  *) echo "mutfull: pass (nicht fällig in $MILESTONE)"; exit 0 ;;
esac
[ -n "${MUT_CMD:-}" ] || { echo "mutfull: MUT_CMD ist leer" >&2; exit 2; }
IFS=',' read -r -a files <<<"$MUTFULL_FILES"
for f in "${files[@]}"; do
  [ -f "$REPO_ROOT/$f" ] || { echo "mutfull: Datei fehlt: $f" >&2; exit 2; }
done

score_from_report() {
  local approved_json='[]'
  [ ! -f "$APPROVED" ] || approved_json="$(jq -c '.approved // []' "$APPROVED" 2>/dev/null || echo '[]')"
  jq -r --argjson approved "$approved_json" '
    [ .files | to_entries[] as $file
      | $file.value.mutants[]
      | . + {sourceFile:$file.key} ] as $mutants
    | ([ $mutants[] | select(.status=="Killed" or .status=="Timeout") ] | length) as $detected
    | ([ $mutants[] | select(.status=="Survived" or .status=="NoCoverage") ]) as $survivors
    | ([ $survivors[] | select(. as $m | any($approved[]; . as $a
        | ($m.sourceFile | endswith($a.file))
        and ($m.mutatorName == $a.mutator)
        and ($m.location.start.line == $a.line))) ] | length) as $equivalent
    | (($survivors|length)-$equivalent) as $undetected
    | if ($detected+$undetected)==0 then 100
      else 100*$detected/($detected+$undetected) end
    | (. * 100 | round) / 100
  ' "$REPO_ROOT/$MUT_REPORT"
}

run_mutation() {
  rm -f "$REPO_ROOT/$MUT_REPORT"
  export MUT_FILES="$MUTFULL_FILES"
  set +e
  bash -c "$MUT_CMD"
  MUT_RC=$?
  set -e
  if [ ! -f "$REPO_ROOT/$MUT_REPORT" ]; then
    echo "mutfull: Werkzeug starb vor der Mutation (rc=$MUT_RC, Report fehlt: $MUT_REPORT)" >&2
    return 2
  fi
  SCORE="$(score_from_report 2>/dev/null)" || {
    echo "mutfull: Report ist nicht im erwarteten Stryker-Format" >&2
    return 2
  }
  # Jede verlangte Datei muss im Bericht mit mindestens einem Mutanten erscheinen.
  for f in "${files[@]}"; do
    n="$(jq -r --arg f "$f" '[.files | to_entries[] | select(.key | endswith($f)) | .value.mutants[]] | length' "$REPO_ROOT/$MUT_REPORT")"
    [ "${n:-0}" -gt 0 ] || { echo "mutfull: keine Mutanten für $f im Bericht" >&2; return 2; }
  done
  return 0
}

run_mutation || exit $?
FIRST_SCORE="$SCORE"
if ! awk -v score="$SCORE" -v required="$MUT_SCORE_MIN" 'BEGIN {exit !(score>=required)}'; then
  echo "mutfull: $SCORE < $MUT_SCORE_MIN; genau ein Flake-Rerun"
  run_mutation || exit $?
  SCORE="$(awk -v a="$FIRST_SCORE" -v b="$SCORE" 'BEGIN {printf "%.2f",(a>b)?a:b}')"
fi
if ! awk -v score="$SCORE" -v required="$MUT_SCORE_MIN" 'BEGIN {exit !(score>=required)}'; then
  echo "mutfull: fail (score=$SCORE required=$MUT_SCORE_MIN files=$MUTFULL_FILES)"
  exit 1
fi
cp "$REPO_ROOT/$MUT_REPORT" "$ORCH/state/$MILESTONE/mutfull-report.json" 2>/dev/null || true
echo "mutfull: pass (score=$SCORE required=$MUT_SCORE_MIN files=$MUTFULL_FILES)"
```

Hinweise: Das Gate läuft nach `86-mutgate` (Nummer 88) und benutzt denselben Adapter `orchestrator/lib/r-mutation.R` mit `MUT_WORKERS=14`; jeder Mutant führt die Testordner aus `MUT_TEST_DIRS` aus, deshalb bleibt `tests/simulation/` dort draußen. Es führt keine Baseline und keinen Ratchet, weil es genau einmal fällig ist. Der Bericht wird nach `orchestrator/state/M1c/mutfull-report.json` kopiert, damit der Reviewer ihn im Handoff zitieren kann. Betreiber-Territorium wie alle Gates; `git add --chmod=+x`.

## 5. Aktivierung (Schritt 5 der Startanleitung)

```bash
for gate in 10-deps 20-lint 30-tests 70-trace 82-territory 86-mutgate 87-golden-adr; do
  cp "orchestrator/gates.d/$gate.sh.example" "orchestrator/gates.d/$gate.sh"
  chmod +x "orchestrator/gates.d/$gate.sh"
  git add --chmod=+x "orchestrator/gates.d/$gate.sh"
done
# 88-mutfull.sh aus Abschnitt 4 anlegen, dann:
chmod +x orchestrator/gates.d/88-mutfull.sh && git add --chmod=+x orchestrator/gates.d/88-mutfull.sh
git ls-files -s orchestrator/gates.d/[0-9][0-9]-*.sh   # jede Zeile beginnt mit 100755
mkdir -p tests/acceptance tests/simulation tests/e2e tests/fuzz tests/fixtures && touch tests/simulation/.gitkeep tests/fixtures/.gitkeep
printf '%s\n' '^tests/simulation$' '^tests/fixtures$' >> .Rbuildignore
```

`orchestrator/artifact-paths.allowlist` um die Preset-Zeilen für `*.Rcheck/`, `<paket>_<version>.tar.gz`, `doc/`, `Meta/`, `pkgdown-site/` ergänzen; `reports/` ist schon enthalten.
