targetScope='subscription'

// references
@description('Application name')
param appName string = 'whitepaper03'
@description('location for aks cluster')
param location string = 'japaneast'
param rgName string = 'rg-${appName}'
param randomStr string

// Network Settings
param virtualNetworkName string = 'Vnet'
param AKSsubnetName string = 'AksSubnet'
param DBsubnetName string = 'DbSubnet'
param ACRsubnetName string = 'AcrSubnet'
param KVsubnetName string = 'KvSubnet'
param VMsubnetName string = 'VMSubnet'
param addressPrefix string = '192.168.0.0/16'
param AKSsubnetPrefix string = '192.168.0.0/24'
param DBsubnetPrefix string = '192.168.1.0/24'
param ACRsubnetPrefix string = '192.168.2.0/24'
param KVsubnetPrefix string = '192.168.3.0/24'
param VMsubnetPrefix string = '192.168.254.0/24'

// VM Settings
param virtualMachineName string = '${appName}-vm'
@secure()
param sshPublicKey string

// AKS Settings
param clusterName string = '${appName}-aks'
param agentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
@description('Enable Private Cluster')
param PrivateCluster bool = true

// DB Settings
param databaseName string = '${appName}-db-${randomStr}'
param administratorLogin string = 'spring'
param administratorLoginPassword string = 'ThisIsTest#123'

// ACR Settings
param acrName string = '${appName}acr${randomStr}'

// Key Vault Settings
param keyvaultName string = '${appName}-kv-${randomStr}'
param clientIpAddress string
param userObjectId string

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: location
}

module vnet 'modules/network.bicep' = {
  name: '${virtualNetworkName}-deploy'
  scope: rg
  params: {
    virtualNetworkName: virtualNetworkName
    location: location
    addressPrefix: addressPrefix
    AKSsubnetName: AKSsubnetName
    AKSsubnetPrefix: AKSsubnetPrefix
    DBsubnetName: DBsubnetName
    DBsubnetPrefix: DBsubnetPrefix
    ACRsubnetName: ACRsubnetName
    ACRsubnetPrefix: ACRsubnetPrefix
    KVsubnetName: KVsubnetName
    KVsubnetPrefix: KVsubnetPrefix
    VMsubnetName: VMsubnetName
    VMsubnetPrefix: VMsubnetPrefix
  }
}


module vm 'modules/linux-vm.bicep' = {
  name: '${virtualMachineName}-deploy'
  scope: rg
  params: {
    virtualMachineName: virtualMachineName
    location: location
    virtualNetworkName: virtualNetworkName
    subnetName: VMsubnetName
    sshPublicKey: sshPublicKey
  }
  dependsOn: [
    vnet
  ]
}

module aks 'modules/aks.bicep' = {
  name: '${clusterName}-deploy'
  scope: rg
  params: {
    clusterName: clusterName
    location: location
    virtualNetworkName: virtualNetworkName
    AKSsubnetName: AKSsubnetName
    agentCount: agentCount
    agentVMSize: agentVMSize
    PrivateCluster: PrivateCluster
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    vnet
    vm
  ]
}


resource aksworkerrg 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: 'MC_${rgName}_${clusterName}_${location}'
}

module md_id 'modules/md_id.bicep' = {
  name: '${clusterName}-managed-id-for-keyvault'
  scope: aksworkerrg
  params: {
    clusterName: clusterName
  }
  dependsOn: [
    aks
  ]
}

module db 'modules/postgresql.bicep' = {
  name: '${databaseName}-deploy' 
  scope: rg
  params: {
    databaseName: databaseName
    location: location
    virtualNetworkName: virtualNetworkName
    subnetName: DBsubnetName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  dependsOn: [
    vnet
  ]
}

module acr 'modules/acr.bicep' = {
  name: '${acrName}-deploy'
  scope: rg
  params: {
    acrName: acrName
    location: location
    virtualNetworkName: virtualNetworkName
    subnetName: ACRsubnetName
    clusterName: clusterName
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    vnet
    aks
  ]
}

module keyvault 'modules/keyvault.bicep' = {
  name: '${keyvaultName}-deploy'
  scope: rg
  params: {
    keyvaultName: keyvaultName
    location: location
    virtualNetworkName: virtualNetworkName
    subnetName: KVsubnetName
    clientIpAddress: clientIpAddress
    managedIdForKeyVault: md_id.outputs.principalIdForKeyVault
    virtualMachineName: virtualMachineName
    userObjectId: userObjectId
  }
  dependsOn: [
    vnet
    md_id
  ]
}

output sshCommand string = vm.outputs.sshCommand
output aksGetCredentialsCommand string = 'az aks get-credentials -g ${rgName} -n ${clusterName}'
output ACRNAME string = acrName
output KEYVAULTNAME string = keyvaultName
output DATABASENAME string = databaseName
output MANAGEDID string = md_id.outputs.managedIdForSecretStoreCsiDriver
output TENANTID string = az.tenant().tenantId
