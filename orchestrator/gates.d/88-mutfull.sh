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
