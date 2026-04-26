#!/bin/sh

# DotFiles Installer
# -----------------
# This script:
# - Creates symlinks from $HOME to dotfiles in $HOME/dotfiles
# - Installs essential MacOS software
# - Sets up Homebrew packages and applications
# - Configures development environments (VS Code)

# Functions
generate_ssh_key <label>

# Install Xcode command line tools
echo "Installing Xcode Command Line Tools..."
xcode-select --install

echo ""
echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

echo ""
echo "Restore dotfiles using stow..."
stow .

# Run the Homebrew Script
./installer.sh

# Set up SSH keys for GitHub
echo ""
echo "Setting up SSH keys for GitHub..."
if test -d ~/.ssh/; then
    echo "Removing old .ssh folder..."
    sudo rm -rf ~/.ssh/
fi

echo ""
echo "Generating new SSH key..."
generate_ssh_key "GitHub"
generate_ssh_key "GitLab"

echo "Installation Complete!"

# Function Definitions
# -------------------------
generate_ssh_key() {
    echo ""
    echo "--- $1 public key ---"
    ssh-keygen -t ed25519 -C "$1" -f ~/.ssh/id_ed25519_$1 -N ""
    cat ~/.ssh/id_ed25519_$1.pub
}
