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
      eza
      fd
      htop
      jq
      ripgrep
      tree

      # Git tools
      delta
      ghq
      lazygit
      peco

      # Terminal tools
      fastfetch
      yazi
      zoxide

      # Development tools
      protobuf
      typos

      # Build tools
      tree-sitter

      # Zsh plugins
      zsh-autosuggestions
      zsh-completions
      zsh-syntax-highlighting

      # GUI Apps
      discord
      ghostty
      google-chrome
      postman
      slack
      spotify
      vlc
      vscode
    ]
    ++ lib.optionals isDarwin [
      tableplus
      zoom-us
    ]
    ++ lib.optionals isLinux [
      docker
      mysql-workbench
      zoom-us
    ];
}
