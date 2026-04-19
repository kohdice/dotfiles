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
    # Reasons to stay on Homebrew Cask instead of nixpkgs:
    # - Not packaged in nixpkgs: azookey, claude, coteditor, devtoys
    # - Packaged but darwin-unsupported in nixpkgs: ghostty (Linux only)
    # - Auto-update on Cask is preferred over flake-pinned versions: chatgpt, google-chrome
    # - System extension / kernel-level integration safer via Cask: karabiner-elements
    casks = [
      "azookey"
      "chatgpt"
      "claude"
      "coteditor"
      "devtoys"
      "ghostty"
      "google-chrome"
      "karabiner-elements"
    ];
  };
}
