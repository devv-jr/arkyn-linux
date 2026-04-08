#!/usr/bin/env bash
set -euo pipefail

ATLAS_REPO="${ATLAS_REPO:-devv-jr/arkyn-linux}"
ATLAS_REF="${ATLAS_REF:-main}"
ATLAS_CONFIG_BASE_URL="${ATLAS_CONFIG_BASE_URL:-https://raw.githubusercontent.com/${ATLAS_REPO}/${ATLAS_REF}/flavors/ATLAS/configs}"
ATLAS_TMP_DIR=""

log() {
  printf '\n[ATLAS] %s\n' "$*"
}

cleanup() {
  if [ -n "$ATLAS_TMP_DIR" ] && [ -d "$ATLAS_TMP_DIR" ]; then
    rm -rf "$ATLAS_TMP_DIR"
  fi
}

trap cleanup EXIT

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    printf '[ERROR] Run this script with sudo or as root.\n' >&2
    exit 1
  fi
}

require_network_tool() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    return
  fi

  printf '[ERROR] Install curl or wget before running this script.\n' >&2
  exit 1
}

fetch_file() {
  local remote_path="$1"
  local output_path="$2"
  local remote_url="${ATLAS_CONFIG_BASE_URL}/${remote_path}"

  install -d "$(dirname "$output_path")"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$remote_url" -o "$output_path"
    return
  fi

  wget -qO "$output_path" "$remote_url"
}

install_packages() {
  log "Updating package lists"
  apt-get update

  log "Installing Plasma and SDDM"
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
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

download_configs() {
  log "Downloading ATLAS configs from ${ATLAS_CONFIG_BASE_URL}"

  ATLAS_TMP_DIR="$(mktemp -d)"

  fetch_file "plasma/kdeglobals" "${ATLAS_TMP_DIR}/kdeglobals"
  fetch_file "plasma/kwinrc" "${ATLAS_TMP_DIR}/kwinrc"
  fetch_file "plasma/kscreenlockerrc" "${ATLAS_TMP_DIR}/kscreenlockerrc"
  fetch_file "sddm/sddm.conf" "${ATLAS_TMP_DIR}/sddm.conf"
  fetch_file "theme/ATLAS.colors" "${ATLAS_TMP_DIR}/ATLAS.colors"
  fetch_file "theme/metadata.desktop" "${ATLAS_TMP_DIR}/metadata.desktop"
}

install_plasma_defaults() {
  log "Installing Plasma defaults"
  install -d /etc/skel/.config
  install -Dm644 "${ATLAS_TMP_DIR}/kdeglobals" /etc/skel/.config/kdeglobals
  install -Dm644 "${ATLAS_TMP_DIR}/kwinrc" /etc/skel/.config/kwinrc
  install -Dm644 "${ATLAS_TMP_DIR}/kscreenlockerrc" /etc/skel/.config/kscreenlockerrc
}

install_sddm_config() {
  log "Installing SDDM config"
  install -d /etc/sddm.conf.d
  install -Dm644 "${ATLAS_TMP_DIR}/sddm.conf" /etc/sddm.conf.d/90-atlas.conf
}

install_theme_assets() {
  log "Installing ATLAS color scheme"
  install -d /usr/share/color-schemes
  install -Dm644 "${ATLAS_TMP_DIR}/ATLAS.colors" /usr/share/color-schemes/ATLAS.colors
  install -Dm644 "${ATLAS_TMP_DIR}/metadata.desktop" /usr/share/color-schemes/ATLAS.desktop
}

configure_layout() {
  log "ATLAS configuration layout"
  log "Plasma config source: ${ATLAS_CONFIG_BASE_URL}/plasma"
  log "SDDM config source: ${ATLAS_CONFIG_BASE_URL}/sddm"
  log "Theme assets source: ${ATLAS_CONFIG_BASE_URL}/theme"
  download_configs
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