param location string
param managedIdName string
var roleNameGuid = guid(managedIdName)

resource md_id 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdName
  location: location
}

resource role 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: roleNameGuid
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalId: md_id.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
