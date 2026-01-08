{ config, lib, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    # CLI tools managed via Homebrew (not available in nixpkgs)
    brews = [
      "mas"
    ];

    # GUI applications (Cask) - only apps NOT available in nixpkgs
    casks = [
      "chatgpt"
      "claude"
      "coteditor"
      "docker-desktop"
      "ghostty"
      "google-japanese-ime"
      "karabiner-elements"
      "numi"
      "postman"
      "raycast"
      "vlc"
      "zoom"
    ];

    # Mac App Store apps
    masApps = {
      "iMovie" = 408981434;
      "RunCat" = 1429033973;
      "Spark" = 6445813049;
      "Xcode" = 497799835;
    };
  };
}
