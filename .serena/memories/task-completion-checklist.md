# Task Completion Checklist

Before considering a task complete, run through this checklist:

## 1. Validate Configuration
```bash
mise run check
```
This catches syntax errors and evaluation issues without building.

## 2. Format Code
```bash
nix fmt
```
Or rely on pre-commit hooks if configured.

## 3. Test the Change

**For home-manager only changes (safer):**
```bash
mise run user
```

**For system-level changes:**
```bash
mise run system
```

## 4. Verify the Change
- If adding a package: verify it's available in shell (`which <cmd>`)
- If changing macOS defaults: check System Settings or use `defaults read`
- If adding launch agents: check with `launchctl list | grep <name>`

## 5. Commit
Use conventional commit format:
```bash
git add -A
git commit -m "feat: add new package X"
```

## Common Issues
- **Apps not in Spotlight**: Run `mise run trampoline`
- **Configuration errors**: Check `mise run check` output
- **Rollback needed**: Use `darwin-rebuild --rollback` or `home-manager generations`
