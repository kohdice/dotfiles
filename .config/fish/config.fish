set fish_greeting ""

set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"

alias ..2 "cd ../.."
alias ..3 "cd ../../.."
alias ..4 "cd ../../../../"

alias cl clear

#git
alias g git
## lazygit
alias lg lazygit

# docker
alias d "docker"
alias dc "docker-compose"
alias dcud "docker-compose up -d"
alias dcudb "docker-compose up -d --build"
alias dce "docker-compose exec"

# Neovim
command -qv nvim && alias vim nvim
alias v nvim
alias view "nvim -R"

alias fishconfig "nvim  ~/.config/fish/config.fish"
alias fishreload "source  ~/.config/fish/config.fish"

# brew
set PATH /opt/homebrew/bin $PATH

# others
set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

set -g hydro_color_git F8A900
set -g hydro_multiline true

# pyenv
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - | source

# volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
