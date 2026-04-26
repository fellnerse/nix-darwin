---
title: OpenClaw memory exhaustion caused by orphaned Chromium processes
date: 2026-04-26
category: performance-issues
module: openclaw-lxc
problem_type: performance_issue
component: assistant
symptoms:
  - "100% memory and swap usage in CT 101"
  - "High I/O wait on Proxmox host (load average ~35)"
  - "Telegram bot unresponsive (embedded run timeouts)"
  - "Processes in uninterruptible sleep (D state)"
root_cause: memory_leak
resolution_type: workflow_improvement
severity: high
tags: [openclaw, chromium, lxc, memory-exhaustion, proxmox, troubleshooting]
---

# OpenClaw memory exhaustion caused by orphaned Chromium processes

## Problem
The OpenClaw LXC container (CT 101) experienced extreme resource exhaustion, leading to a complete system freeze where the Telegram bot stopped responding and SSH access became extremely laggy or timed out.

## Symptoms
- **Resource Spikes**: 100% CPU and 100% Memory usage (1.5Gi/1.5Gi RAM and nearly 100% swap utilized).
- **System Lag**: High I/O wait on the Proxmox host (load average spiked to ~35).
- **Process State**: Multiple processes (including `tailscaled` and `chromium`) entered a `D` state (uninterruptible sleep), indicating they were stuck waiting for disk I/O due to heavy swapping.
- **Bot Failure**: The Telegram bot stopped answering messages; logs showed `WARN` regarding embedded run timeouts (900s).

## What Didn't Work
- **Graceful Interaction**: Standard commands and SSH access were initially impossible due to the I/O lockup.
- **Graceful Restart**: A full container restart was considered but bypassed in favor of a faster, targeted intervention.

## Solution
The issue was resolved by targeting the resource-intensive browser processes and implementing a persistent agent warning:

1. **Force Kill Chromium**: Terminated all renderer processes from the Proxmox host to break the swap thrashing cycle:
   ```bash
   ssh pve.tail "pct exec 101 -- pkill -f chromium"
   ```
2. **Verify Memory Recovery**: Confirmed memory usage dropped from 100% (1.5Gi) to ~50% (769Mi).
3. **Agent Memory Persistence**: Appended a maintenance note to the agent's local `MEMORY.md` to prevent recurrence:
   ```markdown
   ### System Maintenance Note (April 26, 2026)
   - **Action**: Manually terminated all Chromium processes to resolve a system freeze caused by 100% memory and swap usage.
   - **Guidance**: Be more careful with browser resource usage. Prefer reusing existing browser instances or ensure they are explicitly terminated after use to prevent clumping up system resources (CT 101 has 1.5GB RAM limit).
   ```

## Why This Works
The memory exhaustion was caused by excessive Chromium renderer processes generated during browser-based research tasks that failed to terminate. Killing these processes immediately cleared the RAM and stopped the "swap thrashing" that was locking the CPU in I/O wait, allowing the gateway to resume normal operation.

## Prevention
- **Browser Management**: Configure agents to reuse existing Chromium instances or ensure explicit termination of sessions.
- **Resource Limits Awareness**: CT 101 has a strict 1.5GiB RAM ceiling; monitor usage when performing heavy web-based tasks.
- **Agent Tuning**: The `agents.defaults.timeoutSeconds` in `openclaw.json` was increased to 900s to accommodate slower browser startup under load.

## Related Issues
- `.serena/memories/proxmox-homeassistant-maintenance.md` (infrastructure details)
- `.serena/memories/openclaw-telegram-config.md` (channel configuration)
