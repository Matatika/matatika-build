param containerAppEnvironmentPrefix string
param location string = resourceGroup().location
param reactAppEnv string
param persistenceWarehouseUrl string
param persistenceWarehouseUsername string

@secure()
param persistenceWarehousePassword string

param persistenceCatalogUrl string
param persistenceCatalogUsername string

@secure()
param persistenceCatalogPassword string

@secure()
param encryptorPassword string

@secure()
param auth0ClientSecret string

@secure()
param githubApiPrivateKey string

@secure()
param githubApiWorkspacesPrivateKey string

param elasticsearchHost string

@secure()
param elasticsearchPassword string

resource appEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: empty(containerAppEnvironmentPrefix) ? 'matatika' : '${containerAppEnvironmentPrefix}-matatika'
  location: location
  properties: {
    appLogsConfiguration: {}
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

module catalog 'modules/catalog.bicep' = {
  name: 'catalog'
  params: {
    environmentId: appEnvironment.id
    location: location
    reactAppEnv: reactAppEnv
    persistenceWarehouseUrl: persistenceWarehouseUrl
    persistenceWarehouseUsername: persistenceWarehouseUsername
    persistenceWarehousePassword: persistenceWarehousePassword
    persistenceCatalogUrl: persistenceCatalogUrl
    persistenceCatalogUsername: persistenceCatalogUsername
    persistenceCatalogPassword: persistenceCatalogPassword
    encryptorPassword: encryptorPassword
    auth0ClientSecret: auth0ClientSecret
    githubApiPrivateKey: githubApiPrivateKey
    githubApiWorkspacesPrivateKey: githubApiWorkspacesPrivateKey
    elasticsearchHost: elasticsearchHost
    elasticsearchPassword: elasticsearchPassword
    logstashEndpoint: '${logstash.outputs.containerName}:5000'
  }
}
