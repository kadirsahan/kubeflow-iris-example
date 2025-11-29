#!/bin/bash

# Script to configure containerd on a SINGLE node (run this ON the node itself)
# Usage: Run this script directly on each Kubernetes node

set -e

echo "=========================================="
echo "Configure Containerd for Harbor Registry"
echo "=========================================="
echo ""

HARBOR_ENDPOINT="192.168.58.12:30002"
HOSTNAME=$(hostname)

echo "Configuring containerd on: $HOSTNAME"
echo "Harbor Registry: $HARBOR_ENDPOINT"
echo ""

# Backup existing config
echo "Step 1: Backing up existing containerd config..."
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || echo "  No existing config to backup"

# Generate default config
echo "Step 2: Generating default containerd config..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
echo "  ✓ Default config generated"

# Add Harbor registry configuration
echo "Step 3: Adding Harbor registry configuration..."
sudo tee -a /etc/containerd/config.toml > /dev/null <<EOF

# Harbor insecure registry configuration
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."${HARBOR_ENDPOINT}"]
  endpoint = ["http://${HARBOR_ENDPOINT}"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."${HARBOR_ENDPOINT}".tls]
  insecure_skip_verify = true
EOF
echo "  ✓ Harbor configuration added"

# Restart containerd
echo "Step 4: Restarting containerd service..."
sudo systemctl restart containerd

# Wait for containerd
echo "Step 5: Waiting for containerd to be ready..."
sleep 5

# Verify
echo "Step 6: Verifying containerd status..."
if sudo systemctl is-active containerd > /dev/null 2>&1; then
    echo "  ✓ containerd is active and running"
else
    echo "  ✗ containerd is not running properly"
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuration Complete on $HOSTNAME!"
echo "=========================================="
echo ""
echo "Test image pull:"
echo "  sudo crictl pull ${HARBOR_ENDPOINT}/kubeflow-iris/iris-download:v1.0"
echo ""
