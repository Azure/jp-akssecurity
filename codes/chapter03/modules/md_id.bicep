param clusterName string

resource md_id 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'azurekeyvaultsecretsprovider-${clusterName}'
}

output principalIdForKeyVault string = md_id.properties.principalId
output managedIdForSecretStoreCsiDriver string = md_id.properties.clientId
