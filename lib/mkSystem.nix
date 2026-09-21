{ inputs }:

# Platform name: "darwin" or "linux"
platform:
{
  system,
  user,
}:

let
  isDarwin = inputs.nixpkgs.lib.hasSuffix "darwin" system;

  userConfig = import ../users/${user};

  homeDir = if isDarwin then "/Users/${userConfig.info.name}" else "/home/${userConfig.info.name}";

  userInfo = userConfig.info // {
    home = homeDir;
    dotfilesDir = "${homeDir}/developments/dotfiles";
  };

  specialArgs = {
    inherit inputs;
    user = userInfo;
  };

  nixpkgsConfig = {
    allowUnfree = true;
  };

  overlays = import ../overlays { inherit inputs; };

in
if isDarwin then
  inputs.nix-darwin.lib.darwinSystem {
    inherit specialArgs;
    modules = [
      ../modules/${platform}
      userConfig.darwin

      {
        nixpkgs = {
          # Recommended replacement for darwinSystem's legacy `system` argument
          hostPlatform = system;
          config = nixpkgsConfig;
          overlays = overlays;
        };
      }

      inputs.home-manager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = specialArgs;
          users.${userInfo.name} = {
            imports = [
              ../modules/home
              userConfig.home
              inputs.nix-index-database.homeModules.nix-index
            ];
          };
        };
      }

      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          user = userInfo.name;
          autoMigrate = true;
        };
      }
    ];
  }
else
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      localSystem = { inherit system; };
      config = nixpkgsConfig;
      overlays = overlays;
    };
    extraSpecialArgs = specialArgs;
    modules = [
      ../modules/home
      ../modules/${platform}
      userConfig.home
      inputs.nix-index-database.homeModules.nix-index
    ];
  }
