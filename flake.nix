{
  description = "kohdice's dotfiles - Nix-based";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
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
      mkSystem = import ./lib/mkSystem.nix {
        inherit inputs;
      };

      darwinSystem = "aarch64-darwin";
      linuxSystems = [ "x86_64-linux" ];
      allSystems = [ darwinSystem ] ++ linuxSystems;

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

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
      darwinConfigurations = {
        kohdice = mkSystem {
          system = darwinSystem;
          user = "kohdice";
        };
        work = mkSystem {
          system = darwinSystem;
          user = "work";
        };
      };

      homeConfigurations = {
        kohdice = mkSystem {
          system = "x86_64-linux";
          user = "kohdice";
        };
        work = mkSystem {
          system = "x86_64-linux";
          user = "work";
        };
      };

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

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

      apps = forAllSystems (system: import ./lib/apps.nix { inherit inputs system; });
    };
}
