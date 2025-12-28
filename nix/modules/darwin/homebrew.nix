{ config, lib, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    taps = [
      "homebrew/bundle"
      "homebrew/cask"
    ];

    # CLI tools managed via Homebrew (not available in nixpkgs)
    brews = [
      "mas"
    ];

    # GUI applications (Cask) - only apps NOT available in nixpkgs
    casks = [
      "coteditor"
      "docker-desktop"
      "google-japanese-ime"
      "mysqlworkbench"
      "numi"
    ];

    # Mac App Store apps
    masApps = {
      "1Password 7" = 1333542190;
      "iMovie" = 408981434;
      "LINE" = 539883307;
      "RunCat" = 1429033973;
      "Spark" = 1176895641;
      "Xcode" = 497799835;
    };
  };
}
