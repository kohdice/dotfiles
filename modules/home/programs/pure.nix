{ lib, pkgs, ... }:

{
  home.packages = [ pkgs.pure-prompt ];

  programs.zsh.initContent = lib.mkAfter ''
    PURE_GIT_PULL=1
    PURE_CMD_MAX_EXEC_TIME=2

    autoload -Uz promptinit
    promptinit
    prompt pure
  '';
}
