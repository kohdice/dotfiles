{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core tools
    bat
    curl
    dust
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
    tmux
    yazi

    # Development tools
    devcontainer
    podman
    podman-desktop
    typos

    # Communication
    slack
    zoom-us

    # AI tools
    claude-code
    codex
    herdr

    # Build tools
    gnumake
    tree-sitter
  ];
}
