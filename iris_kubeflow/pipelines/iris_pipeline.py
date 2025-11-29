from kfp import dsl

@dsl.pipeline(
    name='iris-classification-pipeline',
    description='A flexible pipeline that trains and predicts on the Iris dataset using dynamically built images.'
)
def iris_pipeline(
    # --- Parameters for ML Logic ---
    model_name: str = 'xgboost',
    model_hyperparameters: str = '{"objective":"multi:softprob", "eval_metric":"mlogloss", "random_state":42}',
    prediction_data: str = "5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3",

    # --- Parameters for CI/CD: These will be provided by the CI pipeline ---
    download_image: str = 'gcr.io/your-project-id/iris-download:latest', # CHANGE_ME to a default or placeholder
    train_image: str = 'gcr.io/your-project-id/iris-train:latest',       # CHANGE_ME to a default or placeholder
    predict_image: str = 'gcr.io/your-project-id/iris-predict:latest'     # CHANGE_ME to a default or placeholder
):
    """
    Defines the Iris classification pipeline using container components.
    """
    
    # --- 1. Download Component ---
    download_task = dsl.ContainerSpec(
        image=download_image,
        command=["python", "download.py"],
        args=["--output_path", dsl.OutputPath('data')]
    )

    # --- 2. Train Component ---
    train_task = dsl.ContainerSpec(
        image=train_image,
        command=["python", "train.py"],
        args=[
            "--data_path", dsl.InputPath('data'),
            "--model_output_path", dsl.OutputPath('model'),
            "--model-name", model_name,
            "--model-hyperparameters", model_hyperparameters
        ]
    )(data=download_task.outputs['data'])

    # --- 3. Predict Component ---
    predict_task = dsl.ContainerSpec(
        image=predict_image,
        command=["python", "predict.py"],
        args=[
            "--model_path", dsl.InputPath('model'),
            "--input_data", prediction_data
        ]
    )(model=train_task.outputs['model'])

# Local compilation is removed as this pipeline is intended to be triggered by the CI pipeline,
# not compiled directly from a static file.
