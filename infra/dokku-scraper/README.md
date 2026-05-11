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
CREATE_DEV_ENV="true" ./setup-dokku.sh
```

**CRITICAL: Authenticate Tailscale**
SSH into the container and join your tailnet:
```bash
ssh scraper.tail.root
tailscale up
```

The script automatically enables **Tailscale Funnel** to expose your apps to the internet securely. *Note: This Funnel state is saved by the Tailscale daemon and will automatically persist across server reboots. You do not need a custom startup script.*

### 3. Deploy the App
Add the Dokku remotes to your application repository:

**Production:**
```bash
git remote add dokku dokku@scraper.tail:sauspiel-scraper
git push dokku main
```

**Development:**
```bash
git remote add dokku-dev dokku@scraper.tail:sauspiel-scraper-dev
git push dokku-dev develop:main
```

## Architecture & Routing

Because we are using the native Tailscale domain (`*.ts.net`) for automatic SSL, we cannot rely solely on domain names to separate the two environments. Instead, we use a hybrid approach combining virtual hosts and port mapping:

| Environment | Internal Dokku Routing | Tailscale Funnel Mapping | Public URL |
| :--- | :--- | :--- | :--- |
| **Production** | Nginx virtual host (`scraper...ts.net`) on port **80** | Public **443** -> Local `127.0.0.1:80` | `https://scraper.tailnet.ts.net/` |
| **Development** | Explicit Dokku port binding on port **8080** | Public **8443** -> Local `127.0.0.1:8080` | `https://scraper.tailnet.ts.net:8443/` |

**How Dokku knows where to route:**
1. **Production:** When traffic hits Funnel on 443, it is forwarded to local port 80. Dokku's Nginx listens on port 80 and checks the `Host` header. Since we set the app's domain to `scraper.tail...ts.net`, Nginx matches it and routes it to the production container.
2. **Development:** We explicitly bypassed Nginx virtual hosts for the dev app by running `dokku ports:add sauspiel-scraper-dev http:8080:5000`. This directly binds the dev container to host port 8080. When traffic hits Funnel on 8443, it forwards to 8080, hitting the dev container directly.

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
