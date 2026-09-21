{ pkgs, ... }:

{
  home.packages = with pkgs; [
    checkmake
    clang
    clang-tools # clangd, clang-format
    lldb
  ];
}
