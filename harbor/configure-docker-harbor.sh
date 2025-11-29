#!/bin/bash

# Script to configure Docker daemon to allow Harbor as insecure registry

set -e

echo "=========================================="
echo "Configure Docker for Harbor Registry"
echo "=========================================="
echo ""

HARBOR_ENDPOINT="192.168.58.12:30002"

echo "Configuring Docker daemon to allow insecure registry: $HARBOR_ENDPOINT"
echo ""

# Backup existing daemon.json if it exists
if [ -f /etc/docker/daemon.json ]; then
    echo "Backing up existing /etc/docker/daemon.json..."
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup-$(date +%Y%m%d-%H%M%S)
fi

# Create or update daemon.json
echo "Creating/updating /etc/docker/daemon.json..."
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "insecure-registries": ["$HARBOR_ENDPOINT"]
}
EOF

echo "✓ Docker daemon configuration updated"
echo ""

# Restart Docker
echo "Restarting Docker daemon..."
sudo systemctl restart docker

echo "Waiting for Docker to restart..."
sleep 5

echo "✓ Docker daemon restarted successfully"
echo ""

# Verify configuration
echo "Verifying Docker configuration..."
docker info | grep -A 5 "Insecure Registries" || echo "Configuration applied"
echo ""

echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Docker is now configured to use Harbor at $HARBOR_ENDPOINT as an insecure registry."
echo ""
echo "You can now login to Harbor:"
echo "  docker login $HARBOR_ENDPOINT"
echo ""
