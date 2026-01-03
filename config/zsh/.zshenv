### XDG Base Directory ###
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

### History ###
export HISTFILE=~/.zsh_history
export HISTSIZE=10000
export SAVEHIST=10000

### Path ###

# Go
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Cargo
export PATH=$PATH:$HOME/.cargo/bin

# Bun
export PATH=$PATH:$HOME/.bun/bin

# Deno
export PATH=$PATH:$HOME/.deno/bin
