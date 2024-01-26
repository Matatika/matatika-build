#
# Login and add the repo
#
helm init --client-only
helm plugin install https://github.com/rimusz/helm-tiller

# setup the Azure client
az login
az acr repository show-tags -n matatika --repository matatika-www

# to run the deploy scripts in 'matatika-build/azure-mks', set some environments
export BUILD_HELM_HOME=/apps/matatika-build/helm-charts

## NB - you can force the container to deploy the latest image by incrementing APP_VERSION
export APP_VERSION=1
export IMAGE_TAG=latest
