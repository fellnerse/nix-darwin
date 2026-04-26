# nix-darwin Project Overview

## Purpose
A nix-darwin + home-manager configuration for an Apple Silicon MacBook Pro (aarch64-darwin). Manages system configuration, user dotfiles, and package installations declaratively through Nix flakes.

## Tech Stack
- **Nix Flakes**: Declarative system configuration
- **nix-darwin**: macOS system configuration (based on nixpkgs-25.11-darwin)
- **home-manager**: User environment management (release-25.11)
- **mac-app-util**: Trampolines for Spotlight/Dock integration
- **Serena**: Code-aware MCP tools

## Architecture
```
flake.nix                    # Entry point - inputs, outputs, overlays
├── hosts/mbp/
│   ├── configuration.nix    # System: packages, fonts, macOS defaults, users, launchd
│   └── homebrew.nix         # Homebrew casks and App Store apps
├── home-manager/
│   ├── common.nix           # Shared: shell, git, editors, CLI tools
│   ├── home.nix             # "sefe" user (work profile)
│   ├── home-private.nix     # "private" user (personal profile)
│   ├── fish.nix             # Fish shell configuration
│   └── wezterm.lua          # WezTerm terminal config
└── pkgs/
    ├── beads.nix            # Custom package: git-backed issue tracker
    └── gastown.nix          # Custom package
```

## Key Patterns
- **Unstable overlay**: Access bleeding-edge packages via `pkgs.unstable.*`
- **Multi-user**: Two home-manager profiles share `common.nix` to avoid duplication
- **Custom packages**: `pkgs/` contains derivations for non-nixpkgs software
- **Unfree packages**: Enabled globally via `config.allowUnfree = true`

## Where to Make Changes
| Task                     | File                                              |
|--------------------------|---------------------------------------------------|
| Add system package       | `hosts/mbp/configuration.nix` → `environment.systemPackages` |
| Add user program         | `home-manager/common.nix` → `home.packages` or `programs.*` |
| Add Homebrew cask/app    | `hosts/mbp/homebrew.nix`                          |
| Change macOS defaults    | `hosts/mbp/configuration.nix` → `system.defaults` |
| Modify shell config      | `home-manager/common.nix` → `programs.fish`       |
| Add custom package       | Create `pkgs/<name>.nix` and add to overlay in `flake.nix` |
