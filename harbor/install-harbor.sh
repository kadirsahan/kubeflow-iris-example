#!/bin/bash

# Harbor Installation Script for Kubernetes using Helm

set -e

echo "=========================================="
echo "Harbor Installation Script"
echo "=========================================="
echo ""

# Variables
NAMESPACE="harbor"
RELEASE_NAME="harbor"
HELM_REPO_NAME="harbor"
HELM_REPO_URL="https://helm.goharbor.io"
VALUES_FILE="values.yaml"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: helm is not installed. Please install helm first."
    exit 1
fi

# Check if cluster is accessible
echo "Checking Kubernetes cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi
echo "✓ Kubernetes cluster is accessible"
echo ""

# Add Harbor Helm repository
echo "Adding Harbor Helm repository..."
helm repo add $HELM_REPO_NAME $HELM_REPO_URL
echo "✓ Harbor Helm repository added"
echo ""

# Update Helm repositories
echo "Updating Helm repositories..."
helm repo update
echo "✓ Helm repositories updated"
echo ""

# Check if values file exists
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: values.yaml file not found in current directory"
    exit 1
fi

# Install or upgrade Harbor
echo "Installing Harbor using Helm..."
echo "Release name: $RELEASE_NAME"
echo "Namespace: $NAMESPACE"
echo "Values file: $VALUES_FILE"
echo ""

helm upgrade --install $RELEASE_NAME $HELM_REPO_NAME/harbor \
    --namespace $NAMESPACE \
    --values $VALUES_FILE \
    --create-namespace \
    --wait \
    --timeout 10m

echo ""
echo "=========================================="
echo "Harbor Installation Complete!"
echo "=========================================="
echo ""
echo "To check the status of Harbor pods:"
echo "  kubectl get pods -n $NAMESPACE"
echo ""
echo "To get Harbor service information:"
echo "  kubectl get svc -n $NAMESPACE"
echo ""
echo "To access Harbor UI:"
echo "  - If using NodePort: http://<node-ip>:30002"
echo "  - Default admin credentials:"
echo "    Username: admin"
echo "    Password: Harbor12345 (change in values.yaml)"
echo ""
echo "To uninstall Harbor:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""
