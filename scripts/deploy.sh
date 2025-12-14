#!/bin/bash

# Azure Container Apps Deployment Script
# Usage: ./deploy.sh <resource-group> <location> [environment-name]

set -e

RESOURCE_GROUP=${1:-"rg-aca-demo"}
LOCATION=${2:-"westus3"}
ENVIRONMENT_NAME=${3:-"demo"}

echo "🚀 Starting Azure Container Apps deployment..."
echo ""

# Check if logged in to Azure
echo "Checking Azure CLI login status..."
ACCOUNT=$(az account show 2>/dev/null || echo "")
if [ -z "$ACCOUNT" ]; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

ACCOUNT_NAME=$(echo $ACCOUNT | jq -r '.user.name')
SUBSCRIPTION_NAME=$(echo $ACCOUNT | jq -r '.name')
echo "✓ Logged in as: $ACCOUNT_NAME"
echo "✓ Subscription: $SUBSCRIPTION_NAME"
echo ""

# Create resource group if it doesn't exist
echo "Checking resource group: $RESOURCE_GROUP"
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP in $LOCATION"
    az group create --name $RESOURCE_GROUP --location $LOCATION --output none
    echo "✓ Resource group created"
else
    echo "✓ Resource group exists"
fi
echo ""

# Deploy infrastructure
echo "Deploying infrastructure with Bicep..."
echo "  - Virtual Network"
echo "  - Azure Container Registry"
echo "  - Container Apps Environment"
echo "  - Container App (placeholder)"
echo ""

DEPLOYMENT_NAME="aca-deploy-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BICEP_FILE="$ROOT_DIR/infra/main.bicep"

DEPLOYMENT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name $DEPLOYMENT_NAME \
    --template-file $BICEP_FILE \
    --parameters location=$LOCATION environmentName=$ENVIRONMENT_NAME \
    --output json)

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi

echo "✓ Infrastructure deployed successfully!"
echo ""

# Extract outputs
ACR_NAME=$(echo $DEPLOYMENT | jq -r '.properties.outputs.acrName.value')
ACR_LOGIN_SERVER=$(echo $DEPLOYMENT | jq -r '.properties.outputs.acrLoginServer.value')
CONTAINER_APP_NAME="ca-demo-webapp"
CONTAINER_APP_URL=$(echo $DEPLOYMENT | jq -r '.properties.outputs.containerAppUrl.value')

echo "📋 Deployment Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  ACR Name: $ACR_NAME"
echo "  ACR Login Server: $ACR_LOGIN_SERVER"
echo "  Container App: $CONTAINER_APP_NAME"
echo "  App URL: https://$CONTAINER_APP_URL"
echo ""

echo "📝 Next Steps:"
echo "  1. Build and push your container image:"
echo "     ./scripts/build-and-push.sh $ACR_NAME $RESOURCE_GROUP"
echo ""
echo "  2. Access your application:"
echo "     https://$CONTAINER_APP_URL"
echo ""

# Save outputs to file
OUTPUT_FILE="$ROOT_DIR/deployment-outputs.json"
echo $DEPLOYMENT | jq '.properties.outputs' > $OUTPUT_FILE
echo "✓ Deployment outputs saved to: $OUTPUT_FILE"
