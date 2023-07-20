#!/bin/bash

# System settings
echo "[defaults.sh] Configure system settings..."

##Dock
# Dock icon size of 36 pixels
defaults write com.apple.dock "tilesize" -int 36
# Autohide the Dock when the mouse is out
defaults write com.apple.dock "autohide" -bool true

##Finder
# Show all file extensions inside the Finder
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool true
# Show hidden files inside the Finder
defaults write com.apple.finder "AppleShowAllFiles" -bool true
# Show path bar
defaults write com.apple.finder "ShowPathbar" -bool true
# Keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirst" -bool true
# Search the current folder
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"
# Keep folders on top
defaults write com.apple.finder "_FXSortFoldersFirstOnDesktop" -bool true

## Safari
# Enable developer menu and web inspector in safari
defaults write com.apple.Safari "IncludeInternalDebugMenu" -bool true
defaults write com.apple.Safari "IncludeDevelopMenu" -bool true
defaults write com.apple.Safari "WebKitDeveloperExtrasEnabledPreferenceKey" -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write -g "WebKitDeveloperExtras" -bool true
# Do not send search queries to Apple
defaults write com.apple.Safari "SuppressSearchSuggestions" -bool true
defaults write com.apple.Safari "UniversalSearchEnabled" -bool false

##Keyrepeat settings
defaults write -g "KeyRepeat" -int 2
defaults write -g "InitialKeyRepeat"-int 15

##.DS_Store
# Do not create .DS_Store files on USB or network storage
defaults write com.apple.desktopservices "DSDontWriteNetworkStores" -bool true
defaults write com.apple.desktopservices "DSDontWriteUSBStores" -bool true

# Date options: Show the day of the week: on Thu Aug 10  12:34:56
defaults write com.apple.menuextra.clock "DateFormat" -string "\"EEE MMM d HH:mm:ss\""

# Do not autogather large files when submitting a report
defaults write com.apple.appleseed.FeedbackAssistant "Autogather" -bool false

# Disable sending crash reports
defaults write com.apple.CrashReporter DialogType -string "none"

# Disable automatic file opening after file download
defaults write com.apple.Safari "AutoOpenSafeDownloads" -bool false

# Remove the default shadow from screenshots
defaults write com.apple.screencapture "disable-shadow" -bool true
