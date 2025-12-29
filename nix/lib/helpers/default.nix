# Helper functions
{ lib }:

{
  # User configuration helpers
  users = import ./users.nix;

  # System configuration helpers
  mkConfigs = import ./mkConfigs.nix;
}
