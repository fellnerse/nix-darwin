# OpenClaw Telegram Configuration

## Key Finding: Pairing Mode is Broken (v0.5.45)

The `dmPolicy: "pairing"` mode does not work correctly in OpenClaw addon version 0.5.45. The bot receives messages (update offset increments) but silently drops them without creating pairing requests or responding to users.

### Root Cause
- Path mismatch: CLI looks in `/root/.openclaw/` but addon uses `/config/.openclaw/`
- Pairing requests are stored in `/config/.openclaw/credentials/telegram-pairing.json`
- The `openclaw pairing approve` CLI command cannot find requests because it reads from the wrong path

### Working Configuration

Use `dmPolicy: "allowlist"` instead of `"pairing"`:

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "allowFrom": ["<telegram-user-id>"],
      "botToken": "<bot_token>",
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  }
}
```

### Important Notes

1. **dmPolicy options:**
   - `"pairing"` - BROKEN, do not use
   - `"allowlist"` - Works, requires `allowFrom` array with Telegram user IDs
   - `"open"` - Works, but requires `allowFrom: ["*"]` - allows anyone to message

2. **Config file location:** `/root/.openclaw/openclaw.json` (LXC container CT 101, access via `ssh openclaw.tail`)

3. **Telegram-related files:**
   - Update offset: `/config/.openclaw/telegram/update-offset-default.json`
   - Pairing requests: `/config/.openclaw/credentials/telegram-pairing.json`
   - Sessions: `/config/.openclaw/agents/main/sessions/sessions.json`

4. **If messages aren't being processed:**
   - Check if an old session exists (delete sessions.json)
   - Check/delete update-offset file to reset polling
   - Verify bot is polling: API call to getUpdates should return 409 conflict

5. **Getting Telegram user ID:**
   - Send a message to the bot, check the pairing file or logs for the numeric ID
   - User's Telegram ID: <telegram-user-id> (Sebastian)

### Commands for Troubleshooting

```bash
# Check addon status
ssh homeassistant.local "ha apps info 17e0cc66_openclaw_assistant --raw-json" | jq '.data.state'

# View logs
ssh pve.local 'qm guest exec 100 -- docker exec addon_17e0cc66_openclaw_assistant cat /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log'

# Check config
ssh pve.local 'qm guest exec 100 -- docker exec addon_17e0cc66_openclaw_assistant cat /config/.openclaw/openclaw.json'

# Restart addon
ssh homeassistant.local "ha apps restart 17e0cc66_openclaw_assistant"

# Write config via base64 (avoids quoting issues)
CONFIG='<json>'
B64=$(echo "$CONFIG" | base64 -w0)
ssh pve.local "qm guest exec 100 -- docker exec addon_17e0cc66_openclaw_assistant sh -c 'echo $B64 | base64 -d > /config/.openclaw/openclaw.json'"
```

### Rate Limiting

If you see "API rate limit" errors, this is from the LLM provider (e.g., Google Gemini), not Telegram. Wait 1-2 minutes for limits to reset.
