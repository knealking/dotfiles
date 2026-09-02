# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Better cat
alias cat='bat'

# Better grep, diff, df
alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# Better cd
alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

# Git
alias gcm='git commit -m'
alias gp='git push'
alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
