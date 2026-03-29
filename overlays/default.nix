# Overlay aggregator
{ inputs }:

let
  overlayFiles = [
    ./marksman-fix.nix # TODO: Remove after nixpkgs fixes .NET wrapper for macOS
    ./llm-agents.nix
  ];

  baseOverlay = final: prev: {
    _llm-agents = inputs.llm-agents;
  };

  applyOverlays =
    final: prev: builtins.foldl' (acc: overlay: acc // (import overlay final prev)) { } overlayFiles;
in
[
  baseOverlay
  applyOverlays
]
