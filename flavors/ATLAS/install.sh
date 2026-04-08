#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

ATLAS_REPO="${ATLAS_REPO:-devv-jr/arkyn-linux}"
ATLAS_REF="${ATLAS_REF:-main}"
ATLAS_FLAVOR_PATH="${ATLAS_FLAVOR_PATH:-flavors/ATLAS}"
ATLAS_CONFIG_BASE_URL="${ATLAS_CONFIG_BASE_URL:-https://raw.githubusercontent.com/${ATLAS_REPO}/${ATLAS_REF}/${ATLAS_FLAVOR_PATH}/configs}"
ATLAS_ASSETS_BASE_URL="${ATLAS_ASSETS_BASE_URL:-https://raw.githubusercontent.com/${ATLAS_REPO}/${ATLAS_REF}/assets/arkyn}"
ATLAS_LOCAL_CONFIG_DIR="${ATLAS_LOCAL_CONFIG_DIR:-${SCRIPT_DIR}/configs}"
ATLAS_LOCAL_ASSETS_DIR="${ATLAS_LOCAL_ASSETS_DIR:-${REPO_ROOT}/assets/arkyn}"
ATLAS_CONFIG_MODE="${ATLAS_CONFIG_MODE:-auto}"
ATLAS_KEEP_TMP="${ATLAS_KEEP_TMP:-0}"
ATLAS_TMP_DIR=""
ATLAS_FETCHED_LOCAL=0
ATLAS_FETCHED_REMOTE=0
ATLAS_WALLPAPER_SELECTED=""

TARGET_USER="${SUDO_USER:-}"
TARGET_USER_HOME=""
ATLAS_USER_DEFAULTS_APPLIED=0

ARKYN_WALLPAPER_DIR="/usr/share/backgrounds/arkyn"
ARKYN_WALLPAPER_DARK="${ARKYN_WALLPAPER_DARK:-default-dark.jpg}"
ARKYN_WALLPAPER_LIGHT="${ARKYN_WALLPAPER_LIGHT:-default-light.jpg}"
ARKYN_THEME_VARIANT="${ARKYN_THEME_VARIANT:-dark}"

usage() {
  cat <<EOF
Usage:
  sudo ${SCRIPT_NAME} [--user USERNAME] [--config-mode auto|online|local] [--keep-tmp]

Options:
  --user USERNAME    Also apply Plasma defaults to an existing user
  --config-mode MODE Config source mode (default: auto)
  --keep-tmp         Keep temporary downloaded files for debugging
  -h, --help         Show this help

Env vars:
  ATLAS_CONFIG_MODE      auto|online|local
  ATLAS_CONFIG_BASE_URL  Remote config base URL
  ATLAS_LOCAL_CONFIG_DIR Local config directory
  ATLAS_LOCAL_ASSETS_DIR Local assets directory
  ARKYN_THEME_VARIANT    dark|light
EOF
}

log() {
  printf '\n[ATLAS] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [ -n "$ATLAS_TMP_DIR" ] && [ -d "$ATLAS_TMP_DIR" ]; then
    if [ "$ATLAS_KEEP_TMP" = "1" ]; then
      log "Keeping temporary files at ${ATLAS_TMP_DIR}"
    else
      rm -rf "$ATLAS_TMP_DIR"
    fi
  fi
}

trap cleanup EXIT

require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    die "Run this script with sudo or as root."
  fi
}

validate_config_mode() {
  case "$ATLAS_CONFIG_MODE" in
    auto|online|local)
      ;;
    *)
      die "Invalid config mode '${ATLAS_CONFIG_MODE}'. Use: auto, online, or local."
      ;;
  esac
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --user)
        shift
        [ $# -gt 0 ] || die "--user requires a username"
        TARGET_USER="$1"
        ;;
      --config-mode)
        shift
        [ $# -gt 0 ] || die "--config-mode requires a value"
        ATLAS_CONFIG_MODE="$1"
        ;;
      --keep-tmp)
        ATLAS_KEEP_TMP="1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done

  validate_config_mode
}

detect_target_user() {
  if [ -z "$TARGET_USER" ]; then
    return
  fi

  if ! id "$TARGET_USER" >/dev/null 2>&1; then
    warn "Target user '$TARGET_USER' does not exist. Defaults will only be copied to /etc/skel."
    TARGET_USER=""
    return
  fi

  TARGET_USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
  if [ -z "$TARGET_USER_HOME" ] || [ ! -d "$TARGET_USER_HOME" ]; then
    warn "Could not resolve a valid home for user '$TARGET_USER'. Skipping per-user defaults."
    TARGET_USER_HOME=""
  fi
}

require_network_tool() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    return
  fi

  die "Install curl or wget before running this script."
}

download_to_file() {
  local url="$1"
  local output_path="$2"

  require_network_tool

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output_path"
    return
  fi

  wget -qO "$output_path" "$url"
}

fetch_file() {
  local remote_path="$1"
  local output_path="$2"
  local local_path="${ATLAS_LOCAL_CONFIG_DIR}/${remote_path}"
  local remote_url="${ATLAS_CONFIG_BASE_URL}/${remote_path}"

  install -d "$(dirname "$output_path")"

  if [ "$ATLAS_CONFIG_MODE" != "online" ] && [ -f "$local_path" ]; then
    install -Dm644 "$local_path" "$output_path"
    ATLAS_FETCHED_LOCAL=$((ATLAS_FETCHED_LOCAL + 1))
    return
  fi

  if [ "$ATLAS_CONFIG_MODE" = "local" ]; then
    die "Missing local config file: ${local_path}"
  fi

  download_to_file "$remote_url" "$output_path"
  ATLAS_FETCHED_REMOTE=$((ATLAS_FETCHED_REMOTE + 1))
}

install_required_wallpaper() {
  local wallpaper_name="$1"
  local local_path="${ATLAS_LOCAL_ASSETS_DIR}/${wallpaper_name}"
  local target_path="${ARKYN_WALLPAPER_DIR}/${wallpaper_name}"
  local remote_url="${ATLAS_ASSETS_BASE_URL}/${wallpaper_name}"

  if [ "$ATLAS_CONFIG_MODE" != "online" ] && [ -f "$local_path" ]; then
    install -m 644 "$local_path" "$target_path"
    return
  fi

  if [ "$ATLAS_CONFIG_MODE" = "local" ]; then
    die "Missing local wallpaper asset: ${local_path}"
  fi

  download_to_file "$remote_url" "$target_path"
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

install_wallpapers() {
  log "Installing required wallpapers"
  install -d "${ARKYN_WALLPAPER_DIR}"
  install_required_wallpaper "${ARKYN_WALLPAPER_DARK}"
  install_required_wallpaper "${ARKYN_WALLPAPER_LIGHT}"
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

install_file_with_backup() {
  local source_file="$1"
  local target_file="$2"

  if [ -f "$target_file" ]; then
    cp -a "$target_file" "${target_file}.arkyn.bak"
  fi

  install -Dm644 "$source_file" "$target_file"
}

install_plasma_defaults() {
  log "Installing Plasma defaults"
  install -d /etc/skel/.config
  install -Dm644 "${ATLAS_TMP_DIR}/kdeglobals" /etc/skel/.config/kdeglobals
  install -Dm644 "${ATLAS_TMP_DIR}/kwinrc" /etc/skel/.config/kwinrc
  install -Dm644 "${ATLAS_TMP_DIR}/kscreenlockerrc" /etc/skel/.config/kscreenlockerrc

  if [ -n "$TARGET_USER" ] && [ -n "$TARGET_USER_HOME" ]; then
    log "Applying Plasma defaults to existing user ${TARGET_USER}"
    install -d "${TARGET_USER_HOME}/.config"

    install_file_with_backup "${ATLAS_TMP_DIR}/kdeglobals" "${TARGET_USER_HOME}/.config/kdeglobals"
    install_file_with_backup "${ATLAS_TMP_DIR}/kwinrc" "${TARGET_USER_HOME}/.config/kwinrc"
    install_file_with_backup "${ATLAS_TMP_DIR}/kscreenlockerrc" "${TARGET_USER_HOME}/.config/kscreenlockerrc"

    chown "$TARGET_USER:$TARGET_USER" \
      "${TARGET_USER_HOME}/.config/kdeglobals" \
      "${TARGET_USER_HOME}/.config/kwinrc" \
      "${TARGET_USER_HOME}/.config/kscreenlockerrc"

    ATLAS_USER_DEFAULTS_APPLIED=1
  fi
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
  ATLAS_WALLPAPER_SELECTED="$wallpaper_path"

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
  log "Config mode: ${ATLAS_CONFIG_MODE}"
  log "Local config dir: ${ATLAS_LOCAL_CONFIG_DIR}"
  log "Remote config URL: ${ATLAS_CONFIG_BASE_URL}"
  log "Local assets dir: ${ATLAS_LOCAL_ASSETS_DIR}"
  log "Remote assets URL: ${ATLAS_ASSETS_BASE_URL}"
  download_configs
  install_wallpapers
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

post_install_verification() {
  local sddm_state="unknown"
  if command -v systemctl >/dev/null 2>&1; then
    sddm_state="$(systemctl is-enabled sddm 2>/dev/null || true)"
    if [ -z "$sddm_state" ]; then
      sddm_state="unknown"
    fi
  fi

  cat <<EOF

[ATLAS] Verification summary
- SDDM enabled: ${sddm_state}
- Config mode: ${ATLAS_CONFIG_MODE}
- Config files from local: ${ATLAS_FETCHED_LOCAL}
- Config files from remote: ${ATLAS_FETCHED_REMOTE}
- Local config dir: ${ATLAS_LOCAL_CONFIG_DIR}
- Remote config URL: ${ATLAS_CONFIG_BASE_URL}
- Wallpaper directory: ${ARKYN_WALLPAPER_DIR}
- Selected wallpaper: ${ATLAS_WALLPAPER_SELECTED:-not found}
EOF

  if [ "$ATLAS_USER_DEFAULTS_APPLIED" -eq 1 ]; then
    printf -- "- Existing user defaults: applied to %s (%s)\n" "$TARGET_USER" "$TARGET_USER_HOME"
  else
    printf -- "- Existing user defaults: not applied\n"
    printf -- "  Use: sudo %s --user <username>\n" "$SCRIPT_NAME"
  fi

  if [ "$ATLAS_KEEP_TMP" = "1" ] && [ -n "$ATLAS_TMP_DIR" ]; then
    printf -- "- Temporary files kept at: %s\n" "$ATLAS_TMP_DIR"
  fi

  printf '\n'
}

main() {
  parse_args "$@"
  require_root
  detect_target_user
  install_packages
  configure_layout
  enable_display_manager
  post_install_verification
  log "ATLAS base installed"
}

main "$@"