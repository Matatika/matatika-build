aws_region           = "eu-west-2"
environment          = "dev"
base_cidr_block      = "10.2.0.0/16"
vpc_database_subnets = ["10.2.10.0/24", "10.2.20.0/24", "10.2.30.0/24"]
vpc_private_subnets  = ["10.2.11.0/24", "10.2.21.0/24", "10.2.31.0/24"]
vpc_public_subnets   = ["10.2.12.0/24", "10.2.23.0/24", "10.2.32.0/24"]
domain_name          = "matatika.com"
cluster_version      = "1.32"
db_config = {
  engine                      = "postgres"
  engine_version              = "16.8"
  db_name                     = "postgres"
  db_id                       = "postgres16"
  family                      = "postgres16"
  instance_class              = "db.t4g.micro"
  storage                     = 5 # GB
  port                        = 5432
  cloudwatch_logs             = ["postgresql", "upgrade"]
  secrets_manager_credentials = "/terraform/rds/credentials"
  multi_az                    = false
  # these Secrets Manager secrets need to be created outside Terraform (e.g. CLI or Console)
  # not to hardcode secret variables in the code
}
cloudflare_secret_credentials = "/terraform/cloudflare/credentials"
