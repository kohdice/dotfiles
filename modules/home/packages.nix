{ pkgs, lib, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isX86_64Linux = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
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
      claude-code
      codex

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
    ]
    ++ lib.optionals (isDarwin || isX86_64Linux) [
      # Discord (aarch64-linux not supported)
      discord
    ];
}
