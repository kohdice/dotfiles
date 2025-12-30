{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    lua
    luajit

    # Formatter
    stylua

    # LSP
    lua-language-server
  ];
}
