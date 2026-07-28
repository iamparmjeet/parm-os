#!/bin/bash

PARM_DRY_RUN=${PARM_DRY_RUN:-0}
PARM_VM_TEST=${PARM_VM_TEST:-0}
PARM_ASSUME_YES=${PARM_ASSUME_YES:-0}
PARM_JSON=${PARM_JSON:-0}
PARM_REMAINING_ARGS=()

parm_log() {
  printf '\033[32m==>\033[0m %s\n' "$*"
}

parm_warn() {
  printf '\033[33mWarning:\033[0m %s\n' "$*" >&2
}

parm_die() {
  printf '\033[31mError:\033[0m %s\n' "$*" >&2
  exit 1
}

parm_parse_global_options() {
  PARM_REMAINING_ARGS=()
  while (($#)); do
    case "$1" in
      --dry-run) PARM_DRY_RUN=1 ;;
      --vm-test) PARM_VM_TEST=1 ;;
      --yes|-y) PARM_ASSUME_YES=1 ;;
      --json) PARM_JSON=1 ;;
      *) PARM_REMAINING_ARGS+=("$1") ;;
    esac
    shift
  done
}

parm_is_testing() {
  [[ ${PARM_TESTING:-0} == 1 ]]
}

parm_target_root() {
  if parm_is_testing; then
    local root=${PARM_TEST_ROOT:-}
    [[ $root == /* ]] || parm_die "PARM_TEST_ROOT must be an absolute path"
    [[ $root != / && $root != /home && $root != /home/parm ]] ||
      parm_die "Refusing unsafe PARM_TEST_ROOT: $root"
    [[ -d $root ]] || parm_die "PARM_TEST_ROOT does not exist: $root"
    realpath -e -- "$root"
  else
    printf '/\n'
  fi
}

parm_root_path() {
  local path=$1
  local root
  root=$(parm_target_root)
  if [[ $root == / ]]; then
    printf '%s\n' "$path"
  else
    printf '%s%s\n' "$root" "$path"
  fi
}

parm_target_user() {
  if [[ -n ${PARM_TARGET_USER:-} ]]; then
    printf '%s\n' "$PARM_TARGET_USER"
  elif [[ -n ${SUDO_USER:-} && $SUDO_USER != root ]]; then
    printf '%s\n' "$SUDO_USER"
  else
    id -un
  fi
}

parm_target_home() {
  if parm_is_testing; then
    parm_root_path "/home/$(parm_target_user)"
  else
    getent passwd "$(parm_target_user)" | cut -d: -f6
  fi
}

parm_run() {
  if (( PARM_DRY_RUN )); then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

parm_run_root() {
  if parm_is_testing; then
    parm_run "$@"
  elif (( EUID == 0 )); then
    parm_run "$@"
  else
    parm_run sudo "$@"
  fi
}

parm_prepare_inspection_privileges() {
  if parm_is_testing || ((EUID == 0)); then
    return
  fi

  command -v sudo >/dev/null 2>&1 ||
    parm_die "sudo is required to validate protected boot files"
  sudo -v ||
    parm_die "sudo authentication is required to validate protected boot files"
}

parm_root_test() {
  local operator=$1
  local path=$2
  local target
  target=$(parm_root_path "$path")

  test "$operator" "$target" && return 0
  if ! parm_is_testing && ((EUID != 0)); then
    sudo -n test "$operator" "$target"
  else
    return 1
  fi
}

parm_install_root_file() {
  local source=$1
  local destination=$2
  local mode=${3:-0644}
  local target
  target=$(parm_root_path "$destination")
  parm_run_root install -D -m "$mode" "$source" "$target"
}

parm_write_root_file() {
  local destination=$1
  local mode=${2:-0644}
  local target temp
  target=$(parm_root_path "$destination")
  temp=$(mktemp)
  trap 'rm -f -- "$temp"' RETURN
  printf '%s' "$(cat)" >"$temp"
  parm_run_root install -D -m "$mode" "$temp" "$target"
  rm -f -- "$temp"
  trap - RETURN
}

parm_virtualization() {
  if parm_is_testing; then
    printf 'test-fixture\n'
    return
  fi
  systemd-detect-virt --vm 2>/dev/null || true
}

parm_require_vm_gate() {
  parm_is_testing && return 0

  [[ $PARM_VM_TEST == 1 ]] ||
    parm_die "Pre-release conversion requires --vm-test"

  local virt
  virt=$(parm_virtualization)
  [[ -n $virt && $virt != none ]] ||
    parm_die "Parm pre-release conversion is restricted to virtual machines"

  case "$virt" in
    kvm|qemu|oracle) ;;
    *) parm_die "Unsupported pre-release virtualization environment: $virt" ;;
  esac
}

parm_confirm_conversion() {
  (( PARM_DRY_RUN || PARM_ASSUME_YES )) && return 0
  local hostname_value response
  hostname_value=$(hostname)
  printf 'Parm will convert VM "%s". Type the hostname to continue: ' "$hostname_value" >/dev/tty
  IFS= read -r response </dev/tty
  [[ $response == "$hostname_value" ]] || parm_die "Confirmation did not match"
}

parm_require_commands() {
  local missing=()
  local command_name
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
  done
  ((${#missing[@]} == 0)) ||
    parm_die "Missing required commands: ${missing[*]}"
}

parm_atomic_json_write() {
  local destination=$1
  local content=$2
  local directory temp
  directory=$(dirname -- "$destination")
  mkdir -p -- "$directory"
  temp=$(mktemp --tmpdir="$directory" .parm-json.XXXXXX)
  printf '%s\n' "$content" >"$temp"
  jq empty "$temp"
  mv -f -- "$temp" "$destination"
}
