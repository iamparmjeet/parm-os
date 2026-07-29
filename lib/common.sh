#!/usr/bin/env bash

parm_log() {
  printf 'parm-config: %s\n' "$*"
}

parm_warn() {
  printf 'parm-config: warning: %s\n' "$*" >&2
}

parm_die() {
  printf 'parm-config: error: %s\n' "$*" >&2
  exit 1
}

parm_target_home() {
  printf '%s\n' "${PARM_CONFIG_HOME:-$HOME}"
}

parm_state_home() {
  local target_home
  target_home=$(parm_target_home)
  printf '%s\n' "${PARM_CONFIG_STATE_HOME:-${XDG_STATE_HOME:-$target_home/.local/state}/parm-config}"
}

parm_validate_profile() {
  case "${PARM_PROFILE:-}" in
    ""|parm-laptop) ;;
    *) parm_die "Unknown profile: $PARM_PROFILE" ;;
  esac
}

parm_validate_destination() {
  local destination=$1
  [[ -n $destination && $destination != /* ]] ||
    parm_die "Manifest destination must be home-relative: $destination"
  case "/$destination/" in
    */../*) parm_die "Manifest destination contains '..': $destination" ;;
  esac
}

parm_manifest_stream() {
  jq -r '.entries[] | [.id,.source,.destination,.mode,(.capture|tostring),(.generated|tostring)] | @tsv' \
    "$PARM_CONFIG_ROOT/config/manifest.json"

  if [[ ${PARM_PROFILE:-} == parm-laptop ]]; then
    jq -r '.entries[] | [.id,.source,.destination,.mode,(.capture|tostring),(.generated|tostring)] | @tsv' \
      "$PARM_CONFIG_ROOT/profiles/parm-laptop/manifest.json"
  fi
}

parm_require_omarchy_4() {
  [[ ${PARM_CONFIG_SKIP_OMARCHY_CHECK:-0} == 1 ]] && return
  command -v omarchy >/dev/null 2>&1 || parm_die "Omarchy is required"
  local version
  version=$(omarchy version 2>/dev/null) || parm_die "Unable to read the Omarchy version"
  [[ $version == 4.* ]] ||
    parm_die "Omarchy 4.x is required; found: $version"
}

parm_file_state() {
  local source=$1 destination=$2 expected_mode=$3
  if [[ ! -f $source ]]; then
    printf 'blocked\n'
  elif [[ -L $destination ]]; then
    printf 'unexpected-symlink\n'
  elif [[ ! -e $destination ]]; then
    printf 'missing\n'
  elif [[ ! -f $destination ]] || ! cmp -s -- "$source" "$destination"; then
    printf 'modified\n'
  elif [[ $(stat -c '%a' "$destination") != "${expected_mode#0}" ]]; then
    printf 'wrong-mode\n'
  else
    printf 'matching\n'
  fi
}

parm_status() {
  command -v jq >/dev/null 2>&1 || parm_die "jq is required"
  local target_home source destination mode state
  local rows=()
  target_home=$(parm_target_home)

  while IFS=$'\t' read -r id source destination mode capture generated; do
    parm_validate_destination "$destination"
    source="$PARM_CONFIG_ROOT/$source"
    state=$(parm_file_state "$source" "$target_home/$destination" "$mode")
    rows+=("$id"$'\t'"$destination"$'\t'"$state")
  done < <(parm_manifest_stream)

  if ((PARM_JSON)); then
    printf '%s\n' "${rows[@]}" |
      jq -Rn '[inputs | split("\t") | {id:.[0], destination:.[1], state:.[2]}]'
  else
    printf '%-28s %-20s %s\n' "ID" "STATE" "DESTINATION"
    local row id destination state
    for row in "${rows[@]}"; do
      IFS=$'\t' read -r id destination state <<<"$row"
      printf '%-28s %-20s %s\n' "$id" "$state" "$destination"
    done
  fi
}
