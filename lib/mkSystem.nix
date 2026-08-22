# Unified system configuration builder
# Handles both Darwin (macOS) and Linux (home-manager standalone)
{ inputs }:

# Platform name: "darwin" or "linux"
platform:
# Configuration options
{
  system,
  user,
}:

let
  # Platform detection
  isDarwin = inputs.nixpkgs.lib.hasSuffix "darwin" system;

  # Import user configuration
  userConfig = import ../users/${user};

  homeDir = if isDarwin then "/Users/${userConfig.info.name}" else "/home/${userConfig.info.name}";

  userInfo = userConfig.info // {
    home = homeDir;
    dotfilesDir = "${homeDir}/developments/dotfiles";
  };

  # Passed to all modules (and to home-manager via extraSpecialArgs);
  # dotfilesDir is reachable as `user.dotfilesDir`.
  specialArgs = {
    inherit inputs;
    user = userInfo;
  };

  # Common nixpkgs configuration
  nixpkgsConfig = {
    allowUnfree = true;
  };

  # Import overlays
  overlays = import ../overlays { inherit inputs; };

in
if isDarwin then
  # Darwin (macOS) configuration
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
  # Linux configuration (home-manager standalone)
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
