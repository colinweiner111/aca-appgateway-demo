[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AcrName,
    
    [Parameter(Mandatory=$false)]
    [string]$ImageTag = "v1",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerAppName = "ca-demo-webapp"
)

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir
$AppDir = Join-Path $RootDir "app"

Write-Host "🐳 Building and pushing container image..." -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
$dockerInfo = docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Docker is running" -ForegroundColor Green
Write-Host ""

# Get ACR login server
Write-Host "Getting ACR information..." -ForegroundColor Yellow
$acr = az acr show --name $AcrName --output json | ConvertFrom-Json
if (-not $acr) {
    Write-Host "❌ ACR not found: $AcrName" -ForegroundColor Red
    exit 1
}
$acrLoginServer = $acr.loginServer
Write-Host "✓ ACR: $acrLoginServer" -ForegroundColor Green
Write-Host ""

# Login to ACR
Write-Host "Logging in to Azure Container Registry..." -ForegroundColor Yellow
az acr login --name $AcrName
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to login to ACR" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Logged in to ACR" -ForegroundColor Green
Write-Host ""

# Build image
$imageName = "$acrLoginServer/demo-webapp:$ImageTag"
Write-Host "Building Docker image: $imageName" -ForegroundColor Yellow
Write-Host "  Source: $AppDir" -ForegroundColor Gray
Write-Host ""

docker build -t $imageName $AppDir
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Image built successfully" -ForegroundColor Green
Write-Host ""

# Push image
Write-Host "Pushing image to ACR..." -ForegroundColor Yellow
docker push $imageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker push failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Image pushed successfully" -ForegroundColor Green
Write-Host ""

# Update container app if ResourceGroupName is provided
if ($ResourceGroupName) {
    Write-Host "Updating Container App: $ContainerAppName" -ForegroundColor Yellow
    az containerapp update `
        --name $ContainerAppName `
        --resource-group $ResourceGroupName `
        --image $imageName `
        --output none
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container App updated" -ForegroundColor Green
        Write-Host ""
        
        # Get app URL
        $fqdn = az containerapp show `
            --name $ContainerAppName `
            --resource-group $ResourceGroupName `
            --query "properties.configuration.ingress.fqdn" `
            --output tsv
        
        Write-Host "🌐 Application URL: https://$fqdn" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Failed to update Container App" -ForegroundColor Yellow
    }
} else {
    Write-Host "📝 To update your Container App, run:" -ForegroundColor Cyan
    Write-Host "   az containerapp update --name $ContainerAppName --resource-group <RESOURCE_GROUP> --image $imageName" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ Build and push completed!" -ForegroundColor Green
