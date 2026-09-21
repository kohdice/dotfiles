# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Overview

Nix Flake-based dotfiles for macOS (nix-darwin with the home-manager module) and Linux (home-manager standalone). Two profiles, `kohdice` and `work`, are each built for `aarch64-darwin` and `x86_64-linux`.

| Path | Role |
| --- | --- |
| `flake.nix` | Inputs, `darwinConfigurations` / `homeConfigurations`, `checks`, `apps` |
| `lib/mkSystem.nix` | Builds one profile for either platform; derives `user.home` and `user.dotfilesDir` from `users/<name>/info.nix` and passes `user` and `inputs` to every module via `specialArgs` |
| `lib/apps.nix` | Defines every `nix run .#<app>`; `lib/setupSshKeys.nix` is the `setup-ssh-keys` app |
| `overlays/` | nixpkgs overlays; `llm-agents.nix` supplies `agent-browser`, `claude-code`, `codex`, `coderabbit-cli` from the `llm-agents` input |
| `modules/darwin/` | macOS system config: `homebrew.nix`, `packages.nix`, `system.nix` |
| `modules/home/` | Cross-platform home-manager modules: `dev/`, `editors/`, `git/`, `jj/`, `programs/`, `ssh/`, `dotfiles.nix`, `packages.nix`; `shell/` holds aliases, env, and PATH shared by `programs/zsh.nix` and `programs/bash.nix` |
| `modules/linux/` | Linux-only packages |
| `users/<name>/` | Profile: `info.nix`, `home.nix`, `darwin.nix`, `default.nix` |
| `config/` | Application configs linked into the home directory (see Symlinks) |
| `templates/` | `AGENTS.md` templates for new C and Rust projects; not used by the flake |
| `docs/ARCHITECTURE.md` | Decision criteria and full tables; read it only when a section below points there |j

## CORE PRINCIPLES

- Document at the right layer: Code → How, Tests → What, Commits → Why, Comments → Why not
- Keep documentation up to date with code changes

## Commands

```bash
nix run .#build            # Build kohdice profile (dry-run)
nix run .#build-work       # Build work profile (dry-run)
nix run .#switch           # Apply kohdice profile
nix run .#switch-work      # Apply work profile
nix run .#update           # Update all inputs and apply kohdice profile (run from repo root)
nix run .#update-work      # Update all inputs and apply work profile (run from repo root)
nix run .#setup-ssh-keys   # One-time GitHub auth / signing key setup (interactive)
nix fmt                    # Format Nix and Lua files (nixfmt, stylua)
nix flake check            # Formatting check plus full builds of every configuration
```

- `switch`, `update`, and `setup-ssh-keys` are interactive (`sudo darwin-rebuild` on macOS, passphrase prompts), and `config/claude/settings.json` denies `nix run .#switch*` and `nix flake update`. Never run them; ask the user to run the command and report back.
- Verification depends on what changed:
  - Nix files (`flake.nix`, `lib/`, `modules/`, `users/`, `overlays/`): run `nix fmt`, then `nix flake check --no-build --all-systems` (what CI runs; evaluates every configuration without building). Run `nix run .#build` or `.#build-work` when the change affects a build output, such as a package or overlay.
  - Lua under `config/nvim/`: run `nix fmt`.
  - Other files under `config/`: no build step; the symlink already points at the checkout.
- Run `nix fmt` before pushing. CI checks formatting with `nix fmt -- --ci`.
- Report the exact command and its result; do not claim a check passed without running it.

## User Profiles

- `kohdice`: personal, user `kohdice`
- `work`: business, user `bea-0021`

`info.nix` holds `name`, `fullName`, and `email` only. `home.nix` and `darwin.nix` carry profile-specific packages and casks. Read `docs/ARCHITECTURE.md` (Creating a New Profile) only when adding a profile.

## Key Patterns

- **Platform conditionals**: `lib.optionals pkgs.stdenv.hostPlatform.isDarwin/isLinux` for platform-specific packages
- **Module imports**: alphabetically ordered in `modules/home/default.nix` and `modules/home/dev/default.nix`
- **Symlinks**: all defined in `modules/home/dotfiles.nix` (`home.file` and `xdg.configFile`). They point at the live checkout via `mkOutOfStoreSymlink`, so an edit to an already-linked file or directory applies without a rebuild.
- **Enumerated directories need `git add` and a rebuild**: `config/agents/skills/`, `config/claude/{skills,commands,agents}/`, and `config/codex/agents/` are linked entry-by-entry from the flake source, which contains only git-tracked files. A new entry there is silently skipped until it is tracked and the profile is switched. Files added inside an already-linked directory (for example `config/nvim/`) need neither.
- **Unlinked backups**: `config/zsh/`, `config/bash/`, `config/git/`, and `config/jj/` are not linked anywhere; the live configs are the home-manager modules under `modules/home/`. Edit the modules, then sync the backups by hand.
- **Plans**: `.plans/` is git-ignored; plan files written there by the planning skills are neither committed nor visible to Nix.

## Adding Packages

- **CLI tools (cross-platform)**: `modules/home/packages.nix`
- **Language tools**: `modules/home/dev/<language>.nix`, imported in `modules/home/dev/default.nix`
- **macOS-only nixpkgs packages**: `modules/darwin/packages.nix`
- **Linux-only packages**: `modules/linux/packages.nix`
- **Homebrew formulae and casks**: `modules/darwin/homebrew.nix`; profile-only casks go in `users/<name>/darwin.nix`
- **Profile-only packages**: `users/<name>/home.nix`
- **AI agent CLIs**: come from `overlays/llm-agents.nix`, not nixpkgs; add new ones to the `inherit` list there

Read `docs/ARCHITECTURE.md` (GUI Application Policy) only when deciding between nixpkgs and Homebrew Cask for a GUI application, and (Config Management Policy) only when deciding whether a new application config becomes a Nix module or a symlink.

## Agent Assets

Split by runtime ownership; the full link table is in `docs/ARCHITECTURE.md` (Symlinks).

- `config/agents/`: runtime-neutral. `AGENTS.md` (linked to `~/.codex/AGENTS.md`; its content also lives in `config/claude/CLAUDE.md` plus `config/claude/rules/global.md`, keep them in sync), `hooks/` (linked to both `~/.claude/hooks` and `~/.codex/hooks`), and `skills/` (linked to both `~/.agents/skills/` and `~/.claude/skills/`).
- `config/claude/`: Claude Code only. `CLAUDE.md`, `rules/`, `settings.json`, `statusline.sh`, `commands/`, `agents/`. `skills/` does not exist today; if added, an entry there wins over a shared skill with the same name.
- `config/codex/`: Codex only. `config.toml`, `rules/`, `agents/` (TOML custom agents).
- Skills are runtime-neutral: a skill resolves sibling skills relative to its own directory and never probes for a runtime-specific path. Keep skill `description` fields at or below 1,024 characters.
