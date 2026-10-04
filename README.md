# Dotfiles

## Quickstart

stable:

```bash
curl -fsSL https://raw.githubusercontent.com/knealking/dotfiles/main/install.sh | sh
```

dev:

```bash
curl -fsSL https://raw.githubusercontent.com/knealking/dotfiles/dev/install.sh | sh
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

Managed without a third-party plugin manager. Plugins are cloned into `$ZDOTDIR/plugins/` on first launch.

| Plugin                                                                                    | Purpose                       |
| ----------------------------------------------------------------------------------------- | ----------------------------- |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Syntax highlighting           |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)                   | Fish-style inline suggestions |

To update all plugins:

```sh
zplugin-update
```

### Linux Cac

```bash
mkdir -p $HOME/.pki/nssdb
certutil -N -d sql:$HOME/.pki/nssdb --empty-password
curl -fsSL https://raw.githubusercontent.com/jdjaxon/linux_cac/main/cac_setup.sh | sudo bash
modutil -dbdir sql:$HOME/.pki/nssdb/ \
    -add "CAC Module" \
    -libfile /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
```
