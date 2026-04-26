# Suggested Commands

## Daily Workflow (via mise)

| Command                  | Description                                       |
|--------------------------|---------------------------------------------------|
| `mise run check`         | **Always run first** - Validate config without building |
| `mise run build`         | Build system without switching                    |
| `mise run system`        | Build and switch system config (requires sudo)    |
| `mise run user`          | Switch home-manager for current user (safer, no sudo) |
| `mise run update`        | Update all flake inputs                           |
| `mise run update-unstable` | Update only nixpkgs-unstable                    |
| `mise run gc`            | Garbage collect old generations                   |
| `mise run trampoline`    | Create app trampolines for macOS Spotlight/Dock   |

## Direct Nix Commands

```bash
# Check flake validity
nix flake check

# Format all Nix files
nix fmt

# Search for packages
nix search nixpkgs <package>

# Show flake outputs
nix flake show

# Update specific input
nix flake update <input-name>
```

## Rollback

```bash
# Rollback system config
darwin-rebuild --rollback

# List home-manager generations
home-manager generations

# Switch to specific generation
/nix/store/<hash>-home-manager-generation/activate
```

## Troubleshooting

```bash
# Check Hydra cache availability
mise run hydra-check

# Clear icon cache (for trampoline apps)
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock && killall Finder
```
