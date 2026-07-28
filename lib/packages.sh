#!/bin/bash

parm_read_package_manifest() {
  local manifest=$1
  sed -E '/^[[:space:]]*(#|$)/d' "$manifest"
}

parm_packages_install() {
  if parm_is_testing || (( PARM_DRY_RUN )); then
    parm_log "Package installation skipped in fixture/dry-run mode"
    return
  fi

  local official=() aur=()
  mapfile -t official < <(parm_read_package_manifest "$PARM_SOURCE_DIR/packages/official.txt")
  mapfile -t aur < <(parm_read_package_manifest "$PARM_SOURCE_DIR/packages/aur.txt")

  parm_run_root pacman -S --needed --noconfirm "${official[@]}"
  if ((${#aur[@]})); then
    command -v yay >/dev/null 2>&1 || parm_die "yay is required for AUR dependencies"
    parm_run sudo -u "$(parm_target_user)" yay -S --needed --noconfirm "${aur[@]}"
  fi

  local retained=()
  mapfile -t retained < <(parm_read_package_manifest "$PARM_SOURCE_DIR/packages/retain.txt")
  local installed=() package_name
  for package_name in "${retained[@]}"; do
    pacman -Q "$package_name" >/dev/null 2>&1 && installed+=("$package_name")
  done
  ((${#installed[@]})) &&
    parm_run_root pacman -D --asexplicit "${installed[@]}"
}
