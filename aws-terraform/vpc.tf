module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"

  name = "${var.environment}-vpc"
  cidr = var.base_cidr_block
  azs  = data.aws_availability_zones.available.names

  database_subnets = var.vpc_database_subnets
  private_subnets  = var.vpc_private_subnets
  public_subnets   = var.vpc_public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames               = true
  enable_dns_support                 = true
  create_database_subnet_route_table = true

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_traffic_type                           = "REJECT" # Valid values: ACCEPT, REJECT, ALL

  database_subnet_tags = {
    SubnetType = "db"
  }

}
