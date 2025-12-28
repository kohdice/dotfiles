{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime & Package Manager
    uv # Python version and package management

    # Linter & Formatter
    ruff

    # LSP
    pyright
  ];
}
