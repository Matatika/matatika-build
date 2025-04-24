using '../main.bicep'

param deploymentNamePrefix = readEnvironmentVariable('DEPLOYMENT_NAME_PREFIX', '')
param containerRegistryConfig = {
  name: readEnvironmentVariable('CONTAINER_REGISTRY_NAME')
  resourceGroupName: readEnvironmentVariable('CONTAINER_REGISTRY_RESOURCE_GROUP_NAME', '')
}
param imageConfig = {
  name: readEnvironmentVariable('IMAGE_CONFIG', 'matatika/catalog')
  tag: readEnvironmentVariable('IMAGE_TAG', 'latest')
}
param customDomainName = readEnvironmentVariable('CUSTOM_DOMAIN_NAME', '')
param reactAppEnv = readEnvironmentVariable('REACT_APP_ENV', 'production')
param appIdentityClientId = readEnvironmentVariable('APP_IDENTITY_CLIENT_ID', '')
param javaOpts = readEnvironmentVariable('JAVA_OPTS', '-XX:MaxDirectMemorySize=128M -XX:MaxMetaspaceSize=240234K -XX:ReservedCodeCacheSize=240M -Xss1M -Xmx1079906K')
param activeProfiles = readEnvironmentVariable('ACTIVE_PROFILES', 'default,deploy')
param persistenceCatalogUrl = readEnvironmentVariable('PERSISTENCE_CATALOG_URL', '')
param persistenceCatalogUsername = readEnvironmentVariable('PERSISTENCE_CATALOG_USERNAME', '')
param persistenceCatalogPassword = readEnvironmentVariable('PERSISTENCE_CATALOG_PASSWORD', '')
param persistenceWarehouseUrl = readEnvironmentVariable('PERSISTENCE_WAREHOUSE_URL')
param persistenceWarehouseUsername = readEnvironmentVariable('PERSISTENCE_WAREHOUSE_USERNAME')
param persistenceWarehousePassword = readEnvironmentVariable('PERSISTENCE_WAREHOUSE_PASSWORD')
param auth0ClientSecret = readEnvironmentVariable('AUTH0_CLIENT_SECRET')
param githubApiPrivateKey = readEnvironmentVariable('GITHUB_API_PRIVATE_KEY')
param githubApiWorkspacesPrivateKey = readEnvironmentVariable('GITHUB_API_WORKSPACES_PRIVATE_KEY')
param elasticsearchHost = readEnvironmentVariable('ELASTICSEARCH_HOST', 'elasticsearch:9200')
param elasticsearchUser = readEnvironmentVariable('ELASTICSEARCH_USER')
param elasticsearchPassword = readEnvironmentVariable('ELASTICSEARCH_PASSWORD')
param encryptorPassword = readEnvironmentVariable('MATATIKA_ENCRYPTOR_PASSWORD')
