# iris_xgboost.py
"""
Iris Dataset Classification using XGBoost
"""

import numpy as np
import pandas as pd
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.preprocessing import LabelEncoder
import xgboost as xgb
import matplotlib.pyplot as plt
import seaborn as sns

# Set random seed for reproducibility
np.random.seed(42)

def load_and_explore_data():
    """
    Load the Iris dataset and explore its basic properties
    """
    print("Loading Iris dataset...")
    iris = load_iris()
    
    # Create a DataFrame for better visualization
    df = pd.DataFrame(data=iris.data, columns=iris.feature_names)
    df['target'] = iris.target
    df['species'] = df['target'].apply(lambda x: iris.target_names[x])
    
    print("\nDataset Overview:")
    print(f"Dataset shape: {df.shape}")
    print(f"Features: {iris.feature_names}")
    print(f"Target classes: {list(iris.target_names)}")
    
    print("\nFirst 5 rows:")
    print(df.head())
    
    print("\nDataset Info:")
    print(df.info())
    
    print("\nBasic Statistics:")
    print(df.describe())
    
    print("\nClass distribution:")
    print(df['species'].value_counts())
    
    return df, iris

def visualize_data(df):
    """
    Create visualizations to understand the data distribution
    """
    print("\nCreating visualizations...")
    
    # Set up the plotting style
    plt.style.use('default')
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    
    # Feature distributions by species
    features = ['sepal length (cm)', 'sepal width (cm)', 'petal length (cm)', 'petal width (cm)']
    
    for i, feature in enumerate(features):
        row, col = i // 2, i % 2
        for species in df['species'].unique():
            species_data = df[df['species'] == species][feature]
            axes[row, col].hist(species_data, alpha=0.7, label=species, bins=15)
        
        axes[row, col].set_title(f'Distribution of {feature}')
        axes[row, col].set_xlabel(feature)
        axes[row, col].set_ylabel('Frequency')
        axes[row, col].legend()
    
    plt.tight_layout()
    plt.show()
    
    # Correlation heatmap
    plt.figure(figsize=(8, 6))
    numeric_df = df.select_dtypes(include=[np.number])
    correlation_matrix = numeric_df.corr()
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0)
    plt.title('Feature Correlation Heatmap')
    plt.show()

def prepare_data(iris):
    """
    Prepare the data for training
    """
    print("\nPreparing data for training...")
    
    X = iris.data
    y = iris.target
    
    # Split the data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    print(f"Training set size: {X_train.shape[0]}")
    print(f"Testing set size: {X_test.shape[0]}")
    print(f"Number of features: {X_train.shape[1]}")
    
    return X_train, X_test, y_train, y_test

def train_xgboost_model(X_train, X_test, y_train, y_test):
    """
    Train and evaluate an XGBoost model
    """
    print("\nTraining XGBoost model...")
    
    # Initialize XGBoost classifier
    model = xgb.XGBClassifier(
        objective='multi:softprob',  # For multi-class classification
        max_depth=6,                 # Maximum depth of trees
        learning_rate=0.1,           # Learning rate
        n_estimators=100,            # Number of trees
        random_state=42,
        eval_metric='mlogloss'       # Evaluation metric for multi-class
    )
    
    # Train the model
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],  # Evaluate on test set during training
        verbose=False
    )
    
    # Make predictions
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)
    
    # Calculate accuracy
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\nModel Accuracy: {accuracy:.4f}")
    
    return model, y_pred, y_pred_proba

def evaluate_model(model, X_test, y_test, y_pred, iris):
    """
    Evaluate the model performance
    """
    print("\nModel Evaluation:")
    print("=" * 50)
    
    # Classification report
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=iris.target_names))
    
    # Confusion matrix
    print("Confusion Matrix:")
    cm = confusion_matrix(y_test, y_pred)
    print(cm)
    
    # Plot confusion matrix
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=iris.target_names, 
                yticklabels=iris.target_names)
    plt.title('Confusion Matrix')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.show()
    
    # Feature importance
    print("\nFeature Importance:")
    feature_importance = model.feature_importances_
    features = iris.feature_names
    
    for feature, importance in zip(features, feature_importance):
        print(f"{feature}: {importance:.4f}")
    
    # Plot feature importance
    plt.figure(figsize=(10, 6))
    indices = np.argsort(feature_importance)[::-1]
    plt.bar(range(len(features)), feature_importance[indices])
    plt.xticks(range(len(features)), [features[i] for i in indices], rotation=45)
    plt.title('Feature Importance')
    plt.xlabel('Features')
    plt.ylabel('Importance')
    plt.tight_layout()
    plt.show()

def make_predictions(model, iris):
    """
    Make predictions on new sample data
    """
    print("\nMaking predictions on sample data...")
    
    # Sample data for prediction (you can modify these values)
    sample_data = [
        [5.1, 3.5, 1.4, 0.2],  # Should be setosa
        [6.7, 3.0, 5.2, 2.3],  # Should be virginica
        [5.9, 3.0, 4.2, 1.5],  # Should be versicolor
        [7.0, 3.2, 4.7, 1.4]   # Should be versicolor
    ]
    
    predictions = model.predict(sample_data)
    prediction_proba = model.predict_proba(sample_data)
    
    print("\nSample Predictions:")
    for i, (sample, pred, proba) in enumerate(zip(sample_data, predictions, prediction_proba)):
        predicted_class = iris.target_names[pred]
        print(f"Sample {i+1}: {sample}")
        print(f"Predicted: {predicted_class}")
        print(f"Probabilities: {dict(zip(iris.target_names, proba))}")
        print("-" * 40)

def main():
    """
    Main function to run the complete pipeline
    """
    print("Iris Dataset Classification with XGBoost")
    print("=" * 50)
    
    try:
        # Load and explore data
        df, iris = load_and_explore_data()
        
        # Visualize data (optional - comment out if you don't want plots)
        # visualize_data(df)
        
        # Prepare data
        X_train, X_test, y_train, y_test = prepare_data(iris)
        
        # Train XGBoost model
        model, y_pred, y_pred_proba = train_xgboost_model(X_train, X_test, y_train, y_test)
        
        # Evaluate model
        evaluate_model(model, X_test, y_test, y_pred, iris)
        
        # Make predictions on sample data
        make_predictions(model, iris)
        
        print("\nTraining completed successfully!")
        print(f"Final model accuracy: {accuracy_score(y_test, y_pred):.4f}")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        return None
    
    return model

if __name__ == "__main__":
    # Install required packages if not already installed:
    # pip install xgboost scikit-learn pandas numpy matplotlib seaborn
    
    trained_model = main()