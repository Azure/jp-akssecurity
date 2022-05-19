targetScope='subscription'

// references
@description('Application name')
param appName string = 'whitepaper04'
@description('location for aks cluster')
param location string = 'japaneast'
param rgName string = 'rg-${appName}'
param randomStr string

// Network Settings
param virtualNetworkName string = 'Vnet'
param AKSsubnetName string = 'AksSubnet'
param addressPrefix string = '192.168.0.0/16'
param AKSsubnetPrefix string = '192.168.0.0/24'

// AKS Settings
param clusterName string = '${appName}-aks'
param AgentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
var clusterEnvList = [
  'stg'
  'prd'
]

// Managed ID Settings
param managedIdName string = guid(clusterName)

// ACR Settings
param acrName string = 'acr${randomStr}'
var acrEnvList = [
  'review'
  'prod'
]

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: location
}

module md_id 'modules/md_id.bicep' = {
  name: 'aks-managed_id-deploy'
  scope: rg
  params: {
    location: location
    managedIdName: managedIdName
  }
}

module vnet 'modules/network.bicep' = [for clusterEnv in clusterEnvList: {
  name: '${virtualNetworkName}-${clusterEnv}-deploy'
  scope: rg
  params: {
    virtualNetworkName: '${virtualNetworkName}-${clusterEnv}'
    location: location
    addressPrefix: addressPrefix
    AKSsubnetName: AKSsubnetName
    AKSsubnetPrefix: AKSsubnetPrefix
  }
}]

module aks 'modules/aks.bicep' = [for clusterEnv in clusterEnvList:{
  name: '${clusterName}-${clusterEnv}-deploy'
  scope: rg
  params: {
    clusterName: '${clusterName}-${clusterEnv}'
    location: location
    virtualNetworkName: '${virtualNetworkName}-${clusterEnv}'
    AKSsubnetName: AKSsubnetName
    AgentCount: AgentCount
    agentVMSize: agentVMSize
    managedIdName: managedIdName
  }
  dependsOn: [
    vnet
    md_id
  ]
}]

module acr 'modules/acr.bicep' = [ for acrEnv in acrEnvList:{
  name: '${acrName}${acrEnv}-deploy'
  scope: rg
  params: {
    acrName: '${acrName}${acrEnv}'
    location: location
  }
}]

module acr_prd_pull 'modules/acr_pull.bicep' = [ for clusterEnv in clusterEnvList: {
  name: '${acrName}prod-${clusterEnv}-pull-deploy'
  scope: rg
  params: {
    acrName: '${acrName}prod'
    clusterName: '${clusterName}-${clusterEnv}'
  }
  dependsOn: [
    acr
    aks
  ]
}]

output aksNameStg string = '${clusterName}-${clusterEnvList[0]}'
output aksNamePro string = '${clusterName}-${clusterEnvList[1]}'
output acrNameReview string = '${acrName}${acrEnvList[0]}'
output acrNamePro string = '${acrName}${acrEnvList[1]}'
output sucscriptionID string = az.subscription().subscriptionId
output rgName string = rgName
