{
  description = "kohdice's dotfiles - Nix-based";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Formatter
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-index database (comma, command-not-found)
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      treefmt-nix,
      nix-index-database,
      ...
    }@inputs:
    let
      # Import helper functions
      helpers = import ./nix/lib/helpers { lib = nixpkgs.lib; };
      users = helpers.users;
      inherit (helpers.mkConfigs) mkDarwinConfig mkHomeConfig;

      # Custom overlays
      overlays = [ (import ./nix/overlays) ];

      # Supported systems
      darwinSystem = "aarch64-darwin";
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      allSystems = [ darwinSystem ] ++ linuxSystems;

      # Helper to generate per-system attributes
      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      # Treefmt configuration
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.stylua.enable = true;
        }
      );

      # Partially applied config builders
      mkDarwin = mkDarwinConfig {
        inherit
          nix-darwin
          home-manager
          nix-homebrew
          inputs
          overlays
          darwinSystem
          ;
      };

      mkHome = mkHomeConfig {
        inherit
          home-manager
          nixpkgs
          nix-index-database
          inputs
          overlays
          ;
      };

    in
    {
      # macOS configurations
      darwinConfigurations = {
        kohdice = mkDarwin users.kohdice;
        work = mkDarwin users.work;
      };

      # Linux configurations
      homeConfigurations = {
        kohdice = mkHome users.kohdice;
        work = mkHome users.work;
      };

      # Formatter (nix fmt)
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Apps (nix run .#<app>)
      apps = forAllSystems (
        system:
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
      );
    };
}
