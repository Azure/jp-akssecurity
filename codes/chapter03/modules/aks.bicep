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
param agentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('Enable Private Cluster')
param PrivateCluster bool = false
param serviceCidr string = ''
param dnsServcieIP string = ''
param dockerBridgeCidr string = ''

param virtualMachineName string

var roleContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource aks_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${virtualNetworkName}/${AKSsubnetName}'
}

var apiServerAccessProfile = PrivateCluster ? {
  authorizedIPRanges: []
  disableRunCommand: true
  enablePrivateCluster: true
  enablePrivateClusterPublicFQDN: false
  privateDNSZone: 'system'
} : {}

// declare Azure kubernetes service
resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: false
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: defaultAgentPoolName
        count: agentCount
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
    addonProfiles:  {
      azureKeyvaultSecretsProvider: {
       enabled: true
      }
    }
    apiServerAccessProfile: apiServerAccessProfile
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' existing = {
  name: virtualMachineName
}

resource contributor_vm 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, clusterName, vm.id, 'AssignContributorToVm')
  scope: aks
  properties: {
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleContributor}'
  }
}
