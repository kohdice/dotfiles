# home-manager module for kohdice profile
{ pkgs, lib, ... }:

{
  # Profile-specific packages
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.discord
  ];
}
