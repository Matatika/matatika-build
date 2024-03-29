# matatika-build

Scripts and helm charts for deployment of the Matatika Platform services.

# Azure AKS

Production scripts for Azure managed kubernetes service can be found in ./azure-mks

# Setup

Execute the script in azure-mks/setup.sh once to create the entire container registry and the kubernetes cluster.

```console
cd azure-mks
./setup.sh
```

# Automatic Deployment using ADO pipelines.

Using Azure DevOps (ADO) pipelines in Azure you can deploy and upgrade the platform with one click.
Edit the file example_deploy.json (ADO export pipeline) with your secrets and DNS names.
Create a new repository in Azure Repos or Gitlab/Github, (named even matatika-build). Copy this whole project into your new repository.

Rename example\* files and folders with your company name. (1 folder and multiple files)

Edit the files:

| File Name                              | Description                                                                  |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| example_deploy.json                    | ADO pipeline that needs to be edited with your secrets, DNS, configuration.  |
| example/application-example.properties | contains platform properties files, that needs to be edited.                 |
| example-\*-values.yaml files           | contains helm charts values that will be used. Please edit also those files. |

As a general rule, inside each file, "example" word needs to be replaced with your company name.

Create a new release pipeline in your ADO project. Import the pipeline from this json file example_deploy.json.
Agent specifications - Azure hosted and Ubuntu-20.04. Fill the missing secrets and configurations.
Save and click create new release on the pipeline.

# Manual Deploy the Platform

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

# Other useful commands

Get the credentials to interact with AKS cluster (NB - this configures kubectl)

`$ az aks get-credentials -n BLUEAKS -g SERVICES`

Set your current context

`$ kubectl config set-context BLUEAKS --namespace=dev`

List all pods

`$ kubectl get pods`

If something goes wrong and you want to delete all charts
https://stackoverflow.com/questions/47817818/helm-delete-all-releases

`$ helm ls --all --short | xargs -L1 helm delete --purge`

Delete everything created in kubectl

`$ kubectl delete all,secrets,cm,pvc,pv --selector=app=[helm release name]`

Authenticate with Azure container registry (https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication)

`$ az acr login --name <acrName>`
`$ az acr repository list  --name <acrName>`

Which docker registry

`$ cat ~/.docker/config.json`
