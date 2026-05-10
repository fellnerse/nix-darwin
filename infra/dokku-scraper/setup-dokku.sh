#!/usr/bin/env bash
set -euo pipefail

# Configuration
APP_NAME="sauspiel-scraper"
DOKKU_VERSION="v0.35.10"
CREATE_DEV_ENV="true" # Set to "true" to provision the dev environment

# Use direct jump host command since aliases might not be active in current shell
TARGET_IP="192.168.178.62"
JUMP_HOST="root@homeassistant.tail401ae4.ts.net"
SSH_CMD="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J $JUMP_HOST root@$TARGET_IP"

echo "--- Dokku & Postgres Setup ---"

# Check connectivity
if ! $SSH_CMD exit 0 >/dev/null 2>&1; then
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
if ! dokku plugin:list | grep -q "postgres"; then
    echo "Installing dokku-postgres..."
    dokku plugin:install https://github.com/dokku/dokku-postgres.git
fi

# 3. Create Production App and Database
if ! dokku apps:list | grep -q "^$APP_NAME$"; then
    echo "Creating app $APP_NAME..."
    dokku apps:create $APP_NAME
fi

if ! dokku postgres:list | grep -q "^$APP_NAME-db$"; then
    echo "Creating database $APP_NAME-db..."
    dokku postgres:create $APP_NAME-db
    dokku postgres:link $APP_NAME-db $APP_NAME
    echo "Exposing production database on port 5432..."
    dokku postgres:expose $APP_NAME-db 5432
fi

# 4. Create Development App and Database (Optional)
if [ "$CREATE_DEV_ENV" = "true" ]; then
    DEV_APP="$APP_NAME-dev"
    DEV_DB="$APP_NAME-db-dev"

    if ! dokku apps:list | grep -q "^\$DEV_APP$"; then
        echo "Creating dev app \$DEV_APP..."
        dokku apps:create \$DEV_APP
    fi

    if ! dokku postgres:list | grep -q "^\$DEV_DB$"; then
        echo "Creating dev database \$DEV_DB..."
        dokku postgres:create \$DEV_DB
        dokku postgres:link \$DEV_DB \$DEV_APP
        echo "Exposing dev database on port 5433..."
        dokku postgres:expose \$DEV_DB 5433
    fi
fi

# 5. Tailscale Setup (Userspace mode for LXC)
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

# 6. Thin Pool Safety Cron Jobs
echo "Setting up safety cron jobs..."
cat > /etc/cron.daily/dokku-safety-cleanup <<CRON
#!/bin/bash
# Clean up build cache and orphaned docker resources to protect PVE thin pool
dokku cleanup:buildcache --all
docker system prune -af --volumes
# Reclaim space
fstrim -a
CRON
chmod +x /etc/cron.daily/dokku-safety-cleanup

echo "--- Setup Commands Finished Inside Container ---"
EOF

echo "--- Setup Complete ---"
echo "Next steps:"
echo "1. Authenticate Tailscale: ssh scraper.tail.root 'tailscale up'"
echo "2. Deploy Production: git remote add dokku dokku@scraper.tail:$APP_NAME"
if [ "$CREATE_DEV_ENV" = "true" ]; then
    echo "3. Deploy Development: git remote add dokku-dev dokku@scraper.tail:$APP_NAME-dev"
fi
