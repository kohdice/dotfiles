# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Overview

Nix Flake-based macOS/Linux development environment dotfiles. Uses nix-darwin (macOS) and home-manager (Linux) for declarative configuration.

## Commands

```bash
# Build and apply configuration
nix run .#build          # Build kohdice profile (dry-run)
nix run .#build-work     # Build work profile (dry-run)
nix run .#switch         # Apply kohdice profile (macOS uses sudo internally)
nix run .#switch-work    # Apply work profile
nix run .#update         # Update all inputs and apply

# Format and validate
nix fmt                  # Format Nix and Lua files (nixfmt, stylua)
nix flake check          # Validate entire flake

# Troubleshooting
darwin-rebuild --list-generations     # List generations (macOS)
darwin-rebuild switch --rollback      # Rollback to previous (macOS)
home-manager generations              # List generations (Linux)
nix eval .#darwinConfigurations.kohdice.system --show-trace  # Debug build errors
```

## Architecture

- `flake.nix` - Entry point defining `darwinConfigurations` and `homeConfigurations`
- `lib/mkSystem.nix` - Unified system builder for Darwin/Linux
- `lib/apps.nix` - App definitions for `nix run .#<app>`
- `modules/darwin/` - macOS-specific (system.nix, homebrew.nix, packages.nix)
- `modules/home/` - Cross-platform home-manager modules
- `modules/linux/` - Linux-specific configuration
- `users/` - User profile definitions
- `config/` - App configs (symlinked via XDG)

## User Profiles

Each profile in `users/<name>/` has three files:

```nix
# users/<name>/default.nix - Exports the profile
{
  info = import ./info.nix;    # User info (name, email, home, dotfilesDir)
  home = ./home.nix;           # home-manager module overrides
  darwin = ./darwin.nix;       # Darwin-specific overrides (macOS only)
}
```

Profiles: `kohdice` (personal, /Users/kohdice) and `work` (business, /Users/karei)

## Key Patterns

- **Module arguments**: All modules receive `user` (from info.nix) and `dotfilesDir` via `specialArgs`
- **Platform conditionals**: Use `lib.optionals isDarwin/isLinux` for platform-specific packages
- **Symlinks**: Managed in `modules/home/dotfiles.nix` for XDG config and home.file
- **Module imports**: Alphabetically ordered in `modules/home/default.nix`
- **Nix vs Symlink decision**: See `docs/ARCHITECTURE.md` for when to use Nix modules vs symlinks

## Adding Packages

- **CLI tools (cross-platform)**: `modules/home/packages.nix`
- **Language tools**: `modules/home/dev/<language>.nix` (import in dev/default.nix)
- **macOS system packages**: `modules/darwin/packages.nix`
- **Homebrew/Cask/MAS**: `modules/darwin/homebrew.nix`

## Neovim (config/nvim/)

- `init.lua` → `lua/config/lazy.lua` - Entry and Lazy.nvim plugin manager
- `lua/config/` - keymaps.lua, options.lua
- `lua/plugins/` - Individual plugin configs
- `lsp/` - Native LSP server configs (gopls, rust_analyzer, lua_ls, ts_ls, etc.)
