#!/bin/bash

DEBIAN_DEPS="build-essential libssl-dev git zsh stow curl wget python3 python3-venv"
ARCH_DEPS="base-devel git zsh stow curl"
FEDORA_DEPS="@development-tools git zsh stow curl"
ALPINE_DEPS="build-base git zsh stow curl"

ZSH_PLUGINS=("zsh-autosuggestions" "zsh-syntax-highlighting")
TMUX_PLUGINS=("tpm" "catppuccin")

# Setup SSH keys
generate_ssh_key() {
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    echo ""
    echo "--- $1 public key start ---"
    cat ~/.ssh/id_ed25519_$1.pub
    echo "--- $1 public key end ---"
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

deps_for_distro() {
    case "$DISTRO_FAMILY" in
        debian)   echo "$DEBIAN_DEPS" ;;
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

zsh_plugin_repo() {
    case "$1" in
        zsh-autosuggestions)     echo "https://github.com/zsh-users/zsh-autosuggestions.git" ;;
        zsh-syntax-highlighting) echo "https://github.com/zsh-users/zsh-syntax-highlighting.git" ;;
    esac
}

install_zsh_plugins() {
    for plugin in "${ZSH_PLUGINS[@]}"; do
        if confirm "Install zsh plugin: $plugin?"; then
            git clone "$(zsh_plugin_repo "$plugin")" ~/.oh-my-zsh/plugins/"$plugin"
        fi
    done
}

tmux_plugin_repo() {
    case "$1" in
        tpm)        echo "https://github.com/tmux-plugins/tpm" ;;
        catppuccin) echo "https://github.com/catppuccin/tmux.git" ;;
    esac
}

tmux_plugin_branch() {
    case "$1" in
        catppuccin) echo "v2.3.0" ;;
    esac
}

install_tmux_plugins() {
    for plugin in "${TMUX_PLUGINS[@]}"; do
        if confirm "Install tmux plugin: $plugin?"; then
            branch="$(tmux_plugin_branch "$plugin")"
            if [ -n "$branch" ]; then
                git clone -b "$branch" "$(tmux_plugin_repo "$plugin")" ~/.tmux/plugins/"$plugin"
            else
                git clone "$(tmux_plugin_repo "$plugin")" ~/.tmux/plugins/"$plugin"
            fi
        fi
    done
}


# Detect distro before doing anything
detect_distro

if confirm "Update system packages?"; then
    echo "Updating system packages..."
    sleep 2
    pkg_update
fi

if confirm "Install dependencies? ($(deps_for_distro))"; then
    echo "Installing dependencies..."
    sleep 2
    install_build_deps
fi

if confirm "Install Oh My Zsh?"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    install_zsh_plugins
fi

if confirm "Install tmux?"; then
    echo "Installing tmux..."
    sleep 2
    pkg_install tmux
    install_tmux_plugins
fi

if confirm "Install Neovim?"; then
    echo "Installing Neovim..."
    sleep 2
    curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    sudo tar -C /usr/local -xzf nvim.tar.gz --strip-components=1
    sudo rm nvim.tar.gz
fi

if confirm "Install VSCode?"; then
    sudo apt install wget gpg &&
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    sudo apt install wget gpg &&
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    sudo tee /etc/apt/sources.list.d/vscode.sources << EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
    sudo apt update &&
    sudo apt install code
fi

if confirm "Stow dotfiles?"; then
    echo "Stowing dotfiles..."
    sleep 2
    stow . --adopt
fi

if confirm "Set up SSH keys?"; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    generate_ssh_key "github"
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519_github

    generate_ssh_key "gitlab"
    ssh-add ~/.ssh/id_ed25519_gitlab
fi

if confirm "Install Nerd Fonts?"; then
    echo "Installing Nerd Fonts..."
    sleep 2
    curl -Lo JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
    mkdir -p ~/.local/share/fonts/JetBrainsMono
    unzip ./JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
    rm ./JetBrainsMono.zip
    fc-cache -fv
fi

echo "Setup complete!"
