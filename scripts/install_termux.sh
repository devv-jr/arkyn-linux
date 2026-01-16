#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
#  ARKYN INSTALLER - Termux Bootstrap Script
#  Cyberpunk-style installation system
# ═══════════════════════════════════════════════════════════════════

# Variables and Constants

export ARKYN_REPO_URL='https://github.com/devv-jr/arkyn-linux.git'

# Colors - Retro terminal aesthetic
C_RESET="\033[0m"
C_GREEN="\033[1;32m"      # Matrix green
C_CYAN="\033[1;36m"       # Neon cyan
C_YELLOW="\033[1;33m"     # Warning amber
C_RED="\033[1;31m"        # Critical red
C_MAGENTA="\033[1;35m"    # Cyberpunk pink
C_DIM="\033[2;37m"        # Dimmed text
C_BLINK="\033[5m"         # Blinking (not all terminals)

# Symbols
SYM_OK="✓"
SYM_FAIL="✗"
SYM_ARROW="→"
SYM_WARN="⚠"
SYM_INFO="ℹ"

# ═══════════════════════════════════════════════════════════════════
#  ASCII Art Banner
# ═══════════════════════════════════════════════════════════════════
print_banner() {
    clear
    echo -e "${C_CYAN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════╗
    ║                                               ║
    ║     █████╗ ██████╗ ██╗  ██╗██╗   ██╗███╗   ██╗║
    ║    ██╔══██╗██╔══██╗██║ ██╔╝╚██╗ ██╔╝████╗  ██║║
    ║    ███████║██████╔╝█████╔╝  ╚████╔╝ ██╔██╗ ██║║
    ║    ██╔══██║██╔══██╗██╔═██╗   ╚██╔╝  ██║╚██╗██║║
    ║    ██║  ██║██║  ██║██║  ██╗   ██║   ██║ ╚████║║
    ║    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═══╝║
    ║                                               ║
    ║          Termux Penetration Framework         ║
    ║              v0.1.0 - ALPHA BUILD             ║
    ╚═══════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
    echo -e "${C_DIM}    [*] Initializing installation sequence...${C_RESET}\n"
    sleep 1
}

# ═══════════════════════════════════════════════════════════════════
#  Helper Functions
# ═══════════════════════════════════════════════════════════════════

# Print status messages
log_info() {
    echo -e "${C_CYAN}[${SYM_INFO}]${C_RESET} $*"
}

log_success() {
    echo -e "${C_GREEN}[${SYM_OK}]${C_RESET} $*"
}

log_error() {
    echo -e "${C_RED}[${SYM_FAIL}]${C_RESET} $*"
}

log_warn() {
    echo -e "${C_YELLOW}[${SYM_WARN}]${C_RESET} $*"
}

# Animated progress bar
progress_bar() {
    local duration=$1
    local text=$2
    local width=40
    
    echo -ne "${C_MAGENTA}${SYM_ARROW} ${text}${C_RESET} ["
    
    for ((i=0; i<=width; i++)); do
        echo -ne "${C_GREEN}█${C_RESET}"
        sleep $(echo "scale=3; $duration/$width" | bc)
    done
    
    echo -e "] ${C_GREEN}${SYM_OK}${C_RESET}"
}

# Simulate loading effect
loading() {
    local text=$1
    local delay=0.1
    echo -ne "${C_CYAN}${text}${C_RESET}"
    for i in {1..3}; do
        echo -ne "${C_DIM}.${C_RESET}"
        sleep $delay
    done
    echo ""
}

# Check command exists
require_cmd() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command not found: $1"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  Installation Steps
# ═══════════════════════════════════════════════════════════════════

step_system_check() {
    log_info "Running system diagnostics..."
    sleep 0.5
    
    # Check if running in Termux
    if [[ ! -d "/data/data/com.termux" ]]; then
        log_warn "Not running in Termux - some features may not work"
    fi
    
    # Check pkg availability
    if ! command -v pkg &> /dev/null; then
        log_error "pkg manager not found - are you in Termux?"
        exit 1
    fi
    
    log_success "System check passed"
}

step_install_deps() {
    log_info "Installing core dependencies..."
    echo ""
    
    loading "  ${SYM_ARROW} Updating package repositories"
    pkg update -y &> /dev/null || true
    
    loading "  ${SYM_ARROW} Installing Python 3"
    pkg install python -y &> /dev/null
    
    loading "  ${SYM_ARROW} Installing Git"
    pkg install git -y &> /dev/null
    
    loading "  ${SYM_ARROW} Upgrading pip"
    python -m pip install --upgrade pip &> /dev/null
    
    log_success "Dependencies installed"
}

step_clone_repo() {
    # Check for repo URL (should be set at script top)
    if [ -z "${ARKYN_REPO_URL-}" ]; then
        log_error "ARKYN_REPO_URL not configured in script!"
        echo -e "${C_YELLOW}"
        echo "  Please edit the script and set ARKYN_REPO_URL variable"
        echo -e "${C_RESET}"
        exit 1
    fi
    
    log_info "Cloning ARKYN repository..."
    echo -e "${C_DIM}  Source: ${ARKYN_REPO_URL}${C_RESET}"
    
    TMP_DIR="$HOME/arkyn_tmp"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    
    if git clone "$ARKYN_REPO_URL" arkyn-src 2>&1 | grep -q "Cloning"; then
        log_success "Repository cloned"
    else
        log_error "Clone failed"
        exit 1
    fi
    
    cd arkyn-src
}

step_install_arkyn() {
    log_info "Installing ARKYN framework..."
    echo ""
    
    loading "  ${SYM_ARROW} Setting up CLI interface"
    loading "  ${SYM_ARROW} Setting up TUI interface"
    
    if pip install -e .[cli,ui] &> /dev/null; then
        log_success "ARKYN installed in editable mode"
    else
        log_error "Installation failed"
        exit 1
    fi
}

step_create_dirs() {
    log_info "Creating configuration directories..."
    
    mkdir -p "$HOME/.arkyn/plugins"
    mkdir -p "$HOME/.arkyn/configs"
    mkdir -p "$HOME/.arkyn/logs"
    
    log_success "Directory structure created"
}

step_verify() {
    log_info "Verifying installation..."
    
    if command -v arkyn &> /dev/null; then
        log_success "ARKYN command available"
        return 0
    else
        log_error "ARKYN command not found in PATH"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  Main Installation Flow
# ═══════════════════════════════════════════════════════════════════

main() {
    print_banner
    
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET}  Installation Sequence Initiated               ${C_MAGENTA}║${C_RESET}"
    echo -e "${C_MAGENTA}╚═════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    step_system_check
    echo ""
    
    step_install_deps
    echo ""
    
    step_clone_repo
    echo ""
    
    step_install_arkyn
    echo ""
    
    step_create_dirs
    echo ""
    
    step_verify
    echo ""
    
    # Success banner
    echo -e "${C_GREEN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════╗
    ║                                               ║
    ║        INSTALLATION COMPLETE ✓                ║
    ║                                               ║
    ║   ARKYN is now operational in your system.    ║
    ║                                               ║
    ╚═══════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
    
    echo -e "${C_CYAN}Quick Start Commands:${C_RESET}"
    echo -e "  ${C_GREEN}arkyn --help${C_RESET}     - Show all commands"
    echo -e "  ${C_GREEN}arkyn info${C_RESET}       - System information"
    echo -e "  ${C_GREEN}arkyn tui${C_RESET}        - Launch TUI interface"
    echo -e "  ${C_GREEN}arkyn plugins list${C_RESET} - List available plugins"
    echo ""
    echo -e "${C_DIM}[*] System ready for deployment${C_RESET}"
}

# Execute main installation
main
