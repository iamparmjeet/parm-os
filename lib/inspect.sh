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
  local config_path
  for config_path in \
    /boot/limine.conf \
    /boot/EFI/limine/limine.conf \
    /boot/EFI/Limine/limine.conf; do
    parm_root_test -f "$config_path" && {
      printf 'limine\n'
      return
    }
  done
  printf 'unknown\n'
}

parm_limine_efi_present() {
  local efi_path
  for efi_path in \
    /boot/EFI/limine/limine_x64.efi \
    /boot/EFI/Limine/limine_x64.efi; do
    parm_root_test -s "$efi_path" && return 0
  done
  return 1
}

parm_detect_firmware() {
  [[ -d $(parm_root_path /sys/firmware/efi) ]] && {
    printf 'uefi\n'
    return
  }
  printf 'bios\n'
}

parm_boot_mounted() {
  if parm_is_testing; then
    [[ -d $(parm_root_path /boot) ]]
  else
    findmnt -n --mountpoint /boot >/dev/null 2>&1
  fi
}

parm_inspect_json() {
  local virt quattro bootloader limine_efi firmware boot_mounted btrfs arch
  virt=$(parm_virtualization)
  parm_detect_quattro && quattro=true || quattro=false
  bootloader=$(parm_detect_bootloader)
  parm_limine_efi_present && limine_efi=true || limine_efi=false
  firmware=$(parm_detect_firmware)
  parm_boot_mounted && boot_mounted=true || boot_mounted=false
  [[ -f $(parm_root_path /etc/arch-release) ]] && arch=true || arch=false
  if parm_is_testing; then
    [[ -d $(parm_root_path /.snapshots) ]] && btrfs=true || btrfs=false
  else
    [[ $(findmnt -n -o FSTYPE / 2>/dev/null || true) == btrfs ]] && btrfs=true || btrfs=false
  fi

  jq -n \
    --arg virtualization "${virt:-none}" \
    --arg bootloader "$bootloader" \
    --arg firmware "$firmware" \
    --argjson limineEfi "$limine_efi" \
    --argjson bootMounted "$boot_mounted" \
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
      limineEfi: $limineEfi,
      firmware: $firmware,
      bootMounted: $bootMounted,
      virtualization: $virtualization,
      compatible: (
        $arch and
        $quattro and
        $btrfs and
        ($bootloader == "limine") and
        $limineEfi and
        ($firmware == "uefi") and
        $bootMounted and
        ($virtualization != "none")
      )
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
  printf '  Limine EFI:       %s\n' "$(jq -r '.limineEfi' <<<"$report")"
  printf '  Firmware:         %s\n' "$(jq -r '.firmware' <<<"$report")"
  printf '  /boot mounted:    %s\n' "$(jq -r '.bootMounted' <<<"$report")"
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
  [[ $(jq -r '.firmware' <<<"$report") == uefi ]] ||
    parm_die "Parm requires UEFI firmware; this VM booted in legacy BIOS mode"
  [[ $(jq -r '.bootMounted' <<<"$report") == true ]] ||
    parm_die "Parm requires the EFI system partition to be mounted at /boot"
  [[ $(jq -r '.btrfsRoot' <<<"$report") == true ]] ||
    parm_die "Parm requires a Btrfs root filesystem"
  [[ $(jq -r '.bootloader' <<<"$report") == limine ]] ||
    parm_die "Parm requires a Limine configuration on the mounted EFI system partition"
  [[ $(jq -r '.limineEfi' <<<"$report") == true ]] ||
    parm_die "Parm requires the Limine EFI executable on the mounted EFI system partition"
}
