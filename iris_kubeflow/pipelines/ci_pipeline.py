from kfp import dsl
from kfp.v2 import compiler

# Define the paths to your component YAML files
GIT_CLONE_COMPONENT_YAML = '../ci_components/git-clone/component.yaml'
KANIKO_COMPONENT_YAML = '../ci_components/kaniko/component.yaml'

@dsl.pipeline(
    name='ci-pipeline-for-iris-classifier',
    description='Clones, builds, and triggers the Iris classification pipeline.'
)
def ci_pipeline(
    # --- Parameters for CI/CD ---
    git_repo_url: str = 'https://github.com/your-username/your-repo.git', # CHANGE_ME
    git_commit_sha: str = 'main', # The Git commit to build
    
    # --- Harbor Registry Details ---
    # Example: 'myharbor.domain/my-project'
    harbor_repo_prefix: str = 'myharbor.domain/my-project', # CHANGE_ME
    harbor_secret_name: str = 'harbor-credentials' # The name of the k8s secret for Harbor auth
):
    """
    This pipeline automates the build and deployment of the Iris ML pipeline.
    """
    # 1. Load component definitions
    git_clone_op = dsl.load_component_from_file(GIT_CLONE_COMPONENT_YAML)
    kaniko_op = dsl.load_component_from_file(KANIKO_COMPONENT_YAML)

    # 2. Clone the specified commit from the repository
    clone_task = git_clone_op(
        repo_url=git_repo_url,
        commit_sha=git_commit_sha
    )
    
    # Define the image names and context paths
    components_to_build = {
        'download': 'components/download',
        'train': 'components/train',
        'predict': 'components/predict'
    }

    # 3. Build all component images in parallel using Kaniko
    build_tasks = {}
    for name, context_path in components_to_build.items():
        image_name = f"{harbor_repo_prefix}/iris-{name}:{git_commit_sha}"
        
        build_task = kaniko_op(
            # The build context is a sub-path within the cloned repository
            build_context=clone_task.outputs['workspace'].join_path(context_path),
            destination_image=image_name,
            docker_config_secret_name=harbor_secret_name
        )
        build_tasks[name] = build_task

    # 4. After all builds are complete, trigger the main ML pipeline
    with dsl.Condition(build_tasks['download'].state == 'SUCCEEDED' and 
                       build_tasks['train'].state == 'SUCCEEDED' and 
                       build_tasks['predict'].state == 'SUCCEEDED'):

        # We need a component to make the final API call to KFP to run the pipeline.
        # This is an advanced use case. For now, we will represent this as a final step.
        # In a real implementation, this would be a component that uses the KFP SDK.
        
        # This is a placeholder showing the intent. A real implementation
        # would require a component with the kfp-server-api or kfp sdk installed.
        trigger_op = dsl.ContainerSpec(
            image='python:3.9-slim',
            command=['sh', '-c'],
            args=[
                'pip install kfp-server-api==1.8.5 && ' # Example, match your KFP version
                'echo "Triggering ML pipeline with the following images:" && '
                f'echo "Download Image: {build_tasks["download"].outputs["destination_image"]}" && '
                f'echo "Train Image: {build_tasks["train"].outputs["destination_image"]}" && '
                f'echo "Predict Image: {build_tasks["predict"].outputs["destination_image"]}"'
                # The actual trigger command would be here, e.g.:
                # 'python trigger_script.py --endpoint $KFP_ENDPOINT ...'
            ]
        )


if __name__ == '__main__':
    compiler.Compiler().compile(
        pipeline_func=ci_pipeline,
        package_path='../manifests/kubeflow/ci_pipeline_compiled.yaml'
    )
    print("CI Pipeline compiled successfully to ../manifests/kubeflow/ci_pipeline_compiled.yaml")

