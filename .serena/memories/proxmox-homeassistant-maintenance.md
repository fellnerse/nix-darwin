# Proxmox & Home Assistant OS Maintenance

## Infrastructure
- **Proxmox host**: `pve.local` (SSH configured, no password)
- **Home Assistant OS VM**: ID 100 on `local-lvm` (thin provisioned)
- **HAOS SSH**: `homeassistant.local` (SSH configured, no password)

### Remote access via Tailscale
- **HA Tailscale hostname**: `<homeassistant-ts-hostname>`
- **SSH aliases** (configured in nix-darwin `common.nix`):
  - `ssh homeassistant.tail` — reach HA via Tailscale from anywhere
  - `ssh pve.tail` — reach PVE via HA as ProxyJump from anywhere
  - `ssh openclaw.tail` — reach OpenClaw container as `sefe` user (192.168.178.61) via HA as ProxyJump
  - `ssh openclaw.tail.root` — reach OpenClaw container as `root`
  - `ssh homeassistant.local` / `ssh pve.local` — direct access on home network
- **Requirement**: Terminal & SSH addon must have `tcp_forwarding: true` (set in HA UI: Settings → Add-ons → Terminal & SSH → Configuration)
- HA also serves as a Tailscale exit node

## Disk Expansion (HAOS on Proxmox)

### Safe expansion process
1. Resize disk in Proxmox (no VM shutdown needed):
   ```bash
   ssh pve.local "qm resize <VMID> scsi0 +<SIZE>G"
   ```
2. Reboot VM - HAOS auto-expands data partition:
   ```bash
   ssh pve.local "qm reboot <VMID>"
   ```
3. Verify:
   ```bash
   ssh homeassistant.local "ha host info"
   ```

### Thin provisioning notes
- Virtual size can exceed physical pool - space consumed only as data written
- **DANGER**: If thin pool hits 100%, VMs get I/O errors and filesystem corruption!
- Check actual usage: `lvs -a -o lv_name,lv_size,data_percent,pool_lv pve`
- Keep pool below 85% to be safe
- **LIMITATION**: Thin pools can only be extended, NOT shrunk! `lvreduce` fails with "cannot be reduced in size yet"
- To reduce pool size, must backup VMs, destroy pool, recreate smaller, restore - not worth the risk

### Monitoring thin pool usage
```bash
# Check thin pool percentage
ssh pve.local "lvs pve/data -o lv_name,lv_size,data_percent"

# Check total virtual vs physical
ssh pve.local "lvs -a -o lv_name,lv_size,data_percent,pool_lv pve"
```

### Extending thin pool
```bash
# Check free space in volume group
ssh pve.local "vgs pve"

# Extend thin pool with all free VG space
ssh pve.local "lvextend -l +100%FREE pve/data"
```

## Proxmox Container Management

### List VMs and containers
```bash
ssh pve.local "qm list"           # VMs
ssh pve.local "pct list"          # LXC containers
```

### Delete container with storage
```bash
ssh pve.local "pct destroy <CTID> --purge"
```

### Find orphaned disks
```bash
ssh pve.local "lvs -a -o lv_name,lv_size,data_percent,pool_lv pve | grep -E '(vm-|base-)'"
```
Compare against `qm list` and `pct list` to identify orphans.

## Home Assistant Backup Management

### Google Drive Backup addon (cebe7a76_hassio_google_drive_backup)
Key settings:
- `max_backups_in_ha`: max local backups
- `max_backups_in_google_drive`: max cloud backups  
- `days_between_backups`: backup frequency
- `ignore_upgrade_backups`: if true, addon update backups pile up and are NOT auto-deleted

### Change addon settings via API (CLI lacks options command)
```bash
ssh homeassistant.local 'curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" -d "{\"options\": {\"setting_name\": value}}" http://supervisor/addons/<addon_slug>/options'
```

### List and delete backups
```bash
# List all backups
ssh homeassistant.local "ha backups list --raw-json" | jq '.data.backups[]'

# Delete partial (addon update) backups in bulk (run from local machine with jq)
SLUGS=$(ssh homeassistant.local "ha backups list --raw-json" | jq -r '.data.backups[] | select(.type == "partial") | .slug')
for slug in $SLUGS; do ssh homeassistant.local "ha backups remove $slug"; done
```

### Check disk usage
```bash
ssh homeassistant.local "ha host info" | grep disk_
```

## HAOS Shell Limitations
- HAOS uses BusyBox with limited commands (no grep -P, limited bash features)
- Use `ha` CLI commands or Supervisor API instead of filesystem access
- For complex parsing, fetch JSON to local machine and use `jq`

## USB Zigbee/Thread Adapter Management

### Hardware inventory
| Adapter | Chip | Z2M Adapter Type | Use Case |
|---------|------|------------------|----------|
| Sonoff Zigbee 3.0 USB Dongle Plus V2 | TI CC2652 | `zstack` | Zigbee2MQTT |
| Nabu Casa SkyConnect | Silicon Labs EFR32 | `ember` (EZSP) | OpenThread Border Router |

### Persistent device paths (CRITICAL)
USB device paths like `/dev/ttyUSB0` can swap on reboot. Always use persistent by-id paths:
```bash
ssh homeassistant.local "ls -la /dev/serial/by-id/"
```
Example output:
```
usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_<serial>-if00-port0 -> ../../ttyUSB1
usb-Nabu_Casa_SkyConnect_v1.0_<serial>-if00-port0 -> ../../ttyUSB0
```

### Zigbee2MQTT configuration
Config file: `/config/zigbee2mqtt/configuration.yaml`
```yaml
serial:
  adapter: zstack  # IMPORTANT: Must match adapter chip type
  port: /dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_<serial>-if00-port0
```

### Addon options vs configuration file
- **Addon options** (set via UI) override config file for certain settings like `serial.port`
- The Supervisor maintains its own database and will revert direct file edits to `options.json`
- To change addon options programmatically, must use Supervisor API from within an addon context
- **Workaround**: Edit config file for settings not controlled by addon options (like `adapter:`)

### Check/modify addon options
```bash
# View addon options
ssh homeassistant.local "ha addons info <addon_slug> --raw-json" | jq '.data.options'

# Addon slugs
# - Zigbee2MQTT: 45df7312_zigbee2mqtt
# - OpenThread BR: core_openthread_border_router
```

### Proxmox guest exec for HAOS filesystem access
When you need to access HAOS filesystem directly (bypassing SSH addon container):
```bash
# Read a file
ssh pve.local "qm guest exec 100 -- cat /path/to/file"

# Execute commands
ssh pve.local 'qm guest exec 100 -- sh -c "command here"'
```

### Common errors and fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Failed to start EZSP layer with status=HOST_FATAL_ERROR` | Wrong adapter type or device conflict | Check adapter type matches chip, use by-id paths |
| `No valid USB adapter found` | Device path doesn't exist or wrong path | Verify device exists with `ls /dev/serial/by-id/` |
| `Matched adapter=ember` when using Sonoff | Auto-detection picked wrong adapter | Explicitly set `adapter: zstack` in config |
| OTBR `mDNSPlatformSendUDP error 99` on veth interfaces | mDNS on Docker virtual interfaces | Harmless - ignore these errors |
| OTBR `Failed to process Link Accept: Security` | Brief handshake issues during network formation | Normal, resolves automatically |

## OpenClaw LXC Container (CT 101)

OpenClaw runs in a standalone Debian 12 LXC container on PVE, separate from Home Assistant.

### Container details
- **CT ID**: 101
- **Hostname**: openclaw
- **IP**: 192.168.178.61 (DHCP on vmbr0)
- **SSH aliases**:
  - `ssh openclaw.tail` — non-root user `sefe` (with passwordless sudo)
  - `ssh openclaw.tail.root` — root access
- **OS**: Debian 12 (bookworm)
- **Resources**: 1536 MB RAM, 512 MB swap, 2 cores, 8 GB rootfs
- **Users**: `root` (openclaw runtime), `sefe` (non-root, passwordless sudo, for Homebrew and tooling)
- **Node.js**: v22 (nodesource)
- **OpenClaw**: v2026.2.25 (installed via `curl -fsSL https://openclaw.ai/install.sh | bash`)
- **Gemini CLI**: v0.31.0 (`@google/gemini-cli`, used for OAuth auth)
- **Go**: 1.24.1 (installed from official tarball to `/usr/local/go`, replacing Debian's 1.19)
- **Homebrew**: installed as `sefe` user at `/home/linuxbrew/.linuxbrew` (root can't run brew directly)
- **pnpm**: v10.30.3 (installed via npm, global dir at `/root/.local/share/pnpm`)
- **Memory search**: disabled (requires embedding API key; Gemini CLI OAuth doesn't support embeddings)
- **Session memory**: file-based (`MEMORY.md` in workspace); `session-memory` hook is enabled — requires `/root/.openclaw/workspace/MEMORY.md` to exist (created empty to prevent ENOENT errors that stall agent startup)
- **Agent timeout**: 900s (increased from default 600s to give browser tool more startup time)
- **Chromium**: v145, runs as a separate systemd service (`chromium-headless.service`) on port 9222
- **OpenClaw browser profile**: `remote-cdp` (connects to Chromium via CDP, not OpenClaw's built-in launcher which fails in LXC)

### Key paths
- **Config**: `/root/.openclaw/openclaw.json`
- **Auth profiles**: `/root/.openclaw/agents/main/agent/auth-profiles.json`
- **Sessions**: `/root/.openclaw/agents/main/sessions/sessions.json`
- **Logs**: `/tmp/openclaw/openclaw-<date>.log`
- **Systemd service**: `/root/.config/systemd/user/openclaw-gateway.service`

### Service management
```bash
# Gateway
ssh openclaw.tail.root "openclaw gateway status"
ssh openclaw.tail.root "systemctl --user status openclaw-gateway"
ssh openclaw.tail.root "systemctl --user restart openclaw-gateway"

# Headless Chromium (system service, not user service)
ssh openclaw.tail.root "systemctl status chromium-headless"
ssh openclaw.tail.root "systemctl restart chromium-headless"
# Verify CDP: curl -s http://127.0.0.1:9222/json/version
```

### Tailscale
- **Tailscale IP**: `100.x.x.x`
- **Tailscale hostname**: `<openclaw-ts-hostname>`
- **`tailscale serve`**: proxies `https://<openclaw-ts-hostname>/` → `http://127.0.0.1:18789`
- **Networking mode**: userspace (`--tun=userspace-networking`) — LXC containers don't have `/dev/net/tun`
- **Systemd override**: `/etc/systemd/system/tailscaled.service.d/override.conf` adds `--tun=userspace-networking`
- **Gateway Tailscale config**: `gateway.tailscale.mode = "serve"` in `openclaw.json`
- **No `publicUrl` key** — OpenClaw doesn't use it; `tailscale serve` handles routing automatically

### Configuration
- **Auth**: Google Gemini CLI (OAuth, not API key)
- **Model**: `google/gemini-2.5-pro`
- **Telegram bot**: @Beschderbot (token stored in openclaw.json)
- **Telegram dmPolicy**: `allowlist` (pairing mode is broken)
- **Telegram allowFrom**: `8280400914` (Sebastian)

### Installed skill dependencies
Installed to support OpenClaw's bundled skills:

| Dependency | Version | Installed via | Provides skill |
|------------|---------|---------------|----------------|
| clawhub | 0.7.0 | pnpm (`/root/.local/share/pnpm`) | clawhub |
| gifgrep | 0.2.3 | `go install` (`/root/go/bin/`, symlinked to `/usr/local/bin/`) | gifgrep |
| goplaces | 0.3.0 | brew `steipete/tap` (`/home/linuxbrew/.linuxbrew/bin/`) | goplaces |
| sonos (sonoscli) | 0.1.1 | `go install` (`/root/go/bin/`, symlinked to `/usr/local/bin/`) | sonoscli |

**Skills status**: 9/51 ready (clawhub, coding-agent, gemini, gifgrep, goplaces, healthcheck, skill-creator, sonoscli, weather).
Most missing skills are macOS-only (Apple Notes, Apple Reminders, Bear, etc.) and won't work on Linux.
`summarize` (steipete/tap/summarize) requires arm64 — no x86_64 build available.

### Installing new Go-based skill dependencies
The container ships Go 1.19 from Debian 12, but Go 1.24 is installed at `/usr/local/go`. Use:
```bash
GOPATH=/root/go /usr/local/go/bin/go install <package>@latest
ln -sf /root/go/bin/<binary> /usr/local/bin/<binary>
```

### Installing brew-based skill dependencies
Must run as `sefe` (brew refuses root):
```bash
ssh openclaw.tail "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)\" && brew install <formula>"
```
Then symlink for root: `ln -sf /home/linuxbrew/.linuxbrew/bin/<binary> /usr/local/bin/<binary>`

### Updating OpenClaw
```bash
ssh openclaw.tail.root "npm install -g openclaw"
ssh openclaw.tail.root "systemctl --user restart openclaw-gateway"
```

### Control UI (Web Dashboard)
- **URL**: `https://<openclaw-ts-hostname>/`
- **Allowed origins**: configured in `gateway.controlUi.allowedOrigins` in `openclaw.json`
- **Device pairing**: browsers must be paired before they can connect. The gateway puts unknown devices into a "pending" queue.
  ```bash
  # List pending and paired devices
  ssh openclaw.tail.root "openclaw devices list"
  
  # Approve a pending request (get request ID from list)
  ssh openclaw.tail.root "openclaw devices approve <request-id>"
  ```
- **TUI alternative**: `ssh openclaw.tail.root "openclaw tui"` (terminal UI, no pairing needed)

### Browser extension (remote Chrome on Mac) — NOT YET SET UP

OpenClaw supports an `extension` driver that lets the agent control your actual Chrome tabs on your Mac, instead of the headless Chromium on the server. Useful for interacting with pages you're already logged into (authenticated sessions, cookies).

**Architecture** (remote gateway setup):
1. **Mac**: Chrome extension + local OpenClaw **node** (`openclaw node start`) running a CDP relay on port 18792
2. **Gateway** (LXC): Proxies browser commands to the Mac's node over Tailscale
3. **Extension**: Attaches to Chrome tabs via `chrome.debugger`, relays CDP to the node

**Setup steps** (when ready):
1. Install OpenClaw on the Mac (or use the existing `openclaw` from nix)
2. Run `openclaw browser extension install` on the Mac
3. Load the unpacked extension in Chrome: `chrome://extensions` → Developer mode → Load unpacked → path from `openclaw browser extension path`
4. Pin the extension, open Options, set port (18792) and gateway token (must match gateway config)
5. Start a node on the Mac: `openclaw node start` (connects to the remote gateway via Tailscale)
6. Use profile `chrome` (built-in): `openclaw browser --browser-profile chrome tabs`

**Extension badge**: `ON` = attached, `!` = relay unreachable

**Docs**: https://docs.openclaw.ai/tools/chrome-extension

Both profiles can coexist — `remote-cdp` (default) for autonomous headless tasks, `chrome` extension for interactive browsing with your Mac's authenticated sessions.

### Common issues (LXC container)

| Issue | Cause | Fix |
|-------|-------|-----|
| Go skill install fails with `log/slog` or `toolchain` error | Debian 12 ships Go 1.19, too old | Use `/usr/local/go/bin/go` (1.24) instead |
| `brew not installed` when installing skills | OpenClaw runs as root, brew is under sefe | Install via `ssh openclaw.tail`, then symlink binary |
| `summarize` skill won't install | Requires arm64 (Apple Silicon) | No fix — container is x86_64 |
| `spawn pnpm ENOENT` | pnpm not in PATH | Source `/root/.bashrc` or use full path `/root/.local/share/pnpm/pnpm` |
| `ENOSPC` during npm install | Rootfs full | `ssh pve.tail "pct resize 101 rootfs +4G"` (online, no restart needed) |
| Memory search errors in `openclaw doctor` | No embedding API key | Disabled via `agents.defaults.memorySearch.enabled: false` |
| Gateway token mismatch | Config changed after gateway install | `openclaw gateway install --force && systemctl --user restart openclaw-gateway` |
| Control UI "origin not allowed" | Tailscale origin not in allowedOrigins | Add `https://<openclaw-ts-hostname>` to `gateway.controlUi.allowedOrigins` |
| Control UI "pairing required" | Browser device not yet paired | Run `openclaw devices list` → `openclaw devices approve <request-id>` |
| `tailscaled` fails with `CreateTUN failed; /dev/net/tun does not exist` | LXC container lacks TUN device | Use `--tun=userspace-networking` (configured via systemd override) |
| `gateway.publicUrl` — "Unrecognized key" | OpenClaw doesn't have this config key | Remove it; `tailscale serve` handles public exposure, no config key needed |
| OpenClaw browser "Failed to start Chrome CDP" | OpenClaw's built-in Chrome launcher doesn't work in LXC containers | Use `remote-cdp` profile with separate `chromium-headless` systemd service on port 9222 |
| Agent browser tool "Can't reach browser control service (timed out)" | First browser tool call after gateway restart is slow (~15-20s); built-in 15s timeout too tight | Gateway restart + increased `agents.defaults.timeoutSeconds` to 900; subsequent calls are fast (50-70ms) |
| ENOENT on `/root/.openclaw/workspace/MEMORY.md` at session start | `session-memory` hook tries to read MEMORY.md but file doesn't exist | Create empty file: `touch /root/.openclaw/workspace/MEMORY.md` |
| Rootfs disk full (ENOSPC) | Playwright browsers + deps take ~500MB | `ssh pve.tail "pct resize 101 rootfs +4G"` (online, no restart) — container is now 12GB |

## ARCHIVED: OpenClaw HA Addon (removed)
The old HA addon (17e0cc66_openclaw_assistant) has been removed. Below is kept for reference only.

### Old Addon Details

### Key paths
- **Config directory**: `/config/.openclaw/` (persisted across restarts)
- **Auth profiles**: `/config/.openclaw/agents/main/agent/auth-profiles.json`
- **Main config**: `/config/.openclaw/openclaw.json`
- **Gateway logs**: `/tmp/openclaw/openclaw-<date>.log`

### Container access
The addon runs in a Docker container. Access it via Proxmox guest exec:
```bash
ssh pve.local 'qm guest exec 100 -- docker exec addon_17e0cc66_openclaw_assistant <command>'
```

### Systemd warnings are expected
In a container, `openclaw gateway status` shows systemd warnings - this is normal. The gateway runs via the addon's s6 supervisor, not systemd. Check `RPC probe: ok` to confirm it's working.

### Configuring LLM providers
OpenClaw uses API keys, not OAuth. Configure via onboard command:
```bash
openclaw onboard --non-interactive --accept-risk --auth-choice gemini-api-key --gemini-api-key "KEY" --skip-channels --skip-skills --skip-daemon
```

**Important**: The onboard command writes to `/root/.openclaw/` but the addon uses `/config/.openclaw/`. Copy auth-profiles.json manually:
```bash
mkdir -p /config/.openclaw/agents/main/agent
cp /root/.openclaw/agents/main/agent/auth-profiles.json /config/.openclaw/agents/main/agent/
```

### Setting the model
Edit `/config/.openclaw/openclaw.json` directly with jq:
```bash
cat openclaw.json | jq '.agents.defaults.model = {"primary": "google/gemini-2.5-pro"}' > tmp && mv tmp openclaw.json
```

Supported providers include: `anthropic`, `google`, `openrouter`, `openai`, `venice`, etc.
Model format: `provider/model-name` (e.g., `google/gemini-2.5-pro`, `anthropic/claude-opus-4-6`)

### Gateway public URL
For Tailscale access, the `gateway_public_url` must include the ingress path:
```
https://homeassistant.tail401ae4.ts.net/api/hassio_ingress/<ingress_token>
```

Get the ingress token:
```bash
ssh homeassistant.local "ha apps info 17e0cc66_openclaw_assistant --raw-json" | jq '.data.ingress_url'
```

### Updating addon options
Must include ALL required options when using the API:
```bash
ssh homeassistant.local 'curl -s -X POST -H "Authorization: Bearer $SUPERVISOR_TOKEN" -H "Content-Type: application/json" -d "{\"options\": {<all_options>}}" http://supervisor/addons/17e0cc66_openclaw_assistant/options'
```

### Common issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `No API key found for provider` | Missing auth-profiles.json | Run onboard and copy auth file to `/config/.openclaw/` |
| Dashboard redirects to HA | Wrong `gateway_public_url` | Include full ingress path in URL |
| Config changes not applied | CLI writes to `/root/` not `/config/` | Edit `/config/.openclaw/` directly or copy files |
| `systemctl --user unavailable` | Container environment | Expected - gateway runs via s6, not systemd |
| Telegram pairing not working | `dmPolicy: "pairing"` is broken in v0.5.45 | Use `dmPolicy: "allowlist"` with explicit user IDs - see `openclaw-telegram-config` memory |
| Telegram messages silently dropped | Old session or offset file | Delete sessions.json and update-offset files, restart addon |

## Disaster Recovery - Thin Pool Full / I/O Errors

### Symptoms
- VM boot loop or drops to rescue shell
- `dmesg` shows: `Buffer I/O error on dev dm-X, logical block XXXXX, lost async page write`
- `lvs` shows `data` at 100% Data%

### Root cause
Thin pool ran out of physical space. VMs couldn't write, causing filesystem corruption.

### Recovery procedure

#### 1. Free space on Proxmox host
```bash
# Check thin pool status
ssh pve.local "lvs pve/data -o lv_name,lv_size,data_percent"

# Delete orphaned disks (VMs that no longer exist)
ssh pve.local "lvremove pve/base-XXX-disk-0"

# Or destroy entire broken VM
ssh pve.local "qm destroy <VMID> --purge"
```

#### 2. Boot from GParted Live ISO to repair filesystem
```bash
# Download GParted ISO
ssh pve.local "cd /var/lib/vz/template/iso && wget https://downloads.sourceforge.net/gparted/gparted-live-1.6.0-3-amd64.iso"

# Attach ISO and set boot order
ssh pve.local "qm set <VMID> -ide2 local:iso/gparted-live-1.6.0-3-amd64.iso,media=cdrom"
ssh pve.local "qm set <VMID> -boot order=ide2"
ssh pve.local "qm start <VMID>"
```

In GParted console:
```bash
# Repair HAOS partitions
sudo fsck.vfat -a /dev/sda1      # boot partition
sudo fsck.ext4 -y /dev/sda7      # overlay partition  
sudo fsck.ext4 -y /dev/sda8      # data partition

# CRITICAL: Reclaim space in thin pool with fstrim
sudo mount /dev/sda8 /mnt/data
sudo fstrim -v /mnt/data
sudo umount /mnt/data
```

#### 3. Delete old backups from inside GParted
```bash
sudo mount /dev/sda8 /mnt/data
sudo du -sh /mnt/data/supervisor/backup/*
sudo rm -rf /mnt/data/supervisor/backup/<old-backup>
sync
sudo fstrim -v /mnt/data
sudo umount /mnt/data
```

#### 4. Restore boot order
```bash
ssh pve.local "qm stop <VMID>"
ssh pve.local "qm set <VMID> -boot order=scsi0"
ssh pve.local "qm set <VMID> -delete ide2"
ssh pve.local "qm start <VMID>"
```

### If filesystem is unrecoverable - Fresh install + restore

#### 1. Create fresh HAOS VM
```bash
# Download latest HAOS
ssh pve.local "wget -O /var/lib/vz/template/iso/haos.qcow2.xz 'https://github.com/home-assistant/operating-system/releases/download/14.2/haos_ova-14.2.qcow2.xz'"
ssh pve.local "cd /var/lib/vz/template/iso && xz -d haos.qcow2.xz"

# Create new VM with same settings (preserves MAC = same IP)
ssh pve.local "qm create 100 --name homeassistant --memory 6144 --cores 2 \
  --net0 virtio=02:0A:EC:D7:F6:87,bridge=vmbr0 --bios ovmf --machine q35 \
  --efidisk0 local-lvm:1,efitype=4m --agent enabled=1 --onboot 1 \
  --cpu host --scsihw virtio-scsi-pci"

# Import disk
ssh pve.local "qm importdisk 100 /var/lib/vz/template/iso/haos.qcow2 local-lvm"
ssh pve.local "qm set 100 --scsi0 local-lvm:vm-100-disk-1,cache=writethrough,discard=on,ssd=1 --boot order=scsi0"

# Add USB passthrough
ssh pve.local "qm set 100 --usb0 host=1cf1:0030 --usb1 host=10c4:ea60 --usb2 host=303a:1001 --usb3 host=10c4:ea60"

# Start
ssh pve.local "qm start 100"
```

#### 2. Restore from Google Drive backup
- Access Home Assistant at http://homeassistant.local:8123
- During onboarding, choose "Restore from backup"
- Use Google Drive backup addon backup

#### 3. Post-restore: Restart Zigbee2MQTT
After restore, Zigbee mesh routing tables are stale. Commands fail with `NWK_NO_ROUTE` or `Timeout`.
```bash
ssh homeassistant.local "ha addons restart 45df7312_zigbee2mqtt"
```
If some devices still don't respond, power cycle router devices (mains-powered plugs, repeaters).

### Prevention
- **Monitor thin pool** - keep below 85%
  - `dmeventd` logs warnings to journal at 80%, 90%, 95%, 100% thresholds
  - But no email alerts by default - configure Proxmox datacenter notifications
- **Limit local backups** in Google Drive Backup addon:
  - Set `max_backups_in_ha: 1` or `2` to prevent backup accumulation
  - Backups are the #1 cause of unexpected storage growth
- **Ensure `discard=on`** on VM disk for automatic TRIM (check: `qm config <VMID> | grep scsi0`)
- **HA built-in disk alerts**: Settings → System → Repairs shows low disk warnings
  - Can also add System Monitor integration for `disk_use_percent` sensor + automations
- **Check actual usage inside VM** (not just thin pool allocation):
  ```bash
  ssh pve.local "qm guest exec 100 -- df -h /mnt/data"
  ssh pve.local "qm guest exec 100 -- du -h -d1 /mnt/data"
  ```
- **Docker cleanup** if needed (rarely reclaimable, but worth checking):
  ```bash
  ssh pve.local "qm guest exec 100 -- docker system df"
  ```
