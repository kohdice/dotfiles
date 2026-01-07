{ pkgs, config, ... }:

let
  aliases = import ../shell/aliases.nix;
  env = import ../shell/env.nix;
  paths = import ../shell/paths.nix;
in
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    shellAliases = aliases // {
      zshreload = "source ~/.zshrc";
    };
    sessionVariables = env;

    # Zsh options
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    initContent = ''
      # Zsh options
      setopt no_beep
      setopt auto_pushd
      setopt pushd_ignore_dups
      setopt inc_append_history

      # Starship
      eval "$(starship init zsh)"

      # zoxide
      eval "$(zoxide init zsh)"

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
      if [[ -n $(echo ''${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ''${^fpath}/cdr(N)) ]]; then
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
          BUFFER="cd ''${selected_dir}"
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
    '';
  };

  home.sessionPath = paths;
}
