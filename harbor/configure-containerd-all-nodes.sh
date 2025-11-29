#!/bin/bash

# Script to configure containerd on all Kubernetes nodes for Harbor registry

set -e

echo "=========================================="
echo "Configure Containerd for Harbor on All Nodes"
echo "=========================================="
echo ""

# Harbor registry endpoint
HARBOR_ENDPOINT="192.168.58.12:30002"

# Kubernetes nodes
NODES=("192.168.58.12" "192.168.58.13" "192.168.58.14" "192.168.58.15")
NODE_NAMES=("huawei-master" "huawei-worker-01" "huawei-worker-02" "huawei-worker-03")

echo "Harbor Registry: $HARBOR_ENDPOINT"
echo "Nodes to configure: ${NODE_NAMES[@]}"
echo ""
echo "This script will:"
echo "  1. Backup existing containerd config on each node"
echo "  2. Add Harbor as insecure registry"
echo "  3. Restart containerd"
echo ""

# Function to configure a single node
configure_node() {
    local node_ip=$1
    local node_name=$2

    echo "=========================================="
    echo "Configuring: $node_name ($node_ip)"
    echo "=========================================="

    # Create the configuration commands
    ssh -o StrictHostKeyChecking=no $node_ip << 'ENDSSH'
set -e

HARBOR_ENDPOINT="192.168.58.12:30002"

echo "  - Backing up containerd config..."
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

echo "  - Generating default containerd config..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

echo "  - Adding Harbor registry configuration..."
sudo tee -a /etc/containerd/config.toml > /dev/null <<EOF

# Harbor insecure registry configuration
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."${HARBOR_ENDPOINT}"]
  endpoint = ["http://${HARBOR_ENDPOINT}"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."${HARBOR_ENDPOINT}".tls]
  insecure_skip_verify = true
EOF

echo "  - Restarting containerd..."
sudo systemctl restart containerd

echo "  - Waiting for containerd to be ready..."
sleep 5

echo "  - Verifying containerd status..."
sudo systemctl is-active containerd

ENDSSH

    if [ $? -eq 0 ]; then
        echo "✓ $node_name configured successfully"
    else
        echo "✗ Failed to configure $node_name"
        return 1
    fi
    echo ""
}

# Configure all nodes
success_count=0
failed_nodes=()

for i in "${!NODES[@]}"; do
    if configure_node "${NODES[$i]}" "${NODE_NAMES[$i]}"; then
        ((success_count++))
    else
        failed_nodes+=("${NODE_NAMES[$i]}")
    fi
done

echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo "Total nodes: ${#NODES[@]}"
echo "Successfully configured: $success_count"
echo "Failed: ${#failed_nodes[@]}"

if [ ${#failed_nodes[@]} -gt 0 ]; then
    echo ""
    echo "Failed nodes:"
    for node in "${failed_nodes[@]}"; do
        echo "  - $node"
    done
    echo ""
    echo "Please configure failed nodes manually."
    exit 1
fi

echo ""
echo "=========================================="
echo "All Nodes Configured Successfully!"
echo "=========================================="
echo ""
echo "Next step: Test image pull from Harbor"
echo ""
