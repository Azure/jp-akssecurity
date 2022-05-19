param keyvaultName string
param location string
param virtualNetworkName string
param subnetName string
param sku string = 'premium'
param clientIpAddress string

param managedIdForKeyVault string
param virtualMachineName string
param userObjectId string

var roleSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'
var roleSecretsOfficer = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'

// query network resources
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

// declare Private DNS Zone
resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
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

resource keyvault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvaultName
  location: location
  properties: {
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: clientIpAddress
        }
      ]
    }
    sku: {
      family: 'A'
      name: sku
    }
  }
}

resource endpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${keyvaultName}-pe'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${keyvaultName}-plink'
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyvault.id
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
  }
}

resource endpointdnszone 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${keyvaultName}-pe-dnszone'
  parent: endpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink.vaultcore.azure.net'
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

resource secrets_user_aks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, keyvaultName, managedIdForKeyVault, 'AssignSecretsUserToAks')
  scope: keyvault
  properties: {
    description: 'Assign Key Vault Secrets User role to AKS'
    principalId: managedIdForKeyVault
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleSecretsUser}'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' existing = {
  name: virtualMachineName
}

resource secrets_officer_vm 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, keyvaultName, vm.id, 'AssignSecretsOfficerToVM')
  scope: keyvault
  properties: {
    description: 'Assign Key Vault Secrets Officer role to VM'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleSecretsOfficer}'
  }
}

resource secrets_officer_user 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, keyvaultName, userObjectId, 'AssignSecretsOfficerToUser')
  scope: keyvault
  properties: {
    description: 'Assign Key Vault Secrets Officer role to User'
    principalId: userObjectId
    principalType: 'User'
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleSecretsOfficer}'
  }
}
