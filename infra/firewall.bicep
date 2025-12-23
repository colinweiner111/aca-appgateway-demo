targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string

@description('Firewall name')
param firewallName string = 'afw-premium'

@description('Firewall subnet ID')
param firewallSubnetId string

@description('Environment name')
param environmentName string = 'demo'

// Public IP for Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'pip-${firewallName}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Firewall Policy for Premium tier
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-05-01' = {
  name: 'afwp-${environmentName}'
  location: location
  properties: {
    sku: {
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    intrusionDetection: {
      mode: 'Alert'
      configuration: {
        signatureOverrides: []
        bypassTrafficSettings: []
      }
    }
    dnsSettings: {
      enableProxy: true
    }
  }
}

// Network rule collection group
resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AzureContainerAppsNetwork'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowMCRCDN'
            description: 'Allow Microsoft Container Registry CDN'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            destinationAddresses: [
              'AzureFrontDoor.FirstParty'
            ]
            destinationPorts: [
              '443'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowAzureMonitor'
            description: 'Allow Azure Monitor'
            ipProtocols: [
              'TCP'
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            destinationAddresses: [
              'AzureMonitor'
            ]
            destinationPorts: [
              '443'
            ]
          }
          {
            ruleType: 'NetworkRule'
            name: 'AllowNTP'
            description: 'Allow NTP time sync'
            ipProtocols: [
              'UDP'
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            destinationFqdns: [
              'ntp.ubuntu.com'
            ]
            destinationPorts: [
              '123'
            ]
          }
        ]
      }
    ]
  }
}

// Application rule collection group
resource applicationRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-05-01' = {
  parent: firewallPolicy
  name: 'DefaultApplicationRuleCollectionGroup'
  properties: {
    priority: 300
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'AzureContainerAppsApplication'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'AllowMCR'
            description: 'Allow Microsoft Container Registry'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            targetFqdns: [
              'mcr.microsoft.com'
              '*.data.mcr.microsoft.com'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowDockerHub'
            description: 'Allow Docker Hub for base images'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            targetFqdns: [
              'docker.io'
              'registry-1.docker.io'
              'production.cloudflare.docker.com'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowACR'
            description: 'Allow Azure Container Registry'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            targetFqdns: [
              '*.azurecr.io'
              '*.blob.core.windows.net'
            ]
          }
          {
            ruleType: 'ApplicationRule'
            name: 'AllowAzureManagement'
            description: 'Allow Azure management endpoints'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.0.0.0/16'
            ]
            targetFqdns: [
              'management.azure.com'
              'login.microsoftonline.com'
            ]
          }
        ]
      }
    ]
  }
  dependsOn: [
    networkRuleCollectionGroup
  ]
}

// Azure Firewall Premium
resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Premium'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'firewallIpConfig'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIP.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
  dependsOn: [
    applicationRuleCollectionGroup
    networkRuleCollectionGroup
  ]
}

output firewallPrivateIP string = firewall.properties.ipConfigurations[0].properties.privateIPAddress
output firewallPublicIP string = firewallPublicIP.properties.ipAddress
output firewallPolicyId string = firewallPolicy.id
output firewallId string = firewall.id
output firewallName string = firewall.name
