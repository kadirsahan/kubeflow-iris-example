#!/bin/bash

# Script to build and push Kubeflow component images to Harbor using Kaniko

set -e

echo "=========================================="
echo "Build Kubeflow Components with Kaniko"
echo "=========================================="
echo ""

# Variables
HARBOR_REGISTRY="192.168.58.12:30002"
HARBOR_PROJECT="kubeflow-iris"
IMAGE_TAG="v1.0"
NAMESPACE="kubeflow"
SECRET_NAME="harbor-credentials"

# Component paths
COMPONENTS_BASE_DIR="/home/kfmrgnmn/projects/kubeflow/iris_kubeflow/components"

# Components to build
declare -A COMPONENTS
COMPONENTS["download"]="$COMPONENTS_BASE_DIR/download"
COMPONENTS["train"]="$COMPONENTS_BASE_DIR/train"
COMPONENTS["predict"]="$COMPONENTS_BASE_DIR/predict"

echo "Harbor Registry: $HARBOR_REGISTRY"
echo "Harbor Project: $HARBOR_PROJECT"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo ""

# Function to create Kaniko job for a component
create_kaniko_job() {
    local component_name=$1
    local context_path=$2
    local image_name="${HARBOR_REGISTRY}/${HARBOR_PROJECT}/iris-${component_name}:${IMAGE_TAG}"

    echo "Creating Kaniko job for component: $component_name"
    echo "  Context path: $context_path"
    echo "  Image name: $image_name"

    cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kaniko-build-${component_name}
  namespace: ${NAMESPACE}
spec:
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: kaniko
        image: gcr.io/kaniko-project/executor:v1.9.0
        args:
        - "--dockerfile=Dockerfile"
        - "--context=${context_path}"
        - "--destination=${image_name}"
        - "--insecure"
        - "--skip-tls-verify"
        - "--verbosity=info"
        volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
        - name: components-source
          mountPath: /workspace
      volumes:
      - name: docker-config
        secret:
          secretName: ${SECRET_NAME}
          items:
          - key: config.json
            path: config.json
      - name: components-source
        hostPath:
          path: ${COMPONENTS_BASE_DIR}
          type: Directory
EOF

    echo "  ✓ Job created: kaniko-build-${component_name}"
    echo ""
}

# Build all components
echo "Building components..."
echo ""

for component in "${!COMPONENTS[@]}"; do
    # Delete old job if exists
    kubectl delete job "kaniko-build-${component}" -n $NAMESPACE 2>/dev/null || true
    sleep 2

    # Create context path relative to mounted volume
    context_path="/workspace/${component}"

    create_kaniko_job "$component" "$context_path"
done

echo "=========================================="
echo "Jobs Created!"
echo "=========================================="
echo ""
echo "Monitor job status with:"
echo "  kubectl get jobs -n $NAMESPACE"
echo ""
echo "View logs for a specific component (e.g., download):"
echo "  kubectl logs -n $NAMESPACE -l job-name=kaniko-build-download -f"
echo ""
echo "Wait for all jobs to complete:"
echo "  kubectl wait --for=condition=complete --timeout=600s job -l app=kaniko-build -n $NAMESPACE"
echo ""
