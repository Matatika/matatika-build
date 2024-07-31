param deploymentNamePrefix string
param location string = resourceGroup().location
param containerRegistryName string
param reactAppEnv string
param javaOpts string
param activeProfiles string
param persistenceWarehouseUrl string = ''
param persistenceWarehouseUsername string = ''

@secure()
param persistenceWarehousePassword string = ''

param persistenceCatalogUrl string = ''
param persistenceCatalogUsername string = ''

@secure()
param persistenceCatalogPassword string = ''

@secure()
param encryptorPassword string

@secure()
param auth0ClientSecret string

@secure()
param githubApiPrivateKey string

@secure()
param githubApiWorkspacesPrivateKey string

param elasticsearchHost string
param elasticsearchUser string

@secure()
param elasticsearchPassword string

var deploymentName = empty(deploymentNamePrefix) ? 'matatika' : '${deploymentNamePrefix}-matatika'
var useManagedDb = empty(persistenceWarehouseUrl) && empty(persistenceCatalogUrl)

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: deploymentName
  location: location
}

resource appEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: deploymentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

module logstash 'modules/logstash.bicep' = {
  name: 'logstash'
  params: {
    environmentId: appEnvironment.id
    location: location
    elasticsearchHost: elasticsearchHost
    elasticsearchPassword: elasticsearchPassword
  }
}

module db 'modules/db.bicep' = if (useManagedDb) {
  name: 'db'
  params: {
    environmentId: appEnvironment.id
    location: location
  }
}

module catalog 'modules/catalog.bicep' = {
  name: 'catalog'
  params: {
    environmentId: appEnvironment.id
    location: location
    containerRegistryName: empty(containerRegistryName) ? 'matatika' : containerRegistryName
    reactAppEnv: reactAppEnv
    javaOpts: javaOpts
    activeProfiles: activeProfiles
    persistenceWarehouseUrl: useManagedDb ? db.outputs.jdbcUrl : persistenceWarehouseUrl
    persistenceWarehouseUsername: useManagedDb ? db.outputs.user : persistenceWarehouseUsername
    persistenceWarehousePassword: useManagedDb ? db.outputs.password : persistenceWarehousePassword
    persistenceCatalogUrl: useManagedDb ? db.outputs.jdbcUrl : persistenceCatalogUrl
    persistenceCatalogUsername: useManagedDb ? db.outputs.user : persistenceCatalogUsername
    persistenceCatalogPassword: useManagedDb ? db.outputs.password : persistenceCatalogPassword
    encryptorPassword: encryptorPassword
    auth0ClientSecret: auth0ClientSecret
    githubApiPrivateKey: githubApiPrivateKey
    githubApiWorkspacesPrivateKey: githubApiWorkspacesPrivateKey
    elasticsearchHost: elasticsearchHost
    elasticsearchUser: elasticsearchUser
    elasticsearchPassword: elasticsearchPassword
    logstashEndpoint: '${logstash.outputs.containerName}:5000'
  }
}
