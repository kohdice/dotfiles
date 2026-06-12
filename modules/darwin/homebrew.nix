{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      # Keep activation deterministic and offline-safe: no implicit
      # `brew update`/`brew upgrade` during switch. Upgrade manually
      # with `brew upgrade` when desired.
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
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
      "scroll-reverser"
    ];
  };
}
