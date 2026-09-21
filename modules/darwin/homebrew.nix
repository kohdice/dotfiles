{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      # Avoid implicit `brew update`/`brew upgrade` during switch.
      # Upgrade manually with `brew upgrade` when desired.
      autoUpdate = false;
      cleanup = "zap";
      upgrade = false;
    };

    brews = [
      "container"
    ];

    casks = [
      "coteditor"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
      "scroll-reverser"
    ];
  };
}
