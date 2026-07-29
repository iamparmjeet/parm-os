#!/usr/bin/env bash

parm_profile_preflight() {
  [[ ${PARM_PROFILE:-} == parm-laptop ]] || return 0
  [[ ${PARM_CONFIG_SKIP_PROFILE_CHECK:-0} == 1 ]] && return 0

  local monitors
  monitors=$(hyprctl monitors all -j 2>/dev/null || true)
  if ! jq -e '
    any(.[]; .name == "HDMI-A-1") and
    any(.[]; .name == "eDP-1")
  ' >/dev/null 2>&1 <<<"$monitors"; then
    ((PARM_FORCE)) ||
      parm_die "parm-laptop expects HDMI-A-1 and eDP-1; use --force to apply anyway"
    parm_warn "Expected profile monitors were not both detected"
  fi
}

parm_install_file() {
  local source=$1 relative=$2 mode=$3
  local target_home target temporary
  target_home=$(parm_target_home)
  target="$target_home/$relative"

  if ((PARM_DRY_RUN)); then
    parm_log "would install $relative"
    return
  fi

  mkdir -p -- "$(dirname -- "$target")"
  temporary=$(mktemp "$(dirname -- "$target")/.parm-config.XXXXXX")
  install -m "$mode" -- "$source" "$temporary"
  rm -f -- "$target"
  mv -- "$temporary" "$target"
}

parm_retire_legacy() {
  ((PARM_FORCE)) || return 0
  local target_home expected relative target actual
  target_home=$(parm_target_home)
  while IFS=$'\t' read -r expected relative; do
    [[ -n $expected && ${expected:0:1} != "#" ]] || continue
    target="$target_home/$relative"
    [[ -f $target ]] || continue
    actual=$(sha256sum "$target" | awk '{print $1}')
    if [[ $actual != "$expected" ]]; then
      parm_warn "leaving edited legacy file untouched: $relative"
      continue
    fi
    parm_backup_path "$relative"
    if ((PARM_DRY_RUN)); then
      parm_log "would retire legacy file $relative"
    else
      rm -f -- "$target"
      parm_log "retired legacy file $relative"
    fi
  done <"$PARM_CONFIG_ROOT/config/retired-v1.tsv"
}

parm_install() {
  command -v jq >/dev/null 2>&1 || parm_die "jq is required"
  parm_require_omarchy_4
  parm_profile_preflight

  local target_home source relative mode state
  local entries=() conflicts=()
  target_home=$(parm_target_home)
  mapfile -t entries < <(parm_manifest_stream)

  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r id source relative mode capture generated <<<"$entry"
    parm_validate_destination "$relative"
    source="$PARM_CONFIG_ROOT/$source"
    state=$(parm_file_state "$source" "$target_home/$relative" "$mode")
    [[ $state != blocked ]] || parm_die "Repository source is missing: $source"
    case "$state" in
      matching|missing) ;;
      *) conflicts+=("$relative ($state)") ;;
    esac
  done

  if ((${#conflicts[@]})) && (( ! PARM_FORCE )); then
    printf 'Conflicting files:\n' >&2
    printf '  %s\n' "${conflicts[@]}" >&2
    parm_die "No files changed; rerun with --force to back up and replace them"
  fi

  parm_install_packages

  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r id source relative mode capture generated <<<"$entry"
    source="$PARM_CONFIG_ROOT/$source"
    state=$(parm_file_state "$source" "$target_home/$relative" "$mode")
    [[ $state == matching ]] && continue
    parm_backup_path "$relative"
    parm_install_file "$source" "$relative" "$mode"
  done

  parm_retire_legacy

  if ((PARM_DRY_RUN)); then
    parm_log "dry-run complete"
    return
  fi

  if [[ $target_home == "$HOME" && -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
    omarchy plugin rescan >/dev/null
  fi

  parm_log "installation complete"
  if [[ -n $PARM_ACTIVE_BACKUP_DIR ]]; then
    parm_log "backup: $(basename -- "$PARM_ACTIVE_BACKUP_DIR")"
  fi
}
