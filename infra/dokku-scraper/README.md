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
Once the LXC is up and reachable, run the setup script. This installs Dokku, PostgreSQL, Let's Encrypt, and Tailscale (userspace mode).
```bash
./setup-dokku.sh
```

**CRITICAL: Authenticate Tailscale**
SSH into the container and join your tailnet:
```bash
ssh scraper.tail.root
tailscale up
```

**Public Exposure (Tailscale Funnel)**
To allow public traffic (IPv4) to reach your private LXC:
```bash
ssh scraper.tail.root "tailscale funnel 443 on"
```

### 3. Deploy the App
Add the Dokku remotes to your application repository:

**Production (sauspiel.sebastianfellner.de):**
```bash
git remote add dokku dokku@scraper.tail:sauspiel-scraper
git push dokku main
```

**SSL Activation:**
Wait until **after** your first successful deploy, then enable SSL:
```bash
ssh scraper.tail.root "dokku letsencrypt:enable sauspiel-scraper"
```

**Development:**
```bash
git remote add dokku-dev dokku@scraper.tail:sauspiel-scraper-dev
git push dokku-dev develop:main
```

## GitHub Actions Deployment

The application repository includes a GitHub Actions workflow that is **branch-aware**:

- Pushes to **`main`** deploy to `sauspiel-scraper` (Production).
- Pushes to **`develop`** deploy to `sauspiel-scraper-dev` (Development).

### Required Secrets
Add these to your application repo:
1. `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET`
2. `DOKKU_HOST` (e.g. `scraper.tailnet-name.ts.net`)
3. `SSH_PRIVATE_KEY` (corresponding to the key in Dokku's `admin`)

## Database Access

Both databases are exposed via Tailscale for remote access from your dev machine.

| Environment | Host | Port | Database |
| :--- | :--- | :--- | :--- |
| **Production** | `scraper.tail` | `5432` | `sauspiel_scraper_db` |
| **Development** | `scraper.tail` | `5433` | `sauspiel_scraper_db_dev` |

Note: Connection strings start with `postgresql://`.
