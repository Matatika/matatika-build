#!/bin/bash

[[ -z "$BUILD_HELM_HOME" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "$BUILD_CONFIG_HOME" ]] && { echo "Error: BUILD_CONFIG_HOME not found in env"; exit 1; }
[[ -z "$STAGE" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "$REGISTRY_PASSWORD" ]] && { echo "Error: REGISTRY_PASSWORD not found in env"; exit 1; }
[[ -z "$WWW_AUTH0_CLIENT_SECRET" ]] && { echo "Error: WWW_AUTH0_CLIENT_SECRET not found in env"; exit 1; }
[[ -z "$WWW_CATALOG_CLIENT_SECRET" ]] && { echo "Error: WWW_CATALOG_CLIENT_SECRET not found in env"; exit 1; }

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
RELEASE=${STAGE}-matatika-www
if [ -z "$APP_VERSION" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi
if [ -z "$IMAGE_TAG" ]; then
	echo "INFO: IMAGE_TAG not set, using APP_VERSION";
	IMAGE_TAG=$APP_VERSION
fi

#
# here we are packing our mysql dependency as we've modified it locally to support kubernetes api requirements
#
tar -czvf $BUILD_HELM_HOME/matatika-www/charts/mysql-0.13.0.tgz -C $BUILD_HELM_HOME/ mysql

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
	--set appService.auth0ClientSecret=${WWW_AUTH0_CLIENT_SECRET} \
	--set appService.catalogClientSecret=${WWW_CATALOG_CLIENT_SECRET} \
	--set mysql.mysqlPassword=test,mysql.mysqlRootPassword=test \
	--debug \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/matatika-www-values.yaml \
	$BUILD_HELM_HOME/matatika-www/
