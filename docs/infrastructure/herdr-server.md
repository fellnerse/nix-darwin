# Herdr Server Runbook & Configuration

This document records the configuration, architecture, and operational procedures for the `herdr` coding agent runtime running on Proxmox VE.

---

## 1. Virtualization & Hardware Specifications

The `herdr` service runs inside an unprivileged LXC container hosted on a Proxmox VE (PVE) node.

- **PVE Host:** Reachable via SSH at `pve.tail` (or `pve.local` when on LAN).
- **Container VMID:** `101` (`pct` management).
- **Guest OS:** Debian GNU/Linux 13 (trixie).
- **Config Path (on PVE):** `/etc/pve/lxc/101.conf`.

### Resource Allocations

| Resource      | Allocation       | Notes                                                                |
| ------------- | ---------------- | -------------------------------------------------------------------- |
| **CPU**       | 2 cores          | Intel Core i3-6100T (host)                                           |
| **RAM**       | 3072 MiB (3 GiB) | Increased from initial 1.5 GiB to support Vite/Node/OMP build spikes |
| **Swap**      | 2048 MiB (2 GiB) | Increased from 512 MiB to prevent cgroup OOM kills                   |
| **Root Disk** | 16 GiB           | Storage pool: `local-lvm:vm-101-disk-0`                              |
| **Features**  | `nesting=1`      | Required for sub-containers / nix / process namespaces               |

> **Host Memory Note:** The PVE host has 7.6 GiB total physical RAM. Home Assistant (VM 100) is configured with virtio-ballooning (`qm set 100 --balloon 4096`) so it releases unused RAM (HA typically uses ~1.8 GiB), preserving 2+ GiB headroom for CT 101.

---

## 2. Networking & Remote Access

### Tailscale Configuration

`herdr` runs Tailscale as a systemd service (`tailscaled.service`) directly inside the container.

- **Tailscale IPv4:** `100.94.59.116`
- **MagicDNS FQDN:** `herdr.tail401ae4.ts.net`
- **Short Name:** `herdr` (resolves via MagicDNS across the tailnet)
- **Firewall:** iptables allows all inbound packets arriving over interface `tailscale0`.

### SSH Configuration (`~/.ssh/config` on Laptop)

```ssh
Host herdr.tail
  HostName herdr.tail401ae4.ts.net
  User root

Host pve.tail
  HostName pve.local
  ProxyJump homeassistant.tail
  User root
```

Authorized public keys in `/root/.ssh/authorized_keys` on `herdr`:

- `sefe@LT6V46LXXQ` (laptop primary key, `~/.ssh/id_rsa.pub`)
- `private@LT6V46LXXQ` (laptop private profile key)
- `root@pve` (PVE cluster key)

---

## 3. Web Dev & HTTPS Access (Port 3000)

Web servers running on `herdr` (e.g. Next.js, Vite, Nuxt) on port `3000` can be exposed to the tailnet in two ways:

### Option A: Automatic Trusted HTTPS via `tailscale serve` (Recommended)

Exposes the local dev server under `https://herdr.tail401ae4.ts.net` with valid Let's Encrypt certificates managed by Tailscale:

```bash
# If your dev server serves HTTP on 3000:
ssh herdr.tail "tailscale serve --bg 3000"

# If your dev server serves HTTPS with self-signed certs:
ssh herdr.tail "tailscale serve --bg https+insecure://localhost:3000"

# Status and cleanup:
ssh herdr.tail "tailscale serve status"
ssh herdr.tail "tailscale serve reset"
```

### Option B: Direct Connection

- Connect to `http://herdr:3000` or `http://herdr.tail401ae4.ts.net:3000`.
- The dev server must bind to `0.0.0.0` (e.g. `vite --host 0.0.0.0`, `next dev -H 0.0.0.0`).
- To get a real Let's Encrypt certificate directly on the machine:
  ```bash
  ssh herdr.tail "tailscale cert herdr.tail401ae4.ts.net"
  ```
  Generates `herdr.tail401ae4.ts.net.crt` and `herdr.tail401ae4.ts.net.key`.

---

## 4. OMP (Oh My Pi) & Herdr Runtime Setup

### Services & Binaries

- **Herdr Server:** Managed via `/etc/systemd/system/herdr.service`.
  - Sockets: `/root/.config/herdr/herdr.sock`, `/root/.config/herdr/herdr-client.sock`
  - Logs: `/root/.config/herdr/herdr-server.log`
- **OMP Binary:** Installed at `/root/.local/bin/omp`, symlinked to `/usr/local/bin/omp`.
  - Config: `/root/.config/herdr/config.toml` (sets `[terminal] default_shell = "/bin/bash"` and `shell_mode = "login"`)

### Environment Variables

Configured in `/etc/environment` and loaded by `herdr.service` (`EnvironmentFile=/etc/environment`) as well as `/root/.bashrc` and `/root/.profile`:

```bash
PATH="/root/.local/bin:/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
NON_EU_API="sk-..."
```

### Models Configuration (`/root/.omp/agent/models.yml`)

Configured to match the providers in `home-manager/omp.nix`, but **manually** -
`omp.nix` is deliberately not imported by `home-manager/home-herdr.nix` (see
§6), so this file stays hand-mirrored, not nix-managed:

- `non-eu`: `https://llm-proxy.dev.ai.edgez.live` (`api: openai-completions`, `litellm` discovery)

---

## 5. Operations & Troubleshooting

### Check Status & Health

```bash
# Check container status from laptop
ssh pve.tail "pct status 101"

# Check memory usage inside herdr
ssh herdr.tail "free -h"

# Check herdr service logs
ssh herdr.tail "journalctl -u herdr.service -n 50 --no-pager"
```

### Adjust Memory or Swap on PVE

Changes to LXC limits apply immediately without restarting:

```bash
ssh pve.tail "pct set 101 -memory 4096 -swap 2048"
```

### Recovering from an OOM Hang

If the container stops responding due to memory thrashing:

```bash
# Check for kernel OOM messages on PVE host
ssh pve.tail "dmesg -T | grep -E 'oom-kill|killed process'"

# Force stop and restart the container
ssh pve.tail "pct stop 101 && pct start 101"
```

### Disk Space

Root disk is 16 GiB total (§1) and Nix chews through it fast (builds, tarball
cache, eval cache). Check and reclaim:

```bash
ssh herdr.tail "df -h /"

# Nix garbage collection - deletes unreferenced store paths (old
# generations, build-time-only deps); everything regenerates/re-downloads
# on the next build. Same as the repo's `mise run gc` task.
ssh herdr.tail "nix-collect-garbage -d"

# If still tight, regenerable build caches are usually the next-biggest
# offenders - safe to wipe, all repopulate on demand:
ssh herdr.tail "rm -rf ~/.cache/ms-playwright/* ~/.cache/node-gyp ~/.cache/nix/tarball-cache-v2 ~/.cache/nix/eval-cache-v6 ~/.local/share/pnpm/store"
ssh herdr.tail "npm cache clean --force"

# node_modules under /root/projects/*/node_modules are also fair game
# (npm/pnpm install regenerates them) - check nothing's actively running
# against them first (ps aux | grep -E 'node|pnpm|vite|next').
```

Growing the actual LXC root disk (`pct resize 101 rootfs +<N>G` on the PVE
host, or via the PVE web UI) has to be run from a machine with the
`pve.tail` SSH alias (your laptop) - herdr itself has no outbound
credentials to reach `pve.local`/`pve.tail`, only inbound `authorized_keys`.

---

## 6. Nix / home-manager Management

herdr has no nix-darwin/NixOS - it's a standalone `home-manager` profile for
`root` (everything here runs as root today), defined in
`home-manager/home-herdr.nix` and wired up as `homeConfigurations.herdr` in
`flake.nix`. It intentionally reuses only `home-manager/claude.nix` from the
rest of the repo:

- **Managed:** Claude Code's global env (`~/.claude/settings.json` →
  `env`: model routing through the same `llm-proxy.edgez.live` proxy OMP
  already uses, telemetry/error-reporting disabled via `DISABLE_TELEMETRY`
  / `DISABLE_ERROR_REPORTING`) and the `context7` MCP server
  (`~/.claude.json` → `mcpServers`).
- **Not managed, on purpose:**
  - `home-manager/omp.nix` (OMP's `models.yml`/`config.yml`/`mcp.json`) -
    that's sefe/private-scoped personal provider config; herdr's
    `/root/.omp/agent/*` stays manually maintained (see §4 above).
  - The `atlassian` MCP server and the `ai-tooling-marketplace` Claude Code
    plugin/statusline - both are sefe-only opt-ins added in
    `home-manager/home.nix` (the marketplace plugin needs SSH access to
    `gitlab.netlight.com`, which herdr doesn't have). `claude.nix` exposes
    `options.claude.{mcpServers,settings}` precisely so per-profile files
    can add these without every profile inheriting them.
- **Config-merge safety:** every write goes through
  `lib/config-merge.nix` (`mergeFile`/`setPath`), which deep-merges the
  declared keys over whatever's already on disk rather than clobbering the
  file - keys Claude Code itself writes at runtime (`theme`,
  `feedbackDrafts`, ...) survive untouched.

Apply changes (no local clone needed on herdr - pulls straight from GitHub):

```bash
ssh herdr.tail "nix run home-manager/release-26.05 -- switch --flake github:fellnerse/nix-darwin#herdr -b backup"
```

`-b backup` renames any pre-existing plain file `home-manager` would
otherwise collide with (suffixed `.backup`) instead of failing.
