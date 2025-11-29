"""
KServe-compatible FastAPI server for Iris XGBoost model
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import numpy as np
from pathlib import Path
from typing import List, Optional
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Iris Model Server", version="1.0")

# Model configuration
MODEL_PATH = Path("/mnt/models/model")  # KServe downloads without extension
CLASS_NAMES = ['setosa', 'versicolor', 'virginica']

# Global model variable
model = None


class PredictionRequest(BaseModel):
    """Request format for predictions"""
    instances: List[List[float]]

    class Config:
        schema_extra = {
            "example": {
                "instances": [
                    [5.1, 3.5, 1.4, 0.2],
                    [6.7, 3.0, 5.2, 2.3]
                ]
            }
        }


class PredictionResponse(BaseModel):
    """Response format for predictions"""
    predictions: List[int]
    class_names: Optional[List[str]] = None


@app.on_event("startup")
async def load_model():
    """Load model at server startup"""
    global model
    try:
        logger.info(f"Loading model from {MODEL_PATH}")

        if not MODEL_PATH.exists():
            logger.warning(f"Model file not found at {MODEL_PATH}, using dummy model")
            # Create a dummy model for testing
            from sklearn.ensemble import RandomForestClassifier
            from sklearn.datasets import load_iris

            iris = load_iris()
            model = RandomForestClassifier(random_state=42)
            model.fit(iris.data, iris.target)
            logger.info("Dummy model created and trained")
        else:
            with open(MODEL_PATH, 'rb') as f:
                model = pickle.load(f)
            logger.info(f"Model loaded successfully from {MODEL_PATH}")

        # Test prediction
        test_input = np.array([[5.1, 3.5, 1.4, 0.2]])
        test_pred = model.predict(test_input)
        logger.info(f"Model test prediction: {test_pred[0]} (class: {CLASS_NAMES[test_pred[0]]})")

    except Exception as e:
        logger.error(f"Error loading model: {e}")
        raise RuntimeError(f"Failed to load model: {e}")


@app.get("/")
async def root():
    """Root endpoint with service info"""
    return {
        "name": "Iris Model Server",
        "version": "1.0",
        "model": "XGBoost/RandomForest Iris Classifier",
        "status": "ready" if model is not None else "not ready",
        "endpoints": {
            "health": "/health",
            "predict_v1": "/v1/models/iris-model:predict",
            "predict": "/predict"
        }
    }


@app.get("/health")
@app.get("/v1/models/iris-model")
async def health():
    """
    Health check endpoint
    Compatible with KServe health check
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    return {
        "name": "iris-model",
        "ready": True,
        "status": "healthy"
    }


@app.post("/v1/models/iris-model:predict", response_model=PredictionResponse)
async def predict_v1(request: PredictionRequest):
    """
    KServe v1 protocol prediction endpoint

    This endpoint follows KServe's prediction protocol:
    POST /v1/models/<model-name>:predict

    Example request:
    {
        "instances": [
            [5.1, 3.5, 1.4, 0.2],
            [6.7, 3.0, 5.2, 2.3]
        ]
    }

    Example response:
    {
        "predictions": [0, 2],
        "class_names": ["setosa", "virginica"]
    }
    """
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        logger.info(f"Received prediction request with {len(request.instances)} instances")

        # Convert to numpy array
        X = np.array(request.instances)

        # Validate input shape
        if X.shape[1] != 4:
            raise ValueError(f"Expected 4 features, got {X.shape[1]}")

        # Make predictions
        predictions = model.predict(X)

        # Convert to list
        pred_list = predictions.tolist()

        # Get class names
        class_list = [CLASS_NAMES[p] for p in pred_list]

        logger.info(f"Predictions: {pred_list} -> {class_list}")

        return {
            "predictions": pred_list,
            "class_names": class_list
        }

    except ValueError as e:
        logger.error(f"Validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Prediction error: {e}")
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    """
    Simple prediction endpoint (alias for v1 endpoint)
    """
    return await predict_v1(request)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
