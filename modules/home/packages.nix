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
      fzf
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
      starship
      yazi
      zoxide

      # Development tools
      protobuf
      typos

      # Build tools
      tree-sitter

      # GUI Apps
      google-chrome
    ]
    ++ lib.optionals isDarwin [
      tableplus
      zoom-us
    ]
    ++ lib.optionals isLinux [
      docker
      ghostty
      mysql-workbench
      zoom-us
    ];
}
