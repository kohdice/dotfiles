{ pkgs, ... }:

{
  home.packages = with pkgs; [
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
    starship
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
    agent-browser
    claude-code
    codex

    # Build tools
    gnumake
    tree-sitter
  ];
}
