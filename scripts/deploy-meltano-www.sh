#!/usr/bin/env bash
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Deploys the matatika-www chart into a GKE cluster. The image is pulled from
# GCP Artifact Registry (IMAGE_NAME:IMAGE_TAG) and Azure-specific storage is
# intentionally NOT configured here — on GKE the persistent volumes are backed
# by a GKE StorageClass set in the environment values file
# (${BUILD_CONFIG_HOME}/${STAGE}/matatika-www-values.yaml), not azurefile.
#
# Receive configuration via environment variables, and fail if any are missing.
[[ -z "${BUILD_HELM_HOME:-}" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "${BUILD_CONFIG_HOME:-}" ]] && { echo "Error: BUILD_CONFIG_HOME not found in env"; exit 1; }
[[ -z "${STAGE:-}" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "${IMAGE_NAME:-}" ]] && { echo "Error: IMAGE_NAME not found in env"; exit 1; } # e.g. europe-west2-docker.pkg.dev/meltano-shared-services/meltano/meltano-www
[[ -z "${WWW_AUTH0_CLIENT_SECRET:-}" ]] && { echo "Error: WWW_AUTH0_CLIENT_SECRET not found in env"; exit 1; }
[[ -z "${WWW_CATALOG_CLIENT_SECRET:-}" ]] && { echo "Error: WWW_CATALOG_CLIENT_SECRET not found in env"; exit 1; }

helm repo rm stable || true
helm repo add stable https://charts.helm.sh/stable

helm list --namespace "${STAGE}"
retval=$?
if [ $retval -ne 0 ]; then
	echo "Error: Helm not operational, our check command returned $retval"; exit 1;
fi

#
# helm upgrade [RELEASE] [CHART] [flags]
#
RELEASE=${STAGE}-matatika-www

if [ -z "${APP_VERSION:-}" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi
if [ -z "${IMAGE_TAG:-}" ]; then
	echo "INFO: IMAGE_TAG not set, using APP_VERSION";
	IMAGE_TAG=$APP_VERSION
fi

#
# Pack the mysql dependency as it has been modified locally to support
# kubernetes api requirements (same as the Azure deploy path).
#
tar -czf "$BUILD_HELM_HOME/matatika-www/charts/mysql-0.13.0.tgz" -C "$BUILD_HELM_HOME/" mysql

echo "Upgrading ${RELEASE} — IMAGE: ${IMAGE_NAME}:${IMAGE_TAG}, APP_VERSION: ${APP_VERSION}"
helm upgrade \
	"${RELEASE}" \
	--namespace "${STAGE}" \
	--create-namespace \
	--install \
	--wait \
	--timeout 10m0s \
	--set image.name="${IMAGE_NAME}" \
	--set image.tag="${IMAGE_TAG}" \
	--set image.pullPolicy=Always \
	--set appService.version="${APP_VERSION}" \
	--set appService.auth0ClientSecret="${WWW_AUTH0_CLIENT_SECRET}" \
	--set appService.catalogClientSecret="${WWW_CATALOG_CLIENT_SECRET}" \
	--set mysql.mysqlPassword=test,mysql.mysqlRootPassword=test \
	--debug \
	--values "${BUILD_CONFIG_HOME}/${STAGE}/matatika-www-values.yaml" \
	"$BUILD_HELM_HOME/matatika-www/"
