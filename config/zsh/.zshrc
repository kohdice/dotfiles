### Aliases ###

# General
alias cl="clear"

# Directory Navigation
alias ..2="cd ../.."
alias ..3="cd ../../.."
alias ..4="cd ../../../../"

# Enhanced ls or eza
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --icons --git"
  alias la="eza -A --icons --git"
  alias ll="eza -l -g --icons"
  alias lla="eza -l -a --icons"
else
  alias ls="ls -p -G"
  alias la="ls -A"
  alias ll="ls -l"
  alias lla="ll -A"
fi

# Zsh configuration
alias zshreload="source ~/.zshrc"
alias zshcfg="nvim ~/.zshrc"

# Neovim
alias v="nvim"
alias view="nvim -R"

# Git
alias g="git"
alias gitcfg="nvim ~/.gitconfig"

# Docker
alias d="docker"
alias dc="docker compose"
alias dce="docker compose exec"
alias dcu="docker compose up"
alias dcub="docker compose up --build"
alias dcud="docker compose up -d"
alias dcudb="docker compose up -d --build"

# Terraform
alias tf="terraform"

# Ghostty
alias gstcfg="nvim ~/.config/ghostty/config"

# Lazygit
alias lg="lazygit"

### Settings ###

# Zsh Options
setopt no_beep               # Disable beep sound
setopt auto_pushd            # Automatically push directories onto the stack
setopt pushd_ignore_dups     # Ignore duplicate directories in stack
setopt hist_ignore_dups      # Ignore duplicate commands in history
setopt share_history         # Share history between sessions
setopt inc_append_history    # Save history immediately

# Starship Prompt
eval "$(starship init zsh)"

### fzf ###

# fzf history
fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history

# cdr setup
if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
  autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
  add-zsh-hook chpwd chpwd_recent_dirs
  zstyle ':completion:*' recent-dirs-insert both
  zstyle ':chpwd:*' recent-dirs-default true
  zstyle ':chpwd:*' recent-dirs-max 1000
fi

# fzf cdr
fzf-cdr() {
  local selected_dir=$(cdr -l | awk '{ print $2 }' | fzf --reverse)
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N fzf-cdr
bindkey '^f' fzf-cdr

# fzf ghq
ghq-fzf() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=grid $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^t' ghq-fzf
