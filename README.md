# Dotfiles

## Setup

Run dependencies setup script:

```sh
./setup
```

Install oh-my-zsh:

```bash
sh -c "$(curl -fsSL \
    https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Install zsh plugins

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
```

### Setup options

- `--adopt` only do the adopt option
