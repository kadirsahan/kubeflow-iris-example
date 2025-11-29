# KServe Model Serving for Iris Classification

This directory contains all the files needed to deploy the trained Iris model as a KServe InferenceService.

## Overview

The serving setup uses KServe to deploy the trained XGBoost model from the Kubeflow pipeline as a REST API endpoint.

## Architecture

1. **Custom Serving Runtime**: FastAPI application that loads the model and serves predictions
2. **Storage Initializer**: Downloads the trained model from MinIO S3 storage
3. **KServe InferenceService**: Manages the deployment, scaling, and routing

## Files

### Application Code

- `serve.py`: FastAPI application for model serving
- `requirements.txt`: Python dependencies
- `Dockerfile`: Container image definition

### Kubernetes Resources

- `service-account.yaml`: Service Account with S3 and Harbor credentials
- `serving-runtime.yaml`: Custom ServingRuntime for the FastAPI serving image
- `inference-service.yaml`: InferenceService definition

## Deployment Steps

### 1. Build and Push Serving Image

```bash
cd /home/kfmrgnmn/projects/kubeflow/iris_kubeflow/serving

# Build image
docker build -t 192.168.58.12:30002/kubeflow-iris/iris-serve:v1.0 .

# Push to Harbor
docker push 192.168.58.12:30002/kubeflow-iris/iris-serve:v1.0
```

### 2. Create Service Account and Secrets

```bash
kubectl apply -f service-account.yaml
```

This creates:
- Service Account `iris-sa` with S3 and Harbor credentials
- Secret `minio-s3-secret` with MinIO access credentials

### 3. Create Custom ServingRuntime

```bash
kubectl apply -f serving-runtime.yaml
```

This registers the custom FastAPI serving runtime with KServe.

### 4. Deploy InferenceService

```bash
kubectl apply -f inference-service.yaml
```

This creates the InferenceService which:
- Downloads the trained model from MinIO using the storage-initializer
- Deploys the serving container
- Exposes a prediction endpoint

### 5. Verify Deployment

```bash
# Check InferenceService status
kubectl get inferenceservice iris-model -n user-example-com

# Check pods
kubectl get pods -n user-example-com | grep iris-model

# Check logs
kubectl logs -n user-example-com <pod-name> -c kserve-container
```

## Model Details

- **Model Location**: MinIO S3 storage
- **Bucket**: mlpipeline
- **Path**: private-artifacts/user-example-com/v2/artifacts/iris-classification-pipeline/.../train-iris-model/.../model
- **Model Type**: XGBoost classifier (sklearn format)
- **Model Accuracy**: 0.9333

## API Endpoints

The InferenceService exposes the following endpoints:

### Health Check
```bash
GET /health
GET /v1/models/iris-model
```

### Predictions (KServe v1 Protocol)
```bash
POST /v1/models/iris-model:predict
Content-Type: application/json

{
  "instances": [
    [5.1, 3.5, 1.4, 0.2],
    [6.7, 3.0, 5.2, 2.3]
  ]
}
```

Response:
```json
{
  "predictions": [0, 2],
  "class_names": ["setosa", "virginica"]
}
```

### Simple Prediction Endpoint
```bash
POST /predict
Content-Type: application/json

{
  "instances": [
    [5.1, 3.5, 1.4, 0.2]
  ]
}
```

## Configuration

### MinIO S3 Credentials

The Service Account uses these annotations to configure S3 access:
- `serving.kserve.io/s3-endpoint`: minio-service.kubeflow:9000
- `serving.kserve.io/s3-usehttps`: "0" (HTTP, not HTTPS)
- `serving.kserve.io/s3-region`: us-east-1
- `serving.kserve.io/s3-verifyssl`: "0" (disable SSL verification)
- `serving.kserve.io/storageSecretName`: minio-s3-secret

### Harbor Registry

The Service Account includes `imagePullSecrets` for pulling the custom serving image from Harbor registry.

## Troubleshooting

### Storage Initializer Fails with "NoCredentialsError"

**Symptom**: Init container fails with `botocore.exceptions.NoCredentialsError`

**Solution**: Ensure the InferenceService annotation `serving.kserve.io/storageSecretName` points to the correct secret name (`minio-s3-secret`).

### Image Pull Errors

**Symptom**: Pod shows ImagePullBackOff

**Solution**: Verify Harbor credentials secret exists in the namespace:
```bash
kubectl get secret harbor-credentials -n user-example-com
```

### Istio DNS Timeout Issues

**Symptom**: Pods stuck in Init with istio-proxy DNS timeouts

**Solution**: The InferenceService has `sidecar.istio.io/inject: "false"` annotation to disable Istio sidecar injection.

## Resources

- CPU Request: 500m, Limit: 1
- Memory Request: 1Gi, Limit: 2Gi

## Next Steps

After successful deployment:
1. Get the InferenceService URL
2. Test predictions with sample Iris data
3. Integrate with frontend applications
4. Set up monitoring and logging
5. Configure autoscaling policies
