
import pandas as pd
import pickle
import argparse

def make_predictions(model_path: str, input_data_str: str):
    """Loads a model and makes predictions on sample data."""
    print("Loading model...")
    with open(model_path, 'rb') as f:
        model = pickle.load(f)
    print("Model loaded.")

    # The input data is passed as a string, e.g., "5.1,3.5,1.4,0.2;6.7,3.0,5.2,2.3"
    # We need to parse it into a list of lists of floats.
    print(f"Parsing input data: {input_data_str}")
    samples_str = input_data_str.strip().split(';')
    samples = [[float(v) for v in s.split(',')] for s in samples_str if s]
    
    if not samples:
        print("No valid data provided for prediction.")
        return

    print(f"Making predictions on {len(samples)} samples...")
    predictions = model.predict(samples)
    prediction_proba = model.predict_proba(samples)
    
    # In a real Kubeflow component, you would save this to a file.
    # For this example, we'll just print the results.
    print("\nPredictions:")
    for i, (sample, pred, proba) in enumerate(zip(samples, predictions, prediction_proba)):
        print(f"Sample {i+1}: {sample}")
        print(f"  -> Predicted class: {pred}")
        print(f"  -> Probabilities: {proba.tolist()}")
        print("-" * 20)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Make predictions with a trained model.')
    parser.add_argument('--model_path', type=str, required=True, help='Path to the trained model.')
    parser.add_argument('--input_data', type=str, required=True, help='Semicolon-separated list of comma-separated feature vectors.')
    
    args = parser.parse_args()
    
    make_predictions(args.model_path, args.input_data)
