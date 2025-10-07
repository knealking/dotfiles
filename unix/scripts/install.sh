#!/usr/bin/env zsh


# DotFiles Installer
# -----------------
# This script:
# - Creates symlinks from $HOME to dotfiles in $HOME/dotfiles
# - Installs essential MacOS software
# - Sets up Homebrew packages and applications
# - Configures development environments (VS Code)

# Install Xcode command line tools
xcode-select --install

echo "Complete the installation of Xcode Command Line Tools before proceeding."
echo "Press enter to continue..."
read

# dotfiles directory
dotfiledir="${HOME}/dotfiles"

# list of files/folders to symlink in ${homedir}
files=(.zshrc .zprofile)

# change to the dotfiles directory
echo "Changing to the ${dotfiledir} directory"
cd "${dotfiledir}" || exit

# create symlinks (will overwrite old dotfiles)
for file in "${files[@]}"; do
    echo "Creating symlink to $file in home directory."
    ln -sf "${dotfiledir}/.${file}" "${HOME}/.${file}"
done

# Run the Homebrew Script
./brew.sh

# Run the MacOS Script
./macOS.sh

echo "Installation Complete!"
