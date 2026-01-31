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

    # GUI applications (Cask)
    casks = [
      "azookey"
      "chatgpt"
      "claude"
      "coteditor"
      "devtoys"
      "docker-desktop"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "numi"
      "postman"
      "raycast"
      "scroll-reverser"
      "slack"
      "tableplus"
      "visual-studio-code"
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
