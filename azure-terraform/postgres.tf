# Azure Database for PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "db" {
  name                = "${var.environment}-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  version    = var.db_config.engine_version
  sku_name   = var.db_config.sku_name
  storage_mb = var.db_config.storage_mb

  administrator_login    = jsondecode(data.azurerm_key_vault_secret.db_creds.value)["username"]
  administrator_password = jsondecode(data.azurerm_key_vault_secret.db_creds.value)["password"]

  # Private networking — equivalent to publicly_accessible = false
  delegated_subnet_id = azurerm_subnet.database.id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  backup_retention_days        = var.rds_backup_retention_period
  geo_redundant_backup_enabled = false

  auto_grow_enabled = true

  # Zone redundancy — equivalent to multi_az
  dynamic "high_availability" {
    for_each = var.db_config.zone_redundant ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  # Equivalent to maintenance_window = "Sun:05:00-Sun:06:00"
  maintenance_window {
    day_of_week  = 0 # Sunday
    start_hour   = 5
    start_minute = 0
  }

  # Customer-managed key encryption — equivalent to kms_key_id + storage_encrypted = true
  customer_managed_key {
    key_vault_key_id                  = azurerm_key_vault_key.db.id
    primary_user_assigned_identity_id = azurerm_user_assigned_identity.postgres.id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.postgres.id]
  }

  # auto_minor_version_upgrade = false — Azure Flexible Server upgrades are controlled via maintenance window
  create_mode = "Default"

  tags = {
    engine      = "postgresql"
    db_id       = var.db_config.db_id
    environment = var.environment
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Initial database — equivalent to db_name in the RDS module
resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.db_config.db_name
  server_id = azurerm_postgresql_flexible_server.db.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Network Security Group — equivalent to module "db_sg"
resource "azurerm_network_security_group" "db" {
  name                = "${var.environment}-db-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "allow-postgres-from-vnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.db_config.port)
    source_address_prefix      = var.base_cidr_block
    destination_address_prefix = "*"
    description                = "Access from within VNet for ${var.environment}"
  }

  security_rule {
    name                       = "allow-postgres-whitelisted-ip"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.db_config.port)
    source_address_prefix      = "82.15.79.130/32"
    destination_address_prefix = "*"
    description                = "Access for whitelisted IP"
  }

  security_rule {
    name                       = "allow-postgres-dbt"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.db_config.port)
    source_address_prefix      = "52.45.144.63/32"
    destination_address_prefix = "*"
    description                = "Access from DBT"
  }

  tags = {
    environment = var.environment
  }
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.db.id
}

# User-assigned managed identity required for customer-managed key
resource "azurerm_user_assigned_identity" "postgres" {
  name                = "${var.environment}-postgres-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    environment = var.environment
  }
}

# Key Vault for CMK encryption — equivalent to aws_kms_key + aws_kms_alias
# Name must be globally unique and 3–24 characters
resource "random_id" "key_vault_suffix" {
  byte_length = 3
}

resource "azurerm_key_vault" "db" {
  name                       = "${var.environment}-db-kv-${random_id.key_vault_suffix.hex}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = var.key_deletion_days
  purge_protection_enabled   = true

  # Caller (Terraform identity) — equivalent to KMS key policy root access
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Create", "Delete", "Get", "List", "Purge", "Recover",
      "Update", "GetRotationPolicy", "SetRotationPolicy",
    ]
  }

  # PostgreSQL managed identity — needs wrap/unwrap for encryption
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.postgres.principal_id

    key_permissions = ["Get", "WrapKey", "UnwrapKey"]
  }

  tags = {
    environment = var.environment
    db_id       = var.db_config.db_id
  }
}

resource "azurerm_key_vault_key" "db" {
  name         = "${var.environment}-${var.db_config.db_id}-cmk"
  key_vault_id = azurerm_key_vault.db.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]

  # Automatic key rotation — equivalent to enable_key_rotation = true
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P30D"
  }
}

# Log Analytics Workspace for PostgreSQL diagnostics — equivalent to CloudWatch log group
resource "azurerm_log_analytics_workspace" "db" {
  name                = "${var.environment}-db-logs"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = var.performance_insights_retention_period

  tags = {
    environment = var.environment
  }
}

# Diagnostic settings — equivalent to enabled_cloudwatch_logs_exports + Performance Insights
resource "azurerm_monitor_diagnostic_setting" "db" {
  count = var.enable_db_insights ? 1 : 0

  name                       = "${var.environment}-db-diagnostics"
  target_resource_id         = azurerm_postgresql_flexible_server.db.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.db.id

  dynamic "enabled_log" {
    for_each = var.db_config.log_categories
    content {
      category = enabled_log.value
    }
  }
}

# Resource lock — equivalent to deletion_protection = true
resource "azurerm_management_lock" "db" {
  count = var.db_deletion_protection ? 1 : 0

  name       = "${var.environment}-db-lock"
  scope      = azurerm_postgresql_flexible_server.db.id
  lock_level = "CanNotDelete"
  notes      = "Deletion protection enabled for ${var.environment} database"
}
