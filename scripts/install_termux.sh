#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
#  INSTALADOR ARKYN - Script de Arranque para Termux
#  Sistema de instalación estilo cyberpunk
# ═══════════════════════════════════════════════════════════════════

# Variables y Constantes

export ARKYN_REPO_URL='https://github.com/devv-jr/arkyn-linux.git'

# Colores - Estética terminal retro
C_RESET="\033[0m"
C_GREEN="\033[1;32m"      # Verde Matrix
C_CYAN="\033[1;36m"       # Cyan neón
C_YELLOW="\033[1;33m"     # Ámbar advertencia
C_RED="\033[1;31m"        # Rojo crítico
C_MAGENTA="\033[1;35m"    # Rosa cyberpunk
C_DIM="\033[2;37m"        # Texto atenuado
C_BLINK="\033[5m"         # Parpadeante (no todas las terminales)

# Símbolos
SYM_OK="✓"
SYM_FAIL="✗"
SYM_ARROW="→"
SYM_WARN="⚠"
SYM_INFO="ℹ"

# ═══════════════════════════════════════════════════════════════════
#  Banner ASCII Art
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
    ║       Framework de Penetración para Termux    ║
    ║           v0.1.0 - VERSIÓN ALPHA              ║
    ╚═══════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
    echo -e "${C_DIM}    [*] Iniciando secuencia de instalación...${C_RESET}\n"
    sleep 1
}

# ═══════════════════════════════════════════════════════════════════
#  Funciones Auxiliares
# ═══════════════════════════════════════════════════════════════════

# Imprimir mensajes de estado
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

# Barra de progreso animada
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

# Simular efecto de carga
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

# Verificar que comando existe
require_cmd() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Comando requerido no encontrado: $1"
        exit 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  Pasos de Instalación
# ═══════════════════════════════════════════════════════════════════

step_system_check() {
    log_info "Ejecutando diagnósticos del sistema..."
    sleep 0.5
    
    # Verificar si está en Termux
    if [[ ! -d "/data/data/com.termux" ]]; then
        log_warn "No está ejecutándose en Termux - algunas funciones podrían no funcionar"
    fi
    
    # Verificar disponibilidad de pkg
    if ! command -v pkg &> /dev/null; then
        log_error "Gestor pkg no encontrado - ¿estás en Termux?"
        exit 1
    fi
    
    log_success "Verificación del sistema completada"
}

step_install_deps() {
    log_info "Instalando dependencias principales..."
    echo ""
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Actualizando repositorios de paquetes${C_RESET}"
    if pkg update -y > /tmp/arkyn_pkg.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
    else
        echo -e " ${C_YELLOW}${SYM_WARN}${C_RESET}"
    fi
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Instalando Python 3${C_RESET}"
    if pkg install python -y > /tmp/arkyn_python.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
    else
        echo -e " ${C_RED}${SYM_FAIL}${C_RESET}"
        log_error "Instalación de Python falló. Revisa /tmp/arkyn_python.log"
        exit 1
    fi
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Instalando Git${C_RESET}"
    if pkg install git -y > /tmp/arkyn_git.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
    else
        echo -e " ${C_RED}${SYM_FAIL}${C_RESET}"
        log_error "Instalación de Git falló. Revisa /tmp/arkyn_git.log"
        exit 1
    fi
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Actualizando pip${C_RESET}"
    if python -m pip install --upgrade pip > /tmp/arkyn_pip.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
    else
        echo -e " ${C_YELLOW}${SYM_WARN}${C_RESET} (no crítico)"
    fi
    
    log_success "Dependencias instaladas"
}

step_clone_repo() {
    # Verificar URL del repositorio (debe estar configurada al inicio)
    if [ -z "${ARKYN_REPO_URL-}" ]; then
        log_error "¡ARKYN_REPO_URL no está configurada en el script!"
        echo -e "${C_YELLOW}"
        echo "  Por favor edita el script y define la variable ARKYN_REPO_URL"
        echo -e "${C_RESET}"
        exit 1
    fi
    
    log_info "Clonando repositorio ARKYN..."
    echo -e "${C_DIM}  Origen: ${ARKYN_REPO_URL}${C_RESET}"
    
    TMP_DIR="$HOME/arkyn_tmp"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR"
    cd "$TMP_DIR"
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Descargando repositorio${C_RESET}"
    if git clone "$ARKYN_REPO_URL" arkyn-src > /tmp/arkyn_clone.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
        log_success "Repositorio clonado"
    else
        echo -e " ${C_RED}${SYM_FAIL}${C_RESET}"
        log_error "Clonación falló. Revisa /tmp/arkyn_clone.log"
        exit 1
    fi
    
    cd arkyn-src
}

step_install_arkyn() {
    log_info "Instalando framework ARKYN..."
    echo ""
    
    echo -ne "${C_CYAN}  ${SYM_ARROW} Instalando componentes CLI y TUI${C_RESET}"
    if pip install -e .[cli,ui] > /tmp/arkyn_install.log 2>&1; then
        echo -e " ${C_GREEN}${SYM_OK}${C_RESET}"
        log_success "ARKYN instalado en modo editable"
    else
        echo -e " ${C_RED}${SYM_FAIL}${C_RESET}"
        log_error "Instalación falló. Revisa /tmp/arkyn_install.log para más detalles"
        cat /tmp/arkyn_install.log
        exit 1
    fi
}

step_create_dirs() {
    log_info "Creando directorios de configuración..."
    
    mkdir -p "$HOME/.arkyn/plugins"
    mkdir -p "$HOME/.arkyn/configs"
    mkdir -p "$HOME/.arkyn/logs"
    
    log_success "Estructura de directorios creada"
}

step_verify() {
    log_info "Verificando instalación..."
    
    if command -v arkyn &> /dev/null; then
        log_success "Comando ARKYN disponible"
        return 0
    else
        log_error "Comando ARKYN no encontrado en PATH"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
#  Flujo Principal de Instalación
# ═══════════════════════════════════════════════════════════════════

main() {
    print_banner
    
    echo -e "${C_MAGENTA}╔═════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_MAGENTA}║${C_RESET}  Secuencia de Instalación Iniciada             ${C_MAGENTA}║${C_RESET}"
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
    
    # Banner de éxito
    echo -e "${C_GREEN}"
    cat << "EOF"
    ╔═══════════════════════════════════════════════╗
    ║                                               ║
    ║        INSTALACIÓN COMPLETADA ✓               ║
    ║                                               ║
    ║   ARKYN está operativo en tu sistema.         ║
    ║                                               ║
    ╚═══════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
    
    echo -e "${C_CYAN}Comandos de Inicio Rápido:${C_RESET}"
    echo -e "  ${C_GREEN}arkyn --help${C_RESET}       - Mostrar todos los comandos"
    echo -e "  ${C_GREEN}arkyn info${C_RESET}         - Información del sistema"
    echo -e "  ${C_GREEN}arkyn tui${C_RESET}          - Lanzar interfaz TUI"
    echo -e "  ${C_GREEN}arkyn plugins list${C_RESET} - Listar plugins disponibles"
    echo ""
    echo -e "${C_DIM}[*] Sistema listo para despliegue${C_RESET}"
}

# Ejecutar instalación principal
main
