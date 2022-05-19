param virtualMachineName string
param location string
param adminUserName string = 'azureuser'
param dnsLabelPrefix string = toLower('${virtualMachineName}-${uniqueString(resourceGroup().id)}')
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'
  '20.04-LTS'
])
@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
param ubuntuOSVersion string = '18.04-LTS'
param VmSize string = 'Standard_B1s'
param virtualNetworkName string
param subnetName string
param networkSecurityGroupName string = '${virtualMachineName}-nsg'
param sshPublicKey string
param tags object = {}

@description('Enable Public Address for VM')
param isPublic bool = true
param publicIpAddressName string = '${virtualMachineName}-pip'
param networkInterfaceName string = '${virtualMachineName}-nic'
param keyName string = '${virtualMachineName}-key'
param denyAccessViaSSH bool = false

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: denyAccessViaSSH ? json('null') : [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIpAddresses@2020-06-01' = if(isPublic) {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: !isPublic ? json('null'): {
            id: pip.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource sshKey 'Microsoft.Compute/sshPublicKeys@2020-12-01' = {
  name: keyName
  location: location
  properties: {
    publicKey: sshPublicKey
  }
  tags: tags
}

var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUserName}/.ssh/authorized_keys'
        keyData: sshKey.properties.publicKey
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUserName
      adminPassword: sshPublicKey
      linuxConfiguration: linuxConfiguration
      customData: 'I2Nsb3VkLWNvbmZpZwpwYWNrYWdlX3VwZ3JhZGU6IHRydWUKcGFja2FnZXM6CiAgLSBkb2NrZXIuaW8KdXNlcnM6CiAgLSBkZWZhdWx0CiAgLSBuYW1lOiBhenVyZXVzZXIKICAgIGdyb3VwczogZG9ja2VyCiAgICAK'
    }
  }
  tags: tags
}

output sshCommand string = 'ssh azureuser@${pip.properties.ipAddress}'
