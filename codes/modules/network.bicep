// Network Settings
param location string = resourceGroup().location
param virtualNetworkName string
param AKSsubnetName string
param APPGWsubnetName string
param FWsubnetName string
param VMsubnetName string
param BastionsubnetName string
param addressPrefix string
param AKSsubnetPrefix string
param APPGWsubnetPrefix string
param FWsubnetPrefix string
param VMsubnetPrefix string
param BastionsubnetPrefix string
param firewallName string
param tags object = {}

// declare RouteTable forwarding to Azure Firewall
resource RouteTable 'Microsoft.Network/routeTables@2021-03-01' = {
  name: '${firewallName}-RouteTable'
  location: location
  properties: {
    disableBgpRoutePropagation: true
  }
}

// declare Azure Virtual Network with some subnets
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: AKSsubnetName
        properties: {
          addressPrefix: AKSsubnetPrefix
          routeTable: {
            id: RouteTable.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: APPGWsubnetName
        properties: {
          addressPrefix: APPGWsubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: FWsubnetName
        properties: {
          addressPrefix: FWsubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: VMsubnetName
        properties: {
          addressPrefix: VMsubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: BastionsubnetName
        properties: {
          addressPrefix: BastionsubnetPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
