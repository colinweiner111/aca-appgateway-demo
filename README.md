# Azure Container Apps Demo with Application Gateway

A demonstration of Azure Container Apps with Application Gateway WAF, private ACR, and VNET integration.

## Architecture

```
Internet
    ↓
Application Gateway WAF (10.0.3.0/24)
    ↓ (HTTPS backend)
Azure Container Apps (10.0.0.0/23)
    ↓ (Private Endpoint)
Azure Container Registry (10.0.2.0/24)
```

### Key Features

- ✅ **Application Gateway WAF_v2** - Layer 7 load balancer with OWASP 3.2 and Bot Manager rulesets
- ✅ **Azure Container Apps** - Serverless container platform with HTTP auto-scaling (1-3 replicas)
- ✅ **Private ACR** - Premium registry with private endpoint integration
- ✅ **Managed Identity** - Secure authentication without credentials
- ✅ **VNET Integration** - Complete network isolation and control

## 📋 Prerequisites

- Azure CLI (`az`) installed and authenticated
- Azure subscription with appropriate permissions
- PowerShell 7+ or Bash

## 🚀 Quick Start

**One-Command Deployment:**

```powershell
git clone https://github.com/colinweiner111/aca-appgateway-demo.git
cd aca-appgateway-demo
.\scripts\deploy-all.ps1
```

This single script deploys everything: resource group, infrastructure, builds the container image, and provides your application URLs.

**Custom deployment:**

```powershell
.\scripts\deploy-all.ps1 -ResourceGroup "rg-aca-demo" -Location "westus3"
```

### Manual Step-by-Step (Optional)

If you prefer manual control:

### 1. Clone the Repository

```bash
git clone https://github.com/colinweiner111/aca-appgateway-demo.git
cd aca-appgateway-demo
```

### 2. Deploy Infrastructure

```bash
# Create resource group
az group create --name rg-aca-demo --location westus3

# Deploy all infrastructure
az deployment group create `
  --resource-group rg-aca-demo `
  --template-file infra/main.bicep `
  --parameters location=westus3
```

**Deployment time**: ~10-11 minutes

### 3. Build and Deploy Application

```powershell
# Get ACR name from deployment output
$ACR_NAME = az deployment group show `
  --resource-group rg-aca-demo `
  --name main `
  --query properties.outputs.acrName.value -o tsv

# Enable public access for ACR Tasks (required for builds)
az acr update --name $ACR_NAME --public-network-enabled true --default-action Allow

# Build and push container image
az acr build `
  --registry $ACR_NAME `
  --image demo-webapp:v1 `
  ./app

# Update Container App with new image
az containerapp update `
  --name ca-demo-webapp `
  --resource-group rg-aca-demo `
  --image "${ACR_NAME}.azurecr.io/demo-webapp:v1"
```

### 4. Access Your Application

Get the Application Gateway public IP and URL:

```powershell
# Get public IP
$APPGW_IP = az deployment group show `
  --resource-group rg-aca-demo `
  --name main `
  --query properties.outputs.appGatewayPublicIp.value -o tsv

# Get FQDN
$APPGW_URL = az deployment group show `
  --resource-group rg-aca-demo `
  --name main `
  --query properties.outputs.appGatewayFqdn.value -o tsv

Write-Host "Application Gateway IP:  http://$APPGW_IP"
Write-Host "Application Gateway URL: http://$APPGW_URL"
```

Access via: `http://<public-ip>` or `http://<fqdn>`

## 📁 Project Structure

```
aca-demo-app/
├── app/
│   ├── Dockerfile              # Container image definition
│   ├── package.json            # Application dependencies
│   └── server.js               # Express web server
├── infra/
│   ├── main.bicep              # Main orchestration template
│   ├── vnet.bicep              # Virtual network with 3 subnets
│   ├── acr.bicep               # Container registry
│   ├── acr-private-endpoint.bicep  # ACR private connectivity
│   ├── container-app.bicep     # Container Apps environment & app
│   └── appgateway.bicep        # Application Gateway with WAF
└── scripts/
    ├── deploy.ps1              # PowerShell deployment script
    ├── deploy.sh               # Bash deployment script
    ├── build-and-push.ps1      # Build & push container (PS)
    ├── build-and-push.sh       # Build & push container (Bash)
    ├── cleanup.ps1             # Delete resources (PS)
    └── cleanup.sh              # Delete resources (Bash)
```

## 🔧 Infrastructure Components

### Virtual Network (10.0.0.0/16)
- **Container Apps Subnet** (10.0.0.0/23) - Hosts Container Apps Environment
- **Private Endpoint Subnet** (10.0.2.0/24) - ACR private endpoint
- **App Gateway Subnet** (10.0.3.0/24) - Application Gateway instances

### Application Gateway
- **SKU**: WAF_v2 (2 instances)
- **WAF Policy**: OWASP 3.2 + Microsoft Bot Manager 1.0 (Prevention mode)
- **Listener**: HTTP on port 80
- **Backend**: HTTPS to Container App on port 443
- **Health Probe**: /health endpoint with 30s interval

### Container Apps
- **Environment**: VNET-integrated with monitoring
- **Scaling**: 1-3 replicas based on HTTP concurrent requests
- **Resources**: 0.25 vCPU, 0.5 GB RAM per replica
- **Ingress**: External on port 3000
- **Authentication**: Managed identity for ACR pull

### Azure Container Registry
- **SKU**: Premium (required for private endpoints)
- **Access**: Private endpoint + public for builds
- **Authentication**: Managed identity (AcrPull role)

## 🧹 Cleanup

Delete the resource group when done:
```powershell
az group delete --name rg-aca-demo --yes --no-wait
```

## 🔒 Security Features

### WAF Protection
- OWASP ModSecurity Core Rule Set 3.2
- Microsoft Bot Manager ruleset 1.0
- Prevention mode (actively blocks threats)
- SQL injection protection
- Cross-site scripting (XSS) prevention

### Network Isolation
- Container Apps in private subnet
- ACR accessible only via private endpoint
- No public IP on Container Apps
- All traffic flows through App Gateway

### Identity & Access
- Managed Identity for ACR authentication
- No secrets or passwords in configuration
- Azure RBAC for resource access

## 🛠️ Deployment Scripts

### PowerShell

**Full Deployment**:
```powershell
.\scripts\deploy.ps1 -ResourceGroupName rg-aca-demo -Location westus3
```

**Build & Push**:
```powershell
.\scripts\build-and-push.ps1 -ResourceGroupName rg-aca-demo -ImageTag v2
```

**Cleanup**:
```powershell
.\scripts\cleanup.ps1 -ResourceGroupName rg-aca-demo
```

### Bash

**Full Deployment**:
```bash
./scripts/deploy.sh rg-aca-demo westus3
```

**Build & Push**:
```bash
./scripts/build-and-push.sh rg-aca-demo v2
```

**Cleanup**:
```bash
./scripts/cleanup.sh rg-aca-demo
```

## 🎨 Application Features

The demo web application showcases:

- **Live Container Metrics**: Hostname, uptime, memory usage
- **Request Headers**: X-Forwarded-For, X-Forwarded-Proto, User-Agent
- **Modern UI**: Glass-morphism design with animated gradients
- **Health Endpoint**: `/health` for App Gateway probes

## 📊 Monitoring

View Container App logs:
```bash
az containerapp logs show \
  --name ca-demo-webapp \
  --resource-group rg-aca-demo \
  --follow
```

Check Application Gateway backend health:
```bash
az network application-gateway show-backend-health \
  --name appgw-demo \
  --resource-group rg-aca-demo
```

## 🔄 Updating the Application

```bash
# Make changes to app/server.js
# Build new version
az acr build --registry <acr-name> --image demo-webapp:v2 ./app

# Deploy new version
az containerapp update \
  --name ca-demo-webapp \
  --resource-group rg-aca-demo \
  --image <acr-name>.azurecr.io/demo-webapp:v2
```

Container Apps creates a new revision and switches traffic automatically.

## 🐛 Troubleshooting

### App Gateway shows unhealthy backend
```bash
# Check Container App is running
az containerapp show --name ca-demo-webapp --resource-group rg-aca-demo --query properties.runningStatus

# Verify health endpoint responds
az containerapp exec --name ca-demo-webapp --resource-group rg-aca-demo --command "wget -O- http://localhost:3000/health"
```

### ACR build fails with access denied
**Error**: `denied: client with IP 'x.x.x.x' is not allowed access`

**Cause**: ACR Tasks build agents run outside your VNET and need public network access.

**Solution**:
```bash
# Enable public access and allow all IPs (required for ACR Tasks)
az acr update --name <acr-name> --public-network-enabled true --default-action Allow
```

**Note**: Container Apps still pulls images securely via the private endpoint. Public access is only needed for builds.

### Container App won't pull image
```bash
# Verify managed identity has AcrPull role
az role assignment list --assignee <managed-identity-id> --scope /subscriptions/<sub-id>/resourceGroups/rg-aca-demo
```

## 📚 Learn More

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Application Gateway WAF](https://learn.microsoft.com/azure/web-application-firewall/ag/ag-overview)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)

## 📝 License

MIT License - feel free to use this for your own projects!

---

**Built with** ☁️ Azure Container Apps • 🛡️ Application Gateway WAF •  Bicep
