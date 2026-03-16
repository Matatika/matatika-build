variable "azure_location" {
  description = "Azure region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

# VNet
variable "base_cidr_block" {
  type        = string
  description = "CIDR block for VNet"
}

variable "vnet_database_subnet" {
  type        = string
  description = "CIDR block for the database delegated subnet"
}

variable "vnet_private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private (app) subnets"
}

variable "vnet_public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public (load balancer) subnets"
}

# DB
variable "db_config" {
  type = object({
    engine_version     = string
    db_name            = string
    db_id              = string
    sku_name           = string
    storage_mb         = number
    port               = number
    log_categories     = list(string)
    credentials_secret = string
    zone_redundant     = bool
  })
  description = "Map of database config"
}

variable "credentials_key_vault_id" {
  type        = string
  description = "Resource ID of the pre-existing Key Vault containing database credentials"
}

variable "enable_db_insights" {
  type        = bool
  description = "Whether to enable database performance insights (controls diagnostic log collection)"
  default     = true
}

variable "performance_insights_retention_period" {
  type        = number
  description = "How long (days) to retain database performance logs in Log Analytics (min 30)"
  default     = 31
}

variable "db_deletion_protection" {
  type        = bool
  description = "Whether to prevent database deletion via a resource management lock"
  default     = true
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Azure automatically retains a final backup on deletion; this variable is kept for parity with AWS"
  default     = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "How long (days) to retain automated database backups (7–35)"
  default     = 30
}

variable "key_deletion_days" {
  type        = number
  description = "Soft-delete retention period (days) for the Key Vault used for database encryption (7–90)"
  default     = 30
}
