[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "demo"
)

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "🚀 Starting Azure Container Apps deployment..." -ForegroundColor Cyan
Write-Host ""

# Check if logged in to Azure
Write-Host "Checking Azure CLI login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Logged in as: $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Subscription: $($account.name)" -ForegroundColor Green
Write-Host ""

# Create resource group if it doesn't exist
Write-Host "Checking resource group: $ResourceGroupName" -ForegroundColor Yellow
$rg = az group show --name $ResourceGroupName 2>$null
if (-not $rg) {
    Write-Host "Creating resource group: $ResourceGroupName in $Location" -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location --output none
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Resource group created" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create resource group" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ Resource group exists" -ForegroundColor Green
}
Write-Host ""

# Deploy infrastructure
Write-Host "Deploying infrastructure with Bicep..." -ForegroundColor Yellow
Write-Host "  - Virtual Network" -ForegroundColor Gray
Write-Host "  - Azure Container Registry" -ForegroundColor Gray
Write-Host "  - Container Apps Environment" -ForegroundColor Gray
Write-Host "  - Container App (placeholder)" -ForegroundColor Gray
Write-Host ""

$deploymentName = "aca-deploy-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$bicepFile = Join-Path $RootDir "infra\main.bicep"

$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --name $deploymentName `
    --template-file $bicepFile `
    --parameters location=$Location environmentName=$EnvironmentName `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host ""

# Extract outputs
$outputs = $deployment.properties.outputs
$acrName = $outputs.acrName.value
$acrLoginServer = $outputs.acrLoginServer.value
$containerAppName = "ca-demo-webapp"
$containerAppUrl = $outputs.containerAppUrl.value

Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "  ACR Name: $acrName" -ForegroundColor White
Write-Host "  ACR Login Server: $acrLoginServer" -ForegroundColor White
Write-Host "  Container App: $containerAppName" -ForegroundColor White
Write-Host "  App URL: https://$containerAppUrl" -ForegroundColor White
Write-Host ""

Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Build and push your container image:" -ForegroundColor Yellow
Write-Host "     .\scripts\build-and-push.ps1 -AcrName $acrName" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Update the container app with your image:" -ForegroundColor Yellow
Write-Host "     az containerapp update --name $containerAppName --resource-group $ResourceGroupName --image $acrLoginServer/demo-webapp:v1" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Access your application:" -ForegroundColor Yellow
Write-Host "     https://$containerAppUrl" -ForegroundColor Gray
Write-Host ""

# Save outputs to file
$outputFile = Join-Path $RootDir "deployment-outputs.json"
$outputs | ConvertTo-Json | Out-File $outputFile
Write-Host "✓ Deployment outputs saved to: $outputFile" -ForegroundColor Green
