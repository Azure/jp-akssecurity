param applicationGatewayName string
param location string = resourceGroup().location
@allowed([
  'Standard'
  'WAF'
  'Standard_v2'
  'WAF_v2'
])
@description('Standard_v1 does not support Ingress Controller for AKS')
param tier string = 'Standard_v2'
@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
  'WAF_Medium'
  'WAF_Large'
  'Standard_v2'
  'WAF_v2'
])
param skuSize string = 'Standard_v2'
@minValue(1)
@maxValue(125)
param capacity int = 2
param virtualNetworkName string
param subnetName string
@allowed([
  '1'
  '2'
  '3'
])
param zones array = []
param publicIpAddressName string
param privateIPAddress string
@allowed([
  'Dynamic'
  'Static'
])
param privateIPAllocationMethod string = 'Static'
param userAssignedIdentityName string
param dnsLabelPrefix string = toLower('${publicIpAddressName}-${uniqueString(subscription().subscriptionId)}')

// query subnet for Azure Application Gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

// declare Public IP Address for Azure Application Gateway
resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

var this = resourceId('Microsoft.Network/applicationGateways',applicationGatewayName)

// declare Azure Application Gateway User Assigned Identity
resource applicationGatewayUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = if(!empty(userAssignedIdentityName)) {
  name: userAssignedIdentityName
  location: location
}

// declare Azure Application Gateway
resource agw 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: applicationGatewayName
  location: location
  zones: zones
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationGatewayUserAssignedIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: skuSize
      tier: tier
      capacity: capacity
    }
    probes: [
      {
        name: 'defaultprobe-Http'
        properties: {
          host: 'localhost'
          interval: 30
          minServers: 0
          path: '/'
          pickHostNameFromBackendHttpSettings: false
          protocol: 'Http'
          timeout: 30
          unhealthyThreshold: 3
        }
      }
      {
        name: 'defaultprobe-Https'
        properties: {
          host: 'localhost'
          interval: 30
          minServers: 0
          path: '/'
          pickHostNameFromBackendHttpSettings: false
          protocol: 'Https'
          timeout: 30
          unhealthyThreshold: 3
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
      {
        name: 'appGwPrivateFrontendIp'
        properties: {
          privateIPAddress: privateIPAddress
          privateIPAllocationMethod: privateIPAllocationMethod
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultaddresspool'
        properties: {
          backendAddresses: []
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaulthttpsetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: 'fl-${uniqueString(subscription().subscriptionId)}'
        properties: {
          frontendIPConfiguration: {
            id: '${this}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${this}/frontendPorts/port_80'
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rr-${uniqueString(subscription().subscriptionId)}'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${this}/httpListeners/fl-${uniqueString(subscription().subscriptionId)}'
          }
          backendAddressPool: {
            id: '${this}/backendAddressPools/defaultaddresspool'
          }
          backendHttpSettings: {
            id: '${this}/backendHttpSettingsCollection/defaulthttpsetting'
          }
        }
      }
    ]
    enableHttp2: true
    sslCertificates: []
  }
}

output agw_id string = agw.id
