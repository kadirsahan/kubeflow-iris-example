# Transformation from Monolithic Script to Kubeflow Pipeline

This document outlines the process and design decisions made to transform a monolithic Python script (`iris-monolith-single-file.py`) into a modular Kubeflow pipeline. The goal was to create a flexible, scalable, and reproducible machine learning workflow without modifying the original script's core logic with Kubeflow-specific decorators.

## 1. Initial Script Analysis

The original script, `iris-monolith-single-file.py`, performed the following sequential steps for Iris dataset classification using XGBoost:

*   `load_and_explore_data`: Loads the Iris dataset, converts it to a Pandas DataFrame, and prints basic statistics.
*   `visualize_data`: Generates and displays various plots for data exploration (e.g., feature distributions, correlation heatmap).
*   `prepare_data`: Splits the dataset into training and testing sets.
*   `train_xgboost_model`: Initializes and trains an XGBoost classifier.
*   `evaluate_model`: Evaluates the trained model, printing a classification report, confusion matrix, and feature importance, along with generating plots.
*   `make_predictions`: Uses the trained model to make predictions on new sample data.
*   `main`: Orchestrates the execution of these functions.

The script also declared dependencies on libraries like `xgboost`, `scikit-learn`, `pandas`, `numpy`, `matplotlib`, and `seaborn`.

## 2. Pipeline Design and Component Breakdown

To adhere to the "no modification of original code" and "component-based" principles for Kubeflow, the monolithic script was decomposed into the following core pipeline components:

*   **`download`**: Responsible for loading the Iris dataset and saving it to a persistent CSV file. This acts as the data ingestion step for the pipeline.
*   **`train`**: Loads the prepared data, trains a machine learning model, and saves the trained model artifact. This component was later enhanced to be model-agnostic.
*   **`predict`**: Loads a trained model and uses it to make predictions on provided input data.

**Note on Visualization and Evaluation:** For the initial pipeline, the `visualize_data` and `evaluate_model` functions were excluded. Their outputs (plots) are typically handled differently in pipelines (e.g., saving images as artifacts, generating reports, or integrating with Kubeflow Metadata). They can be added as separate components if artifact handling is implemented.

## 3. Project Folder Structure

A well-organized project structure was adopted to manage components, pipelines, and Kubernetes/Kubeflow manifests:

```
iris_kubeflow/
├── components/
│   ├── download/
│   │   ├── src/
│   │   │   └── download.py
│   │   ├── component.yaml
│   │   └── Dockerfile
│   ├── train/
│   │   ├── src/
│   │   │   └── train.py
│   │   ├── component.yaml
│   │   └── Dockerfile
│   └── predict/
│       ├── src/
│       │   └── predict.py
│       ├── component.yaml
│       └── Dockerfile
├── pipelines/
│   └── iris_pipeline.py
└── manifests/
    ├── k8s/
    │   ├── namespace.yaml
    │   └── persistent-volume-claim.yaml (Placeholder, not implemented in this session)
    └── kubeflow/
        ├── compiled_pipeline.yaml
        └── pipeline-run.yaml
```

## 4. Component Implementation Details

Each component consists of:

*   **`src/<component_name>.py`**: The Python script containing the core logic.
*   **`Dockerfile`**: Defines the container environment, installing necessary Python packages from `requirements.txt`.
*   **`requirements.txt`**: Lists Python dependencies (`pandas`, `scikit-learn`, `xgboost`).
*   **`component.yaml`**: The Kubeflow component specification, defining inputs, outputs, and the container command.

### 4.1. `download` Component

*   **`download.py`**: Loads `sklearn.datasets.load_iris()` and saves the data (features and target) to a CSV file.
*   **`component.yaml`**:
    *   **Output**: `data` (type `Dataset`, path to the CSV).
    *   **Command**: `python download.py --output_path {outputPath: data}`.

### 4.2. `train` Component (Parameterized)

This component was significantly enhanced to support multiple ML algorithms and their hyperparameters.

*   **`train.py`**:
    *   Accepts `--model-name` (e.g., `xgboost`, `random_forest`, `logistic_regression`) and `--model-hyperparameters` (a JSON string) as command-line arguments.
    *   Parses the JSON string into a dictionary.
    *   Dynamically instantiates the chosen model (`XGBClassifier`, `RandomForestClassifier`, `LogisticRegression`) using keyword argument unpacking (`**hyperparameters`).
    *   Trains the model, evaluates its accuracy, and saves the trained model using `pickle`.
*   **`component.yaml`**:
    *   **Inputs**:
        *   `data` (type `Dataset`)
        *   `model_name` (type `String`, default: `xgboost`)
        *   `model_hyperparameters` (type `String`, default: `{}`)
    *   **Output**: `model` (type `Model`, path to the pickled model file).
    *   **Command**: `python train.py --data_path {inputPath: data} --model_output_path {outputPath: model} --model-name {inputValue: model_name} --model-hyperparameters {inputValue: model_hyperparameters}`.

### 4.3. `predict` Component

*   **`predict.py`**:
    *   Loads the trained model from a file.
    *   Accepts `--input_data` as a semicolon-separated string of comma-separated feature vectors (e.g., `"5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3"`).
    *   Makes predictions on the input data and prints the results (in a real pipeline, these would be saved as an artifact).
*   **`component.yaml`**:
    *   **Inputs**:
        *   `model` (type `Model`)
        *   `input_data` (type `String`)
    *   **Command**: `python predict.py --model_path {inputPath: model} --input_data {inputValue: input_data}`.

## 5. Pipeline Definition (`pipelines/iris_pipeline.py`)

This Python script orchestrates the components using the Kubeflow Pipelines SDK (`kfp`).

*   It loads the `component.yaml` files for `download`, `train`, and `predict`.
*   It defines the `iris_pipeline` function, which is decorated with `@dsl.pipeline`.
*   The `iris_pipeline` function accepts `model_name`, `model_hyperparameters`, and `prediction_data` as top-level parameters with default values.
*   It defines the sequential flow: `download_op` -> `train_op` (passing data from download, and model parameters) -> `predict_op` (passing the trained model from train, and prediction data).
*   It includes a local compilation step (`compiler.Compiler().compile()`) to generate `manifests/kubeflow/compiled_pipeline.yaml`.

## 6. Kubernetes and Kubeflow Manifests

These YAML files define how the pipeline and its resources are deployed and run on a Kubernetes cluster with Kubeflow.

*   **`manifests/k8s/namespace.yaml`**:
    *   Defines a Kubernetes Namespace (`iris-pipeline-example`) to logically isolate pipeline resources.
*   **`manifests/kubeflow/pipeline-run.yaml`**:
    *   This is an Argo Workflow definition, as Kubeflow Pipelines uses Argo as its execution engine.
    *   It specifies the `entrypoint` (the pipeline function name) and `serviceAccountName`.
    *   Crucially, the `arguments.parameters` section allows **overriding the default pipeline parameters** defined in `iris_pipeline.py`.
    *   **Example configuration for a Random Forest run:**
        ```yaml
          arguments:
            parameters:
              - name: model_name
                value: "random_forest"
              - name: model_hyperparameters
                value: '{ "n_estimators": 200, "max_depth": 10, "random_state": 42 }'
              - name: prediction_data
                value: "5.9,3.0,4.2,1.5;7.0,3.2,4.7,1.4"
        ```
    *   The `workflowTemplateRef` points to the `iris-classification-pipeline` (the name used in `@dsl.pipeline` decorator), which refers to the compiled pipeline uploaded to Kubeflow.

## 7. Next Steps for Deployment (User Actions)

To run this pipeline in a Kubeflow environment, the following steps are required:

1.  **Build and Push Docker Images**: For each component (`download`, `train`, `predict`), build a Docker image and push it to a container registry (e.g., GCR, Docker Hub).
    ```bash
    docker build -t gcr.io/your-project-id/iris-download:latest ./iris_kubeflow/components/download/
    docker push gcr.io/your-project-id/iris-download:latest
    # Repeat for train and predict
    ```
2.  **Update `component.yaml` files**: Replace the placeholder `gcr.io/your-project-id/...` image paths in `iris_kubeflow/components/*/component.yaml` with the actual paths to your pushed images.
3.  **Compile the Pipeline**: Run the Python script to generate the compiled pipeline YAML:
    ```bash
    python iris_kubeflow/pipelines/iris_pipeline.py
    ```
    This will create `iris_kubeflow/manifests/kubeflow/compiled_pipeline.yaml`.
4.  **Deploy Kubernetes Namespace**:
    ```bash
    kubectl apply -f iris_kubeflow/manifests/k8s/namespace.yaml
    ```
5.  **Upload to Kubeflow**: Upload `iris_kubeflow/manifests/kubeflow/compiled_pipeline.yaml` to your Kubeflow Pipelines dashboard or via the KFP CLI.
6.  **Initiate Pipeline Run**: You can then start a run from the Kubeflow UI, specifying parameters, or by applying the `pipeline-run.yaml` (after editing it for your desired model and parameters) to your Kubernetes cluster:
    ```bash
    kubectl apply -f iris_kubeflow/manifests/kubeflow/pipeline-run.yaml
    ```

This detailed approach ensures that your machine learning code remains clean, while Kubeflow handles the orchestration, parameterization, and scalability of your workflows.
