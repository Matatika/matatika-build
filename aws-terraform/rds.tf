# RDS shared instance 
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.1"

  identifier = "${var.environment}-db"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = var.db_config.engine
  engine_version       = var.db_config.engine_version
  major_engine_version = var.db_config.engine_version
  instance_class       = var.db_config.instance_class
  family               = var.db_config.family

  allocated_storage = var.db_config.storage
  kms_key_id        = aws_kms_key.db.arn
  storage_encrypted = true
  storage_type      = "gp2"

  db_name  = var.db_config.db_name
  username = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["username"]
  create_random_password = false
  password = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  port     = var.db_config.port

  multi_az               = var.db_config.multi_az
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.db_sg.security_group_id]

  create_db_subnet_group = false
  db_subnet_group_name   = module.vpc.database_subnet_group

  maintenance_window              = "Sun:05:00-Sun:06:00"
  backup_window                   = "03:00-05:00"
  enabled_cloudwatch_logs_exports = var.db_config.cloudwatch_logs

  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = var.db_skip_final_snapshot
  deletion_protection     = var.db_deletion_protection

  performance_insights_enabled          = var.enable_db_insights
  performance_insights_retention_period = var.performance_insights_retention_period
  create_monitoring_role                = true
  monitoring_role_name                  = "${var.environment}-db-monitoring-role-${var.db_config.engine}"
  monitoring_interval                   = 10

  auto_minor_version_upgrade = false
  publicly_accessible        = false

  db_instance_tags = {
    engine = var.db_config.engine
    db_id  = var.db_config.db_id
  }

}

# RDS security group
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4"

  name        = "${var.environment}-db-sg"
  description = "Security group for database in ${var.environment}"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = var.db_config.port
      to_port     = var.db_config.port
      protocol    = "tcp"
      description = "Access from within VPC for ${var.environment}"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = var.db_config.port
      to_port     = var.db_config.port
      protocol    = "tcp"
      description = "Access for whitelisted IP"
      cidr_blocks = "82.15.79.130/32"
    },
    {
      from_port   = var.db_config.port
      to_port     = var.db_config.port
      protocol    = "tcp"
      description = "Access from DBT"
      cidr_blocks = "52.45.144.63/32"
    },
  ]
}

# KMS key
resource "aws_kms_key" "db" {

  description             = "${var.environment}-db-${var.db_config.db_id}-kms"
  is_enabled              = true
  enable_key_rotation     = true
  deletion_window_in_days = var.key_deletion_days

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "default"
    Statement = [
      {
        Sid    = "default"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
          ]
        }
        Action = [
          "kms:*",
        ]
        Resource = "*"
      },
    ]
  })

}

resource "aws_kms_alias" "db" {
  name          = "alias/${var.environment}-${var.db_config.db_id}-kms"
  target_key_id = aws_kms_key.db.key_id
}
