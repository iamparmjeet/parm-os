#!/bin/bash

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

  if parm_is_testing || (( PARM_DRY_RUN )); then
    parm_log "UKI generation skipped in fixture/dry-run mode"
    return
  fi

  command -v limine-mkinitcpio >/dev/null 2>&1 ||
    parm_die "limine-mkinitcpio is required"
  parm_run_root limine-mkinitcpio
  [[ -f /boot/EFI/Linux/parm_linux.efi ]] ||
    parm_die "Parm UKI was not generated"

  parm_run_root systemctl disable sddm.service
  parm_run_root systemctl unmask getty@tty1.service
  parm_run_root systemctl enable getty@tty1.service
}
