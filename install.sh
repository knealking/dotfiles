#!/bin/sh

# if [ -z "${BASH_VERSION:-}" ]; then
#     printf '%s\n' 'This installer requires Bash. Download it and run: bash install.sh' >&2
#     exit 1
# fi

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEBIAN_DEPS="build-essential git lazygit zsh curl wget python3 python3-venv eza \
    bat zoxide fd-find fzf ripgrep tmux libssl-dev alacritty"

MACOS_DEPS="xcode-select"

ARCH_DEPS="base-devel git zsh stow curl eza bat fd fzf ripgrep"
FEDORA_DEPS="@development-tools git zsh stow curl eza bat fd-find fzf ripgrep"
ALPINE_DEPS="build-base git zsh stow curl exa bat fd-find fzf ripgrep"

LOCAL_BIN="$HOME/.local/bin"
ZCACHE="$HOME/.cache/zsh"
FONTS="$HOME/.local/share/fonts"
STATE="$HOME/.local/state/zsh"
NSSDB="$HOME/.pki/nssdb"
ALACRITTY_THEMES="$HOME/.local/state/alacritty/themes"

main() {
    # Detect distro before doing anything
    detect_distro

    check_dir "$LOCAL_BIN"
    check_dir "$ZCACHE"
    check_dir "$STATE"
    check_dir "$NSSDB"

    # Update system
    info "Updating system packages..."
    pkg_update
    success "Update successful"

    # Install defined packages
    info "Installing dependencies..."
    install_build_deps
    success "Dependencies installation successful"

    info "Linking utilities..."
    # ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
    # ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"

    info "Configuring zsh..."
    configure_zsh
    success "Zsh configuration successful"

    # Install alacritty themes
    info "Checking alacritty themes..."
    if [ ! -d "$ALACRITTY_THEMES" ]; then
        info "Alacritty themes not found. Cloning repository..."
        mkdir -p "$ALACRITTY_THEMES"
        git clone --depth=1 https://github.com/alacritty/alacritty-theme "$ALACRITTY_THEMES"
    else
        info "Alacritty themes already exist!"
    fi


    install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" "JetBrainsMono"
    install_font "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" "Meslo"

    # Install nvim
    if [ ! -f /usr/local/bin/nvim ]; then
        info "Installing Neovim..."
        sleep 2
        curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        sudo tar -C /usr/local -xzf nvim.tar.gz --strip-components=1
        sudo rm nvim.tar.gz
        success "Neovim installed successfully!"
    fi
    info "Neovim already installed!"

    # Install Vscode
    if [ ! -f /usr/bin/code ]; then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
        echo 'deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

        sudo apt update && sudo apt install code
        success "Installed VScode successfully!"
    else
        info "VScode already installed!"
    fi

    if confirm "Configure linux cac?"; then
        info "Setting up linux cac..."
        configure_cac
    fi

    if confirm "Set up SSH keys?"; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        generate_ssh_key "github"
        generate_ssh_key "gitlab"
    fi

    # install uv
    if [ ! -f "$HOME/.local/bin/uv" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        success "uv installed successfully!"
    else
        info "uv already installed!"
    fi

    if [ ! -f "$(uv tool dir)/pwndbg/share/pwndbg/gdbinit.py" ]; then
        uv tool install git+https://github.com/pwndbg/pwndbg
        echo "source $(uv tool dir)/pwndbg/share/pwndbg/gdbinit.py" >> ~/.gdbinit
        success "pwndbg installed successfully!"
    else
        info "pwndgb already installed!"
    fi

    # install rustup
    if [ ! -f "$HOME/.cargo/bin/rustup" ]; then
        info "Installing Rust..."
        sleep 2
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
        source ~/.bashrc
        rustup update

        success "rustup installed successfully!"
    else
        info "rustup already installed!"
    fi

    # install yazi
    if [ ! -f "/usr/local/bin/yazi" ]; then
        info "Installing Yazi..."
        curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
        sudo apt update && sudo apt install yazi

        success "yazi installed successfully!"
    else
        info "yazi already installed!"
    fi

    if confirm "Link dotfiles to home directory?"; then
        info "Linking dotfiles..."
        git clone --depth=1 https://github.com/knealking/dotfiles.git ~/dotfiles
        cd dotfiles && ./dotmate.py
        success "Linking dotfiles successful"
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

check_dir () {
    if [ ! -d "$1" ]; then
        info "Creating dir $1..."
        mkdir -p -- "$1"
    else
        info "$1 exists"
    fi
}

# Detect Linux distribution family
detect_distro() {
    if [ ! -f /etc/os-release ]; then
        error "Error: /etc/os-release not found. Cannot detect distro."
        exit 1
    fi

    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"

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
            error "Error: Unsupported distro: $DISTRO_ID"
            exit 1
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
    if [ -z "${XDG_CONFIG_HOME:-}" ]; then
        echo 'export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"' | sudo tee -a /etc/zsh/zshenv >/dev/null
        export XDG_CONFIG_HOME="$HOME/.config"

        success "XGD_CONFIG_HOME set successfully!"
    else
        info "XGD_CONFIG_HOME already set!"
    fi

    if [ -z "${ZDOTDIR:-}" ]; then
        echo 'export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"' | sudo tee -a /etc/zsh/zshenv >/dev/null
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

        success "ZDOTDIR set successfully!"
    else
        info "ZDOTDIR already set!"
    fi

    info "Default shell to zsh..."
    chsh -s "$(which zsh)"
}

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

configure_cac() {
    certutil -N -d sql:$HOME/.pki/nssdb --empty-password

    # run jdjaxon/linux_cac script
    curl -fsSL https://raw.githubusercontent.com/jdjaxon/linux_cac/main/cac_setup.sh | sudo bash

    modutil -dbdir sql:$HOME/.pki/nssdb/ \
        -add "CAC Module" \
        -libfile /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
}

main
