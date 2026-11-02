#!/usr/bin/env bash
# Gemeinsame Funktionen für ausgewählte Gate-Beispiele.

gate_load_config() {
  if [ -f "$ORCH/config.env" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ORCH/config.env"
    set +a
  fi
}

# ADR-041: Schlüssel eines Mutationsberichts aus Commit, Konfiguration und sortierten Dateien.
gate_mut_report_key() {
  printf '%s %s %s\n' "$(git -C "$REPO_ROOT" rev-parse HEAD)" \
    "$(sha256sum "$ORCH/config.env" | cut -d' ' -f1)" \
    "$(tr ',' '\n' <<<"$1" | LC_ALL=C sort | paste -sd, -)"
}

gate_run_configured() {
  local variable="$1" label="$2" command_value
  command_value="${!variable:-}"
  if [ -z "$command_value" ]; then
    echo "$label: Konfigurationsvariable $variable ist leer" >&2
    return 2
  fi
  local rc
  set +e
  bash -c "$command_value"
  rc=$?
  set -e
  if [ "$rc" = 0 ]; then
    echo "$label: Kommando erfolgreich"
    return 0
  fi
  local error_code error_codes="${GATE_ERROR_CODES:-126 127}"
  for error_code in $error_codes; do
    case "$error_code" in ''|*[!0-9]*) echo "$label: ungültiger GATE_ERROR_CODES-Eintrag: $error_code" >&2; return 2 ;; esac
    if [ "$rc" = "$error_code" ]; then
      echo "$label: Kommando-/Infrastrukturfehler rc=$rc" >&2
      return 2
    fi
  done
  echo "$label: Kommando meldet fachlichen Fehlschlag rc=$rc"
  return 1
}

gate_changed() {
  git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" -- "$@"
}
