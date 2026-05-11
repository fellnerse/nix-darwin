---
title: "feat: Setup Dokku on Proxmox LXC for Sauspiel Scraper"
type: feat
status: completed
date: 2026-05-09
origin: docs/brainstorms/2026-05-09-sauspiel-scraper-dokku-migration-requirements.md
---

# feat: Setup Dokku on Proxmox LXC for Sauspiel Scraper

## Overview
This plan establishes a self-hosted Dokku PaaS on a dedicated Debian 12 LXC container within the existing Proxmox cluster. This replaces the planned Render deployment and provides a persistent PostgreSQL database via the Dokku PostgreSQL plugin.

---

## Problem Frame
Render's free tier lacks persistent ephemeral storage for SQLite. To ensure data persistence and a production-grade environment, we are migrating to a self-hosted Proxmox environment with Dokku for a "git push" deployment experience.

---

## Requirements Trace
- R1. Provision a Debian 12 LXC container on Proxmox.
- R2. Install Dokku and required plugins (PostgreSQL).
- R3. Configure container with appropriate resource limits (balancing host stability).
- R4. Integrate host management into the existing Nix-Darwin repository.
- R5. Establish remote access via Tailscale (consistent with OpenClaw CT).

---

## Scope Boundaries
- **In Scope:** 
  - Automation scripts for LXC creation and Dokku setup.
  - Integration of the new host into `home-manager` SSH configuration.
  - Documentation of the deployment flow.
- **Out of Scope:**
  - Application-level code changes (SQLAlchemy migration is a separate plan).
  - Physical Proxmox host maintenance.

---

## Context & Research

### Relevant Code and Patterns
- `proxmox-homeassistant-maintenance.md`: Patterns for `pct` and `qm` management.
- `home-manager/common.nix`: Patterns for declarative SSH aliases.
- `openclaw` (CT 101): Pattern for Debian LXC with Tailscale userspace networking.

### Institutional Learnings
- **Disk Space:** Host `pve/data` thin pool has ~45GB available.
- **RAM:** Host has 1.7GiB available RAM.
- **Networking:** Tailscale in LXC requires `userspace-networking` and `keyctl`/`nesting` features.

---

## Key Technical Decisions
- **Resource Allocation:** 2 Cores, 2GB RAM (1GB Physical + 1GB Swap), 15GB Disk.
- **LXC ID:** `102` (next available after `101`).
- **OS:** Debian 12 (Bookworm).
- **Storage Driver:** Docker `overlay2` (LVM-Thin on PVE host).

---

## Thin Pool Safety (Lessons from HAOS Accident)
To "really make sure" we don't hit the 100% Thin Pool crash documented in `proxmox-homeassistant-maintenance.md`, we will implement:
1. **Pre-flight Check:** `bootstrap.sh` will query `lvs pve/data` and abort if `Data% > 70%`.
2. **Automatic TRIM:** The LXC will be created with `-rootfs local-lvm:10,discard=on` to ensure deleted blocks are reclaimed immediately by the host.
3. **Build Cleanup:** `setup-dokku.sh` will install a cron job for `dokku cleanup:buildcache` and `docker system prune -f` to prevent image layer accumulation.
4. **Conservative Sizing:** We have set the disk to 15GB. With current usage at 48%, this keeps the total virtual allocation (HAOS 32G + OpenClaw 12G + Scraper 15G = 59G) well below the 68GB physical limit, providing a ~9GB absolute safety buffer even if all containers hit 100% usage.

---

## Open Questions

### Resolved During Planning
- **ZFS vs LVM:** Host uses LVM-Thin, so no special ZFS ZVOL mounting is needed for Docker.
- **Resource Limits:** Adjusted downward from 4GB to 2GB to match host availability.

### Deferred to Implementation
- **IP Assignment:** Whether to use a DHCP reservation or a hardcoded static IP in `pct create`.

---

## Output Structure
```
infra/dokku-scraper/
├── bootstrap.sh         # Proxmox-side LXC creation
├── setup-dokku.sh       # Container-side Dokku orchestration
└── README.md            # Management guide
```

---

## Implementation Units

- U1. **Add SSH Aliases to home-manager**
**Goal:** Enable easy access to the new host.
**Requirements:** [R5]
**Files:**
- Modify: `home-manager/common.nix`
**Approach:** Add `scraper.tail` and `scraper.tail.root` aliases using `pve.tail` as a proxy if needed, or direct via `homeassistant.tail`.

- U2. **Infrastructure Scaffolding**
**Goal:** Create the directory for infra scripts.
**Files:**
- Create: `infra/dokku-scraper/README.md`
- Create: `infra/dokku-scraper/bootstrap.sh`
- Create: `infra/dokku-scraper/setup-dokku.sh`

- U3. **LXC Bootstrapping Script (`bootstrap.sh`)**
**Goal:** Automate the creation of the LXC container on PVE host.
**Requirements:** [R1, R3]
**Approach:** Use `ssh pve.tail` to run `pct create 102`, set features (`nesting=1,keyctl=1`), and configure networking.

- U4. **Dokku Orchestration Script (`setup-dokku.sh`)**
**Goal:** Automate Dokku and Postgres installation.
**Requirements:** [R2]
**Approach:** Script the official Dokku bootstrap, install `dokku-postgres`, and create the `sauspiel-scraper` app.

---

## System-Wide Impact
- **Proxmox Resources:** Adds ~15GB virtual disk allocation and up to 2GB RAM usage to the PVE host.

---

## Risks & Dependencies
| Risk | Mitigation |
|------|------------|
| Host Disk Exhaustion | Monitor thin pool via `lvs` before and after provisioning. |
| Tailscale Handshake | Use userspace-networking override as documented in `openclaw` notes. |
