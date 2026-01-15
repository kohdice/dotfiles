{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.packages =
    with pkgs;
    [
      # Core tools
      bat
      curl
      dust
      eza
      fd
      fzf
      htop
      jq
      ripgrep
      tree

      # Git tools
      delta
      ghq
      lazygit

      # Terminal tools
      fastfetch
      navi
      starship
      tmux
      yazi
      zoxide

      # Development tools
      devcontainer
      protobuf
      typos

      # AI tools
      amp
      claude-code
      codex
      opencode

      # Build tools
      tree-sitter

      # GUI Apps
      vscode
    ]
    ++ lib.optionals isLinux [
      # Development tools
      docker

      # GUI Apps
      ghostty
      google-chrome
      slack
    ];
}
