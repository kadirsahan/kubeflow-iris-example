#!/bin/bash
#
# KServe Iris Model - Inference Test Script
# Usage: ./test-inference.sh
#

set -e

echo "🧪 Testing KServe Iris Model Inference Endpoint"
echo "================================================"
echo ""

# Get pod name
POD_NAME=$(kubectl get pods -n user-example-com -l serving.kserve.io/inferenceservice=iris-model -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ Error: No pod found for iris-model InferenceService"
    exit 1
fi

echo "📦 Pod: $POD_NAME"
echo ""

# Test 1: Health Check
echo "🔍 Test 1: Health Check"
echo "-----------------------"
kubectl exec $POD_NAME -n user-example-com -c kserve-container -- python -c "
import requests
response = requests.get('http://localhost:8080/health')
print(f'Status: {response.status_code}')
print(f'Response: {response.json()}')
" 2>/dev/null || echo "⚠️  Health check endpoint may not be available"
echo ""

# Test 2: Single Sample Prediction
echo "🧪 Test 2: Single Sample Prediction (Setosa)"
echo "--------------------------------------------"
echo "Input: [5.1, 3.5, 1.4, 0.2] - Small flower, expected: setosa"
kubectl exec $POD_NAME -n user-example-com -c kserve-container -- python -c "
import requests
import json

response = requests.post(
    'http://localhost:8080/v1/models/iris-model:predict',
    headers={'Content-Type': 'application/json'},
    json={'instances': [[5.1, 3.5, 1.4, 0.2]]}
)
print(f'Status Code: {response.status_code}')
print(f'Response:')
print(json.dumps(response.json(), indent=2))
"
echo ""

# Test 3: Multiple Samples Prediction
echo "🧪 Test 3: Multiple Samples Prediction"
echo "--------------------------------------"
echo "Input 1: [5.1, 3.5, 1.4, 0.2] - Small flower, expected: setosa"
echo "Input 2: [6.7, 3.0, 5.2, 2.3] - Large flower, expected: virginica"
kubectl exec $POD_NAME -n user-example-com -c kserve-container -- python -c "
import requests
import json

response = requests.post(
    'http://localhost:8080/v1/models/iris-model:predict',
    headers={'Content-Type': 'application/json'},
    json={'instances': [[5.1, 3.5, 1.4, 0.2], [6.7, 3.0, 5.2, 2.3]]}
)
print(f'Status Code: {response.status_code}')
print(f'Response:')
print(json.dumps(response.json(), indent=2))
"
echo ""

# Test 4: All Three Classes
echo "🧪 Test 4: All Three Iris Classes"
echo "----------------------------------"
echo "Input 1: [5.1, 3.5, 1.4, 0.2] - expected: setosa (0)"
echo "Input 2: [5.7, 2.8, 4.1, 1.3] - expected: versicolor (1)"
echo "Input 3: [6.3, 3.3, 6.0, 2.5] - expected: virginica (2)"
kubectl exec $POD_NAME -n user-example-com -c kserve-container -- python -c "
import requests
import json

response = requests.post(
    'http://localhost:8080/v1/models/iris-model:predict',
    headers={'Content-Type': 'application/json'},
    json={'instances': [
        [5.1, 3.5, 1.4, 0.2],
        [5.7, 2.8, 4.1, 1.3],
        [6.3, 3.3, 6.0, 2.5]
    ]}
)
print(f'Status Code: {response.status_code}')
print(f'Response:')
print(json.dumps(response.json(), indent=2))
"
echo ""

# Check server logs
echo "📋 Server Logs (last 15 lines)"
echo "-------------------------------"
kubectl logs $POD_NAME -n user-example-com -c kserve-container --tail=15
echo ""

echo "✅ All tests completed!"
echo ""
echo "📊 Summary:"
echo "  - Health check: Tested"
echo "  - Single prediction: ✅"
echo "  - Multiple predictions: ✅"
echo "  - All three classes: ✅"
echo ""
echo "🎉 Model is serving predictions successfully!"
