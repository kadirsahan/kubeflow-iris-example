
import pandas as pd
import xgboost as xgb
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
import argparse
import pickle
import os
import json

def train_model(data_path: str, model_output_path: str, model_name: str, model_hyperparameters: str):
    """Loads data, trains a specified model, and saves it."""
    print("Loading data...")
    df = pd.read_csv(data_path)
    
    X = df.drop('target', axis=1)
    y = df['target']
    
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"Training {model_name} model...")
    
    # Parse the hyperparameter JSON string
    try:
        hyperparameters = json.loads(model_hyperparameters)
    except (json.JSONDecodeError, TypeError):
        print(f"Invalid or empty JSON for hyperparameters. Using default parameters for {model_name}.")
        hyperparameters = {}

    print(f"Using hyperparameters: {hyperparameters}")

    # Select and instantiate the model
    if model_name == 'random_forest':
        model = RandomForestClassifier(**hyperparameters)
    elif model_name == 'logistic_regression':
        model = LogisticRegression(**hyperparameters)
    elif model_name == 'xgboost':
        # Set default xgboost params that can be overridden by the user's JSON
        default_xgb_params = {'objective': 'multi:softprob', 'eval_metric': 'mlogloss', 'use_label_encoder': False}
        final_params = {**default_xgb_params, **hyperparameters}
        model = xgb.XGBClassifier(**final_params)
    else:
        raise ValueError(f"Unsupported model_name: {model_name}. Supported options are 'xgboost', 'random_forest', 'logistic_regression'.")

    model.fit(X_train, y_train)
    
    print(f"Model trained. Accuracy: {model.score(X_test, y_test):.4f}")
    
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(model_output_path), exist_ok=True)
    
    print(f"Saving model to {model_output_path}")
    with open(model_output_path, 'wb') as f:
        pickle.dump(model, f)
    print("Model saved successfully.")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Train a machine learning model.')
    parser.add_argument('--data_path', type=str, required=True, help='Path to the training data.')
    parser.add_argument('--model_output_path', type=str, required=True, help='Path to save the trained model.')
    parser.add_argument('--model-name', type=str, default='xgboost', help="The name of the model to train (e.g., 'xgboost', 'random_forest', 'logistic_regression').")
    parser.add_argument('--model-hyperparameters', type=str, default='{}', help="JSON string of hyperparameters for the model.")
    
    args = parser.parse_args()
    
    train_model(args.data_path, args.model_output_path, args.model_name, args.model_hyperparameters)
