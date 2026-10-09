#!/bin/sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Local paths for installation and configuration
LOCAL_BIN="$HOME/.local/bin"
DATA_HOME="$HOME/.local/share"
ZCACHE="$HOME/.cache/zsh"
STATE="$HOME/.local/state/zsh"
FONTS="$HOME/.local/share/fonts"

# Distribution-specific dependencies
DEBIAN_DEPS="zsh git curl wget tmux build-essential gcc clang stow bat \
    python3 python3-venv ripgrep fd-find eza zoxide"

MACOS_DEPS="xcode-select"

ARCH_DEPS="base-devel git zsh stow curl eza bat fd fzf ripgrep"
FEDORA_DEPS="@development-tools git zsh stow curl eza bat fd-find fzf ripgrep"
ALPINE_DEPS="build-base git zsh stow curl exa bat fd-find fzf ripgrep"

main() {
    # Detect distro before doing anything
    get_os

    # Update system
    info "Updating system packages..."
    pkg_update
    success "Update successful"

    # Install defined packages
    info "Installing dependencies..."
    pkg_install $(deps_for_distro)
    success "Dependencies installation successful"

    info "Linking utilities..."
    mkdir -p "$LOCAL_BIN" "$DATA_HOME" "$ZCACHE" "$STATE" "$FONTS"
    link_command batcat bat
    link_command fdfind fd

    # Install fonts
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "JetBrainsMono"
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" "Meslo"

    # Install nvim
    if [ ! -f /usr/local/bin/nvim ]; then
        info "Installing Neovim..."
        curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        sudo tar -C /usr/local -xzf nvim.tar.gz --strip-components=1
        rm nvim.tar.gz
        success "Neovim installed successfully!"
    else
        info "Neovim already installed!"
    fi

    # install fzf
    if [ ! -d $HOME/.fzf ]; then
        info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --bin
        success "fzf installed successfully!"
    else
        info "fzf already installed!"
    fi

    # install uv
    if [ ! -f "$HOME/.local/bin/uv" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        success "uv installed successfully!"
    else
        info "uv already installed!"
    fi

    # Set up SSH keys
    if confirm "Set up SSH keys?"; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        generate_ssh_key "github"
        generate_ssh_key "gitlab"
    fi

    # install dotfiles
    if [ ! -d "$HOME/.dotfiles" ]; then
        info "Installing dotfiles..."
        git clone https://github.com/knealking/dotfiles.git "$HOME/.dotfiles"
        success "Dotfiles installed successfully!"
    else
        info "Dotfiles already installed!"
    fi

    success "Setup successful!"
}

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

# Link commands to local bin
link_command() {
    command -v "$1" >/dev/null 2>&1 || return 0
    ln -sf "$(command -v "$1")" "$LOCAL_BIN/$2"
}

get_distro() {
    DISTRO=""

    if [ -r /etc/os-release ]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        case "$DISTRO_ID" in
            ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian)
                DISTRO="debian" ;;
            arch|cachyos|manjaro|endeavouros|garuda|artix)
                DISTRO="arch" ;;
            fedora)
                DISTRO="fedora" ;;
            centos|rhel|rocky|almalinux|ol)
                DISTRO="rhel" ;;
            opensuse*|sles|sled)
                DISTRO="opensuse" ;;
            alpine)
                DISTRO="alpine" ;;
            *)
                error "Error: Unsupported distro: $DISTRO_ID"
                exit 1
                ;;
        esac
        ;;
    else
        echo "unknown-linux"
    fi

    echo "$DISTRO"
}

# Detect Linux distribution family
get_os() {
    OS="$(uname -s)"
    case "$OS" in
        Darwin)
            echo "macos"
            ;;
        Linux)
            OS="$(get_distro)"
            ;;
        *)
            echo "unknown"
            ;;
    esac

    success "Detected: $OS"
}

# Get dependencies for the current distribution
deps_for_distro() {
    case "$DISTRO" in
        debian)   echo "$DEBIAN_DEPS" ;;
        macos)    echo "$MACOS_DEPS" ;;
        arch)     echo "$ARCH_DEPS" ;;
        fedora)   echo "$FEDORA_DEPS" ;;
        alpine)   echo "$ALPINE_DEPS" ;;
    esac
}

# Update via system package manager
pkg_update() {
    case "$DISTRO" in
        debian)   sudo apt update && sudo apt upgrade -y ;;
        macos)    brew update && brew upgrade ;;
        arch)     sudo pacman -Syu --noconfirm ;;
        fedora)   sudo dnf upgrade -y ;;
        alpine)   sudo apk update && sudo apk upgrade ;;
    esac
}

# Install packages via system package manager
pkg_install() {
    case "$DISTRO" in
        debian)   sudo apt-get install -y "$@" ;;
        macos)    brew install "$@" ;;
        arch)     sudo pacman -S --noconfirm "$@" ;;
        fedora)   sudo dnf install -y "$@" ;;
        alpine)   sudo apk add "$@" ;;
    esac
}

# Install fonts
install_font() {
    local url="$1"
    local name="$2"

    if [ ! -d "$FONTS/$name" ]; then
        info "Installing $name..."
        curl -LO "$url"
        mkdir -p "$FONTS/$name"
        unzip "./${url##*/}" -d "$FONTS/$name"
        rm "./${url##*/}"
        fc-cache -fv

        success "$name installation successful"
    else
        info "$name already installed"
    fi
}

# Setup SSH keys
generate_ssh_key() {
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    success "--- $1 public key start ---"
    cat ~/.ssh/id_ed25519_$1.pub
    success "--- $1 public key end ---"

    eval "$(ssh-agent -s)"
    sleep 1
    ssh-add ~/.ssh/id_ed25519_$1
}

# Run main script
# ================================================
main
