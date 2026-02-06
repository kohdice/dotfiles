# home-manager module for work profile
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # AWS
    awscli2
    ssm-session-manager-plugin

    # GCP
    google-cloud-sdk

    # mobile development
    cocoapods
    fastlane
  ];
}
