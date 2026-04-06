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

install_plasma_defaults() {
  log "Installing Plasma defaults"
  install -d /etc/skel/.config
  install -Dm644 "${SCRIPT_DIR}/configs/plasma/kdeglobals" /etc/skel/.config/kdeglobals
  install -Dm644 "${SCRIPT_DIR}/configs/plasma/kwinrc" /etc/skel/.config/kwinrc
  install -Dm644 "${SCRIPT_DIR}/configs/plasma/kscreenlockerrc" /etc/skel/.config/kscreenlockerrc
}

install_sddm_config() {
  log "Installing SDDM config"
  install -d /etc/sddm.conf.d
  install -Dm644 "${SCRIPT_DIR}/configs/sddm/sddm.conf" /etc/sddm.conf.d/90-atlas.conf
}

install_theme_assets() {
  log "Installing ATLAS color scheme"
  install -d /usr/share/color-schemes
  install -Dm644 "${SCRIPT_DIR}/configs/theme/ATLAS.colors" /usr/share/color-schemes/ATLAS.colors
  install -Dm644 "${SCRIPT_DIR}/configs/theme/metadata.desktop" /usr/share/color-schemes/ATLAS.desktop
}

configure_layout() {
  log "ATLAS configuration layout"
  log "Plasma config: ${SCRIPT_DIR}/configs/plasma"
  log "SDDM config: ${SCRIPT_DIR}/configs/sddm"
  log "Theme assets: ${SCRIPT_DIR}/configs/theme"
  install_plasma_defaults
  install_sddm_config
  install_theme_assets
}

enable_display_manager() {
  log "Enabling SDDM"
  systemctl enable sddm
  systemctl set-default graphical.target
}

main() {
  require_root
  install_packages
  configure_layout
  enable_display_manager
  log "ATLAS base installed"
}

main "$@"