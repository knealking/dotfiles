# Dotfiles

## Setup

Run dependencies setup script:

```sh
./setup
```

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

## Utilities

Run the utilities script:

```bash
./utils.sh
``
