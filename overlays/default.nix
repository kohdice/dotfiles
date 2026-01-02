# Overlays entry point
# Usage in mkSystem.nix:
#   overlays = [ (import ../overlays { inherit latestPkgs; }) ];

{ latestPkgs }:
final: prev:
{
  # Import all overlays
}
// (import ./ai-tools.nix { inherit latestPkgs; } final prev)
