# Stats Launchd Agent Reliability Issue

## Problem
Stats menu bar app was not starting reliably at login. The launchd agent would show exit code -6 after login.

## Root Cause
Race condition at login - Stats tries to start before the GUI session is fully initialized.

## Solution Applied (2026-02-13)
Changes to `home-manager/common.nix` launchd.agents.stats:

1. **Added 5-second startup delay** via shell wrapper:
   ```nix
   ProgramArguments = [
     "/bin/sh"
     "-c"
     "sleep 5 && exec ${pkgs.stats}/Applications/Stats.app/Contents/MacOS/Stats"
   ];
   ```

2. **Added KeepAlive with SuccessfulExit = false** - Restarts if it crashes, but not if quit intentionally

3. **Added ThrottleInterval = 30** - Prevents rapid restart loops

## Testing Status
- **NOT YET TESTED** - User needs to log out/in to verify the fix works at login time
- Running `mise run user` manually always worked (GUI already initialized)

## Next Steps
After user logs out/in:
- Check if Stats started automatically
- If still failing, may need to increase delay or use a different approach (e.g., `open -g` instead of direct binary)
