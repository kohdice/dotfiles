{ pkgs, ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
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
      KeyRepeat = 2;
      InitialKeyRepeat = 15;

      AppleInterfaceStyle = "Dark";

      # Allow key repeat on long press instead of the accent menu.
      ApplePressAndHoldEnabled = false;

      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticQuoteSubstitutionEnabled = true;
      NSAutomaticSpellingCorrectionEnabled = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerTapGesture = 0;
    };

    WindowManager = {
      EnableStandardClickToShowDesktop = false;
    };

    menuExtraClock = {
      Show24Hour = true;
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
