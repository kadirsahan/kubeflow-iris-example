
import pandas as pd
from sklearn.datasets import load_iris
import argparse
import os

def download_data(output_path):
    """Loads the Iris dataset and saves it to a CSV file."""
    print("Loading Iris dataset...")
    iris = load_iris()
    
    df = pd.DataFrame(data=iris.data, columns=iris.feature_names)
    df['target'] = iris.target
    
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    print(f"Saving data to {output_path}")
    df.to_csv(output_path, index=False)
    print("Data saved successfully.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Download Iris dataset.')
    parser.add_argument('--output_path', type=str, required=True, help='Path to save the downloaded data.')
    args = parser.parse_args()
    
    download_data(args.output_path)
