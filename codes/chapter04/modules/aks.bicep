param virtualNetworkName string = 'Vnet'
param AKSsubnetName string = 'AksSubnet'

// AKS Settings
param clusterName string
param location string
param dnsPrefix string = clusterName
@minLength(1)
@maxLength(12)
param defaultAgentPoolName  string = 'defaultpool'
param availabilityZones array = []
@minValue(1)
@maxValue(50)
param AgentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('Enable Private Cluster')
param serviceCidr string = ''
param dnsServcieIP string = ''
param dockerBridgeCidr string = ''

param managedIdName string


resource aks_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${virtualNetworkName}/${AKSsubnetName}'
}

resource md_id 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdName
}

// declare Azure kubernetes service
resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${md_id.id}': {}
    }
  }
  properties: {
    enableRBAC: true
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: defaultAgentPoolName
        count: AgentCount
        osDiskSizeGB: osDiskSizeGB
        mode: 'System'
        vmSize: agentVMSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        enableAutoScaling: false
        availabilityZones: availabilityZones
        vnetSubnetID: empty(AKSsubnetName) ? json('null') : aks_subnet.id
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'  // use Azure CNI
      loadBalancerSku: 'standard'
      serviceCidr: empty(serviceCidr) ? json('null') : serviceCidr
      dnsServiceIP: empty((dnsServcieIP)) ? json ('null') : dnsServcieIP
      dockerBridgeCidr: empty(dockerBridgeCidr) ? json('null') : dockerBridgeCidr
    }
    addonProfiles: {
      azurepolicy: {
          enabled: true
          config: {
              version: 'v2'
          }
      }
    }
  }
}
