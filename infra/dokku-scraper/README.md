# Dokku Scraper Infrastructure

This directory contains the automation for provisioning a Dokku-based Debian 12 LXC on Proxmox for the Sauspiel Scraper.

## Deployment Overview

1.  **Bootstrap:** Create the LXC on the Proxmox host.
2.  **Setup:** Install Dokku, PostgreSQL, and configure the app.
3.  **App Deployment:** Push the application code to the new host.

## Safety First: Thin Pool Protection

Following a past incident where the Proxmox thin pool hit 100%, these scripts include:
- **Pre-flight checks:** Abort if host disk usage > 70%.
- **TRIM Support:** `discard=on` enabled for the container.
- **Auto-Cleanup:** Daily Docker/Dokku cleanup cron jobs.

## Usage

### 1. Bootstrap the LXC
Run from this machine (uses `pve.tail` SSH alias):
```bash
./bootstrap.sh
```

### 2. Setup Dokku & Tailscale
Once the LXC is up and reachable, run the setup script. This installs Dokku, PostgreSQL, and Tailscale (userspace mode).
```bash
./setup-dokku.sh
```

**CRITICAL: Authenticate Tailscale**
SSH into the container and join your tailnet:
```bash
ssh scraper.tail.root
tailscale up
```

### 3. Deploy the App
Add the Dokku remote to your application repository:
```bash
git remote add dokku dokku@scraper.tail:sauspiel-scraper
git push dokku main
```
Note: Ensure your local machine is also on Tailscale to resolve `scraper.tail`.
