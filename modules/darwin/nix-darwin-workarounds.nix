{
  inputs,
  pkgs,
  ...
}:

let
  darwinUninstaller = pkgs.callPackage "${inputs.nix-darwin}/pkgs/darwin-uninstaller" {
    path = inputs.nixpkgs-nixos-render-docs;
  };
in
{
  # TODO: Remove this workaround after nix-darwin#1819 or an equivalent fix lands.
  # The upstream darwin-uninstaller evaluates a nested Darwin system, so it must
  # use the same compatible nixos-render-docs source as the outer system.
  system.tools.darwin-uninstaller.enable = false;
  environment.systemPackages = [ darwinUninstaller ];
}
