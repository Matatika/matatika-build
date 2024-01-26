#
# Create a private link from our kubernetes cluster to the postgres db
#
# NB - Deployment failed. Correlation ID: af1533b5-09c5-4ef4-8903-a2348781eb20. This feature is not available for the selected edition 'Basic'.
#
# https://docs.microsoft.com/en-us/azure/postgresql/howto-configure-privatelink-cli
# https://docs.microsoft.com/en-us/azure/postgresql/howto-manage-vnet-using-cli
#

az network vnet create --resource-group DEMOS --name matatikaVirtualNetwork --subnet-name staging
az network vnet subnet update --resource-group DEMOS --vnet-name matatikaVirtualNetwork --name staging --disable-private-endpoint-network-policies true

# Creates the service endpoint
az network vnet subnet update --resource-group DEMOS --vnet-name matatikaVirtualNetwork --name staging \
    --address-prefix 10.0.1.0/24 \
    --service-endpoints Microsoft.SQL
# Create a VNet rule on the server to secure it to the subnet. Note: resource group (-g) parameter is where the database exists. VNet resource group if different should be specified using subnet id (URI) instead of subnet, VNet pair.
az postgres server vnet-rule create -n aksRule \
    --resource-group DEMOS --vnet-name matatikaVirtualNetwork --subnet staging \
    -s catalog-staging-matatika

# helpful commands to view setup
# az network vnet subnet show -g DEMOS --vnet-name matatikaVirtualNetwork -n staging
# az network private-link-resource list --resource-group DEMOS -n catalog-staging-matatika --type "Microsoft.DBforPostgreSQL/servers"
# az network private-link-resource list -g DEMOS -n catalog-staging-matatika --resource-type "Microsoft.DBforPostgreSQL/servers" --query "id"



az network private-endpoint create --resource-group DEMOS --vnet-name matatikaVirtualNetwork --subnet staging \
    --name warehousePrivateEndpoint \
    --group-id <find the group id of our postgres server vnet>
    --private-connection-resource-id $(az resource show -g DEMOS -n catalog-staging-matatika --resource-type "Microsoft.DBforPostgreSQL/servers" --query "id" | sed -e 's/^"//' -e 's/"$//') \
    --connection-name warehouseConnection

az network private-dns zone create --resource-group DEMOS --name "staging.postgres.database.azure.com" 
az network private-dns link vnet create --resource-group DEMOS --virtual-network matatikaVirtualNetwork --zone-name  "staging.postgres.database.azure.com" --name StagingDNSLink --registration-enabled false

#Query for the network interface ID  
networkInterfaceId=$(az network private-endpoint show --resource-group DEMOS --name warehousePrivateEndpoint --query 'networkInterfaces[0].id' -o tsv)

az resource show --ids $networkInterfaceId --api-version 2019-04-01 -o json 
# Copy the content for privateIPAddress and FQDN matching the Azure database for PostgreSQL name 
 
#Create DNS records 
az network private-dns record-set a create --name warehouse --zone-name staging.postgres.database.azure.com --resource-group DEMOS  
az network private-dns record-set a add-record --record-set-name warehouse --zone-name staging.postgres.database.azure.com --resource-group DEMOS -a <Private IP Address>



