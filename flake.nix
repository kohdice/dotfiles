{
  description = "kohdice's dotfiles - Nix-based";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "cache.numtide.com-1:xK8dXLdBj3zJ4gSxkrb/21Ex8CoIkcuBNWtoMq7Idgs=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

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

    # AI coding agents
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    let
      # Unified system builder
      mkSystem = import ./lib/mkSystem.nix {
        inherit self inputs;
      };

      # Supported systems
      darwinSystem = "aarch64-darwin";
      linuxSystems = [ "x86_64-linux" ];
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

    in
    {
      # macOS configurations
      darwinConfigurations = {
        kohdice = mkSystem "darwin" {
          system = darwinSystem;
          user = "kohdice";
        };
        work = mkSystem "darwin" {
          system = darwinSystem;
          user = "work";
        };
      };

      # Linux configurations (home-manager standalone)
      homeConfigurations = {
        kohdice = mkSystem "linux" {
          system = "x86_64-linux";
          user = "kohdice";
        };
        work = mkSystem "linux" {
          system = "x86_64-linux";
          user = "work";
        };
      };

      # Formatter (nix fmt)
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Checks (nix flake check): formatting plus full builds of every configuration
      checks = forAllSystems (
        system:
        {
          formatting = treefmtEval.${system}.config.build.check self;
        }
        // nixpkgs.lib.optionalAttrs (system == darwinSystem) {
          kohdice = self.darwinConfigurations.kohdice.system;
          work = self.darwinConfigurations.work.system;
        }
        // nixpkgs.lib.optionalAttrs (builtins.elem system linuxSystems) {
          kohdice-home = self.homeConfigurations.kohdice.activationPackage;
          work-home = self.homeConfigurations.work.activationPackage;
        }
      );

      # Apps (nix run .#<app>)
      apps = forAllSystems (system: import ./lib/apps.nix { inherit inputs system; });
    };
}
