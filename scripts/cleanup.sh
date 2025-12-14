#!/bin/bash

# Cleanup Azure Resources
# Usage: ./cleanup.sh <resource-group>

RESOURCE_GROUP=${1}

if [ -z "$RESOURCE_GROUP" ]; then
    echo "❌ Error: Resource group name is required"
    echo "Usage: ./cleanup.sh <resource-group>"
    exit 1
fi

echo "🗑️  Deleting resource group: $RESOURCE_GROUP"
echo ""

read -p "Are you sure you want to delete the resource group and ALL resources? (yes/no): " CONFIRMATION
if [ "$CONFIRMATION" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo "Deleting resource group (this may take a few minutes)..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "✓ Deletion initiated"
echo ""
echo "To check deletion status:"
echo "  az group show --name $RESOURCE_GROUP"
