# Overlays entry point
# Usage in flake.nix:
#   nixpkgs.overlays = [ (import ./overlays) ];

final: prev:
{
  # Import all overlays
  # Each overlay is a function (final: prev: { ... })
}
// (import ./ai-tools.nix final prev)
