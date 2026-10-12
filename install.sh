#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Local paths for installation and configuration
LOCAL_BIN="$HOME/.local/bin"
DATA_HOME="$HOME/.local/share"
ZCACHE="$HOME/.cache/zsh"
STATE="$HOME/.local/state/zsh"
FONTS="$HOME/.local/share/fonts"

# Use the repo this script lives in when run as ./install.sh,
# otherwise (curl | bash) clone into ~/.dotfiles
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -d "$SCRIPT_DIR/.git" ]; then
    DOTFILES_DIR="$SCRIPT_DIR"
else
    DOTFILES_DIR="$HOME/.dotfiles"
fi

# Distribution-specific dependencies
DEBIAN_DEPS="zsh git curl wget unzip fontconfig tmux build-essential gcc clang stow bat \
    python3 python3-venv ripgrep fd-find eza zoxide"

MACOS_DEPS=""

ARCH_DEPS="base-devel git zsh stow curl unzip fontconfig eza bat fd fzf ripgrep"
FEDORA_DEPS="@development-tools git zsh stow curl unzip fontconfig eza bat fd-find fzf ripgrep"
ALPINE_DEPS="build-base git zsh stow curl unzip fontconfig eza bat fd fzf ripgrep"

main() {
    # Detect distro before doing anything
    get_os

    # Update system
    info "Updating system packages..."
    pkg_update
    success "Update successful"

    # Install defined packages
    info "Installing dependencies..."
    read -ra deps <<< "$(deps_for_distro)"
    pkg_install "${deps[@]}"
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
    if [ ! -d "$HOME/.fzf" ]; then
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
    if [ ! -d "$DOTFILES_DIR" ]; then
        info "Installing dotfiles..."
        git clone https://github.com/knealking/dotfiles.git "$DOTFILES_DIR"
        success "Dotfiles installed successfully!"
    else
        info "Dotfiles already installed at $DOTFILES_DIR"
    fi

    link_dotfiles
    set_default_shell

    success "Setup successful!"
    reload_shell
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
    local answer=""
    printf "%s [Y/n] " "$1"

    # Read from the terminal, not stdin: under `curl | bash` stdin is the script
    read -r answer < /dev/tty || true
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

# Get linux distro (sets DISTRO)
get_distro() {
    if [ ! -r /etc/os-release ]; then
        error "Error: Cannot detect distro, /etc/os-release not found"
        exit 1
    fi

    # shellcheck source=/dev/null
    DISTRO_ID="$(. /etc/os-release && echo "$ID")"
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
}

# Detect OS / Linux distribution family (sets DISTRO)
get_os() {
    case "$(uname -s)" in
        Darwin)
            DISTRO="macos"
            ;;
        Linux)
            get_distro
            ;;
        *)
            error "Error: Unsupported OS: $(uname -s)"
            exit 1
            ;;
    esac

    success "Detected: $DISTRO"
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
        *)
            error "Error: No package manager support for: $DISTRO"
            exit 1
            ;;
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
    local key="$HOME/.ssh/id_ed25519_$1"

    if [ -f "$key" ]; then
        info "SSH key for $1 already exists, skipping"
        return 0
    fi

    ssh-keygen -t ed25519 -C "$1" -f "$key" -N ""
    success "--- $1 public key start ---"
    cat "$key.pub"
    success "--- $1 public key end ---"

    eval "$(ssh-agent -s)"
    sleep 1
    ssh-add "$key"
}

# Symlink dotfiles into $HOME
link_dotfiles() {
    local stow_cmd="stow -d $DOTFILES_DIR -t $HOME ."
    local conflicts

    info "Linking dotfiles..."

    # Dry run first, back up any files that are in the way
    if ! conflicts="$(stow -n -d "$DOTFILES_DIR" -t "$HOME" . 2>&1)"; then
        backup_conflicts "$conflicts"
    fi

    # Anything still conflicting (e.g. files owned by another stow package)
    # has to be resolved manually
    if ! conflicts="$(stow -n -d "$DOTFILES_DIR" -t "$HOME" . 2>&1)"; then
        error "Existing files conflict with dotfiles:"
        printf "%s\n" "$conflicts"
        info "Move or delete the files above, then run:"
        info "    $stow_cmd && exec zsh -l"
        # Exit instead of reloading the shell, which would hide this output
        exit 1
    fi

    stow -d "$DOTFILES_DIR" -t "$HOME" .
    success "Dotfiles linked successfully!"
}

# Move files reported by a stow dry run into a timestamped backup directory
backup_conflicts() {
    local backup_dir
    local target

    backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

    # Conflict paths are relative to $HOME, e.g.
    #   * cannot stow ../repo/.bashrc over existing target .bashrc since ...
    #   * existing target is not owned by stow: .zshrc
    printf "%s\n" "$1" | sed -n \
        -e 's/^.*over existing target \(.*\) since .*$/\1/p' \
        -e 's/^.*existing target is not owned by stow: \(.*\)$/\1/p' \
        -e 's/^.*existing target is neither a link nor a directory: \(.*\)$/\1/p' |
    while IFS= read -r target; do
        [ -e "$HOME/$target" ] || [ -L "$HOME/$target" ] || continue
        mkdir -p "$backup_dir/$(dirname "$target")"
        mv "$HOME/$target" "$backup_dir/$target"
        info "Backed up ~/$target to $backup_dir/$target"
    done
}

# Make zsh the login shell
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
        info "zsh is already the default shell"
        return 0
    fi

    info "Setting zsh as the default shell..."
    sudo chsh -s "$zsh_path" "$USER"
    success "Default shell set to $zsh_path"
}

# Replace this script's process with a fresh zsh login shell. A script runs
# in a child process and can't modify the shell that launched it, so this is
# the closest thing to "reloading" it.
reload_shell() {
    # No terminal (CI, ssh without -t): just tell the user what to do
    if [ ! -t 1 ] || ! : < /dev/tty 2>/dev/null; then
        info "Log out and back in, or run: exec zsh -l"
        return 0
    fi

    info "Starting a fresh zsh shell..."
    # Under `curl | bash` stdin is the script pipe, attach zsh to the terminal
    exec zsh -l < /dev/tty
}

# Run main script
# ================================================
main
