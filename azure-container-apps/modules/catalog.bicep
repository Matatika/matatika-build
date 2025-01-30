param environmentName string
param logAnalyticsWorkspaceName string
param location string
param customDomainName string = ''
param userAssignedIdentityName string = ''
param managedCertificateId string = ''
param containerRegistryConfig object = {
  // name: string?
  // resourceGroupName: string?
}
param imageConfig object = {
  name: 'matatika/catalog'
  tag: 'latest'
}
param containerAppName string = ''
param reactAppEnv string = 'production'
param appIdentityClientId string = ''
param javaOpts string = '-XX:MaxDirectMemorySize=64M -XX:MaxMetaspaceSize=240234K -XX:ReservedCodeCacheSize=240M -Xss1M -Xmx1079906K'
param activeProfiles string = 'default,deploy'
param persistenceCatalogUrl string = ''
param persistenceCatalogUsername string = ''

@secure()
param persistenceCatalogPassword string

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

param logstashEndpoint string = ''

var useUserAssignedIdentity = !empty(userAssignedIdentityName)
var useContainerRegistry = !empty(containerRegistryConfig)

resource environment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: environmentName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (useUserAssignedIdentity) {
  name: userAssignedIdentityName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (useContainerRegistry) {
  name: containerRegistryConfig.name
  scope: resourceGroup(!empty(containerRegistryConfig.resourceGroupName) ? containerRegistryConfig.resourceGroupName : resourceGroup().name)
}

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: !empty(containerAppName) ? containerAppName : 'catalog-${uniqueString(environment.id)}'
  location: location
  identity: {
    type: useUserAssignedIdentity ? 'UserAssigned' : 'SystemAssigned'
    ...useUserAssignedIdentity ? {
      userAssignedIdentities: {
        '${userAssignedIdentity.id}': {}
      }
    } : {}
  }
  properties: {
    managedEnvironmentId: environment.id
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
          value: useContainerRegistry ? containerRegistry.listCredentials().passwords[0].value : 'null'
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
          name: 'oauth-trello-consumer-secret'
          value: oauthTrelloConsumerSecret
        }
        {
          name: 'oauth2-google-client-secret'
          value: oauth2GoogleClientSecret
        }
        {
          name: 'sendgrid-api-key'
          value: sendgridApiKey
        }
        {
          name: 'application-properties'
          value: loadTextContent('../config/catalog/application.properties')
        }
        {
          name: 'shelltask-secrets'
          value: string([
            ...useContainerRegistry ? [
              {
                name: 'container-registry-password'
                value: containerRegistry.listCredentials().passwords[0].value
              }
            ] : []
          ])
        }
        {
          name: 'shelltask-environment'
          value: join([
            'JAVA_OPTS=${javaOpts}'
            'MATATIKA_ENCRYPTOR_PASSWORD=${encryptorPassword}'
            ...empty(logstashEndpoint)
              ? []
              : [
                'MATATIKA_LOGSTASH_ENDPOINT=${logstashEndpoint}'
              ]
          ], ',')
        }
      ]
      registries: [
        ...useContainerRegistry ? [
          {
            server: containerRegistry.properties.loginServer
            username: containerRegistry.name
            passwordSecretRef: 'container-registry-password'
          }
        ] : []
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
          image: useContainerRegistry ? '${containerRegistry.properties.loginServer}/${imageConfig.name}:${imageConfig.tag}' : 'docker.io/${imageConfig.name}:${imageConfig.tag}'
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
            ...empty(appIdentityClientId)
              ? []
              : [
                {
                  name: 'APP_IDENTITY_CLIENT_ID'
                  value: appIdentityClientId
                }
              ]
            {
              name: 'JAVA_OPTS'
              value: javaOpts
            }
            {
              name: 'ACTIVE_PROFILES'
              value: activeProfiles
            }
            ...empty(persistenceCatalogUrl)
              ? []
              : [
                {
                  name: 'PERSISTENCE_CATALOG_URL'
                  value: persistenceCatalogUrl
                }
              ]
            ...empty(persistenceCatalogUsername)
              ? []
              : [
                {
                  name: 'PERSISTENCE_CATALOG_USERNAME'
                  value: persistenceCatalogUsername
                }
              ]
            {
              name: 'PERSISTENCE_CATALOG_PASSWORD'
              secretRef: 'persistence-catalog-pass'
            }
            ...empty(persistenceWarehouseUrl)
              ? []
              : [
                {
                  name: 'PERSISTENCE_WAREHOUSE_URL'
                  value: persistenceWarehouseUrl
                }
              ]
            ...empty(persistenceWarehouseUsername)
              ? []
              : [
                {
                  name: 'PERSISTENCE_WAREHOUSE_USERNAME'
                  value: persistenceWarehouseUsername
                }
              ]
            {
              name: 'PERSISTENCE_WAREHOUSE_PASSWORD'
              secretRef: 'persistence-warehouse-pass'
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
            ...empty(oauthTrelloConsumerSecret)
              ? []
              : [
                {
                  name: 'OAUTH_TRELLO_CONSUMER_SECRET'
                  secretRef: 'oauth-trello-consumer-secret'
                }
              ]
            ...empty(oauth2GoogleClientSecret)
              ? []
              : [
                {
                  name: 'OAUTH2_GOOGLE_CLIENT_SECRET'
                  secretRef: 'oauth2-google-client-secret'
                }
              ]
            ...empty(sendgridApiKey)
              ? []
              : [
                {
                  name: 'SENDGRID_API_KEY'
                  secretRef: 'sendgrid-api-key'
                }
              ]
            {
              name: 'ELASTICSEARCH_ENABLED'
              value: 'false'
            }
            ...empty(logstashEndpoint)
              ? []
              : [
                {
                  name: 'MATATIKA_LOGSTASH_ENDPOINT'
                  value: logstashEndpoint
                }
              ]
            {
              name: 'DATAFLOW_DOCKER_REGISTRY'
              value: useContainerRegistry ? containerRegistry.properties.loginServer : 'docker.io'
            }
            {
              name: 'AZURE_SUBSCRIPTION_ID'
              value: subscription().subscriptionId
            }
            ...useUserAssignedIdentity ? [
              {
                name: 'AZURE_CLIENT_ID'
                value: userAssignedIdentity.properties.clientId
              }
            ] : []
            {
              name: 'SPRING_CLOUD_CONTAINERAPPS_ENABLED'
              value: 'true'
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_ENVIRONMENT'
              value: environment.name
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_RESOURCE_GROUP'
              value: resourceGroup().name
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_LOCATION'
              value: location
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_LOG_ANALYTICS_WORKSPACE_ID'
              value: logAnalyticsWorkspace.properties.customerId
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_SECRETS'
              secretRef: 'shelltask-secrets'
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_REGISTRIES'
              value: string([
                ...useContainerRegistry ? [
                  {
                    server: containerRegistry.properties.loginServer
                    username: containerRegistry.name
                    passwordSecretRef: 'container-registry-password' 
                  }
                ] : []
              ])
            }
            {
              name: 'SPRING_CLOUD_DATAFLOW_TASK_PLATFORM_CONTAINERAPPS_ACCOUNTS_DEFAULT_ENVIRONMENT_VARIABLES'
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

resource containerappsTaskPlatformRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' = if (!useUserAssignedIdentity)  {
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

resource catalogRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!useUserAssignedIdentity) {
  name: guid('catalog-role-assignment')
  properties: {
    principalId: app.identity.principalId
    roleDefinitionId: containerappsTaskPlatformRole.id
  }
}

output containerName string = app.properties.template.containers[0].name
