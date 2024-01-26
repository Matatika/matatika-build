# azure-mks container
This README.md explains hows to run a complete container for working with our kubernetes cluster.

NB - the ReadMe.txt file is displayed inside the container to help you run the first few commands that setup your local environment.

### To use our azure-mks container to install our whole application into kubernetes and start directly using the helm charts

To configure kubectl to connect to your Kubernetes cluster, run
```
az aks get-credentials -g DEMOS --name DEMOAKS
```

Within a linux helm container (https://hub.docker.com/r/alpine/helm)


Powershell (windows)
```
    ps$ cd azure-mks
    ps$ kubectl config use-context DEMOAKS
    ps$ az acr credential show -n matatika --query passwords[0].value
    ps$ docker build --build-arg REGISTRY_PASSWORD=[THE TOKEN] -t local/azure-mks .
    ps$ docker run -ti --rm -v ${PWD}/../:/apps/matatika-build -v ${PWD}/../../matatika-www:/apps/matatika-www -v ~/.kube/config:/root/.kube/config local/azure-mks
```

Linux
```
cd azure-mks
kubectl config use-context DEMOAKS
export REGISTRY_PASSWORD=`az acr credential show -n matatika --query passwords[0].value | sed -e 's/^"//' -e 's/"$//'`
docker build --build-arg REGISTRY_PASSWORD=$REGISTRY_PASSWORD -t local/azure-mks .
docker run -ti --rm -v `pwd`/../:/apps/matatika-build -v `pwd`/../../matatika-www:/apps/matatika-www -v ~/.kube/config:/root/.kube/config local/azure-mks
```

or 
```
./start_container.sh
```

Follow the ReadMe.txt steps shown

(Inside running azure-mks container) start tiller plugin (https://rimusz.net/tillerless-helm/)

```
## NB - you can force the container to deploy the latest image by incrementing APP_VERSION
export APP_VERSION=1
export IMAGE_TAG=latest
/apps/matatika-build/azure-mks/deploy-matatika-www.sh
```
or

```
helm tiller start
cd /apps/matatika-www/helm-charts/matatika-www
helm upgrade --install --set image.password=${REGISTRY_PASSWORD} --set mysql.mysqlPassword=test,mysql.mysqlRootPassword=test [YOUR APP NAME] .
helm tiller stop
```

Make a change and then upgrade

$ helm upgrade [YOUR APP NAME] .

Delete your release

$ helm delete [YOUR APP NAME]


