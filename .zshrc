# nvim binary installed path
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
source <(fzf --zsh)  # -- zsh requires version 0.48.0 or higher

# Programs
alias e="$EDITOR"

# git aliases
alias gc='git clone'
alias gs='git status'
alias ga='git add'
alias gu='git pull'
alias gcm='git commit -m'
alias gp='git push'

# fzf opens the selected file in nvim
alias fnv='nvim $(fzf -m --preview="batcat --color=always {}")'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/nealking/.lmstudio/bin"
# End of LM Studio CLI section

# lazygit binary installed path
export PATH="$PATH:/opt/lazygit"

# local send path
export PATH="$PATH:/opt/LocalSend"

export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
