// Main Bicep template for Azure Deployment Environment (ADE)
// Provisions a managed database server with a selectable engine:
//   - Azure SQL Database
//   - Azure Database for PostgreSQL Flexible Server
//   - Azure Database for MySQL Flexible Server

@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('The database engine to deploy')
@allowed(['sqlserver', 'postgresql', 'mysql'])
param databaseEngine string = 'sqlserver'

@description('The service tier for the database server')
@allowed(['Basic', 'Standard', 'Premium'])
param skuTier string = 'Basic'

@description('The administrator login name for the database server')
param adminUsername string = 'sqladmin'

@description('The administrator password for the database server')
@secure()
param adminPassword string

// ── Naming ─────────────────────────────────────────────────────────────────
var uniqueSuffix = uniqueString(resourceGroup().id)
var serverName   = 'ade-db-${uniqueSuffix}'
var databaseName = 'ade-database'

// ── SKU maps ───────────────────────────────────────────────────────────────
// Azure SQL Database SKUs
var sqlSkuMap = {
  Basic:    { name: 'Basic', tier: 'Basic',    capacity: 5   }
  Standard: { name: 'S1',    tier: 'Standard', capacity: 20  }
  Premium:  { name: 'P1',    tier: 'Premium',  capacity: 125 }
}

// PostgreSQL Flexible Server SKUs
var postgresSkuMap = {
  Basic:    { name: 'Standard_B1ms',   tier: 'Burstable'       }
  Standard: { name: 'Standard_D2s_v3', tier: 'GeneralPurpose'  }
  Premium:  { name: 'Standard_D4s_v3', tier: 'GeneralPurpose'  }
}

// MySQL Flexible Server SKUs
var mysqlSkuMap = {
  Basic:    { name: 'Standard_B1ms',    tier: 'Burstable'       }
  Standard: { name: 'Standard_D2ds_v4', tier: 'GeneralPurpose'  }
  Premium:  { name: 'Standard_D4ds_v4', tier: 'GeneralPurpose'  }
}

// ── Azure SQL Database ─────────────────────────────────────────────────────
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = if (databaseEngine == 'sqlserver') {
  name: serverName
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = if (databaseEngine == 'sqlserver') {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name:     sqlSkuMap[skuTier].name
    tier:     sqlSkuMap[skuTier].tier
    capacity: sqlSkuMap[skuTier].capacity
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// Allows Azure-hosted services to reach the SQL server
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (databaseEngine == 'sqlserver') {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress:   '0.0.0.0'
  }
}

// ── Azure Database for PostgreSQL Flexible Server ──────────────────────────
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = if (databaseEngine == 'postgresql') {
  name: serverName
  location: location
  sku: {
    name: postgresSkuMap[skuTier].name
    tier: postgresSkuMap[skuTier].tier
  }
  properties: {
    administratorLogin:         adminUsername
    administratorLoginPassword: adminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup:  'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth:        'Enabled'
    }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = if (databaseEngine == 'postgresql') {
  parent: postgresServer
  name: databaseName
  properties: {
    charset:   'UTF8'
    collation: 'en_US.utf8'
  }
}

resource postgresFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = if (databaseEngine == 'postgresql') {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress:   '0.0.0.0'
  }
}

// ── Azure Database for MySQL Flexible Server ───────────────────────────────
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = if (databaseEngine == 'mysql') {
  name: serverName
  location: location
  sku: {
    name: mysqlSkuMap[skuTier].name
    tier: mysqlSkuMap[skuTier].tier
  }
  properties: {
    administratorLogin:         adminUsername
    administratorLoginPassword: adminPassword
    version: '8.0.21'
    storage: {
      storageSizeGB: 20
      autoGrow:      'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup:  'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource mysqlDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = if (databaseEngine == 'mysql') {
  parent: mysqlServer
  name: databaseName
  properties: {
    charset:   'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}

resource mysqlFirewallRule 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-06-30' = if (databaseEngine == 'mysql') {
  parent: mysqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress:   '0.0.0.0'
  }
}

// ── Outputs ────────────────────────────────────────────────────────────────
@description('The database engine that was deployed')
output deployedEngine string = databaseEngine

@description('The database server name')
output serverName string = serverName

@description('The database name')
output databaseName string = databaseName

@description('The connection hostname for the deployed server')
output connectionHost string = databaseEngine == 'sqlserver'
  ? '${serverName}.database.windows.net'
  : databaseEngine == 'postgresql'
      ? '${serverName}.postgres.database.azure.com'
      : '${serverName}.mysql.database.azure.com'

@description('The admin username')
output adminLogin string = adminUsername
