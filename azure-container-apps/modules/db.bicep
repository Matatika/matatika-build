param environmentId string
param location string

var user = 'warehouse'
var password = 'warehouse'
var port = 5432

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'db-${uniqueString(environmentId)}'
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: false  // https://github.com/microsoft/azure-container-apps/discussions/1033#discussioncomment-7997192
        targetPort: port
        transport: 'tcp'
      }
      secrets: [
        {
          name: 'postgres-password'
          value: password
        }
      ]
    }
    template: {
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      containers: [
        {
          name: 'db'
          image: 'docker.io/postgres:16.3'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'POSTGRES_USER'
              value: user
            }
            {
              name: 'POSTGRES_PASSWORD'
              value: password
            }
          ]
        }
      ]
    }
  }
}

output jdbcUrl string = 'jdbc:postgresql://${app.name}:${port}/warehouse'
output user string = user

#disable-next-line outputs-should-not-contain-secrets
output password string = password
