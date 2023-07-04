##aliases

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias cl='clear'

alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../../'

# ls
export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -hlrt'
alias la='ls $LS_OPTIONS -hlrta'
export CLICOLOR=1

# git
alias g='git'

# Start neovim with the following command
alias v='nvim'
alias view='nvim -R'

# Edit .bashrc with neovim
alias bashconfig='nvim ~/.bashrc'
# Reload .bashrc
alias bashreload='source ~/.bashrc'


## settings

if [ -f ~/.git-completion.sh ]; then
    source ~/.git-completion.sh
fi
if [ -f ~/.git-prompt.sh ]; then
    source ~/.git-prompt.sh
fi

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM='auto'
GIT_PS1_SHOWCOLORHINTS=true

PS1='[\u@\h]:\w$(__git_ps1 "(%s)")\$ '
