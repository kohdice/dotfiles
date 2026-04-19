{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Development tools
    docker

    # GUI Apps
    ghostty
    google-chrome
  ];
}
