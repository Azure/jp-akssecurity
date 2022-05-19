// Network Settings
param virtualNetworkName string
param location string
param AKSsubnetName string
param DBsubnetName string
param ACRsubnetName string
param KVsubnetName string
param VMsubnetName string

param addressPrefix string
param AKSsubnetPrefix string
param DBsubnetPrefix string
param ACRsubnetPrefix string
param KVsubnetPrefix string
param VMsubnetPrefix string
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
      {
        name: DBsubnetName
        properties: {
          addressPrefix: DBsubnetPrefix
          delegations: [
            {
              name: 'Microsoft.DBforPostgreSQL.flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: ACRsubnetName
        properties: {
          addressPrefix: ACRsubnetPrefix
        }
      }
      {
        name: KVsubnetName
        properties: {
          addressPrefix: KVsubnetPrefix
        }
      }
      {
        name: VMsubnetName
        properties: {
          addressPrefix: VMsubnetPrefix
        }
      }
    ]
  }
}
