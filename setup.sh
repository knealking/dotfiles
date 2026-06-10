#!/bin/sh

# Setup SSH keys
generate_ssh_key() {
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    echo ""
    echo "=== $1 public key ==="
    cat ~/.ssh/id_ed25519_$1.pub
}

# Detect Linux distribution family
detect_distro() {
    if [ ! -f /etc/os-release ]; then
        echo "Error: /etc/os-release not found. Cannot detect distro."
        exit 1
    fi

    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_ID_LIKE="${ID_LIKE:-}"

    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian)
            DISTRO_FAMILY="debian" ;;
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
                    echo "Error: Unsupported distro: $DISTRO_ID"
                    exit 1
                    ;;
            esac
            ;;
    esac

    echo "Detected distro: $DISTRO_ID (family: $DISTRO_FAMILY)"
}

pkg_update() {
    case "$DISTRO_FAMILY" in
        debian)   sudo apt update && sudo apt upgrade -y ;;
        arch)     sudo pacman -Syu --noconfirm ;;
        fedora)   sudo dnf upgrade -y ;;
        rhel)     sudo dnf upgrade -y ;;
        opensuse) sudo zypper refresh && sudo zypper update -y ;;
        alpine)   sudo apk update && sudo apk upgrade ;;
    esac
}

pkg_install() {
    case "$DISTRO_FAMILY" in
        debian)   sudo apt install -y "$@" ;;
        arch)     sudo pacman -S --noconfirm "$@" ;;
        fedora)   sudo dnf install -y "$@" ;;
        rhel)     sudo dnf install -y "$@" ;;
        opensuse) sudo zypper install -y "$@" ;;
        alpine)   sudo apk add "$@" ;;
    esac
}

install_build_deps() {
    case "$DISTRO_FAMILY" in
        debian)   pkg_install build-essential git zsh stow curl ;;
        arch)     pkg_install base-devel git zsh stow curl ;;
        fedora)   pkg_install @development-tools git zsh stow curl ;;
        rhel)     pkg_install @development-tools git zsh stow curl ;;
        opensuse) pkg_install patterns-devel-base-devel_basis git zsh stow curl ;;
        alpine)   pkg_install build-base git zsh stow curl ;;
    esac
}

confirm() {
    printf "%s [Y/n] " "$1"
    read -r answer
    case "$answer" in
        [nN]|[nN][oO]) return 1 ;;
        *) return 0 ;;
    esac
}

# Detect distro before doing anything
detect_distro

# Update system packages
if confirm "Update system packages?"; then
    echo "Updating system packages..."
    sleep 2
    pkg_update
fi

# Install dependencies
if confirm "Install dependencies?"; then
    echo "Installing dependencies..."
    sleep 2
    install_build_deps
fi

# Install lazygit
if confirm "Install lazygit?"; then
    echo "Installing lazygit..."
    sleep 2
    LAZYGIT_VERSION=$(curl -s \
        "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | \grep -Po '"tag_name": *"v\K[^"]*')

    curl -Lo lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/\
v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"

    sudo tar -C /usr/local/bin -xzf lazygit.tar.gz lazygit
    sudo rm lazygit.tar.gz
fi

# Install Neovim
if confirm "Install Neovim?"; then
    echo "Installing Neovim..."
    sleep 2
    curl -Lo nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/latest/download/\
nvim-linux-x86_64.tar.gz"
    sudo tar -C /usr/local -xzf nvim.tar.gz --strip-components=1
    sudo rm nvim.tar.gz
fi

# Install Rust
if confirm "Install Rust (rustup)?"; then
    echo "Installing Rust..."
    sleep 2
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.bashrc
    rustup update
fi

# Install Yazi
if confirm "Install Yazi?"; then
    echo "Installing Yazi..."
    sleep 2
    git clone https://github.com/sxyazi/yazi.git
    cd yazi
    cargo build --release --locked
    sudo mv target/release/ya target/release/yazi /usr/local/bin/
    cd -
fi

# Stow dotfiles
if confirm "Stow dotfiles?"; then
    echo "Stowing dotfiles..."
    cd ~/dotfiles
    stow .
fi

if confirm "Set up SSH keys?"; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    generate_ssh_key "github"
    generate_ssh_key "gitlab"
fi

echo "Setup complete!"
