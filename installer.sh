#!/usr/bin/env zsh

echo ""
echo "Starting DotFiles Installer..."

# Install Homebrew if it isn't already installed
if ! command -v brew &>/dev/null; then
    echo "Homebrew not installed. Installing Homebrew."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Attempt to set up Homebrew PATH automatically for this session
    if [ -x "/opt/homebrew/bin/brew" ]; then
        # For Apple Silicon Macs
        echo "Configuring Homebrew in PATH for Apple Silicon Mac..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

# Verify brew is now accessible
if ! command -v brew &>/dev/null; then
    echo "Failed to configure Homebrew in PATH. Please add Homebrew to your PATH manually."
    exit 1
fi

# Update Homebrew and Upgrade any already-installed formulae
brew update
brew upgrade
brew upgrade --cask
brew cleanup

# Git config name
echo ""
echo "Please enter your USERNAME for Git configuration:"
read git_user_name

# Git config email
echo ""
echo "Please enter your EMAIL for Git configuration:"
read git_user_email

# Set my git credentials
$(brew --prefix)/bin/git config --global user.name "$git_user_name"
$(brew --prefix)/bin/git config --global user.email "$git_user_email"

# Set up SSH keys for GitHub
if test -d ~/.ssh/; then
    echo "Removing old .ssh folder..."
    sudo rm -rf ~/.ssh/
fi

echo ""
echo "Generating ssh keys..."
ssh-keygen -t ed25519 -C "$git_user_email"
echo "Starting the ssh-agent in the background..."
eval "$(ssh-agent -s)"

echo ""
if ! test -f ~/.ssh/config; then
    echo "Config file does not exist. Creating config file..."
    touch ~/.ssh/config
    echo "Adding configuration to config file..."
    echo "Host github.com
 AddKeysToAgent yes
 UseKeychain yes
 IdentityFile ~/.ssh/id_ed25519" > ~/.ssh/config
    echo "Adding key to apple keychain..."
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi

echo ""
echo "Copying public key to clipboard..."
pbcopy < ~/.ssh/id_ed25519.pub
echo "Paste the key into GitHub. Press return after done:"
read

# Install Jetbrains Mono font
echo ""
echo "Installing Jetbrains Mono font..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"

# Update and clean up again for safe measure
brew update
brew upgrade
brew upgrade --cask
brew cleanup

# Enable three finger drag on trackpad
echo "Enabling three-finger-drag on trackpad..."
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
echo "TODO - Make sure to log out and log back in to for this take effect!"

# Read the file line by line and install each app/cask
while IFS= read -r app; do
    if [[ -n "$app" ]]; then  # Check if the line is not empty
        echo "Installing $app..."
        if brew list --cask "$app" &> /dev/null || brew list "$app" &> /dev/null; then
            echo "$app is already installed."
        else
            if brew install --cask "$app" &> /dev/null; then
                echo "$app installed successfully (as a cask)."
            elif brew install "$app" &> /dev/null; then
                echo "$app installed successfully."
            else
                echo "Failed to install $app."
            fi
        fi
    fi
done < "$1"


echo ""
echo "Installing tmux plugin manager..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo

echo "Installation process completed."
