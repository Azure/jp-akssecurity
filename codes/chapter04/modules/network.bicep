// Network Settings
param virtualNetworkName string
param location string
param AKSsubnetName string

param addressPrefix string
param AKSsubnetPrefix string
param tags object = {}

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
        }
      }
    ]
  }
}

