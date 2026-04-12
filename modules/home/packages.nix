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
      zoxide

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

      # Development tools
      devcontainer
      just
      podman
      protobuf
      typos

      # AI tools
      agent-browser
      claude-code
      codex

      # Build tools
      gnumake
      tree-sitter
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
