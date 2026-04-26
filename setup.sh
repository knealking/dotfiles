#!/bin/sh

# DotFiles Installer
# -----------------
# This script:
# - Creates symlinks from $HOME to dotfiles in $HOME/dotfiles
# - Installs essential MacOS software
# - Sets up Homebrew packages and applications
# - Configures development environments (VS Code)

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
./brew.sh

# Run the MacOS Script
./macOS.sh

echo "Installation Complete!"
