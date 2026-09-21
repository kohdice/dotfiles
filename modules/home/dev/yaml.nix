{ pkgs, ... }:

{
  home.packages = with pkgs; [
    yamlfmt
    yaml-language-server
  ];
}
