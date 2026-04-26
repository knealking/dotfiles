#!/bin/sh

# Setup SSH keys
generate_ssh_key() {
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    echo ""
    echo "=== $1 public key ==="
    cat ~/.ssh/id_ed25519_$1.pub
}

# Update system packages
echo "Updating system packages..."
sleep 2
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo ""
echo "Installing dependencies..."
sleep 2
sudo apt install build-essential git zsh stow -y

# Install lazygit
echo ""
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

# Install Neovim
echo ""
echo "Installing Neovim..."
sleep 2
curl -Lo nvim.tar.gz \
    "https://github.com/neovim/neovim/releases/latest/download/\
nvim-linux-x86_64.tar.gz"
sudo tar -C /usr/local/bin -xzf nvim.tar.gz \
    --strip-components=2 nvim-linux-x86_64/bin/nvim
sudo rm nvim.tar.gz

# Install Yazi
echo ""
echo "Installing Yazi..."
sleep 2
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source ~/.bashrc
rustup update

git clone https://github.com/sxyazi/yazi.git
cd yazi
cargo build --release --locked
sudo mv target/release/ya target/release/yazi /usr/local/bin/

# Stow dotfiles
echo ""
echo "Stowing dotfiles..."
cd ~/dotfiles
stow .

echo ""
echo "Setting up SSH keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
generate_ssh_key "github"
generate_ssh_key "gitlab"

echo ""
echo "Setup complete!"
