#!/bin/bash

[[ -z "$BUILD_HELM_HOME" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "$BUILD_CONFIG_HOME" ]] && { echo "Error: BUILD_CONFIG_HOME not found in env"; exit 1; }
[[ -z "$STAGE" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "$REGISTRY_PASSWORD" ]] && { echo "Error: REGISTRY_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_AUTH0_CLIENT_SECRET" ]] && { echo "Error: CATALOG_AUTH0_CLIENT_SECRET not found in env"; exit 1; }
[[ -z "$CATALOG_GITHUB_API_PRIVATE_KEY" ]] && { echo "Error: CATALOG_GITHUB_API_PRIVATE_KEY not found in env"; exit 1; }
[[ -z "$CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY" ]] && { echo "Error: CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY not found in env"; exit 1; }
[[ -z "$CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD" ]] && { echo "Error: CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_PERSISTENCE_CATALOG_PASSWORD" ]] && { echo "Error: CATALOG_PERSISTENCE_CATALOG_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_MATATIKA_ES_ELASTIC_PASSWORD" ]] && { echo "Error: CATALOG_MATATIKA_ES_ELASTIC_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_MATATIKA_ENCRYPTOR_PASSWORD" ]] && { echo "Error: CATALOG_MATATIKA_ENCRYPTOR_PASSWORD not found in env"; exit 1; }

helm repo rm stable
helm repo add stable https://charts.helm.sh/stable

helm list --namespace ${STAGE}
retval=$?
if [ $retval -ne 0 ]; then
    echo "Error: Helm not operational, our check command returned $retval"; exit 1; 
fi
#
# helm upgrade [RELEASE] [CHART] [flags]
#
RELEASE=${STAGE}-matatika-catalog
if [ -z "$APP_VERSION" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi
if [ -z "$IMAGE_TAG" ]; then
	echo "INFO: IMAGE_TAG not set, using APP_VERSION";
	IMAGE_TAG=$APP_VERSION
fi


echo "Upgrading to CHART_VERSION: $CHART_VERSION, APP_VERSION: $APP_VERSION, IMAGE_TAG: $IMAGE_TAG"
helm upgrade \
	${RELEASE} \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--set image.password=${REGISTRY_PASSWORD} \
	--set image.tag=${IMAGE_TAG} \
	--set appService.version=${APP_VERSION} \
	--set appService.auth0ClientSecret=${CATALOG_AUTH0_CLIENT_SECRET} \
	--set appService.githubApiPrivateKey="${CATALOG_GITHUB_API_PRIVATE_KEY}" \
	--set appService.githubApiWorkspacesPrivateKey="${CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY}" \
	--set appService.persistenceWarehousePass=${CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD} \
	--set appService.persistenceCatalogPass=${CATALOG_PERSISTENCE_CATALOG_PASSWORD} \
	--set appService.elasticSearchPassword=${CATALOG_MATATIKA_ES_ELASTIC_PASSWORD} \
	--set appService.encryptorPassword=${CATALOG_MATATIKA_ENCRYPTOR_PASSWORD} \
	--set elasticsearch.rebuild="${ELASTICSEARCH_REBUILD}" \
	--set-file applicationProperties="${BUILD_CONFIG_HOME}/${STAGE}/application-${STAGE}.properties" \
	--debug \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/matatika-catalog-values.yaml \
	$BUILD_HELM_HOME/matatika-catalog/
