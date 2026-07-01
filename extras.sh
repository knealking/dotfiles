#!/bin/bash

confirm() {
    printf "%s [Y/n] " "$1"
    read -r answer
    case "$answer" in
        [nN]|[nN][oO]) return 1 ;;
        *) return 0 ;;
    esac
}

if confirm "Install zsh-plugins?"; then
    echo "Installing zsh plugins..."
    sleep 2
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
fi

if confirm "Install lazygit?"; then
    echo "Installing lazygit..."
    sleep 2
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    sudo tar -C /usr/local/bin -xzf lazygit.tar.gz lazygit
    sudo rm lazygit.tar.gz
fi

if confirm "Install rustup?"; then
    echo "Installing Rust..."
    sleep 2
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ~/.bashrc
    rustup update
fi

if confirm "Install Yazi?"; then
    echo "Installing Yazi..."
    sleep 2
    git clone https://github.com/sxyazi/yazi.git
    cd yazi
    cargo build --release --locked
    sudo mv target/release/ya target/release/yazi /usr/local/bin/
fi
