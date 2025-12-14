#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete deployment script for Azure Container Apps with Application Gateway
.DESCRIPTION
    This script deploys the entire solution from start to finish:
    1. Creates resource group
    2. Deploys infrastructure (VNET, ACR, Container Apps, App Gateway)
    3. Enables ACR public access for build
    4. Builds and pushes container image
    5. Updates container app with the image
    6. Displays application URLs
.PARAMETER ResourceGroup
    Name of the resource group (default: rg-aca-demo)
.PARAMETER Location
    Azure region (default: westus3)
#>

param(
    [string]$ResourceGroup = "rg-aca-demo",
    [string]$Location = "westus3"
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Azure Container Apps Complete Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Create Resource Group
Write-Host "Step 1: Creating resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "✓ Resource group created`n" -ForegroundColor Green

# Step 2: Deploy Infrastructure
Write-Host "Step 2: Deploying infrastructure (this takes ~15-20 minutes)..." -ForegroundColor Yellow
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file infra/main.bicep `
    --parameters location=$Location

if ($LASTEXITCODE -ne 0) { 
    Write-Host "✗ Infrastructure deployment failed" -ForegroundColor Red
    exit 1 
}
Write-Host "✓ Infrastructure deployed successfully`n" -ForegroundColor Green

# Step 3: Get ACR Name
Write-Host "Step 3: Getting Azure Container Registry name..." -ForegroundColor Yellow
$ACR_NAME = az deployment group show `
    --resource-group $ResourceGroup `
    --name main `
    --query properties.outputs.acrName.value `
    --output tsv

Write-Host "✓ ACR Name: $ACR_NAME`n" -ForegroundColor Green

# Step 4: Enable ACR Public Access (required for ACR Tasks build agents)
Write-Host "Step 4: Enabling ACR public access for build..." -ForegroundColor Yellow
az acr update --name $ACR_NAME --public-network-enabled true --default-action Allow
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "✓ ACR public access enabled`n" -ForegroundColor Green

# Step 5: Build and Push Container Image
Write-Host "Step 5: Building and pushing container image..." -ForegroundColor Yellow
az acr build `
    --registry $ACR_NAME `
    --image demo-webapp:v1 `
    --file app/Dockerfile `
    app/

if ($LASTEXITCODE -ne 0) { 
    Write-Host "✗ Container build failed" -ForegroundColor Red
    exit 1 
}
Write-Host "✓ Container image built and pushed`n" -ForegroundColor Green

# Step 6: Update Container App
Write-Host "Step 6: Updating container app with image..." -ForegroundColor Yellow
az containerapp update `
    --name ca-demo-webapp `
    --resource-group $ResourceGroup `
    --image "$ACR_NAME.azurecr.io/demo-webapp:v1"

if ($LASTEXITCODE -ne 0) { 
    Write-Host "✗ Container app update failed" -ForegroundColor Red
    exit 1 
}
Write-Host "✓ Container app updated`n" -ForegroundColor Green

# Step 7: Get Application URLs
Write-Host "Step 7: Retrieving application URLs..." -ForegroundColor Yellow
$APPGW_IP = az deployment group show `
    --resource-group $ResourceGroup `
    --name main `
    --query properties.outputs.appGatewayPublicIP.value `
    --output tsv

$APPGW_URL = az deployment group show `
    --resource-group $ResourceGroup `
    --name main `
    --query properties.outputs.appGatewayFqdn.value `
    --output tsv

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nApplication Gateway IP:  http://$APPGW_IP" -ForegroundColor White
Write-Host "Application Gateway URL: http://$APPGW_URL" -ForegroundColor White
Write-Host "`nOpen either URL in your browser to access the application.`n" -ForegroundColor White
