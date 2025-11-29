#!/bin/bash

# Script to create a project in Harbor using the API

set -e

echo "=========================================="
echo "Create Harbor Project"
echo "=========================================="
echo ""

# Variables
HARBOR_URL="http://192.168.58.12:30002"
HARBOR_USERNAME="admin"
HARBOR_PASSWORD="Harbor12345"
PROJECT_NAME="kubeflow-iris"
PROJECT_PUBLIC="false"  # true for public, false for private

echo "Harbor URL: $HARBOR_URL"
echo "Project Name: $PROJECT_NAME"
echo "Public: $PROJECT_PUBLIC"
echo ""

# Create project using Harbor API
echo "Creating project in Harbor..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "${HARBOR_URL}/api/v2.0/projects" \
  -H "Content-Type: application/json" \
  -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
  -d "{
    \"project_name\": \"${PROJECT_NAME}\",
    \"public\": ${PROJECT_PUBLIC},
    \"metadata\": {
      \"public\": \"${PROJECT_PUBLIC}\"
    }
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" -eq 201 ]; then
    echo "✓ Project '${PROJECT_NAME}' created successfully"
elif [ "$HTTP_CODE" -eq 409 ]; then
    echo "✓ Project '${PROJECT_NAME}' already exists"
else
    echo "Error creating project. HTTP Code: $HTTP_CODE"
    echo "Response: $BODY"
    exit 1
fi

echo ""

# Verify project exists
echo "Verifying project..."
PROJECT_CHECK=$(curl -s -X GET \
  "${HARBOR_URL}/api/v2.0/projects?name=${PROJECT_NAME}" \
  -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}")

if echo "$PROJECT_CHECK" | grep -q "\"name\":\"${PROJECT_NAME}\""; then
    echo "✓ Project verified successfully"
else
    echo "Warning: Could not verify project"
fi

echo ""
echo "=========================================="
echo "Project Creation Complete!"
echo "=========================================="
echo ""
echo "Project Details:"
echo "  Name: $PROJECT_NAME"
echo "  Access: $([ \"$PROJECT_PUBLIC\" = \"true\" ] && echo \"Public\" || echo \"Private\")"
echo ""
echo "View project in Harbor UI:"
echo "  ${HARBOR_URL}"
echo "  Login: $HARBOR_USERNAME"
echo ""
echo "Push images to this project:"
echo "  docker push 192.168.58.12:30002/${PROJECT_NAME}/your-image:tag"
echo ""
