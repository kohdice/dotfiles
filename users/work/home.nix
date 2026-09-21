{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xan
    awscli2
    ssm-session-manager-plugin
    google-cloud-sdk
    gws
  ];
}
