#!/usr/bin/env bash
set -euo pipefail

# Configuration
APP_NAME="sauspiel-scraper"
DOKKU_VERSION="v0.35.10"
# Use direct jump host command since aliases might not be active in current shell
TARGET_IP="192.168.178.62"
JUMP_HOST="root@homeassistant.tail401ae4.ts.net"
SSH_CMD="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J $JUMP_HOST root@$TARGET_IP"

echo "--- Dokku & Postgres Setup ---"

# Check connectivity
if ! $SSH_CMD exit 0 2>/dev/null; then
    echo "ERROR: Cannot reach $TARGET_IP via $JUMP_HOST. Is the bootstrap script finished and the container up?"
    exit 1
fi

$SSH_CMD bash <<EOF
set -euo pipefail

echo "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -y curl gnupg2 sudo cron

# 1. Install Dokku
if ! command -v dokku >/dev/null; then
    echo "Installing Dokku..."
    wget -nv -O bootstrap.sh https://raw.githubusercontent.com/dokku/dokku/$DOKKU_VERSION/bootstrap.sh
    # We use the tag directly
    DOKKU_TAG=$DOKKU_VERSION bash bootstrap.sh
fi

# 2. Install PostgreSQL Plugin
if ! dokku plugin:report postgres >/dev/null 2>&1; then
    echo "Installing dokku-postgres..."
    dokku plugin:install https://github.com/dokku/dokku-postgres.git
fi

# 3. Create App and Database
if ! dokku apps:report $APP_NAME >/dev/null 2>&1; then
    echo "Creating app $APP_NAME..."
    dokku apps:create $APP_NAME
fi

if ! dokku postgres:report $APP_NAME-db >/dev/null 2>&1; then
    echo "Creating database $APP_NAME-db..."
    dokku postgres:create $APP_NAME-db
    dokku postgres:link $APP_NAME-db $APP_NAME
fi

# 4. Tailscale Setup (Userspace mode for LXC)
if ! command -v tailscale >/dev/null; then
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh

    # Configure systemd override for userspace networking
    mkdir -p /etc/systemd/system/tailscaled.service.d
    cat > /etc/systemd/system/tailscaled.service.d/override.conf <<OVERRIDE
[Service]
ExecStart=
ExecStart=/usr/sbin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port 41641 --tun=userspace-networking
OVERRIDE
    systemctl daemon-reload
    systemctl restart tailscaled

    echo "Tailscale installed. You will need to run 'tailscale up' manually to authenticate."
fi

# 5. Thin Pool Safety Cron Jobs
echo "Setting up safety cron jobs..."
cat > /etc/cron.daily/dokku-safety-cleanup <<CRON
#!/bin/bash
# Clean up build cache and orphaned docker resources to protect PVE thin pool
dokku cleanup:buildcache --all
docker system prune -af --volumes
CRON
chmod +x /etc/cron.daily/dokku-safety-cleanup

echo "--- Setup Commands Finished Inside Container ---"
EOF

echo "--- Setup Complete ---"
echo "Next steps:"
echo "1. SSH into the container: ssh $TARGET_HOST"
echo "2. Run 'tailscale up' to join your network."
echo "3. Add your git remote and push: git remote add dokku dokku@scraper.tail:$APP_NAME"
