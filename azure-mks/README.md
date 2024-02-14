# azure-mks

This README.md explains hows to run our app in a kubernetes cluster.

### Setup and deploy

To configure kubectl to connect to your Kubernetes cluster, run

```
az aks get-credentials -g DEMOS --name DEMOAKS
```

Install helm (https://helm.sh/docs/intro/install/) and set the environment to find the helm charts, etc.

```console
export BUILD_HELM_HOME=../helm-charts
export STAGE=dev
# Login to azure and use AKS container registry
# az login
export REGISTRY_PASSWORD=`az acr credential show -n matatika --query passwords[0].value | sed -e 's/^"//' -e 's/"$//'`
```

Execute the deploy scripts to deploy the applications.

```console
## NB - you can force the container to deploy the latest image by incrementing APP_VERSION
export APP_VERSION=1
export IMAGE_TAG=latest
cd azure-mks
./deploy-matatika-catalog.sh
```

Make a change and then upgrade

$ helm upgrade [YOUR APP NAME] .

Delete your release

$ helm delete [YOUR APP NAME]
