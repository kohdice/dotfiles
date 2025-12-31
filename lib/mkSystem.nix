# Unified system configuration builder
# Handles both Darwin (macOS) and Linux (home-manager standalone)
{
  self,
  inputs,
  overlays,
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

  # Platform detection
  isDarwin = inputs.nixpkgs.lib.hasSuffix "darwin" system;

  # Common specialArgs passed to all modules
  specialArgs = {
    inherit inputs;
    user = userConfig.user;
  };

  # dotfiles directory (flake root)
  dotfilesDir = self;

in
if isDarwin then
  # Darwin (macOS) configuration
  inputs.nix-darwin.lib.darwinSystem {
    inherit system specialArgs;
    modules = [
      # Platform-specific configuration
      ../modules/${platform}

      # Apply overlays and allow unfree packages
      {
        nixpkgs.overlays = overlays;
        nixpkgs.config.allowUnfree = true;
      }

      # home-manager integration
      inputs.home-manager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "backup";
          extraSpecialArgs = specialArgs // {
            inherit dotfilesDir;
          };
          users.${userConfig.user.name} = import ../modules/home;
        };
      }

      # nix-homebrew integration
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          enable = true;
          user = userConfig.user.name;
          autoMigrate = true;
        };
      }
    ];
  }
else
  # Linux configuration (home-manager standalone)
  inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system overlays;
      config.allowUnfree = true;
    };
    extraSpecialArgs = specialArgs // {
      inherit dotfilesDir;
    };
    modules = [
      ../modules/home
      ../modules/${platform}
      inputs.nix-index-database.hmModules.nix-index
    ];
  }
