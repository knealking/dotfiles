#!/bin/bash -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEBIAN_DEPS="build-essential git zsh curl wget python3 python3-venv eza bat fd-find fzf ripgrep tmux libssl-dev"
ARCH_DEPS="base-devel git zsh stow curl eza bat fd fzf ripgrep"
FEDORA_DEPS="@development-tools git zsh stow curl eza bat fd-find fzf ripgrep"
ALPINE_DEPS="build-base git zsh stow curl exa bat fd-find fzf ripgrep"
MACOS_DEPS="xcode-select"

error() {
    printf "${RED}[!] %s${NC}\n" "$1"
}

success() {
    printf "${GREEN}[+] %s${NC}\n" "$1"
}

info() {
    printf "[i] %s\n" "$1"
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
        arch|manjaro|endeavouros|garuda|artix)
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
        rhel)     sudo dnf upgrade -y ;;
        opensuse) sudo zypper refresh && sudo zypper update -y ;;
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
        rhel)     sudo dnf install -y "$@" ;;
        opensuse) sudo zypper install -y "$@" ;;
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

confirm() {
    printf "%s [Y/n] " "$1"
    read -r answer
    case "$answer" in
        [nN]|[nN][oO]) return 1 ;;
        *) return 0 ;;
    esac
}

configure_zsh() {
    ln -s "$(which batcat)" "$HOME/.local/bin/bat"
    ln -s "$(which fdfind)" "$HOME/.local/bin/fd"

    mkdir -p "$HOME/.cache/zsh" "$HOME/.local/state/zsh"
    sudo tee -a /etc/zsh/zshenv >/dev/null <<'EOF'
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
EOF
}

# -------------------------------------------------------

# Detect distro before doing anything
detect_distro

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

if confirm "Install Nerd Fonts?"; then
    info "Installing Nerd Fonts..."
    curl -Lo JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    mkdir -p ~/.local/share/fonts/JetBrainsMono
    unzip ./JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
    rm ./JetBrainsMono.zip
    fc-cache -fv
    success "Fonts installation successful"
fi

if confirm "Configure zsh to use the dotfiles directory?"; then
    info "Configuring zsh..."
    configure_zsh
    success "Zsh configuration successful"
fi

if confirm "Link dotfiles to home directory?"; then
    info "Linking dotfiles..."
    ./dotmate.py
    success "Linking dotfiles successful"
fi

success "Setup successful!"
