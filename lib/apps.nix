# App definitions for `nix run .#<app>`
{ inputs, system }:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  isDarwin = pkgs.stdenv.isDarwin;

  # Use the tools pinned by flake.lock instead of registry-resolved ones so
  # the version applying the configuration matches the one that built it.
  darwinRebuild = inputs.nix-darwin.packages.${system}.darwin-rebuild;
  homeManager = inputs.home-manager.packages.${system}.home-manager;

  buildScript =
    profile:
    if isDarwin then
      "nix build .#darwinConfigurations.${profile}.system"
    else
      "nix build .#homeConfigurations.${profile}.activationPackage";

  switchScript =
    profile:
    if isDarwin then
      "sudo ${darwinRebuild}/bin/darwin-rebuild switch --flake .#${profile}"
    else
      "${homeManager}/bin/home-manager switch --flake .#${profile}";

  mkApp = name: description: script: {
    type = "app";
    program = toString (pkgs.writeShellScript name script);
    meta.description = description;
  };
in
{
  build = mkApp "build" "Build kohdice profile" (buildScript "kohdice");
  build-work = mkApp "build-work" "Build work profile" (buildScript "work");
  switch = mkApp "switch" "Apply kohdice profile" (switchScript "kohdice");
  switch-work = mkApp "switch-work" "Apply work profile" (switchScript "work");
  update = mkApp "update" "Update all inputs and apply" ''
    nix flake update
    ${switchScript "kohdice"}
  '';
}
