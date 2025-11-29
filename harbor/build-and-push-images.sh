#!/bin/bash

# Script to build and push Kubeflow component images to Harbor using Docker

set -e

echo "=========================================="
echo "Build and Push Images to Harbor"
echo "=========================================="
echo ""

# Variables
HARBOR_REGISTRY="192.168.58.12:30002"
HARBOR_PROJECT="kubeflow-iris"
IMAGE_TAG="v1.0"
HARBOR_USERNAME="admin"
HARBOR_PASSWORD="Harbor12345"

# Component paths
COMPONENTS_DIR="/home/kfmrgnmn/projects/kubeflow/iris_kubeflow/components"

# Components to build
COMPONENTS=("download" "train" "predict")

echo "Harbor Registry: $HARBOR_REGISTRY"
echo "Harbor Project: $HARBOR_PROJECT"
echo "Image Tag: $IMAGE_TAG"
echo ""

# Login to Harbor
echo "Logging in to Harbor..."
echo "$HARBOR_PASSWORD" | docker login $HARBOR_REGISTRY -u $HARBOR_USERNAME --password-stdin
echo "✓ Logged in successfully"
echo ""

# Build and push each component
for component in "${COMPONENTS[@]}"; do
    echo "----------------------------------------"
    echo "Building component: $component"
    echo "----------------------------------------"

    COMPONENT_PATH="$COMPONENTS_DIR/$component"
    IMAGE_NAME="${HARBOR_REGISTRY}/${HARBOR_PROJECT}/iris-${component}:${IMAGE_TAG}"

    if [ ! -d "$COMPONENT_PATH" ]; then
        echo "Error: Component directory not found: $COMPONENT_PATH"
        continue
    fi

    # Build the image
    echo "Building image: $IMAGE_NAME"
    docker build -t "$IMAGE_NAME" "$COMPONENT_PATH"
    echo "✓ Image built successfully"
    echo ""

    # Push to Harbor
    echo "Pushing image to Harbor..."
    docker push "$IMAGE_NAME"
    echo "✓ Image pushed successfully"
    echo ""
done

echo "=========================================="
echo "Build and Push Complete!"
echo "=========================================="
echo ""
echo "Images built and pushed:"
for component in "${COMPONENTS[@]}"; do
    echo "  - ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/iris-${component}:${IMAGE_TAG}"
done
echo ""
echo "View images in Harbor UI:"
echo "  http://${HARBOR_REGISTRY}"
echo ""
echo "To verify images:"
echo "  docker pull ${HARBOR_REGISTRY}/${HARBOR_PROJECT}/iris-download:${IMAGE_TAG}"
echo ""
