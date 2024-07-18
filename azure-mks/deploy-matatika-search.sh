#!/bin/bash

[[ -z "$BUILD_HELM_HOME" ]] && { echo "Error: BUILD_HELM_HOME not found in env"; exit 1; }
[[ -z "$BUILD_CONFIG_HOME" ]] && { echo "Error: BUILD_CONFIG_HOME not found in env"; exit 1; }
[[ -z "$CATALOG_HOME" ]] && { echo "Error: CATALOG_HOME not found in env"; exit 1; }
[[ -z "$STAGE" ]] && { echo "Error: STAGE not found in env"; exit 1; }
[[ -z "$CATALOG_MATATIKA_ES_ELASTIC_PASSWORD" ]] && { echo "Error: CATALOG_MATATIKA_ES_ELASTIC_PASSWORD not found in env"; exit 1; }

helm repo add stable https://charts.helm.sh/stable
helm repo add elastic https://helm.elastic.co
helm repo update

helm list --namespace ${STAGE}
retval=$?
if [ $retval -ne 0 ]; then
    echo "Error: Helm not operational, our check command returned $retval"; exit 1; 
fi
#
# helm upgrade [RELEASE] [CHART] [flags]
#
RELEASE=${STAGE}-matatika-search
CHART_VERSION=7.17.3
IMAGE_TAG=7.17.3
if [ -z "$APP_VERSION" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi


echo "Upgrading to CHART_VERSION: $CHART_VERSION, APP_VERSION: $APP_VERSION, IMAGE_TAG: $IMAGE_TAG"
{ echo "esConfig:"; } > /tmp/esConfig-values.yaml
{ echo "  elasticsearch.yml: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/elasticsearch.yml; } >> /tmp/esConfig-values.yaml
{ echo "  setup.sh: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/setup.sh; } >> /tmp/esConfig-values.yaml
{ echo "  es_template_default.json: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/es_template_default.json; } >> /tmp/esConfig-values.yaml
{ echo "  es_datasets_index_config.json: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/es_datasets_index_config.json; } >> /tmp/esConfig-values.yaml
{ echo "  es_logstash_policy_config.json: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/es_logstash_policy_config.json; } >> /tmp/esConfig-values.yaml
{ echo "  es_profiles_datasets_likes_index_config.json: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-search/config/es_profiles_datasets_likes_index_config.json; } >> /tmp/esConfig-values.yaml

helm upgrade \
	${RELEASE} \
    --version=${CHART_VERSION} \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--set imageTag=${IMAGE_TAG} \
	--set appVersion=${APP_VERSION} \
	--set extraEnvs[0].value=${CATALOG_MATATIKA_ES_ELASTIC_PASSWORD} \
	--debug \
	--values /tmp/esConfig-values.yaml \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/matatika-search-values.yaml \
	elastic/elasticsearch