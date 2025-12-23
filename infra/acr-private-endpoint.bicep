targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string

@description('Private endpoint name')
param privateEndpointName string

@description('ACR resource ID')
param acrId string

@description('Subnet ID for private endpoint')
param subnetId string

@description('VNET ID for private DNS zone')
param vnetId string

// Private Endpoint for ACR
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: acrId
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone for ACR - Control Plane
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

// Private DNS Zone for ACR - Data Plane (region-specific)
// This zone is REQUIRED for Container Apps to pull images when ACR public access is disabled
resource privateDnsZoneData 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${location}.data.azurecr.io'
  location: 'global'
}

// Link Control Plane DNS Zone to VNET
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateEndpointName}-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// Link Data Plane DNS Zone to VNET
resource privateDnsZoneDataLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZoneData
  name: '${privateEndpointName}-data-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// DNS Zone Group for automatic DNS registration
// This configures BOTH control plane and data plane endpoints
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

output privateEndpointId string = privateEndpoint.id
output privateDnsZoneId string = privateDnsZone.id
output privateDnsZoneDataId string = privateDnsZoneData.id
