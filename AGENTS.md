# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Overview

Nix Flake-based macOS/Linux development environment dotfiles. Uses nix-darwin (macOS) and home-manager (Linux) for declarative configuration.

## Commands

```bash
# Build configuration
nix run .#build          # Build kohdice profile
nix run .#build-work     # Build work profile

# Apply configuration
nix run .#switch         # Apply kohdice profile
nix run .#switch-work    # Apply work profile

# Format code
nix fmt                  # Format Nix and Lua files (nixfmt, stylua)

# Validation
nix flake check          # Validate entire flake
```

## Architecture

```
dotfiles/
├── flake.nix                     # Entry point - darwinConfigurations & homeConfigurations
├── lib/
│   ├── mkSystem.nix              # Unified system builder (darwin/linux)
│   └── apps.nix                  # App definitions for `nix run .#<app>`
├── overlays/                     # Custom package overlays
│   ├── default.nix               # Overlay entry point
│   └── ai-tools.nix              # AI tools bundle (claude-code, codex)
├── modules/
│   ├── darwin/                   # macOS-specific (system.nix, homebrew.nix, packages.nix)
│   ├── home/                     # home-manager modules (cross-platform)
│   │   ├── default.nix           # Module imports only
│   │   ├── dotfiles.nix          # XDG symlinks and home.file configurations
│   │   ├── packages.nix          # CLI tools
│   │   ├── dev/                  # Language-specific tools (go.nix, rust.nix, etc.)
│   │   ├── editors/              # Editor configurations (neovim.nix)
│   │   ├── git/                  # Git configuration and aliases
│   │   └── programs/             # App-specific configs (claude-code.nix, codex.nix, gh.nix)
│   └── linux/                    # Linux-specific configuration
├── users/                        # User profile definitions
│   ├── kohdice/default.nix       # Personal profile
│   └── work/default.nix          # Work profile
└── config/                       # App configs (symlinked via XDG)
    ├── nvim/                     # Neovim (Lazy.nvim plugin manager)
    ├── zsh/, bash/               # Shell configs
    ├── tmux/, ghostty/, lazygit/, starship/, karabiner/
    ├── claude/                   # Claude Code config templates
    │   ├── commands/             # Custom slash commands
    │   └── go/, rust/, zig/      # Language-specific project settings
    └── codex/                    # OpenAI Codex config templates
```

## User Profiles

Defined in `users/` directory and referenced from `flake.nix`:

- `kohdice` - Personal profile (/Users/kohdice)
- `work` - Work profile (/Users/karei)

## Key Patterns

- **Overlays**: Custom packages defined in `overlays/`, applied via `flake.nix`
- **Module imports**: Alphabetically ordered in `modules/home/default.nix`
- **Symlinks**: Managed in `modules/home/dotfiles.nix` (XDG) and app-specific modules
- **Platform conditionals**: Use `lib.optionals isDarwin/isLinux` for platform-specific packages
- **System builder**: `lib/mkSystem.nix` handles both Darwin and Linux configurations

## Primary Languages

Go, Rust, Python, TypeScript/JavaScript, Lua, Zig, Nix

## Neovim Structure (config/nvim/)

- `init.lua` → `lua/config/lazy.lua` - Entry and plugin manager
- `lua/config/` - keymaps.lua, options.lua
- `lua/plugins/` - Individual plugin configs
- `lsp/` - LSP configs (gopls, rust_analyzer, lua_ls, ts_ls)
