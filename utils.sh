#!/usr/bin/env bash


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

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

# Setup SSH keys
generate_ssh_key() {
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    echo ""
    success "--- $1 public key start ---"
    cat ~/.ssh/id_ed25519_$1.pub
    success "--- $1 public key end ---"
    eval "$(ssh-agent -s)"
    sleep 1
    ssh-add ~/.ssh/id_ed25519_$1
}

if confirm "Install Neovim?"; then
    info "Installing Neovim..."
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

if confirm "Set up SSH keys?"; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    generate_ssh_key "github"
    generate_ssh_key "gitlab"
fi

if confirm "Install lazygit?"; then
    info "Installing lazygit..."
    sleep 2
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    sudo tar -C /usr/local/bin -xzf lazygit.tar.gz lazygit
    sudo rm lazygit.tar.gz
fi

if confirm "Install rustup?"; then
    info "Installing Rust..."
    sleep 2
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.bashrc
    rustup update
fi

if confirm "Install Yazi?"; then
    info "Installing Yazi..."
    sleep 2
    git clone https://github.com/sxyazi/yazi.git
    cd yazi
    cargo build --release --locked
    sudo mv target/release/ya target/release/yazi /usr/local/bin/
fi

if confirm "Install uv?" then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
