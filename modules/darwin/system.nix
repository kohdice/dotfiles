{ config, pkgs, ... }:

{
  system.defaults = {
    dock = {
      # Automatically hide and show the Dock
      autohide = true;
      # Size of the icons (in pixels)
      tilesize = 36;
      # Disable magnification
      magnification = false;
      # Don't show recent applications in Dock
      show-recents = false;
      # Don't minimize windows into application icon
      minimize-to-application = false;
    };

    finder = {
      # Show hidden files
      AppleShowAllFiles = true;
      # Show path bar
      ShowPathbar = true;
      # Show status bar
      ShowStatusBar = true;

      # Desktop items to show
      ShowExternalHardDrivesOnDesktop = true; # External drives
      ShowHardDrivesOnDesktop = false; # Internal hard drives (hidden)
      ShowRemovableMediaOnDesktop = true; # Removable media

      # Keep folders on top when sorting by name
      _FXSortFoldersFirst = true;

      # New Finder windows show home folder ("PfHm" = Home folder)
      NewWindowTarget = "PfHm";
    };

    NSGlobalDomain = {
      # Key repeat rate (lower = faster, range: 1-120, default: 6)
      KeyRepeat = 1;

      # Delay until key repeat (lower = faster, range: 10-120, default: 25)
      InitialKeyRepeat = 10;

      # Enable dark mode
      AppleInterfaceStyle = "Dark";

      # Disable press-and-hold for accent characters (false = disabled)
      # Developer setting: enable key repeat on long press
      ApplePressAndHoldEnabled = false;

      # Text input auto-correction features
      NSAutomaticCapitalizationEnabled = true; # Auto-capitalize
      NSAutomaticDashSubstitutionEnabled = true; # Auto-dash substitution (-- to —)
      NSAutomaticPeriodSubstitutionEnabled = true; # Double-space to period
      NSAutomaticQuoteSubstitutionEnabled = true; # Smart quotes (" " to " ")
      NSAutomaticSpellingCorrectionEnabled = true; # Auto-correct spelling
    };

    trackpad = {
      # Enable tap to click
      Clicking = true;
      # Enable two-finger secondary click
      TrackpadRightClick = true;
      # Three-finger tap gesture (0 = disabled)
      TrackpadThreeFingerTapGesture = 0;
    };

    menuExtraClock = {
      # Show 24-hour time
      Show24Hour = true;
      # Don't show date (only day of week and seconds)
      ShowDate = false;
      # Show day of week
      ShowDayOfWeek = true;
      # Show seconds
      ShowSeconds = true;
    };
  };

  # Touch ID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
