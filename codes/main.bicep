targetScope='subscription'

// references
@description('Application name')
param appName string = 'whitepaper'
@description('location for aks cluster')
param location string = 'japaneast'
param rgName string = 'rg-${appName}'

// Network Settings
param virtualNetworkName string = 'Vnet'
param AKSsubnetName string = 'AksSubnet'
param APPGWsubnetName string = 'AzureAppgwSubnet'
param FWsubnetName string = 'AzureFirewallSubnet'
param VMsubnetName string = 'VMSubnet'
param BastionsubnetName string = 'AzureBastionSubnet'
param addressPrefix string = '192.168.0.0/16'
param AKSsubnetPrefix string = '192.168.0.0/24'
param APPGWsubnetPrefix string = '192.168.1.0/24'
param FWsubnetPrefix string = '192.168.2.0/24'
param VMsubnetPrefix string = '192.168.254.0/24'
param BastionsubnetPrefix string= '192.168.255.0/24'

// VM Settings
param virtualMachineName string = '${appName}-vm'
@secure()
param sshPublicKey string

// AppGW Settings
param applicationGatewayName string = '${appName}-appgw'
param AppGWpublicIpAddressName string = '${appName}-pip-appgw'
param userAssignedIdentityName string = '${appName}-id-agw'
param privateIPAddress string = '192.168.1.254'

// Fireawall Settings
@description('Azure FireWall Name')
param firewallName string = '${appName}-fw'
param FWpublicIpAddressName string = '${appName}-pip-fw'

// AKS Settings
param clusterName string = '${appName}-aks'
param AgentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
@description('Enable Private Cluster')
param PrivateCluster bool = true

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: rgName
  location: location
}


module vnet 'modules/network.bicep' = {
  name: '${virtualNetworkName}-deploy'
  scope: rg
  params: {
    virtualNetworkName: virtualNetworkName
    addressPrefix: addressPrefix
    AKSsubnetName: AKSsubnetName
    APPGWsubnetName: APPGWsubnetName
    APPGWsubnetPrefix: APPGWsubnetPrefix
    FWsubnetName: FWsubnetName
    AKSsubnetPrefix: AKSsubnetPrefix
    FWsubnetPrefix: FWsubnetPrefix
    VMsubnetName: VMsubnetName
    VMsubnetPrefix: VMsubnetPrefix
    BastionsubnetName: BastionsubnetName
    BastionsubnetPrefix: BastionsubnetPrefix
    firewallName: firewallName
  }
}

// use Application Gateway module
module appgw 'modules/appgw.bicep' = {
  name: '${applicationGatewayName}-deploy'
  scope: rg
  params: {
    applicationGatewayName: applicationGatewayName
    virtualNetworkName: virtualNetworkName
    subnetName: APPGWsubnetName
    privateIPAddress: privateIPAddress
    publicIpAddressName: AppGWpublicIpAddressName
    userAssignedIdentityName: userAssignedIdentityName
    tier: 'Standard_v2'
    skuSize: 'Standard_v2'
  }
  dependsOn: [
    vnet
  ]
}

module vm 'modules/linux-vm.bicep' = {
  name: '${virtualMachineName}-deploy'
  scope: rg
  params: {
    virtualMachineName: virtualMachineName
    virtualNetworkName: virtualNetworkName
    subnetName: VMsubnetName
    sshPublicKey: sshPublicKey
  }
  dependsOn: [
    vnet
  ]
}

// use Azure Firewall module
module fw 'modules/firewall.bicep' = {
  name: '${firewallName}-deploy'
  scope: rg
  params: {
    firewallName: firewallName
    publicIpAddressName: FWpublicIpAddressName
    virtualNetworkName: virtualNetworkName
    subnetName: FWsubnetName
    sourceAddresses: AKSsubnetPrefix
    vmIp: vm.outputs.privateIp
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
    virtualNetworkName: virtualNetworkName
    AKSsubnetName: AKSsubnetName
    applicationGatewayName: applicationGatewayName
    userAssignedIdentityName: userAssignedIdentityName
    AgentCount: AgentCount
    agentVMSize: agentVMSize
    PrivateCluster: PrivateCluster
    applicationGatewayId: appgw.outputs.agw_id
  }
  dependsOn: [
    vnet
    appgw
  ]
}

output sshCommand string = fw.outputs.sshCommand
output aksGetCredentialsCommand string = 'az aks get-credentials -g ${rgName} -n ${clusterName}'
