# Azure Container Registry Private Endpoint DNS Configuration

## Overview

When using Azure Container Registry (ACR) with Private Endpoints and **public network access disabled**, you **must** configure **TWO private DNS zones** to ensure Container Apps can successfully pull images.

## The Two Endpoints Architecture

Azure Container Registry splits operations across two separate endpoints:

### 1. Control Plane Endpoint
- **FQDN Format**: `<registry>.azurecr.io`
- **Purpose**: Authentication, token exchange, manifest lookups, tag queries
- **Private DNS Zone**: `privatelink.azurecr.io`
- **Example**: `myregistry.azurecr.io` → resolves to `10.0.2.5` (private IP)

### 2. Data Plane Endpoint  
- **FQDN Format**: `<registry>.<region>.data.azurecr.io`
- **Purpose**: Downloading container image layers (blobs)
- **Private DNS Zone**: `privatelink.<region>.data.azurecr.io`
- **Example**: `myregistry.westus3.data.azurecr.io` → resolves to `10.0.2.4` (private IP)

## Why Both Zones Are Required

### Image Pull Flow

When Container Apps pulls an image from ACR:

```
1. ACA → myregistry.azurecr.io (control plane)
   ↓ Authentication successful
   ↓ Receives manifest with layer references
   
2. ACA → myregistry.westus3.data.azurecr.io (data plane)
   ↓ Downloads layer 1
   ↓ Downloads layer 2
   ↓ Downloads layer N
   
3. Image pull complete ✅
```

### What Happens Without the Data Zone

If `privatelink.<region>.data.azurecr.io` is missing:

```
1. ACA → myregistry.azurecr.io ✅
   ↓ Authentication works (control plane has DNS)
   ↓ Receives manifest
   
2. ACA → myregistry.westus3.data.azurecr.io ❌
   ↓ DNS lookup fails or resolves to PUBLIC IP
   ↓ Public endpoint is DISABLED
   ↓ Connection hangs/times out
   
3. Image pull FAILS or hangs indefinitely 🔴
```

**Symptoms:**
- `ImagePullBackOff` errors
- Container Apps revision stuck in "Provisioning" state
- Deployment timeouts after 10+ minutes
- Logs show: "Failed to pull image: context deadline exceeded"

## DNS Zone Configuration

### Zone 1: Control Plane

```bicep
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}
```

**Records Created** (auto-populated by Private Endpoint):
- `<registryname>` → A record → `10.0.2.5`

### Zone 2: Data Plane (Region-Specific)

```bicep
resource privateDnsZoneData 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${location}.data.azurecr.io'  // e.g., 'privatelink.westus3.data.azurecr.io'
  location: 'global'
}
```

**Records Created** (auto-populated by Private Endpoint):
- `<registryname>` → A record → `10.0.2.4`

### Private Endpoint DNS Zone Group

Both zones must be configured in the Private Endpoint's DNS zone group:

```bicep
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurecr-io'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
      {
        name: 'privatelink-data-azurecr-io'
        properties: {
          privateDnsZoneId: privateDnsZoneData.id
        }
      }
    ]
  }
}
```

## Verification Steps

### 1. Check DNS Zones Exist

```bash
RESOURCE_GROUP="rg-aca-demo"
LOCATION="westus3"

# Control plane zone
az network private-dns zone show \
  --resource-group $RESOURCE_GROUP \
  --name privatelink.azurecr.io

# Data plane zone
az network private-dns zone show \
  --resource-group $RESOURCE_GROUP \
  --name "privatelink.${LOCATION}.data.azurecr.io"
```

### 2. Verify VNET Links

```bash
# Both zones should be linked to your Container Apps VNET
az network private-dns link vnet list \
  --resource-group $RESOURCE_GROUP \
  --zone-name privatelink.azurecr.io

az network private-dns link vnet list \
  --resource-group $RESOURCE_GROUP \
  --zone-name "privatelink.${LOCATION}.data.azurecr.io"
```

### 3. Check DNS Records

```bash
ACR_NAME="<your-acr-name>"

# Control plane record
az network private-dns record-set a list \
  --resource-group $RESOURCE_GROUP \
  --zone-name privatelink.azurecr.io \
  --query "[?name=='${ACR_NAME}']"

# Data plane record
az network private-dns record-set a list \
  --resource-group $RESOURCE_GROUP \
  --zone-name "privatelink.${LOCATION}.data.azurecr.io" \
  --query "[?name=='${ACR_NAME}']"
```

**Expected Output**: Each query should show an A record with a private IP (10.0.x.x)

### 4. Test DNS Resolution (from within VNET)

If you have a test VM or Azure Bastion access in the same VNET:

```bash
ACR_NAME="<your-acr-name>"
LOCATION="westus3"

# Should resolve to private IP (10.0.2.x)
nslookup ${ACR_NAME}.azurecr.io

# Should also resolve to private IP (10.0.2.x)
nslookup ${ACR_NAME}.${LOCATION}.data.azurecr.io
```

**Success**: Both resolve to `10.0.x.x` addresses  
**Failure**: Public IP addresses or NXDOMAIN (zone missing)

## Troubleshooting

### Problem: Data plane zone not created

**Error during deployment:**
```
Error: InvalidPrivateDnsZoneConfiguration
The private endpoint does not have a valid DNS zone configuration.
```

**Solution**: Ensure `location` parameter is passed correctly to `acr-private-endpoint.bicep`

### Problem: DNS records not auto-populated

**Check:** Private endpoint's DNS zone group configuration

```bash
az network private-endpoint dns-zone-group show \
  --resource-group $RESOURCE_GROUP \
  --endpoint-name pe-<acrname> \
  --name default
```

Should show TWO `privateDnsZoneConfigs` entries.

### Problem: Container Apps still can't pull images

**Checklist:**
- ✅ Both DNS zones created
- ✅ Both zones linked to Container Apps VNET
- ✅ ACR has `dataEndpointEnabled: true`
- ✅ Container Apps managed identity has `AcrPull` role
- ✅ ACR public network access is `Disabled`
- ✅ Private endpoint is in same VNET as Container Apps

## References

- [Azure Container Registry Private Link Documentation](https://learn.microsoft.com/azure/container-registry/container-registry-private-link)
- [Azure Private Endpoint DNS Configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns)
- [Container Apps with Private ACR](https://learn.microsoft.com/azure/container-apps/managed-identity?tabs=portal%2Cdotnet#configure-registry-credentials)

## Common Misconceptions

### ❌ "One DNS zone is enough"
**Wrong.** You need both control and data plane zones.

### ❌ "The data zone will auto-create"
**Wrong.** Azure does not auto-create the region-specific data zone. You must explicitly configure it.

### ❌ "Public endpoint must be enabled"
**Wrong.** With proper DNS configuration, Container Apps can pull images with public access fully disabled (most secure).

### ❌ "This is only needed for geo-replication"
**Wrong.** Even single-region ACR deployments require both zones when using private endpoints with public network disabled.

## Best Practices

1. **Always configure both zones** when creating ACR private endpoints
2. **Set `dataEndpointEnabled: true`** on the ACR resource
3. **Link both zones to the VNET** hosting Container Apps
4. **Test DNS resolution** from within the VNET before deploying apps
5. **Document the zone names** (especially region-specific data zone) in your IaC
6. **For geo-replicated registries**, create additional data zones for each replica region

---

**Last Updated**: December 23, 2025  
**Tested With**: Azure Container Registry Premium, Container Apps (westus3)
