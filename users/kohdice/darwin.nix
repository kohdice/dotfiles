# nix-darwin module for kohdice profile
{ ... }:

{
  # Homebrew Cask apps
  homebrew.casks = [
    "discord"
  ];

  # Mac App Store apps
  homebrew.masApps = {
    "1Password 7" = 1333542190;
    "LINE" = 539883307;
  };
}
