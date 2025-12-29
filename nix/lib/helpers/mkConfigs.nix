# Configuration builder functions
{
  # Helper function for Darwin configuration
  mkDarwinConfig =
    {
      nix-darwin,
      home-manager,
      nix-homebrew,
      inputs,
      overlays,
      darwinSystem,
    }:
    user:
    nix-darwin.lib.darwinSystem {
      system = darwinSystem;
      specialArgs = { inherit inputs user; };
      modules = [
        ../../modules/darwin
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
            users.${user.name} = import ../../modules/home;
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
    {
      home-manager,
      nixpkgs,
      nix-index-database,
      inputs,
      overlays,
    }:
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
        ../../modules/home
        ../../modules/linux
        nix-index-database.hmModules.nix-index
      ];
    };
}
