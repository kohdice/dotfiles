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

    # Command-line applications (Formulae)
    brews = [
      "container"
    ];

    # GUI applications (Cask)
    casks = [
      "coteditor"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "scroll-reverser"
    ];
  };
}
