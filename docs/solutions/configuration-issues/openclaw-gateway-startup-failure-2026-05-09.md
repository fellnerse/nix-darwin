---
title: OpenClaw gateway startup failure after update
module: openclaw
tags: [openclaw, configuration, telegram, update, startup_failed]
problem_type: configuration_issue
date: 2026-05-09
---

# OpenClaw gateway startup failure after update

## Context
When pressing the update button for openclaw, the systemd gateway service entered a crash loop and failed to start. 

## Guidance
The issue was caused by a breaking change in the `channels.telegram.streaming` configuration key in `/root/.openclaw/openclaw.json`. Previously a scalar value, the new OpenClaw version requires it to be an object.

To repair this, run the `openclaw doctor --fix` command inside the LXC container which automatically migrates legacy configuration keys to their proper formats and canonicalizes them. 

Additionally, the gateway service may need to be reinstalled if it embeds an `OPENCLAW_GATEWAY_TOKEN`.

### When to Apply
If openclaw fails to boot after an update, especially with `gateway.startup_failed` reasons in `/root/.openclaw/logs/stability/`.

### Examples

Check the logs for startup issues:
```bash
ssh pve.tail "pct exec 101 -- ls -la /root/.openclaw/logs/stability/"
ssh pve.tail "pct exec 101 -- cat /root/.openclaw/logs/stability/openclaw-stability-*.json"
```

Fix configuration and re-install the gateway:
```bash
ssh pve.tail "pct exec 101 -- /bin/openclaw doctor --fix"
ssh pve.tail "pct exec 101 -- /bin/openclaw gateway install --force"
```
