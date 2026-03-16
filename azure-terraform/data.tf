# Current tenant / subscription / principal
data "azurerm_client_config" "current" {}

# DB credentials from Azure Key Vault (must be pre-provisioned)
# Secret value must be JSON with keys: "username" and "password"
data "azurerm_key_vault_secret" "db_creds" {
  name         = var.db_config.credentials_secret
  key_vault_id = var.credentials_key_vault_id
}
