# zsh

Powerful but minimal zsh configuration.

## Dependencies

### Arch

```sh
paru -S zsh neovim eza bat fd fzf zoxide starship ripgrep
```

### Ubuntu

```sh
sudo apt install zsh neovim eza bat fd-find fzf ripgrep
# install zoxide and starship separately
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
curl -sS https://starship.rs/install.sh | sh
# Ubuntu installs bat and fd under different names — symlink them so everything works
ln -s $(which batcat) ~/.local/bin/bat
ln -s $(which fdfind) ~/.local/bin/fd
```

### macOS

```sh
brew install zsh neovim eza bat fd fzf zoxide starship ripgrep
```

## Setup

### 1. Clone the repo

```sh
git clone https://github.com/radleylewis/zsh ~/.config/zsh
```

### 2. Point zsh at the config directory

Add the following to `/etc/zsh/zshenv`:

```sh
if [[ -z "$XDG_CONFIG_HOME" ]]
then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -d "$XDG_CONFIG_HOME/zsh" ]]
then
    export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
fi
```

### 3. Set zsh as your default shell

```sh
chsh -s $(which zsh)
```

### 4. Create required directories

```sh
mkdir -p ~/.local/state/zsh   # history
mkdir -p ~/.cache/zsh         # completion cache
```

### 5. Start a new shell

Plugins are installed automatically on first launch via the built-in plugin manager.

## Plugins

Managed without a third-party plugin manager. Plugins are cloned into `$ZDOTDIR/plugins/` on first launch.

| Plugin                                                                                    | Purpose                         |
| ----------------------------------------------------------------------------------------- | ------------------------------- |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Syntax highlighting             |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)                   | Fish-style inline suggestions   |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Up/down arrow history filtering |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode)                                  | Vi keybindings                  |

To update all plugins:

```sh
zplugin-update
```

## Keybindings

| Key       | Action                                              |
| --------- | --------------------------------------------------- |
| `Ctrl+R`  | Fuzzy history search (fzf)                          |
| `Ctrl+T`  | Fuzzy file search including hidden files (fzf + fd) |
| `Ctrl+F`  | Fuzzy file search excluding hidden files (fzf + fd) |
| `Ctrl+→`  | Move forward one word                               |
| `Ctrl+←`  | Move backward one word                              |
| `↑` / `↓` | History search by prefix                            |
| `Ctrl+\`  | Toggle autosuggestions                              |

## Starship Config

Included in the repo at [`starship.toml`](./starship.toml) and loaded automatically via `STARSHIP_CONFIG` in `.zshenv`. Requires a [Nerd Font](https://www.nerdfonts.com) in your terminal.
