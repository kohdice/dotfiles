set fish_greeting ""

set -gx TERM xterm-256color

## theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# Hydro
set -g hydro_color_git F8A900
set -g hydro_multiline true


## aliases
alias cl clear

alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"

alias ..2 "cd ../.."
alias ..3 "cd ../../.."
alias ..4 "cd ../../../../"

# eza
if type -q eza
    alias ll "eza -l -g --icons"
    alias lla "ll -a"
end

# git
alias g git

# fish
alias fishconfig "nvim  ~/.config/fish/config.fish"
alias fishreload "source  ~/.config/fish/config.fish"

# Neovim
command -qv nvim && alias vim nvim
alias v nvim
alias view "nvim -R"

# docker
alias d docker
alias dc docker-compose
alias dcu "docker-compose up"
alias dcub "docker-compose up --build"
alias dcud "docker-compose up -d"
alias dcudb "docker-compose up -d --build"
alias dce "docker-compose exec"

# Terraform
alias tf terraform

# lazygit
alias lg lazygit


## Path
set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# Homebrew
set PATH /opt/homebrew/bin $PATH

# Go
set -x GOPATH $HOME/go
set -x PATH $PATH $GOPATH/bin

# pyenv
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - | source

# volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

# fzf
set -g FZF_PREVIEW_FILE_CMD "bat --style=numbers --color=always --line-range :500"
set -g FZF_LEGACY_KEYBINDINGS 0
