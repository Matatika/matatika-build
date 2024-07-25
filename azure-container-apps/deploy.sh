#!/usr/bin/env bash
set -euo pipefail

: "$CATALOG_HOME"
: "$BUILD_CONFIG_HOME"
: "$STAGE"

cp -r "$CATALOG_HOME"/elastic-logstash/* config/logstash/
cp -r "$BUILD_CONFIG_HOME/azure-mks/$STAGE/application-$STAGE.properties" config/catalog/application.properties

az deployment group create \
    --resource-group SERVICES \
    --template-file main.bicep \
    --parameters parameters/env.bicepparam
