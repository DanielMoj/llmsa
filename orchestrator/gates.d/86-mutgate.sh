#!/usr/bin/env bash
# Mutation-Ratchet v2: Pre-Mutation-Tod=error, roter unmutierter Vorlauf=fail ohne Flake-Rerun,
# Flake-Rerun nur bis MUT_FLAKE_MARGIN Punkte unter der Schwelle, Äquivalenz nur nach Reviewer-Approval.
set -euo pipefail
source "$ORCH/gates.d/_lib.sh"
gate_load_config

MUT_SCOPE_REGEX="${MUT_SCOPE_REGEX:-^src/.*\.(ts|js|py)$}"
MUT_REPORT="${MUT_REPORT:-reports/mutation/mutation.json}"
# Rote Tests des unmutierten Vorlaufs; MUT_CMD schreibt sie neben MUT_REPORT und endet mit rc=3.
MUT_UNMUTATED="$(dirname "$MUT_REPORT")/unmutated.json"
# ADR-041: Schlüssel neben dem Bericht; 88-mutfull übernimmt ihn nur bei gleichem Schlüssel.
MUT_REPORT_KEY="$REPO_ROOT/$(dirname "$MUT_REPORT")/report.key"
MUT_SCORE_MIN="${MUT_SCORE_MIN:-65}"
MUT_SCORE_FLOOR="${MUT_SCORE_FLOOR:-50}"
MUT_RATCHET_TOL="${MUT_RATCHET_TOL:-2}"
# Höchster Abstand des ersten Scores zur Schwelle, bei dem noch genau ein Flake-Rerun läuft.
MUT_FLAKE_MARGIN="${MUT_FLAKE_MARGIN:-5}"
BASELINE_FILE="$ORCH/state/mut-baseline"
APPROVED="$ORCH/handoff/$MILESTONE/MUT-EQUIV-APPROVED.json"

CHANGED="$(git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" | grep -E -- "$MUT_SCOPE_REGEX" | paste -sd, - || true)"
if [ -z "$CHANGED" ]; then
  echo "mutgate: pass (kein geänderter Mutations-Scope)"
  exit 0
fi
[ -n "${MUT_CMD:-}" ] || { echo "mutgate: MUT_CMD ist leer" >&2; exit 2; }
[[ "$MUT_FLAKE_MARGIN" =~ ^[0-9]+([.][0-9]+)?$ ]] \
  || { echo "mutgate: MUT_FLAKE_MARGIN muss eine Zahl ab 0 sein: $MUT_FLAKE_MARGIN" >&2; exit 2; }

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

red_tests_from_report() {
  jq -er '
    if (.tests | length) > 0 then
      "\(.tests | length) Tests: " + ([ .tests[] | "\(.file): \(.test) [\(.status)]" ] | join(" | "))
    else empty end
  ' "$REPO_ROOT/$MUT_UNMUTATED"
}

run_mutation() {
  rm -f "$REPO_ROOT/$MUT_REPORT" "$REPO_ROOT/$MUT_UNMUTATED" "$MUT_REPORT_KEY"
  export MUT_FILES="$CHANGED"
  set +e
  bash -c "$MUT_CMD"
  MUT_RC=$?
  set -e
  # Über einem roten Vorlauf zählte jeder Mutant als entdeckt; deshalb fail und kein Flake-Rerun.
  if [ "$MUT_RC" = 3 ]; then
    if RED="$(red_tests_from_report 2>/dev/null)"; then
      echo "mutgate: fail (unmutierter Vorlauf rot, kein Mutant gelaufen; $RED)"
      return 1
    fi
    echo "mutgate: Vorlauf rot gemeldet (rc=3), aber $MUT_UNMUTATED fehlt oder nennt keinen Test" >&2
    return 2
  fi
  if [ ! -f "$REPO_ROOT/$MUT_REPORT" ]; then
    echo "mutgate: Werkzeug starb vor der Mutation (rc=$MUT_RC, Report fehlt: $MUT_REPORT)" >&2
    return 2
  fi
  SCORE="$(score_from_report 2>/dev/null)" || {
    echo "mutgate: Report ist nicht im erwarteten Stryker-Format" >&2
    return 2
  }
  gate_mut_report_key "$CHANGED" > "$MUT_REPORT_KEY"
  return 0
}

if [ -f "$BASELINE_FILE" ]; then
  BASELINE="$(cat "$BASELINE_FILE")"
  REQUIRED="$(awk -v b="$BASELINE" -v f="$MUT_SCORE_FLOOR" -v t="$MUT_RATCHET_TOL" 'BEGIN {r=b-t; if(r<f)r=f; printf "%.2f",r}')"
else
  BASELINE="n/a"
  REQUIRED="$MUT_SCORE_MIN"
fi

run_mutation || exit $?
FIRST_SCORE="$SCORE"
if ! awk -v score="$SCORE" -v required="$REQUIRED" 'BEGIN {exit !(score>=required)}'; then
  GAP="$(awk -v score="$SCORE" -v required="$REQUIRED" 'BEGIN {printf "%.2f",required-score}')"
  # Der Rerun fängt Schwankungen von ein bis zwei Punkten ab; weiter unter der Schwelle kostet er
  # einen vollen Durchgang und kann das Ergebnis nicht drehen.
  if ! awk -v gap="$GAP" -v margin="$MUT_FLAKE_MARGIN" 'BEGIN {exit !(gap<=margin)}'; then
    echo "mutgate: fail (score=$SCORE required=$REQUIRED baseline=$BASELINE floor=$MUT_SCORE_FLOOR; $GAP Punkte unter der Schwelle, mehr als MUT_FLAKE_MARGIN=$MUT_FLAKE_MARGIN, ohne Flake-Rerun)"
    exit 1
  fi
  echo "mutgate: $SCORE < $REQUIRED ($GAP Punkte darunter, höchstens MUT_FLAKE_MARGIN=$MUT_FLAKE_MARGIN); genau ein Flake-Rerun"
  run_mutation || exit $?
  SCORE="$(awk -v a="$FIRST_SCORE" -v b="$SCORE" 'BEGIN {printf "%.2f",(a>b)?a:b}')"
fi

if ! awk -v score="$SCORE" -v required="$REQUIRED" 'BEGIN {exit !(score>=required)}'; then
  echo "mutgate: fail (score=$SCORE required=$REQUIRED baseline=$BASELINE floor=$MUT_SCORE_FLOOR)"
  exit 1
fi

if [ ! -f "$BASELINE_FILE" ] || awk -v score="$SCORE" -v baseline="$(cat "$BASELINE_FILE" 2>/dev/null || echo -1)" 'BEGIN {exit !(score>baseline)}'; then
  printf '%s\n' "$SCORE" > "$BASELINE_FILE"
fi
echo "mutgate: pass (score=$SCORE required=$REQUIRED baseline=$(cat "$BASELINE_FILE") floor=$MUT_SCORE_FLOOR)"
