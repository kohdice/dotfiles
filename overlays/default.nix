# Overlay aggregator: each entry is a standard `final: prev:` overlay, so
# nixpkgs composes them with its usual fixed-point semantics. Flake inputs
# are passed to each overlay file directly instead of being injected into
# the package set.
{ inputs }:

[
  (import ./llm-agents.nix inputs)
]
