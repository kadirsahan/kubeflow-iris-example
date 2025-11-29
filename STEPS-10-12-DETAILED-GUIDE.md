# Steps 10-12: Detailed Guide - Upload, Run, and Monitor Pipeline

## Overview

These final steps will take your compiled pipeline and actually run it in Kubeflow to perform ML training and predictions.

---

# STEP 10: Upload Pipeline to Kubeflow

## What This Step Does

Uploads the compiled YAML file (`iris_pipeline_compiled.yaml`) to Kubeflow so it becomes available in the Kubeflow Pipelines UI.

## Why This Step is Needed

- The compiled YAML is currently just a file on your local machine
- Kubeflow needs to have it registered in its system
- Once uploaded, you can create runs from this pipeline multiple times

## Two Ways to Do This

### Option A: Via Kubeflow UI (Recommended for Beginners)

#### Step-by-Step:

**1. Access Kubeflow UI**

First, find out how to access Kubeflow:

```bash
# Check if Kubeflow is exposed via NodePort
kubectl get svc -n istio-system istio-ingressgateway

# Look for NodePort (usually port 31380 or similar)
# Example output:
# istio-ingressgateway   NodePort   10.x.x.x   <none>   80:31380/TCP   1d
```

Access Kubeflow at:
- `http://192.168.58.12:31380` (replace 31380 with your NodePort)
- Or `http://192.168.58.13:31380` (any node IP works)

**2. Login to Kubeflow**

Default credentials (if using Dex):
- Email: `user@example.com`
- Password: `12341234` (or check your Kubeflow installation docs)

**3. Navigate to Pipelines**

- On the left sidebar, click **"Pipelines"**
- You'll see the Pipelines dashboard

**4. Upload Pipeline**

- Click the **"+ Upload Pipeline"** button (top right)
- You'll see an upload form with these fields:

**Field 1: Pipeline Name**
```
Name: Iris Classification Pipeline
```

**Field 2: Pipeline Description** (optional)
```
Description: ML pipeline that downloads Iris dataset, trains XGBoost model, and makes predictions using Harbor registry images
```

**Field 3: Upload Method**
- Select: **"Upload a file"**
- Click **"Choose file"**
- Navigate to: `/home/kfmrgnmn/projects/kubeflow/iris_kubeflow/pipelines/iris_pipeline_compiled.yaml`
- Select the file

**5. Submit**

- Click **"Create"** button
- Wait a few seconds for upload to complete
- You should see a success message

**6. Verify Upload**

- You'll be redirected to the pipeline details page
- You should see:
  - Pipeline name: "Iris Classification Pipeline"
  - A graph visualization showing 3 components (download → train → predict)
  - Version information

### Option B: Via KFP CLI (Advanced)

```bash
# Navigate to pipelines directory
cd /home/kfmrgnmn/projects/kubeflow/iris_kubeflow/pipelines

# Upload using kfp CLI
kfp pipeline upload \
  --pipeline-name "Iris Classification Pipeline" \
  --description "ML pipeline using Harbor registry images" \
  iris_pipeline_compiled.yaml

# If kfp CLI is not configured, you may need to set endpoint first:
export KFP_ENDPOINT="http://192.168.58.12:31380/pipeline"
```

## What You Should See After This Step

✅ Pipeline appears in Pipelines list
✅ Pipeline graph shows 3 connected components
✅ Pipeline is ready to create runs

## Expected Time: 5 minutes

---

# STEP 11: Create an Experiment

## What This Step Does

Creates an "Experiment" - a logical grouping for organizing related pipeline runs.

## Why This Step is Needed

- Kubeflow requires all pipeline runs to belong to an experiment
- Experiments help you organize and compare different runs
- You can have multiple runs within one experiment (e.g., different hyperparameters)

## What is an Experiment?

Think of it like a project folder:
- **Experiment**: "Iris ML Experiments"
  - Run 1: Default parameters (today)
  - Run 2: Different model (tomorrow)
  - Run 3: Different hyperparameters (next week)

## How to Create an Experiment

### Via Kubeflow UI (Recommended)

**1. Navigate to Experiments**

- On the left sidebar, click **"Experiments (KFP)"**
- You'll see the Experiments page

**2. Create New Experiment**

- Click **"+ Create Experiment"** button (top right)

**3. Fill in Experiment Details**

**Experiment Name**:
```
Iris ML Experiments
```

**Description** (optional):
```
Experiments for training and evaluating Iris classification models
```

**4. Submit**

- Click **"Next"** or **"Create"**
- Experiment is created instantly

**5. Verify**

- You should see "Iris ML Experiments" in the experiments list
- Click on it to view details (currently 0 runs)

### Via KFP CLI (Advanced)

```bash
kfp experiment create "Iris ML Experiments"
```

## What You Should See After This Step

✅ Experiment "Iris ML Experiments" appears in experiments list
✅ Experiment shows 0 runs initially
✅ Ready to create a run

## Expected Time: 2 minutes

---

# STEP 12: Run the Pipeline

## What This Step Does

Actually executes the pipeline - this will:
1. Pull the download image from Harbor
2. Download the Iris dataset
3. Pull the train image from Harbor
4. Train an XGBoost model
5. Pull the predict image from Harbor
6. Make predictions on sample data

## Why This Step is the Final Goal

This is what we've been working toward! All the previous steps (Harbor setup, images, configuration) enable this pipeline to run successfully.

## How to Run the Pipeline

### Via Kubeflow UI (Recommended)

**1. Navigate to Pipelines**

- Left sidebar → **"Pipelines"**
- Find "Iris Classification Pipeline"
- Click on the pipeline name

**2. Create a Run**

- Click **"+ Create run"** button (top right)

**3. Run Configuration Page**

You'll see a form with several sections:

#### Section 1: Run Details

**Run name**:
```
iris-run-2025-11-29-01
```
(Use a unique name each time, can include date/time)

**Description** (optional):
```
First run with Harbor images - default parameters
```

#### Section 2: Experiment

**Choose Experiment**:
- Select: **"Iris ML Experiments"** (from dropdown)
- Or create new if you skipped Step 11

#### Section 3: Run Type

**One-off**:
- Select: **"One-off"** (run once immediately)

**Recurring** (alternative):
- If you want scheduled runs, select "Recurring"
- Set schedule (cron format)
- We'll use "One-off" for now

#### Section 4: Runtime Parameters

These are the pipeline input parameters:

**model_name** (dropdown or text):
```
xgboost
```
(Keep default - this is the ML algorithm to use)

**model_hyperparameters** (text field):
```
{"objective":"multi:softprob", "eval_metric":"mlogloss", "random_state":42}
```
(Keep default - these are XGBoost training parameters)

**prediction_data** (text field):
```
5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3
```
(Keep default - these are two sample Iris flowers to classify)
- First sample: sepal_length=5.1, sepal_width=3.5, petal_length=1.4, petal_width=0.2
- Second sample: sepal_length=6.7, sepal_width=3.0, petal_length=5.2, petal_width=2.3

**4. Start the Run**

- Click **"Start"** button at the bottom
- You'll be redirected to the run details page

**5. Monitor the Run**

The run details page shows:

**Graph View** (default):
- Visual representation of pipeline
- Each component (box) shows status:
  - ⏳ **Pending** (gray): Waiting to start
  - 🔄 **Running** (blue): Currently executing
  - ✅ **Succeeded** (green): Completed successfully
  - ❌ **Failed** (red): Error occurred
  - ⊗ **Skipped** (gray): Conditionally skipped

**Expected Flow**:
1. Download component starts (blue) → completes (green)
2. Train component starts (blue) → completes (green)
3. Predict component starts (blue) → completes (green)

**Run Details Section**:
- Shows overall run status
- Duration
- Start/end time

**Components to Watch**:

**a) Download Component**:
- **What it does**: Downloads Iris dataset from sklearn
- **Expected duration**: 10-30 seconds
- **Output**: CSV file with Iris data
- **What to watch**:
  - Status should go: Pending → Running → Succeeded
  - If it fails: Check Harbor image pull (logs will show)

**b) Train Component**:
- **What it does**: Trains XGBoost model on the dataset
- **Expected duration**: 30-60 seconds
- **Output**: Trained model file (pickle)
- **What to watch**:
  - Waits for download to complete first
  - Status: Pending → Running → Succeeded
  - Logs will show training progress

**c) Predict Component**:
- **What it does**: Loads model and predicts on sample data
- **Expected duration**: 10-20 seconds
- **Output**: Predictions (printed to logs)
- **What to watch**:
  - Waits for train to complete
  - Status: Pending → Running → Succeeded
  - Check logs for prediction results

**6. View Logs**

For each component:
- Click on the component box in the graph
- Right panel opens showing component details
- Click **"Logs"** tab
- You'll see real-time logs from the container

**Example logs you should see**:

**Download logs**:
```
Starting download component...
Downloading Iris dataset...
Dataset downloaded successfully
Saved to: /tmp/outputs/data/data.csv
Rows: 150, Columns: 5
```

**Train logs**:
```
Starting training component...
Loading data from: /tmp/inputs/data/data.csv
Training XGBoost model...
Model: xgboost
Hyperparameters: {"objective":"multi:softprob", ...}
Training complete!
Model accuracy: 0.95 (or similar)
Saved model to: /tmp/outputs/model/model.pkl
```

**Predict logs**:
```
Starting prediction component...
Loading model from: /tmp/inputs/model/model.pkl
Input data: 5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3
Predictions: [0, 2]
Predicted classes: ['setosa', 'virginica']
```

**7. View Artifacts (Optional)**

- Click **"Artifacts"** tab on each component
- See input/output files
- Download if needed

**8. Run Completion**

When all components are green:
- Overall status shows: **"Succeeded"**
- Total duration displayed
- All components have checkmarks ✅

### Via KFP CLI (Advanced)

```bash
# Create a run
kfp run create \
  --experiment-name "Iris ML Experiments" \
  --run-name "iris-run-$(date +%Y%m%d-%H%M%S)" \
  --pipeline-name "Iris Classification Pipeline" \
  --param model_name=xgboost \
  --param model_hyperparameters='{"objective":"multi:softprob", "eval_metric":"mlogloss", "random_state":42}' \
  --param prediction_data='5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3'
```

## Monitoring via kubectl

While the pipeline runs, you can also monitor from the terminal:

```bash
# Watch pods in user namespace
kubectl get pods -n user-example-com -w

# You'll see pods being created:
# - iris-run-xxx-download-xxx (downloads data)
# - iris-run-xxx-train-xxx (trains model)
# - iris-run-xxx-predict-xxx (makes predictions)

# Check specific pod logs
kubectl logs -n user-example-com <pod-name> -f

# Check if images pulled successfully
kubectl describe pod -n user-example-com <pod-name> | grep -A 10 Events
```

## What Success Looks Like

✅ **All components green** (Succeeded)
✅ **Download logs show**: Dataset downloaded, 150 rows
✅ **Train logs show**: Model trained, accuracy ~95%
✅ **Predict logs show**: Predictions made (e.g., [0, 2])
✅ **No ImagePullBackOff errors**
✅ **No pod failures**

## What You Should See After This Step

✅ Run appears in experiment with "Succeeded" status
✅ All 3 components completed successfully
✅ Predictions are visible in logs
✅ Total run time: 1-3 minutes

## Expected Time

- 2 minutes to configure and start
- 5-10 minutes for pipeline execution
- Total: ~10-12 minutes

---

# TROUBLESHOOTING GUIDE

## Issue 1: ImagePullBackOff

**Symptom**: Pod shows "ImagePullBackOff" status

**Check**:
```bash
kubectl describe pod <pod-name> -n user-example-com | grep -A 20 Events
```

**Common Causes**:
1. Harbor is down
2. Containerd not configured on node
3. Secret missing in namespace
4. Wrong image name

**Solution**:
```bash
# Check Harbor is running
kubectl get pods -n harbor

# Verify secret exists
kubectl get secret harbor-credentials -n user-example-com

# Check service account
kubectl describe sa default -n user-example-com

# Test image pull manually
kubectl run test --image=192.168.58.12:30002/kubeflow-iris/iris-download:v1.0 -n user-example-com
```

## Issue 2: Component Fails

**Symptom**: Component box turns red (Failed)

**Check**:
```bash
# Click on failed component in UI
# View Logs tab

# Or via kubectl
kubectl logs <pod-name> -n user-example-com
```

**Common Causes**:
1. Code error in component
2. Missing dependency
3. Incorrect arguments

**Solution**:
- Read error logs carefully
- Check component source code
- Verify component arguments

## Issue 3: Pipeline Stuck in "Pending"

**Symptom**: Components never start, stay gray

**Check**:
```bash
kubectl get pods -n user-example-com
# If no pods created, check pipeline controller

kubectl logs -n kubeflow ml-pipeline-xxx
```

**Common Causes**:
1. Insufficient cluster resources
2. Pipeline controller issue
3. Workflow controller issue

**Solution**:
```bash
# Check node resources
kubectl top nodes

# Restart pipeline controller
kubectl rollout restart deployment ml-pipeline -n kubeflow
```

## Issue 4: Cannot Access Kubeflow UI

**Check**:
```bash
# Get Kubeflow endpoint
kubectl get svc -n istio-system istio-ingressgateway

# Check if ingress gateway is running
kubectl get pods -n istio-system
```

**Solution**:
- Verify port number
- Check firewall rules
- Try different node IP

---

# VERIFICATION CHECKLIST

After completing steps 10-12, verify:

- [ ] Pipeline uploaded successfully to Kubeflow
- [ ] Experiment created
- [ ] Run started without errors
- [ ] Download component succeeded
- [ ] Train component succeeded
- [ ] Predict component succeeded
- [ ] Logs show expected output
- [ ] No ImagePullBackOff errors
- [ ] Predictions visible in predict component logs
- [ ] Overall run status: Succeeded

---

# WHAT HAPPENS UNDER THE HOOD

When you click "Start" on a run:

1. **Kubeflow API Server** receives the run request
2. **Workflow Controller** creates an Argo Workflow
3. **Argo** creates pods for each component in sequence:
   - `download` pod created first
   - Uses Harbor image: `192.168.58.12:30002/kubeflow-iris/iris-download:v1.0`
   - Pod pulls image from Harbor (using credentials from secret)
   - Containerd on the node fetches image (using config from Step 6)
   - Container runs, downloads dataset
   - Output saved to Kubernetes PersistentVolume
   - Pod completes
4. **Next component** (`train`) starts:
   - Mounts volume with downloaded data
   - Pulls train image from Harbor
   - Trains model
   - Saves model to volume
   - Pod completes
5. **Final component** (`predict`) starts:
   - Mounts volume with trained model
   - Pulls predict image from Harbor
   - Makes predictions
   - Logs predictions
   - Pod completes
6. **Workflow completes** - all done! ✅

---

# SUMMARY

## Step 10: Upload Pipeline
- **Input**: `iris_pipeline_compiled.yaml` file
- **Action**: Upload to Kubeflow via UI or CLI
- **Output**: Pipeline registered in Kubeflow
- **Time**: 5 minutes

## Step 11: Create Experiment
- **Input**: Experiment name and description
- **Action**: Create via UI or CLI
- **Output**: Experiment available for runs
- **Time**: 2 minutes

## Step 12: Run Pipeline
- **Input**: Pipeline, experiment, parameters
- **Action**: Execute pipeline
- **Output**: Trained model + predictions
- **Time**: 10-12 minutes

---

# NEXT STEPS AFTER COMPLETION

Once your first run succeeds:

1. **Try different parameters**:
   - Different model: `random_forest`
   - Different hyperparameters
   - Different prediction data

2. **Compare runs**:
   - View all runs in the experiment
   - Compare metrics and outputs

3. **Integrate into CI/CD**:
   - Use the CI pipeline to build new images
   - Trigger runs automatically

4. **Production deployment**:
   - Deploy best model to KServe
   - Set up model serving

---

# FILES AND LOCATIONS

All files needed for Steps 10-12:

```
/home/kfmrgnmn/projects/kubeflow/
├── iris_kubeflow/
│   └── pipelines/
│       ├── iris_pipeline_compiled.yaml  ← Upload this file in Step 10
│       ├── iris_pipeline_updated.py
│       └── STEP-8-COMPLETED.md
├── harbor/
│   ├── step-6-completed.txt
│   └── STEP-9-COMPLETED.md
└── IMPLEMENTATION-STEPS.md
└── STEPS-10-12-DETAILED-GUIDE.md  ← This file
```

---

# CONCLUSION

These final three steps are straightforward UI interactions:
1. **Upload** the YAML file
2. **Create** an experiment folder
3. **Run** the pipeline and watch it work

Everything we did in Steps 1-9 was preparation to make Step 12 succeed!
