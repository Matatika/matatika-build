
export rg=SERVICES
export location=eastus
export aks_name=GREENAKS

#
# Create a resource group $rg on a specific location $location (for example eastus) which will contain the Azure services we need 
#   - trebuie scos!!!!!
#az group create -l $location -n $rg

#
# Container Registry
#
# Create an ACR registries
#az acr create -n matatika -g $rg -l $location --sku Basic --admin-enabled true
# Get the registry password
#az acr credential show -n matatika --query passwords[0].value

#
# Kubenetes Cluster
#
# Setup of the AKS cluster
az aks create -l $location -n $aks_name -g $rg --generate-ssh-keys -c 1
# Once created (the creation could take ~10 min), get the credentials to interact with your AKS cluster
# (NB - this also configured kubectl)
az aks get-credentials -n $aks_name -g $rg

#
# Delete default pool and create nodepools
#
az aks nodepool add --name esystempool --cluster-name $aks_name --resource-group $rg -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --node-taints CriticalAddonsOnly=true:NoSchedule --mode System
az aks nodepool delete --name nodepool1 --cluster-name $aks_name --resource-group $rg
az aks nodepool add --name nodepool1 --cluster-name $aks_name --resource-group $rg -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 2 --enable-cluster-autoscaler
az aks nodepool add --name appspool --cluster-name $aks_name --resource-group $rg -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 3 --enable-cluster-autoscaler
az aks nodepool add --name stagingapps --cluster-name $aks_name --resource-group $rg -s Standard_DS3_v2 --node-osdisk-type Ephemeral --node-count 1 --min-count 1 --max-count 1 --enable-cluster-autoscaler

# Setup the MKS namespace, you will deploy later some apps into it
kubectl create namespace demo
kubectl create namespace staging
kubectl create namespace staging-tasks
kubectl create namespace prod
kubectl create namespace prod-tasks

# set default namespace
kubectl config set-context $aks_name --namespace=staging
kubectl get pods

#
# HTTP routing
#
# enable
az aks enable-addons -n $aks_name -g $rg --addons http_application_routing
# whats my DNS name
az aks show -n $aks_name -g $rg --query addonProfiles.httpApplicationRouting.config.HTTPApplicationRoutingZoneName

#
# optional
#

# Check the dashboard to ensure everything is working (https://docs.microsoft.com/en-us/azure/aks/kubernetes-dashboard)
# NB - might need this RBAC service account binding
#kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
#az aks browse -n $aks_name -g $rg
