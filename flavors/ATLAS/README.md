# ATLAS

ATLAS is the calm, classic desktop flavor for Debian 12.

Goal:
- clean login screen
- familiar desktop flow
- clear bottom panel
- known app launcher
- sober, organized visual style

Stack:
- Debian 12
- KDE Plasma
- SDDM

Layout:
- `install.sh` installs and configures the flavor
- `configs/plasma/` stores Plasma defaults and session-level tweaks
- `configs/sddm/` stores login manager configuration
- `configs/theme/` stores the visual theme assets and settings

Current files:
- `configs/plasma/kdeglobals`
- `configs/plasma/kwinrc`
- `configs/plasma/kscreenlockerrc`
- `configs/sddm/sddm.conf`
- `configs/theme/ATLAS.colors`
- `configs/theme/metadata.desktop`

ATLAS is meant to feel like a comfortable classic desktop without copying Windows or depending on it.