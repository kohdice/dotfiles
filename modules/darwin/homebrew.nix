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
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "podman-desktop"
      "slack"
      "zoom"
    ];
  };
}
