# Code Style and Conventions

## Formatting
- **Formatter**: `nixfmt-tree` (configured in flake.nix)
- **Pre-commit hook**: Runs `nix fmt` on all `.nix` files
- Run `nix fmt` before committing or use pre-commit

## Nix Code Style
- Use attribute sets with consistent indentation
- Prefer `let...in` for local bindings
- Use `inherit` to reduce duplication
- Group related options together with comments

## File Organization
- System-level config in `hosts/mbp/`
- User-level config in `home-manager/`
- Custom packages in `pkgs/`
- Shared user config goes in `common.nix`, user-specific overrides in individual home files

## Naming
- Flake output names match hostname: `Sebastians-MacBook-Pro-2`
- Home configurations use username: `sefe`, `private`
- Custom packages use lowercase with hyphens

## Commit Messages
- Follow conventional commits: `feat:`, `fix:`, `refactor:`, etc.
- Note: Only `feat` and `fix` trigger releases (if using commitizen)
- Never include Claude-related info in commit messages
