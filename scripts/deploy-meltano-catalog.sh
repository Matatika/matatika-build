#!/usr/bin/env bash
set -euo pipefail
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Receive configuration via environment variables, and fail if any are missing.
[[ -z "$APP_NAME" ]] && { echo "Error: APP_NAME not found in env"; exit 1; } # either "meltano" or "matatika"
[[ -z "$BUILD_HELM_HOME" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "$BUILD_CONFIG_HOME" ]] && { echo "Error: BUILD_CONFIG_HOME not found in env"; exit 1; }
[[ -z "$STAGE" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "$CATALOG_AUTH0_CLIENT_SECRET" ]] && { echo "Error: CATALOG_AUTH0_CLIENT_SECRET not found in env"; exit 1; }
[[ -z "$CATALOG_GITHUB_API_PRIVATE_KEY" ]] && { echo "Error: CATALOG_GITHUB_API_PRIVATE_KEY not found in env"; exit 1; }
[[ -z "$CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY" ]] && { echo "Error: CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY not found in env"; exit 1; }
[[ -z "$CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD" ]] && { echo "Error: CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_PERSISTENCE_CATALOG_PASSWORD" ]] && { echo "Error: CATALOG_PERSISTENCE_CATALOG_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_MATATIKA_ES_ELASTIC_PASSWORD" ]] && { echo "Error: CATALOG_MATATIKA_ES_ELASTIC_PASSWORD not found in env"; exit 1; }
[[ -z "$CATALOG_MATATIKA_ENCRYPTOR_PASSWORD" ]] && { echo "Error: CATALOG_MATATIKA_ENCRYPTOR_PASSWORD not found in env"; exit 1; }

# Azure specific configuration - when deploying to AKE we need to provide a registry password for the Shelltask to run.
if [[ "$APP_NAME" == "matatika" ]]; then
	[[ -z "$REGISTRY_PASSWORD" ]] && { echo "Error: REGISTRY_PASSWORD not found in env"; exit 1; }
fi

helm repo rm stable || true
helm repo add stable https://charts.helm.sh/stable

helm list --namespace ${STAGE}
retval=$?
if [ $retval -ne 0 ]; then
    echo "Error: Helm not operational, our check command returned $retval"; exit 1; 
fi
#
# helm upgrade [RELEASE] [CHART] [flags]
#
RELEASE=${STAGE}-${APP_NAME}-catalog
if [ -z "$APP_VERSION" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi
if [ -z "$IMAGE_TAG" ]; then
	echo "INFO: IMAGE_TAG not set, using APP_VERSION";
	IMAGE_TAG=$APP_VERSION
fi

ELASTICSEARCH_REBUILD=${ELASTICSEARCH_REBUILD:-false}

# Build-unique value rendered into a pod-template annotation so every deploy
# rotates the ReplicaSet, even when image.tag is a mutable tag (e.g. latest-dev)
# whose underlying image has been rebuilt.
REDEPLOY_AT=${CODEBUILD_BUILD_ID:-$(date -u +%Y%m%dT%H%M%SZ)}

echo "Upgrading to APP_VERSION: $APP_VERSION, IMAGE_TAG: $IMAGE_TAG"

# ── GKE context discovery ─────────────────────────────────────────────────────
# When deploying into a GKE cluster, the kubeconfig context is named
# `gke_<project>_<location>_<cluster>`. Pull project / location / cluster
# straight out of it and pass them to the chart's gcp.* values, so the
# environment values file doesn't have to repeat what's already implicit
# in the active context.
HELM_GCP_OVERRIDES=()
CONTEXT=$(kubectl config current-context)
if [[ "$CONTEXT" == gke_* ]]; then
	IFS=_ read -r _ GCP_PROJECT GCP_LOCATION GCP_CLUSTER <<<"$CONTEXT"
	echo "INFO: detected GKE context — project=$GCP_PROJECT, location=$GCP_LOCATION, cluster=$GCP_CLUSTER"
	HELM_GCP_OVERRIDES=(
		--set gcp.enabled=true
		--set gcp.projectId="$GCP_PROJECT"
		--set gcp.cluster.location="$GCP_LOCATION"
		--set gcp.cluster.name="$GCP_CLUSTER"
	)
fi

echo "Upgrading to APP_VERSION: $APP_VERSION, IMAGE_TAG: $IMAGE_TAG"
helm upgrade \
	${RELEASE} \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--timeout 10m0s \
	--set image.tag="${IMAGE_TAG}" \
	--set deploy.redeployAt="${REDEPLOY_AT}" \
	--set appService.version="${APP_VERSION}" \
	--set appService.auth0ClientSecret="${CATALOG_AUTH0_CLIENT_SECRET}" \
	--set appService.githubApiPrivateKey="${CATALOG_GITHUB_API_PRIVATE_KEY}" \
	--set appService.githubApiWorkspacesPrivateKey="${CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY}" \
	--set appService.persistenceWarehousePass="${CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD}" \
	--set appService.persistenceCatalogPass="${CATALOG_PERSISTENCE_CATALOG_PASSWORD}" \
	--set appService.elasticSearchPassword="${CATALOG_MATATIKA_ES_ELASTIC_PASSWORD}" \
	--set appService.encryptorPassword="${CATALOG_MATATIKA_ENCRYPTOR_PASSWORD}" \
	--set elasticsearch.rebuild="${ELASTICSEARCH_REBUILD}" \
	--set-file applicationProperties="${BUILD_CONFIG_HOME}/${STAGE}/application-${STAGE}.properties" \
	--debug \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/${APP_NAME}-catalog-values.yaml \
	${HELM_GCP_OVERRIDES[@]+"${HELM_GCP_OVERRIDES[@]}"} \
	$BUILD_HELM_HOME/${APP_NAME}-catalog/
