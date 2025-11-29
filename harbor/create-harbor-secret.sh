#!/bin/bash

# Script to create Harbor credentials secret for Kaniko in Kubeflow namespace

set -e

echo "=========================================="
echo "Create Harbor Credentials Secret"
echo "=========================================="
echo ""

# Variables
HARBOR_SERVER="192.168.58.12:30002"
HARBOR_USERNAME="admin"
HARBOR_PASSWORD="Harbor12345"
SECRET_NAME="harbor-credentials"
NAMESPACE="kubeflow"

echo "Creating Docker config.json for Harbor authentication..."

# Create temporary directory for docker config
TEMP_DIR=$(mktemp -d)
CONFIG_DIR="$TEMP_DIR/.docker"
mkdir -p "$CONFIG_DIR"

# Create config.json with Harbor credentials
cat > "$CONFIG_DIR/config.json" <<EOF
{
  "auths": {
    "$HARBOR_SERVER": {
      "username": "$HARBOR_USERNAME",
      "password": "$HARBOR_PASSWORD",
      "auth": "$(echo -n "$HARBOR_USERNAME:$HARBOR_PASSWORD" | base64)"
    }
  }
}
EOF

echo "✓ Docker config.json created"
echo ""

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo "Creating namespace: $NAMESPACE"
    kubectl create namespace $NAMESPACE
    echo "✓ Namespace created"
else
    echo "✓ Namespace $NAMESPACE already exists"
fi
echo ""

# Delete secret if it exists
if kubectl get secret $SECRET_NAME -n $NAMESPACE &> /dev/null; then
    echo "Secret $SECRET_NAME already exists, deleting it..."
    kubectl delete secret $SECRET_NAME -n $NAMESPACE
fi

# Create the secret
echo "Creating secret: $SECRET_NAME in namespace: $NAMESPACE"
kubectl create secret generic $SECRET_NAME \
    --from-file=config.json="$CONFIG_DIR/config.json" \
    -n $NAMESPACE

echo "✓ Secret created successfully"
echo ""

# Cleanup
rm -rf "$TEMP_DIR"

# Verify secret
echo "Verifying secret..."
kubectl get secret $SECRET_NAME -n $NAMESPACE
echo ""

echo "=========================================="
echo "Secret Creation Complete!"
echo "=========================================="
echo ""
echo "Secret details:"
echo "  Name: $SECRET_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Harbor Server: $HARBOR_SERVER"
echo "  Username: $HARBOR_USERNAME"
echo ""
echo "This secret will be used by Kaniko to authenticate with Harbor."
echo ""
