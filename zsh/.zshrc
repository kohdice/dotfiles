### aliases ###

alias cl="clear"

alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../../"

alias ls="ls -p -G"
alias la="ls -A"
alias ll="ls -l"
alias lla="ll -A"

# eza
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --git"
  alias la="eza -A --icons --git"
  alias ll="eza -l -g --icons"
  alias lla="ll -a"
fi

# .zshrc
alias zshreload="source ~/.zshrc"
alias zshconfig="nvim ~/.zshrc"

# Neovim
alias v="nvim"
alias view="nvim -R"

# git
alias g="git"

# docker
alias d="docker"
alias dc="docker compose"
alias dce="docker compose exec"
alias dcu="docker compose up"
alias dcub="docker compose up --build"
alias dcud="docker compose up -d"
alias dcudb="docker compose up -d --build"

# Terraform
alias tf="terraform"

# lazygit
alias lg="lazygit"


### settings ###

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

### Path ###

# Go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# poetry
export PATH="$HOME/.local/bin:$PATH"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  autoload -Uz compinit && compinit
fi


### Starship ###
eval "$(starship init zsh)"


### fzf ###

# fzf history
function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

# cdr
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max 1000
fi

# fzf cdr
function fzf-cdr() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --reverse)
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-cdr
setopt noflowcontrol
bindkey '^f' fzf-cdr

# fzf ghq
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=grid $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^t' ghq-fzf
