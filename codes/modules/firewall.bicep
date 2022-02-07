param firewallName string
param location string = resourceGroup().location
param publicIpAddressName string
param dnsLabelPrefix string = toLower('${publicIpAddressName}-${uniqueString(resourceGroup().id)}')
param virtualNetworkName string
param subnetName string
param sourceAddresses string
param TranslateSshPort string = '10022'
param vmIp string = ''

// query subnet for Azure Firewall
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

// declare Public IP Address for Azure Firewall
resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

var this = resourceId('Microsoft.Network/azureFirewalls', firewallName)

// declare Settings for Azure Firewall
var applicationRuleCollections = [
  {
    name: 'aksFirewallRules'
    id: '${this}/applicationRuleCollections/aksFirewallRules'
    properties: {
      priority: 100
      action: {
        type: 'Allow'
      }
      rules: [
        {
          name: 'aksFirewallRules'
          description: 'Rules needed for AKS to operate'
          sourceAddresses: [
            sourceAddresses
          ]
          protocols: [
            {
              protocolType: 'Https'
              port: 443
            }
            {
              protocolType: 'Http'
              port: 80
            }
          ]
          targetFqdns: [
            '*'
          ]
        }
      ]
    }
  }
]

var networkRuleCollections = [
  {
    name: 'ntpRule'
    id: '${this}/networkRuleCollections/ntpRule'
    properties: {
      priority: 100
      action: {
        type: 'Allow'
      }
      rules: [
        {
          name: 'ntpRule'
          description: 'Allow Ubuntu NTP for AKS'
          protocols: [
            'UDP'
          ]
          sourceAddresses: [
            sourceAddresses
          ]
          destinationAddresses: [
            '*'
          ]
          destinationPorts: [
            '123'
          ]
        }
      ]
    }
  }
]

var natRuleCollections = empty(vmIp) ? [] : [
  {
    name: 'VMssh'
    properties: {
      priority: 100
      action: {
        type: 'Dnat'
      }
      rules: [
        {
          name: 'VMssh'
          description: 'VMssh'
          protocols: [
            'TCP'
          ]
          sourceAddresses: [
            '*'
          ]
          destinationAddresses: [
            pip.properties.ipAddress
          ]
          destinationPorts: [
            TranslateSshPort
          ]
          translatedAddress: vmIp
          translatedPort: '22'
        }
      ]
    }
  }
]

// declare Azure Firewall
resource fw 'Microsoft.Network/azureFirewalls@2021-03-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'ipConfig1'
        id: '${this}/azureFirewallIpConfigurations/ipConfig1'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    applicationRuleCollections: applicationRuleCollections
    networkRuleCollections: networkRuleCollections
    natRuleCollections: natRuleCollections
  }
}

resource RouteTable 'Microsoft.Network/routeTables@2020-07-01' existing = {
  name: '${firewallName}-RouteTable'
}

resource defaultRoute 'Microsoft.Network/routeTables/routes@2021-03-01' = {
  name: 'defaultRoute'
  parent: RouteTable
  properties: {
    addressPrefix: '0.0.0.0/0'
    nextHopType: 'VirtualAppliance'
    nextHopIpAddress: fw.properties.ipConfigurations[0].properties.privateIPAddress
  }
}

output publicIp string = pip.properties.ipAddress
output sshCommand string = 'ssh -p ${TranslateSshPort} azureuser@${pip.properties.ipAddress}'
