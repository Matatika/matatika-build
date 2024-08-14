param environmentId string
param logAnalyticsWorkspaceId string
param location string
param customDomainName string = ''
param managedCertificateId string = ''
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

param logstashEndpoint string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'catalog-${uniqueString(environmentId)}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: true  // https://github.com/microsoft/azure-container-apps/discussions/1033#discussioncomment-7997192
        targetPort: 8080
        customDomains: empty(customDomainName)
          ? null
          : [
            {
              name: customDomainName
              bindingType: empty(managedCertificateId) ? 'Disabled' : 'SniEnabled'
              certificateId: empty(managedCertificateId) ? null : managedCertificateId
            }
          ]
      }
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
          name: 'application-properties'
          value: loadTextContent('../config/catalog/application.properties')
        }
        {
          name: 'shelltask-secrets'
          value: string([
            {
              name: 'container-registry-password'
              value: containerRegistry.listCredentials().passwords[0].value
            }
          ])
        }
        {
          name: 'shelltask-environment'
          value: join([
            'JAVA_OPTS=${javaOpts}'
            'MATATIKA_ENCRYPTOR_PASSWORD=${encryptorPassword}'
            'MATATIKA_LOGSTASH_ENDPOINT=${logstashEndpoint}'
          ], ',')
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
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
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
          image: '${containerRegistry.properties.loginServer}/matatika-catalog:latest-dev'
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
              name: 'ELASTICSEARCH_ENABLED'
              value: 'false'
            }
            {
              name: 'MATATIKA_LOGSTASH_ENDPOINT'
              value: logstashEndpoint
            }
            {
              name: 'AZURE_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            {
              name: 'SPRING_CLOUD_CONTAINERAPPS_ENABLED'
              value: 'true'
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_ENVIRONMENT'
              value: environmentId
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_RESOURCEGROUP'
              value: resourceGroup().name
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_LOCATION'
              value: location
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_LOGANALYTICSWORKSPACEID'
              value: logAnalyticsWorkspaceId
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_SECRETS'
              secretRef: 'shelltask-secrets'
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_REGISTRIES'
              value: string([
                {
                  server: containerRegistry.properties.loginServer
                  username: containerRegistry.name
                  passwordSecretRef: 'container-registry-password'
                }
              ])
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_ENVIRONMENTVARIABLES'
              secretRef: 'shelltask-environment' 
            }
            ...empty(customDomainName)
              ? []
              : [
                {
                  name: 'APP_URL'
                  value: 'https://${customDomainName}'
                }
                {
                  name: 'CATALOG_URL'
                  value: 'https://${customDomainName}/api'
                }
                {
                  name: 'CATALOG_ALLOWED_ORIGINS'
                  value: 'https://${customDomainName}'
                }
                {
                  name: 'AUTH0_CLIENT_AUDIENCE'
                  value: 'https://${customDomainName}/api'
                }
                {
                  name: 'AUTH0_RESULTURL'
                  value: 'https://${customDomainName}'
                }
                {
                  name: 'APP_SERVER_URI'
                  value: 'https://${customDomainName}/api'
                }
              ]
          ]
        }
      ]
    }
  }
}

resource containerappsTaskPlatformRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid('containerapps-task-platform')
  properties: {
    roleName: 'ContainerApps Task Platform'
    description: 'ContainerApps task platform for Spring Cloud Data Flow'
    assignableScopes: [resourceGroup().id]
    permissions: [
      {
        actions: [
          'microsoft.app/jobs/*'
          'microsoft.app/managedenvironments/join/action'
          'Microsoft.OperationalInsights/*/read'
        ]
      }
    ]
  }
}

resource catalogRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('catalog-role-assignment')
  properties: {
    principalId: app.identity.principalId
    roleDefinitionId: containerappsTaskPlatformRole.id
  }
}

output containerName string = app.properties.template.containers[0].name
