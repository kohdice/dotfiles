{ pkgs, ... }:

let
  direnvPackage =
    if pkgs.stdenv.isDarwin then
      pkgs.direnv.overrideAttrs (_: {
        # TODO: Remove this override after the upstream zsh integration check
        # no longer hangs under nix-daemon builds on Darwin.
        doCheck = false;
      })
    else
      pkgs.direnv;
in

{
  programs.direnv = {
    enable = true;
    package = direnvPackage;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };
}
