from kfp import dsl
from kfp import components

# Load components from YAML files
# These YAMLs now contain Harbor registry images
download_op = components.load_component_from_file('../components/download/component.yaml')
train_op = components.load_component_from_file('../components/train/component.yaml')
predict_op = components.load_component_from_file('../components/predict/component.yaml')

@dsl.pipeline(
    name='iris-classification-pipeline',
    description='A pipeline that trains and predicts on the Iris dataset using Harbor registry images.'
)
def iris_pipeline(
    # --- Parameters for ML Logic ---
    model_name: str = 'xgboost',
    model_hyperparameters: str = '{"objective":"multi:softprob", "eval_metric":"mlogloss", "random_state":42}',
    prediction_data: str = "5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3"
):
    """
    Defines the Iris classification pipeline using component-based approach.
    Components are loaded from YAML files which reference Harbor registry images.

    Harbor Images Used:
    - download: 192.168.58.12:30002/kubeflow-iris/iris-download:v1.0
    - train: 192.168.58.12:30002/kubeflow-iris/iris-train:v1.0
    - predict: 192.168.58.12:30002/kubeflow-iris/iris-predict:v1.0
    """

    # --- 1. Download Component ---
    download_task = download_op()

    # --- 2. Train Component ---
    train_task = train_op(
        data=download_task.outputs['data'],
        model_name=model_name,
        model_hyperparameters=model_hyperparameters
    )

    # --- 3. Predict Component ---
    predict_task = predict_op(
        model=train_task.outputs['model'],
        input_data=prediction_data
    )

if __name__ == '__main__':
    from kfp import compiler

    # Compile the pipeline
    compiler.Compiler().compile(
        pipeline_func=iris_pipeline,
        package_path='iris_pipeline_compiled.yaml'
    )
    print("Pipeline compiled successfully to: iris_pipeline_compiled.yaml")
    print("")
    print("Components using Harbor images:")
    print("  - download: 192.168.58.12:30002/kubeflow-iris/iris-download:v1.0")
    print("  - train: 192.168.58.12:30002/kubeflow-iris/iris-train:v1.0")
    print("  - predict: 192.168.58.12:30002/kubeflow-iris/iris-predict:v1.0")
    print("")
    print("Next steps:")
    print("  1. Upload iris_pipeline_compiled.yaml to Kubeflow UI")
    print("  2. Create an experiment")
    print("  3. Run the pipeline")
