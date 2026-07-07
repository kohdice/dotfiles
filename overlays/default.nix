# Overlay aggregator: each entry is a standard `final: prev:` overlay, so
# nixpkgs composes them with its usual fixed-point semantics. Flake inputs
# are passed to each overlay file directly instead of being injected into
# the package set.
{ inputs }:

[
  # TODO: Remove this overlay after nix-darwin#1819 or an equivalent fix lands.
  (import ./nixos-render-docs.nix inputs)
  (import ./llm-agents.nix inputs)
]
