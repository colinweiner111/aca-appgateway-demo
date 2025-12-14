#!/bin/bash

# Build and Push Container Image
# Usage: ./build-and-push.sh <acr-name> [resource-group] [image-tag]

set -e

ACR_NAME=${1}
RESOURCE_GROUP=${2:-""}
IMAGE_TAG=${3:-"v1"}
CONTAINER_APP_NAME="ca-demo-webapp"

if [ -z "$ACR_NAME" ]; then
    echo "❌ Error: ACR name is required"
    echo "Usage: ./build-and-push.sh <acr-name> [resource-group] [image-tag]"
    exit 1
fi

echo "🐳 Building and pushing container image..."
echo ""

# Check if Docker is running
echo "Checking Docker..."
if ! docker info &>/dev/null; then
    echo "❌ Docker is not running. Please start Docker."
    exit 1
fi
echo "✓ Docker is running"
echo ""

# Get ACR login server
echo "Getting ACR information..."
ACR_INFO=$(az acr show --name $ACR_NAME --output json 2>/dev/null)
if [ -z "$ACR_INFO" ]; then
    echo "❌ ACR not found: $ACR_NAME"
    exit 1
fi

ACR_LOGIN_SERVER=$(echo $ACR_INFO | jq -r '.loginServer')
echo "✓ ACR: $ACR_LOGIN_SERVER"
echo ""

# Login to ACR
echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME
if [ $? -ne 0 ]; then
    echo "❌ Failed to login to ACR"
    exit 1
fi
echo "✓ Logged in to ACR"
echo ""

# Build image
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
APP_DIR="$ROOT_DIR/app"
IMAGE_NAME="$ACR_LOGIN_SERVER/demo-webapp:$IMAGE_TAG"

echo "Building Docker image: $IMAGE_NAME"
echo "  Source: $APP_DIR"
echo ""

docker build -t $IMAGE_NAME $APP_DIR
if [ $? -ne 0 ]; then
    echo "❌ Docker build failed"
    exit 1
fi
echo "✓ Image built successfully"
echo ""

# Push image
echo "Pushing image to ACR..."
docker push $IMAGE_NAME
if [ $? -ne 0 ]; then
    echo "❌ Docker push failed"
    exit 1
fi
echo "✓ Image pushed successfully"
echo ""

# Update container app if resource group is provided
if [ -n "$RESOURCE_GROUP" ]; then
    echo "Updating Container App: $CONTAINER_APP_NAME"
    az containerapp update \
        --name $CONTAINER_APP_NAME \
        --resource-group $RESOURCE_GROUP \
        --image $IMAGE_NAME \
        --output none
    
    if [ $? -eq 0 ]; then
        echo "✓ Container App updated"
        echo ""
        
        # Get app URL
        FQDN=$(az containerapp show \
            --name $CONTAINER_APP_NAME \
            --resource-group $RESOURCE_GROUP \
            --query "properties.configuration.ingress.fqdn" \
            --output tsv)
        
        echo "🌐 Application URL: https://$FQDN"
    else
        echo "⚠️  Failed to update Container App"
    fi
else
    echo "📝 To update your Container App, run:"
    echo "   az containerapp update --name $CONTAINER_APP_NAME --resource-group <RESOURCE_GROUP> --image $IMAGE_NAME"
fi

echo ""
echo "✓ Build and push completed!"
