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

# Bash configuration
alias bashreload="source ~/.bashrc"
alias bashcfg="nvim ~/.bashrc"

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

# Shell options
shopt -s histappend
shopt -s checkwinsize
shopt -s extglob
shopt -s globstar
shopt -s checkjobs

# Starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash --cmd cd)"
fi

### fzf ###

# fzf history search (Ctrl+R)
fzf-history() {
  local selected
  selected=$(history | tac | awk '{$1=""; print substr($0,2)}' | fzf --query "$READLINE_LINE" --reverse)
  READLINE_LINE="$selected"
  READLINE_POINT=${#READLINE_LINE}
}
bind -x '"\C-r": fzf-history'

# fzf ghq (Ctrl+T)
ghq-fzf() {
  local src
  src=$(ghq list | fzf --preview "bat --color=always --style=grid $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    cd "$(ghq root)/$src" || return
  fi
}
bind -x '"\C-t": ghq-fzf'

# fzf cd to recent directory (Ctrl+F)
fzf-zoxide() {
  local selected
  selected=$(zoxide query -l | fzf --reverse)
  if [ -n "$selected" ]; then
    cd "$selected" || return
  fi
}
bind -x '"\C-f": fzf-zoxide'
