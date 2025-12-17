# nix-darwin configuration

## Troubleshooting

### mac-app-util trampolines: "open: command not found"

When using `mac-app-util` for trampoline apps (so Nix-installed apps work with Spotlight/Dock), you may get `sh: open: command not found` when launching apps.

**Cause:** The launchd PATH doesn't include `/usr/bin` where the `open` command lives.

**Fix (persistent, requires reboot):**
```bash
sudo launchctl config user path "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin"
```

**Fix (current session only):**
```bash
launchctl setenv PATH "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin"
killall Finder  # Restart Finder to pick up new PATH
```

### Icons showing as AppleScript icon

If trampoline apps show the generic AppleScript icon instead of the app icon, clear the icon cache:
```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder
touch ~/Applications/Home\ Manager\ Trampolines/*.app
```

May require logout/login or reboot to fully take effect.
