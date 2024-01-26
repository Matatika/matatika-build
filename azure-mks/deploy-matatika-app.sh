#!/bin/bash

[[ -z "$BUILD_HELM_HOME" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "$STAGE" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "$REGISTRY_PASSWORD" ]] && { echo "Error: REGISTRY_PASSWORD not found in env"; exit 1; }

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
RELEASE=${STAGE}-matatika-app
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
	--set mysql.mysqlPassword=test,mysql.mysqlRootPassword=test \
	--debug \
	--values ./${STAGE}-matatika-app-values.yaml \
	$BUILD_HELM_HOME/matatika-app/
