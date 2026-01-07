#!/bin/bash

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install dev tools
sudo apt install build-essential -y

# Install git
sudo apt install git -y

# Install libsecret
sudo apt install build-essential libsecret-1-0 libsecret-1-dev libglib2.0-dev -y
sudo make --directory=/usr/share/doc/git/contrib/credential/libsecret

# Create symlink for git-credential-libsecret
sudo ln -s /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret /usr/local/bin/git-credential-libsecret

# Configure git to use libsecret for credential storage
git config --global credential.helper libsecret

# Install lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
sudo mkdir -p /opt/lazygit
sudo tar -C /opt/lazygit -xzf lazygit.tar.gz
sudo rm lazygit.tar.gz
echo 'export PATH="$PATH:/opt/lazygit"' >> ~/.zshrc

# Install Neovim
curl -Lo nvim.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim.tar.gz
sudo rm nvim.tar.gz
echo 'export PATH="$PATH:/opt/nvim/bin"' >> ~/.zshrc

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# Install Starship prompt
curl -sS https://starship.rs/install.sh | sh

