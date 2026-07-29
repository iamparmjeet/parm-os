#!/usr/bin/env bash

parm_read_packages() {
  local file=$1
  [[ -f $file ]] || return 0
  sed -E '/^[[:space:]]*(#|$)/d' "$file"
}

parm_install_packages() {
  ((PARM_PACKAGES)) || return 0
  parm_require_omarchy_4

  local official=() aur=()
  mapfile -t official < <(parm_read_packages "$PARM_CONFIG_ROOT/packages/core-official.txt")
  mapfile -t aur < <(parm_read_packages "$PARM_CONFIG_ROOT/packages/core-aur.txt")

  if [[ ${PARM_PROFILE:-} == parm-laptop ]]; then
    mapfile -t -O "${#official[@]}" official \
      < <(parm_read_packages "$PARM_CONFIG_ROOT/packages/parm-laptop-official.txt")
    mapfile -t -O "${#aur[@]}" aur \
      < <(parm_read_packages "$PARM_CONFIG_ROOT/packages/parm-laptop-aur.txt")
  fi

  if ((PARM_DRY_RUN)); then
    if ((${#official[@]})); then
      parm_log "would install official packages: ${official[*]}"
    fi
    if ((${#aur[@]})); then
      parm_log "would install AUR packages: ${aur[*]}"
    fi
    return
  fi

  if ((${#official[@]})); then
    omarchy pkg add "${official[@]}"
  fi
  if ((${#aur[@]})); then
    omarchy pkg aur add "${aur[@]}"
  fi
}
