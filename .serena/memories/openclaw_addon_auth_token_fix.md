# OpenClaw Home Assistant Addon - Auth Token Fix

## Problem
OpenClaw addon was crashing on startup with error:
```
Gateway auth is set to token, but no token is configured.
Set gateway.auth.token (or OPENCLAW_GATEWAY_TOKEN), or pass --token.
```

## Root Cause
The gateway configuration had `"auth": { "mode": "token" }` but was missing the actual `"token"` field value.

## Solution
1. SSH into Home Assistant host via Tailscale:
   ```bash
   ssh root@<homeassistant-ts-hostname>
   ```

2. Locate the OpenClaw addon config:
   ```
   /addon_configs/17e0cc66_openclaw_assistant/.openclaw/openclaw.json
   ```

3. Generate a random auth token:
   ```bash
   od -An -tx1 -N32 /dev/urandom | tr -d ' ' | head -1
   ```

4. Update the config using jq to add the token:
   ```bash
   CONFIG_FILE='/addon_configs/17e0cc66_openclaw_assistant/.openclaw/openclaw.json'
   TOKEN='<generated-token>'
   jq --arg token "$TOKEN" '.gateway.auth.token = $token' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
   ```

5. Verify the update:
   ```bash
   cat /addon_configs/17e0cc66_openclaw_assistant/.openclaw/openclaw.json | grep -A 3 '"auth"'
   ```

6. Restart the OpenClaw addon from Home Assistant UI

## Key Files
- Config location: `/addon_configs/17e0cc66_openclaw_assistant/.openclaw/openclaw.json`
- Addon ID: `17e0cc66_openclaw_assistant`
- Home Assistant root SSH: `ssh root@homeassistant.tail401ae4.ts.net`

## Status
Fixed and tested - addon now starts successfully
