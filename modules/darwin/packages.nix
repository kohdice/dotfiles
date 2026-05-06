{ pkgs, ... }:

{
  # macOS-only GUI applications.
  environment.systemPackages = with pkgs; [
    numi
    raycast
    vlc-bin
  ];
}
