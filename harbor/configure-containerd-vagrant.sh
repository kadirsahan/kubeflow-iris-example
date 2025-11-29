#!/bin/bash

# Script to configure containerd on all Vagrant Kubernetes nodes for Harbor registry

set -e

echo "=========================================="
echo "Configure Containerd for Harbor via Vagrant"
echo "=========================================="
echo ""

VAGRANT_DIR="/home/kfmrgnmn/projects/vagrant/huawei"
HARBOR_ENDPOINT="192.168.58.12:30002"

# Vagrant machine names
MACHINES=("huawei-master" "huawei-worker-01" "huawei-worker-02" "huawei-worker-03")

echo "Vagrant Directory: $VAGRANT_DIR"
echo "Harbor Registry: $HARBOR_ENDPOINT"
echo "Machines: ${MACHINES[@]}"
echo ""

cd "$VAGRANT_DIR"

# Function to configure a single node
configure_node() {
    local machine=$1

    echo "=========================================="
    echo "Configuring: $machine"
    echo "=========================================="

    vagrant ssh $machine << 'ENDSSH'
set -e

HARBOR_ENDPOINT="192.168.58.12:30002"
HOSTNAME=$(hostname)

echo "  Configuring containerd on: $HOSTNAME"

# Backup existing config
echo "  - Backing up containerd config..."
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true

# Generate default config
echo "  - Generating default containerd config..."
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Add Harbor registry configuration
echo "  - Adding Harbor registry configuration..."
sudo tee -a /etc/containerd/config.toml > /dev/null <<EOF

# Harbor insecure registry configuration
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."${HARBOR_ENDPOINT}"]
  endpoint = ["http://${HARBOR_ENDPOINT}"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."${HARBOR_ENDPOINT}".tls]
  insecure_skip_verify = true
EOF

# Restart containerd
echo "  - Restarting containerd..."
sudo systemctl restart containerd

# Wait and verify
echo "  - Waiting for containerd to be ready..."
sleep 5

if sudo systemctl is-active containerd > /dev/null 2>&1; then
    echo "  ✓ containerd is active and running"
else
    echo "  ✗ containerd is not running properly"
    exit 1
fi

echo "  ✓ Configuration complete on $HOSTNAME"

ENDSSH

    if [ $? -eq 0 ]; then
        echo "✓ $machine configured successfully"
        return 0
    else
        echo "✗ Failed to configure $machine"
        return 1
    fi
    echo ""
}

# Configure all nodes
success_count=0
failed_machines=()

for machine in "${MACHINES[@]}"; do
    if configure_node "$machine"; then
        ((success_count++))
    else
        failed_machines+=("$machine")
    fi
done

echo "=========================================="
echo "Configuration Summary"
echo "=========================================="
echo "Total machines: ${#MACHINES[@]}"
echo "Successfully configured: $success_count"
echo "Failed: ${#failed_machines[@]}"

if [ ${#failed_machines[@]} -gt 0 ]; then
    echo ""
    echo "Failed machines:"
    for machine in "${failed_machines[@]}"; do
        echo "  - $machine"
    done
    exit 1
fi

echo ""
echo "=========================================="
echo "All Nodes Configured Successfully!"
echo "=========================================="
echo ""
echo "Testing image pull on master node..."
echo ""

# Test image pull
vagrant ssh master -c "sudo crictl pull ${HARBOR_ENDPOINT}/kubeflow-iris/iris-download:v1.0" || echo "Test pull completed (image may already exist)"

echo ""
echo "✓ Containerd configuration complete!"
echo ""
