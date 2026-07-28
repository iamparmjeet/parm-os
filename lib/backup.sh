#!/bin/bash

parm_backup_create() {
  local label=${1:-manual}
  local target_home state_dir stamp backup_dir
  target_home=$(parm_target_home)
  state_dir="$target_home/.local/state/parm/backups"
  stamp=$(date +%Y%m%d-%H%M%S)
  backup_dir="$state_dir/$stamp-$label"

  parm_run mkdir -p -- "$backup_dir"

  if ! parm_is_testing && command -v snapper >/dev/null 2>&1; then
    parm_run_root snapper -c root create -c number -d "Parm $label"
  fi

  local source archive
  local sources=(
    .config/hypr
    .config/omarchy
    .config/uwsm
    .config/alacritty
    .config/foot
    .config/kdeglobals
    .config/qt6ct
    .config/mise
    .local/state/omarchy
    .local/share/applications
    .zshrc
    .zprofile
  )
  archive="$backup_dir/user-config.tar.zst"
  local existing=()
  for source in "${sources[@]}"; do
    [[ -e $target_home/$source ]] && existing+=("$source")
  done
  if ((${#existing[@]})); then
    parm_run tar --zstd -C "$target_home" -cf "$archive" "${existing[@]}"
  fi

  if ((PARM_DRY_RUN)); then
    if ! parm_is_testing; then
      printf 'DRY-RUN: pacman -Qqe > %q\n' "$backup_dir/packages-explicit.txt"
      printf 'DRY-RUN: pacman -Qq > %q\n' "$backup_dir/packages-all.txt"
    fi
    parm_log "Backup planned: $backup_dir"
    return
  fi

  if ! parm_is_testing; then
    pacman -Qqe >"$backup_dir/packages-explicit.txt"
    pacman -Qq >"$backup_dir/packages-all.txt"
  fi

  (
    cd -- "$backup_dir"
    find . -type f ! -name SHA256SUMS -print0 |
      sort -z |
      xargs -0 -r sha256sum >SHA256SUMS
  )
  parm_log "Backup created: $backup_dir"
}
