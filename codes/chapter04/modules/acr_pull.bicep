param acrName string
param clusterName string

var roleAcrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' existing = {
  name: clusterName
}

resource acr_pull_aks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, aks.id, 'AssignAcrPullToAks')
  scope: acr
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aks.properties.identityProfile.kubeletidentity.objectId //https://github.com/Azure/bicep/discussions/3181
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleAcrPull}'
  }
}
