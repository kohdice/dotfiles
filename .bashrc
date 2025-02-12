### Aliases ###

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# General
alias cl='clear'

# Directory Navigation
alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../../'

# ls with colors and different formats
export CLICOLOR=1
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS -p'
alias ll='ls $LS_OPTIONS -hlp'
alias la='ls $LS_OPTIONS -pA'
alias lla='ls -hlpA'

# Bash configuration
alias bashcfg='nvim ~/.bashrc'
alias bashreload='source ~/.bashrc'

# Neovim
alias v='nvim'
alias view='nvim -R'

# Git
alias g='git'
alias gitcfg='nvim ~/.gitconfig'

# Docker
alias d='docker'
alias dc='docker compose'
alias dce='docker compose exec'
alias dcu='docker compose up'
alias dcub='docker compose up --build'
alias dcud='docker compose up -d'
alias dcudb='docker compose up -d --build'

# Terraform
alias tf='terraform'

# Ghostty
alias gstcfg='nvim ~/.config/ghostty/config'

# Lazygit
alias lg='lazygit'

### Git Prompt Settings ###

if [ -f ~/.git-completion.sh ]; then
    source ~/.git-completion.sh
fi

if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi

export GIT_PS1_SHOWDIRTYSTATE=true
export GIT_PS1_SHOWSTASHSTATE=true
export GIT_PS1_SHOWUNTRACKEDFILES=true
export GIT_PS1_SHOWUPSTREAM='auto'
export GIT_PS1_SHOWCOLORHINTS=true

PS1='[\u@\h]:\w$(__git_ps1 "(%s)")\$ '
