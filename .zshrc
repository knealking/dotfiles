# Custom .zshrc managed by dotfiles

# Environment variables loaded by zsh before .zshrc.

# ---------- XDG base directories ----------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- PATH ----------
export PATH="$HOME/.local/bin:$PATH"

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

ZPLUGINDIR="$HOME/.local/share/zsh/plugins"
PURE_DIR="$ZPLUGINDIR/pure"

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# Shell behavior
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Enable interactive completion menu selection
zstyle ':completion:*' menu select

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# Zsh Prompt
# =========================================================

# Auto-clone Pure if it hasn't been cloned yet
if [ ! -d "$PURE_DIR" ]; then
    echo "Pure prompt not found. Cloning repository..."
    git clone --depth=1 https://github.com/sindresorhus/pure.git "$PURE_DIR"
fi

# Add Pure to the fpath function autoload directory
fpath+=("$PURE_DIR")
fpath+=($PURE_DIR)
autoload -U promptinit; promptinit

# optionally define some options
PURE_CMD_MAX_EXEC_TIME=10

zstyle :prompt:pure:path color white  # change the path color
zstyle :prompt:pure:git:stash show yes  # turn on git stash status
prompt pure

# ---------- Editor ----------
export EDITOR="nvim"

# ---------- GPG ----------
export GPG_TTY="$(tty 2>/dev/null || true)"

# ---------- Aliases ----------
alias ll='eza -lh --icons --git'

# Better cat
alias cat='bat'

# Better grep, diff, df
alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# Git
alias gcm='git commit -m'
alias gp='git push'
alias glog='PAGER="less -F -X" git log'  # -F quit if one screen, -X no clear on exit
alias dotfiles='git -C "$HOME/dotfiles"'

# Modular Config Files
# =========================================================

_zplugin_load() {
  local plugin_path="${ZPLUGINDIR}/${2}"
  if [[ ! -d "$plugin_path" ]]; then
    mkdir -p "$ZPLUGINDIR"
    echo "Installing ${2}..."
    git clone --depth=1 "https://github.com/${1}/${2}" "$plugin_path" \
      || { echo "ERROR: failed to install ${2}" >&2; return 1; }
  fi
  source "${plugin_path}/${2}.plugin.zsh"
}

zplugin-update() {
  local dir
  for dir in "${ZPLUGINDIR}"/*/; do
    echo "Updating ${dir:t}..."
    git -C "$dir" pull --ff-only
  done
}

_zplugin_load zsh-users zsh-autosuggestions
_zplugin_load zdharma-continuum fast-syntax-highlighting

# =========================================================
# Plugins end

# fzf configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix'  # strip-cwd-prefix removes the leading ./ from results

# Ctrl-T uses fd
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UI
export FZF_DEFAULT_OPTS='
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

export _FZF_PREVIEW_CMD='bat --color=always --style=plain,numbers --line-range=:500 {}'
export FZF_CTRL_T_OPTS="--preview '$_FZF_PREVIEW_CMD'"

# Ctrl+F: file picker excluding hidden files
_fzf_file_no_hidden() {
  local cmd result
  cmd="${FZF_DEFAULT_COMMAND/--hidden /}"
  result=$(eval "${cmd:-find . -type f}" | fzf --preview "$_FZF_PREVIEW_CMD") \
    && LBUFFER+="$result"  # LBUFFER is the text left of the cursor
  zle reset-prompt
}

zle -N _fzf_file_no_hidden

# Node / NVM
# =========================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# uv
# =========================================================
. "$HOME/.local/share/../bin/env"

# Cargo
# =========================================================
[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Linux homebrew
# =========================================================
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
