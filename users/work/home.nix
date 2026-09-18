# home-manager module for work profile
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Tools
    xan

    # AWS
    awscli2
    ssm-session-manager-plugin

    # Google
    google-cloud-sdk
    gws
  ];
}
