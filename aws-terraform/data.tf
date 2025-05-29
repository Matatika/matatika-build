# Current region
data "aws_region" "current" {}

# Getting account ID
data "aws_caller_identity" "current" {}

# Region AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# DB
data "aws_secretsmanager_secret" "db_creds" {
  name = var.db_config.secrets_manager_credentials
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = data.aws_secretsmanager_secret.db_creds.id
}
