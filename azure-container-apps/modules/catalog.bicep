param environmentId string
param location string
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

param logstashEndpoint string

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'catalog'
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: [
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
          image: 'docker.io/matatika/catalog:latest'
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
              value: '-XX:MaxDirectMemorySize=64M -XX:MaxMetaspaceSize=240234K -XX:ReservedCodeCacheSize=240M -Xss1M -Xmx1079906K'
            }
            {
              name: 'ACTIVE_PROFILES'
              value: 'default,deploy'
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
              value: 'elastic'
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
