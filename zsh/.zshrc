##aliases

alias cl="clear"

alias ..2='cd ../..'
alias ..3='cd ../../..'
alias ..4='cd ../../../../'

alias ls="ls -p -G"
alias la="ls -A"
alias ll="ls -l"
alias lla="ll -A"

# Neovim
alias v="nvim"
alias view="nvim -R"

# .zshrc
alias zshreload='source ~/.zshrc'
alias zshconfig="nvim ~/.zshrc"

# git
alias g="git"

# docker
alias d='docker'
alias dc='docker-compose'
alias dcps='docker-compose ps'
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcudb='docker-compose up -d --build'
alias dce='docker-compose exec'
alias dcl='docker-compose logs'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dcbnc='docker-compose build --no-cache'
# with tmux
alias dcez='(){tmux select-pane -P "fg=default,bg=colour236"; docker-compose exec $1 zsh;tmux select-pane -P "fg=default,bg=default" }'


## settings

# No beep sound
setopt no_beep
# Automatic pushd when moving directories
setopt auto_pushd
# Ignore duplicates
setopt pushd_ignore_dups
# Same command as the previous one is not saved in the history
setopt hist_ignore_dups
# Share history with other zsh
setopt share_history
# Instantly save history
setopt inc_append_history

# History File Settings
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000


## peco
# Select commands executed in the past, bind to ctrl-r
function peco-select-history() {
  BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

# search a destination from cdr list
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':chpwd:*' recent-dirs-default true
    zstyle ':chpwd:*' recent-dirs-max 1000
    zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
fi

# Select directories that have been moved in the past, bind to ctrl-f
function peco-cdr () {
  local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | peco --prompt="cdr >" --query "$LBUFFER")"
  if [ -n "$selected_dir" ]; then
    BUFFER="cd `echo $selected_dir | awk '{print$2}'`"
    CURSOR=$#BUFFER
    zle reset-prompt
  fi
}
zle -N peco-cdr
bindkey '^f' peco-cdr

# zsh-syntax-highlighting
if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /root/tools/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

#powerlevel10k
source ~/powerlevel10k/powerlevel10k.zsh-theme
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
