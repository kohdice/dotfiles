# Unified system configuration builder
# Handles both Darwin (macOS) and Linux (home-manager standalone)
{
  self,
  inputs,
}:

# Platform name: "darwin" or "linux"
platform:
# Configuration options
{
  system,
  user,
}:

let
  # Import user configuration
  userConfig = import ../users/${user};

  # User info
  userInfo = userConfig.info;

  # User modules
  userHomeModule = userConfig.home;
  userDarwinModule = userConfig.darwin;

  # Platform detection
  isDarwin = inputs.nixpkgs.lib.hasSuffix "darwin" system;

  # Common nixpkgs configuration
  nixpkgsConfig = {
    allowUnfree = true;
  };

  # Common specialArgs passed to all modules
  specialArgs = {
    inherit inputs;
    user = userInfo;
  };

  # dotfiles directory (from user config for writable symlinks)
  dotfilesDir = userInfo.dotfilesDir;

in
if isDarwin then
  # Darwin (macOS) configuration
  inputs.nix-darwin.lib.darwinSystem {
    inherit system specialArgs;
    modules = [
      ../modules/${platform}
      userDarwinModule

      {
        nixpkgs.config = nixpkgsConfig;
      }

      inputs.home-manager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = specialArgs // {
            inherit dotfilesDir;
          };
          users.${userInfo.name} = {
            imports = [
              ../modules/home
              userHomeModule
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
  # Linux configuration (home-manager standalone)
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = nixpkgsConfig;
    };
    extraSpecialArgs = specialArgs // {
      inherit dotfilesDir;
    };
    modules = [
      ../modules/home
      ../modules/${platform}
      userHomeModule
      inputs.nix-index-database.hmModules.nix-index
    ];
  }
