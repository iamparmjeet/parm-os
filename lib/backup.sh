#!/usr/bin/env bash

PARM_ACTIVE_BACKUP_DIR=""

parm_backup_start() {
  [[ -n $PARM_ACTIVE_BACKUP_DIR ]] && return
  local state_home backup_id
  state_home=$(parm_state_home)
  backup_id=$(date '+%Y%m%d-%H%M%S-%N')
  PARM_ACTIVE_BACKUP_DIR="$state_home/backups/$backup_id"

  if ((PARM_DRY_RUN)); then
    parm_log "would create backup $backup_id"
    return
  fi

  mkdir -p -- "$PARM_ACTIVE_BACKUP_DIR/files"
  {
    printf 'version=%s\n' "$(<"$PARM_CONFIG_ROOT/VERSION")"
    printf 'profile=%s\n' "${PARM_PROFILE:-}"
    printf 'created=%s\n' "$(date --iso-8601=seconds)"
  } >"$PARM_ACTIVE_BACKUP_DIR/info"
  : >"$PARM_ACTIVE_BACKUP_DIR/entries.tsv"
}

parm_backup_path() {
  local relative=$1 target_home target backup_target
  target_home=$(parm_target_home)
  target="$target_home/$relative"
  parm_backup_start

  if ((PARM_DRY_RUN)); then
    parm_log "would back up $relative"
    return
  fi

  backup_target="$PARM_ACTIVE_BACKUP_DIR/files/$relative"
  mkdir -p -- "$(dirname -- "$backup_target")"
  if [[ -e $target || -L $target ]]; then
    cp -a -- "$target" "$backup_target"
    printf 'present\t%s\n' "$relative" >>"$PARM_ACTIVE_BACKUP_DIR/entries.tsv"
  else
    printf 'missing\t%s\n' "$relative" >>"$PARM_ACTIVE_BACKUP_DIR/entries.tsv"
  fi
}

parm_backups() {
  local backup_root
  backup_root=$(parm_state_home)/backups
  [[ -d $backup_root ]] || {
    parm_log "no backups"
    return
  }
  find "$backup_root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r
}

parm_restore() {
  local backup_id=$1 backup_dir target_home state relative source target
  backup_dir="$(parm_state_home)/backups/$backup_id"
  [[ -f $backup_dir/entries.tsv ]] || parm_die "Backup not found: $backup_id"
  target_home=$(parm_target_home)

  if (( ! PARM_YES && ! PARM_DRY_RUN )); then
    [[ -t 0 ]] || parm_die "restore requires --yes when stdin is not interactive"
    read -r -p "Restore backup $backup_id? [y/N] " answer
    [[ $answer == y || $answer == Y ]] || parm_die "Restore cancelled"
  fi

  while IFS=$'\t' read -r state relative; do
    parm_validate_destination "$relative"
    target="$target_home/$relative"
    source="$backup_dir/files/$relative"
    if ((PARM_DRY_RUN)); then
      parm_log "would restore $relative ($state)"
      continue
    fi
    if [[ $state == missing ]]; then
      rm -f -- "$target"
    else
      mkdir -p -- "$(dirname -- "$target")"
      rm -f -- "$target"
      cp -a -- "$source" "$target"
    fi
  done <"$backup_dir/entries.tsv"

  parm_log "restored backup $backup_id"
}
