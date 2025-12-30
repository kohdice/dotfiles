{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP
    neocmakelsp

    # Formatter & Linter
    cmake-format
    cmake-lint
  ];
}
