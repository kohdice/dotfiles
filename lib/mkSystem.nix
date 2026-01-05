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
  # Platform detection
  isDarwin = inputs.nixpkgs.lib.hasSuffix "darwin" system;

  # Import user configuration
  userConfig = import ../users/${user};

  # Helper functions for platform-specific configuration
  mkUserInfo =
    homeDir:
    userConfig.info
    // {
      home = homeDir;
      dotfilesDir = "${homeDir}/developments/dotfiles";
    };

  mkSpecialArgs = userInfo: {
    inherit inputs;
    user = userInfo;
  };

  # Common nixpkgs configuration
  nixpkgsConfig = {
    allowUnfree = true;
  };

in
if isDarwin then
  let
    homeDir = "/Users/${userConfig.info.name}";
    userInfo = mkUserInfo homeDir;
    specialArgs = mkSpecialArgs userInfo;
    dotfilesDir = userInfo.dotfilesDir;
  in
  # Darwin (macOS) configuration
  inputs.nix-darwin.lib.darwinSystem {
    inherit system specialArgs;
    modules = [
      ../modules/${platform}
      userConfig.darwin

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
              userConfig.home
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
  let
    homeDir = "/home/${userConfig.info.name}";
    userInfo = mkUserInfo homeDir;
    specialArgs = mkSpecialArgs userInfo;
    dotfilesDir = userInfo.dotfilesDir;
  in
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
      userConfig.home
      inputs.nix-index-database.hmModules.nix-index
    ];
  }
