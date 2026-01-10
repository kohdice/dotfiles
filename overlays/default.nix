# Overlay aggregator
{ inputs }:

let
  overlayFiles = [
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
