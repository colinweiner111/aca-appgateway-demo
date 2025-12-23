# ACR Private Endpoint - Quick Reference Card

## 🎯 Two DNS Zones Required

```
┌──────────────────────────────────────────────────────────┐
│  ✅ privatelink.azurecr.io                               │
│     Purpose: Control plane (auth, manifests)            │
│                                                          │
│  ✅ privatelink.{region}.data.azurecr.io                │
│     Purpose: Data plane (image layers)                  │
└──────────────────────────────────────────────────────────┘
```

## 📋 Quick Checks

### 1. Verify Both Zones Exist
```bash
az network private-dns zone list -g <rg> --query "[?contains(name,'privatelink')].name"
```
✅ Should show BOTH zones

### 2. Test DNS Resolution (from VNET)
```bash
nslookup <acr>.azurecr.io                  # → 10.0.x.x
nslookup <acr>.<region>.data.azurecr.io    # → 10.0.x.x
```
✅ Both should resolve to private IPs

### 3. Check ACR Configuration
```bash
az acr show -n <acr> --query "dataEndpointEnabled"
```
✅ Should return: `true`

### 4. Verify Image Pull Works
```bash
az containerapp update --name <app> --image <acr>.azurecr.io/image:tag
```
✅ Should complete in < 60 seconds

## 🚨 Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `ImagePullBackOff` | Data DNS zone missing | Create `privatelink.<region>.data.azurecr.io` |
| `i/o timeout` | DNS resolves to public IP | Link data zone to VNET |
| Image pull hangs | `dataEndpointEnabled: false` | Set to `true` in ACR |

## 🔧 Bicep Checklist

```bicep
// ✅ ACR Configuration
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  properties: {
    dataEndpointEnabled: true              // Must be true
    publicNetworkAccess: 'Disabled'        // Recommended
  }
}

// ✅ Both DNS Zones
resource controlPlaneDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
}

resource dataPlaneDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${location}.data.azurecr.io'  // Region-specific!
}

// ✅ Both in DNS Zone Group
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  properties: {
    privateDnsZoneConfigs: [
      { privateDnsZoneId: controlPlaneDns.id }  // Control
      { privateDnsZoneId: dataPlaneDns.id }     // Data
    ]
  }
}
```

## 📖 Full Documentation

- **Detailed Guide**: [docs/ACR-PRIVATE-ENDPOINT-DNS.md](ACR-PRIVATE-ENDPOINT-DNS.md)
- **Flow Diagrams**: [docs/DNS-FLOW-DIAGRAM.md](DNS-FLOW-DIAGRAM.md)
- **Change Log**: [docs/CHANGES-2025-12-23.md](CHANGES-2025-12-23.md)

## 💡 Remember

**Without BOTH zones**: Container Apps can *authenticate* but cannot *download layers*  
**Result**: Indefinite hangs or timeouts

**With BOTH zones**: Full private connectivity, no public access needed  
**Result**: Fast, reliable image pulls ✅
