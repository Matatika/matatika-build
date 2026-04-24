# azure-mks

This README.md explains hows to run our app in an AWS Elastic Kubernetes Service cluster with the example configuration.

### Initial Setup

This only needs to take place once per cluster or per environment.

1. Configure kubectl to connect to your Kubernetes cluster (this assumes you are already authenticated to AWS, for the account in question, with appropriate EKS permissions):

```console
aws eks update-kubeconfig --region [region] --name [eks_cluster_name]
```

or if you have previously connected to the cluster:

```console
kubectl config use-context [your_context]
```


2. Create namespaces for our deployment. We need two namespaces per environment - one for the core catalog, and another for tasks.

```console
# create the namespaces
kubectl create namespace example
kubectl create namespace example-tasks

# set default namespace
kubectl config set-context [yourcontext] --namespace=example
kubectl get pods
```


3. Install helm (https://helm.sh/docs/intro/install/) and set the environment to find the helm binary, path to our charts, and any mandatory environments.

```console
export BUILD_HELM_HOME=../helm-charts
export BUILD_CONFIG_HOME=.
export STAGE=example
export CATALOG_PERSISTENCE_CATALOG_PASSWORD=password
export CATALOG_PERSISTENCE_WAREHOUSE_PASSWORD=admin
export CATALOG_MATATIKA_ENCRYPTOR_PASSWORD=encryptor_password
```


4. Install a PostgreSQL database for the default Warehouse (NB - not production grade)

Note: this is only required if you do not have an external PostgreSQL database available to connect to.

```console
helm upgrade \
	catalog-postgres \
	--namespace ${STAGE} \
	--create-namespace \
	--install \
	--wait \
	--timeout 10m0s \
	--set global.postgresql.auth.postgresPassword=admin \
	--set global.postgresql.auth.username=meltano \
	--set global.postgresql.auth.password=${CATALOG_PERSISTENCE_CATALOG_PASSWORD} \
	--set global.postgresql.auth.database=meltano \
	--values ${BUILD_CONFIG_HOME}/${STAGE}/postgres-values.yaml \
	oci://registry-1.docker.io/bitnamicharts/postgresql
```
### Ongoing Deployments

Execute the deploy scripts to deploy the applications.

```console
## NB - you can force the container to deploy the latest image by incrementing APP_VERSION
export APP_VERSION=1
export IMAGE_TAG=latest
export REGISTRY_PASSWORD="NOT USED IN EXAMPLE matatika-catalog-values.yaml"
export CATALOG_AUTH0_CLIENT_SECRET="NOT USED IN EXAMPLE application-example.properties"
export CATALOG_GITHUB_API_PRIVATE_KEY="REPO CREATION DISABLED IN EXAMPLE CONFIGURATION"
export CATALOG_GITHUB_API_WORKSPACES_PRIVATE_KEY="GITHUB DISABLED IN EXAMPLE CONFIGURATION"
export CATALOG_MATATIKA_ES_ELASTIC_PASSWORD="NOT USED IN EXAMPLE matatika-catalog-values.yaml"
./deploy-matatika-catalog.sh
```

Make a change and then deploy again.


6. Go to Lab and create a workspace

    a. `kubectl port-forward svc/example-matatika-catalog-springboot 8080:8080`

    b. Open -> http://localhost:8080

    c. Create a new workspace with an existing repository.
    e.g. https://github.com/Matatika/example-ga4-export

    New Workspace -> Advanced -> URL

    (this is necessary as the repo creation is disabled without github setup.)


To expose Matatika to the internet you will need to configure the matatika-catalog-value.yaml -> ingress -> annotations for your cluster and domains in application-example.properties.


7. Delete your release

$ helm delete [YOUR APP NAME]

e.g. 

```
helm delete example-matatika-catalog
```
