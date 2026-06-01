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
RELEASE=${STAGE}-matatika-logstash
CHART_VERSION=8.5.1
IMAGE_TAG=8.15.3
if [ -z "$APP_VERSION" ]; then
	echo "INFO: APP_VERSION not set, using 'latest'.  NB - helm won't redeploy if there's no changes to the release, even if the pull policy is always";
	APP_VERSION=latest
fi


echo "Upgrading to CHART_VERSION: $CHART_VERSION, APP_VERSION: $APP_VERSION, IMAGE_TAG: $IMAGE_TAG"
{ echo "logstashConfig:"; echo "  logstash.yml: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-logstash/config/logstash.yml; } > /tmp/logstashConfig-values.yaml
{ echo "logstashPipeline:"; echo "  logstash.conf: |"; sed -e 's/^/    /' ${CATALOG_HOME}/elastic-logstash/pipeline/logstash.conf; } > /tmp/logstashPipeline-values.yaml

# Download certificates from elastic search
kubectl exec -n $STAGE matatika-search-master-0 -c elasticsearch -- bash -c "cd /usr/share/elasticsearch/config/certs; tar --dereference -cf - ./ca.crt" | tar -xf - ./ca.crt
# Download certificates from secure external elastic search (R3 signed in this case)
#$CATALOG_HOME/elastic-logstash/certs/downloadcerts.sh
#mv r3.pem ca.crt

[[ ! -f ./ca.crt ]] && { echo "Error: cannot create logstashSecrets-values.yaml, ./ca.crt not found"; exit 1; }
{ echo "secrets:"; } > /tmp/logstashSecrets-values.yaml
{ echo "  - name: elasticsearch-master-credentials"; echo "    value:"; echo "      password: "${CATALOG_MATATIKA_ES_ELASTIC_PASSWORD}; } >> /tmp/logstashSecrets-values.yaml
{ echo "  - name: tls-certificates"; echo "    value:"; echo "      ca.crt: |"; sed -e 's/^/        /' ./ca.crt; } >> /tmp/logstashSecrets-values.yaml

helm upgrade \
	${RELEASE} \
    --version=${CHART_VERSION} \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--set imageTag=${IMAGE_TAG} \
	--set appVersion=${APP_VERSION} \
	--debug \
	--values /tmp/logstashConfig-values.yaml \
	--values /tmp/logstashPipeline-values.yaml \
	--values /tmp/logstashSecrets-values.yaml \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/matatika-logstash-values.yaml \
	elastic/logstash