# Temporary workaround: nixpkgs-unstable dropped darwin support for `podman`
# (its meta.platforms became Linux-only ~2026-06), which breaks the Darwin
# builds. Pin podman/podman-desktop to nixos-25.11, which still ships darwin
# builds. Linux keeps using the unstable packages.
#
# Remove this overlay (and its entry in ./default.nix) once unstable restores
# darwin support; then `pkgs.podman` resolves normally again. Check with:
#   nix eval nixpkgs#podman.meta.platforms   # look for aarch64-darwin
final: prev:
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin (
  let
    # nixos-25.11 @ 0a47451 — podman 5.7.0, with darwin builds.
    pinned =
      import
        (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/0a47451dbe2082a660b88a79a83efdc8d85de445.tar.gz";
          sha256 = "0kk0gn9s6jh3hfczlw6k8c4hgg4685p2id9lbd7b5ky91832njyp";
        })
        {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
  in
  {
    inherit (pinned) podman podman-desktop;
  }
)
