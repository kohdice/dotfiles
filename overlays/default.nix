# Overlays entry point
# Usage in flake.nix:
#   overlays = [ (import ./overlays { inherit inputs; }) ];

{ inputs }:
final: prev:
let
  # Frequently updated packages from nixpkgs-latest
  latestPkgs = inputs.nixpkgs-latest.legacyPackages.${prev.system};
in
{
  # Import all overlays
}
// (import ./ai-tools.nix { inherit latestPkgs; } final prev)
