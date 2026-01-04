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
  eval "$(starship init zsh)"
fi

# Zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
