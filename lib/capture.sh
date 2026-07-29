#!/usr/bin/env bash

parm_capture_portable() {
  local file=$1 relative=$2
  if rg -n '/home/[A-Za-z0-9._-]+' "$file" >/dev/null 2>&1; then
    parm_warn "absolute home path found in $relative"
    return 1
  fi
  return 0
}

parm_capture() {
  command -v rg >/dev/null 2>&1 || parm_die "ripgrep is required"
  local target_home entry id source relative mode capture generated live state temporary
  local blocked=0 changed=0
  target_home=$(parm_target_home)

  while IFS=$'\t' read -r id source relative mode capture generated; do
    [[ $capture == true && $generated == false ]] || continue
    source="$PARM_CONFIG_ROOT/$source"
    live="$target_home/$relative"
    [[ -f $live ]] || {
      parm_warn "live file is missing: $relative"
      blocked=1
      continue
    }
    cmp -s -- "$live" "$source" && continue
    changed=1
    printf '%-28s %s\n' "$id" "$relative"
    parm_capture_portable "$live" "$relative" || {
      blocked=1
      continue
    }
    ((PARM_WRITE)) || continue
    if ! git -C "$PARM_CONFIG_ROOT" diff --quiet -- "$source"; then
      ((PARM_FORCE)) ||
        parm_die "Repository file has uncommitted changes: $source"
    fi
    temporary=$(mktemp "$(dirname -- "$source")/.parm-capture.XXXXXX")
    install -m "$mode" -- "$live" "$temporary"
    mv -- "$temporary" "$source"
  done < <(parm_manifest_stream)

  ((changed)) || parm_log "all capturable files match"
  ((blocked == 0)) || parm_die "capture blocked by missing or non-portable files"
  if ((PARM_WRITE)); then
    parm_log "capture complete"
  fi
}
