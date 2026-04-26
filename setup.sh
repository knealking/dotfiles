#!/bin/sh

# Update system packages
echo "Updating system packages..."
sleep 2
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "Installing dependencies..."
sleep 2
sudo apt install build-essential git zsh stow -y

# Install lazygit
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
echo "Installing Neovim..."
sleep 2
curl -Lo nvim.tar.gz \
    "https://github.com/neovim/neovim/releases/latest/download/\
nvim-linux-x86_64.tar.gz"
sudo tar -C /usr/local/bin -xzf nvim.tar.gz nvim
sudo rm nvim.tar.gz

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL \
    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install zsh plugins
echo "Installing zsh plugins..."
sleep 2
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Stow dotfiles
echo "Stowing dotfiles..."
cd ~/dotfiles
stow .
