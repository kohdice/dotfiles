{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Compiler
    gcc
    clang

    # LSP & Formatter
    clang-tools # clangd, clang-format

    # Linter (Makefile)
    checkmake

    # Debugger
    gdb
  ];
}
