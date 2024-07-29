param environmentId string
param location string
param containerRegistryName string
param reactAppEnv string
param javaOpts string
param activeProfiles string
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
param elasticsearchUser string

@secure()
param elasticsearchPassword string

param logstashEndpoint string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'catalog'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        {
          name: 'persistence-warehouse-pass'
          value: persistenceWarehousePassword
        }
        {
          name: 'persistence-catalog-pass'
          value: persistenceCatalogPassword
        }
        {
          name: 'encryptor-pass'
          value: encryptorPassword
        }
        {
          name: 'auth0-client-secret'
          value: auth0ClientSecret
        }
        {
          name: 'github-api-private-key'
          value: githubApiPrivateKey
        }
        {
          name: 'github-api-workspaces-private-key'
          value: githubApiWorkspacesPrivateKey
        }
        {
          name: 'es-elastic-pass'
          value: elasticsearchPassword
        }
        {
          name: 'application-properties'
          value: loadTextContent('../config/catalog/application.properties')
        }
      ]
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.name
          passwordSecretRef: 'container-registry-password'
        }
      ]
    }
    template: {
      volumes: [
        {
          name: 'config'
          secrets: [
            {
              path: 'application-deploy.properties'
              secretRef: 'application-properties'
            }
          ]
          storageType: 'Secret'  // https://learn.microsoft.com/en-gb/azure/container-apps/manage-secrets?tabs=arm-template#secrets-volume-mounts
        }
      ]
      containers: [
        {
          name: 'catalog'
          image: '${containerRegistry.properties.loginServer}/matatika-catalog:latest'
          resources: {
            cpu: 2
            memory: '4Gi'
          }
          volumeMounts: [
            {
              volumeName: 'config'
              mountPath: '/config/application-deploy.properties'
              subPath: 'application-deploy.properties'
            }
          ]
          env: [
            {
              name: 'REACT_APP_ENV'
              value: reactAppEnv
            }
            {
              name: 'JAVA_OPTS'
              value: javaOpts
            }
            {
              name: 'ACTIVE_PROFILES'
              value: activeProfiles
            }
            {
              name: 'PERSISTENCE_WAREHOUSE_URL'
              value: persistenceWarehouseUrl
            }
            {
              name: 'PERSISTENCE_WAREHOUSE_USERNAME'
              value: persistenceWarehouseUsername
            }
            {
              name: 'PERSISTENCE_WAREHOUSE_PASSWORD'
              secretRef: 'persistence-warehouse-pass'
            }
            {
              name: 'PERSISTENCE_CATALOG_URL'
              value: persistenceCatalogUrl
            }
            {
              name: 'PERSISTENCE_CATALOG_USERNAME'
              value: persistenceCatalogUsername
            }
            {
              name: 'PERSISTENCE_CATALOG_PASSWORD'
              secretRef: 'persistence-catalog-pass'
            }
            {
              name: 'MATATIKA_ENCRYPTOR_PASSWORD'
              secretRef: 'encryptor-pass'
            }
            {
              name: 'AUTH0_CLIENT_SECRET'
              secretRef: 'auth0-client-secret'
            }
            {
              name: 'GITHUB_API_PRIVATE_KEY'
              secretRef: 'github-api-private-key'
            }
            {
              name: 'GITHUB_API_WORKSPACES_PRIVATE_KEY'
              secretRef: 'github-api-workspaces-private-key'
            }
            {
              name: 'ELASTICSEARCH_HOST'
              value: elasticsearchHost
            }
            {
              name: 'ELASTICSEARCH_USER'
              value: elasticsearchUser
            }
            {
              name: 'ELASTICSEARCH_PASSWORD'
              secretRef: 'es-elastic-pass'
            }
            {
              name: 'MATATIKA_LOGSTASH_ENDPOINT'
              value: logstashEndpoint
            }
          ]
        }
      ]
    }
  }
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/containers#acrpull
resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('acrpull-role-assignment')
  properties: {
    principalId: app.identity.principalId
    roleDefinitionId: acrPullRoleDefinition.id
  }
}
