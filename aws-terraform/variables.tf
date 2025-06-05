variable "aws_region" {
  description = "AWS region"
  type        = string
}

# variable "assume_role_arn" {
#   description = "IAM role to assume"
#   type        = string
# }

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

# VPC
variable "base_cidr_block" {
  type        = string
  description = "CIDR blocks for VPC"
}

variable "vpc_database_subnets" {
  type        = list(string)
  description = "CIDR blocks for database subnets"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private (app) subnets"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public (load balancer) subnets"
}

# DB
variable "db_config" {
  type = object({
    engine                      = string
    engine_version              = string
    db_name                     = string
    db_id                       = string
    family                      = string
    instance_class              = string
    storage                     = number
    port                        = number
    cloudwatch_logs             = list(string)
    secrets_manager_credentials = string
    multi_az                    = bool
  })
  description = "Map of database config"
}

variable "enable_db_insights" {
  type        = bool
  description = "Whether to enable RDS Performance Insights for detailed monitoring"
  default     = true
}

variable "performance_insights_retention_period" {
  type        = number
  description = "For how long store RDS Performance Insights"
  default     = 31
}

variable "db_deletion_protection" {
  type        = bool
  description = "Whether to allow for database deletion"
  default     = true
}

variable "db_skip_final_snapshot" {
  type        = bool
  description = "Whether to skip snapshot creation when deleting database"
  default     = false
}

variable "rds_backup_retention_period" {
  type        = number
  description = "For how long store RDS backups"
  default     = 30
}

variable "key_deletion_days" {
  type        = number
  description = "A window of time after deleting KMS key when the deletion is pending"
  default     = 30
}

# EKS

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.31"
}

variable "domain_name" {
  type        = string
  description = "Domain name for ExternalDNS"
  default     = "matatika.com"
}

variable "cloudflare_secret_credentials" {
  type        = string
  description = "Secrets Manager path to CloudFlare API key"
  default     = "/terraform/cloudflare/credentials"

}
