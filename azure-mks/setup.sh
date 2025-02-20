
#export BUILD_AZ_RG=SERVICES
#export BUILD_AZ_LOCATION=eastus
#export BUILD_AZ_AKS_NAME=GREENAKS

[[ -z "$BUILD_AZ_RG" ]] && { echo "Error: BUILD_AZ_RG not found in env"; exit 1; }
[[ -z "$BUILD_AZ_LOCATION" ]] && { echo "Error: BUILD_AZ_LOCATION not found in env"; exit 1; }
[[ -z "$BUILD_AZ_AKS_NAME" ]] && { echo "Error: BUILD_AZ_AKS_NAME not found in env"; exit 1; }

#
# Check resource group exist in supplied location
if [ $(az group exists --name $BUILD_AZ_RG) = false ]; then
    echo "Error: resource group '$BUILD_AZ_RG' not found in '$BUILD_AZ_LOCATION'"; exit 1;
fi

#
# Container Registry
#
# Create an ACR registries
#az acr create -n matatika -g $BUILD_AZ_RG -l $BUILD_AZ_LOCATION --sku Basic --admin-enabled true
# Get the registry password
#az acr credential show -n matatika --query passwords[0].value

#
# Kubenetes Cluster
#
# Setup of the AKS cluster
az aks create -l $BUILD_AZ_LOCATION -n $BUILD_AZ_AKS_NAME -g $BUILD_AZ_RG \
    --enable-app-routing \
    --generate-ssh-keys \
    --node-count 1
# Once created (the creation could take ~10 min), get the credentials to interact with your AKS cluster
# (NB - this also configured kubectl)
az aks get-credentials -n $BUILD_AZ_AKS_NAME -g $BUILD_AZ_RG

#
# Delete default pool and create nodepools
#
az aks nodepool add --name esystempool --cluster-name $BUILD_AZ_AKS_NAME --resource-group $BUILD_AZ_RG -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --node-taints CriticalAddonsOnly=true:NoSchedule --mode System
az aks nodepool delete --name nodepool1 --cluster-name $BUILD_AZ_AKS_NAME --resource-group $BUILD_AZ_RG
az aks nodepool add --name nodepool1 --cluster-name $BUILD_AZ_AKS_NAME --resource-group $BUILD_AZ_RG -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 2 --enable-cluster-autoscaler
az aks nodepool add --name appspool --cluster-name $BUILD_AZ_AKS_NAME --resource-group $BUILD_AZ_RG -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 3 --enable-cluster-autoscaler
az aks nodepool add --name stagingapps --cluster-name $BUILD_AZ_AKS_NAME --resource-group $BUILD_AZ_RG -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 1 --enable-cluster-autoscaler

# Setup the MKS namespace, later you will deploy some apps into it
kubectl create namespace demo
kubectl create namespace staging
kubectl create namespace staging-tasks
kubectl create namespace prod
kubectl create namespace prod-tasks

# set default namespace
kubectl config set-context $BUILD_AZ_AKS_NAME --namespace=staging
kubectl get pods

#
# Ingress
#
# enable
az aks approuting enable --resource-group $BUILD_AZ_RG --name $BUILD_AZ_AKS_NAME
# whats my IP
kubectl get service -n app-routing-system nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}"

#
# optional
#

# Check the dashboard to ensure everything is working (https://docs.microsoft.com/en-us/azure/aks/kubernetes-dashboard)
# NB - might need this RBAC service account binding
#kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
#az aks browse -n $BUILD_AZ_AKS_NAME -g $BUILD_AZ_RG
