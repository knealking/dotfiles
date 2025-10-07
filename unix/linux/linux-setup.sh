#!/usr/bin/env bash

# echo "Updating package lists..."
# sudo apt update
# sudo apt upgrade -y

echo "Installing packages..."
packages=("git" "curl" "wget" "zsh" "neovim" "tmux" "fzf" "lazygit")

# Loop through packages and install each one
for package in "${packages[@]}"; do
    echo "Press Enter to install $package..."
    read -r
    sudo apt install -y "$package"
done

zsh

echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Ghostty..."
snap install --classic ghostty
