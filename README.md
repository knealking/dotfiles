# Dotfiles

## Quickstart

stable:

```bash
curl -fsSL https://raw.githubusercontent.com/knealking/dotfiles/main/install.sh | bash
```

dev:

```bash
curl -fsSL https://raw.githubusercontent.com/knealking/dotfiles/dev/install.sh | bash
```

## Set zsh as your default shell

```sh
chsh -s $(which zsh)
```

## Linutil

Install utilities with [linutil](https://github.com/ChrisTitusTech/linutil)

```bash
curl -fsSL https://christitus.com/linux | sh
```

## Keybindings

| Key      | Action                                              |
| -------- | --------------------------------------------------- |
| `Ctrl+R` | Fuzzy history search (fzf)                          |
| `Ctrl+T` | Fuzzy file search including hidden files (fzf + fd) |
| `Ctrl+F` | Fuzzy file search excluding hidden files (fzf + fd) |

## Plugins

Managed without a third-party plugin manager. Plugins are cloned into `.local/share/zsh/plugins/` on first launch.

- [pure prompt](https://github.com/sindresorhus/pure.git)
- [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [fzf](https://github.com/junegunn/fzf.git)

To update all plugins:

```sh
zplugin-update
```
