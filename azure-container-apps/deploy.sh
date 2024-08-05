#!/usr/bin/env bash
set -euo pipefail

: "$CATALOG_HOME"
: "$BUILD_CONFIG_HOME"
: "$STAGE"

cp -r "$CATALOG_HOME"/elastic-logstash/* config/logstash/
cp -r "$BUILD_CONFIG_HOME/azure-mks/$STAGE/application-$STAGE.properties" config/catalog/application.properties

# multiple deployment runs are required, see
# - https://github.com/microsoft/azure-container-apps/issues/796
# - https://johnnyreilly.com/azure-container-apps-bicep-managed-certificates-custom-domains

az deployment group create \
    --resource-group SERVICES \
    --template-file main.bicep \
    --parameters parameters/env.bicepparam > deployment.json

cname=$(jq -r .properties.outputs.cname.value deployment.json)
txt=$(jq -r .properties.outputs.txt.value deployment.json)

echo "Add/update the following records for your DNS provider:"
echo
echo "CNAME: [www or {subdomain}] $cname (do not proxy)"
echo "TXT: [asuid.www or asuid.{subdomain}] $txt"
echo

if [ -t 1 ]; then
    read -rs -n 1 -p 'Press any key to continue...'
    echo
    echo
fi

deploymentName=$(jq -r .properties.outputs.deploymentName.value deployment.json)
customDomainName=$(jq -r .properties.parameters.customDomainName.value deployment.json)

az deployment group create \
    --resource-group SERVICES \
    --template-file cert.bicep \
    --parameters "deploymentName=$deploymentName" "customDomainName=$customDomainName"

az deployment group create \
    --resource-group SERVICES \
    --template-file main.bicep \
    --parameters parameters/env.bicepparam managedCertificateExists=true
