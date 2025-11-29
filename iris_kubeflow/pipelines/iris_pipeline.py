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
    # Updated to use Harbor registry images
    download_image: str = '192.168.58.12:30002/kubeflow-iris/iris-download:v1.0',
    train_image: str = '192.168.58.12:30002/kubeflow-iris/iris-train:v1.0',
    predict_image: str = '192.168.58.12:30002/kubeflow-iris/iris-predict:v1.0'
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

if __name__ == '__main__':
    from kfp import compiler

    # Compile the pipeline for local use
    compiler.Compiler().compile(
        pipeline_func=iris_pipeline,
        package_path='iris_pipeline_compiled.yaml'
    )
    print("Pipeline compiled successfully to: iris_pipeline_compiled.yaml")
    print("")
    print("Using Harbor images:")
    print("  - download: 192.168.58.12:30002/kubeflow-iris/iris-download:v1.0")
    print("  - train: 192.168.58.12:30002/kubeflow-iris/iris-train:v1.0")
    print("  - predict: 192.168.58.12:30002/kubeflow-iris/iris-predict:v1.0")
