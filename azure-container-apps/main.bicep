param deploymentNamePrefix string
param location string = resourceGroup().location
param containerRegistryConfig object = {
  // name: string?
  // resourceGroupName: string?
}
param imageConfig object = {
  name: 'matatika/catalog'
  tag: 'latest'
}
param managedCertificateExists bool = false
param catalogUserAssignedIdentityName string = ''
param customDomainName string = ''
param reactAppEnv string = 'production'
param appIdentityClientId string = ''
param javaOpts string = '-XX:MaxDirectMemorySize=128M -XX:MaxMetaspaceSize=240234K -XX:ReservedCodeCacheSize=240M -Xss1M -Xmx1079906K'
param activeProfiles string = 'default,deploy'
param persistenceCatalogUrl string = ''
param persistenceCatalogUsername string = ''

@secure()
param persistenceCatalogPassword string = ''

param persistenceWarehouseUrl string = persistenceCatalogUrl
param persistenceWarehouseUsername string = persistenceCatalogUsername

@secure()
param persistenceWarehousePassword string = persistenceCatalogPassword

@secure()
param encryptorPassword string

@secure()
param auth0ClientSecret string

@secure()
param githubApiPrivateKey string

@secure()
param githubApiWorkspacesPrivateKey string

@secure()
param oauthTrelloConsumerSecret string = ''

@secure()
param oauth2GoogleClientSecret string = ''

@secure()
param sendgridApiKey string = ''

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

resource managedCerficate 'Microsoft.App/managedEnvironments/managedCertificates@2024-03-01' existing = if (managedCertificateExists) {
  parent: appEnvironment
  name: customDomainName
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
    environmentName: appEnvironment.name
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.name
    location: location
    managedCertificateId: managedCertificateExists ? managedCerficate.id : ''
    customDomainName: managedCertificateExists ? managedCerficate.properties.subjectName : customDomainName
    userAssignedIdentityName: catalogUserAssignedIdentityName
    containerRegistryConfig: containerRegistryConfig
    imageConfig: imageConfig
    reactAppEnv: reactAppEnv
    appIdentityClientId: appIdentityClientId
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
    oauthTrelloConsumerSecret: oauthTrelloConsumerSecret
    oauth2GoogleClientSecret: oauth2GoogleClientSecret
    sendgridApiKey: sendgridApiKey
    logstashEndpoint: '${logstash.outputs.containerName}:5000'
  }
}

output deploymentName string = deploymentName
output cname string = '${catalog.outputs.containerName}.${appEnvironment.properties.defaultDomain}'
output txt string = appEnvironment.properties.customDomainConfiguration.customDomainVerificationId
