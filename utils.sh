#!/usr/bin/env bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

main() {
    # install lazygit
    if [ ! -f /usr/local/bin/lazygit ]; then
        info "Installing lazygit..."
        sleep 2
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        sudo tar -C /usr/local/bin -xzf lazygit.tar.gz lazygit
        sudo rm lazygit.tar.gz
        success "lazygit installed successfully!"
    else
        info "lazygit already installed!"
    fi

    # install uv
    if [ ! -f "$HOME/.local/bin/uv" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        success "uv installed successfully!"
    else
        info "uv already installed!"
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
        sleep 2
        git clone https://github.com/sxyazi/yazi.git
        cd yazi
        cargo build --release --locked
        sudo mv target/release/ya target/release/yazi /usr/local/bin/
        success "yazi installed successfully!"
    else
        info "yazi already installed!"
    fi
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

main
