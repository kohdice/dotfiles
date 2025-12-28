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
      # Custom overlays
      overlays = [ (import ./nix/overlays) ];

      # User configurations
      users = {
        kohdice = {
          name = "kohdice";
          fullName = "kohdice";
          email = "kohdice.biz@gmail.com";
          home = "/Users/kohdice";
        };
        work = {
          name = "karei";
          fullName = "kohdice";
          email = "kohdice.biz@gmail.com";
          home = "/Users/karei";
        };
      };

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

      # Helper function for Darwin configuration
      mkDarwinConfig =
        user:
        nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          specialArgs = { inherit inputs user; };
          modules = [
            ./nix/modules/darwin
            { nixpkgs.overlays = overlays; }
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs user;
                  dotfilesDir = "${user.home}/developments/dotfiles";
                };
                users.${user.name} = import ./nix/modules/home;
              };
            }
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                user = user.name;
                autoMigrate = true;
              };
            }
          ];
        };

      # Helper function for Home Manager configuration (Linux)
      mkHomeConfig =
        user:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            inherit overlays;
          };
          extraSpecialArgs = {
            inherit inputs user;
            dotfilesDir = "${user.home}/developments/dotfiles";
          };
          modules = [
            ./nix/modules/home
            ./nix/modules/linux
            nix-index-database.hmModules.nix-index
          ];
        };

    in
    {
      # macOS configurations
      darwinConfigurations = {
        kohdice = mkDarwinConfig users.kohdice;
        work = mkDarwinConfig users.work;
      };

      # Linux configurations
      homeConfigurations = {
        kohdice = mkHomeConfig users.kohdice;
        work = mkHomeConfig users.work;
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
          };
        }
      );
    };
}
