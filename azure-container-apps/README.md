# Azure Container Apps

Deploy:

```sh
cd azure-container-apps

# set environment variables for parameters/env.bicepparam

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters parameters/env.bicepparam
```
