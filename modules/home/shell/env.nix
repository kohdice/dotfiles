# Common environment variables shared between zsh and bash.
# XDG base directories are not set here: home-manager already exports them
# via `xdg.enable = true` (see modules/home/dotfiles.nix).
{
  # Go
  GOPATH = "$HOME/go";
}
