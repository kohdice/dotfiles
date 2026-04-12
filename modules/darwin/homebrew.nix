{ config, lib, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

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
      "raycast"
      "scroll-reverser"
      "slack"
      "tableplus"
      "vlc"
      "zoom"
    ];
  };
}
