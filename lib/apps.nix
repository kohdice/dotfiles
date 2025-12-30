# App definitions for `nix run .#<app>`
{ nixpkgs, system }:

let
  pkgs = nixpkgs.legacyPackages.${system};
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  # Build configuration (default: kohdice)
  build = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "build" (
        if isDarwin then
          ''
            nix build .#darwinConfigurations.kohdice.system
          ''
        else
          ''
            nix build .#homeConfigurations.kohdice.activationPackage
          ''
      )
    );
    meta.description = "Build kohdice profile";
  };

  # Build configuration (work)
  build-work = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "build-work" (
        if isDarwin then
          ''
            nix build .#darwinConfigurations.work.system
          ''
        else
          ''
            nix build .#homeConfigurations.work.activationPackage
          ''
      )
    );
    meta.description = "Build work profile";
  };

  # Apply configuration (default: kohdice)
  switch = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "switch" (
        if isDarwin then
          ''
            darwin-rebuild switch --flake .#kohdice
          ''
        else
          ''
            home-manager switch --flake .#kohdice
          ''
      )
    );
    meta.description = "Apply kohdice profile";
  };

  # Apply configuration (work)
  switch-work = {
    type = "app";
    program = toString (
      pkgs.writeShellScript "switch-work" (
        if isDarwin then
          ''
            darwin-rebuild switch --flake .#work
          ''
        else
          ''
            home-manager switch --flake .#work
          ''
      )
    );
    meta.description = "Apply work profile";
  };
}
