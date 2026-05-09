# OpenClaw Update Safety

## Key Finding: Post-Update Maintenance

When the user asks if it is safe to update OpenClaw, advise them that **updates are generally safe but may introduce breaking configuration changes** (such as changes to `openclaw.json` schema).

### Guidance to Provide to the User
When asked about update safety, respond with:
1. **Yes, you can update.**
2. **Warning:** Sometimes updates change the configuration format, which might prevent OpenClaw from starting automatically after the update finishes.
3. If the bot stops responding after the update, provide them with these troubleshooting steps to run from their terminal to repair the config:
   ```bash
   ssh pve.tail "pct exec 101 -- /bin/openclaw doctor --fix"
   ssh pve.tail "pct exec 101 -- /bin/openclaw gateway install --force"
   ```
4. They can verify the status at any time with:
   ```bash
   ssh pve.tail "pct exec 101 -- /bin/openclaw gateway status"
   ```