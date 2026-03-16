terraform {
  # Use Azure Storage remote state and locking
  backend "azurerm" {
    use_azuread_auth = true
  }
}
