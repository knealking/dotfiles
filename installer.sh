#!/usr/bin/env zsh

# Helper to install apps from apps.txt
install_apps() <file>

echo ""
echo " --- Starting DotFiles Installer..."

# Install Homebrew if it isn't already installed
# ---------------------------------
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

# Update and clean up again for safe measure
# ---------------------------------
echo ""
echo " --- Updating Homebrew and cleaning up..."
brew update
brew upgrade
brew upgrade --cask
brew cleanup

# Install Jetbrains Mono font
# ---------------------------------
echo ""
echo " --- Installing Jetbrains Mono font..."
brew install --cask font-jetbrains-mono-nerd-font

# Install apps from apps.txt
# ---------------------------------
install_apps apps.txt

# Install tmux plugin manager
# ---------------------------------
echo ""
echo " --- Installing tmux plugin manager..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install tmux catppuccin theme
# ---------------------------------
echo ""
echo " --- Installing tmux catppuccin theme..."
mkdir -p ~/.tmux/plugins/catppuccin
git clone -b v2.3.0 https://github.com/catppuccin/tmux.git ~/.tmux/plugins/catppuccin

echo " --- Installation process completed."

# Function Definitions
# ---------------------------------
install_apps() {
    local file="$1"
    echo ""
    echo " --- Installing apps from $file..."
    while IFS= read -r app; do
        if [[ -n "$app" ]]; then
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
    done < "$file"
}

