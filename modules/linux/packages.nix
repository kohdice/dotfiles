{ pkgs, ... }:

{
  home.packages = with pkgs; [
    docker
    ghostty
    google-chrome
  ];
}
