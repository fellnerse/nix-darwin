# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a nix-darwin + home-manager configuration for an Apple Silicon MacBook Pro. It manages system configuration, user dotfiles, and package installations declaratively through Nix flakes.

## Common Commands

```bash
mise run check          # Validate configuration without building
mise run build          # Build system without switching
mise run system         # Build and switch system config (requires sudo)
mise run user           # Switch home-manager for current user
mise run update         # Update all flake inputs
mise run update-unstable    # Update only nixpkgs-unstable
mise run gc             # Garbage collect old generations
mise run trampoline     # Create app trampolines for macOS Spotlight/Dock
```

Always run `mise run check` before applying changes. Use `mise run user` for home-manager-only changes (safer, no sudo needed).

## Architecture

```
flake.nix                           # Entry point - defines inputs, outputs, overlays
├── hosts/mbp/
│   ├── configuration.nix           # System-level: packages, fonts, macOS defaults, users
│   └── homebrew.nix               # Homebrew casks and App Store apps
└── home-manager/
    ├── common.nix                  # Shared user config: shell, git, editors, CLI tools
    ├── home.nix                    # "sefe" user - imports common.nix + work settings
    └── home-private.nix            # "private" user - imports common.nix + personal settings

## Documented Solutions

`docs/solutions/` — documented solutions to past problems (bugs, best practices, workflow patterns), organized by category with YAML frontmatter (`module`, `tags`, `problem_type`). Relevant when implementing or debugging in documented areas.
```

### Key Patterns

- **Unstable packages**: Access via `pkgs.unstable.*` (overlay defined in flake.nix)
- **Multi-user**: Two home-manager configs share `common.nix` to avoid duplication
- **mac-app-util trampolines**: Enables Nix apps to work with macOS Spotlight/Dock

## Where to Make Changes

| Task | File |
|------|------|
| Add system package | `hosts/mbp/configuration.nix` → `environment.systemPackages` |
| Add user program | `home-manager/common.nix` → `home.packages` or `programs.*` |
| Add Homebrew cask/app | `hosts/mbp/homebrew.nix` |
| Change macOS defaults | `hosts/mbp/configuration.nix` → `system.defaults` |
| Modify shell config | `home-manager/common.nix` → `programs.fish` |
| Change git settings | `home-manager/common.nix` (shared) or user-specific files (overrides) |

## Troubleshooting

- **Apps not in Spotlight**: Run `mise run trampoline` and see README.md for mac-app-util issues
- **Configuration errors**: Run `mise run check` to see detailed error messages
- **Rollback**: Use `darwin-rebuild --rollback` or `home-manager generations` to switch back
