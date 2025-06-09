module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "4.3.2"

  domain_name               = "${var.environment}.${var.domain_name}"
  validation_method         = "DNS"
  subject_alternative_names = []

  create_route53_records = false
  wait_for_validation    = false
}
