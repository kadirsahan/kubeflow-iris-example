# Kubeflow Iris Pipeline - Complete Implementation Steps

## Overview
Sequential steps to get the Iris ML pipeline running on Kubeflow with Harbor registry.

---

## ✅ COMPLETED STEPS

### 1. Harbor Installation ✅
- Installed Harbor on Kubernetes using Helm
- Harbor running at: http://192.168.58.12:30002
- Status: All pods running in `harbor` namespace

### 2. Harbor Project Creation ✅
- Created project: `kubeflow-iris`
- Access: Private
- Status: Active

### 3. Build and Push Images ✅
- Built 3 component images:
  - iris-download:v1.0
  - iris-train:v1.0
  - iris-predict:v1.0
- Pushed to: 192.168.58.12:30002/kubeflow-iris/
- Status: All images verified in Harbor

### 4. Harbor Credentials Secret ✅
- Created Kubernetes secret: `harbor-credentials`
- Namespace: kubeflow
- Contains: Docker config.json with Harbor auth
- Status: Active

### 5. Update Component YAMLs ✅
- Updated download/component.yaml
- Updated train/component.yaml
- Updated predict/component.yaml
- All pointing to Harbor images
- Status: Complete

---

## 🔄 REMAINING STEPS (In Order)

### Step 6: Configure Containerd on Kubernetes Nodes
**Why**: Kubernetes nodes need to trust Harbor as an insecure registry to pull images

**Actions**:
1. SSH to each Kubernetes node (master + workers)
2. Update containerd configuration
3. Restart containerd service

**Commands to run on EACH node** (huawei-master, huawei-worker-01, huawei-worker-02, huawei-worker-03):

```bash
# Backup existing config
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup

# Generate default config
containerd config default | sudo tee /etc/containerd/config.toml

# Add Harbor registry configuration
sudo tee -a /etc/containerd/config.toml > /dev/null <<EOF

# Harbor insecure registry configuration
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.58.12:30002"]
  endpoint = ["http://192.168.58.12:30002"]

[plugins."io.containerd.grpc.v1.cri".registry.configs."192.168.58.12:30002".tls]
  insecure_skip_verify = true
EOF

# Restart containerd
sudo systemctl restart containerd

# Verify
sudo systemctl status containerd
```

**Verification**:
```bash
# Test pulling image from Harbor on a node
sudo crictl pull 192.168.58.12:30002/kubeflow-iris/iris-download:v1.0
```

**Estimated Time**: 10-15 minutes

---

### Step 7: Review and Update Iris Pipeline
**Why**: Ensure the pipeline correctly references the updated component YAMLs

**File**: `iris_kubeflow/pipelines/iris_pipeline.py`

**Actions**:
1. Review the pipeline file
2. Verify component paths are correct
3. Check if any hardcoded image references need updating
4. Ensure pipeline parameters are set correctly

**Verification**:
```bash
cat iris_kubeflow/pipelines/iris_pipeline.py | grep -E "component.yaml|image:"
```

**Estimated Time**: 5-10 minutes

---

### Step 8: Compile the Iris Pipeline
**Why**: Convert the Python pipeline definition to YAML that Kubeflow can execute

**Actions**:
```bash
cd /home/kfmrgnmn/projects/kubeflow/iris_kubeflow/pipelines

# Install required packages if needed
pip install kfp==2.0.0  # Or the version matching your Kubeflow

# Compile the pipeline
python iris_pipeline.py
```

**Expected Output**:
- Compiled YAML file created (check the script for output path)
- No compilation errors

**Verification**:
```bash
# Check if compiled YAML exists
ls -la *.yaml
```

**Estimated Time**: 2-5 minutes

---

### Step 9: Create ImagePullSecrets in Kubeflow User Namespace
**Why**: Pipeline pods need credentials to pull from Harbor

**Important**: Kubeflow creates user namespaces (e.g., `kubeflow-user-example-com`)

**Actions**:
```bash
# Find your user namespace
kubectl get ns | grep kubeflow-user

# Set the namespace (replace with your actual namespace)
USER_NAMESPACE="kubeflow-user-example-com"

# Create Harbor credentials in user namespace
kubectl create secret docker-registry harbor-credentials \
  --docker-server=192.168.58.12:30002 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --docker-email=admin@example.com \
  -n $USER_NAMESPACE

# Verify
kubectl get secret harbor-credentials -n $USER_NAMESPACE
```

**Alternative**: Add to default service account
```bash
kubectl patch serviceaccount default \
  -n $USER_NAMESPACE \
  -p '{"imagePullSecrets": [{"name": "harbor-credentials"}]}'
```

**Estimated Time**: 5 minutes

---

### Step 10: Update Pipeline to Use ImagePullSecrets (Optional but Recommended)
**Why**: Explicitly tell pipeline pods to use Harbor credentials

**File**: `iris_kubeflow/pipelines/iris_pipeline.py`

**Add this to pipeline definition**:
```python
from kubernetes.client.models import V1LocalObjectReference

@dsl.pipeline(
    name='iris-classification-pipeline',
    description='...'
)
def iris_pipeline():
    # ... existing pipeline code ...

    # Add imagePullSecrets to all tasks
    download_task.set_image_pull_secrets([
        V1LocalObjectReference(name='harbor-credentials')
    ])

    train_task.set_image_pull_secrets([
        V1LocalObjectReference(name='harbor-credentials')
    ])

    predict_task.set_image_pull_secrets([
        V1LocalObjectReference(name='harbor-credentials')
    ])
```

**Estimated Time**: 5-10 minutes

---

### Step 11: Upload Pipeline to Kubeflow
**Why**: Make the pipeline available in Kubeflow UI

**Actions**:
1. Access Kubeflow UI (usually http://<node-ip>:31380 or similar)
2. Navigate to Pipelines
3. Click "Upload Pipeline"
4. Select the compiled YAML file
5. Give it a name and description

**Alternative - CLI**:
```bash
# Using kfp CLI
pip install kfp

# Upload pipeline
kfp pipeline upload \
  --pipeline-name "Iris Classification Pipeline" \
  /path/to/compiled-pipeline.yaml
```

**Estimated Time**: 5 minutes

---

### Step 12: Create an Experiment
**Why**: Kubeflow requires experiments to organize pipeline runs

**Actions**:
1. In Kubeflow UI, go to "Experiments"
2. Click "Create Experiment"
3. Name: "iris-ml-experiments"
4. Description: "Experiments for Iris classification model"

**Alternative - CLI**:
```bash
kfp experiment create "iris-ml-experiments"
```

**Estimated Time**: 2 minutes

---

### Step 13: Run the Pipeline
**Why**: Execute the actual ML workflow

**Actions**:
1. In Kubeflow UI, go to your pipeline
2. Click "Create Run"
3. Select experiment: "iris-ml-experiments"
4. Configure parameters:
   - model_name: xgboost (default)
   - model_hyperparameters: {} (default)
   - input_data: "5.1,3.5,1.4,0.2;6.2,3.4,5.4,2.3" (sample)
5. Click "Start"

**Alternative - CLI**:
```bash
kfp run submit \
  --experiment-name "iris-ml-experiments" \
  --run-name "iris-run-$(date +%Y%m%d-%H%M%S)" \
  --pipeline-name "Iris Classification Pipeline"
```

**Estimated Time**: 2 minutes to start

---

### Step 14: Monitor Pipeline Execution
**Why**: Ensure all steps complete successfully

**Actions**:
1. Watch the pipeline run in Kubeflow UI
2. Monitor pod status in terminal:
   ```bash
   # Watch pods in user namespace
   kubectl get pods -n $USER_NAMESPACE -w
   ```
3. Check logs if any step fails:
   ```bash
   # List pods for the run
   kubectl get pods -n $USER_NAMESPACE

   # View logs
   kubectl logs <pod-name> -n $USER_NAMESPACE
   ```

**Expected Flow**:
1. Download pod: Fetches Iris dataset → Completes
2. Train pod: Trains XGBoost model → Completes
3. Predict pod: Makes predictions → Completes

**Estimated Time**: 5-10 minutes (pipeline execution)

---

### Step 15: Verify Results
**Why**: Confirm the pipeline worked correctly

**Actions**:
1. Check pipeline run status in UI (should be "Succeeded")
2. View artifacts and outputs
3. Check predictions output
4. Verify model was saved

**Verification Commands**:
```bash
# Check completed pods
kubectl get pods -n $USER_NAMESPACE | grep Completed

# View prediction results (if logged)
kubectl logs <predict-pod-name> -n $USER_NAMESPACE
```

**Estimated Time**: 5 minutes

---

## 📊 SUMMARY OF STEPS

| Step | Task | Status | Time Est. |
|------|------|--------|-----------|
| 1 | Harbor Installation | ✅ Done | - |
| 2 | Harbor Project | ✅ Done | - |
| 3 | Build & Push Images | ✅ Done | - |
| 4 | Harbor Secret | ✅ Done | - |
| 5 | Update Component YAMLs | ✅ Done | - |
| 6 | Configure Containerd | ⏳ Required | 10-15 min |
| 7 | Review Pipeline | ⏳ Required | 5-10 min |
| 8 | Compile Pipeline | ⏳ Required | 2-5 min |
| 9 | ImagePullSecrets | ⏳ Required | 5 min |
| 10 | Update Pipeline Code | 🔵 Optional | 5-10 min |
| 11 | Upload to Kubeflow | ⏳ Required | 5 min |
| 12 | Create Experiment | ⏳ Required | 2 min |
| 13 | Run Pipeline | ⏳ Required | 2 min |
| 14 | Monitor Execution | ⏳ Required | 5-10 min |
| 15 | Verify Results | ⏳ Required | 5 min |

**Total Estimated Time**: 45-75 minutes

---

## 🚨 CRITICAL DEPENDENCIES

Each step depends on the previous ones:
- Step 6 must complete before Step 13 (nodes must pull images)
- Step 8 requires Step 7 (compile needs correct pipeline)
- Step 9 must complete before Step 13 (pods need credentials)
- Steps 11-12 must complete before Step 13 (pipeline must be uploaded)

---

## 🔧 TROUBLESHOOTING GUIDE

### Issue: ImagePullBackOff
**Cause**: Containerd not configured or credentials missing
**Solution**:
- Verify Step 6 on all nodes
- Verify Step 9 secret exists
- Check: `kubectl describe pod <pod-name> -n $USER_NAMESPACE`

### Issue: Pipeline Compilation Error
**Cause**: Component YAMLs or Python syntax issues
**Solution**:
- Check component YAML syntax
- Verify all file paths in pipeline.py
- Check kfp library version

### Issue: Permission Denied
**Cause**: User namespace or RBAC issues
**Solution**:
- Verify user namespace exists
- Check service account permissions
- Review Kubeflow profile configuration

### Issue: Harbor Connection Failed
**Cause**: Network or Harbor service issues
**Solution**:
- Check Harbor pods: `kubectl get pods -n harbor`
- Test connectivity: `curl http://192.168.58.12:30002/api/v2.0/systeminfo`
- Verify firewall rules

---

## 📝 NEXT IMMEDIATE ACTION

**START WITH STEP 6**: Configure Containerd on Kubernetes Nodes

This is the most critical step as without it, Kubernetes cannot pull images from Harbor.

Would you like me to proceed with Step 6?
