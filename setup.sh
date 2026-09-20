#!/bin/bash -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEBIAN_DEPS="build-essential git zsh curl wget python3 python3-venv eza bat zoxide fd-find fzf ripgrep tmux libssl-dev alacritty"
ARCH_DEPS="base-devel git zsh stow curl eza bat fd fzf ripgrep"
FEDORA_DEPS="@development-tools git zsh stow curl eza bat fd-find fzf ripgrep"
ALPINE_DEPS="build-base git zsh stow curl exa bat fd-find fzf ripgrep"
MACOS_DEPS="xcode-select"

LOCAL_BIN="$HOME/.local/bin"
ZCACHE="$HOME/.cache/zsh"
FONTS="$HOME/.local/share/fonts"
STATE="$HOME/.local/state/zsh"
NSSDB="$HOME/.pki/nssdb"
ALACRITTY_THEMES="$HOME/.local/state/alacritty/themes"

error() {
    printf "${RED}[!] %s${NC}\n" "$1"
}

success() {
    printf "${GREEN}[+] %s${NC}\n" "$1"
}

info() {
    printf "[i] %s\n" "$1"
}

confirm() {
    printf "%s [Y/n] " "$1"
    read -r answer
    case "$answer" in
        [nN]|[nN][oO]) return 1 ;;
        *) return 0 ;;
    esac
}

check_dir () {
    if [ ! -d "$1" ]; then
        info "Creating dir $1..."
        mkdir -p -- "$1"
    fi
    info "$1 exists"
}

# Detect Linux distribution family
detect_distro() {
    if [ ! -f /etc/os-release ]; then
        error "Error: /etc/os-release not found. Cannot detect distro."
        exit 1
    fi

    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_ID_LIKE="${ID_LIKE:-}"

    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian)
            DISTRO_FAMILY="debian" ;;
        darwin)
            DISTRO_FAMILY="macos" ;;
        arch|cachyos|manjaro|endeavouros|garuda|artix)
            DISTRO_FAMILY="arch" ;;
        fedora)
            DISTRO_FAMILY="fedora" ;;
        centos|rhel|rocky|almalinux|ol)
            DISTRO_FAMILY="rhel" ;;
        opensuse*|sles|sled)
            DISTRO_FAMILY="opensuse" ;;
        alpine)
            DISTRO_FAMILY="alpine" ;;
        *)
            # Fallback using ID_LIKE
            case "$DISTRO_ID_LIKE" in
                *debian*|*ubuntu*)  DISTRO_FAMILY="debian" ;;
                *arch*)             DISTRO_FAMILY="arch" ;;
                *fedora*|*rhel*)    DISTRO_FAMILY="fedora" ;;
                *suse*)             DISTRO_FAMILY="opensuse" ;;
                *)
                    error "Error: Unsupported distro: $DISTRO_ID"
                    exit 1
                    ;;
            esac
            ;;
    esac

    success "Detected distro: $DISTRO_ID (family: $DISTRO_FAMILY)"
}

pkg_update() {
    case "$DISTRO_FAMILY" in
        debian)   sudo apt update && sudo apt upgrade -y ;;
        arch)     sudo pacman -Syu --noconfirm ;;
        fedora)   sudo dnf upgrade -y ;;
        alpine)   sudo apk update && sudo apk upgrade ;;
        macos)    brew update && brew upgrade ;;
    esac
}

pkg_install() {
    case "$DISTRO_FAMILY" in
        debian)   sudo apt-get install -y "$@" ;;
        macos)    brew install "$@" ;;
        arch)     sudo pacman -S --noconfirm "$@" ;;
        fedora)   sudo dnf install -y "$@" ;;
        alpine)   sudo apk add "$@" ;;
    esac
}

deps_for_distro() {
    case "$DISTRO_FAMILY" in
        debian)   echo "$DEBIAN_DEPS" ;;
        macos)    echo "$MACOS_DEPS" ;;
        arch)     echo "$ARCH_DEPS" ;;
        fedora)   echo "$FEDORA_DEPS" ;;
        alpine)   echo "$ALPINE_DEPS" ;;
    esac
}

install_build_deps() {
    pkg_install $(deps_for_distro)
}

configure_zsh() {
    sudo tee -a /etc/zsh/zshenv >/dev/null <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF
}

install_font() {
    local url="$1"
    local name="$2"

    if confirm "Install $name?"; then
        info "Installing $name..."

        curl -LO "$url"

        mkdir -p "$FONTS/$name"
        unzip "./${url##*/}" -d "$FONTS/$name"
        rm "./${url##*/}"

        fc-cache -fv

        success "$name installation successful"
    fi
}

setup_alacritty() {
    if [ ! -d "$ALACRITTY_THEMES" ]; then
        info "Alacritty themes not found. Cloning repository..."
        mkdir -p "$ALACRITTY_THEMES"
        git clone --depth=1 https://github.com/alacritty/alacritty-theme "$ALACRITTY_THEMES"
    fi
}

configure_cac() {
    certutil -N -d sql:$HOME/.pki/nssdb --empty-password

    # run jdjaxon/linux_cac script
    curl -fsSL https://raw.githubusercontent.com/jdjaxon/linux_cac/main/cac_setup.sh

    modutil -dbdir sql:$HOME/.pki/nssdb/ \
        -add "CAC Module" \
        -libfile /lib/x86_64-linux-gnu/opensc-pkcs11.so
}

# main
# =============================================================================
# Detect distro before doing anything
detect_distro

check_dir "$LOCAL_BIN"
check_dir "$ZCACHE"
check_dir "$STATE"
check_dir "$NSSDB"

ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"

if confirm "Update system packages?"; then
    info "Updating system packages..."
    pkg_update
    success "Update successful"
fi

if confirm "Install dependencies? ($(deps_for_distro))"; then
    info "Installing dependencies..."
    install_build_deps
    success "Dependencies installation successful"
fi

if confirm "Configure zsh to use the dotfiles directory?"; then
    info "Configuring zsh..."
    configure_zsh
    success "Zsh configuration successful"
fi

setup_alacritty

install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "JetBrainsMono"
install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" "Meslo"

if confirm "Configure linux cac?"; then
    info "Setting up linux cac..."
    configure_cac
fi

if confirm "Link dotfiles to home directory?"; then
    info "Linking dotfiles..."
    ./dotmate.py
    success "Linking dotfiles successful"
fi

success "Setup successful!"
