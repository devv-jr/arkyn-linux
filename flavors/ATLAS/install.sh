#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '\n[ATLAS] %s\n' "$*"
}

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    printf '[ERROR] Run this script with sudo or as root.\n' >&2
    exit 1
  fi
}

install_packages() {
  log "Updating package lists"
  apt-get update

  log "Installing Plasma and SDDM"
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    kde-plasma-desktop \
    sddm \
    sddm-theme-breeze \
    plasma-nm \
    plasma-pa \
    dolphin \
    konsole \
    ark \
    kate \
    xdg-user-dirs
}

configure_layout() {
  log "ATLAS configuration skeleton"
  log "Plasma config: ${SCRIPT_DIR}/configs/plasma"
  log "SDDM config: ${SCRIPT_DIR}/configs/sddm"
  log "Theme assets: ${SCRIPT_DIR}/configs/theme"
}

enable_display_manager() {
  log "Enabling SDDM"
  systemctl enable sddm
}

main() {
  require_root
  install_packages
  configure_layout
  enable_display_manager
  log "ATLAS base installed"
}

main "$@"