# Each overlay accepts flake inputs before its `final: prev:` arguments.
{ inputs }:

[
  (import ./llm-agents.nix inputs)
]
