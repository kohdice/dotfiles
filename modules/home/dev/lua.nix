{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Runtime
    luajit

    # Formatter
    stylua

    # LSP
    lua-language-server
  ];
}
