export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# Path to your Oh My Zsh Config
export ZSH="$HOME/.oh-my-zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"

# Custom editor
export EDITOR=nvim

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# GPG
export GPG_TTY=$(tty)

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/nealking/.docker/completions $fpath)
autoload -Uz compinit
compinit

# Programs
alias e="$EDITOR"

# custom aliases
alias ls='ls -h'
alias la='la -lh'
alias v='vim'
alias nv='nvim'

# git aliases
alias gc='git clone'
alias gs='git status'
alias ga='git add'
alias gu='git pull'
alias gcm='git commit -m'
alias gp='git push'

# fzf opens the selected file in nvim
alias fnv='nvim $(fzf -m --preview="batcat --color=always {}")'
