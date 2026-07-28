#!/bin/bash

parm_detect_quattro() {
  local shell_path
  for shell_path in \
    /usr/share/omarchy/shell/shell.qml \
    "$HOME/.local/share/omarchy/shell/shell.qml"; do
    [[ -f $shell_path ]] && return 0
  done

  if parm_is_testing; then
    [[ -f "$(parm_root_path /usr/share/omarchy/shell/shell.qml)" ]] && return 0
  fi
  return 1
}

parm_detect_bootloader() {
  [[ -f $(parm_root_path /boot/limine.conf) ]] && {
    printf 'limine\n'
    return
  }
  printf 'unknown\n'
}

parm_inspect_json() {
  local virt quattro bootloader btrfs arch
  virt=$(parm_virtualization)
  parm_detect_quattro && quattro=true || quattro=false
  bootloader=$(parm_detect_bootloader)
  [[ -f $(parm_root_path /etc/arch-release) ]] && arch=true || arch=false
  if parm_is_testing; then
    [[ -d $(parm_root_path /.snapshots) ]] && btrfs=true || btrfs=false
  else
    [[ $(findmnt -n -o FSTYPE / 2>/dev/null || true) == btrfs ]] && btrfs=true || btrfs=false
  fi

  jq -n \
    --arg virtualization "${virt:-none}" \
    --arg bootloader "$bootloader" \
    --argjson arch "$arch" \
    --argjson quattro "$quattro" \
    --argjson btrfs "$btrfs" \
    '{
      product: "Parm",
      prerelease: true,
      archLinux: $arch,
      omarchyQuattro: $quattro,
      btrfsRoot: $btrfs,
      bootloader: $bootloader,
      virtualization: $virtualization,
      compatible: ($arch and $quattro and ($virtualization != "none"))
    }'
}

parm_inspect() {
  local json=${1:-0}
  local report
  report=$(parm_inspect_json)
  if [[ $json == 1 ]]; then
    printf '%s\n' "$report"
    return
  fi

  printf 'Parm pre-release compatibility report\n\n'
  printf '  Arch Linux:       %s\n' "$(jq -r '.archLinux' <<<"$report")"
  printf '  Omarchy Quattro:  %s\n' "$(jq -r '.omarchyQuattro' <<<"$report")"
  printf '  Btrfs root:       %s\n' "$(jq -r '.btrfsRoot' <<<"$report")"
  printf '  Bootloader:       %s\n' "$(jq -r '.bootloader' <<<"$report")"
  printf '  Virtualization:   %s\n' "$(jq -r '.virtualization' <<<"$report")"
  printf '  Compatible:       %s\n' "$(jq -r '.compatible' <<<"$report")"
}

parm_assert_compatible() {
  local report
  report=$(parm_inspect_json)
  [[ $(jq -r '.archLinux' <<<"$report") == true ]] ||
    parm_die "Parm requires Arch Linux"
  [[ $(jq -r '.omarchyQuattro' <<<"$report") == true ]] ||
    parm_die "Parm requires Omarchy Quattro; legacy Omarchy is not supported"
  [[ $(jq -r '.bootloader' <<<"$report") == limine ]] ||
    parm_die "Parm pre-release requires Limine"
}
