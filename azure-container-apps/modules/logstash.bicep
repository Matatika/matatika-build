param environmentId string
param location string
param elasticsearchHost string

@secure()
param elasticsearchPassword string

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'logstash-${uniqueString(environmentId)}'
  location: location
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      secrets: [
        {
          name: 'es-elastic-pass'
          value: elasticsearchPassword
        }
        {
          name: 'config'
          value: loadTextContent('../config/logstash/config/logstash.yml')
        }
        {
          name: 'pipeline-config'
          value: loadTextContent('../config/logstash/pipeline/logstash.conf')
        }
      ]
    }
    template: {
      scale: {
        minReplicas: 1
      }
      volumes: [
        {
          name: 'config'
          secrets: [
            {
              path: 'logstash.yml'
              secretRef: 'config'
            }
            {
              path: 'logstash.conf'
              secretRef: 'pipeline-config'
            }
          ]
          storageType: 'Secret'  // https://learn.microsoft.com/en-gb/azure/container-apps/manage-secrets?tabs=arm-template#secrets-volume-mounts
        }
      ]
      containers: [
        {
          name: 'logstash'
          image: 'docker.elastic.co/logstash/logstash:7.17.22'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          volumeMounts: [
            {
              volumeName: 'config'
              mountPath: '/usr/share/logstash/config/logstash.yml'
              subPath: 'logstash.yml'
            }
            {
              volumeName: 'config'
              mountPath: '/usr/share/logstash/pipeline/logstash.conf'
              subPath: 'logstash.conf'
            }
          ]
          env: [
            {
              name: 'ELASTICSEARCH_HOSTS'
              value: elasticsearchHost
            }
            {
              name: 'MATATIKA_ES_ELASTIC_PASSWORD'
              secretRef: 'es-elastic-pass'
            }
          ]
        }
      ]
    }
  }
}

output containerName string = app.properties.template.containers[0].name
