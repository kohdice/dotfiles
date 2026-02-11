{ ... }:

let
  aliases = import ../shell/aliases.nix;
  env = import ../shell/env.nix;
  paths = import ../shell/paths.nix;
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = aliases // {
      bashreload = "source ~/.bashrc";
    };
    sessionVariables = env;

    historySize = 10000;
    historyFileSize = 10000;
    historyControl = [
      "ignoredups"
      "erasedups"
    ];

    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    initExtra = ''
      # Enhanced ls (eza)
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

      # Starship
      if command -v starship >/dev/null 2>&1; then
        eval "$(starship init bash)"
      fi

      # zoxide
      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init bash --cmd cd)"
      fi

      ### fzf ###

      # fzf history search (Ctrl+R)
      fzf-history() {
        local selected
        selected=$(history | tac | awk '{$1=""; print substr($0,2)}' | fzf --query "$READLINE_LINE" --reverse)
        READLINE_LINE="$selected"
        READLINE_POINT=''${#READLINE_LINE}
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
    '';
  };

  home.sessionPath = paths;
}
