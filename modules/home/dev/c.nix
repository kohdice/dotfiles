{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Compiler
    clang

    # LSP & Formatter
    clang-tools # clangd, clang-format

    # Linter (Makefile)
    checkmake

    # Debugger
    lldb # LLVM debugger
  ];
}
