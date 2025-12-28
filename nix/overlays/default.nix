# Overlays entry point
# Usage in flake.nix:
#   nixpkgs.overlays = [ (import ./nix/overlays) ];
#
# Or individual overlays:
#   nixpkgs.overlays = [ (import ./nix/overlays).ai-tools ];

final: prev:
{
  # Import all overlays
  # Each overlay is a function (final: prev: { ... })
}
// (import ./ai-tools.nix final prev)
