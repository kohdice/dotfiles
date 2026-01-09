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

      # Apps (nix run .#<app>)
      apps = forAllSystems (system: import ./lib/apps.nix { inherit nixpkgs system; });
    };
}
