# Pin nixos-render-docs to the last known compatible nixpkgs revision while
# nix-darwin still passes removed manual HTML flags.
inputs: final: prev:
let
  pinnedPkgs = import inputs.nixpkgs-nixos-render-docs {
    inherit (prev.stdenv.hostPlatform) system;
    config = prev.config or { };
  };
in
{
  nixos-render-docs = pinnedPkgs.nixos-render-docs;
}
