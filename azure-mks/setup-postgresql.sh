#!/bin/bash -e

#
# create the POSTGRESQL analytics database 
#
# (managed azure postgresql)
# https://docs.microsoft.com/en-us/cli/azure/ext/db-up/postgres?view=azure-cli-latest#ext-db-up-az-postgres-up
az postgres server create --resource-group DEMOS --name catalog-staging-matatika --location eastus --admin-user adminLJQWE --admin-password [see 1password] --sku-name B_Gen5_1 --version 10.0 --storage-size 5120
az postgres server show --resource-group DEMOS --name catalog-staging-matatika
# psql postgresql://[admin-user]%40[admin-password]@catalog-staging-matatika.postgres.database.azure.com:5432/postgres


# Create a firewall rule to allow Virgin Media at home
az postgres server firewall-rule create --resource-group DEMOS --server catalog-staging-matatika --name AllowMyIP --start-ip-address 82.15.79.130 --end-ip-address 82.15.79.130
# Create a firewall rule to allow DBT connection
az postgres server firewall-rule create --resource-group DEMOS --server catalog-staging-matatika --name AllowDBTIP --start-ip-address 52.45.144.63 --end-ip-address 52.45.144.63
# Create a firewall rule to allow ALL Azure service (e.g. our AKS) NB - might need to restart the server
# select * from pg_hba_file_rules;
az postgres server firewall-rule create --resource-group DEMOS --server catalog-staging-matatika --name AllWindowsAzureIPs --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
az postgres server firewall-rule create --resource-group DEMOS --server catalog-staging-matatika --name AllowAKSIP --start-ip-address 40.88.49.53 --end-ip-address 40.88.49.53


# Create 'warehouse' db
az postgres db create --resource-group DEMOS --server-name catalog-staging-matatika --name warehouse