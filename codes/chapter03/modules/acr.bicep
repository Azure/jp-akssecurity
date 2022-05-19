param acrName string
param location string
param virtualNetworkName string
param subnetName string
param sku string = 'Premium'

param clusterName string
param virtualMachineName string

var roleAcrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var roleAcrPush = '8311e382-0749-4cb8-b61a-304f252e45ec'

// query network resources
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}


// declare Private DNS Zone
resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

// declare DNS Zone VNet link
resource dnszonelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnszone.name}-link' 
  location: 'global'
  parent: dnszone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    networkRuleSet: {
      defaultAction: 'Deny'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'None'
  }
}

resource endpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${acrName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${acrName}-plink'
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: acr.id
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
  }
}

resource endpointdnszone 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${acrName}-pe-dnszone'
  parent: endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.azurecr.io'
        properties: {
          privateDnsZoneId: dnszone.id
        }
      }
    ]
  }
  dependsOn: [
    dnszonelink
  ]
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' existing = {
  name: clusterName
}

resource acr_pull_aks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, aks.id, 'AssignAcrPullToAks')
  scope: acr
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aks.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleAcrPull}'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' existing = {
  name: virtualMachineName
}

resource acr_push_vm 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, vm.id, 'AssignAcrPushToVm')
  scope: acr
  properties: {
    description: 'Assign AcrPush role to VM'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleAcrPush}'
  }
}
output loginCommand string = 'az acr login --name ${acr.name}'
