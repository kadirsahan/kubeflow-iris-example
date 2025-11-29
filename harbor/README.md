# Harbor Container Registry Installation

This folder contains the configuration and scripts to install Harbor container registry on Kubernetes using Helm.

## Prerequisites

- Kubernetes cluster (Minikube, K3s, or any K8s cluster)
- kubectl installed and configured
- Helm 3.x installed
- Sufficient cluster resources (minimum 4GB RAM, 2 CPU cores recommended)

## Files

- `values.yaml` - Harbor Helm chart configuration
- `install-harbor.sh` - Installation script
- `README.md` - This file

## Quick Start

### 1. Review and Update Configuration

Edit `values.yaml` to customize your Harbor installation:

```bash
vim values.yaml
```

**Important settings to review:**
- `harborAdminPassword` - Change the default admin password
- `externalURL` - Update to match your environment
- `persistence.persistentVolumeClaim.*.size` - Adjust storage sizes
- `expose.type` - Choose nodePort, loadBalancer, or ingress

### 2. Run Installation Script

```bash
cd harbor
./install-harbor.sh
```

The script will:
1. Check prerequisites (kubectl, helm)
2. Create harbor namespace
3. Add Harbor Helm repository
4. Install Harbor with your custom values
5. Wait for all pods to be ready

### 3. Verify Installation

Check if all Harbor pods are running:

```bash
kubectl get pods -n harbor
```

Expected pods:
- harbor-core
- harbor-database
- harbor-jobservice
- harbor-portal
- harbor-registry
- harbor-registryctl
- harbor-trivy
- harbor-chartmuseum (if enabled)

### 4. Access Harbor

**NodePort (default in values.yaml):**
```bash
# Get the node IP
kubectl get nodes -o wide

# Access Harbor at:
# http://<NODE_IP>:30002
```

**LoadBalancer (cloud providers):**
```bash
kubectl get svc -n harbor harbor
# Use the EXTERNAL-IP provided
```

**Ingress:**
Configure your ingress controller and access via the configured hostname.

### 5. Login to Harbor

**Default Credentials:**
- Username: `admin`
- Password: `Harbor12345` (or what you set in values.yaml)

**Change the admin password immediately after first login!**

## Manual Installation (without script)

If you prefer to install manually:

```bash
# Add Harbor Helm repository
helm repo add harbor https://helm.goharbor.io
helm repo update

# Create namespace
kubectl create namespace harbor

# Install Harbor
helm install harbor harbor/harbor \
  --namespace harbor \
  --values values.yaml \
  --wait \
  --timeout 10m
```

## Configuration Options

### Storage

By default, persistent volumes are created for:
- Registry data (20Gi)
- ChartMuseum (5Gi)
- JobService (1Gi)
- Database (1Gi)
- Redis (1Gi)
- Trivy (5Gi)

Adjust sizes in `values.yaml` based on your needs.

### TLS/HTTPS

To enable TLS:

```yaml
expose:
  tls:
    enabled: true
    certSource: auto  # or 'secret' for custom certificates
    auto:
      commonName: "harbor.example.com"
```

### External Database

For production, use external PostgreSQL:

```yaml
database:
  type: external
  external:
    host: "postgres.example.com"
    port: "5432"
    username: "harbor"
    password: "your-password"
    coreDatabase: "registry"
```

## Using Harbor with Kubeflow

### 1. Create a Project in Harbor

1. Login to Harbor UI
2. Click "New Project"
3. Name: `kubeflow-components`
4. Access Level: Private or Public

### 2. Configure Docker/Podman to Use Harbor

```bash
# For insecure registry (HTTP), add to Docker daemon config:
# /etc/docker/daemon.json
{
  "insecure-registries": ["<NODE_IP>:30002"]
}

# Restart Docker
sudo systemctl restart docker

# Login to Harbor
docker login <NODE_IP>:30002
# Username: admin
# Password: Harbor12345
```

### 3. Push Images to Harbor

```bash
# Tag your image
docker tag my-component:latest <NODE_IP>:30002/kubeflow-components/my-component:latest

# Push to Harbor
docker push <NODE_IP>:30002/kubeflow-components/my-component:latest
```

### 4. Create Kubernetes Secret for Harbor

Create a secret for pulling images from Harbor:

```bash
kubectl create secret docker-registry harbor-secret \
  --docker-server=<NODE_IP>:30002 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --docker-email=admin@example.com \
  -n kubeflow
```

### 5. Use in Kubeflow Pipeline

Reference Harbor images in your Kubeflow components:

```python
from kfp import dsl

@dsl.component
def my_component():
    return dsl.ContainerOp(
        name='my-task',
        image='<NODE_IP>:30002/kubeflow-components/my-component:latest',
        image_pull_secrets=[dsl.PipelineParam(name='harbor-secret')]
    )
```

## Upgrading Harbor

To upgrade Harbor to a newer version:

```bash
# Update Helm repository
helm repo update

# Upgrade Harbor
helm upgrade harbor harbor/harbor \
  --namespace harbor \
  --values values.yaml \
  --wait
```

## Uninstalling Harbor

```bash
# Uninstall Harbor
helm uninstall harbor -n harbor

# Delete namespace (this will also delete PVCs if persistentVolumeClaim.resourcePolicy is not "keep")
kubectl delete namespace harbor
```

To keep data for future installations, ensure in values.yaml:
```yaml
persistence:
  resourcePolicy: "keep"
```

## Troubleshooting

### Pods not starting

Check pod logs:
```bash
kubectl logs -n harbor <pod-name>
kubectl describe pod -n harbor <pod-name>
```

### Insufficient storage

Check PVCs:
```bash
kubectl get pvc -n harbor
```

### Cannot access Harbor UI

Check service:
```bash
kubectl get svc -n harbor
kubectl describe svc -n harbor harbor
```

### Database connection issues

Check database pod:
```bash
kubectl logs -n harbor harbor-database-0
```

## Additional Resources

- [Harbor Official Documentation](https://goharbor.io/docs/)
- [Harbor Helm Chart](https://github.com/goharbor/harbor-helm)
- [Harbor GitHub](https://github.com/goharbor/harbor)

## Security Best Practices

1. **Change default passwords** immediately
2. **Enable TLS/HTTPS** for production
3. **Use external database** for production
4. **Enable vulnerability scanning** with Trivy
5. **Set up RBAC** and project-based access control
6. **Regular backups** of Harbor data
7. **Use strong passwords** for registry credentials
8. **Enable audit logging**

## Support

For issues related to:
- Harbor installation: Check Harbor GitHub issues
- Kubeflow integration: Refer to Kubeflow documentation
- This setup: Open an issue in the project repository
