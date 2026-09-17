#!/usr/bin/env bash
set -euo pipefail

# Configuration
CTID="102"
HOSTNAME="scraper"
CORES="2"
MEMORY="1024"
SWAP="1024"
DISK="15"
BRIDGE="vmbr0"
IP="192.168.178.62/24"
GW="192.168.178.1"
TEMPLATE="local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
PVE_HOST="pve.tail"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"

echo "--- Proxmox Dokku Bootstrap ---"

# 1. Thin Pool Safety Check
echo "Checking Thin Pool usage on $PVE_HOST..."
# Get usage, remove leading spaces, split by dot to get integer part
USAGE=$(ssh "$PVE_HOST" "lvs pve/data -o data_percent --noheadings" | tr -d ' ' | cut -d. -f1)

if [ "$USAGE" -gt 70 ]; then
    echo "ERROR: Thin Pool usage is at ${USAGE}%. Aborting to prevent host crash."
    exit 1
fi
echo "Thin Pool usage is at ${USAGE}%. Proceeding..."

# 2. Check if container already exists
if ssh "$PVE_HOST" "pct status $CTID" >/dev/null 2>&1; then
    echo "ERROR: Container $CTID already exists."
    exit 1
fi

# 3. Create the container
echo "Creating container $CTID ($HOSTNAME)..."
# Upload key to PVE first
scp "$SSH_KEY_PATH" "$PVE_HOST:/tmp/scraper.pub"

ssh "$PVE_HOST" "pct create $CTID $TEMPLATE \
    --hostname $HOSTNAME \
    --cores $CORES \
    --memory $MEMORY \
    --swap $SWAP \
    --net0 name=eth0,bridge=$BRIDGE,ip=$IP,gw=$GW,firewall=1 \
    --rootfs local-lvm:$DISK \
    --features nesting=1,keyctl=1 \
    --unprivileged 1 \
    --onboot 1 \
    --ssh-public-keys /tmp/scraper.pub"

# Cleanup key on PVE
ssh "$PVE_HOST" "rm /tmp/scraper.pub"

# 4. Start the container
echo "Starting container $CTID..."
ssh "$PVE_HOST" "pct start $CTID"

echo "--- Bootstrap Complete ---"
echo "Wait a few seconds for networking to initialize."
echo "Then test connectivity: ssh scraper.tail.root"
