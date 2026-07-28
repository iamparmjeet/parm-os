#!/bin/bash

# shellcheck source=lib/packages.sh
source "$PARM_SOURCE_DIR/lib/packages.sh"
# shellcheck source=lib/backup.sh
source "$PARM_SOURCE_DIR/lib/backup.sh"
# shellcheck source=lib/boot.sh
source "$PARM_SOURCE_DIR/lib/boot.sh"

parm_install_product_files() {
  local relative destination
  local files=(
    VERSION
    LICENSE
    LICENSES/OMARCHY
    bin/parmctl
    config/config.schema.json
    config/default.json
    config/hypr/default.lua
    config/hypr/helpers.lua
    config/hypr/hyprland.lua
    config/hypr/hypridle.conf
    config/hypr/hyprlock.conf
    config/hypr/overrides.lua
    config/uwsm/env
    config/uwsm/default
    packages/official.txt
    packages/aur.txt
    packages/retain.txt
    packages/remove.txt
    shell/shell.qml
    settings/settings.qml
    themes/matugen/config.toml
    themes/apply
    migrations/omarchy-quattro/import
    system/health-check
    system/finalize
    system/parm-health.service
    system/parm-finalize.service
    assets/logo/parm-mark.svg
    assets/logo/parm-wordmark.svg
  )

  for relative in "${files[@]}"; do
    [[ -f $PARM_SOURCE_DIR/$relative ]] ||
      parm_die "Product file is missing: $relative"
    destination="/usr/share/parm/$relative"
    case "$relative" in
      bin/*|themes/apply|migrations/*/import|system/health-check|system/finalize)
        parm_install_root_file "$PARM_SOURCE_DIR/$relative" "$destination" 0755
        ;;
      *)
        parm_install_root_file "$PARM_SOURCE_DIR/$relative" "$destination" 0644
        ;;
    esac
  done

  parm_install_root_file "$PARM_SOURCE_DIR/bin/parmctl" /usr/bin/parmctl 0755
  parm_install_root_file "$PARM_SOURCE_DIR/system/parm-health.service" \
    /usr/lib/systemd/user/parm-health.service 0644
  parm_install_root_file "$PARM_SOURCE_DIR/system/parm-finalize.service" \
    /etc/systemd/system/parm-finalize.service 0644
}

parm_install_user_config() {
  local target_user target_home config_dir
  target_user=$(parm_target_user)
  target_home=$(parm_target_home)
  config_dir="$target_home/.config/parm"

  parm_run mkdir -p -- "$config_dir/hypr" "$target_home/.local/state/parm"
  if [[ ! -f $config_dir/config.json ]]; then
    parm_run install -m 0644 "$PARM_SOURCE_DIR/config/default.json" \
      "$config_dir/config.json"
  fi
  if [[ ! -f $config_dir/hypr/overrides.lua ]]; then
    parm_run install -m 0644 "$PARM_SOURCE_DIR/config/hypr/overrides.lua" \
      "$config_dir/hypr/overrides.lua"
  fi

  parm_run env \
    PARM_SOURCE_DIR="$PARM_SOURCE_DIR" \
    PARM_TARGET_HOME="$target_home" \
    "$PARM_SOURCE_DIR/migrations/omarchy-quattro/import"

  if ((PARM_DRY_RUN)); then
    parm_log "Wallpaper discovery and application skipped in dry-run mode"
    return
  fi

  local wallpaper
  wallpaper=$(jq -r '.appearance.wallpaper' "$config_dir/config.json")
  if ! parm_is_testing && [[ -f $wallpaper ]]; then
    parm_run sudo -u "$target_user" env \
      HOME="$target_home" \
      PARM_CONFIG="$config_dir/config.json" \
      "$PARM_SOURCE_DIR/themes/apply" dark
  fi

  if ! parm_is_testing && (( EUID == 0 )); then
    chown -R "$target_user:$target_user" "$config_dir" "$target_home/.local/state/parm"
  fi
}

parm_install_system_units() {
  local target_user target_uid env_content
  target_user=$(parm_target_user)
  target_uid=$(id -u "$target_user" 2>/dev/null || printf '1000')
  env_content=$(printf 'PARM_TARGET_USER=%q\nPARM_TARGET_UID=%q\nPARM_TARGET_HOME=%q\n' \
    "$target_user" "$target_uid" "$(parm_target_home)")
  printf '%s' "$env_content" | parm_write_root_file /etc/parm/install.env 0644

  if parm_is_testing; then
    return
  fi

  parm_run_root systemctl daemon-reload
  parm_run systemctl --user daemon-reload
  parm_run systemctl --user enable parm-health.service
  parm_run_root systemctl enable parm-finalize.service
}

parm_write_install_manifest() {
  local target manifest version
  target=$(parm_root_path /var/lib/parm/install-manifest.json)
  version=$(<"$PARM_SOURCE_DIR/VERSION")
  manifest=$(jq -n \
    --arg version "$version" \
    --arg installedAt "$(date --iso-8601=seconds)" \
    --arg source "$PARM_SOURCE_DIR" \
    '{schemaVersion:1, version:$version, installedAt:$installedAt, source:$source}')
  if ((PARM_DRY_RUN)); then
    printf '%s\n' "$manifest" |
      parm_write_root_file /var/lib/parm/install-manifest.json 0644
  elif parm_is_testing; then
    mkdir -p -- "$(dirname -- "$target")"
    parm_atomic_json_write "$target" "$manifest"
  else
    printf '%s\n' "$manifest" | parm_write_root_file /var/lib/parm/install-manifest.json 0644
  fi
}

parm_install_stage() {
  parm_require_commands jq rsync tar sha256sum
  parm_assert_compatible
  parm_backup_create "pre-conversion"
  parm_packages_install
  parm_install_product_files
  parm_install_user_config
  parm_boot_stage
  parm_install_system_units
  parm_write_install_manifest
  printf 'staged\n' | parm_write_root_file /var/lib/parm/conversion-phase 0644
  parm_log "Parm staging completed successfully"
}

parm_update() {
  local version=${1:-latest}
  parm_warn "Signed release updates are disabled in development build $version"
  parm_repair
}

parm_repair() {
  parm_log "Validating product files"
  local file missing=0
  for file in setup bin/parmctl config/config.schema.json config/default.json; do
    if [[ ! -f $PARM_SOURCE_DIR/$file ]]; then
      parm_warn "Missing source file: $file"
      missing=1
    fi
  done
  (( missing == 0 )) || parm_die "Repair validation failed"
  jq empty "$PARM_SOURCE_DIR/config/default.json"
  parm_require_vm_gate
  parm_backup_create "pre-repair"
  parm_install_product_files
  parm_install_user_config
  parm_install_system_units

  if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] &&
    command -v quickshell >/dev/null 2>&1; then
    parm_run "$PARM_SOURCE_DIR/bin/parmctl" shell restart
  fi

  parm_log "Parm-owned files and session startup were repaired"
}

parm_uninstall() {
  parm_require_vm_gate
  parm_backup_create "pre-uninstall"
  parm_die "Development uninstall intentionally stops after backup; restore is manual"
}
