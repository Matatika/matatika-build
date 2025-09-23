# azure-mks

This README.md explains hows to run our app in a kubernetes cluster with the example configuration.

### Setup and deploy

1. Configure kubectl to connect to your Kubernetes cluster, e.g on Azure run

```console
az aks get-credentials -g DEMOS --name DEMOAKS
```

or 

```console
kubectl config use-context [your context]
```


2. Create namespaces for our example deployment

```console
# Setup the MKS namespace, later you will deploy some apps into it
kubectl create namespace example
kubectl create namespace example-tasks

# set default namespace
kubectl config set-context [your context] --namespace=example
kubectl get pods
```


3. Install helm (https://helm.sh/docs/intro/install/) and set the environment to find the helm binary, path to our charts, and any mandatory environments.

```console
export BUILD_HELM_HOME=../helm-charts
export BUILD_CONFIG_HOME=.
export STAGE=example
export CATALOG_PERSISTENCE_CATALOG_PASSWORD=password
export CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD=password
export CATALOG_MATATIKA_ENCRYPTOR_PASSWORD=encryptor_password
```


4. Install a postgres database (NB - not production grade)

```console
helm upgrade \
	catalog-postgres \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--timeout 10m0s \
	--set global.postgresql.auth.postgresPassword=admin \
	--set global.postgresql.auth.username=matatika \
	--set global.postgresql.auth.password=${CATALOG_PERSISTENCE_CATALOG_PASSWORD} \
	--set global.postgresql.auth.database=matatika \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/postgres-values.yaml \
	oci://registry-1.docker.io/bitnamicharts/postgresql
```


5. Execute the deploy scripts to deploy the applications.

```console
## NB - you can force the container to deploy the latest image by incrementing APP_VERSION
export APP_VERSION=1
export IMAGE_TAG=latest
export REGISTRY_PASSWORD="NOT USED IN EXAMPLE matatika-catalog-values.yaml"
export CATALOG_AUTH0_CLIENT_SECRET="NOT USED IN EXAMPLE application-example.properties"
export CATALOG_GITHUB_API_PRIVATE_KEY="REPO CREATION WILL FAIL IN EXAMPLE CONFIGURATION"
export CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY="NOT USED IN EXAMPLE application-example.properties"
export CATALOG_MATATIKA_ES_ELASTIC_PASSWORD="NOT USED IN EXAMPLE matatika-catalog-values.yaml"
./deploy-matatika-catalog.sh
```

Make a change and then deploy again.


6. Expose ingress

To expose Matatika to the internet you will need to configure the matatika-catalog-value.yaml -> ingress -> annotations for your cluster.


7. Delete your release

$ helm delete [YOUR APP NAME]

e.g. 

```
helm delete example-matatika-catalog
```
