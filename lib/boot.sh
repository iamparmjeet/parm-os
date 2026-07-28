#!/bin/bash

parm_boot_configure_limine_identity() {
  local config backup temp
  config=$(parm_root_path /etc/default/limine)
  backup=$(parm_root_path /etc/default/limine.parm-preconversion)

  [[ -f $config ]] ||
    parm_die "Limine configuration is missing: /etc/default/limine"

  if [[ ! -e $backup ]]; then
    parm_run_root cp -a -- "$config" "$backup"
  fi

  temp=$(mktemp)
  trap 'rm -f -- "$temp"' RETURN
  awk '
    /^[[:space:]]*(TARGET_OS_NAME|CUSTOM_UKI_NAME|ENABLE_UKI)[[:space:]]*=/ { next }
    { print }
    END {
      print ""
      print "# Managed by Parm after Omarchy conversion"
      print "TARGET_OS_NAME=\"Parm\""
      print "CUSTOM_UKI_NAME=\"parm\""
      print "ENABLE_UKI=yes"
    }
  ' "$config" >"$temp"
  parm_run_root install -m 0644 "$temp" "$config"
  rm -f -- "$temp"
  trap - RETURN
  parm_log "Configured highest-priority Limine identity for Parm"
}

parm_boot_stage() {
  local defaults
  defaults='TARGET_OS_NAME="Parm"
KERNEL_CMDLINE[default]+=" quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"
CUSTOM_UKI_NAME="parm"
ENABLE_UKI=yes
ENABLE_LIMINE_FALLBACK=yes
FIND_BOOTLOADERS=yes
BOOT_ORDER="*, *fallback, Snapshots"
MAX_SNAPSHOT_ENTRIES=5
SNAPSHOT_FORMAT_CHOICE=5
'
  printf '%s' "$defaults" |
    parm_write_root_file /etc/limine-entry-tool.d/parm-defaults.conf 0644

  local target_user getty_config
  target_user=$(parm_target_user)
  getty_config=$(printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin %s --noclear %%I $TERM\n' "$target_user")
  printf '%s' "$getty_config" |
    parm_write_root_file /etc/systemd/system/getty@tty1.service.d/autologin.conf 0644

  if ((PARM_DRY_RUN)); then
    parm_log "Limine identity change and UKI generation skipped in dry-run mode"
    return
  fi

  parm_boot_configure_limine_identity
  if parm_is_testing; then
    parm_log "UKI generation skipped in fixture mode"
    return
  fi

  command -v limine-mkinitcpio >/dev/null 2>&1 ||
    parm_die "limine-mkinitcpio is required"
  parm_run_root limine-mkinitcpio
  parm_root_test -s /boot/EFI/Linux/parm_linux.efi ||
    parm_die "Parm UKI was not generated"

  parm_run_root systemctl disable sddm.service
  parm_run_root systemctl unmask getty@tty1.service
  parm_run_root systemctl enable getty@tty1.service
}
