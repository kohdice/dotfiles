{ config, pkgs, ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 36;
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = false;
    };

    NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 10;
    };
  };

  security.pam.enableSudoTouchIdAuth = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
