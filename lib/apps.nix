# App definitions for `nix run .#<app>`
{ inputs, system }:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

  # Use the tools pinned by flake.lock instead of registry-resolved ones so
  # the version applying the configuration matches the one that built it.
  darwinRebuild = inputs.nix-darwin.packages.${system}.darwin-rebuild;
  homeManager = inputs.home-manager.packages.${system}.home-manager;

  # Reference the evaluated flake by store path so build/switch work from any
  # working directory (a bare `.#` resolves against the caller's cwd).
  flakeRef = "${inputs.self}";

  setupSshKeys = import ./setupSshKeys.nix { inherit pkgs; };

  buildScript =
    profile:
    if isDarwin then
      "nix build ${flakeRef}#darwinConfigurations.${profile}.system"
    else
      "nix build ${flakeRef}#homeConfigurations.${profile}.activationPackage";

  switchScript =
    flake: profile:
    if isDarwin then
      "sudo ${darwinRebuild}/bin/darwin-rebuild switch --flake ${flake}#${profile}"
    else
      "${homeManager}/bin/home-manager switch --flake ${flake}#${profile}";

  # `nix flake update` must run against the writable checkout, so the update
  # apps require being invoked from the repository root and re-apply via the
  # freshly updated local flake instead of the store copy. writeShellApplication
  # sets errexit, so a failed update aborts before switching.
  updateScript = profile: ''
    if [ ! -f flake.nix ]; then
      echo "error: run this from the dotfiles repository root (flake.nix not found)" >&2
      exit 1
    fi
    nix flake update
    ${switchScript "." profile}
  '';

  mkPackageApp = package: description: {
    type = "app";
    program = pkgs.lib.getExe package;
    meta.description = description;
  };

  mkApp =
    name: description: text:
    mkPackageApp (pkgs.writeShellApplication { inherit name text; }) description;
in
{
  build = mkApp "build" "Build kohdice profile" (buildScript "kohdice");
  build-work = mkApp "build-work" "Build work profile" (buildScript "work");
  switch = mkApp "switch" "Apply kohdice profile" (switchScript flakeRef "kohdice");
  switch-work = mkApp "switch-work" "Apply work profile" (switchScript flakeRef "work");
  update = mkApp "update" "Update all inputs and apply kohdice profile" (updateScript "kohdice");
  update-work = mkApp "update-work" "Update all inputs and apply work profile" (updateScript "work");
  setup-ssh-keys = mkPackageApp setupSshKeys "Set up GitHub authentication and Git signing keys";
}
