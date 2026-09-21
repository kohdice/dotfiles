{ pkgs, ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      # Icon size in pixels.
      tilesize = 36;
      magnification = false;
      show-recents = false;
      minimize-to-application = false;
    };

    finder = {
      AppleShowAllFiles = true;
      ShowPathbar = true;
      ShowStatusBar = true;

      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;

      _FXSortFoldersFirst = true;

      NewWindowTarget = "Home";
    };

    NSGlobalDomain = {
      # Lower values repeat keys faster.
      KeyRepeat = 2;

      # Lower values shorten the delay before key repeat.
      InitialKeyRepeat = 15;

      AppleInterfaceStyle = "Dark";

      # Allow key repeat on long press instead of the accent menu.
      ApplePressAndHoldEnabled = false;

      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true; # -- becomes an em dash.
      NSAutomaticPeriodSubstitutionEnabled = true; # Double-space becomes a period.
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      # 0 disables the three-finger tap gesture.
      TrackpadThreeFingerTapGesture = 0;
    };

    WindowManager = {
      # Restrict click-wallpaper-to-show-desktop to Stage Manager.
      EnableStandardClickToShowDesktop = false;
    };

    menuExtraClock = {
      Show24Hour = true;
      # 0 = when space allows, 1 = always, 2 = never.
      ShowDate = 0;
      ShowDayOfWeek = true;
      ShowSeconds = true;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
