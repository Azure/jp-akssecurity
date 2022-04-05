param location string = resourceGroup().location
param virtualNetworkName string = 'Vnet'
param AKSsubnetName string = 'AksSubnet'
param applicationGatewayName string
param userAssignedIdentityName string

// AKS Settings
param clusterName string
param kubernetesVersion string = '1.20.9'
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
param PrivateCluster bool = false
param serviceCidr string = ''
param dnsServcieIP string = ''
param dockerBridgeCidr string = ''
param applicationGatewayId string


// declare subnet for AKS with routing to Azure Firewall
resource aks_subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' existing = {
  name: '${virtualNetworkName}/${AKSsubnetName}'
}

// query Application Gateway
resource agw 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  name: applicationGatewayName
}
// query Application Gateway User Assigned Identity
resource applicationGatewayUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedIdentityName
}

// declare Settings for Azure kubernetes service
var ingressApplicationGateway = empty(applicationGatewayName) ? {} : {
  ingressApplicationGateway: {
    enabled: true
    config: {
      applicationGatewayId: applicationGatewayId
      // effectiveApplicationGatewayId: agw.id
    }
  }
}
var addonProfiles = (ingressApplicationGateway)

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
    kubernetesVersion: kubernetesVersion
    enableRBAC: false
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
    addonProfiles: addonProfiles
    apiServerAccessProfile: apiServerAccessProfile
  }
}

// query General Built-in Role
var readerRoleObjectId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: readerRoleObjectId
  scope: subscription()
}
var contibutorRoleObjectId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: contibutorRoleObjectId
  scope: subscription()
}
var managedIdentityOperatorRoleObjectId = 'f1a07417-d97a-45cb-824c-7a7467783830'
resource managedIdentityOperatorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: managedIdentityOperatorRoleObjectId
  scope: subscription()
}

// Role for AGIC
resource agwContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(!empty(applicationGatewayName)) {
  name: guid(clusterName,applicationGatewayName,contibutorRoleObjectId)
  scope: agw
  properties: {
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    roleDefinitionId: contributorRoleDefinition.id
  }
}

resource rgReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(!empty(applicationGatewayName)) {
  name: guid(clusterName,applicationGatewayName,readerRoleObjectId)
  scope: resourceGroup()
  properties: {
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    roleDefinitionId: readerRoleDefinition.id
  }
}

resource agwManagedIdentityOperatorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = if(!empty(applicationGatewayName)) {
  name: guid(clusterName,userAssignedIdentityName,managedIdentityOperatorRoleObjectId)
  scope: applicationGatewayUserAssignedIdentity
  properties: {
    principalId: aks.properties.addonProfiles.ingressApplicationGateway.identity.objectId
    roleDefinitionId: managedIdentityOperatorRoleDefinition.id
  }
}
