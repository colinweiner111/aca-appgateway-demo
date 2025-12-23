targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string

@description('Route table name')
param routeTableName string = 'rt-firewall'

@description('Azure Firewall private IP address')
param firewallPrivateIP string

@description('Container Apps subnet ID')
param containerAppsSubnetId string

@description('App Gateway subnet ID')
param appGatewaySubnetId string

// Route Table - Only for Container Apps subnet
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIP
        }
      }
    ]
  }
}

// Get the VNET from the subnet ID to update it
var vnetName = split(containerAppsSubnetId, '/')[8]

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

// Update Container Apps subnet with route table
resource containerAppsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' = {
  parent: vnet
  name: 'snet-container-apps'
  properties: {
    addressPrefix: '10.0.0.0/23'
    delegations: [
      {
        name: 'delegateToContainerApps'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
    routeTable: {
      id: routeTable.id
    }
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

output routeTableId string = routeTable.id
output routeTableName string = routeTable.name
