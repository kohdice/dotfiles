{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # LSP & Formatter
    taplo
  ];
}
