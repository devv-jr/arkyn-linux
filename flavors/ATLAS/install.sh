#!/usr/bin/env bash
set -euo pipefail

ATLAS_REPO="${ATLAS_REPO:-devv-jr/arkyn-linux}"
ATLAS_REF="${ATLAS_REF:-main}"
ATLAS_CONFIG_BASE_URL="${ATLAS_CONFIG_BASE_URL:-https://raw.githubusercontent.com/${ATLAS_REPO}/${ATLAS_REF}/flavors/ATLAS/configs}"
ATLAS_TMP_DIR=""
ARKYN_WALLPAPER_DIR="/usr/share/backgrounds/arkyn"
ARKYN_WALLPAPER_DARK="${ARKYN_WALLPAPER_DARK:-default-dark.jpg}"
ARKYN_WALLPAPER_LIGHT="${ARKYN_WALLPAPER_LIGHT:-default-light.jpg}"
ARKYN_THEME_VARIANT="${ARKYN_THEME_VARIANT:-dark}"

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

resolve_default_wallpaper() {
  local wallpaper_name="${ARKYN_WALLPAPER_DARK}"

  if [ "${ARKYN_THEME_VARIANT}" = "light" ]; then
    wallpaper_name="${ARKYN_WALLPAPER_LIGHT}"
  fi

  if [ -f "${ARKYN_WALLPAPER_DIR}/${wallpaper_name}" ]; then
    printf '%s\n' "${ARKYN_WALLPAPER_DIR}/${wallpaper_name}"
    return
  fi

  if [ -f "${ARKYN_WALLPAPER_DIR}/${ARKYN_WALLPAPER_DARK}" ]; then
    printf '%s\n' "${ARKYN_WALLPAPER_DIR}/${ARKYN_WALLPAPER_DARK}"
    return
  fi

  if [ -f "${ARKYN_WALLPAPER_DIR}/${ARKYN_WALLPAPER_LIGHT}" ]; then
    printf '%s\n' "${ARKYN_WALLPAPER_DIR}/${ARKYN_WALLPAPER_LIGHT}"
    return
  fi

  printf '\n'
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

install_kde_wallpaper_defaults() {
  local wallpaper_path
  wallpaper_path="$(resolve_default_wallpaper)"

  if [ -z "${wallpaper_path}" ]; then
    log "Skipping KDE wallpaper defaults (no wallpaper found in ${ARKYN_WALLPAPER_DIR})"
    return
  fi

  log "Installing KDE wallpaper defaults (${wallpaper_path})"

  install -d /usr/local/bin /etc/xdg/autostart

  cat > /usr/local/bin/arkyn-apply-kde-wallpaper <<EOF
#!/usr/bin/env bash
set -euo pipefail

MARKER="\${XDG_CONFIG_HOME:-\$HOME/.config}/.arkyn-kde-wallpaper-initialized"
if [[ -f "\${MARKER}" ]]; then
  exit 0
fi

if ! command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
  exit 0
fi

plasma-apply-wallpaperimage "${wallpaper_path}" >/dev/null 2>&1 || exit 0
mkdir -p "\$(dirname "\${MARKER}")"
: > "\${MARKER}"
EOF

  chmod 755 /usr/local/bin/arkyn-apply-kde-wallpaper

  cat > /etc/xdg/autostart/arkyn-apply-kde-wallpaper.desktop <<'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=ARKYN KDE Wallpaper Default
Comment=Apply ARKYN default wallpaper on first KDE login
Exec=/usr/local/bin/arkyn-apply-kde-wallpaper
OnlyShowIn=KDE;
X-KDE-autostart-phase=2
NoDisplay=true
EOF
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
  install_kde_wallpaper_defaults
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