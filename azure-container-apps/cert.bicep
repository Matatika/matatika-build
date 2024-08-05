param deploymentName string
param location string = resourceGroup().location
param customDomainName string

resource appEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: deploymentName

  resource managedCerficate 'managedCertificates@2024-03-01' = {
    name: customDomainName
    location: location
    properties: {
      subjectName: customDomainName
      domainControlValidation: 'CNAME'
    }
  }

}
