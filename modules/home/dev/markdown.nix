{ pkgs, ... }:

{
  home.packages = with pkgs; [
    marksman
    markdownlint-cli2
  ];
}
