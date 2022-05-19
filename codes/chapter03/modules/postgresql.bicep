param databaseName string
param location string
param virtualNetworkName string
param subnetName string
param administratorLogin string
param administratorLoginPassword string
param skuName string = 'Standard_B1ms'
param skuTier string = 'Burstable'
param availabilityZone string = ''
param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param createMode string = 'Create'


// query network resources
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  name: '${virtualNetworkName}/${subnetName}'
}

// declare Private DNS Zone
resource dnszone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${databaseName}.private.postgres.database.azure.com'
  location: 'global'
}

// declare DNS Zone VNet link
resource dnszonelink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${databaseName}-link' 
  location: 'global'
  parent: dnszone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

 // declare Azure Database for PostgreSQL - Flexible Server
resource db 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: databaseName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    createMode: createMode
    network: {
      delegatedSubnetResourceId: subnet.id
      privateDnsZoneArmResourceId: dnszone.id
    }
    storage: {
      storageSizeGB: 32
    }
    version: '13'
  }
  dependsOn: [
    dnszonelink
  ]
}
