# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Overview

Nix Flake-based macOS/Linux development environment dotfiles. Uses nix-darwin (macOS) and home-manager (Linux) for declarative configuration. See `docs/ARCHITECTURE.md` for the directory layout, the Nix-vs-symlink decision criteria, the full symlink map, and new-profile creation steps.

## Commands

```bash
nix run .#build          # Build kohdice profile (dry-run)
nix run .#build-work     # Build work profile (dry-run)
nix run .#switch         # Apply kohdice profile
nix run .#switch-work    # Apply work profile
nix run .#update         # Update all inputs and apply kohdice profile (run from repo root)
nix run .#update-work    # Update all inputs and apply work profile (run from repo root)
nix fmt                  # Format Nix and Lua files (nixfmt, stylua)
nix flake check          # Validate entire flake
```

- `switch` and `update` run `sudo darwin-rebuild` on macOS and prompt for a password, so agents cannot run them; ask the user to run the command.
- Run `nix fmt` before pushing. CI checks formatting with `nix fmt -- --ci`.

## User Profiles

Profiles live in `users/<name>/` (`info.nix`, `home.nix`, `darwin.nix`, `default.nix`):

- `kohdice`: personal, user `kohdice`
- `work`: business, user `bea-0021`

`home` and `dotfilesDir` are derived from `info.nix` in `lib/mkSystem.nix`, and every module receives them as `user` via `specialArgs`.

## Key Patterns

- **Platform conditionals**: Use `lib.optionals isDarwin/isLinux` for platform-specific packages
- **Symlinks**: Managed in `modules/home/dotfiles.nix` (`home.file` and `xdg.configFile`); they point at the live checkout via `mkOutOfStoreSymlink`, so edits to already-linked files apply without a rebuild
- **Untracked files are invisible to Nix**: pure evaluation only sees git-tracked files, so `git add` new entries under `config/` before building; untracked entries are silently skipped
- **Module imports**: Alphabetically ordered in `modules/home/default.nix`

## Adding Packages

- **CLI tools (cross-platform)**: `modules/home/packages.nix`
- **Language tools**: `modules/home/dev/<language>.nix` (import in dev/default.nix)
- **macOS system packages**: `modules/darwin/packages.nix`
- **Homebrew/Cask/MAS**: `modules/darwin/homebrew.nix`
