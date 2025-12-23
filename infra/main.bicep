targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
param environmentName string = 'demo'

@description('Container Registry name')
param acrName string = 'acrccsf${uniqueString(resourceGroup().id)}'

@description('Container Apps Environment name')
param containerAppsEnvName string = 'cae-${environmentName}'

@description('Container App name')
param containerAppName string = 'ca-demo-webapp'

// Deploy Virtual Network (Container Apps)
module spokeVnet 'vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    location: location
    vnetName: 'vnet-containerapp-${environmentName}'
  }
}

// Deploy Azure Firewall Premium
module firewall 'firewall.bicep' = {
  name: 'firewall-deployment'
  params: {
    location: location
    firewallName: 'afw-${environmentName}'
    firewallSubnetId: spokeVnet.outputs.azureFirewallSubnetId
    environmentName: environmentName
  }
}

// Deploy Route Table (after firewall to get private IP)
module routeTable 'route-table.bicep' = {
  name: 'routetable-deployment'
  params: {
    location: location
    routeTableName: 'rt-${environmentName}'
    firewallPrivateIP: firewall.outputs.firewallPrivateIP
    containerAppsSubnetId: spokeVnet.outputs.containerAppsSubnetId
    appGatewaySubnetId: spokeVnet.outputs.appGatewaySubnetId
  }
  dependsOn: [
    spokeVnet
    firewall
  ]
}

// Deploy Azure Container Registry
module acr 'acr.bicep' = {
  name: 'acr-deployment'
  params: {
    location: location
    acrName: acrName
    privateEndpointSubnetId: spokeVnet.outputs.privateEndpointSubnetId
  }
}

// Deploy ACR Private Endpoint
module acrPrivateEndpoint 'acr-private-endpoint.bicep' = {
  name: 'acr-private-endpoint-deployment'
  params: {
    location: location
    privateEndpointName: 'pe-${acrName}'
    acrId: acr.outputs.acrId
    subnetId: spokeVnet.outputs.privateEndpointSubnetId
    vnetId: spokeVnet.outputs.vnetId
  }
}

// Deploy Container Apps Environment and App (after route table)
module containerApp 'container-app.bicep' = {
  name: 'containerapp-deployment'
  params: {
    location: location
    containerAppsEnvName: containerAppsEnvName
    containerAppName: containerAppName
    subnetId: spokeVnet.outputs.containerAppsSubnetId
    acrName: acr.outputs.acrName
    acrLoginServer: acr.outputs.acrLoginServer
  }
  dependsOn: [
    routeTable
  ]
}

// Deploy Application Gateway (after route table)
module appGateway 'appgateway.bicep' = {
  name: 'appgateway-deployment'
  params: {
    location: location
    vnetName: spokeVnet.outputs.vnetName
    appGatewaySubnetId: spokeVnet.outputs.appGatewaySubnetId
    backendFqdn: containerApp.outputs.containerAppFqdn
  }
  dependsOn: [
    routeTable
    containerApp
  ]
}

// Outputs
output containerAppUrl string = containerApp.outputs.containerAppFqdn
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output spokeVnetName string = spokeVnet.outputs.vnetName
output containerAppsEnvName string = containerApp.outputs.containerAppsEnvName
output appGatewayPublicIp string = appGateway.outputs.appGatewayPublicIp
output appGatewayFqdn string = appGateway.outputs.appGatewayFqdn
output firewallPrivateIP string = firewall.outputs.firewallPrivateIP
output firewallPublicIP string = firewall.outputs.firewallPublicIP
